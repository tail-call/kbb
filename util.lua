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

local function withCanvas(canvas, cb)
  love.graphics.setCanvas(canvas)
  love.graphics.push('transform')
  love.graphics.replaceTransform(love.math.newTransform())
  cb()
  love.graphics.pop()
  love.graphics.setCanvas()
end

return {
  exhaust = exhaust,
  withCanvas = withCanvas,
}