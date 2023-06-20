---@class Squad
---@field __module 'Squad'
---@field shouldFollow boolean True if guys should follow the player
---@field followers { [Guy]: true } Guys in the squad
---@field removeFromSquad fun(self: Squad, guy: Guy) Removes a guy from the squad
---@field addToSquad fun(self: Squad, guy: Guy) Adds a guy to the squad
---@field startFollowing fun(self: Squad) Squad will begin following the player
---@field toggleFollow fun(self: Squad) Toggle follow mode for squad

local M = require('core.class').define{..., metatable = {
  ---@type Squad
  __index = {
    removeFromSquad = function(self, guy)
      self.followers[guy] = nil
    end,
    addToSquad = function(self, guy)
      self.followers[guy] = true
    end,
    startFollowing = function(self)
      self.shouldFollow = true
    end,
    toggleFollow = function(self)
      self.shouldFollow = not self.shouldFollow
    end,
  }
}}

---@param squad Squad
function M.init(squad)
  ---@type Squad
  squad.followers = squad.followers or {}
  squad.shouldFollow = squad.shouldFollow or true
  return squad
end

---@param squad Squad
---@param entity Guy
---@return boolean
function M.isAFollower(squad, entity)
  return squad.followers[entity] or false
end

return M