-- <https://github.com/LuaLS/lua-language-server/wiki/Annotations>

local images = require('./images')

local guy = {
  x = 0,
  y = 0,
  ---@type love.Image
  image = nil,

  ---@param key 'up' | 'down' | 'left' | 'right'
  move = function (self, key)
    if key == 'up' then
      self.y = self.y - 1
    elseif key == 'down' then
      self.y = self.y + 1
    elseif key == 'left' then
      self.x = self.x - 1
    elseif key == 'right' then
      self.x = self.x + 1
    end
  end
}

---@type love.Image
local grassImage

function love.load()
  love.window.setMode(320 * 3, 200 * 3)
  love.graphics.setDefaultFilter("nearest", "nearest")
  local images = images.load()
  guy.image = love.graphics.newImage(images.guy)
  grassImage = love.graphics.newImage(images.grass)
end

function love.keypressed(key, scancode, isrepeat)
  if isrepeat then return end

  guy:move(key)
end

function love.draw()
  love.graphics.scale(3)
  love.graphics.translate(320/2 - 8, 200/2 - 16)
  love.graphics.translate(-guy.x * 16, -guy.y * 16)
  for i = 1, 20 do
    for j = 1, 13 do
      love.graphics.draw(grassImage, (i - 1) * 16, (j - 1) * 16)
    end
  end
  love.graphics.draw(grassImage, 0, 0)
  love.graphics.draw(guy.image, guy.x * 16, guy.y * 16)
end