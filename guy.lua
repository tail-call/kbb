local draw = require('./draw')
local vector = require('./vector')

---@alias Collider fun(v: Vector): boolean

---@class Guy
---@field pos Vector
---@field pixie Pixie
---@field color number[]
---@field update fun(self: Guy, dt: number): nil
---@field draw fun(self: Guy): nil
---@field move fun(self: Guy, vec: Vector, canMoveTo: Collider): nil

local Guy = {
  ---@type Vector
  pos = { x = 0, y = 0 },
  pixie = nil,
}

function Guy:update(dt)
  self.pixie:update(dt)
end

---@param self Guy
---@param vec Vector
---@param canMoveTo Collider
function Guy:move(vec, canMoveTo)
  local newPos = vector.add(self.pos, vec)
  if canMoveTo(newPos) then
    self.pos = newPos
  end
  self.pixie:move(self.pos)
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
  local time = math.random()
  local super = guy.update
  function guy:update(dt)
    super(guy, dt)
    time = time + dt
    while time > 0.25 do
      time = time % 0.25
      self:move(({
        vector.dir.up,
        vector.dir.down,
        vector.dir.left,
        vector.dir.right,
      })[math.random(1, 4)], collider)
    end
  end
end

function Guy.makeLeader()
  local guy = Guy.new{
    pos = { x = 5, y = 5 },
    color = { 1, 1, 0, 1 },
  }
  return guy
end

---@param coord integer
function Guy.makeGoodGuy(coord)
  local guy = Guy.new{ pos = { x = coord, y = coord } }
  return guy
end

---@param collider Collider
function Guy.makeEvilGuy(collider)
  local guy = Guy.new{
    pos = { x = 22, y = 6 },
    color = { 1, 0, 0, 1 },
  }
  addWanderBehavior(guy, collider)
  return guy
end

---@param self Guy
function Guy:draw()
  self.pixie:draw()
end


return { Guy = Guy }