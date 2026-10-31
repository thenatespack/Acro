// Generated from particle_sort_write.comp by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: b3fb08b5145c4f06
// glsl-fnv1a64: 418a9f39cbe2e0eb

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct _18
{
    uint _m0[1];
};

struct _32
{
    uint _m0[1];
};

struct _38
{
    uint2 _m0[1];
};

constant uint3 gl_WorkGroupSize [[maybe_unused]] = uint3(256u, 1u, 1u);

kernel void compute_main(device _32& _34 [[buffer(22)]], device _18& _20 [[buffer(26)]], device _38& _40 [[buffer(27)]], uint3 gl_GlobalInvocationID [[thread_position_in_grid]])
{
    if (gl_GlobalInvocationID.x < _20._m0[1])
    {
        _34._m0[gl_GlobalInvocationID.x] = ((device uint*)&_40._m0[gl_GlobalInvocationID.x])[1u];
    }
}

