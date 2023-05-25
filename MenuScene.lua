---@class MenuScene: Scene
---@field load fun(kind: 'initial' | 'reload')

---@type MenuScene
local M = require('Module').define{...}

local SAVEFILE_NAME = './kobo2.kpss'
local AFTER_DRAW_DURATION = 0.05

local afterDraw = nil
local afterDrawTimer = nil

local uiModel = {
  extraText = '',
  cursorTimer = 0,
  doNothingCounter = 0,
}

local ui = require('UI').makeUIScript({}, './ui/menu.ui.lua', uiModel)

function M.load(kind)
  local extraText
  if kind == 'initial' then
    extraText = ''
  elseif kind == 'reload' then
    extraText = 'Reload successful.\n'
  else
    extraText = 'You came back from game.\n'
  end
  uiModel.extraText = extraText
end

function M.update(dt)
  uiModel.cursorTimer = uiModel.cursorTimer + 4 * dt
  if uiModel.cursorTimer > 1 then
    uiModel.cursorTimer = 0
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

  require('Draw').drawUI(require('DrawState').new(), ui)
end

---@param key love.KeyConstant
---@param scancode love.Scancode
---@param isrepeat boolean
function M.keypressed(key, scancode, isrepeat)
  local loadScene = require('Scene').loadScene
  afterDrawTimer = AFTER_DRAW_DURATION
  if scancode == 'l' then
    uiModel.extraText = '\nLOADING...'
    afterDraw = function ()
      loadScene('GameScene', SAVEFILE_NAME)
    end
  elseif scancode == 'n' then
    uiModel.extraText = '\nSTARTING NEW GAME...'
    afterDraw = function ()
      loadScene('GameScene', '#dontload')
    end
  elseif scancode == 'q' then
    uiModel.extraText = '\nQUITTING...'
    afterDraw = function ()
      love.event.quit()
    end
  elseif scancode == 'f' then
    uiModel.extraText = '\nRELOADING...'
    afterDraw = function ()
      loadScene('MenuScene', 'reload')
    end
  else
    uiModel.doNothingCounter = uiModel.doNothingCounter + 1
    uiModel.extraText = scancode:upper()
      .. ') Do nothing ('
      .. uiModel.doNothingCounter
      ..')\n'
    afterDraw = function ()
      afterDraw = nil
    end
  end
end

return M