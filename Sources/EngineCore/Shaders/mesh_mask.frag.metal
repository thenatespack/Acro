// Generated from mesh_mask.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 0d727ec835f7e033
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
    float4 m_3028 [[color(0)]];
    float2 m_3036 [[color(1)]];
};

struct fragment_main_in
{
    float3 m_1691 [[user(locn0)]];
    float3 m_1601 [[user(locn1)]];
    float2 m_2060 [[user(locn2)]];
    float4 m_2083 [[user(locn3)]];
    float4 m_2328 [[user(locn5)]];
    float4 m_3037 [[user(locn6)]];
    float4 m_3038 [[user(locn7)]];
    float4 m_1607 [[user(locn8)]];
};

fragment fragment_main_out fragment_main(fragment_main_in in [[stage_in]], constant _1529& _1531 [[buffer(2)]], constant _1682& _1684 [[buffer(3)]], constant _1717& _1719 [[buffer(4)]], constant _1725& _1727 [[buffer(5)]], constant _1820& _1822 [[buffer(6)]], constant _1841& _1843 [[buffer(7)]], constant _191& _193 [[buffer(15)]], texture2d<float> _213 [[texture(0)]], texture2d<float> _2076 [[texture(1)]], texture2d<float> _2532 [[texture(2)]], texture2d<float> _2205 [[texture(3)]], texture2d<float> _2007 [[texture(4)]], texture2d<float> _2918 [[texture(5)]], texture2d<float> _1228 [[texture(6)]], texture2d<float> _1334 [[texture(7)]], sampler _213Smplr [[sampler(0)]], sampler _1230 [[sampler(1)]], sampler _1336 [[sampler(7)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])
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
    float3 _7240;
    if (_1531._m1.x > 0.5)
    {
        float2 _2126 = floor(in.m_1691.xz * float2(0.5));
        _7240 = _2092 * ((mod(abs(_2126.x + _2126.y), 2.0) < 0.5) ? 1.0 : 0.75);
    }
    else
    {
        _7240 = _2092;
    }
    float3 _7337;
    float _7368;
    float2 _7401;
    if (_1531._m3.w > 0.5)
    {
        float3 _3139;
        float2 _3146;
        float _7238;
        do
        {
            float3 _3110 = float4(_1531._m2.w, _1531._m3.w, 0.0, 0.0).xyy;
            float3 _3113 = floor(_3110 * float3(1.52587890625e-05));
            float3 _3118 = _3110 - (_3113 * 65536.0);
            float3 _3121 = floor(_3118 * float3(0.00390625));
            float3 _3129 = _3118 - (_3121 * 256.0);
            _3139 = (float3(_3129.x, _3121.x, _3113.x) * float3(0.0039215688593685626983642578125)) * 2.0;
            _3146 = float2(_3129.y, _3121.y) * float2(0.0039215688593685626983642578125);
            float _3149 = _3113.y - 128.0;
            float _3155 = floor(_3149 * 0.03125) * 0.3333333432674407958984375;
            float3 _3161 = fast::normalize(in.m_1601);
            float _3165 = dot(_3161, in.m_1607.xyz);
            float _3177 = (_3165 / fast::max(length(in.m_1607.xyz - (_3161 * _3165)), 9.9999999747524270787835121154785e-07)) * 25.5;
            if (((-24.0) + _3177) < (-2.0))
            {
                _7238 = 0.0;
                break;
            }
            float2 _3185 = _2074 * (4.0 * exp2(mod(_3149, 32.0) * 0.3333333432674407958984375));
            float2 _3222 = floor(_3185);
            float2 _3225 = _3185 - _3222;
            float2 _3233 = (_3225 * _3225) * (float2(3.0) - (_3225 * 2.0));
            uint2 _3261 = uint2(int2(_3222) + int2(65536));
            uint _3270 = ((_3261.x * 1597334677u) ^ (_3261.y * 3812015801u)) * 1597334677u;
            uint2 _3286 = uint2(int2(_3222 + float2(1.0, 0.0)) + int2(65536));
            uint _3295 = ((_3286.x * 1597334677u) ^ (_3286.y * 3812015801u)) * 1597334677u;
            float _3240 = _3233.x;
            uint2 _3311 = uint2(int2(_3222 + float2(0.0, 1.0)) + int2(65536));
            uint _3320 = ((_3311.x * 1597334677u) ^ (_3311.y * 3812015801u)) * 1597334677u;
            uint2 _3336 = uint2(int2(_3222 + float2(1.0)) + int2(65536));
            uint _3345 = ((_3336.x * 1597334677u) ^ (_3336.y * 3812015801u)) * 1597334677u;
            float2 _3191 = (_3185 * 2.7000000476837158203125) + float2(17.299999237060546875, 5.099999904632568359375);
            float2 _3364 = floor(_3191);
            float2 _3367 = _3191 - _3364;
            float2 _3375 = (_3367 * _3367) * (float2(3.0) - (_3367 * 2.0));
            uint2 _3403 = uint2(int2(_3364) + int2(65536));
            uint _3412 = ((_3403.x * 1597334677u) ^ (_3403.y * 3812015801u)) * 1597334677u;
            uint2 _3428 = uint2(int2(_3364 + float2(1.0, 0.0)) + int2(65536));
            uint _3437 = ((_3428.x * 1597334677u) ^ (_3428.y * 3812015801u)) * 1597334677u;
            float _3382 = _3375.x;
            uint2 _3453 = uint2(int2(_3364 + float2(0.0, 1.0)) + int2(65536));
            uint _3462 = ((_3453.x * 1597334677u) ^ (_3453.y * 3812015801u)) * 1597334677u;
            uint2 _3478 = uint2(int2(_3364 + float2(1.0)) + int2(65536));
            uint _3487 = ((_3478.x * 1597334677u) ^ (_3478.y * 3812015801u)) * 1597334677u;
            float _3196 = mix(0.449999988079071044921875, 0.0500000007450580596923828125, _3155);
            float _3204 = (_3177 + (-24.450000762939453125)) + ((((mix(mix(float((_3270 ^ (_3270 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_3295 ^ (_3295 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _3240), mix(float((_3320 ^ (_3320 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_3345 ^ (_3345 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _3240), _3233.y) * 0.64999997615814208984375) + (mix(mix(float((_3412 ^ (_3412 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_3437 ^ (_3437 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _3382), mix(float((_3462 ^ (_3462 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_3487 ^ (_3487 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _3382), _3375.y) * 0.3499999940395355224609375)) - 0.5) * mix(0.800000011920928955078125, 2.2000000476837158203125, _3155));
            _7238 = smoothstep(-_3196, _3196, _3204);
            break;
        } while(false);
        _7401 = _3146;
        _7368 = _7238;
        _7337 = mix(_7240, (in.m_2083.xyz * _3139) * mix(float3(1.0), _2091 * 2.0, float3(0.5)), float3(_7238));
    }
    else
    {
        _7401 = float2(0.0);
        _7368 = 0.0;
        _7337 = _7240;
    }
    float3 _2170 = fast::normalize(in.m_1601);
    float3 _7250;
    if (_1531._m6.y > 0.5)
    {
        float3 _2185 = in.m_1607.xyz - (_2170 * dot(_2170, in.m_1607.xyz));
        float3 _7251;
        if (dot(_2185, _2185) > 9.9999999600419720025001879548654e-13)
        {
            float3 _2194 = fast::normalize(_2185);
            float4 _2210 = _2205.sample(_1230, _2074);
            float3 _7242;
            if (_1531._m6.z > 0.5)
            {
                float2 _7241;
                if (_1531._m6.z > 1.5)
                {
                    _7241 = _2210.xw;
                }
                else
                {
                    _7241 = _2210.xy;
                }
                float2 _2232 = (_7241 * 2.0) - float2(1.0);
                _7242 = float3(_2232, sqrt(fast::clamp(1.0 - dot(_2232, _2232), 0.0, 1.0)));
            }
            else
            {
                _7242 = (_2210.xyz * 2.0) - float3(1.0);
            }
            float2 _2254 = _7242.xy * _1531._m4.z;
            _7251 = fast::normalize(((_2194 * _2254.x) + ((cross(_2170, _2194) * ((in.m_1607.w < 0.0) ? (-1.0) : 1.0)) * _2254.y)) + (_2170 * _7242.z));
        }
        else
        {
            _7251 = _2170;
        }
        _7250 = _7251;
    }
    else
    {
        _7250 = _2170;
    }
    bool _2278 = _1531._m5.w > 0.5;
    float _7247;
    if (_2278)
    {
        _7247 = fast::clamp(_1531._m1.z, 0.0, 1.0);
    }
    else
    {
        _7247 = 0.0;
    }
    bool _2296;
    if (_2278)
    {
        _2296 = !gl_FrontFacing;
    }
    else
    {
        _2296 = _2278;
    }
    float3 _7437;
    if (_2296 && (_7247 <= 0.0))
    {
        _7437 = -_7250;
    }
    else
    {
        _7437 = _7250;
    }
    float3 _2308 = fast::normalize(_193._m4.xyz);
    float3 _2314 = _193._m6.xyz - in.m_1691;
    float3 _2315 = fast::normalize(_2314);
    float3 _2320 = fast::normalize(_2308 + _2315);
    float3 _2326 = _2170 * (gl_FrontFacing ? 1.0 : (-1.0));
    bool _2331 = in.m_2328.x > 0.5;
    float3 _7431;
    float _7471;
    if ((_193._m5.w > 0.5) && _2331)
    {
        float _7307;
        float3 _7308;
        do
        {
            int _3516 = int(_193._m21.x);
            float _3524 = dot(_193._m20.xyz, in.m_1691) + _193._m20.w;
            int _7252;
            _7252 = 0;
            for (;;)
            {
                bool _3530 = _7252 < (_3516 - 1);
                bool _3538;
                if (_3530)
                {
                    _3538 = _3524 > _193._m16[_7252];
                }
                else
                {
                    _3538 = _3530;
                }
                if (_3538)
                {
                    _7252++;
                    continue;
                }
                else
                {
                    break;
                }
            }
            if (_3524 > _193._m16[_7252])
            {
                _7308 = float3(1.0);
                _7307 = 1.0;
                break;
            }
            float _7265;
            do
            {
                float4 _3640 = _193._m14[_7252] * float4(in.m_1691 + (_2326 * _193._m18[_7252]), 1.0);
                float _3643 = _3640.x;
                bool _3644 = _3643 < 0.0;
                bool _3651;
                if (!_3644)
                {
                    _3651 = _3643 > 1.0;
                }
                else
                {
                    _3651 = _3644;
                }
                bool _3658;
                if (!_3651)
                {
                    _3658 = _3640.y < 0.0;
                }
                else
                {
                    _3658 = _3651;
                }
                bool _3665;
                if (!_3658)
                {
                    _3665 = _3640.y > 1.0;
                }
                else
                {
                    _3665 = _3658;
                }
                if (_3665)
                {
                    _7265 = 1.0;
                    break;
                }
                float2 _3678 = float2(float(_7252 & 1), float(_7252 >> 1)) * _193._m23.xy;
                float _3685 = fast::min(_3640.z, 1.0) - _193._m19[_7252];
                float2 _3704 = _193._m22.xy * 0.5;
                float2 _3709 = _3678 + (_3640.xy * _193._m23.xy);
                float4 _3722 = float4(_3678 + _3704, (_3678 + _193._m23.xy) - _3704);
                float _7264;
                do
                {
                    int _3748 = int(_193._m22.z);
                    if (_3748 <= 0)
                    {
                        _7264 = spvDepthCast(_213).sample_compare(_213Smplr, float3(fast::clamp(_3709, _3722.xy, _3722.zw), _3685).xy, _3685);
                        break;
                    }
                    float2 _3771 = (_3709 / _193._m22.xy) + float2(0.5);
                    float2 _3772 = floor(_3771);
                    float2 _3777 = _3771 - _3772;
                    float2 _3780 = _3772 - float2(0.5);
                    bool _3784 = _3748 == 1;
                    spvUnsafeArray<float2, 3> _3732;
                    spvUnsafeArray<float2, 3> _3733;
                    if (_3784)
                    {
                        float2 _3787 = _3777 * 2.0;
                        _3732[0] = float2(3.0) - _3787;
                        _3732[1] = float2(1.0) + _3787;
                        _3733[0] = ((float2(2.0) - _3777) / _3732[0]) - float2(1.0);
                        _3733[1] = (_3777 / _3732[1]) + float2(1.0);
                    }
                    else
                    {
                        float2 _3814 = _3777 * 3.0;
                        _3732[0] = float2(4.0) - _3814;
                        _3732[1] = float2(7.0);
                        _3732[2] = float2(1.0) + _3814;
                        _3733[0] = ((float2(3.0) - (_3777 * 2.0)) / _3732[0]) - float2(2.0);
                        _3733[1] = (float2(3.0) + _3777) / _3732[1];
                        _3733[2] = (_3777 / _3732[2]) + float2(2.0);
                    }
                    int _8021 = _3784 ? 2 : 3;
                    int _7254;
                    float _7257;
                    _7257 = 0.0;
                    _7254 = 0;
                    float _7263;
                    for (; _7254 < _8021; _7257 = _7263, _7254++)
                    {
                        _7263 = _7257;
                        for (int _7260 = 0; _7260 < _8021; )
                        {
                            _7263 += ((_3732[_7260].x * _3732[_7254].y) * spvDepthCast(_213).sample_compare(_213Smplr, float3(fast::clamp(_193._m22.xy * (_3780 + float2(_3733[_7260].x, _3733[_7254].y)), _3722.xy, _3722.zw), _3685).xy, _3685));
                            _7260++;
                            continue;
                        }
                    }
                    _7264 = _7257 * (_3784 ? 0.0625 : 0.0069444444961845874786376953125);
                    break;
                } while(false);
                _7265 = _7264;
                break;
            } while(false);
            float3 _7302;
            float _7305;
            if (_3524 > _193._m17[_7252])
            {
                float _3578 = (_3524 - _193._m17[_7252]) / (_193._m16[_7252] - _193._m17[_7252]);
                int _3580 = _7252 + 1;
                float3 _7303;
                float _7306;
                if (_3580 < _3516)
                {
                    float _7285;
                    do
                    {
                        float4 _3927 = _193._m14[_3580] * float4(in.m_1691 + (_2326 * _193._m18[_3580]), 1.0);
                        float _3930 = _3927.x;
                        bool _3931 = _3930 < 0.0;
                        bool _3938;
                        if (!_3931)
                        {
                            _3938 = _3930 > 1.0;
                        }
                        else
                        {
                            _3938 = _3931;
                        }
                        bool _3945;
                        if (!_3938)
                        {
                            _3945 = _3927.y < 0.0;
                        }
                        else
                        {
                            _3945 = _3938;
                        }
                        bool _3952;
                        if (!_3945)
                        {
                            _3952 = _3927.y > 1.0;
                        }
                        else
                        {
                            _3952 = _3945;
                        }
                        if (_3952)
                        {
                            _7285 = 1.0;
                            break;
                        }
                        float2 _3965 = float2(float(_3580 & 1), float(_3580 >> 1)) * _193._m23.xy;
                        float _3972 = fast::min(_3927.z, 1.0) - _193._m19[_3580];
                        float2 _3991 = _193._m22.xy * 0.5;
                        float2 _3996 = _3965 + (_3927.xy * _193._m23.xy);
                        float4 _4009 = float4(_3965 + _3991, (_3965 + _193._m23.xy) - _3991);
                        float _7284;
                        do
                        {
                            int _4035 = int(_193._m22.z);
                            if (_4035 <= 0)
                            {
                                _7284 = spvDepthCast(_213).sample_compare(_213Smplr, float3(fast::clamp(_3996, _4009.xy, _4009.zw), _3972).xy, _3972);
                                break;
                            }
                            float2 _4058 = (_3996 / _193._m22.xy) + float2(0.5);
                            float2 _4059 = floor(_4058);
                            float2 _4064 = _4058 - _4059;
                            float2 _4067 = _4059 - float2(0.5);
                            bool _4071 = _4035 == 1;
                            spvUnsafeArray<float2, 3> _4019;
                            spvUnsafeArray<float2, 3> _4020;
                            if (_4071)
                            {
                                float2 _4074 = _4064 * 2.0;
                                _4019[0] = float2(3.0) - _4074;
                                _4019[1] = float2(1.0) + _4074;
                                _4020[0] = ((float2(2.0) - _4064) / _4019[0]) - float2(1.0);
                                _4020[1] = (_4064 / _4019[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _4101 = _4064 * 3.0;
                                _4019[0] = float2(4.0) - _4101;
                                _4019[1] = float2(7.0);
                                _4019[2] = float2(1.0) + _4101;
                                _4020[0] = ((float2(3.0) - (_4064 * 2.0)) / _4019[0]) - float2(2.0);
                                _4020[1] = (float2(3.0) + _4064) / _4019[1];
                                _4020[2] = (_4064 / _4019[2]) + float2(2.0);
                            }
                            int _8023 = _4071 ? 2 : 3;
                            int _7274;
                            float _7277;
                            _7277 = 0.0;
                            _7274 = 0;
                            float _7283;
                            for (; _7274 < _8023; _7277 = _7283, _7274++)
                            {
                                _7283 = _7277;
                                for (int _7280 = 0; _7280 < _8023; )
                                {
                                    _7283 += ((_4019[_7280].x * _4019[_7274].y) * spvDepthCast(_213).sample_compare(_213Smplr, float3(fast::clamp(_193._m22.xy * (_4067 + float2(_4020[_7280].x, _4020[_7274].y)), _4009.xy, _4009.zw), _3972).xy, _3972));
                                    _7280++;
                                    continue;
                                }
                            }
                            _7284 = _7277 * (_4071 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _7285 = _7284;
                        break;
                    } while(false);
                    _7306 = mix(_7265, _7285, _3578);
                    _7303 = mix(_567[_7252], _567[_3580], float3(_3578));
                }
                else
                {
                    _7306 = mix(_7265, 1.0, _3578);
                    _7303 = _567[_7252];
                }
                _7305 = _7306;
                _7302 = _7303;
            }
            else
            {
                _7305 = _7265;
                _7302 = _567[_7252];
            }
            _7308 = select(float3(1.0), _7302, bool3(_193._m22.w > 0.5));
            _7307 = _7305;
            break;
        } while(false);
        _7471 = _7307;
        _7431 = _7337 * _7308;
    }
    else
    {
        _7471 = 1.0;
        _7431 = _7337;
    }
    float3 _2357 = _193._m5.xyz * _193._m4.w;
    bool _2361 = _1531._m6.w > 0.5;
    float _7360;
    if (_2361)
    {
        _7360 = 1.0;
    }
    else
    {
        _7360 = 1.0 + (_1531._m4.w * (_2007.sample(_1230, _2074).x - 1.0));
    }
    float _2381 = abs(in.m_1607.w);
    float _7561;
    if (_2381 > 0.0)
    {
        _7561 = _7360 * fast::min(_2381, 1.0);
    }
    else
    {
        _7561 = _7360;
    }
    float3 _7719;
    if (!_2278)
    {
        float _2397 = dot(_7437, _2308);
        float3 _7711;
        if (_193._m29.x > 0.5)
        {
            float _4252 = (_193._m29.z * _7437.x) - (_193._m29.w * _7437.z);
            float _4265 = (_193._m29.w * _7437.x) + (_193._m29.z * _7437.z);
            float _4283 = 1.09254801273345947265625 * _4252;
            spvUnsafeArray<float, 9> _7015 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _7437.y, 0.48860299587249755859375 * _4265, 0.48860299587249755859375 * _4252, _4283 * _7437.y, (1.09254801273345947265625 * _7437.y) * _4265, 0.3153919875621795654296875 * (((3.0 * _4265) * _4265) - 1.0), _4283 * _4265, 0.546274006366729736328125 * ((_4252 * _4252) - (_7437.y * _7437.y)) });
            spvUnsafeArray<float, 9> _4197 = _7015;
            float3 _7710;
            _7710 = float3(0.0);
            for (int _7709 = 0; _7709 < 9; )
            {
                _7710 += (_1228.read(uint2((int2(496, 256) + int2(_7709, 0))), 0).xyz * _4197[_7709]);
                _7709++;
                continue;
            }
            _7711 = fast::max(_7710, float3(0.0)) * _193._m29.y;
        }
        else
        {
            _7711 = mix(_193._m9.xyz, _193._m8.xyz, float3((_7437.y * 0.5) + 0.5)) * _193._m8.w;
        }
        float3 _2447 = (_7431 * ((_7711 * _7561) + ((_2357 * fast::max(_2397, 0.0)) * _7471))) + ((_2357 * ((powr(fast::max(dot(_7437, _2320), 0.0), _1531._m1.w) * _1531._m1.z) * step(0.0, _2397))) * _7471);
        float3 _7720;
        if (_193._m13.w > 0.5)
        {
            float2 _4368 = fast::clamp(floor(gl_FragCoord.xy * _193._m12.xy), float2(0.0), _193._m13.xy - float2(1.0));
            uint _4396 = uint((((fast::clamp(floor((log2(fast::max(dot(_193._m11.xyz, in.m_1691) + _193._m11.w, 9.9999999747524270787835121154785e-07)) * _193._m12.z) + _193._m12.w), 0.0, _193._m13.z - 1.0) * _193._m13.y) + _4368.y) * _193._m13.x) + _4368.x);
            uint _4398 = _4396 >> uint(2);
            uint _4400 = _4396 & 3u;
            uint _4404 = _1822._m0[_4398][_4400] & 65535u;
            uint _4406 = _1822._m0[_4398][_4400] >> uint(16);
            float3 _7721;
            _7721 = _2447;
            float3 _2527;
            spvUnsafeArray<float2, 3> _4814;
            spvUnsafeArray<float2, 3> _4815;
            spvUnsafeArray<float2, 3> _5027;
            spvUnsafeArray<float2, 3> _5028;
            for (uint _7718 = _4404; _7718 < (_4404 + _4406); _7721 = _2527, _7718++)
            {
                uint _4412 = _7718 / 3u;
                uint _4425 = (_1843._m0[_4412 >> uint(2)][_4412 & 3u] >> ((_7718 - (_4412 * 3u)) * 10u)) & 1023u;
                float3 _4442 = _1684._m0[_4425].xyz - in.m_1691;
                float _4445 = dot(_4442, _4442);
                float _4449 = _4445 * _1684._m0[_4425].w;
                float _4454 = fast::clamp(1.0 - (_4449 * _4449), 0.0, 1.0);
                float3 _4459 = _4442 * rsqrt(fast::max(_4445, 9.9999999392252902907785028219223e-09));
                float _4477 = fast::clamp((dot(-_4459, _1727._m0[_4425].xyz) * _1719._m0[_4425].w) + _1727._m0[_4425].w, 0.0, 1.0);
                float3 _4490 = _1719._m0[_4425].xyz * ((((_4454 * _4454) * _4477) * _4477) / fast::max(_4445, 9.9999997473787516355514526367188e-05));
                float3 _7926;
                if (_2331)
                {
                    float _7872;
                    do
                    {
                        uint _4526 = uint(_193._m21.z);
                        if (_4425 < _4526)
                        {
                            float _4548 = _193._m26[_4425].z * fast::max((_193._m15[_4425] * float4(in.m_1691, 1.0)).w, 0.0);
                            float4 _4572 = _193._m15[_4425] * float4((in.m_1691 + (_2326 * (_4548 * _193._m25.x))) + (_4459 * (_4548 * _193._m25.y)), 1.0);
                            float _4574 = _4572.w;
                            if (_4574 <= 0.0)
                            {
                                _7872 = 1.0;
                                break;
                            }
                            float3 _4583 = _4572.xyz / float3(_4574);
                            float _4585 = _4583.x;
                            bool _4586 = _4585 < 0.0;
                            bool _4593;
                            if (!_4586)
                            {
                                _4593 = _4585 > 1.0;
                            }
                            else
                            {
                                _4593 = _4586;
                            }
                            bool _4600;
                            if (!_4593)
                            {
                                _4600 = _4583.y < 0.0;
                            }
                            else
                            {
                                _4600 = _4593;
                            }
                            bool _4607;
                            if (!_4600)
                            {
                                _4607 = _4583.y > 1.0;
                            }
                            else
                            {
                                _4607 = _4600;
                            }
                            bool _4614;
                            if (!_4607)
                            {
                                _4614 = _4583.z > 1.0;
                            }
                            else
                            {
                                _4614 = _4607;
                            }
                            if (_4614)
                            {
                                _7872 = 1.0;
                                break;
                            }
                            float _4620 = _4583.z;
                            float2 _4786 = _193._m22.xy * 0.5;
                            float2 _4791 = _193._m26[_4425].xy + (_4583.xy * _193._m23.zw);
                            float4 _4804 = float4(_193._m26[_4425].xy + _4786, (_193._m26[_4425].xy + _193._m23.zw) - _4786);
                            float _7871;
                            do
                            {
                                int _4830 = int(_193._m22.z);
                                if (_4830 <= 0)
                                {
                                    float2 _4840 = fast::clamp(_4791, _4804.xy, _4804.zw);
                                    _7871 = spvDepthCast(_213).sample_compare(_213Smplr, float3(_4840, _4620).xy, _4620);
                                    break;
                                }
                                float2 _4853 = (_4791 / _193._m22.xy) + float2(0.5);
                                float2 _4854 = floor(_4853);
                                float2 _4859 = _4853 - _4854;
                                float2 _4862 = _4854 - float2(0.5);
                                bool _4866 = _4830 == 1;
                                if (_4866)
                                {
                                    float2 _4869 = _4859 * 2.0;
                                    _4814[0] = float2(3.0) - _4869;
                                    _4814[1] = float2(1.0) + _4869;
                                    _4815[0] = ((float2(2.0) - _4859) / _4814[0]) - float2(1.0);
                                    _4815[1] = (_4859 / _4814[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _4896 = _4859 * 3.0;
                                    _4814[0] = float2(4.0) - _4896;
                                    _4814[1] = float2(7.0);
                                    _4814[2] = float2(1.0) + _4896;
                                    _4815[0] = ((float2(3.0) - (_4859 * 2.0)) / _4814[0]) - float2(2.0);
                                    _4815[1] = (float2(3.0) + _4859) / _4814[1];
                                    _4815[2] = (_4859 / _4814[2]) + float2(2.0);
                                }
                                int _8028 = _4866 ? 2 : 3;
                                int _7861;
                                float _7864;
                                _7864 = 0.0;
                                _7861 = 0;
                                float _7870;
                                for (; _7861 < _8028; _7864 = _7870, _7861++)
                                {
                                    _7870 = _7864;
                                    for (int _7867 = 0; _7867 < _8028; )
                                    {
                                        _7870 += ((_4814[_7867].x * _4814[_7861].y) * spvDepthCast(_213).sample_compare(_213Smplr, float3(fast::clamp(_193._m22.xy * (_4862 + float2(_4815[_7867].x, _4815[_7861].y)), _4804.xy, _4804.zw), _4620).xy, _4620));
                                        _7867++;
                                        continue;
                                    }
                                }
                                _7871 = _7864 * (_4866 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _7872 = _7871;
                            break;
                        }
                        uint _4630 = _4425 - _4526;
                        if (_4630 >= uint(_193._m21.w))
                        {
                            _7872 = 1.0;
                            break;
                        }
                        float _4651 = _193._m27[_4630].w * length(in.m_1691 - _193._m27[_4630].xyz);
                        float3 _4669 = ((in.m_1691 + (_2326 * (_4651 * _193._m25.x))) + (_4459 * (_4651 * _193._m25.y))) - _193._m27[_4630].xyz;
                        float3 _4671 = abs(_4669);
                        float _4673 = _4671.x;
                        float _4675 = _4671.y;
                        bool _4676 = _4673 >= _4675;
                        bool _4684;
                        if (_4676)
                        {
                            _4684 = _4673 >= _4671.z;
                        }
                        else
                        {
                            _4684 = _4676;
                        }
                        float _7846;
                        int _7848;
                        if (_4684)
                        {
                            _7848 = (_4669.x > 0.0) ? 0 : 1;
                            _7846 = _4673;
                        }
                        else
                        {
                            float _4696 = _4671.z;
                            bool _4697 = _4675 >= _4696;
                            int _7849;
                            if (_4697)
                            {
                                _7849 = (_4669.y > 0.0) ? 2 : 3;
                            }
                            else
                            {
                                _7849 = (_4669.z > 0.0) ? 4 : 5;
                            }
                            _7848 = _7849;
                            _7846 = _4697 ? _4675 : _4696;
                        }
                        if (_7846 <= 0.0)
                        {
                            _7872 = 1.0;
                            break;
                        }
                        float2 _4734 = float2(dot(_4669, _871[_7848]), dot(_4669, _880[_7848])) / float2(_7846 * _193._m24.z);
                        float _4741 = _193._m28[_4630].z + (_193._m28[_4630].w / _7846);
                        if (_4741 > 1.0)
                        {
                            _7872 = 1.0;
                            break;
                        }
                        float2 _4759 = _193._m28[_4630].xy + (float2(float(spvSMod(_7848, 3)), float(_7848 / 3)) * _193._m24.xy);
                        float2 _4999 = _193._m22.xy * 0.5;
                        float2 _5004 = _4759 + (float2(0.5 + (0.5 * _4734.x), 0.5 - (0.5 * _4734.y)) * _193._m24.xy);
                        float4 _5017 = float4(_4759 + _4999, (_4759 + _193._m24.xy) - _4999);
                        float _7860;
                        do
                        {
                            int _5043 = int(_193._m22.z);
                            if (_5043 <= 0)
                            {
                                _7860 = spvDepthCast(_213).sample_compare(_213Smplr, float3(fast::clamp(_5004, _5017.xy, _5017.zw), _4741).xy, _4741);
                                break;
                            }
                            float2 _5066 = (_5004 / _193._m22.xy) + float2(0.5);
                            float2 _5067 = floor(_5066);
                            float2 _5072 = _5066 - _5067;
                            float2 _5075 = _5067 - float2(0.5);
                            bool _5079 = _5043 == 1;
                            if (_5079)
                            {
                                float2 _5082 = _5072 * 2.0;
                                _5027[0] = float2(3.0) - _5082;
                                _5027[1] = float2(1.0) + _5082;
                                _5028[0] = ((float2(2.0) - _5072) / _5027[0]) - float2(1.0);
                                _5028[1] = (_5072 / _5027[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _5109 = _5072 * 3.0;
                                _5027[0] = float2(4.0) - _5109;
                                _5027[1] = float2(7.0);
                                _5027[2] = float2(1.0) + _5109;
                                _5028[0] = ((float2(3.0) - (_5072 * 2.0)) / _5027[0]) - float2(2.0);
                                _5028[1] = (float2(3.0) + _5072) / _5027[1];
                                _5028[2] = (_5072 / _5027[2]) + float2(2.0);
                            }
                            int _8031 = _5079 ? 2 : 3;
                            int _7850;
                            float _7853;
                            _7853 = 0.0;
                            _7850 = 0;
                            float _7859;
                            for (; _7850 < _8031; _7853 = _7859, _7850++)
                            {
                                _7859 = _7853;
                                for (int _7856 = 0; _7856 < _8031; )
                                {
                                    _7859 += ((_5027[_7856].x * _5027[_7850].y) * spvDepthCast(_213).sample_compare(_213Smplr, float3(fast::clamp(_193._m22.xy * (_5075 + float2(_5028[_7856].x, _5028[_7850].y)), _5017.xy, _5017.zw), _4741).xy, _4741));
                                    _7856++;
                                    continue;
                                }
                            }
                            _7860 = _7853 * (_5079 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _7872 = _7860;
                        break;
                    } while(false);
                    _7926 = _4490 * _7872;
                }
                else
                {
                    _7926 = _4490;
                }
                float _2498 = dot(_7437, _4459);
                _2527 = _7721 + (((_7431 * fast::max(_2498, 0.0)) * _7926) + (_7926 * ((powr(fast::max(dot(_7437, fast::normalize(_4459 + _2315)), 0.0), _1531._m1.w) * _1531._m1.z) * step(0.0, _2498))));
            }
            _7720 = _7721;
        }
        else
        {
            _7720 = _2447;
        }
        _7719 = _7720;
    }
    else
    {
        float4 _2537 = _2532.sample(_1230, _2074);
        float _2544 = fast::clamp(_1531._m4.x * _2537.z, 0.0, 1.0);
        float _2552 = fast::clamp(_1531._m4.y * _2537.y, 0.04500000178813934326171875, 1.0);
        float _7427;
        float _7432;
        if (_7368 > 0.0)
        {
            _7432 = mix(_2544, _7401.y, _7368);
            _7427 = mix(_2552, fast::max(_7401.x, 0.04500000178813934326171875), _7368);
        }
        else
        {
            _7432 = _2544;
            _7427 = _2552;
        }
        float _2571 = _7427 * _7427;
        float3 _2576 = _7431 * (1.0 - _7432);
        float3 _2582 = mix(float3(0.039999999105930328369140625), _7431, float3(_7432));
        bool _2586 = _7247 > 0.0;
        float3 _7460;
        if (_2586)
        {
            float3 _2591 = dfdx(in.m_1691);
            float3 _2593 = dfdy(in.m_1691);
            float3 _2594 = cross(_2591, _2593);
            float3 _7461;
            if (dot(_2594, _2594) > 9.9999996826552253889678874634872e-21)
            {
                _7461 = fast::normalize((fast::normalize(_2594) * ((dot(_2594, _2315) < 0.0) ? (-1.0) : 1.0)) + (_7437 - _2170));
            }
            else
            {
                _7461 = _7437;
            }
            _7460 = _7461;
        }
        else
        {
            _7460 = _7437;
        }
        float _2620 = fast::max(dot(_7460, _2315), 9.9999997473787516355514526367188e-05);
        float _2629 = dot(_7460, _2308);
        float _2630 = fast::clamp(_2629, 0.0, 1.0);
        float _2635 = fast::clamp(dot(_7460, _2320), 0.0, 1.0);
        float _2640 = fast::clamp(dot(_2315, _2320), 0.0, 1.0);
        float _7464;
        float _7465;
        if (_2586)
        {
            _7465 = fast::max(_2620, 0.5);
            _7464 = fast::max(_2640, 0.5);
        }
        else
        {
            _7465 = _2620;
            _7464 = _2640;
        }
        float3 _5211 = float3(1.0) - _2582;
        float3 _5214 = _2582 + (_5211 * powr(1.0 - _7464, 5.0));
        float _5221 = _2571 * _2571;
        float _5226 = _5221 - 1.0;
        float _5228 = ((_2635 * _2635) * _5226) + 1.0;
        float _5248 = 1.0 - _5221;
        float _5252 = sqrt(((_7465 * _7465) * _5248) + _5221);
        float3 _2686 = (((((float3(1.0) - _5214) * _2576) * fast::clamp(dot(_7437, _2308), 0.0, 1.0)) + (((_5214 * ((_5221 / ((3.1415927410125732421875 * _5228) * _5228)) * (0.5 / fast::max((_2630 * _5252) + (_7465 * sqrt(((_2630 * _2630) * _5248) + _5221)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875) * _2630)) * _2357) * _7471;
        float3 _7575;
        if (_2586)
        {
            _7575 = _2686 + (((((_2576 * _2357) * _7471) * _7247) * fast::clamp(-_2629, 0.0, 1.0)) * (0.3499999940395355224609375 + (0.64999997615814208984375 * powr(fast::clamp(dot(-_2315, _2308), 0.0, 1.0), 3.0))));
        }
        else
        {
            _7575 = _2686;
        }
        float3 _7501;
        float2 _7525;
        float3 _7537;
        if (_193._m29.x > 0.5)
        {
            float4 _5285 = _1334.sample(_1336, (((float2(_7465, _7427) * 31.0) + float2(0.5)) * float2(0.03125)));
            float _5344 = (_193._m29.z * _7437.x) - (_193._m29.w * _7437.z);
            float _5357 = (_193._m29.w * _7437.x) + (_193._m29.z * _7437.z);
            float _5375 = 1.09254801273345947265625 * _5344;
            spvUnsafeArray<float, 9> _6996 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _7437.y, 0.48860299587249755859375 * _5357, 0.48860299587249755859375 * _5344, _5375 * _7437.y, (1.09254801273345947265625 * _7437.y) * _5357, 0.3153919875621795654296875 * (((3.0 * _5357) * _5357) - 1.0), _5375 * _5357, 0.546274006366729736328125 * ((_5344 * _5344) - (_7437.y * _7437.y)) });
            spvUnsafeArray<float, 9> _5289 = _6996;
            float3 _7483;
            _7483 = float3(0.0);
            for (int _7482 = 0; _7482 < 9; )
            {
                _7483 += (_1228.read(uint2((int2(496, 256) + int2(_7482, 0))), 0).xyz * _5289[_7482]);
                _7482++;
                continue;
            }
            float3 _2738 = reflect(-_2315, _7460);
            float _5470 = _2738.x;
            float _5475 = _2738.z;
            float2 _5507 = float2((precise::atan2((_193._m29.z * _5470) - (_193._m29.w * _5475), -((_193._m29.w * _5470) + (_193._m29.z * _5475))) * 0.15915493667125701904296875) + 0.5, acos(fast::clamp(_2738.y, -1.0, 1.0)) * 0.3183098733425140380859375);
            float _5439 = _7427 * 5.0;
            int _5442 = min(int(_5439), 4);
            float2 _5528 = (_5507 * float2(_1290[_5442].zw)) - float2(0.5);
            float2 _5530 = floor(_5528);
            float2 _5533 = _5528 - _5530;
            int _5536 = int(_5530.x);
            int _5539 = int(_5530.y);
            int _7486;
            if (_5536 < 0)
            {
                _7486 = _5536 + _1290[_5442].z;
            }
            else
            {
                _7486 = _5536;
            }
            int _7487;
            if (_7486 >= _1290[_5442].z)
            {
                _7487 = _7486 - _1290[_5442].z;
            }
            else
            {
                _7487 = _7486;
            }
            int _5559 = _7487 + 1;
            int _8032 = (_5559 == _1290[_5442].z) ? 0 : _5559;
            int _5574 = min((_5539 + 1), (_1290[_5442].w - 1));
            int _5576 = max(_5539, 0);
            float3 _5629 = float3(_5533.x);
            int _5449 = _5442 + 1;
            float2 _5661 = (_5507 * float2(_1290[_5449].zw)) - float2(0.5);
            float2 _5663 = floor(_5661);
            float2 _5666 = _5661 - _5663;
            int _5669 = int(_5663.x);
            int _5672 = int(_5663.y);
            int _7493;
            if (_5669 < 0)
            {
                _7493 = _5669 + _1290[_5449].z;
            }
            else
            {
                _7493 = _5669;
            }
            int _7494;
            if (_7493 >= _1290[_5449].z)
            {
                _7494 = _7493 - _1290[_5449].z;
            }
            else
            {
                _7494 = _7493;
            }
            int _5692 = _7494 + 1;
            int _8033 = (_5692 == _1290[_5449].z) ? 0 : _5692;
            int _5707 = min((_5672 + 1), (_1290[_5449].w - 1));
            int _5709 = max(_5672, 0);
            float3 _5762 = float3(_5666.x);
            float3 _5464 = mix(mix(mix(_1228.read(uint2((_1290[_5442].xy + int2(_7487, _5576))), 0).xyz, _1228.read(uint2((_1290[_5442].xy + int2(_8032, _5576))), 0).xyz, _5629), mix(_1228.read(uint2((_1290[_5442].xy + int2(_7487, _5574))), 0).xyz, _1228.read(uint2((_1290[_5442].xy + int2(_8032, _5574))), 0).xyz, _5629), float3(_5533.y)), mix(mix(_1228.read(uint2((_1290[_5449].xy + int2(_7494, _5709))), 0).xyz, _1228.read(uint2((_1290[_5449].xy + int2(_8033, _5709))), 0).xyz, _5762), mix(_1228.read(uint2((_1290[_5449].xy + int2(_7494, _5707))), 0).xyz, _1228.read(uint2((_1290[_5449].xy + int2(_8033, _5707))), 0).xyz, _5762), float3(_5666.y)), float3(_5439 - float(_5442))) * _193._m29.y;
            _7537 = fast::max(_7483, float3(0.0)) * _193._m29.y;
            _7525 = _5285.xy;
            _7501 = _5464;
        }
        else
        {
            float4 _5780 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * _7427) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);
            float _5782 = _5780.x;
            float3 _5817 = mix(_193._m9.xyz, _193._m8.xyz, float3((_7437.y * 0.5) + 0.5)) * _193._m8.w;
            _7537 = _5817;
            _7525 = (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_5782 * _5782, exp2((-9.27999973297119140625) * _7465)) * _5782) + _5780.y)) + _5780.zw;
            _7501 = mix(mix(_193._m9.xyz, _193._m8.xyz, float3((reflect(-_2315, _7460).y * 0.5) + 0.5)) * _193._m8.w, _5817, float3(_7427));
        }
        bool _2770;
        if (_2361)
        {
            _2770 = _193._m33.z > 0.5;
        }
        else
        {
            _2770 = _2361;
        }
        float3 _7546;
        if (_2770)
        {
            float3 _7522;
            do
            {
                float _5896 = ((_193._m32.x * (1.0 - smoothstep(_193._m33.x * 0.5, _193._m33.x, abs(dot(_193._m31.xyz, in.m_1691) - _193._m31.w)))) * smoothstep(0.5, 0.89999997615814208984375, dot(_2326, _193._m31.xyz))) * (1.0 - smoothstep(_193._m32.y * 0.5, _193._m32.y, _7427));
                if (_5896 <= 0.0)
                {
                    _7522 = _7501;
                    break;
                }
                float4 _5921 = _193._m30 * float4(in.m_1691 + ((_7437 - (_193._m31.xyz * dot(_7437, _193._m31.xyz))) * _193._m32.w), 1.0);
                float2 _5934 = ((float2(_5921.x, -_5921.y) / float2(_5921.w)) * 0.5) + float2(0.5);
                float _5938 = _193._m32.z * _7427;
                float3 _7520;
                float _7521;
                _7521 = 0.0;
                _7520 = float3(0.0);
                for (int _7519 = 0; _7519 < 12; )
                {
                    float _5945 = float(_7519);
                    float _5953 = _5945 * 2.3999631404876708984375;
                    float2 _5965 = _5934 + (float2(cos(_5953) * _193._m33.y, sin(_5953)) * (sqrt((_5945 + 0.5) * 0.083333335816860198974609375) * _5938));
                    float2 _5970 = fast::min(_5965, float2(1.0) - _5965);
                    float _5976 = smoothstep(0.0, 0.039999999105930328369140625, fast::min(_5970.x, _5970.y));
                    float4 _5984 = _2007.sample(_1230, fast::clamp(_5965, float2(0.0), float2(1.0)), level(0.0));
                    float3 _5986 = _5984.xyz;
                    _7521 += (_5984.w * _5976);
                    _7520 += ((_5986 / (float3(1.0) - fast::min(_5986, float3(0.99500000476837158203125)))) * _5976);
                    _7519++;
                    continue;
                }
                _7522 = mix(_7501, (_7520 * float3(0.083333335816860198974609375)) + (_7501 * (1.0 - (_7521 * 0.083333335816860198974609375))), float3(_5896));
                break;
            } while(false);
            _7546 = _7522;
        }
        else
        {
            _7546 = _7501;
        }
        float3 _2790 = (_2582 * _7525.x) + float3(_7525.y);
        float3 _2806 = _7575 + (((((float3(1.0) - _2790) * _2576) * _7537) + (_2790 * _7546)) * _7561);
        float3 _7722;
        if (_193._m13.w > 0.5)
        {
            float2 _6050 = fast::clamp(floor(gl_FragCoord.xy * _193._m12.xy), float2(0.0), _193._m13.xy - float2(1.0));
            uint _6078 = uint((((fast::clamp(floor((log2(fast::max(dot(_193._m11.xyz, in.m_1691) + _193._m11.w, 9.9999999747524270787835121154785e-07)) * _193._m12.z) + _193._m12.w), 0.0, _193._m13.z - 1.0) * _193._m13.y) + _6050.y) * _193._m13.x) + _6050.x);
            uint _6080 = _6078 >> uint(2);
            uint _6082 = _6078 & 3u;
            uint _6086 = _1822._m0[_6080][_6082] & 65535u;
            uint _6088 = _1822._m0[_6080][_6082] >> uint(16);
            float3 _7675;
            _7675 = _2806;
            float3 _2906;
            spvUnsafeArray<float2, 3> _6496;
            spvUnsafeArray<float2, 3> _6497;
            spvUnsafeArray<float2, 3> _6709;
            spvUnsafeArray<float2, 3> _6710;
            for (uint _7578 = _6086; _7578 < (_6086 + _6088); _7675 = _2906, _7578++)
            {
                uint _6094 = _7578 / 3u;
                uint _6107 = (_1843._m0[_6094 >> uint(2)][_6094 & 3u] >> ((_7578 - (_6094 * 3u)) * 10u)) & 1023u;
                float3 _6124 = _1684._m0[_6107].xyz - in.m_1691;
                float _6127 = dot(_6124, _6124);
                float _6131 = _6127 * _1684._m0[_6107].w;
                float _6136 = fast::clamp(1.0 - (_6131 * _6131), 0.0, 1.0);
                float3 _6141 = _6124 * rsqrt(fast::max(_6127, 9.9999999392252902907785028219223e-09));
                float _6159 = fast::clamp((dot(-_6141, _1727._m0[_6107].xyz) * _1719._m0[_6107].w) + _1727._m0[_6107].w, 0.0, 1.0);
                float3 _6172 = _1719._m0[_6107].xyz * ((((_6136 * _6136) * _6159) * _6159) / fast::max(_6127, 9.9999997473787516355514526367188e-05));
                float3 _7673;
                if (_2331)
                {
                    float _7605;
                    do
                    {
                        uint _6208 = uint(_193._m21.z);
                        if (_6107 < _6208)
                        {
                            float _6230 = _193._m26[_6107].z * fast::max((_193._m15[_6107] * float4(in.m_1691, 1.0)).w, 0.0);
                            float4 _6254 = _193._m15[_6107] * float4((in.m_1691 + (_2326 * (_6230 * _193._m25.x))) + (_6141 * (_6230 * _193._m25.y)), 1.0);
                            float _6256 = _6254.w;
                            if (_6256 <= 0.0)
                            {
                                _7605 = 1.0;
                                break;
                            }
                            float3 _6265 = _6254.xyz / float3(_6256);
                            float _6267 = _6265.x;
                            bool _6268 = _6267 < 0.0;
                            bool _6275;
                            if (!_6268)
                            {
                                _6275 = _6267 > 1.0;
                            }
                            else
                            {
                                _6275 = _6268;
                            }
                            bool _6282;
                            if (!_6275)
                            {
                                _6282 = _6265.y < 0.0;
                            }
                            else
                            {
                                _6282 = _6275;
                            }
                            bool _6289;
                            if (!_6282)
                            {
                                _6289 = _6265.y > 1.0;
                            }
                            else
                            {
                                _6289 = _6282;
                            }
                            bool _6296;
                            if (!_6289)
                            {
                                _6296 = _6265.z > 1.0;
                            }
                            else
                            {
                                _6296 = _6289;
                            }
                            if (_6296)
                            {
                                _7605 = 1.0;
                                break;
                            }
                            float _6302 = _6265.z;
                            float2 _6468 = _193._m22.xy * 0.5;
                            float2 _6473 = _193._m26[_6107].xy + (_6265.xy * _193._m23.zw);
                            float4 _6486 = float4(_193._m26[_6107].xy + _6468, (_193._m26[_6107].xy + _193._m23.zw) - _6468);
                            float _7604;
                            do
                            {
                                int _6512 = int(_193._m22.z);
                                if (_6512 <= 0)
                                {
                                    float2 _6522 = fast::clamp(_6473, _6486.xy, _6486.zw);
                                    _7604 = spvDepthCast(_213).sample_compare(_213Smplr, float3(_6522, _6302).xy, _6302);
                                    break;
                                }
                                float2 _6535 = (_6473 / _193._m22.xy) + float2(0.5);
                                float2 _6536 = floor(_6535);
                                float2 _6541 = _6535 - _6536;
                                float2 _6544 = _6536 - float2(0.5);
                                bool _6548 = _6512 == 1;
                                if (_6548)
                                {
                                    float2 _6551 = _6541 * 2.0;
                                    _6496[0] = float2(3.0) - _6551;
                                    _6496[1] = float2(1.0) + _6551;
                                    _6497[0] = ((float2(2.0) - _6541) / _6496[0]) - float2(1.0);
                                    _6497[1] = (_6541 / _6496[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _6578 = _6541 * 3.0;
                                    _6496[0] = float2(4.0) - _6578;
                                    _6496[1] = float2(7.0);
                                    _6496[2] = float2(1.0) + _6578;
                                    _6497[0] = ((float2(3.0) - (_6541 * 2.0)) / _6496[0]) - float2(2.0);
                                    _6497[1] = (float2(3.0) + _6541) / _6496[1];
                                    _6497[2] = (_6541 / _6496[2]) + float2(2.0);
                                }
                                int _8035 = _6548 ? 2 : 3;
                                int _7594;
                                float _7597;
                                _7597 = 0.0;
                                _7594 = 0;
                                float _7603;
                                for (; _7594 < _8035; _7597 = _7603, _7594++)
                                {
                                    _7603 = _7597;
                                    for (int _7600 = 0; _7600 < _8035; )
                                    {
                                        _7603 += ((_6496[_7600].x * _6496[_7594].y) * spvDepthCast(_213).sample_compare(_213Smplr, float3(fast::clamp(_193._m22.xy * (_6544 + float2(_6497[_7600].x, _6497[_7594].y)), _6486.xy, _6486.zw), _6302).xy, _6302));
                                        _7600++;
                                        continue;
                                    }
                                }
                                _7604 = _7597 * (_6548 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _7605 = _7604;
                            break;
                        }
                        uint _6312 = _6107 - _6208;
                        if (_6312 >= uint(_193._m21.w))
                        {
                            _7605 = 1.0;
                            break;
                        }
                        float _6333 = _193._m27[_6312].w * length(in.m_1691 - _193._m27[_6312].xyz);
                        float3 _6351 = ((in.m_1691 + (_2326 * (_6333 * _193._m25.x))) + (_6141 * (_6333 * _193._m25.y))) - _193._m27[_6312].xyz;
                        float3 _6353 = abs(_6351);
                        float _6355 = _6353.x;
                        float _6357 = _6353.y;
                        bool _6358 = _6355 >= _6357;
                        bool _6366;
                        if (_6358)
                        {
                            _6366 = _6355 >= _6353.z;
                        }
                        else
                        {
                            _6366 = _6358;
                        }
                        float _7579;
                        int _7581;
                        if (_6366)
                        {
                            _7581 = (_6351.x > 0.0) ? 0 : 1;
                            _7579 = _6355;
                        }
                        else
                        {
                            float _6378 = _6353.z;
                            bool _6379 = _6357 >= _6378;
                            int _7582;
                            if (_6379)
                            {
                                _7582 = (_6351.y > 0.0) ? 2 : 3;
                            }
                            else
                            {
                                _7582 = (_6351.z > 0.0) ? 4 : 5;
                            }
                            _7581 = _7582;
                            _7579 = _6379 ? _6357 : _6378;
                        }
                        if (_7579 <= 0.0)
                        {
                            _7605 = 1.0;
                            break;
                        }
                        float2 _6416 = float2(dot(_6351, _871[_7581]), dot(_6351, _880[_7581])) / float2(_7579 * _193._m24.z);
                        float _6423 = _193._m28[_6312].z + (_193._m28[_6312].w / _7579);
                        if (_6423 > 1.0)
                        {
                            _7605 = 1.0;
                            break;
                        }
                        float2 _6441 = _193._m28[_6312].xy + (float2(float(spvSMod(_7581, 3)), float(_7581 / 3)) * _193._m24.xy);
                        float2 _6681 = _193._m22.xy * 0.5;
                        float2 _6686 = _6441 + (float2(0.5 + (0.5 * _6416.x), 0.5 - (0.5 * _6416.y)) * _193._m24.xy);
                        float4 _6699 = float4(_6441 + _6681, (_6441 + _193._m24.xy) - _6681);
                        float _7593;
                        do
                        {
                            int _6725 = int(_193._m22.z);
                            if (_6725 <= 0)
                            {
                                _7593 = spvDepthCast(_213).sample_compare(_213Smplr, float3(fast::clamp(_6686, _6699.xy, _6699.zw), _6423).xy, _6423);
                                break;
                            }
                            float2 _6748 = (_6686 / _193._m22.xy) + float2(0.5);
                            float2 _6749 = floor(_6748);
                            float2 _6754 = _6748 - _6749;
                            float2 _6757 = _6749 - float2(0.5);
                            bool _6761 = _6725 == 1;
                            if (_6761)
                            {
                                float2 _6764 = _6754 * 2.0;
                                _6709[0] = float2(3.0) - _6764;
                                _6709[1] = float2(1.0) + _6764;
                                _6710[0] = ((float2(2.0) - _6754) / _6709[0]) - float2(1.0);
                                _6710[1] = (_6754 / _6709[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _6791 = _6754 * 3.0;
                                _6709[0] = float2(4.0) - _6791;
                                _6709[1] = float2(7.0);
                                _6709[2] = float2(1.0) + _6791;
                                _6710[0] = ((float2(3.0) - (_6754 * 2.0)) / _6709[0]) - float2(2.0);
                                _6710[1] = (float2(3.0) + _6754) / _6709[1];
                                _6710[2] = (_6754 / _6709[2]) + float2(2.0);
                            }
                            int _8038 = _6761 ? 2 : 3;
                            int _7583;
                            float _7586;
                            _7586 = 0.0;
                            _7583 = 0;
                            float _7592;
                            for (; _7583 < _8038; _7586 = _7592, _7583++)
                            {
                                _7592 = _7586;
                                for (int _7589 = 0; _7589 < _8038; )
                                {
                                    _7592 += ((_6709[_7589].x * _6709[_7583].y) * spvDepthCast(_213).sample_compare(_213Smplr, float3(fast::clamp(_193._m22.xy * (_6757 + float2(_6710[_7589].x, _6710[_7583].y)), _6699.xy, _6699.zw), _6423).xy, _6423));
                                    _7589++;
                                    continue;
                                }
                            }
                            _7593 = _7586 * (_6761 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _7605 = _7593;
                        break;
                    } while(false);
                    _7673 = _6172 * _7605;
                }
                else
                {
                    _7673 = _6172;
                }
                float3 _2858 = fast::normalize(_6141 + _2315);
                float _2863 = fast::clamp(dot(_7437, _6141), 0.0, 1.0);
                float _2868 = fast::clamp(dot(_7437, _2858), 0.0, 1.0);
                float3 _6896 = _2582 + (_5211 * powr(1.0 - fast::clamp(dot(_2315, _2858), 0.0, 1.0), 5.0));
                float _6910 = ((_2868 * _2868) * _5226) + 1.0;
                _2906 = _7675 + (((((float3(1.0) - _6896) * _2576) + ((_6896 * ((_5221 / ((3.1415927410125732421875 * _6910) * _6910)) * (0.5 / fast::max((_2863 * _5252) + (_7465 * sqrt(((_2863 * _2863) * _5248) + _5221)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875)) * _2863) * _7673);
            }
            _7722 = _7675;
        }
        else
        {
            _7722 = _2806;
        }
        _7719 = _7722;
    }
    float4 _2923 = _2918.sample(_1230, _2074);
    float _2941 = -length(_2314);
    float _7764;
    if (_193._m9.w != 0.0)
    {
        float _2965 = _193._m9.w * (in.m_1691 - _193._m6.xyz).y;
        float _7761;
        if (abs(_2965) < 9.9999997473787516355514526367188e-05)
        {
            _7761 = 1.0 - (0.5 * _2965);
        }
        else
        {
            _7761 = (1.0 - exp(fast::min(-_2965, 60.0))) / _2965;
        }
        _7764 = 1.0 - exp((_2941 * (_193._m7.w * exp(fast::min((-_193._m9.w) * (_193._m6.y - _193._m6.w), 30.0)))) * _7761);
    }
    else
    {
        _7764 = 1.0 - exp(_2941 * _193._m7.w);
    }
    float3 _3016 = mix(mix(_7719, _7431, float3(_1531._m1.y)) + ((_1531._m5.xyz * _2923.xyz) * (float3(1.0) + in.m_2328.yzw)), _193._m7.xyz, float3(_7764));
    float3 _7765;
    if (_193._m33.w > 0.5)
    {
        _7765 = _3016 / (float3(1.0) + _3016);
    }
    else
    {
        _7765 = _3016;
    }
    out.m_3028 = float4(_7765, in.m_2083.w);
    float2 _7845;
    do
    {
        if (in.m_3038.w <= 0.0)
        {
            _7845 = float2(0.0);
            break;
        }
        _7845 = ((in.m_3038.xy / float2(in.m_3038.w)) - (in.m_3037.xy / float2(in.m_3037.w))) * float2(0.5, -0.5);
        break;
    } while(false);
    out.m_3036 = _7845;
    return out;
}

