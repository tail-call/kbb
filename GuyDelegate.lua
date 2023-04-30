---@class GuyDelegate
---@field collider fun(v: Vector): CollisionInfo Function that performs collision checks between game world objects
---@field beginBattle fun(attacker: Guy, defender: Guy): nil Begins a battle between an attacker and defender
---@field enterHouse fun(guest: Guy, entity: GameEntity_Building): 'shouldMove' | 'shouldNotMove' Tells whether the guy may enter the building

local isAtFullHealth = require('GuyStats').isAtFullHealth
local heal = require('GuyStats').mut.heal

local M = require('Module').define(..., 0)

---@param game Game
---@param collider fun(self: Game, v: Vector): CollisionInfo Function that performs collision checks between game world objects
---@return GuyDelegate
function M.new(game, collider)
  ---@type GuyDelegate
  local guyDelegate = {
    beginBattle = function (attacker, defender)
      require('Game').mut.beginBattle(game, attacker, defender)
    end,
    enterHouse = function (guy, entity)
      if isAtFullHealth(guy.stats) then
        return 'shouldNotMove'
      end
      heal(guy.stats)
      require('Game').mut.removeEntity(game, entity)
      return 'shouldMove'
    end,
    collider = function (pos)
      return collider(game, pos)
    end,
  }
  return guyDelegate
end

return M