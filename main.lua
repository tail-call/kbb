local World = require('./world').World
local Guy = require('./guy').Guy
local vector = require('./vector')
local draw = require('./draw')
local tbl = require('./tbl')

---@type World
local world
---@type Guy[]
local guys = {}
---@type Guy
local player
local squad

local function collider(v)
  local found = tbl.find(guys, function(guy)
    return vector.equal(guy.pos, v)
  end)
  return not found and world:isPassable(v)
end

local lerpVec = { x = 0, y = 0 }

local function drawWorld()
  lerpVec = {
    x = lerpVec.x + (player.pos.x - lerpVec.x) * 0.06,
    y = lerpVec.y + (player.pos.y - lerpVec.y) * 0.06,
  }
  draw.centerCameraOn(lerpVec)
  world:draw()
  draw.drawSprites()
end

function love.load()
  draw.init()
  player = Guy.makeLeader()
  guys = {
    player,
    Guy.makeGoodGuy(3),
    Guy.makeGoodGuy(4),
    Guy.makeGoodGuy(6),
    Guy.makeEvilGuy(collider),
    Guy.makeEvilGuy(collider),
    Guy.makeEvilGuy(collider),
    Guy.makeEvilGuy(collider),
    Guy.makeEvilGuy(collider),
    Guy.makeEvilGuy(collider),
  }
  world = World.new()
  squad = {
    leader = player,
    guys[2], guys[3], guys[4]
  }
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
    for _, guy in ipairs(squad) do
      guy:move(key, collider)
    end
    squad.leader:move(key, collider)
  end
end

function love.draw()
  draw.prepareFrame()
  love.graphics.push()
  drawWorld()
  love.graphics.pop()
  draw.hud(#squad)
end