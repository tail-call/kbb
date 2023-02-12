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

---@param text string
---@param r number
---@param g number
---@param b number
---@return love.ImageData
local function guyToImageData(text, r, g, b)
  local raw = ''
  for i = 1, text:len() do
    if text:byte(i) == 35 then
      raw = raw .. string.char(r, g, b, 255)
    else
      raw = raw .. string.char(0, 0, 0, 0)
    end
  end
  return love.image.newImageData(16, 16, "rgba8", raw)
end

local function load()
  return {
    guy = guyToImageData(guy, 255, 255, 255),
    grass = guyToImageData(grass, 0, 128, 0),
  }
end

return { load = load }