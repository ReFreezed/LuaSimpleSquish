io.stdout:setvbuf("no")
io.stderr:setvbuf("no")

-- Test squishing the library itself.
local file = assert(io.open"simpleSquish.lua")
local lua  = file:read"*a"
file:close()

local squish      = require"simpleSquish"
local minifiedLua = assert(squish.minify(lua))

print("================================")
print("Squished output:")
print(minifiedLua)
print("================================")
