// Generated from decal.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 4554a98134ea4f9c
// glsl-fnv1a64: fb6d431f66aaae0b

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

struct _11
{
    float4x4 _m0;
    float4x4 _m1;
    float4x4 _m2;
    float4 _m3;
    float4 _m4;
    float4 _m5;
};

struct _68
{
    float4x4 _m0;
};

constant spvUnsafeArray<float3, 8> _33 = spvUnsafeArray<float3, 8>({ float3(-0.5), float3(0.5, -0.5, -0.5), float3(-0.5, 0.5, -0.5), float3(0.5, 0.5, -0.5), float3(-0.5, -0.5, 0.5), float3(0.5, -0.5, 0.5), float3(-0.5, 0.5, 0.5), float3(0.5) });
constant spvUnsafeArray<int, 36> _43 = spvUnsafeArray<int, 36>({ 1, 3, 7, 1, 7, 5, 0, 4, 6, 0, 6, 2, 2, 6, 7, 2, 7, 3, 0, 1, 5, 0, 5, 4, 4, 5, 7, 4, 7, 6, 0, 2, 3, 0, 3, 1 });

struct vertex_main_out
{
    float4 gl_Position [[position]];
};

vertex vertex_main_out vertex_main(constant _11& _13 [[buffer(2)]], constant _68& _70 [[buffer(15)]], uint gl_VertexIndex [[vertex_id]])
{
    vertex_main_out out = {};
    out.gl_Position = _70._m0 * (_13._m0 * float4(_33[_43[int(gl_VertexIndex)]], 1.0));
    out.gl_Position.y = -out.gl_Position.y;
    out.gl_Position.y = -(out.gl_Position.y);    // Invert Y-axis for Metal
    return out;
}

