local bit32s = require 'bit32s'

it('arshift: arithmetic right shift (JavaScript >> operator)', function()
  assert.equal(-1, bit32s.arshift(0xffffffff, 0))
  assert.equal(2, bit32s.arshift(5, 1))
end)

it('bor: bitwise or (JavaScript | operator)', function()
  assert.equal(-1, bit32s.bor(0xffffffff, 0))
  assert.equal(5, bit32s.bor(5, 1))
  assert.equal(-1, bit32s.bor(-1, 0))
end)
