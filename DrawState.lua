---@class DrawState
---@field windowScale number Window scale
---@field camera Vector3 Camera position in the world
---@field cursorTimer number Cursor animation timer
---@field battleTimer number Battle animation timer
---@field waterTimer number Water animation timer

---@return DrawState
local function makeDrawState()
  local drawState = {
    windowScale = 1,
    camera = { x = 266 * 16, y = 229 * 16, z = 0.01 },
    cursorTimer = 0,
    battleTimer = 0,
    waterTimer = 0,
  }
  return drawState
end

return {
  makeDrawState = makeDrawState,
}