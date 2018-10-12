local bit32 = require 'bit32'
local bit32s = require 'long.bit32s'
local class = require 'middleclass'

local IS_LUA_53 = string.match(_VERSION, 'Lua 5.3')

local function eval(expr)
  if IS_LUA_53 then
    return load(expr)()
  else
    return loadstring(expr)()
  end
end

local Long = class('Long')

--[[
 * Constructs a 64 bit two's-complement integer, given its low and high 32 bit values as *signed* integers.
 *  See the from* functions below for more convenient ways of constructing Longs.
 * @exports Long
 * @class A Long class for representing a 64 bit two's-complement integer value.
 * @param {number} low The low (signed) 32 bits of the long
 * @param {number} high The high (signed) 32 bits of the long
 * @param {boolean=} unsigned Whether unsigned or not, defaults to `false` for signed
 * @constructor
--]]
function Long:initialize(low, high, unsigned)

  --[[
   * The low 32 bits as a signed value.
   * @type {number}
  --]]
  self.low = bit32s.bor(low, 0)

  --[[
   * The high 32 bits as a signed value.
   * @type {number}
  --]]
  self.high = bit32s.bor(high, 0)

  --[[
   * Whether unsigned or not.
   * @type {boolean}
  --]]
  self.unsigned = not not unsigned
end

--[[
 * Returns a Long representing the 64 bit integer that comes by concatenating the given low and high bits. Each is
 *  assumed to use 32 bits.
 * @function
 * @param {number} lowBits The low 32 bits
 * @param {number} highBits The high 32 bits
 * @param {boolean=} unsigned Whether unsigned or not, defaults to `false` for signed
 * @returns {!Long} The corresponding Long value
--]]
function Long.fromBits(lowBits, highBits, unsigned)
  return Long:new(lowBits, highBits, unsigned)
end

--[[
 * Returns a Long representing the given 32 bit integer value.
 * @function
 * @param {number} value The 32 bit integer in question
 * @param {boolean=} unsigned Whether unsigned or not, defaults to `false` for signed
 * @returns {!Long} The corresponding Long value
--]]
function Long.fromInt(value, unsigned)
  local obj --, cachedObj, cache
  if unsigned then
    value = bit32s.rshift(value, 0)
--      if (cache = (0 <= value && value < 256)) {
--          cachedObj = UINT_CACHE[value]
--          if (cachedObj)
--              return cachedObj
--      }
    if bit32s.bor(value, 0) < 0 then
      obj = Long.fromBits(value, -1, true)
    else
      obj = Long.fromBits(value, 0, true)
    end
--      if (cache)
--          UINT_CACHE[value] = obj
    return obj
  else
    value = bit32s.bor(value, 0)
--    if (cache = (-128 <= value && value < 128)) {
--        cachedObj = INT_CACHE[value]
--        if (cachedObj)
--            return cachedObj
--    }
    if value < 0 then
      obj = Long.fromBits(value, -1, false)
    else
      obj = Long.fromBits(value, 0, false)
    end
--    if (cache)
--        INT_CACHE[value] = obj
    return obj
  end
end

--[[
 * @function
 * @param {!Long|number|string|!{low: number, high: number, unsigned: boolean}} val
 * @returns {!Long}
 * @inner
--]]
function Long.fromValue(val)
  if type(val) == 'table' then
    if val.isInstanceOf and val:isInstanceOf(Long) then return val end
    return Long.fromBits(val.low, val.high, val.unsigned)
  elseif type(val) == 'number' then
    return Long.fromNumber(val)
  elseif type(val) == 'string' then
    return Long.fromString(val)
  end
  error('unsupported type')
end

--[[
 * @type {number}
 * @const
 * @inner
--]]
local TWO_PWR_16_DBL
if IS_LUA_53 then
  TWO_PWR_16_DBL = eval('return 1 << 16')
else
  TWO_PWR_16_DBL = bit32s.lshift(1, 16)
end

--[[
 * @type {number}
 * @const
 * @inner
--]]
local TWO_PWR_24_DBL
if IS_LUA_53 then
  TWO_PWR_24_DBL = eval('return 1 << 24')
else
 TWO_PWR_24_DBL = bit32s.lshift(1, 24)
end

--[[
 * @type {number}
 * @const
 * @inner
--]]
local TWO_PWR_32_DBL
if IS_LUA_53 then
  TWO_PWR_32_DBL = eval('return 1 << 32')
else
  TWO_PWR_32_DBL = TWO_PWR_16_DBL * TWO_PWR_16_DBL
end

--[[
 * @type {number}
 * @const
 * @inner
--]]
local TWO_PWR_64_DBL
if IS_LUA_53 then
  TWO_PWR_64_DBL = 1.0 * TWO_PWR_32_DBL * TWO_PWR_32_DBL
else
  TWO_PWR_64_DBL = TWO_PWR_32_DBL * TWO_PWR_32_DBL
end

--[[
 * @type {number}
 * @const
 * @inner
--]]
local TWO_PWR_63_DBL = TWO_PWR_64_DBL / 2

--[[
 * @type {!Long}
 * @const
 * @inner
--]]
local TWO_PWR_24 = Long.fromInt(TWO_PWR_24_DBL)

--[[
 * @function
 * @param {number} base
 * @param {number} exponent
 * @returns {number}
 * @inner
--]]
local pow_dbl = math.pow -- Used 4 times (4*8 to 15+4)

--[[
 * Signed zero.
 * @type {!Long}
--]]
Long.ZERO = Long.fromInt(0)

--[[
 * Unsigned zero.
 * @type {!Long}
--]]
Long.UZERO = Long.fromInt(0, true)

--[[
 * Signed one.
 * @type {!Long}
--]]
Long.ONE = Long.fromInt(1)

--[[
 * Unsigned one.
 * @type {!Long}
--]]
Long.UONE = Long.fromInt(1, true)

--[[
 * Signed negative one.
 * @type {!Long}
--]]
Long.NEG_ONE = Long.fromInt(-1)

--[[
 * Maximum signed value.
 * @type {!Long}
--]]
Long.MAX_VALUE = Long.fromBits(bit32s.bor(0xFFFFFFFF, 0), bit32s.bor(0x7FFFFFFF, 0), false)

--[[
 * Maximum unsigned value.
 * @type {!Long}
--]]
Long.MAX_UNSIGNED_VALUE = Long.fromBits(bit32s.bor(0xFFFFFFFF, 0), bit32s.bor(0xFFFFFFFF, 0), true)

--[[
 * Minimum signed value.
 * @type {!Long}
--]]
Long.MIN_VALUE = Long.fromBits(0, bit32s.bor(0x80000000, 0), false)

-- The internal representation of a long is the two given signed, 32-bit values.
-- We use 32-bit pieces because these are the size of integers on which
-- Javascript performs bit-operations.  For operations like addition and
-- multiplication, we split each number into 16 bit pieces, which can easily be
-- multiplied within Javascript's floating-point representation without overflow
-- or change in sign.
--
-- In the algorithms below, we frequently reduce the negative case to the
-- positive case by negating the input(s) and then post-processing the result.
-- Note that we must ALWAYS check specially whether those values are MIN_VALUE
-- (-2^63) because -MIN_VALUE == MIN_VALUE (since 2^63 cannot be represented as
-- a positive number, it overflows back into a negative).  Not handling this
-- case would often result in infinite recursion.
--
-- Common constant values ZERO, ONE, NEG_ONE, etc. are defined below the from*
-- methods on which they depend.

--[[
 * Returns a Long representing the given value, provided that it is a finite number. Otherwise, zero is returned.
 * @function
 * @param {number} value The number in question
 * @param {boolean=} unsigned Whether unsigned or not, defaults to `false` for signed
 * @returns {!Long} The corresponding Long value
--]]
function Long.fromNumber(value, unsigned)
  if type(value) ~= 'number' or value == math.huge then
    if unsigned then return Long.UZERO else return Long.ZERO end
  end
  if unsigned then
    if value < 0 then return Long.UZERO end
    if value >= TWO_PWR_64_DBL then return Long.MAX_UNSIGNED_VALUE end
  else
    if value <= -TWO_PWR_63_DBL then return Long.MIN_VALUE end
    if value + 1 >= TWO_PWR_63_DBL then return Long.MAX_VALUE end
  end
  if value < 0 then return Long.fromNumber(-value, unsigned):neg() end
  return Long.fromBits((value % TWO_PWR_32_DBL) or 0, (value / TWO_PWR_32_DBL) or 0, unsigned)
end

function Long:__tostring()
  return 'Long {low=' .. self.low .. ', high=' .. self.high .. ', unsigned=' .. tostring(self.unsigned) .. '}'
end

--[[
 * Returns the sum of this and the specified Long.
 * @param {!Long|number|string} addend Addend
 * @returns {!Long} Sum
--]]
function Long:add(addend)
  if not Long.isLong(addend) then
    addend = Long.fromValue(addend)
  end

  -- Divide each number into 4 chunks of 16 bits, and then sum the chunks.

  local a48 = bit32.rshift(self.high, 16)
  local a32 = bit32.band(self.high, 0xFFFF)
  local a16 = bit32.rshift(self.low, 16)
  local a00 = bit32.band(self.low, 0xFFFF)

  local b48 = bit32.rshift(addend.high, 16)
  local b32 = bit32.band(addend.high, 0xFFFF)
  local b16 = bit32.rshift(addend.low, 16)
  local b00 = bit32.band(addend.low, 0xFFFF)

  local c48, c32, c16, c00 = 0, 0, 0, 0
  c00 = c00 + a00 + b00
  c16 = c16 + bit32.rshift(c00, 16)
  c00 = bit32.band(c00, 0xFFFF)
  c16 = c16 + a16 + b16
  c32 = c32 + bit32.rshift(c16, 16)
  c16 = bit32.band(c16, 0xFFFF)
  c32 = c32 + a32 + b32
  c48 = c48 + bit32.rshift(c32, 16)
  c32 = bit32.band(c32, 0xFFFF)
  c48 = c48 + a48 + b48
  c48 = bit32.band(c48, 0xFFFF)
  return Long.fromBits(bit32.bor(bit32.lshift(c16,16), c00), bit32.bor(bit32.lshift(c48, 16), c32), self.unsigned)
end
Long.__add = Long.add

--[[
 * Returns the bitwise AND of this Long and the specified.
 * @param {!Long|number|string} other Other Long
 * @returns {!Long}
--]]
function Long:band(other)
  if not Long.isLong(other) then other = Long.fromValue(other) end
  return Long.fromBits(bit32.band(self.low, other.low), bit32.band(self.high, other.high), self.unsigned)
end

--[[
 * Returns the bitwise NOT of this Long.
 * @returns {!Long}
--]]
function Long:bnot()
  return Long.fromBits(bit32.bnot(self.low), bit32.bnot(self.high), self.unsigned)
end

--[[
 * Returns the bitwise OR of this Long and the specified.
 * @param {!Long|number|string} other Other Long
 * @returns {!Long}
--]]
function Long:bor(other)
  if not Long.isLong(other) then other = Long.fromValue(other) end
  return Long.fromBits(bit32.bor(self.low, other.low), bit32.bor(self.high, other.high), self.unsigned)
end

--[[
 * Returns the bitwise XOR of this Long and the given one.
 * @param {!Long|number|string} other Other Long
 * @returns {!Long}
--]]
function Long:bxor(other)
  if not Long.isLong(other) then other = Long.fromValue(other) end
  return Long.fromBits(bit32.bxor(self.low, other.low), bit32.bxor(self.high, other.high), self.unsigned)
end
Long.xor = Long.bxor

--[[
 * Compares this Long's value with the specified's.
 * @param {!Long|number|string} other Other value
 * @returns {number} 0 if they are the same, 1 if the this is greater and -1
 *  if the given one is greater
--]]
function Long:compare(other)
  if not Long.isLong(other) then other = Long.fromValue(other) end
  if self:eq(other) then return 0 end
  local selfNeg, otherNeg = self:isNegative(), other:isNegative()
  if selfNeg and not otherNeg then return -1 end
  if not selfNeg and otherNeg then return 1 end
  -- At this point the sign bits are the same
  if not self.unsigned then
    if self:sub(other):isNegative() then return -1 else return 1 end
  end
  -- Both are positive if at least one is unsigned
  if bit32.rshift(other.high, 0) > bit32.rshift(self.high, 0) or (other.high == self.high and bit32.rshift(other.low, 0) > bit32.rshift(self.low, 0)) then
    return -1
  else
    return 1
  end
end

--[[
 * Compares this Long's value with the specified's. This is an alias of {@link Long#compare}.
 * @function
 * @param {!Long|number|string} other Other value
 * @returns {number} 0 if they are the same, 1 if the this is greater and -1
 *  if the given one is greater
--]]
Long.comp = Long.compare

--[[
 * Returns this Long divided by the specified. The result is signed if this Long is signed or
 *  unsigned if this Long is unsigned.
 * @param {!Long|number|string} divisor Divisor
 * @returns {!Long} Quotient
--]]
function Long:divide(divisor)
  if not Long.isLong(divisor) then
    divisor = Long.fromValue(divisor)
  end
  assert(not divisor:isZero(), 'division by zero')
  if self:isZero() then
    if self.unsigned then return Long.UZERO else return Long.ZERO end
  end
  local approx, rem, res
  if not self.unsigned then
    -- This section is only relevant for signed longs and is derived from the
    -- closure library as a whole.
    if self:eq(Long.MIN_VALUE) then
      if divisor:eq(Long.ONE) or divisor:eq(Long.NEG_ONE) then
        return Long.MIN_VALUE  -- recall that -MIN_VALUE == MIN_VALUE
      elseif divisor:eq(Long.MIN_VALUE) then
        return Long.ONE
      else
        -- At this point, we have |other| >= 2, so |this/other| < |MIN_VALUE|.
        local halfSelf = self:shr(1)
        approx = halfSelf:div(divisor):shl(1)
        if approx:eq(Long.ZERO) then
          if divisor:isNegative() then return Long.ONE else return Long.NEG_ONE end
        else
          rem = self:sub(divisor:mul(approx))
          res = approx:add(rem:div(divisor))
          return res
        end
      end
    elseif divisor:eq(Long.MIN_VALUE) then
      if self.unsigned then return Long.UZERO else return Long.ZERO end
    end
    if self:isNegative() then
      if divisor:isNegative() then
        return self:neg():div(divisor:neg())
      end
      return self:neg():div(divisor):neg()
    elseif divisor:isNegative() then
      return self:div(divisor:neg()):neg()
    end
    res = Long.ZERO
  else
    -- The algorithm below has not been made for unsigned longs. It's therefore
    -- required to take special care of the MSB prior to running it.
    if not divisor.unsigned then
      divisor = divisor:toUnsigned()
    end
    if divisor:gt(self) then
      return Long.UZERO
    end
    if divisor:gt(self:shru(1)) then -- 15 >>> 1 = 7  with divisor = 8  true
      return Long.UONE
    end
    res = Long.UZERO
  end

  -- Repeat the following until the remainder is less than other:  find a
  -- floating-point that approximates remainder / other *from below*, add this
  -- into the result, and subtract it from the remainder.  It is critical that
  -- the approximate value is less than or equal to the real value so that the
  -- remainder never becomes negative.
  rem = self
  while rem:gte(divisor) do
    -- Approximate the result of division. This may be a little greater or
    -- smaller than the actual value.
    approx = math.max(1, math.floor(rem:toNumber() / divisor:toNumber()))

    -- We will tweak the approximate result by changing it in the 48-th digit or
    -- the smallest non-fractional digit, whichever is larger.
    local log2 = math.ceil(math.log(approx) / math.log(2))
    local delta
    if log2 <= 48 then
      delta = 1
    else
      delta = pow_dbl(2, log2 - 48)
    end

    -- Decrease the approximation until it is smaller than the remainder.  Note
    -- that if it is too large, the product overflows and is negative.
    local approxRes = Long.fromNumber(approx)
    local approxRem = approxRes:mul(divisor)
    while approxRem:isNegative() or approxRem:gt(rem) do
      approx = approx - delta
      approxRes = Long.fromNumber(approx, self.unsigned)
      approxRem = approxRes:mul(divisor)
    end

    -- We know the answer can't be zero... and actually, zero would cause
    -- infinite recursion since we would make no progress.
    if approxRes:isZero() then
      approxRes = Long.ONE
    end

    res = res:add(approxRes)
    rem = rem:sub(approxRem)
  end
  return res
end

--[[
 * Returns this Long divided by the specified. This is an alias of {@link Long#divide}.
 * @function
 * @param {!Long|number|string} divisor Divisor
 * @returns {!Long} Quotient
--]]
Long.div = Long.divide
Long.__div = Long.divide

--[[
 * Tests if this Long's value equals the specified's.
 * @param {!Long|number|string} other Other value
 * @returns {boolean}
--]]
function Long:equals(other)
  if not Long.isLong(other) then
    other = Long.fromValue(other)
  end
  if self.unsigned ~= other.unsigned and bit32.rshift(self.high, 31) == 1 and bit32.rshift(other.high, 31) == 1 then
    return false
  end
  return self.high == other.high and self.low == other.low
end

--[[
 * Tests if this Long's value equals the specified's. This is an alias of {@link Long#equals}.
 * @function
 * @param {!Long|number|string} other Other value
 * @returns {boolean}
--]]
Long.eq = Long.equals
Long.__eq = Long.equals

--[[
 * Tests if this Long's value is greater than the specified's.
 * @param {!Long|number|string} other Other value
 * @returns {boolean}
--]]
function Long:greaterThan(other)
  return self:comp(other) > 0
end

--[[
 * Tests if this Long's value is greater than the specified's. This is an alias of {@link Long#greaterThan}.
 * @function
 * @param {!Long|number|string} other Other value
 * @returns {boolean}
--]]
Long.gt = Long.greaterThan

--[[
 * Tests if this Long's value is greater than or equal the specified's.
 * @param {!Long|number|string} other Other value
 * @returns {boolean}
--]]
function Long:greaterThanOrEqual(other)
  return self:comp(other) >= 0
end

--[[
 * Tests if this Long's value is greater than or equal the specified's. This is an alias of {@link Long#greaterThanOrEqual}.
 * @function
 * @param {!Long|number|string} other Other value
 * @returns {boolean}
--]]
Long.gte = Long.greaterThanOrEqual

--[[
 * Tests if this Long's value is even.
 * @returns {boolean}
--]]
function Long:isEven()
  return bit32.band(self.low, 1) == 0
end

--[[
 * Tests if the specified object is a Long.
 * @function
 * @param {*} obj Object
 * @returns {boolean}
--]]
function Long:isLong()
  return type(self) == 'table' and self.isInstanceOf and self:isInstanceOf(Long)
end

--[[
 * Tests if this Long's value is negative.
 * @returns {boolean}
--]]
function Long:isNegative()
  return not self.unsigned and self.high < 0
end

--[[
 * Tests if this Long's value is odd.
 * @returns {boolean}
--]]
function Long:isOdd()
  return bit32.band(self.low, 1) == 1
end

--[[
 * Tests if this Long's value equals zero.
 * @returns {boolean}
--]]
function Long:isZero()
  return self.high == 0 and self.low == 0
end

--[[
 * Tests if this Long's value is less than the specified's.
 * @param {!Long|number|string} other Other value
 * @returns {boolean}
--]]
function Long:lessThan(other)
  return self:comp(other) < 0
end

--[[
 * Tests if this Long's value is less than the specified's. This is an alias of {@link Long#lessThan}.
 * @function
 * @param {!Long|number|string} other Other value
 * @returns {boolean}
--]]
Long.lt = Long.lessThan
Long.__lt = Long.lessThan

--[[
 * Tests if this Long's value is less than or equal the specified's.
 * @param {!Long|number|string} other Other value
 * @returns {boolean}
--]]
function Long:lessThanOrEqual(other)
  return self:comp(other) <= 0
end

--[[
 * Tests if this Long's value is less than or equal the specified's. This is an alias of {@link Long#lessThanOrEqual}.
 * @function
 * @param {!Long|number|string} other Other value
 * @returns {boolean}
--]]
Long.lte = Long.lessThanOrEqual
Long.__le = Long.lessThanOrEqual

--[[
 * Returns this Long modulo the specified.
 * @param {!Long|number|string} divisor Divisor
 * @returns {!Long} Remainder
--]]
function Long:modulo(divisor)
  if not Long.isLong(divisor) then divisor = Long.fromValue(divisor) end
  return self:sub(self:div(divisor):mul(divisor))
end

--[[
 * Returns this Long modulo the specified. This is an alias of {@link Long#modulo}.
 * @function
 * @param {!Long|number|string} divisor Divisor
 * @returns {!Long} Remainder
--]]
Long.mod = Long.modulo
Long.__mod = Long.modulo

--[[
 * Returns the product of this and the specified Long.
 * @param {!Long|number|string} multiplier Multiplier
 * @returns {!Long} Product
--]]
function Long:multiply(multiplier)
  if self:isZero() then return Long.ZERO end
  if not Long.isLong(multiplier) then
    multiplier = Long.fromValue(multiplier)
  end
  if multiplier:isZero() then return Long.ZERO end
  if self:eq(Long.MIN_VALUE) then
    if multiplier:isOdd() then return Long.MIN_VALUE else return Long.ZERO end
  end
  if multiplier:eq(Long.MIN_VALUE) then
    if self:isOdd() then return Long.MIN_VALUE else return Long.ZERO end
  end

  if self:isNegative() then
    if multiplier:isNegative() then
      return self:neg():mul(multiplier:neg())
    else
      return self:neg():mul(multiplier):neg()
    end
  elseif multiplier:isNegative() then
    return self:mul(multiplier:neg()):neg()
  end

  -- If both longs are small, use float multiplication
  if self:lt(TWO_PWR_24) and multiplier:lt(TWO_PWR_24) then
    return Long.fromNumber(self:toNumber() * multiplier:toNumber(), self.unsigned)
  end

  -- Divide each long into 4 chunks of 16 bits, and then add up 4x4 products.
  -- We can skip products that would overflow.

  local a48 = bit32.rshift(self.high, 16)
  local a32 = bit32.band(self.high, 0xFFFF)
  local a16 = bit32.rshift(self.low, 16)
  local a00 = bit32.band(self.low, 0xFFFF)

  local b48 = bit32.rshift(multiplier.high, 16)
  local b32 = bit32.band(multiplier.high, 0xFFFF)
  local b16 = bit32.rshift(multiplier.low, 16)
  local b00 = bit32.band(multiplier.low, 0xFFFF)

  local c48, c32, c16, c00 = 0, 0, 0, 0
  c00 = c00 + a00 * b00
  c16 = c16 + bit32.rshift(c00, 16)
  c00 = bit32.band(c00, 0xFFFF)
  c16 = c16 + a16 * b00
  c32 = c32 + bit32.rshift(c16, 16)
  c16 = bit32.band(c16, 0xFFFF)
  c16 = c16 + a00 * b16
  c32 = c32 + bit32.rshift(c16, 16)
  c16 = bit32.band(c16, 0xFFFF)
  c32 = c32 + a32 * b00
  c48 = c48 + bit32.rshift(c32, 16)
  c32 = bit32.band(c32, 0xFFFF)
  c32 = c32 + a16 * b16
  c48 = c48 + bit32.rshift(c32, 16)
  c32 = bit32.band(c32, 0xFFFF)
  c32 = c32 + a00 * b32
  c48 = c48 + bit32.rshift(c32, 16)
  c32 = bit32.band(c32, 0xFFFF)
  c48 = c48 + a48 * b00 + a32 * b16 + a16 * b32 + a00 * b48
  c48 = bit32.band(c48, 0xFFFF)
  local lowBits = bit32.bor(bit32.lshift(c16, 16), c00)
  local highBits = bit32.bor(bit32.lshift(c48, 16), c32)
  return Long.fromBits(lowBits, highBits, self.unsigned)
end

--[[
 * Returns the product of this and the specified Long. This is an alias of {@link Long#multiply}.
 * @function
 * @param {!Long|number|string} multiplier Multiplier
 * @returns {!Long} Product
--]]
Long.mul = Long.multiply
Long.__mul = Long.multiply

--[[
 * Negates this Long's value.
 * @function
 * @returns {!Long} Negated Long
--]]
function Long:negate()
  if not self.unsigned and self:eq(Long.MIN_VALUE) then
    return Long.MIN_VALUE
  end
  return self:bnot():add(Long.ONE)
end

--[[
 * Negates this Long's value. This is an alias of {@link Long#negate}.
 * @function
 * @returns {!Long} Negated Long
--]]
Long.neg = Long.negate
Long.__unm = Long.negate

--[[
 * Returns this Long with bits shifted to the left by the given amount.
 * @param {number|!Long} numBits Number of bits
 * @returns {!Long} Shifted Long
--]]
function Long:shiftLeft(numBits)
  if Long.isLong(numBits) then
    numBits = numBits:toInt()
  end
  if bit32.band(numBits, 63) == 0 then
    return self
  elseif numBits < 32 then
    local lowBits = bit32.lshift(self.low, numBits)
    local highBits = bit32.bor(bit32.lshift(self.high, numBits), bit32.rshift(self.low, 32 - numBits))
    return Long.fromBits(lowBits, highBits, self.unsigned)
  else
    return Long.fromBits(0, bit32.lshift(self.low, numBits - 32), self.unsigned)
  end
end

--[[
 * Returns this Long with bits shifted to the left by the given amount. This is an alias of {@link Long#shiftLeft}.
 * @function
 * @param {number|!Long} numBits Number of bits
 * @returns {!Long} Shifted Long
--]]
Long.shl = Long.shiftLeft

--[[
 * Returns this Long with bits arithmetically shifted to the right by the given amount.
 * @param {number|!Long} numBits Number of bits
 * @returns {!Long} Shifted Long
--]]
function Long:shiftRight(numBits)
  if Long.isLong(numBits) then
    numBits = numBits:toInt()
  end
  if bit32.band(numBits, 63) == 0 then
      return self
  elseif numBits < 32 then
    local lowBits = bit32.bor(bit32.rshift(self.low, numBits), bit32.lshift(self.high, 32 - numBits))
    local highBits = bit32s.arshift(self.high, numBits)
    return Long.fromBits(lowBits, highBits, self.unsigned)
  else
    local lowBits = bit32s.arshift(self.high, numBits - 32)
    local highBits
    if self.high >= 0 then highBits = 0 else highBits = -1 end
    return Long.fromBits(lowBits, highBits, self.unsigned)
  end
end

--[[
 * Returns this Long with bits arithmetically shifted to the right by the given amount. This is an alias of {@link Long#shiftRight}.
 * @function
 * @param {number|!Long} numBits Number of bits
 * @returns {!Long} Shifted Long
--]]
Long.shr = Long.shiftRight

--[[
 * Returns this Long with bits logically shifted to the right by the given amount.
 * @param {number|!Long} numBits Number of bits
 * @returns {!Long} Shifted Long
--]]
function Long:shiftRightUnsigned(numBits)
  if Long.isLong(numBits) then
    numBits = numBits:toInt()
  end
  numBits = bit32.band(numBits, 63)
  if numBits == 0 then
    return self
  else
    local high = self.high
    if numBits < 32 then
      local low = self.low
      --return Long.fromBits((low >>> numBits) | (high << (32 - numBits)), high >>> numBits, self.unsigned)
      local lowBits = bit32.bor(bit32.rshift(low, numBits), bit32.lshift(high, 32 - numBits))
      local highBits = bit32.rshift(high, numBits)
      return Long.fromBits(lowBits, highBits, self.unsigned)
    elseif numBits == 32 then
      return Long.fromBits(high, 0, self.unsigned)
    else
      return Long.fromBits(bit32.rshift(high, numBits - 32), 0, self.unsigned)
    end
  end
end

--[[
 * Returns this Long with bits logically shifted to the right by the given amount. This is an alias of {@link Long#shiftRightUnsigned}.
 * @function
 * @param {number|!Long} numBits Number of bits
 * @returns {!Long} Shifted Long
--]]
Long.shru = Long.shiftRightUnsigned

--[[
 * Returns the difference of this and the specified Long.
 * @param {!Long|number|string} subtrahend Subtrahend
 * @returns {!Long} Difference
--]]
function Long:subtract(subtrahend)
  if not Long.isLong(subtrahend) then
    subtrahend = Long.fromValue(subtrahend)
  end
  return self:add(subtrahend:neg())
end

--[[
 * Returns the difference of this and the specified Long. This is an alias of {@link Long#subtract}.
 * @function
 * @param {!Long|number|string} subtrahend Subtrahend
 * @returns {!Long} Difference
--]]
Long.sub = Long.subtract
Long.__sub = Long.subtract

--[[
 * Converts this Long to its byte representation.
 * @param {boolean=} le Whether little or big endian, defaults to big endian
 * @returns {!Array.<number>} Byte representation
--]]
function Long:toBytes(le)
  if le then return self:toBytesLE() else return self:toBytesBE() end
end

--[[
 * Converts this Long to its little endian byte representation.
 * @returns {!Array.<number>} Little endian byte representation
--]]
function Long:toBytesLE()
  local hi, lo = self.high, self.low
  return {
    bit32s.band(lo                   , 0xff),
    bit32s.band(bit32s.rshift(lo,  8), 0xff),
    bit32s.band(bit32s.rshift(lo, 16), 0xff),
    bit32s.band(bit32s.rshift(lo, 24), 0xff),
    bit32s.band(hi                   , 0xff),
    bit32s.band(bit32s.rshift(hi, 8) , 0xff),
    bit32s.band(bit32s.rshift(hi, 16), 0xff),
    bit32s.band(bit32s.rshift(hi, 24), 0xff)
  }
end

--[[
 * Converts this Long to its big endian byte representation.
 * @returns {!Array.<number>} Big endian byte representation
--]]
function Long:toBytesBE()
  local hi, lo = self.high, self.low
  return {
    bit32s.band(bit32s.rshift(hi, 24), 0xff),
    bit32s.band(bit32s.rshift(hi, 16), 0xff),
    bit32s.band(bit32s.rshift(hi,  8), 0xff),
    bit32s.band(hi                   , 0xff),
    bit32s.band(bit32s.rshift(lo, 24), 0xff),
    bit32s.band(bit32s.rshift(lo, 16), 0xff),
    bit32s.band(bit32s.rshift(lo,  8), 0xff),
    bit32s.band(lo                   , 0xff)
  }
end

--[[
 * Converts the Long to a 32 bit integer, assuming it is a 32 bit integer.
 * @returns {number}
--]]
function Long:toInt()
  if self.unsigned then return bit32.rshift(self.low, 0) else return self.low end
end

--[[
 * Converts the Long to a the nearest floating-point representation of this value (double, 53 bit mantissa).
 * @returns {number}
--]]
function Long:toNumber()
  if self.unsigned then
    return (bit32.rshift(self.high, 0) * TWO_PWR_32_DBL) + bit32.rshift(self.low, 0)
  end
  return self.high * TWO_PWR_32_DBL + bit32.rshift(self.low, 0)
end

--[[
 * Converts this Long to signed.
 * @returns {!Long} Signed long
--]]
function Long:toSigned()
  if not self.unsigned then return self end
  return Long.fromBits(self.low, self.high, false)
end

--[[
 * Converts the Long to a string written in the specified radix.
 * @param {number=} radix Radix (2-36), defaults to 10
 * @returns {string}
 * @override
 * @throws {RangeError} If `radix` is out of range
--]]
function Long:toString(radix)
  radix = radix or 10
  if radix < 2 or 36 < radix then
    error('radix')
  end

  if self:isZero() then return '0' end
  if self:isNegative() then -- Unsigned Longs are never negative
    if self:eq(Long.MIN_VALUE) then
      if radix == 10 then
        return '-9223372036854775808'
      elseif radix == 16 then
        return 'ffffffffffffffff'
      else
        error('unsupported radix: ' .. tostring(radix))
      end
    else
      return '-' .. self:neg():toString(radix)
    end
  end

  if self:eq(Long.MAX_UNSIGNED_VALUE) then
    if radix == 10 then
      return '18446744073709551615'
    elseif radix == 16 then
      return 'ffffffffffffffff'
    else
      error('unsupported radix: ' .. tostring(radix))
    end
  end

  -- Do several (6) digits each time through the loop, so as to
  -- minimize the calls to the very expensive emulated div.
  local radixToPower = Long.fromNumber(pow_dbl(radix, 6), self.unsigned)
  local rem = self
  local result = ''
  while true do
    local remDiv = rem:div(radixToPower)
    local intval = bit32.rshift(rem:sub(remDiv:mul(radixToPower)):toInt(), 0)
    local digits
    if radix == 10 then
      digits = tostring(intval)
    elseif radix == 16 then
      assert(not self.unsigned, 'toString(radix=16) for unsigned number not supported yet')
      digits = string.format('%x', intval)
    else
      error('unsupported radix: ' .. tostring(radix))
    end
    rem = remDiv
    if rem:isZero() then
      return digits .. result
    else
      while #digits < 6 do
        digits = '0' .. digits
      end
      result = digits .. result
    end
  end
end

--[[
 * Converts this Long to unsigned.
 * @returns {!Long} Unsigned long
--]]
function Long:toUnsigned()
  if self.unsigned then return self end
  return Long.fromBits(self.low, self.high, true)
end

return Long
