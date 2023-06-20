---@class core.class
---@field __modulename string
---@field new fun(bak: table): table Makes a new object
---@field init fun(bak: table, strategy: fun(moduleName: string, dep: table): table): any Initializes an object
---@field deinit fun(bak: table)  Deinitializes an object
---@field reload fun(bak: table) Reloads an object from its originating module

---@class core.class.options
---@field metatable nil Deprecated
---@field version nil Deprecated
---@field slots string[] Names of properties required for object initialization
---@field index table Table to be set as value of object's metatable's `__index` key

---@class core.class.slot
---@field name string Slot name
---@field isRequired string Does slot have to be initialized?

---@param slotString string String passed to `slots` parameter in `defineClass`, like `'normal'` or `'!required'`
---@return core.class.slot
local function slotStringToSlot(slotString)
  if slotString:sub(1, 1) == '!' then
    return {
      name = slotString:sub(2),
      isRequired = true
    }
  else
    return {
      name = slotString,
      isRequired = false
    }
  end
end

---@generic T
---@param opts core.class.options
---@return T
local function defineClass(opts)
  local metatable = nil
  local name = opts[1] or error('name is required')
  local slots = {}
  local class

  local function findSlot(slotName)
    for _, slot in ipairs(slots) do
      if slot.name == slotName then
        return slot
      end
    end
    return nil
  end

  if opts.metatable then
    require 'core.log'.deprecated {
      'core.class', 'define', 'opts', 'metatable'
    }
    metatable = opts.metatable or nil
  end
  if opts.version then
    require 'core.log'.deprecated {
      'core.class', 'define', 'opts', 'version'
    }
  end

  for _, slot in ipairs(opts.slots or {}) do
    table.insert(slots, slotStringToSlot(slot))
  end

  if opts.index then
    metatable = { __index = opts.index }
  end

  class = {
    __modulename = name,
    slots = slots,
    ---@generic T
    ---@param bak T
    ---@param strategy fun(moduleName: string, bak: T)
    init = function (bak, strategy)

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
    ---@param backup T
    ---@return T
    new = function (backup)
      local object = class.migrate(backup or {})
      if object == nil then
        error('migrate must return a value')
      end
      for _, slot in ipairs(slots) do
        if slot.isRequired and not object[slot.name] then
          error(slot.name .. ' is required', 6)
        end
      end
      object.__module = name
      setmetatable(object, metatable)
      class.init(object, function (moduleName, dep)
        return require(moduleName).new(dep)
      end)
      return object
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
  defineClass = defineClass,
  reload = reload,
}