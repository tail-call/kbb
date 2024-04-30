local sounds = {}

local function sound(path)
  return love.audio.newSource(path, "static")
end

local sfx = {
  init = function()
    print('sfx did init')
    sounds = {
      boop = sound "res/boop.flac"
    }
  end,
  playBoop = function () 
    local sound = sounds.boop
    sound:stop()
    sound:play()
  end,
}

return sfx

