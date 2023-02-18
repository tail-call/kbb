local World = require('./world').World
local Guy = require('./guy').Guy
local vector = require('./vector')
local draw = require('./draw')
local tbl = require('./tbl')


local game = {
  ---@type World
  world = nil,
  ---@type Guy[]
  guys = {},
  ---@type Guy
  player = nil,
  squad = {},
}

function game:init()
end

local function collider(v)
  local found = tbl.find(game.guys, function(guy)
    return vector.equal(guy.pos, v)
  end)
  return not found and game.world:isPassable(v)
end

local lerpVec = { x = 0, y = 0 }

local function drawWorld()
  lerpVec = {
    x = lerpVec.x + (game.player.pos.x - lerpVec.x) * 0.06,
    y = lerpVec.y + (game.player.pos.y - lerpVec.y) * 0.06,
  }
  draw.centerCameraOn(lerpVec)
  game.world:draw()
  draw.drawSprites()
end

function love.load()
  draw.init()
  game.player = Guy.makeLeader()
  game.guys = {
    game.player,
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
  game.world = World.new()
  game.squad = {
    leader = game.player,
    game.guys[2], game.guys[3], game.guys[4]
  }
end

---@param dt number
function love.update(dt)
  for _, guy in ipairs(game.guys) do
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
    for _, guy in ipairs(game.squad) do
      guy:move(key, collider)
    end
    game.squad.leader:move(key, collider)
  end
end

function love.draw()
  draw.prepareFrame()
  love.graphics.push()
  drawWorld()
  love.graphics.pop()
  draw.hud(#game.squad)
end