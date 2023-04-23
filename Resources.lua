---@class Resources: X_Serializable
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

local KPSS = require('KPSS')

local ResourcesModule = {}

---@param resources Resources
local function serializeResources(resources)
  return table.concat {
    'OBJECT Resources resources 5\n',
    'NUMBER wood %s\n',
    'NUMBER stone %s\n',
    'NUMBER pretzels %s\n',
    'NUMBER grass %s\n',
    'NUMBER water %s\n',
  }:format(
    resources.wood,
    resources.stone,
    resources.pretzels,
    resources.grass,
    resources.water
  )
end

---@return Resources
function ResourcesModule.new()
  ---@type Resources
  local resources = {
    pretzels = 1,
    addPretzels = function (self, count)
      self.pretzels = self.pretzels + count
    end,

    wood = 0,
    addWood = function (self, count)
      self.wood = self.wood + count
    end,

    stone = 0,
    addStone = function (self, count)
      self.stone = self.stone + count
    end,

    grass = 0,
    addGrass = function (self, count)
      self.grass = self.grass + count
    end,

    water = 0,
    addWater = function (self, count)
      self.water = self.water + count
    end,

    X_Serializable = require('X_Serializable'),
    serialize = serializeResources,
  }
  return resources
end

---@param file file*
---@param repeats integer
---@return Resources
function ResourcesModule.deserialize (file, repeats)
  local resources = ResourcesModule.new()
  for i = 1, repeats do
    KPSS.executeNextLine(file, '???', KPSS.makeCommandHandler(resources), i)
  end
  return resources
end

return ResourcesModule