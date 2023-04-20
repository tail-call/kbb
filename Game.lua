local Guy = require('./Guy').Guy
local canRecruitGuy = require('./Guy').canRecruitGuy
local moveGuy = require('./Guy').moveGuy
local warpGuy = require('./Guy').warpGuy
local updateGuy = require('./Guy').updateGuy
local loadWorld = require('./world').loadWorld
local setTile = require('./world').setTile
local getTile = require('./world').getTile
local isPassable = require('./world').isPassable
local ui = require('./ui')
local tbl = require('./tbl')
local vector = require('./vector')
local rng = require('./rng')
local ability = require('./ability')
local maybeDrop = require('./tbl').maybeDrop
local makeConsoleMessage = require('./console').makeConsoleMessage
local makeConsole = require('./console').makeConsole
local randomLetterCode = require('./util').randomLetterCode
local makeRecruitCircle = require('./recruitcircle').makeRecruitCircle
local isRecruitCircleActive = require('./recruitcircle').isRecruitCircleActive
local makeSquad = require('./squad').makeSquad
local isGuyAFollower = require('./squad').isGuyAFollower
local makeResources = require('./resources').makeResources
local makeBattle = require('./battle').makeBattle
local makeUIDelegate = require('./UIDelegate').makeUIDelegate
local makeText = require('./Text').makeText
local makeBuilding = require('./Building').makeBuilding
local makeBuildingEntity = require('./GameEntity').makeBuildingEntity
local makeBattleEntity = require('./GameEntity').makeBattleEntity

---@class Game
---
---# Simulation
---
---@field world World Game world
---@field time number Time of day in seconds, max is 24*60
---@field advanceClock fun(self: Game, dt: number) Advances in-game clock
---@field resources Resources Resources player may spend on upgrades
---
---@field score integer Score the player has accumulated
---@field addScore fun(self: Game, count: integer) Increases score count
---
---@field squad Squad A bunch of guys that follows player's movement
---
---@field player Guy A guy controlled by the player
---@field guyDelegate GuyDelegate Object that talks to guys
---@field frozenGuys { [Guy]: true } Guys that shouldn't be rendered nor updated
---@field guys Guy[] Guys aka units
---@field addGuy fun(self: Game, guy: Guy) Adds a guy into the world
---@field freezeGuy fun(self: Game, guy: Guy) Freezes a guy
---@field unfreezeGuy fun(self: Game, guy: Guy) Unfreezes a guy
---@field removeGuy fun(self: Game, guy: Guy) Removes the guy from the game
---
---@field texts Text[] Text objects in the game world
---@field addText fun(self: Game, text: Text) Adds the text in the game world
---@field entities GameEntity[] Things in the game world
---@field addEntity fun(self: Game, entity: GameEntity) Adds a building to the world
---@field removeEntity fun(self: Game, entity: GameEntity) Adds a building to the world
---@field beginBattle fun(self: Game, attacker: Guy, defender: Guy): nil
---
---@field collider fun(self: Game, v: Vector): CollisionInfo Function that performs collision checks between game world objects
---
---# Game flow
---
---@field isFocused boolean True if focus mode is on
---@field onLost (fun(): nil) | nil Called when game is lost
---
---@field toggleFocus fun(self: Game) Toggles focus mode
---@field disableFocus fun(self: Game) Turns focus mode off
---
---# UI
---
---@field ui UI User interface root
---@field console Console Bottom console
---@field activeTab integer Current active tab in the focus screen
---
---@field cursorPos Vector Points to a square player's cursor is aimed at
---@field recruitCircle RecruitCircle Circle thing used to recruit units
---@field nextTab fun(self: Game) Switches tab in the UI
---
---# GFX
---
---@field makeVisionSourcesCo fun(self: Game): fun(): VisionSource Returns a coroutine function that will yield all vision sources in the game world
---
---@field magnificationFactor number How much the camera is zoomed in
---@field nextMagnificationFactor fun(self: Game) Switches magnification factor to a different one

local WHITE_PANEL_COLOR = { r = 1, g = 1, b = 1, a = 1 }
local BLACK_PANEL_COLOR = { r = 0, g = 0, b = 0, a = 1 }
local GRAY_PANEL_COLOR = { r = 0.5, g = 0.5, b = 0.5, a = 1 }
local DARK_GRAY_PANEL_COLOR = { r = 0.25, g = 0.25, b = 0.25, a = 1 }
---@type Vector
local EVIL_SPAWN_LOCATION = { x = 281, y = 195 }

local SCORES_TABLE = {
  killedAnEnemy = 100,
  builtAHouse = 500,
}

---@type CollisionInfo
local NONE_COLLISION = { type = 'none' }
---@type CollisionInfo
local TERRAIN_COLLISION = { type = 'terrain' }

---@param game Game
---@param guy Guy
---@return boolean
local function isFrozen(game, guy)
  return game.frozenGuys[guy] or false
end

---@param guy Guy
local function isAtFullHealth(guy)
  return guy.stats.hp >= guy.stats.maxHp
end

---@param guy Guy
local function isGoodGuy(guy)
  return guy.team == 'good'
end

---@param game Game
---@param pos Vector
---@return Guy | nil
local function findGuyAtPos(game, pos)
  return tbl.find(game.guys, function (guy)
    return vector.equal(guy.pos, pos)
  end)
end

---@param game Game
---@param pos Vector
---@return GameEntity | nil
local function findEntityAtPos(game, pos)
  return tbl.find(game.entities, function (entity)
    return vector.equal(entity.object.pos, pos)
  end)
end

---@param delegate UIDelegate
local function makeUIScript(delegate)
  return ui.makeRoot({}, {
    ---@type PanelUI
    ui.makePanel(ui.origin(), 320, 8, GRAY_PANEL_COLOR, {
      coloredText = delegate.topPanelText,
    }),
    ---@type PanelUI
    ui.makePanel(ui.origin():translate(0, 8), 88, 184, GRAY_PANEL_COLOR, {
      shouldDraw = delegate.shouldDrawFocusModeUI,
      text = delegate.leftPanelText,
    }),
    -- Empty underlay for console
    ---@type PanelUI
    ui.makePanel(ui.origin():translate(88, 144), 320-80, 52, DARK_GRAY_PANEL_COLOR, {
      shouldDraw = delegate.shouldDrawFocusModeUI,
    }),
    ui.makePanel(ui.origin():translate(320-88, 8), 88, 200-16-52+4, BLACK_PANEL_COLOR, {
      shouldDraw = delegate.shouldDrawFocusModeUI,
      text = delegate.rightPanelText,
    }),
    ---@type PanelUI
    ui.makePanel(ui.origin():translate(0, 192), 320, 8, GRAY_PANEL_COLOR, {
      text = delegate.bottomPanelText,
    }),
    -- Pause icon
    ui.makePanel(ui.origin():translate(92, 132), 3, 8, WHITE_PANEL_COLOR, {
      shouldDraw = delegate.shouldDrawFocusModeUI,
    }),
    ui.makePanel(ui.origin():translate(97, 132), 3, 8, WHITE_PANEL_COLOR, {
      shouldDraw = delegate.shouldDrawFocusModeUI,
    }),
  })
end

---@param game Game
---@return GuyDelegate
local function makeGuyDelegate(game)
  ---@type GuyDelegate
  local guyDelegate = {
    beginBattle = function (attacker, defender)
      game:beginBattle(attacker, defender)
    end,
    enterHouse = function (guy, entity)
      if isAtFullHealth(guy) then
        return 'shouldNotMove'
      end
      guy.stats:heal()
      game:removeEntity(entity)
      return 'shouldMove'
    end,
    collider = function (pos)
      return game:collider(pos)
    end,
  }
  return guyDelegate
end

---@return Game
local function makeGame()
  ---@type Game
  local game

  local player = Guy.makeLeader({ x = 269, y = 231 })
  player:rename('Leader')

  ---@type Guy[]
  local guys = {
    player,
    Guy.makeGoodGuy({ x = 274, y = 231 }),
    Guy.makeGoodGuy({ x = 272, y = 231 }),
    Guy.makeGoodGuy({ x = 274, y = 229 }),
    Guy.makeGoodGuy({ x = 272, y = 229 }),
  }

  ---@type Game
  game = {
    world = loadWorld('map.png'),
    activeTab = 0,
    score = 0,
    buildings = {
      { pos = { x = 277, y = 233 } }
    },
    console = makeConsole(),
    frozenGuys = tbl.weaken({}, 'k'),
    resources = makeResources(),
    guys = guys,
    time = math.random() * 24 * 60,
    entities = {},
    player = player,
    squad = makeSquad(),
    recruitCircle = makeRecruitCircle(),
    onLost = nil,
    cursorPos = player.pos,
    magnificationFactor = 1,
    isFocused = false,
    texts = {},
    makeVisionSourcesCo = function (self)
      return function ()
        coroutine.yield({ pos = self.player.pos, sight = 10 })

        for _, guy in ipairs(self.guys) do
          if isGoodGuy(guy) then
            coroutine.yield({ pos = guy.pos, sight = 8 })
          end
        end

        return {
          pos = self.cursorPos,
          sight = math.max(2, self.recruitCircle.radius or 0),
        }
      end
    end,
    collider = function(self, v)
      local someoneThere = findGuyAtPos(self, v)
      if someoneThere then
        return { type = 'guy', guy = someoneThere }
      end
      local someEntityThere = findEntityAtPos(self, v)
      if someEntityThere then
        return { type = 'entity', entity = someEntityThere }
      end
      if isPassable(self.world, v) then
        return NONE_COLLISION
      end
      return TERRAIN_COLLISION
    end,

    -- Methods

    addScore = function(self, count)
      self.score = self.score + count
    end,
    removeGuy = function (self, guy)
      maybeDrop(self.guys, guy)
      self.squad:remove(guy)
      self.frozenGuys[guy] = nil

      if guy == game.player and game.onLost then
        game.onLost()
      end
    end,
    addText = function (self, text)
      table.insert(self.texts, text)
    end,
    addEntity = function (self, entity)
      table.insert(self.entities, entity)
    end,
    toggleFocus = function (self)
      self.isFocused = not self.isFocused
    end,
    disableFocus = function (self)
      self.isFocused = false
    end,
    removeEntity = function (self, entity)
      local idx = tbl.indexOf(self.entities, entity)
      table.remove(self.entities, idx)
    end,
    freezeGuy = function (self, guy)
      self.frozenGuys[guy] = true
    end,
    advanceClock = function (self, dt)
      self.time = (self.time + dt) % (24 * 60)
    end,
    nextMagnificationFactor = function (self)
      if self.magnificationFactor == 1 then
        self.magnificationFactor = 2/3
      elseif self.magnificationFactor == 2/3 then
        self.magnificationFactor = 2
      else
        self.magnificationFactor = 1
      end
    end,
    addGuy = function (self, guy)
      table.insert(self.guys, guy)
    end,
    nextTab = function (self)
      self.activeTab = self.activeTab + 1
    end,
    unfreezeGuy = function (self, guy)
      self.frozenGuys[guy] = nil
    end,
    beginBattle = function (self, attacker, defender)
      self:freezeGuy(attacker)
      self:freezeGuy(defender)

      self:addEntity(makeBattleEntity(makeBattle(attacker, defender)))
    end
  }

  game.ui = makeUIScript(makeUIDelegate(game, player))
  game.guyDelegate = makeGuyDelegate(game)

  game:addText(
    makeText('Build house on rock.', { x = 269, y = 228 }, 9)
  )

  game:addText(
    makeText('\nGARDEN\n  o\n   f\n EDEN', { x = 280, y = 194 }, 8)
  )

  game.console:say(
    makeConsoleMessage('Welcome to Kobold Princess Simulator.', 10)
  )
  game.console:say(
    makeConsoleMessage('This is day 1 of your reign.', 10)
  )

  return game
end

---@param game Game
---@param guy Guy
---@return boolean
local function isGuyAPlayer(game, guy)
  return guy == game.player
end


---@param game Game
---@param guy Guy
---@return boolean
local function mayRecruit(game, guy)
  if not isRecruitCircleActive(game.recruitCircle) then return false end
  if isGuyAPlayer(game, guy) then return false end
  if isGuyAFollower(game.squad, guy) then return false end
  if not canRecruitGuy(guy) then return false end
  return vector.dist(guy.pos, game.cursorPos) < game.recruitCircle.radius + 0.5
end

-- Writers

---@param game Game
local function dismissSquad(game)
  for guy in pairs(game.squad.followers) do
    game.squad:remove(guy)
  end
end

---@param game Game
local function beginRecruiting(game)
  if game.isFocused then return end
  game.recruitCircle:reset()
end

---@param game Game
local function endRecruiting(game)
  for _, guy in ipairs(game.guys) do
    if mayRecruit(game, guy) then
      game.squad:add(guy)
    end
  end
  game.squad:startFollowing()
  game.recruitCircle:clear()
end

---@param game Game
local function isReadyForOrder(game)
  return game.player.mayMove
end

---@param game Game
---@param vec Vector
---@return 'shouldRetryOtherDirection' | 'shouldStop'
local function orderMove(game, vec)
  if game.isFocused then return 'shouldStop' end

  if game.squad.shouldFollow then
    for guy in pairs(game.squad.followers) do
      if not isFrozen(game, guy) then
        moveGuy(guy, vec, game.guyDelegate)
      end
    end
  end
  if not isFrozen(game, game.player) then
    if moveGuy(game.player, vec, game.guyDelegate) then
      return 'shouldStop'
    end
  end
  return 'shouldRetryOtherDirection'
end

---@param game Game
---@param text string
local function say(game, text)
  game.console:say(makeConsoleMessage(text, 6))
end

---@param game Game
---@param attacker Guy
---@param defender Guy
---@param damageModifier number
local function fight(game, attacker, defender, damageModifier)
  local attackerAction = rng.weightedRandom(attacker.abilities)
  local defenderAction = rng.weightedRandom(attacker.abilities)

  local attackerEffect = attackerAction.ability.combat
  local defenderEffect = defenderAction.ability.defence

  ---@param guy Guy
  ---@param damage number
  local function dealDamage(guy, damage)
    guy.stats:hurt(damage * damageModifier)
    say(game, string.format('%s got %s damage, has %s hp now.', guy.name, damage, guy.stats.hp))
  end

  if defenderEffect == ability.effects.defence.parry then
    if attackerEffect == ability.effects.combat.normalAttack then
      say(game, '%s attacked, but %s parried!')
      dealDamage(defender, 0)
    elseif attackerEffect == ability.effects.combat.miss then
      say(game, '%s attacked and missed, %s gets an extra turn!')
      fight(game, defender, attacker, damageModifier)
    elseif attackerEffect == ability.effects.combat.criticalAttack then
      say(game, '%s did a critical attack, but %s parried! They strike back with %sx damage.')
      fight(game, defender, attacker, damageModifier * 2)
    end
  elseif defenderEffect == ability.effects.defence.takeDamage then
    if attackerEffect == ability.effects.combat.normalAttack then
      say(game, '%s attacked! %s takes damage.')
      dealDamage(defender, attackerAction.weight)
    elseif attackerEffect == ability.effects.combat.miss then
      say(game, '%s attacked but missed!')
      dealDamage(defender, 0)
    elseif attackerEffect == ability.effects.combat.criticalAttack then
      say(game, '%s did a critical attack! %s takes %sx damage.')
      dealDamage(defender, attackerAction.weight * 2)
    end
  end
end

---@param game Game
---@param entity GameEntity_Battle
---@param dt number
local function updateBattle(game, entity, dt)
  local battle = entity.object
  battle:advanceTimer(dt)
  if battle.timer < 0 then
    fight(game, battle.attacker, battle.defender, 1)
    battle:swapSides()

    ---@param guy Guy
    local function die(guy)
      say(game, (guy.name .. ' dies with %s hp.'):format(guy.stats.hp))

      if guy.team == 'evil' then
        game.resources:addPretzels(1)
        game:addScore(SCORES_TABLE.killedAnEnemy)
      end

      game:removeGuy(guy)
    end

    if battle.attacker.stats.hp > 0 and battle.defender.stats.hp > 0 then
      -- Keep fighting
      battle:beginNewRound()
    else
      -- Fight is over
      game:removeEntity(entity)

      -- TODO: use events to die
      if battle.attacker.stats.hp <= 0 then
        die(battle.attacker)
      end

      if battle.defender.stats.hp <= 0 then
        die(battle.defender)
      end

      game:unfreezeGuy(battle.attacker)
      game:unfreezeGuy(battle.defender)
    end
  end
end

---@param console Console
---@param dt number
local function updateConsole(console, dt)
  for _, message in ipairs(console.messages) do
    message:fadeOut(dt)
  end
end

---@param game Game
---@param dt number
local function updateGame(game, dt)
  updateConsole(game.console, dt)
  game.recruitCircle:maybeGrow(dt)

  if game.isFocused then return end

  game:advanceClock(dt)

  for _, entity in ipairs(game.entities) do
    if entity.type == 'battle' then
      ---@cast entity any
      updateBattle(game, entity, dt)
    end
  end

  for _, guy in ipairs(game.guys) do
    if not isFrozen(game, guy) then
      updateGuy(guy, dt, game.guyDelegate)
    end
  end
end

local function orderFocus(game)
  game:toggleFocus()
end

---@param game Game
---@param guy Guy
local function maybeChop(game, guy)
  if isFrozen(game, guy) then return end

  local pos = guy.pos
  local tile = getTile(game.world, pos)
  if tile == 'forest' then
    game.resources:addWood(1)
    setTile(game.world, pos, 'grass')
    game:addGuy(Guy.makeEvilGuy(EVIL_SPAWN_LOCATION))
  end
end

local function orderChop(game)
  maybeChop(game, game.player)
  for guy in pairs(game.squad.followers) do
    maybeChop(game, guy)
  end
end

---@param game Game
local function orderBuild(game)
  -- Check if has enough resources
  if game.resources.wood < 5 then
    return
  end

  local pos = game.cursorPos

  -- Check if no other entities
  for _, entity in ipairs(game.entities) do
    if vector.equal(entity.object.pos, pos) then
      return
    end
  end

  -- Is building on rock?
  if getTile(game.world, pos) == 'rock' then
    game.resources:addStone(1)
    game:addGuy(Guy.makeStrongEvilGuy(EVIL_SPAWN_LOCATION))
    setTile(game.world, pos, 'sand')
  end

  -- Build
  game.resources:addWood(-5)
  game:addEntity(makeBuildingEntity(makeBuilding(pos)))
  game:addScore(SCORES_TABLE.builtAHouse)
  game:disableFocus()
end

---@param game Game
local function orderScribe(game)
  game:addText(makeText(string.format(
    '%c%c\n%c%c',
    randomLetterCode(),
    randomLetterCode(),
    randomLetterCode(),
    randomLetterCode()
  ), game.cursorPos, 4))

  game:disableFocus()
end

---@param game Game
local function orderSummon(game)
  if game.resources.pretzels <= 0 then
    return
  end

  game.resources:addPretzels(-1)
  local guy = Guy.makeGoodGuy({
    x = game.cursorPos.x,
    y = game.cursorPos.y
  })
  say(game, ('%s was summonned.'):format(guy.name))
  game:addGuy(guy)
  game.squad:add(guy)

  game:toggleFocus()
end

---@param game Game
---@param scancode string
local function handleInput(game, scancode)
  if scancode == 'tab' then
    game:nextTab()
  elseif scancode == 'b' then
    orderBuild(game)
  elseif scancode == 'm' then
    orderScribe(game)
  elseif scancode == 'r' then
    orderSummon(game)
  elseif scancode == 't' then
    warpGuy(game.player, game.cursorPos)
    game:disableFocus()
  elseif scancode == 'space' then
    orderFocus(game)
  end
end

return {
  dismissSquad = dismissSquad,
  handleInput = handleInput,
  orderChop = orderChop,
  orderMove = orderMove,
  updateGame = updateGame,
  orderFocus = orderFocus,
  beginRecruiting = beginRecruiting,
  endRecruiting = endRecruiting,
  isFrozen = isFrozen,
  mayRecruit = mayRecruit,
  isReadyForOrder = isReadyForOrder,
  makeGame = makeGame,
}