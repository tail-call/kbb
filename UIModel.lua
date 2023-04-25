---@class UIModel
---@field prompt string
---@field topPanelText fun(): table Love2D colored text for top panel
---@field leftPanelText fun(): string Left panel text
---@field rightPanelText fun(): string Right panel text
---@field bottomPanelText fun(): string Bottom panel text
---@field promptText fun(): string Prompt text
---@field shouldDrawFocusModeUI fun(): boolean True if should draw focus mode UI
---@field didTypeCharacter fun(self: UIModel, char: string) Called when player typed a character
---@field didPressBackspace fun(self: UIModel) Called when player typed a character

local getTile = require('World').getTile
local formatVector = require('Vector').formatVector
local dump = require('Util').dump

local WHITE_COLOR = { 1, 1, 1, 1 }
local GRAY_COLOR = { 0.5, 0.5, 0.5, 1 }

-- TODO: this is actually a view model, not a delegate

---@param game Game
---@param player Guy
local function new(game, player)
  ---@type UIModel
  local model
  model = {
    __module = 'UIModel',
    prompt = '',
    topPanelText = function()
      return {
        WHITE_COLOR,
        string.format(
          'Score: %d | Revealed: %d/%d %0.ffps\n',
          game.score,
          game.world.revealedTilesCount,
          game.world.height * game.world.width,
          love.timer.getFPS()
        ),
        WHITE_COLOR,
        'WASD] move\nRet] focus\nLMB] recruit\n8] save\nZ] zoom\nN] reload\nF] follow\nQ] gather\nT] warp\nC] collect\n',
        player.stats.moves >= 1 and WHITE_COLOR or GRAY_COLOR,
        'G] dismiss 1t\n',
        player.stats.moves >= 25 and game.resources.pretzels >= 1 and WHITE_COLOR or GRAY_COLOR,
        'R] ritual 25t 1p\n',
        player.stats.moves >= 50 and game.resources.wood >= 5 and WHITE_COLOR or GRAY_COLOR,
        'B] build 50t 5w\n',
      }
    end,
    leftPanelText = function ()
      local tileUnderCursor = getTile(game.world, game.cursorPos) or '???'
      return string.format(
        ''
          .. 'Terrain:\n %s'
          .. '\nCoords:\n %s'
          .. '\n1234] scale'
          .. '\nM] message',
        tileUnderCursor,
        formatVector(game.cursorPos)
      )
    end,
    rightPanelText = function ()
      local header = '<- Tab ->\n\n'

      local idx = 1 + (game.activeTab % 3)

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
          .. ' DEBUG\n'
          .. string.format('mayMove %s\n', game.player.mayMove)
          .. string.format('pos %s\n', formatVector(game.player.pos))
      elseif idx == 3 then
        return ''
          .. header
          .. ' INVENTORY  \n'
          .. dump(game.resources)

      end
      return ''
    end,
    bottomPanelText = function ()
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
    shouldDrawFocusModeUI = function ()
      return game.isFocused
    end,
    didPressBackspace = function (self)
      self.prompt = self.prompt:sub(1,-2)
    end,
    didTypeCharacter = function (self, char)
      self.prompt = self.prompt .. char
    end,
    promptText = function ()
      local isBlink = 0 == (
        math.floor(love.timer.getTime() * 4) % 2
      )
      if isBlink then
        return ('lua>%s_'):format(model.prompt)
      else
        return ('lua>%s'):format(model.prompt)
      end
    end,
  }
  return model
end

return {
  new = new,
}