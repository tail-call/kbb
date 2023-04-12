local Guy = require('./guy').Guy
local canRecruitGuy = require('./guy').canRecruitGuy
local moveGuy = require('./guy').moveGuy
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

---@class Text
---@field text string
---@field pos Vector
---@field maxWidth number

---@class VisionSource
---@field pos Vector
---@field sight integer

---@class Game
---@field world World
---@field frozenGuys { [Guy]: true }
---@field resources Resources
---@field guys Guy[]
---@field time number
---@field battles Battle[]
---@field player Guy
---@field squad Squad
---@field buildings Building[]
---@field lerpVec Vector
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

local whiteColor = { 1, 1, 1, 1 }
local blackPanelColor = { r = 0, g = 0, b = 0, a = 1 }
local grayPanelColor = { r = 0.5, g = 0.5, b = 0.5, a = 1 }
local recruitCircleMaxRadius = 6
local recruitCircleGrowthSpeed = 6
local lerpSpeed = 10
local battleRoundDuration = 0.5

---@type CollisionInfo
local noneCollision = { type = 'none' }
local terrainCollision = { type = 'terrain' }

---@type Game
local game
game = {
  ---@type World
  world = nil,
  frozenGuys = tbl.weaken({}, 'k'),
  resources = {
    pretzels = 1,
    wood = 0,
    stone = 10,
  },
  guys = {},
  time = math.random() * 24 * 60,
  battles = {},
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
      text = 'Move your troops with arrow keys.',
      pos = { x = 268, y = 227 },
      maxWidth = 8,
    },
    {
      text = 'Space to focus.',
      pos = { x = 268, y = 229 },
      maxWidth = 8,
    },
    {
      text = 'Press 1, 2, 3, 4 to change window scale.',
      pos = { x = 268, y = 231 },
      maxWidth = 8,
    },
    {
      text = 'Press F to toggle follow mode.',
      pos = { x = 268, y = 233 },
      maxWidth = 8,
    },
    {
      text = 'G to dismiss squad.',
      pos = { x = 268, y = 235 },
      maxWidth = 8,
    },
    {
      text = 'Click to recruit units.',
      pos = { x = 268, y = 237 },
      maxWidth = 8,
    },
    {
      text = 'C to chop wood.',
      pos = { x = 268, y = 239 },
      maxWidth = 8,
    },
    {
      text = 'Z to switch camera zoom.',
      pos = { x = 268, y = 241 },
      maxWidth = 8,
    },
    {
      text = 'Your enemies are red. Bump into them to fight.',
      pos = { x = 342, y = 189 },
      maxWidth = 9,
    },
    {
      text = 'If your character dies, you lose.',
      pos = { x = 342, y = 191 },
      maxWidth = 8,
    },
  },
  ui = ui.makeRoot({}, {
    ---@type PanelUI
    ui.makePanel(ui.origin(), 320, 8, blackPanelColor, {
      coloredText = function ()
        return {
          whiteColor,
          string.format(
            'HP: %s | Time: %02d:%02d | FPS: %.1f',
            game.player.stats.hp,
            math.floor(game.time / 60),
            math.floor(game.time % 60),
            love.timer.getFPS()
          ),
        }
      end
    }),
    ---@type PanelUI
    ui.makePanel(ui.origin():translate(0, 8), 320, 32, grayPanelColor, {
      shouldDraw = function ()
        return game.isFocused
      end,
      text = function ()
        local tileUnderCursor = getTile(game.world, game.cursorPos) or '???'
        return string.format(
          ''
            .. 'Terrain: %s'
            .. '\nCoords: (%s,%s)'
            .. '\nPress B to build a house (5 wood)'
            .. '\nPress M to scribe a message.',
          tileUnderCursor,
          game.cursorPos.x,
          game.cursorPos.y
        )
      end
    }),
    ---@type PanelUI
    ui.makePanel(ui.origin():translate(0, 192), 320, 8, blackPanelColor, {
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
  local battle = tbl.find(game.battles, function (battle)
    return vector.equal(battle.pos, v)
  end)
  if battle then
    return terrainCollision
  end
  if isPassable(game.world, v) then
    return noneCollision
  end
  return terrainCollision
end

---@generic T
---@param items T[]
---@param item T
local function maybeDrop(items, item)
  local i = tbl.indexOf(items, item)
  if not i then return end

  tbl.fastRemoveAtIndex(items, i)
end

---@type GuyDelegate
local guyDelegate = {
  beginBattle = function (attacker, defender)
    freeze(attacker)
    freeze(defender)

    table.insert(game.battles, {
      attacker = attacker,
      defender = defender,
      pos = defender.pos,
      round = 1,
      timer = battleRoundDuration,
    })
  end,
  collider = game.collider,
}

function game:init()
  self.player = Guy.makeLeader({ x = 266, y = 229 })
  self.guys = {
    self.player,
    Guy.makeGoodGuy({ x = 269, y = 228 }),
    Guy.makeGoodGuy({ x = 269, y = 230 }),
    Guy.makeGoodGuy({ x = 270, y = 228 }),
    Guy.makeGoodGuy({ x = 270, y = 230 }),
    -- Close to us, to the east
    Guy.makeEvilGuy({ x = 286, y = 230 }),
    Guy.makeEvilGuy({ x = 287, y = 230 }),
    Guy.makeEvilGuy({ x = 286, y = 231 }),
    Guy.makeEvilGuy({ x = 287, y = 231 }),
    -- To the north-east
    Guy.makeEvilGuy({ x = 364, y = 199 }),
    Guy.makeEvilGuy({ x = 364, y = 199 }),
    Guy.makeEvilGuy({ x = 364, y = 199 }),
    Guy.makeEvilGuy({ x = 364, y = 199 }),
    Guy.makeEvilGuy({ x = 364, y = 199 }),
    Guy.makeEvilGuy({ x = 364, y = 199 }),
    Guy.makeEvilGuy({ x = 364, y = 199 }),
    Guy.makeEvilGuy({ x = 364, y = 199 }),
    Guy.makeEvilGuy({ x = 364, y = 199 }),
    Guy.makeEvilGuy({ x = 364, y = 199 }),
    Guy.makeEvilGuy({ x = 364, y = 199 }),
    Guy.makeEvilGuy({ x = 364, y = 199 }),
    Guy.makeEvilGuy({ x = 364, y = 199 }),
    Guy.makeEvilGuy({ x = 364, y = 199 }),
    Guy.makeEvilGuy({ x = 364, y = 199 }),
    Guy.makeEvilGuy({ x = 364, y = 199 }),
    Guy.makeEvilGuy({ x = 364, y = 199 }),
    Guy.makeEvilGuy({ x = 364, y = 199 }),
    Guy.makeEvilGuy({ x = 364, y = 199 }),
  }
  self.buildings = {
    { pos = { x = 277, y = 233 } }
  }
  self.world = loadWorld('map.png')
  self.squad = {
    shouldFollow = true,
    ---@type Guy[]
    followers = tbl.weaken({}, 'k'),
  }
  self.lerpVec = self.player.pos
  self.cursorPos = self.player.pos
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

---@param attacker Guy
---@param defender Guy
---@param damageModifier number
local function fight(attacker, defender, damageModifier)
  local attackerAction = rng.weightedRandom(attacker.abilities)
  local defenderAction = rng.weightedRandom(attacker.abilities)

  local attackerEffect = attackerAction.ability.combat
  local defenderEffect = defenderAction.ability.defence

  ---@param guy Guy
  ---@param damage number
  local function dealDamage(guy, damage)
    print(string.format('   %s gets %s damage.', guy.name, damage))
    guy.stats.hp = guy.stats.hp - damage * damageModifier
    print(string.format('   %s has %s hp now.', guy.name, guy.stats.hp))
  end

  local function say(message)
    print(string.format(
      message,
      attacker.name, defender.name, damageModifier
    ))
  end

  if defenderEffect == ability.effects.defence.parry then
    if attackerEffect == ability.effects.combat.normalAttack then
      say('1. %s attacked, but %s parried!')
      dealDamage(defender, 0)
    elseif attackerEffect == ability.effects.combat.miss then
      say('2. %s attacked and missed, %s gets an extra turn!')
      fight(defender, attacker, damageModifier)
    elseif attackerEffect == ability.effects.combat.criticalAttack then
      say('3. %s did a critical attack, but %s parried! They strike back with %sx damage.')
      fight(defender, attacker, damageModifier * 2)
    end
  elseif defenderEffect == ability.effects.defence.takeDamage then
    if attackerEffect == ability.effects.combat.normalAttack then
      say('4. %s attacked! %s takes damage.')
      dealDamage(defender, attackerAction.weight)
    elseif attackerEffect == ability.effects.combat.miss then
      say('5. %s attacked but missed!')
      dealDamage(defender, 0)
    elseif attackerEffect == ability.effects.combat.criticalAttack then
      say('6. %s did a critical attack! %s takes %sx damage.')
      dealDamage(defender, attackerAction.weight * 2)
    end
  end
end

---@param game Game
---@param dt number
local function calcNewLerpVector(game, dt)
  return vector.lerp(
    game.lerpVec,
    (not game.isFocused)
      and vector.midpoint(game.player.pos, game.cursorPos)
      or game.cursorPos,
    dt * lerpSpeed
  )
end

---@param game Game
---@param dt number
local function advanceClock(game, dt)
  return (game.time + dt) % (24 * 60)
end

---@param game Game
---@param dt number
local function updateBattles(game, dt)
  for _, battle in ipairs(game.battles) do
    battle.timer = battle.timer - dt
    if battle.timer < 0 then
      fight(battle.attacker, battle.defender, 1)
      battle.attacker, battle.defender = battle.defender, battle.attacker

      ---@param guy Guy
      local function maybeDie(guy)
        if guy.stats.hp <= 0 then
          print((guy.name .. ' dies with %s hp.'):format(guy.stats.hp))
          maybeDrop(game.guys, guy)
          game.squad.followers[guy] = nil

          if guy == game.player and game.onLost then
            game.onLost()
          end
        end
      end

      if battle.attacker.stats.hp > 0 and battle.defender.stats.hp > 0 then
        -- Keep fighting
        battle.timer = battleRoundDuration
      else
        -- Fight is over
        maybeDrop(game.battles, battle)
        maybeDie(battle.attacker)
        maybeDie(battle.defender)
        unfreeze(battle.attacker)
        unfreeze(battle.defender)
      end

      -- Next round
      battle.round = battle.round + 1
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

---@param game Game
---@param dt number
local function updateGame(game, dt)
  game.lerpVec = calcNewLerpVector(game, dt)
  game.time = advanceClock(game, dt)
  updateBattles(game, dt)
  updateGuys(game, dt)
  updateRecruitCircle(game, dt)
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
  for _, building in ipairs(game.buildings) do
    if vector.equal(building.pos, pos) then
      return
    end
  end
  game.resources.wood = game.resources.wood - 5
  table.insert(game.buildings, { pos = pos })
  game.isFocused = false
end

---@param game Game
local function orderScribe(game)
  local function randomLetter()
    local letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    local idx = math.random(#letters)
    return string.byte(letters, idx)
  end
  table.insert(game.texts, {
    text = string.format(
      '%c%c\n%c%c',
      randomLetter(),
      randomLetter(),
      randomLetter(),
      randomLetter()
    ),
    pos = game.cursorPos,
    maxWidth = 4,
  })
  game.isFocused = false
end

---@param game Game
---@param scancode string
local function handleInput(game, scancode)
  if scancode == 'b' then
    orderBuild(game)
  end
  if scancode == 'm' then
    orderScribe(game)
  end
  if scancode == 'space' then
    game:orderFocus()
  end
end

return {
  game = game,
  switchMagn = switchMagn,
  updateGame = updateGame,
  handleInput = handleInput,
}