local M = require('Module').define(..., 0)

local SAVEFILE_NAME = './kobo2.kpss'
local AFTER_DRAW_DURATION = 0.05
local INTRO = [[
Welcome to KOBOLD PRINCESS SIMULATOR
+In-game controls:---------------------+
|1, 2, 3, 4) window scale         o o  |
|W, A, S, D) move                  w   |
|H, J, K, L) also move                 |
|arrow keys) also move                 |
|Return)     open lua console          |
|            (try typing 'help()')     |
|Escape)     close lua console         |
|N)          reload main guy           |
+--------------------------------------+
Now choose:

N) Start new game
L) Load game from disk (file kobo2.kpss)
F) Reload this menu
X) Exit game
]]

local cursorTimer = 0
local afterDraw = nil
local afterDrawTimer = nil
local doNothingCounter = 0
local extraText = ''

function M.load(type)
  if type == 'initial' then
    extraText = ''
  elseif type == 'reload' then
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
  local loadScene = require('main').loadScene
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
  elseif scancode == 'x' then
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