---@module 'lang/ui'

SetModel {
  leftPanelText = function ()
    return 'Space] exit\n1,2,3,4] scale UI'
  end,
}

return UI {
  Panel { -- Top panel
    background = RGBA(0.1, 0.5, 0.5, 1),
    transform = function () return Origin() end,
    w = FullWidth,
    h = Fixed(8),
    coloredText = Model.topPanelText,
  },
  Panel { -- Left panel
    shouldDraw = Model.shouldDrawFocusModeUI,
    background = RGBA(0.5, 0.1, 0.5, 1),
    transform = function ()
      return Origin():translate(0, 8)
    end,
    w = Fixed(88),
    h = FullHeight,
    Model.leftPanelText,
  },
  Panel { -- Empty underlay for console
    shouldDraw = Model.shouldDrawFocusModeUI,
    background = RGBA(0.25, 0.25, 0.25, 1),
    transform = function (drawState)
      return Origin():translate(88, FullHeight(drawState) - 60)
    end,
    w = Fixed(240),
    h = Fixed(52),
  },
  Panel { -- Right panel
    background = RGBA(0, 0, 0, 0),
    transform = function (drawState)
      return Origin():translate(FullWidth(drawState)-88, 8)
    end,
    w = Fixed(88),
    h = Fixed(128),
    Model.rightPanelText,
  },
  Panel { -- Bottom panel
    background = RGBA(0.5, 0.5, 0.5, 1),
    transform = function (drawState)
      return Origin():translate(0, FullHeight(drawState) - 8)
    end,
    w = FullWidth,
    h = Fixed(8),
    Model.bottomPanelText,
  },
  Panel { -- Command line
    shouldDraw = Model.shouldDrawFocusModeUI,
    background = RGBA(0, 0, 0, 0),
    transform = function (drawState)
      return Origin():translate(96, FullHeight(drawState) - 76)
    end,
    w = Fixed(200),
    h = FullHeight,
  },
}