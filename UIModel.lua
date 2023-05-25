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

local M = {}

---@param game Game
function M.new(game)
  ---@type UIModel
  local model
  model = {
    __module = 'UIModel',
    console = require('Console').new {},
    prompt = '',
    game = game,
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