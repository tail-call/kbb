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