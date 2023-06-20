---A stash of resources to spend on stuff
---@class Resources
---@field __module 'Resources'
---@field pretzels integer Amount of pretzels owned
---@field wood integer Amount of wood owned
---@field stone integer Amount of stone owned
---@field grass integer Amount of grass owned
---@field water integer Amount of water owned
---@field add fun(self: Resources, delta: Resources) Get more resources

local Resources = require 'core.class'.define {
  ...,
  index = {
    add = function (self, delta)
      self.pretzels = self.pretzels + (delta.pretzels or 0)
      self.wood = self.wood + (delta.wood or 0)
      self.grass = self.grass + (delta.grass or 0)
      self.stone = self.stone + (delta.stone or 0)
      self.water = self.water + (delta.water or 0)
    end
  },
}

---@param res Resources
function Resources.init(res)
  res.pretzels = res.pretzels or 0
  res.wood = res.wood or 0
  res.stone = res.stone or 0
  res.grass = res.grass or 0
  res.water = res.water or 0
end

return Resources