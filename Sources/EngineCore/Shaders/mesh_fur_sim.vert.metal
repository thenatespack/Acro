// Generated from mesh_fur_sim.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 59c341b95e6b5bcd
// glsl-fnv1a64: d6a224587197e062

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
    float3 m_640 [[user(locn0)]];
    float3 m_642 [[user(locn1)]];
    float2 m_556 [[user(locn2)]];
    float4 m_648 [[user(locn3)]];
    float3 m_559 [[user(locn4)]];
    float4 m_650 [[user(locn5)]];
    float4 m_672 [[user(locn6)]];
    float4 m_674 [[user(locn7)]];
    float4 m_515 [[user(locn8)]];
    float3 m_676 [[user(locn9)]];
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
    float4 m_594 [[attribute(14)]];
};

vertex vertex_main_out vertex_main(vertex_main_in in [[stage_in]], constant _47& _49 [[buffer(2)]], constant _478& _480 [[buffer(15)]])
{
    vertex_main_out out = {};
    float3 _718;
    float3 _733;
    float3 _742;
    float3x3 _755;
    float3 _764;
    bool _773;
    float3 _1042;
    float3 _1043;
    do
    {
        _718 = in.m_154;
        float3 _724 = (float4x4(in.m_437, in.m_439, in.m_441, in.m_443) * float4(_718, 1.0)).xyz;
        _733 = in.m_441.xyz;
        _742 = cross(in.m_437.xyz, in.m_439.xyz);
        _755 = float3x3(cross(in.m_439.xyz, _733), cross(_733, in.m_437.xyz), _742);
        _764 = in.m_214;
        float3 _768 = fast::normalize(spvFMulMatrixVector(_755, _764) * ((dot(_742, _733) < 0.0) ? (-1.0) : 1.0));
        _773 = _49._m1[3].w > 0.5;
        float _971 = spvFAdd(spvFMul(dot(in.m_443.xz, _49._m1[5].xy), 0.3499999940395355224609375), spvFMul(dot(in.m_443.xz, float2(0.829999983310699462890625, -0.569999992847442626953125)), 1.7000000476837158203125));
        float _995 = spvFMul(dot(in.m_443.xyz, float3(3.099999904632568359375, 2.2999999523162841796875, 2.7000000476837158203125)), 3.0);
        float3 _793 = spvFAdd(float3(_49._m1[5].x, 0.0, _49._m1[5].y) * spvFMul(spvFMul(spvFMul(_49._m1[5].z, spvFAdd(1.0, spvFMul(_49._m1[5].w, spvFSub(spvFMul(spvFAdd(0.5, spvFMul(spvFMul(0.5, sin(spvFAdd(spvFMul(_49._m1[6].x, 0.61000001430511474609375), _971))), sin(spvFAdd(spvFMul(_49._m1[6].x, 0.23000000417232513427734375), spvFMul(_971, 0.699999988079071044921875))))), 1.60000002384185791015625), 0.60000002384185791015625)))), spvFAdd(0.699999988079071044921875, spvFMul(spvFMul(0.300000011920928955078125, sin(spvFAdd(spvFMul(_49._m1[6].x, 4.69999980926513671875), _995))), sin(spvFAdd(spvFMul(_49._m1[6].x, 2.900000095367431640625), spvFMul(_995, 0.37000000476837158203125)))))), 0.3499999940395355224609375), float3(in.m_28.z, 0.0, in.m_28.w) / float3(fast::max(_49._m1[0].x, 0.001000000047497451305389404296875))) * spvFMul(_49._m1[2].x, (in.m_230.w < (-0.5)) ? 0.0 : 1.0);
        if (_773)
        {
            _1043 = fast::normalize((float3x3(float3(in.m_437.xyz), float3(in.m_439.xyz), float3(in.m_441.xyz)) * in.m_280.xyz) + (_793 * (2.0 * in.m_261.y)));
            _1042 = spvFAdd(_724, _793 * spvFMul(spvFMul(_49._m1[0].x, in.m_261.y), in.m_261.y));
            break;
        }
        bool _837 = in.m_28.y > 1.5;
        float _1040;
        if (_837)
        {
            _1040 = in.m_261.y;
        }
        else
        {
            _1040 = in.m_28.y;
        }
        float _853 = spvFMul(_49._m1[0].x, fast::max(spvFSub(in.m_280.w, 1.0), 0.0));
        if ((_1040 <= 0.0) && (!_837))
        {
            _1043 = _768;
            _1042 = spvFAdd(_724, _768 * spvFAdd(spvFMul(_853, 0.039999999105930328369140625), 0.00039999998989515006542205810546875));
            break;
        }
        float3 _888 = spvFMulMatrixVector(float3x3(float3(in.m_437.xyz), float3(in.m_439.xyz), float3(in.m_441.xyz)), in.m_280.xyz);
        float _891 = fast::min(length(_888), 1.0);
        float3 _897 = spvFAdd(float3(0.0, -_49._m1[1].w, 0.0), _793);
        float _923 = spvFMul(_853, _1040);
        float3 _924 = fast::normalize(spvFAdd(spvFAdd(_768 * spvFSub(1.0, _891), _888), _897 * spvFMul(0.5, _1040))) * _923;
        float _927 = dot(_924, _768);
        float _931 = spvFMul(_923, 0.119999997317790985107421875);
        float3 _1041;
        if (_927 < _931)
        {
            _1041 = spvFAdd(_924, _768 * spvFSub(_931, _927));
        }
        else
        {
            _1041 = _924;
        }
        _1043 = fast::normalize(((_768 * (1.0 - _891)) + _888) + (_897 * _1040));
        _1042 = spvFAdd(_724, _1041);
        break;
    } while(false);
    float4 _488 = float4(_1042, 1.0);
    out.gl_Position = spvFMulMatrixVector(_480._m0, _488);
    out.gl_Position.y = -out.gl_Position.y;
    bool _508 = !_773;
    bool _514;
    if (_508)
    {
        _514 = in.m_28.y > 1.5;
    }
    else
    {
        _514 = _508;
    }
    float _1045;
    if (_773 || _514)
    {
        _1045 = in.m_261.y;
    }
    else
    {
        _1045 = in.m_28.y;
    }
    float _1046;
    if (_773)
    {
        _1046 = fract(in.m_280.w);
    }
    else
    {
        _1046 = 0.0;
    }
    float _1047;
    if (_773)
    {
        _1047 = 1.0;
    }
    else
    {
        _1047 = _514 ? 2.0 : 0.0;
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
    out.m_515 = float4(_1045, _1046, _1047, float(_552));
    out.m_556 = in.m_261;
    out.m_559 = _718;
    out.m_561 = _764;
    out.m_640 = _1042;
    out.m_642 = (_755 * _764) * ((dot(_742, _733) < 0.0) ? (-1.0) : 1.0);
    out.m_648 = in.m_230;
    out.m_650 = float4(in.m_28.x, 0.0, 0.0, 0.0);
    out.m_672 = spvFMulMatrixVector(_480._m2, _488);
    out.m_674 = spvFMulMatrixVector(_480._m3, float4(in.m_594.xyz, 1.0));
    out.m_676 = _1043;
    out.gl_Position.y = -(out.gl_Position.y);    // Invert Y-axis for Metal
    return out;
}

