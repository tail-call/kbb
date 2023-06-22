---@class core.Vector
---@field x number X coordinate of the vector
---@field y number Y coordinate of the vector

local UP = { x =  0, y = -1 }
local DOWN = { x =  0, y =  1 }
local LEFT = { x = -1, y =  0 }
local RIGHT = { x =  1, y =  0 }

local Vector = Class {
  ...,
  ---@type core.Vector
  index = {},
}

Vector.dir = {
  up = UP,
  down = DOWN,
  left = LEFT,
  right = RIGHT,
  w = UP,
  a = LEFT,
  s = DOWN,
  d = RIGHT,
}

---@param v1 core.Vector
---@param v2 core.Vector
---@return core.Vector
function Vector.add(v1, v2)
  return { x = v1.x + v2.x, y = v1.y + v2.y }
end

---@param v1 core.Vector
---@param v2 core.Vector
---@return core.Vector
function Vector.sub(v1, v2)
  return { x = v1.x - v2.x, y = v1.y - v2.y }
end

---@param v core.Vector
---@param c number
---@return core.Vector
function Vector.scale(v, c)
  return { x = c * v.x, y = c * v.y }
end

---@param v core.Vector
---@return core.Vector
function Vector.neg(v)
  return { x = -v.x, y = -v.y }
end

---@param v1 core.Vector
---@param v2 core.Vector
---@return boolean
function Vector.equal(v1, v2)
  return v1.x == v2.x and v1.y == v2.y
end

---@param v1 core.Vector
---@param v2 core.Vector
---@return core.Vector
function Vector.lerp(v1, v2, factor)
  return {
    x = v1.x + (v2.x - v1.x) * factor,
    y = v1.y + (v2.y - v1.y) * factor,
  }
end

---@param v core.Vector
---@return number
function Vector.len(v)
  return math.sqrt(v.x * v.x + v.y * v.y)
end

---@param v1 core.Vector
---@param v2 core.Vector
---@return number
function Vector.dist(v1, v2)
  return Vector.len(Vector.sub(v2, v1))
end

---@param v1 core.Vector
---@param v2 core.Vector
---@return core.Vector
function Vector.midpoint(v1, v2)
  return {
    x = (v1.x + v2.x) / 2,
    y = (v1.y + v2.y) / 2,
  }
end

---@param v1 core.Vector
---@param v2 core.Vector
---@return core.Vector
function Vector.dotProd(v1, v2)
  return {
    x = v1.x * v2.x - v1.y * v2.y,
    y = v1.x * v2.y + v1.y * v2.x
  }
end

---@param v core.Vector
---@return string
function Vector.formatVector(v)
  return string.format('%sx %sy', v.x, v.y)
end

return Vector