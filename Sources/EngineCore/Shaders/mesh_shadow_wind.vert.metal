// Generated from mesh_shadow_wind.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 19e72d3438b37467
// glsl-fnv1a64: 6409d66e3301d2f8

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

struct _354
{
    float4x4 _m0;
    float4x4 _m1;
};

struct vertex_main_out
{
    float2 m_370 [[user(locn0)]];
    float4 gl_Position [[position]];
};

struct vertex_main_in
{
    float3 m_335 [[attribute(0)]];
    float2 m_372 [[attribute(2)]];
    float4 m_303 [[attribute(3)]];
    float4 m_305 [[attribute(4)]];
    float4 m_307 [[attribute(5)]];
    float4 m_309 [[attribute(6)]];
};

vertex vertex_main_out vertex_main(vertex_main_in in [[stage_in]], constant _32& _34 [[buffer(2)]], constant _354& _356 [[buffer(15)]])
{
    vertex_main_out out = {};
    float4x4 _331 = float4x4(in.m_303, in.m_305, in.m_307, in.m_309);
    float _448 = fast::max(dot(_34._m2.xyz, spvFSub(in.m_335, _34._m1.xyz)), 0.0);
    float2 _455 = (_331 * float4(_34._m1.xyz, 1.0)).xz;
    float _463 = spvFAdd(spvFMul(dot(_455, _34._m3.xy), 0.3499999940395355224609375), spvFMul(dot(_455, float2(0.829999983310699462890625, -0.569999992847442626953125)), 1.7000000476837158203125));
    float _484 = spvFAdd(1.0, spvFMul(_34._m3.w, spvFSub(spvFMul(spvFAdd(0.5, spvFMul(spvFMul(0.5, sin(spvFAdd(spvFMul(_34._m4.x, 0.61000001430511474609375), _463))), sin(spvFAdd(spvFMul(_34._m4.x, 0.23000000417232513427734375), spvFMul(_463, 0.699999988079071044921875))))), 1.60000002384185791015625), 0.60000002384185791015625)));
    float _505 = spvFMul(spvFMul(spvFMul(spvFMul(spvFMul(spvFMul(_34._m3.z, _484), spvFAdd(0.75, spvFMul(0.25, sin(spvFAdd(spvFMul(_34._m4.x, 1.7000000476837158203125), spvFMul(_463, 1.2999999523162841796875)))))), 0.0599999986588954925537109375), _448), _448), _34._m2.w);
    float3 _513 = spvFMulMatrixVector(transpose(float3x3(float3(in.m_303.xyz), float3(in.m_305.xyz), float3(in.m_307.xyz))), float3(_34._m3.x, 0.0, _34._m3.y));
    float _516 = dot(_513, _513);
    float3 _599;
    if (_516 > 9.9999999600419720025001879548654e-13)
    {
        _599 = _513 * rsqrt(_516);
    }
    else
    {
        _599 = float3(0.0);
    }
    float _543 = dot(in.m_335, float3(3.099999904632568359375, 2.2999999523162841796875, 2.7000000476837158203125));
    float _554 = spvFMul(_543, 1.7000000476837158203125);
    out.gl_Position = _356._m1 * spvFMulMatrixVector(_331, float4(spvFAdd(in.m_335, spvFAdd(spvFSub(_599 * _505, _34._m2.xyz * (spvFMul(spvFMul(0.5, _505), _505) / fast::max(_448, 0.001000000047497451305389404296875))), float3(sin(spvFAdd(spvFMul(_543, 1.2999999523162841796875), 1.0)), cos(spvFMul(_543, 0.89999997615814208984375)), sin(spvFAdd(_554, 2.0))) * spvFMul(spvFMul(spvFMul(spvFMul(spvFMul(_34._m1.w, _34._m3.z), spvFAdd(0.60000002384185791015625, spvFMul(0.4000000059604644775390625, _484))), fast::clamp(spvFMul(_448, 3.0), 0.0, 1.0)), 0.0199999995529651641845703125), spvFAdd(sin(spvFAdd(spvFAdd(spvFMul(_34._m4.x, 7.30000019073486328125), _543), _463)), spvFMul(0.5, sin(spvFAdd(spvFAdd(spvFMul(_34._m4.x, 11.1000003814697265625), _554), spvFMul(_463, 2.099999904632568359375)))))))), 1.0));
    out.gl_Position.y = -out.gl_Position.y;
    out.m_370 = in.m_372;
    out.gl_Position.y = -(out.gl_Position.y);    // Invert Y-axis for Metal
    return out;
}

