return {
  deprecated = function (path)
    local message = string.format(
      'WARNING: %s is deprecated',
      table.concat(path, ': ')
    )
    print(debug.traceback(message, 3))
  end,
}