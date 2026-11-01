// Generated from mesh_mask.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: f657bdeca27ca224
// glsl-fnv1a64: 4f56061c7a0a3fa1

#pragma clang diagnostic ignored "-Wmissing-prototypes"
#pragma clang diagnostic ignored "-Wmissing-braces"

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

template<typename T, size_t Num>
struct spvUnsafeArray
{
    T elements[Num ? Num : 1];
    
    thread T& operator [] (size_t pos) thread
    {
        return elements[pos];
    }
    constexpr const thread T& operator [] (size_t pos) const thread
    {
        return elements[pos];
    }
    
    device T& operator [] (size_t pos) device
    {
        return elements[pos];
    }
    constexpr const device T& operator [] (size_t pos) const device
    {
        return elements[pos];
    }
    
    constexpr const constant T& operator [] (size_t pos) const constant
    {
        return elements[pos];
    }
    
    threadgroup T& operator [] (size_t pos) threadgroup
    {
        return elements[pos];
    }
    constexpr const threadgroup T& operator [] (size_t pos) const threadgroup
    {
        return elements[pos];
    }
};

// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()
template<typename Tx, typename Ty>
inline Tx mod(Tx x, Ty y)
{
    return x - y * floor(x / y);
}

// Implementation of signed integer mod accurate to SPIR-V specification
template<typename Tx, typename Ty>
inline Tx spvSMod(Tx x, Ty y)
{
    Tx remainder = x - y * (x / y);
    return select(Tx(remainder + y), remainder, remainder == 0 || (x >= 0) == (y >= 0));
}

template <typename T>
static inline depth2d<T> spvDepthCast(texture2d<T> t)
{
    return reinterpret_cast<thread const depth2d<T> &>(t);
}

template <typename T>
static inline depth2d_array<T> spvDepthCast(texture2d_array<T> t)
{
    return reinterpret_cast<thread const depth2d_array<T> &>(t);
}

template <typename T>
static inline depthcube<T> spvDepthCast(texturecube<T> t)
{
    return reinterpret_cast<thread const depthcube<T> &>(t);
}

template <typename T>
static inline depthcube_array<T> spvDepthCast(texturecube_array<T> t)
{
    return reinterpret_cast<thread const depthcube_array<T> &>(t);
}

struct _171
{
    float4x4 _m0;
    float4x4 _m1;
    float4x4 _m2;
    float4x4 _m3;
    float4 _m4;
    float4 _m5;
    float4 _m6;
    float4 _m7;
    float4 _m8;
    float4 _m9;
    float4 _m10;
    float4 _m11;
    float4 _m12;
    float4 _m13;
    float4x4 _m14[4];
    float4x4 _m15[8];
    float4 _m16;
    float4 _m17;
    float4 _m18;
    float4 _m19;
    float4 _m20;
    float4 _m21;
    float4 _m22;
    float4 _m23;
    float4 _m24;
    float4 _m25;
    float4 _m26[8];
    float4 _m27[4];
    float4 _m28[4];
    float4 _m29;
};

struct _1434
{
    float4 _m0[1024];
};

struct _1470
{
    float4 _m0[1024];
};

struct _1478
{
    float4 _m0[1024];
};

struct _1575
{
    uint4 _m0[1024];
};

struct _1597
{
    uint4 _m0[1024];
};

struct _1618
{
    float4 _m0;
    float4 _m1;
    float4 _m2;
    float4 _m3;
    float4 _m4;
    float4 _m5;
    float4 _m6;
};

constant spvUnsafeArray<float3, 4> _547 = spvUnsafeArray<float3, 4>({ float3(1.0, 0.449999988079071044921875, 0.449999988079071044921875), float3(0.449999988079071044921875, 1.0, 0.449999988079071044921875), float3(0.5, 0.60000002384185791015625, 1.0), float3(1.0, 1.0, 0.4000000059604644775390625) });
constant spvUnsafeArray<float3, 6> _851 = spvUnsafeArray<float3, 6>({ float3(0.0, 0.0, 1.0), float3(0.0, 0.0, -1.0), float3(-1.0, 0.0, 0.0), float3(-1.0, 0.0, 0.0), float3(-1.0, 0.0, 0.0), float3(1.0, 0.0, 0.0) });
constant spvUnsafeArray<float3, 6> _860 = spvUnsafeArray<float3, 6>({ float3(0.0, 1.0, 0.0), float3(0.0, 1.0, 0.0), float3(0.0, 0.0, -1.0), float3(0.0, 0.0, 1.0), float3(0.0, 1.0, 0.0), float3(0.0, 1.0, 0.0) });
constant spvUnsafeArray<int4, 6> _1270 = spvUnsafeArray<int4, 6>({ int4(0, 0, 512, 256), int4(0, 256, 256, 128), int4(256, 256, 128, 64), int4(384, 256, 64, 32), int4(448, 256, 32, 16), int4(480, 256, 16, 8) });

struct fragment_main_out
{
    float4 m_2403 [[color(0)]];
    float2 m_2417 [[color(1)]];
};

struct fragment_main_in
{
    float3 m_1444 [[user(locn0)]];
    float3 m_1705 [[user(locn1)]];
    float2 m_1625 [[user(locn2)]];
    float4 m_1648 [[user(locn3)]];
    float4 m_1853 [[user(locn5)]];
    float4 m_2418 [[user(locn6)]];
    float4 m_2419 [[user(locn7)]];
    float4 m_1714 [[user(locn8)]];
};

fragment fragment_main_out fragment_main(fragment_main_in in [[stage_in]], constant _1618& _1620 [[buffer(2)]], constant _1434& _1436 [[buffer(3)]], constant _1470& _1472 [[buffer(4)]], constant _1478& _1480 [[buffer(5)]], constant _1575& _1577 [[buffer(6)]], constant _1597& _1599 [[buffer(7)]], constant _171& _173 [[buffer(15)]], texture2d<float> _193 [[texture(0)]], texture2d<float> _1641 [[texture(1)]], texture2d<float> _2039 [[texture(2)]], texture2d<float> _1743 [[texture(3)]], texture2d<float> _1886 [[texture(4)]], texture2d<float> _2311 [[texture(5)]], texture2d<float> _1208 [[texture(6)]], texture2d<float> _1314 [[texture(7)]], sampler _193Smplr [[sampler(0)]], sampler _1210 [[sampler(1)]], sampler _1316 [[sampler(7)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])
{
    fragment_main_out out = {};
    float2 _1639 = float2(dot(_1620._m2.xy, in.m_1625) + _1620._m2.z, dot(_1620._m3.xy, in.m_1625) + _1620._m3.z);
    float4 _1646 = _1641.sample(_1210, _1639);
    float3 _1657 = (in.m_1648.xyz * _1620._m0.xyz) * _1646.xyz;
    if ((_1620._m0.w * _1646.w) < _1620._m6.x)
    {
        discard_fragment();
    }
    float3 _6063;
    if (_1620._m1.x > 0.5)
    {
        float2 _1691 = floor(in.m_1444.xz * float2(0.5));
        _6063 = _1657 * ((mod(abs(_1691.x + _1691.y), 2.0) < 0.5) ? 1.0 : 0.75);
    }
    else
    {
        _6063 = _1657;
    }
    float3 _1707 = fast::normalize(in.m_1705);
    float3 _5977;
    if (_1620._m6.y > 0.5)
    {
        float3 _1723 = in.m_1714.xyz - (_1707 * dot(_1707, in.m_1714.xyz));
        float3 _5978;
        if (dot(_1723, _1723) > 9.9999999600419720025001879548654e-13)
        {
            float3 _1732 = fast::normalize(_1723);
            float4 _1748 = _1743.sample(_1210, _1639);
            float3 _5971;
            if (_1620._m6.z > 0.5)
            {
                float2 _5970;
                if (_1620._m6.z > 1.5)
                {
                    _5970 = _1748.xw;
                }
                else
                {
                    _5970 = _1748.xy;
                }
                float2 _1770 = (_5970 * 2.0) - float2(1.0);
                _5971 = float3(_1770, sqrt(fast::clamp(1.0 - dot(_1770, _1770), 0.0, 1.0)));
            }
            else
            {
                _5971 = (_1748.xyz * 2.0) - float3(1.0);
            }
            float2 _1792 = _5971.xy * _1620._m4.z;
            _5978 = fast::normalize(((_1732 * _1792.x) + ((cross(_1707, _1732) * ((in.m_1714.w < 0.0) ? (-1.0) : 1.0)) * _1792.y)) + (_1707 * _5971.z));
        }
        else
        {
            _5978 = _1707;
        }
        _5977 = _5978;
    }
    else
    {
        _5977 = _1707;
    }
    bool _1816 = _1620._m5.w > 0.5;
    bool _1824;
    if (_1816)
    {
        _1824 = !gl_FrontFacing;
    }
    else
    {
        _1824 = _1816;
    }
    float3 _6088;
    if (_1824)
    {
        _6088 = -_5977;
    }
    else
    {
        _6088 = _5977;
    }
    float3 _1833 = fast::normalize(_173._m4.xyz);
    float3 _1839 = _173._m6.xyz - in.m_1444;
    float3 _1840 = fast::normalize(_1839);
    float3 _1845 = fast::normalize(_1833 + _1840);
    float3 _1851 = _1707 * (gl_FrontFacing ? 1.0 : (-1.0));
    bool _1856 = in.m_1853.x > 0.5;
    float3 _6086;
    float _6111;
    if ((_173._m5.w > 0.5) && _1856)
    {
        float _6034;
        float3 _6035;
        do
        {
            int _2472 = int(_173._m21.x);
            float _2480 = dot(_173._m20.xyz, in.m_1444) + _173._m20.w;
            int _5979;
            _5979 = 0;
            for (;;)
            {
                bool _2486 = _5979 < (_2472 - 1);
                bool _2494;
                if (_2486)
                {
                    _2494 = _2480 > _173._m16[_5979];
                }
                else
                {
                    _2494 = _2486;
                }
                if (_2494)
                {
                    _5979++;
                    continue;
                }
                else
                {
                    break;
                }
            }
            if (_2480 > _173._m16[_5979])
            {
                _6035 = float3(1.0);
                _6034 = 1.0;
                break;
            }
            float _5992;
            do
            {
                float4 _2596 = _173._m14[_5979] * float4(in.m_1444 + (_1851 * _173._m18[_5979]), 1.0);
                float _2599 = _2596.x;
                bool _2600 = _2599 < 0.0;
                bool _2607;
                if (!_2600)
                {
                    _2607 = _2599 > 1.0;
                }
                else
                {
                    _2607 = _2600;
                }
                bool _2614;
                if (!_2607)
                {
                    _2614 = _2596.y < 0.0;
                }
                else
                {
                    _2614 = _2607;
                }
                bool _2621;
                if (!_2614)
                {
                    _2621 = _2596.y > 1.0;
                }
                else
                {
                    _2621 = _2614;
                }
                if (_2621)
                {
                    _5992 = 1.0;
                    break;
                }
                float2 _2634 = float2(float(_5979 & 1), float(_5979 >> 1)) * _173._m23.xy;
                float _2641 = fast::min(_2596.z, 1.0) - _173._m19[_5979];
                float2 _2660 = _173._m22.xy * 0.5;
                float2 _2665 = _2634 + (_2596.xy * _173._m23.xy);
                float4 _2678 = float4(_2634 + _2660, (_2634 + _173._m23.xy) - _2660);
                float _5991;
                do
                {
                    int _2704 = int(_173._m22.z);
                    if (_2704 <= 0)
                    {
                        _5991 = spvDepthCast(_193).sample_compare(_193Smplr, float3(fast::clamp(_2665, _2678.xy, _2678.zw), _2641).xy, _2641);
                        break;
                    }
                    float2 _2727 = (_2665 / _173._m22.xy) + float2(0.5);
                    float2 _2728 = floor(_2727);
                    float2 _2733 = _2727 - _2728;
                    float2 _2736 = _2728 - float2(0.5);
                    bool _2740 = _2704 == 1;
                    spvUnsafeArray<float2, 3> _2688;
                    spvUnsafeArray<float2, 3> _2689;
                    if (_2740)
                    {
                        float2 _2743 = _2733 * 2.0;
                        _2688[0] = float2(3.0) - _2743;
                        _2688[1] = float2(1.0) + _2743;
                        _2689[0] = ((float2(2.0) - _2733) / _2688[0]) - float2(1.0);
                        _2689[1] = (_2733 / _2688[1]) + float2(1.0);
                    }
                    else
                    {
                        float2 _2770 = _2733 * 3.0;
                        _2688[0] = float2(4.0) - _2770;
                        _2688[1] = float2(7.0);
                        _2688[2] = float2(1.0) + _2770;
                        _2689[0] = ((float2(3.0) - (_2733 * 2.0)) / _2688[0]) - float2(2.0);
                        _2689[1] = (float2(3.0) + _2733) / _2688[1];
                        _2689[2] = (_2733 / _2688[2]) + float2(2.0);
                    }
                    int _6517 = _2740 ? 2 : 3;
                    int _5981;
                    float _5984;
                    _5984 = 0.0;
                    _5981 = 0;
                    float _5990;
                    for (; _5981 < _6517; _5984 = _5990, _5981++)
                    {
                        _5990 = _5984;
                        for (int _5987 = 0; _5987 < _6517; )
                        {
                            _5990 += ((_2688[_5987].x * _2688[_5981].y) * spvDepthCast(_193).sample_compare(_193Smplr, float3(fast::clamp(_173._m22.xy * (_2736 + float2(_2689[_5987].x, _2689[_5981].y)), _2678.xy, _2678.zw), _2641).xy, _2641));
                            _5987++;
                            continue;
                        }
                    }
                    _5991 = _5984 * (_2740 ? 0.0625 : 0.0069444444961845874786376953125);
                    break;
                } while(false);
                _5992 = _5991;
                break;
            } while(false);
            float3 _6029;
            float _6032;
            if (_2480 > _173._m17[_5979])
            {
                float _2534 = (_2480 - _173._m17[_5979]) / (_173._m16[_5979] - _173._m17[_5979]);
                int _2536 = _5979 + 1;
                float3 _6030;
                float _6033;
                if (_2536 < _2472)
                {
                    float _6012;
                    do
                    {
                        float4 _2883 = _173._m14[_2536] * float4(in.m_1444 + (_1851 * _173._m18[_2536]), 1.0);
                        float _2886 = _2883.x;
                        bool _2887 = _2886 < 0.0;
                        bool _2894;
                        if (!_2887)
                        {
                            _2894 = _2886 > 1.0;
                        }
                        else
                        {
                            _2894 = _2887;
                        }
                        bool _2901;
                        if (!_2894)
                        {
                            _2901 = _2883.y < 0.0;
                        }
                        else
                        {
                            _2901 = _2894;
                        }
                        bool _2908;
                        if (!_2901)
                        {
                            _2908 = _2883.y > 1.0;
                        }
                        else
                        {
                            _2908 = _2901;
                        }
                        if (_2908)
                        {
                            _6012 = 1.0;
                            break;
                        }
                        float2 _2921 = float2(float(_2536 & 1), float(_2536 >> 1)) * _173._m23.xy;
                        float _2928 = fast::min(_2883.z, 1.0) - _173._m19[_2536];
                        float2 _2947 = _173._m22.xy * 0.5;
                        float2 _2952 = _2921 + (_2883.xy * _173._m23.xy);
                        float4 _2965 = float4(_2921 + _2947, (_2921 + _173._m23.xy) - _2947);
                        float _6011;
                        do
                        {
                            int _2991 = int(_173._m22.z);
                            if (_2991 <= 0)
                            {
                                _6011 = spvDepthCast(_193).sample_compare(_193Smplr, float3(fast::clamp(_2952, _2965.xy, _2965.zw), _2928).xy, _2928);
                                break;
                            }
                            float2 _3014 = (_2952 / _173._m22.xy) + float2(0.5);
                            float2 _3015 = floor(_3014);
                            float2 _3020 = _3014 - _3015;
                            float2 _3023 = _3015 - float2(0.5);
                            bool _3027 = _2991 == 1;
                            spvUnsafeArray<float2, 3> _2975;
                            spvUnsafeArray<float2, 3> _2976;
                            if (_3027)
                            {
                                float2 _3030 = _3020 * 2.0;
                                _2975[0] = float2(3.0) - _3030;
                                _2975[1] = float2(1.0) + _3030;
                                _2976[0] = ((float2(2.0) - _3020) / _2975[0]) - float2(1.0);
                                _2976[1] = (_3020 / _2975[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _3057 = _3020 * 3.0;
                                _2975[0] = float2(4.0) - _3057;
                                _2975[1] = float2(7.0);
                                _2975[2] = float2(1.0) + _3057;
                                _2976[0] = ((float2(3.0) - (_3020 * 2.0)) / _2975[0]) - float2(2.0);
                                _2976[1] = (float2(3.0) + _3020) / _2975[1];
                                _2976[2] = (_3020 / _2975[2]) + float2(2.0);
                            }
                            int _6519 = _3027 ? 2 : 3;
                            int _6001;
                            float _6004;
                            _6004 = 0.0;
                            _6001 = 0;
                            float _6010;
                            for (; _6001 < _6519; _6004 = _6010, _6001++)
                            {
                                _6010 = _6004;
                                for (int _6007 = 0; _6007 < _6519; )
                                {
                                    _6010 += ((_2975[_6007].x * _2975[_6001].y) * spvDepthCast(_193).sample_compare(_193Smplr, float3(fast::clamp(_173._m22.xy * (_3023 + float2(_2976[_6007].x, _2976[_6001].y)), _2965.xy, _2965.zw), _2928).xy, _2928));
                                    _6007++;
                                    continue;
                                }
                            }
                            _6011 = _6004 * (_3027 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _6012 = _6011;
                        break;
                    } while(false);
                    _6033 = mix(_5992, _6012, _2534);
                    _6030 = mix(_547[_5979], _547[_2536], float3(_2534));
                }
                else
                {
                    _6033 = mix(_5992, 1.0, _2534);
                    _6030 = _547[_5979];
                }
                _6032 = _6033;
                _6029 = _6030;
            }
            else
            {
                _6032 = _5992;
                _6029 = _547[_5979];
            }
            _6035 = select(float3(1.0), _6029, bool3(_173._m22.w > 0.5));
            _6034 = _6032;
            break;
        } while(false);
        _6111 = _6034;
        _6086 = _6063 * _6035;
    }
    else
    {
        _6111 = 1.0;
        _6086 = _6063;
    }
    float3 _1882 = _173._m5.xyz * _173._m4.w;
    float4 _1891 = _1886.sample(_1210, _1639);
    float _1895 = 1.0 + (_1620._m4.w * (_1891.x - 1.0));
    float3 _6258;
    if (!_1816)
    {
        float _1903 = dot(_6088, _1833);
        float3 _6252;
        if (_173._m29.x > 0.5)
        {
            float _3208 = (_173._m29.z * _6088.x) - (_173._m29.w * _6088.z);
            float _3221 = (_173._m29.w * _6088.x) + (_173._m29.z * _6088.z);
            float _3239 = 1.09254801273345947265625 * _3208;
            spvUnsafeArray<float, 9> _5783 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _6088.y, 0.48860299587249755859375 * _3221, 0.48860299587249755859375 * _3208, _3239 * _6088.y, (1.09254801273345947265625 * _6088.y) * _3221, 0.3153919875621795654296875 * (((3.0 * _3221) * _3221) - 1.0), _3239 * _3221, 0.546274006366729736328125 * ((_3208 * _3208) - (_6088.y * _6088.y)) });
            spvUnsafeArray<float, 9> _3153 = _5783;
            float3 _6251;
            _6251 = float3(0.0);
            for (int _6250 = 0; _6250 < 9; )
            {
                _6251 += (_1208.read(uint2((int2(496, 256) + int2(_6250, 0))), 0).xyz * _3153[_6250]);
                _6250++;
                continue;
            }
            _6252 = fast::max(_6251, float3(0.0)) * _173._m29.y;
        }
        else
        {
            _6252 = mix(_173._m9.xyz, _173._m8.xyz, float3((_6088.y * 0.5) + 0.5)) * _173._m8.w;
        }
        float3 _1953 = (_6086 * ((_6252 * _1895) + ((_1882 * fast::max(_1903, 0.0)) * _6111))) + ((_1882 * ((powr(fast::max(dot(_6088, _1845), 0.0), _1620._m1.w) * _1620._m1.z) * step(0.0, _1903))) * _6111);
        float3 _6259;
        if (_173._m13.w > 0.5)
        {
            float2 _3324 = fast::clamp(floor(gl_FragCoord.xy * _173._m12.xy), float2(0.0), _173._m13.xy - float2(1.0));
            uint _3352 = uint((((fast::clamp(floor((log2(fast::max(dot(_173._m11.xyz, in.m_1444) + _173._m11.w, 9.9999999747524270787835121154785e-07)) * _173._m12.z) + _173._m12.w), 0.0, _173._m13.z - 1.0) * _173._m13.y) + _3324.y) * _173._m13.x) + _3324.x);
            uint _3354 = _3352 >> uint(2);
            uint _3356 = _3352 & 3u;
            uint _3360 = _1577._m0[_3354][_3356] & 65535u;
            uint _3362 = _1577._m0[_3354][_3356] >> uint(16);
            float3 _6260;
            _6260 = _1953;
            float3 _2034;
            spvUnsafeArray<float2, 3> _3770;
            spvUnsafeArray<float2, 3> _3771;
            spvUnsafeArray<float2, 3> _3983;
            spvUnsafeArray<float2, 3> _3984;
            for (uint _6257 = _3360; _6257 < (_3360 + _3362); _6260 = _2034, _6257++)
            {
                uint _3368 = _6257 / 3u;
                uint _3381 = (_1599._m0[_3368 >> uint(2)][_3368 & 3u] >> ((_6257 - (_3368 * 3u)) * 10u)) & 1023u;
                float3 _3398 = _1436._m0[_3381].xyz - in.m_1444;
                float _3401 = dot(_3398, _3398);
                float _3405 = _3401 * _1436._m0[_3381].w;
                float _3410 = fast::clamp(1.0 - (_3405 * _3405), 0.0, 1.0);
                float3 _3415 = _3398 * rsqrt(fast::max(_3401, 9.9999999392252902907785028219223e-09));
                float _3433 = fast::clamp((dot(-_3415, _1480._m0[_3381].xyz) * _1472._m0[_3381].w) + _1480._m0[_3381].w, 0.0, 1.0);
                float3 _3446 = _1472._m0[_3381].xyz * ((((_3410 * _3410) * _3433) * _3433) / fast::max(_3401, 9.9999997473787516355514526367188e-05));
                float3 _6441;
                if (_1856)
                {
                    float _6387;
                    do
                    {
                        uint _3482 = uint(_173._m21.z);
                        if (_3381 < _3482)
                        {
                            float _3504 = _173._m26[_3381].z * fast::max((_173._m15[_3381] * float4(in.m_1444, 1.0)).w, 0.0);
                            float4 _3528 = _173._m15[_3381] * float4((in.m_1444 + (_1851 * (_3504 * _173._m25.x))) + (_3415 * (_3504 * _173._m25.y)), 1.0);
                            float _3530 = _3528.w;
                            if (_3530 <= 0.0)
                            {
                                _6387 = 1.0;
                                break;
                            }
                            float3 _3539 = _3528.xyz / float3(_3530);
                            float _3541 = _3539.x;
                            bool _3542 = _3541 < 0.0;
                            bool _3549;
                            if (!_3542)
                            {
                                _3549 = _3541 > 1.0;
                            }
                            else
                            {
                                _3549 = _3542;
                            }
                            bool _3556;
                            if (!_3549)
                            {
                                _3556 = _3539.y < 0.0;
                            }
                            else
                            {
                                _3556 = _3549;
                            }
                            bool _3563;
                            if (!_3556)
                            {
                                _3563 = _3539.y > 1.0;
                            }
                            else
                            {
                                _3563 = _3556;
                            }
                            bool _3570;
                            if (!_3563)
                            {
                                _3570 = _3539.z > 1.0;
                            }
                            else
                            {
                                _3570 = _3563;
                            }
                            if (_3570)
                            {
                                _6387 = 1.0;
                                break;
                            }
                            float _3576 = _3539.z;
                            float2 _3742 = _173._m22.xy * 0.5;
                            float2 _3747 = _173._m26[_3381].xy + (_3539.xy * _173._m23.zw);
                            float4 _3760 = float4(_173._m26[_3381].xy + _3742, (_173._m26[_3381].xy + _173._m23.zw) - _3742);
                            float _6386;
                            do
                            {
                                int _3786 = int(_173._m22.z);
                                if (_3786 <= 0)
                                {
                                    float2 _3796 = fast::clamp(_3747, _3760.xy, _3760.zw);
                                    _6386 = spvDepthCast(_193).sample_compare(_193Smplr, float3(_3796, _3576).xy, _3576);
                                    break;
                                }
                                float2 _3809 = (_3747 / _173._m22.xy) + float2(0.5);
                                float2 _3810 = floor(_3809);
                                float2 _3815 = _3809 - _3810;
                                float2 _3818 = _3810 - float2(0.5);
                                bool _3822 = _3786 == 1;
                                if (_3822)
                                {
                                    float2 _3825 = _3815 * 2.0;
                                    _3770[0] = float2(3.0) - _3825;
                                    _3770[1] = float2(1.0) + _3825;
                                    _3771[0] = ((float2(2.0) - _3815) / _3770[0]) - float2(1.0);
                                    _3771[1] = (_3815 / _3770[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _3852 = _3815 * 3.0;
                                    _3770[0] = float2(4.0) - _3852;
                                    _3770[1] = float2(7.0);
                                    _3770[2] = float2(1.0) + _3852;
                                    _3771[0] = ((float2(3.0) - (_3815 * 2.0)) / _3770[0]) - float2(2.0);
                                    _3771[1] = (float2(3.0) + _3815) / _3770[1];
                                    _3771[2] = (_3815 / _3770[2]) + float2(2.0);
                                }
                                int _6524 = _3822 ? 2 : 3;
                                int _6376;
                                float _6379;
                                _6379 = 0.0;
                                _6376 = 0;
                                float _6385;
                                for (; _6376 < _6524; _6379 = _6385, _6376++)
                                {
                                    _6385 = _6379;
                                    for (int _6382 = 0; _6382 < _6524; )
                                    {
                                        _6385 += ((_3770[_6382].x * _3770[_6376].y) * spvDepthCast(_193).sample_compare(_193Smplr, float3(fast::clamp(_173._m22.xy * (_3818 + float2(_3771[_6382].x, _3771[_6376].y)), _3760.xy, _3760.zw), _3576).xy, _3576));
                                        _6382++;
                                        continue;
                                    }
                                }
                                _6386 = _6379 * (_3822 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _6387 = _6386;
                            break;
                        }
                        uint _3586 = _3381 - _3482;
                        if (_3586 >= uint(_173._m21.w))
                        {
                            _6387 = 1.0;
                            break;
                        }
                        float _3607 = _173._m27[_3586].w * length(in.m_1444 - _173._m27[_3586].xyz);
                        float3 _3625 = ((in.m_1444 + (_1851 * (_3607 * _173._m25.x))) + (_3415 * (_3607 * _173._m25.y))) - _173._m27[_3586].xyz;
                        float3 _3627 = abs(_3625);
                        float _3629 = _3627.x;
                        float _3631 = _3627.y;
                        bool _3632 = _3629 >= _3631;
                        bool _3640;
                        if (_3632)
                        {
                            _3640 = _3629 >= _3627.z;
                        }
                        else
                        {
                            _3640 = _3632;
                        }
                        float _6361;
                        int _6363;
                        if (_3640)
                        {
                            _6363 = (_3625.x > 0.0) ? 0 : 1;
                            _6361 = _3629;
                        }
                        else
                        {
                            float _3652 = _3627.z;
                            bool _3653 = _3631 >= _3652;
                            int _6364;
                            if (_3653)
                            {
                                _6364 = (_3625.y > 0.0) ? 2 : 3;
                            }
                            else
                            {
                                _6364 = (_3625.z > 0.0) ? 4 : 5;
                            }
                            _6363 = _6364;
                            _6361 = _3653 ? _3631 : _3652;
                        }
                        if (_6361 <= 0.0)
                        {
                            _6387 = 1.0;
                            break;
                        }
                        float2 _3690 = float2(dot(_3625, _851[_6363]), dot(_3625, _860[_6363])) / float2(_6361 * _173._m24.z);
                        float _3697 = _173._m28[_3586].z + (_173._m28[_3586].w / _6361);
                        if (_3697 > 1.0)
                        {
                            _6387 = 1.0;
                            break;
                        }
                        float2 _3715 = _173._m28[_3586].xy + (float2(float(spvSMod(_6363, 3)), float(_6363 / 3)) * _173._m24.xy);
                        float2 _3955 = _173._m22.xy * 0.5;
                        float2 _3960 = _3715 + (float2(0.5 + (0.5 * _3690.x), 0.5 - (0.5 * _3690.y)) * _173._m24.xy);
                        float4 _3973 = float4(_3715 + _3955, (_3715 + _173._m24.xy) - _3955);
                        float _6375;
                        do
                        {
                            int _3999 = int(_173._m22.z);
                            if (_3999 <= 0)
                            {
                                _6375 = spvDepthCast(_193).sample_compare(_193Smplr, float3(fast::clamp(_3960, _3973.xy, _3973.zw), _3697).xy, _3697);
                                break;
                            }
                            float2 _4022 = (_3960 / _173._m22.xy) + float2(0.5);
                            float2 _4023 = floor(_4022);
                            float2 _4028 = _4022 - _4023;
                            float2 _4031 = _4023 - float2(0.5);
                            bool _4035 = _3999 == 1;
                            if (_4035)
                            {
                                float2 _4038 = _4028 * 2.0;
                                _3983[0] = float2(3.0) - _4038;
                                _3983[1] = float2(1.0) + _4038;
                                _3984[0] = ((float2(2.0) - _4028) / _3983[0]) - float2(1.0);
                                _3984[1] = (_4028 / _3983[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _4065 = _4028 * 3.0;
                                _3983[0] = float2(4.0) - _4065;
                                _3983[1] = float2(7.0);
                                _3983[2] = float2(1.0) + _4065;
                                _3984[0] = ((float2(3.0) - (_4028 * 2.0)) / _3983[0]) - float2(2.0);
                                _3984[1] = (float2(3.0) + _4028) / _3983[1];
                                _3984[2] = (_4028 / _3983[2]) + float2(2.0);
                            }
                            int _6527 = _4035 ? 2 : 3;
                            int _6365;
                            float _6368;
                            _6368 = 0.0;
                            _6365 = 0;
                            float _6374;
                            for (; _6365 < _6527; _6368 = _6374, _6365++)
                            {
                                _6374 = _6368;
                                for (int _6371 = 0; _6371 < _6527; )
                                {
                                    _6374 += ((_3983[_6371].x * _3983[_6365].y) * spvDepthCast(_193).sample_compare(_193Smplr, float3(fast::clamp(_173._m22.xy * (_4031 + float2(_3984[_6371].x, _3984[_6365].y)), _3973.xy, _3973.zw), _3697).xy, _3697));
                                    _6371++;
                                    continue;
                                }
                            }
                            _6375 = _6368 * (_4035 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _6387 = _6375;
                        break;
                    } while(false);
                    _6441 = _3446 * _6387;
                }
                else
                {
                    _6441 = _3446;
                }
                float _2005 = dot(_6088, _3415);
                _2034 = _6260 + (((_6086 * fast::max(_2005, 0.0)) * _6441) + (_6441 * ((powr(fast::max(dot(_6088, fast::normalize(_3415 + _1840)), 0.0), _1620._m1.w) * _1620._m1.z) * step(0.0, _2005))));
            }
            _6259 = _6260;
        }
        else
        {
            _6259 = _1953;
        }
        _6258 = _6259;
    }
    else
    {
        float4 _2044 = _2039.sample(_1210, _1639);
        float _2051 = fast::clamp(_1620._m4.x * _2044.z, 0.0, 1.0);
        float _2059 = fast::clamp(_1620._m4.y * _2044.y, 0.04500000178813934326171875, 1.0);
        float _2063 = _2059 * _2059;
        float3 _2068 = _6086 * (1.0 - _2051);
        float3 _2075 = mix(float3(0.039999999105930328369140625), _6086, float3(_2051));
        float _2080 = fast::max(dot(_6088, _1840), 9.9999997473787516355514526367188e-05);
        float _2085 = fast::clamp(dot(_6088, _1833), 0.0, 1.0);
        float _2090 = fast::clamp(dot(_6088, _1845), 0.0, 1.0);
        float3 _4167 = float3(1.0) - _2075;
        float3 _4170 = _2075 + (_4167 * powr(1.0 - fast::clamp(dot(_1840, _1845), 0.0, 1.0), 5.0));
        float _4177 = _2063 * _2063;
        float _4182 = _4177 - 1.0;
        float _4184 = ((_2090 * _2090) * _4182) + 1.0;
        float _4204 = 1.0 - _4177;
        float _4208 = sqrt(((_2080 * _2080) * _4204) + _4177);
        float2 _6129;
        float3 _6137;
        float3 _6144;
        if (_173._m29.x > 0.5)
        {
            float4 _4241 = _1314.sample(_1316, (((float2(_2080, _2059) * 31.0) + float2(0.5)) * float2(0.03125)));
            float _4300 = (_173._m29.z * _6088.x) - (_173._m29.w * _6088.z);
            float _4313 = (_173._m29.w * _6088.x) + (_173._m29.z * _6088.z);
            float _4331 = 1.09254801273345947265625 * _4300;
            spvUnsafeArray<float, 9> _5764 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _6088.y, 0.48860299587249755859375 * _4313, 0.48860299587249755859375 * _4300, _4331 * _6088.y, (1.09254801273345947265625 * _6088.y) * _4313, 0.3153919875621795654296875 * (((3.0 * _4313) * _4313) - 1.0), _4331 * _4313, 0.546274006366729736328125 * ((_4300 * _4300) - (_6088.y * _6088.y)) });
            spvUnsafeArray<float, 9> _4245 = _5764;
            float3 _6113;
            _6113 = float3(0.0);
            for (int _6112 = 0; _6112 < 9; )
            {
                _6113 += (_1208.read(uint2((int2(496, 256) + int2(_6112, 0))), 0).xyz * _4245[_6112]);
                _6112++;
                continue;
            }
            float3 _2151 = reflect(-_1840, _6088);
            float _4426 = _2151.x;
            float _4431 = _2151.z;
            float2 _4463 = float2((precise::atan2((_173._m29.z * _4426) - (_173._m29.w * _4431), -((_173._m29.w * _4426) + (_173._m29.z * _4431))) * 0.15915493667125701904296875) + 0.5, acos(fast::clamp(_2151.y, -1.0, 1.0)) * 0.3183098733425140380859375);
            float _4395 = _2059 * 5.0;
            int _4398 = min(int(_4395), 4);
            float2 _4484 = (_4463 * float2(_1270[_4398].zw)) - float2(0.5);
            float2 _4486 = floor(_4484);
            float2 _4489 = _4484 - _4486;
            int _4492 = int(_4486.x);
            int _4495 = int(_4486.y);
            int _6115;
            if (_4492 < 0)
            {
                _6115 = _4492 + _1270[_4398].z;
            }
            else
            {
                _6115 = _4492;
            }
            int _6116;
            if (_6115 >= _1270[_4398].z)
            {
                _6116 = _6115 - _1270[_4398].z;
            }
            else
            {
                _6116 = _6115;
            }
            int _4515 = _6116 + 1;
            int _6528 = (_4515 == _1270[_4398].z) ? 0 : _4515;
            int _4530 = min((_4495 + 1), (_1270[_4398].w - 1));
            int _4532 = max(_4495, 0);
            float3 _4585 = float3(_4489.x);
            int _4405 = _4398 + 1;
            float2 _4617 = (_4463 * float2(_1270[_4405].zw)) - float2(0.5);
            float2 _4619 = floor(_4617);
            float2 _4622 = _4617 - _4619;
            int _4625 = int(_4619.x);
            int _4628 = int(_4619.y);
            int _6122;
            if (_4625 < 0)
            {
                _6122 = _4625 + _1270[_4405].z;
            }
            else
            {
                _6122 = _4625;
            }
            int _6123;
            if (_6122 >= _1270[_4405].z)
            {
                _6123 = _6122 - _1270[_4405].z;
            }
            else
            {
                _6123 = _6122;
            }
            int _4648 = _6123 + 1;
            int _6529 = (_4648 == _1270[_4405].z) ? 0 : _4648;
            int _4663 = min((_4628 + 1), (_1270[_4405].w - 1));
            int _4665 = max(_4628, 0);
            float3 _4718 = float3(_4622.x);
            float3 _4420 = mix(mix(mix(_1208.read(uint2((_1270[_4398].xy + int2(_6116, _4532))), 0).xyz, _1208.read(uint2((_1270[_4398].xy + int2(_6528, _4532))), 0).xyz, _4585), mix(_1208.read(uint2((_1270[_4398].xy + int2(_6116, _4530))), 0).xyz, _1208.read(uint2((_1270[_4398].xy + int2(_6528, _4530))), 0).xyz, _4585), float3(_4489.y)), mix(mix(_1208.read(uint2((_1270[_4405].xy + int2(_6123, _4665))), 0).xyz, _1208.read(uint2((_1270[_4405].xy + int2(_6529, _4665))), 0).xyz, _4718), mix(_1208.read(uint2((_1270[_4405].xy + int2(_6123, _4663))), 0).xyz, _1208.read(uint2((_1270[_4405].xy + int2(_6529, _4663))), 0).xyz, _4718), float3(_4622.y)), float3(_4395 - float(_4398))) * _173._m29.y;
            _6144 = _4420;
            _6137 = fast::max(_6113, float3(0.0)) * _173._m29.y;
            _6129 = _4241.xy;
        }
        else
        {
            float4 _4736 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * _2059) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);
            float _4738 = _4736.x;
            float3 _4773 = mix(_173._m9.xyz, _173._m8.xyz, float3((_6088.y * 0.5) + 0.5)) * _173._m8.w;
            _6144 = mix(mix(_173._m9.xyz, _173._m8.xyz, float3((reflect(-_1840, _6088).y * 0.5) + 0.5)) * _173._m8.w, _4773, float3(_2059));
            _6137 = _4773;
            _6129 = (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_4738 * _4738, exp2((-9.27999973297119140625) * _2080)) * _4738) + _4736.y)) + _4736.zw;
        }
        float3 _2183 = (_2075 * _6129.x) + float3(_6129.y);
        float3 _2199 = ((((((float3(1.0) - _4170) * _2068) + ((_4170 * ((_4177 / ((3.1415927410125732421875 * _4184) * _4184)) * (0.5 / fast::max((_2085 * _4208) + (_2080 * sqrt(((_2085 * _2085) * _4204) + _4177)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875)) * _2085) * _1882) * _6111) + (((((float3(1.0) - _2183) * _2068) * _6137) + (_2183 * _6144)) * _1895);
        float3 _6261;
        if (_173._m13.w > 0.5)
        {
            float2 _4818 = fast::clamp(floor(gl_FragCoord.xy * _173._m12.xy), float2(0.0), _173._m13.xy - float2(1.0));
            uint _4846 = uint((((fast::clamp(floor((log2(fast::max(dot(_173._m11.xyz, in.m_1444) + _173._m11.w, 9.9999999747524270787835121154785e-07)) * _173._m12.z) + _173._m12.w), 0.0, _173._m13.z - 1.0) * _173._m13.y) + _4818.y) * _173._m13.x) + _4818.x);
            uint _4848 = _4846 >> uint(2);
            uint _4850 = _4846 & 3u;
            uint _4854 = _1577._m0[_4848][_4850] & 65535u;
            uint _4856 = _1577._m0[_4848][_4850] >> uint(16);
            float3 _6216;
            _6216 = _2199;
            float3 _2299;
            spvUnsafeArray<float2, 3> _5264;
            spvUnsafeArray<float2, 3> _5265;
            spvUnsafeArray<float2, 3> _5477;
            spvUnsafeArray<float2, 3> _5478;
            for (uint _6145 = _4854; _6145 < (_4854 + _4856); _6216 = _2299, _6145++)
            {
                uint _4862 = _6145 / 3u;
                uint _4875 = (_1599._m0[_4862 >> uint(2)][_4862 & 3u] >> ((_6145 - (_4862 * 3u)) * 10u)) & 1023u;
                float3 _4892 = _1436._m0[_4875].xyz - in.m_1444;
                float _4895 = dot(_4892, _4892);
                float _4899 = _4895 * _1436._m0[_4875].w;
                float _4904 = fast::clamp(1.0 - (_4899 * _4899), 0.0, 1.0);
                float3 _4909 = _4892 * rsqrt(fast::max(_4895, 9.9999999392252902907785028219223e-09));
                float _4927 = fast::clamp((dot(-_4909, _1480._m0[_4875].xyz) * _1472._m0[_4875].w) + _1480._m0[_4875].w, 0.0, 1.0);
                float3 _4940 = _1472._m0[_4875].xyz * ((((_4904 * _4904) * _4927) * _4927) / fast::max(_4895, 9.9999997473787516355514526367188e-05));
                float3 _6214;
                if (_1856)
                {
                    float _6172;
                    do
                    {
                        uint _4976 = uint(_173._m21.z);
                        if (_4875 < _4976)
                        {
                            float _4998 = _173._m26[_4875].z * fast::max((_173._m15[_4875] * float4(in.m_1444, 1.0)).w, 0.0);
                            float4 _5022 = _173._m15[_4875] * float4((in.m_1444 + (_1851 * (_4998 * _173._m25.x))) + (_4909 * (_4998 * _173._m25.y)), 1.0);
                            float _5024 = _5022.w;
                            if (_5024 <= 0.0)
                            {
                                _6172 = 1.0;
                                break;
                            }
                            float3 _5033 = _5022.xyz / float3(_5024);
                            float _5035 = _5033.x;
                            bool _5036 = _5035 < 0.0;
                            bool _5043;
                            if (!_5036)
                            {
                                _5043 = _5035 > 1.0;
                            }
                            else
                            {
                                _5043 = _5036;
                            }
                            bool _5050;
                            if (!_5043)
                            {
                                _5050 = _5033.y < 0.0;
                            }
                            else
                            {
                                _5050 = _5043;
                            }
                            bool _5057;
                            if (!_5050)
                            {
                                _5057 = _5033.y > 1.0;
                            }
                            else
                            {
                                _5057 = _5050;
                            }
                            bool _5064;
                            if (!_5057)
                            {
                                _5064 = _5033.z > 1.0;
                            }
                            else
                            {
                                _5064 = _5057;
                            }
                            if (_5064)
                            {
                                _6172 = 1.0;
                                break;
                            }
                            float _5070 = _5033.z;
                            float2 _5236 = _173._m22.xy * 0.5;
                            float2 _5241 = _173._m26[_4875].xy + (_5033.xy * _173._m23.zw);
                            float4 _5254 = float4(_173._m26[_4875].xy + _5236, (_173._m26[_4875].xy + _173._m23.zw) - _5236);
                            float _6171;
                            do
                            {
                                int _5280 = int(_173._m22.z);
                                if (_5280 <= 0)
                                {
                                    float2 _5290 = fast::clamp(_5241, _5254.xy, _5254.zw);
                                    _6171 = spvDepthCast(_193).sample_compare(_193Smplr, float3(_5290, _5070).xy, _5070);
                                    break;
                                }
                                float2 _5303 = (_5241 / _173._m22.xy) + float2(0.5);
                                float2 _5304 = floor(_5303);
                                float2 _5309 = _5303 - _5304;
                                float2 _5312 = _5304 - float2(0.5);
                                bool _5316 = _5280 == 1;
                                if (_5316)
                                {
                                    float2 _5319 = _5309 * 2.0;
                                    _5264[0] = float2(3.0) - _5319;
                                    _5264[1] = float2(1.0) + _5319;
                                    _5265[0] = ((float2(2.0) - _5309) / _5264[0]) - float2(1.0);
                                    _5265[1] = (_5309 / _5264[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _5346 = _5309 * 3.0;
                                    _5264[0] = float2(4.0) - _5346;
                                    _5264[1] = float2(7.0);
                                    _5264[2] = float2(1.0) + _5346;
                                    _5265[0] = ((float2(3.0) - (_5309 * 2.0)) / _5264[0]) - float2(2.0);
                                    _5265[1] = (float2(3.0) + _5309) / _5264[1];
                                    _5265[2] = (_5309 / _5264[2]) + float2(2.0);
                                }
                                int _6531 = _5316 ? 2 : 3;
                                int _6161;
                                float _6164;
                                _6164 = 0.0;
                                _6161 = 0;
                                float _6170;
                                for (; _6161 < _6531; _6164 = _6170, _6161++)
                                {
                                    _6170 = _6164;
                                    for (int _6167 = 0; _6167 < _6531; )
                                    {
                                        _6170 += ((_5264[_6167].x * _5264[_6161].y) * spvDepthCast(_193).sample_compare(_193Smplr, float3(fast::clamp(_173._m22.xy * (_5312 + float2(_5265[_6167].x, _5265[_6161].y)), _5254.xy, _5254.zw), _5070).xy, _5070));
                                        _6167++;
                                        continue;
                                    }
                                }
                                _6171 = _6164 * (_5316 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _6172 = _6171;
                            break;
                        }
                        uint _5080 = _4875 - _4976;
                        if (_5080 >= uint(_173._m21.w))
                        {
                            _6172 = 1.0;
                            break;
                        }
                        float _5101 = _173._m27[_5080].w * length(in.m_1444 - _173._m27[_5080].xyz);
                        float3 _5119 = ((in.m_1444 + (_1851 * (_5101 * _173._m25.x))) + (_4909 * (_5101 * _173._m25.y))) - _173._m27[_5080].xyz;
                        float3 _5121 = abs(_5119);
                        float _5123 = _5121.x;
                        float _5125 = _5121.y;
                        bool _5126 = _5123 >= _5125;
                        bool _5134;
                        if (_5126)
                        {
                            _5134 = _5123 >= _5121.z;
                        }
                        else
                        {
                            _5134 = _5126;
                        }
                        float _6146;
                        int _6148;
                        if (_5134)
                        {
                            _6148 = (_5119.x > 0.0) ? 0 : 1;
                            _6146 = _5123;
                        }
                        else
                        {
                            float _5146 = _5121.z;
                            bool _5147 = _5125 >= _5146;
                            int _6149;
                            if (_5147)
                            {
                                _6149 = (_5119.y > 0.0) ? 2 : 3;
                            }
                            else
                            {
                                _6149 = (_5119.z > 0.0) ? 4 : 5;
                            }
                            _6148 = _6149;
                            _6146 = _5147 ? _5125 : _5146;
                        }
                        if (_6146 <= 0.0)
                        {
                            _6172 = 1.0;
                            break;
                        }
                        float2 _5184 = float2(dot(_5119, _851[_6148]), dot(_5119, _860[_6148])) / float2(_6146 * _173._m24.z);
                        float _5191 = _173._m28[_5080].z + (_173._m28[_5080].w / _6146);
                        if (_5191 > 1.0)
                        {
                            _6172 = 1.0;
                            break;
                        }
                        float2 _5209 = _173._m28[_5080].xy + (float2(float(spvSMod(_6148, 3)), float(_6148 / 3)) * _173._m24.xy);
                        float2 _5449 = _173._m22.xy * 0.5;
                        float2 _5454 = _5209 + (float2(0.5 + (0.5 * _5184.x), 0.5 - (0.5 * _5184.y)) * _173._m24.xy);
                        float4 _5467 = float4(_5209 + _5449, (_5209 + _173._m24.xy) - _5449);
                        float _6160;
                        do
                        {
                            int _5493 = int(_173._m22.z);
                            if (_5493 <= 0)
                            {
                                _6160 = spvDepthCast(_193).sample_compare(_193Smplr, float3(fast::clamp(_5454, _5467.xy, _5467.zw), _5191).xy, _5191);
                                break;
                            }
                            float2 _5516 = (_5454 / _173._m22.xy) + float2(0.5);
                            float2 _5517 = floor(_5516);
                            float2 _5522 = _5516 - _5517;
                            float2 _5525 = _5517 - float2(0.5);
                            bool _5529 = _5493 == 1;
                            if (_5529)
                            {
                                float2 _5532 = _5522 * 2.0;
                                _5477[0] = float2(3.0) - _5532;
                                _5477[1] = float2(1.0) + _5532;
                                _5478[0] = ((float2(2.0) - _5522) / _5477[0]) - float2(1.0);
                                _5478[1] = (_5522 / _5477[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _5559 = _5522 * 3.0;
                                _5477[0] = float2(4.0) - _5559;
                                _5477[1] = float2(7.0);
                                _5477[2] = float2(1.0) + _5559;
                                _5478[0] = ((float2(3.0) - (_5522 * 2.0)) / _5477[0]) - float2(2.0);
                                _5478[1] = (float2(3.0) + _5522) / _5477[1];
                                _5478[2] = (_5522 / _5477[2]) + float2(2.0);
                            }
                            int _6534 = _5529 ? 2 : 3;
                            int _6150;
                            float _6153;
                            _6153 = 0.0;
                            _6150 = 0;
                            float _6159;
                            for (; _6150 < _6534; _6153 = _6159, _6150++)
                            {
                                _6159 = _6153;
                                for (int _6156 = 0; _6156 < _6534; )
                                {
                                    _6159 += ((_5477[_6156].x * _5477[_6150].y) * spvDepthCast(_193).sample_compare(_193Smplr, float3(fast::clamp(_173._m22.xy * (_5525 + float2(_5478[_6156].x, _5478[_6150].y)), _5467.xy, _5467.zw), _5191).xy, _5191));
                                    _6156++;
                                    continue;
                                }
                            }
                            _6160 = _6153 * (_5529 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _6172 = _6160;
                        break;
                    } while(false);
                    _6214 = _4940 * _6172;
                }
                else
                {
                    _6214 = _4940;
                }
                float3 _2251 = fast::normalize(_4909 + _1840);
                float _2256 = fast::clamp(dot(_6088, _4909), 0.0, 1.0);
                float _2261 = fast::clamp(dot(_6088, _2251), 0.0, 1.0);
                float3 _5664 = _2075 + (_4167 * powr(1.0 - fast::clamp(dot(_1840, _2251), 0.0, 1.0), 5.0));
                float _5678 = ((_2261 * _2261) * _4182) + 1.0;
                _2299 = _6216 + (((((float3(1.0) - _5664) * _2068) + ((_5664 * ((_4177 / ((3.1415927410125732421875 * _5678) * _5678)) * (0.5 / fast::max((_2256 * _4208) + (_2080 * sqrt(((_2256 * _2256) * _4204) + _4177)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875)) * _2256) * _6214);
            }
            _6261 = _6216;
        }
        else
        {
            _6261 = _2199;
        }
        _6258 = _6261;
    }
    float4 _2316 = _2311.sample(_1210, _1639);
    float _2334 = -length(_1839);
    float _6295;
    if (_173._m9.w != 0.0)
    {
        float _2358 = _173._m9.w * (in.m_1444 - _173._m6.xyz).y;
        float _6292;
        if (abs(_2358) < 9.9999997473787516355514526367188e-05)
        {
            _6292 = 1.0 - (0.5 * _2358);
        }
        else
        {
            _6292 = (1.0 - exp(fast::min(-_2358, 60.0))) / _2358;
        }
        _6295 = 1.0 - exp((_2334 * (_173._m7.w * exp(fast::min((-_173._m9.w) * (_173._m6.y - _173._m6.w), 30.0)))) * _6292);
    }
    else
    {
        _6295 = 1.0 - exp(_2334 * _173._m7.w);
    }
    out.m_2403 = float4(mix(mix(_6258, _6086, float3(_1620._m1.y)) + ((_1620._m5.xyz * _2316.xyz) * (float3(1.0) + in.m_1853.yzw)), _173._m7.xyz, float3(_6295)), in.m_1648.w);
    float2 _6360;
    do
    {
        if (in.m_2419.w <= 0.0)
        {
            _6360 = float2(0.0);
            break;
        }
        _6360 = ((in.m_2419.xy / float2(in.m_2419.w)) - (in.m_2418.xy / float2(in.m_2418.w))) * float2(0.5, -0.5);
        break;
    } while(false);
    out.m_2417 = _6360;
    return out;
}

