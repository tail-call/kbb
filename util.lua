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

---@param canvas love.Canvas
---@param cb fun(canvas: love.Canvas): nil
local function withCanvas(canvas, cb)
  love.graphics.setCanvas(canvas)
  love.graphics.push('transform')
  love.graphics.replaceTransform(love.math.newTransform())
  cb(canvas)
  love.graphics.pop()
  love.graphics.setCanvas()
end

---@param r number
---@param g number
---@param b number
---@param a number
---@param cb fun(): nil
local function withColor(r, g, b, a, cb)
  local xr, xg, xb, xa = love.graphics.getColor()
  love.graphics.setColor(r, g, b, a)
  cb()
  love.graphics.setColor(xr, xg, xb, xa)
end

---@param lineWidth number
---@param cb fun(): nil
local function withLineWidth(lineWidth, cb)
  local xLineWidth = love.graphics.getLineWidth()
  love.graphics.setLineWidth(lineWidth)
  cb()
  love.graphics.setLineWidth(xLineWidth)
end

return {
  exhaust = exhaust,
  withCanvas = withCanvas,
  withColor = withColor,
  withLineWidth = withLineWidth,
}