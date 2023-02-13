-- <https://github.com/LuaLS/lua-language-server/wiki/Annotations>

local loadImages = require('./images').load
local World = require('./world').World
local Guy = require('./guy').Guy

---@type Guy[]
local guys = {
  Guy.new{ pos = { x = 5, y = 5 } },
  Guy.makeWanderingGuy(),
  Guy.makeWanderingGuy(),
  Guy.makeWanderingGuy(),
}
local player = guys[1]

---@type World
local world

local function centerCameraOn(pos)
  love.graphics.translate(
    320/2 - 8 - pos.x * 16,
    200/2 - 16 - pos.y * 16
  )
end

local function drawWorld()
  centerCameraOn(player.pos)
  world:draw()
  for _, guy in ipairs(guys) do
    love.graphics.draw(guy.image, guy.pos.x * 16, guy.pos.y * 16)
  end
end

local function drawHud()
  love.graphics.print('Units: ' .. #guys, 0, 0)
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
  for _, guy in ipairs(guys) do
    guy:update(dt)
  end
end

function love.keypressed(key, scancode, isrepeat)
  if isrepeat then return end

  player:move(key)
end

function love.draw()
  love.graphics.scale(3)
  love.graphics.push()
  drawWorld()
  love.graphics.pop()
  drawHud()
end