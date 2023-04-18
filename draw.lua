local loadTileset = require('./tileset').load
local updateTileset = require('./tileset').update
local getTileset = require('./tileset').getTileset
local parallaxTile = require('./tileset').parallaxTile
local regenerateTileset = require('./tileset').regenerate
local loadFont = require('./font').load
local tbl = require('./tbl')
local vector = require('./vector')
local util = require('./util')
local withColor = require('./util').withColor
local withLineWidth = require('./util').withLineWidth
local withTransform = require('./util').withTransform

-- Constants

local SCREEN_WIDTH = 320
local SCREEN_HEIGHT = 200
local TILE_HEIGHT = 16
local TILE_WIDTH = 16
local CAMERA_LERP_SPEED = 10
local CURSOR_TIMER_SPEED = 2
local BATTLE_TIMER_SPEED = 2
local WATER_TIMER_SPEED = 1/4
local MINIMAP_SIZE = 72
local HIGHLIGHT_CIRCLE_RADIUS = 10

local WHITE_CURSOR_COLOR = { 1, 1, 1, 0.8 }
local RED_COLOR = { 1, 0, 0, 0.8 }
local YELLOW_COLOR = { 1, 1, 0, 0.8 }

local SKY_TABLE = {
  -- 00:00
  { r = 0.3, g = 0.3, b = 0.6, },
  -- 06:00
  { r = 1.0, g = 0.9, b = 0.8, },
  -- 12:00
  { r = 1, g = 1, b = 1, },
  -- 18:00
  { r = 1.0, g = 0.7, b = 0.7, },
}

-- Variables

local drawState = {
  zoom = 1,
  ---@type Vector3
  camera = { x = 266 * 16, y = 229 * 16, z = 0.01 },
  cursorTimer = 0,
  battleTimer = 0,
  waterTimer = 0,
}

local function setZoom(z)
  drawState.zoom = z
  love.graphics.setFont(loadFont('cga8.png', 8, 8, math.random() > 0.5))
  local w, h = love.window.getMode()
  if w ~= SCREEN_WIDTH * z and h ~= SCREEN_WIDTH * z then
    love.window.setMode(SCREEN_WIDTH * z, SCREEN_HEIGHT * z)
  end
  local tileset = getTileset()
  if tileset then
    regenerateTileset(tileset)
  end
end

local function init()
  setZoom(3)
  love.graphics.setDefaultFilter('linear', 'nearest')
  love.graphics.setFont(loadFont('cga8.png', 8, 8, true))
  love.graphics.setLineStyle('rough')
  loadTileset()
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
      love.graphics.rectangle('fill', 0, 0, ui.w, ui.h)
    end)

    -- Draw text with shadow

    for val = 0, 1 do
      withColor(val, val, val, 1, function ()
        if ui.coloredText then
          love.graphics.print(
            ui.coloredText(),
            1 - val, 1 - val
          )
        elseif ui.text then
          love.graphics.printf(ui.text(), 1 - val, 1 - val, ui.w)
        end
      end)
    end
  end

  for _, child in ipairs(ui.children) do
    drawUI(child)
  end

  love.graphics.applyTransform(ui.transform:inverse())
end

--- Should be called at the start of love.draw
local function prepareFrame()
  love.graphics.scale(drawState.zoom)
end

---@param dt number
---@param lookingAt Vector
---@param magn number
---@param isAltCentering boolean
local function update(dt, lookingAt, magn, isAltCentering)
  local tileset = getTileset()

  drawState.battleTimer = (
    drawState.battleTimer + BATTLE_TIMER_SPEED * dt
  ) % 1

  drawState.waterTimer = (
    drawState.waterTimer + WATER_TIMER_SPEED * dt
  ) % (math.pi / 2)

  drawState.cursorTimer = (
    drawState.cursorTimer + CURSOR_TIMER_SPEED * dt
  ) % (math.pi * 2)

  local yOffset = isAltCentering and SCREEN_HEIGHT/magn/8 or 0
  local offset = vector.add(
    vector.scale(lookingAt, TILE_WIDTH), { x = 0, y = yOffset }
  )

  drawState.camera = vector.lerp3(
    drawState.camera,
    { x = offset.x, y = offset.y, z = magn },
    dt * CAMERA_LERP_SPEED
  )

  updateTileset(tileset, dt)
end

---@param pos Vector
local function recruitableHighlight(pos)
  local x = pos.x * TILE_WIDTH + TILE_WIDTH / 2
  local y = pos.y * TILE_HEIGHT + TILE_HEIGHT / 2

  withColor(1, 1, 1, 1, function ()
    love.graphics.circle('line', x, y, HIGHLIGHT_CIRCLE_RADIUS)
  end)

  withColor(1, 1, 1, 0.5, function ()
    love.graphics.circle('fill', x, y, HIGHLIGHT_CIRCLE_RADIUS)
  end)
end

---@param pos Vector
local function recruitCircle(pos, radius)
  -- Concentric circles
  for i = 1, radius + 2 do
    local alpha = 0.6 * (1 - (i / (2 + radius)) ^ 2)
    withColor(1, 1, 1, alpha, function ()
      love.graphics.circle(
        'line',
        pos.x * TILE_WIDTH + TILE_WIDTH / 2,
        pos.y * TILE_HEIGHT + TILE_HEIGHT / 2,
        (i - 0.5) * TILE_WIDTH
      )
    end)
  end

  -- Thicc outline

  withColor(1, 1, 1, 0.5, function ()
    withLineWidth(3, function ()
      love.graphics.circle(
        'line',
        pos.x * TILE_WIDTH + TILE_WIDTH / 2,
        pos.y * TILE_HEIGHT + TILE_HEIGHT / 2,
        radius * TILE_WIDTH
      )
    end)
  end)

  -- Actual circle
  love.graphics.circle(
    'line',
    pos.x * TILE_WIDTH + TILE_WIDTH / 2,
    pos.y * TILE_HEIGHT + TILE_HEIGHT / 2,
    radius * TILE_WIDTH
  )
end

---@param battle Battle
local function drawBattle(battle)
  local posX = battle.pos.x * TILE_WIDTH
  local posY = battle.pos.y * TILE_HEIGHT
  local tileset = getTileset()

  withColor(0, 0, 0, 0.5, function ()
    love.graphics.rectangle(
      'fill', posX, posY, TILE_WIDTH, TILE_HEIGHT
    )
  end)

  local isBlink = drawState.battleTimer % 1/4 < 1/16

  if not isBlink then
    local r = 0.5 + drawState.battleTimer / 2
    local g = 1 - drawState.battleTimer / 2
    local b = 0
    withColor(r, g, b, 1, function ()
      love.graphics.draw(
        tileset.tiles,
        tileset.quads.battle,
        posX, posY
      )
    end)
  end

  -- Round counter

  love.graphics.print(
    tostring(battle.round),
    posX + TILE_WIDTH / 4,
    posY + TILE_HEIGHT / 4 - battle.round * 2
  )
end

---@param pixie Pixie
local function drawPixie(pixie)
  withTransform(pixie.transform, function()
    -- Shadow
    withColor(0, 0, 0, 0.5, function ()
      love.graphics.ellipse('fill', 8, 16, 4, 1.5)
    end)

    withColor(0, 0, 0, 0.25, function ()
      love.graphics.ellipse('fill', 8, 16, 8, 3)
    end)

    -- Texture
    local r, g, b, a = unpack(pixie.color)
    withColor(r, g, b, a, function ()
      love.graphics.draw(pixie.texture, pixie.quad, 0, 0)
    end)
  end)
end

---@param guy Guy
local function drawGuy(guy)
  drawPixie(guy.pixie)
end

---@param text string
---@param pos Vector
---@param maxWidth integer
local function textAtTile(text, pos, maxWidth)
  love.graphics.printf(
    text,
    TILE_WIDTH * pos.x,
    TILE_HEIGHT * pos.y,
    TILE_WIDTH * maxWidth
  )
end

---@param pos Vector
local function drawHouse(pos)
  local tileset = getTileset()
  love.graphics.draw(
    tileset.tiles,
    tileset.quads.house,
    pos.x * TILE_WIDTH,
    pos.y * TILE_HEIGHT
  )
end

---@return number, number
local function getCursorCoords()
  local x, y = love.graphics.inverseTransformPoint(
    love.mouse.getPosition()
  )

  return math.floor(x / TILE_WIDTH), math.floor(y / TILE_HEIGHT)
end

---@param pos Vector
---@param isFocused boolean
local function drawCursor(pos, isFocused)
  local invSqrt2 = 1/math.sqrt(2)
  local mInvSqrt2 = 1 - invSqrt2

  -- Rotating square

  local transform = love.math.newTransform(
    pos.x * TILE_WIDTH + TILE_WIDTH / 2,
    pos.y * TILE_HEIGHT + TILE_HEIGHT / 2
  )
    :rotate(drawState.cursorTimer)
    :scale(mInvSqrt2 * math.cos(
      drawState.cursorTimer * 4 + 4 * math.pi/2
    ) / 2 + invSqrt2)
    :translate(-TILE_WIDTH/2, -TILE_HEIGHT/2)

  withTransform(transform, function ()
    love.graphics.rectangle(
      'line', 0, 0, TILE_WIDTH, TILE_HEIGHT
    )
  end)

  -- FOCUS text: four sides

  if isFocused then
    withTransform(transform:scale(1/2.5, 1/2.5), function ()
      love.graphics.print('FOCUS', 0, 48)
    end)
    for _ = 1, 3 do
      withTransform(transform:rotate(math.rad(90)):translate(0,-42), function ()
        love.graphics.print('FOCUS', 0, 48)
      end)
    end
  end
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

---@param time number
---@return { r: number, g: number, b: number }
local function skyColorAtTime(time)
  local length = #SKY_TABLE
  local offset, blendFactor = math.modf((time) / (24 * 60) * length)
  local colorA = SKY_TABLE[1 + (offset + 0) % length]
  local colorB = SKY_TABLE[1 + (offset + 1) % length]
  -- Blend colors together
  return {
    r = colorA.r + (colorB.r - colorA.r) * blendFactor,
    g = colorA.g + (colorB.g - colorA.g) * blendFactor,
    b = colorA.b + (colorB.b - colorA.b) * blendFactor,
  }
end

---@param game Game
---@param sky { r: number, b: number, g: number }
local function drawWorld(game, sky)
  local world = game.world
  local function index(x, y) return world.width * (y - 1) + x end

  ---@param visionSource VisionSource
  local function calcVisionDistance(visionSource)
    return math.floor(visionSource.sight * sky.g)
  end

  -- Reveal fog of war
  util.exhaust(game.visionSourcesCo, function (visionSource)
    local pos = visionSource.pos
    local visionDistance = calcVisionDistance(visionSource)
    local vd2 = visionDistance ^ 2
    local posX = pos.x
    local posY = pos.y
    for y = posY - visionDistance, posY + visionDistance do
      for x = posX - visionDistance, posX + visionDistance do
        local alpha = 1
        if isVisible(vd2, posX, posY, x, y) then
          -- Neighbor based shading
          for dy = -1, 1 do
            for dx = -1, 1 do
              if not isVisible(vd2, posX, posY, x + dx, y + dy) then
                alpha = alpha - 1/8
              end
            end
          end
        else
          alpha = 0
        end
        local idx = index(x,y)
        world.fogOfWar[idx] = math.max(alpha, world.fogOfWar[idx] or 0)
      end
    end
  end)

  local tileset = getTileset()
  local posX, posY = game.player.pos.x, game.player.pos.y
  local visionDistance = 21
  local voidTile = parallaxTile(0, 48, -drawState.camera.x/2, -drawState.camera.y/2)
  local waterPhase = 16 * math.sin(drawState.waterTimer)
  local waterTile = parallaxTile(48, 0, -waterPhase, waterPhase)

  for y = posY - visionDistance, posY + visionDistance do
    for x = posX - visionDistance, posX + visionDistance do
      local idx = index(x, y)
      local fog = world.fogOfWar[idx] or 0
      local tileType = world.tileTypes[idx] or 'void'
      local tile = tileset.quads[tileType]

      local function drawFragmentedTile(fragmentedTile)
        for _, fragment in ipairs(fragmentedTile) do
          withTransform(fragment.transform, function ()
            love.graphics.draw(
              tileset.tiles, fragment.quad, x * TILE_WIDTH, y * TILE_HEIGHT
            )
          end)
        end
      end

      withColor(sky.r, sky.g, sky.b, fog, function ()
        if tileType == 'void' then
          drawFragmentedTile(voidTile)
        elseif tileType == 'water' then
          drawFragmentedTile(waterTile)
        else
          love.graphics.draw(
            tileset.tiles, tile, x * TILE_WIDTH, y * TILE_HEIGHT
          )
        end
      end)
    end
  end
end

---@param game Game
local function drawGame(game)
  love.graphics.push('transform')

  -- Setup camera

  do
    local pos = {
      x = 8 + drawState.camera.x,
      y = 8 + drawState.camera.y
    }
    love.graphics.scale(drawState.camera.z)
    love.graphics.translate(
      math.floor(SCREEN_WIDTH / 2 / drawState.camera.z - pos.x),
      math.floor(SCREEN_HEIGHT / 2 / drawState.camera.z - pos.y)
    )
  end

  -- Draw visible terrain

  local colorOfSky = skyColorAtTime(game.time)
  drawWorld(game, colorOfSky)

  -- Draw in-game objects

  -- We keep this list so nothing renders twice
  local drawn = {}

  -- TODO: sort all visible objects before drawing
  local guysClone = tbl.iclone(game.guys)
  table.sort(guysClone, function (g1, g2)
    return g1.pos.y < g2.pos.y
  end)

  -- Draw lines between player and units
  for guy in pairs(game.squad.followers) do
    local guyHealth = guy.stats.hp / guy.stats.maxHp
    withColor(1, guyHealth, guyHealth, 0.5, function ()
      local playerX = game.player.pos.x * TILE_WIDTH + TILE_WIDTH / 2
      local playerY = game.player.pos.y * TILE_HEIGHT + TILE_HEIGHT
      local guyX = guy.pos.x * TILE_WIDTH + TILE_WIDTH / 2
      local guyY = guy.pos.y * TILE_HEIGHT + TILE_HEIGHT

      if not game.squad.shouldFollow then
        love.graphics.setColor(0.3, 0.3, 0.4, 0.5)
      end

      love.graphics.line(playerX, playerY, guyX, guyY)
      love.graphics.ellipse(
        'line',
        guy.pos.x * TILE_WIDTH + TILE_WIDTH / 2,
        guy.pos.y * TILE_HEIGHT + TILE_HEIGHT,
        TILE_WIDTH / 1.9,
        TILE_HEIGHT / 8
      )
    end)
  end

  -- Draw visible objects

  util.exhaust(game.visionSourcesCo, function (visionSource)
    local vd2 = (visionSource.sight * colorOfSky.b) ^ 2
    local posX = visionSource.pos.x
    local posY = visionSource.pos.y

    -- Draw texts

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

    -- Draw entities

    for _, entity in ipairs(game.entities) do
      if entity.type == 'building' then
        if not drawn[entity] and isVisible(
          vd2,
          posX, posY,
          entity.object.pos.x, entity.object.pos.y
        ) then
          drawHouse(entity.object.pos)
          drawn[entity] = true
        end
      elseif entity.type == 'battle' then
        local battle = entity.object
        if not drawn[entity] then
          drawBattle(battle)
          drawn[entity] = true
        end
      end
    end

    -- Draw guys

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
  end)

  -- Draw recruit circle

  if game.recruitCircle then
    recruitCircle(game.cursorPos, game.recruitCircle)
    for _, guy in tbl.ifilter(game.guys, function (guy)
      return game.mayRecruit(guy)
    end) do
      recruitableHighlight(guy.pos)
    end
  end

  -- Draw cursor

  local curX, curY = getCursorCoords()
  local curDistance = 12
  curX = math.min(game.player.pos.x + curDistance, curX)
  curX = math.max(game.player.pos.x - curDistance, curX)
  curY = math.min(game.player.pos.y + curDistance, curY)
  curY = math.max(game.player.pos.y - curDistance, curY)
  do
    local cursorPos = { x = curX, y = curY }
    local cursorColor = WHITE_CURSOR_COLOR

    if game.isFocused then
      cursorColor = YELLOW_COLOR
    else
      game.cursorPos = cursorPos
    end

    local collision = game.collider(nil, game.cursorPos)

    if collision.type == 'terrain' then
      cursorColor = RED_COLOR
    end

    local r, g, b, a = unpack(cursorColor)
    withColor(r, g, b, a, function ()
      drawCursor(game.cursorPos, game.isFocused)
    end)
  end

  love.graphics.pop()

  -- Draw UI

  drawUI(game.ui)

  -- Draw minimap

  withTransform(love.math.newTransform(8, SCREEN_HEIGHT - 16 - MINIMAP_SIZE), function ()
    local offsetX = game.player.pos.x - MINIMAP_SIZE / 2
    local offsetY = game.player.pos.y - MINIMAP_SIZE / 2
    local quad = love.graphics.newQuad(
      offsetX, offsetY,
      MINIMAP_SIZE, MINIMAP_SIZE,
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
        and pointX < MINIMAP_SIZE
        and pointY >= 0
        and pointY < MINIMAP_SIZE
      then
        withColor(color[1], color[2], color[3], 1, function ()
          love.graphics.rectangle('fill', pointX, pointY, 1, 1)
        end)
      end
    end

    -- Cursor
    withColor(1, 1, 1, 0.5, function ()
      love.graphics.rectangle('fill', curX - offsetX, curY - offsetY, 1, 1)
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
  getTileset = getTileset,
  init = init,
  prepareFrame = prepareFrame,
  recruitCircle = recruitCircle,
  recruitableHighlight = recruitableHighlight,
  setZoom = setZoom,
  update = update,
  textAtTile = textAtTile,
  house = drawHouse,
  getCursorCoords = getCursorCoords,
  cursor = drawCursor,
  drawGame = drawGame,
}