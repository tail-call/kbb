---@class RecruitCircle
---@field radius number | nil
---@field growthSpeed number
---@field maxRadius number
---@field grow fun(self: RecruitCircle, dt: number) -- Increase recruit circle radius if active
---@field reset fun(self: RecruitCircle) -- Activates recruit circle
---@field clear fun(self: RecruitCircle) -- Deactivates recruit circle

local RECRUIT_CIRCLE_MAX_RADIUS = 6
local RECRUIT_CIRCLE_GROWTH_SPEED = 6

---@return RecruitCircle
local function makeRecruitCircle()
  ---@type RecruitCircle
  local recruitCircle = {
    radius = nil,
    maxRadius = RECRUIT_CIRCLE_MAX_RADIUS,
    growthSpeed = RECRUIT_CIRCLE_GROWTH_SPEED,
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
    end
  }
  return recruitCircle
end

---@param recruitCircle RecruitCircle
---@return boolean
local function isRecruitCircleActive(recruitCircle)
  return recruitCircle.radius ~= nil
end

return {
  makeRecruitCircle = makeRecruitCircle,
  isRecruitCircleActive = isRecruitCircleActive,
}