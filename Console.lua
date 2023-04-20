---@class Console Bottom console
---@field messages ConsoleMessage[] List of displayed messages
---@field say fun(self: Console, message: ConsoleMessage) Displays a message

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
}