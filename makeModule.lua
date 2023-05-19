#!/usr/bin/env luajit

local name = ...

if name == nil then
  return
end

local templatePath = './templates/Module.lua.template'

local templateFile = io.open(templatePath)

if templateFile == nil then
  error(('failed to open file: %s'):format(templatePath))
end

---@type string
local contents = templateFile:read("*a")
templateFile:close()

local output = contents:gsub('%$%{(%w+)%}', function (var)
  if var == 'name' then
    return name
  else
    error(('unknown variable: %s'):format(var))
  end
end)

print(output)