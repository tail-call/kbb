local SCREEN_WIDE = 40
local SCREEN_TALL = 24

local cursor = {
  ---@type Vector
  pos = require 'core.Vector'.new { x = 0, y = 0 },
  ---@type Timer
  timer = require 'Timer'.new { threshold = 1/4 },
  locate = function (self, newPos)
    self.pos = newPos
  end,
  carriageReturn = function (self, onOverflow)
    self.pos.x = 0
    self.pos.y = self.pos.y + 1

    if self.pos.y >= SCREEN_TALL then
      onOverflow()
    end
  end,
  advance = function (self, onOverflow)
    self.pos.x = self.pos.x + 1

    if self.pos.x >= SCREEN_WIDE then
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

---@return string[][]
local screen = ({
  init = function (self)
    for _ = 1, SCREEN_TALL do
      local line = {}
      for _ = 1, SCREEN_WIDE do
        table.insert(line, ' ')
      end
      table.insert(self, line)
    end

    self:echo('KB-DOS v15.1\n>')
    return self
  end,
  scroll = function (self)
    table.remove(self, 1)
    table.insert(self, {})
    for _ = 1, SCREEN_WIDE do
      table.insert(self[SCREEN_TALL - 1], ' ')
    end
    cursor:locate { x = 0, y = SCREEN_TALL - 1 }
  end,
  putChar = function (self, char)
    local function onOverflow()
      self:scroll()
    end
    if char == '\n' then
      cursor:carriageReturn(onOverflow)
    else
      print(self[cursor.pos.y + 1])
      self[cursor.pos.y + 1][cursor.pos.x + 1] = char
      cursor:advance(onOverflow)
    end
  end,
  ---@param self table
  ---@param text string
  echo = function (self, text)
    for i = 1, #text do
      self:putChar(text:sub(i, i))
    end
  end,
}):init()

local readline = {
  input = {},
  pos = 1,
  clear = function (self)
    self.input = {}
    self.pos = 1
  end,
  addChar = function (self, char)
    screen:putChar(char)
    table.insert(self.input, char)
    self.pos = self.pos + 1
  end,
  rubBack = function (self)
    if #self.input == 0 then
      return
    end
    cursor:retreat()
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

local function executeLine()
  local line = table.concat(readline.input)
  readline:clear()

  screen:echo(string.format('You typed "%s"\n', line))
  screen:echo('>')
end

OnDraw(function ()
  love.graphics.scale(3, 3)
  for i, line in ipairs(screen) do
    for x = 1, #line do
      love.graphics.print(line[x], (x - 1) * 8, (i - 1) * 8)
    end
  end
  if cursor.timer.value > cursor.timer.threshold / 2 then
    love.graphics.print('_', cursor.pos.x * 8, cursor.pos.y * 8)
  end
end)

OnUpdate(function (dt)
  cursor.timer:advance(dt)
end)

OnKeyPressed(function (key, scancode, isrepeat)
  if #key == 1 then
    readline:addChar(key)
  elseif scancode == 'backspace' then
    readline:rubBack()
  elseif scancode == 'space' then
    readline:addChar(' ')
  elseif scancode == 'return' then
    cursor:carriageReturn(function ()
      screen:scroll()
    end)
    executeLine()
  end
end)
