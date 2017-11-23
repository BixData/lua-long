local bit32 = require 'bit32'
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
  self.low = low or 0

  --[[
   * The high 32 bits as a signed value.
   * @type {number}
  --]]
  self.high = high or 0

  --[[
   * Whether unsigned or not.
   * @type {boolean}
  --]]
  self.unsigned = not not unsigned
end

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
 * @function
 * @param {*} obj Object
 * @returns {boolean}
 * @inner
--]]
local function isLong(obj)
    return obj and obj.isInstanceOf and obj:isInstanceOf(Long)
end

--[[
 * Tests if the specified object is a Long.
 * @function
 * @param {*} obj Object
 * @returns {boolean}
--]]
function Long:isLong() return isLong(self) end

--[[
 * @param {number} lowBits
 * @param {number} highBits
 * @param {boolean=} unsigned
 * @returns {!Long}
 * @inner
--]]
local function fromBits(lowBits, highBits, unsigned)
  return Long:new(lowBits, highBits, unsigned)
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
Long.fromBits = fromBits
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
    bit32.band(lo                  , 0xff),
    bit32.band(bit32.rshift(lo,  8), 0xff),
    bit32.band(bit32.rshift(lo, 16), 0xff),
    bit32.band(bit32.rshift(lo, 24), 0xff),
    bit32.band(hi                  , 0xff),
    bit32.band(bit32.rshift(hi, 8) , 0xff),
    bit32.band(bit32.rshift(hi, 16), 0xff),
    bit32.band(bit32.rshift(hi, 24), 0xff)
  }
end

--[[
 * Converts this Long to its big endian byte representation.
 * @returns {!Array.<number>} Big endian byte representation
--]]
function Long:toBytesBE()
  local hi, lo = self.high, self.low
  return {
    bit32.band(bit32.rshift(hi, 24), 0xff),
    bit32.band(bit32.rshift(hi, 16), 0xff),
    bit32.band(bit32.rshift(hi,  8), 0xff),
    bit32.band(hi                  , 0xff),
    bit32.band(bit32.rshift(lo, 24), 0xff),
    bit32.band(bit32.rshift(lo, 16), 0xff),
    bit32.band(bit32.rshift(lo,  8), 0xff),
    bit32.band(lo                  , 0xff)
  }
end

return Long
