#!/usr/bin/env luajit

local commandName = ...

local printf = function (fmt, ...)
  return print(string.format(fmt, ...))
end

if commandName == 'game' then
  os.execute('/Applications/love.app/Contents/MacOS/love .')
elseif commandName == 'test' then
  require 'core.test'.runTests()
else
  printf('Kobold Princess Simulator Launch Utility')
  printf('')
  printf('Usage:')
  printf('  %s game - run game', arg[0])
  printf('  %s test - run tests', arg[0])
  os.exit(1)
end