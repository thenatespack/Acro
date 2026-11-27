// Generated from mesh_fur_depth.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: b41c07030a2b9499
// glsl-fnv1a64: c394983351f825f5

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
};

struct vertex_main_out
{
    float2 m_556 [[user(locn2)]];
    float3 m_559 [[user(locn4)]];
    float4 m_515 [[user(locn8)]];
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
    float4 m_230 [[attribute(11)]];
    float4 m_28 [[attribute(12)]];
    float4 m_280 [[attribute(13)]];
};

vertex vertex_main_out vertex_main(vertex_main_in in [[stage_in]], constant _47& _49 [[buffer(2)]], constant _478& _480 [[buffer(15)]])
{
    vertex_main_out out = {};
    float3 _607;
    float3 _653;
    bool _662;
    float3 _928;
    do
    {
        _607 = in.m_154;
        float3 _613 = (float4x4(in.m_437, in.m_439, in.m_441, in.m_443) * float4(_607, 1.0)).xyz;
        float3 _631 = cross(in.m_437.xyz, in.m_439.xyz);
        _653 = in.m_214;
        float3 _657 = fast::normalize(spvFMulMatrixVector(float3x3(cross(in.m_439.xyz, in.m_441.xyz), cross(in.m_441.xyz, in.m_437.xyz), _631), _653) * ((dot(_631, in.m_441.xyz) < 0.0) ? (-1.0) : 1.0));
        _662 = _49._m1[3].w > 0.5;
        float _860 = spvFAdd(spvFMul(dot(in.m_443.xz, _49._m1[5].xy), 0.3499999940395355224609375), spvFMul(dot(in.m_443.xz, float2(0.829999983310699462890625, -0.569999992847442626953125)), 1.7000000476837158203125));
        float _884 = spvFMul(dot(in.m_443.xyz, float3(3.099999904632568359375, 2.2999999523162841796875, 2.7000000476837158203125)), 3.0);
        float3 _682 = spvFAdd(float3(_49._m1[5].x, 0.0, _49._m1[5].y) * spvFMul(spvFMul(spvFMul(_49._m1[5].z, spvFAdd(1.0, spvFMul(_49._m1[5].w, spvFSub(spvFMul(spvFAdd(0.5, spvFMul(spvFMul(0.5, sin(spvFAdd(spvFMul(_49._m1[6].x, 0.61000001430511474609375), _860))), sin(spvFAdd(spvFMul(_49._m1[6].x, 0.23000000417232513427734375), spvFMul(_860, 0.699999988079071044921875))))), 1.60000002384185791015625), 0.60000002384185791015625)))), spvFAdd(0.699999988079071044921875, spvFMul(spvFMul(0.300000011920928955078125, sin(spvFAdd(spvFMul(_49._m1[6].x, 4.69999980926513671875), _884))), sin(spvFAdd(spvFMul(_49._m1[6].x, 2.900000095367431640625), spvFMul(_884, 0.37000000476837158203125)))))), 0.3499999940395355224609375), float3(in.m_28.z, 0.0, in.m_28.w) / float3(fast::max(_49._m1[0].x, 0.001000000047497451305389404296875))) * spvFMul(_49._m1[2].x, (in.m_230.w < (-0.5)) ? 0.0 : 1.0);
        if (_662)
        {
            _928 = spvFAdd(_613, _682 * spvFMul(spvFMul(_49._m1[0].x, in.m_261.y), in.m_261.y));
            break;
        }
        bool _726 = in.m_28.y > 1.5;
        float _926;
        if (_726)
        {
            _926 = in.m_261.y;
        }
        else
        {
            _926 = in.m_28.y;
        }
        float _742 = spvFMul(_49._m1[0].x, fast::max(spvFSub(in.m_280.w, 1.0), 0.0));
        if ((_926 <= 0.0) && (!_726))
        {
            _928 = spvFAdd(_613, _657 * spvFAdd(spvFMul(_742, 0.039999999105930328369140625), 0.00039999998989515006542205810546875));
            break;
        }
        float3 _777 = spvFMulMatrixVector(float3x3(float3(in.m_437.xyz), float3(in.m_439.xyz), float3(in.m_441.xyz)), in.m_280.xyz);
        float _812 = spvFMul(_742, _926);
        float3 _813 = fast::normalize(spvFAdd(spvFAdd(_657 * spvFSub(1.0, fast::min(length(_777), 1.0)), _777), spvFAdd(float3(0.0, -_49._m1[1].w, 0.0), _682) * spvFMul(0.5, _926))) * _812;
        float _816 = dot(_813, _657);
        float _820 = spvFMul(_812, 0.119999997317790985107421875);
        float3 _927;
        if (_816 < _820)
        {
            _927 = spvFAdd(_813, _657 * spvFSub(_820, _816));
        }
        else
        {
            _927 = _813;
        }
        _928 = spvFAdd(_613, _927);
        break;
    } while(false);
    out.gl_Position = spvFMulMatrixVector(_480._m0, float4(_928, 1.0));
    out.gl_Position.y = -out.gl_Position.y;
    bool _508 = !_662;
    bool _514;
    if (_508)
    {
        _514 = in.m_28.y > 1.5;
    }
    else
    {
        _514 = _508;
    }
    float _929;
    if (_662 || _514)
    {
        _929 = in.m_261.y;
    }
    else
    {
        _929 = in.m_28.y;
    }
    float _930;
    if (_662)
    {
        _930 = fract(in.m_280.w);
    }
    else
    {
        _930 = 0.0;
    }
    float _931;
    if (_662)
    {
        _931 = 1.0;
    }
    else
    {
        _931 = _514 ? 2.0 : 0.0;
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
    out.m_515 = float4(_929, _930, _931, float(_552));
    out.m_556 = in.m_261;
    out.m_559 = _607;
    out.m_561 = _653;
    out.gl_Position.y = -(out.gl_Position.y);    // Invert Y-axis for Metal
    return out;
}

