---A patch of land
---@class Patch
---@field name string Name of the patch
---@field world World Containing world
---@field coords core.Vector Coordinates

local Patch = Class {
  ...,
  slots = { '!world', '!coords' }
}

---@param patch Patch
function Patch.init(patch)
  require 'core.Dep' (patch, function (want)
    return { want.world, want.coords }
  end)
  patch.name = patch.name or string.format(
    'PATCH (%d,%d)', patch.coords.x, patch.coords.y
  )
end

---@param patch Patch
function Patch.patchCenter(patch)
  return patch.coords.x * 8 + 4, patch.coords.y * 8 + 4
end

return Patch