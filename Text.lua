---@class Text Text object displayed in the world
---@field text string Text content
---@field pos Vector Position in the world
---@field maxWidth number Maximum width of displayed text

---@param content string
---@param pos Vector
---@param maxWidth number
local function makeText(content, pos, maxWidth)
  ---@type Text
  local text = {
    text = content,
    pos = pos,
    maxWidth = maxWidth,
  }
  return text
end

return {
  makeText = makeText,
}