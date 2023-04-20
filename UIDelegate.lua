---@class UIDelegate
---@field topPanelText fun(): table Love2D colored text for top panel
---@field leftPanelText fun(): string Left panel text
---@field rightPanelText fun(): string Right panel text
---@field bottomPanelText fun(): string Bottom panel text
---@field shouldDrawFocusModeUI fun(): boolean True if should draw focus mode UI

local getTile = require('World').getTile

local WHITE_COLOR = { 1, 1, 1, 1 }

---@param game Game
---@param player Guy
local function makeUIDelegate(game, player)
  ---@type UIDelegate
  local uiDelegate = {
    topPanelText = function()
      return {
        WHITE_COLOR,
        string.format(
          'Score: %d | FPS: %.1f\n%02d:%02d',
          game.score,
          love.timer.getFPS(),
          math.floor(game.time / 60),
          math.floor(game.time % 60)
        ),
      }
    end,
    leftPanelText = function ()
      local tileUnderCursor = getTile(game.world, game.cursorPos) or '???'
      return string.format(
        ''
          .. 'Time: %02d:%02d\n (paused)\n'
          .. 'Terrain:\n %s'
          .. '\nCoords:\n %sX %sY'
          .. '\nB] build\n (5 wood)'
          .. '\nM] message'
          .. '\nR] ritual'
          .. '\nT] warp',
        math.floor(game.time / 60),
        math.floor(game.time % 60),
        tileUnderCursor,
        game.cursorPos.x,
        game.cursorPos.y
      )
    end,
    rightPanelText = function ()
      local header = '<- Tab ->\n\n'

      local idx = 1 + (game.activeTab % 2)

      if idx == 1 then
        return string.format(
          ''
            .. header
            .. 'Name:\n %s\n'
            .. 'Rank:\n Harmless\n'
            .. 'Coords:\n %sX %sY\n'
            .. 'HP:\n %s/%s\n'
            .. 'Action:\n %.2f/%.2f\n'
            .. 'Moves:\n  %s\n',
          game.player.name,
          game.player.pos.x,
          game.player.pos.y,
          game.player.stats.hp,
          game.player.stats.maxHp,
          game.player.timer,
          game.player.speed,
          game.player.stats.moves
        )
      elseif idx == 2 then
        return ''
            .. header
          .. ' CONTROLS  \n'
          .. 'WASD:  move\n'
          .. 'LMB:recruit\n'
          .. 'Spc:  focus\n'
          .. '1234: scale\n'
          .. 'F:   follow\n'
          .. 'G:  dismiss\n'
          .. 'C:     chop\n'
          .. 'Z:     zoom\n'
      end
      return ''
    end,
    bottomPanelText = function ()
      return string.format(
        'Wood: %s | Stone: %s | Pretzels: %s',
        game.resources.wood,
        game.resources.stone,
        game.resources.pretzels
      )
    end,
    shouldDrawFocusModeUI = function()
      return game.isFocused
    end,
  }
  return uiDelegate
end

return {
  makeUIDelegate = makeUIDelegate,
}