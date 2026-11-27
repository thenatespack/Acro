// Generated from mesh_fur.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: c899b7728ebfdc0d
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

struct _478
{
    float4x4 _m0;
    float4x4 _m1;
    float4x4 _m2;
    float4x4 _m3;
};

struct vertex_main_out
{
    float3 m_646 [[user(locn0)]];
    float3 m_648 [[user(locn1)]];
    float2 m_556 [[user(locn2)]];
    float4 m_654 [[user(locn3)]];
    float3 m_559 [[user(locn4)]];
    float4 m_656 [[user(locn5)]];
    float4 m_678 [[user(locn6)]];
    float4 m_680 [[user(locn7)]];
    float4 m_515 [[user(locn8)]];
    float3 m_682 [[user(locn9)]];
    float3 m_561 [[user(locn10)]];
    float4 gl_Position [[position]];
};

struct vertex_main_in
{
    float3 m_154 [[attribute(0)]];
    float3 m_214 [[attribute(1)]];
    float2 m_261 [[attribute(2)]];
    float4 m_437 [[attribute(3)]];
    float4 m_439 [[attribute(4)]];
    float4 m_441 [[attribute(5)]];
    float4 m_443 [[attribute(6)]];
    float4 m_564 [[attribute(7)]];
    float4 m_566 [[attribute(8)]];
    float4 m_568 [[attribute(9)]];
    float4 m_570 [[attribute(10)]];
    float4 m_230 [[attribute(11)]];
    float4 m_28 [[attribute(12)]];
    float4 m_280 [[attribute(13)]];
};

vertex vertex_main_out vertex_main(vertex_main_in in [[stage_in]], constant _47& _49 [[buffer(2)]], constant _478& _480 [[buffer(15)]])
{
    vertex_main_out out = {};
    float3 _724;
    float4 _728;
    float3 _739;
    float3 _748;
    float3x3 _761;
    float3 _770;
    bool _779;
    float _791;
    float3 _794;
    float _798;
    float2 _967;
    float _993;
    float3 _1020;
    float _1022;
    float3 _1400;
    float3 _1401;
    do
    {
        _724 = in.m_154;
        _728 = float4(_724, 1.0);
        float3 _730 = (float4x4(in.m_437, in.m_439, in.m_441, in.m_443) * _728).xyz;
        _739 = in.m_441.xyz;
        _748 = cross(in.m_437.xyz, in.m_439.xyz);
        _761 = float3x3(cross(in.m_439.xyz, _739), cross(_739, in.m_437.xyz), _748);
        _770 = in.m_214;
        float3 _774 = fast::normalize(spvFMulMatrixVector(_761, _770) * ((dot(_748, _739) < 0.0) ? (-1.0) : 1.0));
        _779 = _49._m1[3].w > 0.5;
        _967 = _49._m1[5].xy;
        float _977 = spvFAdd(spvFMul(dot(in.m_443.xz, _967), 0.3499999940395355224609375), spvFMul(dot(in.m_443.xz, float2(0.829999983310699462890625, -0.569999992847442626953125)), 1.7000000476837158203125));
        _993 = _49._m1[5].w;
        float _1001 = spvFMul(dot(in.m_443.xyz, float3(3.099999904632568359375, 2.2999999523162841796875, 2.7000000476837158203125)), 3.0);
        _1020 = float3(_49._m1[5].x, 0.0, _49._m1[5].y);
        _1022 = _49._m1[5].z;
        _791 = _49._m1[0].x;
        _794 = float3(in.m_28.z, 0.0, in.m_28.w) / float3(fast::max(_791, 0.001000000047497451305389404296875));
        _798 = spvFMul(_49._m1[2].x, (in.m_230.w < (-0.5)) ? 0.0 : 1.0);
        float3 _799 = spvFAdd(_1020 * spvFMul(spvFMul(spvFMul(_1022, spvFAdd(1.0, spvFMul(_993, spvFSub(spvFMul(spvFAdd(0.5, spvFMul(spvFMul(0.5, sin(spvFAdd(spvFMul(_49._m1[6].x, 0.61000001430511474609375), _977))), sin(spvFAdd(spvFMul(_49._m1[6].x, 0.23000000417232513427734375), spvFMul(_977, 0.699999988079071044921875))))), 1.60000002384185791015625), 0.60000002384185791015625)))), spvFAdd(0.699999988079071044921875, spvFMul(spvFMul(0.300000011920928955078125, sin(spvFAdd(spvFMul(_49._m1[6].x, 4.69999980926513671875), _1001))), sin(spvFAdd(spvFMul(_49._m1[6].x, 2.900000095367431640625), spvFMul(_1001, 0.37000000476837158203125)))))), 0.3499999940395355224609375), _794) * _798;
        if (_779)
        {
            _1401 = fast::normalize((float3x3(float3(in.m_437.xyz), float3(in.m_439.xyz), float3(in.m_441.xyz)) * in.m_280.xyz) + (_799 * (2.0 * in.m_261.y)));
            _1400 = spvFAdd(_730, _799 * spvFMul(spvFMul(_791, in.m_261.y), in.m_261.y));
            break;
        }
        bool _843 = in.m_28.y > 1.5;
        float _1398;
        if (_843)
        {
            _1398 = in.m_261.y;
        }
        else
        {
            _1398 = in.m_28.y;
        }
        float _859 = spvFMul(_791, fast::max(spvFSub(in.m_280.w, 1.0), 0.0));
        if ((_1398 <= 0.0) && (!_843))
        {
            _1401 = _774;
            _1400 = spvFAdd(_730, _774 * spvFAdd(spvFMul(_859, 0.039999999105930328369140625), 0.00039999998989515006542205810546875));
            break;
        }
        float3 _894 = spvFMulMatrixVector(float3x3(float3(in.m_437.xyz), float3(in.m_439.xyz), float3(in.m_441.xyz)), in.m_280.xyz);
        float _897 = fast::min(length(_894), 1.0);
        float3 _903 = spvFAdd(float3(0.0, -_49._m1[1].w, 0.0), _799);
        float _929 = spvFMul(_859, _1398);
        float3 _930 = fast::normalize(spvFAdd(spvFAdd(_774 * spvFSub(1.0, _897), _894), _903 * spvFMul(0.5, _1398))) * _929;
        float _933 = dot(_930, _774);
        float _937 = spvFMul(_929, 0.119999997317790985107421875);
        float3 _1399;
        if (_933 < _937)
        {
            _1399 = spvFAdd(_930, _774 * spvFSub(_937, _933));
        }
        else
        {
            _1399 = _930;
        }
        _1401 = fast::normalize(((_774 * (1.0 - _897)) + _894) + (_903 * _1398));
        _1400 = spvFAdd(_730, _1399);
        break;
    } while(false);
    float4 _488 = float4(_1400, 1.0);
    out.gl_Position = spvFMulMatrixVector(_480._m0, _488);
    out.gl_Position.y = -out.gl_Position.y;
    bool _508 = !_779;
    bool _514;
    if (_508)
    {
        _514 = in.m_28.y > 1.5;
    }
    else
    {
        _514 = _508;
    }
    float _1403;
    if (_779 || _514)
    {
        _1403 = in.m_261.y;
    }
    else
    {
        _1403 = in.m_28.y;
    }
    float _1404;
    if (_779)
    {
        _1404 = fract(in.m_280.w);
    }
    else
    {
        _1404 = 0.0;
    }
    float _1405;
    if (_779)
    {
        _1405 = 1.0;
    }
    else
    {
        _1405 = _514 ? 2.0 : 0.0;
    }
    bool _552;
    if (_508)
    {
        _552 = in.m_28.y <= 0.0;
    }
    else
    {
        _552 = _508;
    }
    out.m_515 = float4(_1403, _1404, _1405, float(_552));
    out.m_556 = in.m_261;
    out.m_559 = _724;
    out.m_561 = _770;
    float3 _1408;
    do
    {
        float3 _1076 = (float4x4(in.m_564, in.m_566, in.m_568, in.m_570) * _728).xyz;
        float3 _1094 = cross(in.m_564.xyz, in.m_566.xyz);
        float3 _1120 = fast::normalize(spvFMulMatrixVector(float3x3(cross(in.m_566.xyz, in.m_568.xyz), cross(in.m_568.xyz, in.m_564.xyz), _1094), _770) * ((dot(_1094, in.m_568.xyz) < 0.0) ? (-1.0) : 1.0));
        float _1323 = spvFAdd(spvFMul(dot(in.m_570.xz, _967), 0.3499999940395355224609375), spvFMul(dot(in.m_570.xz, float2(0.829999983310699462890625, -0.569999992847442626953125)), 1.7000000476837158203125));
        float _1347 = spvFMul(dot(in.m_570.xyz, float3(3.099999904632568359375, 2.2999999523162841796875, 2.7000000476837158203125)), 3.0);
        float3 _1145 = spvFAdd(_1020 * spvFMul(spvFMul(spvFMul(_1022, spvFAdd(1.0, spvFMul(_993, spvFSub(spvFMul(spvFAdd(0.5, spvFMul(spvFMul(0.5, sin(spvFAdd(spvFMul(_49._m1[6].y, 0.61000001430511474609375), _1323))), sin(spvFAdd(spvFMul(_49._m1[6].y, 0.23000000417232513427734375), spvFMul(_1323, 0.699999988079071044921875))))), 1.60000002384185791015625), 0.60000002384185791015625)))), spvFAdd(0.699999988079071044921875, spvFMul(spvFMul(0.300000011920928955078125, sin(spvFAdd(spvFMul(_49._m1[6].y, 4.69999980926513671875), _1347))), sin(spvFAdd(spvFMul(_49._m1[6].y, 2.900000095367431640625), spvFMul(_1347, 0.37000000476837158203125)))))), 0.3499999940395355224609375), _794) * _798;
        if (_779)
        {
            _1408 = spvFAdd(_1076, _1145 * spvFMul(spvFMul(_791, in.m_261.y), in.m_261.y));
            break;
        }
        bool _1189 = in.m_28.y > 1.5;
        float _1406;
        if (_1189)
        {
            _1406 = in.m_261.y;
        }
        else
        {
            _1406 = in.m_28.y;
        }
        float _1205 = spvFMul(_791, fast::max(spvFSub(in.m_280.w, 1.0), 0.0));
        if ((_1406 <= 0.0) && (!_1189))
        {
            _1408 = spvFAdd(_1076, _1120 * spvFAdd(spvFMul(_1205, 0.039999999105930328369140625), 0.00039999998989515006542205810546875));
            break;
        }
        float3 _1240 = spvFMulMatrixVector(float3x3(float3(in.m_564.xyz), float3(in.m_566.xyz), float3(in.m_568.xyz)), in.m_280.xyz);
        float _1275 = spvFMul(_1205, _1406);
        float3 _1276 = fast::normalize(spvFAdd(spvFAdd(_1120 * spvFSub(1.0, fast::min(length(_1240), 1.0)), _1240), spvFAdd(float3(0.0, -_49._m1[1].w, 0.0), _1145) * spvFMul(0.5, _1406))) * _1275;
        float _1279 = dot(_1276, _1120);
        float _1283 = spvFMul(_1275, 0.119999997317790985107421875);
        float3 _1407;
        if (_1279 < _1283)
        {
            _1407 = spvFAdd(_1276, _1120 * spvFSub(_1283, _1279));
        }
        else
        {
            _1407 = _1276;
        }
        _1408 = spvFAdd(_1076, _1407);
        break;
    } while(false);
    out.m_646 = _1400;
    out.m_648 = (_761 * _770) * ((dot(_748, _739) < 0.0) ? (-1.0) : 1.0);
    out.m_654 = in.m_230;
    out.m_656 = float4(in.m_28.x, 0.0, 0.0, 0.0);
    out.m_678 = spvFMulMatrixVector(_480._m2, _488);
    out.m_680 = spvFMulMatrixVector(_480._m3, float4(_1408, 1.0));
    out.m_682 = _1401;
    out.gl_Position.y = -(out.gl_Position.y);    // Invert Y-axis for Metal
    return out;
}

