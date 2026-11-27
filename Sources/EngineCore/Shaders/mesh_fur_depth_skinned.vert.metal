// Generated from mesh_fur_depth_skinned.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 80119e685d2b8a7b
// glsl-fnv1a64: ba2babc36f09d628

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

struct _68
{
    float4 _m0[8];
    float4 _m1[8];
    float4 _m2[128];
    float4 _m3[384];
    float4 _m4[384];
};

struct _582
{
    float4x4 _m0;
    float4x4 _m1;
};

struct vertex_main_out
{
    float2 m_660 [[user(locn2)]];
    float3 m_663 [[user(locn4)]];
    float4 m_619 [[user(locn8)]];
    float3 m_665 [[user(locn10)]];
    float4 gl_Position [[position]];
};

struct vertex_main_in
{
    float3 m_268 [[attribute(0)]];
    float3 m_324 [[attribute(1)]];
    float2 m_361 [[attribute(2)]];
    float4 m_538 [[attribute(3)]];
    float4 m_540 [[attribute(4)]];
    float4 m_542 [[attribute(5)]];
    float4 m_544 [[attribute(6)]];
    float4 m_405 [[attribute(12)]];
    float4 m_380 [[attribute(13)]];
    float4 m_51 [[attribute(14)]];
    float4 m_75 [[attribute(15)]];
};

vertex vertex_main_out vertex_main(vertex_main_in in [[stage_in]], constant _68& _70 [[buffer(2)]], constant _582& _584 [[buffer(15)]])
{
    vertex_main_out out = {};
    float4 _1120;
    float4 _1121;
    float4 _1122;
    _1122 = float4(0.0);
    _1121 = float4(0.0);
    _1120 = float4(0.0);
    for (int _1119 = 0; _1119 < 4; )
    {
        int _695 = int(in.m_51[_1119]) * 3;
        _1122 = spvFAdd(_1122, _70._m3[_695 + 2] * in.m_75[_1119]);
        _1121 = spvFAdd(_1121, _70._m3[_695 + 1] * in.m_75[_1119]);
        _1120 = spvFAdd(_1120, _70._m3[_695] * in.m_75[_1119]);
        _1119++;
        continue;
    }
    float3 _786;
    float3 _832;
    bool _841;
    float4x4 _569 = spvFMulMatrixMatrix(float4x4(in.m_538, in.m_540, in.m_542, in.m_544), transpose(float4x4(_1120, _1121, _1122, float4(0.0, 0.0, 0.0, 1.0))));
    float3 _1127;
    do
    {
        _786 = in.m_268;
        float3 _792 = (_569 * float4(_786, 1.0)).xyz;
        float4 _794 = _569[0];
        float3 _795 = _794.xyz;
        float4 _797 = _569[1];
        float3 _798 = _797.xyz;
        float4 _800 = _569[2];
        float3 _801 = _800.xyz;
        float3 _810 = cross(_795, _798);
        _832 = in.m_324;
        float3 _836 = fast::normalize(spvFMulMatrixVector(float3x3(cross(_798, _801), cross(_801, _795), _810), _832) * ((dot(_810, _801) < 0.0) ? (-1.0) : 1.0));
        _841 = _70._m1[3].w > 0.5;
        float4 _843 = _569[3];
        float2 _1025 = _843.xz;
        float _1033 = spvFAdd(spvFMul(dot(_1025, _70._m1[5].xy), 0.3499999940395355224609375), spvFMul(dot(_1025, float2(0.829999983310699462890625, -0.569999992847442626953125)), 1.7000000476837158203125));
        float _1057 = spvFMul(dot(_843.xyz, float3(3.099999904632568359375, 2.2999999523162841796875, 2.7000000476837158203125)), 3.0);
        float3 _1124;
        _1124 = float3(0.0);
        for (int _1123 = 0; _1123 < 4; )
        {
            _1124 += (_70._m2[int(in.m_51[_1123])].xyz * in.m_75[_1123]);
            _1123++;
            continue;
        }
        float3 _855 = spvFAdd(float3(_70._m1[5].x, 0.0, _70._m1[5].y) * spvFMul(spvFMul(spvFMul(_70._m1[5].z, spvFAdd(1.0, spvFMul(_70._m1[5].w, spvFSub(spvFMul(spvFAdd(0.5, spvFMul(spvFMul(0.5, sin(spvFAdd(spvFMul(_70._m1[6].x, 0.61000001430511474609375), _1033))), sin(spvFAdd(spvFMul(_70._m1[6].x, 0.23000000417232513427734375), spvFMul(_1033, 0.699999988079071044921875))))), 1.60000002384185791015625), 0.60000002384185791015625)))), spvFAdd(0.699999988079071044921875, spvFMul(spvFMul(0.300000011920928955078125, sin(spvFAdd(spvFMul(_70._m1[6].x, 4.69999980926513671875), _1057))), sin(spvFAdd(spvFMul(_70._m1[6].x, 2.900000095367431640625), spvFMul(_1057, 0.37000000476837158203125)))))), 0.3499999940395355224609375), _1124 / float3(fast::max(_70._m1[0].x, 0.001000000047497451305389404296875))) * _70._m1[2].x;
        if (_841)
        {
            _1127 = spvFAdd(_792, _855 * spvFMul(spvFMul(_70._m1[0].x, in.m_361.y), in.m_361.y));
            break;
        }
        bool _899 = in.m_405.y > 1.5;
        float _1125;
        if (_899)
        {
            _1125 = in.m_361.y;
        }
        else
        {
            _1125 = in.m_405.y;
        }
        float _915 = spvFMul(_70._m1[0].x, fast::max(spvFSub(in.m_380.w, 1.0), 0.0));
        if ((_1125 <= 0.0) && (!_899))
        {
            _1127 = spvFAdd(_792, _836 * spvFAdd(spvFMul(_915, 0.039999999105930328369140625), 0.00039999998989515006542205810546875));
            break;
        }
        float3 _950 = spvFMulMatrixVector(float3x3(float3(_794.xyz), float3(_797.xyz), float3(_800.xyz)), in.m_380.xyz);
        float _985 = spvFMul(_915, _1125);
        float3 _986 = fast::normalize(spvFAdd(spvFAdd(_836 * spvFSub(1.0, fast::min(length(_950), 1.0)), _950), spvFAdd(float3(0.0, -_70._m1[1].w, 0.0), _855) * spvFMul(0.5, _1125))) * _985;
        float _989 = dot(_986, _836);
        float _993 = spvFMul(_985, 0.119999997317790985107421875);
        float3 _1126;
        if (_989 < _993)
        {
            _1126 = spvFAdd(_986, _836 * spvFSub(_993, _989));
        }
        else
        {
            _1126 = _986;
        }
        _1127 = spvFAdd(_792, _1126);
        break;
    } while(false);
    out.gl_Position = spvFMulMatrixVector(_584._m0, float4(_1127, 1.0));
    out.gl_Position.y = -out.gl_Position.y;
    bool _612 = !_841;
    bool _618;
    if (_612)
    {
        _618 = in.m_405.y > 1.5;
    }
    else
    {
        _618 = _612;
    }
    float _1128;
    if (_841 || _618)
    {
        _1128 = in.m_361.y;
    }
    else
    {
        _1128 = in.m_405.y;
    }
    float _1129;
    if (_841)
    {
        _1129 = fract(in.m_380.w);
    }
    else
    {
        _1129 = 0.0;
    }
    float _1130;
    if (_841)
    {
        _1130 = 1.0;
    }
    else
    {
        _1130 = _618 ? 2.0 : 0.0;
    }
    bool _656;
    if (_612)
    {
        _656 = in.m_405.y <= 0.0;
    }
    else
    {
        _656 = _612;
    }
    out.m_619 = float4(_1128, _1129, _1130, float(_656));
    out.m_660 = in.m_361;
    out.m_663 = _786;
    out.m_665 = _832;
    out.gl_Position.y = -(out.gl_Position.y);    // Invert Y-axis for Metal
    return out;
}

