local draw = require('./draw')
local game = require('./game')
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
    game:update(dt)
  else

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

  if scancode == 'f' then
    game:toggleFollow()
  end

  if scancode == 'g' then
    game:dismissSquad()
  end

  if scancode == 'space' then
    game:beginRecruiting()
  end

  local vec = vector.dir[scancode]
  if vec then
    game:orderMove(vec)
  end

  if scancode == 'b' then
    game:orderBuild()
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
    game:draw()
  else
    gameover.draw()
  end
end