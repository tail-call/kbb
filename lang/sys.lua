---@class lang.System
---@field screen terminal.Screen
---@field goToScene fun(name: string, ...)
---@field setCurrentDir fun(path: string)
---@field getCurrentDir fun(): string
---@field getKey fun(): love.Scancode

---@type lang.System
Sys = {}