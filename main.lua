-- <https://github.com/LuaLS/lua-language-server/wiki/Annotations>

local images = require('./images')

local guy = {
  x = 10,
  y = 6,
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
---@type love.Image
local rockImage

function love.load()
  love.window.setMode(320 * 3, 200 * 3)
  love.graphics.setDefaultFilter("nearest", "nearest")
  local pics = images.load()
  guy.image = love.graphics.newImage(pics.guy)
  grassImage = love.graphics.newImage(pics.grass)
  rockImage = love.graphics.newImage(pics.rock)
end

function love.keypressed(key, scancode, isrepeat)
  if isrepeat then return end

  guy:move(key)
end

local function drawWorld()
  love.graphics.translate(320/2 - 8, 200/2 - 16)
  love.graphics.translate(-guy.x * 16, -guy.y * 16)
  for i = 1, 20 do
    for j = 1, 13 do
      if i == 1 then
        love.graphics.draw(rockImage, (i - 1) * 16, (j - 1) * 16)
      else
        love.graphics.draw(grassImage, (i - 1) * 16, (j - 1) * 16)
      end
    end
  end
  love.graphics.draw(guy.image, guy.x * 16, guy.y * 16)
end

function love.draw()
  love.graphics.scale(3)
  love.graphics.push()
  drawWorld()
  love.graphics.pop()
  love.graphics.print('Units: 1', 0, 0)
end