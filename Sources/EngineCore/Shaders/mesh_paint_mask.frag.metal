// Generated from mesh_paint_mask.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 4b017794001962cc
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

struct _190
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

struct _1577
{
    float4 _m0;
    float4 _m1;
    float4 _m2;
    float4 _m3;
    float4 _m4;
    float4 _m5;
    float4 _m6;
};

struct _1732
{
    float4 _m0[1024];
};

struct _1767
{
    float4 _m0[1024];
};

struct _1775
{
    float4 _m0[1024];
};

struct _1870
{
    uint4 _m0[1024];
};

struct _1891
{
    uint4 _m0[1024];
};

constant spvUnsafeArray<float3, 4> _566 = spvUnsafeArray<float3, 4>({ float3(1.0, 0.449999988079071044921875, 0.449999988079071044921875), float3(0.449999988079071044921875, 1.0, 0.449999988079071044921875), float3(0.5, 0.60000002384185791015625, 1.0), float3(1.0, 1.0, 0.4000000059604644775390625) });
constant spvUnsafeArray<float3, 6> _870 = spvUnsafeArray<float3, 6>({ float3(0.0, 0.0, 1.0), float3(0.0, 0.0, -1.0), float3(-1.0, 0.0, 0.0), float3(-1.0, 0.0, 0.0), float3(-1.0, 0.0, 0.0), float3(1.0, 0.0, 0.0) });
constant spvUnsafeArray<float3, 6> _879 = spvUnsafeArray<float3, 6>({ float3(0.0, 1.0, 0.0), float3(0.0, 1.0, 0.0), float3(0.0, 0.0, -1.0), float3(0.0, 0.0, 1.0), float3(0.0, 1.0, 0.0), float3(0.0, 1.0, 0.0) });
constant spvUnsafeArray<int4, 6> _1289 = spvUnsafeArray<int4, 6>({ int4(0, 0, 512, 256), int4(0, 256, 256, 128), int4(256, 256, 128, 64), int4(384, 256, 64, 32), int4(448, 256, 32, 16), int4(480, 256, 16, 8) });

struct fragment_main_out
{
    float4 m_3096 [[color(0)]];
    float2 m_3104 [[color(1)]];
};

struct fragment_main_in
{
    float3 m_1741 [[user(locn0)]];
    float3 m_1649 [[user(locn1)]];
    float2 m_2110 [[user(locn2)]];
    float4 m_2133 [[user(locn3)]];
    float3 m_1684 [[user(locn4)]];
    float4 m_2385 [[user(locn5)]];
    float4 m_3105 [[user(locn6)]];
    float4 m_3106 [[user(locn7)]];
    float4 m_1655 [[user(locn8)]];
    float4 m_2166 [[user(locn9)]];
    float4 m_2602 [[user(locn10)]];
};

fragment fragment_main_out fragment_main(fragment_main_in in [[stage_in]], constant _1577& _1579 [[buffer(2)]], constant _1732& _1734 [[buffer(3)]], constant _1767& _1769 [[buffer(4)]], constant _1775& _1777 [[buffer(5)]], constant _1870& _1872 [[buffer(6)]], constant _1891& _1893 [[buffer(7)]], constant _190& _192 [[buffer(15)]], texture2d<float> _212 [[texture(0)]], texture2d<float> _2126 [[texture(1)]], texture2d<float> _2590 [[texture(2)]], texture2d<float> _2262 [[texture(3)]], texture2d<float> _2057 [[texture(4)]], texture2d<float> _2983 [[texture(5)]], texture2d<float> _1227 [[texture(6)]], texture2d<float> _1333 [[texture(7)]], sampler _212Smplr [[sampler(0)]], sampler _1229 [[sampler(1)]], sampler _1335 [[sampler(7)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])
{
    fragment_main_out out = {};
    float2 _2124 = float2(dot(_1579._m2.xy, in.m_2110) + _1579._m2.z, dot(_1579._m3.xy, in.m_2110) + _1579._m3.z);
    float4 _2131 = _2126.sample(_1229, _2124);
    float3 _2141 = _2131.xyz;
    if ((_1579._m0.w * _2131.w) < _1579._m6.x)
    {
        discard_fragment();
    }
    float3 _2170 = ((in.m_2133.xyz * _1579._m0.xyz) * _2141) * in.m_2166.xyz;
    float3 _7707;
    if (_1579._m1.x > 0.5)
    {
        float2 _2185 = floor(in.m_1741.xz * float2(0.5));
        _7707 = _2170 * ((mod(abs(_2185.x + _2185.y), 2.0) < 0.5) ? 1.0 : 0.75);
    }
    else
    {
        _7707 = _2170;
    }
    float3 _7804;
    float _7835;
    float2 _7868;
    if (_1579._m3.w > 0.5)
    {
        float3 _3224;
        float2 _3231;
        float _7705;
        do
        {
            float3 _3195 = float4(_1579._m2.w, _1579._m3.w, 0.0, 0.0).xyy;
            float3 _3198 = floor(_3195 * float3(1.52587890625e-05));
            float3 _3203 = _3195 - (_3198 * 65536.0);
            float3 _3206 = floor(_3203 * float3(0.00390625));
            float3 _3214 = _3203 - (_3206 * 256.0);
            _3224 = (float3(_3214.x, _3206.x, _3198.x) * float3(0.0039215688593685626983642578125)) * 2.0;
            _3231 = float2(_3214.y, _3206.y) * float2(0.0039215688593685626983642578125);
            float _3234 = _3198.y - 128.0;
            float _3240 = floor(_3234 * 0.03125) * 0.3333333432674407958984375;
            float3 _3246 = fast::normalize(in.m_1649);
            float _3250 = dot(_3246, in.m_1655.xyz);
            float _3262 = (_3250 / fast::max(length(in.m_1655.xyz - (_3246 * _3250)), 9.9999999747524270787835121154785e-07)) * 25.5;
            if (((-24.0) + _3262) < (-2.0))
            {
                _7705 = 0.0;
                break;
            }
            float3 _3270 = in.m_1684 * (4.0 * exp2(mod(_3234, 32.0) * 0.3333333432674407958984375));
            float3 _3314 = floor(_3270);
            float3 _3317 = _3270 - _3314;
            float3 _3325 = (_3317 * _3317) * (float3(3.0) - (_3317 * 2.0));
            uint3 _3392 = uint3(int3(_3314));
            uint _3405 = (((_3392.x * 1597334677u) ^ (_3392.y * 3812015801u)) ^ (_3392.z * 2798796415u)) * 1597334677u;
            uint3 _3420 = uint3(int3(_3314 + float3(1.0, 0.0, 0.0)));
            uint _3433 = (((_3420.x * 1597334677u) ^ (_3420.y * 3812015801u)) ^ (_3420.z * 2798796415u)) * 1597334677u;
            float _3334 = _3325.x;
            uint3 _3448 = uint3(int3(_3314 + float3(0.0, 1.0, 0.0)));
            uint _3461 = (((_3448.x * 1597334677u) ^ (_3448.y * 3812015801u)) ^ (_3448.z * 2798796415u)) * 1597334677u;
            uint3 _3476 = uint3(int3(_3314 + float3(1.0, 1.0, 0.0)));
            uint _3489 = (((_3476.x * 1597334677u) ^ (_3476.y * 3812015801u)) ^ (_3476.z * 2798796415u)) * 1597334677u;
            float _3350 = _3325.y;
            uint3 _3504 = uint3(int3(_3314 + float3(0.0, 0.0, 1.0)));
            uint _3517 = (((_3504.x * 1597334677u) ^ (_3504.y * 3812015801u)) ^ (_3504.z * 2798796415u)) * 1597334677u;
            uint3 _3532 = uint3(int3(_3314 + float3(1.0, 0.0, 1.0)));
            uint _3545 = (((_3532.x * 1597334677u) ^ (_3532.y * 3812015801u)) ^ (_3532.z * 2798796415u)) * 1597334677u;
            uint3 _3560 = uint3(int3(_3314 + float3(0.0, 1.0, 1.0)));
            uint _3573 = (((_3560.x * 1597334677u) ^ (_3560.y * 3812015801u)) ^ (_3560.z * 2798796415u)) * 1597334677u;
            uint3 _3588 = uint3(int3(_3314 + float3(1.0)));
            uint _3601 = (((_3588.x * 1597334677u) ^ (_3588.y * 3812015801u)) ^ (_3588.z * 2798796415u)) * 1597334677u;
            float3 _3276 = (_3270 * 2.7000000476837158203125) + float3(17.299999237060546875, 5.099999904632568359375, 9.69999980926513671875);
            float3 _3627 = floor(_3276);
            float3 _3630 = _3276 - _3627;
            float3 _3638 = (_3630 * _3630) * (float3(3.0) - (_3630 * 2.0));
            uint3 _3705 = uint3(int3(_3627));
            uint _3718 = (((_3705.x * 1597334677u) ^ (_3705.y * 3812015801u)) ^ (_3705.z * 2798796415u)) * 1597334677u;
            uint3 _3733 = uint3(int3(_3627 + float3(1.0, 0.0, 0.0)));
            uint _3746 = (((_3733.x * 1597334677u) ^ (_3733.y * 3812015801u)) ^ (_3733.z * 2798796415u)) * 1597334677u;
            float _3647 = _3638.x;
            uint3 _3761 = uint3(int3(_3627 + float3(0.0, 1.0, 0.0)));
            uint _3774 = (((_3761.x * 1597334677u) ^ (_3761.y * 3812015801u)) ^ (_3761.z * 2798796415u)) * 1597334677u;
            uint3 _3789 = uint3(int3(_3627 + float3(1.0, 1.0, 0.0)));
            uint _3802 = (((_3789.x * 1597334677u) ^ (_3789.y * 3812015801u)) ^ (_3789.z * 2798796415u)) * 1597334677u;
            float _3663 = _3638.y;
            uint3 _3817 = uint3(int3(_3627 + float3(0.0, 0.0, 1.0)));
            uint _3830 = (((_3817.x * 1597334677u) ^ (_3817.y * 3812015801u)) ^ (_3817.z * 2798796415u)) * 1597334677u;
            uint3 _3845 = uint3(int3(_3627 + float3(1.0, 0.0, 1.0)));
            uint _3858 = (((_3845.x * 1597334677u) ^ (_3845.y * 3812015801u)) ^ (_3845.z * 2798796415u)) * 1597334677u;
            uint3 _3873 = uint3(int3(_3627 + float3(0.0, 1.0, 1.0)));
            uint _3886 = (((_3873.x * 1597334677u) ^ (_3873.y * 3812015801u)) ^ (_3873.z * 2798796415u)) * 1597334677u;
            uint3 _3901 = uint3(int3(_3627 + float3(1.0)));
            uint _3914 = (((_3901.x * 1597334677u) ^ (_3901.y * 3812015801u)) ^ (_3901.z * 2798796415u)) * 1597334677u;
            float _3281 = mix(0.449999988079071044921875, 0.0500000007450580596923828125, _3240);
            float _3285 = ((mix(mix(mix(float((_3405 ^ (_3405 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_3433 ^ (_3433 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _3334), mix(float((_3461 ^ (_3461 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_3489 ^ (_3489 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _3334), _3350), mix(mix(float((_3517 ^ (_3517 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_3545 ^ (_3545 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _3334), mix(float((_3573 ^ (_3573 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_3601 ^ (_3601 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _3334), _3350), _3325.z) * 0.64999997615814208984375) + (mix(mix(mix(float((_3718 ^ (_3718 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_3746 ^ (_3746 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _3647), mix(float((_3774 ^ (_3774 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_3802 ^ (_3802 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _3647), _3663), mix(mix(float((_3830 ^ (_3830 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_3858 ^ (_3858 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _3647), mix(float((_3886 ^ (_3886 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_3914 ^ (_3914 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _3647), _3663), _3638.z) * 0.3499999940395355224609375)) - 0.5;
            _7705 = smoothstep(-_3281, _3281, (_3262 + (-24.450000762939453125)) + (_3285 * mix(0.800000011920928955078125, 2.2000000476837158203125, _3240)));
            break;
        } while(false);
        _7868 = _3231;
        _7835 = _7705;
        _7804 = mix(_7707, (in.m_2133.xyz * _3224) * mix(float3(1.0), _2141 * 2.0, float3(0.5)), float3(_7705));
    }
    else
    {
        _7868 = float2(0.0);
        _7835 = 0.0;
        _7804 = _7707;
    }
    float3 _2227 = fast::normalize(in.m_1649);
    float3 _7717;
    if (_1579._m6.y > 0.5)
    {
        float3 _2242 = in.m_1655.xyz - (_2227 * dot(_2227, in.m_1655.xyz));
        float3 _7718;
        if (dot(_2242, _2242) > 9.9999999600419720025001879548654e-13)
        {
            float3 _2251 = fast::normalize(_2242);
            float4 _2267 = _2262.sample(_1229, _2124);
            float3 _7709;
            if (_1579._m6.z > 0.5)
            {
                float2 _7708;
                if (_1579._m6.z > 1.5)
                {
                    _7708 = _2267.xw;
                }
                else
                {
                    _7708 = _2267.xy;
                }
                float2 _2289 = (_7708 * 2.0) - float2(1.0);
                _7709 = float3(_2289, sqrt(fast::clamp(1.0 - dot(_2289, _2289), 0.0, 1.0)));
            }
            else
            {
                _7709 = (_2267.xyz * 2.0) - float3(1.0);
            }
            float2 _2311 = _7709.xy * _1579._m4.z;
            _7718 = fast::normalize(((_2251 * _2311.x) + ((cross(_2227, _2251) * ((in.m_1655.w < 0.0) ? (-1.0) : 1.0)) * _2311.y)) + (_2227 * _7709.z));
        }
        else
        {
            _7718 = _2227;
        }
        _7717 = _7718;
    }
    else
    {
        _7717 = _2227;
    }
    bool _2335 = _1579._m5.w > 0.5;
    float _7714;
    if (_2335)
    {
        _7714 = fast::clamp(_1579._m1.z, 0.0, 1.0);
    }
    else
    {
        _7714 = 0.0;
    }
    bool _2353;
    if (_2335)
    {
        _2353 = !gl_FrontFacing;
    }
    else
    {
        _2353 = _2335;
    }
    float3 _7904;
    if (_2353 && (_7714 <= 0.0))
    {
        _7904 = -_7717;
    }
    else
    {
        _7904 = _7717;
    }
    float3 _2365 = fast::normalize(_192._m4.xyz);
    float3 _2371 = _192._m6.xyz - in.m_1741;
    float3 _2372 = fast::normalize(_2371);
    float3 _2377 = fast::normalize(_2365 + _2372);
    float3 _2383 = _2227 * (gl_FrontFacing ? 1.0 : (-1.0));
    bool _2388 = in.m_2385.x > 0.5;
    float3 _7898;
    float _7938;
    if ((_192._m5.w > 0.5) && _2388)
    {
        float _7774;
        float3 _7775;
        do
        {
            int _3943 = int(_192._m21.x);
            float _3951 = dot(_192._m20.xyz, in.m_1741) + _192._m20.w;
            int _7719;
            _7719 = 0;
            for (;;)
            {
                bool _3957 = _7719 < (_3943 - 1);
                bool _3965;
                if (_3957)
                {
                    _3965 = _3951 > _192._m16[_7719];
                }
                else
                {
                    _3965 = _3957;
                }
                if (_3965)
                {
                    _7719++;
                    continue;
                }
                else
                {
                    break;
                }
            }
            if (_3951 > _192._m16[_7719])
            {
                _7775 = float3(1.0);
                _7774 = 1.0;
                break;
            }
            float _7732;
            do
            {
                float4 _4067 = _192._m14[_7719] * float4(in.m_1741 + (_2383 * _192._m18[_7719]), 1.0);
                float _4070 = _4067.x;
                bool _4071 = _4070 < 0.0;
                bool _4078;
                if (!_4071)
                {
                    _4078 = _4070 > 1.0;
                }
                else
                {
                    _4078 = _4071;
                }
                bool _4085;
                if (!_4078)
                {
                    _4085 = _4067.y < 0.0;
                }
                else
                {
                    _4085 = _4078;
                }
                bool _4092;
                if (!_4085)
                {
                    _4092 = _4067.y > 1.0;
                }
                else
                {
                    _4092 = _4085;
                }
                if (_4092)
                {
                    _7732 = 1.0;
                    break;
                }
                float2 _4105 = float2(float(_7719 & 1), float(_7719 >> 1)) * _192._m23.xy;
                float _4112 = fast::min(_4067.z, 1.0) - _192._m19[_7719];
                float2 _4131 = _192._m22.xy * 0.5;
                float2 _4136 = _4105 + (_4067.xy * _192._m23.xy);
                float4 _4149 = float4(_4105 + _4131, (_4105 + _192._m23.xy) - _4131);
                float _7731;
                do
                {
                    int _4175 = int(_192._m22.z);
                    if (_4175 <= 0)
                    {
                        _7731 = spvDepthCast(_212).sample_compare(_212Smplr, float3(fast::clamp(_4136, _4149.xy, _4149.zw), _4112).xy, _4112);
                        break;
                    }
                    float2 _4198 = (_4136 / _192._m22.xy) + float2(0.5);
                    float2 _4199 = floor(_4198);
                    float2 _4204 = _4198 - _4199;
                    float2 _4207 = _4199 - float2(0.5);
                    bool _4211 = _4175 == 1;
                    spvUnsafeArray<float2, 3> _4159;
                    spvUnsafeArray<float2, 3> _4160;
                    if (_4211)
                    {
                        float2 _4214 = _4204 * 2.0;
                        _4159[0] = float2(3.0) - _4214;
                        _4159[1] = float2(1.0) + _4214;
                        _4160[0] = ((float2(2.0) - _4204) / _4159[0]) - float2(1.0);
                        _4160[1] = (_4204 / _4159[1]) + float2(1.0);
                    }
                    else
                    {
                        float2 _4241 = _4204 * 3.0;
                        _4159[0] = float2(4.0) - _4241;
                        _4159[1] = float2(7.0);
                        _4159[2] = float2(1.0) + _4241;
                        _4160[0] = ((float2(3.0) - (_4204 * 2.0)) / _4159[0]) - float2(2.0);
                        _4160[1] = (float2(3.0) + _4204) / _4159[1];
                        _4160[2] = (_4204 / _4159[2]) + float2(2.0);
                    }
                    int _8493 = _4211 ? 2 : 3;
                    int _7721;
                    float _7724;
                    _7724 = 0.0;
                    _7721 = 0;
                    float _7730;
                    for (; _7721 < _8493; _7724 = _7730, _7721++)
                    {
                        _7730 = _7724;
                        for (int _7727 = 0; _7727 < _8493; )
                        {
                            _7730 += ((_4159[_7727].x * _4159[_7721].y) * spvDepthCast(_212).sample_compare(_212Smplr, float3(fast::clamp(_192._m22.xy * (_4207 + float2(_4160[_7727].x, _4160[_7721].y)), _4149.xy, _4149.zw), _4112).xy, _4112));
                            _7727++;
                            continue;
                        }
                    }
                    _7731 = _7724 * (_4211 ? 0.0625 : 0.0069444444961845874786376953125);
                    break;
                } while(false);
                _7732 = _7731;
                break;
            } while(false);
            float3 _7769;
            float _7772;
            if (_3951 > _192._m17[_7719])
            {
                float _4005 = (_3951 - _192._m17[_7719]) / (_192._m16[_7719] - _192._m17[_7719]);
                int _4007 = _7719 + 1;
                float3 _7770;
                float _7773;
                if (_4007 < _3943)
                {
                    float _7752;
                    do
                    {
                        float4 _4354 = _192._m14[_4007] * float4(in.m_1741 + (_2383 * _192._m18[_4007]), 1.0);
                        float _4357 = _4354.x;
                        bool _4358 = _4357 < 0.0;
                        bool _4365;
                        if (!_4358)
                        {
                            _4365 = _4357 > 1.0;
                        }
                        else
                        {
                            _4365 = _4358;
                        }
                        bool _4372;
                        if (!_4365)
                        {
                            _4372 = _4354.y < 0.0;
                        }
                        else
                        {
                            _4372 = _4365;
                        }
                        bool _4379;
                        if (!_4372)
                        {
                            _4379 = _4354.y > 1.0;
                        }
                        else
                        {
                            _4379 = _4372;
                        }
                        if (_4379)
                        {
                            _7752 = 1.0;
                            break;
                        }
                        float2 _4392 = float2(float(_4007 & 1), float(_4007 >> 1)) * _192._m23.xy;
                        float _4399 = fast::min(_4354.z, 1.0) - _192._m19[_4007];
                        float2 _4418 = _192._m22.xy * 0.5;
                        float2 _4423 = _4392 + (_4354.xy * _192._m23.xy);
                        float4 _4436 = float4(_4392 + _4418, (_4392 + _192._m23.xy) - _4418);
                        float _7751;
                        do
                        {
                            int _4462 = int(_192._m22.z);
                            if (_4462 <= 0)
                            {
                                _7751 = spvDepthCast(_212).sample_compare(_212Smplr, float3(fast::clamp(_4423, _4436.xy, _4436.zw), _4399).xy, _4399);
                                break;
                            }
                            float2 _4485 = (_4423 / _192._m22.xy) + float2(0.5);
                            float2 _4486 = floor(_4485);
                            float2 _4491 = _4485 - _4486;
                            float2 _4494 = _4486 - float2(0.5);
                            bool _4498 = _4462 == 1;
                            spvUnsafeArray<float2, 3> _4446;
                            spvUnsafeArray<float2, 3> _4447;
                            if (_4498)
                            {
                                float2 _4501 = _4491 * 2.0;
                                _4446[0] = float2(3.0) - _4501;
                                _4446[1] = float2(1.0) + _4501;
                                _4447[0] = ((float2(2.0) - _4491) / _4446[0]) - float2(1.0);
                                _4447[1] = (_4491 / _4446[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _4528 = _4491 * 3.0;
                                _4446[0] = float2(4.0) - _4528;
                                _4446[1] = float2(7.0);
                                _4446[2] = float2(1.0) + _4528;
                                _4447[0] = ((float2(3.0) - (_4491 * 2.0)) / _4446[0]) - float2(2.0);
                                _4447[1] = (float2(3.0) + _4491) / _4446[1];
                                _4447[2] = (_4491 / _4446[2]) + float2(2.0);
                            }
                            int _8495 = _4498 ? 2 : 3;
                            int _7741;
                            float _7744;
                            _7744 = 0.0;
                            _7741 = 0;
                            float _7750;
                            for (; _7741 < _8495; _7744 = _7750, _7741++)
                            {
                                _7750 = _7744;
                                for (int _7747 = 0; _7747 < _8495; )
                                {
                                    _7750 += ((_4446[_7747].x * _4446[_7741].y) * spvDepthCast(_212).sample_compare(_212Smplr, float3(fast::clamp(_192._m22.xy * (_4494 + float2(_4447[_7747].x, _4447[_7741].y)), _4436.xy, _4436.zw), _4399).xy, _4399));
                                    _7747++;
                                    continue;
                                }
                            }
                            _7751 = _7744 * (_4498 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _7752 = _7751;
                        break;
                    } while(false);
                    _7773 = mix(_7732, _7752, _4005);
                    _7770 = mix(_566[_7719], _566[_4007], float3(_4005));
                }
                else
                {
                    _7773 = mix(_7732, 1.0, _4005);
                    _7770 = _566[_7719];
                }
                _7772 = _7773;
                _7769 = _7770;
            }
            else
            {
                _7772 = _7732;
                _7769 = _566[_7719];
            }
            _7775 = select(float3(1.0), _7769, bool3(_192._m22.w > 0.5));
            _7774 = _7772;
            break;
        } while(false);
        _7938 = _7774;
        _7898 = _7804 * _7775;
    }
    else
    {
        _7938 = 1.0;
        _7898 = _7804;
    }
    float3 _2414 = _192._m5.xyz * _192._m4.w;
    bool _2418 = _1579._m6.w > 0.5;
    float _7827;
    if (_2418)
    {
        _7827 = 1.0;
    }
    else
    {
        _7827 = 1.0 + (_1579._m4.w * (_2057.sample(_1229, _2124).x - 1.0));
    }
    float _2438 = abs(in.m_1655.w);
    float _8028;
    if (_2438 > 0.0)
    {
        _8028 = _7827 * fast::min(_2438, 1.0);
    }
    else
    {
        _8028 = _7827;
    }
    float3 _8186;
    if (!_2335)
    {
        float _2454 = dot(_7904, _2365);
        float3 _8178;
        if (_192._m29.x > 0.5)
        {
            float _4679 = (_192._m29.z * _7904.x) - (_192._m29.w * _7904.z);
            float _4692 = (_192._m29.w * _7904.x) + (_192._m29.z * _7904.z);
            float _4710 = 1.09254801273345947265625 * _4679;
            spvUnsafeArray<float, 9> _7442 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _7904.y, 0.48860299587249755859375 * _4692, 0.48860299587249755859375 * _4679, _4710 * _7904.y, (1.09254801273345947265625 * _7904.y) * _4692, 0.3153919875621795654296875 * (((3.0 * _4692) * _4692) - 1.0), _4710 * _4692, 0.546274006366729736328125 * ((_4679 * _4679) - (_7904.y * _7904.y)) });
            spvUnsafeArray<float, 9> _4624 = _7442;
            float3 _8177;
            _8177 = float3(0.0);
            for (int _8176 = 0; _8176 < 9; )
            {
                _8177 += (_1227.read(uint2((int2(496, 256) + int2(_8176, 0))), 0).xyz * _4624[_8176]);
                _8176++;
                continue;
            }
            _8178 = fast::max(_8177, float3(0.0)) * _192._m29.y;
        }
        else
        {
            _8178 = mix(_192._m9.xyz, _192._m8.xyz, float3((_7904.y * 0.5) + 0.5)) * _192._m8.w;
        }
        float3 _2504 = (_7898 * ((_8178 * _8028) + ((_2414 * fast::max(_2454, 0.0)) * _7938))) + ((_2414 * ((powr(fast::max(dot(_7904, _2377), 0.0), _1579._m1.w) * _1579._m1.z) * step(0.0, _2454))) * _7938);
        float3 _8187;
        if (_192._m13.w > 0.5)
        {
            float2 _4795 = fast::clamp(floor(gl_FragCoord.xy * _192._m12.xy), float2(0.0), _192._m13.xy - float2(1.0));
            uint _4823 = uint((((fast::clamp(floor((log2(fast::max(dot(_192._m11.xyz, in.m_1741) + _192._m11.w, 9.9999999747524270787835121154785e-07)) * _192._m12.z) + _192._m12.w), 0.0, _192._m13.z - 1.0) * _192._m13.y) + _4795.y) * _192._m13.x) + _4795.x);
            uint _4825 = _4823 >> uint(2);
            uint _4827 = _4823 & 3u;
            uint _4831 = _1872._m0[_4825][_4827] & 65535u;
            uint _4833 = _1872._m0[_4825][_4827] >> uint(16);
            float3 _8188;
            _8188 = _2504;
            float3 _2585;
            spvUnsafeArray<float2, 3> _5241;
            spvUnsafeArray<float2, 3> _5242;
            spvUnsafeArray<float2, 3> _5454;
            spvUnsafeArray<float2, 3> _5455;
            for (uint _8185 = _4831; _8185 < (_4831 + _4833); _8188 = _2585, _8185++)
            {
                uint _4839 = _8185 / 3u;
                uint _4852 = (_1893._m0[_4839 >> uint(2)][_4839 & 3u] >> ((_8185 - (_4839 * 3u)) * 10u)) & 1023u;
                float3 _4869 = _1734._m0[_4852].xyz - in.m_1741;
                float _4872 = dot(_4869, _4869);
                float _4876 = _4872 * _1734._m0[_4852].w;
                float _4881 = fast::clamp(1.0 - (_4876 * _4876), 0.0, 1.0);
                float3 _4886 = _4869 * rsqrt(fast::max(_4872, 9.9999999392252902907785028219223e-09));
                float _4904 = fast::clamp((dot(-_4886, _1777._m0[_4852].xyz) * _1769._m0[_4852].w) + _1777._m0[_4852].w, 0.0, 1.0);
                float3 _4917 = _1769._m0[_4852].xyz * ((((_4881 * _4881) * _4904) * _4904) / fast::max(_4872, 9.9999997473787516355514526367188e-05));
                float3 _8393;
                if (_2388)
                {
                    float _8339;
                    do
                    {
                        uint _4953 = uint(_192._m21.z);
                        if (_4852 < _4953)
                        {
                            float _4975 = _192._m26[_4852].z * fast::max((_192._m15[_4852] * float4(in.m_1741, 1.0)).w, 0.0);
                            float4 _4999 = _192._m15[_4852] * float4((in.m_1741 + (_2383 * (_4975 * _192._m25.x))) + (_4886 * (_4975 * _192._m25.y)), 1.0);
                            float _5001 = _4999.w;
                            if (_5001 <= 0.0)
                            {
                                _8339 = 1.0;
                                break;
                            }
                            float3 _5010 = _4999.xyz / float3(_5001);
                            float _5012 = _5010.x;
                            bool _5013 = _5012 < 0.0;
                            bool _5020;
                            if (!_5013)
                            {
                                _5020 = _5012 > 1.0;
                            }
                            else
                            {
                                _5020 = _5013;
                            }
                            bool _5027;
                            if (!_5020)
                            {
                                _5027 = _5010.y < 0.0;
                            }
                            else
                            {
                                _5027 = _5020;
                            }
                            bool _5034;
                            if (!_5027)
                            {
                                _5034 = _5010.y > 1.0;
                            }
                            else
                            {
                                _5034 = _5027;
                            }
                            bool _5041;
                            if (!_5034)
                            {
                                _5041 = _5010.z > 1.0;
                            }
                            else
                            {
                                _5041 = _5034;
                            }
                            if (_5041)
                            {
                                _8339 = 1.0;
                                break;
                            }
                            float _5047 = _5010.z;
                            float2 _5213 = _192._m22.xy * 0.5;
                            float2 _5218 = _192._m26[_4852].xy + (_5010.xy * _192._m23.zw);
                            float4 _5231 = float4(_192._m26[_4852].xy + _5213, (_192._m26[_4852].xy + _192._m23.zw) - _5213);
                            float _8338;
                            do
                            {
                                int _5257 = int(_192._m22.z);
                                if (_5257 <= 0)
                                {
                                    float2 _5267 = fast::clamp(_5218, _5231.xy, _5231.zw);
                                    _8338 = spvDepthCast(_212).sample_compare(_212Smplr, float3(_5267, _5047).xy, _5047);
                                    break;
                                }
                                float2 _5280 = (_5218 / _192._m22.xy) + float2(0.5);
                                float2 _5281 = floor(_5280);
                                float2 _5286 = _5280 - _5281;
                                float2 _5289 = _5281 - float2(0.5);
                                bool _5293 = _5257 == 1;
                                if (_5293)
                                {
                                    float2 _5296 = _5286 * 2.0;
                                    _5241[0] = float2(3.0) - _5296;
                                    _5241[1] = float2(1.0) + _5296;
                                    _5242[0] = ((float2(2.0) - _5286) / _5241[0]) - float2(1.0);
                                    _5242[1] = (_5286 / _5241[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _5323 = _5286 * 3.0;
                                    _5241[0] = float2(4.0) - _5323;
                                    _5241[1] = float2(7.0);
                                    _5241[2] = float2(1.0) + _5323;
                                    _5242[0] = ((float2(3.0) - (_5286 * 2.0)) / _5241[0]) - float2(2.0);
                                    _5242[1] = (float2(3.0) + _5286) / _5241[1];
                                    _5242[2] = (_5286 / _5241[2]) + float2(2.0);
                                }
                                int _8500 = _5293 ? 2 : 3;
                                int _8328;
                                float _8331;
                                _8331 = 0.0;
                                _8328 = 0;
                                float _8337;
                                for (; _8328 < _8500; _8331 = _8337, _8328++)
                                {
                                    _8337 = _8331;
                                    for (int _8334 = 0; _8334 < _8500; )
                                    {
                                        _8337 += ((_5241[_8334].x * _5241[_8328].y) * spvDepthCast(_212).sample_compare(_212Smplr, float3(fast::clamp(_192._m22.xy * (_5289 + float2(_5242[_8334].x, _5242[_8328].y)), _5231.xy, _5231.zw), _5047).xy, _5047));
                                        _8334++;
                                        continue;
                                    }
                                }
                                _8338 = _8331 * (_5293 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _8339 = _8338;
                            break;
                        }
                        uint _5057 = _4852 - _4953;
                        if (_5057 >= uint(_192._m21.w))
                        {
                            _8339 = 1.0;
                            break;
                        }
                        float _5078 = _192._m27[_5057].w * length(in.m_1741 - _192._m27[_5057].xyz);
                        float3 _5096 = ((in.m_1741 + (_2383 * (_5078 * _192._m25.x))) + (_4886 * (_5078 * _192._m25.y))) - _192._m27[_5057].xyz;
                        float3 _5098 = abs(_5096);
                        float _5100 = _5098.x;
                        float _5102 = _5098.y;
                        bool _5103 = _5100 >= _5102;
                        bool _5111;
                        if (_5103)
                        {
                            _5111 = _5100 >= _5098.z;
                        }
                        else
                        {
                            _5111 = _5103;
                        }
                        float _8313;
                        int _8315;
                        if (_5111)
                        {
                            _8315 = (_5096.x > 0.0) ? 0 : 1;
                            _8313 = _5100;
                        }
                        else
                        {
                            float _5123 = _5098.z;
                            bool _5124 = _5102 >= _5123;
                            int _8316;
                            if (_5124)
                            {
                                _8316 = (_5096.y > 0.0) ? 2 : 3;
                            }
                            else
                            {
                                _8316 = (_5096.z > 0.0) ? 4 : 5;
                            }
                            _8315 = _8316;
                            _8313 = _5124 ? _5102 : _5123;
                        }
                        if (_8313 <= 0.0)
                        {
                            _8339 = 1.0;
                            break;
                        }
                        float2 _5161 = float2(dot(_5096, _870[_8315]), dot(_5096, _879[_8315])) / float2(_8313 * _192._m24.z);
                        float _5168 = _192._m28[_5057].z + (_192._m28[_5057].w / _8313);
                        if (_5168 > 1.0)
                        {
                            _8339 = 1.0;
                            break;
                        }
                        float2 _5186 = _192._m28[_5057].xy + (float2(float(spvSMod(_8315, 3)), float(_8315 / 3)) * _192._m24.xy);
                        float2 _5426 = _192._m22.xy * 0.5;
                        float2 _5431 = _5186 + (float2(0.5 + (0.5 * _5161.x), 0.5 - (0.5 * _5161.y)) * _192._m24.xy);
                        float4 _5444 = float4(_5186 + _5426, (_5186 + _192._m24.xy) - _5426);
                        float _8327;
                        do
                        {
                            int _5470 = int(_192._m22.z);
                            if (_5470 <= 0)
                            {
                                _8327 = spvDepthCast(_212).sample_compare(_212Smplr, float3(fast::clamp(_5431, _5444.xy, _5444.zw), _5168).xy, _5168);
                                break;
                            }
                            float2 _5493 = (_5431 / _192._m22.xy) + float2(0.5);
                            float2 _5494 = floor(_5493);
                            float2 _5499 = _5493 - _5494;
                            float2 _5502 = _5494 - float2(0.5);
                            bool _5506 = _5470 == 1;
                            if (_5506)
                            {
                                float2 _5509 = _5499 * 2.0;
                                _5454[0] = float2(3.0) - _5509;
                                _5454[1] = float2(1.0) + _5509;
                                _5455[0] = ((float2(2.0) - _5499) / _5454[0]) - float2(1.0);
                                _5455[1] = (_5499 / _5454[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _5536 = _5499 * 3.0;
                                _5454[0] = float2(4.0) - _5536;
                                _5454[1] = float2(7.0);
                                _5454[2] = float2(1.0) + _5536;
                                _5455[0] = ((float2(3.0) - (_5499 * 2.0)) / _5454[0]) - float2(2.0);
                                _5455[1] = (float2(3.0) + _5499) / _5454[1];
                                _5455[2] = (_5499 / _5454[2]) + float2(2.0);
                            }
                            int _8503 = _5506 ? 2 : 3;
                            int _8317;
                            float _8320;
                            _8320 = 0.0;
                            _8317 = 0;
                            float _8326;
                            for (; _8317 < _8503; _8320 = _8326, _8317++)
                            {
                                _8326 = _8320;
                                for (int _8323 = 0; _8323 < _8503; )
                                {
                                    _8326 += ((_5454[_8323].x * _5454[_8317].y) * spvDepthCast(_212).sample_compare(_212Smplr, float3(fast::clamp(_192._m22.xy * (_5502 + float2(_5455[_8323].x, _5455[_8317].y)), _5444.xy, _5444.zw), _5168).xy, _5168));
                                    _8323++;
                                    continue;
                                }
                            }
                            _8327 = _8320 * (_5506 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _8339 = _8327;
                        break;
                    } while(false);
                    _8393 = _4917 * _8339;
                }
                else
                {
                    _8393 = _4917;
                }
                float _2556 = dot(_7904, _4886);
                _2585 = _8188 + (((_7898 * fast::max(_2556, 0.0)) * _8393) + (_8393 * ((powr(fast::max(dot(_7904, fast::normalize(_4886 + _2372)), 0.0), _1579._m1.w) * _1579._m1.z) * step(0.0, _2556))));
            }
            _8187 = _8188;
        }
        else
        {
            _8187 = _2504;
        }
        _8186 = _8187;
    }
    else
    {
        float4 _2595 = _2590.sample(_1229, _2124);
        float _2606 = fast::clamp((_1579._m4.x * _2595.z) * in.m_2602.y, 0.0, 1.0);
        float _2617 = fast::clamp((_1579._m4.y * _2595.y) * in.m_2602.x, 0.04500000178813934326171875, 1.0);
        float _7894;
        float _7899;
        if (_7835 > 0.0)
        {
            _7899 = mix(_2606, _7868.y, _7835);
            _7894 = mix(_2617, fast::max(_7868.x, 0.04500000178813934326171875), _7835);
        }
        else
        {
            _7899 = _2606;
            _7894 = _2617;
        }
        float _2636 = _7894 * _7894;
        float3 _2641 = _7898 * (1.0 - _7899);
        float3 _2647 = mix(float3(0.039999999105930328369140625), _7898, float3(_7899));
        bool _2651 = _7714 > 0.0;
        float3 _7927;
        if (_2651)
        {
            float3 _2656 = dfdx(in.m_1741);
            float3 _2658 = dfdy(in.m_1741);
            float3 _2659 = cross(_2656, _2658);
            float3 _7928;
            if (dot(_2659, _2659) > 9.9999996826552253889678874634872e-21)
            {
                _7928 = fast::normalize((fast::normalize(_2659) * ((dot(_2659, _2372) < 0.0) ? (-1.0) : 1.0)) + (_7904 - _2227));
            }
            else
            {
                _7928 = _7904;
            }
            _7927 = _7928;
        }
        else
        {
            _7927 = _7904;
        }
        float _2685 = fast::max(dot(_7927, _2372), 9.9999997473787516355514526367188e-05);
        float _2694 = dot(_7927, _2365);
        float _2695 = fast::clamp(_2694, 0.0, 1.0);
        float _2700 = fast::clamp(dot(_7927, _2377), 0.0, 1.0);
        float _2705 = fast::clamp(dot(_2372, _2377), 0.0, 1.0);
        float _7931;
        float _7932;
        if (_2651)
        {
            _7932 = fast::max(_2685, 0.5);
            _7931 = fast::max(_2705, 0.5);
        }
        else
        {
            _7932 = _2685;
            _7931 = _2705;
        }
        float3 _5638 = float3(1.0) - _2647;
        float3 _5641 = _2647 + (_5638 * powr(1.0 - _7931, 5.0));
        float _5648 = _2636 * _2636;
        float _5653 = _5648 - 1.0;
        float _5655 = ((_2700 * _2700) * _5653) + 1.0;
        float _5675 = 1.0 - _5648;
        float _5679 = sqrt(((_7932 * _7932) * _5675) + _5648);
        float3 _2751 = (((((float3(1.0) - _5641) * _2641) * fast::clamp(dot(_7904, _2365), 0.0, 1.0)) + (((_5641 * ((_5648 / ((3.1415927410125732421875 * _5655) * _5655)) * (0.5 / fast::max((_2695 * _5679) + (_7932 * sqrt(((_2695 * _2695) * _5675) + _5648)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875) * _2695)) * _2414) * _7938;
        float3 _8042;
        if (_2651)
        {
            _8042 = _2751 + (((((_2641 * _2414) * _7938) * _7714) * fast::clamp(-_2694, 0.0, 1.0)) * (0.3499999940395355224609375 + (0.64999997615814208984375 * powr(fast::clamp(dot(-_2372, _2365), 0.0, 1.0), 3.0))));
        }
        else
        {
            _8042 = _2751;
        }
        float3 _7968;
        float2 _7992;
        float3 _8004;
        if (_192._m29.x > 0.5)
        {
            float4 _5712 = _1333.sample(_1335, (((float2(_7932, _7894) * 31.0) + float2(0.5)) * float2(0.03125)));
            float _5771 = (_192._m29.z * _7904.x) - (_192._m29.w * _7904.z);
            float _5784 = (_192._m29.w * _7904.x) + (_192._m29.z * _7904.z);
            float _5802 = 1.09254801273345947265625 * _5771;
            spvUnsafeArray<float, 9> _7423 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _7904.y, 0.48860299587249755859375 * _5784, 0.48860299587249755859375 * _5771, _5802 * _7904.y, (1.09254801273345947265625 * _7904.y) * _5784, 0.3153919875621795654296875 * (((3.0 * _5784) * _5784) - 1.0), _5802 * _5784, 0.546274006366729736328125 * ((_5771 * _5771) - (_7904.y * _7904.y)) });
            spvUnsafeArray<float, 9> _5716 = _7423;
            float3 _7950;
            _7950 = float3(0.0);
            for (int _7949 = 0; _7949 < 9; )
            {
                _7950 += (_1227.read(uint2((int2(496, 256) + int2(_7949, 0))), 0).xyz * _5716[_7949]);
                _7949++;
                continue;
            }
            float3 _2803 = reflect(-_2372, _7927);
            float _5897 = _2803.x;
            float _5902 = _2803.z;
            float2 _5934 = float2((precise::atan2((_192._m29.z * _5897) - (_192._m29.w * _5902), -((_192._m29.w * _5897) + (_192._m29.z * _5902))) * 0.15915493667125701904296875) + 0.5, acos(fast::clamp(_2803.y, -1.0, 1.0)) * 0.3183098733425140380859375);
            float _5866 = _7894 * 5.0;
            int _5869 = min(int(_5866), 4);
            float2 _5955 = (_5934 * float2(_1289[_5869].zw)) - float2(0.5);
            float2 _5957 = floor(_5955);
            float2 _5960 = _5955 - _5957;
            int _5963 = int(_5957.x);
            int _5966 = int(_5957.y);
            int _7953;
            if (_5963 < 0)
            {
                _7953 = _5963 + _1289[_5869].z;
            }
            else
            {
                _7953 = _5963;
            }
            int _7954;
            if (_7953 >= _1289[_5869].z)
            {
                _7954 = _7953 - _1289[_5869].z;
            }
            else
            {
                _7954 = _7953;
            }
            int _5986 = _7954 + 1;
            int _8504 = (_5986 == _1289[_5869].z) ? 0 : _5986;
            int _6001 = min((_5966 + 1), (_1289[_5869].w - 1));
            int _6003 = max(_5966, 0);
            float3 _6056 = float3(_5960.x);
            int _5876 = _5869 + 1;
            float2 _6088 = (_5934 * float2(_1289[_5876].zw)) - float2(0.5);
            float2 _6090 = floor(_6088);
            float2 _6093 = _6088 - _6090;
            int _6096 = int(_6090.x);
            int _6099 = int(_6090.y);
            int _7960;
            if (_6096 < 0)
            {
                _7960 = _6096 + _1289[_5876].z;
            }
            else
            {
                _7960 = _6096;
            }
            int _7961;
            if (_7960 >= _1289[_5876].z)
            {
                _7961 = _7960 - _1289[_5876].z;
            }
            else
            {
                _7961 = _7960;
            }
            int _6119 = _7961 + 1;
            int _8505 = (_6119 == _1289[_5876].z) ? 0 : _6119;
            int _6134 = min((_6099 + 1), (_1289[_5876].w - 1));
            int _6136 = max(_6099, 0);
            float3 _6189 = float3(_6093.x);
            float3 _5891 = mix(mix(mix(_1227.read(uint2((_1289[_5869].xy + int2(_7954, _6003))), 0).xyz, _1227.read(uint2((_1289[_5869].xy + int2(_8504, _6003))), 0).xyz, _6056), mix(_1227.read(uint2((_1289[_5869].xy + int2(_7954, _6001))), 0).xyz, _1227.read(uint2((_1289[_5869].xy + int2(_8504, _6001))), 0).xyz, _6056), float3(_5960.y)), mix(mix(_1227.read(uint2((_1289[_5876].xy + int2(_7961, _6136))), 0).xyz, _1227.read(uint2((_1289[_5876].xy + int2(_8505, _6136))), 0).xyz, _6189), mix(_1227.read(uint2((_1289[_5876].xy + int2(_7961, _6134))), 0).xyz, _1227.read(uint2((_1289[_5876].xy + int2(_8505, _6134))), 0).xyz, _6189), float3(_6093.y)), float3(_5866 - float(_5869))) * _192._m29.y;
            _8004 = fast::max(_7950, float3(0.0)) * _192._m29.y;
            _7992 = _5712.xy;
            _7968 = _5891;
        }
        else
        {
            float4 _6207 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * _7894) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);
            float _6209 = _6207.x;
            float3 _6244 = mix(_192._m9.xyz, _192._m8.xyz, float3((_7904.y * 0.5) + 0.5)) * _192._m8.w;
            _8004 = _6244;
            _7992 = (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_6209 * _6209, exp2((-9.27999973297119140625) * _7932)) * _6209) + _6207.y)) + _6207.zw;
            _7968 = mix(mix(_192._m9.xyz, _192._m8.xyz, float3((reflect(-_2372, _7927).y * 0.5) + 0.5)) * _192._m8.w, _6244, float3(_7894));
        }
        bool _2835;
        if (_2418)
        {
            _2835 = _192._m33.z > 0.5;
        }
        else
        {
            _2835 = _2418;
        }
        float3 _8013;
        if (_2835)
        {
            float3 _7989;
            do
            {
                float _6323 = ((_192._m32.x * (1.0 - smoothstep(_192._m33.x * 0.5, _192._m33.x, abs(dot(_192._m31.xyz, in.m_1741) - _192._m31.w)))) * smoothstep(0.5, 0.89999997615814208984375, dot(_2383, _192._m31.xyz))) * (1.0 - smoothstep(_192._m32.y * 0.5, _192._m32.y, _7894));
                if (_6323 <= 0.0)
                {
                    _7989 = _7968;
                    break;
                }
                float4 _6348 = _192._m30 * float4(in.m_1741 + ((_7904 - (_192._m31.xyz * dot(_7904, _192._m31.xyz))) * _192._m32.w), 1.0);
                float2 _6361 = ((float2(_6348.x, -_6348.y) / float2(_6348.w)) * 0.5) + float2(0.5);
                float _6365 = _192._m32.z * _7894;
                float3 _7987;
                float _7988;
                _7988 = 0.0;
                _7987 = float3(0.0);
                for (int _7986 = 0; _7986 < 12; )
                {
                    float _6372 = float(_7986);
                    float _6380 = _6372 * 2.3999631404876708984375;
                    float2 _6392 = _6361 + (float2(cos(_6380) * _192._m33.y, sin(_6380)) * (sqrt((_6372 + 0.5) * 0.083333335816860198974609375) * _6365));
                    float2 _6397 = fast::min(_6392, float2(1.0) - _6392);
                    float _6403 = smoothstep(0.0, 0.039999999105930328369140625, fast::min(_6397.x, _6397.y));
                    float4 _6411 = _2057.sample(_1229, fast::clamp(_6392, float2(0.0), float2(1.0)), level(0.0));
                    float3 _6413 = _6411.xyz;
                    _7988 += (_6411.w * _6403);
                    _7987 += ((_6413 / (float3(1.0) - fast::min(_6413, float3(0.99500000476837158203125)))) * _6403);
                    _7986++;
                    continue;
                }
                _7989 = mix(_7968, (_7987 * float3(0.083333335816860198974609375)) + (_7968 * (1.0 - (_7988 * 0.083333335816860198974609375))), float3(_6323));
                break;
            } while(false);
            _8013 = _7989;
        }
        else
        {
            _8013 = _7968;
        }
        float3 _2855 = (_2647 * _7992.x) + float3(_7992.y);
        float3 _2871 = _8042 + (((((float3(1.0) - _2855) * _2641) * _8004) + (_2855 * _8013)) * _8028);
        float3 _8189;
        if (_192._m13.w > 0.5)
        {
            float2 _6477 = fast::clamp(floor(gl_FragCoord.xy * _192._m12.xy), float2(0.0), _192._m13.xy - float2(1.0));
            uint _6505 = uint((((fast::clamp(floor((log2(fast::max(dot(_192._m11.xyz, in.m_1741) + _192._m11.w, 9.9999999747524270787835121154785e-07)) * _192._m12.z) + _192._m12.w), 0.0, _192._m13.z - 1.0) * _192._m13.y) + _6477.y) * _192._m13.x) + _6477.x);
            uint _6507 = _6505 >> uint(2);
            uint _6509 = _6505 & 3u;
            uint _6513 = _1872._m0[_6507][_6509] & 65535u;
            uint _6515 = _1872._m0[_6507][_6509] >> uint(16);
            float3 _8142;
            _8142 = _2871;
            float3 _2971;
            spvUnsafeArray<float2, 3> _6923;
            spvUnsafeArray<float2, 3> _6924;
            spvUnsafeArray<float2, 3> _7136;
            spvUnsafeArray<float2, 3> _7137;
            for (uint _8045 = _6513; _8045 < (_6513 + _6515); _8142 = _2971, _8045++)
            {
                uint _6521 = _8045 / 3u;
                uint _6534 = (_1893._m0[_6521 >> uint(2)][_6521 & 3u] >> ((_8045 - (_6521 * 3u)) * 10u)) & 1023u;
                float3 _6551 = _1734._m0[_6534].xyz - in.m_1741;
                float _6554 = dot(_6551, _6551);
                float _6558 = _6554 * _1734._m0[_6534].w;
                float _6563 = fast::clamp(1.0 - (_6558 * _6558), 0.0, 1.0);
                float3 _6568 = _6551 * rsqrt(fast::max(_6554, 9.9999999392252902907785028219223e-09));
                float _6586 = fast::clamp((dot(-_6568, _1777._m0[_6534].xyz) * _1769._m0[_6534].w) + _1777._m0[_6534].w, 0.0, 1.0);
                float3 _6599 = _1769._m0[_6534].xyz * ((((_6563 * _6563) * _6586) * _6586) / fast::max(_6554, 9.9999997473787516355514526367188e-05));
                float3 _8140;
                if (_2388)
                {
                    float _8072;
                    do
                    {
                        uint _6635 = uint(_192._m21.z);
                        if (_6534 < _6635)
                        {
                            float _6657 = _192._m26[_6534].z * fast::max((_192._m15[_6534] * float4(in.m_1741, 1.0)).w, 0.0);
                            float4 _6681 = _192._m15[_6534] * float4((in.m_1741 + (_2383 * (_6657 * _192._m25.x))) + (_6568 * (_6657 * _192._m25.y)), 1.0);
                            float _6683 = _6681.w;
                            if (_6683 <= 0.0)
                            {
                                _8072 = 1.0;
                                break;
                            }
                            float3 _6692 = _6681.xyz / float3(_6683);
                            float _6694 = _6692.x;
                            bool _6695 = _6694 < 0.0;
                            bool _6702;
                            if (!_6695)
                            {
                                _6702 = _6694 > 1.0;
                            }
                            else
                            {
                                _6702 = _6695;
                            }
                            bool _6709;
                            if (!_6702)
                            {
                                _6709 = _6692.y < 0.0;
                            }
                            else
                            {
                                _6709 = _6702;
                            }
                            bool _6716;
                            if (!_6709)
                            {
                                _6716 = _6692.y > 1.0;
                            }
                            else
                            {
                                _6716 = _6709;
                            }
                            bool _6723;
                            if (!_6716)
                            {
                                _6723 = _6692.z > 1.0;
                            }
                            else
                            {
                                _6723 = _6716;
                            }
                            if (_6723)
                            {
                                _8072 = 1.0;
                                break;
                            }
                            float _6729 = _6692.z;
                            float2 _6895 = _192._m22.xy * 0.5;
                            float2 _6900 = _192._m26[_6534].xy + (_6692.xy * _192._m23.zw);
                            float4 _6913 = float4(_192._m26[_6534].xy + _6895, (_192._m26[_6534].xy + _192._m23.zw) - _6895);
                            float _8071;
                            do
                            {
                                int _6939 = int(_192._m22.z);
                                if (_6939 <= 0)
                                {
                                    float2 _6949 = fast::clamp(_6900, _6913.xy, _6913.zw);
                                    _8071 = spvDepthCast(_212).sample_compare(_212Smplr, float3(_6949, _6729).xy, _6729);
                                    break;
                                }
                                float2 _6962 = (_6900 / _192._m22.xy) + float2(0.5);
                                float2 _6963 = floor(_6962);
                                float2 _6968 = _6962 - _6963;
                                float2 _6971 = _6963 - float2(0.5);
                                bool _6975 = _6939 == 1;
                                if (_6975)
                                {
                                    float2 _6978 = _6968 * 2.0;
                                    _6923[0] = float2(3.0) - _6978;
                                    _6923[1] = float2(1.0) + _6978;
                                    _6924[0] = ((float2(2.0) - _6968) / _6923[0]) - float2(1.0);
                                    _6924[1] = (_6968 / _6923[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _7005 = _6968 * 3.0;
                                    _6923[0] = float2(4.0) - _7005;
                                    _6923[1] = float2(7.0);
                                    _6923[2] = float2(1.0) + _7005;
                                    _6924[0] = ((float2(3.0) - (_6968 * 2.0)) / _6923[0]) - float2(2.0);
                                    _6924[1] = (float2(3.0) + _6968) / _6923[1];
                                    _6924[2] = (_6968 / _6923[2]) + float2(2.0);
                                }
                                int _8507 = _6975 ? 2 : 3;
                                int _8061;
                                float _8064;
                                _8064 = 0.0;
                                _8061 = 0;
                                float _8070;
                                for (; _8061 < _8507; _8064 = _8070, _8061++)
                                {
                                    _8070 = _8064;
                                    for (int _8067 = 0; _8067 < _8507; )
                                    {
                                        _8070 += ((_6923[_8067].x * _6923[_8061].y) * spvDepthCast(_212).sample_compare(_212Smplr, float3(fast::clamp(_192._m22.xy * (_6971 + float2(_6924[_8067].x, _6924[_8061].y)), _6913.xy, _6913.zw), _6729).xy, _6729));
                                        _8067++;
                                        continue;
                                    }
                                }
                                _8071 = _8064 * (_6975 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _8072 = _8071;
                            break;
                        }
                        uint _6739 = _6534 - _6635;
                        if (_6739 >= uint(_192._m21.w))
                        {
                            _8072 = 1.0;
                            break;
                        }
                        float _6760 = _192._m27[_6739].w * length(in.m_1741 - _192._m27[_6739].xyz);
                        float3 _6778 = ((in.m_1741 + (_2383 * (_6760 * _192._m25.x))) + (_6568 * (_6760 * _192._m25.y))) - _192._m27[_6739].xyz;
                        float3 _6780 = abs(_6778);
                        float _6782 = _6780.x;
                        float _6784 = _6780.y;
                        bool _6785 = _6782 >= _6784;
                        bool _6793;
                        if (_6785)
                        {
                            _6793 = _6782 >= _6780.z;
                        }
                        else
                        {
                            _6793 = _6785;
                        }
                        float _8046;
                        int _8048;
                        if (_6793)
                        {
                            _8048 = (_6778.x > 0.0) ? 0 : 1;
                            _8046 = _6782;
                        }
                        else
                        {
                            float _6805 = _6780.z;
                            bool _6806 = _6784 >= _6805;
                            int _8049;
                            if (_6806)
                            {
                                _8049 = (_6778.y > 0.0) ? 2 : 3;
                            }
                            else
                            {
                                _8049 = (_6778.z > 0.0) ? 4 : 5;
                            }
                            _8048 = _8049;
                            _8046 = _6806 ? _6784 : _6805;
                        }
                        if (_8046 <= 0.0)
                        {
                            _8072 = 1.0;
                            break;
                        }
                        float2 _6843 = float2(dot(_6778, _870[_8048]), dot(_6778, _879[_8048])) / float2(_8046 * _192._m24.z);
                        float _6850 = _192._m28[_6739].z + (_192._m28[_6739].w / _8046);
                        if (_6850 > 1.0)
                        {
                            _8072 = 1.0;
                            break;
                        }
                        float2 _6868 = _192._m28[_6739].xy + (float2(float(spvSMod(_8048, 3)), float(_8048 / 3)) * _192._m24.xy);
                        float2 _7108 = _192._m22.xy * 0.5;
                        float2 _7113 = _6868 + (float2(0.5 + (0.5 * _6843.x), 0.5 - (0.5 * _6843.y)) * _192._m24.xy);
                        float4 _7126 = float4(_6868 + _7108, (_6868 + _192._m24.xy) - _7108);
                        float _8060;
                        do
                        {
                            int _7152 = int(_192._m22.z);
                            if (_7152 <= 0)
                            {
                                _8060 = spvDepthCast(_212).sample_compare(_212Smplr, float3(fast::clamp(_7113, _7126.xy, _7126.zw), _6850).xy, _6850);
                                break;
                            }
                            float2 _7175 = (_7113 / _192._m22.xy) + float2(0.5);
                            float2 _7176 = floor(_7175);
                            float2 _7181 = _7175 - _7176;
                            float2 _7184 = _7176 - float2(0.5);
                            bool _7188 = _7152 == 1;
                            if (_7188)
                            {
                                float2 _7191 = _7181 * 2.0;
                                _7136[0] = float2(3.0) - _7191;
                                _7136[1] = float2(1.0) + _7191;
                                _7137[0] = ((float2(2.0) - _7181) / _7136[0]) - float2(1.0);
                                _7137[1] = (_7181 / _7136[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _7218 = _7181 * 3.0;
                                _7136[0] = float2(4.0) - _7218;
                                _7136[1] = float2(7.0);
                                _7136[2] = float2(1.0) + _7218;
                                _7137[0] = ((float2(3.0) - (_7181 * 2.0)) / _7136[0]) - float2(2.0);
                                _7137[1] = (float2(3.0) + _7181) / _7136[1];
                                _7137[2] = (_7181 / _7136[2]) + float2(2.0);
                            }
                            int _8510 = _7188 ? 2 : 3;
                            int _8050;
                            float _8053;
                            _8053 = 0.0;
                            _8050 = 0;
                            float _8059;
                            for (; _8050 < _8510; _8053 = _8059, _8050++)
                            {
                                _8059 = _8053;
                                for (int _8056 = 0; _8056 < _8510; )
                                {
                                    _8059 += ((_7136[_8056].x * _7136[_8050].y) * spvDepthCast(_212).sample_compare(_212Smplr, float3(fast::clamp(_192._m22.xy * (_7184 + float2(_7137[_8056].x, _7137[_8050].y)), _7126.xy, _7126.zw), _6850).xy, _6850));
                                    _8056++;
                                    continue;
                                }
                            }
                            _8060 = _8053 * (_7188 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _8072 = _8060;
                        break;
                    } while(false);
                    _8140 = _6599 * _8072;
                }
                else
                {
                    _8140 = _6599;
                }
                float3 _2923 = fast::normalize(_6568 + _2372);
                float _2928 = fast::clamp(dot(_7904, _6568), 0.0, 1.0);
                float _2933 = fast::clamp(dot(_7904, _2923), 0.0, 1.0);
                float3 _7323 = _2647 + (_5638 * powr(1.0 - fast::clamp(dot(_2372, _2923), 0.0, 1.0), 5.0));
                float _7337 = ((_2933 * _2933) * _5653) + 1.0;
                _2971 = _8142 + (((((float3(1.0) - _7323) * _2641) + ((_7323 * ((_5648 / ((3.1415927410125732421875 * _7337) * _7337)) * (0.5 / fast::max((_2928 * _5679) + (_7932 * sqrt(((_2928 * _2928) * _5675) + _5648)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875)) * _2928) * _8140);
            }
            _8189 = _8142;
        }
        else
        {
            _8189 = _2871;
        }
        _8186 = _8189;
    }
    float4 _2988 = _2983.sample(_1229, _2124);
    float _3009 = -length(_2371);
    float _8231;
    if (_192._m9.w != 0.0)
    {
        float _3033 = _192._m9.w * (in.m_1741 - _192._m6.xyz).y;
        float _8228;
        if (abs(_3033) < 9.9999997473787516355514526367188e-05)
        {
            _8228 = 1.0 - (0.5 * _3033);
        }
        else
        {
            _8228 = (1.0 - exp(fast::min(-_3033, 60.0))) / _3033;
        }
        _8231 = 1.0 - exp((_3009 * (_192._m7.w * exp(fast::min((-_192._m9.w) * (_192._m6.y - _192._m6.w), 30.0)))) * _8228);
    }
    else
    {
        _8231 = 1.0 - exp(_3009 * _192._m7.w);
    }
    float3 _3084 = mix(mix(_8186, _7898, float3(_1579._m1.y)) + (((_1579._m5.xyz * _2988.xyz) * (float3(1.0) + in.m_2385.yzw)) * in.m_2602.z), _192._m7.xyz, float3(_8231));
    float3 _8232;
    if (_192._m33.w > 0.5)
    {
        _8232 = _3084 / (float3(1.0) + _3084);
    }
    else
    {
        _8232 = _3084;
    }
    out.m_3096 = float4(_8232, in.m_2133.w * in.m_2166.w);
    float2 _8312;
    do
    {
        if (in.m_3106.w <= 0.0)
        {
            _8312 = float2(0.0);
            break;
        }
        _8312 = ((in.m_3106.xy / float2(in.m_3106.w)) - (in.m_3105.xy / float2(in.m_3105.w))) * float2(0.5, -0.5);
        break;
    } while(false);
    out.m_3104 = _8312;
    return out;
}

