local loadImages = require('./images').load

---@alias SpriteId integer

local screenWidth = 320
local screenHeight = 200
local zoom = 1

---@type Tileset
local tileset
---@type love.SpriteBatch
local sprites

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
  tileset = loadImages()
  sprites = love.graphics.newSpriteBatch(tileset.tiles)
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
local function hud(numberOfGuys)
  withColor(0, 0, 0, 1, function ()
    love.graphics.rectangle("fill", 0, 0, screenWidth, 16)
  end)
  love.graphics.print('Units: ' .. numberOfGuys, 0, 0)
end

local function prepareFrame()
  love.graphics.scale(zoom)
end

---@param name string
---@param x integer
---@param y integer
---@param r number
---@param g number
---@param b number
---@param a number
---@return SpriteId
local function addSprite(name, x, y, r, g, b, a)
  local aTile = tileset[name] --[[@as love.Quad]]
  sprites:setColor(r, g, b, a)
  return sprites:add(aTile, x * 16, y * 16)
end

---@param id SpriteId
---@param name string
---@param x integer
---@param y integer
---@param r number
---@param g number
---@param b number
---@param a number
local function moveSprite(id, name, x, y, r, g, b, a)
  local aTile = tileset[name] --[[@as love.Quad]]
  sprites:setColor(r, g, b, a)
  sprites:set(id, aTile, x * 16, y * 16)
end

local function drawSprites()
  love.graphics.draw(sprites)
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
  addSprite = addSprite,
  moveSprite = moveSprite,
  drawSprites = drawSprites,
}