// Generated from mesh_fur_skinned.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: b79a1ee65ad1e6c4
// glsl-fnv1a64: b04aa777f9f00a8c

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

struct _70
{
    float4 _m0[8];
    float4 _m1[8];
    float4 _m2[128];
    float4 _m3[384];
    float4 _m4[384];
};

struct _729
{
    float4x4 _m0;
    float4x4 _m1;
    float4x4 _m2;
    float4x4 _m3;
};

struct vertex_main_out
{
    float3 m_754 [[user(locn0)]];
    float3 m_756 [[user(locn1)]];
    float2 m_763 [[user(locn2)]];
    float4 m_765 [[user(locn3)]];
    float3 m_832 [[user(locn4)]];
    float4 m_768 [[user(locn5)]];
    float4 m_790 [[user(locn6)]];
    float4 m_792 [[user(locn7)]];
    float4 m_798 [[user(locn8)]];
    float3 m_830 [[user(locn9)]];
    float3 m_834 [[user(locn10)]];
    float4 gl_Position [[position]];
};

struct vertex_main_in
{
    float3 m_345 [[attribute(0)]];
    float3 m_401 [[attribute(1)]];
    float2 m_438 [[attribute(2)]];
    float4 m_599 [[attribute(3)]];
    float4 m_601 [[attribute(4)]];
    float4 m_603 [[attribute(5)]];
    float4 m_605 [[attribute(6)]];
    float4 m_629 [[attribute(7)]];
    float4 m_631 [[attribute(8)]];
    float4 m_633 [[attribute(9)]];
    float4 m_635 [[attribute(10)]];
    float4 m_766 [[attribute(11)]];
    float4 m_482 [[attribute(12)]];
    float4 m_457 [[attribute(13)]];
    float4 m_53 [[attribute(14)]];
    float4 m_77 [[attribute(15)]];
};

vertex vertex_main_out vertex_main(vertex_main_in in [[stage_in]], constant _70& _72 [[buffer(2)]], constant _729& _731 [[buffer(15)]])
{
    vertex_main_out out = {};
    float4 _1697;
    float4 _1698;
    float4 _1699;
    _1699 = float4(0.0);
    _1698 = float4(0.0);
    _1697 = float4(0.0);
    for (int _1696 = 0; _1696 < 4; )
    {
        int _859 = int(in.m_53[_1696]) * 3;
        _1699 = spvFAdd(_1699, _72._m3[_859 + 2] * in.m_77[_1696]);
        _1698 = spvFAdd(_1698, _72._m3[_859 + 1] * in.m_77[_1696]);
        _1697 = spvFAdd(_1697, _72._m3[_859] * in.m_77[_1696]);
        _1696++;
        continue;
    }
    float4x4 _660 = spvFMulMatrixMatrix(float4x4(in.m_599, in.m_601, in.m_603, in.m_605), transpose(float4x4(_1697, _1698, _1699, float4(0.0, 0.0, 0.0, 1.0))));
    float4 _1702;
    float4 _1703;
    float4 _1704;
    _1704 = float4(0.0);
    _1703 = float4(0.0);
    _1702 = float4(0.0);
    for (int _1701 = 0; _1701 < 4; )
    {
        int _934 = int(in.m_53[_1701]) * 3;
        _1704 = spvFAdd(_1704, _72._m4[_934 + 2] * in.m_77[_1701]);
        _1703 = spvFAdd(_1703, _72._m4[_934 + 1] * in.m_77[_1701]);
        _1702 = spvFAdd(_1702, _72._m4[_934] * in.m_77[_1701]);
        _1701++;
        continue;
    }
    float3 _1023;
    float4 _1027;
    float3 _1038;
    float3 _1047;
    float3x3 _1060;
    float3 _1069;
    float _1075;
    bool _1078;
    float _1086;
    float3 _1088;
    float2 _1247;
    float _1273;
    float3 _1300;
    float _1302;
    float4x4 _663 = spvFMulMatrixMatrix(float4x4(in.m_629, in.m_631, in.m_633, in.m_635), transpose(float4x4(_1702, _1703, _1704, float4(0.0, 0.0, 0.0, 1.0))));
    float3 _1709;
    float3 _1710;
    do
    {
        _1023 = in.m_345;
        _1027 = float4(_1023, 1.0);
        float3 _1029 = (_660 * _1027).xyz;
        float4 _1031 = _660[0];
        float3 _1032 = _1031.xyz;
        float4 _1034 = _660[1];
        float3 _1035 = _1034.xyz;
        float4 _1037 = _660[2];
        _1038 = _1037.xyz;
        _1047 = cross(_1032, _1035);
        _1060 = float3x3(cross(_1035, _1038), cross(_1038, _1032), _1047);
        _1069 = in.m_401;
        float3 _1073 = fast::normalize(spvFMulMatrixVector(_1060, _1069) * ((dot(_1047, _1038) < 0.0) ? (-1.0) : 1.0));
        _1075 = _72._m1[2].x;
        _1078 = _72._m1[3].w > 0.5;
        float4 _1080 = _660[3];
        _1247 = _72._m1[5].xy;
        float2 _1249 = _1080.xz;
        float _1257 = spvFAdd(spvFMul(dot(_1249, _1247), 0.3499999940395355224609375), spvFMul(dot(_1249, float2(0.829999983310699462890625, -0.569999992847442626953125)), 1.7000000476837158203125));
        _1273 = _72._m1[5].w;
        float _1281 = spvFMul(dot(_1080.xyz, float3(3.099999904632568359375, 2.2999999523162841796875, 2.7000000476837158203125)), 3.0);
        _1300 = float3(_72._m1[5].x, 0.0, _72._m1[5].y);
        _1302 = _72._m1[5].z;
        float3 _1707;
        _1707 = float3(0.0);
        for (int _1706 = 0; _1706 < 4; )
        {
            _1707 += (_72._m2[int(in.m_53[_1706])].xyz * in.m_77[_1706]);
            _1706++;
            continue;
        }
        _1086 = _72._m1[0].x;
        _1088 = float3(fast::max(_1086, 0.001000000047497451305389404296875));
        float3 _1092 = spvFAdd(_1300 * spvFMul(spvFMul(spvFMul(_1302, spvFAdd(1.0, spvFMul(_1273, spvFSub(spvFMul(spvFAdd(0.5, spvFMul(spvFMul(0.5, sin(spvFAdd(spvFMul(_72._m1[6].x, 0.61000001430511474609375), _1257))), sin(spvFAdd(spvFMul(_72._m1[6].x, 0.23000000417232513427734375), spvFMul(_1257, 0.699999988079071044921875))))), 1.60000002384185791015625), 0.60000002384185791015625)))), spvFAdd(0.699999988079071044921875, spvFMul(spvFMul(0.300000011920928955078125, sin(spvFAdd(spvFMul(_72._m1[6].x, 4.69999980926513671875), _1281))), sin(spvFAdd(spvFMul(_72._m1[6].x, 2.900000095367431640625), spvFMul(_1281, 0.37000000476837158203125)))))), 0.3499999940395355224609375), _1707 / _1088) * _1075;
        if (_1078)
        {
            _1710 = fast::normalize((float3x3(float3(_1031.xyz), float3(_1034.xyz), float3(_1037.xyz)) * in.m_457.xyz) + (_1092 * (2.0 * in.m_438.y)));
            _1709 = spvFAdd(_1029, _1092 * spvFMul(spvFMul(_1086, in.m_438.y), in.m_438.y));
            break;
        }
        float _1142 = spvFMul(_1086, fast::max(spvFSub(in.m_457.w, 1.0), 0.0));
        if (in.m_482.y <= 0.0)
        {
            _1710 = _1073;
            _1709 = spvFAdd(_1029, _1073 * spvFAdd(spvFMul(_1142, 0.039999999105930328369140625), 0.00039999998989515006542205810546875));
            break;
        }
        float3 _1174 = spvFMulMatrixVector(float3x3(float3(_1031.xyz), float3(_1034.xyz), float3(_1037.xyz)), in.m_457.xyz);
        float _1177 = fast::min(length(_1174), 1.0);
        float3 _1183 = spvFAdd(float3(0.0, -_72._m1[1].w, 0.0), _1092);
        float _1209 = spvFMul(_1142, in.m_482.y);
        float3 _1210 = fast::normalize(spvFAdd(spvFAdd(_1073 * spvFSub(1.0, _1177), _1174), _1183 * spvFMul(0.5, in.m_482.y))) * _1209;
        float _1213 = dot(_1210, _1073);
        float _1217 = spvFMul(_1209, 0.119999997317790985107421875);
        float3 _1708;
        if (_1213 < _1217)
        {
            _1708 = spvFAdd(_1210, _1073 * spvFSub(_1217, _1213));
        }
        else
        {
            _1708 = _1210;
        }
        _1710 = fast::normalize(((_1073 * (1.0 - _1177)) + _1174) + (_1183 * in.m_482.y));
        _1709 = spvFAdd(_1029, _1708);
        break;
    } while(false);
    float3 _1718;
    do
    {
        float3 _1373 = (_663 * _1027).xyz;
        float4 _1375 = _663[0];
        float3 _1376 = _1375.xyz;
        float4 _1378 = _663[1];
        float3 _1379 = _1378.xyz;
        float4 _1381 = _663[2];
        float3 _1382 = _1381.xyz;
        float3 _1391 = cross(_1376, _1379);
        float3 _1417 = fast::normalize(spvFMulMatrixVector(float3x3(cross(_1379, _1382), cross(_1382, _1376), _1391), _1069) * ((dot(_1391, _1382) < 0.0) ? (-1.0) : 1.0));
        float4 _1424 = _663[3];
        float2 _1593 = _1424.xz;
        float _1601 = spvFAdd(spvFMul(dot(_1593, _1247), 0.3499999940395355224609375), spvFMul(dot(_1593, float2(0.829999983310699462890625, -0.569999992847442626953125)), 1.7000000476837158203125));
        float _1625 = spvFMul(dot(_1424.xyz, float3(3.099999904632568359375, 2.2999999523162841796875, 2.7000000476837158203125)), 3.0);
        float3 _1716;
        _1716 = float3(0.0);
        for (int _1715 = 0; _1715 < 4; )
        {
            _1716 += (_72._m2[int(in.m_53[_1715])].xyz * in.m_77[_1715]);
            _1715++;
            continue;
        }
        float3 _1436 = spvFAdd(_1300 * spvFMul(spvFMul(spvFMul(_1302, spvFAdd(1.0, spvFMul(_1273, spvFSub(spvFMul(spvFAdd(0.5, spvFMul(spvFMul(0.5, sin(spvFAdd(spvFMul(_72._m1[6].y, 0.61000001430511474609375), _1601))), sin(spvFAdd(spvFMul(_72._m1[6].y, 0.23000000417232513427734375), spvFMul(_1601, 0.699999988079071044921875))))), 1.60000002384185791015625), 0.60000002384185791015625)))), spvFAdd(0.699999988079071044921875, spvFMul(spvFMul(0.300000011920928955078125, sin(spvFAdd(spvFMul(_72._m1[6].y, 4.69999980926513671875), _1625))), sin(spvFAdd(spvFMul(_72._m1[6].y, 2.900000095367431640625), spvFMul(_1625, 0.37000000476837158203125)))))), 0.3499999940395355224609375), _1716 / _1088) * _1075;
        if (_1078)
        {
            _1718 = spvFAdd(_1373, _1436 * spvFMul(spvFMul(_1086, in.m_438.y), in.m_438.y));
            break;
        }
        float _1486 = spvFMul(_1086, fast::max(spvFSub(in.m_457.w, 1.0), 0.0));
        if (in.m_482.y <= 0.0)
        {
            _1718 = spvFAdd(_1373, _1417 * spvFAdd(spvFMul(_1486, 0.039999999105930328369140625), 0.00039999998989515006542205810546875));
            break;
        }
        float3 _1518 = spvFMulMatrixVector(float3x3(float3(_1375.xyz), float3(_1378.xyz), float3(_1381.xyz)), in.m_457.xyz);
        float _1553 = spvFMul(_1486, in.m_482.y);
        float3 _1554 = fast::normalize(spvFAdd(spvFAdd(_1417 * spvFSub(1.0, fast::min(length(_1518), 1.0)), _1518), spvFAdd(float3(0.0, -_72._m1[1].w, 0.0), _1436) * spvFMul(0.5, in.m_482.y))) * _1553;
        float _1557 = dot(_1554, _1417);
        float _1561 = spvFMul(_1553, 0.119999997317790985107421875);
        float3 _1717;
        if (_1557 < _1561)
        {
            _1717 = spvFAdd(_1554, _1417 * spvFSub(_1561, _1557));
        }
        else
        {
            _1717 = _1554;
        }
        _1718 = spvFAdd(_1373, _1717);
        break;
    } while(false);
    float4 _739 = float4(_1709, 1.0);
    out.gl_Position = spvFMulMatrixVector(_731._m0, _739);
    out.gl_Position.y = -out.gl_Position.y;
    out.m_754 = _1709;
    out.m_756 = (_1060 * _1069) * ((dot(_1047, _1038) < 0.0) ? (-1.0) : 1.0);
    out.m_763 = in.m_438;
    out.m_765 = in.m_766;
    out.m_768 = float4(in.m_482.x, 0.0, 0.0, 0.0);
    out.m_790 = spvFMulMatrixVector(_731._m2, _739);
    out.m_792 = spvFMulMatrixVector(_731._m3, float4(_1718, 1.0));
    float _1725;
    if (_1078)
    {
        _1725 = in.m_438.y;
    }
    else
    {
        _1725 = in.m_482.y;
    }
    float _1726;
    if (_1078)
    {
        _1726 = fract(in.m_457.w);
    }
    else
    {
        _1726 = 0.0;
    }
    bool _821 = !_1078;
    bool _827;
    if (_821)
    {
        _827 = in.m_482.y <= 0.0;
    }
    else
    {
        _827 = _821;
    }
    out.m_798 = float4(_1725, _1726, float(_1078), float(_827));
    out.m_830 = _1710;
    out.m_832 = _1023;
    out.m_834 = _1069;
    out.gl_Position.y = -(out.gl_Position.y);    // Invert Y-axis for Metal
    return out;
}

