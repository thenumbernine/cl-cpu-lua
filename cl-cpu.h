//these globals should be in the cl kernel program's obj
// that means I'll have to lua-template this to replace the <?=id?>'s with the program id
// so can I gcc it into an obj and g++ this into an obj and link fine into a lib?

typedef unsigned char uchar;
typedef unsigned short ushort;
typedef unsigned int uint;
typedef unsigned long ulong;

typedef struct {
	uint work_dim;
	size_t global_size[<?=cl.private.deviceMaxWorkItemDim?>];
	size_t local_size[<?=cl.private.deviceMaxWorkItemDim?>];
	size_t num_groups[<?=cl.private.deviceMaxWorkItemDim?>];
	size_t global_work_offset[<?=cl.private.deviceMaxWorkItemDim?>];
} clcpu_private_globalinfo_t;
<?=extern?> clcpu_private_globalinfo_t clcpu_private_globalinfo;

//unlike the singlethread implementation, 
// the multithread implementation needs a unique one of these per-thread.

typedef struct {
	size_t global_linear_id;
	size_t local_linear_id;
	size_t global_id[<?=cl.private.deviceMaxWorkItemDim?>];
	size_t local_id[<?=cl.private.deviceMaxWorkItemDim?>];
	size_t group_id[<?=cl.private.deviceMaxWorkItemDim?>];
} clcpu_private_threadinfo_t;
<?=extern?> clcpu_private_threadinfo_t clcpu_private_threadinfo[<?=cl.private.numcores?>];
