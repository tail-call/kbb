local M = {}

function M.forceSlashAtEnd(str)
  for k in str:gmatch('.$') do
    if k ~= '/' then
      str = str .. '/'
    end
  end
  return str
end

function M.startsWith(str, prefix)
  if prefix == '' then return true end
  return str:sub(1, #prefix) == prefix
end

return M