---@class GuyDelegate
---@field collider fun(v: Vector): CollisionInfo Function that performs collision checks between game world objects
---@field beginBattle fun(attacker: Guy, defender: Guy): nil Begins a battle between an attacker and defender
---@field enterHouse fun(guest: Guy, building: Building): 'shouldMove' | 'shouldNotMove' Tells whether the guy may enter the building

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
    enterHouse = function (guy, building)
      if guy.team ~= 'good' then
        return 'shouldNotMove'
      end
      require('GuyStats').mut.setMaxHp(guy.stats, guy.stats.maxHp + 1)
      require('Game').mut.removeEntity(game, building)
      return 'shouldMove'
    end,
    collider = function (pos)
      return collider(game, pos)
    end,
  }
  return guyDelegate
end

return M