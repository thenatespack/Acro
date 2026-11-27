// Generated from mesh_fur_skinned.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: bfe5988631990025
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

struct _643
{
    float4x4 _m0;
    float4x4 _m1;
    float4x4 _m2;
    float4x4 _m3;
};

struct vertex_main_out
{
    float3 m_797 [[user(locn0)]];
    float3 m_799 [[user(locn1)]];
    float2 m_704 [[user(locn2)]];
    float4 m_805 [[user(locn3)]];
    float3 m_707 [[user(locn4)]];
    float4 m_808 [[user(locn5)]];
    float4 m_830 [[user(locn6)]];
    float4 m_832 [[user(locn7)]];
    float4 m_671 [[user(locn8)]];
    float3 m_834 [[user(locn9)]];
    float3 m_709 [[user(locn10)]];
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
    float4 m_712 [[attribute(7)]];
    float4 m_714 [[attribute(8)]];
    float4 m_716 [[attribute(9)]];
    float4 m_718 [[attribute(10)]];
    float4 m_806 [[attribute(11)]];
    float4 m_482 [[attribute(12)]];
    float4 m_457 [[attribute(13)]];
    float4 m_53 [[attribute(14)]];
    float4 m_77 [[attribute(15)]];
};

vertex vertex_main_out vertex_main(vertex_main_in in [[stage_in]], constant _70& _72 [[buffer(2)]], constant _643& _645 [[buffer(15)]])
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
    float3 _948;
    float4 _952;
    float3 _963;
    float3 _972;
    float3x3 _985;
    float3 _994;
    float _1000;
    bool _1003;
    float _1011;
    float3 _1013;
    float2 _1172;
    float _1198;
    float3 _1225;
    float _1227;
    float4x4 _630 = spvFMulMatrixMatrix(float4x4(in.m_599, in.m_601, in.m_603, in.m_605), transpose(float4x4(_1697, _1698, _1699, float4(0.0, 0.0, 0.0, 1.0))));
    float3 _1703;
    float3 _1704;
    do
    {
        _948 = in.m_345;
        _952 = float4(_948, 1.0);
        float3 _954 = (_630 * _952).xyz;
        float4 _956 = _630[0];
        float3 _957 = _956.xyz;
        float4 _959 = _630[1];
        float3 _960 = _959.xyz;
        float4 _962 = _630[2];
        _963 = _962.xyz;
        _972 = cross(_957, _960);
        _985 = float3x3(cross(_960, _963), cross(_963, _957), _972);
        _994 = in.m_401;
        float3 _998 = fast::normalize(spvFMulMatrixVector(_985, _994) * ((dot(_972, _963) < 0.0) ? (-1.0) : 1.0));
        _1000 = _72._m1[2].x;
        _1003 = _72._m1[3].w > 0.5;
        float4 _1005 = _630[3];
        _1172 = _72._m1[5].xy;
        float2 _1174 = _1005.xz;
        float _1182 = spvFAdd(spvFMul(dot(_1174, _1172), 0.3499999940395355224609375), spvFMul(dot(_1174, float2(0.829999983310699462890625, -0.569999992847442626953125)), 1.7000000476837158203125));
        _1198 = _72._m1[5].w;
        float _1206 = spvFMul(dot(_1005.xyz, float3(3.099999904632568359375, 2.2999999523162841796875, 2.7000000476837158203125)), 3.0);
        _1225 = float3(_72._m1[5].x, 0.0, _72._m1[5].y);
        _1227 = _72._m1[5].z;
        float3 _1701;
        _1701 = float3(0.0);
        for (int _1700 = 0; _1700 < 4; )
        {
            _1701 += (_72._m2[int(in.m_53[_1700])].xyz * in.m_77[_1700]);
            _1700++;
            continue;
        }
        _1011 = _72._m1[0].x;
        _1013 = float3(fast::max(_1011, 0.001000000047497451305389404296875));
        float3 _1017 = spvFAdd(_1225 * spvFMul(spvFMul(spvFMul(_1227, spvFAdd(1.0, spvFMul(_1198, spvFSub(spvFMul(spvFAdd(0.5, spvFMul(spvFMul(0.5, sin(spvFAdd(spvFMul(_72._m1[6].x, 0.61000001430511474609375), _1182))), sin(spvFAdd(spvFMul(_72._m1[6].x, 0.23000000417232513427734375), spvFMul(_1182, 0.699999988079071044921875))))), 1.60000002384185791015625), 0.60000002384185791015625)))), spvFAdd(0.699999988079071044921875, spvFMul(spvFMul(0.300000011920928955078125, sin(spvFAdd(spvFMul(_72._m1[6].x, 4.69999980926513671875), _1206))), sin(spvFAdd(spvFMul(_72._m1[6].x, 2.900000095367431640625), spvFMul(_1206, 0.37000000476837158203125)))))), 0.3499999940395355224609375), _1701 / _1013) * _1000;
        if (_1003)
        {
            _1704 = fast::normalize((float3x3(float3(_956.xyz), float3(_959.xyz), float3(_962.xyz)) * in.m_457.xyz) + (_1017 * (2.0 * in.m_438.y)));
            _1703 = spvFAdd(_954, _1017 * spvFMul(spvFMul(_1011, in.m_438.y), in.m_438.y));
            break;
        }
        float _1067 = spvFMul(_1011, fast::max(spvFSub(in.m_457.w, 1.0), 0.0));
        if (in.m_482.y <= 0.0)
        {
            _1704 = _998;
            _1703 = spvFAdd(_954, _998 * spvFAdd(spvFMul(_1067, 0.039999999105930328369140625), 0.00039999998989515006542205810546875));
            break;
        }
        float3 _1099 = spvFMulMatrixVector(float3x3(float3(_956.xyz), float3(_959.xyz), float3(_962.xyz)), in.m_457.xyz);
        float _1102 = fast::min(length(_1099), 1.0);
        float3 _1108 = spvFAdd(float3(0.0, -_72._m1[1].w, 0.0), _1017);
        float _1134 = spvFMul(_1067, in.m_482.y);
        float3 _1135 = fast::normalize(spvFAdd(spvFAdd(_998 * spvFSub(1.0, _1102), _1099), _1108 * spvFMul(0.5, in.m_482.y))) * _1134;
        float _1138 = dot(_1135, _998);
        float _1142 = spvFMul(_1134, 0.119999997317790985107421875);
        float3 _1702;
        if (_1138 < _1142)
        {
            _1702 = spvFAdd(_1135, _998 * spvFSub(_1142, _1138));
        }
        else
        {
            _1702 = _1135;
        }
        _1704 = fast::normalize(((_998 * (1.0 - _1102)) + _1099) + (_1108 * in.m_482.y));
        _1703 = spvFAdd(_954, _1702);
        break;
    } while(false);
    float4 _653 = float4(_1703, 1.0);
    out.gl_Position = spvFMulMatrixVector(_645._m0, _653);
    out.gl_Position.y = -out.gl_Position.y;
    float _1706;
    if (_1003)
    {
        _1706 = in.m_438.y;
    }
    else
    {
        _1706 = in.m_482.y;
    }
    float _1707;
    if (_1003)
    {
        _1707 = fract(in.m_457.w);
    }
    else
    {
        _1707 = 0.0;
    }
    bool _694 = !_1003;
    bool _700;
    if (_694)
    {
        _700 = in.m_482.y <= 0.0;
    }
    else
    {
        _700 = _694;
    }
    out.m_671 = float4(_1706, _1707, float(_1003), float(_700));
    out.m_704 = in.m_438;
    out.m_707 = _948;
    out.m_709 = _994;
    float4 _1709;
    float4 _1710;
    float4 _1711;
    _1711 = float4(0.0);
    _1710 = float4(0.0);
    _1709 = float4(0.0);
    for (int _1708 = 0; _1708 < 4; )
    {
        int _1278 = int(in.m_53[_1708]) * 3;
        _1711 = spvFAdd(_1711, _72._m4[_1278 + 2] * in.m_77[_1708]);
        _1710 = spvFAdd(_1710, _72._m4[_1278 + 1] * in.m_77[_1708]);
        _1709 = spvFAdd(_1709, _72._m4[_1278] * in.m_77[_1708]);
        _1708++;
        continue;
    }
    float4x4 _743 = spvFMulMatrixMatrix(float4x4(in.m_712, in.m_714, in.m_716, in.m_718), transpose(float4x4(_1709, _1710, _1711, float4(0.0, 0.0, 0.0, 1.0))));
    float3 _1715;
    do
    {
        float3 _1373 = (_743 * _952).xyz;
        float4 _1375 = _743[0];
        float3 _1376 = _1375.xyz;
        float4 _1378 = _743[1];
        float3 _1379 = _1378.xyz;
        float4 _1381 = _743[2];
        float3 _1382 = _1381.xyz;
        float3 _1391 = cross(_1376, _1379);
        float3 _1417 = fast::normalize(spvFMulMatrixVector(float3x3(cross(_1379, _1382), cross(_1382, _1376), _1391), _994) * ((dot(_1391, _1382) < 0.0) ? (-1.0) : 1.0));
        float4 _1424 = _743[3];
        float2 _1593 = _1424.xz;
        float _1601 = spvFAdd(spvFMul(dot(_1593, _1172), 0.3499999940395355224609375), spvFMul(dot(_1593, float2(0.829999983310699462890625, -0.569999992847442626953125)), 1.7000000476837158203125));
        float _1625 = spvFMul(dot(_1424.xyz, float3(3.099999904632568359375, 2.2999999523162841796875, 2.7000000476837158203125)), 3.0);
        float3 _1713;
        _1713 = float3(0.0);
        for (int _1712 = 0; _1712 < 4; )
        {
            _1713 += (_72._m2[int(in.m_53[_1712])].xyz * in.m_77[_1712]);
            _1712++;
            continue;
        }
        float3 _1436 = spvFAdd(_1225 * spvFMul(spvFMul(spvFMul(_1227, spvFAdd(1.0, spvFMul(_1198, spvFSub(spvFMul(spvFAdd(0.5, spvFMul(spvFMul(0.5, sin(spvFAdd(spvFMul(_72._m1[6].y, 0.61000001430511474609375), _1601))), sin(spvFAdd(spvFMul(_72._m1[6].y, 0.23000000417232513427734375), spvFMul(_1601, 0.699999988079071044921875))))), 1.60000002384185791015625), 0.60000002384185791015625)))), spvFAdd(0.699999988079071044921875, spvFMul(spvFMul(0.300000011920928955078125, sin(spvFAdd(spvFMul(_72._m1[6].y, 4.69999980926513671875), _1625))), sin(spvFAdd(spvFMul(_72._m1[6].y, 2.900000095367431640625), spvFMul(_1625, 0.37000000476837158203125)))))), 0.3499999940395355224609375), _1713 / _1013) * _1000;
        if (_1003)
        {
            _1715 = spvFAdd(_1373, _1436 * spvFMul(spvFMul(_1011, in.m_438.y), in.m_438.y));
            break;
        }
        float _1486 = spvFMul(_1011, fast::max(spvFSub(in.m_457.w, 1.0), 0.0));
        if (in.m_482.y <= 0.0)
        {
            _1715 = spvFAdd(_1373, _1417 * spvFAdd(spvFMul(_1486, 0.039999999105930328369140625), 0.00039999998989515006542205810546875));
            break;
        }
        float3 _1518 = spvFMulMatrixVector(float3x3(float3(_1375.xyz), float3(_1378.xyz), float3(_1381.xyz)), in.m_457.xyz);
        float _1553 = spvFMul(_1486, in.m_482.y);
        float3 _1554 = fast::normalize(spvFAdd(spvFAdd(_1417 * spvFSub(1.0, fast::min(length(_1518), 1.0)), _1518), spvFAdd(float3(0.0, -_72._m1[1].w, 0.0), _1436) * spvFMul(0.5, in.m_482.y))) * _1553;
        float _1557 = dot(_1554, _1417);
        float _1561 = spvFMul(_1553, 0.119999997317790985107421875);
        float3 _1714;
        if (_1557 < _1561)
        {
            _1714 = spvFAdd(_1554, _1417 * spvFSub(_1561, _1557));
        }
        else
        {
            _1714 = _1554;
        }
        _1715 = spvFAdd(_1373, _1714);
        break;
    } while(false);
    out.m_797 = _1703;
    out.m_799 = (_985 * _994) * ((dot(_972, _963) < 0.0) ? (-1.0) : 1.0);
    out.m_805 = in.m_806;
    out.m_808 = float4(in.m_482.x, 0.0, 0.0, 0.0);
    out.m_830 = spvFMulMatrixVector(_645._m2, _653);
    out.m_832 = spvFMulMatrixVector(_645._m3, float4(_1715, 1.0));
    out.m_834 = _1704;
    out.gl_Position.y = -(out.gl_Position.y);    // Invert Y-axis for Metal
    return out;
}

