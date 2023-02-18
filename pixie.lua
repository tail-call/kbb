-- A pixie is a texture + quad + transform with animation support

---@class Pixie
---@field texture love.Texture
---@field quad love.Quad
---@field transform love.Transform
---@field color number[]
---@field draw fun(self: Pixie): nil

local Pixie = {}

---@return Pixie
function Pixie.new(texture, quad)
  local pixie = {
    texture = texture,
    quad = quad,
    transform = love.math.newTransform(),
    color = { 1, 1, 1, 1 },
  }
  setmetatable(pixie, { __index = Pixie })
  return pixie
end

---@param self Pixie
function Pixie:draw()
  local r, g, b, a = love.graphics.getColor()
  love.graphics.setColor(unpack(self.color))
  love.graphics.draw(self.texture, self.quad, self.transform)
  love.graphics.setColor(r, g, b, a)
end

---@param self Pixie
---@param dt number
function Pixie:update(dt)
end

return Pixie