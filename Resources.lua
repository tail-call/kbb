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

local executeCommand = require('SaveLoad').executeCommand
local makeCommandHandler = require('SaveLoad').makeCommandHandler

---@return Resources
local function makeResources()
  ---@type Resources
  local resources = {
    pretzels = 1,
    wood = 0,
    stone = 0,
    addPretzels = function (self, count)
      self.pretzels = self.pretzels + count
    end,
    addWood = function (self, count)
      self.wood = self.wood + count
    end,
    addStone = function (self, count)
      self.stone = self.stone + count
    end,
    X_Serializable = require('X_Serializable'),
    serialize = function(self)
      ---@cast self Resources
      return table.concat {
        'OBJECT Resources resources 3\n',
        ('NUMBER wood %s\n'):format(self.wood),
        ('NUMBER stone %s\n'):format(self.stone),
        ('NUMBER pretzels %s\n'):format(self.pretzels),
      }
    end,
  }
  return resources
end

---@param file file*
---@param repeats integer
---@return Resources
local deserialize = function (file, repeats)
  local resources = makeResources()
  for i = 1, repeats do
    executeCommand(file, '???', makeCommandHandler(resources), i)
  end
  return resources
end

return {
  makeResources = makeResources,
  deserialize = deserialize,
}