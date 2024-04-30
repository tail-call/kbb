local screenSize = { wide = 80, tall = 24 }

local keyListener = nil

---@type terminal.Screen
local screen = require 'terminal.Screen'.new {
  screenSize = screenSize,
  cursor = require 'terminal.Cursor'.new {
    screenSize = screenSize
  }
}

---@type terminal.Readline
local readline = require 'terminal.Readline'.new {
  screen = screen
}

local builtinCommands = {
  cls = function ()
    screen:clear()
  end,
}

local os = {
  currentDir = '/',

  setCurrentDir = function (self, path)
    self.currentDir = require 'core.string'
      .forceSlashAtEnd(path)
  end
}

local function splitToWords(line)
  local words = {}
  for word in string.gmatch(line, '[^%s]+') do
    table.insert(words, word)
  end
  return words
end

local function runCommand(input)
  local function onFinish()
    screen:setShouldScroll(true)
    screen:putChar('\n')
  end
  xpcall(function ()
    local lang = require 'core.Dump'.makeLanguage {
      print = function (...)
        for k, v in ipairs {...} do
          screen:echo(v)
        end
        screen:echo('\n')
      end,
      ---@type lang.System
      Sys = {
        screen = screen,
        getKey = function ()
          return coroutine.yield('getKey')
        end,
        goToScene = function (sceneName, ...)
          require(sceneName).go(...)
        end,
        setCurrentDir = function (path)
          os:setCurrentDir(path)
        end,
        getCurrentDir = function ()
          return os.currentDir
        end,
      }
    }

    local args = splitToWords(input)
    local commandName = args[1]
    table.remove(args, 1)

    local command = builtinCommands[commandName]

    if not command then
      command = loadfile('bin/' .. commandName .. '.lua')
    end

    if not command then
      screen:echo(('command not found: %s\n'):format(commandName))
      return
    end

    require 'core.coroutine'.exhaust(function ()
      return lang.call(command, unpack(args))
    end, function (request, resume)
      if request == 'getKey' then
        keyListener = resume
      else
        error('oh no')
      end
    end)

    onFinish()
  end, function (err)
    screen:echo(err)
    onFinish()
  end)
end

local function fetchInput()
  screen.cursor:carriageReturn(function ()
    screen:scroll()
  end)

  local line = table.concat(readline.input)
  readline:clear()

  return line
end

OnDraw(function ()
  love.graphics.push('transform')
  love.graphics.scale(1.5, 3)
  for rep = 1, 2 do
    if rep == 1 then
      love.graphics.setColor(1, 1, 1, 1)
    elseif rep == 2 then
      love.graphics.translate(0.5, 0)
      love.graphics.setColor(1, 1, 1, 0.5)
    end
    for i, line in ipairs(screen.chars) do
      for x = 1, #line do
        love.graphics.print(line[x], (x - 1) * 8, (i - 1) * 8)
      end
    end
  end
  love.graphics.setColor(1, 1, 1, 1)
  if readline.screen.cursor.timer.value > readline.screen.cursor.timer.threshold / 2 then
    love.graphics.print('_', readline.screen.cursor.pos.x * 8, readline.screen.cursor.pos.y * 8)
  end

  love.graphics.pop()
  love.graphics.scale(3, 3)
end)

OnLoad(function ()
  screen:echo('KB-DOS v15.1\nType "scene scene.menu" to play\n>')
end)

OnUpdate(function (dt)
end)

OnTextInput(function (text)
  if not keyListener then
    readline:addChar(text)
  end
end)

OnKeyPressed(function (key, scancode, isrepeat)
  if keyListener then
    require 'sfx'.playBoop()
    keyListener(key)
    return
  end

  if scancode == 'backspace' then
    readline:rubBack()
  elseif scancode == 'return' then
    runCommand(fetchInput())
    screen:echo('>')
  end
end)
