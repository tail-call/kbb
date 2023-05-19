---State of the renderer
---@class DrawState
---@field __module 'DrawState'
---# Properties
---@field windowScale number Window scale
---@field tileset Tileset Tileset used for drawing
---@field camera Vector3 Camera position in the world
---@field cursorTimer Timer Cursor animation timer
---@field battleTimer Timer Battle animation timer
---@field waterTimer Timer Water animation timer
---# Methods
---@field setWindowScale fun(self: DrawState, windowScale: number) Changes window scale
---@field setCamera fun(self: DrawState, offset: Vector, z: number, magn: number)

local lerp3 = require('Vector3').lerp3
local VectorModule = require('Vector')
local updateTileset = require('Tileset').update

local TILE_WIDTH = require('const').TILE_WIDTH
local SCREEN_HEIGHT = 200

local CAMERA_LERP_SPEED = 10

local M = require('Module').define{..., version = 0, metatable = {
  ---@type DrawState
  __index = {
    setWindowScale = function (self, windowScale)
      self.windowScale = windowScale

      self.tileset:regenerate()
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

---@param obj DrawState
function M.init(obj)
  obj.windowScale = obj.windowScale or 3
  obj.tileset = obj.tileset or error('DrawState: tileset is required')
  obj.camera = obj.camera or { x = 266 * 16, y = 229 * 16, z = 0.01 }
  obj.cursorTimer = obj.cursorTimer or require('Timer').new {
    speed = 2,
    threshold = math.pi * 2,
  }
  obj.battleTimer = obj.battleTimer or require('Timer').new {
    speed = 2,
  }
  obj.waterTimer = obj.waterTimer or require('Timer').new {
    speed = 1/4,
  }
end

---@param drawState DrawState
---@param dt number
---@param lookingAt Vector
---@param magn number
---@param isAltCentering boolean
function M.updateDrawState(drawState, dt, lookingAt, magn, isAltCentering)
  drawState.cursorTimer:advance(dt)
  drawState.battleTimer:advance(dt)
  drawState.waterTimer:advance(dt)

  local yOffset = isAltCentering and SCREEN_HEIGHT/magn/8 or 0
  local offset = VectorModule.add(
    VectorModule.scale(lookingAt, TILE_WIDTH), { x = 0, y = yOffset }
  )

  drawState:setCamera(offset, dt, magn)
  updateTileset(drawState.tileset, dt)
end

return M