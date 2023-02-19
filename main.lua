local draw = require('./draw')
local game = require('./game')
local tbl = require('./tbl')
local vector = require('./vector')

function love.load()
  draw.init()
  game:init()
end

---@param dt number
function love.update(dt)
  draw.update(dt)
  game:update(dt)
end

---@param key love.KeyConstant
---@param scancode love.Scancode
---@param isrepeat boolean
function love.keypressed(key, scancode, isrepeat)
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
end

---@param key love.KeyConstant
---@param scancode love.Scancode
function love.keyreleased(key, scancode)
  if scancode == 'space' then
    game:endRecruiting()
  end
end

function love.draw()
  game:draw()
end