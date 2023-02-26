local draw = require('./draw')
local vector = require('./vector')

---@class Guy
---@field pos Vector
---@field pixie Pixie
---@field time number
---@field behavior 'none' | 'wander'
---@field team 'good' | 'evil'

---@alias CollisionInfo { type: 'guy' | 'terrain' | 'none', guy: Guy | nil }
---@alias Collider fun(collidingGuy: Guy, v: Vector): CollisionInfo

---@class GuyDelegate
---@field collider Collider
---@field beginBattle fun(attacker: Guy, defender: Guy): nil

---@type Guy
local Guy = {
  pos = { x = 0, y = 0 },
  time = 0,
  behavior = 'none',
  team = 'good',
}

---@param guy Guy
---@param vec Vector
---@param delegate GuyDelegate
local function moveGuy(guy, vec, delegate)
  local newPos = vector.add(guy.pos, vec)
  local collision = delegate.collider(guy, newPos)
  if collision.type == 'none' then
    guy.pos = newPos
  elseif collision.type == 'guy' then
    if guy.team ~= collision.guy.team then
      guy.pos = newPos
      delegate.beginBattle(guy, collision.guy)
    end
  end
  guy.pixie:move(guy.pos)
end

---@param guy Guy
---@param dt number
---@param delegate GuyDelegate
local function updateGuy(guy, dt, delegate)
  guy.pixie:update(dt)
  if guy.behavior == 'wander' then
    guy.time = guy.time + dt
    while guy.time > 0.25 do
      guy.time = guy.time % 0.25
      moveGuy(guy, ({
        vector.dir.up,
        vector.dir.down,
        vector.dir.left,
        vector.dir.right,
      })[math.random(1, 4)], delegate)
    end
  end
end

---@return Guy
function Guy.new(props)
  ---@type Guy
  local guy = {}
  setmetatable(guy, { __index = Guy })
  guy.pos = props.pos or guy.pos
  guy.pixie = draw.makePixie('guy')
  guy.pixie.color = props.color or guy.pixie.color
  guy.pixie:move(guy.pos)
  return guy
end

---@param pos Vector
function Guy.makeLeader(pos)
  local guy = Guy.new{
    pos = pos,
    color = { 1, 1, 0, 1 },
  }
  return guy
end

---@param pos Vector
function Guy.makeGoodGuy(pos)
  local guy = Guy.new{ pos = pos }
  guy.team = 'good'
  return guy
end

---@param pos Vector
function Guy.makeEvilGuy(pos)
  local guy = Guy.new{
    pos = pos,
    color = { 1, 0, 0, 1 },
  }
  guy.time = math.random()
  guy.behavior = 'wander'
  guy.team = 'evil'
  return guy
end

local function canRecruitGuy(guy)
  return guy.team == 'good'
end

return {
  Guy = Guy,
  canRecruitGuy = canRecruitGuy,
  moveGuy = moveGuy,
  updateGuy = updateGuy,
}