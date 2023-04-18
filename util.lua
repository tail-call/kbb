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

local function withColor(r, g, b, a, cb)
  local xr, xg, xb, xa = love.graphics.getColor()
  love.graphics.setColor(r, g, b, a)
  cb()
  love.graphics.setColor(xr, xg, xb, xa)
end

return {
  exhaust = exhaust,
  withCanvas = withCanvas,
  withColor = withColor,
}