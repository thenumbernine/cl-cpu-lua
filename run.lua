#!/usr/bin/env luajit

local execfn = arg[0]

require 'cl-cpu.setup'
require 'ffi.req' 'OpenCL'.pathToCLCPU = require 'ext.path'(execfn):getdir()

local filename = ...
loadfile(filename)(select(2, ...))
