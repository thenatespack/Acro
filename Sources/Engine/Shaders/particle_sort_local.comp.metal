// Generated from particle_sort_local.comp by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 128d9e944dd41860
// glsl-fnv1a64: 252276dafcf82af4

#pragma clang diagnostic ignored "-Wmissing-prototypes"
#pragma clang diagnostic ignored "-Wmissing-braces"

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

template<typename T, size_t Num>
struct spvUnsafeArray
{
    T elements[Num ? Num : 1];
    
    thread T& operator [] (size_t pos) thread
    {
        return elements[pos];
    }
    constexpr const thread T& operator [] (size_t pos) const thread
    {
        return elements[pos];
    }
    
    device T& operator [] (size_t pos) device
    {
        return elements[pos];
    }
    constexpr const device T& operator [] (size_t pos) const device
    {
        return elements[pos];
    }
    
    constexpr const constant T& operator [] (size_t pos) const constant
    {
        return elements[pos];
    }
    
    threadgroup T& operator [] (size_t pos) threadgroup
    {
        return elements[pos];
    }
    constexpr const threadgroup T& operator [] (size_t pos) const threadgroup
    {
        return elements[pos];
    }
};

struct _147
{
    uint2 _m0[1];
};

struct _164
{
    uint4 _m0;
};

constant uint3 gl_WorkGroupSize [[maybe_unused]] = uint3(256u, 1u, 1u);

kernel void compute_main(constant _164& _166 [[buffer(16)]], device _147& _149 [[buffer(27)]], uint gl_LocalInvocationIndex [[thread_index_in_threadgroup]], uint3 gl_WorkGroupID [[threadgroup_position_in_grid]])
{
    threadgroup spvUnsafeArray<uint2, 2048> _92;
    uint _130 = gl_WorkGroupID.x * 2048u;
    for (uint _432 = 0u; _432 < 8u; )
    {
        uint _144 = 256u * _432;
        _92[gl_LocalInvocationIndex + _144] = _149._m0[(_130 + gl_LocalInvocationIndex) + _144];
        _432++;
        continue;
    }
    threadgroup_barrier(mem_flags::mem_threadgroup);
    if (_166._m0.x == 0u)
    {
        for (uint _439 = 2u; _439 <= 2048u; _439 = _439 << uint(1))
        {
            uint _183 = _439 >> uint(1);
            for (uint _441 = _183; _441 > 0u; _441 = _441 >> uint(1))
            {
                for (uint _443 = 0u; _443 < 4u; _443++)
                {
                    uint _263 = gl_LocalInvocationIndex + (256u * _443);
                    uint _273 = ((2u * _441) * (_263 / _441)) + (_263 % _441);
                    uint _276 = _273 + _441;
                    bool _315 = _92[_276].x < _92[_273].x;
                    bool _332;
                    if (!_315)
                    {
                        bool _322 = _92[_276].x == _92[_273].x;
                        bool _330;
                        if (_322)
                        {
                            _330 = _92[_276].y < _92[_273].y;
                        }
                        else
                        {
                            _330 = _322;
                        }
                        _332 = _330;
                    }
                    else
                    {
                        _332 = _315;
                    }
                    if (_332 == (((_130 + _273) & _439) == 0u))
                    {
                        uint2 _295 = _92[_273];
                        _92[_273] = _92[_276];
                        _92[_276] = _295;
                    }
                }
                threadgroup_barrier(mem_flags::mem_threadgroup);
            }
        }
    }
    else
    {
        for (uint _433 = 1024u; _433 > 0u; _433 = _433 >> uint(1))
        {
            for (uint _434 = 0u; _434 < 4u; _434++)
            {
                uint _350 = gl_LocalInvocationIndex + (256u * _434);
                uint _360 = ((2u * _433) * (_350 / _433)) + (_350 % _433);
                uint _363 = _360 + _433;
                bool _402 = _92[_363].x < _92[_360].x;
                bool _419;
                if (!_402)
                {
                    bool _409 = _92[_363].x == _92[_360].x;
                    bool _417;
                    if (_409)
                    {
                        _417 = _92[_363].y < _92[_360].y;
                    }
                    else
                    {
                        _417 = _409;
                    }
                    _419 = _417;
                }
                else
                {
                    _419 = _402;
                }
                if (_419 == (((_130 + _360) & _166._m0.x) == 0u))
                {
                    uint2 _382 = _92[_360];
                    _92[_360] = _92[_363];
                    _92[_363] = _382;
                }
            }
            threadgroup_barrier(mem_flags::mem_threadgroup);
        }
    }
    for (uint _440 = 0u; _440 < 8u; )
    {
        uint _234 = 256u * _440;
        _149._m0[(_130 + gl_LocalInvocationIndex) + _234] = _92[gl_LocalInvocationIndex + _234];
        _440++;
        continue;
    }
}

