local SAVEFILE_NAME = './kobo2.kpss'
local AFTER_DRAW_DURATION = 0.05

local afterDraw = nil
local afterDrawTimer = nil

local uiModel = {
  extraText = '',
  doNothingCounter = 0,
}

local ui = require 'ui.menu'(uiModel)

OnLoad(function (kind)
  local source = love.audio.newSource('music/title.xm', 'stream')
  source:play()
end)

OnUpdate(function (dt)
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