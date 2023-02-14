local draw = require('./draw')
local vector = require('./vector')

---@alias Collider fun(v: Vector): boolean

---@class Guy
---@field pos Vector
---@field update fun(self: Guy, dt: number): nil
---@field draw fun(self: Guy): nil
---@field move fun(self: Guy, key: string, canMoveTo: Collider): boolean): nil

local Guy = {
  ---@type Vector
  pos = { x = 0, y = 0 },

  update = function (dt)
  end,
}

---@param self Guy
---@param key 'up' | 'down' | 'left' | 'right'
---@param canMoveTo Collider
function Guy:move(key, canMoveTo)
  local newPos = vector.add(self.pos, vector.dir[key])
  if canMoveTo(newPos) then
    self.pos = newPos
  end
end

function Guy:draw()
  draw.guy(self.pos)
end

---@return Guy
function Guy.new(props)
  local guy = {}
  setmetatable(guy, { __index = Guy })
  guy.pos = props.pos or guy.pos
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

---@param guy Guy
local function addEvilAppearance(guy)
  function guy:draw()
    draw.evilGuy(self.pos)
  end
end

---@param collider Collider
function Guy.makeWanderingGuy(collider)
  local guy = Guy.new{ pos = { x = 6, y = 6 } }
  addWanderBehavior(guy, collider)
  return guy
end

---@param collider Collider
function Guy.makeEvilGuy(collider)
  local guy = Guy.new{ pos = { x = 22, y = 6 } }
  addWanderBehavior(guy, collider)
  addEvilAppearance(guy)
  return guy
end


return { Guy = Guy }