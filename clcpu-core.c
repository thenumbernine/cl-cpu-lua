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
} cl_threadinfo_t;
cl_threadinfo_t clcpu_private_threadinfo[<?=numcores?>];

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
