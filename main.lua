local World = require('./world').World
local Guy = require('./guy').Guy
local vector = require('./vector')
local draw = require('./draw')
local tbl = require('./tbl')

---@type World
local world

local function collider(v)
  return world:isPassable(v)
end

local player = Guy.new{ pos = { x = 5, y = 5 } }

---@type Guy[]
local guys = {
  player,
  Guy.makeGoodGuy(collider, player, 3),
  Guy.makeGoodGuy(collider, player, 4),
  Guy.makeGoodGuy(collider, player, 6),
  Guy.makeEvilGuy(collider),
  Guy.makeEvilGuy(collider),
  Guy.makeEvilGuy(collider),
  Guy.makeEvilGuy(collider),
  Guy.makeEvilGuy(collider),
  Guy.makeEvilGuy(collider),
}


local function drawWorld()
  draw.centerCameraOn(player.pos)
  world:draw()
  for _, guy in ipairs(guys) do
    guy:draw()
  end
end

function love.load()
  draw.init()
  world = World.new()
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

  if tbl.has({ '1', '2', '3', '4' }, key) then
    draw.setZoom(tonumber(key))
  end

  if vector.dir[key] then
    player:move(key, collider)
  end
end

function love.draw()
  draw.prepareFrame()
  love.graphics.push()
  drawWorld()
  love.graphics.pop()
  draw.hud(#guys)
end