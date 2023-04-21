---@alias WorldTile 'grass' | 'rock' | 'water' | 'forest' | 'sand' | 'void' | 'snow' | 'cave' | 'wall'

---@class World
---@field width integer
---@field height integer
---@field image love.Image
---@field revealedTilesCount number
---@field tileTypes WorldTile[]
---@field fogOfWar number[] Number from 0 to 1

local FOG_REVEAL_SPEED = 1
local SQUARE_REVEAL_VALUE = 0.5

local calcVisionDistance = require('VisionSource').calcVisionDistance
local isVisible = require('VisionSource').isVisible

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
    revealedTilesCount = 0,
    tileTypes = {},
    fogOfWar = {}
  }

  local tileColors = {
    ['1,1,1'] = 'snow',
    ['0.5,0,0.5'] = 'wall',
    ['0,0.5,0.5'] = 'cave',
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
local function vectorToLinearIndex(world, v)
  return (v.y - 1) * world.width + v.x
end

---@param world World
---@param v Vector
local function isPassable(world, v)
  local t = world.tileTypes[vectorToLinearIndex(world, v)]
  return t == 'grass' or t == 'forest' or t == 'sand' or t == 'void' or t == 'cave' or t == 'snow'
end

---@param world World
---@param v Vector
---@param t WorldTile
local function setTile(world, v, t)
  local id = vectorToLinearIndex(world, v)
  world.tileTypes[id] = t
end

---@param world World
---@param v Vector
---@return WorldTile
local function getTile(world, v)
  return world.tileTypes[vectorToLinearIndex(world, v)]
end

---@param world World
---@param v Vector
---@return number transparency
local function getFog(world, v)
  return world.fogOfWar[vectorToLinearIndex(world, v)]
end

---@param world World
---@param visionSource VisionSource
---@param light number
---@param dt number
local function revealFogOfWar(world, visionSource, light, dt)
  local pos = visionSource.pos
  local visionDistance = calcVisionDistance(visionSource, light)
  local vd2 = visionDistance ^ 2
  local posX = pos.x
  local posY = pos.y
  local tmpVec = { x = 0, y = 0 }
  for y = posY - visionDistance, posY + visionDistance do
    for x = posX - visionDistance, posX + visionDistance do
      local alpha = 1
      if isVisible(vd2, visionSource, tmpVec) then
        -- Neighbor based shading
        for dy = -1, 1 do
          for dx = -1, 1 do
            tmpVec.x, tmpVec.y = x + dx, y + dy
            if not isVisible(vd2, visionSource, tmpVec) then
              alpha = alpha - 1/8
            end
          end
        end
      else
        alpha = 0
      end
      tmpVec.x, tmpVec.y = x, y
      local idx = vectorToLinearIndex(world, tmpVec)
      local oldValue = world.fogOfWar[idx] or 0
      local newValue = oldValue + alpha * dt * FOG_REVEAL_SPEED
      world.fogOfWar[idx] = math.max(newValue, oldValue)
      if oldValue < SQUARE_REVEAL_VALUE and newValue > SQUARE_REVEAL_VALUE then
        world.revealedTilesCount = world.revealedTilesCount + 1
      end
    end
  end
end


return {
  isPassable = isPassable,
  setTile = setTile,
  getTile = getTile,
  getFog = getFog,
  loadWorld = loadWorld,
  revealFogOfWar = revealFogOfWar,
  vectorToLinearIndex = vectorToLinearIndex,
}