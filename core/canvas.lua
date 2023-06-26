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

return {
  withCanvas = withCanvas,
}