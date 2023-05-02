---A representation of a battle between units
---@class Battle: Object2D
---@field __module "Battle"
---@field attacker Guy Who initiated the battle
---@field defender Guy Who was attacked
---@field timer number Time before current round finishes
---@field round number Current round number

---@class BattleMutator
---@field advanceTimer fun(self: Battle, dt: number) Makes battle timer go down
---@field beginNewRound fun(self: Battle) Reset round timer

local M = require('Module').define(..., 0)

local weightedRandom = require('Util').weightedRandom
local Ability = require('Ability')

local hurt = require('GuyStats').mut.hurt

local BATTLE_ROUND_DURATION = 0.5

---@type BattleMutator
M.mut = require('Mutator').new {
  advanceTimer = function (self, dt)
    self.timer = self.timer - dt
  end,
  beginNewRound = function (self)
    self.attacker, self.defender = self.defender, self.attacker
    self.timer = BATTLE_ROUND_DURATION
    self.round = self.round + 1
  end,
}

---@param battle Battle
function M.init(battle)
  battle.attacker = battle.attacker or error("Battle: attacker is required")
  battle.defender = battle.defender or error("Battle: defender is required")
  battle.pos = battle.defender.pos or error("Battle: defender.pos is required")
  battle.round = battle.round or 1
  battle.timer = BATTLE_ROUND_DURATION
end

---@param game Game
---@param attacker Guy
---@param defender Guy
---@param damageModifier number
---@param say fun(text: string)
local function fight(game, attacker, defender, damageModifier, say)
  local attackerAction = weightedRandom(attacker.abilities)
  local defenderAction = weightedRandom(attacker.abilities)

  local attackerEffect = attackerAction.ability.combat
  local defenderEffect = defenderAction.ability.defence

  ---@param guy Guy
  ---@param damage number
  local function dealDamage(guy, damage)
    hurt(guy.stats, damage * damageModifier)
    say(('%s got %s damage, has %s hp now.'):format(guy.name, damage, guy.stats.hp))
  end

  if defenderEffect == Ability.effects.defence.parry then
    if attackerEffect == Ability.effects.combat.normalAttack then
      say(('%s attacked, but %s parried!'):format(attacker.name, defender.name))
      dealDamage(defender, 0)
    elseif attackerEffect == Ability.effects.combat.miss then
      say(('%s attacked and missed, %s gets an extra turn!'):format(attacker.name, defender.name))
      fight(game, defender, attacker, damageModifier, say)
    elseif attackerEffect == Ability.effects.combat.criticalAttack then
      say(('%s did a critical attack, but %s parried! They strike back with %sx damage.'):format(attacker.name, defender.name, damageModifier))
      fight(game, defender, attacker, damageModifier * 2, say)
    end
  elseif defenderEffect == Ability.effects.defence.takeDamage then
    if attackerEffect == Ability.effects.combat.normalAttack then
      say(('%s attacked! %s takes damage.'):format(attacker.name, defender.name))
      dealDamage(defender, attackerAction.weight)
    elseif attackerEffect == Ability.effects.combat.miss then
      say(('%s attacked but missed!'):format(attacker.name))
      dealDamage(defender, 0)
    elseif attackerEffect == Ability.effects.combat.criticalAttack then
      say(('%s did a critical attack! %s takes %sx damage.'):format(attacker.name, defender.name, damageModifier))
      dealDamage(defender, attackerAction.weight * 2)
    end
  end
end

---@param game Game
---@param battle Battle
---@param dt number
---@param say fun(text: string)
---@param fightIsOver fun()
function M.updateBattle(game, battle, dt, say, fightIsOver)
  M.mut.advanceTimer(battle, dt)
  if battle.timer < 0 then
    fight(game, battle.attacker, battle.defender, 1, say)
    if battle.attacker.stats.hp > 0 and battle.defender.stats.hp > 0 then
      M.mut.beginNewRound(battle)
    else
      fightIsOver()
    end
  end
end

return M
