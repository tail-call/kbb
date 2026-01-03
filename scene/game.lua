local updateDrawState = require 'DrawState'.updateDrawState
local Vector = require 'core.Vector'
local updateGame = require 'Game'.updateGame
local endRecruiting = require 'Game'.endRecruiting
local orderMove = require 'Game'.orderMove

---@type Game
local game
---@type UIModel
local uiModel = {}
local ui = require 'ui.hud'(uiModel)
local alternatingKeyIndex = 1

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
  if not game or game.mode ~= 'edit' then
    return {}
  end

  local line1
  if game.mode == 'edit' then
    line1 = 'C=' .. game.painterTile
  else
    line1 = game.world:getTile(game.cursorPos) or '???'
  end

  local line2 = Vector.formatVector(game.cursorPos)
  local entity = {}
  -- Detect entities under cursor
  for _, v in ipairs(game.entities) do
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
  elseif savefileName == '#new' then
    game = require 'Game'.new {
      world = require 'World'.new(),
      resources = require 'Resources'.new(),
      squad = require 'Squad'.new(),
      recruitCircle = require 'RecruitCircle'.new(),
    }
  else
    local loadGame, err = require 'core.class'
      .loadObject(savefileName)
    game = loadGame and loadGame() or error(err)
  end
  uiModel.game = game
end)

OnUpdate(function (dt)
  local pv = game.player and game.player.pos or Global.leaderSpawnLocation
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

  if game.mode == 'edit' then
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
            if not game:isFrozen(guy) then
              require 'Guy'.moveGuy(guy, vec, game.guyDelegate)
            end
          end
        end

        if game.player and not game:isFrozen(game.player) then
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

---@class Keymap
---@field bindings table
---@field handleScancode fun(self: Keymap, scancode: string)

---@param bindings table
---@return Keymap
local function Keymap(bindings)
  return {
    bindings = bindings,
    handleScancode = function(self, scancode)
      local handler = self.bindings[scancode]

      if handler == nil then
        return
      end

      if type(handler) ~= "function" then
        error(string.format(
          "handleScancode: handler for scancode %s is not a function",
          scancode
        ))
      end
      
      handler()
    end,
  }
end

local selectNextTile = require 'World'.makeTileTypesIterator()

local commonKeyPressMap = Keymap {
  ['8'] = function()
    require 'core.class'.saveObject(game, './kobo2.kpss')
  end,
  ['z'] = function()
    game:nextMagnificationFactor()
  end,
  ['tab'] = function()
    uiModel:nextTab()
  end,
  ['return'] = function()
    require 'scene.console'.go(game)
  end,
  ['space'] = function()
    game:switchMode()
  end,
  ['g'] = function()
    require 'Game'.orderDismiss(game)
  end,
  ['r'] = function()
    require 'Game'.orderSummon(game)
  end,
  ['f'] = function()
    game.squad:toggleFollow()
  end,
  ['b'] = function()
    require 'Game'.orderBuild(game)
  end,
  ['c'] = function()
    game.painterTile = selectNextTile()
  end,
}

local CONTROLS = {
  SCALE1 = '1',
  SCALE2 = '2',
  SCALE3 = '3',
  SCALE4 = '4',
  COLLECT = 'c',
  WONDER = 'e',
  WARP = 't',
}

OnKeyPressed(function (key, scancode, isrepeat)
  commonKeyPressMap:handleScancode(scancode)

  if game.mode == 'focus' then
    if require 'core.table'.has({
      CONTROLS.SCALE1,
      CONTROLS.SCALE2,
      CONTROLS.SCALE3,
      CONTROLS.SCALE4
    }, scancode) then
      DrawState:setWindowScale(tonumber(scancode) or 1)
    end
  elseif game.mode == 'normal' then
    if scancode == CONTROLS.COLLECT then
      require 'Game'.orderCollect(game)
    elseif scancode == CONTROLS.WONDER then
      local patch = require 'World'.patchAt(game.world, game.player.pos)
      require 'World'.randomizePatch(game.world, patch)
    elseif scancode == CONTROLS.WARP then
      game.player:warp(game.cursorPos)
    end
  end
end)

---@param x number
---@param y number
---@param button 1 | 2 | 3
---@param presses table
OnMousePressed(function (x, y, button, presses)
  if button == 1 and not DrawState.hitPanel then
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
    if DrawState.hitPanel then
      DrawState.hitPanel.action()
    end

    endRecruiting(game)
  elseif button == 2 then
    orderMove(game)
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