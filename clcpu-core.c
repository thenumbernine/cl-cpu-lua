// this is stuff that gets compiled into a single lib used by all cl programs
// it holds the opencl functions used everywhere
// and some private stuff


#include <ffi.h>

// TODO maybe put these in their own library or something?
// they are only used for cl-cpu , so ... how about compiling them into their own .so?
<? for _,f in ipairs(ffi_all_types) do
?>void ffi_set_<?=f[2]?>(ffi_type ** const t) { t[0] = &ffi_type_<?=f[2]?>; }
<? end ?>

// I can put the code shared by all programs in this one place
// hmm and I need to linking against the clcpu global tmp lib

typedef unsigned char uchar;
typedef unsigned short ushort;
typedef unsigned int uint;
typedef unsigned long ulong;

// private variables:

typedef struct {
	uint work_dim;
	size_t global_size[<?=clDeviceMaxWorkItemDimension?>];
	size_t local_size[<?=clDeviceMaxWorkItemDimension?>];
	size_t num_groups[<?=clDeviceMaxWorkItemDimension?>];
	size_t global_work_offset[<?=clDeviceMaxWorkItemDimension?>];
} clcpu_private_globalinfo_t;
clcpu_private_globalinfo_t clcpu_private_globalinfo;

typedef struct {
	size_t global_linear_id;
	size_t local_linear_id;
	size_t global_id[<?=clDeviceMaxWorkItemDimension?>];
	size_t local_id[<?=clDeviceMaxWorkItemDimension?>];
	size_t group_id[<?=clDeviceMaxWorkItemDimension?>];
} clcpu_private_threadinfo_t;
clcpu_private_threadinfo_t clcpu_private_threadinfo[<?=numcores?>];

// opencl api:

uint get_work_dim() {
	return clcpu_private_globalinfo.work_dim;
}

size_t get_global_size(int n) {
	return clcpu_private_globalinfo.global_size[n];
}

size_t get_local_size(int n) {
	return clcpu_private_globalinfo.local_size[n];
}

//this one is supposed to give back the auto-determined size for when clEnqueueNDRangeKernel local_size = NULL
size_t get_enqueued_local_size(int n) {
	return clcpu_private_globalinfo.local_size[n];
}

size_t get_num_groups(int n) {
	return clcpu_private_globalinfo.num_groups[n];
}

size_t get_global_offset(int n) {
	return clcpu_private_globalinfo.global_work_offset[n];
}

//TODO
void barrier(int) {}

<?
if cl.clcpu_kernelCallMethod == 'C-multithread' then
?>
// defined in clcpu-core-multi.cpp
size_t clcpu_private_currentthreadindex();
<? else ?>
#define clcpu_private_currentthreadindex() 0
<? end ?>

size_t get_global_linear_id() {
	return clcpu_private_threadinfo[clcpu_private_currentthreadindex()].global_linear_id;
}

size_t get_local_linear_id() {
	return clcpu_private_threadinfo[clcpu_private_currentthreadindex()].local_linear_id;
}

size_t get_global_id(int n) {
	return clcpu_private_threadinfo[clcpu_private_currentthreadindex()].global_id[n];
}

size_t get_local_id(int n) {
	return clcpu_private_threadinfo[clcpu_private_currentthreadindex()].local_id[n];
}

size_t get_group_id(int n) {
	return clcpu_private_threadinfo[clcpu_private_currentthreadindex()].group_id[n];
}


<?
if cl.clcpu_kernelCallMethod == 'C-singlethread'
or cl.clcpu_kernelCallMethod == 'C-multithread'
then
?>

#include <ffi.h>

void clcpu_private_execSingleThread(
	ffi_cif * cif,
	void (*func)(),
	void ** values
) {

	clcpu_private_globalinfo_t * globalinfo = &clcpu_private_globalinfo;
	clcpu_private_threadinfo_t * threadinfo = clcpu_private_threadinfo;

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

<? end -- cl.clcpu_kernelCallMethod == 'C-singlethread' ?>
