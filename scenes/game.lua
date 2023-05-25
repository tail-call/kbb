local updateDrawState = require('DrawState').updateDrawState
local Vector = require('Vector')
local updateGame = require('Game').updateGame
local handleInput = require('Game').handleInput
local endRecruiting = require('Game').endRecruiting

---@type Game
local game
---@type DrawState
local drawState

---@param filename string
---@param loaders { [string]: function }
---@return fun()?, string? errorMessage
local function loadGame(filename, loaders)
  return require('Util').doFileWithIndex(filename, function(t, k)
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

OnLoad(function (savefileName)
  drawState = require('DrawState').new()

  if savefileName == '#back' then
    return
  elseif savefileName == '#dontload' then
    game = require('Game').new{}
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
end)

OnUpdate(function (dt)
  local pv = game.player.pos
  local cv = game.cursorPos
  updateDrawState(
    drawState,
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

  updateGame(game, dt, directions)
end)

OnKeyPressed(function (key, scancode, isrepeat)
  if scancode == '8' then
    -- Write to file
    local file = io.open('./kobo2.kpss', 'w+')
    if file == nil then error('no file') end

    file:write('-- This is a Kobold Princess Simulator v0.4 savefile. You should not run it.\n')
    file:write('-- It was created at ' .. os.date() .. '\n')

    file:write(require('Util').dump(game))
    file:close()
  elseif scancode == 'return' then
    require('Scene').loadScene('FocusScene', M)
  end

  handleInput(game, drawState, scancode, key)
end)

---@param x number
---@param y number
---@param button 1 | 2 | 3
---@param presses table
OnMousePressed(function (x, y, button, presses)
  if button == 1 then
    if game.mode == 'normal' then
      require('Game').beginRecruiting(game)
    elseif game.mode == 'paint' then
      require('Game').orderPaint(game)
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
  require('Draw').drawGame(game, drawState)
end)