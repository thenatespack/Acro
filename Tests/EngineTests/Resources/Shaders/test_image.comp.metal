// Generated from test_image.comp by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: fd508b86021ef62f
// glsl-fnv1a64: cbdd1b91842cdcb1

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct _23
{
    int2 _m0;
    uint _m1;
};

struct _87
{
    uint _m0[1];
};

constant uint3 gl_WorkGroupSize [[maybe_unused]] = uint3(8u, 8u, 1u);

kernel void compute_main(constant _23& _25 [[buffer(16)]], device _87& _89 [[buffer(20)]], texture2d<float> _75 [[texture(1)]], texture2d<float, access::write> _54 [[texture(8)]], sampler _79 [[sampler(1)]], uint3 gl_GlobalInvocationID [[thread_position_in_grid]])
{
    do
    {
        int2 _17 = int2(gl_GlobalInvocationID.xy);
        int _22 = _17.x;
        bool _30 = _22 >= _25._m0.x;
        bool _40;
        if (!_30)
        {
            _40 = _17.y >= _25._m0.y;
        }
        else
        {
            _40 = _30;
        }
        if (_40)
        {
            break;
        }
        if (_25._m1 == 0u)
        {
            _54.write(float4(float(_22) * 0.015625, float(_17.y) * 0.015625, 0.25, 1.0), uint2(_17));
        }
        else
        {
            _89._m0[(_17.y * _25._m0.x) + _22] = pack_float_to_unorm4x8(_75.read(uint2(_17), 0));
        }
        break;
    } while(false);
}

