-- <https://github.com/LuaLS/lua-language-server/wiki/Annotations>

local images = require('./images')

local guyX = 5
local guyY = 5
---@type love.Image
local guyImage
---@type love.Image
local grassImage

function love.load()
  love.window.setMode(320 * 3, 200 * 3)
  love.graphics.setDefaultFilter("nearest", "nearest")
  local images = images.load()
  guyImage = love.graphics.newImage(images.guy)
  grassImage = love.graphics.newImage(images.grass)
end

function love.keypressed(key, scancode, isrepeat)
  if isrepeat then return end

  if key == 'up' then
    guyY = guyY - 1
  elseif key == 'down' then
    guyY = guyY + 1
  elseif key == 'left' then
    guyX = guyX - 1
  elseif key == 'right' then
    guyX = guyX + 1
  end
end

function love.draw()
  love.graphics.scale(3)
  love.graphics.translate(320/2 - 8, 200/2 - 16)
  love.graphics.translate(-guyX * 16, -guyY * 16)
  for i = 1, 20 do
    for j = 1, 13 do
      love.graphics.draw(grassImage, (i - 1) * 16, (j - 1) * 16)
    end
  end
  love.graphics.draw(grassImage, 0, 0)
  love.graphics.draw(guyImage, guyX * 16, guyY * 16)
end