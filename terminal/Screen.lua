---@class terminal.Screen
---@field screenSize { tall: integer, wide: integer }
---@field cursor terminal.Cursor
---@field clear fun(self: terminal.Screen)
---@field scroll fun(self: terminal.Screen)
---@field putChar fun(self: terminal.Screen, char: string)
---@field echo fun(self: terminal.Screen, text: string)

local M = require 'core.Module'.define{..., metatable = {
  ---@type terminal.Screen
  __index = {
    clear = function (self)
      for _ = 1, self.screenSize.tall do
        table.remove(self)
      end

      for _ = 1, self.screenSize.tall do
        local line = {}
        for _ = 1, self.screenSize.wide do
          table.insert(line, ' ')
        end
        table.insert(self, line)
      end

      self.cursor:locate { x = 0, y = 0 }
    end,
    scroll = function (self)
      table.remove(self, 1)
      table.insert(self, {})
      for _ = 1, self.screenSize.wide do
        table.insert(self[self.screenSize.tall - 1], ' ')
      end
      self.cursor:locate { x = 0, y = self.screenSize.tall - 1 }
    end,
    putChar = function (self, char)
      local function onOverflow()
        self:scroll()
      end
      if char == '\n' then
        self.cursor:carriageReturn(onOverflow)
      else
        self[self.cursor.pos.y + 1][self.cursor.pos.x + 1] = char
        self.cursor:advance(onOverflow)
      end
    end,
    ---@param self table
    ---@param text string
    echo = function (self, text)
      if text == nil then
        text = 'nil'
      end
      for i = 1, #text do
        self:putChar(text:sub(i, i))
      end
    end,
  }
}}

function M.init(obj)
  require 'core.Dep' (obj, function (want)
    return { want.screenSize, want.cursor }
  end)

  obj:clear()
end

return M