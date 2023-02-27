local withCanvas = require('./canvas').withCanvas

---@class Tileset
---@field tiles love.Canvas
---@field image love.Image
---@field timer number
---@field waterFrames love.Quad[]
---@field waterFrame integer
---@field guy love.Quad
---@field grass love.Quad
---@field rock love.Quad
---@field water love.Quad
---@field battle love.Quad
---@field house love.Quad
---@field forest love.Quad

local timerCeil = 0.3

local function regenerate(tileset)
  withCanvas(tileset.tiles, function ()
    love.graphics.draw(tileset.image)
  end)
end

---@return Tileset
local function load()
  local image = love.graphics.newImage('tiles.png')
  local canvas = love.graphics.newCanvas(image:getWidth(), image:getHeight())

  local function tile(x, y)
    return love.graphics.newQuad(
      x * 16, y * 16, 16, 16,
      image:getWidth(), image:getHeight()
    )
  end

  ---@type Tileset
  local tileset = {
    timer = 1,
    tiles = canvas,
    waterFrame = 4,
    image = image,
    guy = tile(0, 0),
    grass = tile(1, 0),
    rock = tile(2, 0),
    water = tile(3, 0),
    battle = tile(0, 2),
    house = tile(1, 2),
    forest = tile(2, 2),
    waterFrames = {
      tile(0, 1),
      tile(1, 1),
      tile(2, 1),
      tile(3, 1),
    }
  }

  regenerate(tileset)
  return tileset
end
---@param tileset Tileset
---@param dt number
local function update(tileset, dt)
  tileset.timer = tileset.timer + dt
  if tileset.timer > timerCeil then
    tileset.timer = tileset.timer % timerCeil
    tileset.waterFrame = tileset.waterFrame + 1
    if tileset.waterFrame > #tileset.waterFrames then
      tileset.waterFrame = 1
    end

    withCanvas(tileset.tiles, function ()
      local quad = tileset.waterFrames[tileset.waterFrame]
      local x, y = tileset.water:getViewport()
      love.graphics.draw(tileset.image, quad, x, y)
    end)
  end
end

return {
  load = load,
  update = update,
  regenerate = regenerate,
}