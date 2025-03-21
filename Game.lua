---@alias GameMode 'normal' | 'focus' | 'edit'


local moveGuy = require 'Guy'.moveGuy
local isPassable = require 'World'.isPassable
local Vector = require 'core.Vector'
local updateConsole = require 'Console'.updateConsole
local isRecruitCircleActive = require 'RecruitCircle'.isRecruitCircleActive
local isAFollower = require 'Squad'.isAFollower
local revealVisionSourceFog = require 'World'.revealVisionSourceFog
local ruleBook = require 'ruleBook'.ruleBook
local evalRule = require 'ruleBook'.evalRule

local CURSOR_MAX_DISTANCE = 12


--XXX Evaluate
-- local Game = Class(function (C)
--   C.slot { 'world', type = 'required' }
--   C.slot { 'time',
--     default = Class.constantly(12 * 60),
--   }
--   C.slot { 'stats',
--     -- Works like 'default' if provided
--     class = require 'GameStats',
--   }
--   C.index {
--     doStuff = function (self)
--       print('do stuff')
--     end,
--   }
-- end)

---Game state
---@class Game: core.class
---@field __module 'Game'
---# Properties
---@field world World Game world
---@field resources Resources Resources player may spend on upgrades
---@field entities Object2D[] Things in the game world
---@field guyDelegate Guy.delegate Object that talks to guys
---@field squad Squad A bunch of guys that follow player's movement
---@field player Guy | nil A guy controlled by the player
---@field stats GameStats Game stats like player score etc.
---@field time number Time of day in seconds, max is 24*60
---@field cursorPos core.Vector Points to a square player's cursor is aimed at
---@field magnificationFactor number How much the camera is zoomed in
---@field mode GameMode Current game mode. Affects how player's input is handled.
---@field console Console Bottom console
---@field recruitCircle RecruitCircle Circle thing used to recruit units
---@field frozenEntities { [Object2D]: true } Entities that should be not rendered and should not behave
---@field painterTile World.tile Current selected tile in edit mode
---# Methods
---@field advanceClock fun(self: Game, dt: number) Advances in-game clock
---@field switchMode fun(self: Game) Switches to next mode
---@field addEntity fun(self: Game, entity: Object2D) Adds an entity to the world
---@field removeEntity fun(self: Game, entity: Object2D, shouldGenerateEvent: boolean) Adds a building to the world
---@field addPlayer fun(self: Game, guy: Guy) Adds a controllable unit to the game
---@field nextMagnificationFactor fun(self: Game) Switches magnification factor to a different one
---@field setEntityFrozen fun(self: Game, entity: Object2D, state: boolean) Unfreezes a guy
---@field beginBattle fun(self: Game, attacker: Guy, defender: Guy) Starts a new battle
---@field setAlternatingKeyIndex fun(self: Game, index: number) Moves diagonal movement reader head to a new index
---@field isFrozen fun(self: Game, entity: Object2D): boolean Returns true if an entity is marked as frozen
---@field syncCursorPos fun(self: Game, vec: core.Vector) Records a new value to `self.cursorPos`.
---@field effCursorPos fun(self: Game, x: number, y: number): number, number Effective cursor position. Used to implement a cursor bound to a certain distance in normal mode
---@field cursorColor fun(self: Game): Color Returns the game's cursor color.
local Game = Class {
  ...,
  slots = {
    '!world',
    '!squad',
    '!recruitCircle',
    '!resources',
    'painterTile',
  },
  ---@type Game
  index = {
    addPlayer = function (self, guy)
      if self.player ~= nil then
        self:removeEntity(self.player, true)
      end

      self.player = guy
      self:addEntity(guy)
    end,
    advanceClock = function (self, dt)
      self.time = (self.time + dt) % (24 * 60)
    end,
    addEntity = function (self, entity)
      Log.printf('Welcome, %s\n', entity.__module)
      table.insert(self.entities, entity)
    end,
    removeEntity = function (self, entity, shouldGenerateEvent)
      require 'core.table'.maybeDrop(self.entities, entity)

      if entity.__module == 'Guy' then
        ---@cast entity Guy
        self.squad:removeFromSquad(entity)
        self.frozenEntities[entity] = nil
        if entity == self.player then
          self.player = nil
        end

        if shouldGenerateEvent then
          evalRule(
            ruleBook.onGuyRemoved,
            self,
            entity,
            self.world:getTile(entity.pos),
            ruleBook
          )
        end
      end
    end,
    switchMode = function (self)
      require 'sfx'.playBoop()
      if self.mode == 'normal' then
        self.mode = 'edit'
      elseif self.mode == 'edit' then
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
    isFrozen = function (self, entity)
      return self.frozenEntities[entity] or false
    end,
    syncCursorPos = function (self, vec)
      if self.mode == 'edit' then
        self.cursorPos = vec
      elseif self.mode == 'normal' then
        self.cursorPos = vec
      end
    end,
    effCursorPos = function (self, curX, curY)
      local player = self.player

      if not player then
        return 0, 0
      end

      local playerPos = player.pos

      if self.mode == 'normal' then
        curX = math.min(playerPos.x + CURSOR_MAX_DISTANCE, curX)
        curX = math.max(playerPos.x - CURSOR_MAX_DISTANCE, curX)
        curY = math.min(playerPos.y + CURSOR_MAX_DISTANCE, curY)
        curY = math.max(playerPos.y - CURSOR_MAX_DISTANCE, curY)
      end

      return curX, curY
    end,
    cursorColor = function (self)
      local Color = require 'Color'

      if self.mode == 'focus' then
        return Color.cursorYellow
      elseif self.mode == 'edit' then
        return Color.cursorGreen
      else
        return Color.cursorWhite
      end
    end,
  }
}

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
    enterHealingRune = function (guy, rune)
      guy.stats:heal(rune.restoredHp)
    end,
    enterHouse = function (guy, building)
      if guy.team ~= 'good' then
        return 'shouldNotMove'
      end
      guy.stats:setMaxHp(guy.stats.maxHp + 1)
      game:removeEntity(building, true)
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

---@param game Game
function Game.init(game)
  game.console = game.console or require 'Console'.new()
  game.stats = game.stats or require 'GameStats'.new()
  game.frozenEntities = require 'core.table'.weaken(game.frozenEntities or {}, 'k')
  game.time = game.time or (12 * 60)
  game.entities = game.entities or {}
  game.cursorPos = game.cursorPos or { x = 0, y = 0 }
  game.magnificationFactor = game.magnificationFactor or 1
  game.mode = game.mode or 'normal'
  game.painterTile = 'rock'

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
    game:addPlayer(Guy.makeLeader(Global.leaderSpawnLocation))
  end

  if game.player == nil then
    error 'no player'
  end

  game.player.stats:heal(4000)
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
function Game.mayRecruit(game, entity)
  if entity.__module ~= 'Guy' then return false end

  ---@cast entity Guy
  if not isRecruitCircleActive(game.recruitCircle) then
    return false
  elseif isGuyAPlayer(game, entity) then
    return false
  elseif isAFollower(game.squad, entity) then
    return false
  elseif entity.team ~= game.player.team then
    return false
  end

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
function Game.beginRecruiting(game)
  if game.mode ~= 'normal' then return end
  game.recruitCircle:reset()
end

---@param game Game
function Game.endRecruiting(game)
  for _, entity in ipairs(game.entities) do
    local mayRecruit = Game.mayRecruit(game, entity)
    if mayRecruit then
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
    if not game:isFrozen(entity) then
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

  game:removeEntity(guy, true)
  game:removeEntity(battle, true)
end

---@param game Game Game object
---@param dt number Time since last update
---@param visibility number How far we should see in tiles
---@param movementDirections core.Vector[] Momentarily pressed movement directions
function Game.updateGame(game, dt, movementDirections, visibility)
  if not game.player then
    Log.warn 'no player, game stopped'
    return
  end

  local visionSources = {{
    pos = game.player.pos,
    sight = 10
  }}

  if game.mode == 'edit' then
    table.insert(visionSources, {
      pos = game.cursorPos,
      sight = 10
    })
  end

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
          local function becomeStronger(guy)
            guy.stats:setMaxHp(guy.stats.maxHp + 2)
          end

          if entity.attacker.stats.hp <= 0 then
            becomeStronger(entity.defender)
            die(entity.attacker, game, entity)
          end

          if entity.defender.stats.hp <= 0 then
            becomeStronger(entity.attacker)
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

    return ruleBook.tileSpeeds[tile] or 1
  end

  for _, entity in ipairs(game.entities) do
    if entity.__module == 'Guy' then
        ---@cast entity Guy
      entity:update(
        dt * speedFactor(
          entity,
          game.world:getTile(entity.pos)
        )
      )
      if not game:isFrozen(entity) then
        entity:behave(game.guyDelegate)
      end
    end
  end
end

---@param game Game
---@param guy Guy
local function maybeCollect(game, guy)
  if game:isFrozen(guy) then return end

  local pos = guy.pos
  local patch = require 'World'.patchAt(game.world, pos)
  local patchCenterX, patchCenterY = require 'Patch'.patchCenter(patch)
  local tile = game.world:getTile(pos)

  local effect = ruleBook.onCollect[tile]
  if effect and effect.give then
    if effect.give then
      game.resources:add(effect.give)
    end

    if effect.replaceTile then
      game.world:setTile(pos, effect.replaceTile)
    end

    if effect.spawn then
      game:addEntity(effect.spawn { x = patchCenterX, y = patchCenterY })
    end
  end
end

---@param game Game
function Game.orderCollect(game)
  if game.player then
    maybeCollect(game, game.player)
  end

  for guy in pairs(game.squad.followers) do
    maybeCollect(game, guy)
  end
end

---@param game Game
function Game.orderBuild(game)
  local pos = game.cursorPos

  -- Check if no other entities
  for _, entity in ipairs(game.entities) do
    if Vector.equal(entity.pos, pos) then
      return
    end
  end

  local tile = game.world:getTile(pos)

  -- Is building on rock?
  if tile == 'rock' then
    ---@diagnostic disable-next-line: missing-fields
    game.resources:add { stone = 1 }
    game.world:setTile(pos, 'sand')
  end

  local building = require 'Building'.new { pos = pos }
  game:addEntity(building)
  evalRule(ruleBook.onBuild, game, building, tile, ruleBook)
end

---@param game Game
function Game.orderSummon(game)
  local guy = require 'Guy'.makeGoodGuy(game.cursorPos)
  if game.resources.pretzels <= 0 then
    echo(game, 'Not enough pretzels.')
    return
  end
  game:addEntity(guy)
  game.squad:addToSquad(guy)
  echo(game, ('%s was summonned.'):format(guy.name))
  evalRule(ruleBook.onSummon, game, guy, game.world:getTile(guy.pos), ruleBook)
end

---@param game Game
function Game.orderPaint(game)
  game.world:setTile(game.cursorPos, game.painterTile)
end

---@param game Game
function Game.orderDismiss(game)
  dismissSquad(game)
  evalRule(ruleBook.onDismiss, game, game.player, game.world:getTile(game.player.pos), ruleBook)
end

return Game
