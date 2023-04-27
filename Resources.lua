---A stash of resources to spend on stuff
---@class Resources
---
---@field pretzels integer Amount of pretzels owned
---@field addPretzels fun(self: Resources, count: integer) Get more pretzels
---
---@field wood integer Amount of wood owned
---@field addWood fun(self: Resources, count: integer) Get more wood
---
---@field stone integer Amount of stone owned
---@field addStone fun(self: Resources, count: integer) Get more stone
---
---@field grass integer Amount of grass owned
---@field addGrass fun(self: Resources, count: integer) Get more grass
---
---@field water integer Amount of water owned
---@field addWater fun(self: Resources, count: integer) Get more water

---@class ResourcesMutator

local ResourcesModule = {}

---@param bak Resources | nil
---@return Resources
function ResourcesModule.new(bak)
  bak = bak or {}

  ---@type Resources
  local resources = {
    pretzels = bak.pretzels or 1,
    addPretzels = function (self, count)
      self.pretzels = self.pretzels + count
    end,

    wood = bak.wood or 0,
    addWood = function (self, count)
      self.wood = self.wood + count
    end,

    stone = bak.stone or 0,
    addStone = function (self, count)
      self.stone = self.stone + count
    end,

    grass = bak.grass or 0,
    addGrass = function (self, count)
      self.grass = self.grass + count
    end,

    water = bak.water or 0,
    addWater = function (self, count)
      self.water = self.water + count
    end,
  }
  return resources
end

return ResourcesModule