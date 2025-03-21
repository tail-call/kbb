---Console for in-game messages
---@class Console: core.Object
---@field __module "Console"
---@field messages ConsoleMessage[] List of displayed messages
---@field say fun(self: Console, message: ConsoleMessage) Displays a message
local Console = Class {
  ..., 
  slots = {},
  ---@type Console
  index = {
    say = function (self, message)
      io.stdout:write(('\tEcho: %s\n'):format(message.text))
      table.insert(self.messages, message)
      while #self.messages >= 8 do
        table.remove(self.messages, 1)
      end
    end
  }
}

---@param console Console
function Console.init(console)
  console.messages = console.messages or {}
end

---@param console Console
---@param dt number
function Console.updateConsole(console, dt)
  for _, message in ipairs(console.messages) do
    message:fadeOut(dt)
  end
end

return Console