---@class DrawState
---
---@field windowScale number Window scale
---@field setWindowScale fun(self: DrawState, windowScale: number) Changes window scale
---
---@field tileset Tileset Tileset used for drawing
---
---@field camera Vector3 Camera position in the world
---@field setCamera fun(self: DrawState, offset: Vector, z: number, magn: number)
---
---@field cursorTimer number Cursor animation timer
---@field battleTimer number Battle animation timer
---@field waterTimer number Water animation timer
---@field advanceTime fun(self: DrawState, dt: number)

local lerp3 = require('Vector3').lerp3

local CURSOR_TIMER_SPEED = 2
local BATTLE_TIMER_SPEED = 2
local WATER_TIMER_SPEED = 1/4
local CAMERA_LERP_SPEED = 10

---@param tileset Tileset
---@return DrawState
local function new(tileset)
  ---@type DrawState
  local drawState = {
    windowScale = 3,
    tileset = tileset,
    setWindowScale = function (self, windowScale)
      self.windowScale = windowScale

      self.tileset:regenerate()
    end,
    camera = { x = 266 * 16, y = 229 * 16, z = 0.01 },
    cursorTimer = 0,
    battleTimer = 0,
    waterTimer = 0,
    advanceTime = function (self, dt)
      self.battleTimer = (
        self.battleTimer + BATTLE_TIMER_SPEED * dt
      ) % 1

      self.waterTimer = (
        self.waterTimer + WATER_TIMER_SPEED * dt
      ) % (math.pi / 2)

      self.cursorTimer = (
        self.cursorTimer + CURSOR_TIMER_SPEED * dt
      ) % (math.pi * 2)
    end,
    setCamera = function (self, offset, dt, magn)
      self.camera = lerp3(
        self.camera,
        { x = offset.x, y = offset.y, z = magn },
        dt * CAMERA_LERP_SPEED
      )
    end
  }
  return drawState
end

return {
  new = new,
}