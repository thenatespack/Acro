// Generated from mesh_terrain.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: aeb73bb57e22b408
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

struct _501
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

struct _1749
{
    float4 _m0[1024];
};

struct _1784
{
    float4 _m0[1024];
};

struct _1792
{
    float4 _m0[1024];
};

struct _1889
{
    uint4 _m0[1024];
};

struct _1911
{
    uint4 _m0[1024];
};

struct _2146
{
    float4 _m0;
};

struct _2239
{
    float4 _m0;
    float4 _m1;
    float4 _m2;
    float4 _m3;
    float4 _m4;
    float4 _m5;
    float4 _m6;
};

constant spvUnsafeArray<float3, 4> _868 = spvUnsafeArray<float3, 4>({ float3(1.0, 0.449999988079071044921875, 0.449999988079071044921875), float3(0.449999988079071044921875, 1.0, 0.449999988079071044921875), float3(0.5, 0.60000002384185791015625, 1.0), float3(1.0, 1.0, 0.4000000059604644775390625) });
constant spvUnsafeArray<float3, 6> _1170 = spvUnsafeArray<float3, 6>({ float3(0.0, 0.0, 1.0), float3(0.0, 0.0, -1.0), float3(-1.0, 0.0, 0.0), float3(-1.0, 0.0, 0.0), float3(-1.0, 0.0, 0.0), float3(1.0, 0.0, 0.0) });
constant spvUnsafeArray<float3, 6> _1179 = spvUnsafeArray<float3, 6>({ float3(0.0, 1.0, 0.0), float3(0.0, 1.0, 0.0), float3(0.0, 0.0, -1.0), float3(0.0, 0.0, 1.0), float3(0.0, 1.0, 0.0), float3(0.0, 1.0, 0.0) });
constant spvUnsafeArray<int4, 6> _1585 = spvUnsafeArray<int4, 6>({ int4(0, 0, 512, 256), int4(0, 256, 256, 128), int4(256, 256, 128, 64), int4(384, 256, 64, 32), int4(448, 256, 32, 16), int4(480, 256, 16, 8) });

struct fragment_main_out
{
    float4 m_2846 [[color(0)]];
};

struct fragment_main_in
{
    float3 m_1759 [[user(locn0)]];
    float3 m_2131 [[user(locn1)]];
    float2 m_2126 [[user(locn2)]];
    float4 m_2143 [[user(locn3)]];
    float4 m_2281 [[user(locn5)]];
    float4 m_2855 [[user(locn6)]];
    float4 m_2856 [[user(locn7)]];
    float4 m_2184 [[user(locn8)]];
};

fragment fragment_main_out fragment_main(fragment_main_in in [[stage_in]], constant _2239& _2241 [[buffer(2)]], constant _1749& _1751 [[buffer(3)]], constant _1784& _1786 [[buffer(4)]], constant _1792& _1794 [[buffer(5)]], constant _1889& _1891 [[buffer(6)]], constant _1911& _1913 [[buffer(7)]], constant _501& _503 [[buffer(15)]], constant _2146& _2148 [[buffer(16)]], const device _183& _185 [[buffer(20)]], texture2d<float> _521 [[texture(0)]], texture2d<float> _380 [[texture(1)]], texture2d<float> _267 [[texture(2)]], texture2d<float> _401 [[texture(3)]], texture2d<float> _2077 [[texture(4)]], texture2d<float> _283 [[texture(5)]], texture2d<float> _1524 [[texture(6)]], texture2d<float> _1629 [[texture(7)]], sampler _521Smplr [[sampler(0)]], sampler _269 [[sampler(1)]], sampler _1631 [[sampler(7)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])
{
    float2 _2854;
    fragment_main_out out = {};
    int _2936 = int(_185._m0[0].x + 0.5);
    int _2940 = int(_185._m0[0].y + 0.5);
    float2 _2948 = (in.m_2126 * _185._m0[0].z) + float2(_185._m0[0].w);
    float4 _2900 = _267.sample(_269, _2948, level(0.0));
    float4 _6879;
    if (_2936 > 4)
    {
        _6879 = _283.sample(_269, _2948, level(0.0));
    }
    else
    {
        _6879 = float4(0.0);
    }
    float4 _2901 = _6879;
    float2 _2970 = (in.m_2126 - float2(0.5)) * _185._m0[1].xy;
    float2 _2972 = dfdx(_2970);
    float2 _2974 = dfdy(_2970);
    float3 _6884;
    float3 _6888;
    float _6891;
    _6891 = 0.0;
    _6888 = float3(0.0);
    _6884 = float3(0.0);
    float3 _7446;
    float3 _7448;
    float _7449;
    for (int _6880 = 0; _6880 < 8; _6891 = _7449, _6888 = _7448, _6884 = _7446, _6880++)
    {
        if (_6880 >= _2936)
        {
            break;
        }
        float _6881;
        if (_6880 < 4)
        {
            _6881 = _2900[_6880];
        }
        else
        {
            _6881 = _2901[_6880 - 4];
        }
        if (_6881 < 0.001953125)
        {
            _7449 = _6891;
            _7448 = _6888;
            _7446 = _6884;
            continue;
        }
        int _3004 = 3 + (_6880 / 4);
        int _3006 = spvSMod(_6880, 4);
        float2 _3014 = _2972 * ((device float*)&_185._m0[_3004])[_3006];
        float2 _3017 = _2974 * ((device float*)&_185._m0[_3004])[_3006];
        float _3120 = fast::clamp(0.5 * log2(fast::max((fast::max(dot(_3014, _3014), dot(_3017, _3017)) * _185._m0[2].w) * _185._m0[2].w, 9.9999999392252902907785028219223e-09)), 0.0, fast::max(log2(_185._m0[2].w) - 2.0, 0.0));
        float _3133 = float(_6880);
        float _3148 = (0.5 * exp2(ceil(_3120))) / _185._m0[2].w;
        float2 _3162 = (float2(mod(_3133, _185._m0[2].y), floor(_3133 / _185._m0[2].y)) + fast::clamp(fract(_2970 * ((device float*)&_185._m0[_3004])[_3006]), float2(_3148), float2(1.0 - _3148))) / _185._m0[2].yz;
        float3 _6885;
        if (((_2940 >> _6880) & 1) != 0)
        {
            float3 _3051 = (_401.sample(_269, _3162, level(_3120)).xyz * 2.0) - float3(1.0);
            float2 _3056 = _3051.xy * _185._m0[1].z;
            float3 _6692 = _3051;
            _6692.x = _3056.x;
            _6692.y = _3056.y;
            _6885 = _6692;
        }
        else
        {
            _6885 = float3(0.0, 0.0, 1.0);
        }
        _7449 = _6891 + _6881;
        _7448 = _6888 + (_6885 * _6881);
        _7446 = _6884 + (_380.sample(_269, _3162, level(_3120)).xyz * _6881);
    }
    bool _3075 = _6891 > 0.0;
    float _6895;
    if (_3075)
    {
        _6895 = 1.0 / _6891;
    }
    else
    {
        _6895 = 0.0;
    }
    float3 _6901;
    if (_3075)
    {
        _6901 = _6888 * _6895;
    }
    else
    {
        _6901 = float3(0.0, 0.0, 1.0);
    }
    float3 _2158 = in.m_2143.xyz * fast::max(_6884 * _6895, float3(0.0));
    if (_2148._m0.y > 0.5)
    {
        if (1.0 < _2148._m0.z)
        {
            discard_fragment();
        }
    }
    float3 _2182 = fast::normalize(in.m_2131);
    float3 _2193 = in.m_2184.xyz - (_2182 * dot(_2182, in.m_2184.xyz));
    bool _2198 = dot(_2193, _2193) > 9.9999999600419720025001879548654e-13;
    bool _2205;
    if (_2198)
    {
        _2205 = dot(_6901, _6901) > 9.9999999600419720025001879548654e-13;
    }
    else
    {
        _2205 = _2198;
    }
    float3 _6905;
    if (_2205)
    {
        float3 _2209 = fast::normalize(_2193);
        float3 _2221 = fast::normalize(_6901);
        _6905 = fast::normalize(((_2209 * _2221.x) + ((cross(_2182, _2209) * ((in.m_2184.w < 0.0) ? (-1.0) : 1.0)) * _2221.y)) + (_2182 * _2221.z));
    }
    else
    {
        _6905 = _2182;
    }
    bool _2244 = _2241._m5.w > 0.5;
    bool _2252;
    if (_2244)
    {
        _2252 = !gl_FrontFacing;
    }
    else
    {
        _2252 = _2244;
    }
    float3 _7015;
    if (_2252)
    {
        _7015 = -_6905;
    }
    else
    {
        _7015 = _6905;
    }
    float3 _2261 = fast::normalize(_503._m4.xyz);
    float3 _2267 = _503._m6.xyz - in.m_1759;
    float3 _2268 = fast::normalize(_2267);
    float3 _2273 = fast::normalize(_2261 + _2268);
    float3 _2279 = _2182 * (gl_FrontFacing ? 1.0 : (-1.0));
    bool _2284 = in.m_2281.x > 0.5;
    float3 _7012;
    float _7039;
    if ((_503._m5.w > 0.5) && _2284)
    {
        float _6961;
        float3 _6962;
        do
        {
            int _3183 = int(_503._m21.x);
            float _3191 = dot(_503._m20.xyz, in.m_1759) + _503._m20.w;
            int _6906;
            _6906 = 0;
            for (;;)
            {
                bool _3197 = _6906 < (_3183 - 1);
                bool _3205;
                if (_3197)
                {
                    _3205 = _3191 > _503._m16[_6906];
                }
                else
                {
                    _3205 = _3197;
                }
                if (_3205)
                {
                    _6906++;
                    continue;
                }
                else
                {
                    break;
                }
            }
            if (_3191 > _503._m16[_6906])
            {
                _6962 = float3(1.0);
                _6961 = 1.0;
                break;
            }
            float _6919;
            do
            {
                float4 _3307 = _503._m14[_6906] * float4(in.m_1759 + (_2279 * _503._m18[_6906]), 1.0);
                float _3310 = _3307.x;
                bool _3311 = _3310 < 0.0;
                bool _3318;
                if (!_3311)
                {
                    _3318 = _3310 > 1.0;
                }
                else
                {
                    _3318 = _3311;
                }
                bool _3325;
                if (!_3318)
                {
                    _3325 = _3307.y < 0.0;
                }
                else
                {
                    _3325 = _3318;
                }
                bool _3332;
                if (!_3325)
                {
                    _3332 = _3307.y > 1.0;
                }
                else
                {
                    _3332 = _3325;
                }
                if (_3332)
                {
                    _6919 = 1.0;
                    break;
                }
                float2 _3345 = float2(float(_6906 & 1), float(_6906 >> 1)) * _503._m23.xy;
                float _3352 = fast::min(_3307.z, 1.0) - _503._m19[_6906];
                float2 _3371 = _503._m22.xy * 0.5;
                float2 _3376 = _3345 + (_3307.xy * _503._m23.xy);
                float4 _3389 = float4(_3345 + _3371, (_3345 + _503._m23.xy) - _3371);
                float _6918;
                do
                {
                    int _3415 = int(_503._m22.z);
                    if (_3415 <= 0)
                    {
                        _6918 = spvDepthCast(_521).sample_compare(_521Smplr, float3(fast::clamp(_3376, _3389.xy, _3389.zw), _3352).xy, _3352);
                        break;
                    }
                    float2 _3438 = (_3376 / _503._m22.xy) + float2(0.5);
                    float2 _3439 = floor(_3438);
                    float2 _3444 = _3438 - _3439;
                    float2 _3447 = _3439 - float2(0.5);
                    bool _3451 = _3415 == 1;
                    spvUnsafeArray<float2, 3> _3399;
                    spvUnsafeArray<float2, 3> _3400;
                    if (_3451)
                    {
                        float2 _3454 = _3444 * 2.0;
                        _3399[0] = float2(3.0) - _3454;
                        _3399[1] = float2(1.0) + _3454;
                        _3400[0] = ((float2(2.0) - _3444) / _3399[0]) - float2(1.0);
                        _3400[1] = (_3444 / _3399[1]) + float2(1.0);
                    }
                    else
                    {
                        float2 _3481 = _3444 * 3.0;
                        _3399[0] = float2(4.0) - _3481;
                        _3399[1] = float2(7.0);
                        _3399[2] = float2(1.0) + _3481;
                        _3400[0] = ((float2(3.0) - (_3444 * 2.0)) / _3399[0]) - float2(2.0);
                        _3400[1] = (float2(3.0) + _3444) / _3399[1];
                        _3400[2] = (_3444 / _3399[2]) + float2(2.0);
                    }
                    int _7498 = _3451 ? 2 : 3;
                    int _6908;
                    float _6911;
                    _6911 = 0.0;
                    _6908 = 0;
                    float _6917;
                    for (; _6908 < _7498; _6911 = _6917, _6908++)
                    {
                        _6917 = _6911;
                        for (int _6914 = 0; _6914 < _7498; )
                        {
                            _6917 += ((_3399[_6914].x * _3399[_6908].y) * spvDepthCast(_521).sample_compare(_521Smplr, float3(fast::clamp(_503._m22.xy * (_3447 + float2(_3400[_6914].x, _3400[_6908].y)), _3389.xy, _3389.zw), _3352).xy, _3352));
                            _6914++;
                            continue;
                        }
                    }
                    _6918 = _6911 * (_3451 ? 0.0625 : 0.0069444444961845874786376953125);
                    break;
                } while(false);
                _6919 = _6918;
                break;
            } while(false);
            float3 _6956;
            float _6959;
            if (_3191 > _503._m17[_6906])
            {
                float _3245 = (_3191 - _503._m17[_6906]) / (_503._m16[_6906] - _503._m17[_6906]);
                int _3247 = _6906 + 1;
                float3 _6957;
                float _6960;
                if (_3247 < _3183)
                {
                    float _6939;
                    do
                    {
                        float4 _3594 = _503._m14[_3247] * float4(in.m_1759 + (_2279 * _503._m18[_3247]), 1.0);
                        float _3597 = _3594.x;
                        bool _3598 = _3597 < 0.0;
                        bool _3605;
                        if (!_3598)
                        {
                            _3605 = _3597 > 1.0;
                        }
                        else
                        {
                            _3605 = _3598;
                        }
                        bool _3612;
                        if (!_3605)
                        {
                            _3612 = _3594.y < 0.0;
                        }
                        else
                        {
                            _3612 = _3605;
                        }
                        bool _3619;
                        if (!_3612)
                        {
                            _3619 = _3594.y > 1.0;
                        }
                        else
                        {
                            _3619 = _3612;
                        }
                        if (_3619)
                        {
                            _6939 = 1.0;
                            break;
                        }
                        float2 _3632 = float2(float(_3247 & 1), float(_3247 >> 1)) * _503._m23.xy;
                        float _3639 = fast::min(_3594.z, 1.0) - _503._m19[_3247];
                        float2 _3658 = _503._m22.xy * 0.5;
                        float2 _3663 = _3632 + (_3594.xy * _503._m23.xy);
                        float4 _3676 = float4(_3632 + _3658, (_3632 + _503._m23.xy) - _3658);
                        float _6938;
                        do
                        {
                            int _3702 = int(_503._m22.z);
                            if (_3702 <= 0)
                            {
                                _6938 = spvDepthCast(_521).sample_compare(_521Smplr, float3(fast::clamp(_3663, _3676.xy, _3676.zw), _3639).xy, _3639);
                                break;
                            }
                            float2 _3725 = (_3663 / _503._m22.xy) + float2(0.5);
                            float2 _3726 = floor(_3725);
                            float2 _3731 = _3725 - _3726;
                            float2 _3734 = _3726 - float2(0.5);
                            bool _3738 = _3702 == 1;
                            spvUnsafeArray<float2, 3> _3686;
                            spvUnsafeArray<float2, 3> _3687;
                            if (_3738)
                            {
                                float2 _3741 = _3731 * 2.0;
                                _3686[0] = float2(3.0) - _3741;
                                _3686[1] = float2(1.0) + _3741;
                                _3687[0] = ((float2(2.0) - _3731) / _3686[0]) - float2(1.0);
                                _3687[1] = (_3731 / _3686[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _3768 = _3731 * 3.0;
                                _3686[0] = float2(4.0) - _3768;
                                _3686[1] = float2(7.0);
                                _3686[2] = float2(1.0) + _3768;
                                _3687[0] = ((float2(3.0) - (_3731 * 2.0)) / _3686[0]) - float2(2.0);
                                _3687[1] = (float2(3.0) + _3731) / _3686[1];
                                _3687[2] = (_3731 / _3686[2]) + float2(2.0);
                            }
                            int _7500 = _3738 ? 2 : 3;
                            int _6928;
                            float _6931;
                            _6931 = 0.0;
                            _6928 = 0;
                            float _6937;
                            for (; _6928 < _7500; _6931 = _6937, _6928++)
                            {
                                _6937 = _6931;
                                for (int _6934 = 0; _6934 < _7500; )
                                {
                                    _6937 += ((_3686[_6934].x * _3686[_6928].y) * spvDepthCast(_521).sample_compare(_521Smplr, float3(fast::clamp(_503._m22.xy * (_3734 + float2(_3687[_6934].x, _3687[_6928].y)), _3676.xy, _3676.zw), _3639).xy, _3639));
                                    _6934++;
                                    continue;
                                }
                            }
                            _6938 = _6931 * (_3738 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _6939 = _6938;
                        break;
                    } while(false);
                    _6960 = mix(_6919, _6939, _3245);
                    _6957 = mix(_868[_6906], _868[_3247], float3(_3245));
                }
                else
                {
                    _6960 = mix(_6919, 1.0, _3245);
                    _6957 = _868[_6906];
                }
                _6959 = _6960;
                _6956 = _6957;
            }
            else
            {
                _6959 = _6919;
                _6956 = _868[_6906];
            }
            _6962 = select(float3(1.0), _6956, bool3(_503._m22.w > 0.5));
            _6961 = _6959;
            break;
        } while(false);
        _7039 = _6961;
        _7012 = _2158 * _6962;
    }
    else
    {
        _7039 = 1.0;
        _7012 = _2158;
    }
    float3 _2310 = _503._m5.xyz * _503._m4.w;
    float _2317 = abs(in.m_2184.w);
    float _7105;
    if (_2317 > 0.0)
    {
        _7105 = fast::min(_2317, 1.0);
    }
    else
    {
        _7105 = 1.0;
    }
    float3 _7219;
    if (!_2244)
    {
        float _2333 = dot(_7015, _2261);
        float3 _7211;
        if (_503._m29.x > 0.5)
        {
            float _3919 = (_503._m29.z * _7015.x) - (_503._m29.w * _7015.z);
            float _3932 = (_503._m29.w * _7015.x) + (_503._m29.z * _7015.z);
            float _3950 = 1.09254801273345947265625 * _3919;
            spvUnsafeArray<float, 9> _6682 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _7015.y, 0.48860299587249755859375 * _3932, 0.48860299587249755859375 * _3919, _3950 * _7015.y, (1.09254801273345947265625 * _7015.y) * _3932, 0.3153919875621795654296875 * (((3.0 * _3932) * _3932) - 1.0), _3950 * _3932, 0.546274006366729736328125 * ((_3919 * _3919) - (_7015.y * _7015.y)) });
            spvUnsafeArray<float, 9> _3864 = _6682;
            float3 _7210;
            _7210 = float3(0.0);
            for (int _7209 = 0; _7209 < 9; )
            {
                _7210 += (_1524.read(uint2((int2(496, 256) + int2(_7209, 0))), 0).xyz * _3864[_7209]);
                _7209++;
                continue;
            }
            _7211 = fast::max(_7210, float3(0.0)) * _503._m29.y;
        }
        else
        {
            _7211 = mix(_503._m9.xyz, _503._m8.xyz, float3((_7015.y * 0.5) + 0.5)) * _503._m8.w;
        }
        float3 _2383 = (_7012 * ((_7211 * _7105) + ((_2310 * fast::max(_2333, 0.0)) * _7039))) + ((_2310 * ((powr(fast::max(dot(_7015, _2273), 0.0), _2241._m1.w) * _2241._m1.z) * step(0.0, _2333))) * _7039);
        float3 _7220;
        if (_503._m13.w > 0.5)
        {
            float2 _4035 = fast::clamp(floor(gl_FragCoord.xy * _503._m12.xy), float2(0.0), _503._m13.xy - float2(1.0));
            uint _4063 = uint((((fast::clamp(floor((log2(fast::max(dot(_503._m11.xyz, in.m_1759) + _503._m11.w, 9.9999999747524270787835121154785e-07)) * _503._m12.z) + _503._m12.w), 0.0, _503._m13.z - 1.0) * _503._m13.y) + _4035.y) * _503._m13.x) + _4035.x);
            uint _4065 = _4063 >> uint(2);
            uint _4067 = _4063 & 3u;
            uint _4071 = _1891._m0[_4065][_4067] & 65535u;
            uint _4073 = _1891._m0[_4065][_4067] >> uint(16);
            float3 _7221;
            _7221 = _2383;
            float3 _2464;
            spvUnsafeArray<float2, 3> _4481;
            spvUnsafeArray<float2, 3> _4482;
            spvUnsafeArray<float2, 3> _4694;
            spvUnsafeArray<float2, 3> _4695;
            for (uint _7218 = _4071; _7218 < (_4071 + _4073); _7221 = _2464, _7218++)
            {
                uint _4079 = _7218 / 3u;
                uint _4092 = (_1913._m0[_4079 >> uint(2)][_4079 & 3u] >> ((_7218 - (_4079 * 3u)) * 10u)) & 1023u;
                float3 _4109 = _1751._m0[_4092].xyz - in.m_1759;
                float _4112 = dot(_4109, _4109);
                float _4116 = _4112 * _1751._m0[_4092].w;
                float _4121 = fast::clamp(1.0 - (_4116 * _4116), 0.0, 1.0);
                float3 _4126 = _4109 * rsqrt(fast::max(_4112, 9.9999999392252902907785028219223e-09));
                float _4144 = fast::clamp((dot(-_4126, _1794._m0[_4092].xyz) * _1786._m0[_4092].w) + _1794._m0[_4092].w, 0.0, 1.0);
                float3 _4157 = _1786._m0[_4092].xyz * ((((_4121 * _4121) * _4144) * _4144) / fast::max(_4112, 9.9999997473787516355514526367188e-05));
                float3 _7411;
                if (_2284)
                {
                    float _7357;
                    do
                    {
                        uint _4193 = uint(_503._m21.z);
                        if (_4092 < _4193)
                        {
                            float _4215 = _503._m26[_4092].z * fast::max((_503._m15[_4092] * float4(in.m_1759, 1.0)).w, 0.0);
                            float4 _4239 = _503._m15[_4092] * float4((in.m_1759 + (_2279 * (_4215 * _503._m25.x))) + (_4126 * (_4215 * _503._m25.y)), 1.0);
                            float _4241 = _4239.w;
                            if (_4241 <= 0.0)
                            {
                                _7357 = 1.0;
                                break;
                            }
                            float3 _4250 = _4239.xyz / float3(_4241);
                            float _4252 = _4250.x;
                            bool _4253 = _4252 < 0.0;
                            bool _4260;
                            if (!_4253)
                            {
                                _4260 = _4252 > 1.0;
                            }
                            else
                            {
                                _4260 = _4253;
                            }
                            bool _4267;
                            if (!_4260)
                            {
                                _4267 = _4250.y < 0.0;
                            }
                            else
                            {
                                _4267 = _4260;
                            }
                            bool _4274;
                            if (!_4267)
                            {
                                _4274 = _4250.y > 1.0;
                            }
                            else
                            {
                                _4274 = _4267;
                            }
                            bool _4281;
                            if (!_4274)
                            {
                                _4281 = _4250.z > 1.0;
                            }
                            else
                            {
                                _4281 = _4274;
                            }
                            if (_4281)
                            {
                                _7357 = 1.0;
                                break;
                            }
                            float _4287 = _4250.z;
                            float2 _4453 = _503._m22.xy * 0.5;
                            float2 _4458 = _503._m26[_4092].xy + (_4250.xy * _503._m23.zw);
                            float4 _4471 = float4(_503._m26[_4092].xy + _4453, (_503._m26[_4092].xy + _503._m23.zw) - _4453);
                            float _7356;
                            do
                            {
                                int _4497 = int(_503._m22.z);
                                if (_4497 <= 0)
                                {
                                    float2 _4507 = fast::clamp(_4458, _4471.xy, _4471.zw);
                                    _7356 = spvDepthCast(_521).sample_compare(_521Smplr, float3(_4507, _4287).xy, _4287);
                                    break;
                                }
                                float2 _4520 = (_4458 / _503._m22.xy) + float2(0.5);
                                float2 _4521 = floor(_4520);
                                float2 _4526 = _4520 - _4521;
                                float2 _4529 = _4521 - float2(0.5);
                                bool _4533 = _4497 == 1;
                                if (_4533)
                                {
                                    float2 _4536 = _4526 * 2.0;
                                    _4481[0] = float2(3.0) - _4536;
                                    _4481[1] = float2(1.0) + _4536;
                                    _4482[0] = ((float2(2.0) - _4526) / _4481[0]) - float2(1.0);
                                    _4482[1] = (_4526 / _4481[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _4563 = _4526 * 3.0;
                                    _4481[0] = float2(4.0) - _4563;
                                    _4481[1] = float2(7.0);
                                    _4481[2] = float2(1.0) + _4563;
                                    _4482[0] = ((float2(3.0) - (_4526 * 2.0)) / _4481[0]) - float2(2.0);
                                    _4482[1] = (float2(3.0) + _4526) / _4481[1];
                                    _4482[2] = (_4526 / _4481[2]) + float2(2.0);
                                }
                                int _7505 = _4533 ? 2 : 3;
                                int _7346;
                                float _7349;
                                _7349 = 0.0;
                                _7346 = 0;
                                float _7355;
                                for (; _7346 < _7505; _7349 = _7355, _7346++)
                                {
                                    _7355 = _7349;
                                    for (int _7352 = 0; _7352 < _7505; )
                                    {
                                        _7355 += ((_4481[_7352].x * _4481[_7346].y) * spvDepthCast(_521).sample_compare(_521Smplr, float3(fast::clamp(_503._m22.xy * (_4529 + float2(_4482[_7352].x, _4482[_7346].y)), _4471.xy, _4471.zw), _4287).xy, _4287));
                                        _7352++;
                                        continue;
                                    }
                                }
                                _7356 = _7349 * (_4533 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _7357 = _7356;
                            break;
                        }
                        uint _4297 = _4092 - _4193;
                        if (_4297 >= uint(_503._m21.w))
                        {
                            _7357 = 1.0;
                            break;
                        }
                        float _4318 = _503._m27[_4297].w * length(in.m_1759 - _503._m27[_4297].xyz);
                        float3 _4336 = ((in.m_1759 + (_2279 * (_4318 * _503._m25.x))) + (_4126 * (_4318 * _503._m25.y))) - _503._m27[_4297].xyz;
                        float3 _4338 = abs(_4336);
                        float _4340 = _4338.x;
                        float _4342 = _4338.y;
                        bool _4343 = _4340 >= _4342;
                        bool _4351;
                        if (_4343)
                        {
                            _4351 = _4340 >= _4338.z;
                        }
                        else
                        {
                            _4351 = _4343;
                        }
                        float _7331;
                        int _7333;
                        if (_4351)
                        {
                            _7333 = (_4336.x > 0.0) ? 0 : 1;
                            _7331 = _4340;
                        }
                        else
                        {
                            float _4363 = _4338.z;
                            bool _4364 = _4342 >= _4363;
                            int _7334;
                            if (_4364)
                            {
                                _7334 = (_4336.y > 0.0) ? 2 : 3;
                            }
                            else
                            {
                                _7334 = (_4336.z > 0.0) ? 4 : 5;
                            }
                            _7333 = _7334;
                            _7331 = _4364 ? _4342 : _4363;
                        }
                        if (_7331 <= 0.0)
                        {
                            _7357 = 1.0;
                            break;
                        }
                        float2 _4401 = float2(dot(_4336, _1170[_7333]), dot(_4336, _1179[_7333])) / float2(_7331 * _503._m24.z);
                        float _4408 = _503._m28[_4297].z + (_503._m28[_4297].w / _7331);
                        if (_4408 > 1.0)
                        {
                            _7357 = 1.0;
                            break;
                        }
                        float2 _4426 = _503._m28[_4297].xy + (float2(float(spvSMod(_7333, 3)), float(_7333 / 3)) * _503._m24.xy);
                        float2 _4666 = _503._m22.xy * 0.5;
                        float2 _4671 = _4426 + (float2(0.5 + (0.5 * _4401.x), 0.5 - (0.5 * _4401.y)) * _503._m24.xy);
                        float4 _4684 = float4(_4426 + _4666, (_4426 + _503._m24.xy) - _4666);
                        float _7345;
                        do
                        {
                            int _4710 = int(_503._m22.z);
                            if (_4710 <= 0)
                            {
                                _7345 = spvDepthCast(_521).sample_compare(_521Smplr, float3(fast::clamp(_4671, _4684.xy, _4684.zw), _4408).xy, _4408);
                                break;
                            }
                            float2 _4733 = (_4671 / _503._m22.xy) + float2(0.5);
                            float2 _4734 = floor(_4733);
                            float2 _4739 = _4733 - _4734;
                            float2 _4742 = _4734 - float2(0.5);
                            bool _4746 = _4710 == 1;
                            if (_4746)
                            {
                                float2 _4749 = _4739 * 2.0;
                                _4694[0] = float2(3.0) - _4749;
                                _4694[1] = float2(1.0) + _4749;
                                _4695[0] = ((float2(2.0) - _4739) / _4694[0]) - float2(1.0);
                                _4695[1] = (_4739 / _4694[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _4776 = _4739 * 3.0;
                                _4694[0] = float2(4.0) - _4776;
                                _4694[1] = float2(7.0);
                                _4694[2] = float2(1.0) + _4776;
                                _4695[0] = ((float2(3.0) - (_4739 * 2.0)) / _4694[0]) - float2(2.0);
                                _4695[1] = (float2(3.0) + _4739) / _4694[1];
                                _4695[2] = (_4739 / _4694[2]) + float2(2.0);
                            }
                            int _7508 = _4746 ? 2 : 3;
                            int _7335;
                            float _7338;
                            _7338 = 0.0;
                            _7335 = 0;
                            float _7344;
                            for (; _7335 < _7508; _7338 = _7344, _7335++)
                            {
                                _7344 = _7338;
                                for (int _7341 = 0; _7341 < _7508; )
                                {
                                    _7344 += ((_4694[_7341].x * _4694[_7335].y) * spvDepthCast(_521).sample_compare(_521Smplr, float3(fast::clamp(_503._m22.xy * (_4742 + float2(_4695[_7341].x, _4695[_7335].y)), _4684.xy, _4684.zw), _4408).xy, _4408));
                                    _7341++;
                                    continue;
                                }
                            }
                            _7345 = _7338 * (_4746 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _7357 = _7345;
                        break;
                    } while(false);
                    _7411 = _4157 * _7357;
                }
                else
                {
                    _7411 = _4157;
                }
                float _2435 = dot(_7015, _4126);
                _2464 = _7221 + (((_7012 * fast::max(_2435, 0.0)) * _7411) + (_7411 * ((powr(fast::max(dot(_7015, fast::normalize(_4126 + _2268)), 0.0), _2241._m1.w) * _2241._m1.z) * step(0.0, _2435))));
            }
            _7220 = _7221;
        }
        else
        {
            _7220 = _2383;
        }
        _7219 = _7220;
    }
    else
    {
        float _2470 = fast::clamp(_185._m0[2].x, 0.0, 1.0);
        float _2474 = fast::clamp(_185._m0[1].w, 0.04500000178813934326171875, 1.0);
        float _2478 = _2474 * _2474;
        float3 _2483 = _7012 * (1.0 - _2470);
        float3 _2489 = mix(float3(0.039999999105930328369140625), _7012, float3(_2470));
        float _2494 = fast::max(dot(_7015, _2268), 9.9999997473787516355514526367188e-05);
        float _2499 = fast::clamp(dot(_7015, _2261), 0.0, 1.0);
        float _2504 = fast::clamp(dot(_7015, _2273), 0.0, 1.0);
        float3 _4878 = float3(1.0) - _2489;
        float3 _4881 = _2489 + (_4878 * powr(1.0 - fast::clamp(dot(_2268, _2273), 0.0, 1.0), 5.0));
        float _4888 = _2478 * _2478;
        float _4893 = _4888 - 1.0;
        float _4895 = ((_2504 * _2504) * _4893) + 1.0;
        float _4915 = 1.0 - _4888;
        float _4919 = sqrt(((_2494 * _2494) * _4915) + _4888);
        float3 _7058;
        float2 _7073;
        float3 _7085;
        if (_503._m29.x > 0.5)
        {
            float4 _4952 = _1629.sample(_1631, (((float2(_2494, _2474) * 31.0) + float2(0.5)) * float2(0.03125)));
            float _5011 = (_503._m29.z * _7015.x) - (_503._m29.w * _7015.z);
            float _5024 = (_503._m29.w * _7015.x) + (_503._m29.z * _7015.z);
            float _5042 = 1.09254801273345947265625 * _5011;
            spvUnsafeArray<float, 9> _6663 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _7015.y, 0.48860299587249755859375 * _5024, 0.48860299587249755859375 * _5011, _5042 * _7015.y, (1.09254801273345947265625 * _7015.y) * _5024, 0.3153919875621795654296875 * (((3.0 * _5024) * _5024) - 1.0), _5042 * _5024, 0.546274006366729736328125 * ((_5011 * _5011) - (_7015.y * _7015.y)) });
            spvUnsafeArray<float, 9> _4956 = _6663;
            float3 _7041;
            _7041 = float3(0.0);
            for (int _7040 = 0; _7040 < 9; )
            {
                _7041 += (_1524.read(uint2((int2(496, 256) + int2(_7040, 0))), 0).xyz * _4956[_7040]);
                _7040++;
                continue;
            }
            float3 _2565 = reflect(-_2268, _7015);
            float _5137 = _2565.x;
            float _5142 = _2565.z;
            float2 _5174 = float2((precise::atan2((_503._m29.z * _5137) - (_503._m29.w * _5142), -((_503._m29.w * _5137) + (_503._m29.z * _5142))) * 0.15915493667125701904296875) + 0.5, acos(fast::clamp(_2565.y, -1.0, 1.0)) * 0.3183098733425140380859375);
            float _5106 = _2474 * 5.0;
            int _5109 = min(int(_5106), 4);
            float2 _5195 = (_5174 * float2(_1585[_5109].zw)) - float2(0.5);
            float2 _5197 = floor(_5195);
            float2 _5200 = _5195 - _5197;
            int _5203 = int(_5197.x);
            int _5206 = int(_5197.y);
            int _7043;
            if (_5203 < 0)
            {
                _7043 = _5203 + _1585[_5109].z;
            }
            else
            {
                _7043 = _5203;
            }
            int _7044;
            if (_7043 >= _1585[_5109].z)
            {
                _7044 = _7043 - _1585[_5109].z;
            }
            else
            {
                _7044 = _7043;
            }
            int _5226 = _7044 + 1;
            int _7509 = (_5226 == _1585[_5109].z) ? 0 : _5226;
            int _5241 = min((_5206 + 1), (_1585[_5109].w - 1));
            int _5243 = max(_5206, 0);
            float3 _5296 = float3(_5200.x);
            int _5116 = _5109 + 1;
            float2 _5328 = (_5174 * float2(_1585[_5116].zw)) - float2(0.5);
            float2 _5330 = floor(_5328);
            float2 _5333 = _5328 - _5330;
            int _5336 = int(_5330.x);
            int _5339 = int(_5330.y);
            int _7050;
            if (_5336 < 0)
            {
                _7050 = _5336 + _1585[_5116].z;
            }
            else
            {
                _7050 = _5336;
            }
            int _7051;
            if (_7050 >= _1585[_5116].z)
            {
                _7051 = _7050 - _1585[_5116].z;
            }
            else
            {
                _7051 = _7050;
            }
            int _5359 = _7051 + 1;
            int _7510 = (_5359 == _1585[_5116].z) ? 0 : _5359;
            int _5374 = min((_5339 + 1), (_1585[_5116].w - 1));
            int _5376 = max(_5339, 0);
            float3 _5429 = float3(_5333.x);
            float3 _5131 = mix(mix(mix(_1524.read(uint2((_1585[_5109].xy + int2(_7044, _5243))), 0).xyz, _1524.read(uint2((_1585[_5109].xy + int2(_7509, _5243))), 0).xyz, _5296), mix(_1524.read(uint2((_1585[_5109].xy + int2(_7044, _5241))), 0).xyz, _1524.read(uint2((_1585[_5109].xy + int2(_7509, _5241))), 0).xyz, _5296), float3(_5200.y)), mix(mix(_1524.read(uint2((_1585[_5116].xy + int2(_7051, _5376))), 0).xyz, _1524.read(uint2((_1585[_5116].xy + int2(_7510, _5376))), 0).xyz, _5429), mix(_1524.read(uint2((_1585[_5116].xy + int2(_7051, _5374))), 0).xyz, _1524.read(uint2((_1585[_5116].xy + int2(_7510, _5374))), 0).xyz, _5429), float3(_5333.y)), float3(_5106 - float(_5109))) * _503._m29.y;
            _7085 = fast::max(_7041, float3(0.0)) * _503._m29.y;
            _7073 = _4952.xy;
            _7058 = _5131;
        }
        else
        {
            float4 _5447 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * _2474) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);
            float _5449 = _5447.x;
            float3 _5484 = mix(_503._m9.xyz, _503._m8.xyz, float3((_7015.y * 0.5) + 0.5)) * _503._m8.w;
            _7085 = _5484;
            _7073 = (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_5449 * _5449, exp2((-9.27999973297119140625) * _2494)) * _5449) + _5447.y)) + _5447.zw;
            _7058 = mix(mix(_503._m9.xyz, _503._m8.xyz, float3((reflect(-_2268, _7015).y * 0.5) + 0.5)) * _503._m8.w, _5484, float3(_2474));
        }
        bool _2591 = _2241._m6.w > 0.5;
        bool _2597;
        if (_2591)
        {
            _2597 = _503._m33.z > 0.5;
        }
        else
        {
            _2597 = _2591;
        }
        float3 _7094;
        if (_2597)
        {
            float3 _7070;
            do
            {
                float _5563 = ((_503._m32.x * (1.0 - smoothstep(_503._m33.x * 0.5, _503._m33.x, abs(dot(_503._m31.xyz, in.m_1759) - _503._m31.w)))) * smoothstep(0.5, 0.89999997615814208984375, dot(_2279, _503._m31.xyz))) * (1.0 - smoothstep(_503._m32.y * 0.5, _503._m32.y, _2474));
                if (_5563 <= 0.0)
                {
                    _7070 = _7058;
                    break;
                }
                float4 _5588 = _503._m30 * float4(in.m_1759 + ((_7015 - (_503._m31.xyz * dot(_7015, _503._m31.xyz))) * _503._m32.w), 1.0);
                float2 _5601 = ((float2(_5588.x, -_5588.y) / float2(_5588.w)) * 0.5) + float2(0.5);
                float _5605 = _503._m32.z * _2474;
                float3 _7068;
                float _7069;
                _7069 = 0.0;
                _7068 = float3(0.0);
                for (int _7067 = 0; _7067 < 12; )
                {
                    float _5612 = float(_7067);
                    float _5620 = _5612 * 2.3999631404876708984375;
                    float2 _5632 = _5601 + (float2(cos(_5620) * _503._m33.y, sin(_5620)) * (sqrt((_5612 + 0.5) * 0.083333335816860198974609375) * _5605));
                    float2 _5637 = fast::min(_5632, float2(1.0) - _5632);
                    float _5643 = smoothstep(0.0, 0.039999999105930328369140625, fast::min(_5637.x, _5637.y));
                    float4 _5651 = _2077.sample(_269, fast::clamp(_5632, float2(0.0), float2(1.0)), level(0.0));
                    float3 _5653 = _5651.xyz;
                    _7069 += (_5651.w * _5643);
                    _7068 += ((_5653 / (float3(1.0) - fast::min(_5653, float3(0.99500000476837158203125)))) * _5643);
                    _7067++;
                    continue;
                }
                _7070 = mix(_7058, (_7068 * float3(0.083333335816860198974609375)) + (_7058 * (1.0 - (_7069 * 0.083333335816860198974609375))), float3(_5563));
                break;
            } while(false);
            _7094 = _7070;
        }
        else
        {
            _7094 = _7058;
        }
        float3 _2617 = (_2489 * _7073.x) + float3(_7073.y);
        float3 _2633 = ((((((float3(1.0) - _4881) * _2483) + ((_4881 * ((_4888 / ((3.1415927410125732421875 * _4895) * _4895)) * (0.5 / fast::max((_2499 * _4919) + (_2494 * sqrt(((_2499 * _2499) * _4915) + _4888)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875)) * _2499) * _2310) * _7039) + (((((float3(1.0) - _2617) * _2483) * _7085) + (_2617 * _7094)) * _7105);
        float3 _7222;
        if (_503._m13.w > 0.5)
        {
            float2 _5717 = fast::clamp(floor(gl_FragCoord.xy * _503._m12.xy), float2(0.0), _503._m13.xy - float2(1.0));
            uint _5745 = uint((((fast::clamp(floor((log2(fast::max(dot(_503._m11.xyz, in.m_1759) + _503._m11.w, 9.9999999747524270787835121154785e-07)) * _503._m12.z) + _503._m12.w), 0.0, _503._m13.z - 1.0) * _503._m13.y) + _5717.y) * _503._m13.x) + _5717.x);
            uint _5747 = _5745 >> uint(2);
            uint _5749 = _5745 & 3u;
            uint _5753 = _1891._m0[_5747][_5749] & 65535u;
            uint _5755 = _1891._m0[_5747][_5749] >> uint(16);
            float3 _7175;
            _7175 = _2633;
            float3 _2733;
            spvUnsafeArray<float2, 3> _6163;
            spvUnsafeArray<float2, 3> _6164;
            spvUnsafeArray<float2, 3> _6376;
            spvUnsafeArray<float2, 3> _6377;
            for (uint _7108 = _5753; _7108 < (_5753 + _5755); _7175 = _2733, _7108++)
            {
                uint _5761 = _7108 / 3u;
                uint _5774 = (_1913._m0[_5761 >> uint(2)][_5761 & 3u] >> ((_7108 - (_5761 * 3u)) * 10u)) & 1023u;
                float3 _5791 = _1751._m0[_5774].xyz - in.m_1759;
                float _5794 = dot(_5791, _5791);
                float _5798 = _5794 * _1751._m0[_5774].w;
                float _5803 = fast::clamp(1.0 - (_5798 * _5798), 0.0, 1.0);
                float3 _5808 = _5791 * rsqrt(fast::max(_5794, 9.9999999392252902907785028219223e-09));
                float _5826 = fast::clamp((dot(-_5808, _1794._m0[_5774].xyz) * _1786._m0[_5774].w) + _1794._m0[_5774].w, 0.0, 1.0);
                float3 _5839 = _1786._m0[_5774].xyz * ((((_5803 * _5803) * _5826) * _5826) / fast::max(_5794, 9.9999997473787516355514526367188e-05));
                float3 _7173;
                if (_2284)
                {
                    float _7135;
                    do
                    {
                        uint _5875 = uint(_503._m21.z);
                        if (_5774 < _5875)
                        {
                            float _5897 = _503._m26[_5774].z * fast::max((_503._m15[_5774] * float4(in.m_1759, 1.0)).w, 0.0);
                            float4 _5921 = _503._m15[_5774] * float4((in.m_1759 + (_2279 * (_5897 * _503._m25.x))) + (_5808 * (_5897 * _503._m25.y)), 1.0);
                            float _5923 = _5921.w;
                            if (_5923 <= 0.0)
                            {
                                _7135 = 1.0;
                                break;
                            }
                            float3 _5932 = _5921.xyz / float3(_5923);
                            float _5934 = _5932.x;
                            bool _5935 = _5934 < 0.0;
                            bool _5942;
                            if (!_5935)
                            {
                                _5942 = _5934 > 1.0;
                            }
                            else
                            {
                                _5942 = _5935;
                            }
                            bool _5949;
                            if (!_5942)
                            {
                                _5949 = _5932.y < 0.0;
                            }
                            else
                            {
                                _5949 = _5942;
                            }
                            bool _5956;
                            if (!_5949)
                            {
                                _5956 = _5932.y > 1.0;
                            }
                            else
                            {
                                _5956 = _5949;
                            }
                            bool _5963;
                            if (!_5956)
                            {
                                _5963 = _5932.z > 1.0;
                            }
                            else
                            {
                                _5963 = _5956;
                            }
                            if (_5963)
                            {
                                _7135 = 1.0;
                                break;
                            }
                            float _5969 = _5932.z;
                            float2 _6135 = _503._m22.xy * 0.5;
                            float2 _6140 = _503._m26[_5774].xy + (_5932.xy * _503._m23.zw);
                            float4 _6153 = float4(_503._m26[_5774].xy + _6135, (_503._m26[_5774].xy + _503._m23.zw) - _6135);
                            float _7134;
                            do
                            {
                                int _6179 = int(_503._m22.z);
                                if (_6179 <= 0)
                                {
                                    float2 _6189 = fast::clamp(_6140, _6153.xy, _6153.zw);
                                    _7134 = spvDepthCast(_521).sample_compare(_521Smplr, float3(_6189, _5969).xy, _5969);
                                    break;
                                }
                                float2 _6202 = (_6140 / _503._m22.xy) + float2(0.5);
                                float2 _6203 = floor(_6202);
                                float2 _6208 = _6202 - _6203;
                                float2 _6211 = _6203 - float2(0.5);
                                bool _6215 = _6179 == 1;
                                if (_6215)
                                {
                                    float2 _6218 = _6208 * 2.0;
                                    _6163[0] = float2(3.0) - _6218;
                                    _6163[1] = float2(1.0) + _6218;
                                    _6164[0] = ((float2(2.0) - _6208) / _6163[0]) - float2(1.0);
                                    _6164[1] = (_6208 / _6163[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _6245 = _6208 * 3.0;
                                    _6163[0] = float2(4.0) - _6245;
                                    _6163[1] = float2(7.0);
                                    _6163[2] = float2(1.0) + _6245;
                                    _6164[0] = ((float2(3.0) - (_6208 * 2.0)) / _6163[0]) - float2(2.0);
                                    _6164[1] = (float2(3.0) + _6208) / _6163[1];
                                    _6164[2] = (_6208 / _6163[2]) + float2(2.0);
                                }
                                int _7512 = _6215 ? 2 : 3;
                                int _7124;
                                float _7127;
                                _7127 = 0.0;
                                _7124 = 0;
                                float _7133;
                                for (; _7124 < _7512; _7127 = _7133, _7124++)
                                {
                                    _7133 = _7127;
                                    for (int _7130 = 0; _7130 < _7512; )
                                    {
                                        _7133 += ((_6163[_7130].x * _6163[_7124].y) * spvDepthCast(_521).sample_compare(_521Smplr, float3(fast::clamp(_503._m22.xy * (_6211 + float2(_6164[_7130].x, _6164[_7124].y)), _6153.xy, _6153.zw), _5969).xy, _5969));
                                        _7130++;
                                        continue;
                                    }
                                }
                                _7134 = _7127 * (_6215 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _7135 = _7134;
                            break;
                        }
                        uint _5979 = _5774 - _5875;
                        if (_5979 >= uint(_503._m21.w))
                        {
                            _7135 = 1.0;
                            break;
                        }
                        float _6000 = _503._m27[_5979].w * length(in.m_1759 - _503._m27[_5979].xyz);
                        float3 _6018 = ((in.m_1759 + (_2279 * (_6000 * _503._m25.x))) + (_5808 * (_6000 * _503._m25.y))) - _503._m27[_5979].xyz;
                        float3 _6020 = abs(_6018);
                        float _6022 = _6020.x;
                        float _6024 = _6020.y;
                        bool _6025 = _6022 >= _6024;
                        bool _6033;
                        if (_6025)
                        {
                            _6033 = _6022 >= _6020.z;
                        }
                        else
                        {
                            _6033 = _6025;
                        }
                        float _7109;
                        int _7111;
                        if (_6033)
                        {
                            _7111 = (_6018.x > 0.0) ? 0 : 1;
                            _7109 = _6022;
                        }
                        else
                        {
                            float _6045 = _6020.z;
                            bool _6046 = _6024 >= _6045;
                            int _7112;
                            if (_6046)
                            {
                                _7112 = (_6018.y > 0.0) ? 2 : 3;
                            }
                            else
                            {
                                _7112 = (_6018.z > 0.0) ? 4 : 5;
                            }
                            _7111 = _7112;
                            _7109 = _6046 ? _6024 : _6045;
                        }
                        if (_7109 <= 0.0)
                        {
                            _7135 = 1.0;
                            break;
                        }
                        float2 _6083 = float2(dot(_6018, _1170[_7111]), dot(_6018, _1179[_7111])) / float2(_7109 * _503._m24.z);
                        float _6090 = _503._m28[_5979].z + (_503._m28[_5979].w / _7109);
                        if (_6090 > 1.0)
                        {
                            _7135 = 1.0;
                            break;
                        }
                        float2 _6108 = _503._m28[_5979].xy + (float2(float(spvSMod(_7111, 3)), float(_7111 / 3)) * _503._m24.xy);
                        float2 _6348 = _503._m22.xy * 0.5;
                        float2 _6353 = _6108 + (float2(0.5 + (0.5 * _6083.x), 0.5 - (0.5 * _6083.y)) * _503._m24.xy);
                        float4 _6366 = float4(_6108 + _6348, (_6108 + _503._m24.xy) - _6348);
                        float _7123;
                        do
                        {
                            int _6392 = int(_503._m22.z);
                            if (_6392 <= 0)
                            {
                                _7123 = spvDepthCast(_521).sample_compare(_521Smplr, float3(fast::clamp(_6353, _6366.xy, _6366.zw), _6090).xy, _6090);
                                break;
                            }
                            float2 _6415 = (_6353 / _503._m22.xy) + float2(0.5);
                            float2 _6416 = floor(_6415);
                            float2 _6421 = _6415 - _6416;
                            float2 _6424 = _6416 - float2(0.5);
                            bool _6428 = _6392 == 1;
                            if (_6428)
                            {
                                float2 _6431 = _6421 * 2.0;
                                _6376[0] = float2(3.0) - _6431;
                                _6376[1] = float2(1.0) + _6431;
                                _6377[0] = ((float2(2.0) - _6421) / _6376[0]) - float2(1.0);
                                _6377[1] = (_6421 / _6376[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _6458 = _6421 * 3.0;
                                _6376[0] = float2(4.0) - _6458;
                                _6376[1] = float2(7.0);
                                _6376[2] = float2(1.0) + _6458;
                                _6377[0] = ((float2(3.0) - (_6421 * 2.0)) / _6376[0]) - float2(2.0);
                                _6377[1] = (float2(3.0) + _6421) / _6376[1];
                                _6377[2] = (_6421 / _6376[2]) + float2(2.0);
                            }
                            int _7515 = _6428 ? 2 : 3;
                            int _7113;
                            float _7116;
                            _7116 = 0.0;
                            _7113 = 0;
                            float _7122;
                            for (; _7113 < _7515; _7116 = _7122, _7113++)
                            {
                                _7122 = _7116;
                                for (int _7119 = 0; _7119 < _7515; )
                                {
                                    _7122 += ((_6376[_7119].x * _6376[_7113].y) * spvDepthCast(_521).sample_compare(_521Smplr, float3(fast::clamp(_503._m22.xy * (_6424 + float2(_6377[_7119].x, _6377[_7113].y)), _6366.xy, _6366.zw), _6090).xy, _6090));
                                    _7119++;
                                    continue;
                                }
                            }
                            _7123 = _7116 * (_6428 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _7135 = _7123;
                        break;
                    } while(false);
                    _7173 = _5839 * _7135;
                }
                else
                {
                    _7173 = _5839;
                }
                float3 _2685 = fast::normalize(_5808 + _2268);
                float _2690 = fast::clamp(dot(_7015, _5808), 0.0, 1.0);
                float _2695 = fast::clamp(dot(_7015, _2685), 0.0, 1.0);
                float3 _6563 = _2489 + (_4878 * powr(1.0 - fast::clamp(dot(_2268, _2685), 0.0, 1.0), 5.0));
                float _6577 = ((_2695 * _2695) * _4893) + 1.0;
                _2733 = _7175 + (((((float3(1.0) - _6563) * _2483) + ((_6563 * ((_4888 / ((3.1415927410125732421875 * _6577) * _6577)) * (0.5 / fast::max((_2690 * _4919) + (_2494 * sqrt(((_2690 * _2690) * _4915) + _4888)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875)) * _2690) * _7173);
            }
            _7222 = _7175;
        }
        else
        {
            _7222 = _2633;
        }
        _7219 = _7222;
    }
    float _2759 = -length(_2267);
    float _7260;
    if (_503._m9.w != 0.0)
    {
        float _2783 = _503._m9.w * (in.m_1759 - _503._m6.xyz).y;
        float _7257;
        if (abs(_2783) < 9.9999997473787516355514526367188e-05)
        {
            _7257 = 1.0 - (0.5 * _2783);
        }
        else
        {
            _7257 = (1.0 - exp(fast::min(-_2783, 60.0))) / _2783;
        }
        _7260 = 1.0 - exp((_2759 * (_503._m7.w * exp(fast::min((-_503._m9.w) * (_503._m6.y - _503._m6.w), 30.0)))) * _7257);
    }
    else
    {
        _7260 = 1.0 - exp(_2759 * _503._m7.w);
    }
    float3 _2834 = mix(mix(_7219, _7012, float3(_2241._m1.y)), _503._m7.xyz, float3(_7260));
    float3 _7261;
    if (_503._m33.w > 0.5)
    {
        _7261 = _2834 / (float3(1.0) + _2834);
    }
    else
    {
        _7261 = _2834;
    }
    out.m_2846 = float4(_7261, in.m_2143.w);
    float2 _7330;
    do
    {
        if (in.m_2856.w <= 0.0)
        {
            _7330 = float2(0.0);
            break;
        }
        _7330 = ((in.m_2856.xy / float2(in.m_2856.w)) - (in.m_2855.xy / float2(in.m_2855.w))) * float2(0.5, -0.5);
        break;
    } while(false);
    _2854 = _7330;
    return out;
}

