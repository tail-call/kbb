---@class Building
---@field pos Vector Building's position

---@param pos Vector
local function makeBuilding(pos)
  return { pos = pos }
end

return {
  makeBuilding = makeBuilding
}