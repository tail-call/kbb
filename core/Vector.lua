---@alias Vector { x: number, y: number }

local UP = { x =  0, y = -1 }
local DOWN = { x =  0, y =  1 }
local LEFT = { x = -1, y =  0 }
local RIGHT = { x =  1, y =  0 }

local VectorModule = {
  dir = {
    up = UP,
    down = DOWN,
    left = LEFT,
    right = RIGHT,
    w = UP,
    a = LEFT,
    s = DOWN,
    d = RIGHT,
    h = LEFT,
    j = DOWN,
    k = UP,
    ['l'] = RIGHT,
  }
}

---@param v1 Vector
---@param v2 Vector
---@return Vector
function VectorModule.add(v1, v2)
  return { x = v1.x + v2.x, y = v1.y + v2.y }
end

---@param v1 Vector
---@param v2 Vector
---@return Vector
function VectorModule.sub(v1, v2)
  return { x = v1.x - v2.x, y = v1.y - v2.y }
end

---@param v Vector
---@param c number
---@return Vector
function VectorModule.scale(v, c)
  return { x = c * v.x, y = c * v.y }
end

---@param v Vector
---@return Vector
function VectorModule.neg(v)
  return { x = -v.x, y = -v.y }
end

---@param v1 Vector
---@param v2 Vector
---@return boolean
function VectorModule.equal(v1, v2)
  return v1.x == v2.x and v1.y == v2.y
end

---@param v1 Vector
---@param v2 Vector
---@return Vector
function VectorModule.lerp(v1, v2, factor)
  return {
    x = v1.x + (v2.x - v1.x) * factor,
    y = v1.y + (v2.y - v1.y) * factor,
  }
end

---@param v Vector
---@return number
function VectorModule.len(v)
  return math.sqrt(v.x * v.x + v.y * v.y)
end

---@param v1 Vector
---@param v2 Vector
---@return number
function VectorModule.dist(v1, v2)
  return VectorModule.len(VectorModule.sub(v2, v1))
end

---@param v1 Vector
---@param v2 Vector
---@return Vector
function VectorModule.midpoint(v1, v2)
  return {
    x = (v1.x + v2.x) / 2,
    y = (v1.y + v2.y) / 2,
  }
end

---@param v1 Vector
---@param v2 Vector
---@return Vector
function VectorModule.dotProd(v1, v2)
  return {
    x = v1.x * v2.x - v1.y * v2.y,
    y = v1.x * v2.y + v1.y * v2.x
  }
end

---@param v Vector
---@return string
function VectorModule.formatVector(v)
  return ('%sx %sy'):format(v.x, v.y)
end

return VectorModule