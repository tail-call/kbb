---A patch of land
---@class Patch
---@field name string Name of the patch
---@field world World Containing world
---@field coords core.Vector Coordinates

local M = require('core.class').define{...}

---@param patch Patch
function M.init(patch)
  require 'core.Dep' (patch, function (want)
    return { want.world, want.coords }
  end)
  patch.name = patch.name or ('PATCH (%d,%d)'):format(patch.coords.x, patch.coords.y)
end

---@param patch Patch
function M.patchCenter(patch)
  return patch.coords.x * 8 + 4, patch.coords.y * 8 + 4
end

return M