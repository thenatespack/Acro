// Generated from particle_sort_global.comp by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 65183d349d72525a
// glsl-fnv1a64: ccd34339da422625

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct _18
{
    uint4 _m0;
};

struct _47
{
    uint2 _m0[1];
};

constant uint3 gl_WorkGroupSize [[maybe_unused]] = uint3(256u, 1u, 1u);

kernel void compute_main(constant _18& _20 [[buffer(16)]], device _47& _49 [[buffer(27)]], uint3 gl_GlobalInvocationID [[thread_position_in_grid]])
{
    uint _38 = ((2u * _20._m0.y) * (gl_GlobalInvocationID.x / _20._m0.y)) + (gl_GlobalInvocationID.x % _20._m0.y);
    uint _42 = _38 + _20._m0.y;
    uint2 _53 = _49._m0[_38];
    bool _71 = _49._m0[_42].x < _53.x;
    bool _88;
    if (!_71)
    {
        bool _79 = _49._m0[_42].x == _53.x;
        bool _87;
        if (_79)
        {
            _87 = _49._m0[_42].y < _53.y;
        }
        else
        {
            _87 = _79;
        }
        _88 = _87;
    }
    else
    {
        _88 = _71;
    }
    if (_88 == ((_38 & _20._m0.x) == 0u))
    {
        _49._m0[_38] = _49._m0[_42];
        _49._m0[_42] = _53;
    }
}

