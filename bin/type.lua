#!/usr/bin/env luajit

local filename = ...

local file = io.open(filename)
if not file then
  error(('file not found: %s'):format(filename))
end
local content = file:read('*a')
file:close()
print(content)