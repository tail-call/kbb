local M = require 'Module'.define(..., 0)

local withColor = require('Util').withColor

---@type GameScene
local storedScene = nil

---@param scene GameScene
function M.load(scene)
  storedScene = scene
end

---@param key love.KeyConstant
---@param scancode love.Scancode
---@param isrepeat boolean
function M.keypressed(key, scancode, isrepeat)
  require('main').setScene(storedScene, '#back')
end

function M.draw()
  if storedScene ~= nil then
    storedScene.draw()
  end
  withColor(0, 0, 0, 0.8, function ()
    local w, h = love.window.getMode()
    love.graphics.rectangle('fill', 0, 0, w, h)
  end)
  love.graphics.origin()
  love.graphics.print(tostring(storedScene), 10, 10)
  love.graphics.print('press X to X-it', 10, 20)
  love.graphics.print(require('Util').dump(storedScene), 10, 30)
end

return M