---@class RecruitCircle
---@field radius number | nil
---@field growthSpeed number
---@field maxRadius number

---@class RecruitCircleMutator
---@field growRecruitCircle fun(self: RecruitCircle, dt: number) -- Increase recruit circle radius if active
---@field resetRecruitCircle fun(self: RecruitCircle) -- Activates recruit circle
---@field clearRecruitCircle fun(self: RecruitCircle) -- Deactivates recruit circle

local M = require('Module').define(..., 0)

local RECRUIT_CIRCLE_MAX_RADIUS = 6
local RECRUIT_CIRCLE_GROWTH_SPEED = 6

---@type RecruitCircleMutator
M.mut = require('Mutator').new {
  resetRecruitCircle = function(self)
    self.radius = 0
  end,
  clearRecruitCircle = function(self)
    self.radius = nil
  end,
  growRecruitCircle = function (self, dt)
    self.radius = math.min(
      self.radius + dt * self.growthSpeed,
      self.maxRadius
    )
  end,
}

---@param recruitCircle RecruitCircle
function M.init(recruitCircle)
  recruitCircle.radius = recruitCircle.radius or nil
  recruitCircle.maxRadius = RECRUIT_CIRCLE_MAX_RADIUS
  recruitCircle.growthSpeed = RECRUIT_CIRCLE_GROWTH_SPEED
end

---@param recruitCircle RecruitCircle
---@return boolean
function M.isRecruitCircleActive(recruitCircle)
  return recruitCircle.radius ~= nil
end

return M