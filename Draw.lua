local updateTileset = require('Tileset').update
local parallaxTile = require('Tileset').parallaxTile
local regenerateTileset = require('Tileset').regenerate
local tbl = require('tbl')
local Vector = require('Vector')
local withColor = require('util').withColor
local withLineWidth = require('util').withLineWidth
local withTransform = require('util').withTransform
local isFrozen = require('Game').isFrozen
local mayRecruit = require('Game').mayRecruit
local vectorToLinearIndex = require('World').vectorToLinearIndex
local skyColorAtTime = require('util').skyColorAtTime
local getFog = require('World').getFog

-- Constants

local SCREEN_WIDTH = 320
local SCREEN_HEIGHT = 200
local TILE_HEIGHT = 16
local TILE_WIDTH = 16
local MINIMAP_SIZE = 72
local HIGHLIGHT_CIRCLE_RADIUS = 10

local WHITE_CURSOR_COLOR = { 1, 1, 1, 0.8 }
local RED_COLOR = { 1, 0, 0, 0.8 }
local YELLOW_COLOR = { 1, 1, 0, 0.8 }

---@param drawState DrawState
---@param z number
local function setZoom(drawState, z)
  drawState:setWindowScale(z)
  local w, h = love.window.getMode()
  if w ~= SCREEN_WIDTH * z and h ~= SCREEN_WIDTH * z then
    love.window.setMode(SCREEN_WIDTH * z, SCREEN_HEIGHT * z)
  end

  regenerateTileset(drawState.tileset)
end

---@param drawState DrawState
local function init(drawState)
  setZoom(drawState, 3)
  return drawState
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
---@param drawState DrawState
local function prepareFrame(drawState)
  love.graphics.scale(drawState.windowScale)
end

---@param drawState DrawState
---@param dt number
---@param lookingAt Vector
---@param magn number
---@param isAltCentering boolean
local function update(drawState, dt, lookingAt, magn, isAltCentering)
  drawState:advanceTime(dt)

  local yOffset = isAltCentering and SCREEN_HEIGHT/magn/8 or 0
  local offset = Vector.add(
    Vector.scale(lookingAt, TILE_WIDTH), { x = 0, y = yOffset }
  )

  drawState:setCamera(offset, dt, magn)
  updateTileset(drawState.tileset, dt)
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
local function drawRecruitCircle(pos, radius)
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

---@param drawState DrawState
---@param battle Battle
local function drawBattle(drawState, battle)
  local posX = battle.pos.x * TILE_WIDTH
  local posY = battle.pos.y * TILE_HEIGHT

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
        drawState.tileset.tiles,
        drawState.tileset.quads.battle,
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
  local ambR, ambG, ambB, ambA = love.graphics.getColor()
  local _, _, _, h = pixie.quad:getViewport()
  local extraHeight = 16 - h
  local transform = pixie.transform:clone():translate(0, extraHeight)
  withTransform(transform, function()
    -- Shadow
    withColor(0, 0, 0, 0.5, function ()
      love.graphics.ellipse('fill', 8, 16 - extraHeight, 4, 1.5)
    end)

    withColor(0, 0, 0, 0.25, function ()
      love.graphics.ellipse('fill', 8, 16 - extraHeight, 8, 3)
    end)

    -- Texture
    local r, g, b, a = unpack(pixie.color)
    withColor(r * ambR, g * ambG, b * ambB, a * ambA, function ()
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

---@param tileset Tileset
---@param pos Vector
local function drawHouse(tileset, pos)
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

---@param drawState DrawState
---@param pos Vector
---@param isFocused boolean
---@param moves number
local function drawCursor(drawState, pos, isFocused, moves)
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

  transform
    :translate(TILE_WIDTH/2, TILE_HEIGHT/2)
    :rotate(-drawState.cursorTimer)
    :translate(-7.5, -TILE_HEIGHT/4)

  withTransform(transform, function ()
    love.graphics.print(
      ('%02d'):format(moves), 0, 0
    )
    if isFocused then
      love.graphics.print('FOCUS', -11, -16)
    end
  end)
end

---@param game Game
---@param drawState DrawState
---@param sky { r: number, b: number, g: number }
---@param globalLight number
local function drawWorld(game, drawState, sky, globalLight)
  local posX, posY = game.player.pos.x, game.player.pos.y
  local visionDistance = 21
  local voidTile = parallaxTile(0, 48, -drawState.camera.x/2, -drawState.camera.y/2)
  local waterPhase = 16 * math.sin(drawState.waterTimer)
  local waterTile = parallaxTile(48, 0, -waterPhase, waterPhase)

  local vec = { x = 0, y = 0 }
  for y = posY - visionDistance, posY + visionDistance do
    for x = posX - visionDistance, posX + visionDistance do
      vec.x = x
      vec.y = y

      local world = game.world
      local idx = vectorToLinearIndex(world, vec)
      local fog = world.fogOfWar[idx] or 0
      local tileType = world.tileTypes[idx] or 'void'
      local tile = drawState.tileset.quads[tileType]

      local function drawFragmentedTile(fragmentedTile)
        for _, fragment in ipairs(fragmentedTile) do
          withTransform(fragment.transform, function ()
            love.graphics.draw(
              drawState.tileset.tiles, fragment.quad, x * TILE_WIDTH, y * TILE_HEIGHT
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
            drawState.tileset.tiles, tile, x * TILE_WIDTH, y * TILE_HEIGHT
          )
        end
      end)
    end
  end
end

---@param game Game
---@param drawState DrawState
local function drawGame(game, drawState)
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
  drawWorld(game, drawState, colorOfSky, colorOfSky.g)

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

      if not game.squad.shouldFollow then
        love.graphics.setColor(0.3, 0.3, 0.4, 0.5)
      end

      local playerX, playerY = game.player.pixie.transform:transformPoint(8, 16)
      local guyX, guyY = guy.pixie.transform:transformPoint(8, 16)

      love.graphics.line(
        playerX, playerY,
        guyX, guyY
      )
      love.graphics.ellipse(
        'line',
        guyX,
        guyY,
        TILE_WIDTH / 1.9,
        TILE_HEIGHT / 8
      )
    end)
  end

  -- Draw visible objects

  ---@param obj { pos: Vector }
  local function cullAndShade(obj, cb)
    if drawn[obj] then return end
    drawn[obj] = true

    -- Is within screen?
    local ox, oy = obj.pos.x, obj.pos.y
    local px, py = game.player.pos.x, game.player.pos.y
    local d = 16

    if ox < px - d or ox > px + d or oy < py - d or oy > py + d then
      return
    end

    local fog = getFog(game.world, obj.pos)
    withColor(fog, fog, fog, 1, cb)
  end

  -- Draw texts

  for _, text in ipairs(game.texts) do
    cullAndShade(text, function ()
      textAtTile(text.text, text.pos, text.maxWidth)
    end)
  end

  -- Draw entities

  for _, entity in ipairs(game.entities) do
    if entity.type == 'building' then
      cullAndShade(entity.object, function ()
        drawHouse(drawState.tileset, entity.object.pos)
      end)
    elseif entity.type == 'battle' then
      local battle = entity.object
      cullAndShade(battle, function ()
        drawBattle(drawState, battle)
      end)
    end
  end

  -- Draw guys

  for _, guy in ipairs(guysClone) do
    if not isFrozen(game, guy) then
      cullAndShade(guy, function ()
        drawGuy(guy)
      end)
    end
  end

  -- Draw recruit circle

  if game.recruitCircle.radius then
    drawRecruitCircle(game.cursorPos, game.recruitCircle.radius)
    for _, guy in tbl.ifilter(game.guys, function (guy)
      return mayRecruit(game, guy)
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

    local collision = game:collider(game.cursorPos)

    if collision.type == 'terrain' then
      cursorColor = RED_COLOR
    end

    local r, g, b, a = unpack(cursorColor)
    withColor(r, g, b, a, function ()
      drawCursor(drawState, game.cursorPos, game.isFocused, game.player.stats.moves)
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
      local pointX = guy.pos.x - 1 - offsetX
      local pointY = guy.pos.y - 1 - offsetY
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
      for i, message in ipairs(game.console.messages) do
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
  init = init,
  prepareFrame = prepareFrame,
  recruitableHighlight = recruitableHighlight,
  setZoom = setZoom,
  update = update,
  textAtTile = textAtTile,
  house = drawHouse,
  getCursorCoords = getCursorCoords,
  cursor = drawCursor,
  drawGame = drawGame,
}