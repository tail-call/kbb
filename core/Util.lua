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

  local buf = require 'string.buffer'.new()
  buf:put('local O = {}\n' )
  require 'core.coroutine'.exhaust(process, function(part)
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
    local buf = require 'string.buffer'.new()
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
---@param index table | function
---@return function?, string? errorMessage
local function loadFileWithIndex(filename, index)
  local chunk, compileError = loadfile(filename)
  if chunk == nil then
    return nil, compileError
  end

  return setfenv(chunk, setmetatable({}, {
    __index = index --[[@as table]]
  }))
end

local function makeLanguage(dictionary)
  setmetatable(dictionary, { __index = _G })

  return {
    doFile = function(path)
      local chunk, err = loadFileWithIndex(path, dictionary)
      if not chunk then
        error(err)
      end
      return chunk()
    end
  }
end
return {
  randomLetterCode = randomLetterCode,
  loadFont = loadFont,
  weightedRandom = weightedRandom,
  clamped = clamped,
  dump = dump,
  makeBufDumper = makeBufDumper,
  loadFileWithIndex = loadFileWithIndex,
  makeLanguage = makeLanguage,
}