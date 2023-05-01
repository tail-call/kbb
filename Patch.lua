---A patch of land
---@class Patch
---@field name string Name of the patch
---@field world World Containing world
---@field coords Vector Coordinates

local M = require('Module').define(..., 0)

---@param patch Patch
function M.init(patch)
  patch.world = patch.world or error('Patch: world is required')
  patch.coords = patch.coords or error('Patch: coords is required')
  patch.name = patch.name or ('PATCH %x %x'):format(patch.coords.x, patch.coords.y)
end

return M