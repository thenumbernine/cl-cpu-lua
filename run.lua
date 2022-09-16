#!/usr/bin/env luajit

local execfn = arg[0]

require 'cl-cpu.setup'
require 'ffi.OpenCL'.pathToCLCPU = require 'ext.file'(execfn):getdir()

local filename = ...
loadfile(filename)(select(2, ...))
