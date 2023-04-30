-- Need to do this before anything else is executed
math.randomseed(os.time())

local handleInput = require('Game').handleInput
local updateGame = require('Game').updateGame
local beginRecruiting = require('Game').beginRecruiting
local endRecruiting = require('Game').endRecruiting
local tbl = require('tbl')
local vector = require('Vector')
local gameover = require('GameOver')
local loadTileset = require('Tileset').load
local loadFont = require('Util').loadFont
local updateDrawState = require('DrawState').updateDrawState

local setWindowScale = require('DrawState').mut.setWindowScale

local SAVEFILE_NAME = './kobo2.kpss'

package.preload['res/map.png'] = function (filename)
  local imageData = love.image.newImageData(filename)
  return imageData
end

package.preload['res/tiles.png'] = function (filename)
  return love.graphics.newImage(filename)
end

---@type 'game' | 'dead'
local state = 'game'
---@type Game
local game

---@type DrawState
local drawState

---@param filename string
---@param loaders { [string]: function }
---@return fun()?, string? errorMessage
local function loadGame(filename, loaders)
  local saveGameFunction, compileError = loadfile(filename)
  if saveGameFunction == nil then
    return nil, compileError
  end

  local moduleLoader = {}
  setmetatable(moduleLoader, { __index = function(t, k)
    return function(...)
      local loader = loaders[k]
      if loader ~= nil then
        return loader(...)
      else
        return require(k).new(...)
      end
    end
  end })
  setfenv(saveGameFunction, moduleLoader)
  return saveGameFunction
end

function love.load()
  love.graphics.setDefaultFilter('linear', 'nearest')
  love.graphics.setFont(loadFont('res/cga8.png', 8, 8, math.random() > 0.5))
  love.graphics.setLineStyle('rough')
  love.mouse.setVisible(false)
  loadTileset()
  local tileset = require('Tileset').getTileset()
  drawState = require('DrawState').new({ tileset = tileset })
  game = require('Game').new({})
  game.onLost = function ()
    state = 'dead'
  end
  local gameFunction, loadingError = loadGame(SAVEFILE_NAME, {
    Quad = function (...)
      return love.graphics.newQuad(...)
    end,
    buf = function (props)
      local compressedData = love.data.decode('data', 'base64', props.base64)
      local data = love.data.decompress('string', 'zlib', compressedData)
      ---@cast data string
      local array = loadstring(data)()
      return array
    end,
  })
  if gameFunction == nil then
    error('loading error: ' .. loadingError)
  end
  game = gameFunction()
end

---@param dt number
function love.update(dt)
  local pv = game.player.pos
  local cv = game.cursorPos
  updateDrawState(
    drawState,
    dt,
    game.isFocused
      and vector.add(cv, { x = 0, y = 0 })
      or vector.midpoint(pv, cv),
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

local function serializeGame()
  local dump = require('Util').dump

  return {[[
    -- This is a Kobold Princess Simulator v0.2 savefile. You shouldn't run it.
    -- It was created at ]],os.date(),[[
    
    return Game{
      time = ]],tostring(game.time),[[,
      score = ]],tostring(game.score),[[,
      deathsCount = ]],tostring(game.deathsCount),[[,
      guys = ]],dump(game.guys),[[,
      magnificationFactor = ]],tostring(game.magnificationFactor),[[,
      world = ]],dump(game.world),[[,
      texts = ]],dump(game.texts),[[,
      entities = ]],dump(game.entities),[[,
      resources = ]],dump(game.resources),[[,
    }
  ]]}
end

---@param key love.KeyConstant
---@param scancode love.Scancode
---@param isrepeat boolean
function love.keypressed(key, scancode, isrepeat)
  if tbl.has({ '1', '2', '3', '4' }, scancode) then
    setWindowScale(drawState, tonumber(scancode) or 1)
  end

  if scancode == '8' then
    -- Write to file
    do
      local file = io.open(SAVEFILE_NAME, 'w+')
      if file == nil then error('no file') end

      for _, line in ipairs(serializeGame(game)) do
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