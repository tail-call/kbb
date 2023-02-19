local withCanvas = require('./canvas').withCanvas

---@class Tileset
---@field tiles love.Texture
---@field guy love.Quad
---@field grass love.Quad
---@field rock love.Quad
---@field water love.Quad
---@field water1 love.Quad
---@field water2 love.Quad
---@field water3 love.Quad
---@field water4 love.Quad
---@field update fun(self: Tileset, dt: number): nil
---@field regenerate fun(): nil

---@return Tileset
local function load()
  local tiles = love.graphics.newImage('tiles.png')
  local canvas = love.graphics.newCanvas(tiles:getWidth(), tiles:getHeight())

  local function tile(x, y)
    return love.graphics.newQuad(
      x * 16, y * 16, 16, 16,
      tiles:getWidth(), tiles:getHeight()
    )
  end

  local tileset = {
    tiles = canvas,
    guy = tile(0, 0),
    grass = tile(1, 0),
    rock = tile(2, 0),
    water = tile(3, 0),
    water1 = tile(0, 1),
    water2 = tile(1, 1),
    water3 = tile(2, 1),
    water4 = tile(3, 1),
  }

  local timer = 1
  local timerCeil = 0.3
  local water = {
    tileset.water1,
    tileset.water2,
    tileset.water3,
    tileset.water4,
  }
  local waterFrame = 4


  function tileset:update(dt)
    timer = timer + dt
    if timer > timerCeil then
      timer = timer % timerCeil
      waterFrame = waterFrame + 1
      if waterFrame > #water then
        waterFrame = 1
      end

      withCanvas(canvas, function ()
        local quad = water[waterFrame]
        local x, y = tileset.water:getViewport()
        love.graphics.draw(tiles, quad, x, y)
      end)
    end
  end

  --- Needs to be called on each window size change
  function tileset:regenerate()
    withCanvas(canvas, function ()
      love.graphics.draw(tiles)
    end)
  end

  tileset:regenerate()
  return tileset
end

return { load = load }