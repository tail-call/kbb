---@class VisionSource
---@field pos Vector Vision source's position
---@field sight integer Vision source's radius of sight

local VisionSource = {}

---Returns true if the target should be directly visible from the vision sourc
---@param vd2 number Square of vision's distance
---@param vs VisionSource Vision source
---@param t Vector
---@return boolean
function VisionSource.isVisible(vd2, vs, t)
  return vd2 + 2 - (vs.pos.x - t.x) ^ 2 - (vs.pos.y - t.y) ^ 2 > 0
end

---Calculates vision distance (in squares) given current light conditions
---@param visionSource VisionSource Vision source
---@param light number Amount of light: from 0.0 to 1.0
---@return integer distance
function VisionSource.calcVisionDistance(visionSource, light)
  return math.floor(visionSource.sight * light)
end

return VisionSource