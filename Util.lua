local buffer = require('string.buffer')

local SKY_TABLE = {
  -- 00:00
  { r = 0.3, g = 0.3, b = 0.6, },
  -- 06:00
  { r = 1.0, g = 0.9, b = 0.8, },
  -- 12:00
  { r = 1, g = 1, b = 1, },
  -- 18:00
  { r = 1.0, g = 0.7, b = 0.7, },
}

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

---@param data love.ImageData
---@param charWidth integer
---@param charHeight integer
---@param isBold boolean
local function loadFont(data, charWidth, charHeight, isBold)
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

---Adapted from <https://www.reddit.com/r/lua/comments/8t0mlf/methods_for_weighted_random_picks/>
---@generic T: { weight: number }
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

---@param time number
---@return { r: number, g: number, b: number }
local function skyColorAtTime(time)
  local length = #SKY_TABLE
  local offset, blendFactor = math.modf((time) / (24 * 60) * length)
  local colorA = SKY_TABLE[1 + (offset + 0) % length]
  local colorB = SKY_TABLE[1 + (offset + 1) % length]
  -- Blend colors together
  return {
    r = colorA.r + (colorB.r - colorA.r) * blendFactor,
    g = colorA.g + (colorB.g - colorA.g) * blendFactor,
    b = colorA.b + (colorB.b - colorA.b) * blendFactor,
  }
end

---Dumps an object to Lua code
---@param object any
---@return string
local function dump(object)
  local references = {}
  local lastReference = 0

  local function withRecord(obj, cb)
    coroutine.yield(('O[%d] = '):format(lastReference + 1))
    cb()
    lastReference = lastReference + 1
    references[obj] = lastReference
    coroutine.yield('\n')
  end

  local function isPrimitive(obj)
    local t = type(obj)
    return (
      t == 'boolean'
      or t == 'function'
      or t == 'number'
      or t == 'string'
      or t == 'nil'
    )
  end

  local function dumpPrimitive(obj)
    local t = type(obj)
    if t == 'boolean' then
      return t and 'true' or 'false'
    elseif t == 'function' then
      return ('nil--[[%s]]'):format(obj)
    elseif t == 'number' then
      return tostring(obj)
    elseif t == 'string' then
      return ('%q'):format(obj)
    elseif t == 'nil' then
      return 'nil'
    end
  end

  ---@param obj any
  local function process(obj)
    if references[obj] then
      withRecord(obj, function ()
        coroutine.yield(('O[%d]'):format(references[obj]))
      end)
    elseif type(obj) == 'table' then
      local metatable = getmetatable(obj)
      local customDump = metatable and metatable.dump or nil
      if customDump then
        withRecord(obj, function ()
          customDump(coroutine.yield)
        end)
      else
        -- First dump all dependencies
        for k, v in pairs(obj) do
          if not isPrimitive(v) then
            process(v)
          end
        end

        withRecord(obj, function ()
          if obj.__module then
            coroutine.yield(obj.__module)
          end

          coroutine.yield('{')
          for k, v in pairs(obj) do
            if type(k) == 'number' then
              coroutine.yield('['..k..']')
            else
              coroutine.yield(k)
            end

            coroutine.yield('=')
            if isPrimitive(v) then
              coroutine.yield(dumpPrimitive(v))
            else
              coroutine.yield(('O[%d]'):format(references[v]))
            end
            coroutine.yield(',')
          end

          coroutine.yield('}')
        end)
      end
    elseif type(obj) == 'userdata' then
      withRecord(obj, function ()
        if obj:type() == 'Quad' then
          ---@cast obj love.Quad
          coroutine.yield('quad(')
          local x, y, w, h = obj:getViewport()
          local sw, sh = obj:getTextureDimensions()
          coroutine.yield(('%s,%s,%s,%s,%s,%s'):format(x, y, w, h, sw, sh))
          coroutine.yield(')')
        else
          coroutine.yield(obj:type())
        end
      end)
    else
      error(('dump: unsupported type %s of object %s'):format(type(obj), obj))
    end
  end

  local buf = buffer.new()
  buf:put('local O = {}\n' )
  exhaust(process, function(part)
    buf:put(part or '')
  end, object)

  buf:put('return O[#O]')

  return buf:tostring()
end

---Returns a function that will dump an array into a base64 encoded buffer
---@param array any
---@param format any
---@return function
local function makeBufDumper (array, format)
  ---@param write fun(data: string)
  return function(write)
    local buf = buffer.new()
    buf:put('return{')
    for _, word in ipairs(array) do
      buf:put(string.format(format, word))
    end

    buf:put('}')
    local data = buf:tostring()

    write('buf{base64=[[')
    local compressedData = love.data.compress('data', 'zlib', data)
    local encodedData = love.data.encode('string', 'base64', compressedData)
    ---@cast encodedData string
    write(encodedData)
    write(']]}')
  end
end

---@param filename string
---@param index table
---@return fun()?, string? errorMessage
local function doFileWithIndex(filename, index)
  local chunk, compileError = loadfile(filename)
  if chunk == nil then
    return nil, compileError
  end

  return setfenv(chunk, setmetatable({}, { __index = index }))
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
  skyColorAtTime = skyColorAtTime,
  dump = dump,
  makeBufDumper = makeBufDumper,
  doFileWithIndex = doFileWithIndex,
}