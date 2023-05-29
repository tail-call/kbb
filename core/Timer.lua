---A looping timer
---@class core.Timer
---@field __module 'core.Timer'
---# Properties
---@field speed number Time multiplication factor
---@field value number Current timer value
---@field threshold number Timer resets when value exceeds threshold
---# Methods
---@field package update fun(self: core.Timer, dt: number) Advances timer's value

---@type { [core.Timer]: true }
local timers = require 'core.table'.weaken({}, 'k')

---@type Module
local M = require 'core.Module'.define{..., version = 0, metatable = {
  ---@type core.Timer
  __index = {
    update = function (self, dt)
      self.value = (
        self.value + self.speed * dt
      ) % self.threshold
    end
  }
}}

---@param dt number
function M.update(dt)
  for timer in pairs(timers) do
    timer:update(dt)
  end
end

---@param obj core.Timer
function M.init(obj)
  obj.speed = obj.speed or 1
  obj.value = obj.value or 0
  obj.threshold = obj.threshold or 1

  timers[obj] = true
end

return M