local withColor = require('util').withColor

local gameover = {}

function gameover.draw()
  withColor(0, 0, 0, 1, function ()
    local msg = 'Wow! You lose.'
    love.graphics.rectangle('fill', 110, 80, msg:len() * 8, 8)
    love.graphics.setColor(1, 0, 0, 1)
    love.graphics.print(msg, 110, 80)
  end)
end

return gameover