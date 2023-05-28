---@generic T
---@param fun fun(): T
---@param cb fun(value: T): nil
local function exhaust(fun, cb, ...)
  local crt = coroutine.create(fun)
  local isRunning, result = coroutine.resume(crt, ...)

  local function doStuff()
    -- Crash if coroutine fails
    local stupidMessage = 'cannot resume dead coroutine'
    if not isRunning and result ~= stupidMessage then
      error(result)
    end
  end

  doStuff()
  while isRunning do
    cb(result)
    isRunning, result = coroutine.resume(crt)
    doStuff()
  end
end

return {
  exhaust = exhaust
}