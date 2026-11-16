// Generated from mesh.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 0f728b2e743b9948
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

struct _191
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

struct _1529
{
    float4 _m0;
    float4 _m1;
    float4 _m2;
    float4 _m3;
    float4 _m4;
    float4 _m5;
    float4 _m6;
};

struct _1682
{
    float4 _m0[1024];
};

struct _1717
{
    float4 _m0[1024];
};

struct _1725
{
    float4 _m0[1024];
};

struct _1820
{
    uint4 _m0[1024];
};

struct _1841
{
    uint4 _m0[1024];
};

constant spvUnsafeArray<float3, 4> _567 = spvUnsafeArray<float3, 4>({ float3(1.0, 0.449999988079071044921875, 0.449999988079071044921875), float3(0.449999988079071044921875, 1.0, 0.449999988079071044921875), float3(0.5, 0.60000002384185791015625, 1.0), float3(1.0, 1.0, 0.4000000059604644775390625) });
constant spvUnsafeArray<float3, 6> _871 = spvUnsafeArray<float3, 6>({ float3(0.0, 0.0, 1.0), float3(0.0, 0.0, -1.0), float3(-1.0, 0.0, 0.0), float3(-1.0, 0.0, 0.0), float3(-1.0, 0.0, 0.0), float3(1.0, 0.0, 0.0) });
constant spvUnsafeArray<float3, 6> _880 = spvUnsafeArray<float3, 6>({ float3(0.0, 1.0, 0.0), float3(0.0, 1.0, 0.0), float3(0.0, 0.0, -1.0), float3(0.0, 0.0, 1.0), float3(0.0, 1.0, 0.0), float3(0.0, 1.0, 0.0) });
constant spvUnsafeArray<int4, 6> _1290 = spvUnsafeArray<int4, 6>({ int4(0, 0, 512, 256), int4(0, 256, 256, 128), int4(256, 256, 128, 64), int4(384, 256, 64, 32), int4(448, 256, 32, 16), int4(480, 256, 16, 8) });

struct fragment_main_out
{
    float4 m_3015 [[color(0)]];
    float2 m_3023 [[color(1)]];
};

struct fragment_main_in
{
    float3 m_1691 [[user(locn0)]];
    float3 m_1601 [[user(locn1)]];
    float2 m_2060 [[user(locn2)]];
    float4 m_2083 [[user(locn3)]];
    float4 m_2315 [[user(locn5)]];
    float4 m_3024 [[user(locn6)]];
    float4 m_3025 [[user(locn7)]];
    float4 m_1607 [[user(locn8)]];
};

fragment fragment_main_out fragment_main(fragment_main_in in [[stage_in]], constant _1529& _1531 [[buffer(2)]], constant _1682& _1684 [[buffer(3)]], constant _1717& _1719 [[buffer(4)]], constant _1725& _1727 [[buffer(5)]], constant _1820& _1822 [[buffer(6)]], constant _1841& _1843 [[buffer(7)]], constant _191& _193 [[buffer(15)]], texture2d<float> _213 [[texture(0)]], texture2d<float> _2076 [[texture(1)]], texture2d<float> _2519 [[texture(2)]], texture2d<float> _2192 [[texture(3)]], texture2d<float> _2007 [[texture(4)]], texture2d<float> _2905 [[texture(5)]], texture2d<float> _1228 [[texture(6)]], texture2d<float> _1334 [[texture(7)]], sampler _213Smplr [[sampler(0)]], sampler _1230 [[sampler(1)]], sampler _1336 [[sampler(7)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])
{
    fragment_main_out out = {};
    float2 _2074 = float2(dot(_1531._m2.xy, in.m_2060) + _1531._m2.z, dot(_1531._m3.xy, in.m_2060) + _1531._m3.z);
    float4 _2081 = _2076.sample(_1230, _2074);
    float3 _2091 = _2081.xyz;
    float3 _2092 = (in.m_2083.xyz * _1531._m0.xyz) * _2091;
    float3 _7226;
    if (_1531._m1.x > 0.5)
    {
        float2 _2113 = floor(in.m_1691.xz * float2(0.5));
        _7226 = _2092 * ((mod(abs(_2113.x + _2113.y), 2.0) < 0.5) ? 1.0 : 0.75);
    }
    else
    {
        _7226 = _2092;
    }
    float3 _7323;
    float _7354;
    float2 _7387;
    if (_1531._m3.w > 0.5)
    {
        float3 _3126;
        float2 _3133;
        float _7224;
        do
        {
            float3 _3097 = float4(_1531._m2.w, _1531._m3.w, 0.0, 0.0).xyy;
            float3 _3100 = floor(_3097 * float3(1.52587890625e-05));
            float3 _3105 = _3097 - (_3100 * 65536.0);
            float3 _3108 = floor(_3105 * float3(0.00390625));
            float3 _3116 = _3105 - (_3108 * 256.0);
            _3126 = (float3(_3116.x, _3108.x, _3100.x) * float3(0.0039215688593685626983642578125)) * 2.0;
            _3133 = float2(_3116.y, _3108.y) * float2(0.0039215688593685626983642578125);
            float _3136 = _3100.y - 128.0;
            float _3142 = floor(_3136 * 0.03125) * 0.3333333432674407958984375;
            float3 _3148 = fast::normalize(in.m_1601);
            float _3152 = dot(_3148, in.m_1607.xyz);
            float _3164 = (_3152 / fast::max(length(in.m_1607.xyz - (_3148 * _3152)), 9.9999999747524270787835121154785e-07)) * 25.5;
            if (((-24.0) + _3164) < (-2.0))
            {
                _7224 = 0.0;
                break;
            }
            float2 _3172 = _2074 * (4.0 * exp2(mod(_3136, 32.0) * 0.3333333432674407958984375));
            float2 _3209 = floor(_3172);
            float2 _3212 = _3172 - _3209;
            float2 _3220 = (_3212 * _3212) * (float2(3.0) - (_3212 * 2.0));
            uint2 _3248 = uint2(int2(_3209) + int2(65536));
            uint _3257 = ((_3248.x * 1597334677u) ^ (_3248.y * 3812015801u)) * 1597334677u;
            uint2 _3273 = uint2(int2(_3209 + float2(1.0, 0.0)) + int2(65536));
            uint _3282 = ((_3273.x * 1597334677u) ^ (_3273.y * 3812015801u)) * 1597334677u;
            float _3227 = _3220.x;
            uint2 _3298 = uint2(int2(_3209 + float2(0.0, 1.0)) + int2(65536));
            uint _3307 = ((_3298.x * 1597334677u) ^ (_3298.y * 3812015801u)) * 1597334677u;
            uint2 _3323 = uint2(int2(_3209 + float2(1.0)) + int2(65536));
            uint _3332 = ((_3323.x * 1597334677u) ^ (_3323.y * 3812015801u)) * 1597334677u;
            float2 _3178 = (_3172 * 2.7000000476837158203125) + float2(17.299999237060546875, 5.099999904632568359375);
            float2 _3351 = floor(_3178);
            float2 _3354 = _3178 - _3351;
            float2 _3362 = (_3354 * _3354) * (float2(3.0) - (_3354 * 2.0));
            uint2 _3390 = uint2(int2(_3351) + int2(65536));
            uint _3399 = ((_3390.x * 1597334677u) ^ (_3390.y * 3812015801u)) * 1597334677u;
            uint2 _3415 = uint2(int2(_3351 + float2(1.0, 0.0)) + int2(65536));
            uint _3424 = ((_3415.x * 1597334677u) ^ (_3415.y * 3812015801u)) * 1597334677u;
            float _3369 = _3362.x;
            uint2 _3440 = uint2(int2(_3351 + float2(0.0, 1.0)) + int2(65536));
            uint _3449 = ((_3440.x * 1597334677u) ^ (_3440.y * 3812015801u)) * 1597334677u;
            uint2 _3465 = uint2(int2(_3351 + float2(1.0)) + int2(65536));
            uint _3474 = ((_3465.x * 1597334677u) ^ (_3465.y * 3812015801u)) * 1597334677u;
            float _3183 = mix(0.449999988079071044921875, 0.0500000007450580596923828125, _3142);
            float _3191 = (_3164 + (-24.450000762939453125)) + ((((mix(mix(float((_3257 ^ (_3257 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_3282 ^ (_3282 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _3227), mix(float((_3307 ^ (_3307 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_3332 ^ (_3332 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _3227), _3220.y) * 0.64999997615814208984375) + (mix(mix(float((_3399 ^ (_3399 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_3424 ^ (_3424 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _3369), mix(float((_3449 ^ (_3449 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_3474 ^ (_3474 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _3369), _3362.y) * 0.3499999940395355224609375)) - 0.5) * mix(0.800000011920928955078125, 2.2000000476837158203125, _3142));
            _7224 = smoothstep(-_3183, _3183, _3191);
            break;
        } while(false);
        _7387 = _3133;
        _7354 = _7224;
        _7323 = mix(_7226, (in.m_2083.xyz * _3126) * mix(float3(1.0), _2091 * 2.0, float3(0.5)), float3(_7224));
    }
    else
    {
        _7387 = float2(0.0);
        _7354 = 0.0;
        _7323 = _7226;
    }
    float3 _2157 = fast::normalize(in.m_1601);
    float3 _7236;
    if (_1531._m6.y > 0.5)
    {
        float3 _2172 = in.m_1607.xyz - (_2157 * dot(_2157, in.m_1607.xyz));
        float3 _7237;
        if (dot(_2172, _2172) > 9.9999999600419720025001879548654e-13)
        {
            float3 _2181 = fast::normalize(_2172);
            float4 _2197 = _2192.sample(_1230, _2074);
            float3 _7228;
            if (_1531._m6.z > 0.5)
            {
                float2 _7227;
                if (_1531._m6.z > 1.5)
                {
                    _7227 = _2197.xw;
                }
                else
                {
                    _7227 = _2197.xy;
                }
                float2 _2219 = (_7227 * 2.0) - float2(1.0);
                _7228 = float3(_2219, sqrt(fast::clamp(1.0 - dot(_2219, _2219), 0.0, 1.0)));
            }
            else
            {
                _7228 = (_2197.xyz * 2.0) - float3(1.0);
            }
            float2 _2241 = _7228.xy * _1531._m4.z;
            _7237 = fast::normalize(((_2181 * _2241.x) + ((cross(_2157, _2181) * ((in.m_1607.w < 0.0) ? (-1.0) : 1.0)) * _2241.y)) + (_2157 * _7228.z));
        }
        else
        {
            _7237 = _2157;
        }
        _7236 = _7237;
    }
    else
    {
        _7236 = _2157;
    }
    bool _2265 = _1531._m5.w > 0.5;
    float _7233;
    if (_2265)
    {
        _7233 = fast::clamp(_1531._m1.z, 0.0, 1.0);
    }
    else
    {
        _7233 = 0.0;
    }
    bool _2283;
    if (_2265)
    {
        _2283 = !gl_FrontFacing;
    }
    else
    {
        _2283 = _2265;
    }
    float3 _7423;
    if (_2283 && (_7233 <= 0.0))
    {
        _7423 = -_7236;
    }
    else
    {
        _7423 = _7236;
    }
    float3 _2295 = fast::normalize(_193._m4.xyz);
    float3 _2301 = _193._m6.xyz - in.m_1691;
    float3 _2302 = fast::normalize(_2301);
    float3 _2307 = fast::normalize(_2295 + _2302);
    float3 _2313 = _2157 * (gl_FrontFacing ? 1.0 : (-1.0));
    bool _2318 = in.m_2315.x > 0.5;
    float3 _7417;
    float _7457;
    if ((_193._m5.w > 0.5) && _2318)
    {
        float _7293;
        float3 _7294;
        do
        {
            int _3503 = int(_193._m21.x);
            float _3511 = dot(_193._m20.xyz, in.m_1691) + _193._m20.w;
            int _7238;
            _7238 = 0;
            for (;;)
            {
                bool _3517 = _7238 < (_3503 - 1);
                bool _3525;
                if (_3517)
                {
                    _3525 = _3511 > _193._m16[_7238];
                }
                else
                {
                    _3525 = _3517;
                }
                if (_3525)
                {
                    _7238++;
                    continue;
                }
                else
                {
                    break;
                }
            }
            if (_3511 > _193._m16[_7238])
            {
                _7294 = float3(1.0);
                _7293 = 1.0;
                break;
            }
            float _7251;
            do
            {
                float4 _3627 = _193._m14[_7238] * float4(in.m_1691 + (_2313 * _193._m18[_7238]), 1.0);
                float _3630 = _3627.x;
                bool _3631 = _3630 < 0.0;
                bool _3638;
                if (!_3631)
                {
                    _3638 = _3630 > 1.0;
                }
                else
                {
                    _3638 = _3631;
                }
                bool _3645;
                if (!_3638)
                {
                    _3645 = _3627.y < 0.0;
                }
                else
                {
                    _3645 = _3638;
                }
                bool _3652;
                if (!_3645)
                {
                    _3652 = _3627.y > 1.0;
                }
                else
                {
                    _3652 = _3645;
                }
                if (_3652)
                {
                    _7251 = 1.0;
                    break;
                }
                float2 _3665 = float2(float(_7238 & 1), float(_7238 >> 1)) * _193._m23.xy;
                float _3672 = fast::min(_3627.z, 1.0) - _193._m19[_7238];
                float2 _3691 = _193._m22.xy * 0.5;
                float2 _3696 = _3665 + (_3627.xy * _193._m23.xy);
                float4 _3709 = float4(_3665 + _3691, (_3665 + _193._m23.xy) - _3691);
                float _7250;
                do
                {
                    int _3735 = int(_193._m22.z);
                    if (_3735 <= 0)
                    {
                        _7250 = spvDepthCast(_213).sample_compare(_213Smplr, float3(fast::clamp(_3696, _3709.xy, _3709.zw), _3672).xy, _3672);
                        break;
                    }
                    float2 _3758 = (_3696 / _193._m22.xy) + float2(0.5);
                    float2 _3759 = floor(_3758);
                    float2 _3764 = _3758 - _3759;
                    float2 _3767 = _3759 - float2(0.5);
                    bool _3771 = _3735 == 1;
                    spvUnsafeArray<float2, 3> _3719;
                    spvUnsafeArray<float2, 3> _3720;
                    if (_3771)
                    {
                        float2 _3774 = _3764 * 2.0;
                        _3719[0] = float2(3.0) - _3774;
                        _3719[1] = float2(1.0) + _3774;
                        _3720[0] = ((float2(2.0) - _3764) / _3719[0]) - float2(1.0);
                        _3720[1] = (_3764 / _3719[1]) + float2(1.0);
                    }
                    else
                    {
                        float2 _3801 = _3764 * 3.0;
                        _3719[0] = float2(4.0) - _3801;
                        _3719[1] = float2(7.0);
                        _3719[2] = float2(1.0) + _3801;
                        _3720[0] = ((float2(3.0) - (_3764 * 2.0)) / _3719[0]) - float2(2.0);
                        _3720[1] = (float2(3.0) + _3764) / _3719[1];
                        _3720[2] = (_3764 / _3719[2]) + float2(2.0);
                    }
                    int _7911 = _3771 ? 2 : 3;
                    int _7240;
                    float _7243;
                    _7243 = 0.0;
                    _7240 = 0;
                    float _7249;
                    for (; _7240 < _7911; _7243 = _7249, _7240++)
                    {
                        _7249 = _7243;
                        for (int _7246 = 0; _7246 < _7911; )
                        {
                            _7249 += ((_3719[_7246].x * _3719[_7240].y) * spvDepthCast(_213).sample_compare(_213Smplr, float3(fast::clamp(_193._m22.xy * (_3767 + float2(_3720[_7246].x, _3720[_7240].y)), _3709.xy, _3709.zw), _3672).xy, _3672));
                            _7246++;
                            continue;
                        }
                    }
                    _7250 = _7243 * (_3771 ? 0.0625 : 0.0069444444961845874786376953125);
                    break;
                } while(false);
                _7251 = _7250;
                break;
            } while(false);
            float3 _7288;
            float _7291;
            if (_3511 > _193._m17[_7238])
            {
                float _3565 = (_3511 - _193._m17[_7238]) / (_193._m16[_7238] - _193._m17[_7238]);
                int _3567 = _7238 + 1;
                float3 _7289;
                float _7292;
                if (_3567 < _3503)
                {
                    float _7271;
                    do
                    {
                        float4 _3914 = _193._m14[_3567] * float4(in.m_1691 + (_2313 * _193._m18[_3567]), 1.0);
                        float _3917 = _3914.x;
                        bool _3918 = _3917 < 0.0;
                        bool _3925;
                        if (!_3918)
                        {
                            _3925 = _3917 > 1.0;
                        }
                        else
                        {
                            _3925 = _3918;
                        }
                        bool _3932;
                        if (!_3925)
                        {
                            _3932 = _3914.y < 0.0;
                        }
                        else
                        {
                            _3932 = _3925;
                        }
                        bool _3939;
                        if (!_3932)
                        {
                            _3939 = _3914.y > 1.0;
                        }
                        else
                        {
                            _3939 = _3932;
                        }
                        if (_3939)
                        {
                            _7271 = 1.0;
                            break;
                        }
                        float2 _3952 = float2(float(_3567 & 1), float(_3567 >> 1)) * _193._m23.xy;
                        float _3959 = fast::min(_3914.z, 1.0) - _193._m19[_3567];
                        float2 _3978 = _193._m22.xy * 0.5;
                        float2 _3983 = _3952 + (_3914.xy * _193._m23.xy);
                        float4 _3996 = float4(_3952 + _3978, (_3952 + _193._m23.xy) - _3978);
                        float _7270;
                        do
                        {
                            int _4022 = int(_193._m22.z);
                            if (_4022 <= 0)
                            {
                                _7270 = spvDepthCast(_213).sample_compare(_213Smplr, float3(fast::clamp(_3983, _3996.xy, _3996.zw), _3959).xy, _3959);
                                break;
                            }
                            float2 _4045 = (_3983 / _193._m22.xy) + float2(0.5);
                            float2 _4046 = floor(_4045);
                            float2 _4051 = _4045 - _4046;
                            float2 _4054 = _4046 - float2(0.5);
                            bool _4058 = _4022 == 1;
                            spvUnsafeArray<float2, 3> _4006;
                            spvUnsafeArray<float2, 3> _4007;
                            if (_4058)
                            {
                                float2 _4061 = _4051 * 2.0;
                                _4006[0] = float2(3.0) - _4061;
                                _4006[1] = float2(1.0) + _4061;
                                _4007[0] = ((float2(2.0) - _4051) / _4006[0]) - float2(1.0);
                                _4007[1] = (_4051 / _4006[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _4088 = _4051 * 3.0;
                                _4006[0] = float2(4.0) - _4088;
                                _4006[1] = float2(7.0);
                                _4006[2] = float2(1.0) + _4088;
                                _4007[0] = ((float2(3.0) - (_4051 * 2.0)) / _4006[0]) - float2(2.0);
                                _4007[1] = (float2(3.0) + _4051) / _4006[1];
                                _4007[2] = (_4051 / _4006[2]) + float2(2.0);
                            }
                            int _7913 = _4058 ? 2 : 3;
                            int _7260;
                            float _7263;
                            _7263 = 0.0;
                            _7260 = 0;
                            float _7269;
                            for (; _7260 < _7913; _7263 = _7269, _7260++)
                            {
                                _7269 = _7263;
                                for (int _7266 = 0; _7266 < _7913; )
                                {
                                    _7269 += ((_4006[_7266].x * _4006[_7260].y) * spvDepthCast(_213).sample_compare(_213Smplr, float3(fast::clamp(_193._m22.xy * (_4054 + float2(_4007[_7266].x, _4007[_7260].y)), _3996.xy, _3996.zw), _3959).xy, _3959));
                                    _7266++;
                                    continue;
                                }
                            }
                            _7270 = _7263 * (_4058 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _7271 = _7270;
                        break;
                    } while(false);
                    _7292 = mix(_7251, _7271, _3565);
                    _7289 = mix(_567[_7238], _567[_3567], float3(_3565));
                }
                else
                {
                    _7292 = mix(_7251, 1.0, _3565);
                    _7289 = _567[_7238];
                }
                _7291 = _7292;
                _7288 = _7289;
            }
            else
            {
                _7291 = _7251;
                _7288 = _567[_7238];
            }
            _7294 = select(float3(1.0), _7288, bool3(_193._m22.w > 0.5));
            _7293 = _7291;
            break;
        } while(false);
        _7457 = _7293;
        _7417 = _7323 * _7294;
    }
    else
    {
        _7457 = 1.0;
        _7417 = _7323;
    }
    float3 _2344 = _193._m5.xyz * _193._m4.w;
    bool _2348 = _1531._m6.w > 0.5;
    float _7346;
    if (_2348)
    {
        _7346 = 1.0;
    }
    else
    {
        _7346 = 1.0 + (_1531._m4.w * (_2007.sample(_1230, _2074).x - 1.0));
    }
    float _2368 = abs(in.m_1607.w);
    float _7547;
    if (_2368 > 0.0)
    {
        _7547 = _7346 * fast::min(_2368, 1.0);
    }
    else
    {
        _7547 = _7346;
    }
    float3 _7705;
    if (!_2265)
    {
        float _2384 = dot(_7423, _2295);
        float3 _7697;
        if (_193._m29.x > 0.5)
        {
            float _4239 = (_193._m29.z * _7423.x) - (_193._m29.w * _7423.z);
            float _4252 = (_193._m29.w * _7423.x) + (_193._m29.z * _7423.z);
            float _4270 = 1.09254801273345947265625 * _4239;
            spvUnsafeArray<float, 9> _7002 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _7423.y, 0.48860299587249755859375 * _4252, 0.48860299587249755859375 * _4239, _4270 * _7423.y, (1.09254801273345947265625 * _7423.y) * _4252, 0.3153919875621795654296875 * (((3.0 * _4252) * _4252) - 1.0), _4270 * _4252, 0.546274006366729736328125 * ((_4239 * _4239) - (_7423.y * _7423.y)) });
            spvUnsafeArray<float, 9> _4184 = _7002;
            float3 _7696;
            _7696 = float3(0.0);
            for (int _7695 = 0; _7695 < 9; )
            {
                _7696 += (_1228.read(uint2((int2(496, 256) + int2(_7695, 0))), 0).xyz * _4184[_7695]);
                _7695++;
                continue;
            }
            _7697 = fast::max(_7696, float3(0.0)) * _193._m29.y;
        }
        else
        {
            _7697 = mix(_193._m9.xyz, _193._m8.xyz, float3((_7423.y * 0.5) + 0.5)) * _193._m8.w;
        }
        float3 _2434 = (_7417 * ((_7697 * _7547) + ((_2344 * fast::max(_2384, 0.0)) * _7457))) + ((_2344 * ((powr(fast::max(dot(_7423, _2307), 0.0), _1531._m1.w) * _1531._m1.z) * step(0.0, _2384))) * _7457);
        float3 _7706;
        if (_193._m13.w > 0.5)
        {
            float2 _4355 = fast::clamp(floor(gl_FragCoord.xy * _193._m12.xy), float2(0.0), _193._m13.xy - float2(1.0));
            uint _4383 = uint((((fast::clamp(floor((log2(fast::max(dot(_193._m11.xyz, in.m_1691) + _193._m11.w, 9.9999999747524270787835121154785e-07)) * _193._m12.z) + _193._m12.w), 0.0, _193._m13.z - 1.0) * _193._m13.y) + _4355.y) * _193._m13.x) + _4355.x);
            uint _4385 = _4383 >> uint(2);
            uint _4387 = _4383 & 3u;
            uint _4391 = _1822._m0[_4385][_4387] & 65535u;
            uint _4393 = _1822._m0[_4385][_4387] >> uint(16);
            float3 _7707;
            _7707 = _2434;
            float3 _2514;
            spvUnsafeArray<float2, 3> _4801;
            spvUnsafeArray<float2, 3> _4802;
            spvUnsafeArray<float2, 3> _5014;
            spvUnsafeArray<float2, 3> _5015;
            for (uint _7704 = _4391; _7704 < (_4391 + _4393); _7707 = _2514, _7704++)
            {
                uint _4399 = _7704 / 3u;
                uint _4412 = (_1843._m0[_4399 >> uint(2)][_4399 & 3u] >> ((_7704 - (_4399 * 3u)) * 10u)) & 1023u;
                float3 _4429 = _1684._m0[_4412].xyz - in.m_1691;
                float _4432 = dot(_4429, _4429);
                float _4436 = _4432 * _1684._m0[_4412].w;
                float _4441 = fast::clamp(1.0 - (_4436 * _4436), 0.0, 1.0);
                float3 _4446 = _4429 * rsqrt(fast::max(_4432, 9.9999999392252902907785028219223e-09));
                float _4464 = fast::clamp((dot(-_4446, _1727._m0[_4412].xyz) * _1719._m0[_4412].w) + _1727._m0[_4412].w, 0.0, 1.0);
                float3 _4477 = _1719._m0[_4412].xyz * ((((_4441 * _4441) * _4464) * _4464) / fast::max(_4432, 9.9999997473787516355514526367188e-05));
                float3 _7833;
                if (_2318)
                {
                    float _7779;
                    do
                    {
                        uint _4513 = uint(_193._m21.z);
                        if (_4412 < _4513)
                        {
                            float _4535 = _193._m26[_4412].z * fast::max((_193._m15[_4412] * float4(in.m_1691, 1.0)).w, 0.0);
                            float4 _4559 = _193._m15[_4412] * float4((in.m_1691 + (_2313 * (_4535 * _193._m25.x))) + (_4446 * (_4535 * _193._m25.y)), 1.0);
                            float _4561 = _4559.w;
                            if (_4561 <= 0.0)
                            {
                                _7779 = 1.0;
                                break;
                            }
                            float3 _4570 = _4559.xyz / float3(_4561);
                            float _4572 = _4570.x;
                            bool _4573 = _4572 < 0.0;
                            bool _4580;
                            if (!_4573)
                            {
                                _4580 = _4572 > 1.0;
                            }
                            else
                            {
                                _4580 = _4573;
                            }
                            bool _4587;
                            if (!_4580)
                            {
                                _4587 = _4570.y < 0.0;
                            }
                            else
                            {
                                _4587 = _4580;
                            }
                            bool _4594;
                            if (!_4587)
                            {
                                _4594 = _4570.y > 1.0;
                            }
                            else
                            {
                                _4594 = _4587;
                            }
                            bool _4601;
                            if (!_4594)
                            {
                                _4601 = _4570.z > 1.0;
                            }
                            else
                            {
                                _4601 = _4594;
                            }
                            if (_4601)
                            {
                                _7779 = 1.0;
                                break;
                            }
                            float _4607 = _4570.z;
                            float2 _4773 = _193._m22.xy * 0.5;
                            float2 _4778 = _193._m26[_4412].xy + (_4570.xy * _193._m23.zw);
                            float4 _4791 = float4(_193._m26[_4412].xy + _4773, (_193._m26[_4412].xy + _193._m23.zw) - _4773);
                            float _7778;
                            do
                            {
                                int _4817 = int(_193._m22.z);
                                if (_4817 <= 0)
                                {
                                    float2 _4827 = fast::clamp(_4778, _4791.xy, _4791.zw);
                                    _7778 = spvDepthCast(_213).sample_compare(_213Smplr, float3(_4827, _4607).xy, _4607);
                                    break;
                                }
                                float2 _4840 = (_4778 / _193._m22.xy) + float2(0.5);
                                float2 _4841 = floor(_4840);
                                float2 _4846 = _4840 - _4841;
                                float2 _4849 = _4841 - float2(0.5);
                                bool _4853 = _4817 == 1;
                                if (_4853)
                                {
                                    float2 _4856 = _4846 * 2.0;
                                    _4801[0] = float2(3.0) - _4856;
                                    _4801[1] = float2(1.0) + _4856;
                                    _4802[0] = ((float2(2.0) - _4846) / _4801[0]) - float2(1.0);
                                    _4802[1] = (_4846 / _4801[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _4883 = _4846 * 3.0;
                                    _4801[0] = float2(4.0) - _4883;
                                    _4801[1] = float2(7.0);
                                    _4801[2] = float2(1.0) + _4883;
                                    _4802[0] = ((float2(3.0) - (_4846 * 2.0)) / _4801[0]) - float2(2.0);
                                    _4802[1] = (float2(3.0) + _4846) / _4801[1];
                                    _4802[2] = (_4846 / _4801[2]) + float2(2.0);
                                }
                                int _7918 = _4853 ? 2 : 3;
                                int _7768;
                                float _7771;
                                _7771 = 0.0;
                                _7768 = 0;
                                float _7777;
                                for (; _7768 < _7918; _7771 = _7777, _7768++)
                                {
                                    _7777 = _7771;
                                    for (int _7774 = 0; _7774 < _7918; )
                                    {
                                        _7777 += ((_4801[_7774].x * _4801[_7768].y) * spvDepthCast(_213).sample_compare(_213Smplr, float3(fast::clamp(_193._m22.xy * (_4849 + float2(_4802[_7774].x, _4802[_7768].y)), _4791.xy, _4791.zw), _4607).xy, _4607));
                                        _7774++;
                                        continue;
                                    }
                                }
                                _7778 = _7771 * (_4853 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _7779 = _7778;
                            break;
                        }
                        uint _4617 = _4412 - _4513;
                        if (_4617 >= uint(_193._m21.w))
                        {
                            _7779 = 1.0;
                            break;
                        }
                        float _4638 = _193._m27[_4617].w * length(in.m_1691 - _193._m27[_4617].xyz);
                        float3 _4656 = ((in.m_1691 + (_2313 * (_4638 * _193._m25.x))) + (_4446 * (_4638 * _193._m25.y))) - _193._m27[_4617].xyz;
                        float3 _4658 = abs(_4656);
                        float _4660 = _4658.x;
                        float _4662 = _4658.y;
                        bool _4663 = _4660 >= _4662;
                        bool _4671;
                        if (_4663)
                        {
                            _4671 = _4660 >= _4658.z;
                        }
                        else
                        {
                            _4671 = _4663;
                        }
                        float _7753;
                        int _7755;
                        if (_4671)
                        {
                            _7755 = (_4656.x > 0.0) ? 0 : 1;
                            _7753 = _4660;
                        }
                        else
                        {
                            float _4683 = _4658.z;
                            bool _4684 = _4662 >= _4683;
                            int _7756;
                            if (_4684)
                            {
                                _7756 = (_4656.y > 0.0) ? 2 : 3;
                            }
                            else
                            {
                                _7756 = (_4656.z > 0.0) ? 4 : 5;
                            }
                            _7755 = _7756;
                            _7753 = _4684 ? _4662 : _4683;
                        }
                        if (_7753 <= 0.0)
                        {
                            _7779 = 1.0;
                            break;
                        }
                        float2 _4721 = float2(dot(_4656, _871[_7755]), dot(_4656, _880[_7755])) / float2(_7753 * _193._m24.z);
                        float _4728 = _193._m28[_4617].z + (_193._m28[_4617].w / _7753);
                        if (_4728 > 1.0)
                        {
                            _7779 = 1.0;
                            break;
                        }
                        float2 _4746 = _193._m28[_4617].xy + (float2(float(spvSMod(_7755, 3)), float(_7755 / 3)) * _193._m24.xy);
                        float2 _4986 = _193._m22.xy * 0.5;
                        float2 _4991 = _4746 + (float2(0.5 + (0.5 * _4721.x), 0.5 - (0.5 * _4721.y)) * _193._m24.xy);
                        float4 _5004 = float4(_4746 + _4986, (_4746 + _193._m24.xy) - _4986);
                        float _7767;
                        do
                        {
                            int _5030 = int(_193._m22.z);
                            if (_5030 <= 0)
                            {
                                _7767 = spvDepthCast(_213).sample_compare(_213Smplr, float3(fast::clamp(_4991, _5004.xy, _5004.zw), _4728).xy, _4728);
                                break;
                            }
                            float2 _5053 = (_4991 / _193._m22.xy) + float2(0.5);
                            float2 _5054 = floor(_5053);
                            float2 _5059 = _5053 - _5054;
                            float2 _5062 = _5054 - float2(0.5);
                            bool _5066 = _5030 == 1;
                            if (_5066)
                            {
                                float2 _5069 = _5059 * 2.0;
                                _5014[0] = float2(3.0) - _5069;
                                _5014[1] = float2(1.0) + _5069;
                                _5015[0] = ((float2(2.0) - _5059) / _5014[0]) - float2(1.0);
                                _5015[1] = (_5059 / _5014[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _5096 = _5059 * 3.0;
                                _5014[0] = float2(4.0) - _5096;
                                _5014[1] = float2(7.0);
                                _5014[2] = float2(1.0) + _5096;
                                _5015[0] = ((float2(3.0) - (_5059 * 2.0)) / _5014[0]) - float2(2.0);
                                _5015[1] = (float2(3.0) + _5059) / _5014[1];
                                _5015[2] = (_5059 / _5014[2]) + float2(2.0);
                            }
                            int _7921 = _5066 ? 2 : 3;
                            int _7757;
                            float _7760;
                            _7760 = 0.0;
                            _7757 = 0;
                            float _7766;
                            for (; _7757 < _7921; _7760 = _7766, _7757++)
                            {
                                _7766 = _7760;
                                for (int _7763 = 0; _7763 < _7921; )
                                {
                                    _7766 += ((_5014[_7763].x * _5014[_7757].y) * spvDepthCast(_213).sample_compare(_213Smplr, float3(fast::clamp(_193._m22.xy * (_5062 + float2(_5015[_7763].x, _5015[_7757].y)), _5004.xy, _5004.zw), _4728).xy, _4728));
                                    _7763++;
                                    continue;
                                }
                            }
                            _7767 = _7760 * (_5066 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _7779 = _7767;
                        break;
                    } while(false);
                    _7833 = _4477 * _7779;
                }
                else
                {
                    _7833 = _4477;
                }
                float _2485 = dot(_7423, _4446);
                _2514 = _7707 + (((_7417 * fast::max(_2485, 0.0)) * _7833) + (_7833 * ((powr(fast::max(dot(_7423, fast::normalize(_4446 + _2302)), 0.0), _1531._m1.w) * _1531._m1.z) * step(0.0, _2485))));
            }
            _7706 = _7707;
        }
        else
        {
            _7706 = _2434;
        }
        _7705 = _7706;
    }
    else
    {
        float4 _2524 = _2519.sample(_1230, _2074);
        float _2531 = fast::clamp(_1531._m4.x * _2524.z, 0.0, 1.0);
        float _2539 = fast::clamp(_1531._m4.y * _2524.y, 0.04500000178813934326171875, 1.0);
        float _7413;
        float _7418;
        if (_7354 > 0.0)
        {
            _7418 = mix(_2531, _7387.y, _7354);
            _7413 = mix(_2539, fast::max(_7387.x, 0.04500000178813934326171875), _7354);
        }
        else
        {
            _7418 = _2531;
            _7413 = _2539;
        }
        float _2558 = _7413 * _7413;
        float3 _2563 = _7417 * (1.0 - _7418);
        float3 _2569 = mix(float3(0.039999999105930328369140625), _7417, float3(_7418));
        bool _2573 = _7233 > 0.0;
        float3 _7446;
        if (_2573)
        {
            float3 _2578 = dfdx(in.m_1691);
            float3 _2580 = dfdy(in.m_1691);
            float3 _2581 = cross(_2578, _2580);
            float3 _7447;
            if (dot(_2581, _2581) > 9.9999996826552253889678874634872e-21)
            {
                _7447 = fast::normalize((fast::normalize(_2581) * ((dot(_2581, _2302) < 0.0) ? (-1.0) : 1.0)) + (_7423 - _2157));
            }
            else
            {
                _7447 = _7423;
            }
            _7446 = _7447;
        }
        else
        {
            _7446 = _7423;
        }
        float _2607 = fast::max(dot(_7446, _2302), 9.9999997473787516355514526367188e-05);
        float _2616 = dot(_7446, _2295);
        float _2617 = fast::clamp(_2616, 0.0, 1.0);
        float _2622 = fast::clamp(dot(_7446, _2307), 0.0, 1.0);
        float _2627 = fast::clamp(dot(_2302, _2307), 0.0, 1.0);
        float _7450;
        float _7451;
        if (_2573)
        {
            _7451 = fast::max(_2607, 0.5);
            _7450 = fast::max(_2627, 0.5);
        }
        else
        {
            _7451 = _2607;
            _7450 = _2627;
        }
        float3 _5198 = float3(1.0) - _2569;
        float3 _5201 = _2569 + (_5198 * powr(1.0 - _7450, 5.0));
        float _5208 = _2558 * _2558;
        float _5213 = _5208 - 1.0;
        float _5215 = ((_2622 * _2622) * _5213) + 1.0;
        float _5235 = 1.0 - _5208;
        float _5239 = sqrt(((_7451 * _7451) * _5235) + _5208);
        float3 _2673 = (((((float3(1.0) - _5201) * _2563) * fast::clamp(dot(_7423, _2295), 0.0, 1.0)) + (((_5201 * ((_5208 / ((3.1415927410125732421875 * _5215) * _5215)) * (0.5 / fast::max((_2617 * _5239) + (_7451 * sqrt(((_2617 * _2617) * _5235) + _5208)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875) * _2617)) * _2344) * _7457;
        float3 _7561;
        if (_2573)
        {
            _7561 = _2673 + (((((_2563 * _2344) * _7457) * _7233) * fast::clamp(-_2616, 0.0, 1.0)) * (0.3499999940395355224609375 + (0.64999997615814208984375 * powr(fast::clamp(dot(-_2302, _2295), 0.0, 1.0), 3.0))));
        }
        else
        {
            _7561 = _2673;
        }
        float3 _7487;
        float2 _7511;
        float3 _7523;
        if (_193._m29.x > 0.5)
        {
            float4 _5272 = _1334.sample(_1336, (((float2(_7451, _7413) * 31.0) + float2(0.5)) * float2(0.03125)));
            float _5331 = (_193._m29.z * _7423.x) - (_193._m29.w * _7423.z);
            float _5344 = (_193._m29.w * _7423.x) + (_193._m29.z * _7423.z);
            float _5362 = 1.09254801273345947265625 * _5331;
            spvUnsafeArray<float, 9> _6983 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _7423.y, 0.48860299587249755859375 * _5344, 0.48860299587249755859375 * _5331, _5362 * _7423.y, (1.09254801273345947265625 * _7423.y) * _5344, 0.3153919875621795654296875 * (((3.0 * _5344) * _5344) - 1.0), _5362 * _5344, 0.546274006366729736328125 * ((_5331 * _5331) - (_7423.y * _7423.y)) });
            spvUnsafeArray<float, 9> _5276 = _6983;
            float3 _7469;
            _7469 = float3(0.0);
            for (int _7468 = 0; _7468 < 9; )
            {
                _7469 += (_1228.read(uint2((int2(496, 256) + int2(_7468, 0))), 0).xyz * _5276[_7468]);
                _7468++;
                continue;
            }
            float3 _2725 = reflect(-_2302, _7446);
            float _5457 = _2725.x;
            float _5462 = _2725.z;
            float2 _5494 = float2((precise::atan2((_193._m29.z * _5457) - (_193._m29.w * _5462), -((_193._m29.w * _5457) + (_193._m29.z * _5462))) * 0.15915493667125701904296875) + 0.5, acos(fast::clamp(_2725.y, -1.0, 1.0)) * 0.3183098733425140380859375);
            float _5426 = _7413 * 5.0;
            int _5429 = min(int(_5426), 4);
            float2 _5515 = (_5494 * float2(_1290[_5429].zw)) - float2(0.5);
            float2 _5517 = floor(_5515);
            float2 _5520 = _5515 - _5517;
            int _5523 = int(_5517.x);
            int _5526 = int(_5517.y);
            int _7472;
            if (_5523 < 0)
            {
                _7472 = _5523 + _1290[_5429].z;
            }
            else
            {
                _7472 = _5523;
            }
            int _7473;
            if (_7472 >= _1290[_5429].z)
            {
                _7473 = _7472 - _1290[_5429].z;
            }
            else
            {
                _7473 = _7472;
            }
            int _5546 = _7473 + 1;
            int _7922 = (_5546 == _1290[_5429].z) ? 0 : _5546;
            int _5561 = min((_5526 + 1), (_1290[_5429].w - 1));
            int _5563 = max(_5526, 0);
            float3 _5616 = float3(_5520.x);
            int _5436 = _5429 + 1;
            float2 _5648 = (_5494 * float2(_1290[_5436].zw)) - float2(0.5);
            float2 _5650 = floor(_5648);
            float2 _5653 = _5648 - _5650;
            int _5656 = int(_5650.x);
            int _5659 = int(_5650.y);
            int _7479;
            if (_5656 < 0)
            {
                _7479 = _5656 + _1290[_5436].z;
            }
            else
            {
                _7479 = _5656;
            }
            int _7480;
            if (_7479 >= _1290[_5436].z)
            {
                _7480 = _7479 - _1290[_5436].z;
            }
            else
            {
                _7480 = _7479;
            }
            int _5679 = _7480 + 1;
            int _7923 = (_5679 == _1290[_5436].z) ? 0 : _5679;
            int _5694 = min((_5659 + 1), (_1290[_5436].w - 1));
            int _5696 = max(_5659, 0);
            float3 _5749 = float3(_5653.x);
            float3 _5451 = mix(mix(mix(_1228.read(uint2((_1290[_5429].xy + int2(_7473, _5563))), 0).xyz, _1228.read(uint2((_1290[_5429].xy + int2(_7922, _5563))), 0).xyz, _5616), mix(_1228.read(uint2((_1290[_5429].xy + int2(_7473, _5561))), 0).xyz, _1228.read(uint2((_1290[_5429].xy + int2(_7922, _5561))), 0).xyz, _5616), float3(_5520.y)), mix(mix(_1228.read(uint2((_1290[_5436].xy + int2(_7480, _5696))), 0).xyz, _1228.read(uint2((_1290[_5436].xy + int2(_7923, _5696))), 0).xyz, _5749), mix(_1228.read(uint2((_1290[_5436].xy + int2(_7480, _5694))), 0).xyz, _1228.read(uint2((_1290[_5436].xy + int2(_7923, _5694))), 0).xyz, _5749), float3(_5653.y)), float3(_5426 - float(_5429))) * _193._m29.y;
            _7523 = fast::max(_7469, float3(0.0)) * _193._m29.y;
            _7511 = _5272.xy;
            _7487 = _5451;
        }
        else
        {
            float4 _5767 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * _7413) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);
            float _5769 = _5767.x;
            float3 _5804 = mix(_193._m9.xyz, _193._m8.xyz, float3((_7423.y * 0.5) + 0.5)) * _193._m8.w;
            _7523 = _5804;
            _7511 = (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_5769 * _5769, exp2((-9.27999973297119140625) * _7451)) * _5769) + _5767.y)) + _5767.zw;
            _7487 = mix(mix(_193._m9.xyz, _193._m8.xyz, float3((reflect(-_2302, _7446).y * 0.5) + 0.5)) * _193._m8.w, _5804, float3(_7413));
        }
        bool _2757;
        if (_2348)
        {
            _2757 = _193._m33.z > 0.5;
        }
        else
        {
            _2757 = _2348;
        }
        float3 _7532;
        if (_2757)
        {
            float3 _7508;
            do
            {
                float _5883 = ((_193._m32.x * (1.0 - smoothstep(_193._m33.x * 0.5, _193._m33.x, abs(dot(_193._m31.xyz, in.m_1691) - _193._m31.w)))) * smoothstep(0.5, 0.89999997615814208984375, dot(_2313, _193._m31.xyz))) * (1.0 - smoothstep(_193._m32.y * 0.5, _193._m32.y, _7413));
                if (_5883 <= 0.0)
                {
                    _7508 = _7487;
                    break;
                }
                float4 _5908 = _193._m30 * float4(in.m_1691 + ((_7423 - (_193._m31.xyz * dot(_7423, _193._m31.xyz))) * _193._m32.w), 1.0);
                float2 _5921 = ((float2(_5908.x, -_5908.y) / float2(_5908.w)) * 0.5) + float2(0.5);
                float _5925 = _193._m32.z * _7413;
                float3 _7506;
                float _7507;
                _7507 = 0.0;
                _7506 = float3(0.0);
                for (int _7505 = 0; _7505 < 12; )
                {
                    float _5932 = float(_7505);
                    float _5940 = _5932 * 2.3999631404876708984375;
                    float2 _5952 = _5921 + (float2(cos(_5940) * _193._m33.y, sin(_5940)) * (sqrt((_5932 + 0.5) * 0.083333335816860198974609375) * _5925));
                    float2 _5957 = fast::min(_5952, float2(1.0) - _5952);
                    float _5963 = smoothstep(0.0, 0.039999999105930328369140625, fast::min(_5957.x, _5957.y));
                    float4 _5971 = _2007.sample(_1230, fast::clamp(_5952, float2(0.0), float2(1.0)), level(0.0));
                    float3 _5973 = _5971.xyz;
                    _7507 += (_5971.w * _5963);
                    _7506 += ((_5973 / (float3(1.0) - fast::min(_5973, float3(0.99500000476837158203125)))) * _5963);
                    _7505++;
                    continue;
                }
                _7508 = mix(_7487, (_7506 * float3(0.083333335816860198974609375)) + (_7487 * (1.0 - (_7507 * 0.083333335816860198974609375))), float3(_5883));
                break;
            } while(false);
            _7532 = _7508;
        }
        else
        {
            _7532 = _7487;
        }
        float3 _2777 = (_2569 * _7511.x) + float3(_7511.y);
        float3 _2793 = _7561 + (((((float3(1.0) - _2777) * _2563) * _7523) + (_2777 * _7532)) * _7547);
        float3 _7708;
        if (_193._m13.w > 0.5)
        {
            float2 _6037 = fast::clamp(floor(gl_FragCoord.xy * _193._m12.xy), float2(0.0), _193._m13.xy - float2(1.0));
            uint _6065 = uint((((fast::clamp(floor((log2(fast::max(dot(_193._m11.xyz, in.m_1691) + _193._m11.w, 9.9999999747524270787835121154785e-07)) * _193._m12.z) + _193._m12.w), 0.0, _193._m13.z - 1.0) * _193._m13.y) + _6037.y) * _193._m13.x) + _6037.x);
            uint _6067 = _6065 >> uint(2);
            uint _6069 = _6065 & 3u;
            uint _6073 = _1822._m0[_6067][_6069] & 65535u;
            uint _6075 = _1822._m0[_6067][_6069] >> uint(16);
            float3 _7661;
            _7661 = _2793;
            float3 _2893;
            spvUnsafeArray<float2, 3> _6483;
            spvUnsafeArray<float2, 3> _6484;
            spvUnsafeArray<float2, 3> _6696;
            spvUnsafeArray<float2, 3> _6697;
            for (uint _7564 = _6073; _7564 < (_6073 + _6075); _7661 = _2893, _7564++)
            {
                uint _6081 = _7564 / 3u;
                uint _6094 = (_1843._m0[_6081 >> uint(2)][_6081 & 3u] >> ((_7564 - (_6081 * 3u)) * 10u)) & 1023u;
                float3 _6111 = _1684._m0[_6094].xyz - in.m_1691;
                float _6114 = dot(_6111, _6111);
                float _6118 = _6114 * _1684._m0[_6094].w;
                float _6123 = fast::clamp(1.0 - (_6118 * _6118), 0.0, 1.0);
                float3 _6128 = _6111 * rsqrt(fast::max(_6114, 9.9999999392252902907785028219223e-09));
                float _6146 = fast::clamp((dot(-_6128, _1727._m0[_6094].xyz) * _1719._m0[_6094].w) + _1727._m0[_6094].w, 0.0, 1.0);
                float3 _6159 = _1719._m0[_6094].xyz * ((((_6123 * _6123) * _6146) * _6146) / fast::max(_6114, 9.9999997473787516355514526367188e-05));
                float3 _7659;
                if (_2318)
                {
                    float _7591;
                    do
                    {
                        uint _6195 = uint(_193._m21.z);
                        if (_6094 < _6195)
                        {
                            float _6217 = _193._m26[_6094].z * fast::max((_193._m15[_6094] * float4(in.m_1691, 1.0)).w, 0.0);
                            float4 _6241 = _193._m15[_6094] * float4((in.m_1691 + (_2313 * (_6217 * _193._m25.x))) + (_6128 * (_6217 * _193._m25.y)), 1.0);
                            float _6243 = _6241.w;
                            if (_6243 <= 0.0)
                            {
                                _7591 = 1.0;
                                break;
                            }
                            float3 _6252 = _6241.xyz / float3(_6243);
                            float _6254 = _6252.x;
                            bool _6255 = _6254 < 0.0;
                            bool _6262;
                            if (!_6255)
                            {
                                _6262 = _6254 > 1.0;
                            }
                            else
                            {
                                _6262 = _6255;
                            }
                            bool _6269;
                            if (!_6262)
                            {
                                _6269 = _6252.y < 0.0;
                            }
                            else
                            {
                                _6269 = _6262;
                            }
                            bool _6276;
                            if (!_6269)
                            {
                                _6276 = _6252.y > 1.0;
                            }
                            else
                            {
                                _6276 = _6269;
                            }
                            bool _6283;
                            if (!_6276)
                            {
                                _6283 = _6252.z > 1.0;
                            }
                            else
                            {
                                _6283 = _6276;
                            }
                            if (_6283)
                            {
                                _7591 = 1.0;
                                break;
                            }
                            float _6289 = _6252.z;
                            float2 _6455 = _193._m22.xy * 0.5;
                            float2 _6460 = _193._m26[_6094].xy + (_6252.xy * _193._m23.zw);
                            float4 _6473 = float4(_193._m26[_6094].xy + _6455, (_193._m26[_6094].xy + _193._m23.zw) - _6455);
                            float _7590;
                            do
                            {
                                int _6499 = int(_193._m22.z);
                                if (_6499 <= 0)
                                {
                                    float2 _6509 = fast::clamp(_6460, _6473.xy, _6473.zw);
                                    _7590 = spvDepthCast(_213).sample_compare(_213Smplr, float3(_6509, _6289).xy, _6289);
                                    break;
                                }
                                float2 _6522 = (_6460 / _193._m22.xy) + float2(0.5);
                                float2 _6523 = floor(_6522);
                                float2 _6528 = _6522 - _6523;
                                float2 _6531 = _6523 - float2(0.5);
                                bool _6535 = _6499 == 1;
                                if (_6535)
                                {
                                    float2 _6538 = _6528 * 2.0;
                                    _6483[0] = float2(3.0) - _6538;
                                    _6483[1] = float2(1.0) + _6538;
                                    _6484[0] = ((float2(2.0) - _6528) / _6483[0]) - float2(1.0);
                                    _6484[1] = (_6528 / _6483[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _6565 = _6528 * 3.0;
                                    _6483[0] = float2(4.0) - _6565;
                                    _6483[1] = float2(7.0);
                                    _6483[2] = float2(1.0) + _6565;
                                    _6484[0] = ((float2(3.0) - (_6528 * 2.0)) / _6483[0]) - float2(2.0);
                                    _6484[1] = (float2(3.0) + _6528) / _6483[1];
                                    _6484[2] = (_6528 / _6483[2]) + float2(2.0);
                                }
                                int _7925 = _6535 ? 2 : 3;
                                int _7580;
                                float _7583;
                                _7583 = 0.0;
                                _7580 = 0;
                                float _7589;
                                for (; _7580 < _7925; _7583 = _7589, _7580++)
                                {
                                    _7589 = _7583;
                                    for (int _7586 = 0; _7586 < _7925; )
                                    {
                                        _7589 += ((_6483[_7586].x * _6483[_7580].y) * spvDepthCast(_213).sample_compare(_213Smplr, float3(fast::clamp(_193._m22.xy * (_6531 + float2(_6484[_7586].x, _6484[_7580].y)), _6473.xy, _6473.zw), _6289).xy, _6289));
                                        _7586++;
                                        continue;
                                    }
                                }
                                _7590 = _7583 * (_6535 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _7591 = _7590;
                            break;
                        }
                        uint _6299 = _6094 - _6195;
                        if (_6299 >= uint(_193._m21.w))
                        {
                            _7591 = 1.0;
                            break;
                        }
                        float _6320 = _193._m27[_6299].w * length(in.m_1691 - _193._m27[_6299].xyz);
                        float3 _6338 = ((in.m_1691 + (_2313 * (_6320 * _193._m25.x))) + (_6128 * (_6320 * _193._m25.y))) - _193._m27[_6299].xyz;
                        float3 _6340 = abs(_6338);
                        float _6342 = _6340.x;
                        float _6344 = _6340.y;
                        bool _6345 = _6342 >= _6344;
                        bool _6353;
                        if (_6345)
                        {
                            _6353 = _6342 >= _6340.z;
                        }
                        else
                        {
                            _6353 = _6345;
                        }
                        float _7565;
                        int _7567;
                        if (_6353)
                        {
                            _7567 = (_6338.x > 0.0) ? 0 : 1;
                            _7565 = _6342;
                        }
                        else
                        {
                            float _6365 = _6340.z;
                            bool _6366 = _6344 >= _6365;
                            int _7568;
                            if (_6366)
                            {
                                _7568 = (_6338.y > 0.0) ? 2 : 3;
                            }
                            else
                            {
                                _7568 = (_6338.z > 0.0) ? 4 : 5;
                            }
                            _7567 = _7568;
                            _7565 = _6366 ? _6344 : _6365;
                        }
                        if (_7565 <= 0.0)
                        {
                            _7591 = 1.0;
                            break;
                        }
                        float2 _6403 = float2(dot(_6338, _871[_7567]), dot(_6338, _880[_7567])) / float2(_7565 * _193._m24.z);
                        float _6410 = _193._m28[_6299].z + (_193._m28[_6299].w / _7565);
                        if (_6410 > 1.0)
                        {
                            _7591 = 1.0;
                            break;
                        }
                        float2 _6428 = _193._m28[_6299].xy + (float2(float(spvSMod(_7567, 3)), float(_7567 / 3)) * _193._m24.xy);
                        float2 _6668 = _193._m22.xy * 0.5;
                        float2 _6673 = _6428 + (float2(0.5 + (0.5 * _6403.x), 0.5 - (0.5 * _6403.y)) * _193._m24.xy);
                        float4 _6686 = float4(_6428 + _6668, (_6428 + _193._m24.xy) - _6668);
                        float _7579;
                        do
                        {
                            int _6712 = int(_193._m22.z);
                            if (_6712 <= 0)
                            {
                                _7579 = spvDepthCast(_213).sample_compare(_213Smplr, float3(fast::clamp(_6673, _6686.xy, _6686.zw), _6410).xy, _6410);
                                break;
                            }
                            float2 _6735 = (_6673 / _193._m22.xy) + float2(0.5);
                            float2 _6736 = floor(_6735);
                            float2 _6741 = _6735 - _6736;
                            float2 _6744 = _6736 - float2(0.5);
                            bool _6748 = _6712 == 1;
                            if (_6748)
                            {
                                float2 _6751 = _6741 * 2.0;
                                _6696[0] = float2(3.0) - _6751;
                                _6696[1] = float2(1.0) + _6751;
                                _6697[0] = ((float2(2.0) - _6741) / _6696[0]) - float2(1.0);
                                _6697[1] = (_6741 / _6696[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _6778 = _6741 * 3.0;
                                _6696[0] = float2(4.0) - _6778;
                                _6696[1] = float2(7.0);
                                _6696[2] = float2(1.0) + _6778;
                                _6697[0] = ((float2(3.0) - (_6741 * 2.0)) / _6696[0]) - float2(2.0);
                                _6697[1] = (float2(3.0) + _6741) / _6696[1];
                                _6697[2] = (_6741 / _6696[2]) + float2(2.0);
                            }
                            int _7928 = _6748 ? 2 : 3;
                            int _7569;
                            float _7572;
                            _7572 = 0.0;
                            _7569 = 0;
                            float _7578;
                            for (; _7569 < _7928; _7572 = _7578, _7569++)
                            {
                                _7578 = _7572;
                                for (int _7575 = 0; _7575 < _7928; )
                                {
                                    _7578 += ((_6696[_7575].x * _6696[_7569].y) * spvDepthCast(_213).sample_compare(_213Smplr, float3(fast::clamp(_193._m22.xy * (_6744 + float2(_6697[_7575].x, _6697[_7569].y)), _6686.xy, _6686.zw), _6410).xy, _6410));
                                    _7575++;
                                    continue;
                                }
                            }
                            _7579 = _7572 * (_6748 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _7591 = _7579;
                        break;
                    } while(false);
                    _7659 = _6159 * _7591;
                }
                else
                {
                    _7659 = _6159;
                }
                float3 _2845 = fast::normalize(_6128 + _2302);
                float _2850 = fast::clamp(dot(_7423, _6128), 0.0, 1.0);
                float _2855 = fast::clamp(dot(_7423, _2845), 0.0, 1.0);
                float3 _6883 = _2569 + (_5198 * powr(1.0 - fast::clamp(dot(_2302, _2845), 0.0, 1.0), 5.0));
                float _6897 = ((_2855 * _2855) * _5213) + 1.0;
                _2893 = _7661 + (((((float3(1.0) - _6883) * _2563) + ((_6883 * ((_5208 / ((3.1415927410125732421875 * _6897) * _6897)) * (0.5 / fast::max((_2850 * _5239) + (_7451 * sqrt(((_2850 * _2850) * _5235) + _5208)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875)) * _2850) * _7659);
            }
            _7708 = _7661;
        }
        else
        {
            _7708 = _2793;
        }
        _7705 = _7708;
    }
    float4 _2910 = _2905.sample(_1230, _2074);
    float _2928 = -length(_2301);
    float _7750;
    if (_193._m9.w != 0.0)
    {
        float _2952 = _193._m9.w * (in.m_1691 - _193._m6.xyz).y;
        float _7747;
        if (abs(_2952) < 9.9999997473787516355514526367188e-05)
        {
            _7747 = 1.0 - (0.5 * _2952);
        }
        else
        {
            _7747 = (1.0 - exp(fast::min(-_2952, 60.0))) / _2952;
        }
        _7750 = 1.0 - exp((_2928 * (_193._m7.w * exp(fast::min((-_193._m9.w) * (_193._m6.y - _193._m6.w), 30.0)))) * _7747);
    }
    else
    {
        _7750 = 1.0 - exp(_2928 * _193._m7.w);
    }
    float3 _3003 = mix(mix(_7705, _7417, float3(_1531._m1.y)) + ((_1531._m5.xyz * _2910.xyz) * (float3(1.0) + in.m_2315.yzw)), _193._m7.xyz, float3(_7750));
    float3 _7751;
    if (_193._m33.w > 0.5)
    {
        _7751 = _3003 / (float3(1.0) + _3003);
    }
    else
    {
        _7751 = _3003;
    }
    out.m_3015 = float4(_7751, (in.m_2083.w * _1531._m0.w) * _2081.w);
    float2 _7752;
    do
    {
        if (in.m_3025.w <= 0.0)
        {
            _7752 = float2(0.0);
            break;
        }
        _7752 = ((in.m_3025.xy / float2(in.m_3025.w)) - (in.m_3024.xy / float2(in.m_3024.w))) * float2(0.5, -0.5);
        break;
    } while(false);
    out.m_3023 = _7752;
    return out;
}

