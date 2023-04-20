---@class ConsoleMessage Message in the bottom console
---@field text string Message text
---@field lifetime number Seconds before message is faded out
---@field fadeOut fun(self: ConsoleMessage, dt: number) Applies fade out to the message

---@class Console Bottom console
---@field messages ConsoleMessage[] List of displayed messages
---@field say fun(self: Console, message: ConsoleMessage) Displays a message
---@field removeTopMessage fun(self: Console) Removes a topmost message

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

---@param messages ConsoleMessage[]
---@return Console
local function makeConsole(messages)
  ---@type Console
  local console = {
    messages = messages,
    say = function (self, message)
      table.insert(self.messages, message)
    end,
    removeTopMessage = function (self)
      table.remove(self.messages, 1)
    end
  }
  return console
end

return {
  makeConsole = makeConsole,
  makeConsoleMessage = makeConsoleMessage,
}