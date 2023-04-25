---@class Text Text object displayed in the world
---@field text string Text content
---@field pos Vector Position in the world
---@field maxWidth number Maximum width of displayed text

local M = require('Module').define(..., 0)

---@param bak Text
function M.init(bak)
  bak.text = bak.text or 'Insert text'
  bak.pos = bak.pos or error('Text: pos is mandatory')
  bak.maxWidth = bak.maxWidth or 32
end

return M