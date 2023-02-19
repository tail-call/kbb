local Guy = require('./guy').Guy
local World = require('./world').World
local draw = require('./draw')
local tbl = require('./tbl')
local vector = require('./vector')

local instructions = ''
  .. 'Move your troops with arrow keys.'
  .. '\n\n'
  .. 'Press 1, 2, 3, 4 to change window scale.'
  .. '\n\n'
  .. 'Press F to toggle follow mode.'
  .. '\n\n'
  .. 'G to dismiss squad.\n\nSpace to recruit units.'

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

function game:drawRecruitables()
  if not self.recruitCircle then return end

  for _, guy in tbl.ifilter(self.guys, function (guy)
    if guy == self.player then return false end
    return vector.dist(guy.pos, self.player.pos) < self.recruitCircle + 0.5
  end) do
    love.graphics.circle(
      "line",
      guy.pos.x * 16 + 8,
      guy.pos.y * 16 + 8,
      10
    )
    draw.withColor(1, 1, 1, 0.5, function ()
      love.graphics.circle(
        "fill",
        guy.pos.x * 16 + 8,
        guy.pos.y * 16 + 8,
        10
      )
    end)
  end
end

function game:toggleFollow()
  self.squad.shouldFollow = not self.squad.shouldFollow
end

function game:dismissSquad()
  self.squad.followers = {}
end

function game:beginRecruiting()
  self.recruitCircle = 0
end

function game:endRecruiting()
  self.recruitCircle = nil
end

function game:orderMove(vec)
  if self.squad.shouldFollow then
    for _, guy in ipairs(self.squad.followers) do
      guy:move(vec, collider)
    end
  end
  self.squad.leader:move(vec, collider)
end

function game:draw()
  draw.prepareFrame()
  love.graphics.push('transform')

  self.lerpVec = vector.lerp(self.lerpVec, self.player.pos, 0.04)

  draw.centerCameraOn(self.lerpVec)
  self.world:draw()

  love.graphics.printf(
    instructions,
    16 * 3, 16 * 6,
    16 * 8
  )

  for _, guy in ipairs(self.guys) do
    guy:draw()
  end

  self:drawRecruitables()

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

return game