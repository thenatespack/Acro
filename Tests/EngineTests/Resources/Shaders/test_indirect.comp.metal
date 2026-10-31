// Generated from test_indirect.comp by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 54281fc0d25ce886
// glsl-fnv1a64: c9fc2abcc54a40d5

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

struct _13
{
    float _m0;
    float _m1;
};

struct _54
{
    float4 _m0[1];
};

struct _71
{
    uint _m0[1];
};

constant uint3 gl_WorkGroupSize [[maybe_unused]] = uint3(1u);

kernel void compute_main(constant _13& _15 [[buffer(16)]], device _54& _56 [[buffer(20)]], device _71& _73 [[buffer(21)]])
{
    float2 _22 = float2(_15._m0, -1.0);
    float2 _30 = float2(_15._m1, 1.0);
    spvUnsafeArray<float2, 6> _40 = spvUnsafeArray<float2, 6>({ _22, float2(_15._m1, -1.0), _30, _22, _30, float2(_15._m0, 1.0) });
    spvUnsafeArray<float2, 6> _12 = _40;
    for (int _85 = 0; _85 < 6; )
    {
        _56._m0[_85] = float4(_12[_85], 0.5, 1.0);
        _85++;
        continue;
    }
    _73._m0[0] = 6u;
    _73._m0[1] = 1u;
    _73._m0[2] = 0u;
    _73._m0[3] = 0u;
}

