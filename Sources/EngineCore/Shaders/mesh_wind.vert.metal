// Generated from mesh_wind.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 872dc3f15f315794
// glsl-fnv1a64: ac73d45f40701f36

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

struct _452
{
    float4x4 _m0;
    float4x4 _m1;
    float4x4 _m2;
    float4x4 _m3;
};

struct vertex_main_out
{
    float3 m_468 [[user(locn0)]];
    float3 m_471 [[user(locn1)]];
    float2 m_479 [[user(locn2)]];
    float4 m_483 [[user(locn3)]];
    float4 m_486 [[user(locn5)]];
    float4 m_489 [[user(locn6)]];
    float4 m_494 [[user(locn7)]];
    float4 m_499 [[user(locn8)]];
    float4 gl_Position [[position]];
};

struct vertex_main_in
{
    float3 m_338 [[attribute(0)]];
    float3 m_473 [[attribute(1)]];
    float2 m_481 [[attribute(2)]];
    float4 m_246 [[attribute(3)]];
    float4 m_248 [[attribute(4)]];
    float4 m_250 [[attribute(5)]];
    float4 m_252 [[attribute(6)]];
    float4 m_276 [[attribute(7)]];
    float4 m_278 [[attribute(8)]];
    float4 m_280 [[attribute(9)]];
    float4 m_282 [[attribute(10)]];
    float4 m_484 [[attribute(11)]];
    float4 m_487 [[attribute(12)]];
    float4 m_516 [[attribute(13)]];
};

vertex vertex_main_out vertex_main(vertex_main_in in [[stage_in]], constant _24& _26 [[buffer(2)]], constant _452& _454 [[buffer(15)]])
{
    vertex_main_out out = {};
    float4x4 _274 = float4x4(in.m_246, in.m_248, in.m_250, in.m_252);
    float4x4 _304 = float4x4(in.m_276, in.m_278, in.m_280, in.m_282);
    float4 _322 = float4(_26._m1.xyz, 1.0);
    float3x3 _355 = float3x3(float3(in.m_246.xyz), float3(in.m_248.xyz), float3(in.m_250.xyz));
    float _555 = fast::max(dot(_26._m2.xyz, in.m_338 - _26._m1.xyz), 0.0);
    float2 _562 = (_274 * _322).xz;
    float _570 = (dot(_562, _26._m3.xy) * 0.3499999940395355224609375) + (dot(_562, float2(0.829999983310699462890625, -0.569999992847442626953125)) * 1.7000000476837158203125);
    float _591 = 1.0 + (_26._m3.w * (((0.5 + ((0.5 * sin((_26._m4.x * 0.61000001430511474609375) + _570)) * sin((_26._m4.x * 0.23000000417232513427734375) + (_570 * 0.699999988079071044921875)))) * 1.60000002384185791015625) - 0.60000002384185791015625));
    float _612 = (((((_26._m3.z * _591) * (0.75 + (0.25 * sin((_26._m4.x * 1.7000000476837158203125) + (_570 * 1.2999999523162841796875))))) * 0.0599999986588954925537109375) * _555) * _555) * _26._m2.w;
    float3 _619 = float3(_26._m3.x, 0.0, _26._m3.y);
    float3 _620 = transpose(_355) * _619;
    float _623 = dot(_620, _620);
    float3 _875;
    if (_623 > 9.9999999600419720025001879548654e-13)
    {
        _875 = _620 * rsqrt(_623);
    }
    else
    {
        _875 = float3(0.0);
    }
    float _645 = fast::max(_555, 0.001000000047497451305389404296875);
    float _650 = dot(in.m_338, float3(3.099999904632568359375, 2.2999999523162841796875, 2.7000000476837158203125));
    float _661 = _650 * 1.7000000476837158203125;
    float _672 = _26._m1.w * _26._m3.z;
    float _679 = fast::clamp(_555 * 3.0, 0.0, 1.0);
    float3 _696 = float3(sin((_650 * 1.2999999523162841796875) + 1.0), cos(_650 * 0.89999997615814208984375), sin(_661 + 2.0));
    float2 _733 = (_304 * _322).xz;
    float _741 = (dot(_733, _26._m3.xy) * 0.3499999940395355224609375) + (dot(_733, float2(0.829999983310699462890625, -0.569999992847442626953125)) * 1.7000000476837158203125);
    float _762 = 1.0 + (_26._m3.w * (((0.5 + ((0.5 * sin((_26._m4.y * 0.61000001430511474609375) + _741)) * sin((_26._m4.y * 0.23000000417232513427734375) + (_741 * 0.699999988079071044921875)))) * 1.60000002384185791015625) - 0.60000002384185791015625));
    float _783 = (((((_26._m3.z * _762) * (0.75 + (0.25 * sin((_26._m4.y * 1.7000000476837158203125) + (_741 * 1.2999999523162841796875))))) * 0.0599999986588954925537109375) * _555) * _555) * _26._m2.w;
    float3 _791 = transpose(float3x3(float3(in.m_276.xyz), float3(in.m_278.xyz), float3(in.m_280.xyz))) * _619;
    float _794 = dot(_791, _791);
    float3 _876;
    if (_794 > 9.9999999600419720025001879548654e-13)
    {
        _876 = _791 * rsqrt(_794);
    }
    else
    {
        _876 = float3(0.0);
    }
    float4 _406 = _274 * float4(in.m_338 + (((_875 * _612) - (_26._m2.xyz * (((0.5 * _612) * _612) / _645))) + (_696 * ((((_672 * (0.60000002384185791015625 + (0.4000000059604644775390625 * _591))) * _679) * 0.0199999995529651641845703125) * (sin(((_26._m4.x * 7.30000019073486328125) + _650) + _570) + (0.5 * sin(((_26._m4.x * 11.1000003814697265625) + _661) + (_570 * 2.099999904632568359375))))))), 1.0);
    float3 _424 = cross(in.m_246.xyz, in.m_248.xyz);
    float _446 = (dot(_424, in.m_250.xyz) < 0.0) ? (-1.0) : 1.0;
    out.gl_Position = _454._m0 * _406;
    out.gl_Position.y = -out.gl_Position.y;
    out.m_468 = _406.xyz;
    out.m_471 = (float3x3(cross(in.m_248.xyz, in.m_250.xyz), cross(in.m_250.xyz, in.m_246.xyz), _424) * in.m_473) * _446;
    out.m_479 = in.m_481;
    out.m_483 = in.m_484;
    out.m_486 = in.m_487;
    out.m_489 = _454._m2 * _406;
    out.m_494 = _454._m3 * (_304 * float4(in.m_338 + (((_876 * _783) - (_26._m2.xyz * (((0.5 * _783) * _783) / _645))) + (_696 * ((((_672 * (0.60000002384185791015625 + (0.4000000059604644775390625 * _762))) * _679) * 0.0199999995529651641845703125) * (sin(((_26._m4.y * 7.30000019073486328125) + _650) + _741) + (0.5 * sin(((_26._m4.y * 11.1000003814697265625) + _661) + (_741 * 2.099999904632568359375))))))), 1.0));
    out.m_499 = float4(_355 * in.m_516.xyz, in.m_516.w * _446);
    out.gl_Position.y = -(out.gl_Position.y);    // Invert Y-axis for Metal
    return out;
}

