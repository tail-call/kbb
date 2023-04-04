local loadTileset = require('./tileset').load
local updateTileset = require('./tileset').update
local regenerateTileset = require('./tileset').regenerate
local loadFont = require('./font').load
local pix = require('./pixie')
local tbl = require('./tbl')

-- Constants

local screenWidth = 320
local screenHeight = 200
local tileHeight = 16
local tileWidth = 16
local whiteColor = { 1, 1, 1, 1 }
local grayColor = { 0.5, 0.5, 0.5, 1 }
local shrinkTransform = love.math.newTransform():scale(1/2)

local sky = love.graphics.newMesh({
  {
    0, 0,
    0, 0,
    0.5, 0.5, 1,
  },
  {
    320, 0,
    0, 0,
    0.5, 0.5, 1,
  },
  {
    320, 200,
    0, 0,
    0.25, 0.25, 0.5,
  },
  {
    0, 200,
    0, 0,
    0.25, 0.25, 0.5,
  },
})

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
---@param magn number
local function centerCameraOn(pos, magn)
  love.graphics.scale(magn)
  love.graphics.translate(
    math.floor(screenWidth/magn/2 - 8 - pos.x * tileWidth),
    math.floor(screenHeight/magn/2 - tileHeight/2- pos.y * tileHeight)
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
---@param resources Resources
local function hud(numberOfGuys, isFollowMode, resources)
  withColor(0, 0, 0, 1, function ()
    love.graphics.rectangle('fill', 0, 0, screenWidth, 8)
    love.graphics.rectangle('fill', 0, screenHeight - 8, screenWidth, 8)
  end)
  local num = '' .. numberOfGuys
  love.graphics.print(
    {
      whiteColor,
      'Units: ',
      isFollowMode and whiteColor or grayColor,
      num,
    },
    0, 0
  )
  love.graphics.print(
    'Wood: ' .. resources.wood .. ' | Stone: ' .. resources.stone .. ' | Pretzels: ' .. resources.pretzels,
    0, screenHeight - 8
  )
end

--- Should be called whenever at the start of love.draw
local function prepareFrame()
  love.graphics.scale(zoom)
  love.graphics.draw(sky)
end

---@param name string
---@return Pixie
local function makePixie(name)
  return pix.Pixie.new(tileset.tiles, tileset.quads[name])
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
  withColor(0, 0, 0, 0.5, function ()
    love.graphics.rectangle(
      'fill',
      pos.x * tileWidth,
      pos.y * tileHeight,
      tileWidth,
      tileHeight
    )
  end)
  if battleTimer % 1/4 < 1/16 then
    return
  end
  withColor(0.5 + battleTimer / 2, 1 - battleTimer / 2, 0, 1, function ()
    love.graphics.draw(
      tileset.tiles,
      tileset.quads.battle,
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

---@param pixie Pixie
local function drawPixie(pixie)
  local r, g, b, a = love.graphics.getColor()
  love.graphics.setColor(unpack(pixie.color))
  love.graphics.draw(pixie.texture, pixie.quad, pixie.transform)
  love.graphics.setColor(r, g, b, a)
end

---@param guy Guy
local function drawGuy(guy)
  drawPixie(guy.pixie)

  -- withTransform(
  --   love.math.newTransform(
  --     guy.pos.x * tileWidth,
  --     guy.pos.y * tileHeight - tileHeight / 4
  --   ):apply(shrinkTransform),
  --   function ()
  --     love.graphics.print(guy.team)
  --   end
  -- )
end

---@param guys Guy[]
---@param shouldSkip fun(guy: Guy): boolean
local function drawGuys(guys, shouldSkip)
  local guysClone = tbl.iclone(guys)
  table.sort(guysClone, function (g1, g2)
    return g1.pos.y < g2.pos.y
  end)
  for _, guy in ipairs(guysClone) do
    if not shouldSkip(guy) then
      drawGuy(guy)
    end
  end
end

---@param text string
---@param pos Vector
---@param maxWidth integer
local function textAtTile(text, pos, maxWidth)
  love.graphics.printf(
    text,
    tileWidth * pos.x,
    tileHeight * pos.y,
    tileWidth * maxWidth
  )
end

---@param pos Vector
local function house(pos)
  love.graphics.draw(
    tileset.tiles,
    tileset.quads.house,
    pos.x * tileWidth,
    pos.y * tileHeight
  )
end

---@return number, number
local function getCursorCoords()
  local cx, cy = love.graphics.inverseTransformPoint(
    love.mouse.getPosition()
  )

  return math.floor(cx / tileWidth), math.floor(cy / tileHeight)
end

---@param pos Vector
local function cursor(pos)
  return love.graphics.rectangle(
    'line',
    pos.x * tileWidth,
    pos.y * tileHeight,
    tileWidth,
    tileHeight
  )
end

---@param world World
local function drawWorld(world)
  love.graphics.draw(world.tiles)
end

return {
  battle = battle,
  centerCameraOn = centerCameraOn,
  drawGuys = drawGuys,
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
  textAtTile = textAtTile,
  house = house,
  drawPixie = drawPixie,
  getCursorCoords = getCursorCoords,
  cursor = cursor,
  drawWorld = drawWorld,
}