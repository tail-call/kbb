---@module 'lang/ui'

---@class UIModel
---
---@field prompt string Command line prompt text
---@field console Console Bottom console
---
---@field leftPanelText fun(): string Left panel text
---@field rightPanelText fun(): string Right panel text
---@field bottomPanelText fun(): string Bottom panel text
---@field topPanelText fun(): table
---
---@field activeTab integer Current active tab in the right panel
---@field nextTab fun(self: UIModel) Switches tab in the UI
---
---@field shouldDrawFocusModeUI fun(): boolean True if should draw focus mode UI

local WHITE_COLOR = { 1, 1, 1, 1 }
local GRAY_COLOR = { 0.5, 0.5, 0.5, 1 }
local game = Game()

SetModel {
  console = Console(),
  prompt = '',
  activeTab = 0,
  nextTab = function (self)
    self.activeTab = self.activeTab + 1
  end,
  didTypeCharacter = function () end,
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
        game.player.name,
        game.player.pos.x,
        game.player.pos.y,
        game.player.stats.hp,
        game.player.stats.maxHp,
        game.player.timer,
        game.player.speed,
        game.player.stats.moves,
        game.deathsCount
      )
    elseif idx == 2 then
      return ''
        .. header
        .. ' DEBUG\n'
        .. Format('mayMove %s\n', game.player.mayMove)
        .. Format('pos %s\n', FormatVector(game.player.pos))
    elseif idx == 3 then
      return ''
        .. header
        .. ' INVENTORY  \n'
        .. Dump(game.resources)
    end
    return ''
  end,
  bottomPanelText = function ()
    return Format(
      '%02d:%02d Wd=%s St=%s Pr=%s Gr=%s Wt=%s',
      math.floor(game.time / 60),
      math.floor(game.time % 60),
      game.resources.wood,
      game.resources.stone,
      game.resources.pretzels,
      game.resources.grass,
      game.resources.water
    )
  end,
  topPanelText = function ()
    local player = game.player
    local controls = ''
    if game.mode == 'normal' then
      controls = 'Space] paint\nLMB] recruit\n8] save\nZ] zoom\nF] follow\nQ] gather\nT] warp\nC] collect\n'     
    elseif game.mode == 'paint' then
      controls = 'Space] focus\nLMB] paint\n'
    end
    return {
      WHITE_COLOR,
      Format(
        'Score: %d | Revealed: %d/%d %0.ffps\n',
        game.score,
        game.world.revealedTilesCount,
        game.world.height * game.world.width,
        FPS()
      ),
      WHITE_COLOR,
      controls,
      player.stats.moves >= 1 and WHITE_COLOR or GRAY_COLOR,
      'G] dismiss 1t\n',
      player.stats.moves >= 25 and game.resources.pretzels >= 1 and WHITE_COLOR or GRAY_COLOR,
      'R] ritual 25t 1p\n',
      player.stats.moves >= 50 and game.resources.wood >= 5 and WHITE_COLOR or GRAY_COLOR,
      'B] build 50t 5w\n',
    }
  end,
  shouldDrawFocusModeUI = function ()
    return game.mode == 'focus'
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