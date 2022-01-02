local ffi = require 'ffi'
local table = require 'ext.table'
local io = require 'ext.io'
local string = require 'ext.string'
local template = require 'template'

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
struct _cl_platform_id { int id; };
struct _cl_device_id { int id; };
struct _cl_context { int id; };
struct _cl_command_queue { int id; };
struct _cl_event { int id; };

struct _cl_mem {
	size_t verify;
	size_t size;
	uint8_t* ptr;
};

struct _cl_program {
	int id;	//unique id, used to lookup program libs
};

struct _cl_kernel {
	int id;
};

]]

local cl = {}

local function getString(strValue, resultPtr, sizePtr)
	if sizePtr ~= nil then
		sizePtr[0] = #strValue + 1
	end
	if resultPtr ~= nil then
		ffi.copy(resultPtr, strValue)
	end
end


local function handleGetter(args, id, name, paramSize, resultPtr, sizePtr)
--print(debug.traceback())
--print(args.name, id, name)--, paramSize, resultPtr, sizePtr)
	
	local var = args[name]
	if not var then return ffi.C.CL_INVALID_VALUE end

	local tvar = type(var)
	if tvar == 'string' then
		var = {type = 'char[]', getString = var}
	elseif tvar == 'boolean' then
		var = {type = 'cl_bool', get = function() return var end}
	elseif tvar == 'table' then
		local value = var.value
		if value then
			assert(var.get == nil)
			var.get = function() return ffi.cast(var.type, value) end
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

	-- this crashes us immediately ... hmm ... 
	sizePtr = ffi.cast('size_t*', sizePtr)

--print('resultPtr', resultPtr)
--print('sizePtr', sizePtr)

	-- TODO this should be used for array getters, not just string getters
	-- TODO should this only be called when the type ends in a [] ?
	if var.getString then
		local strValue = type(var.getString) == 'string' and var.getString or var.getString()
		assert(type(strValue) == 'string')

		if sizePtr ~= nil then
			sizePtr[0] = #strValue + 1
		end
		
		if resultPtr ~= nil then
			ffi.copy(resultPtr, strValue)
		end
	elseif var.getArray then
		return var.getArray(resultPtr, sizePtr) or cl.CL_SUCCESS
	else
		-- single-value POD results:
		if sizePtr ~= nil then
			sizePtr[0] = ffi.sizeof(var.type)
		end
		if resultPtr ~= nil then
			-- copy by ref
			local value, err = var.get()
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

cl.clGetPlatformInfo = makeGetter{
	name = 'clGetPlatformInfo',
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

local allPlatforms = table{
	ffi.new('struct _cl_platform_id', {id=0})
}

function cl.clGetPlatformIDs(count, platformIDs, countPtr)
	if count == 0 and platformIDs ~= nil then
		return ffi.C.CL_INVALID_VALUE
	end
	if platformIDs == nil and countPtr == nil then
		return ffi.C.CL_INVALID_VALUE
	end
	if countPtr ~= nil then
		countPtr[0] = 1
	end
	if platformIDs ~= nil and count >= 1 then
		platformIDs[0] = allPlatforms[1]
	end
	return ffi.C.CL_SUCCESS
end


-- DEVICE

function cl.clRetainDevice(device) end
function cl.clReleaseDevice(device) end

cl.clGetDeviceInfo = makeGetter{
	name = 'clGetDeviceInfo',
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
		value = 3,
	},
	[ffi.C.CL_DEVICE_MAX_WORK_GROUP_SIZE] = {
		type = 'size_t',
		value = 16,
	},
	[ffi.C.CL_DEVICE_MAX_WORK_ITEM_SIZES] = {
		type = 'size_t[]',
		-- TODO just use get() but when the type ends in [], instead handle mult ret?
		getArray = function(resultPtr, sizePtr)
			if sizePtr ~= nil then
				sizePtr[0] = ffi.sizeof'size_t' * 3	-- * CL_MAX_WORK_ITEM_DIMENSIONS
			end
			if resultPtr ~= nil then
				resultPtr[0] = 256
				resultPtr[1] = 256
				resultPtr[2] = 256
			end
		end,
	},
	[ffi.C.CL_DEVICE_NAME] = 'CPU debug implementation',
	[ffi.C.CL_DEVICE_VENDOR] = 'Christopher Moore',
	[ffi.C.CL_DEVICE_PROFILE] = 'FULL_PROFILE',
	[ffi.C.CL_DEVICE_VERSION] = 'OpenCL 1.1',
	[ffi.C.CL_DEVICE_EXTENSIONS] = 'cl_khr_fp64',
	[ffi.C.CL_DEVICE_PLATFORM] = {
		type = 'cl_platform_id',
		getArray = function(resultPtr, sizePtr)
			if sizePtr ~= nil then
				sizePtr[0] = ffi.sizeof(cl_platform_id)
			end
			if resultPtr ~= nil then
				resultPtr[0] = allPlatforms[1]
			end
		end,
	},
	[ffi.C.CL_DEVICE_OPENCL_C_VERSION] = 'OpenCL 1.1',
	[ffi.C.CL_DEVICE_LINKER_AVAILABLE] = false,
	[ffi.C.CL_DEVICE_BUILT_IN_KERNELS] = '',
}

local allDevices = table{
	ffi.new('struct _cl_device_id[1]', {id = 0})
}

function cl.clGetDeviceIDs(platformID, deviceType, count, deviceIDs, countPtr)
	-- if platformID isn't valid then return CL_INVALID_PLATFORM end
	-- if deviceType isn't valid then return CL_INVALID_DEVICE_TYPE end
	if count == 0 and deviceIDs ~= nil then return ffi.C.CL_INVALID_VALUE end
	-- should I only return success when querying cpus?
	--if bit.band(deviceType, bit.bor(ffi.C.CL_DEVICE_TYPE_CPU, ffi.C.CL_DEVICE_TYPE_DEFAULT)) ~= 0 then
	-- or just always?
	if true then
		if countPtr ~= nil then
			countPtr[0] = 1
		end
		if deviceIDs ~= nil and count >= 1 then
			deviceIDs[0] = allDevices[1]
		end
	else
		return ffi.C.CL_DEVICE_NOT_FOUND
	end
	return ffi.C.CL_SUCCESS
end

-- CONTEXT

function cl.clRetainContext(ctx) end
function cl.clReleaseContext(ctx) end

cl.clGetContextInfo = makeGetter{
	name = 'clGetContextInfo',
	--[ffi.C.CL_CONTEXT_REFERENCE_COUNT] = ...,
	[ffi.C.CL_CONTEXT_NUM_DEVICES] = {
		type = 'cl_uint',
		value = 1,
	},
	[ffi.C.CL_CONTEXT_DEVICES] = {
		type = 'cl_device_id[]',
		getArray = function(resultPtr, sizePtr)
			if sizePtr ~= nil then
				sizePtr[0] = ffi.sizeof'cl_device_id' * 1
			end
			if resultPtr ~= nil then
				resultPtr[0] = allDevices[1]
			end
		end,
	},
	[ffi.C.CL_CONTEXT_PROPERTIES] = {
		type = 'cl_context_properties[]',
		getArray = function(resultPtr, sizePtr)
			if sizePtr ~= nil then
				sizePtr[0] = 0
			end
			-- resultPtr doesn't matter ... it's a zero-sized array we are filling
		end,
	},
}

-- TODO multiple contexts? any need yet?
local allContexts = table{
	ffi.new('struct _cl_context[1]', {id = 0}),
}

function cl.clCreateContext(properties, numDevices, deviceIDs, notify, x, errPtr)
	if errPtr ~= nil then 
		errPtr[0] = ffi.C.CL_SUCCESS 
	end
	local ctx = allContexts[1]
	return ctx
end

-- MEMORY OBJECT

function cl.clRetainMemObject(mem) end
function cl.clReleaseMemObject(mem) end

function cl.clGetMemObjectInfo(mem, name, size, valuePtr, sizePtr)
	print('clGetMemObjectInfo', mem, name, size, valuePtr, sizePtr)
	return ffi.C.CL_SUCCESS
end

-- IMAGE

function cl.clGetImageInfo(mem, name, size, valuePtr, sizePtr)
	print('clGetImageInfo', mem, name, size, valuePtr, sizePtr)
	return ffi.C.CL_SUCCESS
end

-- BUFFER


local allMems = table()
local allPtrs = table()	-- because I don't trust luajit to not gc a ptr I ffi.new'd 

local cl_mem_verify = ffi.new('size_t', 0xdeadbeefdeadbeef)

--[[
returns cl_mem
which I have typecast to a _cl_mem*
and so in luajit I'm returning a _cl_mem[1]
so that it will act like a _cl_mem*
--]]
function cl.clCreateBuffer(ctxID, flags, size, hostPtr, errPtr)
	ctxID = ffi.cast('cl_context', ctxID)
	flags = ffi.cast('cl_mem_flags', flags)
	size = ffi.cast('size_t', size)
	hostPtr = ffi.cast('void*', hostPtr)
	errPtr = ffi.cast('cl_int*', errPtr)
print('clCreateBuffer', ctxID, flags, size, hostPtr, errPtr)	
	
	if size == 0 then
		if errPtr ~= nil then 
			errPtr[0] = ffi.C.CL_INVALID_BUFFER_SIZE
		end
		return
	end
	-- TODO if size > CL_DEVICE_MAX_MEM_ALLOC_SIZE then return CL_INVALID_BUFFER_SIZE

	local reqHost = bit.band(flags, bit.bor(ffi.C.CL_MEM_USE_HOST_PTR, ffi.C.CL_MEM_COPY_HOST_PTR)) ~= 0
	if (reqHost and hostPtr == nil)
	or (not reqHost and hostPtr ~= nil)
	then
		if errPtr ~= nil then
			errPtr[0] = ffi.C.CL_INVALID_HOST_PTR
		end
		return
	end

	local mem = ffi.new'struct _cl_mem[1]'

	-- TODO upon fail here, return CL_MEM_OBJECT_ALLOCATION_FAILURE or CL_OUT_OF_HOST_MEMORY
	local ptr = ffi.new('uint8_t[?]', size)
	allPtrs:insert(ptr)

print('ptr', ptr)
print('size', size)
	mem[0].verify = cl_mem_verify
	mem[0].ptr = ptr
	mem[0].size = size
	allMems:insert(mem)	-- don't let luajit gc it.  TODO refcount / retain / release to keep track of it that way
	
	if reqHost then ffi.copy(mem[0].ptr, hostPtr, size) end
	
	if errPtr ~= nil then 
		errPtr[0] = ffi.C.CL_SUCCESS 
	end
	return ffi.cast('cl_mem', mem)	-- return the ptr, not the obj, so ffi.sizeof says it's a ptr size, not the obj size (which is double)
end

local function handleEvents(numWaitListEvents, waitListEvents, event)
	-- ignore the wait list, since luajit doesn't have multithreading and so all cl kernels are executed immediately
	-- if an event is specified then ...
	if event ~= nil then
		-- event should be type cl_event*
		event = ffi.cast('struct _cl_event *', event)
		event[0].id = 0
	end
end

function cl.clEnqueueWriteBuffer(cmds, buffer, block, offset, size, ptr, numWaitListEvents, waitListEvents, event)
--print(debug.traceback())
print('clEnqueueWriteBuffer', cmds, buffer, block, offset, size, ptr, numWaitListEvents, waitListEvents, event)
	handleEvents(numWaitListEvents, waitListEvents, event)
	ffi.copy(buffer[0].ptr + offset, ptr, size)
	return ffi.C.CL_SUCCESS
end

function cl.clEnqueueReadBuffer(cmds, buffer, block, offset, size, ptr, numWaitListEvents, waitListEvents, event)
--print(debug.traceback())
print('clEnqueueReadBuffer', cmds, buffer, block, offset, size, ptr, numWaitListEvents, waitListEvents, event)
	handleEvents(numWaitListEvents, waitListEvents, event)
	ffi.copy(ptr, buffer[0].ptr + offset, size)
	return ffi.C.CL_SUCCESS
end

local int0 = ffi.new('int[1]', 0)
function cl.clEnqueueFillBuffer(cmds, buffer, pattern, patternSize, offset, size, numWaitListEvents, waitListEvents, event)
--print(debug.traceback())
--print('clEnqueueFillBuffer', cmds, buffer, pattern, patternSize, offset, size, numWaitListEvents, waitListEvents, event)
	pattern = ffi.cast('uint8_t*', pattern)
	offset = ffi.cast('size_t', offset)
	size = ffi.cast('size_t', size)
	patternSize = ffi.cast('size_t', patternSize)
print('clEnqueueFillBuffer', cmds, buffer, pattern, patternSize, offset, size, numWaitListEvents, waitListEvents, event)
print('buffer size', buffer[0].size)
print('buffer ptr', buffer[0].ptr)
print('ffi sizeof buffer ptr', ffi.sizeof(buffer[0].ptr))
	handleEvents(numWaitListEvents, waitListEvents, event)
	
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

	if buffer[0].ptr == nil then
		return ffi.C.CL_INVALID_MEM_OBJECT
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

-- PROGRAM

-- c fails on arith ops for vector types
local gcc = require 'ffi-c.c'
-- c++ fails on field initialization
--local gcc = require 'ffi-c.cpp'

-- global ... should make this context-based, but right now all the ctx stuff is c-structs ...
local programsForID = table()

function cl.clRetainProgram(cmds) end
function cl.clReleaseProgram(cmds) end

function cl.clGetProgramInfo(programHandle, name, paramSize, resultPtr, sizePtr)
	local id = programHandle[0].id
	local program = assert(programsForID[id])
	if name == ffi.C.CL_PROGRAM_BINARY_SIZES then
		if resultPtr == nil then
			ffi.cast('size_t*', sizePtr)[0] = ffi.sizeof'size_t'
		else
			ffi.cast('size_t*', resultPtr)[0] = #program.libdata
		end
	elseif name == ffi.C.CL_PROGRAM_BINARIES then
		if resultPtr == nil then
			ffi.cast('size_t*', sizePtr)[0] = ffi.sizeof'unsigned char*'
		else
			ffi.cast('unsigned char**', resultPtr)[0] = ffi.cast('unsigned char*', program.libdata)
		end

	else
		print('clGetProgramInfo', programHandle, name, paramSize, resultPtr, sizePtr)
	end
	return ffi.C.CL_SUCCESS
end

function cl.clGetProgramBuildInfo(programHandle, device, name, paramSize, resultPtr, sizePtr)
	local id = programHandle[0].id
	local program = assert(programsForID[id])
	if name == ffi.C.CL_PROGRAM_BUILD_LOG then
		local log = table()
		log:insert(program.compileLog)
		log:insert(program.linkLog)
		getString(log:concat'\n', resultPtr, sizePtr)
	else
		print('clGetProgramBuildInfo', programHandle, name, paramSize, resultPtr, sizePtr)
	end
	return ffi.C.CL_SUCCESS
end

local allProgramHandles = table()

function cl.clCreateProgramWithSource(ctx, numStrings, stringsPtr, lengthsPtr, errPtr)
	-- I'm creating the program entry up front
	-- so there can be dead programs in the table
	-- but the tradeoff is that I can also now use the program unique ID in the program's code gen
	local programHandle = ffi.new'struct _cl_program[1]'
	local id = #programsForID+1
	programHandle[0].id = id
print('adding program entry', id)
	programsForID[id] = {id=id}
	allProgramHandles[id] = programHandle
	
	local vectorTypes = {'char', 'uchar', 'short', 'ushort', 'int', 'uint', 'long', 'ulong', 'float', 'double'}
	local code = table{
		template([[
<?
local ffi = require 'ffi'
if ffi.os == 'Windows' then
?>
#define __attribute__(x)

//I hate Windows
#define EXTERN __declspec(dllexport)
#define kernel EXTERN

<? else ?>

#define EXTERN
#define kernel

<?
end
?>

#define constant const
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


EXTERN size_t _program_<?=id?>_global_id_0 = 0;
EXTERN size_t _program_<?=id?>_global_id_1 = 0;
EXTERN size_t _program_<?=id?>_global_id_2 = 0;
#define get_global_id(n)	_program_<?=id?>_global_id_##n

EXTERN int _program_<?=id?>_global_size_0 = 0;
EXTERN int _program_<?=id?>_global_size_1 = 0;
EXTERN int _program_<?=id?>_global_size_2 = 0;
#define get_global_size(n)	_program_<?=id?>_global_size_##n

EXTERN size_t _program_<?=id?>_local_id_0 = 0;
EXTERN size_t _program_<?=id?>_local_id_1 = 0;
EXTERN size_t _program_<?=id?>_local_id_2 = 0;
#define get_local_id(n)	_program_<?=id?>_local_id_##n

EXTERN int _program_<?=id?>_local_size_0 = 0;
EXTERN int _program_<?=id?>_local_size_1 = 0;
EXTERN int _program_<?=id?>_local_size_2 = 0;
#define get_local_size(n)	_program_<?=id?>_local_size_##n

EXTERN size_t _program_<?=id?>_group_id_0 = 0;
EXTERN size_t _program_<?=id?>_group_id_1 = 0;
EXTERN size_t _program_<?=id?>_group_id_2 = 0;
#define get_group_id(n)	_program_<?=id?>_group_id_##n

int4 int4_add(int4 a, int4 b) {
	return (int4){
		.x = a.x + b.x,
		.y = a.y + b.y,
		.z = a.z + b.z,
		.w = a.w + b.w,
	};
}

]], 	{
			id = id,
			vectorTypes = vectorTypes,
		}),
	}
	for i=0,numStrings-1 do
		code:insert(ffi.string(stringsPtr[i], lengthsPtr[i]))
	end
	code = code:concat'\n'

-- hmm, typedef with a cl vector type, which uses constructor syntax not supported by C...
local realtype = code:match'typedef%s+(%S*)%s+real;'
if realtype then
	print('replacing realtype '..realtype)
	code = code:gsub('%(real4%)', '('..realtype..'4)')
end
for _,base in ipairs(vectorTypes) do
	code = code:gsub('%('..base..'4%)%(', '_'..base..'4(')
end

	-- hmm, opencl allows for (type#)(...) initializers for vectors
	-- how to convert this to C ?

	-- opencl also overloads arithmetic operators ...
	code = code:gsub('i %+= _int4%(([^)]*)%)', function(inside)
		return 'i = int4_add(i,_int4('..inside..'))'
	end)

	programsForID[id].code = code

	if errPtr then errPtr[0] = ffi.C.CL_SUCCESS end
	return programHandle
end

function cl.clCreateProgramWithBinary(ctx, numDevices, devices, lengths, binaries, binaryStatus, errcodeRets)
	error("not yet implemented")
end

function cl.clBuildProgram(programHandle, numDevices, deviceIDs, options, a, b)
	local err = ffi.C.CL_SUCCESS
	local id = programHandle[0].id
	assert(not a and not b)
print('compiling program entry', id)
	local program = programsForID[id]
	xpcall(function()
		local result = gcc:compile(program.code)
		if result.error then error(result.error) end
print('done compiling program entry', id)
		
		-- gcc:compile calls ffi.load
		-- so these should now be available:
		ffi.cdef(template([[
size_t _program_<?=id?>_global_id_0;
size_t _program_<?=id?>_global_id_1;
size_t _program_<?=id?>_global_id_2;

int _program_<?=id?>_global_size_0;
int _program_<?=id?>_global_size_1;
int _program_<?=id?>_global_size_2;

size_t _program_<?=id?>_local_id_0;
size_t _program_<?=id?>_local_id_1;
size_t _program_<?=id?>_local_id_2;

int _program_<?=id?>_local_size_0;
int _program_<?=id?>_local_size_1;
int _program_<?=id?>_local_size_2;

size_t _program_<?=id?>_group_id_0;
size_t _program_<?=id?>_group_id_1;
size_t _program_<?=id?>_group_id_2;
]], {id=id}))
		
		program.lib = result.lib
		program.libfile = result.libfile
		program.libdata = assert(io.readfile(result.libfile), "couldn't open file "..result.libfile)
		program.compileLog = result.compileLog
		program.linkLog = result.linkLog
	end, function(err)
print('error while compiling: '..err)
--print(debug.traceback())
		err = ffi.C.CL_BUILD_PROGRAM_FAILURE
	end)
	return err
end

-- KERNEL

local kernelsForID = table()

function cl.clRetainKernel(kernel) end
function cl.clReleaseKernel(kernel) end

function cl.clGetKernelInfo(kernel, name, paramSize, resultPtr, sizePtr)
	print('clGetKernelInfo', kernel, name, paramSize, resultPtr, sizePtr)
	return ffi.C.CL_SUCCESS
end


-- from my lua-preproc project ...
local function removeCommentsAndApplyContinuations(code)
	
	-- should line continuations \ affect single-line comments?
	-- if so then do this here
	-- or should they not?  then do this after.
	repeat
		local i, j = code:find('\\%s*\n')
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



function cl.clCreateKernel(programHandle, kernelName, errPtr)
--print(debug.traceback())
print('clCreateKernel', programHandle, kernelName, errPtr)	
	local program = assert(programsForID[programHandle[0].id])

	local code = removeCommentsAndApplyContinuations(program.code)

	print('searching for kernel', kernelName)
	
	-- TODO how to get the signature?
	-- search for it in the code maybe?

	local sig = code:match('kernel%s+void%s+'..kernelName..'%s*%([^)]*%)')
	print('found with signature:\n'..sig:gsub('%s+', ' '))

	local sigargs = sig:match('^kernel%s+void%s+'..kernelName..'%s*%(([^)]*)%)$')
	assert(sigargs, "doesn't match a kernel void")
		
	-- split by comma and parse each arg separately
	-- let's hope there's no macros in there with commas in them
	local argInfos = table()
	sigargs = string.split(sigargs, ','):mapi(function(arg,i)
		local argInfo = {}
		argInfos[i] = argInfo
		
		arg = string.trim(arg)
		local tokens = string.split(arg, '%s+')
		-- split off any *'s into unique tokens
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
			end
		end
		for j=1,#tokens do 	-- TODO table.replace?  how have I never needed table.replace until now?
			if tokens[j] == 'constant' then
				tokens[j] = 'const'
				argInfo.isConstant = true
			end
		end

		local varname = tokens:remove()	-- assume the last is the variable name
		argInfo.name = varname

		-- keep track of the type to convert to before calling the kernel
		argInfo.origtype = tokens:concat' '
		-- or not? idk that i need it -- I'll let the kernel code do the casting

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
	-- now replace "constant structname const *" => "const void const *" with just "void *"

	sig = 'void '..kernelName.. '(' .. sigargs .. ');'
	
	print("cdef'ing as sig:\n"..sig)
	ffi.cdef(sig)

	local func = program.lib[kernelName]
	print('func', func)

	if errPtr then errPtr[0] = ffi.C.CL_SUCCESS end
	local kernelHandle = ffi.new'struct _cl_kernel[1]'
	kernelHandle[0].id = #kernelsForID+1
	kernelsForID[kernelHandle[0].id] = {
		name = kernelName,
		program = program,
		func = func,
		argInfos = argInfos,		-- holds for each arg: name, type, isGlobal, isLocal
		args = {},					-- holds the clSetKernelArg() values
		numargs = numargs,
		isGlobal = isGlobal,
		isLocal = isLocal,
		isConstant = isConstant,
		handle = kernelHandle,		-- hold so luajit doesn't free
	}
	
	print('returning kernel handle', kernelHandle[0].id)

	return kernelHandle
end

function cl.clSetKernelArg(kernelHandle, index, size, value)
	kernelHandle = ffi.cast('cl_kernel', kernelHandle)
	index = ffi.cast('cl_uint', index)
	size = ffi.cast('size_t', size)
	value = ffi.cast('void*', value)
	
	local kernel = kernelsForID[kernelHandle[0].id]
	if not kernel then
		return ffi.C.CL_INVALID_KERNEL
	end
	if index >= kernel.numargs then
		return ffi.C.CL_INVALID_ARG_INDEX
	end
	local argInfo = kernel.argInfos[tonumber(index)+1]
	assert(argInfo, "tried to set kernel arg "..tonumber(index)
		.." but arginfo is nil, only has "..#kernel.argInfos
		.." though numargs is "..kernel.numargs)

	-- if the kernel arg isn't local then the value can't be null ...
	if value == nil then
		if not argInfo.isLocal then
			return ffi.C.CL_INVALID_ARG_VALUE
		end
	end
	
	-- if the kernel arg is global then the value better be a cl_mem ...
	if argInfo.isGlobal 
	or argInfo.isConstant
	then
		-- clSetKernelArg for globals uses cl_mem[1], which is _cl_mem*[1]
		local verifyvalue = ffi.cast('cl_mem*', value)
		if verifyvalue[0][0].verify ~= cl_mem_verify then
			return ffi.C.CL_INVALID_MEM_OBJECT
		end
	
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

	-- mind you value is a void* by now. 
	-- if it's a global then it points to a struct _cl_mem
	kernel.args[tonumber(index)+1] = value	-- {size, value}
	
	return ffi.C.CL_SUCCESS
end

function cl.clGetKernelWorkGroupInfo(kernelID, deviceID, name, paramSize, resultPtr, sizePtr)
	if name == ffi.C.CL_KERNEL_WORK_GROUP_SIZE then
		resultPtr = ffi.cast('size_t*', resultPtr)
		if resultPtr ~= nil then
			resultPtr[0] = 16
		end
	else
		print('clGetKernelWorkGroupInfo', kernelID, deviceID, name, paramSize, resultPtr, sizePtr)
	end
	return ffi.C.CL_SUCCESS
end

-- COMMAND QUEUE

local allCmds = table{
	ffi.new('struct _cl_command_queue[1]', {id=0}),
}

function cl.clRetainCommandQueue(cmds) end
function cl.clReleaseCommandQueue(cmds) end

function cl.clCreateCommandQueue(ctx, device, properties, errPtr)
	if errPtr then errPtr[0] = ffi.C.CL_SUCCESS end
	local cmds = allCmds[1]
	return cmds
end

function cl.clGetCommandQueueInfo(cmds, name, paramSize, param, paramSizePtr)
	print('clGetCommandQueueInfo', cmds, name, paramSize, param, paramSizePtr)
	return ffi.C.CL_SUCCESS
end

function cl.clEnqueueNDRangeKernel(cmds, kernelHandle, work_dim, global_work_offset, global_work_size, local_work_size, num_events_in_wait_list, event_wait_list, event)
--print(debug.traceback())
print('clEnqueueNDRangeKernel', cmds, kernelHandle, work_dim, global_work_offset, global_work_size, local_work_size, num_events_in_wait_list, event_wait_list, event)
	local kernel = kernelsForID[kernelHandle[0].id]
print('kernel', kernel.name)
	local program = kernel.program
print('program', program.libfile)
	local pid = program.id
	local lib = program.lib
	local args = table(kernel.args)
	local argInfos = kernel.argInfos
	for i=1,kernel.numargs do
		local argInfo = assert(argInfos[i])
		local arg = args[i]
print('arg '..i)
print('type(arg)', type(arg))
print('ffi.typeof(arg)', ffi.typeof(arg))
print('argInfo.origtype', argInfo.origtype)
print('argInfo.type', argInfo.type)		
		assert(type(arg) == 'cdata')
		assert(tostring(ffi.typeof(arg)) == 'ctype<void *>')
		
		if argInfo.isGlobal 
		or argInfo.isConstant
		then	-- assert we have a cl_mem ... same with local?
print'isGlobal or isConstant'
print('before cast', arg)			
			arg = ffi.cast('cl_mem*', arg)
print('after cast, arg', arg)
print('after cast, arg[0]', arg[0])
print('after cast, arg[0][0]', arg[0][0])
print('after cast, arg[0][0].verify', arg[0][0].verify)
			assert(arg[0][0].verify == cl_mem_verify)
			arg = arg[0][0].ptr
		elseif argInfo.isLocal then
print'isLocal'			
			-- use the pointer as-is
		else
print'neither local nor global (prim?)'			
			arg = ffi.cast(argInfo.type..'*', arg)[0]
		end
print('arg value', arg)
		args[i] = arg
	end

print('calling...')
	local global_work_offset_v = {}
	local global_work_size_v = {}
	local local_work_size_v = {}
	assert(work_dim >= 1 and work_dim <= 3)
	for i=1,work_dim do
		global_work_offset_v[i] = tonumber(global_work_offset[i-1])
		global_work_size_v[i] = tonumber(global_work_size[i-1])
		local_work_size_v[i] = tonumber(local_work_size[i-1])
	end
	for i=work_dim+1,3 do
		global_work_offset_v[i] = 0
		global_work_size_v[i] = 1
		local_work_size_v[i] = 1
	end
	local local_id_fields = {}
	local group_id_fields = {}
	local global_id_fields = {}
	for n=0,2 do
		lib['_program_'..pid..'_local_size_'..n] = local_work_size_v[n+1]
		-- does global size include the global offset?
		lib['_program_'..pid..'_global_size_'..n] = global_work_size_v[n+1]
		local_id_fields[n+1] = '_program_'..pid..'_local_id_'..n
		group_id_fields[n+1] = '_program_'..pid..'_group_id_'..n
		global_id_fields[n+1] = '_program_'..pid..'_global_id_'..n
	end
	local is = {}
	for i=0,global_work_size_v[1]-1 do
		for j=0,global_work_size_v[2]-1 do
			for k=0,global_work_size_v[3]-1 do
				is[1]=i is[2]=j is[3]=k
				for n=1,3 do
					lib[local_id_fields[n]] = is[n] % local_work_size_v[n]
					lib[group_id_fields[n]] = is[n] / local_work_size_v[n]
					lib[global_id_fields[n]] = is[n] + global_work_offset_v[n]
				end
--io.write('('..table.concat(is, ', ')..') ')
				kernel.func(table.unpack(args, 1, kernel.numargs))
			end
		end
	end
print('clEnqueueNDRangeKernel done')
	return ffi.C.CL_SUCCESS
end

function cl.clFinish() end

-- EVENT

-- TODO refcount or something if you care, but I don't
function cl.clRetainEvent(event) end
function cl.clReleaseEvent(event) end

cl.clGetEventInfo = makeGetter{
	name = 'clGetEventInfo',
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

setmetatable(cl, {__index=ffi.C})
return cl
