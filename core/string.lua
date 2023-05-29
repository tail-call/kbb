local M = {}

function M.forceSlashAtEnd(str)
  for k in str:gmatch('.$') do
    if k ~= '/' then
      str = str .. '/'
    end
  end
  return str
end

return M