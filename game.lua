local Guy = require('./guy').Guy
local canRecruitGuy = require('./guy').canRecruitGuy
local moveGuy = require('./guy').moveGuy
local updateGuy = require('./guy').updateGuy
local loadWorld = require('./world').loadWorld
local setTile = require('./world').setTile
local getTile = require('./world').getTile
local drawWorld = require('./world').drawWorld
local isPassable = require('./world').isPassable
local draw = require('./draw')
local tbl = require('./tbl')
local vector = require('./vector')

---@class Building
---@field pos Vector

---@class Squad
---@field shouldFollow boolean
---@field followers { [Guy]: true }

---@class Resources
---@field pretzels integer
---@field wood integer
---@field stone integer

---@class Battle
---@field attacker Guy
---@field defender Guy
---@field pos Vector
---@field timer number

local recruitCircleMaxRadius = 6
local recruitCircleGrowthSpeed = 6

local instructions1 = ''
  .. 'Move your troops with arrow keys.'
  .. '\n\n'
  .. 'Press 1, 2, 3, 4 to change window scale.'
  .. '\n\n'
  .. 'Press F to toggle follow mode.'
  .. '\n\n'
  .. 'G to dismiss squad.\n\nSpace to recruit units.'
  .. '\n\n'
  .. 'C to chop wood.'
  .. '\n\n'
  .. 'B to biuld a house (5 wood).'

local instructions2 = ''
  .. 'Your enemies are red. Bump into them to fight.'
  .. '\n\n'
  .. 'If your character dies, you lose.'

---@type CollisionInfo
local noneCollision = { type = 'none' }
local terrainCollision = { type = 'terrain' }

local game = {
  ---@type World
  world = nil,
  ---@type { [Guy]: true }
  frozenGuys = tbl.weaken({}, 'k'),
  ---@type Resources
  resources = {
    pretzels = 1,
    wood = 0,
    stone = 10,
  },
  ---@type Guy[]
  guys = {},
  ---@type Battle[]
  battles = {},
  ---@type Guy
  player = nil,
  ---@type Squad
  squad = {
    frozenGuys = tbl.weaken({}, 'k'),
    shouldFollow = false,
  },
  ---@type Building[]
  buildings = {},
  ---@type Vector
  lerpVec = { x = 0, y = 0 },
  ---@type number | nil
  recruitCircle = nil,
  ---@type fun(): nil
  onLost = nil,
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
local function isFrozen(guy)
  return game.frozenGuys[guy] or false
end

---@type Collider
local function collider(collidingGuy, v)
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
  collider = collider,
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
    { pos = { x = 15, y = 14 } }
  }
  self.world = loadWorld('map.png')
  self.squad = {
    shouldFollow = true,
    ---@type Guy[]
    followers = { },
  }
end

---@param guy Guy
---@return boolean
function game:mayRecruit(guy)
  if guy == self.player then return false end
  if self.squad.followers[guy] then return false end
  if not canRecruitGuy(guy) then return false end
  return vector.dist(guy.pos, self.player.pos) < self.recruitCircle + 0.5
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
    return self:mayRecruit(guy)
  end) do
    self.squad.followers[guy] = true
  end
  self.squad.shouldFollow = true
  self.recruitCircle = nil
end

function game:orderMove(vec)
  if self.squad.shouldFollow then
    for guy in pairs(self.squad.followers) do
      if not isFrozen(guy) then
        moveGuy(guy, vec, guyDelegate)
      end
    end
  end
  if not isFrozen(self.player) then
    moveGuy(self.player, vec, guyDelegate)
  end
end

---@param squad Squad
---@return integer
local function countFollowers(squad)
  local counter = 0
  for _ in pairs(squad.followers) do
    counter = counter + 1
  end
  return counter
end

function game:draw()
  love.graphics.push('transform')

  self.lerpVec = vector.lerp(self.lerpVec, self.player.pos, 0.04)

  draw.centerCameraOn(self.lerpVec)

  drawWorld(self.world)

  draw.textAtTile(instructions1, { x = 268, y = 227 }, 8)
  draw.textAtTile(instructions2, { x = 280, y = 227 }, 9)

  for _, building in ipairs(game.buildings) do
    draw.house(building.pos)
  end

  draw.drawGuys(self.guys, isFrozen)

  if self.recruitCircle then
    for _, guy in tbl.ifilter(self.guys, function (guy)
      return self:mayRecruit(guy)
    end) do
      draw.recruitableHighlight(guy.pos)
    end
  end

  for _, battle in ipairs(game.battles) do
    draw.battle(battle.pos)
  end

  if self.recruitCircle then
    draw.recruitCircle(self.player.pos, self.recruitCircle)
  end

  love.graphics.pop()
  draw.hud(
    countFollowers(self.squad),
    self.squad.shouldFollow,
    self.player.pos,
    self.resources
  )
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
    if not isFrozen(guy) then
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

function game:orderBuild()
  if isFrozen(game.player) then
    return
  end
  if game.resources.wood < 5 then
    return
  end
  local pos = game.player.pos
  for _, building in ipairs(game.buildings) do
    if vector.equal(building.pos, pos) then
      return
    end
  end
  game.resources.wood = game.resources.wood - 5
  table.insert(game.buildings, { pos = pos })
end

local function maybeChop(guy)
  if isFrozen(guy) then return end

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

return game