// Generated from mesh_paint.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 4fe4aad6c0b17aa5
// glsl-fnv1a64: a46ad71f169736b6

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
    float4 m_3034 [[color(0)]];
    float2 m_3042 [[color(1)]];
};

struct fragment_main_in
{
    float3 m_1691 [[user(locn0)]];
    float3 m_1601 [[user(locn1)]];
    float2 m_2060 [[user(locn2)]];
    float4 m_2083 [[user(locn3)]];
    float4 m_2324 [[user(locn5)]];
    float4 m_3043 [[user(locn6)]];
    float4 m_3044 [[user(locn7)]];
    float4 m_1607 [[user(locn8)]];
    float4 m_2103 [[user(locn9)]];
    float4 m_2540 [[user(locn10)]];
};

fragment fragment_main_out fragment_main(fragment_main_in in [[stage_in]], constant _1529& _1531 [[buffer(2)]], constant _1682& _1684 [[buffer(3)]], constant _1717& _1719 [[buffer(4)]], constant _1725& _1727 [[buffer(5)]], constant _1820& _1822 [[buffer(6)]], constant _1841& _1843 [[buffer(7)]], constant _191& _193 [[buffer(15)]], texture2d<float> _213 [[texture(0)]], texture2d<float> _2076 [[texture(1)]], texture2d<float> _2528 [[texture(2)]], texture2d<float> _2201 [[texture(3)]], texture2d<float> _2007 [[texture(4)]], texture2d<float> _2921 [[texture(5)]], texture2d<float> _1228 [[texture(6)]], texture2d<float> _1334 [[texture(7)]], sampler _213Smplr [[sampler(0)]], sampler _1230 [[sampler(1)]], sampler _1336 [[sampler(7)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])
{
    fragment_main_out out = {};
    float2 _2074 = float2(dot(_1531._m2.xy, in.m_2060) + _1531._m2.z, dot(_1531._m3.xy, in.m_2060) + _1531._m3.z);
    float4 _2081 = _2076.sample(_1230, _2074);
    float3 _2091 = _2081.xyz;
    float3 _2107 = ((in.m_2083.xyz * _1531._m0.xyz) * _2091) * in.m_2103.xyz;
    float3 _7245;
    if (_1531._m1.x > 0.5)
    {
        float2 _2122 = floor(in.m_1691.xz * float2(0.5));
        _7245 = _2107 * ((mod(abs(_2122.x + _2122.y), 2.0) < 0.5) ? 1.0 : 0.75);
    }
    else
    {
        _7245 = _2107;
    }
    float3 _7342;
    float _7373;
    float2 _7406;
    if (_1531._m3.w > 0.5)
    {
        float3 _3145;
        float2 _3152;
        float _7243;
        do
        {
            float3 _3116 = float4(_1531._m2.w, _1531._m3.w, 0.0, 0.0).xyy;
            float3 _3119 = floor(_3116 * float3(1.52587890625e-05));
            float3 _3124 = _3116 - (_3119 * 65536.0);
            float3 _3127 = floor(_3124 * float3(0.00390625));
            float3 _3135 = _3124 - (_3127 * 256.0);
            _3145 = (float3(_3135.x, _3127.x, _3119.x) * float3(0.0039215688593685626983642578125)) * 2.0;
            _3152 = float2(_3135.y, _3127.y) * float2(0.0039215688593685626983642578125);
            float _3155 = _3119.y - 128.0;
            float _3161 = floor(_3155 * 0.03125) * 0.3333333432674407958984375;
            float3 _3167 = fast::normalize(in.m_1601);
            float _3171 = dot(_3167, in.m_1607.xyz);
            float _3183 = (_3171 / fast::max(length(in.m_1607.xyz - (_3167 * _3171)), 9.9999999747524270787835121154785e-07)) * 25.5;
            if (((-24.0) + _3183) < (-2.0))
            {
                _7243 = 0.0;
                break;
            }
            float2 _3191 = _2074 * (4.0 * exp2(mod(_3155, 32.0) * 0.3333333432674407958984375));
            float2 _3228 = floor(_3191);
            float2 _3231 = _3191 - _3228;
            float2 _3239 = (_3231 * _3231) * (float2(3.0) - (_3231 * 2.0));
            uint2 _3267 = uint2(int2(_3228) + int2(65536));
            uint _3276 = ((_3267.x * 1597334677u) ^ (_3267.y * 3812015801u)) * 1597334677u;
            uint2 _3292 = uint2(int2(_3228 + float2(1.0, 0.0)) + int2(65536));
            uint _3301 = ((_3292.x * 1597334677u) ^ (_3292.y * 3812015801u)) * 1597334677u;
            float _3246 = _3239.x;
            uint2 _3317 = uint2(int2(_3228 + float2(0.0, 1.0)) + int2(65536));
            uint _3326 = ((_3317.x * 1597334677u) ^ (_3317.y * 3812015801u)) * 1597334677u;
            uint2 _3342 = uint2(int2(_3228 + float2(1.0)) + int2(65536));
            uint _3351 = ((_3342.x * 1597334677u) ^ (_3342.y * 3812015801u)) * 1597334677u;
            float2 _3197 = (_3191 * 2.7000000476837158203125) + float2(17.299999237060546875, 5.099999904632568359375);
            float2 _3370 = floor(_3197);
            float2 _3373 = _3197 - _3370;
            float2 _3381 = (_3373 * _3373) * (float2(3.0) - (_3373 * 2.0));
            uint2 _3409 = uint2(int2(_3370) + int2(65536));
            uint _3418 = ((_3409.x * 1597334677u) ^ (_3409.y * 3812015801u)) * 1597334677u;
            uint2 _3434 = uint2(int2(_3370 + float2(1.0, 0.0)) + int2(65536));
            uint _3443 = ((_3434.x * 1597334677u) ^ (_3434.y * 3812015801u)) * 1597334677u;
            float _3388 = _3381.x;
            uint2 _3459 = uint2(int2(_3370 + float2(0.0, 1.0)) + int2(65536));
            uint _3468 = ((_3459.x * 1597334677u) ^ (_3459.y * 3812015801u)) * 1597334677u;
            uint2 _3484 = uint2(int2(_3370 + float2(1.0)) + int2(65536));
            uint _3493 = ((_3484.x * 1597334677u) ^ (_3484.y * 3812015801u)) * 1597334677u;
            float _3202 = mix(0.449999988079071044921875, 0.0500000007450580596923828125, _3161);
            float _3210 = (_3183 + (-24.450000762939453125)) + ((((mix(mix(float((_3276 ^ (_3276 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_3301 ^ (_3301 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _3246), mix(float((_3326 ^ (_3326 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_3351 ^ (_3351 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _3246), _3239.y) * 0.64999997615814208984375) + (mix(mix(float((_3418 ^ (_3418 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_3443 ^ (_3443 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _3388), mix(float((_3468 ^ (_3468 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_3493 ^ (_3493 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _3388), _3381.y) * 0.3499999940395355224609375)) - 0.5) * mix(0.800000011920928955078125, 2.2000000476837158203125, _3161));
            _7243 = smoothstep(-_3202, _3202, _3210);
            break;
        } while(false);
        _7406 = _3152;
        _7373 = _7243;
        _7342 = mix(_7245, (in.m_2083.xyz * _3145) * mix(float3(1.0), _2091 * 2.0, float3(0.5)), float3(_7243));
    }
    else
    {
        _7406 = float2(0.0);
        _7373 = 0.0;
        _7342 = _7245;
    }
    float3 _2166 = fast::normalize(in.m_1601);
    float3 _7255;
    if (_1531._m6.y > 0.5)
    {
        float3 _2181 = in.m_1607.xyz - (_2166 * dot(_2166, in.m_1607.xyz));
        float3 _7256;
        if (dot(_2181, _2181) > 9.9999999600419720025001879548654e-13)
        {
            float3 _2190 = fast::normalize(_2181);
            float4 _2206 = _2201.sample(_1230, _2074);
            float3 _7247;
            if (_1531._m6.z > 0.5)
            {
                float2 _7246;
                if (_1531._m6.z > 1.5)
                {
                    _7246 = _2206.xw;
                }
                else
                {
                    _7246 = _2206.xy;
                }
                float2 _2228 = (_7246 * 2.0) - float2(1.0);
                _7247 = float3(_2228, sqrt(fast::clamp(1.0 - dot(_2228, _2228), 0.0, 1.0)));
            }
            else
            {
                _7247 = (_2206.xyz * 2.0) - float3(1.0);
            }
            float2 _2250 = _7247.xy * _1531._m4.z;
            _7256 = fast::normalize(((_2190 * _2250.x) + ((cross(_2166, _2190) * ((in.m_1607.w < 0.0) ? (-1.0) : 1.0)) * _2250.y)) + (_2166 * _7247.z));
        }
        else
        {
            _7256 = _2166;
        }
        _7255 = _7256;
    }
    else
    {
        _7255 = _2166;
    }
    bool _2274 = _1531._m5.w > 0.5;
    float _7252;
    if (_2274)
    {
        _7252 = fast::clamp(_1531._m1.z, 0.0, 1.0);
    }
    else
    {
        _7252 = 0.0;
    }
    bool _2292;
    if (_2274)
    {
        _2292 = !gl_FrontFacing;
    }
    else
    {
        _2292 = _2274;
    }
    float3 _7442;
    if (_2292 && (_7252 <= 0.0))
    {
        _7442 = -_7255;
    }
    else
    {
        _7442 = _7255;
    }
    float3 _2304 = fast::normalize(_193._m4.xyz);
    float3 _2310 = _193._m6.xyz - in.m_1691;
    float3 _2311 = fast::normalize(_2310);
    float3 _2316 = fast::normalize(_2304 + _2311);
    float3 _2322 = _2166 * (gl_FrontFacing ? 1.0 : (-1.0));
    bool _2327 = in.m_2324.x > 0.5;
    float3 _7436;
    float _7476;
    if ((_193._m5.w > 0.5) && _2327)
    {
        float _7312;
        float3 _7313;
        do
        {
            int _3522 = int(_193._m21.x);
            float _3530 = dot(_193._m20.xyz, in.m_1691) + _193._m20.w;
            int _7257;
            _7257 = 0;
            for (;;)
            {
                bool _3536 = _7257 < (_3522 - 1);
                bool _3544;
                if (_3536)
                {
                    _3544 = _3530 > _193._m16[_7257];
                }
                else
                {
                    _3544 = _3536;
                }
                if (_3544)
                {
                    _7257++;
                    continue;
                }
                else
                {
                    break;
                }
            }
            if (_3530 > _193._m16[_7257])
            {
                _7313 = float3(1.0);
                _7312 = 1.0;
                break;
            }
            float _7270;
            do
            {
                float4 _3646 = _193._m14[_7257] * float4(in.m_1691 + (_2322 * _193._m18[_7257]), 1.0);
                float _3649 = _3646.x;
                bool _3650 = _3649 < 0.0;
                bool _3657;
                if (!_3650)
                {
                    _3657 = _3649 > 1.0;
                }
                else
                {
                    _3657 = _3650;
                }
                bool _3664;
                if (!_3657)
                {
                    _3664 = _3646.y < 0.0;
                }
                else
                {
                    _3664 = _3657;
                }
                bool _3671;
                if (!_3664)
                {
                    _3671 = _3646.y > 1.0;
                }
                else
                {
                    _3671 = _3664;
                }
                if (_3671)
                {
                    _7270 = 1.0;
                    break;
                }
                float2 _3684 = float2(float(_7257 & 1), float(_7257 >> 1)) * _193._m23.xy;
                float _3691 = fast::min(_3646.z, 1.0) - _193._m19[_7257];
                float2 _3710 = _193._m22.xy * 0.5;
                float2 _3715 = _3684 + (_3646.xy * _193._m23.xy);
                float4 _3728 = float4(_3684 + _3710, (_3684 + _193._m23.xy) - _3710);
                float _7269;
                do
                {
                    int _3754 = int(_193._m22.z);
                    if (_3754 <= 0)
                    {
                        _7269 = spvDepthCast(_213).sample_compare(_213Smplr, float3(fast::clamp(_3715, _3728.xy, _3728.zw), _3691).xy, _3691);
                        break;
                    }
                    float2 _3777 = (_3715 / _193._m22.xy) + float2(0.5);
                    float2 _3778 = floor(_3777);
                    float2 _3783 = _3777 - _3778;
                    float2 _3786 = _3778 - float2(0.5);
                    bool _3790 = _3754 == 1;
                    spvUnsafeArray<float2, 3> _3738;
                    spvUnsafeArray<float2, 3> _3739;
                    if (_3790)
                    {
                        float2 _3793 = _3783 * 2.0;
                        _3738[0] = float2(3.0) - _3793;
                        _3738[1] = float2(1.0) + _3793;
                        _3739[0] = ((float2(2.0) - _3783) / _3738[0]) - float2(1.0);
                        _3739[1] = (_3783 / _3738[1]) + float2(1.0);
                    }
                    else
                    {
                        float2 _3820 = _3783 * 3.0;
                        _3738[0] = float2(4.0) - _3820;
                        _3738[1] = float2(7.0);
                        _3738[2] = float2(1.0) + _3820;
                        _3739[0] = ((float2(3.0) - (_3783 * 2.0)) / _3738[0]) - float2(2.0);
                        _3739[1] = (float2(3.0) + _3783) / _3738[1];
                        _3739[2] = (_3783 / _3738[2]) + float2(2.0);
                    }
                    int _7930 = _3790 ? 2 : 3;
                    int _7259;
                    float _7262;
                    _7262 = 0.0;
                    _7259 = 0;
                    float _7268;
                    for (; _7259 < _7930; _7262 = _7268, _7259++)
                    {
                        _7268 = _7262;
                        for (int _7265 = 0; _7265 < _7930; )
                        {
                            _7268 += ((_3738[_7265].x * _3738[_7259].y) * spvDepthCast(_213).sample_compare(_213Smplr, float3(fast::clamp(_193._m22.xy * (_3786 + float2(_3739[_7265].x, _3739[_7259].y)), _3728.xy, _3728.zw), _3691).xy, _3691));
                            _7265++;
                            continue;
                        }
                    }
                    _7269 = _7262 * (_3790 ? 0.0625 : 0.0069444444961845874786376953125);
                    break;
                } while(false);
                _7270 = _7269;
                break;
            } while(false);
            float3 _7307;
            float _7310;
            if (_3530 > _193._m17[_7257])
            {
                float _3584 = (_3530 - _193._m17[_7257]) / (_193._m16[_7257] - _193._m17[_7257]);
                int _3586 = _7257 + 1;
                float3 _7308;
                float _7311;
                if (_3586 < _3522)
                {
                    float _7290;
                    do
                    {
                        float4 _3933 = _193._m14[_3586] * float4(in.m_1691 + (_2322 * _193._m18[_3586]), 1.0);
                        float _3936 = _3933.x;
                        bool _3937 = _3936 < 0.0;
                        bool _3944;
                        if (!_3937)
                        {
                            _3944 = _3936 > 1.0;
                        }
                        else
                        {
                            _3944 = _3937;
                        }
                        bool _3951;
                        if (!_3944)
                        {
                            _3951 = _3933.y < 0.0;
                        }
                        else
                        {
                            _3951 = _3944;
                        }
                        bool _3958;
                        if (!_3951)
                        {
                            _3958 = _3933.y > 1.0;
                        }
                        else
                        {
                            _3958 = _3951;
                        }
                        if (_3958)
                        {
                            _7290 = 1.0;
                            break;
                        }
                        float2 _3971 = float2(float(_3586 & 1), float(_3586 >> 1)) * _193._m23.xy;
                        float _3978 = fast::min(_3933.z, 1.0) - _193._m19[_3586];
                        float2 _3997 = _193._m22.xy * 0.5;
                        float2 _4002 = _3971 + (_3933.xy * _193._m23.xy);
                        float4 _4015 = float4(_3971 + _3997, (_3971 + _193._m23.xy) - _3997);
                        float _7289;
                        do
                        {
                            int _4041 = int(_193._m22.z);
                            if (_4041 <= 0)
                            {
                                _7289 = spvDepthCast(_213).sample_compare(_213Smplr, float3(fast::clamp(_4002, _4015.xy, _4015.zw), _3978).xy, _3978);
                                break;
                            }
                            float2 _4064 = (_4002 / _193._m22.xy) + float2(0.5);
                            float2 _4065 = floor(_4064);
                            float2 _4070 = _4064 - _4065;
                            float2 _4073 = _4065 - float2(0.5);
                            bool _4077 = _4041 == 1;
                            spvUnsafeArray<float2, 3> _4025;
                            spvUnsafeArray<float2, 3> _4026;
                            if (_4077)
                            {
                                float2 _4080 = _4070 * 2.0;
                                _4025[0] = float2(3.0) - _4080;
                                _4025[1] = float2(1.0) + _4080;
                                _4026[0] = ((float2(2.0) - _4070) / _4025[0]) - float2(1.0);
                                _4026[1] = (_4070 / _4025[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _4107 = _4070 * 3.0;
                                _4025[0] = float2(4.0) - _4107;
                                _4025[1] = float2(7.0);
                                _4025[2] = float2(1.0) + _4107;
                                _4026[0] = ((float2(3.0) - (_4070 * 2.0)) / _4025[0]) - float2(2.0);
                                _4026[1] = (float2(3.0) + _4070) / _4025[1];
                                _4026[2] = (_4070 / _4025[2]) + float2(2.0);
                            }
                            int _7932 = _4077 ? 2 : 3;
                            int _7279;
                            float _7282;
                            _7282 = 0.0;
                            _7279 = 0;
                            float _7288;
                            for (; _7279 < _7932; _7282 = _7288, _7279++)
                            {
                                _7288 = _7282;
                                for (int _7285 = 0; _7285 < _7932; )
                                {
                                    _7288 += ((_4025[_7285].x * _4025[_7279].y) * spvDepthCast(_213).sample_compare(_213Smplr, float3(fast::clamp(_193._m22.xy * (_4073 + float2(_4026[_7285].x, _4026[_7279].y)), _4015.xy, _4015.zw), _3978).xy, _3978));
                                    _7285++;
                                    continue;
                                }
                            }
                            _7289 = _7282 * (_4077 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _7290 = _7289;
                        break;
                    } while(false);
                    _7311 = mix(_7270, _7290, _3584);
                    _7308 = mix(_567[_7257], _567[_3586], float3(_3584));
                }
                else
                {
                    _7311 = mix(_7270, 1.0, _3584);
                    _7308 = _567[_7257];
                }
                _7310 = _7311;
                _7307 = _7308;
            }
            else
            {
                _7310 = _7270;
                _7307 = _567[_7257];
            }
            _7313 = select(float3(1.0), _7307, bool3(_193._m22.w > 0.5));
            _7312 = _7310;
            break;
        } while(false);
        _7476 = _7312;
        _7436 = _7342 * _7313;
    }
    else
    {
        _7476 = 1.0;
        _7436 = _7342;
    }
    float3 _2353 = _193._m5.xyz * _193._m4.w;
    bool _2357 = _1531._m6.w > 0.5;
    float _7365;
    if (_2357)
    {
        _7365 = 1.0;
    }
    else
    {
        _7365 = 1.0 + (_1531._m4.w * (_2007.sample(_1230, _2074).x - 1.0));
    }
    float _2377 = abs(in.m_1607.w);
    float _7566;
    if (_2377 > 0.0)
    {
        _7566 = _7365 * fast::min(_2377, 1.0);
    }
    else
    {
        _7566 = _7365;
    }
    float3 _7724;
    if (!_2274)
    {
        float _2393 = dot(_7442, _2304);
        float3 _7716;
        if (_193._m29.x > 0.5)
        {
            float _4258 = (_193._m29.z * _7442.x) - (_193._m29.w * _7442.z);
            float _4271 = (_193._m29.w * _7442.x) + (_193._m29.z * _7442.z);
            float _4289 = 1.09254801273345947265625 * _4258;
            spvUnsafeArray<float, 9> _7021 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _7442.y, 0.48860299587249755859375 * _4271, 0.48860299587249755859375 * _4258, _4289 * _7442.y, (1.09254801273345947265625 * _7442.y) * _4271, 0.3153919875621795654296875 * (((3.0 * _4271) * _4271) - 1.0), _4289 * _4271, 0.546274006366729736328125 * ((_4258 * _4258) - (_7442.y * _7442.y)) });
            spvUnsafeArray<float, 9> _4203 = _7021;
            float3 _7715;
            _7715 = float3(0.0);
            for (int _7714 = 0; _7714 < 9; )
            {
                _7715 += (_1228.read(uint2((int2(496, 256) + int2(_7714, 0))), 0).xyz * _4203[_7714]);
                _7714++;
                continue;
            }
            _7716 = fast::max(_7715, float3(0.0)) * _193._m29.y;
        }
        else
        {
            _7716 = mix(_193._m9.xyz, _193._m8.xyz, float3((_7442.y * 0.5) + 0.5)) * _193._m8.w;
        }
        float3 _2443 = (_7436 * ((_7716 * _7566) + ((_2353 * fast::max(_2393, 0.0)) * _7476))) + ((_2353 * ((powr(fast::max(dot(_7442, _2316), 0.0), _1531._m1.w) * _1531._m1.z) * step(0.0, _2393))) * _7476);
        float3 _7725;
        if (_193._m13.w > 0.5)
        {
            float2 _4374 = fast::clamp(floor(gl_FragCoord.xy * _193._m12.xy), float2(0.0), _193._m13.xy - float2(1.0));
            uint _4402 = uint((((fast::clamp(floor((log2(fast::max(dot(_193._m11.xyz, in.m_1691) + _193._m11.w, 9.9999999747524270787835121154785e-07)) * _193._m12.z) + _193._m12.w), 0.0, _193._m13.z - 1.0) * _193._m13.y) + _4374.y) * _193._m13.x) + _4374.x);
            uint _4404 = _4402 >> uint(2);
            uint _4406 = _4402 & 3u;
            uint _4410 = _1822._m0[_4404][_4406] & 65535u;
            uint _4412 = _1822._m0[_4404][_4406] >> uint(16);
            float3 _7726;
            _7726 = _2443;
            float3 _2523;
            spvUnsafeArray<float2, 3> _4820;
            spvUnsafeArray<float2, 3> _4821;
            spvUnsafeArray<float2, 3> _5033;
            spvUnsafeArray<float2, 3> _5034;
            for (uint _7723 = _4410; _7723 < (_4410 + _4412); _7726 = _2523, _7723++)
            {
                uint _4418 = _7723 / 3u;
                uint _4431 = (_1843._m0[_4418 >> uint(2)][_4418 & 3u] >> ((_7723 - (_4418 * 3u)) * 10u)) & 1023u;
                float3 _4448 = _1684._m0[_4431].xyz - in.m_1691;
                float _4451 = dot(_4448, _4448);
                float _4455 = _4451 * _1684._m0[_4431].w;
                float _4460 = fast::clamp(1.0 - (_4455 * _4455), 0.0, 1.0);
                float3 _4465 = _4448 * rsqrt(fast::max(_4451, 9.9999999392252902907785028219223e-09));
                float _4483 = fast::clamp((dot(-_4465, _1727._m0[_4431].xyz) * _1719._m0[_4431].w) + _1727._m0[_4431].w, 0.0, 1.0);
                float3 _4496 = _1719._m0[_4431].xyz * ((((_4460 * _4460) * _4483) * _4483) / fast::max(_4451, 9.9999997473787516355514526367188e-05));
                float3 _7852;
                if (_2327)
                {
                    float _7798;
                    do
                    {
                        uint _4532 = uint(_193._m21.z);
                        if (_4431 < _4532)
                        {
                            float _4554 = _193._m26[_4431].z * fast::max((_193._m15[_4431] * float4(in.m_1691, 1.0)).w, 0.0);
                            float4 _4578 = _193._m15[_4431] * float4((in.m_1691 + (_2322 * (_4554 * _193._m25.x))) + (_4465 * (_4554 * _193._m25.y)), 1.0);
                            float _4580 = _4578.w;
                            if (_4580 <= 0.0)
                            {
                                _7798 = 1.0;
                                break;
                            }
                            float3 _4589 = _4578.xyz / float3(_4580);
                            float _4591 = _4589.x;
                            bool _4592 = _4591 < 0.0;
                            bool _4599;
                            if (!_4592)
                            {
                                _4599 = _4591 > 1.0;
                            }
                            else
                            {
                                _4599 = _4592;
                            }
                            bool _4606;
                            if (!_4599)
                            {
                                _4606 = _4589.y < 0.0;
                            }
                            else
                            {
                                _4606 = _4599;
                            }
                            bool _4613;
                            if (!_4606)
                            {
                                _4613 = _4589.y > 1.0;
                            }
                            else
                            {
                                _4613 = _4606;
                            }
                            bool _4620;
                            if (!_4613)
                            {
                                _4620 = _4589.z > 1.0;
                            }
                            else
                            {
                                _4620 = _4613;
                            }
                            if (_4620)
                            {
                                _7798 = 1.0;
                                break;
                            }
                            float _4626 = _4589.z;
                            float2 _4792 = _193._m22.xy * 0.5;
                            float2 _4797 = _193._m26[_4431].xy + (_4589.xy * _193._m23.zw);
                            float4 _4810 = float4(_193._m26[_4431].xy + _4792, (_193._m26[_4431].xy + _193._m23.zw) - _4792);
                            float _7797;
                            do
                            {
                                int _4836 = int(_193._m22.z);
                                if (_4836 <= 0)
                                {
                                    float2 _4846 = fast::clamp(_4797, _4810.xy, _4810.zw);
                                    _7797 = spvDepthCast(_213).sample_compare(_213Smplr, float3(_4846, _4626).xy, _4626);
                                    break;
                                }
                                float2 _4859 = (_4797 / _193._m22.xy) + float2(0.5);
                                float2 _4860 = floor(_4859);
                                float2 _4865 = _4859 - _4860;
                                float2 _4868 = _4860 - float2(0.5);
                                bool _4872 = _4836 == 1;
                                if (_4872)
                                {
                                    float2 _4875 = _4865 * 2.0;
                                    _4820[0] = float2(3.0) - _4875;
                                    _4820[1] = float2(1.0) + _4875;
                                    _4821[0] = ((float2(2.0) - _4865) / _4820[0]) - float2(1.0);
                                    _4821[1] = (_4865 / _4820[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _4902 = _4865 * 3.0;
                                    _4820[0] = float2(4.0) - _4902;
                                    _4820[1] = float2(7.0);
                                    _4820[2] = float2(1.0) + _4902;
                                    _4821[0] = ((float2(3.0) - (_4865 * 2.0)) / _4820[0]) - float2(2.0);
                                    _4821[1] = (float2(3.0) + _4865) / _4820[1];
                                    _4821[2] = (_4865 / _4820[2]) + float2(2.0);
                                }
                                int _7937 = _4872 ? 2 : 3;
                                int _7787;
                                float _7790;
                                _7790 = 0.0;
                                _7787 = 0;
                                float _7796;
                                for (; _7787 < _7937; _7790 = _7796, _7787++)
                                {
                                    _7796 = _7790;
                                    for (int _7793 = 0; _7793 < _7937; )
                                    {
                                        _7796 += ((_4820[_7793].x * _4820[_7787].y) * spvDepthCast(_213).sample_compare(_213Smplr, float3(fast::clamp(_193._m22.xy * (_4868 + float2(_4821[_7793].x, _4821[_7787].y)), _4810.xy, _4810.zw), _4626).xy, _4626));
                                        _7793++;
                                        continue;
                                    }
                                }
                                _7797 = _7790 * (_4872 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _7798 = _7797;
                            break;
                        }
                        uint _4636 = _4431 - _4532;
                        if (_4636 >= uint(_193._m21.w))
                        {
                            _7798 = 1.0;
                            break;
                        }
                        float _4657 = _193._m27[_4636].w * length(in.m_1691 - _193._m27[_4636].xyz);
                        float3 _4675 = ((in.m_1691 + (_2322 * (_4657 * _193._m25.x))) + (_4465 * (_4657 * _193._m25.y))) - _193._m27[_4636].xyz;
                        float3 _4677 = abs(_4675);
                        float _4679 = _4677.x;
                        float _4681 = _4677.y;
                        bool _4682 = _4679 >= _4681;
                        bool _4690;
                        if (_4682)
                        {
                            _4690 = _4679 >= _4677.z;
                        }
                        else
                        {
                            _4690 = _4682;
                        }
                        float _7772;
                        int _7774;
                        if (_4690)
                        {
                            _7774 = (_4675.x > 0.0) ? 0 : 1;
                            _7772 = _4679;
                        }
                        else
                        {
                            float _4702 = _4677.z;
                            bool _4703 = _4681 >= _4702;
                            int _7775;
                            if (_4703)
                            {
                                _7775 = (_4675.y > 0.0) ? 2 : 3;
                            }
                            else
                            {
                                _7775 = (_4675.z > 0.0) ? 4 : 5;
                            }
                            _7774 = _7775;
                            _7772 = _4703 ? _4681 : _4702;
                        }
                        if (_7772 <= 0.0)
                        {
                            _7798 = 1.0;
                            break;
                        }
                        float2 _4740 = float2(dot(_4675, _871[_7774]), dot(_4675, _880[_7774])) / float2(_7772 * _193._m24.z);
                        float _4747 = _193._m28[_4636].z + (_193._m28[_4636].w / _7772);
                        if (_4747 > 1.0)
                        {
                            _7798 = 1.0;
                            break;
                        }
                        float2 _4765 = _193._m28[_4636].xy + (float2(float(spvSMod(_7774, 3)), float(_7774 / 3)) * _193._m24.xy);
                        float2 _5005 = _193._m22.xy * 0.5;
                        float2 _5010 = _4765 + (float2(0.5 + (0.5 * _4740.x), 0.5 - (0.5 * _4740.y)) * _193._m24.xy);
                        float4 _5023 = float4(_4765 + _5005, (_4765 + _193._m24.xy) - _5005);
                        float _7786;
                        do
                        {
                            int _5049 = int(_193._m22.z);
                            if (_5049 <= 0)
                            {
                                _7786 = spvDepthCast(_213).sample_compare(_213Smplr, float3(fast::clamp(_5010, _5023.xy, _5023.zw), _4747).xy, _4747);
                                break;
                            }
                            float2 _5072 = (_5010 / _193._m22.xy) + float2(0.5);
                            float2 _5073 = floor(_5072);
                            float2 _5078 = _5072 - _5073;
                            float2 _5081 = _5073 - float2(0.5);
                            bool _5085 = _5049 == 1;
                            if (_5085)
                            {
                                float2 _5088 = _5078 * 2.0;
                                _5033[0] = float2(3.0) - _5088;
                                _5033[1] = float2(1.0) + _5088;
                                _5034[0] = ((float2(2.0) - _5078) / _5033[0]) - float2(1.0);
                                _5034[1] = (_5078 / _5033[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _5115 = _5078 * 3.0;
                                _5033[0] = float2(4.0) - _5115;
                                _5033[1] = float2(7.0);
                                _5033[2] = float2(1.0) + _5115;
                                _5034[0] = ((float2(3.0) - (_5078 * 2.0)) / _5033[0]) - float2(2.0);
                                _5034[1] = (float2(3.0) + _5078) / _5033[1];
                                _5034[2] = (_5078 / _5033[2]) + float2(2.0);
                            }
                            int _7940 = _5085 ? 2 : 3;
                            int _7776;
                            float _7779;
                            _7779 = 0.0;
                            _7776 = 0;
                            float _7785;
                            for (; _7776 < _7940; _7779 = _7785, _7776++)
                            {
                                _7785 = _7779;
                                for (int _7782 = 0; _7782 < _7940; )
                                {
                                    _7785 += ((_5033[_7782].x * _5033[_7776].y) * spvDepthCast(_213).sample_compare(_213Smplr, float3(fast::clamp(_193._m22.xy * (_5081 + float2(_5034[_7782].x, _5034[_7776].y)), _5023.xy, _5023.zw), _4747).xy, _4747));
                                    _7782++;
                                    continue;
                                }
                            }
                            _7786 = _7779 * (_5085 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _7798 = _7786;
                        break;
                    } while(false);
                    _7852 = _4496 * _7798;
                }
                else
                {
                    _7852 = _4496;
                }
                float _2494 = dot(_7442, _4465);
                _2523 = _7726 + (((_7436 * fast::max(_2494, 0.0)) * _7852) + (_7852 * ((powr(fast::max(dot(_7442, fast::normalize(_4465 + _2311)), 0.0), _1531._m1.w) * _1531._m1.z) * step(0.0, _2494))));
            }
            _7725 = _7726;
        }
        else
        {
            _7725 = _2443;
        }
        _7724 = _7725;
    }
    else
    {
        float4 _2533 = _2528.sample(_1230, _2074);
        float _2544 = fast::clamp((_1531._m4.x * _2533.z) * in.m_2540.y, 0.0, 1.0);
        float _2555 = fast::clamp((_1531._m4.y * _2533.y) * in.m_2540.x, 0.04500000178813934326171875, 1.0);
        float _7432;
        float _7437;
        if (_7373 > 0.0)
        {
            _7437 = mix(_2544, _7406.y, _7373);
            _7432 = mix(_2555, fast::max(_7406.x, 0.04500000178813934326171875), _7373);
        }
        else
        {
            _7437 = _2544;
            _7432 = _2555;
        }
        float _2574 = _7432 * _7432;
        float3 _2579 = _7436 * (1.0 - _7437);
        float3 _2585 = mix(float3(0.039999999105930328369140625), _7436, float3(_7437));
        bool _2589 = _7252 > 0.0;
        float3 _7465;
        if (_2589)
        {
            float3 _2594 = dfdx(in.m_1691);
            float3 _2596 = dfdy(in.m_1691);
            float3 _2597 = cross(_2594, _2596);
            float3 _7466;
            if (dot(_2597, _2597) > 9.9999996826552253889678874634872e-21)
            {
                _7466 = fast::normalize((fast::normalize(_2597) * ((dot(_2597, _2311) < 0.0) ? (-1.0) : 1.0)) + (_7442 - _2166));
            }
            else
            {
                _7466 = _7442;
            }
            _7465 = _7466;
        }
        else
        {
            _7465 = _7442;
        }
        float _2623 = fast::max(dot(_7465, _2311), 9.9999997473787516355514526367188e-05);
        float _2632 = dot(_7465, _2304);
        float _2633 = fast::clamp(_2632, 0.0, 1.0);
        float _2638 = fast::clamp(dot(_7465, _2316), 0.0, 1.0);
        float _2643 = fast::clamp(dot(_2311, _2316), 0.0, 1.0);
        float _7469;
        float _7470;
        if (_2589)
        {
            _7470 = fast::max(_2623, 0.5);
            _7469 = fast::max(_2643, 0.5);
        }
        else
        {
            _7470 = _2623;
            _7469 = _2643;
        }
        float3 _5217 = float3(1.0) - _2585;
        float3 _5220 = _2585 + (_5217 * powr(1.0 - _7469, 5.0));
        float _5227 = _2574 * _2574;
        float _5232 = _5227 - 1.0;
        float _5234 = ((_2638 * _2638) * _5232) + 1.0;
        float _5254 = 1.0 - _5227;
        float _5258 = sqrt(((_7470 * _7470) * _5254) + _5227);
        float3 _2689 = (((((float3(1.0) - _5220) * _2579) * fast::clamp(dot(_7442, _2304), 0.0, 1.0)) + (((_5220 * ((_5227 / ((3.1415927410125732421875 * _5234) * _5234)) * (0.5 / fast::max((_2633 * _5258) + (_7470 * sqrt(((_2633 * _2633) * _5254) + _5227)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875) * _2633)) * _2353) * _7476;
        float3 _7580;
        if (_2589)
        {
            _7580 = _2689 + (((((_2579 * _2353) * _7476) * _7252) * fast::clamp(-_2632, 0.0, 1.0)) * (0.3499999940395355224609375 + (0.64999997615814208984375 * powr(fast::clamp(dot(-_2311, _2304), 0.0, 1.0), 3.0))));
        }
        else
        {
            _7580 = _2689;
        }
        float3 _7506;
        float2 _7530;
        float3 _7542;
        if (_193._m29.x > 0.5)
        {
            float4 _5291 = _1334.sample(_1336, (((float2(_7470, _7432) * 31.0) + float2(0.5)) * float2(0.03125)));
            float _5350 = (_193._m29.z * _7442.x) - (_193._m29.w * _7442.z);
            float _5363 = (_193._m29.w * _7442.x) + (_193._m29.z * _7442.z);
            float _5381 = 1.09254801273345947265625 * _5350;
            spvUnsafeArray<float, 9> _7002 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _7442.y, 0.48860299587249755859375 * _5363, 0.48860299587249755859375 * _5350, _5381 * _7442.y, (1.09254801273345947265625 * _7442.y) * _5363, 0.3153919875621795654296875 * (((3.0 * _5363) * _5363) - 1.0), _5381 * _5363, 0.546274006366729736328125 * ((_5350 * _5350) - (_7442.y * _7442.y)) });
            spvUnsafeArray<float, 9> _5295 = _7002;
            float3 _7488;
            _7488 = float3(0.0);
            for (int _7487 = 0; _7487 < 9; )
            {
                _7488 += (_1228.read(uint2((int2(496, 256) + int2(_7487, 0))), 0).xyz * _5295[_7487]);
                _7487++;
                continue;
            }
            float3 _2741 = reflect(-_2311, _7465);
            float _5476 = _2741.x;
            float _5481 = _2741.z;
            float2 _5513 = float2((precise::atan2((_193._m29.z * _5476) - (_193._m29.w * _5481), -((_193._m29.w * _5476) + (_193._m29.z * _5481))) * 0.15915493667125701904296875) + 0.5, acos(fast::clamp(_2741.y, -1.0, 1.0)) * 0.3183098733425140380859375);
            float _5445 = _7432 * 5.0;
            int _5448 = min(int(_5445), 4);
            float2 _5534 = (_5513 * float2(_1290[_5448].zw)) - float2(0.5);
            float2 _5536 = floor(_5534);
            float2 _5539 = _5534 - _5536;
            int _5542 = int(_5536.x);
            int _5545 = int(_5536.y);
            int _7491;
            if (_5542 < 0)
            {
                _7491 = _5542 + _1290[_5448].z;
            }
            else
            {
                _7491 = _5542;
            }
            int _7492;
            if (_7491 >= _1290[_5448].z)
            {
                _7492 = _7491 - _1290[_5448].z;
            }
            else
            {
                _7492 = _7491;
            }
            int _5565 = _7492 + 1;
            int _7941 = (_5565 == _1290[_5448].z) ? 0 : _5565;
            int _5580 = min((_5545 + 1), (_1290[_5448].w - 1));
            int _5582 = max(_5545, 0);
            float3 _5635 = float3(_5539.x);
            int _5455 = _5448 + 1;
            float2 _5667 = (_5513 * float2(_1290[_5455].zw)) - float2(0.5);
            float2 _5669 = floor(_5667);
            float2 _5672 = _5667 - _5669;
            int _5675 = int(_5669.x);
            int _5678 = int(_5669.y);
            int _7498;
            if (_5675 < 0)
            {
                _7498 = _5675 + _1290[_5455].z;
            }
            else
            {
                _7498 = _5675;
            }
            int _7499;
            if (_7498 >= _1290[_5455].z)
            {
                _7499 = _7498 - _1290[_5455].z;
            }
            else
            {
                _7499 = _7498;
            }
            int _5698 = _7499 + 1;
            int _7942 = (_5698 == _1290[_5455].z) ? 0 : _5698;
            int _5713 = min((_5678 + 1), (_1290[_5455].w - 1));
            int _5715 = max(_5678, 0);
            float3 _5768 = float3(_5672.x);
            float3 _5470 = mix(mix(mix(_1228.read(uint2((_1290[_5448].xy + int2(_7492, _5582))), 0).xyz, _1228.read(uint2((_1290[_5448].xy + int2(_7941, _5582))), 0).xyz, _5635), mix(_1228.read(uint2((_1290[_5448].xy + int2(_7492, _5580))), 0).xyz, _1228.read(uint2((_1290[_5448].xy + int2(_7941, _5580))), 0).xyz, _5635), float3(_5539.y)), mix(mix(_1228.read(uint2((_1290[_5455].xy + int2(_7499, _5715))), 0).xyz, _1228.read(uint2((_1290[_5455].xy + int2(_7942, _5715))), 0).xyz, _5768), mix(_1228.read(uint2((_1290[_5455].xy + int2(_7499, _5713))), 0).xyz, _1228.read(uint2((_1290[_5455].xy + int2(_7942, _5713))), 0).xyz, _5768), float3(_5672.y)), float3(_5445 - float(_5448))) * _193._m29.y;
            _7542 = fast::max(_7488, float3(0.0)) * _193._m29.y;
            _7530 = _5291.xy;
            _7506 = _5470;
        }
        else
        {
            float4 _5786 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * _7432) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);
            float _5788 = _5786.x;
            float3 _5823 = mix(_193._m9.xyz, _193._m8.xyz, float3((_7442.y * 0.5) + 0.5)) * _193._m8.w;
            _7542 = _5823;
            _7530 = (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_5788 * _5788, exp2((-9.27999973297119140625) * _7470)) * _5788) + _5786.y)) + _5786.zw;
            _7506 = mix(mix(_193._m9.xyz, _193._m8.xyz, float3((reflect(-_2311, _7465).y * 0.5) + 0.5)) * _193._m8.w, _5823, float3(_7432));
        }
        bool _2773;
        if (_2357)
        {
            _2773 = _193._m33.z > 0.5;
        }
        else
        {
            _2773 = _2357;
        }
        float3 _7551;
        if (_2773)
        {
            float3 _7527;
            do
            {
                float _5902 = ((_193._m32.x * (1.0 - smoothstep(_193._m33.x * 0.5, _193._m33.x, abs(dot(_193._m31.xyz, in.m_1691) - _193._m31.w)))) * smoothstep(0.5, 0.89999997615814208984375, dot(_2322, _193._m31.xyz))) * (1.0 - smoothstep(_193._m32.y * 0.5, _193._m32.y, _7432));
                if (_5902 <= 0.0)
                {
                    _7527 = _7506;
                    break;
                }
                float4 _5927 = _193._m30 * float4(in.m_1691 + ((_7442 - (_193._m31.xyz * dot(_7442, _193._m31.xyz))) * _193._m32.w), 1.0);
                float2 _5940 = ((float2(_5927.x, -_5927.y) / float2(_5927.w)) * 0.5) + float2(0.5);
                float _5944 = _193._m32.z * _7432;
                float3 _7525;
                float _7526;
                _7526 = 0.0;
                _7525 = float3(0.0);
                for (int _7524 = 0; _7524 < 12; )
                {
                    float _5951 = float(_7524);
                    float _5959 = _5951 * 2.3999631404876708984375;
                    float2 _5971 = _5940 + (float2(cos(_5959) * _193._m33.y, sin(_5959)) * (sqrt((_5951 + 0.5) * 0.083333335816860198974609375) * _5944));
                    float2 _5976 = fast::min(_5971, float2(1.0) - _5971);
                    float _5982 = smoothstep(0.0, 0.039999999105930328369140625, fast::min(_5976.x, _5976.y));
                    float4 _5990 = _2007.sample(_1230, fast::clamp(_5971, float2(0.0), float2(1.0)), level(0.0));
                    float3 _5992 = _5990.xyz;
                    _7526 += (_5990.w * _5982);
                    _7525 += ((_5992 / (float3(1.0) - fast::min(_5992, float3(0.99500000476837158203125)))) * _5982);
                    _7524++;
                    continue;
                }
                _7527 = mix(_7506, (_7525 * float3(0.083333335816860198974609375)) + (_7506 * (1.0 - (_7526 * 0.083333335816860198974609375))), float3(_5902));
                break;
            } while(false);
            _7551 = _7527;
        }
        else
        {
            _7551 = _7506;
        }
        float3 _2793 = (_2585 * _7530.x) + float3(_7530.y);
        float3 _2809 = _7580 + (((((float3(1.0) - _2793) * _2579) * _7542) + (_2793 * _7551)) * _7566);
        float3 _7727;
        if (_193._m13.w > 0.5)
        {
            float2 _6056 = fast::clamp(floor(gl_FragCoord.xy * _193._m12.xy), float2(0.0), _193._m13.xy - float2(1.0));
            uint _6084 = uint((((fast::clamp(floor((log2(fast::max(dot(_193._m11.xyz, in.m_1691) + _193._m11.w, 9.9999999747524270787835121154785e-07)) * _193._m12.z) + _193._m12.w), 0.0, _193._m13.z - 1.0) * _193._m13.y) + _6056.y) * _193._m13.x) + _6056.x);
            uint _6086 = _6084 >> uint(2);
            uint _6088 = _6084 & 3u;
            uint _6092 = _1822._m0[_6086][_6088] & 65535u;
            uint _6094 = _1822._m0[_6086][_6088] >> uint(16);
            float3 _7680;
            _7680 = _2809;
            float3 _2909;
            spvUnsafeArray<float2, 3> _6502;
            spvUnsafeArray<float2, 3> _6503;
            spvUnsafeArray<float2, 3> _6715;
            spvUnsafeArray<float2, 3> _6716;
            for (uint _7583 = _6092; _7583 < (_6092 + _6094); _7680 = _2909, _7583++)
            {
                uint _6100 = _7583 / 3u;
                uint _6113 = (_1843._m0[_6100 >> uint(2)][_6100 & 3u] >> ((_7583 - (_6100 * 3u)) * 10u)) & 1023u;
                float3 _6130 = _1684._m0[_6113].xyz - in.m_1691;
                float _6133 = dot(_6130, _6130);
                float _6137 = _6133 * _1684._m0[_6113].w;
                float _6142 = fast::clamp(1.0 - (_6137 * _6137), 0.0, 1.0);
                float3 _6147 = _6130 * rsqrt(fast::max(_6133, 9.9999999392252902907785028219223e-09));
                float _6165 = fast::clamp((dot(-_6147, _1727._m0[_6113].xyz) * _1719._m0[_6113].w) + _1727._m0[_6113].w, 0.0, 1.0);
                float3 _6178 = _1719._m0[_6113].xyz * ((((_6142 * _6142) * _6165) * _6165) / fast::max(_6133, 9.9999997473787516355514526367188e-05));
                float3 _7678;
                if (_2327)
                {
                    float _7610;
                    do
                    {
                        uint _6214 = uint(_193._m21.z);
                        if (_6113 < _6214)
                        {
                            float _6236 = _193._m26[_6113].z * fast::max((_193._m15[_6113] * float4(in.m_1691, 1.0)).w, 0.0);
                            float4 _6260 = _193._m15[_6113] * float4((in.m_1691 + (_2322 * (_6236 * _193._m25.x))) + (_6147 * (_6236 * _193._m25.y)), 1.0);
                            float _6262 = _6260.w;
                            if (_6262 <= 0.0)
                            {
                                _7610 = 1.0;
                                break;
                            }
                            float3 _6271 = _6260.xyz / float3(_6262);
                            float _6273 = _6271.x;
                            bool _6274 = _6273 < 0.0;
                            bool _6281;
                            if (!_6274)
                            {
                                _6281 = _6273 > 1.0;
                            }
                            else
                            {
                                _6281 = _6274;
                            }
                            bool _6288;
                            if (!_6281)
                            {
                                _6288 = _6271.y < 0.0;
                            }
                            else
                            {
                                _6288 = _6281;
                            }
                            bool _6295;
                            if (!_6288)
                            {
                                _6295 = _6271.y > 1.0;
                            }
                            else
                            {
                                _6295 = _6288;
                            }
                            bool _6302;
                            if (!_6295)
                            {
                                _6302 = _6271.z > 1.0;
                            }
                            else
                            {
                                _6302 = _6295;
                            }
                            if (_6302)
                            {
                                _7610 = 1.0;
                                break;
                            }
                            float _6308 = _6271.z;
                            float2 _6474 = _193._m22.xy * 0.5;
                            float2 _6479 = _193._m26[_6113].xy + (_6271.xy * _193._m23.zw);
                            float4 _6492 = float4(_193._m26[_6113].xy + _6474, (_193._m26[_6113].xy + _193._m23.zw) - _6474);
                            float _7609;
                            do
                            {
                                int _6518 = int(_193._m22.z);
                                if (_6518 <= 0)
                                {
                                    float2 _6528 = fast::clamp(_6479, _6492.xy, _6492.zw);
                                    _7609 = spvDepthCast(_213).sample_compare(_213Smplr, float3(_6528, _6308).xy, _6308);
                                    break;
                                }
                                float2 _6541 = (_6479 / _193._m22.xy) + float2(0.5);
                                float2 _6542 = floor(_6541);
                                float2 _6547 = _6541 - _6542;
                                float2 _6550 = _6542 - float2(0.5);
                                bool _6554 = _6518 == 1;
                                if (_6554)
                                {
                                    float2 _6557 = _6547 * 2.0;
                                    _6502[0] = float2(3.0) - _6557;
                                    _6502[1] = float2(1.0) + _6557;
                                    _6503[0] = ((float2(2.0) - _6547) / _6502[0]) - float2(1.0);
                                    _6503[1] = (_6547 / _6502[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _6584 = _6547 * 3.0;
                                    _6502[0] = float2(4.0) - _6584;
                                    _6502[1] = float2(7.0);
                                    _6502[2] = float2(1.0) + _6584;
                                    _6503[0] = ((float2(3.0) - (_6547 * 2.0)) / _6502[0]) - float2(2.0);
                                    _6503[1] = (float2(3.0) + _6547) / _6502[1];
                                    _6503[2] = (_6547 / _6502[2]) + float2(2.0);
                                }
                                int _7944 = _6554 ? 2 : 3;
                                int _7599;
                                float _7602;
                                _7602 = 0.0;
                                _7599 = 0;
                                float _7608;
                                for (; _7599 < _7944; _7602 = _7608, _7599++)
                                {
                                    _7608 = _7602;
                                    for (int _7605 = 0; _7605 < _7944; )
                                    {
                                        _7608 += ((_6502[_7605].x * _6502[_7599].y) * spvDepthCast(_213).sample_compare(_213Smplr, float3(fast::clamp(_193._m22.xy * (_6550 + float2(_6503[_7605].x, _6503[_7599].y)), _6492.xy, _6492.zw), _6308).xy, _6308));
                                        _7605++;
                                        continue;
                                    }
                                }
                                _7609 = _7602 * (_6554 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _7610 = _7609;
                            break;
                        }
                        uint _6318 = _6113 - _6214;
                        if (_6318 >= uint(_193._m21.w))
                        {
                            _7610 = 1.0;
                            break;
                        }
                        float _6339 = _193._m27[_6318].w * length(in.m_1691 - _193._m27[_6318].xyz);
                        float3 _6357 = ((in.m_1691 + (_2322 * (_6339 * _193._m25.x))) + (_6147 * (_6339 * _193._m25.y))) - _193._m27[_6318].xyz;
                        float3 _6359 = abs(_6357);
                        float _6361 = _6359.x;
                        float _6363 = _6359.y;
                        bool _6364 = _6361 >= _6363;
                        bool _6372;
                        if (_6364)
                        {
                            _6372 = _6361 >= _6359.z;
                        }
                        else
                        {
                            _6372 = _6364;
                        }
                        float _7584;
                        int _7586;
                        if (_6372)
                        {
                            _7586 = (_6357.x > 0.0) ? 0 : 1;
                            _7584 = _6361;
                        }
                        else
                        {
                            float _6384 = _6359.z;
                            bool _6385 = _6363 >= _6384;
                            int _7587;
                            if (_6385)
                            {
                                _7587 = (_6357.y > 0.0) ? 2 : 3;
                            }
                            else
                            {
                                _7587 = (_6357.z > 0.0) ? 4 : 5;
                            }
                            _7586 = _7587;
                            _7584 = _6385 ? _6363 : _6384;
                        }
                        if (_7584 <= 0.0)
                        {
                            _7610 = 1.0;
                            break;
                        }
                        float2 _6422 = float2(dot(_6357, _871[_7586]), dot(_6357, _880[_7586])) / float2(_7584 * _193._m24.z);
                        float _6429 = _193._m28[_6318].z + (_193._m28[_6318].w / _7584);
                        if (_6429 > 1.0)
                        {
                            _7610 = 1.0;
                            break;
                        }
                        float2 _6447 = _193._m28[_6318].xy + (float2(float(spvSMod(_7586, 3)), float(_7586 / 3)) * _193._m24.xy);
                        float2 _6687 = _193._m22.xy * 0.5;
                        float2 _6692 = _6447 + (float2(0.5 + (0.5 * _6422.x), 0.5 - (0.5 * _6422.y)) * _193._m24.xy);
                        float4 _6705 = float4(_6447 + _6687, (_6447 + _193._m24.xy) - _6687);
                        float _7598;
                        do
                        {
                            int _6731 = int(_193._m22.z);
                            if (_6731 <= 0)
                            {
                                _7598 = spvDepthCast(_213).sample_compare(_213Smplr, float3(fast::clamp(_6692, _6705.xy, _6705.zw), _6429).xy, _6429);
                                break;
                            }
                            float2 _6754 = (_6692 / _193._m22.xy) + float2(0.5);
                            float2 _6755 = floor(_6754);
                            float2 _6760 = _6754 - _6755;
                            float2 _6763 = _6755 - float2(0.5);
                            bool _6767 = _6731 == 1;
                            if (_6767)
                            {
                                float2 _6770 = _6760 * 2.0;
                                _6715[0] = float2(3.0) - _6770;
                                _6715[1] = float2(1.0) + _6770;
                                _6716[0] = ((float2(2.0) - _6760) / _6715[0]) - float2(1.0);
                                _6716[1] = (_6760 / _6715[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _6797 = _6760 * 3.0;
                                _6715[0] = float2(4.0) - _6797;
                                _6715[1] = float2(7.0);
                                _6715[2] = float2(1.0) + _6797;
                                _6716[0] = ((float2(3.0) - (_6760 * 2.0)) / _6715[0]) - float2(2.0);
                                _6716[1] = (float2(3.0) + _6760) / _6715[1];
                                _6716[2] = (_6760 / _6715[2]) + float2(2.0);
                            }
                            int _7947 = _6767 ? 2 : 3;
                            int _7588;
                            float _7591;
                            _7591 = 0.0;
                            _7588 = 0;
                            float _7597;
                            for (; _7588 < _7947; _7591 = _7597, _7588++)
                            {
                                _7597 = _7591;
                                for (int _7594 = 0; _7594 < _7947; )
                                {
                                    _7597 += ((_6715[_7594].x * _6715[_7588].y) * spvDepthCast(_213).sample_compare(_213Smplr, float3(fast::clamp(_193._m22.xy * (_6763 + float2(_6716[_7594].x, _6716[_7588].y)), _6705.xy, _6705.zw), _6429).xy, _6429));
                                    _7594++;
                                    continue;
                                }
                            }
                            _7598 = _7591 * (_6767 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _7610 = _7598;
                        break;
                    } while(false);
                    _7678 = _6178 * _7610;
                }
                else
                {
                    _7678 = _6178;
                }
                float3 _2861 = fast::normalize(_6147 + _2311);
                float _2866 = fast::clamp(dot(_7442, _6147), 0.0, 1.0);
                float _2871 = fast::clamp(dot(_7442, _2861), 0.0, 1.0);
                float3 _6902 = _2585 + (_5217 * powr(1.0 - fast::clamp(dot(_2311, _2861), 0.0, 1.0), 5.0));
                float _6916 = ((_2871 * _2871) * _5232) + 1.0;
                _2909 = _7680 + (((((float3(1.0) - _6902) * _2579) + ((_6902 * ((_5227 / ((3.1415927410125732421875 * _6916) * _6916)) * (0.5 / fast::max((_2866 * _5258) + (_7470 * sqrt(((_2866 * _2866) * _5254) + _5227)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875)) * _2866) * _7678);
            }
            _7727 = _7680;
        }
        else
        {
            _7727 = _2809;
        }
        _7724 = _7727;
    }
    float4 _2926 = _2921.sample(_1230, _2074);
    float _2947 = -length(_2310);
    float _7769;
    if (_193._m9.w != 0.0)
    {
        float _2971 = _193._m9.w * (in.m_1691 - _193._m6.xyz).y;
        float _7766;
        if (abs(_2971) < 9.9999997473787516355514526367188e-05)
        {
            _7766 = 1.0 - (0.5 * _2971);
        }
        else
        {
            _7766 = (1.0 - exp(fast::min(-_2971, 60.0))) / _2971;
        }
        _7769 = 1.0 - exp((_2947 * (_193._m7.w * exp(fast::min((-_193._m9.w) * (_193._m6.y - _193._m6.w), 30.0)))) * _7766);
    }
    else
    {
        _7769 = 1.0 - exp(_2947 * _193._m7.w);
    }
    float3 _3022 = mix(mix(_7724, _7436, float3(_1531._m1.y)) + (((_1531._m5.xyz * _2926.xyz) * (float3(1.0) + in.m_2324.yzw)) * in.m_2540.z), _193._m7.xyz, float3(_7769));
    float3 _7770;
    if (_193._m33.w > 0.5)
    {
        _7770 = _3022 / (float3(1.0) + _3022);
    }
    else
    {
        _7770 = _3022;
    }
    out.m_3034 = float4(_7770, ((in.m_2083.w * _1531._m0.w) * _2081.w) * in.m_2103.w);
    float2 _7771;
    do
    {
        if (in.m_3044.w <= 0.0)
        {
            _7771 = float2(0.0);
            break;
        }
        _7771 = ((in.m_3044.xy / float2(in.m_3044.w)) - (in.m_3043.xy / float2(in.m_3043.w))) * float2(0.5, -0.5);
        break;
    } while(false);
    out.m_3042 = _7771;
    return out;
}

