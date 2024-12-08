local group = require 'core.test'.group
local assert = require 'core.test'.assert
local assertEq = require 'core.test'.assertEq

local Commands = require 'Commands'

group('Commands/new', function ()
  local echoes = {}
  local global = {}
  local root = {}
  local scribben = {}
  local helpTable = {
    o = {
      'test test',
      example = 'o',
    },
    scribe = {
      'scribes a message',
      '@param msg string',
      example = 'scribe(msg)',
    }
  }

  local currentTime = 0
  local currentTimeExpected = 1200

  local clear = function ()
    echoes = {}
  end

  local scribe = function (text)
    table.insert(scribben, text)
  end

  local function noon ()
    currentTime = currentTimeExpected
  end

  local function spawnHealingRune ()
    currentTime = currentTimeExpected
  end

  local env = Commands.new {
    echo = function (...)
      table.insert(echoes, table.concat({ ... }))
    end,
    helpTable = helpTable,
    global = global,
    root = root,
    clear = clear,
    scribe = scribe,
    noon = noon,
    spawnHealingRune = spawnHealingRune,
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
    local function testHelp(item, sample, test)
      if not test then
        test = function (a, b)
          return a == b
        end
      end
      env.help(item)
      local output = table.concat(echoes, '\n')
      clear()
      return test(output, sample)
    end

    assert(testHelp(nil, 'try these commands', require 'core.string'.startsWith))
    assert(testHelp(env.o, '---test test\no'))
    assert(testHelp(env.scribe, '---scribes a message\n---@param msg string\nscribe(msg)'))
    assert(not testHelp(env.scribe, 'random garbage'))
  end

end)
