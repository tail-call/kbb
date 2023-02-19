local loadTileset = require('./tileset').load
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
  if tileset then
    tileset:regenerate()
  end
end

local function init()
  setZoom(3)
  love.graphics.setDefaultFilter('nearest', 'nearest')
  love.graphics.setFont(loadFont('cga8.png', 8, 8))
  love.graphics.setLineStyle('rough')
  tileset = loadTileset()
end

---@param pos Vector
local function centerCameraOn(pos)
  love.graphics.translate(
    math.floor(screenWidth/2 - 8 - pos.x * tileWidth),
    math.floor(screenHeight/2 - tileHeight/2- pos.y * tileHeight)
  )
end

local function withColor(r, g, b, a, cb)
  local xr, xg, xb, xa = love.graphics.getColor()
  love.graphics.setColor(r, g, b, a)
  cb()
  love.graphics.setColor(xr, xg, xb, xa)
end

---@param numberOfGuys integer
---@param isFollowMode boolean
local function hud(numberOfGuys, isFollowMode)
  withColor(0, 0, 0, 1, function ()
    love.graphics.rectangle("fill", 0, 0, screenWidth, 8)
  end)
  local num = '' .. numberOfGuys
  love.graphics.print(
    {
      { 1, 1, 1, 1 },
      'Units: ',
      isFollowMode and { 1, 1, 1, 1 } or { 0.5, 0.5, 0.5, 1 },
      num,
    },
  0, 0)
end

--- Should be called whenever at the start of love.draw
local function prepareFrame()
  love.graphics.scale(zoom)
end

---@param name string
---@return Pixie
local function makePixie(name)
  return Pixie.new(tileset.tiles, tileset[name])
end

local function update(dt)
  tileset:update(dt)
end

return {
  centerCameraOn = centerCameraOn,
  getTileset = getTileset,
  hud = hud,
  init = init,
  prepareFrame = prepareFrame,
  setZoom = setZoom,
  makePixie = makePixie,
  update = update,
  withColor = withColor,
}