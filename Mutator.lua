---@alias MutatorListener fun(table: table, key: any, value: any, oldValue: any)

---@class Mutator
---@field listeners { [table] : MutatorListener[] } Maps objects to their mutator listeners
---@field [string] function

---@class MutatorMutator
---@field addListener fun(self: Mutator, table: table, listener: MutatorListener)
---@field removeListener fun(self: Mutator, table: table, listener: MutatorListener)

local M = require('Module').define(..., 0)

local maybeDrop = require('tbl').maybeDrop

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

---@type MutatorMutator
M.mut = M.new {
  addListener = function (self, aTable, listener)
    self.listeners[aTable] = self.listeners[aTable] or {}
    table.insert(self.listeners[aTable], listener)
  end,
  removeListener = function (self, aTable, listener)
    self.listeners[aTable] = self.listeners[aTable] or {}
    maybeDrop(self.listeners, listener)
  end,
}

---@alias MutatorModule `M`
return M