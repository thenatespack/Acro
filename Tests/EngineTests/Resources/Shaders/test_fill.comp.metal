// Generated from test_fill.comp by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 8d4eedef1ba6b8f0
// glsl-fnv1a64: 897f9be272f7da8d

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct _17
{
    uint _m0;
    uint _m1;
    uint _m2;
    uint _m3;
};

struct _31
{
    uint _m0[1];
};

constant uint3 gl_WorkGroupSize [[maybe_unused]] = uint3(64u, 1u, 1u);

kernel void compute_main(constant _17& _19 [[buffer(16)]], device _31& _33 [[buffer(20)]], uint3 gl_GlobalInvocationID [[thread_position_in_grid]])
{
    do
    {
        if (gl_GlobalInvocationID.x >= _19._m0)
        {
            break;
        }
        uint _67;
        if (_19._m3 == 0u)
        {
            _67 = gl_GlobalInvocationID.x;
        }
        else
        {
            _67 = _33._m0[gl_GlobalInvocationID.x];
        }
        _33._m0[gl_GlobalInvocationID.x] = (_67 * _19._m1) + _19._m2;
        break;
    } while(false);
}

