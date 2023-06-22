-- This exists to allow loading love2d quads from the save file

return {
  new = function (...)
    return love.graphics.newQuad(...)
  end
}