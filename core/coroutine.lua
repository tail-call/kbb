---@generic T
---@param fun fun(...): T
---@param cb fun(value: T, resume: fun(...)): nil
local function exhaust(fun, cb, ...)
  local thread = coroutine.create(fun)
  local isRunning, result = coroutine.resume(thread, ...)

  while true do
    -- Crash if coroutine fails
    local stupidMessage = 'cannot resume dead coroutine'

    if not isRunning and result ~= stupidMessage then
      error(result)
    end

    if not isRunning then
      return
    end

    cb(result, function (...)
      isRunning, result = coroutine.resume(thread, ...)
    end)
  end
end

return {
  exhaust = exhaust
}