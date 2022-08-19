// ok I could use a c based threadpool
// but instead I'm just going to use std::async

#include <ffi.h>
//#include <vector>
//#include <numeric>	//iota
//#include <future>

//extern "C" {

typedef unsigned int uint;

//these globals should be in the cl kernel program's obj
// that means I'll have to lua-template this to replace the <?=id?>'s with the program id
// so can I gcc it into an obj and g++ this into an obj and link fine into a lib?

typedef struct {
	uint work_dim;
	size_t global_size[<?=clDeviceMaxWorkItemDimension?>];
	size_t local_size[<?=clDeviceMaxWorkItemDimension?>];
	size_t num_groups[<?=clDeviceMaxWorkItemDimension?>];
	size_t global_work_offset[<?=clDeviceMaxWorkItemDimension?>];
} cl_globalinfo_t;
extern cl_globalinfo_t _program_<?=id?>_globalinfo;

//unlike the singlethread implementation, 
// the multithread implementation needs a unique one of these per-thread.

typedef struct {
	size_t global_linear_id;
	size_t local_linear_id;
	size_t local_id[<?=clDeviceMaxWorkItemDimension?>];
	size_t group_id[<?=clDeviceMaxWorkItemDimension?>];
	size_t global_id[<?=clDeviceMaxWorkItemDimension?>];
} cl_threadinfo_t;
extern cl_threadinfo_t _program_<?=id?>_threadinfo[<?=numcores?>];


void _program_<?=id?>_execMultiThread(
	ffi_cif * cif,
	void (*func)(),
	void ** values
) {
#if 1	//single-thread in multi-thread/cpp file
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
#else	//multithread
	cl_globalinfo_t * globalinfo = &_program_<?=id?>_globalinfo;

	static std::vector<size_t> cpuids;
	std::iota(cpuids.begin(), cpuids.end(), 0);
	std::vector<std::future<bool>> handles(<?=numcores?>);

	size_t size = globalinfo->global_size[0]
		* globalinfo->global_size[1]
		* globalinfo->global_size[2];

	for (size_t coreid = 0; coreid < <?=numcores?>; ++coreid) {
		handles[coreid] = std::async(std::launch::async,
			[size, globalinfo, cif, func, values](size_t coreid) -> bool {
				cl_threadinfo_t * threadinfo = _program_<?=id?>_threadinfo + coreid;
				size_t ibegin = size * coreid / <?=numcores?>;
				size_t iend = size * (coreid+1) / <?=numcores?>;

				for (size_t i = ibegin; i < iend; ++i) {
					threadinfo->global_linear_id = i;
				
					size_t is[<?=clDeviceMaxWorkItemDimension?>];
					is[0] = i % globalinfo->global_size[0];
					threadinfo->local_id[0] = is[0] % globalinfo->local_size[0];
					threadinfo->group_id[0] = is[0] / globalinfo->local_size[0];
					threadinfo->group_id[0] = is[0] + globalinfo->global_work_offset[0];
					
					is[1] = (i / globalinfo->global_size[0]) % globalinfo->global_size[1];
					threadinfo->local_id[1] = is[1] % globalinfo->local_size[1];
					threadinfo->group_id[1] = is[1] / globalinfo->local_size[1];
					threadinfo->group_id[1] = is[1] + globalinfo->global_work_offset[1];
					
					is[2] = (i / globalinfo->global_size[0]) / globalinfo->global_size[1];
					threadinfo->local_id[2] = is[2] % globalinfo->local_size[2];
					threadinfo->group_id[2] = is[2] / globalinfo->local_size[2];
					threadinfo->group_id[2] = is[2] + globalinfo->global_work_offset[2];
				
					threadinfo->local_linear_id =
						threadinfo->local_id[0] + globalinfo->local_size[0] * (
							threadinfo->local_id[1] + globalinfo->local_size[1] * (
								threadinfo->local_id[2]
							)
						)
					;

					void *tmpret;
					ffi_call(cif, func, &tmpret, values);
				
					return true;
				}
			},
			coreid
		);
	}
	for (auto & h : handles) { h.get(); }
#endif
}

//}
