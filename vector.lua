---@alias Vector { x: integer, y: integer }

return {
  ---@param v1 Vector
  ---@param v2 Vector
  ---@return Vector
  add = function(v1, v2)
    return { x = v1.x + v2.x, y = v1.y + v2.y }
  end,

  ---@param v1 Vector
  ---@param v2 Vector
  ---@return Vector
  sub = function(v1, v2)
    return { x = v1.x - v2.x, y = v1.y - v2.y }
  end,

  ---@param v Vector
  ---@return Vector
  neg = function(v)
    return { x = -v.x, y = -v.y }
  end,

  ---@param v1 Vector
  ---@param v2 Vector
  ---@return boolean
  equal = function(v1, v2)
    return v1.x == v2.x and v1.y == v2.y
  end,

  ---@param v1 Vector
  ---@param v2 Vector
  ---@return Vector
  lerp = function(v1, v2, factor)
    return {
      x = v1.x + (v2.x - v1.x) * factor,
      y = v1.y + (v2.y - v1.y) * factor,
    }
  end,

  dir = {
    up    = { x =  0, y = -1 },
    down  = { x =  0, y =  1 },
    left  = { x = -1, y =  0 },
    right = { x =  1, y =  0 },
  },
}