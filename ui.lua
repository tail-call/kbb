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
---@field text string
---@field coloredText table
