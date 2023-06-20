---Game stats like player score etc.
---@class GameStats
---@field __module 'GameStats'
---# Properties
---@field score integer Score the player has accumulated
---@field deathsCount number Number of times player has died
---# Methods
---@field addScore fun(self: GameStats, count: integer) Increases score count
---@field addDeaths fun(self: GameStats, count: integer) Adds a death to a game

local GameStats = require 'core.class'.define {
  ...,
  ---@type GameStats
  index = {
    addScore = function(self, count)
      self.score = self.score + count
    end,
    addDeaths = function (self, guy)
      self.deathsCount = self.deathsCount + 1
    end,
  }
}

---@param obj GameStats
function GameStats.init(obj)
  obj.score = obj.score or 0
  obj.deathsCount = obj.deathsCount or 0
end

return GameStats
