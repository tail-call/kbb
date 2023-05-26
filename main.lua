---@class Object
---@field __module string

---@class Object2D: Object
---@field pos Vector Object's position in the world

local function uiLoader(path)
  return function (game, model)
    return require('UI').makeUIScript(game, path, model)
  end
end

-- Initialization
do
  package.preload['res/map.png'] = love.image.newImageData
  package.preload['res/cga8.png'] = love.image.newImageData
  package.preload['res/tiles.png'] = love.graphics.newImage
  package.preload['ui/screen'] = uiLoader
  package.preload['ui/menu'] = uiLoader

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