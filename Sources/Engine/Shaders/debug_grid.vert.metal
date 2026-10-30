// Generated from debug_grid.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: c20cafa6caa0cedf
// glsl-fnv1a64: 7ed243f89614a799

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

struct _30
{
    float4x4 _m0;
    float4 _m1;
    float4 _m2;
    float4 _m3;
    float4 _m4;
    float4 _m5;
    float4 _m6;
};

constant spvUnsafeArray<float2, 6> _19 = spvUnsafeArray<float2, 6>({ float2(-1.0), float2(1.0, -1.0), float2(1.0), float2(-1.0), float2(1.0), float2(-1.0, 1.0) });

struct vertex_main_out
{
    float3 m_41 [[user(locn0)]];
    float4 gl_Position [[position]];
};

vertex vertex_main_out vertex_main(constant _30& _32 [[buffer(2)]], uint gl_VertexIndex [[vertex_id]])
{
    vertex_main_out out = {};
    float2 _38 = _19[int(gl_VertexIndex)] * _32._m2.z;
    out.m_41 = float3(_32._m1.x + _38.x, _32._m1.w, _32._m1.z + _38.y);
    out.gl_Position = _32._m0 * float4(out.m_41, 1.0);
    out.gl_Position.y = -out.gl_Position.y;
    out.gl_Position.y = -(out.gl_Position.y);    // Invert Y-axis for Metal
    return out;
}

