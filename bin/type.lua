#!/usr/bin/env luajit

local filename = ...

if not filename then
  print 'USAGE:\ntype <filename>'
  return
end

local file = io.open(filename)
if not file then
  print(('file not found: %s'):format(filename))
  return
end

local content = file:read('*a')
file:close()

print(content)