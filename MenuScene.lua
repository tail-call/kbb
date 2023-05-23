---@class MenuScene: Scene
---@field load fun(kind: 'initial' | 'reload')

---@type MenuScene
local M = require('Module').define{...}

local SAVEFILE_NAME = './kobo2.kpss'
local AFTER_DRAW_DURATION = 0.05
local INTRO = [[
Welcome to KOBOLD PRINCESS SIMULATOR

+In-game controls:---------------------+
|W, A, S, D) move                 o o  |
|H, J, K, L) also move             w   |
|Arrow keys) also move                 |
|Space)      switch mode               |
|Return)     open lua console          |
|            (try typing 'help()')     |
|Escape)     close lua console         |
|N)          reload main guy           |
|E)          terramorphing             |
+--------------------------------------+

Now choose:

N) Play in empty world
L) Load world from disk (kobo2.kpss)
F) Reload this menu
Q) Quit game
]]

local cursorTimer = 0
local afterDraw = nil
local afterDrawTimer = nil
local doNothingCounter = 0
local extraText = ''

function M.load(kind)
  if kind == 'initial' then
    extraText = ''
  elseif kind == 'reload' then
    extraText = 'Reload successful.\n'
  else
    extraText = 'You came back from game.\n'
  end
end

function M.update(dt)
  cursorTimer = cursorTimer + 4 * dt
  if cursorTimer > 1 then
    cursorTimer = 0
  end
  if afterDrawTimer ~= nil then
    afterDrawTimer = afterDrawTimer - dt
    if afterDrawTimer <= 0 then
      afterDrawTimer = nil
      afterDraw()
    end
  end
end

function M.draw()
  love.graphics.scale(3, 3)
  love.graphics.print(
    INTRO
      .. (extraText)
      .. (afterDraw and '' or '\nPress a key')
      .. (cursorTimer > 0.5 and '_' or ''),
    0, 0
  )
end

---@param key love.KeyConstant
---@param scancode love.Scancode
---@param isrepeat boolean
function M.keypressed(key, scancode, isrepeat)
  local loadScene = require('Scene').loadScene
  afterDrawTimer = AFTER_DRAW_DURATION
  if scancode == 'l' then
    extraText = '\nLOADING...'
    afterDraw = function ()
      loadScene('GameScene', SAVEFILE_NAME)
    end
  elseif scancode == 'n' then
    extraText = '\nSTARTING NEW GAME...'
    afterDraw = function ()
      loadScene('GameScene', '#dontload')
    end
  elseif scancode == 'q' then
    afterDraw = function ()
      extraText = '\nQUITTING...'
      love.event.quit()
    end
  elseif scancode == 'f' then
    extraText = '\nRELOADING...'
    afterDraw = function ()
      loadScene('MenuScene', 'reload')
    end
  else
    doNothingCounter = doNothingCounter + 1
    extraText = scancode:upper()
      .. ') Do nothing ('
      .. doNothingCounter
      ..')\n'
    afterDraw = function ()
      afterDraw = nil
    end
  end
end

return M