#!/usr/bin/env luajit

local execfn = arg[0]

require 'cl-cpu.setup'
require 'ffi.req' 'OpenCL'.pathToCLCPU = require 'ext.path'(execfn):getdir():abs().path

local function run(...)
	local x = ...
	-- handle any args?
	if x == "-cpp" then
		require 'ffi.req' 'OpenCL'.useCpp = true
		return run(select(2, ...))
	end
	-- else ...
	local filename = ...
	loadfile(filename)(select(2, ...))
end

run(...)
