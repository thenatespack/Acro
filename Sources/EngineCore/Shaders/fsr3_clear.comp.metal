// Generated from fsr3_clear.comp by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: e5008d88e79f01d3
// glsl-fnv1a64: dbe8576bc452220d

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct _18
{
    float4 _m0;
    uint2 _m1;
    uint _m2;
    uint _m3;
};

struct _54
{
    uint _m0[1];
};

constant uint3 gl_WorkGroupSize [[maybe_unused]] = uint3(8u, 8u, 1u);

kernel void compute_main(constant _18& _20 [[buffer(16)]], device _54& _56 [[buffer(20)]], texture2d<float, access::write> _43 [[texture(8)]], uint3 gl_GlobalInvocationID [[thread_position_in_grid]])
{
    do
    {
        if (any(gl_GlobalInvocationID.xy >= _20._m1))
        {
            break;
        }
        if (_20._m2 == 0u)
        {
            _43.write(_20._m0, uint2(int2(gl_GlobalInvocationID.xy)));
        }
        else
        {
            _56._m0[(gl_GlobalInvocationID.y * _20._m1.x) + gl_GlobalInvocationID.x] = _20._m3;
        }
        break;
    } while(false);
}

