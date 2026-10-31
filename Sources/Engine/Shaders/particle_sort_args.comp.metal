// Generated from particle_sort_args.comp by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: f80676eac273c29e
// glsl-fnv1a64: 9035c28833b632d1

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct _14
{
    uint _m0[1];
};

struct _40
{
    uint _m0[1];
};

struct _47
{
    uint4 _m0;
};

constant uint3 gl_WorkGroupSize [[maybe_unused]] = uint3(1u);

kernel void compute_main(constant _47& _49 [[buffer(16)]], device _40& _42 [[buffer(21)]], device _14& _16 [[buffer(26)]])
{
    uint _45 = _42._m0[1];
    uint _54 = min(_45, _49._m0.x);
    uint _215;
    _215 = 2048u;
    for (; _215 < _54; )
    {
        _215 = _215 << uint(1);
        continue;
    }
    _16._m0[0] = _215;
    _16._m0[1] = _54;
    _16._m0[4u] = _215 / 256u;
    _16._m0[5u] = 1u;
    _16._m0[6u] = 1u;
    uint _79 = _215 / 2048u;
    _16._m0[7u] = _79;
    _16._m0[8u] = 1u;
    _16._m0[9u] = 1u;
    for (uint _216 = 0u; _216 < _49._m0.y; _216++)
    {
        bool _99 = (4096u << _216) <= _215;
        uint _102 = 2u * _216;
        uint _218;
        if (_99)
        {
            _218 = _215 / 512u;
        }
        else
        {
            _218 = 0u;
        }
        uint _175 = 3u * (2u + _102);
        _16._m0[4u + _175] = _218;
        _16._m0[5u + _175] = 1u;
        _16._m0[6u + _175] = 1u;
        uint _189 = 3u * (3u + _102);
        _16._m0[4u + _189] = _99 ? _79 : 0u;
        _16._m0[5u + _189] = 1u;
        _16._m0[6u + _189] = 1u;
    }
    uint _203 = 3u * (2u + (2u * _49._m0.y));
    _16._m0[4u + _203] = (_54 + 255u) / 256u;
    _16._m0[5u + _203] = 1u;
    _16._m0[6u + _203] = 1u;
}

