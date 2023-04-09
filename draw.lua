local loadTileset = require('./tileset').load
local updateTileset = require('./tileset').update
local getTileset = require('./tileset').getTileset
local regenerateTileset = require('./tileset').regenerate
local loadFont = require('./font').load
local pix = require('./pixie')
local tbl = require('./tbl')
local vector = require('./vector')
local getTile = require('./world').getTile

-- Constants

local screenWidth = 320
local screenHeight = 200
local tileHeight = 16
local tileWidth = 16
local whiteColor = { 1, 1, 1, 1 }
local grayColor = { 0.5, 0.5, 0.5, 1 }
local cursorTimerSpeed = 2
local battleTimerSpeed = 2

local whiteCursorColor = { 1, 1, 1, 0.8 }
local redColor = { 1, 0, 0, 0.8 }
local yellowColor = { 1, 1, 0, 0.8 }

-- Variables

local highlightCircleRadius = 10
local zoom = 1
local cursorTimer = 0
local battleTimer = 0

local function setZoom(z)
  zoom = z
  love.window.setMode(screenWidth * z, screenHeight * z)
  local tileset = getTileset()
  if tileset then
    regenerateTileset(tileset)
  end
end

local function init()
  setZoom(3)
  love.graphics.setDefaultFilter('linear', 'nearest')
  love.graphics.setFont(loadFont('cga8.png', 8, 8))
  love.graphics.setLineStyle('rough')
  loadTileset()
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

---@param ui UI
local function drawUI(ui)
  love.graphics.translate(ui.x, ui.y)
  if ui.type == 'none' then
    ---@cast ui UI
  elseif ui.type == 'panel' then
    ---@cast ui PanelUI
    local bg = ui.background
    withColor(bg.r, bg.g, bg.b, bg.a, function ()
      love.graphics.rectangle(
        'fill',
        0,
        0,
        ui.w,
        ui.h
      )
    end)
    if ui.coloredText then
      love.graphics.print(
        ui.coloredText(),
        0, 0
      )
    else
      withColor(1, 1, 1, 1, function ()
        love.graphics.printf(ui.text(), 0, 0, ui.w)
      end)
    end
  end
  for _, child in ipairs(ui.children) do
    drawUI(child)
  end
  love.graphics.translate(-ui.x, -ui.y)
end

---@param numberOfGuys integer
---@param isFollowMode boolean
---@param resources Resources
local function drawHud(numberOfGuys, isFollowMode, resources)
  drawUI({
    type = 'none',
    x = 0,
    y = 0,
    children = {
      ---@type PanelUI
      {
        type = 'panel',
        x = 0,
        y = 0,
        w = screenWidth,
        h = 8,
        background = { r = 0, g = 0, b = 0, a = 1 },
        coloredText = function ()
          return {
            whiteColor,
            'Units: ',
            isFollowMode and whiteColor or grayColor,
            '' .. numberOfGuys,
          }
        end,
        children = {},
      },
      ---@type PanelUI
      {
        type = 'panel',
        x = 0,
        y = screenHeight - 8,
        w = screenWidth,
        h = 8,
        background = { r = 0, g = 0, b = 0, a = 1 },
        text = function ()
          return string.format(
            'Wood: %s | Stone: %s | Pretzels: %s',
            resources.wood,
            resources.stone,
            resources.pretzels
          )
        end,
        children = {},
      },
    },
  })
end

--- Should be called whenever at the start of love.draw
local function prepareFrame()
  love.graphics.scale(zoom)
end

local function update(dt)
  local tileset = getTileset()
  battleTimer = (battleTimer + battleTimerSpeed * dt) % 1
  cursorTimer = (cursorTimer + cursorTimerSpeed * dt) % (math.pi * 2)
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
local function drawBattle(pos)
  local tileset = getTileset()
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
  local tileset = getTileset()
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
local function drawCursor(pos)
  local invSqrt2 = 1/math.sqrt(2)
  local mInvSqrt2 = 1 - invSqrt2

  local transform = love.math.newTransform(
    pos.x * tileWidth + tileWidth / 2,
    pos.y * tileHeight + tileHeight / 2
  )
    :rotate(cursorTimer)
    :scale(mInvSqrt2 * math.cos(cursorTimer * 4 + 4 * math.pi/2) / 2 + invSqrt2)
    :translate(-tileWidth/2, -tileHeight/2)

  withTransform(transform, function ()
    love.graphics.rectangle(
      'line', 0, 0, tileWidth, tileHeight
    )
  end)
end

---@param world World
---@param pos Vector
---@param visionDistance number
local function drawWorld(world, pos, visionDistance)
  local tileset = getTileset()
  local vd2 = visionDistance ^ 2
  for y = pos.y - visionDistance, pos.y + visionDistance do
    for x = pos.x - visionDistance, pos.x + visionDistance do
      ---@param v Vector
      ---@return number
      local function calcDist(v)
        local dir = vector.sub(pos, v)
        return vd2 - dir.x ^ 2 - dir.y ^ 2 + 2
      end
      local dist = calcDist({ x = x, y = y })
      if dist > 0 then
        local alpha = 1
        for dy = -1, 1 do
          for dx = -1, 1 do
            if calcDist({ x = x + dx, y = y + dy }) < 0 then
              alpha = alpha - 1/8
            end
          end
        end
        withColor(0.5, 0.5, 0.8, alpha, function ()
          love.graphics.draw(tileset.tiles, tileset.quads[
            world.tileTypes[world.width * (y - 1) + x] or 'water'
          ], x * tileWidth, y * tileHeight)
        end)
      end
    end
  end
end

---@param squad Squad
---@return integer
local function countFollowers(squad)
  local counter = 0
  for _ in pairs(squad.followers) do
    counter = counter + 1
  end
  return counter
end

---@param game Game
local function drawGame(game)
  love.graphics.push('transform')

  -- Draw terrain

  centerCameraOn(game.lerpVec, game.magnificationFactor)

  drawWorld(game.world, game.player.pos, 10)
  for _, guy in ipairs(game.guys) do
    if guy.team == 'good' then
      drawWorld(game.world, guy.pos, 10)
    end
  end
  drawWorld(game.world, game.cursorPos, 2)

  -- Draw in-game objects

  for _, text in ipairs(game.texts) do
    textAtTile(text.text, text.pos, text.maxWidth)
  end

  for _, building in ipairs(game.buildings) do
    house(building.pos)
  end

  drawGuys(game.guys, function (guy)
    return game.isFrozen(guy)
  end)

  if game.recruitCircle then
    for _, guy in tbl.ifilter(game.guys, function (guy)
      return game.mayRecruit(guy)
    end) do
      recruitableHighlight(guy.pos)
    end
  end

  for _, battle in ipairs(game.battles) do
    drawBattle(battle.pos)
  end

  if game.recruitCircle then
    recruitCircle(game.player.pos, game.recruitCircle)
  end

  -- Draw cursor

  local cx, cy = getCursorCoords()
  local tileUnderCursor
  do
    local cursorPos = { x = cx, y = cy }
    local cursorColor = whiteCursorColor

    if game.isFocused then
      cursorColor = yellowColor
    else
      game.cursorPos = cursorPos
    end

    tileUnderCursor = getTile(game.world, game.cursorPos) or '???'
    local collision = game.collider(nil, game.cursorPos)

    if collision.type == 'terrain' then
      cursorColor = redColor
    end

    local r, g, b, a = unpack(cursorColor)
    withColor(r, g, b, a, function ()
      drawCursor(game.cursorPos)
    end)
  end

  love.graphics.pop()

  -- Draw HUD

  drawHud(
    countFollowers(game.squad),
    game.squad.shouldFollow,
    game.resources
  )

  if game.isFocused then
    love.graphics.print(
      string.format(
        'Terrain: %s\nCoords: (%s,%s)\nPress B to build a house (5 wood)'
          .. '\nPress S to scribe a message.',
        tileUnderCursor,
        game.cursorPos.x,
        game.cursorPos.y
      ), 0, 8
    )
  end
end


return {
  battle = drawBattle,
  centerCameraOn = centerCameraOn,
  drawGuys = drawGuys,
  getTileset = getTileset,
  hud = drawHud,
  init = init,
  prepareFrame = prepareFrame,
  recruitCircle = recruitCircle,
  recruitableHighlight = recruitableHighlight,
  setZoom = setZoom,
  update = update,
  withColor = withColor,
  withTransform = withTransform,
  textAtTile = textAtTile,
  house = house,
  drawPixie = drawPixie,
  getCursorCoords = getCursorCoords,
  cursor = drawCursor,
  drawWorld = drawWorld,
  drawGame = drawGame,
}