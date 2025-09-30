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

SetModel {
  prompt = '',
  activeTab = 0,
  nextTab = function (self)
    self.activeTab = self.activeTab + 1
  end,
  rightPanelText = function ()
    local game = Model.game
    local numFollowers = game.squad:numFollowers()
    local idx = 1 + (Model.activeTab % (1 + numFollowers))
    local header = ('<- Tab %d ->\n\n'):format(idx)

    local function formatGuy(guy)
      return string.format(
        ''
          .. header
          .. 'Name:\n %s\n'
          .. 'Rank:\n Harmless\n'
          .. 'Coords:\n %sX %sY\n'
          .. 'HP:\n %s/%s\n'
          .. 'Action:\n %.2f/%.2f\n'
          .. 'Moves:\n  %s\n',
        guy.name,
        guy.pos.x,
        guy.pos.y,
        guy.stats.hp,
        guy.stats.maxHp,
        guy.timer,
        guy.speed,
        guy.stats.moves
      )
    end

    if idx == 1 then
      if not game.player then return 'Player\nis nil' end

      return formatGuy(game.player)
    else
      local follower = game.squad:followerByIdx(idx - 1)
      if follower then
        return formatGuy(follower)
      else
        return header .. '\n<???>'
      end
    end
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
      controls = 'Space] edit\nLMB] recruit\nRMB] go\n8] save\nZ] zoom\nF] follow\nE] wonder\nQ] gather\nT] warp\nC] collect\nH] respawn\n'
    elseif game.mode == 'edit' then
      controls = 'Space] focus\nLMB] paint\nC] change tile\n'
    end
    local totalTiles = game.world.height * game.world.width
    return {
      WHITE_COLOR,
      string.format(
        'Score: %d | Revealed: %d/%d | Deaths: %d | %0.ffps\n',
        game.stats.score,
        game.world.revealedTilesCount,
        totalTiles,
        game.stats.deathsCount,
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

local sidePanelWidth = 88
local btnColorNormal = { r = 0.5, g = 0.2, b = 0.2, a = 1 }
local btnColorHover = { r = 0.9, g = 0.5, b = 0.5, a = 1 }
local btnColorPush = { r = 0.2, g = 0.1, b = 0.1, a = 1 }
local transparentColor = { r = 0, g = 0, b = 0, a = 0 }
local panelHoverColor = { r = 0, g = 0, b = 0, a = 0.5 }

local glassPanelBg = Background(function (state)
  if state == "normal" then
    return transparentColor
  else
    return panelHoverColor
  end
end)

local buttonBg = Background(function (state)
  if state == "normal" then
    return btnColorNormal
  elseif state == "hover" then
    return btnColorHover
  elseif state == "push" then
    return btnColorPush
  end
end)

local function Action(fun)
  return { 'action', fun = fun }
end

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
    Size(sidePanelWidth, 'full'),
    Text('Space] exit\n1,2,3,4] scale UI'),
    Background(0.5, 0.1, 0.5, 1),
  },
  Panel { -- Empty underlay for console
    shouldDraw = Model.shouldDrawFocusModeUI,
    transform = function (drawState)
      return Origin():translate(sidePanelWidth, FullHeight(drawState) - 60)
    end,
    Size(240, 52),
    Text(''),
    Background(0.25, 0.25, 0.25, 1),
  },
  Panel { -- Right panel
    transform = function (drawState)
      return Origin():translate(FullWidth(drawState) - sidePanelWidth, 8)
    end,
    Size(sidePanelWidth, 128),
    Model.rightPanelText,
    glassPanelBg,
  },
  Panel { -- Bottom panel
    transform = function (drawState)
      return Origin():translate(0, FullHeight(drawState) - 8)
    end,
    Size('full', 8),
    Model.bottomPanelText,
    Background(0.5, 0.5, 0.5, 1),
  },
  Panel { -- Fly btn
    transform = function (drawState)
      return Origin():translate(16, FullHeight(drawState) - 24)
    end,
    Size(24, 16),
    Text('FLY'),
    buttonBg,
    Action(function ()
      Model.game.player.pixie:setIsFloating(not Model.game.player.pixie.isFloating)
    end),
  },
}