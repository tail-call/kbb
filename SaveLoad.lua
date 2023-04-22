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

function SaveLoad.loadGame(game, filename, echo, commandHandler)
  echo(('now loading from %s'):format(filename))
  local file = io.open(filename, 'rb')
  if file == nil then
    echo('failed to open for reading: kobo.sav')
  else
    commandHandler.echo = echo
    local lineCounter = 1
    while SaveLoad.executeCommand(file, filename, commandHandler, lineCounter) do
      lineCounter = lineCounter + 1
    end
    file:close()
  end
end

return SaveLoad