---Global variables. `Global.lua` defines default values, `conf.lua`
---contains actual configuration.
Global = {
  ---If true, warning functions from `core.log` module will crash the program
  shouldCrashOnWarnings = false,
  ---If true, warnings will be printed to the console
  shouldLogWarnings = true,
  ---Module to be required and used as a starting scene
  initialScene = '<not a scene>',
  ---Default scale of the graphics
  defaultGraphicsScale = 2,
  ---Where to spawn the leader at when she dies
  leaderSpawnLocation = { x = 250, y = 250 },
}
