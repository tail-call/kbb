local SAVE_FORMAT_MAJOR = '0'
local SAVE_FORMAT_MINOR = '0'

local SaveLoad = {}

---@param game Game
---@param filename string
---@param echo fun(text: string)
function SaveLoad.saveGame(game, filename, echo)
  echo(('now saving to %s'):format(filename))

  -- Save fog of war

  ---@type string[]
  local fogOfWar = game.world.fogOfWar
  local fogContents = {}

  for _, fog in ipairs(fogOfWar) do
    local char = math.floor(fog * 255)
    table.insert(fogContents, string.char(char))
  end

  local fogData = table.concat(fogContents)

  local fogCompressedData = love.data.compress(
    'string', 'zlib', fogData, 9
  )

  local fileContents = {
    ('KPSSVERSION %s %s\n'):format(SAVE_FORMAT_MAJOR, SAVE_FORMAT_MINOR),
    'COM kobold princess simulator save file\n',
    'COM every line is a command, COM is a comment command\n',
    'COM binary data is compressed with zlib\n',
    'COM\n',
    'COM fog data is just an array of bytes\n',
    ('BLOCK fogOfWar %d\n'):format(fogCompressedData:len()),
    fogCompressedData, '\n'
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

---@param game Game
---@param filename string
---@param echo fun(text: string)
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

      local nextWord = string.gmatch(line, '(%w+)')
      local command = nextWord()

      if command == 'KPSSVERSION' then
        local major = nextWord()
        local minor = nextWord()
        echo(('savefile format version %s %s'):format(major, minor))
        assert(major == SAVE_FORMAT_MAJOR, 'savefile major version mismatch')
        assert(minor == SAVE_FORMAT_MINOR, 'savefile major version mismatch')
      elseif command == 'COM' then
        -- Is a comment, do nothing
      elseif command == 'BLOCK' then
        local blockName = nextWord()
        local blockSizeRaw = nextWord()
        local blockSize = tonumber(blockSizeRaw)

        if blockSize == nil then
          error(('%s:%s: BLOCK: bad block size "%s"'):format(filename, lineCounter, blockSize))
        end

        local compressedBytes = file:read(blockSize)

        if compressedBytes == nil then
          error(('%s:%s: no block data for block "%s"'):format(filename, lineCounter, blockName))
        end

        local bytes = love.data.decompress('string', 'zlib', compressedBytes)
        echo(('%s uncompressed bytes'):format(bytes:len()))

        -- Skip newline
        file:read(1)
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