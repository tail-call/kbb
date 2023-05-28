---@alias MutatorListener fun(table: table, key: any, value: any, oldValue: any)

---@class Mutator
---@field listeners { [table] : MutatorListener[] } Maps objects to their mutator listeners
---@field [string] function
---@field addListener fun(self: Mutator, table: table, listener: MutatorListener)
---@field removeListener fun(self: Mutator, table: table, listener: MutatorListener)

local M = require 'core.Module'.define{..., metatable = {
  ---@type Mutator
  __index = {
    addListener = function (self, aTable, listener)
      self.listeners[aTable] = self.listeners[aTable] or {}
      table.insert(self.listeners[aTable], listener)
    end,
    removeListener = function (self, aTable, listener)
      self.listeners[aTable] = self.listeners[aTable] or {}
      require 'core.table'.maybeDrop(self.listeners, listener)
    end,
  }
}}

---@param mut Mutator
function M.init(mut)
  mut.listeners = mut.listeners or {}

  for propName, func in pairs(mut) do
    if propName ~= 'listeners' then
      mut[propName] = function (self, ...)
        local imposter = setmetatable({}, {
          ---@param table table
          ---@param key any
          ---@return any
          __index = function (table, key)
            return self[key]
          end,
          ---@param table table
          ---@param key any
          ---@param newValue any
          __newindex = function (table, key, newValue)
            local oldValue = self[key]
            self[key] = newValue
            local listeners = mut.listeners[self] or {}
            for _, listener in ipairs(listeners) do
              listener(table, key, newValue, oldValue)
            end
          end,
        })
        func(imposter, ...)
      end
    end
  end
  return mut
end

return M