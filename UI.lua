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

local function origin()
  return love.math.newTransform()
end

---@param opts UIOptions
---@param children UI[]
---@return UI
local function makeRoot(opts, children)
  return {
    type = 'none',
    transform = function () return origin() end,
    shouldDraw = opts.shouldDraw,
    children = children
  }
end

---@param bak PanelUI
---@return PanelUI
local function makePanel(bak)
  local panel = makeRoot({
    shouldDraw = bak.shouldDraw
  }, {})

  panel.type = 'panel'
  panel.transform = bak.transform
  panel.w = bak[1][2] or function () return 0 end
  panel.h = bak[1][3] or function () return 0 end
  panel.background = bak[3] or { r = 0, g = 0, b = 0, a = 1 }

  if type(bak[2]) == 'string' then
    panel.text = bak[2]
  else
    panel.coloredText = bak[2]
  end

  ---@cast panel PanelUI
  return panel
end

---@param game Game
---@param path string
---@param uiModel UIModel
function M.makeUIScript(game, path, uiModel)
  local index
  index = {
    Panel = makePanel,
    Origin = origin,
    Format = string.format,
    Dump = require('Util').dump,
    formatVector = require('Vector').formatVector,
    SetModel = function (props)
      for k, v in pairs(props) do
        uiModel[k] = v
      end
    end,
    Model = uiModel,
    math = math,
    FPS = love.timer.getFPS,
    Text = function (text)
      return function() return text end
    end,
    Game = function ()
      return game
    end,
    Fixed = function (x)
      return function () return x end
    end,
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
    Size = function (width, height)
      return {
        'size',
        (width == 'full') and index.FullWidth or index.Fixed(width),
        (height == 'full') and index.FullHeight or index.Fixed(height),
      }
    end,
    Background = function (r, g, b, a)
      return {
        'background',
        r = r or 1, g = g or 1, b = b or 1, a = a or 1
      }
    end
  }

  return makeRoot(
    {},
    require('Util')
      .makeLanguage(index)
      .doFile(path)
  )
end

return M