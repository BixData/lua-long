local Long = require 'long'

it('consts', function()
  assert.equal(false, Long.ZERO.unsigned)
  assert.equal(0, Long.ZERO.low)
  assert.equal(0, Long.ZERO.high)
  
  assert.equal(true, Long.UZERO.unsigned)
  assert.equal(0, Long.UZERO.low)
  assert.equal(0, Long.UZERO.high)
  
  assert.equal(false, Long.ONE.unsigned)
  assert.equal(1, Long.ONE.low)
  assert.equal(0, Long.ONE.high)
  
  assert.equal(true, Long.UONE.unsigned)
  assert.equal(1, Long.UONE.low)
  assert.equal(0, Long.UONE.high)
  
  assert.equal(false, Long.NEG_ONE.unsigned)
  assert.equal(-1, Long.NEG_ONE.low)
  assert.equal(-1, Long.NEG_ONE.high)
  
  assert.equal(false, Long.MAX_VALUE.unsigned)
  assert.equal(-1, Long.MAX_VALUE.low)
  assert.equal(2147483647, Long.MAX_VALUE.high)
  
  assert.equal(true, Long.MAX_UNSIGNED_VALUE.unsigned)
  assert.equal(-1, Long.MAX_UNSIGNED_VALUE.low)
  assert.equal(-1, Long.MAX_UNSIGNED_VALUE.high)
  
  assert.equal(false, Long.MIN_VALUE.unsigned)
  assert.equal(0, Long.MIN_VALUE.low)
  assert.equal(-2147483648, Long.MIN_VALUE.high)
end)

it('greaterThan', function()
  assert.is_true(Long.ONE:gt(Long.ZERO))
  assert.is_true(Long.MAX_VALUE:gt(Long.ZERO))
  assert.is_true(Long.MAX_VALUE:gt(Long.ONE))
  
  assert.is_false(Long.ZERO:gt(Long.ONE))
  assert.is_false(Long.ZERO:gt(Long.MAX_VALUE))
  assert.is_false(Long.NEG_ONE:gt(Long.ZERO))
  assert.is_false(Long.NEG_ONE:gt(Long.ONE))
  assert.is_false(Long.MIN_VALUE:gt(Long.ZERO))
  
  assert.is_false(Long.ZERO:gt(Long.ZERO))
  assert.is_false(Long.ONE:gt(Long.ONE))
  assert.is_false(Long.NEG_ONE:gt(Long.NEG_ONE))
end)

it('lessThan', function()
  assert.is_true(Long.ZERO:lt(Long.ONE))
  assert.is_true(Long.ZERO:lt(Long.MAX_VALUE))
  assert.is_true(Long.NEG_ONE:lt(Long.ZERO))
  assert.is_true(Long.NEG_ONE:lt(Long.ONE))
  assert.is_true(Long.MIN_VALUE:lt(Long.ZERO))
  
  assert.is_false(Long.ONE:lt(Long.ZERO))
  
  assert.is_false(Long.ZERO:lt(Long.ZERO))
  assert.is_false(Long.ONE:lt(Long.ONE))
  assert.is_false(Long.NEG_ONE:lt(Long.NEG_ONE))
end)

it('equal', function()
  assert.is_true(Long.ZERO:eq(Long.ZERO))
  assert.is_true(Long.NEG_ONE:eq(Long.NEG_ONE))
  assert.is_true(Long.ONE:eq(Long.ONE))
  assert.is_true(Long.MIN_VALUE:eq(Long.MIN_VALUE))
  
  assert.is_false(Long.ONE:eq(Long.ZERO))
  assert.is_false(Long.ONE:eq(Long.NEG_ONE))
end)

it('isNegative', function()
  assert.is_true(Long.NEG_ONE:isNegative())
  assert.is_true(Long.MIN_VALUE:isNegative())

  assert.is_false(Long.ZERO:isNegative())
  assert.is_false(Long.UZERO:isNegative())
  assert.is_false(Long.ONE:isNegative())
  assert.is_false(Long.MAX_VALUE:isNegative())
  assert.is_false(Long.MAX_UNSIGNED_VALUE:isNegative())
end)

it('isZero', function()
  assert.is_true(Long.ZERO:isZero())
  assert.is_true(Long.UZERO:isZero())
  
  assert.is_false(Long.ONE:isZero())
  assert.is_false(Long.NEG_ONE:isZero())
  assert.is_false(Long.MIN_VALUE:isZero())
  assert.is_false(Long.MAX_VALUE:isZero())
  assert.is_false(Long.MAX_UNSIGNED_VALUE:isZero())
end)
