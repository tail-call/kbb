---@alias GameMode 'normal' | 'focus' | 'paint'

---Game state
---@class Game
---@field __module 'Game'
---# Properties
---@field world World Game world
---@field resources Resources Resources player may spend on upgrades
---@field entities Object2D[] Things in the game world
---@field guyDelegate Guy.delegate Object that talks to guys
---@field squad Squad A bunch of guys that follow player's movement
---@field player Guy A guy controlled by the player
---@field stats GameStats Game stats like player score etc.
---@field time number Time of day in seconds, max is 24*60
---@field cursorPos core.Vector Points to a square player's cursor is aimed at
---@field magnificationFactor number How much the camera is zoomed in
---@field mode GameMode Current game mode. Affects how player's input is handled.
---@field console Console Bottom console
---@field recruitCircle RecruitCircle Circle thing used to recruit units
---@field frozenEntities { [Object2D]: true } Entities that should be not rendered and should not behave
---# Methods
---@field advanceClock fun(self: Game, dt: number) Advances in-game clock
---@field switchMode fun(self: Game) Switches to next mode
---@field addEntity fun(self: Game, entity: Object2D) Adds an entity to the world
---@field removeEntity fun(self: Game, entity: Object2D) Adds a building to the world
---@field addPlayer fun(self: Game, guy: Guy) Adds a controllable unit to the game
---@field nextMagnificationFactor fun(self: Game) Switches magnification factor to a different one
---@field setEntityFrozen fun(self: Game, entity: Object2D, state: boolean) Unfreezes a guy
---@field beginBattle fun(self: Game, attacker: Guy, defender: Guy) Starts a new battle
---@field setAlternatingKeyIndex fun(self: Game, index: number) Moves diagonal movement reader head to a new index

local canRecruitGuy = require 'Guy'.canRecruitGuy
local moveGuy = require 'Guy'.moveGuy
local getTile = require 'World'.getTile
local isPassable = require 'World'.isPassable
local Vector = require 'core.Vector'
local updateConsole = require 'Console'.updateConsole
local isRecruitCircleActive = require 'RecruitCircle'.isRecruitCircleActive
local isAFollower = require 'Squad'.isAFollower
local revealVisionSourceFog = require 'World'.revealVisionSourceFog
local behave = require 'Guy'.behave
local addMoves = require 'GuyStats'.mut.addMoves

---@type core.Vector
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

local TILE_SPEEDS = {
  forest = 1/2,
  void = 1/8,
}

local BUILDING_COST = 5

local M = require 'core.Module'.define{..., metatable = {
  ---@type Game
  __index = {
    addPlayer = function (self, guy)
      if self.player ~= nil then
        self:removeEntity(self.player)
        self.player = nil
      end

      self.player = guy
      self:addEntity(guy)
    end,
    advanceClock = function (self, dt)
      self.time = (self.time + dt) % (24 * 60)
    end,
    addEntity = function (self, entity)
      table.insert(self.entities, entity)
    end,
    removeEntity = function (self, entity)
      require 'core.table'.maybeDrop(self.entities, entity)

      if entity.__module == 'Guy' then
        ---@cast entity Guy
        self.squad:removeFromSquad(entity)
        self.frozenEntities[entity] = nil

        local tile = getTile(self.world, entity.pos)

        if entity.team == 'evil' then
          if tile == 'sand' then
            self.world:setTile(entity.pos, 'grass')
          elseif tile == 'grass' then
            self.world:setTile(entity.pos, 'forest')
          elseif tile == 'forest' then
            self.world:setTile(entity.pos, 'water')
          end
        elseif entity.team == 'good' then
          if tile == 'sand' then
            self.world:setTile(entity.pos, 'rock')
          else
            self.world:setTile(entity.pos, 'sand')
          end
        end
      end
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
    nextMagnificationFactor = function (self)
      if self.magnificationFactor == 1 then
        self.magnificationFactor = 2/3
      elseif self.magnificationFactor == 2/3 then
        self.magnificationFactor = 2
      else
        self.magnificationFactor = 1
      end
    end,
    setEntityFrozen = function (self, entity, state)
      self.frozenEntities[entity] = state or nil
    end,
    beginBattle = function (self, attacker, defender)
      self:setEntityFrozen(attacker, true)
      self:setEntityFrozen(defender, true)

      self:addEntity(require 'Battle'.new {
        attacker = attacker,
        defender = defender,
      })
    end,
  }
}}

---@type Guy.collision
local NONE_COLLISION = { type = 'none' }
---@type Guy.collision
local TERRAIN_COLLISION = { type = 'terrain' }

---@param game Game
---@param pos core.Vector
---@return { pos: core.Vector } | nil
local function findEntityAtPos(game, pos)
  return require 'core.table'.find(game.entities, function (entity)
    return Vector.equal(entity.pos, pos)
  end)
end

---@param game Game
---@return Guy.delegate
local function makeGuyDelegate(game)
  ---@type Guy.delegate
  local guyDelegate = {
    beginBattle = function (attacker, defender)
      game:beginBattle(attacker, defender)
    end,
    enterHouse = function (guy, building)
      if guy.team ~= 'good' then
        return 'shouldNotMove'
      end
      require 'GuyStats'.mut.setMaxHp(guy.stats, guy.stats.maxHp + 1)
      game:removeEntity(building)
      return 'shouldMove'
    end,
    collider = function (pos, guy)
      local someEntityThere = findEntityAtPos(game, pos)
      if someEntityThere then
        return { type = 'entity', entity = someEntityThere }
      end

      if guy.pixie.isFloating then
        return NONE_COLLISION
      elseif isPassable(game.world, pos) then
        return NONE_COLLISION
      end

      return TERRAIN_COLLISION
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
function M.init(game)
  require 'core.Dep' (game, function (want)
    return {
      want.world,
      want.squad,
      want.recruitCircle,
      want.resources
    }
  end)
  game.console = game.console or require 'Console'.new()
  game.stats = game.stats or require 'GameStats'.new()
  game.frozenEntities = require 'core.table'.weaken(game.frozenEntities or {}, 'k')
  game.time = game.time or (12 * 60)
  game.entities = game.entities or {}
  game.cursorPos = game.cursorPos or { x = 0, y = 0 }
  game.magnificationFactor = game.magnificationFactor or 1
  game.mode = game.mode or 'normal'

  game.guyDelegate = makeGuyDelegate(game)

  local messages = {
    'This is your first day of ruling your own Kobold tribe.',
    'Tonight, you had a dream where you saw Zirnitra, your dragon deity, speak to you.',
    '\'Avenge my death on filthy humans!\' she said.',
    '\'Build a temple to honor me and we shall talk again. You have 6 months.\'',
  }

  for k, v in ipairs(messages) do
    game.console:say(
      require 'ConsoleMessage'.new {
        text = v,
        lifetime = 10
      }
    )
  end

  local Guy = require 'Guy'

  if not require 'core.table'.has(game.entities, game.player) then
    game:addPlayer(Guy.makeLeader(LEADER_SPAWN_LOCATION))
  end

  -- Subscribe to player stats
  do
    local function listenPlayerDeath()
      require 'GuyStats'.mut:addListener(
        game.player.stats,
        function (playerStats, key, value, oldValue)
          if key == 'hp' and value <= 0 then
            game.stats:addDeaths(1)
            game:addPlayer(Guy.makeLeader(LEADER_SPAWN_LOCATION))
            game.stats:addScore(SCORES_TABLE.dead)
            listenPlayerDeath()
          end
        end
      )
    end
    listenPlayerDeath()
  end

  if game.player == nil then
    error 'no player'
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
    game.squad:removeFromSquad(guy)
  end
end

---@param game Game
function M.beginRecruiting(game)
  if game.mode ~= 'normal' then return end
  game.recruitCircle:reset()
end

---@param game Game
function M.endRecruiting(game)
  for _, entity in ipairs(game.entities) do
    if M.mayRecruit(game, entity) then
      if entity.__module == 'Guy' then
        ---@cast entity Guy
        game.squad:addToSquad(entity)
      end
    end
  end
  game.squad:startFollowing()
  game.recruitCircle:clear()
end

---@param game Game
---@param text string
local function echo(game, text)
  game.console:say(require 'ConsoleMessage'.new {
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
---@param battle Battle
local function die(guy, game, battle)
  echo(game, ('%s dies with %s hp.'):format(guy.name, guy.stats.hp))

  if guy.team == 'evil' then
    game.resources:add { pretzels = 1 }
    game.stats:addScore(SCORES_TABLE.killedAnEnemy)
  end

  game:removeEntity(guy)
  game:removeEntity(battle)
end

---@param game Game Game object
---@param dt number Time since last update
---@param visibility number How far we should see in tiles
---@param movementDirections core.Vector[] Momentarily pressed movement directions
function M.updateGame(game, dt, movementDirections, visibility)
  local visionSources = {{
    pos = game.player.pos,
    sight = 10
  }, {
    pos = game.cursorPos,
    sight = math.max(2, game.recruitCircle.radius or 0),
  }}

  for _,v in ipairs(visionSources) do
    revealVisionSourceFog(game.world, v, visibility, dt)
  end

  updateConsole(game.console, dt)
  if isRecruitCircleActive(game.recruitCircle) then
    game.recruitCircle:grow(dt)
  end


  -- Handle normal mode movement input

  if game.mode ~= 'focus' then
    if love.keyboard.isDown('q') then
      orderGather(game)
    end

    -- Handle normal mode logic

    game:advanceClock(dt)
    for _, entity in ipairs(game.entities) do
      if entity.__module == 'Battle' then
        ---@cast entity Battle
        require 'Battle'.updateBattle(game, entity, dt, function (text)
          echo(game, text)
        end, function ()
          if entity.attacker.stats.hp <= 0 then
            die(entity.attacker, game, entity)
          end

          if entity.defender.stats.hp <= 0 then
            die(entity.defender, game,  entity)
          end

          game:setEntityFrozen(entity.attacker, false)
          game:setEntityFrozen(entity.defender, false)
        end)
      end
    end
  end

  ---Returns a speed factor that a guy should have on a specified tile
  ---@param guy Guy
  ---@param tile World.tile
  ---@return number
  local function speedFactor(guy, tile)
    if guy.pixie.isFloating then
      return 1
    end

    return TILE_SPEEDS[tile] or 1
  end

  for _, entity in ipairs(game.entities) do
    if entity.__module == 'Guy' then
        ---@cast entity Guy
      entity:update(dt * speedFactor(entity, getTile(game.world, entity.pos)))
      if not M.isFrozen(game, entity) then
        behave(entity, game.guyDelegate)
      end
    end
  end
end

---@param game Game
---@param guy Guy
local function maybeCollect(game, guy)
  local Guy = require 'Guy'

  if M.isFrozen(game, guy) then return end

  local pos = guy.pos
  local patch = require 'World'.patchAt(game.world, pos)
  local patchCenterX, patchCenterY = require 'Patch'.patchCenter(patch)
  local tile = getTile(game.world, pos)
  if tile == 'forest' then
    game.resources:add { wood = 1 }
    game.world:setTile(pos, 'grass')
    game:addEntity(Guy.makeEvilGuy {
      x = patchCenterX,
      y = patchCenterY,
    })
  elseif tile == 'rock' then
    game.resources:add { stone = 1 }
    game.world:setTile(pos, 'cave')
    game:addEntity(Guy.makeStrongEvilGuy {
      x = patchCenterX,
      y = patchCenterY,
    })
  elseif tile == 'grass' then
    game.resources:add { grass = 1 }
    game.world:setTile(pos, 'sand')
    require 'GuyStats'.mut.heal(guy.stats, 1)
  elseif tile == 'water' then
    game.resources:add { water = 1 }
    game.world:setTile(pos, 'sand')
  end
end

---@param game Game
function M.orderCollect(game)
  maybeCollect(game, game.player)
  for guy in pairs(game.squad.followers) do
    maybeCollect(game, guy)
  end
end

---@param game Game
function M.orderBuild(game)
  local pos = game.cursorPos

  -- Check if no other entities
  for _, entity in ipairs(game.entities) do
    if Vector.equal(entity.pos, pos) then
      return
    end
  end

  -- Is building on rock?
  if getTile(game.world, pos) == 'rock' then
    game.resources:add { stone = 1 }
    game.world:setTile(pos, 'sand')
  end

  -- Build
  game.resources:add { wood = -BUILDING_COST }
  addMoves(game.player.stats, -MOVE_COSTS_TABLE.build)
  game:addEntity(require 'Building'.new { pos = pos })
  game.stats:addScore(SCORES_TABLE.builtAHouse)
end

---@param game Game
function M.orderSummon(game)
  game.resources:add { pretzels = -1 }
  addMoves(game.player.stats, -MOVE_COSTS_TABLE.summon)
  local guy = require 'Guy'.makeGoodGuy(game.cursorPos)
  echo(game, ('%s was summonned.'):format(guy.name))
  game:addEntity(guy)
  game.squad:addToSquad(guy)
end

---@param game Game
function M.orderPaint(game)
  game.world:setTile(game.cursorPos, 'grass')
end

---@param game Game
function M.orderDismiss(game)
  if game.player.stats.moves >= MOVE_COSTS_TABLE.dismissSquad then
    addMoves(game.player.stats, -MOVE_COSTS_TABLE.dismissSquad)
    dismissSquad(game)
  end
end

return M