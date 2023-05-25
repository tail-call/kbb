---@class GameModule: Module
---@field __modulename 'GameModule'
---@field mut GameMutator

---@alias GameMode 'normal' | 'focus' | 'paint'

---Game state
---@class Game
---@field __module 'Game'
---# Properties
---@field world World Game world
---@field resources Resources Resources player may spend on upgrades
---@field entities Object2D[] Things in the game world
---@field deathsCount number Number of times player has died
---@field guyDelegate GuyDelegate Object that talks to guys
---@field squad Squad A bunch of guys that follow player's movement
---@field player Guy A guy controlled by the player
---@field score integer Score the player has accumulated
---@field time number Time of day in seconds, max is 24*60
---@field cursorPos Vector Points to a square player's cursor is aimed at
---@field magnificationFactor number How much the camera is zoomed in
---@field mode GameMode Current game mode. Affects how player's input is handled.
---@field ui UI User interface root
---@field uiModel UIModel GUI state
---@field alternatingKeyIndex integer Diagonal movement reader head index
---@field recruitCircle RecruitCircle Circle thing used to recruit units
---@field frozenEntities { [Object2D]: true } Entities that should be not rendered and should not behave
---# Methods
---@field advanceClock fun(self: Game, dt: number) Advances in-game clock
---@field addScore fun(self: Game, count: integer) Increases score count
---@field switchMode fun(self: Game) Switches to next mode
---@field addEntity fun(self: Game, entity: Object2D) Adds an entity to the world

---@class GameMutator
---@field setEntityFrozen fun(self: Game, entity: Object2D, state: boolean) Unfreezes a guy
---@field removeEntity fun(self: Game, entity: Object2D) Adds a building to the world
---@field beginBattle fun(self: Game, attacker: Guy, defender: Guy) Starts a new battle
---@field setAlternatingKeyIndex fun(self: Game, index: number) Moves diagonal movement reader head to a new index
---@field addPlayer fun(self: Game, guy: Guy) Adds a controllable unit to the game
---@field disableFocus fun(self: Game) Turns focus mode off
---@field nextMagnificationFactor fun(self: Game) Switches magnification factor to a different one

local canRecruitGuy = require('Guy').canRecruitGuy
local moveGuy = require('Guy').moveGuy
local warpGuy = require('Guy').warpGuy
local setTile = require('World').setTile
local getTile = require('World').getTile
local isPassable = require('World').isPassable
local tbl = require('tbl')
local Vector = require('Vector')
local maybeDrop = require('tbl').maybeDrop
local updateConsole = require('Console').updateConsole
local isRecruitCircleActive = require('RecruitCircle').isRecruitCircleActive
local isAFollower = require('Squad').isAFollower
local revealFogOfWar = require('World').revealVisionSourceFog
local skyColorAtTime = require('Util').skyColorAtTime
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

---@type GameModule
local M = require('Module').define{..., metatable = {
  ---@type Game
  __index = {
    advanceClock = function (self, dt)
      self.time = (self.time + dt) % (24 * 60)
    end,
    addScore = function(self, count)
      self.score = self.score + count
    end,
    addEntity = function (self, entity)
      table.insert(self.entities, entity)
    end,
    switchMode = function (self)
      if self.mode == 'normal' then
        self.mode = 'paint'
      elseif self.mode == 'paint' then
        self.mode = 'focus'
      else
        self.mode = 'normal'
      end
    end,
  }
}}

---@type CollisionInfo
local NONE_COLLISION = { type = 'none' }
---@type CollisionInfo
local TERRAIN_COLLISION = { type = 'terrain' }

---@type GameMutator
M.mut = require('Mutator').new {
  addPlayer = function (self, guy)
    if self.player ~= nil then
      M.mut.removeEntity(self, self.player)
      self.player = nil
    end

    self.player = guy
    self:addEntity(guy)
  end,
  disableFocus = function (self)
    self.isFocused = false
  end,
  removeEntity = function (self, entity)
    maybeDrop(self.entities, entity)

    if entity.__module == 'Guy' then
      removeFromSquad(self.squad, entity)
      self.frozenEntities[entity] = nil

      local tile = getTile(self.world, entity.pos)

      if entity.team == 'evil' then
        if tile == 'sand' then
          setTile(self.world, entity.pos, 'grass')
        elseif tile == 'grass' then
          setTile(self.world, entity.pos, 'forest')
        elseif tile == 'forest' then
          setTile(self.world, entity.pos, 'water')
        end
      elseif entity.team == 'good' then
        if tile == 'sand' then
          setTile(self.world, entity.pos, 'rock')
        else
          setTile(self.world, entity.pos, 'sand')
        end
      end
    end
  end,
  setEntityFrozen = function (self, entity, state)
    self.frozenEntities[entity] = state or nil
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

    self:addEntity(require('Battle').new {
      attacker = attacker,
      defender = defender,
    })
  end,
  setAlternatingKeyIndex = function (self, x)
    self.alternatingKeyIndex = x
  end,
}


---@param game Game
---@param collider fun(self: Game, v: Vector): CollisionInfo Function that performs collision checks between game world objects
---@return GuyDelegate
local function makeGuyDelegate(game, collider)
  ---@type GuyDelegate
  local guyDelegate = {
    beginBattle = function (attacker, defender)
      require('Game').mut.beginBattle(game, attacker, defender)
    end,
    enterHouse = function (guy, building)
      if guy.team ~= 'good' then
        return 'shouldNotMove'
      end
      require('GuyStats').mut.setMaxHp(guy.stats, guy.stats.maxHp + 1)
      require('Game').mut.removeEntity(game, building)
      return 'shouldMove'
    end,
    collider = function (pos)
      return collider(game, pos)
    end,
  }
  return guyDelegate
end

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
  return require('Util').doFileWithIndex('./screen.ui.lua', {
    UI = function (children)
      return require('UI').new({}, children)
    end,
    Panel = require('UI').makePanel,
    Origin = require('UI').origin,
    Model = game.uiModel,
    ---@param drawState DrawState
    FullHeight = function (drawState)
      local _, sh = love.window.getMode()
      return sh / drawState.windowScale
    end,
    ---@param drawState DrawState
    FullWidth = function (drawState)
      local sw, _ = love.window.getMode()
      return sw / drawState.windowScale
    end,
    Fixed = function (x)
      return function () return x end
    end,
  })()
end

---@param game Game
function M.init(game)
  local Guy = require('Guy')

  game.world = game.world or require('World').new()
  game.score = game.score or 0
  game.frozenEntities = tbl.weaken(game.frozenEntities or {}, 'k')
  game.resources = game.resources or require('Resources').new()
  game.time = game.time or (12 * 60)
  game.entities = game.entities or {}
  game.deathsCount = game.deathsCount or 0
  game.alternatingKeyIndex = 1
  game.squad = require('Squad').new {}
  game.recruitCircle = require('RecruitCircle').new {}
  game.cursorPos = game.cursorPos or { x = 0, y = 0 }
  game.magnificationFactor = game.magnificationFactor or 1
  game.mode = game.mode or 'normal'

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

  local messages = {
    'This is your first day of ruling your own Kobold tribe.',
    'Tonight, you had a dream where you saw Zirnitra, your dragon deity, speak to you.',
    '\'Avenge my death on filthy humans!\' she said.',
    '\'Build a temple to honor me and we shall talk again. You have 6 months.\'',
  }

  for k, v in ipairs(messages) do
    game.uiModel.console:say(
      require('ConsoleMessage').new {
        text = v,
        lifetime = 10
      }
    )
  end

  if not require('tbl').has(game.entities, game.player) then
    M.mut.addPlayer(game, Guy.makeLeader(LEADER_SPAWN_LOCATION))
  end

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
            game:addEntity(newPlayer)
            --- TODO: mutators
            game.player = newPlayer
            game.deathsCount = game.deathsCount + 1
            game:addScore(SCORES_TABLE.dead)
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
  if game.mode ~= 'normal' then return end
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
    game:addScore(SCORES_TABLE.killedAnEnemy)
  end

  mut.removeEntity(game, guy)
  mut.removeEntity(game, battle)
end

---@param game Game Game object
---@param dt number Time since last update
---@param movementDirections Vector[] Momentarily pressed movement directions
function M.updateGame(game, dt, movementDirections)
  local visionSources = {{
    pos = game.player.pos,
    sight = 10
  }, {
    pos = game.cursorPos,
    sight = math.max(2, game.recruitCircle.radius or 0),
  }}

  for _,v in ipairs(visionSources) do
    revealFogOfWar(game.world, v, skyColorAtTime(game.time).g, dt)
  end

  updateConsole(game.uiModel.console, dt)
  if isRecruitCircleActive(game.recruitCircle) then
    growRecruitCircle(game.recruitCircle, dt)
  end

  if game.mode == 'focus' then return end

  -- Handle normal mode movement input

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

  -- Handle normal mode logic

  game:advanceClock(dt)
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
        entity:update(dt / 2)
      elseif getTile(game.world, entity.pos) == 'void' then
        entity:update(dt / 8)
      else
        entity:update(dt)
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
    game:addEntity(Guy.makeEvilGuy {
      x = patchCenterX,
      y = patchCenterY,
    })
  elseif tile == 'rock' then
    addResources(game.resources, { stone = 1 })
    setTile(game.world, pos, 'cave')
    game:addEntity(Guy.makeStrongEvilGuy {
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
  game:addEntity(require('Building').new { pos = pos })
  game:addScore(SCORES_TABLE.builtAHouse)
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
  game:addEntity(guy)
  addToSquad(game.squad, guy)
end

---@param game Game
---@param drawState DrawState
---@param scancode string
---@param key string
local function handleFocusModeInput(game, drawState, scancode, key)
  if tbl.has({ '1', '2', '3', '4' }, scancode) then
    drawState:setWindowScale(tonumber(scancode) or 1)
  else
    -- TODO: use mutator
    game.uiModel = require('UIModel').new(game)
    game.ui = require('Game').makeUIScript(game)
    echo(game, 'recreated uiModel and ui')
  end
end

---@param game Game
---@param scancode string
local function handleNormalModeInput(game, scancode)
  if scancode == 'tab' then
    game.uiModel:nextTab()
  elseif scancode == 'c' then
    orderCollect(game)
  elseif scancode == 'e' then
    local patch = require('World').patchAt(game.world, game.player.pos)
    require('World').randomizePatch(game.world, patch)
  elseif scancode == 't' then
    warpGuy(game.player, game.cursorPos)
  end
end


---@param game Game
function M.orderPaint(game)
  setTile(game.world, game.cursorPos, 'grass')
end

---@param game Game
---@param drawState DrawState
---@param scancode string
---@param key string
function M.handleInput(game, drawState, scancode, key)
  if scancode == 'z' then
    M.mut.nextMagnificationFactor(game)
  end

  if scancode == 'space' then
    game:switchMode()
  elseif scancode == 'g' then
    if game.player.stats.moves >= MOVE_COSTS_TABLE.dismissSquad then
      addMoves(game.player.stats, -MOVE_COSTS_TABLE.dismissSquad)
      dismissSquad(game)
    end
  elseif scancode == 'r' then
    orderSummon(game)
  elseif scancode == 'f' then
    toggleFollow(game.squad)
  elseif scancode == 'b' then
    orderBuild(game)
  elseif game.mode == 'focus' then
    handleFocusModeInput(game, drawState, scancode, key)
  elseif game.mode == 'normal' then
    handleNormalModeInput(game, scancode)
  end
end

---@param game Game
---@param text string
function M.handleText(game, text)
  if game.mode == 'focus' then
    game.uiModel:didTypeCharacter(text)
  end
end

return M