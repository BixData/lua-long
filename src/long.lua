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
--      obj = fromBits(value, (value | 0) < 0 ? -1 : 0, true)
    if bit32s.bor(value, 0) < 0 then
      obj = Long.fromBits(value, -1, true)
    else
      obj = Long.fromBits(value, 0, true)
    end
--      if (cache)
--          UINT_CACHE[value] = obj
    return obj
  else
--    value |= 0
    value = bit32s.bor(value, 0)
--    if (cache = (-128 <= value && value < 128)) {
--        cachedObj = INT_CACHE[value]
--        if (cachedObj)
--            return cachedObj
--    }
--    obj = fromBits(value, value < 0 ? -1 : 0, false)
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
  if val and val.isInstanceOf and val:isInstanceOf(Long) then
    return val
  end
  if type(val) == 'number' then
    return Long.fromNumber(val)
  end
  if type(val) == 'string' then
    return Long.fromString(val)
  end
  -- Throws for non-objects, converts non-instanceof Long:
  return Long.fromBits(val.low, val.high, val.unsigned)
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

--[[
 * Tests if the specified object is a Long.
 * @function
 * @param {*} obj Object
 * @returns {boolean}
--]]
function Long:isLong()
  return self and self.isInstanceOf and self:isInstanceOf(Long)
end

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
 * Converts the Long to a the nearest floating-point representation of this value (double, 53 bit mantissa).
 * @returns {number}
--]]
function Long:toNumber()
  if self.unsigned then
    --return ((self.high >>> 0) * TWO_PWR_32_DBL) + (self.low >>> 0)
    return (bit32.rshift(self.high, 0) * TWO_PWR_32_DBL) + bit32.rshift(self.low, 0)
  end
  --return self.high * TWO_PWR_32_DBL + (self.low >>> 0)
  return self.high * TWO_PWR_32_DBL + bit32.rshift(self.low, 0)
end

return Long
