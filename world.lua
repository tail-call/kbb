local getTileset = require('./tileset').getTileset

---@alias WorldTile 'grass' | 'rock' | 'water' | 'forest' | 'sand' | 'void'

---@class World
---@field width integer
---@field height integer
---@field image love.Image
---@field tileTypes WorldTile[]

---@return World
local function newWorld()
  local width = 40
  local height = 26

  ---@type World
  local world = {
    width = width,
    height = height,
    tileTypes = {}
  }

  return world
end

---@param filename string
---@return World
local function loadWorld(filename)
  local data = love.image.newImageData(filename)
  local image = love.graphics.newImage(data)

  local width = data:getWidth()
  local height = data:getHeight()

  ---@type World
  local world = {
    width = width,
    height = height,
    image = image,
    tileTypes = {}
  }

  local tileColors = {
    ['0,0,1'] = 'water',
    ['0,0.5,0'] = 'forest',
    ['0.5,0.5,0.5'] = 'rock',
    ['1,1,0'] = 'sand',
    ['0.5,0,0'] = 'void',
    default = 'grass',
  }

  for y = 0, data:getHeight() - 1 do
    for x = 0, data:getWidth() - 1 do
      local r, g, b = data:getPixel(x, y)
      r = math.floor(r*2)/2
      g = math.floor(g*2)/2
      b = math.floor(b*2)/2
      local tileType = tileColors[
        string.format('%s,%s,%s', r, g, b)
      ] or tileColors.default
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
  return t == 'grass' or t == 'forest' or t == 'sand' or t == 'void'
end

---@param world World
---@param v Vector
---@param t WorldTile
local function setTile(world, v, t)
  local tileset = getTileset()

  local id = vToTile(world, v)
  world.tileTypes[id] = t
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