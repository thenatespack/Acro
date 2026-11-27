// Generated from mesh_fur_depth.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 33ecaacfab9688dc
// glsl-fnv1a64: c394983351f825f5

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

struct _47
{
    float4 _m0[8];
    float4 _m1[8];
};

struct _453
{
    float4x4 _m0;
    float4x4 _m1;
};

struct vertex_main_out
{
    float2 m_514 [[user(locn2)]];
    float3 m_517 [[user(locn4)]];
    float4 m_481 [[user(locn8)]];
    float3 m_519 [[user(locn10)]];
    float4 gl_Position [[position]];
};

struct vertex_main_in
{
    float3 m_154 [[attribute(0)]];
    float3 m_214 [[attribute(1)]];
    float2 m_252 [[attribute(2)]];
    float4 m_412 [[attribute(3)]];
    float4 m_414 [[attribute(4)]];
    float4 m_416 [[attribute(5)]];
    float4 m_418 [[attribute(6)]];
    float4 m_28 [[attribute(12)]];
    float4 m_271 [[attribute(13)]];
};

vertex vertex_main_out vertex_main(vertex_main_in in [[stage_in]], constant _47& _49 [[buffer(2)]], constant _453& _455 [[buffer(15)]])
{
    vertex_main_out out = {};
    float3 _563;
    float3 _609;
    bool _618;
    float3 _864;
    do
    {
        _563 = in.m_154;
        float3 _569 = (float4x4(in.m_412, in.m_414, in.m_416, in.m_418) * float4(_563, 1.0)).xyz;
        float3 _587 = cross(in.m_412.xyz, in.m_414.xyz);
        _609 = in.m_214;
        float3 _613 = fast::normalize(spvFMulMatrixVector(float3x3(cross(in.m_414.xyz, in.m_416.xyz), cross(in.m_416.xyz, in.m_412.xyz), _587), _609) * ((dot(_587, in.m_416.xyz) < 0.0) ? (-1.0) : 1.0));
        _618 = _49._m1[3].w > 0.5;
        float _797 = spvFAdd(spvFMul(dot(in.m_418.xz, _49._m1[5].xy), 0.3499999940395355224609375), spvFMul(dot(in.m_418.xz, float2(0.829999983310699462890625, -0.569999992847442626953125)), 1.7000000476837158203125));
        float _821 = spvFMul(dot(in.m_418.xyz, float3(3.099999904632568359375, 2.2999999523162841796875, 2.7000000476837158203125)), 3.0);
        float3 _632 = spvFAdd(float3(_49._m1[5].x, 0.0, _49._m1[5].y) * spvFMul(spvFMul(spvFMul(_49._m1[5].z, spvFAdd(1.0, spvFMul(_49._m1[5].w, spvFSub(spvFMul(spvFAdd(0.5, spvFMul(spvFMul(0.5, sin(spvFAdd(spvFMul(_49._m1[6].x, 0.61000001430511474609375), _797))), sin(spvFAdd(spvFMul(_49._m1[6].x, 0.23000000417232513427734375), spvFMul(_797, 0.699999988079071044921875))))), 1.60000002384185791015625), 0.60000002384185791015625)))), spvFAdd(0.699999988079071044921875, spvFMul(spvFMul(0.300000011920928955078125, sin(spvFAdd(spvFMul(_49._m1[6].x, 4.69999980926513671875), _821))), sin(spvFAdd(spvFMul(_49._m1[6].x, 2.900000095367431640625), spvFMul(_821, 0.37000000476837158203125)))))), 0.3499999940395355224609375), float3(in.m_28.z, 0.0, in.m_28.w) / float3(fast::max(_49._m1[0].x, 0.001000000047497451305389404296875))) * _49._m1[2].x;
        if (_618)
        {
            _864 = spvFAdd(_569, _632 * spvFMul(spvFMul(_49._m1[0].x, in.m_252.y), in.m_252.y));
            break;
        }
        float _682 = spvFMul(_49._m1[0].x, fast::max(spvFSub(in.m_271.w, 1.0), 0.0));
        if (in.m_28.y <= 0.0)
        {
            _864 = spvFAdd(_569, _613 * spvFAdd(spvFMul(_682, 0.039999999105930328369140625), 0.00039999998989515006542205810546875));
            break;
        }
        float3 _714 = spvFMulMatrixVector(float3x3(float3(in.m_412.xyz), float3(in.m_414.xyz), float3(in.m_416.xyz)), in.m_271.xyz);
        float _749 = spvFMul(_682, in.m_28.y);
        float3 _750 = fast::normalize(spvFAdd(spvFAdd(_613 * spvFSub(1.0, fast::min(length(_714), 1.0)), _714), spvFAdd(float3(0.0, -_49._m1[1].w, 0.0), _632) * spvFMul(0.5, in.m_28.y))) * _749;
        float _753 = dot(_750, _613);
        float _757 = spvFMul(_749, 0.119999997317790985107421875);
        float3 _863;
        if (_753 < _757)
        {
            _863 = spvFAdd(_750, _613 * spvFSub(_757, _753));
        }
        else
        {
            _863 = _750;
        }
        _864 = spvFAdd(_569, _863);
        break;
    } while(false);
    out.gl_Position = spvFMulMatrixVector(_455._m0, float4(_864, 1.0));
    out.gl_Position.y = -out.gl_Position.y;
    float _865;
    if (_618)
    {
        _865 = in.m_252.y;
    }
    else
    {
        _865 = in.m_28.y;
    }
    float _866;
    if (_618)
    {
        _866 = fract(in.m_271.w);
    }
    else
    {
        _866 = 0.0;
    }
    bool _504 = !_618;
    bool _510;
    if (_504)
    {
        _510 = in.m_28.y <= 0.0;
    }
    else
    {
        _510 = _504;
    }
    out.m_481 = float4(_865, _866, float(_618), float(_510));
    out.m_514 = in.m_252;
    out.m_517 = _563;
    out.m_519 = _609;
    out.gl_Position.y = -(out.gl_Position.y);    // Invert Y-axis for Metal
    return out;
}

