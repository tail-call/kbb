local parallaxTile = require('Tileset').parallaxTile
local tbl = require('tbl')
local withColor = require('Util').withColor
local withLineWidth = require('Util').withLineWidth
local withTransform = require('Util').withTransform
local isFrozen = require('Game').isFrozen
local mayRecruit = require('Game').mayRecruit
local vectorToLinearIndex = require('World').vectorToLinearIndex
local getFog = require('World').getFog
local TILE_HEIGHT = require('const').TILE_HEIGHT
local TILE_WIDTH = require('const').TILE_WIDTH

-- Constants
local MINIMAP_SIZE = 72
local HIGHLIGHT_CIRCLE_RADIUS = 10

local WHITE_CURSOR_COLOR = { 1, 1, 1, 0.8 }
local RED_COLOR = { 1, 0, 0, 0.8 }
local YELLOW_COLOR = { 1, 1, 0, 0.8 }
local GREEN_COLOR = { 0, 1, 0, 0.8 }

local isUsingBoldFont = false

---@param drawState DrawState
---@param ui UI
local function drawUI(drawState, ui)
  if ui.shouldDraw and not ui.shouldDraw() then return end

  local transform = ui.transform(drawState)
  love.graphics.applyTransform(transform)

  if ui.type == 'none' then
    ---@cast ui UI
  elseif ui.type == 'panel' then
    ---@cast ui PanelUI
    local bg = (type(ui.background) == 'function')
      and ui.background()
      or ui.background

    local width, height = ui.w(drawState), ui.h(drawState)
    withColor(bg.r, bg.g, bg.b, bg.a, function ()
      love.graphics.rectangle('fill', 0, 0, width, height)
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
          love.graphics.printf(ui.text(), 1 - val, 1 - val, width)
        end
      end)
    end
  end

  for _, child in ipairs(ui.children) do
    drawUI(drawState, child)
  end

  love.graphics.applyTransform(transform:inverse())
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

  local isBlink = drawState.battleTimer.value % 1/4 < 1/16

  if not isBlink then
    local r = 0.5 + drawState.battleTimer.value / 2
    local g = 1 - drawState.battleTimer.value / 2
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
  -- Appearance
  drawPixie(guy.pixie)
  -- Health bar
  do
    local x, y = guy.pixie.transform:transformPoint(0, 0)
    local xOffset = guy.pixie.isFlipped and -16 or 0
    withColor(1, 0, 0, 1, function ()
      love.graphics.rectangle('fill', x + xOffset, y + 20, 16, 2)
    end)
    local width = 16 * guy.stats.hp / guy.stats.maxHp
    withColor(0, 1, 0, 1, function ()
      love.graphics.rectangle('fill', x + xOffset, y + 20, width, 2)
    end)
  end
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
---@param mode GameMode
---@param moves number
local function drawCursor(drawState, pos, mode, moves)
  local invSqrt2 = 1/math.sqrt(2)
  local mInvSqrt2 = 1 - invSqrt2

  -- Rotating square

  local transform = love.math.newTransform(
    pos.x * TILE_WIDTH + TILE_WIDTH / 2,
    pos.y * TILE_HEIGHT + TILE_HEIGHT / 2
  )
    :rotate(drawState.cursorTimer.value)
    :scale(mInvSqrt2 * math.cos(
      drawState.cursorTimer.value * 4 + 4 * math.pi/2
    ) / 2 + invSqrt2)
    :translate(-TILE_WIDTH/2, -TILE_HEIGHT/2)

  withTransform(transform, function ()
    love.graphics.rectangle(
      'line', 0, 0, TILE_WIDTH, TILE_HEIGHT
    )
  end)

  transform
    :translate(TILE_WIDTH/2, TILE_HEIGHT/2)
    :rotate(-drawState.cursorTimer.value)
    :translate(-7.5, -TILE_HEIGHT/4)

  withTransform(transform, function ()
    love.graphics.print(
      ('%02d'):format(moves), 0, 0
    )
    love.graphics.print(mode, -11, -16)
  end)
end

---@param observerPos Vector
---@param world World
---@param drawState DrawState
---@param sky { r: number, b: number, g: number }
local function drawTerrain(observerPos, world, drawState, sky)
  local posX, posY = observerPos.x, observerPos.y
  local visionDistance = 21
  local voidTile = parallaxTile(0, 48, -drawState.camera.x/2, -drawState.camera.y/2)
  local waterPhase = 16 * math.sin(drawState.waterTimer.value)
  local waterTile = parallaxTile(48, 0, -waterPhase, waterPhase)

  local vec = { x = 0, y = 0 }
  for y = posY - visionDistance, posY + visionDistance do
    for x = posX - visionDistance, posX + visionDistance do
      vec.x = x
      vec.y = y

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

---@param drawState DrawState
---@param tooltips fun(): string[]
local function drawPointer(drawState, tooltips)
  local x, y = love.mouse.getPosition()
  x = x / drawState.windowScale
  y = y / drawState.windowScale

  love.graphics.draw(
    drawState.tileset.image,
    drawState.tileset.quads.pointer,
    x, y
  )

  -- Tooltip

  if not tooltips then
    return
  end

  local tooltipTransform = love.math.newTransform()
    :translate(x + 10, y)
    :scale(2/3, 2/3)

  withTransform(tooltipTransform, function ()
    withColor(0, 0, 0, 0.5, function ()
      local width, height = 72, 72
      love.graphics.rectangle('fill', 0, 0, width, height)
    end)
    love.graphics.print(tooltips()[1] or '')
    love.graphics.print(tooltips()[2] or '', 0, 8)
    love.graphics.print(tooltips()[3] or '', 0, 16)
  end)
end

---@param game Game
---@param drawState DrawState
---@param ui UI
---@param ambientColor { r: number, g: number, b: number }
local function drawGame(game, drawState, ui, ambientColor)
  love.graphics.scale(drawState.windowScale)
  love.graphics.push('transform')

  -- Setup camera

  local screenW, screenH = love.window.getMode()
  screenW = screenW / drawState.windowScale
  screenH = screenH / drawState.windowScale
  do
    local pos = {
      x = 8 + drawState.camera.x,
      y = 8 + drawState.camera.y
    }
    love.graphics.scale(drawState.camera.z)
    love.graphics.translate(
      math.floor(screenW / 2 / drawState.camera.z - pos.x),
      math.floor(screenH / 2 / drawState.camera.z - pos.y)
    )
  end

  -- Draw visible terrain

  drawTerrain(game.player.pos, game.world, drawState, ambientColor)

  -- Draw patch highlight
  if game.mode == 'paint' then
    withColor(0, 0, 0, 1, function ()
      local patchWidth, patchHeight = 8 * TILE_WIDTH, 8 * TILE_HEIGHT
      local patch = require('World').patchAt(game.world, game.player.pos)
      love.graphics.rectangle(
        'line',
        patch.coords.x * patchWidth,
        patch.coords.y * patchHeight,
        patchWidth,
        patchHeight
      )
      love.graphics.print(
        patch.name,
        patch.coords.x * patchWidth,
        patch.coords.y * patchHeight
      )
    end)
  end

  -- Draw in-game objects

  -- We keep this list so nothing renders twice
  local drawn = {}

  -- Draw lines between player and units
  for entity in pairs(game.squad.followers) do
    if entity.__module == 'Guy' then
      ---@cast entity Guy
      local guyHealth = entity.stats.hp / entity.stats.maxHp
      withColor(1, guyHealth, guyHealth, 0.5, function ()

        if not game.squad.shouldFollow then
          love.graphics.setColor(0.3, 0.3, 0.4, 0.5)
        end

        local playerX, playerY = game.player.pixie.transform:transformPoint(8, 16)
        local guyX, guyY = entity.pixie.transform:transformPoint(8, 16)

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

  -- Draw entities

  local entities = tbl.iclone(game.entities)
  table.sort(entities, function (g1, g2)
    return g1.pos.y < g2.pos.y
  end)

  for _, entity in ipairs(entities) do
    if entity.__module == 'Building' then
      ---@cast entity Building
      cullAndShade(entity, function ()
        drawHouse(drawState.tileset, entity.pos)
      end)
    elseif entity.__module == 'Battle' then
      ---@cast entity Battle
      cullAndShade(entity, function ()
        drawBattle(drawState, entity)
      end)
    elseif entity.__module == 'Text' then
      ---@cast entity Text
      cullAndShade(entity, function ()
        textAtTile(entity.text, entity.pos, entity.maxWidth)
      end)
    elseif entity.__module == 'Guy' then
      ---@cast entity Guy
      if not isFrozen(game, entity) then
        cullAndShade(entity, function ()
          drawGuy(entity)
        end)
      end
    end
  end

  -- Draw recruit circle

  if game.recruitCircle.radius then
    drawRecruitCircle(game.cursorPos, game.recruitCircle.radius)
    for _, guy in tbl.ifilter(game.entities, function (entity)
      return mayRecruit(game, entity)
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

    if game.mode == 'focus' then
      cursorColor = YELLOW_COLOR
    elseif game.mode == 'paint' then
      cursorColor = GREEN_COLOR
      game.cursorPos = cursorPos
    elseif game.mode == 'normal' then
      game.cursorPos = cursorPos
    end

    local collision = game.guyDelegate.collider(game.cursorPos)

    if collision.type == 'terrain' then
      cursorColor = RED_COLOR
    end

    local r, g, b, a = unpack(cursorColor)
    withColor(r, g, b, a, function ()
      drawCursor(drawState, game.cursorPos, game.mode, game.player.stats.moves)
    end)
  end

  love.graphics.pop()

  -- Draw UI

  drawUI(drawState, ui)

  -- Draw minimap

  withTransform(love.math.newTransform(8, screenH - 16 - MINIMAP_SIZE), function ()
    local offsetX = game.player.pos.x - MINIMAP_SIZE / 2
    local offsetY = game.player.pos.y - MINIMAP_SIZE / 2

    local quad = love.graphics.newQuad(
      offsetX, offsetY,
      MINIMAP_SIZE, MINIMAP_SIZE,
      game.world.image:getWidth(),
      game.world.image:getHeight()
    )

    local alpha = (game.mode == 'focus') and 1 or 0.25

    -- Overlay
    withColor(1, 1, 1, alpha, function ()
      love.graphics.draw(game.world.image, quad, 0, 0)
      love.graphics.print('R A D A R', 0, -8)
      love.graphics.setColor(0, 0, 0, 0.25)
      love.graphics.print('    N    ', 0, 0)
      love.graphics.print('W       E', 0, 32)
      love.graphics.print('    S    ', 0, 64)
    end)

    -- Entities
    for _, entity in ipairs(game.entities) do
      local color = { 0.5, 0.5, 0.5, 1 }
      if entity.__module == 'Guy' then
        ---@cast entity Guy
        color = entity.pixie.color
      end
      local pointX = entity.pos.x - 1 - offsetX
      local pointY = entity.pos.y - 1 - offsetY
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

    -- Console messages
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

local function nextFont()
  isUsingBoldFont = not isUsingBoldFont
  love.graphics.setFont(
    require('Util').loadFont(
      require('res/cga8.png'),
      8, 8,
      isUsingBoldFont
    )
  )
end

return {
  drawGame = drawGame,
  drawUI = drawUI,
  nextFont = nextFont,
  drawPointer = drawPointer,
}