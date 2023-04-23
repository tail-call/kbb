---@class Battle
---@field attacker Guy Who initiated the battle
---@field defender Guy Who was attacked
---@field pos Vector Battle's location
---@field timer number Time before current round finishes
---@field round number Current round number
---# Methods
---@field swapSides fun(self: Battle) Swap attacker and defender
---@field advanceTimer fun(self: Battle, dt: number) Makes battle timer go down
---@field beginNewRound fun(self: Battle) Reset round timer

local BATTLE_ROUND_DURATION = 0.5

local Battle = {}

---@param bak Battle
---@return Battle
function Battle.new(bak)
  ---@type Battle
  local battle = {
    __module = 'Battle',
    attacker = bak.attacker,
    defender = bak.defender,
    pos = bak.defender.pos,
    round = 1,
    timer = BATTLE_ROUND_DURATION,
    swapSides = function (self)
      self.attacker, self.defender = self.defender, self.attacker
    end,
    advanceTimer = function (self, dt)
      self.timer = self.timer - dt
    end,
    beginNewRound = function (self)
      self.timer = BATTLE_ROUND_DURATION
      self.round = self.round + 1
    end
  }
  return battle
end

return Battle
