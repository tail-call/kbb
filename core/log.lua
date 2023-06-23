---Logs a warning message.
---@param message string
---@param level? integer
local function warn(message, level)
  if not Global.shouldLogWarnings then
    return
  end

  if Global.shouldCrashOnWarnings then
    error(message, level)
  else
    print(debug.traceback('WARNING: ' .. message, level))
  end
end

---Logs a deprecation warning. `path` is an array of strings
---indicating the particular name that has been deprecated.
---Usually starts with a module name followed by a function
---followed by a parameter name.
---
---Example call: `deprecated { 'core.class', 'define', 'opts', 'metatable' }`
---@param path string[]
local function deprecated(path)
  local message = string.format(
    '%s is deprecated',
    table.concat(path, ': ')
  )
  warn(message, 3)
end

local printf = function (fmt, ...)
  return io.write(string.format(fmt, ...))
end


return {
  warn = warn,
  deprecated = deprecated,
  printf = printf,
}