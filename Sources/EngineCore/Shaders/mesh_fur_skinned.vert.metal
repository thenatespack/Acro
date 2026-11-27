// Generated from mesh_fur_skinned.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 120ab4424b2a5b08
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

struct _668
{
    float4x4 _m0;
    float4x4 _m1;
    float4x4 _m2;
    float4x4 _m3;
};

struct vertex_main_out
{
    float3 m_839 [[user(locn0)]];
    float3 m_841 [[user(locn1)]];
    float2 m_746 [[user(locn2)]];
    float4 m_847 [[user(locn3)]];
    float3 m_749 [[user(locn4)]];
    float4 m_849 [[user(locn5)]];
    float4 m_871 [[user(locn6)]];
    float4 m_873 [[user(locn7)]];
    float4 m_705 [[user(locn8)]];
    float3 m_875 [[user(locn9)]];
    float3 m_751 [[user(locn10)]];
    float4 gl_Position [[position]];
};

struct vertex_main_in
{
    float3 m_345 [[attribute(0)]];
    float3 m_401 [[attribute(1)]];
    float2 m_447 [[attribute(2)]];
    float4 m_624 [[attribute(3)]];
    float4 m_626 [[attribute(4)]];
    float4 m_628 [[attribute(5)]];
    float4 m_630 [[attribute(6)]];
    float4 m_754 [[attribute(7)]];
    float4 m_756 [[attribute(8)]];
    float4 m_758 [[attribute(9)]];
    float4 m_760 [[attribute(10)]];
    float4 m_416 [[attribute(11)]];
    float4 m_491 [[attribute(12)]];
    float4 m_466 [[attribute(13)]];
    float4 m_53 [[attribute(14)]];
    float4 m_77 [[attribute(15)]];
};

vertex vertex_main_out vertex_main(vertex_main_in in [[stage_in]], constant _70& _72 [[buffer(2)]], constant _668& _670 [[buffer(15)]])
{
    vertex_main_out out = {};
    float4 _1782;
    float4 _1783;
    float4 _1784;
    _1784 = float4(0.0);
    _1783 = float4(0.0);
    _1782 = float4(0.0);
    for (int _1781 = 0; _1781 < 4; )
    {
        int _900 = int(in.m_53[_1781]) * 3;
        _1784 = spvFAdd(_1784, _72._m3[_900 + 2] * in.m_77[_1781]);
        _1783 = spvFAdd(_1783, _72._m3[_900 + 1] * in.m_77[_1781]);
        _1782 = spvFAdd(_1782, _72._m3[_900] * in.m_77[_1781]);
        _1781++;
        continue;
    }
    float3 _992;
    float4 _996;
    float3 _1007;
    float3 _1016;
    float3x3 _1029;
    float3 _1038;
    bool _1047;
    float _1059;
    float3 _1061;
    float _1066;
    float2 _1235;
    float _1261;
    float3 _1288;
    float _1290;
    float4x4 _655 = spvFMulMatrixMatrix(float4x4(in.m_624, in.m_626, in.m_628, in.m_630), transpose(float4x4(_1782, _1783, _1784, float4(0.0, 0.0, 0.0, 1.0))));
    float3 _1789;
    float3 _1790;
    do
    {
        _992 = in.m_345;
        _996 = float4(_992, 1.0);
        float3 _998 = (_655 * _996).xyz;
        float4 _1000 = _655[0];
        float3 _1001 = _1000.xyz;
        float4 _1003 = _655[1];
        float3 _1004 = _1003.xyz;
        float4 _1006 = _655[2];
        _1007 = _1006.xyz;
        _1016 = cross(_1001, _1004);
        _1029 = float3x3(cross(_1004, _1007), cross(_1007, _1001), _1016);
        _1038 = in.m_401;
        float3 _1042 = fast::normalize(spvFMulMatrixVector(_1029, _1038) * ((dot(_1016, _1007) < 0.0) ? (-1.0) : 1.0));
        _1047 = _72._m1[3].w > 0.5;
        float4 _1053 = _655[3];
        _1235 = _72._m1[5].xy;
        float2 _1237 = _1053.xz;
        float _1245 = spvFAdd(spvFMul(dot(_1237, _1235), 0.3499999940395355224609375), spvFMul(dot(_1237, float2(0.829999983310699462890625, -0.569999992847442626953125)), 1.7000000476837158203125));
        _1261 = _72._m1[5].w;
        float _1269 = spvFMul(dot(_1053.xyz, float3(3.099999904632568359375, 2.2999999523162841796875, 2.7000000476837158203125)), 3.0);
        _1288 = float3(_72._m1[5].x, 0.0, _72._m1[5].y);
        _1290 = _72._m1[5].z;
        float3 _1786;
        _1786 = float3(0.0);
        for (int _1785 = 0; _1785 < 4; )
        {
            _1786 += (_72._m2[int(in.m_53[_1785])].xyz * in.m_77[_1785]);
            _1785++;
            continue;
        }
        _1059 = _72._m1[0].x;
        _1061 = float3(fast::max(_1059, 0.001000000047497451305389404296875));
        _1066 = spvFMul(_72._m1[2].x, (in.m_416.w < (-0.5)) ? 0.0 : 1.0);
        float3 _1067 = spvFAdd(_1288 * spvFMul(spvFMul(spvFMul(_1290, spvFAdd(1.0, spvFMul(_1261, spvFSub(spvFMul(spvFAdd(0.5, spvFMul(spvFMul(0.5, sin(spvFAdd(spvFMul(_72._m1[6].x, 0.61000001430511474609375), _1245))), sin(spvFAdd(spvFMul(_72._m1[6].x, 0.23000000417232513427734375), spvFMul(_1245, 0.699999988079071044921875))))), 1.60000002384185791015625), 0.60000002384185791015625)))), spvFAdd(0.699999988079071044921875, spvFMul(spvFMul(0.300000011920928955078125, sin(spvFAdd(spvFMul(_72._m1[6].x, 4.69999980926513671875), _1269))), sin(spvFAdd(spvFMul(_72._m1[6].x, 2.900000095367431640625), spvFMul(_1269, 0.37000000476837158203125)))))), 0.3499999940395355224609375), _1786 / _1061) * _1066;
        if (_1047)
        {
            _1790 = fast::normalize((float3x3(float3(_1000.xyz), float3(_1003.xyz), float3(_1006.xyz)) * in.m_466.xyz) + (_1067 * (2.0 * in.m_447.y)));
            _1789 = spvFAdd(_998, _1067 * spvFMul(spvFMul(_1059, in.m_447.y), in.m_447.y));
            break;
        }
        bool _1111 = in.m_491.y > 1.5;
        float _1787;
        if (_1111)
        {
            _1787 = in.m_447.y;
        }
        else
        {
            _1787 = in.m_491.y;
        }
        float _1127 = spvFMul(_1059, fast::max(spvFSub(in.m_466.w, 1.0), 0.0));
        if ((_1787 <= 0.0) && (!_1111))
        {
            _1790 = _1042;
            _1789 = spvFAdd(_998, _1042 * spvFAdd(spvFMul(_1127, 0.039999999105930328369140625), 0.00039999998989515006542205810546875));
            break;
        }
        float3 _1162 = spvFMulMatrixVector(float3x3(float3(_1000.xyz), float3(_1003.xyz), float3(_1006.xyz)), in.m_466.xyz);
        float _1165 = fast::min(length(_1162), 1.0);
        float3 _1171 = spvFAdd(float3(0.0, -_72._m1[1].w, 0.0), _1067);
        float _1197 = spvFMul(_1127, _1787);
        float3 _1198 = fast::normalize(spvFAdd(spvFAdd(_1042 * spvFSub(1.0, _1165), _1162), _1171 * spvFMul(0.5, _1787))) * _1197;
        float _1201 = dot(_1198, _1042);
        float _1205 = spvFMul(_1197, 0.119999997317790985107421875);
        float3 _1788;
        if (_1201 < _1205)
        {
            _1788 = spvFAdd(_1198, _1042 * spvFSub(_1205, _1201));
        }
        else
        {
            _1788 = _1198;
        }
        _1790 = fast::normalize(((_1042 * (1.0 - _1165)) + _1162) + (_1171 * _1787));
        _1789 = spvFAdd(_998, _1788);
        break;
    } while(false);
    float4 _678 = float4(_1789, 1.0);
    out.gl_Position = spvFMulMatrixVector(_670._m0, _678);
    out.gl_Position.y = -out.gl_Position.y;
    bool _698 = !_1047;
    bool _704;
    if (_698)
    {
        _704 = in.m_491.y > 1.5;
    }
    else
    {
        _704 = _698;
    }
    float _1792;
    if (_1047 || _704)
    {
        _1792 = in.m_447.y;
    }
    else
    {
        _1792 = in.m_491.y;
    }
    float _1793;
    if (_1047)
    {
        _1793 = fract(in.m_466.w);
    }
    else
    {
        _1793 = 0.0;
    }
    float _1794;
    if (_1047)
    {
        _1794 = 1.0;
    }
    else
    {
        _1794 = _704 ? 2.0 : 0.0;
    }
    bool _742;
    if (_698)
    {
        _742 = in.m_491.y <= 0.0;
    }
    else
    {
        _742 = _698;
    }
    out.m_705 = float4(_1792, _1793, _1794, float(_742));
    out.m_746 = in.m_447;
    out.m_749 = _992;
    out.m_751 = _1038;
    float4 _1796;
    float4 _1797;
    float4 _1798;
    _1798 = float4(0.0);
    _1797 = float4(0.0);
    _1796 = float4(0.0);
    for (int _1795 = 0; _1795 < 4; )
    {
        int _1341 = int(in.m_53[_1795]) * 3;
        _1798 = spvFAdd(_1798, _72._m4[_1341 + 2] * in.m_77[_1795]);
        _1797 = spvFAdd(_1797, _72._m4[_1341 + 1] * in.m_77[_1795]);
        _1796 = spvFAdd(_1796, _72._m4[_1341] * in.m_77[_1795]);
        _1795++;
        continue;
    }
    float4x4 _785 = spvFMulMatrixMatrix(float4x4(in.m_754, in.m_756, in.m_758, in.m_760), transpose(float4x4(_1796, _1797, _1798, float4(0.0, 0.0, 0.0, 1.0))));
    float3 _1803;
    do
    {
        float3 _1439 = (_785 * _996).xyz;
        float4 _1441 = _785[0];
        float3 _1442 = _1441.xyz;
        float4 _1444 = _785[1];
        float3 _1445 = _1444.xyz;
        float4 _1447 = _785[2];
        float3 _1448 = _1447.xyz;
        float3 _1457 = cross(_1442, _1445);
        float3 _1483 = fast::normalize(spvFMulMatrixVector(float3x3(cross(_1445, _1448), cross(_1448, _1442), _1457), _1038) * ((dot(_1457, _1448) < 0.0) ? (-1.0) : 1.0));
        float4 _1494 = _785[3];
        float2 _1678 = _1494.xz;
        float _1686 = spvFAdd(spvFMul(dot(_1678, _1235), 0.3499999940395355224609375), spvFMul(dot(_1678, float2(0.829999983310699462890625, -0.569999992847442626953125)), 1.7000000476837158203125));
        float _1710 = spvFMul(dot(_1494.xyz, float3(3.099999904632568359375, 2.2999999523162841796875, 2.7000000476837158203125)), 3.0);
        float3 _1800;
        _1800 = float3(0.0);
        for (int _1799 = 0; _1799 < 4; )
        {
            _1800 += (_72._m2[int(in.m_53[_1799])].xyz * in.m_77[_1799]);
            _1799++;
            continue;
        }
        float3 _1508 = spvFAdd(_1288 * spvFMul(spvFMul(spvFMul(_1290, spvFAdd(1.0, spvFMul(_1261, spvFSub(spvFMul(spvFAdd(0.5, spvFMul(spvFMul(0.5, sin(spvFAdd(spvFMul(_72._m1[6].y, 0.61000001430511474609375), _1686))), sin(spvFAdd(spvFMul(_72._m1[6].y, 0.23000000417232513427734375), spvFMul(_1686, 0.699999988079071044921875))))), 1.60000002384185791015625), 0.60000002384185791015625)))), spvFAdd(0.699999988079071044921875, spvFMul(spvFMul(0.300000011920928955078125, sin(spvFAdd(spvFMul(_72._m1[6].y, 4.69999980926513671875), _1710))), sin(spvFAdd(spvFMul(_72._m1[6].y, 2.900000095367431640625), spvFMul(_1710, 0.37000000476837158203125)))))), 0.3499999940395355224609375), _1800 / _1061) * _1066;
        if (_1047)
        {
            _1803 = spvFAdd(_1439, _1508 * spvFMul(spvFMul(_1059, in.m_447.y), in.m_447.y));
            break;
        }
        bool _1552 = in.m_491.y > 1.5;
        float _1801;
        if (_1552)
        {
            _1801 = in.m_447.y;
        }
        else
        {
            _1801 = in.m_491.y;
        }
        float _1568 = spvFMul(_1059, fast::max(spvFSub(in.m_466.w, 1.0), 0.0));
        if ((_1801 <= 0.0) && (!_1552))
        {
            _1803 = spvFAdd(_1439, _1483 * spvFAdd(spvFMul(_1568, 0.039999999105930328369140625), 0.00039999998989515006542205810546875));
            break;
        }
        float3 _1603 = spvFMulMatrixVector(float3x3(float3(_1441.xyz), float3(_1444.xyz), float3(_1447.xyz)), in.m_466.xyz);
        float _1638 = spvFMul(_1568, _1801);
        float3 _1639 = fast::normalize(spvFAdd(spvFAdd(_1483 * spvFSub(1.0, fast::min(length(_1603), 1.0)), _1603), spvFAdd(float3(0.0, -_72._m1[1].w, 0.0), _1508) * spvFMul(0.5, _1801))) * _1638;
        float _1642 = dot(_1639, _1483);
        float _1646 = spvFMul(_1638, 0.119999997317790985107421875);
        float3 _1802;
        if (_1642 < _1646)
        {
            _1802 = spvFAdd(_1639, _1483 * spvFSub(_1646, _1642));
        }
        else
        {
            _1802 = _1639;
        }
        _1803 = spvFAdd(_1439, _1802);
        break;
    } while(false);
    out.m_839 = _1789;
    out.m_841 = (_1029 * _1038) * ((dot(_1016, _1007) < 0.0) ? (-1.0) : 1.0);
    out.m_847 = in.m_416;
    out.m_849 = float4(in.m_491.x, 0.0, 0.0, 0.0);
    out.m_871 = spvFMulMatrixVector(_670._m2, _678);
    out.m_873 = spvFMulMatrixVector(_670._m3, float4(_1803, 1.0));
    out.m_875 = _1790;
    out.gl_Position.y = -(out.gl_Position.y);    // Invert Y-axis for Metal
    return out;
}

