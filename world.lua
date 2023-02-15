local vector = require('./vector')
local draw = require('./draw')

---@class World
---@field width integer
---@field height integer
---@field tiles integer[]
---@field draw fun(self: World): nil
---@field isPassable fun(self: World, v: Vector): nil

local World = {
  width = 40,
  height = 26,
  tiles = { }
}

---@param self World
function World:draw()
  for i = 1, self.width do
    for j = 1, self.height do
      if self:isPassable{ x = i, y = j } then
        draw.tile('grass', { x = i, y = j })
      else
        draw.tile('rock', { x = i, y = j })
      end
    end
  end
end

---@return World
function World.new()
  local world = {}
  setmetatable(world, { __index = World })
  return world
end

---@param v Vector
function World:isPassable(v)
  if vector.equal(v, { x = 4, y = 4 }) then
    return true
  end
  if vector.equal(v, { x = 16, y = 16 }) then
    return true
  end
  if
    v.x == 1
    or v.y == 4
    or v.x == self.width
    or v.y == 1
    or v.y == 16
    or v.y == self.height
  then
    return false
  else
    return true
  end
end

return { World = World }