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
  ---@type Vector
  lerpVec = { x = 0, y = 0 }
}

local function collider(v)
  local found = tbl.find(game.guys, function(guy)
    return vector.equal(guy.pos, v)
  end)
  return not found and game.world:isPassable(v)
end

function game:init()
  self.player = Guy.makeLeader()
  self.guys = {
    self.player,
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
  self.world = World.new()
  self.squad = {
    leader = self.player,
    self.guys[2], self.guys[3], self.guys[4]
  }
end

function game:draw()
  self.lerpVec = {
    x = self.lerpVec.x + (self.player.pos.x - self.lerpVec.x) * 0.06,
    y = self.lerpVec.y + (self.player.pos.y - self.lerpVec.y) * 0.06,
  }
  draw.centerCameraOn(self.lerpVec)
  game.world:draw()
  draw.drawSprites()
end

function love.load()
  draw.init()
  game:init()
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
  game:draw()
  love.graphics.pop()
  draw.hud(#game.squad)
end