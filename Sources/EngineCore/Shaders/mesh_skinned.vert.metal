// Generated from mesh_skinned.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: acd4e7dc470d319a
// glsl-fnv1a64: d5e47112554e85b0

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

struct _49
{
    float4 _m0[8];
    float4 _m1[384];
    float4 _m2[384];
};

struct _324
{
    float4x4 _m0;
    float4x4 _m1;
    float4x4 _m2;
    float4x4 _m3;
};

struct vertex_main_out
{
    float3 m_346 [[user(locn0)]];
    float3 m_349 [[user(locn1)]];
    float2 m_358 [[user(locn2)]];
    float4 m_362 [[user(locn3)]];
    float3 m_412 [[user(locn4)]];
    float4 m_365 [[user(locn5)]];
    float4 m_378 [[user(locn6)]];
    float4 m_380 [[user(locn7)]];
    float4 m_382 [[user(locn8)]];
    float4 gl_Position [[position]];
};

struct vertex_main_in
{
    float3 m_260 [[attribute(0)]];
    float3 m_351 [[attribute(1)]];
    float2 m_360 [[attribute(2)]];
    float4 m_193 [[attribute(3)]];
    float4 m_195 [[attribute(4)]];
    float4 m_197 [[attribute(5)]];
    float4 m_199 [[attribute(6)]];
    float4 m_225 [[attribute(7)]];
    float4 m_227 [[attribute(8)]];
    float4 m_229 [[attribute(9)]];
    float4 m_231 [[attribute(10)]];
    float4 m_363 [[attribute(11)]];
    float4 m_366 [[attribute(12)]];
    float4 m_399 [[attribute(13)]];
    float4 m_35 [[attribute(14)]];
    float4 m_57 [[attribute(15)]];
};

vertex vertex_main_out vertex_main(vertex_main_in in [[stage_in]], constant _49& _51 [[buffer(2)]], constant _324& _326 [[buffer(15)]])
{
    vertex_main_out out = {};
    float4 _568;
    float4 _569;
    float4 _570;
    _570 = float4(0.0);
    _569 = float4(0.0);
    _568 = float4(0.0);
    for (int _567 = 0; _567 < 4; )
    {
        int _430 = int(in.m_35[_567]) * 3;
        _570 = spvFAdd(_570, _51._m1[_430 + 2] * in.m_57[_567]);
        _569 = spvFAdd(_569, _51._m1[_430 + 1] * in.m_57[_567]);
        _568 = spvFAdd(_568, _51._m1[_430] * in.m_57[_567]);
        _567++;
        continue;
    }
    float4x4 _223 = spvFMulMatrixMatrix(float4x4(in.m_193, in.m_195, in.m_197, in.m_199), transpose(float4x4(_568, _569, _570, float4(0.0, 0.0, 0.0, 1.0))));
    float4 _572;
    float4 _573;
    float4 _574;
    _574 = float4(0.0);
    _573 = float4(0.0);
    _572 = float4(0.0);
    for (int _571 = 0; _571 < 4; )
    {
        int _505 = int(in.m_35[_571]) * 3;
        _574 = spvFAdd(_574, _51._m2[_505 + 2] * in.m_57[_571]);
        _573 = spvFAdd(_573, _51._m2[_505 + 1] * in.m_57[_571]);
        _572 = spvFAdd(_572, _51._m2[_505] * in.m_57[_571]);
        _571++;
        continue;
    }
    float4 _265 = float4(in.m_260, 1.0);
    float4 _266 = spvFMulMatrixVector(_223, _265);
    float4 _278 = _223[0];
    float3 _279 = _278.xyz;
    float4 _282 = _223[1];
    float3 _283 = _282.xyz;
    float4 _286 = _223[2];
    float3 _287 = _286.xyz;
    float3 _299 = cross(_279, _283);
    float _322 = (dot(_299, _287) < 0.0) ? (-1.0) : 1.0;
    out.gl_Position = spvFMulMatrixVector(_326._m0, _266);
    out.gl_Position.y = -out.gl_Position.y;
    out.m_346 = _266.xyz;
    out.m_349 = (float3x3(cross(_283, _287), cross(_287, _279), _299) * in.m_351) * _322;
    out.m_358 = in.m_360;
    out.m_362 = in.m_363;
    out.m_365 = in.m_366;
    out.m_378 = spvFMulMatrixVector(_326._m2, _266);
    out.m_380 = spvFMulMatrixVector(_326._m3, spvFMulMatrixVector(spvFMulMatrixMatrix(float4x4(in.m_225, in.m_227, in.m_229, in.m_231), transpose(float4x4(_572, _573, _574, float4(0.0, 0.0, 0.0, 1.0)))), _265));
    out.m_382 = float4(float3x3(float3(_278.xyz), float3(_282.xyz), float3(_286.xyz)) * in.m_399.xyz, in.m_399.w * _322);
    out.m_412 = in.m_260;
    out.gl_Position.y = -(out.gl_Position.y);    // Invert Y-axis for Metal
    return out;
}

