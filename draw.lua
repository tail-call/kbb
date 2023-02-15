local loadImages = require('./images').load

local screenWidth = 320
local screenHeight = 200
local zoom = 1

---@type ImageLibrary
local library

local function setZoom(z)
  zoom = z
  love.window.setMode(screenWidth * z, screenHeight * z)
end

local function init()
  setZoom(3)
  love.graphics.setDefaultFilter('nearest', 'nearest')
  library = loadImages()
end

---@param pos Vector
local function centerCameraOn(pos)
  love.graphics.translate(
    screenWidth/2 - 8 - pos.x * 16,
    screenHeight/2 - 16 - pos.y * 16
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

local function prepareFrame()
  love.graphics.scale(zoom)
end

return {
  init = init,
  setZoom = setZoom,
  centerCameraOn = centerCameraOn,
  guy = guy,
  evilGuy = evilGuy,
  hud = hud,
  tile = tile,
  prepareFrame = prepareFrame,
}