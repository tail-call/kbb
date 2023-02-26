local Guy = require('./guy').Guy
local canRecruitGuy = require('./guy').canRecruitGuy
local moveGuy = require('./guy').moveGuy
local updateGuy = require('./guy').updateGuy
local World = require('./world').World
local drawWorld = require('./world').drawWorld
local isPassable = require('./world').isPassable
local draw = require('./draw')
local tbl = require('./tbl')
local vector = require('./vector')

local recruitCircleMaxRadius = 6
local recruitCircleGrowthSpeed = 6

local instructions = ''
  .. 'Move your troops with arrow keys.'
  .. '\n\n'
  .. 'Press 1, 2, 3, 4 to change window scale.'
  .. '\n\n'
  .. 'Press F to toggle follow mode.'
  .. '\n\n'
  .. 'G to dismiss squad.\n\nSpace to recruit units.'

---@type CollisionInfo
local noneCollision = { type = 'none' }

---@class Battle
---@field attacker Guy
---@field defender Guy
---@field pos Vector
---@field timer number

local game = {
  ---@type World
  world = nil,
  ---@type { [Guy]: true }
  frozenGuys = tbl.weaken({}, 'k'),
  ---@type Guy[]
  guys = {},
  ---@type Battle[]
  battles = {},
  ---@type Guy
  player = nil,
  squad = {},
  ---@type Vector
  lerpVec = { x = 0, y = 0 },
  recruitCircle = nil,
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
    return { type = 'terrain' }
  end
  if isPassable(game.world, v) then
    return noneCollision
  end
  return { type = 'terrain' }
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
  self.player = Guy.makeLeader({ x = 10, y = 9 })
  self.guys = {
    self.player,
    Guy.makeGoodGuy({ x = 11, y = 10 }),
    Guy.makeGoodGuy({ x = 12, y = 10 }),
    Guy.makeGoodGuy({ x = 11, y = 11 }),
    Guy.makeGoodGuy({ x = 12, y = 11 }),
    Guy.makeEvilGuy({ x = 20, y = 9 }),
    Guy.makeEvilGuy({ x = 21, y = 9 }),
    Guy.makeEvilGuy({ x = 22, y = 9 }),
    Guy.makeEvilGuy({ x = 20, y = 10 }),
    Guy.makeEvilGuy({ x = 21, y = 10 }),
    Guy.makeEvilGuy({ x = 22, y = 10 }),
    Guy.makeEvilGuy({ x = 20, y = 11 }),
    Guy.makeEvilGuy({ x = 21, y = 11 }),
    Guy.makeEvilGuy({ x = 22, y = 11 }),
  }
  self.world = World.new()
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
  if tbl.has(self.squad.followers, guy) then return false end
  if not canRecruitGuy(guy) then return false end
  return vector.dist(guy.pos, self.player.pos) < self.recruitCircle + 0.5
end

function game:drawRecruitables()
  if not self.recruitCircle then return end

  for _, guy in tbl.ifilter(self.guys, function (guy)
    return self:mayRecruit(guy)
  end) do
    draw.recruitableHighlight(guy.pos)
  end
end

function game:toggleFollow()
  self.squad.shouldFollow = not self.squad.shouldFollow
end

function game:dismissSquad()
  self.squad.followers = {}
end

function game:beginRecruiting()
  self.recruitCircle = 0
end

function game:endRecruiting()
  for _, guy in tbl.ifilter(self.guys, function (guy)
    return self:mayRecruit(guy)
  end) do
    table.insert(self.squad.followers, guy)
  end
  self.squad.shouldFollow = true
  self.recruitCircle = nil
end

function game:orderMove(vec)
  if self.squad.shouldFollow then
    for _, guy in ipairs(self.squad.followers) do
      if not isFrozen(guy) then
        moveGuy(guy, vec, guyDelegate)
      end
    end
  end
  if not isFrozen(self.player) then
    moveGuy(self.player, vec, guyDelegate)
  end
end

function game:draw()
  love.graphics.push('transform')

  self.lerpVec = vector.lerp(self.lerpVec, self.player.pos, 0.04)

  draw.centerCameraOn(self.lerpVec)
  drawWorld(self.world)

  love.graphics.printf(
    instructions,
    16 * 3, 16 * 6,
    16 * 8
  )

  draw.drawGuys(self.guys, isFrozen)

  self:drawRecruitables()

  for _, battle in ipairs(game.battles) do
    draw.battle(battle.pos)
  end

  if self.recruitCircle then
    draw.recruitCircle(self.player.pos, self.recruitCircle)
  end

  love.graphics.pop()
  draw.hud(
    #self.squad.followers,
    self.squad.shouldFollow,
    self.player.pos
  )
end

---@param dt number
function game:update(dt)
  for _, battle in ipairs(self.battles) do
    battle.timer = battle.timer - dt
    if battle.timer < 0 then
      maybeDrop(self.battles, battle)
      if math.random() > 0.5 then
        unfreeze(battle.attacker)
        maybeDrop(game.guys, battle.defender)
      else
        unfreeze(battle.defender)
        maybeDrop(game.guys, battle.attacker)
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

return game