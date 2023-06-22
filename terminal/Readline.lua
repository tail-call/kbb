---@class terminal.Readline
---@field screen terminal.Screen
---@field input string[]
---@field pos integer
---@field clear fun(self: terminal.Readline)
---@field addChar fun(self: terminal.Readline, char: string)
---@field rubBack fun(self: terminal.Readline)
---@field rubForward fun(self: terminal.Readline)

local Readline = Class {
  ...,
  ---@type terminal.Readline
  index = {
    clear = function (self)
      self.input = {}
      self.pos = 1
    end,
    addChar = function (self, char)
      self.screen:putChar(char)
      table.insert(self.input, char)
      self.pos = self.pos + 1
    end,
    rubBack = function (self)
      if #self.input == 0 then
        return
      end
      self.screen.cursor:retreat()
      table.remove(self.input)
      self.pos = self.pos - 1
    end,
    rubForward = function (self)
      if #self.input == 0 then
        return
      end
      table.remove(self.input)
      self.pos = self.pos - 1
    end,
  }
}

---@param obj terminal.Readline
function Readline.init(obj)
  obj.input = obj.input or {}
  obj.pos = obj.pos or 1
end

return Readline