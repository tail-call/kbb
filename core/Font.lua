-- See <https://love2d.org/wiki/ImageFontFormat>
---@param data love.ImageData
---@param charWidth integer
---@param charHeight integer
---@param isBold boolean
---@return love.Font
local function load(data, charWidth, charHeight, isBold)
  local characters = ' !"#$%&\'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~'
  local fontWidth = 1 + #characters * (charWidth + 1)
  local output = love.image.newImageData(fontWidth, charHeight)

  local function putSeparator(x)
    for y = 0, charHeight - 1 do
      output:setPixel(x, y, 1, 0, 1, 1)
    end
  end

  local base = (isBold and 256 or 0) + 32 -- base 0 + 32 for non-bold font
  local offset = 0
  for char = base, base + #characters do
    putSeparator(offset)
    local y = math.floor(char / 32)
    local x = char % 32

    output:paste(
      data, -- Source
      offset + 1, -- dx
      0, -- dy
      charWidth * x, -- sx
      charHeight * y, -- sy
      charWidth, -- sw
      charHeight -- sh
    )

    offset = offset + charWidth + 1
  end

  putSeparator(fontWidth - 1)

  return love.graphics.newImageFont(output, characters)
end

return {
  load = load
}