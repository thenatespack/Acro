// Generated from mesh_shadow_graph_skinned.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: d0434e084c4e40c4
// glsl-fnv1a64: 0465ea86b096f023

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

struct _207
{
    float4x4 _m0;
    float4x4 _m1;
};

struct vertex_main_out
{
    float3 m_229 [[user(locn0)]];
    float3 m_232 [[user(locn1)]];
    float2 m_241 [[user(locn2)]];
    float4 m_245 [[user(locn3)]];
    float4 gl_Position [[position]];
};

struct vertex_main_in
{
    float3 m_151 [[attribute(0)]];
    float3 m_234 [[attribute(1)]];
    float2 m_243 [[attribute(2)]];
    float4 m_116 [[attribute(3)]];
    float4 m_118 [[attribute(4)]];
    float4 m_120 [[attribute(5)]];
    float4 m_122 [[attribute(6)]];
    float4 m_246 [[attribute(11)]];
    float4 m_33 [[attribute(14)]];
    float4 m_55 [[attribute(15)]];
};

vertex vertex_main_out vertex_main(vertex_main_in in [[stage_in]], constant _47& _49 [[buffer(2)]], constant _207& _209 [[buffer(15)]])
{
    vertex_main_out out = {};
    float4 _327;
    float4 _328;
    float4 _329;
    _329 = float4(0.0);
    _328 = float4(0.0);
    _327 = float4(0.0);
    for (int _326 = 0; _326 < 4; )
    {
        int _264 = int(in.m_33[_326]) * 3;
        _329 = spvFAdd(_329, _49._m1[_264 + 2] * in.m_55[_326]);
        _328 = spvFAdd(_328, _49._m1[_264 + 1] * in.m_55[_326]);
        _327 = spvFAdd(_327, _49._m1[_264] * in.m_55[_326]);
        _326++;
        continue;
    }
    float4x4 _146 = spvFMulMatrixMatrix(float4x4(in.m_116, in.m_118, in.m_120, in.m_122), transpose(float4x4(_327, _328, _329, float4(0.0, 0.0, 0.0, 1.0))));
    float4 _157 = spvFMulMatrixVector(_146, float4(in.m_151, 1.0));
    float3 _162 = _146[0].xyz;
    float3 _166 = _146[1].xyz;
    float3 _170 = _146[2].xyz;
    float3 _182 = cross(_162, _166);
    out.gl_Position = spvFMulMatrixVector(_209._m1, _157);
    out.gl_Position.y = -out.gl_Position.y;
    out.m_229 = _157.xyz;
    out.m_232 = (float3x3(cross(_166, _170), cross(_170, _162), _182) * in.m_234) * ((dot(_182, _170) < 0.0) ? (-1.0) : 1.0);
    out.m_241 = in.m_243;
    out.m_245 = in.m_246;
    out.gl_Position.y = -(out.gl_Position.y);    // Invert Y-axis for Metal
    return out;
}

