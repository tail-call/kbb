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

---@class Building
---@field pos Vector

---@class Squad
---@field shouldFollow boolean
---@field followers { [Guy]: true }
---@field frozenGuys { [Guy]: true }

---@class Resources
---@field pretzels integer
---@field wood integer
---@field stone integer

---@class Battle
---@field attacker Guy
---@field defender Guy
---@field pos Vector
---@field timer number
---@field round number

---@class ConsoleMessage
---@field text string
---@field lifetime number

---@class Text
---@field text string
---@field pos Vector
---@field maxWidth number

---@class VisionSource
---@field pos Vector
---@field sight integer

---@class Game
---@field world World
---@field score integer
---@field frozenGuys { [Guy]: true }
---@field resources Resources
---@field entities GameEntity[]
---@field guys Guy[]
---@field time number
---@field player Guy
---@field squad Squad
---@field consoleMessages ConsoleMessage[]
---@field magnificationFactor number
---@field recruitCircle number | nil
---@field isFocused boolean
---@field texts Text[]
---@field collider Collider
---@field ui UI
---@field cursorPos Vector
---@field onLost (fun(): nil) | nil
---@field visionSourcesCo fun(): VisionSource
---@field isFrozen fun(guy: Guy): boolean
---@field mayRecruit fun(guy: Guy): boolean
---@field orderMove fun(self: Game, vec: Vector): nil
---@field isReadyForOrder fun(self: Game): boolean
---@field init fun(self: Game): nil
---@field update fun(self: Game, dt: number): nil
---@field orderFocus fun(self: Game): nil

---@class GameEntity
---@field type string
---@field object any

---@class BuildingGameEntity
---@field type 'building'
---@field object Building

---@class BattleGameEntity
---@field type 'battle'
---@field object Battle

local whiteColor = { 1, 1, 1, 1 }
local blackPanelColor = { r = 0, g = 0, b = 0, a = 1 }
local grayPanelColor = { r = 0.5, g = 0.5, b = 0.5, a = 1 }
local darkGrayPanelColor = { r = 0.25, g = 0.25, b = 0.25, a = 1 }
local evilSpawnLocation = { x = 281, y = 195 }
local recruitCircleMaxRadius = 6
local recruitCircleGrowthSpeed = 6
local battleRoundDuration = 0.5

local scoresTable = {
  killedAnEnemy = 100,
  builtAHouse = 500,
}

---@type CollisionInfo
local noneCollision = { type = 'none' }
local terrainCollision = { type = 'terrain' }

local activeTab = 0

---@type Game
local game
game = {
  ---@type World
  world = nil,
  score = 0,
  frozenGuys = tbl.weaken({}, 'k'),
  resources = {
    pretzels = 0,
    wood = 0,
    stone = 0,
  },
  guys = {},
  time = math.random() * 24 * 60,
  entities = {},
  ---@type Guy
  player = nil,
  squad = {
    frozenGuys = tbl.weaken({}, 'k'),
    followers = {},
    shouldFollow = false,
  },
  buildings = {},
  lerpVec = { x = 0, y = 0 },
  recruitCircle = nil,
  ---@type fun(): nil
  onLost = nil,
  ---@type Vector
  cursorPos = { x = 0, y = 0 },
  magnificationFactor = 1,
  isFocused = false,
  texts = {
    {
      text = 'Build house on rock.',
      pos = { x = 269, y = 228 },
      maxWidth = 9,
    },
    {
      text = '\nGARDEN\n  OF\n  OF\n EDEN',
      pos = { x = 280, y = 194 },
      maxWidth = 8,
    },
  },
  ui = ui.makeRoot({}, {
    ---@type PanelUI
    ui.makePanel(ui.origin(), 320, 8, grayPanelColor, {
      coloredText = function ()
        return {
          whiteColor,
          string.format(
            'Score: %d | FPS: %.1f\n%02d:%02d',
            game.score,
            love.timer.getFPS(),
            math.floor(game.time / 60),
            math.floor(game.time % 60)
          ),
        }
      end
    }),
    ---@type PanelUI
    ui.makePanel(ui.origin():translate(0, 8), 88, 184, grayPanelColor, {
      shouldDraw = function ()
        return game.isFocused
      end,
      text = function ()
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
      end
    }),
    -- Empty underlay for console
    ---@type PanelUI
    ui.makePanel(ui.origin():translate(88, 144), 320-80, 52, darkGrayPanelColor, {
      shouldDraw = function ()
        return game.isFocused
      end,
    }),
    ui.makePanel(ui.origin():translate(320-88, 8), 88, 200-16-52+4, blackPanelColor, {
      shouldDraw = function ()
        return game.isFocused
      end,
      text = function ()
        local text = '<- Tab ->\n\n'
        local charSheet = string.format(
          ''
            .. 'Name:\n %s\n'
            .. 'Rank:\n Harmless\n'
            .. 'Coords:\n %sX %sY\n'
            .. 'HP:\n %s/%s\n'
            .. 'Action:\n %.2f/%.2f\n',
          game.player.name,
          game.player.pos.x,
          game.player.pos.y,
          game.player.stats.hp,
          game.player.stats.maxHp,
          game.player.time,
          game.player.speed
        )
        local tips = ''
          .. 'Out of troops? Press space and R.\n\n'
          .. 'Move your troops with arrow keys.\n\n'
          .. 'Space to focus.\n\n'
          .. 'Click to recruit units.\n\n'

        local tips2 = ''
          .. 'Press 1, 2, 3, 4 to change window scale.\n\n'
          .. 'Press F to toggle follow mode.\n\n'
          .. 'G to dismiss squad.\n\n'

        local tips3 = ''
          .. 'C to chop wood.\n\n'
          .. 'Z to switch camera zoom.\n\n'

        local tips4 = ''
          .. 'Your enemies are red. Bump into them to fight.\n\n'
          .. 'If your character dies, you lose.\n\n'

        local tabs = { charSheet, tips, tips2, tips3, tips4 }

        local idx = 1 + (activeTab % #tabs)
        return text .. tabs[idx]
      end,
    }),
    ---@type PanelUI
    ui.makePanel(ui.origin():translate(0, 192), 320, 8, grayPanelColor, {
      text = function ()
        return string.format(
          'Wood: %s | Stone: %s | Pretzels: %s',
          game.resources.wood,
          game.resources.stone,
          game.resources.pretzels
        )
      end,
    }),
  })
}

---@param guy Guy
local function freeze(guy)
  game.frozenGuys[guy] = true
end

---@param guy Guy
local function unfreeze(guy)
  game.frozenGuys[guy] = nil
end

---@param guy Guy
---@return boolean
function game.isFrozen(guy)
  return game.frozenGuys[guy] or false
end

---@type Collider
function game.collider(nothing, v)
  local otherGuy = tbl.find(game.guys, function (guy)
    return vector.equal(guy.pos, v)
  end)
  if otherGuy then
    return { type = 'guy', guy = otherGuy }
  end
  local entity = tbl.find(game.entities, function (entity)
    return vector.equal(entity.object.pos, v)
  end)
  if entity then
    return { type = 'entity', entity = entity }
  end
  if isPassable(game.world, v) then
    return noneCollision
  end
  return terrainCollision
end

---@type GuyDelegate
local guyDelegate = {
  beginBattle = function (attacker, defender)
    freeze(attacker)
    freeze(defender)

    table.insert(game.entities, {
      type = 'battle',
      object = {
        attacker = attacker,
        defender = defender,
        pos = defender.pos,
        round = 1,
        timer = battleRoundDuration,
      }
    })
  end,
  enterHouse = function (guy, entity)
    if guy.stats.hp >= guy.stats.maxHp then
      return false
    end
    guy.stats.hp = guy.stats.maxHp
    local idx = tbl.indexOf(game.entities, entity)
    table.remove(game.entities, idx)
    return true
  end,
  collider = game.collider,
}

function game:init()
  self.player = Guy.makeLeader({ x = 269, y = 231 })
  self.guys = {
    self.player,
    Guy.makeGoodGuy({ x = 274, y = 231 }),
    Guy.makeGoodGuy({ x = 272, y = 231 }),
    Guy.makeGoodGuy({ x = 274, y = 229 }),
    Guy.makeGoodGuy({ x = 272, y = 229 }),
  }
  -- for _ = 1, 20 do
    -- table.insert(self.guys, Guy.makeEvilGuy(evilSpawnLocation))
  -- end
  self.buildings = {
    { pos = { x = 277, y = 233 } }
  }
  self.world = loadWorld('map.png')
  self.squad = {
    shouldFollow = true,
    ---@type Guy[]
    followers = tbl.weaken({}, 'k'),
  }
  self.cursorPos = self.player.pos
  self.consoleMessages = {
    {
      text = 'Welcome to Kobold Princess Simulator.',
      lifetime = 10,
    },
    {
      text = 'This is day 1 of your reign.',
      lifetime = 16,
    }
  }
end

---@param guy Guy
---@return boolean
 function game.mayRecruit(guy)
  if not game.recruitCircle then return false end
  if guy == game.player then return false end
  if game.squad.followers[guy] then return false end
  if not canRecruitGuy(guy) then return false end
  return vector.dist(guy.pos, game.cursorPos) < game.recruitCircle + 0.5
end

function game:toggleFollow()
  self.squad.shouldFollow = not self.squad.shouldFollow
end

function game:dismissSquad()
  for guy in pairs(self.squad.followers) do
    self.squad.followers[guy] = nil
  end
end

function game:beginRecruiting()
  if game.isFocused then return end
  self.recruitCircle = 0
end

function game:endRecruiting()
  for _, guy in tbl.ifilter(self.guys, function (guy)
    return game.mayRecruit(guy)
  end) do
    self.squad.followers[guy] = true
  end
  self.squad.shouldFollow = true
  self.recruitCircle = nil
end

function game:isReadyForOrder()
  return self.player.mayMove
end

function game:orderMove(vec)
  if game.isFocused then return end

  if self.squad.shouldFollow then
    for guy in pairs(self.squad.followers) do
      if not game.isFrozen(guy) then
        moveGuy(guy, vec, guyDelegate)
      end
    end
  end
  if not game.isFrozen(self.player) then
    moveGuy(self.player, vec, guyDelegate)
  end
end

function game.visionSourcesCo()
  coroutine.yield({ pos = game.player.pos, sight = 10 })

  for _, guy in ipairs(game.guys) do
    if guy.team == 'good' then
      coroutine.yield({ pos = guy.pos, sight = 8 })
    end
  end

  return {
    pos = game.cursorPos,
    sight = math.max(2, game.recruitCircle or 0),
  }
end

---@param game Game
---@param text string
local function echo(game, text)
  table.insert(game.consoleMessages, {
    text = text,
    lifetime = 6,
  })
  while #game.consoleMessages >= 8 do
    table.remove(game.consoleMessages, 1)
  end
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
    guy.stats.hp = guy.stats.hp - damage * damageModifier
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
---@param guy Guy
local function killGuy(game, guy)
  maybeDrop(game.guys, guy)
  game.squad.followers[guy] = nil

  if guy.team == 'evil' then
    game.resources.pretzels = game.resources.pretzels + 1
    game.score = game.score + scoresTable.killedAnEnemy
  end

  if guy == game.player and game.onLost then
    game.onLost()
  end
end

---@param game Game
---@param entity BattleGameEntity
---@param dt number
local function updateBattle(game, entity, dt)
  local battle = entity.object
  battle.timer = battle.timer - dt
  if battle.timer < 0 then
    fight(game, battle.attacker, battle.defender, 1)
    battle.attacker, battle.defender = battle.defender, battle.attacker

    ---@param guy Guy
    local function maybeDie(guy)
      if guy.stats.hp <= 0 then
        echo(game, (guy.name .. ' dies with %s hp.'):format(guy.stats.hp))
        killGuy(game, guy)
      end
    end

    if battle.attacker.stats.hp > 0 and battle.defender.stats.hp > 0 then
      -- Keep fighting
      battle.timer = battleRoundDuration
    else
      -- Fight is over
      maybeDrop(game.entities, entity)
      maybeDie(battle.attacker)
      maybeDie(battle.defender)
      unfreeze(battle.attacker)
      unfreeze(battle.defender)
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
    if not game.isFrozen(guy) then
      updateGuy(guy, dt, guyDelegate)
    end
  end
end

---@param game Game
---@param dt number
local function updateRecruitCircle(game, dt)
  if game.recruitCircle == nil then return end

  game.recruitCircle = math.min(
    game.recruitCircle + dt * recruitCircleGrowthSpeed,
    recruitCircleMaxRadius
  )
end

---@param consoleMessages ConsoleMessage[]
---@param dt number
local function updateConsole(consoleMessages, dt)
  for _, message in ipairs(consoleMessages) do
    message.lifetime = math.max(message.lifetime - dt, 0)
  end
end

---@param game Game
---@param dt number
local function updateGame(game, dt)
  updateConsole(game.consoleMessages, dt)
  updateRecruitCircle(game, dt)

  if game.isFocused then return end

  game.time = advanceClock(game, dt)
  updateBattles(game, dt)
  updateGuys(game, dt)
end

function game:orderFocus()
  game.isFocused = not game.isFocused
end

local function maybeChop(guy)
  if game.isFrozen(guy) then return end

  local pos = guy.pos
  local t = getTile(game.world, pos)
  if t == 'forest' then
    game.resources.wood = game.resources.wood + 1
    setTile(game.world, pos, 'grass')
    table.insert(game.guys, Guy.makeEvilGuy(evilSpawnLocation))
  end
end

function game:orderChop()
  maybeChop(game.player)
  for guy in pairs(game.squad.followers) do
    maybeChop(guy)
  end
end

local function switchMagn()
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
    game.resources.stone = game.resources.stone + 1
    table.insert(game.guys, Guy.makeStrongEvilGuy(evilSpawnLocation))
    setTile(game.world, pos, 'sand')
  end
  game.resources.wood = game.resources.wood - 5
  table.insert(game.entities, {
    type = 'building',
    object = { pos = pos }
  })
  game.score = game.score + scoresTable.builtAHouse
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
  table.insert(game.texts, {
    text = string.format(
      '%c%c\n%c%c',
      randomLetterCode(),
      randomLetterCode(),
      randomLetterCode(),
      randomLetterCode()
    ),
    pos = game.cursorPos,
    maxWidth = 4,
  })
  game.isFocused = false
end

---@param game Game
local function orderSummon(game)
  if game.resources.pretzels <= 0 then
    return
  end

  game.resources.pretzels = game.resources.pretzels - 1
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
    activeTab = activeTab + 1
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
    game:orderFocus()
  end
end

return {
  game = game,
  switchMagn = switchMagn,
  updateGame = updateGame,
  handleInput = handleInput,
  echo = echo,
}