local M = require('Module').define(..., 0)

local INTRO = [[
Welcome to KOBOLD PRINCESS SIMULATOR

N) Start new game
L) Load game from disk (file kobo2.kpss)
X) Exit game

Press a key]]

local cursorTimer = 0

function M.update(dt)
  cursorTimer = cursorTimer + 4 * dt
  if cursorTimer > 1 then
    cursorTimer = 0
  end
end

function M.draw()
  love.graphics.scale(3, 3)
  love.graphics.print(INTRO .. (cursorTimer > 0.5 and '_' or ''), 0, 0)
end

---@param key love.KeyConstant
---@param scancode love.Scancode
---@param isrepeat boolean
function M.keypressed(key, scancode, isrepeat)
  if scancode == 'l' then
    error('Load not implemented')
  elseif scancode == 'n' then
    error('New game not implemented')
  elseif scancode == 'x' then
    error('Exit not implemented')
  end
end

return M