local function warn(message, level)
  if GlobalOptions.shouldCrashOnWarnings then
    error(message, level)
  else
    print(debug.traceback('WARNING: ' .. message, level))
  end
end

local function deprecated(path)
  local message = string.format(
    '%s is deprecated',
    table.concat(path, ': ')
  )
  warn(message, 3)
end

return {
  warn = warn,
  deprecated = deprecated,
}