---@class GameBlueprint
---@field world World Game world
---@field resources Resources Resources player may spend on upgrades
---@field texts Text[] Text objects in the game world
---@field entities GameEntity[] Things in the game world
---@field deathsCount number Number of times player has died
---@field guys Guy[] Guys aka units
---@field score integer Score the player has accumulated
---@field time number Time of day in seconds, max is 24*60
---@field cursorPos Vector Points to a square player's cursor is aimed at
---@field magnificationFactor number How much the camera is zoomed in

---@class Game: GameBlueprint
---
---# Simulation
---
---@field advanceClock fun(self: Game, dt: number) Advances in-game clock
---
---@field addScore fun(self: Game, count: integer) Increases score count
---
---@field squad Squad A bunch of guys that follows player's movement
---
---@field player Guy A guy controlled by the player
---@field guyDelegate GuyDelegate Object that talks to guys
---@field frozenGuys { [Guy]: true } Guys that should be not rendered and should not behave
---@field addGuy fun(self: Game, guy: Guy) Adds a guy into the world
---@field setGuyFrozen fun(self: Game, guy: Guy, state: boolean) Unfreezes a guy
---@field removeGuy fun(self: Game, guy: Guy) Removes the guy from the game
---
---@field addText fun(self: Game, text: Text) Adds the text in the game world
---@field addEntity fun(self: Game, entity: GameEntity) Adds a building to the world
---@field removeEntity fun(self: Game, entity: GameEntity) Adds a building to the world
---@field beginBattle fun(self: Game, attacker: Guy, defender: Guy): nil
---
---@field collider fun(self: Game, v: Vector): CollisionInfo Function that performs collision checks between game world objects
---
---# Game flow
---
---@field isFocused boolean True if focus mode is on
---
---@field toggleFocus fun(self: Game) Toggles focus mode
---@field disableFocus fun(self: Game) Turns focus mode off
---
---# UI
---
---@field ui UI User interface root
---@field uiModel UIModel GUI state
---@field alternatingKeyIndex integer Diagonal movement reader head index
---@field setAlternatingKeyIndex fun(self: Game, x: number) Moves diagonam movement reader head to a new location
---
---@field recruitCircle RecruitCircle Circle thing used to recruit units
---
---# GFX
---
---@field makeVisionSourcesCo fun(self: Game): fun(): VisionSource Returns a coroutine function that will yield all vision sources in the game world
---@field fogOfWarTimer number
---
---@field nextMagnificationFactor fun(self: Game) Switches magnification factor to a different one

local canRecruitGuy = require('Guy').canRecruitGuy
local moveGuy = require('Guy').moveGuy
local warpGuy = require('Guy').warpGuy
local updateGuy = require('Guy').updateGuy
local setTile = require('World').setTile
local getTile = require('World').getTile
local isPassable = require('World').isPassable
local tbl = require('tbl')
local Vector = require('Vector')
local maybeDrop = require('tbl').maybeDrop
local updateConsole = require('Console').updateConsole
local isRecruitCircleActive = require('RecruitCircle').isRecruitCircleActive
local isGuyAFollower = require('Squad').isGuyAFollower
local makeGuyDelegate = require('GuyDelegate').makeGuyDelegate
local revealFogOfWar = require('World').revealFogOfWar
local skyColorAtTime = require('Util').skyColorAtTime
local exhaust = require('Util').exhaust
local behave = require('Guy').behave
local makeBufDumper = require('Util').makeBufDumper

local addMoves = require('GuyStats').mut.addMoves
local updateBattle = require('Battle').updateBattle
local say = require('Console').mut.say
local resetRecruitCircle = require('RecruitCircle').mut.resetRecruitCircle
local clearRecruitCircle = require('RecruitCircle').mut.clearRecruitCircle
local growRecruitCircle = require('RecruitCircle').mut.growRecruitCircle
local addResources = require('Resources').mut.addResources
local addToSquad = require('Squad').mut.addToSquad
local removeFromSquad = require('Squad').mut.removeFromSquad
local startFollowing = require('Squad').mut.startFollowing
local toggleFollow = require('Squad').mut.toggleFollow

local addListener = require('Mutator').mut.addListener

---@type Vector
local EVIL_SPAWN_LOCATION = { x = 301, y = 184 }
---@type Vector
local LEADER_SPAWN_LOCATION = { x = 269, y = 231 }

local SCORES_TABLE = {
  killedAnEnemy = 100,
  builtAHouse = 500,
}

local MOVE_COSTS_TABLE = {
  dismissSquad = 1,
  summon = 25,
  build = 50,
}

local BUILDING_COST = 5
local FOG_OF_WAR_TIMER_LIMIT = 1/3

---@type CollisionInfo
local NONE_COLLISION = { type = 'none' }
---@type CollisionInfo
local TERRAIN_COLLISION = { type = 'terrain' }

---Returns true if guy is marked as frozen
---@param game Game
---@param guy Guy
---@return boolean
local function isFrozen(game, guy)
  return game.frozenGuys[guy] or false
end

---@param game Game
---@param pos Vector
---@return Guy | nil
local function findGuyAtPos(game, pos)
  return tbl.find(game.guys, function (guy)
    return Vector.equal(guy.pos, pos)
  end)
end

---@param game Game
---@param pos Vector
---@return GameEntity | nil
local function findEntityAtPos(game, pos)
  return tbl.find(game.entities, function (entity)
    return Vector.equal(entity.object.pos, pos)
  end)
end

---@param game Game
local function makeUIScript(game)
  local TRANSPARENT_PANEL_COLOR = { r = 0, g = 0, b = 0, a = 0 }
  local GRAY_PANEL_COLOR = { r = 0.5, g = 0.5, b = 0.5, a = 1 }
  local DARK_GRAY_PANEL_COLOR = { r = 0.25, g = 0.25, b = 0.25, a = 1 }

  local model = game.uiModel

  local UIModule = require('UI')
  local makePanel = UIModule.makePanel
  local origin = UIModule.origin

  ---@param drawState DrawState
  local function fullWidth(drawState)
    local sw, _ = love.window.getMode()
    return sw / drawState.windowScale
  end

  ---@param drawState DrawState
  local function fullHeight(drawState)
    local _, sh = love.window.getMode()
    return sh / drawState.windowScale
  end

  local function fixed(x)
    return function () return x end
  end

  return UIModule.new({}, {
    ---@type PanelUI
    makePanel({
      background = GRAY_PANEL_COLOR,
      transform = function () return origin() end,
      w = fullWidth,
      h = fixed(8),
      coloredText = require('UIModel').topPanelText(game)
    }),
    -- Left panel
    makePanel({
      shouldDraw = model.shouldDrawFocusModeUI,
      background = GRAY_PANEL_COLOR,
      transform = function ()
        return origin():translate(0, 8)
      end,
      w = fixed(88),
      h = fullHeight,
      text = model.leftPanelText,
    }),
    -- Empty underlay for console
    makePanel({
      shouldDraw = model.shouldDrawFocusModeUI,
      background = DARK_GRAY_PANEL_COLOR,
      transform = function (drawState)
        return origin():translate(88, fullHeight(drawState) - 60)
      end,
      w = fixed(240),
      h = fixed(52),
    }),
    -- Right panel
    makePanel({
      background = TRANSPARENT_PANEL_COLOR,
      transform = function (drawState)
        return origin():translate(fullWidth(drawState)-88, 8)
      end,
      w = fixed(88),
      h = fixed(128),
      text = model.rightPanelText,
    }),
    -- Bottom panel
    makePanel({
      background = GRAY_PANEL_COLOR,
      transform = function (drawState)
        return origin():translate(0, fullHeight(drawState) - 8)
      end,
      w = fullWidth,
      h = fixed(8),
      text = model.bottomPanelText,
    }),
    -- Command line
    makePanel({
      shouldDraw = model.shouldDrawFocusModeUI,
      background = TRANSPARENT_PANEL_COLOR,
      transform = function (drawState)
        return origin():translate(96, fullHeight(drawState) - 76)
      end,
      w = fixed(200),
      h = fullHeight,
      text = model.promptText,
    }),
  })
end

---@param bak GameBlueprint?
---@return Game
local function new(bak)
  local Guy = require('Guy')
  bak = bak or {}

  local tileset = require('Tileset').getTileset()
  ---@type Game
  local game

  ---@type Guy[]
  local guys = bak.guys or {
    Guy.makeLeader(tileset, LEADER_SPAWN_LOCATION),
    Guy.makeGoodGuy(tileset, { x = 274, y = 231 }),
    Guy.makeGoodGuy(tileset, { x = 272, y = 231 }),
    Guy.makeGoodGuy(tileset, { x = 274, y = 229 }),
    Guy.makeGoodGuy(tileset, { x = 272, y = 229 }),
  }

  ---@type Game
  game = {
    -- TODO: use load param
    world = require('World').new(bak.world or {}),
    score = bak.score or 0,
    frozenGuys = tbl.weaken({}, 'k'),
    -- TODO: use load param
    resources = require('Resources').new(bak.resources or {}),
    guys = guys,
    time = bak.time or (12 * 60),
    entities = bak.entities or {},
    deathsCount = bak.deathsCount or 0,
    alternatingKeyIndex = 1,
    player = guys[1],
    squad = require('Squad').new {},
    recruitCircle = require('RecruitCircle').new {},
    fogOfWarTimer = 0,
    cursorPos = bak.cursorPos or { x = 0, y = 0 },
    magnificationFactor = bak.magnificationFactor or 1,
    isFocused = false,
    texts = bak.texts or {},
    makeVisionSourcesCo = function (self)
      return function ()
        coroutine.yield({ pos = self.player.pos, sight = 10 })

        return {
          pos = self.cursorPos,
          sight = math.max(2, self.recruitCircle.radius or 0),
        }
      end
    end,
    collider = function(self, v)
      local someoneThere = findGuyAtPos(self, v)
      if someoneThere then
        return { type = 'guy', guy = someoneThere }
      end
      local someEntityThere = findEntityAtPos(self, v)
      if someEntityThere then
        return { type = 'entity', entity = someEntityThere }
      end
      if isPassable(self.world, v) then
        return NONE_COLLISION
      end
      return TERRAIN_COLLISION
    end,

    -- Methods

    addScore = function(self, count)
      self.score = self.score + count
    end,
    removeGuy = function (self, guy)
      maybeDrop(self.guys, guy)
      removeFromSquad(self.squad, guy)
      self.frozenGuys[guy] = nil

      local tile = getTile(game.world, guy.pos)

      if guy.team == 'evil' then
        if tile == 'sand' then
          setTile(game.world, guy.pos, 'grass')
        elseif tile == 'grass' then
          setTile(game.world, guy.pos, 'forest')
        elseif tile == 'forest' then
          setTile(game.world, guy.pos, 'water')
        end
      elseif guy.team == 'good' then
        if tile == 'sand' then
          setTile(game.world, guy.pos, 'rock')
        else
          setTile(game.world, guy.pos, 'sand')
        end
      end
    end,
    addText = function (self, text)
      table.insert(self.texts, text)
    end,
    addEntity = function (self, entity)
      table.insert(self.entities, entity)
    end,
    toggleFocus = function (self)
      self.isFocused = not self.isFocused
    end,
    disableFocus = function (self)
      self.isFocused = false
    end,
    removeEntity = function (self, entity)
      local idx = tbl.indexOf(self.entities, entity)
      table.remove(self.entities, idx)
    end,
    setGuyFrozen = function (self, guy, state)
      self.frozenGuys[guy] = state or nil
    end,
    advanceClock = function (self, dt)
      self.time = (self.time + dt) % (24 * 60)
      self.fogOfWarTimer = self.fogOfWarTimer + dt
      if self.fogOfWarTimer > FOG_OF_WAR_TIMER_LIMIT then
        self.fogOfWarTimer = self.fogOfWarTimer % FOG_OF_WAR_TIMER_LIMIT
      end
    end,
    nextMagnificationFactor = function (self)
      if self.magnificationFactor == 1 then
        self.magnificationFactor = 2/3
      elseif self.magnificationFactor == 2/3 then
        self.magnificationFactor = 2
      else
        self.magnificationFactor = 1
      end
    end,
    addGuy = function (self, guy)
      table.insert(self.guys, guy)
    end,
    beginBattle = function (self, attacker, defender)
      self:setGuyFrozen(attacker, true)
      self:setGuyFrozen(defender, true)

      self:addEntity(
        require('GameEntity').makeBattleEntity(
          require('Battle').new {
          attacker = attacker, defender = defender
        })
      )
    end,
    setAlternatingKeyIndex = function (self, x)
      self.alternatingKeyIndex = x
    end,
    -- TODO: move this outta here
    serialize1 = function (self)
      ---@cast self Game
      local dump = require('Util').dump

      game.world.fogOfWar.__dump = makeBufDumper(game.world.fogOfWar, '%.3f,')
      game.world.tileTypes.__dump = makeBufDumper(game.world.tileTypes, '%q,')

      return {[[
        -- This is a Kobold Princess Simulator v0.2 savefile. You shouldn't run it.
        -- It was created at ]],os.date(),[[
        
        return Game{
          time = ]],tostring(self.time),[[,
          score = ]],tostring(self.score),[[,
          deathsCount = ]],tostring(self.deathsCount),[[,
          guys = ]],dump(self.guys),[[,
          magnificationFactor = ]],tostring(self.magnificationFactor),[[,
          world = ]],dump(self.world),[[,
          texts = ]],dump(self.texts),[[,
          entities = ]],dump(self.entities),[[,
          resources = ]],dump(self.resources),[[,
        }
      ]]}
    end,
  }

  game.uiModel = require('UIModel').new(game)
  game.ui = makeUIScript(game)
  game.guyDelegate = makeGuyDelegate(game)

  say(
    game.uiModel.console,
    require('ConsoleMessage').new {
      text = 'Welcome to Kobold Princess Simulator.',
      lifetime = 10
    }
  )

  say(
    game.uiModel.console,
    require('ConsoleMessage').new {
      text = 'This is day 1 of your reign.',
      lifetime = 10,
    }
  )

  -- Subscribe to player stats
  do
    local listenPlayerDeath
    function listenPlayerDeath()
      addListener(require('GuyStats').mut,
        game.player.stats,
        function (playerStats, key, value, oldValue)
          if key == 'hp' and value <= 0 then
            local newPlayer = Guy.makeLeader(tileset, LEADER_SPAWN_LOCATION)
            game:addGuy(newPlayer)
            game.player = newPlayer
            game.deathsCount = game.deathsCount + 1
            listenPlayerDeath()
          end
        end
      )
    end
    listenPlayerDeath()
  end

  return game
end

---@param game Game
---@param guy Guy
---@return boolean
local function isGuyAPlayer(game, guy)
  return guy == game.player
end


---@param game Game
---@param guy Guy
---@return boolean
local function mayRecruit(game, guy)
  if not isRecruitCircleActive(game.recruitCircle) then return false end
  if isGuyAPlayer(game, guy) then return false end
  if isGuyAFollower(game.squad, guy) then return false end
  if not canRecruitGuy(guy) then return false end
  return Vector.dist(guy.pos, game.cursorPos) < game.recruitCircle.radius + 0.5
end

-- Writers

---@param game Game
local function dismissSquad(game)
  for guy in pairs(game.squad.followers) do
    removeFromSquad(game.squad, guy)
  end
end

---@param game Game
local function beginRecruiting(game)
  if game.isFocused then return end
  resetRecruitCircle(game.recruitCircle)
end

---@param game Game
local function endRecruiting(game)
  for _, guy in ipairs(game.guys) do
    if mayRecruit(game, guy) then
      addToSquad(game.squad, guy)
    end
  end
  startFollowing(game.squad)
  clearRecruitCircle(game.recruitCircle)
end

---@param game Game
---@param text string
local function echo(game, text)
  say(game.uiModel.console, require('ConsoleMessage').new {
    text = text,
    lifetime = 60,
  })
end


---@param game Game
local function orderGather(game)
  for guy in pairs(game.squad.followers) do
    if not isFrozen(game, guy) then
      local destination = { x = 0, y = 0 }
      local guyDist = Vector.dist(guy.pos, game.player.pos)
      for _, direction in ipairs{
        Vector.dir.up,
        Vector.dir.down,
        Vector.dir.left,
        Vector.dir.right,
      } do
        local pos = Vector.add(direction, guy.pos)
        local posDist = Vector.dist(game.player.pos, pos)
        if posDist < guyDist then
          destination = direction
        end
      end
      moveGuy(guy, destination, game.guyDelegate)
    end
  end
end

---@param guy Guy
---@param game Game
---@param entity GameEntity_Battle
local function die(guy, game, entity)
  echo(game, ('%s dies with %s hp.'):format(guy.name, guy.stats.hp))

  if guy.team == 'evil' then
    addResources(game.resources, { pretzels = 1})
    game:addScore(SCORES_TABLE.killedAnEnemy)
  end

  game:removeGuy(guy)
  game:removeEntity(entity)
end


---@param game Game -- Game object
---@param dt number -- Time since last update
---@param movementDirections Vector[] -- Momentarily pressed movement directions
local function updateGame(game, dt, movementDirections)
  exhaust(game:makeVisionSourcesCo(), function (visionSource)
    revealFogOfWar(game.world, visionSource, skyColorAtTime(game.time).g, dt)
  end)
  updateConsole(game.uiModel.console, dt)
  if isRecruitCircleActive(game.recruitCircle) then
    growRecruitCircle(game.recruitCircle, dt)
  end

  if game.isFocused then return end

  -- Handle input

  if game.player.stats.moves > 0 and #movementDirections > 0 then
    for _ = 1, #movementDirections do
      local index = (game.alternatingKeyIndex + 1) % (#movementDirections)
      game:setAlternatingKeyIndex(index)

      local vec = movementDirections[index + 1]

      if game.squad.shouldFollow then
        for guy in pairs(game.squad.followers) do
          if not isFrozen(game, guy) then
            moveGuy(guy, vec, game.guyDelegate)
          end
        end
      end

      if not isFrozen(game, game.player) then
        local oldPos = game.player.pos
        local newPos = moveGuy(game.player, vec, game.guyDelegate)
        if not Vector.equal(newPos, oldPos) then
          break
        end
      end
    end
  end

  if love.keyboard.isDown('q') then
    orderGather(game)
  end

  -- Handle game logic

  game:advanceClock(dt)
  for _, entity in ipairs(game.entities) do
    if entity.type == 'battle' then
      ---@cast entity GameEntity_Battle
      local battle = entity.object
      updateBattle(game, battle, dt, function (text)
        echo(game, text)
      end, function ()
        -- TODO: use events to die
        if battle.attacker.stats.hp <= 0 then
          die(battle.attacker, game, entity)
        end

        if battle.defender.stats.hp <= 0 then
          die(battle.defender, game, entity)
        end

        game:setGuyFrozen(battle.attacker, false)
        game:setGuyFrozen(battle.defender, false)
      end)
    end
  end

  for _, guy in ipairs(game.guys) do
    if getTile(game.world, guy.pos) == 'forest' then
      updateGuy(guy, dt / 2)
    elseif getTile(game.world, guy.pos) == 'void' then
      updateGuy(guy, dt / 8)
    else
      updateGuy(guy, dt)
    end
    if not isFrozen(game, guy) then
      behave(guy, game.guyDelegate)
    end
  end
end

---@param tileset Tileset
---@param game Game
---@param guy Guy
local function maybeCollect(tileset, game, guy)
  local Guy = require('Guy')
  if isFrozen(game, guy) then return end

  local pos = guy.pos
  local tile = getTile(game.world, pos)
  if tile == 'forest' then
    addResources(game.resources, { wood = 1 })
    setTile(game.world, pos, 'grass')
    game:addGuy(Guy.makeEvilGuy(tileset, EVIL_SPAWN_LOCATION))
  elseif tile == 'rock' then
    addResources(game.resources, { stone = 1 })
    setTile(game.world, pos, 'sand')
    game:addGuy(Guy.makeStrongEvilGuy(tileset, EVIL_SPAWN_LOCATION))
  elseif tile == 'grass' then
    addResources(game.resources, { grass = 1 })
    setTile(game.world, pos, 'sand')
  elseif tile == 'water' then
    addResources(game.resources, { water = 1 })
    setTile(game.world, pos, 'sand')
  end
end

---@param tileset Tileset
---@param game Game
local function orderChop(tileset, game)
  maybeCollect(tileset, game, game.player)
  for guy in pairs(game.squad.followers) do
    maybeCollect(tileset, game, guy)
  end
end

---@param game Game
local function orderBuild(game)
  -- Check if has enough resources
  if game.resources.wood < BUILDING_COST then return end
  if game.player.stats.moves < MOVE_COSTS_TABLE.build then return end

  local pos = game.cursorPos

  -- Check if no other entities
  for _, entity in ipairs(game.entities) do
    if Vector.equal(entity.object.pos, pos) then
      return
    end
  end

  -- Is building on rock?
  if getTile(game.world, pos) == 'rock' then
    addResources(game.resources, { stone = 1 })
    setTile(game.world, pos, 'sand')
  end

  -- Build
  addResources(game.resources, { wood = -BUILDING_COST })
  addMoves(game.player.stats, -MOVE_COSTS_TABLE.build)
  game:addEntity(
    require('GameEntity').makeBuildingEntity(
      require('Building').new { pos = pos }
    )
  )
  game:addScore(SCORES_TABLE.builtAHouse)
  game:disableFocus()
end

---@param game Game
---@param tileset Tileset
local function orderSummon(game, tileset)
  if game.resources.pretzels <= 0 then return end
  if game.player.stats.moves <= MOVE_COSTS_TABLE.summon then return end

  addResources(game.resources, { pretzels = -1 })
  addMoves(game.player.stats, -MOVE_COSTS_TABLE.summon)
  local guy = require('Guy').makeGoodGuy(tileset, game.cursorPos)
  echo(game, ('%s was summonned.'):format(guy.name))
  game:addGuy(guy)
  addToSquad(game.squad, guy)
end

---@param game Game
---@param scancode string
---@param key string
local function handleFocusModeInput(game, scancode, key)
  if scancode == 'escape' then
    game:toggleFocus()
  elseif scancode == 'return' then
    local prompt = game.uiModel.prompt
    game.uiModel.prompt = ''
    local chunk = loadstring(prompt, 'commandline')
    if chunk ~= nil then
      local commands
      commands = {
        reload = function(moduleName)
          require('Module').reload(moduleName)
          game.uiModel = require('UIModel').new(game)
          game.ui = require('Game').makeUIScript(game)
          game.player = require('Guy').new(game.player)
          game.guys[1] = game.player
          echo(game, 'recreated uiModel, ui, and player')
        end,
        scribe = function(text)
          game:addText(require('Text').new{
            text = text,
            pos = game.player.pos,
          })
        end,
        print = function (something)
          echo(game, something)
        end,
        help = function ()
          for k in pairs(commands) do
            commands.print(k)
          end
        end,
      }
      setfenv(chunk, commands)
      chunk()
    end
  elseif scancode == 'backspace' then
    game.uiModel:didPressBackspace()
  end
end

---@param game Game
---@param scancode string
local function handleNormalModeInput(game, scancode)
  local tileset = require('Tileset').getTileset()

  if scancode == 'tab' then
    game.uiModel:nextTab()
  elseif scancode == 'f' then
    toggleFollow(game.squad)
  elseif scancode == 'g' then
    if game.player.stats.moves >= MOVE_COSTS_TABLE.dismissSquad then
      addMoves(game.player.stats, -MOVE_COSTS_TABLE.dismissSquad)
      dismissSquad(game)
    end
  elseif scancode == 'c' then
    orderChop(tileset, game)
  elseif scancode == 'b' then
    orderBuild(game)
  elseif scancode == 'r' then
    orderSummon(game, tileset)
  elseif scancode == 'return' then
    game:toggleFocus()
  elseif scancode == 't' then
    warpGuy(game.player, game.cursorPos)
  end
end

---@param game Game
---@param scancode string
---@param key string
local function handleInput(game, scancode, key)
  if scancode == 'z' then
    game:nextMagnificationFactor()
  end

  if game.isFocused then
    handleFocusModeInput(game, scancode, key)
  else
    handleNormalModeInput(game, scancode)
  end
end

---@param game Game
---@param text string
local function handleText(game, text)
  if game.isFocused then
    game.uiModel:didTypeCharacter(text)
  end
end

return {
  handleInput = handleInput,
  updateGame = updateGame,
  beginRecruiting = beginRecruiting,
  endRecruiting = endRecruiting,
  isFrozen = isFrozen,
  mayRecruit = mayRecruit,
  new = new,
  say = echo,
  handleText = handleText,
  makeUIScript = makeUIScript,
}