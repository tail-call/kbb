---@class AbilityEffect
---@field name string

---@type { [string]: AbilityEffect }
local combatEffects = {
  miss = { name = "Miss" },
  normalAttack = { name = "Normal Attack" },
  criticalAttack = { name = "Critical Attack" },
}

---@type { [string]: AbilityEffect }
local defenceEffects = {
  takeDamage = { name = "Take Damage" },
  parry = { name = "Parry" },
}

---@type { [string]: AbilityEffect }
local treeCutEffects = {
  loiter = { name = "Loiter" },
  normalChop = { name = "Normal Chop" },
  criticalChop = { name = "Critical Chop" },
}

return {
  combat = combatEffects,
  defence = defenceEffects,
  treeCut = treeCutEffects,
}
