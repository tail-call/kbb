---@class Ability
---@field combat AbilityEffect
---@field defence AbilityEffect
---@field treeCut AbilityEffect

local AbilityEffect = require 'game.AbilityEffect'

---@type { [string]: Ability }
local abilities = {
  normalFail = {
    combat = AbilityEffect.combat.miss,
    defence = AbilityEffect.defence.takeDamage,
    treeCut = AbilityEffect.treeCut.loiter,
  },
  normalSuccess = {
    combat = AbilityEffect.combat.normalAttack,
    defence = AbilityEffect.defence.takeDamage,
    treeCut = AbilityEffect.treeCut.normalChop,
  },
  normalCriticalSuccess = {
    combat = AbilityEffect.combat.criticalAttack,
    defence = AbilityEffect.defence.parry,
    treeCut = AbilityEffect.treeCut.criticalChop,
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
  effects = AbilityEffect,
  pickAbility = pickAbility,
}