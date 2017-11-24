local bit32 = require 'bit32'

it('rshift (JavaScript >>> operator)', function()
  assert.equal(4294967295, bit32.rshift(0xffffffff, 0))
  assert.equal(2, bit32.rshift(5, 1))
end)
