// Generated from mesh_fur.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: bf1c24389d9605dd
// glsl-fnv1a64: c770a578588d3aa5

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
    float4x4 _m2;
    float4x4 _m3;
};

struct vertex_main_out
{
    float3 m_637 [[user(locn0)]];
    float3 m_639 [[user(locn1)]];
    float2 m_547 [[user(locn2)]];
    float4 m_645 [[user(locn3)]];
    float3 m_550 [[user(locn4)]];
    float4 m_648 [[user(locn5)]];
    float4 m_670 [[user(locn6)]];
    float4 m_672 [[user(locn7)]];
    float4 m_506 [[user(locn8)]];
    float3 m_674 [[user(locn9)]];
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
    float4 m_555 [[attribute(7)]];
    float4 m_557 [[attribute(8)]];
    float4 m_559 [[attribute(9)]];
    float4 m_561 [[attribute(10)]];
    float4 m_646 [[attribute(11)]];
    float4 m_28 [[attribute(12)]];
    float4 m_271 [[attribute(13)]];
};

vertex vertex_main_out vertex_main(vertex_main_in in [[stage_in]], constant _47& _49 [[buffer(2)]], constant _469& _471 [[buffer(15)]])
{
    vertex_main_out out = {};
    float3 _715;
    float4 _719;
    float3 _730;
    float3 _739;
    float3x3 _752;
    float3 _761;
    float _767;
    bool _770;
    float _778;
    float3 _781;
    float2 _952;
    float _978;
    float3 _1005;
    float _1007;
    float3 _1378;
    float3 _1379;
    do
    {
        _715 = in.m_154;
        _719 = float4(_715, 1.0);
        float3 _721 = (float4x4(in.m_428, in.m_430, in.m_432, in.m_434) * _719).xyz;
        _730 = in.m_432.xyz;
        _739 = cross(in.m_428.xyz, in.m_430.xyz);
        _752 = float3x3(cross(in.m_430.xyz, _730), cross(_730, in.m_428.xyz), _739);
        _761 = in.m_214;
        float3 _765 = fast::normalize(spvFMulMatrixVector(_752, _761) * ((dot(_739, _730) < 0.0) ? (-1.0) : 1.0));
        _767 = _49._m1[2].x;
        _770 = _49._m1[3].w > 0.5;
        _952 = _49._m1[5].xy;
        float _962 = spvFAdd(spvFMul(dot(in.m_434.xz, _952), 0.3499999940395355224609375), spvFMul(dot(in.m_434.xz, float2(0.829999983310699462890625, -0.569999992847442626953125)), 1.7000000476837158203125));
        _978 = _49._m1[5].w;
        float _986 = spvFMul(dot(in.m_434.xyz, float3(3.099999904632568359375, 2.2999999523162841796875, 2.7000000476837158203125)), 3.0);
        _1005 = float3(_49._m1[5].x, 0.0, _49._m1[5].y);
        _1007 = _49._m1[5].z;
        _778 = _49._m1[0].x;
        _781 = float3(in.m_28.z, 0.0, in.m_28.w) / float3(fast::max(_778, 0.001000000047497451305389404296875));
        float3 _784 = spvFAdd(_1005 * spvFMul(spvFMul(spvFMul(_1007, spvFAdd(1.0, spvFMul(_978, spvFSub(spvFMul(spvFAdd(0.5, spvFMul(spvFMul(0.5, sin(spvFAdd(spvFMul(_49._m1[6].x, 0.61000001430511474609375), _962))), sin(spvFAdd(spvFMul(_49._m1[6].x, 0.23000000417232513427734375), spvFMul(_962, 0.699999988079071044921875))))), 1.60000002384185791015625), 0.60000002384185791015625)))), spvFAdd(0.699999988079071044921875, spvFMul(spvFMul(0.300000011920928955078125, sin(spvFAdd(spvFMul(_49._m1[6].x, 4.69999980926513671875), _986))), sin(spvFAdd(spvFMul(_49._m1[6].x, 2.900000095367431640625), spvFMul(_986, 0.37000000476837158203125)))))), 0.3499999940395355224609375), _781) * _767;
        if (_770)
        {
            _1379 = fast::normalize((float3x3(float3(in.m_428.xyz), float3(in.m_430.xyz), float3(in.m_432.xyz)) * in.m_271.xyz) + (_784 * (2.0 * in.m_252.y)));
            _1378 = spvFAdd(_721, _784 * spvFMul(spvFMul(_778, in.m_252.y), in.m_252.y));
            break;
        }
        bool _828 = in.m_28.y > 1.5;
        float _1376;
        if (_828)
        {
            _1376 = in.m_252.y;
        }
        else
        {
            _1376 = in.m_28.y;
        }
        float _844 = spvFMul(_778, fast::max(spvFSub(in.m_271.w, 1.0), 0.0));
        if ((_1376 <= 0.0) && (!_828))
        {
            _1379 = _765;
            _1378 = spvFAdd(_721, _765 * spvFAdd(spvFMul(_844, 0.039999999105930328369140625), 0.00039999998989515006542205810546875));
            break;
        }
        float3 _879 = spvFMulMatrixVector(float3x3(float3(in.m_428.xyz), float3(in.m_430.xyz), float3(in.m_432.xyz)), in.m_271.xyz);
        float _882 = fast::min(length(_879), 1.0);
        float3 _888 = spvFAdd(float3(0.0, -_49._m1[1].w, 0.0), _784);
        float _914 = spvFMul(_844, _1376);
        float3 _915 = fast::normalize(spvFAdd(spvFAdd(_765 * spvFSub(1.0, _882), _879), _888 * spvFMul(0.5, _1376))) * _914;
        float _918 = dot(_915, _765);
        float _922 = spvFMul(_914, 0.119999997317790985107421875);
        float3 _1377;
        if (_918 < _922)
        {
            _1377 = spvFAdd(_915, _765 * spvFSub(_922, _918));
        }
        else
        {
            _1377 = _915;
        }
        _1379 = fast::normalize(((_765 * (1.0 - _882)) + _879) + (_888 * _1376));
        _1378 = spvFAdd(_721, _1377);
        break;
    } while(false);
    float4 _479 = float4(_1378, 1.0);
    out.gl_Position = spvFMulMatrixVector(_471._m0, _479);
    out.gl_Position.y = -out.gl_Position.y;
    bool _499 = !_770;
    bool _505;
    if (_499)
    {
        _505 = in.m_28.y > 1.5;
    }
    else
    {
        _505 = _499;
    }
    float _1381;
    if (_770 || _505)
    {
        _1381 = in.m_252.y;
    }
    else
    {
        _1381 = in.m_28.y;
    }
    float _1382;
    if (_770)
    {
        _1382 = fract(in.m_271.w);
    }
    else
    {
        _1382 = 0.0;
    }
    float _1383;
    if (_770)
    {
        _1383 = 1.0;
    }
    else
    {
        _1383 = _505 ? 2.0 : 0.0;
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
    out.m_506 = float4(_1381, _1382, _1383, float(_543));
    out.m_547 = in.m_252;
    out.m_550 = _715;
    out.m_552 = _761;
    float3 _1386;
    do
    {
        float3 _1060 = (float4x4(in.m_555, in.m_557, in.m_559, in.m_561) * _719).xyz;
        float3 _1078 = cross(in.m_555.xyz, in.m_557.xyz);
        float3 _1104 = fast::normalize(spvFMulMatrixVector(float3x3(cross(in.m_557.xyz, in.m_559.xyz), cross(in.m_559.xyz, in.m_555.xyz), _1078), _761) * ((dot(_1078, in.m_559.xyz) < 0.0) ? (-1.0) : 1.0));
        float _1301 = spvFAdd(spvFMul(dot(in.m_561.xz, _952), 0.3499999940395355224609375), spvFMul(dot(in.m_561.xz, float2(0.829999983310699462890625, -0.569999992847442626953125)), 1.7000000476837158203125));
        float _1325 = spvFMul(dot(in.m_561.xyz, float3(3.099999904632568359375, 2.2999999523162841796875, 2.7000000476837158203125)), 3.0);
        float3 _1123 = spvFAdd(_1005 * spvFMul(spvFMul(spvFMul(_1007, spvFAdd(1.0, spvFMul(_978, spvFSub(spvFMul(spvFAdd(0.5, spvFMul(spvFMul(0.5, sin(spvFAdd(spvFMul(_49._m1[6].y, 0.61000001430511474609375), _1301))), sin(spvFAdd(spvFMul(_49._m1[6].y, 0.23000000417232513427734375), spvFMul(_1301, 0.699999988079071044921875))))), 1.60000002384185791015625), 0.60000002384185791015625)))), spvFAdd(0.699999988079071044921875, spvFMul(spvFMul(0.300000011920928955078125, sin(spvFAdd(spvFMul(_49._m1[6].y, 4.69999980926513671875), _1325))), sin(spvFAdd(spvFMul(_49._m1[6].y, 2.900000095367431640625), spvFMul(_1325, 0.37000000476837158203125)))))), 0.3499999940395355224609375), _781) * _767;
        if (_770)
        {
            _1386 = spvFAdd(_1060, _1123 * spvFMul(spvFMul(_778, in.m_252.y), in.m_252.y));
            break;
        }
        bool _1167 = in.m_28.y > 1.5;
        float _1384;
        if (_1167)
        {
            _1384 = in.m_252.y;
        }
        else
        {
            _1384 = in.m_28.y;
        }
        float _1183 = spvFMul(_778, fast::max(spvFSub(in.m_271.w, 1.0), 0.0));
        if ((_1384 <= 0.0) && (!_1167))
        {
            _1386 = spvFAdd(_1060, _1104 * spvFAdd(spvFMul(_1183, 0.039999999105930328369140625), 0.00039999998989515006542205810546875));
            break;
        }
        float3 _1218 = spvFMulMatrixVector(float3x3(float3(in.m_555.xyz), float3(in.m_557.xyz), float3(in.m_559.xyz)), in.m_271.xyz);
        float _1253 = spvFMul(_1183, _1384);
        float3 _1254 = fast::normalize(spvFAdd(spvFAdd(_1104 * spvFSub(1.0, fast::min(length(_1218), 1.0)), _1218), spvFAdd(float3(0.0, -_49._m1[1].w, 0.0), _1123) * spvFMul(0.5, _1384))) * _1253;
        float _1257 = dot(_1254, _1104);
        float _1261 = spvFMul(_1253, 0.119999997317790985107421875);
        float3 _1385;
        if (_1257 < _1261)
        {
            _1385 = spvFAdd(_1254, _1104 * spvFSub(_1261, _1257));
        }
        else
        {
            _1385 = _1254;
        }
        _1386 = spvFAdd(_1060, _1385);
        break;
    } while(false);
    out.m_637 = _1378;
    out.m_639 = (_752 * _761) * ((dot(_739, _730) < 0.0) ? (-1.0) : 1.0);
    out.m_645 = in.m_646;
    out.m_648 = float4(in.m_28.x, 0.0, 0.0, 0.0);
    out.m_670 = spvFMulMatrixVector(_471._m2, _479);
    out.m_672 = spvFMulMatrixVector(_471._m3, float4(_1386, 1.0));
    out.m_674 = _1379;
    out.gl_Position.y = -(out.gl_Position.y);    // Invert Y-axis for Metal
    return out;
}

