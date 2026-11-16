// Generated from mesh_shadow_wind.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: a50fdc58e00ea278
// glsl-fnv1a64: d5080def099eb0fc

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct _32
{
    float4 _m0[8];
    float4 _m1;
    float4 _m2;
    float4 _m3;
    float4 _m4;
};

struct _332
{
    float4x4 _m0;
    float4x4 _m1;
};

struct vertex_main_out
{
    float2 m_364 [[user(locn0)]];
    float4 gl_Position [[position]];
};

struct vertex_main_in
{
    float3 m_340 [[attribute(0)]];
    float2 m_366 [[attribute(2)]];
    float4 m_299 [[attribute(3)]];
    float4 m_301 [[attribute(4)]];
    float4 m_303 [[attribute(5)]];
    float4 m_305 [[attribute(6)]];
};

vertex vertex_main_out vertex_main(vertex_main_in in [[stage_in]], constant _32& _34 [[buffer(2)]], constant _332& _334 [[buffer(15)]])
{
    vertex_main_out out = {};
    float4x4 _327 = float4x4(in.m_299, in.m_301, in.m_303, in.m_305);
    float _439 = fast::max(dot(_34._m2.xyz, in.m_340 - _34._m1.xyz), 0.0);
    float2 _446 = (_327 * float4(_34._m1.xyz, 1.0)).xz;
    float _454 = (dot(_446, _34._m3.xy) * 0.3499999940395355224609375) + (dot(_446, float2(0.829999983310699462890625, -0.569999992847442626953125)) * 1.7000000476837158203125);
    float _475 = 1.0 + (_34._m3.w * (((0.5 + ((0.5 * sin((_34._m4.x * 0.61000001430511474609375) + _454)) * sin((_34._m4.x * 0.23000000417232513427734375) + (_454 * 0.699999988079071044921875)))) * 1.60000002384185791015625) - 0.60000002384185791015625));
    float _496 = (((((_34._m3.z * _475) * (0.75 + (0.25 * sin((_34._m4.x * 1.7000000476837158203125) + (_454 * 1.2999999523162841796875))))) * 0.0599999986588954925537109375) * _439) * _439) * _34._m2.w;
    float3 _504 = transpose(float3x3(float3(in.m_299.xyz), float3(in.m_301.xyz), float3(in.m_303.xyz))) * float3(_34._m3.x, 0.0, _34._m3.y);
    float _507 = dot(_504, _504);
    float3 _589;
    if (_507 > 9.9999999600419720025001879548654e-13)
    {
        _589 = _504 * rsqrt(_507);
    }
    else
    {
        _589 = float3(0.0);
    }
    float _534 = dot(in.m_340, float3(3.099999904632568359375, 2.2999999523162841796875, 2.7000000476837158203125));
    float _545 = _534 * 1.7000000476837158203125;
    out.gl_Position = _334._m1 * (_327 * float4(in.m_340 + (((_589 * _496) - (_34._m2.xyz * (((0.5 * _496) * _496) / fast::max(_439, 0.001000000047497451305389404296875)))) + (float3(sin((_534 * 1.2999999523162841796875) + 1.0), cos(_534 * 0.89999997615814208984375), sin(_545 + 2.0)) * (((((_34._m1.w * _34._m3.z) * (0.60000002384185791015625 + (0.4000000059604644775390625 * _475))) * fast::clamp(_439 * 3.0, 0.0, 1.0)) * 0.0199999995529651641845703125) * (sin(((_34._m4.x * 7.30000019073486328125) + _534) + _454) + (0.5 * sin(((_34._m4.x * 11.1000003814697265625) + _545) + (_454 * 2.099999904632568359375))))))), 1.0));
    out.gl_Position.y = -out.gl_Position.y;
    out.m_364 = in.m_366;
    out.gl_Position.y = -(out.gl_Position.y);    // Invert Y-axis for Metal
    return out;
}

