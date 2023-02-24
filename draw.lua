local loadTileset = require('./tileset').load
local updateTileset = require('./tileset').update
local regenerateTileset = require('./tileset').regenerate
local loadFont = require('./font').load
local Pixie = require('./pixie')

-- Constants

local screenWidth = 320
local screenHeight = 200
local tileHeight = 16
local tileWidth = 16

-- Variables

local highlightCircleRadius = 10
local zoom = 1

local battleTimer = 0
local battleTimerSpeed = 2

---@type Tileset
local tileset

local function getTileset()
  return tileset
end

local function setZoom(z)
  zoom = z
  love.window.setMode(screenWidth * z, screenHeight * z)
  if tileset then
    regenerateTileset(tileset)
  end
end

local function init()
  setZoom(3)
  love.graphics.setDefaultFilter('linear', 'nearest')
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
---@param position Vector
local function hud(numberOfGuys, isFollowMode, position)
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
      { 1, 1, 1, 1 },
      ' | Coords: (' .. position.x .. ', ' .. position.y .. ')',
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
  battleTimer = (battleTimer + battleTimerSpeed * dt) % 1
  updateTileset(tileset, dt)
end

---@param pos Vector
local function recruitableHighlight(pos)
  local x = pos.x * tileWidth + tileWidth / 2
  local y = pos.y * tileHeight + tileHeight / 2
  withColor(1, 1, 1, 1, function ()
    love.graphics.circle('line', x, y, highlightCircleRadius)
  end)
  withColor(1, 1, 1, 0.5, function ()
    love.graphics.circle('fill', x, y, highlightCircleRadius)
  end)
end

---@param pos Vector
local function recruitCircle(pos, radius)
  love.graphics.circle(
    'line',
    pos.x * tileWidth + tileWidth / 2,
    pos.y * tileHeight + tileHeight / 2,
    radius * tileWidth
  )
end

---@param pos Vector
local function battle(pos)
  if battleTimer % 1/4 < 1/16 then
    return
  end
  withColor(0.5 + battleTimer / 2, 1 - battleTimer / 2, 0, 1, function ()
    love.graphics.draw(
      tileset.tiles,
      tileset.battle,
      pos.x * tileWidth,
      pos.y * tileHeight
    )
  end)
end

---@param transform love.Transform
---@param cb fun(): nil
local function withTransform(transform, cb)
  love.graphics.push('transform')
  love.graphics.applyTransform(transform)
  cb()
  love.graphics.pop()
end

return {
  battle = battle,
  centerCameraOn = centerCameraOn,
  getTileset = getTileset,
  hud = hud,
  init = init,
  prepareFrame = prepareFrame,
  recruitCircle = recruitCircle,
  recruitableHighlight = recruitableHighlight,
  setZoom = setZoom,
  makePixie = makePixie,
  update = update,
  withColor = withColor,
  withTransform = withTransform,
}