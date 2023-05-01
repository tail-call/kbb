local M = require 'Module'.define(..., 0)

local withColor = require('Util').withColor

---@type GameScene
local storedScene = nil

local output = ''
local prompt = ''

---@param scene GameScene
function M.load(scene)
  storedScene = scene
end

---@param text string
function M.textinput(text)
  prompt = prompt .. text
end

---@param ... string
local function echo(...)
  output = table.concat(
    require('tbl').imap({ output, ... }, tostring)
  )
  output = output .. '\n'
end

---@param key love.KeyConstant
---@param scancode love.Scancode
---@param isrepeat boolean
function M.keypressed(key, scancode, isrepeat)
  if scancode == 'escape' then
   require('main').setScene(storedScene, '#back')
  elseif scancode == 'return' then
    local savedPrompt = prompt
    prompt = ''
    local chunk, compileErrorMessage = loadstring(savedPrompt, 'commandline')
    echo('lua>' .. savedPrompt)
    if chunk ~= nil then
      local commands
      commands = {
        reloadHelp = function ()
          echo [[
---Reloads a module
---@param moduleName string
reload(moduleName)]]
        end,
        reload = function(moduleName)
          require('Module').reload(moduleName)
        end,
        scribeHelp = function ()
          echo [[
---Scribes a message in the world
---@param message string
scribe(message)]]
        end,
        scribe = function(text)
          error('no scribe for you today')
          -- M.mut.addText(
          --   game,
          --   require('Text').new {
          --     text = text,
          --     pos = game.player.pos,
          --   }
          -- )
        end,
        printHelp = function ()
          echo [[
---Prints objects to a console
---@param ... any[]
print(...)]]
        end,
        print = function (...)
          echo(...)
        end,
        clearHelp = function ()
          echo [[
---Clears the screen
clear()]]
        end,
        clear = function (...)
          output = ''
        end,
        helpHelp = function ()
          echo [[
---Outputs info about a command in the console
---@param name string
help(name)]]
        end,
        help = function (arg)
          if arg == nil then
            echo 'try these commands or hit escape if confused:\n'
            for k in pairs(commands) do
              echo(('help(\'%s\')'):format(k))
            end
          else
            local helpFunc = commands[arg .. 'Help']
            if helpFunc == nil then
              echo(([[
---Don't use this command
%s(...) -- bad]]):format(arg))
            else
              helpFunc()
            end
          end
        end,
        quitHelp = function ()
          echo [[
---Quits to the main menu
quit()]]
        end,
        quit = function ()
          package.loaded['MenuScene'] = nil
          require('main').loadScene('MenuScene', 'fromgame')
        end,
      }
      setfenv(chunk, commands)
      local isSuccess, errorMessage = pcall(chunk)
      if not isSuccess then
        echo(errorMessage)
      end
    else
      echo(compileErrorMessage or 'Unknown error')
    end
  elseif scancode == 'backspace' then
    prompt = prompt:sub(1,-2)
  end
end

local function promptText()
  local isBlink = 0 == (
    math.floor(love.timer.getTime() * 4) % 2
  )
  if isBlink then
    return ('%slua>%s_'):format(output, prompt)
  else
    return ('%slua>%s'):format(output, prompt)
  end
end

function M.draw()
  if storedScene ~= nil then
    storedScene.draw()
  end
  withColor(0, 0, 0, 0.8, function ()
    local w, h = love.window.getMode()
    love.graphics.rectangle('fill', 0, 0, w, h)
  end)
  love.graphics.origin()
  love.graphics.print('welcome to command line, try help() or hit escape if confused', 10, 8)
  love.graphics.print(promptText(), 10, 16)
end

return M