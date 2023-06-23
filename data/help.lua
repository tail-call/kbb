-- These are used in Commands.lua for help() function
return {
  Global = {
    'print(Global)',
    'Global variables'
  },
  o = {
    'o',
    'Root game object'
  },
  help = {
    'help(name)',
    'Outputs info about a command in the console',
    '@param name string'
  },
  print = {
    'print(...)',
    'Prints objects to a console',
    '@param ... any[]'
  },
  clear = {
    'clear()',
    'Clears the screen'
  },
  scribe = {
    'scribe(message)',
    'Scribes a message in the world',
    '@param message string'
  },
  reload = {
    'reload(moduleName)',
    'Reloads a module',
    '@param moduleName string'
  },
  quit = {
    'quit()',
    'Quits to the main menu'
  },
}
