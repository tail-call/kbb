---Global variables. `main.lua` defines default values, `conf.lua`
---contains actual configuration.
Global = {
  ---If true, warning functions from `core.log` module will crash the program
  shouldCrashOnWarnings = false,
  ---Module to be required and used as a starting scene
  initialScene = '<not a scene>',
}

dofile('conf.lua')

Class = require 'core.class'.defineClass

local function moduleNameToPath(name)
  name = string.gsub(name, '%.', '/')
  name = string.gsub(name, '$', '.lua')
  return name
end

local function uiLoader(moduleName)
  return function (...)
    return require 'UI'.makeUIScript(
      moduleNameToPath(moduleName), ...
    )
  end
end

local function sceneLoader(path)
  return {
    go = function (...)
      return require 'Scene'.loadScene(
        moduleNameToPath(path), ...
      )
    end
  }
end

-- Initialization
do
  package.preload['res/map.png'] = love.image.newImageData
  package.preload['res/cga8.png'] = love.image.newImageData
  package.preload['res/tiles.png'] = love.graphics.newImage
  package.preload['ui.screen'] = uiLoader
  package.preload['ui.menu'] = uiLoader
  package.preload['scene.menu'] = sceneLoader
  package.preload['scene.game'] = sceneLoader
  package.preload['scene.console'] = sceneLoader
  package.preload['scene.terminal'] = sceneLoader

  math.randomseed(os.time())
end

function love.load()
  love.graphics.setDefaultFilter('linear', 'nearest')
  love.graphics.setLineStyle('rough')
  love.mouse.setVisible(false)
  require 'Tileset'.load()
  require(Global.initialScene).go()
end