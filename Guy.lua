---@alias GuyTeam 'good' | 'evil' | 'neutral'

---@class GuyOptions
---@field pos Vector | nil
---@field color number[] | nil
---@field tileset Tileset
---@field quad love.Quad

---@class Guy
---@field pos Vector Guy's position in the world
---@field mayMove boolean True if may move
---@field name string Guy's name
---@field team GuyTeam
---@field pixie Pixie Graphical representation of the guy
---@field stats GuyStats RPG stats
---@field timer number Movement timer
---@field speed number Delay in seconds between moves
---@field abilities { ability: Ability, weight: number }[]
---@field behavior 'none' | 'wander'

---@class GuyMutator
---@field move fun(self: Guy, pos: Vector) Changes guy's position
---@field setSpeed fun(self: Guy, speed: number) Sets how quickly may move again after moving
---@field beginWandering fun(self: Guy)
---@field advanceTimer fun(self: Guy, dt: number)
---@field rename fun(self: Guy, name: string) Gives the guy a different name
---@field reteam fun(self: Guy, team: GuyTeam) Switches team of the guy

---@alias CollisionInfo { type: 'entity' | 'guy' | 'terrain' | 'none', guy: Guy | nil, entity: GameEntity | nil }

local M = require('Module').define(..., 0)

local Vector = require('Vector')
local abilities = require('Ability').abilities

local addMoves = require('GuyStats').mut.addMoves
local movePixie = require('Pixie').mut.movePixie
local updatePixie = require('Pixie').mut.updatePixie
local playSpawnAnimation = require('Pixie').mut.playSpawnAnimation

---@type Guy
M.Guy = {}

---@type GuyMutator
M.mut = {
  rename = function (self, name)
    self.name = name
  end,
  reteam = function (self, team)
    self.team = team
  end,
  beginWandering = function (self)
    self.behavior = 'wander'
  end,
  setSpeed = function (self, speed)
    self.speed = speed
  end,
  move = function (self, pos)
    self.mayMove = false
    self.timer = 0
    addMoves(self.stats, -2)
    self.pos = pos
    movePixie(self.pixie, self.pos)
  end,
  advanceTimer = function (self, dt)
    updatePixie(self.pixie, dt)

    self.timer = self.timer + dt

    while self.timer >= self.speed do
      self.mayMove = true
      self.timer = self.timer % self.speed
      addMoves(self.stats, 1)
    end
  end,
}

---@param team1 GuyTeam
---@param team2 GuyTeam
---@return boolean
local function checkIfRivals(team1, team2)
  return team1 == 'good' and team2 == 'evil'
    or team1 == 'evil' and team2 == 'good'
end

---@param guy Guy
---@param vec Vector
---@param delegate GuyDelegate
---@return Vector newPosition
function M.moveGuy(guy, vec, delegate)
  if not guy.mayMove or guy.stats.moves < 1 then return guy.pos end

  local stepForward = Vector.add(guy.pos, vec)
  local diagonalStepLeft = Vector.add(guy.pos,
    Vector.add(vec, Vector.dotProd(vec, { x = 0, y = 1 }))
  )
  local diagonalStepRight = Vector.add(guy.pos,
    Vector.add(vec, Vector.dotProd(vec, { x = 0, y = -1 }))
  )

  for _, pos in ipairs{stepForward, diagonalStepLeft, diagonalStepRight} do
    local collision = delegate.collider(pos)
    if collision.type == 'none' then
      M.mut.move(guy, pos)
      return pos
    elseif collision.type == 'guy' then
      if checkIfRivals(guy.team, collision.guy.team) then
        M.mut.move(guy, pos)
        delegate.beginBattle(guy, collision.guy)
        return pos
      end
    elseif collision.type == 'entity' then
      if collision.entity.type == 'building' then
        local entity = collision.entity
        ---@cast entity any
        local sameEntity = entity
        ---@cast sameEntity GameEntity_Building
        local shouldMove = delegate.enterHouse(guy, sameEntity)
        if shouldMove == 'shouldMove' then
          M.mut.move(guy, pos)
          return pos
        end
      end
    end
  end

  return guy.pos
end

function M.warpGuy(guy, vec)
  guy.pos = vec
  guy.pixie:spawn(guy.pos)
end

---@param guy Guy
---@param dt number
function M.updateGuy(guy, dt)
  M.mut.advanceTimer(guy, dt)
end

---@param guy Guy
---@param delegate GuyDelegate
function M.behave(guy, delegate)
  if guy.behavior == 'wander' then
    M.moveGuy(guy, ({
      Vector.dir.up,
      Vector.dir.down,
      Vector.dir.left,
      Vector.dir.right,
    })[math.random(1, 4)], delegate)
  end
end

---@param guy Guy
function M.init(guy, load)
  guy.stats = load('GuyStats', guy.stats)
  guy.name = guy.name or 'Unnamed'
  guy.timer = guy.timer or 0
  guy.behavior = guy.behavior or 'none'
  guy.abilities = {
    { ability = abilities.normalSuccess, weight = 4 },
    { ability = abilities.normalCriticalSuccess, weight = 1 },
    { ability = abilities.normalFail, weight = 1 },
  }
  guy.team = guy.team or 'good'
  guy.mayMove = guy.mayMove or false
  guy.speed = guy.speed or 0.15
  guy.pos = guy.pos or { x = 0, y = 0 }
  guy.pixie = load('Pixie', guy.pixie)

  movePixie(guy.pixie, guy.pos)
  playSpawnAnimation(guy.pixie, guy.pos)
end

---@param tileset Tileset
---@param pos Vector
function M.makeLeader(tileset, pos)
  local guy = M.new{
    pixie = {
      quad = tileset.quads.guy,
      color = { 1, 1, 0, 1 },
    },
    pos = pos,
    tileset = tileset,
  }
  return guy
end

---@param tileset Tileset
---@param pos Vector
function M.makeHuman(tileset, pos)
  local guy = M.new{
    pixie = {
      quad = tileset.quads.human,
      color = { 1, 1, 1, 1 },
    },
    pos = pos,
    tileset = tileset,
  }
  M.mut.reteam(guy, 'neutral')
  M.mut.rename(guy, 'Maria')
  return guy
end

---@param tileset Tileset
---@param pos Vector
function M.makeGoodGuy(tileset, pos)
  local guy = M.new{
    pixie = {
      quad = tileset.quads.guy
    },
    pos = pos,
    tileset = tileset
  }
  M.mut.reteam(guy, 'good')
  M.mut.rename(guy, 'Good Guy')
  return guy
end

---@param tileset Tileset
---@param pos Vector
function M.makeEvilGuy(tileset, pos)
  local guy = M.new{
    pixie = {
      quad = tileset.quads.guy,
      color = { 1, 0, 0, 1 },
    },
    pos = pos,
    tileset = tileset,
  }
  M.mut.setSpeed(guy, 0.5)
  M.mut.beginWandering(guy)
  M.mut.reteam(guy, 'evil')
  M.mut.rename(guy, 'Evil Guy')
  return guy
end

---@param tileset Tileset
---@param pos Vector
function M.makeStrongEvilGuy(tileset, pos)
  local guy = M.new{
    pixie = {
      quad = tileset.quads.guy,
      color = { 1, 0, 1, 1 },
    },
    pos = pos,
    tileset = tileset,
  }
  guy.stats:setMaxHp(50)
  guy.speed = 0.25
  guy.behavior = 'wander'
  guy.team = 'evil'
  guy.name = 'Evil Guy'
  return guy
end

---@param guy Guy
---@return boolean
function M.canRecruitGuy(guy)
  return guy.team == 'good'
end

return M