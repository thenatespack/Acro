// Generated from mesh_fur.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: f59096b5c8e27aa5
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

struct _453
{
    float4x4 _m0;
    float4x4 _m1;
    float4x4 _m2;
    float4x4 _m3;
};

struct vertex_main_out
{
    float3 m_604 [[user(locn0)]];
    float3 m_606 [[user(locn1)]];
    float2 m_514 [[user(locn2)]];
    float4 m_612 [[user(locn3)]];
    float3 m_517 [[user(locn4)]];
    float4 m_615 [[user(locn5)]];
    float4 m_637 [[user(locn6)]];
    float4 m_639 [[user(locn7)]];
    float4 m_481 [[user(locn8)]];
    float3 m_641 [[user(locn9)]];
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
    float4 m_522 [[attribute(7)]];
    float4 m_524 [[attribute(8)]];
    float4 m_526 [[attribute(9)]];
    float4 m_528 [[attribute(10)]];
    float4 m_613 [[attribute(11)]];
    float4 m_28 [[attribute(12)]];
    float4 m_271 [[attribute(13)]];
};

vertex vertex_main_out vertex_main(vertex_main_in in [[stage_in]], constant _47& _49 [[buffer(2)]], constant _453& _455 [[buffer(15)]])
{
    vertex_main_out out = {};
    float3 _680;
    float4 _684;
    float3 _695;
    float3 _704;
    float3x3 _717;
    float3 _726;
    float _732;
    bool _735;
    float _743;
    float3 _746;
    float2 _904;
    float _930;
    float3 _957;
    float _959;
    float3 _1314;
    float3 _1315;
    do
    {
        _680 = in.m_154;
        _684 = float4(_680, 1.0);
        float3 _686 = (float4x4(in.m_412, in.m_414, in.m_416, in.m_418) * _684).xyz;
        _695 = in.m_416.xyz;
        _704 = cross(in.m_412.xyz, in.m_414.xyz);
        _717 = float3x3(cross(in.m_414.xyz, _695), cross(_695, in.m_412.xyz), _704);
        _726 = in.m_214;
        float3 _730 = fast::normalize(spvFMulMatrixVector(_717, _726) * ((dot(_704, _695) < 0.0) ? (-1.0) : 1.0));
        _732 = _49._m1[2].x;
        _735 = _49._m1[3].w > 0.5;
        _904 = _49._m1[5].xy;
        float _914 = spvFAdd(spvFMul(dot(in.m_418.xz, _904), 0.3499999940395355224609375), spvFMul(dot(in.m_418.xz, float2(0.829999983310699462890625, -0.569999992847442626953125)), 1.7000000476837158203125));
        _930 = _49._m1[5].w;
        float _938 = spvFMul(dot(in.m_418.xyz, float3(3.099999904632568359375, 2.2999999523162841796875, 2.7000000476837158203125)), 3.0);
        _957 = float3(_49._m1[5].x, 0.0, _49._m1[5].y);
        _959 = _49._m1[5].z;
        _743 = _49._m1[0].x;
        _746 = float3(in.m_28.z, 0.0, in.m_28.w) / float3(fast::max(_743, 0.001000000047497451305389404296875));
        float3 _749 = spvFAdd(_957 * spvFMul(spvFMul(spvFMul(_959, spvFAdd(1.0, spvFMul(_930, spvFSub(spvFMul(spvFAdd(0.5, spvFMul(spvFMul(0.5, sin(spvFAdd(spvFMul(_49._m1[6].x, 0.61000001430511474609375), _914))), sin(spvFAdd(spvFMul(_49._m1[6].x, 0.23000000417232513427734375), spvFMul(_914, 0.699999988079071044921875))))), 1.60000002384185791015625), 0.60000002384185791015625)))), spvFAdd(0.699999988079071044921875, spvFMul(spvFMul(0.300000011920928955078125, sin(spvFAdd(spvFMul(_49._m1[6].x, 4.69999980926513671875), _938))), sin(spvFAdd(spvFMul(_49._m1[6].x, 2.900000095367431640625), spvFMul(_938, 0.37000000476837158203125)))))), 0.3499999940395355224609375), _746) * _732;
        if (_735)
        {
            _1315 = fast::normalize((float3x3(float3(in.m_412.xyz), float3(in.m_414.xyz), float3(in.m_416.xyz)) * in.m_271.xyz) + (_749 * (2.0 * in.m_252.y)));
            _1314 = spvFAdd(_686, _749 * spvFMul(spvFMul(_743, in.m_252.y), in.m_252.y));
            break;
        }
        float _799 = spvFMul(_743, fast::max(spvFSub(in.m_271.w, 1.0), 0.0));
        if (in.m_28.y <= 0.0)
        {
            _1315 = _730;
            _1314 = spvFAdd(_686, _730 * spvFAdd(spvFMul(_799, 0.039999999105930328369140625), 0.00039999998989515006542205810546875));
            break;
        }
        float3 _831 = spvFMulMatrixVector(float3x3(float3(in.m_412.xyz), float3(in.m_414.xyz), float3(in.m_416.xyz)), in.m_271.xyz);
        float _834 = fast::min(length(_831), 1.0);
        float3 _840 = spvFAdd(float3(0.0, -_49._m1[1].w, 0.0), _749);
        float _866 = spvFMul(_799, in.m_28.y);
        float3 _867 = fast::normalize(spvFAdd(spvFAdd(_730 * spvFSub(1.0, _834), _831), _840 * spvFMul(0.5, in.m_28.y))) * _866;
        float _870 = dot(_867, _730);
        float _874 = spvFMul(_866, 0.119999997317790985107421875);
        float3 _1313;
        if (_870 < _874)
        {
            _1313 = spvFAdd(_867, _730 * spvFSub(_874, _870));
        }
        else
        {
            _1313 = _867;
        }
        _1315 = fast::normalize(((_730 * (1.0 - _834)) + _831) + (_840 * in.m_28.y));
        _1314 = spvFAdd(_686, _1313);
        break;
    } while(false);
    float4 _463 = float4(_1314, 1.0);
    out.gl_Position = spvFMulMatrixVector(_455._m0, _463);
    out.gl_Position.y = -out.gl_Position.y;
    float _1317;
    if (_735)
    {
        _1317 = in.m_252.y;
    }
    else
    {
        _1317 = in.m_28.y;
    }
    float _1318;
    if (_735)
    {
        _1318 = fract(in.m_271.w);
    }
    else
    {
        _1318 = 0.0;
    }
    bool _504 = !_735;
    bool _510;
    if (_504)
    {
        _510 = in.m_28.y <= 0.0;
    }
    else
    {
        _510 = _504;
    }
    out.m_481 = float4(_1317, _1318, float(_735), float(_510));
    out.m_514 = in.m_252;
    out.m_517 = _680;
    out.m_519 = _726;
    float3 _1320;
    do
    {
        float3 _1010 = (float4x4(in.m_522, in.m_524, in.m_526, in.m_528) * _684).xyz;
        float3 _1028 = cross(in.m_522.xyz, in.m_524.xyz);
        float3 _1054 = fast::normalize(spvFMulMatrixVector(float3x3(cross(in.m_524.xyz, in.m_526.xyz), cross(in.m_526.xyz, in.m_522.xyz), _1028), _726) * ((dot(_1028, in.m_526.xyz) < 0.0) ? (-1.0) : 1.0));
        float _1238 = spvFAdd(spvFMul(dot(in.m_528.xz, _904), 0.3499999940395355224609375), spvFMul(dot(in.m_528.xz, float2(0.829999983310699462890625, -0.569999992847442626953125)), 1.7000000476837158203125));
        float _1262 = spvFMul(dot(in.m_528.xyz, float3(3.099999904632568359375, 2.2999999523162841796875, 2.7000000476837158203125)), 3.0);
        float3 _1073 = spvFAdd(_957 * spvFMul(spvFMul(spvFMul(_959, spvFAdd(1.0, spvFMul(_930, spvFSub(spvFMul(spvFAdd(0.5, spvFMul(spvFMul(0.5, sin(spvFAdd(spvFMul(_49._m1[6].y, 0.61000001430511474609375), _1238))), sin(spvFAdd(spvFMul(_49._m1[6].y, 0.23000000417232513427734375), spvFMul(_1238, 0.699999988079071044921875))))), 1.60000002384185791015625), 0.60000002384185791015625)))), spvFAdd(0.699999988079071044921875, spvFMul(spvFMul(0.300000011920928955078125, sin(spvFAdd(spvFMul(_49._m1[6].y, 4.69999980926513671875), _1262))), sin(spvFAdd(spvFMul(_49._m1[6].y, 2.900000095367431640625), spvFMul(_1262, 0.37000000476837158203125)))))), 0.3499999940395355224609375), _746) * _732;
        if (_735)
        {
            _1320 = spvFAdd(_1010, _1073 * spvFMul(spvFMul(_743, in.m_252.y), in.m_252.y));
            break;
        }
        float _1123 = spvFMul(_743, fast::max(spvFSub(in.m_271.w, 1.0), 0.0));
        if (in.m_28.y <= 0.0)
        {
            _1320 = spvFAdd(_1010, _1054 * spvFAdd(spvFMul(_1123, 0.039999999105930328369140625), 0.00039999998989515006542205810546875));
            break;
        }
        float3 _1155 = spvFMulMatrixVector(float3x3(float3(in.m_522.xyz), float3(in.m_524.xyz), float3(in.m_526.xyz)), in.m_271.xyz);
        float _1190 = spvFMul(_1123, in.m_28.y);
        float3 _1191 = fast::normalize(spvFAdd(spvFAdd(_1054 * spvFSub(1.0, fast::min(length(_1155), 1.0)), _1155), spvFAdd(float3(0.0, -_49._m1[1].w, 0.0), _1073) * spvFMul(0.5, in.m_28.y))) * _1190;
        float _1194 = dot(_1191, _1054);
        float _1198 = spvFMul(_1190, 0.119999997317790985107421875);
        float3 _1319;
        if (_1194 < _1198)
        {
            _1319 = spvFAdd(_1191, _1054 * spvFSub(_1198, _1194));
        }
        else
        {
            _1319 = _1191;
        }
        _1320 = spvFAdd(_1010, _1319);
        break;
    } while(false);
    out.m_604 = _1314;
    out.m_606 = (_717 * _726) * ((dot(_704, _695) < 0.0) ? (-1.0) : 1.0);
    out.m_612 = in.m_613;
    out.m_615 = float4(in.m_28.x, 0.0, 0.0, 0.0);
    out.m_637 = spvFMulMatrixVector(_455._m2, _463);
    out.m_639 = spvFMulMatrixVector(_455._m3, float4(_1320, 1.0));
    out.m_641 = _1315;
    out.gl_Position.y = -(out.gl_Position.y);    // Invert Y-axis for Metal
    return out;
}

