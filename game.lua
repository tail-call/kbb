local Guy = require('./guy').Guy
local canRecruitGuy = require('./guy').canRecruitGuy
local moveGuy = require('./guy').moveGuy
local warpGuy = require('./guy').warpGuy
local updateGuy = require('./guy').updateGuy
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

---@class Building
---@field pos Vector Building's position

---@class RecruitCircle
---@field radius number | nil
---@field growthSpeed number
---@field maxRadius number
---@field maybeGrow fun(self: RecruitCircle, dt: number)
---@field reset fun(self: RecruitCircle)
---@field clear fun(self: RecruitCircle)

---@class Squad
---@field shouldFollow boolean True if guys should follow the player
---@field followers { [Guy]: true } Guys in the squad
---# Methods
---@field remove fun(self: Squad, guy: Guy) Removes a guy from the squad
---@field add fun(self: Squad, guy: Guy) Adds a guy to the squad
---@field startFollowing fun(self: Squad) Squad will begin following the player

---@class Resources
---@field pretzels integer Amount of pretzels owned
---@field wood integer Amount of wood owned
---@field stone integer Amount of stone owned
---# Methods
---@field addPretzels fun(self: Resources, count: integer) Get more pretzels
---@field addWood fun(self: Resources, count: integer) Get more wood
---@field addStone fun(self: Resources, count: integer) Get more stone

---@class Battle
---@field attacker Guy Who initiated the battle
---@field defender Guy Who was attacked
---@field pos Vector Battle's location
---@field timer number Time before current round finishes
---@field round number Current round number
---# Methods
---@field swapSides fun(self: Battle) Swap attacker and defender
---@field advanceTimer fun(self: Battle, dt: number) Makes battle timer go down
---@field beginNewRound fun(self: Battle) Reset round timer

---@class Text Text object displayed in the world
---@field text string Text content
---@field pos Vector Position in the world
---@field maxWidth number Maximum width of displayed text

---@class VisionSource
---@field pos Vector Vision source's position
---@field sight integer Vision source's radius of sight

---@class GameEntity
---@field type string
---@field object any

---@class GameEntity_Building: GameEntity
---@field type 'building'
---@field object Building

---@class GameEntity_Battle: GameEntity
---@field type 'battle'
---@field object Battle
--
---@class GameEntity_Text: GameEntity
---@field type 'text'
---@field object Text

---@class UIDelegate
---@field topPanelText fun(): table Love2D colored text for top panel
---@field leftPanelText fun(): string Left panel text
---@field rightPanelText fun(): string Right panel text
---@field bottomPanelText fun(): string Bottom panel text
---@field shouldDrawFocusModeUI fun(): boolean True if should draw focus mode UI

---@class Game
---# Simulation
---@field world World Game world
---@field guyDelegate GuyDelegate Object that talks to guys
---@field collider Collider Object that performs collision checks between game world objects
---@field score integer Score the player has accumulated
---@field frozenGuys { [Guy]: true } Guys that shouldn't be rendered nor updated
---@field resources Resources Resources player may spend on upgrades
---@field entities GameEntity[] Things in the game world
---@field guys Guy[] Guys aka units
---@field player Guy A guy controlled by the player
---@field time number Time of day in seconds, max is 24*60
---@field squad Squad A bunch of guys that follows player's movement
---@field visionSourcesCo fun(): VisionSource Coroutine that will yield all vision sources in the game world
---@field texts Text[] Text objects in the game world
---# Game flow
---@field isFocused boolean True if focus mode is on
---@field onLost (fun(): nil) | nil
---# UI
---@field console Console Bottom console
---@field recruitCircle RecruitCircle Circle thing used to recruit units
---@field ui UI User interface script
---@field activeTab integer Current active tab in the focus screen
---@field cursorPos Vector Points to a square player's cursor is aimed at
---# GFX
---@field magnificationFactor number How much the camera is zoomed in
---# Methods
---@field toggleFollow fun(self: Game): nil Toggles follow mode on or off
---@field addScore fun(self: Game, count: integer): nil Increases score count
---@field removeGuy fun(self: Game, guy: Guy): nil Removes the guy from the game
---@field addText fun(self: Game, text: Text): nil Adds the text in the game world

local WHITE_COLOR = { 1, 1, 1, 1 }
local WHITE_PANEL_COLOR = { r = 1, g = 1, b = 1, a = 1 }
local BLACK_PANEL_COLOR = { r = 0, g = 0, b = 0, a = 1 }
local GRAY_PANEL_COLOR = { r = 0.5, g = 0.5, b = 0.5, a = 1 }
local DARK_GRAY_PANEL_COLOR = { r = 0.25, g = 0.25, b = 0.25, a = 1 }
---@type Vector
local EVIL_SPAWN_LOCATION = { x = 281, y = 195 }
local RECRUIT_CIRCLE_MAX_RADIUS = 6
local RECRUIT_CIRCLE_GROWTH_SPEED = 6
local BATTLE_ROUND_DURATION = 0.5

local SCORES_TABLE = {
  killedAnEnemy = 100,
  builtAHouse = 500,
}

---@type CollisionInfo
local NONE_COLLISION = { type = 'none' }
---@type CollisionInfo
local TERRAIN_COLLISION = { type = 'terrain' }

---@return RecruitCircle
local function makeRecruitCircle()
  ---@type RecruitCircle
  local recruitCircle = {
    radius = nil,
    maxRadius = RECRUIT_CIRCLE_MAX_RADIUS,
    growthSpeed = RECRUIT_CIRCLE_GROWTH_SPEED,
    reset = function(self)
      self.radius = 0
    end,
    clear = function(self)
      self.radius = nil
    end,
    maybeGrow = function (self, dt)
      if self.radius == nil then return end

      self.radius = math.min(
        self.radius + dt * self.growthSpeed,
        self.maxRadius
      )
    end
  }
  return recruitCircle
end

---@return Resources
local function makeResources()
  ---@type Resources
  local resources = {
    pretzels = 0,
    wood = 0,
    stone = 0,
    addPretzels = function (self, count)
      self.pretzels = self.pretzels + count
    end,
    addWood = function (self, count)
      self.wood = self.wood + count
    end,
    addStone = function (self, count)
      self.stone = self.stone + count
    end,
  }
  return resources
end

---@param game Game
---@param text string
local function echo(game, text)
  game.console:say(makeConsoleMessage(text, 6))
  while #game.console.messages >= 8 do
    game.console:removeTopMessage()
  end
end

---@param game Game
---@param guy Guy
local function freeze(game, guy)
  game.frozenGuys[guy] = true
end

---@param game Game
---@param guy Guy
local function unfreeze(game, guy)
  game.frozenGuys[guy] = nil
end

---@param game Game
---@param guy Guy
---@return boolean
local function isFrozen(game, guy)
  return game.frozenGuys[guy] or false
end

---@param guy Guy
local function healGuy(guy)
  guy.stats.hp = guy.stats.maxHp
end

---@param guy Guy
local function isAtFullHealth(guy)
  return guy.stats.hp >= guy.stats.maxHp
end

---@param game Game
---@param entity GameEntity
local function addEntity(game, entity)
  table.insert(game.entities, entity)
end

---@param game Game
---@param entity GameEntity
local function removeEntity(game, entity)
  local idx = tbl.indexOf(game.entities, entity)
  table.remove(game.entities, idx)
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
local function makeUI(delegate)
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

---@param content string
---@param pos Vector
---@param maxWidth number
local function makeText(content, pos, maxWidth)
  ---@type Text
  local text = {
    text = content,
    pos = pos,
    maxWidth = maxWidth,
  }
  return text
end

---@return Game
local function init()
  ---@type Game
  local game

  local player = Guy.makeLeader({ x = 269, y = 231 })
  player.name = 'Leader'

  ---@type UIDelegate
  local uiDelegate = {
    topPanelText = function()
      return {
        WHITE_COLOR,
        string.format(
          'Score: %d | FPS: %.1f\n%02d:%02d',
          game.score,
          love.timer.getFPS(),
          math.floor(game.time / 60),
          math.floor(game.time % 60)
        ),
      }
    end,
    leftPanelText = function ()
      local tileUnderCursor = getTile(game.world, game.cursorPos) or '???'
      return string.format(
        ''
          .. 'Time: %02d:%02d\n (paused)\n'
          .. 'Terrain:\n %s'
          .. '\nCoords:\n %sX %sY'
          .. '\nB] build\n (5 wood)'
          .. '\nM] message'
          .. '\nR] ritual'
          .. '\nT] warp',
        math.floor(game.time / 60),
        math.floor(game.time % 60),
        tileUnderCursor,
        game.cursorPos.x,
        game.cursorPos.y
      )
    end,
    rightPanelText = function ()
      local function charSheet(guy)
        return function ()
          return string.format(
            ''
              .. 'Name:\n %s\n'
              .. 'Rank:\n Harmless\n'
              .. 'Coords:\n %sX %sY\n'
              .. 'HP:\n %s/%s\n'
              .. 'Action:\n %.2f/%.2f\n',
            guy.name,
            guy.pos.x,
            guy.pos.y,
            guy.stats.hp,
            guy.stats.maxHp,
            guy.time,
            guy.speed
          )
        end
      end

      local function controls()
        return ''
          .. ' CONTROLS  \n'
          .. 'WASD:  move\n'
          .. 'LMB:recruit\n'
          .. 'Spc:  focus\n'
          .. '1234: scale\n'
          .. 'F:   follow\n'
          .. 'G:  dismiss\n'
          .. 'C:     chop\n'
          .. 'Z:     zoom\n'
      end

      local header = '<- Tab ->\n\n'
      local tabs = { charSheet(player), controls }
      local idx = 1 + (game.activeTab % #tabs)

      return header .. tabs[idx]()
    end,
    bottomPanelText = function ()
      return string.format(
        'Wood: %s | Stone: %s | Pretzels: %s',
        game.resources.wood,
        game.resources.stone,
        game.resources.pretzels
      )
    end,
    shouldDrawFocusModeUI = function()
      return game.isFocused
    end,
  }

  ---@type Guy[]
  local guys = {
    player,
    Guy.makeGoodGuy({ x = 274, y = 231 }),
    Guy.makeGoodGuy({ x = 272, y = 231 }),
    Guy.makeGoodGuy({ x = 274, y = 229 }),
    Guy.makeGoodGuy({ x = 272, y = 229 }),
  }

  ---@type ConsoleMessage[]
  local messages = {
    makeConsoleMessage('Welcome to Kobold Princess Simulator.', 10),
    makeConsoleMessage('This is day 1 of your reign.', 10),
  }

  ---@return VisionSource
  local function visionSourcesCo()
    coroutine.yield({ pos = game.player.pos, sight = 10 })

    for _, guy in ipairs(game.guys) do
      if isGoodGuy(guy) then
        coroutine.yield({ pos = guy.pos, sight = 8 })
      end
    end

    return {
      pos = game.cursorPos,
      sight = math.max(2, game.recruitCircle.radius or 0),
    }
  end

  ---@type Collider
  local function collider(nothing, v)
    local someoneThere = findGuyAtPos(game, v)
    if someoneThere then
      return { type = 'guy', guy = someoneThere }
    end
    local someEntityThere = findEntityAtPos(game, v)
    if someEntityThere then
      return { type = 'entity', entity = someEntityThere }
    end
    if isPassable(game.world, v) then
      return NONE_COLLISION
    end
    return TERRAIN_COLLISION
  end

  ---@type GuyDelegate
  local guyDelegate = {
    beginBattle = function (attacker, defender)
      freeze(game, attacker)
      freeze(game, defender)

        ---@type Battle
      local battle = {
        attacker = attacker,
        defender = defender,
        pos = defender.pos,
        round = 1,
        timer = BATTLE_ROUND_DURATION,
        swapSides = function (self)
          self.attacker, self.defender = self.defender, self.attacker
        end,
        advanceTimer = function (self, dt)
          self.timer = self.timer - dt
        end,
        beginNewRound = function (self)
          self.timer = BATTLE_ROUND_DURATION
        end
      }

      addEntity(game, {
        type = 'battle',
        object = battle
      })
    end,
    enterHouse = function (guy, entity)
      if isAtFullHealth(guy) then
        return false
      end
      healGuy(guy)
      removeEntity(game, entity)
      return true
    end,
    collider = collider,
  }

  ---@type Game
  game = {
    world = loadWorld('map.png'),
    guyDelegate = guyDelegate,
    activeTab = 0,
    score = 0,
    buildings = {
      { pos = { x = 277, y = 233 } }
    },
    console = makeConsole(messages),
    frozenGuys = tbl.weaken({}, 'k'),
    resources = makeResources(),
    guys = guys,
    time = math.random() * 24 * 60,
    entities = {},
    player = player,
    squad = {
      followers = {},
      shouldFollow = false,
      remove = function(self, guy)
        self.followers[guy] = nil
      end,
      add = function(self, guy)
        self.followers[guy] = true
      end,
      startFollowing = function(self)
        self.shouldFollow = true
      end,
    },
    recruitCircle = makeRecruitCircle(),
    onLost = nil,
    cursorPos = player.pos,
    magnificationFactor = 1,
    isFocused = false,
    texts = {},
    visionSourcesCo = visionSourcesCo,
    collider = collider,
    ui = makeUI(uiDelegate),

    -- Methods

    toggleFollow = function(self)
      self.squad.shouldFollow = not self.squad.shouldFollow
    end,
    addScore = function(self, count)
      self.score = self.score + count
    end,
    removeGuy = function (self, guy)
      maybeDrop(self.guys, guy)
      self.squad:remove(guy)

      if guy == game.player and game.onLost then
        game.onLost()
      end
    end,
    addText = function (self, text)
      table.insert(self.texts, text)
    end,
  }

  game:addText(makeText('Build house on rock.', { x = 269, y = 228 }, 9))
  game:addText(makeText('\nGARDEN\n  o\n   f\n EDEN', { x = 280, y = 194 }, 8))

  return game
end

---@param game Game
---@return boolean
local function isRecruitCircleActive(game)
  return game.recruitCircle.radius ~= nil
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
local function isGuyAFollower(game, guy)
  return game.squad.followers[guy] or false
end

---@param game Game
---@param guy Guy
---@return boolean
local function mayRecruit(game, guy)
  if not isRecruitCircleActive(game) then return false end
  if isGuyAPlayer(game, guy) then return false end
  if isGuyAFollower(game, guy) then return false end
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

local function endRecruiting(game)
  for _, guy in tbl.ifilter(game.guys, function (guy)
    return mayRecruit(game, guy)
  end) do
    game.squad:add(guy)
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
    echo(game, string.format('%s got %s damage, has %s hp now.', guy.name, damage, guy.stats.hp))
  end

  local function say(message)
    echo(game, string.format(
      message,
      attacker.name, defender.name, damageModifier
    ))
  end

  if defenderEffect == ability.effects.defence.parry then
    if attackerEffect == ability.effects.combat.normalAttack then
      say('%s attacked, but %s parried!')
      dealDamage(defender, 0)
    elseif attackerEffect == ability.effects.combat.miss then
      say('%s attacked and missed, %s gets an extra turn!')
      fight(game, defender, attacker, damageModifier)
    elseif attackerEffect == ability.effects.combat.criticalAttack then
      say('%s did a critical attack, but %s parried! They strike back with %sx damage.')
      fight(game, defender, attacker, damageModifier * 2)
    end
  elseif defenderEffect == ability.effects.defence.takeDamage then
    if attackerEffect == ability.effects.combat.normalAttack then
      say('%s attacked! %s takes damage.')
      dealDamage(defender, attackerAction.weight)
    elseif attackerEffect == ability.effects.combat.miss then
      say('%s attacked but missed!')
      dealDamage(defender, 0)
    elseif attackerEffect == ability.effects.combat.criticalAttack then
      say('%s did a critical attack! %s takes %sx damage.')
      dealDamage(defender, attackerAction.weight * 2)
    end
  end
end

---@param game Game
---@param dt number
local function advanceClock(game, dt)
  return (game.time + dt) % (24 * 60)
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
    local function maybeDie(guy)
      if guy.stats.hp <= 0 then
        echo(game, (guy.name .. ' dies with %s hp.'):format(guy.stats.hp))

        if guy.team == 'evil' then
          game.resources:addPretzels(1)
          game:addScore(SCORES_TABLE.killedAnEnemy)
        end

        game:removeGuy(guy)
      end
    end

    if battle.attacker.stats.hp > 0 and battle.defender.stats.hp > 0 then
      -- Keep fighting
      battle:beginNewRound()
    else
      -- Fight is over
      maybeDrop(game.entities, entity)
      maybeDie(battle.attacker)
      maybeDie(battle.defender)
      unfreeze(game, battle.attacker)
      unfreeze(game, battle.defender)
    end

    -- Next round
    battle.round = battle.round + 1
  end
end

---@param game Game
---@param dt number
local function updateBattles(game, dt)
  for _, entity in ipairs(game.entities) do
    if entity.type == 'battle' then
      ---@cast entity any
      updateBattle(game, entity, dt)
    end
  end
end

---@param game Game
---@param dt number
local function updateGuys(game, dt)
  for _, guy in ipairs(game.guys) do
    if not isFrozen(game, guy) then
      updateGuy(guy, dt, game.guyDelegate)
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

  game.time = advanceClock(game, dt)
  updateBattles(game, dt)
  updateGuys(game, dt)
end

local function orderFocus(game)
  game.isFocused = not game.isFocused
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
    table.insert(game.guys, Guy.makeEvilGuy(EVIL_SPAWN_LOCATION))
  end
end

local function orderChop(game)
  maybeChop(game, game.player)
  for guy in pairs(game.squad.followers) do
    maybeChop(game, guy)
  end
end

---@param game Game
local function switchMagn(game)
  if game.magnificationFactor == 1 then
    game.magnificationFactor = 2/3
  elseif game.magnificationFactor == 2/3 then
    game.magnificationFactor = 2
  else
    game.magnificationFactor = 1
  end
end

---@param game Game
local function orderBuild(game)
  if game.resources.wood < 5 then
    return
  end
  local pos = game.cursorPos
  for _, entity in ipairs(game.entities) do
    if vector.equal(entity.object.pos, pos) then
      return
    end
  end
  local t = getTile(game.world, pos)
  if t == 'rock' then
    game.resources:addStone(1)
    table.insert(game.guys, Guy.makeStrongEvilGuy(EVIL_SPAWN_LOCATION))
    setTile(game.world, pos, 'sand')
  end
  game.resources:addWood(-5)
  table.insert(game.entities, {
    type = 'building',
    object = { pos = pos }
  })
  game:addScore(SCORES_TABLE.builtAHouse)
  game.isFocused = false
end

---@return integer
local function randomLetterCode()
  local letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
  local idx = math.random(#letters)
  return string.byte(letters, idx)
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

  game.isFocused = false
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
  echo(game, ('%s was summonned.'):format(guy.name))
  table.insert(game.guys, guy)
  game.squad.followers[guy] = true

  game.isFocused = not game.isFocused
end

---@param game Game
---@param scancode string
local function handleInput(game, scancode)
  if scancode == 'tab' then
    game.activeTab = game.activeTab + 1
  elseif scancode == 'b' then
    orderBuild(game)
  elseif scancode == 'm' then
    orderScribe(game)
  elseif scancode == 'r' then
    orderSummon(game)
  elseif scancode == 't' then
    warpGuy(game.player, game.cursorPos)
    game.isFocused = false
  elseif scancode == 'space' then
    orderFocus(game)
  end
end

return {
  dismissSquad = dismissSquad,
  handleInput = handleInput,
  orderChop = orderChop,
  orderMove = orderMove,
  echo = echo,
  updateGame = updateGame,
  orderFocus = orderFocus,
  beginRecruiting = beginRecruiting,
  endRecruiting = endRecruiting,
  switchMagn = switchMagn,
  isFrozen = isFrozen,
  mayRecruit = mayRecruit,
  isReadyForOrder = isReadyForOrder,
  init = init,
}