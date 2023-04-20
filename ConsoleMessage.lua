---@class ConsoleMessage Message in the bottom console
---@field text string Message text
---@field lifetime number Seconds before message is faded out
---@field fadeOut fun(self: ConsoleMessage, dt: number) Applies fade out to the message

---@param text string
---@param lifetime number
---@return ConsoleMessage
local function makeConsoleMessage(text, lifetime)
  ---@type ConsoleMessage
  local message = {
    text = text,
    lifetime = lifetime,
    fadeOut = function (self, dt)
      self.lifetime = math.max(self.lifetime - dt, 0)
    end,
  }
  return message
end

return {
  makeConsoleMessage = makeConsoleMessage,
}