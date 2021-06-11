io.stdout:setvbuf("no")
io.stderr:setvbuf("no")

-- Test squishing the library itself.
local squish      = require"simpleSquish"
local lua         = assert(squish.read"simpleSquish.lua")
local minifiedLua = assert(squish.minify(lua))

print("================================")
print("Squished output:")
print(minifiedLua)
print("================================")
