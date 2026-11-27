// Generated from mesh_fur_depth_skinned.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 4d5220664c4791d5
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

struct _566
{
    float4x4 _m0;
    float4x4 _m1;
};

struct vertex_main_out
{
    float2 m_627 [[user(locn2)]];
    float3 m_630 [[user(locn4)]];
    float4 m_594 [[user(locn8)]];
    float3 m_632 [[user(locn10)]];
    float4 gl_Position [[position]];
};

struct vertex_main_in
{
    float3 m_268 [[attribute(0)]];
    float3 m_324 [[attribute(1)]];
    float2 m_361 [[attribute(2)]];
    float4 m_522 [[attribute(3)]];
    float4 m_524 [[attribute(4)]];
    float4 m_526 [[attribute(5)]];
    float4 m_528 [[attribute(6)]];
    float4 m_405 [[attribute(12)]];
    float4 m_380 [[attribute(13)]];
    float4 m_51 [[attribute(14)]];
    float4 m_75 [[attribute(15)]];
};

vertex vertex_main_out vertex_main(vertex_main_in in [[stage_in]], constant _68& _70 [[buffer(2)]], constant _566& _568 [[buffer(15)]])
{
    vertex_main_out out = {};
    float4 _1072;
    float4 _1073;
    float4 _1074;
    _1074 = float4(0.0);
    _1073 = float4(0.0);
    _1072 = float4(0.0);
    for (int _1071 = 0; _1071 < 4; )
    {
        int _662 = int(in.m_51[_1071]) * 3;
        _1074 = spvFAdd(_1074, _70._m3[_662 + 2] * in.m_75[_1071]);
        _1073 = spvFAdd(_1073, _70._m3[_662 + 1] * in.m_75[_1071]);
        _1072 = spvFAdd(_1072, _70._m3[_662] * in.m_75[_1071]);
        _1071++;
        continue;
    }
    float3 _751;
    float3 _797;
    bool _806;
    float4x4 _553 = spvFMulMatrixMatrix(float4x4(in.m_522, in.m_524, in.m_526, in.m_528), transpose(float4x4(_1072, _1073, _1074, float4(0.0, 0.0, 0.0, 1.0))));
    float3 _1078;
    do
    {
        _751 = in.m_268;
        float3 _757 = (_553 * float4(_751, 1.0)).xyz;
        float4 _759 = _553[0];
        float3 _760 = _759.xyz;
        float4 _762 = _553[1];
        float3 _763 = _762.xyz;
        float4 _765 = _553[2];
        float3 _766 = _765.xyz;
        float3 _775 = cross(_760, _763);
        _797 = in.m_324;
        float3 _801 = fast::normalize(spvFMulMatrixVector(float3x3(cross(_763, _766), cross(_766, _760), _775), _797) * ((dot(_775, _766) < 0.0) ? (-1.0) : 1.0));
        _806 = _70._m1[3].w > 0.5;
        float4 _808 = _553[3];
        float2 _977 = _808.xz;
        float _985 = spvFAdd(spvFMul(dot(_977, _70._m1[5].xy), 0.3499999940395355224609375), spvFMul(dot(_977, float2(0.829999983310699462890625, -0.569999992847442626953125)), 1.7000000476837158203125));
        float _1009 = spvFMul(dot(_808.xyz, float3(3.099999904632568359375, 2.2999999523162841796875, 2.7000000476837158203125)), 3.0);
        float3 _1076;
        _1076 = float3(0.0);
        for (int _1075 = 0; _1075 < 4; )
        {
            _1076 += (_70._m2[int(in.m_51[_1075])].xyz * in.m_75[_1075]);
            _1075++;
            continue;
        }
        float3 _820 = spvFAdd(float3(_70._m1[5].x, 0.0, _70._m1[5].y) * spvFMul(spvFMul(spvFMul(_70._m1[5].z, spvFAdd(1.0, spvFMul(_70._m1[5].w, spvFSub(spvFMul(spvFAdd(0.5, spvFMul(spvFMul(0.5, sin(spvFAdd(spvFMul(_70._m1[6].x, 0.61000001430511474609375), _985))), sin(spvFAdd(spvFMul(_70._m1[6].x, 0.23000000417232513427734375), spvFMul(_985, 0.699999988079071044921875))))), 1.60000002384185791015625), 0.60000002384185791015625)))), spvFAdd(0.699999988079071044921875, spvFMul(spvFMul(0.300000011920928955078125, sin(spvFAdd(spvFMul(_70._m1[6].x, 4.69999980926513671875), _1009))), sin(spvFAdd(spvFMul(_70._m1[6].x, 2.900000095367431640625), spvFMul(_1009, 0.37000000476837158203125)))))), 0.3499999940395355224609375), _1076 / float3(fast::max(_70._m1[0].x, 0.001000000047497451305389404296875))) * _70._m1[2].x;
        if (_806)
        {
            _1078 = spvFAdd(_757, _820 * spvFMul(spvFMul(_70._m1[0].x, in.m_361.y), in.m_361.y));
            break;
        }
        float _870 = spvFMul(_70._m1[0].x, fast::max(spvFSub(in.m_380.w, 1.0), 0.0));
        if (in.m_405.y <= 0.0)
        {
            _1078 = spvFAdd(_757, _801 * spvFAdd(spvFMul(_870, 0.039999999105930328369140625), 0.00039999998989515006542205810546875));
            break;
        }
        float3 _902 = spvFMulMatrixVector(float3x3(float3(_759.xyz), float3(_762.xyz), float3(_765.xyz)), in.m_380.xyz);
        float _937 = spvFMul(_870, in.m_405.y);
        float3 _938 = fast::normalize(spvFAdd(spvFAdd(_801 * spvFSub(1.0, fast::min(length(_902), 1.0)), _902), spvFAdd(float3(0.0, -_70._m1[1].w, 0.0), _820) * spvFMul(0.5, in.m_405.y))) * _937;
        float _941 = dot(_938, _801);
        float _945 = spvFMul(_937, 0.119999997317790985107421875);
        float3 _1077;
        if (_941 < _945)
        {
            _1077 = spvFAdd(_938, _801 * spvFSub(_945, _941));
        }
        else
        {
            _1077 = _938;
        }
        _1078 = spvFAdd(_757, _1077);
        break;
    } while(false);
    out.gl_Position = spvFMulMatrixVector(_568._m0, float4(_1078, 1.0));
    out.gl_Position.y = -out.gl_Position.y;
    float _1079;
    if (_806)
    {
        _1079 = in.m_361.y;
    }
    else
    {
        _1079 = in.m_405.y;
    }
    float _1080;
    if (_806)
    {
        _1080 = fract(in.m_380.w);
    }
    else
    {
        _1080 = 0.0;
    }
    bool _617 = !_806;
    bool _623;
    if (_617)
    {
        _623 = in.m_405.y <= 0.0;
    }
    else
    {
        _623 = _617;
    }
    out.m_594 = float4(_1079, _1080, float(_806), float(_623));
    out.m_627 = in.m_361;
    out.m_630 = _751;
    out.m_632 = _797;
    out.gl_Position.y = -(out.gl_Position.y);    // Invert Y-axis for Metal
    return out;
}

