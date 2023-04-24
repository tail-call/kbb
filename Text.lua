---@class Text Text object displayed in the world
---@field text string Text content
---@field pos Vector Position in the world
---@field maxWidth number Maximum width of displayed text

---@param bak Text
local function new(bak)
  bak = bak or {}

  ---@type Text
  local text = {
    __module = 'Text',
    text = bak.text or 'Insert text',
    pos = bak.pos or error('Text: pos is mandatory'),
    maxWidth = bak.maxWidth or 32,
  }
  return text
end

return {
  new = new,
}