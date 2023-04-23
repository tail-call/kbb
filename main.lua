-- Need to do this before anything else is executed
math.randomseed(os.time())

-- Mock he table module
table.new = function () return {} end

local draw = require('Draw')
local makeGame = require('Game').new
local drawGame = require('Draw').drawGame
local handleInput = require('Game').handleInput
local updateGame = require('Game').updateGame
local beginRecruiting = require('Game').beginRecruiting
local endRecruiting = require('Game').endRecruiting
local tbl = require('tbl')
local vector = require('Vector')
local gameover = require('GameOver')
local loadTileset = require('Tileset').load
local loadFont = require('Util').loadFont
local orderLoad = require('Game').orderLoad

---@type 'game' | 'dead'
local state = 'game'
---@type Game
local game

---@type DrawState
local drawState

function love.load()
  love.graphics.setDefaultFilter('linear', 'nearest')
  love.graphics.setFont(loadFont('cga8.png', 8, 8, math.random() > 0.5))
  love.graphics.setLineStyle('rough')
  loadTileset()
  local tileset = require('Tileset').getTileset()
  drawState = require('DrawState').new(tileset)
  game = makeGame()
  game.onLost = function ()
    state = 'dead'
  end
  orderLoad(game)
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


---@param key love.KeyConstant
---@param scancode love.Scancode
---@param isrepeat boolean
function love.keypressed(key, scancode, isrepeat)
  if tbl.has({ '1', '2', '3', '4' }, scancode) then
    draw.setZoom(drawState, tonumber(scancode) or 1)
  end


  if scancode == 'return' then
    local lines = {}
    local function addLines(t)
      for _, v in ipairs(t) do
        if type(v) == 'string' then
          table.insert(lines, v)
        elseif type(v) == 'table' then
          addLines(v)
        end
      end
    end
    addLines(game:serialize1())
    local script = table.concat(lines)
    print(script)

    local saveGameFunction, compileError = loadstring(script)
    if compileError then
      error(compileError)
    end

    local moduleLoader = {}
    setmetatable(moduleLoader, { __index = function(t, k)
      return function(props)
        if k == 'Quad' then
          return love.graphics.newQuad
        else
          print('Loading from module '..k)
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

  if state ~= 'game' then return end

  handleInput(game, scancode, drawState.tileset)
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
  draw.prepareFrame(drawState)
  drawGame(game, drawState)
  if state == 'dead' then
    gameover.draw()
  end
end