-- <https://github.com/LuaLS/lua-language-server/wiki/Annotations>

local images = require('./images')
local world = require('./world')

local Guy = {
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

function Guy.new()
  local guy = {}
  setmetatable(guy, { __index = Guy })
  return guy
end

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
local map

function love.load()
  love.window.setMode(320 * 3, 200 * 3)
  love.graphics.setDefaultFilter("nearest", "nearest")
  local pics = images.load()
  Guy.image = love.graphics.newImage(pics.guy)
  map = world.World.new({
    love.graphics.newImage(pics.rock),
    love.graphics.newImage(pics.grass),
  })
end

function love.update(dt)
  otherGuy:update(dt)
end

function love.keypressed(key, scancode, isrepeat)
  if isrepeat then return end

  guy:move(key)
end

local function drawWorld()
  love.graphics.translate(320/2 - 8, 200/2 - 16)
  love.graphics.translate(-guy.x * 16, -guy.y * 16)
  map:draw()
  love.graphics.draw(otherGuy.image, otherGuy.x * 16, otherGuy.y * 16)
  love.graphics.draw(guy.image, guy.x * 16, guy.y * 16)
end

function love.draw()
  love.graphics.scale(3)
  love.graphics.push()
  drawWorld()
  love.graphics.pop()
  love.graphics.print('Units: 2', 0, 0)
end