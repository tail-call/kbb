local draw = require('./draw')

local gameover = {}

function gameover.draw()
  draw.withColor(1, 0, 0, 1, function ()
    love.graphics.print('Wow! You lose.', 110, 80)
  end)
end

return gameover