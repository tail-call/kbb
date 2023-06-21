-- If `Global` table exists, then `conf.lua` was called for configuration
if Global then
  Global.shouldCrashOnWarnings = false
  if true then
    Global.initialScene = 'scene.menu'
  else
    Global.initialScene = 'scene.terminal'
  end
end

function love.conf(t)
  t.window.title = 'Kobold Princess Simulator'
  t.window.resizable = true
  t.window.width = 320 * 3
  t.window.height = 200 * 3
end