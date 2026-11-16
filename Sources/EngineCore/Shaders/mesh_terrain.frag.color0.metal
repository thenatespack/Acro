// Generated from mesh_terrain.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: ebfe837efcb67e2e
// glsl-fnv1a64: 08f2d8721d375c02

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

struct _183
{
    float4 _m0[1];
};

struct _500
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
    float4x4 _m30;
    float4 _m31;
    float4 _m32;
    float4 _m33;
};

struct _1748
{
    float4 _m0[1024];
};

struct _1783
{
    float4 _m0[1024];
};

struct _1791
{
    float4 _m0[1024];
};

struct _1888
{
    uint4 _m0[1024];
};

struct _1910
{
    uint4 _m0[1024];
};

struct _2145
{
    float4 _m0;
};

struct _2238
{
    float4 _m0;
    float4 _m1;
    float4 _m2;
    float4 _m3;
    float4 _m4;
    float4 _m5;
    float4 _m6;
};

constant spvUnsafeArray<float3, 4> _867 = spvUnsafeArray<float3, 4>({ float3(1.0, 0.449999988079071044921875, 0.449999988079071044921875), float3(0.449999988079071044921875, 1.0, 0.449999988079071044921875), float3(0.5, 0.60000002384185791015625, 1.0), float3(1.0, 1.0, 0.4000000059604644775390625) });
constant spvUnsafeArray<float3, 6> _1169 = spvUnsafeArray<float3, 6>({ float3(0.0, 0.0, 1.0), float3(0.0, 0.0, -1.0), float3(-1.0, 0.0, 0.0), float3(-1.0, 0.0, 0.0), float3(-1.0, 0.0, 0.0), float3(1.0, 0.0, 0.0) });
constant spvUnsafeArray<float3, 6> _1178 = spvUnsafeArray<float3, 6>({ float3(0.0, 1.0, 0.0), float3(0.0, 1.0, 0.0), float3(0.0, 0.0, -1.0), float3(0.0, 0.0, 1.0), float3(0.0, 1.0, 0.0), float3(0.0, 1.0, 0.0) });
constant spvUnsafeArray<int4, 6> _1584 = spvUnsafeArray<int4, 6>({ int4(0, 0, 512, 256), int4(0, 256, 256, 128), int4(256, 256, 128, 64), int4(384, 256, 64, 32), int4(448, 256, 32, 16), int4(480, 256, 16, 8) });

struct fragment_main_out
{
    float4 m_2833 [[color(0)]];
};

struct fragment_main_in
{
    float3 m_1758 [[user(locn0)]];
    float3 m_2130 [[user(locn1)]];
    float2 m_2125 [[user(locn2)]];
    float4 m_2142 [[user(locn3)]];
    float4 m_2280 [[user(locn5)]];
    float4 m_2842 [[user(locn6)]];
    float4 m_2843 [[user(locn7)]];
    float4 m_2183 [[user(locn8)]];
};

fragment fragment_main_out fragment_main(fragment_main_in in [[stage_in]], constant _2238& _2240 [[buffer(2)]], constant _1748& _1750 [[buffer(3)]], constant _1783& _1785 [[buffer(4)]], constant _1791& _1793 [[buffer(5)]], constant _1888& _1890 [[buffer(6)]], constant _1910& _1912 [[buffer(7)]], constant _500& _502 [[buffer(15)]], constant _2145& _2147 [[buffer(16)]], const device _183& _185 [[buffer(20)]], texture2d<float> _520 [[texture(0)]], texture2d<float> _379 [[texture(1)]], texture2d<float> _266 [[texture(2)]], texture2d<float> _400 [[texture(3)]], texture2d<float> _2076 [[texture(4)]], texture2d<float> _282 [[texture(5)]], texture2d<float> _1523 [[texture(6)]], texture2d<float> _1628 [[texture(7)]], sampler _520Smplr [[sampler(0)]], sampler _268 [[sampler(1)]], sampler _1630 [[sampler(7)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])
{
    float2 _2841;
    fragment_main_out out = {};
    int _2923 = int(_185._m0[0].x + 0.5);
    int _2927 = int(_185._m0[0].y + 0.5);
    float2 _2935 = (in.m_2125 * _185._m0[0].z) + float2(_185._m0[0].w);
    float4 _2887 = _266.sample(_268, _2935, level(0.0));
    float4 _6865;
    if (_2923 > 4)
    {
        _6865 = _282.sample(_268, _2935, level(0.0));
    }
    else
    {
        _6865 = float4(0.0);
    }
    float4 _2888 = _6865;
    float2 _2957 = (in.m_2125 - float2(0.5)) * _185._m0[1].xy;
    float2 _2959 = dfdx(_2957);
    float2 _2961 = dfdy(_2957);
    float3 _6870;
    float3 _6874;
    float _6877;
    _6877 = 0.0;
    _6874 = float3(0.0);
    _6870 = float3(0.0);
    float3 _7413;
    float3 _7415;
    float _7416;
    for (int _6866 = 0; _6866 < 8; _6877 = _7416, _6874 = _7415, _6870 = _7413, _6866++)
    {
        if (_6866 >= _2923)
        {
            break;
        }
        float _6867;
        if (_6866 < 4)
        {
            _6867 = _2887[_6866];
        }
        else
        {
            _6867 = _2888[_6866 - 4];
        }
        if (_6867 < 0.001953125)
        {
            _7416 = _6877;
            _7415 = _6874;
            _7413 = _6870;
            continue;
        }
        int _2991 = 3 + (_6866 / 4);
        int _2993 = spvSMod(_6866, 4);
        float2 _3001 = _2959 * ((device float*)&_185._m0[_2991])[_2993];
        float2 _3004 = _2961 * ((device float*)&_185._m0[_2991])[_2993];
        float _3107 = fast::clamp(0.5 * log2(fast::max((fast::max(dot(_3001, _3001), dot(_3004, _3004)) * _185._m0[2].w) * _185._m0[2].w, 9.9999999392252902907785028219223e-09)), 0.0, fast::max(log2(_185._m0[2].w) - 2.0, 0.0));
        float _3120 = float(_6866);
        float _3134 = (0.5 * exp2(_3107)) / _185._m0[2].w;
        float2 _3148 = (float2(mod(_3120, _185._m0[2].y), floor(_3120 / _185._m0[2].y)) + fast::clamp(fract(_2957 * ((device float*)&_185._m0[_2991])[_2993]), float2(_3134), float2(1.0 - _3134))) / _185._m0[2].yz;
        float3 _6871;
        if (((_2927 >> _6866) & 1) != 0)
        {
            float3 _3038 = (_400.sample(_268, _3148, level(_3107)).xyz * 2.0) - float3(1.0);
            float2 _3043 = _3038.xy * _185._m0[1].z;
            float3 _6678 = _3038;
            _6678.x = _3043.x;
            _6678.y = _3043.y;
            _6871 = _6678;
        }
        else
        {
            _6871 = float3(0.0, 0.0, 1.0);
        }
        _7416 = _6877 + _6867;
        _7415 = _6874 + (_6871 * _6867);
        _7413 = _6870 + (_379.sample(_268, _3148, level(_3107)).xyz * _6867);
    }
    bool _3062 = _6877 > 0.0;
    float _6881;
    if (_3062)
    {
        _6881 = 1.0 / _6877;
    }
    else
    {
        _6881 = 0.0;
    }
    float3 _6887;
    if (_3062)
    {
        _6887 = _6874 * _6881;
    }
    else
    {
        _6887 = float3(0.0, 0.0, 1.0);
    }
    float3 _2157 = in.m_2142.xyz * fast::max(_6870 * _6881, float3(0.0));
    if (_2147._m0.y > 0.5)
    {
        if (1.0 < _2147._m0.z)
        {
            discard_fragment();
        }
    }
    float3 _2181 = fast::normalize(in.m_2130);
    float3 _2192 = in.m_2183.xyz - (_2181 * dot(_2181, in.m_2183.xyz));
    bool _2197 = dot(_2192, _2192) > 9.9999999600419720025001879548654e-13;
    bool _2204;
    if (_2197)
    {
        _2204 = dot(_6887, _6887) > 9.9999999600419720025001879548654e-13;
    }
    else
    {
        _2204 = _2197;
    }
    float3 _6891;
    if (_2204)
    {
        float3 _2208 = fast::normalize(_2192);
        float3 _2220 = fast::normalize(_6887);
        _6891 = fast::normalize(((_2208 * _2220.x) + ((cross(_2181, _2208) * ((in.m_2183.w < 0.0) ? (-1.0) : 1.0)) * _2220.y)) + (_2181 * _2220.z));
    }
    else
    {
        _6891 = _2181;
    }
    bool _2243 = _2240._m5.w > 0.5;
    bool _2251;
    if (_2243)
    {
        _2251 = !gl_FrontFacing;
    }
    else
    {
        _2251 = _2243;
    }
    float3 _6999;
    if (_2251)
    {
        _6999 = -_6891;
    }
    else
    {
        _6999 = _6891;
    }
    float3 _2260 = fast::normalize(_502._m4.xyz);
    float3 _2266 = _502._m6.xyz - in.m_1758;
    float3 _2267 = fast::normalize(_2266);
    float3 _2272 = fast::normalize(_2260 + _2267);
    float3 _2278 = _2181 * (gl_FrontFacing ? 1.0 : (-1.0));
    bool _2283 = in.m_2280.x > 0.5;
    float3 _6997;
    float _7022;
    if ((_502._m5.w > 0.5) && _2283)
    {
        float _6947;
        float3 _6948;
        do
        {
            int _3169 = int(_502._m21.x);
            float _3177 = dot(_502._m20.xyz, in.m_1758) + _502._m20.w;
            int _6892;
            _6892 = 0;
            for (;;)
            {
                bool _3183 = _6892 < (_3169 - 1);
                bool _3191;
                if (_3183)
                {
                    _3191 = _3177 > _502._m16[_6892];
                }
                else
                {
                    _3191 = _3183;
                }
                if (_3191)
                {
                    _6892++;
                    continue;
                }
                else
                {
                    break;
                }
            }
            if (_3177 > _502._m16[_6892])
            {
                _6948 = float3(1.0);
                _6947 = 1.0;
                break;
            }
            float _6905;
            do
            {
                float4 _3293 = _502._m14[_6892] * float4(in.m_1758 + (_2278 * _502._m18[_6892]), 1.0);
                float _3296 = _3293.x;
                bool _3297 = _3296 < 0.0;
                bool _3304;
                if (!_3297)
                {
                    _3304 = _3296 > 1.0;
                }
                else
                {
                    _3304 = _3297;
                }
                bool _3311;
                if (!_3304)
                {
                    _3311 = _3293.y < 0.0;
                }
                else
                {
                    _3311 = _3304;
                }
                bool _3318;
                if (!_3311)
                {
                    _3318 = _3293.y > 1.0;
                }
                else
                {
                    _3318 = _3311;
                }
                if (_3318)
                {
                    _6905 = 1.0;
                    break;
                }
                float2 _3331 = float2(float(_6892 & 1), float(_6892 >> 1)) * _502._m23.xy;
                float _3338 = fast::min(_3293.z, 1.0) - _502._m19[_6892];
                float2 _3357 = _502._m22.xy * 0.5;
                float2 _3362 = _3331 + (_3293.xy * _502._m23.xy);
                float4 _3375 = float4(_3331 + _3357, (_3331 + _502._m23.xy) - _3357);
                float _6904;
                do
                {
                    int _3401 = int(_502._m22.z);
                    if (_3401 <= 0)
                    {
                        _6904 = spvDepthCast(_520).sample_compare(_520Smplr, float3(fast::clamp(_3362, _3375.xy, _3375.zw), _3338).xy, _3338);
                        break;
                    }
                    float2 _3424 = (_3362 / _502._m22.xy) + float2(0.5);
                    float2 _3425 = floor(_3424);
                    float2 _3430 = _3424 - _3425;
                    float2 _3433 = _3425 - float2(0.5);
                    bool _3437 = _3401 == 1;
                    spvUnsafeArray<float2, 3> _3385;
                    spvUnsafeArray<float2, 3> _3386;
                    if (_3437)
                    {
                        float2 _3440 = _3430 * 2.0;
                        _3385[0] = float2(3.0) - _3440;
                        _3385[1] = float2(1.0) + _3440;
                        _3386[0] = ((float2(2.0) - _3430) / _3385[0]) - float2(1.0);
                        _3386[1] = (_3430 / _3385[1]) + float2(1.0);
                    }
                    else
                    {
                        float2 _3467 = _3430 * 3.0;
                        _3385[0] = float2(4.0) - _3467;
                        _3385[1] = float2(7.0);
                        _3385[2] = float2(1.0) + _3467;
                        _3386[0] = ((float2(3.0) - (_3430 * 2.0)) / _3385[0]) - float2(2.0);
                        _3386[1] = (float2(3.0) + _3430) / _3385[1];
                        _3386[2] = (_3430 / _3385[2]) + float2(2.0);
                    }
                    int _7465 = _3437 ? 2 : 3;
                    int _6894;
                    float _6897;
                    _6897 = 0.0;
                    _6894 = 0;
                    float _6903;
                    for (; _6894 < _7465; _6897 = _6903, _6894++)
                    {
                        _6903 = _6897;
                        for (int _6900 = 0; _6900 < _7465; )
                        {
                            _6903 += ((_3385[_6900].x * _3385[_6894].y) * spvDepthCast(_520).sample_compare(_520Smplr, float3(fast::clamp(_502._m22.xy * (_3433 + float2(_3386[_6900].x, _3386[_6894].y)), _3375.xy, _3375.zw), _3338).xy, _3338));
                            _6900++;
                            continue;
                        }
                    }
                    _6904 = _6897 * (_3437 ? 0.0625 : 0.0069444444961845874786376953125);
                    break;
                } while(false);
                _6905 = _6904;
                break;
            } while(false);
            float3 _6942;
            float _6945;
            if (_3177 > _502._m17[_6892])
            {
                float _3231 = (_3177 - _502._m17[_6892]) / (_502._m16[_6892] - _502._m17[_6892]);
                int _3233 = _6892 + 1;
                float3 _6943;
                float _6946;
                if (_3233 < _3169)
                {
                    float _6925;
                    do
                    {
                        float4 _3580 = _502._m14[_3233] * float4(in.m_1758 + (_2278 * _502._m18[_3233]), 1.0);
                        float _3583 = _3580.x;
                        bool _3584 = _3583 < 0.0;
                        bool _3591;
                        if (!_3584)
                        {
                            _3591 = _3583 > 1.0;
                        }
                        else
                        {
                            _3591 = _3584;
                        }
                        bool _3598;
                        if (!_3591)
                        {
                            _3598 = _3580.y < 0.0;
                        }
                        else
                        {
                            _3598 = _3591;
                        }
                        bool _3605;
                        if (!_3598)
                        {
                            _3605 = _3580.y > 1.0;
                        }
                        else
                        {
                            _3605 = _3598;
                        }
                        if (_3605)
                        {
                            _6925 = 1.0;
                            break;
                        }
                        float2 _3618 = float2(float(_3233 & 1), float(_3233 >> 1)) * _502._m23.xy;
                        float _3625 = fast::min(_3580.z, 1.0) - _502._m19[_3233];
                        float2 _3644 = _502._m22.xy * 0.5;
                        float2 _3649 = _3618 + (_3580.xy * _502._m23.xy);
                        float4 _3662 = float4(_3618 + _3644, (_3618 + _502._m23.xy) - _3644);
                        float _6924;
                        do
                        {
                            int _3688 = int(_502._m22.z);
                            if (_3688 <= 0)
                            {
                                _6924 = spvDepthCast(_520).sample_compare(_520Smplr, float3(fast::clamp(_3649, _3662.xy, _3662.zw), _3625).xy, _3625);
                                break;
                            }
                            float2 _3711 = (_3649 / _502._m22.xy) + float2(0.5);
                            float2 _3712 = floor(_3711);
                            float2 _3717 = _3711 - _3712;
                            float2 _3720 = _3712 - float2(0.5);
                            bool _3724 = _3688 == 1;
                            spvUnsafeArray<float2, 3> _3672;
                            spvUnsafeArray<float2, 3> _3673;
                            if (_3724)
                            {
                                float2 _3727 = _3717 * 2.0;
                                _3672[0] = float2(3.0) - _3727;
                                _3672[1] = float2(1.0) + _3727;
                                _3673[0] = ((float2(2.0) - _3717) / _3672[0]) - float2(1.0);
                                _3673[1] = (_3717 / _3672[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _3754 = _3717 * 3.0;
                                _3672[0] = float2(4.0) - _3754;
                                _3672[1] = float2(7.0);
                                _3672[2] = float2(1.0) + _3754;
                                _3673[0] = ((float2(3.0) - (_3717 * 2.0)) / _3672[0]) - float2(2.0);
                                _3673[1] = (float2(3.0) + _3717) / _3672[1];
                                _3673[2] = (_3717 / _3672[2]) + float2(2.0);
                            }
                            int _7467 = _3724 ? 2 : 3;
                            int _6914;
                            float _6917;
                            _6917 = 0.0;
                            _6914 = 0;
                            float _6923;
                            for (; _6914 < _7467; _6917 = _6923, _6914++)
                            {
                                _6923 = _6917;
                                for (int _6920 = 0; _6920 < _7467; )
                                {
                                    _6923 += ((_3672[_6920].x * _3672[_6914].y) * spvDepthCast(_520).sample_compare(_520Smplr, float3(fast::clamp(_502._m22.xy * (_3720 + float2(_3673[_6920].x, _3673[_6914].y)), _3662.xy, _3662.zw), _3625).xy, _3625));
                                    _6920++;
                                    continue;
                                }
                            }
                            _6924 = _6917 * (_3724 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _6925 = _6924;
                        break;
                    } while(false);
                    _6946 = mix(_6905, _6925, _3231);
                    _6943 = mix(_867[_6892], _867[_3233], float3(_3231));
                }
                else
                {
                    _6946 = mix(_6905, 1.0, _3231);
                    _6943 = _867[_6892];
                }
                _6945 = _6946;
                _6942 = _6943;
            }
            else
            {
                _6945 = _6905;
                _6942 = _867[_6892];
            }
            _6948 = select(float3(1.0), _6942, bool3(_502._m22.w > 0.5));
            _6947 = _6945;
            break;
        } while(false);
        _7022 = _6947;
        _6997 = _2157 * _6948;
    }
    else
    {
        _7022 = 1.0;
        _6997 = _2157;
    }
    float3 _2309 = _502._m5.xyz * _502._m4.w;
    float3 _7187;
    if (!_2243)
    {
        float _2320 = dot(_6999, _2260);
        float3 _7181;
        if (_502._m29.x > 0.5)
        {
            float _3905 = (_502._m29.z * _6999.x) - (_502._m29.w * _6999.z);
            float _3918 = (_502._m29.w * _6999.x) + (_502._m29.z * _6999.z);
            float _3936 = 1.09254801273345947265625 * _3905;
            spvUnsafeArray<float, 9> _6668 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _6999.y, 0.48860299587249755859375 * _3918, 0.48860299587249755859375 * _3905, _3936 * _6999.y, (1.09254801273345947265625 * _6999.y) * _3918, 0.3153919875621795654296875 * (((3.0 * _3918) * _3918) - 1.0), _3936 * _3918, 0.546274006366729736328125 * ((_3905 * _3905) - (_6999.y * _6999.y)) });
            spvUnsafeArray<float, 9> _3850 = _6668;
            float3 _7180;
            _7180 = float3(0.0);
            for (int _7179 = 0; _7179 < 9; )
            {
                _7180 += (_1523.read(uint2((int2(496, 256) + int2(_7179, 0))), 0).xyz * _3850[_7179]);
                _7179++;
                continue;
            }
            _7181 = fast::max(_7180, float3(0.0)) * _502._m29.y;
        }
        else
        {
            _7181 = mix(_502._m9.xyz, _502._m8.xyz, float3((_6999.y * 0.5) + 0.5)) * _502._m8.w;
        }
        float3 _2370 = (_6997 * ((_7181 * 1.0) + ((_2309 * fast::max(_2320, 0.0)) * _7022))) + ((_2309 * ((powr(fast::max(dot(_6999, _2272), 0.0), _2240._m1.w) * _2240._m1.z) * step(0.0, _2320))) * _7022);
        float3 _7188;
        if (_502._m13.w > 0.5)
        {
            float2 _4021 = fast::clamp(floor(gl_FragCoord.xy * _502._m12.xy), float2(0.0), _502._m13.xy - float2(1.0));
            uint _4049 = uint((((fast::clamp(floor((log2(fast::max(dot(_502._m11.xyz, in.m_1758) + _502._m11.w, 9.9999999747524270787835121154785e-07)) * _502._m12.z) + _502._m12.w), 0.0, _502._m13.z - 1.0) * _502._m13.y) + _4021.y) * _502._m13.x) + _4021.x);
            uint _4051 = _4049 >> uint(2);
            uint _4053 = _4049 & 3u;
            uint _4057 = _1890._m0[_4051][_4053] & 65535u;
            uint _4059 = _1890._m0[_4051][_4053] >> uint(16);
            float3 _7189;
            _7189 = _2370;
            float3 _2451;
            spvUnsafeArray<float2, 3> _4467;
            spvUnsafeArray<float2, 3> _4468;
            spvUnsafeArray<float2, 3> _4680;
            spvUnsafeArray<float2, 3> _4681;
            for (uint _7186 = _4057; _7186 < (_4057 + _4059); _7189 = _2451, _7186++)
            {
                uint _4065 = _7186 / 3u;
                uint _4078 = (_1912._m0[_4065 >> uint(2)][_4065 & 3u] >> ((_7186 - (_4065 * 3u)) * 10u)) & 1023u;
                float3 _4095 = _1750._m0[_4078].xyz - in.m_1758;
                float _4098 = dot(_4095, _4095);
                float _4102 = _4098 * _1750._m0[_4078].w;
                float _4107 = fast::clamp(1.0 - (_4102 * _4102), 0.0, 1.0);
                float3 _4112 = _4095 * rsqrt(fast::max(_4098, 9.9999999392252902907785028219223e-09));
                float _4130 = fast::clamp((dot(-_4112, _1793._m0[_4078].xyz) * _1785._m0[_4078].w) + _1793._m0[_4078].w, 0.0, 1.0);
                float3 _4143 = _1785._m0[_4078].xyz * ((((_4107 * _4107) * _4130) * _4130) / fast::max(_4098, 9.9999997473787516355514526367188e-05));
                float3 _7378;
                if (_2283)
                {
                    float _7324;
                    do
                    {
                        uint _4179 = uint(_502._m21.z);
                        if (_4078 < _4179)
                        {
                            float _4201 = _502._m26[_4078].z * fast::max((_502._m15[_4078] * float4(in.m_1758, 1.0)).w, 0.0);
                            float4 _4225 = _502._m15[_4078] * float4((in.m_1758 + (_2278 * (_4201 * _502._m25.x))) + (_4112 * (_4201 * _502._m25.y)), 1.0);
                            float _4227 = _4225.w;
                            if (_4227 <= 0.0)
                            {
                                _7324 = 1.0;
                                break;
                            }
                            float3 _4236 = _4225.xyz / float3(_4227);
                            float _4238 = _4236.x;
                            bool _4239 = _4238 < 0.0;
                            bool _4246;
                            if (!_4239)
                            {
                                _4246 = _4238 > 1.0;
                            }
                            else
                            {
                                _4246 = _4239;
                            }
                            bool _4253;
                            if (!_4246)
                            {
                                _4253 = _4236.y < 0.0;
                            }
                            else
                            {
                                _4253 = _4246;
                            }
                            bool _4260;
                            if (!_4253)
                            {
                                _4260 = _4236.y > 1.0;
                            }
                            else
                            {
                                _4260 = _4253;
                            }
                            bool _4267;
                            if (!_4260)
                            {
                                _4267 = _4236.z > 1.0;
                            }
                            else
                            {
                                _4267 = _4260;
                            }
                            if (_4267)
                            {
                                _7324 = 1.0;
                                break;
                            }
                            float _4273 = _4236.z;
                            float2 _4439 = _502._m22.xy * 0.5;
                            float2 _4444 = _502._m26[_4078].xy + (_4236.xy * _502._m23.zw);
                            float4 _4457 = float4(_502._m26[_4078].xy + _4439, (_502._m26[_4078].xy + _502._m23.zw) - _4439);
                            float _7323;
                            do
                            {
                                int _4483 = int(_502._m22.z);
                                if (_4483 <= 0)
                                {
                                    float2 _4493 = fast::clamp(_4444, _4457.xy, _4457.zw);
                                    _7323 = spvDepthCast(_520).sample_compare(_520Smplr, float3(_4493, _4273).xy, _4273);
                                    break;
                                }
                                float2 _4506 = (_4444 / _502._m22.xy) + float2(0.5);
                                float2 _4507 = floor(_4506);
                                float2 _4512 = _4506 - _4507;
                                float2 _4515 = _4507 - float2(0.5);
                                bool _4519 = _4483 == 1;
                                if (_4519)
                                {
                                    float2 _4522 = _4512 * 2.0;
                                    _4467[0] = float2(3.0) - _4522;
                                    _4467[1] = float2(1.0) + _4522;
                                    _4468[0] = ((float2(2.0) - _4512) / _4467[0]) - float2(1.0);
                                    _4468[1] = (_4512 / _4467[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _4549 = _4512 * 3.0;
                                    _4467[0] = float2(4.0) - _4549;
                                    _4467[1] = float2(7.0);
                                    _4467[2] = float2(1.0) + _4549;
                                    _4468[0] = ((float2(3.0) - (_4512 * 2.0)) / _4467[0]) - float2(2.0);
                                    _4468[1] = (float2(3.0) + _4512) / _4467[1];
                                    _4468[2] = (_4512 / _4467[2]) + float2(2.0);
                                }
                                int _7472 = _4519 ? 2 : 3;
                                int _7313;
                                float _7316;
                                _7316 = 0.0;
                                _7313 = 0;
                                float _7322;
                                for (; _7313 < _7472; _7316 = _7322, _7313++)
                                {
                                    _7322 = _7316;
                                    for (int _7319 = 0; _7319 < _7472; )
                                    {
                                        _7322 += ((_4467[_7319].x * _4467[_7313].y) * spvDepthCast(_520).sample_compare(_520Smplr, float3(fast::clamp(_502._m22.xy * (_4515 + float2(_4468[_7319].x, _4468[_7313].y)), _4457.xy, _4457.zw), _4273).xy, _4273));
                                        _7319++;
                                        continue;
                                    }
                                }
                                _7323 = _7316 * (_4519 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _7324 = _7323;
                            break;
                        }
                        uint _4283 = _4078 - _4179;
                        if (_4283 >= uint(_502._m21.w))
                        {
                            _7324 = 1.0;
                            break;
                        }
                        float _4304 = _502._m27[_4283].w * length(in.m_1758 - _502._m27[_4283].xyz);
                        float3 _4322 = ((in.m_1758 + (_2278 * (_4304 * _502._m25.x))) + (_4112 * (_4304 * _502._m25.y))) - _502._m27[_4283].xyz;
                        float3 _4324 = abs(_4322);
                        float _4326 = _4324.x;
                        float _4328 = _4324.y;
                        bool _4329 = _4326 >= _4328;
                        bool _4337;
                        if (_4329)
                        {
                            _4337 = _4326 >= _4324.z;
                        }
                        else
                        {
                            _4337 = _4329;
                        }
                        float _7298;
                        int _7300;
                        if (_4337)
                        {
                            _7300 = (_4322.x > 0.0) ? 0 : 1;
                            _7298 = _4326;
                        }
                        else
                        {
                            float _4349 = _4324.z;
                            bool _4350 = _4328 >= _4349;
                            int _7301;
                            if (_4350)
                            {
                                _7301 = (_4322.y > 0.0) ? 2 : 3;
                            }
                            else
                            {
                                _7301 = (_4322.z > 0.0) ? 4 : 5;
                            }
                            _7300 = _7301;
                            _7298 = _4350 ? _4328 : _4349;
                        }
                        if (_7298 <= 0.0)
                        {
                            _7324 = 1.0;
                            break;
                        }
                        float2 _4387 = float2(dot(_4322, _1169[_7300]), dot(_4322, _1178[_7300])) / float2(_7298 * _502._m24.z);
                        float _4394 = _502._m28[_4283].z + (_502._m28[_4283].w / _7298);
                        if (_4394 > 1.0)
                        {
                            _7324 = 1.0;
                            break;
                        }
                        float2 _4412 = _502._m28[_4283].xy + (float2(float(spvSMod(_7300, 3)), float(_7300 / 3)) * _502._m24.xy);
                        float2 _4652 = _502._m22.xy * 0.5;
                        float2 _4657 = _4412 + (float2(0.5 + (0.5 * _4387.x), 0.5 - (0.5 * _4387.y)) * _502._m24.xy);
                        float4 _4670 = float4(_4412 + _4652, (_4412 + _502._m24.xy) - _4652);
                        float _7312;
                        do
                        {
                            int _4696 = int(_502._m22.z);
                            if (_4696 <= 0)
                            {
                                _7312 = spvDepthCast(_520).sample_compare(_520Smplr, float3(fast::clamp(_4657, _4670.xy, _4670.zw), _4394).xy, _4394);
                                break;
                            }
                            float2 _4719 = (_4657 / _502._m22.xy) + float2(0.5);
                            float2 _4720 = floor(_4719);
                            float2 _4725 = _4719 - _4720;
                            float2 _4728 = _4720 - float2(0.5);
                            bool _4732 = _4696 == 1;
                            if (_4732)
                            {
                                float2 _4735 = _4725 * 2.0;
                                _4680[0] = float2(3.0) - _4735;
                                _4680[1] = float2(1.0) + _4735;
                                _4681[0] = ((float2(2.0) - _4725) / _4680[0]) - float2(1.0);
                                _4681[1] = (_4725 / _4680[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _4762 = _4725 * 3.0;
                                _4680[0] = float2(4.0) - _4762;
                                _4680[1] = float2(7.0);
                                _4680[2] = float2(1.0) + _4762;
                                _4681[0] = ((float2(3.0) - (_4725 * 2.0)) / _4680[0]) - float2(2.0);
                                _4681[1] = (float2(3.0) + _4725) / _4680[1];
                                _4681[2] = (_4725 / _4680[2]) + float2(2.0);
                            }
                            int _7475 = _4732 ? 2 : 3;
                            int _7302;
                            float _7305;
                            _7305 = 0.0;
                            _7302 = 0;
                            float _7311;
                            for (; _7302 < _7475; _7305 = _7311, _7302++)
                            {
                                _7311 = _7305;
                                for (int _7308 = 0; _7308 < _7475; )
                                {
                                    _7311 += ((_4680[_7308].x * _4680[_7302].y) * spvDepthCast(_520).sample_compare(_520Smplr, float3(fast::clamp(_502._m22.xy * (_4728 + float2(_4681[_7308].x, _4681[_7302].y)), _4670.xy, _4670.zw), _4394).xy, _4394));
                                    _7308++;
                                    continue;
                                }
                            }
                            _7312 = _7305 * (_4732 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _7324 = _7312;
                        break;
                    } while(false);
                    _7378 = _4143 * _7324;
                }
                else
                {
                    _7378 = _4143;
                }
                float _2422 = dot(_6999, _4112);
                _2451 = _7189 + (((_6997 * fast::max(_2422, 0.0)) * _7378) + (_7378 * ((powr(fast::max(dot(_6999, fast::normalize(_4112 + _2267)), 0.0), _2240._m1.w) * _2240._m1.z) * step(0.0, _2422))));
            }
            _7188 = _7189;
        }
        else
        {
            _7188 = _2370;
        }
        _7187 = _7188;
    }
    else
    {
        float _2457 = fast::clamp(_185._m0[2].x, 0.0, 1.0);
        float _2461 = fast::clamp(_185._m0[1].w, 0.04500000178813934326171875, 1.0);
        float _2465 = _2461 * _2461;
        float3 _2470 = _6997 * (1.0 - _2457);
        float3 _2476 = mix(float3(0.039999999105930328369140625), _6997, float3(_2457));
        float _2481 = fast::max(dot(_6999, _2267), 9.9999997473787516355514526367188e-05);
        float _2486 = fast::clamp(dot(_6999, _2260), 0.0, 1.0);
        float _2491 = fast::clamp(dot(_6999, _2272), 0.0, 1.0);
        float3 _4864 = float3(1.0) - _2476;
        float3 _4867 = _2476 + (_4864 * powr(1.0 - fast::clamp(dot(_2267, _2272), 0.0, 1.0), 5.0));
        float _4874 = _2465 * _2465;
        float _4879 = _4874 - 1.0;
        float _4881 = ((_2491 * _2491) * _4879) + 1.0;
        float _4901 = 1.0 - _4874;
        float _4905 = sqrt(((_2481 * _2481) * _4901) + _4874);
        float3 _7041;
        float2 _7056;
        float3 _7068;
        if (_502._m29.x > 0.5)
        {
            float4 _4938 = _1628.sample(_1630, (((float2(_2481, _2461) * 31.0) + float2(0.5)) * float2(0.03125)));
            float _4997 = (_502._m29.z * _6999.x) - (_502._m29.w * _6999.z);
            float _5010 = (_502._m29.w * _6999.x) + (_502._m29.z * _6999.z);
            float _5028 = 1.09254801273345947265625 * _4997;
            spvUnsafeArray<float, 9> _6649 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _6999.y, 0.48860299587249755859375 * _5010, 0.48860299587249755859375 * _4997, _5028 * _6999.y, (1.09254801273345947265625 * _6999.y) * _5010, 0.3153919875621795654296875 * (((3.0 * _5010) * _5010) - 1.0), _5028 * _5010, 0.546274006366729736328125 * ((_4997 * _4997) - (_6999.y * _6999.y)) });
            spvUnsafeArray<float, 9> _4942 = _6649;
            float3 _7024;
            _7024 = float3(0.0);
            for (int _7023 = 0; _7023 < 9; )
            {
                _7024 += (_1523.read(uint2((int2(496, 256) + int2(_7023, 0))), 0).xyz * _4942[_7023]);
                _7023++;
                continue;
            }
            float3 _2552 = reflect(-_2267, _6999);
            float _5123 = _2552.x;
            float _5128 = _2552.z;
            float2 _5160 = float2((precise::atan2((_502._m29.z * _5123) - (_502._m29.w * _5128), -((_502._m29.w * _5123) + (_502._m29.z * _5128))) * 0.15915493667125701904296875) + 0.5, acos(fast::clamp(_2552.y, -1.0, 1.0)) * 0.3183098733425140380859375);
            float _5092 = _2461 * 5.0;
            int _5095 = min(int(_5092), 4);
            float2 _5181 = (_5160 * float2(_1584[_5095].zw)) - float2(0.5);
            float2 _5183 = floor(_5181);
            float2 _5186 = _5181 - _5183;
            int _5189 = int(_5183.x);
            int _5192 = int(_5183.y);
            int _7026;
            if (_5189 < 0)
            {
                _7026 = _5189 + _1584[_5095].z;
            }
            else
            {
                _7026 = _5189;
            }
            int _7027;
            if (_7026 >= _1584[_5095].z)
            {
                _7027 = _7026 - _1584[_5095].z;
            }
            else
            {
                _7027 = _7026;
            }
            int _5212 = _7027 + 1;
            int _7476 = (_5212 == _1584[_5095].z) ? 0 : _5212;
            int _5227 = min((_5192 + 1), (_1584[_5095].w - 1));
            int _5229 = max(_5192, 0);
            float3 _5282 = float3(_5186.x);
            int _5102 = _5095 + 1;
            float2 _5314 = (_5160 * float2(_1584[_5102].zw)) - float2(0.5);
            float2 _5316 = floor(_5314);
            float2 _5319 = _5314 - _5316;
            int _5322 = int(_5316.x);
            int _5325 = int(_5316.y);
            int _7033;
            if (_5322 < 0)
            {
                _7033 = _5322 + _1584[_5102].z;
            }
            else
            {
                _7033 = _5322;
            }
            int _7034;
            if (_7033 >= _1584[_5102].z)
            {
                _7034 = _7033 - _1584[_5102].z;
            }
            else
            {
                _7034 = _7033;
            }
            int _5345 = _7034 + 1;
            int _7477 = (_5345 == _1584[_5102].z) ? 0 : _5345;
            int _5360 = min((_5325 + 1), (_1584[_5102].w - 1));
            int _5362 = max(_5325, 0);
            float3 _5415 = float3(_5319.x);
            float3 _5117 = mix(mix(mix(_1523.read(uint2((_1584[_5095].xy + int2(_7027, _5229))), 0).xyz, _1523.read(uint2((_1584[_5095].xy + int2(_7476, _5229))), 0).xyz, _5282), mix(_1523.read(uint2((_1584[_5095].xy + int2(_7027, _5227))), 0).xyz, _1523.read(uint2((_1584[_5095].xy + int2(_7476, _5227))), 0).xyz, _5282), float3(_5186.y)), mix(mix(_1523.read(uint2((_1584[_5102].xy + int2(_7034, _5362))), 0).xyz, _1523.read(uint2((_1584[_5102].xy + int2(_7477, _5362))), 0).xyz, _5415), mix(_1523.read(uint2((_1584[_5102].xy + int2(_7034, _5360))), 0).xyz, _1523.read(uint2((_1584[_5102].xy + int2(_7477, _5360))), 0).xyz, _5415), float3(_5319.y)), float3(_5092 - float(_5095))) * _502._m29.y;
            _7068 = fast::max(_7024, float3(0.0)) * _502._m29.y;
            _7056 = _4938.xy;
            _7041 = _5117;
        }
        else
        {
            float4 _5433 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * _2461) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);
            float _5435 = _5433.x;
            float3 _5470 = mix(_502._m9.xyz, _502._m8.xyz, float3((_6999.y * 0.5) + 0.5)) * _502._m8.w;
            _7068 = _5470;
            _7056 = (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_5435 * _5435, exp2((-9.27999973297119140625) * _2481)) * _5435) + _5433.y)) + _5433.zw;
            _7041 = mix(mix(_502._m9.xyz, _502._m8.xyz, float3((reflect(-_2267, _6999).y * 0.5) + 0.5)) * _502._m8.w, _5470, float3(_2461));
        }
        bool _2578 = _2240._m6.w > 0.5;
        bool _2584;
        if (_2578)
        {
            _2584 = _502._m33.z > 0.5;
        }
        else
        {
            _2584 = _2578;
        }
        float3 _7077;
        if (_2584)
        {
            float3 _7053;
            do
            {
                float _5549 = ((_502._m32.x * (1.0 - smoothstep(_502._m33.x * 0.5, _502._m33.x, abs(dot(_502._m31.xyz, in.m_1758) - _502._m31.w)))) * smoothstep(0.5, 0.89999997615814208984375, dot(_2278, _502._m31.xyz))) * (1.0 - smoothstep(_502._m32.y * 0.5, _502._m32.y, _2461));
                if (_5549 <= 0.0)
                {
                    _7053 = _7041;
                    break;
                }
                float4 _5574 = _502._m30 * float4(in.m_1758 + ((_6999 - (_502._m31.xyz * dot(_6999, _502._m31.xyz))) * _502._m32.w), 1.0);
                float2 _5587 = ((float2(_5574.x, -_5574.y) / float2(_5574.w)) * 0.5) + float2(0.5);
                float _5591 = _502._m32.z * _2461;
                float3 _7051;
                float _7052;
                _7052 = 0.0;
                _7051 = float3(0.0);
                for (int _7050 = 0; _7050 < 12; )
                {
                    float _5598 = float(_7050);
                    float _5606 = _5598 * 2.3999631404876708984375;
                    float2 _5618 = _5587 + (float2(cos(_5606) * _502._m33.y, sin(_5606)) * (sqrt((_5598 + 0.5) * 0.083333335816860198974609375) * _5591));
                    float2 _5623 = fast::min(_5618, float2(1.0) - _5618);
                    float _5629 = smoothstep(0.0, 0.039999999105930328369140625, fast::min(_5623.x, _5623.y));
                    float4 _5637 = _2076.sample(_268, fast::clamp(_5618, float2(0.0), float2(1.0)), level(0.0));
                    float3 _5639 = _5637.xyz;
                    _7052 += (_5637.w * _5629);
                    _7051 += ((_5639 / (float3(1.0) - fast::min(_5639, float3(0.99500000476837158203125)))) * _5629);
                    _7050++;
                    continue;
                }
                _7053 = mix(_7041, (_7051 * float3(0.083333335816860198974609375)) + (_7041 * (1.0 - (_7052 * 0.083333335816860198974609375))), float3(_5549));
                break;
            } while(false);
            _7077 = _7053;
        }
        else
        {
            _7077 = _7041;
        }
        float3 _2604 = (_2476 * _7056.x) + float3(_7056.y);
        float3 _2620 = ((((((float3(1.0) - _4867) * _2470) + ((_4867 * ((_4874 / ((3.1415927410125732421875 * _4881) * _4881)) * (0.5 / fast::max((_2486 * _4905) + (_2481 * sqrt(((_2486 * _2486) * _4901) + _4874)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875)) * _2486) * _2309) * _7022) + (((((float3(1.0) - _2604) * _2470) * _7068) + (_2604 * _7077)) * 1.0);
        float3 _7190;
        if (_502._m13.w > 0.5)
        {
            float2 _5703 = fast::clamp(floor(gl_FragCoord.xy * _502._m12.xy), float2(0.0), _502._m13.xy - float2(1.0));
            uint _5731 = uint((((fast::clamp(floor((log2(fast::max(dot(_502._m11.xyz, in.m_1758) + _502._m11.w, 9.9999999747524270787835121154785e-07)) * _502._m12.z) + _502._m12.w), 0.0, _502._m13.z - 1.0) * _502._m13.y) + _5703.y) * _502._m13.x) + _5703.x);
            uint _5733 = _5731 >> uint(2);
            uint _5735 = _5731 & 3u;
            uint _5739 = _1890._m0[_5733][_5735] & 65535u;
            uint _5741 = _1890._m0[_5733][_5735] >> uint(16);
            float3 _7145;
            _7145 = _2620;
            float3 _2720;
            spvUnsafeArray<float2, 3> _6149;
            spvUnsafeArray<float2, 3> _6150;
            spvUnsafeArray<float2, 3> _6362;
            spvUnsafeArray<float2, 3> _6363;
            for (uint _7078 = _5739; _7078 < (_5739 + _5741); _7145 = _2720, _7078++)
            {
                uint _5747 = _7078 / 3u;
                uint _5760 = (_1912._m0[_5747 >> uint(2)][_5747 & 3u] >> ((_7078 - (_5747 * 3u)) * 10u)) & 1023u;
                float3 _5777 = _1750._m0[_5760].xyz - in.m_1758;
                float _5780 = dot(_5777, _5777);
                float _5784 = _5780 * _1750._m0[_5760].w;
                float _5789 = fast::clamp(1.0 - (_5784 * _5784), 0.0, 1.0);
                float3 _5794 = _5777 * rsqrt(fast::max(_5780, 9.9999999392252902907785028219223e-09));
                float _5812 = fast::clamp((dot(-_5794, _1793._m0[_5760].xyz) * _1785._m0[_5760].w) + _1793._m0[_5760].w, 0.0, 1.0);
                float3 _5825 = _1785._m0[_5760].xyz * ((((_5789 * _5789) * _5812) * _5812) / fast::max(_5780, 9.9999997473787516355514526367188e-05));
                float3 _7143;
                if (_2283)
                {
                    float _7105;
                    do
                    {
                        uint _5861 = uint(_502._m21.z);
                        if (_5760 < _5861)
                        {
                            float _5883 = _502._m26[_5760].z * fast::max((_502._m15[_5760] * float4(in.m_1758, 1.0)).w, 0.0);
                            float4 _5907 = _502._m15[_5760] * float4((in.m_1758 + (_2278 * (_5883 * _502._m25.x))) + (_5794 * (_5883 * _502._m25.y)), 1.0);
                            float _5909 = _5907.w;
                            if (_5909 <= 0.0)
                            {
                                _7105 = 1.0;
                                break;
                            }
                            float3 _5918 = _5907.xyz / float3(_5909);
                            float _5920 = _5918.x;
                            bool _5921 = _5920 < 0.0;
                            bool _5928;
                            if (!_5921)
                            {
                                _5928 = _5920 > 1.0;
                            }
                            else
                            {
                                _5928 = _5921;
                            }
                            bool _5935;
                            if (!_5928)
                            {
                                _5935 = _5918.y < 0.0;
                            }
                            else
                            {
                                _5935 = _5928;
                            }
                            bool _5942;
                            if (!_5935)
                            {
                                _5942 = _5918.y > 1.0;
                            }
                            else
                            {
                                _5942 = _5935;
                            }
                            bool _5949;
                            if (!_5942)
                            {
                                _5949 = _5918.z > 1.0;
                            }
                            else
                            {
                                _5949 = _5942;
                            }
                            if (_5949)
                            {
                                _7105 = 1.0;
                                break;
                            }
                            float _5955 = _5918.z;
                            float2 _6121 = _502._m22.xy * 0.5;
                            float2 _6126 = _502._m26[_5760].xy + (_5918.xy * _502._m23.zw);
                            float4 _6139 = float4(_502._m26[_5760].xy + _6121, (_502._m26[_5760].xy + _502._m23.zw) - _6121);
                            float _7104;
                            do
                            {
                                int _6165 = int(_502._m22.z);
                                if (_6165 <= 0)
                                {
                                    float2 _6175 = fast::clamp(_6126, _6139.xy, _6139.zw);
                                    _7104 = spvDepthCast(_520).sample_compare(_520Smplr, float3(_6175, _5955).xy, _5955);
                                    break;
                                }
                                float2 _6188 = (_6126 / _502._m22.xy) + float2(0.5);
                                float2 _6189 = floor(_6188);
                                float2 _6194 = _6188 - _6189;
                                float2 _6197 = _6189 - float2(0.5);
                                bool _6201 = _6165 == 1;
                                if (_6201)
                                {
                                    float2 _6204 = _6194 * 2.0;
                                    _6149[0] = float2(3.0) - _6204;
                                    _6149[1] = float2(1.0) + _6204;
                                    _6150[0] = ((float2(2.0) - _6194) / _6149[0]) - float2(1.0);
                                    _6150[1] = (_6194 / _6149[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _6231 = _6194 * 3.0;
                                    _6149[0] = float2(4.0) - _6231;
                                    _6149[1] = float2(7.0);
                                    _6149[2] = float2(1.0) + _6231;
                                    _6150[0] = ((float2(3.0) - (_6194 * 2.0)) / _6149[0]) - float2(2.0);
                                    _6150[1] = (float2(3.0) + _6194) / _6149[1];
                                    _6150[2] = (_6194 / _6149[2]) + float2(2.0);
                                }
                                int _7479 = _6201 ? 2 : 3;
                                int _7094;
                                float _7097;
                                _7097 = 0.0;
                                _7094 = 0;
                                float _7103;
                                for (; _7094 < _7479; _7097 = _7103, _7094++)
                                {
                                    _7103 = _7097;
                                    for (int _7100 = 0; _7100 < _7479; )
                                    {
                                        _7103 += ((_6149[_7100].x * _6149[_7094].y) * spvDepthCast(_520).sample_compare(_520Smplr, float3(fast::clamp(_502._m22.xy * (_6197 + float2(_6150[_7100].x, _6150[_7094].y)), _6139.xy, _6139.zw), _5955).xy, _5955));
                                        _7100++;
                                        continue;
                                    }
                                }
                                _7104 = _7097 * (_6201 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _7105 = _7104;
                            break;
                        }
                        uint _5965 = _5760 - _5861;
                        if (_5965 >= uint(_502._m21.w))
                        {
                            _7105 = 1.0;
                            break;
                        }
                        float _5986 = _502._m27[_5965].w * length(in.m_1758 - _502._m27[_5965].xyz);
                        float3 _6004 = ((in.m_1758 + (_2278 * (_5986 * _502._m25.x))) + (_5794 * (_5986 * _502._m25.y))) - _502._m27[_5965].xyz;
                        float3 _6006 = abs(_6004);
                        float _6008 = _6006.x;
                        float _6010 = _6006.y;
                        bool _6011 = _6008 >= _6010;
                        bool _6019;
                        if (_6011)
                        {
                            _6019 = _6008 >= _6006.z;
                        }
                        else
                        {
                            _6019 = _6011;
                        }
                        float _7079;
                        int _7081;
                        if (_6019)
                        {
                            _7081 = (_6004.x > 0.0) ? 0 : 1;
                            _7079 = _6008;
                        }
                        else
                        {
                            float _6031 = _6006.z;
                            bool _6032 = _6010 >= _6031;
                            int _7082;
                            if (_6032)
                            {
                                _7082 = (_6004.y > 0.0) ? 2 : 3;
                            }
                            else
                            {
                                _7082 = (_6004.z > 0.0) ? 4 : 5;
                            }
                            _7081 = _7082;
                            _7079 = _6032 ? _6010 : _6031;
                        }
                        if (_7079 <= 0.0)
                        {
                            _7105 = 1.0;
                            break;
                        }
                        float2 _6069 = float2(dot(_6004, _1169[_7081]), dot(_6004, _1178[_7081])) / float2(_7079 * _502._m24.z);
                        float _6076 = _502._m28[_5965].z + (_502._m28[_5965].w / _7079);
                        if (_6076 > 1.0)
                        {
                            _7105 = 1.0;
                            break;
                        }
                        float2 _6094 = _502._m28[_5965].xy + (float2(float(spvSMod(_7081, 3)), float(_7081 / 3)) * _502._m24.xy);
                        float2 _6334 = _502._m22.xy * 0.5;
                        float2 _6339 = _6094 + (float2(0.5 + (0.5 * _6069.x), 0.5 - (0.5 * _6069.y)) * _502._m24.xy);
                        float4 _6352 = float4(_6094 + _6334, (_6094 + _502._m24.xy) - _6334);
                        float _7093;
                        do
                        {
                            int _6378 = int(_502._m22.z);
                            if (_6378 <= 0)
                            {
                                _7093 = spvDepthCast(_520).sample_compare(_520Smplr, float3(fast::clamp(_6339, _6352.xy, _6352.zw), _6076).xy, _6076);
                                break;
                            }
                            float2 _6401 = (_6339 / _502._m22.xy) + float2(0.5);
                            float2 _6402 = floor(_6401);
                            float2 _6407 = _6401 - _6402;
                            float2 _6410 = _6402 - float2(0.5);
                            bool _6414 = _6378 == 1;
                            if (_6414)
                            {
                                float2 _6417 = _6407 * 2.0;
                                _6362[0] = float2(3.0) - _6417;
                                _6362[1] = float2(1.0) + _6417;
                                _6363[0] = ((float2(2.0) - _6407) / _6362[0]) - float2(1.0);
                                _6363[1] = (_6407 / _6362[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _6444 = _6407 * 3.0;
                                _6362[0] = float2(4.0) - _6444;
                                _6362[1] = float2(7.0);
                                _6362[2] = float2(1.0) + _6444;
                                _6363[0] = ((float2(3.0) - (_6407 * 2.0)) / _6362[0]) - float2(2.0);
                                _6363[1] = (float2(3.0) + _6407) / _6362[1];
                                _6363[2] = (_6407 / _6362[2]) + float2(2.0);
                            }
                            int _7482 = _6414 ? 2 : 3;
                            int _7083;
                            float _7086;
                            _7086 = 0.0;
                            _7083 = 0;
                            float _7092;
                            for (; _7083 < _7482; _7086 = _7092, _7083++)
                            {
                                _7092 = _7086;
                                for (int _7089 = 0; _7089 < _7482; )
                                {
                                    _7092 += ((_6362[_7089].x * _6362[_7083].y) * spvDepthCast(_520).sample_compare(_520Smplr, float3(fast::clamp(_502._m22.xy * (_6410 + float2(_6363[_7089].x, _6363[_7083].y)), _6352.xy, _6352.zw), _6076).xy, _6076));
                                    _7089++;
                                    continue;
                                }
                            }
                            _7093 = _7086 * (_6414 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _7105 = _7093;
                        break;
                    } while(false);
                    _7143 = _5825 * _7105;
                }
                else
                {
                    _7143 = _5825;
                }
                float3 _2672 = fast::normalize(_5794 + _2267);
                float _2677 = fast::clamp(dot(_6999, _5794), 0.0, 1.0);
                float _2682 = fast::clamp(dot(_6999, _2672), 0.0, 1.0);
                float3 _6549 = _2476 + (_4864 * powr(1.0 - fast::clamp(dot(_2267, _2672), 0.0, 1.0), 5.0));
                float _6563 = ((_2682 * _2682) * _4879) + 1.0;
                _2720 = _7145 + (((((float3(1.0) - _6549) * _2470) + ((_6549 * ((_4874 / ((3.1415927410125732421875 * _6563) * _6563)) * (0.5 / fast::max((_2677 * _4905) + (_2481 * sqrt(((_2677 * _2677) * _4901) + _4874)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875)) * _2677) * _7143);
            }
            _7190 = _7145;
        }
        else
        {
            _7190 = _2620;
        }
        _7187 = _7190;
    }
    float _2746 = -length(_2266);
    float _7228;
    if (_502._m9.w != 0.0)
    {
        float _2770 = _502._m9.w * (in.m_1758 - _502._m6.xyz).y;
        float _7225;
        if (abs(_2770) < 9.9999997473787516355514526367188e-05)
        {
            _7225 = 1.0 - (0.5 * _2770);
        }
        else
        {
            _7225 = (1.0 - exp(fast::min(-_2770, 60.0))) / _2770;
        }
        _7228 = 1.0 - exp((_2746 * (_502._m7.w * exp(fast::min((-_502._m9.w) * (_502._m6.y - _502._m6.w), 30.0)))) * _7225);
    }
    else
    {
        _7228 = 1.0 - exp(_2746 * _502._m7.w);
    }
    float3 _2821 = mix(mix(_7187, _6997, float3(_2240._m1.y)), _502._m7.xyz, float3(_7228));
    float3 _7229;
    if (_502._m33.w > 0.5)
    {
        _7229 = _2821 / (float3(1.0) + _2821);
    }
    else
    {
        _7229 = _2821;
    }
    out.m_2833 = float4(_7229, in.m_2142.w);
    float2 _7297;
    do
    {
        if (in.m_2843.w <= 0.0)
        {
            _7297 = float2(0.0);
            break;
        }
        _7297 = ((in.m_2843.xy / float2(in.m_2843.w)) - (in.m_2842.xy / float2(in.m_2842.w))) * float2(0.5, -0.5);
        break;
    } while(false);
    _2841 = _7297;
    return out;
}

