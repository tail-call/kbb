---@class Guy: Object2D
---@field __module 'Guy'
---# Properties
---@field mayMove boolean True if may move
---@field name string Guy's name
---@field team Guy.team Guy's team
---@field pixie Pixie Graphical representation of the guy
---@field stats game.GuyStats RPG stats
---@field timer number Movement timer
---@field isFlying boolean True if flies
---@field speed number Delay in seconds between moves
---@field abilities { ability: Ability, weight: number }[]
---@field behavior 'none' | 'wander'
---# Methods
---@field move fun(self: Guy, pos: core.Vector) Changes guy's position
---@field warp fun(self: Guy, pos: core.Vector) Changes guy's position instantly
---@field update fun(self: Guy, dt: number)
---@field behave fun(self: Guy, delegate: Guy.delegate) Changes guy's position

---@class Guy.delegate
---@field collider fun(v: core.Vector, guy: Guy): Guy.collision Function that performs collision checks between game world objects
---@field beginBattle fun(attacker: Guy, defender: Guy): nil Begins a battle between an attacker and defender
---@field enterHouse fun(guest: Guy, building: Building): 'shouldMove' | 'shouldNotMove' Tells whether the guy may enter the building

---@alias Guy.team 'good' | 'evil' | 'neutral'

---@class Guy.collision
---@field type 'entity' | 'terrain' | 'none'
---@field entity Object2D | nil

local Vector = require 'core.Vector'
local abilities = require 'game.Ability'.abilities

local Guy
Guy = Class {
  ...,
  slots = { 'mayMove', 'timer', '!pos', '!pixie' },
  index = {
    move = function (self, pos)
      self.mayMove = false
      self.timer = 0
      self.stats:addMoves(-2)
      self.pos = pos
      self.pixie:move(self.pos)
    end,
    warp = function (self, pos)
      self.pos = pos
      self.pixie:playSpawnAnimation(self.pos)
    end,
    update = function (self, dt)
      self.pixie:update(dt)

      self.timer = self.timer + dt

      while self.timer >= self.speed do
        self.mayMove = true
        self.timer = self.timer % self.speed
        self.stats:addMoves(1)
      end
    end,
    behave = function (self, delegate)
      if self.behavior == 'wander' then
        Guy.moveGuy(self, ({
          Vector.dir.up,
          Vector.dir.down,
          Vector.dir.left,
          Vector.dir.right,
        })[math.random(1, 4)], delegate)
      end
    end,
  }
}

---@param team1 Guy.team
---@param team2 Guy.team
---@return boolean
local function checkIfRivals(team1, team2)
  return team1 == 'good' and team2 == 'evil'
    or team1 == 'evil' and team2 == 'good'
end

---@param guy Guy
---@param vec core.Vector
---@param delegate Guy.delegate
---@return core.Vector newPosition
function Guy.moveGuy(guy, vec, delegate)
  if not guy.mayMove or guy.stats.moves < 1 then return guy.pos end

  local stepForward = Vector.add(guy.pos, vec)
  local diagonalStepLeft = Vector.add(guy.pos,
    Vector.add(vec, Vector.dotProd(vec, { x = 0, y = 1 }))
  )
  local diagonalStepRight = Vector.add(guy.pos,
    Vector.add(vec, Vector.dotProd(vec, { x = 0, y = -1 }))
  )

  for _, pos in ipairs{ stepForward, diagonalStepLeft, diagonalStepRight } do
    local collision = delegate.collider(pos, guy)
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

---@param guy Guy
function Guy.init(guy)
  guy.stats = guy.stats or require 'game.GuyStats'.new()
  guy.pixie = guy.pixie or require 'Pixie'.new()
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

  guy.pixie:move(guy.pos)
  guy.pixie:playSpawnAnimation(guy.pos)
end

---@param pos core.Vector
function Guy.makeLeader(pos)
  local tileset = require 'Tileset'.getTileset()

  local guy = Guy.new {
    pixie = require 'Pixie'.new {
      quad = tileset.quads.guy,
      color = { 1, 1, 0, 1 },
    },
    pos = pos,
    tileset = tileset,
  }
  return guy
end

---@param pos core.Vector
function Guy.makeHuman(pos)
  local tileset = require 'Tileset'.getTileset()

  return Guy.new {
    name = 'Maria',
    team = 'neutral',
    pixie = require 'Pixie'.new {
      quad = tileset.quads.human,
      color = { 1, 1, 1, 1 },
    },
    pos = pos,
    tileset = tileset,
  }
end

---@param pos core.Vector
function Guy.makeGoodGuy(pos)
  local tileset = require 'Tileset'.getTileset()

  return Guy.new {
    name = 'Good Guy',
    team = 'neutral',
    pixie = require 'Pixie'.new {
      quad = tileset.quads.guy
    },
    pos = pos,
    tileset = tileset
  }
end

---@param pos core.Vector
function Guy.makeEvilGuy(pos)
  local tileset = require 'Tileset'.getTileset()

  local guy = Guy.new {
    name = 'Evil Guy',
    team = 'evil',
    speed = 0.5,
    behavior = 'wander',
    pixie = require 'Pixie'.new {
      quad = tileset.quads.guy,
      color = { 1, 0, 0, 1 },
    },
    pos = pos,
    tileset = tileset,
  }
  return guy
end

---@param pos core.Vector
function Guy.makeStrongEvilGuy(pos)
  local tileset = require 'Tileset'.getTileset()

  local guy = Guy.new {
    pixie = require 'Pixie'.new {
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
---@return string
function Guy.tooltipText(guy)
  return ('%s\n%s/%s'):format(guy.name, guy.stats.hp, guy.stats.maxHp)
end

return Guy