io.stdout:setvbuf("no")
io.stderr:setvbuf("no")

-- Test squishing the library itself.
local file = assert(io.open"simpleSquish.lua")
local lua  = file:read"*a"
file:close()

local simpleSquish = require"simpleSquish"
local squishedLua  = assert(simpleSquish.minify(lua))

print("================================")
print("Squished output:")
print(squishedLua)
print("================================")
