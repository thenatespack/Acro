// Generated from outline_mask_skinned.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: f2ee3bc3241f131c
// glsl-fnv1a64: f0de2dcd52e191e9

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

struct _47
{
    float4 _m0[8];
    float4 _m1[384];
    float4 _m2[384];
};

struct _148
{
    float4x4 _m0;
    float4 _m1;
};

struct vertex_main_out
{
    float4 gl_Position [[position]];
};

struct vertex_main_in
{
    float3 m_157 [[attribute(0)]];
    float4 m_116 [[attribute(3)]];
    float4 m_118 [[attribute(4)]];
    float4 m_120 [[attribute(5)]];
    float4 m_122 [[attribute(6)]];
    float4 m_33 [[attribute(14)]];
    float4 m_55 [[attribute(15)]];
};

vertex vertex_main_out vertex_main(vertex_main_in in [[stage_in]], constant _47& _49 [[buffer(2)]], constant _148& _150 [[buffer(16)]])
{
    vertex_main_out out = {};
    float4 _254;
    float4 _255;
    float4 _256;
    _256 = float4(0.0);
    _255 = float4(0.0);
    _254 = float4(0.0);
    for (int _253 = 0; _253 < 4; )
    {
        int _194 = int(in.m_33[_253]) * 3;
        _256 = spvFAdd(_256, _49._m1[_194 + 2] * in.m_55[_253]);
        _255 = spvFAdd(_255, _49._m1[_194 + 1] * in.m_55[_253]);
        _254 = spvFAdd(_254, _49._m1[_194] * in.m_55[_253]);
        _253++;
        continue;
    }
    out.gl_Position = spvFMulMatrixVector(_150._m0, spvFMulMatrixVector(spvFMulMatrixMatrix(float4x4(in.m_116, in.m_118, in.m_120, in.m_122), transpose(float4x4(_254, _255, _256, float4(0.0, 0.0, 0.0, 1.0)))), float4(in.m_157, 1.0)));
    out.gl_Position.y = -out.gl_Position.y;
    out.gl_Position.y = -(out.gl_Position.y);    // Invert Y-axis for Metal
    return out;
}

