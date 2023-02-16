local vector = require('./vector')
local draw = require('./draw')

---@class World
---@field width integer
---@field height integer
---@field tiles love.SpriteBatch
---@field draw fun(self: World): nil
---@field isPassable fun(self: World, v: Vector): nil

local World = {
  width = 40,
  height = 26,
  tiles = nil,
}

---@param self World
function World:draw()
  love.graphics.draw(self.tiles)
end

---@return World
function World.new()
  local world = {}
  setmetatable(world, { __index = World })

  local tileset = draw.getTileset()

  world.tiles = love.graphics.newSpriteBatch(
    tileset.tiles,
    world.width * world.height
  )

  for x = 1, world.width do
    for y = 1, world.height do
      if world:isPassable{ x = x, y = y } then
        world.tiles:add(tileset.grass, x * 16, y * 16)
      else
        world.tiles:add(tileset.rock, x * 16, y * 16)
      end
    end
  end

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