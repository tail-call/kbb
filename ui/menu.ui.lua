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
    Background(0.2, 0.3, 0.1, 1),
  },
}