local bit32 = require 'bit32'

-- signed 32-bit bitwise operations, useful when converting JavaScript to Lua
local M = {}

local function signed(n)
  if n >= 2^31 then
    return n - 2^32
  end
  return n
end

function M.band(...)
  return signed(bit32.band(...))
end

function M.bor(...)
  return signed(bit32.bor(...))
end

function M.lshift(...)
  return signed(bit32.lshift(...))
end

function M.rshift(...)
  return signed(bit32.rshift(...))
end

return M
