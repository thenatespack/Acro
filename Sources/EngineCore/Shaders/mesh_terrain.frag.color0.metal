// Generated from mesh_terrain.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 3bcdea22e7cd956f
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
    float4 _m34;
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
    int _3049 = int(_185._m0[0].x + 0.5);
    int _3053 = int(_185._m0[0].y + 0.5);
    float2 _3061 = (in.m_2126 * _185._m0[0].z) + float2(_185._m0[0].w);
    float4 _3013 = _267.sample(_269, _3061, level(0.0));
    float4 _6992;
    if (_3049 > 4)
    {
        _6992 = _283.sample(_269, _3061, level(0.0));
    }
    else
    {
        _6992 = float4(0.0);
    }
    float4 _3014 = _6992;
    float2 _3083 = (in.m_2126 - float2(0.5)) * _185._m0[1].xy;
    float2 _3085 = dfdx(_3083);
    float2 _3087 = dfdy(_3083);
    float3 _6997;
    float3 _7001;
    float _7004;
    _7004 = 0.0;
    _7001 = float3(0.0);
    _6997 = float3(0.0);
    float3 _7633;
    float3 _7635;
    float _7636;
    for (int _6993 = 0; _6993 < 8; _7004 = _7636, _7001 = _7635, _6997 = _7633, _6993++)
    {
        if (_6993 >= _3049)
        {
            break;
        }
        float _6994;
        if (_6993 < 4)
        {
            _6994 = _3013[_6993];
        }
        else
        {
            _6994 = _3014[_6993 - 4];
        }
        if (_6994 < 0.001953125)
        {
            _7636 = _7004;
            _7635 = _7001;
            _7633 = _6997;
            continue;
        }
        int _3117 = 3 + (_6993 / 4);
        int _3119 = spvSMod(_6993, 4);
        float2 _3127 = _3085 * ((device float*)&_185._m0[_3117])[_3119];
        float2 _3130 = _3087 * ((device float*)&_185._m0[_3117])[_3119];
        float _3233 = fast::clamp(0.5 * log2(fast::max((fast::max(dot(_3127, _3127), dot(_3130, _3130)) * _185._m0[2].w) * _185._m0[2].w, 9.9999999392252902907785028219223e-09)), 0.0, fast::max(log2(_185._m0[2].w) - 2.0, 0.0));
        float _3246 = float(_6993);
        float _3261 = (0.5 * exp2(ceil(_3233))) / _185._m0[2].w;
        float2 _3275 = (float2(mod(_3246, _185._m0[2].y), floor(_3246 / _185._m0[2].y)) + fast::clamp(fract(_3083 * ((device float*)&_185._m0[_3117])[_3119]), float2(_3261), float2(1.0 - _3261))) / _185._m0[2].yz;
        float3 _6998;
        if (((_3053 >> _6993) & 1) != 0)
        {
            float3 _3164 = (_401.sample(_269, _3275, level(_3233)).xyz * 2.0) - float3(1.0);
            float2 _3169 = _3164.xy * _185._m0[1].z;
            float3 _6805 = _3164;
            _6805.x = _3169.x;
            _6805.y = _3169.y;
            _6998 = _6805;
        }
        else
        {
            _6998 = float3(0.0, 0.0, 1.0);
        }
        _7636 = _7004 + _6994;
        _7635 = _7001 + (_6998 * _6994);
        _7633 = _6997 + (_380.sample(_269, _3275, level(_3233)).xyz * _6994);
    }
    bool _3188 = _7004 > 0.0;
    float _7008;
    if (_3188)
    {
        _7008 = 1.0 / _7004;
    }
    else
    {
        _7008 = 0.0;
    }
    float3 _7014;
    if (_3188)
    {
        _7014 = _7001 * _7008;
    }
    else
    {
        _7014 = float3(0.0, 0.0, 1.0);
    }
    float3 _2158 = in.m_2143.xyz * fast::max(_6997 * _7008, float3(0.0));
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
        _2205 = dot(_7014, _7014) > 9.9999999600419720025001879548654e-13;
    }
    else
    {
        _2205 = _2198;
    }
    float3 _7020;
    if (_2205)
    {
        float3 _2209 = fast::normalize(_2193);
        float3 _2221 = fast::normalize(_7014);
        _7020 = fast::normalize(((_2209 * _2221.x) + ((cross(_2182, _2209) * ((in.m_2184.w < 0.0) ? (-1.0) : 1.0)) * _2221.y)) + (_2182 * _2221.z));
    }
    else
    {
        _7020 = _2182;
    }
    bool _2244 = _2241._m5.w > 0.5;
    float _7017;
    if (_2244)
    {
        _7017 = fast::clamp(_2241._m1.z, 0.0, 1.0);
    }
    else
    {
        _7017 = 0.0;
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
    float3 _7131;
    if (_2262 && (_7017 <= 0.0))
    {
        _7131 = -_7020;
    }
    else
    {
        _7131 = _7020;
    }
    float3 _2274 = fast::normalize(_503._m4.xyz);
    float3 _2280 = _503._m6.xyz - in.m_1759;
    float3 _2281 = fast::normalize(_2280);
    float3 _2286 = fast::normalize(_2274 + _2281);
    float3 _2292 = _2182 * (gl_FrontFacing ? 1.0 : (-1.0));
    bool _2297 = in.m_2294.x > 0.5;
    float3 _7128;
    float _7163;
    if ((_503._m5.w > 0.5) && _2297)
    {
        float _7076;
        float3 _7077;
        do
        {
            int _3296 = int(_503._m21.x);
            float _3304 = dot(_503._m20.xyz, in.m_1759) + _503._m20.w;
            int _7021;
            _7021 = 0;
            for (;;)
            {
                bool _3310 = _7021 < (_3296 - 1);
                bool _3318;
                if (_3310)
                {
                    _3318 = _3304 > _503._m16[_7021];
                }
                else
                {
                    _3318 = _3310;
                }
                if (_3318)
                {
                    _7021++;
                    continue;
                }
                else
                {
                    break;
                }
            }
            if (_3304 > _503._m16[_7021])
            {
                _7077 = float3(1.0);
                _7076 = 1.0;
                break;
            }
            float _7034;
            do
            {
                float4 _3420 = _503._m14[_7021] * float4(in.m_1759 + (_2292 * _503._m18[_7021]), 1.0);
                float _3423 = _3420.x;
                bool _3424 = _3423 < 0.0;
                bool _3431;
                if (!_3424)
                {
                    _3431 = _3423 > 1.0;
                }
                else
                {
                    _3431 = _3424;
                }
                bool _3438;
                if (!_3431)
                {
                    _3438 = _3420.y < 0.0;
                }
                else
                {
                    _3438 = _3431;
                }
                bool _3445;
                if (!_3438)
                {
                    _3445 = _3420.y > 1.0;
                }
                else
                {
                    _3445 = _3438;
                }
                if (_3445)
                {
                    _7034 = 1.0;
                    break;
                }
                float2 _3458 = float2(float(_7021 & 1), float(_7021 >> 1)) * _503._m23.xy;
                float _3465 = fast::min(_3420.z, 1.0) - _503._m19[_7021];
                float2 _3484 = _503._m22.xy * 0.5;
                float2 _3489 = _3458 + (_3420.xy * _503._m23.xy);
                float4 _3502 = float4(_3458 + _3484, (_3458 + _503._m23.xy) - _3484);
                float _7033;
                do
                {
                    int _3528 = int(_503._m22.z);
                    if (_3528 <= 0)
                    {
                        _7033 = spvDepthCast(_521).sample_compare(_521Smplr, float3(fast::clamp(_3489, _3502.xy, _3502.zw), _3465).xy, _3465);
                        break;
                    }
                    float2 _3551 = (_3489 / _503._m22.xy) + float2(0.5);
                    float2 _3552 = floor(_3551);
                    float2 _3557 = _3551 - _3552;
                    float2 _3560 = _3552 - float2(0.5);
                    bool _3564 = _3528 == 1;
                    spvUnsafeArray<float2, 3> _3512;
                    spvUnsafeArray<float2, 3> _3513;
                    if (_3564)
                    {
                        float2 _3567 = _3557 * 2.0;
                        _3512[0] = float2(3.0) - _3567;
                        _3512[1] = float2(1.0) + _3567;
                        _3513[0] = ((float2(2.0) - _3557) / _3512[0]) - float2(1.0);
                        _3513[1] = (_3557 / _3512[1]) + float2(1.0);
                    }
                    else
                    {
                        float2 _3594 = _3557 * 3.0;
                        _3512[0] = float2(4.0) - _3594;
                        _3512[1] = float2(7.0);
                        _3512[2] = float2(1.0) + _3594;
                        _3513[0] = ((float2(3.0) - (_3557 * 2.0)) / _3512[0]) - float2(2.0);
                        _3513[1] = (float2(3.0) + _3557) / _3512[1];
                        _3513[2] = (_3557 / _3512[2]) + float2(2.0);
                    }
                    int _7685 = _3564 ? 2 : 3;
                    int _7023;
                    float _7026;
                    _7026 = 0.0;
                    _7023 = 0;
                    float _7032;
                    for (; _7023 < _7685; _7026 = _7032, _7023++)
                    {
                        _7032 = _7026;
                        for (int _7029 = 0; _7029 < _7685; )
                        {
                            _7032 += ((_3512[_7029].x * _3512[_7023].y) * spvDepthCast(_521).sample_compare(_521Smplr, float3(fast::clamp(_503._m22.xy * (_3560 + float2(_3513[_7029].x, _3513[_7023].y)), _3502.xy, _3502.zw), _3465).xy, _3465));
                            _7029++;
                            continue;
                        }
                    }
                    _7033 = _7026 * (_3564 ? 0.0625 : 0.0069444444961845874786376953125);
                    break;
                } while(false);
                _7034 = _7033;
                break;
            } while(false);
            float3 _7071;
            float _7074;
            if (_3304 > _503._m17[_7021])
            {
                float _3358 = (_3304 - _503._m17[_7021]) / (_503._m16[_7021] - _503._m17[_7021]);
                int _3360 = _7021 + 1;
                float3 _7072;
                float _7075;
                if (_3360 < _3296)
                {
                    float _7054;
                    do
                    {
                        float4 _3707 = _503._m14[_3360] * float4(in.m_1759 + (_2292 * _503._m18[_3360]), 1.0);
                        float _3710 = _3707.x;
                        bool _3711 = _3710 < 0.0;
                        bool _3718;
                        if (!_3711)
                        {
                            _3718 = _3710 > 1.0;
                        }
                        else
                        {
                            _3718 = _3711;
                        }
                        bool _3725;
                        if (!_3718)
                        {
                            _3725 = _3707.y < 0.0;
                        }
                        else
                        {
                            _3725 = _3718;
                        }
                        bool _3732;
                        if (!_3725)
                        {
                            _3732 = _3707.y > 1.0;
                        }
                        else
                        {
                            _3732 = _3725;
                        }
                        if (_3732)
                        {
                            _7054 = 1.0;
                            break;
                        }
                        float2 _3745 = float2(float(_3360 & 1), float(_3360 >> 1)) * _503._m23.xy;
                        float _3752 = fast::min(_3707.z, 1.0) - _503._m19[_3360];
                        float2 _3771 = _503._m22.xy * 0.5;
                        float2 _3776 = _3745 + (_3707.xy * _503._m23.xy);
                        float4 _3789 = float4(_3745 + _3771, (_3745 + _503._m23.xy) - _3771);
                        float _7053;
                        do
                        {
                            int _3815 = int(_503._m22.z);
                            if (_3815 <= 0)
                            {
                                _7053 = spvDepthCast(_521).sample_compare(_521Smplr, float3(fast::clamp(_3776, _3789.xy, _3789.zw), _3752).xy, _3752);
                                break;
                            }
                            float2 _3838 = (_3776 / _503._m22.xy) + float2(0.5);
                            float2 _3839 = floor(_3838);
                            float2 _3844 = _3838 - _3839;
                            float2 _3847 = _3839 - float2(0.5);
                            bool _3851 = _3815 == 1;
                            spvUnsafeArray<float2, 3> _3799;
                            spvUnsafeArray<float2, 3> _3800;
                            if (_3851)
                            {
                                float2 _3854 = _3844 * 2.0;
                                _3799[0] = float2(3.0) - _3854;
                                _3799[1] = float2(1.0) + _3854;
                                _3800[0] = ((float2(2.0) - _3844) / _3799[0]) - float2(1.0);
                                _3800[1] = (_3844 / _3799[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _3881 = _3844 * 3.0;
                                _3799[0] = float2(4.0) - _3881;
                                _3799[1] = float2(7.0);
                                _3799[2] = float2(1.0) + _3881;
                                _3800[0] = ((float2(3.0) - (_3844 * 2.0)) / _3799[0]) - float2(2.0);
                                _3800[1] = (float2(3.0) + _3844) / _3799[1];
                                _3800[2] = (_3844 / _3799[2]) + float2(2.0);
                            }
                            int _7687 = _3851 ? 2 : 3;
                            int _7043;
                            float _7046;
                            _7046 = 0.0;
                            _7043 = 0;
                            float _7052;
                            for (; _7043 < _7687; _7046 = _7052, _7043++)
                            {
                                _7052 = _7046;
                                for (int _7049 = 0; _7049 < _7687; )
                                {
                                    _7052 += ((_3799[_7049].x * _3799[_7043].y) * spvDepthCast(_521).sample_compare(_521Smplr, float3(fast::clamp(_503._m22.xy * (_3847 + float2(_3800[_7049].x, _3800[_7043].y)), _3789.xy, _3789.zw), _3752).xy, _3752));
                                    _7049++;
                                    continue;
                                }
                            }
                            _7053 = _7046 * (_3851 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _7054 = _7053;
                        break;
                    } while(false);
                    _7075 = mix(_7034, _7054, _3358);
                    _7072 = mix(_868[_7021], _868[_3360], float3(_3358));
                }
                else
                {
                    _7075 = mix(_7034, 1.0, _3358);
                    _7072 = _868[_7021];
                }
                _7074 = _7075;
                _7071 = _7072;
            }
            else
            {
                _7074 = _7034;
                _7071 = _868[_7021];
            }
            _7077 = select(float3(1.0), _7071, bool3(_503._m22.w > 0.5));
            _7076 = _7074;
            break;
        } while(false);
        _7163 = _7076;
        _7128 = _2158 * _7077;
    }
    else
    {
        _7163 = 1.0;
        _7128 = _2158;
    }
    float3 _2323 = _503._m5.xyz * _503._m4.w;
    float _2330 = abs(in.m_2184.w);
    float _7239;
    if (_2330 > 0.0)
    {
        _7239 = fast::min(_2330, 1.0);
    }
    else
    {
        _7239 = 1.0;
    }
    float3 _7397;
    if (!_2244)
    {
        float _2346 = dot(_7131, _2274);
        float3 _7389;
        if (_503._m29.x > 0.5)
        {
            float _4032 = (_503._m29.z * _7131.x) - (_503._m29.w * _7131.z);
            float _4045 = (_503._m29.w * _7131.x) + (_503._m29.z * _7131.z);
            float _4063 = 1.09254801273345947265625 * _4032;
            spvUnsafeArray<float, 9> _6795 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _7131.y, 0.48860299587249755859375 * _4045, 0.48860299587249755859375 * _4032, _4063 * _7131.y, (1.09254801273345947265625 * _7131.y) * _4045, 0.3153919875621795654296875 * (((3.0 * _4045) * _4045) - 1.0), _4063 * _4045, 0.546274006366729736328125 * ((_4032 * _4032) - (_7131.y * _7131.y)) });
            spvUnsafeArray<float, 9> _3977 = _6795;
            float3 _7388;
            _7388 = float3(0.0);
            for (int _7387 = 0; _7387 < 9; )
            {
                _7388 += (_1524.read(uint2((int2(496, 256) + int2(_7387, 0))), 0).xyz * _3977[_7387]);
                _7387++;
                continue;
            }
            _7389 = fast::max(_7388, float3(0.0)) * _503._m29.y;
        }
        else
        {
            _7389 = mix(_503._m9.xyz, _503._m8.xyz, float3((_7131.y * 0.5) + 0.5)) * _503._m8.w;
        }
        float3 _2396 = (_7128 * ((_7389 * _7239) + ((_2323 * fast::max(_2346, 0.0)) * _7163))) + ((_2323 * ((powr(fast::max(dot(_7131, _2286), 0.0), _2241._m1.w) * _2241._m1.z) * step(0.0, _2346))) * _7163);
        float3 _7398;
        if (_503._m13.w > 0.5)
        {
            float2 _4148 = fast::clamp(floor(gl_FragCoord.xy * _503._m12.xy), float2(0.0), _503._m13.xy - float2(1.0));
            uint _4176 = uint((((fast::clamp(floor((log2(fast::max(dot(_503._m11.xyz, in.m_1759) + _503._m11.w, 9.9999999747524270787835121154785e-07)) * _503._m12.z) + _503._m12.w), 0.0, _503._m13.z - 1.0) * _503._m13.y) + _4148.y) * _503._m13.x) + _4148.x);
            uint _4178 = _4176 >> uint(2);
            uint _4180 = _4176 & 3u;
            uint _4184 = _1891._m0[_4178][_4180] & 65535u;
            uint _4186 = _1891._m0[_4178][_4180] >> uint(16);
            float3 _7399;
            _7399 = _2396;
            float3 _2477;
            spvUnsafeArray<float2, 3> _4594;
            spvUnsafeArray<float2, 3> _4595;
            spvUnsafeArray<float2, 3> _4807;
            spvUnsafeArray<float2, 3> _4808;
            for (uint _7396 = _4184; _7396 < (_4184 + _4186); _7399 = _2477, _7396++)
            {
                uint _4192 = _7396 / 3u;
                uint _4205 = (_1913._m0[_4192 >> uint(2)][_4192 & 3u] >> ((_7396 - (_4192 * 3u)) * 10u)) & 1023u;
                float3 _4222 = _1751._m0[_4205].xyz - in.m_1759;
                float _4225 = dot(_4222, _4222);
                float _4229 = _4225 * _1751._m0[_4205].w;
                float _4234 = fast::clamp(1.0 - (_4229 * _4229), 0.0, 1.0);
                float3 _4239 = _4222 * rsqrt(fast::max(_4225, 9.9999999392252902907785028219223e-09));
                float _4257 = fast::clamp((dot(-_4239, _1794._m0[_4205].xyz) * _1786._m0[_4205].w) + _1794._m0[_4205].w, 0.0, 1.0);
                float3 _4270 = _1786._m0[_4205].xyz * ((((_4234 * _4234) * _4257) * _4257) / fast::max(_4225, 9.9999997473787516355514526367188e-05));
                float3 _7598;
                if (_2297)
                {
                    float _7544;
                    do
                    {
                        uint _4306 = uint(_503._m21.z);
                        if (_4205 < _4306)
                        {
                            float _4328 = _503._m26[_4205].z * fast::max((_503._m15[_4205] * float4(in.m_1759, 1.0)).w, 0.0);
                            float4 _4352 = _503._m15[_4205] * float4((in.m_1759 + (_2292 * (_4328 * _503._m25.x))) + (_4239 * (_4328 * _503._m25.y)), 1.0);
                            float _4354 = _4352.w;
                            if (_4354 <= 0.0)
                            {
                                _7544 = 1.0;
                                break;
                            }
                            float3 _4363 = _4352.xyz / float3(_4354);
                            float _4365 = _4363.x;
                            bool _4366 = _4365 < 0.0;
                            bool _4373;
                            if (!_4366)
                            {
                                _4373 = _4365 > 1.0;
                            }
                            else
                            {
                                _4373 = _4366;
                            }
                            bool _4380;
                            if (!_4373)
                            {
                                _4380 = _4363.y < 0.0;
                            }
                            else
                            {
                                _4380 = _4373;
                            }
                            bool _4387;
                            if (!_4380)
                            {
                                _4387 = _4363.y > 1.0;
                            }
                            else
                            {
                                _4387 = _4380;
                            }
                            bool _4394;
                            if (!_4387)
                            {
                                _4394 = _4363.z > 1.0;
                            }
                            else
                            {
                                _4394 = _4387;
                            }
                            if (_4394)
                            {
                                _7544 = 1.0;
                                break;
                            }
                            float _4400 = _4363.z;
                            float2 _4566 = _503._m22.xy * 0.5;
                            float2 _4571 = _503._m26[_4205].xy + (_4363.xy * _503._m23.zw);
                            float4 _4584 = float4(_503._m26[_4205].xy + _4566, (_503._m26[_4205].xy + _503._m23.zw) - _4566);
                            float _7543;
                            do
                            {
                                int _4610 = int(_503._m22.z);
                                if (_4610 <= 0)
                                {
                                    float2 _4620 = fast::clamp(_4571, _4584.xy, _4584.zw);
                                    _7543 = spvDepthCast(_521).sample_compare(_521Smplr, float3(_4620, _4400).xy, _4400);
                                    break;
                                }
                                float2 _4633 = (_4571 / _503._m22.xy) + float2(0.5);
                                float2 _4634 = floor(_4633);
                                float2 _4639 = _4633 - _4634;
                                float2 _4642 = _4634 - float2(0.5);
                                bool _4646 = _4610 == 1;
                                if (_4646)
                                {
                                    float2 _4649 = _4639 * 2.0;
                                    _4594[0] = float2(3.0) - _4649;
                                    _4594[1] = float2(1.0) + _4649;
                                    _4595[0] = ((float2(2.0) - _4639) / _4594[0]) - float2(1.0);
                                    _4595[1] = (_4639 / _4594[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _4676 = _4639 * 3.0;
                                    _4594[0] = float2(4.0) - _4676;
                                    _4594[1] = float2(7.0);
                                    _4594[2] = float2(1.0) + _4676;
                                    _4595[0] = ((float2(3.0) - (_4639 * 2.0)) / _4594[0]) - float2(2.0);
                                    _4595[1] = (float2(3.0) + _4639) / _4594[1];
                                    _4595[2] = (_4639 / _4594[2]) + float2(2.0);
                                }
                                int _7692 = _4646 ? 2 : 3;
                                int _7533;
                                float _7536;
                                _7536 = 0.0;
                                _7533 = 0;
                                float _7542;
                                for (; _7533 < _7692; _7536 = _7542, _7533++)
                                {
                                    _7542 = _7536;
                                    for (int _7539 = 0; _7539 < _7692; )
                                    {
                                        _7542 += ((_4594[_7539].x * _4594[_7533].y) * spvDepthCast(_521).sample_compare(_521Smplr, float3(fast::clamp(_503._m22.xy * (_4642 + float2(_4595[_7539].x, _4595[_7533].y)), _4584.xy, _4584.zw), _4400).xy, _4400));
                                        _7539++;
                                        continue;
                                    }
                                }
                                _7543 = _7536 * (_4646 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _7544 = _7543;
                            break;
                        }
                        uint _4410 = _4205 - _4306;
                        if (_4410 >= uint(_503._m21.w))
                        {
                            _7544 = 1.0;
                            break;
                        }
                        float _4431 = _503._m27[_4410].w * length(in.m_1759 - _503._m27[_4410].xyz);
                        float3 _4449 = ((in.m_1759 + (_2292 * (_4431 * _503._m25.x))) + (_4239 * (_4431 * _503._m25.y))) - _503._m27[_4410].xyz;
                        float3 _4451 = abs(_4449);
                        float _4453 = _4451.x;
                        float _4455 = _4451.y;
                        bool _4456 = _4453 >= _4455;
                        bool _4464;
                        if (_4456)
                        {
                            _4464 = _4453 >= _4451.z;
                        }
                        else
                        {
                            _4464 = _4456;
                        }
                        float _7518;
                        int _7520;
                        if (_4464)
                        {
                            _7520 = (_4449.x > 0.0) ? 0 : 1;
                            _7518 = _4453;
                        }
                        else
                        {
                            float _4476 = _4451.z;
                            bool _4477 = _4455 >= _4476;
                            int _7521;
                            if (_4477)
                            {
                                _7521 = (_4449.y > 0.0) ? 2 : 3;
                            }
                            else
                            {
                                _7521 = (_4449.z > 0.0) ? 4 : 5;
                            }
                            _7520 = _7521;
                            _7518 = _4477 ? _4455 : _4476;
                        }
                        if (_7518 <= 0.0)
                        {
                            _7544 = 1.0;
                            break;
                        }
                        float2 _4514 = float2(dot(_4449, _1170[_7520]), dot(_4449, _1179[_7520])) / float2(_7518 * _503._m24.z);
                        float _4521 = _503._m28[_4410].z + (_503._m28[_4410].w / _7518);
                        if (_4521 > 1.0)
                        {
                            _7544 = 1.0;
                            break;
                        }
                        float2 _4539 = _503._m28[_4410].xy + (float2(float(spvSMod(_7520, 3)), float(_7520 / 3)) * _503._m24.xy);
                        float2 _4779 = _503._m22.xy * 0.5;
                        float2 _4784 = _4539 + (float2(0.5 + (0.5 * _4514.x), 0.5 - (0.5 * _4514.y)) * _503._m24.xy);
                        float4 _4797 = float4(_4539 + _4779, (_4539 + _503._m24.xy) - _4779);
                        float _7532;
                        do
                        {
                            int _4823 = int(_503._m22.z);
                            if (_4823 <= 0)
                            {
                                _7532 = spvDepthCast(_521).sample_compare(_521Smplr, float3(fast::clamp(_4784, _4797.xy, _4797.zw), _4521).xy, _4521);
                                break;
                            }
                            float2 _4846 = (_4784 / _503._m22.xy) + float2(0.5);
                            float2 _4847 = floor(_4846);
                            float2 _4852 = _4846 - _4847;
                            float2 _4855 = _4847 - float2(0.5);
                            bool _4859 = _4823 == 1;
                            if (_4859)
                            {
                                float2 _4862 = _4852 * 2.0;
                                _4807[0] = float2(3.0) - _4862;
                                _4807[1] = float2(1.0) + _4862;
                                _4808[0] = ((float2(2.0) - _4852) / _4807[0]) - float2(1.0);
                                _4808[1] = (_4852 / _4807[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _4889 = _4852 * 3.0;
                                _4807[0] = float2(4.0) - _4889;
                                _4807[1] = float2(7.0);
                                _4807[2] = float2(1.0) + _4889;
                                _4808[0] = ((float2(3.0) - (_4852 * 2.0)) / _4807[0]) - float2(2.0);
                                _4808[1] = (float2(3.0) + _4852) / _4807[1];
                                _4808[2] = (_4852 / _4807[2]) + float2(2.0);
                            }
                            int _7695 = _4859 ? 2 : 3;
                            int _7522;
                            float _7525;
                            _7525 = 0.0;
                            _7522 = 0;
                            float _7531;
                            for (; _7522 < _7695; _7525 = _7531, _7522++)
                            {
                                _7531 = _7525;
                                for (int _7528 = 0; _7528 < _7695; )
                                {
                                    _7531 += ((_4807[_7528].x * _4807[_7522].y) * spvDepthCast(_521).sample_compare(_521Smplr, float3(fast::clamp(_503._m22.xy * (_4855 + float2(_4808[_7528].x, _4808[_7522].y)), _4797.xy, _4797.zw), _4521).xy, _4521));
                                    _7528++;
                                    continue;
                                }
                            }
                            _7532 = _7525 * (_4859 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _7544 = _7532;
                        break;
                    } while(false);
                    _7598 = _4270 * _7544;
                }
                else
                {
                    _7598 = _4270;
                }
                float _2448 = dot(_7131, _4239);
                _2477 = _7399 + (((_7128 * fast::max(_2448, 0.0)) * _7598) + (_7598 * ((powr(fast::max(dot(_7131, fast::normalize(_4239 + _2281)), 0.0), _2241._m1.w) * _2241._m1.z) * step(0.0, _2448))));
            }
            _7398 = _7399;
        }
        else
        {
            _7398 = _2396;
        }
        _7397 = _7398;
    }
    else
    {
        float _2483 = fast::clamp(_185._m0[2].x, 0.0, 1.0);
        float _2487 = fast::clamp(_185._m0[1].w, 0.04500000178813934326171875, 1.0);
        float _2491 = _2487 * _2487;
        float3 _2496 = _7128 * (1.0 - _2483);
        float3 _2502 = mix(float3(0.039999999105930328369140625), _7128, float3(_2483));
        bool _2506 = _7017 > 0.0;
        float3 _7154;
        if (_2506)
        {
            float3 _2511 = dfdx(in.m_1759);
            float3 _2513 = dfdy(in.m_1759);
            float3 _2514 = cross(_2511, _2513);
            float3 _7155;
            if (dot(_2514, _2514) > 9.9999996826552253889678874634872e-21)
            {
                _7155 = fast::normalize((fast::normalize(_2514) * ((dot(_2514, _2281) < 0.0) ? (-1.0) : 1.0)) + (_7131 - _2182));
            }
            else
            {
                _7155 = _7131;
            }
            _7154 = _7155;
        }
        else
        {
            _7154 = _7131;
        }
        float _2540 = fast::max(dot(_7154, _2281), 9.9999997473787516355514526367188e-05);
        float _2549 = dot(_7154, _2274);
        float _2550 = fast::clamp(_2549, 0.0, 1.0);
        float _2555 = fast::clamp(dot(_7154, _2286), 0.0, 1.0);
        float _2560 = fast::clamp(dot(_2281, _2286), 0.0, 1.0);
        float _7158;
        float _7159;
        if (_2506)
        {
            _7159 = fast::max(_2540, 0.5);
            _7158 = fast::max(_2560, 0.5);
        }
        else
        {
            _7159 = _2540;
            _7158 = _2560;
        }
        float3 _4991 = float3(1.0) - _2502;
        float3 _4994 = _2502 + (_4991 * powr(1.0 - _7158, 5.0));
        float _5001 = _2491 * _2491;
        float _5006 = _5001 - 1.0;
        float _5008 = ((_2555 * _2555) * _5006) + 1.0;
        float _5028 = 1.0 - _5001;
        float _5032 = sqrt(((_7159 * _7159) * _5028) + _5001);
        float3 _2606 = (((((float3(1.0) - _4994) * _2496) * fast::clamp(dot(_7131, _2274), 0.0, 1.0)) + (((_4994 * ((_5001 / ((3.1415927410125732421875 * _5008) * _5008)) * (0.5 / fast::max((_2550 * _5032) + (_7159 * sqrt(((_2550 * _2550) * _5028) + _5001)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875) * _2550)) * _2323) * _7163;
        float3 _7253;
        if (_2506)
        {
            _7253 = _2606 + (((((_2496 * _2323) * _7163) * _7017) * fast::clamp(-_2549, 0.0, 1.0)) * (0.3499999940395355224609375 + (0.64999997615814208984375 * powr(fast::clamp(dot(-_2281, _2274), 0.0, 1.0), 3.0))));
        }
        else
        {
            _7253 = _2606;
        }
        float3 _7188;
        float2 _7204;
        float3 _7216;
        if (_503._m29.x > 0.5)
        {
            float4 _5065 = _1629.sample(_1631, (((float2(_7159, _2487) * 31.0) + float2(0.5)) * float2(0.03125)));
            float _5124 = (_503._m29.z * _7131.x) - (_503._m29.w * _7131.z);
            float _5137 = (_503._m29.w * _7131.x) + (_503._m29.z * _7131.z);
            float _5155 = 1.09254801273345947265625 * _5124;
            spvUnsafeArray<float, 9> _6776 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _7131.y, 0.48860299587249755859375 * _5137, 0.48860299587249755859375 * _5124, _5155 * _7131.y, (1.09254801273345947265625 * _7131.y) * _5137, 0.3153919875621795654296875 * (((3.0 * _5137) * _5137) - 1.0), _5155 * _5137, 0.546274006366729736328125 * ((_5124 * _5124) - (_7131.y * _7131.y)) });
            spvUnsafeArray<float, 9> _5069 = _6776;
            float3 _7171;
            _7171 = float3(0.0);
            for (int _7170 = 0; _7170 < 9; )
            {
                _7171 += (_1524.read(uint2((int2(496, 256) + int2(_7170, 0))), 0).xyz * _5069[_7170]);
                _7170++;
                continue;
            }
            float3 _2660 = reflect(-_2281, _7154);
            float _5250 = _2660.x;
            float _5255 = _2660.z;
            float2 _5287 = float2((precise::atan2((_503._m29.z * _5250) - (_503._m29.w * _5255), -((_503._m29.w * _5250) + (_503._m29.z * _5255))) * 0.15915493667125701904296875) + 0.5, acos(fast::clamp(_2660.y, -1.0, 1.0)) * 0.3183098733425140380859375);
            float _5219 = _2487 * 5.0;
            int _5222 = min(int(_5219), 4);
            float2 _5308 = (_5287 * float2(_1585[_5222].zw)) - float2(0.5);
            float2 _5310 = floor(_5308);
            float2 _5313 = _5308 - _5310;
            int _5316 = int(_5310.x);
            int _5319 = int(_5310.y);
            int _7173;
            if (_5316 < 0)
            {
                _7173 = _5316 + _1585[_5222].z;
            }
            else
            {
                _7173 = _5316;
            }
            int _7174;
            if (_7173 >= _1585[_5222].z)
            {
                _7174 = _7173 - _1585[_5222].z;
            }
            else
            {
                _7174 = _7173;
            }
            int _5339 = _7174 + 1;
            int _7696 = (_5339 == _1585[_5222].z) ? 0 : _5339;
            int _5354 = min((_5319 + 1), (_1585[_5222].w - 1));
            int _5356 = max(_5319, 0);
            float3 _5409 = float3(_5313.x);
            int _5229 = _5222 + 1;
            float2 _5441 = (_5287 * float2(_1585[_5229].zw)) - float2(0.5);
            float2 _5443 = floor(_5441);
            float2 _5446 = _5441 - _5443;
            int _5449 = int(_5443.x);
            int _5452 = int(_5443.y);
            int _7180;
            if (_5449 < 0)
            {
                _7180 = _5449 + _1585[_5229].z;
            }
            else
            {
                _7180 = _5449;
            }
            int _7181;
            if (_7180 >= _1585[_5229].z)
            {
                _7181 = _7180 - _1585[_5229].z;
            }
            else
            {
                _7181 = _7180;
            }
            int _5472 = _7181 + 1;
            int _7697 = (_5472 == _1585[_5229].z) ? 0 : _5472;
            int _5487 = min((_5452 + 1), (_1585[_5229].w - 1));
            int _5489 = max(_5452, 0);
            float3 _5542 = float3(_5446.x);
            float3 _5244 = mix(mix(mix(_1524.read(uint2((_1585[_5222].xy + int2(_7174, _5356))), 0).xyz, _1524.read(uint2((_1585[_5222].xy + int2(_7696, _5356))), 0).xyz, _5409), mix(_1524.read(uint2((_1585[_5222].xy + int2(_7174, _5354))), 0).xyz, _1524.read(uint2((_1585[_5222].xy + int2(_7696, _5354))), 0).xyz, _5409), float3(_5313.y)), mix(mix(_1524.read(uint2((_1585[_5229].xy + int2(_7181, _5489))), 0).xyz, _1524.read(uint2((_1585[_5229].xy + int2(_7697, _5489))), 0).xyz, _5542), mix(_1524.read(uint2((_1585[_5229].xy + int2(_7181, _5487))), 0).xyz, _1524.read(uint2((_1585[_5229].xy + int2(_7697, _5487))), 0).xyz, _5542), float3(_5446.y)), float3(_5219 - float(_5222))) * _503._m29.y;
            _7216 = fast::max(_7171, float3(0.0)) * _503._m29.y;
            _7204 = _5065.xy;
            _7188 = _5244;
        }
        else
        {
            float4 _5560 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * _2487) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);
            float _5562 = _5560.x;
            float3 _5597 = mix(_503._m9.xyz, _503._m8.xyz, float3((_7131.y * 0.5) + 0.5)) * _503._m8.w;
            _7216 = _5597;
            _7204 = (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_5562 * _5562, exp2((-9.27999973297119140625) * _7159)) * _5562) + _5560.y)) + _5560.zw;
            _7188 = mix(mix(_503._m9.xyz, _503._m8.xyz, float3((reflect(-_2281, _7154).y * 0.5) + 0.5)) * _503._m8.w, _5597, float3(_2487));
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
        float3 _7225;
        if (_2692)
        {
            float3 _7201;
            do
            {
                float _5676 = ((_503._m32.x * (1.0 - smoothstep(_503._m33.x * 0.5, _503._m33.x, abs(dot(_503._m31.xyz, in.m_1759) - _503._m31.w)))) * smoothstep(0.5, 0.89999997615814208984375, dot(_2292, _503._m31.xyz))) * (1.0 - smoothstep(_503._m32.y * 0.5, _503._m32.y, _2487));
                if (_5676 <= 0.0)
                {
                    _7201 = _7188;
                    break;
                }
                float4 _5701 = _503._m30 * float4(in.m_1759 + ((_7131 - (_503._m31.xyz * dot(_7131, _503._m31.xyz))) * _503._m32.w), 1.0);
                float2 _5714 = ((float2(_5701.x, -_5701.y) / float2(_5701.w)) * 0.5) + float2(0.5);
                float _5718 = _503._m32.z * _2487;
                float3 _7199;
                float _7200;
                _7200 = 0.0;
                _7199 = float3(0.0);
                for (int _7198 = 0; _7198 < 12; )
                {
                    float _5725 = float(_7198);
                    float _5733 = _5725 * 2.3999631404876708984375;
                    float2 _5745 = _5714 + (float2(cos(_5733) * _503._m33.y, sin(_5733)) * (sqrt((_5725 + 0.5) * 0.083333335816860198974609375) * _5718));
                    float2 _5750 = fast::min(_5745, float2(1.0) - _5745);
                    float _5756 = smoothstep(0.0, 0.039999999105930328369140625, fast::min(_5750.x, _5750.y));
                    float4 _5764 = _2077.sample(_269, fast::clamp(_5745, float2(0.0), float2(1.0)), level(0.0));
                    float3 _5766 = _5764.xyz;
                    _7200 += (_5764.w * _5756);
                    _7199 += ((_5766 / (float3(1.0) - fast::min(_5766, float3(0.99500000476837158203125)))) * _5756);
                    _7198++;
                    continue;
                }
                _7201 = mix(_7188, (_7199 * float3(0.083333335816860198974609375)) + (_7188 * (1.0 - (_7200 * 0.083333335816860198974609375))), float3(_5676));
                break;
            } while(false);
            _7225 = _7201;
        }
        else
        {
            _7225 = _7188;
        }
        float3 _2712 = (_2502 * _7204.x) + float3(_7204.y);
        float3 _2728 = _7253 + (((((float3(1.0) - _2712) * _2496) * _7216) + (_2712 * _7225)) * _7239);
        float3 _7400;
        if (_503._m13.w > 0.5)
        {
            float2 _5830 = fast::clamp(floor(gl_FragCoord.xy * _503._m12.xy), float2(0.0), _503._m13.xy - float2(1.0));
            uint _5858 = uint((((fast::clamp(floor((log2(fast::max(dot(_503._m11.xyz, in.m_1759) + _503._m11.w, 9.9999999747524270787835121154785e-07)) * _503._m12.z) + _503._m12.w), 0.0, _503._m13.z - 1.0) * _503._m13.y) + _5830.y) * _503._m13.x) + _5830.x);
            uint _5860 = _5858 >> uint(2);
            uint _5862 = _5858 & 3u;
            uint _5866 = _1891._m0[_5860][_5862] & 65535u;
            uint _5868 = _1891._m0[_5860][_5862] >> uint(16);
            float3 _7353;
            _7353 = _2728;
            float3 _2828;
            spvUnsafeArray<float2, 3> _6276;
            spvUnsafeArray<float2, 3> _6277;
            spvUnsafeArray<float2, 3> _6489;
            spvUnsafeArray<float2, 3> _6490;
            for (uint _7256 = _5866; _7256 < (_5866 + _5868); _7353 = _2828, _7256++)
            {
                uint _5874 = _7256 / 3u;
                uint _5887 = (_1913._m0[_5874 >> uint(2)][_5874 & 3u] >> ((_7256 - (_5874 * 3u)) * 10u)) & 1023u;
                float3 _5904 = _1751._m0[_5887].xyz - in.m_1759;
                float _5907 = dot(_5904, _5904);
                float _5911 = _5907 * _1751._m0[_5887].w;
                float _5916 = fast::clamp(1.0 - (_5911 * _5911), 0.0, 1.0);
                float3 _5921 = _5904 * rsqrt(fast::max(_5907, 9.9999999392252902907785028219223e-09));
                float _5939 = fast::clamp((dot(-_5921, _1794._m0[_5887].xyz) * _1786._m0[_5887].w) + _1794._m0[_5887].w, 0.0, 1.0);
                float3 _5952 = _1786._m0[_5887].xyz * ((((_5916 * _5916) * _5939) * _5939) / fast::max(_5907, 9.9999997473787516355514526367188e-05));
                float3 _7351;
                if (_2297)
                {
                    float _7283;
                    do
                    {
                        uint _5988 = uint(_503._m21.z);
                        if (_5887 < _5988)
                        {
                            float _6010 = _503._m26[_5887].z * fast::max((_503._m15[_5887] * float4(in.m_1759, 1.0)).w, 0.0);
                            float4 _6034 = _503._m15[_5887] * float4((in.m_1759 + (_2292 * (_6010 * _503._m25.x))) + (_5921 * (_6010 * _503._m25.y)), 1.0);
                            float _6036 = _6034.w;
                            if (_6036 <= 0.0)
                            {
                                _7283 = 1.0;
                                break;
                            }
                            float3 _6045 = _6034.xyz / float3(_6036);
                            float _6047 = _6045.x;
                            bool _6048 = _6047 < 0.0;
                            bool _6055;
                            if (!_6048)
                            {
                                _6055 = _6047 > 1.0;
                            }
                            else
                            {
                                _6055 = _6048;
                            }
                            bool _6062;
                            if (!_6055)
                            {
                                _6062 = _6045.y < 0.0;
                            }
                            else
                            {
                                _6062 = _6055;
                            }
                            bool _6069;
                            if (!_6062)
                            {
                                _6069 = _6045.y > 1.0;
                            }
                            else
                            {
                                _6069 = _6062;
                            }
                            bool _6076;
                            if (!_6069)
                            {
                                _6076 = _6045.z > 1.0;
                            }
                            else
                            {
                                _6076 = _6069;
                            }
                            if (_6076)
                            {
                                _7283 = 1.0;
                                break;
                            }
                            float _6082 = _6045.z;
                            float2 _6248 = _503._m22.xy * 0.5;
                            float2 _6253 = _503._m26[_5887].xy + (_6045.xy * _503._m23.zw);
                            float4 _6266 = float4(_503._m26[_5887].xy + _6248, (_503._m26[_5887].xy + _503._m23.zw) - _6248);
                            float _7282;
                            do
                            {
                                int _6292 = int(_503._m22.z);
                                if (_6292 <= 0)
                                {
                                    float2 _6302 = fast::clamp(_6253, _6266.xy, _6266.zw);
                                    _7282 = spvDepthCast(_521).sample_compare(_521Smplr, float3(_6302, _6082).xy, _6082);
                                    break;
                                }
                                float2 _6315 = (_6253 / _503._m22.xy) + float2(0.5);
                                float2 _6316 = floor(_6315);
                                float2 _6321 = _6315 - _6316;
                                float2 _6324 = _6316 - float2(0.5);
                                bool _6328 = _6292 == 1;
                                if (_6328)
                                {
                                    float2 _6331 = _6321 * 2.0;
                                    _6276[0] = float2(3.0) - _6331;
                                    _6276[1] = float2(1.0) + _6331;
                                    _6277[0] = ((float2(2.0) - _6321) / _6276[0]) - float2(1.0);
                                    _6277[1] = (_6321 / _6276[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _6358 = _6321 * 3.0;
                                    _6276[0] = float2(4.0) - _6358;
                                    _6276[1] = float2(7.0);
                                    _6276[2] = float2(1.0) + _6358;
                                    _6277[0] = ((float2(3.0) - (_6321 * 2.0)) / _6276[0]) - float2(2.0);
                                    _6277[1] = (float2(3.0) + _6321) / _6276[1];
                                    _6277[2] = (_6321 / _6276[2]) + float2(2.0);
                                }
                                int _7699 = _6328 ? 2 : 3;
                                int _7272;
                                float _7275;
                                _7275 = 0.0;
                                _7272 = 0;
                                float _7281;
                                for (; _7272 < _7699; _7275 = _7281, _7272++)
                                {
                                    _7281 = _7275;
                                    for (int _7278 = 0; _7278 < _7699; )
                                    {
                                        _7281 += ((_6276[_7278].x * _6276[_7272].y) * spvDepthCast(_521).sample_compare(_521Smplr, float3(fast::clamp(_503._m22.xy * (_6324 + float2(_6277[_7278].x, _6277[_7272].y)), _6266.xy, _6266.zw), _6082).xy, _6082));
                                        _7278++;
                                        continue;
                                    }
                                }
                                _7282 = _7275 * (_6328 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _7283 = _7282;
                            break;
                        }
                        uint _6092 = _5887 - _5988;
                        if (_6092 >= uint(_503._m21.w))
                        {
                            _7283 = 1.0;
                            break;
                        }
                        float _6113 = _503._m27[_6092].w * length(in.m_1759 - _503._m27[_6092].xyz);
                        float3 _6131 = ((in.m_1759 + (_2292 * (_6113 * _503._m25.x))) + (_5921 * (_6113 * _503._m25.y))) - _503._m27[_6092].xyz;
                        float3 _6133 = abs(_6131);
                        float _6135 = _6133.x;
                        float _6137 = _6133.y;
                        bool _6138 = _6135 >= _6137;
                        bool _6146;
                        if (_6138)
                        {
                            _6146 = _6135 >= _6133.z;
                        }
                        else
                        {
                            _6146 = _6138;
                        }
                        float _7257;
                        int _7259;
                        if (_6146)
                        {
                            _7259 = (_6131.x > 0.0) ? 0 : 1;
                            _7257 = _6135;
                        }
                        else
                        {
                            float _6158 = _6133.z;
                            bool _6159 = _6137 >= _6158;
                            int _7260;
                            if (_6159)
                            {
                                _7260 = (_6131.y > 0.0) ? 2 : 3;
                            }
                            else
                            {
                                _7260 = (_6131.z > 0.0) ? 4 : 5;
                            }
                            _7259 = _7260;
                            _7257 = _6159 ? _6137 : _6158;
                        }
                        if (_7257 <= 0.0)
                        {
                            _7283 = 1.0;
                            break;
                        }
                        float2 _6196 = float2(dot(_6131, _1170[_7259]), dot(_6131, _1179[_7259])) / float2(_7257 * _503._m24.z);
                        float _6203 = _503._m28[_6092].z + (_503._m28[_6092].w / _7257);
                        if (_6203 > 1.0)
                        {
                            _7283 = 1.0;
                            break;
                        }
                        float2 _6221 = _503._m28[_6092].xy + (float2(float(spvSMod(_7259, 3)), float(_7259 / 3)) * _503._m24.xy);
                        float2 _6461 = _503._m22.xy * 0.5;
                        float2 _6466 = _6221 + (float2(0.5 + (0.5 * _6196.x), 0.5 - (0.5 * _6196.y)) * _503._m24.xy);
                        float4 _6479 = float4(_6221 + _6461, (_6221 + _503._m24.xy) - _6461);
                        float _7271;
                        do
                        {
                            int _6505 = int(_503._m22.z);
                            if (_6505 <= 0)
                            {
                                _7271 = spvDepthCast(_521).sample_compare(_521Smplr, float3(fast::clamp(_6466, _6479.xy, _6479.zw), _6203).xy, _6203);
                                break;
                            }
                            float2 _6528 = (_6466 / _503._m22.xy) + float2(0.5);
                            float2 _6529 = floor(_6528);
                            float2 _6534 = _6528 - _6529;
                            float2 _6537 = _6529 - float2(0.5);
                            bool _6541 = _6505 == 1;
                            if (_6541)
                            {
                                float2 _6544 = _6534 * 2.0;
                                _6489[0] = float2(3.0) - _6544;
                                _6489[1] = float2(1.0) + _6544;
                                _6490[0] = ((float2(2.0) - _6534) / _6489[0]) - float2(1.0);
                                _6490[1] = (_6534 / _6489[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _6571 = _6534 * 3.0;
                                _6489[0] = float2(4.0) - _6571;
                                _6489[1] = float2(7.0);
                                _6489[2] = float2(1.0) + _6571;
                                _6490[0] = ((float2(3.0) - (_6534 * 2.0)) / _6489[0]) - float2(2.0);
                                _6490[1] = (float2(3.0) + _6534) / _6489[1];
                                _6490[2] = (_6534 / _6489[2]) + float2(2.0);
                            }
                            int _7702 = _6541 ? 2 : 3;
                            int _7261;
                            float _7264;
                            _7264 = 0.0;
                            _7261 = 0;
                            float _7270;
                            for (; _7261 < _7702; _7264 = _7270, _7261++)
                            {
                                _7270 = _7264;
                                for (int _7267 = 0; _7267 < _7702; )
                                {
                                    _7270 += ((_6489[_7267].x * _6489[_7261].y) * spvDepthCast(_521).sample_compare(_521Smplr, float3(fast::clamp(_503._m22.xy * (_6537 + float2(_6490[_7267].x, _6490[_7261].y)), _6479.xy, _6479.zw), _6203).xy, _6203));
                                    _7267++;
                                    continue;
                                }
                            }
                            _7271 = _7264 * (_6541 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _7283 = _7271;
                        break;
                    } while(false);
                    _7351 = _5952 * _7283;
                }
                else
                {
                    _7351 = _5952;
                }
                float3 _2780 = fast::normalize(_5921 + _2281);
                float _2785 = fast::clamp(dot(_7131, _5921), 0.0, 1.0);
                float _2790 = fast::clamp(dot(_7131, _2780), 0.0, 1.0);
                float3 _6676 = _2502 + (_4991 * powr(1.0 - fast::clamp(dot(_2281, _2780), 0.0, 1.0), 5.0));
                float _6690 = ((_2790 * _2790) * _5006) + 1.0;
                _2828 = _7353 + (((((float3(1.0) - _6676) * _2496) + ((_6676 * ((_5001 / ((3.1415927410125732421875 * _6690) * _6690)) * (0.5 / fast::max((_2785 * _5032) + (_7159 * sqrt(((_2785 * _2785) * _5028) + _5001)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875)) * _2785) * _7351);
            }
            _7400 = _7353;
        }
        else
        {
            _7400 = _2728;
        }
        _7397 = _7400;
    }
    float _2854 = -length(_2280);
    float _7442;
    if (_503._m9.w != 0.0)
    {
        float _2878 = _503._m9.w * (in.m_1759 - _503._m6.xyz).y;
        float _7439;
        if (abs(_2878) < 9.9999997473787516355514526367188e-05)
        {
            _7439 = 1.0 - (0.5 * _2878);
        }
        else
        {
            _7439 = (1.0 - exp(fast::min(-_2878, 60.0))) / _2878;
        }
        _7442 = 1.0 - exp((_2854 * (_503._m7.w * exp(fast::min((-_503._m9.w) * (_503._m6.y - _503._m6.w), 30.0)))) * _7439);
    }
    else
    {
        _7442 = 1.0 - exp(_2854 * _503._m7.w);
    }
    float3 _2929 = mix(mix(_7397, _7128, float3(_2241._m1.y)), _503._m7.xyz, float3(_7442));
    float3 _7443;
    if (_503._m33.w > 0.5)
    {
        _7443 = _2929 / (float3(1.0) + _2929);
    }
    else
    {
        _7443 = _2929;
    }
    out.m_2941 = float4(_7443, in.m_2143.w);
    float2 _7517;
    do
    {
        if (in.m_2951.w <= 0.0)
        {
            _7517 = float2(0.0);
            break;
        }
        _7517 = ((in.m_2951.xy / float2(in.m_2951.w)) - (in.m_2950.xy / float2(in.m_2950.w))) * float2(0.5, -0.5);
        break;
    } while(false);
    _2949 = _7517;
    return out;
}

