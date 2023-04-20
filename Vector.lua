---@class Vector
---@field x number
---@field y number

local UP = { x =  0, y = -1 }
local DOWN = { x =  0, y =  1 }
local LEFT = { x = -1, y =  0 }
local RIGHT = { x =  1, y =  0 }

---@param v1 Vector
---@param v2 Vector
---@return Vector
local function add(v1, v2)
  return { x = v1.x + v2.x, y = v1.y + v2.y }
end

---@param v1 Vector
---@param v2 Vector
---@return Vector
local function sub(v1, v2)
  return { x = v1.x - v2.x, y = v1.y - v2.y }
end

---@param v Vector
---@param c number
---@return Vector
local function scale(v, c)
  return { x = c * v.x, y = c * v.y }
end

---@param v Vector
---@return Vector
local function neg (v)
  return { x = -v.x, y = -v.y }
end

---@param v1 Vector
---@param v2 Vector
---@return boolean
local function equal(v1, v2)
  return v1.x == v2.x and v1.y == v2.y
end

---@param v1 Vector
---@param v2 Vector
---@return Vector
local function lerp(v1, v2, factor)
  return {
    x = v1.x + (v2.x - v1.x) * factor,
    y = v1.y + (v2.y - v1.y) * factor,
  }
end

---@param v Vector
---@return number
local function len(v)
  return math.sqrt(v.x * v.x + v.y * v.y)
end

---@param v1 Vector
---@param v2 Vector
---@return number
local function dist(v1, v2)
  return len(sub(v2, v1))
end

---@param v1 Vector
---@param v2 Vector
---@return Vector
local function midpoint(v1, v2)
  return {
    x = (v1.x + v2.x) / 2,
    y = (v1.y + v2.y) / 2,
  }
end

---@param v1 Vector
---@param v2 Vector
---@return Vector
local function dotProd(v1, v2)
  return {
    x = v1.x * v2.x - v1.y * v2.y,
    y = v1.x * v2.y + v1.y * v2.x
  }
end

local dir = {
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

return {
  add = add,
  sub = sub,
  scale = scale,
  neg = neg,
  equal = equal,
  lerp = lerp,
  len = len,
  dist = dist,
  midpoint = midpoint,
  dotProd = dotProd,
  dir = dir,
}