---@class SaveLoad
---@field SAVE_FORMAT_MAJOR 0
---@field SAVE_FORMAT_MINOR 0
---@field saveGame fun(game: Game, filename: string, echo: fun(text: string))
---@field loadGame fun(game: Game, filename: string, echo: fun(text: string), commandHandler: any)

---@type SaveLoad
local SaveLoad = {}

SaveLoad.SAVE_FORMAT_MAJOR = 0
SaveLoad.SAVE_FORMAT_MINOR = 0

function SaveLoad.saveGame(game, filename, echo)
  echo(('now saving to %s'):format(filename))

  -- Save fog of war

  local fileContents = {
    ('KPSSVERSION %s %s\n'):format(SaveLoad.SAVE_FORMAT_MAJOR, SaveLoad.SAVE_FORMAT_MINOR),
    'COM kobold princess simulator save file\n',
    'COM every line is a command, COM is a comment command\n',
    'COM\n',
    game:serialize(),
  }

  local file = io.open(filename, 'wb')
  local bytesWritten = 0

  if file == nil then
    echo('failed to open for writing: kobo.sav')
  else
    for _, line in ipairs(fileContents) do
      file:write(line)
      bytesWritten = bytesWritten + line:len()
    end
    echo(('wrote %d bytes'):format(bytesWritten))
    file:close()
  end
end

---@param obj any
function SaveLoad.makeCommandHandler(obj)
  local commandHandler = {
    COM_PARAMS = {},
    COM = function (self)
      -- Is a comment, do nothing
    end,

    KPSSVERSION_PARAMS = { 'number', 'number' },
    KPSSVERSION = function (self, major, minor)
      assert(major == SaveLoad.SAVE_FORMAT_MAJOR, 'savefile major version mismatch')
      assert(minor == SaveLoad.SAVE_FORMAT_MINOR, 'savefile major version mismatch')
    end,

    NUMBER_PARAMS = { 'string', 'number' },
    NUMBER = function (self, name, num)
      obj[name] = num
    end,

    VECTOR_PARAMS = { 'string', 'number', 'number' },
    VECTOR = function (self, name, x, y)
      if name == 'playerPos' then
        obj.player:move({ x = x, y = y })
      else
        error('what is ' .. name)
      end
    end,

    OBJECT_PARAMS = { 'file', 'string', 'string', 'number' },
    OBJECT = function (self, file, moduleName, name, propsCount)
      local module = require(moduleName)

      if module == nil then
        error('no such module')
      end

      local deserialize = module.deserialize

      if deserialize == nil then
        error('module not deserializable')
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

function SaveLoad.executeCommand(file, filename, commandHandler, lineCounter)
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

function SaveLoad.loadGame(game, filename, echo)
  echo(('now loading from %s'):format(filename))
  local file = io.open(filename, 'rb')
  if file == nil then
    echo('failed to open for reading: kobo.sav')
  else
    local commandHandler = SaveLoad.makeCommandHandler(game)
    local lineCounter = 1
    while SaveLoad.executeCommand(file, filename, commandHandler, lineCounter) do
      lineCounter = lineCounter + 1
    end
    file:close()
  end
end

return SaveLoad