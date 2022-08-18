// ok I could use a c based threadpool
// but instead I'm just going to use std::async

#include <ffi.h>

extern "C" {

//these globals should be in the cl kernel program's obj
// that means I'll have to lua-template this to replace the <?=id?>'s with the program id
// so can I gcc it into an obj and g++ this into an obj and link fine into a lib?

extern uint _program_<?=id?>_work_dim;

extern size_t _program_<?=id?>_global_size_0;
extern size_t _program_<?=id?>_global_size_1;
extern size_t _program_<?=id?>_global_size_2;

extern size_t _program_<?=id?>_local_size_0;
extern size_t _program_<?=id?>_local_size_1;
extern size_t _program_<?=id?>_local_size_2;

extern size_t _program_<?=id?>_num_groups_0;
extern size_t _program_<?=id?>_num_groups_1;
extern size_t _program_<?=id?>_num_groups_2;

extern size_t _program_<?=id?>_global_work_offset_0;
extern size_t _program_<?=id?>_global_work_offset_1;
extern size_t _program_<?=id?>_global_work_offset_2;


//unlike the singlethread implementation, 
// the multithread implementation needs a unique one of these per-thread.

typedef struct {
	extern size_t global_linear_id;
	extern size_t local_linear_id;

	extern size_t local_id_0;
	extern size_t local_id_1;
	extern size_t local_id_2;

	extern size_t group_id_0;
	extern size_t group_id_1;
	extern size_t group_id_2;

	extern size_t global_id_0;
	extern size_t global_id_1;
	extern size_t global_id_2;
} cl_threadinfo_t;
extern cl_threadinfo_t _program_<?=id?>_threadinfo[<?=numcores?>];

void executeKernelMultiThread(
	ffi_cif * cif,
	void (*func)(),
	void ** values
) {
	static std::vector<size_t> cpuids;
	std::itoa(cpuids.begin(), cpuids.end(), 0);
	std::vector<std::future<bool>> handles(<?=numcores?>);

	size_t size = _program_<?=id?>_global_size_0
		* _program_<?=id?>_global_size_1
		* _program_<?=id?>_global_size_2;

	for (size_t coreid = 0; coreid < <?=numcores?>; ++coreid) {
		handles[coreid] = std::async(std::launch::async,
			[coreid](size_t coreid) -> bool {
				auto * info = _program_<?=id?>_threadinfo + coreid;
				size_t ibegin = size*coreid/<?=numcores?>;
				size_t iend = size*(coreid+1)/<?=numcores?>;

				for (size_t i = ibegin; i < iend; ++i) {
					info->global_linear_id = i;
				
					size_t i_0 = i % _program_<?=id?>_global_size_0;
					info->local_id_0 = i_0 % _program_<?=id?>_local_size_0;
					info->group_id_0 = i_0 / _program_<?=id?>_local_size_0;
					info->global_id_0 = i_0 + _program_<?=id?>_global_work_offset_0;
					
					size_t i_1 = (i / _program_<?=id?>_global_size_0) % _program_<?=id?>_global_size_1;
					info->local_id_1 = i_1 % _program_<?=id?>_local_size_1;
					info->group_id_1 = i_1 / _program_<?=id?>_local_size_1;
					info->global_id_1 = i_1 + _program_<?=id?>_global_work_offset_1;
					
					size_t i_2 = (i / _program_<?=id?>_global_size_0) / _program_<?=id?>_global_size_1;
					info->local_id_2 = i_2 % _program_<?=id?>_local_size_2;
					info->group_id_2 = i_2 / _program_<?=id?>_local_size_2;
					info->global_id_2 = i_2 + _program_<?=id?>_global_work_offset_2;
				
					info->local_linear_id = 
						info->local_id_0 + _program_<?=id?>_local_size_0 * (
							info->local_id_1 + _program_<?=id?>_local_size_1 * (
								info->local_id_2
							)
						)
					;

					func();
				}
			},
			coreid
		);
	}
	for (auto & h : handles) { h.get(); }
}

}
