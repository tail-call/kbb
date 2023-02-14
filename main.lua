local loadImages = require('./images').load
local World = require('./world').World
local Guy = require('./guy').Guy
local vector = require('./vector')
local draw = require('./draw')

---@type World
local world

local function collider(v)
  return world:isPassable(v)
end

---@type Guy[]
local guys = {
  Guy.new{ pos = { x = 5, y = 5 } },
  Guy.makeWanderingGuy(collider),
  Guy.makeWanderingGuy(collider),
  Guy.makeWanderingGuy(collider),
}
local player = guys[1]


local function drawWorld()
  draw.centerCameraOn(player.pos)
  world:draw()
  for _, guy in ipairs(guys) do
    draw.guy(guy.pos)
  end
end

function love.load()
  love.window.setMode(320 * 3, 200 * 3)
  love.graphics.setDefaultFilter("nearest", "nearest")
  local images = loadImages()
  draw.setLibrary(images)
  world = World.new({
    images.rock,
    images.grass,
  })
end

---@param dt number
function love.update(dt)
  for _, guy in ipairs(guys) do
    guy:update(dt)
  end
end

---@param key love.KeyConstant
---@param scancode love.Scancode
---@param isrepeat boolean
function love.keypressed(key, scancode, isrepeat)
  if isrepeat then return end

  if vector.dir[key] then
    player:move(key, collider)
  end
end

function love.draw()
  love.graphics.scale(3)
  love.graphics.push()
  drawWorld()
  love.graphics.pop()
  draw.hud(#guys)
end