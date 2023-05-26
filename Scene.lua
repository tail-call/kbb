---@class Scene: Module
---@field load fun(...) Initializes the scene
---@field draw fun() Draws the scene on the screen
---@field update fun(dt: number) Updates the scene state
---@field keypressed fun(key: love.KeyConstant, scancode: love.Scancode, isRepeat: boolean) Handles key press
---@field mousemoved fun(x: number, y: number, dx: number, dy: number, isTouch: boolean) Handles mouse movement

local M = require('Module').define{...}

local drawState = require('DrawState').new()
local rescuedCallbacks = {}
local previousScene = nil

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
  local prev = previousScene
  local scene = { path = path }
  local index = {
    DrawState = drawState,
    OnLoad = function (load)
      scene.load = load
    end,
    OnUpdate = function (update)
      scene.update = function (dt)
        update(dt, drawState)
      end
    end,
    OnDraw = function (draw)
      scene.draw = function ()
        draw(drawState)
      end
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
    OnTextInput = function (load)
      scene.textinput = load
    end,
    DrawUI = function (ui)
      require('Draw').drawUI(require('DrawState').new(), ui)
    end,
    UI = function (uiPath, model)
      return require('UI').makeUIScript({}, uiPath, model)
    end,
    Transition = function (path, ...)
      M.loadScene(path, ...)
    end,
    Self = scene,
    GoBack = function (...)
      require('Scene').setScene(prev, ...)
    end,
  }
  require('Util').makeLanguage(index).doFile(path)
  M.setScene(scene, ...)
end

---Switches to a different scene
---@param scene Scene
function M.setScene(scene, ...)
  previousScene = scene
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