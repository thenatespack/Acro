// Generated from test_depth_read.comp by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 35f7e5e8274a9be9
// glsl-fnv1a64: 874aa7d4e42f6396

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct _20
{
    uint _m0;
    uint _m1;
};

struct _45
{
    float _m0[1];
};

constant uint3 gl_WorkGroupSize [[maybe_unused]] = uint3(8u, 8u, 1u);

kernel void compute_main(constant _20& _22 [[buffer(16)]], device _45& _47 [[buffer(20)]], texture2d<float> _58 [[texture(1)]], sampler _62 [[sampler(1)]], uint3 gl_GlobalInvocationID [[thread_position_in_grid]])
{
    do
    {
        bool _28 = gl_GlobalInvocationID.x >= _22._m0;
        bool _39;
        if (!_28)
        {
            _39 = gl_GlobalInvocationID.y >= _22._m1;
        }
        else
        {
            _39 = _28;
        }
        if (_39)
        {
            break;
        }
        _47._m0[(gl_GlobalInvocationID.y * _22._m0) + gl_GlobalInvocationID.x] = _58.read(uint2(int2(gl_GlobalInvocationID.xy)), 0).x;
        break;
    } while(false);
}

