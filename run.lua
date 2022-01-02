#!/usr/bin/env luajit
local filename = ...
package.loaded['ffi.OpenCL'] = require 'cl-cpu'
dofile(filename)
