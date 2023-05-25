---@module 'lang/ui'

local TRANSPARENT_PANEL_COLOR = { r = 0, g = 0, b = 0, a = 0 }
local GRAY_PANEL_COLOR = { r = 0.5, g = 0.5, b = 0.5, a = 1 }
local DARK_GRAY_PANEL_COLOR = { r = 0.25, g = 0.25, b = 0.25, a = 1 }

return UI {
  Panel { -- Top panel
    background = GRAY_PANEL_COLOR,
    transform = function () return Origin() end,
    w = FullWidth,
    h = Fixed(8),
    coloredText = Model.topPanelText,
  },
  Panel { -- Left panel
    shouldDraw = Model.shouldDrawFocusModeUI,
    background = GRAY_PANEL_COLOR,
    transform = function ()
      return Origin():translate(0, 8)
    end,
    w = Fixed(88),
    h = FullHeight,
    text = Model.leftPanelText,
  },
  Panel { -- Empty underlay for console
    shouldDraw = Model.shouldDrawFocusModeUI,
    background = DARK_GRAY_PANEL_COLOR,
    transform = function (drawState)
      return Origin():translate(88, FullHeight(drawState) - 60)
    end,
    w = Fixed(240),
    h = Fixed(52),
  },
  Panel { -- Right panel
    background = TRANSPARENT_PANEL_COLOR,
    transform = function (drawState)
      return Origin():translate(FullWidth(drawState)-88, 8)
    end,
    w = Fixed(88),
    h = Fixed(128),
    text = Model.rightPanelText,
  },
  Panel { -- Bottom panel
    background = GRAY_PANEL_COLOR,
    transform = function (drawState)
      return Origin():translate(0, FullHeight(drawState) - 8)
    end,
    w = FullWidth,
    h = Fixed(8),
    text = Model.bottomPanelText,
  },
  Panel { -- Command line
    shouldDraw = Model.shouldDrawFocusModeUI,
    background = TRANSPARENT_PANEL_COLOR,
    transform = function (drawState)
      return Origin():translate(96, FullHeight(drawState) - 76)
    end,
    w = Fixed(200),
    h = FullHeight,
  },
}