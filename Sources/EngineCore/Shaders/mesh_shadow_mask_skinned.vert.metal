// Generated from mesh_shadow_mask_skinned.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: d29357ae853f142b
// glsl-fnv1a64: 183c28eabc2e461c

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
    float4x4 _m1;
};

struct vertex_main_out
{
    float2 m_180 [[user(locn0)]];
    float4 gl_Position [[position]];
};

struct vertex_main_in
{
    float3 m_157 [[attribute(0)]];
    float2 m_182 [[attribute(2)]];
    float4 m_116 [[attribute(3)]];
    float4 m_118 [[attribute(4)]];
    float4 m_120 [[attribute(5)]];
    float4 m_122 [[attribute(6)]];
    float4 m_33 [[attribute(14)]];
    float4 m_55 [[attribute(15)]];
};

vertex vertex_main_out vertex_main(vertex_main_in in [[stage_in]], constant _47& _49 [[buffer(2)]], constant _148& _150 [[buffer(15)]])
{
    vertex_main_out out = {};
    float4 _260;
    float4 _261;
    float4 _262;
    _262 = float4(0.0);
    _261 = float4(0.0);
    _260 = float4(0.0);
    for (int _259 = 0; _259 < 4; )
    {
        int _200 = int(in.m_33[_259]) * 3;
        _262 = spvFAdd(_262, _49._m1[_200 + 2] * in.m_55[_259]);
        _261 = spvFAdd(_261, _49._m1[_200 + 1] * in.m_55[_259]);
        _260 = spvFAdd(_260, _49._m1[_200] * in.m_55[_259]);
        _259++;
        continue;
    }
    out.gl_Position = spvFMulMatrixVector(_150._m1, spvFMulMatrixVector(spvFMulMatrixMatrix(float4x4(in.m_116, in.m_118, in.m_120, in.m_122), transpose(float4x4(_260, _261, _262, float4(0.0, 0.0, 0.0, 1.0)))), float4(in.m_157, 1.0)));
    out.gl_Position.y = -out.gl_Position.y;
    out.m_180 = in.m_182;
    out.gl_Position.y = -(out.gl_Position.y);    // Invert Y-axis for Metal
    return out;
}

