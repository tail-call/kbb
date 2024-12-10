local assert = require 'core.test'.assert
local assertEq = require 'core.test'.assertEq
local group = require 'core.test'.group
local M = require 'core.table'

group('core.table/find', function ()
  assert(M.find({ 1, 2, 3, 4 }, function (item)
    return item % 2 == 0
  end) == 2)

  assert(M.find({}, function () return true end) == nil)
end)

group('core.table/fill', function ()
  local input = { 1, 2, 3, 4, 5 }
  local fillValue = 'test'

  local filled = M.fill(input, fillValue)

  assert(#filled == #input)

  for _, x in ipairs(filled) do
    assert(x == fillValue)
  end
end)

group('core.table/stringifyArray', function ()
  local input = { 5, 4, 3, 2, 1 }

  assertEq(M.stringifyArray(input), '{ 5, 4, 3, 2, 1 }');
  assertEq(M.stringifyArray {}, '{}');
end)