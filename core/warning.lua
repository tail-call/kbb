return {
  deprecated = function (path)
    local message = string.format(
      '%s is deprecated',
      table.concat(path, ': ')
    )
    local level = 3
    if GlobalOptions.shouldCrashOnWarnings then
      error(message, level)
    else
      print(debug.traceback('WARNING: ' .. message, level))
    end
  end,
}