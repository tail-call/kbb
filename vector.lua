---@alias Vector { x: integer, y: integer }

local vector

local up = { x =  0, y = -1 }
local down = { x =  0, y =  1 }
local left = { x = -1, y =  0 }
local right = { x =  1, y =  0 }

vector = {
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
  ---@param c number
  ---@return Vector
  scale = function(v, c)
    return { x = c * v.x, y = c * v.y }
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

  ---@param v Vector
  ---@return number
  len = function(v)
    return math.sqrt(v.x * v.x + v.y * v.y)
  end,

  ---@param v1 Vector
  ---@param v2 Vector
  ---@return number
  dist = function(v1, v2)
    return vector.len(vector.sub(v2, v1))
  end,

  ---@param v1 Vector
  ---@param v2 Vector
  ---@return Vector
  midpoint = function(v1, v2)
    return {
      x = (v1.x + v2.x) / 2,
      y = (v1.y + v2.y) / 2,
    }
  end,

  dir = {
    up = up,
    down = down,
    left = left,
    right = right,
    w = up,
    a = left,
    s = down,
    d = right,
    h = left,
    j = down,
    k = up,
    ['l'] = right,
  },
}

return vector