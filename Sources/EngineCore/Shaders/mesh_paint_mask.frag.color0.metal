// Generated from mesh_paint_mask.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 528afedc11532c2d
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
    float2 _3104;
    fragment_main_out out = {};
    float2 _2124 = float2(dot(_1579._m2.xy, in.m_2110) + _1579._m2.z, dot(_1579._m3.xy, in.m_2110) + _1579._m3.z);
    float4 _2131 = _2126.sample(_1229, _2124);
    float3 _2141 = _2131.xyz;
    if ((_1579._m0.w * _2131.w) < _1579._m6.x)
    {
        discard_fragment();
    }
    float3 _2170 = ((in.m_2133.xyz * _1579._m0.xyz) * _2141) * in.m_2166.xyz;
    float3 _7690;
    if (_1579._m1.x > 0.5)
    {
        float2 _2185 = floor(in.m_1741.xz * float2(0.5));
        _7690 = _2170 * ((mod(abs(_2185.x + _2185.y), 2.0) < 0.5) ? 1.0 : 0.75);
    }
    else
    {
        _7690 = _2170;
    }
    float3 _7787;
    float _7818;
    float2 _7851;
    if (_1579._m3.w > 0.5)
    {
        float3 _3207;
        float2 _3214;
        float _7688;
        do
        {
            float3 _3178 = float4(_1579._m2.w, _1579._m3.w, 0.0, 0.0).xyy;
            float3 _3181 = floor(_3178 * float3(1.52587890625e-05));
            float3 _3186 = _3178 - (_3181 * 65536.0);
            float3 _3189 = floor(_3186 * float3(0.00390625));
            float3 _3197 = _3186 - (_3189 * 256.0);
            _3207 = (float3(_3197.x, _3189.x, _3181.x) * float3(0.0039215688593685626983642578125)) * 2.0;
            _3214 = float2(_3197.y, _3189.y) * float2(0.0039215688593685626983642578125);
            float _3217 = _3181.y - 128.0;
            float _3223 = floor(_3217 * 0.03125) * 0.3333333432674407958984375;
            float3 _3229 = fast::normalize(in.m_1649);
            float _3233 = dot(_3229, in.m_1655.xyz);
            float _3245 = (_3233 / fast::max(length(in.m_1655.xyz - (_3229 * _3233)), 9.9999999747524270787835121154785e-07)) * 25.5;
            if (((-24.0) + _3245) < (-2.0))
            {
                _7688 = 0.0;
                break;
            }
            float3 _3253 = in.m_1684 * (4.0 * exp2(mod(_3217, 32.0) * 0.3333333432674407958984375));
            float3 _3297 = floor(_3253);
            float3 _3300 = _3253 - _3297;
            float3 _3308 = (_3300 * _3300) * (float3(3.0) - (_3300 * 2.0));
            uint3 _3375 = uint3(int3(_3297));
            uint _3388 = (((_3375.x * 1597334677u) ^ (_3375.y * 3812015801u)) ^ (_3375.z * 2798796415u)) * 1597334677u;
            uint3 _3403 = uint3(int3(_3297 + float3(1.0, 0.0, 0.0)));
            uint _3416 = (((_3403.x * 1597334677u) ^ (_3403.y * 3812015801u)) ^ (_3403.z * 2798796415u)) * 1597334677u;
            float _3317 = _3308.x;
            uint3 _3431 = uint3(int3(_3297 + float3(0.0, 1.0, 0.0)));
            uint _3444 = (((_3431.x * 1597334677u) ^ (_3431.y * 3812015801u)) ^ (_3431.z * 2798796415u)) * 1597334677u;
            uint3 _3459 = uint3(int3(_3297 + float3(1.0, 1.0, 0.0)));
            uint _3472 = (((_3459.x * 1597334677u) ^ (_3459.y * 3812015801u)) ^ (_3459.z * 2798796415u)) * 1597334677u;
            float _3333 = _3308.y;
            uint3 _3487 = uint3(int3(_3297 + float3(0.0, 0.0, 1.0)));
            uint _3500 = (((_3487.x * 1597334677u) ^ (_3487.y * 3812015801u)) ^ (_3487.z * 2798796415u)) * 1597334677u;
            uint3 _3515 = uint3(int3(_3297 + float3(1.0, 0.0, 1.0)));
            uint _3528 = (((_3515.x * 1597334677u) ^ (_3515.y * 3812015801u)) ^ (_3515.z * 2798796415u)) * 1597334677u;
            uint3 _3543 = uint3(int3(_3297 + float3(0.0, 1.0, 1.0)));
            uint _3556 = (((_3543.x * 1597334677u) ^ (_3543.y * 3812015801u)) ^ (_3543.z * 2798796415u)) * 1597334677u;
            uint3 _3571 = uint3(int3(_3297 + float3(1.0)));
            uint _3584 = (((_3571.x * 1597334677u) ^ (_3571.y * 3812015801u)) ^ (_3571.z * 2798796415u)) * 1597334677u;
            float3 _3259 = (_3253 * 2.7000000476837158203125) + float3(17.299999237060546875, 5.099999904632568359375, 9.69999980926513671875);
            float3 _3610 = floor(_3259);
            float3 _3613 = _3259 - _3610;
            float3 _3621 = (_3613 * _3613) * (float3(3.0) - (_3613 * 2.0));
            uint3 _3688 = uint3(int3(_3610));
            uint _3701 = (((_3688.x * 1597334677u) ^ (_3688.y * 3812015801u)) ^ (_3688.z * 2798796415u)) * 1597334677u;
            uint3 _3716 = uint3(int3(_3610 + float3(1.0, 0.0, 0.0)));
            uint _3729 = (((_3716.x * 1597334677u) ^ (_3716.y * 3812015801u)) ^ (_3716.z * 2798796415u)) * 1597334677u;
            float _3630 = _3621.x;
            uint3 _3744 = uint3(int3(_3610 + float3(0.0, 1.0, 0.0)));
            uint _3757 = (((_3744.x * 1597334677u) ^ (_3744.y * 3812015801u)) ^ (_3744.z * 2798796415u)) * 1597334677u;
            uint3 _3772 = uint3(int3(_3610 + float3(1.0, 1.0, 0.0)));
            uint _3785 = (((_3772.x * 1597334677u) ^ (_3772.y * 3812015801u)) ^ (_3772.z * 2798796415u)) * 1597334677u;
            float _3646 = _3621.y;
            uint3 _3800 = uint3(int3(_3610 + float3(0.0, 0.0, 1.0)));
            uint _3813 = (((_3800.x * 1597334677u) ^ (_3800.y * 3812015801u)) ^ (_3800.z * 2798796415u)) * 1597334677u;
            uint3 _3828 = uint3(int3(_3610 + float3(1.0, 0.0, 1.0)));
            uint _3841 = (((_3828.x * 1597334677u) ^ (_3828.y * 3812015801u)) ^ (_3828.z * 2798796415u)) * 1597334677u;
            uint3 _3856 = uint3(int3(_3610 + float3(0.0, 1.0, 1.0)));
            uint _3869 = (((_3856.x * 1597334677u) ^ (_3856.y * 3812015801u)) ^ (_3856.z * 2798796415u)) * 1597334677u;
            uint3 _3884 = uint3(int3(_3610 + float3(1.0)));
            uint _3897 = (((_3884.x * 1597334677u) ^ (_3884.y * 3812015801u)) ^ (_3884.z * 2798796415u)) * 1597334677u;
            float _3264 = mix(0.449999988079071044921875, 0.0500000007450580596923828125, _3223);
            float _3268 = ((mix(mix(mix(float((_3388 ^ (_3388 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_3416 ^ (_3416 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _3317), mix(float((_3444 ^ (_3444 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_3472 ^ (_3472 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _3317), _3333), mix(mix(float((_3500 ^ (_3500 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_3528 ^ (_3528 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _3317), mix(float((_3556 ^ (_3556 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_3584 ^ (_3584 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _3317), _3333), _3308.z) * 0.64999997615814208984375) + (mix(mix(mix(float((_3701 ^ (_3701 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_3729 ^ (_3729 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _3630), mix(float((_3757 ^ (_3757 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_3785 ^ (_3785 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _3630), _3646), mix(mix(float((_3813 ^ (_3813 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_3841 ^ (_3841 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _3630), mix(float((_3869 ^ (_3869 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_3897 ^ (_3897 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _3630), _3646), _3621.z) * 0.3499999940395355224609375)) - 0.5;
            _7688 = smoothstep(-_3264, _3264, (_3245 + (-24.450000762939453125)) + (_3268 * mix(0.800000011920928955078125, 2.2000000476837158203125, _3223)));
            break;
        } while(false);
        _7851 = _3214;
        _7818 = _7688;
        _7787 = mix(_7690, (in.m_2133.xyz * _3207) * mix(float3(1.0), _2141 * 2.0, float3(0.5)), float3(_7688));
    }
    else
    {
        _7851 = float2(0.0);
        _7818 = 0.0;
        _7787 = _7690;
    }
    float3 _2227 = fast::normalize(in.m_1649);
    float3 _7700;
    if (_1579._m6.y > 0.5)
    {
        float3 _2242 = in.m_1655.xyz - (_2227 * dot(_2227, in.m_1655.xyz));
        float3 _7701;
        if (dot(_2242, _2242) > 9.9999999600419720025001879548654e-13)
        {
            float3 _2251 = fast::normalize(_2242);
            float4 _2267 = _2262.sample(_1229, _2124);
            float3 _7692;
            if (_1579._m6.z > 0.5)
            {
                float2 _7691;
                if (_1579._m6.z > 1.5)
                {
                    _7691 = _2267.xw;
                }
                else
                {
                    _7691 = _2267.xy;
                }
                float2 _2289 = (_7691 * 2.0) - float2(1.0);
                _7692 = float3(_2289, sqrt(fast::clamp(1.0 - dot(_2289, _2289), 0.0, 1.0)));
            }
            else
            {
                _7692 = (_2267.xyz * 2.0) - float3(1.0);
            }
            float2 _2311 = _7692.xy * _1579._m4.z;
            _7701 = fast::normalize(((_2251 * _2311.x) + ((cross(_2227, _2251) * ((in.m_1655.w < 0.0) ? (-1.0) : 1.0)) * _2311.y)) + (_2227 * _7692.z));
        }
        else
        {
            _7701 = _2227;
        }
        _7700 = _7701;
    }
    else
    {
        _7700 = _2227;
    }
    bool _2335 = _1579._m5.w > 0.5;
    float _7697;
    if (_2335)
    {
        _7697 = fast::clamp(_1579._m1.z, 0.0, 1.0);
    }
    else
    {
        _7697 = 0.0;
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
    float3 _7887;
    if (_2353 && (_7697 <= 0.0))
    {
        _7887 = -_7700;
    }
    else
    {
        _7887 = _7700;
    }
    float3 _2365 = fast::normalize(_192._m4.xyz);
    float3 _2371 = _192._m6.xyz - in.m_1741;
    float3 _2372 = fast::normalize(_2371);
    float3 _2377 = fast::normalize(_2365 + _2372);
    float3 _2383 = _2227 * (gl_FrontFacing ? 1.0 : (-1.0));
    bool _2388 = in.m_2385.x > 0.5;
    float3 _7881;
    float _7921;
    if ((_192._m5.w > 0.5) && _2388)
    {
        float _7757;
        float3 _7758;
        do
        {
            int _3926 = int(_192._m21.x);
            float _3934 = dot(_192._m20.xyz, in.m_1741) + _192._m20.w;
            int _7702;
            _7702 = 0;
            for (;;)
            {
                bool _3940 = _7702 < (_3926 - 1);
                bool _3948;
                if (_3940)
                {
                    _3948 = _3934 > _192._m16[_7702];
                }
                else
                {
                    _3948 = _3940;
                }
                if (_3948)
                {
                    _7702++;
                    continue;
                }
                else
                {
                    break;
                }
            }
            if (_3934 > _192._m16[_7702])
            {
                _7758 = float3(1.0);
                _7757 = 1.0;
                break;
            }
            float _7715;
            do
            {
                float4 _4050 = _192._m14[_7702] * float4(in.m_1741 + (_2383 * _192._m18[_7702]), 1.0);
                float _4053 = _4050.x;
                bool _4054 = _4053 < 0.0;
                bool _4061;
                if (!_4054)
                {
                    _4061 = _4053 > 1.0;
                }
                else
                {
                    _4061 = _4054;
                }
                bool _4068;
                if (!_4061)
                {
                    _4068 = _4050.y < 0.0;
                }
                else
                {
                    _4068 = _4061;
                }
                bool _4075;
                if (!_4068)
                {
                    _4075 = _4050.y > 1.0;
                }
                else
                {
                    _4075 = _4068;
                }
                if (_4075)
                {
                    _7715 = 1.0;
                    break;
                }
                float2 _4088 = float2(float(_7702 & 1), float(_7702 >> 1)) * _192._m23.xy;
                float _4095 = fast::min(_4050.z, 1.0) - _192._m19[_7702];
                float2 _4114 = _192._m22.xy * 0.5;
                float2 _4119 = _4088 + (_4050.xy * _192._m23.xy);
                float4 _4132 = float4(_4088 + _4114, (_4088 + _192._m23.xy) - _4114);
                float _7714;
                do
                {
                    int _4158 = int(_192._m22.z);
                    if (_4158 <= 0)
                    {
                        _7714 = spvDepthCast(_212).sample_compare(_212Smplr, float3(fast::clamp(_4119, _4132.xy, _4132.zw), _4095).xy, _4095);
                        break;
                    }
                    float2 _4181 = (_4119 / _192._m22.xy) + float2(0.5);
                    float2 _4182 = floor(_4181);
                    float2 _4187 = _4181 - _4182;
                    float2 _4190 = _4182 - float2(0.5);
                    bool _4194 = _4158 == 1;
                    spvUnsafeArray<float2, 3> _4142;
                    spvUnsafeArray<float2, 3> _4143;
                    if (_4194)
                    {
                        float2 _4197 = _4187 * 2.0;
                        _4142[0] = float2(3.0) - _4197;
                        _4142[1] = float2(1.0) + _4197;
                        _4143[0] = ((float2(2.0) - _4187) / _4142[0]) - float2(1.0);
                        _4143[1] = (_4187 / _4142[1]) + float2(1.0);
                    }
                    else
                    {
                        float2 _4224 = _4187 * 3.0;
                        _4142[0] = float2(4.0) - _4224;
                        _4142[1] = float2(7.0);
                        _4142[2] = float2(1.0) + _4224;
                        _4143[0] = ((float2(3.0) - (_4187 * 2.0)) / _4142[0]) - float2(2.0);
                        _4143[1] = (float2(3.0) + _4187) / _4142[1];
                        _4143[2] = (_4187 / _4142[2]) + float2(2.0);
                    }
                    int _8476 = _4194 ? 2 : 3;
                    int _7704;
                    float _7707;
                    _7707 = 0.0;
                    _7704 = 0;
                    float _7713;
                    for (; _7704 < _8476; _7707 = _7713, _7704++)
                    {
                        _7713 = _7707;
                        for (int _7710 = 0; _7710 < _8476; )
                        {
                            _7713 += ((_4142[_7710].x * _4142[_7704].y) * spvDepthCast(_212).sample_compare(_212Smplr, float3(fast::clamp(_192._m22.xy * (_4190 + float2(_4143[_7710].x, _4143[_7704].y)), _4132.xy, _4132.zw), _4095).xy, _4095));
                            _7710++;
                            continue;
                        }
                    }
                    _7714 = _7707 * (_4194 ? 0.0625 : 0.0069444444961845874786376953125);
                    break;
                } while(false);
                _7715 = _7714;
                break;
            } while(false);
            float3 _7752;
            float _7755;
            if (_3934 > _192._m17[_7702])
            {
                float _3988 = (_3934 - _192._m17[_7702]) / (_192._m16[_7702] - _192._m17[_7702]);
                int _3990 = _7702 + 1;
                float3 _7753;
                float _7756;
                if (_3990 < _3926)
                {
                    float _7735;
                    do
                    {
                        float4 _4337 = _192._m14[_3990] * float4(in.m_1741 + (_2383 * _192._m18[_3990]), 1.0);
                        float _4340 = _4337.x;
                        bool _4341 = _4340 < 0.0;
                        bool _4348;
                        if (!_4341)
                        {
                            _4348 = _4340 > 1.0;
                        }
                        else
                        {
                            _4348 = _4341;
                        }
                        bool _4355;
                        if (!_4348)
                        {
                            _4355 = _4337.y < 0.0;
                        }
                        else
                        {
                            _4355 = _4348;
                        }
                        bool _4362;
                        if (!_4355)
                        {
                            _4362 = _4337.y > 1.0;
                        }
                        else
                        {
                            _4362 = _4355;
                        }
                        if (_4362)
                        {
                            _7735 = 1.0;
                            break;
                        }
                        float2 _4375 = float2(float(_3990 & 1), float(_3990 >> 1)) * _192._m23.xy;
                        float _4382 = fast::min(_4337.z, 1.0) - _192._m19[_3990];
                        float2 _4401 = _192._m22.xy * 0.5;
                        float2 _4406 = _4375 + (_4337.xy * _192._m23.xy);
                        float4 _4419 = float4(_4375 + _4401, (_4375 + _192._m23.xy) - _4401);
                        float _7734;
                        do
                        {
                            int _4445 = int(_192._m22.z);
                            if (_4445 <= 0)
                            {
                                _7734 = spvDepthCast(_212).sample_compare(_212Smplr, float3(fast::clamp(_4406, _4419.xy, _4419.zw), _4382).xy, _4382);
                                break;
                            }
                            float2 _4468 = (_4406 / _192._m22.xy) + float2(0.5);
                            float2 _4469 = floor(_4468);
                            float2 _4474 = _4468 - _4469;
                            float2 _4477 = _4469 - float2(0.5);
                            bool _4481 = _4445 == 1;
                            spvUnsafeArray<float2, 3> _4429;
                            spvUnsafeArray<float2, 3> _4430;
                            if (_4481)
                            {
                                float2 _4484 = _4474 * 2.0;
                                _4429[0] = float2(3.0) - _4484;
                                _4429[1] = float2(1.0) + _4484;
                                _4430[0] = ((float2(2.0) - _4474) / _4429[0]) - float2(1.0);
                                _4430[1] = (_4474 / _4429[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _4511 = _4474 * 3.0;
                                _4429[0] = float2(4.0) - _4511;
                                _4429[1] = float2(7.0);
                                _4429[2] = float2(1.0) + _4511;
                                _4430[0] = ((float2(3.0) - (_4474 * 2.0)) / _4429[0]) - float2(2.0);
                                _4430[1] = (float2(3.0) + _4474) / _4429[1];
                                _4430[2] = (_4474 / _4429[2]) + float2(2.0);
                            }
                            int _8478 = _4481 ? 2 : 3;
                            int _7724;
                            float _7727;
                            _7727 = 0.0;
                            _7724 = 0;
                            float _7733;
                            for (; _7724 < _8478; _7727 = _7733, _7724++)
                            {
                                _7733 = _7727;
                                for (int _7730 = 0; _7730 < _8478; )
                                {
                                    _7733 += ((_4429[_7730].x * _4429[_7724].y) * spvDepthCast(_212).sample_compare(_212Smplr, float3(fast::clamp(_192._m22.xy * (_4477 + float2(_4430[_7730].x, _4430[_7724].y)), _4419.xy, _4419.zw), _4382).xy, _4382));
                                    _7730++;
                                    continue;
                                }
                            }
                            _7734 = _7727 * (_4481 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _7735 = _7734;
                        break;
                    } while(false);
                    _7756 = mix(_7715, _7735, _3988);
                    _7753 = mix(_566[_7702], _566[_3990], float3(_3988));
                }
                else
                {
                    _7756 = mix(_7715, 1.0, _3988);
                    _7753 = _566[_7702];
                }
                _7755 = _7756;
                _7752 = _7753;
            }
            else
            {
                _7755 = _7715;
                _7752 = _566[_7702];
            }
            _7758 = select(float3(1.0), _7752, bool3(_192._m22.w > 0.5));
            _7757 = _7755;
            break;
        } while(false);
        _7921 = _7757;
        _7881 = _7787 * _7758;
    }
    else
    {
        _7921 = 1.0;
        _7881 = _7787;
    }
    float3 _2414 = _192._m5.xyz * _192._m4.w;
    bool _2418 = _1579._m6.w > 0.5;
    float _7810;
    if (_2418)
    {
        _7810 = 1.0;
    }
    else
    {
        _7810 = 1.0 + (_1579._m4.w * (_2057.sample(_1229, _2124).x - 1.0));
    }
    float _2438 = abs(in.m_1655.w);
    float _8011;
    if (_2438 > 0.0)
    {
        _8011 = _7810 * fast::min(_2438, 1.0);
    }
    else
    {
        _8011 = _7810;
    }
    float3 _8169;
    if (!_2335)
    {
        float _2454 = dot(_7887, _2365);
        float3 _8161;
        if (_192._m29.x > 0.5)
        {
            float _4662 = (_192._m29.z * _7887.x) - (_192._m29.w * _7887.z);
            float _4675 = (_192._m29.w * _7887.x) + (_192._m29.z * _7887.z);
            float _4693 = 1.09254801273345947265625 * _4662;
            spvUnsafeArray<float, 9> _7425 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _7887.y, 0.48860299587249755859375 * _4675, 0.48860299587249755859375 * _4662, _4693 * _7887.y, (1.09254801273345947265625 * _7887.y) * _4675, 0.3153919875621795654296875 * (((3.0 * _4675) * _4675) - 1.0), _4693 * _4675, 0.546274006366729736328125 * ((_4662 * _4662) - (_7887.y * _7887.y)) });
            spvUnsafeArray<float, 9> _4607 = _7425;
            float3 _8160;
            _8160 = float3(0.0);
            for (int _8159 = 0; _8159 < 9; )
            {
                _8160 += (_1227.read(uint2((int2(496, 256) + int2(_8159, 0))), 0).xyz * _4607[_8159]);
                _8159++;
                continue;
            }
            _8161 = fast::max(_8160, float3(0.0)) * _192._m29.y;
        }
        else
        {
            _8161 = mix(_192._m9.xyz, _192._m8.xyz, float3((_7887.y * 0.5) + 0.5)) * _192._m8.w;
        }
        float3 _2504 = (_7881 * ((_8161 * _8011) + ((_2414 * fast::max(_2454, 0.0)) * _7921))) + ((_2414 * ((powr(fast::max(dot(_7887, _2377), 0.0), _1579._m1.w) * _1579._m1.z) * step(0.0, _2454))) * _7921);
        float3 _8170;
        if (_192._m13.w > 0.5)
        {
            float2 _4778 = fast::clamp(floor(gl_FragCoord.xy * _192._m12.xy), float2(0.0), _192._m13.xy - float2(1.0));
            uint _4806 = uint((((fast::clamp(floor((log2(fast::max(dot(_192._m11.xyz, in.m_1741) + _192._m11.w, 9.9999999747524270787835121154785e-07)) * _192._m12.z) + _192._m12.w), 0.0, _192._m13.z - 1.0) * _192._m13.y) + _4778.y) * _192._m13.x) + _4778.x);
            uint _4808 = _4806 >> uint(2);
            uint _4810 = _4806 & 3u;
            uint _4814 = _1872._m0[_4808][_4810] & 65535u;
            uint _4816 = _1872._m0[_4808][_4810] >> uint(16);
            float3 _8171;
            _8171 = _2504;
            float3 _2585;
            spvUnsafeArray<float2, 3> _5224;
            spvUnsafeArray<float2, 3> _5225;
            spvUnsafeArray<float2, 3> _5437;
            spvUnsafeArray<float2, 3> _5438;
            for (uint _8168 = _4814; _8168 < (_4814 + _4816); _8171 = _2585, _8168++)
            {
                uint _4822 = _8168 / 3u;
                uint _4835 = (_1893._m0[_4822 >> uint(2)][_4822 & 3u] >> ((_8168 - (_4822 * 3u)) * 10u)) & 1023u;
                float3 _4852 = _1734._m0[_4835].xyz - in.m_1741;
                float _4855 = dot(_4852, _4852);
                float _4859 = _4855 * _1734._m0[_4835].w;
                float _4864 = fast::clamp(1.0 - (_4859 * _4859), 0.0, 1.0);
                float3 _4869 = _4852 * rsqrt(fast::max(_4855, 9.9999999392252902907785028219223e-09));
                float _4887 = fast::clamp((dot(-_4869, _1777._m0[_4835].xyz) * _1769._m0[_4835].w) + _1777._m0[_4835].w, 0.0, 1.0);
                float3 _4900 = _1769._m0[_4835].xyz * ((((_4864 * _4864) * _4887) * _4887) / fast::max(_4855, 9.9999997473787516355514526367188e-05));
                float3 _8376;
                if (_2388)
                {
                    float _8322;
                    do
                    {
                        uint _4936 = uint(_192._m21.z);
                        if (_4835 < _4936)
                        {
                            float _4958 = _192._m26[_4835].z * fast::max((_192._m15[_4835] * float4(in.m_1741, 1.0)).w, 0.0);
                            float4 _4982 = _192._m15[_4835] * float4((in.m_1741 + (_2383 * (_4958 * _192._m25.x))) + (_4869 * (_4958 * _192._m25.y)), 1.0);
                            float _4984 = _4982.w;
                            if (_4984 <= 0.0)
                            {
                                _8322 = 1.0;
                                break;
                            }
                            float3 _4993 = _4982.xyz / float3(_4984);
                            float _4995 = _4993.x;
                            bool _4996 = _4995 < 0.0;
                            bool _5003;
                            if (!_4996)
                            {
                                _5003 = _4995 > 1.0;
                            }
                            else
                            {
                                _5003 = _4996;
                            }
                            bool _5010;
                            if (!_5003)
                            {
                                _5010 = _4993.y < 0.0;
                            }
                            else
                            {
                                _5010 = _5003;
                            }
                            bool _5017;
                            if (!_5010)
                            {
                                _5017 = _4993.y > 1.0;
                            }
                            else
                            {
                                _5017 = _5010;
                            }
                            bool _5024;
                            if (!_5017)
                            {
                                _5024 = _4993.z > 1.0;
                            }
                            else
                            {
                                _5024 = _5017;
                            }
                            if (_5024)
                            {
                                _8322 = 1.0;
                                break;
                            }
                            float _5030 = _4993.z;
                            float2 _5196 = _192._m22.xy * 0.5;
                            float2 _5201 = _192._m26[_4835].xy + (_4993.xy * _192._m23.zw);
                            float4 _5214 = float4(_192._m26[_4835].xy + _5196, (_192._m26[_4835].xy + _192._m23.zw) - _5196);
                            float _8321;
                            do
                            {
                                int _5240 = int(_192._m22.z);
                                if (_5240 <= 0)
                                {
                                    float2 _5250 = fast::clamp(_5201, _5214.xy, _5214.zw);
                                    _8321 = spvDepthCast(_212).sample_compare(_212Smplr, float3(_5250, _5030).xy, _5030);
                                    break;
                                }
                                float2 _5263 = (_5201 / _192._m22.xy) + float2(0.5);
                                float2 _5264 = floor(_5263);
                                float2 _5269 = _5263 - _5264;
                                float2 _5272 = _5264 - float2(0.5);
                                bool _5276 = _5240 == 1;
                                if (_5276)
                                {
                                    float2 _5279 = _5269 * 2.0;
                                    _5224[0] = float2(3.0) - _5279;
                                    _5224[1] = float2(1.0) + _5279;
                                    _5225[0] = ((float2(2.0) - _5269) / _5224[0]) - float2(1.0);
                                    _5225[1] = (_5269 / _5224[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _5306 = _5269 * 3.0;
                                    _5224[0] = float2(4.0) - _5306;
                                    _5224[1] = float2(7.0);
                                    _5224[2] = float2(1.0) + _5306;
                                    _5225[0] = ((float2(3.0) - (_5269 * 2.0)) / _5224[0]) - float2(2.0);
                                    _5225[1] = (float2(3.0) + _5269) / _5224[1];
                                    _5225[2] = (_5269 / _5224[2]) + float2(2.0);
                                }
                                int _8483 = _5276 ? 2 : 3;
                                int _8311;
                                float _8314;
                                _8314 = 0.0;
                                _8311 = 0;
                                float _8320;
                                for (; _8311 < _8483; _8314 = _8320, _8311++)
                                {
                                    _8320 = _8314;
                                    for (int _8317 = 0; _8317 < _8483; )
                                    {
                                        _8320 += ((_5224[_8317].x * _5224[_8311].y) * spvDepthCast(_212).sample_compare(_212Smplr, float3(fast::clamp(_192._m22.xy * (_5272 + float2(_5225[_8317].x, _5225[_8311].y)), _5214.xy, _5214.zw), _5030).xy, _5030));
                                        _8317++;
                                        continue;
                                    }
                                }
                                _8321 = _8314 * (_5276 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _8322 = _8321;
                            break;
                        }
                        uint _5040 = _4835 - _4936;
                        if (_5040 >= uint(_192._m21.w))
                        {
                            _8322 = 1.0;
                            break;
                        }
                        float _5061 = _192._m27[_5040].w * length(in.m_1741 - _192._m27[_5040].xyz);
                        float3 _5079 = ((in.m_1741 + (_2383 * (_5061 * _192._m25.x))) + (_4869 * (_5061 * _192._m25.y))) - _192._m27[_5040].xyz;
                        float3 _5081 = abs(_5079);
                        float _5083 = _5081.x;
                        float _5085 = _5081.y;
                        bool _5086 = _5083 >= _5085;
                        bool _5094;
                        if (_5086)
                        {
                            _5094 = _5083 >= _5081.z;
                        }
                        else
                        {
                            _5094 = _5086;
                        }
                        float _8296;
                        int _8298;
                        if (_5094)
                        {
                            _8298 = (_5079.x > 0.0) ? 0 : 1;
                            _8296 = _5083;
                        }
                        else
                        {
                            float _5106 = _5081.z;
                            bool _5107 = _5085 >= _5106;
                            int _8299;
                            if (_5107)
                            {
                                _8299 = (_5079.y > 0.0) ? 2 : 3;
                            }
                            else
                            {
                                _8299 = (_5079.z > 0.0) ? 4 : 5;
                            }
                            _8298 = _8299;
                            _8296 = _5107 ? _5085 : _5106;
                        }
                        if (_8296 <= 0.0)
                        {
                            _8322 = 1.0;
                            break;
                        }
                        float2 _5144 = float2(dot(_5079, _870[_8298]), dot(_5079, _879[_8298])) / float2(_8296 * _192._m24.z);
                        float _5151 = _192._m28[_5040].z + (_192._m28[_5040].w / _8296);
                        if (_5151 > 1.0)
                        {
                            _8322 = 1.0;
                            break;
                        }
                        float2 _5169 = _192._m28[_5040].xy + (float2(float(spvSMod(_8298, 3)), float(_8298 / 3)) * _192._m24.xy);
                        float2 _5409 = _192._m22.xy * 0.5;
                        float2 _5414 = _5169 + (float2(0.5 + (0.5 * _5144.x), 0.5 - (0.5 * _5144.y)) * _192._m24.xy);
                        float4 _5427 = float4(_5169 + _5409, (_5169 + _192._m24.xy) - _5409);
                        float _8310;
                        do
                        {
                            int _5453 = int(_192._m22.z);
                            if (_5453 <= 0)
                            {
                                _8310 = spvDepthCast(_212).sample_compare(_212Smplr, float3(fast::clamp(_5414, _5427.xy, _5427.zw), _5151).xy, _5151);
                                break;
                            }
                            float2 _5476 = (_5414 / _192._m22.xy) + float2(0.5);
                            float2 _5477 = floor(_5476);
                            float2 _5482 = _5476 - _5477;
                            float2 _5485 = _5477 - float2(0.5);
                            bool _5489 = _5453 == 1;
                            if (_5489)
                            {
                                float2 _5492 = _5482 * 2.0;
                                _5437[0] = float2(3.0) - _5492;
                                _5437[1] = float2(1.0) + _5492;
                                _5438[0] = ((float2(2.0) - _5482) / _5437[0]) - float2(1.0);
                                _5438[1] = (_5482 / _5437[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _5519 = _5482 * 3.0;
                                _5437[0] = float2(4.0) - _5519;
                                _5437[1] = float2(7.0);
                                _5437[2] = float2(1.0) + _5519;
                                _5438[0] = ((float2(3.0) - (_5482 * 2.0)) / _5437[0]) - float2(2.0);
                                _5438[1] = (float2(3.0) + _5482) / _5437[1];
                                _5438[2] = (_5482 / _5437[2]) + float2(2.0);
                            }
                            int _8486 = _5489 ? 2 : 3;
                            int _8300;
                            float _8303;
                            _8303 = 0.0;
                            _8300 = 0;
                            float _8309;
                            for (; _8300 < _8486; _8303 = _8309, _8300++)
                            {
                                _8309 = _8303;
                                for (int _8306 = 0; _8306 < _8486; )
                                {
                                    _8309 += ((_5437[_8306].x * _5437[_8300].y) * spvDepthCast(_212).sample_compare(_212Smplr, float3(fast::clamp(_192._m22.xy * (_5485 + float2(_5438[_8306].x, _5438[_8300].y)), _5427.xy, _5427.zw), _5151).xy, _5151));
                                    _8306++;
                                    continue;
                                }
                            }
                            _8310 = _8303 * (_5489 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _8322 = _8310;
                        break;
                    } while(false);
                    _8376 = _4900 * _8322;
                }
                else
                {
                    _8376 = _4900;
                }
                float _2556 = dot(_7887, _4869);
                _2585 = _8171 + (((_7881 * fast::max(_2556, 0.0)) * _8376) + (_8376 * ((powr(fast::max(dot(_7887, fast::normalize(_4869 + _2372)), 0.0), _1579._m1.w) * _1579._m1.z) * step(0.0, _2556))));
            }
            _8170 = _8171;
        }
        else
        {
            _8170 = _2504;
        }
        _8169 = _8170;
    }
    else
    {
        float4 _2595 = _2590.sample(_1229, _2124);
        float _2606 = fast::clamp((_1579._m4.x * _2595.z) * in.m_2602.y, 0.0, 1.0);
        float _2617 = fast::clamp((_1579._m4.y * _2595.y) * in.m_2602.x, 0.04500000178813934326171875, 1.0);
        float _7877;
        float _7882;
        if (_7818 > 0.0)
        {
            _7882 = mix(_2606, _7851.y, _7818);
            _7877 = mix(_2617, fast::max(_7851.x, 0.04500000178813934326171875), _7818);
        }
        else
        {
            _7882 = _2606;
            _7877 = _2617;
        }
        float _2636 = _7877 * _7877;
        float3 _2641 = _7881 * (1.0 - _7882);
        float3 _2647 = mix(float3(0.039999999105930328369140625), _7881, float3(_7882));
        bool _2651 = _7697 > 0.0;
        float3 _7910;
        if (_2651)
        {
            float3 _2656 = dfdx(in.m_1741);
            float3 _2658 = dfdy(in.m_1741);
            float3 _2659 = cross(_2656, _2658);
            float3 _7911;
            if (dot(_2659, _2659) > 9.9999996826552253889678874634872e-21)
            {
                _7911 = fast::normalize((fast::normalize(_2659) * ((dot(_2659, _2372) < 0.0) ? (-1.0) : 1.0)) + (_7887 - _2227));
            }
            else
            {
                _7911 = _7887;
            }
            _7910 = _7911;
        }
        else
        {
            _7910 = _7887;
        }
        float _2685 = fast::max(dot(_7910, _2372), 9.9999997473787516355514526367188e-05);
        float _2694 = dot(_7910, _2365);
        float _2695 = fast::clamp(_2694, 0.0, 1.0);
        float _2700 = fast::clamp(dot(_7910, _2377), 0.0, 1.0);
        float _2705 = fast::clamp(dot(_2372, _2377), 0.0, 1.0);
        float _7914;
        float _7915;
        if (_2651)
        {
            _7915 = fast::max(_2685, 0.5);
            _7914 = fast::max(_2705, 0.5);
        }
        else
        {
            _7915 = _2685;
            _7914 = _2705;
        }
        float3 _5621 = float3(1.0) - _2647;
        float3 _5624 = _2647 + (_5621 * powr(1.0 - _7914, 5.0));
        float _5631 = _2636 * _2636;
        float _5636 = _5631 - 1.0;
        float _5638 = ((_2700 * _2700) * _5636) + 1.0;
        float _5658 = 1.0 - _5631;
        float _5662 = sqrt(((_7915 * _7915) * _5658) + _5631);
        float3 _2751 = (((((float3(1.0) - _5624) * _2641) * fast::clamp(dot(_7887, _2365), 0.0, 1.0)) + (((_5624 * ((_5631 / ((3.1415927410125732421875 * _5638) * _5638)) * (0.5 / fast::max((_2695 * _5662) + (_7915 * sqrt(((_2695 * _2695) * _5658) + _5631)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875) * _2695)) * _2414) * _7921;
        float3 _8025;
        if (_2651)
        {
            _8025 = _2751 + (((((_2641 * _2414) * _7921) * _7697) * fast::clamp(-_2694, 0.0, 1.0)) * (0.3499999940395355224609375 + (0.64999997615814208984375 * powr(fast::clamp(dot(-_2372, _2365), 0.0, 1.0), 3.0))));
        }
        else
        {
            _8025 = _2751;
        }
        float3 _7951;
        float2 _7975;
        float3 _7987;
        if (_192._m29.x > 0.5)
        {
            float4 _5695 = _1333.sample(_1335, (((float2(_7915, _7877) * 31.0) + float2(0.5)) * float2(0.03125)));
            float _5754 = (_192._m29.z * _7887.x) - (_192._m29.w * _7887.z);
            float _5767 = (_192._m29.w * _7887.x) + (_192._m29.z * _7887.z);
            float _5785 = 1.09254801273345947265625 * _5754;
            spvUnsafeArray<float, 9> _7406 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _7887.y, 0.48860299587249755859375 * _5767, 0.48860299587249755859375 * _5754, _5785 * _7887.y, (1.09254801273345947265625 * _7887.y) * _5767, 0.3153919875621795654296875 * (((3.0 * _5767) * _5767) - 1.0), _5785 * _5767, 0.546274006366729736328125 * ((_5754 * _5754) - (_7887.y * _7887.y)) });
            spvUnsafeArray<float, 9> _5699 = _7406;
            float3 _7933;
            _7933 = float3(0.0);
            for (int _7932 = 0; _7932 < 9; )
            {
                _7933 += (_1227.read(uint2((int2(496, 256) + int2(_7932, 0))), 0).xyz * _5699[_7932]);
                _7932++;
                continue;
            }
            float3 _2803 = reflect(-_2372, _7910);
            float _5880 = _2803.x;
            float _5885 = _2803.z;
            float2 _5917 = float2((precise::atan2((_192._m29.z * _5880) - (_192._m29.w * _5885), -((_192._m29.w * _5880) + (_192._m29.z * _5885))) * 0.15915493667125701904296875) + 0.5, acos(fast::clamp(_2803.y, -1.0, 1.0)) * 0.3183098733425140380859375);
            float _5849 = _7877 * 5.0;
            int _5852 = min(int(_5849), 4);
            float2 _5938 = (_5917 * float2(_1289[_5852].zw)) - float2(0.5);
            float2 _5940 = floor(_5938);
            float2 _5943 = _5938 - _5940;
            int _5946 = int(_5940.x);
            int _5949 = int(_5940.y);
            int _7936;
            if (_5946 < 0)
            {
                _7936 = _5946 + _1289[_5852].z;
            }
            else
            {
                _7936 = _5946;
            }
            int _7937;
            if (_7936 >= _1289[_5852].z)
            {
                _7937 = _7936 - _1289[_5852].z;
            }
            else
            {
                _7937 = _7936;
            }
            int _5969 = _7937 + 1;
            int _8487 = (_5969 == _1289[_5852].z) ? 0 : _5969;
            int _5984 = min((_5949 + 1), (_1289[_5852].w - 1));
            int _5986 = max(_5949, 0);
            float3 _6039 = float3(_5943.x);
            int _5859 = _5852 + 1;
            float2 _6071 = (_5917 * float2(_1289[_5859].zw)) - float2(0.5);
            float2 _6073 = floor(_6071);
            float2 _6076 = _6071 - _6073;
            int _6079 = int(_6073.x);
            int _6082 = int(_6073.y);
            int _7943;
            if (_6079 < 0)
            {
                _7943 = _6079 + _1289[_5859].z;
            }
            else
            {
                _7943 = _6079;
            }
            int _7944;
            if (_7943 >= _1289[_5859].z)
            {
                _7944 = _7943 - _1289[_5859].z;
            }
            else
            {
                _7944 = _7943;
            }
            int _6102 = _7944 + 1;
            int _8488 = (_6102 == _1289[_5859].z) ? 0 : _6102;
            int _6117 = min((_6082 + 1), (_1289[_5859].w - 1));
            int _6119 = max(_6082, 0);
            float3 _6172 = float3(_6076.x);
            float3 _5874 = mix(mix(mix(_1227.read(uint2((_1289[_5852].xy + int2(_7937, _5986))), 0).xyz, _1227.read(uint2((_1289[_5852].xy + int2(_8487, _5986))), 0).xyz, _6039), mix(_1227.read(uint2((_1289[_5852].xy + int2(_7937, _5984))), 0).xyz, _1227.read(uint2((_1289[_5852].xy + int2(_8487, _5984))), 0).xyz, _6039), float3(_5943.y)), mix(mix(_1227.read(uint2((_1289[_5859].xy + int2(_7944, _6119))), 0).xyz, _1227.read(uint2((_1289[_5859].xy + int2(_8488, _6119))), 0).xyz, _6172), mix(_1227.read(uint2((_1289[_5859].xy + int2(_7944, _6117))), 0).xyz, _1227.read(uint2((_1289[_5859].xy + int2(_8488, _6117))), 0).xyz, _6172), float3(_6076.y)), float3(_5849 - float(_5852))) * _192._m29.y;
            _7987 = fast::max(_7933, float3(0.0)) * _192._m29.y;
            _7975 = _5695.xy;
            _7951 = _5874;
        }
        else
        {
            float4 _6190 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * _7877) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);
            float _6192 = _6190.x;
            float3 _6227 = mix(_192._m9.xyz, _192._m8.xyz, float3((_7887.y * 0.5) + 0.5)) * _192._m8.w;
            _7987 = _6227;
            _7975 = (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_6192 * _6192, exp2((-9.27999973297119140625) * _7915)) * _6192) + _6190.y)) + _6190.zw;
            _7951 = mix(mix(_192._m9.xyz, _192._m8.xyz, float3((reflect(-_2372, _7910).y * 0.5) + 0.5)) * _192._m8.w, _6227, float3(_7877));
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
        float3 _7996;
        if (_2835)
        {
            float3 _7972;
            do
            {
                float _6306 = ((_192._m32.x * (1.0 - smoothstep(_192._m33.x * 0.5, _192._m33.x, abs(dot(_192._m31.xyz, in.m_1741) - _192._m31.w)))) * smoothstep(0.5, 0.89999997615814208984375, dot(_2383, _192._m31.xyz))) * (1.0 - smoothstep(_192._m32.y * 0.5, _192._m32.y, _7877));
                if (_6306 <= 0.0)
                {
                    _7972 = _7951;
                    break;
                }
                float4 _6331 = _192._m30 * float4(in.m_1741 + ((_7887 - (_192._m31.xyz * dot(_7887, _192._m31.xyz))) * _192._m32.w), 1.0);
                float2 _6344 = ((float2(_6331.x, -_6331.y) / float2(_6331.w)) * 0.5) + float2(0.5);
                float _6348 = _192._m32.z * _7877;
                float3 _7970;
                float _7971;
                _7971 = 0.0;
                _7970 = float3(0.0);
                for (int _7969 = 0; _7969 < 12; )
                {
                    float _6355 = float(_7969);
                    float _6363 = _6355 * 2.3999631404876708984375;
                    float2 _6375 = _6344 + (float2(cos(_6363) * _192._m33.y, sin(_6363)) * (sqrt((_6355 + 0.5) * 0.083333335816860198974609375) * _6348));
                    float2 _6380 = fast::min(_6375, float2(1.0) - _6375);
                    float _6386 = smoothstep(0.0, 0.039999999105930328369140625, fast::min(_6380.x, _6380.y));
                    float4 _6394 = _2057.sample(_1229, fast::clamp(_6375, float2(0.0), float2(1.0)), level(0.0));
                    float3 _6396 = _6394.xyz;
                    _7971 += (_6394.w * _6386);
                    _7970 += ((_6396 / (float3(1.0) - fast::min(_6396, float3(0.99500000476837158203125)))) * _6386);
                    _7969++;
                    continue;
                }
                _7972 = mix(_7951, (_7970 * float3(0.083333335816860198974609375)) + (_7951 * (1.0 - (_7971 * 0.083333335816860198974609375))), float3(_6306));
                break;
            } while(false);
            _7996 = _7972;
        }
        else
        {
            _7996 = _7951;
        }
        float3 _2855 = (_2647 * _7975.x) + float3(_7975.y);
        float3 _2871 = _8025 + (((((float3(1.0) - _2855) * _2641) * _7987) + (_2855 * _7996)) * _8011);
        float3 _8172;
        if (_192._m13.w > 0.5)
        {
            float2 _6460 = fast::clamp(floor(gl_FragCoord.xy * _192._m12.xy), float2(0.0), _192._m13.xy - float2(1.0));
            uint _6488 = uint((((fast::clamp(floor((log2(fast::max(dot(_192._m11.xyz, in.m_1741) + _192._m11.w, 9.9999999747524270787835121154785e-07)) * _192._m12.z) + _192._m12.w), 0.0, _192._m13.z - 1.0) * _192._m13.y) + _6460.y) * _192._m13.x) + _6460.x);
            uint _6490 = _6488 >> uint(2);
            uint _6492 = _6488 & 3u;
            uint _6496 = _1872._m0[_6490][_6492] & 65535u;
            uint _6498 = _1872._m0[_6490][_6492] >> uint(16);
            float3 _8125;
            _8125 = _2871;
            float3 _2971;
            spvUnsafeArray<float2, 3> _6906;
            spvUnsafeArray<float2, 3> _6907;
            spvUnsafeArray<float2, 3> _7119;
            spvUnsafeArray<float2, 3> _7120;
            for (uint _8028 = _6496; _8028 < (_6496 + _6498); _8125 = _2971, _8028++)
            {
                uint _6504 = _8028 / 3u;
                uint _6517 = (_1893._m0[_6504 >> uint(2)][_6504 & 3u] >> ((_8028 - (_6504 * 3u)) * 10u)) & 1023u;
                float3 _6534 = _1734._m0[_6517].xyz - in.m_1741;
                float _6537 = dot(_6534, _6534);
                float _6541 = _6537 * _1734._m0[_6517].w;
                float _6546 = fast::clamp(1.0 - (_6541 * _6541), 0.0, 1.0);
                float3 _6551 = _6534 * rsqrt(fast::max(_6537, 9.9999999392252902907785028219223e-09));
                float _6569 = fast::clamp((dot(-_6551, _1777._m0[_6517].xyz) * _1769._m0[_6517].w) + _1777._m0[_6517].w, 0.0, 1.0);
                float3 _6582 = _1769._m0[_6517].xyz * ((((_6546 * _6546) * _6569) * _6569) / fast::max(_6537, 9.9999997473787516355514526367188e-05));
                float3 _8123;
                if (_2388)
                {
                    float _8055;
                    do
                    {
                        uint _6618 = uint(_192._m21.z);
                        if (_6517 < _6618)
                        {
                            float _6640 = _192._m26[_6517].z * fast::max((_192._m15[_6517] * float4(in.m_1741, 1.0)).w, 0.0);
                            float4 _6664 = _192._m15[_6517] * float4((in.m_1741 + (_2383 * (_6640 * _192._m25.x))) + (_6551 * (_6640 * _192._m25.y)), 1.0);
                            float _6666 = _6664.w;
                            if (_6666 <= 0.0)
                            {
                                _8055 = 1.0;
                                break;
                            }
                            float3 _6675 = _6664.xyz / float3(_6666);
                            float _6677 = _6675.x;
                            bool _6678 = _6677 < 0.0;
                            bool _6685;
                            if (!_6678)
                            {
                                _6685 = _6677 > 1.0;
                            }
                            else
                            {
                                _6685 = _6678;
                            }
                            bool _6692;
                            if (!_6685)
                            {
                                _6692 = _6675.y < 0.0;
                            }
                            else
                            {
                                _6692 = _6685;
                            }
                            bool _6699;
                            if (!_6692)
                            {
                                _6699 = _6675.y > 1.0;
                            }
                            else
                            {
                                _6699 = _6692;
                            }
                            bool _6706;
                            if (!_6699)
                            {
                                _6706 = _6675.z > 1.0;
                            }
                            else
                            {
                                _6706 = _6699;
                            }
                            if (_6706)
                            {
                                _8055 = 1.0;
                                break;
                            }
                            float _6712 = _6675.z;
                            float2 _6878 = _192._m22.xy * 0.5;
                            float2 _6883 = _192._m26[_6517].xy + (_6675.xy * _192._m23.zw);
                            float4 _6896 = float4(_192._m26[_6517].xy + _6878, (_192._m26[_6517].xy + _192._m23.zw) - _6878);
                            float _8054;
                            do
                            {
                                int _6922 = int(_192._m22.z);
                                if (_6922 <= 0)
                                {
                                    float2 _6932 = fast::clamp(_6883, _6896.xy, _6896.zw);
                                    _8054 = spvDepthCast(_212).sample_compare(_212Smplr, float3(_6932, _6712).xy, _6712);
                                    break;
                                }
                                float2 _6945 = (_6883 / _192._m22.xy) + float2(0.5);
                                float2 _6946 = floor(_6945);
                                float2 _6951 = _6945 - _6946;
                                float2 _6954 = _6946 - float2(0.5);
                                bool _6958 = _6922 == 1;
                                if (_6958)
                                {
                                    float2 _6961 = _6951 * 2.0;
                                    _6906[0] = float2(3.0) - _6961;
                                    _6906[1] = float2(1.0) + _6961;
                                    _6907[0] = ((float2(2.0) - _6951) / _6906[0]) - float2(1.0);
                                    _6907[1] = (_6951 / _6906[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _6988 = _6951 * 3.0;
                                    _6906[0] = float2(4.0) - _6988;
                                    _6906[1] = float2(7.0);
                                    _6906[2] = float2(1.0) + _6988;
                                    _6907[0] = ((float2(3.0) - (_6951 * 2.0)) / _6906[0]) - float2(2.0);
                                    _6907[1] = (float2(3.0) + _6951) / _6906[1];
                                    _6907[2] = (_6951 / _6906[2]) + float2(2.0);
                                }
                                int _8490 = _6958 ? 2 : 3;
                                int _8044;
                                float _8047;
                                _8047 = 0.0;
                                _8044 = 0;
                                float _8053;
                                for (; _8044 < _8490; _8047 = _8053, _8044++)
                                {
                                    _8053 = _8047;
                                    for (int _8050 = 0; _8050 < _8490; )
                                    {
                                        _8053 += ((_6906[_8050].x * _6906[_8044].y) * spvDepthCast(_212).sample_compare(_212Smplr, float3(fast::clamp(_192._m22.xy * (_6954 + float2(_6907[_8050].x, _6907[_8044].y)), _6896.xy, _6896.zw), _6712).xy, _6712));
                                        _8050++;
                                        continue;
                                    }
                                }
                                _8054 = _8047 * (_6958 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _8055 = _8054;
                            break;
                        }
                        uint _6722 = _6517 - _6618;
                        if (_6722 >= uint(_192._m21.w))
                        {
                            _8055 = 1.0;
                            break;
                        }
                        float _6743 = _192._m27[_6722].w * length(in.m_1741 - _192._m27[_6722].xyz);
                        float3 _6761 = ((in.m_1741 + (_2383 * (_6743 * _192._m25.x))) + (_6551 * (_6743 * _192._m25.y))) - _192._m27[_6722].xyz;
                        float3 _6763 = abs(_6761);
                        float _6765 = _6763.x;
                        float _6767 = _6763.y;
                        bool _6768 = _6765 >= _6767;
                        bool _6776;
                        if (_6768)
                        {
                            _6776 = _6765 >= _6763.z;
                        }
                        else
                        {
                            _6776 = _6768;
                        }
                        float _8029;
                        int _8031;
                        if (_6776)
                        {
                            _8031 = (_6761.x > 0.0) ? 0 : 1;
                            _8029 = _6765;
                        }
                        else
                        {
                            float _6788 = _6763.z;
                            bool _6789 = _6767 >= _6788;
                            int _8032;
                            if (_6789)
                            {
                                _8032 = (_6761.y > 0.0) ? 2 : 3;
                            }
                            else
                            {
                                _8032 = (_6761.z > 0.0) ? 4 : 5;
                            }
                            _8031 = _8032;
                            _8029 = _6789 ? _6767 : _6788;
                        }
                        if (_8029 <= 0.0)
                        {
                            _8055 = 1.0;
                            break;
                        }
                        float2 _6826 = float2(dot(_6761, _870[_8031]), dot(_6761, _879[_8031])) / float2(_8029 * _192._m24.z);
                        float _6833 = _192._m28[_6722].z + (_192._m28[_6722].w / _8029);
                        if (_6833 > 1.0)
                        {
                            _8055 = 1.0;
                            break;
                        }
                        float2 _6851 = _192._m28[_6722].xy + (float2(float(spvSMod(_8031, 3)), float(_8031 / 3)) * _192._m24.xy);
                        float2 _7091 = _192._m22.xy * 0.5;
                        float2 _7096 = _6851 + (float2(0.5 + (0.5 * _6826.x), 0.5 - (0.5 * _6826.y)) * _192._m24.xy);
                        float4 _7109 = float4(_6851 + _7091, (_6851 + _192._m24.xy) - _7091);
                        float _8043;
                        do
                        {
                            int _7135 = int(_192._m22.z);
                            if (_7135 <= 0)
                            {
                                _8043 = spvDepthCast(_212).sample_compare(_212Smplr, float3(fast::clamp(_7096, _7109.xy, _7109.zw), _6833).xy, _6833);
                                break;
                            }
                            float2 _7158 = (_7096 / _192._m22.xy) + float2(0.5);
                            float2 _7159 = floor(_7158);
                            float2 _7164 = _7158 - _7159;
                            float2 _7167 = _7159 - float2(0.5);
                            bool _7171 = _7135 == 1;
                            if (_7171)
                            {
                                float2 _7174 = _7164 * 2.0;
                                _7119[0] = float2(3.0) - _7174;
                                _7119[1] = float2(1.0) + _7174;
                                _7120[0] = ((float2(2.0) - _7164) / _7119[0]) - float2(1.0);
                                _7120[1] = (_7164 / _7119[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _7201 = _7164 * 3.0;
                                _7119[0] = float2(4.0) - _7201;
                                _7119[1] = float2(7.0);
                                _7119[2] = float2(1.0) + _7201;
                                _7120[0] = ((float2(3.0) - (_7164 * 2.0)) / _7119[0]) - float2(2.0);
                                _7120[1] = (float2(3.0) + _7164) / _7119[1];
                                _7120[2] = (_7164 / _7119[2]) + float2(2.0);
                            }
                            int _8493 = _7171 ? 2 : 3;
                            int _8033;
                            float _8036;
                            _8036 = 0.0;
                            _8033 = 0;
                            float _8042;
                            for (; _8033 < _8493; _8036 = _8042, _8033++)
                            {
                                _8042 = _8036;
                                for (int _8039 = 0; _8039 < _8493; )
                                {
                                    _8042 += ((_7119[_8039].x * _7119[_8033].y) * spvDepthCast(_212).sample_compare(_212Smplr, float3(fast::clamp(_192._m22.xy * (_7167 + float2(_7120[_8039].x, _7120[_8033].y)), _7109.xy, _7109.zw), _6833).xy, _6833));
                                    _8039++;
                                    continue;
                                }
                            }
                            _8043 = _8036 * (_7171 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _8055 = _8043;
                        break;
                    } while(false);
                    _8123 = _6582 * _8055;
                }
                else
                {
                    _8123 = _6582;
                }
                float3 _2923 = fast::normalize(_6551 + _2372);
                float _2928 = fast::clamp(dot(_7887, _6551), 0.0, 1.0);
                float _2933 = fast::clamp(dot(_7887, _2923), 0.0, 1.0);
                float3 _7306 = _2647 + (_5621 * powr(1.0 - fast::clamp(dot(_2372, _2923), 0.0, 1.0), 5.0));
                float _7320 = ((_2933 * _2933) * _5636) + 1.0;
                _2971 = _8125 + (((((float3(1.0) - _7306) * _2641) + ((_7306 * ((_5631 / ((3.1415927410125732421875 * _7320) * _7320)) * (0.5 / fast::max((_2928 * _5662) + (_7915 * sqrt(((_2928 * _2928) * _5658) + _5631)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875)) * _2928) * _8123);
            }
            _8172 = _8125;
        }
        else
        {
            _8172 = _2871;
        }
        _8169 = _8172;
    }
    float4 _2988 = _2983.sample(_1229, _2124);
    float _3009 = -length(_2371);
    float _8214;
    if (_192._m9.w != 0.0)
    {
        float _3033 = _192._m9.w * (in.m_1741 - _192._m6.xyz).y;
        float _8211;
        if (abs(_3033) < 9.9999997473787516355514526367188e-05)
        {
            _8211 = 1.0 - (0.5 * _3033);
        }
        else
        {
            _8211 = (1.0 - exp(fast::min(-_3033, 60.0))) / _3033;
        }
        _8214 = 1.0 - exp((_3009 * (_192._m7.w * exp(fast::min((-_192._m9.w) * (_192._m6.y - _192._m6.w), 30.0)))) * _8211);
    }
    else
    {
        _8214 = 1.0 - exp(_3009 * _192._m7.w);
    }
    float3 _3084 = mix(mix(_8169, _7881, float3(_1579._m1.y)) + (((_1579._m5.xyz * _2988.xyz) * (float3(1.0) + in.m_2385.yzw)) * in.m_2602.z), _192._m7.xyz, float3(_8214));
    float3 _8215;
    if (_192._m33.w > 0.5)
    {
        _8215 = _3084 / (float3(1.0) + _3084);
    }
    else
    {
        _8215 = _3084;
    }
    out.m_3096 = float4(_8215, in.m_2133.w * in.m_2166.w);
    float2 _8295;
    do
    {
        if (in.m_3106.w <= 0.0)
        {
            _8295 = float2(0.0);
            break;
        }
        _8295 = ((in.m_3106.xy / float2(in.m_3106.w)) - (in.m_3105.xy / float2(in.m_3105.w))) * float2(0.5, -0.5);
        break;
    } while(false);
    _3104 = _8295;
    return out;
}

