---Message in the console
---@class ConsoleMessage
---@field __module "ConsoleMessage"
---@field text string Message text
---@field lifetime number Seconds before message is faded out

---@class ConsoleMessageMutator Message in the bottom console
---@field fadeOut fun(self: ConsoleMessage, dt: number) Applies fade out to the message

local M = require('Module').define(..., 0)

---@type ConsoleMessageMutator
M.mut = {
  fadeOut = function (self, dt)
    self.lifetime = math.max(self.lifetime - dt, 0)
  end,
}

---@param message ConsoleMessage
function M.init(message)
  message.text = message.text or error('Message: text is required')
  message.lifetime = message.lifetime or error('Message: lifetime is requried')
end

return M