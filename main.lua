-- Need to do this before anything else is executed
math.randomseed(os.time())

local draw = require('Draw')
local makeGame = require('Game').makeGame
local drawGame = require('Draw').drawGame
local handleInput = require('Game').handleInput
local updateGame = require('Game').updateGame
local beginRecruiting = require('Game').beginRecruiting
local endRecruiting = require('Game').endRecruiting
local tbl = require('tbl')
local vector = require('Vector')
local gameover = require('GameOver')
local makeDrawState = require('DrawState').makeDrawState
local loadTileset = require('Tileset').load
local loadFont = require('util').loadFont
local getTileset = require('Tileset').getTileset

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
  local tileset = getTileset()
  drawState = makeDrawState(tileset)
  draw.init(drawState)
  game = makeGame(tileset)
  game.onLost = function ()
    state = 'dead'
  end
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