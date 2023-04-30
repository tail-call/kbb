local M = require('Module').define(..., 0)

local rescuedCallbacks = {}

---Loads a scene for execution
---@param scene table
function M.loadScene (scene, ...)
  for _, callbackName in ipairs(require('const').LOVE_CALLBACKS) do
    love[callbackName] = scene[callbackName]
      or rescuedCallbacks[callbackName]
      or error('main: no such callback: ' .. callbackName)
  end
  if scene.load ~= nil then
    scene.load(...)
  end
end


local loadTileset = require('Tileset').load
local loadFont = require('Util').loadFont

local function imageLoader(filename)
  local imageData = love.image.newImageData(filename)
  return imageData
end

local function imageDataLoader(filename)
  return love.graphics.newImage(filename)
end

local function rescueLoveDefaultCallbacks()
  for _, callbackName in ipairs(require('const').LOVE_CALLBACKS) do
    rescuedCallbacks[callbackName] = love[callbackName] or function () end
  end
end

function love.load()
  -- Need to do this before anything else is executed
  do
    package.preload['res/map.png'] = imageLoader
    package.preload['res/cga8.png'] = imageLoader
    package.preload['res/tiles.png'] = imageDataLoader

    love.graphics.setDefaultFilter('linear', 'nearest')
    love.graphics.setFont(loadFont(require('res/cga8.png'), 8, 8, math.random() > 0.5))
    love.graphics.setLineStyle('rough')
    love.mouse.setVisible(false)

    math.randomseed(os.time())
    rescueLoveDefaultCallbacks()
  end

  loadTileset()
  M.loadScene(require('MenuScene'), 'initial')
end

return M