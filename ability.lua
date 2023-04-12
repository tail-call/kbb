---@class Effect
---@field name string

---@type { [string]: Effect }
local combatEffects = {
  miss = { name = "Miss" },
  normalAttack = { name = "Normal Attack" },
  criticalAttack = { name = "Critical Attack" },
}

---@type { [string]: Effect }
local defenceEffects = {
  takeDamage = { name = "Take Damage" },
  parry = { name = "Parry" },
}

---@type { [string]: Effect }
local treeCutEffects = {
  loiter = { name = "Loiter" },
  normalChop = { name = "Normal Chop" },
  criticalChop = { name = "Critical Chop" },
}

local effects = {
  combat = combatEffects,
  defence = defenceEffects,
  treeCut = treeCutEffects,
}

---@class Ability
---@field combat Effect
---@field defence Effect
---@field treeCut Effect

---@type { [string]: Ability }
local abilities = {
  normalFail = {
    combat = effects.combat.miss,
    defence = effects.defence.takeDamage,
    treeCut = effects.treeCut.loiter,
  },
  normalSuccess = {
    combat = effects.combat.normalAttack,
    defence = effects.defence.takeDamage,
    treeCut = effects.treeCut.normalChop,
  },
  normalCriticalSuccess = {
    combat = effects.combat.criticalAttack,
    defence = effects.defence.parry,
    treeCut = effects.treeCut.criticalChop,
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
  effects = effects,
  pickAbility = pickAbility,
}