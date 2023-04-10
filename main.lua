-- Need to do this before anything else is executed
math.randomseed(os.time())

local draw = require('./draw')
local game = require('./game').game
local drawGame = require('./draw').drawGame
local switchMagn = require('./game').switchMagn
local updateGame = require('./game').updateGame
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

---@param dt number
function love.update(dt)
  draw.update(dt)
  if state == 'game' then
    updateGame(game, dt)

    for key, value in pairs(vector.dir) do
      if love.keyboard.isDown(key) then
        game:orderMove(value)
      end
    end
  end
end

---@param key love.KeyConstant
---@param scancode love.Scancode
---@param isrepeat boolean
function love.keypressed(key, scancode, isrepeat)
  if state ~= 'game' then return end

  if scancode == 'z' then
    switchMagn()
  end

  if tbl.has({ '1', '2', '3', '4' }, scancode) then
    draw.setZoom(tonumber(scancode))
  end

  if game.isFocused then
    if scancode == 'b' then
      game:orderBuild()
    end
    if scancode == 's' then
      game:orderScribe()
    end
  else
    if scancode == 'f' then
      game:toggleFollow()
    end

    if scancode == 'g' then
      game:dismissSquad()
    end

    if scancode == 'c' then
      game:orderChop()
    end

    if scancode == 'space' then
      game:beginRecruiting()
    end
  end
end

function love.mousepressed(x, y, button, presses)
  if button == 1 then
    game:orderFocus()
  end
end

---@param key love.KeyConstant
---@param scancode love.Scancode
function love.keyreleased(key, scancode)
  if state ~= 'game' then return end

  if scancode == 'space' then
    game:endRecruiting()
  end
end

function love.draw()
  draw.prepareFrame()
  if state == 'game' then
    drawGame(game)
  else
    gameover.draw()
  end
end