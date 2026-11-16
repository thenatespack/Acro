// Generated from mesh_mask.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 7aab3548bb9611a7
// glsl-fnv1a64: 4f56061c7a0a3fa1

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
    float4 m_2935 [[color(0)]];
    float2 m_2943 [[color(1)]];
};

struct fragment_main_in
{
    float3 m_1691 [[user(locn0)]];
    float3 m_1601 [[user(locn1)]];
    float2 m_2060 [[user(locn2)]];
    float4 m_2083 [[user(locn3)]];
    float4 m_2315 [[user(locn5)]];
    float4 m_2944 [[user(locn6)]];
    float4 m_2945 [[user(locn7)]];
    float4 m_1607 [[user(locn8)]];
};

fragment fragment_main_out fragment_main(fragment_main_in in [[stage_in]], constant _1529& _1531 [[buffer(2)]], constant _1682& _1684 [[buffer(3)]], constant _1717& _1719 [[buffer(4)]], constant _1725& _1727 [[buffer(5)]], constant _1820& _1822 [[buffer(6)]], constant _1841& _1843 [[buffer(7)]], constant _191& _193 [[buffer(15)]], texture2d<float> _213 [[texture(0)]], texture2d<float> _2076 [[texture(1)]], texture2d<float> _2519 [[texture(2)]], texture2d<float> _2205 [[texture(3)]], texture2d<float> _2007 [[texture(4)]], texture2d<float> _2825 [[texture(5)]], texture2d<float> _1228 [[texture(6)]], texture2d<float> _1334 [[texture(7)]], sampler _213Smplr [[sampler(0)]], sampler _1230 [[sampler(1)]], sampler _1336 [[sampler(7)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])
{
    fragment_main_out out = {};
    float2 _2074 = float2(dot(_1531._m2.xy, in.m_2060) + _1531._m2.z, dot(_1531._m3.xy, in.m_2060) + _1531._m3.z);
    float4 _2081 = _2076.sample(_1230, _2074);
    float3 _2091 = _2081.xyz;
    float3 _2092 = (in.m_2083.xyz * _1531._m0.xyz) * _2091;
    if ((_1531._m0.w * _2081.w) < _1531._m6.x)
    {
        discard_fragment();
    }
    float3 _7147;
    if (_1531._m1.x > 0.5)
    {
        float2 _2126 = floor(in.m_1691.xz * float2(0.5));
        _7147 = _2092 * ((mod(abs(_2126.x + _2126.y), 2.0) < 0.5) ? 1.0 : 0.75);
    }
    else
    {
        _7147 = _2092;
    }
    float3 _7241;
    float _7271;
    float2 _7303;
    if (_1531._m3.w > 0.5)
    {
        float3 _3046;
        float2 _3053;
        float _7145;
        do
        {
            float3 _3017 = float4(_1531._m2.w, _1531._m3.w, 0.0, 0.0).xyy;
            float3 _3020 = floor(_3017 * float3(1.52587890625e-05));
            float3 _3025 = _3017 - (_3020 * 65536.0);
            float3 _3028 = floor(_3025 * float3(0.00390625));
            float3 _3036 = _3025 - (_3028 * 256.0);
            _3046 = (float3(_3036.x, _3028.x, _3020.x) * float3(0.0039215688593685626983642578125)) * 2.0;
            _3053 = float2(_3036.y, _3028.y) * float2(0.0039215688593685626983642578125);
            float _3056 = _3020.y - 128.0;
            float _3062 = floor(_3056 * 0.03125) * 0.3333333432674407958984375;
            float3 _3068 = fast::normalize(in.m_1601);
            float _3072 = dot(_3068, in.m_1607.xyz);
            float _3084 = (_3072 / fast::max(length(in.m_1607.xyz - (_3068 * _3072)), 9.9999999747524270787835121154785e-07)) * 25.5;
            if (((-24.0) + _3084) < (-2.0))
            {
                _7145 = 0.0;
                break;
            }
            float2 _3092 = _2074 * (4.0 * exp2(mod(_3056, 32.0) * 0.3333333432674407958984375));
            float2 _3129 = floor(_3092);
            float2 _3132 = _3092 - _3129;
            float2 _3140 = (_3132 * _3132) * (float2(3.0) - (_3132 * 2.0));
            uint2 _3168 = uint2(int2(_3129) + int2(65536));
            uint _3177 = ((_3168.x * 1597334677u) ^ (_3168.y * 3812015801u)) * 1597334677u;
            uint2 _3193 = uint2(int2(_3129 + float2(1.0, 0.0)) + int2(65536));
            uint _3202 = ((_3193.x * 1597334677u) ^ (_3193.y * 3812015801u)) * 1597334677u;
            float _3147 = _3140.x;
            uint2 _3218 = uint2(int2(_3129 + float2(0.0, 1.0)) + int2(65536));
            uint _3227 = ((_3218.x * 1597334677u) ^ (_3218.y * 3812015801u)) * 1597334677u;
            uint2 _3243 = uint2(int2(_3129 + float2(1.0)) + int2(65536));
            uint _3252 = ((_3243.x * 1597334677u) ^ (_3243.y * 3812015801u)) * 1597334677u;
            float2 _3098 = (_3092 * 2.7000000476837158203125) + float2(17.299999237060546875, 5.099999904632568359375);
            float2 _3271 = floor(_3098);
            float2 _3274 = _3098 - _3271;
            float2 _3282 = (_3274 * _3274) * (float2(3.0) - (_3274 * 2.0));
            uint2 _3310 = uint2(int2(_3271) + int2(65536));
            uint _3319 = ((_3310.x * 1597334677u) ^ (_3310.y * 3812015801u)) * 1597334677u;
            uint2 _3335 = uint2(int2(_3271 + float2(1.0, 0.0)) + int2(65536));
            uint _3344 = ((_3335.x * 1597334677u) ^ (_3335.y * 3812015801u)) * 1597334677u;
            float _3289 = _3282.x;
            uint2 _3360 = uint2(int2(_3271 + float2(0.0, 1.0)) + int2(65536));
            uint _3369 = ((_3360.x * 1597334677u) ^ (_3360.y * 3812015801u)) * 1597334677u;
            uint2 _3385 = uint2(int2(_3271 + float2(1.0)) + int2(65536));
            uint _3394 = ((_3385.x * 1597334677u) ^ (_3385.y * 3812015801u)) * 1597334677u;
            float _3103 = mix(0.449999988079071044921875, 0.0500000007450580596923828125, _3062);
            float _3111 = (_3084 + (-24.450000762939453125)) + ((((mix(mix(float((_3177 ^ (_3177 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_3202 ^ (_3202 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _3147), mix(float((_3227 ^ (_3227 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_3252 ^ (_3252 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _3147), _3140.y) * 0.64999997615814208984375) + (mix(mix(float((_3319 ^ (_3319 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_3344 ^ (_3344 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _3289), mix(float((_3369 ^ (_3369 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_3394 ^ (_3394 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _3289), _3282.y) * 0.3499999940395355224609375)) - 0.5) * mix(0.800000011920928955078125, 2.2000000476837158203125, _3062));
            _7145 = smoothstep(-_3103, _3103, _3111);
            break;
        } while(false);
        _7303 = _3053;
        _7271 = _7145;
        _7241 = mix(_7147, (in.m_2083.xyz * _3046) * mix(float3(1.0), _2091 * 2.0, float3(0.5)), float3(_7145));
    }
    else
    {
        _7303 = float2(0.0);
        _7271 = 0.0;
        _7241 = _7147;
    }
    float3 _2170 = fast::normalize(in.m_1601);
    float3 _7155;
    if (_1531._m6.y > 0.5)
    {
        float3 _2185 = in.m_1607.xyz - (_2170 * dot(_2170, in.m_1607.xyz));
        float3 _7156;
        if (dot(_2185, _2185) > 9.9999999600419720025001879548654e-13)
        {
            float3 _2194 = fast::normalize(_2185);
            float4 _2210 = _2205.sample(_1230, _2074);
            float3 _7149;
            if (_1531._m6.z > 0.5)
            {
                float2 _7148;
                if (_1531._m6.z > 1.5)
                {
                    _7148 = _2210.xw;
                }
                else
                {
                    _7148 = _2210.xy;
                }
                float2 _2232 = (_7148 * 2.0) - float2(1.0);
                _7149 = float3(_2232, sqrt(fast::clamp(1.0 - dot(_2232, _2232), 0.0, 1.0)));
            }
            else
            {
                _7149 = (_2210.xyz * 2.0) - float3(1.0);
            }
            float2 _2254 = _7149.xy * _1531._m4.z;
            _7156 = fast::normalize(((_2194 * _2254.x) + ((cross(_2170, _2194) * ((in.m_1607.w < 0.0) ? (-1.0) : 1.0)) * _2254.y)) + (_2170 * _7149.z));
        }
        else
        {
            _7156 = _2170;
        }
        _7155 = _7156;
    }
    else
    {
        _7155 = _2170;
    }
    bool _2278 = _1531._m5.w > 0.5;
    bool _2286;
    if (_2278)
    {
        _2286 = !gl_FrontFacing;
    }
    else
    {
        _2286 = _2278;
    }
    float3 _7339;
    if (_2286)
    {
        _7339 = -_7155;
    }
    else
    {
        _7339 = _7155;
    }
    float3 _2295 = fast::normalize(_193._m4.xyz);
    float3 _2301 = _193._m6.xyz - in.m_1691;
    float3 _2302 = fast::normalize(_2301);
    float3 _2307 = fast::normalize(_2295 + _2302);
    float3 _2313 = _2170 * (gl_FrontFacing ? 1.0 : (-1.0));
    bool _2318 = in.m_2315.x > 0.5;
    float3 _7333;
    float _7365;
    if ((_193._m5.w > 0.5) && _2318)
    {
        float _7212;
        float3 _7213;
        do
        {
            int _3423 = int(_193._m21.x);
            float _3431 = dot(_193._m20.xyz, in.m_1691) + _193._m20.w;
            int _7157;
            _7157 = 0;
            for (;;)
            {
                bool _3437 = _7157 < (_3423 - 1);
                bool _3445;
                if (_3437)
                {
                    _3445 = _3431 > _193._m16[_7157];
                }
                else
                {
                    _3445 = _3437;
                }
                if (_3445)
                {
                    _7157++;
                    continue;
                }
                else
                {
                    break;
                }
            }
            if (_3431 > _193._m16[_7157])
            {
                _7213 = float3(1.0);
                _7212 = 1.0;
                break;
            }
            float _7170;
            do
            {
                float4 _3547 = _193._m14[_7157] * float4(in.m_1691 + (_2313 * _193._m18[_7157]), 1.0);
                float _3550 = _3547.x;
                bool _3551 = _3550 < 0.0;
                bool _3558;
                if (!_3551)
                {
                    _3558 = _3550 > 1.0;
                }
                else
                {
                    _3558 = _3551;
                }
                bool _3565;
                if (!_3558)
                {
                    _3565 = _3547.y < 0.0;
                }
                else
                {
                    _3565 = _3558;
                }
                bool _3572;
                if (!_3565)
                {
                    _3572 = _3547.y > 1.0;
                }
                else
                {
                    _3572 = _3565;
                }
                if (_3572)
                {
                    _7170 = 1.0;
                    break;
                }
                float2 _3585 = float2(float(_7157 & 1), float(_7157 >> 1)) * _193._m23.xy;
                float _3592 = fast::min(_3547.z, 1.0) - _193._m19[_7157];
                float2 _3611 = _193._m22.xy * 0.5;
                float2 _3616 = _3585 + (_3547.xy * _193._m23.xy);
                float4 _3629 = float4(_3585 + _3611, (_3585 + _193._m23.xy) - _3611);
                float _7169;
                do
                {
                    int _3655 = int(_193._m22.z);
                    if (_3655 <= 0)
                    {
                        _7169 = spvDepthCast(_213).sample_compare(_213Smplr, float3(fast::clamp(_3616, _3629.xy, _3629.zw), _3592).xy, _3592);
                        break;
                    }
                    float2 _3678 = (_3616 / _193._m22.xy) + float2(0.5);
                    float2 _3679 = floor(_3678);
                    float2 _3684 = _3678 - _3679;
                    float2 _3687 = _3679 - float2(0.5);
                    bool _3691 = _3655 == 1;
                    spvUnsafeArray<float2, 3> _3639;
                    spvUnsafeArray<float2, 3> _3640;
                    if (_3691)
                    {
                        float2 _3694 = _3684 * 2.0;
                        _3639[0] = float2(3.0) - _3694;
                        _3639[1] = float2(1.0) + _3694;
                        _3640[0] = ((float2(2.0) - _3684) / _3639[0]) - float2(1.0);
                        _3640[1] = (_3684 / _3639[1]) + float2(1.0);
                    }
                    else
                    {
                        float2 _3721 = _3684 * 3.0;
                        _3639[0] = float2(4.0) - _3721;
                        _3639[1] = float2(7.0);
                        _3639[2] = float2(1.0) + _3721;
                        _3640[0] = ((float2(3.0) - (_3684 * 2.0)) / _3639[0]) - float2(2.0);
                        _3640[1] = (float2(3.0) + _3684) / _3639[1];
                        _3640[2] = (_3684 / _3639[2]) + float2(2.0);
                    }
                    int _7848 = _3691 ? 2 : 3;
                    int _7159;
                    float _7162;
                    _7162 = 0.0;
                    _7159 = 0;
                    float _7168;
                    for (; _7159 < _7848; _7162 = _7168, _7159++)
                    {
                        _7168 = _7162;
                        for (int _7165 = 0; _7165 < _7848; )
                        {
                            _7168 += ((_3639[_7165].x * _3639[_7159].y) * spvDepthCast(_213).sample_compare(_213Smplr, float3(fast::clamp(_193._m22.xy * (_3687 + float2(_3640[_7165].x, _3640[_7159].y)), _3629.xy, _3629.zw), _3592).xy, _3592));
                            _7165++;
                            continue;
                        }
                    }
                    _7169 = _7162 * (_3691 ? 0.0625 : 0.0069444444961845874786376953125);
                    break;
                } while(false);
                _7170 = _7169;
                break;
            } while(false);
            float3 _7207;
            float _7210;
            if (_3431 > _193._m17[_7157])
            {
                float _3485 = (_3431 - _193._m17[_7157]) / (_193._m16[_7157] - _193._m17[_7157]);
                int _3487 = _7157 + 1;
                float3 _7208;
                float _7211;
                if (_3487 < _3423)
                {
                    float _7190;
                    do
                    {
                        float4 _3834 = _193._m14[_3487] * float4(in.m_1691 + (_2313 * _193._m18[_3487]), 1.0);
                        float _3837 = _3834.x;
                        bool _3838 = _3837 < 0.0;
                        bool _3845;
                        if (!_3838)
                        {
                            _3845 = _3837 > 1.0;
                        }
                        else
                        {
                            _3845 = _3838;
                        }
                        bool _3852;
                        if (!_3845)
                        {
                            _3852 = _3834.y < 0.0;
                        }
                        else
                        {
                            _3852 = _3845;
                        }
                        bool _3859;
                        if (!_3852)
                        {
                            _3859 = _3834.y > 1.0;
                        }
                        else
                        {
                            _3859 = _3852;
                        }
                        if (_3859)
                        {
                            _7190 = 1.0;
                            break;
                        }
                        float2 _3872 = float2(float(_3487 & 1), float(_3487 >> 1)) * _193._m23.xy;
                        float _3879 = fast::min(_3834.z, 1.0) - _193._m19[_3487];
                        float2 _3898 = _193._m22.xy * 0.5;
                        float2 _3903 = _3872 + (_3834.xy * _193._m23.xy);
                        float4 _3916 = float4(_3872 + _3898, (_3872 + _193._m23.xy) - _3898);
                        float _7189;
                        do
                        {
                            int _3942 = int(_193._m22.z);
                            if (_3942 <= 0)
                            {
                                _7189 = spvDepthCast(_213).sample_compare(_213Smplr, float3(fast::clamp(_3903, _3916.xy, _3916.zw), _3879).xy, _3879);
                                break;
                            }
                            float2 _3965 = (_3903 / _193._m22.xy) + float2(0.5);
                            float2 _3966 = floor(_3965);
                            float2 _3971 = _3965 - _3966;
                            float2 _3974 = _3966 - float2(0.5);
                            bool _3978 = _3942 == 1;
                            spvUnsafeArray<float2, 3> _3926;
                            spvUnsafeArray<float2, 3> _3927;
                            if (_3978)
                            {
                                float2 _3981 = _3971 * 2.0;
                                _3926[0] = float2(3.0) - _3981;
                                _3926[1] = float2(1.0) + _3981;
                                _3927[0] = ((float2(2.0) - _3971) / _3926[0]) - float2(1.0);
                                _3927[1] = (_3971 / _3926[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _4008 = _3971 * 3.0;
                                _3926[0] = float2(4.0) - _4008;
                                _3926[1] = float2(7.0);
                                _3926[2] = float2(1.0) + _4008;
                                _3927[0] = ((float2(3.0) - (_3971 * 2.0)) / _3926[0]) - float2(2.0);
                                _3927[1] = (float2(3.0) + _3971) / _3926[1];
                                _3927[2] = (_3971 / _3926[2]) + float2(2.0);
                            }
                            int _7850 = _3978 ? 2 : 3;
                            int _7179;
                            float _7182;
                            _7182 = 0.0;
                            _7179 = 0;
                            float _7188;
                            for (; _7179 < _7850; _7182 = _7188, _7179++)
                            {
                                _7188 = _7182;
                                for (int _7185 = 0; _7185 < _7850; )
                                {
                                    _7188 += ((_3926[_7185].x * _3926[_7179].y) * spvDepthCast(_213).sample_compare(_213Smplr, float3(fast::clamp(_193._m22.xy * (_3974 + float2(_3927[_7185].x, _3927[_7179].y)), _3916.xy, _3916.zw), _3879).xy, _3879));
                                    _7185++;
                                    continue;
                                }
                            }
                            _7189 = _7182 * (_3978 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _7190 = _7189;
                        break;
                    } while(false);
                    _7211 = mix(_7170, _7190, _3485);
                    _7208 = mix(_567[_7157], _567[_3487], float3(_3485));
                }
                else
                {
                    _7211 = mix(_7170, 1.0, _3485);
                    _7208 = _567[_7157];
                }
                _7210 = _7211;
                _7207 = _7208;
            }
            else
            {
                _7210 = _7170;
                _7207 = _567[_7157];
            }
            _7213 = select(float3(1.0), _7207, bool3(_193._m22.w > 0.5));
            _7212 = _7210;
            break;
        } while(false);
        _7365 = _7212;
        _7333 = _7241 * _7213;
    }
    else
    {
        _7365 = 1.0;
        _7333 = _7241;
    }
    float3 _2344 = _193._m5.xyz * _193._m4.w;
    bool _2348 = _1531._m6.w > 0.5;
    float _7264;
    if (_2348)
    {
        _7264 = 1.0;
    }
    else
    {
        _7264 = 1.0 + (_1531._m4.w * (_2007.sample(_1230, _2074).x - 1.0));
    }
    float _2368 = abs(in.m_1607.w);
    float _7441;
    if (_2368 > 0.0)
    {
        _7441 = _7264 * fast::min(_2368, 1.0);
    }
    else
    {
        _7441 = _7264;
    }
    float3 _7555;
    if (!_2278)
    {
        float _2384 = dot(_7339, _2295);
        float3 _7547;
        if (_193._m29.x > 0.5)
        {
            float _4159 = (_193._m29.z * _7339.x) - (_193._m29.w * _7339.z);
            float _4172 = (_193._m29.w * _7339.x) + (_193._m29.z * _7339.z);
            float _4190 = 1.09254801273345947265625 * _4159;
            spvUnsafeArray<float, 9> _6922 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _7339.y, 0.48860299587249755859375 * _4172, 0.48860299587249755859375 * _4159, _4190 * _7339.y, (1.09254801273345947265625 * _7339.y) * _4172, 0.3153919875621795654296875 * (((3.0 * _4172) * _4172) - 1.0), _4190 * _4172, 0.546274006366729736328125 * ((_4159 * _4159) - (_7339.y * _7339.y)) });
            spvUnsafeArray<float, 9> _4104 = _6922;
            float3 _7546;
            _7546 = float3(0.0);
            for (int _7545 = 0; _7545 < 9; )
            {
                _7546 += (_1228.read(uint2((int2(496, 256) + int2(_7545, 0))), 0).xyz * _4104[_7545]);
                _7545++;
                continue;
            }
            _7547 = fast::max(_7546, float3(0.0)) * _193._m29.y;
        }
        else
        {
            _7547 = mix(_193._m9.xyz, _193._m8.xyz, float3((_7339.y * 0.5) + 0.5)) * _193._m8.w;
        }
        float3 _2434 = (_7333 * ((_7547 * _7441) + ((_2344 * fast::max(_2384, 0.0)) * _7365))) + ((_2344 * ((powr(fast::max(dot(_7339, _2307), 0.0), _1531._m1.w) * _1531._m1.z) * step(0.0, _2384))) * _7365);
        float3 _7556;
        if (_193._m13.w > 0.5)
        {
            float2 _4275 = fast::clamp(floor(gl_FragCoord.xy * _193._m12.xy), float2(0.0), _193._m13.xy - float2(1.0));
            uint _4303 = uint((((fast::clamp(floor((log2(fast::max(dot(_193._m11.xyz, in.m_1691) + _193._m11.w, 9.9999999747524270787835121154785e-07)) * _193._m12.z) + _193._m12.w), 0.0, _193._m13.z - 1.0) * _193._m13.y) + _4275.y) * _193._m13.x) + _4275.x);
            uint _4305 = _4303 >> uint(2);
            uint _4307 = _4303 & 3u;
            uint _4311 = _1822._m0[_4305][_4307] & 65535u;
            uint _4313 = _1822._m0[_4305][_4307] >> uint(16);
            float3 _7557;
            _7557 = _2434;
            float3 _2514;
            spvUnsafeArray<float2, 3> _4721;
            spvUnsafeArray<float2, 3> _4722;
            spvUnsafeArray<float2, 3> _4934;
            spvUnsafeArray<float2, 3> _4935;
            for (uint _7554 = _4311; _7554 < (_4311 + _4313); _7557 = _2514, _7554++)
            {
                uint _4319 = _7554 / 3u;
                uint _4332 = (_1843._m0[_4319 >> uint(2)][_4319 & 3u] >> ((_7554 - (_4319 * 3u)) * 10u)) & 1023u;
                float3 _4349 = _1684._m0[_4332].xyz - in.m_1691;
                float _4352 = dot(_4349, _4349);
                float _4356 = _4352 * _1684._m0[_4332].w;
                float _4361 = fast::clamp(1.0 - (_4356 * _4356), 0.0, 1.0);
                float3 _4366 = _4349 * rsqrt(fast::max(_4352, 9.9999999392252902907785028219223e-09));
                float _4384 = fast::clamp((dot(-_4366, _1727._m0[_4332].xyz) * _1719._m0[_4332].w) + _1727._m0[_4332].w, 0.0, 1.0);
                float3 _4397 = _1719._m0[_4332].xyz * ((((_4361 * _4361) * _4384) * _4384) / fast::max(_4352, 9.9999997473787516355514526367188e-05));
                float3 _7753;
                if (_2318)
                {
                    float _7699;
                    do
                    {
                        uint _4433 = uint(_193._m21.z);
                        if (_4332 < _4433)
                        {
                            float _4455 = _193._m26[_4332].z * fast::max((_193._m15[_4332] * float4(in.m_1691, 1.0)).w, 0.0);
                            float4 _4479 = _193._m15[_4332] * float4((in.m_1691 + (_2313 * (_4455 * _193._m25.x))) + (_4366 * (_4455 * _193._m25.y)), 1.0);
                            float _4481 = _4479.w;
                            if (_4481 <= 0.0)
                            {
                                _7699 = 1.0;
                                break;
                            }
                            float3 _4490 = _4479.xyz / float3(_4481);
                            float _4492 = _4490.x;
                            bool _4493 = _4492 < 0.0;
                            bool _4500;
                            if (!_4493)
                            {
                                _4500 = _4492 > 1.0;
                            }
                            else
                            {
                                _4500 = _4493;
                            }
                            bool _4507;
                            if (!_4500)
                            {
                                _4507 = _4490.y < 0.0;
                            }
                            else
                            {
                                _4507 = _4500;
                            }
                            bool _4514;
                            if (!_4507)
                            {
                                _4514 = _4490.y > 1.0;
                            }
                            else
                            {
                                _4514 = _4507;
                            }
                            bool _4521;
                            if (!_4514)
                            {
                                _4521 = _4490.z > 1.0;
                            }
                            else
                            {
                                _4521 = _4514;
                            }
                            if (_4521)
                            {
                                _7699 = 1.0;
                                break;
                            }
                            float _4527 = _4490.z;
                            float2 _4693 = _193._m22.xy * 0.5;
                            float2 _4698 = _193._m26[_4332].xy + (_4490.xy * _193._m23.zw);
                            float4 _4711 = float4(_193._m26[_4332].xy + _4693, (_193._m26[_4332].xy + _193._m23.zw) - _4693);
                            float _7698;
                            do
                            {
                                int _4737 = int(_193._m22.z);
                                if (_4737 <= 0)
                                {
                                    float2 _4747 = fast::clamp(_4698, _4711.xy, _4711.zw);
                                    _7698 = spvDepthCast(_213).sample_compare(_213Smplr, float3(_4747, _4527).xy, _4527);
                                    break;
                                }
                                float2 _4760 = (_4698 / _193._m22.xy) + float2(0.5);
                                float2 _4761 = floor(_4760);
                                float2 _4766 = _4760 - _4761;
                                float2 _4769 = _4761 - float2(0.5);
                                bool _4773 = _4737 == 1;
                                if (_4773)
                                {
                                    float2 _4776 = _4766 * 2.0;
                                    _4721[0] = float2(3.0) - _4776;
                                    _4721[1] = float2(1.0) + _4776;
                                    _4722[0] = ((float2(2.0) - _4766) / _4721[0]) - float2(1.0);
                                    _4722[1] = (_4766 / _4721[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _4803 = _4766 * 3.0;
                                    _4721[0] = float2(4.0) - _4803;
                                    _4721[1] = float2(7.0);
                                    _4721[2] = float2(1.0) + _4803;
                                    _4722[0] = ((float2(3.0) - (_4766 * 2.0)) / _4721[0]) - float2(2.0);
                                    _4722[1] = (float2(3.0) + _4766) / _4721[1];
                                    _4722[2] = (_4766 / _4721[2]) + float2(2.0);
                                }
                                int _7855 = _4773 ? 2 : 3;
                                int _7688;
                                float _7691;
                                _7691 = 0.0;
                                _7688 = 0;
                                float _7697;
                                for (; _7688 < _7855; _7691 = _7697, _7688++)
                                {
                                    _7697 = _7691;
                                    for (int _7694 = 0; _7694 < _7855; )
                                    {
                                        _7697 += ((_4721[_7694].x * _4721[_7688].y) * spvDepthCast(_213).sample_compare(_213Smplr, float3(fast::clamp(_193._m22.xy * (_4769 + float2(_4722[_7694].x, _4722[_7688].y)), _4711.xy, _4711.zw), _4527).xy, _4527));
                                        _7694++;
                                        continue;
                                    }
                                }
                                _7698 = _7691 * (_4773 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _7699 = _7698;
                            break;
                        }
                        uint _4537 = _4332 - _4433;
                        if (_4537 >= uint(_193._m21.w))
                        {
                            _7699 = 1.0;
                            break;
                        }
                        float _4558 = _193._m27[_4537].w * length(in.m_1691 - _193._m27[_4537].xyz);
                        float3 _4576 = ((in.m_1691 + (_2313 * (_4558 * _193._m25.x))) + (_4366 * (_4558 * _193._m25.y))) - _193._m27[_4537].xyz;
                        float3 _4578 = abs(_4576);
                        float _4580 = _4578.x;
                        float _4582 = _4578.y;
                        bool _4583 = _4580 >= _4582;
                        bool _4591;
                        if (_4583)
                        {
                            _4591 = _4580 >= _4578.z;
                        }
                        else
                        {
                            _4591 = _4583;
                        }
                        float _7673;
                        int _7675;
                        if (_4591)
                        {
                            _7675 = (_4576.x > 0.0) ? 0 : 1;
                            _7673 = _4580;
                        }
                        else
                        {
                            float _4603 = _4578.z;
                            bool _4604 = _4582 >= _4603;
                            int _7676;
                            if (_4604)
                            {
                                _7676 = (_4576.y > 0.0) ? 2 : 3;
                            }
                            else
                            {
                                _7676 = (_4576.z > 0.0) ? 4 : 5;
                            }
                            _7675 = _7676;
                            _7673 = _4604 ? _4582 : _4603;
                        }
                        if (_7673 <= 0.0)
                        {
                            _7699 = 1.0;
                            break;
                        }
                        float2 _4641 = float2(dot(_4576, _871[_7675]), dot(_4576, _880[_7675])) / float2(_7673 * _193._m24.z);
                        float _4648 = _193._m28[_4537].z + (_193._m28[_4537].w / _7673);
                        if (_4648 > 1.0)
                        {
                            _7699 = 1.0;
                            break;
                        }
                        float2 _4666 = _193._m28[_4537].xy + (float2(float(spvSMod(_7675, 3)), float(_7675 / 3)) * _193._m24.xy);
                        float2 _4906 = _193._m22.xy * 0.5;
                        float2 _4911 = _4666 + (float2(0.5 + (0.5 * _4641.x), 0.5 - (0.5 * _4641.y)) * _193._m24.xy);
                        float4 _4924 = float4(_4666 + _4906, (_4666 + _193._m24.xy) - _4906);
                        float _7687;
                        do
                        {
                            int _4950 = int(_193._m22.z);
                            if (_4950 <= 0)
                            {
                                _7687 = spvDepthCast(_213).sample_compare(_213Smplr, float3(fast::clamp(_4911, _4924.xy, _4924.zw), _4648).xy, _4648);
                                break;
                            }
                            float2 _4973 = (_4911 / _193._m22.xy) + float2(0.5);
                            float2 _4974 = floor(_4973);
                            float2 _4979 = _4973 - _4974;
                            float2 _4982 = _4974 - float2(0.5);
                            bool _4986 = _4950 == 1;
                            if (_4986)
                            {
                                float2 _4989 = _4979 * 2.0;
                                _4934[0] = float2(3.0) - _4989;
                                _4934[1] = float2(1.0) + _4989;
                                _4935[0] = ((float2(2.0) - _4979) / _4934[0]) - float2(1.0);
                                _4935[1] = (_4979 / _4934[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _5016 = _4979 * 3.0;
                                _4934[0] = float2(4.0) - _5016;
                                _4934[1] = float2(7.0);
                                _4934[2] = float2(1.0) + _5016;
                                _4935[0] = ((float2(3.0) - (_4979 * 2.0)) / _4934[0]) - float2(2.0);
                                _4935[1] = (float2(3.0) + _4979) / _4934[1];
                                _4935[2] = (_4979 / _4934[2]) + float2(2.0);
                            }
                            int _7858 = _4986 ? 2 : 3;
                            int _7677;
                            float _7680;
                            _7680 = 0.0;
                            _7677 = 0;
                            float _7686;
                            for (; _7677 < _7858; _7680 = _7686, _7677++)
                            {
                                _7686 = _7680;
                                for (int _7683 = 0; _7683 < _7858; )
                                {
                                    _7686 += ((_4934[_7683].x * _4934[_7677].y) * spvDepthCast(_213).sample_compare(_213Smplr, float3(fast::clamp(_193._m22.xy * (_4982 + float2(_4935[_7683].x, _4935[_7677].y)), _4924.xy, _4924.zw), _4648).xy, _4648));
                                    _7683++;
                                    continue;
                                }
                            }
                            _7687 = _7680 * (_4986 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _7699 = _7687;
                        break;
                    } while(false);
                    _7753 = _4397 * _7699;
                }
                else
                {
                    _7753 = _4397;
                }
                float _2485 = dot(_7339, _4366);
                _2514 = _7557 + (((_7333 * fast::max(_2485, 0.0)) * _7753) + (_7753 * ((powr(fast::max(dot(_7339, fast::normalize(_4366 + _2302)), 0.0), _1531._m1.w) * _1531._m1.z) * step(0.0, _2485))));
            }
            _7556 = _7557;
        }
        else
        {
            _7556 = _2434;
        }
        _7555 = _7556;
    }
    else
    {
        float4 _2524 = _2519.sample(_1230, _2074);
        float _2531 = fast::clamp(_1531._m4.x * _2524.z, 0.0, 1.0);
        float _2539 = fast::clamp(_1531._m4.y * _2524.y, 0.04500000178813934326171875, 1.0);
        float _7329;
        float _7334;
        if (_7271 > 0.0)
        {
            _7334 = mix(_2531, _7303.y, _7271);
            _7329 = mix(_2539, fast::max(_7303.x, 0.04500000178813934326171875), _7271);
        }
        else
        {
            _7334 = _2531;
            _7329 = _2539;
        }
        float _2558 = _7329 * _7329;
        float3 _2563 = _7333 * (1.0 - _7334);
        float3 _2569 = mix(float3(0.039999999105930328369140625), _7333, float3(_7334));
        float _2574 = fast::max(dot(_7339, _2302), 9.9999997473787516355514526367188e-05);
        float _2579 = fast::clamp(dot(_7339, _2295), 0.0, 1.0);
        float _2584 = fast::clamp(dot(_7339, _2307), 0.0, 1.0);
        float3 _5118 = float3(1.0) - _2569;
        float3 _5121 = _2569 + (_5118 * powr(1.0 - fast::clamp(dot(_2302, _2307), 0.0, 1.0), 5.0));
        float _5128 = _2558 * _2558;
        float _5133 = _5128 - 1.0;
        float _5135 = ((_2584 * _2584) * _5133) + 1.0;
        float _5155 = 1.0 - _5128;
        float _5159 = sqrt(((_2574 * _2574) * _5155) + _5128);
        float3 _7385;
        float2 _7408;
        float3 _7420;
        if (_193._m29.x > 0.5)
        {
            float4 _5192 = _1334.sample(_1336, (((float2(_2574, _7329) * 31.0) + float2(0.5)) * float2(0.03125)));
            float _5251 = (_193._m29.z * _7339.x) - (_193._m29.w * _7339.z);
            float _5264 = (_193._m29.w * _7339.x) + (_193._m29.z * _7339.z);
            float _5282 = 1.09254801273345947265625 * _5251;
            spvUnsafeArray<float, 9> _6903 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _7339.y, 0.48860299587249755859375 * _5264, 0.48860299587249755859375 * _5251, _5282 * _7339.y, (1.09254801273345947265625 * _7339.y) * _5264, 0.3153919875621795654296875 * (((3.0 * _5264) * _5264) - 1.0), _5282 * _5264, 0.546274006366729736328125 * ((_5251 * _5251) - (_7339.y * _7339.y)) });
            spvUnsafeArray<float, 9> _5196 = _6903;
            float3 _7367;
            _7367 = float3(0.0);
            for (int _7366 = 0; _7366 < 9; )
            {
                _7367 += (_1228.read(uint2((int2(496, 256) + int2(_7366, 0))), 0).xyz * _5196[_7366]);
                _7366++;
                continue;
            }
            float3 _2645 = reflect(-_2302, _7339);
            float _5377 = _2645.x;
            float _5382 = _2645.z;
            float2 _5414 = float2((precise::atan2((_193._m29.z * _5377) - (_193._m29.w * _5382), -((_193._m29.w * _5377) + (_193._m29.z * _5382))) * 0.15915493667125701904296875) + 0.5, acos(fast::clamp(_2645.y, -1.0, 1.0)) * 0.3183098733425140380859375);
            float _5346 = _7329 * 5.0;
            int _5349 = min(int(_5346), 4);
            float2 _5435 = (_5414 * float2(_1290[_5349].zw)) - float2(0.5);
            float2 _5437 = floor(_5435);
            float2 _5440 = _5435 - _5437;
            int _5443 = int(_5437.x);
            int _5446 = int(_5437.y);
            int _7370;
            if (_5443 < 0)
            {
                _7370 = _5443 + _1290[_5349].z;
            }
            else
            {
                _7370 = _5443;
            }
            int _7371;
            if (_7370 >= _1290[_5349].z)
            {
                _7371 = _7370 - _1290[_5349].z;
            }
            else
            {
                _7371 = _7370;
            }
            int _5466 = _7371 + 1;
            int _7859 = (_5466 == _1290[_5349].z) ? 0 : _5466;
            int _5481 = min((_5446 + 1), (_1290[_5349].w - 1));
            int _5483 = max(_5446, 0);
            float3 _5536 = float3(_5440.x);
            int _5356 = _5349 + 1;
            float2 _5568 = (_5414 * float2(_1290[_5356].zw)) - float2(0.5);
            float2 _5570 = floor(_5568);
            float2 _5573 = _5568 - _5570;
            int _5576 = int(_5570.x);
            int _5579 = int(_5570.y);
            int _7377;
            if (_5576 < 0)
            {
                _7377 = _5576 + _1290[_5356].z;
            }
            else
            {
                _7377 = _5576;
            }
            int _7378;
            if (_7377 >= _1290[_5356].z)
            {
                _7378 = _7377 - _1290[_5356].z;
            }
            else
            {
                _7378 = _7377;
            }
            int _5599 = _7378 + 1;
            int _7860 = (_5599 == _1290[_5356].z) ? 0 : _5599;
            int _5614 = min((_5579 + 1), (_1290[_5356].w - 1));
            int _5616 = max(_5579, 0);
            float3 _5669 = float3(_5573.x);
            float3 _5371 = mix(mix(mix(_1228.read(uint2((_1290[_5349].xy + int2(_7371, _5483))), 0).xyz, _1228.read(uint2((_1290[_5349].xy + int2(_7859, _5483))), 0).xyz, _5536), mix(_1228.read(uint2((_1290[_5349].xy + int2(_7371, _5481))), 0).xyz, _1228.read(uint2((_1290[_5349].xy + int2(_7859, _5481))), 0).xyz, _5536), float3(_5440.y)), mix(mix(_1228.read(uint2((_1290[_5356].xy + int2(_7378, _5616))), 0).xyz, _1228.read(uint2((_1290[_5356].xy + int2(_7860, _5616))), 0).xyz, _5669), mix(_1228.read(uint2((_1290[_5356].xy + int2(_7378, _5614))), 0).xyz, _1228.read(uint2((_1290[_5356].xy + int2(_7860, _5614))), 0).xyz, _5669), float3(_5573.y)), float3(_5346 - float(_5349))) * _193._m29.y;
            _7420 = fast::max(_7367, float3(0.0)) * _193._m29.y;
            _7408 = _5192.xy;
            _7385 = _5371;
        }
        else
        {
            float4 _5687 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * _7329) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);
            float _5689 = _5687.x;
            float3 _5724 = mix(_193._m9.xyz, _193._m8.xyz, float3((_7339.y * 0.5) + 0.5)) * _193._m8.w;
            _7420 = _5724;
            _7408 = (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_5689 * _5689, exp2((-9.27999973297119140625) * _2574)) * _5689) + _5687.y)) + _5687.zw;
            _7385 = mix(mix(_193._m9.xyz, _193._m8.xyz, float3((reflect(-_2302, _7339).y * 0.5) + 0.5)) * _193._m8.w, _5724, float3(_7329));
        }
        bool _2677;
        if (_2348)
        {
            _2677 = _193._m33.z > 0.5;
        }
        else
        {
            _2677 = _2348;
        }
        float3 _7429;
        if (_2677)
        {
            float3 _7405;
            do
            {
                float _5803 = ((_193._m32.x * (1.0 - smoothstep(_193._m33.x * 0.5, _193._m33.x, abs(dot(_193._m31.xyz, in.m_1691) - _193._m31.w)))) * smoothstep(0.5, 0.89999997615814208984375, dot(_2313, _193._m31.xyz))) * (1.0 - smoothstep(_193._m32.y * 0.5, _193._m32.y, _7329));
                if (_5803 <= 0.0)
                {
                    _7405 = _7385;
                    break;
                }
                float4 _5828 = _193._m30 * float4(in.m_1691 + ((_7339 - (_193._m31.xyz * dot(_7339, _193._m31.xyz))) * _193._m32.w), 1.0);
                float2 _5841 = ((float2(_5828.x, -_5828.y) / float2(_5828.w)) * 0.5) + float2(0.5);
                float _5845 = _193._m32.z * _7329;
                float3 _7403;
                float _7404;
                _7404 = 0.0;
                _7403 = float3(0.0);
                for (int _7402 = 0; _7402 < 12; )
                {
                    float _5852 = float(_7402);
                    float _5860 = _5852 * 2.3999631404876708984375;
                    float2 _5872 = _5841 + (float2(cos(_5860) * _193._m33.y, sin(_5860)) * (sqrt((_5852 + 0.5) * 0.083333335816860198974609375) * _5845));
                    float2 _5877 = fast::min(_5872, float2(1.0) - _5872);
                    float _5883 = smoothstep(0.0, 0.039999999105930328369140625, fast::min(_5877.x, _5877.y));
                    float4 _5891 = _2007.sample(_1230, fast::clamp(_5872, float2(0.0), float2(1.0)), level(0.0));
                    float3 _5893 = _5891.xyz;
                    _7404 += (_5891.w * _5883);
                    _7403 += ((_5893 / (float3(1.0) - fast::min(_5893, float3(0.99500000476837158203125)))) * _5883);
                    _7402++;
                    continue;
                }
                _7405 = mix(_7385, (_7403 * float3(0.083333335816860198974609375)) + (_7385 * (1.0 - (_7404 * 0.083333335816860198974609375))), float3(_5803));
                break;
            } while(false);
            _7429 = _7405;
        }
        else
        {
            _7429 = _7385;
        }
        float3 _2697 = (_2569 * _7408.x) + float3(_7408.y);
        float3 _2713 = ((((((float3(1.0) - _5121) * _2563) + ((_5121 * ((_5128 / ((3.1415927410125732421875 * _5135) * _5135)) * (0.5 / fast::max((_2579 * _5159) + (_2574 * sqrt(((_2579 * _2579) * _5155) + _5128)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875)) * _2579) * _2344) * _7365) + (((((float3(1.0) - _2697) * _2563) * _7420) + (_2697 * _7429)) * _7441);
        float3 _7558;
        if (_193._m13.w > 0.5)
        {
            float2 _5957 = fast::clamp(floor(gl_FragCoord.xy * _193._m12.xy), float2(0.0), _193._m13.xy - float2(1.0));
            uint _5985 = uint((((fast::clamp(floor((log2(fast::max(dot(_193._m11.xyz, in.m_1691) + _193._m11.w, 9.9999999747524270787835121154785e-07)) * _193._m12.z) + _193._m12.w), 0.0, _193._m13.z - 1.0) * _193._m13.y) + _5957.y) * _193._m13.x) + _5957.x);
            uint _5987 = _5985 >> uint(2);
            uint _5989 = _5985 & 3u;
            uint _5993 = _1822._m0[_5987][_5989] & 65535u;
            uint _5995 = _1822._m0[_5987][_5989] >> uint(16);
            float3 _7511;
            _7511 = _2713;
            float3 _2813;
            spvUnsafeArray<float2, 3> _6403;
            spvUnsafeArray<float2, 3> _6404;
            spvUnsafeArray<float2, 3> _6616;
            spvUnsafeArray<float2, 3> _6617;
            for (uint _7444 = _5993; _7444 < (_5993 + _5995); _7511 = _2813, _7444++)
            {
                uint _6001 = _7444 / 3u;
                uint _6014 = (_1843._m0[_6001 >> uint(2)][_6001 & 3u] >> ((_7444 - (_6001 * 3u)) * 10u)) & 1023u;
                float3 _6031 = _1684._m0[_6014].xyz - in.m_1691;
                float _6034 = dot(_6031, _6031);
                float _6038 = _6034 * _1684._m0[_6014].w;
                float _6043 = fast::clamp(1.0 - (_6038 * _6038), 0.0, 1.0);
                float3 _6048 = _6031 * rsqrt(fast::max(_6034, 9.9999999392252902907785028219223e-09));
                float _6066 = fast::clamp((dot(-_6048, _1727._m0[_6014].xyz) * _1719._m0[_6014].w) + _1727._m0[_6014].w, 0.0, 1.0);
                float3 _6079 = _1719._m0[_6014].xyz * ((((_6043 * _6043) * _6066) * _6066) / fast::max(_6034, 9.9999997473787516355514526367188e-05));
                float3 _7509;
                if (_2318)
                {
                    float _7471;
                    do
                    {
                        uint _6115 = uint(_193._m21.z);
                        if (_6014 < _6115)
                        {
                            float _6137 = _193._m26[_6014].z * fast::max((_193._m15[_6014] * float4(in.m_1691, 1.0)).w, 0.0);
                            float4 _6161 = _193._m15[_6014] * float4((in.m_1691 + (_2313 * (_6137 * _193._m25.x))) + (_6048 * (_6137 * _193._m25.y)), 1.0);
                            float _6163 = _6161.w;
                            if (_6163 <= 0.0)
                            {
                                _7471 = 1.0;
                                break;
                            }
                            float3 _6172 = _6161.xyz / float3(_6163);
                            float _6174 = _6172.x;
                            bool _6175 = _6174 < 0.0;
                            bool _6182;
                            if (!_6175)
                            {
                                _6182 = _6174 > 1.0;
                            }
                            else
                            {
                                _6182 = _6175;
                            }
                            bool _6189;
                            if (!_6182)
                            {
                                _6189 = _6172.y < 0.0;
                            }
                            else
                            {
                                _6189 = _6182;
                            }
                            bool _6196;
                            if (!_6189)
                            {
                                _6196 = _6172.y > 1.0;
                            }
                            else
                            {
                                _6196 = _6189;
                            }
                            bool _6203;
                            if (!_6196)
                            {
                                _6203 = _6172.z > 1.0;
                            }
                            else
                            {
                                _6203 = _6196;
                            }
                            if (_6203)
                            {
                                _7471 = 1.0;
                                break;
                            }
                            float _6209 = _6172.z;
                            float2 _6375 = _193._m22.xy * 0.5;
                            float2 _6380 = _193._m26[_6014].xy + (_6172.xy * _193._m23.zw);
                            float4 _6393 = float4(_193._m26[_6014].xy + _6375, (_193._m26[_6014].xy + _193._m23.zw) - _6375);
                            float _7470;
                            do
                            {
                                int _6419 = int(_193._m22.z);
                                if (_6419 <= 0)
                                {
                                    float2 _6429 = fast::clamp(_6380, _6393.xy, _6393.zw);
                                    _7470 = spvDepthCast(_213).sample_compare(_213Smplr, float3(_6429, _6209).xy, _6209);
                                    break;
                                }
                                float2 _6442 = (_6380 / _193._m22.xy) + float2(0.5);
                                float2 _6443 = floor(_6442);
                                float2 _6448 = _6442 - _6443;
                                float2 _6451 = _6443 - float2(0.5);
                                bool _6455 = _6419 == 1;
                                if (_6455)
                                {
                                    float2 _6458 = _6448 * 2.0;
                                    _6403[0] = float2(3.0) - _6458;
                                    _6403[1] = float2(1.0) + _6458;
                                    _6404[0] = ((float2(2.0) - _6448) / _6403[0]) - float2(1.0);
                                    _6404[1] = (_6448 / _6403[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _6485 = _6448 * 3.0;
                                    _6403[0] = float2(4.0) - _6485;
                                    _6403[1] = float2(7.0);
                                    _6403[2] = float2(1.0) + _6485;
                                    _6404[0] = ((float2(3.0) - (_6448 * 2.0)) / _6403[0]) - float2(2.0);
                                    _6404[1] = (float2(3.0) + _6448) / _6403[1];
                                    _6404[2] = (_6448 / _6403[2]) + float2(2.0);
                                }
                                int _7862 = _6455 ? 2 : 3;
                                int _7460;
                                float _7463;
                                _7463 = 0.0;
                                _7460 = 0;
                                float _7469;
                                for (; _7460 < _7862; _7463 = _7469, _7460++)
                                {
                                    _7469 = _7463;
                                    for (int _7466 = 0; _7466 < _7862; )
                                    {
                                        _7469 += ((_6403[_7466].x * _6403[_7460].y) * spvDepthCast(_213).sample_compare(_213Smplr, float3(fast::clamp(_193._m22.xy * (_6451 + float2(_6404[_7466].x, _6404[_7460].y)), _6393.xy, _6393.zw), _6209).xy, _6209));
                                        _7466++;
                                        continue;
                                    }
                                }
                                _7470 = _7463 * (_6455 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _7471 = _7470;
                            break;
                        }
                        uint _6219 = _6014 - _6115;
                        if (_6219 >= uint(_193._m21.w))
                        {
                            _7471 = 1.0;
                            break;
                        }
                        float _6240 = _193._m27[_6219].w * length(in.m_1691 - _193._m27[_6219].xyz);
                        float3 _6258 = ((in.m_1691 + (_2313 * (_6240 * _193._m25.x))) + (_6048 * (_6240 * _193._m25.y))) - _193._m27[_6219].xyz;
                        float3 _6260 = abs(_6258);
                        float _6262 = _6260.x;
                        float _6264 = _6260.y;
                        bool _6265 = _6262 >= _6264;
                        bool _6273;
                        if (_6265)
                        {
                            _6273 = _6262 >= _6260.z;
                        }
                        else
                        {
                            _6273 = _6265;
                        }
                        float _7445;
                        int _7447;
                        if (_6273)
                        {
                            _7447 = (_6258.x > 0.0) ? 0 : 1;
                            _7445 = _6262;
                        }
                        else
                        {
                            float _6285 = _6260.z;
                            bool _6286 = _6264 >= _6285;
                            int _7448;
                            if (_6286)
                            {
                                _7448 = (_6258.y > 0.0) ? 2 : 3;
                            }
                            else
                            {
                                _7448 = (_6258.z > 0.0) ? 4 : 5;
                            }
                            _7447 = _7448;
                            _7445 = _6286 ? _6264 : _6285;
                        }
                        if (_7445 <= 0.0)
                        {
                            _7471 = 1.0;
                            break;
                        }
                        float2 _6323 = float2(dot(_6258, _871[_7447]), dot(_6258, _880[_7447])) / float2(_7445 * _193._m24.z);
                        float _6330 = _193._m28[_6219].z + (_193._m28[_6219].w / _7445);
                        if (_6330 > 1.0)
                        {
                            _7471 = 1.0;
                            break;
                        }
                        float2 _6348 = _193._m28[_6219].xy + (float2(float(spvSMod(_7447, 3)), float(_7447 / 3)) * _193._m24.xy);
                        float2 _6588 = _193._m22.xy * 0.5;
                        float2 _6593 = _6348 + (float2(0.5 + (0.5 * _6323.x), 0.5 - (0.5 * _6323.y)) * _193._m24.xy);
                        float4 _6606 = float4(_6348 + _6588, (_6348 + _193._m24.xy) - _6588);
                        float _7459;
                        do
                        {
                            int _6632 = int(_193._m22.z);
                            if (_6632 <= 0)
                            {
                                _7459 = spvDepthCast(_213).sample_compare(_213Smplr, float3(fast::clamp(_6593, _6606.xy, _6606.zw), _6330).xy, _6330);
                                break;
                            }
                            float2 _6655 = (_6593 / _193._m22.xy) + float2(0.5);
                            float2 _6656 = floor(_6655);
                            float2 _6661 = _6655 - _6656;
                            float2 _6664 = _6656 - float2(0.5);
                            bool _6668 = _6632 == 1;
                            if (_6668)
                            {
                                float2 _6671 = _6661 * 2.0;
                                _6616[0] = float2(3.0) - _6671;
                                _6616[1] = float2(1.0) + _6671;
                                _6617[0] = ((float2(2.0) - _6661) / _6616[0]) - float2(1.0);
                                _6617[1] = (_6661 / _6616[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _6698 = _6661 * 3.0;
                                _6616[0] = float2(4.0) - _6698;
                                _6616[1] = float2(7.0);
                                _6616[2] = float2(1.0) + _6698;
                                _6617[0] = ((float2(3.0) - (_6661 * 2.0)) / _6616[0]) - float2(2.0);
                                _6617[1] = (float2(3.0) + _6661) / _6616[1];
                                _6617[2] = (_6661 / _6616[2]) + float2(2.0);
                            }
                            int _7865 = _6668 ? 2 : 3;
                            int _7449;
                            float _7452;
                            _7452 = 0.0;
                            _7449 = 0;
                            float _7458;
                            for (; _7449 < _7865; _7452 = _7458, _7449++)
                            {
                                _7458 = _7452;
                                for (int _7455 = 0; _7455 < _7865; )
                                {
                                    _7458 += ((_6616[_7455].x * _6616[_7449].y) * spvDepthCast(_213).sample_compare(_213Smplr, float3(fast::clamp(_193._m22.xy * (_6664 + float2(_6617[_7455].x, _6617[_7449].y)), _6606.xy, _6606.zw), _6330).xy, _6330));
                                    _7455++;
                                    continue;
                                }
                            }
                            _7459 = _7452 * (_6668 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _7471 = _7459;
                        break;
                    } while(false);
                    _7509 = _6079 * _7471;
                }
                else
                {
                    _7509 = _6079;
                }
                float3 _2765 = fast::normalize(_6048 + _2302);
                float _2770 = fast::clamp(dot(_7339, _6048), 0.0, 1.0);
                float _2775 = fast::clamp(dot(_7339, _2765), 0.0, 1.0);
                float3 _6803 = _2569 + (_5118 * powr(1.0 - fast::clamp(dot(_2302, _2765), 0.0, 1.0), 5.0));
                float _6817 = ((_2775 * _2775) * _5133) + 1.0;
                _2813 = _7511 + (((((float3(1.0) - _6803) * _2563) + ((_6803 * ((_5128 / ((3.1415927410125732421875 * _6817) * _6817)) * (0.5 / fast::max((_2770 * _5159) + (_2574 * sqrt(((_2770 * _2770) * _5155) + _5128)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875)) * _2770) * _7509);
            }
            _7558 = _7511;
        }
        else
        {
            _7558 = _2713;
        }
        _7555 = _7558;
    }
    float4 _2830 = _2825.sample(_1230, _2074);
    float _2848 = -length(_2301);
    float _7596;
    if (_193._m9.w != 0.0)
    {
        float _2872 = _193._m9.w * (in.m_1691 - _193._m6.xyz).y;
        float _7593;
        if (abs(_2872) < 9.9999997473787516355514526367188e-05)
        {
            _7593 = 1.0 - (0.5 * _2872);
        }
        else
        {
            _7593 = (1.0 - exp(fast::min(-_2872, 60.0))) / _2872;
        }
        _7596 = 1.0 - exp((_2848 * (_193._m7.w * exp(fast::min((-_193._m9.w) * (_193._m6.y - _193._m6.w), 30.0)))) * _7593);
    }
    else
    {
        _7596 = 1.0 - exp(_2848 * _193._m7.w);
    }
    float3 _2923 = mix(mix(_7555, _7333, float3(_1531._m1.y)) + ((_1531._m5.xyz * _2830.xyz) * (float3(1.0) + in.m_2315.yzw)), _193._m7.xyz, float3(_7596));
    float3 _7597;
    if (_193._m33.w > 0.5)
    {
        _7597 = _2923 / (float3(1.0) + _2923);
    }
    else
    {
        _7597 = _2923;
    }
    out.m_2935 = float4(_7597, in.m_2083.w);
    float2 _7672;
    do
    {
        if (in.m_2945.w <= 0.0)
        {
            _7672 = float2(0.0);
            break;
        }
        _7672 = ((in.m_2945.xy / float2(in.m_2945.w)) - (in.m_2944.xy / float2(in.m_2944.w))) * float2(0.5, -0.5);
        break;
    } while(false);
    out.m_2943 = _7672;
    return out;
}

