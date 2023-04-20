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
      local function charSheet(guy)
        return function ()
          return string.format(
            ''
              .. 'Name:\n %s\n'
              .. 'Rank:\n Harmless\n'
              .. 'Coords:\n %sX %sY\n'
              .. 'HP:\n %s/%s\n'
              .. 'Action:\n %.2f/%.2f\n',
            guy.name,
            guy.pos.x,
            guy.pos.y,
            guy.stats.hp,
            guy.stats.maxHp,
            guy.time,
            guy.speed
          )
        end
      end

      local function controls()
        return ''
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

      local header = '<- Tab ->\n\n'
      local tabs = { charSheet(player), controls }
      local idx = 1 + (game.activeTab % #tabs)

      return header .. tabs[idx]()
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