---@class Building
---@field __module "Building"
---@field pos Vector Building's position

local M = require('Module').define(..., 0)

---@param building Building
function M.init(building)
  building.pos = building.pos or error("Building: pos is required")
end

return M