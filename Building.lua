---@class Building
---@field pos Vector Building's position

---@param bak Building
local function new(bak)
  return {
    __module = 'Building',
    pos = bak.pos,
  }
end

return {
  new = new
}