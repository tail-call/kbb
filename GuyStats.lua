---@class GuyStats
---@field __module 'GuyStats'
---@field hp number Current health points
---@field maxHp number Maximum health points
---@field moves number Current moves
---@field maxMoves number Maximum moves

---@class GuyStatsMutator: Mutator
---@field hurt fun(self: GuyStats, damage: number) Decreases health points
---@field heal fun(self: GuyStats, amount: number) Heals a specified amount of damage
---@field setMaxHp fun(self: GuyStats, maxHp: number) Sets maximum health points and fully heals
---@field addMoves fun(self: GuyStats, amount: number) Adds moves

local M = require 'core.class'.define{...}

---@type GuyStatsMutator
M.mut = require 'core.Mutator'.new {
  hurt = function (self, damage)
    self.hp = self.hp - damage
  end,
  heal = function (self, amount)
    self.hp = math.min(self.hp + amount, self.maxHp)
  end,
  setMaxHp = function (self, maxHp)
    self.hp = maxHp
    self.maxHp = maxHp
  end,
  addMoves = function (self, amount)
    self.moves = require 'core.numeric'.clamped(
      self.moves + amount,
      0,
      self.maxMoves
    )
  end
}

---@param stats GuyStats
function M.init(stats)
  stats.hp = stats.hp or 10
  stats.maxHp = stats.maxHp or 10
  stats.moves = stats.moves or 0
  stats.maxMoves = stats.maxMoves or 99
end

---@param stats GuyStats
---@return boolean
function M.isAtFullHealth(stats)
  return stats.hp >= stats.maxHp
end

return M