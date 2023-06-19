--- Control flow functions

local function TypeCase(obj, fallthroughHandler)
  return function (args)
    for i = 1, #args, 2 do
      local signature, action = args[i], args[i + 1]
      local function doAction(o)
        if type(action) == 'function' then
          return action(o)
        else
          return action
        end
      end
      if signature == nil then
        return doAction(obj)
      elseif type(signature) == 'string' then
        if type(obj) == signature then
          return doAction(obj)
        end
      elseif type(signature) == 'table' then
        local mt = getmetatable(obj)
        if mt and mt.__index == obj then
          return doAction(obj)
        end
      elseif type(signature) == 'function' then
        if signature(obj) then
          return doAction(obj)
        end
      else
        error('invalid TypeCase signature: ' .. tostring(signature))
      end
    end

    if fallthroughHandler then
      fallthroughHandler(obj)
    end
  end
end

local function ETypeCase (obj)
  return TypeCase(obj, function ()
    error('An object fell through TypeCase expression: ' .. tostring(obj))
  end)
end

return {
  TypeCase = TypeCase,
  ETypeCase = ETypeCase,
}
