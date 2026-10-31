// Generated from test_formats.comp by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 69710e5ebc8d30a6
// glsl-fnv1a64: 226ab1351aacc825

#pragma clang diagnostic ignored "-Wmissing-prototypes"

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

template <typename ImageT>
void spvImageFence(ImageT img) { img.fence(); }

struct _16
{
    uint2 _m0;
    uint _m1;
};

struct _117
{
    float _m0[1];
};

constant uint3 gl_WorkGroupSize [[maybe_unused]] = uint3(8u, 8u, 1u);

kernel void compute_main(constant _16& _18 [[buffer(16)]], device _117& _119 [[buffer(20)]], texture2d<float> _123 [[texture(1)]], texture2d<float> _132 [[texture(2)]], texture2d<float> _141 [[texture(3)]], texture2d<float> _158 [[texture(4)]], texture2d<float, access::read_write> _55 [[texture(8)]], texture2d<float, access::write> _67 [[texture(9)]], texture2d<float, access::write> _77 [[texture(10)]], texture2d<float, access::write> _90 [[texture(11)]], uint3 gl_GlobalInvocationID [[thread_position_in_grid]])
{
    do
    {
        if (any(gl_GlobalInvocationID.xy >= _18._m0))
        {
            break;
        }
        uint _45 = (gl_GlobalInvocationID.y * _18._m0.x) + gl_GlobalInvocationID.x;
        float _46 = float(_45);
        if (_18._m1 == 0u)
        {
            int2 _59 = int2(gl_GlobalInvocationID.xy);
            _55.write(float4(_46 * 0.0039215688593685626983642578125), uint2(_59));
            _67.write(float4(_46 * 0.5), uint2(_59));
            _77.write(float4(-_46, _46 * 0.25, 0.0, 0.0), uint2(_59));
            _90.write(float4((_46 * 1000.0) + 0.125), uint2(_59));
        }
        else
        {
            uint _111 = _45 * 6u;
            int2 _115 = int2(gl_GlobalInvocationID.xy);
            _119._m0[_111] = _123.read(uint2(_115), 0).x;
            _119._m0[_111 + 1u] = _132.read(uint2(_115), 0).x;
            _119._m0[_111 + 2u] = _141.read(uint2(_115), 0).x;
            _119._m0[_111 + 3u] = _141.read(uint2(_115), 0).y;
            _119._m0[_111 + 4u] = _158.read(uint2(_115), 0).x;
            spvImageFence(_55);
            _119._m0[_111 + 5u] = _55.read(uint2(_115)).x;
        }
        break;
    } while(false);
}

