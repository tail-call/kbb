---@class GuyStats
---@field hp number Current health points
---@field maxHp number Maximum health points
---@field moves number Current moves
---@field maxMoves number Maximum moves
---@field hurt fun(self: GuyStats, damage: number) Decreases health points
---@field heal fun(self: GuyStats) Sets health points eqal max health points
---@field setMaxHp fun(self: GuyStats, maxHp: number) Sets maximum health points and fully heals
---@field addMoves fun(self: GuyStats, amount: number) Adds moves

local clamped = require('Util').clamped

local GuyStats = {}

---@param bak GuyStats
function GuyStats.new(bak)
  bak = bak or {}

  ---@type GuyStats
  local guyStats = {
    __module = 'GuyStats',
    hp = bak.hp or 10,
    maxHp = bak.maxHp or 10,
    moves = bak.moves or 0,
    maxMoves = bak.maxMoves or 99,
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
    addMoves = function (self, amount)
      self.moves = clamped(self.moves + amount, 0, self.maxMoves)
    end,
  }
  return guyStats
end


---@param stats GuyStats
---@return boolean
function GuyStats.isAtFullHealth(stats)
  return stats.hp >= stats.maxHp
end

return GuyStats