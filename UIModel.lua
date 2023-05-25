---@class UIModel
---
---@field game Game Game
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
---
---@field didTypeCharacter fun(self: UIModel, char: string) Called when player typed a character
---@field didPressBackspace fun(self: UIModel) Called when player typed a character

local formatVector = require('Vector').formatVector
local dump = require('Util').dump

local WHITE_COLOR = { 1, 1, 1, 1 }
local GRAY_COLOR = { 0.5, 0.5, 0.5, 1 }

local M = {}

---Love2d colored text for top panel
---@param game Game
---@return fun(): table
local function topPanelText(game)
  return function ()
    local player = game.player
    local controls = ''
    if game.mode == 'normal' then
      controls = 'Space] paint\nLMB] recruit\n8] save\nZ] zoom\nF] follow\nQ] gather\nT] warp\nC] collect\n'     
    elseif game.mode == 'paint' then
      controls = 'Space] focus\nLMB] paint\n'
    end
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
      controls,
      player.stats.moves >= 1 and WHITE_COLOR or GRAY_COLOR,
      'G] dismiss 1t\n',
      player.stats.moves >= 25 and game.resources.pretzels >= 1 and WHITE_COLOR or GRAY_COLOR,
      'R] ritual 25t 1p\n',
      player.stats.moves >= 50 and game.resources.wood >= 5 and WHITE_COLOR or GRAY_COLOR,
      'B] build 50t 5w\n',
    }
  end
end

---@param game Game
function M.new(game)
  ---@type UIModel
  local model
  model = {
    __module = 'UIModel',
    console = require('Console').new {},
    prompt = '',
    game = game,
    activeTab = 0,
    topPanelText = topPanelText(game),
    nextTab = function (self)
      self.activeTab = self.activeTab + 1
    end,
    didTypeCharacter = function (self, char)
      self.prompt = self.prompt .. char
    end,
  }
  return model
end

return M