-- Table utilities

---@generic T
---@param items T[]
---@param predicate fun(item: T): boolean
---@return T | nil
local function find(items, predicate)
  for k, v in ipairs(items) do
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

return {
  find = find,
  iclone = iclone,
  ifilter = ifilter,
  has = has,
  fastRemoveAtIndex = fastRemoveAtIndex,
  indexOf = indexOf,
}