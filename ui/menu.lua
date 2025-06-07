---@module 'lang/ui'

---@class MenuModel
---@field extraText string
---@field afterDraw string

---@type MenuModel
local Model = Model

local INTRO = [[


               KOBOLD--+
               PRINCESS|
               SIMULATOR

                ( o o )
                 " w "

               Chapter I

            " Born of Mud,
             Born of Blood "



             
 N) New World

 L) Load World
                          A game by
 D) KoBolDOS                Engraze

 Q) Quit Game]]

-- From <https://love2d.org/wiki/HSV_color>
local function hsv(h, s, v)
  if s <= 0 then return v,v,v end
  h = h * 6
  local c = v*s
  local x = (1-math.abs((h%2)-1))*c
  local m,r,g,b = (v-c), 0, 0, 0
  if h < 1 then
      r, g, b = c, x, 0
  elseif h < 2 then
      r, g, b = x, c, 0
  elseif h < 3 then
      r, g, b = 0, c, x
  elseif h < 4 then
      r, g, b = 0, x, c
  elseif h < 5 then
      r, g, b = x, 0, c
  else
      r, g, b = c, 0, x
  end
  return { r = r + m, g = g + m, b = b + m, a = 1 }
end

return {
  Panel {
    transform = function () return Origin() end,
    Size('full', 'full'),
    function ()
      return INTRO
        .. (Model.afterDraw and '' or '             Press a key')
        .. ('\n\n ' .. Model.extraText)
    end,
    Background(function()
      return hsv(
        (love.timer.getTime() / 3) % 1,
        0.5,
        0.5
      )
    end),
  },
}
