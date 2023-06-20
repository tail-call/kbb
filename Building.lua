---A representation of a building
---@class Building: Object2D
---@field __module "Building"

local Building = Class {
  ...,
  slots = { '!pos' },
}

---@return string
function Building.tooltipText()
  return 'It\'s a house'
end

return Building