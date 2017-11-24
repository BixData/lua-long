local bit32 = require 'bit32'
local bit32s = require 'bit32s'
local class = require 'middleclass'

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
--      value >>>= 0
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
local TWO_PWR_16_DBL = bit32s.lshift(1, 16)

--[[
 * @type {number}
 * @const
 * @inner
--]]
--local TWO_PWR_24_DBL = bit32s.lshift(1, 24)

--[[
 * @type {number}
 * @const
 * @inner
--]]
local TWO_PWR_32_DBL = TWO_PWR_16_DBL * TWO_PWR_16_DBL

--[[
 * @type {number}
 * @const
 * @inner
--]]
local TWO_PWR_64_DBL = TWO_PWR_32_DBL * TWO_PWR_32_DBL

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
--local TWO_PWR_24 = Long.fromInt(TWO_PWR_24_DBL)

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

--[[
 * Returns the bitwise NOT of this Long.
 * @returns {!Long}
--]]
function Long:bnot()
  return Long.fromBits(bit32.bnot(self.low), bit32.bnot(self.high), self.unsigned)
end

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
  --return (other.high >>> 0) > (self.high >>> 0) || (other.high === self.high && (other.low >>> 0) > (self.low >>> 0)) ? -1 : 1
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
    bit32s.band(lo                  , 0xff),
    bit32s.band(bit32s.rshift(lo,  8), 0xff),
    bit32s.band(bit32s.rshift(lo, 16), 0xff),
    bit32s.band(bit32s.rshift(lo, 24), 0xff),
    bit32s.band(hi                  , 0xff),
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
    bit32s.band(hi                  , 0xff),
    bit32s.band(bit32s.rshift(lo, 24), 0xff),
    bit32s.band(bit32s.rshift(lo, 16), 0xff),
    bit32s.band(bit32s.rshift(lo,  8), 0xff),
    bit32s.band(lo                  , 0xff)
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
 * Converts this Long to unsigned.
 * @returns {!Long} Unsigned long
--]]
function Long:toUnsigned()
  if self.unsigned then return self end
  return Long.fromBits(self.low, self.high, true)
end

return Long
