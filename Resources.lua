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
  }
  return resources
end

return {
  makeResources = makeResources,
}