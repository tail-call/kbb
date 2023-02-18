local loadImages = require('./images').load
local loadFont = require('./font').load
local Pixie = require('./pixie')

---@alias SpriteId integer

local screenWidth = 320
local screenHeight = 200
local tileHeight = 16
local tileWidth = 16
local zoom = 1

---@type Tileset
local tileset

local function getTileset()
  return tileset
end

local function setZoom(z)
  zoom = z
  love.window.setMode(screenWidth * z, screenHeight * z)
end

local function init()
  setZoom(3)
  love.graphics.setDefaultFilter('nearest', 'nearest')
  love.graphics.setFont(loadFont('cga8.png', 8, 8))
  tileset = loadImages()
end

---@param pos Vector
local function centerCameraOn(pos)
  love.graphics.translate(
    math.floor(screenWidth/2 - 8 - pos.x * tileWidth),
    math.floor(screenHeight/2 - tileHeight - pos.y * tileHeight)
  )
end

---@param pos Vector
local function guy(pos)
  love.graphics.draw(tileset.tiles, tileset.guy, pos.x * 16, pos.y * 16)
end

local function withColor(r, g, b, a, cb)
  local xr, xg, xb, xa = love.graphics.getColor()
  love.graphics.setColor(r, g, b, a)
  cb()
  love.graphics.setColor(xr, xg, xb, xa)
end

---@param r number
---@param g number
---@param b number
---@param a number
---@param pos Vector
local function guyWithColor(r, g, b, a, pos)
  withColor(r, g, b, a, function ()
    guy(pos)
  end)
end

---@param numberOfGuys integer
---@param isFollowMode boolean
local function hud(numberOfGuys, isFollowMode)
  withColor(0, 0, 0, 1, function ()
    love.graphics.rectangle("fill", 0, 0, screenWidth, 8)
  end)
  local num = '' .. numberOfGuys
  if not isFollowMode then
    num = '(' .. num .. ')'
  end
  love.graphics.print('Units: ' .. num, 0, 0)
end

local function prepareFrame()
  love.graphics.scale(zoom)
end

---@param name string
---@return Pixie
local function makePixie(name)
  return Pixie.new(tileset.tiles, tileset[name])
end

return {
  centerCameraOn = centerCameraOn,
  getTileset = getTileset,
  guy = guy,
  guyWithColor = guyWithColor,
  hud = hud,
  init = init,
  prepareFrame = prepareFrame,
  setZoom = setZoom,
  makePixie = makePixie,
}