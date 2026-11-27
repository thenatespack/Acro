// Generated from mesh_fur_skinned.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 1f4f9fe8aceb91f6
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

struct _659
{
    float4x4 _m0;
    float4x4 _m1;
    float4x4 _m2;
    float4x4 _m3;
};

struct vertex_main_out
{
    float3 m_830 [[user(locn0)]];
    float3 m_832 [[user(locn1)]];
    float2 m_737 [[user(locn2)]];
    float4 m_838 [[user(locn3)]];
    float3 m_740 [[user(locn4)]];
    float4 m_841 [[user(locn5)]];
    float4 m_863 [[user(locn6)]];
    float4 m_865 [[user(locn7)]];
    float4 m_696 [[user(locn8)]];
    float3 m_867 [[user(locn9)]];
    float3 m_742 [[user(locn10)]];
    float4 gl_Position [[position]];
};

struct vertex_main_in
{
    float3 m_345 [[attribute(0)]];
    float3 m_401 [[attribute(1)]];
    float2 m_438 [[attribute(2)]];
    float4 m_615 [[attribute(3)]];
    float4 m_617 [[attribute(4)]];
    float4 m_619 [[attribute(5)]];
    float4 m_621 [[attribute(6)]];
    float4 m_745 [[attribute(7)]];
    float4 m_747 [[attribute(8)]];
    float4 m_749 [[attribute(9)]];
    float4 m_751 [[attribute(10)]];
    float4 m_839 [[attribute(11)]];
    float4 m_482 [[attribute(12)]];
    float4 m_457 [[attribute(13)]];
    float4 m_53 [[attribute(14)]];
    float4 m_77 [[attribute(15)]];
};

vertex vertex_main_out vertex_main(vertex_main_in in [[stage_in]], constant _70& _72 [[buffer(2)]], constant _659& _661 [[buffer(15)]])
{
    vertex_main_out out = {};
    float4 _1760;
    float4 _1761;
    float4 _1762;
    _1762 = float4(0.0);
    _1761 = float4(0.0);
    _1760 = float4(0.0);
    for (int _1759 = 0; _1759 < 4; )
    {
        int _892 = int(in.m_53[_1759]) * 3;
        _1762 = spvFAdd(_1762, _72._m3[_892 + 2] * in.m_77[_1759]);
        _1761 = spvFAdd(_1761, _72._m3[_892 + 1] * in.m_77[_1759]);
        _1760 = spvFAdd(_1760, _72._m3[_892] * in.m_77[_1759]);
        _1759++;
        continue;
    }
    float3 _983;
    float4 _987;
    float3 _998;
    float3 _1007;
    float3x3 _1020;
    float3 _1029;
    float _1035;
    bool _1038;
    float _1046;
    float3 _1048;
    float2 _1220;
    float _1246;
    float3 _1273;
    float _1275;
    float4x4 _646 = spvFMulMatrixMatrix(float4x4(in.m_615, in.m_617, in.m_619, in.m_621), transpose(float4x4(_1760, _1761, _1762, float4(0.0, 0.0, 0.0, 1.0))));
    float3 _1767;
    float3 _1768;
    do
    {
        _983 = in.m_345;
        _987 = float4(_983, 1.0);
        float3 _989 = (_646 * _987).xyz;
        float4 _991 = _646[0];
        float3 _992 = _991.xyz;
        float4 _994 = _646[1];
        float3 _995 = _994.xyz;
        float4 _997 = _646[2];
        _998 = _997.xyz;
        _1007 = cross(_992, _995);
        _1020 = float3x3(cross(_995, _998), cross(_998, _992), _1007);
        _1029 = in.m_401;
        float3 _1033 = fast::normalize(spvFMulMatrixVector(_1020, _1029) * ((dot(_1007, _998) < 0.0) ? (-1.0) : 1.0));
        _1035 = _72._m1[2].x;
        _1038 = _72._m1[3].w > 0.5;
        float4 _1040 = _646[3];
        _1220 = _72._m1[5].xy;
        float2 _1222 = _1040.xz;
        float _1230 = spvFAdd(spvFMul(dot(_1222, _1220), 0.3499999940395355224609375), spvFMul(dot(_1222, float2(0.829999983310699462890625, -0.569999992847442626953125)), 1.7000000476837158203125));
        _1246 = _72._m1[5].w;
        float _1254 = spvFMul(dot(_1040.xyz, float3(3.099999904632568359375, 2.2999999523162841796875, 2.7000000476837158203125)), 3.0);
        _1273 = float3(_72._m1[5].x, 0.0, _72._m1[5].y);
        _1275 = _72._m1[5].z;
        float3 _1764;
        _1764 = float3(0.0);
        for (int _1763 = 0; _1763 < 4; )
        {
            _1764 += (_72._m2[int(in.m_53[_1763])].xyz * in.m_77[_1763]);
            _1763++;
            continue;
        }
        _1046 = _72._m1[0].x;
        _1048 = float3(fast::max(_1046, 0.001000000047497451305389404296875));
        float3 _1052 = spvFAdd(_1273 * spvFMul(spvFMul(spvFMul(_1275, spvFAdd(1.0, spvFMul(_1246, spvFSub(spvFMul(spvFAdd(0.5, spvFMul(spvFMul(0.5, sin(spvFAdd(spvFMul(_72._m1[6].x, 0.61000001430511474609375), _1230))), sin(spvFAdd(spvFMul(_72._m1[6].x, 0.23000000417232513427734375), spvFMul(_1230, 0.699999988079071044921875))))), 1.60000002384185791015625), 0.60000002384185791015625)))), spvFAdd(0.699999988079071044921875, spvFMul(spvFMul(0.300000011920928955078125, sin(spvFAdd(spvFMul(_72._m1[6].x, 4.69999980926513671875), _1254))), sin(spvFAdd(spvFMul(_72._m1[6].x, 2.900000095367431640625), spvFMul(_1254, 0.37000000476837158203125)))))), 0.3499999940395355224609375), _1764 / _1048) * _1035;
        if (_1038)
        {
            _1768 = fast::normalize((float3x3(float3(_991.xyz), float3(_994.xyz), float3(_997.xyz)) * in.m_457.xyz) + (_1052 * (2.0 * in.m_438.y)));
            _1767 = spvFAdd(_989, _1052 * spvFMul(spvFMul(_1046, in.m_438.y), in.m_438.y));
            break;
        }
        bool _1096 = in.m_482.y > 1.5;
        float _1765;
        if (_1096)
        {
            _1765 = in.m_438.y;
        }
        else
        {
            _1765 = in.m_482.y;
        }
        float _1112 = spvFMul(_1046, fast::max(spvFSub(in.m_457.w, 1.0), 0.0));
        if ((_1765 <= 0.0) && (!_1096))
        {
            _1768 = _1033;
            _1767 = spvFAdd(_989, _1033 * spvFAdd(spvFMul(_1112, 0.039999999105930328369140625), 0.00039999998989515006542205810546875));
            break;
        }
        float3 _1147 = spvFMulMatrixVector(float3x3(float3(_991.xyz), float3(_994.xyz), float3(_997.xyz)), in.m_457.xyz);
        float _1150 = fast::min(length(_1147), 1.0);
        float3 _1156 = spvFAdd(float3(0.0, -_72._m1[1].w, 0.0), _1052);
        float _1182 = spvFMul(_1112, _1765);
        float3 _1183 = fast::normalize(spvFAdd(spvFAdd(_1033 * spvFSub(1.0, _1150), _1147), _1156 * spvFMul(0.5, _1765))) * _1182;
        float _1186 = dot(_1183, _1033);
        float _1190 = spvFMul(_1182, 0.119999997317790985107421875);
        float3 _1766;
        if (_1186 < _1190)
        {
            _1766 = spvFAdd(_1183, _1033 * spvFSub(_1190, _1186));
        }
        else
        {
            _1766 = _1183;
        }
        _1768 = fast::normalize(((_1033 * (1.0 - _1150)) + _1147) + (_1156 * _1765));
        _1767 = spvFAdd(_989, _1766);
        break;
    } while(false);
    float4 _669 = float4(_1767, 1.0);
    out.gl_Position = spvFMulMatrixVector(_661._m0, _669);
    out.gl_Position.y = -out.gl_Position.y;
    bool _689 = !_1038;
    bool _695;
    if (_689)
    {
        _695 = in.m_482.y > 1.5;
    }
    else
    {
        _695 = _689;
    }
    float _1770;
    if (_1038 || _695)
    {
        _1770 = in.m_438.y;
    }
    else
    {
        _1770 = in.m_482.y;
    }
    float _1771;
    if (_1038)
    {
        _1771 = fract(in.m_457.w);
    }
    else
    {
        _1771 = 0.0;
    }
    float _1772;
    if (_1038)
    {
        _1772 = 1.0;
    }
    else
    {
        _1772 = _695 ? 2.0 : 0.0;
    }
    bool _733;
    if (_689)
    {
        _733 = in.m_482.y <= 0.0;
    }
    else
    {
        _733 = _689;
    }
    out.m_696 = float4(_1770, _1771, _1772, float(_733));
    out.m_737 = in.m_438;
    out.m_740 = _983;
    out.m_742 = _1029;
    float4 _1774;
    float4 _1775;
    float4 _1776;
    _1776 = float4(0.0);
    _1775 = float4(0.0);
    _1774 = float4(0.0);
    for (int _1773 = 0; _1773 < 4; )
    {
        int _1326 = int(in.m_53[_1773]) * 3;
        _1776 = spvFAdd(_1776, _72._m4[_1326 + 2] * in.m_77[_1773]);
        _1775 = spvFAdd(_1775, _72._m4[_1326 + 1] * in.m_77[_1773]);
        _1774 = spvFAdd(_1774, _72._m4[_1326] * in.m_77[_1773]);
        _1773++;
        continue;
    }
    float4x4 _776 = spvFMulMatrixMatrix(float4x4(in.m_745, in.m_747, in.m_749, in.m_751), transpose(float4x4(_1774, _1775, _1776, float4(0.0, 0.0, 0.0, 1.0))));
    float3 _1781;
    do
    {
        float3 _1423 = (_776 * _987).xyz;
        float4 _1425 = _776[0];
        float3 _1426 = _1425.xyz;
        float4 _1428 = _776[1];
        float3 _1429 = _1428.xyz;
        float4 _1431 = _776[2];
        float3 _1432 = _1431.xyz;
        float3 _1441 = cross(_1426, _1429);
        float3 _1467 = fast::normalize(spvFMulMatrixVector(float3x3(cross(_1429, _1432), cross(_1432, _1426), _1441), _1029) * ((dot(_1441, _1432) < 0.0) ? (-1.0) : 1.0));
        float4 _1474 = _776[3];
        float2 _1656 = _1474.xz;
        float _1664 = spvFAdd(spvFMul(dot(_1656, _1220), 0.3499999940395355224609375), spvFMul(dot(_1656, float2(0.829999983310699462890625, -0.569999992847442626953125)), 1.7000000476837158203125));
        float _1688 = spvFMul(dot(_1474.xyz, float3(3.099999904632568359375, 2.2999999523162841796875, 2.7000000476837158203125)), 3.0);
        float3 _1778;
        _1778 = float3(0.0);
        for (int _1777 = 0; _1777 < 4; )
        {
            _1778 += (_72._m2[int(in.m_53[_1777])].xyz * in.m_77[_1777]);
            _1777++;
            continue;
        }
        float3 _1486 = spvFAdd(_1273 * spvFMul(spvFMul(spvFMul(_1275, spvFAdd(1.0, spvFMul(_1246, spvFSub(spvFMul(spvFAdd(0.5, spvFMul(spvFMul(0.5, sin(spvFAdd(spvFMul(_72._m1[6].y, 0.61000001430511474609375), _1664))), sin(spvFAdd(spvFMul(_72._m1[6].y, 0.23000000417232513427734375), spvFMul(_1664, 0.699999988079071044921875))))), 1.60000002384185791015625), 0.60000002384185791015625)))), spvFAdd(0.699999988079071044921875, spvFMul(spvFMul(0.300000011920928955078125, sin(spvFAdd(spvFMul(_72._m1[6].y, 4.69999980926513671875), _1688))), sin(spvFAdd(spvFMul(_72._m1[6].y, 2.900000095367431640625), spvFMul(_1688, 0.37000000476837158203125)))))), 0.3499999940395355224609375), _1778 / _1048) * _1035;
        if (_1038)
        {
            _1781 = spvFAdd(_1423, _1486 * spvFMul(spvFMul(_1046, in.m_438.y), in.m_438.y));
            break;
        }
        bool _1530 = in.m_482.y > 1.5;
        float _1779;
        if (_1530)
        {
            _1779 = in.m_438.y;
        }
        else
        {
            _1779 = in.m_482.y;
        }
        float _1546 = spvFMul(_1046, fast::max(spvFSub(in.m_457.w, 1.0), 0.0));
        if ((_1779 <= 0.0) && (!_1530))
        {
            _1781 = spvFAdd(_1423, _1467 * spvFAdd(spvFMul(_1546, 0.039999999105930328369140625), 0.00039999998989515006542205810546875));
            break;
        }
        float3 _1581 = spvFMulMatrixVector(float3x3(float3(_1425.xyz), float3(_1428.xyz), float3(_1431.xyz)), in.m_457.xyz);
        float _1616 = spvFMul(_1546, _1779);
        float3 _1617 = fast::normalize(spvFAdd(spvFAdd(_1467 * spvFSub(1.0, fast::min(length(_1581), 1.0)), _1581), spvFAdd(float3(0.0, -_72._m1[1].w, 0.0), _1486) * spvFMul(0.5, _1779))) * _1616;
        float _1620 = dot(_1617, _1467);
        float _1624 = spvFMul(_1616, 0.119999997317790985107421875);
        float3 _1780;
        if (_1620 < _1624)
        {
            _1780 = spvFAdd(_1617, _1467 * spvFSub(_1624, _1620));
        }
        else
        {
            _1780 = _1617;
        }
        _1781 = spvFAdd(_1423, _1780);
        break;
    } while(false);
    out.m_830 = _1767;
    out.m_832 = (_1020 * _1029) * ((dot(_1007, _998) < 0.0) ? (-1.0) : 1.0);
    out.m_838 = in.m_839;
    out.m_841 = float4(in.m_482.x, 0.0, 0.0, 0.0);
    out.m_863 = spvFMulMatrixVector(_661._m2, _669);
    out.m_865 = spvFMulMatrixVector(_661._m3, float4(_1781, 1.0));
    out.m_867 = _1768;
    out.gl_Position.y = -(out.gl_Position.y);    // Invert Y-axis for Metal
    return out;
}

