---@class Module
---@field mut table Mutator object
---@field new fun(bak: any): any Makes a new object
---@field init fun(bak: any): any Initializes an object
---@field deinit fun(bak: any): any Deinitializes an object
---@field reload fun(bak: any): any Reloads an object from its originating module

local M = {}

---@param name string
---@param version number
---@return table
function M.define(name, version)
  local module
  module = {
    mut = {},
    __modulename = name,
    init = function (bak, strategy)
      -- Do nothing
    end,
    deinit = function (bak)
      -- Do nothing
    end,
    new = function (bak)
      local obj = bak or {}
      obj.__module = name
      obj.__version = version
      module.init(obj, function (moduleName, bak)
        return require(moduleName).new(bak)
      end)
      return obj
    end,
    reload = function (obj)
      module.deinit(obj)
      return module.init(obj, function (moduleName, bak)
        require(moduleName).reload(bak)
      end)
    end,
  }
  return module
end

function M.reload(name)
  package.loaded[name] = nil
  require(name)
end

return M