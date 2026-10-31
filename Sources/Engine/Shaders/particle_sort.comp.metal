// Generated from particle_sort.comp by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: f9b0771d423d8e89
// glsl-fnv1a64: 8812e92cd0dcc27f

#pragma clang diagnostic ignored "-Wunused-variable"
#pragma clang diagnostic ignored "-Wmissing-prototypes"
#pragma clang diagnostic ignored "-Wmissing-braces"

#include <metal_stdlib>
#include <simd/simd.h>
#include <metal_atomic>

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

struct _58
{
    float4 _m0;
    uint4 _m1;
};

struct _95
{
    float4 _m0;
    float4 _m1;
    float4 _m2;
};

struct _97
{
    _95 _m0[1];
};

struct _236
{
    uint _m0[1];
};

struct _252
{
    uint _m0[1];
};

constant uint3 gl_WorkGroupSize [[maybe_unused]] = uint3(256u, 1u, 1u);

kernel void compute_main(constant _58& _60 [[buffer(2)]], device _97& _99 [[buffer(20)]], device _252& _254 [[buffer(21)]], device _236& _238 [[buffer(22)]], uint gl_LocalInvocationIndex [[thread_index_in_threadgroup]])
{
    threadgroup spvUnsafeArray<uint, 2048> _17;
    threadgroup spvUnsafeArray<uint, 2048> _38;
    threadgroup uint _75;
    bool _72 = gl_LocalInvocationIndex == 0u;
    if (_72)
    {
        _75 = 0u;
    }
    threadgroup_barrier(mem_flags::mem_threadgroup);
    for (uint _295 = gl_LocalInvocationIndex; _295 < _60._m1.y; _295 += 256u)
    {
        bool _92 = _295 < _60._m1.x;
        bool _108;
        if (_92)
        {
            _108 = ((device float*)&_99._m0[_295]._m1)[3u] > 0.0;
        }
        else
        {
            _108 = _92;
        }
        uint _309;
        if (_108)
        {
            float4 _117 = _99._m0[_295]._m0;
            uint _130 = atomic_fetch_add_explicit((threadgroup atomic_uint*)&_75, 1u, memory_order_relaxed);
            _309 = ~as_type<uint>(fast::max(length(_117.xyz - _60._m0.xyz), 9.9999999747524270787835121154785e-07));
        }
        else
        {
            _309 = 4294967295u;
        }
        _17[_295] = _309;
        _38[_295] = _295;
    }
    threadgroup_barrier(mem_flags::mem_threadgroup);
    for (uint _296 = 2u; _296 <= _60._m1.y; _296 = _296 << uint(1))
    {
        uint _151 = _296 >> uint(1);
        for (uint _298 = _151; _298 > 0u; _298 = _298 >> uint(1))
        {
            for (uint _300 = gl_LocalInvocationIndex; _300 < _60._m1.y; _300 += 256u)
            {
                uint _172 = _300 ^ _298;
                if (_172 > _300)
                {
                    bool _273 = _17[_172] < _17[_300];
                    bool _294;
                    if (!_273)
                    {
                        bool _282 = _17[_172] == _17[_300];
                        bool _292;
                        if (_282)
                        {
                            _292 = _38[_172] < _38[_300];
                        }
                        else
                        {
                            _292 = _282;
                        }
                        _294 = _292;
                    }
                    else
                    {
                        _294 = _273;
                    }
                    if (_294 == ((_300 & _296) == 0u))
                    {
                        uint _196 = _17[_300];
                        uint _200 = _38[_300];
                        _17[_300] = _17[_172];
                        _38[_300] = _38[_172];
                        _17[_172] = _196;
                        _38[_172] = _200;
                    }
                }
            }
            threadgroup_barrier(mem_flags::mem_threadgroup);
        }
    }
    for (uint _297 = gl_LocalInvocationIndex; _297 < _75; )
    {
        _238._m0[_297] = _38[_297];
        _297 += 256u;
        continue;
    }
    if (_72)
    {
        _254._m0[0] = 6u;
        _254._m0[1] = _75;
        _254._m0[2] = 0u;
        _254._m0[3] = 0u;
    }
}

