#!/usr/bin/env luajit

local execfn = arg[0]

require 'cl-cpu.setup'
require 'ffi.OpenCL'.pathToCLCPU = require 'ext.io'.getfiledir(execfn)

local filename = ...
loadfile(filename)(select(2, ...))
