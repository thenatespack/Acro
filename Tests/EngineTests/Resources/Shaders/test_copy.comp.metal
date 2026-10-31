// Generated from test_copy.comp by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 34f8b0b89d3f75cb
// glsl-fnv1a64: 3d7264c8dd164a83

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct _16
{
    uint2 _m0;
};

struct _34
{
    float4 _m0[1];
};

constant uint3 gl_WorkGroupSize [[maybe_unused]] = uint3(8u, 8u, 1u);

kernel void compute_main(constant _16& _18 [[buffer(16)]], device _34& _36 [[buffer(20)]], texture2d<float> _51 [[texture(1)]], uint3 gl_GlobalInvocationID [[thread_position_in_grid]])
{
    do
    {
        if (any(gl_GlobalInvocationID.xy >= _18._m0))
        {
            break;
        }
        _36._m0[(gl_GlobalInvocationID.y * _18._m0.x) + gl_GlobalInvocationID.x] = _51.read(uint2(int2(gl_GlobalInvocationID.xy)), 0);
        break;
    } while(false);
}

