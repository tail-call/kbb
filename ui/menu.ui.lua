---@module 'lang/ui'

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

local function text()
  return INTRO
    .. (Model['extraText'])
    .. (Model['afterDraw'] and '' or '\nPress a key')
    .. (Model['cursorTimer'] > 0.5 and '_' or '')
end

return UI {
  Panel {
    background = RGBA(0.2, 0.3, 0.1, 1),
    transform = function () return Origin() end,
    w = FullWidth,
    h = FullHeight,
    text
  },
}