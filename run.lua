#!/usr/bin/env luajit

local execfn = arg[0]

require 'cl-cpu.setup'
local clcpu = require 'cl'

local args = {}
args.pathToCLCPU = require 'ext.path'(execfn):getdir():abs()

local function handleArgs(...)
	local x = ...
	-- handle any args?
	if x == "-cpp" then
		args.useCpp = true
		return handleArgs(select(2, ...))
	elseif x == '-I' then
		-- TODO how about we just pass args to compiler
		local inc = assert(select(2, ...), "expected -I <include dirs> (;-separated)")
		local path = require 'ext.path'
		args.includeDirs = args.includeDirs or require 'ext.table'()
		args.includeDirs:insert(path(inc):abs().path)
		return handleArgs(select(3, ...))
	elseif x == '-kernelCallMethod' then
		args.kernelCallMethod = select(2, ...)
		return handleArgs(select(3, ...))
	end

	arg = {select(2, ...)}

	-- else run ...
	clcpu.private:initialize(args)
	loadfile(x)(select(2, ...))
end

handleArgs(...)
