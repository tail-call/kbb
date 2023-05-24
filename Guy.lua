---@alias GuyTeam 'good' | 'evil' | 'neutral'

---@class GuyDelegate
---@field collider fun(v: Vector): CollisionInfo Function that performs collision checks between game world objects
---@field beginBattle fun(attacker: Guy, defender: Guy): nil Begins a battle between an attacker and defender
---@field enterHouse fun(guest: Guy, building: Building): 'shouldMove' | 'shouldNotMove' Tells whether the guy may enter the building

---@class Guy: Object2D
---@field __module 'Guy'
---# Properties
---@field mayMove boolean True if may move
---@field name string Guy's name
---@field team GuyTeam Guy's team
---@field pixie Pixie Graphical representation of the guy
---@field stats GuyStats RPG stats
---@field timer number Movement timer
---@field speed number Delay in seconds between moves
---@field abilities { ability: Ability, weight: number }[]
---@field behavior 'none' | 'wander'
---# Methods
---@field move fun(self: Guy, pos: Vector) Changes guy's position
---@field advanceTimer fun(self: Guy, dt: number)

---@alias CollisionInfo { type: 'entity' | 'terrain' | 'none', entity: Object2D | nil }

local Vector = require('Vector')
local abilities = require('Ability').abilities

local addMoves = require('GuyStats').mut.addMoves
local movePixie = require('Pixie').mut.movePixie
local updatePixie = require('Pixie').mut.updatePixie
local playSpawnAnimation = require('Pixie').mut.playSpawnAnimation
local setMaxHp = require('GuyStats').mut.setMaxHp

local M = require('Module').define{..., metatable = {
  ---@type Guy
  __index = {
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
}}

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

  for _, pos in ipairs{ stepForward, diagonalStepLeft, diagonalStepRight } do
    local collision = delegate.collider(pos)
    if collision.type == 'none' then
      guy:move(pos)
      return pos
    elseif collision.type == 'entity' then
      local entity = collision.entity
      if entity ~= nil then
        if entity.__module == 'Building' then
          ---@cast entity Building
          local shouldMove = delegate.enterHouse(guy, entity)
          if shouldMove == 'shouldMove' then
            guy:move(pos)
            return pos
          end
        elseif collision.entity.__module == 'Guy' then
          ---@cast entity Guy
          if checkIfRivals(guy.team, collision.entity.team) then
            guy:move(pos)
            delegate.beginBattle(guy, entity)
            return pos
          end
        end
      end
    end
  end

  return guy.pos
end

function M.warpGuy(guy, vec)
  guy.pos = vec
  require('Pixie').mut.playSpawnAnimation(guy.pixie, guy.pos)
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
  guy.pixie = load('Pixie', guy.pixie)
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

  movePixie(guy.pixie, guy.pos)
  playSpawnAnimation(guy.pixie, guy.pos)
end

---@param pos Vector
function M.makeLeader(pos)
  local tileset = require('Tileset').getTileset()

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

---@param pos Vector
function M.makeHuman(pos)
  local tileset = require('Tileset').getTileset()

  return M.new {
    name = 'Maria',
    team = 'neutral',
    pixie = {
      quad = tileset.quads.human,
      color = { 1, 1, 1, 1 },
    },
    pos = pos,
    tileset = tileset,
  }
end

---@param pos Vector
function M.makeGoodGuy(pos)
  local tileset = require('Tileset').getTileset()

  return M.new {
    name = 'Good Guy',
    team = 'neutral',
    pixie = {
      quad = tileset.quads.guy
    },
    pos = pos,
    tileset = tileset
  }
end

---@param pos Vector
function M.makeEvilGuy(pos)
  local tileset = require('Tileset').getTileset()

  local guy = M.new {
    name = 'Evil Guy',
    team = 'evil',
    speed = 0.5,
    behavior = 'wander',
    pixie = {
      quad = tileset.quads.guy,
      color = { 1, 0, 0, 1 },
    },
    pos = pos,
    tileset = tileset,
  }
  return guy
end

---@param pos Vector
function M.makeStrongEvilGuy(pos)
  local tileset = require('Tileset').getTileset()

  local guy = M.new{
    pixie = {
      quad = tileset.quads.guy,
      color = { 1, 0, 1, 1 },
    },
    pos = pos,
    tileset = tileset,
  }
  setMaxHp(guy.stats, 50)
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

---@param guy Guy
---@return string
function M.tooltipText(guy)
  return ('%s\n%s/%s'):format(guy.name, guy.stats.hp, guy.stats.maxHp)
end

return M