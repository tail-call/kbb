local M = require('Module').define(..., 0)

local setWindowScale = require('DrawState').mut.setWindowScale

local updateDrawState = require('DrawState').updateDrawState
local Vector = require('Vector')
local updateGame = require('Game').updateGame
local handleText = require('Game').handleText
local tbl = require('tbl')
local handleInput = require('Game').handleInput
local beginRecruiting = require('Game').beginRecruiting
local endRecruiting = require('Game').endRecruiting

---@type Game
local game
---@type DrawState
local drawState

---@param filename string
---@param loaders { [string]: function }
---@return fun()?, string? errorMessage
local function loadGame(filename, loaders)
  local saveGameFunction, compileError = loadfile(filename)
  if saveGameFunction == nil then
    return nil, compileError
  end

  local moduleLoader = {}
  setmetatable(moduleLoader, { __index = function(t, k)
    return function(...)
      local loader = loaders[k]
      if loader ~= nil then
        return loader(...)
      else
        return require(k).new(...)
      end
    end
  end })
  setfenv(saveGameFunction, moduleLoader)
  return saveGameFunction
end

---@param savefileName string
function M.load(savefileName)
  local tileset = require('Tileset').getTileset()
  drawState = require('DrawState').new({ tileset = tileset })
  local gameFunction = loadGame(savefileName, {
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
  game = gameFunction
    and gameFunction()
    or require('Game').new {}
end

---@param dt number
function M.update(dt)
  local pv = game.player.pos
  local cv = game.cursorPos
  updateDrawState(
    drawState,
    dt,
    game.isFocused
      and Vector.add(cv, { x = 0, y = 0 })
      or Vector.midpoint(pv, cv),
    game.isFocused
      and game.magnificationFactor * 2
      or game.magnificationFactor,
    game.isFocused
  )
  -- Handle diagonal movement
  local directions = {}
  for key, value in pairs(Vector.dir) do
    if love.keyboard.isDown(key) then
      table.insert(directions, value)
    end
  end

  updateGame(game, dt, directions)
end

---@param text string
function M.textinput(text)
  handleText(game, text)
end

---@param key love.KeyConstant
---@param scancode love.Scancode
---@param isrepeat boolean
function M.keypressed(key, scancode, isrepeat)
  if tbl.has({ '1', '2', '3', '4' }, scancode) then
    setWindowScale(drawState, tonumber(scancode) or 1)
  end

  if scancode == '8' then
    -- Write to file
    do
      local file = io.open('./kobo2.kpss', 'w+')
      if file == nil then error('no file') end

      file:write('-- This is a Kobold Princess Simulator v0.2 savefile. You should not run it.\n')
      file:write('-- It was created at ' .. os.date() .. '\n')
      file:write('return ')
      
      file:write(require('Util').dump(game))
      file:close()
    end
  end

  handleInput(game, scancode, key)
end

---@param x number
---@param y number
---@param button 1 | 2 | 3
---@param presses table
function M.mousepressed(x, y, button, presses)
  if button == 1 then
    beginRecruiting(game)
  end
end

---@param x number
---@param y number
---@param button 1 | 2 | 3
---@param presses table
function M.mousereleased(x, y, button, presses)
  if button == 1 then
    endRecruiting(game)
  end
end

function M.draw()
  require('Draw').prepareFrame(drawState)
  require('Draw').drawGame(game, drawState)
end

return M