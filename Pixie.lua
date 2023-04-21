-- A pixie is a texture + quad + transform with animation support

---@class Pixie
---@field texture love.Texture
---@field quad love.Quad
---@field pos Vector
---@field flip boolean
---@field transform love.Transform
---@field transformSpeed number
---@field targetTransform love.Transform
---@field color number[]
---@field move fun(self: Pixie, pos: Vector): nil
---@field update fun(self: Pixie, dt: number): nil
---@field spawn fun(self: Pixie, pos: Vector): nil

---@param name string
---@param opts PixieOptions
---@return Pixie
local function makePixie(name, opts)
  local texture = opts.tileset.tiles
  local quad = opts.tileset.quads[name]

  ---@type Pixie
  local pixie = {
    texture = texture,
    quad = quad,
    pos = { x = 0, y = 0 },
    flip = false,
    transform = love.math.newTransform(),
    transformSpeed = 1,
    color = opts.color or { 1, 1, 1, 1 },
    targetTransform = love.math.newTransform(),
    move = function (self, pos)
      self.transformSpeed = 12
      self.targetTransform:setTransformation(
        pos.x * 16, pos.y * 16
      )
      local hDirection = pos.x - self.pos.x
      if hDirection < 0 and self.flip then
        self.flip = false
      end
      if hDirection > 0 or self.flip then
        self.targetTransform:scale(-1, 1)
        self.targetTransform:translate(-16, 0)
        self.flip = true
      end
      local vDirection = pos.y - self.pos.y
      -- Moving horizontally
      if hDirection ~= 0 then
        self.transform:translate(0, -8)
      end
      if not (vDirection == 0) then
        self.transform:scale(0.5, 1.5)
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
    spawn =function (self, pos)
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

  return pixie
end

return {
  makePixie = makePixie,
}