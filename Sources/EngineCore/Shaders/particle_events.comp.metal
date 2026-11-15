// Generated from particle_events.comp by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: b29620524b430bb7
// glsl-fnv1a64: fd7e55ec5ce293fb

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

struct _36
{
    uint _m0[1];
};

struct _42
{
    uint4 _m0;
    uint4 _m1;
};

struct _106
{
    uint _m0[1];
};

struct _175
{
    float4 _m0;
    float4 _m1;
    float4 _m2;
};

struct _177
{
    _175 _m0[1];
};

struct _193
{
    float4 _m0[1];
};

struct _250
{
    uint _m0[1];
};

constant uint3 gl_WorkGroupSize [[maybe_unused]] = uint3(256u, 1u, 1u);

kernel void compute_main(constant _42& _44 [[buffer(16)]], device _177& _179 [[buffer(20)]], device _36& _38 [[buffer(21)]], device _106& _108 [[buffer(23)]], device _193& _195 [[buffer(24)]], device _250& _252 [[buffer(25)]], uint gl_LocalInvocationIndex [[thread_index_in_threadgroup]], uint3 gl_WorkGroupID [[threadgroup_position_in_grid]], uint3 gl_GlobalInvocationID [[thread_position_in_grid]])
{
    threadgroup spvUnsafeArray<uint, 256> _61;
    uint _291;
    _291 = 0u;
    for (uint _290 = gl_LocalInvocationIndex; _290 < gl_WorkGroupID.x; )
    {
        _291 += _38._m0[_44._m0.w + _290];
        _290 += 256u;
        continue;
    }
    _61[gl_LocalInvocationIndex] = _291;
    threadgroup_barrier(mem_flags::mem_threadgroup);
    for (uint _292 = 128u; _292 > 0u; _292 = _292 >> uint(1))
    {
        if (gl_LocalInvocationIndex < _292)
        {
            _61[gl_LocalInvocationIndex] += _61[gl_LocalInvocationIndex + _292];
        }
        threadgroup_barrier(mem_flags::mem_threadgroup);
    }
    uint _97 = _61[0];
    threadgroup_barrier(mem_flags::mem_threadgroup);
    bool _102 = gl_GlobalInvocationID.x < _44._m0.x;
    bool _116;
    if (_102)
    {
        _116 = (_108._m0[gl_GlobalInvocationID.x] & _44._m0.z) != 0u;
    }
    else
    {
        _116 = _102;
    }
    _61[gl_LocalInvocationIndex] = uint(_116);
    threadgroup_barrier(mem_flags::mem_threadgroup);
    for (uint _293 = 1u; _293 < 256u; _293 = _293 << uint(1))
    {
        uint _294;
        if (gl_LocalInvocationIndex >= _293)
        {
            _294 = _61[gl_LocalInvocationIndex - _293];
        }
        else
        {
            _294 = 0u;
        }
        threadgroup_barrier(mem_flags::mem_threadgroup);
        _61[gl_LocalInvocationIndex] += _294;
        threadgroup_barrier(mem_flags::mem_threadgroup);
    }
    uint _158 = (_97 + _61[gl_LocalInvocationIndex]) - 1u;
    bool _167;
    if (_116)
    {
        _167 = _158 < _44._m1.x;
    }
    else
    {
        _167 = _116;
    }
    if (_167)
    {
        float4 _306 = _179._m0[gl_GlobalInvocationID.x]._m1;
        uint _197 = 2u * _158;
        _195._m0[_197] = float4(_179._m0[gl_GlobalInvocationID.x]._m0.xyz, 0.0);
        _195._m0[_197 + 1u] = float4(_306.xyz, 0.0);
    }
    if ((gl_WorkGroupID.x == (_44._m0.y - 1u)) && (gl_LocalInvocationIndex == 255u))
    {
        uint _247 = min((min((_97 + _61[gl_LocalInvocationIndex]), _44._m1.x) * _44._m1.y), _44._m1.z);
        uint _255 = _252._m0[7];
        _252._m0[0] = (_247 + 255u) / 256u;
        _252._m0[1] = 1u;
        _252._m0[2] = 1u;
        _252._m0[4] = _255;
        _252._m0[5] = _247;
        _252._m0[6] = _252._m0[8];
        _252._m0[7] = (_255 + _247) % _44._m1.z;
        _252._m0[8] += _247;
    }
}

