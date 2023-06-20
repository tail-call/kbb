---@class terminal.Screen
---@field screenSize { tall: integer, wide: integer }
---@field cursor terminal.Cursor
---@field chars string[][]
---@field shouldScroll boolean
---@field clear fun(self: terminal.Screen)
---@field scroll fun(self: terminal.Screen)
---@field putChar fun(self: terminal.Screen, char: string)
---@field echo fun(self: terminal.Screen, text: string)
---@field setShouldScroll fun(self: terminal.Screen, value: boolean)

local M = Class {
  ...,
  ---@type terminal.Screen
  index = {
    clear = function (self)
      self.chars = {}

      for _ = 1, self.screenSize.tall do
        ---@type string[]
        local line = {}
        for _ = 1, self.screenSize.wide do
          table.insert(line, ' ')
        end
        table.insert(self.chars, line)
      end

      self.cursor:goHome()
    end,
    scroll = function (self)
      if self.shouldScroll then
        table.remove(self.chars, 1)
        table.insert(self.chars, {})
        for _ = 1, self.screenSize.wide do
          table.insert(self.chars[self.screenSize.tall - 1], ' ')
        end
        self.cursor:locate { x = 0, y = self.screenSize.tall - 1 }
      end
    end,
    putChar = function (self, char)
      local function onOverflow()
        self:scroll()
      end
      if char == '\n' then
        self.cursor:carriageReturn(onOverflow)
      else
        local y = math.min(self.cursor.pos.y + 1, self.screenSize.tall)
        local x = self.cursor.pos.x + 1
        self.chars[y][x] = char
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
    setShouldScroll = function (self, value)
      self.shouldScroll = value
    end,
  }
}

function M.init(obj)
  require 'core.Dep' (obj, function (want)
    return { want.screenSize, want.cursor }
  end)

  if not obj.chars then
    obj:clear()
  end
end

return M