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
--
---@class Text
---@field text string
---@field pos Vector
---@field maxWidth number

---@class Game
---@field world World
---@field frozenGuys { [Guy]: true }
---@field resources Resources
---@field guys Guy[]
---@field battles Battle[]
---@field player Guy
---@field squad Squad
---@field buildings Building[]
---@field lerpVec Vector
---@field magnificationFactor number
---@field recruitCircle number | nil
---@field isFocused boolean
---@field texts Text[]
---@field isFrozen fun(guy: Guy): boolean
---@field mayRecruit fun(guy: Guy): boolean
---@field collider Collider
---@field ui UI

local whiteColor = { 1, 1, 1, 1 }
local blackPanelColor = { r = 0, g = 0, b = 0, a = 1 }
local transparentPanelColor = { r = 0, g = 0, b = 0, a = 0 }
local grayColor = { 0.5, 0.5, 0.5, 1 }
local recruitCircleMaxRadius = 6
local recruitCircleGrowthSpeed = 6
local lerpSpeed = 5

---@type CollisionInfo
local noneCollision = { type = 'none' }
local terrainCollision = { type = 'terrain' }

---@param squad Squad
---@return integer
local function countFollowers(squad)
  local counter = 0
  for _ in pairs(squad.followers) do
    counter = counter + 1
  end
  return counter
end

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
      text = ''
        .. 'Move your troops with arrow keys.'
        .. '\n\n'
        .. 'Click on ground to focus.'
        .. '\n\n'
        .. 'Press 1, 2, 3, 4 to change window scale.'
        .. '\n\n'
        .. 'Press F to toggle follow mode.'
        .. '\n\n'
        .. 'G to dismiss squad.\n\nSpace to recruit units.'
        .. '\n\n'
        .. 'C to chop wood.'
        .. '\n\n'
        .. 'Z to switch camera zoom.',
      pos = { x = 268, y = 227 },
      maxWidth = 8,
    },
    {

      text = ''
        .. 'Your enemies are red. Bump into them to fight.'
        .. '\n\n'
        .. 'If your character dies, you lose.',
      pos = { x = 280, y = 227 },
      maxWidth = 9,
    },
  },
  ui = ui.makeRoot {
    ---@type PanelUI
    ui.makePanel(ui.origin(), 320, 8, blackPanelColor, {
      coloredText = function ()
        return {
          whiteColor,
          'Units: ',
          game.squad.shouldFollow and whiteColor or grayColor,
          '' .. countFollowers(game.squad)
        }
      end
    }),
    ---@type PanelUI
    ui.makePanel(ui.origin():translate(0, 8), 320, 32, transparentPanelColor, {
      text = function ()
        if game.isFocused then
          local tileUnderCursor = getTile(game.world, game.cursorPos) or '???'
          return string.format(
            'Terrain: %s\nCoords: (%s,%s)'
              .. '\nPress B to build a house (5 wood)'
              .. '\nPress S to scribe a message.',
            tileUnderCursor,
            game.cursorPos.x,
            game.cursorPos.y
          )
        else
          return ''
        end
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
  }
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
      timer = 1,
    })
  end,
  collider = game.collider,
}

function game:init()
  self.player = Guy.makeLeader({ x = 268, y = 227 })
  self.guys = {
    self.player,
    Guy.makeGoodGuy({ x = 269, y = 228 }),
    Guy.makeGoodGuy({ x = 269, y = 230 }),
    Guy.makeGoodGuy({ x = 270, y = 228 }),
    Guy.makeGoodGuy({ x = 270, y = 230 }),
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
  return vector.dist(guy.pos, game.player.pos) < game.recruitCircle + 0.5
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

function game:orderScribe()
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

local function fight(attacker, defender)
  if math.random() > 0.6 then
    return attacker, defender
  else
    return defender, attacker
  end
end

---@param dt number
function game:update(dt)
  game.lerpVec = vector.lerp(
    game.lerpVec,
    (not game.isFocused)
      and vector.midpoint(game.player.pos, game.cursorPos)
      or game.cursorPos,
    dt * lerpSpeed
  )

  for _, battle in ipairs(self.battles) do
    battle.timer = battle.timer - dt
    if battle.timer < 0 then
      maybeDrop(self.battles, battle)
      local winner, loser = fight(battle.attacker, battle.defender)
      unfreeze(winner)
      maybeDrop(game.guys, loser)
      game.squad.followers[loser] = nil
      if loser == game.player then
        game.onLost()
      end
    end
  end
  for _, guy in ipairs(self.guys) do
    if not game.isFrozen(guy) then
      updateGuy(guy, dt, guyDelegate)
    end
  end
  if self.recruitCircle ~= nil then
    self.recruitCircle = math.min(
      self.recruitCircle + dt * recruitCircleGrowthSpeed,
      recruitCircleMaxRadius
    )
  end
end

function game:orderFocus()
  game.isFocused = not game.isFocused
end

function game:orderBuild()
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
    game.magnificationFactor = 0.5
  elseif game.magnificationFactor == 0.5 then
    game.magnificationFactor = 2
  else
    game.magnificationFactor = 1
  end
end

return {
  game = game,
  switchMagn = switchMagn,
}