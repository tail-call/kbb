---Console for in-game messages
---@class Console
---@field __module "Console"
---@field messages ConsoleMessage[] List of displayed messages
---@field say fun(self: Console, message: ConsoleMessage) Displays a message

local M = require('Module').define(..., 0)

local fadeOut = require('ConsoleMessage').mut.fadeOut

local meta = {
  ---@type Console
  __index = {
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
function M.init(console)
  console.messages = console.messages or {}
  setmetatable(console, meta)
end

---@param console Console
---@param dt number
function M.updateConsole(console, dt)
  for _, message in ipairs(console.messages) do
    fadeOut(message, dt)
  end
end

return M