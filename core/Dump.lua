--- Functions for translating Lua objects into Lua source
--- It's like JSON but for Lua and not dumbed down

local ETypeCase = require 'core.flow'.ETypeCase

---`coroutine.yield`s a formatted string
---@param formatString string
---@param ... any
local function emit(formatString, ...)
  coroutine.yield(
    string.format(formatString, ...)
  )
end

local function isPrimitive(obj)
  return ETypeCase(obj) {
    'boolean', true,
    'function', true,
    'number', true,
    'string', true,
    'nil', true,
    nil, false,
  }
end

---@class RecordWriter
---@field references table Record table
---@field withRecord fun(self: RecordWriter, obj: any, cb: fun()) Emits a record
---@field referenceForObject fun(self: RecordWriter, obj: any): number | nil Returns a reference number for an object if any

---Creates and returns a new record writer
---@return RecordWriter
local function makeRecordWriter()
  local lastReference = 0
  local references = {}

  return {
    withRecord = function (self, obj, cb)
      emit('O[%d] = ', lastReference + 1)
      cb()
      lastReference = lastReference + 1
      references[obj] = lastReference
      emit('\n')
    end,
    referenceForObject = function (self, obj)
      return references[obj]
    end,
  }
end

---@param obj any
---@param recordWriter RecordWriter
local function process(obj, recordWriter)
  local reference = recordWriter:referenceForObject(obj)
  if reference then
    recordWriter:withRecord(obj, function ()
      emit('O[%d]', reference)
    end)
  else ETypeCase(obj) {
    'table', function ()
      local metatable = getmetatable(obj)
      local customDump = metatable and metatable.dump or nil
      if customDump then
        recordWriter:withRecord(obj, function ()
          customDump()
        end)
      else
        -- First dump all dependencies
        for k, v in pairs(obj) do
          if not isPrimitive(v) then
            process(v, recordWriter)
          end
        end

        recordWriter:withRecord(obj, function ()
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
              ETypeCase(v) {
                'function', function ()
                  -- Will emit a function's address
                  return emit('nil--[[%s]]', v)
                end,
                'string', function ()
                  return emit('%q', v)
                end,
                nil, function ()
                  emit(tostring(v))
                end,
              }
            else
              emit('O[%d]', recordWriter:referenceForObject(v))
            end
            emit(',')
          end

          emit('}')
        end)
      end
    end,
    'userdata', function ()
      recordWriter:withRecord(obj, function ()
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

---Dumps an object to Lua code
---@param object any
---@return string
local function dump(object)
  local recordWriter = makeRecordWriter()
  local buf = require 'string.buffer'.new()
  buf:put('local O = {}\n' )

  require 'core.coroutine'.exhaust(function (o)
    return process(o, recordWriter)
  end, function(part, resume)
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
  return function()
    local buf = require 'string.buffer'.new()
    buf:put('return{')
    for _, word in ipairs(array) do
      buf:put(string.format(format, word))
    end

    buf:put('}')
    local data = buf:tostring()

    emit('buf{base64=[[')
    local compressedData = love.data.compress('data', 'zlib', data)
    local encodedData = love.data.encode('string', 'base64', compressedData)
    ---@cast encodedData string
    emit(encodedData)
    emit(']]}')
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
    end,
  }

  return lang
end

return {
  dump = dump,
  makeBufDumper = makeBufDumper,
  loadFileWithIndex = loadFileWithIndex,
  makeLanguage = makeLanguage,
}