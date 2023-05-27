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
---@field console Console Bottom console
---@field alternatingKeyIndex integer Diagonal movement reader head index
---@field recruitCircle RecruitCircle Circle thing used to recruit units
---@field frozenEntities { [Object2D]: true } Entities that should be not rendered and should not behave
---# Methods
---@field advanceClock fun(self: Game, dt: number) Advances in-game clock
---@field addScore fun(self: Game, count: integer) Increases score count
---@field switchMode fun(self: Game) Switches to next mode
---@field addEntity fun(self: Game, entity: Object2D) Adds an entity to the world
---@field removeEntity fun(self: Game, entity: Object2D) Adds a building to the world
---@field addPlayer fun(self: Game, guy: Guy) Adds a controllable unit to the game
---@field addDeaths fun(self: Game, count: integer) Adds a death to a game
---@field nextMagnificationFactor fun(self: Game) Switches magnification factor to a different one
---@field setEntityFrozen fun(self: Game, entity: Object2D, state: boolean) Unfreezes a guy
---@field beginBattle fun(self: Game, attacker: Guy, defender: Guy) Starts a new battle
---@field setAlternatingKeyIndex fun(self: Game, index: number) Moves diagonal movement reader head to a new index

local canRecruitGuy = require 'Guy'.canRecruitGuy
local moveGuy = require 'Guy'.moveGuy
local getTile = require 'World'.getTile
local isPassable = require 'World'.isPassable
local tbl = require 'tbl'
local Vector = require 'Vector'
local maybeDrop = require 'tbl'.maybeDrop
local updateConsole = require 'Console'.updateConsole
local isRecruitCircleActive = require 'RecruitCircle'.isRecruitCircleActive
local isAFollower = require 'Squad'.isAFollower
local revealVisionSourceFog = require 'World'.revealVisionSourceFog
local skyColorAtTime = require 'Util'.skyColorAtTime
local behave = require 'Guy'.behave
local addMoves = require 'GuyStats'.mut.addMoves

local addListener = require 'Mutator'.mut.addListener

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

local M = require 'Module'.define{..., metatable = {
  ---@type Game
  __index = {
    addDeaths = function (self, guy)
      self.deathsCount = self.deathsCount + 1
    end,
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
    addScore = function(self, count)
      self.score = self.score + count
    end,
    addEntity = function (self, entity)
      table.insert(self.entities, entity)
    end,
    removeEntity = function (self, entity)
      maybeDrop(self.entities, entity)

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
    -- TODO: move to scene file
    setAlternatingKeyIndex = function (self, x)
      self.alternatingKeyIndex = x
    end,
  }
}}

---@type CollisionInfo
local NONE_COLLISION = { type = 'none' }
---@type CollisionInfo
local TERRAIN_COLLISION = { type = 'terrain' }

---@param game Game
---@param collider fun(self: Game, v: Vector): CollisionInfo Function that performs collision checks between game world objects
---@return GuyDelegate
local function makeGuyDelegate(game, collider)
  ---@type GuyDelegate
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
function M.init(game)
  game.console = game.console or require 'Console'.new()
  game.world = game.world or require 'World'.new()
  game.score = game.score or 0
  game.frozenEntities = tbl.weaken(game.frozenEntities or {}, 'k')
  game.resources = game.resources or require 'Resources'.new()
  game.time = game.time or (12 * 60)
  game.entities = game.entities or {}
  game.deathsCount = game.deathsCount or 0
  game.alternatingKeyIndex = 1
  game.squad = require 'Squad'.new {}
  game.recruitCircle = require 'RecruitCircle'.new {}
  game.cursorPos = game.cursorPos or { x = 0, y = 0 }
  game.magnificationFactor = game.magnificationFactor or 1
  game.mode = game.mode or 'normal'

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
    game.console:say(
      require 'ConsoleMessage'.new {
        text = v,
        lifetime = 10
      }
    )
  end

  local Guy = require 'Guy'

  if not require 'tbl'.has(game.entities, game.player) then
    game:addPlayer(Guy.makeLeader(LEADER_SPAWN_LOCATION))
  end

  -- Subscribe to player stats
  do
    local function listenPlayerDeath()
      addListener(
       require 'GuyStats'.mut,
        game.player.stats,
        function (playerStats, key, value, oldValue)
          if key == 'hp' and value <= 0 then
            game:addDeaths(1)
            game:addPlayer(Guy.makeLeader(LEADER_SPAWN_LOCATION))
            game:addScore(SCORES_TABLE.dead)
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
    game:addScore(SCORES_TABLE.killedAnEnemy)
  end

  game:removeEntity(guy)
  game:removeEntity(battle)
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
    revealVisionSourceFog(game.world, v, skyColorAtTime(game.time).g, dt)
  end

  updateConsole(game.console, dt)
  if isRecruitCircleActive(game.recruitCircle) then
    game.recruitCircle:grow(dt)
  end

  if game.mode == 'focus' then return end

  -- Handle normal mode movement input

  if game.player.stats.moves > 0 and #movementDirections > 0 then
    for _ = 1, #movementDirections do
      local index = (game.alternatingKeyIndex + 1) % (#movementDirections)
      game:setAlternatingKeyIndex(index)

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
  game:addScore(SCORES_TABLE.builtAHouse)
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