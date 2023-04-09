local withCanvas = require('./canvas').withCanvas

---@class TilesetQuads
---@field guy love.Quad
---@field grass love.Quad
---@field rock love.Quad
---@field water love.Quad
---@field battle love.Quad
---@field house love.Quad
---@field forest love.Quad
---@field sand love.Quad
---@field waterFrames love.Quad[]

---@class Tileset
---@field tiles love.Canvas
---@field image love.Image
---@field timer number
---@field waterFrame integer
---@field quads TilesetQuads

local timerCeil = 0.3

local function regenerate(tileset)
  withCanvas(tileset.tiles, function ()
    love.graphics.draw(tileset.image)
  end)
end

---@type Tileset
local tileset

local function getTileset()
  return tileset
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

  ---@type Tileset
  local aTileset = {
    timer = 1,
    tiles = canvas,
    waterFrame = 4,
    image = image,
    quads = {
      guy = tile(0, 0),
      grass = tile(1, 0),
      rock = tile(2, 0),
      water = tile(3, 0),
      battle = tile(0, 2),
      house = tile(1, 2),
      forest = tile(2, 2),
      sand = tile(3, 2),
      waterFrames = {
        tile(0, 1),
        tile(1, 1),
        tile(2, 1),
        tile(3, 1),
      }
    }
  }

  regenerate(aTileset)
  tileset = aTileset
end
---@param tileset Tileset
---@param dt number
local function update(tileset, dt)
  tileset.timer = tileset.timer + dt
  if tileset.timer > timerCeil then
    tileset.timer = tileset.timer % timerCeil
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
  regenerate = regenerate,
  getTileset = getTileset,
}