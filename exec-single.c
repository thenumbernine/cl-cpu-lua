// this is the Lua-templated header code that gets put at the top of the CL files
// to make them more C like
// and includes the FFI stuff for the C-singlethread implementation


<?
local ffi = require 'ffi'
if ffi.os == 'Windows' then
?>
#define __attribute__(x)

//I hate Windows
#define EXPORT __declspec(dllexport)
#define kernel EXPORT

<?
else
	if cl.useCpp then
?>
#define EXPORT
#define kernel extern "C"
<?
	else
?>
#define EXPORT
#define kernel
<?
	end
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

//TODO
#define CLK_LOCAL_MEM_FENCE	0
void _program_<?=id?>_barrier(int whatever) {}
#define barrier _program_<?=id?>_barrier

#define mix(a, b, t) 	((a) * (1. - t) + (b) * t)
#define rsqrt(x)		(1. / sqrt(x))

#include <math.h>

typedef unsigned char uchar;
typedef unsigned short ushort;
typedef unsigned int uint;
typedef unsigned long ulong;

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

typedef struct {
	uint work_dim;
	size_t global_size[<?=clDeviceMaxWorkItemDimension?>];
	size_t local_size[<?=clDeviceMaxWorkItemDimension?>];
	size_t num_groups[<?=clDeviceMaxWorkItemDimension?>];
	size_t global_work_offset[<?=clDeviceMaxWorkItemDimension?>];
} cl_globalinfo_t;
EXPORT cl_globalinfo_t _program_<?=id?>_globalinfo;

#define get_work_dim()		_program_<?=id?>_globalinfo.work_dim
#define get_global_size(n)	_program_<?=id?>_globalinfo.global_size[n]
#define get_local_size(n)	_program_<?=id?>_globalinfo.local_size[n]

//this one is supposed to give back the auto-determined size for when clEnqueueNDRangeKernel local_size = NULL
#define get_enqueued_local_size(n)	_program_<?=id?>_globalinfo.local_size[n]

#define get_num_groups(n)		_program_<?=id?>_globalinfo.num_groups[n]
#define get_global_offset(n)	_program_<?=id?>_global_work_offset[n]


// everything in the following need to know which core you're on:
typedef struct {
	size_t global_linear_id;
	size_t local_linear_id;
	size_t global_id[<?=clDeviceMaxWorkItemDimension?>];
	size_t local_id[<?=clDeviceMaxWorkItemDimension?>];
	size_t group_id[<?=clDeviceMaxWorkItemDimension?>];
} cl_threadinfo_t;
EXPORT cl_threadinfo_t _program_<?=id?>_threadinfo[<?=numcores?>];


<? if kernelCallMethod == 'C-multithread' then ?>
extern size_t _program_<?=id?>_currentthreadindex();
<? else ?>
#define _program_<?=id?>_currentthreadindex()	0
<? end ?>

#define get_global_linear_id() 	_program_<?=id?>_threadinfo[_program_<?=id?>_currentthreadindex()].global_linear_id
#define get_local_linear_id() 	_program_<?=id?>_threadinfo[_program_<?=id?>_currentthreadindex()].local_linear_id
#define get_global_id(n)		_program_<?=id?>_threadinfo[_program_<?=id?>_currentthreadindex()].global_id[n]
#define get_local_id(n)			_program_<?=id?>_threadinfo[_program_<?=id?>_currentthreadindex()].local_id[n]
#define get_group_id(n)			_program_<?=id?>_threadinfo[_program_<?=id?>_currentthreadindex()].group_id[n]

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

<?
if kernelCallMethod == 'C-singlethread'
or kernelCallMethod == 'C-multithread'
then
?>

#include <ffi.h>

void _program_<?=id?>_execSingleThread(
	ffi_cif * cif,
	void (*func)(),
	void ** values
) {
	cl_globalinfo_t * globalinfo = &_program_<?=id?>_globalinfo;
	cl_threadinfo_t * threadinfo = _program_<?=id?>_threadinfo;

	threadinfo->global_linear_id = 0;

	size_t is[<?=clDeviceMaxWorkItemDimension?>];

	is[0] = 0;
	for (
		threadinfo->local_id[0] = 0,
		threadinfo->group_id[0] = 0,
		threadinfo->global_id[0] = globalinfo->global_work_offset[0];

		is[0] < globalinfo->global_size[0];

		++is[0],
		++threadinfo->local_id[0],
		++threadinfo->global_id[0]
	) {
		if (threadinfo->local_id[0] == globalinfo->local_size[0]) {
			threadinfo->local_id[0] = 0;
			++threadinfo->group_id[0];
		}

		is[1] = 0;
		for (
			threadinfo->local_id[1] = 0,
			threadinfo->group_id[1] = 0,
			threadinfo->global_id[1] = globalinfo->global_work_offset[1];

			is[1] < globalinfo->global_size[1];

			++is[1],
			++threadinfo->local_id[1],
			++threadinfo->global_id[1]
		) {
			if (threadinfo->local_id[1] == globalinfo->local_size[1]) {
				threadinfo->local_id[1] = 0;
				++threadinfo->group_id[1];
			}

			is[2] = 0;
			for (
				threadinfo->local_id[2] = 0,
				threadinfo->group_id[2] = 0,
				threadinfo->global_id[2] = globalinfo->global_work_offset[2];

				is[2] < globalinfo->global_size[2];

				++is[2],
				++threadinfo->local_id[2],
				++threadinfo->global_id[2],
				++threadinfo->global_linear_id
			) {
				if (threadinfo->local_id[2] == globalinfo->local_size[2]) {
					threadinfo->local_id[2] = 0;
					++threadinfo->group_id[2];
				}

				threadinfo->local_linear_id =
					threadinfo->local_id[0] + globalinfo->local_size[0] * (
						threadinfo->local_id[1] + globalinfo->local_size[1] * (
							threadinfo->local_id[2]
						)
					)
				;


				void *tmpret;
				ffi_call(cif, func, &tmpret, values);
			}
		}
	}
}


<? end -- kernelCallMethod == 'C-singlethread' ?>
