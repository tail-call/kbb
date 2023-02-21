local vector = require('./vector')
local draw = require('./draw')

---@class World
---@field width integer
---@field height integer
---@field tiles love.SpriteBatch

local World = {
  width = 40,
  height = 26,
  tiles = nil,
}

---@param world World
local function drawWorld(world)
  love.graphics.draw(world.tiles)
end

---@param v Vector
---@return boolean
local function isWater(v)
  return v.x > 10 and v.x < 20 and v.y > 4 and v.y < 8
end

---@param world World
---@param v Vector
---@return boolean
local function isPassable(world, v)
  if isWater(v) then
    return false
  end
  if vector.equal(v, { x = 4, y = 4 }) then
    return true
  end
  if vector.equal(v, { x = 16, y = 16 }) then
    return true
  end
  if
    v.x == 1
    or v.y == 4
    or v.x == world.width
    or v.y == 1
    or v.y == 16
    or v.y == world.height
  then
    return false
  else
    return true
  end
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
      if isWater{ x = x, y = y } then
        world.tiles:add(tileset.water, x * 16, y * 16)
      elseif isPassable(world, { x = x, y = y }) then
        world.tiles:add(tileset.grass, x * 16, y * 16)
      else
        world.tiles:add(tileset.rock, x * 16, y * 16)
      end
    end
  end

  return world
end

return {
  World = World,
  drawWorld = drawWorld,
  isPassable = isPassable,
}