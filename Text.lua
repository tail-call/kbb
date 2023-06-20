---@class Text: Object2D Text object displayed in the world
---@field __module 'Text'
---@field text string Text content
---@field maxWidth number Maximum width of displayed text

local M = require('core.class').defineClass{...}

---@param bak Text
function M.init(bak)
  bak.text = bak.text or 'Insert text'
  bak.pos = bak.pos or error('Text: pos is mandatory')
  bak.maxWidth = bak.maxWidth or 32
end

---@param text Text
---@return string
function M.tooltipText(text)
  return ('It says:\n"%s"'):format(text.text)
end

return M