// Generated from mesh_paint.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 2d83a2b2d60e16c7
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
    float4 m_3083 [[color(0)]];
    float2 m_3091 [[color(1)]];
};

struct fragment_main_in
{
    float3 m_1741 [[user(locn0)]];
    float3 m_1649 [[user(locn1)]];
    float2 m_2110 [[user(locn2)]];
    float4 m_2133 [[user(locn3)]];
    float3 m_1684 [[user(locn4)]];
    float4 m_2372 [[user(locn5)]];
    float4 m_3092 [[user(locn6)]];
    float4 m_3093 [[user(locn7)]];
    float4 m_1655 [[user(locn8)]];
    float4 m_2153 [[user(locn9)]];
    float4 m_2589 [[user(locn10)]];
};

fragment fragment_main_out fragment_main(fragment_main_in in [[stage_in]], constant _1577& _1579 [[buffer(2)]], constant _1732& _1734 [[buffer(3)]], constant _1767& _1769 [[buffer(4)]], constant _1775& _1777 [[buffer(5)]], constant _1870& _1872 [[buffer(6)]], constant _1891& _1893 [[buffer(7)]], constant _190& _192 [[buffer(15)]], texture2d<float> _212 [[texture(0)]], texture2d<float> _2126 [[texture(1)]], texture2d<float> _2577 [[texture(2)]], texture2d<float> _2249 [[texture(3)]], texture2d<float> _2057 [[texture(4)]], texture2d<float> _2970 [[texture(5)]], texture2d<float> _1227 [[texture(6)]], texture2d<float> _1333 [[texture(7)]], sampler _212Smplr [[sampler(0)]], sampler _1229 [[sampler(1)]], sampler _1335 [[sampler(7)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])
{
    fragment_main_out out = {};
    float2 _2124 = float2(dot(_1579._m2.xy, in.m_2110) + _1579._m2.z, dot(_1579._m3.xy, in.m_2110) + _1579._m3.z);
    float4 _2131 = _2126.sample(_1229, _2124);
    float3 _2141 = _2131.xyz;
    float3 _2157 = ((in.m_2133.xyz * _1579._m0.xyz) * _2141) * in.m_2153.xyz;
    float3 _7676;
    if (_1579._m1.x > 0.5)
    {
        float2 _2172 = floor(in.m_1741.xz * float2(0.5));
        _7676 = _2157 * ((mod(abs(_2172.x + _2172.y), 2.0) < 0.5) ? 1.0 : 0.75);
    }
    else
    {
        _7676 = _2157;
    }
    float3 _7773;
    float _7804;
    float2 _7837;
    if (_1579._m3.w > 0.5)
    {
        float3 _3194;
        float2 _3201;
        float _7674;
        do
        {
            float3 _3165 = float4(_1579._m2.w, _1579._m3.w, 0.0, 0.0).xyy;
            float3 _3168 = floor(_3165 * float3(1.52587890625e-05));
            float3 _3173 = _3165 - (_3168 * 65536.0);
            float3 _3176 = floor(_3173 * float3(0.00390625));
            float3 _3184 = _3173 - (_3176 * 256.0);
            _3194 = (float3(_3184.x, _3176.x, _3168.x) * float3(0.0039215688593685626983642578125)) * 2.0;
            _3201 = float2(_3184.y, _3176.y) * float2(0.0039215688593685626983642578125);
            float _3204 = _3168.y - 128.0;
            float _3210 = floor(_3204 * 0.03125) * 0.3333333432674407958984375;
            float3 _3216 = fast::normalize(in.m_1649);
            float _3220 = dot(_3216, in.m_1655.xyz);
            float _3232 = (_3220 / fast::max(length(in.m_1655.xyz - (_3216 * _3220)), 9.9999999747524270787835121154785e-07)) * 25.5;
            if (((-24.0) + _3232) < (-2.0))
            {
                _7674 = 0.0;
                break;
            }
            float3 _3240 = in.m_1684 * (4.0 * exp2(mod(_3204, 32.0) * 0.3333333432674407958984375));
            float3 _3284 = floor(_3240);
            float3 _3287 = _3240 - _3284;
            float3 _3295 = (_3287 * _3287) * (float3(3.0) - (_3287 * 2.0));
            uint3 _3362 = uint3(int3(_3284));
            uint _3375 = (((_3362.x * 1597334677u) ^ (_3362.y * 3812015801u)) ^ (_3362.z * 2798796415u)) * 1597334677u;
            uint3 _3390 = uint3(int3(_3284 + float3(1.0, 0.0, 0.0)));
            uint _3403 = (((_3390.x * 1597334677u) ^ (_3390.y * 3812015801u)) ^ (_3390.z * 2798796415u)) * 1597334677u;
            float _3304 = _3295.x;
            uint3 _3418 = uint3(int3(_3284 + float3(0.0, 1.0, 0.0)));
            uint _3431 = (((_3418.x * 1597334677u) ^ (_3418.y * 3812015801u)) ^ (_3418.z * 2798796415u)) * 1597334677u;
            uint3 _3446 = uint3(int3(_3284 + float3(1.0, 1.0, 0.0)));
            uint _3459 = (((_3446.x * 1597334677u) ^ (_3446.y * 3812015801u)) ^ (_3446.z * 2798796415u)) * 1597334677u;
            float _3320 = _3295.y;
            uint3 _3474 = uint3(int3(_3284 + float3(0.0, 0.0, 1.0)));
            uint _3487 = (((_3474.x * 1597334677u) ^ (_3474.y * 3812015801u)) ^ (_3474.z * 2798796415u)) * 1597334677u;
            uint3 _3502 = uint3(int3(_3284 + float3(1.0, 0.0, 1.0)));
            uint _3515 = (((_3502.x * 1597334677u) ^ (_3502.y * 3812015801u)) ^ (_3502.z * 2798796415u)) * 1597334677u;
            uint3 _3530 = uint3(int3(_3284 + float3(0.0, 1.0, 1.0)));
            uint _3543 = (((_3530.x * 1597334677u) ^ (_3530.y * 3812015801u)) ^ (_3530.z * 2798796415u)) * 1597334677u;
            uint3 _3558 = uint3(int3(_3284 + float3(1.0)));
            uint _3571 = (((_3558.x * 1597334677u) ^ (_3558.y * 3812015801u)) ^ (_3558.z * 2798796415u)) * 1597334677u;
            float3 _3246 = (_3240 * 2.7000000476837158203125) + float3(17.299999237060546875, 5.099999904632568359375, 9.69999980926513671875);
            float3 _3597 = floor(_3246);
            float3 _3600 = _3246 - _3597;
            float3 _3608 = (_3600 * _3600) * (float3(3.0) - (_3600 * 2.0));
            uint3 _3675 = uint3(int3(_3597));
            uint _3688 = (((_3675.x * 1597334677u) ^ (_3675.y * 3812015801u)) ^ (_3675.z * 2798796415u)) * 1597334677u;
            uint3 _3703 = uint3(int3(_3597 + float3(1.0, 0.0, 0.0)));
            uint _3716 = (((_3703.x * 1597334677u) ^ (_3703.y * 3812015801u)) ^ (_3703.z * 2798796415u)) * 1597334677u;
            float _3617 = _3608.x;
            uint3 _3731 = uint3(int3(_3597 + float3(0.0, 1.0, 0.0)));
            uint _3744 = (((_3731.x * 1597334677u) ^ (_3731.y * 3812015801u)) ^ (_3731.z * 2798796415u)) * 1597334677u;
            uint3 _3759 = uint3(int3(_3597 + float3(1.0, 1.0, 0.0)));
            uint _3772 = (((_3759.x * 1597334677u) ^ (_3759.y * 3812015801u)) ^ (_3759.z * 2798796415u)) * 1597334677u;
            float _3633 = _3608.y;
            uint3 _3787 = uint3(int3(_3597 + float3(0.0, 0.0, 1.0)));
            uint _3800 = (((_3787.x * 1597334677u) ^ (_3787.y * 3812015801u)) ^ (_3787.z * 2798796415u)) * 1597334677u;
            uint3 _3815 = uint3(int3(_3597 + float3(1.0, 0.0, 1.0)));
            uint _3828 = (((_3815.x * 1597334677u) ^ (_3815.y * 3812015801u)) ^ (_3815.z * 2798796415u)) * 1597334677u;
            uint3 _3843 = uint3(int3(_3597 + float3(0.0, 1.0, 1.0)));
            uint _3856 = (((_3843.x * 1597334677u) ^ (_3843.y * 3812015801u)) ^ (_3843.z * 2798796415u)) * 1597334677u;
            uint3 _3871 = uint3(int3(_3597 + float3(1.0)));
            uint _3884 = (((_3871.x * 1597334677u) ^ (_3871.y * 3812015801u)) ^ (_3871.z * 2798796415u)) * 1597334677u;
            float _3251 = mix(0.449999988079071044921875, 0.0500000007450580596923828125, _3210);
            float _3255 = ((mix(mix(mix(float((_3375 ^ (_3375 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_3403 ^ (_3403 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _3304), mix(float((_3431 ^ (_3431 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_3459 ^ (_3459 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _3304), _3320), mix(mix(float((_3487 ^ (_3487 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_3515 ^ (_3515 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _3304), mix(float((_3543 ^ (_3543 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_3571 ^ (_3571 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _3304), _3320), _3295.z) * 0.64999997615814208984375) + (mix(mix(mix(float((_3688 ^ (_3688 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_3716 ^ (_3716 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _3617), mix(float((_3744 ^ (_3744 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_3772 ^ (_3772 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _3617), _3633), mix(mix(float((_3800 ^ (_3800 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_3828 ^ (_3828 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _3617), mix(float((_3856 ^ (_3856 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_3884 ^ (_3884 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _3617), _3633), _3608.z) * 0.3499999940395355224609375)) - 0.5;
            _7674 = smoothstep(-_3251, _3251, (_3232 + (-24.450000762939453125)) + (_3255 * mix(0.800000011920928955078125, 2.2000000476837158203125, _3210)));
            break;
        } while(false);
        _7837 = _3201;
        _7804 = _7674;
        _7773 = mix(_7676, (in.m_2133.xyz * _3194) * mix(float3(1.0), _2141 * 2.0, float3(0.5)), float3(_7674));
    }
    else
    {
        _7837 = float2(0.0);
        _7804 = 0.0;
        _7773 = _7676;
    }
    float3 _2214 = fast::normalize(in.m_1649);
    float3 _7686;
    if (_1579._m6.y > 0.5)
    {
        float3 _2229 = in.m_1655.xyz - (_2214 * dot(_2214, in.m_1655.xyz));
        float3 _7687;
        if (dot(_2229, _2229) > 9.9999999600419720025001879548654e-13)
        {
            float3 _2238 = fast::normalize(_2229);
            float4 _2254 = _2249.sample(_1229, _2124);
            float3 _7678;
            if (_1579._m6.z > 0.5)
            {
                float2 _7677;
                if (_1579._m6.z > 1.5)
                {
                    _7677 = _2254.xw;
                }
                else
                {
                    _7677 = _2254.xy;
                }
                float2 _2276 = (_7677 * 2.0) - float2(1.0);
                _7678 = float3(_2276, sqrt(fast::clamp(1.0 - dot(_2276, _2276), 0.0, 1.0)));
            }
            else
            {
                _7678 = (_2254.xyz * 2.0) - float3(1.0);
            }
            float2 _2298 = _7678.xy * _1579._m4.z;
            _7687 = fast::normalize(((_2238 * _2298.x) + ((cross(_2214, _2238) * ((in.m_1655.w < 0.0) ? (-1.0) : 1.0)) * _2298.y)) + (_2214 * _7678.z));
        }
        else
        {
            _7687 = _2214;
        }
        _7686 = _7687;
    }
    else
    {
        _7686 = _2214;
    }
    bool _2322 = _1579._m5.w > 0.5;
    float _7683;
    if (_2322)
    {
        _7683 = fast::clamp(_1579._m1.z, 0.0, 1.0);
    }
    else
    {
        _7683 = 0.0;
    }
    bool _2340;
    if (_2322)
    {
        _2340 = !gl_FrontFacing;
    }
    else
    {
        _2340 = _2322;
    }
    float3 _7873;
    if (_2340 && (_7683 <= 0.0))
    {
        _7873 = -_7686;
    }
    else
    {
        _7873 = _7686;
    }
    float3 _2352 = fast::normalize(_192._m4.xyz);
    float3 _2358 = _192._m6.xyz - in.m_1741;
    float3 _2359 = fast::normalize(_2358);
    float3 _2364 = fast::normalize(_2352 + _2359);
    float3 _2370 = _2214 * (gl_FrontFacing ? 1.0 : (-1.0));
    bool _2375 = in.m_2372.x > 0.5;
    float3 _7867;
    float _7907;
    if ((_192._m5.w > 0.5) && _2375)
    {
        float _7743;
        float3 _7744;
        do
        {
            int _3913 = int(_192._m21.x);
            float _3921 = dot(_192._m20.xyz, in.m_1741) + _192._m20.w;
            int _7688;
            _7688 = 0;
            for (;;)
            {
                bool _3927 = _7688 < (_3913 - 1);
                bool _3935;
                if (_3927)
                {
                    _3935 = _3921 > _192._m16[_7688];
                }
                else
                {
                    _3935 = _3927;
                }
                if (_3935)
                {
                    _7688++;
                    continue;
                }
                else
                {
                    break;
                }
            }
            if (_3921 > _192._m16[_7688])
            {
                _7744 = float3(1.0);
                _7743 = 1.0;
                break;
            }
            float _7701;
            do
            {
                float4 _4037 = _192._m14[_7688] * float4(in.m_1741 + (_2370 * _192._m18[_7688]), 1.0);
                float _4040 = _4037.x;
                bool _4041 = _4040 < 0.0;
                bool _4048;
                if (!_4041)
                {
                    _4048 = _4040 > 1.0;
                }
                else
                {
                    _4048 = _4041;
                }
                bool _4055;
                if (!_4048)
                {
                    _4055 = _4037.y < 0.0;
                }
                else
                {
                    _4055 = _4048;
                }
                bool _4062;
                if (!_4055)
                {
                    _4062 = _4037.y > 1.0;
                }
                else
                {
                    _4062 = _4055;
                }
                if (_4062)
                {
                    _7701 = 1.0;
                    break;
                }
                float2 _4075 = float2(float(_7688 & 1), float(_7688 >> 1)) * _192._m23.xy;
                float _4082 = fast::min(_4037.z, 1.0) - _192._m19[_7688];
                float2 _4101 = _192._m22.xy * 0.5;
                float2 _4106 = _4075 + (_4037.xy * _192._m23.xy);
                float4 _4119 = float4(_4075 + _4101, (_4075 + _192._m23.xy) - _4101);
                float _7700;
                do
                {
                    int _4145 = int(_192._m22.z);
                    if (_4145 <= 0)
                    {
                        _7700 = spvDepthCast(_212).sample_compare(_212Smplr, float3(fast::clamp(_4106, _4119.xy, _4119.zw), _4082).xy, _4082);
                        break;
                    }
                    float2 _4168 = (_4106 / _192._m22.xy) + float2(0.5);
                    float2 _4169 = floor(_4168);
                    float2 _4174 = _4168 - _4169;
                    float2 _4177 = _4169 - float2(0.5);
                    bool _4181 = _4145 == 1;
                    spvUnsafeArray<float2, 3> _4129;
                    spvUnsafeArray<float2, 3> _4130;
                    if (_4181)
                    {
                        float2 _4184 = _4174 * 2.0;
                        _4129[0] = float2(3.0) - _4184;
                        _4129[1] = float2(1.0) + _4184;
                        _4130[0] = ((float2(2.0) - _4174) / _4129[0]) - float2(1.0);
                        _4130[1] = (_4174 / _4129[1]) + float2(1.0);
                    }
                    else
                    {
                        float2 _4211 = _4174 * 3.0;
                        _4129[0] = float2(4.0) - _4211;
                        _4129[1] = float2(7.0);
                        _4129[2] = float2(1.0) + _4211;
                        _4130[0] = ((float2(3.0) - (_4174 * 2.0)) / _4129[0]) - float2(2.0);
                        _4130[1] = (float2(3.0) + _4174) / _4129[1];
                        _4130[2] = (_4174 / _4129[2]) + float2(2.0);
                    }
                    int _8366 = _4181 ? 2 : 3;
                    int _7690;
                    float _7693;
                    _7693 = 0.0;
                    _7690 = 0;
                    float _7699;
                    for (; _7690 < _8366; _7693 = _7699, _7690++)
                    {
                        _7699 = _7693;
                        for (int _7696 = 0; _7696 < _8366; )
                        {
                            _7699 += ((_4129[_7696].x * _4129[_7690].y) * spvDepthCast(_212).sample_compare(_212Smplr, float3(fast::clamp(_192._m22.xy * (_4177 + float2(_4130[_7696].x, _4130[_7690].y)), _4119.xy, _4119.zw), _4082).xy, _4082));
                            _7696++;
                            continue;
                        }
                    }
                    _7700 = _7693 * (_4181 ? 0.0625 : 0.0069444444961845874786376953125);
                    break;
                } while(false);
                _7701 = _7700;
                break;
            } while(false);
            float3 _7738;
            float _7741;
            if (_3921 > _192._m17[_7688])
            {
                float _3975 = (_3921 - _192._m17[_7688]) / (_192._m16[_7688] - _192._m17[_7688]);
                int _3977 = _7688 + 1;
                float3 _7739;
                float _7742;
                if (_3977 < _3913)
                {
                    float _7721;
                    do
                    {
                        float4 _4324 = _192._m14[_3977] * float4(in.m_1741 + (_2370 * _192._m18[_3977]), 1.0);
                        float _4327 = _4324.x;
                        bool _4328 = _4327 < 0.0;
                        bool _4335;
                        if (!_4328)
                        {
                            _4335 = _4327 > 1.0;
                        }
                        else
                        {
                            _4335 = _4328;
                        }
                        bool _4342;
                        if (!_4335)
                        {
                            _4342 = _4324.y < 0.0;
                        }
                        else
                        {
                            _4342 = _4335;
                        }
                        bool _4349;
                        if (!_4342)
                        {
                            _4349 = _4324.y > 1.0;
                        }
                        else
                        {
                            _4349 = _4342;
                        }
                        if (_4349)
                        {
                            _7721 = 1.0;
                            break;
                        }
                        float2 _4362 = float2(float(_3977 & 1), float(_3977 >> 1)) * _192._m23.xy;
                        float _4369 = fast::min(_4324.z, 1.0) - _192._m19[_3977];
                        float2 _4388 = _192._m22.xy * 0.5;
                        float2 _4393 = _4362 + (_4324.xy * _192._m23.xy);
                        float4 _4406 = float4(_4362 + _4388, (_4362 + _192._m23.xy) - _4388);
                        float _7720;
                        do
                        {
                            int _4432 = int(_192._m22.z);
                            if (_4432 <= 0)
                            {
                                _7720 = spvDepthCast(_212).sample_compare(_212Smplr, float3(fast::clamp(_4393, _4406.xy, _4406.zw), _4369).xy, _4369);
                                break;
                            }
                            float2 _4455 = (_4393 / _192._m22.xy) + float2(0.5);
                            float2 _4456 = floor(_4455);
                            float2 _4461 = _4455 - _4456;
                            float2 _4464 = _4456 - float2(0.5);
                            bool _4468 = _4432 == 1;
                            spvUnsafeArray<float2, 3> _4416;
                            spvUnsafeArray<float2, 3> _4417;
                            if (_4468)
                            {
                                float2 _4471 = _4461 * 2.0;
                                _4416[0] = float2(3.0) - _4471;
                                _4416[1] = float2(1.0) + _4471;
                                _4417[0] = ((float2(2.0) - _4461) / _4416[0]) - float2(1.0);
                                _4417[1] = (_4461 / _4416[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _4498 = _4461 * 3.0;
                                _4416[0] = float2(4.0) - _4498;
                                _4416[1] = float2(7.0);
                                _4416[2] = float2(1.0) + _4498;
                                _4417[0] = ((float2(3.0) - (_4461 * 2.0)) / _4416[0]) - float2(2.0);
                                _4417[1] = (float2(3.0) + _4461) / _4416[1];
                                _4417[2] = (_4461 / _4416[2]) + float2(2.0);
                            }
                            int _8368 = _4468 ? 2 : 3;
                            int _7710;
                            float _7713;
                            _7713 = 0.0;
                            _7710 = 0;
                            float _7719;
                            for (; _7710 < _8368; _7713 = _7719, _7710++)
                            {
                                _7719 = _7713;
                                for (int _7716 = 0; _7716 < _8368; )
                                {
                                    _7719 += ((_4416[_7716].x * _4416[_7710].y) * spvDepthCast(_212).sample_compare(_212Smplr, float3(fast::clamp(_192._m22.xy * (_4464 + float2(_4417[_7716].x, _4417[_7710].y)), _4406.xy, _4406.zw), _4369).xy, _4369));
                                    _7716++;
                                    continue;
                                }
                            }
                            _7720 = _7713 * (_4468 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _7721 = _7720;
                        break;
                    } while(false);
                    _7742 = mix(_7701, _7721, _3975);
                    _7739 = mix(_566[_7688], _566[_3977], float3(_3975));
                }
                else
                {
                    _7742 = mix(_7701, 1.0, _3975);
                    _7739 = _566[_7688];
                }
                _7741 = _7742;
                _7738 = _7739;
            }
            else
            {
                _7741 = _7701;
                _7738 = _566[_7688];
            }
            _7744 = select(float3(1.0), _7738, bool3(_192._m22.w > 0.5));
            _7743 = _7741;
            break;
        } while(false);
        _7907 = _7743;
        _7867 = _7773 * _7744;
    }
    else
    {
        _7907 = 1.0;
        _7867 = _7773;
    }
    float3 _2401 = _192._m5.xyz * _192._m4.w;
    bool _2405 = _1579._m6.w > 0.5;
    float _7796;
    if (_2405)
    {
        _7796 = 1.0;
    }
    else
    {
        _7796 = 1.0 + (_1579._m4.w * (_2057.sample(_1229, _2124).x - 1.0));
    }
    float _2425 = abs(in.m_1655.w);
    float _7997;
    if (_2425 > 0.0)
    {
        _7997 = _7796 * fast::min(_2425, 1.0);
    }
    else
    {
        _7997 = _7796;
    }
    float3 _8155;
    if (!_2322)
    {
        float _2441 = dot(_7873, _2352);
        float3 _8147;
        if (_192._m29.x > 0.5)
        {
            float _4649 = (_192._m29.z * _7873.x) - (_192._m29.w * _7873.z);
            float _4662 = (_192._m29.w * _7873.x) + (_192._m29.z * _7873.z);
            float _4680 = 1.09254801273345947265625 * _4649;
            spvUnsafeArray<float, 9> _7412 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _7873.y, 0.48860299587249755859375 * _4662, 0.48860299587249755859375 * _4649, _4680 * _7873.y, (1.09254801273345947265625 * _7873.y) * _4662, 0.3153919875621795654296875 * (((3.0 * _4662) * _4662) - 1.0), _4680 * _4662, 0.546274006366729736328125 * ((_4649 * _4649) - (_7873.y * _7873.y)) });
            spvUnsafeArray<float, 9> _4594 = _7412;
            float3 _8146;
            _8146 = float3(0.0);
            for (int _8145 = 0; _8145 < 9; )
            {
                _8146 += (_1227.read(uint2((int2(496, 256) + int2(_8145, 0))), 0).xyz * _4594[_8145]);
                _8145++;
                continue;
            }
            _8147 = fast::max(_8146, float3(0.0)) * _192._m29.y;
        }
        else
        {
            _8147 = mix(_192._m9.xyz, _192._m8.xyz, float3((_7873.y * 0.5) + 0.5)) * _192._m8.w;
        }
        float3 _2491 = (_7867 * ((_8147 * _7997) + ((_2401 * fast::max(_2441, 0.0)) * _7907))) + ((_2401 * ((powr(fast::max(dot(_7873, _2364), 0.0), _1579._m1.w) * _1579._m1.z) * step(0.0, _2441))) * _7907);
        float3 _8156;
        if (_192._m13.w > 0.5)
        {
            float2 _4765 = fast::clamp(floor(gl_FragCoord.xy * _192._m12.xy), float2(0.0), _192._m13.xy - float2(1.0));
            uint _4793 = uint((((fast::clamp(floor((log2(fast::max(dot(_192._m11.xyz, in.m_1741) + _192._m11.w, 9.9999999747524270787835121154785e-07)) * _192._m12.z) + _192._m12.w), 0.0, _192._m13.z - 1.0) * _192._m13.y) + _4765.y) * _192._m13.x) + _4765.x);
            uint _4795 = _4793 >> uint(2);
            uint _4797 = _4793 & 3u;
            uint _4801 = _1872._m0[_4795][_4797] & 65535u;
            uint _4803 = _1872._m0[_4795][_4797] >> uint(16);
            float3 _8157;
            _8157 = _2491;
            float3 _2572;
            spvUnsafeArray<float2, 3> _5211;
            spvUnsafeArray<float2, 3> _5212;
            spvUnsafeArray<float2, 3> _5424;
            spvUnsafeArray<float2, 3> _5425;
            for (uint _8154 = _4801; _8154 < (_4801 + _4803); _8157 = _2572, _8154++)
            {
                uint _4809 = _8154 / 3u;
                uint _4822 = (_1893._m0[_4809 >> uint(2)][_4809 & 3u] >> ((_8154 - (_4809 * 3u)) * 10u)) & 1023u;
                float3 _4839 = _1734._m0[_4822].xyz - in.m_1741;
                float _4842 = dot(_4839, _4839);
                float _4846 = _4842 * _1734._m0[_4822].w;
                float _4851 = fast::clamp(1.0 - (_4846 * _4846), 0.0, 1.0);
                float3 _4856 = _4839 * rsqrt(fast::max(_4842, 9.9999999392252902907785028219223e-09));
                float _4874 = fast::clamp((dot(-_4856, _1777._m0[_4822].xyz) * _1769._m0[_4822].w) + _1777._m0[_4822].w, 0.0, 1.0);
                float3 _4887 = _1769._m0[_4822].xyz * ((((_4851 * _4851) * _4874) * _4874) / fast::max(_4842, 9.9999997473787516355514526367188e-05));
                float3 _8283;
                if (_2375)
                {
                    float _8229;
                    do
                    {
                        uint _4923 = uint(_192._m21.z);
                        if (_4822 < _4923)
                        {
                            float _4945 = _192._m26[_4822].z * fast::max((_192._m15[_4822] * float4(in.m_1741, 1.0)).w, 0.0);
                            float4 _4969 = _192._m15[_4822] * float4((in.m_1741 + (_2370 * (_4945 * _192._m25.x))) + (_4856 * (_4945 * _192._m25.y)), 1.0);
                            float _4971 = _4969.w;
                            if (_4971 <= 0.0)
                            {
                                _8229 = 1.0;
                                break;
                            }
                            float3 _4980 = _4969.xyz / float3(_4971);
                            float _4982 = _4980.x;
                            bool _4983 = _4982 < 0.0;
                            bool _4990;
                            if (!_4983)
                            {
                                _4990 = _4982 > 1.0;
                            }
                            else
                            {
                                _4990 = _4983;
                            }
                            bool _4997;
                            if (!_4990)
                            {
                                _4997 = _4980.y < 0.0;
                            }
                            else
                            {
                                _4997 = _4990;
                            }
                            bool _5004;
                            if (!_4997)
                            {
                                _5004 = _4980.y > 1.0;
                            }
                            else
                            {
                                _5004 = _4997;
                            }
                            bool _5011;
                            if (!_5004)
                            {
                                _5011 = _4980.z > 1.0;
                            }
                            else
                            {
                                _5011 = _5004;
                            }
                            if (_5011)
                            {
                                _8229 = 1.0;
                                break;
                            }
                            float _5017 = _4980.z;
                            float2 _5183 = _192._m22.xy * 0.5;
                            float2 _5188 = _192._m26[_4822].xy + (_4980.xy * _192._m23.zw);
                            float4 _5201 = float4(_192._m26[_4822].xy + _5183, (_192._m26[_4822].xy + _192._m23.zw) - _5183);
                            float _8228;
                            do
                            {
                                int _5227 = int(_192._m22.z);
                                if (_5227 <= 0)
                                {
                                    float2 _5237 = fast::clamp(_5188, _5201.xy, _5201.zw);
                                    _8228 = spvDepthCast(_212).sample_compare(_212Smplr, float3(_5237, _5017).xy, _5017);
                                    break;
                                }
                                float2 _5250 = (_5188 / _192._m22.xy) + float2(0.5);
                                float2 _5251 = floor(_5250);
                                float2 _5256 = _5250 - _5251;
                                float2 _5259 = _5251 - float2(0.5);
                                bool _5263 = _5227 == 1;
                                if (_5263)
                                {
                                    float2 _5266 = _5256 * 2.0;
                                    _5211[0] = float2(3.0) - _5266;
                                    _5211[1] = float2(1.0) + _5266;
                                    _5212[0] = ((float2(2.0) - _5256) / _5211[0]) - float2(1.0);
                                    _5212[1] = (_5256 / _5211[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _5293 = _5256 * 3.0;
                                    _5211[0] = float2(4.0) - _5293;
                                    _5211[1] = float2(7.0);
                                    _5211[2] = float2(1.0) + _5293;
                                    _5212[0] = ((float2(3.0) - (_5256 * 2.0)) / _5211[0]) - float2(2.0);
                                    _5212[1] = (float2(3.0) + _5256) / _5211[1];
                                    _5212[2] = (_5256 / _5211[2]) + float2(2.0);
                                }
                                int _8373 = _5263 ? 2 : 3;
                                int _8218;
                                float _8221;
                                _8221 = 0.0;
                                _8218 = 0;
                                float _8227;
                                for (; _8218 < _8373; _8221 = _8227, _8218++)
                                {
                                    _8227 = _8221;
                                    for (int _8224 = 0; _8224 < _8373; )
                                    {
                                        _8227 += ((_5211[_8224].x * _5211[_8218].y) * spvDepthCast(_212).sample_compare(_212Smplr, float3(fast::clamp(_192._m22.xy * (_5259 + float2(_5212[_8224].x, _5212[_8218].y)), _5201.xy, _5201.zw), _5017).xy, _5017));
                                        _8224++;
                                        continue;
                                    }
                                }
                                _8228 = _8221 * (_5263 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _8229 = _8228;
                            break;
                        }
                        uint _5027 = _4822 - _4923;
                        if (_5027 >= uint(_192._m21.w))
                        {
                            _8229 = 1.0;
                            break;
                        }
                        float _5048 = _192._m27[_5027].w * length(in.m_1741 - _192._m27[_5027].xyz);
                        float3 _5066 = ((in.m_1741 + (_2370 * (_5048 * _192._m25.x))) + (_4856 * (_5048 * _192._m25.y))) - _192._m27[_5027].xyz;
                        float3 _5068 = abs(_5066);
                        float _5070 = _5068.x;
                        float _5072 = _5068.y;
                        bool _5073 = _5070 >= _5072;
                        bool _5081;
                        if (_5073)
                        {
                            _5081 = _5070 >= _5068.z;
                        }
                        else
                        {
                            _5081 = _5073;
                        }
                        float _8203;
                        int _8205;
                        if (_5081)
                        {
                            _8205 = (_5066.x > 0.0) ? 0 : 1;
                            _8203 = _5070;
                        }
                        else
                        {
                            float _5093 = _5068.z;
                            bool _5094 = _5072 >= _5093;
                            int _8206;
                            if (_5094)
                            {
                                _8206 = (_5066.y > 0.0) ? 2 : 3;
                            }
                            else
                            {
                                _8206 = (_5066.z > 0.0) ? 4 : 5;
                            }
                            _8205 = _8206;
                            _8203 = _5094 ? _5072 : _5093;
                        }
                        if (_8203 <= 0.0)
                        {
                            _8229 = 1.0;
                            break;
                        }
                        float2 _5131 = float2(dot(_5066, _870[_8205]), dot(_5066, _879[_8205])) / float2(_8203 * _192._m24.z);
                        float _5138 = _192._m28[_5027].z + (_192._m28[_5027].w / _8203);
                        if (_5138 > 1.0)
                        {
                            _8229 = 1.0;
                            break;
                        }
                        float2 _5156 = _192._m28[_5027].xy + (float2(float(spvSMod(_8205, 3)), float(_8205 / 3)) * _192._m24.xy);
                        float2 _5396 = _192._m22.xy * 0.5;
                        float2 _5401 = _5156 + (float2(0.5 + (0.5 * _5131.x), 0.5 - (0.5 * _5131.y)) * _192._m24.xy);
                        float4 _5414 = float4(_5156 + _5396, (_5156 + _192._m24.xy) - _5396);
                        float _8217;
                        do
                        {
                            int _5440 = int(_192._m22.z);
                            if (_5440 <= 0)
                            {
                                _8217 = spvDepthCast(_212).sample_compare(_212Smplr, float3(fast::clamp(_5401, _5414.xy, _5414.zw), _5138).xy, _5138);
                                break;
                            }
                            float2 _5463 = (_5401 / _192._m22.xy) + float2(0.5);
                            float2 _5464 = floor(_5463);
                            float2 _5469 = _5463 - _5464;
                            float2 _5472 = _5464 - float2(0.5);
                            bool _5476 = _5440 == 1;
                            if (_5476)
                            {
                                float2 _5479 = _5469 * 2.0;
                                _5424[0] = float2(3.0) - _5479;
                                _5424[1] = float2(1.0) + _5479;
                                _5425[0] = ((float2(2.0) - _5469) / _5424[0]) - float2(1.0);
                                _5425[1] = (_5469 / _5424[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _5506 = _5469 * 3.0;
                                _5424[0] = float2(4.0) - _5506;
                                _5424[1] = float2(7.0);
                                _5424[2] = float2(1.0) + _5506;
                                _5425[0] = ((float2(3.0) - (_5469 * 2.0)) / _5424[0]) - float2(2.0);
                                _5425[1] = (float2(3.0) + _5469) / _5424[1];
                                _5425[2] = (_5469 / _5424[2]) + float2(2.0);
                            }
                            int _8376 = _5476 ? 2 : 3;
                            int _8207;
                            float _8210;
                            _8210 = 0.0;
                            _8207 = 0;
                            float _8216;
                            for (; _8207 < _8376; _8210 = _8216, _8207++)
                            {
                                _8216 = _8210;
                                for (int _8213 = 0; _8213 < _8376; )
                                {
                                    _8216 += ((_5424[_8213].x * _5424[_8207].y) * spvDepthCast(_212).sample_compare(_212Smplr, float3(fast::clamp(_192._m22.xy * (_5472 + float2(_5425[_8213].x, _5425[_8207].y)), _5414.xy, _5414.zw), _5138).xy, _5138));
                                    _8213++;
                                    continue;
                                }
                            }
                            _8217 = _8210 * (_5476 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _8229 = _8217;
                        break;
                    } while(false);
                    _8283 = _4887 * _8229;
                }
                else
                {
                    _8283 = _4887;
                }
                float _2543 = dot(_7873, _4856);
                _2572 = _8157 + (((_7867 * fast::max(_2543, 0.0)) * _8283) + (_8283 * ((powr(fast::max(dot(_7873, fast::normalize(_4856 + _2359)), 0.0), _1579._m1.w) * _1579._m1.z) * step(0.0, _2543))));
            }
            _8156 = _8157;
        }
        else
        {
            _8156 = _2491;
        }
        _8155 = _8156;
    }
    else
    {
        float4 _2582 = _2577.sample(_1229, _2124);
        float _2593 = fast::clamp((_1579._m4.x * _2582.z) * in.m_2589.y, 0.0, 1.0);
        float _2604 = fast::clamp((_1579._m4.y * _2582.y) * in.m_2589.x, 0.04500000178813934326171875, 1.0);
        float _7863;
        float _7868;
        if (_7804 > 0.0)
        {
            _7868 = mix(_2593, _7837.y, _7804);
            _7863 = mix(_2604, fast::max(_7837.x, 0.04500000178813934326171875), _7804);
        }
        else
        {
            _7868 = _2593;
            _7863 = _2604;
        }
        float _2623 = _7863 * _7863;
        float3 _2628 = _7867 * (1.0 - _7868);
        float3 _2634 = mix(float3(0.039999999105930328369140625), _7867, float3(_7868));
        bool _2638 = _7683 > 0.0;
        float3 _7896;
        if (_2638)
        {
            float3 _2643 = dfdx(in.m_1741);
            float3 _2645 = dfdy(in.m_1741);
            float3 _2646 = cross(_2643, _2645);
            float3 _7897;
            if (dot(_2646, _2646) > 9.9999996826552253889678874634872e-21)
            {
                _7897 = fast::normalize((fast::normalize(_2646) * ((dot(_2646, _2359) < 0.0) ? (-1.0) : 1.0)) + (_7873 - _2214));
            }
            else
            {
                _7897 = _7873;
            }
            _7896 = _7897;
        }
        else
        {
            _7896 = _7873;
        }
        float _2672 = fast::max(dot(_7896, _2359), 9.9999997473787516355514526367188e-05);
        float _2681 = dot(_7896, _2352);
        float _2682 = fast::clamp(_2681, 0.0, 1.0);
        float _2687 = fast::clamp(dot(_7896, _2364), 0.0, 1.0);
        float _2692 = fast::clamp(dot(_2359, _2364), 0.0, 1.0);
        float _7900;
        float _7901;
        if (_2638)
        {
            _7901 = fast::max(_2672, 0.5);
            _7900 = fast::max(_2692, 0.5);
        }
        else
        {
            _7901 = _2672;
            _7900 = _2692;
        }
        float3 _5608 = float3(1.0) - _2634;
        float3 _5611 = _2634 + (_5608 * powr(1.0 - _7900, 5.0));
        float _5618 = _2623 * _2623;
        float _5623 = _5618 - 1.0;
        float _5625 = ((_2687 * _2687) * _5623) + 1.0;
        float _5645 = 1.0 - _5618;
        float _5649 = sqrt(((_7901 * _7901) * _5645) + _5618);
        float3 _2738 = (((((float3(1.0) - _5611) * _2628) * fast::clamp(dot(_7873, _2352), 0.0, 1.0)) + (((_5611 * ((_5618 / ((3.1415927410125732421875 * _5625) * _5625)) * (0.5 / fast::max((_2682 * _5649) + (_7901 * sqrt(((_2682 * _2682) * _5645) + _5618)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875) * _2682)) * _2401) * _7907;
        float3 _8011;
        if (_2638)
        {
            _8011 = _2738 + (((((_2628 * _2401) * _7907) * _7683) * fast::clamp(-_2681, 0.0, 1.0)) * (0.3499999940395355224609375 + (0.64999997615814208984375 * powr(fast::clamp(dot(-_2359, _2352), 0.0, 1.0), 3.0))));
        }
        else
        {
            _8011 = _2738;
        }
        float3 _7937;
        float2 _7961;
        float3 _7973;
        if (_192._m29.x > 0.5)
        {
            float4 _5682 = _1333.sample(_1335, (((float2(_7901, _7863) * 31.0) + float2(0.5)) * float2(0.03125)));
            float _5741 = (_192._m29.z * _7873.x) - (_192._m29.w * _7873.z);
            float _5754 = (_192._m29.w * _7873.x) + (_192._m29.z * _7873.z);
            float _5772 = 1.09254801273345947265625 * _5741;
            spvUnsafeArray<float, 9> _7393 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _7873.y, 0.48860299587249755859375 * _5754, 0.48860299587249755859375 * _5741, _5772 * _7873.y, (1.09254801273345947265625 * _7873.y) * _5754, 0.3153919875621795654296875 * (((3.0 * _5754) * _5754) - 1.0), _5772 * _5754, 0.546274006366729736328125 * ((_5741 * _5741) - (_7873.y * _7873.y)) });
            spvUnsafeArray<float, 9> _5686 = _7393;
            float3 _7919;
            _7919 = float3(0.0);
            for (int _7918 = 0; _7918 < 9; )
            {
                _7919 += (_1227.read(uint2((int2(496, 256) + int2(_7918, 0))), 0).xyz * _5686[_7918]);
                _7918++;
                continue;
            }
            float3 _2790 = reflect(-_2359, _7896);
            float _5867 = _2790.x;
            float _5872 = _2790.z;
            float2 _5904 = float2((precise::atan2((_192._m29.z * _5867) - (_192._m29.w * _5872), -((_192._m29.w * _5867) + (_192._m29.z * _5872))) * 0.15915493667125701904296875) + 0.5, acos(fast::clamp(_2790.y, -1.0, 1.0)) * 0.3183098733425140380859375);
            float _5836 = _7863 * 5.0;
            int _5839 = min(int(_5836), 4);
            float2 _5925 = (_5904 * float2(_1289[_5839].zw)) - float2(0.5);
            float2 _5927 = floor(_5925);
            float2 _5930 = _5925 - _5927;
            int _5933 = int(_5927.x);
            int _5936 = int(_5927.y);
            int _7922;
            if (_5933 < 0)
            {
                _7922 = _5933 + _1289[_5839].z;
            }
            else
            {
                _7922 = _5933;
            }
            int _7923;
            if (_7922 >= _1289[_5839].z)
            {
                _7923 = _7922 - _1289[_5839].z;
            }
            else
            {
                _7923 = _7922;
            }
            int _5956 = _7923 + 1;
            int _8377 = (_5956 == _1289[_5839].z) ? 0 : _5956;
            int _5971 = min((_5936 + 1), (_1289[_5839].w - 1));
            int _5973 = max(_5936, 0);
            float3 _6026 = float3(_5930.x);
            int _5846 = _5839 + 1;
            float2 _6058 = (_5904 * float2(_1289[_5846].zw)) - float2(0.5);
            float2 _6060 = floor(_6058);
            float2 _6063 = _6058 - _6060;
            int _6066 = int(_6060.x);
            int _6069 = int(_6060.y);
            int _7929;
            if (_6066 < 0)
            {
                _7929 = _6066 + _1289[_5846].z;
            }
            else
            {
                _7929 = _6066;
            }
            int _7930;
            if (_7929 >= _1289[_5846].z)
            {
                _7930 = _7929 - _1289[_5846].z;
            }
            else
            {
                _7930 = _7929;
            }
            int _6089 = _7930 + 1;
            int _8378 = (_6089 == _1289[_5846].z) ? 0 : _6089;
            int _6104 = min((_6069 + 1), (_1289[_5846].w - 1));
            int _6106 = max(_6069, 0);
            float3 _6159 = float3(_6063.x);
            float3 _5861 = mix(mix(mix(_1227.read(uint2((_1289[_5839].xy + int2(_7923, _5973))), 0).xyz, _1227.read(uint2((_1289[_5839].xy + int2(_8377, _5973))), 0).xyz, _6026), mix(_1227.read(uint2((_1289[_5839].xy + int2(_7923, _5971))), 0).xyz, _1227.read(uint2((_1289[_5839].xy + int2(_8377, _5971))), 0).xyz, _6026), float3(_5930.y)), mix(mix(_1227.read(uint2((_1289[_5846].xy + int2(_7930, _6106))), 0).xyz, _1227.read(uint2((_1289[_5846].xy + int2(_8378, _6106))), 0).xyz, _6159), mix(_1227.read(uint2((_1289[_5846].xy + int2(_7930, _6104))), 0).xyz, _1227.read(uint2((_1289[_5846].xy + int2(_8378, _6104))), 0).xyz, _6159), float3(_6063.y)), float3(_5836 - float(_5839))) * _192._m29.y;
            _7973 = fast::max(_7919, float3(0.0)) * _192._m29.y;
            _7961 = _5682.xy;
            _7937 = _5861;
        }
        else
        {
            float4 _6177 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * _7863) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);
            float _6179 = _6177.x;
            float3 _6214 = mix(_192._m9.xyz, _192._m8.xyz, float3((_7873.y * 0.5) + 0.5)) * _192._m8.w;
            _7973 = _6214;
            _7961 = (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_6179 * _6179, exp2((-9.27999973297119140625) * _7901)) * _6179) + _6177.y)) + _6177.zw;
            _7937 = mix(mix(_192._m9.xyz, _192._m8.xyz, float3((reflect(-_2359, _7896).y * 0.5) + 0.5)) * _192._m8.w, _6214, float3(_7863));
        }
        bool _2822;
        if (_2405)
        {
            _2822 = _192._m33.z > 0.5;
        }
        else
        {
            _2822 = _2405;
        }
        float3 _7982;
        if (_2822)
        {
            float3 _7958;
            do
            {
                float _6293 = ((_192._m32.x * (1.0 - smoothstep(_192._m33.x * 0.5, _192._m33.x, abs(dot(_192._m31.xyz, in.m_1741) - _192._m31.w)))) * smoothstep(0.5, 0.89999997615814208984375, dot(_2370, _192._m31.xyz))) * (1.0 - smoothstep(_192._m32.y * 0.5, _192._m32.y, _7863));
                if (_6293 <= 0.0)
                {
                    _7958 = _7937;
                    break;
                }
                float4 _6318 = _192._m30 * float4(in.m_1741 + ((_7873 - (_192._m31.xyz * dot(_7873, _192._m31.xyz))) * _192._m32.w), 1.0);
                float2 _6331 = ((float2(_6318.x, -_6318.y) / float2(_6318.w)) * 0.5) + float2(0.5);
                float _6335 = _192._m32.z * _7863;
                float3 _7956;
                float _7957;
                _7957 = 0.0;
                _7956 = float3(0.0);
                for (int _7955 = 0; _7955 < 12; )
                {
                    float _6342 = float(_7955);
                    float _6350 = _6342 * 2.3999631404876708984375;
                    float2 _6362 = _6331 + (float2(cos(_6350) * _192._m33.y, sin(_6350)) * (sqrt((_6342 + 0.5) * 0.083333335816860198974609375) * _6335));
                    float2 _6367 = fast::min(_6362, float2(1.0) - _6362);
                    float _6373 = smoothstep(0.0, 0.039999999105930328369140625, fast::min(_6367.x, _6367.y));
                    float4 _6381 = _2057.sample(_1229, fast::clamp(_6362, float2(0.0), float2(1.0)), level(0.0));
                    float3 _6383 = _6381.xyz;
                    _7957 += (_6381.w * _6373);
                    _7956 += ((_6383 / (float3(1.0) - fast::min(_6383, float3(0.99500000476837158203125)))) * _6373);
                    _7955++;
                    continue;
                }
                _7958 = mix(_7937, (_7956 * float3(0.083333335816860198974609375)) + (_7937 * (1.0 - (_7957 * 0.083333335816860198974609375))), float3(_6293));
                break;
            } while(false);
            _7982 = _7958;
        }
        else
        {
            _7982 = _7937;
        }
        float3 _2842 = (_2634 * _7961.x) + float3(_7961.y);
        float3 _2858 = _8011 + (((((float3(1.0) - _2842) * _2628) * _7973) + (_2842 * _7982)) * _7997);
        float3 _8158;
        if (_192._m13.w > 0.5)
        {
            float2 _6447 = fast::clamp(floor(gl_FragCoord.xy * _192._m12.xy), float2(0.0), _192._m13.xy - float2(1.0));
            uint _6475 = uint((((fast::clamp(floor((log2(fast::max(dot(_192._m11.xyz, in.m_1741) + _192._m11.w, 9.9999999747524270787835121154785e-07)) * _192._m12.z) + _192._m12.w), 0.0, _192._m13.z - 1.0) * _192._m13.y) + _6447.y) * _192._m13.x) + _6447.x);
            uint _6477 = _6475 >> uint(2);
            uint _6479 = _6475 & 3u;
            uint _6483 = _1872._m0[_6477][_6479] & 65535u;
            uint _6485 = _1872._m0[_6477][_6479] >> uint(16);
            float3 _8111;
            _8111 = _2858;
            float3 _2958;
            spvUnsafeArray<float2, 3> _6893;
            spvUnsafeArray<float2, 3> _6894;
            spvUnsafeArray<float2, 3> _7106;
            spvUnsafeArray<float2, 3> _7107;
            for (uint _8014 = _6483; _8014 < (_6483 + _6485); _8111 = _2958, _8014++)
            {
                uint _6491 = _8014 / 3u;
                uint _6504 = (_1893._m0[_6491 >> uint(2)][_6491 & 3u] >> ((_8014 - (_6491 * 3u)) * 10u)) & 1023u;
                float3 _6521 = _1734._m0[_6504].xyz - in.m_1741;
                float _6524 = dot(_6521, _6521);
                float _6528 = _6524 * _1734._m0[_6504].w;
                float _6533 = fast::clamp(1.0 - (_6528 * _6528), 0.0, 1.0);
                float3 _6538 = _6521 * rsqrt(fast::max(_6524, 9.9999999392252902907785028219223e-09));
                float _6556 = fast::clamp((dot(-_6538, _1777._m0[_6504].xyz) * _1769._m0[_6504].w) + _1777._m0[_6504].w, 0.0, 1.0);
                float3 _6569 = _1769._m0[_6504].xyz * ((((_6533 * _6533) * _6556) * _6556) / fast::max(_6524, 9.9999997473787516355514526367188e-05));
                float3 _8109;
                if (_2375)
                {
                    float _8041;
                    do
                    {
                        uint _6605 = uint(_192._m21.z);
                        if (_6504 < _6605)
                        {
                            float _6627 = _192._m26[_6504].z * fast::max((_192._m15[_6504] * float4(in.m_1741, 1.0)).w, 0.0);
                            float4 _6651 = _192._m15[_6504] * float4((in.m_1741 + (_2370 * (_6627 * _192._m25.x))) + (_6538 * (_6627 * _192._m25.y)), 1.0);
                            float _6653 = _6651.w;
                            if (_6653 <= 0.0)
                            {
                                _8041 = 1.0;
                                break;
                            }
                            float3 _6662 = _6651.xyz / float3(_6653);
                            float _6664 = _6662.x;
                            bool _6665 = _6664 < 0.0;
                            bool _6672;
                            if (!_6665)
                            {
                                _6672 = _6664 > 1.0;
                            }
                            else
                            {
                                _6672 = _6665;
                            }
                            bool _6679;
                            if (!_6672)
                            {
                                _6679 = _6662.y < 0.0;
                            }
                            else
                            {
                                _6679 = _6672;
                            }
                            bool _6686;
                            if (!_6679)
                            {
                                _6686 = _6662.y > 1.0;
                            }
                            else
                            {
                                _6686 = _6679;
                            }
                            bool _6693;
                            if (!_6686)
                            {
                                _6693 = _6662.z > 1.0;
                            }
                            else
                            {
                                _6693 = _6686;
                            }
                            if (_6693)
                            {
                                _8041 = 1.0;
                                break;
                            }
                            float _6699 = _6662.z;
                            float2 _6865 = _192._m22.xy * 0.5;
                            float2 _6870 = _192._m26[_6504].xy + (_6662.xy * _192._m23.zw);
                            float4 _6883 = float4(_192._m26[_6504].xy + _6865, (_192._m26[_6504].xy + _192._m23.zw) - _6865);
                            float _8040;
                            do
                            {
                                int _6909 = int(_192._m22.z);
                                if (_6909 <= 0)
                                {
                                    float2 _6919 = fast::clamp(_6870, _6883.xy, _6883.zw);
                                    _8040 = spvDepthCast(_212).sample_compare(_212Smplr, float3(_6919, _6699).xy, _6699);
                                    break;
                                }
                                float2 _6932 = (_6870 / _192._m22.xy) + float2(0.5);
                                float2 _6933 = floor(_6932);
                                float2 _6938 = _6932 - _6933;
                                float2 _6941 = _6933 - float2(0.5);
                                bool _6945 = _6909 == 1;
                                if (_6945)
                                {
                                    float2 _6948 = _6938 * 2.0;
                                    _6893[0] = float2(3.0) - _6948;
                                    _6893[1] = float2(1.0) + _6948;
                                    _6894[0] = ((float2(2.0) - _6938) / _6893[0]) - float2(1.0);
                                    _6894[1] = (_6938 / _6893[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _6975 = _6938 * 3.0;
                                    _6893[0] = float2(4.0) - _6975;
                                    _6893[1] = float2(7.0);
                                    _6893[2] = float2(1.0) + _6975;
                                    _6894[0] = ((float2(3.0) - (_6938 * 2.0)) / _6893[0]) - float2(2.0);
                                    _6894[1] = (float2(3.0) + _6938) / _6893[1];
                                    _6894[2] = (_6938 / _6893[2]) + float2(2.0);
                                }
                                int _8380 = _6945 ? 2 : 3;
                                int _8030;
                                float _8033;
                                _8033 = 0.0;
                                _8030 = 0;
                                float _8039;
                                for (; _8030 < _8380; _8033 = _8039, _8030++)
                                {
                                    _8039 = _8033;
                                    for (int _8036 = 0; _8036 < _8380; )
                                    {
                                        _8039 += ((_6893[_8036].x * _6893[_8030].y) * spvDepthCast(_212).sample_compare(_212Smplr, float3(fast::clamp(_192._m22.xy * (_6941 + float2(_6894[_8036].x, _6894[_8030].y)), _6883.xy, _6883.zw), _6699).xy, _6699));
                                        _8036++;
                                        continue;
                                    }
                                }
                                _8040 = _8033 * (_6945 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _8041 = _8040;
                            break;
                        }
                        uint _6709 = _6504 - _6605;
                        if (_6709 >= uint(_192._m21.w))
                        {
                            _8041 = 1.0;
                            break;
                        }
                        float _6730 = _192._m27[_6709].w * length(in.m_1741 - _192._m27[_6709].xyz);
                        float3 _6748 = ((in.m_1741 + (_2370 * (_6730 * _192._m25.x))) + (_6538 * (_6730 * _192._m25.y))) - _192._m27[_6709].xyz;
                        float3 _6750 = abs(_6748);
                        float _6752 = _6750.x;
                        float _6754 = _6750.y;
                        bool _6755 = _6752 >= _6754;
                        bool _6763;
                        if (_6755)
                        {
                            _6763 = _6752 >= _6750.z;
                        }
                        else
                        {
                            _6763 = _6755;
                        }
                        float _8015;
                        int _8017;
                        if (_6763)
                        {
                            _8017 = (_6748.x > 0.0) ? 0 : 1;
                            _8015 = _6752;
                        }
                        else
                        {
                            float _6775 = _6750.z;
                            bool _6776 = _6754 >= _6775;
                            int _8018;
                            if (_6776)
                            {
                                _8018 = (_6748.y > 0.0) ? 2 : 3;
                            }
                            else
                            {
                                _8018 = (_6748.z > 0.0) ? 4 : 5;
                            }
                            _8017 = _8018;
                            _8015 = _6776 ? _6754 : _6775;
                        }
                        if (_8015 <= 0.0)
                        {
                            _8041 = 1.0;
                            break;
                        }
                        float2 _6813 = float2(dot(_6748, _870[_8017]), dot(_6748, _879[_8017])) / float2(_8015 * _192._m24.z);
                        float _6820 = _192._m28[_6709].z + (_192._m28[_6709].w / _8015);
                        if (_6820 > 1.0)
                        {
                            _8041 = 1.0;
                            break;
                        }
                        float2 _6838 = _192._m28[_6709].xy + (float2(float(spvSMod(_8017, 3)), float(_8017 / 3)) * _192._m24.xy);
                        float2 _7078 = _192._m22.xy * 0.5;
                        float2 _7083 = _6838 + (float2(0.5 + (0.5 * _6813.x), 0.5 - (0.5 * _6813.y)) * _192._m24.xy);
                        float4 _7096 = float4(_6838 + _7078, (_6838 + _192._m24.xy) - _7078);
                        float _8029;
                        do
                        {
                            int _7122 = int(_192._m22.z);
                            if (_7122 <= 0)
                            {
                                _8029 = spvDepthCast(_212).sample_compare(_212Smplr, float3(fast::clamp(_7083, _7096.xy, _7096.zw), _6820).xy, _6820);
                                break;
                            }
                            float2 _7145 = (_7083 / _192._m22.xy) + float2(0.5);
                            float2 _7146 = floor(_7145);
                            float2 _7151 = _7145 - _7146;
                            float2 _7154 = _7146 - float2(0.5);
                            bool _7158 = _7122 == 1;
                            if (_7158)
                            {
                                float2 _7161 = _7151 * 2.0;
                                _7106[0] = float2(3.0) - _7161;
                                _7106[1] = float2(1.0) + _7161;
                                _7107[0] = ((float2(2.0) - _7151) / _7106[0]) - float2(1.0);
                                _7107[1] = (_7151 / _7106[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _7188 = _7151 * 3.0;
                                _7106[0] = float2(4.0) - _7188;
                                _7106[1] = float2(7.0);
                                _7106[2] = float2(1.0) + _7188;
                                _7107[0] = ((float2(3.0) - (_7151 * 2.0)) / _7106[0]) - float2(2.0);
                                _7107[1] = (float2(3.0) + _7151) / _7106[1];
                                _7107[2] = (_7151 / _7106[2]) + float2(2.0);
                            }
                            int _8383 = _7158 ? 2 : 3;
                            int _8019;
                            float _8022;
                            _8022 = 0.0;
                            _8019 = 0;
                            float _8028;
                            for (; _8019 < _8383; _8022 = _8028, _8019++)
                            {
                                _8028 = _8022;
                                for (int _8025 = 0; _8025 < _8383; )
                                {
                                    _8028 += ((_7106[_8025].x * _7106[_8019].y) * spvDepthCast(_212).sample_compare(_212Smplr, float3(fast::clamp(_192._m22.xy * (_7154 + float2(_7107[_8025].x, _7107[_8019].y)), _7096.xy, _7096.zw), _6820).xy, _6820));
                                    _8025++;
                                    continue;
                                }
                            }
                            _8029 = _8022 * (_7158 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _8041 = _8029;
                        break;
                    } while(false);
                    _8109 = _6569 * _8041;
                }
                else
                {
                    _8109 = _6569;
                }
                float3 _2910 = fast::normalize(_6538 + _2359);
                float _2915 = fast::clamp(dot(_7873, _6538), 0.0, 1.0);
                float _2920 = fast::clamp(dot(_7873, _2910), 0.0, 1.0);
                float3 _7293 = _2634 + (_5608 * powr(1.0 - fast::clamp(dot(_2359, _2910), 0.0, 1.0), 5.0));
                float _7307 = ((_2920 * _2920) * _5623) + 1.0;
                _2958 = _8111 + (((((float3(1.0) - _7293) * _2628) + ((_7293 * ((_5618 / ((3.1415927410125732421875 * _7307) * _7307)) * (0.5 / fast::max((_2915 * _5649) + (_7901 * sqrt(((_2915 * _2915) * _5645) + _5618)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875)) * _2915) * _8109);
            }
            _8158 = _8111;
        }
        else
        {
            _8158 = _2858;
        }
        _8155 = _8158;
    }
    float4 _2975 = _2970.sample(_1229, _2124);
    float _2996 = -length(_2358);
    float _8200;
    if (_192._m9.w != 0.0)
    {
        float _3020 = _192._m9.w * (in.m_1741 - _192._m6.xyz).y;
        float _8197;
        if (abs(_3020) < 9.9999997473787516355514526367188e-05)
        {
            _8197 = 1.0 - (0.5 * _3020);
        }
        else
        {
            _8197 = (1.0 - exp(fast::min(-_3020, 60.0))) / _3020;
        }
        _8200 = 1.0 - exp((_2996 * (_192._m7.w * exp(fast::min((-_192._m9.w) * (_192._m6.y - _192._m6.w), 30.0)))) * _8197);
    }
    else
    {
        _8200 = 1.0 - exp(_2996 * _192._m7.w);
    }
    float3 _3071 = mix(mix(_8155, _7867, float3(_1579._m1.y)) + (((_1579._m5.xyz * _2975.xyz) * (float3(1.0) + in.m_2372.yzw)) * in.m_2589.z), _192._m7.xyz, float3(_8200));
    float3 _8201;
    if (_192._m33.w > 0.5)
    {
        _8201 = _3071 / (float3(1.0) + _3071);
    }
    else
    {
        _8201 = _3071;
    }
    out.m_3083 = float4(_8201, ((in.m_2133.w * _1579._m0.w) * _2131.w) * in.m_2153.w);
    float2 _8202;
    do
    {
        if (in.m_3093.w <= 0.0)
        {
            _8202 = float2(0.0);
            break;
        }
        _8202 = ((in.m_3093.xy / float2(in.m_3093.w)) - (in.m_3092.xy / float2(in.m_3092.w))) * float2(0.5, -0.5);
        break;
    } while(false);
    out.m_3091 = _8202;
    return out;
}

