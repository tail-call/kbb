---A looping timer
---@class Timer
---@field __module 'Timer'
---# Properties
---@field speed number Time multiplication factor
---@field value number Current timer value
---@field threshold number Timer resets when value exceeds threshold
---# Methods
---@field advance fun(self: Timer, dt: number) Advances timer's value

---@type { [Timer]: true }
local timers = require 'core.table'.weaken({}, 'k')

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

---@param dt number
function M.update(dt)
  for timer in pairs(timers) do
    timer:advance(dt)
  end
end

---@param obj Timer
function M.init(obj)
  obj.speed = obj.speed or 1
  obj.value = obj.value or 0
  obj.threshold = obj.threshold or 1

  timers[obj] = true
end

return M