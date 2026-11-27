// Generated from mesh_fur_depth.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 57c0baf8a0e3d4a2
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

struct _469
{
    float4x4 _m0;
    float4x4 _m1;
};

struct vertex_main_out
{
    float2 m_547 [[user(locn2)]];
    float3 m_550 [[user(locn4)]];
    float4 m_506 [[user(locn8)]];
    float3 m_552 [[user(locn10)]];
    float4 gl_Position [[position]];
};

struct vertex_main_in
{
    float3 m_154 [[attribute(0)]];
    float3 m_214 [[attribute(1)]];
    float2 m_252 [[attribute(2)]];
    float4 m_428 [[attribute(3)]];
    float4 m_430 [[attribute(4)]];
    float4 m_432 [[attribute(5)]];
    float4 m_434 [[attribute(6)]];
    float4 m_28 [[attribute(12)]];
    float4 m_271 [[attribute(13)]];
};

vertex vertex_main_out vertex_main(vertex_main_in in [[stage_in]], constant _47& _49 [[buffer(2)]], constant _469& _471 [[buffer(15)]])
{
    vertex_main_out out = {};
    float3 _598;
    float3 _644;
    bool _653;
    float3 _913;
    do
    {
        _598 = in.m_154;
        float3 _604 = (float4x4(in.m_428, in.m_430, in.m_432, in.m_434) * float4(_598, 1.0)).xyz;
        float3 _622 = cross(in.m_428.xyz, in.m_430.xyz);
        _644 = in.m_214;
        float3 _648 = fast::normalize(spvFMulMatrixVector(float3x3(cross(in.m_430.xyz, in.m_432.xyz), cross(in.m_432.xyz, in.m_428.xyz), _622), _644) * ((dot(_622, in.m_432.xyz) < 0.0) ? (-1.0) : 1.0));
        _653 = _49._m1[3].w > 0.5;
        float _845 = spvFAdd(spvFMul(dot(in.m_434.xz, _49._m1[5].xy), 0.3499999940395355224609375), spvFMul(dot(in.m_434.xz, float2(0.829999983310699462890625, -0.569999992847442626953125)), 1.7000000476837158203125));
        float _869 = spvFMul(dot(in.m_434.xyz, float3(3.099999904632568359375, 2.2999999523162841796875, 2.7000000476837158203125)), 3.0);
        float3 _667 = spvFAdd(float3(_49._m1[5].x, 0.0, _49._m1[5].y) * spvFMul(spvFMul(spvFMul(_49._m1[5].z, spvFAdd(1.0, spvFMul(_49._m1[5].w, spvFSub(spvFMul(spvFAdd(0.5, spvFMul(spvFMul(0.5, sin(spvFAdd(spvFMul(_49._m1[6].x, 0.61000001430511474609375), _845))), sin(spvFAdd(spvFMul(_49._m1[6].x, 0.23000000417232513427734375), spvFMul(_845, 0.699999988079071044921875))))), 1.60000002384185791015625), 0.60000002384185791015625)))), spvFAdd(0.699999988079071044921875, spvFMul(spvFMul(0.300000011920928955078125, sin(spvFAdd(spvFMul(_49._m1[6].x, 4.69999980926513671875), _869))), sin(spvFAdd(spvFMul(_49._m1[6].x, 2.900000095367431640625), spvFMul(_869, 0.37000000476837158203125)))))), 0.3499999940395355224609375), float3(in.m_28.z, 0.0, in.m_28.w) / float3(fast::max(_49._m1[0].x, 0.001000000047497451305389404296875))) * _49._m1[2].x;
        if (_653)
        {
            _913 = spvFAdd(_604, _667 * spvFMul(spvFMul(_49._m1[0].x, in.m_252.y), in.m_252.y));
            break;
        }
        bool _711 = in.m_28.y > 1.5;
        float _911;
        if (_711)
        {
            _911 = in.m_252.y;
        }
        else
        {
            _911 = in.m_28.y;
        }
        float _727 = spvFMul(_49._m1[0].x, fast::max(spvFSub(in.m_271.w, 1.0), 0.0));
        if ((_911 <= 0.0) && (!_711))
        {
            _913 = spvFAdd(_604, _648 * spvFAdd(spvFMul(_727, 0.039999999105930328369140625), 0.00039999998989515006542205810546875));
            break;
        }
        float3 _762 = spvFMulMatrixVector(float3x3(float3(in.m_428.xyz), float3(in.m_430.xyz), float3(in.m_432.xyz)), in.m_271.xyz);
        float _797 = spvFMul(_727, _911);
        float3 _798 = fast::normalize(spvFAdd(spvFAdd(_648 * spvFSub(1.0, fast::min(length(_762), 1.0)), _762), spvFAdd(float3(0.0, -_49._m1[1].w, 0.0), _667) * spvFMul(0.5, _911))) * _797;
        float _801 = dot(_798, _648);
        float _805 = spvFMul(_797, 0.119999997317790985107421875);
        float3 _912;
        if (_801 < _805)
        {
            _912 = spvFAdd(_798, _648 * spvFSub(_805, _801));
        }
        else
        {
            _912 = _798;
        }
        _913 = spvFAdd(_604, _912);
        break;
    } while(false);
    out.gl_Position = spvFMulMatrixVector(_471._m0, float4(_913, 1.0));
    out.gl_Position.y = -out.gl_Position.y;
    bool _499 = !_653;
    bool _505;
    if (_499)
    {
        _505 = in.m_28.y > 1.5;
    }
    else
    {
        _505 = _499;
    }
    float _914;
    if (_653 || _505)
    {
        _914 = in.m_252.y;
    }
    else
    {
        _914 = in.m_28.y;
    }
    float _915;
    if (_653)
    {
        _915 = fract(in.m_271.w);
    }
    else
    {
        _915 = 0.0;
    }
    float _916;
    if (_653)
    {
        _916 = 1.0;
    }
    else
    {
        _916 = _505 ? 2.0 : 0.0;
    }
    bool _543;
    if (_499)
    {
        _543 = in.m_28.y <= 0.0;
    }
    else
    {
        _543 = _499;
    }
    out.m_506 = float4(_914, _915, _916, float(_543));
    out.m_547 = in.m_252;
    out.m_550 = _598;
    out.m_552 = _644;
    out.gl_Position.y = -(out.gl_Position.y);    // Invert Y-axis for Metal
    return out;
}

