---@class UI
---@field type 'none' | 'panel'
---@field transform (fun(drawState: DrawState): love.Transform)
---@field shouldDraw (fun(): boolean) | nil
---@field children UI[]

---@class PanelUI: UI
---@field type 'panel'
---@field w fun(drawState: DrawState): integer
---@field h fun(drawState: DrawState): integer
---@field background { r: number, g: number, b: number, a: number }
---@field text fun(): string
---@field coloredText fun(): table

---@class UIOptions
---@field shouldDraw (fun(): boolean) | nil

local M = {}

function M.origin()
  return love.math.newTransform()
end

---@param opts UIOptions
---@param children UI[]
---@return UI
function M.new(opts, children)
  return {
    type = 'none',
    transform = function () return M.origin() end,
    shouldDraw = opts.shouldDraw,
    children = children
  }
end

---@param bak PanelUI
---@return PanelUI
function M.makePanel(bak)
  local panel = M.new({
    shouldDraw = bak.shouldDraw
  }, {})
  panel.type = 'panel'
  panel.transform = bak.transform
  panel.w = bak.w or 0
  panel.h = bak.h or 0
  panel.background = bak.background or { 0, 0, 0, 1 }
  if type(bak[1]) == 'string' then
    panel.text = bak[1]
  else
    panel.coloredText = bak[1]
  end

  ---@cast panel PanelUI
  return panel
end

---@param game Game
function M.makeUIScript(game)
  return require('Util').doFileWithIndex('./screen.ui.lua', {
    UI = function (children)
      return M.new({}, children)
    end,
    Panel = M.makePanel,
    Origin = M.origin,
    Format = string.format,
    Dump = require('Util').dump,
    formatVector = require('Vector').formatVector,
    Console = require('Console').new,
    RGBA = function (r, g, b, a)
      return {
        r = r or 1, g = g or 1, b = b or 1, a = a or 1
      }
    end,
    SetModel = function (props)
      for k, v in pairs(props) do
        game.uiModel[k] = v
      end
    end,
    Model = game.uiModel,
    ---@param drawState DrawState
    FullHeight = function (drawState)
      local _, sh = love.window.getMode()
      return sh / drawState.windowScale
    end,
    ---@param drawState DrawState
    FullWidth = function (drawState)
      local sw, _ = love.window.getMode()
      return sw / drawState.windowScale
    end,
    Fixed = function (x)
      return function () return x end
    end,
    math = math,
    FPS = love.timer.getFPS,
    Text = function (text)
      return function() return text end
    end
  })()
end

return M