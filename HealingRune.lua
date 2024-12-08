---When you step on it, you heal.
---@class HealingRune: Object2D, core.class
---@field restoredHp number
---@field rechargeTime number
---@field __module "HealingRune"
local HealingRune = Class {
  ...,
  slots = { '!restoredHp', '!rechargeTime'},
  ---@type HealingRune
  index = {},
  tooltipText = function ()
    return 'Healing rune'
  end,
}

return HealingRune