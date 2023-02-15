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

return {
  find = find,
  has = has,
}