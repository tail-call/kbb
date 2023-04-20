---@class GameEntity
---@field type string
---@field object any

---@class GameEntity_Building: GameEntity
---@field type 'building'
---@field object Building

---@class GameEntity_Battle: GameEntity
---@field type 'battle'
---@field object Battle
--
---@class GameEntity_Text: GameEntity
---@field type 'text'
---@field object Text

---@param object Building
---@return GameEntity_Building
local function makeBuildingEntity(object)
  ---@type GameEntity_Building
  local entity = {
    type = 'building',
    object = object,
  }
  return entity
end

---@param object Battle
---@return GameEntity_Battle
local function makeBattleEntity(object)
  ---@type GameEntity_Battle
  local entity = {
    type = 'battle',
    object = object,
  }
  return entity
end

return {
  makeBuildingEntity = makeBuildingEntity,
  makeBattleEntity = makeBattleEntity,
}