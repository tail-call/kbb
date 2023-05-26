---@class Object
---@field __module string

---@class Object2D: Object
---@field pos Vector Object's position in the world

-- Initialization
do
  package.preload['res/map.png'] = love.image.newImageData
  package.preload['res/cga8.png'] = love.image.newImageData
  package.preload['res/tiles.png'] = love.graphics.newImage

  math.randomseed(os.time())
end

function love.load()
  love.graphics.setDefaultFilter('linear', 'nearest')
  love.graphics.setLineStyle('rough')
  love.mouse.setVisible(false)
  require('Draw').nextFont()
  require('Tileset').load()
  require('Scene').loadScene('./scene/menu.lua', 'initial')
end