---Message in the console
---@class ConsoleMessage
---@field __module "ConsoleMessage"
---@field text string Message text
---@field lifetime number Seconds before message is faded out
---@field fadeOut fun(self: ConsoleMessage, dt: number) Applies fade out to the message

local ConsoleMessage = Class {
  ...,
  ---@type ConsoleMessage
  index = {
    fadeOut = function (self, dt)
      self.lifetime = math.max(self.lifetime - dt, 0)
    end,
  },
  requiredProperties = { 'text', 'lifetime' },
}

return ConsoleMessage