-- here's the package overriding to redirect ffi.OpenCL 
package.loaded['ffi.OpenCL'] = require 'cl-cpu'
