// Generated from mesh_fur_depth_skinned.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 09676756adff21d3
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

struct _591
{
    float4x4 _m0;
    float4x4 _m1;
};

struct vertex_main_out
{
    float2 m_669 [[user(locn2)]];
    float3 m_672 [[user(locn4)]];
    float4 m_628 [[user(locn8)]];
    float3 m_674 [[user(locn10)]];
    float4 gl_Position [[position]];
};

struct vertex_main_in
{
    float3 m_268 [[attribute(0)]];
    float3 m_324 [[attribute(1)]];
    float2 m_370 [[attribute(2)]];
    float4 m_547 [[attribute(3)]];
    float4 m_549 [[attribute(4)]];
    float4 m_551 [[attribute(5)]];
    float4 m_553 [[attribute(6)]];
    float4 m_339 [[attribute(11)]];
    float4 m_414 [[attribute(12)]];
    float4 m_389 [[attribute(13)]];
    float4 m_51 [[attribute(14)]];
    float4 m_75 [[attribute(15)]];
};

vertex vertex_main_out vertex_main(vertex_main_in in [[stage_in]], constant _68& _70 [[buffer(2)]], constant _591& _593 [[buffer(15)]])
{
    vertex_main_out out = {};
    float4 _1135;
    float4 _1136;
    float4 _1137;
    _1137 = float4(0.0);
    _1136 = float4(0.0);
    _1135 = float4(0.0);
    for (int _1134 = 0; _1134 < 4; )
    {
        int _703 = int(in.m_51[_1134]) * 3;
        _1137 = spvFAdd(_1137, _70._m3[_703 + 2] * in.m_75[_1134]);
        _1136 = spvFAdd(_1136, _70._m3[_703 + 1] * in.m_75[_1134]);
        _1135 = spvFAdd(_1135, _70._m3[_703] * in.m_75[_1134]);
        _1134++;
        continue;
    }
    float3 _795;
    float3 _841;
    bool _850;
    float4x4 _578 = spvFMulMatrixMatrix(float4x4(in.m_547, in.m_549, in.m_551, in.m_553), transpose(float4x4(_1135, _1136, _1137, float4(0.0, 0.0, 0.0, 1.0))));
    float3 _1142;
    do
    {
        _795 = in.m_268;
        float3 _801 = (_578 * float4(_795, 1.0)).xyz;
        float4 _803 = _578[0];
        float3 _804 = _803.xyz;
        float4 _806 = _578[1];
        float3 _807 = _806.xyz;
        float4 _809 = _578[2];
        float3 _810 = _809.xyz;
        float3 _819 = cross(_804, _807);
        _841 = in.m_324;
        float3 _845 = fast::normalize(spvFMulMatrixVector(float3x3(cross(_807, _810), cross(_810, _804), _819), _841) * ((dot(_819, _810) < 0.0) ? (-1.0) : 1.0));
        _850 = _70._m1[3].w > 0.5;
        float4 _856 = _578[3];
        float2 _1040 = _856.xz;
        float _1048 = spvFAdd(spvFMul(dot(_1040, _70._m1[5].xy), 0.3499999940395355224609375), spvFMul(dot(_1040, float2(0.829999983310699462890625, -0.569999992847442626953125)), 1.7000000476837158203125));
        float _1072 = spvFMul(dot(_856.xyz, float3(3.099999904632568359375, 2.2999999523162841796875, 2.7000000476837158203125)), 3.0);
        float3 _1139;
        _1139 = float3(0.0);
        for (int _1138 = 0; _1138 < 4; )
        {
            _1139 += (_70._m2[int(in.m_51[_1138])].xyz * in.m_75[_1138]);
            _1138++;
            continue;
        }
        float3 _870 = spvFAdd(float3(_70._m1[5].x, 0.0, _70._m1[5].y) * spvFMul(spvFMul(spvFMul(_70._m1[5].z, spvFAdd(1.0, spvFMul(_70._m1[5].w, spvFSub(spvFMul(spvFAdd(0.5, spvFMul(spvFMul(0.5, sin(spvFAdd(spvFMul(_70._m1[6].x, 0.61000001430511474609375), _1048))), sin(spvFAdd(spvFMul(_70._m1[6].x, 0.23000000417232513427734375), spvFMul(_1048, 0.699999988079071044921875))))), 1.60000002384185791015625), 0.60000002384185791015625)))), spvFAdd(0.699999988079071044921875, spvFMul(spvFMul(0.300000011920928955078125, sin(spvFAdd(spvFMul(_70._m1[6].x, 4.69999980926513671875), _1072))), sin(spvFAdd(spvFMul(_70._m1[6].x, 2.900000095367431640625), spvFMul(_1072, 0.37000000476837158203125)))))), 0.3499999940395355224609375), _1139 / float3(fast::max(_70._m1[0].x, 0.001000000047497451305389404296875))) * spvFMul(_70._m1[2].x, (in.m_339.w < (-0.5)) ? 0.0 : 1.0);
        if (_850)
        {
            _1142 = spvFAdd(_801, _870 * spvFMul(spvFMul(_70._m1[0].x, in.m_370.y), in.m_370.y));
            break;
        }
        bool _914 = in.m_414.y > 1.5;
        float _1140;
        if (_914)
        {
            _1140 = in.m_370.y;
        }
        else
        {
            _1140 = in.m_414.y;
        }
        float _930 = spvFMul(_70._m1[0].x, fast::max(spvFSub(in.m_389.w, 1.0), 0.0));
        if ((_1140 <= 0.0) && (!_914))
        {
            _1142 = spvFAdd(_801, _845 * spvFAdd(spvFMul(_930, 0.039999999105930328369140625), 0.00039999998989515006542205810546875));
            break;
        }
        float3 _965 = spvFMulMatrixVector(float3x3(float3(_803.xyz), float3(_806.xyz), float3(_809.xyz)), in.m_389.xyz);
        float _1000 = spvFMul(_930, _1140);
        float3 _1001 = fast::normalize(spvFAdd(spvFAdd(_845 * spvFSub(1.0, fast::min(length(_965), 1.0)), _965), spvFAdd(float3(0.0, -_70._m1[1].w, 0.0), _870) * spvFMul(0.5, _1140))) * _1000;
        float _1004 = dot(_1001, _845);
        float _1008 = spvFMul(_1000, 0.119999997317790985107421875);
        float3 _1141;
        if (_1004 < _1008)
        {
            _1141 = spvFAdd(_1001, _845 * spvFSub(_1008, _1004));
        }
        else
        {
            _1141 = _1001;
        }
        _1142 = spvFAdd(_801, _1141);
        break;
    } while(false);
    out.gl_Position = spvFMulMatrixVector(_593._m0, float4(_1142, 1.0));
    out.gl_Position.y = -out.gl_Position.y;
    bool _621 = !_850;
    bool _627;
    if (_621)
    {
        _627 = in.m_414.y > 1.5;
    }
    else
    {
        _627 = _621;
    }
    float _1143;
    if (_850 || _627)
    {
        _1143 = in.m_370.y;
    }
    else
    {
        _1143 = in.m_414.y;
    }
    float _1144;
    if (_850)
    {
        _1144 = fract(in.m_389.w);
    }
    else
    {
        _1144 = 0.0;
    }
    float _1145;
    if (_850)
    {
        _1145 = 1.0;
    }
    else
    {
        _1145 = _627 ? 2.0 : 0.0;
    }
    bool _665;
    if (_621)
    {
        _665 = in.m_414.y <= 0.0;
    }
    else
    {
        _665 = _621;
    }
    out.m_628 = float4(_1143, _1144, _1145, float(_665));
    out.m_669 = in.m_370;
    out.m_672 = _795;
    out.m_674 = _841;
    out.gl_Position.y = -(out.gl_Position.y);    // Invert Y-axis for Metal
    return out;
}

