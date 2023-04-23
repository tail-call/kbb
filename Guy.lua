---@alias GuyTeam 'good' | 'evil' | 'neutral'

---@class GuyOptions
---@field pos Vector | nil
---@field color number[] | nil
---@field tileset Tileset
---@field quad love.Quad

---@class Guy
---@field pos Vector Guy's position in the world
---@field mayMove boolean True if may move
---@field move fun(self: Guy, pos: Vector) Changes guy's position
---@field name string Guy's name
---@field rename fun(self: Guy, name: string) Gives the guy a different name
---@field setSpeed fun(self: Guy, speed: number) Sets how quickly may move again after moving
---@field team GuyTeam
---@field reteam fun(self: Guy, team: GuyTeam) Switches team of the guy
---@field pixie Pixie Graphical representation of the guy
---@field stats GuyStats RPG stats
---@field timer number Movement timer
---@field advanceTimer fun(self: Guy, dt: number)
---@field speed number Delay in seconds between moves
---@field abilities { ability: Ability, weight: number }[]
---@field behavior 'none' | 'wander'
---@field beginWandering fun(self: Guy)

---@alias CollisionInfo { type: 'entity' | 'guy' | 'terrain' | 'none', guy: Guy | nil, entity: GameEntity | nil }

local makePixie = require('Pixie').new
local Vector = require('Vector')
local abilities = require('Ability').abilities
local makeGuyStats = require('GuyStats').makeGuyStats

---@type Guy
local Guy = {}

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
local function moveGuy(guy, vec, delegate)
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
      guy:move(pos)
      return pos
    elseif collision.type == 'guy' then
      if checkIfRivals(guy.team, collision.guy.team) then
        guy:move(pos)
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
          guy:move(pos)
          return pos
        end
      end
    end
  end

  return guy.pos
end

local function warpGuy(guy, vec)
  guy.pos = vec
  guy.pixie:spawn(guy.pos)
end

---@param guy Guy
---@param dt number
local function updateGuy(guy, dt)
  guy:advanceTimer(dt)
end

---@param guy Guy
---@param delegate GuyDelegate
local function behave(guy, delegate)
  if guy.behavior == 'wander' then
    moveGuy(guy, ({
      Vector.dir.up,
      Vector.dir.down,
      Vector.dir.left,
      Vector.dir.right,
    })[math.random(1, 4)], delegate)
  end
end

---@param bak Guy
---@return Guy
local function new(bak)
  bak = bak or {}
  ---@type Guy
  local guy = {
    __module = 'Guy',
    name = 'Unnamed',
    timer = 0,
    behavior = bak.behavior or 'none',
    abilities = {
      { ability = abilities.normalSuccess, weight = 4 },
      { ability = abilities.normalCriticalSuccess, weight = 1 },
      { ability = abilities.normalFail, weight = 1 },
    },
    team = bak.team or 'good',
    mayMove = bak.mayMove or false,
    speed = bak.speed or 0.15,
    pos = bak.pos or { x = 0, y = 0 },
    stats = makeGuyStats(),
    pixie = makePixie(bak.pixie),
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
      self.stats:addMoves(-2)
      self.pos = pos
      self.pixie:move(self.pos)
    end,
    advanceTimer = function (self, dt)
      self.pixie:update(dt)
      self.timer = self.timer + dt

      while self.timer >= self.speed do
        self.mayMove = true
        self.timer = self.timer % self.speed
        self.stats:addMoves(1)
      end
    end
  }

  guy.pixie:move(guy.pos)
  guy.pixie:spawn(guy.pos)

  return guy
end

---@param tileset Tileset
---@param pos Vector
function Guy.makeLeader(tileset, pos)
  local guy = new{
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
function Guy.makeHuman(tileset, pos)
  local guy = new{
    pixie = {
      quad = tileset.quads.human,
      color = { 1, 1, 1, 1 },
    },
    pos = pos,
    tileset = tileset,
  }
  guy:reteam('neutral')
  guy:rename('Maria')
  return guy
end

---@param tileset Tileset
---@param pos Vector
function Guy.makeGoodGuy(tileset, pos)
  local guy = new{
    pixie = {
      quad = tileset.quads.guy
    },
    pos = pos,
    tileset = tileset
  }
  guy:reteam('good')
  guy:rename('Good Guy')
  return guy
end

---@param tileset Tileset
---@param pos Vector
function Guy.makeEvilGuy(tileset, pos)
  local guy = new{
    pixie = {
      quad = tileset.quads.guy,
      color = { 1, 0, 0, 1 },
    },
    pos = pos,
    tileset = tileset,
  }
  guy:setSpeed(0.5)
  guy:beginWandering()
  guy:reteam('evil')
  guy:rename('Evil Guy')
  return guy
end

---@param tileset Tileset
---@param pos Vector
function Guy.makeStrongEvilGuy(tileset, pos)
  local guy = new{
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

local function canRecruitGuy(guy)
  return guy.team == 'good'
end

return {
  Guy = Guy,
  canRecruitGuy = canRecruitGuy,
  moveGuy = moveGuy,
  updateGuy = updateGuy,
  warpGuy = warpGuy,
  behave = behave,
  new = new,
}