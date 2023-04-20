---@alias UIType 'none' | 'panel'

---@class UI
---@field type UIType
---@field transform love.Transform
---@field shouldDraw (fun(): boolean) | nil
---@field children UI[]

---@class PanelUI: UI
---@field type 'panel'
---@field w integer
---@field h integer
---@field background { r: number, g: number, b: number, a: number }
---@field text fun(): string
---@field coloredText fun(): table

---@class UIOptions
---@field shouldDraw (fun(): boolean) | nil

local function origin()
  return love.math.newTransform()
end

---@param opts UIOptions
---@param children UI[]
---@return UI
local function makeRoot(opts, children)
  return {
    type = 'none',
    transform = origin(),
    shouldDraw = opts.shouldDraw,
    children = children
  }
end

---@param transform love.Transform
---@param w number
---@param h number
---@param background { r: number, g: number, b: number, a: number }
---@param textOpt { text: (fun(): string), coloredText: (fun(): table), shouldDraw: (fun(): boolean) }
---@return PanelUI
local function makePanel(transform, w, h, background, textOpt)
  return {
    type = 'panel',
    transform = transform,
    w = w,
    h = h,
    background = background,
    coloredText = textOpt.coloredText,
    text = textOpt.text,
    shouldDraw = textOpt.shouldDraw,
    children = {},
  }
end

return {
  origin = origin,
  makeRoot = makeRoot,
  makePanel = makePanel,
}