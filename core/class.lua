---@class core.class
---@field __modulename string
---@field new fun(bak: table): table Makes a new object
---@field init fun(bak: table, strategy: fun(moduleName: string, dep: table): table): any Initializes an object
---@field deinit fun(bak: table)  Deinitializes an object
---@field reload fun(bak: table) Reloads an object from its originating module

---@generic T
---@param opts table
---@return T
local function define(opts)
  local metatable = nil
  if opts.metatable then
    require 'core.warning'.deprecated {
      'core.class', 'define', 'opts', 'metatable'
    }
    metatable = opts.metatable or nil
  end
  if opts.version then
    require 'core.warning'.deprecated {
      'core.class', 'define', 'opts', 'version'
    }
  end
  local version = opts.version or 0
  local name = opts[1]
  if opts.index then
    metatable = { __index = opts.index }
  end

  local class
  class = {
    __modulename = name,
    ---@generic T
    ---@param bak T
    ---@param strategy fun(moduleName: string, bak: T)
    init = function (bak, strategy)
      return bak
    end,
    type = function ()
      return metatable
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
      local obj = class.migrate(bak or {})
      if obj == nil then
        error('migrate must return a value')
      end
      obj.__module = name
      obj.__version = version
      setmetatable(obj, metatable)
      class.init(obj, function (moduleName, dep)
        return require(moduleName).new(dep)
      end)
      return obj
    end,
    reload = function (obj)
      setmetatable(obj, metatable)
      class.deinit(obj)
      class.init(obj, function (moduleName, dep)
        require(moduleName).reload(dep)
      end)
      return obj
    end,
  }
  return class
end

local function reload(name)
  package.loaded[name] = nil
  return require(name)
end

return {
  define = define,
  reload = reload,
}