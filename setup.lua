-- here's the package overriding to redirect ffi.OpenCL 
local ffi = require 'ffi'
local clcpu = require 'cl-cpu'
-- work around all the requests of ffi.req
package.loaded['ffi.'..ffi.os..'.'..ffi.arch..'.OpenCL'] = clcpu
package.loaded['ffi.'..ffi.os..'.OpenCL'] = clcpu
package.loaded['ffi.'..ffi.arch..'.OpenCL'] = clcpu
package.loaded['ffi.OpenCL'] = clcpu
