-- Need to do this before anything else is executed
math.randomseed(os.time())

local draw = require('./draw')
local game = require('./game').game
local orderMove = require('./game').orderMove
local drawGame = require('./draw').drawGame
local handleInput = require('./game').handleInput
local switchMagn = require('./game').switchMagn
local updateGame = require('./game').updateGame
local toggleFollow = require('./game').toggleFollow
local dismissSquad = require('./game').dismissSquad
local orderChop = require('./game').orderChop
local orderFocus = require('./game').orderFocus
local beginRecruiting = require('./game').beginRecruiting
local endRecruiting = require('./game').endRecruiting
local tbl = require('./tbl')
local vector = require('./vector')
local gameover = require('./gameover')

---@type 'game' | 'dead'
local state = 'game'

function love.load()
  draw.init()
  game:init()
  game.onLost = function ()
    state = 'dead'
  end
end

local alternatingKeyIndex = 0

---@param dt number
function love.update(dt)
  draw.update(
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

    if game:isReadyForOrder() and #directions > 0 then
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
    draw.setZoom(tonumber(scancode))
  end

  if scancode == 'z' then
    switchMagn()
  end

  if game.isFocused then
    handleInput(game, scancode)
  else
    if scancode == 'f' then
      toggleFollow(game)
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
  draw.prepareFrame()
  drawGame(game)
  if state == 'dead' then
    gameover.draw()
  end
end