---@class Module
---@field mut table Mutator object
---@field new fun(bak: any): any Makes a new object
---@field init fun(bak: any, strategy: fun(moduleName: string, dep: any): any): any Initializes an object
---@field deinit fun(bak: any): any Deinitializes an object
---@field reload fun(bak: any): any Reloads an object from its originating module

local M = {}

---@generic T
---@param name string
---@param version number
---@return T
function M.define(name, version)
  local module
  module = {
    mut = {},
    __modulename = name,
    ---@generic T
    ---@param bak T
    ---@param strategy fun(moduleName: string, bak: T)
    init = function (bak, strategy)
      -- Do nothing
    end,
    deinit = function (bak)
      -- Do nothing
    end,
    migrate = function (bak)
      return bak
    end,
    new = function (bak)
      local migratedBak = module.migrate(bak)
      local obj = migratedBak or {}
      obj.__module = name
      obj.__version = version
      module.init(obj, function (moduleName, dep)
        if dep == nil then return nil end
        return require(moduleName).new(dep)
      end)
      return obj
    end,
    reload = function (obj)
      module.deinit(obj)
      return module.init(obj, function (moduleName, dep)
        if dep == nil then return end
        require(moduleName).reload(dep)
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