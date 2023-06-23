---@class CommandsOptions
---@field echo fun(...)
---@field clear fun(...)
---@field scribe fun(text: string)
---@field root table
---@field global table

---@param opts CommandsOptions
---@return table
local function new(opts)
  local echo = opts.echo or error('opts.echo is required', 2)
  local root = opts.root or error('opts.root is required', 2)
  local global = opts.global or error('opts.global is required', 2)
  local clear = opts.clear or error('opts.clear is required', 2)
  local scribe = opts.scribe or error('opts.scribe is required', 2)

  local env, helpPages
  env = {
    pairs = pairs,
    ipairs = ipairs,
    require = require,
    package = package,
    o = root,
    Global = global,
    reload = require 'core.class'.reload,
    scribe = scribe,
    clear = clear,
    print = function (...)
      local items = {...}
      for i = 1, #items do
        if type(items[i]) == 'table' then
          local props = {}
          for k, v in pairs(items[i]) do
            table.insert(props, string.format('%s = %s', k, v))
          end
          table.sort(items)
          items[i] = table.concat(props, '\n')
        end
      end
      echo(unpack(items))
    end,
    -- TODO: make it data-driven
    help = function (arg)
      if arg == nil then
        echo 'try these commands or hit escape if confused:\n'
        for k in pairs(env) do
          echo(('help(%s)'):format(k))
        end
      else
        local helpFunc = helpPages[arg]
        if helpFunc == nil then
          echo(([[
---Don't use this command
%s(...) -- bad]]):format(arg))
        else
          helpFunc()
        end
      end
    end,
    quit = function ()
      package.loaded['scene.menu'] = nil
      require 'scene.menu'.go('fromgame')
    end,
  }
  helpPages = {
    [env.Global] = function ()
      echo [[
---Global variables
print(Global)]]
    end,
    [env.o] = function ()
      echo [[
---Root game object
o]]
    end,
    [env.help] = function ()
      echo [[
---Outputs info about a command in the console
---@param name string
help(name)]]
    end,
    [env.print] = function ()
      echo [[
---Prints objects to a console
---@param ... any[]
print(...)]]
    end,
    [env.clear] = function ()
      echo [[
---Clears the screen
clear()]]
    end,
    [env.scribe] = function ()
      echo [[
---Scribes a message in the world
---@param message string
scribe(message)]]
    end,
    [env.reload] = function ()
      echo [[
---Reloads a module
---@param moduleName string
reload(moduleName)]]
    end,
    [env.quit] = function ()
      echo [[
---Quits to the main menu
quit()]]
    end,
  }
  return env
end

return {
  new = new,
}