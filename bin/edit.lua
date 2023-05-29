local filename = ...

local function readLines()
  local lines = {}

  local file = io.open(filename)

  if not file then
    error('edit: can\'t open file: ' .. filename)
  end

  for line in file:lines() do
    table.insert(lines, line)
  end

  io.close(file)

  return lines
end

local editor = {
  lines = readLines(),
}

do
  Sys.screen:clear()
  Sys.screen:setShouldScroll(false)
  Sys.screen.cursor:goHome()
  for i = 1, Sys.screen.screenSize.tall do
    print(editor.lines[i])
  end
  Sys.screen.cursor:goHome()
  while true do
    local key = Sys.getKey()
    if key == 'l' then
      Sys.screen.cursor:advance(function ()
        error('oh no')
      end)
    elseif key == 'h' then
      Sys.screen.cursor:locate {
        x = Sys.screen.cursor.pos.x - 1,
        y = Sys.screen.cursor.pos.y,
      }
    elseif key == 'k' then
      Sys.screen.cursor:locate {
        x = Sys.screen.cursor.pos.x,
        y = Sys.screen.cursor.pos.y - 1,
      }
    elseif key == 'j' then
      Sys.screen.cursor:locate {
        x = Sys.screen.cursor.pos.x,
        y = Sys.screen.cursor.pos.y + 1,
      }
    end
  end
  print('done')
  Sys.screen.cursor:goHome()
end