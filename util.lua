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

---@param transform love.Transform
---@param cb fun(): nil
local function withTransform(transform, cb)
  love.graphics.push('transform')
  love.graphics.applyTransform(transform)
  cb()
  love.graphics.pop()
end

---@return integer
local function randomLetterCode()
  local letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
  local idx = math.random(#letters)
  return string.byte(letters, idx)
end

-- See <https://love2d.org/wiki/ImageFontFormat>

---@param name string
---@param charWidth integer
---@param charHeight integer
---@param isBold boolean
local function loadFont(name, charWidth, charHeight, isBold)
  local data = love.image.newImageData(name)
  local characters = ' !"#$%&\'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~'
  local fontWidth = 1 + #characters * (charWidth + 1)
  local output = love.image.newImageData(fontWidth, charHeight)

  local function putSeparator(x)
    for y = 0, charHeight - 1 do
      output:setPixel(x, y, 1, 0, 1, 1)
    end
  end

  local base = (isBold and 256 or 0) + 32 -- base 0 + 32 for non-bold font
  local offset = 0
  for char = base, base + #characters do
    putSeparator(offset)
    local y = math.floor(char / 32)
    local x = char % 32

    output:paste(
      data, -- Source
      offset + 1, -- dx
      0, -- dy
      charWidth * x, -- sx
      charHeight * y, -- sy
      charWidth, -- sw
      charHeight -- sh
    )

    offset = offset + charWidth + 1
  end

  putSeparator(fontWidth - 1)

  return love.graphics.newImageFont(output, characters)
end

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

---@param value number
---@param from number
---@param to number
local function clamped(value, from, to)
  return math.min(math.max(value, from), to)
end

return {
  exhaust = exhaust,
  withCanvas = withCanvas,
  withColor = withColor,
  withLineWidth = withLineWidth,
  withTransform = withTransform,
  randomLetterCode = randomLetterCode,
  loadFont = loadFont,
  weightedRandom = weightedRandom,
  clamped = clamped,
}