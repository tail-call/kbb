---@alias core.Vector3 { x: number, y: number, z: number }

---@param v1 core.Vector3
---@param v2 core.Vector3
---@return core.Vector3
local function lerp3(v1, v2, factor)
  return {
    x = v1.x + (v2.x - v1.x) * factor,
    y = v1.y + (v2.y - v1.y) * factor,
    z = v1.z + (v2.z - v1.z) * factor,
  }
end

return {
  lerp3 = lerp3,
}