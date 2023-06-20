---Message in the console
---@class ConsoleMessage
---@field __module "ConsoleMessage"
---@field text string Message text
---@field lifetime number Seconds before message is faded out
---@field fadeOut fun(self: ConsoleMessage, dt: number) Applies fade out to the message

local M = require('core.class').define{..., metatable = {
  ---@type ConsoleMessage
  __index = {
    fadeOut = function (self, dt)
      self.lifetime = math.max(self.lifetime - dt, 0)
    end,
  }
}}

---@param message ConsoleMessage
function M.init(message)
  require 'core.Dep' (message, function (want)
    return { want.text, want.lifetime }
  end)
end

return M