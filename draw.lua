---@param pos Vector
local function centerCameraOn(pos)
  love.graphics.translate(
    320/2 - 8 - pos.x * 16,
    200/2 - 16 - pos.y * 16
  )
end

local function guy(image, pos)
  love.graphics.draw(image, pos.x * 16, pos.y * 16)
end

---@param numberOfGuys integer
local function hud(numberOfGuys)
  love.graphics.print('Units: ' .. numberOfGuys, 0, 0)
end

local function tile(image, pos)
  love.graphics.draw(image, pos.x * 16, pos.y * 16)
end

return {
  centerCameraOn = centerCameraOn,
  guy = guy,
  hud = hud,
  tile = tile,
}