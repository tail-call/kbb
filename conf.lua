if GlobalOptions then
  GlobalOptions.shouldCrashOnWarnings = false
end

function love.conf(t)
  t.window.title = 'Kobold Princess Simulator'
  t.window.resizable = true
  t.window.width = 320 * 3
  t.window.height = 200 * 3
end