local Guy = {
  x = 10,
  y = 6,
  ---@type love.Image
  image = nil,

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

return { Guy = Guy }