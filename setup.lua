-- here's the package overriding to redirect ffi.OpenCL 
local clcpu = require 'cl-cpu'
-- work around all the requests of ffi.req
package.loaded['cl.ffi.OpenCL'] = clcpu
