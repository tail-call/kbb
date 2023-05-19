---State of the renderer
---@class DrawState
---@field __module 'DrawState'
---# Properties
---@field windowScale number Window scale
---@field tileset Tileset Tileset used for drawing
---@field camera Vector3 Camera position in the world
---@field cursorTimer number Cursor animation timer
---@field battleTimer number Battle animation timer
---@field waterTimer number Water animation timer
---# Methods
---@field setWindowScale fun(self: DrawState, windowScale: number) Changes window scale
---@field setCamera fun(self: DrawState, offset: Vector, z: number, magn: number)
---@field advanceTime fun(self: DrawState, dt: number) Advances draw-related timers

local lerp3 = require('Vector3').lerp3
local VectorModule = require('Vector')
local updateTileset = require('Tileset').update

local TILE_WIDTH = require('const').TILE_WIDTH
local SCREEN_HEIGHT = 200

local CURSOR_TIMER_SPEED = 2
local BATTLE_TIMER_SPEED = 2
local WATER_TIMER_SPEED = 1/4
local CAMERA_LERP_SPEED = 10


local M = require('Module').define{..., version = 0, metatable = {
  ---@type DrawState
  __index = {
    setWindowScale = function (self, windowScale)
      self.windowScale = windowScale

      self.tileset:regenerate()
    end,
    advanceTime = function (self, dt)
      self.battleTimer = (
        self.battleTimer + BATTLE_TIMER_SPEED * dt
      ) % 1

      self.waterTimer = (
        self.waterTimer + WATER_TIMER_SPEED * dt
      ) % (math.pi / 2)

      self.cursorTimer = (
        self.cursorTimer + CURSOR_TIMER_SPEED * dt
      ) % (math.pi * 2)
    end,
    setCamera = function (self, offset, dt, magn)
      self.camera = lerp3(
        self.camera,
        { x = offset.x, y = offset.y, z = magn },
        dt * CAMERA_LERP_SPEED
      )
    end
  }
}}

---@param drawState DrawState
function M.init(drawState)
  drawState.windowScale = drawState.windowScale or 3
  drawState.tileset = drawState.tileset or error('DrawState: tileset is required')
  drawState.camera = drawState.camera or { x = 266 * 16, y = 229 * 16, z = 0.01 }
  drawState.cursorTimer = drawState.cursorTimer or 0
  drawState.battleTimer = drawState.battleTimer or 0
  drawState.waterTimer = drawState.waterTimer or  0
end

---@param drawState DrawState
---@param dt number
---@param lookingAt Vector
---@param magn number
---@param isAltCentering boolean
function M.updateDrawState(drawState, dt, lookingAt, magn, isAltCentering)
  drawState:advanceTime(dt)

  local yOffset = isAltCentering and SCREEN_HEIGHT/magn/8 or 0
  local offset = VectorModule.add(
    VectorModule.scale(lookingAt, TILE_WIDTH), { x = 0, y = yOffset }
  )

  drawState:setCamera(offset, dt, magn)
  updateTileset(drawState.tileset, dt)
end

return M