---@class World
---@field image love.Image Minimap image
---@field width integer World's width in squares
---@field height integer World's height in squares
---@field revealedTilesCount number Number of tiles player had revealed
---@field tileTypes World.tile[] Tile types of each square in the world
---@field fogOfWar number[] How visible is each square in the world. Numbers from 0 to 1
---@field revealFogOfWar fun(self: World, pos: core.Vector, value: number, dt: number) Partially reveals fog of war over sime time dt
---@field setTile fun(self: World, v: core.Vector, tile: World.tile) Changes a tile at specific pos

---@alias World.tile
---| 'grass'
---| 'rock'
---| 'water'
---| 'forest'
---| 'sand'
---| 'void'
---| 'snow'
---| 'cave'
---| 'wall'

local FOG_REVEAL_SPEED = 1
local SQUARE_REVEAL_THRESHOLD = 0.5

---@param world World
---@param v core.Vector
---@return integer
local function vectorToLinearIndex(world, v)
  return (v.y - 1) * world.width + v.x
end

local M = require 'core.Module'.define{..., metatable = {
  ---@type World
  __index = {
    revealFogOfWar = function (self, pos, value, dt)
      local idx = vectorToLinearIndex(self, pos)
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
    setTile = function (self, v, t)
      local id = vectorToLinearIndex(self, v)
      self.tileTypes[id] = t
    end,
  }
}}

local calcVisionDistance = require 'VisionSource'.calcVisionDistance
local isVisible = require 'VisionSource'.isVisible

---@param world World
---@param v core.Vector
---@return integer
function M.vectorToLinearIndex(world, v)
  return vectorToLinearIndex(world, v)
end

local function generateTiles(width, height)
  local tileTypes = {}
  for i = 1, width * height do
    tileTypes[i] = 'grass'
  end
  return tileTypes
end

---@param world World
function M.init(world)
  ---@type love.ImageData
  local data = require 'res/map.png'

  world.width = data:getWidth()
  world.height = data:getHeight()
  world.image = love.graphics.newImage(data)
  world.revealedTilesCount = world.revealedTilesCount or 0
  world.tileTypes = world.tileTypes or generateTiles(world.width, world.height)
  world.fogOfWar = world.fogOfWar or {}

  local makeBufDumper = require 'core.Dump'.makeBufDumper
  -- TODO: call setmetatable for return values
  setmetatable(world.fogOfWar, {
    dump = makeBufDumper(world.fogOfWar, '%.3f,')
  })
  setmetatable(world.tileTypes, {
    dump = makeBufDumper(world.tileTypes, '%q,')
  })

  ---@type World

  for y = 0, data:getHeight() - 1 do
    for x = 0, data:getWidth() - 1 do
      local r, g, b = data:getPixel(x, y)
      r = math.floor(r*2)/2
      g = math.floor(g*2)/2
      b = math.floor(b*2)/2
      table.insert(world.tileTypes, 'void')
      table.insert(world.fogOfWar, 0.0)
    end
  end


end

---@param world World
---@param v core.Vector
function M.isPassable(world, v)
  local t = world.tileTypes[M.vectorToLinearIndex(world, v)]
  return t == 'grass' or t == 'forest' or t == 'sand' or t == 'void' or t == 'cave' or t == 'snow'
end

---@param world World
---@param v core.Vector
---@return World.tile
function M.getTile(world, v)
  return world.tileTypes[M.vectorToLinearIndex(world, v)]
end

---@param world World
---@param v core.Vector
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
      world:revealFogOfWar(tmpVec, alpha, dt)
    end
  end
end

---@param world World
---@param pos core.Vector
---@return Patch
function M.patchAt(world, pos)
  return require 'Patch'.new {
    world = world,
    coords = {
      x = math.floor(pos.x / 8),
      y = math.floor(pos.y / 8),
    },
  }
end

---@param world World
---@param patch Patch
function M.randomizePatch(world, patch)
  local weightTable = {{
    weight = math.random(1, 100),
    tile = 'grass',
  }, {
    weight = math.random(1, 100),
    tile = 'rock',
  }, {
    weight = math.random(1, 100),
    tile = 'sand',
  }, {
    weight = math.random(1, 100),
    tile = 'forest',
  }, {
    weight = math.random(1, 60),
    tile = 'water',
  }, {
    weight = math.random(1, 3),
    tile = 'snow',
  }, {
    weight = math.random(1, 2),
    tile = 'cave',
  }, {
    weight = math.random(1, 1),
    tile = 'wall',
  }}
  for y = patch.coords.y * 8, patch.coords.y * 8 + 8 - 1 do
    for x = patch.coords.x * 8, patch.coords.x * 8 + 8 - 1 do
      local tileAbove = M.getTile(world, { x = x, y = y - 1 })
      local tileToTheLeft = M.getTile(world, { x = x - 1, y = y })

      local tile = require 'core.numeric'.weightedRandom(weightTable)
      world:setTile({ x = x, y = y }, tile.tile)

      if tileAbove == tileToTheLeft and tileAbove ~= 'void' then
        world:setTile({ x = x, y = y }, tileAbove or 'grass')
      end
    end
  end
end

return M