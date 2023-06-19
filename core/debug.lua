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

return {
  inspect = inspect,
}