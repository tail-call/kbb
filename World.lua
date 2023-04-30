---@class World
---@field image love.Image Minimap image
---@field width integer World's width in squares
---@field height integer World's height in squares
---@field revealedTilesCount number Number of tiles player had revealed
---@field tileTypes WorldTile[] Tile types of each square in the world
---@field fogOfWar number[] How visible is each square in the world. Numbers from 0 to 1

---@class WorldMutator
---@field revealFogOfWar fun(self: World, pos: Vector, value: number, dt: number) Partially reveals fog of war over sime time dt

---@alias WorldTile
---| 'grass'
---| 'rock'
---| 'water'
---| 'forest'
---| 'sand'
---| 'void'
---| 'snow'
---| 'cave'
---| 'wall'

local M = require('Module').define(..., 0)

local calcVisionDistance = require('VisionSource').calcVisionDistance
local isVisible = require('VisionSource').isVisible

local FOG_REVEAL_SPEED = 1
local SQUARE_REVEAL_THRESHOLD = 0.5


---@type WorldMutator
M.mut = require('Mutator').new {
  revealFogOfWar = function (self, pos, value, dt)
    local idx = M.vectorToLinearIndex(self, pos)
    local oldValue = self.fogOfWar[idx] or 0
    local newValue = oldValue + value * dt * FOG_REVEAL_SPEED
    if newValue > 1 then
      newValue = 1
    end
    self.fogOfWar[idx] = newValue
    if oldValue < SQUARE_REVEAL_THRESHOLD and newValue > SQUARE_REVEAL_THRESHOLD then
      self.revealedTilesCount = self.revealedTilesCount + 1
    end
  end,
}

---@param world World
---@param v Vector
---@return integer
function M.vectorToLinearIndex(world, v)
  return (v.y - 1) * world.width + v.x
end

---@param world World
function M.init(world)
  local data = love.image.newImageData('map.png')
  local image = love.graphics.newImage(data)

  local width = data:getWidth()
  local height = data:getHeight()

  world.width = width
  world.height = height
  world.image = image
  world.revealedTilesCount = world.revealedTilesCount or 0
  world.tileTypes = world.tileTypes or {}
  world.fogOfWar = world.fogOfWar or {}

  ---@type World

  local tileColors = {
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


end

---@param world World
---@param v Vector
function M.isPassable(world, v)
  local t = world.tileTypes[M.vectorToLinearIndex(world, v)]
  return t == 'grass' or t == 'forest' or t == 'sand' or t == 'void' or t == 'cave' or t == 'snow'
end

-- TODO: make it a mutator
---@param world World
---@param v Vector
---@param t WorldTile
function M.setTile(world, v, t)
  local id = M.vectorToLinearIndex(world, v)
  world.tileTypes[id] = t
end

---@param world World
---@param v Vector
---@return WorldTile
function M.getTile(world, v)
  return world.tileTypes[M.vectorToLinearIndex(world, v)]
end

---@param world World
---@param v Vector
---@return number transparency
function M.getFog(world, v)
  return world.fogOfWar[M.vectorToLinearIndex(world, v)]
end

---@param world World
---@param visionSource VisionSource
---@param light number
---@param dt number
function M.revealVisionSourceFog(world, visionSource, light, dt)
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
      M.mut.revealFogOfWar(world, tmpVec, alpha, dt)
    end
  end
end

return M