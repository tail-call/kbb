local draw = require('./draw')
local vector = require('./vector')

---@alias Collider fun(v: Vector): boolean

---@class Guy
---@field pos Vector
---@field spriteId SpriteId
---@field color number[]
---@field update fun(self: Guy, dt: number): nil
---@field draw fun(self: Guy): nil
---@field move fun(self: Guy, key: string, canMoveTo: Collider): nil
---@field moveVec fun(self: Guy, vec: Vector, canMoveTo: Collider): nil

local Guy = {
  ---@type Vector
  pos = { x = 0, y = 0 },
  spriteId = -1,
  color = { 1, 1, 1, 1 },

  update = function (dt)
  end,
}

---@param self Guy
---@param key 'up' | 'down' | 'left' | 'right'
---@param canMoveTo Collider
function Guy:move(key, canMoveTo)
  self:moveVec(vector.dir[key], canMoveTo)
  draw.moveSprite(self.spriteId, 'guy', self.pos.x, self.pos.y, unpack(self.color))
end

---@param vec Vector
---@param canMoveTo Collider
function Guy:moveVec(vec, canMoveTo)
  local newPos = vector.add(self.pos, vec)
  if canMoveTo(newPos) then
    self.pos = newPos
  end
end

---@return Guy
function Guy.new(props)
  local guy = {}
  setmetatable(guy, { __index = Guy })
  guy.pos = props.pos or guy.pos
  guy.color = props.color or guy.color
  guy.spriteId = draw.addSprite('guy', guy.pos.x, guy.pos.y, unpack(guy.color))
  return guy
end

---@param guy Guy
---@param collider Collider
local function addWanderBehavior(guy, collider)
  local time = math.random()
  function guy:update(dt)
    time = time + dt
    while time > 0.25 do
      time = time % 0.25
      self:move(({ 'up', 'down', 'left', 'right' })[math.random(1, 4)], collider)
    end
  end
end

function Guy.makeLeader()
  local guy = Guy.new{
    pos = { x = 5, y = 5 },
    color = { 1, 1, 0, 1 },
  }
  return guy
end

---@param coord integer
function Guy.makeGoodGuy(coord)
  local guy = Guy.new{ pos = { x = coord, y = coord } }
  return guy
end

---@param collider Collider
function Guy.makeEvilGuy(collider)
  local guy = Guy.new{
    pos = { x = 22, y = 6 },
    color = { 1, 0, 0, 1 },
  }
  addWanderBehavior(guy, collider)
  return guy
end


return { Guy = Guy }