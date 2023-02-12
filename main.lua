-- <https://github.com/LuaLS/lua-language-server/wiki/Annotations>

local loadImages = require('./images').load
local World = require('./world').World
local Guy = require('./guy').Guy

local guy = Guy.new()

local otherGuy = Guy.new()
otherGuy.time = 0.0
function otherGuy:update(dt)
  self.time = self.time + dt
  while self.time > 0.25 do
    self.time = self.time % 0.25
    self:move(({ 'up', 'down', 'left', 'right' })[math.random(1, 4)])
  end
end

---@type World
local world

local function drawWorld()
  love.graphics.translate(320/2 - 8, 200/2 - 16)
  love.graphics.translate(-guy.x * 16, -guy.y * 16)
  world:draw()
  love.graphics.draw(otherGuy.image, otherGuy.x * 16, otherGuy.y * 16)
  love.graphics.draw(guy.image, guy.x * 16, guy.y * 16)
end

local function drawHud()
  love.graphics.print('Units: 2', 0, 0)
end

function love.load()
  love.window.setMode(320 * 3, 200 * 3)
  love.graphics.setDefaultFilter("nearest", "nearest")
  local images = loadImages()
  Guy.image = love.graphics.newImage(images.guy)
  world = World.new({
    love.graphics.newImage(images.rock),
    love.graphics.newImage(images.grass),
  })
end

function love.update(dt)
  otherGuy:update(dt)
end

function love.keypressed(key, scancode, isrepeat)
  if isrepeat then return end

  guy:move(key)
end

function love.draw()
  love.graphics.scale(3)
  love.graphics.push()
  drawWorld()
  love.graphics.pop()
  drawHud()
end