---@alias Tileset { tiles: love.Image, guy: love.Quad, grass: love.Quad, rock: love.Quad }

local function load()
  local tiles = love.graphics.newImage('tiles.png')
  return {
    tiles = tiles,
    guy = love.graphics.newQuad(0, 0, 16, 16, tiles:getWidth(), tiles:getHeight()),
    grass = love.graphics.newQuad(16, 0, 16, 16, tiles:getWidth(), tiles:getHeight()),
    rock = love.graphics.newQuad(32, 0, 16, 16, tiles:getWidth(), tiles:getHeight()),
  }
end

return { load = load }