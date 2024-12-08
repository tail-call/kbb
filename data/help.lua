-- These are used in Commands.lua for help() function
return {
  Global = {
    'Global variables',
    example = 'print(Global)',
  },
  o = {
    'Root game object',
    example = 'o',
  },
  help = {
    'Outputs info about a command in the console',
    '@param name string',
    example = 'help(name)',
  },
  print = {
    'Prints objects to a console',
    '@param ... any[]',
    example = 'print(...)',
  },
  clear = {
    'Clears the screen',
    example = 'clear()',
  },
  scribe = {
    'Scribes a message in the world',
    '@param message string',
    example = 'scribe(message)',
  },
  reload = {
    'Reloads a module',
    '@param moduleName string',
    example = 'reload(moduleName)',
  },
  quit = {
    'Quits to the main menu',
    example = 'quit()',
  },
  noon = {
    'Sets time to 12:00',
    example = 'noon()',
  },
  shr = {
    'Spawns a healing rune under cursor.',
    example = 'shr(restoredHp, rechargeTime)',
  }
}
