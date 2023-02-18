local World = require('./world').World
local Guy = require('./guy').Guy
local vector = require('./vector')
local draw = require('./draw')
local tbl = require('./tbl')
local loadFont = require('./font').load

-- Lerpable vector for smooth camera movement

local lerpVec = { x = 0, y = 0 }

local font = loadFont('cga8.png', 8, 8)

function lerpVec:lerp(pos, factor)
  self.x = self.x + (pos.x - self.x) * factor
  self.y = self.y + (pos.y - self.y) * factor
end

-- Game state

local game = {
  ---@type World
  world = nil,
  ---@type Guy[]
  guys = {},
  ---@type Guy
  player = nil,
  squad = {},
  lerpVec = lerpVec
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
  draw.prepareFrame()
  love.graphics.push()

  self.lerpVec:lerp(self.player.pos, 0.04)

  draw.centerCameraOn(self.lerpVec)
  game.world:draw()
  for _, guy in ipairs(self.guys) do
    guy:draw()
  end
  love.graphics.draw(font, 0, 128)

  love.graphics.pop()
  draw.hud(#game.squad)
end

-- Löve callbacks

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
  if tbl.has({ '1', '2', '3', '4' }, key) then
    draw.setZoom(tonumber(key))
  end

  local vec = vector.dir[key]
  if vec then
    for _, guy in ipairs(game.squad) do
      guy:move(vec, collider)
    end
    game.squad.leader:move(vec, collider)
  end
end

function love.draw()
  game:draw()
end