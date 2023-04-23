---@class KPSSModule
---@field MAJOR_VERSION 0
---@field MINOR_VERSION 0
---@field save fun(object: X_Serializable, file: file*, echo: fun(text: string))
---@field load fun(object: X_Serializable, file: file*, echo: fun(text: string), commandHandler: any)
---@field executeCommand fun(file: file*, name: string, commandHandler: table, rep: number)

---@type KPSSModule
local KPSS = {}

KPSS.MAJOR_VERSION = 0
KPSS.MINOR_VERSION = 0

function KPSS.save(object, file, echo)
  echo(('now saving to %s'):format(file))

  -- Save fog of war

  local fileContents = {
    ('KPSSVERSION %s %s\n'):format(KPSS.MAJOR_VERSION, KPSS.MINOR_VERSION),
    'COM kobold princess simulator save file\n',
    'COM every line is a command, COM is a comment command\n',
    'COM\n',
    object:serialize(),
  }

  local bytesWritten = 0

  if file == nil then
    echo('failed to open for writing: kobo.sav')
  else
    for _, line in ipairs(fileContents) do
      file:write(line)
      bytesWritten = bytesWritten + line:len()
    end
    echo(('wrote %d bytes'):format(bytesWritten))
  end
end

---@param obj any
function KPSS.makeCommandHandler(obj)
  local commandHandler = {
    COM_PARAMS = {},
    COM = function (self)
      -- Is a comment, do nothing
    end,

    KPSSVERSION_PARAMS = { 'number', 'number' },
    KPSSVERSION = function (self, major, minor)
      assert(major == KPSS.MAJOR_VERSION, 'savefile major version mismatch')
      assert(minor == KPSS.MINOR_VERSION, 'savefile major version mismatch')
    end,

    NUMBER_PARAMS = { 'string', 'number' },
    NUMBER = function (self, name, num)
      obj[name] = num
    end,

    VECTOR_PARAMS = { 'string', 'number', 'number' },
    VECTOR = function (self, name, x, y)
      obj[name] = { x = x, y = y }
    end,

    OBJECT_PARAMS = { 'file', 'string', 'string', 'number' },
    OBJECT = function (self, file, moduleName, name, propsCount)
      local module = require(moduleName)

      if module == nil then
        error('no such module')
      end

      local deserialize = module.deserialize

      if deserialize == nil then
        error(('module %s is not deserializable'):format(moduleName))
      end

      obj[name] = deserialize(file, propsCount)
    end,

    BLOCK_PARAMS = { 'file', 'string', 'block' },
    BLOCK = function (self, file, blockName, bytes)
      obj:hack_parseBlock(blockName, bytes)

      -- Skip newline
      file:read(1)
    end,
  }
  return commandHandler
end

function KPSS.executeNextLine(file, filename, commandHandler, lineCounter)
  local line = file:read('*l')
  if line == nil then return false end

  commandHandler.echoPrefix = filename .. ':' .. lineCounter

  local nextWord = string.gmatch(line, '([%w.]+)')
  local commandName = nextWord()

  if commandName == nil then
    error(('%s:%s: no command'):format(filename, lineCounter))
  end

  local command = commandHandler[commandName]
  local commandParams = commandHandler[commandName .. '_PARAMS']

  if not command then
    error(('%s:%s: unknown command "%s"'):format(filename, lineCounter, commandName))
  end

  -- Parse parameters

  local parsedParams = {}
  for _, commandParam in ipairs(commandParams) do
    local param
    if commandParam == 'number' then
      param = tonumber(nextWord())
    elseif commandParam == 'string' then
      param = nextWord()
    elseif commandParam == 'block' then
      local blockSize = tonumber(nextWord())
      local compressedBytes = file:read(blockSize)

      if compressedBytes == nil then
        error('no block data')
      end

      param = love.data.decompress('string', 'zlib', compressedBytes)
    elseif commandParam == 'file' then
      param = file
    else
      error(('%s:%s: bad param "%s"'):format(filename, lineCounter, commandParam))
    end
    table.insert(parsedParams, param)
  end

  command(commandHandler, unpack(parsedParams))
  return true
end

function KPSS.load(object, file, echo)
  echo(('now loading from %s'):format(file))
  if file == nil then
    echo('failed to open for reading: kobo.sav')
  else
    local commandHandler = KPSS.makeCommandHandler(object)
    local lineCounter = 1
    while KPSS.executeNextLine(file, '???', commandHandler, lineCounter) do
      lineCounter = lineCounter + 1
    end
  end
end

---@param obj table
---@return string
function KPSS.dumpTable (obj, module, name, prefix)
  local lines = {}
  prefix = prefix or ''

  for key, value in pairs(obj) do
    local luaType = type(value)
    local line = ('DIAG Failed to parse value "%s" of type "%s" at key "%s"\n'):format(value, luaType, key)
    if type(key) == 'string' and luaType == 'function' then
      if key:sub(1, 2) == 'X_' then
        line = ('COM implements %s interface\n'):format(key)
      else
        line = ('COM method %s\n'):format(key)
      end
    elseif luaType == 'number' then
      line = ('NUMBER %s %s\n'):format(key, value)
    elseif luaType == 'boolean' then
      line = ('BOOLEAN %s %s\n'):format(key, value)
    elseif luaType == 'userdata' then
      if value:typeOf('Transform') then
        ---@cast value love.Transform
        line = ('TRANSFORM %s ' .. ('%s'):rep(16, ' ') .. '\n' ):format(key, value:getMatrix())
      elseif value:typeOf('Quad') then
        ---@cast value love.Quad
        local x, y, w, h = value:getViewport()
        local sw, sh = value:getTextureDimensions()
        line = ('QUAD %s %s %s %s %s %s %s\n'):format(key, x, y, w, h, sw, sh)
      end
    elseif luaType == 'table' then
      line = KPSS.dumpTable(value, nil, key, ' ' .. prefix)
    elseif luaType == 'string' then
      line = ('STRING %s %q\n'):format(key, value)
    end
    table.insert(lines, ' ' .. prefix .. line)
  end

  local header = ('OBJECT %s %s %s\n'):format(module, name, #lines)
  table.insert(lines, 1, header)

  return table.concat(lines)
end

return KPSS