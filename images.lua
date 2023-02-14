---@alias ImageLibrary { guy: love.Image, grass: love.Image, rock: love.Image }

local guy = ''
  .. '                '
  .. '                '
  .. '  ##        ##  '
  .. ' ##   ###    ## '
  .. ' ##  #####   ## '
  .. ' ###   ###  ### '
  .. '  ############  '
  .. '     ######     '
  .. '      ####      '
  .. '      ####      '
  .. '     ######     '
  .. '     ######     '
  .. '    ## ## ## #  '
  .. '    ##  # ## ## '
  .. '    ##    ##    '
  .. '   ###    ###   '

local grass = ''
  .. '     #          '
  .. '           #    '
  .. ' #              '
  .. '                '
  .. '   #            '
  .. '             #  '
  .. '                '
  .. '                '
  .. '     #          '
  .. '             #  '
  .. '       #        '
  .. '                '
  .. '                '
  .. '               #'
  .. '   #            '
  .. '                '

local rock = ''
  .. '   #     #      '
  .. '# # #   # #   # '
  .. ' #   # #   # # #'
  .. '   #     #      '
  .. '# # #   # #   # '
  .. ' #   # #   # # #'
  .. '   #     #      '
  .. '# # #   # #   # '
  .. ' #   # #   # # #'
  .. '   #     #      '
  .. '# # #   # #   # '
  .. ' #   # #   # # #'
  .. '   #     #      '
  .. '# # #   # #   # '
  .. ' #   # #   # # #'
  .. '################'

---@param text string
---@param r number
---@param g number
---@param b number
---@return love.Image
local function guyToImage(text, r, g, b)
  local raw = ''
  for i = 1, text:len() do
    if text:byte(i) == 35 then
      raw = raw .. string.char(r, g, b, 255)
    else
      raw = raw .. string.char(0, 0, 0, 0)
    end
  end
  return love.graphics.newImage(
    love.image.newImageData(16, 16, "rgba8", raw)
  )
end

---@return ImageLibrary
local function load()
  return {
    guy = guyToImage(guy, 255, 255, 255),
    grass = guyToImage(grass, 0, 128, 0),
    rock = guyToImage(rock, 128, 128, 128),
  }
end

return { load = load }