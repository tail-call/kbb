local Guy = {
  x = 10,
  y = 6,
  ---@type love.Image
  image = nil,

  update = function (dt)
  end,

  ---@param key 'up' | 'down' | 'left' | 'right'
  move = function (self, key)
    if key == 'up' then
      self.y = self.y - 1
    elseif key == 'down' then
      self.y = self.y + 1
    elseif key == 'left' then
      self.x = self.x - 1
    elseif key == 'right' then
      self.x = self.x + 1
    end
  end
}

function Guy.new()
  local guy = {}
  setmetatable(guy, { __index = Guy })
  return guy
end

function Guy.makeWanderingGuy()
  local guy = Guy.new()
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