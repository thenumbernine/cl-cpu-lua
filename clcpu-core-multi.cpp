// here's stuff that goes in one place for everyone
// but just cpp
// esp for multithreading

// ok I could use a c based threadpool
// but instead I'm just going to use std::async

#include <stddef.h>			//size_t

<?=clcpu_h?>

#include <vector>
#include <numeric>	//iota
#include <future>

#include <ffi.h>

extern "C" void clcpu_private_execSingleThread(
	ffi_cif * cif,
	void (*func)(),
	void ** values
);

#include <iostream>

// ok to convert the get_group_id get_global_id get_local_id etc to a single lib
// I need currentthreadindex
// but for that to move to my single lib
// I need a cpp portion of it
// and for that
// I might as well move this file into it ...

static thread_local size_t clcpu_private_threadIndexForID = {};

extern "C" size_t clcpu_private_currentthreadindex() {
	return clcpu_private_threadIndexForID;
}

extern "C" void clcpu_private_execMultiThread(
	ffi_cif * cif,
	void (*func)(),
	void ** values
) {
#if 0	//single-thread in multi-thread/cpp file
	clcpu_private_execSingleThread(cif, func, values);
#else	//multithread
	clcpu_private_globalinfo_t * globalinfo = &clcpu_private_globalinfo;

	static std::vector<size_t> cpuids;
	std::iota(cpuids.begin(), cpuids.end(), 0);
	std::vector<std::future<bool>> handles(<?=cl.private.numcores?>);

	size_t size = globalinfo->global_size[0]
		* globalinfo->global_size[1]
		* globalinfo->global_size[2];

	for (size_t coreid = 0; coreid < <?=cl.private.numcores?>; ++coreid) {
		handles[coreid] = std::async(std::launch::async,
			[size, globalinfo, cif, func, values](size_t coreid) -> bool {
				clcpu_private_threadIndexForID = coreid;
				clcpu_private_threadinfo_t * threadinfo = clcpu_private_threadinfo + coreid;
				size_t ibegin = size * coreid / <?=cl.private.numcores?>;
				size_t iend = size * (coreid+1) / <?=cl.private.numcores?>;
				for (size_t i = ibegin; i < iend; ++i) {
					threadinfo->global_linear_id = i;
				
					size_t is[<?=clDeviceMaxWorkItemDimension?>];
					size_t rest = i;
					is[0] = rest % globalinfo->global_size[0];
					rest -= is[0];
					rest /= globalinfo->global_size[0];
					threadinfo->local_id[0] = is[0] % globalinfo->local_size[0];
					threadinfo->group_id[0] = is[0] / globalinfo->local_size[0];
					threadinfo->global_id[0] = is[0] + globalinfo->global_work_offset[0];
					
					is[1] = rest % globalinfo->global_size[1];
					rest -= is[1];
					rest /= globalinfo->global_size[1];
					threadinfo->local_id[1] = is[1] % globalinfo->local_size[1];
					threadinfo->group_id[1] = is[1] / globalinfo->local_size[1];
					threadinfo->global_id[1] = is[1] + globalinfo->global_work_offset[1];
					
					is[2] = rest; // % globalinfo->global_size[1];
					threadinfo->local_id[2] = is[2] % globalinfo->local_size[2];
					threadinfo->group_id[2] = is[2] / globalinfo->local_size[2];
					threadinfo->global_id[2] = is[2] + globalinfo->global_work_offset[2];
				
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
				return true;
			},
			coreid
		);
	}
	for (auto & h : handles) { h.get(); }
#endif
}
