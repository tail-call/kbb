---Game stats like player score etc.
---@class GameStats
---@field __module 'GameStats'
---# Properties
---@field score integer Score the player has accumulated
---@field deathsCount number Number of times player has died
---# Methods
---@field addScore fun(self: Game, count: integer) Increases score count
---@field addDeaths fun(self: Game, count: integer) Adds a death to a game

local M = require 'core.Module'.define{..., metatable = {
  ---@type GameStats
  __index = {
    addScore = function(self, count)
      self.score = self.score + count
    end,
    addDeaths = function (self, guy)
      self.deathsCount = self.deathsCount + 1
    end,
  }
}}

---@param obj GameStats
function M.init(obj)
  obj.score = obj.score or 0
  obj.deathsCount = obj.deathsCount or 0
end

return M
