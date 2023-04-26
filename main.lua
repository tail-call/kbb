-- Need to do this before anything else is executed
math.randomseed(os.time())

local draw = require('Draw')
local makeGame = require('Game').new
local handleInput = require('Game').handleInput
local updateGame = require('Game').updateGame
local beginRecruiting = require('Game').beginRecruiting
local endRecruiting = require('Game').endRecruiting
local tbl = require('tbl')
local vector = require('Vector')
local gameover = require('GameOver')
local loadTileset = require('Tileset').load
local loadFont = require('Util').loadFont

local FILENAME = './kobo2.kpss'

---@type 'game' | 'dead'
local state = 'game'
---@type Game
local game

---@type DrawState
local drawState

local function loadGame()
  local saveGameFunction, compileError = loadfile(FILENAME)
  if saveGameFunction == nil then
    error(compileError)
  end

  local moduleLoader = {}
  setmetatable(moduleLoader, { __index = function(t, k)
    return function(props)
      if k == 'Quad' then
        return love.graphics.newQuad
      elseif k == 'buf' then
        return function(props)
          local compressedData = love.data.decode('data', 'base64', props.base64)
          local data = love.data.decompress('string', 'zlib', compressedData)
          ---@cast data string
          local array = loadstring(data)()
          return array
        end
      else
        -- Loading from module k
        props.__module = k
        return require(k).new(props)
      end
    end
  end })
  setfenv(saveGameFunction, moduleLoader)
  game = saveGameFunction()
  if game == nil then
    error('no game')
  end
end

function love.load()
  love.graphics.setDefaultFilter('linear', 'nearest')
  love.graphics.setFont(loadFont('cga8.png', 8, 8, math.random() > 0.5))
  love.graphics.setLineStyle('rough')
  love.mouse.setVisible(false)
  loadTileset()
  local tileset = require('Tileset').getTileset()
  drawState = require('DrawState').new(tileset)
  game = makeGame()
  game.onLost = function ()
    state = 'dead'
  end
  loadGame()
end

---@param dt number
function love.update(dt)
  draw.update(
    drawState,
    dt,
    game.isFocused
      and vector.add(game.cursorPos, { x = 0, y = 0 })
      or vector.midpoint(game.player.pos, game.cursorPos),
    game.isFocused
      and game.magnificationFactor * 2
      or game.magnificationFactor,
    game.isFocused
  )
  if state == 'game' then
    -- Handle diagonal movement
    local directions = {}
    for key, value in pairs(vector.dir) do
      if love.keyboard.isDown(key) then
        table.insert(directions, value)
      end
    end

    updateGame(game, dt, directions)
  end
end

function love.textinput(text)
  require('Game').handleText(game, text)
end

---@param key love.KeyConstant
---@param scancode love.Scancode
---@param isrepeat boolean
function love.keypressed(key, scancode, isrepeat)
  if tbl.has({ '1', '2', '3', '4' }, scancode) then
    draw.setZoom(drawState, tonumber(scancode) or 1)
  end

  if scancode == '8' then
    -- Write to file
    do
      local file = io.open(FILENAME, 'w+')
      if file == nil then error('no file') end

      for _, line in ipairs(game:serialize1()) do
        file:write(line)
      end
      file:close()
    end

  end

  if state ~= 'game' then return end

  handleInput(game, scancode, key)
end

function love.mousepressed(x, y, button, presses)
  if button == 1 then
    beginRecruiting(game)
  end
end

function love.mousereleased(x, y, button, presses)
  if button == 1 then
    endRecruiting(game)
  end
end

---@param key love.KeyConstant
---@param scancode love.Scancode
function love.keyreleased(key, scancode)
  if state ~= 'game' then return end
end

function love.draw()
  require('Draw').prepareFrame(drawState)
  require('Draw').drawGame(game, drawState)
  if state == 'dead' then
    gameover.draw()
  end
end