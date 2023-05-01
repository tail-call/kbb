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

---@param text string
local function echo(text)
  output = table.concat { output, text, '\n' }
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
    local chunk = loadstring(savedPrompt, 'commandline')
    if chunk ~= nil then
      echo('lua>' .. savedPrompt)
      local commands
      commands = {
        reload = function(moduleName)
          require('Module').reload(moduleName)
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
        print = function (something)
          echo(something)
        end,
        help = function ()
          for k in pairs(commands) do
            commands.print(k)
          end
        end,
        quit = function ()
          package.loaded['MenuScene'] = nil
          require('main').loadScene('MenuScene', 'fromgame')
        end,
      }
      setfenv(chunk, commands)
      chunk()
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
  love.graphics.print(tostring(storedScene), 10, 10)
  love.graphics.print('press X to X-it', 10, 20)
  love.graphics.print(promptText(), 10, 30)
end

return M