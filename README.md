# SimpleSquish
*SimpleSquish* is a simple Lua library that wraps around [Squish](https://github.com/LuaDist/squish/).
It exposes the functionality of Squish without requiring a file system.
Internally, *SimpleSquish* creates a virtual file system which enables us to feed Squish all necessary
data as Lua strings instead of having to deal with creating `squish` files for it, etc.

*SimpleSquish* is perfect if you, for example, just want to minify or obfuscate some Lua code as part of your program.

- [Usage](#usage)
- [API](#api)
	- [Squish arguments](#squish-arguments)


## Usage
The files you need from this repository are [`simpleSquish.lua`](simpleSquish.lua) and [`squish.lua`](squish.lua).

```lua
local simpleSquish = require("simpleSquish")

local lua = [[
	local x = 5
	local function foo()
		print("Hello")
	end
]]

local squishedLua = simpleSquish.minify(lua)
print(squishedLua)

-- Output will be something like:
-- local a=5 local function b()print("Hello")end
```

See [`runTest.lua`](runTest.lua) for more example code.


## API

#### minify
`squishedLua = simpleSquish.minify( lua [, minifyLevel="full", extraSquishArguments ] )`

Apply *minify* on some Lua code.
`minifyLevel` can be "none", "debug", "default", "basic" or "full".
Shorthand for:

```lua
local args = {"--minify-level=full"}
local squishedLua = simpleSquish.squish(lua, args)
```

#### minifyAndUglify
`squishedLua = simpleSquish.minifyAndUglify( lua [, minifyLevel="full", extraSquishArguments ] )`

Apply *minify* and *uglify* on some Lua code.
`minifyLevel` can be "none", "debug", "default", "basic" or "full".
Shorthand for:

```lua
local args = {"--minify-level=full", "--uglify"}
local squishedLua = simpleSquish.squish(lua, args)
```

#### squish
`squishedLua = simpleSquish.squish( lua [, squishArguments ] )`

Squish some Lua code.

#### squishPath
`simpleSquish.squishPath = "./squish.lua"`

The path to `squish.lua`.
You may have to update this if the current working directory isn't the library's folder.

#### VERSION
`simpleSquish.VERSION`

The current version of *SimpleSquish*, e.g. `"1.3.0"`.


### Squish Arguments
Arguments can be prefixed with `no-` to negate their meaning, e.g. `--no-minify-comments`.
Some arguments may not work in certain situations.

#### Minify
- `--minify`
- `--minify-level=none|debug|default|basic|full`
- `--minify-comments`
- `--minify-emptylines`
- `--minify-entropy`
- `--minify-eols`
- `--minify-locals`
- `--minify-numbers`
- `--minify-strings`
- `--minify-whitespace`

#### Uglify
- `--uglify`
- `--uglify-level=full`

#### Logging
- `--verbose` or `-v`
- `--very-verbose` or `-vv`
- `--quiet` or `-q`
- `--very-quiet` or `-qq`

#### Other
- `--compile`
- `--compile-strip`
- `--debug`
- `--executable`
- `--executable=path`
- `--use-http`

See Squish documentation/code for more info about it's arguments.

