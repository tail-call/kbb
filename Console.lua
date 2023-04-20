---@class ConsoleMessage Message in the bottom console
---@field text string Message text
---@field lifetime number Seconds before message is faded out
---@field fadeOut fun(self: ConsoleMessage, dt: number) Applies fade out to the message

---@class Console Bottom console
---@field messages ConsoleMessage[] List of displayed messages
---@field say fun(self: Console, message: ConsoleMessage) Displays a message

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

---@return Console
local function makeConsole()
  ---@type Console
  local console = {
    messages = {},
    say = function (self, message)
      table.insert(self.messages, message)
      while #self.messages >= 8 do
        table.remove(self.messages, 1)
      end
    end,
  }
  return console
end

return {
  makeConsole = makeConsole,
  makeConsoleMessage = makeConsoleMessage,
}