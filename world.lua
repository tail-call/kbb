local draw = require('./draw')

---@alias WorldTile 'grass' | 'rock' | 'water' | 'forest' | 'sand'

---@class World
---@field width integer
---@field height integer
---@field tiles love.SpriteBatch
---@field tileTypes WorldTile[]

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
      local tileType
      if r == 0 and g == 0 and b == 1 then
        tileType = 'water'
      elseif r == 0 and g == 0.5 and b == 0 then
        tileType = 'forest'
      elseif r == 0.5 and g == 0.5 and b == 0.5 then
        tileType = 'rock'
      elseif r == 1 and g == 1 and b == 0 then
        tileType = 'sand'
      else
        tileType = 'grass'
      end
      world.tiles:add(tileset.quads[tileType], (x + 1) * 16, (y + 1) * 16)
      table.insert(world.tileTypes, tileType)
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
  isPassable = isPassable,
  setTile = setTile,
  getTile = getTile,
  loadWorld = loadWorld,
}