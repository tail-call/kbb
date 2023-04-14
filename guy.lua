local makePixie = require('./pixie').makePixie
local vector = require('./vector')
local abilities = require('./ability').abilities

---@class GuyStats
---@field hp number
---@field maxHp number

---@class Guy
---@field pos Vector
---@field name string
---@field pixie Pixie
---@field stats GuyStats
---@field time number
---@field mayMove boolean
---@field speed number
---@field abilities { ability: Ability, weight: number }[]
---@field behavior 'none' | 'wander'
---@field team 'good' | 'evil'

---@alias CollisionInfo { type: 'entity' | 'guy' | 'terrain' | 'none', guy: Guy | nil, entity: GameEntity | nil }
---@alias Collider fun(nothing: nil, v: Vector): CollisionInfo

---@class GuyDelegate
---@field collider Collider
---@field beginBattle fun(attacker: Guy, defender: Guy): nil
---@field enterHouse fun(guest: Guy, entity: BuildingGameEntity): nil

---@type Guy
local Guy = {
  pos = { x = 0, y = 0 },
  name = 'Good Guy',
  time = 0,
  behavior = 'none',
  stats = {
    hp = -1,
    maxHp = -1,
  },
  abilities = {
    { ability = abilities.normalSuccess, weight = 4 },
    { ability = abilities.normalCriticalSuccess, weight = 1 },
    { ability = abilities.normalFail, weight = 1 },
  },
  team = 'good',
  mayMove = false,
  speed = 0.15,
}

---@param guy Guy
---@param vec Vector
---@param delegate GuyDelegate
---@return boolean didMove
local function moveGuy(guy, vec, delegate)
  if not guy.mayMove then return false end

  local didMove = false

  local stepForward = vector.add(guy.pos, vec)
  local diagonalStepLeft = vector.add(guy.pos,
    vector.add(vec, vector.dotProd(vec, { x = 0, y = 1 }))
  )
  local diagonalStepRight = vector.add(guy.pos,
    vector.add(vec, vector.dotProd(vec, { x = 0, y = -1 }))
  )

  ---@param pos Vector
  local function move(pos)
    didMove = true
    guy.mayMove = false
    guy.pos = pos
    guy.pixie:move(guy.pos)
  end

  for _, pos in ipairs{stepForward, diagonalStepLeft, diagonalStepRight} do
    local collision = delegate.collider(nil, pos)
    if collision.type == 'none' then
      move(pos)
    elseif collision.type == 'guy' then
      if guy.team ~= collision.guy.team then
        move(pos)
        delegate.beginBattle(guy, collision.guy)
      end
    elseif collision.type == 'entity' then
      if collision.entity.type == 'building' then
        local entity = collision.entity
        ---@cast entity any
        local sameEntity = entity
        ---@cast sameEntity BuildingGameEntity
        local shouldMove = delegate.enterHouse(guy, sameEntity)
        if shouldMove then
          move(pos)
        end
      end
    end
    if didMove then
      break
    end
  end

  return didMove
end

local function warpGuy(guy, vec)
  guy.pos = vec
  guy.pixie:spawn(guy.pos)
end

---@param guy Guy
---@param dt number
---@param delegate GuyDelegate
local function updateGuy(guy, dt, delegate)
  guy.pixie:update(dt)
  guy.time = guy.time + dt
  while guy.time >= guy.speed do
    guy.time = guy.time % guy.speed
    guy.mayMove = true
  end

  if guy.behavior == 'wander' then
    moveGuy(guy, ({
      vector.dir.up,
      vector.dir.down,
      vector.dir.left,
      vector.dir.right,
    })[math.random(1, 4)], delegate)
  end
end

---@return Guy
function Guy.new(props)
  ---@type Guy
  local guy = {}
  setmetatable(guy, { __index = Guy })
  guy.pos = props.pos or guy.pos
  guy.pixie = makePixie('guy')
  guy.pixie.color = props.color or guy.pixie.color
  guy.pixie:move(guy.pos)
  guy.stats = {
    hp = 10,
    maxHp = 10,
  }
  guy.pixie:spawn(props.pos)
  return guy
end

---@param pos Vector
function Guy.makeLeader(pos)
  local guy = Guy.new{
    pos = pos,
    color = { 1, 1, 0, 1 },
  }
  return guy
end

---@param pos Vector
function Guy.makeGoodGuy(pos)
  local guy = Guy.new{ pos = pos }
  guy.team = 'good'
  guy.name = 'Good Guy'
  return guy
end

---@param pos Vector
function Guy.makeEvilGuy(pos)
  local guy = Guy.new{
    pos = pos,
    color = { 1, 0, 0, 1 },
  }
  guy.time = 0
  guy.speed = 0.5
  guy.behavior = 'wander'
  guy.team = 'evil'
  guy.name = 'Evil Guy'
  return guy
end

---@param pos Vector
function Guy.makeStrongEvilGuy(pos)
  local guy = Guy.new{
    pos = pos,
    color = { 1, 0, 1, 1 },
  }
  guy.time = 0
  guy.stats.hp = 50
  guy.stats.maxHp = 50
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
}