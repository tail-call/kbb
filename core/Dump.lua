--- Functions for translating Lua objects into Lua source
--- It's like JSON but for Lua and not dumbed down

local TypeCase = require 'core.flow'.TypeCase
local ETypeCase = require 'core.flow'.ETypeCase

---`coroutine.yield`s a formatted string
---@param formatString string
---@param ... any
local function emit(formatString, ...)
  coroutine.yield(
    string.format(formatString, ...)
  )
end

---Dumps an object to Lua code
---@param object any
---@return string
local function dump(object)
  local references = {}
  local lastReference = 0

  local function withRecord(obj, cb)
    emit('O[%d] = ', lastReference + 1)
    cb()
    lastReference = lastReference + 1
    references[obj] = lastReference
    emit('\n')
  end

  local function isPrimitive(obj)
    return TypeCase(obj) {
      'boolean', true,
      'function', true,
      'number', true,
      'string', true,
      'nil', true,
      nil, false,
    }
  end

  local function dumpPrimitive(obj)
    return TypeCase(obj) {
      'boolean', function ()
        return obj and 'true' or 'false'
      end,
      'function', function ()
        return ('nil--[[%s]]'):format(obj)
      end,
      'number', function ()
        return tostring(obj)
      end,
      'string', function ()
        return ('%q'):format(obj)
      end,
      'nil', function ()
        return 'nil'
      end,
    }
  end

  ---@param obj any
  local function process(obj)
    if references[obj] then
      withRecord(obj, function ()
        emit('O[%d]', references[obj])
      end)
    else ETypeCase(obj) {
      'table', function ()
        local metatable = getmetatable(obj)
        local customDump = metatable and metatable.dump or nil
        if customDump then
          withRecord(obj, function ()
            customDump(emit)
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
              emit(obj.__module)
            end

            emit('{')
            for k, v in pairs(obj) do
              ETypeCase(k) {
                'number', function ()
                  emit('['..k..']')
                end,
                'table', function ()
                  error('tables as keys are not supported')
                end,
                nil, function ()
                  emit(k)
                end,
              }

              emit('=')
              if isPrimitive(v) then
                emit(dumpPrimitive(v))
              else
                emit('O[%d]', references[v])
              end
              emit(',')
            end

            emit('}')
          end)
        end
      end,
      'userdata', function ()
        withRecord(obj, function ()
          if obj:type() == 'Quad' then
            ---@cast obj love.Quad
            emit('quad(')
            local x, y, w, h = obj:getViewport()
            local sw, sh = obj:getTextureDimensions()
            emit('%s,%s,%s,%s,%s,%s', x, y, w, h, sw, sh)
            emit(')')
          else
            emit(obj:type())
          end
        end)
      end
    } end
  end

  local buf = require 'string.buffer'.new()
  buf:put('local O = {}\n' )

  require 'core.coroutine'.exhaust(process, function(part, resume)
    buf:put(part or '')
    resume()
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

  local lang
  lang = {
    call = function (fun, ...)
      local oldEnv = getfenv(fun)
      setfenv(fun, dictionary)(...)
      setfenv(fun, oldEnv)
    end,
    loadFile = function(path)
      local chunk, err = loadFileWithIndex(path, dictionary)
      if not chunk then
        error(err)
      end
      return chunk
    end,
    doFile = function(path)
      return lang.loadFile(path)()
    end
  }

  return lang
end

return {
  dump = dump,
  makeBufDumper = makeBufDumper,
  loadFileWithIndex = loadFileWithIndex,
  makeLanguage = makeLanguage,
}