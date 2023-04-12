local loadTileset = require('./tileset').load
local updateTileset = require('./tileset').update
local getTileset = require('./tileset').getTileset
local regenerateTileset = require('./tileset').regenerate
local loadFont = require('./font').load
local tbl = require('./tbl')
local vector = require('./vector')
local getTile = require('./world').getTile

-- Constants

local screenWidth = 320
local screenHeight = 200
local tileHeight = 16
local tileWidth = 16
local cursorTimerSpeed = 2
local battleTimerSpeed = 2
local minimapSize = 72

local whiteCursorColor = { 1, 1, 1, 0.8 }
local redColor = { 1, 0, 0, 0.8 }
local yellowColor = { 1, 1, 0, 0.8 }

local lerpSpeed = 10

-- Variables

local highlightCircleRadius = 10
local zoom = 1
local cursorTimer = 0
local battleTimer = 0
---@type Vector3
local lerpVec = { x = 0, y = 0, z = 1 }
local cameraOffset = { x = 0, y = 0 }

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

local function withColor(r, g, b, a, cb)
  local xr, xg, xb, xa = love.graphics.getColor()
  love.graphics.setColor(r, g, b, a)
  cb()
  love.graphics.setColor(xr, xg, xb, xa)
end

---@param ui UI
local function drawUI(ui)
  if ui.shouldDraw and not ui.shouldDraw() then return end

  love.graphics.applyTransform(ui.transform)
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
    elseif ui.text then
      withColor(1, 1, 1, 1, function ()
        love.graphics.printf(ui.text(), 0, 0, ui.w)
      end)
    end
  end
  for _, child in ipairs(ui.children) do
    drawUI(child)
  end
  love.graphics.applyTransform(ui.transform:inverse())
end

--- Should be called whenever at the start of love.draw
local function prepareFrame()
  love.graphics.scale(zoom)
end

---@param dt number
---@param camera Vector
---@param magn number
---@param isAltCentering boolean
local function update(dt, camera, magn, isAltCentering)
  local tileset = getTileset()
  battleTimer = (battleTimer + battleTimerSpeed * dt) % 1
  cursorTimer = (cursorTimer + cursorTimerSpeed * dt) % (math.pi * 2)
  local offset = vector.add(
    vector.scale(camera, tileWidth),
    { x = 0, y = isAltCentering and screenHeight/magn/8 or 0 }
  )
  lerpVec = vector.lerp3(
    lerpVec,
    { x = offset.x, y = offset.y, z = magn },
    dt * lerpSpeed
  )
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
  for i = 1, radius + 2 do
    local alpha = 0.6 * (1 - (i / (2 + radius)) ^ 2)
    withColor(1, 1, 1, alpha, function ()
      love.graphics.circle(
        'line',
        pos.x * tileWidth + tileWidth / 2,
        pos.y * tileHeight + tileHeight / 2,
        (i - 0.5) * tileWidth
      )
    end)
  end
  local lineWidth = love.graphics.getLineWidth()
  withColor(1, 1, 1, 0.5, function ()
    love.graphics.setLineWidth(lineWidth * 3)
    love.graphics.circle(
      'line',
      pos.x * tileWidth + tileWidth / 2,
      pos.y * tileHeight + tileHeight / 2,
      radius * tileWidth
    )
  end)
  love.graphics.setLineWidth(lineWidth)
  love.graphics.circle(
    'line',
    pos.x * tileWidth + tileWidth / 2,
    pos.y * tileHeight + tileHeight / 2,
    radius * tileWidth
  )
end

---@param battle Battle
local function drawBattle(battle)
  local posX = battle.pos.x * tileWidth
  local posY = battle.pos.y * tileHeight

  local tileset = getTileset()
  withColor(0, 0, 0, 0.5, function ()
    love.graphics.rectangle(
      'fill', posX, posY, tileWidth, tileHeight
    )
  end)

  local isBlink = battleTimer % 1/4 < 1/16

  if not isBlink then
    withColor(0.5 + battleTimer / 2, 1 - battleTimer / 2, 0, 1, function ()
      love.graphics.draw(tileset.tiles, tileset.quads.battle, posX, posY)
    end)
  end

  love.graphics.print(
    tostring(battle.round),
    posX + tileWidth / 4,
    posY + tileHeight / 4 - battle.round * 2
  )
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
local function drawHouse(pos)
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

---Returns true if the target should be directly visible from the point
---@param vd2 number Square of vision's distance
---@param ox number Origin's X coordinate
---@param oy number Origin's Y coordinate
---@param tx number Target's X coordinate
---@param ty number Target's Y coordinate
---@return boolean
local function isVisible(vd2, ox, oy, tx, ty)
  return vd2 + 2 - (ox - tx) ^ 2 - (oy - ty) ^ 2 > 0
end

---@param world World
---@param pos Vector
---@param visionDistance number
---@param sky { r: number, b: number, g: number }
local function drawWorld(world, pos, visionDistance, sky)
  local tileset = getTileset()
  local vd2 = visionDistance ^ 2
  local posX = pos.x
  local posY = pos.y
  for y = posY - visionDistance, posY + visionDistance do
    for x = posX - visionDistance, posX + visionDistance do
      if isVisible(vd2, posX, posY, x, y) then
        local alpha = 1
        for dy = -1, 1 do
          for dx = -1, 1 do
            if not isVisible(vd2, posX, posY, x + dx, y + dy) then
              alpha = alpha - 1/8
            end
          end
        end
        withColor(sky.r, sky.g, sky.b, alpha, function ()
          love.graphics.draw(tileset.tiles, tileset.quads[
            world.tileTypes[world.width * (y - 1) + x] or 'water'
          ], x * tileWidth, y * tileHeight)
        end)
      end
    end
  end
end

---@param game Game
---@param cb fun(visionSource: VisionSource): nil
local function forEachVisionSource(game, cb)
  do
    local visionSources = coroutine.create(game.visionSourcesCo)
    local isRunning, visionSource = coroutine.resume(visionSources)
    while isRunning do
      cb(visionSource)
      isRunning, visionSource = coroutine.resume(visionSources)
    end
  end
end

local skyTable = {
  -- 00:00
  { r = 0.3, g = 0.3, b = 0.6, },
  -- 06:00
  { r = 1.0, g = 0.9, b = 0.8, },
  -- 12:00
  { r = 1, g = 1, b = 1, },
  -- 18:00
  { r = 1.0, g = 0.7, b = 0.7, },
}

---@param time number
---@return { r: number, g: number, b: number }
local function skyColor(time)
  local length = #skyTable
  local offset, blendFactor = math.modf((time) / (24 * 60) * length)
  local colorA = skyTable[1 + (offset + 0) % length]
  local colorB = skyTable[1 + (offset + 1) % length]
  return {
    r = colorA.r + (colorB.r - colorA.r) * blendFactor,
    g = colorA.g + (colorB.g - colorA.g) * blendFactor,
    b = colorA.b + (colorB.b - colorA.b) * blendFactor,
  }
end

---@param game Game
local function drawGame(game)
  love.graphics.push('transform')

  -- Setup camera

  do
    local cx, cy = 0.5, 0.5
    local pos = {
      x = 8 + lerpVec.x,
      y = 8 + lerpVec.y
    }
    love.graphics.scale(lerpVec.z)
    love.graphics.translate(
      math.floor(screenWidth / lerpVec.z * cx - pos.x - cameraOffset.x),
      math.floor(screenHeight / lerpVec.z * cy - pos.y - cameraOffset.y)
    )
  end

  -- Draw visible terrain

  local colorOfSky = skyColor(game.time)
  do
    forEachVisionSource(game, function (visionSource)
      drawWorld(
        game.world,
        visionSource.pos,
        math.floor(visionSource.sight * colorOfSky.g),
        colorOfSky
      )
    end)
  end

  -- Draw in-game objects

  local drawn = {}

  local guysClone = tbl.iclone(game.guys)
  table.sort(guysClone, function (g1, g2)
    return g1.pos.y < g2.pos.y
  end)

  -- Draw squad highlight
  for guy in pairs(game.squad.followers) do
    local guyHealth = guy.stats.hp / guy.stats.maxHp
    withColor(1, guyHealth, guyHealth, 0.5, function ()
      local ax = game.player.pos.x * tileWidth + tileWidth / 2
      local ay = game.player.pos.y * tileHeight + tileHeight
      local bx = guy.pos.x * tileWidth + tileWidth / 2
      local by = guy.pos.y * tileHeight + tileHeight

      if not game.squad.shouldFollow then
        love.graphics.setColor(0.3, 0.3, 0.4, 0.5)
      end

      love.graphics.line(ax, ay, bx, by)
      love.graphics.ellipse(
        'line',
        guy.pos.x * tileWidth + tileWidth / 2,
        guy.pos.y * tileHeight + tileHeight,
        tileWidth / 1.9,
        tileHeight / 8
      )
    end)
  end

  forEachVisionSource(game, function (visionSource)
    local vd2 = (visionSource.sight * colorOfSky.b) ^ 2
    local posX = visionSource.pos.x
    local posY = visionSource.pos.y

    for _, text in ipairs(game.texts) do
      if not drawn[text] and isVisible(
        vd2,
        posX, posY,
        text.pos.x, text.pos.y
      ) then
        textAtTile(text.text, text.pos, text.maxWidth)
        drawn[text] = true
      end
    end

    for _, building in ipairs(game.buildings) do
      if not drawn[building] and isVisible(
        vd2,
        posX, posY,
        building.pos.x, building.pos.y
      ) then
        drawHouse(building.pos)
        drawn[building] = true
      end
    end

    for _, guy in ipairs(guysClone) do
      if not game.isFrozen(guy) then
        if not drawn[guy] and isVisible(
          vd2,
          posX, posY,
          guy.pos.x, guy.pos.y
        ) then
          drawGuy(guy)
          drawn[guy] = true
        end
      end
    end

    for _, battle in ipairs(game.battles) do
      if not drawn[battle] then
        drawBattle(battle)
        drawn[battle] = true
      end
    end
  end)

  if game.recruitCircle then
    recruitCircle(game.cursorPos, game.recruitCircle)
    for _, guy in tbl.ifilter(game.guys, function (guy)
      return game.mayRecruit(guy)
    end) do
      recruitableHighlight(guy.pos)
    end
  end

  -- Draw cursor

  local cx, cy = getCursorCoords()
  local curDistance = 12
  cx = math.min(game.player.pos.x + curDistance, cx)
  cx = math.max(game.player.pos.x - curDistance, cx)
  cy = math.min(game.player.pos.y + curDistance, cy)
  cy = math.max(game.player.pos.y - curDistance, cy)
  do
    local cursorPos = { x = cx, y = cy }
    local cursorColor = whiteCursorColor

    if game.isFocused then
      cursorColor = yellowColor
    else
      game.cursorPos = cursorPos
    end

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

  drawUI(game.ui)

  -- Console

  -- Minimap

  withTransform(love.math.newTransform(8, screenHeight - 16 - minimapSize), function ()
    local offsetX = game.player.pos.x - minimapSize / 2
    local offsetY = game.player.pos.y - minimapSize / 2
    local quad = love.graphics.newQuad(
      offsetX, offsetY,
      minimapSize, minimapSize,
      game.world.image:getWidth(),
      game.world.image:getHeight()
    )

    local alpha = game.isFocused and 1 or 0.25

    -- Overlay
    withColor(1, 1, 1, alpha, function ()
      love.graphics.draw(game.world.image, quad, 0, 0)
      love.graphics.print('R A D A R', 0, -8)
      love.graphics.setColor(0, 0, 0, 0.25)
      love.graphics.print('    N    ', 0, 0)
      love.graphics.print('W       E', 0, 32)
      love.graphics.print('    S    ', 0, 64)
    end)

    -- Units
    for _, guy in ipairs(game.guys) do
      local color = guy.pixie.color
      local pointX = guy.pos.x - offsetX
      local pointY = guy.pos.y - offsetY
      if pointX >= 0
        and pointX < minimapSize
        and pointY >= 0
        and pointY < minimapSize
      then
        withColor(color[1], color[2], color[3], 1, function ()
          love.graphics.rectangle('fill', pointX, pointY, 1, 1)
        end)
      end
    end

    -- Cursor
    withColor(1, 1, 1, 0.5, function ()
      love.graphics.rectangle('fill', cx - offsetX, cy - offsetY, 1, 1)
    end)

    withTransform(love.math.newTransform(88, 32):scale(2/3, 2/3), function ()
      for i, message in ipairs(game.consoleMessages) do
        local fadeOut = math.min(message.lifetime, 1)
        withColor(1, 1, 1, alpha * fadeOut, function ()
          love.graphics.print(message.text, 0, 8 * i)
        end)
      end
    end)
  end)
end


return {
  battle = drawBattle,
  centerCameraOn = centerCameraOn,
  getTileset = getTileset,
  init = init,
  prepareFrame = prepareFrame,
  recruitCircle = recruitCircle,
  recruitableHighlight = recruitableHighlight,
  setZoom = setZoom,
  update = update,
  withColor = withColor,
  withTransform = withTransform,
  textAtTile = textAtTile,
  house = drawHouse,
  drawPixie = drawPixie,
  getCursorCoords = getCursorCoords,
  cursor = drawCursor,
  drawWorld = drawWorld,
  drawGame = drawGame,
}