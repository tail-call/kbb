---@class GuyStats
---@field hp number Current health points
---@field maxHp number Maximum health points
---@field hurt fun(self: GuyStats, damage: number): nil Decreases health points
---@field heal fun(self: GuyStats): nil Sets health points eqal max health points

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
    end
  }
  return guyStats
end

return GuyStats