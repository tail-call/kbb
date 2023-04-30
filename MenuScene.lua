local M = require('Module').define(..., 0)
local SAVEFILE_NAME = './kobo2.kpss'
local AFTER_DRAW_DURATION = 0.05
local INTRO = [[
Welcome to KOBOLD PRINCESS SIMULATOR

N) Start new game
L) Load game from disk (file kobo2.kpss)
X) Exit game

Press a key]]

local cursorTimer = 0
local afterDraw = nil
local afterDrawTimer = nil

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
      .. (afterDraw and '\nLOADING...' or '')
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
    afterDraw = function ()
      loadScene(require('GameScene'), SAVEFILE_NAME)
    end
  elseif scancode == 'n' then
    afterDraw = function ()
      loadScene(require('GameScene'), '???')
    end
  elseif scancode == 'x' then
    afterDraw = function ()
      error('Exit not implemented')
    end
  end
end

return M