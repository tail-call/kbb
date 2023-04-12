
-- Adapted from <https://www.reddit.com/r/lua/comments/8t0mlf/methods_for_weighted_random_picks/>
---@generic T
---@param pool T[]
---@return T
local function weightedRandom (pool)
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

return {
  weightedRandom = weightedRandom,
}