---@class X_Serializable
---@field X_Serializable fun(): X_Serializable Implementation
---@field serialize1 fun(self: self): string[] Dumps object into a string of bytes

---@param obj X_Serializable
---@return fun(): X_Serializable
return function(obj)
  return obj.X_Serializable
end