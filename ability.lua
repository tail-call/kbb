---@class Ability
---@field combat AbilityEffect
---@field defence AbilityEffect
---@field treeCut AbilityEffect

local Effect = require('AbilityEffect')

---@type { [string]: Ability }
local abilities = {
  normalFail = {
    combat = Effect.combat.miss,
    defence = Effect.defence.takeDamage,
    treeCut = Effect.treeCut.loiter,
  },
  normalSuccess = {
    combat = Effect.combat.normalAttack,
    defence = Effect.defence.takeDamage,
    treeCut = Effect.treeCut.normalChop,
  },
  normalCriticalSuccess = {
    combat = Effect.combat.criticalAttack,
    defence = Effect.defence.parry,
    treeCut = Effect.treeCut.criticalChop,
  },
}

---@param abilitiesTable { [Ability]: number }
local function pickAbility(abilitiesTable)
  local sum = 0
  local probs = {}
  for ability, weight in pairs(abilitiesTable) do
    probs[sum] = ability
    sum = sum + weight
  end
end

return {
  abilities = abilities,
  effects = Effect,
  pickAbility = pickAbility,
}