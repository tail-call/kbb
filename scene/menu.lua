---@module 'lang/scene'

local SAVEFILE_NAME = './kobo2.kpss'
local AFTER_DRAW_DURATION = 0.05

local afterDraw = nil
local afterDrawTimer = nil

local uiModel = {
  extraText = '',
  cursorTimer = 0,
  doNothingCounter = 0,
}

local ui = require 'ui.menu'(uiModel)

OnLoad(function (kind)
  local extraText
  if kind == 'initial' then
    extraText = ''
  elseif kind == 'reload' then
    extraText = 'Reload successful.\n'
  else
    extraText = 'You came back from game.\n'
  end
  uiModel.extraText = extraText
end)

OnUpdate(function (dt)
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
end)

OnDraw(function ()
  love.graphics.scale(3, 3)
  DrawUI(ui)
end)

---@param key love.KeyConstant
---@param scancode love.Scancode
---@param isrepeat boolean
OnKeyPressed(function (key, scancode, isrepeat)
  afterDrawTimer = AFTER_DRAW_DURATION
  if scancode == 'l' then
    uiModel.extraText = '\nLOADING...'
    afterDraw = function ()
      require 'scene.game'.go(SAVEFILE_NAME)
    end
  elseif scancode == 'n' then
    uiModel.extraText = '\nSTARTING NEW GAME...'
    afterDraw = function ()
      require 'scene.game'.go('#dontload')
    end
  elseif scancode == 'q' then
    uiModel.extraText = '\nQUITTING...'
    afterDraw = function ()
      GoBack()
    end
  elseif scancode == 'f' then
    uiModel.extraText = '\nRELOADING...'
    require 'Draw'.nextFont()
    require(Self.path).go('reload')
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
end)