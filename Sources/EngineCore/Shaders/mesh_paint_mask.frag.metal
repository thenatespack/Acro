// Generated from mesh_paint_mask.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 52c068ceb3fb1ca4
// glsl-fnv1a64: 72efd934e73050e1

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
    float4 m_3047 [[color(0)]];
    float2 m_3055 [[color(1)]];
};

struct fragment_main_in
{
    float3 m_1691 [[user(locn0)]];
    float3 m_1601 [[user(locn1)]];
    float2 m_2060 [[user(locn2)]];
    float4 m_2083 [[user(locn3)]];
    float4 m_2337 [[user(locn5)]];
    float4 m_3056 [[user(locn6)]];
    float4 m_3057 [[user(locn7)]];
    float4 m_1607 [[user(locn8)]];
    float4 m_2116 [[user(locn9)]];
    float4 m_2553 [[user(locn10)]];
};

fragment fragment_main_out fragment_main(fragment_main_in in [[stage_in]], constant _1529& _1531 [[buffer(2)]], constant _1682& _1684 [[buffer(3)]], constant _1717& _1719 [[buffer(4)]], constant _1725& _1727 [[buffer(5)]], constant _1820& _1822 [[buffer(6)]], constant _1841& _1843 [[buffer(7)]], constant _191& _193 [[buffer(15)]], texture2d<float> _213 [[texture(0)]], texture2d<float> _2076 [[texture(1)]], texture2d<float> _2541 [[texture(2)]], texture2d<float> _2214 [[texture(3)]], texture2d<float> _2007 [[texture(4)]], texture2d<float> _2934 [[texture(5)]], texture2d<float> _1228 [[texture(6)]], texture2d<float> _1334 [[texture(7)]], sampler _213Smplr [[sampler(0)]], sampler _1230 [[sampler(1)]], sampler _1336 [[sampler(7)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])
{
    fragment_main_out out = {};
    float2 _2074 = float2(dot(_1531._m2.xy, in.m_2060) + _1531._m2.z, dot(_1531._m3.xy, in.m_2060) + _1531._m3.z);
    float4 _2081 = _2076.sample(_1230, _2074);
    float3 _2091 = _2081.xyz;
    if ((_1531._m0.w * _2081.w) < _1531._m6.x)
    {
        discard_fragment();
    }
    float3 _2120 = ((in.m_2083.xyz * _1531._m0.xyz) * _2091) * in.m_2116.xyz;
    float3 _7259;
    if (_1531._m1.x > 0.5)
    {
        float2 _2135 = floor(in.m_1691.xz * float2(0.5));
        _7259 = _2120 * ((mod(abs(_2135.x + _2135.y), 2.0) < 0.5) ? 1.0 : 0.75);
    }
    else
    {
        _7259 = _2120;
    }
    float3 _7356;
    float _7387;
    float2 _7420;
    if (_1531._m3.w > 0.5)
    {
        float3 _3158;
        float2 _3165;
        float _7257;
        do
        {
            float3 _3129 = float4(_1531._m2.w, _1531._m3.w, 0.0, 0.0).xyy;
            float3 _3132 = floor(_3129 * float3(1.52587890625e-05));
            float3 _3137 = _3129 - (_3132 * 65536.0);
            float3 _3140 = floor(_3137 * float3(0.00390625));
            float3 _3148 = _3137 - (_3140 * 256.0);
            _3158 = (float3(_3148.x, _3140.x, _3132.x) * float3(0.0039215688593685626983642578125)) * 2.0;
            _3165 = float2(_3148.y, _3140.y) * float2(0.0039215688593685626983642578125);
            float _3168 = _3132.y - 128.0;
            float _3174 = floor(_3168 * 0.03125) * 0.3333333432674407958984375;
            float3 _3180 = fast::normalize(in.m_1601);
            float _3184 = dot(_3180, in.m_1607.xyz);
            float _3196 = (_3184 / fast::max(length(in.m_1607.xyz - (_3180 * _3184)), 9.9999999747524270787835121154785e-07)) * 25.5;
            if (((-24.0) + _3196) < (-2.0))
            {
                _7257 = 0.0;
                break;
            }
            float2 _3204 = _2074 * (4.0 * exp2(mod(_3168, 32.0) * 0.3333333432674407958984375));
            float2 _3241 = floor(_3204);
            float2 _3244 = _3204 - _3241;
            float2 _3252 = (_3244 * _3244) * (float2(3.0) - (_3244 * 2.0));
            uint2 _3280 = uint2(int2(_3241) + int2(65536));
            uint _3289 = ((_3280.x * 1597334677u) ^ (_3280.y * 3812015801u)) * 1597334677u;
            uint2 _3305 = uint2(int2(_3241 + float2(1.0, 0.0)) + int2(65536));
            uint _3314 = ((_3305.x * 1597334677u) ^ (_3305.y * 3812015801u)) * 1597334677u;
            float _3259 = _3252.x;
            uint2 _3330 = uint2(int2(_3241 + float2(0.0, 1.0)) + int2(65536));
            uint _3339 = ((_3330.x * 1597334677u) ^ (_3330.y * 3812015801u)) * 1597334677u;
            uint2 _3355 = uint2(int2(_3241 + float2(1.0)) + int2(65536));
            uint _3364 = ((_3355.x * 1597334677u) ^ (_3355.y * 3812015801u)) * 1597334677u;
            float2 _3210 = (_3204 * 2.7000000476837158203125) + float2(17.299999237060546875, 5.099999904632568359375);
            float2 _3383 = floor(_3210);
            float2 _3386 = _3210 - _3383;
            float2 _3394 = (_3386 * _3386) * (float2(3.0) - (_3386 * 2.0));
            uint2 _3422 = uint2(int2(_3383) + int2(65536));
            uint _3431 = ((_3422.x * 1597334677u) ^ (_3422.y * 3812015801u)) * 1597334677u;
            uint2 _3447 = uint2(int2(_3383 + float2(1.0, 0.0)) + int2(65536));
            uint _3456 = ((_3447.x * 1597334677u) ^ (_3447.y * 3812015801u)) * 1597334677u;
            float _3401 = _3394.x;
            uint2 _3472 = uint2(int2(_3383 + float2(0.0, 1.0)) + int2(65536));
            uint _3481 = ((_3472.x * 1597334677u) ^ (_3472.y * 3812015801u)) * 1597334677u;
            uint2 _3497 = uint2(int2(_3383 + float2(1.0)) + int2(65536));
            uint _3506 = ((_3497.x * 1597334677u) ^ (_3497.y * 3812015801u)) * 1597334677u;
            float _3215 = mix(0.449999988079071044921875, 0.0500000007450580596923828125, _3174);
            float _3223 = (_3196 + (-24.450000762939453125)) + ((((mix(mix(float((_3289 ^ (_3289 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_3314 ^ (_3314 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _3259), mix(float((_3339 ^ (_3339 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_3364 ^ (_3364 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _3259), _3252.y) * 0.64999997615814208984375) + (mix(mix(float((_3431 ^ (_3431 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_3456 ^ (_3456 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _3401), mix(float((_3481 ^ (_3481 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_3506 ^ (_3506 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _3401), _3394.y) * 0.3499999940395355224609375)) - 0.5) * mix(0.800000011920928955078125, 2.2000000476837158203125, _3174));
            _7257 = smoothstep(-_3215, _3215, _3223);
            break;
        } while(false);
        _7420 = _3165;
        _7387 = _7257;
        _7356 = mix(_7259, (in.m_2083.xyz * _3158) * mix(float3(1.0), _2091 * 2.0, float3(0.5)), float3(_7257));
    }
    else
    {
        _7420 = float2(0.0);
        _7387 = 0.0;
        _7356 = _7259;
    }
    float3 _2179 = fast::normalize(in.m_1601);
    float3 _7269;
    if (_1531._m6.y > 0.5)
    {
        float3 _2194 = in.m_1607.xyz - (_2179 * dot(_2179, in.m_1607.xyz));
        float3 _7270;
        if (dot(_2194, _2194) > 9.9999999600419720025001879548654e-13)
        {
            float3 _2203 = fast::normalize(_2194);
            float4 _2219 = _2214.sample(_1230, _2074);
            float3 _7261;
            if (_1531._m6.z > 0.5)
            {
                float2 _7260;
                if (_1531._m6.z > 1.5)
                {
                    _7260 = _2219.xw;
                }
                else
                {
                    _7260 = _2219.xy;
                }
                float2 _2241 = (_7260 * 2.0) - float2(1.0);
                _7261 = float3(_2241, sqrt(fast::clamp(1.0 - dot(_2241, _2241), 0.0, 1.0)));
            }
            else
            {
                _7261 = (_2219.xyz * 2.0) - float3(1.0);
            }
            float2 _2263 = _7261.xy * _1531._m4.z;
            _7270 = fast::normalize(((_2203 * _2263.x) + ((cross(_2179, _2203) * ((in.m_1607.w < 0.0) ? (-1.0) : 1.0)) * _2263.y)) + (_2179 * _7261.z));
        }
        else
        {
            _7270 = _2179;
        }
        _7269 = _7270;
    }
    else
    {
        _7269 = _2179;
    }
    bool _2287 = _1531._m5.w > 0.5;
    float _7266;
    if (_2287)
    {
        _7266 = fast::clamp(_1531._m1.z, 0.0, 1.0);
    }
    else
    {
        _7266 = 0.0;
    }
    bool _2305;
    if (_2287)
    {
        _2305 = !gl_FrontFacing;
    }
    else
    {
        _2305 = _2287;
    }
    float3 _7456;
    if (_2305 && (_7266 <= 0.0))
    {
        _7456 = -_7269;
    }
    else
    {
        _7456 = _7269;
    }
    float3 _2317 = fast::normalize(_193._m4.xyz);
    float3 _2323 = _193._m6.xyz - in.m_1691;
    float3 _2324 = fast::normalize(_2323);
    float3 _2329 = fast::normalize(_2317 + _2324);
    float3 _2335 = _2179 * (gl_FrontFacing ? 1.0 : (-1.0));
    bool _2340 = in.m_2337.x > 0.5;
    float3 _7450;
    float _7490;
    if ((_193._m5.w > 0.5) && _2340)
    {
        float _7326;
        float3 _7327;
        do
        {
            int _3535 = int(_193._m21.x);
            float _3543 = dot(_193._m20.xyz, in.m_1691) + _193._m20.w;
            int _7271;
            _7271 = 0;
            for (;;)
            {
                bool _3549 = _7271 < (_3535 - 1);
                bool _3557;
                if (_3549)
                {
                    _3557 = _3543 > _193._m16[_7271];
                }
                else
                {
                    _3557 = _3549;
                }
                if (_3557)
                {
                    _7271++;
                    continue;
                }
                else
                {
                    break;
                }
            }
            if (_3543 > _193._m16[_7271])
            {
                _7327 = float3(1.0);
                _7326 = 1.0;
                break;
            }
            float _7284;
            do
            {
                float4 _3659 = _193._m14[_7271] * float4(in.m_1691 + (_2335 * _193._m18[_7271]), 1.0);
                float _3662 = _3659.x;
                bool _3663 = _3662 < 0.0;
                bool _3670;
                if (!_3663)
                {
                    _3670 = _3662 > 1.0;
                }
                else
                {
                    _3670 = _3663;
                }
                bool _3677;
                if (!_3670)
                {
                    _3677 = _3659.y < 0.0;
                }
                else
                {
                    _3677 = _3670;
                }
                bool _3684;
                if (!_3677)
                {
                    _3684 = _3659.y > 1.0;
                }
                else
                {
                    _3684 = _3677;
                }
                if (_3684)
                {
                    _7284 = 1.0;
                    break;
                }
                float2 _3697 = float2(float(_7271 & 1), float(_7271 >> 1)) * _193._m23.xy;
                float _3704 = fast::min(_3659.z, 1.0) - _193._m19[_7271];
                float2 _3723 = _193._m22.xy * 0.5;
                float2 _3728 = _3697 + (_3659.xy * _193._m23.xy);
                float4 _3741 = float4(_3697 + _3723, (_3697 + _193._m23.xy) - _3723);
                float _7283;
                do
                {
                    int _3767 = int(_193._m22.z);
                    if (_3767 <= 0)
                    {
                        _7283 = spvDepthCast(_213).sample_compare(_213Smplr, float3(fast::clamp(_3728, _3741.xy, _3741.zw), _3704).xy, _3704);
                        break;
                    }
                    float2 _3790 = (_3728 / _193._m22.xy) + float2(0.5);
                    float2 _3791 = floor(_3790);
                    float2 _3796 = _3790 - _3791;
                    float2 _3799 = _3791 - float2(0.5);
                    bool _3803 = _3767 == 1;
                    spvUnsafeArray<float2, 3> _3751;
                    spvUnsafeArray<float2, 3> _3752;
                    if (_3803)
                    {
                        float2 _3806 = _3796 * 2.0;
                        _3751[0] = float2(3.0) - _3806;
                        _3751[1] = float2(1.0) + _3806;
                        _3752[0] = ((float2(2.0) - _3796) / _3751[0]) - float2(1.0);
                        _3752[1] = (_3796 / _3751[1]) + float2(1.0);
                    }
                    else
                    {
                        float2 _3833 = _3796 * 3.0;
                        _3751[0] = float2(4.0) - _3833;
                        _3751[1] = float2(7.0);
                        _3751[2] = float2(1.0) + _3833;
                        _3752[0] = ((float2(3.0) - (_3796 * 2.0)) / _3751[0]) - float2(2.0);
                        _3752[1] = (float2(3.0) + _3796) / _3751[1];
                        _3752[2] = (_3796 / _3751[2]) + float2(2.0);
                    }
                    int _8040 = _3803 ? 2 : 3;
                    int _7273;
                    float _7276;
                    _7276 = 0.0;
                    _7273 = 0;
                    float _7282;
                    for (; _7273 < _8040; _7276 = _7282, _7273++)
                    {
                        _7282 = _7276;
                        for (int _7279 = 0; _7279 < _8040; )
                        {
                            _7282 += ((_3751[_7279].x * _3751[_7273].y) * spvDepthCast(_213).sample_compare(_213Smplr, float3(fast::clamp(_193._m22.xy * (_3799 + float2(_3752[_7279].x, _3752[_7273].y)), _3741.xy, _3741.zw), _3704).xy, _3704));
                            _7279++;
                            continue;
                        }
                    }
                    _7283 = _7276 * (_3803 ? 0.0625 : 0.0069444444961845874786376953125);
                    break;
                } while(false);
                _7284 = _7283;
                break;
            } while(false);
            float3 _7321;
            float _7324;
            if (_3543 > _193._m17[_7271])
            {
                float _3597 = (_3543 - _193._m17[_7271]) / (_193._m16[_7271] - _193._m17[_7271]);
                int _3599 = _7271 + 1;
                float3 _7322;
                float _7325;
                if (_3599 < _3535)
                {
                    float _7304;
                    do
                    {
                        float4 _3946 = _193._m14[_3599] * float4(in.m_1691 + (_2335 * _193._m18[_3599]), 1.0);
                        float _3949 = _3946.x;
                        bool _3950 = _3949 < 0.0;
                        bool _3957;
                        if (!_3950)
                        {
                            _3957 = _3949 > 1.0;
                        }
                        else
                        {
                            _3957 = _3950;
                        }
                        bool _3964;
                        if (!_3957)
                        {
                            _3964 = _3946.y < 0.0;
                        }
                        else
                        {
                            _3964 = _3957;
                        }
                        bool _3971;
                        if (!_3964)
                        {
                            _3971 = _3946.y > 1.0;
                        }
                        else
                        {
                            _3971 = _3964;
                        }
                        if (_3971)
                        {
                            _7304 = 1.0;
                            break;
                        }
                        float2 _3984 = float2(float(_3599 & 1), float(_3599 >> 1)) * _193._m23.xy;
                        float _3991 = fast::min(_3946.z, 1.0) - _193._m19[_3599];
                        float2 _4010 = _193._m22.xy * 0.5;
                        float2 _4015 = _3984 + (_3946.xy * _193._m23.xy);
                        float4 _4028 = float4(_3984 + _4010, (_3984 + _193._m23.xy) - _4010);
                        float _7303;
                        do
                        {
                            int _4054 = int(_193._m22.z);
                            if (_4054 <= 0)
                            {
                                _7303 = spvDepthCast(_213).sample_compare(_213Smplr, float3(fast::clamp(_4015, _4028.xy, _4028.zw), _3991).xy, _3991);
                                break;
                            }
                            float2 _4077 = (_4015 / _193._m22.xy) + float2(0.5);
                            float2 _4078 = floor(_4077);
                            float2 _4083 = _4077 - _4078;
                            float2 _4086 = _4078 - float2(0.5);
                            bool _4090 = _4054 == 1;
                            spvUnsafeArray<float2, 3> _4038;
                            spvUnsafeArray<float2, 3> _4039;
                            if (_4090)
                            {
                                float2 _4093 = _4083 * 2.0;
                                _4038[0] = float2(3.0) - _4093;
                                _4038[1] = float2(1.0) + _4093;
                                _4039[0] = ((float2(2.0) - _4083) / _4038[0]) - float2(1.0);
                                _4039[1] = (_4083 / _4038[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _4120 = _4083 * 3.0;
                                _4038[0] = float2(4.0) - _4120;
                                _4038[1] = float2(7.0);
                                _4038[2] = float2(1.0) + _4120;
                                _4039[0] = ((float2(3.0) - (_4083 * 2.0)) / _4038[0]) - float2(2.0);
                                _4039[1] = (float2(3.0) + _4083) / _4038[1];
                                _4039[2] = (_4083 / _4038[2]) + float2(2.0);
                            }
                            int _8042 = _4090 ? 2 : 3;
                            int _7293;
                            float _7296;
                            _7296 = 0.0;
                            _7293 = 0;
                            float _7302;
                            for (; _7293 < _8042; _7296 = _7302, _7293++)
                            {
                                _7302 = _7296;
                                for (int _7299 = 0; _7299 < _8042; )
                                {
                                    _7302 += ((_4038[_7299].x * _4038[_7293].y) * spvDepthCast(_213).sample_compare(_213Smplr, float3(fast::clamp(_193._m22.xy * (_4086 + float2(_4039[_7299].x, _4039[_7293].y)), _4028.xy, _4028.zw), _3991).xy, _3991));
                                    _7299++;
                                    continue;
                                }
                            }
                            _7303 = _7296 * (_4090 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _7304 = _7303;
                        break;
                    } while(false);
                    _7325 = mix(_7284, _7304, _3597);
                    _7322 = mix(_567[_7271], _567[_3599], float3(_3597));
                }
                else
                {
                    _7325 = mix(_7284, 1.0, _3597);
                    _7322 = _567[_7271];
                }
                _7324 = _7325;
                _7321 = _7322;
            }
            else
            {
                _7324 = _7284;
                _7321 = _567[_7271];
            }
            _7327 = select(float3(1.0), _7321, bool3(_193._m22.w > 0.5));
            _7326 = _7324;
            break;
        } while(false);
        _7490 = _7326;
        _7450 = _7356 * _7327;
    }
    else
    {
        _7490 = 1.0;
        _7450 = _7356;
    }
    float3 _2366 = _193._m5.xyz * _193._m4.w;
    bool _2370 = _1531._m6.w > 0.5;
    float _7379;
    if (_2370)
    {
        _7379 = 1.0;
    }
    else
    {
        _7379 = 1.0 + (_1531._m4.w * (_2007.sample(_1230, _2074).x - 1.0));
    }
    float _2390 = abs(in.m_1607.w);
    float _7580;
    if (_2390 > 0.0)
    {
        _7580 = _7379 * fast::min(_2390, 1.0);
    }
    else
    {
        _7580 = _7379;
    }
    float3 _7738;
    if (!_2287)
    {
        float _2406 = dot(_7456, _2317);
        float3 _7730;
        if (_193._m29.x > 0.5)
        {
            float _4271 = (_193._m29.z * _7456.x) - (_193._m29.w * _7456.z);
            float _4284 = (_193._m29.w * _7456.x) + (_193._m29.z * _7456.z);
            float _4302 = 1.09254801273345947265625 * _4271;
            spvUnsafeArray<float, 9> _7034 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _7456.y, 0.48860299587249755859375 * _4284, 0.48860299587249755859375 * _4271, _4302 * _7456.y, (1.09254801273345947265625 * _7456.y) * _4284, 0.3153919875621795654296875 * (((3.0 * _4284) * _4284) - 1.0), _4302 * _4284, 0.546274006366729736328125 * ((_4271 * _4271) - (_7456.y * _7456.y)) });
            spvUnsafeArray<float, 9> _4216 = _7034;
            float3 _7729;
            _7729 = float3(0.0);
            for (int _7728 = 0; _7728 < 9; )
            {
                _7729 += (_1228.read(uint2((int2(496, 256) + int2(_7728, 0))), 0).xyz * _4216[_7728]);
                _7728++;
                continue;
            }
            _7730 = fast::max(_7729, float3(0.0)) * _193._m29.y;
        }
        else
        {
            _7730 = mix(_193._m9.xyz, _193._m8.xyz, float3((_7456.y * 0.5) + 0.5)) * _193._m8.w;
        }
        float3 _2456 = (_7450 * ((_7730 * _7580) + ((_2366 * fast::max(_2406, 0.0)) * _7490))) + ((_2366 * ((powr(fast::max(dot(_7456, _2329), 0.0), _1531._m1.w) * _1531._m1.z) * step(0.0, _2406))) * _7490);
        float3 _7739;
        if (_193._m13.w > 0.5)
        {
            float2 _4387 = fast::clamp(floor(gl_FragCoord.xy * _193._m12.xy), float2(0.0), _193._m13.xy - float2(1.0));
            uint _4415 = uint((((fast::clamp(floor((log2(fast::max(dot(_193._m11.xyz, in.m_1691) + _193._m11.w, 9.9999999747524270787835121154785e-07)) * _193._m12.z) + _193._m12.w), 0.0, _193._m13.z - 1.0) * _193._m13.y) + _4387.y) * _193._m13.x) + _4387.x);
            uint _4417 = _4415 >> uint(2);
            uint _4419 = _4415 & 3u;
            uint _4423 = _1822._m0[_4417][_4419] & 65535u;
            uint _4425 = _1822._m0[_4417][_4419] >> uint(16);
            float3 _7740;
            _7740 = _2456;
            float3 _2536;
            spvUnsafeArray<float2, 3> _4833;
            spvUnsafeArray<float2, 3> _4834;
            spvUnsafeArray<float2, 3> _5046;
            spvUnsafeArray<float2, 3> _5047;
            for (uint _7737 = _4423; _7737 < (_4423 + _4425); _7740 = _2536, _7737++)
            {
                uint _4431 = _7737 / 3u;
                uint _4444 = (_1843._m0[_4431 >> uint(2)][_4431 & 3u] >> ((_7737 - (_4431 * 3u)) * 10u)) & 1023u;
                float3 _4461 = _1684._m0[_4444].xyz - in.m_1691;
                float _4464 = dot(_4461, _4461);
                float _4468 = _4464 * _1684._m0[_4444].w;
                float _4473 = fast::clamp(1.0 - (_4468 * _4468), 0.0, 1.0);
                float3 _4478 = _4461 * rsqrt(fast::max(_4464, 9.9999999392252902907785028219223e-09));
                float _4496 = fast::clamp((dot(-_4478, _1727._m0[_4444].xyz) * _1719._m0[_4444].w) + _1727._m0[_4444].w, 0.0, 1.0);
                float3 _4509 = _1719._m0[_4444].xyz * ((((_4473 * _4473) * _4496) * _4496) / fast::max(_4464, 9.9999997473787516355514526367188e-05));
                float3 _7945;
                if (_2340)
                {
                    float _7891;
                    do
                    {
                        uint _4545 = uint(_193._m21.z);
                        if (_4444 < _4545)
                        {
                            float _4567 = _193._m26[_4444].z * fast::max((_193._m15[_4444] * float4(in.m_1691, 1.0)).w, 0.0);
                            float4 _4591 = _193._m15[_4444] * float4((in.m_1691 + (_2335 * (_4567 * _193._m25.x))) + (_4478 * (_4567 * _193._m25.y)), 1.0);
                            float _4593 = _4591.w;
                            if (_4593 <= 0.0)
                            {
                                _7891 = 1.0;
                                break;
                            }
                            float3 _4602 = _4591.xyz / float3(_4593);
                            float _4604 = _4602.x;
                            bool _4605 = _4604 < 0.0;
                            bool _4612;
                            if (!_4605)
                            {
                                _4612 = _4604 > 1.0;
                            }
                            else
                            {
                                _4612 = _4605;
                            }
                            bool _4619;
                            if (!_4612)
                            {
                                _4619 = _4602.y < 0.0;
                            }
                            else
                            {
                                _4619 = _4612;
                            }
                            bool _4626;
                            if (!_4619)
                            {
                                _4626 = _4602.y > 1.0;
                            }
                            else
                            {
                                _4626 = _4619;
                            }
                            bool _4633;
                            if (!_4626)
                            {
                                _4633 = _4602.z > 1.0;
                            }
                            else
                            {
                                _4633 = _4626;
                            }
                            if (_4633)
                            {
                                _7891 = 1.0;
                                break;
                            }
                            float _4639 = _4602.z;
                            float2 _4805 = _193._m22.xy * 0.5;
                            float2 _4810 = _193._m26[_4444].xy + (_4602.xy * _193._m23.zw);
                            float4 _4823 = float4(_193._m26[_4444].xy + _4805, (_193._m26[_4444].xy + _193._m23.zw) - _4805);
                            float _7890;
                            do
                            {
                                int _4849 = int(_193._m22.z);
                                if (_4849 <= 0)
                                {
                                    float2 _4859 = fast::clamp(_4810, _4823.xy, _4823.zw);
                                    _7890 = spvDepthCast(_213).sample_compare(_213Smplr, float3(_4859, _4639).xy, _4639);
                                    break;
                                }
                                float2 _4872 = (_4810 / _193._m22.xy) + float2(0.5);
                                float2 _4873 = floor(_4872);
                                float2 _4878 = _4872 - _4873;
                                float2 _4881 = _4873 - float2(0.5);
                                bool _4885 = _4849 == 1;
                                if (_4885)
                                {
                                    float2 _4888 = _4878 * 2.0;
                                    _4833[0] = float2(3.0) - _4888;
                                    _4833[1] = float2(1.0) + _4888;
                                    _4834[0] = ((float2(2.0) - _4878) / _4833[0]) - float2(1.0);
                                    _4834[1] = (_4878 / _4833[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _4915 = _4878 * 3.0;
                                    _4833[0] = float2(4.0) - _4915;
                                    _4833[1] = float2(7.0);
                                    _4833[2] = float2(1.0) + _4915;
                                    _4834[0] = ((float2(3.0) - (_4878 * 2.0)) / _4833[0]) - float2(2.0);
                                    _4834[1] = (float2(3.0) + _4878) / _4833[1];
                                    _4834[2] = (_4878 / _4833[2]) + float2(2.0);
                                }
                                int _8047 = _4885 ? 2 : 3;
                                int _7880;
                                float _7883;
                                _7883 = 0.0;
                                _7880 = 0;
                                float _7889;
                                for (; _7880 < _8047; _7883 = _7889, _7880++)
                                {
                                    _7889 = _7883;
                                    for (int _7886 = 0; _7886 < _8047; )
                                    {
                                        _7889 += ((_4833[_7886].x * _4833[_7880].y) * spvDepthCast(_213).sample_compare(_213Smplr, float3(fast::clamp(_193._m22.xy * (_4881 + float2(_4834[_7886].x, _4834[_7880].y)), _4823.xy, _4823.zw), _4639).xy, _4639));
                                        _7886++;
                                        continue;
                                    }
                                }
                                _7890 = _7883 * (_4885 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _7891 = _7890;
                            break;
                        }
                        uint _4649 = _4444 - _4545;
                        if (_4649 >= uint(_193._m21.w))
                        {
                            _7891 = 1.0;
                            break;
                        }
                        float _4670 = _193._m27[_4649].w * length(in.m_1691 - _193._m27[_4649].xyz);
                        float3 _4688 = ((in.m_1691 + (_2335 * (_4670 * _193._m25.x))) + (_4478 * (_4670 * _193._m25.y))) - _193._m27[_4649].xyz;
                        float3 _4690 = abs(_4688);
                        float _4692 = _4690.x;
                        float _4694 = _4690.y;
                        bool _4695 = _4692 >= _4694;
                        bool _4703;
                        if (_4695)
                        {
                            _4703 = _4692 >= _4690.z;
                        }
                        else
                        {
                            _4703 = _4695;
                        }
                        float _7865;
                        int _7867;
                        if (_4703)
                        {
                            _7867 = (_4688.x > 0.0) ? 0 : 1;
                            _7865 = _4692;
                        }
                        else
                        {
                            float _4715 = _4690.z;
                            bool _4716 = _4694 >= _4715;
                            int _7868;
                            if (_4716)
                            {
                                _7868 = (_4688.y > 0.0) ? 2 : 3;
                            }
                            else
                            {
                                _7868 = (_4688.z > 0.0) ? 4 : 5;
                            }
                            _7867 = _7868;
                            _7865 = _4716 ? _4694 : _4715;
                        }
                        if (_7865 <= 0.0)
                        {
                            _7891 = 1.0;
                            break;
                        }
                        float2 _4753 = float2(dot(_4688, _871[_7867]), dot(_4688, _880[_7867])) / float2(_7865 * _193._m24.z);
                        float _4760 = _193._m28[_4649].z + (_193._m28[_4649].w / _7865);
                        if (_4760 > 1.0)
                        {
                            _7891 = 1.0;
                            break;
                        }
                        float2 _4778 = _193._m28[_4649].xy + (float2(float(spvSMod(_7867, 3)), float(_7867 / 3)) * _193._m24.xy);
                        float2 _5018 = _193._m22.xy * 0.5;
                        float2 _5023 = _4778 + (float2(0.5 + (0.5 * _4753.x), 0.5 - (0.5 * _4753.y)) * _193._m24.xy);
                        float4 _5036 = float4(_4778 + _5018, (_4778 + _193._m24.xy) - _5018);
                        float _7879;
                        do
                        {
                            int _5062 = int(_193._m22.z);
                            if (_5062 <= 0)
                            {
                                _7879 = spvDepthCast(_213).sample_compare(_213Smplr, float3(fast::clamp(_5023, _5036.xy, _5036.zw), _4760).xy, _4760);
                                break;
                            }
                            float2 _5085 = (_5023 / _193._m22.xy) + float2(0.5);
                            float2 _5086 = floor(_5085);
                            float2 _5091 = _5085 - _5086;
                            float2 _5094 = _5086 - float2(0.5);
                            bool _5098 = _5062 == 1;
                            if (_5098)
                            {
                                float2 _5101 = _5091 * 2.0;
                                _5046[0] = float2(3.0) - _5101;
                                _5046[1] = float2(1.0) + _5101;
                                _5047[0] = ((float2(2.0) - _5091) / _5046[0]) - float2(1.0);
                                _5047[1] = (_5091 / _5046[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _5128 = _5091 * 3.0;
                                _5046[0] = float2(4.0) - _5128;
                                _5046[1] = float2(7.0);
                                _5046[2] = float2(1.0) + _5128;
                                _5047[0] = ((float2(3.0) - (_5091 * 2.0)) / _5046[0]) - float2(2.0);
                                _5047[1] = (float2(3.0) + _5091) / _5046[1];
                                _5047[2] = (_5091 / _5046[2]) + float2(2.0);
                            }
                            int _8050 = _5098 ? 2 : 3;
                            int _7869;
                            float _7872;
                            _7872 = 0.0;
                            _7869 = 0;
                            float _7878;
                            for (; _7869 < _8050; _7872 = _7878, _7869++)
                            {
                                _7878 = _7872;
                                for (int _7875 = 0; _7875 < _8050; )
                                {
                                    _7878 += ((_5046[_7875].x * _5046[_7869].y) * spvDepthCast(_213).sample_compare(_213Smplr, float3(fast::clamp(_193._m22.xy * (_5094 + float2(_5047[_7875].x, _5047[_7869].y)), _5036.xy, _5036.zw), _4760).xy, _4760));
                                    _7875++;
                                    continue;
                                }
                            }
                            _7879 = _7872 * (_5098 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _7891 = _7879;
                        break;
                    } while(false);
                    _7945 = _4509 * _7891;
                }
                else
                {
                    _7945 = _4509;
                }
                float _2507 = dot(_7456, _4478);
                _2536 = _7740 + (((_7450 * fast::max(_2507, 0.0)) * _7945) + (_7945 * ((powr(fast::max(dot(_7456, fast::normalize(_4478 + _2324)), 0.0), _1531._m1.w) * _1531._m1.z) * step(0.0, _2507))));
            }
            _7739 = _7740;
        }
        else
        {
            _7739 = _2456;
        }
        _7738 = _7739;
    }
    else
    {
        float4 _2546 = _2541.sample(_1230, _2074);
        float _2557 = fast::clamp((_1531._m4.x * _2546.z) * in.m_2553.y, 0.0, 1.0);
        float _2568 = fast::clamp((_1531._m4.y * _2546.y) * in.m_2553.x, 0.04500000178813934326171875, 1.0);
        float _7446;
        float _7451;
        if (_7387 > 0.0)
        {
            _7451 = mix(_2557, _7420.y, _7387);
            _7446 = mix(_2568, fast::max(_7420.x, 0.04500000178813934326171875), _7387);
        }
        else
        {
            _7451 = _2557;
            _7446 = _2568;
        }
        float _2587 = _7446 * _7446;
        float3 _2592 = _7450 * (1.0 - _7451);
        float3 _2598 = mix(float3(0.039999999105930328369140625), _7450, float3(_7451));
        bool _2602 = _7266 > 0.0;
        float3 _7479;
        if (_2602)
        {
            float3 _2607 = dfdx(in.m_1691);
            float3 _2609 = dfdy(in.m_1691);
            float3 _2610 = cross(_2607, _2609);
            float3 _7480;
            if (dot(_2610, _2610) > 9.9999996826552253889678874634872e-21)
            {
                _7480 = fast::normalize((fast::normalize(_2610) * ((dot(_2610, _2324) < 0.0) ? (-1.0) : 1.0)) + (_7456 - _2179));
            }
            else
            {
                _7480 = _7456;
            }
            _7479 = _7480;
        }
        else
        {
            _7479 = _7456;
        }
        float _2636 = fast::max(dot(_7479, _2324), 9.9999997473787516355514526367188e-05);
        float _2645 = dot(_7479, _2317);
        float _2646 = fast::clamp(_2645, 0.0, 1.0);
        float _2651 = fast::clamp(dot(_7479, _2329), 0.0, 1.0);
        float _2656 = fast::clamp(dot(_2324, _2329), 0.0, 1.0);
        float _7483;
        float _7484;
        if (_2602)
        {
            _7484 = fast::max(_2636, 0.5);
            _7483 = fast::max(_2656, 0.5);
        }
        else
        {
            _7484 = _2636;
            _7483 = _2656;
        }
        float3 _5230 = float3(1.0) - _2598;
        float3 _5233 = _2598 + (_5230 * powr(1.0 - _7483, 5.0));
        float _5240 = _2587 * _2587;
        float _5245 = _5240 - 1.0;
        float _5247 = ((_2651 * _2651) * _5245) + 1.0;
        float _5267 = 1.0 - _5240;
        float _5271 = sqrt(((_7484 * _7484) * _5267) + _5240);
        float3 _2702 = (((((float3(1.0) - _5233) * _2592) * fast::clamp(dot(_7456, _2317), 0.0, 1.0)) + (((_5233 * ((_5240 / ((3.1415927410125732421875 * _5247) * _5247)) * (0.5 / fast::max((_2646 * _5271) + (_7484 * sqrt(((_2646 * _2646) * _5267) + _5240)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875) * _2646)) * _2366) * _7490;
        float3 _7594;
        if (_2602)
        {
            _7594 = _2702 + (((((_2592 * _2366) * _7490) * _7266) * fast::clamp(-_2645, 0.0, 1.0)) * (0.3499999940395355224609375 + (0.64999997615814208984375 * powr(fast::clamp(dot(-_2324, _2317), 0.0, 1.0), 3.0))));
        }
        else
        {
            _7594 = _2702;
        }
        float3 _7520;
        float2 _7544;
        float3 _7556;
        if (_193._m29.x > 0.5)
        {
            float4 _5304 = _1334.sample(_1336, (((float2(_7484, _7446) * 31.0) + float2(0.5)) * float2(0.03125)));
            float _5363 = (_193._m29.z * _7456.x) - (_193._m29.w * _7456.z);
            float _5376 = (_193._m29.w * _7456.x) + (_193._m29.z * _7456.z);
            float _5394 = 1.09254801273345947265625 * _5363;
            spvUnsafeArray<float, 9> _7015 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _7456.y, 0.48860299587249755859375 * _5376, 0.48860299587249755859375 * _5363, _5394 * _7456.y, (1.09254801273345947265625 * _7456.y) * _5376, 0.3153919875621795654296875 * (((3.0 * _5376) * _5376) - 1.0), _5394 * _5376, 0.546274006366729736328125 * ((_5363 * _5363) - (_7456.y * _7456.y)) });
            spvUnsafeArray<float, 9> _5308 = _7015;
            float3 _7502;
            _7502 = float3(0.0);
            for (int _7501 = 0; _7501 < 9; )
            {
                _7502 += (_1228.read(uint2((int2(496, 256) + int2(_7501, 0))), 0).xyz * _5308[_7501]);
                _7501++;
                continue;
            }
            float3 _2754 = reflect(-_2324, _7479);
            float _5489 = _2754.x;
            float _5494 = _2754.z;
            float2 _5526 = float2((precise::atan2((_193._m29.z * _5489) - (_193._m29.w * _5494), -((_193._m29.w * _5489) + (_193._m29.z * _5494))) * 0.15915493667125701904296875) + 0.5, acos(fast::clamp(_2754.y, -1.0, 1.0)) * 0.3183098733425140380859375);
            float _5458 = _7446 * 5.0;
            int _5461 = min(int(_5458), 4);
            float2 _5547 = (_5526 * float2(_1290[_5461].zw)) - float2(0.5);
            float2 _5549 = floor(_5547);
            float2 _5552 = _5547 - _5549;
            int _5555 = int(_5549.x);
            int _5558 = int(_5549.y);
            int _7505;
            if (_5555 < 0)
            {
                _7505 = _5555 + _1290[_5461].z;
            }
            else
            {
                _7505 = _5555;
            }
            int _7506;
            if (_7505 >= _1290[_5461].z)
            {
                _7506 = _7505 - _1290[_5461].z;
            }
            else
            {
                _7506 = _7505;
            }
            int _5578 = _7506 + 1;
            int _8051 = (_5578 == _1290[_5461].z) ? 0 : _5578;
            int _5593 = min((_5558 + 1), (_1290[_5461].w - 1));
            int _5595 = max(_5558, 0);
            float3 _5648 = float3(_5552.x);
            int _5468 = _5461 + 1;
            float2 _5680 = (_5526 * float2(_1290[_5468].zw)) - float2(0.5);
            float2 _5682 = floor(_5680);
            float2 _5685 = _5680 - _5682;
            int _5688 = int(_5682.x);
            int _5691 = int(_5682.y);
            int _7512;
            if (_5688 < 0)
            {
                _7512 = _5688 + _1290[_5468].z;
            }
            else
            {
                _7512 = _5688;
            }
            int _7513;
            if (_7512 >= _1290[_5468].z)
            {
                _7513 = _7512 - _1290[_5468].z;
            }
            else
            {
                _7513 = _7512;
            }
            int _5711 = _7513 + 1;
            int _8052 = (_5711 == _1290[_5468].z) ? 0 : _5711;
            int _5726 = min((_5691 + 1), (_1290[_5468].w - 1));
            int _5728 = max(_5691, 0);
            float3 _5781 = float3(_5685.x);
            float3 _5483 = mix(mix(mix(_1228.read(uint2((_1290[_5461].xy + int2(_7506, _5595))), 0).xyz, _1228.read(uint2((_1290[_5461].xy + int2(_8051, _5595))), 0).xyz, _5648), mix(_1228.read(uint2((_1290[_5461].xy + int2(_7506, _5593))), 0).xyz, _1228.read(uint2((_1290[_5461].xy + int2(_8051, _5593))), 0).xyz, _5648), float3(_5552.y)), mix(mix(_1228.read(uint2((_1290[_5468].xy + int2(_7513, _5728))), 0).xyz, _1228.read(uint2((_1290[_5468].xy + int2(_8052, _5728))), 0).xyz, _5781), mix(_1228.read(uint2((_1290[_5468].xy + int2(_7513, _5726))), 0).xyz, _1228.read(uint2((_1290[_5468].xy + int2(_8052, _5726))), 0).xyz, _5781), float3(_5685.y)), float3(_5458 - float(_5461))) * _193._m29.y;
            _7556 = fast::max(_7502, float3(0.0)) * _193._m29.y;
            _7544 = _5304.xy;
            _7520 = _5483;
        }
        else
        {
            float4 _5799 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * _7446) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);
            float _5801 = _5799.x;
            float3 _5836 = mix(_193._m9.xyz, _193._m8.xyz, float3((_7456.y * 0.5) + 0.5)) * _193._m8.w;
            _7556 = _5836;
            _7544 = (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_5801 * _5801, exp2((-9.27999973297119140625) * _7484)) * _5801) + _5799.y)) + _5799.zw;
            _7520 = mix(mix(_193._m9.xyz, _193._m8.xyz, float3((reflect(-_2324, _7479).y * 0.5) + 0.5)) * _193._m8.w, _5836, float3(_7446));
        }
        bool _2786;
        if (_2370)
        {
            _2786 = _193._m33.z > 0.5;
        }
        else
        {
            _2786 = _2370;
        }
        float3 _7565;
        if (_2786)
        {
            float3 _7541;
            do
            {
                float _5915 = ((_193._m32.x * (1.0 - smoothstep(_193._m33.x * 0.5, _193._m33.x, abs(dot(_193._m31.xyz, in.m_1691) - _193._m31.w)))) * smoothstep(0.5, 0.89999997615814208984375, dot(_2335, _193._m31.xyz))) * (1.0 - smoothstep(_193._m32.y * 0.5, _193._m32.y, _7446));
                if (_5915 <= 0.0)
                {
                    _7541 = _7520;
                    break;
                }
                float4 _5940 = _193._m30 * float4(in.m_1691 + ((_7456 - (_193._m31.xyz * dot(_7456, _193._m31.xyz))) * _193._m32.w), 1.0);
                float2 _5953 = ((float2(_5940.x, -_5940.y) / float2(_5940.w)) * 0.5) + float2(0.5);
                float _5957 = _193._m32.z * _7446;
                float3 _7539;
                float _7540;
                _7540 = 0.0;
                _7539 = float3(0.0);
                for (int _7538 = 0; _7538 < 12; )
                {
                    float _5964 = float(_7538);
                    float _5972 = _5964 * 2.3999631404876708984375;
                    float2 _5984 = _5953 + (float2(cos(_5972) * _193._m33.y, sin(_5972)) * (sqrt((_5964 + 0.5) * 0.083333335816860198974609375) * _5957));
                    float2 _5989 = fast::min(_5984, float2(1.0) - _5984);
                    float _5995 = smoothstep(0.0, 0.039999999105930328369140625, fast::min(_5989.x, _5989.y));
                    float4 _6003 = _2007.sample(_1230, fast::clamp(_5984, float2(0.0), float2(1.0)), level(0.0));
                    float3 _6005 = _6003.xyz;
                    _7540 += (_6003.w * _5995);
                    _7539 += ((_6005 / (float3(1.0) - fast::min(_6005, float3(0.99500000476837158203125)))) * _5995);
                    _7538++;
                    continue;
                }
                _7541 = mix(_7520, (_7539 * float3(0.083333335816860198974609375)) + (_7520 * (1.0 - (_7540 * 0.083333335816860198974609375))), float3(_5915));
                break;
            } while(false);
            _7565 = _7541;
        }
        else
        {
            _7565 = _7520;
        }
        float3 _2806 = (_2598 * _7544.x) + float3(_7544.y);
        float3 _2822 = _7594 + (((((float3(1.0) - _2806) * _2592) * _7556) + (_2806 * _7565)) * _7580);
        float3 _7741;
        if (_193._m13.w > 0.5)
        {
            float2 _6069 = fast::clamp(floor(gl_FragCoord.xy * _193._m12.xy), float2(0.0), _193._m13.xy - float2(1.0));
            uint _6097 = uint((((fast::clamp(floor((log2(fast::max(dot(_193._m11.xyz, in.m_1691) + _193._m11.w, 9.9999999747524270787835121154785e-07)) * _193._m12.z) + _193._m12.w), 0.0, _193._m13.z - 1.0) * _193._m13.y) + _6069.y) * _193._m13.x) + _6069.x);
            uint _6099 = _6097 >> uint(2);
            uint _6101 = _6097 & 3u;
            uint _6105 = _1822._m0[_6099][_6101] & 65535u;
            uint _6107 = _1822._m0[_6099][_6101] >> uint(16);
            float3 _7694;
            _7694 = _2822;
            float3 _2922;
            spvUnsafeArray<float2, 3> _6515;
            spvUnsafeArray<float2, 3> _6516;
            spvUnsafeArray<float2, 3> _6728;
            spvUnsafeArray<float2, 3> _6729;
            for (uint _7597 = _6105; _7597 < (_6105 + _6107); _7694 = _2922, _7597++)
            {
                uint _6113 = _7597 / 3u;
                uint _6126 = (_1843._m0[_6113 >> uint(2)][_6113 & 3u] >> ((_7597 - (_6113 * 3u)) * 10u)) & 1023u;
                float3 _6143 = _1684._m0[_6126].xyz - in.m_1691;
                float _6146 = dot(_6143, _6143);
                float _6150 = _6146 * _1684._m0[_6126].w;
                float _6155 = fast::clamp(1.0 - (_6150 * _6150), 0.0, 1.0);
                float3 _6160 = _6143 * rsqrt(fast::max(_6146, 9.9999999392252902907785028219223e-09));
                float _6178 = fast::clamp((dot(-_6160, _1727._m0[_6126].xyz) * _1719._m0[_6126].w) + _1727._m0[_6126].w, 0.0, 1.0);
                float3 _6191 = _1719._m0[_6126].xyz * ((((_6155 * _6155) * _6178) * _6178) / fast::max(_6146, 9.9999997473787516355514526367188e-05));
                float3 _7692;
                if (_2340)
                {
                    float _7624;
                    do
                    {
                        uint _6227 = uint(_193._m21.z);
                        if (_6126 < _6227)
                        {
                            float _6249 = _193._m26[_6126].z * fast::max((_193._m15[_6126] * float4(in.m_1691, 1.0)).w, 0.0);
                            float4 _6273 = _193._m15[_6126] * float4((in.m_1691 + (_2335 * (_6249 * _193._m25.x))) + (_6160 * (_6249 * _193._m25.y)), 1.0);
                            float _6275 = _6273.w;
                            if (_6275 <= 0.0)
                            {
                                _7624 = 1.0;
                                break;
                            }
                            float3 _6284 = _6273.xyz / float3(_6275);
                            float _6286 = _6284.x;
                            bool _6287 = _6286 < 0.0;
                            bool _6294;
                            if (!_6287)
                            {
                                _6294 = _6286 > 1.0;
                            }
                            else
                            {
                                _6294 = _6287;
                            }
                            bool _6301;
                            if (!_6294)
                            {
                                _6301 = _6284.y < 0.0;
                            }
                            else
                            {
                                _6301 = _6294;
                            }
                            bool _6308;
                            if (!_6301)
                            {
                                _6308 = _6284.y > 1.0;
                            }
                            else
                            {
                                _6308 = _6301;
                            }
                            bool _6315;
                            if (!_6308)
                            {
                                _6315 = _6284.z > 1.0;
                            }
                            else
                            {
                                _6315 = _6308;
                            }
                            if (_6315)
                            {
                                _7624 = 1.0;
                                break;
                            }
                            float _6321 = _6284.z;
                            float2 _6487 = _193._m22.xy * 0.5;
                            float2 _6492 = _193._m26[_6126].xy + (_6284.xy * _193._m23.zw);
                            float4 _6505 = float4(_193._m26[_6126].xy + _6487, (_193._m26[_6126].xy + _193._m23.zw) - _6487);
                            float _7623;
                            do
                            {
                                int _6531 = int(_193._m22.z);
                                if (_6531 <= 0)
                                {
                                    float2 _6541 = fast::clamp(_6492, _6505.xy, _6505.zw);
                                    _7623 = spvDepthCast(_213).sample_compare(_213Smplr, float3(_6541, _6321).xy, _6321);
                                    break;
                                }
                                float2 _6554 = (_6492 / _193._m22.xy) + float2(0.5);
                                float2 _6555 = floor(_6554);
                                float2 _6560 = _6554 - _6555;
                                float2 _6563 = _6555 - float2(0.5);
                                bool _6567 = _6531 == 1;
                                if (_6567)
                                {
                                    float2 _6570 = _6560 * 2.0;
                                    _6515[0] = float2(3.0) - _6570;
                                    _6515[1] = float2(1.0) + _6570;
                                    _6516[0] = ((float2(2.0) - _6560) / _6515[0]) - float2(1.0);
                                    _6516[1] = (_6560 / _6515[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _6597 = _6560 * 3.0;
                                    _6515[0] = float2(4.0) - _6597;
                                    _6515[1] = float2(7.0);
                                    _6515[2] = float2(1.0) + _6597;
                                    _6516[0] = ((float2(3.0) - (_6560 * 2.0)) / _6515[0]) - float2(2.0);
                                    _6516[1] = (float2(3.0) + _6560) / _6515[1];
                                    _6516[2] = (_6560 / _6515[2]) + float2(2.0);
                                }
                                int _8054 = _6567 ? 2 : 3;
                                int _7613;
                                float _7616;
                                _7616 = 0.0;
                                _7613 = 0;
                                float _7622;
                                for (; _7613 < _8054; _7616 = _7622, _7613++)
                                {
                                    _7622 = _7616;
                                    for (int _7619 = 0; _7619 < _8054; )
                                    {
                                        _7622 += ((_6515[_7619].x * _6515[_7613].y) * spvDepthCast(_213).sample_compare(_213Smplr, float3(fast::clamp(_193._m22.xy * (_6563 + float2(_6516[_7619].x, _6516[_7613].y)), _6505.xy, _6505.zw), _6321).xy, _6321));
                                        _7619++;
                                        continue;
                                    }
                                }
                                _7623 = _7616 * (_6567 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _7624 = _7623;
                            break;
                        }
                        uint _6331 = _6126 - _6227;
                        if (_6331 >= uint(_193._m21.w))
                        {
                            _7624 = 1.0;
                            break;
                        }
                        float _6352 = _193._m27[_6331].w * length(in.m_1691 - _193._m27[_6331].xyz);
                        float3 _6370 = ((in.m_1691 + (_2335 * (_6352 * _193._m25.x))) + (_6160 * (_6352 * _193._m25.y))) - _193._m27[_6331].xyz;
                        float3 _6372 = abs(_6370);
                        float _6374 = _6372.x;
                        float _6376 = _6372.y;
                        bool _6377 = _6374 >= _6376;
                        bool _6385;
                        if (_6377)
                        {
                            _6385 = _6374 >= _6372.z;
                        }
                        else
                        {
                            _6385 = _6377;
                        }
                        float _7598;
                        int _7600;
                        if (_6385)
                        {
                            _7600 = (_6370.x > 0.0) ? 0 : 1;
                            _7598 = _6374;
                        }
                        else
                        {
                            float _6397 = _6372.z;
                            bool _6398 = _6376 >= _6397;
                            int _7601;
                            if (_6398)
                            {
                                _7601 = (_6370.y > 0.0) ? 2 : 3;
                            }
                            else
                            {
                                _7601 = (_6370.z > 0.0) ? 4 : 5;
                            }
                            _7600 = _7601;
                            _7598 = _6398 ? _6376 : _6397;
                        }
                        if (_7598 <= 0.0)
                        {
                            _7624 = 1.0;
                            break;
                        }
                        float2 _6435 = float2(dot(_6370, _871[_7600]), dot(_6370, _880[_7600])) / float2(_7598 * _193._m24.z);
                        float _6442 = _193._m28[_6331].z + (_193._m28[_6331].w / _7598);
                        if (_6442 > 1.0)
                        {
                            _7624 = 1.0;
                            break;
                        }
                        float2 _6460 = _193._m28[_6331].xy + (float2(float(spvSMod(_7600, 3)), float(_7600 / 3)) * _193._m24.xy);
                        float2 _6700 = _193._m22.xy * 0.5;
                        float2 _6705 = _6460 + (float2(0.5 + (0.5 * _6435.x), 0.5 - (0.5 * _6435.y)) * _193._m24.xy);
                        float4 _6718 = float4(_6460 + _6700, (_6460 + _193._m24.xy) - _6700);
                        float _7612;
                        do
                        {
                            int _6744 = int(_193._m22.z);
                            if (_6744 <= 0)
                            {
                                _7612 = spvDepthCast(_213).sample_compare(_213Smplr, float3(fast::clamp(_6705, _6718.xy, _6718.zw), _6442).xy, _6442);
                                break;
                            }
                            float2 _6767 = (_6705 / _193._m22.xy) + float2(0.5);
                            float2 _6768 = floor(_6767);
                            float2 _6773 = _6767 - _6768;
                            float2 _6776 = _6768 - float2(0.5);
                            bool _6780 = _6744 == 1;
                            if (_6780)
                            {
                                float2 _6783 = _6773 * 2.0;
                                _6728[0] = float2(3.0) - _6783;
                                _6728[1] = float2(1.0) + _6783;
                                _6729[0] = ((float2(2.0) - _6773) / _6728[0]) - float2(1.0);
                                _6729[1] = (_6773 / _6728[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _6810 = _6773 * 3.0;
                                _6728[0] = float2(4.0) - _6810;
                                _6728[1] = float2(7.0);
                                _6728[2] = float2(1.0) + _6810;
                                _6729[0] = ((float2(3.0) - (_6773 * 2.0)) / _6728[0]) - float2(2.0);
                                _6729[1] = (float2(3.0) + _6773) / _6728[1];
                                _6729[2] = (_6773 / _6728[2]) + float2(2.0);
                            }
                            int _8057 = _6780 ? 2 : 3;
                            int _7602;
                            float _7605;
                            _7605 = 0.0;
                            _7602 = 0;
                            float _7611;
                            for (; _7602 < _8057; _7605 = _7611, _7602++)
                            {
                                _7611 = _7605;
                                for (int _7608 = 0; _7608 < _8057; )
                                {
                                    _7611 += ((_6728[_7608].x * _6728[_7602].y) * spvDepthCast(_213).sample_compare(_213Smplr, float3(fast::clamp(_193._m22.xy * (_6776 + float2(_6729[_7608].x, _6729[_7602].y)), _6718.xy, _6718.zw), _6442).xy, _6442));
                                    _7608++;
                                    continue;
                                }
                            }
                            _7612 = _7605 * (_6780 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _7624 = _7612;
                        break;
                    } while(false);
                    _7692 = _6191 * _7624;
                }
                else
                {
                    _7692 = _6191;
                }
                float3 _2874 = fast::normalize(_6160 + _2324);
                float _2879 = fast::clamp(dot(_7456, _6160), 0.0, 1.0);
                float _2884 = fast::clamp(dot(_7456, _2874), 0.0, 1.0);
                float3 _6915 = _2598 + (_5230 * powr(1.0 - fast::clamp(dot(_2324, _2874), 0.0, 1.0), 5.0));
                float _6929 = ((_2884 * _2884) * _5245) + 1.0;
                _2922 = _7694 + (((((float3(1.0) - _6915) * _2592) + ((_6915 * ((_5240 / ((3.1415927410125732421875 * _6929) * _6929)) * (0.5 / fast::max((_2879 * _5271) + (_7484 * sqrt(((_2879 * _2879) * _5267) + _5240)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875)) * _2879) * _7692);
            }
            _7741 = _7694;
        }
        else
        {
            _7741 = _2822;
        }
        _7738 = _7741;
    }
    float4 _2939 = _2934.sample(_1230, _2074);
    float _2960 = -length(_2323);
    float _7783;
    if (_193._m9.w != 0.0)
    {
        float _2984 = _193._m9.w * (in.m_1691 - _193._m6.xyz).y;
        float _7780;
        if (abs(_2984) < 9.9999997473787516355514526367188e-05)
        {
            _7780 = 1.0 - (0.5 * _2984);
        }
        else
        {
            _7780 = (1.0 - exp(fast::min(-_2984, 60.0))) / _2984;
        }
        _7783 = 1.0 - exp((_2960 * (_193._m7.w * exp(fast::min((-_193._m9.w) * (_193._m6.y - _193._m6.w), 30.0)))) * _7780);
    }
    else
    {
        _7783 = 1.0 - exp(_2960 * _193._m7.w);
    }
    float3 _3035 = mix(mix(_7738, _7450, float3(_1531._m1.y)) + (((_1531._m5.xyz * _2939.xyz) * (float3(1.0) + in.m_2337.yzw)) * in.m_2553.z), _193._m7.xyz, float3(_7783));
    float3 _7784;
    if (_193._m33.w > 0.5)
    {
        _7784 = _3035 / (float3(1.0) + _3035);
    }
    else
    {
        _7784 = _3035;
    }
    out.m_3047 = float4(_7784, in.m_2083.w * in.m_2116.w);
    float2 _7864;
    do
    {
        if (in.m_3057.w <= 0.0)
        {
            _7864 = float2(0.0);
            break;
        }
        _7864 = ((in.m_3057.xy / float2(in.m_3057.w)) - (in.m_3056.xy / float2(in.m_3056.w))) * float2(0.5, -0.5);
        break;
    } while(false);
    out.m_3055 = _7864;
    return out;
}

