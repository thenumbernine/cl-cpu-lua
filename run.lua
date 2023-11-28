#!/usr/bin/env luajit

local execfn = arg[0]

require 'cl-cpu.setup'
local clcpu = require 'ffi.req' 'OpenCL'
clcpu.pathToCLCPU = require 'ext.path'(execfn):getdir():abs()

local function run(...)
	local x = ...
	-- handle any args?
	if x == "-cpp" then
		clcpu.useCpp = true
		return run(select(2, ...))
	elseif x == '-I' then
		-- TODO how about we just pass args to compiler
		local inc = assert(select(2, ...), "expected -I <include dirs> (;-separated)")
		local path = require 'ext.path'
		clcpu.extraInclude:insert(path(inc):abs().path)
		return run(select(3, ...))
	end
	-- else ...
	loadfile(x)(select(2, ...))
end

run(...)
