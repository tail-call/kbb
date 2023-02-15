local loadImages = require('./images').load

---@type ImageLibrary
local library

local function init()
  love.window.setMode(320 * 3, 200 * 3)
  love.graphics.setDefaultFilter('nearest', 'nearest')
  library = loadImages()
end

---@param pos Vector
local function centerCameraOn(pos)
  love.graphics.translate(
    320/2 - 8 - pos.x * 16,
    200/2 - 16 - pos.y * 16
  )
end

---@param pos Vector
local function guy(pos)
  love.graphics.draw(library.guy, pos.x * 16, pos.y * 16)
end

---@param pos Vector
local function evilGuy(pos)
  local r, g, b, a = love.graphics.getColor()
  love.graphics.setColor(1, 0, 0, 1);
  guy(pos)
  love.graphics.setColor(r, g, b, a)
end

---@param numberOfGuys integer
local function hud(numberOfGuys)
  love.graphics.print('Units: ' .. numberOfGuys, 0, 0)
end

---@param name string
---@param pos Vector
local function tile(name, pos)
  love.graphics.draw(library[name], pos.x * 16, pos.y * 16)
end

return {
  init = init,
  centerCameraOn = centerCameraOn,
  guy = guy,
  evilGuy = evilGuy,
  hud = hud,
  tile = tile,
}