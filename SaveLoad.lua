local SAVE_FORMAT_MAGIC = 'KPSS'
local SAVE_FORMAT_MAJOR = 0
local SAVE_FORMAT_MINOR = 0

local SaveLoad = {}

---@param game Game
---@param filename string
---@param echo fun(text: string)
function SaveLoad.saveGame(game, filename, echo)
  local fogOfWar = game.world.fogOfWar
  local input = SAVE_FORMAT_MAGIC
    .. string.char(SAVE_FORMAT_MAJOR, SAVE_FORMAT_MINOR)

  for _, fog in ipairs(fogOfWar) do
    local char = math.floor(fog * 255)
    input = input .. string.char(char)
  end

  local data = love.data.compress('string', 'zlib', input, 9)
  local file = io.open(filename, 'wb')

  if file == nil then
    echo('failed to open for writing: kobo.sav')
  else
    echo(('Written %d bytes'):format(data:len()))
    file:write('' .. data)
    file:close()
  end
end

---@param game Game
---@param filename string
---@param echo fun(text: string)
function SaveLoad.loadGame(game, filename, echo)
  echo('loading...')
  local file = io.open(filename, 'rb')
  if file == nil then
    echo('failed to open for reading: kobo.sav')
  else
    echo('file opened')
    local bytes = file:read('*a')
    ---@type string
    local text = love.data.decompress('string', 'zlib', bytes)
    local magic = text:sub(1, 4)
    echo('text size: ' .. #text)
    echo(('magic: %d %d %d %d'):format(magic:byte(1), magic:byte(2), magic:byte(3), magic:byte(4)))
    file:close()
  end
end

return SaveLoad