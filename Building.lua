---A representation of a building
---@class Building: Object2D
---@field __module "Building"

local M = require('Module').define{..., version = 0}

---@param building Building
function M.init(building)
  building.pos = building.pos or error("Building: pos is required")
end

return M