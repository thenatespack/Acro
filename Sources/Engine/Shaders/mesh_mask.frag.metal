// Generated from mesh_mask.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 0264422ead528981
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
    float4 m_2337 [[color(0)]];
    float2 m_2351 [[color(1)]];
};

struct fragment_main_in
{
    float3 m_1444 [[user(locn0)]];
    float3 m_1705 [[user(locn1)]];
    float2 m_1625 [[user(locn2)]];
    float4 m_1648 [[user(locn3)]];
    float4 m_1853 [[user(locn5)]];
    float4 m_2352 [[user(locn6)]];
    float4 m_2353 [[user(locn7)]];
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
    float3 _5996;
    if (_1620._m1.x > 0.5)
    {
        float2 _1691 = floor(in.m_1444.xz * float2(0.5));
        _5996 = _1657 * ((mod(abs(_1691.x + _1691.y), 2.0) < 0.5) ? 1.0 : 0.75);
    }
    else
    {
        _5996 = _1657;
    }
    float3 _1707 = fast::normalize(in.m_1705);
    float3 _5910;
    if (_1620._m6.y > 0.5)
    {
        float3 _1723 = in.m_1714.xyz - (_1707 * dot(_1707, in.m_1714.xyz));
        float3 _5911;
        if (dot(_1723, _1723) > 9.9999999600419720025001879548654e-13)
        {
            float3 _1732 = fast::normalize(_1723);
            float4 _1748 = _1743.sample(_1210, _1639);
            float3 _5904;
            if (_1620._m6.z > 0.5)
            {
                float2 _5903;
                if (_1620._m6.z > 1.5)
                {
                    _5903 = _1748.xw;
                }
                else
                {
                    _5903 = _1748.xy;
                }
                float2 _1770 = (_5903 * 2.0) - float2(1.0);
                _5904 = float3(_1770, sqrt(fast::clamp(1.0 - dot(_1770, _1770), 0.0, 1.0)));
            }
            else
            {
                _5904 = (_1748.xyz * 2.0) - float3(1.0);
            }
            float2 _1792 = _5904.xy * _1620._m4.z;
            _5911 = fast::normalize(((_1732 * _1792.x) + ((cross(_1707, _1732) * ((in.m_1714.w < 0.0) ? (-1.0) : 1.0)) * _1792.y)) + (_1707 * _5904.z));
        }
        else
        {
            _5911 = _1707;
        }
        _5910 = _5911;
    }
    else
    {
        _5910 = _1707;
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
    float3 _6021;
    if (_1824)
    {
        _6021 = -_5910;
    }
    else
    {
        _6021 = _5910;
    }
    float3 _1833 = fast::normalize(_173._m4.xyz);
    float3 _1839 = _173._m6.xyz - in.m_1444;
    float3 _1840 = fast::normalize(_1839);
    float3 _1845 = fast::normalize(_1833 + _1840);
    float3 _1851 = _1707 * (gl_FrontFacing ? 1.0 : (-1.0));
    bool _1856 = in.m_1853.x > 0.5;
    float3 _6019;
    float _6044;
    if ((_173._m5.w > 0.5) && _1856)
    {
        float _5967;
        float3 _5968;
        do
        {
            int _2406 = int(_173._m21.x);
            float _2414 = dot(_173._m20.xyz, in.m_1444) + _173._m20.w;
            int _5912;
            _5912 = 0;
            for (;;)
            {
                bool _2420 = _5912 < (_2406 - 1);
                bool _2428;
                if (_2420)
                {
                    _2428 = _2414 > _173._m16[_5912];
                }
                else
                {
                    _2428 = _2420;
                }
                if (_2428)
                {
                    _5912++;
                    continue;
                }
                else
                {
                    break;
                }
            }
            if (_2414 > _173._m16[_5912])
            {
                _5968 = float3(1.0);
                _5967 = 1.0;
                break;
            }
            float _5925;
            do
            {
                float4 _2530 = _173._m14[_5912] * float4(in.m_1444 + (_1851 * _173._m18[_5912]), 1.0);
                float _2533 = _2530.x;
                bool _2534 = _2533 < 0.0;
                bool _2541;
                if (!_2534)
                {
                    _2541 = _2533 > 1.0;
                }
                else
                {
                    _2541 = _2534;
                }
                bool _2548;
                if (!_2541)
                {
                    _2548 = _2530.y < 0.0;
                }
                else
                {
                    _2548 = _2541;
                }
                bool _2555;
                if (!_2548)
                {
                    _2555 = _2530.y > 1.0;
                }
                else
                {
                    _2555 = _2548;
                }
                if (_2555)
                {
                    _5925 = 1.0;
                    break;
                }
                float2 _2568 = float2(float(_5912 & 1), float(_5912 >> 1)) * _173._m23.xy;
                float _2575 = fast::min(_2530.z, 1.0) - _173._m19[_5912];
                float2 _2594 = _173._m22.xy * 0.5;
                float2 _2599 = _2568 + (_2530.xy * _173._m23.xy);
                float4 _2612 = float4(_2568 + _2594, (_2568 + _173._m23.xy) - _2594);
                float _5924;
                do
                {
                    int _2638 = int(_173._m22.z);
                    if (_2638 <= 0)
                    {
                        _5924 = spvDepthCast(_193).sample_compare(_193Smplr, float3(fast::clamp(_2599, _2612.xy, _2612.zw), _2575).xy, _2575);
                        break;
                    }
                    float2 _2661 = (_2599 / _173._m22.xy) + float2(0.5);
                    float2 _2662 = floor(_2661);
                    float2 _2667 = _2661 - _2662;
                    float2 _2670 = _2662 - float2(0.5);
                    bool _2674 = _2638 == 1;
                    spvUnsafeArray<float2, 3> _2622;
                    spvUnsafeArray<float2, 3> _2623;
                    if (_2674)
                    {
                        float2 _2677 = _2667 * 2.0;
                        _2622[0] = float2(3.0) - _2677;
                        _2622[1] = float2(1.0) + _2677;
                        _2623[0] = ((float2(2.0) - _2667) / _2622[0]) - float2(1.0);
                        _2623[1] = (_2667 / _2622[1]) + float2(1.0);
                    }
                    else
                    {
                        float2 _2704 = _2667 * 3.0;
                        _2622[0] = float2(4.0) - _2704;
                        _2622[1] = float2(7.0);
                        _2622[2] = float2(1.0) + _2704;
                        _2623[0] = ((float2(3.0) - (_2667 * 2.0)) / _2622[0]) - float2(2.0);
                        _2623[1] = (float2(3.0) + _2667) / _2622[1];
                        _2623[2] = (_2667 / _2622[2]) + float2(2.0);
                    }
                    int _6444 = _2674 ? 2 : 3;
                    int _5914;
                    float _5917;
                    _5917 = 0.0;
                    _5914 = 0;
                    float _5923;
                    for (; _5914 < _6444; _5917 = _5923, _5914++)
                    {
                        _5923 = _5917;
                        for (int _5920 = 0; _5920 < _6444; )
                        {
                            _5923 += ((_2622[_5920].x * _2622[_5914].y) * spvDepthCast(_193).sample_compare(_193Smplr, float3(fast::clamp(_173._m22.xy * (_2670 + float2(_2623[_5920].x, _2623[_5914].y)), _2612.xy, _2612.zw), _2575).xy, _2575));
                            _5920++;
                            continue;
                        }
                    }
                    _5924 = _5917 * (_2674 ? 0.0625 : 0.0069444444961845874786376953125);
                    break;
                } while(false);
                _5925 = _5924;
                break;
            } while(false);
            float3 _5962;
            float _5965;
            if (_2414 > _173._m17[_5912])
            {
                float _2468 = (_2414 - _173._m17[_5912]) / (_173._m16[_5912] - _173._m17[_5912]);
                int _2470 = _5912 + 1;
                float3 _5963;
                float _5966;
                if (_2470 < _2406)
                {
                    float _5945;
                    do
                    {
                        float4 _2817 = _173._m14[_2470] * float4(in.m_1444 + (_1851 * _173._m18[_2470]), 1.0);
                        float _2820 = _2817.x;
                        bool _2821 = _2820 < 0.0;
                        bool _2828;
                        if (!_2821)
                        {
                            _2828 = _2820 > 1.0;
                        }
                        else
                        {
                            _2828 = _2821;
                        }
                        bool _2835;
                        if (!_2828)
                        {
                            _2835 = _2817.y < 0.0;
                        }
                        else
                        {
                            _2835 = _2828;
                        }
                        bool _2842;
                        if (!_2835)
                        {
                            _2842 = _2817.y > 1.0;
                        }
                        else
                        {
                            _2842 = _2835;
                        }
                        if (_2842)
                        {
                            _5945 = 1.0;
                            break;
                        }
                        float2 _2855 = float2(float(_2470 & 1), float(_2470 >> 1)) * _173._m23.xy;
                        float _2862 = fast::min(_2817.z, 1.0) - _173._m19[_2470];
                        float2 _2881 = _173._m22.xy * 0.5;
                        float2 _2886 = _2855 + (_2817.xy * _173._m23.xy);
                        float4 _2899 = float4(_2855 + _2881, (_2855 + _173._m23.xy) - _2881);
                        float _5944;
                        do
                        {
                            int _2925 = int(_173._m22.z);
                            if (_2925 <= 0)
                            {
                                _5944 = spvDepthCast(_193).sample_compare(_193Smplr, float3(fast::clamp(_2886, _2899.xy, _2899.zw), _2862).xy, _2862);
                                break;
                            }
                            float2 _2948 = (_2886 / _173._m22.xy) + float2(0.5);
                            float2 _2949 = floor(_2948);
                            float2 _2954 = _2948 - _2949;
                            float2 _2957 = _2949 - float2(0.5);
                            bool _2961 = _2925 == 1;
                            spvUnsafeArray<float2, 3> _2909;
                            spvUnsafeArray<float2, 3> _2910;
                            if (_2961)
                            {
                                float2 _2964 = _2954 * 2.0;
                                _2909[0] = float2(3.0) - _2964;
                                _2909[1] = float2(1.0) + _2964;
                                _2910[0] = ((float2(2.0) - _2954) / _2909[0]) - float2(1.0);
                                _2910[1] = (_2954 / _2909[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _2991 = _2954 * 3.0;
                                _2909[0] = float2(4.0) - _2991;
                                _2909[1] = float2(7.0);
                                _2909[2] = float2(1.0) + _2991;
                                _2910[0] = ((float2(3.0) - (_2954 * 2.0)) / _2909[0]) - float2(2.0);
                                _2910[1] = (float2(3.0) + _2954) / _2909[1];
                                _2910[2] = (_2954 / _2909[2]) + float2(2.0);
                            }
                            int _6446 = _2961 ? 2 : 3;
                            int _5934;
                            float _5937;
                            _5937 = 0.0;
                            _5934 = 0;
                            float _5943;
                            for (; _5934 < _6446; _5937 = _5943, _5934++)
                            {
                                _5943 = _5937;
                                for (int _5940 = 0; _5940 < _6446; )
                                {
                                    _5943 += ((_2909[_5940].x * _2909[_5934].y) * spvDepthCast(_193).sample_compare(_193Smplr, float3(fast::clamp(_173._m22.xy * (_2957 + float2(_2910[_5940].x, _2910[_5934].y)), _2899.xy, _2899.zw), _2862).xy, _2862));
                                    _5940++;
                                    continue;
                                }
                            }
                            _5944 = _5937 * (_2961 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _5945 = _5944;
                        break;
                    } while(false);
                    _5966 = mix(_5925, _5945, _2468);
                    _5963 = mix(_547[_5912], _547[_2470], float3(_2468));
                }
                else
                {
                    _5966 = mix(_5925, 1.0, _2468);
                    _5963 = _547[_5912];
                }
                _5965 = _5966;
                _5962 = _5963;
            }
            else
            {
                _5965 = _5925;
                _5962 = _547[_5912];
            }
            _5968 = select(float3(1.0), _5962, bool3(_173._m22.w > 0.5));
            _5967 = _5965;
            break;
        } while(false);
        _6044 = _5967;
        _6019 = _5996 * _5968;
    }
    else
    {
        _6044 = 1.0;
        _6019 = _5996;
    }
    float3 _1882 = _173._m5.xyz * _173._m4.w;
    float4 _1891 = _1886.sample(_1210, _1639);
    float _1895 = 1.0 + (_1620._m4.w * (_1891.x - 1.0));
    float3 _6191;
    if (!_1816)
    {
        float _1903 = dot(_6021, _1833);
        float3 _6185;
        if (_173._m29.x > 0.5)
        {
            float _3142 = (_173._m29.z * _6021.x) - (_173._m29.w * _6021.z);
            float _3155 = (_173._m29.w * _6021.x) + (_173._m29.z * _6021.z);
            float _3173 = 1.09254801273345947265625 * _3142;
            spvUnsafeArray<float, 9> _5717 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _6021.y, 0.48860299587249755859375 * _3155, 0.48860299587249755859375 * _3142, _3173 * _6021.y, (1.09254801273345947265625 * _6021.y) * _3155, 0.3153919875621795654296875 * (((3.0 * _3155) * _3155) - 1.0), _3173 * _3155, 0.546274006366729736328125 * ((_3142 * _3142) - (_6021.y * _6021.y)) });
            spvUnsafeArray<float, 9> _3087 = _5717;
            float3 _6184;
            _6184 = float3(0.0);
            for (int _6183 = 0; _6183 < 9; )
            {
                _6184 += (_1208.read(uint2((int2(496, 256) + int2(_6183, 0))), 0).xyz * _3087[_6183]);
                _6183++;
                continue;
            }
            _6185 = fast::max(_6184, float3(0.0)) * _173._m29.y;
        }
        else
        {
            _6185 = mix(_173._m9.xyz, _173._m8.xyz, float3((_6021.y * 0.5) + 0.5)) * _173._m8.w;
        }
        float3 _1953 = (_6019 * ((_6185 * _1895) + ((_1882 * fast::max(_1903, 0.0)) * _6044))) + ((_1882 * ((powr(fast::max(dot(_6021, _1845), 0.0), _1620._m1.w) * _1620._m1.z) * step(0.0, _1903))) * _6044);
        float3 _6192;
        if (_173._m13.w > 0.5)
        {
            float2 _3258 = fast::clamp(floor(gl_FragCoord.xy * _173._m12.xy), float2(0.0), _173._m13.xy - float2(1.0));
            uint _3286 = uint((((fast::clamp(floor((log2(fast::max(dot(_173._m11.xyz, in.m_1444) + _173._m11.w, 9.9999999747524270787835121154785e-07)) * _173._m12.z) + _173._m12.w), 0.0, _173._m13.z - 1.0) * _173._m13.y) + _3258.y) * _173._m13.x) + _3258.x);
            uint _3288 = _3286 >> uint(2);
            uint _3290 = _3286 & 3u;
            uint _3294 = _1577._m0[_3288][_3290] & 65535u;
            uint _3296 = _1577._m0[_3288][_3290] >> uint(16);
            float3 _6193;
            _6193 = _1953;
            float3 _2034;
            spvUnsafeArray<float2, 3> _3704;
            spvUnsafeArray<float2, 3> _3705;
            spvUnsafeArray<float2, 3> _3917;
            spvUnsafeArray<float2, 3> _3918;
            for (uint _6190 = _3294; _6190 < (_3294 + _3296); _6193 = _2034, _6190++)
            {
                uint _3302 = _6190 / 3u;
                uint _3315 = (_1599._m0[_3302 >> uint(2)][_3302 & 3u] >> ((_6190 - (_3302 * 3u)) * 10u)) & 1023u;
                float3 _3332 = _1436._m0[_3315].xyz - in.m_1444;
                float _3335 = dot(_3332, _3332);
                float _3339 = _3335 * _1436._m0[_3315].w;
                float _3344 = fast::clamp(1.0 - (_3339 * _3339), 0.0, 1.0);
                float3 _3349 = _3332 * rsqrt(fast::max(_3335, 9.9999999392252902907785028219223e-09));
                float _3367 = fast::clamp((dot(-_3349, _1480._m0[_3315].xyz) * _1472._m0[_3315].w) + _1480._m0[_3315].w, 0.0, 1.0);
                float3 _3380 = _1472._m0[_3315].xyz * ((((_3344 * _3344) * _3367) * _3367) / fast::max(_3335, 9.9999997473787516355514526367188e-05));
                float3 _6368;
                if (_1856)
                {
                    float _6314;
                    do
                    {
                        uint _3416 = uint(_173._m21.z);
                        if (_3315 < _3416)
                        {
                            float _3438 = _173._m26[_3315].z * fast::max((_173._m15[_3315] * float4(in.m_1444, 1.0)).w, 0.0);
                            float4 _3462 = _173._m15[_3315] * float4((in.m_1444 + (_1851 * (_3438 * _173._m25.x))) + (_3349 * (_3438 * _173._m25.y)), 1.0);
                            float _3464 = _3462.w;
                            if (_3464 <= 0.0)
                            {
                                _6314 = 1.0;
                                break;
                            }
                            float3 _3473 = _3462.xyz / float3(_3464);
                            float _3475 = _3473.x;
                            bool _3476 = _3475 < 0.0;
                            bool _3483;
                            if (!_3476)
                            {
                                _3483 = _3475 > 1.0;
                            }
                            else
                            {
                                _3483 = _3476;
                            }
                            bool _3490;
                            if (!_3483)
                            {
                                _3490 = _3473.y < 0.0;
                            }
                            else
                            {
                                _3490 = _3483;
                            }
                            bool _3497;
                            if (!_3490)
                            {
                                _3497 = _3473.y > 1.0;
                            }
                            else
                            {
                                _3497 = _3490;
                            }
                            bool _3504;
                            if (!_3497)
                            {
                                _3504 = _3473.z > 1.0;
                            }
                            else
                            {
                                _3504 = _3497;
                            }
                            if (_3504)
                            {
                                _6314 = 1.0;
                                break;
                            }
                            float _3510 = _3473.z;
                            float2 _3676 = _173._m22.xy * 0.5;
                            float2 _3681 = _173._m26[_3315].xy + (_3473.xy * _173._m23.zw);
                            float4 _3694 = float4(_173._m26[_3315].xy + _3676, (_173._m26[_3315].xy + _173._m23.zw) - _3676);
                            float _6313;
                            do
                            {
                                int _3720 = int(_173._m22.z);
                                if (_3720 <= 0)
                                {
                                    float2 _3730 = fast::clamp(_3681, _3694.xy, _3694.zw);
                                    _6313 = spvDepthCast(_193).sample_compare(_193Smplr, float3(_3730, _3510).xy, _3510);
                                    break;
                                }
                                float2 _3743 = (_3681 / _173._m22.xy) + float2(0.5);
                                float2 _3744 = floor(_3743);
                                float2 _3749 = _3743 - _3744;
                                float2 _3752 = _3744 - float2(0.5);
                                bool _3756 = _3720 == 1;
                                if (_3756)
                                {
                                    float2 _3759 = _3749 * 2.0;
                                    _3704[0] = float2(3.0) - _3759;
                                    _3704[1] = float2(1.0) + _3759;
                                    _3705[0] = ((float2(2.0) - _3749) / _3704[0]) - float2(1.0);
                                    _3705[1] = (_3749 / _3704[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _3786 = _3749 * 3.0;
                                    _3704[0] = float2(4.0) - _3786;
                                    _3704[1] = float2(7.0);
                                    _3704[2] = float2(1.0) + _3786;
                                    _3705[0] = ((float2(3.0) - (_3749 * 2.0)) / _3704[0]) - float2(2.0);
                                    _3705[1] = (float2(3.0) + _3749) / _3704[1];
                                    _3705[2] = (_3749 / _3704[2]) + float2(2.0);
                                }
                                int _6451 = _3756 ? 2 : 3;
                                int _6303;
                                float _6306;
                                _6306 = 0.0;
                                _6303 = 0;
                                float _6312;
                                for (; _6303 < _6451; _6306 = _6312, _6303++)
                                {
                                    _6312 = _6306;
                                    for (int _6309 = 0; _6309 < _6451; )
                                    {
                                        _6312 += ((_3704[_6309].x * _3704[_6303].y) * spvDepthCast(_193).sample_compare(_193Smplr, float3(fast::clamp(_173._m22.xy * (_3752 + float2(_3705[_6309].x, _3705[_6303].y)), _3694.xy, _3694.zw), _3510).xy, _3510));
                                        _6309++;
                                        continue;
                                    }
                                }
                                _6313 = _6306 * (_3756 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _6314 = _6313;
                            break;
                        }
                        uint _3520 = _3315 - _3416;
                        if (_3520 >= uint(_173._m21.w))
                        {
                            _6314 = 1.0;
                            break;
                        }
                        float _3541 = _173._m27[_3520].w * length(in.m_1444 - _173._m27[_3520].xyz);
                        float3 _3559 = ((in.m_1444 + (_1851 * (_3541 * _173._m25.x))) + (_3349 * (_3541 * _173._m25.y))) - _173._m27[_3520].xyz;
                        float3 _3561 = abs(_3559);
                        float _3563 = _3561.x;
                        float _3565 = _3561.y;
                        bool _3566 = _3563 >= _3565;
                        bool _3574;
                        if (_3566)
                        {
                            _3574 = _3563 >= _3561.z;
                        }
                        else
                        {
                            _3574 = _3566;
                        }
                        float _6288;
                        int _6290;
                        if (_3574)
                        {
                            _6290 = (_3559.x > 0.0) ? 0 : 1;
                            _6288 = _3563;
                        }
                        else
                        {
                            float _3586 = _3561.z;
                            bool _3587 = _3565 >= _3586;
                            int _6291;
                            if (_3587)
                            {
                                _6291 = (_3559.y > 0.0) ? 2 : 3;
                            }
                            else
                            {
                                _6291 = (_3559.z > 0.0) ? 4 : 5;
                            }
                            _6290 = _6291;
                            _6288 = _3587 ? _3565 : _3586;
                        }
                        if (_6288 <= 0.0)
                        {
                            _6314 = 1.0;
                            break;
                        }
                        float2 _3624 = float2(dot(_3559, _851[_6290]), dot(_3559, _860[_6290])) / float2(_6288 * _173._m24.z);
                        float _3631 = _173._m28[_3520].z + (_173._m28[_3520].w / _6288);
                        if (_3631 > 1.0)
                        {
                            _6314 = 1.0;
                            break;
                        }
                        float2 _3649 = _173._m28[_3520].xy + (float2(float(spvSMod(_6290, 3)), float(_6290 / 3)) * _173._m24.xy);
                        float2 _3889 = _173._m22.xy * 0.5;
                        float2 _3894 = _3649 + (float2(0.5 + (0.5 * _3624.x), 0.5 - (0.5 * _3624.y)) * _173._m24.xy);
                        float4 _3907 = float4(_3649 + _3889, (_3649 + _173._m24.xy) - _3889);
                        float _6302;
                        do
                        {
                            int _3933 = int(_173._m22.z);
                            if (_3933 <= 0)
                            {
                                _6302 = spvDepthCast(_193).sample_compare(_193Smplr, float3(fast::clamp(_3894, _3907.xy, _3907.zw), _3631).xy, _3631);
                                break;
                            }
                            float2 _3956 = (_3894 / _173._m22.xy) + float2(0.5);
                            float2 _3957 = floor(_3956);
                            float2 _3962 = _3956 - _3957;
                            float2 _3965 = _3957 - float2(0.5);
                            bool _3969 = _3933 == 1;
                            if (_3969)
                            {
                                float2 _3972 = _3962 * 2.0;
                                _3917[0] = float2(3.0) - _3972;
                                _3917[1] = float2(1.0) + _3972;
                                _3918[0] = ((float2(2.0) - _3962) / _3917[0]) - float2(1.0);
                                _3918[1] = (_3962 / _3917[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _3999 = _3962 * 3.0;
                                _3917[0] = float2(4.0) - _3999;
                                _3917[1] = float2(7.0);
                                _3917[2] = float2(1.0) + _3999;
                                _3918[0] = ((float2(3.0) - (_3962 * 2.0)) / _3917[0]) - float2(2.0);
                                _3918[1] = (float2(3.0) + _3962) / _3917[1];
                                _3918[2] = (_3962 / _3917[2]) + float2(2.0);
                            }
                            int _6454 = _3969 ? 2 : 3;
                            int _6292;
                            float _6295;
                            _6295 = 0.0;
                            _6292 = 0;
                            float _6301;
                            for (; _6292 < _6454; _6295 = _6301, _6292++)
                            {
                                _6301 = _6295;
                                for (int _6298 = 0; _6298 < _6454; )
                                {
                                    _6301 += ((_3917[_6298].x * _3917[_6292].y) * spvDepthCast(_193).sample_compare(_193Smplr, float3(fast::clamp(_173._m22.xy * (_3965 + float2(_3918[_6298].x, _3918[_6292].y)), _3907.xy, _3907.zw), _3631).xy, _3631));
                                    _6298++;
                                    continue;
                                }
                            }
                            _6302 = _6295 * (_3969 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _6314 = _6302;
                        break;
                    } while(false);
                    _6368 = _3380 * _6314;
                }
                else
                {
                    _6368 = _3380;
                }
                float _2005 = dot(_6021, _3349);
                _2034 = _6193 + (((_6019 * fast::max(_2005, 0.0)) * _6368) + (_6368 * ((powr(fast::max(dot(_6021, fast::normalize(_3349 + _1840)), 0.0), _1620._m1.w) * _1620._m1.z) * step(0.0, _2005))));
            }
            _6192 = _6193;
        }
        else
        {
            _6192 = _1953;
        }
        _6191 = _6192;
    }
    else
    {
        float4 _2044 = _2039.sample(_1210, _1639);
        float _2051 = fast::clamp(_1620._m4.x * _2044.z, 0.0, 1.0);
        float _2059 = fast::clamp(_1620._m4.y * _2044.y, 0.04500000178813934326171875, 1.0);
        float _2063 = _2059 * _2059;
        float3 _2068 = _6019 * (1.0 - _2051);
        float3 _2075 = mix(float3(0.039999999105930328369140625), _6019, float3(_2051));
        float _2080 = fast::max(dot(_6021, _1840), 9.9999997473787516355514526367188e-05);
        float _2085 = fast::clamp(dot(_6021, _1833), 0.0, 1.0);
        float _2090 = fast::clamp(dot(_6021, _1845), 0.0, 1.0);
        float3 _4101 = float3(1.0) - _2075;
        float3 _4104 = _2075 + (_4101 * powr(1.0 - fast::clamp(dot(_1840, _1845), 0.0, 1.0), 5.0));
        float _4111 = _2063 * _2063;
        float _4116 = _4111 - 1.0;
        float _4118 = ((_2090 * _2090) * _4116) + 1.0;
        float _4138 = 1.0 - _4111;
        float _4142 = sqrt(((_2080 * _2080) * _4138) + _4111);
        float2 _6062;
        float3 _6070;
        float3 _6077;
        if (_173._m29.x > 0.5)
        {
            float4 _4175 = _1314.sample(_1316, (((float2(_2080, _2059) * 31.0) + float2(0.5)) * float2(0.03125)));
            float _4234 = (_173._m29.z * _6021.x) - (_173._m29.w * _6021.z);
            float _4247 = (_173._m29.w * _6021.x) + (_173._m29.z * _6021.z);
            float _4265 = 1.09254801273345947265625 * _4234;
            spvUnsafeArray<float, 9> _5698 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _6021.y, 0.48860299587249755859375 * _4247, 0.48860299587249755859375 * _4234, _4265 * _6021.y, (1.09254801273345947265625 * _6021.y) * _4247, 0.3153919875621795654296875 * (((3.0 * _4247) * _4247) - 1.0), _4265 * _4247, 0.546274006366729736328125 * ((_4234 * _4234) - (_6021.y * _6021.y)) });
            spvUnsafeArray<float, 9> _4179 = _5698;
            float3 _6046;
            _6046 = float3(0.0);
            for (int _6045 = 0; _6045 < 9; )
            {
                _6046 += (_1208.read(uint2((int2(496, 256) + int2(_6045, 0))), 0).xyz * _4179[_6045]);
                _6045++;
                continue;
            }
            float3 _2151 = reflect(-_1840, _6021);
            float _4360 = _2151.x;
            float _4365 = _2151.z;
            float2 _4397 = float2((precise::atan2((_173._m29.z * _4360) - (_173._m29.w * _4365), -((_173._m29.w * _4360) + (_173._m29.z * _4365))) * 0.15915493667125701904296875) + 0.5, acos(fast::clamp(_2151.y, -1.0, 1.0)) * 0.3183098733425140380859375);
            float _4329 = _2059 * 5.0;
            int _4332 = min(int(_4329), 4);
            float2 _4418 = (_4397 * float2(_1270[_4332].zw)) - float2(0.5);
            float2 _4420 = floor(_4418);
            float2 _4423 = _4418 - _4420;
            int _4426 = int(_4420.x);
            int _4429 = int(_4420.y);
            int _6048;
            if (_4426 < 0)
            {
                _6048 = _4426 + _1270[_4332].z;
            }
            else
            {
                _6048 = _4426;
            }
            int _6049;
            if (_6048 >= _1270[_4332].z)
            {
                _6049 = _6048 - _1270[_4332].z;
            }
            else
            {
                _6049 = _6048;
            }
            int _4449 = _6049 + 1;
            int _6455 = (_4449 == _1270[_4332].z) ? 0 : _4449;
            int _4464 = min((_4429 + 1), (_1270[_4332].w - 1));
            int _4466 = max(_4429, 0);
            float3 _4519 = float3(_4423.x);
            int _4339 = _4332 + 1;
            float2 _4551 = (_4397 * float2(_1270[_4339].zw)) - float2(0.5);
            float2 _4553 = floor(_4551);
            float2 _4556 = _4551 - _4553;
            int _4559 = int(_4553.x);
            int _4562 = int(_4553.y);
            int _6055;
            if (_4559 < 0)
            {
                _6055 = _4559 + _1270[_4339].z;
            }
            else
            {
                _6055 = _4559;
            }
            int _6056;
            if (_6055 >= _1270[_4339].z)
            {
                _6056 = _6055 - _1270[_4339].z;
            }
            else
            {
                _6056 = _6055;
            }
            int _4582 = _6056 + 1;
            int _6456 = (_4582 == _1270[_4339].z) ? 0 : _4582;
            int _4597 = min((_4562 + 1), (_1270[_4339].w - 1));
            int _4599 = max(_4562, 0);
            float3 _4652 = float3(_4556.x);
            float3 _4354 = mix(mix(mix(_1208.read(uint2((_1270[_4332].xy + int2(_6049, _4466))), 0).xyz, _1208.read(uint2((_1270[_4332].xy + int2(_6455, _4466))), 0).xyz, _4519), mix(_1208.read(uint2((_1270[_4332].xy + int2(_6049, _4464))), 0).xyz, _1208.read(uint2((_1270[_4332].xy + int2(_6455, _4464))), 0).xyz, _4519), float3(_4423.y)), mix(mix(_1208.read(uint2((_1270[_4339].xy + int2(_6056, _4599))), 0).xyz, _1208.read(uint2((_1270[_4339].xy + int2(_6456, _4599))), 0).xyz, _4652), mix(_1208.read(uint2((_1270[_4339].xy + int2(_6056, _4597))), 0).xyz, _1208.read(uint2((_1270[_4339].xy + int2(_6456, _4597))), 0).xyz, _4652), float3(_4556.y)), float3(_4329 - float(_4332))) * _173._m29.y;
            _6077 = _4354;
            _6070 = fast::max(_6046, float3(0.0)) * _173._m29.y;
            _6062 = _4175.xy;
        }
        else
        {
            float4 _4670 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * _2059) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);
            float _4672 = _4670.x;
            float3 _4707 = mix(_173._m9.xyz, _173._m8.xyz, float3((_6021.y * 0.5) + 0.5)) * _173._m8.w;
            _6077 = mix(mix(_173._m9.xyz, _173._m8.xyz, float3((reflect(-_1840, _6021).y * 0.5) + 0.5)) * _173._m8.w, _4707, float3(_2059));
            _6070 = _4707;
            _6062 = (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_4672 * _4672, exp2((-9.27999973297119140625) * _2080)) * _4672) + _4670.y)) + _4670.zw;
        }
        float3 _2183 = (_2075 * _6062.x) + float3(_6062.y);
        float3 _2199 = ((((((float3(1.0) - _4104) * _2068) + ((_4104 * ((_4111 / ((3.1415927410125732421875 * _4118) * _4118)) * (0.5 / fast::max((_2085 * _4142) + (_2080 * sqrt(((_2085 * _2085) * _4138) + _4111)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875)) * _2085) * _1882) * _6044) + (((((float3(1.0) - _2183) * _2068) * _6070) + (_2183 * _6077)) * _1895);
        float3 _6194;
        if (_173._m13.w > 0.5)
        {
            float2 _4752 = fast::clamp(floor(gl_FragCoord.xy * _173._m12.xy), float2(0.0), _173._m13.xy - float2(1.0));
            uint _4780 = uint((((fast::clamp(floor((log2(fast::max(dot(_173._m11.xyz, in.m_1444) + _173._m11.w, 9.9999999747524270787835121154785e-07)) * _173._m12.z) + _173._m12.w), 0.0, _173._m13.z - 1.0) * _173._m13.y) + _4752.y) * _173._m13.x) + _4752.x);
            uint _4782 = _4780 >> uint(2);
            uint _4784 = _4780 & 3u;
            uint _4788 = _1577._m0[_4782][_4784] & 65535u;
            uint _4790 = _1577._m0[_4782][_4784] >> uint(16);
            float3 _6149;
            _6149 = _2199;
            float3 _2299;
            spvUnsafeArray<float2, 3> _5198;
            spvUnsafeArray<float2, 3> _5199;
            spvUnsafeArray<float2, 3> _5411;
            spvUnsafeArray<float2, 3> _5412;
            for (uint _6078 = _4788; _6078 < (_4788 + _4790); _6149 = _2299, _6078++)
            {
                uint _4796 = _6078 / 3u;
                uint _4809 = (_1599._m0[_4796 >> uint(2)][_4796 & 3u] >> ((_6078 - (_4796 * 3u)) * 10u)) & 1023u;
                float3 _4826 = _1436._m0[_4809].xyz - in.m_1444;
                float _4829 = dot(_4826, _4826);
                float _4833 = _4829 * _1436._m0[_4809].w;
                float _4838 = fast::clamp(1.0 - (_4833 * _4833), 0.0, 1.0);
                float3 _4843 = _4826 * rsqrt(fast::max(_4829, 9.9999999392252902907785028219223e-09));
                float _4861 = fast::clamp((dot(-_4843, _1480._m0[_4809].xyz) * _1472._m0[_4809].w) + _1480._m0[_4809].w, 0.0, 1.0);
                float3 _4874 = _1472._m0[_4809].xyz * ((((_4838 * _4838) * _4861) * _4861) / fast::max(_4829, 9.9999997473787516355514526367188e-05));
                float3 _6147;
                if (_1856)
                {
                    float _6105;
                    do
                    {
                        uint _4910 = uint(_173._m21.z);
                        if (_4809 < _4910)
                        {
                            float _4932 = _173._m26[_4809].z * fast::max((_173._m15[_4809] * float4(in.m_1444, 1.0)).w, 0.0);
                            float4 _4956 = _173._m15[_4809] * float4((in.m_1444 + (_1851 * (_4932 * _173._m25.x))) + (_4843 * (_4932 * _173._m25.y)), 1.0);
                            float _4958 = _4956.w;
                            if (_4958 <= 0.0)
                            {
                                _6105 = 1.0;
                                break;
                            }
                            float3 _4967 = _4956.xyz / float3(_4958);
                            float _4969 = _4967.x;
                            bool _4970 = _4969 < 0.0;
                            bool _4977;
                            if (!_4970)
                            {
                                _4977 = _4969 > 1.0;
                            }
                            else
                            {
                                _4977 = _4970;
                            }
                            bool _4984;
                            if (!_4977)
                            {
                                _4984 = _4967.y < 0.0;
                            }
                            else
                            {
                                _4984 = _4977;
                            }
                            bool _4991;
                            if (!_4984)
                            {
                                _4991 = _4967.y > 1.0;
                            }
                            else
                            {
                                _4991 = _4984;
                            }
                            bool _4998;
                            if (!_4991)
                            {
                                _4998 = _4967.z > 1.0;
                            }
                            else
                            {
                                _4998 = _4991;
                            }
                            if (_4998)
                            {
                                _6105 = 1.0;
                                break;
                            }
                            float _5004 = _4967.z;
                            float2 _5170 = _173._m22.xy * 0.5;
                            float2 _5175 = _173._m26[_4809].xy + (_4967.xy * _173._m23.zw);
                            float4 _5188 = float4(_173._m26[_4809].xy + _5170, (_173._m26[_4809].xy + _173._m23.zw) - _5170);
                            float _6104;
                            do
                            {
                                int _5214 = int(_173._m22.z);
                                if (_5214 <= 0)
                                {
                                    float2 _5224 = fast::clamp(_5175, _5188.xy, _5188.zw);
                                    _6104 = spvDepthCast(_193).sample_compare(_193Smplr, float3(_5224, _5004).xy, _5004);
                                    break;
                                }
                                float2 _5237 = (_5175 / _173._m22.xy) + float2(0.5);
                                float2 _5238 = floor(_5237);
                                float2 _5243 = _5237 - _5238;
                                float2 _5246 = _5238 - float2(0.5);
                                bool _5250 = _5214 == 1;
                                if (_5250)
                                {
                                    float2 _5253 = _5243 * 2.0;
                                    _5198[0] = float2(3.0) - _5253;
                                    _5198[1] = float2(1.0) + _5253;
                                    _5199[0] = ((float2(2.0) - _5243) / _5198[0]) - float2(1.0);
                                    _5199[1] = (_5243 / _5198[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _5280 = _5243 * 3.0;
                                    _5198[0] = float2(4.0) - _5280;
                                    _5198[1] = float2(7.0);
                                    _5198[2] = float2(1.0) + _5280;
                                    _5199[0] = ((float2(3.0) - (_5243 * 2.0)) / _5198[0]) - float2(2.0);
                                    _5199[1] = (float2(3.0) + _5243) / _5198[1];
                                    _5199[2] = (_5243 / _5198[2]) + float2(2.0);
                                }
                                int _6458 = _5250 ? 2 : 3;
                                int _6094;
                                float _6097;
                                _6097 = 0.0;
                                _6094 = 0;
                                float _6103;
                                for (; _6094 < _6458; _6097 = _6103, _6094++)
                                {
                                    _6103 = _6097;
                                    for (int _6100 = 0; _6100 < _6458; )
                                    {
                                        _6103 += ((_5198[_6100].x * _5198[_6094].y) * spvDepthCast(_193).sample_compare(_193Smplr, float3(fast::clamp(_173._m22.xy * (_5246 + float2(_5199[_6100].x, _5199[_6094].y)), _5188.xy, _5188.zw), _5004).xy, _5004));
                                        _6100++;
                                        continue;
                                    }
                                }
                                _6104 = _6097 * (_5250 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _6105 = _6104;
                            break;
                        }
                        uint _5014 = _4809 - _4910;
                        if (_5014 >= uint(_173._m21.w))
                        {
                            _6105 = 1.0;
                            break;
                        }
                        float _5035 = _173._m27[_5014].w * length(in.m_1444 - _173._m27[_5014].xyz);
                        float3 _5053 = ((in.m_1444 + (_1851 * (_5035 * _173._m25.x))) + (_4843 * (_5035 * _173._m25.y))) - _173._m27[_5014].xyz;
                        float3 _5055 = abs(_5053);
                        float _5057 = _5055.x;
                        float _5059 = _5055.y;
                        bool _5060 = _5057 >= _5059;
                        bool _5068;
                        if (_5060)
                        {
                            _5068 = _5057 >= _5055.z;
                        }
                        else
                        {
                            _5068 = _5060;
                        }
                        float _6079;
                        int _6081;
                        if (_5068)
                        {
                            _6081 = (_5053.x > 0.0) ? 0 : 1;
                            _6079 = _5057;
                        }
                        else
                        {
                            float _5080 = _5055.z;
                            bool _5081 = _5059 >= _5080;
                            int _6082;
                            if (_5081)
                            {
                                _6082 = (_5053.y > 0.0) ? 2 : 3;
                            }
                            else
                            {
                                _6082 = (_5053.z > 0.0) ? 4 : 5;
                            }
                            _6081 = _6082;
                            _6079 = _5081 ? _5059 : _5080;
                        }
                        if (_6079 <= 0.0)
                        {
                            _6105 = 1.0;
                            break;
                        }
                        float2 _5118 = float2(dot(_5053, _851[_6081]), dot(_5053, _860[_6081])) / float2(_6079 * _173._m24.z);
                        float _5125 = _173._m28[_5014].z + (_173._m28[_5014].w / _6079);
                        if (_5125 > 1.0)
                        {
                            _6105 = 1.0;
                            break;
                        }
                        float2 _5143 = _173._m28[_5014].xy + (float2(float(spvSMod(_6081, 3)), float(_6081 / 3)) * _173._m24.xy);
                        float2 _5383 = _173._m22.xy * 0.5;
                        float2 _5388 = _5143 + (float2(0.5 + (0.5 * _5118.x), 0.5 - (0.5 * _5118.y)) * _173._m24.xy);
                        float4 _5401 = float4(_5143 + _5383, (_5143 + _173._m24.xy) - _5383);
                        float _6093;
                        do
                        {
                            int _5427 = int(_173._m22.z);
                            if (_5427 <= 0)
                            {
                                _6093 = spvDepthCast(_193).sample_compare(_193Smplr, float3(fast::clamp(_5388, _5401.xy, _5401.zw), _5125).xy, _5125);
                                break;
                            }
                            float2 _5450 = (_5388 / _173._m22.xy) + float2(0.5);
                            float2 _5451 = floor(_5450);
                            float2 _5456 = _5450 - _5451;
                            float2 _5459 = _5451 - float2(0.5);
                            bool _5463 = _5427 == 1;
                            if (_5463)
                            {
                                float2 _5466 = _5456 * 2.0;
                                _5411[0] = float2(3.0) - _5466;
                                _5411[1] = float2(1.0) + _5466;
                                _5412[0] = ((float2(2.0) - _5456) / _5411[0]) - float2(1.0);
                                _5412[1] = (_5456 / _5411[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _5493 = _5456 * 3.0;
                                _5411[0] = float2(4.0) - _5493;
                                _5411[1] = float2(7.0);
                                _5411[2] = float2(1.0) + _5493;
                                _5412[0] = ((float2(3.0) - (_5456 * 2.0)) / _5411[0]) - float2(2.0);
                                _5412[1] = (float2(3.0) + _5456) / _5411[1];
                                _5412[2] = (_5456 / _5411[2]) + float2(2.0);
                            }
                            int _6461 = _5463 ? 2 : 3;
                            int _6083;
                            float _6086;
                            _6086 = 0.0;
                            _6083 = 0;
                            float _6092;
                            for (; _6083 < _6461; _6086 = _6092, _6083++)
                            {
                                _6092 = _6086;
                                for (int _6089 = 0; _6089 < _6461; )
                                {
                                    _6092 += ((_5411[_6089].x * _5411[_6083].y) * spvDepthCast(_193).sample_compare(_193Smplr, float3(fast::clamp(_173._m22.xy * (_5459 + float2(_5412[_6089].x, _5412[_6083].y)), _5401.xy, _5401.zw), _5125).xy, _5125));
                                    _6089++;
                                    continue;
                                }
                            }
                            _6093 = _6086 * (_5463 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _6105 = _6093;
                        break;
                    } while(false);
                    _6147 = _4874 * _6105;
                }
                else
                {
                    _6147 = _4874;
                }
                float3 _2251 = fast::normalize(_4843 + _1840);
                float _2256 = fast::clamp(dot(_6021, _4843), 0.0, 1.0);
                float _2261 = fast::clamp(dot(_6021, _2251), 0.0, 1.0);
                float3 _5598 = _2075 + (_4101 * powr(1.0 - fast::clamp(dot(_1840, _2251), 0.0, 1.0), 5.0));
                float _5612 = ((_2261 * _2261) * _4116) + 1.0;
                _2299 = _6149 + (((((float3(1.0) - _5598) * _2068) + ((_5598 * ((_4111 / ((3.1415927410125732421875 * _5612) * _5612)) * (0.5 / fast::max((_2256 * _4142) + (_2080 * sqrt(((_2256 * _2256) * _4138) + _4111)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875)) * _2256) * _6147);
            }
            _6194 = _6149;
        }
        else
        {
            _6194 = _2199;
        }
        _6191 = _6194;
    }
    out.m_2337 = float4(mix(mix(_6191, _6019, float3(_1620._m1.y)) + (_1620._m5.xyz * _2311.sample(_1210, _1639).xyz), _173._m7.xyz, float3(1.0 - exp((-length(_1839)) * _173._m7.w))), in.m_1648.w);
    float2 _6287;
    do
    {
        if (in.m_2353.w <= 0.0)
        {
            _6287 = float2(0.0);
            break;
        }
        _6287 = ((in.m_2353.xy / float2(in.m_2353.w)) - (in.m_2352.xy / float2(in.m_2352.w))) * float2(0.5, -0.5);
        break;
    } while(false);
    out.m_2351 = _6287;
    return out;
}

