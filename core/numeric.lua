local M = {}

---Adapted from <https://www.reddit.com/r/lua/comments/8t0mlf/methods_for_weighted_random_picks/>
---@generic T: { weight: number }
---@param pool T[]
---@return T
function M.weightedRandom (pool)
  local poolsize = 0
  for _,v in ipairs(pool) do
   poolsize = poolsize + v.weight
  end
  local selection = math.random(1,poolsize)
  for _,v in ipairs(pool) do
   selection = selection - v.weight
   if (selection <= 0) then
    return v
   end
  end
  return pool[1]
 end

---@param value number
---@param from number
---@param to number
function M.clamped(value, from, to)
  return math.min(math.max(value, from), to)
end

return M