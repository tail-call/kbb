---@class GuyStats
---@field hp number Current health points
---@field maxHp number Maximum health points
---@field hurt fun(self: GuyStats, damage: number) Decreases health points
---@field heal fun(self: GuyStats) Sets health points eqal max health points
---@field setMaxHp fun(self: GuyStats, maxHp: number) Sets maximum health points and fully heals

local GuyStats = {}

function GuyStats.makeGuyStats()
  local guyStats = {
    hp = 10,
    maxHp = 10,
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
  }
  return guyStats
end

return GuyStats