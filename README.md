# SimpleSquish
**SimpleSquish** is a simple library for Lua 5.1 that wraps around [Squish](https://github.com/LuaDist/squish/).
It exposes the functionality of Squish without requiring a file system.
Internally, SimpleSquish creates a virtual file system which enables us to feed Squish all necessary
data as Lua strings instead of having to deal with creating `squishy` files for it, etc.

SimpleSquish is perfect if you, for example, just want to minify or obfuscate some Lua code as part of your program.

- [Usage](#usage)
- [API](#api)
- [Squish arguments](#squish-arguments)
- [Command Line](#command-line)



## Usage
The files you need from this repository are [simpleSquish.lua](simpleSquish.lua) and [squish.lua](squish.lua).
To use the library from the [command line](#command-line) you also need [simpleSquishCl.lua](simpleSquishCl.lua).

```lua
local squish = require("simpleSquish")

local lua = [[
	local x = 5 -- Hello.
	local function foo()
		print("World")
	end
]]

local minifiedLua = squish.minify(lua)
print(minifiedLua)

-- Output will be something like:
-- local a=5 local function b()print("World")end
```

See [runTest.lua](runTest.lua) for more example code.



## API


### minify

`squishedLua = squish.minify( lua [, minifyLevel="full", extraSquishArguments ] )`

Apply *minify* on some Lua code.
`minifyLevel` can be `"none"`, `"debug"`, `"default"`, `"basic"` or `"full"`.
Shorthand for:

```lua
local args        = {"--minify-level=full"}
local squishedLua = squish.squish(lua, args)
```


### minifyAndUglify

`squishedLua = squish.minifyAndUglify( lua [, minifyLevel="full", extraSquishArguments ] )`

Apply *minify* and *uglify* on some Lua code.
`minifyLevel` can be `"none"`, `"debug"`, `"default"`, `"basic"` or `"full"`.
Shorthand for:

```lua
local args        = {"--minify-level=full", "--uglify"}
local squishedLua = squish.squish(lua, args)
```


### read

`contents, error = squish.read( path [, isBinaryFile=false ] )`

Read the entire contents of a file.
Returns **nil** and a message on error.


### squish

`squishedLua = squish.squish( lua [, squishArguments ] )`

Squish some Lua code, optionally with extra [arguments for Squish](#squish-arguments).


### squishPath

`squish.squishPath = ""`

The path to [squish.lua](squish.lua).
An empty string means SimpleSquish will try to load it from the same folder as SimpleSquish is in.


### VERSION

`squish.VERSION`

The current version of SimpleSquish, e.g. `"1.3.0"`.


### write

`success, error = squish.write( path, contents [, isBinaryFile=false ] )`

Write to a file.
Returns **false** and a message on error.



## Squish Arguments

Arguments can be prefixed with `no-` to negate their meaning, e.g. `--no-minify-comments`.
Some arguments may not work in certain situations.


### Minify

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


### Uglify

- `--uglify`
- `--uglify-level=full`


### Logging

- `--verbose` or `-v`
- `--very-verbose` or `-vv`
- `--quiet` or `-q`
- `--very-quiet` or `-qq`


### Other

- `--compile`
- `--compile-strip`
- `--debug`
- `--executable`
- `--executable=path`
- `--use-http`

See Squish documentation/code for more information about it's arguments.



## Command Line

The library can be used from the command line through [simpleSquishCl.lua](simpleSquishCl.lua):

`lua simpleSquishCl.lua <inputFile> <outputFile> <squishArguments>`

Example:

`lua path/to/simpleSquishCl.lua src/myApp.lua output/myApp.lua --minify`


