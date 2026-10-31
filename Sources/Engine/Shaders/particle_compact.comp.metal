// Generated from particle_compact.comp by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 28a77012f2101ae6
// glsl-fnv1a64: bb641916ba5e9e44

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

struct _97
{
    float4x4 _m0;
    float4 _m1;
    float4 _m2;
    float4 _m3;
    float4 _m4;
    float4 _m5;
    float4 _m6;
    float4 _m7;
    float4 _m8;
    uint4 _m9;
    uint4 _m10;
    float4 _m11;
};

struct _98
{
    _97 _m0;
};

struct _108
{
    float4 _m0;
    float4 _m1;
    float4 _m2;
};

struct _110
{
    _108 _m0[1];
};

struct _161
{
    uint _m0[1];
};

constant uint3 gl_WorkGroupSize [[maybe_unused]] = uint3(256u, 1u, 1u);

kernel void compute_main(constant _98& _100 [[buffer(2)]], device _110& _112 [[buffer(20)]], device _36& _38 [[buffer(21)]], device _161& _163 [[buffer(22)]], uint gl_LocalInvocationIndex [[thread_index_in_threadgroup]], uint3 gl_WorkGroupID [[threadgroup_position_in_grid]], uint3 gl_GlobalInvocationID [[thread_position_in_grid]])
{
    threadgroup spvUnsafeArray<uint, 256> _54;
    uint _197;
    _197 = 0u;
    for (uint _196 = gl_LocalInvocationIndex; _196 < gl_WorkGroupID.x; )
    {
        _197 += _38._m0[4u + _196];
        _196 += 256u;
        continue;
    }
    _54[gl_LocalInvocationIndex] = _197;
    threadgroup_barrier(mem_flags::mem_threadgroup);
    for (uint _198 = 128u; _198 > 0u; _198 = _198 >> uint(1))
    {
        if (gl_LocalInvocationIndex < _198)
        {
            _54[gl_LocalInvocationIndex] += _54[gl_LocalInvocationIndex + _198];
        }
        threadgroup_barrier(mem_flags::mem_threadgroup);
    }
    uint _90 = _54[0];
    threadgroup_barrier(mem_flags::mem_threadgroup);
    bool _105 = gl_GlobalInvocationID.x < _100._m0._m10.x;
    bool _120;
    if (_105)
    {
        _120 = ((device float*)&_112._m0[gl_GlobalInvocationID.x]._m1)[3u] > 0.0;
    }
    else
    {
        _120 = _105;
    }
    _54[gl_LocalInvocationIndex] = uint(_120);
    threadgroup_barrier(mem_flags::mem_threadgroup);
    for (uint _199 = 1u; _199 < 256u; _199 = _199 << uint(1))
    {
        uint _200;
        if (gl_LocalInvocationIndex >= _199)
        {
            _200 = _54[gl_LocalInvocationIndex - _199];
        }
        else
        {
            _200 = 0u;
        }
        threadgroup_barrier(mem_flags::mem_threadgroup);
        _54[gl_LocalInvocationIndex] += _200;
        threadgroup_barrier(mem_flags::mem_threadgroup);
    }
    if (_120)
    {
        _163._m0[(_90 + _54[gl_LocalInvocationIndex]) - 1u] = gl_GlobalInvocationID.x;
    }
    if ((gl_WorkGroupID.x == (_100._m0._m10.y - 1u)) && (gl_LocalInvocationIndex == 255u))
    {
        _38._m0[0] = 6u;
        _38._m0[1] = _90 + _54[gl_LocalInvocationIndex];
        _38._m0[2] = 0u;
        _38._m0[3] = 0u;
    }
}

