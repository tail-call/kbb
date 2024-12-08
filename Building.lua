---A representation of a building
---@class Building: Object2D, core.class
---@field __module "Building"
local Building = Class {
  ...,
  slots = { '!pos' },
  ---@type Building
  index = {},
}

---@return string
function Building.tooltipText()
  return 'It\'s a house'
end

return Building