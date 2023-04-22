---@alias WorldTile 'grass' | 'rock' | 'water' | 'forest' | 'sand' | 'void' | 'snow' | 'cave' | 'wall'

---@class World: X_Serializable
---@field width integer World's width in squares
---@field height integer World's height in squares
---@field image love.Image Minimap image
---@field revealedTilesCount number Number of tiles player had revealed
---@field tileTypes WorldTile[] Tile types of each square in the world
---@field fogOfWar number[] How visible is each square in the world. Numbers from 0 to 1
---@field revealFogOfWar fun(self: World, pos: Vector, value: number, dt: number) Partially reveals fog of war over sime time dt

local FOG_REVEAL_SPEED = 1
local SQUARE_REVEAL_THRESHOLD = 0.5

local X_Serializable = require('X_Serializable')

local calcVisionDistance = require('VisionSource').calcVisionDistance
local isVisible = require('VisionSource').isVisible

---@param world World
---@param v Vector
---@return integer
local function vectorToLinearIndex(world, v)
  return (v.y - 1) * world.width + v.x
end

---@param block string Raw bytes of a block
---@return number[] fogOfWar fog of war object
local function makeFogOfWarFromBlock(block)
  local fogOfWar = {}
  for i = 1, block:len() do
    table.insert(fogOfWar, block:byte(i) / 255)
  end
  return fogOfWar
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
    revealedTilesCount = 0,
    tileTypes = {},
    fogOfWar = {},
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
    X_Serializable = X_Serializable,
    serialize = function (self)
      ---@cast self World

      local fogContents = {}
      for _, fog in ipairs(self.fogOfWar) do
        local char = math.floor(fog * 255)
        table.insert(fogContents, string.char(char))
      end

      local fogCompressedData = love.data.compress(
        'string', 'zlib', table.concat(fogContents), 9
      )

      return table.concat {
        'COM World: hey guys\n',
        'COM World: fog data is a block\n',
        'COM World: a block: array of zlib-compressed bytes\n',
        ---@cast fogCompressedData string
        'BLOCK fogOfWar ' .. fogCompressedData:len() .. '\n',
        fogCompressedData,
      }
    end,
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
      world:revealFogOfWar(tmpVec, alpha, dt)
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
  makeFogOfWarFromBlock = makeFogOfWarFromBlock,
}