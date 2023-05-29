local path = ...

if not path then
  print(('You are in %s.'):format(Sys.getCurrentDir()))
  return
end

Sys.setCurrentDir(path)