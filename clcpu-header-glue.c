// this is the Lua-templated header code that gets put at the top of the CL files
// to make them more C like
// and includes the FFI stuff for the C-singlethread implementation

<?
local externC = cl.useCpp and 'extern "C"' or ""
?>

<?
local ffi = require 'ffi'
if ffi.os == 'Windows' then
?>
#define __attribute__(x)

//I hate Windows
#define kernel <?=externC?> __declspec(dllexport)

<?
else
?>
#define kernel <?=externC?>
<?
end
?>


<? if not cl.useCpp then ?>

// "constant" is the name of a variable used in bits/timex.h, so ... you can't do this ...
// unless you can think of a name to define it as which doubles as both a valid c++ name and is an argument attribute that degenerates to nothing.
// otherwise ...
// for clcpp files you will have to insert these #defines after all #includes
// (and for headers, #undef them at the end of the file)
#define constant
#define global
#define local

typedef char bool;
#define true 1
#define false 0

//unlike CL, C cannot handle function overloading
#define max(a,b) ((a) > (b) ? (a) : (b))
#define min(a,b) ((a) < (b) ? (a) : (b))
#define clamp(x,_min,_max)	min(_max,max(_min,x))

<? else -- cl.useCpp ?>

#define CLCPU_ENABLED

#include <algorithm>
using std::clamp;
using std::min;
using std::max;

<? end -- cl.useCpp ?>

#include <stddef.h>

//TODO esp in multithreaded implementation
#define CLK_LOCAL_MEM_FENCE	0
void barrier(int);

#define mix(a, b, t) 	((a) * (1. - t) + (b) * t)
#define rsqrt(x)		(1. / sqrt(x))

#include <math.h>

<?=clcpu_h?>

//https://stackoverflow.com/questions/45108628/how-to-enable-fp16-type-on-gcc-for-x86-64
// so maybe with clang?
// TODO half?
//typedef __fp16 half;

<? if cl.useCpp then ?>

<? for _,base in ipairs(vectorTypes) do ?>
union <?=base?>2 {
	struct { <?=base?> x, y; };
	struct { <?=base?> s0, s1; };
	<?=base?> s[2];
	<?=base?>2() {}
	<?=base?>2(<?=base?> const x_, <?=base?> const y_) { x = x_; y = y_; }
} __attribute__((aligned(<?=ffi.sizeof('cl_'..base)*2?>)));

union <?=base?>3 {
	struct { <?=base?> x, y, z; };
	struct { <?=base?> s0, s1, s2; };
	<?=base?> s[3];
	<?=base?>3() {}
	<?=base?>3(<?=base?> const x_, <?=base?> const y_, <?=base?> const z_) { x = x_; y = y_; z = z_; }
} __attribute__((aligned(<?=ffi.sizeof('cl_'..base)*4?>)));

union <?=base?>4 {
	struct { <?=base?> x, y, z, w; };
	struct { <?=base?> s0, s1, s2, s3; };
	<?=base?> s[4];
	<?=base?>4() {}
	<?=base?>4(<?=base?> const x_, <?=base?> const y_, <?=base?> const z_, <?=base?> const w_) { x = x_; y = y_; z = z_; w = w_; }
} __attribute__((aligned(<?=ffi.sizeof('cl_'..base)*4?>)));

union <?=base?>8 {
	struct { <?=base?> x, y, z, w; };
	struct { <?=base?> s0, s1, s2, s3, s4, s5, s6, s7; };
	<?=base?> s[8];
} __attribute__((aligned(<?=ffi.sizeof('cl_'..base)*8?>)));
<? end ?>

<? else -- cl.useCpp ?>

<? for _,base in ipairs(vectorTypes) do ?>
typedef union {
	struct { <?=base?> x, y; };
	struct { <?=base?> s0, s1; };
	<?=base?> s[2];
} <?=base?>2 __attribute__((aligned(<?=ffi.sizeof('cl_'..base)*2?>)));

typedef union {
	struct { <?=base?> x, y, z; };
	struct { <?=base?> s0, s1, s2; };
	<?=base?> s[3];
} <?=base?>3 __attribute__((aligned(<?=ffi.sizeof('cl_'..base)*4?>)));

typedef union {
	struct { <?=base?> x, y, z, w; };
	struct { <?=base?> s0, s1, s2, s3; };
	<?=base?> s[4];
} <?=base?>4 __attribute__((aligned(<?=ffi.sizeof('cl_'..base)*4?>)));

typedef union {
	struct { <?=base?> x, y, z, w; };
	struct { <?=base?> s0, s1, s2, s3, s4, s5, s6, s7; };
	<?=base?> s[8];
} <?=base?>8 __attribute__((aligned(<?=ffi.sizeof('cl_'..base)*8?>)));

//I replace all the (int4)(a,b,c,d) with _int4(a,b,c,d) in cl-cpu.lua
#define _<?=base?>2(a,b)		(<?=base?>2){.s={a,b}}
#define _<?=base?>4(a,b,c,d)	(<?=base?>4){.s={a,b,c,d}}

<? end ?>

<? end -- cl.useCpp ?>

<?=externC?> uint get_work_dim();
<?=externC?> size_t get_global_size(int n);
<?=externC?> size_t get_local_size(int n);
<?=externC?> size_t get_enqueued_local_size(int n);
<?=externC?> size_t get_num_groups(int n);
<?=externC?> size_t get_global_offset(int n);

<?=externC?> size_t get_global_linear_id();
<?=externC?> size_t get_local_linear_id();
<?=externC?> size_t get_global_id(int n);
<?=externC?> size_t get_local_id(int n);
<?=externC?> size_t get_group_id(int n);


<? if cl.useCpp then ?>

inline int4 operator+(int4 const & a, int4 const & b) {
	return int4{a.x + b.x, a.y + b.y, a.z + b.z, a.w + b.w};
}
inline int4 operator-(int4 const & a, int4 const & b) {
	return int4{a.x - b.x, a.y - b.y, a.z - b.z, a.w - b.w};
}
inline int4 operator*(int const a, int4 const & b) {
	return int4{a * b.x, a * b.y, a * b.z, a * b.w};
}
inline int4 operator*(int4 const & a, int const b) {
	return int4{a.x * b, a.y * b, a.z * b, a.w * b};
}

<? else -- cl.useCpp ?>

static int4 int4_add(int4 a, int4 b) {
	return (int4){
		.x = a.x + b.x,
		.y = a.y + b.y,
		.z = a.z + b.z,
		.w = a.w + b.w,
	};
}

<? end -- cl.useCpp ?>

// TODO should include isfinite(x) ? NAN : ...
#define sign(x)	((x) > 0 ? 1 : ((x) < 0 ? -1 : 0))
