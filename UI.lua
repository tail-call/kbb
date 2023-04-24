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

local UIModule = {}

function UIModule.origin()
  return love.math.newTransform()
end

---@param opts UIOptions
---@param children UI[]
---@return UI
function UIModule.new(opts, children)
  return {
    type = 'none',
    transform = function () return UIModule.origin() end,
    shouldDraw = opts.shouldDraw,
    children = children
  }
end

---@param bak PanelUI
---@return PanelUI
function UIModule.makePanel(bak)
  local panel = UIModule.new({
    shouldDraw = bak.shouldDraw
  }, {})
  panel.type = 'panel'
  panel.transform = bak.transform
  panel.w = bak.w or 0
  panel.h = bak.h or 0
  panel.background = bak.background or { 0, 0, 0, 1 }
  panel.coloredText = bak.coloredText
  panel.text = bak.text

  ---@cast panel PanelUI
  return panel
end

return UIModule