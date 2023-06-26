---A pixie is a texture + quad + transform with animation support
---@class Pixie
---@field __module 'Pixie'
---# Properties
---@field texture love.Texture
---@field quad love.Quad
---@field pos core.Vector
---@field isFlipped boolean
---@field isFloating boolean
---@field transform love.Transform
---@field isRightStep boolean
---@field transformSpeed number
---@field targetTransform love.Transform
---@field color number[]
---# Methods
---@field playSpawnAnimation fun(self: Pixie, pos: core.Vector): nil
---@field move fun(self: Pixie, pos: core.Vector): nil
---@field update fun(self: Pixie, dt: number): nil
---@field setIsFloating fun(self: Pixie, value: boolean): nil

local Pixie = Class {
  ...,
  ---@type Pixie
  index = {
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
    move = function (self, pos)
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
        if not self.isFloating then
          self.targetTransform:translate(-16, 0)
        end
        self.isFlipped = true
      end
      local vDirection = pos.y - self.pos.y
      -- Moving horizontally
      if hDirection ~= 0 then
        -- Do nothing
      end
      if not self.isFloating then
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
      end
      self.pos = pos
    end,
    update = function (self, dt)
      local m1 = { self.transform:getMatrix() }
      local m2 = { self.targetTransform:getMatrix() }
      local m3 = {}

      for i = 1, #m1 do
        m3[i] = m1[i] + (m2[i] - m1[i]) * dt * self.transformSpeed
      end

      self.transform:setMatrix(unpack(m3))
    end,
    setIsFloating = function (self, value)
      self.isFloating = value
    end,
  }
}

---@param pixie Pixie
---@return Pixie
function Pixie.init(pixie)
  pixie.texture = require 'Tileset'.getTileset().image
  pixie.quad = pixie.quad or error 'quad is required'
  pixie.isRightStep = pixie.isRightStep or false
  pixie.pos = { x = 0, y = 0 }
  pixie.isFlipped = pixie.isFlipped or false
  pixie.isFloating = pixie.isFloating or false
  pixie.transform = love.math.newTransform()
  pixie.transformSpeed = 1
  pixie.color = pixie.color or { 1, 1, 1, 1 }
  pixie.targetTransform = love.math.newTransform()
end

return Pixie