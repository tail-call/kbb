---Evaluates a rule from the rulebook
---@param rule table
---@param game Game
---@param entity Object2D
---@param tile World.tile
local function evalRule(rule, game, entity, tile)
  if rule.exec then
    rule.exec(game, entity, tile)
  end

  local shouldEval = true

  if rule.ifTeam then
    -- TODO: cast to Guy when needed
    shouldEval = rule.ifTeam == entity['team']
  end

  if rule.ifTile then
    shouldEval = rule.ifTile == tile
  end

  if rule.ifPlayer then
    shouldEval = game.player == entity
  end

  if shouldEval then
    if rule.setTile then
      game.world:setTile(entity.pos, rule.setTile)
    end

    for _, childRule in ipairs(rule) do
      evalRule(childRule, game, entity, tile)
    end
  elseif rule.default then
    evalRule(rule.default, game, entity, tile)
  end
end

local ruleBook

ruleBook = {
  buildingCostWood = 5,
  scoresTable = {
    killedAnEnemy = 100,
    builtAHouse = 500,
    dead = -1000,
  },
  moveCostsTable = {
    dismissSquad = 1,
    summon = 25,
    build = 50,
  },
  onBuild = {
    exec = function (game)
      -- Build
      game.resources:add { wood = -ruleBook.buildingCostWood }
      game.player.stats:addMoves(-ruleBook.moveCostsTable.build)
      game.stats:addScore(ruleBook.scoresTable.builtAHouse)
    end,
  },
  onSummon = {
    exec = function (game)
      game.resources:add { pretzels = -1 }
      game.player.stats:addMoves(-ruleBook.moveCostsTable.summon)
    end,
  },
  onDismiss = {
    exec = function (game, cb)
      if game.player.stats.moves >= ruleBook.moveCostsTable.dismissSquad then
        game.player.stats:addMoves(-ruleBook.moveCostsTable.dismissSquad)
        cb()
      end
    end,
  },
  onGuyRemoved = {
    {
      ifPlayer = true,
      exec = function (game)
        game:addPlayer()
        -- TODO: build these into rules instead
        game.stats:addDeaths(1)
        game.stats:addScore(ruleBook.scoresTable.dead)
      end,
    },
    {
      ifTeam = 'evil',
      exec = function (game)
        game.resources:add { pretzels = 1 }
        game.stats:addScore(ruleBook.scoresTable.killedAnEnemy)
      end,
    },
    {
      ifTeam = 'evil',
      { ifTile = 'sand', setTile = 'grass' },
      { ifTile = 'grass', setTile = 'forest' },
      { ifTile = 'forest', setTile = 'water' },
    },
    {
      ifTeam = 'good',
      {
        ifTile = 'sand',
        setTile = 'rock',
        default = { setTile = 'rock' },
      },
    },
  },
  onCollect = {
    forest = {
      give = { wood = 1 },
      replaceTile = 'grass',
      spawn = require 'Guy'.makeEvilGuy,
    },
    rock = {
      give = { stone = 1 },
      replaceTile = 'cave',
      spawn = require 'Guy'.makeStrongEvilGuy,
    },
    grass = {
      give = { grass = 1 },
      replaceTile = 'sand',
    },
    water = {
      give = { water = 1 },
      replaceTile = 'sand',
    },
  },
}

return {
  evalRule = evalRule,
  ruleBook = ruleBook,
}