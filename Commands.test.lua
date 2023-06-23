local group = require 'core.test'.group
local assert = require 'core.test'.assert
local assertEq = require 'core.test'.assertEq

local Commands = require 'Commands'

group('Commands/new', function ()
  local echoes = {}
  local global = {}
  local root = {}
  local scribben = {}

  local clear = function ()
    echoes = {}
  end

  local scribe = function (text)
    table.insert(scribben, text)
  end

  local env = Commands.new {
    echo = function (...)
      table.insert(echoes, table.concat({ ... }))
    end,
    global = global,
    root = root,
    clear = clear,
    scribe = scribe,
  }

  do -- Check if functions are loaded properly
    assertEq(env.pairs, pairs)
    assertEq(env.ipairs, ipairs)
    assertEq(env.require, require)
    assertEq(env.package, package)
    assertEq(env.o, root)
    assertEq(env.reload, require 'core.class'.reload)
    assertEq(env.scribe, scribe)
    assertEq(env.clear, clear)
  end

  do --Check help commands
    local function testHelp(item, pattern)
      env.help(item)
      local output = table.concat(echoes, '\n')
      local isFound = output:find(pattern, 1, true)
      clear()
      return isFound
    end

    assert(testHelp(nil, 'try these commands'))
    assert(testHelp('random letters', '---Don\'t'))
    assert(testHelp(env.Global, '---Global'))
    assert(testHelp(env.o, '---Root'))
    assert(testHelp(env.help, '---Outputs'))
    assert(testHelp(env.print, '---Prints'))
    assert(testHelp(env.clear, '---Clears'))
    assert(testHelp(env.scribe, '---Scribes'))
    assert(testHelp(env.reload, '---Reloads'))
    assert(testHelp(env.quit, '---Quits'))
  end

end)