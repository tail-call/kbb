local loadTileset = require('Tileset').load
local loadFont = require('Util').loadFont

local function imageLoader(filename)
  local imageData = love.image.newImageData(filename)
  return imageData
end

local function imageDataLoader(filename)
  return love.graphics.newImage(filename)
end

local function loadScene (scene)
  for k, v in pairs(scene) do
    love[k] = v
  end
  scene.load()
end

function love.load()
  package.preload['res/map.png'] = imageLoader
  package.preload['res/cga8.png'] = imageLoader
  package.preload['res/tiles.png'] = imageDataLoader

  -- Need to do this before anything else is executed
  math.randomseed(os.time())

  love.graphics.setDefaultFilter('linear', 'nearest')
  love.graphics.setFont(loadFont(require('res/cga8.png'), 8, 8, math.random() > 0.5))
  love.graphics.setLineStyle('rough')
  love.mouse.setVisible(false)
  loadTileset()
  loadScene(require('GameScene'))
end