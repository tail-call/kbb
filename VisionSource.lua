---@class VisionSource
---@field pos Vector Vision source's position
---@field sight integer Vision source's radius of sight

local VisionSource = {}

---Calculates vision distance (in squares) given current light conditions
---@param visionSource VisionSource Vision source
---@param light number Amount of light: from 0.0 to 1.0
---@return integer distance
function VisionSource.calcVisionDistance(visionSource, light)
  return math.floor(visionSource.sight * light)
end

return VisionSource