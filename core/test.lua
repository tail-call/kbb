local function endsWith(str, postfix)
  if postfix == '' then return true end
  return str:sub(-#postfix) == postfix
end

local state = {
  successCount = 0,
  failCount = 0,
  title = '?',
  reset = function (self)
    self.successCount = 0
    self.failCount = 0
    self.title = '?'
  end,
  setTitle = function (self, title)
    self.title = title
  end,
  success = function (self)
    self.successCount = self.successCount + 1
  end,
  fail = function (self)
    self.failCount = self.failCount + 1
  end,
}

local function assert(expr)
  if expr then
    state:success()
  else
    state:fail()
  end
end

local function group(name, cb)
  print('\tRunning group ' .. name .. ':')
  state.title = name
  cb()
end

local function runTests()
  print()
  IsTesting = true
  local dir = io.popen('ls -FR', 'r')
  if not dir then
    error('can\'t open directory: core')
  end

  local prefix = ''

  for line in dir:lines('*l') do
    ---@cast line string

    if endsWith(line, ':') then
      prefix = line:sub(0, #line - 1) .. '/'
      goto continue
    end

    local filename = prefix .. line
    if endsWith(filename, 'test.lua') then
      print('\tRunning test file ' .. filename .. ':')
      dofile(filename)
      print(
        string.format(
          '%s\t%s done, %d succeeded, %d failed',
          state.failCount == 0 and '' or '*',
          state.title, state.successCount, state.failCount
        )
      )
      state:reset()
      print()
    end

    ::continue::
  end
  dir:close()
  print()
end

if IsTesting then
  assert(endsWith('abba', 'ba'))
  assert(endsWith('abba', ''))
  assert(not endsWith('user', 'root'))
end

return {
  runTests = runTests,
  group = group,
  assert = assert,
}