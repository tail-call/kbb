---@alias Tileset { tiles: love.Image, guy: love.Quad, grass: love.Quad, rock: love.Quad, water: love.Quad }

local function load()
  local tiles = love.graphics.newImage('tiles.png')
  local function quad(x, y, w, h)
    return love.graphics.newQuad(x, y, w, h, tiles:getWidth(), tiles:getHeight())
  end
  return {
    tiles = tiles,
    guy = quad(0, 0, 16, 16),
    grass = quad(16, 0, 16, 16),
    rock = quad(32, 0, 16, 16),
    water = quad(0, 16, 16, 16),
  }
end

return { load = load }