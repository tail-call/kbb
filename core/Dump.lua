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

local function shouldInline(obj)
  return ETypeCase(obj) {
    'boolean', true,
    'function', true,
    'number', true,
    'string', true,
    'nil', true,
    nil, false,
  }
end

---@class core.dump.ChildEmitter
---@field references table Record table
---@field emitChild fun(self: core.dump.ChildEmitter, obj: any, cb: fun()) Emits a record
---@field idOfChild fun(self: core.dump.ChildEmitter, obj: any): number | nil Returns a reference number for an object if any

---Creates and returns a new child emitter
---@return core.dump.ChildEmitter
local function makeChildEmitter()
  local lastId = 0
  local childrenToIds = {}

  return {
    emitChild = function (self, child, cb)
      emit('O[%d] = ', lastId + 1)
      cb()
      lastId = lastId + 1
      childrenToIds[child] = lastId
      emit('\n')
    end,
    idOfChild = function (self, obj)
      return childrenToIds[obj]
    end,
  }
end

---@param obj any
---@param childEmitter core.dump.ChildEmitter
local function emitTable(obj, childEmitter)
  local objId = childEmitter:idOfChild(obj)
  if objId then
    childEmitter:emitChild(obj, function ()
      emit('O[%d]', objId)
    end)
  else ETypeCase(obj) {
    'table', function ()
      local metatable = getmetatable(obj)
      local customDump = metatable and metatable.dump or nil
      if customDump then
        childEmitter:emitChild(obj, function ()
          customDump(obj)
        end)
      else
        -- First dump all children
        for _, v in pairs(obj) do
          if not shouldInline(v) then
            emitTable(v, childEmitter)
          end
        end

        childEmitter:emitChild(obj, function ()
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
            if shouldInline(v) then
              ETypeCase(v) {
                'function', function ()
                  -- Will emit a function's address
                  emit('nil--[[%s]]', v)
                end,
                'string', function ()
                  emit('%q', v)
                end,
                nil, function ()
                  emit(tostring(v))
                end,
              }
            else
              emit('O[%d]', childEmitter:idOfChild(v))
            end
            emit(',')
          end

          emit('}')
        end)
      end
    end,
    'userdata', function ()
      childEmitter:emitChild(obj, function ()
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
  local buf = require 'string.buffer'.new()
  buf:put('local O = {}\n' )

  require 'core.coroutine'.exhaust(function (o)
    return emitTable(o, makeChildEmitter())
  end, function(part, resume)
    buf:put(part or '')
    resume()
  end, object)

  buf:put('return O[#O]')

  return buf:tostring()
end

---Returns a function that will dump an array into a base64 encoded buffer.
---
---`format` is something `string.format` may accept.
---@param formatString string
---@return function
local function makeBase64Dumper (formatString)
  return function(array)
    local buf = require 'string.buffer'.new()
    buf:put('return{')
    for _, word in ipairs(array) do
      buf:put(string.format(formatString, word))
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
  makeBase64Dumper = makeBase64Dumper,
  loadFileWithIndex = loadFileWithIndex,
  makeLanguage = makeLanguage,
}