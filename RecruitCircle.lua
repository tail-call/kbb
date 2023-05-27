---@class RecruitCircle
---@field __module 'RecruitCircle'
---@field radius number | nil
---@field growthSpeed number
---@field maxRadius number
---@field grow fun(self: RecruitCircle, dt: number) -- Increase recruit circle radius if active
---@field reset fun(self: RecruitCircle) -- Activates recruit circle
---@field clear fun(self: RecruitCircle) -- Deactivates recruit circle

local M = require 'Module'.define{..., metatable = {
  ---@type RecruitCircle
  __index = {
    reset = function(self)
      self.radius = 0
    end,
    clear = function(self)
      self.radius = nil
    end,
    grow = function (self, dt)
      self.radius = math.min(
        self.radius + dt * self.growthSpeed,
        self.maxRadius
      )
    end,
  }
}}

local RECRUIT_CIRCLE_MAX_RADIUS = 6
local RECRUIT_CIRCLE_GROWTH_SPEED = 6

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