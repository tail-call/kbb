---@class UI
---@field type 'none' | 'panel'
---@field transform (fun(drawState: DrawState): love.Transform)
---@field shouldDraw (fun(): boolean) | nil
---@field children UI[]

---@class UIColor
---@field r number
---@field g number
---@field b number
---@field a number
---@field fun fun(): UIColor

---@class PanelUI: UI
---@field type 'panel'
---@field w fun(drawState: DrawState): integer
---@field h fun(drawState: DrawState): integer
---@field background UIColor
---@field text fun(): string
---@field coloredText fun(): table

---@class UIOptions
---@field shouldDraw (fun(): boolean) | nil

local TypeCase = require 'core.flow'.TypeCase

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
  panel.background = { r = 0, g = 0, b = 0, a = 1 }
  TypeCase(bak[3].fun) {
    'function', function ()
      panel.background = bak[3].fun
    end,
    nil, function ()
      panel.background = bak[3]
    end,
  }

  TypeCase(bak[2]) {
    'string', function ()
      panel.text = bak[2]
    end,
    nil, function ()
      panel.coloredText = bak[2]
    end,
  }

  ---@cast panel PanelUI
  return panel
end

---@param path string
---@param uiModel UIModel
function M.makeUIScript(path, uiModel)
  local index
  index = {
    Panel = makePanel,
    Origin = origin,
    SetModel = function (props)
      for k, v in pairs(props) do
        uiModel[k] = v
      end
    end,
    Model = uiModel,
    Text = function (text)
      return function() return text end
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
      if type(r) == 'function' then
        return { 'background', fun = r }
      else
        return {
          'background',
          r = r or 1, g = g or 1, b = b or 1, a = a or 1
        }
      end
    end
  }

  return makeRoot(
    {},
    require 'core.Dump'
      .makeLanguage(index)
      .doFile(path)
  )
end

return M