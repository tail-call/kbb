---@alias UIType 'none' | 'panel'
---@class UI
---@field type UIType
---@field x integer
---@field y integer
---@field children UI[]

---@class PanelUI: UI
---@field type 'panel'
---@field w integer
---@field h integer
---@field background { r: number, g: number, b: number, a: number }
---@field text fun(): string
---@field coloredText fun(): table

---@param children UI[]
---@return UI
local function makeRoot(children)
  return {
    x = 0,
    y = 0,
    children = children
  }
end

---@param x number
---@param y number
---@param w number
---@param h number
---@param background { r: number, g: number, b: number, a: number }
---@param textOpt { text: (fun(): string), coloredText: (fun(): table) }
---@return PanelUI
local function makePanel(x, y, w, h, background, textOpt)
  return {
    type = 'panel',
    x = x,
    y = y,
    w = w,
    h = h,
    background = background,
    coloredText = textOpt.coloredText,
    text = textOpt.text,
    children = {},
  }
end

return {
  makeRoot = makeRoot,
  makePanel = makePanel,
}