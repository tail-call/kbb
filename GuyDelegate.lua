---@class GuyDelegate
---@field collider fun(v: Vector): CollisionInfo Function that performs collision checks between game world objects
---@field beginBattle fun(attacker: Guy, defender: Guy): nil Begins a battle between an attacker and defender
---@field enterHouse fun(guest: Guy, entity: GameEntity_Building): 'shouldMove' | 'shouldNotMove' Tells whether the guy may enter the building

local isAtFullHealth = require('GuyStats').isAtFullHealth
local heal = require('GuyStats').mut.heal

local GuyDelegate = {}
---@param game Game
---@return GuyDelegate
function GuyDelegate.makeGuyDelegate(game)
  ---@type GuyDelegate
  local guyDelegate = {
    beginBattle = function (attacker, defender)
      game:beginBattle(attacker, defender)
    end,
    enterHouse = function (guy, entity)
      if isAtFullHealth(guy.stats) then
        return 'shouldNotMove'
      end
      heal(guy.stats)
      game:removeEntity(entity)
      return 'shouldMove'
    end,
    collider = function (pos)
      return game:collider(pos)
    end,
  }
  return guyDelegate
end

return GuyDelegate