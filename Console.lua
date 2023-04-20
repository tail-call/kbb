---@class Console Bottom console
---@field messages ConsoleMessage[] List of displayed messages
---@field say fun(self: Console, message: ConsoleMessage) Displays a message

local Console = {}

---@return Console
function Console.makeConsole()
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

---@param console Console
---@param dt number
function Console.updateConsole(console, dt)
  for _, message in ipairs(console.messages) do
    message:fadeOut(dt)
  end
end

return Console