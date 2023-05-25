---@module 'lang/ui'

local WHITE_COLOR = { 1, 1, 1, 1 }
local GRAY_COLOR = { 0.5, 0.5, 0.5, 1 }

SetModel {
  rightPanelText = function ()
    local header = '<- Tab ->\n\n'

    local idx = 1 + (Model.activeTab % 3)

    if idx == 1 then
      return Format(
        ''
          .. header
          .. 'Name:\n %s\n'
          .. 'Rank:\n Harmless\n'
          .. 'Coords:\n %sX %sY\n'
          .. 'HP:\n %s/%s\n'
          .. 'Action:\n %.2f/%.2f\n'
          .. 'Moves:\n  %s\n'
          .. 'Deaths:\n  %s\n',
        Model.game.player.name,
        Model.game.player.pos.x,
        Model.game.player.pos.y,
        Model.game.player.stats.hp,
        Model.game.player.stats.maxHp,
        Model.game.player.timer,
        Model.game.player.speed,
        Model.game.player.stats.moves,
        Model.game.deathsCount
      )
    elseif idx == 2 then
      return ''
        .. header
        .. ' DEBUG\n'
        .. Format('mayMove %s\n', Model.game.player.mayMove)
        .. Format('pos %s\n', FormatVector(Model.game.player.pos))
    elseif idx == 3 then
      return ''
        .. header
        .. ' INVENTORY  \n'
        .. Dump(Model.game.resources)
    end
    return ''
  end,
  bottomPanelText = function ()
    return Format(
      '%02d:%02d Wd=%s St=%s Pr=%s Gr=%s Wt=%s',
      math.floor(Model.game.time / 60),
      math.floor(Model.game.time % 60),
      Model.game.resources.wood,
      Model.game.resources.stone,
      Model.game.resources.pretzels,
      Model.game.resources.grass,
      Model.game.resources.water
    )
  end,
  topPanelText = function ()
    local player = Model.game.player
    local controls = ''
    if Model.game.mode == 'normal' then
      controls = 'Space] paint\nLMB] recruit\n8] save\nZ] zoom\nF] follow\nQ] gather\nT] warp\nC] collect\n'     
    elseif Model.game.mode == 'paint' then
      controls = 'Space] focus\nLMB] paint\n'
    end
    return {
      WHITE_COLOR,
      Format(
        'Score: %d | Revealed: %d/%d %0.ffps\n',
        Model.game.score,
        Model.game.world.revealedTilesCount,
        Model.game.world.height * Model.game.world.width,
        FPS()
      ),
      WHITE_COLOR,
      controls,
      player.stats.moves >= 1 and WHITE_COLOR or GRAY_COLOR,
      'G] dismiss 1t\n',
      player.stats.moves >= 25 and Model.game.resources.pretzels >= 1 and WHITE_COLOR or GRAY_COLOR,
      'R] ritual 25t 1p\n',
      player.stats.moves >= 50 and Model.game.resources.wood >= 5 and WHITE_COLOR or GRAY_COLOR,
      'B] build 50t 5w\n',
    }
  end,
  shouldDrawFocusModeUI = function ()
    return Model.game.mode == 'focus'
  end,
}

return UI {
  Panel { -- Top panel
    background = RGBA(0.1, 0.5, 0.5, 1),
    transform = function () return Origin() end,
    w = FullWidth,
    h = Fixed(8),
    Model.topPanelText,
  },
  Panel { -- Left panel
    shouldDraw = Model.shouldDrawFocusModeUI,
    background = RGBA(0.5, 0.1, 0.5, 1),
    transform = function ()
      return Origin():translate(0, 8)
    end,
    w = Fixed(88),
    h = FullHeight,
    Text('Space] exit\n1,2,3,4] scale UI'),
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