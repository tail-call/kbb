-- Need to do this before anything else is executed
math.randomseed(os.time())

local loadTileset = require('Tileset').load
local loadFont = require('Util').loadFont

package.preload['res/map.png'] = function (filename)
  local imageData = love.image.newImageData(filename)
  return imageData
end

package.preload['res/cga8.png'] = package.preload['res/map.png']

package.preload['res/tiles.png'] = function (filename)
  return love.graphics.newImage(filename)
end

function love.load()
  love.graphics.setDefaultFilter('linear', 'nearest')
  love.graphics.setFont(loadFont(require('res/cga8.png'), 8, 8, math.random() > 0.5))
  love.graphics.setLineStyle('rough')
  love.mouse.setVisible(false)
  loadTileset()
  require('GameScene').load()
end

function love.update(...)
  require('GameScene').update(...)
end

function love.textinput(...)
  require('GameScene').textinput(...)
end

function love.keypressed(...)
  require('GameScene').keypressed(...)
end

function love.mousereleased(...)
  require('GameScene').mousereleased(...)
end

function love.draw()
  require('GameScene').draw()
end