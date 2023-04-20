-- Need to do this before anything else is executed
math.randomseed(os.time())

local draw = require('Draw')
local makeGame = require('Game').makeGame
local orderMove = require('Game').orderMove
local drawGame = require('Draw').drawGame
local handleInput = require('Game').handleInput
local updateGame = require('Game').updateGame
local dismissSquad = require('Game').dismissSquad
local orderChop = require('Game').orderChop
local orderFocus = require('Game').orderFocus
local beginRecruiting = require('Game').beginRecruiting
local endRecruiting = require('Game').endRecruiting
local isReadyForOrder = require('Game').isReadyForOrder
local tbl = require('tbl')
local vector = require('Vector')
local gameover = require('GameOver')
local makeDrawState = require('DrawState').makeDrawState

---@type 'game' | 'dead'
local state = 'game'
---@type Game
local game

---@type DrawState
local drawState

function love.load()
  drawState = makeDrawState()
  draw.init(drawState)
  game = makeGame()
  game.onLost = function ()
    state = 'dead'
  end
end

local alternatingKeyIndex = 0

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

    if isReadyForOrder(game) and #directions > 0 then
      for _ = 1, #directions do
        alternatingKeyIndex = (alternatingKeyIndex + 1) % (#directions)
        if orderMove(
          game, directions[alternatingKeyIndex + 1]
        ) == 'shouldStop' then
          break
        end
      end
    end

    updateGame(game, dt)
  end
end

---@param key love.KeyConstant
---@param scancode love.Scancode
---@param isrepeat boolean
function love.keypressed(key, scancode, isrepeat)
  if state ~= 'game' then return end

  if tbl.has({ '1', '2', '3', '4' }, scancode) then
    draw.setZoom(drawState, tonumber(scancode) or 1)
  end

  if scancode == 'z' then
    game:nextMagnificationFactor()
  end

  if game.isFocused then
    handleInput(game, scancode)
  else
    if scancode == 'f' then
      game.squad:toggleFollow()
    end

    if scancode == 'g' then
      dismissSquad(game)
    end

    if scancode == 'c' then
      orderChop(game)
    end

    if scancode == 'space' then
      orderFocus(game)
    end
  end
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