// Generated from mesh_wind.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: acfad44aa5689380
// glsl-fnv1a64: 81f2cafcc0851775

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

struct _440
{
    float4x4 _m0;
    float4x4 _m1;
    float4x4 _m2;
    float4x4 _m3;
};

struct vertex_main_out
{
    float3 m_456 [[user(locn0)]];
    float3 m_459 [[user(locn1)]];
    float2 m_467 [[user(locn2)]];
    float4 m_471 [[user(locn3)]];
    float4 m_474 [[user(locn5)]];
    float4 m_477 [[user(locn6)]];
    float4 m_482 [[user(locn7)]];
    float4 m_487 [[user(locn8)]];
    float4 gl_Position [[position]];
};

struct vertex_main_in
{
    float3 m_369 [[attribute(0)]];
    float3 m_461 [[attribute(1)]];
    float2 m_469 [[attribute(2)]];
    float4 m_299 [[attribute(3)]];
    float4 m_301 [[attribute(4)]];
    float4 m_303 [[attribute(5)]];
    float4 m_305 [[attribute(6)]];
    float4 m_329 [[attribute(7)]];
    float4 m_331 [[attribute(8)]];
    float4 m_333 [[attribute(9)]];
    float4 m_335 [[attribute(10)]];
    float4 m_472 [[attribute(11)]];
    float4 m_475 [[attribute(12)]];
    float4 m_504 [[attribute(13)]];
};

vertex vertex_main_out vertex_main(vertex_main_in in [[stage_in]], constant _32& _34 [[buffer(2)]], constant _440& _442 [[buffer(15)]])
{
    vertex_main_out out = {};
    float4x4 _327 = float4x4(in.m_299, in.m_301, in.m_303, in.m_305);
    float4x4 _357 = float4x4(in.m_329, in.m_331, in.m_333, in.m_335);
    float4 _531 = float4(_34._m1.xyz, 1.0);
    float3x3 _556 = float3x3(float3(in.m_299.xyz), float3(in.m_301.xyz), float3(in.m_303.xyz));
    float _588 = fast::max(dot(_34._m2.xyz, in.m_369 - _34._m1.xyz), 0.0);
    float2 _595 = (_327 * _531).xz;
    float _603 = (dot(_595, _34._m3.xy) * 0.3499999940395355224609375) + (dot(_595, float2(0.829999983310699462890625, -0.569999992847442626953125)) * 1.7000000476837158203125);
    float _624 = 1.0 + (_34._m3.w * (((0.5 + ((0.5 * sin((_34._m4.x * 0.61000001430511474609375) + _603)) * sin((_34._m4.x * 0.23000000417232513427734375) + (_603 * 0.699999988079071044921875)))) * 1.60000002384185791015625) - 0.60000002384185791015625));
    float _645 = (((((_34._m3.z * _624) * (0.75 + (0.25 * sin((_34._m4.x * 1.7000000476837158203125) + (_603 * 1.2999999523162841796875))))) * 0.0599999986588954925537109375) * _588) * _588) * _34._m2.w;
    float3 _652 = float3(_34._m3.x, 0.0, _34._m3.y);
    float3 _653 = transpose(_556) * _652;
    float _656 = dot(_653, _653);
    float3 _959;
    if (_656 > 9.9999999600419720025001879548654e-13)
    {
        _959 = _653 * rsqrt(_656);
    }
    else
    {
        _959 = float3(0.0);
    }
    float _678 = fast::max(_588, 0.001000000047497451305389404296875);
    float _683 = dot(in.m_369, float3(3.099999904632568359375, 2.2999999523162841796875, 2.7000000476837158203125));
    float _694 = _683 * 1.7000000476837158203125;
    float _705 = _34._m1.w * _34._m3.z;
    float _712 = fast::clamp(_588 * 3.0, 0.0, 1.0);
    float3 _729 = float3(sin((_683 * 1.2999999523162841796875) + 1.0), cos(_683 * 0.89999997615814208984375), sin(_694 + 2.0));
    float2 _811 = (_357 * _531).xz;
    float _819 = (dot(_811, _34._m3.xy) * 0.3499999940395355224609375) + (dot(_811, float2(0.829999983310699462890625, -0.569999992847442626953125)) * 1.7000000476837158203125);
    float _840 = 1.0 + (_34._m3.w * (((0.5 + ((0.5 * sin((_34._m4.y * 0.61000001430511474609375) + _819)) * sin((_34._m4.y * 0.23000000417232513427734375) + (_819 * 0.699999988079071044921875)))) * 1.60000002384185791015625) - 0.60000002384185791015625));
    float _861 = (((((_34._m3.z * _840) * (0.75 + (0.25 * sin((_34._m4.y * 1.7000000476837158203125) + (_819 * 1.2999999523162841796875))))) * 0.0599999986588954925537109375) * _588) * _588) * _34._m2.w;
    float3 _869 = transpose(float3x3(float3(in.m_329.xyz), float3(in.m_331.xyz), float3(in.m_333.xyz))) * _652;
    float _872 = dot(_869, _869);
    float3 _960;
    if (_872 > 9.9999999600419720025001879548654e-13)
    {
        _960 = _869 * rsqrt(_872);
    }
    else
    {
        _960 = float3(0.0);
    }
    float4 _395 = _327 * float4(in.m_369 + (((_959 * _645) - (_34._m2.xyz * (((0.5 * _645) * _645) / _678))) + (_729 * ((((_705 * (0.60000002384185791015625 + (0.4000000059604644775390625 * _624))) * _712) * 0.0199999995529651641845703125) * (sin(((_34._m4.x * 7.30000019073486328125) + _683) + _603) + (0.5 * sin(((_34._m4.x * 11.1000003814697265625) + _694) + (_603 * 2.099999904632568359375))))))), 1.0);
    float3 _413 = cross(in.m_299.xyz, in.m_301.xyz);
    float _435 = (dot(_413, in.m_303.xyz) < 0.0) ? (-1.0) : 1.0;
    out.gl_Position = _442._m0 * _395;
    out.gl_Position.y = -out.gl_Position.y;
    out.m_456 = _395.xyz;
    out.m_459 = (float3x3(cross(in.m_301.xyz, in.m_303.xyz), cross(in.m_303.xyz, in.m_299.xyz), _413) * in.m_461) * _435;
    out.m_467 = in.m_469;
    out.m_471 = in.m_472;
    out.m_474 = in.m_475;
    out.m_477 = _442._m2 * _395;
    out.m_482 = _442._m3 * (_357 * float4(in.m_369 + (((_960 * _861) - (_34._m2.xyz * (((0.5 * _861) * _861) / _678))) + (_729 * ((((_705 * (0.60000002384185791015625 + (0.4000000059604644775390625 * _840))) * _712) * 0.0199999995529651641845703125) * (sin(((_34._m4.y * 7.30000019073486328125) + _683) + _819) + (0.5 * sin(((_34._m4.y * 11.1000003814697265625) + _694) + (_819 * 2.099999904632568359375))))))), 1.0));
    out.m_487 = float4(_556 * in.m_504.xyz, in.m_504.w * _435);
    out.gl_Position.y = -(out.gl_Position.y);    // Invert Y-axis for Metal
    return out;
}

