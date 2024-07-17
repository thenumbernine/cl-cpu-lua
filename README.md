[![Donate via Stripe](https://img.shields.io/badge/Donate-Stripe-green.svg)](https://buy.stripe.com/00gbJZ0OdcNs9zi288)<br>

I haven't had the best of luck with the CPU OpenCL implementation of Intel OpenCL.
I guess AMD's CPU OpenCL is dead.
So for now I'll make a LuaJIT version.
I'm making it in LuaJIT so that I can easily do string manipulation and invoke the gcc/clang compiler.
Maybe later I'll make a C++ version.

Depends on my libraries:
*	[lua-ext](https://github.com/thenumbernine/lua-ext)
*	[lua-template](https://github.com/thenumbernine/lua-template)
*	[lua-ffi-c](https://github.com/thenumbernine/lua-ffi-c)
