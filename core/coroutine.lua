---@generic T
---@param fun fun(): T
---@param cb fun(value: T, resume: fun(...)): nil
local function exhaust(fun, cb, ...)
  local thread = coroutine.create(fun)
  local isRunning, result = coroutine.resume(thread, ...)

  local function run()
    -- Crash if coroutine fails
    local stupidMessage = 'cannot resume dead coroutine'
    if not isRunning and result ~= stupidMessage then
      error(result)
    end

    cb(result, function (...)
      isRunning, result = coroutine.resume(thread, ...)
      run()
    end)
  end

  run()
end

return {
  exhaust = exhaust
}