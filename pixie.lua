-- A pixie is a texture + quad + transform with animation support
local getTileset = require('./tileset').getTileset

---@class Pixie
---@field texture love.Texture
---@field quad love.Quad
---@field pos Vector
---@field flip boolean
---@field transform love.Transform
---@field targetTransform love.Transform
---@field color number[]
---@field move fun(self: Pixie, pos: Vector): nil
---@field update fun(self: Pixie, dt: number): nil

local Pixie = {}

---@return Pixie
function Pixie.new(texture, quad)
  local pixie = {
    texture = texture,
    quad = quad,
    pos = { x = 0, y = 0 },
    flip = false,
    transform = love.math.newTransform(),
    color = { 1, 1, 1, 1 },
    targetTransform = love.math.newTransform(),
  }
  setmetatable(pixie, { __index = Pixie })
  return pixie
end

---@param self Pixie
---@param pos Vector
function Pixie:move(pos)
  self.targetTransform:setTransformation(
    pos.x * 16, pos.y * 16
  )
  local direction = pos.x - self.pos.x
  if direction < 0 and self.flip then
    self.flip = false
  end
  if direction > 0 or self.flip then
    self.targetTransform:scale(-1, 1)
    self.targetTransform:translate(-16, 0)
    self.flip = true
  end
  local vDirection = pos.y - self.pos.y
  if direction ~= 0 then
    self.transform:translate(16, 4)
    self.transform:scale(1.5, 0.5)
    self.transform:translate(-16, 0)
  end
  if not (vDirection == 0) then
    self.transform:scale(0.5, 1.5)
  end
  self.pos = pos
end

---@param self Pixie
---@param dt number
function Pixie:update(dt)
  local m1 = { self.transform:getMatrix() }
  local m2 = { self.targetTransform:getMatrix() }
  local m3 = {}

  for i = 1, #m1 do
    m3[i] = (m1[i] + m2[i]) / 2
  end

  self.transform:setMatrix(unpack(m3))
end

---@param name string
---@return Pixie
local function makePixie(name)
  local tileset = getTileset()
  return Pixie.new(tileset.tiles, tileset.quads[name])
end

return {
  makePixie = makePixie,
}