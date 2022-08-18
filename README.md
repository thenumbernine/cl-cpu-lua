[![paypal](https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=KYWUWS86GSFGL)

I haven't had the best of luck with the CPU OpenCL implementation of Intel OpenCL.
I guess AMD's CPU OpenCL is dead.
So for now I'll make a LuaJIT version.
I'm making it in LuaJIT so that I can easily do string manipulation and invoke the gcc compiler.
Maybe later I'll make a C++ version.

Depends on my libraries:
*	lua-ext
*	lua-template
*	lua-ffi-c
