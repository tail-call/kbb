---@generic T
---@param fun fun(): T
---@param cb fun(value: T): nil
local function exhaust(fun, cb)
  local crt = coroutine.create(fun)
  local isRunning, result = coroutine.resume(crt)
  while isRunning do
    cb(result)
    isRunning, result = coroutine.resume(crt)
  end
end

return {
  exhaust = exhaust,
}