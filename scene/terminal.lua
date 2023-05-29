---@class terminal.Readline
---@field screen terminal.Screen
---@field input string[]
---@field pos integer
---@field clear fun(self: terminal.Readline)
---@field addChar fun(self: terminal.Readline, char: string)
---@field rubBack fun(self: terminal.Readline)
---@field rubForward fun(self: terminal.Readline)

---@return terminal.Readline
local function makeReadline(opts)
  return {
    screen = opts.screen,
    input = {},
    pos = 1,
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
end

local screenSize = { wide = 80, tall = 24 }

local readline = makeReadline {
  screen = require 'terminal.Screen'.new {
    screenSize = screenSize,
    cursor = require 'terminal.Cursor'.new {
      screenSize = screenSize
    }
  }
}

readline.screen:echo('KB-DOS v15.1\n>')

local function forceSlashAtEnd(str)
  for k in str:gmatch('.$') do
    if k ~= '/' then
      str = str .. '/'
    end
  end
  return str
end

local os = {
  currentDir = '/',

  setCurrentDir = function (self, path)
    self.currentDir = forceSlashAtEnd(path)
  end
}

local function runCommand(words, commands)
  local command = commands[words[1]]
  if not command then
    readline.screen:echo(('command not found: %s\n'):format(words[1]))
    return
  end

  command(unpack(words))
end

local function splitToWords(line)
  local words = {}
  for word in string.gmatch(line, '[^%s]+') do
    table.insert(words, word)
  end
  return words
end

local function doStuff(words)
  runCommand(
    words,
    {
      type = function (_, filename)
        local file = io.open(filename)
        if not file then
          error('no file')
        end
        local content = file:read('*a')
        file:close()
        readline.screen:echo(content)
        readline.screen:echo('\n')
      end,
      cls = function (_)
        readline.screen:clear()
      end,
      cd = function (_, path)
        if not path then
          readline.screen:echo(('You are in %s.\n'):format(os.currentDir))
          return
        end

        os:setCurrentDir(path)
      end,
      dir = function (_, path)
        if not path then
          path = os.currentDir
        end
        path = forceSlashAtEnd(path)
        local items = love.filesystem.getDirectoryItems(path)
        for _, item in ipairs(items) do
          local info = love.filesystem.getInfo(item)
          if info.type == 'directory' then
            item = forceSlashAtEnd(item)
          end
          readline.screen:echo(('%s%s\n'):format(path, item))
        end
      end,
      run = function (_)
        require 'scene.menu'.go('initial')
      end
    }
  )

  readline.screen:echo('>')
end

local function fetchInput()
  readline.screen.cursor:carriageReturn(function ()
    readline.screen:scroll()
  end)

  local line = table.concat(readline.input)
  readline:clear()

  return line
end

OnDraw(function ()
  love.graphics.scale(1.5, 3)
  for rep = 1, 2 do
    if rep == 1 then
      love.graphics.setColor(1, 1, 1, 1)
    elseif rep == 2 then
      love.graphics.translate(0.5, 0)
      love.graphics.setColor(1, 1, 1, 0.5)
    end
    for i, line in ipairs(readline.screen) do
      for x = 1, #line do
        love.graphics.print(line[x], (x - 1) * 8, (i - 1) * 8)
      end
    end
  end
  love.graphics.setColor(1, 1, 1, 1)
  if readline.screen.cursor.timer.value > readline.screen.cursor.timer.threshold / 2 then
    love.graphics.print('_', readline.screen.cursor.pos.x * 8, readline.screen.cursor.pos.y * 8)
  end
end)

OnUpdate(function (dt)
  readline.screen.cursor.timer:advance(dt)
end)

OnTextInput(function (text)
  readline:addChar(text)
end)

OnKeyPressed(function (key, scancode, isrepeat)
  if scancode == 'backspace' then
    readline:rubBack()
  elseif scancode == 'return' then
    doStuff(splitToWords(fetchInput()))
  end
end)
