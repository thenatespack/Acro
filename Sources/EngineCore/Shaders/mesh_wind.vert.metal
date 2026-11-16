// Generated from mesh_wind.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: eb8e9800b038ec9d
// glsl-fnv1a64: c9098a0d13dff761

#pragma clang diagnostic ignored "-Wmissing-prototypes"

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

template<typename T>
[[clang::optnone]] T spvFMul(T l, T r)
{
    return fma(l, r, T(0));
}

template<typename T, int Cols, int Rows>
[[clang::optnone]] vec<T, Cols> spvFMulVectorMatrix(vec<T, Rows> v, matrix<T, Cols, Rows> m)
{
    vec<T, Cols> res = vec<T, Cols>(0);
    for (uint i = Rows; i > 0; --i)
    {
        vec<T, Cols> tmp(0);
        for (uint j = 0; j < Cols; ++j)
        {
            tmp[j] = m[j][i - 1];
        }
        res = fma(tmp, vec<T, Cols>(v[i - 1]), res);
    }
    return res;
}

template<typename T, int Cols, int Rows>
[[clang::optnone]] vec<T, Rows> spvFMulMatrixVector(matrix<T, Cols, Rows> m, vec<T, Cols> v)
{
    vec<T, Rows> res = vec<T, Rows>(0);
    for (uint i = Cols; i > 0; --i)
    {
        res = fma(m[i - 1], vec<T, Rows>(v[i - 1]), res);
    }
    return res;
}

template<typename T, int LCols, int LRows, int RCols, int RRows>
[[clang::optnone]] matrix<T, RCols, LRows> spvFMulMatrixMatrix(matrix<T, LCols, LRows> l, matrix<T, RCols, RRows> r)
{
    static_assert(LCols == RRows, "column-row configuration mismatch");
    matrix<T, RCols, LRows> res;
    for (uint i = 0; i < RCols; i++)
    {
        vec<T, LRows> tmp(0);
        for (uint j = 0; j < LCols; j++)
        {
            tmp = fma(vec<T, LRows>(r[i][j]), l[j], tmp);
        }
        res[i] = tmp;
    }
    return res;
}

template<typename T>
[[clang::optnone]] T spvFAdd(T l, T r)
{
    return fma(T(1), l, r);
}

template<typename T>
[[clang::optnone]] T spvFSub(T l, T r)
{
    return fma(T(-1), r, l);
}

struct _32
{
    float4 _m0[8];
    float4 _m1;
    float4 _m2;
    float4 _m3;
    float4 _m4;
};

struct _444
{
    float4x4 _m0;
    float4x4 _m1;
    float4x4 _m2;
    float4x4 _m3;
};

struct vertex_main_out
{
    float3 m_460 [[user(locn0)]];
    float3 m_463 [[user(locn1)]];
    float2 m_471 [[user(locn2)]];
    float4 m_475 [[user(locn3)]];
    float4 m_478 [[user(locn5)]];
    float4 m_481 [[user(locn6)]];
    float4 m_486 [[user(locn7)]];
    float4 m_491 [[user(locn8)]];
    float4 gl_Position [[position]];
};

struct vertex_main_in
{
    float3 m_373 [[attribute(0)]];
    float3 m_465 [[attribute(1)]];
    float2 m_473 [[attribute(2)]];
    float4 m_303 [[attribute(3)]];
    float4 m_305 [[attribute(4)]];
    float4 m_307 [[attribute(5)]];
    float4 m_309 [[attribute(6)]];
    float4 m_333 [[attribute(7)]];
    float4 m_335 [[attribute(8)]];
    float4 m_337 [[attribute(9)]];
    float4 m_339 [[attribute(10)]];
    float4 m_476 [[attribute(11)]];
    float4 m_479 [[attribute(12)]];
    float4 m_508 [[attribute(13)]];
};

vertex vertex_main_out vertex_main(vertex_main_in in [[stage_in]], constant _32& _34 [[buffer(2)]], constant _444& _446 [[buffer(15)]])
{
    vertex_main_out out = {};
    float4x4 _331 = float4x4(in.m_303, in.m_305, in.m_307, in.m_309);
    float4x4 _361 = float4x4(in.m_333, in.m_335, in.m_337, in.m_339);
    float4 _536 = float4(_34._m1.xyz, 1.0);
    float3x3 _561 = float3x3(float3(in.m_303.xyz), float3(in.m_305.xyz), float3(in.m_307.xyz));
    float _595 = fast::max(dot(_34._m2.xyz, spvFSub(in.m_373, _34._m1.xyz)), 0.0);
    float2 _602 = (_331 * _536).xz;
    float _610 = spvFAdd(spvFMul(dot(_602, _34._m3.xy), 0.3499999940395355224609375), spvFMul(dot(_602, float2(0.829999983310699462890625, -0.569999992847442626953125)), 1.7000000476837158203125));
    float _631 = spvFAdd(1.0, spvFMul(_34._m3.w, spvFSub(spvFMul(spvFAdd(0.5, spvFMul(spvFMul(0.5, sin(spvFAdd(spvFMul(_34._m4.x, 0.61000001430511474609375), _610))), sin(spvFAdd(spvFMul(_34._m4.x, 0.23000000417232513427734375), spvFMul(_610, 0.699999988079071044921875))))), 1.60000002384185791015625), 0.60000002384185791015625)));
    float _652 = spvFMul(spvFMul(spvFMul(spvFMul(spvFMul(spvFMul(_34._m3.z, _631), spvFAdd(0.75, spvFMul(0.25, sin(spvFAdd(spvFMul(_34._m4.x, 1.7000000476837158203125), spvFMul(_610, 1.2999999523162841796875)))))), 0.0599999986588954925537109375), _595), _595), _34._m2.w);
    float3 _659 = float3(_34._m3.x, 0.0, _34._m3.y);
    float3 _660 = spvFMulMatrixVector(transpose(_561), _659);
    float _663 = dot(_660, _660);
    float3 _971;
    if (_663 > 9.9999999600419720025001879548654e-13)
    {
        _971 = _660 * rsqrt(_663);
    }
    else
    {
        _971 = float3(0.0);
    }
    float _685 = fast::max(_595, 0.001000000047497451305389404296875);
    float _690 = dot(in.m_373, float3(3.099999904632568359375, 2.2999999523162841796875, 2.7000000476837158203125));
    float _701 = spvFMul(_690, 1.7000000476837158203125);
    float _712 = spvFMul(_34._m1.w, _34._m3.z);
    float _719 = fast::clamp(spvFMul(_595, 3.0), 0.0, 1.0);
    float3 _736 = float3(sin(spvFAdd(spvFMul(_690, 1.2999999523162841796875), 1.0)), cos(spvFMul(_690, 0.89999997615814208984375)), sin(spvFAdd(_701, 2.0)));
    float2 _822 = (_361 * _536).xz;
    float _830 = spvFAdd(spvFMul(dot(_822, _34._m3.xy), 0.3499999940395355224609375), spvFMul(dot(_822, float2(0.829999983310699462890625, -0.569999992847442626953125)), 1.7000000476837158203125));
    float _851 = spvFAdd(1.0, spvFMul(_34._m3.w, spvFSub(spvFMul(spvFAdd(0.5, spvFMul(spvFMul(0.5, sin(spvFAdd(spvFMul(_34._m4.y, 0.61000001430511474609375), _830))), sin(spvFAdd(spvFMul(_34._m4.y, 0.23000000417232513427734375), spvFMul(_830, 0.699999988079071044921875))))), 1.60000002384185791015625), 0.60000002384185791015625)));
    float _872 = spvFMul(spvFMul(spvFMul(spvFMul(spvFMul(spvFMul(_34._m3.z, _851), spvFAdd(0.75, spvFMul(0.25, sin(spvFAdd(spvFMul(_34._m4.y, 1.7000000476837158203125), spvFMul(_830, 1.2999999523162841796875)))))), 0.0599999986588954925537109375), _595), _595), _34._m2.w);
    float3 _880 = spvFMulMatrixVector(transpose(float3x3(float3(in.m_333.xyz), float3(in.m_335.xyz), float3(in.m_337.xyz))), _659);
    float _883 = dot(_880, _880);
    float3 _972;
    if (_883 > 9.9999999600419720025001879548654e-13)
    {
        _972 = _880 * rsqrt(_883);
    }
    else
    {
        _972 = float3(0.0);
    }
    float4 _399 = spvFMulMatrixVector(_331, float4(spvFAdd(in.m_373, spvFAdd(spvFSub(_971 * _652, _34._m2.xyz * (spvFMul(spvFMul(0.5, _652), _652) / _685)), _736 * spvFMul(spvFMul(spvFMul(spvFMul(_712, spvFAdd(0.60000002384185791015625, spvFMul(0.4000000059604644775390625, _631))), _719), 0.0199999995529651641845703125), spvFAdd(sin(spvFAdd(spvFAdd(spvFMul(_34._m4.x, 7.30000019073486328125), _690), _610)), spvFMul(0.5, sin(spvFAdd(spvFAdd(spvFMul(_34._m4.x, 11.1000003814697265625), _701), spvFMul(_610, 2.099999904632568359375)))))))), 1.0));
    float3 _417 = cross(in.m_303.xyz, in.m_305.xyz);
    float _439 = (dot(_417, in.m_307.xyz) < 0.0) ? (-1.0) : 1.0;
    out.gl_Position = _446._m0 * _399;
    out.gl_Position.y = -out.gl_Position.y;
    out.m_460 = _399.xyz;
    out.m_463 = (float3x3(cross(in.m_305.xyz, in.m_307.xyz), cross(in.m_307.xyz, in.m_303.xyz), _417) * in.m_465) * _439;
    out.m_471 = in.m_473;
    out.m_475 = in.m_476;
    out.m_478 = in.m_479;
    out.m_481 = _446._m2 * _399;
    out.m_486 = _446._m3 * spvFMulMatrixVector(_361, float4(spvFAdd(in.m_373, spvFAdd(spvFSub(_972 * _872, _34._m2.xyz * (spvFMul(spvFMul(0.5, _872), _872) / _685)), _736 * spvFMul(spvFMul(spvFMul(spvFMul(_712, spvFAdd(0.60000002384185791015625, spvFMul(0.4000000059604644775390625, _851))), _719), 0.0199999995529651641845703125), spvFAdd(sin(spvFAdd(spvFAdd(spvFMul(_34._m4.y, 7.30000019073486328125), _690), _830)), spvFMul(0.5, sin(spvFAdd(spvFAdd(spvFMul(_34._m4.y, 11.1000003814697265625), _701), spvFMul(_830, 2.099999904632568359375)))))))), 1.0));
    out.m_491 = float4(_561 * in.m_508.xyz, in.m_508.w * _439);
    out.gl_Position.y = -(out.gl_Position.y);    // Invert Y-axis for Metal
    return out;
}

