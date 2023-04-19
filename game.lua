local Guy = require('./guy').Guy
local canRecruitGuy = require('./guy').canRecruitGuy
local moveGuy = require('./guy').moveGuy
local warpGuy = require('./guy').warpGuy
local updateGuy = require('./guy').updateGuy
local loadWorld = require('./world').loadWorld
local setTile = require('./world').setTile
local getTile = require('./world').getTile
local isPassable = require('./world').isPassable
local ui = require('./ui')
local tbl = require('./tbl')
local vector = require('./vector')
local rng = require('./rng')
local ability = require('./ability')
local maybeDrop = require('./tbl').maybeDrop

---@class Building
---@field pos Vector Building's position

---@class Squad
---@field shouldFollow boolean
---@field followers { [Guy]: true }
---@field frozenGuys { [Guy]: true }

---@class Resources
---@field pretzels integer
---@field wood integer
---@field stone integer

---@class Battle
---@field attacker Guy Who initiated the battle
---@field defender Guy Who was attacked
---@field pos Vector Battle's location
---@field timer number Timer before current round finishes
---@field round number Current round number

---@class ConsoleMessage
---@field text string
---@field lifetime number Seconds before message is faded out

---@class Text
---@field text string
---@field pos Vector
---@field maxWidth number

---@class VisionSource
---@field pos Vector
---@field sight integer

---@class GameEntity
---@field type string
---@field object any

---@class GameEntity_Building
---@field type 'building'
---@field object Building

---@class GameEntity_Battle
---@field type 'battle'
---@field object Battle

---@class Game
---# Simulation
---@field world World Game world
---@field guyDelegate GuyDelegate Object that talks to guys
---@field collider Collider Object that performs collision checks between game world objects
---@field score integer Score the player has accumulated
---@field frozenGuys { [Guy]: true } Guys that shouldn't be rendered nor updated
---@field resources Resources Resources player may spend on upgrades
---@field entities GameEntity[] Things in the game world
---@field guys Guy[] Guys aka units
---@field player Guy A guy controlled by the player
---@field time number Time of day in seconds, max is 24*60
---@field squad Squad A bunch of guys that follows player's movement
---@field visionSourcesCo fun(): VisionSource Coroutine that will yield all vision sources in the game world
---@field texts Text[] Text objects in the game world
---# Meta
---@field isFocused boolean True if focus mode is on
---@field onLost (fun(): nil) | nil
---# UI
---@field consoleMessages ConsoleMessage[] Messages in the bottom console
---@field recruitCircle number | nil Radius of a circle thing used to recruit units
---@field ui UI User interface script
---@field activeTab integer Current active tab in the focus screen
---@field cursorPos Vector Points to a square player's cursor is aimed at
---# GFX
---@field magnificationFactor number How much the camera is zoomed in

local WHITE_COLOR = { 1, 1, 1, 1 }
local WHITE_PANEL_COLOR = { r = 1, g = 1, b = 1, a = 1 }
local BLACK_PANEL_COLOR = { r = 0, g = 0, b = 0, a = 1 }
local GRAY_PANEL_COLOR = { r = 0.5, g = 0.5, b = 0.5, a = 1 }
local DARK_GRAY_PANEL_COLOR = { r = 0.25, g = 0.25, b = 0.25, a = 1 }
---@type Vector
local EVIL_SPAWN_LOCATION = { x = 281, y = 195 }
local RECRUIT_CIRCLE_MAX_RADIUS = 6
local RECRUIT_CIRCLE_GROWTH_SPEED = 6
local BATTLE_ROUND_DURATION = 0.5

local SCORES_TABLE = {
  killedAnEnemy = 100,
  builtAHouse = 500,
}

---@type CollisionInfo
local NONE_COLLISION = { type = 'none' }
---@type CollisionInfo
local TERRAIN_COLLISION = { type = 'terrain' }

---@param game Game
---@param text string
local function echo(game, text)
  table.insert(game.consoleMessages, {
    text = text,
    lifetime = 6,
  })
  while #game.consoleMessages >= 8 do
    table.remove(game.consoleMessages, 1)
  end
end

---@param game Game
---@param guy Guy
local function freeze(game, guy)
  game.frozenGuys[guy] = true
end

---@param game Game
---@param guy Guy
local function unfreeze(game, guy)
  game.frozenGuys[guy] = nil
end

---@param game Game
---@param guy Guy
---@return boolean
local function isFrozen(game, guy)
  return game.frozenGuys[guy] or false
end

---@return Game
local function init()
  local game

  ---@type GuyDelegate
  local guyDelegate = {
    beginBattle = function (attacker, defender)
      freeze(game, attacker)
      freeze(game, defender)

      table.insert(game.entities, {
        type = 'battle',
        object = {
          attacker = attacker,
          defender = defender,
          pos = defender.pos,
          round = 1,
          timer = BATTLE_ROUND_DURATION,
        }
      })
    end,
    enterHouse = function (guy, entity)
      if guy.stats.hp >= guy.stats.maxHp then
        return false
      end
      guy.stats.hp = guy.stats.maxHp
      local idx = tbl.indexOf(game.entities, entity)
      table.remove(game.entities, idx)
      return true
    end,
  }

  game = {
    ---@type World
    world = nil,
    guyDelegate = guyDelegate,
    activeTab = 0,
    score = 0,
    frozenGuys = tbl.weaken({}, 'k'),
    resources = {
      pretzels = 0,
      wood = 0,
      stone = 0,
    },
    guys = {},
    time = math.random() * 24 * 60,
    entities = {},
    ---@type Guy
    player = nil,
    squad = {
      frozenGuys = tbl.weaken({}, 'k'),
      followers = {},
      shouldFollow = false,
    },
    buildings = {},
    recruitCircle = nil,
    ---@type fun(): nil
    onLost = nil,
    ---@type Vector
    cursorPos = { x = 0, y = 0 },
    magnificationFactor = 1,
    isFocused = false,
    texts = {
      {
        text = 'Build house on rock.',
        pos = { x = 269, y = 228 },
        maxWidth = 9,
      },
      {
        text = '\nGARDEN\n  o\n   f\n EDEN',
        pos = { x = 280, y = 194 },
        maxWidth = 8,
      },
    },
    ui = ui.makeRoot({}, {
      ---@type PanelUI
      ui.makePanel(ui.origin(), 320, 8, GRAY_PANEL_COLOR, {
        coloredText = function ()
          return {
            WHITE_COLOR,
            string.format(
              'Score: %d | FPS: %.1f\n%02d:%02d',
              game.score,
              love.timer.getFPS(),
              math.floor(game.time / 60),
              math.floor(game.time % 60)
            ),
          }
        end
      }),
      ---@type PanelUI
      ui.makePanel(ui.origin():translate(0, 8), 88, 184, GRAY_PANEL_COLOR, {
        shouldDraw = function ()
          return game.isFocused
        end,
        text = function ()
          local tileUnderCursor = getTile(game.world, game.cursorPos) or '???'
          return string.format(
            ''
              .. 'Time: %02d:%02d\n (paused)\n'
              .. 'Terrain:\n %s'
              .. '\nCoords:\n %sX %sY'
              .. '\nB] build\n (5 wood)'
              .. '\nM] message'
              .. '\nR] ritual'
              .. '\nT] warp',
            math.floor(game.time / 60),
            math.floor(game.time % 60),
            tileUnderCursor,
            game.cursorPos.x,
            game.cursorPos.y
          )
        end
      }),
      -- Empty underlay for console
      ---@type PanelUI
      ui.makePanel(ui.origin():translate(88, 144), 320-80, 52, DARK_GRAY_PANEL_COLOR, {
        shouldDraw = function ()
          return game.isFocused
        end,
      }),
      ui.makePanel(ui.origin():translate(320-88, 8), 88, 200-16-52+4, BLACK_PANEL_COLOR, {
        shouldDraw = function ()
          return game.isFocused
        end,
        text = function ()
          local function charSheet(guy)
            return function ()
              return string.format(
                ''
                  .. 'Name:\n %s\n'
                  .. 'Rank:\n Harmless\n'
                  .. 'Coords:\n %sX %sY\n'
                  .. 'HP:\n %s/%s\n'
                  .. 'Action:\n %.2f/%.2f\n',
                guy.name,
                guy.pos.x,
                guy.pos.y,
                guy.stats.hp,
                guy.stats.maxHp,
                guy.time,
                guy.speed
              )
            end
          end

          local function controls()
            return ''
              .. ' CONTROLS  \n'
              .. 'WASD:  move\n'
              .. 'LMB:recruit\n'
              .. 'Spc:  focus\n'
              .. '1234: scale\n'
              .. 'F:   follow\n'
              .. 'G:  dismiss\n'
              .. 'C:     chop\n'
              .. 'Z:     zoom\n'
          end


          local header = '<- Tab ->\n\n'
          local tabs = { charSheet(game.player), controls }
          local idx = 1 + (game.activeTab % #tabs)

          return header .. tabs[idx]()
        end,
      }),
      ---@type PanelUI
      ui.makePanel(ui.origin():translate(0, 192), 320, 8, GRAY_PANEL_COLOR, {
        text = function ()
          return string.format(
            'Wood: %s | Stone: %s | Pretzels: %s',
            game.resources.wood,
            game.resources.stone,
            game.resources.pretzels
          )
        end,
      }),
      -- Pause icon
      ui.makePanel(ui.origin():translate(92, 132), 3, 8, WHITE_PANEL_COLOR, {
        shouldDraw = function ()
          return game.isFocused
        end,
      }),
      ui.makePanel(ui.origin():translate(97, 132), 3, 8, WHITE_PANEL_COLOR, {
        shouldDraw = function ()
          return game.isFocused
        end,
      }),
    })
  }

  function game.visionSourcesCo()
    coroutine.yield({ pos = game.player.pos, sight = 10 })

    for _, guy in ipairs(game.guys) do
      if guy.team == 'good' then
        coroutine.yield({ pos = guy.pos, sight = 8 })
      end
    end

    return {
      pos = game.cursorPos,
      sight = math.max(2, game.recruitCircle or 0),
    }
  end


  ---@type Collider
  function game.collider(nothing, v)
    local otherGuy = tbl.find(game.guys, function (guy)
      return vector.equal(guy.pos, v)
    end)
    if otherGuy then
      return { type = 'guy', guy = otherGuy }
    end
    local entity = tbl.find(game.entities, function (entity)
      return vector.equal(entity.object.pos, v)
    end)
    if entity then
      return { type = 'entity', entity = entity }
    end
    if isPassable(game.world, v) then
      return NONE_COLLISION
    end
    return TERRAIN_COLLISION
  end

  guyDelegate.collider = game.collider

  game.player = Guy.makeLeader({ x = 269, y = 231 })
  game.player.name = 'Leader'
  game.guys = {
    game.player,
    Guy.makeGoodGuy({ x = 274, y = 231 }),
    Guy.makeGoodGuy({ x = 272, y = 231 }),
    Guy.makeGoodGuy({ x = 274, y = 229 }),
    Guy.makeGoodGuy({ x = 272, y = 229 }),
  }
  game.buildings = {
    { pos = { x = 277, y = 233 } }
  }
  game.world = loadWorld('map.png')
  game.squad = {
    shouldFollow = true,
    ---@type Guy[]
    followers = tbl.weaken({}, 'k'),
  }
  game.cursorPos = game.player.pos
  game.consoleMessages = {
    {
      text = 'Welcome to Kobold Princess Simulator.',
      lifetime = 10,
    },
    {
      text = 'This is day 1 of your reign.',
      lifetime = 16,
    }
  }
  return game
end

---@param game Game
---@param guy Guy
---@return boolean
local function mayRecruit(game, guy)
  if not game.recruitCircle then return false end
  if guy == game.player then return false end
  if game.squad.followers[guy] then return false end
  if not canRecruitGuy(guy) then return false end
  return vector.dist(guy.pos, game.cursorPos) < game.recruitCircle + 0.5
end

local function toggleFollow(game)
  game.squad.shouldFollow = not game.squad.shouldFollow
end

local function dismissSquad(game)
  for guy in pairs(game.squad.followers) do
    game.squad.followers[guy] = nil
  end
end

local function beginRecruiting(game)
  if game.isFocused then return end
  game.recruitCircle = 0
end

local function endRecruiting(game)
  for _, guy in tbl.ifilter(game.guys, function (guy)
    return mayRecruit(game, guy)
  end) do
    game.squad.followers[guy] = true
  end
  game.squad.shouldFollow = true
  game.recruitCircle = nil
end

---@param game Game
local function isReadyForOrder(game)
  return game.player.mayMove
end

---@param game Game
---@param vec Vector
---@return 'shouldRetryOtherDirection' | 'shouldStop'
local function orderMove(game, vec)
  if game.isFocused then return 'shouldStop' end

  if game.squad.shouldFollow then
    for guy in pairs(game.squad.followers) do
      if not isFrozen(game, guy) then
        moveGuy(guy, vec, game.guyDelegate)
      end
    end
  end
  if not isFrozen(game, game.player) then
    if moveGuy(game.player, vec, game.guyDelegate) then
      return 'shouldStop'
    end
  end
  return 'shouldRetryOtherDirection'
end

---@param game Game
---@param attacker Guy
---@param defender Guy
---@param damageModifier number
local function fight(game, attacker, defender, damageModifier)
  local attackerAction = rng.weightedRandom(attacker.abilities)
  local defenderAction = rng.weightedRandom(attacker.abilities)

  local attackerEffect = attackerAction.ability.combat
  local defenderEffect = defenderAction.ability.defence

  ---@param guy Guy
  ---@param damage number
  local function dealDamage(guy, damage)
    guy.stats.hp = guy.stats.hp - damage * damageModifier
    echo(game, string.format('%s got %s damage, has %s hp now.', guy.name, damage, guy.stats.hp))
  end

  local function say(message)
    echo(game, string.format(
      message,
      attacker.name, defender.name, damageModifier
    ))
  end

  if defenderEffect == ability.effects.defence.parry then
    if attackerEffect == ability.effects.combat.normalAttack then
      say('%s attacked, but %s parried!')
      dealDamage(defender, 0)
    elseif attackerEffect == ability.effects.combat.miss then
      say('%s attacked and missed, %s gets an extra turn!')
      fight(game, defender, attacker, damageModifier)
    elseif attackerEffect == ability.effects.combat.criticalAttack then
      say('%s did a critical attack, but %s parried! They strike back with %sx damage.')
      fight(game, defender, attacker, damageModifier * 2)
    end
  elseif defenderEffect == ability.effects.defence.takeDamage then
    if attackerEffect == ability.effects.combat.normalAttack then
      say('%s attacked! %s takes damage.')
      dealDamage(defender, attackerAction.weight)
    elseif attackerEffect == ability.effects.combat.miss then
      say('%s attacked but missed!')
      dealDamage(defender, 0)
    elseif attackerEffect == ability.effects.combat.criticalAttack then
      say('%s did a critical attack! %s takes %sx damage.')
      dealDamage(defender, attackerAction.weight * 2)
    end
  end
end

---@param game Game
---@param dt number
local function advanceClock(game, dt)
  return (game.time + dt) % (24 * 60)
end


---@param game Game
---@param guy Guy
local function killGuy(game, guy)
  maybeDrop(game.guys, guy)
  game.squad.followers[guy] = nil

  if guy.team == 'evil' then
    game.resources.pretzels = game.resources.pretzels + 1
    game.score = game.score + SCORES_TABLE.killedAnEnemy
  end

  if guy == game.player and game.onLost then
    game.onLost()
  end
end

---@param game Game
---@param entity GameEntity_Battle
---@param dt number
local function updateBattle(game, entity, dt)
  local battle = entity.object
  battle.timer = battle.timer - dt
  if battle.timer < 0 then
    fight(game, battle.attacker, battle.defender, 1)
    battle.attacker, battle.defender = battle.defender, battle.attacker

    ---@param guy Guy
    local function maybeDie(guy)
      if guy.stats.hp <= 0 then
        echo(game, (guy.name .. ' dies with %s hp.'):format(guy.stats.hp))
        killGuy(game, guy)
      end
    end

    if battle.attacker.stats.hp > 0 and battle.defender.stats.hp > 0 then
      -- Keep fighting
      battle.timer = BATTLE_ROUND_DURATION
    else
      -- Fight is over
      maybeDrop(game.entities, entity)
      maybeDie(battle.attacker)
      maybeDie(battle.defender)
      unfreeze(game, battle.attacker)
      unfreeze(game, battle.defender)
    end

    -- Next round
    battle.round = battle.round + 1
  end
end

---@param game Game
---@param dt number
local function updateBattles(game, dt)
  for _, entity in ipairs(game.entities) do
    if entity.type == 'battle' then
      ---@cast entity any
      updateBattle(game, entity, dt)
    end
  end
end

---@param game Game
---@param dt number
local function updateGuys(game, dt)
  for _, guy in ipairs(game.guys) do
    if not isFrozen(game, guy) then
      updateGuy(guy, dt, game.guyDelegate)
    end
  end
end

---@param game Game
---@param dt number
local function updateRecruitCircle(game, dt)
  if game.recruitCircle == nil then return end

  game.recruitCircle = math.min(
    game.recruitCircle + dt * RECRUIT_CIRCLE_GROWTH_SPEED,
    RECRUIT_CIRCLE_MAX_RADIUS
  )
end

---@param consoleMessages ConsoleMessage[]
---@param dt number
local function updateConsole(consoleMessages, dt)
  for _, message in ipairs(consoleMessages) do
    message.lifetime = math.max(message.lifetime - dt, 0)
  end
end

---@param game Game
---@param dt number
local function updateGame(game, dt)
  updateConsole(game.consoleMessages, dt)
  updateRecruitCircle(game, dt)

  if game.isFocused then return end

  game.time = advanceClock(game, dt)
  updateBattles(game, dt)
  updateGuys(game, dt)
end

local function orderFocus(game)
  game.isFocused = not game.isFocused
end

---@param game Game
---@param guy Guy
local function maybeChop(game, guy)
  if isFrozen(game, guy) then return end

  local pos = guy.pos
  local tile = getTile(game.world, pos)
  if tile == 'forest' then
    game.resources.wood = game.resources.wood + 1
    setTile(game.world, pos, 'grass')
    table.insert(game.guys, Guy.makeEvilGuy(EVIL_SPAWN_LOCATION))
  end
end

local function orderChop(game)
  maybeChop(game, game.player)
  for guy in pairs(game.squad.followers) do
    maybeChop(game, guy)
  end
end

---@param game Game
local function switchMagn(game)
  if game.magnificationFactor == 1 then
    game.magnificationFactor = 2/3
  elseif game.magnificationFactor == 2/3 then
    game.magnificationFactor = 2
  else
    game.magnificationFactor = 1
  end
end

---@param game Game
local function orderBuild(game)
  if game.resources.wood < 5 then
    return
  end
  local pos = game.cursorPos
  for _, entity in ipairs(game.entities) do
    if vector.equal(entity.object.pos, pos) then
      return
    end
  end
  local t = getTile(game.world, pos)
  if t == 'rock' then
    game.resources.stone = game.resources.stone + 1
    table.insert(game.guys, Guy.makeStrongEvilGuy(EVIL_SPAWN_LOCATION))
    setTile(game.world, pos, 'sand')
  end
  game.resources.wood = game.resources.wood - 5
  table.insert(game.entities, {
    type = 'building',
    object = { pos = pos }
  })
  game.score = game.score + SCORES_TABLE.builtAHouse
  game.isFocused = false
end

---@return integer
local function randomLetterCode()
  local letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
  local idx = math.random(#letters)
  return string.byte(letters, idx)
end

---@param game Game
local function orderScribe(game)
  table.insert(game.texts, {
    text = string.format(
      '%c%c\n%c%c',
      randomLetterCode(),
      randomLetterCode(),
      randomLetterCode(),
      randomLetterCode()
    ),
    pos = game.cursorPos,
    maxWidth = 4,
  })
  game.isFocused = false
end

---@param game Game
local function orderSummon(game)
  if game.resources.pretzels <= 0 then
    return
  end

  game.resources.pretzels = game.resources.pretzels - 1
  local guy = Guy.makeGoodGuy({
    x = game.cursorPos.x,
    y = game.cursorPos.y
  })
  echo(game, ('%s was summonned.'):format(guy.name))
  table.insert(game.guys, guy)
  game.squad.followers[guy] = true

  game.isFocused = not game.isFocused
end

---@param game Game
---@param scancode string
local function handleInput(game, scancode)
  if scancode == 'tab' then
    game.activeTab = game.activeTab + 1
  elseif scancode == 'b' then
    orderBuild(game)
  elseif scancode == 'm' then
    orderScribe(game)
  elseif scancode == 'r' then
    orderSummon(game)
  elseif scancode == 't' then
    warpGuy(game.player, game.cursorPos)
    game.isFocused = false
  elseif scancode == 'space' then
    orderFocus(game)
  end
end

return {
  dismissSquad = dismissSquad,
  handleInput = handleInput,
  orderChop = orderChop,
  orderMove = orderMove,
  echo = echo,
  toggleFollow = toggleFollow,
  updateGame = updateGame,
  orderFocus = orderFocus,
  beginRecruiting = beginRecruiting,
  endRecruiting = endRecruiting,
  switchMagn = switchMagn,
  isFrozen = isFrozen,
  mayRecruit = mayRecruit,
  isReadyForOrder = isReadyForOrder,
  init = init,
}