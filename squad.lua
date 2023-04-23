---@class Squad
---@field shouldFollow boolean True if guys should follow the player
---@field followers { [Guy]: true } Guys in the squad
---# Methods
---@field remove fun(self: Squad, guy: Guy) Removes a guy from the squad
---@field add fun(self: Squad, guy: Guy) Adds a guy to the squad
---@field startFollowing fun(self: Squad) Squad will begin following the player
---@field toggleFollow fun(self: Squad) Toggle follow mode for squad

local SquadModule = {}

---@return Squad
function SquadModule.new()
  ---@type Squad
  local squad = {
    followers = {},
    shouldFollow = true,
    remove = function(self, guy)
      self.followers[guy] = nil
    end,
    add = function(self, guy)
      self.followers[guy] = true
    end,
    startFollowing = function(self)
      self.shouldFollow = true
    end,
    toggleFollow = function(self)
      self.shouldFollow = not self.shouldFollow
    end,
  }
  return squad
end

---@param squad Squad
---@param guy Guy
---@return boolean
function SquadModule.isGuyAFollower(squad, guy)
  return squad.followers[guy] or false
end

return SquadModule