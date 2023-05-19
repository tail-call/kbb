---@class GameModule: Module
---@field __modulename 'GameModule'
---@field mut GameMutator

---@class Game
---@field world World Game world
---@field resources Resources Resources player may spend on upgrades
---@field entities Object2D[] Things in the game world
---@field deathsCount number Number of times player has died
---@field guyDelegate GuyDelegate Object that talks to guys
---@field squad Squad A bunch of guys that follows player's movement
---@field player Guy A guy controlled by the player
---@field score integer Score the player has accumulated
---@field time number Time of day in seconds, max is 24*60
---@field cursorPos Vector Points to a square player's cursor is aimed at
---@field magnificationFactor number How much the camera is zoomed in
---@field isFocused boolean True if focus mode is on
---@field ui UI User interface root
---@field uiModel UIModel GUI state
---@field alternatingKeyIndex integer Diagonal movement reader head index
---@field recruitCircle RecruitCircle Circle thing used to recruit units
---@field fogOfWarTimer number
---@field frozenEntities { [Object2D]: true } Entities that should be not rendered and should not behave

---@class GameMutator
---@field advanceClock fun(self: Game, dt: number) Advances in-game clock
---@field addScore fun(self: Game, count: integer) Increases score count
---@field setEntityFrozen fun(self: Game, entity: Object2D, state: boolean) Unfreezes a guy
---@field addEntity fun(self: Game, entity: Object2D) Adds an entity to the world
---@field removeEntity fun(self: Game, entity: Object2D) Adds a building to the world
---@field beginBattle fun(self: Game, attacker: Guy, defender: Guy) Starts a new battle
---@field setAlternatingKeyIndex fun(self: Game, index: number) Moves diagonal movement reader head to a new index
---@field addPlayer fun(self: Game, guy: Guy) Adds a controllable unit to the game
---@field toggleFocus fun(self: Game) Toggles focus mode
---@field disableFocus fun(self: Game) Turns focus mode off
---@field nextMagnificationFactor fun(self: Game) Switches magnification factor to a different one

---@type GameModule
local M = require('Module').define(..., 0)

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
local isAFollower = require('Squad').isAFollower
local makeGuyDelegate = require('GuyDelegate').new
local revealFogOfWar = require('World').revealVisionSourceFog
local skyColorAtTime = require('Util').skyColorAtTime
local exhaust = require('Util').exhaust
local behave = require('Guy').behave

local addMoves = require('GuyStats').mut.addMoves
local updateBattle = require('Battle').updateBattle
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
local LEADER_SPAWN_LOCATION = { x = 250, y = 250 }

local SCORES_TABLE = {
  killedAnEnemy = 100,
  builtAHouse = 500,
  dead = -1000,
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

---@type GameMutator
M.mut = require('Mutator').new {
  -- Methods
  addScore = function(self, count)
    self.score = self.score + count
  end,
  removeGuy = function (self, guy)
    maybeDrop(self.guys, guy)
    removeFromSquad(self.squad, guy)
    self.frozenEntities[guy] = nil

    local tile = getTile(self.world, guy.pos)

    if guy.team == 'evil' then
      if tile == 'sand' then
        setTile(self.world, guy.pos, 'grass')
      elseif tile == 'grass' then
        setTile(self.world, guy.pos, 'forest')
      elseif tile == 'forest' then
        setTile(self.world, guy.pos, 'water')
      end
    elseif guy.team == 'good' then
      if tile == 'sand' then
        setTile(self.world, guy.pos, 'rock')
      else
        setTile(self.world, guy.pos, 'sand')
      end
    end
  end,
  addPlayer = function (self, guy)
    if self.player ~= nil then
      M.mut.removeEntity(self, self.player)
      self.player = nil
    end

    self.player = guy
    M.mut.addEntity(self, guy)
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
    maybeDrop(self.entities, entity)
  end,
  setEntityFrozen = function (self, entity, state)
    self.frozenEntities[entity] = state or nil
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
    M.mut.setEntityFrozen(self, attacker, true)
    M.mut.setEntityFrozen(self, defender, true)

    M.mut.addEntity(
      self,
      require('Battle').new {
        attacker = attacker, defender = defender
      }
    )
  end,
  setAlternatingKeyIndex = function (self, x)
    self.alternatingKeyIndex = x
  end,
}

---Returns true if guy is marked as frozen
---@param game Game
---@param object Object2D
---@return boolean
function M.isFrozen(game, object)
  return game.frozenEntities[object] or false
end

---@param game Game
---@param pos Vector
---@return { pos: Vector } | nil
local function findEntityAtPos(game, pos)
  return tbl.find(game.entities, function (entity)
    return Vector.equal(entity.pos, pos)
  end)
end

---@param game Game
function M.makeUIScript(game)
  local TRANSPARENT_PANEL_COLOR = { r = 0, g = 0, b = 0, a = 0 }
  local GRAY_PANEL_COLOR = { r = 0.5, g = 0.5, b = 0.5, a = 1 }
  local DARK_GRAY_PANEL_COLOR = { r = 0.25, g = 0.25, b = 0.25, a = 1 }

  local model = game.uiModel

  local UIModule = require('UI')
  local panel = UIModule.makePanel
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

  -- TODO: make UI from serialized markup
  return UIModule.new({}, {
    panel {
      background = GRAY_PANEL_COLOR,
      transform = function () return origin() end,
      w = fullWidth,
      h = fixed(8),
      coloredText = require('UIModel').topPanelText(game)
    },
    -- Left panel
    panel {
      shouldDraw = model.shouldDrawFocusModeUI,
      background = GRAY_PANEL_COLOR,
      transform = function ()
        return origin():translate(0, 8)
      end,
      w = fixed(88),
      h = fullHeight,
      text = model.leftPanelText,
    },
    -- Empty underlay for console
    panel {
      shouldDraw = model.shouldDrawFocusModeUI,
      background = DARK_GRAY_PANEL_COLOR,
      transform = function (drawState)
        return origin():translate(88, fullHeight(drawState) - 60)
      end,
      w = fixed(240),
      h = fixed(52),
    },
    -- Right panel
    panel {
      background = TRANSPARENT_PANEL_COLOR,
      transform = function (drawState)
        return origin():translate(fullWidth(drawState)-88, 8)
      end,
      w = fixed(88),
      h = fixed(128),
      text = model.rightPanelText,
    },
    -- Bottom panel
    panel {
      background = GRAY_PANEL_COLOR,
      transform = function (drawState)
        return origin():translate(0, fullHeight(drawState) - 8)
      end,
      w = fullWidth,
      h = fixed(8),
      text = model.bottomPanelText,
    },
    -- Command line
    panel {
      shouldDraw = model.shouldDrawFocusModeUI,
      background = TRANSPARENT_PANEL_COLOR,
      transform = function (drawState)
        return origin():translate(96, fullHeight(drawState) - 76)
      end,
      w = fixed(200),
      h = fullHeight,
    },
  })
end

---@param game Game
function M.init(game)
  local Guy = require('Guy')

    -- TODO: use load param
  game.world = require('World').new(game.world or {})
  game.score = game.score or 0
  game.frozenEntities = tbl.weaken({}, 'k')
  -- TODO: use load param
  game.resources = require('Resources').new(game.resources or {})
  game.time = game.time or (12 * 60)
  game.entities = game.entities or {}
  game.deathsCount = game.deathsCount or 0
  game.alternatingKeyIndex = 1
  game.squad = require('Squad').new {}
  game.recruitCircle = require('RecruitCircle').new {}
  game.fogOfWarTimer = 0
  game.cursorPos = game.cursorPos or { x = 0, y = 0 }
  game.magnificationFactor = game.magnificationFactor or 1
  game.isFocused = false

  game.uiModel = require('UIModel').new(game)
  game.ui = M.makeUIScript(game)
  game.guyDelegate = makeGuyDelegate(game, function(self, v)
    local someEntityThere = findEntityAtPos(self, v)
    if someEntityThere then
      return { type = 'entity', entity = someEntityThere }
    end
    if isPassable(self.world, v) then
      return NONE_COLLISION
    end
    return TERRAIN_COLLISION
  end)

  game.uiModel.console:say(
    require('ConsoleMessage').new {
      text = 'Welcome to Kobold Princess Simulator.',
      lifetime = 10
    }
  )

  game.uiModel.console:say(
    require('ConsoleMessage').new {
      text = 'This is day 1 of your reign.',
      lifetime = 10,
    }
  )

  M.mut.addPlayer(game, Guy.makeLeader(LEADER_SPAWN_LOCATION))

  -- Subscribe to player stats
  -- TODO: move this into an "addPlayer" function
  do
    local function listenPlayerDeath()
      addListener(
       require('GuyStats').mut,
        game.player.stats,
        function (playerStats, key, value, oldValue)
          if key == 'hp' and value <= 0 then
            local newPlayer = Guy.makeLeader(LEADER_SPAWN_LOCATION)
            M.mut.addEntity(game, newPlayer)
            --- TODO: mutators
            game.player = newPlayer
            game.deathsCount = game.deathsCount + 1
            M.mut.addScore(game, SCORES_TABLE.dead)
            listenPlayerDeath()
          end
        end
      )
    end
    listenPlayerDeath()
  end

  if game.player == nil then
    error('no player')
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
---@param entity Object2D
---@return boolean
function M.mayRecruit(game, entity)
  if not entity.__module == 'Guy' then return false end
  ---@cast entity Guy
  if not isRecruitCircleActive(game.recruitCircle) then return false end
  if isGuyAPlayer(game, entity) then return false end
  if isAFollower(game.squad, entity) then return false end
  if not canRecruitGuy(entity) then return false end
  return Vector.dist(entity.pos, game.cursorPos) < game.recruitCircle.radius + 0.5
end

-- Writers

---@param game Game
local function dismissSquad(game)
  for guy in pairs(game.squad.followers) do
    removeFromSquad(game.squad, guy)
  end
end

---@param game Game
function M.beginRecruiting(game)
  if game.isFocused then return end
  resetRecruitCircle(game.recruitCircle)
end

---@param game Game
function M.endRecruiting(game)
  for _, entity in ipairs(game.entities) do
    if M.mayRecruit(game, entity) then
      if entity.__module == 'Guy' then
        ---@cast entity Guy
        addToSquad(game.squad, entity)
      end
    end
  end
  startFollowing(game.squad)
  clearRecruitCircle(game.recruitCircle)
end

---@param game Game
---@param text string
local function echo(game, text)
  game.uiModel.console:say(require('ConsoleMessage').new {
    text = text,
    lifetime = 60,
  })
end

---@param game Game
local function orderGather(game)
  for entity in pairs(game.squad.followers) do
    if not M.isFrozen(game, entity) then
      local destination = { x = 0, y = 0 }
      local guyDist = Vector.dist(entity.pos, game.player.pos)
      for _, direction in ipairs{
        Vector.dir.up,
        Vector.dir.down,
        Vector.dir.left,
        Vector.dir.right,
      } do
        local pos = Vector.add(direction, entity.pos)
        local posDist = Vector.dist(game.player.pos, pos)
        if posDist < guyDist then
          destination = direction
        end
      end
      moveGuy(entity, destination, game.guyDelegate)
    end
  end
end

---@param guy Guy
---@param game Game
---@param mut GameMutator
---@param battle Battle
local function die(guy, game, mut, battle)
  echo(game, ('%s dies with %s hp.'):format(guy.name, guy.stats.hp))

  if guy.team == 'evil' then
    addResources(game.resources, { pretzels = 1})
    mut.addScore(game, SCORES_TABLE.killedAnEnemy)
  end

  mut.removeEntity(game, guy)
  mut.removeEntity(game, battle)
end

---@param game Game -- Game object
---@param dt number -- Time since last update
---@param movementDirections Vector[] -- Momentarily pressed movement directions
function M.updateGame(game, dt, movementDirections)
  exhaust(function ()
    coroutine.yield({ pos = game.player.pos, sight = 10 })

    return {
      pos = game.cursorPos,
      sight = math.max(2, game.recruitCircle.radius or 0),
    }
  end, function (visionSource)
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
      M.mut.setAlternatingKeyIndex(game, index)

      local vec = movementDirections[index + 1]

      if game.squad.shouldFollow then
        for guy in pairs(game.squad.followers) do
          if not M.isFrozen(game, guy) then
            moveGuy(guy, vec, game.guyDelegate)
          end
        end
      end

      if not M.isFrozen(game, game.player) then
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

  M.mut.advanceClock(game, dt)
  for _, entity in ipairs(game.entities) do
    if entity.__module == 'Battle' then
      ---@cast entity Battle
      updateBattle(game, entity, dt, function (text)
        echo(game, text)
      end, function ()
        -- TODO: use events to die
        if entity.attacker.stats.hp <= 0 then
          die(entity.attacker, game, M.mut, entity)
        end

        if entity.defender.stats.hp <= 0 then
          die(entity.defender, game, M.mut, entity)
        end

        M.mut.setEntityFrozen(game, entity.attacker, false)
        M.mut.setEntityFrozen(game, entity.defender, false)
      end)
    end
  end

  for _, entity in ipairs(game.entities) do
    if entity.__module == 'Guy' then
      ---@cast entity Guy
      if getTile(game.world, entity.pos) == 'forest' then
        updateGuy(entity, dt / 2)
      elseif getTile(game.world, entity.pos) == 'void' then
        updateGuy(entity, dt / 8)
      else
        updateGuy(entity, dt)
      end
      if not M.isFrozen(game, entity) then
        behave(entity, game.guyDelegate)
      end
    end
  end
end

---@param game Game
---@param guy Guy
local function maybeCollect(game, guy)
  local Guy = require('Guy')

  if M.isFrozen(game, guy) then return end

  local pos = guy.pos
  local patch = require('World').patchAt(game.world, pos)
  local patchCenterX, patchCenterY = require('Patch').patchCenter(patch)
  local tile = getTile(game.world, pos)
  if tile == 'forest' then
    addResources(game.resources, { wood = 1 })
    setTile(game.world, pos, 'grass')
    M.mut.addEntity(game, Guy.makeEvilGuy {
      x = patchCenterX,
      y = patchCenterY,
    })
  elseif tile == 'rock' then
    addResources(game.resources, { stone = 1 })
    setTile(game.world, pos, 'cave')
    M.mut.addEntity(game, Guy.makeStrongEvilGuy {
      x = patchCenterX,
      y = patchCenterY,
    })
  elseif tile == 'grass' then
    addResources(game.resources, { grass = 1 })
    setTile(game.world, pos, 'sand')
    require('GuyStats').mut.heal(guy.stats, 1)
  elseif tile == 'water' then
    addResources(game.resources, { water = 1 })
    setTile(game.world, pos, 'sand')
  end
end

---@param game Game
local function orderCollect(game)
  maybeCollect(game, game.player)
  for guy in pairs(game.squad.followers) do
    maybeCollect(game, guy)
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
    if Vector.equal(entity.pos, pos) then
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
  M.mut.addEntity(
    game,
    require('Building').new { pos = pos }
  )
  M.mut.addScore(game, SCORES_TABLE.builtAHouse)
  M.mut.disableFocus(game)
end

---@param game Game
local function orderSummon(game)
  if game.resources.pretzels <= 0 then return end
  if game.player.stats.moves <= MOVE_COSTS_TABLE.summon then return end

  addResources(game.resources, { pretzels = -1 })
  addMoves(game.player.stats, -MOVE_COSTS_TABLE.summon)
  local guy = require('Guy').makeGoodGuy(game.cursorPos)
  echo(game, ('%s was summonned.'):format(guy.name))
  M.mut.addEntity(game, guy)
  addToSquad(game.squad, guy)
end

---@param game Game
---@param scancode string
---@param key string
local function handleFocusModeInput(game, scancode, key)
  M.mut.toggleFocus(game)
  -- TODO: use mutator
  game.uiModel = require('UIModel').new(game)
  game.ui = require('Game').makeUIScript(game)
  echo(game, 'recreated uiModel and ui')
end

---@param game Game
---@param scancode string
local function handleNormalModeInput(game, scancode)
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
    orderCollect(game)
  elseif scancode == 'b' then
    orderBuild(game)
  elseif scancode == 'r' then
    orderSummon(game)
  elseif scancode == 'e' then
    local patch = require('World').patchAt(game.world, game.player.pos)
    require('World').randomizePatch(game.world, patch)
  elseif scancode == 'return' then
    M.mut.toggleFocus(game)
  elseif scancode == 't' then
    warpGuy(game.player, game.cursorPos)
  end
end

---@param game Game
---@param scancode string
---@param key string
function M.handleInput(game, scancode, key)
  if scancode == 'z' then
    M.mut.nextMagnificationFactor(game)
  end

  if game.isFocused then
    handleFocusModeInput(game, scancode, key)
  else
    handleNormalModeInput(game, scancode)
  end
end

---@param game Game
---@param text string
function M.handleText(game, text)
  if game.isFocused then
    game.uiModel:didTypeCharacter(text)
  end
end

return M