#!/usr/bin/env luajit
local filename = ...
require 'cl-cpu.setup'
loadfile(filename)(select(2, ...))
