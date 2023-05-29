---@class core.Vector
---@field x number X coordinate of the vector
---@field y number Y coordinate of the vector

local UP = { x =  0, y = -1 }
local DOWN = { x =  0, y =  1 }
local LEFT = { x = -1, y =  0 }
local RIGHT = { x =  1, y =  0 }

local M = require 'core.Module'.define{..., metatable = {
  ---@type core.Vector
  __index = {}
}}

M.dir = {
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
  l = RIGHT,
}

---@param v1 core.Vector
---@param v2 core.Vector
---@return core.Vector
function M.add(v1, v2)
  return { x = v1.x + v2.x, y = v1.y + v2.y }
end

---@param v1 core.Vector
---@param v2 core.Vector
---@return core.Vector
function M.sub(v1, v2)
  return { x = v1.x - v2.x, y = v1.y - v2.y }
end

---@param v core.Vector
---@param c number
---@return core.Vector
function M.scale(v, c)
  return { x = c * v.x, y = c * v.y }
end

---@param v core.Vector
---@return core.Vector
function M.neg(v)
  return { x = -v.x, y = -v.y }
end

---@param v1 core.Vector
---@param v2 core.Vector
---@return boolean
function M.equal(v1, v2)
  return v1.x == v2.x and v1.y == v2.y
end

---@param v1 core.Vector
---@param v2 core.Vector
---@return core.Vector
function M.lerp(v1, v2, factor)
  return {
    x = v1.x + (v2.x - v1.x) * factor,
    y = v1.y + (v2.y - v1.y) * factor,
  }
end

---@param v core.Vector
---@return number
function M.len(v)
  return math.sqrt(v.x * v.x + v.y * v.y)
end

---@param v1 core.Vector
---@param v2 core.Vector
---@return number
function M.dist(v1, v2)
  return M.len(M.sub(v2, v1))
end

---@param v1 core.Vector
---@param v2 core.Vector
---@return core.Vector
function M.midpoint(v1, v2)
  return {
    x = (v1.x + v2.x) / 2,
    y = (v1.y + v2.y) / 2,
  }
end

---@param v1 core.Vector
---@param v2 core.Vector
---@return core.Vector
function M.dotProd(v1, v2)
  return {
    x = v1.x * v2.x - v1.y * v2.y,
    y = v1.x * v2.y + v1.y * v2.x
  }
end

---@param v core.Vector
---@return string
function M.formatVector(v)
  return ('%sx %sy'):format(v.x, v.y)
end

return M