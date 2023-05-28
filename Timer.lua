---A looping timer
---@class Timer
---@field __module 'Timer'
---# Properties
---@field speed number Time multiplication factor
---@field value number Current timer value
---@field threshold number Timer resets when value exceeds threshold
---# Methods
---@field advance fun(self: Timer, dt: number) Advances timer's value

-- TODO: hook timers up to some global timer manager

---@type Module
local M = require 'core.Module'.define{..., version = 0, metatable = {
  ---@type Timer
  __index = {
    advance = function (self, dt)
      self.value = (
        self.value + self.speed * dt
      ) % self.threshold
    end
  }
}}

---@param obj Timer
function M.init(obj)
  obj.speed = obj.speed or 1
  obj.value = obj.value or 0
  obj.threshold = obj.threshold or 1
end

return M