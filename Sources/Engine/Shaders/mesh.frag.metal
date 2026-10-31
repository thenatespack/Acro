// Generated from mesh.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: bc2c235c60c1619c
// glsl-fnv1a64: 8ca1a5e24f97303a

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
    float4 m_2324 [[color(0)]];
    float2 m_2338 [[color(1)]];
};

struct fragment_main_in
{
    float3 m_1444 [[user(locn0)]];
    float3 m_1692 [[user(locn1)]];
    float2 m_1625 [[user(locn2)]];
    float4 m_1648 [[user(locn3)]];
    float4 m_1840 [[user(locn5)]];
    float4 m_2339 [[user(locn6)]];
    float4 m_2340 [[user(locn7)]];
    float4 m_1701 [[user(locn8)]];
};

fragment fragment_main_out fragment_main(fragment_main_in in [[stage_in]], constant _1618& _1620 [[buffer(2)]], constant _1434& _1436 [[buffer(3)]], constant _1470& _1472 [[buffer(4)]], constant _1478& _1480 [[buffer(5)]], constant _1575& _1577 [[buffer(6)]], constant _1597& _1599 [[buffer(7)]], constant _171& _173 [[buffer(15)]], texture2d<float> _193 [[texture(0)]], texture2d<float> _1641 [[texture(1)]], texture2d<float> _2026 [[texture(2)]], texture2d<float> _1730 [[texture(3)]], texture2d<float> _1873 [[texture(4)]], texture2d<float> _2298 [[texture(5)]], texture2d<float> _1208 [[texture(6)]], texture2d<float> _1314 [[texture(7)]], sampler _193Smplr [[sampler(0)]], sampler _1210 [[sampler(1)]], sampler _1316 [[sampler(7)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])
{
    fragment_main_out out = {};
    float2 _1639 = float2(dot(_1620._m2.xy, in.m_1625) + _1620._m2.z, dot(_1620._m3.xy, in.m_1625) + _1620._m3.z);
    float4 _1646 = _1641.sample(_1210, _1639);
    float3 _1657 = (in.m_1648.xyz * _1620._m0.xyz) * _1646.xyz;
    float3 _5982;
    if (_1620._m1.x > 0.5)
    {
        float2 _1678 = floor(in.m_1444.xz * float2(0.5));
        _5982 = _1657 * ((mod(abs(_1678.x + _1678.y), 2.0) < 0.5) ? 1.0 : 0.75);
    }
    else
    {
        _5982 = _1657;
    }
    float3 _1694 = fast::normalize(in.m_1692);
    float3 _5896;
    if (_1620._m6.y > 0.5)
    {
        float3 _1710 = in.m_1701.xyz - (_1694 * dot(_1694, in.m_1701.xyz));
        float3 _5897;
        if (dot(_1710, _1710) > 9.9999999600419720025001879548654e-13)
        {
            float3 _1719 = fast::normalize(_1710);
            float4 _1735 = _1730.sample(_1210, _1639);
            float3 _5890;
            if (_1620._m6.z > 0.5)
            {
                float2 _5889;
                if (_1620._m6.z > 1.5)
                {
                    _5889 = _1735.xw;
                }
                else
                {
                    _5889 = _1735.xy;
                }
                float2 _1757 = (_5889 * 2.0) - float2(1.0);
                _5890 = float3(_1757, sqrt(fast::clamp(1.0 - dot(_1757, _1757), 0.0, 1.0)));
            }
            else
            {
                _5890 = (_1735.xyz * 2.0) - float3(1.0);
            }
            float2 _1779 = _5890.xy * _1620._m4.z;
            _5897 = fast::normalize(((_1719 * _1779.x) + ((cross(_1694, _1719) * ((in.m_1701.w < 0.0) ? (-1.0) : 1.0)) * _1779.y)) + (_1694 * _5890.z));
        }
        else
        {
            _5897 = _1694;
        }
        _5896 = _5897;
    }
    else
    {
        _5896 = _1694;
    }
    bool _1803 = _1620._m5.w > 0.5;
    bool _1811;
    if (_1803)
    {
        _1811 = !gl_FrontFacing;
    }
    else
    {
        _1811 = _1803;
    }
    float3 _6007;
    if (_1811)
    {
        _6007 = -_5896;
    }
    else
    {
        _6007 = _5896;
    }
    float3 _1820 = fast::normalize(_173._m4.xyz);
    float3 _1826 = _173._m6.xyz - in.m_1444;
    float3 _1827 = fast::normalize(_1826);
    float3 _1832 = fast::normalize(_1820 + _1827);
    float3 _1838 = _1694 * (gl_FrontFacing ? 1.0 : (-1.0));
    bool _1843 = in.m_1840.x > 0.5;
    float3 _6005;
    float _6030;
    if ((_173._m5.w > 0.5) && _1843)
    {
        float _5953;
        float3 _5954;
        do
        {
            int _2393 = int(_173._m21.x);
            float _2401 = dot(_173._m20.xyz, in.m_1444) + _173._m20.w;
            int _5898;
            _5898 = 0;
            for (;;)
            {
                bool _2407 = _5898 < (_2393 - 1);
                bool _2415;
                if (_2407)
                {
                    _2415 = _2401 > _173._m16[_5898];
                }
                else
                {
                    _2415 = _2407;
                }
                if (_2415)
                {
                    _5898++;
                    continue;
                }
                else
                {
                    break;
                }
            }
            if (_2401 > _173._m16[_5898])
            {
                _5954 = float3(1.0);
                _5953 = 1.0;
                break;
            }
            float _5911;
            do
            {
                float4 _2517 = _173._m14[_5898] * float4(in.m_1444 + (_1838 * _173._m18[_5898]), 1.0);
                float _2520 = _2517.x;
                bool _2521 = _2520 < 0.0;
                bool _2528;
                if (!_2521)
                {
                    _2528 = _2520 > 1.0;
                }
                else
                {
                    _2528 = _2521;
                }
                bool _2535;
                if (!_2528)
                {
                    _2535 = _2517.y < 0.0;
                }
                else
                {
                    _2535 = _2528;
                }
                bool _2542;
                if (!_2535)
                {
                    _2542 = _2517.y > 1.0;
                }
                else
                {
                    _2542 = _2535;
                }
                if (_2542)
                {
                    _5911 = 1.0;
                    break;
                }
                float2 _2555 = float2(float(_5898 & 1), float(_5898 >> 1)) * _173._m23.xy;
                float _2562 = fast::min(_2517.z, 1.0) - _173._m19[_5898];
                float2 _2581 = _173._m22.xy * 0.5;
                float2 _2586 = _2555 + (_2517.xy * _173._m23.xy);
                float4 _2599 = float4(_2555 + _2581, (_2555 + _173._m23.xy) - _2581);
                float _5910;
                do
                {
                    int _2625 = int(_173._m22.z);
                    if (_2625 <= 0)
                    {
                        _5910 = spvDepthCast(_193).sample_compare(_193Smplr, float3(fast::clamp(_2586, _2599.xy, _2599.zw), _2562).xy, _2562);
                        break;
                    }
                    float2 _2648 = (_2586 / _173._m22.xy) + float2(0.5);
                    float2 _2649 = floor(_2648);
                    float2 _2654 = _2648 - _2649;
                    float2 _2657 = _2649 - float2(0.5);
                    bool _2661 = _2625 == 1;
                    spvUnsafeArray<float2, 3> _2609;
                    spvUnsafeArray<float2, 3> _2610;
                    if (_2661)
                    {
                        float2 _2664 = _2654 * 2.0;
                        _2609[0] = float2(3.0) - _2664;
                        _2609[1] = float2(1.0) + _2664;
                        _2610[0] = ((float2(2.0) - _2654) / _2609[0]) - float2(1.0);
                        _2610[1] = (_2654 / _2609[1]) + float2(1.0);
                    }
                    else
                    {
                        float2 _2691 = _2654 * 3.0;
                        _2609[0] = float2(4.0) - _2691;
                        _2609[1] = float2(7.0);
                        _2609[2] = float2(1.0) + _2691;
                        _2610[0] = ((float2(3.0) - (_2654 * 2.0)) / _2609[0]) - float2(2.0);
                        _2610[1] = (float2(3.0) + _2654) / _2609[1];
                        _2610[2] = (_2654 / _2609[2]) + float2(2.0);
                    }
                    int _6351 = _2661 ? 2 : 3;
                    int _5900;
                    float _5903;
                    _5903 = 0.0;
                    _5900 = 0;
                    float _5909;
                    for (; _5900 < _6351; _5903 = _5909, _5900++)
                    {
                        _5909 = _5903;
                        for (int _5906 = 0; _5906 < _6351; )
                        {
                            _5909 += ((_2609[_5906].x * _2609[_5900].y) * spvDepthCast(_193).sample_compare(_193Smplr, float3(fast::clamp(_173._m22.xy * (_2657 + float2(_2610[_5906].x, _2610[_5900].y)), _2599.xy, _2599.zw), _2562).xy, _2562));
                            _5906++;
                            continue;
                        }
                    }
                    _5910 = _5903 * (_2661 ? 0.0625 : 0.0069444444961845874786376953125);
                    break;
                } while(false);
                _5911 = _5910;
                break;
            } while(false);
            float3 _5948;
            float _5951;
            if (_2401 > _173._m17[_5898])
            {
                float _2455 = (_2401 - _173._m17[_5898]) / (_173._m16[_5898] - _173._m17[_5898]);
                int _2457 = _5898 + 1;
                float3 _5949;
                float _5952;
                if (_2457 < _2393)
                {
                    float _5931;
                    do
                    {
                        float4 _2804 = _173._m14[_2457] * float4(in.m_1444 + (_1838 * _173._m18[_2457]), 1.0);
                        float _2807 = _2804.x;
                        bool _2808 = _2807 < 0.0;
                        bool _2815;
                        if (!_2808)
                        {
                            _2815 = _2807 > 1.0;
                        }
                        else
                        {
                            _2815 = _2808;
                        }
                        bool _2822;
                        if (!_2815)
                        {
                            _2822 = _2804.y < 0.0;
                        }
                        else
                        {
                            _2822 = _2815;
                        }
                        bool _2829;
                        if (!_2822)
                        {
                            _2829 = _2804.y > 1.0;
                        }
                        else
                        {
                            _2829 = _2822;
                        }
                        if (_2829)
                        {
                            _5931 = 1.0;
                            break;
                        }
                        float2 _2842 = float2(float(_2457 & 1), float(_2457 >> 1)) * _173._m23.xy;
                        float _2849 = fast::min(_2804.z, 1.0) - _173._m19[_2457];
                        float2 _2868 = _173._m22.xy * 0.5;
                        float2 _2873 = _2842 + (_2804.xy * _173._m23.xy);
                        float4 _2886 = float4(_2842 + _2868, (_2842 + _173._m23.xy) - _2868);
                        float _5930;
                        do
                        {
                            int _2912 = int(_173._m22.z);
                            if (_2912 <= 0)
                            {
                                _5930 = spvDepthCast(_193).sample_compare(_193Smplr, float3(fast::clamp(_2873, _2886.xy, _2886.zw), _2849).xy, _2849);
                                break;
                            }
                            float2 _2935 = (_2873 / _173._m22.xy) + float2(0.5);
                            float2 _2936 = floor(_2935);
                            float2 _2941 = _2935 - _2936;
                            float2 _2944 = _2936 - float2(0.5);
                            bool _2948 = _2912 == 1;
                            spvUnsafeArray<float2, 3> _2896;
                            spvUnsafeArray<float2, 3> _2897;
                            if (_2948)
                            {
                                float2 _2951 = _2941 * 2.0;
                                _2896[0] = float2(3.0) - _2951;
                                _2896[1] = float2(1.0) + _2951;
                                _2897[0] = ((float2(2.0) - _2941) / _2896[0]) - float2(1.0);
                                _2897[1] = (_2941 / _2896[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _2978 = _2941 * 3.0;
                                _2896[0] = float2(4.0) - _2978;
                                _2896[1] = float2(7.0);
                                _2896[2] = float2(1.0) + _2978;
                                _2897[0] = ((float2(3.0) - (_2941 * 2.0)) / _2896[0]) - float2(2.0);
                                _2897[1] = (float2(3.0) + _2941) / _2896[1];
                                _2897[2] = (_2941 / _2896[2]) + float2(2.0);
                            }
                            int _6353 = _2948 ? 2 : 3;
                            int _5920;
                            float _5923;
                            _5923 = 0.0;
                            _5920 = 0;
                            float _5929;
                            for (; _5920 < _6353; _5923 = _5929, _5920++)
                            {
                                _5929 = _5923;
                                for (int _5926 = 0; _5926 < _6353; )
                                {
                                    _5929 += ((_2896[_5926].x * _2896[_5920].y) * spvDepthCast(_193).sample_compare(_193Smplr, float3(fast::clamp(_173._m22.xy * (_2944 + float2(_2897[_5926].x, _2897[_5920].y)), _2886.xy, _2886.zw), _2849).xy, _2849));
                                    _5926++;
                                    continue;
                                }
                            }
                            _5930 = _5923 * (_2948 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _5931 = _5930;
                        break;
                    } while(false);
                    _5952 = mix(_5911, _5931, _2455);
                    _5949 = mix(_547[_5898], _547[_2457], float3(_2455));
                }
                else
                {
                    _5952 = mix(_5911, 1.0, _2455);
                    _5949 = _547[_5898];
                }
                _5951 = _5952;
                _5948 = _5949;
            }
            else
            {
                _5951 = _5911;
                _5948 = _547[_5898];
            }
            _5954 = select(float3(1.0), _5948, bool3(_173._m22.w > 0.5));
            _5953 = _5951;
            break;
        } while(false);
        _6030 = _5953;
        _6005 = _5982 * _5954;
    }
    else
    {
        _6030 = 1.0;
        _6005 = _5982;
    }
    float3 _1869 = _173._m5.xyz * _173._m4.w;
    float4 _1878 = _1873.sample(_1210, _1639);
    float _1882 = 1.0 + (_1620._m4.w * (_1878.x - 1.0));
    float3 _6177;
    if (!_1803)
    {
        float _1890 = dot(_6007, _1820);
        float3 _6171;
        if (_173._m29.x > 0.5)
        {
            float _3129 = (_173._m29.z * _6007.x) - (_173._m29.w * _6007.z);
            float _3142 = (_173._m29.w * _6007.x) + (_173._m29.z * _6007.z);
            float _3160 = 1.09254801273345947265625 * _3129;
            spvUnsafeArray<float, 9> _5704 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _6007.y, 0.48860299587249755859375 * _3142, 0.48860299587249755859375 * _3129, _3160 * _6007.y, (1.09254801273345947265625 * _6007.y) * _3142, 0.3153919875621795654296875 * (((3.0 * _3142) * _3142) - 1.0), _3160 * _3142, 0.546274006366729736328125 * ((_3129 * _3129) - (_6007.y * _6007.y)) });
            spvUnsafeArray<float, 9> _3074 = _5704;
            float3 _6170;
            _6170 = float3(0.0);
            for (int _6169 = 0; _6169 < 9; )
            {
                _6170 += (_1208.read(uint2((int2(496, 256) + int2(_6169, 0))), 0).xyz * _3074[_6169]);
                _6169++;
                continue;
            }
            _6171 = fast::max(_6170, float3(0.0)) * _173._m29.y;
        }
        else
        {
            _6171 = mix(_173._m9.xyz, _173._m8.xyz, float3((_6007.y * 0.5) + 0.5)) * _173._m8.w;
        }
        float3 _1940 = (_6005 * ((_6171 * _1882) + ((_1869 * fast::max(_1890, 0.0)) * _6030))) + ((_1869 * ((powr(fast::max(dot(_6007, _1832), 0.0), _1620._m1.w) * _1620._m1.z) * step(0.0, _1890))) * _6030);
        float3 _6178;
        if (_173._m13.w > 0.5)
        {
            float2 _3245 = fast::clamp(floor(gl_FragCoord.xy * _173._m12.xy), float2(0.0), _173._m13.xy - float2(1.0));
            uint _3273 = uint((((fast::clamp(floor((log2(fast::max(dot(_173._m11.xyz, in.m_1444) + _173._m11.w, 9.9999999747524270787835121154785e-07)) * _173._m12.z) + _173._m12.w), 0.0, _173._m13.z - 1.0) * _173._m13.y) + _3245.y) * _173._m13.x) + _3245.x);
            uint _3275 = _3273 >> uint(2);
            uint _3277 = _3273 & 3u;
            uint _3281 = _1577._m0[_3275][_3277] & 65535u;
            uint _3283 = _1577._m0[_3275][_3277] >> uint(16);
            float3 _6179;
            _6179 = _1940;
            float3 _2021;
            spvUnsafeArray<float2, 3> _3691;
            spvUnsafeArray<float2, 3> _3692;
            spvUnsafeArray<float2, 3> _3904;
            spvUnsafeArray<float2, 3> _3905;
            for (uint _6176 = _3281; _6176 < (_3281 + _3283); _6179 = _2021, _6176++)
            {
                uint _3289 = _6176 / 3u;
                uint _3302 = (_1599._m0[_3289 >> uint(2)][_3289 & 3u] >> ((_6176 - (_3289 * 3u)) * 10u)) & 1023u;
                float3 _3319 = _1436._m0[_3302].xyz - in.m_1444;
                float _3322 = dot(_3319, _3319);
                float _3326 = _3322 * _1436._m0[_3302].w;
                float _3331 = fast::clamp(1.0 - (_3326 * _3326), 0.0, 1.0);
                float3 _3336 = _3319 * rsqrt(fast::max(_3322, 9.9999999392252902907785028219223e-09));
                float _3354 = fast::clamp((dot(-_3336, _1480._m0[_3302].xyz) * _1472._m0[_3302].w) + _1480._m0[_3302].w, 0.0, 1.0);
                float3 _3367 = _1472._m0[_3302].xyz * ((((_3331 * _3331) * _3354) * _3354) / fast::max(_3322, 9.9999997473787516355514526367188e-05));
                float3 _6292;
                if (_1843)
                {
                    float _6238;
                    do
                    {
                        uint _3403 = uint(_173._m21.z);
                        if (_3302 < _3403)
                        {
                            float _3425 = _173._m26[_3302].z * fast::max((_173._m15[_3302] * float4(in.m_1444, 1.0)).w, 0.0);
                            float4 _3449 = _173._m15[_3302] * float4((in.m_1444 + (_1838 * (_3425 * _173._m25.x))) + (_3336 * (_3425 * _173._m25.y)), 1.0);
                            float _3451 = _3449.w;
                            if (_3451 <= 0.0)
                            {
                                _6238 = 1.0;
                                break;
                            }
                            float3 _3460 = _3449.xyz / float3(_3451);
                            float _3462 = _3460.x;
                            bool _3463 = _3462 < 0.0;
                            bool _3470;
                            if (!_3463)
                            {
                                _3470 = _3462 > 1.0;
                            }
                            else
                            {
                                _3470 = _3463;
                            }
                            bool _3477;
                            if (!_3470)
                            {
                                _3477 = _3460.y < 0.0;
                            }
                            else
                            {
                                _3477 = _3470;
                            }
                            bool _3484;
                            if (!_3477)
                            {
                                _3484 = _3460.y > 1.0;
                            }
                            else
                            {
                                _3484 = _3477;
                            }
                            bool _3491;
                            if (!_3484)
                            {
                                _3491 = _3460.z > 1.0;
                            }
                            else
                            {
                                _3491 = _3484;
                            }
                            if (_3491)
                            {
                                _6238 = 1.0;
                                break;
                            }
                            float _3497 = _3460.z;
                            float2 _3663 = _173._m22.xy * 0.5;
                            float2 _3668 = _173._m26[_3302].xy + (_3460.xy * _173._m23.zw);
                            float4 _3681 = float4(_173._m26[_3302].xy + _3663, (_173._m26[_3302].xy + _173._m23.zw) - _3663);
                            float _6237;
                            do
                            {
                                int _3707 = int(_173._m22.z);
                                if (_3707 <= 0)
                                {
                                    float2 _3717 = fast::clamp(_3668, _3681.xy, _3681.zw);
                                    _6237 = spvDepthCast(_193).sample_compare(_193Smplr, float3(_3717, _3497).xy, _3497);
                                    break;
                                }
                                float2 _3730 = (_3668 / _173._m22.xy) + float2(0.5);
                                float2 _3731 = floor(_3730);
                                float2 _3736 = _3730 - _3731;
                                float2 _3739 = _3731 - float2(0.5);
                                bool _3743 = _3707 == 1;
                                if (_3743)
                                {
                                    float2 _3746 = _3736 * 2.0;
                                    _3691[0] = float2(3.0) - _3746;
                                    _3691[1] = float2(1.0) + _3746;
                                    _3692[0] = ((float2(2.0) - _3736) / _3691[0]) - float2(1.0);
                                    _3692[1] = (_3736 / _3691[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _3773 = _3736 * 3.0;
                                    _3691[0] = float2(4.0) - _3773;
                                    _3691[1] = float2(7.0);
                                    _3691[2] = float2(1.0) + _3773;
                                    _3692[0] = ((float2(3.0) - (_3736 * 2.0)) / _3691[0]) - float2(2.0);
                                    _3692[1] = (float2(3.0) + _3736) / _3691[1];
                                    _3692[2] = (_3736 / _3691[2]) + float2(2.0);
                                }
                                int _6358 = _3743 ? 2 : 3;
                                int _6227;
                                float _6230;
                                _6230 = 0.0;
                                _6227 = 0;
                                float _6236;
                                for (; _6227 < _6358; _6230 = _6236, _6227++)
                                {
                                    _6236 = _6230;
                                    for (int _6233 = 0; _6233 < _6358; )
                                    {
                                        _6236 += ((_3691[_6233].x * _3691[_6227].y) * spvDepthCast(_193).sample_compare(_193Smplr, float3(fast::clamp(_173._m22.xy * (_3739 + float2(_3692[_6233].x, _3692[_6227].y)), _3681.xy, _3681.zw), _3497).xy, _3497));
                                        _6233++;
                                        continue;
                                    }
                                }
                                _6237 = _6230 * (_3743 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _6238 = _6237;
                            break;
                        }
                        uint _3507 = _3302 - _3403;
                        if (_3507 >= uint(_173._m21.w))
                        {
                            _6238 = 1.0;
                            break;
                        }
                        float _3528 = _173._m27[_3507].w * length(in.m_1444 - _173._m27[_3507].xyz);
                        float3 _3546 = ((in.m_1444 + (_1838 * (_3528 * _173._m25.x))) + (_3336 * (_3528 * _173._m25.y))) - _173._m27[_3507].xyz;
                        float3 _3548 = abs(_3546);
                        float _3550 = _3548.x;
                        float _3552 = _3548.y;
                        bool _3553 = _3550 >= _3552;
                        bool _3561;
                        if (_3553)
                        {
                            _3561 = _3550 >= _3548.z;
                        }
                        else
                        {
                            _3561 = _3553;
                        }
                        float _6212;
                        int _6214;
                        if (_3561)
                        {
                            _6214 = (_3546.x > 0.0) ? 0 : 1;
                            _6212 = _3550;
                        }
                        else
                        {
                            float _3573 = _3548.z;
                            bool _3574 = _3552 >= _3573;
                            int _6215;
                            if (_3574)
                            {
                                _6215 = (_3546.y > 0.0) ? 2 : 3;
                            }
                            else
                            {
                                _6215 = (_3546.z > 0.0) ? 4 : 5;
                            }
                            _6214 = _6215;
                            _6212 = _3574 ? _3552 : _3573;
                        }
                        if (_6212 <= 0.0)
                        {
                            _6238 = 1.0;
                            break;
                        }
                        float2 _3611 = float2(dot(_3546, _851[_6214]), dot(_3546, _860[_6214])) / float2(_6212 * _173._m24.z);
                        float _3618 = _173._m28[_3507].z + (_173._m28[_3507].w / _6212);
                        if (_3618 > 1.0)
                        {
                            _6238 = 1.0;
                            break;
                        }
                        float2 _3636 = _173._m28[_3507].xy + (float2(float(spvSMod(_6214, 3)), float(_6214 / 3)) * _173._m24.xy);
                        float2 _3876 = _173._m22.xy * 0.5;
                        float2 _3881 = _3636 + (float2(0.5 + (0.5 * _3611.x), 0.5 - (0.5 * _3611.y)) * _173._m24.xy);
                        float4 _3894 = float4(_3636 + _3876, (_3636 + _173._m24.xy) - _3876);
                        float _6226;
                        do
                        {
                            int _3920 = int(_173._m22.z);
                            if (_3920 <= 0)
                            {
                                _6226 = spvDepthCast(_193).sample_compare(_193Smplr, float3(fast::clamp(_3881, _3894.xy, _3894.zw), _3618).xy, _3618);
                                break;
                            }
                            float2 _3943 = (_3881 / _173._m22.xy) + float2(0.5);
                            float2 _3944 = floor(_3943);
                            float2 _3949 = _3943 - _3944;
                            float2 _3952 = _3944 - float2(0.5);
                            bool _3956 = _3920 == 1;
                            if (_3956)
                            {
                                float2 _3959 = _3949 * 2.0;
                                _3904[0] = float2(3.0) - _3959;
                                _3904[1] = float2(1.0) + _3959;
                                _3905[0] = ((float2(2.0) - _3949) / _3904[0]) - float2(1.0);
                                _3905[1] = (_3949 / _3904[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _3986 = _3949 * 3.0;
                                _3904[0] = float2(4.0) - _3986;
                                _3904[1] = float2(7.0);
                                _3904[2] = float2(1.0) + _3986;
                                _3905[0] = ((float2(3.0) - (_3949 * 2.0)) / _3904[0]) - float2(2.0);
                                _3905[1] = (float2(3.0) + _3949) / _3904[1];
                                _3905[2] = (_3949 / _3904[2]) + float2(2.0);
                            }
                            int _6361 = _3956 ? 2 : 3;
                            int _6216;
                            float _6219;
                            _6219 = 0.0;
                            _6216 = 0;
                            float _6225;
                            for (; _6216 < _6361; _6219 = _6225, _6216++)
                            {
                                _6225 = _6219;
                                for (int _6222 = 0; _6222 < _6361; )
                                {
                                    _6225 += ((_3904[_6222].x * _3904[_6216].y) * spvDepthCast(_193).sample_compare(_193Smplr, float3(fast::clamp(_173._m22.xy * (_3952 + float2(_3905[_6222].x, _3905[_6216].y)), _3894.xy, _3894.zw), _3618).xy, _3618));
                                    _6222++;
                                    continue;
                                }
                            }
                            _6226 = _6219 * (_3956 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _6238 = _6226;
                        break;
                    } while(false);
                    _6292 = _3367 * _6238;
                }
                else
                {
                    _6292 = _3367;
                }
                float _1992 = dot(_6007, _3336);
                _2021 = _6179 + (((_6005 * fast::max(_1992, 0.0)) * _6292) + (_6292 * ((powr(fast::max(dot(_6007, fast::normalize(_3336 + _1827)), 0.0), _1620._m1.w) * _1620._m1.z) * step(0.0, _1992))));
            }
            _6178 = _6179;
        }
        else
        {
            _6178 = _1940;
        }
        _6177 = _6178;
    }
    else
    {
        float4 _2031 = _2026.sample(_1210, _1639);
        float _2038 = fast::clamp(_1620._m4.x * _2031.z, 0.0, 1.0);
        float _2046 = fast::clamp(_1620._m4.y * _2031.y, 0.04500000178813934326171875, 1.0);
        float _2050 = _2046 * _2046;
        float3 _2055 = _6005 * (1.0 - _2038);
        float3 _2062 = mix(float3(0.039999999105930328369140625), _6005, float3(_2038));
        float _2067 = fast::max(dot(_6007, _1827), 9.9999997473787516355514526367188e-05);
        float _2072 = fast::clamp(dot(_6007, _1820), 0.0, 1.0);
        float _2077 = fast::clamp(dot(_6007, _1832), 0.0, 1.0);
        float3 _4088 = float3(1.0) - _2062;
        float3 _4091 = _2062 + (_4088 * powr(1.0 - fast::clamp(dot(_1827, _1832), 0.0, 1.0), 5.0));
        float _4098 = _2050 * _2050;
        float _4103 = _4098 - 1.0;
        float _4105 = ((_2077 * _2077) * _4103) + 1.0;
        float _4125 = 1.0 - _4098;
        float _4129 = sqrt(((_2067 * _2067) * _4125) + _4098);
        float2 _6048;
        float3 _6056;
        float3 _6063;
        if (_173._m29.x > 0.5)
        {
            float4 _4162 = _1314.sample(_1316, (((float2(_2067, _2046) * 31.0) + float2(0.5)) * float2(0.03125)));
            float _4221 = (_173._m29.z * _6007.x) - (_173._m29.w * _6007.z);
            float _4234 = (_173._m29.w * _6007.x) + (_173._m29.z * _6007.z);
            float _4252 = 1.09254801273345947265625 * _4221;
            spvUnsafeArray<float, 9> _5685 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _6007.y, 0.48860299587249755859375 * _4234, 0.48860299587249755859375 * _4221, _4252 * _6007.y, (1.09254801273345947265625 * _6007.y) * _4234, 0.3153919875621795654296875 * (((3.0 * _4234) * _4234) - 1.0), _4252 * _4234, 0.546274006366729736328125 * ((_4221 * _4221) - (_6007.y * _6007.y)) });
            spvUnsafeArray<float, 9> _4166 = _5685;
            float3 _6032;
            _6032 = float3(0.0);
            for (int _6031 = 0; _6031 < 9; )
            {
                _6032 += (_1208.read(uint2((int2(496, 256) + int2(_6031, 0))), 0).xyz * _4166[_6031]);
                _6031++;
                continue;
            }
            float3 _2138 = reflect(-_1827, _6007);
            float _4347 = _2138.x;
            float _4352 = _2138.z;
            float2 _4384 = float2((precise::atan2((_173._m29.z * _4347) - (_173._m29.w * _4352), -((_173._m29.w * _4347) + (_173._m29.z * _4352))) * 0.15915493667125701904296875) + 0.5, acos(fast::clamp(_2138.y, -1.0, 1.0)) * 0.3183098733425140380859375);
            float _4316 = _2046 * 5.0;
            int _4319 = min(int(_4316), 4);
            float2 _4405 = (_4384 * float2(_1270[_4319].zw)) - float2(0.5);
            float2 _4407 = floor(_4405);
            float2 _4410 = _4405 - _4407;
            int _4413 = int(_4407.x);
            int _4416 = int(_4407.y);
            int _6034;
            if (_4413 < 0)
            {
                _6034 = _4413 + _1270[_4319].z;
            }
            else
            {
                _6034 = _4413;
            }
            int _6035;
            if (_6034 >= _1270[_4319].z)
            {
                _6035 = _6034 - _1270[_4319].z;
            }
            else
            {
                _6035 = _6034;
            }
            int _4436 = _6035 + 1;
            int _6362 = (_4436 == _1270[_4319].z) ? 0 : _4436;
            int _4451 = min((_4416 + 1), (_1270[_4319].w - 1));
            int _4453 = max(_4416, 0);
            float3 _4506 = float3(_4410.x);
            int _4326 = _4319 + 1;
            float2 _4538 = (_4384 * float2(_1270[_4326].zw)) - float2(0.5);
            float2 _4540 = floor(_4538);
            float2 _4543 = _4538 - _4540;
            int _4546 = int(_4540.x);
            int _4549 = int(_4540.y);
            int _6041;
            if (_4546 < 0)
            {
                _6041 = _4546 + _1270[_4326].z;
            }
            else
            {
                _6041 = _4546;
            }
            int _6042;
            if (_6041 >= _1270[_4326].z)
            {
                _6042 = _6041 - _1270[_4326].z;
            }
            else
            {
                _6042 = _6041;
            }
            int _4569 = _6042 + 1;
            int _6363 = (_4569 == _1270[_4326].z) ? 0 : _4569;
            int _4584 = min((_4549 + 1), (_1270[_4326].w - 1));
            int _4586 = max(_4549, 0);
            float3 _4639 = float3(_4543.x);
            float3 _4341 = mix(mix(mix(_1208.read(uint2((_1270[_4319].xy + int2(_6035, _4453))), 0).xyz, _1208.read(uint2((_1270[_4319].xy + int2(_6362, _4453))), 0).xyz, _4506), mix(_1208.read(uint2((_1270[_4319].xy + int2(_6035, _4451))), 0).xyz, _1208.read(uint2((_1270[_4319].xy + int2(_6362, _4451))), 0).xyz, _4506), float3(_4410.y)), mix(mix(_1208.read(uint2((_1270[_4326].xy + int2(_6042, _4586))), 0).xyz, _1208.read(uint2((_1270[_4326].xy + int2(_6363, _4586))), 0).xyz, _4639), mix(_1208.read(uint2((_1270[_4326].xy + int2(_6042, _4584))), 0).xyz, _1208.read(uint2((_1270[_4326].xy + int2(_6363, _4584))), 0).xyz, _4639), float3(_4543.y)), float3(_4316 - float(_4319))) * _173._m29.y;
            _6063 = _4341;
            _6056 = fast::max(_6032, float3(0.0)) * _173._m29.y;
            _6048 = _4162.xy;
        }
        else
        {
            float4 _4657 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * _2046) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);
            float _4659 = _4657.x;
            float3 _4694 = mix(_173._m9.xyz, _173._m8.xyz, float3((_6007.y * 0.5) + 0.5)) * _173._m8.w;
            _6063 = mix(mix(_173._m9.xyz, _173._m8.xyz, float3((reflect(-_1827, _6007).y * 0.5) + 0.5)) * _173._m8.w, _4694, float3(_2046));
            _6056 = _4694;
            _6048 = (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_4659 * _4659, exp2((-9.27999973297119140625) * _2067)) * _4659) + _4657.y)) + _4657.zw;
        }
        float3 _2170 = (_2062 * _6048.x) + float3(_6048.y);
        float3 _2186 = ((((((float3(1.0) - _4091) * _2055) + ((_4091 * ((_4098 / ((3.1415927410125732421875 * _4105) * _4105)) * (0.5 / fast::max((_2072 * _4129) + (_2067 * sqrt(((_2072 * _2072) * _4125) + _4098)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875)) * _2072) * _1869) * _6030) + (((((float3(1.0) - _2170) * _2055) * _6056) + (_2170 * _6063)) * _1882);
        float3 _6180;
        if (_173._m13.w > 0.5)
        {
            float2 _4739 = fast::clamp(floor(gl_FragCoord.xy * _173._m12.xy), float2(0.0), _173._m13.xy - float2(1.0));
            uint _4767 = uint((((fast::clamp(floor((log2(fast::max(dot(_173._m11.xyz, in.m_1444) + _173._m11.w, 9.9999999747524270787835121154785e-07)) * _173._m12.z) + _173._m12.w), 0.0, _173._m13.z - 1.0) * _173._m13.y) + _4739.y) * _173._m13.x) + _4739.x);
            uint _4769 = _4767 >> uint(2);
            uint _4771 = _4767 & 3u;
            uint _4775 = _1577._m0[_4769][_4771] & 65535u;
            uint _4777 = _1577._m0[_4769][_4771] >> uint(16);
            float3 _6135;
            _6135 = _2186;
            float3 _2286;
            spvUnsafeArray<float2, 3> _5185;
            spvUnsafeArray<float2, 3> _5186;
            spvUnsafeArray<float2, 3> _5398;
            spvUnsafeArray<float2, 3> _5399;
            for (uint _6064 = _4775; _6064 < (_4775 + _4777); _6135 = _2286, _6064++)
            {
                uint _4783 = _6064 / 3u;
                uint _4796 = (_1599._m0[_4783 >> uint(2)][_4783 & 3u] >> ((_6064 - (_4783 * 3u)) * 10u)) & 1023u;
                float3 _4813 = _1436._m0[_4796].xyz - in.m_1444;
                float _4816 = dot(_4813, _4813);
                float _4820 = _4816 * _1436._m0[_4796].w;
                float _4825 = fast::clamp(1.0 - (_4820 * _4820), 0.0, 1.0);
                float3 _4830 = _4813 * rsqrt(fast::max(_4816, 9.9999999392252902907785028219223e-09));
                float _4848 = fast::clamp((dot(-_4830, _1480._m0[_4796].xyz) * _1472._m0[_4796].w) + _1480._m0[_4796].w, 0.0, 1.0);
                float3 _4861 = _1472._m0[_4796].xyz * ((((_4825 * _4825) * _4848) * _4848) / fast::max(_4816, 9.9999997473787516355514526367188e-05));
                float3 _6133;
                if (_1843)
                {
                    float _6091;
                    do
                    {
                        uint _4897 = uint(_173._m21.z);
                        if (_4796 < _4897)
                        {
                            float _4919 = _173._m26[_4796].z * fast::max((_173._m15[_4796] * float4(in.m_1444, 1.0)).w, 0.0);
                            float4 _4943 = _173._m15[_4796] * float4((in.m_1444 + (_1838 * (_4919 * _173._m25.x))) + (_4830 * (_4919 * _173._m25.y)), 1.0);
                            float _4945 = _4943.w;
                            if (_4945 <= 0.0)
                            {
                                _6091 = 1.0;
                                break;
                            }
                            float3 _4954 = _4943.xyz / float3(_4945);
                            float _4956 = _4954.x;
                            bool _4957 = _4956 < 0.0;
                            bool _4964;
                            if (!_4957)
                            {
                                _4964 = _4956 > 1.0;
                            }
                            else
                            {
                                _4964 = _4957;
                            }
                            bool _4971;
                            if (!_4964)
                            {
                                _4971 = _4954.y < 0.0;
                            }
                            else
                            {
                                _4971 = _4964;
                            }
                            bool _4978;
                            if (!_4971)
                            {
                                _4978 = _4954.y > 1.0;
                            }
                            else
                            {
                                _4978 = _4971;
                            }
                            bool _4985;
                            if (!_4978)
                            {
                                _4985 = _4954.z > 1.0;
                            }
                            else
                            {
                                _4985 = _4978;
                            }
                            if (_4985)
                            {
                                _6091 = 1.0;
                                break;
                            }
                            float _4991 = _4954.z;
                            float2 _5157 = _173._m22.xy * 0.5;
                            float2 _5162 = _173._m26[_4796].xy + (_4954.xy * _173._m23.zw);
                            float4 _5175 = float4(_173._m26[_4796].xy + _5157, (_173._m26[_4796].xy + _173._m23.zw) - _5157);
                            float _6090;
                            do
                            {
                                int _5201 = int(_173._m22.z);
                                if (_5201 <= 0)
                                {
                                    float2 _5211 = fast::clamp(_5162, _5175.xy, _5175.zw);
                                    _6090 = spvDepthCast(_193).sample_compare(_193Smplr, float3(_5211, _4991).xy, _4991);
                                    break;
                                }
                                float2 _5224 = (_5162 / _173._m22.xy) + float2(0.5);
                                float2 _5225 = floor(_5224);
                                float2 _5230 = _5224 - _5225;
                                float2 _5233 = _5225 - float2(0.5);
                                bool _5237 = _5201 == 1;
                                if (_5237)
                                {
                                    float2 _5240 = _5230 * 2.0;
                                    _5185[0] = float2(3.0) - _5240;
                                    _5185[1] = float2(1.0) + _5240;
                                    _5186[0] = ((float2(2.0) - _5230) / _5185[0]) - float2(1.0);
                                    _5186[1] = (_5230 / _5185[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _5267 = _5230 * 3.0;
                                    _5185[0] = float2(4.0) - _5267;
                                    _5185[1] = float2(7.0);
                                    _5185[2] = float2(1.0) + _5267;
                                    _5186[0] = ((float2(3.0) - (_5230 * 2.0)) / _5185[0]) - float2(2.0);
                                    _5186[1] = (float2(3.0) + _5230) / _5185[1];
                                    _5186[2] = (_5230 / _5185[2]) + float2(2.0);
                                }
                                int _6365 = _5237 ? 2 : 3;
                                int _6080;
                                float _6083;
                                _6083 = 0.0;
                                _6080 = 0;
                                float _6089;
                                for (; _6080 < _6365; _6083 = _6089, _6080++)
                                {
                                    _6089 = _6083;
                                    for (int _6086 = 0; _6086 < _6365; )
                                    {
                                        _6089 += ((_5185[_6086].x * _5185[_6080].y) * spvDepthCast(_193).sample_compare(_193Smplr, float3(fast::clamp(_173._m22.xy * (_5233 + float2(_5186[_6086].x, _5186[_6080].y)), _5175.xy, _5175.zw), _4991).xy, _4991));
                                        _6086++;
                                        continue;
                                    }
                                }
                                _6090 = _6083 * (_5237 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _6091 = _6090;
                            break;
                        }
                        uint _5001 = _4796 - _4897;
                        if (_5001 >= uint(_173._m21.w))
                        {
                            _6091 = 1.0;
                            break;
                        }
                        float _5022 = _173._m27[_5001].w * length(in.m_1444 - _173._m27[_5001].xyz);
                        float3 _5040 = ((in.m_1444 + (_1838 * (_5022 * _173._m25.x))) + (_4830 * (_5022 * _173._m25.y))) - _173._m27[_5001].xyz;
                        float3 _5042 = abs(_5040);
                        float _5044 = _5042.x;
                        float _5046 = _5042.y;
                        bool _5047 = _5044 >= _5046;
                        bool _5055;
                        if (_5047)
                        {
                            _5055 = _5044 >= _5042.z;
                        }
                        else
                        {
                            _5055 = _5047;
                        }
                        float _6065;
                        int _6067;
                        if (_5055)
                        {
                            _6067 = (_5040.x > 0.0) ? 0 : 1;
                            _6065 = _5044;
                        }
                        else
                        {
                            float _5067 = _5042.z;
                            bool _5068 = _5046 >= _5067;
                            int _6068;
                            if (_5068)
                            {
                                _6068 = (_5040.y > 0.0) ? 2 : 3;
                            }
                            else
                            {
                                _6068 = (_5040.z > 0.0) ? 4 : 5;
                            }
                            _6067 = _6068;
                            _6065 = _5068 ? _5046 : _5067;
                        }
                        if (_6065 <= 0.0)
                        {
                            _6091 = 1.0;
                            break;
                        }
                        float2 _5105 = float2(dot(_5040, _851[_6067]), dot(_5040, _860[_6067])) / float2(_6065 * _173._m24.z);
                        float _5112 = _173._m28[_5001].z + (_173._m28[_5001].w / _6065);
                        if (_5112 > 1.0)
                        {
                            _6091 = 1.0;
                            break;
                        }
                        float2 _5130 = _173._m28[_5001].xy + (float2(float(spvSMod(_6067, 3)), float(_6067 / 3)) * _173._m24.xy);
                        float2 _5370 = _173._m22.xy * 0.5;
                        float2 _5375 = _5130 + (float2(0.5 + (0.5 * _5105.x), 0.5 - (0.5 * _5105.y)) * _173._m24.xy);
                        float4 _5388 = float4(_5130 + _5370, (_5130 + _173._m24.xy) - _5370);
                        float _6079;
                        do
                        {
                            int _5414 = int(_173._m22.z);
                            if (_5414 <= 0)
                            {
                                _6079 = spvDepthCast(_193).sample_compare(_193Smplr, float3(fast::clamp(_5375, _5388.xy, _5388.zw), _5112).xy, _5112);
                                break;
                            }
                            float2 _5437 = (_5375 / _173._m22.xy) + float2(0.5);
                            float2 _5438 = floor(_5437);
                            float2 _5443 = _5437 - _5438;
                            float2 _5446 = _5438 - float2(0.5);
                            bool _5450 = _5414 == 1;
                            if (_5450)
                            {
                                float2 _5453 = _5443 * 2.0;
                                _5398[0] = float2(3.0) - _5453;
                                _5398[1] = float2(1.0) + _5453;
                                _5399[0] = ((float2(2.0) - _5443) / _5398[0]) - float2(1.0);
                                _5399[1] = (_5443 / _5398[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _5480 = _5443 * 3.0;
                                _5398[0] = float2(4.0) - _5480;
                                _5398[1] = float2(7.0);
                                _5398[2] = float2(1.0) + _5480;
                                _5399[0] = ((float2(3.0) - (_5443 * 2.0)) / _5398[0]) - float2(2.0);
                                _5399[1] = (float2(3.0) + _5443) / _5398[1];
                                _5399[2] = (_5443 / _5398[2]) + float2(2.0);
                            }
                            int _6368 = _5450 ? 2 : 3;
                            int _6069;
                            float _6072;
                            _6072 = 0.0;
                            _6069 = 0;
                            float _6078;
                            for (; _6069 < _6368; _6072 = _6078, _6069++)
                            {
                                _6078 = _6072;
                                for (int _6075 = 0; _6075 < _6368; )
                                {
                                    _6078 += ((_5398[_6075].x * _5398[_6069].y) * spvDepthCast(_193).sample_compare(_193Smplr, float3(fast::clamp(_173._m22.xy * (_5446 + float2(_5399[_6075].x, _5399[_6069].y)), _5388.xy, _5388.zw), _5112).xy, _5112));
                                    _6075++;
                                    continue;
                                }
                            }
                            _6079 = _6072 * (_5450 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _6091 = _6079;
                        break;
                    } while(false);
                    _6133 = _4861 * _6091;
                }
                else
                {
                    _6133 = _4861;
                }
                float3 _2238 = fast::normalize(_4830 + _1827);
                float _2243 = fast::clamp(dot(_6007, _4830), 0.0, 1.0);
                float _2248 = fast::clamp(dot(_6007, _2238), 0.0, 1.0);
                float3 _5585 = _2062 + (_4088 * powr(1.0 - fast::clamp(dot(_1827, _2238), 0.0, 1.0), 5.0));
                float _5599 = ((_2248 * _2248) * _4103) + 1.0;
                _2286 = _6135 + (((((float3(1.0) - _5585) * _2055) + ((_5585 * ((_4098 / ((3.1415927410125732421875 * _5599) * _5599)) * (0.5 / fast::max((_2243 * _4129) + (_2067 * sqrt(((_2243 * _2243) * _4125) + _4098)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875)) * _2243) * _6133);
            }
            _6180 = _6135;
        }
        else
        {
            _6180 = _2186;
        }
        _6177 = _6180;
    }
    out.m_2324 = float4(mix(mix(_6177, _6005, float3(_1620._m1.y)) + (_1620._m5.xyz * _2298.sample(_1210, _1639).xyz), _173._m7.xyz, float3(1.0 - exp((-length(_1826)) * _173._m7.w))), (in.m_1648.w * _1620._m0.w) * _1646.w);
    float2 _6211;
    do
    {
        if (in.m_2340.w <= 0.0)
        {
            _6211 = float2(0.0);
            break;
        }
        _6211 = ((in.m_2340.xy / float2(in.m_2340.w)) - (in.m_2339.xy / float2(in.m_2339.w))) * float2(0.5, -0.5);
        break;
    } while(false);
    out.m_2338 = _6211;
    return out;
}

