// Generated from mesh_terrain.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: c3ce48d0934c4096
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
    float4 m_2941 [[color(0)]];
};

struct fragment_main_in
{
    float3 m_1759 [[user(locn0)]];
    float3 m_2131 [[user(locn1)]];
    float2 m_2126 [[user(locn2)]];
    float4 m_2143 [[user(locn3)]];
    float4 m_2294 [[user(locn5)]];
    float4 m_2950 [[user(locn6)]];
    float4 m_2951 [[user(locn7)]];
    float4 m_2184 [[user(locn8)]];
};

fragment fragment_main_out fragment_main(fragment_main_in in [[stage_in]], constant _2239& _2241 [[buffer(2)]], constant _1749& _1751 [[buffer(3)]], constant _1784& _1786 [[buffer(4)]], constant _1792& _1794 [[buffer(5)]], constant _1889& _1891 [[buffer(6)]], constant _1911& _1913 [[buffer(7)]], constant _501& _503 [[buffer(15)]], constant _2146& _2148 [[buffer(16)]], const device _183& _185 [[buffer(20)]], texture2d<float> _521 [[texture(0)]], texture2d<float> _380 [[texture(1)]], texture2d<float> _267 [[texture(2)]], texture2d<float> _401 [[texture(3)]], texture2d<float> _2077 [[texture(4)]], texture2d<float> _283 [[texture(5)]], texture2d<float> _1524 [[texture(6)]], texture2d<float> _1629 [[texture(7)]], sampler _521Smplr [[sampler(0)]], sampler _269 [[sampler(1)]], sampler _1631 [[sampler(7)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])
{
    float2 _2949;
    fragment_main_out out = {};
    int _3031 = int(_185._m0[0].x + 0.5);
    int _3035 = int(_185._m0[0].y + 0.5);
    float2 _3043 = (in.m_2126 * _185._m0[0].z) + float2(_185._m0[0].w);
    float4 _2995 = _267.sample(_269, _3043, level(0.0));
    float4 _6974;
    if (_3031 > 4)
    {
        _6974 = _283.sample(_269, _3043, level(0.0));
    }
    else
    {
        _6974 = float4(0.0);
    }
    float4 _2996 = _6974;
    float2 _3065 = (in.m_2126 - float2(0.5)) * _185._m0[1].xy;
    float2 _3067 = dfdx(_3065);
    float2 _3069 = dfdy(_3065);
    float3 _6979;
    float3 _6983;
    float _6986;
    _6986 = 0.0;
    _6983 = float3(0.0);
    _6979 = float3(0.0);
    float3 _7615;
    float3 _7617;
    float _7618;
    for (int _6975 = 0; _6975 < 8; _6986 = _7618, _6983 = _7617, _6979 = _7615, _6975++)
    {
        if (_6975 >= _3031)
        {
            break;
        }
        float _6976;
        if (_6975 < 4)
        {
            _6976 = _2995[_6975];
        }
        else
        {
            _6976 = _2996[_6975 - 4];
        }
        if (_6976 < 0.001953125)
        {
            _7618 = _6986;
            _7617 = _6983;
            _7615 = _6979;
            continue;
        }
        int _3099 = 3 + (_6975 / 4);
        int _3101 = spvSMod(_6975, 4);
        float2 _3109 = _3067 * ((device float*)&_185._m0[_3099])[_3101];
        float2 _3112 = _3069 * ((device float*)&_185._m0[_3099])[_3101];
        float _3215 = fast::clamp(0.5 * log2(fast::max((fast::max(dot(_3109, _3109), dot(_3112, _3112)) * _185._m0[2].w) * _185._m0[2].w, 9.9999999392252902907785028219223e-09)), 0.0, fast::max(log2(_185._m0[2].w) - 2.0, 0.0));
        float _3228 = float(_6975);
        float _3243 = (0.5 * exp2(ceil(_3215))) / _185._m0[2].w;
        float2 _3257 = (float2(mod(_3228, _185._m0[2].y), floor(_3228 / _185._m0[2].y)) + fast::clamp(fract(_3065 * ((device float*)&_185._m0[_3099])[_3101]), float2(_3243), float2(1.0 - _3243))) / _185._m0[2].yz;
        float3 _6980;
        if (((_3035 >> _6975) & 1) != 0)
        {
            float3 _3146 = (_401.sample(_269, _3257, level(_3215)).xyz * 2.0) - float3(1.0);
            float2 _3151 = _3146.xy * _185._m0[1].z;
            float3 _6787 = _3146;
            _6787.x = _3151.x;
            _6787.y = _3151.y;
            _6980 = _6787;
        }
        else
        {
            _6980 = float3(0.0, 0.0, 1.0);
        }
        _7618 = _6986 + _6976;
        _7617 = _6983 + (_6980 * _6976);
        _7615 = _6979 + (_380.sample(_269, _3257, level(_3215)).xyz * _6976);
    }
    bool _3170 = _6986 > 0.0;
    float _6990;
    if (_3170)
    {
        _6990 = 1.0 / _6986;
    }
    else
    {
        _6990 = 0.0;
    }
    float3 _6996;
    if (_3170)
    {
        _6996 = _6983 * _6990;
    }
    else
    {
        _6996 = float3(0.0, 0.0, 1.0);
    }
    float3 _2158 = in.m_2143.xyz * fast::max(_6979 * _6990, float3(0.0));
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
        _2205 = dot(_6996, _6996) > 9.9999999600419720025001879548654e-13;
    }
    else
    {
        _2205 = _2198;
    }
    float3 _7002;
    if (_2205)
    {
        float3 _2209 = fast::normalize(_2193);
        float3 _2221 = fast::normalize(_6996);
        _7002 = fast::normalize(((_2209 * _2221.x) + ((cross(_2182, _2209) * ((in.m_2184.w < 0.0) ? (-1.0) : 1.0)) * _2221.y)) + (_2182 * _2221.z));
    }
    else
    {
        _7002 = _2182;
    }
    bool _2244 = _2241._m5.w > 0.5;
    float _6999;
    if (_2244)
    {
        _6999 = fast::clamp(_2241._m1.z, 0.0, 1.0);
    }
    else
    {
        _6999 = 0.0;
    }
    bool _2262;
    if (_2244)
    {
        _2262 = !gl_FrontFacing;
    }
    else
    {
        _2262 = _2244;
    }
    float3 _7113;
    if (_2262 && (_6999 <= 0.0))
    {
        _7113 = -_7002;
    }
    else
    {
        _7113 = _7002;
    }
    float3 _2274 = fast::normalize(_503._m4.xyz);
    float3 _2280 = _503._m6.xyz - in.m_1759;
    float3 _2281 = fast::normalize(_2280);
    float3 _2286 = fast::normalize(_2274 + _2281);
    float3 _2292 = _2182 * (gl_FrontFacing ? 1.0 : (-1.0));
    bool _2297 = in.m_2294.x > 0.5;
    float3 _7110;
    float _7145;
    if ((_503._m5.w > 0.5) && _2297)
    {
        float _7058;
        float3 _7059;
        do
        {
            int _3278 = int(_503._m21.x);
            float _3286 = dot(_503._m20.xyz, in.m_1759) + _503._m20.w;
            int _7003;
            _7003 = 0;
            for (;;)
            {
                bool _3292 = _7003 < (_3278 - 1);
                bool _3300;
                if (_3292)
                {
                    _3300 = _3286 > _503._m16[_7003];
                }
                else
                {
                    _3300 = _3292;
                }
                if (_3300)
                {
                    _7003++;
                    continue;
                }
                else
                {
                    break;
                }
            }
            if (_3286 > _503._m16[_7003])
            {
                _7059 = float3(1.0);
                _7058 = 1.0;
                break;
            }
            float _7016;
            do
            {
                float4 _3402 = _503._m14[_7003] * float4(in.m_1759 + (_2292 * _503._m18[_7003]), 1.0);
                float _3405 = _3402.x;
                bool _3406 = _3405 < 0.0;
                bool _3413;
                if (!_3406)
                {
                    _3413 = _3405 > 1.0;
                }
                else
                {
                    _3413 = _3406;
                }
                bool _3420;
                if (!_3413)
                {
                    _3420 = _3402.y < 0.0;
                }
                else
                {
                    _3420 = _3413;
                }
                bool _3427;
                if (!_3420)
                {
                    _3427 = _3402.y > 1.0;
                }
                else
                {
                    _3427 = _3420;
                }
                if (_3427)
                {
                    _7016 = 1.0;
                    break;
                }
                float2 _3440 = float2(float(_7003 & 1), float(_7003 >> 1)) * _503._m23.xy;
                float _3447 = fast::min(_3402.z, 1.0) - _503._m19[_7003];
                float2 _3466 = _503._m22.xy * 0.5;
                float2 _3471 = _3440 + (_3402.xy * _503._m23.xy);
                float4 _3484 = float4(_3440 + _3466, (_3440 + _503._m23.xy) - _3466);
                float _7015;
                do
                {
                    int _3510 = int(_503._m22.z);
                    if (_3510 <= 0)
                    {
                        _7015 = spvDepthCast(_521).sample_compare(_521Smplr, float3(fast::clamp(_3471, _3484.xy, _3484.zw), _3447).xy, _3447);
                        break;
                    }
                    float2 _3533 = (_3471 / _503._m22.xy) + float2(0.5);
                    float2 _3534 = floor(_3533);
                    float2 _3539 = _3533 - _3534;
                    float2 _3542 = _3534 - float2(0.5);
                    bool _3546 = _3510 == 1;
                    spvUnsafeArray<float2, 3> _3494;
                    spvUnsafeArray<float2, 3> _3495;
                    if (_3546)
                    {
                        float2 _3549 = _3539 * 2.0;
                        _3494[0] = float2(3.0) - _3549;
                        _3494[1] = float2(1.0) + _3549;
                        _3495[0] = ((float2(2.0) - _3539) / _3494[0]) - float2(1.0);
                        _3495[1] = (_3539 / _3494[1]) + float2(1.0);
                    }
                    else
                    {
                        float2 _3576 = _3539 * 3.0;
                        _3494[0] = float2(4.0) - _3576;
                        _3494[1] = float2(7.0);
                        _3494[2] = float2(1.0) + _3576;
                        _3495[0] = ((float2(3.0) - (_3539 * 2.0)) / _3494[0]) - float2(2.0);
                        _3495[1] = (float2(3.0) + _3539) / _3494[1];
                        _3495[2] = (_3539 / _3494[2]) + float2(2.0);
                    }
                    int _7667 = _3546 ? 2 : 3;
                    int _7005;
                    float _7008;
                    _7008 = 0.0;
                    _7005 = 0;
                    float _7014;
                    for (; _7005 < _7667; _7008 = _7014, _7005++)
                    {
                        _7014 = _7008;
                        for (int _7011 = 0; _7011 < _7667; )
                        {
                            _7014 += ((_3494[_7011].x * _3494[_7005].y) * spvDepthCast(_521).sample_compare(_521Smplr, float3(fast::clamp(_503._m22.xy * (_3542 + float2(_3495[_7011].x, _3495[_7005].y)), _3484.xy, _3484.zw), _3447).xy, _3447));
                            _7011++;
                            continue;
                        }
                    }
                    _7015 = _7008 * (_3546 ? 0.0625 : 0.0069444444961845874786376953125);
                    break;
                } while(false);
                _7016 = _7015;
                break;
            } while(false);
            float3 _7053;
            float _7056;
            if (_3286 > _503._m17[_7003])
            {
                float _3340 = (_3286 - _503._m17[_7003]) / (_503._m16[_7003] - _503._m17[_7003]);
                int _3342 = _7003 + 1;
                float3 _7054;
                float _7057;
                if (_3342 < _3278)
                {
                    float _7036;
                    do
                    {
                        float4 _3689 = _503._m14[_3342] * float4(in.m_1759 + (_2292 * _503._m18[_3342]), 1.0);
                        float _3692 = _3689.x;
                        bool _3693 = _3692 < 0.0;
                        bool _3700;
                        if (!_3693)
                        {
                            _3700 = _3692 > 1.0;
                        }
                        else
                        {
                            _3700 = _3693;
                        }
                        bool _3707;
                        if (!_3700)
                        {
                            _3707 = _3689.y < 0.0;
                        }
                        else
                        {
                            _3707 = _3700;
                        }
                        bool _3714;
                        if (!_3707)
                        {
                            _3714 = _3689.y > 1.0;
                        }
                        else
                        {
                            _3714 = _3707;
                        }
                        if (_3714)
                        {
                            _7036 = 1.0;
                            break;
                        }
                        float2 _3727 = float2(float(_3342 & 1), float(_3342 >> 1)) * _503._m23.xy;
                        float _3734 = fast::min(_3689.z, 1.0) - _503._m19[_3342];
                        float2 _3753 = _503._m22.xy * 0.5;
                        float2 _3758 = _3727 + (_3689.xy * _503._m23.xy);
                        float4 _3771 = float4(_3727 + _3753, (_3727 + _503._m23.xy) - _3753);
                        float _7035;
                        do
                        {
                            int _3797 = int(_503._m22.z);
                            if (_3797 <= 0)
                            {
                                _7035 = spvDepthCast(_521).sample_compare(_521Smplr, float3(fast::clamp(_3758, _3771.xy, _3771.zw), _3734).xy, _3734);
                                break;
                            }
                            float2 _3820 = (_3758 / _503._m22.xy) + float2(0.5);
                            float2 _3821 = floor(_3820);
                            float2 _3826 = _3820 - _3821;
                            float2 _3829 = _3821 - float2(0.5);
                            bool _3833 = _3797 == 1;
                            spvUnsafeArray<float2, 3> _3781;
                            spvUnsafeArray<float2, 3> _3782;
                            if (_3833)
                            {
                                float2 _3836 = _3826 * 2.0;
                                _3781[0] = float2(3.0) - _3836;
                                _3781[1] = float2(1.0) + _3836;
                                _3782[0] = ((float2(2.0) - _3826) / _3781[0]) - float2(1.0);
                                _3782[1] = (_3826 / _3781[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _3863 = _3826 * 3.0;
                                _3781[0] = float2(4.0) - _3863;
                                _3781[1] = float2(7.0);
                                _3781[2] = float2(1.0) + _3863;
                                _3782[0] = ((float2(3.0) - (_3826 * 2.0)) / _3781[0]) - float2(2.0);
                                _3782[1] = (float2(3.0) + _3826) / _3781[1];
                                _3782[2] = (_3826 / _3781[2]) + float2(2.0);
                            }
                            int _7669 = _3833 ? 2 : 3;
                            int _7025;
                            float _7028;
                            _7028 = 0.0;
                            _7025 = 0;
                            float _7034;
                            for (; _7025 < _7669; _7028 = _7034, _7025++)
                            {
                                _7034 = _7028;
                                for (int _7031 = 0; _7031 < _7669; )
                                {
                                    _7034 += ((_3781[_7031].x * _3781[_7025].y) * spvDepthCast(_521).sample_compare(_521Smplr, float3(fast::clamp(_503._m22.xy * (_3829 + float2(_3782[_7031].x, _3782[_7025].y)), _3771.xy, _3771.zw), _3734).xy, _3734));
                                    _7031++;
                                    continue;
                                }
                            }
                            _7035 = _7028 * (_3833 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _7036 = _7035;
                        break;
                    } while(false);
                    _7057 = mix(_7016, _7036, _3340);
                    _7054 = mix(_868[_7003], _868[_3342], float3(_3340));
                }
                else
                {
                    _7057 = mix(_7016, 1.0, _3340);
                    _7054 = _868[_7003];
                }
                _7056 = _7057;
                _7053 = _7054;
            }
            else
            {
                _7056 = _7016;
                _7053 = _868[_7003];
            }
            _7059 = select(float3(1.0), _7053, bool3(_503._m22.w > 0.5));
            _7058 = _7056;
            break;
        } while(false);
        _7145 = _7058;
        _7110 = _2158 * _7059;
    }
    else
    {
        _7145 = 1.0;
        _7110 = _2158;
    }
    float3 _2323 = _503._m5.xyz * _503._m4.w;
    float _2330 = abs(in.m_2184.w);
    float _7221;
    if (_2330 > 0.0)
    {
        _7221 = fast::min(_2330, 1.0);
    }
    else
    {
        _7221 = 1.0;
    }
    float3 _7379;
    if (!_2244)
    {
        float _2346 = dot(_7113, _2274);
        float3 _7371;
        if (_503._m29.x > 0.5)
        {
            float _4014 = (_503._m29.z * _7113.x) - (_503._m29.w * _7113.z);
            float _4027 = (_503._m29.w * _7113.x) + (_503._m29.z * _7113.z);
            float _4045 = 1.09254801273345947265625 * _4014;
            spvUnsafeArray<float, 9> _6777 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _7113.y, 0.48860299587249755859375 * _4027, 0.48860299587249755859375 * _4014, _4045 * _7113.y, (1.09254801273345947265625 * _7113.y) * _4027, 0.3153919875621795654296875 * (((3.0 * _4027) * _4027) - 1.0), _4045 * _4027, 0.546274006366729736328125 * ((_4014 * _4014) - (_7113.y * _7113.y)) });
            spvUnsafeArray<float, 9> _3959 = _6777;
            float3 _7370;
            _7370 = float3(0.0);
            for (int _7369 = 0; _7369 < 9; )
            {
                _7370 += (_1524.read(uint2((int2(496, 256) + int2(_7369, 0))), 0).xyz * _3959[_7369]);
                _7369++;
                continue;
            }
            _7371 = fast::max(_7370, float3(0.0)) * _503._m29.y;
        }
        else
        {
            _7371 = mix(_503._m9.xyz, _503._m8.xyz, float3((_7113.y * 0.5) + 0.5)) * _503._m8.w;
        }
        float3 _2396 = (_7110 * ((_7371 * _7221) + ((_2323 * fast::max(_2346, 0.0)) * _7145))) + ((_2323 * ((powr(fast::max(dot(_7113, _2286), 0.0), _2241._m1.w) * _2241._m1.z) * step(0.0, _2346))) * _7145);
        float3 _7380;
        if (_503._m13.w > 0.5)
        {
            float2 _4130 = fast::clamp(floor(gl_FragCoord.xy * _503._m12.xy), float2(0.0), _503._m13.xy - float2(1.0));
            uint _4158 = uint((((fast::clamp(floor((log2(fast::max(dot(_503._m11.xyz, in.m_1759) + _503._m11.w, 9.9999999747524270787835121154785e-07)) * _503._m12.z) + _503._m12.w), 0.0, _503._m13.z - 1.0) * _503._m13.y) + _4130.y) * _503._m13.x) + _4130.x);
            uint _4160 = _4158 >> uint(2);
            uint _4162 = _4158 & 3u;
            uint _4166 = _1891._m0[_4160][_4162] & 65535u;
            uint _4168 = _1891._m0[_4160][_4162] >> uint(16);
            float3 _7381;
            _7381 = _2396;
            float3 _2477;
            spvUnsafeArray<float2, 3> _4576;
            spvUnsafeArray<float2, 3> _4577;
            spvUnsafeArray<float2, 3> _4789;
            spvUnsafeArray<float2, 3> _4790;
            for (uint _7378 = _4166; _7378 < (_4166 + _4168); _7381 = _2477, _7378++)
            {
                uint _4174 = _7378 / 3u;
                uint _4187 = (_1913._m0[_4174 >> uint(2)][_4174 & 3u] >> ((_7378 - (_4174 * 3u)) * 10u)) & 1023u;
                float3 _4204 = _1751._m0[_4187].xyz - in.m_1759;
                float _4207 = dot(_4204, _4204);
                float _4211 = _4207 * _1751._m0[_4187].w;
                float _4216 = fast::clamp(1.0 - (_4211 * _4211), 0.0, 1.0);
                float3 _4221 = _4204 * rsqrt(fast::max(_4207, 9.9999999392252902907785028219223e-09));
                float _4239 = fast::clamp((dot(-_4221, _1794._m0[_4187].xyz) * _1786._m0[_4187].w) + _1794._m0[_4187].w, 0.0, 1.0);
                float3 _4252 = _1786._m0[_4187].xyz * ((((_4216 * _4216) * _4239) * _4239) / fast::max(_4207, 9.9999997473787516355514526367188e-05));
                float3 _7580;
                if (_2297)
                {
                    float _7526;
                    do
                    {
                        uint _4288 = uint(_503._m21.z);
                        if (_4187 < _4288)
                        {
                            float _4310 = _503._m26[_4187].z * fast::max((_503._m15[_4187] * float4(in.m_1759, 1.0)).w, 0.0);
                            float4 _4334 = _503._m15[_4187] * float4((in.m_1759 + (_2292 * (_4310 * _503._m25.x))) + (_4221 * (_4310 * _503._m25.y)), 1.0);
                            float _4336 = _4334.w;
                            if (_4336 <= 0.0)
                            {
                                _7526 = 1.0;
                                break;
                            }
                            float3 _4345 = _4334.xyz / float3(_4336);
                            float _4347 = _4345.x;
                            bool _4348 = _4347 < 0.0;
                            bool _4355;
                            if (!_4348)
                            {
                                _4355 = _4347 > 1.0;
                            }
                            else
                            {
                                _4355 = _4348;
                            }
                            bool _4362;
                            if (!_4355)
                            {
                                _4362 = _4345.y < 0.0;
                            }
                            else
                            {
                                _4362 = _4355;
                            }
                            bool _4369;
                            if (!_4362)
                            {
                                _4369 = _4345.y > 1.0;
                            }
                            else
                            {
                                _4369 = _4362;
                            }
                            bool _4376;
                            if (!_4369)
                            {
                                _4376 = _4345.z > 1.0;
                            }
                            else
                            {
                                _4376 = _4369;
                            }
                            if (_4376)
                            {
                                _7526 = 1.0;
                                break;
                            }
                            float _4382 = _4345.z;
                            float2 _4548 = _503._m22.xy * 0.5;
                            float2 _4553 = _503._m26[_4187].xy + (_4345.xy * _503._m23.zw);
                            float4 _4566 = float4(_503._m26[_4187].xy + _4548, (_503._m26[_4187].xy + _503._m23.zw) - _4548);
                            float _7525;
                            do
                            {
                                int _4592 = int(_503._m22.z);
                                if (_4592 <= 0)
                                {
                                    float2 _4602 = fast::clamp(_4553, _4566.xy, _4566.zw);
                                    _7525 = spvDepthCast(_521).sample_compare(_521Smplr, float3(_4602, _4382).xy, _4382);
                                    break;
                                }
                                float2 _4615 = (_4553 / _503._m22.xy) + float2(0.5);
                                float2 _4616 = floor(_4615);
                                float2 _4621 = _4615 - _4616;
                                float2 _4624 = _4616 - float2(0.5);
                                bool _4628 = _4592 == 1;
                                if (_4628)
                                {
                                    float2 _4631 = _4621 * 2.0;
                                    _4576[0] = float2(3.0) - _4631;
                                    _4576[1] = float2(1.0) + _4631;
                                    _4577[0] = ((float2(2.0) - _4621) / _4576[0]) - float2(1.0);
                                    _4577[1] = (_4621 / _4576[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _4658 = _4621 * 3.0;
                                    _4576[0] = float2(4.0) - _4658;
                                    _4576[1] = float2(7.0);
                                    _4576[2] = float2(1.0) + _4658;
                                    _4577[0] = ((float2(3.0) - (_4621 * 2.0)) / _4576[0]) - float2(2.0);
                                    _4577[1] = (float2(3.0) + _4621) / _4576[1];
                                    _4577[2] = (_4621 / _4576[2]) + float2(2.0);
                                }
                                int _7674 = _4628 ? 2 : 3;
                                int _7515;
                                float _7518;
                                _7518 = 0.0;
                                _7515 = 0;
                                float _7524;
                                for (; _7515 < _7674; _7518 = _7524, _7515++)
                                {
                                    _7524 = _7518;
                                    for (int _7521 = 0; _7521 < _7674; )
                                    {
                                        _7524 += ((_4576[_7521].x * _4576[_7515].y) * spvDepthCast(_521).sample_compare(_521Smplr, float3(fast::clamp(_503._m22.xy * (_4624 + float2(_4577[_7521].x, _4577[_7515].y)), _4566.xy, _4566.zw), _4382).xy, _4382));
                                        _7521++;
                                        continue;
                                    }
                                }
                                _7525 = _7518 * (_4628 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _7526 = _7525;
                            break;
                        }
                        uint _4392 = _4187 - _4288;
                        if (_4392 >= uint(_503._m21.w))
                        {
                            _7526 = 1.0;
                            break;
                        }
                        float _4413 = _503._m27[_4392].w * length(in.m_1759 - _503._m27[_4392].xyz);
                        float3 _4431 = ((in.m_1759 + (_2292 * (_4413 * _503._m25.x))) + (_4221 * (_4413 * _503._m25.y))) - _503._m27[_4392].xyz;
                        float3 _4433 = abs(_4431);
                        float _4435 = _4433.x;
                        float _4437 = _4433.y;
                        bool _4438 = _4435 >= _4437;
                        bool _4446;
                        if (_4438)
                        {
                            _4446 = _4435 >= _4433.z;
                        }
                        else
                        {
                            _4446 = _4438;
                        }
                        float _7500;
                        int _7502;
                        if (_4446)
                        {
                            _7502 = (_4431.x > 0.0) ? 0 : 1;
                            _7500 = _4435;
                        }
                        else
                        {
                            float _4458 = _4433.z;
                            bool _4459 = _4437 >= _4458;
                            int _7503;
                            if (_4459)
                            {
                                _7503 = (_4431.y > 0.0) ? 2 : 3;
                            }
                            else
                            {
                                _7503 = (_4431.z > 0.0) ? 4 : 5;
                            }
                            _7502 = _7503;
                            _7500 = _4459 ? _4437 : _4458;
                        }
                        if (_7500 <= 0.0)
                        {
                            _7526 = 1.0;
                            break;
                        }
                        float2 _4496 = float2(dot(_4431, _1170[_7502]), dot(_4431, _1179[_7502])) / float2(_7500 * _503._m24.z);
                        float _4503 = _503._m28[_4392].z + (_503._m28[_4392].w / _7500);
                        if (_4503 > 1.0)
                        {
                            _7526 = 1.0;
                            break;
                        }
                        float2 _4521 = _503._m28[_4392].xy + (float2(float(spvSMod(_7502, 3)), float(_7502 / 3)) * _503._m24.xy);
                        float2 _4761 = _503._m22.xy * 0.5;
                        float2 _4766 = _4521 + (float2(0.5 + (0.5 * _4496.x), 0.5 - (0.5 * _4496.y)) * _503._m24.xy);
                        float4 _4779 = float4(_4521 + _4761, (_4521 + _503._m24.xy) - _4761);
                        float _7514;
                        do
                        {
                            int _4805 = int(_503._m22.z);
                            if (_4805 <= 0)
                            {
                                _7514 = spvDepthCast(_521).sample_compare(_521Smplr, float3(fast::clamp(_4766, _4779.xy, _4779.zw), _4503).xy, _4503);
                                break;
                            }
                            float2 _4828 = (_4766 / _503._m22.xy) + float2(0.5);
                            float2 _4829 = floor(_4828);
                            float2 _4834 = _4828 - _4829;
                            float2 _4837 = _4829 - float2(0.5);
                            bool _4841 = _4805 == 1;
                            if (_4841)
                            {
                                float2 _4844 = _4834 * 2.0;
                                _4789[0] = float2(3.0) - _4844;
                                _4789[1] = float2(1.0) + _4844;
                                _4790[0] = ((float2(2.0) - _4834) / _4789[0]) - float2(1.0);
                                _4790[1] = (_4834 / _4789[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _4871 = _4834 * 3.0;
                                _4789[0] = float2(4.0) - _4871;
                                _4789[1] = float2(7.0);
                                _4789[2] = float2(1.0) + _4871;
                                _4790[0] = ((float2(3.0) - (_4834 * 2.0)) / _4789[0]) - float2(2.0);
                                _4790[1] = (float2(3.0) + _4834) / _4789[1];
                                _4790[2] = (_4834 / _4789[2]) + float2(2.0);
                            }
                            int _7677 = _4841 ? 2 : 3;
                            int _7504;
                            float _7507;
                            _7507 = 0.0;
                            _7504 = 0;
                            float _7513;
                            for (; _7504 < _7677; _7507 = _7513, _7504++)
                            {
                                _7513 = _7507;
                                for (int _7510 = 0; _7510 < _7677; )
                                {
                                    _7513 += ((_4789[_7510].x * _4789[_7504].y) * spvDepthCast(_521).sample_compare(_521Smplr, float3(fast::clamp(_503._m22.xy * (_4837 + float2(_4790[_7510].x, _4790[_7504].y)), _4779.xy, _4779.zw), _4503).xy, _4503));
                                    _7510++;
                                    continue;
                                }
                            }
                            _7514 = _7507 * (_4841 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _7526 = _7514;
                        break;
                    } while(false);
                    _7580 = _4252 * _7526;
                }
                else
                {
                    _7580 = _4252;
                }
                float _2448 = dot(_7113, _4221);
                _2477 = _7381 + (((_7110 * fast::max(_2448, 0.0)) * _7580) + (_7580 * ((powr(fast::max(dot(_7113, fast::normalize(_4221 + _2281)), 0.0), _2241._m1.w) * _2241._m1.z) * step(0.0, _2448))));
            }
            _7380 = _7381;
        }
        else
        {
            _7380 = _2396;
        }
        _7379 = _7380;
    }
    else
    {
        float _2483 = fast::clamp(_185._m0[2].x, 0.0, 1.0);
        float _2487 = fast::clamp(_185._m0[1].w, 0.04500000178813934326171875, 1.0);
        float _2491 = _2487 * _2487;
        float3 _2496 = _7110 * (1.0 - _2483);
        float3 _2502 = mix(float3(0.039999999105930328369140625), _7110, float3(_2483));
        bool _2506 = _6999 > 0.0;
        float3 _7136;
        if (_2506)
        {
            float3 _2511 = dfdx(in.m_1759);
            float3 _2513 = dfdy(in.m_1759);
            float3 _2514 = cross(_2511, _2513);
            float3 _7137;
            if (dot(_2514, _2514) > 9.9999996826552253889678874634872e-21)
            {
                _7137 = fast::normalize((fast::normalize(_2514) * ((dot(_2514, _2281) < 0.0) ? (-1.0) : 1.0)) + (_7113 - _2182));
            }
            else
            {
                _7137 = _7113;
            }
            _7136 = _7137;
        }
        else
        {
            _7136 = _7113;
        }
        float _2540 = fast::max(dot(_7136, _2281), 9.9999997473787516355514526367188e-05);
        float _2549 = dot(_7136, _2274);
        float _2550 = fast::clamp(_2549, 0.0, 1.0);
        float _2555 = fast::clamp(dot(_7136, _2286), 0.0, 1.0);
        float _2560 = fast::clamp(dot(_2281, _2286), 0.0, 1.0);
        float _7140;
        float _7141;
        if (_2506)
        {
            _7141 = fast::max(_2540, 0.5);
            _7140 = fast::max(_2560, 0.5);
        }
        else
        {
            _7141 = _2540;
            _7140 = _2560;
        }
        float3 _4973 = float3(1.0) - _2502;
        float3 _4976 = _2502 + (_4973 * powr(1.0 - _7140, 5.0));
        float _4983 = _2491 * _2491;
        float _4988 = _4983 - 1.0;
        float _4990 = ((_2555 * _2555) * _4988) + 1.0;
        float _5010 = 1.0 - _4983;
        float _5014 = sqrt(((_7141 * _7141) * _5010) + _4983);
        float3 _2606 = (((((float3(1.0) - _4976) * _2496) * fast::clamp(dot(_7113, _2274), 0.0, 1.0)) + (((_4976 * ((_4983 / ((3.1415927410125732421875 * _4990) * _4990)) * (0.5 / fast::max((_2550 * _5014) + (_7141 * sqrt(((_2550 * _2550) * _5010) + _4983)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875) * _2550)) * _2323) * _7145;
        float3 _7235;
        if (_2506)
        {
            _7235 = _2606 + (((((_2496 * _2323) * _7145) * _6999) * fast::clamp(-_2549, 0.0, 1.0)) * (0.3499999940395355224609375 + (0.64999997615814208984375 * powr(fast::clamp(dot(-_2281, _2274), 0.0, 1.0), 3.0))));
        }
        else
        {
            _7235 = _2606;
        }
        float3 _7170;
        float2 _7186;
        float3 _7198;
        if (_503._m29.x > 0.5)
        {
            float4 _5047 = _1629.sample(_1631, (((float2(_7141, _2487) * 31.0) + float2(0.5)) * float2(0.03125)));
            float _5106 = (_503._m29.z * _7113.x) - (_503._m29.w * _7113.z);
            float _5119 = (_503._m29.w * _7113.x) + (_503._m29.z * _7113.z);
            float _5137 = 1.09254801273345947265625 * _5106;
            spvUnsafeArray<float, 9> _6758 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _7113.y, 0.48860299587249755859375 * _5119, 0.48860299587249755859375 * _5106, _5137 * _7113.y, (1.09254801273345947265625 * _7113.y) * _5119, 0.3153919875621795654296875 * (((3.0 * _5119) * _5119) - 1.0), _5137 * _5119, 0.546274006366729736328125 * ((_5106 * _5106) - (_7113.y * _7113.y)) });
            spvUnsafeArray<float, 9> _5051 = _6758;
            float3 _7153;
            _7153 = float3(0.0);
            for (int _7152 = 0; _7152 < 9; )
            {
                _7153 += (_1524.read(uint2((int2(496, 256) + int2(_7152, 0))), 0).xyz * _5051[_7152]);
                _7152++;
                continue;
            }
            float3 _2660 = reflect(-_2281, _7136);
            float _5232 = _2660.x;
            float _5237 = _2660.z;
            float2 _5269 = float2((precise::atan2((_503._m29.z * _5232) - (_503._m29.w * _5237), -((_503._m29.w * _5232) + (_503._m29.z * _5237))) * 0.15915493667125701904296875) + 0.5, acos(fast::clamp(_2660.y, -1.0, 1.0)) * 0.3183098733425140380859375);
            float _5201 = _2487 * 5.0;
            int _5204 = min(int(_5201), 4);
            float2 _5290 = (_5269 * float2(_1585[_5204].zw)) - float2(0.5);
            float2 _5292 = floor(_5290);
            float2 _5295 = _5290 - _5292;
            int _5298 = int(_5292.x);
            int _5301 = int(_5292.y);
            int _7155;
            if (_5298 < 0)
            {
                _7155 = _5298 + _1585[_5204].z;
            }
            else
            {
                _7155 = _5298;
            }
            int _7156;
            if (_7155 >= _1585[_5204].z)
            {
                _7156 = _7155 - _1585[_5204].z;
            }
            else
            {
                _7156 = _7155;
            }
            int _5321 = _7156 + 1;
            int _7678 = (_5321 == _1585[_5204].z) ? 0 : _5321;
            int _5336 = min((_5301 + 1), (_1585[_5204].w - 1));
            int _5338 = max(_5301, 0);
            float3 _5391 = float3(_5295.x);
            int _5211 = _5204 + 1;
            float2 _5423 = (_5269 * float2(_1585[_5211].zw)) - float2(0.5);
            float2 _5425 = floor(_5423);
            float2 _5428 = _5423 - _5425;
            int _5431 = int(_5425.x);
            int _5434 = int(_5425.y);
            int _7162;
            if (_5431 < 0)
            {
                _7162 = _5431 + _1585[_5211].z;
            }
            else
            {
                _7162 = _5431;
            }
            int _7163;
            if (_7162 >= _1585[_5211].z)
            {
                _7163 = _7162 - _1585[_5211].z;
            }
            else
            {
                _7163 = _7162;
            }
            int _5454 = _7163 + 1;
            int _7679 = (_5454 == _1585[_5211].z) ? 0 : _5454;
            int _5469 = min((_5434 + 1), (_1585[_5211].w - 1));
            int _5471 = max(_5434, 0);
            float3 _5524 = float3(_5428.x);
            float3 _5226 = mix(mix(mix(_1524.read(uint2((_1585[_5204].xy + int2(_7156, _5338))), 0).xyz, _1524.read(uint2((_1585[_5204].xy + int2(_7678, _5338))), 0).xyz, _5391), mix(_1524.read(uint2((_1585[_5204].xy + int2(_7156, _5336))), 0).xyz, _1524.read(uint2((_1585[_5204].xy + int2(_7678, _5336))), 0).xyz, _5391), float3(_5295.y)), mix(mix(_1524.read(uint2((_1585[_5211].xy + int2(_7163, _5471))), 0).xyz, _1524.read(uint2((_1585[_5211].xy + int2(_7679, _5471))), 0).xyz, _5524), mix(_1524.read(uint2((_1585[_5211].xy + int2(_7163, _5469))), 0).xyz, _1524.read(uint2((_1585[_5211].xy + int2(_7679, _5469))), 0).xyz, _5524), float3(_5428.y)), float3(_5201 - float(_5204))) * _503._m29.y;
            _7198 = fast::max(_7153, float3(0.0)) * _503._m29.y;
            _7186 = _5047.xy;
            _7170 = _5226;
        }
        else
        {
            float4 _5542 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * _2487) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);
            float _5544 = _5542.x;
            float3 _5579 = mix(_503._m9.xyz, _503._m8.xyz, float3((_7113.y * 0.5) + 0.5)) * _503._m8.w;
            _7198 = _5579;
            _7186 = (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_5544 * _5544, exp2((-9.27999973297119140625) * _7141)) * _5544) + _5542.y)) + _5542.zw;
            _7170 = mix(mix(_503._m9.xyz, _503._m8.xyz, float3((reflect(-_2281, _7136).y * 0.5) + 0.5)) * _503._m8.w, _5579, float3(_2487));
        }
        bool _2686 = _2241._m6.w > 0.5;
        bool _2692;
        if (_2686)
        {
            _2692 = _503._m33.z > 0.5;
        }
        else
        {
            _2692 = _2686;
        }
        float3 _7207;
        if (_2692)
        {
            float3 _7183;
            do
            {
                float _5658 = ((_503._m32.x * (1.0 - smoothstep(_503._m33.x * 0.5, _503._m33.x, abs(dot(_503._m31.xyz, in.m_1759) - _503._m31.w)))) * smoothstep(0.5, 0.89999997615814208984375, dot(_2292, _503._m31.xyz))) * (1.0 - smoothstep(_503._m32.y * 0.5, _503._m32.y, _2487));
                if (_5658 <= 0.0)
                {
                    _7183 = _7170;
                    break;
                }
                float4 _5683 = _503._m30 * float4(in.m_1759 + ((_7113 - (_503._m31.xyz * dot(_7113, _503._m31.xyz))) * _503._m32.w), 1.0);
                float2 _5696 = ((float2(_5683.x, -_5683.y) / float2(_5683.w)) * 0.5) + float2(0.5);
                float _5700 = _503._m32.z * _2487;
                float3 _7181;
                float _7182;
                _7182 = 0.0;
                _7181 = float3(0.0);
                for (int _7180 = 0; _7180 < 12; )
                {
                    float _5707 = float(_7180);
                    float _5715 = _5707 * 2.3999631404876708984375;
                    float2 _5727 = _5696 + (float2(cos(_5715) * _503._m33.y, sin(_5715)) * (sqrt((_5707 + 0.5) * 0.083333335816860198974609375) * _5700));
                    float2 _5732 = fast::min(_5727, float2(1.0) - _5727);
                    float _5738 = smoothstep(0.0, 0.039999999105930328369140625, fast::min(_5732.x, _5732.y));
                    float4 _5746 = _2077.sample(_269, fast::clamp(_5727, float2(0.0), float2(1.0)), level(0.0));
                    float3 _5748 = _5746.xyz;
                    _7182 += (_5746.w * _5738);
                    _7181 += ((_5748 / (float3(1.0) - fast::min(_5748, float3(0.99500000476837158203125)))) * _5738);
                    _7180++;
                    continue;
                }
                _7183 = mix(_7170, (_7181 * float3(0.083333335816860198974609375)) + (_7170 * (1.0 - (_7182 * 0.083333335816860198974609375))), float3(_5658));
                break;
            } while(false);
            _7207 = _7183;
        }
        else
        {
            _7207 = _7170;
        }
        float3 _2712 = (_2502 * _7186.x) + float3(_7186.y);
        float3 _2728 = _7235 + (((((float3(1.0) - _2712) * _2496) * _7198) + (_2712 * _7207)) * _7221);
        float3 _7382;
        if (_503._m13.w > 0.5)
        {
            float2 _5812 = fast::clamp(floor(gl_FragCoord.xy * _503._m12.xy), float2(0.0), _503._m13.xy - float2(1.0));
            uint _5840 = uint((((fast::clamp(floor((log2(fast::max(dot(_503._m11.xyz, in.m_1759) + _503._m11.w, 9.9999999747524270787835121154785e-07)) * _503._m12.z) + _503._m12.w), 0.0, _503._m13.z - 1.0) * _503._m13.y) + _5812.y) * _503._m13.x) + _5812.x);
            uint _5842 = _5840 >> uint(2);
            uint _5844 = _5840 & 3u;
            uint _5848 = _1891._m0[_5842][_5844] & 65535u;
            uint _5850 = _1891._m0[_5842][_5844] >> uint(16);
            float3 _7335;
            _7335 = _2728;
            float3 _2828;
            spvUnsafeArray<float2, 3> _6258;
            spvUnsafeArray<float2, 3> _6259;
            spvUnsafeArray<float2, 3> _6471;
            spvUnsafeArray<float2, 3> _6472;
            for (uint _7238 = _5848; _7238 < (_5848 + _5850); _7335 = _2828, _7238++)
            {
                uint _5856 = _7238 / 3u;
                uint _5869 = (_1913._m0[_5856 >> uint(2)][_5856 & 3u] >> ((_7238 - (_5856 * 3u)) * 10u)) & 1023u;
                float3 _5886 = _1751._m0[_5869].xyz - in.m_1759;
                float _5889 = dot(_5886, _5886);
                float _5893 = _5889 * _1751._m0[_5869].w;
                float _5898 = fast::clamp(1.0 - (_5893 * _5893), 0.0, 1.0);
                float3 _5903 = _5886 * rsqrt(fast::max(_5889, 9.9999999392252902907785028219223e-09));
                float _5921 = fast::clamp((dot(-_5903, _1794._m0[_5869].xyz) * _1786._m0[_5869].w) + _1794._m0[_5869].w, 0.0, 1.0);
                float3 _5934 = _1786._m0[_5869].xyz * ((((_5898 * _5898) * _5921) * _5921) / fast::max(_5889, 9.9999997473787516355514526367188e-05));
                float3 _7333;
                if (_2297)
                {
                    float _7265;
                    do
                    {
                        uint _5970 = uint(_503._m21.z);
                        if (_5869 < _5970)
                        {
                            float _5992 = _503._m26[_5869].z * fast::max((_503._m15[_5869] * float4(in.m_1759, 1.0)).w, 0.0);
                            float4 _6016 = _503._m15[_5869] * float4((in.m_1759 + (_2292 * (_5992 * _503._m25.x))) + (_5903 * (_5992 * _503._m25.y)), 1.0);
                            float _6018 = _6016.w;
                            if (_6018 <= 0.0)
                            {
                                _7265 = 1.0;
                                break;
                            }
                            float3 _6027 = _6016.xyz / float3(_6018);
                            float _6029 = _6027.x;
                            bool _6030 = _6029 < 0.0;
                            bool _6037;
                            if (!_6030)
                            {
                                _6037 = _6029 > 1.0;
                            }
                            else
                            {
                                _6037 = _6030;
                            }
                            bool _6044;
                            if (!_6037)
                            {
                                _6044 = _6027.y < 0.0;
                            }
                            else
                            {
                                _6044 = _6037;
                            }
                            bool _6051;
                            if (!_6044)
                            {
                                _6051 = _6027.y > 1.0;
                            }
                            else
                            {
                                _6051 = _6044;
                            }
                            bool _6058;
                            if (!_6051)
                            {
                                _6058 = _6027.z > 1.0;
                            }
                            else
                            {
                                _6058 = _6051;
                            }
                            if (_6058)
                            {
                                _7265 = 1.0;
                                break;
                            }
                            float _6064 = _6027.z;
                            float2 _6230 = _503._m22.xy * 0.5;
                            float2 _6235 = _503._m26[_5869].xy + (_6027.xy * _503._m23.zw);
                            float4 _6248 = float4(_503._m26[_5869].xy + _6230, (_503._m26[_5869].xy + _503._m23.zw) - _6230);
                            float _7264;
                            do
                            {
                                int _6274 = int(_503._m22.z);
                                if (_6274 <= 0)
                                {
                                    float2 _6284 = fast::clamp(_6235, _6248.xy, _6248.zw);
                                    _7264 = spvDepthCast(_521).sample_compare(_521Smplr, float3(_6284, _6064).xy, _6064);
                                    break;
                                }
                                float2 _6297 = (_6235 / _503._m22.xy) + float2(0.5);
                                float2 _6298 = floor(_6297);
                                float2 _6303 = _6297 - _6298;
                                float2 _6306 = _6298 - float2(0.5);
                                bool _6310 = _6274 == 1;
                                if (_6310)
                                {
                                    float2 _6313 = _6303 * 2.0;
                                    _6258[0] = float2(3.0) - _6313;
                                    _6258[1] = float2(1.0) + _6313;
                                    _6259[0] = ((float2(2.0) - _6303) / _6258[0]) - float2(1.0);
                                    _6259[1] = (_6303 / _6258[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _6340 = _6303 * 3.0;
                                    _6258[0] = float2(4.0) - _6340;
                                    _6258[1] = float2(7.0);
                                    _6258[2] = float2(1.0) + _6340;
                                    _6259[0] = ((float2(3.0) - (_6303 * 2.0)) / _6258[0]) - float2(2.0);
                                    _6259[1] = (float2(3.0) + _6303) / _6258[1];
                                    _6259[2] = (_6303 / _6258[2]) + float2(2.0);
                                }
                                int _7681 = _6310 ? 2 : 3;
                                int _7254;
                                float _7257;
                                _7257 = 0.0;
                                _7254 = 0;
                                float _7263;
                                for (; _7254 < _7681; _7257 = _7263, _7254++)
                                {
                                    _7263 = _7257;
                                    for (int _7260 = 0; _7260 < _7681; )
                                    {
                                        _7263 += ((_6258[_7260].x * _6258[_7254].y) * spvDepthCast(_521).sample_compare(_521Smplr, float3(fast::clamp(_503._m22.xy * (_6306 + float2(_6259[_7260].x, _6259[_7254].y)), _6248.xy, _6248.zw), _6064).xy, _6064));
                                        _7260++;
                                        continue;
                                    }
                                }
                                _7264 = _7257 * (_6310 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _7265 = _7264;
                            break;
                        }
                        uint _6074 = _5869 - _5970;
                        if (_6074 >= uint(_503._m21.w))
                        {
                            _7265 = 1.0;
                            break;
                        }
                        float _6095 = _503._m27[_6074].w * length(in.m_1759 - _503._m27[_6074].xyz);
                        float3 _6113 = ((in.m_1759 + (_2292 * (_6095 * _503._m25.x))) + (_5903 * (_6095 * _503._m25.y))) - _503._m27[_6074].xyz;
                        float3 _6115 = abs(_6113);
                        float _6117 = _6115.x;
                        float _6119 = _6115.y;
                        bool _6120 = _6117 >= _6119;
                        bool _6128;
                        if (_6120)
                        {
                            _6128 = _6117 >= _6115.z;
                        }
                        else
                        {
                            _6128 = _6120;
                        }
                        float _7239;
                        int _7241;
                        if (_6128)
                        {
                            _7241 = (_6113.x > 0.0) ? 0 : 1;
                            _7239 = _6117;
                        }
                        else
                        {
                            float _6140 = _6115.z;
                            bool _6141 = _6119 >= _6140;
                            int _7242;
                            if (_6141)
                            {
                                _7242 = (_6113.y > 0.0) ? 2 : 3;
                            }
                            else
                            {
                                _7242 = (_6113.z > 0.0) ? 4 : 5;
                            }
                            _7241 = _7242;
                            _7239 = _6141 ? _6119 : _6140;
                        }
                        if (_7239 <= 0.0)
                        {
                            _7265 = 1.0;
                            break;
                        }
                        float2 _6178 = float2(dot(_6113, _1170[_7241]), dot(_6113, _1179[_7241])) / float2(_7239 * _503._m24.z);
                        float _6185 = _503._m28[_6074].z + (_503._m28[_6074].w / _7239);
                        if (_6185 > 1.0)
                        {
                            _7265 = 1.0;
                            break;
                        }
                        float2 _6203 = _503._m28[_6074].xy + (float2(float(spvSMod(_7241, 3)), float(_7241 / 3)) * _503._m24.xy);
                        float2 _6443 = _503._m22.xy * 0.5;
                        float2 _6448 = _6203 + (float2(0.5 + (0.5 * _6178.x), 0.5 - (0.5 * _6178.y)) * _503._m24.xy);
                        float4 _6461 = float4(_6203 + _6443, (_6203 + _503._m24.xy) - _6443);
                        float _7253;
                        do
                        {
                            int _6487 = int(_503._m22.z);
                            if (_6487 <= 0)
                            {
                                _7253 = spvDepthCast(_521).sample_compare(_521Smplr, float3(fast::clamp(_6448, _6461.xy, _6461.zw), _6185).xy, _6185);
                                break;
                            }
                            float2 _6510 = (_6448 / _503._m22.xy) + float2(0.5);
                            float2 _6511 = floor(_6510);
                            float2 _6516 = _6510 - _6511;
                            float2 _6519 = _6511 - float2(0.5);
                            bool _6523 = _6487 == 1;
                            if (_6523)
                            {
                                float2 _6526 = _6516 * 2.0;
                                _6471[0] = float2(3.0) - _6526;
                                _6471[1] = float2(1.0) + _6526;
                                _6472[0] = ((float2(2.0) - _6516) / _6471[0]) - float2(1.0);
                                _6472[1] = (_6516 / _6471[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _6553 = _6516 * 3.0;
                                _6471[0] = float2(4.0) - _6553;
                                _6471[1] = float2(7.0);
                                _6471[2] = float2(1.0) + _6553;
                                _6472[0] = ((float2(3.0) - (_6516 * 2.0)) / _6471[0]) - float2(2.0);
                                _6472[1] = (float2(3.0) + _6516) / _6471[1];
                                _6472[2] = (_6516 / _6471[2]) + float2(2.0);
                            }
                            int _7684 = _6523 ? 2 : 3;
                            int _7243;
                            float _7246;
                            _7246 = 0.0;
                            _7243 = 0;
                            float _7252;
                            for (; _7243 < _7684; _7246 = _7252, _7243++)
                            {
                                _7252 = _7246;
                                for (int _7249 = 0; _7249 < _7684; )
                                {
                                    _7252 += ((_6471[_7249].x * _6471[_7243].y) * spvDepthCast(_521).sample_compare(_521Smplr, float3(fast::clamp(_503._m22.xy * (_6519 + float2(_6472[_7249].x, _6472[_7243].y)), _6461.xy, _6461.zw), _6185).xy, _6185));
                                    _7249++;
                                    continue;
                                }
                            }
                            _7253 = _7246 * (_6523 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _7265 = _7253;
                        break;
                    } while(false);
                    _7333 = _5934 * _7265;
                }
                else
                {
                    _7333 = _5934;
                }
                float3 _2780 = fast::normalize(_5903 + _2281);
                float _2785 = fast::clamp(dot(_7113, _5903), 0.0, 1.0);
                float _2790 = fast::clamp(dot(_7113, _2780), 0.0, 1.0);
                float3 _6658 = _2502 + (_4973 * powr(1.0 - fast::clamp(dot(_2281, _2780), 0.0, 1.0), 5.0));
                float _6672 = ((_2790 * _2790) * _4988) + 1.0;
                _2828 = _7335 + (((((float3(1.0) - _6658) * _2496) + ((_6658 * ((_4983 / ((3.1415927410125732421875 * _6672) * _6672)) * (0.5 / fast::max((_2785 * _5014) + (_7141 * sqrt(((_2785 * _2785) * _5010) + _4983)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875)) * _2785) * _7333);
            }
            _7382 = _7335;
        }
        else
        {
            _7382 = _2728;
        }
        _7379 = _7382;
    }
    float _2854 = -length(_2280);
    float _7424;
    if (_503._m9.w != 0.0)
    {
        float _2878 = _503._m9.w * (in.m_1759 - _503._m6.xyz).y;
        float _7421;
        if (abs(_2878) < 9.9999997473787516355514526367188e-05)
        {
            _7421 = 1.0 - (0.5 * _2878);
        }
        else
        {
            _7421 = (1.0 - exp(fast::min(-_2878, 60.0))) / _2878;
        }
        _7424 = 1.0 - exp((_2854 * (_503._m7.w * exp(fast::min((-_503._m9.w) * (_503._m6.y - _503._m6.w), 30.0)))) * _7421);
    }
    else
    {
        _7424 = 1.0 - exp(_2854 * _503._m7.w);
    }
    float3 _2929 = mix(mix(_7379, _7110, float3(_2241._m1.y)), _503._m7.xyz, float3(_7424));
    float3 _7425;
    if (_503._m33.w > 0.5)
    {
        _7425 = _2929 / (float3(1.0) + _2929);
    }
    else
    {
        _7425 = _2929;
    }
    out.m_2941 = float4(_7425, in.m_2143.w);
    float2 _7499;
    do
    {
        if (in.m_2951.w <= 0.0)
        {
            _7499 = float2(0.0);
            break;
        }
        _7499 = ((in.m_2951.xy / float2(in.m_2951.w)) - (in.m_2950.xy / float2(in.m_2950.w))) * float2(0.5, -0.5);
        break;
    } while(false);
    _2949 = _7499;
    return out;
}

