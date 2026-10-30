// Generated from lit.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 3d0088b72cef6f52
// glsl-fnv1a64: 882ebf60aa24c3fa

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct _113
{
    float4x4 _m0;
    float4x4 _m1;
    float4 _m2;
    float4 _m3;
    float4 _m4;
    float4 _m5;
    float4x4 _m6;
    float4x4 _m7;
    float4 _m8;
};

struct vertex_main_out
{
    float3 m_238 [[user(locn0)]];
    float3 m_241 [[user(locn1)]];
    float4 m_247 [[user(locn2)]];
    float4 m_252 [[user(locn3)]];
    float4 m_250 [[user(locn4)]];
    float4 m_258 [[user(locn5)]];
    float4 m_264 [[user(locn6)]];
    float4 gl_Position [[position]];
};

struct vertex_main_in
{
    float3 m_98 [[attribute(0)]];
    float3 m_101 [[attribute(1)]];
    float4 m_66 [[attribute(2)]];
    float4 m_68 [[attribute(3)]];
    float4 m_70 [[attribute(4)]];
    float4 m_72 [[attribute(5)]];
    float4 m_248 [[attribute(6)]];
    float4 m_103 [[attribute(7)]];
};

vertex vertex_main_out vertex_main(vertex_main_in in [[stage_in]], constant _113& _115 [[buffer(15)]])
{
    vertex_main_out out = {};
    float4x4 _94 = float4x4(in.m_66, in.m_68, in.m_70, in.m_72);
    float4 _346;
    float3 _347;
    float4 _348;
    if (in.m_103.w > 0.0)
    {
        float _277 = _115._m3.w + in.m_103.z;
        float _278 = cos(_277);
        float _283 = sin(_277);
        float3x3 _292 = float3x3(float3(_278, 0.0, -_283), float3(0.0, 1.0, 0.0), float3(_283, 0.0, _278));
        float _311 = _115._m8.x + in.m_103.z;
        float _312 = cos(_311);
        float _317 = sin(_311);
        _348 = (_94 * float4(float3x3(float3(_312, 0.0, -_317), float3(0.0, 1.0, 0.0), float3(_317, 0.0, _312)) * in.m_98, 1.0)) + float4(0.0, sin((_115._m8.x * 2.0) + in.m_103.z) * in.m_103.w, 0.0, 0.0);
        _347 = _292 * in.m_101;
        _346 = (_94 * float4(_292 * in.m_98, 1.0)) + float4(0.0, sin((_115._m3.w * 2.0) + in.m_103.z) * in.m_103.w, 0.0, 0.0);
    }
    else
    {
        float4 _180 = _94 * float4(in.m_98, 1.0);
        _348 = _180;
        _347 = in.m_101;
        _346 = _180;
    }
    out.gl_Position = _115._m0 * _346;
    out.gl_Position.y = -out.gl_Position.y;
    out.m_238 = _346.xyz;
    out.m_241 = float3x3(float3(in.m_66.xyz), float3(in.m_68.xyz), float3(in.m_70.xyz)) * (_347 / float3(dot(in.m_66.xyz, in.m_66.xyz), dot(in.m_68.xyz, in.m_68.xyz), dot(in.m_70.xyz, in.m_70.xyz)));
    out.m_247 = in.m_248;
    out.m_250 = in.m_103;
    out.m_252 = _115._m1 * _346;
    out.m_258 = _115._m6 * _346;
    out.m_264 = _115._m7 * _348;
    out.gl_Position.y = -(out.gl_Position.y);    // Invert Y-axis for Metal
    return out;
}

