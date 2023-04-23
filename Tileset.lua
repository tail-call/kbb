---@class TilesetQuads
---@field guy love.Quad
---@field grass love.Quad
---@field rock love.Quad
---@field water love.Quad
---@field battle love.Quad
---@field house love.Quad
---@field forest love.Quad
---@field sand love.Quad
---@field void love.Quad
---@field human love.Quad
---@field snow love.Quad
---@field cave love.Quad
---@field wall love.Quad
---@field waterFrames love.Quad[]

---@class Tileset
---@field tiles love.Canvas Tileset dynamic canvas
---@field image love.Image Tileset source image
---@field animationTimer number Timer that controls animation
---@field waterFrame integer Current water animation frame
---@field quads TilesetQuads Quads this tileset provides
---@field regenerate fun(self: Tileset) Regenerates tileset. Need to call when video mode changes

local withCanvas = require('Util').withCanvas

local timerCeil = 0.3

---@type Tileset
local tileset

local function getTileset()
  return tileset
end

---@param baseX number
---@param baseY number
---@param offsetX number
---@param offsetY number
---@return { transform: love.Transform, quad: love.Quad }[]
local function parallaxTile(baseX, baseY, offsetX, offsetY)
  offsetX = offsetX % 16
  offsetY = offsetY % 16
  return {
    {
      transform = love.math.newTransform(
        0, 0
      ),
      quad = love.graphics.newQuad(
        baseX + offsetX,
        baseY + offsetY,
        16 - offsetX,
        16 - offsetY,
        tileset.tiles:getDimensions()
      ),
    },
    {
      transform = love.math.newTransform(
        16 - offsetX, 0
      ),
      quad = love.graphics.newQuad(
        baseX,
        baseY + offsetY,
        offsetX,
        16 - offsetY,
        tileset.tiles:getDimensions()
      ),
    },
    {
      transform = love.math.newTransform(
        0, 16 - offsetY
      ),
      quad = love.graphics.newQuad(
        baseX + offsetX,
        baseY,
        16 - offsetX,
        offsetY,
        tileset.tiles:getDimensions()
      ),
    },
    {
      transform = love.math.newTransform(
        16 - offsetX, 16 - offsetY
      ),
      quad = love.graphics.newQuad(
        baseX,
        baseY,
        offsetX,
        offsetY,
        tileset.tiles:getDimensions()
      ),
    },
  }
end

local function load()
  local image = love.graphics.newImage('tiles.png')
  local canvas = love.graphics.newCanvas(image:getWidth(), image:getHeight())

  local function tile(x, y)
    return love.graphics.newQuad(
      x * 16, y * 16, 16, 16,
      image:getDimensions()
    )
  end

  local function tile2h(x, y)
    return love.graphics.newQuad(
      x * 16, y * 16, 16, 32,
      image:getDimensions()
    )
  end

  ---@type Tileset
  local aTileset = {
    animationTimer = 1,
    tiles = canvas,
    waterFrame = 4,
    image = image,
    regenerate = function (self)
      withCanvas(self.tiles, function ()
        love.graphics.draw(self.image)
      end)
    end,
    quads = {
      guy = tile(0, 0),
      grass = tile(1, 0),
      rock = tile(2, 0),
      water = tile(3, 0),
      battle = tile(0, 2),
      house = tile(1, 2),
      forest = tile(2, 2),
      sand = tile(3, 2),
      void = tile(0, 3),
      human = tile2h(4, 0),
      snow = tile(3, 3),
      cave = tile(1, 3),
      wall = tile(2, 3),
      waterFrames = {
        tile(0, 1),
        tile(1, 1),
        tile(2, 1),
        tile(3, 1),
      }
    }
  }

  aTileset:regenerate()
  tileset = aTileset
end
---@param tileset Tileset
---@param dt number
local function update(tileset, dt)
  tileset.animationTimer = tileset.animationTimer + dt
  if tileset.animationTimer > timerCeil then
    tileset.animationTimer = tileset.animationTimer % timerCeil
    tileset.waterFrame = tileset.waterFrame + 1
    if tileset.waterFrame > #tileset.quads.waterFrames then
      tileset.waterFrame = 1
    end

    withCanvas(tileset.tiles, function ()
      local quad = tileset.quads.waterFrames[tileset.waterFrame]
      local x, y = tileset.quads.water:getViewport()
      love.graphics.draw(tileset.image, quad, x, y)
    end)
  end
end

return {
  load = load,
  update = update,
  getTileset = getTileset,
  parallaxTile = parallaxTile,
}