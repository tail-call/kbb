local updateDrawState = require 'DrawState'.updateDrawState
local Vector = require 'core.Vector'
local updateGame = require 'Game'.updateGame
local endRecruiting = require 'Game'.endRecruiting
local getTile = require 'World'.getTile

---@type Game
local game
---@type UIModel
local uiModel = {}
local ui = require 'ui.screen'(uiModel)
local alternatingKeyIndex = 1

local function saveGame()
  local file = io.open('./kobo2.kpss', 'w+')
  if file == nil then error('no file') end

  file:write('-- This is a Kobold Princess Simulator v0.4 savefile. You should not run it.\n')
  file:write('-- It was created at ' .. os.date() .. '\n')

  file:write(require 'core.Util'.dump(game))
  file:close()
end

---@param filename string
---@param loaders { [string]: function }
---@return fun()?, string? errorMessage
local function loadGame(filename, loaders)
  return require 'core.Util'.loadFileWithIndex(filename, function(t, k)
    return function(...)
      local loader = loaders[k]
      if loader ~= nil then
        return loader(...)
      else
        return require(k).new(...)
      end
    end
  end)
end

---@param time number
---@return { r: number, g: number, b: number }
local function skyColorAtTime(time)
  local skyTable = {
    { r = 0.3, g = 0.3, b = 0.6, }, -- 00:00
    { r = 1.0, g = 0.9, b = 0.8, }, -- 06:00
    { r = 1, g = 1, b = 1, },       -- 12:00
    { r = 1.0, g = 0.7, b = 0.7, }  -- 18:00
  }

  local length = #skyTable
  local offset, blendFactor = math.modf((time) / (24 * 60) * length)
  local colorA = skyTable[1 + (offset + 0) % length]
  local colorB = skyTable[1 + (offset + 1) % length]
  -- Blend colors together
  return {
    r = colorA.r + (colorB.r - colorA.r) * blendFactor,
    g = colorA.g + (colorB.g - colorA.g) * blendFactor,
    b = colorA.b + (colorB.b - colorA.b) * blendFactor,
  }
end

Tooltip(function ()
  if not game then
    return {}
  end

  local line1 = getTile(game.world, game.cursorPos) or '???'
  local line2 = Vector.formatVector(game.cursorPos)
  local entity = {}
  -- Detect entities under cursor
  for k, v in ipairs(game.entities) do
    if Vector.equal(v.pos, game.cursorPos) then
      entity = v
    end
  end

  local line3 = ''
  if entity.__module then
    local textGenerator = require(entity.__module).tooltipText or function (_)
      return 'nothing special'
    end
    line3 = textGenerator(entity)
  end

  return { line1, line2, line3 }
end)

OnLoad(function (savefileName)
  if savefileName == '#back' then
    return
  elseif savefileName == '#dontload' then
    game = require 'Game'.new {
      world = require 'World'.new(),
      resources = require 'Resources'.new(),
      squad = require 'Squad'.new(),
      recruitCircle = require 'RecruitCircle'.new(),
    }
  else
    local gameFunction, err = loadGame(savefileName, {
      quad = function (...)
        return love.graphics.newQuad(...)
      end,
      buf = function (props)
        local compressedData = love.data.decode('data', 'base64', props.base64)
        local data = love.data.decompress('string', 'zlib', compressedData)
        ---@cast data string
        local array = loadstring(data)()
        return array
      end,
    })
    game = gameFunction and gameFunction() or error(err)
  end
  uiModel.game = game
end)

OnUpdate(function (dt)
  local pv = game.player.pos
  local cv = game.cursorPos
  updateDrawState(
    DrawState,
    dt,
    game.mode == 'focus'
      and Vector.add(cv, { x = 0, y = 0 })
      or Vector.midpoint(pv, cv),
    game.mode == 'focus'
      and game.magnificationFactor * 2
      or game.magnificationFactor,
    game.mode == 'focus'
  )
  -- Handle diagonal movement
  local directions = {}
  for key, value in pairs(Vector.dir) do
    if love.keyboard.isDown(key) then
      table.insert(directions, value)
    end
  end

  if game.mode == 'paint' then
    if love.mouse.isDown(1) then
      require 'Game'.orderPaint(game)
    end
  elseif game.mode ~= 'focus' then
    if #directions > 0 then
      for _ = 1, #directions do
        local index = (alternatingKeyIndex + 1) % (#directions)
        alternatingKeyIndex = index

        local vec = directions[index + 1]

        if game.squad.shouldFollow then
          for guy in pairs(game.squad.followers) do
            if not require 'Game'.isFrozen(game, guy) then
              require 'Guy'.moveGuy(guy, vec, game.guyDelegate)
            end
          end
        end

        if not require 'Game'.isFrozen(game, game.player) then
          local oldPos = game.player.pos
          local newPos = require 'Guy'.moveGuy(
            game.player,
            vec,
            game.guyDelegate
          )
          if not Vector.equal(newPos, oldPos) then
            break
          end
        end
      end
    end
  end

  updateGame(game, dt, directions, skyColorAtTime(game.time).g)
end)

OnKeyPressed(function (key, scancode, isrepeat)
  if scancode == '8' then
    saveGame()
  elseif scancode == 'z' then
    game:nextMagnificationFactor()
  elseif scancode == 'tab' then
    uiModel:nextTab()
  elseif scancode == 'return' then
    require 'scene.console'.go(game)
  elseif scancode == 'space' then
    game:switchMode()
  elseif scancode == 'g' then
    require 'Game'.orderDismiss(game)
  elseif scancode == 'r' then
    require 'Game'.orderSummon(game)
  elseif scancode == 'f' then
    game.squad:toggleFollow()
  elseif scancode == 'b' then
    require 'Game'.orderBuild(game)
  end

  if game.mode == 'focus' then
    if require 'core.table'.has({ '1', '2', '3', '4' }, scancode) then
      DrawState:setWindowScale(tonumber(scancode) or 1)
    end
  elseif game.mode == 'normal' then
    if scancode == 'c' then
      require 'Game'.orderCollect(game)
    elseif scancode == 'e' then
      local patch = require 'World'.patchAt(game.world, game.player.pos)
      require 'World'.randomizePatch(game.world, patch)
    elseif scancode == 't' then
      game.player:warp(game.cursorPos)
    end
  end
end)

---@param x number
---@param y number
---@param button 1 | 2 | 3
---@param presses table
OnMousePressed(function (x, y, button, presses)
  if button == 1 then
    if game.mode == 'normal' then
      require 'Game'.beginRecruiting(game)
    end
  end
end)

---@param x number
---@param y number
---@param button 1 | 2 | 3
---@param presses table
OnMouseReleased(function (x, y, button, presses)
  if button == 1 then
    endRecruiting(game)
  end
end)

OnDraw(function ()
  require 'Draw'.drawGame(
    game,
    DrawState,
    ui,
    skyColorAtTime(game.time)
  )
end)