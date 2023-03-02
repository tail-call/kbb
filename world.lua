local vector = require('./vector')
local draw = require('./draw')

---@alias WorldTile 'grass' | 'rock' | 'water' | 'forest' | 'sand'

---@class World
---@field width integer
---@field height integer
---@field tiles love.SpriteBatch
---@field tileTypes WorldTile[]

---@param world World
local function drawWorld(world)
  love.graphics.draw(world.tiles)
end

---@param v Vector
---@return boolean
local function isWater(v)
  return v.x > 10 and v.x < 20 and v.y > 4 and v.y < 8
end

---@param v Vector
---@return boolean
local function isForest(v)
  return v.x >= 3 and v.x <= 38 and v.y >= 18 and v.y <= 24
end

---@param world World
---@param v Vector
---@return boolean
local function isGrass(world, v)
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
    or v.y == world.height
  then
    return false
  else
    return true
  end
end


---@return World
local function newWorld()
  local tileset = draw.getTileset()

  local width = 40
  local height = 26

  ---@type World
  local world = {
    width = width,
    height = height,
    tiles = love.graphics.newSpriteBatch(
      tileset.tiles,
      width * height
    ),
    tileTypes = {}
  }

  for y = 1, world.height do
    for x = 1, world.width do
      if isWater{ x = x, y = y } then
        world.tiles:add(tileset.quads.water, x * 16, y * 16)
        table.insert(world.tileTypes, 'water')
      elseif isForest{ x = x, y = y } then
        world.tiles:add(tileset.quads.forest, x * 16, y * 16)
        table.insert(world.tileTypes, 'forest')
      elseif isGrass(world, { x = x, y = y }) then
        world.tiles:add(tileset.quads.grass, x * 16, y * 16)
        table.insert(world.tileTypes, 'grass')
      else
        world.tiles:add(tileset.quads.rock, x * 16, y * 16)
        table.insert(world.tileTypes, 'rock')
      end
    end
  end

  return world
end

---@param filename string
---@return World
local function loadWorld(filename)
  local tileset = draw.getTileset()
  local data = love.image.newImageData(filename)

  local width = data:getWidth()
  local height = data:getHeight()

  ---@type World
  local world = {
    width = width,
    height = height,
    tiles = love.graphics.newSpriteBatch(
      tileset.tiles,
      width * height
    ),
    tileTypes = {}
  }

  for y = 0, data:getHeight() - 1 do
    for x = 0, data:getWidth() - 1 do
      local r, g, b = data:getPixel(x, y)
      r = math.floor(r*2)/2
      g = math.floor(g*2)/2
      b = math.floor(b*2)/2
      if r == 0 and g == 0 and b == 1 then
        world.tiles:add(tileset.quads.water, (x + 1) * 16, (y + 1) * 16)
        table.insert(world.tileTypes, 'water')
      elseif r == 0 and g == 0.5 and b == 0 then
        world.tiles:add(tileset.quads.forest, (x + 1) * 16, (y + 1) * 16)
        table.insert(world.tileTypes, 'forest')
      elseif r == 0.5 and g == 0.5 and b == 0.5 then
        world.tiles:add(tileset.quads.rock, (x + 1) * 16, (y + 1) * 16)
        table.insert(world.tileTypes, 'rock')
      elseif r == 1 and g == 1 and b == 0 then
        world.tiles:add(tileset.quads.sand, (x + 1) * 16, (y + 1) * 16)
        table.insert(world.tileTypes, 'sand')
      else
        world.tiles:add(tileset.quads.grass, (x + 1) * 16, (y + 1) * 16)
        table.insert(world.tileTypes, 'grass')
      end
    end
  end

  return world
end

---@param world World
---@param v Vector
---@return integer
local function vToTile(world, v)
  return (v.y - 1) * world.width + v.x
end

---@param world World
---@param v Vector
local function isPassable(world, v)
  local t = world.tileTypes[vToTile(world, v)]
  return t == 'grass' or t == 'forest' or t == 'sand'
end

---@param world World
---@param v Vector
---@param t WorldTile
local function setTile(world, v, t)
  local tileset = draw.getTileset()

  local id = vToTile(world, v)
  world.tileTypes[id] = t
  world.tiles:set(id, tileset.quads[t], v.x * 16, v.y * 16)
end

---@param world World
---@param v Vector
---@return WorldTile
local function getTile(world, v)
  return world.tileTypes[vToTile(world, v)]
end

return {
  newWorld = newWorld,
  drawWorld = drawWorld,
  isPassable = isPassable,
  setTile = setTile,
  getTile = getTile,
  loadWorld = loadWorld,
}