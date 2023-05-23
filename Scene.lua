---@class Scene: Module
---@field load fun(...) Initializes the scene
---@field draw fun() Draws the scene on the screen
---@field update fun(dt: number) Updates the scene state
---@field keypressed fun(key: love.KeyConstant, scancode: love.Scancode, isRepeat: boolean) Handles key press
---@field mousemoved fun(x: number, y: number, dx: number, dy: number, isTouch: boolean) Handles mouse movement

local M = require('Module').define{...}

local rescuedCallbacks = {}

-- Initialization
do
  -- Rescue default love callbacks
  for _, callbackName in ipairs(require('const').LOVE_CALLBACKS) do
    rescuedCallbacks[callbackName] = love[callbackName] or function () end
  end
end

---Loads a scene for execution
---@param sceneName string
function M.loadScene(sceneName, ...)
  print('Loading ' .. sceneName .. '...')
  local scene = require('Module').reload(sceneName)
  M.setScene(scene, ...)
end

---Switches to a different scene
---@param scene Scene
function M.setScene(scene, ...)
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

return M