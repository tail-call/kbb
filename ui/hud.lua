---@module 'lang/ui'

---@class UIModel
---
---@field prompt string Command line prompt text
---
---@field game Game Game
---@field leftPanelText fun(): string Left panel text
---@field rightPanelText fun(): string Right panel text
---@field bottomPanelText fun(): string Bottom panel text
---@field topPanelText fun(): table
---
---@field activeTab integer Current active tab in the right panel
---@field nextTab fun(self: UIModel) Switches tab in the UI
---
---@field shouldDrawFocusModeUI fun(): boolean True if should draw focus mode UI

---@type UIModel
local Model = Model

local WHITE_COLOR = { 1, 1, 1, 1 }
local GRAY_COLOR = { 0.5, 0.5, 0.5, 1 }

local formatVector = require 'core.Vector'.formatVector

SetModel {
  prompt = '',
  activeTab = 0,
  nextTab = function (self)
    self.activeTab = self.activeTab + 1
  end,
  rightPanelText = function ()
    local game = Model.game
    local header = '<- Tab ->\n\n'

    local idx = 1 + (Model.activeTab % 2)

    if idx == 1 then
      if not game.player then return 'Player\nis nil' end

      return string.format(
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
        game.stats.deathsCount
      )
    elseif idx == 2 then
      return ''
        .. header
        .. ' DEBUG\n'
        .. string.format('mayMove %s\n', game.player.mayMove)
        .. string.format('pos %s\n', formatVector(game.player.pos))
    end
    return ''
  end,
  bottomPanelText = function ()
    local game = Model.game
    return string.format(
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
    local game = Model.game
    local player = game.player
    if not player then return 'Wow, you lose! Press H to revive' end

    local controls = ''
    if game.mode == 'normal' then
      controls = 'Space] paint\nLMB] recruit\n8] save\nZ] zoom\nF] follow\nE] wonder\nQ] gather\nT] warp\nC] collect\nX] fly\nH] respawn\n'
    elseif game.mode == 'paint' then
      controls = 'Space] focus\nLMB] paint\nC] change tile\n'
    end
    return {
      WHITE_COLOR,
      string.format(
        'Score: %d | Revealed: %d/%d %0.ffps\n',
        game.stats.score,
        game.world.revealedTilesCount,
        game.world.height * game.world.width,
        love.timer.getFPS()
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
    return Model.game.mode == 'focus'
  end,
}

return {
  Panel { -- Top panel
    transform = function () return Origin() end,
    Size('full', 8),
    Model.topPanelText,
    Background(0.1, 0.5, 0.5, 1),
  },
  Panel { -- Left panel
    shouldDraw = Model.shouldDrawFocusModeUI,
    transform = function ()
      return Origin():translate(0, 8)
    end,
    Size(88, 'full'),
    Text('Space] exit\n1,2,3,4] scale UI'),
    Background(0.5, 0.1, 0.5, 1),
  },
  Panel { -- Empty underlay for console
    shouldDraw = Model.shouldDrawFocusModeUI,
    transform = function (drawState)
      return Origin():translate(88, FullHeight(drawState) - 60)
    end,
    Size(240, 52),
    Text(''),
    Background(0.25, 0.25, 0.25, 1),
  },
  Panel { -- Right panel
    transform = function (drawState)
      return Origin():translate(FullWidth(drawState) - 88, 8)
    end,
    Size(88, 128),
    Model.rightPanelText,
    Background(0, 0, 0, 0),
  },
  Panel { -- Bottom panel
    transform = function (drawState)
      return Origin():translate(0, FullHeight(drawState) - 8)
    end,
    Size('full', 8),
    Model.bottomPanelText,
    Background(0.5, 0.5, 0.5, 1),
  },
}