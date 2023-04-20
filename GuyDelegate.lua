---@class GuyDelegate
---@field collider fun(v: Vector): CollisionInfo Function that performs collision checks between game world objects
---@field beginBattle fun(attacker: Guy, defender: Guy): nil Begins a battle between an attacker and defender
---@field enterHouse fun(guest: Guy, entity: GameEntity_Building): 'shouldMove' | 'shouldNotMove' Tells whether the guy may enter the building

local GuyDelegate = {}

---@param guy Guy
local function isAtFullHealth(guy)
  return guy.stats.hp >= guy.stats.maxHp
end

---@param game Game
---@return GuyDelegate
function GuyDelegate.makeGuyDelegate(game)
  ---@type GuyDelegate
  local guyDelegate = {
    beginBattle = function (attacker, defender)
      game:beginBattle(attacker, defender)
    end,
    enterHouse = function (guy, entity)
      if isAtFullHealth(guy) then
        return 'shouldNotMove'
      end
      guy.stats:heal()
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