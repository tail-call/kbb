---@class Module
---@field mut Mutator Mutator object
---@field new fun(bak: table): table Makes a new object
---@field init fun(bak: table, strategy: fun(moduleName: string, dep: table): table): any Initializes an object
---@field deinit fun(bak: table)  Deinitializes an object
---@field reload fun(bak: table) Reloads an object from its originating module

local M = {}

---@generic T
---@param name string | table
---@param version? number
---@return T
function M.define(name, version)
  local metatable = nil

  if type(name) == 'table' then
    version = name.version
    metatable = name.metatable
    name = name[1]
  end

  local module
  module = {
    mut = {},
    __modulename = name,
    ---@generic T
    ---@param bak T
    ---@param strategy fun(moduleName: string, bak: T)
    init = function (bak, strategy)
      return bak
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
      if obj == nil then
        error('migrate must return a value')
      end
      obj.__module = name
      obj.__version = version
      module.init(obj, function (moduleName, dep)
        return require(moduleName).new(dep)
      end)
      setmetatable(obj, metatable)
      return obj
    end,
    reload = function (obj)
      module.deinit(obj)
      module.init(obj, function (moduleName, dep)
        require(moduleName).reload(dep)
      end)
      setmetatable(obj, metatable)
      return obj
    end,
  }
  return module
end

---@param module Module
---@return Module
function M.extend(module)
end

function M.reload(name)
  package.loaded[name] = nil
  return require(name)
end

return M