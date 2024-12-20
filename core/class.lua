---@class core.class
---@field __modulename string
---@field new fun(bak?: table): any Makes a new object
---@field init fun(bak: table, strategy: fun(moduleName: string, dep: table): table) Initializes an object
---@field deinit fun(bak: table) Deinitializes an object
---@field reload fun(bak: table) Reloads an object from its originating module

---@alias core.class.slotType 'normal' | 'required'

---@class core.class.slot
---@field name string Slot name
---@field type core.class.slotType Slot type

---@alias core.class.slotdef string | { [1]: string, type: core.class.slotType }

---@class core.class.options
---@field metatable nil Deprecated
---@field version nil Deprecated
---@field slots core.class.slotdef[] Names of properties required for object initialization
---@field index table Table to be set as value of object's metatable's `__index` key

local function asString(value)
  if type(value) == 'string' then
    return value
  end

  error('not a string: ' .. tostring(value))
end

local function asSlotType(slotType)
  if slotType == 'normal' or slotType == 'required' then
    return value
  end

  error('not a slot type: ' .. slotType)
end

---@param slotdef core.class.slotdef Slot definition passed to `slots` parameter in `defineClass`
---@return core.class.slot
local function slotdefToSlot(slotdef)
  local t = type(slotdef)
  if t == 'string' then
    if slotdef:sub(1, 1) == '!' then
      return {
        name = slotdef:sub(2),
        type = 'required',
      }
    else
      return {
        name = slotdef,
        type = 'normal',
      }
    end
  elseif t == 'table' then
    ---@cast slotdef table
    return {
      name = asString(slotdef[1]),
      type = asSlotType(slotdef.type),
    }
  end
  error('invalid type of slotdef: ' .. t)
end

---@generic T
---@param opts core.class.options
---@return core.class 
local function defineClass(opts)
  local metatable = nil
  local name = opts[1] or error('name is required')
  ---@type core.class.slot[]
  local slots = {}
  local class

  if opts.metatable then
    Log.deprecated {
      'core.class', 'define', 'opts', 'metatable'
    }
    metatable = opts.metatable or nil
  end
  if opts.version then
    Log.deprecated {
      'core.class', 'define', 'opts', 'version'
    }
  end

  for _, slot in ipairs(opts.slots or {}) do
    table.insert(slots, slotdefToSlot(slot))
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
    ---@param backup? core.Object
    ---@return core.Object 
    new = function (backup)
      local object = class.migrate(backup or {})
      if object == nil then
        error('migrate must return a value')
      end
      for _, slot in ipairs(slots) do
        if slot.type == 'required' and not object[slot.name] then
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

local function saveObject(object, filename)
  local file = io.open(filename, 'w+')
  if file == nil then error('no file') end

  file:write('-- This is a Kobold Princess Simulator v0.4 savefile. You should not run it.\n')
  file:write('-- It was created at ' .. os.date() .. '\n')

  file:write(require 'core.Dump'.dump(object))
  file:close()
end

---@param filename string
---@return fun()?, string? errorMessage
local function loadObject(filename)
  return require 'core.Dump'.loadFileWithIndex(filename, function(t, k)
    -- TODO: make any class loadable
    if k == 'game' then
      return {
        GuyStats = require 'game.GuyStats'.new
      }
    end
    return function(...)
      return require(k).new(...)
    end
  end)
end


return {
  defineClass = defineClass,
  reload = reload,
  saveObject = saveObject,
  loadObject = loadObject,
}