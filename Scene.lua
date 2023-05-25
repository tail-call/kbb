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
---@param path string
function M.loadScene(path, ...)
  local scene = {}
  local index = {
    OnLoad = function (load)
      scene.load = load
    end,
    OnUpdate = function (load)
      scene.update = load
    end,
    OnDraw = function (load)
      scene.draw = load
    end,
    OnKeyPressed = function (load)
      scene.keypressed = load
    end,
    OnMousePressed = function (load)
      scene.mousepressed = load
    end,
    OnMouseReleased = function (load)
      scene.mousereleased = load
    end,
    DrawUI = function (ui)
      require('Draw').drawUI(require('DrawState').new(), ui)
    end,
    UI = function (uiPath, model)
      return require('UI').makeUIScript({}, uiPath, model)
    end,
    Transition = function (path, ...)
      M.loadScene(path, ...)
    end
  }
  setmetatable(index, { __index = _G })
  require('Util').doFileWithIndex(path, index)()
  M.setScene(scene, ...)
end

---Switches to a different scene
---@param scene Scene
function M.setScene(scene, ...)
  for _, callbackName in ipairs(require('const').LOVE_CALLBACKS) do
    love[callbackName] = scene[callbackName]
      or rescuedCallbacks[callbackName]
      or error('main: no such callback: ' .. callbackName)
  end
  if scene.load ~= nil then
    scene.load(...)
  end
end

return M