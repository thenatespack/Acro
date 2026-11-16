// Generated from mesh.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 6b84d7b5344f42c5
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

struct _178
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

struct _1441
{
    float4 _m0[1024];
};

struct _1477
{
    float4 _m0[1024];
};

struct _1485
{
    float4 _m0[1024];
};

struct _1582
{
    uint4 _m0[1024];
};

struct _1604
{
    uint4 _m0[1024];
};

struct _1819
{
    float4 _m0;
    float4 _m1;
    float4 _m2;
    float4 _m3;
    float4 _m4;
    float4 _m5;
    float4 _m6;
};

constant spvUnsafeArray<float3, 4> _554 = spvUnsafeArray<float3, 4>({ float3(1.0, 0.449999988079071044921875, 0.449999988079071044921875), float3(0.449999988079071044921875, 1.0, 0.449999988079071044921875), float3(0.5, 0.60000002384185791015625, 1.0), float3(1.0, 1.0, 0.4000000059604644775390625) });
constant spvUnsafeArray<float3, 6> _858 = spvUnsafeArray<float3, 6>({ float3(0.0, 0.0, 1.0), float3(0.0, 0.0, -1.0), float3(-1.0, 0.0, 0.0), float3(-1.0, 0.0, 0.0), float3(-1.0, 0.0, 0.0), float3(1.0, 0.0, 0.0) });
constant spvUnsafeArray<float3, 6> _867 = spvUnsafeArray<float3, 6>({ float3(0.0, 1.0, 0.0), float3(0.0, 1.0, 0.0), float3(0.0, 0.0, -1.0), float3(0.0, 0.0, 1.0), float3(0.0, 1.0, 0.0), float3(0.0, 1.0, 0.0) });
constant spvUnsafeArray<int4, 6> _1277 = spvUnsafeArray<int4, 6>({ int4(0, 0, 512, 256), int4(0, 256, 256, 128), int4(256, 256, 128, 64), int4(384, 256, 64, 32), int4(448, 256, 32, 16), int4(480, 256, 16, 8) });

struct fragment_main_out
{
    float4 m_2742 [[color(0)]];
};

struct fragment_main_in
{
    float3 m_1451 [[user(locn0)]];
    float3 m_1893 [[user(locn1)]];
    float2 m_1826 [[user(locn2)]];
    float4 m_1849 [[user(locn3)]];
    float4 m_2054 [[user(locn5)]];
    float4 m_2751 [[user(locn6)]];
    float4 m_2752 [[user(locn7)]];
    float4 m_1902 [[user(locn8)]];
};

fragment fragment_main_out fragment_main(fragment_main_in in [[stage_in]], constant _1819& _1821 [[buffer(2)]], constant _1441& _1443 [[buffer(3)]], constant _1477& _1479 [[buffer(4)]], constant _1485& _1487 [[buffer(5)]], constant _1582& _1584 [[buffer(6)]], constant _1604& _1606 [[buffer(7)]], constant _178& _180 [[buffer(15)]], texture2d<float> _200 [[texture(0)]], texture2d<float> _1842 [[texture(1)]], texture2d<float> _2259 [[texture(2)]], texture2d<float> _1931 [[texture(3)]], texture2d<float> _1770 [[texture(4)]], texture2d<float> _2632 [[texture(5)]], texture2d<float> _1215 [[texture(6)]], texture2d<float> _1321 [[texture(7)]], sampler _200Smplr [[sampler(0)]], sampler _1217 [[sampler(1)]], sampler _1323 [[sampler(7)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])
{
    float2 _2750;
    fragment_main_out out = {};
    float2 _1840 = float2(dot(_1821._m2.xy, in.m_1826) + _1821._m2.z, dot(_1821._m3.xy, in.m_1826) + _1821._m3.z);
    float4 _1847 = _1842.sample(_1217, _1840);
    float3 _1858 = (in.m_1849.xyz * _1821._m0.xyz) * _1847.xyz;
    float3 _6597;
    if (_1821._m1.x > 0.5)
    {
        float2 _1879 = floor(in.m_1451.xz * float2(0.5));
        _6597 = _1858 * ((mod(abs(_1879.x + _1879.y), 2.0) < 0.5) ? 1.0 : 0.75);
    }
    else
    {
        _6597 = _1858;
    }
    float3 _1895 = fast::normalize(in.m_1893);
    float3 _6510;
    if (_1821._m6.y > 0.5)
    {
        float3 _1911 = in.m_1902.xyz - (_1895 * dot(_1895, in.m_1902.xyz));
        float3 _6511;
        if (dot(_1911, _1911) > 9.9999999600419720025001879548654e-13)
        {
            float3 _1920 = fast::normalize(_1911);
            float4 _1936 = _1931.sample(_1217, _1840);
            float3 _6502;
            if (_1821._m6.z > 0.5)
            {
                float2 _6501;
                if (_1821._m6.z > 1.5)
                {
                    _6501 = _1936.xw;
                }
                else
                {
                    _6501 = _1936.xy;
                }
                float2 _1958 = (_6501 * 2.0) - float2(1.0);
                _6502 = float3(_1958, sqrt(fast::clamp(1.0 - dot(_1958, _1958), 0.0, 1.0)));
            }
            else
            {
                _6502 = (_1936.xyz * 2.0) - float3(1.0);
            }
            float2 _1980 = _6502.xy * _1821._m4.z;
            _6511 = fast::normalize(((_1920 * _1980.x) + ((cross(_1895, _1920) * ((in.m_1902.w < 0.0) ? (-1.0) : 1.0)) * _1980.y)) + (_1895 * _6502.z));
        }
        else
        {
            _6511 = _1895;
        }
        _6510 = _6511;
    }
    else
    {
        _6510 = _1895;
    }
    bool _2004 = _1821._m5.w > 0.5;
    float _6507;
    if (_2004)
    {
        _6507 = fast::clamp(_1821._m1.z, 0.0, 1.0);
    }
    else
    {
        _6507 = 0.0;
    }
    bool _2022;
    if (_2004)
    {
        _2022 = !gl_FrontFacing;
    }
    else
    {
        _2022 = _2004;
    }
    float3 _6627;
    if (_2022 && (_6507 <= 0.0))
    {
        _6627 = -_6510;
    }
    else
    {
        _6627 = _6510;
    }
    float3 _2034 = fast::normalize(_180._m4.xyz);
    float3 _2040 = _180._m6.xyz - in.m_1451;
    float3 _2041 = fast::normalize(_2040);
    float3 _2046 = fast::normalize(_2034 + _2041);
    float3 _2052 = _1895 * (gl_FrontFacing ? 1.0 : (-1.0));
    bool _2057 = in.m_2054.x > 0.5;
    float3 _6623;
    float _6660;
    if ((_180._m5.w > 0.5) && _2057)
    {
        float _6567;
        float3 _6568;
        do
        {
            int _2810 = int(_180._m21.x);
            float _2818 = dot(_180._m20.xyz, in.m_1451) + _180._m20.w;
            int _6512;
            _6512 = 0;
            for (;;)
            {
                bool _2824 = _6512 < (_2810 - 1);
                bool _2832;
                if (_2824)
                {
                    _2832 = _2818 > _180._m16[_6512];
                }
                else
                {
                    _2832 = _2824;
                }
                if (_2832)
                {
                    _6512++;
                    continue;
                }
                else
                {
                    break;
                }
            }
            if (_2818 > _180._m16[_6512])
            {
                _6568 = float3(1.0);
                _6567 = 1.0;
                break;
            }
            float _6525;
            do
            {
                float4 _2934 = _180._m14[_6512] * float4(in.m_1451 + (_2052 * _180._m18[_6512]), 1.0);
                float _2937 = _2934.x;
                bool _2938 = _2937 < 0.0;
                bool _2945;
                if (!_2938)
                {
                    _2945 = _2937 > 1.0;
                }
                else
                {
                    _2945 = _2938;
                }
                bool _2952;
                if (!_2945)
                {
                    _2952 = _2934.y < 0.0;
                }
                else
                {
                    _2952 = _2945;
                }
                bool _2959;
                if (!_2952)
                {
                    _2959 = _2934.y > 1.0;
                }
                else
                {
                    _2959 = _2952;
                }
                if (_2959)
                {
                    _6525 = 1.0;
                    break;
                }
                float2 _2972 = float2(float(_6512 & 1), float(_6512 >> 1)) * _180._m23.xy;
                float _2979 = fast::min(_2934.z, 1.0) - _180._m19[_6512];
                float2 _2998 = _180._m22.xy * 0.5;
                float2 _3003 = _2972 + (_2934.xy * _180._m23.xy);
                float4 _3016 = float4(_2972 + _2998, (_2972 + _180._m23.xy) - _2998);
                float _6524;
                do
                {
                    int _3042 = int(_180._m22.z);
                    if (_3042 <= 0)
                    {
                        _6524 = spvDepthCast(_200).sample_compare(_200Smplr, float3(fast::clamp(_3003, _3016.xy, _3016.zw), _2979).xy, _2979);
                        break;
                    }
                    float2 _3065 = (_3003 / _180._m22.xy) + float2(0.5);
                    float2 _3066 = floor(_3065);
                    float2 _3071 = _3065 - _3066;
                    float2 _3074 = _3066 - float2(0.5);
                    bool _3078 = _3042 == 1;
                    spvUnsafeArray<float2, 3> _3026;
                    spvUnsafeArray<float2, 3> _3027;
                    if (_3078)
                    {
                        float2 _3081 = _3071 * 2.0;
                        _3026[0] = float2(3.0) - _3081;
                        _3026[1] = float2(1.0) + _3081;
                        _3027[0] = ((float2(2.0) - _3071) / _3026[0]) - float2(1.0);
                        _3027[1] = (_3071 / _3026[1]) + float2(1.0);
                    }
                    else
                    {
                        float2 _3108 = _3071 * 3.0;
                        _3026[0] = float2(4.0) - _3108;
                        _3026[1] = float2(7.0);
                        _3026[2] = float2(1.0) + _3108;
                        _3027[0] = ((float2(3.0) - (_3071 * 2.0)) / _3026[0]) - float2(2.0);
                        _3027[1] = (float2(3.0) + _3071) / _3026[1];
                        _3027[2] = (_3071 / _3026[2]) + float2(2.0);
                    }
                    int _7086 = _3078 ? 2 : 3;
                    int _6514;
                    float _6517;
                    _6517 = 0.0;
                    _6514 = 0;
                    float _6523;
                    for (; _6514 < _7086; _6517 = _6523, _6514++)
                    {
                        _6523 = _6517;
                        for (int _6520 = 0; _6520 < _7086; )
                        {
                            _6523 += ((_3026[_6520].x * _3026[_6514].y) * spvDepthCast(_200).sample_compare(_200Smplr, float3(fast::clamp(_180._m22.xy * (_3074 + float2(_3027[_6520].x, _3027[_6514].y)), _3016.xy, _3016.zw), _2979).xy, _2979));
                            _6520++;
                            continue;
                        }
                    }
                    _6524 = _6517 * (_3078 ? 0.0625 : 0.0069444444961845874786376953125);
                    break;
                } while(false);
                _6525 = _6524;
                break;
            } while(false);
            float3 _6562;
            float _6565;
            if (_2818 > _180._m17[_6512])
            {
                float _2872 = (_2818 - _180._m17[_6512]) / (_180._m16[_6512] - _180._m17[_6512]);
                int _2874 = _6512 + 1;
                float3 _6563;
                float _6566;
                if (_2874 < _2810)
                {
                    float _6545;
                    do
                    {
                        float4 _3221 = _180._m14[_2874] * float4(in.m_1451 + (_2052 * _180._m18[_2874]), 1.0);
                        float _3224 = _3221.x;
                        bool _3225 = _3224 < 0.0;
                        bool _3232;
                        if (!_3225)
                        {
                            _3232 = _3224 > 1.0;
                        }
                        else
                        {
                            _3232 = _3225;
                        }
                        bool _3239;
                        if (!_3232)
                        {
                            _3239 = _3221.y < 0.0;
                        }
                        else
                        {
                            _3239 = _3232;
                        }
                        bool _3246;
                        if (!_3239)
                        {
                            _3246 = _3221.y > 1.0;
                        }
                        else
                        {
                            _3246 = _3239;
                        }
                        if (_3246)
                        {
                            _6545 = 1.0;
                            break;
                        }
                        float2 _3259 = float2(float(_2874 & 1), float(_2874 >> 1)) * _180._m23.xy;
                        float _3266 = fast::min(_3221.z, 1.0) - _180._m19[_2874];
                        float2 _3285 = _180._m22.xy * 0.5;
                        float2 _3290 = _3259 + (_3221.xy * _180._m23.xy);
                        float4 _3303 = float4(_3259 + _3285, (_3259 + _180._m23.xy) - _3285);
                        float _6544;
                        do
                        {
                            int _3329 = int(_180._m22.z);
                            if (_3329 <= 0)
                            {
                                _6544 = spvDepthCast(_200).sample_compare(_200Smplr, float3(fast::clamp(_3290, _3303.xy, _3303.zw), _3266).xy, _3266);
                                break;
                            }
                            float2 _3352 = (_3290 / _180._m22.xy) + float2(0.5);
                            float2 _3353 = floor(_3352);
                            float2 _3358 = _3352 - _3353;
                            float2 _3361 = _3353 - float2(0.5);
                            bool _3365 = _3329 == 1;
                            spvUnsafeArray<float2, 3> _3313;
                            spvUnsafeArray<float2, 3> _3314;
                            if (_3365)
                            {
                                float2 _3368 = _3358 * 2.0;
                                _3313[0] = float2(3.0) - _3368;
                                _3313[1] = float2(1.0) + _3368;
                                _3314[0] = ((float2(2.0) - _3358) / _3313[0]) - float2(1.0);
                                _3314[1] = (_3358 / _3313[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _3395 = _3358 * 3.0;
                                _3313[0] = float2(4.0) - _3395;
                                _3313[1] = float2(7.0);
                                _3313[2] = float2(1.0) + _3395;
                                _3314[0] = ((float2(3.0) - (_3358 * 2.0)) / _3313[0]) - float2(2.0);
                                _3314[1] = (float2(3.0) + _3358) / _3313[1];
                                _3314[2] = (_3358 / _3313[2]) + float2(2.0);
                            }
                            int _7088 = _3365 ? 2 : 3;
                            int _6534;
                            float _6537;
                            _6537 = 0.0;
                            _6534 = 0;
                            float _6543;
                            for (; _6534 < _7088; _6537 = _6543, _6534++)
                            {
                                _6543 = _6537;
                                for (int _6540 = 0; _6540 < _7088; )
                                {
                                    _6543 += ((_3313[_6540].x * _3313[_6534].y) * spvDepthCast(_200).sample_compare(_200Smplr, float3(fast::clamp(_180._m22.xy * (_3361 + float2(_3314[_6540].x, _3314[_6534].y)), _3303.xy, _3303.zw), _3266).xy, _3266));
                                    _6540++;
                                    continue;
                                }
                            }
                            _6544 = _6537 * (_3365 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _6545 = _6544;
                        break;
                    } while(false);
                    _6566 = mix(_6525, _6545, _2872);
                    _6563 = mix(_554[_6512], _554[_2874], float3(_2872));
                }
                else
                {
                    _6566 = mix(_6525, 1.0, _2872);
                    _6563 = _554[_6512];
                }
                _6565 = _6566;
                _6562 = _6563;
            }
            else
            {
                _6565 = _6525;
                _6562 = _554[_6512];
            }
            _6568 = select(float3(1.0), _6562, bool3(_180._m22.w > 0.5));
            _6567 = _6565;
            break;
        } while(false);
        _6660 = _6567;
        _6623 = _6597 * _6568;
    }
    else
    {
        _6660 = 1.0;
        _6623 = _6597;
    }
    float3 _2083 = _180._m5.xyz * _180._m4.w;
    bool _2087 = _1821._m6.w > 0.5;
    float _6620;
    if (_2087)
    {
        _6620 = 1.0;
    }
    else
    {
        _6620 = 1.0 + (_1821._m4.w * (_1770.sample(_1217, _1840).x - 1.0));
    }
    float _2107 = abs(in.m_1902.w);
    float _6736;
    if (_2107 > 0.0)
    {
        _6736 = _6620 * fast::min(_2107, 1.0);
    }
    else
    {
        _6736 = _6620;
    }
    float3 _6894;
    if (!_2004)
    {
        float _2123 = dot(_6627, _2034);
        float3 _6886;
        if (_180._m29.x > 0.5)
        {
            float _3546 = (_180._m29.z * _6627.x) - (_180._m29.w * _6627.z);
            float _3559 = (_180._m29.w * _6627.x) + (_180._m29.z * _6627.z);
            float _3577 = 1.09254801273345947265625 * _3546;
            spvUnsafeArray<float, 9> _6309 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _6627.y, 0.48860299587249755859375 * _3559, 0.48860299587249755859375 * _3546, _3577 * _6627.y, (1.09254801273345947265625 * _6627.y) * _3559, 0.3153919875621795654296875 * (((3.0 * _3559) * _3559) - 1.0), _3577 * _3559, 0.546274006366729736328125 * ((_3546 * _3546) - (_6627.y * _6627.y)) });
            spvUnsafeArray<float, 9> _3491 = _6309;
            float3 _6885;
            _6885 = float3(0.0);
            for (int _6884 = 0; _6884 < 9; )
            {
                _6885 += (_1215.read(uint2((int2(496, 256) + int2(_6884, 0))), 0).xyz * _3491[_6884]);
                _6884++;
                continue;
            }
            _6886 = fast::max(_6885, float3(0.0)) * _180._m29.y;
        }
        else
        {
            _6886 = mix(_180._m9.xyz, _180._m8.xyz, float3((_6627.y * 0.5) + 0.5)) * _180._m8.w;
        }
        float3 _2173 = (_6623 * ((_6886 * _6736) + ((_2083 * fast::max(_2123, 0.0)) * _6660))) + ((_2083 * ((powr(fast::max(dot(_6627, _2046), 0.0), _1821._m1.w) * _1821._m1.z) * step(0.0, _2123))) * _6660);
        float3 _6895;
        if (_180._m13.w > 0.5)
        {
            float2 _3662 = fast::clamp(floor(gl_FragCoord.xy * _180._m12.xy), float2(0.0), _180._m13.xy - float2(1.0));
            uint _3690 = uint((((fast::clamp(floor((log2(fast::max(dot(_180._m11.xyz, in.m_1451) + _180._m11.w, 9.9999999747524270787835121154785e-07)) * _180._m12.z) + _180._m12.w), 0.0, _180._m13.z - 1.0) * _180._m13.y) + _3662.y) * _180._m13.x) + _3662.x);
            uint _3692 = _3690 >> uint(2);
            uint _3694 = _3690 & 3u;
            uint _3698 = _1584._m0[_3692][_3694] & 65535u;
            uint _3700 = _1584._m0[_3692][_3694] >> uint(16);
            float3 _6896;
            _6896 = _2173;
            float3 _2254;
            spvUnsafeArray<float2, 3> _4108;
            spvUnsafeArray<float2, 3> _4109;
            spvUnsafeArray<float2, 3> _4321;
            spvUnsafeArray<float2, 3> _4322;
            for (uint _6893 = _3698; _6893 < (_3698 + _3700); _6896 = _2254, _6893++)
            {
                uint _3706 = _6893 / 3u;
                uint _3719 = (_1606._m0[_3706 >> uint(2)][_3706 & 3u] >> ((_6893 - (_3706 * 3u)) * 10u)) & 1023u;
                float3 _3736 = _1443._m0[_3719].xyz - in.m_1451;
                float _3739 = dot(_3736, _3736);
                float _3743 = _3739 * _1443._m0[_3719].w;
                float _3748 = fast::clamp(1.0 - (_3743 * _3743), 0.0, 1.0);
                float3 _3753 = _3736 * rsqrt(fast::max(_3739, 9.9999999392252902907785028219223e-09));
                float _3771 = fast::clamp((dot(-_3753, _1487._m0[_3719].xyz) * _1479._m0[_3719].w) + _1487._m0[_3719].w, 0.0, 1.0);
                float3 _3784 = _1479._m0[_3719].xyz * ((((_3748 * _3748) * _3771) * _3771) / fast::max(_3739, 9.9999997473787516355514526367188e-05));
                float3 _7022;
                if (_2057)
                {
                    float _6968;
                    do
                    {
                        uint _3820 = uint(_180._m21.z);
                        if (_3719 < _3820)
                        {
                            float _3842 = _180._m26[_3719].z * fast::max((_180._m15[_3719] * float4(in.m_1451, 1.0)).w, 0.0);
                            float4 _3866 = _180._m15[_3719] * float4((in.m_1451 + (_2052 * (_3842 * _180._m25.x))) + (_3753 * (_3842 * _180._m25.y)), 1.0);
                            float _3868 = _3866.w;
                            if (_3868 <= 0.0)
                            {
                                _6968 = 1.0;
                                break;
                            }
                            float3 _3877 = _3866.xyz / float3(_3868);
                            float _3879 = _3877.x;
                            bool _3880 = _3879 < 0.0;
                            bool _3887;
                            if (!_3880)
                            {
                                _3887 = _3879 > 1.0;
                            }
                            else
                            {
                                _3887 = _3880;
                            }
                            bool _3894;
                            if (!_3887)
                            {
                                _3894 = _3877.y < 0.0;
                            }
                            else
                            {
                                _3894 = _3887;
                            }
                            bool _3901;
                            if (!_3894)
                            {
                                _3901 = _3877.y > 1.0;
                            }
                            else
                            {
                                _3901 = _3894;
                            }
                            bool _3908;
                            if (!_3901)
                            {
                                _3908 = _3877.z > 1.0;
                            }
                            else
                            {
                                _3908 = _3901;
                            }
                            if (_3908)
                            {
                                _6968 = 1.0;
                                break;
                            }
                            float _3914 = _3877.z;
                            float2 _4080 = _180._m22.xy * 0.5;
                            float2 _4085 = _180._m26[_3719].xy + (_3877.xy * _180._m23.zw);
                            float4 _4098 = float4(_180._m26[_3719].xy + _4080, (_180._m26[_3719].xy + _180._m23.zw) - _4080);
                            float _6967;
                            do
                            {
                                int _4124 = int(_180._m22.z);
                                if (_4124 <= 0)
                                {
                                    float2 _4134 = fast::clamp(_4085, _4098.xy, _4098.zw);
                                    _6967 = spvDepthCast(_200).sample_compare(_200Smplr, float3(_4134, _3914).xy, _3914);
                                    break;
                                }
                                float2 _4147 = (_4085 / _180._m22.xy) + float2(0.5);
                                float2 _4148 = floor(_4147);
                                float2 _4153 = _4147 - _4148;
                                float2 _4156 = _4148 - float2(0.5);
                                bool _4160 = _4124 == 1;
                                if (_4160)
                                {
                                    float2 _4163 = _4153 * 2.0;
                                    _4108[0] = float2(3.0) - _4163;
                                    _4108[1] = float2(1.0) + _4163;
                                    _4109[0] = ((float2(2.0) - _4153) / _4108[0]) - float2(1.0);
                                    _4109[1] = (_4153 / _4108[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _4190 = _4153 * 3.0;
                                    _4108[0] = float2(4.0) - _4190;
                                    _4108[1] = float2(7.0);
                                    _4108[2] = float2(1.0) + _4190;
                                    _4109[0] = ((float2(3.0) - (_4153 * 2.0)) / _4108[0]) - float2(2.0);
                                    _4109[1] = (float2(3.0) + _4153) / _4108[1];
                                    _4109[2] = (_4153 / _4108[2]) + float2(2.0);
                                }
                                int _7093 = _4160 ? 2 : 3;
                                int _6957;
                                float _6960;
                                _6960 = 0.0;
                                _6957 = 0;
                                float _6966;
                                for (; _6957 < _7093; _6960 = _6966, _6957++)
                                {
                                    _6966 = _6960;
                                    for (int _6963 = 0; _6963 < _7093; )
                                    {
                                        _6966 += ((_4108[_6963].x * _4108[_6957].y) * spvDepthCast(_200).sample_compare(_200Smplr, float3(fast::clamp(_180._m22.xy * (_4156 + float2(_4109[_6963].x, _4109[_6957].y)), _4098.xy, _4098.zw), _3914).xy, _3914));
                                        _6963++;
                                        continue;
                                    }
                                }
                                _6967 = _6960 * (_4160 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _6968 = _6967;
                            break;
                        }
                        uint _3924 = _3719 - _3820;
                        if (_3924 >= uint(_180._m21.w))
                        {
                            _6968 = 1.0;
                            break;
                        }
                        float _3945 = _180._m27[_3924].w * length(in.m_1451 - _180._m27[_3924].xyz);
                        float3 _3963 = ((in.m_1451 + (_2052 * (_3945 * _180._m25.x))) + (_3753 * (_3945 * _180._m25.y))) - _180._m27[_3924].xyz;
                        float3 _3965 = abs(_3963);
                        float _3967 = _3965.x;
                        float _3969 = _3965.y;
                        bool _3970 = _3967 >= _3969;
                        bool _3978;
                        if (_3970)
                        {
                            _3978 = _3967 >= _3965.z;
                        }
                        else
                        {
                            _3978 = _3970;
                        }
                        float _6942;
                        int _6944;
                        if (_3978)
                        {
                            _6944 = (_3963.x > 0.0) ? 0 : 1;
                            _6942 = _3967;
                        }
                        else
                        {
                            float _3990 = _3965.z;
                            bool _3991 = _3969 >= _3990;
                            int _6945;
                            if (_3991)
                            {
                                _6945 = (_3963.y > 0.0) ? 2 : 3;
                            }
                            else
                            {
                                _6945 = (_3963.z > 0.0) ? 4 : 5;
                            }
                            _6944 = _6945;
                            _6942 = _3991 ? _3969 : _3990;
                        }
                        if (_6942 <= 0.0)
                        {
                            _6968 = 1.0;
                            break;
                        }
                        float2 _4028 = float2(dot(_3963, _858[_6944]), dot(_3963, _867[_6944])) / float2(_6942 * _180._m24.z);
                        float _4035 = _180._m28[_3924].z + (_180._m28[_3924].w / _6942);
                        if (_4035 > 1.0)
                        {
                            _6968 = 1.0;
                            break;
                        }
                        float2 _4053 = _180._m28[_3924].xy + (float2(float(spvSMod(_6944, 3)), float(_6944 / 3)) * _180._m24.xy);
                        float2 _4293 = _180._m22.xy * 0.5;
                        float2 _4298 = _4053 + (float2(0.5 + (0.5 * _4028.x), 0.5 - (0.5 * _4028.y)) * _180._m24.xy);
                        float4 _4311 = float4(_4053 + _4293, (_4053 + _180._m24.xy) - _4293);
                        float _6956;
                        do
                        {
                            int _4337 = int(_180._m22.z);
                            if (_4337 <= 0)
                            {
                                _6956 = spvDepthCast(_200).sample_compare(_200Smplr, float3(fast::clamp(_4298, _4311.xy, _4311.zw), _4035).xy, _4035);
                                break;
                            }
                            float2 _4360 = (_4298 / _180._m22.xy) + float2(0.5);
                            float2 _4361 = floor(_4360);
                            float2 _4366 = _4360 - _4361;
                            float2 _4369 = _4361 - float2(0.5);
                            bool _4373 = _4337 == 1;
                            if (_4373)
                            {
                                float2 _4376 = _4366 * 2.0;
                                _4321[0] = float2(3.0) - _4376;
                                _4321[1] = float2(1.0) + _4376;
                                _4322[0] = ((float2(2.0) - _4366) / _4321[0]) - float2(1.0);
                                _4322[1] = (_4366 / _4321[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _4403 = _4366 * 3.0;
                                _4321[0] = float2(4.0) - _4403;
                                _4321[1] = float2(7.0);
                                _4321[2] = float2(1.0) + _4403;
                                _4322[0] = ((float2(3.0) - (_4366 * 2.0)) / _4321[0]) - float2(2.0);
                                _4322[1] = (float2(3.0) + _4366) / _4321[1];
                                _4322[2] = (_4366 / _4321[2]) + float2(2.0);
                            }
                            int _7096 = _4373 ? 2 : 3;
                            int _6946;
                            float _6949;
                            _6949 = 0.0;
                            _6946 = 0;
                            float _6955;
                            for (; _6946 < _7096; _6949 = _6955, _6946++)
                            {
                                _6955 = _6949;
                                for (int _6952 = 0; _6952 < _7096; )
                                {
                                    _6955 += ((_4321[_6952].x * _4321[_6946].y) * spvDepthCast(_200).sample_compare(_200Smplr, float3(fast::clamp(_180._m22.xy * (_4369 + float2(_4322[_6952].x, _4322[_6946].y)), _4311.xy, _4311.zw), _4035).xy, _4035));
                                    _6952++;
                                    continue;
                                }
                            }
                            _6956 = _6949 * (_4373 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _6968 = _6956;
                        break;
                    } while(false);
                    _7022 = _3784 * _6968;
                }
                else
                {
                    _7022 = _3784;
                }
                float _2225 = dot(_6627, _3753);
                _2254 = _6896 + (((_6623 * fast::max(_2225, 0.0)) * _7022) + (_7022 * ((powr(fast::max(dot(_6627, fast::normalize(_3753 + _2041)), 0.0), _1821._m1.w) * _1821._m1.z) * step(0.0, _2225))));
            }
            _6895 = _6896;
        }
        else
        {
            _6895 = _2173;
        }
        _6894 = _6895;
    }
    else
    {
        float4 _2264 = _2259.sample(_1217, _1840);
        float _2271 = fast::clamp(_1821._m4.x * _2264.z, 0.0, 1.0);
        float _2279 = fast::clamp(_1821._m4.y * _2264.y, 0.04500000178813934326171875, 1.0);
        float _2283 = _2279 * _2279;
        float3 _2288 = _6623 * (1.0 - _2271);
        float3 _2294 = mix(float3(0.039999999105930328369140625), _6623, float3(_2271));
        bool _2298 = _6507 > 0.0;
        float3 _6650;
        if (_2298)
        {
            float3 _2303 = dfdx(in.m_1451);
            float3 _2305 = dfdy(in.m_1451);
            float3 _2306 = cross(_2303, _2305);
            float3 _6651;
            if (dot(_2306, _2306) > 9.9999996826552253889678874634872e-21)
            {
                _6651 = fast::normalize((fast::normalize(_2306) * ((dot(_2306, _2041) < 0.0) ? (-1.0) : 1.0)) + (_6627 - _1895));
            }
            else
            {
                _6651 = _6627;
            }
            _6650 = _6651;
        }
        else
        {
            _6650 = _6627;
        }
        float _2332 = fast::max(dot(_6650, _2041), 9.9999997473787516355514526367188e-05);
        float _2341 = dot(_6650, _2034);
        float _2342 = fast::clamp(_2341, 0.0, 1.0);
        float _2347 = fast::clamp(dot(_6650, _2046), 0.0, 1.0);
        float _2352 = fast::clamp(dot(_2041, _2046), 0.0, 1.0);
        float _6654;
        float _6655;
        if (_2298)
        {
            _6655 = fast::max(_2332, 0.5);
            _6654 = fast::max(_2352, 0.5);
        }
        else
        {
            _6655 = _2332;
            _6654 = _2352;
        }
        float3 _4505 = float3(1.0) - _2294;
        float3 _4508 = _2294 + (_4505 * powr(1.0 - _6654, 5.0));
        float _4515 = _2283 * _2283;
        float _4520 = _4515 - 1.0;
        float _4522 = ((_2347 * _2347) * _4520) + 1.0;
        float _4542 = 1.0 - _4515;
        float _4546 = sqrt(((_6655 * _6655) * _4542) + _4515);
        float3 _2398 = (((((float3(1.0) - _4508) * _2288) * fast::clamp(dot(_6627, _2034), 0.0, 1.0)) + (((_4508 * ((_4515 / ((3.1415927410125732421875 * _4522) * _4522)) * (0.5 / fast::max((_2342 * _4546) + (_6655 * sqrt(((_2342 * _2342) * _4542) + _4515)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875) * _2342)) * _2083) * _6660;
        float3 _6750;
        if (_2298)
        {
            _6750 = _2398 + (((((_2288 * _2083) * _6660) * _6507) * fast::clamp(-_2341, 0.0, 1.0)) * (0.3499999940395355224609375 + (0.64999997615814208984375 * powr(fast::clamp(dot(-_2041, _2034), 0.0, 1.0), 3.0))));
        }
        else
        {
            _6750 = _2398;
        }
        float3 _6685;
        float2 _6701;
        float3 _6713;
        if (_180._m29.x > 0.5)
        {
            float4 _4579 = _1321.sample(_1323, (((float2(_6655, _2279) * 31.0) + float2(0.5)) * float2(0.03125)));
            float _4638 = (_180._m29.z * _6627.x) - (_180._m29.w * _6627.z);
            float _4651 = (_180._m29.w * _6627.x) + (_180._m29.z * _6627.z);
            float _4669 = 1.09254801273345947265625 * _4638;
            spvUnsafeArray<float, 9> _6290 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _6627.y, 0.48860299587249755859375 * _4651, 0.48860299587249755859375 * _4638, _4669 * _6627.y, (1.09254801273345947265625 * _6627.y) * _4651, 0.3153919875621795654296875 * (((3.0 * _4651) * _4651) - 1.0), _4669 * _4651, 0.546274006366729736328125 * ((_4638 * _4638) - (_6627.y * _6627.y)) });
            spvUnsafeArray<float, 9> _4583 = _6290;
            float3 _6668;
            _6668 = float3(0.0);
            for (int _6667 = 0; _6667 < 9; )
            {
                _6668 += (_1215.read(uint2((int2(496, 256) + int2(_6667, 0))), 0).xyz * _4583[_6667]);
                _6667++;
                continue;
            }
            float3 _2452 = reflect(-_2041, _6650);
            float _4764 = _2452.x;
            float _4769 = _2452.z;
            float2 _4801 = float2((precise::atan2((_180._m29.z * _4764) - (_180._m29.w * _4769), -((_180._m29.w * _4764) + (_180._m29.z * _4769))) * 0.15915493667125701904296875) + 0.5, acos(fast::clamp(_2452.y, -1.0, 1.0)) * 0.3183098733425140380859375);
            float _4733 = _2279 * 5.0;
            int _4736 = min(int(_4733), 4);
            float2 _4822 = (_4801 * float2(_1277[_4736].zw)) - float2(0.5);
            float2 _4824 = floor(_4822);
            float2 _4827 = _4822 - _4824;
            int _4830 = int(_4824.x);
            int _4833 = int(_4824.y);
            int _6670;
            if (_4830 < 0)
            {
                _6670 = _4830 + _1277[_4736].z;
            }
            else
            {
                _6670 = _4830;
            }
            int _6671;
            if (_6670 >= _1277[_4736].z)
            {
                _6671 = _6670 - _1277[_4736].z;
            }
            else
            {
                _6671 = _6670;
            }
            int _4853 = _6671 + 1;
            int _7097 = (_4853 == _1277[_4736].z) ? 0 : _4853;
            int _4868 = min((_4833 + 1), (_1277[_4736].w - 1));
            int _4870 = max(_4833, 0);
            float3 _4923 = float3(_4827.x);
            int _4743 = _4736 + 1;
            float2 _4955 = (_4801 * float2(_1277[_4743].zw)) - float2(0.5);
            float2 _4957 = floor(_4955);
            float2 _4960 = _4955 - _4957;
            int _4963 = int(_4957.x);
            int _4966 = int(_4957.y);
            int _6677;
            if (_4963 < 0)
            {
                _6677 = _4963 + _1277[_4743].z;
            }
            else
            {
                _6677 = _4963;
            }
            int _6678;
            if (_6677 >= _1277[_4743].z)
            {
                _6678 = _6677 - _1277[_4743].z;
            }
            else
            {
                _6678 = _6677;
            }
            int _4986 = _6678 + 1;
            int _7098 = (_4986 == _1277[_4743].z) ? 0 : _4986;
            int _5001 = min((_4966 + 1), (_1277[_4743].w - 1));
            int _5003 = max(_4966, 0);
            float3 _5056 = float3(_4960.x);
            float3 _4758 = mix(mix(mix(_1215.read(uint2((_1277[_4736].xy + int2(_6671, _4870))), 0).xyz, _1215.read(uint2((_1277[_4736].xy + int2(_7097, _4870))), 0).xyz, _4923), mix(_1215.read(uint2((_1277[_4736].xy + int2(_6671, _4868))), 0).xyz, _1215.read(uint2((_1277[_4736].xy + int2(_7097, _4868))), 0).xyz, _4923), float3(_4827.y)), mix(mix(_1215.read(uint2((_1277[_4743].xy + int2(_6678, _5003))), 0).xyz, _1215.read(uint2((_1277[_4743].xy + int2(_7098, _5003))), 0).xyz, _5056), mix(_1215.read(uint2((_1277[_4743].xy + int2(_6678, _5001))), 0).xyz, _1215.read(uint2((_1277[_4743].xy + int2(_7098, _5001))), 0).xyz, _5056), float3(_4960.y)), float3(_4733 - float(_4736))) * _180._m29.y;
            _6713 = fast::max(_6668, float3(0.0)) * _180._m29.y;
            _6701 = _4579.xy;
            _6685 = _4758;
        }
        else
        {
            float4 _5074 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * _2279) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);
            float _5076 = _5074.x;
            float3 _5111 = mix(_180._m9.xyz, _180._m8.xyz, float3((_6627.y * 0.5) + 0.5)) * _180._m8.w;
            _6713 = _5111;
            _6701 = (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_5076 * _5076, exp2((-9.27999973297119140625) * _6655)) * _5076) + _5074.y)) + _5074.zw;
            _6685 = mix(mix(_180._m9.xyz, _180._m8.xyz, float3((reflect(-_2041, _6650).y * 0.5) + 0.5)) * _180._m8.w, _5111, float3(_2279));
        }
        bool _2484;
        if (_2087)
        {
            _2484 = _180._m33.z > 0.5;
        }
        else
        {
            _2484 = _2087;
        }
        float3 _6722;
        if (_2484)
        {
            float3 _6698;
            do
            {
                float _5190 = ((_180._m32.x * (1.0 - smoothstep(_180._m33.x * 0.5, _180._m33.x, abs(dot(_180._m31.xyz, in.m_1451) - _180._m31.w)))) * smoothstep(0.5, 0.89999997615814208984375, dot(_2052, _180._m31.xyz))) * (1.0 - smoothstep(_180._m32.y * 0.5, _180._m32.y, _2279));
                if (_5190 <= 0.0)
                {
                    _6698 = _6685;
                    break;
                }
                float4 _5215 = _180._m30 * float4(in.m_1451 + ((_6627 - (_180._m31.xyz * dot(_6627, _180._m31.xyz))) * _180._m32.w), 1.0);
                float2 _5228 = ((float2(_5215.x, -_5215.y) / float2(_5215.w)) * 0.5) + float2(0.5);
                float _5232 = _180._m32.z * _2279;
                float3 _6696;
                float _6697;
                _6697 = 0.0;
                _6696 = float3(0.0);
                for (int _6695 = 0; _6695 < 12; )
                {
                    float _5239 = float(_6695);
                    float _5247 = _5239 * 2.3999631404876708984375;
                    float2 _5259 = _5228 + (float2(cos(_5247) * _180._m33.y, sin(_5247)) * (sqrt((_5239 + 0.5) * 0.083333335816860198974609375) * _5232));
                    float2 _5264 = fast::min(_5259, float2(1.0) - _5259);
                    float _5270 = smoothstep(0.0, 0.039999999105930328369140625, fast::min(_5264.x, _5264.y));
                    float4 _5278 = _1770.sample(_1217, fast::clamp(_5259, float2(0.0), float2(1.0)), level(0.0));
                    float3 _5280 = _5278.xyz;
                    _6697 += (_5278.w * _5270);
                    _6696 += ((_5280 / (float3(1.0) - fast::min(_5280, float3(0.99500000476837158203125)))) * _5270);
                    _6695++;
                    continue;
                }
                _6698 = mix(_6685, (_6696 * float3(0.083333335816860198974609375)) + (_6685 * (1.0 - (_6697 * 0.083333335816860198974609375))), float3(_5190));
                break;
            } while(false);
            _6722 = _6698;
        }
        else
        {
            _6722 = _6685;
        }
        float3 _2504 = (_2294 * _6701.x) + float3(_6701.y);
        float3 _2520 = _6750 + (((((float3(1.0) - _2504) * _2288) * _6713) + (_2504 * _6722)) * _6736);
        float3 _6897;
        if (_180._m13.w > 0.5)
        {
            float2 _5344 = fast::clamp(floor(gl_FragCoord.xy * _180._m12.xy), float2(0.0), _180._m13.xy - float2(1.0));
            uint _5372 = uint((((fast::clamp(floor((log2(fast::max(dot(_180._m11.xyz, in.m_1451) + _180._m11.w, 9.9999999747524270787835121154785e-07)) * _180._m12.z) + _180._m12.w), 0.0, _180._m13.z - 1.0) * _180._m13.y) + _5344.y) * _180._m13.x) + _5344.x);
            uint _5374 = _5372 >> uint(2);
            uint _5376 = _5372 & 3u;
            uint _5380 = _1584._m0[_5374][_5376] & 65535u;
            uint _5382 = _1584._m0[_5374][_5376] >> uint(16);
            float3 _6850;
            _6850 = _2520;
            float3 _2620;
            spvUnsafeArray<float2, 3> _5790;
            spvUnsafeArray<float2, 3> _5791;
            spvUnsafeArray<float2, 3> _6003;
            spvUnsafeArray<float2, 3> _6004;
            for (uint _6753 = _5380; _6753 < (_5380 + _5382); _6850 = _2620, _6753++)
            {
                uint _5388 = _6753 / 3u;
                uint _5401 = (_1606._m0[_5388 >> uint(2)][_5388 & 3u] >> ((_6753 - (_5388 * 3u)) * 10u)) & 1023u;
                float3 _5418 = _1443._m0[_5401].xyz - in.m_1451;
                float _5421 = dot(_5418, _5418);
                float _5425 = _5421 * _1443._m0[_5401].w;
                float _5430 = fast::clamp(1.0 - (_5425 * _5425), 0.0, 1.0);
                float3 _5435 = _5418 * rsqrt(fast::max(_5421, 9.9999999392252902907785028219223e-09));
                float _5453 = fast::clamp((dot(-_5435, _1487._m0[_5401].xyz) * _1479._m0[_5401].w) + _1487._m0[_5401].w, 0.0, 1.0);
                float3 _5466 = _1479._m0[_5401].xyz * ((((_5430 * _5430) * _5453) * _5453) / fast::max(_5421, 9.9999997473787516355514526367188e-05));
                float3 _6848;
                if (_2057)
                {
                    float _6780;
                    do
                    {
                        uint _5502 = uint(_180._m21.z);
                        if (_5401 < _5502)
                        {
                            float _5524 = _180._m26[_5401].z * fast::max((_180._m15[_5401] * float4(in.m_1451, 1.0)).w, 0.0);
                            float4 _5548 = _180._m15[_5401] * float4((in.m_1451 + (_2052 * (_5524 * _180._m25.x))) + (_5435 * (_5524 * _180._m25.y)), 1.0);
                            float _5550 = _5548.w;
                            if (_5550 <= 0.0)
                            {
                                _6780 = 1.0;
                                break;
                            }
                            float3 _5559 = _5548.xyz / float3(_5550);
                            float _5561 = _5559.x;
                            bool _5562 = _5561 < 0.0;
                            bool _5569;
                            if (!_5562)
                            {
                                _5569 = _5561 > 1.0;
                            }
                            else
                            {
                                _5569 = _5562;
                            }
                            bool _5576;
                            if (!_5569)
                            {
                                _5576 = _5559.y < 0.0;
                            }
                            else
                            {
                                _5576 = _5569;
                            }
                            bool _5583;
                            if (!_5576)
                            {
                                _5583 = _5559.y > 1.0;
                            }
                            else
                            {
                                _5583 = _5576;
                            }
                            bool _5590;
                            if (!_5583)
                            {
                                _5590 = _5559.z > 1.0;
                            }
                            else
                            {
                                _5590 = _5583;
                            }
                            if (_5590)
                            {
                                _6780 = 1.0;
                                break;
                            }
                            float _5596 = _5559.z;
                            float2 _5762 = _180._m22.xy * 0.5;
                            float2 _5767 = _180._m26[_5401].xy + (_5559.xy * _180._m23.zw);
                            float4 _5780 = float4(_180._m26[_5401].xy + _5762, (_180._m26[_5401].xy + _180._m23.zw) - _5762);
                            float _6779;
                            do
                            {
                                int _5806 = int(_180._m22.z);
                                if (_5806 <= 0)
                                {
                                    float2 _5816 = fast::clamp(_5767, _5780.xy, _5780.zw);
                                    _6779 = spvDepthCast(_200).sample_compare(_200Smplr, float3(_5816, _5596).xy, _5596);
                                    break;
                                }
                                float2 _5829 = (_5767 / _180._m22.xy) + float2(0.5);
                                float2 _5830 = floor(_5829);
                                float2 _5835 = _5829 - _5830;
                                float2 _5838 = _5830 - float2(0.5);
                                bool _5842 = _5806 == 1;
                                if (_5842)
                                {
                                    float2 _5845 = _5835 * 2.0;
                                    _5790[0] = float2(3.0) - _5845;
                                    _5790[1] = float2(1.0) + _5845;
                                    _5791[0] = ((float2(2.0) - _5835) / _5790[0]) - float2(1.0);
                                    _5791[1] = (_5835 / _5790[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _5872 = _5835 * 3.0;
                                    _5790[0] = float2(4.0) - _5872;
                                    _5790[1] = float2(7.0);
                                    _5790[2] = float2(1.0) + _5872;
                                    _5791[0] = ((float2(3.0) - (_5835 * 2.0)) / _5790[0]) - float2(2.0);
                                    _5791[1] = (float2(3.0) + _5835) / _5790[1];
                                    _5791[2] = (_5835 / _5790[2]) + float2(2.0);
                                }
                                int _7100 = _5842 ? 2 : 3;
                                int _6769;
                                float _6772;
                                _6772 = 0.0;
                                _6769 = 0;
                                float _6778;
                                for (; _6769 < _7100; _6772 = _6778, _6769++)
                                {
                                    _6778 = _6772;
                                    for (int _6775 = 0; _6775 < _7100; )
                                    {
                                        _6778 += ((_5790[_6775].x * _5790[_6769].y) * spvDepthCast(_200).sample_compare(_200Smplr, float3(fast::clamp(_180._m22.xy * (_5838 + float2(_5791[_6775].x, _5791[_6769].y)), _5780.xy, _5780.zw), _5596).xy, _5596));
                                        _6775++;
                                        continue;
                                    }
                                }
                                _6779 = _6772 * (_5842 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _6780 = _6779;
                            break;
                        }
                        uint _5606 = _5401 - _5502;
                        if (_5606 >= uint(_180._m21.w))
                        {
                            _6780 = 1.0;
                            break;
                        }
                        float _5627 = _180._m27[_5606].w * length(in.m_1451 - _180._m27[_5606].xyz);
                        float3 _5645 = ((in.m_1451 + (_2052 * (_5627 * _180._m25.x))) + (_5435 * (_5627 * _180._m25.y))) - _180._m27[_5606].xyz;
                        float3 _5647 = abs(_5645);
                        float _5649 = _5647.x;
                        float _5651 = _5647.y;
                        bool _5652 = _5649 >= _5651;
                        bool _5660;
                        if (_5652)
                        {
                            _5660 = _5649 >= _5647.z;
                        }
                        else
                        {
                            _5660 = _5652;
                        }
                        float _6754;
                        int _6756;
                        if (_5660)
                        {
                            _6756 = (_5645.x > 0.0) ? 0 : 1;
                            _6754 = _5649;
                        }
                        else
                        {
                            float _5672 = _5647.z;
                            bool _5673 = _5651 >= _5672;
                            int _6757;
                            if (_5673)
                            {
                                _6757 = (_5645.y > 0.0) ? 2 : 3;
                            }
                            else
                            {
                                _6757 = (_5645.z > 0.0) ? 4 : 5;
                            }
                            _6756 = _6757;
                            _6754 = _5673 ? _5651 : _5672;
                        }
                        if (_6754 <= 0.0)
                        {
                            _6780 = 1.0;
                            break;
                        }
                        float2 _5710 = float2(dot(_5645, _858[_6756]), dot(_5645, _867[_6756])) / float2(_6754 * _180._m24.z);
                        float _5717 = _180._m28[_5606].z + (_180._m28[_5606].w / _6754);
                        if (_5717 > 1.0)
                        {
                            _6780 = 1.0;
                            break;
                        }
                        float2 _5735 = _180._m28[_5606].xy + (float2(float(spvSMod(_6756, 3)), float(_6756 / 3)) * _180._m24.xy);
                        float2 _5975 = _180._m22.xy * 0.5;
                        float2 _5980 = _5735 + (float2(0.5 + (0.5 * _5710.x), 0.5 - (0.5 * _5710.y)) * _180._m24.xy);
                        float4 _5993 = float4(_5735 + _5975, (_5735 + _180._m24.xy) - _5975);
                        float _6768;
                        do
                        {
                            int _6019 = int(_180._m22.z);
                            if (_6019 <= 0)
                            {
                                _6768 = spvDepthCast(_200).sample_compare(_200Smplr, float3(fast::clamp(_5980, _5993.xy, _5993.zw), _5717).xy, _5717);
                                break;
                            }
                            float2 _6042 = (_5980 / _180._m22.xy) + float2(0.5);
                            float2 _6043 = floor(_6042);
                            float2 _6048 = _6042 - _6043;
                            float2 _6051 = _6043 - float2(0.5);
                            bool _6055 = _6019 == 1;
                            if (_6055)
                            {
                                float2 _6058 = _6048 * 2.0;
                                _6003[0] = float2(3.0) - _6058;
                                _6003[1] = float2(1.0) + _6058;
                                _6004[0] = ((float2(2.0) - _6048) / _6003[0]) - float2(1.0);
                                _6004[1] = (_6048 / _6003[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _6085 = _6048 * 3.0;
                                _6003[0] = float2(4.0) - _6085;
                                _6003[1] = float2(7.0);
                                _6003[2] = float2(1.0) + _6085;
                                _6004[0] = ((float2(3.0) - (_6048 * 2.0)) / _6003[0]) - float2(2.0);
                                _6004[1] = (float2(3.0) + _6048) / _6003[1];
                                _6004[2] = (_6048 / _6003[2]) + float2(2.0);
                            }
                            int _7103 = _6055 ? 2 : 3;
                            int _6758;
                            float _6761;
                            _6761 = 0.0;
                            _6758 = 0;
                            float _6767;
                            for (; _6758 < _7103; _6761 = _6767, _6758++)
                            {
                                _6767 = _6761;
                                for (int _6764 = 0; _6764 < _7103; )
                                {
                                    _6767 += ((_6003[_6764].x * _6003[_6758].y) * spvDepthCast(_200).sample_compare(_200Smplr, float3(fast::clamp(_180._m22.xy * (_6051 + float2(_6004[_6764].x, _6004[_6758].y)), _5993.xy, _5993.zw), _5717).xy, _5717));
                                    _6764++;
                                    continue;
                                }
                            }
                            _6768 = _6761 * (_6055 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _6780 = _6768;
                        break;
                    } while(false);
                    _6848 = _5466 * _6780;
                }
                else
                {
                    _6848 = _5466;
                }
                float3 _2572 = fast::normalize(_5435 + _2041);
                float _2577 = fast::clamp(dot(_6627, _5435), 0.0, 1.0);
                float _2582 = fast::clamp(dot(_6627, _2572), 0.0, 1.0);
                float3 _6190 = _2294 + (_4505 * powr(1.0 - fast::clamp(dot(_2041, _2572), 0.0, 1.0), 5.0));
                float _6204 = ((_2582 * _2582) * _4520) + 1.0;
                _2620 = _6850 + (((((float3(1.0) - _6190) * _2288) + ((_6190 * ((_4515 / ((3.1415927410125732421875 * _6204) * _6204)) * (0.5 / fast::max((_2577 * _4546) + (_6655 * sqrt(((_2577 * _2577) * _4542) + _4515)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875)) * _2577) * _6848);
            }
            _6897 = _6850;
        }
        else
        {
            _6897 = _2520;
        }
        _6894 = _6897;
    }
    float4 _2637 = _2632.sample(_1217, _1840);
    float _2655 = -length(_2040);
    float _6939;
    if (_180._m9.w != 0.0)
    {
        float _2679 = _180._m9.w * (in.m_1451 - _180._m6.xyz).y;
        float _6936;
        if (abs(_2679) < 9.9999997473787516355514526367188e-05)
        {
            _6936 = 1.0 - (0.5 * _2679);
        }
        else
        {
            _6936 = (1.0 - exp(fast::min(-_2679, 60.0))) / _2679;
        }
        _6939 = 1.0 - exp((_2655 * (_180._m7.w * exp(fast::min((-_180._m9.w) * (_180._m6.y - _180._m6.w), 30.0)))) * _6936);
    }
    else
    {
        _6939 = 1.0 - exp(_2655 * _180._m7.w);
    }
    float3 _2730 = mix(mix(_6894, _6623, float3(_1821._m1.y)) + ((_1821._m5.xyz * _2637.xyz) * (float3(1.0) + in.m_2054.yzw)), _180._m7.xyz, float3(_6939));
    float3 _6940;
    if (_180._m33.w > 0.5)
    {
        _6940 = _2730 / (float3(1.0) + _2730);
    }
    else
    {
        _6940 = _2730;
    }
    out.m_2742 = float4(_6940, (in.m_1849.w * _1821._m0.w) * _1847.w);
    float2 _6941;
    do
    {
        if (in.m_2752.w <= 0.0)
        {
            _6941 = float2(0.0);
            break;
        }
        _6941 = ((in.m_2752.xy / float2(in.m_2752.w)) - (in.m_2751.xy / float2(in.m_2751.w))) * float2(0.5, -0.5);
        break;
    } while(false);
    _2750 = _6941;
    return out;
}

