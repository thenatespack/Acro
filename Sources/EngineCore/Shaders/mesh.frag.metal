// Generated from mesh.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 6789c53dcabdd880
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
    float4 m_3064 [[color(0)]];
    float2 m_3072 [[color(1)]];
};

struct fragment_main_in
{
    float3 m_1741 [[user(locn0)]];
    float3 m_1649 [[user(locn1)]];
    float2 m_2110 [[user(locn2)]];
    float4 m_2133 [[user(locn3)]];
    float3 m_1684 [[user(locn4)]];
    float4 m_2363 [[user(locn5)]];
    float4 m_3073 [[user(locn6)]];
    float4 m_3074 [[user(locn7)]];
    float4 m_1655 [[user(locn8)]];
};

fragment fragment_main_out fragment_main(fragment_main_in in [[stage_in]], constant _1577& _1579 [[buffer(2)]], constant _1732& _1734 [[buffer(3)]], constant _1767& _1769 [[buffer(4)]], constant _1775& _1777 [[buffer(5)]], constant _1870& _1872 [[buffer(6)]], constant _1891& _1893 [[buffer(7)]], constant _190& _192 [[buffer(15)]], texture2d<float> _212 [[texture(0)]], texture2d<float> _2126 [[texture(1)]], texture2d<float> _2568 [[texture(2)]], texture2d<float> _2240 [[texture(3)]], texture2d<float> _2057 [[texture(4)]], texture2d<float> _2954 [[texture(5)]], texture2d<float> _1227 [[texture(6)]], texture2d<float> _1333 [[texture(7)]], sampler _212Smplr [[sampler(0)]], sampler _1229 [[sampler(1)]], sampler _1335 [[sampler(7)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])
{
    fragment_main_out out = {};
    float2 _2124 = float2(dot(_1579._m2.xy, in.m_2110) + _1579._m2.z, dot(_1579._m3.xy, in.m_2110) + _1579._m3.z);
    float4 _2131 = _2126.sample(_1229, _2124);
    float3 _2141 = _2131.xyz;
    float3 _2142 = (in.m_2133.xyz * _1579._m0.xyz) * _2141;
    float3 _7674;
    if (_1579._m1.x > 0.5)
    {
        float2 _2163 = floor(in.m_1741.xz * float2(0.5));
        _7674 = _2142 * ((mod(abs(_2163.x + _2163.y), 2.0) < 0.5) ? 1.0 : 0.75);
    }
    else
    {
        _7674 = _2142;
    }
    float3 _7771;
    float _7802;
    float2 _7835;
    if (_1579._m3.w > 0.5)
    {
        float3 _3192;
        float2 _3199;
        float _7672;
        do
        {
            float3 _3163 = float4(_1579._m2.w, _1579._m3.w, 0.0, 0.0).xyy;
            float3 _3166 = floor(_3163 * float3(1.52587890625e-05));
            float3 _3171 = _3163 - (_3166 * 65536.0);
            float3 _3174 = floor(_3171 * float3(0.00390625));
            float3 _3182 = _3171 - (_3174 * 256.0);
            _3192 = (float3(_3182.x, _3174.x, _3166.x) * float3(0.0039215688593685626983642578125)) * 2.0;
            _3199 = float2(_3182.y, _3174.y) * float2(0.0039215688593685626983642578125);
            float _3202 = _3166.y - 128.0;
            float _3208 = floor(_3202 * 0.03125) * 0.3333333432674407958984375;
            float3 _3214 = fast::normalize(in.m_1649);
            float _3218 = dot(_3214, in.m_1655.xyz);
            float _3230 = (_3218 / fast::max(length(in.m_1655.xyz - (_3214 * _3218)), 9.9999999747524270787835121154785e-07)) * 25.5;
            if (((-24.0) + _3230) < (-2.0))
            {
                _7672 = 0.0;
                break;
            }
            float3 _3238 = in.m_1684 * (4.0 * exp2(mod(_3202, 32.0) * 0.3333333432674407958984375));
            float3 _3282 = floor(_3238);
            float3 _3285 = _3238 - _3282;
            float3 _3293 = (_3285 * _3285) * (float3(3.0) - (_3285 * 2.0));
            uint3 _3360 = uint3(int3(_3282));
            uint _3373 = (((_3360.x * 1597334677u) ^ (_3360.y * 3812015801u)) ^ (_3360.z * 2798796415u)) * 1597334677u;
            uint3 _3388 = uint3(int3(_3282 + float3(1.0, 0.0, 0.0)));
            uint _3401 = (((_3388.x * 1597334677u) ^ (_3388.y * 3812015801u)) ^ (_3388.z * 2798796415u)) * 1597334677u;
            float _3302 = _3293.x;
            uint3 _3416 = uint3(int3(_3282 + float3(0.0, 1.0, 0.0)));
            uint _3429 = (((_3416.x * 1597334677u) ^ (_3416.y * 3812015801u)) ^ (_3416.z * 2798796415u)) * 1597334677u;
            uint3 _3444 = uint3(int3(_3282 + float3(1.0, 1.0, 0.0)));
            uint _3457 = (((_3444.x * 1597334677u) ^ (_3444.y * 3812015801u)) ^ (_3444.z * 2798796415u)) * 1597334677u;
            float _3318 = _3293.y;
            uint3 _3472 = uint3(int3(_3282 + float3(0.0, 0.0, 1.0)));
            uint _3485 = (((_3472.x * 1597334677u) ^ (_3472.y * 3812015801u)) ^ (_3472.z * 2798796415u)) * 1597334677u;
            uint3 _3500 = uint3(int3(_3282 + float3(1.0, 0.0, 1.0)));
            uint _3513 = (((_3500.x * 1597334677u) ^ (_3500.y * 3812015801u)) ^ (_3500.z * 2798796415u)) * 1597334677u;
            uint3 _3528 = uint3(int3(_3282 + float3(0.0, 1.0, 1.0)));
            uint _3541 = (((_3528.x * 1597334677u) ^ (_3528.y * 3812015801u)) ^ (_3528.z * 2798796415u)) * 1597334677u;
            uint3 _3556 = uint3(int3(_3282 + float3(1.0)));
            uint _3569 = (((_3556.x * 1597334677u) ^ (_3556.y * 3812015801u)) ^ (_3556.z * 2798796415u)) * 1597334677u;
            float3 _3244 = (_3238 * 2.7000000476837158203125) + float3(17.299999237060546875, 5.099999904632568359375, 9.69999980926513671875);
            float3 _3595 = floor(_3244);
            float3 _3598 = _3244 - _3595;
            float3 _3606 = (_3598 * _3598) * (float3(3.0) - (_3598 * 2.0));
            uint3 _3673 = uint3(int3(_3595));
            uint _3686 = (((_3673.x * 1597334677u) ^ (_3673.y * 3812015801u)) ^ (_3673.z * 2798796415u)) * 1597334677u;
            uint3 _3701 = uint3(int3(_3595 + float3(1.0, 0.0, 0.0)));
            uint _3714 = (((_3701.x * 1597334677u) ^ (_3701.y * 3812015801u)) ^ (_3701.z * 2798796415u)) * 1597334677u;
            float _3615 = _3606.x;
            uint3 _3729 = uint3(int3(_3595 + float3(0.0, 1.0, 0.0)));
            uint _3742 = (((_3729.x * 1597334677u) ^ (_3729.y * 3812015801u)) ^ (_3729.z * 2798796415u)) * 1597334677u;
            uint3 _3757 = uint3(int3(_3595 + float3(1.0, 1.0, 0.0)));
            uint _3770 = (((_3757.x * 1597334677u) ^ (_3757.y * 3812015801u)) ^ (_3757.z * 2798796415u)) * 1597334677u;
            float _3631 = _3606.y;
            uint3 _3785 = uint3(int3(_3595 + float3(0.0, 0.0, 1.0)));
            uint _3798 = (((_3785.x * 1597334677u) ^ (_3785.y * 3812015801u)) ^ (_3785.z * 2798796415u)) * 1597334677u;
            uint3 _3813 = uint3(int3(_3595 + float3(1.0, 0.0, 1.0)));
            uint _3826 = (((_3813.x * 1597334677u) ^ (_3813.y * 3812015801u)) ^ (_3813.z * 2798796415u)) * 1597334677u;
            uint3 _3841 = uint3(int3(_3595 + float3(0.0, 1.0, 1.0)));
            uint _3854 = (((_3841.x * 1597334677u) ^ (_3841.y * 3812015801u)) ^ (_3841.z * 2798796415u)) * 1597334677u;
            uint3 _3869 = uint3(int3(_3595 + float3(1.0)));
            uint _3882 = (((_3869.x * 1597334677u) ^ (_3869.y * 3812015801u)) ^ (_3869.z * 2798796415u)) * 1597334677u;
            float _3249 = mix(0.449999988079071044921875, 0.0500000007450580596923828125, _3208);
            float _3253 = ((mix(mix(mix(float((_3373 ^ (_3373 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_3401 ^ (_3401 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _3302), mix(float((_3429 ^ (_3429 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_3457 ^ (_3457 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _3302), _3318), mix(mix(float((_3485 ^ (_3485 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_3513 ^ (_3513 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _3302), mix(float((_3541 ^ (_3541 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_3569 ^ (_3569 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _3302), _3318), _3293.z) * 0.64999997615814208984375) + (mix(mix(mix(float((_3686 ^ (_3686 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_3714 ^ (_3714 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _3615), mix(float((_3742 ^ (_3742 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_3770 ^ (_3770 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _3615), _3631), mix(mix(float((_3798 ^ (_3798 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_3826 ^ (_3826 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _3615), mix(float((_3854 ^ (_3854 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_3882 ^ (_3882 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _3615), _3631), _3606.z) * 0.3499999940395355224609375)) - 0.5;
            _7672 = smoothstep(-_3249, _3249, (_3230 + (-24.450000762939453125)) + (_3253 * mix(0.800000011920928955078125, 2.2000000476837158203125, _3208)));
            break;
        } while(false);
        _7835 = _3199;
        _7802 = _7672;
        _7771 = mix(_7674, (in.m_2133.xyz * _3192) * mix(float3(1.0), _2141 * 2.0, float3(0.5)), float3(_7672));
    }
    else
    {
        _7835 = float2(0.0);
        _7802 = 0.0;
        _7771 = _7674;
    }
    float3 _2205 = fast::normalize(in.m_1649);
    float3 _7684;
    if (_1579._m6.y > 0.5)
    {
        float3 _2220 = in.m_1655.xyz - (_2205 * dot(_2205, in.m_1655.xyz));
        float3 _7685;
        if (dot(_2220, _2220) > 9.9999999600419720025001879548654e-13)
        {
            float3 _2229 = fast::normalize(_2220);
            float4 _2245 = _2240.sample(_1229, _2124);
            float3 _7676;
            if (_1579._m6.z > 0.5)
            {
                float2 _7675;
                if (_1579._m6.z > 1.5)
                {
                    _7675 = _2245.xw;
                }
                else
                {
                    _7675 = _2245.xy;
                }
                float2 _2267 = (_7675 * 2.0) - float2(1.0);
                _7676 = float3(_2267, sqrt(fast::clamp(1.0 - dot(_2267, _2267), 0.0, 1.0)));
            }
            else
            {
                _7676 = (_2245.xyz * 2.0) - float3(1.0);
            }
            float2 _2289 = _7676.xy * _1579._m4.z;
            _7685 = fast::normalize(((_2229 * _2289.x) + ((cross(_2205, _2229) * ((in.m_1655.w < 0.0) ? (-1.0) : 1.0)) * _2289.y)) + (_2205 * _7676.z));
        }
        else
        {
            _7685 = _2205;
        }
        _7684 = _7685;
    }
    else
    {
        _7684 = _2205;
    }
    bool _2313 = _1579._m5.w > 0.5;
    float _7681;
    if (_2313)
    {
        _7681 = fast::clamp(_1579._m1.z, 0.0, 1.0);
    }
    else
    {
        _7681 = 0.0;
    }
    bool _2331;
    if (_2313)
    {
        _2331 = !gl_FrontFacing;
    }
    else
    {
        _2331 = _2313;
    }
    float3 _7871;
    if (_2331 && (_7681 <= 0.0))
    {
        _7871 = -_7684;
    }
    else
    {
        _7871 = _7684;
    }
    float3 _2343 = fast::normalize(_192._m4.xyz);
    float3 _2349 = _192._m6.xyz - in.m_1741;
    float3 _2350 = fast::normalize(_2349);
    float3 _2355 = fast::normalize(_2343 + _2350);
    float3 _2361 = _2205 * (gl_FrontFacing ? 1.0 : (-1.0));
    bool _2366 = in.m_2363.x > 0.5;
    float3 _7865;
    float _7905;
    if ((_192._m5.w > 0.5) && _2366)
    {
        float _7741;
        float3 _7742;
        do
        {
            int _3911 = int(_192._m21.x);
            float _3919 = dot(_192._m20.xyz, in.m_1741) + _192._m20.w;
            int _7686;
            _7686 = 0;
            for (;;)
            {
                bool _3925 = _7686 < (_3911 - 1);
                bool _3933;
                if (_3925)
                {
                    _3933 = _3919 > _192._m16[_7686];
                }
                else
                {
                    _3933 = _3925;
                }
                if (_3933)
                {
                    _7686++;
                    continue;
                }
                else
                {
                    break;
                }
            }
            if (_3919 > _192._m16[_7686])
            {
                _7742 = float3(1.0);
                _7741 = 1.0;
                break;
            }
            float _7699;
            do
            {
                float4 _4035 = _192._m14[_7686] * float4(in.m_1741 + (_2361 * _192._m18[_7686]), 1.0);
                float _4038 = _4035.x;
                bool _4039 = _4038 < 0.0;
                bool _4046;
                if (!_4039)
                {
                    _4046 = _4038 > 1.0;
                }
                else
                {
                    _4046 = _4039;
                }
                bool _4053;
                if (!_4046)
                {
                    _4053 = _4035.y < 0.0;
                }
                else
                {
                    _4053 = _4046;
                }
                bool _4060;
                if (!_4053)
                {
                    _4060 = _4035.y > 1.0;
                }
                else
                {
                    _4060 = _4053;
                }
                if (_4060)
                {
                    _7699 = 1.0;
                    break;
                }
                float2 _4073 = float2(float(_7686 & 1), float(_7686 >> 1)) * _192._m23.xy;
                float _4080 = fast::min(_4035.z, 1.0) - _192._m19[_7686];
                float2 _4099 = _192._m22.xy * 0.5;
                float2 _4104 = _4073 + (_4035.xy * _192._m23.xy);
                float4 _4117 = float4(_4073 + _4099, (_4073 + _192._m23.xy) - _4099);
                float _7698;
                do
                {
                    int _4143 = int(_192._m22.z);
                    if (_4143 <= 0)
                    {
                        _7698 = spvDepthCast(_212).sample_compare(_212Smplr, float3(fast::clamp(_4104, _4117.xy, _4117.zw), _4080).xy, _4080);
                        break;
                    }
                    float2 _4166 = (_4104 / _192._m22.xy) + float2(0.5);
                    float2 _4167 = floor(_4166);
                    float2 _4172 = _4166 - _4167;
                    float2 _4175 = _4167 - float2(0.5);
                    bool _4179 = _4143 == 1;
                    spvUnsafeArray<float2, 3> _4127;
                    spvUnsafeArray<float2, 3> _4128;
                    if (_4179)
                    {
                        float2 _4182 = _4172 * 2.0;
                        _4127[0] = float2(3.0) - _4182;
                        _4127[1] = float2(1.0) + _4182;
                        _4128[0] = ((float2(2.0) - _4172) / _4127[0]) - float2(1.0);
                        _4128[1] = (_4172 / _4127[1]) + float2(1.0);
                    }
                    else
                    {
                        float2 _4209 = _4172 * 3.0;
                        _4127[0] = float2(4.0) - _4209;
                        _4127[1] = float2(7.0);
                        _4127[2] = float2(1.0) + _4209;
                        _4128[0] = ((float2(3.0) - (_4172 * 2.0)) / _4127[0]) - float2(2.0);
                        _4128[1] = (float2(3.0) + _4172) / _4127[1];
                        _4128[2] = (_4172 / _4127[2]) + float2(2.0);
                    }
                    int _8364 = _4179 ? 2 : 3;
                    int _7688;
                    float _7691;
                    _7691 = 0.0;
                    _7688 = 0;
                    float _7697;
                    for (; _7688 < _8364; _7691 = _7697, _7688++)
                    {
                        _7697 = _7691;
                        for (int _7694 = 0; _7694 < _8364; )
                        {
                            _7697 += ((_4127[_7694].x * _4127[_7688].y) * spvDepthCast(_212).sample_compare(_212Smplr, float3(fast::clamp(_192._m22.xy * (_4175 + float2(_4128[_7694].x, _4128[_7688].y)), _4117.xy, _4117.zw), _4080).xy, _4080));
                            _7694++;
                            continue;
                        }
                    }
                    _7698 = _7691 * (_4179 ? 0.0625 : 0.0069444444961845874786376953125);
                    break;
                } while(false);
                _7699 = _7698;
                break;
            } while(false);
            float3 _7736;
            float _7739;
            if (_3919 > _192._m17[_7686])
            {
                float _3973 = (_3919 - _192._m17[_7686]) / (_192._m16[_7686] - _192._m17[_7686]);
                int _3975 = _7686 + 1;
                float3 _7737;
                float _7740;
                if (_3975 < _3911)
                {
                    float _7719;
                    do
                    {
                        float4 _4322 = _192._m14[_3975] * float4(in.m_1741 + (_2361 * _192._m18[_3975]), 1.0);
                        float _4325 = _4322.x;
                        bool _4326 = _4325 < 0.0;
                        bool _4333;
                        if (!_4326)
                        {
                            _4333 = _4325 > 1.0;
                        }
                        else
                        {
                            _4333 = _4326;
                        }
                        bool _4340;
                        if (!_4333)
                        {
                            _4340 = _4322.y < 0.0;
                        }
                        else
                        {
                            _4340 = _4333;
                        }
                        bool _4347;
                        if (!_4340)
                        {
                            _4347 = _4322.y > 1.0;
                        }
                        else
                        {
                            _4347 = _4340;
                        }
                        if (_4347)
                        {
                            _7719 = 1.0;
                            break;
                        }
                        float2 _4360 = float2(float(_3975 & 1), float(_3975 >> 1)) * _192._m23.xy;
                        float _4367 = fast::min(_4322.z, 1.0) - _192._m19[_3975];
                        float2 _4386 = _192._m22.xy * 0.5;
                        float2 _4391 = _4360 + (_4322.xy * _192._m23.xy);
                        float4 _4404 = float4(_4360 + _4386, (_4360 + _192._m23.xy) - _4386);
                        float _7718;
                        do
                        {
                            int _4430 = int(_192._m22.z);
                            if (_4430 <= 0)
                            {
                                _7718 = spvDepthCast(_212).sample_compare(_212Smplr, float3(fast::clamp(_4391, _4404.xy, _4404.zw), _4367).xy, _4367);
                                break;
                            }
                            float2 _4453 = (_4391 / _192._m22.xy) + float2(0.5);
                            float2 _4454 = floor(_4453);
                            float2 _4459 = _4453 - _4454;
                            float2 _4462 = _4454 - float2(0.5);
                            bool _4466 = _4430 == 1;
                            spvUnsafeArray<float2, 3> _4414;
                            spvUnsafeArray<float2, 3> _4415;
                            if (_4466)
                            {
                                float2 _4469 = _4459 * 2.0;
                                _4414[0] = float2(3.0) - _4469;
                                _4414[1] = float2(1.0) + _4469;
                                _4415[0] = ((float2(2.0) - _4459) / _4414[0]) - float2(1.0);
                                _4415[1] = (_4459 / _4414[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _4496 = _4459 * 3.0;
                                _4414[0] = float2(4.0) - _4496;
                                _4414[1] = float2(7.0);
                                _4414[2] = float2(1.0) + _4496;
                                _4415[0] = ((float2(3.0) - (_4459 * 2.0)) / _4414[0]) - float2(2.0);
                                _4415[1] = (float2(3.0) + _4459) / _4414[1];
                                _4415[2] = (_4459 / _4414[2]) + float2(2.0);
                            }
                            int _8366 = _4466 ? 2 : 3;
                            int _7708;
                            float _7711;
                            _7711 = 0.0;
                            _7708 = 0;
                            float _7717;
                            for (; _7708 < _8366; _7711 = _7717, _7708++)
                            {
                                _7717 = _7711;
                                for (int _7714 = 0; _7714 < _8366; )
                                {
                                    _7717 += ((_4414[_7714].x * _4414[_7708].y) * spvDepthCast(_212).sample_compare(_212Smplr, float3(fast::clamp(_192._m22.xy * (_4462 + float2(_4415[_7714].x, _4415[_7708].y)), _4404.xy, _4404.zw), _4367).xy, _4367));
                                    _7714++;
                                    continue;
                                }
                            }
                            _7718 = _7711 * (_4466 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _7719 = _7718;
                        break;
                    } while(false);
                    _7740 = mix(_7699, _7719, _3973);
                    _7737 = mix(_566[_7686], _566[_3975], float3(_3973));
                }
                else
                {
                    _7740 = mix(_7699, 1.0, _3973);
                    _7737 = _566[_7686];
                }
                _7739 = _7740;
                _7736 = _7737;
            }
            else
            {
                _7739 = _7699;
                _7736 = _566[_7686];
            }
            _7742 = select(float3(1.0), _7736, bool3(_192._m22.w > 0.5));
            _7741 = _7739;
            break;
        } while(false);
        _7905 = _7741;
        _7865 = _7771 * _7742;
    }
    else
    {
        _7905 = 1.0;
        _7865 = _7771;
    }
    float3 _2392 = _192._m5.xyz * _192._m4.w;
    bool _2396 = _1579._m6.w > 0.5;
    float _7794;
    if (_2396)
    {
        _7794 = 1.0;
    }
    else
    {
        _7794 = 1.0 + (_1579._m4.w * (_2057.sample(_1229, _2124).x - 1.0));
    }
    float _2416 = abs(in.m_1655.w);
    float _7995;
    if (_2416 > 0.0)
    {
        _7995 = _7794 * fast::min(_2416, 1.0);
    }
    else
    {
        _7995 = _7794;
    }
    float3 _8153;
    if (!_2313)
    {
        float _2432 = dot(_7871, _2343);
        float3 _8145;
        if (_192._m29.x > 0.5)
        {
            float _4647 = (_192._m29.z * _7871.x) - (_192._m29.w * _7871.z);
            float _4660 = (_192._m29.w * _7871.x) + (_192._m29.z * _7871.z);
            float _4678 = 1.09254801273345947265625 * _4647;
            spvUnsafeArray<float, 9> _7410 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _7871.y, 0.48860299587249755859375 * _4660, 0.48860299587249755859375 * _4647, _4678 * _7871.y, (1.09254801273345947265625 * _7871.y) * _4660, 0.3153919875621795654296875 * (((3.0 * _4660) * _4660) - 1.0), _4678 * _4660, 0.546274006366729736328125 * ((_4647 * _4647) - (_7871.y * _7871.y)) });
            spvUnsafeArray<float, 9> _4592 = _7410;
            float3 _8144;
            _8144 = float3(0.0);
            for (int _8143 = 0; _8143 < 9; )
            {
                _8144 += (_1227.read(uint2((int2(496, 256) + int2(_8143, 0))), 0).xyz * _4592[_8143]);
                _8143++;
                continue;
            }
            _8145 = fast::max(_8144, float3(0.0)) * _192._m29.y;
        }
        else
        {
            _8145 = mix(_192._m9.xyz, _192._m8.xyz, float3((_7871.y * 0.5) + 0.5)) * _192._m8.w;
        }
        float3 _2482 = (_7865 * ((_8145 * _7995) + ((_2392 * fast::max(_2432, 0.0)) * _7905))) + ((_2392 * ((powr(fast::max(dot(_7871, _2355), 0.0), _1579._m1.w) * _1579._m1.z) * step(0.0, _2432))) * _7905);
        float3 _8154;
        if (_192._m13.w > 0.5)
        {
            float2 _4763 = fast::clamp(floor(gl_FragCoord.xy * _192._m12.xy), float2(0.0), _192._m13.xy - float2(1.0));
            uint _4791 = uint((((fast::clamp(floor((log2(fast::max(dot(_192._m11.xyz, in.m_1741) + _192._m11.w, 9.9999999747524270787835121154785e-07)) * _192._m12.z) + _192._m12.w), 0.0, _192._m13.z - 1.0) * _192._m13.y) + _4763.y) * _192._m13.x) + _4763.x);
            uint _4793 = _4791 >> uint(2);
            uint _4795 = _4791 & 3u;
            uint _4799 = _1872._m0[_4793][_4795] & 65535u;
            uint _4801 = _1872._m0[_4793][_4795] >> uint(16);
            float3 _8155;
            _8155 = _2482;
            float3 _2563;
            spvUnsafeArray<float2, 3> _5209;
            spvUnsafeArray<float2, 3> _5210;
            spvUnsafeArray<float2, 3> _5422;
            spvUnsafeArray<float2, 3> _5423;
            for (uint _8152 = _4799; _8152 < (_4799 + _4801); _8155 = _2563, _8152++)
            {
                uint _4807 = _8152 / 3u;
                uint _4820 = (_1893._m0[_4807 >> uint(2)][_4807 & 3u] >> ((_8152 - (_4807 * 3u)) * 10u)) & 1023u;
                float3 _4837 = _1734._m0[_4820].xyz - in.m_1741;
                float _4840 = dot(_4837, _4837);
                float _4844 = _4840 * _1734._m0[_4820].w;
                float _4849 = fast::clamp(1.0 - (_4844 * _4844), 0.0, 1.0);
                float3 _4854 = _4837 * rsqrt(fast::max(_4840, 9.9999999392252902907785028219223e-09));
                float _4872 = fast::clamp((dot(-_4854, _1777._m0[_4820].xyz) * _1769._m0[_4820].w) + _1777._m0[_4820].w, 0.0, 1.0);
                float3 _4885 = _1769._m0[_4820].xyz * ((((_4849 * _4849) * _4872) * _4872) / fast::max(_4840, 9.9999997473787516355514526367188e-05));
                float3 _8281;
                if (_2366)
                {
                    float _8227;
                    do
                    {
                        uint _4921 = uint(_192._m21.z);
                        if (_4820 < _4921)
                        {
                            float _4943 = _192._m26[_4820].z * fast::max((_192._m15[_4820] * float4(in.m_1741, 1.0)).w, 0.0);
                            float4 _4967 = _192._m15[_4820] * float4((in.m_1741 + (_2361 * (_4943 * _192._m25.x))) + (_4854 * (_4943 * _192._m25.y)), 1.0);
                            float _4969 = _4967.w;
                            if (_4969 <= 0.0)
                            {
                                _8227 = 1.0;
                                break;
                            }
                            float3 _4978 = _4967.xyz / float3(_4969);
                            float _4980 = _4978.x;
                            bool _4981 = _4980 < 0.0;
                            bool _4988;
                            if (!_4981)
                            {
                                _4988 = _4980 > 1.0;
                            }
                            else
                            {
                                _4988 = _4981;
                            }
                            bool _4995;
                            if (!_4988)
                            {
                                _4995 = _4978.y < 0.0;
                            }
                            else
                            {
                                _4995 = _4988;
                            }
                            bool _5002;
                            if (!_4995)
                            {
                                _5002 = _4978.y > 1.0;
                            }
                            else
                            {
                                _5002 = _4995;
                            }
                            bool _5009;
                            if (!_5002)
                            {
                                _5009 = _4978.z > 1.0;
                            }
                            else
                            {
                                _5009 = _5002;
                            }
                            if (_5009)
                            {
                                _8227 = 1.0;
                                break;
                            }
                            float _5015 = _4978.z;
                            float2 _5181 = _192._m22.xy * 0.5;
                            float2 _5186 = _192._m26[_4820].xy + (_4978.xy * _192._m23.zw);
                            float4 _5199 = float4(_192._m26[_4820].xy + _5181, (_192._m26[_4820].xy + _192._m23.zw) - _5181);
                            float _8226;
                            do
                            {
                                int _5225 = int(_192._m22.z);
                                if (_5225 <= 0)
                                {
                                    float2 _5235 = fast::clamp(_5186, _5199.xy, _5199.zw);
                                    _8226 = spvDepthCast(_212).sample_compare(_212Smplr, float3(_5235, _5015).xy, _5015);
                                    break;
                                }
                                float2 _5248 = (_5186 / _192._m22.xy) + float2(0.5);
                                float2 _5249 = floor(_5248);
                                float2 _5254 = _5248 - _5249;
                                float2 _5257 = _5249 - float2(0.5);
                                bool _5261 = _5225 == 1;
                                if (_5261)
                                {
                                    float2 _5264 = _5254 * 2.0;
                                    _5209[0] = float2(3.0) - _5264;
                                    _5209[1] = float2(1.0) + _5264;
                                    _5210[0] = ((float2(2.0) - _5254) / _5209[0]) - float2(1.0);
                                    _5210[1] = (_5254 / _5209[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _5291 = _5254 * 3.0;
                                    _5209[0] = float2(4.0) - _5291;
                                    _5209[1] = float2(7.0);
                                    _5209[2] = float2(1.0) + _5291;
                                    _5210[0] = ((float2(3.0) - (_5254 * 2.0)) / _5209[0]) - float2(2.0);
                                    _5210[1] = (float2(3.0) + _5254) / _5209[1];
                                    _5210[2] = (_5254 / _5209[2]) + float2(2.0);
                                }
                                int _8371 = _5261 ? 2 : 3;
                                int _8216;
                                float _8219;
                                _8219 = 0.0;
                                _8216 = 0;
                                float _8225;
                                for (; _8216 < _8371; _8219 = _8225, _8216++)
                                {
                                    _8225 = _8219;
                                    for (int _8222 = 0; _8222 < _8371; )
                                    {
                                        _8225 += ((_5209[_8222].x * _5209[_8216].y) * spvDepthCast(_212).sample_compare(_212Smplr, float3(fast::clamp(_192._m22.xy * (_5257 + float2(_5210[_8222].x, _5210[_8216].y)), _5199.xy, _5199.zw), _5015).xy, _5015));
                                        _8222++;
                                        continue;
                                    }
                                }
                                _8226 = _8219 * (_5261 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _8227 = _8226;
                            break;
                        }
                        uint _5025 = _4820 - _4921;
                        if (_5025 >= uint(_192._m21.w))
                        {
                            _8227 = 1.0;
                            break;
                        }
                        float _5046 = _192._m27[_5025].w * length(in.m_1741 - _192._m27[_5025].xyz);
                        float3 _5064 = ((in.m_1741 + (_2361 * (_5046 * _192._m25.x))) + (_4854 * (_5046 * _192._m25.y))) - _192._m27[_5025].xyz;
                        float3 _5066 = abs(_5064);
                        float _5068 = _5066.x;
                        float _5070 = _5066.y;
                        bool _5071 = _5068 >= _5070;
                        bool _5079;
                        if (_5071)
                        {
                            _5079 = _5068 >= _5066.z;
                        }
                        else
                        {
                            _5079 = _5071;
                        }
                        float _8201;
                        int _8203;
                        if (_5079)
                        {
                            _8203 = (_5064.x > 0.0) ? 0 : 1;
                            _8201 = _5068;
                        }
                        else
                        {
                            float _5091 = _5066.z;
                            bool _5092 = _5070 >= _5091;
                            int _8204;
                            if (_5092)
                            {
                                _8204 = (_5064.y > 0.0) ? 2 : 3;
                            }
                            else
                            {
                                _8204 = (_5064.z > 0.0) ? 4 : 5;
                            }
                            _8203 = _8204;
                            _8201 = _5092 ? _5070 : _5091;
                        }
                        if (_8201 <= 0.0)
                        {
                            _8227 = 1.0;
                            break;
                        }
                        float2 _5129 = float2(dot(_5064, _870[_8203]), dot(_5064, _879[_8203])) / float2(_8201 * _192._m24.z);
                        float _5136 = _192._m28[_5025].z + (_192._m28[_5025].w / _8201);
                        if (_5136 > 1.0)
                        {
                            _8227 = 1.0;
                            break;
                        }
                        float2 _5154 = _192._m28[_5025].xy + (float2(float(spvSMod(_8203, 3)), float(_8203 / 3)) * _192._m24.xy);
                        float2 _5394 = _192._m22.xy * 0.5;
                        float2 _5399 = _5154 + (float2(0.5 + (0.5 * _5129.x), 0.5 - (0.5 * _5129.y)) * _192._m24.xy);
                        float4 _5412 = float4(_5154 + _5394, (_5154 + _192._m24.xy) - _5394);
                        float _8215;
                        do
                        {
                            int _5438 = int(_192._m22.z);
                            if (_5438 <= 0)
                            {
                                _8215 = spvDepthCast(_212).sample_compare(_212Smplr, float3(fast::clamp(_5399, _5412.xy, _5412.zw), _5136).xy, _5136);
                                break;
                            }
                            float2 _5461 = (_5399 / _192._m22.xy) + float2(0.5);
                            float2 _5462 = floor(_5461);
                            float2 _5467 = _5461 - _5462;
                            float2 _5470 = _5462 - float2(0.5);
                            bool _5474 = _5438 == 1;
                            if (_5474)
                            {
                                float2 _5477 = _5467 * 2.0;
                                _5422[0] = float2(3.0) - _5477;
                                _5422[1] = float2(1.0) + _5477;
                                _5423[0] = ((float2(2.0) - _5467) / _5422[0]) - float2(1.0);
                                _5423[1] = (_5467 / _5422[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _5504 = _5467 * 3.0;
                                _5422[0] = float2(4.0) - _5504;
                                _5422[1] = float2(7.0);
                                _5422[2] = float2(1.0) + _5504;
                                _5423[0] = ((float2(3.0) - (_5467 * 2.0)) / _5422[0]) - float2(2.0);
                                _5423[1] = (float2(3.0) + _5467) / _5422[1];
                                _5423[2] = (_5467 / _5422[2]) + float2(2.0);
                            }
                            int _8374 = _5474 ? 2 : 3;
                            int _8205;
                            float _8208;
                            _8208 = 0.0;
                            _8205 = 0;
                            float _8214;
                            for (; _8205 < _8374; _8208 = _8214, _8205++)
                            {
                                _8214 = _8208;
                                for (int _8211 = 0; _8211 < _8374; )
                                {
                                    _8214 += ((_5422[_8211].x * _5422[_8205].y) * spvDepthCast(_212).sample_compare(_212Smplr, float3(fast::clamp(_192._m22.xy * (_5470 + float2(_5423[_8211].x, _5423[_8205].y)), _5412.xy, _5412.zw), _5136).xy, _5136));
                                    _8211++;
                                    continue;
                                }
                            }
                            _8215 = _8208 * (_5474 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _8227 = _8215;
                        break;
                    } while(false);
                    _8281 = _4885 * _8227;
                }
                else
                {
                    _8281 = _4885;
                }
                float _2534 = dot(_7871, _4854);
                _2563 = _8155 + (((_7865 * fast::max(_2534, 0.0)) * _8281) + (_8281 * ((powr(fast::max(dot(_7871, fast::normalize(_4854 + _2350)), 0.0), _1579._m1.w) * _1579._m1.z) * step(0.0, _2534))));
            }
            _8154 = _8155;
        }
        else
        {
            _8154 = _2482;
        }
        _8153 = _8154;
    }
    else
    {
        float4 _2573 = _2568.sample(_1229, _2124);
        float _2580 = fast::clamp(_1579._m4.x * _2573.z, 0.0, 1.0);
        float _2588 = fast::clamp(_1579._m4.y * _2573.y, 0.04500000178813934326171875, 1.0);
        float _7861;
        float _7866;
        if (_7802 > 0.0)
        {
            _7866 = mix(_2580, _7835.y, _7802);
            _7861 = mix(_2588, fast::max(_7835.x, 0.04500000178813934326171875), _7802);
        }
        else
        {
            _7866 = _2580;
            _7861 = _2588;
        }
        float _2607 = _7861 * _7861;
        float3 _2612 = _7865 * (1.0 - _7866);
        float3 _2618 = mix(float3(0.039999999105930328369140625), _7865, float3(_7866));
        bool _2622 = _7681 > 0.0;
        float3 _7894;
        if (_2622)
        {
            float3 _2627 = dfdx(in.m_1741);
            float3 _2629 = dfdy(in.m_1741);
            float3 _2630 = cross(_2627, _2629);
            float3 _7895;
            if (dot(_2630, _2630) > 9.9999996826552253889678874634872e-21)
            {
                _7895 = fast::normalize((fast::normalize(_2630) * ((dot(_2630, _2350) < 0.0) ? (-1.0) : 1.0)) + (_7871 - _2205));
            }
            else
            {
                _7895 = _7871;
            }
            _7894 = _7895;
        }
        else
        {
            _7894 = _7871;
        }
        float _2656 = fast::max(dot(_7894, _2350), 9.9999997473787516355514526367188e-05);
        float _2665 = dot(_7894, _2343);
        float _2666 = fast::clamp(_2665, 0.0, 1.0);
        float _2671 = fast::clamp(dot(_7894, _2355), 0.0, 1.0);
        float _2676 = fast::clamp(dot(_2350, _2355), 0.0, 1.0);
        float _7898;
        float _7899;
        if (_2622)
        {
            _7899 = fast::max(_2656, 0.5);
            _7898 = fast::max(_2676, 0.5);
        }
        else
        {
            _7899 = _2656;
            _7898 = _2676;
        }
        float3 _5606 = float3(1.0) - _2618;
        float3 _5609 = _2618 + (_5606 * powr(1.0 - _7898, 5.0));
        float _5616 = _2607 * _2607;
        float _5621 = _5616 - 1.0;
        float _5623 = ((_2671 * _2671) * _5621) + 1.0;
        float _5643 = 1.0 - _5616;
        float _5647 = sqrt(((_7899 * _7899) * _5643) + _5616);
        float3 _2722 = (((((float3(1.0) - _5609) * _2612) * fast::clamp(dot(_7871, _2343), 0.0, 1.0)) + (((_5609 * ((_5616 / ((3.1415927410125732421875 * _5623) * _5623)) * (0.5 / fast::max((_2666 * _5647) + (_7899 * sqrt(((_2666 * _2666) * _5643) + _5616)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875) * _2666)) * _2392) * _7905;
        float3 _8009;
        if (_2622)
        {
            _8009 = _2722 + (((((_2612 * _2392) * _7905) * _7681) * fast::clamp(-_2665, 0.0, 1.0)) * (0.3499999940395355224609375 + (0.64999997615814208984375 * powr(fast::clamp(dot(-_2350, _2343), 0.0, 1.0), 3.0))));
        }
        else
        {
            _8009 = _2722;
        }
        float3 _7935;
        float2 _7959;
        float3 _7971;
        if (_192._m29.x > 0.5)
        {
            float4 _5680 = _1333.sample(_1335, (((float2(_7899, _7861) * 31.0) + float2(0.5)) * float2(0.03125)));
            float _5739 = (_192._m29.z * _7871.x) - (_192._m29.w * _7871.z);
            float _5752 = (_192._m29.w * _7871.x) + (_192._m29.z * _7871.z);
            float _5770 = 1.09254801273345947265625 * _5739;
            spvUnsafeArray<float, 9> _7391 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _7871.y, 0.48860299587249755859375 * _5752, 0.48860299587249755859375 * _5739, _5770 * _7871.y, (1.09254801273345947265625 * _7871.y) * _5752, 0.3153919875621795654296875 * (((3.0 * _5752) * _5752) - 1.0), _5770 * _5752, 0.546274006366729736328125 * ((_5739 * _5739) - (_7871.y * _7871.y)) });
            spvUnsafeArray<float, 9> _5684 = _7391;
            float3 _7917;
            _7917 = float3(0.0);
            for (int _7916 = 0; _7916 < 9; )
            {
                _7917 += (_1227.read(uint2((int2(496, 256) + int2(_7916, 0))), 0).xyz * _5684[_7916]);
                _7916++;
                continue;
            }
            float3 _2774 = reflect(-_2350, _7894);
            float _5865 = _2774.x;
            float _5870 = _2774.z;
            float2 _5902 = float2((precise::atan2((_192._m29.z * _5865) - (_192._m29.w * _5870), -((_192._m29.w * _5865) + (_192._m29.z * _5870))) * 0.15915493667125701904296875) + 0.5, acos(fast::clamp(_2774.y, -1.0, 1.0)) * 0.3183098733425140380859375);
            float _5834 = _7861 * 5.0;
            int _5837 = min(int(_5834), 4);
            float2 _5923 = (_5902 * float2(_1289[_5837].zw)) - float2(0.5);
            float2 _5925 = floor(_5923);
            float2 _5928 = _5923 - _5925;
            int _5931 = int(_5925.x);
            int _5934 = int(_5925.y);
            int _7920;
            if (_5931 < 0)
            {
                _7920 = _5931 + _1289[_5837].z;
            }
            else
            {
                _7920 = _5931;
            }
            int _7921;
            if (_7920 >= _1289[_5837].z)
            {
                _7921 = _7920 - _1289[_5837].z;
            }
            else
            {
                _7921 = _7920;
            }
            int _5954 = _7921 + 1;
            int _8375 = (_5954 == _1289[_5837].z) ? 0 : _5954;
            int _5969 = min((_5934 + 1), (_1289[_5837].w - 1));
            int _5971 = max(_5934, 0);
            float3 _6024 = float3(_5928.x);
            int _5844 = _5837 + 1;
            float2 _6056 = (_5902 * float2(_1289[_5844].zw)) - float2(0.5);
            float2 _6058 = floor(_6056);
            float2 _6061 = _6056 - _6058;
            int _6064 = int(_6058.x);
            int _6067 = int(_6058.y);
            int _7927;
            if (_6064 < 0)
            {
                _7927 = _6064 + _1289[_5844].z;
            }
            else
            {
                _7927 = _6064;
            }
            int _7928;
            if (_7927 >= _1289[_5844].z)
            {
                _7928 = _7927 - _1289[_5844].z;
            }
            else
            {
                _7928 = _7927;
            }
            int _6087 = _7928 + 1;
            int _8376 = (_6087 == _1289[_5844].z) ? 0 : _6087;
            int _6102 = min((_6067 + 1), (_1289[_5844].w - 1));
            int _6104 = max(_6067, 0);
            float3 _6157 = float3(_6061.x);
            float3 _5859 = mix(mix(mix(_1227.read(uint2((_1289[_5837].xy + int2(_7921, _5971))), 0).xyz, _1227.read(uint2((_1289[_5837].xy + int2(_8375, _5971))), 0).xyz, _6024), mix(_1227.read(uint2((_1289[_5837].xy + int2(_7921, _5969))), 0).xyz, _1227.read(uint2((_1289[_5837].xy + int2(_8375, _5969))), 0).xyz, _6024), float3(_5928.y)), mix(mix(_1227.read(uint2((_1289[_5844].xy + int2(_7928, _6104))), 0).xyz, _1227.read(uint2((_1289[_5844].xy + int2(_8376, _6104))), 0).xyz, _6157), mix(_1227.read(uint2((_1289[_5844].xy + int2(_7928, _6102))), 0).xyz, _1227.read(uint2((_1289[_5844].xy + int2(_8376, _6102))), 0).xyz, _6157), float3(_6061.y)), float3(_5834 - float(_5837))) * _192._m29.y;
            _7971 = fast::max(_7917, float3(0.0)) * _192._m29.y;
            _7959 = _5680.xy;
            _7935 = _5859;
        }
        else
        {
            float4 _6175 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * _7861) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);
            float _6177 = _6175.x;
            float3 _6212 = mix(_192._m9.xyz, _192._m8.xyz, float3((_7871.y * 0.5) + 0.5)) * _192._m8.w;
            _7971 = _6212;
            _7959 = (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_6177 * _6177, exp2((-9.27999973297119140625) * _7899)) * _6177) + _6175.y)) + _6175.zw;
            _7935 = mix(mix(_192._m9.xyz, _192._m8.xyz, float3((reflect(-_2350, _7894).y * 0.5) + 0.5)) * _192._m8.w, _6212, float3(_7861));
        }
        bool _2806;
        if (_2396)
        {
            _2806 = _192._m33.z > 0.5;
        }
        else
        {
            _2806 = _2396;
        }
        float3 _7980;
        if (_2806)
        {
            float3 _7956;
            do
            {
                float _6291 = ((_192._m32.x * (1.0 - smoothstep(_192._m33.x * 0.5, _192._m33.x, abs(dot(_192._m31.xyz, in.m_1741) - _192._m31.w)))) * smoothstep(0.5, 0.89999997615814208984375, dot(_2361, _192._m31.xyz))) * (1.0 - smoothstep(_192._m32.y * 0.5, _192._m32.y, _7861));
                if (_6291 <= 0.0)
                {
                    _7956 = _7935;
                    break;
                }
                float4 _6316 = _192._m30 * float4(in.m_1741 + ((_7871 - (_192._m31.xyz * dot(_7871, _192._m31.xyz))) * _192._m32.w), 1.0);
                float2 _6329 = ((float2(_6316.x, -_6316.y) / float2(_6316.w)) * 0.5) + float2(0.5);
                float _6333 = _192._m32.z * _7861;
                float3 _7954;
                float _7955;
                _7955 = 0.0;
                _7954 = float3(0.0);
                for (int _7953 = 0; _7953 < 12; )
                {
                    float _6340 = float(_7953);
                    float _6348 = _6340 * 2.3999631404876708984375;
                    float2 _6360 = _6329 + (float2(cos(_6348) * _192._m33.y, sin(_6348)) * (sqrt((_6340 + 0.5) * 0.083333335816860198974609375) * _6333));
                    float2 _6365 = fast::min(_6360, float2(1.0) - _6360);
                    float _6371 = smoothstep(0.0, 0.039999999105930328369140625, fast::min(_6365.x, _6365.y));
                    float4 _6379 = _2057.sample(_1229, fast::clamp(_6360, float2(0.0), float2(1.0)), level(0.0));
                    float3 _6381 = _6379.xyz;
                    _7955 += (_6379.w * _6371);
                    _7954 += ((_6381 / (float3(1.0) - fast::min(_6381, float3(0.99500000476837158203125)))) * _6371);
                    _7953++;
                    continue;
                }
                _7956 = mix(_7935, (_7954 * float3(0.083333335816860198974609375)) + (_7935 * (1.0 - (_7955 * 0.083333335816860198974609375))), float3(_6291));
                break;
            } while(false);
            _7980 = _7956;
        }
        else
        {
            _7980 = _7935;
        }
        float3 _2826 = (_2618 * _7959.x) + float3(_7959.y);
        float3 _2842 = _8009 + (((((float3(1.0) - _2826) * _2612) * _7971) + (_2826 * _7980)) * _7995);
        float3 _8156;
        if (_192._m13.w > 0.5)
        {
            float2 _6445 = fast::clamp(floor(gl_FragCoord.xy * _192._m12.xy), float2(0.0), _192._m13.xy - float2(1.0));
            uint _6473 = uint((((fast::clamp(floor((log2(fast::max(dot(_192._m11.xyz, in.m_1741) + _192._m11.w, 9.9999999747524270787835121154785e-07)) * _192._m12.z) + _192._m12.w), 0.0, _192._m13.z - 1.0) * _192._m13.y) + _6445.y) * _192._m13.x) + _6445.x);
            uint _6475 = _6473 >> uint(2);
            uint _6477 = _6473 & 3u;
            uint _6481 = _1872._m0[_6475][_6477] & 65535u;
            uint _6483 = _1872._m0[_6475][_6477] >> uint(16);
            float3 _8109;
            _8109 = _2842;
            float3 _2942;
            spvUnsafeArray<float2, 3> _6891;
            spvUnsafeArray<float2, 3> _6892;
            spvUnsafeArray<float2, 3> _7104;
            spvUnsafeArray<float2, 3> _7105;
            for (uint _8012 = _6481; _8012 < (_6481 + _6483); _8109 = _2942, _8012++)
            {
                uint _6489 = _8012 / 3u;
                uint _6502 = (_1893._m0[_6489 >> uint(2)][_6489 & 3u] >> ((_8012 - (_6489 * 3u)) * 10u)) & 1023u;
                float3 _6519 = _1734._m0[_6502].xyz - in.m_1741;
                float _6522 = dot(_6519, _6519);
                float _6526 = _6522 * _1734._m0[_6502].w;
                float _6531 = fast::clamp(1.0 - (_6526 * _6526), 0.0, 1.0);
                float3 _6536 = _6519 * rsqrt(fast::max(_6522, 9.9999999392252902907785028219223e-09));
                float _6554 = fast::clamp((dot(-_6536, _1777._m0[_6502].xyz) * _1769._m0[_6502].w) + _1777._m0[_6502].w, 0.0, 1.0);
                float3 _6567 = _1769._m0[_6502].xyz * ((((_6531 * _6531) * _6554) * _6554) / fast::max(_6522, 9.9999997473787516355514526367188e-05));
                float3 _8107;
                if (_2366)
                {
                    float _8039;
                    do
                    {
                        uint _6603 = uint(_192._m21.z);
                        if (_6502 < _6603)
                        {
                            float _6625 = _192._m26[_6502].z * fast::max((_192._m15[_6502] * float4(in.m_1741, 1.0)).w, 0.0);
                            float4 _6649 = _192._m15[_6502] * float4((in.m_1741 + (_2361 * (_6625 * _192._m25.x))) + (_6536 * (_6625 * _192._m25.y)), 1.0);
                            float _6651 = _6649.w;
                            if (_6651 <= 0.0)
                            {
                                _8039 = 1.0;
                                break;
                            }
                            float3 _6660 = _6649.xyz / float3(_6651);
                            float _6662 = _6660.x;
                            bool _6663 = _6662 < 0.0;
                            bool _6670;
                            if (!_6663)
                            {
                                _6670 = _6662 > 1.0;
                            }
                            else
                            {
                                _6670 = _6663;
                            }
                            bool _6677;
                            if (!_6670)
                            {
                                _6677 = _6660.y < 0.0;
                            }
                            else
                            {
                                _6677 = _6670;
                            }
                            bool _6684;
                            if (!_6677)
                            {
                                _6684 = _6660.y > 1.0;
                            }
                            else
                            {
                                _6684 = _6677;
                            }
                            bool _6691;
                            if (!_6684)
                            {
                                _6691 = _6660.z > 1.0;
                            }
                            else
                            {
                                _6691 = _6684;
                            }
                            if (_6691)
                            {
                                _8039 = 1.0;
                                break;
                            }
                            float _6697 = _6660.z;
                            float2 _6863 = _192._m22.xy * 0.5;
                            float2 _6868 = _192._m26[_6502].xy + (_6660.xy * _192._m23.zw);
                            float4 _6881 = float4(_192._m26[_6502].xy + _6863, (_192._m26[_6502].xy + _192._m23.zw) - _6863);
                            float _8038;
                            do
                            {
                                int _6907 = int(_192._m22.z);
                                if (_6907 <= 0)
                                {
                                    float2 _6917 = fast::clamp(_6868, _6881.xy, _6881.zw);
                                    _8038 = spvDepthCast(_212).sample_compare(_212Smplr, float3(_6917, _6697).xy, _6697);
                                    break;
                                }
                                float2 _6930 = (_6868 / _192._m22.xy) + float2(0.5);
                                float2 _6931 = floor(_6930);
                                float2 _6936 = _6930 - _6931;
                                float2 _6939 = _6931 - float2(0.5);
                                bool _6943 = _6907 == 1;
                                if (_6943)
                                {
                                    float2 _6946 = _6936 * 2.0;
                                    _6891[0] = float2(3.0) - _6946;
                                    _6891[1] = float2(1.0) + _6946;
                                    _6892[0] = ((float2(2.0) - _6936) / _6891[0]) - float2(1.0);
                                    _6892[1] = (_6936 / _6891[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _6973 = _6936 * 3.0;
                                    _6891[0] = float2(4.0) - _6973;
                                    _6891[1] = float2(7.0);
                                    _6891[2] = float2(1.0) + _6973;
                                    _6892[0] = ((float2(3.0) - (_6936 * 2.0)) / _6891[0]) - float2(2.0);
                                    _6892[1] = (float2(3.0) + _6936) / _6891[1];
                                    _6892[2] = (_6936 / _6891[2]) + float2(2.0);
                                }
                                int _8378 = _6943 ? 2 : 3;
                                int _8028;
                                float _8031;
                                _8031 = 0.0;
                                _8028 = 0;
                                float _8037;
                                for (; _8028 < _8378; _8031 = _8037, _8028++)
                                {
                                    _8037 = _8031;
                                    for (int _8034 = 0; _8034 < _8378; )
                                    {
                                        _8037 += ((_6891[_8034].x * _6891[_8028].y) * spvDepthCast(_212).sample_compare(_212Smplr, float3(fast::clamp(_192._m22.xy * (_6939 + float2(_6892[_8034].x, _6892[_8028].y)), _6881.xy, _6881.zw), _6697).xy, _6697));
                                        _8034++;
                                        continue;
                                    }
                                }
                                _8038 = _8031 * (_6943 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _8039 = _8038;
                            break;
                        }
                        uint _6707 = _6502 - _6603;
                        if (_6707 >= uint(_192._m21.w))
                        {
                            _8039 = 1.0;
                            break;
                        }
                        float _6728 = _192._m27[_6707].w * length(in.m_1741 - _192._m27[_6707].xyz);
                        float3 _6746 = ((in.m_1741 + (_2361 * (_6728 * _192._m25.x))) + (_6536 * (_6728 * _192._m25.y))) - _192._m27[_6707].xyz;
                        float3 _6748 = abs(_6746);
                        float _6750 = _6748.x;
                        float _6752 = _6748.y;
                        bool _6753 = _6750 >= _6752;
                        bool _6761;
                        if (_6753)
                        {
                            _6761 = _6750 >= _6748.z;
                        }
                        else
                        {
                            _6761 = _6753;
                        }
                        float _8013;
                        int _8015;
                        if (_6761)
                        {
                            _8015 = (_6746.x > 0.0) ? 0 : 1;
                            _8013 = _6750;
                        }
                        else
                        {
                            float _6773 = _6748.z;
                            bool _6774 = _6752 >= _6773;
                            int _8016;
                            if (_6774)
                            {
                                _8016 = (_6746.y > 0.0) ? 2 : 3;
                            }
                            else
                            {
                                _8016 = (_6746.z > 0.0) ? 4 : 5;
                            }
                            _8015 = _8016;
                            _8013 = _6774 ? _6752 : _6773;
                        }
                        if (_8013 <= 0.0)
                        {
                            _8039 = 1.0;
                            break;
                        }
                        float2 _6811 = float2(dot(_6746, _870[_8015]), dot(_6746, _879[_8015])) / float2(_8013 * _192._m24.z);
                        float _6818 = _192._m28[_6707].z + (_192._m28[_6707].w / _8013);
                        if (_6818 > 1.0)
                        {
                            _8039 = 1.0;
                            break;
                        }
                        float2 _6836 = _192._m28[_6707].xy + (float2(float(spvSMod(_8015, 3)), float(_8015 / 3)) * _192._m24.xy);
                        float2 _7076 = _192._m22.xy * 0.5;
                        float2 _7081 = _6836 + (float2(0.5 + (0.5 * _6811.x), 0.5 - (0.5 * _6811.y)) * _192._m24.xy);
                        float4 _7094 = float4(_6836 + _7076, (_6836 + _192._m24.xy) - _7076);
                        float _8027;
                        do
                        {
                            int _7120 = int(_192._m22.z);
                            if (_7120 <= 0)
                            {
                                _8027 = spvDepthCast(_212).sample_compare(_212Smplr, float3(fast::clamp(_7081, _7094.xy, _7094.zw), _6818).xy, _6818);
                                break;
                            }
                            float2 _7143 = (_7081 / _192._m22.xy) + float2(0.5);
                            float2 _7144 = floor(_7143);
                            float2 _7149 = _7143 - _7144;
                            float2 _7152 = _7144 - float2(0.5);
                            bool _7156 = _7120 == 1;
                            if (_7156)
                            {
                                float2 _7159 = _7149 * 2.0;
                                _7104[0] = float2(3.0) - _7159;
                                _7104[1] = float2(1.0) + _7159;
                                _7105[0] = ((float2(2.0) - _7149) / _7104[0]) - float2(1.0);
                                _7105[1] = (_7149 / _7104[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _7186 = _7149 * 3.0;
                                _7104[0] = float2(4.0) - _7186;
                                _7104[1] = float2(7.0);
                                _7104[2] = float2(1.0) + _7186;
                                _7105[0] = ((float2(3.0) - (_7149 * 2.0)) / _7104[0]) - float2(2.0);
                                _7105[1] = (float2(3.0) + _7149) / _7104[1];
                                _7105[2] = (_7149 / _7104[2]) + float2(2.0);
                            }
                            int _8381 = _7156 ? 2 : 3;
                            int _8017;
                            float _8020;
                            _8020 = 0.0;
                            _8017 = 0;
                            float _8026;
                            for (; _8017 < _8381; _8020 = _8026, _8017++)
                            {
                                _8026 = _8020;
                                for (int _8023 = 0; _8023 < _8381; )
                                {
                                    _8026 += ((_7104[_8023].x * _7104[_8017].y) * spvDepthCast(_212).sample_compare(_212Smplr, float3(fast::clamp(_192._m22.xy * (_7152 + float2(_7105[_8023].x, _7105[_8017].y)), _7094.xy, _7094.zw), _6818).xy, _6818));
                                    _8023++;
                                    continue;
                                }
                            }
                            _8027 = _8020 * (_7156 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _8039 = _8027;
                        break;
                    } while(false);
                    _8107 = _6567 * _8039;
                }
                else
                {
                    _8107 = _6567;
                }
                float3 _2894 = fast::normalize(_6536 + _2350);
                float _2899 = fast::clamp(dot(_7871, _6536), 0.0, 1.0);
                float _2904 = fast::clamp(dot(_7871, _2894), 0.0, 1.0);
                float3 _7291 = _2618 + (_5606 * powr(1.0 - fast::clamp(dot(_2350, _2894), 0.0, 1.0), 5.0));
                float _7305 = ((_2904 * _2904) * _5621) + 1.0;
                _2942 = _8109 + (((((float3(1.0) - _7291) * _2612) + ((_7291 * ((_5616 / ((3.1415927410125732421875 * _7305) * _7305)) * (0.5 / fast::max((_2899 * _5647) + (_7899 * sqrt(((_2899 * _2899) * _5643) + _5616)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875)) * _2899) * _8107);
            }
            _8156 = _8109;
        }
        else
        {
            _8156 = _2842;
        }
        _8153 = _8156;
    }
    float4 _2959 = _2954.sample(_1229, _2124);
    float _2977 = -length(_2349);
    float _8198;
    if (_192._m9.w != 0.0)
    {
        float _3001 = _192._m9.w * (in.m_1741 - _192._m6.xyz).y;
        float _8195;
        if (abs(_3001) < 9.9999997473787516355514526367188e-05)
        {
            _8195 = 1.0 - (0.5 * _3001);
        }
        else
        {
            _8195 = (1.0 - exp(fast::min(-_3001, 60.0))) / _3001;
        }
        _8198 = 1.0 - exp((_2977 * (_192._m7.w * exp(fast::min((-_192._m9.w) * (_192._m6.y - _192._m6.w), 30.0)))) * _8195);
    }
    else
    {
        _8198 = 1.0 - exp(_2977 * _192._m7.w);
    }
    float3 _3052 = mix(mix(_8153, _7865, float3(_1579._m1.y)) + ((_1579._m5.xyz * _2959.xyz) * (float3(1.0) + in.m_2363.yzw)), _192._m7.xyz, float3(_8198));
    float3 _8199;
    if (_192._m33.w > 0.5)
    {
        _8199 = _3052 / (float3(1.0) + _3052);
    }
    else
    {
        _8199 = _3052;
    }
    out.m_3064 = float4(_8199, (in.m_2133.w * _1579._m0.w) * _2131.w);
    float2 _8200;
    do
    {
        if (in.m_3074.w <= 0.0)
        {
            _8200 = float2(0.0);
            break;
        }
        _8200 = ((in.m_3074.xy / float2(in.m_3074.w)) - (in.m_3073.xy / float2(in.m_3073.w))) * float2(0.5, -0.5);
        break;
    } while(false);
    out.m_3072 = _8200;
    return out;
}

