---@class World
---@field width integer
---@field height integer
---@field tiles integer[]
---@field tileset love.Image[]
---@field draw fun(self: World): nil

local World = {
  width = 20,
  height = 13,
  tileset = { },
  tiles = { }
}

---@param self World
function World:draw()
  for i = 1, self.width do
    for j = 1, self.height do
      if i == 1 or j == 4 then
        love.graphics.draw(self.tileset[1], (i - 1) * 16, (j - 1) * 16)
      else
        love.graphics.draw(self.tileset[2], (i - 1) * 16, (j - 1) * 16)
      end
    end
  end
end

---@param tileset love.Image[]
---@return World
function World.new(tileset)
  local world = {}
  setmetatable(world, { __index = World })
  world.tileset = tileset
  return world
end

return { World = World }