--[[============================================================
--=
--=  SimpleSquish library - a wrapper around Squish
--=  by Marcus 'ReFreezed' Thunström
--=
--=  License: MIT (see the bottom of this file)
--=  Website: https://github.com/ReFreezed/LuaSimpleSquish
--=
--=  Tested for Lua 5.1.
--=
--============================================================]]

local VERSION = "0.1.0"

local squish



--==============================================================
--= Local Functions ============================================
--==============================================================

local assertarg
local copyTable
local indexOf
local newSquishEnvironment
local readFile, writeFile

local doSquish
local minify, minifyAndUglify



-- assertarg( argumentNumber, value, expectedValueType1, ... )
function assertarg(n, v, ...)
	local vType = type(v)

	for i = 1, select("#", ...) do
		if vType == select(i, ...) then  return  end
	end

	local fName   = debug.getInfo(2, "n").name
	local expects = table.concat({...}, " or ")

	if fName == "" then  fName = "?"  end

	error(F("bad argument #%d to '%s' (%s expected, got %s)", n, fName, expects, vType), 3)
end



-- copy = copyTable( table [, deep=false ] )
do
	local function deepCopy(t, copy, tableCopies)
		for k, v in pairs(t) do
			if type(v) == "table" then
				local vCopy = tableCopies[v]

				if vCopy then
					copy[k] = vCopy
				else
					vCopy          = {}
					tableCopies[v] = vCopy
					copy[k]        = deepCopy(v, vCopy, tableCopies)
				end

			else
				copy[k] = v
			end
		end
		return copy
	end

	function copyTable(t, deep)
		if deep then
			return deepCopy(t, {}, {})
		end

		local copy = {}
		for k, v in pairs(t) do  copy[k] = v  end

		return copy
	end
end



function indexOf(t, v)
	for i = 1, #t do
		if t[i] == v then  return i  end
	end
	return nil
end



local YIELD_EXIT = {}

-- environment, runInEnvironment, setVirtualFileContents, getVirtualFileContents = newSquishEnvironment( )
function newSquishEnvironment()
	-- Squish is made as a command line tool unfortunately so here we try to create
	-- a virtual file system for it so we can use it as a library that don't operate
	-- on any actual files.

	-- @Incomplete: Simplify paths containing "." and "..".

	local env = {
		_VERSION=_VERSION, assert=assert, collectgarbage=collectgarbage, dofile=dofile, error=error, getfenv=getfenv,
		getmetatable=getmetatable, ipairs=ipairs, load=load, loadfile=loadfile, loadstring=loadstring, module=module,
		next=next, pairs=pairs, pcall=pcall, print=print, rawequal=rawequal, rawget=rawget, rawset=rawset, require=require,
		select=select, setfenv=setfenv, setmetatable=setmetatable, tonumber=tonumber, tostring=tostring, type=type,
		unpack=unpack, xpcall=xpcall,

		coroutine = copyTable(coroutine, true),
		debug     = copyTable(debug,     true),
		io        = copyTable(io,        true),
		math      = copyTable(math,      true),
		os        = copyTable(os,        true),
		package   = copyTable(package,   true),
		string    = copyTable(string,    true),
		table     = copyTable(table,     true),
	}
	env._G = env

	local virtualFileContents = {--[[path=contents]]}
	local openVirtualFiles    = {--[[virtualFile, ...]]}
	local openVirtualPaths    = {--[[path=true]]}
	local closedVirtualFiles  = setmetatable({--[[virtualFile=true]]}, {__mode="k"})

	function env.dofile(path)
		return assert(env.loadfile(path))()
	end
	function env.loadfile(path)
		if not virtualFileContents[path] then
			return nil, "File does not exist."
		end

		local chunk, err = loadstring(virtualFileContents[path], path)
		if not chunk then  return nil, err  end

		setfenv(chunk, env)
		return chunk
	end
	function env.module(moduleName, ...)
		-- @Incomplete: Apply extra arguments. (https://www.lua.org/manual/5.1/manual.html#pdf-module)
		local M = env.package.loaded[moduleName]

		if not M then
			M = env[moduleName] or {}
			env[moduleName] = M
		end

		setfenv(2, M)
		env.package.loaded[moduleName] = M
	end
	function env.require(moduleName)
		local M = env.package.loaded[moduleName]
		if M then  return M  end

		if env.package.preload[moduleName] then
			M = env.package.preload[moduleName](moduleName)

			-- I'm not sure exactly how module() and require() works together in the native functions...
			if M == nil then  M = env.package.loaded[moduleName]  end
			if M == nil then  M = true  end

			env.package.loaded[moduleName] = M
			return M
		end

		error("@Incomplete: Require new modules.")
	end

	function env.io.lines(path)
		error("@Incomplete: io.lines()")
	end
	function env.io.open(path, mode)
		mode = mode or "r"

		local modeMode, modeBinary, modeUpdate = mode:match"^([rwa])(b?)(%+?)$"
		if not modeMode then
			return nil, "Invalid mode '"..mode.."'."
		end

		if openVirtualPaths[path] then
			return nil, path..": File is already open."
		end

		modeBinary = modeBinary == "b"
		modeUpdate = modeUpdate == "+"

		if modeMode == "r" then
			if not virtualFileContents[path] then
				return nil, path..": File does not exist."
			end
		elseif modeMode == "a" then
			return nil, "@Incomplete: io.open(path, 'a')"
		end

		local isOpen = true
		local buffer = {}

		local virtualFile = {
			close = function(virtualFile)
				if not isOpen then  return  end

				isOpen = false
				table.remove(openVirtualFiles, indexOf(openVirtualFiles, virtualFile))
				closedVirtualFiles[virtualFile] = true
				openVirtualPaths[path] = nil

				if modeMode == "w" then
					virtualFileContents[path] = table.concat(buffer)
				end
			end,

			flush = function(virtualFile)
				-- This has no effect in the virtual file system.
			end,

			lines = function(virtualFile)
				error("@Incomplete: file:lines()")
			end,

			read = function(virtualFile, ...)
				if not isOpen      then  return nil, "File is closed."             end
				if modeMode ~= "r" then  return nil, "File is in read-only mode."  end

				if select("#", ...) ~= 1 then
					error("@Incomplete: Other than 1 argument for file:read().")
				end

				local readFormat = ...
				if readFormat ~= "*a" then
					error("@Incomplete: Other formats than '*a' for file:read().")
				end

				-- @Incomplete: Start from the pointer and move the pointer to the end.
				local s = virtualFileContents[path]

				-- @Incomplete: Detect OS somehow?
				-- if isWindows and not modeBinary then  s = s:gsub("\r\n", "\n")  end

				return s
			end,

			seek = function(virtualFile)
				error("@Incomplete: file:seek()")
			end,

			setvbuf = function(virtualFile)
				-- This has no effect in the virtual file system.
			end,

			write = function(virtualFile, ...)
				if not isOpen      then  return nil, "File is closed."              end
				if modeMode ~= "w" then  return nil, "File is in write-only mode."  end

				for i = 1, select("#", ...) do
					local v = select(i, ...)

					if not (type(v) == "string" or type(v) == "number") then
						error("Value is not a string or number. (Got a "..type(v)..": "..tostring(v)..")", 2)
					end

					local s = tostring(v)

					-- @Incomplete: Detect OS somehow?
					-- if isWindows and not modeBinary then  s = s:gsub("\n", "\r\n")  end

					table.insert(buffer, s)
				end

				return true
			end,
		}

		openVirtualPaths[path] = true
		table.insert(openVirtualFiles, virtualFile)

		return virtualFile
	end
	function env.io.type(obj)
		if indexOf(openVirtualFiles, obj) then
			return "file"
		elseif closedVirtualFiles[obj] then
			return "closed file"
		else
			return nil
		end
	end

	function env.os.exit(exitCode)
		exitCode = exitCode or 0
		coroutine.yield(YIELD_EXIT, exitCode)
	end
	function env.os.remove(path)
		if openVirtualPaths[path] then
			return false, path..": File is open."
		elseif not virtualFileContents[path] then
			return false, path..": File does not exist."
		end
		virtualFileContents[path] = nil
		return true
	end
	function env.os.rename(pathOld, pathNew)
		if openVirtualPaths[pathOld] then
			return false, pathOld..": File is open."
		elseif not virtualFileContents[pathOld] then
			return false, pathOld..": File does not exist."
		elseif virtualFileContents[pathNew] or openVirtualPaths[pathNew] then
			return false, pathNew..": File already exists."
		end

		virtualFileContents[pathNew] = virtualFileContents[pathOld]
		virtualFileContents[pathOld] = nil
	end

	-- success, exitCode = runInEnvironment( function, arg1, ... ) -- If success is true.
	-- success, error    = runInEnvironment( function, arg1, ... ) -- If success is false.
	local function runInEnvironment(f, ...)
		setfenv(f, env)
		local co = coroutine.create(f)
		local ok, yieldedCodeOrErr, exitCode = coroutine.resume(co, ...)

		if ok then
			local yieldedCode = yieldedCodeOrErr
			return true, (yieldedCode == YIELD_EXIT and exitCode or nil)
		else
			local err = yieldedCodeOrErr
			return false, err
		end
	end

	local function getVirtualFileContents(path)
		return virtualFileContents[path]
	end

	local function setVirtualFileContents(path, contents)
		virtualFileContents[path] = contents
	end

	return env, runInEnvironment, getVirtualFileContents, setVirtualFileContents
end



-- contents, error = readFile( path [, isTextFile=false ] )
function readFile(path, isTextFile)
	local file, err = io.open(path, (isTextFile and "r" or "rb"))
	if not file then  return nil, err  end

	local contents = file:read"*a"
	file:close()

	return contents
end

-- success, error = writeFile( path, contents [, isTextFile=false ] )
function writeFile(path, contents, isTextFile)
	local file, err = io.open(path, (isTextFile and "w" or "wb"))
	if not file then  return nil, err  end

	file:write(contents)
	file:close()

	return true
end



--==============================================================



-- squishedLua = doSquish( lua [, squishArguments ] )
-- @Incomplete: Allow 'lua' to be an array of strings.
local function doSquish(lua, squishArgs)
	assertarg(1, lua,        "string")
	assertarg(2, squishArgs, "table","nil")

	squishArgs = squishArgs and copyTable(squishArgs) or {}
	-- table.insert(squishArgs, "--very-verbose") -- DEBUG

	-- Remove --output/-o as they are useless in the virtual file system.
	for i = #squishArgs, 1, -1 do
		local option = (squishArgs[i]:match"^%-%-?([^=]+)" or ""):lower()

		if option == "output" or option == "o" then
			table.remove(squishArgs, i)
		end
	end

	local basePath = "." -- Concept used in Squish.

	local squishy = [[
		Output "out"
		Main   "lua"
	]]

	local env, runInEnvironment, getVirtualFileContents, setVirtualFileContents = newSquishEnvironment()
	setVirtualFileContents(basePath.."/lua", lua)
	setVirtualFileContents(basePath.."/squishy", squishy)

	local path = squish.squishPath
	if path == "" then
		local source         = debug.getinfo(1, "S").source
		local pathToThisFile = source and source:match"@?(.+)" or "?"
		path                 = pathToThisFile:gsub("[^/]+$", "squish.lua")
	end

	local chunk, err = loadfile(path)
	if not chunk then  return nil, err  end

	local ok, errOrExitCode = runInEnvironment(chunk, basePath, unpack(squishArgs))
	if not ok then
		local err = errOrExitCode
		return nil, err
	end

	if errOrExitCode then
		local exitCode = errOrExitCode
		if exitCode ~= 0 then
			return nil, "Squish exited with code "..exitCode.."."
		end
	end

	local luaSquished = getVirtualFileContents"out"
	if not luaSquished then  return nil, "Something went wrong."  end

	return luaSquished
end



-- squishedLua = minify( lua [, minifyLevel="full", extraSquishArguments ] )
function minify(lua, minifyLevel, squishArgs)
	assertarg(1, lua,         "string")
	assertarg(2, minifyLevel, "string","nil")
	assertarg(3, squishArgs,  "table","nil")

	minifyLevel = minifyLevel or "full"
	squishArgs  = squishArgs and copyTable(squishArgs) or {}

	table.insert(squishArgs, "--minify-level="..minifyLevel)

	return doSquish(lua, squishArgs)
end

-- squishedLua = minifyAndUglify( lua [, minifyLevel="full", extraSquishArguments ] )
function minifyAndUglify(lua, minifyLevel, squishArgs)
	assertarg(1, lua,         "string")
	assertarg(2, minifyLevel, "string","nil")
	assertarg(3, squishArgs,  "table","nil")

	minifyLevel = minifyLevel or "full"
	squishArgs  = squishArgs and copyTable(squishArgs) or {}

	table.insert(squishArgs, "--minify-level="..minifyLevel)

	table.insert(squishArgs, "--uglify")
	table.insert(squishArgs, "--uglify-level=full")

	return doSquish(lua, squishArgs)
end



--==============================================================
--==============================================================
--==============================================================

squish = {
	VERSION         = VERSION,
	squishPath      = "", -- An empty string means we'll try to guess where Squish is using the debug library.

	read            = readFile,
	write           = writeFile,

	minify          = minify,
	minifyAndUglify = minifyAndUglify,
	squish          = doSquish,
}

return squish



--[[!===========================================================

Copyright © 2018 Marcus 'ReFreezed' Thunström

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

==============================================================]]
