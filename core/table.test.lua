local assert = require 'core.test'.assert
local group = require 'core.test'.group
local M = require 'core.table'

group('core.table/find', function ()
  assert(M.find({ 1, 2, 3, 4 }, function (item)
    return item % 2 == 0
  end) == 2)

  assert(M.find({}, function () return true end) == nil)
end)