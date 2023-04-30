---@class Module
---@field mut Mutator Mutator object
---@field new fun(bak: table): table Makes a new object
---@field init fun(bak: table, strategy: fun(moduleName: string, dep: table): table): any Initializes an object
---@field deinit fun(bak: table)  Deinitializes an object
---@field reload fun(bak: table) Reloads an object from its originating module

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
    ---@generic T
    ---@param bak T
    ---@return T
    new = function (bak)
      local obj = module.migrate(bak or {})
      obj.__module = name
      obj.__version = version
      module.init(obj, function (moduleName, dep)
        return require(moduleName).new(dep)
      end)
      return obj
    end,
    reload = function (obj)
      module.deinit(obj)
      return module.init(obj, function (moduleName, dep)
        require(moduleName).reload(dep)
      end)
    end,
  }
  return module
end

function M.reload(name)
  package.loaded[name] = nil
  return require(name)
end

return M