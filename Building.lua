---A representation of a building
---@class Building: Object2D
---@field __module "Building"

local M = require('Module').define{...}

---@param building Building
function M.init(building)
  building.pos = building.pos or error("Building: pos is required")
end

---@param building Building
---@return string
function M.tooltipText(building)
  return 'It\'s a house'
end

return M