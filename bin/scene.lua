local sceneName = ...

if not sceneName then
  print('scene: name is required\n')
  return
end

Sys.goToScene(sceneName, ...)