---@class GuyStats
---@field hp number Current health points
---@field maxHp number Maximum health points
---@field moves number Current moves
---@field maxMoves number Maximum moves
---@field hurt fun(self: GuyStats, damage: number) Decreases health points
---@field heal fun(self: GuyStats) Sets health points eqal max health points
---@field setMaxHp fun(self: GuyStats, maxHp: number) Sets maximum health points and fully heals
---@field increaseMoves fun(self: GuyStats) Increases moves by 1

local GuyStats = {}

function GuyStats.makeGuyStats()
  ---@type GuyStats
  local guyStats = {
    hp = 10,
    maxHp = 10,
    moves = 0,
    maxMoves = 99,
    hurt = function (self, damage)
      self.hp = self.hp - damage
    end,
    heal = function (self)
      self.hp = self.hp + self.maxHp
    end,
    setMaxHp = function (self, maxHp)
      self.hp = maxHp
      self.maxHp = maxHp
    end,
    increaseMoves = function (self)
      self.moves = math.min(self.moves + 1, self.maxMoves)
    end,
  }
  return guyStats
end

return GuyStats