local draw = require('./draw')
local vector = require('./vector')

---@alias Collider fun(v: Vector): boolean

---@class Guy
---@field pos Vector
---@field pixie Pixie
---@field time number
---@field behavior 'none' | 'wander'
---@field team 'good' | 'evil'

---@class GuyDelegate
---@field collider Collider

---@type Guy
local Guy = {
  pos = { x = 0, y = 0 },
  time = 0,
  behavior = 'none',
  team = 'good',
}

---@param guy Guy
---@param vec Vector
---@param canMoveTo Collider
local function moveGuy(guy, vec, canMoveTo)
  local newPos = vector.add(guy.pos, vec)
  if canMoveTo(newPos) then
    guy.pos = newPos
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
      })[math.random(1, 4)], delegate.collider)
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