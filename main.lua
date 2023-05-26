---@class Object
---@field __module string

---@class Object2D: Object
---@field pos Vector Object's position in the world

local function uiLoader(path)
  return function (game, model)
    return require('UI').makeUIScript(game, path, model)
  end
end

local function sceneLoader(path)
  return {
    go = function (...)
      return require('Scene').loadScene(path, ...)
    end
  }
end

-- Initialization
do
  package.preload['res/map.png'] = love.image.newImageData
  package.preload['res/cga8.png'] = love.image.newImageData
  package.preload['res/tiles.png'] = love.graphics.newImage
  package.preload['ui/screen.lua'] = uiLoader
  package.preload['ui/menu.lua'] = uiLoader
  package.preload['scene/menu.lua'] = sceneLoader
  package.preload['scene/game.lua'] = sceneLoader
  package.preload['scene/console.lua'] = sceneLoader

  math.randomseed(os.time())
end

function love.load()
  love.graphics.setDefaultFilter('linear', 'nearest')
  love.graphics.setLineStyle('rough')
  love.mouse.setVisible(false)
  require('Draw').nextFont()
  require('Tileset').load()
  require('scene/menu.lua').go('initial')
end