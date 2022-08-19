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

<? else ?>

#define EXPORT
#define kernel

<?
end
?>

#define constant
#define global
#define local

#if !defined(__cplusplus)
typedef char bool;
#define true 1
#define false 0
#endif

#include <stddef.h>

//unlike CL, C cannot handle function overloading
#define max(a,b) ((a) > (b) ? (a) : (b))
#define min(a,b) ((a) < (b) ? (a) : (b))
#define clamp(x,_min,_max)	min(_max,max(_min,x))

//TODO
#define CLK_LOCAL_MEM_FENCE	0
void barrier(int whatever) {}

#include <math.h>

typedef unsigned char uchar;
typedef unsigned short ushort;
typedef unsigned int uint;
typedef unsigned long ulong;


// TODO half?
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

#define _<?=base?>4(a,b,c,d) (<?=base?>4){.s={a,b,c,d}}

typedef union {
	struct { <?=base?> x, y, z, w; };
	struct { <?=base?> s0, s1, s2, s3, s4, s5, s6, s7; };
	<?=base?> s[8];
} <?=base?>8 __attribute__((aligned(<?=ffi.sizeof('cl_'..base)*8?>)));
<? end ?>


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

#define get_global_linear_id() 	_program_<?=id?>_threadinfo[0].global_linear_id
#define get_local_linear_id() 	_program_<?=id?>_threadinfo[0].local_linear_id
#define get_global_id(n)		_program_<?=id?>_threadinfo[0].global_id[n]
#define get_local_id(n)			_program_<?=id?>_threadinfo[0].local_id[n]
#define get_group_id(n)			_program_<?=id?>_threadinfo[0].group_id[n]


static int4 int4_add(int4 a, int4 b) {
	return (int4){
		.x = a.x + b.x,
		.y = a.y + b.y,
		.z = a.z + b.z,
		.w = a.w + b.w,
	};
}

// TODO should include isfinite(x) ? NAN : ...
#define sign(x)	((x) > 0 ? 1 : ((x) < 0 ? -1 : 0))

<? 
if kernelCallMethod == 'C-singlethread'
or kernelCallMethod == 'C-multithread'
then 
?>

#include <ffi.h>

<? for _,f in ipairs(ffi_all_types) do 
?>void ffi_set_<?=f[2]?>(ffi_type ** const t) { t[0] = &ffi_type_<?=f[2]?>; }
<? end ?>


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
