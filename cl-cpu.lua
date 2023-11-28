local ffi = require 'ffi'
local table = require 'ext.table'
local path = require 'ext.path'
local string = require 'ext.string'
local io = require 'ext.io'
local template = require 'template'

require 'ffi.req' 'c.stdlib'	-- rand()



local cl = {}

-- this is written in cl-cpu/run.lua immediately after loading cl-cpu/cl-cpu.lua
cl.pathToCLCPU = '.'

-- whether to verify each pointer passed into a function was an object we created
local extraStrictVerification = true


--cl.clcpu_kernelCallMethod = 'Lua'				-- fps 3
--cl.clcpu_kernelCallMethod = 'C-singlethread'		-- fps 15
cl.clcpu_kernelCallMethod = 'C-multithread'


if cl.clcpu_kernelCallMethod == 'C-singlethread'
or cl.clcpu_kernelCallMethod == 'C-multithread'
then
	require 'ffi.req' 'libffi'	-- this is lib-ffi, not luajit-ffi
end

local ffi_all_types = table{
--[[ these are typedef'd to others
	'uchar',
	'schar',
	'ushort',
	'sshort',
	'uint',
	'sint',
	'ulong',
	'slong',
--]]
	-- [1] = C name, [2] = ffi name
	{'uint8_t', 'uint8'},
	{'int8_t', 'sint8'},
	{'uint16_t', 'uint16'},
	{'int16_t', 'sint16'},
	{'uint32_t', 'uint32'},
	{'int32_t', 'sint32'},
	{'uint64_t', 'uint64'},
	{'int64_t', 'sint64'},
	{'float', 'float'},
	{'double', 'double'},
	{'long double', 'longdouble'},

	-- these don't need setters
	{'void', 'void'},
	{'void*', 'pointer'},
}

local numcores = 1
if cl.clcpu_kernelCallMethod == 'C-multithread' then
	-- TODO get numcores from hardware_concurrency
	require 'ffi.req' 'c.sys.sysinfo'
	numcores = tonumber(ffi.C.get_nprocs())
	print('using '..numcores..' cores')
end


-- copied from ffi/OpenCL.lua
ffi.cdef[[
enum {
  CL_SUCCESS                                   = 0,
  CL_DEVICE_NOT_FOUND                          = -1,
  CL_DEVICE_NOT_AVAILABLE                      = -2,
  CL_COMPILER_NOT_AVAILABLE                    = -3,
  CL_MEM_OBJECT_ALLOCATION_FAILURE             = -4,
  CL_OUT_OF_RESOURCES                          = -5,
  CL_OUT_OF_HOST_MEMORY                        = -6,
  CL_PROFILING_INFO_NOT_AVAILABLE              = -7,
  CL_MEM_COPY_OVERLAP                          = -8,
  CL_IMAGE_FORMAT_MISMATCH                     = -9,
  CL_IMAGE_FORMAT_NOT_SUPPORTED                = -10,
  CL_BUILD_PROGRAM_FAILURE                     = -11,
  CL_MAP_FAILURE                               = -12,
  CL_MISALIGNED_SUB_BUFFER_OFFSET              = -13,
  CL_EXEC_STATUS_ERROR_FOR_EVENTS_IN_WAIT_LIST = -14,
  CL_COMPILE_PROGRAM_FAILURE                  = -15,
  CL_LINKER_NOT_AVAILABLE                     = -16,
  CL_LINK_PROGRAM_FAILURE                     = -17,
  CL_DEVICE_PARTITION_FAILED                  = -18,
  CL_KERNEL_ARG_INFO_NOT_AVAILABLE            = -19,

  CL_INVALID_VALUE                             = -30,
  CL_INVALID_DEVICE_TYPE                       = -31,
  CL_INVALID_PLATFORM                          = -32,
  CL_INVALID_DEVICE                            = -33,
  CL_INVALID_CONTEXT                           = -34,
  CL_INVALID_QUEUE_PROPERTIES                  = -35,
  CL_INVALID_COMMAND_QUEUE                     = -36,
  CL_INVALID_HOST_PTR                          = -37,
  CL_INVALID_MEM_OBJECT                        = -38,
  CL_INVALID_IMAGE_FORMAT_DESCRIPTOR           = -39,
  CL_INVALID_IMAGE_SIZE                        = -40,
  CL_INVALID_SAMPLER                           = -41,
  CL_INVALID_BINARY                            = -42,
  CL_INVALID_BUILD_OPTIONS                     = -43,
  CL_INVALID_PROGRAM                           = -44,
  CL_INVALID_PROGRAM_EXECUTABLE                = -45,
  CL_INVALID_KERNEL_NAME                       = -46,
  CL_INVALID_KERNEL_DEFINITION                 = -47,
  CL_INVALID_KERNEL                            = -48,
  CL_INVALID_ARG_INDEX                         = -49,
  CL_INVALID_ARG_VALUE                         = -50,
  CL_INVALID_ARG_SIZE                          = -51,
  CL_INVALID_KERNEL_ARGS                       = -52,
  CL_INVALID_WORK_DIMENSION                    = -53,
  CL_INVALID_WORK_GROUP_SIZE                   = -54,
  CL_INVALID_WORK_ITEM_SIZE                    = -55,
  CL_INVALID_GLOBAL_OFFSET                     = -56,
  CL_INVALID_EVENT_WAIT_LIST                   = -57,
  CL_INVALID_EVENT                             = -58,
  CL_INVALID_OPERATION                         = -59,
  CL_INVALID_GL_OBJECT                         = -60,
  CL_INVALID_BUFFER_SIZE                       = -61,
  CL_INVALID_MIP_LEVEL                         = -62,
  CL_INVALID_GLOBAL_WORK_SIZE                  = -63,
  CL_INVALID_PROPERTY                          = -64,
  CL_VERSION_1_0                               = 1,
  CL_VERSION_1_1                               = 1,
  CL_FALSE                                     = 0,
  CL_TRUE                                      = 1,
  CL_PLATFORM_PROFILE                          = 0x0900,
  CL_PLATFORM_VERSION                          = 0x0901,
  CL_PLATFORM_NAME                             = 0x0902,
  CL_PLATFORM_VENDOR                           = 0x0903,
  CL_PLATFORM_EXTENSIONS                       = 0x0904,
  CL_PLATFORM_HOST_TIMER_RESOLUTION            = 0x0905,
  CL_DEVICE_TYPE_DEFAULT                       = 0x01,
  CL_DEVICE_TYPE_CPU                           = 0x02,
  CL_DEVICE_TYPE_GPU                           = 0x04,
  CL_DEVICE_TYPE_ACCELERATOR                   = 0x08,
  CL_DEVICE_TYPE_ALL                           = 0xFFFFFFFF,
  CL_DEVICE_TYPE                               = 0x1000,
  CL_DEVICE_VENDOR_ID                          = 0x1001,
  CL_DEVICE_MAX_COMPUTE_UNITS                  = 0x1002,
  CL_DEVICE_MAX_WORK_ITEM_DIMENSIONS           = 0x1003,
  CL_DEVICE_MAX_WORK_GROUP_SIZE                = 0x1004,
  CL_DEVICE_MAX_WORK_ITEM_SIZES                = 0x1005,
  CL_DEVICE_PREFERRED_VECTOR_WIDTH_CHAR        = 0x1006,
  CL_DEVICE_PREFERRED_VECTOR_WIDTH_SHORT       = 0x1007,
  CL_DEVICE_PREFERRED_VECTOR_WIDTH_INT         = 0x1008,
  CL_DEVICE_PREFERRED_VECTOR_WIDTH_LONG        = 0x1009,
  CL_DEVICE_PREFERRED_VECTOR_WIDTH_FLOAT       = 0x100A,
  CL_DEVICE_PREFERRED_VECTOR_WIDTH_DOUBLE      = 0x100B,
  CL_DEVICE_MAX_CLOCK_FREQUENCY                = 0x100C,
  CL_DEVICE_ADDRESS_BITS                       = 0x100D,
  CL_DEVICE_MAX_READ_IMAGE_ARGS                = 0x100E,
  CL_DEVICE_MAX_WRITE_IMAGE_ARGS               = 0x100F,
  CL_DEVICE_MAX_MEM_ALLOC_SIZE                 = 0x1010,
  CL_DEVICE_IMAGE2D_MAX_WIDTH                  = 0x1011,
  CL_DEVICE_IMAGE2D_MAX_HEIGHT                 = 0x1012,
  CL_DEVICE_IMAGE3D_MAX_WIDTH                  = 0x1013,
  CL_DEVICE_IMAGE3D_MAX_HEIGHT                 = 0x1014,
  CL_DEVICE_IMAGE3D_MAX_DEPTH                  = 0x1015,
  CL_DEVICE_IMAGE_SUPPORT                      = 0x1016,
  CL_DEVICE_MAX_PARAMETER_SIZE                 = 0x1017,
  CL_DEVICE_MAX_SAMPLERS                       = 0x1018,
  CL_DEVICE_MEM_BASE_ADDR_ALIGN                = 0x1019,
  CL_DEVICE_MIN_DATA_TYPE_ALIGN_SIZE           = 0x101A,
  CL_DEVICE_SINGLE_FP_CONFIG                   = 0x101B,
  CL_DEVICE_GLOBAL_MEM_CACHE_TYPE              = 0x101C,
  CL_DEVICE_GLOBAL_MEM_CACHELINE_SIZE          = 0x101D,
  CL_DEVICE_GLOBAL_MEM_CACHE_SIZE              = 0x101E,
  CL_DEVICE_GLOBAL_MEM_SIZE                    = 0x101F,
  CL_DEVICE_MAX_CONSTANT_BUFFER_SIZE           = 0x1020,
  CL_DEVICE_MAX_CONSTANT_ARGS                  = 0x1021,
  CL_DEVICE_LOCAL_MEM_TYPE                     = 0x1022,
  CL_DEVICE_LOCAL_MEM_SIZE                     = 0x1023,
  CL_DEVICE_ERROR_CORRECTION_SUPPORT           = 0x1024,
  CL_DEVICE_PROFILING_TIMER_RESOLUTION         = 0x1025,
  CL_DEVICE_ENDIAN_LITTLE                      = 0x1026,
  CL_DEVICE_AVAILABLE                          = 0x1027,
  CL_DEVICE_COMPILER_AVAILABLE                 = 0x1028,
  CL_DEVICE_EXECUTION_CAPABILITIES             = 0x1029,
  CL_DEVICE_QUEUE_PROPERTIES                   = 0x102A,
  CL_DEVICE_NAME                               = 0x102B,
  CL_DEVICE_VENDOR                             = 0x102C,
  CL_DRIVER_VERSION                            = 0x102D,
  CL_DEVICE_DRIVER_VERSION                     = CL_DRIVER_VERSION,
  CL_DEVICE_PROFILE                            = 0x102E,
  CL_DEVICE_VERSION                            = 0x102F,
  CL_DEVICE_EXTENSIONS                         = 0x1030,
  CL_DEVICE_PLATFORM                           = 0x1031,
  CL_DEVICE_DOUBLE_FP_CONFIG                   = 0x1032,
  CL_DEVICE_HALF_FP_CONFIG                     = 0x1033,
  CL_DEVICE_PREFERRED_VECTOR_WIDTH_HALF        = 0x1034,
  CL_DEVICE_HOST_UNIFIED_MEMORY                = 0x1035,
  CL_DEVICE_NATIVE_VECTOR_WIDTH_CHAR           = 0x1036,
  CL_DEVICE_NATIVE_VECTOR_WIDTH_SHORT          = 0x1037,
  CL_DEVICE_NATIVE_VECTOR_WIDTH_INT            = 0x1038,
  CL_DEVICE_NATIVE_VECTOR_WIDTH_LONG           = 0x1039,
  CL_DEVICE_NATIVE_VECTOR_WIDTH_FLOAT          = 0x103A,
  CL_DEVICE_NATIVE_VECTOR_WIDTH_DOUBLE         = 0x103B,
  CL_DEVICE_NATIVE_VECTOR_WIDTH_HALF           = 0x103C,
  CL_DEVICE_OPENCL_C_VERSION                   = 0x103D,
  CL_DEVICE_LINKER_AVAILABLE                   = 0x103E,
  CL_DEVICE_BUILT_IN_KERNELS                   = 0x103F,
  CL_FP_DENORM                                 = 0x01,
  CL_FP_INF_NAN                                = 0x02,
  CL_FP_ROUND_TO_NEAREST                       = 0x04,
  CL_FP_ROUND_TO_ZERO                          = 0x08,
  CL_FP_ROUND_TO_INF                           = 0x10,
  CL_FP_FMA                                    = 0x20,
  CL_FP_SOFT_FLOAT                             = 0x40,
  CL_NONE                                      = 0x0,
  CL_READ_ONLY_CACHE                           = 0x1,
  CL_READ_WRITE_CACHE                          = 0x2,
  CL_LOCAL                                     = 0x1,
  CL_GLOBAL                                    = 0x2,
  CL_EXEC_KERNEL                               = 0x1,
  CL_EXEC_NATIVE_KERNEL                        = 0x2,
  CL_QUEUE_OUT_OF_ORDER_EXEC_MODE_ENABLE       = 0x1,
  CL_QUEUE_PROFILING_ENABLE                    = 0x2,
  CL_CONTEXT_REFERENCE_COUNT                   = 0x1080,
  CL_CONTEXT_DEVICES                           = 0x1081,
  CL_CONTEXT_PROPERTIES                        = 0x1082,
  CL_CONTEXT_NUM_DEVICES                       = 0x1083,
  CL_CONTEXT_PLATFORM                          = 0x1084,
  CL_QUEUE_CONTEXT                             = 0x1090,
  CL_QUEUE_DEVICE                              = 0x1091,
  CL_QUEUE_REFERENCE_COUNT                     = 0x1092,
  CL_QUEUE_PROPERTIES                          = 0x1093,
  CL_QUEUE_SIZE                                = 0x1094,
  CL_QUEUE_DEVICE_DEFAULT                      = 0x1095,
  CL_MEM_READ_WRITE                            = 0x01,
  CL_MEM_WRITE_ONLY                            = 0x02,
  CL_MEM_READ_ONLY                             = 0x04,
  CL_MEM_USE_HOST_PTR                          = 0x08,
  CL_MEM_ALLOC_HOST_PTR                        = 0x10,
  CL_MEM_COPY_HOST_PTR                         = 0x20,
  CL_R                                         = 0x10B0,
  CL_A                                         = 0x10B1,
  CL_RG                                        = 0x10B2,
  CL_RA                                        = 0x10B3,
  CL_RGB                                       = 0x10B4,
  CL_RGBA                                      = 0x10B5,
  CL_BGRA                                      = 0x10B6,
  CL_ARGB                                      = 0x10B7,
  CL_INTENSITY                                 = 0x10B8,
  CL_LUMINANCE                                 = 0x10B9,
  CL_Rx                                        = 0x10BA,
  CL_RGx                                       = 0x10BB,
  CL_RGBx                                      = 0x10BC,
  CL_SNORM_INT8                                = 0x10D0,
  CL_SNORM_INT16                               = 0x10D1,
  CL_UNORM_INT8                                = 0x10D2,
  CL_UNORM_INT16                               = 0x10D3,
  CL_UNORM_SHORT_565                           = 0x10D4,
  CL_UNORM_SHORT_555                           = 0x10D5,
  CL_UNORM_INT_101010                          = 0x10D6,
  CL_SIGNED_INT8                               = 0x10D7,
  CL_SIGNED_INT16                              = 0x10D8,
  CL_SIGNED_INT32                              = 0x10D9,
  CL_UNSIGNED_INT8                             = 0x10DA,
  CL_UNSIGNED_INT16                            = 0x10DB,
  CL_UNSIGNED_INT32                            = 0x10DC,
  CL_HALF_FLOAT                                = 0x10DD,
  CL_FLOAT                                     = 0x10DE,
  CL_MEM_OBJECT_BUFFER                         = 0x10F0,
  CL_MEM_OBJECT_IMAGE2D                        = 0x10F1,
  CL_MEM_OBJECT_IMAGE3D                        = 0x10F2,
  CL_MEM_TYPE                                  = 0x1100,
  CL_MEM_FLAGS                                 = 0x1101,
  CL_MEM_SIZE                                  = 0x1102,
  CL_MEM_HOST_PTR                              = 0x1103,
  CL_MEM_MAP_COUNT                             = 0x1104,
  CL_MEM_REFERENCE_COUNT                       = 0x1105,
  CL_MEM_CONTEXT                               = 0x1106,
  CL_MEM_ASSOCIATED_MEMOBJECT                  = 0x1107,
  CL_MEM_OFFSET                                = 0x1108,
  CL_IMAGE_FORMAT                              = 0x1110,
  CL_IMAGE_ELEMENT_SIZE                        = 0x1111,
  CL_IMAGE_ROW_PITCH                           = 0x1112,
  CL_IMAGE_SLICE_PITCH                         = 0x1113,
  CL_IMAGE_WIDTH                               = 0x1114,
  CL_IMAGE_HEIGHT                              = 0x1115,
  CL_IMAGE_DEPTH                               = 0x1116,
  CL_ADDRESS_NONE                              = 0x1130,
  CL_ADDRESS_CLAMP_TO_EDGE                     = 0x1131,
  CL_ADDRESS_CLAMP                             = 0x1132,
  CL_ADDRESS_REPEAT                            = 0x1133,
  CL_ADDRESS_MIRRORED_REPEAT                   = 0x1134,
  CL_FILTER_NEAREST                            = 0x1140,
  CL_FILTER_LINEAR                             = 0x1141,
  CL_SAMPLER_REFERENCE_COUNT                   = 0x1150,
  CL_SAMPLER_CONTEXT                           = 0x1151,
  CL_SAMPLER_NORMALIZED_COORDS                 = 0x1152,
  CL_SAMPLER_ADDRESSING_MODE                   = 0x1153,
  CL_SAMPLER_FILTER_MODE                       = 0x1154,
  CL_MAP_READ                                  = 0x01,
  CL_MAP_WRITE                                 = 0x02,
  CL_PROGRAM_REFERENCE_COUNT                   = 0x1160,
  CL_PROGRAM_CONTEXT                           = 0x1161,
  CL_PROGRAM_NUM_DEVICES                       = 0x1162,
  CL_PROGRAM_DEVICES                           = 0x1163,
  CL_PROGRAM_SOURCE                            = 0x1164,
  CL_PROGRAM_BINARY_SIZES                      = 0x1165,
  CL_PROGRAM_BINARIES                          = 0x1166,
  CL_PROGRAM_BUILD_STATUS                      = 0x1181,
  CL_PROGRAM_BUILD_OPTIONS                     = 0x1182,
  CL_PROGRAM_BUILD_LOG                         = 0x1183,
  CL_BUILD_SUCCESS                             = 0,
  CL_BUILD_NONE                                = -1,
  CL_BUILD_ERROR                               = -2,
  CL_BUILD_IN_PROGRESS                         = -3,
  CL_KERNEL_FUNCTION_NAME                      = 0x1190,
  CL_KERNEL_NUM_ARGS                           = 0x1191,
  CL_KERNEL_REFERENCE_COUNT                    = 0x1192,
  CL_KERNEL_CONTEXT                            = 0x1193,
  CL_KERNEL_PROGRAM                            = 0x1194,
  CL_KERNEL_WORK_GROUP_SIZE                    = 0x11B0,
  CL_KERNEL_COMPILE_WORK_GROUP_SIZE            = 0x11B1,
  CL_KERNEL_LOCAL_MEM_SIZE                     = 0x11B2,
  CL_KERNEL_PREFERRED_WORK_GROUP_SIZE_MULTIPLE = 0x11B3,
  CL_KERNEL_PRIVATE_MEM_SIZE                   = 0x11B4,
  CL_EVENT_COMMAND_QUEUE                       = 0x11D0,
  CL_EVENT_COMMAND_TYPE                        = 0x11D1,
  CL_EVENT_REFERENCE_COUNT                     = 0x11D2,
  CL_EVENT_COMMAND_EXECUTION_STATUS            = 0x11D3,
  CL_EVENT_CONTEXT                             = 0x11D4,
  CL_COMMAND_NDRANGE_KERNEL                    = 0x11F0,
  CL_COMMAND_TASK                              = 0x11F1,
  CL_COMMAND_NATIVE_KERNEL                     = 0x11F2,
  CL_COMMAND_READ_BUFFER                       = 0x11F3,
  CL_COMMAND_WRITE_BUFFER                      = 0x11F4,
  CL_COMMAND_COPY_BUFFER                       = 0x11F5,
  CL_COMMAND_READ_IMAGE                        = 0x11F6,
  CL_COMMAND_WRITE_IMAGE                       = 0x11F7,
  CL_COMMAND_COPY_IMAGE                        = 0x11F8,
  CL_COMMAND_COPY_IMAGE_TO_BUFFER              = 0x11F9,
  CL_COMMAND_COPY_BUFFER_TO_IMAGE              = 0x11FA,
  CL_COMMAND_MAP_BUFFER                        = 0x11FB,
  CL_COMMAND_MAP_IMAGE                         = 0x11FC,
  CL_COMMAND_UNMAP_MEM_OBJECT                  = 0x11FD,
  CL_COMMAND_MARKER                            = 0x11FE,
  CL_COMMAND_ACQUIRE_GL_OBJECTS                = 0x11FF,
  CL_COMMAND_RELEASE_GL_OBJECTS                = 0x1200,
  CL_COMMAND_READ_BUFFER_RECT                  = 0x1201,
  CL_COMMAND_WRITE_BUFFER_RECT                 = 0x1202,
  CL_COMMAND_COPY_BUFFER_RECT                  = 0x1203,
  CL_COMMAND_USER                              = 0x1204,
  CL_COMPLETE                                  = 0x0,
  CL_RUNNING                                   = 0x1,
  CL_SUBMITTED                                 = 0x2,
  CL_QUEUED                                    = 0x3,
  CL_BUFFER_CREATE_TYPE_REGION                 = 0x1220,
  CL_PROFILING_COMMAND_QUEUED                  = 0x1280,
  CL_PROFILING_COMMAND_SUBMIT                  = 0x1281,
  CL_PROFILING_COMMAND_START                   = 0x1282,
  CL_PROFILING_COMMAND_END                     = 0x1283,
  CL_PROFILING_COMMAND_COMPLETE                = 0x1284,
};

typedef signed char               int8_t;
typedef short                     int16_t;
typedef int                       int32_t;
typedef long long                 int64_t;
typedef unsigned char             uint8_t;
typedef unsigned short            uint16_t;
typedef unsigned int              uint32_t;
typedef unsigned long long        uint64_t;
typedef int8_t                    int_least8_t;
typedef int16_t                   int_least16_t;
typedef int32_t                   int_least32_t;
typedef int64_t                   int_least64_t;
typedef uint8_t                   uint_least8_t;
typedef uint16_t                  uint_least16_t;
typedef uint32_t                  uint_least32_t;
typedef uint64_t                  uint_least64_t;
typedef int8_t                    int_fast8_t;
typedef int16_t                   int_fast16_t;
typedef int32_t                   int_fast32_t;
typedef int64_t                   int_fast64_t;
typedef uint8_t                   uint_fast8_t;
typedef uint16_t                  uint_fast16_t;
typedef uint32_t                  uint_fast32_t;
typedef uint64_t                  uint_fast64_t;
typedef long                      intptr_t;
typedef unsigned long             uintptr_t;
typedef long int                  intmax_t;
typedef long unsigned int         uintmax_t;
typedef int8_t                    cl_char;
typedef uint8_t                   cl_uchar;
typedef long int                  ptrdiff_t;
typedef long unsigned int         size_t;
typedef int                       wchar_t;
typedef int16_t                   cl_short        __attribute__((aligned(2)));
typedef uint16_t                  cl_ushort       __attribute__((aligned(2)));
typedef int32_t                   cl_int          __attribute__((aligned(4)));
typedef uint32_t                  cl_uint         __attribute__((aligned(4)));
typedef int64_t                   cl_long         __attribute__((aligned(8)));
typedef uint64_t                  cl_ulong        __attribute__((aligned(8)));
typedef uint16_t                  cl_half         __attribute__((aligned(2)));
typedef float                     cl_float        __attribute__((aligned(4)));
typedef double                    cl_double       __attribute__((aligned(8)));
typedef int8_t                    cl_char2[2]     __attribute__((aligned(2)));
typedef int8_t                    cl_char4[4]     __attribute__((aligned(4)));
typedef int8_t                    cl_char8[8]     __attribute__((aligned(8)));
typedef int8_t                    cl_char16[16]   __attribute__((aligned(16)));
typedef uint8_t                   cl_uchar2[2]    __attribute__((aligned(2)));
typedef uint8_t                   cl_uchar4[4]    __attribute__((aligned(4)));
typedef uint8_t                   cl_uchar8[8]    __attribute__((aligned(8)));
typedef uint8_t                   cl_uchar16[16]  __attribute__((aligned(16)));
typedef int16_t                   cl_short2[2]    __attribute__((aligned(4)));
typedef int16_t                   cl_short4[4]    __attribute__((aligned(8)));
typedef int16_t                   cl_short8[8]    __attribute__((aligned(16)));
typedef int16_t                   cl_short16[16]  __attribute__((aligned(32)));
typedef uint16_t                  cl_ushort2[2]   __attribute__((aligned(4)));
typedef uint16_t                  cl_ushort4[4]   __attribute__((aligned(8)));
typedef uint16_t                  cl_ushort8[8]   __attribute__((aligned(16)));
typedef uint16_t                  cl_ushort16[16] __attribute__((aligned(32)));
typedef int32_t                   cl_int2[2]      __attribute__((aligned(8)));
typedef int32_t                   cl_int4[4]      __attribute__((aligned(16)));
typedef int32_t                   cl_int8[8]      __attribute__((aligned(32)));
typedef int32_t                   cl_int16[16]    __attribute__((aligned(64)));
typedef uint32_t                  cl_uint2[2]     __attribute__((aligned(8)));
typedef uint32_t                  cl_uint4[4]     __attribute__((aligned(16)));
typedef uint32_t                  cl_uint8[8]     __attribute__((aligned(32)));
typedef uint32_t                  cl_uint16[16]   __attribute__((aligned(64)));
typedef int64_t                   cl_long2[2]     __attribute__((aligned(16)));
typedef int64_t                   cl_long4[4]     __attribute__((aligned(32)));
typedef int64_t                   cl_long8[8]     __attribute__((aligned(64)));
typedef int64_t                   cl_long16[16]   __attribute__((aligned(128)));
typedef uint64_t                  cl_ulong2[2]    __attribute__((aligned(16)));
typedef uint64_t                  cl_ulong4[4]    __attribute__((aligned(32)));
typedef uint64_t                  cl_ulong8[8]    __attribute__((aligned(64)));
typedef uint64_t                  cl_ulong16[16]  __attribute__((aligned(128)));
typedef float                     cl_float2[2]    __attribute__((aligned(8)));
typedef float                     cl_float4[4]    __attribute__((aligned(16)));
typedef float                     cl_float8[8]    __attribute__((aligned(32)));
typedef float                     cl_float16[16]  __attribute__((aligned(64)));
typedef double                    cl_double2[2]   __attribute__((aligned(16)));
typedef double                    cl_double4[4]   __attribute__((aligned(32)));
typedef double                    cl_double8[8]   __attribute__((aligned(64)));
typedef double                    cl_double16[16] __attribute__((aligned(128)));
typedef struct _cl_platform_id*   cl_platform_id;
typedef struct _cl_device_id*     cl_device_id;
typedef struct _cl_context*       cl_context;
typedef struct _cl_command_queue* cl_command_queue;
typedef struct _cl_mem*           cl_mem;
typedef struct _cl_program*       cl_program;
typedef struct _cl_kernel*        cl_kernel;
typedef struct _cl_event*         cl_event;
typedef struct _cl_sampler*       cl_sampler;
typedef cl_uint                   cl_bool;
typedef cl_ulong                  cl_bitfield;
typedef cl_bitfield               cl_device_type;
typedef cl_uint                   cl_platform_info;
typedef cl_uint                   cl_device_info;
typedef cl_bitfield               cl_device_address_info;
typedef cl_bitfield               cl_device_fp_config;
typedef cl_uint                   cl_device_mem_cache_type;
typedef cl_uint                   cl_device_local_mem_type;
typedef cl_bitfield               cl_device_exec_capabilities;
typedef cl_bitfield               cl_command_queue_properties;
typedef intptr_t                  cl_context_properties;
typedef cl_uint                   cl_context_info;
typedef cl_uint                   cl_command_queue_info;
typedef cl_uint                   cl_channel_order;
typedef cl_uint                   cl_channel_type;
typedef cl_bitfield               cl_mem_flags;
typedef cl_uint                   cl_mem_object_type;
typedef cl_uint                   cl_mem_info;
typedef cl_uint                   cl_image_info;
typedef cl_uint                   cl_addressing_mode;
typedef cl_uint                   cl_filter_mode;
typedef cl_uint                   cl_sampler_info;
typedef cl_bitfield               cl_map_flags;
typedef cl_uint                   cl_program_info;
typedef cl_uint                   cl_program_build_info;
typedef cl_int                    cl_build_status;
typedef cl_uint                   cl_kernel_info;
typedef cl_uint                   cl_kernel_work_group_info;
typedef cl_uint                   cl_event_info;
typedef cl_uint                   cl_command_type;
typedef cl_uint                   cl_profiling_info;
typedef cl_uint                   cl_buffer_region;

typedef struct _cl_image_format {
  cl_channel_order image_channel_order;
  cl_channel_type  image_channel_data_type;
} cl_image_format;

enum {
  cl_APPLE_SetMemObjectDestructor             = 1,
  cl_APPLE_ContextLoggingFunctions            = 1,
  cl_khr_icd                                  = 1,
  cl_amd_device_memory_flags                  = 1,
  cl_amd_atomic_counters                      = 1,
  cl_ext_device_fission                       = 1,
};
enum {
  CL_PLATFORM_ICD_SUFFIX_KHR                  = 0x0920,
  CL_PLATFORM_NOT_FOUND_KHR                   = -1001,
  CL_DEVICE_COMPUTE_CAPABILITY_MAJOR_NV       = 0x4000,
  CL_DEVICE_COMPUTE_CAPABILITY_MINOR_NV       = 0x4001,
  CL_DEVICE_REGISTERS_PER_BLOCK_NV            = 0x4002,
  CL_DEVICE_WARP_SIZE_NV                      = 0x4003,
  CL_DEVICE_GPU_OVERLAP_NV                    = 0x4004,
  CL_DEVICE_KERNEL_EXEC_TIMEOUT_NV            = 0x4005,
  CL_DEVICE_INTEGRATED_MEMORY_NV              = 0x4006,
  CL_MEM_USE_PERSISTENT_MEM_AMD               = 1 << 6,
  CL_DEVICE_PROFILING_TIMER_OFFSET_AMD        = 0x4036,
  CL_CONTEXT_OFFLINE_DEVICES_AMD              = 0x403F,
  CL_INVALID_COUNTER_AMD                      = -10000,
  CL_DEVICE_MAX_ATOMIC_COUNTERS_AMD           = 0x10000,
  CL_COUNTER_INC_ONLY_AMD                     = 1 << 0,
  CL_COUNTER_DEC_ONLY_AMD                     = 1 << 1,
  CL_COUNTER_FLAGS_AMD                        = 0x10001,
  CL_COUNTER_REFERENCE_COUNT_AMD              = 0x10002,
  CL_COUNTER_CONTEXT_AMD                      = 0x10003,
  CL_COMMAND_READ_COUNTER_AMD                 = 0x10004,
  CL_COMMAND_WRITE_COUNTER_AMD                = 0x10005,
  CL_DEVICE_PARTITION_EQUALLY_EXT             = 0x4050,
  CL_DEVICE_PARTITION_BY_COUNTS_EXT           = 0x4051,
  CL_DEVICE_PARTITION_BY_NAMES_EXT            = 0x4052,
  CL_DEVICE_PARTITION_BY_AFFINITY_DOMAIN_EXT  = 0x4053,
  CL_DEVICE_PARENT_DEVICE_EXT                 = 0x4054,
  CL_DEVICE_PARTITION_TYPES_EXT               = 0x4055,
  CL_DEVICE_AFFINITY_DOMAINS_EXT              = 0x4056,
  CL_DEVICE_REFERENCE_COUNT_EXT               = 0x4057,
  CL_DEVICE_PARTITION_STYLE_EXT               = 0x4058,
  CL_DEVICE_PARTITION_FAILED_EXT              = -1057,
  CL_INVALID_PARTITION_COUNT_EXT              = -1058,
  CL_INVALID_PARTITION_NAME_EXT               = -1059,
  CL_AFFINITY_DOMAIN_L1_CACHE_EXT             = 0x1,
  CL_AFFINITY_DOMAIN_L2_CACHE_EXT             = 0x2,
  CL_AFFINITY_DOMAIN_L3_CACHE_EXT             = 0x3,
  CL_AFFINITY_DOMAIN_L4_CACHE_EXT             = 0x4,
  CL_AFFINITY_DOMAIN_NUMA_EXT                 = 0x10,
  CL_AFFINITY_DOMAIN_NEXT_FISSIONABLE_EXT     = 0x100,
  CL_PROPERTIES_LIST_END_EXT                  = 0,
  CL_PARTITION_BY_COUNTS_LIST_END_EXT         = 0,
  CL_PARTITION_BY_NAMES_LIST_END_EXT          = -1,
};

typedef struct _cl_counter_amd* cl_counter_amd;
typedef cl_bitfield             cl_counter_flags_amd;
typedef cl_uint                 cl_counter_info_amd;
typedef cl_ulong                cl_device_partition_property_ext;

typedef cl_int         (* clIcdGetPlatformIDsKHR_fn)(   cl_uint, cl_platform_id *, cl_uint *);
typedef cl_counter_amd (* clCreateCounterAMD_fn)(       cl_context,     cl_counter_flags_amd, cl_uint, cl_int * );
typedef cl_int         (* clGetCounterInfoAMD_fn)(      cl_counter_amd, cl_counter_info_amd, size_t, void *, size_t * );
typedef cl_int         (* clRetainCounterAMD_fn)(       cl_counter_amd  );
typedef cl_int         (* clReleaseCounterAMD_fn)(      cl_counter_amd  );
typedef cl_int         (* clEnqueueReadCounterAMD_fn)(  cl_command_queue, cl_counter_amd, cl_bool, cl_uint *, cl_uint, const cl_event *, cl_event * );
typedef cl_int         (* clEnqueueWriteCounterAMD_fn)( cl_command_queue, cl_counter_amd, cl_bool, cl_uint, cl_uint, const cl_event *, cl_event * );
typedef cl_int         (* clReleaseDeviceEXT_fn)(       cl_device_id );
typedef cl_int         (* clRetainDeviceEXT_fn)(        cl_device_id );
typedef cl_int         (* clCreateSubDevicesEXT_fn)(    cl_device_id, const cl_device_partition_property_ext*, cl_uint, cl_device_id*, cl_uint *);

typedef unsigned int     cl_GLuint;
typedef int              cl_GLint;
typedef unsigned int     cl_GLenum;
typedef cl_uint          cl_gl_object_type;
typedef cl_uint          cl_gl_texture_info;
typedef cl_uint          cl_gl_platform_info;
typedef cl_uint          cl_gl_context_info;
typedef struct __GLsync* cl_GLsync;
typedef cl_int        (* clGetGLContextInfoKHR_fn)( const cl_context_properties *, cl_gl_context_info, size_t, void *, size_t * );

enum {
  cl_khr_gl_sharing                      = 1,
  CL_GL_OBJECT_BUFFER                    = 0x2000,
  CL_GL_OBJECT_TEXTURE2D                 = 0x2001,
  CL_GL_OBJECT_TEXTURE3D                 = 0x2002,
  CL_GL_OBJECT_RENDERBUFFER              = 0x2003,
  CL_GL_TEXTURE_TARGET                   = 0x2004,
  CL_GL_MIPMAP_LEVEL                     = 0x2005,
  CL_INVALID_GL_SHAREGROUP_REFERENCE_KHR = -1000,
  CL_CURRENT_DEVICE_FOR_GL_CONTEXT_KHR   = 0x2006,
  CL_DEVICES_FOR_GL_CONTEXT_KHR          = 0x2007,
  CL_GL_CONTEXT_KHR                      = 0x2008,
  CL_EGL_DISPLAY_KHR                     = 0x2009,
  CL_GLX_DISPLAY_KHR                     = 0x200A,
  CL_WGL_HDC_KHR                         = 0x200B,
  CL_CGL_SHAREGROUP_KHR                  = 0x200C,
  CL_COMMAND_GL_FENCE_SYNC_OBJECT_KHR    = 0x200D,
};

// specific for this CPU implementation
struct _cl_platform_id {
	int verify;
};
struct _cl_device_id {
	int verify;
};
struct _cl_context {
	int verify;
};
struct _cl_mem {
	int verify;
	size_t size;
	cl_mem_flags flags;
	uint8_t* ptr;
	uint8_t* hostPtr;
	cl_context ctx;
};
struct _cl_command_queue {
	int verify;
	cl_context ctx;
	cl_device_id device;
	cl_command_queue_properties properties;
};
struct _cl_event {
	int verify;
	int id;
};

struct _cl_program {
	int verify;
	int id;				//unique id, lookup into programsForID lua table
};

struct _cl_kernel {
	int verify;
	int id;				//unique id, lookup into kernelsForID lua table
};

// start of 1.2 stuff
// not sure where to put it or how to organize this ...
enum {
	CL_PROGRAM_NUM_KERNELS                      = 0x1167,
	CL_PROGRAM_KERNEL_NAMES                     = 0x1168,
};
]]

-- id is usually a cl_* which is typedef'd to a struct _cl_* *, so it's essentially a void*
-- cl_*_info name ... cl_*_info is always uint32, except cl_device_address_info, which is a cl_bitfield, which is a uint64
-- size_t paramSize
-- void* resultPtr
-- size_t* sizePtr
local function handleGetter(args, id, name, paramSize, resultPtr, sizePtr, ...)
--print(debug.traceback())
	if args.idcast then
		local err
		id, err = args.idcast(id)	-- segfault for getting kernel names ...
		if err then return err end
	end

	-- correct type or not, better key it as a lua number,
	-- because keying it as a luajit ffi int will treat it like an object -- then only the identical object in memory will reference the value
	-- likewise I'm keying the args with ffi.C.*** which is a C enum, and luajit will evaluate those as Lua numbers.
	if args.infotype then
		name = tonumber(ffi.cast(args.infotype, name))
	else
		name = tonumber(ffi.cast('cl_uint', name))
	end

	paramSize = ffi.cast('size_t', paramSize)
	resultPtr = ffi.cast('void*', resultPtr)
	sizePtr = ffi.cast('size_t*', sizePtr)
--print(args.name, id, name)--, paramSize, resultPtr, sizePtr)

	local var = args[name]
	if not var then return ffi.C.CL_INVALID_VALUE end

	local tvar = type(var)
	if tvar == 'string' then
		var = {type = 'char[]', getString = var}
	elseif tvar == 'boolean' then
		var = {type = 'cl_bool', get = function(id) return var end}
	elseif tvar == 'table' then
		local value = var.value
		if value then
			assert(var.get == nil)
			var.get = function(id) return ffi.cast(var.type, value) end
			var.value = nil
		end
	end

-- assert that our pointers are already the right type ... ?

--print('var.type', var.type)
	local casttype
	local arraybasetype	-- only used when var.type ends with []
	if var.type:sub(-2) == '[]' then
		-- assume it's a pointer to the array
		arraybasetype = var.type:sub(1,-3)
		casttype = arraybasetype .. '*'
	else
	-- assume it's a pointer to the value
		casttype = var.type .. '*'
	end
--print('casting to '..casttype)
	resultPtr = ffi.cast(casttype, resultPtr)

--print('resultPtr', resultPtr)
--print('sizePtr', sizePtr)

	-- TODO this should be used for array getters, not just string getters
	-- TODO should this only be called when the type ends in a [] ?
	if var.getString then
		local strValue = type(var.getString) == 'string'
			and var.getString
			or var.getString(id, ...)
		assert(type(strValue) == 'string')

		if sizePtr ~= nil then
			sizePtr[0] = #strValue + 1
		end

		if resultPtr ~= nil then
			-- don't copy more than paramSize bytes
			if paramSize < #strValue + 1 then
				return ffi.C.CL_INVALID_VALUE
			end
			ffi.copy(resultPtr, strValue)
		end
	elseif var.getArray then
		return var.getArray(paramSize, resultPtr, sizePtr, id, ...) or ffi.C.CL_SUCCESS
	else
		-- single-value POD results:
		if sizePtr ~= nil then
			sizePtr[0] = ffi.sizeof(var.type)
		end
		if resultPtr ~= nil then
			if paramSize < ffi.sizeof(var.type) then
				return ffi.C.CL_INVALID_VALUE
			end
			-- copy by value
			local value, err = var.get(id, ...)
			if err then
				return err
			end
			resultPtr[0] = value
		end
	end

	return ffi.C.CL_SUCCESS
end

local function makeGetter(args)
	return function(id, name, paramSize, resultPtr, sizePtr)
		return handleGetter(args, id, name, paramSize, resultPtr, sizePtr)
	end
end


-- PLATFORM


local cl_platform_id_verify = ffi.cast('int', ffi.C.rand())

local allPlatforms = table{
	-- allocate a single-array so I can cast it as a pointer
	-- because it's an array-of-struct, I have to use {{ }} in the initializer
	ffi.new('struct _cl_platform_id[1]', {{
		verify = cl_platform_id_verify,
	}})
}
assert(allPlatforms[1][0].verify == cl_platform_id_verify)

local function platformCastAndVerify(platform)
	platform = ffi.cast('struct _cl_platform_id*', platform)
	if platform == nil
	or platform[0].verify ~= cl_platform_id_verify
	or platform ~= ffi.cast('struct _cl_platform_id*', allPlatforms[1])
	then
		return nil, ffi.C.CL_INVALID_PLATFORM
	end
	return platform
end

cl.clGetPlatformInfo = makeGetter{
	name = 'clGetPlatformInfo',
	infotype = 'cl_platform_info',
	idcast = platformCastAndVerify,
	[ffi.C.CL_PLATFORM_PROFILE] = 'FULL_PROFILE',
	[ffi.C.CL_PLATFORM_VERSION] = 'OpenCL 1.1',
	[ffi.C.CL_PLATFORM_NAME] = 'CPU debug implementation',
	[ffi.C.CL_PLATFORM_VENDOR] = 'Christopher Moore',
	[ffi.C.CL_PLATFORM_EXTENSIONS] = '',		-- separator=' '
	[ffi.C.CL_PLATFORM_HOST_TIMER_RESOLUTION] = {
		type = 'cl_ulong',
		value = 1,	-- host timer resolution, in nanosecond, used by clGetDeviceAndHostTimer
	},
}

function cl.clGetPlatformIDs(count, platforms, countPtr)

	count = ffi.cast('cl_uint', count)
	platforms = ffi.cast('cl_platform_id*', platforms)
	countPtr = ffi.cast('cl_uint*', countPtr)

	if count == 0 and platforms ~= nil then
		return ffi.C.CL_INVALID_VALUE
	end
	if platforms == nil and countPtr == nil then
		return ffi.C.CL_INVALID_VALUE
	end
	if countPtr ~= nil then
		countPtr[0] = 1
	end

	if platforms ~= nil and count >= 1 then
		platforms[0] = ffi.cast('struct _cl_platform_id*', allPlatforms[1])
	end

	return ffi.C.CL_SUCCESS
end


-- DEVICE


local clDeviceMaxMemAllocSize = 5461822664
local clDeviceMaxWorkItemDimension = 3
local clDeviceMaxWorkGroupSize = 1

local cl_device_id_verify = ffi.cast('int', ffi.C.rand())

local allDevices = table{
	ffi.new('struct _cl_device_id[1]', {{
		verify = cl_device_id_verify,
	}})
}
assert(allDevices[1][0].verify == cl_device_id_verify)

local function deviceCastAndVerify(device)
	device = ffi.cast('struct _cl_device_id*', device)
	if device == nil
	or device[0].verify ~= cl_device_id_verify
	or device ~= ffi.cast('struct _cl_device_id*', allDevices[1])
	then
		return nil, ffi.C.CL_INVALID_DEVICE
	end
	return device
end

function cl.clRetainDevice(device) end
function cl.clReleaseDevice(device) end

cl.clGetDeviceInfo = makeGetter{
	name = 'clGetDeviceInfo',
	infotype = 'cl_device_info',
	idcast = deviceCastAndVerify,
	[ffi.C.CL_DEVICE_TYPE] = {
		type = 'cl_device_type',
		value = ffi.C.CL_DEVICE_TYPE_CPU,
	},
	[ffi.C.CL_DEVICE_VENDOR_ID] = {
		type = 'cl_uint',
		value = 0,	-- ?
	},
	[ffi.C.CL_DEVICE_MAX_COMPUTE_UNITS] = {
		type = 'cl_uint',
		value = 1,	-- granted, this could be multi-threaded, but the luajit implementation is only single-threaded
	},
	[ffi.C.CL_DEVICE_MAX_WORK_ITEM_DIMENSIONS] = {
		type = 'cl_uint',
		value = clDeviceMaxWorkItemDimension,
	},
	[ffi.C.CL_DEVICE_MAX_WORK_GROUP_SIZE] = {
		type = 'size_t',
		value = clDeviceMaxWorkGroupSize,
	},
	[ffi.C.CL_DEVICE_MAX_WORK_ITEM_SIZES] = {
		type = 'size_t[]',
		-- TODO just use get() but when the type ends in [], instead handle mult ret?
		getArray = function(paramSize, resultPtr, sizePtr)
			if sizePtr ~= nil then
				sizePtr[0] = ffi.sizeof'size_t' * clDeviceMaxWorkItemDimension
			end
			if resultPtr ~= nil then
				if paramSize < ffi.sizeof'size_t' * clDeviceMaxWorkItemDimension then
					return ffi.C.CL_INVALID_VALUE
				end
				resultPtr[0] = 1024
				resultPtr[1] = 1024
				resultPtr[2] = 1024
			end
		end,
	},
	[ffi.C.CL_DEVICE_MAX_MEM_ALLOC_SIZE] = {
		type = 'cl_ulong',
		value = clDeviceMaxMemAllocSize,
	},
	[ffi.C.CL_DEVICE_NAME] = 'CPU debug implementation',
	[ffi.C.CL_DEVICE_VENDOR] = 'Christopher Moore',
	[ffi.C.CL_DEVICE_PROFILE] = 'FULL_PROFILE',
	[ffi.C.CL_DEVICE_VERSION] = 'OpenCL 1.1',
	[ffi.C.CL_DEVICE_EXTENSIONS] = table{
		'cl_khr_fp64',
		--'cl_khr_fp16', -- see the half comments in exec-single.c
	}:concat' ',
	[ffi.C.CL_DEVICE_PLATFORM] = {
		type = 'cl_platform_id',
		getArray = function(paramSize, resultPtr, sizePtr)
			if sizePtr ~= nil then
				sizePtr[0] = ffi.sizeof'cl_platform_id'
			end
			if resultPtr ~= nil then
				if paramSize < ffi.sizeof'cl_platform_id' then
					return ffi.C.CL_INVALID_VALUE
				end
				resultPtr[0] = allPlatforms[1]
			end
		end,
	},
	[ffi.C.CL_DEVICE_OPENCL_C_VERSION] = 'OpenCL 1.1',
	[ffi.C.CL_DEVICE_LINKER_AVAILABLE] = false,
	[ffi.C.CL_DEVICE_BUILT_IN_KERNELS] = '',

	-- ok luajit ...
	-- you can assign variables with suffixes LL or ULL
	-- but you can't ffi.cdef enum them
	[ffi.C.CL_DEVICE_IMAGE2D_MAX_WIDTH] = { type = 'size_t', value = 0xFFFFFFFFFFFFFFFFULL},
	[ffi.C.CL_DEVICE_IMAGE2D_MAX_HEIGHT] = { type = 'size_t', value = 0xFFFFFFFFFFFFFFFFULL},
	[ffi.C.CL_DEVICE_IMAGE3D_MAX_WIDTH] = { type = 'size_t', value = 0xFFFFFFFFFFFFFFFFULL},
	[ffi.C.CL_DEVICE_IMAGE3D_MAX_HEIGHT] = { type = 'size_t', value = 0xFFFFFFFFFFFFFFFFULL},
	[ffi.C.CL_DEVICE_IMAGE3D_MAX_DEPTH] = { type = 'size_t', value = 0xFFFFFFFFFFFFFFFFULL},
}

function cl.clGetDeviceIDs(platform, deviceType, count, devices, countPtr)
	--platform = ffi.cast('cl_platform_id', platform)
	deviceType = ffi.cast('cl_device_type', deviceType)
	count = ffi.cast('cl_uint', count)
	devices = ffi.cast('cl_device_id*', devices)
	countPtr = ffi.cast('cl_uint*', countPtr)

	local platform, err = platformCastAndVerify(platform)
	if err then return err end

	-- if deviceType isn't valid then return CL_INVALID_DEVICE_TYPE end
	if count == 0 and devices ~= nil then
		return ffi.C.CL_INVALID_VALUE
	end

	-- should I only return success when querying cpus?
	--if bit.band(deviceType, bit.bor(ffi.C.CL_DEVICE_TYPE_CPU, ffi.C.CL_DEVICE_TYPE_DEFAULT)) ~= 0 then
	-- or just always?
	if true then
		if countPtr ~= nil then
			countPtr[0] = 1
		end
		if devices ~= nil and count >= 1 then
			devices[0] = allDevices[1]
		end
	else
		return ffi.C.CL_DEVICE_NOT_FOUND
	end
	return ffi.C.CL_SUCCESS
end


-- CONTEXT


local cl_context_verify = ffi.C.rand()

-- TODO multiple contexts? any need yet?
local allContexts = table{
	ffi.new('struct _cl_context[1]', {{
		verify = cl_context_verify,
	}}),
}
assert(allContexts[1][0].verify == cl_context_verify)

local function contextCastAndVerify(ctx)
	ctx = ffi.cast('struct _cl_context*', ctx)
	if ctx == nil
	or ctx[0].verify ~= cl_context_verify
	or ctx ~= ffi.cast('struct _cl_context*', allContexts[1])
	then
		return nil, ffi.C.CL_INVALID_CONTEXT
	end
	return ctx
end

function cl.clRetainContext(ctx) end
function cl.clReleaseContext(ctx) end

cl.clGetContextInfo = makeGetter{
	name = 'clGetContextInfo',
	infotype = 'cl_context_info',
	idcast = contextCastAndVerify,
	--[ffi.C.CL_CONTEXT_REFERENCE_COUNT] = ...,
	[ffi.C.CL_CONTEXT_NUM_DEVICES] = {
		type = 'cl_uint',
		value = 1,
	},
	[ffi.C.CL_CONTEXT_DEVICES] = {
		type = 'cl_device_id[]',
		getArray = function(paramSize, resultPtr, sizePtr)
			if sizePtr ~= nil then
				sizePtr[0] = ffi.sizeof'cl_device_id'
			end
			if resultPtr ~= nil then
				if paramSize < ffi.sizeof'cl_device_id' then
					return ffi.C.CL_INVALID_VALUE
				end
				resultPtr[0] = allDevices[1]
			end
		end,
	},
	[ffi.C.CL_CONTEXT_PROPERTIES] = {
		type = 'cl_context_properties[]',
		getArray = function(paramSize, resultPtr, sizePtr)
			if sizePtr ~= nil then
				sizePtr[0] = 0
			end
			-- resultPtr doesn't matter ... it's a zero-sized array we are filling
		end,
	},
}

local function prepareArgsDevices(numDevices, devices)
	numDevices = ffi.cast('cl_uint', numDevices)
	numDevices = tonumber(numDevices)

--print("devices before cast", devices)
	devices = ffi.cast('cl_device_id*', devices)
--print("devices after cast", devices)
	if devices == nil and numDevices > 0 then
--print("devices was nil but numDevices > 0 was ", numDevices)
		return ffi.C.CL_INVALID_VALUE
	end
	if devices ~= nil and numDevices == 0 then
--print("devices wasn't nil", devices," but numDevices == 0")
		return ffi.C.CL_INVALID_VALUE
	end
	-- make a local copy so program can hold onto it
	local newDevices = ffi.new('cl_device_id[?]', numDevices)
	for i=0,numDevices-1 do
		local device, err = deviceCastAndVerify(devices[i])
		if err then
--print("device["..i.."] wasn't really a device")
			return err
		end
		newDevices[i] = device
	end
	devices = newDevices

	return cl.CL_SUCCESS, devices, numDevices
end

function cl.clCreateContext(properties, numDevices, devices, notify, userData, errcodeRet)
	properties = ffi.cast('cl_context_properties*', properties)
	numDevices = ffi.cast('cl_uint', numDevices)
	devices = ffi.cast('cl_device_id*', devices)

	errcodeRet = ffi.cast('cl_int*', errcodeRet)
	local function returnError(err, ret)
		if errcodeRet ~= nil then errcodeRet[0] = err end
		return ffi.cast('cl_context', ret)
 	end

	-- if 'properties' is invalid, or if 'properties' is null and no platform could be selected, then return CL_INVALID_PLATFORM
	-- if any value in 'properties' is not a valid name then return CL_INVALID_VALUE
	for i=0,tonumber(numDevices)-1 do
		local device, err = deviceCastAndVerify(devices[i])
		if err then
			return returnError(ffi.C.CL_SUCCESS)	-- ... success?
		end
		-- if the device isn't available then return CL_DEVICE_NOT_AVAILABLE
	end
	-- notify is a callback ...
	-- userData is userdata for the notify()
	return returnError(ffi.C.CL_SUCCESS, allContexts[1])
end


-- MEMORY OBJECT


local allMems = table()
local allPtrs = table()	-- because I don't trust luajit to not gc a ptr I ffi.new'd
cl.clcpu_allMems = allMems
cl.clcpu_allPtrs = allPtrs

local cl_mem_verify = ffi.C.rand()

-- casts and returns it as a cl_mem i.e. struct _cl_mem*
-- if it has any problems then returns false, ffi.C.CL_INVALID_MEM_OBJECT
local function memCastAndVerify(mem)
	mem = ffi.cast('struct _cl_mem*', mem)
	if mem == nil
	or mem[0].verify ~= cl_mem_verify
	then
		return nil, ffi.C.CL_INVALID_MEM_OBJECT
	end
	if extraStrictVerification then
		local i
		for j,omem in ipairs(allMems) do
			if ffi.cast('struct _cl_mem*', omem) == mem then
				i = j
				break
			end
		end
		if not i then
			return nil, ffi.C.CL_INVALID_MEM_OBJECT
		end
		assert(#allPtrs == #allMems)
		if allPtrs[i] ~= mem[0].ptr then
			print("mem", mem)
			print("matches allMems["..i.."]")
			print("mem[0].ptr", mem[0].ptr)
			print("allMems["..i.."][0].ptr", allMems[i][0].ptr)
			print("allPtrs["..i.."]", allPtrs[i])
			error'here'
		end
	end
	return mem
end

local function memCastAndVerifyAndAssertNotNull(mem)
	local mem, err = memCastAndVerify(mem)
	if err then return err end

	if mem[0].ptr == nil then
		return nil, ffi.C.CL_INVALID_MEM_OBJECT
	end

	return mem
end

function cl.clRetainMemObject(mem) end
function cl.clReleaseMemObject(mem) end

cl.clGetMemObjectInfo = makeGetter{
	name = 'clGetMemObjectInfo',
	infotype = 'cl_mem_info',
	idcast = memCastAndVerify,
	--[[
	TODO add support for CL_MEM_OBJECT_IMAGE2D, CL_MEM_OBJECT_IMAGE3D via clCreateImage2D / clCreateImage3D
	--]]
	[ffi.C.CL_MEM_TYPE] = {
		type = 'cl_mem_object_type',
		value = ffi.C.CL_MEM_OBJECT_BUFFER,
	},
	[ffi.C.CL_MEM_FLAGS] = {
		type = 'cl_mem_flags',
		get = function(mem)
			return mem[0].flags
		end,
	},
	[ffi.C.CL_MEM_SIZE] = {
		type = 'size_t',
		get = function(mem)
			return mem[0].size
		end,
	},
	[ffi.C.CL_MEM_HOST_PTR] = {
		type = 'void*',
		get = function(mem)
			return mem[0].hostPtr
		end,
	},
	[ffi.C.CL_MEM_MAP_COUNT] = {
		type = 'cl_uint',
		value = 0,	-- "considered immediately stale, used for debugging"
	},
	-- CL_MEM_REFERENCE_COUNT cl_uint
	[ffi.C.CL_MEM_CONTEXT] = {
		type = 'cl_context',
		get = function(mem)
			return mem[0].ctx
		end,
	},
}


-- IMAGE


cl.clGetImageInfo = makeGetter{
	name = 'clGetImageInfo',
	infotype = 'cl_image_info',
	-- and no keys so it should always fail
}


-- BUFFER


--[[
returns cl_mem
which I have typecast to a _cl_mem*
and so in luajit I'm returning a _cl_mem[1]
so that it will act like a _cl_mem*
--]]
function cl.clCreateBuffer(ctx, flags, size, hostPtr, errcodeRet)
	--ctx = ffi.cast('cl_context', ctx)
	flags = ffi.cast('cl_mem_flags', flags)
	size = ffi.cast('size_t', size)
	hostPtr = ffi.cast('void*', hostPtr)
--print('clCreateBuffer', ctx, flags, size, hostPtr, errcodeRet)

	errcodeRet = ffi.cast('cl_int*', errcodeRet)
	local function returnError(err, ret)
		if errcodeRet ~= nil then errcodeRet[0] = err end
		return ffi.cast('cl_mem', ret)
 	end

	local ctx, err = contextCastAndVerify(ctx)
	if err then
		return returnError(err)
	end

	if bit.band(flags, bit.bnot(bit.bor(
		ffi.C.CL_MEM_READ_WRITE,
		ffi.C.CL_MEM_WRITE_ONLY,
		ffi.C.CL_MEM_READ_ONLY,
		ffi.C.CL_MEM_USE_HOST_PTR,
		ffi.C.CL_MEM_ALLOC_HOST_PTR,
		ffi.C.CL_MEM_COPY_HOST_PTR
	))) ~= 0 then
		return returnError(ffi.C.CL_INVALID_VALUE)
	end

	if size == 0
	or size > clDeviceMaxMemAllocSize
	then
		return returnError(ffi.C.CL_INVALID_BUFFER_SIZE)
	end

	local reqHost = bit.band(flags, bit.bor(ffi.C.CL_MEM_USE_HOST_PTR, ffi.C.CL_MEM_COPY_HOST_PTR)) ~= 0
	if (reqHost and hostPtr == nil)
	or (not reqHost and hostPtr ~= nil)
	then
		return returnError(ffi.C.CL_INVALID_HOST_PTR)
	end

	local mem = ffi.new'struct _cl_mem[1]'

	-- TODO upon fail here, return CL_MEM_OBJECT_ALLOCATION_FAILURE or CL_OUT_OF_HOST_MEMORY
	local ptr = ffi.new('uint8_t[?]', size)
	allPtrs:insert(ptr)

--print('ptr', ptr)
--print('size', size)
	mem[0].verify = cl_mem_verify
	mem[0].size = size
	mem[0].flags = flags
	mem[0].ptr = ptr
	mem[0].hostPtr = hostPtr
	mem[0].ctx = ctx
	allMems:insert(mem)	-- don't let luajit gc it.  TODO refcount / retain / release to keep track of it that way

	if reqHost then ffi.copy(mem[0].ptr, hostPtr, size) end

	return returnError(ffi.C.CL_SUCCESS, mem)
	-- return the ptr, not the obj, so ffi.sizeof says it's a ptr size, not the obj size (which is double)
end


-- COMMAND QUEUE


local cl_command_queue_verify = ffi.C.rand()

local allCmds = table{
	ffi.new('struct _cl_command_queue[1]', {{
		verify = cl_command_queue_verify,
	}}),
}
assert(allCmds[1][0].verify == cl_command_queue_verify)

local function queueCastAndVerify(cmds)
	cmds = ffi.cast('struct _cl_command_queue*', cmds)
	if cmds == nil
	or cmds[0].verify ~= cl_command_queue_verify
	or cmds ~= ffi.cast('cl_command_queue', allCmds[1])
	then
		return nil, ffi.C.CL_INVALID_COMMAND_QUEUE
	end
	return cmds
end

function cl.clRetainCommandQueue(cmds) end
function cl.clReleaseCommandQueue(cmds) end

function cl.clCreateCommandQueue(ctx, device, properties, errcodeRet)
	--ctx = ffi.cast('cl_context', ctx)
	--device = ffi.cast('cl_device_id', device)
	properties = ffi.cast('cl_command_queue_properties', properties)

	errcodeRet = ffi.cast('cl_int*', errcodeRet)
	local function returnError(err, ret)
		if errcodeRet ~= nil then errcodeRet[0] = err end
		return ffi.cast('cl_command_queue', ret)
 	end

	local ctx, err = contextCastAndVerify(ctx)
	if err then
		return returnError(err)
	end

	local device, err = deviceCastAndVerify(device)
	if err then
		return returnError(err)
	end

	-- if the values in properties are invalid then return CL_INVALID_VALUE
	-- if the values in properties are valid, but not supported by the device, return CL_INVALID_QUEUE_PROPERTIES

	local cmds = ffi.cast('cl_command_queue', allCmds[1])
	cmds[0].ctx = ctx
	cmds[0].device = device
	cmds[0].properties = properties

	return returnError(ffi.C.CL_SUCCESS, cmds)
end

cl.clGetCommandQueueInfo = makeGetter{
	name = 'clGetCommandQueueInfo',
	infotype = 'cl_command_queue_info',
	idcast = queueCastAndVerify,
	[ffi.C.CL_QUEUE_CONTEXT] = {
		type = 'cl_context',
		get = function(cmds)
			return cmds[0].ctx
		end,
	},
	[ffi.C.CL_QUEUE_DEVICE] = {
		type = 'cl_device_id',
		get = function(cmds)
			return cmds[0].device
		end,
	},
	-- ffi.C.CL_QUEUE_REFERENCE_COUNT = cl_uint
	[ffi.C.CL_QUEUE_PROPERTIES] = {
		type = 'cl_command_queue_properties',
		get = function(cmds)
			return cmds[0].properties
		end,
	},
	-- 2.0
	[ffi.C.CL_QUEUE_SIZE] = {
		type = 'cl_uint',
		value = 0,	-- always execute immediately such that all queues always are empty
	},
	-- 2.1
	-- return the default command queue for the underlying device (the device of the command queue?)
	[ffi.C.CL_QUEUE_DEVICE_DEFAULT] = {
		type = 'cl_command_queue',
		get = function(cmds)
			return cmds
		end,
	},
}

local handleEvents

function cl.clEnqueueWriteBuffer(cmds, buffer, block, offset, size, ptr, numWaitListEvents, waitListEvents, event)
--print(debug.traceback())
	--cmds = ffi.cast('cl_command_queue', cmds)
	--buffer = ffi.cast('cl_mem', buffer)
	block = ffi.cast('cl_bool', block)
	offset = ffi.cast('size_t', offset)
	size = ffi.cast('size_t', size)
	ptr = ffi.cast('void*', ptr)
	numWaitListEvents = ffi.cast('cl_uint', numWaitListEvents)
	waitListEvents = ffi.cast('cl_event*', waitListEvents)
	event = ffi.cast('cl_event*', event)
--print('clEnqueueWriteBuffer', cmds, buffer, block, offset, size, ptr, numWaitListEvents, waitListEvents, event)

	local cmds, err = queueCastAndVerify(cmds)
	if err then return err end

	if numWaitListEvents > 0 and waitListEvents == nil then
		return ffi.C.CL_INVALID_EVENT_WAIT_LIST
	end
	handleEvents(numWaitListEvents, waitListEvents, event)

	if ptr == nil then
		return ffi.C.CL_INVALID_VALUE
	end

	local buffer, err = memCastAndVerify(buffer)
	if err then return err end

	if buffer[0].ptr == nil then
		return ffi.C.CL_INVALID_MEM_OBJECT
	end

	if offset + size > buffer[0].size then
		return ffi.C.CL_INVALID_VALUE
	end

	ffi.copy(buffer[0].ptr + offset, ptr, size)

	return ffi.C.CL_SUCCESS
end

function cl.clEnqueueReadBuffer(cmds, buffer, block, offset, size, ptr, numWaitListEvents, waitListEvents, event)
--print(debug.traceback())
	--cmds = ffi.cast('cl_command_queue', cmds)
	--buffer = ffi.cast('cl_mem', buffer)
	block = ffi.cast('cl_bool', block)
	offset = ffi.cast('size_t', offset)
	size = ffi.cast('size_t', size)
	ptr = ffi.cast('void*', ptr)
	numWaitListEvents = ffi.cast('cl_uint', numWaitListEvents)
	waitListEvents = ffi.cast('cl_event*', waitListEvents)
	event = ffi.cast('cl_event*', event)
--print('clEnqueueReadBuffer', cmds, buffer, block, offset, size, ptr, numWaitListEvents, waitListEvents, event)

	local cmds, err = queueCastAndVerify(cmds)
	if err then return err end

	if numWaitListEvents > 0 and waitListEvents == nil then
		return ffi.C.CL_INVALID_EVENT_WAIT_LIST
	end
	handleEvents(numWaitListEvents, waitListEvents, event)

	if ptr == nil then
		return ffi.C.CL_INVALID_VALUE
	end

	local buffer, err = memCastAndVerify(buffer)
	if err then return err end

	if buffer[0].ptr == nil then
		return ffi.C.CL_INVALID_MEM_OBJECT
	end

	if offset + size > buffer[0].size then
		return ffi.C.CL_INVALID_VALUE
	end

	ffi.copy(ptr, buffer[0].ptr + offset, size)

	return ffi.C.CL_SUCCESS
end

local int0 = ffi.new('int[1]', 0)
function cl.clEnqueueFillBuffer(cmds, buffer, pattern, patternSize, offset, size, numWaitListEvents, waitListEvents, event)
--print(debug.traceback())
	--cmds = ffi.cast('cl_command_queue', cmds)
	--buffer = ffi.cast('cl_mem', buffer)
	pattern = ffi.cast('uint8_t*', pattern)	-- signature says void* but it will end up uint8_t eventually
	patternSize = ffi.cast('size_t', patternSize)
	offset = ffi.cast('size_t', offset)
	size = ffi.cast('size_t', size)
	numWaitListEvents = ffi.cast('cl_uint', numWaitListEvents)
	waitListEvents = ffi.cast('cl_event*', waitListEvents)
	event = ffi.cast('cl_event*', event)
--print('clEnqueueFillBuffer', cmds, buffer, pattern, patternSize, offset, size, numWaitListEvents, waitListEvents, event)
--print('buffer size', buffer[0].size)
--print('buffer ptr', buffer[0].ptr)
--print('ffi sizeof buffer ptr', ffi.sizeof(buffer[0].ptr))

	local cmds, err = queueCastAndVerify(cmds)
	if err then return err end

	if numWaitListEvents > 0 and waitListEvents == nil then
		return ffi.C.CL_INVALID_EVENT_WAIT_LIST
	end
	handleEvents(numWaitListEvents, waitListEvents, event)

	local buffer, err = memCastAndVerifyAndAssertNotNull(buffer)
	if err then return err end

	if pattern == nil then
		return ffi.C.CL_INVALID_VALUE
	end

	if patternSize ~= 1
	and patternSize ~= 2
	and patternSize ~= 4
	and patternSize ~= 8
	and patternSize ~= 16
	and patternSize ~= 32
	and patternSize ~= 64
	and patternSize ~= 128
	then
		return ffi.C.CL_INVALID_VALUE
	end
	patternSize = tonumber(patternSize)

	if size % patternSize ~= 0 then
		return ffi.C.CL_INVALID_VALUE
	end

	if offset + size > buffer[0].size then
		return ffi.C.CL_INVALID_VALUE
	end

	local isZero = true
	for i=0,patternSize-1 do
		if pattern[i] ~= 0 then
			isZero = false
			break
		end
	end
	if isZero then
--print(debug.traceback())
		ffi.fill(buffer[0].ptr + offset, size)
--print(debug.traceback())
	else
--print(debug.traceback())
		local i = ffi.cast('size_t', 0)
		while i < size do
			buffer[0].ptr[offset+i] = pattern[i%patternSize]
			i = i + 1
		end
--print(debug.traceback())
	end

	return ffi.C.CL_SUCCESS
end

function cl.clEnqueueCopyBuffer(
	cmds,	-- cl_command_queue
	src_buffer,	-- cl_mem
	dst_buffer,	-- cl_mem
	src_offset,	-- size_t
	dst_offset,	-- size_t
	size,	-- size_t
	numWaitListEvents,	-- cl_uint
	waitListEvents,	-- const cl_event *
	event	-- cl_event *
)
	src_buffer = ffi.cast('uint8_t*', src_buffer)
	dst_buffer = ffi.cast('uint8_t*', dst_buffer)
	src_offset = ffi.cast('size_t', src_offset)
	dst_offset = ffi.cast('size_t', dst_offset)
	size = ffi.cast('size_t', size)
	numWaitListEvents = ffi.cast('cl_uint', numWaitListEvents)
	waitListEvents = ffi.cast('cl_event*', waitListEvents)
	event = ffi.cast('cl_event*', event)

	local cmds, err = queueCastAndVerify(cmds)
	if err then return err end

	if numWaitListEvents > 0 and waitListEvents == nil then
		return ffi.C.CL_INVALID_EVENT_WAIT_LIST
	end
	handleEvents(numWaitListEvents, waitListEvents, event)

	local src_buffer, err = memCastAndVerifyAndAssertNotNull(src_buffer)
	if err then return err end

	local dst_buffer, err = memCastAndVerifyAndAssertNotNull(dst_buffer)
	if err then return err end

	if src_offset + size > src_buffer[0].size then
		return ffi.C.CL_INVALID_VALUE
	end

	if dst_offset + size > dst_buffer[0].size then
		return ffi.C.CL_INVALID_VALUE
	end

	if src_buffer == dst_buffer
	and src_offset + size > dst_offset	-- src max > dst min
	and src_offset < dst_offset + size	-- src min < dst max
	then
		return ffi.C.CL_MEM_COPY_OVERLAP
	end

	ffi.copy(dst_buffer[0].ptr + dst_offset, src_buffer[0].ptr + src_offset, size)

	-- CL_MEM_OBJECT_ALLOCATION_FAILURE if there's failure to allocate memory associated with src_buffer or dst_buffer (not needed in only-CPU version?)
	-- CL_OUT_OF_HOST_MEMORY if the OpenCL host fails to allocate (same?)

	return ffi.C.CL_SUCCESS
end


-- KERNEL helper

local clKernelWorkGroupSize = 1

local cl_kernel_verify = ffi.C.rand()

local kernelsForID = table()

local ffi_setter_for_ctype = {}

local function kernelCastAndVerify(kernelHandle)
	kernelHandle = ffi.cast('struct _cl_kernel*', kernelHandle)
	if kernelHandle == nil
	or kernelHandle[0].verify ~= cl_kernel_verify
	or not kernelsForID[kernelHandle[0].id]
	or kernelHandle ~= ffi.cast('cl_kernel', kernelsForID[kernelHandle[0].id].handle)
	then
		return nil, ffi.C.CL_INVALID_KERNEL
	end
	return kernelHandle
end

-- from my lua-preproc project ...
local function removeCommentsAndApplyContinuations(code)

	-- should line continuations \ affect single-line comments?
	-- if so then do this here
	-- or should they not?  then do this after.
	repeat
		local i, j = code:find('\\\n')
		if not i then break end
		code = code:sub(1,i-1)..' '..code:sub(j+1)
	until false

	-- remove all /* */ blocks first
	repeat
		local i = code:find('/*',1,true)
		if not i then break end
		local j = code:find('*/',i+2,true)
		if not j then
			error("found /* with no */")
		end
		code = code:sub(1,i-1)..code:sub(j+2)
	until false

	-- [[ remove all // \n blocks first
	repeat
		local i = code:find('//',1,true)
		if not i then break end
		local j = code:find('\n',i+2,true) or #code
		code = code:sub(1,i-1)..code:sub(j)
	until false
	--]]

	return code
end

-- run this on program when it has .code to build an initial map of kernels
local function findProgramKernelsFromCode(program)
	-- now that we've compiled it, search the code for kernels...

	local code = removeCommentsAndApplyContinuations(assert(program.code, "expected to find program.code"))

	-- try to find all kernels in the code ...
	for kernelName, sigargs in code:gmatch('kernel%s+void%s+([a-zA-Z_][a-zA-Z0-9_]*)%s*%(([^)]*)%)') do
--print("found kernel", kernelName, "with signature", sigargs)

		-- split by comma and parse each arg separately
		-- let's hope there's no macros in there with commas in them
		local argInfos = table()
		sigargs = string.split(sigargs, ','):mapi(function(arg,i)
			local argInfo = {}
			argInfos[i] = argInfo

			arg = string.trim(arg)
			local tokens = string.split(arg, '%s+')
			-- split off any *'s into unique tokens
			-- TODO not just at the end of the word.  that's just my coding style, right?
			-- TODO how about []'s?
			for j=#tokens,1,-1 do
				while tokens[j]:sub(-1) == '*' do
					table.insert(tokens, j+1, '*')
					tokens[j] = tokens[j]:sub(1,-2)
				end

				if tokens[j] == 'global' then
					table.remove(tokens, j)
					argInfo.isGlobal = true
				elseif tokens[j] == 'local' then
					table.remove(tokens, j)
					argInfo.isLocal = true
				elseif tokens[j] == 'constant' then
					table.remove(tokens, j)
					argInfo.isConstant = true
				end
			end

			local varname = tokens:remove()	-- assume the last is the variable name
			argInfo.name = varname

			-- keep track of the type to convert to before calling the kernel
			argInfo.origtype = tokens:concat' '
			-- or not? idk that i need it -- I'll let the kernel code do the casting

			-- remove consts
			tokens = tokens:filter(function(t) return t ~= 'const' end)

			-- ok now when deducing the link signature, there will be lots of struct ptrs - just convert them to void*
			-- so if the 2nd-to-last is a * then replace all type tokens with 'void*'
			if tokens:find'*' then
				tokens = table{'void', '*'}
			end

			-- treat all ptr args as void*'s
			argInfo.type = tokens:concat' '

			tokens:insert(varname)

			return tokens:concat' '
		end)
		local numargs = #sigargs
		assert(#argInfos == numargs)

		sigargs = sigargs:concat', '

		local sig = 'void '..kernelName.. '(' .. sigargs .. ');'

		local kernelHandle = ffi.new'struct _cl_kernel[1]'
		kernelHandle[0].verify = cl_kernel_verify
		kernelHandle[0].id = #kernelsForID+1
		local kernel = {
			name = kernelName,
			program = program,
			sig = sig,					-- use this for ffi.cdef after link
			--func = func,				-- assign this later, after link
			argInfos = argInfos,		-- holds for each arg: name, type, isGlobal, isLocal, isConstant
			args = {},					-- holds the clSetKernelArg() values
			numargs = numargs,
			handle = kernelHandle,		-- hold so luajit doesn't free
			ctx = program.ctx,
		}
		kernelsForID[kernelHandle[0].id] = kernel

		-- TODO what if the kernel was already requested?
		program.kernels[kernelName] = kernel
	end
end

local function bindProgramKernels(program)
	-- do this after link
	for kernelName, kernel in pairs(program.kernels) do
		-- only do this after library loading
	--print("cdef'ing as sig:\n"..sig)
		ffi.cdef(kernel.sig)

		if not xpcall(function()
			kernel.func = program.lib[kernelName]
	--print('func', kernel.func)
		end, function(err)
			print('error while compiling: '..err)
			print(debug.traceback())
		end) then
			-- an error in reading program.lib[kernelName] is most likely absence of the function in the library
			-- TODO how to report these errors?
			error("here")
		end

		-- if we're using C+FFI then setup the CIF here
		if cl.clcpu_kernelCallMethod == 'C-singlethread'
		or cl.clcpu_kernelCallMethod == 'C-multithread'
		then
			local ffi_atypes = ffi.new('ffi_type*[?]', kernel.numargs)
			kernel.ffi_atypes = ffi_atypes

			kernel.ffi_rtype = ffi.new('ffi_type*[1]')
			local lib = assert(program.lib, "couldn't find program.lib")
			lib['ffi_set_void'](kernel.ffi_rtype)	-- kernel always returns void

			kernel.ffi_values = ffi.new('void*[?]', kernel.numargs)
			kernel.ffi_ptrs = ffi.new('void*[?]', kernel.numargs)

			for i=1,kernel.numargs do
				local argInfo = assert(kernel.argInfos[i])
				if argInfo.isGlobal
				or argInfo.isConstant
				then
					lib['ffi_set_pointer'](ffi_atypes+i-1)
				elseif argInfo.isLocal then
					lib['ffi_set_pointer'](ffi_atypes+i-1)
				else
					-- TODO how to detect the type of the arg?
					-- all the CL API cares about is the sizeof
					-- FFI wants to know more details than that
					-- but all I have from the CL code is the CL/C typename
					-- which could be typedef'd
					-- so I have to consult luajit's ffi for more info
					-- TODO better way to do this?
					local k = tostring(ffi.typeof(argInfo.type))

					local settername = ffi_setter_for_ctype[k]
					if not settername then
						-- TODO how to report this error
						error("couldn't find setter for type "..k)
					else
						lib[settername](ffi_atypes+i-1)
					end
				end
			end

			kernel.ffi_cif = ffi.new('ffi_cif[1]')
			if ffi.C.ffi_prep_cif(kernel.ffi_cif, ffi.C.FFI_DEFAULT_ABI, kernel.numargs, kernel.ffi_rtype[0], ffi_atypes) ~= ffi.C.FFI_OK then
				-- TODO how to report this error
				error("failed to prepare the FFI CIF")
			end

			-- hmm, luajit can't pass C function pointers into C function pointer args of functions, so gotta make a closure even though I'm not wrapping a luajit function ...
			kernel.func_closure = ffi.cast('void(*)()', kernel.func)
		end
	end
end




-- PROGRAM

-- hack for forcing cpp format which is found in cl-cpu/run.lua:
cl.useCpp = false
cl.extraInclude = table()
local buildEnv
local ffiSetterLib 	-- info for the lib holding all the ffi_set_ stuff ... which everyone else will have to link to
function cl:getBuildEnv()
	if buildEnv then return buildEnv end

	-- using ffi-c is convenient so long as the compile + link are done together ...
	-- but if I want to separate them, I'll have so do this myself ...
	-- [[
	if self.useCpp then
		-- c++ fails on field initialization
		buildEnv = require 'ffi-c.cpp'
	else
		-- c fails on arith ops for vector types
		buildEnv = require 'ffi-c.c'
	end

	-- don't clean up files upon gc
	-- because this is deleting libraries that i'm trying to debug ...
	function buildEnv:cleanup() end

	-- while we're here, do this once ... and with C only
	ffiSetterLib = require 'ffi-c.c':build(template([[
#include <ffi.h>

// TODO maybe put these in their own library or something?
// they are only used for cl-cpu , so ... how about compiling them into their own .so?
<? for _,f in ipairs(ffi_all_types) do
?>void ffi_set_<?=f[2]?>(ffi_type ** const t) { t[0] = &ffi_type_<?=f[2]?>; }
<? end ?>

]], {
		ffi_all_types = ffi_all_types,
	}))

	ffi.cdef(template([[
typedef struct ffi_type;
<? for _,f in ipairs(ffi_all_types) do ?>
void ffi_set_<?=f[2]?>(ffi_type ** const);
<? end ?>
]], {
		ffi_all_types = ffi_all_types,
	}))

	for _,f in ipairs(ffi_all_types) do
		local k = tostring(ffi.typeof(f[1]))
		ffi_setter_for_ctype[k] = 'ffi_set_'..f[2]
	end

	return buildEnv
end

--]]
--[[ so this is a more flexible version ...
-- maybe this should replace ffi-c ?
-- or maybe it'll end up too cl-specifc?
local Program = class()

local MakeEnv = require 'make.env'
function Program:init()
	self.env = MakeEnv()
end

function Program:build(code)
	return {
		error = nil,
		libfile = nil,
		compileLog = nil,
		linkLog = nil,
	}
end

function Program:link(code)
end
--]]

local cl_program_verify = ffi.C.rand()

-- global
-- lua table
-- 1-based
-- ... should make this context-based, but right now all the ctx stuff is c-structs ...
local programsForID = table()

local function programCastAndVerify(programHandle)
--print(debug.traceback())
	programHandle = ffi.cast('struct _cl_program*', programHandle)
--print(debug.traceback())
	if programHandle == nil then
--print(debug.traceback())
		return nil, ffi.C.CL_INVALID_PROGRAM
	end
--print(debug.traceback())
--print(programHandle)
--print(programHandle[0])
	if programHandle[0].verify ~= cl_program_verify then
--print(debug.traceback())
		return nil, ffi.C.CL_INVALID_PROGRAM
	end
--print(debug.traceback())
	local program = programsForID[programHandle[0].id]
--print(debug.traceback())
	if not program then
--print(debug.traceback())
		return nil, ffi.C.CL_INVALID_PROGRAM
	end
--print(debug.traceback())
	if not program.handle then
--print(debug.traceback())
		return nil, ffi.C.CL_INVALID_PROGRAM
	end
--print(debug.traceback())
	if programHandle ~= ffi.cast('cl_program', program.handle) then
		-- TODO or maybe an error for internal integrity check?
--print(debug.traceback())
		return nil, ffi.C.CL_INVALID_PROGRAM
	end
--print(debug.traceback())
	return programHandle
end

function cl.clRetainProgram(programHandle) end
function cl.clReleaseProgram(programHandle) end

local function getKernelName(program)
	--[[ using nm on the .so
	local cmd = table{
		'nm -D -f just-symbols',
		path(program.libfile):escape(),
	}:concat' '
print('>> '..cmd)
	local out = io.readproc(cmd)
print(out)
	return string.split(string.trim(out), '\n')
	--]]
	-- [[ using the kernels
	return table.keys(program.kernels):sort()
	--]]
end

cl.clGetProgramInfo = makeGetter{
	name = 'clGetProgramInfo',
	infotype = 'cl_program_info',
	idcast = programCastAndVerify,
	--[ffi.C.CL_PROGRAM_REFERENCE_COUNT] = { type = 'cl_uint'},
	[ffi.C.CL_PROGRAM_CONTEXT] = {
		type = 'cl_context',
		get = function(programHandle)
			local program = assert(programsForID[programHandle[0].id])
			return program.ctx
		end,
	},
	[ffi.C.CL_PROGRAM_NUM_DEVICES] = {
		type = 'cl_uint',
		get = function(programHandle)
			local program = assert(programsForID[programHandle[0].id])
			return program.numDevices
		end,
	},
	[ffi.C.CL_PROGRAM_DEVICES] = {
		type = 'cl_device_id[]',
		getArray = function(paramSize, resultPtr, sizePtr, programHandle)
			local program = assert(programsForID[programHandle[0].id])
			if sizePtr ~= nil then
				sizePtr[0] = ffi.sizeof'cl_device_id' * program.numDevices
			end
			if resultPtr ~= nil then
				if paramSize < ffi.sizeof'cl_device_id' * program.numDevices then return ffi.C.CL_INVALID_VALUE end
				for i=0,program.numDevices-1 do
					resultPtr[i] = program.devices[i]
				end
			end
		end,
	},
	[ffi.C.CL_PROGRAM_SOURCE] = {
		type = 'char[]',
		getString = function(programHandle)
			local program = assert(programsForID[programHandle[0].id])
			-- The source string returned is a concatenation of all source strings specified to clCreateProgramWithSource with a null terminator. The concatenation strips any nulls in the original source strings.
			-- The actual number of characters that represents the program source code including the null terminator is returned in param_value_size_ret.
			-- so you are supposed to strip nulls,
			-- but include the nulls in the size?
			-- Weird.
			return program.code
		end,
	},
	[ffi.C.CL_PROGRAM_BINARY_SIZES] = {
		type = 'size_t',	-- TODO this is really a size_t[]
		get = function(programHandle)
			local program = assert(programsForID[programHandle[0].id])
			return #program.libdata
		end,
	},
	[ffi.C.CL_PROGRAM_BINARIES] = {
		type = 'char[]',	-- ... and this is a unsigned char*[] ... so who allocates the multiple char*'s?
		getString = function(programHandle)
			local program = assert(programsForID[programHandle[0].id])
			return program.libdata
		end,
	},
	-- 1.2:
	[ffi.C.CL_PROGRAM_NUM_KERNELS] = {
		type = 'size_t',
		get = function(programHandle)
			local programID = programHandle[0].id
			local program = assert(programsForID[programID])
			assert(program.libfile, "couldn't find a lib for this program")
			local symbols = getKernelName(program)
			return #symbols
		end,
	},
	[ffi.C.CL_PROGRAM_KERNEL_NAMES] = {
		type = 'char[]',
		getString = function(programHandle)
			local programID = programHandle[0].id
			local program = assert(programsForID[programID])
			assert(program.libfile, "couldn't find a lib for this program")
			local symbols = getKernelName(program)
			return symbols:concat';'
		end,
	},
	-- 2.1:
	--[ffi.C.CL_PROGRAM_IL] = char[]
	-- 2.2:
	--[ffi.C.CL_PROGRAM_SCOPE_GLOBAL_CTORS_PRESENT] = cl_bool,
	--[ffi.C.CL_PROGRAM_SCOPE_GLOBAL_DTORS_PRESENT] = cl_bool,
}

function cl.clGetProgramBuildInfo(programHandle, device, name, paramSize, resultPtr, sizePtr)
	local device, err = deviceCastAndVerify(device)
	if err then return err end
	return handleGetter({
		name = 'clGetProgramBuildInfo',
		infotype = 'cl_program_build_info',
		idcast = programCastAndVerify,
		[ffi.C.CL_PROGRAM_BUILD_STATUS] = {
			type = 'cl_build_status',
			get = function(programHandle, device)
				local program = assert(programsForID[programHandle[0].id])
				return program.status
			end,
		},
		[ffi.C.CL_PROGRAM_BUILD_OPTIONS] = {
			type = 'char[]',
			getString = function(programHandle, device)
				local program = assert(programsForID[programHandle[0].id])
				return program.options
			end,
		},
		[ffi.C.CL_PROGRAM_BUILD_LOG] = {
			type = 'char[]',
			getString = function(programHandle, device)
				local program = assert(programsForID[programHandle[0].id])
				local log = table()
				log:insert(program.compileLog or '')
				log:insert(program.linkLog or '')
				return log:concat'\n'
			end,
		},
		-- 1.2:
		--[ffi.C.CL_PROGRAM_BINARY_TYPE] = cl_program_binary_type
		-- one of:
		-- CL_PROGRAM_BINARY_TYPE_NONE
		-- CL_PROGRAM_BINARY_TYPE_COMPILED_OBJECT
		-- CL_PROGRAM_BINARY_TYPE_LIBRARY
		-- CL_PROGRAM_BINARY_TYPE_EXECUTABLE
		-- 2.0:
		--[ffi.C.CL_PROGRAM_BUILD_GLOBAL_VARIABLE_TOTAL_SIZE] = size_t
	}, programHandle, name, paramSize, resultPtr, sizePtr, device)
end

function cl.clCreateProgramWithSource(ctx, numStrings, stringsPtr, lengthsPtr, errcodeRet)
	--ctx = ffi.cast('cl_context', ctx)
	numStrings = ffi.cast('cl_uint', numStrings)
	stringsPtr = ffi.cast('char**', stringsPtr)
	lengthsPtr = ffi.cast('size_t*', lengthsPtr)

	errcodeRet = ffi.cast('cl_int*', errcodeRet)
	local function returnError(err, ret)
		if errcodeRet ~= nil then errcodeRet[0] = err end
		return ffi.cast('cl_program', ret)
 	end

	local ctx, err = contextCastAndVerify(ctx)
	if err then
		return returnError(err)
	end

	-- I'm creating the program entry up front
	-- so there can be dead programs in the table
	-- but the tradeoff is that I can also now use the program unique ID in the program's code gen
	local programHandle = ffi.new'struct _cl_program[1]'
	local id = #programsForID+1
	programHandle[0].verify = cl_program_verify
	programHandle[0].id = id
--print('adding program entry', id)

	local vectorTypes = {'char', 'uchar', 'short', 'ushort', 'int', 'uint', 'long', 'ulong', 'float', 'double'}
	local srcfn = cl.pathToCLCPU..'/exec-single.c'
	local code = table{
		template(assert(path(srcfn):read()), {
			id = id,
			vectorTypes = vectorTypes,
			kernelCallMethod = cl.clcpu_kernelCallMethod,
			numcores = numcores,
			cl = cl,
			clDeviceMaxWorkItemDimension = clDeviceMaxWorkItemDimension,
		}),
	}
	for i=0,tonumber(numStrings)-1 do
		code:insert(ffi.string(stringsPtr[i], lengthsPtr[i]))
	end
	code = code:concat'\n'

	-- hmm, typedef with a cl vector type, which uses constructor syntax not supported by C...
	local realtype = code:match'typedef%s+(%S*)%s+real;'
	for _,n in ipairs{2,4} do
		if realtype then
--print('replacing realtype '..realtype)
			code = code:gsub('%(real'..n..'%)', '('..realtype..n..')')
		end

		if cl.useCpp then	-- convert .cl to .cpp
			for _,base in ipairs(vectorTypes) do
				code = code:gsub('%('..base..n..'%)%(', base..n..'(')
			end
		else	-- convert .cl to .c
			for _,base in ipairs(vectorTypes) do
				code = code:gsub('%('..base..n..'%)%(', '_'..base..n..'(')
			end

			-- hmm, opencl allows for (type#)(...) initializers for vectors
			-- how to convert this to C ?

			-- opencl also overloads arithmetic operators ...
			code = code:gsub('i %+= _int'..n..'%(([^)]*)%)', function(inside)
				return 'i = int'..n..'_add(i,_int'..n..'('..inside..'))'
			end)
		end
	end

	-- replace #pragma OPENCL with comments
	code = string.split(code, '\n'):mapi(function(l)
		if l:lower():match'^#%s*pragma%s+opencl' then
			return '// '..l
		else
			return l
		end
	end):concat'\n'

	local program = {
		id = id,
		handle = programHandle,
		code = code,
		ctx = ctx,
		status = ffi.C.CL_BUILD_NONE,
		kernels = {},		-- key = kernel name, value = kernelsForID object
	}
	programsForID[id] = program

	return returnError(ffi.C.CL_SUCCESS, programHandle)
end


function cl.clCreateProgramWithBinary(ctx, numDevices, devices, lengths, binaries, binaryStatus, errcodeRets)
	-- TODO an easy implementation would be to just return a string for the binary
	-- but it gets more difficult if you want to support programs as binary-obj, binary-lib, binary-exe ... then you should also keep track of which one the clprogram is ...
	error("not yet implemented")
end

cl.clcpu_build = 'release'

local function setupCLProgramHeader(id)
	local headerCode
	local result, msg = xpcall(function()
		headerCode = template([[

//everything accessible everywhere goes here
typedef struct cl_globalinfo_t_<?=id?> {
	uint work_dim;
	size_t global_size[<?=clDeviceMaxWorkItemDimension?>];
	size_t local_size[<?=clDeviceMaxWorkItemDimension?>];
	size_t num_groups[<?=clDeviceMaxWorkItemDimension?>];
	size_t global_work_offset[<?=clDeviceMaxWorkItemDimension?>];
} cl_globalinfo_t_<?=id?>;
cl_globalinfo_t_<?=id?> _program_<?=id?>_globalinfo;


// everything in the following need to know which core you're on:
typedef struct cl_threadinfo_t_<?=id?> {
	size_t global_linear_id;
	size_t local_linear_id;
	size_t global_id[<?=clDeviceMaxWorkItemDimension?>];
	size_t local_id[<?=clDeviceMaxWorkItemDimension?>];
	size_t group_id[<?=clDeviceMaxWorkItemDimension?>];
} cl_threadinfo_t_<?=id?>;
cl_threadinfo_t_<?=id?> _program_<?=id?>_threadinfo[<?=numcores?>];



<?
if kernelCallMethod == 'C-singlethread'
or kernelCallMethod == 'C-multithread'
then
?>

typedef struct ffi_cif;

void _program_<?=id?>_execSingleThread(
	ffi_cif * cif,
	void (*func)(),
	void ** values
);

<? if kernelCallMethod == 'C-multithread' then ?>

void _program_<?=id?>_execMultiThread(
	ffi_cif * cif,
	void (*func)(),
	void ** values
);

<? end ?>
<? end ?>

]], 	{
			id = id,
			kernelCallMethod = cl.clcpu_kernelCallMethod,
			numcores = numcores,
			clDeviceMaxWorkItemDimension = clDeviceMaxWorkItemDimension,
		})
		ffi.cdef(headerCode)
	end, function(err)
		return err..'\n'
			..'header code:\n'
			..require 'template.showcode'(tostring(headerCode))..'\n'
			..debug.traceback()
	end)
	-- rethrow ...
	if not result then error(msg) end
end

-- just source -> obj
--cl_int clCompileProgram(cl_program program, cl_uint num_devices, const cl_device_id * device_list, const char * options, cl_uint num_input_headers, const cl_program * input_headers, const char ** header_include_names, void ( * pfn_notify)(cl_program program, void * user_data), void * user_data);
function cl.clCompileProgram(programHandle, numDevices, devices, options, numInputHeaders, inputHeaders, headerIncludeNames, notify, userData)
	-- in order to split the clBuildProgram up into compile + link, that means splitting up the ffi-c :build process into separate compile + link ...
	-- I could do that ... or I could just pull the contents out of it (which relies on lua-make) , and just use that, and separate that into compile + link

	-- [[ BEGIN matches clBuildProgram

	local err
	err, numDevices, devices = prepareArgsDevices(numDevices, devices)
	if err ~= ffi.C.CL_SUCCESS then return err end
	-- TODO if device is still building a program then return CL_INVALID_OPERATION

	options = ffi.cast('char*', options)
	if options ~= nil then
		options = ffi.string(options)
	else
		options = nil
	end
	-- TODO if any options are invalid then return CL_INVALID_BUILD_OPTIONS

	if notify == nil and userData ~= nil then
		return ffi.C.CL_INVALID_VALUE
	end

	local programHandle, err = programCastAndVerify(programHandle)
	if err then return err end

	local err = ffi.C.CL_SUCCESS
	local id = programHandle[0].id
--print('compiling program entry', id)
	local program = programsForID[id]

	-- if there are kernels attached to the program...
	if next(program.kernels) ~= nil then
		return ffi.C.CL_INVALID_OPERATION
	end

	--]] END matches clBuildProgram

	-- clear results of a previous build?
	program.lib = nil
	program.libfile = nil
	program.libdata = nil
	program.compileLog = nil
	program.linkLog = nil
	program.numDevices = nil
	program.devices = nil
	program.status = ffi.C.CL_BUILD_IN_PROGRESS
	program.options = nil
	program.kernel = {}

	xpcall(function()
		local buildCtx = {}
		buildCtx.currentProgramID = program.id	-- used by buildEnv:link
		buildCtx.include = cl.extraInclude
		buildCtx.cppver = cl.useCpp and 'c++20' or nil
		-- this does ...
		-- :setup - makes the make env obj & writes code
		-- :compile - code -> .o file
		-- :link - .o file -> .so file
		-- :load - loads the .so file
		-- so if we split this up into clBuild and clLink, we will have to track the context file between these calls
		local args = {
			code = assert(program.code, "couldn't find program.code"),
			build = cl.clcpu_build,	-- debug vs release, corresponding compiler flags are in lua-make
		}
		local buildEnv = cl:getBuildEnv()
		buildEnv:setup(args, buildCtx)
		if buildCtx.error then error(buildCtx.error) end
		buildEnv:compile(args, buildCtx)
		if buildCtx.error then error(buildCtx.error) end
--print('done compiling program entry', id)

		-- save for later for when clLinkProgram is called
		program.buildArgs = args
		program.buildCtx = buildCtx

		findProgramKernelsFromCode(program)
	end, function(err)
		-- this is still in the temp file so ...
		--io.stderr:write('code:', '\n')
		--io.stderr:write(require 'template.showcode'(tostring(program.code)), '\n')
		io.stderr:write('error while compiling: '..tostring(err), '\n')
		io.stderr:write(debug.traceback(), '\n')
		io.stderr:flush()
		err = ffi.C.CL_BUILD_PROGRAM_FAILURE
		program.status = ffi.C.CL_BUILD_ERROR
	end)
	return err
end

-- just obj -> exe
--cl_program clLinkProgram(cl_context context, cl_uint num_devices, const cl_device_id * device_list, const char * options, cl_uint num_input_programs, const cl_program * input_programs, void ( * pfn_notify)(cl_program program, void * user_data), void * user_data, cl_int * errcode_ret);
function cl.clLinkProgram(ctx, numDevices, devices, options, numInputPrograms, inputProgramHandles, notify, userData, errcodeRet)
	errcodeRet = ffi.cast('cl_int*', errcodeRet)
	local function returnError(err, ret)
		if errcodeRet ~= nil then errcodeRet[0] = err end
		return ffi.cast('cl_program', ret)
 	end

	local ctx, err = contextCastAndVerify(ctx)
	if err then
		return returnError(err)
	end

	-- [[ BEGIN matches clBuildProgram

	local err
	err, numDevices, devices = prepareArgsDevices(numDevices, devices)
	if err ~= ffi.C.CL_SUCCESS then
--print("prepareArgsDevices failed")
		return returnError(err)
	end
	-- TODO if device is still building a program then return CL_INVALID_OPERATION

	options = ffi.cast('char*', options)
	if options ~= nil then
		options = ffi.string(options)
	else
		options = nil
	end
	-- TODO if any options are invalid then return CL_INVALID_BUILD_OPTIONS

	if notify == nil and userData ~= nil then
--print("notify was nil but userData wasn't nil ... CL_INVALID_VALUE")
		return returnError(ffi.C.CL_INVALID_VALUE)
	end

	-- ]] END matches clBuildProgram

	-- numInputPrograms, inputProgramHandles
	numInputPrograms = ffi.cast('cl_uint', numInputPrograms)
	numInputPrograms = tonumber(numInputPrograms)
	inputProgramHandles = ffi.cast('cl_program*', inputProgramHandles)
	if (inputProgramHandles == nil and numInputPrograms > 0)
	or (inputProgramHandles ~= nil and numInputPrograms == 0)
	then
--print("numInputPrograms vs inputProgramHandles disagreed ... CL_INVALID_VALUE")
		return returnError(ffi.C.CL_INVALID_VALUE)
	end

	local programs = table()
	for i=0,numInputPrograms-1 do
		local programHandle, err = programCastAndVerify(inputProgramHandles[i])
		if err then
--print("programCastAndVerify on inputProgramHandles["..i.."] failed")
			return returnError(err)
		end
		local id = programHandle[0].id
		local program = programsForID[id]
		-- if the program wasn't called with clCompileProgram , or if that failed or something meh idk
		if not program.buildCtx then
print("tried to link program but source program "..tostring(program.srcfile).." has no buildCtx")
			return returnError(ffi.C.CL_INVALID_OPERATION)
		end
		-- TODO what about if the program succeeded as a .lib?
		programs:insert(program)
	end

	-- our new program ...
	local programHandle = ffi.new'struct _cl_program[1]'
	local id = #programsForID+1
	programHandle[0].verify = cl_program_verify
	programHandle[0].id = id
	local program = {
		id = id,
		handle = programHandle,
		-- no code
		ctx = ctx,
		status = ffi.C.CL_BUILD_NONE,
		kernels = {},
	}
	programsForID[id] = program

	-- clear results of previous build?
	program.lib = nil
	program.libfile = nil
	program.libdata = nil
	program.compileLog = nil
	program.linkLog = nil
	program.numDevices = nil
	program.devices = nil
	program.status = ffi.C.CL_BUILD_IN_PROGRESS
	program.options = nil

	local err = ffi.C.CL_SUCCESS

	local headerCode
	xpcall(function()
		local buildEnv = cl:getBuildEnv()
		local buildCtx = {}
		local args = {}
		buildEnv:setup(args, buildCtx)
		if buildCtx.error then error(buildCtx.error) end
		-- ... don't compile ...
		function buildEnv:addExtraObjFiles(objfiles)
			for i=#objfiles,1,-1 do objfiles[i] = nil end
			objfiles:insert((assert(ffiSetterLib.objfile)))
			objfiles:append(programs:mapi(function(srcProgram)
				return (assert(srcProgram.buildCtx.objfile))
			end))
		end
		buildEnv:link(args, buildCtx)
		if buildCtx.error then error(buildCtx.error) end
		buildEnv:load(args, buildCtx)
		if buildCtx.error then error(buildCtx.error) end

		-- TODO here, how to build from other builds ...
		-- by skipping the code / :compile part, and by overriding the :addExtraObjFiles part

		setupCLProgramHeader(id)
		local libdata = assert(path(buildCtx.libfile):read(), "couldn't open file "..buildCtx.libfile)

		local kernels = {}
		-- is this safe?
		-- will there be collisions? I suppose not if there have already been compiler link collisions.
		-- will something get written later?  hmm...
		-- now I have to copy the kernels and give them unique programs ...
		for _,srcProgram in ipairs(programs) do
			for kernelName,srcKernel in pairs(srcProgram.kernels) do
				local kernelHandle = ffi.new'struct _cl_kernel[1]'
				kernelHandle[0].verify = cl_kernel_verify
				kernelHandle[0].id = #kernelsForID+1
				local kernel = {
					name = kernelName,
					program = program,	-- use the new program
					sig = srcKernel.sig,
					func = srcKernel.func,	-- is this assigned yet?  I think not until bindProgramKernels ...
					argInfos = table(srcKernel.argInfos),	-- read-only?  deep copy? idk?
					args = {},	-- srcKernel.args,	-- holds clSetKernelArg() stuff, so might as well empty it ...
					numargs = srcKernel.numargs,
					handle = kernelHandle,	-- handle has to be new
					ctx = program.ctx,
				}
				kernelsForID[kernelHandle[0].id] = kernel
				kernels[kernelName] = kernel
			end
		end

		program.lib = assert(buildCtx.lib, "looks like we didn't get the lib...")
		program.libfile = buildCtx.libfile
		program.libdata = libdata
		program.compileLog = buildCtx.compileLog
		program.linkLog = buildCtx.linkLog
		program.numDevices = numDevices
		program.devices = devices
		program.status = ffi.C.CL_BUILD_SUCCESS
		program.options = options
		program.kernels = kernels

		bindProgramKernels(program)
	end, function(err)
		io.stderr:write('error while compiling: '..tostring(err), '\n')
		io.stderr:write(debug.traceback(), '\n')
		io.stderr:flush()
		err = ffi.C.CL_BUILD_PROGRAM_FAILURE
		program.status = ffi.C.CL_BUILD_ERROR
	end)

	return returnError(err, programHandle)
end

-- source -> obj, then obj -> exe
function cl.clBuildProgram(programHandle, numDevices, devices, options, notify, userData)
	--programHandle = ffi.cast('cl_program', programHandle)

	-- [[ BEGIN matches clBuildProgram

	local err
	err, numDevices, devices = prepareArgsDevices(numDevices, devices)
	if err ~= ffi.C.CL_SUCCESS then return err end
	-- TODO if device is still building a program then return CL_INVALID_OPERATION

	options = ffi.cast('char*', options)
	if options ~= nil then
		options = ffi.string(options)
	else
		options = nil
	end
	-- TODO if any options are invalid then return CL_INVALID_BUILD_OPTIONS

	if notify == nil and userData ~= nil then
		return ffi.C.CL_INVALID_VALUE
	end

	local programHandle, err = programCastAndVerify(programHandle)
	if err then return err end

	local err = ffi.C.CL_SUCCESS
	local id = programHandle[0].id
--print('compiling program entry', id)
	local program = programsForID[id]

	-- if there are kernels attached to the program already...
	if next(program.kernels) ~= nil then
		return ffi.C.CL_INVALID_OPERATION
	end

	--]] END matches clBuildProgram

	-- TODO if program was built with binary and devices listed in device_list do not have a valid program binary loaded then return bL_INVALID_BINARY
	-- TODO CL_COMPILER_NOT_AVAILABLE

	-- TODO CL_INVALID_OPERATION if program was not created with clCreateProgramWithSource, clCreateProgramWithIL or clCreateProgramWithBinary

	-- clear results of a previous build?
	program.lib = nil
	program.libfile = nil
	program.libdata = nil
	program.compileLog = nil
	program.linkLog = nil
	program.numDevices = nil
	program.devices = nil
	program.status = ffi.C.CL_BUILD_IN_PROGRESS
	program.options = nil

	xpcall(function()
		local buildEnv = cl:getBuildEnv()

		-- called from buildEnv:link stage
		-- I'm going to change this whether it is clCompileProgram or clBuildProgram or clLinkProgram ...
		function buildEnv:addExtraObjFiles(objfiles, buildCtx)
			if cl.clcpu_kernelCallMethod == 'C-multithread' then

				-- TODO replace buildCtx.srcfile's suffix from self.srcSuffix to _multi .. self.srcSuffix
				local name = self:getBuildDir()..'/'..buildCtx.name..'_multi'

				local pushcompiler = buildCtx.env.compiler
				local pushcppver = buildCtx.env.cppver
				buildCtx.env.compiler = 'g++'

				-- TODO this has to be done before postConfig()
				-- or else it won't get baked into the compileFlags
				-- or I could just move the amend-to-compile-flags into the build itself? like I do macros etc
				buildCtx.env.cppver = 'c++20'
				-- so just do this
				local pushcflags = buildCtx.env.compileFlags
				buildCtx.env.compileFlags = buildCtx.env.compileFlags:gsub('std=c11', 'std=c++20')

				-- I could use templates
				-- I was using templates
				-- but I need to pass the values through into the included file where the cl-cpu structs are
				-- and I can't do that with templates (unless I further inline-and-template)
				-- so instead I'll use macros
				local nmacros = #buildCtx.env.macros
				--buildCtx.env.macros:insert('CLCPU_MAXDIM='..clDeviceMaxWorkItemDimension)
				--buildCtx.env.macros:insert('CLCPU_NUMCORES='..numcores)
				-- on second thought, I can't use macros in the luajit ffi.cdef
				-- so for that i'd have to replace stuff anyways
				-- so meh might as well just use templates

				local srcsrcfile = cl.pathToCLCPU..'/exec-multi.cpp'
				local srcfile = name..'.cpp'
				local objfile = name..buildCtx.env.objSuffix

				-- generate the file from the templated file
				assert(path(srcfile):write(template(assert(path(srcsrcfile):read()), {
					id = buildCtx.currentProgramID,
					numcores = numcores,
					clDeviceMaxWorkItemDimension = clDeviceMaxWorkItemDimension,
				})))

				buildCtx.env.objLogFile = name..'-obj.log'	-- what's this for again?
				local status, compileLog = buildCtx.env:buildObj(objfile, srcfile)
				buildCtx.compileLog = buildCtx.compileLog..compileLog
				if not status then
					buildCtx.error = "failed to build c code"
					error'here'	-- throwing away errors?
					--return buildCtx
				end

				objfiles:insert(objfile)

				buildCtx.env.macros = buildCtx.env.macros:sub(1, nmacros)

				buildCtx.env.compiler = pushcompiler
				buildCtx.env.cppver = pushcppver
				buildCtx.env.compileFlags = pushcflags
			end

			objfiles:insert((assert(ffiSetterLib.objfile)))
		end

		-- this does ...
		-- :setup - makes the make env obj & writes code
		-- :compile - code -> .o file
		-- :link - .o file -> .so file
		-- :load - loads the .so file
		-- so if we split this up into clBuild and clLink, we will have to track the context file between these calls
		local buildCtx = buildEnv:build({
			code = program.code,
			build = cl.clcpu_build,	-- debug vs release, corresponding compiler flags are in lua-make
		}, {
			-- used by buildEnv:link
			currentProgramID = program.id,
			include = cl.extraInclude,
			cppver = cl.useCpp and 'c++20' or nil,
		})
		if buildCtx.error then error(buildCtx.error) end
--print('done compiling program entry', id)

		-- buildEnv:build calls ffi.load
		-- so these should now be available:
		setupCLProgramHeader(id)

		-- assign to locals first so if any errors occur in reading fields, program will still be clean
		local libdata = assert(path(buildCtx.libfile):read(), "couldn't open file "..buildCtx.libfile)

print("clBuildProgram GOT LIB FOR PROGRAM "..buildCtx.srcfile)
		program.lib = assert(buildCtx.lib)
		program.libfile = buildCtx.libfile
		program.libdata = libdata
		program.compileLog = buildCtx.compileLog
		program.linkLog = buildCtx.linkLog
		program.numDevices = numDevices
		program.devices = devices
		program.status = ffi.C.CL_BUILD_SUCCESS
		program.options = options

		-- also now that we've built, we can extract kernels
		findProgramKernelsFromCode(program)
		bindProgramKernels(program)

	end, function(err)
		-- this is still in the temp file so ...
		--io.stderr:write('code:', '\n')
		--io.stderr:write(require 'template.showcode'(tostring(program.code)), '\n')
		io.stderr:write('error while compiling: '..tostring(err), '\n')
		io.stderr:write(debug.traceback(), '\n')
		io.stderr:flush()
		err = ffi.C.CL_BUILD_PROGRAM_FAILURE
		program.status = ffi.C.CL_BUILD_ERROR
	end)
	return err
end


-- KERNEL


function cl.clRetainKernel(kernel) end
function cl.clReleaseKernel(kernel) end

cl.clGetKernelInfo = makeGetter{
	name = 'clGetKernelInfo',
	infotype = 'cl_kernel_info',
	idcast = kernelCastAndVerify,
	[ffi.C.CL_KERNEL_FUNCTION_NAME] = {
		type = 'char[]',
		get = function(kernelHandle)
			local kernel = kernelsForID[kernelHandle[0].id]
			return kernel.name
		end,
	},
	[ffi.C.CL_KERNEL_NUM_ARGS] = {
		type = 'cl_uint',
		get = function(kernelHandle)
			local kernel = kernelsForID[kernelHandle[0].id]
			return kernel.numargs
		end,
	},
	[ffi.C.CL_KERNEL_CONTEXT] = {
		type = 'cl_context',
		get = function(kernelHandle)
			local kernel = kernelsForID[kernelHandle[0].id]
			return kernel.ctx
		end,
	},
	[ffi.C.CL_KERNEL_PROGRAM] = {
		type = 'cl_program',
		get = function(kernelHandle)
			local kernel = kernelsForID[kernelHandle[0].id]
			return kernel.program	-- TODO not program, but programHandle, which is an id to the index of the program ...
		end,
	},
}

function cl.clCreateKernel(programHandle, kernelName, errcodeRet)
--print('clCreateKernel', programHandle, kernelName, errcodeRet)
	errcodeRet = ffi.cast('cl_int*', errcodeRet)
	local function returnError(err, ret)
		if errcodeRet ~= nil then errcodeRet[0] = err end
		return ffi.cast('cl_kernel', ret)
 	end

	kernelName = ffi.cast('char*', kernelName)
	if kernelName == nil then
		return returnError(ffi.C.CL_INVALID_VALUE)
	end
	kernelName = ffi.string(kernelName)

	local programHandle, err = programCastAndVerify(programHandle)
	if err then
		return returnError(err)
	end

	local program = assert(programsForID[programHandle[0].id])
	if program.status ~= ffi.C.CL_BUILD_SUCCESS then
print("program.status is not CL_BUILD_SUCCESS...")
		return returnError(ffi.C.CL_INVALID_PROGRAM_EXECUTABLE)
	end
	if program.lib == nil then
print("program.lib is nil")
		return returnError(ffi.C.CL_INVALID_PROGRAM_EXECUTABLE)
	end

	local kernel = program.kernels[kernelName]
	if not kernel then
		return returnError(ffi.C.CL_INVALID_KERNEL_NAME)
	end
	assert(kernel.program == program, "how did a program end up with another programs kernel?")

	return returnError(ffi.C.CL_SUCCESS, kernel.handle)
end

function cl.clSetKernelArg(kernelHandle, index, size, value)
	--kernelHandle = ffi.cast('cl_kernel', kernelHandle)
	index = ffi.cast('cl_uint', index)
	index = tonumber(index)
	size = ffi.cast('size_t', size)
	value = ffi.cast('void*', value)

	local kernelHandle, err = kernelCastAndVerify(kernelHandle)
	if err then return err end
	local kernel = kernelsForID[kernelHandle[0].id]
	if not kernel then
		return ffi.C.CL_INVALID_KERNEL
	end

	if index >= kernel.numargs then
		return ffi.C.CL_INVALID_ARG_INDEX
	end
	local argInfo = kernel.argInfos[index+1]
	assert(argInfo, "tried to set kernel arg "..index
		.." but arginfo is nil, only has "..#kernel.argInfos
		.." though numargs is "..kernel.numargs)

	-- if the kernel arg isn't local then the value can't be null ...
	if value == nil then
		if not argInfo.isLocal then
			return ffi.C.CL_INVALID_ARG_VALUE
		end
	end

--print('clSetKernelArg', kernelHandle, index, size, value)

	-- if the kernel arg is global then the value better be a cl_mem ...
	if argInfo.isGlobal
	or argInfo.isConstant
	then
		-- clSetKernelArg for globals uses cl_mem[1], which is _cl_mem*[1]
		local verifyvalue = ffi.cast('cl_mem*', value)
		if verifyvalue == nil then
			return ffi.C.CL_INVALID_MEM_OBJECT
		end

		local _, err = memCastAndVerify(verifyvalue[0])
		if err then return err end

		if size ~= ffi.sizeof'cl_mem' then	-- which is a ptr's size ...
			return ffi.C.CL_INVALID_ARG_SIZE
		end
	else
		if size ~= ffi.sizeof(argInfo.type)
		and not argInfo.isLocal -- locals could be pointers to data
		then
			return ffi.C.CL_INVALID_ARG_SIZE
		end
	end

	-- copy the value into the arg - in case the client gets rid of it later
	local copyOfValue = ffi.new('uint8_t[?]', size)
	if value ~= nil then
		ffi.copy(copyOfValue, value, size)
	end

	-- mind you value is a void* by now.
	-- if it's a global then it points to a struct _cl_mem
	kernel.args[index+1] = {ptr=copyOfValue, size=size}

	return ffi.C.CL_SUCCESS
end

function cl.clGetKernelWorkGroupInfo(kernelID, device, name, paramSize, resultPtr, sizePtr)
	return handleGetter({
		name = 'clGetKernelWorkGroupInfo',
		infotype = 'cl_kernel_work_group_info',
		idcast = kernelCastAndVerify,
		[ffi.C.CL_KERNEL_WORK_GROUP_SIZE] = {
			type = 'size_t',
			value = clKernelWorkGroupSize,
		},
	}, kernelID, name, paramSize, resultPtr, sizePtr, device)
end

local defaultGlobalWorkOffset = ffi.new('size_t[?]', clDeviceMaxWorkItemDimension)
local defaultLocalWorkSize = ffi.new('size_t[?]', clDeviceMaxWorkItemDimension)
local defaultGlobalWorkSize = ffi.new('size_t[?]', clDeviceMaxWorkItemDimension)
for i=0,clDeviceMaxWorkItemDimension-1 do
	defaultGlobalWorkOffset[i] = 0
	defaultLocalWorkSize[i] = 1
	defaultGlobalWorkSize[i] = 1
end

function cl.clEnqueueNDRangeKernel(cmds, kernelHandle, workDim, globalWorkOffset, globalWorkSize, localWorkSize, numWaitListEvents, waitListEvents, event)
--print(debug.traceback())
--print('clEnqueueNDRangeKernel', cmds, kernelHandle, workDim, globalWorkOffset, globalWorkSize, localWorkSize, numWaitListEvents, waitListEvents, event)

	--cmds = ffi.cast('cl_command_queue', cmds)
	local cmds, err = queueCastAndVerify(cmds)
	if err then return err end

	--kernelHandle = ffi.cast('cl_kernel', kernelHandle)
	local kernelHandle, err = kernelCastAndVerify(kernelHandle)
	if err then return err end

	local kernel = kernelsForID[kernelHandle[0].id]
	if not kernel then return ffi.C.CL_INVALID_KERNEL end
--print('kernel', kernel.name)

--print('kernel.ctx', kernel.ctx)
--print('cmds[0].ctx', cmds[0].ctx)
	if kernel.ctx ~= cmds[0].ctx then return ffi.C.CL_INVALID_CONTEXT end

	workDim = ffi.cast('cl_uint', workDim)
	workDim = tonumber(workDim)
	if workDim < 1 or workDim > clDeviceMaxWorkItemDimension then return ffi.C.CL_INVALID_WORK_DIMENSION end

	globalWorkOffset = ffi.cast('size_t*', globalWorkOffset)
	if globalWorkOffset == nil then
		globalWorkOffset = ffi.cast('size_t*', defaultGlobalWorkOffset)
	end

	globalWorkSize = ffi.cast('size_t*', globalWorkSize)
	if globalWorkSize == nil then
		globalWorkSize = ffi.cast('size_t*', defaultGlobalWorkSize)
	end
--	for i=0,clDeviceMaxWorkItemDimension-1 do
--		if globalWorkSize[i] + globalWorkOffset[i] > max device work size then return ffi.C.CL_INVALID_GLOBAL_WORK_SIZE end
--	end

	localWorkSize = ffi.cast('size_t*', localWorkSize)
	if localWorkSize == nil then
		localWorkSize = ffi.cast('size_t*', defaultLocalWorkSize)
	end
	-- if the local work group size doesn't match the local size specified in the kernel's source then return ffi.C.CL_INVALID_WORK_GROUP_SIZE end
	-- if the local work group size isn't consistent with the required number of sub-groups for the kernel in the program source then return ffi.C.CL_INVALID_WORK_GROUP_SIZE end
	local totalLocalWorkSize = 1
	for i=0,workDim-1 do
		totalLocalWorkSize = totalLocalWorkSize * localWorkSize[i]
	end
--print('totalLocalWorkSize', totalLocalWorkSize)
--print('clKernelWorkGroupSize', clKernelWorkGroupSize)
--print('clDeviceMaxWorkGroupSize', clDeviceMaxWorkGroupSize)
	if totalLocalWorkSize > clKernelWorkGroupSize then return ffi.C.CL_INVALID_WORK_GROUP_SIZE end
	-- TODO return CL_INVALID_WORK_GROUP_SIZE if the program was compiled with cl-uniform-work-group-size and the number of work-items specified by global_work_size is not evenly divisible by size of work-group given by local_work_size or by the required work-group size specified in the kernel source.
	if totalLocalWorkSize > clDeviceMaxWorkGroupSize then return ffi.C.CL_INVALID_WORK_ITEM_SIZE end
if totalLocalWorkSize == 0 then
	error'here'
end

	numWaitListEvents = ffi.cast('cl_uint', numWaitListEvents)
	waitListEvents = ffi.cast('cl_event*', waitListEvents)
	event = ffi.cast('cl_event*', event)
	if numWaitListEvents > 0 then
		if waitListEvents == nil then
			return ffi.C.CL_INVALID_EVENT_WAIT_LIST
		end
		for i=0,numWaitListEvents-1 do
			-- if cmds.ctx ~= waitListEvents.ctx then return ffi.C.CL_INVALID_CONTEXT end
		end
	end
	handleEvents(numWaitListEvents, waitListEvents, event)

	local program = kernel.program
	if not program then return ffi.C.CL_INVALID_PROGRAM_EXECUTABLE end
--print('program', program.libfile)
--print('program id', program.id)

	local pid = program.id
	local lib = program.lib
	if not lib then
print("tried to enqueue a kernel of program "..tostring(program.buildCtx.srcfile).." which didn't have an associated lib.")
		return ffi.C.CL_INVALID_PROGRAM_EXECUTABLE
	end
	local srcargs = kernel.args
	local argInfos = kernel.argInfos

	-- used with cl.clcpu_kernelCallMethod == 'Lua'
	local dstargs
	if cl.clcpu_kernelCallMethod == 'Lua' then
		dstargs = {}
		for i=1,kernel.numargs do
			local argInfo = assert(argInfos[i])
			local srcarg = srcargs[i]
			if srcarg == nil then		-- arg was not specified
--print("Lua call branch: arg was not specified ...")
				return ffi.C.CL_INVALID_KERNEL_ARGS
			end
			local arg = srcarg.ptr
			local size = srcarg.size
	--print('arg '..i)
	--print('type(arg)', type(arg))
	--print('ffi.typeof(arg)', ffi.typeof(arg))
	--print('argInfo.origtype', argInfo.origtype)
	--print('argInfo.type', argInfo.type)
			assert(type(arg) == 'cdata')
			--assert(tostring(ffi.typeof(arg)) == 'ctype<void *>')	-- if i'm keeping track of the client's ptr
			assert(tostring(ffi.typeof(arg)) == 'ctype<unsigned char [?]>')	-- if i'm saving it in my own buffer

			if argInfo.isGlobal
			or argInfo.isConstant
			then	-- assert we have a cl_mem ... same with local?
	--print'isGlobal or isConstant'
	--print('before cast', arg)
				arg = ffi.cast('cl_mem*', arg)
				if arg == nil then
					error'here'
				end
				local _, err = memCastAndVerify(arg[0])
				if err then
					error'here'
					return err
				end
	--print('after cast, arg', arg)
	--print('after cast, arg[0]', arg[0])
	--print('after cast, arg[0][0]', arg[0][0])
	--print('after cast, arg[0][0].verify', arg[0][0].verify)
				arg = arg[0][0].ptr
			elseif argInfo.isLocal then
	--print'isLocal'
				-- use the pointer as-is
				local localptr = srcarg.localptr
				if not localptr then
					localptr = ffi.new('uint8_t[?]', size)
					srcarg.localptr = localptr
				end
				arg = localptr
			else
	--print'neither local nor global (prim?)'
				arg = ffi.cast(argInfo.type..'*', arg)[0]
			end
	--print('arg value', arg)
			dstargs[i] = arg
		end
	elseif cl.clcpu_kernelCallMethod == 'C-singlethread'
	or cl.clcpu_kernelCallMethod == 'C-multithread'
	then
		-- used with cl.clcpu_kernelCallMethod == 'C-singlethread' or 'C-multithread'
		-- since most often values has to point to a pointer
		-- reset all values before assigning from what the user provided
		-- TODO this could be skipped if value-setting was all done in clSetKernelArg
		for i=0,kernel.numargs-1 do
			kernel.ffi_values[i] = kernel.ffi_ptrs + i
		end

		for i=1,kernel.numargs do
			local argInfo = assert(argInfos[i])
			--print('ARGINFOTYPE', argInfo.type, argInfo.isGlobal, argInfo.isConstant, argInfo.isLocal)
			local srcarg = srcargs[i]
			if srcarg == nil then		-- arg was not specified
--print("C call branch: arg was not specified ...")
				return ffi.C.CL_INVALID_KERNEL_ARGS
			end
			local arg = srcarg.ptr
			local size = srcarg.size
			assert(type(arg) == 'cdata')
			--assert(tostring(ffi.typeof(arg)) == 'ctype<void *>')	-- if i'm keeping track of the client's ptr
			assert(tostring(ffi.typeof(arg)) == 'ctype<unsigned char [?]>')	-- if i'm saving it in my own buffer

			if argInfo.isGlobal
			or argInfo.isConstant
			then
				arg = ffi.cast('cl_mem*', arg)
				if arg == nil then
					error'here'
				end
				local _, err = memCastAndVerify(arg[0])
				if err then
					error'here'
					return err
				end

				-- ffi says this should be a pointer-to-a-pointer
				kernel.ffi_ptrs[i-1] = arg[0][0].ptr
			elseif argInfo.isLocal then
				-- use the pointer as-is
				local localptr = srcarg.localptr
				if not localptr then
					localptr = ffi.new('uint8_t[?]', size)
					srcarg.localptr = localptr
				end
				-- ffi says this should be a pointer-to-a-pointer
				kernel.ffi_ptrs[i-1] = localptr
			else
				-- can't get pointers in luajit, not even to externs, bleh
				-- so I have to wrap that in C code ...
				-- then assign the values[i] to some alloc'd pointer holding it
				kernel.ffi_values[i-1] = arg
			end
		end
	end


--print('calling...')
	local global_work_offset_v = {}
	local global_work_size_v = {}
	local local_work_size_v = {}
	local num_groups_v = {}
	for i=1,workDim do
		global_work_offset_v[i] = tonumber(globalWorkOffset[i-1])
		global_work_size_v[i] = tonumber(globalWorkSize[i-1])
		local_work_size_v[i] = tonumber(localWorkSize[i-1])
		num_groups_v[i] = globalWorkSize[i-1] / localWorkSize[i-1]
		if globalWorkSize[i-1] % localWorkSize[i-1] ~= 0 then
			num_groups_v[i] = num_groups_v[i] + 1
		end
	end
	for i=workDim+1,clDeviceMaxWorkItemDimension do
		global_work_offset_v[i] = 0
		global_work_size_v[i] = 1
		local_work_size_v[i] = 1
		num_groups_v[i] = 1
	end
--print'assigning globals...'
	local globalinfo = lib['_program_'..pid..'_globalinfo']
	globalinfo.work_dim = workDim
	for n=0,clDeviceMaxWorkItemDimension-1 do
		globalinfo.local_size[n] = local_work_size_v[n+1]
		globalinfo.global_size[n] = global_work_size_v[n+1]
		globalinfo.num_groups[n] = num_groups_v[n+1]
		globalinfo.global_work_offset[n] = global_work_offset_v[n+1]
	end
--print'...globals assigning'
	assert(clDeviceMaxWorkItemDimension == 3)	-- TODO generalize the dim of the loop?
	if cl.clcpu_kernelCallMethod == 'Lua' then
		local threadinfo = lib['_program_'..pid..'_threadinfo']

		threadinfo[0].global_linear_id = 0
		local is = {}
		for i=0,global_work_size_v[1]-1 do
			for j=0,global_work_size_v[2]-1 do
				for k=0,global_work_size_v[3]-1 do
--print(i,j,k)
					is[1]=i
					is[2]=j
					is[3]=k
					for n=1,clDeviceMaxWorkItemDimension  do
						threadinfo[0].local_id[n-1] = is[n] % local_work_size_v[n]
						threadinfo[0].group_id[n-1] = is[n] / local_work_size_v[n]
						threadinfo[0].global_id[n-1] = is[n] + globalinfo.global_work_offset[n-1]
					end

					threadinfo[0].local_linear_id =
						is[1] + local_work_size_v[1] * (
							is[2] + local_work_size_v[2] * (
								is[3]
							)
						)

--io.write('('..table.concat(is, ', ')..') ')
					-- TODO don't use real C function args, instead use globals with names associated with the kernel, i.e. <kernel>_arg<i>
					-- and then immediately store them upon clSetKernelArg
					-- but this would mean replacing all functions and their prototypes in the C code with empty-args, and then inserting code in the function beginning to copy from these global vars into the function local vars ...
					kernel.func(table.unpack(dstargs, 1, kernel.numargs))

					threadinfo[0].global_linear_id = threadinfo[0].global_linear_id + 1
				end
			end
		end
	elseif cl.clcpu_kernelCallMethod == 'C-singlethread' then
		lib['_program_'..program.id..'_execSingleThread'](kernel.ffi_cif, kernel.func_closure, kernel.ffi_values)
	elseif cl.clcpu_kernelCallMethod == 'C-multithread' then
		-- multithreaded luajit?  j/k, send to to a C wrapper of std::async
		-- ... but how to forward / pass varargs?
		-- maybe I should be buffering all arg values in clSetKernelArg, and removing the args from the function call in clEnqueueNDRangeKernel
		-- also, if each kernel function call needs a different local_id, group_id, and global_id ...
		-- ... I guess those need to be per-thread variables, so probably need to be replaced with a macro somehow and then stored in arguments of the C function?
		lib['_program_'..program.id..'_execMultiThread'](kernel.ffi_cif, kernel.func_closure, kernel.ffi_values)
		--lib['_program_'..program.id..'_execSingleThread'](kernel.ffi_cif, kernel.func_closure, kernel.ffi_values)
	else
		error("unknown kernelCallMethod "..tostring(cl.clcpu_kernelCallMethod))
	end
--print('clEnqueueNDRangeKernel done')
	return ffi.C.CL_SUCCESS
end

function cl.clFinish() end


-- EVENT

local cl_event_verify = ffi.C.rand()

local allEvents = table()

local function eventCastAndVerify(event)
	event = ffi.cast('struct _cl_event*', event)
	if event == nil
	or event[0].verify ~= cl_event_verify
	--or event ~= ffi.cast('struct _cl_event*', allEvents[1])
	then
		return nil, ffi.C.CL_INVALID_EVENT
	end
	return event
end

function handleEvents(numWaitListEvents, waitListEvents, eventHandle)
	-- ignore the wait list, since luajit doesn't have multithreading and so all cl kernels are executed immediately
	-- if an event is specified then ...
	if eventHandle ~= nil then
		-- eventHandle should be type cl_event*
		eventHandle = ffi.cast('cl_event*', eventHandle)

		local event = ffi.new'struct _cl_event[1]'

		local id = #allEvents+1
		allEvents[id] = event
		event[0].verify = cl_event_verify
		event[0].id = id

		eventHandle[0] = event
	end
end

-- TODO refcount or something if you care, but I don't
function cl.clRetainEvent(event) end
function cl.clReleaseEvent(event) end

cl.clGetEventInfo = makeGetter{
	name = 'clGetEventInfo',
	infotype = 'cl_event_info',
	idcast = eventCastAndVerify,
	-- 1.0:
	[ffi.C.CL_EVENT_COMMAND_QUEUE] = {
		type = 'cl_command_queue',
		value = 0,
	},
	[ffi.C.CL_EVENT_COMMAND_TYPE] = {
		type = 'cl_command_type',
		--[[ one of:
CL_COMMAND_NDRANGE_KERNEL
CL_COMMAND_NATIVE_KERNEL
CL_COMMAND_READ_BUFFER
CL_COMMAND_WRITE_BUFFER
CL_COMMAND_COPY_BUFFER
CL_COMMAND_READ_IMAGE
CL_COMMAND_WRITE_IMAGE
CL_COMMAND_COPY_IMAGE
CL_COMMAND_COPY_BUFFER_TO_IMAGE
CL_COMMAND_COPY_IMAGE_TO_BUFFER
CL_COMMAND_MAP_BUFFER
CL_COMMAND_MAP_IMAGE
CL_COMMAND_UNMAP_MEM_OBJECT
CL_COMMAND_MARKER
CL_COMMAND_ACQUIRE_GL_OBJECTS
CL_COMMAND_RELEASE_GL_OBJECTS
CL_COMMAND_READ_BUFFER_RECT
CL_COMMAND_WRITE_BUFFER_RECT
CL_COMMAND_COPY_BUFFER_RECT
CL_COMMAND_USER
CL_COMMAND_BARRIER
CL_COMMAND_MIGRATE_MEM_OBJECTS
CL_COMMAND_FILL_BUFFER
CL_COMMAND_FILL_IMAGE
CL_COMMAND_SVM_FREE
CL_COMMAND_SVM_MEMCPY
CL_COMMAND_SVM_MEMFILL
CL_COMMAND_SVM_MAP
CL_COMMAND_SVM_UNMAP
			--]]
		value = 0,
	},
	[ffi.C.CL_EVENT_REFERENCE_COUNT] = {
		type = 'cl_uint',
		value = 0,
	},
	[ffi.C.CL_EVENT_COMMAND_EXECUTION_STATUS] = {
		type = 'cl_int',
			--[[
CL_QUEUED
CL_SUBMITTED
CL_RUNNING
CL_COMPLETE
or error code
			--]]
		value = ffi.C.CL_COMPLETE,
	},
	-- 1.1
	[ffi.C.CL_EVENT_CONTEXT] = {
		type = 'cl_context',
		value = 0,	-- TODO give clcpu's contexts unique numbers
	},
}

cl.clGetEventProfilingInfo = makeGetter{
	name = 'clGetEventProfilingInfo',
	infotype = 'cl_event_info',
	idcast = eventCastAndVerify,
	-- 1.0
	[ffi.C.CL_PROFILING_COMMAND_QUEUED] = {
		type = 'cl_ulong',
		value = 0,
	},
	[ffi.C.CL_PROFILING_COMMAND_SUBMIT] = {
		type = 'cl_ulong',
		value = 0,
	},
	[ffi.C.CL_PROFILING_COMMAND_START] = {
		type = 'cl_ulong',
		value = 0,
	},
	[ffi.C.CL_PROFILING_COMMAND_END] = {
		type = 'cl_ulong',
		value = 0,
	},
	-- 2.0
	[ffi.C.CL_PROFILING_COMMAND_COMPLETE] = {
		type = 'cl_ulong',
		value = 0,
	},
}

--[[ cleanup buildEnv libtmp on exit?
-- TODO shouldn't the ffi-c do this?
local GCWrapper = require 'ffi.gcwrapper.gcwrapper'
cl.cleanup = class(GCWrapper{
	gctype = 'cl_cpu_shutdown_t',
	ctype = 'int',
	release = function(ptr)
		os.execute('rm /tmp/libtmp*')
	end,
})()
--]]

setmetatable(cl, {__index=ffi.C})
return cl
