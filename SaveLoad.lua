---@class SaveLoad
---@field saveGame fun(game: Game, filename: string, echo: fun(text: string))
---@field loadGame fun(game: Game, filename: string, echo: fun(text: string))

local SAVE_FORMAT_MAJOR = 0
local SAVE_FORMAT_MINOR = 0

---@type SaveLoad
local SaveLoad = {}

function SaveLoad.saveGame(game, filename, echo)
  echo(('now saving to %s'):format(filename))

  -- Save fog of war

  local fileContents = {
    ('KPSSVERSION %s %s\n'):format(SAVE_FORMAT_MAJOR, SAVE_FORMAT_MINOR),
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

local commandHandler = {
  ---@type fun(text: string)
  echo = nil,
  echoPrefix = '',

  COM_PARAMS = {},
  COM = function (self)
    -- Is a comment, do nothing
  end,

  KPSSVERSION_PARAMS = { 'number', 'number' },
  KPSSVERSION = function (self, major, minor)
    self.echo(('savefile format version %s %s'):format(major, minor))
    assert(major == SAVE_FORMAT_MAJOR, 'savefile major version mismatch')
    assert(minor == SAVE_FORMAT_MINOR, 'savefile major version mismatch')
  end,

  BLOCK_PARAMS = { 'file', 'number', 'number' },
  BLOCK = function (self, file, blockSize, blockName)
    local compressedBytes = file:read(blockSize)

    if compressedBytes == nil then
      error((self.echoPrefix .. 'no block data for block "%s"'):format(blockName))
    end

    local bytes = love.data.decompress('string', 'zlib', compressedBytes)
    ---@cast bytes string
    self.echo(('%s uncompressed bytes'):format(bytes:len()))

    -- Skip newline
    file:read(1)
  end,
}

function SaveLoad.loadGame(game, filename, echo)
  echo(('now loading from %s'):format(filename))
  local file = io.open(filename, 'rb')
  if file == nil then
    echo('failed to open for reading: kobo.sav')
  else
    local lineCounter = 0
    while true do
      local line = file:read('*l')
      if line == nil then break end

      lineCounter = lineCounter + 1

      commandHandler.echoPrefix = filename .. ':' .. lineCounter
      commandHandler.echo = echo

      local nextWord = string.gmatch(line, '(%w+)')
      local commandName = nextWord()

      if commandName == nil then
        error(('%s:%s: no command'):format(filename, lineCounter))
      end

      local command = commandHandler[commandName]
      local commandParams = commandHandler[commandName .. '_PARAMS']

      if not command then
        error(('%s:%s: unknown command "%s"'):format(filename, lineCounter, command))
      end

      -- Parse parameters

      local parsedParams = {}
      for _, commandParam in ipairs(commandParams) do
        local param
        if commandParam == 'number' then
          param = tonumber(nextWord())
        elseif commandParam == 'file' then
          param = file
        else
          error(('%s:%s: bad param "%s"'):format(filename, lineCounter, commandParam))
        end
        table.insert(parsedParams, param)
      end

      command(commandHandler, unpack(parsedParams))
    end
    file:close()
  end
end

return SaveLoad