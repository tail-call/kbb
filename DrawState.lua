---State of the renderer
---@class DrawState: core.Object
---@field __module 'DrawState'
---# Properties
---@field windowScale number Window scale
---@field tileset Tileset Tileset used for drawing
---@field camera core.Vector3 Camera position in the world
---@field cursorTimer core.Timer Cursor animation timer
---@field battleTimer core.Timer Battle animation timer
---@field waterTimer core.Timer Water animation timer
---# Methods
---@field setWindowScale fun(self: DrawState, windowScale: number) Changes window scale
---@field setCamera fun(self: DrawState, offset: core.Vector, z: number, magn: number)
---@field nextFont fun(self: DrawState)

local lerp3 = require 'core.Vector3'.lerp3
local VectorModule = require 'core.Vector'
local updateTileset = require 'Tileset'.update

local TILE_WIDTH = require 'Draw'.TILE_WIDTH
local SCREEN_HEIGHT = 200

local CAMERA_LERP_SPEED = 10

local DrawState = Class {
  ...,
  ---@type DrawState
  index = {
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
    end,
    nextFont = function (self)
      self.isUsingBoldFont = not self.isUsingBoldFont
      love.graphics.setFont(
        require 'core.Font'.load(
          require 'res/cga8.png',
          8, 8,
          self.isUsingBoldFont
        )
      )
    end
  }
}

---@param obj DrawState
function DrawState.init(obj)
  local Timer = require 'core.Timer'.new
  obj.isUsingBoldFont = obj.isUsingBoldFont or false
  obj.windowScale = obj.windowScale or Global.defaultGraphicsScale
  obj.tileset = obj.tileset or require 'Tileset'.getTileset()
  obj.camera = obj.camera or { x = 266 * 16, y = 229 * 16, z = 0.01 }
  obj.cursorTimer = obj.cursorTimer or Timer {
    speed = 2,
    threshold = math.pi * 2,
  }
  obj.battleTimer = obj.battleTimer or Timer {
    speed = 2,
  }
  obj.waterTimer = obj.waterTimer or Timer {
    speed = 1/4,
  }
  obj:nextFont()
end

---@param drawState DrawState
---@param dt number
---@param lookingAt core.Vector
---@param magn number
---@param isAltCentering boolean
function DrawState.updateDrawState(drawState, dt, lookingAt, magn, isAltCentering)
  local yOffset = isAltCentering and SCREEN_HEIGHT/magn/8 or 0
  local offset = VectorModule.add(
    VectorModule.scale(lookingAt, TILE_WIDTH), { x = 0, y = yOffset }
  )

  drawState:setCamera(offset, dt, magn)
  updateTileset(drawState.tileset, dt)
end

return DrawState