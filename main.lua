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
  love.graphics.setFont(
    require('Util').loadFont(
      require('res/cga8.png'),
      8, 8,
      math.random() > 0.5
    )
  )
  love.graphics.setLineStyle('rough')
  love.mouse.setVisible(false)

  require('Tileset').load()
  require('Scene').loadScene('./scenes/menu.lua', 'initial')
end