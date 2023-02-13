---@alias position { x: integer, y: integer }

---@class Guy
---@field pos position
---@field image love.Image
---@field update fun(self: Guy, dt: number): nil
---@field move fun(self: Guy, key: string): nil

local Guy = {
  ---@type position
  pos = { x = 0, y = 0 },
  ---@type love.Image
  image = nil,

  update = function (dt)
  end,

  ---@param key 'up' | 'down' | 'left' | 'right'
  move = function (self, key)
    local pos = { x = self.pos.x, y = self.pos.y }

    if key == 'up' then
      pos.y = pos.y - 1
    elseif key == 'down' then
      pos.y = pos.y + 1
    elseif key == 'left' then
      pos.x = pos.x - 1
    elseif key == 'right' then
      pos.x = pos.x + 1
    end

    self.pos = pos
  end
}

---@return Guy
function Guy.new(props)
  local guy = {}
  setmetatable(guy, { __index = Guy })
  guy.pos = props.pos or guy.pos
  return guy
end

function Guy.makeWanderingGuy()
  local guy = Guy.new{ pos = { x = 6, y = 6 } }
  guy.time = math.random()
  function guy:update(dt)
    self.time = self.time + dt
    while self.time > 0.25 do
      self.time = self.time % 0.25
      self:move(({ 'up', 'down', 'left', 'right' })[math.random(1, 4)])
    end
  end
  return guy
end


return { Guy = Guy }