local function withCanvas(canvas, cb)
  love.graphics.setCanvas(canvas)
  love.graphics.push('transform')
  love.graphics.replaceTransform(love.math.newTransform())
  cb()
  love.graphics.pop()
  love.graphics.setCanvas()
end

return {
  withCanvas = withCanvas
}