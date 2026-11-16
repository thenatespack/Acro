// Generated from mesh_shadow_wind.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 038cf735f5ad9d5c
// glsl-fnv1a64: 101acdb1cd8da430

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct _24
{
    float4 _m0[8];
    float4 _m1;
    float4 _m2;
    float4 _m3;
    float4 _m4;
};

struct _325
{
    float4x4 _m0;
    float4x4 _m1;
};

struct vertex_main_out
{
    float2 m_347 [[user(locn0)]];
    float4 gl_Position [[position]];
};

struct vertex_main_in
{
    float3 m_288 [[attribute(0)]];
    float2 m_349 [[attribute(2)]];
    float4 m_246 [[attribute(3)]];
    float4 m_248 [[attribute(4)]];
    float4 m_250 [[attribute(5)]];
    float4 m_252 [[attribute(6)]];
};

vertex vertex_main_out vertex_main(vertex_main_in in [[stage_in]], constant _24& _26 [[buffer(2)]], constant _325& _327 [[buffer(15)]])
{
    vertex_main_out out = {};
    float4x4 _274 = float4x4(in.m_246, in.m_248, in.m_250, in.m_252);
    float _377 = fast::max(dot(_26._m2.xyz, in.m_288 - _26._m1.xyz), 0.0);
    float2 _384 = (_274 * float4(_26._m1.xyz, 1.0)).xz;
    float _392 = (dot(_384, _26._m3.xy) * 0.3499999940395355224609375) + (dot(_384, float2(0.829999983310699462890625, -0.569999992847442626953125)) * 1.7000000476837158203125);
    float _413 = 1.0 + (_26._m3.w * (((0.5 + ((0.5 * sin((_26._m4.x * 0.61000001430511474609375) + _392)) * sin((_26._m4.x * 0.23000000417232513427734375) + (_392 * 0.699999988079071044921875)))) * 1.60000002384185791015625) - 0.60000002384185791015625));
    float _434 = (((((_26._m3.z * _413) * (0.75 + (0.25 * sin((_26._m4.x * 1.7000000476837158203125) + (_392 * 1.2999999523162841796875))))) * 0.0599999986588954925537109375) * _377) * _377) * _26._m2.w;
    float3 _442 = transpose(float3x3(float3(in.m_246.xyz), float3(in.m_248.xyz), float3(in.m_250.xyz))) * float3(_26._m3.x, 0.0, _26._m3.y);
    float _445 = dot(_442, _442);
    float3 _524;
    if (_445 > 9.9999999600419720025001879548654e-13)
    {
        _524 = _442 * rsqrt(_445);
    }
    else
    {
        _524 = float3(0.0);
    }
    float _472 = dot(in.m_288, float3(3.099999904632568359375, 2.2999999523162841796875, 2.7000000476837158203125));
    float _483 = _472 * 1.7000000476837158203125;
    out.gl_Position = _327._m1 * (_274 * float4(in.m_288 + (((_524 * _434) - (_26._m2.xyz * (((0.5 * _434) * _434) / fast::max(_377, 0.001000000047497451305389404296875)))) + (float3(sin((_472 * 1.2999999523162841796875) + 1.0), cos(_472 * 0.89999997615814208984375), sin(_483 + 2.0)) * (((((_26._m1.w * _26._m3.z) * (0.60000002384185791015625 + (0.4000000059604644775390625 * _413))) * fast::clamp(_377 * 3.0, 0.0, 1.0)) * 0.0199999995529651641845703125) * (sin(((_26._m4.x * 7.30000019073486328125) + _472) + _392) + (0.5 * sin(((_26._m4.x * 11.1000003814697265625) + _483) + (_392 * 2.099999904632568359375))))))), 1.0));
    out.gl_Position.y = -out.gl_Position.y;
    out.m_347 = in.m_349;
    out.gl_Position.y = -(out.gl_Position.y);    // Invert Y-axis for Metal
    return out;
}

