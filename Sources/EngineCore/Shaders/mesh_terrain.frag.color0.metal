// Generated from mesh_terrain.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 04e129f931f44fea
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
    float4 m_2834 [[color(0)]];
};

struct fragment_main_in
{
    float3 m_1759 [[user(locn0)]];
    float3 m_2131 [[user(locn1)]];
    float2 m_2126 [[user(locn2)]];
    float4 m_2143 [[user(locn3)]];
    float4 m_2281 [[user(locn5)]];
    float4 m_2843 [[user(locn6)]];
    float4 m_2844 [[user(locn7)]];
    float4 m_2184 [[user(locn8)]];
};

fragment fragment_main_out fragment_main(fragment_main_in in [[stage_in]], constant _2239& _2241 [[buffer(2)]], constant _1749& _1751 [[buffer(3)]], constant _1784& _1786 [[buffer(4)]], constant _1792& _1794 [[buffer(5)]], constant _1889& _1891 [[buffer(6)]], constant _1911& _1913 [[buffer(7)]], constant _501& _503 [[buffer(15)]], constant _2146& _2148 [[buffer(16)]], const device _183& _185 [[buffer(20)]], texture2d<float> _521 [[texture(0)]], texture2d<float> _380 [[texture(1)]], texture2d<float> _267 [[texture(2)]], texture2d<float> _401 [[texture(3)]], texture2d<float> _2077 [[texture(4)]], texture2d<float> _283 [[texture(5)]], texture2d<float> _1524 [[texture(6)]], texture2d<float> _1629 [[texture(7)]], sampler _521Smplr [[sampler(0)]], sampler _269 [[sampler(1)]], sampler _1631 [[sampler(7)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])
{
    float2 _2842;
    fragment_main_out out = {};
    int _2924 = int(_185._m0[0].x + 0.5);
    int _2928 = int(_185._m0[0].y + 0.5);
    float2 _2936 = (in.m_2126 * _185._m0[0].z) + float2(_185._m0[0].w);
    float4 _2888 = _267.sample(_269, _2936, level(0.0));
    float4 _6867;
    if (_2924 > 4)
    {
        _6867 = _283.sample(_269, _2936, level(0.0));
    }
    else
    {
        _6867 = float4(0.0);
    }
    float4 _2889 = _6867;
    float2 _2958 = (in.m_2126 - float2(0.5)) * _185._m0[1].xy;
    float2 _2960 = dfdx(_2958);
    float2 _2962 = dfdy(_2958);
    float3 _6872;
    float3 _6876;
    float _6879;
    _6879 = 0.0;
    _6876 = float3(0.0);
    _6872 = float3(0.0);
    float3 _7415;
    float3 _7417;
    float _7418;
    for (int _6868 = 0; _6868 < 8; _6879 = _7418, _6876 = _7417, _6872 = _7415, _6868++)
    {
        if (_6868 >= _2924)
        {
            break;
        }
        float _6869;
        if (_6868 < 4)
        {
            _6869 = _2888[_6868];
        }
        else
        {
            _6869 = _2889[_6868 - 4];
        }
        if (_6869 < 0.001953125)
        {
            _7418 = _6879;
            _7417 = _6876;
            _7415 = _6872;
            continue;
        }
        int _2992 = 3 + (_6868 / 4);
        int _2994 = spvSMod(_6868, 4);
        float2 _3002 = _2960 * ((device float*)&_185._m0[_2992])[_2994];
        float2 _3005 = _2962 * ((device float*)&_185._m0[_2992])[_2994];
        float _3108 = fast::clamp(0.5 * log2(fast::max((fast::max(dot(_3002, _3002), dot(_3005, _3005)) * _185._m0[2].w) * _185._m0[2].w, 9.9999999392252902907785028219223e-09)), 0.0, fast::max(log2(_185._m0[2].w) - 2.0, 0.0));
        float _3121 = float(_6868);
        float _3136 = (0.5 * exp2(ceil(_3108))) / _185._m0[2].w;
        float2 _3150 = (float2(mod(_3121, _185._m0[2].y), floor(_3121 / _185._m0[2].y)) + fast::clamp(fract(_2958 * ((device float*)&_185._m0[_2992])[_2994]), float2(_3136), float2(1.0 - _3136))) / _185._m0[2].yz;
        float3 _6873;
        if (((_2928 >> _6868) & 1) != 0)
        {
            float3 _3039 = (_401.sample(_269, _3150, level(_3108)).xyz * 2.0) - float3(1.0);
            float2 _3044 = _3039.xy * _185._m0[1].z;
            float3 _6680 = _3039;
            _6680.x = _3044.x;
            _6680.y = _3044.y;
            _6873 = _6680;
        }
        else
        {
            _6873 = float3(0.0, 0.0, 1.0);
        }
        _7418 = _6879 + _6869;
        _7417 = _6876 + (_6873 * _6869);
        _7415 = _6872 + (_380.sample(_269, _3150, level(_3108)).xyz * _6869);
    }
    bool _3063 = _6879 > 0.0;
    float _6883;
    if (_3063)
    {
        _6883 = 1.0 / _6879;
    }
    else
    {
        _6883 = 0.0;
    }
    float3 _6889;
    if (_3063)
    {
        _6889 = _6876 * _6883;
    }
    else
    {
        _6889 = float3(0.0, 0.0, 1.0);
    }
    float3 _2158 = in.m_2143.xyz * fast::max(_6872 * _6883, float3(0.0));
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
        _2205 = dot(_6889, _6889) > 9.9999999600419720025001879548654e-13;
    }
    else
    {
        _2205 = _2198;
    }
    float3 _6893;
    if (_2205)
    {
        float3 _2209 = fast::normalize(_2193);
        float3 _2221 = fast::normalize(_6889);
        _6893 = fast::normalize(((_2209 * _2221.x) + ((cross(_2182, _2209) * ((in.m_2184.w < 0.0) ? (-1.0) : 1.0)) * _2221.y)) + (_2182 * _2221.z));
    }
    else
    {
        _6893 = _2182;
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
    float3 _7001;
    if (_2252)
    {
        _7001 = -_6893;
    }
    else
    {
        _7001 = _6893;
    }
    float3 _2261 = fast::normalize(_503._m4.xyz);
    float3 _2267 = _503._m6.xyz - in.m_1759;
    float3 _2268 = fast::normalize(_2267);
    float3 _2273 = fast::normalize(_2261 + _2268);
    float3 _2279 = _2182 * (gl_FrontFacing ? 1.0 : (-1.0));
    bool _2284 = in.m_2281.x > 0.5;
    float3 _6999;
    float _7024;
    if ((_503._m5.w > 0.5) && _2284)
    {
        float _6949;
        float3 _6950;
        do
        {
            int _3171 = int(_503._m21.x);
            float _3179 = dot(_503._m20.xyz, in.m_1759) + _503._m20.w;
            int _6894;
            _6894 = 0;
            for (;;)
            {
                bool _3185 = _6894 < (_3171 - 1);
                bool _3193;
                if (_3185)
                {
                    _3193 = _3179 > _503._m16[_6894];
                }
                else
                {
                    _3193 = _3185;
                }
                if (_3193)
                {
                    _6894++;
                    continue;
                }
                else
                {
                    break;
                }
            }
            if (_3179 > _503._m16[_6894])
            {
                _6950 = float3(1.0);
                _6949 = 1.0;
                break;
            }
            float _6907;
            do
            {
                float4 _3295 = _503._m14[_6894] * float4(in.m_1759 + (_2279 * _503._m18[_6894]), 1.0);
                float _3298 = _3295.x;
                bool _3299 = _3298 < 0.0;
                bool _3306;
                if (!_3299)
                {
                    _3306 = _3298 > 1.0;
                }
                else
                {
                    _3306 = _3299;
                }
                bool _3313;
                if (!_3306)
                {
                    _3313 = _3295.y < 0.0;
                }
                else
                {
                    _3313 = _3306;
                }
                bool _3320;
                if (!_3313)
                {
                    _3320 = _3295.y > 1.0;
                }
                else
                {
                    _3320 = _3313;
                }
                if (_3320)
                {
                    _6907 = 1.0;
                    break;
                }
                float2 _3333 = float2(float(_6894 & 1), float(_6894 >> 1)) * _503._m23.xy;
                float _3340 = fast::min(_3295.z, 1.0) - _503._m19[_6894];
                float2 _3359 = _503._m22.xy * 0.5;
                float2 _3364 = _3333 + (_3295.xy * _503._m23.xy);
                float4 _3377 = float4(_3333 + _3359, (_3333 + _503._m23.xy) - _3359);
                float _6906;
                do
                {
                    int _3403 = int(_503._m22.z);
                    if (_3403 <= 0)
                    {
                        _6906 = spvDepthCast(_521).sample_compare(_521Smplr, float3(fast::clamp(_3364, _3377.xy, _3377.zw), _3340).xy, _3340);
                        break;
                    }
                    float2 _3426 = (_3364 / _503._m22.xy) + float2(0.5);
                    float2 _3427 = floor(_3426);
                    float2 _3432 = _3426 - _3427;
                    float2 _3435 = _3427 - float2(0.5);
                    bool _3439 = _3403 == 1;
                    spvUnsafeArray<float2, 3> _3387;
                    spvUnsafeArray<float2, 3> _3388;
                    if (_3439)
                    {
                        float2 _3442 = _3432 * 2.0;
                        _3387[0] = float2(3.0) - _3442;
                        _3387[1] = float2(1.0) + _3442;
                        _3388[0] = ((float2(2.0) - _3432) / _3387[0]) - float2(1.0);
                        _3388[1] = (_3432 / _3387[1]) + float2(1.0);
                    }
                    else
                    {
                        float2 _3469 = _3432 * 3.0;
                        _3387[0] = float2(4.0) - _3469;
                        _3387[1] = float2(7.0);
                        _3387[2] = float2(1.0) + _3469;
                        _3388[0] = ((float2(3.0) - (_3432 * 2.0)) / _3387[0]) - float2(2.0);
                        _3388[1] = (float2(3.0) + _3432) / _3387[1];
                        _3388[2] = (_3432 / _3387[2]) + float2(2.0);
                    }
                    int _7467 = _3439 ? 2 : 3;
                    int _6896;
                    float _6899;
                    _6899 = 0.0;
                    _6896 = 0;
                    float _6905;
                    for (; _6896 < _7467; _6899 = _6905, _6896++)
                    {
                        _6905 = _6899;
                        for (int _6902 = 0; _6902 < _7467; )
                        {
                            _6905 += ((_3387[_6902].x * _3387[_6896].y) * spvDepthCast(_521).sample_compare(_521Smplr, float3(fast::clamp(_503._m22.xy * (_3435 + float2(_3388[_6902].x, _3388[_6896].y)), _3377.xy, _3377.zw), _3340).xy, _3340));
                            _6902++;
                            continue;
                        }
                    }
                    _6906 = _6899 * (_3439 ? 0.0625 : 0.0069444444961845874786376953125);
                    break;
                } while(false);
                _6907 = _6906;
                break;
            } while(false);
            float3 _6944;
            float _6947;
            if (_3179 > _503._m17[_6894])
            {
                float _3233 = (_3179 - _503._m17[_6894]) / (_503._m16[_6894] - _503._m17[_6894]);
                int _3235 = _6894 + 1;
                float3 _6945;
                float _6948;
                if (_3235 < _3171)
                {
                    float _6927;
                    do
                    {
                        float4 _3582 = _503._m14[_3235] * float4(in.m_1759 + (_2279 * _503._m18[_3235]), 1.0);
                        float _3585 = _3582.x;
                        bool _3586 = _3585 < 0.0;
                        bool _3593;
                        if (!_3586)
                        {
                            _3593 = _3585 > 1.0;
                        }
                        else
                        {
                            _3593 = _3586;
                        }
                        bool _3600;
                        if (!_3593)
                        {
                            _3600 = _3582.y < 0.0;
                        }
                        else
                        {
                            _3600 = _3593;
                        }
                        bool _3607;
                        if (!_3600)
                        {
                            _3607 = _3582.y > 1.0;
                        }
                        else
                        {
                            _3607 = _3600;
                        }
                        if (_3607)
                        {
                            _6927 = 1.0;
                            break;
                        }
                        float2 _3620 = float2(float(_3235 & 1), float(_3235 >> 1)) * _503._m23.xy;
                        float _3627 = fast::min(_3582.z, 1.0) - _503._m19[_3235];
                        float2 _3646 = _503._m22.xy * 0.5;
                        float2 _3651 = _3620 + (_3582.xy * _503._m23.xy);
                        float4 _3664 = float4(_3620 + _3646, (_3620 + _503._m23.xy) - _3646);
                        float _6926;
                        do
                        {
                            int _3690 = int(_503._m22.z);
                            if (_3690 <= 0)
                            {
                                _6926 = spvDepthCast(_521).sample_compare(_521Smplr, float3(fast::clamp(_3651, _3664.xy, _3664.zw), _3627).xy, _3627);
                                break;
                            }
                            float2 _3713 = (_3651 / _503._m22.xy) + float2(0.5);
                            float2 _3714 = floor(_3713);
                            float2 _3719 = _3713 - _3714;
                            float2 _3722 = _3714 - float2(0.5);
                            bool _3726 = _3690 == 1;
                            spvUnsafeArray<float2, 3> _3674;
                            spvUnsafeArray<float2, 3> _3675;
                            if (_3726)
                            {
                                float2 _3729 = _3719 * 2.0;
                                _3674[0] = float2(3.0) - _3729;
                                _3674[1] = float2(1.0) + _3729;
                                _3675[0] = ((float2(2.0) - _3719) / _3674[0]) - float2(1.0);
                                _3675[1] = (_3719 / _3674[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _3756 = _3719 * 3.0;
                                _3674[0] = float2(4.0) - _3756;
                                _3674[1] = float2(7.0);
                                _3674[2] = float2(1.0) + _3756;
                                _3675[0] = ((float2(3.0) - (_3719 * 2.0)) / _3674[0]) - float2(2.0);
                                _3675[1] = (float2(3.0) + _3719) / _3674[1];
                                _3675[2] = (_3719 / _3674[2]) + float2(2.0);
                            }
                            int _7469 = _3726 ? 2 : 3;
                            int _6916;
                            float _6919;
                            _6919 = 0.0;
                            _6916 = 0;
                            float _6925;
                            for (; _6916 < _7469; _6919 = _6925, _6916++)
                            {
                                _6925 = _6919;
                                for (int _6922 = 0; _6922 < _7469; )
                                {
                                    _6925 += ((_3674[_6922].x * _3674[_6916].y) * spvDepthCast(_521).sample_compare(_521Smplr, float3(fast::clamp(_503._m22.xy * (_3722 + float2(_3675[_6922].x, _3675[_6916].y)), _3664.xy, _3664.zw), _3627).xy, _3627));
                                    _6922++;
                                    continue;
                                }
                            }
                            _6926 = _6919 * (_3726 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _6927 = _6926;
                        break;
                    } while(false);
                    _6948 = mix(_6907, _6927, _3233);
                    _6945 = mix(_868[_6894], _868[_3235], float3(_3233));
                }
                else
                {
                    _6948 = mix(_6907, 1.0, _3233);
                    _6945 = _868[_6894];
                }
                _6947 = _6948;
                _6944 = _6945;
            }
            else
            {
                _6947 = _6907;
                _6944 = _868[_6894];
            }
            _6950 = select(float3(1.0), _6944, bool3(_503._m22.w > 0.5));
            _6949 = _6947;
            break;
        } while(false);
        _7024 = _6949;
        _6999 = _2158 * _6950;
    }
    else
    {
        _7024 = 1.0;
        _6999 = _2158;
    }
    float3 _2310 = _503._m5.xyz * _503._m4.w;
    float3 _7189;
    if (!_2244)
    {
        float _2321 = dot(_7001, _2261);
        float3 _7183;
        if (_503._m29.x > 0.5)
        {
            float _3907 = (_503._m29.z * _7001.x) - (_503._m29.w * _7001.z);
            float _3920 = (_503._m29.w * _7001.x) + (_503._m29.z * _7001.z);
            float _3938 = 1.09254801273345947265625 * _3907;
            spvUnsafeArray<float, 9> _6670 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _7001.y, 0.48860299587249755859375 * _3920, 0.48860299587249755859375 * _3907, _3938 * _7001.y, (1.09254801273345947265625 * _7001.y) * _3920, 0.3153919875621795654296875 * (((3.0 * _3920) * _3920) - 1.0), _3938 * _3920, 0.546274006366729736328125 * ((_3907 * _3907) - (_7001.y * _7001.y)) });
            spvUnsafeArray<float, 9> _3852 = _6670;
            float3 _7182;
            _7182 = float3(0.0);
            for (int _7181 = 0; _7181 < 9; )
            {
                _7182 += (_1524.read(uint2((int2(496, 256) + int2(_7181, 0))), 0).xyz * _3852[_7181]);
                _7181++;
                continue;
            }
            _7183 = fast::max(_7182, float3(0.0)) * _503._m29.y;
        }
        else
        {
            _7183 = mix(_503._m9.xyz, _503._m8.xyz, float3((_7001.y * 0.5) + 0.5)) * _503._m8.w;
        }
        float3 _2371 = (_6999 * ((_7183 * 1.0) + ((_2310 * fast::max(_2321, 0.0)) * _7024))) + ((_2310 * ((powr(fast::max(dot(_7001, _2273), 0.0), _2241._m1.w) * _2241._m1.z) * step(0.0, _2321))) * _7024);
        float3 _7190;
        if (_503._m13.w > 0.5)
        {
            float2 _4023 = fast::clamp(floor(gl_FragCoord.xy * _503._m12.xy), float2(0.0), _503._m13.xy - float2(1.0));
            uint _4051 = uint((((fast::clamp(floor((log2(fast::max(dot(_503._m11.xyz, in.m_1759) + _503._m11.w, 9.9999999747524270787835121154785e-07)) * _503._m12.z) + _503._m12.w), 0.0, _503._m13.z - 1.0) * _503._m13.y) + _4023.y) * _503._m13.x) + _4023.x);
            uint _4053 = _4051 >> uint(2);
            uint _4055 = _4051 & 3u;
            uint _4059 = _1891._m0[_4053][_4055] & 65535u;
            uint _4061 = _1891._m0[_4053][_4055] >> uint(16);
            float3 _7191;
            _7191 = _2371;
            float3 _2452;
            spvUnsafeArray<float2, 3> _4469;
            spvUnsafeArray<float2, 3> _4470;
            spvUnsafeArray<float2, 3> _4682;
            spvUnsafeArray<float2, 3> _4683;
            for (uint _7188 = _4059; _7188 < (_4059 + _4061); _7191 = _2452, _7188++)
            {
                uint _4067 = _7188 / 3u;
                uint _4080 = (_1913._m0[_4067 >> uint(2)][_4067 & 3u] >> ((_7188 - (_4067 * 3u)) * 10u)) & 1023u;
                float3 _4097 = _1751._m0[_4080].xyz - in.m_1759;
                float _4100 = dot(_4097, _4097);
                float _4104 = _4100 * _1751._m0[_4080].w;
                float _4109 = fast::clamp(1.0 - (_4104 * _4104), 0.0, 1.0);
                float3 _4114 = _4097 * rsqrt(fast::max(_4100, 9.9999999392252902907785028219223e-09));
                float _4132 = fast::clamp((dot(-_4114, _1794._m0[_4080].xyz) * _1786._m0[_4080].w) + _1794._m0[_4080].w, 0.0, 1.0);
                float3 _4145 = _1786._m0[_4080].xyz * ((((_4109 * _4109) * _4132) * _4132) / fast::max(_4100, 9.9999997473787516355514526367188e-05));
                float3 _7380;
                if (_2284)
                {
                    float _7326;
                    do
                    {
                        uint _4181 = uint(_503._m21.z);
                        if (_4080 < _4181)
                        {
                            float _4203 = _503._m26[_4080].z * fast::max((_503._m15[_4080] * float4(in.m_1759, 1.0)).w, 0.0);
                            float4 _4227 = _503._m15[_4080] * float4((in.m_1759 + (_2279 * (_4203 * _503._m25.x))) + (_4114 * (_4203 * _503._m25.y)), 1.0);
                            float _4229 = _4227.w;
                            if (_4229 <= 0.0)
                            {
                                _7326 = 1.0;
                                break;
                            }
                            float3 _4238 = _4227.xyz / float3(_4229);
                            float _4240 = _4238.x;
                            bool _4241 = _4240 < 0.0;
                            bool _4248;
                            if (!_4241)
                            {
                                _4248 = _4240 > 1.0;
                            }
                            else
                            {
                                _4248 = _4241;
                            }
                            bool _4255;
                            if (!_4248)
                            {
                                _4255 = _4238.y < 0.0;
                            }
                            else
                            {
                                _4255 = _4248;
                            }
                            bool _4262;
                            if (!_4255)
                            {
                                _4262 = _4238.y > 1.0;
                            }
                            else
                            {
                                _4262 = _4255;
                            }
                            bool _4269;
                            if (!_4262)
                            {
                                _4269 = _4238.z > 1.0;
                            }
                            else
                            {
                                _4269 = _4262;
                            }
                            if (_4269)
                            {
                                _7326 = 1.0;
                                break;
                            }
                            float _4275 = _4238.z;
                            float2 _4441 = _503._m22.xy * 0.5;
                            float2 _4446 = _503._m26[_4080].xy + (_4238.xy * _503._m23.zw);
                            float4 _4459 = float4(_503._m26[_4080].xy + _4441, (_503._m26[_4080].xy + _503._m23.zw) - _4441);
                            float _7325;
                            do
                            {
                                int _4485 = int(_503._m22.z);
                                if (_4485 <= 0)
                                {
                                    float2 _4495 = fast::clamp(_4446, _4459.xy, _4459.zw);
                                    _7325 = spvDepthCast(_521).sample_compare(_521Smplr, float3(_4495, _4275).xy, _4275);
                                    break;
                                }
                                float2 _4508 = (_4446 / _503._m22.xy) + float2(0.5);
                                float2 _4509 = floor(_4508);
                                float2 _4514 = _4508 - _4509;
                                float2 _4517 = _4509 - float2(0.5);
                                bool _4521 = _4485 == 1;
                                if (_4521)
                                {
                                    float2 _4524 = _4514 * 2.0;
                                    _4469[0] = float2(3.0) - _4524;
                                    _4469[1] = float2(1.0) + _4524;
                                    _4470[0] = ((float2(2.0) - _4514) / _4469[0]) - float2(1.0);
                                    _4470[1] = (_4514 / _4469[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _4551 = _4514 * 3.0;
                                    _4469[0] = float2(4.0) - _4551;
                                    _4469[1] = float2(7.0);
                                    _4469[2] = float2(1.0) + _4551;
                                    _4470[0] = ((float2(3.0) - (_4514 * 2.0)) / _4469[0]) - float2(2.0);
                                    _4470[1] = (float2(3.0) + _4514) / _4469[1];
                                    _4470[2] = (_4514 / _4469[2]) + float2(2.0);
                                }
                                int _7474 = _4521 ? 2 : 3;
                                int _7315;
                                float _7318;
                                _7318 = 0.0;
                                _7315 = 0;
                                float _7324;
                                for (; _7315 < _7474; _7318 = _7324, _7315++)
                                {
                                    _7324 = _7318;
                                    for (int _7321 = 0; _7321 < _7474; )
                                    {
                                        _7324 += ((_4469[_7321].x * _4469[_7315].y) * spvDepthCast(_521).sample_compare(_521Smplr, float3(fast::clamp(_503._m22.xy * (_4517 + float2(_4470[_7321].x, _4470[_7315].y)), _4459.xy, _4459.zw), _4275).xy, _4275));
                                        _7321++;
                                        continue;
                                    }
                                }
                                _7325 = _7318 * (_4521 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _7326 = _7325;
                            break;
                        }
                        uint _4285 = _4080 - _4181;
                        if (_4285 >= uint(_503._m21.w))
                        {
                            _7326 = 1.0;
                            break;
                        }
                        float _4306 = _503._m27[_4285].w * length(in.m_1759 - _503._m27[_4285].xyz);
                        float3 _4324 = ((in.m_1759 + (_2279 * (_4306 * _503._m25.x))) + (_4114 * (_4306 * _503._m25.y))) - _503._m27[_4285].xyz;
                        float3 _4326 = abs(_4324);
                        float _4328 = _4326.x;
                        float _4330 = _4326.y;
                        bool _4331 = _4328 >= _4330;
                        bool _4339;
                        if (_4331)
                        {
                            _4339 = _4328 >= _4326.z;
                        }
                        else
                        {
                            _4339 = _4331;
                        }
                        float _7300;
                        int _7302;
                        if (_4339)
                        {
                            _7302 = (_4324.x > 0.0) ? 0 : 1;
                            _7300 = _4328;
                        }
                        else
                        {
                            float _4351 = _4326.z;
                            bool _4352 = _4330 >= _4351;
                            int _7303;
                            if (_4352)
                            {
                                _7303 = (_4324.y > 0.0) ? 2 : 3;
                            }
                            else
                            {
                                _7303 = (_4324.z > 0.0) ? 4 : 5;
                            }
                            _7302 = _7303;
                            _7300 = _4352 ? _4330 : _4351;
                        }
                        if (_7300 <= 0.0)
                        {
                            _7326 = 1.0;
                            break;
                        }
                        float2 _4389 = float2(dot(_4324, _1170[_7302]), dot(_4324, _1179[_7302])) / float2(_7300 * _503._m24.z);
                        float _4396 = _503._m28[_4285].z + (_503._m28[_4285].w / _7300);
                        if (_4396 > 1.0)
                        {
                            _7326 = 1.0;
                            break;
                        }
                        float2 _4414 = _503._m28[_4285].xy + (float2(float(spvSMod(_7302, 3)), float(_7302 / 3)) * _503._m24.xy);
                        float2 _4654 = _503._m22.xy * 0.5;
                        float2 _4659 = _4414 + (float2(0.5 + (0.5 * _4389.x), 0.5 - (0.5 * _4389.y)) * _503._m24.xy);
                        float4 _4672 = float4(_4414 + _4654, (_4414 + _503._m24.xy) - _4654);
                        float _7314;
                        do
                        {
                            int _4698 = int(_503._m22.z);
                            if (_4698 <= 0)
                            {
                                _7314 = spvDepthCast(_521).sample_compare(_521Smplr, float3(fast::clamp(_4659, _4672.xy, _4672.zw), _4396).xy, _4396);
                                break;
                            }
                            float2 _4721 = (_4659 / _503._m22.xy) + float2(0.5);
                            float2 _4722 = floor(_4721);
                            float2 _4727 = _4721 - _4722;
                            float2 _4730 = _4722 - float2(0.5);
                            bool _4734 = _4698 == 1;
                            if (_4734)
                            {
                                float2 _4737 = _4727 * 2.0;
                                _4682[0] = float2(3.0) - _4737;
                                _4682[1] = float2(1.0) + _4737;
                                _4683[0] = ((float2(2.0) - _4727) / _4682[0]) - float2(1.0);
                                _4683[1] = (_4727 / _4682[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _4764 = _4727 * 3.0;
                                _4682[0] = float2(4.0) - _4764;
                                _4682[1] = float2(7.0);
                                _4682[2] = float2(1.0) + _4764;
                                _4683[0] = ((float2(3.0) - (_4727 * 2.0)) / _4682[0]) - float2(2.0);
                                _4683[1] = (float2(3.0) + _4727) / _4682[1];
                                _4683[2] = (_4727 / _4682[2]) + float2(2.0);
                            }
                            int _7477 = _4734 ? 2 : 3;
                            int _7304;
                            float _7307;
                            _7307 = 0.0;
                            _7304 = 0;
                            float _7313;
                            for (; _7304 < _7477; _7307 = _7313, _7304++)
                            {
                                _7313 = _7307;
                                for (int _7310 = 0; _7310 < _7477; )
                                {
                                    _7313 += ((_4682[_7310].x * _4682[_7304].y) * spvDepthCast(_521).sample_compare(_521Smplr, float3(fast::clamp(_503._m22.xy * (_4730 + float2(_4683[_7310].x, _4683[_7304].y)), _4672.xy, _4672.zw), _4396).xy, _4396));
                                    _7310++;
                                    continue;
                                }
                            }
                            _7314 = _7307 * (_4734 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _7326 = _7314;
                        break;
                    } while(false);
                    _7380 = _4145 * _7326;
                }
                else
                {
                    _7380 = _4145;
                }
                float _2423 = dot(_7001, _4114);
                _2452 = _7191 + (((_6999 * fast::max(_2423, 0.0)) * _7380) + (_7380 * ((powr(fast::max(dot(_7001, fast::normalize(_4114 + _2268)), 0.0), _2241._m1.w) * _2241._m1.z) * step(0.0, _2423))));
            }
            _7190 = _7191;
        }
        else
        {
            _7190 = _2371;
        }
        _7189 = _7190;
    }
    else
    {
        float _2458 = fast::clamp(_185._m0[2].x, 0.0, 1.0);
        float _2462 = fast::clamp(_185._m0[1].w, 0.04500000178813934326171875, 1.0);
        float _2466 = _2462 * _2462;
        float3 _2471 = _6999 * (1.0 - _2458);
        float3 _2477 = mix(float3(0.039999999105930328369140625), _6999, float3(_2458));
        float _2482 = fast::max(dot(_7001, _2268), 9.9999997473787516355514526367188e-05);
        float _2487 = fast::clamp(dot(_7001, _2261), 0.0, 1.0);
        float _2492 = fast::clamp(dot(_7001, _2273), 0.0, 1.0);
        float3 _4866 = float3(1.0) - _2477;
        float3 _4869 = _2477 + (_4866 * powr(1.0 - fast::clamp(dot(_2268, _2273), 0.0, 1.0), 5.0));
        float _4876 = _2466 * _2466;
        float _4881 = _4876 - 1.0;
        float _4883 = ((_2492 * _2492) * _4881) + 1.0;
        float _4903 = 1.0 - _4876;
        float _4907 = sqrt(((_2482 * _2482) * _4903) + _4876);
        float3 _7043;
        float2 _7058;
        float3 _7070;
        if (_503._m29.x > 0.5)
        {
            float4 _4940 = _1629.sample(_1631, (((float2(_2482, _2462) * 31.0) + float2(0.5)) * float2(0.03125)));
            float _4999 = (_503._m29.z * _7001.x) - (_503._m29.w * _7001.z);
            float _5012 = (_503._m29.w * _7001.x) + (_503._m29.z * _7001.z);
            float _5030 = 1.09254801273345947265625 * _4999;
            spvUnsafeArray<float, 9> _6651 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _7001.y, 0.48860299587249755859375 * _5012, 0.48860299587249755859375 * _4999, _5030 * _7001.y, (1.09254801273345947265625 * _7001.y) * _5012, 0.3153919875621795654296875 * (((3.0 * _5012) * _5012) - 1.0), _5030 * _5012, 0.546274006366729736328125 * ((_4999 * _4999) - (_7001.y * _7001.y)) });
            spvUnsafeArray<float, 9> _4944 = _6651;
            float3 _7026;
            _7026 = float3(0.0);
            for (int _7025 = 0; _7025 < 9; )
            {
                _7026 += (_1524.read(uint2((int2(496, 256) + int2(_7025, 0))), 0).xyz * _4944[_7025]);
                _7025++;
                continue;
            }
            float3 _2553 = reflect(-_2268, _7001);
            float _5125 = _2553.x;
            float _5130 = _2553.z;
            float2 _5162 = float2((precise::atan2((_503._m29.z * _5125) - (_503._m29.w * _5130), -((_503._m29.w * _5125) + (_503._m29.z * _5130))) * 0.15915493667125701904296875) + 0.5, acos(fast::clamp(_2553.y, -1.0, 1.0)) * 0.3183098733425140380859375);
            float _5094 = _2462 * 5.0;
            int _5097 = min(int(_5094), 4);
            float2 _5183 = (_5162 * float2(_1585[_5097].zw)) - float2(0.5);
            float2 _5185 = floor(_5183);
            float2 _5188 = _5183 - _5185;
            int _5191 = int(_5185.x);
            int _5194 = int(_5185.y);
            int _7028;
            if (_5191 < 0)
            {
                _7028 = _5191 + _1585[_5097].z;
            }
            else
            {
                _7028 = _5191;
            }
            int _7029;
            if (_7028 >= _1585[_5097].z)
            {
                _7029 = _7028 - _1585[_5097].z;
            }
            else
            {
                _7029 = _7028;
            }
            int _5214 = _7029 + 1;
            int _7478 = (_5214 == _1585[_5097].z) ? 0 : _5214;
            int _5229 = min((_5194 + 1), (_1585[_5097].w - 1));
            int _5231 = max(_5194, 0);
            float3 _5284 = float3(_5188.x);
            int _5104 = _5097 + 1;
            float2 _5316 = (_5162 * float2(_1585[_5104].zw)) - float2(0.5);
            float2 _5318 = floor(_5316);
            float2 _5321 = _5316 - _5318;
            int _5324 = int(_5318.x);
            int _5327 = int(_5318.y);
            int _7035;
            if (_5324 < 0)
            {
                _7035 = _5324 + _1585[_5104].z;
            }
            else
            {
                _7035 = _5324;
            }
            int _7036;
            if (_7035 >= _1585[_5104].z)
            {
                _7036 = _7035 - _1585[_5104].z;
            }
            else
            {
                _7036 = _7035;
            }
            int _5347 = _7036 + 1;
            int _7479 = (_5347 == _1585[_5104].z) ? 0 : _5347;
            int _5362 = min((_5327 + 1), (_1585[_5104].w - 1));
            int _5364 = max(_5327, 0);
            float3 _5417 = float3(_5321.x);
            float3 _5119 = mix(mix(mix(_1524.read(uint2((_1585[_5097].xy + int2(_7029, _5231))), 0).xyz, _1524.read(uint2((_1585[_5097].xy + int2(_7478, _5231))), 0).xyz, _5284), mix(_1524.read(uint2((_1585[_5097].xy + int2(_7029, _5229))), 0).xyz, _1524.read(uint2((_1585[_5097].xy + int2(_7478, _5229))), 0).xyz, _5284), float3(_5188.y)), mix(mix(_1524.read(uint2((_1585[_5104].xy + int2(_7036, _5364))), 0).xyz, _1524.read(uint2((_1585[_5104].xy + int2(_7479, _5364))), 0).xyz, _5417), mix(_1524.read(uint2((_1585[_5104].xy + int2(_7036, _5362))), 0).xyz, _1524.read(uint2((_1585[_5104].xy + int2(_7479, _5362))), 0).xyz, _5417), float3(_5321.y)), float3(_5094 - float(_5097))) * _503._m29.y;
            _7070 = fast::max(_7026, float3(0.0)) * _503._m29.y;
            _7058 = _4940.xy;
            _7043 = _5119;
        }
        else
        {
            float4 _5435 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * _2462) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);
            float _5437 = _5435.x;
            float3 _5472 = mix(_503._m9.xyz, _503._m8.xyz, float3((_7001.y * 0.5) + 0.5)) * _503._m8.w;
            _7070 = _5472;
            _7058 = (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_5437 * _5437, exp2((-9.27999973297119140625) * _2482)) * _5437) + _5435.y)) + _5435.zw;
            _7043 = mix(mix(_503._m9.xyz, _503._m8.xyz, float3((reflect(-_2268, _7001).y * 0.5) + 0.5)) * _503._m8.w, _5472, float3(_2462));
        }
        bool _2579 = _2241._m6.w > 0.5;
        bool _2585;
        if (_2579)
        {
            _2585 = _503._m33.z > 0.5;
        }
        else
        {
            _2585 = _2579;
        }
        float3 _7079;
        if (_2585)
        {
            float3 _7055;
            do
            {
                float _5551 = ((_503._m32.x * (1.0 - smoothstep(_503._m33.x * 0.5, _503._m33.x, abs(dot(_503._m31.xyz, in.m_1759) - _503._m31.w)))) * smoothstep(0.5, 0.89999997615814208984375, dot(_2279, _503._m31.xyz))) * (1.0 - smoothstep(_503._m32.y * 0.5, _503._m32.y, _2462));
                if (_5551 <= 0.0)
                {
                    _7055 = _7043;
                    break;
                }
                float4 _5576 = _503._m30 * float4(in.m_1759 + ((_7001 - (_503._m31.xyz * dot(_7001, _503._m31.xyz))) * _503._m32.w), 1.0);
                float2 _5589 = ((float2(_5576.x, -_5576.y) / float2(_5576.w)) * 0.5) + float2(0.5);
                float _5593 = _503._m32.z * _2462;
                float3 _7053;
                float _7054;
                _7054 = 0.0;
                _7053 = float3(0.0);
                for (int _7052 = 0; _7052 < 12; )
                {
                    float _5600 = float(_7052);
                    float _5608 = _5600 * 2.3999631404876708984375;
                    float2 _5620 = _5589 + (float2(cos(_5608) * _503._m33.y, sin(_5608)) * (sqrt((_5600 + 0.5) * 0.083333335816860198974609375) * _5593));
                    float2 _5625 = fast::min(_5620, float2(1.0) - _5620);
                    float _5631 = smoothstep(0.0, 0.039999999105930328369140625, fast::min(_5625.x, _5625.y));
                    float4 _5639 = _2077.sample(_269, fast::clamp(_5620, float2(0.0), float2(1.0)), level(0.0));
                    float3 _5641 = _5639.xyz;
                    _7054 += (_5639.w * _5631);
                    _7053 += ((_5641 / (float3(1.0) - fast::min(_5641, float3(0.99500000476837158203125)))) * _5631);
                    _7052++;
                    continue;
                }
                _7055 = mix(_7043, (_7053 * float3(0.083333335816860198974609375)) + (_7043 * (1.0 - (_7054 * 0.083333335816860198974609375))), float3(_5551));
                break;
            } while(false);
            _7079 = _7055;
        }
        else
        {
            _7079 = _7043;
        }
        float3 _2605 = (_2477 * _7058.x) + float3(_7058.y);
        float3 _2621 = ((((((float3(1.0) - _4869) * _2471) + ((_4869 * ((_4876 / ((3.1415927410125732421875 * _4883) * _4883)) * (0.5 / fast::max((_2487 * _4907) + (_2482 * sqrt(((_2487 * _2487) * _4903) + _4876)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875)) * _2487) * _2310) * _7024) + (((((float3(1.0) - _2605) * _2471) * _7070) + (_2605 * _7079)) * 1.0);
        float3 _7192;
        if (_503._m13.w > 0.5)
        {
            float2 _5705 = fast::clamp(floor(gl_FragCoord.xy * _503._m12.xy), float2(0.0), _503._m13.xy - float2(1.0));
            uint _5733 = uint((((fast::clamp(floor((log2(fast::max(dot(_503._m11.xyz, in.m_1759) + _503._m11.w, 9.9999999747524270787835121154785e-07)) * _503._m12.z) + _503._m12.w), 0.0, _503._m13.z - 1.0) * _503._m13.y) + _5705.y) * _503._m13.x) + _5705.x);
            uint _5735 = _5733 >> uint(2);
            uint _5737 = _5733 & 3u;
            uint _5741 = _1891._m0[_5735][_5737] & 65535u;
            uint _5743 = _1891._m0[_5735][_5737] >> uint(16);
            float3 _7147;
            _7147 = _2621;
            float3 _2721;
            spvUnsafeArray<float2, 3> _6151;
            spvUnsafeArray<float2, 3> _6152;
            spvUnsafeArray<float2, 3> _6364;
            spvUnsafeArray<float2, 3> _6365;
            for (uint _7080 = _5741; _7080 < (_5741 + _5743); _7147 = _2721, _7080++)
            {
                uint _5749 = _7080 / 3u;
                uint _5762 = (_1913._m0[_5749 >> uint(2)][_5749 & 3u] >> ((_7080 - (_5749 * 3u)) * 10u)) & 1023u;
                float3 _5779 = _1751._m0[_5762].xyz - in.m_1759;
                float _5782 = dot(_5779, _5779);
                float _5786 = _5782 * _1751._m0[_5762].w;
                float _5791 = fast::clamp(1.0 - (_5786 * _5786), 0.0, 1.0);
                float3 _5796 = _5779 * rsqrt(fast::max(_5782, 9.9999999392252902907785028219223e-09));
                float _5814 = fast::clamp((dot(-_5796, _1794._m0[_5762].xyz) * _1786._m0[_5762].w) + _1794._m0[_5762].w, 0.0, 1.0);
                float3 _5827 = _1786._m0[_5762].xyz * ((((_5791 * _5791) * _5814) * _5814) / fast::max(_5782, 9.9999997473787516355514526367188e-05));
                float3 _7145;
                if (_2284)
                {
                    float _7107;
                    do
                    {
                        uint _5863 = uint(_503._m21.z);
                        if (_5762 < _5863)
                        {
                            float _5885 = _503._m26[_5762].z * fast::max((_503._m15[_5762] * float4(in.m_1759, 1.0)).w, 0.0);
                            float4 _5909 = _503._m15[_5762] * float4((in.m_1759 + (_2279 * (_5885 * _503._m25.x))) + (_5796 * (_5885 * _503._m25.y)), 1.0);
                            float _5911 = _5909.w;
                            if (_5911 <= 0.0)
                            {
                                _7107 = 1.0;
                                break;
                            }
                            float3 _5920 = _5909.xyz / float3(_5911);
                            float _5922 = _5920.x;
                            bool _5923 = _5922 < 0.0;
                            bool _5930;
                            if (!_5923)
                            {
                                _5930 = _5922 > 1.0;
                            }
                            else
                            {
                                _5930 = _5923;
                            }
                            bool _5937;
                            if (!_5930)
                            {
                                _5937 = _5920.y < 0.0;
                            }
                            else
                            {
                                _5937 = _5930;
                            }
                            bool _5944;
                            if (!_5937)
                            {
                                _5944 = _5920.y > 1.0;
                            }
                            else
                            {
                                _5944 = _5937;
                            }
                            bool _5951;
                            if (!_5944)
                            {
                                _5951 = _5920.z > 1.0;
                            }
                            else
                            {
                                _5951 = _5944;
                            }
                            if (_5951)
                            {
                                _7107 = 1.0;
                                break;
                            }
                            float _5957 = _5920.z;
                            float2 _6123 = _503._m22.xy * 0.5;
                            float2 _6128 = _503._m26[_5762].xy + (_5920.xy * _503._m23.zw);
                            float4 _6141 = float4(_503._m26[_5762].xy + _6123, (_503._m26[_5762].xy + _503._m23.zw) - _6123);
                            float _7106;
                            do
                            {
                                int _6167 = int(_503._m22.z);
                                if (_6167 <= 0)
                                {
                                    float2 _6177 = fast::clamp(_6128, _6141.xy, _6141.zw);
                                    _7106 = spvDepthCast(_521).sample_compare(_521Smplr, float3(_6177, _5957).xy, _5957);
                                    break;
                                }
                                float2 _6190 = (_6128 / _503._m22.xy) + float2(0.5);
                                float2 _6191 = floor(_6190);
                                float2 _6196 = _6190 - _6191;
                                float2 _6199 = _6191 - float2(0.5);
                                bool _6203 = _6167 == 1;
                                if (_6203)
                                {
                                    float2 _6206 = _6196 * 2.0;
                                    _6151[0] = float2(3.0) - _6206;
                                    _6151[1] = float2(1.0) + _6206;
                                    _6152[0] = ((float2(2.0) - _6196) / _6151[0]) - float2(1.0);
                                    _6152[1] = (_6196 / _6151[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _6233 = _6196 * 3.0;
                                    _6151[0] = float2(4.0) - _6233;
                                    _6151[1] = float2(7.0);
                                    _6151[2] = float2(1.0) + _6233;
                                    _6152[0] = ((float2(3.0) - (_6196 * 2.0)) / _6151[0]) - float2(2.0);
                                    _6152[1] = (float2(3.0) + _6196) / _6151[1];
                                    _6152[2] = (_6196 / _6151[2]) + float2(2.0);
                                }
                                int _7481 = _6203 ? 2 : 3;
                                int _7096;
                                float _7099;
                                _7099 = 0.0;
                                _7096 = 0;
                                float _7105;
                                for (; _7096 < _7481; _7099 = _7105, _7096++)
                                {
                                    _7105 = _7099;
                                    for (int _7102 = 0; _7102 < _7481; )
                                    {
                                        _7105 += ((_6151[_7102].x * _6151[_7096].y) * spvDepthCast(_521).sample_compare(_521Smplr, float3(fast::clamp(_503._m22.xy * (_6199 + float2(_6152[_7102].x, _6152[_7096].y)), _6141.xy, _6141.zw), _5957).xy, _5957));
                                        _7102++;
                                        continue;
                                    }
                                }
                                _7106 = _7099 * (_6203 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _7107 = _7106;
                            break;
                        }
                        uint _5967 = _5762 - _5863;
                        if (_5967 >= uint(_503._m21.w))
                        {
                            _7107 = 1.0;
                            break;
                        }
                        float _5988 = _503._m27[_5967].w * length(in.m_1759 - _503._m27[_5967].xyz);
                        float3 _6006 = ((in.m_1759 + (_2279 * (_5988 * _503._m25.x))) + (_5796 * (_5988 * _503._m25.y))) - _503._m27[_5967].xyz;
                        float3 _6008 = abs(_6006);
                        float _6010 = _6008.x;
                        float _6012 = _6008.y;
                        bool _6013 = _6010 >= _6012;
                        bool _6021;
                        if (_6013)
                        {
                            _6021 = _6010 >= _6008.z;
                        }
                        else
                        {
                            _6021 = _6013;
                        }
                        float _7081;
                        int _7083;
                        if (_6021)
                        {
                            _7083 = (_6006.x > 0.0) ? 0 : 1;
                            _7081 = _6010;
                        }
                        else
                        {
                            float _6033 = _6008.z;
                            bool _6034 = _6012 >= _6033;
                            int _7084;
                            if (_6034)
                            {
                                _7084 = (_6006.y > 0.0) ? 2 : 3;
                            }
                            else
                            {
                                _7084 = (_6006.z > 0.0) ? 4 : 5;
                            }
                            _7083 = _7084;
                            _7081 = _6034 ? _6012 : _6033;
                        }
                        if (_7081 <= 0.0)
                        {
                            _7107 = 1.0;
                            break;
                        }
                        float2 _6071 = float2(dot(_6006, _1170[_7083]), dot(_6006, _1179[_7083])) / float2(_7081 * _503._m24.z);
                        float _6078 = _503._m28[_5967].z + (_503._m28[_5967].w / _7081);
                        if (_6078 > 1.0)
                        {
                            _7107 = 1.0;
                            break;
                        }
                        float2 _6096 = _503._m28[_5967].xy + (float2(float(spvSMod(_7083, 3)), float(_7083 / 3)) * _503._m24.xy);
                        float2 _6336 = _503._m22.xy * 0.5;
                        float2 _6341 = _6096 + (float2(0.5 + (0.5 * _6071.x), 0.5 - (0.5 * _6071.y)) * _503._m24.xy);
                        float4 _6354 = float4(_6096 + _6336, (_6096 + _503._m24.xy) - _6336);
                        float _7095;
                        do
                        {
                            int _6380 = int(_503._m22.z);
                            if (_6380 <= 0)
                            {
                                _7095 = spvDepthCast(_521).sample_compare(_521Smplr, float3(fast::clamp(_6341, _6354.xy, _6354.zw), _6078).xy, _6078);
                                break;
                            }
                            float2 _6403 = (_6341 / _503._m22.xy) + float2(0.5);
                            float2 _6404 = floor(_6403);
                            float2 _6409 = _6403 - _6404;
                            float2 _6412 = _6404 - float2(0.5);
                            bool _6416 = _6380 == 1;
                            if (_6416)
                            {
                                float2 _6419 = _6409 * 2.0;
                                _6364[0] = float2(3.0) - _6419;
                                _6364[1] = float2(1.0) + _6419;
                                _6365[0] = ((float2(2.0) - _6409) / _6364[0]) - float2(1.0);
                                _6365[1] = (_6409 / _6364[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _6446 = _6409 * 3.0;
                                _6364[0] = float2(4.0) - _6446;
                                _6364[1] = float2(7.0);
                                _6364[2] = float2(1.0) + _6446;
                                _6365[0] = ((float2(3.0) - (_6409 * 2.0)) / _6364[0]) - float2(2.0);
                                _6365[1] = (float2(3.0) + _6409) / _6364[1];
                                _6365[2] = (_6409 / _6364[2]) + float2(2.0);
                            }
                            int _7484 = _6416 ? 2 : 3;
                            int _7085;
                            float _7088;
                            _7088 = 0.0;
                            _7085 = 0;
                            float _7094;
                            for (; _7085 < _7484; _7088 = _7094, _7085++)
                            {
                                _7094 = _7088;
                                for (int _7091 = 0; _7091 < _7484; )
                                {
                                    _7094 += ((_6364[_7091].x * _6364[_7085].y) * spvDepthCast(_521).sample_compare(_521Smplr, float3(fast::clamp(_503._m22.xy * (_6412 + float2(_6365[_7091].x, _6365[_7085].y)), _6354.xy, _6354.zw), _6078).xy, _6078));
                                    _7091++;
                                    continue;
                                }
                            }
                            _7095 = _7088 * (_6416 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _7107 = _7095;
                        break;
                    } while(false);
                    _7145 = _5827 * _7107;
                }
                else
                {
                    _7145 = _5827;
                }
                float3 _2673 = fast::normalize(_5796 + _2268);
                float _2678 = fast::clamp(dot(_7001, _5796), 0.0, 1.0);
                float _2683 = fast::clamp(dot(_7001, _2673), 0.0, 1.0);
                float3 _6551 = _2477 + (_4866 * powr(1.0 - fast::clamp(dot(_2268, _2673), 0.0, 1.0), 5.0));
                float _6565 = ((_2683 * _2683) * _4881) + 1.0;
                _2721 = _7147 + (((((float3(1.0) - _6551) * _2471) + ((_6551 * ((_4876 / ((3.1415927410125732421875 * _6565) * _6565)) * (0.5 / fast::max((_2678 * _4907) + (_2482 * sqrt(((_2678 * _2678) * _4903) + _4876)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875)) * _2678) * _7145);
            }
            _7192 = _7147;
        }
        else
        {
            _7192 = _2621;
        }
        _7189 = _7192;
    }
    float _2747 = -length(_2267);
    float _7230;
    if (_503._m9.w != 0.0)
    {
        float _2771 = _503._m9.w * (in.m_1759 - _503._m6.xyz).y;
        float _7227;
        if (abs(_2771) < 9.9999997473787516355514526367188e-05)
        {
            _7227 = 1.0 - (0.5 * _2771);
        }
        else
        {
            _7227 = (1.0 - exp(fast::min(-_2771, 60.0))) / _2771;
        }
        _7230 = 1.0 - exp((_2747 * (_503._m7.w * exp(fast::min((-_503._m9.w) * (_503._m6.y - _503._m6.w), 30.0)))) * _7227);
    }
    else
    {
        _7230 = 1.0 - exp(_2747 * _503._m7.w);
    }
    float3 _2822 = mix(mix(_7189, _6999, float3(_2241._m1.y)), _503._m7.xyz, float3(_7230));
    float3 _7231;
    if (_503._m33.w > 0.5)
    {
        _7231 = _2822 / (float3(1.0) + _2822);
    }
    else
    {
        _7231 = _2822;
    }
    out.m_2834 = float4(_7231, in.m_2143.w);
    float2 _7299;
    do
    {
        if (in.m_2844.w <= 0.0)
        {
            _7299 = float2(0.0);
            break;
        }
        _7299 = ((in.m_2844.xy / float2(in.m_2844.w)) - (in.m_2843.xy / float2(in.m_2843.w))) * float2(0.5, -0.5);
        break;
    } while(false);
    _2842 = _7299;
    return out;
}

