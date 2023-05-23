local buffer = require('string.buffer')

---@type Scene
local M = require 'Module'.define{...}

local withColor = require('Util').withColor

---@type GameScene
local storedScene = nil

local output = ''
local input = ''
local offset = { x = 0, y = 0}

---@param scene GameScene
function M.load(scene)
  storedScene = scene
end

---@param text string
function M.textinput(text)
  input = input .. text
end

---@param ... string
local function echo(...)
  local buf = buffer.new()
  buf:put(output)
  for _, v in ipairs{ ... } do
    buf:put(tostring(v))
  end
  buf:put('\n')
  output = buf:tostring()
end

function M.keypressed(key, scancode, isrepeat)
  if scancode == 'escape' then
   require('Scene').setScene(storedScene, '#back')
  elseif scancode == 'home' then
    offset.x = offset.x + love.graphics.getWidth() / 2
  elseif scancode == 'end' then
    offset.x = offset.x - love.graphics.getWidth() / 2
  elseif scancode == 'pageup' then
    offset.y = offset.y + love.graphics.getHeight() / 2
  elseif scancode == 'pagedown' then
    offset.y = offset.y - love.graphics.getHeight() / 2
  elseif scancode == 'return' then
    local savedPrompt = input
    input = ''
    local chunk, compileErrorMessage = loadstring(savedPrompt, 'commandline')
    echo('lua>' .. savedPrompt)
    if chunk ~= nil then
      setfenv(chunk, require('Commands').new {
        root = storedScene.getGame(),
        echo = echo,
        clear = function ()
          output = ''
        end,
        scribe = function (text)
          echo('no scribe for you today')
          -- M.mut.addText(
          --   game,
          --   require('Text').new {
          --     text = text,
          --     pos = game.player.pos,
          --   }
          -- )
        end,
      })
      local isSuccess, errorMessage = pcall(chunk)
      if not isSuccess then
        echo(errorMessage)
      end
    else
      echo(compileErrorMessage or 'Unknown error')
    end
  elseif scancode == 'backspace' then
    input = input:sub(1,-2)
  end
end

local function promptText()
  local isBlink = 0 == (
    math.floor(love.timer.getTime() * 4) % 2
  )
  if isBlink then
    return ('%slua>%s_'):format(output, input)
  else
    return ('%slua>%s'):format(output, input)
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
  love.graphics.translate(offset.x, offset.y)
  love.graphics.print('welcome to command line, try help() or hit escape if confused', 10, 8)
  love.graphics.print('use fn+arrows (or pageup, pagedown, home, end) to scroll', 10, 16)
  love.graphics.print(promptText(), 10, 24)
end

return M