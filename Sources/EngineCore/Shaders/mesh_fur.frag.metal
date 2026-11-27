// Generated from mesh_fur.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 449e9296fb71c82b
// glsl-fnv1a64: bb19ffbedd20c8f5

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

struct _161
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

struct _875
{
    float4 _m0[1024];
};

struct _911
{
    float4 _m0[1024];
};

struct _919
{
    float4 _m0[1024];
};

struct _1016
{
    uint4 _m0[1024];
};

struct _1039
{
    uint4 _m0[1024];
};

struct _1142
{
    float4 _m0[8];
    float4 _m1[8];
};

constant float _7468 = {};

constant spvUnsafeArray<float3, 6> _633 = spvUnsafeArray<float3, 6>({ float3(0.0, 0.0, 1.0), float3(0.0, 0.0, -1.0), float3(-1.0, 0.0, 0.0), float3(-1.0, 0.0, 0.0), float3(-1.0, 0.0, 0.0), float3(1.0, 0.0, 0.0) });
constant spvUnsafeArray<float3, 6> _642 = spvUnsafeArray<float3, 6>({ float3(0.0, 1.0, 0.0), float3(0.0, 1.0, 0.0), float3(0.0, 0.0, -1.0), float3(0.0, 0.0, 1.0), float3(0.0, 1.0, 0.0), float3(0.0, 1.0, 0.0) });
constant spvUnsafeArray<float3, 4> _2058 = spvUnsafeArray<float3, 4>({ float3(1.0, 0.449999988079071044921875, 0.449999988079071044921875), float3(0.449999988079071044921875, 1.0, 0.449999988079071044921875), float3(0.5, 0.60000002384185791015625, 1.0), float3(1.0, 1.0, 0.4000000059604644775390625) });

struct fragment_main_out
{
    float4 m_2587 [[color(0)]];
    float2 m_2595 [[color(1)]];
};

struct fragment_main_in
{
    float3 m_885 [[user(locn0)]];
    float3 m_2269 [[user(locn1)]];
    float2 m_1164 [[user(locn2)]];
    float4 m_2194 [[user(locn3)]];
    float3 m_1185 [[user(locn4)]];
    float4 m_2301 [[user(locn5)]];
    float4 m_2596 [[user(locn6)]];
    float4 m_2597 [[user(locn7)]];
    float4 m_1127 [[user(locn8)]];
    float3 m_2285 [[user(locn9)]];
    float3 m_1207 [[user(locn10)]];
};

fragment fragment_main_out fragment_main(fragment_main_in in [[stage_in]], constant _1142& _1144 [[buffer(2)]], constant _875& _877 [[buffer(3)]], constant _911& _913 [[buffer(4)]], constant _919& _921 [[buffer(5)]], constant _1016& _1018 [[buffer(6)]], constant _1039& _1041 [[buffer(7)]], constant _161& _163 [[buffer(15)]], texture2d<float> _183 [[texture(0)]], texture2d<float> _1159 [[texture(2)]], texture2d<float> _839 [[texture(6)]], sampler _183Smplr [[sampler(0)]], sampler _843 [[sampler(1)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])
{
    fragment_main_out out = {};
    bool _2136 = in.m_1127.z > 0.5;
    bool _2140 = in.m_1127.w > 0.5;
    bool _6937;
    float _6938;
    float _6947;
    float _6956;
    float _6965;
    do
    {
        float _6935;
        if (_1144._m1[6].z > 0.5)
        {
            float4 _2718 = _1159.sample(_843, in.m_1164);
            float _2719 = _2718.x;
            float _6936;
            if (_1144._m1[6].w > 0.5)
            {
                _6936 = 1.0 - _2719;
            }
            else
            {
                _6936 = _2719;
            }
            _6935 = _6936;
        }
        else
        {
            _6935 = 1.0;
        }
        float _6945;
        float _6954;
        float _6963;
        float _6972;
        if (_2140)
        {
            if (_6935 < 0.0199999995529651641845703125)
            {
                _6965 = 0.0;
                _6956 = 1.0;
                _6947 = 0.5;
                _6938 = 0.0;
                _6937 = false;
                break;
            }
            uint3 _3047 = uint3(int3(floor(in.m_1185 / float3(fast::max(_1144._m1[0].y, 9.9999997473787516355514526367188e-06)))) + int3(1048576));
            uint _3058 = ((_3047.x * 1597334677u) ^ (_3047.y * 3812015801u)) ^ (_3047.z * 2798796415u);
            uint _3064 = (_3058 ^ (_3058 >> uint(15))) * 2246822519u;
            uint _3070 = (_3064 ^ (_3064 >> uint(13))) * 3266489917u;
            uint _3076 = (_3070 ^ (_3070 >> uint(16))) * 668265263u;
            _6972 = 0.0;
            _6963 = 1.0;
            _6954 = (float3(_7468, _7468, float((_3076 ^ (_3076 >> uint(15))) & 65535u)) * float3(1.525902189314365386962890625e-05)).z;
            _6945 = 0.0;
        }
        else
        {
            float _6946;
            float _6955;
            float _6964;
            float _6973;
            if (!_2136)
            {
                float _2749 = fast::max(_1144._m1[0].y, 9.9999997473787516355514526367188e-06);
                float3 _2751 = fast::normalize(in.m_1207);
                float3 _6923;
                float _6971;
                if (_1144._m1[1].x > 0.0)
                {
                    float _2758 = _2749 * 4.0;
                    float3 _2763 = floor(in.m_1185 / float3(_2758));
                    uint3 _3102 = uint3(int3(_2763 + float3(31.0, 17.0, 5.0)) + int3(1048576));
                    uint _3113 = ((_3102.x * 1597334677u) ^ (_3102.y * 3812015801u)) ^ (_3102.z * 2798796415u);
                    uint _3119 = (_3113 ^ (_3113 >> uint(15))) * 2246822519u;
                    uint _3123 = _3119 ^ (_3119 >> uint(13));
                    uint _3125 = _3123 * 3266489917u;
                    uint _3129 = _3125 ^ (_3125 >> uint(16));
                    uint _3131 = _3129 * 668265263u;
                    float3 _2775 = ((_2763 + float3(0.5)) + (((float3(float(_3123 & 65535u), float(_3129 & 65535u), float((_3131 ^ (_3131 >> uint(15))) & 65535u)) * float3(1.525902189314365386962890625e-05)) - float3(0.5)) * 0.60000002384185791015625)) * _2758;
                    float3 _2784 = _2775 - (_2751 * dot(_2775 - in.m_1185, _2751));
                    float3 _2789 = in.m_1185 - _2784;
                    _6971 = _1144._m1[1].x * smoothstep(0.1500000059604644775390625, 0.60000002384185791015625, length(_2789) / _2758);
                    _6923 = _2784 + (_2789 / float3(1.0 - fast::min((_1144._m1[1].x * in.m_1127.x) * 0.85000002384185791015625, 0.89999997615814208984375)));
                }
                else
                {
                    _6971 = 0.0;
                    _6923 = in.m_1185;
                }
                float3 _2815 = floor(_6923 / float3(_2749));
                uint3 _3157 = uint3(int3(_2815) + int3(1048576));
                uint _3168 = ((_3157.x * 1597334677u) ^ (_3157.y * 3812015801u)) ^ (_3157.z * 2798796415u);
                uint _3174 = (_3168 ^ (_3168 >> uint(15))) * 2246822519u;
                uint _3178 = _3174 ^ (_3174 >> uint(13));
                uint _3180 = _3178 * 3266489917u;
                uint _3184 = _3180 ^ (_3180 >> uint(16));
                uint _3186 = _3184 * 668265263u;
                float3 _3202 = float3(float(_3178 & 65535u), float(_3184 & 65535u), float((_3186 ^ (_3186 >> uint(15))) & 65535u)) * float3(1.525902189314365386962890625e-05);
                float3 _2827 = ((_2815 + float3(0.5)) + ((_3202 - float3(0.5)) * 0.5)) * _2749;
                float3 _6924;
                if (abs(_2751.y) < 0.89999997615814208984375)
                {
                    _6924 = cross(_2751, float3(0.0, 1.0, 0.0));
                }
                else
                {
                    _6924 = cross(_2751, float3(1.0, 0.0, 0.0));
                }
                float3 _2840 = fast::normalize(_6924);
                float3 _6926;
                if (_1144._m1[1].y > 0.0)
                {
                    float _2853 = (in.m_1127.x * 12.5659999847412109375) + (_3202.x * 6.28299999237060546875);
                    _6926 = _2827 + (((_2840 * cos(_2853)) + (cross(_2751, _2840) * sin(_2853))) * ((_1144._m1[1].y * 0.300000011920928955078125) * _2749));
                }
                else
                {
                    _6926 = _2827;
                }
                float3 _6930;
                if (_1144._m1[1].z > 0.0)
                {
                    float _2877 = in.m_1127.x * 4.0;
                    float _2881 = floor(_2877) * 7.0;
                    uint3 _3212 = uint3(int3(_2815 + float3(_2881, 3.0, 11.0)) + int3(1048576));
                    uint _3223 = ((_3212.x * 1597334677u) ^ (_3212.y * 3812015801u)) ^ (_3212.z * 2798796415u);
                    uint _3229 = (_3223 ^ (_3223 >> uint(15))) * 2246822519u;
                    uint _3233 = _3229 ^ (_3229 >> uint(13));
                    uint _3235 = _3233 * 3266489917u;
                    uint _3239 = _3235 ^ (_3235 >> uint(16));
                    uint _3241 = _3239 * 668265263u;
                    uint3 _3267 = uint3(int3(_2815 + float3(_2881 + 7.0, 3.0, 11.0)) + int3(1048576));
                    uint _3278 = ((_3267.x * 1597334677u) ^ (_3267.y * 3812015801u)) ^ (_3267.z * 2798796415u);
                    uint _3284 = (_3278 ^ (_3278 >> uint(15))) * 2246822519u;
                    uint _3288 = _3284 ^ (_3284 >> uint(13));
                    uint _3290 = _3288 * 3266489917u;
                    uint _3294 = _3290 ^ (_3290 >> uint(16));
                    uint _3296 = _3294 * 668265263u;
                    _6930 = _6926 + ((mix(float3(float(_3233 & 65535u), float(_3239 & 65535u), float((_3241 ^ (_3241 >> uint(15))) & 65535u)) * float3(1.525902189314365386962890625e-05), float3(float(_3288 & 65535u), float(_3294 & 65535u), float((_3296 ^ (_3296 >> uint(15))) & 65535u)) * float3(1.525902189314365386962890625e-05), float3(smoothstep(0.0, 1.0, fract(_2877)))) - float3(0.5)) * (((_1144._m1[1].z * 0.4000000059604644775390625) * _2749) * in.m_1127.x));
                }
                else
                {
                    _6930 = _6926;
                }
                float3 _2915 = _6923 - _6930;
                float3 _2922 = _2915 - (_2751 * dot(_2915, _2751));
                float _2931 = (1.0 - (_1144._m1[2].y * _3202.y)) * fast::min(_6935, 1.0);
                if (in.m_1127.x > _2931)
                {
                    _6965 = _6971;
                    _6956 = 1.0;
                    _6947 = 0.5;
                    _6938 = 0.0;
                    _6937 = false;
                    break;
                }
                float _2944 = in.m_1127.x / fast::max(_2931, 0.001000000047497451305389404296875);
                float _2948 = (mix(_1144._m1[0].z, _1144._m1[0].w, _2944) * 0.5) * _2749;
                if (dot(_2922, _2922) > (_2948 * _2948))
                {
                    _6965 = _6971;
                    _6956 = 1.0;
                    _6947 = 0.5;
                    _6938 = 0.0;
                    _6937 = false;
                    break;
                }
                _6973 = _6971;
                _6964 = 1.0;
                _6955 = _3202.z;
                _6946 = _2944;
            }
            else
            {
                float _2973 = in.m_1164.x * fast::max(_1144._m1[4].w, 1.0);
                uint3 _3322 = uint3(int3(float3(floor(_2973), floor(in.m_1127.y * 65535.0), 7.0)) + int3(1048576));
                uint _3333 = ((_3322.x * 1597334677u) ^ (_3322.y * 3812015801u)) ^ (_3322.z * 2798796415u);
                uint _3339 = (_3333 ^ (_3333 >> uint(15))) * 2246822519u;
                uint _3343 = _3339 ^ (_3339 >> uint(13));
                uint _3345 = _3343 * 3266489917u;
                uint _3349 = _3345 ^ (_3345 >> uint(16));
                uint _3351 = _3349 * 668265263u;
                float3 _3367 = float3(float(_3343 & 65535u), float(_3349 & 65535u), float((_3351 ^ (_3351 >> uint(15))) & 65535u)) * float3(1.525902189314365386962890625e-05);
                float _2997 = 1.0 - (_1144._m1[2].y * _3367.y);
                if (in.m_1127.x > _2997)
                {
                    _6965 = 0.0;
                    _6956 = 1.0;
                    _6947 = 0.5;
                    _6938 = 0.0;
                    _6937 = false;
                    break;
                }
                float _3006 = in.m_1127.x / fast::max(_2997, 0.001000000047497451305389404296875);
                float _3012 = mix(_1144._m1[0].z, _1144._m1[0].w, _3006);
                float _3027 = (1.0 - smoothstep(_3012 * 0.2750000059604644775390625, _3012 * 0.5, abs((fract(_2973) - 0.5) + ((_3367.x - 0.5) * 0.300000011920928955078125)))) * (1.0 - smoothstep(0.85000002384185791015625, 1.0, _3006));
                if (_3027 < 0.02999999932944774627685546875)
                {
                    _6965 = 0.0;
                    _6956 = _3027;
                    _6947 = 0.5;
                    _6938 = _3006;
                    _6937 = false;
                    break;
                }
                _6973 = 0.0;
                _6964 = _3027;
                _6955 = _3367.z;
                _6946 = _3006;
            }
            _6972 = _6973;
            _6963 = _6964;
            _6954 = _6955;
            _6945 = _6946;
        }
        _6965 = _6972;
        _6956 = _6963;
        _6947 = _6954;
        _6938 = _6945;
        _6937 = true;
        break;
    } while(false);
    if (!_6937)
    {
        discard_fragment();
    }
    float _2178 = _6947 - 0.5;
    float3 _2197 = (mix(_1144._m1[3].xyz, _1144._m1[4].xyz, float3(powr(_6938, 0.800000011920928955078125))) * fast::max(1.0 + ((_2178 * 2.0) * _1144._m1[2].z), 0.0)) * in.m_2194.xyz;
    float _6974;
    if (_2136)
    {
        _6974 = 3.0;
    }
    else
    {
        _6974 = ((_1144._m1[0].x * (_1144._m1[0].z + _1144._m1[0].w)) * 0.5) / fast::max(_1144._m1[0].y, 9.9999997473787516355514526367188e-06);
    }
    float _2229 = 1.0 - exp((_6974 * (1.0 - (0.60000002384185791015625 * _6965))) * (-0.20000000298023223876953125));
    float _6975;
    if (_2140)
    {
        _6975 = 1.0;
    }
    else
    {
        _6975 = 1.0 - (_2136 ? _6938 : in.m_1127.x);
    }
    float _2260 = fast::max(mix(exp((_2229 * (-2.5)) * _6975), 1.0, 0.300000011920928955078125 * sqrt(fast::clamp(dot(_2197, float3(0.2125999927520751953125, 0.715200006961822509765625, 0.072200000286102294921875)), 0.0, 1.0))), 0.119999997317790985107421875);
    float _7246;
    if (_2136)
    {
        _7246 = _2260 * mix(0.85000002384185791015625, 1.0, _6947);
    }
    else
    {
        _7246 = _2260;
    }
    float3 _2271 = fast::normalize(in.m_2269);
    bool _2279;
    if (_2136)
    {
        _2279 = !gl_FrontFacing;
    }
    else
    {
        _2279 = _2136;
    }
    float3 _6979;
    if (_2279)
    {
        _6979 = -_2271;
    }
    else
    {
        _6979 = _2271;
    }
    float3 _2287 = fast::normalize(in.m_2285);
    float3 _2292 = fast::normalize(_163._m4.xyz);
    float3 _2298 = _163._m6.xyz - in.m_885;
    float3 _2299 = fast::normalize(_2298);
    bool _2304 = in.m_2301.x > 0.5;
    float _2314 = fast::clamp((_1144._m1[0].x * 2.0) / fast::max(5.0 * _2229, 1.0), 0.0040000001899898052215576171875, 0.0599999986588954925537109375);
    float3 _7238;
    float _7239;
    if ((_163._m5.w > 0.5) && _2304)
    {
        float _7119;
        float3 _7120;
        do
        {
            int _3390 = int(_163._m21.x);
            float _3398 = dot(_163._m20.xyz, in.m_885) + _163._m20.w;
            int _6980;
            _6980 = 0;
            for (;;)
            {
                bool _3404 = _6980 < (_3390 - 1);
                bool _3412;
                if (_3404)
                {
                    _3412 = _3398 > _163._m16[_6980];
                }
                else
                {
                    _3412 = _3404;
                }
                if (_3412)
                {
                    _6980++;
                    continue;
                }
                else
                {
                    break;
                }
            }
            if (_3398 > _163._m16[_6980])
            {
                _7120 = float3(1.0);
                _7119 = 1.0;
                break;
            }
            float _7023;
            do
            {
                float4 _3530 = _163._m14[_6980] * float4(in.m_885 + (_6979 * _163._m18[_6980]), 1.0);
                float _3533 = _3530.x;
                bool _3534 = _3533 < 0.0;
                bool _3541;
                if (!_3534)
                {
                    _3541 = _3533 > 1.0;
                }
                else
                {
                    _3541 = _3534;
                }
                bool _3548;
                if (!_3541)
                {
                    _3548 = _3530.y < 0.0;
                }
                else
                {
                    _3548 = _3541;
                }
                bool _3555;
                if (!_3548)
                {
                    _3555 = _3530.y > 1.0;
                }
                else
                {
                    _3555 = _3548;
                }
                if (_3555)
                {
                    _7023 = 1.0;
                    break;
                }
                int _3681;
                bool _3683;
                float2 _3568 = float2(float(_6980 & 1), float(_6980 >> 1)) * _163._m23.xy;
                float _3575 = fast::min(_3530.z, 1.0) - _163._m19[_6980];
                float _3586 = _2314 * length(float3(_163._m14[_6980][0].z, _163._m14[_6980][1].z, _163._m14[_6980][2].z));
                float _3590 = _3575 - (_3586 * 0.180000007152557373046875);
                float2 _3637 = _163._m22.xy * 0.5;
                float2 _3642 = _3568 + (_3530.xy * _163._m23.xy);
                float4 _3655 = float4(_3568 + _3637, (_3568 + _163._m23.xy) - _3637);
                float _6992;
                do
                {
                    _3681 = int(_163._m22.z);
                    _3683 = _3681 <= 0;
                    if (_3683)
                    {
                        _6992 = spvDepthCast(_183).sample_compare(_183Smplr, float3(fast::clamp(_3642, _3655.xy, _3655.zw), _3590).xy, _3590);
                        break;
                    }
                    float2 _3704 = (_3642 / _163._m22.xy) + float2(0.5);
                    float2 _3705 = floor(_3704);
                    float2 _3710 = _3704 - _3705;
                    float2 _3713 = _3705 - float2(0.5);
                    bool _3717 = _3681 == 1;
                    spvUnsafeArray<float2, 3> _3665;
                    spvUnsafeArray<float2, 3> _3666;
                    if (_3717)
                    {
                        float2 _3720 = _3710 * 2.0;
                        _3665[0] = float2(3.0) - _3720;
                        _3665[1] = float2(1.0) + _3720;
                        _3666[0] = ((float2(2.0) - _3710) / _3665[0]) - float2(1.0);
                        _3666[1] = (_3710 / _3665[1]) + float2(1.0);
                    }
                    else
                    {
                        float2 _3747 = _3710 * 3.0;
                        _3665[0] = float2(4.0) - _3747;
                        _3665[1] = float2(7.0);
                        _3665[2] = float2(1.0) + _3747;
                        _3666[0] = ((float2(3.0) - (_3710 * 2.0)) / _3665[0]) - float2(2.0);
                        _3666[1] = (float2(3.0) + _3710) / _3665[1];
                        _3666[2] = (_3710 / _3665[2]) + float2(2.0);
                    }
                    int _7470 = _3717 ? 2 : 3;
                    int _6982;
                    float _6985;
                    _6985 = 0.0;
                    _6982 = 0;
                    float _6991;
                    for (; _6982 < _7470; _6985 = _6991, _6982++)
                    {
                        _6991 = _6985;
                        for (int _6988 = 0; _6988 < _7470; )
                        {
                            _6991 += ((_3665[_6988].x * _3665[_6982].y) * spvDepthCast(_183).sample_compare(_183Smplr, float3(fast::clamp(_163._m22.xy * (_3713 + float2(_3666[_6988].x, _3666[_6982].y)), _3655.xy, _3655.zw), _3590).xy, _3590));
                            _6988++;
                            continue;
                        }
                    }
                    _6992 = _6985 * (_3717 ? 0.0625 : 0.0069444444961845874786376953125);
                    break;
                } while(false);
                float _3601 = _3575 - (_3586 * 0.689999997615814208984375);
                float _7003;
                do
                {
                    if (_3683)
                    {
                        _7003 = spvDepthCast(_183).sample_compare(_183Smplr, float3(fast::clamp(_3642, _3655.xy, _3655.zw), _3601).xy, _3601);
                        break;
                    }
                    float2 _3917 = (_3642 / _163._m22.xy) + float2(0.5);
                    float2 _3918 = floor(_3917);
                    float2 _3923 = _3917 - _3918;
                    float2 _3926 = _3918 - float2(0.5);
                    bool _3930 = _3681 == 1;
                    spvUnsafeArray<float2, 3> _3878;
                    spvUnsafeArray<float2, 3> _3879;
                    if (_3930)
                    {
                        float2 _3933 = _3923 * 2.0;
                        _3878[0] = float2(3.0) - _3933;
                        _3878[1] = float2(1.0) + _3933;
                        _3879[0] = ((float2(2.0) - _3923) / _3878[0]) - float2(1.0);
                        _3879[1] = (_3923 / _3878[1]) + float2(1.0);
                    }
                    else
                    {
                        float2 _3960 = _3923 * 3.0;
                        _3878[0] = float2(4.0) - _3960;
                        _3878[1] = float2(7.0);
                        _3878[2] = float2(1.0) + _3960;
                        _3879[0] = ((float2(3.0) - (_3923 * 2.0)) / _3878[0]) - float2(2.0);
                        _3879[1] = (float2(3.0) + _3923) / _3878[1];
                        _3879[2] = (_3923 / _3878[2]) + float2(2.0);
                    }
                    int _7472 = _3930 ? 2 : 3;
                    int _6993;
                    float _6996;
                    _6996 = 0.0;
                    _6993 = 0;
                    float _7002;
                    for (; _6993 < _7472; _6996 = _7002, _6993++)
                    {
                        _7002 = _6996;
                        for (int _6999 = 0; _6999 < _7472; )
                        {
                            _7002 += ((_3878[_6999].x * _3878[_6993].y) * spvDepthCast(_183).sample_compare(_183Smplr, float3(fast::clamp(_163._m22.xy * (_3926 + float2(_3879[_6999].x, _3879[_6993].y)), _3655.xy, _3655.zw), _3601).xy, _3601));
                            _6999++;
                            continue;
                        }
                    }
                    _7003 = _6996 * (_3930 ? 0.0625 : 0.0069444444961845874786376953125);
                    break;
                } while(false);
                float _3614 = _3575 - (_3586 * 1.78999996185302734375);
                float _7018;
                do
                {
                    if (_3683)
                    {
                        _7018 = spvDepthCast(_183).sample_compare(_183Smplr, float3(fast::clamp(_3642, _3655.xy, _3655.zw), _3614).xy, _3614);
                        break;
                    }
                    float2 _4130 = (_3642 / _163._m22.xy) + float2(0.5);
                    float2 _4131 = floor(_4130);
                    float2 _4136 = _4130 - _4131;
                    float2 _4139 = _4131 - float2(0.5);
                    bool _4143 = _3681 == 1;
                    spvUnsafeArray<float2, 3> _4091;
                    spvUnsafeArray<float2, 3> _4092;
                    if (_4143)
                    {
                        float2 _4146 = _4136 * 2.0;
                        _4091[0] = float2(3.0) - _4146;
                        _4091[1] = float2(1.0) + _4146;
                        _4092[0] = ((float2(2.0) - _4136) / _4091[0]) - float2(1.0);
                        _4092[1] = (_4136 / _4091[1]) + float2(1.0);
                    }
                    else
                    {
                        float2 _4173 = _4136 * 3.0;
                        _4091[0] = float2(4.0) - _4173;
                        _4091[1] = float2(7.0);
                        _4091[2] = float2(1.0) + _4173;
                        _4092[0] = ((float2(3.0) - (_4136 * 2.0)) / _4091[0]) - float2(2.0);
                        _4092[1] = (float2(3.0) + _4136) / _4091[1];
                        _4092[2] = (_4136 / _4091[2]) + float2(2.0);
                    }
                    int _7474 = _4143 ? 2 : 3;
                    int _7008;
                    float _7011;
                    _7011 = 0.0;
                    _7008 = 0;
                    float _7017;
                    for (; _7008 < _7474; _7011 = _7017, _7008++)
                    {
                        _7017 = _7011;
                        for (int _7014 = 0; _7014 < _7474; )
                        {
                            _7017 += ((_4091[_7014].x * _4091[_7008].y) * spvDepthCast(_183).sample_compare(_183Smplr, float3(fast::clamp(_163._m22.xy * (_4139 + float2(_4092[_7014].x, _4092[_7008].y)), _3655.xy, _3655.zw), _3614).xy, _3614));
                            _7014++;
                            continue;
                        }
                    }
                    _7018 = _7011 * (_4143 ? 0.0625 : 0.0069444444961845874786376953125);
                    break;
                } while(false);
                _7023 = ((_6992 + _7003) + _7018) * 0.3333333432674407958984375;
                break;
            } while(false);
            float3 _7114;
            float _7117;
            if (_3398 > _163._m17[_6980])
            {
                float _3453 = (_3398 - _163._m17[_6980]) / (_163._m16[_6980] - _163._m17[_6980]);
                int _3455 = _6980 + 1;
                float3 _7115;
                float _7118;
                if (_3455 < _3390)
                {
                    float _7081;
                    do
                    {
                        float4 _4300 = _163._m14[_3455] * float4(in.m_885 + (_6979 * _163._m18[_3455]), 1.0);
                        float _4303 = _4300.x;
                        bool _4304 = _4303 < 0.0;
                        bool _4311;
                        if (!_4304)
                        {
                            _4311 = _4303 > 1.0;
                        }
                        else
                        {
                            _4311 = _4304;
                        }
                        bool _4318;
                        if (!_4311)
                        {
                            _4318 = _4300.y < 0.0;
                        }
                        else
                        {
                            _4318 = _4311;
                        }
                        bool _4325;
                        if (!_4318)
                        {
                            _4325 = _4300.y > 1.0;
                        }
                        else
                        {
                            _4325 = _4318;
                        }
                        if (_4325)
                        {
                            _7081 = 1.0;
                            break;
                        }
                        int _4451;
                        bool _4453;
                        float2 _4338 = float2(float(_3455 & 1), float(_3455 >> 1)) * _163._m23.xy;
                        float _4345 = fast::min(_4300.z, 1.0) - _163._m19[_3455];
                        float _4356 = _2314 * length(float3(_163._m14[_3455][0].z, _163._m14[_3455][1].z, _163._m14[_3455][2].z));
                        float _4360 = _4345 - (_4356 * 0.180000007152557373046875);
                        float2 _4407 = _163._m22.xy * 0.5;
                        float2 _4412 = _4338 + (_4300.xy * _163._m23.xy);
                        float4 _4425 = float4(_4338 + _4407, (_4338 + _163._m23.xy) - _4407);
                        float _7050;
                        do
                        {
                            _4451 = int(_163._m22.z);
                            _4453 = _4451 <= 0;
                            if (_4453)
                            {
                                _7050 = spvDepthCast(_183).sample_compare(_183Smplr, float3(fast::clamp(_4412, _4425.xy, _4425.zw), _4360).xy, _4360);
                                break;
                            }
                            float2 _4474 = (_4412 / _163._m22.xy) + float2(0.5);
                            float2 _4475 = floor(_4474);
                            float2 _4480 = _4474 - _4475;
                            float2 _4483 = _4475 - float2(0.5);
                            bool _4487 = _4451 == 1;
                            spvUnsafeArray<float2, 3> _4435;
                            spvUnsafeArray<float2, 3> _4436;
                            if (_4487)
                            {
                                float2 _4490 = _4480 * 2.0;
                                _4435[0] = float2(3.0) - _4490;
                                _4435[1] = float2(1.0) + _4490;
                                _4436[0] = ((float2(2.0) - _4480) / _4435[0]) - float2(1.0);
                                _4436[1] = (_4480 / _4435[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _4517 = _4480 * 3.0;
                                _4435[0] = float2(4.0) - _4517;
                                _4435[1] = float2(7.0);
                                _4435[2] = float2(1.0) + _4517;
                                _4436[0] = ((float2(3.0) - (_4480 * 2.0)) / _4435[0]) - float2(2.0);
                                _4436[1] = (float2(3.0) + _4480) / _4435[1];
                                _4436[2] = (_4480 / _4435[2]) + float2(2.0);
                            }
                            int _7476 = _4487 ? 2 : 3;
                            int _7040;
                            float _7043;
                            _7043 = 0.0;
                            _7040 = 0;
                            float _7049;
                            for (; _7040 < _7476; _7043 = _7049, _7040++)
                            {
                                _7049 = _7043;
                                for (int _7046 = 0; _7046 < _7476; )
                                {
                                    _7049 += ((_4435[_7046].x * _4435[_7040].y) * spvDepthCast(_183).sample_compare(_183Smplr, float3(fast::clamp(_163._m22.xy * (_4483 + float2(_4436[_7046].x, _4436[_7040].y)), _4425.xy, _4425.zw), _4360).xy, _4360));
                                    _7046++;
                                    continue;
                                }
                            }
                            _7050 = _7043 * (_4487 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        float _4371 = _4345 - (_4356 * 0.689999997615814208984375);
                        float _7061;
                        do
                        {
                            if (_4453)
                            {
                                _7061 = spvDepthCast(_183).sample_compare(_183Smplr, float3(fast::clamp(_4412, _4425.xy, _4425.zw), _4371).xy, _4371);
                                break;
                            }
                            float2 _4687 = (_4412 / _163._m22.xy) + float2(0.5);
                            float2 _4688 = floor(_4687);
                            float2 _4693 = _4687 - _4688;
                            float2 _4696 = _4688 - float2(0.5);
                            bool _4700 = _4451 == 1;
                            spvUnsafeArray<float2, 3> _4648;
                            spvUnsafeArray<float2, 3> _4649;
                            if (_4700)
                            {
                                float2 _4703 = _4693 * 2.0;
                                _4648[0] = float2(3.0) - _4703;
                                _4648[1] = float2(1.0) + _4703;
                                _4649[0] = ((float2(2.0) - _4693) / _4648[0]) - float2(1.0);
                                _4649[1] = (_4693 / _4648[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _4730 = _4693 * 3.0;
                                _4648[0] = float2(4.0) - _4730;
                                _4648[1] = float2(7.0);
                                _4648[2] = float2(1.0) + _4730;
                                _4649[0] = ((float2(3.0) - (_4693 * 2.0)) / _4648[0]) - float2(2.0);
                                _4649[1] = (float2(3.0) + _4693) / _4648[1];
                                _4649[2] = (_4693 / _4648[2]) + float2(2.0);
                            }
                            int _7478 = _4700 ? 2 : 3;
                            int _7051;
                            float _7054;
                            _7054 = 0.0;
                            _7051 = 0;
                            float _7060;
                            for (; _7051 < _7478; _7054 = _7060, _7051++)
                            {
                                _7060 = _7054;
                                for (int _7057 = 0; _7057 < _7478; )
                                {
                                    _7060 += ((_4648[_7057].x * _4648[_7051].y) * spvDepthCast(_183).sample_compare(_183Smplr, float3(fast::clamp(_163._m22.xy * (_4696 + float2(_4649[_7057].x, _4649[_7051].y)), _4425.xy, _4425.zw), _4371).xy, _4371));
                                    _7057++;
                                    continue;
                                }
                            }
                            _7061 = _7054 * (_4700 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        float _4384 = _4345 - (_4356 * 1.78999996185302734375);
                        float _7076;
                        do
                        {
                            if (_4453)
                            {
                                _7076 = spvDepthCast(_183).sample_compare(_183Smplr, float3(fast::clamp(_4412, _4425.xy, _4425.zw), _4384).xy, _4384);
                                break;
                            }
                            float2 _4900 = (_4412 / _163._m22.xy) + float2(0.5);
                            float2 _4901 = floor(_4900);
                            float2 _4906 = _4900 - _4901;
                            float2 _4909 = _4901 - float2(0.5);
                            bool _4913 = _4451 == 1;
                            spvUnsafeArray<float2, 3> _4861;
                            spvUnsafeArray<float2, 3> _4862;
                            if (_4913)
                            {
                                float2 _4916 = _4906 * 2.0;
                                _4861[0] = float2(3.0) - _4916;
                                _4861[1] = float2(1.0) + _4916;
                                _4862[0] = ((float2(2.0) - _4906) / _4861[0]) - float2(1.0);
                                _4862[1] = (_4906 / _4861[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _4943 = _4906 * 3.0;
                                _4861[0] = float2(4.0) - _4943;
                                _4861[1] = float2(7.0);
                                _4861[2] = float2(1.0) + _4943;
                                _4862[0] = ((float2(3.0) - (_4906 * 2.0)) / _4861[0]) - float2(2.0);
                                _4862[1] = (float2(3.0) + _4906) / _4861[1];
                                _4862[2] = (_4906 / _4861[2]) + float2(2.0);
                            }
                            int _7480 = _4913 ? 2 : 3;
                            int _7066;
                            float _7069;
                            _7069 = 0.0;
                            _7066 = 0;
                            float _7075;
                            for (; _7066 < _7480; _7069 = _7075, _7066++)
                            {
                                _7075 = _7069;
                                for (int _7072 = 0; _7072 < _7480; )
                                {
                                    _7075 += ((_4861[_7072].x * _4861[_7066].y) * spvDepthCast(_183).sample_compare(_183Smplr, float3(fast::clamp(_163._m22.xy * (_4909 + float2(_4862[_7072].x, _4862[_7066].y)), _4425.xy, _4425.zw), _4384).xy, _4384));
                                    _7072++;
                                    continue;
                                }
                            }
                            _7076 = _7069 * (_4913 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _7081 = ((_7050 + _7061) + _7076) * 0.3333333432674407958984375;
                        break;
                    } while(false);
                    _7118 = mix(_7023, _7081, _3453);
                    _7115 = mix(_2058[_6980], _2058[_3455], float3(_3453));
                }
                else
                {
                    _7118 = mix(_7023, 1.0, _3453);
                    _7115 = _2058[_6980];
                }
                _7117 = _7118;
                _7114 = _7115;
            }
            else
            {
                _7117 = _7023;
                _7114 = _2058[_6980];
            }
            _7120 = select(float3(1.0), _7114, bool3(_163._m22.w > 0.5));
            _7119 = _7117;
            break;
        } while(false);
        _7239 = _7119;
        _7238 = _2197 * _7120;
    }
    else
    {
        _7239 = 1.0;
        _7238 = _2197;
    }
    float _2340 = 0.0599999986588954925537109375 + (_2178 * 0.07999999821186065673828125);
    float _2344 = _2136 ? 0.37999999523162841796875 : 0.449999988079071044921875;
    bool _2357 = !_2136;
    float _5076 = fast::clamp(dot(_2287, _2292), -1.0, 1.0);
    float _5080 = fast::clamp(dot(_2287, _2299), -1.0, 1.0);
    float _5082 = asin(_5080);
    float _5089 = fast::max(cos(0.5 * abs(_5082 - asin(_5076))), 0.0500000007450580596923828125);
    float3 _5094 = _2292 - (_2287 * _5076);
    float3 _5099 = _2299 - (_2287 * _5080);
    float _5108 = dot(_5099, _5099);
    float _5112 = dot(_5094, _5099) * rsqrt(fast::max(dot(_5094, _5094) * _5108, 9.9999999747524270787835121154785e-07));
    float _5117 = sqrt(fast::clamp(0.5 + (0.5 * _5112), 0.0, 1.0));
    float _5120 = _2344 * _2344;
    float _5123 = _5076 + _5080;
    float _5128 = 2.0 * _2340;
    float _5129 = _5123 + _5128;
    float _7459 = _5120 * _5120;
    float _5305 = 1.99996149539947509765625 * _7459;
    float _5309 = _5120 * 3.5448734760284423828125;
    float _5317 = 1.0 - fast::clamp(sqrt(fast::clamp(0.5 + (0.5 * dot(_2292, _2299)), 0.0, 1.0)), 0.0, 1.0);
    float _5320 = _5317 * _5317;
    float _5148 = (_5120 * 0.5) + 0.07999999821186065673828125;
    float _5151 = _5123 - _2340;
    float _5336 = _5148 * _5148;
    float _5340 = 2.5066282749176025390625 * _5148;
    float _5159 = _5117 * (1.0 + (0.64516127109527587890625 * (0.60000002384185791015625 - (0.800000011920928955078125 * _5112))));
    float _5163 = _5159 * _5159;
    float _5348 = 1.0 - fast::clamp(_5089 * sqrt(fast::clamp(1.0 - _5163, 0.0, 1.0)), 0.0, 1.0);
    float _5351 = _5348 * _5348;
    float3 _5170 = fast::max(_7238, float3(9.9999997473787516355514526367188e-05));
    float _5190 = 0.9534800052642822265625 - (((0.9534800052642822265625 * _5351) * _5351) * _5348);
    float _5204 = 4.0 * _2340;
    float _5205 = _5123 - _5204;
    float _5367 = 7.999845981597900390625 * _7459;
    float _5371 = _5120 * 7.089746952056884765625;
    float _5379 = 1.0 - fast::clamp(_5089 * 0.5, 0.0, 1.0);
    float _5382 = _5379 * _5379;
    float _5388 = ((0.9534800052642822265625 * _5382) * _5382) * _5379;
    float _5223 = 0.9534800052642822265625 - _5388;
    float _7240;
    if (_2357)
    {
        float _5242 = fast::clamp((dot(_6979, _2292) * 0.60000002384185791015625) + 0.4000000059604644775390625, 0.0, 1.0);
        _7240 = _5242 * _5242;
    }
    else
    {
        _7240 = mix(fast::clamp((dot(_5099 * rsqrt(fast::max(_5108, 9.9999999747524270787835121154785e-07)), _2292) + 1.0) * 0.5, 0.0, 1.0), 1.0 - abs(_5076), 0.3300000131130218505859375);
    }
    float3 _5278 = _5170 / float3(fast::max(dot(_7238, float3(0.2125999927520751953125, 0.715200006961822509765625, 0.072200000286102294921875)), 9.9999997473787516355514526367188e-05));
    float3 _5286 = powr(_5170, float3(0.920000016689300537109375));
    float _5294 = _1144._m1[2].w * 3.1415927410125732421875;
    float3 _5295 = ((float3(((((exp((((-0.5) * _5129) * _5129) / _5305) / _5309) * 0.25) * _5117) * (0.0465199984610080718994140625 + (((0.9534800052642822265625 * _5320) * _5320) * _5317))) * 3.0) + (powr(_5170, float3(sqrt(fast::clamp(1.0 - (_5163 * 0.416233062744140625), 0.0, 1.0)) / _5089)) * ((((exp((((-0.5) * _5151) * _5151) / _5336) / _5340) * exp(((-3.650000095367431640625) * _5112) - 3.980000019073486328125)) * _5190) * _5190))) + ((powr(_5170, float3(0.800000011920928955078125 / _5089)) * (((((exp((((-0.5) * _5205) * _5205) / _5367) / _5371) * exp((17.0 * _5112) - 16.7800006866455078125)) * _5223) * _5223) * (0.0465199984610080718994140625 + _5388))) * 4.0)) * _5294;
    float _2383 = mix(0.5, 1.0, _7246);
    float3 _7288;
    if (_163._m29.x > 0.5)
    {
        float _5447 = (_163._m29.z * _6979.x) - (_163._m29.w * _6979.z);
        float _5460 = (_163._m29.w * _6979.x) + (_163._m29.z * _6979.z);
        float _5478 = 1.09254801273345947265625 * _5447;
        spvUnsafeArray<float, 9> _6795 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _6979.y, 0.48860299587249755859375 * _5460, 0.48860299587249755859375 * _5447, _5478 * _6979.y, (1.09254801273345947265625 * _6979.y) * _5460, 0.3153919875621795654296875 * (((3.0 * _5460) * _5460) - 1.0), _5478 * _5460, 0.546274006366729736328125 * ((_5447 * _5447) - (_6979.y * _6979.y)) });
        spvUnsafeArray<float, 9> _5392 = _6795;
        float3 _7287;
        _7287 = float3(0.0);
        for (int _7286 = 0; _7286 < 9; )
        {
            _7287 += (_839.read(uint2((int2(496, 256) + int2(_7286, 0))), 0).xyz * _5392[_7286]);
            _7286++;
            continue;
        }
        _7288 = fast::max(_7287, float3(0.0)) * _163._m29.y;
    }
    else
    {
        _7288 = mix(_163._m9.xyz, _163._m8.xyz, float3((_6979.y * 0.5) + 0.5)) * _163._m8.w;
    }
    float3 _2406 = ((((((_5286 * powr(_5278, float3((1.0 - _7239) * 0.3499999940395355224609375))) * _7240) + _5295) * (_163._m5.xyz * _163._m4.w)) * _7239) * _2383) + ((_7238 * _7288) * _7246);
    float3 _7299;
    if (_163._m13.w > 0.5)
    {
        float2 _5563 = fast::clamp(floor(gl_FragCoord.xy * _163._m12.xy), float2(0.0), _163._m13.xy - float2(1.0));
        uint _5591 = uint((((fast::clamp(floor((log2(fast::max(dot(_163._m11.xyz, in.m_885) + _163._m11.w, 9.9999999747524270787835121154785e-07)) * _163._m12.z) + _163._m12.w), 0.0, _163._m13.z - 1.0) * _163._m13.y) + _5563.y) * _163._m13.x) + _5563.x);
        uint _5593 = _5591 >> uint(2);
        uint _5595 = _5591 & 3u;
        uint _5599 = _1018._m0[_5593][_5595] & 65535u;
        uint _5601 = _1018._m0[_5593][_5595] >> uint(16);
        float3 _7300;
        _7300 = _2406;
        float3 _2487;
        spvUnsafeArray<float2, 3> _6009;
        spvUnsafeArray<float2, 3> _6010;
        spvUnsafeArray<float2, 3> _6222;
        spvUnsafeArray<float2, 3> _6223;
        for (uint _7296 = _5599; _7296 < (_5599 + _5601); _7300 = _2487, _7296++)
        {
            uint _5607 = _7296 / 3u;
            uint _5620 = (_1041._m0[_5607 >> uint(2)][_5607 & 3u] >> ((_7296 - (_5607 * 3u)) * 10u)) & 1023u;
            float3 _5637 = _877._m0[_5620].xyz - in.m_885;
            float _5640 = dot(_5637, _5637);
            float _5644 = _5640 * _877._m0[_5620].w;
            float _5649 = fast::clamp(1.0 - (_5644 * _5644), 0.0, 1.0);
            float3 _5654 = _5637 * rsqrt(fast::max(_5640, 9.9999999392252902907785028219223e-09));
            float _5672 = fast::clamp((dot(-_5654, _921._m0[_5620].xyz) * _913._m0[_5620].w) + _921._m0[_5620].w, 0.0, 1.0);
            float _7335;
            if (_2304)
            {
                float _7334;
                do
                {
                    uint _5721 = uint(_163._m21.z);
                    if (_5620 < _5721)
                    {
                        float _5743 = _163._m26[_5620].z * fast::max((_163._m15[_5620] * float4(in.m_885, 1.0)).w, 0.0);
                        float4 _5767 = _163._m15[_5620] * float4((in.m_885 + (_6979 * (_5743 * _163._m25.x))) + (_5654 * (_5743 * _163._m25.y)), 1.0);
                        float _5769 = _5767.w;
                        if (_5769 <= 0.0)
                        {
                            _7334 = 1.0;
                            break;
                        }
                        float3 _5778 = _5767.xyz / float3(_5769);
                        float _5780 = _5778.x;
                        bool _5781 = _5780 < 0.0;
                        bool _5788;
                        if (!_5781)
                        {
                            _5788 = _5780 > 1.0;
                        }
                        else
                        {
                            _5788 = _5781;
                        }
                        bool _5795;
                        if (!_5788)
                        {
                            _5795 = _5778.y < 0.0;
                        }
                        else
                        {
                            _5795 = _5788;
                        }
                        bool _5802;
                        if (!_5795)
                        {
                            _5802 = _5778.y > 1.0;
                        }
                        else
                        {
                            _5802 = _5795;
                        }
                        bool _5809;
                        if (!_5802)
                        {
                            _5809 = _5778.z > 1.0;
                        }
                        else
                        {
                            _5809 = _5802;
                        }
                        if (_5809)
                        {
                            _7334 = 1.0;
                            break;
                        }
                        float _5815 = _5778.z;
                        float2 _5981 = _163._m22.xy * 0.5;
                        float2 _5986 = _163._m26[_5620].xy + (_5778.xy * _163._m23.zw);
                        float4 _5999 = float4(_163._m26[_5620].xy + _5981, (_163._m26[_5620].xy + _163._m23.zw) - _5981);
                        float _7333;
                        do
                        {
                            int _6025 = int(_163._m22.z);
                            if (_6025 <= 0)
                            {
                                float2 _6035 = fast::clamp(_5986, _5999.xy, _5999.zw);
                                _7333 = spvDepthCast(_183).sample_compare(_183Smplr, float3(_6035, _5815).xy, _5815);
                                break;
                            }
                            float2 _6048 = (_5986 / _163._m22.xy) + float2(0.5);
                            float2 _6049 = floor(_6048);
                            float2 _6054 = _6048 - _6049;
                            float2 _6057 = _6049 - float2(0.5);
                            bool _6061 = _6025 == 1;
                            if (_6061)
                            {
                                float2 _6064 = _6054 * 2.0;
                                _6009[0] = float2(3.0) - _6064;
                                _6009[1] = float2(1.0) + _6064;
                                _6010[0] = ((float2(2.0) - _6054) / _6009[0]) - float2(1.0);
                                _6010[1] = (_6054 / _6009[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _6091 = _6054 * 3.0;
                                _6009[0] = float2(4.0) - _6091;
                                _6009[1] = float2(7.0);
                                _6009[2] = float2(1.0) + _6091;
                                _6010[0] = ((float2(3.0) - (_6054 * 2.0)) / _6009[0]) - float2(2.0);
                                _6010[1] = (float2(3.0) + _6054) / _6009[1];
                                _6010[2] = (_6054 / _6009[2]) + float2(2.0);
                            }
                            int _7485 = _6061 ? 2 : 3;
                            int _7323;
                            float _7326;
                            _7326 = 0.0;
                            _7323 = 0;
                            float _7332;
                            for (; _7323 < _7485; _7326 = _7332, _7323++)
                            {
                                _7332 = _7326;
                                for (int _7329 = 0; _7329 < _7485; )
                                {
                                    _7332 += ((_6009[_7329].x * _6009[_7323].y) * spvDepthCast(_183).sample_compare(_183Smplr, float3(fast::clamp(_163._m22.xy * (_6057 + float2(_6010[_7329].x, _6010[_7323].y)), _5999.xy, _5999.zw), _5815).xy, _5815));
                                    _7329++;
                                    continue;
                                }
                            }
                            _7333 = _7326 * (_6061 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _7334 = _7333;
                        break;
                    }
                    uint _5825 = _5620 - _5721;
                    if (_5825 >= uint(_163._m21.w))
                    {
                        _7334 = 1.0;
                        break;
                    }
                    float _5846 = _163._m27[_5825].w * length(in.m_885 - _163._m27[_5825].xyz);
                    float3 _5864 = ((in.m_885 + (_6979 * (_5846 * _163._m25.x))) + (_5654 * (_5846 * _163._m25.y))) - _163._m27[_5825].xyz;
                    float3 _5866 = abs(_5864);
                    float _5868 = _5866.x;
                    float _5870 = _5866.y;
                    bool _5871 = _5868 >= _5870;
                    bool _5879;
                    if (_5871)
                    {
                        _5879 = _5868 >= _5866.z;
                    }
                    else
                    {
                        _5879 = _5871;
                    }
                    float _7308;
                    int _7310;
                    if (_5879)
                    {
                        _7310 = (_5864.x > 0.0) ? 0 : 1;
                        _7308 = _5868;
                    }
                    else
                    {
                        float _5891 = _5866.z;
                        bool _5892 = _5870 >= _5891;
                        int _7311;
                        if (_5892)
                        {
                            _7311 = (_5864.y > 0.0) ? 2 : 3;
                        }
                        else
                        {
                            _7311 = (_5864.z > 0.0) ? 4 : 5;
                        }
                        _7310 = _7311;
                        _7308 = _5892 ? _5870 : _5891;
                    }
                    if (_7308 <= 0.0)
                    {
                        _7334 = 1.0;
                        break;
                    }
                    float2 _5929 = float2(dot(_5864, _633[_7310]), dot(_5864, _642[_7310])) / float2(_7308 * _163._m24.z);
                    float _5936 = _163._m28[_5825].z + (_163._m28[_5825].w / _7308);
                    if (_5936 > 1.0)
                    {
                        _7334 = 1.0;
                        break;
                    }
                    float2 _5954 = _163._m28[_5825].xy + (float2(float(spvSMod(_7310, 3)), float(_7310 / 3)) * _163._m24.xy);
                    float2 _6194 = _163._m22.xy * 0.5;
                    float2 _6199 = _5954 + (float2(0.5 + (0.5 * _5929.x), 0.5 - (0.5 * _5929.y)) * _163._m24.xy);
                    float4 _6212 = float4(_5954 + _6194, (_5954 + _163._m24.xy) - _6194);
                    float _7322;
                    do
                    {
                        int _6238 = int(_163._m22.z);
                        if (_6238 <= 0)
                        {
                            _7322 = spvDepthCast(_183).sample_compare(_183Smplr, float3(fast::clamp(_6199, _6212.xy, _6212.zw), _5936).xy, _5936);
                            break;
                        }
                        float2 _6261 = (_6199 / _163._m22.xy) + float2(0.5);
                        float2 _6262 = floor(_6261);
                        float2 _6267 = _6261 - _6262;
                        float2 _6270 = _6262 - float2(0.5);
                        bool _6274 = _6238 == 1;
                        if (_6274)
                        {
                            float2 _6277 = _6267 * 2.0;
                            _6222[0] = float2(3.0) - _6277;
                            _6222[1] = float2(1.0) + _6277;
                            _6223[0] = ((float2(2.0) - _6267) / _6222[0]) - float2(1.0);
                            _6223[1] = (_6267 / _6222[1]) + float2(1.0);
                        }
                        else
                        {
                            float2 _6304 = _6267 * 3.0;
                            _6222[0] = float2(4.0) - _6304;
                            _6222[1] = float2(7.0);
                            _6222[2] = float2(1.0) + _6304;
                            _6223[0] = ((float2(3.0) - (_6267 * 2.0)) / _6222[0]) - float2(2.0);
                            _6223[1] = (float2(3.0) + _6267) / _6222[1];
                            _6223[2] = (_6267 / _6222[2]) + float2(2.0);
                        }
                        int _7488 = _6274 ? 2 : 3;
                        int _7312;
                        float _7315;
                        _7315 = 0.0;
                        _7312 = 0;
                        float _7321;
                        for (; _7312 < _7488; _7315 = _7321, _7312++)
                        {
                            _7321 = _7315;
                            for (int _7318 = 0; _7318 < _7488; )
                            {
                                _7321 += ((_6222[_7318].x * _6222[_7312].y) * spvDepthCast(_183).sample_compare(_183Smplr, float3(fast::clamp(_163._m22.xy * (_6270 + float2(_6223[_7318].x, _6223[_7312].y)), _6212.xy, _6212.zw), _5936).xy, _5936));
                                _7318++;
                                continue;
                            }
                        }
                        _7322 = _7315 * (_6274 ? 0.0625 : 0.0069444444961845874786376953125);
                        break;
                    } while(false);
                    _7334 = _7322;
                    break;
                } while(false);
                _7335 = _7334;
            }
            else
            {
                _7335 = 1.0;
            }
            float _6437 = fast::clamp(dot(_2287, _5654), -1.0, 1.0);
            float _6450 = fast::max(cos(0.5 * abs(_5082 - asin(_6437))), 0.0500000007450580596923828125);
            float3 _6455 = _5654 - (_2287 * _6437);
            float _6473 = dot(_6455, _5099) * rsqrt(fast::max(dot(_6455, _6455) * _5108, 9.9999999747524270787835121154785e-07));
            float _6478 = sqrt(fast::clamp(0.5 + (0.5 * _6473), 0.0, 1.0));
            float _6484 = _6437 + _5080;
            float _6490 = _6484 + _5128;
            float _6678 = 1.0 - fast::clamp(sqrt(fast::clamp(0.5 + (0.5 * dot(_5654, _2299)), 0.0, 1.0)), 0.0, 1.0);
            float _6681 = _6678 * _6678;
            float _6512 = _6484 - _2340;
            float _6520 = _6478 * (1.0 + (0.64516127109527587890625 * (0.60000002384185791015625 - (0.800000011920928955078125 * _6473))));
            float _6524 = _6520 * _6520;
            float _6709 = 1.0 - fast::clamp(_6450 * sqrt(fast::clamp(1.0 - _6524, 0.0, 1.0)), 0.0, 1.0);
            float _6712 = _6709 * _6709;
            float _6551 = 0.9534800052642822265625 - (((0.9534800052642822265625 * _6712) * _6712) * _6709);
            float _6566 = _6484 - _5204;
            float _6740 = 1.0 - fast::clamp(_6450 * 0.5, 0.0, 1.0);
            float _6743 = _6740 * _6740;
            float _6749 = ((0.9534800052642822265625 * _6743) * _6743) * _6740;
            float _6584 = 0.9534800052642822265625 - _6749;
            float _7371;
            if (_2357)
            {
                float _6603 = fast::clamp((dot(_6979, _5654) * 0.60000002384185791015625) + 0.4000000059604644775390625, 0.0, 1.0);
                _7371 = _6603 * _6603;
            }
            else
            {
                _7371 = mix(fast::clamp((dot(_5099 * rsqrt(fast::max(_5108, 9.9999999747524270787835121154785e-07)), _5654) + 1.0) * 0.5, 0.0, 1.0), 1.0 - abs(_6437), 0.3300000131130218505859375);
            }
            float3 _6656 = ((float3(((((exp((((-0.5) * _6490) * _6490) / _5305) / _5309) * 0.25) * _6478) * (0.0465199984610080718994140625 + (((0.9534800052642822265625 * _6681) * _6681) * _6678))) * 3.0) + (powr(_5170, float3(sqrt(fast::clamp(1.0 - (_6524 * 0.416233062744140625), 0.0, 1.0)) / _6450)) * ((((exp((((-0.5) * _6512) * _6512) / _5336) / _5340) * exp(((-3.650000095367431640625) * _6473) - 3.980000019073486328125)) * _6551) * _6551))) + ((powr(_5170, float3(0.800000011920928955078125 / _6450)) * (((((exp((((-0.5) * _6566) * _6566) / _5367) / _5371) * exp((17.0 * _6473) - 16.7800006866455078125)) * _6584) * _6584) * (0.0465199984610080718994140625 + _6749))) * 4.0)) * _5294;
            _2487 = _7300 + ((((((_5286 * powr(_5278, float3((1.0 - _7335) * 0.3499999940395355224609375))) * _7371) + _6656) * (_913._m0[_5620].xyz * ((((_5649 * _5649) * _5672) * _5672) / fast::max(_5640, 9.9999997473787516355514526367188e-05)))) * _7335) * _2383);
        }
        _7299 = _7300;
    }
    else
    {
        _7299 = _2406;
    }
    float _2499 = -length(_2298);
    float _7302;
    if (_163._m9.w != 0.0)
    {
        float _2523 = _163._m9.w * (in.m_885 - _163._m6.xyz).y;
        float _7297;
        if (abs(_2523) < 9.9999997473787516355514526367188e-05)
        {
            _7297 = 1.0 - (0.5 * _2523);
        }
        else
        {
            _7297 = (1.0 - exp(fast::min(-_2523, 60.0))) / _2523;
        }
        _7302 = 1.0 - exp((_2499 * (_163._m7.w * exp(fast::min((-_163._m9.w) * (_163._m6.y - _163._m6.w), 30.0)))) * _7297);
    }
    else
    {
        _7302 = 1.0 - exp(_2499 * _163._m7.w);
    }
    float3 _2574 = mix(_7299, _163._m7.xyz, float3(_7302));
    float3 _7303;
    if (_163._m33.w > 0.5)
    {
        _7303 = _2574 / (float3(1.0) + _2574);
    }
    else
    {
        _7303 = _2574;
    }
    out.m_2587 = float4(_7303, _6956);
    float2 _7304;
    do
    {
        if (in.m_2597.w <= 0.0)
        {
            _7304 = float2(0.0);
            break;
        }
        _7304 = ((in.m_2597.xy / float2(in.m_2597.w)) - (in.m_2596.xy / float2(in.m_2596.w))) * float2(0.5, -0.5);
        break;
    } while(false);
    out.m_2595 = _7304;
    return out;
}

