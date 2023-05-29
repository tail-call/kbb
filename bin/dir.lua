local path = ...

if not path then
  path = Sys.getCurrentDir()
end

path = require 'core.string'.forceSlashAtEnd(path)

local items = love.filesystem.getDirectoryItems(path)

for _, item in ipairs(items) do
  local info = love.filesystem.getInfo(item)
  if info.type == 'directory' then
    item = require 'core.string'.forceSlashAtEnd(item)
  end
  print(path .. item)
end