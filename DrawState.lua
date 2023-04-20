---@class DrawState
---@field windowScale number Window scale
---@field setWindowScale fun(self: DrawState, windowScale: number) Changes window scale
---@field camera Vector3 Camera position in the world
---@field cursorTimer number Cursor animation timer
---@field battleTimer number Battle animation timer
---@field waterTimer number Water animation timer
---@field advanceTime fun(self: DrawState, dt: number)

local CURSOR_TIMER_SPEED = 2
local BATTLE_TIMER_SPEED = 2
local WATER_TIMER_SPEED = 1/4

---@return DrawState
local function makeDrawState()
  ---@type DrawState
  local drawState = {
    windowScale = 1,
    setWindowScale = function (self, windowScale)
      self.windowScale = windowScale
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
    end
  }
  return drawState
end

return {
  makeDrawState = makeDrawState,
}