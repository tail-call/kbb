dofile 'Global.lua'
dofile 'conf.lua'

Class = require 'core.class'.defineClass
Log = require 'core.log'

local function moduleNameToPath(name)
  name = string.gsub(name, '%.', '/')
  name = string.gsub(name, '$', '.lua')
  return name
end

local function preloadResources(resources)
  for k, v in pairs(resources) do
    package.preload[k] = v
  end
end

local loader = {
  image = love.graphics.newImage,
  imageData = love.image.newImageData,
  ui = function(moduleName)
    return function (...)
      return require 'UI'.makeUIScript(
        moduleNameToPath(moduleName), ...
      )
    end
  end,
  scene = function(path)
    return {
      go = function (...)
        return require 'Scene'.loadScene(
          moduleNameToPath(path), ...
        )
      end
    }
  end,
}

local function startGame()
  require(Global.initialScene).go()
end

function love.load()
  love.graphics.setDefaultFilter('linear', 'nearest')
  love.graphics.setLineStyle('rough')
  love.mouse.setVisible(false)

  preloadResources {
    ['res/map.png'] = loader.imageData,
    ['res/cga8.png'] = loader.imageData,
    ['res/tiles.png'] = loader.image,
    ['ui.hud'] = loader.ui,
    ['ui.menu'] = loader.ui,
    ['scene.menu'] = loader.scene,
    ['scene.game'] = loader.scene,
    ['scene.console'] = loader.scene,
    ['scene.terminal'] = loader.scene,
  }

  math.randomseed(os.time())

  require 'sfx'.init()

  startGame()
end
