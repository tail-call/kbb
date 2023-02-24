local draw = require('./draw')
local vector = require('./vector')

---@alias Collider fun(v: Vector): boolean

---@class Guy
---@field pos Vector
---@field pixie Pixie
---@field color number[]
---@field canRecruit boolean
---@field time number
---@field behavior 'none' | 'wander'

local Guy = {
  ---@type Vector
  pos = { x = 0, y = 0 },
  pixie = nil,
  time = 0,
  canRecruit = false,
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
---@param canMoveTo Collider
local function updateGuy(guy, dt, canMoveTo)
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
      })[math.random(1, 4)], canMoveTo)
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

---@param guy Guy
---@param collider Collider
local function addWanderBehavior(guy, collider)
  guy.time = math.random()
  guy.behavior = 'wander'
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
  guy.canRecruit = true
  return guy
end

---@param pos Vector
---@param collider Collider
function Guy.makeEvilGuy(pos, collider)
  local guy = Guy.new{
    pos = pos,
    color = { 1, 0, 0, 1 },
  }
  addWanderBehavior(guy, collider)
  return guy
end

local function canRecruitGuy(guy)
  return guy.canRecruit
end

local function drawGuy(guy)
  guy.pixie:draw()
end

return {
  Guy = Guy,
  canRecruitGuy = canRecruitGuy,
  drawGuy = drawGuy,
  moveGuy = moveGuy,
  updateGuy = updateGuy,
}