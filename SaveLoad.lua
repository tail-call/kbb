---@class SaveLoad
---@field saveGame fun(game: Game, filename: string, echo: fun(text: string))
---@field loadGame fun(game: Game, filename: string, echo: fun(text: string))

local SAVE_FORMAT_MAJOR = '0'
local SAVE_FORMAT_MINOR = '0'

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
    'COM fog data is a block: array of zlib-compressed bytes\n',
    game.world:serialize(),
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

  COM = function (self, major, minor)
    -- Is a comment, do nothing
  end,

  KPSSVERSION = function (self, major, minor)
    self.echo(('savefile format version %s %s'):format(major, minor))
    assert(major == SAVE_FORMAT_MAJOR, 'savefile major version mismatch')
    assert(minor == SAVE_FORMAT_MINOR, 'savefile major version mismatch')
  end,

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
      local command = nextWord()

      if command == 'KPSSVERSION' then
        commandHandler:KPSSVERSION(nextWord(), nextWord())
      elseif command == 'COM' then
        commandHandler:COM()
      elseif command == 'BLOCK' then
        local blockName = nextWord()
        local blockSizeRaw = nextWord()
        local blockSize = tonumber(blockSizeRaw)

        if blockSize == nil then
          error(('%s:%s: BLOCK: bad block size "%s"'):format(filename, lineCounter, blockSize))
        end

        commandHandler:BLOCK(file, blockSize, blockName)
      elseif command == nil then
        error(('%s:%s: no command'):format(filename, lineCounter))
      else
        error(('%s:%s: unknown command "%s"'):format(filename, lineCounter, command))
      end
    end
    file:close()
  end
end

return SaveLoad