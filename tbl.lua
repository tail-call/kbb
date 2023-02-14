---@generic T
---@param items T[]
---@param predicate fun(item: T): boolean
local function find(items, predicate)
  for k, v in ipairs(items) do
    if predicate(v) then
      return v
    end
  end
  return nil
end

return {
  find = find
}