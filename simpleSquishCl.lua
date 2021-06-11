#!/usr/bin/env lua
--[[============================================================
--=
--=  Command line utility for SimpleSquish
--=  by Marcus 'ReFreezed' Thunström
--=
--=  License: MIT (see the bottom of this file)
--=  Website: https://github.com/ReFreezed/LuaSimpleSquish
--=
--=  Tested for Lua 5.1.
--=
--=  Usage: lua simpleSquishCl.lua <inputFile> <outputFile> <squishArguments>
--=
--============================================================]]

local function errorLine(message)
	io.stderr:write("[SimpleSquish] Error: ", tostring(message), "\n")
	os.exit(1)
end
local function assertLine(v, ...)
	if v then  return v, ...  end
	errorLine(... or "Assertion failed!")
end

local hereSource = debug.getinfo(1, "S").source
local herePath   = hereSource and hereSource:match"@?(.+)"
assertLine(herePath, "Cannot get current directory.")

local pathToSimpleSquish = herePath:gsub("[^/]+$", "simpleSquish.lua")

local squish     = dofile(pathToSimpleSquish)
local squishArgs = _G.arg
local pathIn     = table.remove(squishArgs, 1) or print("[SimpleSquish] Usage: lua simpleSquishCl.lua <inputFile> <outputFile> <squishArguments>") or os.exit()
local pathOut    = table.remove(squishArgs, 1) or errorLine("Missing output path argument.")

local lua = assertLine(squish.read(pathIn))
lua       = assertLine(squish.squish(lua, squishArgs))

assertLine(squish.write(pathOut, lua))
