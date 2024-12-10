-- Table utilities

---@generic T
---@param items T[]
---@param predicate fun(item: T): boolean
---@return T | nil
local function find(items, predicate)
  for _, v in ipairs(items) do
    if predicate(v) then
      return v
    end
  end
  return nil
end

---@generic T
---@param items any[]
---@param item T
---@return T | nil
local function has(items, item)
  return find(items, function (x)
    return x == item
  end)
end

---@generic T
---@param items T[]
---@param pred fun(item: T): boolean
---@return fun(): nil | number, T
local function ifilter(items, pred)
  local i = 0

  return function()
    while true do
      i = i + 1
      local item = items[i]
      if item == nil then
        return nil
      elseif pred(item) then
        return i, item
      end
    end
  end
end

---@generic T
---@param items T[]
---@return T[]
local function iclone(items)
  local result = {}
  for _, v in ipairs(items) do
    table.insert(result, v)
  end
  return result
end

---@generic T
---@param items T[]
local function fastRemoveAtIndex(items, index)
  items[index] = items[#items]
  -- Delete last element
  table.remove(items)
end

local function indexOf(items, item)
  for i, v in ipairs(items) do
    if v == item then return i end
  end
  return nil
end

---@param table table
---@param mode 'k' | 'v' | 'kv'
---@return table
local function weaken(table, mode)
  setmetatable(table, { __mode = mode })
  return table
end

---Removes and item from the array if it's in there
---@generic T
---@param items T[]
---@param item T
local function maybeDrop(items, item)
  local i = indexOf(items, item)
  if not i then return end

  fastRemoveAtIndex(items, i)
end

---Maps an array
---@generic T, U
---@param items T[]
---@param mapper fun(item: T): U
---@return U[]
local function imap(items, mapper)
  local itemsClone = {}
  for _, v in ipairs(items) do
    table.insert(itemsClone, mapper(v))
  end
  return itemsClone
end

---@generic K, V
---@param items { [K]: V }
---@return { [V]: K }
local function invert(items)
  local result = {}

  for k, v in pairs(items) do
    result[v] = k
  end

  return result
end

---@generic I, T, U
---@param items { [I]: T }
---@param value U
---@return { [I]: U }
local function fill(items, value)
  local result = {}

  for i, _ in ipairs(items) do
    result[i] = value
  end

  return result
end

---@generic T 
---@param items T[]
---@return string
local function stringifyArray(items)
  if #items == 0 then
    return '{}'
  end

  local result = {
    put = function (self, x)
      table.insert(self, x)
    end,

    join = function (self)
      return table.concat(self)
    end
  }

  result:put('{ ')

  for i, item in ipairs(items) do
    result:put(item)

    if i < #items then
      result:put(', ')
    end
  end

  result:put(' }')

  return result:join()
end

return {
  find = find,
  iclone = iclone,
  imap = imap,
  ifilter = ifilter,
  has = has,
  fastRemoveAtIndex = fastRemoveAtIndex,
  indexOf = indexOf,
  weaken = weaken,
  maybeDrop = maybeDrop,
  invert = invert,
  fill = fill,
  stringifyArray = stringifyArray,
}