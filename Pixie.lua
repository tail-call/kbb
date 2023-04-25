---A pixie is a texture + quad + transform with animation support

---@class Pixie
---@field texture love.Texture
---@field quad love.Quad
---@field pos Vector
---@field isFlipped boolean
---@field transform love.Transform
---@field isRightStep boolean
---@field transformSpeed number
---@field targetTransform love.Transform
---@field color number[]

---@class PixieMutator
---@field movePixie fun(self: Pixie, pos: Vector): nil
---@field updatePixie fun(self: Pixie, dt: number): nil
---@field playSpawnAnimation fun(self: Pixie, pos: Vector): nil

local M = require('Module').define(..., 0)

---@type PixieMutator
M.mut = {
  movePixie = function (self, pos)
    self.isRightStep = not self.isRightStep
    self.transformSpeed = 12
    self.targetTransform:setTransformation(
      pos.x * 16, pos.y * 16
    )
    local hDirection = pos.x - self.pos.x
    if hDirection < 0 and self.isFlipped then
      self.isFlipped = false
    end
    if hDirection > 0 or self.isFlipped then
      self.targetTransform:scale(-1, 1)
      self.targetTransform:translate(-16, 0)
      self.isFlipped = true
    end
    local vDirection = pos.y - self.pos.y
    -- Moving horizontally
    if hDirection ~= 0 then
    end
    -- Moving vertically
    if vDirection < 0 then
      self.transform:scale(1, 1.1)
    else
      self.transform:scale(1, 0.9)
    end
    -- Moving vertically
    if self.isRightStep then
      self.transform:rotate(0.1)
    else
      self.transform:rotate(-0.1)
    end
    self.pos = pos
  end,
  updatePixie = function (self, dt)
    local m1 = { self.transform:getMatrix() }
    local m2 = { self.targetTransform:getMatrix() }
    local m3 = {}

    for i = 1, #m1 do
      m3[i] = m1[i] + (m2[i] - m1[i]) * dt * self.transformSpeed
    end

    self.transform:setMatrix(unpack(m3))
  end,
  playSpawnAnimation = function (self, pos)
    self.transformSpeed = 8
    self.transform:setTransformation(
      pos.x * 16, pos.y * 16
    ):scale(8, 8):translate(
      32, -24
    )
    self.targetTransform:setTransformation(
      pos.x * 16, pos.y * 16
    )
  end,
}

---@param pixie Pixie
---@return Pixie
function M.init(pixie, load)
  pixie.texture = require('Tileset').getTileset().image
  pixie.quad = pixie.quad
  pixie.isRightStep = pixie.isRightStep or false
  pixie.pos = { x = 0, y = 0 }
  pixie.isFlipped = false
  pixie.transform = love.math.newTransform()
  pixie.transformSpeed = 1
  pixie.color = pixie.color or { 1, 1, 1, 1 }
  pixie.targetTransform = love.math.newTransform()

  return pixie
end

return M