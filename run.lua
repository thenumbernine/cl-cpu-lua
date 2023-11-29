#!/usr/bin/env luajit

local execfn = arg[0]

require 'cl-cpu.setup'
local clcpu = require 'ffi.req' 'OpenCL'
local pathToCLCPU = require 'ext.path'(execfn):getdir():abs()

local function handleArgs(...)
	local x = ...
	-- handle any args?
	if x == "-cpp" then
		clcpu.useCpp = true
		return handleArgs(select(2, ...))
	elseif x == '-I' then
		-- TODO how about we just pass args to compiler
		local inc = assert(select(2, ...), "expected -I <include dirs> (;-separated)")
		local path = require 'ext.path'
		clcpu.extraInclude:insert(path(inc):abs().path)
		return handleArgs(select(3, ...))
	end

	-- else run ...
	clcpu.private:initialize{
		pathToCLCPU = pathToCLCPU,
	}
	loadfile(x)(select(2, ...))
end

handleArgs(...)
