local Guy = require('./guy').Guy
local canRecruitGuy = require('./guy').canRecruitGuy
local moveGuy = require('./guy').moveGuy
local updateGuy = require('./guy').updateGuy
local loadWorld = require('./world').loadWorld
local setTile = require('./world').setTile
local getTile = require('./world').getTile
local drawWorld = require('./world').drawWorld
local isPassable = require('./world').isPassable
local draw = require('./draw')
local tbl = require('./tbl')
local vector = require('./vector')

---@class Building
---@field pos Vector

---@class Squad
---@field shouldFollow boolean
---@field followers { [Guy]: true }

---@class Resources
---@field pretzels integer
---@field wood integer
---@field stone integer

---@class Battle
---@field attacker Guy
---@field defender Guy
---@field pos Vector
---@field timer number

local whiteColor = { 1, 1, 1, 1 }
local redColor = { 1, 0, 0, 1 }
local yellowColor = { 1, 1, 0, 1 }

local recruitCircleMaxRadius = 6
local recruitCircleGrowthSpeed = 6
local lerpSpeed = 5

local instructions1 = ''
  .. 'Move your troops with arrow keys.'
  .. '\n\n'
  .. 'Press 1, 2, 3, 4 to change window scale.'
  .. '\n\n'
  .. 'Press F to toggle follow mode.'
  .. '\n\n'
  .. 'G to dismiss squad.\n\nSpace to recruit units.'
  .. '\n\n'
  .. 'C to chop wood.'
  .. '\n\n'
  .. 'Click to biuld a house (5 wood).'
  .. '\n\n'
  .. 'Z to switch camera zoom.'

local instructions2 = ''
  .. 'Your enemies are red. Bump into them to fight.'
  .. '\n\n'
  .. 'If your character dies, you lose.'

---@type CollisionInfo
local noneCollision = { type = 'none' }
local terrainCollision = { type = 'terrain' }

local game = {
  ---@type World
  world = nil,
  ---@type { [Guy]: true }
  frozenGuys = tbl.weaken({}, 'k'),
  ---@type Resources
  resources = {
    pretzels = 1,
    wood = 0,
    stone = 10,
  },
  ---@type Guy[]
  guys = {},
  ---@type Battle[]
  battles = {},
  ---@type Guy
  player = nil,
  ---@type Squad
  squad = {
    frozenGuys = tbl.weaken({}, 'k'),
    shouldFollow = false,
  },
  ---@type Building[]
  buildings = {},
  ---@type Vector
  lerpVec = { x = 0, y = 0 },
  ---@type number | nil
  recruitCircle = nil,
  ---@type fun(): nil
  onLost = nil,
  ---@type Vector
  cursorPos = { x = 0, y = 0 },
  magnificationFactor = 1,
}

---@param guy Guy
local function freeze(guy)
  game.frozenGuys[guy] = true
end

---@param guy Guy
local function unfreeze(guy)
  game.frozenGuys[guy] = nil
end

---@param guy Guy
---@return boolean
local function isFrozen(guy)
  return game.frozenGuys[guy] or false
end

---@type Collider
local function collider(nothing, v)
  local otherGuy = tbl.find(game.guys, function (guy)
    return vector.equal(guy.pos, v)
  end)
  if otherGuy then
    return { type = 'guy', guy = otherGuy }
  end
  local battle = tbl.find(game.battles, function (battle)
    return vector.equal(battle.pos, v)
  end)
  if battle then
    return terrainCollision
  end
  if isPassable(game.world, v) then
    return noneCollision
  end
  return terrainCollision
end

---@generic T
---@param items T[]
---@param item T
local function maybeDrop(items, item)
  local i = tbl.indexOf(items, item)
  if not i then return end

  tbl.fastRemoveAtIndex(items, i)
end

---@type GuyDelegate
local guyDelegate = {
  beginBattle = function (attacker, defender)
    freeze(attacker)
    freeze(defender)

    table.insert(game.battles, {
      attacker = attacker,
      defender = defender,
      pos = defender.pos,
      timer = 1,
    })
  end,
  collider = collider,
}

function game:init()
  self.player = Guy.makeLeader({ x = 268, y = 227 })
  self.guys = {
    self.player,
    Guy.makeGoodGuy({ x = 269, y = 228 }),
    Guy.makeGoodGuy({ x = 269, y = 230 }),
    Guy.makeGoodGuy({ x = 270, y = 228 }),
    Guy.makeGoodGuy({ x = 270, y = 230 }),
    Guy.makeEvilGuy({ x = 364, y = 199 }),
    Guy.makeEvilGuy({ x = 364, y = 199 }),
    Guy.makeEvilGuy({ x = 364, y = 199 }),
    Guy.makeEvilGuy({ x = 364, y = 199 }),
    Guy.makeEvilGuy({ x = 364, y = 199 }),
    Guy.makeEvilGuy({ x = 364, y = 199 }),
    Guy.makeEvilGuy({ x = 364, y = 199 }),
    Guy.makeEvilGuy({ x = 364, y = 199 }),
    Guy.makeEvilGuy({ x = 364, y = 199 }),
    Guy.makeEvilGuy({ x = 364, y = 199 }),
    Guy.makeEvilGuy({ x = 364, y = 199 }),
    Guy.makeEvilGuy({ x = 364, y = 199 }),
    Guy.makeEvilGuy({ x = 364, y = 199 }),
    Guy.makeEvilGuy({ x = 364, y = 199 }),
    Guy.makeEvilGuy({ x = 364, y = 199 }),
    Guy.makeEvilGuy({ x = 364, y = 199 }),
    Guy.makeEvilGuy({ x = 364, y = 199 }),
    Guy.makeEvilGuy({ x = 364, y = 199 }),
    Guy.makeEvilGuy({ x = 364, y = 199 }),
  }
  self.buildings = {
    { pos = { x = 15, y = 14 } }
  }
  self.world = loadWorld('map.png')
  self.squad = {
    shouldFollow = true,
    ---@type Guy[]
    followers = tbl.weaken({}, 'k'),
  }
  self.lerpVec = self.player.pos
end

---@param guy Guy
---@return boolean
local function mayRecruit(guy)
  if guy == game.player then return false end
  if game.squad.followers[guy] then return false end
  if not canRecruitGuy(guy) then return false end
  return vector.dist(guy.pos, game.player.pos) < game.recruitCircle + 0.5
end

function game:toggleFollow()
  self.squad.shouldFollow = not self.squad.shouldFollow
end

function game:dismissSquad()
  for guy in pairs(self.squad.followers) do
    self.squad.followers[guy] = nil
  end
end

function game:beginRecruiting()
  self.recruitCircle = 0
end

function game:endRecruiting()
  for _, guy in tbl.ifilter(self.guys, function (guy)
    return mayRecruit(guy)
  end) do
    self.squad.followers[guy] = true
  end
  self.squad.shouldFollow = true
  self.recruitCircle = nil
end

function game:orderMove(vec)
  if self.squad.shouldFollow then
    for guy in pairs(self.squad.followers) do
      if not isFrozen(guy) then
        moveGuy(guy, vec, guyDelegate)
      end
    end
  end
  if not isFrozen(self.player) then
    moveGuy(self.player, vec, guyDelegate)
  end
end

---@param squad Squad
---@return integer
local function countFollowers(squad)
  local counter = 0
  for _ in pairs(squad.followers) do
    counter = counter + 1
  end
  return counter
end

local function drawGame(game)
  love.graphics.push('transform')

  -- Draw terrain

  draw.centerCameraOn(game.lerpVec, game.magnificationFactor)

  drawWorld(game.world)

  -- Draw in-game objects

  draw.textAtTile(instructions1, { x = 268, y = 227 }, 8)
  draw.textAtTile(instructions2, { x = 280, y = 227 }, 9)

  for _, building in ipairs(game.buildings) do
    draw.house(building.pos)
  end

  draw.drawGuys(game.guys, isFrozen)

  if game.recruitCircle then
    for _, guy in tbl.ifilter(game.guys, function (guy)
      return mayRecruit(guy)
    end) do
      draw.recruitableHighlight(guy.pos)
    end
  end

  for _, battle in ipairs(game.battles) do
    draw.battle(battle.pos)
  end

  if game.recruitCircle then
    draw.recruitCircle(game.player.pos, game.recruitCircle)
  end

  -- Draw cursor

  local cx, cy = draw.getCursorCoords()
  do
    local cursorPos = { x = cx, y = cy }
    local collision = collider(nil, cursorPos)
    local cursorColor = whiteColor

    local tile = getTile(game.world, cursorPos) or '???'

    if collision.type == 'guy' then
      cursorColor = yellowColor
    elseif collision.type == 'terrain' then
      cursorColor = redColor
    end
    local r, g, b, a = unpack(cursorColor)
    draw.withColor(r, g, b, a, function ()
      draw.cursor(cursorPos)
      draw.textAtTile(
        '(' .. cx .. ',' .. cy .. ')\n' .. tile,
        vector.add(cursorPos, { x = 0, y = 1 }),
        8
      )
    end)
    game.cursorPos = cursorPos
  end

  love.graphics.pop()

  -- Draw HUD

  draw.hud(
    countFollowers(game.squad),
    game.squad.shouldFollow,
    game.resources
  )
end

local function fight(attacker, defender)
  if math.random() > 0.6 then
    return attacker, defender
  else
    return defender, attacker
  end
end

---@param dt number
function game:update(dt)
  game.lerpVec = vector.lerp(
    game.lerpVec,
    vector.midpoint(game.player.pos, game.cursorPos),
    dt * lerpSpeed
  )

  for _, battle in ipairs(self.battles) do
    battle.timer = battle.timer - dt
    if battle.timer < 0 then
      maybeDrop(self.battles, battle)
      local winner, loser = fight(battle.attacker, battle.defender)
      unfreeze(winner)
      maybeDrop(game.guys, loser)
      game.squad.followers[loser] = nil
      if loser == game.player then
        game.onLost()
      end
    end
  end
  for _, guy in ipairs(self.guys) do
    if not isFrozen(guy) then
      updateGuy(guy, dt, guyDelegate)
    end
  end
  if self.recruitCircle ~= nil then
    self.recruitCircle = math.min(
      self.recruitCircle + dt * recruitCircleGrowthSpeed,
      recruitCircleMaxRadius
    )
  end
end

function game:orderBuild()
  if isFrozen(game.player) then
    return
  end
  if game.resources.wood < 5 then
    return
  end
  local pos = game.cursorPos
  for _, building in ipairs(game.buildings) do
    if vector.equal(building.pos, pos) then
      return
    end
  end
  game.resources.wood = game.resources.wood - 5
  table.insert(game.buildings, { pos = pos })
end

local function maybeChop(guy)
  if isFrozen(guy) then return end

  local pos = guy.pos
  local t = getTile(game.world, pos)
  if t == 'forest' then
    game.resources.wood = game.resources.wood + 1
    setTile(game.world, pos, 'grass')
  end
end

function game:orderChop()
  maybeChop(game.player)
  for guy in pairs(game.squad.followers) do
    maybeChop(guy)
  end
end

local function switchMagn()
  if game.magnificationFactor == 1 then
    game.magnificationFactor = 0.5
  elseif game.magnificationFactor == 0.5 then
    game.magnificationFactor = 2
  else
    game.magnificationFactor = 1
  end
end

return {
  game = game,
  drawGame = drawGame,
  switchMagn = switchMagn,
}