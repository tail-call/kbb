---@class Object
---@field __module string

---@class Object2D: Object
---@field pos Vector

local M = require('Module').define(..., 0)

local rescuedCallbacks = {}

-- Rescue default love callbacks

for _, callbackName in ipairs(require('const').LOVE_CALLBACKS) do
  rescuedCallbacks[callbackName] = love[callbackName] or function () end
end

---Loads a scene for execution
---@param sceneName string
function M.loadScene (sceneName, ...)
  print('Loading ' .. sceneName .. '...')
  local scene = require('Module').reload(sceneName)
  M.setScene(scene, ...)
end

---Switches to a different scene
---@param scene table
function M.setScene (scene, ...)
  print('Redefining callbacks for '..scene.__modulename .. '...')
  for _, callbackName in ipairs(require('const').LOVE_CALLBACKS) do
    love[callbackName] = scene[callbackName]
      or rescuedCallbacks[callbackName]
      or error('main: no such callback: ' .. callbackName)
  end
  if scene.load ~= nil then
    print('Initializing '..scene.__modulename .. '...')
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
  end

  loadTileset()
  M.loadScene('MenuScene', 'initial')
end

return M