local function dep(obj, cb)
  local impostor = {}
  setmetatable(impostor, {
    __index = function (t, k)
      if obj[k] == nil then
        error(k .. ' is required', 6)
      end
      return obj[k]
    end
  })
  cb(impostor)
end

return dep