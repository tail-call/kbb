---@module 'lang/ui'

---@class MenuModel
---@field extraText string
---@field afterDraw string
---@field cursorTimer number

---@type MenuModel
local Model = Model

local INTRO = [[
Welcome to KOBOLD PRINCESS SIMULATOR

+In-game controls:---------------------+
|W, A, S, D) move                 o o  |
|H, J, K, L) also move             w   |
|Arrow keys) also move                 |
|Space)      switch mode               |
|Return)     open lua console          |
|            (try typing 'help()')     |
|Escape)     close lua console         |
|N)          reload main guy           |
|E)          terramorphing             |
+--------------------------------------+

Now choose:

N) Play in empty world
L) Load world from disk (kobo2.kpss)
F) Reload this menu
Q) Quit game
]]

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
        .. (Model.extraText)
        .. (Model.afterDraw and '' or '\nPress a key')
        .. (Model.cursorTimer > 0.5 and '_' or '')
    end,
    Background(function()
      return hsv(
        (love.timer.getTime() / 4) % 1,
        0.5,
        0.5
      )
    end),
  },
}