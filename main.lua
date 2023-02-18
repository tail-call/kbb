local World = require('./world').World
local Guy = require('./guy').Guy
local vector = require('./vector')
local draw = require('./draw')
local tbl = require('./tbl')

-- Game state

local game = {
  ---@type World
  world = nil,
  ---@type Guy[]
  guys = {},
  ---@type Guy
  player = nil,
  squad = {},
  ---@type Vector
  lerpVec = { x = 0, y = 0 },
  recruitCircle = nil,
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
    shouldFollow = true,
    followers = { self.guys[2], self.guys[3], self.guys[4] },
  }
end

function game:draw()
  draw.prepareFrame()
  love.graphics.push()

  self.lerpVec = vector.lerp(self.lerpVec, self.player.pos, 0.04)

  draw.centerCameraOn(self.lerpVec)
  game.world:draw()

  love.graphics.printf(
    "Move your troops with arrow keys.\n\nPress 1, 2, 3, 4 to change window scale.\n\nPress F to toggle follow mode.\n\nG to dismiss squad.\n\nSpace to recruit units.", 
    love.math.newTransform(16 * 3, 16 * 6),
    16 * 8
  )

  for _, guy in ipairs(self.guys) do
    guy:draw()
  end

  if self.recruitCircle then
    love.graphics.circle(
      'line',
      self.player.pos.x * 16 + 8,
      self.player.pos.y * 16 + 8,
      self.recruitCircle * 16
    )
  end

  love.graphics.pop()
  draw.hud(#game.squad.followers, game.squad.shouldFollow)
end

---@param dt number
function game:update(dt)
  for _, guy in ipairs(self.guys) do
    guy:update(dt)
  end
  if self.recruitCircle ~= nil then
    self.recruitCircle = math.min(self.recruitCircle + dt * 6, 6)
  end
end

-- Löve callbacks

function love.load()
  draw.init()
  game:init()
end

---@param dt number
function love.update(dt)
  draw.update(dt)
  game:update(dt)
end

---@param key love.KeyConstant
---@param scancode love.Scancode
---@param isrepeat boolean
function love.keypressed(key, scancode, isrepeat)
  if tbl.has({ '1', '2', '3', '4' }, scancode) then
    draw.setZoom(tonumber(scancode))
  end

  if scancode == 'f' then
    game.squad.shouldFollow = not game.squad.shouldFollow
  end

  if scancode == 'g' then
    game.squad.followers = {}
  end

  if scancode == 'space' then
    game.recruitCircle = 0
  end

  local vec = vector.dir[scancode]
  if vec then
    if game.squad.shouldFollow then
      for _, guy in ipairs(game.squad.followers) do
        guy:move(vec, collider)
      end
    end
    game.squad.leader:move(vec, collider)
  end
end

---@param key love.KeyConstant
---@param scancode love.Scancode
function love.keyreleased(key, scancode)
  if scancode == 'space' then
    game.recruitCircle = nil
  end
end

function love.draw()
  game:draw()
end