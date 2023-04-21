---@alias WorldTile 'grass' | 'rock' | 'water' | 'forest' | 'sand' | 'void'

---@class World
---@field width integer
---@field height integer
---@field image love.Image
---@field tileTypes WorldTile[]
---@field fogOfWar number[] Number from 0 to 1

local getTileset = require('./tileset').getTileset
local calcVisionDistance = require('VisionSource').calcVisionDistance
local isVisible = require('VisionSource').isVisible

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
    tileTypes = {},
    fogOfWar = {}
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
      table.insert(world.fogOfWar, 0.0)
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

---@param world World
---@param x number
---@param y number
---@return number index
local function getWorldIndex(world, x, y)
  return world.width * (y - 1) + x
end

---@param game Game
---@param visionSource VisionSource
---@param light number
local function revealFogOfWar(game, visionSource, light)
  local world = game.world
  local pos = visionSource.pos
  local visionDistance = calcVisionDistance(visionSource, light)
  local vd2 = visionDistance ^ 2
  local posX = pos.x
  local posY = pos.y
  for y = posY - visionDistance, posY + visionDistance do
    for x = posX - visionDistance, posX + visionDistance do
      local alpha = 1
      if isVisible(vd2, visionSource, x, y) then
        -- Neighbor based shading
        for dy = -1, 1 do
          for dx = -1, 1 do
            if not isVisible(vd2, visionSource, x + dx, y + dy) then
              alpha = alpha - 1/8
            end
          end
        end
      else
        alpha = 0
      end
      local idx = getWorldIndex(world, x, y)
      world.fogOfWar[idx] = math.max(alpha, world.fogOfWar[idx] or 0)
    end
  end
end


return {
  newWorld = newWorld,
  isPassable = isPassable,
  setTile = setTile,
  getTile = getTile,
  loadWorld = loadWorld,
  getWorldIndex = getWorldIndex,
  revealFogOfWar = revealFogOfWar,
}