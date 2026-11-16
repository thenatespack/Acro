// Generated from mesh_mask.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 657ce5b26bc4eff0
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
    float4 m_3077 [[color(0)]];
    float2 m_3085 [[color(1)]];
};

struct fragment_main_in
{
    float3 m_1741 [[user(locn0)]];
    float3 m_1649 [[user(locn1)]];
    float2 m_2110 [[user(locn2)]];
    float4 m_2133 [[user(locn3)]];
    float3 m_1684 [[user(locn4)]];
    float4 m_2376 [[user(locn5)]];
    float4 m_3086 [[user(locn6)]];
    float4 m_3087 [[user(locn7)]];
    float4 m_1655 [[user(locn8)]];
};

fragment fragment_main_out fragment_main(fragment_main_in in [[stage_in]], constant _1577& _1579 [[buffer(2)]], constant _1732& _1734 [[buffer(3)]], constant _1767& _1769 [[buffer(4)]], constant _1775& _1777 [[buffer(5)]], constant _1870& _1872 [[buffer(6)]], constant _1891& _1893 [[buffer(7)]], constant _190& _192 [[buffer(15)]], texture2d<float> _212 [[texture(0)]], texture2d<float> _2126 [[texture(1)]], texture2d<float> _2581 [[texture(2)]], texture2d<float> _2253 [[texture(3)]], texture2d<float> _2057 [[texture(4)]], texture2d<float> _2967 [[texture(5)]], texture2d<float> _1227 [[texture(6)]], texture2d<float> _1333 [[texture(7)]], sampler _212Smplr [[sampler(0)]], sampler _1229 [[sampler(1)]], sampler _1335 [[sampler(7)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])
{
    fragment_main_out out = {};
    float2 _2124 = float2(dot(_1579._m2.xy, in.m_2110) + _1579._m2.z, dot(_1579._m3.xy, in.m_2110) + _1579._m3.z);
    float4 _2131 = _2126.sample(_1229, _2124);
    float3 _2141 = _2131.xyz;
    float3 _2142 = (in.m_2133.xyz * _1579._m0.xyz) * _2141;
    if ((_1579._m0.w * _2131.w) < _1579._m6.x)
    {
        discard_fragment();
    }
    float3 _7671;
    if (_1579._m1.x > 0.5)
    {
        float2 _2176 = floor(in.m_1741.xz * float2(0.5));
        _7671 = _2142 * ((mod(abs(_2176.x + _2176.y), 2.0) < 0.5) ? 1.0 : 0.75);
    }
    else
    {
        _7671 = _2142;
    }
    float3 _7768;
    float _7799;
    float2 _7832;
    if (_1579._m3.w > 0.5)
    {
        float3 _3188;
        float2 _3195;
        float _7669;
        do
        {
            float3 _3159 = float4(_1579._m2.w, _1579._m3.w, 0.0, 0.0).xyy;
            float3 _3162 = floor(_3159 * float3(1.52587890625e-05));
            float3 _3167 = _3159 - (_3162 * 65536.0);
            float3 _3170 = floor(_3167 * float3(0.00390625));
            float3 _3178 = _3167 - (_3170 * 256.0);
            _3188 = (float3(_3178.x, _3170.x, _3162.x) * float3(0.0039215688593685626983642578125)) * 2.0;
            _3195 = float2(_3178.y, _3170.y) * float2(0.0039215688593685626983642578125);
            float _3198 = _3162.y - 128.0;
            float _3204 = floor(_3198 * 0.03125) * 0.3333333432674407958984375;
            float3 _3210 = fast::normalize(in.m_1649);
            float _3214 = dot(_3210, in.m_1655.xyz);
            float _3226 = (_3214 / fast::max(length(in.m_1655.xyz - (_3210 * _3214)), 9.9999999747524270787835121154785e-07)) * 25.5;
            if (((-24.0) + _3226) < (-2.0))
            {
                _7669 = 0.0;
                break;
            }
            float3 _3234 = in.m_1684 * (4.0 * exp2(mod(_3198, 32.0) * 0.3333333432674407958984375));
            float3 _3278 = floor(_3234);
            float3 _3281 = _3234 - _3278;
            float3 _3289 = (_3281 * _3281) * (float3(3.0) - (_3281 * 2.0));
            uint3 _3356 = uint3(int3(_3278));
            uint _3369 = (((_3356.x * 1597334677u) ^ (_3356.y * 3812015801u)) ^ (_3356.z * 2798796415u)) * 1597334677u;
            uint3 _3384 = uint3(int3(_3278 + float3(1.0, 0.0, 0.0)));
            uint _3397 = (((_3384.x * 1597334677u) ^ (_3384.y * 3812015801u)) ^ (_3384.z * 2798796415u)) * 1597334677u;
            float _3298 = _3289.x;
            uint3 _3412 = uint3(int3(_3278 + float3(0.0, 1.0, 0.0)));
            uint _3425 = (((_3412.x * 1597334677u) ^ (_3412.y * 3812015801u)) ^ (_3412.z * 2798796415u)) * 1597334677u;
            uint3 _3440 = uint3(int3(_3278 + float3(1.0, 1.0, 0.0)));
            uint _3453 = (((_3440.x * 1597334677u) ^ (_3440.y * 3812015801u)) ^ (_3440.z * 2798796415u)) * 1597334677u;
            float _3314 = _3289.y;
            uint3 _3468 = uint3(int3(_3278 + float3(0.0, 0.0, 1.0)));
            uint _3481 = (((_3468.x * 1597334677u) ^ (_3468.y * 3812015801u)) ^ (_3468.z * 2798796415u)) * 1597334677u;
            uint3 _3496 = uint3(int3(_3278 + float3(1.0, 0.0, 1.0)));
            uint _3509 = (((_3496.x * 1597334677u) ^ (_3496.y * 3812015801u)) ^ (_3496.z * 2798796415u)) * 1597334677u;
            uint3 _3524 = uint3(int3(_3278 + float3(0.0, 1.0, 1.0)));
            uint _3537 = (((_3524.x * 1597334677u) ^ (_3524.y * 3812015801u)) ^ (_3524.z * 2798796415u)) * 1597334677u;
            uint3 _3552 = uint3(int3(_3278 + float3(1.0)));
            uint _3565 = (((_3552.x * 1597334677u) ^ (_3552.y * 3812015801u)) ^ (_3552.z * 2798796415u)) * 1597334677u;
            float3 _3240 = (_3234 * 2.7000000476837158203125) + float3(17.299999237060546875, 5.099999904632568359375, 9.69999980926513671875);
            float3 _3591 = floor(_3240);
            float3 _3594 = _3240 - _3591;
            float3 _3602 = (_3594 * _3594) * (float3(3.0) - (_3594 * 2.0));
            uint3 _3669 = uint3(int3(_3591));
            uint _3682 = (((_3669.x * 1597334677u) ^ (_3669.y * 3812015801u)) ^ (_3669.z * 2798796415u)) * 1597334677u;
            uint3 _3697 = uint3(int3(_3591 + float3(1.0, 0.0, 0.0)));
            uint _3710 = (((_3697.x * 1597334677u) ^ (_3697.y * 3812015801u)) ^ (_3697.z * 2798796415u)) * 1597334677u;
            float _3611 = _3602.x;
            uint3 _3725 = uint3(int3(_3591 + float3(0.0, 1.0, 0.0)));
            uint _3738 = (((_3725.x * 1597334677u) ^ (_3725.y * 3812015801u)) ^ (_3725.z * 2798796415u)) * 1597334677u;
            uint3 _3753 = uint3(int3(_3591 + float3(1.0, 1.0, 0.0)));
            uint _3766 = (((_3753.x * 1597334677u) ^ (_3753.y * 3812015801u)) ^ (_3753.z * 2798796415u)) * 1597334677u;
            float _3627 = _3602.y;
            uint3 _3781 = uint3(int3(_3591 + float3(0.0, 0.0, 1.0)));
            uint _3794 = (((_3781.x * 1597334677u) ^ (_3781.y * 3812015801u)) ^ (_3781.z * 2798796415u)) * 1597334677u;
            uint3 _3809 = uint3(int3(_3591 + float3(1.0, 0.0, 1.0)));
            uint _3822 = (((_3809.x * 1597334677u) ^ (_3809.y * 3812015801u)) ^ (_3809.z * 2798796415u)) * 1597334677u;
            uint3 _3837 = uint3(int3(_3591 + float3(0.0, 1.0, 1.0)));
            uint _3850 = (((_3837.x * 1597334677u) ^ (_3837.y * 3812015801u)) ^ (_3837.z * 2798796415u)) * 1597334677u;
            uint3 _3865 = uint3(int3(_3591 + float3(1.0)));
            uint _3878 = (((_3865.x * 1597334677u) ^ (_3865.y * 3812015801u)) ^ (_3865.z * 2798796415u)) * 1597334677u;
            float _3245 = mix(0.449999988079071044921875, 0.0500000007450580596923828125, _3204);
            float _3249 = ((mix(mix(mix(float((_3369 ^ (_3369 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_3397 ^ (_3397 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _3298), mix(float((_3425 ^ (_3425 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_3453 ^ (_3453 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _3298), _3314), mix(mix(float((_3481 ^ (_3481 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_3509 ^ (_3509 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _3298), mix(float((_3537 ^ (_3537 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_3565 ^ (_3565 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _3298), _3314), _3289.z) * 0.64999997615814208984375) + (mix(mix(mix(float((_3682 ^ (_3682 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_3710 ^ (_3710 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _3611), mix(float((_3738 ^ (_3738 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_3766 ^ (_3766 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _3611), _3627), mix(mix(float((_3794 ^ (_3794 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_3822 ^ (_3822 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _3611), mix(float((_3850 ^ (_3850 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_3878 ^ (_3878 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _3611), _3627), _3602.z) * 0.3499999940395355224609375)) - 0.5;
            _7669 = smoothstep(-_3245, _3245, (_3226 + (-24.450000762939453125)) + (_3249 * mix(0.800000011920928955078125, 2.2000000476837158203125, _3204)));
            break;
        } while(false);
        _7832 = _3195;
        _7799 = _7669;
        _7768 = mix(_7671, (in.m_2133.xyz * _3188) * mix(float3(1.0), _2141 * 2.0, float3(0.5)), float3(_7669));
    }
    else
    {
        _7832 = float2(0.0);
        _7799 = 0.0;
        _7768 = _7671;
    }
    float3 _2218 = fast::normalize(in.m_1649);
    float3 _7681;
    if (_1579._m6.y > 0.5)
    {
        float3 _2233 = in.m_1655.xyz - (_2218 * dot(_2218, in.m_1655.xyz));
        float3 _7682;
        if (dot(_2233, _2233) > 9.9999999600419720025001879548654e-13)
        {
            float3 _2242 = fast::normalize(_2233);
            float4 _2258 = _2253.sample(_1229, _2124);
            float3 _7673;
            if (_1579._m6.z > 0.5)
            {
                float2 _7672;
                if (_1579._m6.z > 1.5)
                {
                    _7672 = _2258.xw;
                }
                else
                {
                    _7672 = _2258.xy;
                }
                float2 _2280 = (_7672 * 2.0) - float2(1.0);
                _7673 = float3(_2280, sqrt(fast::clamp(1.0 - dot(_2280, _2280), 0.0, 1.0)));
            }
            else
            {
                _7673 = (_2258.xyz * 2.0) - float3(1.0);
            }
            float2 _2302 = _7673.xy * _1579._m4.z;
            _7682 = fast::normalize(((_2242 * _2302.x) + ((cross(_2218, _2242) * ((in.m_1655.w < 0.0) ? (-1.0) : 1.0)) * _2302.y)) + (_2218 * _7673.z));
        }
        else
        {
            _7682 = _2218;
        }
        _7681 = _7682;
    }
    else
    {
        _7681 = _2218;
    }
    bool _2326 = _1579._m5.w > 0.5;
    float _7678;
    if (_2326)
    {
        _7678 = fast::clamp(_1579._m1.z, 0.0, 1.0);
    }
    else
    {
        _7678 = 0.0;
    }
    bool _2344;
    if (_2326)
    {
        _2344 = !gl_FrontFacing;
    }
    else
    {
        _2344 = _2326;
    }
    float3 _7868;
    if (_2344 && (_7678 <= 0.0))
    {
        _7868 = -_7681;
    }
    else
    {
        _7868 = _7681;
    }
    float3 _2356 = fast::normalize(_192._m4.xyz);
    float3 _2362 = _192._m6.xyz - in.m_1741;
    float3 _2363 = fast::normalize(_2362);
    float3 _2368 = fast::normalize(_2356 + _2363);
    float3 _2374 = _2218 * (gl_FrontFacing ? 1.0 : (-1.0));
    bool _2379 = in.m_2376.x > 0.5;
    float3 _7862;
    float _7902;
    if ((_192._m5.w > 0.5) && _2379)
    {
        float _7738;
        float3 _7739;
        do
        {
            int _3907 = int(_192._m21.x);
            float _3915 = dot(_192._m20.xyz, in.m_1741) + _192._m20.w;
            int _7683;
            _7683 = 0;
            for (;;)
            {
                bool _3921 = _7683 < (_3907 - 1);
                bool _3929;
                if (_3921)
                {
                    _3929 = _3915 > _192._m16[_7683];
                }
                else
                {
                    _3929 = _3921;
                }
                if (_3929)
                {
                    _7683++;
                    continue;
                }
                else
                {
                    break;
                }
            }
            if (_3915 > _192._m16[_7683])
            {
                _7739 = float3(1.0);
                _7738 = 1.0;
                break;
            }
            float _7696;
            do
            {
                float4 _4031 = _192._m14[_7683] * float4(in.m_1741 + (_2374 * _192._m18[_7683]), 1.0);
                float _4034 = _4031.x;
                bool _4035 = _4034 < 0.0;
                bool _4042;
                if (!_4035)
                {
                    _4042 = _4034 > 1.0;
                }
                else
                {
                    _4042 = _4035;
                }
                bool _4049;
                if (!_4042)
                {
                    _4049 = _4031.y < 0.0;
                }
                else
                {
                    _4049 = _4042;
                }
                bool _4056;
                if (!_4049)
                {
                    _4056 = _4031.y > 1.0;
                }
                else
                {
                    _4056 = _4049;
                }
                if (_4056)
                {
                    _7696 = 1.0;
                    break;
                }
                float2 _4069 = float2(float(_7683 & 1), float(_7683 >> 1)) * _192._m23.xy;
                float _4076 = fast::min(_4031.z, 1.0) - _192._m19[_7683];
                float2 _4095 = _192._m22.xy * 0.5;
                float2 _4100 = _4069 + (_4031.xy * _192._m23.xy);
                float4 _4113 = float4(_4069 + _4095, (_4069 + _192._m23.xy) - _4095);
                float _7695;
                do
                {
                    int _4139 = int(_192._m22.z);
                    if (_4139 <= 0)
                    {
                        _7695 = spvDepthCast(_212).sample_compare(_212Smplr, float3(fast::clamp(_4100, _4113.xy, _4113.zw), _4076).xy, _4076);
                        break;
                    }
                    float2 _4162 = (_4100 / _192._m22.xy) + float2(0.5);
                    float2 _4163 = floor(_4162);
                    float2 _4168 = _4162 - _4163;
                    float2 _4171 = _4163 - float2(0.5);
                    bool _4175 = _4139 == 1;
                    spvUnsafeArray<float2, 3> _4123;
                    spvUnsafeArray<float2, 3> _4124;
                    if (_4175)
                    {
                        float2 _4178 = _4168 * 2.0;
                        _4123[0] = float2(3.0) - _4178;
                        _4123[1] = float2(1.0) + _4178;
                        _4124[0] = ((float2(2.0) - _4168) / _4123[0]) - float2(1.0);
                        _4124[1] = (_4168 / _4123[1]) + float2(1.0);
                    }
                    else
                    {
                        float2 _4205 = _4168 * 3.0;
                        _4123[0] = float2(4.0) - _4205;
                        _4123[1] = float2(7.0);
                        _4123[2] = float2(1.0) + _4205;
                        _4124[0] = ((float2(3.0) - (_4168 * 2.0)) / _4123[0]) - float2(2.0);
                        _4124[1] = (float2(3.0) + _4168) / _4123[1];
                        _4124[2] = (_4168 / _4123[2]) + float2(2.0);
                    }
                    int _8457 = _4175 ? 2 : 3;
                    int _7685;
                    float _7688;
                    _7688 = 0.0;
                    _7685 = 0;
                    float _7694;
                    for (; _7685 < _8457; _7688 = _7694, _7685++)
                    {
                        _7694 = _7688;
                        for (int _7691 = 0; _7691 < _8457; )
                        {
                            _7694 += ((_4123[_7691].x * _4123[_7685].y) * spvDepthCast(_212).sample_compare(_212Smplr, float3(fast::clamp(_192._m22.xy * (_4171 + float2(_4124[_7691].x, _4124[_7685].y)), _4113.xy, _4113.zw), _4076).xy, _4076));
                            _7691++;
                            continue;
                        }
                    }
                    _7695 = _7688 * (_4175 ? 0.0625 : 0.0069444444961845874786376953125);
                    break;
                } while(false);
                _7696 = _7695;
                break;
            } while(false);
            float3 _7733;
            float _7736;
            if (_3915 > _192._m17[_7683])
            {
                float _3969 = (_3915 - _192._m17[_7683]) / (_192._m16[_7683] - _192._m17[_7683]);
                int _3971 = _7683 + 1;
                float3 _7734;
                float _7737;
                if (_3971 < _3907)
                {
                    float _7716;
                    do
                    {
                        float4 _4318 = _192._m14[_3971] * float4(in.m_1741 + (_2374 * _192._m18[_3971]), 1.0);
                        float _4321 = _4318.x;
                        bool _4322 = _4321 < 0.0;
                        bool _4329;
                        if (!_4322)
                        {
                            _4329 = _4321 > 1.0;
                        }
                        else
                        {
                            _4329 = _4322;
                        }
                        bool _4336;
                        if (!_4329)
                        {
                            _4336 = _4318.y < 0.0;
                        }
                        else
                        {
                            _4336 = _4329;
                        }
                        bool _4343;
                        if (!_4336)
                        {
                            _4343 = _4318.y > 1.0;
                        }
                        else
                        {
                            _4343 = _4336;
                        }
                        if (_4343)
                        {
                            _7716 = 1.0;
                            break;
                        }
                        float2 _4356 = float2(float(_3971 & 1), float(_3971 >> 1)) * _192._m23.xy;
                        float _4363 = fast::min(_4318.z, 1.0) - _192._m19[_3971];
                        float2 _4382 = _192._m22.xy * 0.5;
                        float2 _4387 = _4356 + (_4318.xy * _192._m23.xy);
                        float4 _4400 = float4(_4356 + _4382, (_4356 + _192._m23.xy) - _4382);
                        float _7715;
                        do
                        {
                            int _4426 = int(_192._m22.z);
                            if (_4426 <= 0)
                            {
                                _7715 = spvDepthCast(_212).sample_compare(_212Smplr, float3(fast::clamp(_4387, _4400.xy, _4400.zw), _4363).xy, _4363);
                                break;
                            }
                            float2 _4449 = (_4387 / _192._m22.xy) + float2(0.5);
                            float2 _4450 = floor(_4449);
                            float2 _4455 = _4449 - _4450;
                            float2 _4458 = _4450 - float2(0.5);
                            bool _4462 = _4426 == 1;
                            spvUnsafeArray<float2, 3> _4410;
                            spvUnsafeArray<float2, 3> _4411;
                            if (_4462)
                            {
                                float2 _4465 = _4455 * 2.0;
                                _4410[0] = float2(3.0) - _4465;
                                _4410[1] = float2(1.0) + _4465;
                                _4411[0] = ((float2(2.0) - _4455) / _4410[0]) - float2(1.0);
                                _4411[1] = (_4455 / _4410[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _4492 = _4455 * 3.0;
                                _4410[0] = float2(4.0) - _4492;
                                _4410[1] = float2(7.0);
                                _4410[2] = float2(1.0) + _4492;
                                _4411[0] = ((float2(3.0) - (_4455 * 2.0)) / _4410[0]) - float2(2.0);
                                _4411[1] = (float2(3.0) + _4455) / _4410[1];
                                _4411[2] = (_4455 / _4410[2]) + float2(2.0);
                            }
                            int _8459 = _4462 ? 2 : 3;
                            int _7705;
                            float _7708;
                            _7708 = 0.0;
                            _7705 = 0;
                            float _7714;
                            for (; _7705 < _8459; _7708 = _7714, _7705++)
                            {
                                _7714 = _7708;
                                for (int _7711 = 0; _7711 < _8459; )
                                {
                                    _7714 += ((_4410[_7711].x * _4410[_7705].y) * spvDepthCast(_212).sample_compare(_212Smplr, float3(fast::clamp(_192._m22.xy * (_4458 + float2(_4411[_7711].x, _4411[_7705].y)), _4400.xy, _4400.zw), _4363).xy, _4363));
                                    _7711++;
                                    continue;
                                }
                            }
                            _7715 = _7708 * (_4462 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _7716 = _7715;
                        break;
                    } while(false);
                    _7737 = mix(_7696, _7716, _3969);
                    _7734 = mix(_566[_7683], _566[_3971], float3(_3969));
                }
                else
                {
                    _7737 = mix(_7696, 1.0, _3969);
                    _7734 = _566[_7683];
                }
                _7736 = _7737;
                _7733 = _7734;
            }
            else
            {
                _7736 = _7696;
                _7733 = _566[_7683];
            }
            _7739 = select(float3(1.0), _7733, bool3(_192._m22.w > 0.5));
            _7738 = _7736;
            break;
        } while(false);
        _7902 = _7738;
        _7862 = _7768 * _7739;
    }
    else
    {
        _7902 = 1.0;
        _7862 = _7768;
    }
    float3 _2405 = _192._m5.xyz * _192._m4.w;
    bool _2409 = _1579._m6.w > 0.5;
    float _7791;
    if (_2409)
    {
        _7791 = 1.0;
    }
    else
    {
        _7791 = 1.0 + (_1579._m4.w * (_2057.sample(_1229, _2124).x - 1.0));
    }
    float _2429 = abs(in.m_1655.w);
    float _7992;
    if (_2429 > 0.0)
    {
        _7992 = _7791 * fast::min(_2429, 1.0);
    }
    else
    {
        _7992 = _7791;
    }
    float3 _8150;
    if (!_2326)
    {
        float _2445 = dot(_7868, _2356);
        float3 _8142;
        if (_192._m29.x > 0.5)
        {
            float _4643 = (_192._m29.z * _7868.x) - (_192._m29.w * _7868.z);
            float _4656 = (_192._m29.w * _7868.x) + (_192._m29.z * _7868.z);
            float _4674 = 1.09254801273345947265625 * _4643;
            spvUnsafeArray<float, 9> _7406 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _7868.y, 0.48860299587249755859375 * _4656, 0.48860299587249755859375 * _4643, _4674 * _7868.y, (1.09254801273345947265625 * _7868.y) * _4656, 0.3153919875621795654296875 * (((3.0 * _4656) * _4656) - 1.0), _4674 * _4656, 0.546274006366729736328125 * ((_4643 * _4643) - (_7868.y * _7868.y)) });
            spvUnsafeArray<float, 9> _4588 = _7406;
            float3 _8141;
            _8141 = float3(0.0);
            for (int _8140 = 0; _8140 < 9; )
            {
                _8141 += (_1227.read(uint2((int2(496, 256) + int2(_8140, 0))), 0).xyz * _4588[_8140]);
                _8140++;
                continue;
            }
            _8142 = fast::max(_8141, float3(0.0)) * _192._m29.y;
        }
        else
        {
            _8142 = mix(_192._m9.xyz, _192._m8.xyz, float3((_7868.y * 0.5) + 0.5)) * _192._m8.w;
        }
        float3 _2495 = (_7862 * ((_8142 * _7992) + ((_2405 * fast::max(_2445, 0.0)) * _7902))) + ((_2405 * ((powr(fast::max(dot(_7868, _2368), 0.0), _1579._m1.w) * _1579._m1.z) * step(0.0, _2445))) * _7902);
        float3 _8151;
        if (_192._m13.w > 0.5)
        {
            float2 _4759 = fast::clamp(floor(gl_FragCoord.xy * _192._m12.xy), float2(0.0), _192._m13.xy - float2(1.0));
            uint _4787 = uint((((fast::clamp(floor((log2(fast::max(dot(_192._m11.xyz, in.m_1741) + _192._m11.w, 9.9999999747524270787835121154785e-07)) * _192._m12.z) + _192._m12.w), 0.0, _192._m13.z - 1.0) * _192._m13.y) + _4759.y) * _192._m13.x) + _4759.x);
            uint _4789 = _4787 >> uint(2);
            uint _4791 = _4787 & 3u;
            uint _4795 = _1872._m0[_4789][_4791] & 65535u;
            uint _4797 = _1872._m0[_4789][_4791] >> uint(16);
            float3 _8152;
            _8152 = _2495;
            float3 _2576;
            spvUnsafeArray<float2, 3> _5205;
            spvUnsafeArray<float2, 3> _5206;
            spvUnsafeArray<float2, 3> _5418;
            spvUnsafeArray<float2, 3> _5419;
            for (uint _8149 = _4795; _8149 < (_4795 + _4797); _8152 = _2576, _8149++)
            {
                uint _4803 = _8149 / 3u;
                uint _4816 = (_1893._m0[_4803 >> uint(2)][_4803 & 3u] >> ((_8149 - (_4803 * 3u)) * 10u)) & 1023u;
                float3 _4833 = _1734._m0[_4816].xyz - in.m_1741;
                float _4836 = dot(_4833, _4833);
                float _4840 = _4836 * _1734._m0[_4816].w;
                float _4845 = fast::clamp(1.0 - (_4840 * _4840), 0.0, 1.0);
                float3 _4850 = _4833 * rsqrt(fast::max(_4836, 9.9999999392252902907785028219223e-09));
                float _4868 = fast::clamp((dot(-_4850, _1777._m0[_4816].xyz) * _1769._m0[_4816].w) + _1777._m0[_4816].w, 0.0, 1.0);
                float3 _4881 = _1769._m0[_4816].xyz * ((((_4845 * _4845) * _4868) * _4868) / fast::max(_4836, 9.9999997473787516355514526367188e-05));
                float3 _8357;
                if (_2379)
                {
                    float _8303;
                    do
                    {
                        uint _4917 = uint(_192._m21.z);
                        if (_4816 < _4917)
                        {
                            float _4939 = _192._m26[_4816].z * fast::max((_192._m15[_4816] * float4(in.m_1741, 1.0)).w, 0.0);
                            float4 _4963 = _192._m15[_4816] * float4((in.m_1741 + (_2374 * (_4939 * _192._m25.x))) + (_4850 * (_4939 * _192._m25.y)), 1.0);
                            float _4965 = _4963.w;
                            if (_4965 <= 0.0)
                            {
                                _8303 = 1.0;
                                break;
                            }
                            float3 _4974 = _4963.xyz / float3(_4965);
                            float _4976 = _4974.x;
                            bool _4977 = _4976 < 0.0;
                            bool _4984;
                            if (!_4977)
                            {
                                _4984 = _4976 > 1.0;
                            }
                            else
                            {
                                _4984 = _4977;
                            }
                            bool _4991;
                            if (!_4984)
                            {
                                _4991 = _4974.y < 0.0;
                            }
                            else
                            {
                                _4991 = _4984;
                            }
                            bool _4998;
                            if (!_4991)
                            {
                                _4998 = _4974.y > 1.0;
                            }
                            else
                            {
                                _4998 = _4991;
                            }
                            bool _5005;
                            if (!_4998)
                            {
                                _5005 = _4974.z > 1.0;
                            }
                            else
                            {
                                _5005 = _4998;
                            }
                            if (_5005)
                            {
                                _8303 = 1.0;
                                break;
                            }
                            float _5011 = _4974.z;
                            float2 _5177 = _192._m22.xy * 0.5;
                            float2 _5182 = _192._m26[_4816].xy + (_4974.xy * _192._m23.zw);
                            float4 _5195 = float4(_192._m26[_4816].xy + _5177, (_192._m26[_4816].xy + _192._m23.zw) - _5177);
                            float _8302;
                            do
                            {
                                int _5221 = int(_192._m22.z);
                                if (_5221 <= 0)
                                {
                                    float2 _5231 = fast::clamp(_5182, _5195.xy, _5195.zw);
                                    _8302 = spvDepthCast(_212).sample_compare(_212Smplr, float3(_5231, _5011).xy, _5011);
                                    break;
                                }
                                float2 _5244 = (_5182 / _192._m22.xy) + float2(0.5);
                                float2 _5245 = floor(_5244);
                                float2 _5250 = _5244 - _5245;
                                float2 _5253 = _5245 - float2(0.5);
                                bool _5257 = _5221 == 1;
                                if (_5257)
                                {
                                    float2 _5260 = _5250 * 2.0;
                                    _5205[0] = float2(3.0) - _5260;
                                    _5205[1] = float2(1.0) + _5260;
                                    _5206[0] = ((float2(2.0) - _5250) / _5205[0]) - float2(1.0);
                                    _5206[1] = (_5250 / _5205[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _5287 = _5250 * 3.0;
                                    _5205[0] = float2(4.0) - _5287;
                                    _5205[1] = float2(7.0);
                                    _5205[2] = float2(1.0) + _5287;
                                    _5206[0] = ((float2(3.0) - (_5250 * 2.0)) / _5205[0]) - float2(2.0);
                                    _5206[1] = (float2(3.0) + _5250) / _5205[1];
                                    _5206[2] = (_5250 / _5205[2]) + float2(2.0);
                                }
                                int _8464 = _5257 ? 2 : 3;
                                int _8292;
                                float _8295;
                                _8295 = 0.0;
                                _8292 = 0;
                                float _8301;
                                for (; _8292 < _8464; _8295 = _8301, _8292++)
                                {
                                    _8301 = _8295;
                                    for (int _8298 = 0; _8298 < _8464; )
                                    {
                                        _8301 += ((_5205[_8298].x * _5205[_8292].y) * spvDepthCast(_212).sample_compare(_212Smplr, float3(fast::clamp(_192._m22.xy * (_5253 + float2(_5206[_8298].x, _5206[_8292].y)), _5195.xy, _5195.zw), _5011).xy, _5011));
                                        _8298++;
                                        continue;
                                    }
                                }
                                _8302 = _8295 * (_5257 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _8303 = _8302;
                            break;
                        }
                        uint _5021 = _4816 - _4917;
                        if (_5021 >= uint(_192._m21.w))
                        {
                            _8303 = 1.0;
                            break;
                        }
                        float _5042 = _192._m27[_5021].w * length(in.m_1741 - _192._m27[_5021].xyz);
                        float3 _5060 = ((in.m_1741 + (_2374 * (_5042 * _192._m25.x))) + (_4850 * (_5042 * _192._m25.y))) - _192._m27[_5021].xyz;
                        float3 _5062 = abs(_5060);
                        float _5064 = _5062.x;
                        float _5066 = _5062.y;
                        bool _5067 = _5064 >= _5066;
                        bool _5075;
                        if (_5067)
                        {
                            _5075 = _5064 >= _5062.z;
                        }
                        else
                        {
                            _5075 = _5067;
                        }
                        float _8277;
                        int _8279;
                        if (_5075)
                        {
                            _8279 = (_5060.x > 0.0) ? 0 : 1;
                            _8277 = _5064;
                        }
                        else
                        {
                            float _5087 = _5062.z;
                            bool _5088 = _5066 >= _5087;
                            int _8280;
                            if (_5088)
                            {
                                _8280 = (_5060.y > 0.0) ? 2 : 3;
                            }
                            else
                            {
                                _8280 = (_5060.z > 0.0) ? 4 : 5;
                            }
                            _8279 = _8280;
                            _8277 = _5088 ? _5066 : _5087;
                        }
                        if (_8277 <= 0.0)
                        {
                            _8303 = 1.0;
                            break;
                        }
                        float2 _5125 = float2(dot(_5060, _870[_8279]), dot(_5060, _879[_8279])) / float2(_8277 * _192._m24.z);
                        float _5132 = _192._m28[_5021].z + (_192._m28[_5021].w / _8277);
                        if (_5132 > 1.0)
                        {
                            _8303 = 1.0;
                            break;
                        }
                        float2 _5150 = _192._m28[_5021].xy + (float2(float(spvSMod(_8279, 3)), float(_8279 / 3)) * _192._m24.xy);
                        float2 _5390 = _192._m22.xy * 0.5;
                        float2 _5395 = _5150 + (float2(0.5 + (0.5 * _5125.x), 0.5 - (0.5 * _5125.y)) * _192._m24.xy);
                        float4 _5408 = float4(_5150 + _5390, (_5150 + _192._m24.xy) - _5390);
                        float _8291;
                        do
                        {
                            int _5434 = int(_192._m22.z);
                            if (_5434 <= 0)
                            {
                                _8291 = spvDepthCast(_212).sample_compare(_212Smplr, float3(fast::clamp(_5395, _5408.xy, _5408.zw), _5132).xy, _5132);
                                break;
                            }
                            float2 _5457 = (_5395 / _192._m22.xy) + float2(0.5);
                            float2 _5458 = floor(_5457);
                            float2 _5463 = _5457 - _5458;
                            float2 _5466 = _5458 - float2(0.5);
                            bool _5470 = _5434 == 1;
                            if (_5470)
                            {
                                float2 _5473 = _5463 * 2.0;
                                _5418[0] = float2(3.0) - _5473;
                                _5418[1] = float2(1.0) + _5473;
                                _5419[0] = ((float2(2.0) - _5463) / _5418[0]) - float2(1.0);
                                _5419[1] = (_5463 / _5418[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _5500 = _5463 * 3.0;
                                _5418[0] = float2(4.0) - _5500;
                                _5418[1] = float2(7.0);
                                _5418[2] = float2(1.0) + _5500;
                                _5419[0] = ((float2(3.0) - (_5463 * 2.0)) / _5418[0]) - float2(2.0);
                                _5419[1] = (float2(3.0) + _5463) / _5418[1];
                                _5419[2] = (_5463 / _5418[2]) + float2(2.0);
                            }
                            int _8467 = _5470 ? 2 : 3;
                            int _8281;
                            float _8284;
                            _8284 = 0.0;
                            _8281 = 0;
                            float _8290;
                            for (; _8281 < _8467; _8284 = _8290, _8281++)
                            {
                                _8290 = _8284;
                                for (int _8287 = 0; _8287 < _8467; )
                                {
                                    _8290 += ((_5418[_8287].x * _5418[_8281].y) * spvDepthCast(_212).sample_compare(_212Smplr, float3(fast::clamp(_192._m22.xy * (_5466 + float2(_5419[_8287].x, _5419[_8281].y)), _5408.xy, _5408.zw), _5132).xy, _5132));
                                    _8287++;
                                    continue;
                                }
                            }
                            _8291 = _8284 * (_5470 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _8303 = _8291;
                        break;
                    } while(false);
                    _8357 = _4881 * _8303;
                }
                else
                {
                    _8357 = _4881;
                }
                float _2547 = dot(_7868, _4850);
                _2576 = _8152 + (((_7862 * fast::max(_2547, 0.0)) * _8357) + (_8357 * ((powr(fast::max(dot(_7868, fast::normalize(_4850 + _2363)), 0.0), _1579._m1.w) * _1579._m1.z) * step(0.0, _2547))));
            }
            _8151 = _8152;
        }
        else
        {
            _8151 = _2495;
        }
        _8150 = _8151;
    }
    else
    {
        float4 _2586 = _2581.sample(_1229, _2124);
        float _2593 = fast::clamp(_1579._m4.x * _2586.z, 0.0, 1.0);
        float _2601 = fast::clamp(_1579._m4.y * _2586.y, 0.04500000178813934326171875, 1.0);
        float _7858;
        float _7863;
        if (_7799 > 0.0)
        {
            _7863 = mix(_2593, _7832.y, _7799);
            _7858 = mix(_2601, fast::max(_7832.x, 0.04500000178813934326171875), _7799);
        }
        else
        {
            _7863 = _2593;
            _7858 = _2601;
        }
        float _2620 = _7858 * _7858;
        float3 _2625 = _7862 * (1.0 - _7863);
        float3 _2631 = mix(float3(0.039999999105930328369140625), _7862, float3(_7863));
        bool _2635 = _7678 > 0.0;
        float3 _7891;
        if (_2635)
        {
            float3 _2640 = dfdx(in.m_1741);
            float3 _2642 = dfdy(in.m_1741);
            float3 _2643 = cross(_2640, _2642);
            float3 _7892;
            if (dot(_2643, _2643) > 9.9999996826552253889678874634872e-21)
            {
                _7892 = fast::normalize((fast::normalize(_2643) * ((dot(_2643, _2363) < 0.0) ? (-1.0) : 1.0)) + (_7868 - _2218));
            }
            else
            {
                _7892 = _7868;
            }
            _7891 = _7892;
        }
        else
        {
            _7891 = _7868;
        }
        float _2669 = fast::max(dot(_7891, _2363), 9.9999997473787516355514526367188e-05);
        float _2678 = dot(_7891, _2356);
        float _2679 = fast::clamp(_2678, 0.0, 1.0);
        float _2684 = fast::clamp(dot(_7891, _2368), 0.0, 1.0);
        float _2689 = fast::clamp(dot(_2363, _2368), 0.0, 1.0);
        float _7895;
        float _7896;
        if (_2635)
        {
            _7896 = fast::max(_2669, 0.5);
            _7895 = fast::max(_2689, 0.5);
        }
        else
        {
            _7896 = _2669;
            _7895 = _2689;
        }
        float3 _5602 = float3(1.0) - _2631;
        float3 _5605 = _2631 + (_5602 * powr(1.0 - _7895, 5.0));
        float _5612 = _2620 * _2620;
        float _5617 = _5612 - 1.0;
        float _5619 = ((_2684 * _2684) * _5617) + 1.0;
        float _5639 = 1.0 - _5612;
        float _5643 = sqrt(((_7896 * _7896) * _5639) + _5612);
        float3 _2735 = (((((float3(1.0) - _5605) * _2625) * fast::clamp(dot(_7868, _2356), 0.0, 1.0)) + (((_5605 * ((_5612 / ((3.1415927410125732421875 * _5619) * _5619)) * (0.5 / fast::max((_2679 * _5643) + (_7896 * sqrt(((_2679 * _2679) * _5639) + _5612)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875) * _2679)) * _2405) * _7902;
        float3 _8006;
        if (_2635)
        {
            _8006 = _2735 + (((((_2625 * _2405) * _7902) * _7678) * fast::clamp(-_2678, 0.0, 1.0)) * (0.3499999940395355224609375 + (0.64999997615814208984375 * powr(fast::clamp(dot(-_2363, _2356), 0.0, 1.0), 3.0))));
        }
        else
        {
            _8006 = _2735;
        }
        float3 _7932;
        float2 _7956;
        float3 _7968;
        if (_192._m29.x > 0.5)
        {
            float4 _5676 = _1333.sample(_1335, (((float2(_7896, _7858) * 31.0) + float2(0.5)) * float2(0.03125)));
            float _5735 = (_192._m29.z * _7868.x) - (_192._m29.w * _7868.z);
            float _5748 = (_192._m29.w * _7868.x) + (_192._m29.z * _7868.z);
            float _5766 = 1.09254801273345947265625 * _5735;
            spvUnsafeArray<float, 9> _7387 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _7868.y, 0.48860299587249755859375 * _5748, 0.48860299587249755859375 * _5735, _5766 * _7868.y, (1.09254801273345947265625 * _7868.y) * _5748, 0.3153919875621795654296875 * (((3.0 * _5748) * _5748) - 1.0), _5766 * _5748, 0.546274006366729736328125 * ((_5735 * _5735) - (_7868.y * _7868.y)) });
            spvUnsafeArray<float, 9> _5680 = _7387;
            float3 _7914;
            _7914 = float3(0.0);
            for (int _7913 = 0; _7913 < 9; )
            {
                _7914 += (_1227.read(uint2((int2(496, 256) + int2(_7913, 0))), 0).xyz * _5680[_7913]);
                _7913++;
                continue;
            }
            float3 _2787 = reflect(-_2363, _7891);
            float _5861 = _2787.x;
            float _5866 = _2787.z;
            float2 _5898 = float2((precise::atan2((_192._m29.z * _5861) - (_192._m29.w * _5866), -((_192._m29.w * _5861) + (_192._m29.z * _5866))) * 0.15915493667125701904296875) + 0.5, acos(fast::clamp(_2787.y, -1.0, 1.0)) * 0.3183098733425140380859375);
            float _5830 = _7858 * 5.0;
            int _5833 = min(int(_5830), 4);
            float2 _5919 = (_5898 * float2(_1289[_5833].zw)) - float2(0.5);
            float2 _5921 = floor(_5919);
            float2 _5924 = _5919 - _5921;
            int _5927 = int(_5921.x);
            int _5930 = int(_5921.y);
            int _7917;
            if (_5927 < 0)
            {
                _7917 = _5927 + _1289[_5833].z;
            }
            else
            {
                _7917 = _5927;
            }
            int _7918;
            if (_7917 >= _1289[_5833].z)
            {
                _7918 = _7917 - _1289[_5833].z;
            }
            else
            {
                _7918 = _7917;
            }
            int _5950 = _7918 + 1;
            int _8468 = (_5950 == _1289[_5833].z) ? 0 : _5950;
            int _5965 = min((_5930 + 1), (_1289[_5833].w - 1));
            int _5967 = max(_5930, 0);
            float3 _6020 = float3(_5924.x);
            int _5840 = _5833 + 1;
            float2 _6052 = (_5898 * float2(_1289[_5840].zw)) - float2(0.5);
            float2 _6054 = floor(_6052);
            float2 _6057 = _6052 - _6054;
            int _6060 = int(_6054.x);
            int _6063 = int(_6054.y);
            int _7924;
            if (_6060 < 0)
            {
                _7924 = _6060 + _1289[_5840].z;
            }
            else
            {
                _7924 = _6060;
            }
            int _7925;
            if (_7924 >= _1289[_5840].z)
            {
                _7925 = _7924 - _1289[_5840].z;
            }
            else
            {
                _7925 = _7924;
            }
            int _6083 = _7925 + 1;
            int _8469 = (_6083 == _1289[_5840].z) ? 0 : _6083;
            int _6098 = min((_6063 + 1), (_1289[_5840].w - 1));
            int _6100 = max(_6063, 0);
            float3 _6153 = float3(_6057.x);
            float3 _5855 = mix(mix(mix(_1227.read(uint2((_1289[_5833].xy + int2(_7918, _5967))), 0).xyz, _1227.read(uint2((_1289[_5833].xy + int2(_8468, _5967))), 0).xyz, _6020), mix(_1227.read(uint2((_1289[_5833].xy + int2(_7918, _5965))), 0).xyz, _1227.read(uint2((_1289[_5833].xy + int2(_8468, _5965))), 0).xyz, _6020), float3(_5924.y)), mix(mix(_1227.read(uint2((_1289[_5840].xy + int2(_7925, _6100))), 0).xyz, _1227.read(uint2((_1289[_5840].xy + int2(_8469, _6100))), 0).xyz, _6153), mix(_1227.read(uint2((_1289[_5840].xy + int2(_7925, _6098))), 0).xyz, _1227.read(uint2((_1289[_5840].xy + int2(_8469, _6098))), 0).xyz, _6153), float3(_6057.y)), float3(_5830 - float(_5833))) * _192._m29.y;
            _7968 = fast::max(_7914, float3(0.0)) * _192._m29.y;
            _7956 = _5676.xy;
            _7932 = _5855;
        }
        else
        {
            float4 _6171 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * _7858) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);
            float _6173 = _6171.x;
            float3 _6208 = mix(_192._m9.xyz, _192._m8.xyz, float3((_7868.y * 0.5) + 0.5)) * _192._m8.w;
            _7968 = _6208;
            _7956 = (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_6173 * _6173, exp2((-9.27999973297119140625) * _7896)) * _6173) + _6171.y)) + _6171.zw;
            _7932 = mix(mix(_192._m9.xyz, _192._m8.xyz, float3((reflect(-_2363, _7891).y * 0.5) + 0.5)) * _192._m8.w, _6208, float3(_7858));
        }
        bool _2819;
        if (_2409)
        {
            _2819 = _192._m33.z > 0.5;
        }
        else
        {
            _2819 = _2409;
        }
        float3 _7977;
        if (_2819)
        {
            float3 _7953;
            do
            {
                float _6287 = ((_192._m32.x * (1.0 - smoothstep(_192._m33.x * 0.5, _192._m33.x, abs(dot(_192._m31.xyz, in.m_1741) - _192._m31.w)))) * smoothstep(0.5, 0.89999997615814208984375, dot(_2374, _192._m31.xyz))) * (1.0 - smoothstep(_192._m32.y * 0.5, _192._m32.y, _7858));
                if (_6287 <= 0.0)
                {
                    _7953 = _7932;
                    break;
                }
                float4 _6312 = _192._m30 * float4(in.m_1741 + ((_7868 - (_192._m31.xyz * dot(_7868, _192._m31.xyz))) * _192._m32.w), 1.0);
                float2 _6325 = ((float2(_6312.x, -_6312.y) / float2(_6312.w)) * 0.5) + float2(0.5);
                float _6329 = _192._m32.z * _7858;
                float3 _7951;
                float _7952;
                _7952 = 0.0;
                _7951 = float3(0.0);
                for (int _7950 = 0; _7950 < 12; )
                {
                    float _6336 = float(_7950);
                    float _6344 = _6336 * 2.3999631404876708984375;
                    float2 _6356 = _6325 + (float2(cos(_6344) * _192._m33.y, sin(_6344)) * (sqrt((_6336 + 0.5) * 0.083333335816860198974609375) * _6329));
                    float2 _6361 = fast::min(_6356, float2(1.0) - _6356);
                    float _6367 = smoothstep(0.0, 0.039999999105930328369140625, fast::min(_6361.x, _6361.y));
                    float4 _6375 = _2057.sample(_1229, fast::clamp(_6356, float2(0.0), float2(1.0)), level(0.0));
                    float3 _6377 = _6375.xyz;
                    _7952 += (_6375.w * _6367);
                    _7951 += ((_6377 / (float3(1.0) - fast::min(_6377, float3(0.99500000476837158203125)))) * _6367);
                    _7950++;
                    continue;
                }
                _7953 = mix(_7932, (_7951 * float3(0.083333335816860198974609375)) + (_7932 * (1.0 - (_7952 * 0.083333335816860198974609375))), float3(_6287));
                break;
            } while(false);
            _7977 = _7953;
        }
        else
        {
            _7977 = _7932;
        }
        float3 _2839 = (_2631 * _7956.x) + float3(_7956.y);
        float3 _2855 = _8006 + (((((float3(1.0) - _2839) * _2625) * _7968) + (_2839 * _7977)) * _7992);
        float3 _8153;
        if (_192._m13.w > 0.5)
        {
            float2 _6441 = fast::clamp(floor(gl_FragCoord.xy * _192._m12.xy), float2(0.0), _192._m13.xy - float2(1.0));
            uint _6469 = uint((((fast::clamp(floor((log2(fast::max(dot(_192._m11.xyz, in.m_1741) + _192._m11.w, 9.9999999747524270787835121154785e-07)) * _192._m12.z) + _192._m12.w), 0.0, _192._m13.z - 1.0) * _192._m13.y) + _6441.y) * _192._m13.x) + _6441.x);
            uint _6471 = _6469 >> uint(2);
            uint _6473 = _6469 & 3u;
            uint _6477 = _1872._m0[_6471][_6473] & 65535u;
            uint _6479 = _1872._m0[_6471][_6473] >> uint(16);
            float3 _8106;
            _8106 = _2855;
            float3 _2955;
            spvUnsafeArray<float2, 3> _6887;
            spvUnsafeArray<float2, 3> _6888;
            spvUnsafeArray<float2, 3> _7100;
            spvUnsafeArray<float2, 3> _7101;
            for (uint _8009 = _6477; _8009 < (_6477 + _6479); _8106 = _2955, _8009++)
            {
                uint _6485 = _8009 / 3u;
                uint _6498 = (_1893._m0[_6485 >> uint(2)][_6485 & 3u] >> ((_8009 - (_6485 * 3u)) * 10u)) & 1023u;
                float3 _6515 = _1734._m0[_6498].xyz - in.m_1741;
                float _6518 = dot(_6515, _6515);
                float _6522 = _6518 * _1734._m0[_6498].w;
                float _6527 = fast::clamp(1.0 - (_6522 * _6522), 0.0, 1.0);
                float3 _6532 = _6515 * rsqrt(fast::max(_6518, 9.9999999392252902907785028219223e-09));
                float _6550 = fast::clamp((dot(-_6532, _1777._m0[_6498].xyz) * _1769._m0[_6498].w) + _1777._m0[_6498].w, 0.0, 1.0);
                float3 _6563 = _1769._m0[_6498].xyz * ((((_6527 * _6527) * _6550) * _6550) / fast::max(_6518, 9.9999997473787516355514526367188e-05));
                float3 _8104;
                if (_2379)
                {
                    float _8036;
                    do
                    {
                        uint _6599 = uint(_192._m21.z);
                        if (_6498 < _6599)
                        {
                            float _6621 = _192._m26[_6498].z * fast::max((_192._m15[_6498] * float4(in.m_1741, 1.0)).w, 0.0);
                            float4 _6645 = _192._m15[_6498] * float4((in.m_1741 + (_2374 * (_6621 * _192._m25.x))) + (_6532 * (_6621 * _192._m25.y)), 1.0);
                            float _6647 = _6645.w;
                            if (_6647 <= 0.0)
                            {
                                _8036 = 1.0;
                                break;
                            }
                            float3 _6656 = _6645.xyz / float3(_6647);
                            float _6658 = _6656.x;
                            bool _6659 = _6658 < 0.0;
                            bool _6666;
                            if (!_6659)
                            {
                                _6666 = _6658 > 1.0;
                            }
                            else
                            {
                                _6666 = _6659;
                            }
                            bool _6673;
                            if (!_6666)
                            {
                                _6673 = _6656.y < 0.0;
                            }
                            else
                            {
                                _6673 = _6666;
                            }
                            bool _6680;
                            if (!_6673)
                            {
                                _6680 = _6656.y > 1.0;
                            }
                            else
                            {
                                _6680 = _6673;
                            }
                            bool _6687;
                            if (!_6680)
                            {
                                _6687 = _6656.z > 1.0;
                            }
                            else
                            {
                                _6687 = _6680;
                            }
                            if (_6687)
                            {
                                _8036 = 1.0;
                                break;
                            }
                            float _6693 = _6656.z;
                            float2 _6859 = _192._m22.xy * 0.5;
                            float2 _6864 = _192._m26[_6498].xy + (_6656.xy * _192._m23.zw);
                            float4 _6877 = float4(_192._m26[_6498].xy + _6859, (_192._m26[_6498].xy + _192._m23.zw) - _6859);
                            float _8035;
                            do
                            {
                                int _6903 = int(_192._m22.z);
                                if (_6903 <= 0)
                                {
                                    float2 _6913 = fast::clamp(_6864, _6877.xy, _6877.zw);
                                    _8035 = spvDepthCast(_212).sample_compare(_212Smplr, float3(_6913, _6693).xy, _6693);
                                    break;
                                }
                                float2 _6926 = (_6864 / _192._m22.xy) + float2(0.5);
                                float2 _6927 = floor(_6926);
                                float2 _6932 = _6926 - _6927;
                                float2 _6935 = _6927 - float2(0.5);
                                bool _6939 = _6903 == 1;
                                if (_6939)
                                {
                                    float2 _6942 = _6932 * 2.0;
                                    _6887[0] = float2(3.0) - _6942;
                                    _6887[1] = float2(1.0) + _6942;
                                    _6888[0] = ((float2(2.0) - _6932) / _6887[0]) - float2(1.0);
                                    _6888[1] = (_6932 / _6887[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _6969 = _6932 * 3.0;
                                    _6887[0] = float2(4.0) - _6969;
                                    _6887[1] = float2(7.0);
                                    _6887[2] = float2(1.0) + _6969;
                                    _6888[0] = ((float2(3.0) - (_6932 * 2.0)) / _6887[0]) - float2(2.0);
                                    _6888[1] = (float2(3.0) + _6932) / _6887[1];
                                    _6888[2] = (_6932 / _6887[2]) + float2(2.0);
                                }
                                int _8471 = _6939 ? 2 : 3;
                                int _8025;
                                float _8028;
                                _8028 = 0.0;
                                _8025 = 0;
                                float _8034;
                                for (; _8025 < _8471; _8028 = _8034, _8025++)
                                {
                                    _8034 = _8028;
                                    for (int _8031 = 0; _8031 < _8471; )
                                    {
                                        _8034 += ((_6887[_8031].x * _6887[_8025].y) * spvDepthCast(_212).sample_compare(_212Smplr, float3(fast::clamp(_192._m22.xy * (_6935 + float2(_6888[_8031].x, _6888[_8025].y)), _6877.xy, _6877.zw), _6693).xy, _6693));
                                        _8031++;
                                        continue;
                                    }
                                }
                                _8035 = _8028 * (_6939 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _8036 = _8035;
                            break;
                        }
                        uint _6703 = _6498 - _6599;
                        if (_6703 >= uint(_192._m21.w))
                        {
                            _8036 = 1.0;
                            break;
                        }
                        float _6724 = _192._m27[_6703].w * length(in.m_1741 - _192._m27[_6703].xyz);
                        float3 _6742 = ((in.m_1741 + (_2374 * (_6724 * _192._m25.x))) + (_6532 * (_6724 * _192._m25.y))) - _192._m27[_6703].xyz;
                        float3 _6744 = abs(_6742);
                        float _6746 = _6744.x;
                        float _6748 = _6744.y;
                        bool _6749 = _6746 >= _6748;
                        bool _6757;
                        if (_6749)
                        {
                            _6757 = _6746 >= _6744.z;
                        }
                        else
                        {
                            _6757 = _6749;
                        }
                        float _8010;
                        int _8012;
                        if (_6757)
                        {
                            _8012 = (_6742.x > 0.0) ? 0 : 1;
                            _8010 = _6746;
                        }
                        else
                        {
                            float _6769 = _6744.z;
                            bool _6770 = _6748 >= _6769;
                            int _8013;
                            if (_6770)
                            {
                                _8013 = (_6742.y > 0.0) ? 2 : 3;
                            }
                            else
                            {
                                _8013 = (_6742.z > 0.0) ? 4 : 5;
                            }
                            _8012 = _8013;
                            _8010 = _6770 ? _6748 : _6769;
                        }
                        if (_8010 <= 0.0)
                        {
                            _8036 = 1.0;
                            break;
                        }
                        float2 _6807 = float2(dot(_6742, _870[_8012]), dot(_6742, _879[_8012])) / float2(_8010 * _192._m24.z);
                        float _6814 = _192._m28[_6703].z + (_192._m28[_6703].w / _8010);
                        if (_6814 > 1.0)
                        {
                            _8036 = 1.0;
                            break;
                        }
                        float2 _6832 = _192._m28[_6703].xy + (float2(float(spvSMod(_8012, 3)), float(_8012 / 3)) * _192._m24.xy);
                        float2 _7072 = _192._m22.xy * 0.5;
                        float2 _7077 = _6832 + (float2(0.5 + (0.5 * _6807.x), 0.5 - (0.5 * _6807.y)) * _192._m24.xy);
                        float4 _7090 = float4(_6832 + _7072, (_6832 + _192._m24.xy) - _7072);
                        float _8024;
                        do
                        {
                            int _7116 = int(_192._m22.z);
                            if (_7116 <= 0)
                            {
                                _8024 = spvDepthCast(_212).sample_compare(_212Smplr, float3(fast::clamp(_7077, _7090.xy, _7090.zw), _6814).xy, _6814);
                                break;
                            }
                            float2 _7139 = (_7077 / _192._m22.xy) + float2(0.5);
                            float2 _7140 = floor(_7139);
                            float2 _7145 = _7139 - _7140;
                            float2 _7148 = _7140 - float2(0.5);
                            bool _7152 = _7116 == 1;
                            if (_7152)
                            {
                                float2 _7155 = _7145 * 2.0;
                                _7100[0] = float2(3.0) - _7155;
                                _7100[1] = float2(1.0) + _7155;
                                _7101[0] = ((float2(2.0) - _7145) / _7100[0]) - float2(1.0);
                                _7101[1] = (_7145 / _7100[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _7182 = _7145 * 3.0;
                                _7100[0] = float2(4.0) - _7182;
                                _7100[1] = float2(7.0);
                                _7100[2] = float2(1.0) + _7182;
                                _7101[0] = ((float2(3.0) - (_7145 * 2.0)) / _7100[0]) - float2(2.0);
                                _7101[1] = (float2(3.0) + _7145) / _7100[1];
                                _7101[2] = (_7145 / _7100[2]) + float2(2.0);
                            }
                            int _8474 = _7152 ? 2 : 3;
                            int _8014;
                            float _8017;
                            _8017 = 0.0;
                            _8014 = 0;
                            float _8023;
                            for (; _8014 < _8474; _8017 = _8023, _8014++)
                            {
                                _8023 = _8017;
                                for (int _8020 = 0; _8020 < _8474; )
                                {
                                    _8023 += ((_7100[_8020].x * _7100[_8014].y) * spvDepthCast(_212).sample_compare(_212Smplr, float3(fast::clamp(_192._m22.xy * (_7148 + float2(_7101[_8020].x, _7101[_8014].y)), _7090.xy, _7090.zw), _6814).xy, _6814));
                                    _8020++;
                                    continue;
                                }
                            }
                            _8024 = _8017 * (_7152 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _8036 = _8024;
                        break;
                    } while(false);
                    _8104 = _6563 * _8036;
                }
                else
                {
                    _8104 = _6563;
                }
                float3 _2907 = fast::normalize(_6532 + _2363);
                float _2912 = fast::clamp(dot(_7868, _6532), 0.0, 1.0);
                float _2917 = fast::clamp(dot(_7868, _2907), 0.0, 1.0);
                float3 _7287 = _2631 + (_5602 * powr(1.0 - fast::clamp(dot(_2363, _2907), 0.0, 1.0), 5.0));
                float _7301 = ((_2917 * _2917) * _5617) + 1.0;
                _2955 = _8106 + (((((float3(1.0) - _7287) * _2625) + ((_7287 * ((_5612 / ((3.1415927410125732421875 * _7301) * _7301)) * (0.5 / fast::max((_2912 * _5643) + (_7896 * sqrt(((_2912 * _2912) * _5639) + _5612)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875)) * _2912) * _8104);
            }
            _8153 = _8106;
        }
        else
        {
            _8153 = _2855;
        }
        _8150 = _8153;
    }
    float4 _2972 = _2967.sample(_1229, _2124);
    float _2990 = -length(_2362);
    float _8195;
    if (_192._m9.w != 0.0)
    {
        float _3014 = _192._m9.w * (in.m_1741 - _192._m6.xyz).y;
        float _8192;
        if (abs(_3014) < 9.9999997473787516355514526367188e-05)
        {
            _8192 = 1.0 - (0.5 * _3014);
        }
        else
        {
            _8192 = (1.0 - exp(fast::min(-_3014, 60.0))) / _3014;
        }
        _8195 = 1.0 - exp((_2990 * (_192._m7.w * exp(fast::min((-_192._m9.w) * (_192._m6.y - _192._m6.w), 30.0)))) * _8192);
    }
    else
    {
        _8195 = 1.0 - exp(_2990 * _192._m7.w);
    }
    float3 _3065 = mix(mix(_8150, _7862, float3(_1579._m1.y)) + ((_1579._m5.xyz * _2972.xyz) * (float3(1.0) + in.m_2376.yzw)), _192._m7.xyz, float3(_8195));
    float3 _8196;
    if (_192._m33.w > 0.5)
    {
        _8196 = _3065 / (float3(1.0) + _3065);
    }
    else
    {
        _8196 = _3065;
    }
    out.m_3077 = float4(_8196, in.m_2133.w);
    float2 _8276;
    do
    {
        if (in.m_3087.w <= 0.0)
        {
            _8276 = float2(0.0);
            break;
        }
        _8276 = ((in.m_3087.xy / float2(in.m_3087.w)) - (in.m_3086.xy / float2(in.m_3086.w))) * float2(0.5, -0.5);
        break;
    } while(false);
    out.m_3085 = _8276;
    return out;
}

