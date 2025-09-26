---A representation of a battle between units

local BATTLE_ROUND_DURATION = 0.5

---@class Battle: Object2D
---@field __module "Battle"
---@field attacker Guy Who initiated the battle
---@field defender Guy Who was attacked
---@field timer number Time before current round finishes
---@field round number Current round number
---@field advanceTimer fun(self: Battle, dt: number) Makes battle timer go down
---@field beginNewRound fun(self: Battle) Reset round timer
local Battle = Class {
  ...,
  slots = { '!attacker', '!defender' },
  index = {
    advanceTimer = function (self, dt)
      self.timer = self.timer - dt
    end,
    beginNewRound = function (self)
      self.attacker, self.defender = self.defender, self.attacker
      self.timer = BATTLE_ROUND_DURATION
      self.round = self.round + 1
    end,
  }
}

---@param battle Battle
function Battle.init(battle)
  battle.pos = battle.defender.pos
  battle.round = battle.round or 1
  battle.timer = BATTLE_ROUND_DURATION
end

---@param game Game
---@param attacker Guy
---@param defender Guy
---@param damageModifier number
---@param say fun(text: string)
local function fight(game, attacker, defender, damageModifier, say)
  local attackerAction = require 'core.numeric'.weightedRandom(attacker.abilities)
  local defenderAction = require 'core.numeric'.weightedRandom(defender.abilities)

  local attackerEffect = attackerAction.ability.combat
  local defenderEffect = defenderAction.ability.defence

  ---@param guy Guy
  ---@param damage number
  local function dealDamage(guy, damage)
    guy.stats:hurt(damage * damageModifier)
    say(('%s got %s damage, has %s hp now.'):format(guy.name, damage, guy.stats.hp))
  end

  local Ability = require 'game.Ability'

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
function Battle.updateBattle(game, battle, dt, say, fightIsOver)
  battle:advanceTimer(dt)
  if battle.timer < 0 then
    fight(game, battle.attacker, battle.defender, 1, say)
    if math.random() > 0.9 then
      fightIsOver()
    elseif battle.attacker.stats.hp > 0 and battle.defender.stats.hp > 0 then
      battle:beginNewRound()
    else
      fightIsOver()
    end
  end
end

return Battle
