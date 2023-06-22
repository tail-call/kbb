local function inspect(value)
  _G.see = function (t)
    for k, v in pairs(t) do
      print(k, v)
    end
    print('---')
    print('metatable', getmetatable(t))
  end
  _G.mee = function (t)
    _G.see(getmetatable(t))
  end
  _G.value = value
  print('Type see(value) to print tables, mee(value) to print metatables')
  debug.debug()
end

local qdump

---yap yap yap
---@param ... any yap
local function yap(...)
  for _, v in ipairs { ... } do
    if type(v) == 'table' then
      -- yap yap yap
      qdump(v)
    else
      -- yap
      io.write(tostring(v))
    end
  end
end

function qdump(tbl)
  yap('{ ')
  for k, v in pairs(tbl) do
    yap(k, ' = ', v, ', ')
  end
  yap(' }\n')
end

return {
  inspect = inspect,
  yap = yap,
  qdump = qdump,
}