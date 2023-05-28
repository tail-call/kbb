---A representation of a building
---@class Building: Object2D
---@field __module "Building"

local M = require('core.Module').define{...}

---@param building Building
function M.init(building)
  require 'core.Dep' (building, function (want)
    return { want.pos }
  end)
end

---@param building Building
---@return string
function M.tooltipText(building)
  return 'It\'s a house'
end

return M