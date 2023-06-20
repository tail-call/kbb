---@class terminal.Cursor
---@field pos core.Vector
---@field timer core.Timer
---@field screenSize { tall: integer, wide: integer }
---@field locate fun(self: terminal.Cursor, newPos: core.Vector)
---@field goHome fun(self: terminal.Cursor)
---@field carriageReturn fun(self: terminal.Cursor, onOverflow: fun())
---@field advance fun(self: terminal.Cursor, onOverflow: fun())
---@field retreat fun(self: terminal.Cursor)

local M = require 'core.class'.define{..., metatable = {
  __index = {
    locate = function (self, newPos)
      self.pos = newPos
    end,
    goHome = function (self, newPos)
      self:locate(require 'core.Vector'.new { x = 0, y = 0 })
    end,
    carriageReturn = function (self, onOverflow)
      self.pos.x = 0
      self.pos.y = self.pos.y + 1

      if self.pos.y >= self.screenSize.tall then
        onOverflow()
      end
    end,
    advance = function (self, onOverflow)
      self.pos.x = self.pos.x + 1

      if self.pos.x >= self.screenSize.wide then
        self:carriageReturn(onOverflow)
      end
    end,
    retreat = function (self)
      self.pos.x = self.pos.x - 1

      if self.pos.x < 0 then
        error('underflow')
      end
    end,
  }
}}

function M.init(cursor)
  require 'core.Dep' (cursor, function (want)
    return { want.screenSize }
  end)
  cursor.pos = cursor.pos or require 'core.Vector'.new { x = 0, y = 0 }
  cursor.timer = cursor.timer or require 'core.Timer'.new { threshold = 1/4 }
end

return M