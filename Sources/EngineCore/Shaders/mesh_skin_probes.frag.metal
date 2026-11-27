// Generated from mesh_skin_probes.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 39bea39e25b463fa
// glsl-fnv1a64: 2de752fba45c2c26

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

struct _380
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

struct _1378
{
    uint4 _m0[1];
};

struct _2973
{
    float4 _m0;
    float4 _m1;
    float4 _m2;
    float4 _m3;
    float4 _m4;
    float4 _m5;
    float4 _m6;
};

struct _3127
{
    float4 _m0[1024];
};

struct _3162
{
    float4 _m0[1024];
};

struct _3170
{
    float4 _m0[1024];
};

struct _3264
{
    uint4 _m0[1024];
};

struct _3285
{
    uint4 _m0[1024];
};

struct _3370
{
    float4 _m0;
    float4 _m1;
    float4 _m2;
    float4 _m3;
    float4 _m4;
    float4 _m5;
    float4 _m6;
};

constant float _37892 = {};

constant spvUnsafeArray<float3, 4> _756 = spvUnsafeArray<float3, 4>({ float3(1.0, 0.449999988079071044921875, 0.449999988079071044921875), float3(0.449999988079071044921875, 1.0, 0.449999988079071044921875), float3(0.5, 0.60000002384185791015625, 1.0), float3(1.0, 1.0, 0.4000000059604644775390625) });
constant spvUnsafeArray<float3, 6> _1060 = spvUnsafeArray<float3, 6>({ float3(0.0, 0.0, 1.0), float3(0.0, 0.0, -1.0), float3(-1.0, 0.0, 0.0), float3(-1.0, 0.0, 0.0), float3(-1.0, 0.0, 0.0), float3(1.0, 0.0, 0.0) });
constant spvUnsafeArray<float3, 6> _1069 = spvUnsafeArray<float3, 6>({ float3(0.0, 1.0, 0.0), float3(0.0, 1.0, 0.0), float3(0.0, 0.0, -1.0), float3(0.0, 0.0, 1.0), float3(0.0, 1.0, 0.0), float3(0.0, 1.0, 0.0) });
constant spvUnsafeArray<int3, 6> _1452 = spvUnsafeArray<int3, 6>({ int3(0, 256, 128), int3(32768, 128, 64), int3(40960, 64, 32), int3(43008, 32, 16), int3(43520, 16, 8), int3(43648, 8, 4) });
constant spvUnsafeArray<int4, 6> _2687 = spvUnsafeArray<int4, 6>({ int4(0, 0, 512, 256), int4(0, 256, 256, 128), int4(256, 256, 128, 64), int4(384, 256, 64, 32), int4(448, 256, 32, 16), int4(480, 256, 16, 8) });
constant spvUnsafeArray<float, 4> _3479 = spvUnsafeArray<float, 4>({ 0.00200000009499490261077880859375, 0.004999999888241291046142578125, 0.00999999977648258209228515625, 0.0199999995529651641845703125 });

struct fragment_main_out
{
    float4 m_6415 [[color(0)]];
    float2 m_6423 [[color(1)]];
};

struct fragment_main_in
{
    float3 m_3136 [[user(locn0)]];
    float3 m_3045 [[user(locn1)]];
    float2 m_5100 [[user(locn2)]];
    float4 m_5685 [[user(locn3)]];
    float3 m_3079 [[user(locn4)]];
    float4 m_5911 [[user(locn5)]];
    float4 m_6424 [[user(locn6)]];
    float4 m_6425 [[user(locn7)]];
    float4 m_3051 [[user(locn8)]];
};

fragment fragment_main_out fragment_main(fragment_main_in in [[stage_in]], constant _2973& _2975 [[buffer(2)]], constant _3127& _3129 [[buffer(3)]], constant _3162& _3164 [[buffer(4)]], constant _3170& _3172 [[buffer(5)]], constant _3264& _3266 [[buffer(6)]], constant _3285& _3287 [[buffer(7)]], constant _380& _382 [[buffer(15)]], constant _3370& _3372 [[buffer(16)]], const device _1378& _1380 [[buffer(21)]], texture2d<float> _402 [[texture(0)]], texture2d<float> _5678 [[texture(1)]], texture2d<float> _6154 [[texture(2)]], texture2d<float> _5791 [[texture(3)]], texture2d<float> _5951 [[texture(4)]], texture2d<float> _6244 [[texture(5)]], texture2d<float> _2630 [[texture(6)]], texture2d<float> _2731 [[texture(7)]], sampler _402Smplr [[sampler(0)]], sampler _2632 [[sampler(1)]], sampler _2733 [[sampler(7)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])
{
    fragment_main_out out = {};
    float2 _5676 = float2(dot(_2975._m2.xy, in.m_5100) + _2975._m2.z, dot(_2975._m3.xy, in.m_5100) + _2975._m3.z);
    float4 _5683 = _5678.sample(_2632, _5676);
    float3 _5693 = _5683.xyz;
    float3 _5694 = (in.m_5685.xyz * _2975._m0.xyz) * _5693;
    float3 _35353;
    if (_2975._m1.x > 0.5)
    {
        float2 _5715 = floor(in.m_3136.xz * float2(0.5));
        _35353 = _5694 * ((mod(abs(_5715.x + _5715.y), 2.0) < 0.5) ? 1.0 : 0.75);
    }
    else
    {
        _35353 = _5694;
    }
    float3 _35450;
    float _35481;
    float2 _35514;
    if (_2975._m3.w > 0.5)
    {
        float3 _6551;
        float2 _6558;
        float _35351;
        do
        {
            float3 _6522 = float4(_2975._m2.w, _2975._m3.w, 0.0, 0.0).xyy;
            float3 _6525 = floor(_6522 * float3(1.52587890625e-05));
            float3 _6530 = _6522 - (_6525 * 65536.0);
            float3 _6533 = floor(_6530 * float3(0.00390625));
            float3 _6541 = _6530 - (_6533 * 256.0);
            _6551 = (float3(_6541.x, _6533.x, _6525.x) * float3(0.0039215688593685626983642578125)) * 2.0;
            _6558 = float2(_6541.y, _6533.y) * float2(0.0039215688593685626983642578125);
            float _6561 = _6525.y - 128.0;
            float _6567 = floor(_6561 * 0.03125) * 0.3333333432674407958984375;
            float3 _6573 = fast::normalize(in.m_3045);
            float _6577 = dot(_6573, in.m_3051.xyz);
            float _6589 = (_6577 / fast::max(length(in.m_3051.xyz - (_6573 * _6577)), 9.9999999747524270787835121154785e-07)) * 25.5;
            if (((-24.0) + _6589) < (-2.0))
            {
                _35351 = 0.0;
                break;
            }
            float3 _6597 = in.m_3079 * (4.0 * exp2(mod(_6561, 32.0) * 0.3333333432674407958984375));
            float3 _6641 = floor(_6597);
            float3 _6644 = _6597 - _6641;
            float3 _6652 = (_6644 * _6644) * (float3(3.0) - (_6644 * 2.0));
            uint3 _6719 = uint3(int3(_6641));
            uint _6732 = (((_6719.x * 1597334677u) ^ (_6719.y * 3812015801u)) ^ (_6719.z * 2798796415u)) * 1597334677u;
            uint3 _6747 = uint3(int3(_6641 + float3(1.0, 0.0, 0.0)));
            uint _6760 = (((_6747.x * 1597334677u) ^ (_6747.y * 3812015801u)) ^ (_6747.z * 2798796415u)) * 1597334677u;
            float _6661 = _6652.x;
            uint3 _6775 = uint3(int3(_6641 + float3(0.0, 1.0, 0.0)));
            uint _6788 = (((_6775.x * 1597334677u) ^ (_6775.y * 3812015801u)) ^ (_6775.z * 2798796415u)) * 1597334677u;
            uint3 _6803 = uint3(int3(_6641 + float3(1.0, 1.0, 0.0)));
            uint _6816 = (((_6803.x * 1597334677u) ^ (_6803.y * 3812015801u)) ^ (_6803.z * 2798796415u)) * 1597334677u;
            float _6677 = _6652.y;
            uint3 _6831 = uint3(int3(_6641 + float3(0.0, 0.0, 1.0)));
            uint _6844 = (((_6831.x * 1597334677u) ^ (_6831.y * 3812015801u)) ^ (_6831.z * 2798796415u)) * 1597334677u;
            uint3 _6859 = uint3(int3(_6641 + float3(1.0, 0.0, 1.0)));
            uint _6872 = (((_6859.x * 1597334677u) ^ (_6859.y * 3812015801u)) ^ (_6859.z * 2798796415u)) * 1597334677u;
            uint3 _6887 = uint3(int3(_6641 + float3(0.0, 1.0, 1.0)));
            uint _6900 = (((_6887.x * 1597334677u) ^ (_6887.y * 3812015801u)) ^ (_6887.z * 2798796415u)) * 1597334677u;
            uint3 _6915 = uint3(int3(_6641 + float3(1.0)));
            uint _6928 = (((_6915.x * 1597334677u) ^ (_6915.y * 3812015801u)) ^ (_6915.z * 2798796415u)) * 1597334677u;
            float3 _6603 = (_6597 * 2.7000000476837158203125) + float3(17.299999237060546875, 5.099999904632568359375, 9.69999980926513671875);
            float3 _6954 = floor(_6603);
            float3 _6957 = _6603 - _6954;
            float3 _6965 = (_6957 * _6957) * (float3(3.0) - (_6957 * 2.0));
            uint3 _7032 = uint3(int3(_6954));
            uint _7045 = (((_7032.x * 1597334677u) ^ (_7032.y * 3812015801u)) ^ (_7032.z * 2798796415u)) * 1597334677u;
            uint3 _7060 = uint3(int3(_6954 + float3(1.0, 0.0, 0.0)));
            uint _7073 = (((_7060.x * 1597334677u) ^ (_7060.y * 3812015801u)) ^ (_7060.z * 2798796415u)) * 1597334677u;
            float _6974 = _6965.x;
            uint3 _7088 = uint3(int3(_6954 + float3(0.0, 1.0, 0.0)));
            uint _7101 = (((_7088.x * 1597334677u) ^ (_7088.y * 3812015801u)) ^ (_7088.z * 2798796415u)) * 1597334677u;
            uint3 _7116 = uint3(int3(_6954 + float3(1.0, 1.0, 0.0)));
            uint _7129 = (((_7116.x * 1597334677u) ^ (_7116.y * 3812015801u)) ^ (_7116.z * 2798796415u)) * 1597334677u;
            float _6990 = _6965.y;
            uint3 _7144 = uint3(int3(_6954 + float3(0.0, 0.0, 1.0)));
            uint _7157 = (((_7144.x * 1597334677u) ^ (_7144.y * 3812015801u)) ^ (_7144.z * 2798796415u)) * 1597334677u;
            uint3 _7172 = uint3(int3(_6954 + float3(1.0, 0.0, 1.0)));
            uint _7185 = (((_7172.x * 1597334677u) ^ (_7172.y * 3812015801u)) ^ (_7172.z * 2798796415u)) * 1597334677u;
            uint3 _7200 = uint3(int3(_6954 + float3(0.0, 1.0, 1.0)));
            uint _7213 = (((_7200.x * 1597334677u) ^ (_7200.y * 3812015801u)) ^ (_7200.z * 2798796415u)) * 1597334677u;
            uint3 _7228 = uint3(int3(_6954 + float3(1.0)));
            uint _7241 = (((_7228.x * 1597334677u) ^ (_7228.y * 3812015801u)) ^ (_7228.z * 2798796415u)) * 1597334677u;
            float _6608 = mix(0.449999988079071044921875, 0.0500000007450580596923828125, _6567);
            float _6612 = ((mix(mix(mix(float((_6732 ^ (_6732 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_6760 ^ (_6760 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _6661), mix(float((_6788 ^ (_6788 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_6816 ^ (_6816 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _6661), _6677), mix(mix(float((_6844 ^ (_6844 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_6872 ^ (_6872 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _6661), mix(float((_6900 ^ (_6900 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_6928 ^ (_6928 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _6661), _6677), _6652.z) * 0.64999997615814208984375) + (mix(mix(mix(float((_7045 ^ (_7045 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_7073 ^ (_7073 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _6974), mix(float((_7101 ^ (_7101 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_7129 ^ (_7129 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _6974), _6990), mix(mix(float((_7157 ^ (_7157 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_7185 ^ (_7185 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _6974), mix(float((_7213 ^ (_7213 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_7241 ^ (_7241 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _6974), _6990), _6965.z) * 0.3499999940395355224609375)) - 0.5;
            _35351 = smoothstep(-_6608, _6608, (_6589 + (-24.450000762939453125)) + (_6612 * mix(0.800000011920928955078125, 2.2000000476837158203125, _6567)));
            break;
        } while(false);
        _35514 = _6558;
        _35481 = _35351;
        _35450 = mix(_35353, (in.m_5685.xyz * _6551) * mix(float3(1.0), _5693 * 2.0, float3(0.5)), float3(_35351));
    }
    else
    {
        _35514 = float2(0.0);
        _35481 = 0.0;
        _35450 = _35353;
    }
    float3 _5757 = fast::normalize(in.m_3045);
    float3 _35363;
    if (_2975._m6.y > 0.5)
    {
        float3 _5772 = in.m_3051.xyz - (_5757 * dot(_5757, in.m_3051.xyz));
        float3 _35364;
        if (dot(_5772, _5772) > 9.9999999600419720025001879548654e-13)
        {
            float3 _5780 = fast::normalize(_5772);
            float4 _5796 = _5791.sample(_2632, _5676);
            float3 _35355;
            if (_2975._m6.z > 0.5)
            {
                float2 _35354;
                if (_2975._m6.z > 1.5)
                {
                    _35354 = _5796.xw;
                }
                else
                {
                    _35354 = _5796.xy;
                }
                float2 _5818 = (_35354 * 2.0) - float2(1.0);
                _35355 = float3(_5818, sqrt(fast::clamp(1.0 - dot(_5818, _5818), 0.0, 1.0)));
            }
            else
            {
                _35355 = (_5796.xyz * 2.0) - float3(1.0);
            }
            float2 _5840 = _35355.xy * _2975._m4.z;
            _35364 = fast::normalize(((_5780 * _5840.x) + ((cross(_5757, _5780) * ((in.m_3051.w < 0.0) ? (-1.0) : 1.0)) * _5840.y)) + (_5757 * _35355.z));
        }
        else
        {
            _35364 = _5757;
        }
        _35363 = _35364;
    }
    else
    {
        _35363 = _5757;
    }
    bool _5863 = _2975._m5.w > 0.5;
    float _35360;
    if (_5863)
    {
        _35360 = fast::clamp(_2975._m1.z, 0.0, 1.0);
    }
    else
    {
        _35360 = 0.0;
    }
    bool _5879;
    if (_5863)
    {
        _5879 = !gl_FrontFacing;
    }
    else
    {
        _5879 = _5863;
    }
    float3 _35548;
    if (_5879 && (_35360 <= 0.0))
    {
        _35548 = -_35363;
    }
    else
    {
        _35548 = _35363;
    }
    float3 _5891 = fast::normalize(_382._m4.xyz);
    float3 _5897 = _382._m6.xyz - in.m_3136;
    float3 _5898 = fast::normalize(_5897);
    float3 _5903 = fast::normalize(_5891 + _5898);
    float3 _5909 = _5757 * (gl_FrontFacing ? 1.0 : (-1.0));
    bool _5914 = in.m_5911.x > 0.5;
    float3 _35543;
    float _35574;
    if ((_382._m5.w > 0.5) && _5914)
    {
        float _35420;
        float3 _35421;
        do
        {
            int _7270 = int(_382._m21.x);
            float _7278 = dot(_382._m20.xyz, in.m_3136) + _382._m20.w;
            int _35365;
            _35365 = 0;
            for (;;)
            {
                bool _7284 = _35365 < (_7270 - 1);
                bool _7292;
                if (_7284)
                {
                    _7292 = _7278 > _382._m16[_35365];
                }
                else
                {
                    _7292 = _7284;
                }
                if (_7292)
                {
                    _35365++;
                    continue;
                }
                else
                {
                    break;
                }
            }
            if (_7278 > _382._m16[_35365])
            {
                _35421 = float3(1.0);
                _35420 = 1.0;
                break;
            }
            float _35378;
            do
            {
                float4 _7394 = _382._m14[_35365] * float4(in.m_3136 + (_5909 * _382._m18[_35365]), 1.0);
                float _7397 = _7394.x;
                bool _7398 = _7397 < 0.0;
                bool _7405;
                if (!_7398)
                {
                    _7405 = _7397 > 1.0;
                }
                else
                {
                    _7405 = _7398;
                }
                bool _7412;
                if (!_7405)
                {
                    _7412 = _7394.y < 0.0;
                }
                else
                {
                    _7412 = _7405;
                }
                bool _7419;
                if (!_7412)
                {
                    _7419 = _7394.y > 1.0;
                }
                else
                {
                    _7419 = _7412;
                }
                if (_7419)
                {
                    _35378 = 1.0;
                    break;
                }
                float2 _7432 = float2(float(_35365 & 1), float(_35365 >> 1)) * _382._m23.xy;
                float _7439 = fast::min(_7394.z, 1.0) - _382._m19[_35365];
                float2 _7458 = _382._m22.xy * 0.5;
                float2 _7463 = _7432 + (_7394.xy * _382._m23.xy);
                float4 _7476 = float4(_7432 + _7458, (_7432 + _382._m23.xy) - _7458);
                float _35377;
                do
                {
                    int _7502 = int(_382._m22.z);
                    if (_7502 <= 0)
                    {
                        _35377 = spvDepthCast(_402).sample_compare(_402Smplr, float3(fast::clamp(_7463, _7476.xy, _7476.zw), _7439).xy, _7439);
                        break;
                    }
                    float2 _7525 = (_7463 / _382._m22.xy) + float2(0.5);
                    float2 _7526 = floor(_7525);
                    float2 _7531 = _7525 - _7526;
                    float2 _7534 = _7526 - float2(0.5);
                    bool _7538 = _7502 == 1;
                    spvUnsafeArray<float2, 3> _7486;
                    spvUnsafeArray<float2, 3> _7487;
                    if (_7538)
                    {
                        float2 _7541 = _7531 * 2.0;
                        _7486[0] = float2(3.0) - _7541;
                        _7486[1] = float2(1.0) + _7541;
                        _7487[0] = ((float2(2.0) - _7531) / _7486[0]) - float2(1.0);
                        _7487[1] = (_7531 / _7486[1]) + float2(1.0);
                    }
                    else
                    {
                        float2 _7568 = _7531 * 3.0;
                        _7486[0] = float2(4.0) - _7568;
                        _7486[1] = float2(7.0);
                        _7486[2] = float2(1.0) + _7568;
                        _7487[0] = ((float2(3.0) - (_7531 * 2.0)) / _7486[0]) - float2(2.0);
                        _7487[1] = (float2(3.0) + _7531) / _7486[1];
                        _7487[2] = (_7531 / _7486[2]) + float2(2.0);
                    }
                    int _37907 = _7538 ? 2 : 3;
                    int _35367;
                    float _35370;
                    _35370 = 0.0;
                    _35367 = 0;
                    float _35376;
                    for (; _35367 < _37907; _35370 = _35376, _35367++)
                    {
                        _35376 = _35370;
                        for (int _35373 = 0; _35373 < _37907; )
                        {
                            _35376 += ((_7486[_35373].x * _7486[_35367].y) * spvDepthCast(_402).sample_compare(_402Smplr, float3(fast::clamp(_382._m22.xy * (_7534 + float2(_7487[_35373].x, _7487[_35367].y)), _7476.xy, _7476.zw), _7439).xy, _7439));
                            _35373++;
                            continue;
                        }
                    }
                    _35377 = _35370 * (_7538 ? 0.0625 : 0.0069444444961845874786376953125);
                    break;
                } while(false);
                _35378 = _35377;
                break;
            } while(false);
            float3 _35415;
            float _35418;
            if (_7278 > _382._m17[_35365])
            {
                float _7332 = (_7278 - _382._m17[_35365]) / (_382._m16[_35365] - _382._m17[_35365]);
                int _7334 = _35365 + 1;
                float3 _35416;
                float _35419;
                if (_7334 < _7270)
                {
                    float _35398;
                    do
                    {
                        float4 _7681 = _382._m14[_7334] * float4(in.m_3136 + (_5909 * _382._m18[_7334]), 1.0);
                        float _7684 = _7681.x;
                        bool _7685 = _7684 < 0.0;
                        bool _7692;
                        if (!_7685)
                        {
                            _7692 = _7684 > 1.0;
                        }
                        else
                        {
                            _7692 = _7685;
                        }
                        bool _7699;
                        if (!_7692)
                        {
                            _7699 = _7681.y < 0.0;
                        }
                        else
                        {
                            _7699 = _7692;
                        }
                        bool _7706;
                        if (!_7699)
                        {
                            _7706 = _7681.y > 1.0;
                        }
                        else
                        {
                            _7706 = _7699;
                        }
                        if (_7706)
                        {
                            _35398 = 1.0;
                            break;
                        }
                        float2 _7719 = float2(float(_7334 & 1), float(_7334 >> 1)) * _382._m23.xy;
                        float _7726 = fast::min(_7681.z, 1.0) - _382._m19[_7334];
                        float2 _7745 = _382._m22.xy * 0.5;
                        float2 _7750 = _7719 + (_7681.xy * _382._m23.xy);
                        float4 _7763 = float4(_7719 + _7745, (_7719 + _382._m23.xy) - _7745);
                        float _35397;
                        do
                        {
                            int _7789 = int(_382._m22.z);
                            if (_7789 <= 0)
                            {
                                _35397 = spvDepthCast(_402).sample_compare(_402Smplr, float3(fast::clamp(_7750, _7763.xy, _7763.zw), _7726).xy, _7726);
                                break;
                            }
                            float2 _7812 = (_7750 / _382._m22.xy) + float2(0.5);
                            float2 _7813 = floor(_7812);
                            float2 _7818 = _7812 - _7813;
                            float2 _7821 = _7813 - float2(0.5);
                            bool _7825 = _7789 == 1;
                            spvUnsafeArray<float2, 3> _7773;
                            spvUnsafeArray<float2, 3> _7774;
                            if (_7825)
                            {
                                float2 _7828 = _7818 * 2.0;
                                _7773[0] = float2(3.0) - _7828;
                                _7773[1] = float2(1.0) + _7828;
                                _7774[0] = ((float2(2.0) - _7818) / _7773[0]) - float2(1.0);
                                _7774[1] = (_7818 / _7773[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _7855 = _7818 * 3.0;
                                _7773[0] = float2(4.0) - _7855;
                                _7773[1] = float2(7.0);
                                _7773[2] = float2(1.0) + _7855;
                                _7774[0] = ((float2(3.0) - (_7818 * 2.0)) / _7773[0]) - float2(2.0);
                                _7774[1] = (float2(3.0) + _7818) / _7773[1];
                                _7774[2] = (_7818 / _7773[2]) + float2(2.0);
                            }
                            int _37909 = _7825 ? 2 : 3;
                            int _35387;
                            float _35390;
                            _35390 = 0.0;
                            _35387 = 0;
                            float _35396;
                            for (; _35387 < _37909; _35390 = _35396, _35387++)
                            {
                                _35396 = _35390;
                                for (int _35393 = 0; _35393 < _37909; )
                                {
                                    _35396 += ((_7773[_35393].x * _7773[_35387].y) * spvDepthCast(_402).sample_compare(_402Smplr, float3(fast::clamp(_382._m22.xy * (_7821 + float2(_7774[_35393].x, _7774[_35387].y)), _7763.xy, _7763.zw), _7726).xy, _7726));
                                    _35393++;
                                    continue;
                                }
                            }
                            _35397 = _35390 * (_7825 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _35398 = _35397;
                        break;
                    } while(false);
                    _35419 = mix(_35378, _35398, _7332);
                    _35416 = mix(_756[_35365], _756[_7334], float3(_7332));
                }
                else
                {
                    _35419 = mix(_35378, 1.0, _7332);
                    _35416 = _756[_35365];
                }
                _35418 = _35419;
                _35415 = _35416;
            }
            else
            {
                _35418 = _35378;
                _35415 = _756[_35365];
            }
            _35421 = select(float3(1.0), _35415, bool3(_382._m22.w > 0.5));
            _35420 = _35418;
            break;
        } while(false);
        _35574 = _35420;
        _35543 = _35450 * _35421;
    }
    else
    {
        _35574 = 1.0;
        _35543 = _35450;
    }
    float3 _5940 = _382._m5.xyz * _382._m4.w;
    float _35473;
    if (_2975._m6.w > 0.5)
    {
        _35473 = 1.0;
    }
    else
    {
        _35473 = 1.0 + (_2975._m4.w * (_5951.sample(_2632, _5676).x - 1.0));
    }
    float _5965 = abs(in.m_3051.w);
    float _35576;
    if (_5965 > 0.0)
    {
        _35576 = _35473 * fast::min(_5965, 1.0);
    }
    else
    {
        _35576 = _35473;
    }
    float3 _36594;
    float3 _37172;
    if (!_5863)
    {
        float _5982 = dot(_35548, _5891);
        bool _6007 = _382._m29.x > 0.5;
        float3 _36569;
        if (_6007)
        {
            float _8006 = (_382._m29.z * _35548.x) - (_382._m29.w * _35548.z);
            float _8019 = (_382._m29.w * _35548.x) + (_382._m29.z * _35548.z);
            float _8037 = 1.09254801273345947265625 * _8006;
            spvUnsafeArray<float, 9> _33087 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _35548.y, 0.48860299587249755859375 * _8019, 0.48860299587249755859375 * _8006, _8037 * _35548.y, (1.09254801273345947265625 * _35548.y) * _8019, 0.3153919875621795654296875 * (((3.0 * _8019) * _8019) - 1.0), _8037 * _8019, 0.546274006366729736328125 * ((_8006 * _8006) - (_35548.y * _35548.y)) });
            spvUnsafeArray<float, 9> _7951 = _33087;
            float3 _36568;
            _36568 = float3(0.0);
            for (int _36567 = 0; _36567 < 9; )
            {
                _36568 += (_2630.read(uint2((int2(496, 256) + int2(_36567, 0))), 0).xyz * _7951[_36567]);
                _36567++;
                continue;
            }
            _36569 = fast::max(_36568, float3(0.0)) * _382._m29.y;
        }
        else
        {
            _36569 = mix(_382._m9.xyz, _382._m8.xyz, float3((_35548.y * 0.5) + 0.5)) * _382._m8.w;
        }
        float3 _6032 = (_35543 * ((_36569 * _35576) + ((_5940 * fast::max(_5982, 0.0)) * _35574))) + ((_5940 * ((powr(fast::max(dot(_35548, _5903), 0.0), _2975._m1.w) * _2975._m1.z) * step(0.0, _5982))) * _35574);
        float3 _36596;
        if (_382._m34.y > 0.5)
        {
            float3 _36580;
            if (_6007)
            {
                float _8152 = (_382._m29.z * _35548.x) - (_382._m29.w * _35548.z);
                float _8165 = (_382._m29.w * _35548.x) + (_382._m29.z * _35548.z);
                float _8183 = 1.09254801273345947265625 * _8152;
                spvUnsafeArray<float, 9> _33068 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _35548.y, 0.48860299587249755859375 * _8165, 0.48860299587249755859375 * _8152, _8183 * _35548.y, (1.09254801273345947265625 * _35548.y) * _8165, 0.3153919875621795654296875 * (((3.0 * _8165) * _8165) - 1.0), _8183 * _8165, 0.546274006366729736328125 * ((_8152 * _8152) - (_35548.y * _35548.y)) });
                spvUnsafeArray<float, 9> _8097 = _33068;
                float3 _36579;
                _36579 = float3(0.0);
                for (int _36578 = 0; _36578 < 9; )
                {
                    _36579 += (_2630.read(uint2((int2(496, 256) + int2(_36578, 0))), 0).xyz * _8097[_36578]);
                    _36578++;
                    continue;
                }
                _36580 = fast::max(_36579, float3(0.0)) * _382._m29.y;
            }
            else
            {
                _36580 = mix(_382._m9.xyz, _382._m8.xyz, float3((_35548.y * 0.5) + 0.5)) * _382._m8.w;
            }
            int _8360 = int(_382._m34.y);
            int _8363 = int(_382._m34.x);
            float3 _36586;
            _36586 = _36580;
            float3 _37683;
            for (int _36585 = 0; _36585 < _8360; _36586 = _37683, _36585++)
            {
                int _8375 = 8 * (_8363 + _36585);
                float4 _8584 = as_type<float4>(_1380._m0[_8375 + 3]);
                float4 _8628 = as_type<float4>(_1380._m0[_8375]);
                float4 _8634 = as_type<float4>(_1380._m0[_8375 + 1]);
                float4 _8640 = as_type<float4>(_1380._m0[_8375 + 2]);
                float3 _8602 = _8628.xyz;
                float _8606 = _8628.w;
                float3 _8609 = _8634.xyz;
                float _8613 = _8634.w;
                float3 _8616 = _8640.xyz;
                float _8620 = _8640.w;
                float3 _8622 = float3(dot(_8602, in.m_3136) + _8606, dot(_8609, in.m_3136) + _8613, dot(_8616, in.m_3136) + _8620);
                float3 _8384 = _8584.xyz;
                float _8386 = _8584.w;
                float _37548;
                do
                {
                    float3 _8652 = _8384 - abs(_8622);
                    float _8660 = fast::min(_8652.x, fast::min(_8652.y, _8652.z));
                    if (_8660 <= 0.0)
                    {
                        _37548 = 0.0;
                        break;
                    }
                    if (_8386 <= 0.0)
                    {
                        _37548 = 1.0;
                        break;
                    }
                    float _8672 = fast::min(_8660 / _8386, 1.0);
                    _37548 = (_8672 * _8672) * (3.0 - (2.0 * _8672));
                    break;
                } while(false);
                if (_37548 <= 0.0)
                {
                    _37683 = _36586;
                    continue;
                }
                float3 _8395 = as_type<float4>(_1380._m0[_8375 + 4]).xyz;
                float4 _8693 = as_type<float4>(_1380._m0[_8375 + 5]);
                int _8699 = int(((device uint*)&_1380._m0[_8375 + 6])[0u]);
                float _8709 = dot(_8602, _35548);
                float _8715 = dot(_8609, _35548);
                float _8721 = dot(_8616, _35548);
                float3 _8722 = float3(_8709, _8715, _8721);
                float3 _8415 = (in.m_3136 + (_35548 * _8693.x)) + (_5898 * _8693.y);
                float3 _8434 = fast::clamp((((float3(dot(_8602, _8415) + _8606, dot(_8609, _8415) + _8613, dot(_8616, _8415) + _8620) + _8384) / fast::max(_8384 * 2.0, float3(9.9999999747524270787835121154785e-07))) * _8395) - float3(0.5), float3(0.0), _8395 - float3(1.0));
                int3 _8436 = int3(_8395);
                int3 _8443 = min(int3(_8434), max((_8436 - int3(2)), int3(0)));
                float3 _8447 = _8434 - float3(_8443);
                float _8802 = 0.48860299587249755859375 * _8715;
                float _8805 = 0.48860299587249755859375 * _8721;
                float _8808 = 0.48860299587249755859375 * _8709;
                float _8813 = 1.09254801273345947265625 * _8709;
                float _8816 = _8813 * _8715;
                float _8822 = (1.09254801273345947265625 * _8715) * _8721;
                float _8830 = 0.3153919875621795654296875 * (((3.0 * _8721) * _8721) - 1.0);
                float _8836 = _8813 * _8721;
                float _8850 = 0.546274006366729736328125 * ((_8709 * _8709) - (_8715 * _8715));
                int3 _8869 = _8436 - int3(1);
                int3 _8870 = min(_8443, _8869);
                int _8875 = _8436.x;
                int _8879 = _8436.y;
                int _8887 = _8699 + ((_8870.x + (_8875 * (_8870.y + (_8879 * _8870.z)))) * 4);
                float3 _8890 = float3(1.0) - _8447;
                float3 _8908 = (((((float3(_8870) + float3(0.5)) / _8395) * _8384) * 2.0) - _8384) - _8622;
                float _8918 = dot(_8908 * rsqrt(fast::max(dot(_8908, _8908), 1.0000000133514319600180897396058e-10)), _8722) + 1.0;
                float _8921 = _8890.x;
                float _8923 = _8890.y;
                float _8924 = _8921 * _8923;
                float _8926 = _8890.z;
                int _8950 = _8887 + 3;
                float _8936 = ((_8924 * _8926) * ((0.25 * (_8918 * _8918)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1380._m0[_8950])[1u])).y > 0.5);
                int _8980 = _8887 + 1;
                int _8984 = _8887 + 2;
                float2 _8996 = float2(as_type<half2>(_1380._m0[_8887].y));
                float2 _9005 = float2(as_type<half2>(_1380._m0[_8980].x));
                float2 _9014 = float2(as_type<half2>(_1380._m0[_8980].w));
                float2 _9023 = float2(as_type<half2>(_1380._m0[_8984].z));
                float3 _9111 = (((((((float3(float2(as_type<half2>(_1380._m0[_8887].x)), _8996.x) * 0.2820949852466583251953125) + (float3(_8996.y, float2(as_type<half2>(_1380._m0[_8887].z))) * _8802)) + (float3(float2(as_type<half2>(_1380._m0[_8887].w)), _9005.x) * _8805)) + (float3(_9005.y, float2(as_type<half2>(_1380._m0[_8980].y))) * _8808)) + (float3(float2(as_type<half2>(_1380._m0[_8980].z)), _9014.x) * _8816)) + (float3(_9014.y, float2(as_type<half2>(_1380._m0[_8984].x))) * _8822)) + (float3(float2(as_type<half2>(_1380._m0[_8984].y)), _9023.x) * _8830)) + (float3(_9023.y, float2(as_type<half2>(_1380._m0[_8984].w))) * _8836);
                int3 _9139 = min((_8443 + int3(1, 0, 0)), _8869);
                int _9156 = _8699 + ((_9139.x + (_8875 * (_9139.y + (_8879 * _9139.z)))) * 4);
                float3 _9177 = (((((float3(_9139) + float3(0.5)) / _8395) * _8384) * 2.0) - _8384) - _8622;
                float _9187 = dot(_9177 * rsqrt(fast::max(dot(_9177, _9177), 1.0000000133514319600180897396058e-10)), _8722) + 1.0;
                float _9193 = _8447.x * _8923;
                int _9219 = _9156 + 3;
                float _9205 = ((_9193 * _8926) * ((0.25 * (_9187 * _9187)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1380._m0[_9219])[1u])).y > 0.5);
                int _9249 = _9156 + 1;
                int _9253 = _9156 + 2;
                float2 _9265 = float2(as_type<half2>(_1380._m0[_9156].y));
                float2 _9274 = float2(as_type<half2>(_1380._m0[_9249].x));
                float2 _9283 = float2(as_type<half2>(_1380._m0[_9249].w));
                float2 _9292 = float2(as_type<half2>(_1380._m0[_9253].z));
                float3 _9380 = (((((((float3(float2(as_type<half2>(_1380._m0[_9156].x)), _9265.x) * 0.2820949852466583251953125) + (float3(_9265.y, float2(as_type<half2>(_1380._m0[_9156].z))) * _8802)) + (float3(float2(as_type<half2>(_1380._m0[_9156].w)), _9274.x) * _8805)) + (float3(_9274.y, float2(as_type<half2>(_1380._m0[_9249].y))) * _8808)) + (float3(float2(as_type<half2>(_1380._m0[_9249].z)), _9283.x) * _8816)) + (float3(_9283.y, float2(as_type<half2>(_1380._m0[_9253].x))) * _8822)) + (float3(float2(as_type<half2>(_1380._m0[_9253].y)), _9292.x) * _8830)) + (float3(_9292.y, float2(as_type<half2>(_1380._m0[_9253].w))) * _8836);
                int3 _9408 = min((_8443 + int3(0, 1, 0)), _8869);
                int _9425 = _8699 + ((_9408.x + (_8875 * (_9408.y + (_8879 * _9408.z)))) * 4);
                float3 _9446 = (((((float3(_9408) + float3(0.5)) / _8395) * _8384) * 2.0) - _8384) - _8622;
                float _9456 = dot(_9446 * rsqrt(fast::max(dot(_9446, _9446), 1.0000000133514319600180897396058e-10)), _8722) + 1.0;
                float _9462 = _8921 * _8447.y;
                int _9488 = _9425 + 3;
                float _9474 = ((_9462 * _8926) * ((0.25 * (_9456 * _9456)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1380._m0[_9488])[1u])).y > 0.5);
                int _9518 = _9425 + 1;
                int _9522 = _9425 + 2;
                float2 _9534 = float2(as_type<half2>(_1380._m0[_9425].y));
                float2 _9543 = float2(as_type<half2>(_1380._m0[_9518].x));
                float2 _9552 = float2(as_type<half2>(_1380._m0[_9518].w));
                float2 _9561 = float2(as_type<half2>(_1380._m0[_9522].z));
                float3 _9649 = (((((((float3(float2(as_type<half2>(_1380._m0[_9425].x)), _9534.x) * 0.2820949852466583251953125) + (float3(_9534.y, float2(as_type<half2>(_1380._m0[_9425].z))) * _8802)) + (float3(float2(as_type<half2>(_1380._m0[_9425].w)), _9543.x) * _8805)) + (float3(_9543.y, float2(as_type<half2>(_1380._m0[_9518].y))) * _8808)) + (float3(float2(as_type<half2>(_1380._m0[_9518].z)), _9552.x) * _8816)) + (float3(_9552.y, float2(as_type<half2>(_1380._m0[_9522].x))) * _8822)) + (float3(float2(as_type<half2>(_1380._m0[_9522].y)), _9561.x) * _8830)) + (float3(_9561.y, float2(as_type<half2>(_1380._m0[_9522].w))) * _8836);
                int3 _9677 = min((_8443 + int3(1, 1, 0)), _8869);
                int _9694 = _8699 + ((_9677.x + (_8875 * (_9677.y + (_8879 * _9677.z)))) * 4);
                float3 _9715 = (((((float3(_9677) + float3(0.5)) / _8395) * _8384) * 2.0) - _8384) - _8622;
                float _9725 = dot(_9715 * rsqrt(fast::max(dot(_9715, _9715), 1.0000000133514319600180897396058e-10)), _8722) + 1.0;
                float _9731 = _8447.x * _8447.y;
                int _9757 = _9694 + 3;
                float _9743 = ((_9731 * _8926) * ((0.25 * (_9725 * _9725)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1380._m0[_9757])[1u])).y > 0.5);
                int _9787 = _9694 + 1;
                int _9791 = _9694 + 2;
                float2 _9803 = float2(as_type<half2>(_1380._m0[_9694].y));
                float2 _9812 = float2(as_type<half2>(_1380._m0[_9787].x));
                float2 _9821 = float2(as_type<half2>(_1380._m0[_9787].w));
                float2 _9830 = float2(as_type<half2>(_1380._m0[_9791].z));
                float3 _9918 = (((((((float3(float2(as_type<half2>(_1380._m0[_9694].x)), _9803.x) * 0.2820949852466583251953125) + (float3(_9803.y, float2(as_type<half2>(_1380._m0[_9694].z))) * _8802)) + (float3(float2(as_type<half2>(_1380._m0[_9694].w)), _9812.x) * _8805)) + (float3(_9812.y, float2(as_type<half2>(_1380._m0[_9787].y))) * _8808)) + (float3(float2(as_type<half2>(_1380._m0[_9787].z)), _9821.x) * _8816)) + (float3(_9821.y, float2(as_type<half2>(_1380._m0[_9791].x))) * _8822)) + (float3(float2(as_type<half2>(_1380._m0[_9791].y)), _9830.x) * _8830)) + (float3(_9830.y, float2(as_type<half2>(_1380._m0[_9791].w))) * _8836);
                int3 _9946 = min((_8443 + int3(0, 0, 1)), _8869);
                int _9963 = _8699 + ((_9946.x + (_8875 * (_9946.y + (_8879 * _9946.z)))) * 4);
                float3 _9984 = (((((float3(_9946) + float3(0.5)) / _8395) * _8384) * 2.0) - _8384) - _8622;
                float _9994 = dot(_9984 * rsqrt(fast::max(dot(_9984, _9984), 1.0000000133514319600180897396058e-10)), _8722) + 1.0;
                int _10026 = _9963 + 3;
                float _10012 = ((_8924 * _8447.z) * ((0.25 * (_9994 * _9994)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1380._m0[_10026])[1u])).y > 0.5);
                int _10056 = _9963 + 1;
                int _10060 = _9963 + 2;
                float2 _10072 = float2(as_type<half2>(_1380._m0[_9963].y));
                float2 _10081 = float2(as_type<half2>(_1380._m0[_10056].x));
                float2 _10090 = float2(as_type<half2>(_1380._m0[_10056].w));
                float2 _10099 = float2(as_type<half2>(_1380._m0[_10060].z));
                float3 _10187 = (((((((float3(float2(as_type<half2>(_1380._m0[_9963].x)), _10072.x) * 0.2820949852466583251953125) + (float3(_10072.y, float2(as_type<half2>(_1380._m0[_9963].z))) * _8802)) + (float3(float2(as_type<half2>(_1380._m0[_9963].w)), _10081.x) * _8805)) + (float3(_10081.y, float2(as_type<half2>(_1380._m0[_10056].y))) * _8808)) + (float3(float2(as_type<half2>(_1380._m0[_10056].z)), _10090.x) * _8816)) + (float3(_10090.y, float2(as_type<half2>(_1380._m0[_10060].x))) * _8822)) + (float3(float2(as_type<half2>(_1380._m0[_10060].y)), _10099.x) * _8830)) + (float3(_10099.y, float2(as_type<half2>(_1380._m0[_10060].w))) * _8836);
                float4 _8514 = (((float4((_9111 + (float3(float2(as_type<half2>(_1380._m0[_8950].x)), float2(as_type<half2>(_1380._m0[_8950].y)).x) * _8850)) * _8936, _8936) + float4((_9380 + (float3(float2(as_type<half2>(_1380._m0[_9219].x)), float2(as_type<half2>(_1380._m0[_9219].y)).x) * _8850)) * _9205, _9205)) + float4((_9649 + (float3(float2(as_type<half2>(_1380._m0[_9488].x)), float2(as_type<half2>(_1380._m0[_9488].y)).x) * _8850)) * _9474, _9474)) + float4((_9918 + (float3(float2(as_type<half2>(_1380._m0[_9757].x)), float2(as_type<half2>(_1380._m0[_9757].y)).x) * _8850)) * _9743, _9743)) + float4((_10187 + (float3(float2(as_type<half2>(_1380._m0[_10026].x)), float2(as_type<half2>(_1380._m0[_10026].y)).x) * _8850)) * _10012, _10012);
                int3 _10215 = min((_8443 + int3(1, 0, 1)), _8869);
                int _10232 = _8699 + ((_10215.x + (_8875 * (_10215.y + (_8879 * _10215.z)))) * 4);
                float3 _10253 = (((((float3(_10215) + float3(0.5)) / _8395) * _8384) * 2.0) - _8384) - _8622;
                float _10263 = dot(_10253 * rsqrt(fast::max(dot(_10253, _10253), 1.0000000133514319600180897396058e-10)), _8722) + 1.0;
                int _10295 = _10232 + 3;
                float _10281 = ((_9193 * _8447.z) * ((0.25 * (_10263 * _10263)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1380._m0[_10295])[1u])).y > 0.5);
                int _10325 = _10232 + 1;
                int _10329 = _10232 + 2;
                float2 _10341 = float2(as_type<half2>(_1380._m0[_10232].y));
                float2 _10350 = float2(as_type<half2>(_1380._m0[_10325].x));
                float2 _10359 = float2(as_type<half2>(_1380._m0[_10325].w));
                float2 _10368 = float2(as_type<half2>(_1380._m0[_10329].z));
                float3 _10456 = (((((((float3(float2(as_type<half2>(_1380._m0[_10232].x)), _10341.x) * 0.2820949852466583251953125) + (float3(_10341.y, float2(as_type<half2>(_1380._m0[_10232].z))) * _8802)) + (float3(float2(as_type<half2>(_1380._m0[_10232].w)), _10350.x) * _8805)) + (float3(_10350.y, float2(as_type<half2>(_1380._m0[_10325].y))) * _8808)) + (float3(float2(as_type<half2>(_1380._m0[_10325].z)), _10359.x) * _8816)) + (float3(_10359.y, float2(as_type<half2>(_1380._m0[_10329].x))) * _8822)) + (float3(float2(as_type<half2>(_1380._m0[_10329].y)), _10368.x) * _8830)) + (float3(_10368.y, float2(as_type<half2>(_1380._m0[_10329].w))) * _8836);
                int3 _10484 = min((_8443 + int3(0, 1, 1)), _8869);
                int _10501 = _8699 + ((_10484.x + (_8875 * (_10484.y + (_8879 * _10484.z)))) * 4);
                float3 _10522 = (((((float3(_10484) + float3(0.5)) / _8395) * _8384) * 2.0) - _8384) - _8622;
                float _10532 = dot(_10522 * rsqrt(fast::max(dot(_10522, _10522), 1.0000000133514319600180897396058e-10)), _8722) + 1.0;
                int _10564 = _10501 + 3;
                float _10550 = ((_9462 * _8447.z) * ((0.25 * (_10532 * _10532)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1380._m0[_10564])[1u])).y > 0.5);
                int _10594 = _10501 + 1;
                int _10598 = _10501 + 2;
                float2 _10610 = float2(as_type<half2>(_1380._m0[_10501].y));
                float2 _10619 = float2(as_type<half2>(_1380._m0[_10594].x));
                float2 _10628 = float2(as_type<half2>(_1380._m0[_10594].w));
                float2 _10637 = float2(as_type<half2>(_1380._m0[_10598].z));
                float3 _10725 = (((((((float3(float2(as_type<half2>(_1380._m0[_10501].x)), _10610.x) * 0.2820949852466583251953125) + (float3(_10610.y, float2(as_type<half2>(_1380._m0[_10501].z))) * _8802)) + (float3(float2(as_type<half2>(_1380._m0[_10501].w)), _10619.x) * _8805)) + (float3(_10619.y, float2(as_type<half2>(_1380._m0[_10594].y))) * _8808)) + (float3(float2(as_type<half2>(_1380._m0[_10594].z)), _10628.x) * _8816)) + (float3(_10628.y, float2(as_type<half2>(_1380._m0[_10598].x))) * _8822)) + (float3(float2(as_type<half2>(_1380._m0[_10598].y)), _10637.x) * _8830)) + (float3(_10637.y, float2(as_type<half2>(_1380._m0[_10598].w))) * _8836);
                int3 _10753 = min((_8443 + int3(1)), _8869);
                int _10770 = _8699 + ((_10753.x + (_8875 * (_10753.y + (_8879 * _10753.z)))) * 4);
                float3 _10791 = (((((float3(_10753) + float3(0.5)) / _8395) * _8384) * 2.0) - _8384) - _8622;
                float _10801 = dot(_10791 * rsqrt(fast::max(dot(_10791, _10791), 1.0000000133514319600180897396058e-10)), _8722) + 1.0;
                int _10833 = _10770 + 3;
                float _10819 = ((_9731 * _8447.z) * ((0.25 * (_10801 * _10801)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1380._m0[_10833])[1u])).y > 0.5);
                int _10863 = _10770 + 1;
                int _10867 = _10770 + 2;
                float2 _10879 = float2(as_type<half2>(_1380._m0[_10770].y));
                float2 _10888 = float2(as_type<half2>(_1380._m0[_10863].x));
                float2 _10897 = float2(as_type<half2>(_1380._m0[_10863].w));
                float2 _10906 = float2(as_type<half2>(_1380._m0[_10867].z));
                float3 _10994 = (((((((float3(float2(as_type<half2>(_1380._m0[_10770].x)), _10879.x) * 0.2820949852466583251953125) + (float3(_10879.y, float2(as_type<half2>(_1380._m0[_10770].z))) * _8802)) + (float3(float2(as_type<half2>(_1380._m0[_10770].w)), _10888.x) * _8805)) + (float3(_10888.y, float2(as_type<half2>(_1380._m0[_10863].y))) * _8808)) + (float3(float2(as_type<half2>(_1380._m0[_10863].z)), _10897.x) * _8816)) + (float3(_10897.y, float2(as_type<half2>(_1380._m0[_10867].x))) * _8822)) + (float3(float2(as_type<half2>(_1380._m0[_10867].y)), _10906.x) * _8830)) + (float3(_10906.y, float2(as_type<half2>(_1380._m0[_10867].w))) * _8836);
                float4 _8553 = ((_8514 + float4((_10456 + (float3(float2(as_type<half2>(_1380._m0[_10295].x)), float2(as_type<half2>(_1380._m0[_10295].y)).x) * _8850)) * _10281, _10281)) + float4((_10725 + (float3(float2(as_type<half2>(_1380._m0[_10564].x)), float2(as_type<half2>(_1380._m0[_10564].y)).x) * _8850)) * _10550, _10550)) + float4((_10994 + (float3(float2(as_type<half2>(_1380._m0[_10833].x)), float2(as_type<half2>(_1380._m0[_10833].y)).x) * _8850)) * _10819, _10819);
                float _8557 = _8553.w;
                float3 _37684;
                if (_8557 > 9.9999997473787516355514526367188e-06)
                {
                    _37684 = mix(_36586, (fast::max(_8553.xyz, float3(0.0)) / float3(_8557)) * _8693.z, float3(_37548));
                }
                else
                {
                    _37684 = _36586;
                }
                _37683 = _37684;
            }
            _36596 = _6032 + ((_35543 * (_36586 - _36580)) * _35576);
        }
        else
        {
            _36596 = _6032;
        }
        float3 _36595;
        if (_382._m13.w > 0.5)
        {
            float2 _11032 = fast::clamp(floor(gl_FragCoord.xy * _382._m12.xy), float2(0.0), _382._m13.xy - float2(1.0));
            uint _11060 = uint((((fast::clamp(floor((log2(fast::max(dot(_382._m11.xyz, in.m_3136) + _382._m11.w, 9.9999999747524270787835121154785e-07)) * _382._m12.z) + _382._m12.w), 0.0, _382._m13.z - 1.0) * _382._m13.y) + _11032.y) * _382._m13.x) + _11032.x);
            uint _11062 = _11060 >> uint(2);
            uint _11064 = _11060 & 3u;
            uint _11068 = _3266._m0[_11062][_11064] & 65535u;
            uint _11070 = _3266._m0[_11062][_11064] >> uint(16);
            float3 _36597;
            _36597 = _36596;
            float3 _6149;
            spvUnsafeArray<float2, 3> _11478;
            spvUnsafeArray<float2, 3> _11479;
            spvUnsafeArray<float2, 3> _11691;
            spvUnsafeArray<float2, 3> _11692;
            for (uint _36593 = _11068; _36593 < (_11068 + _11070); _36597 = _6149, _36593++)
            {
                uint _11076 = _36593 / 3u;
                uint _11089 = (_3287._m0[_11076 >> uint(2)][_11076 & 3u] >> ((_36593 - (_11076 * 3u)) * 10u)) & 1023u;
                float3 _11106 = _3129._m0[_11089].xyz - in.m_3136;
                float _11109 = dot(_11106, _11106);
                float _11113 = _11109 * _3129._m0[_11089].w;
                float _11118 = fast::clamp(1.0 - (_11113 * _11113), 0.0, 1.0);
                float3 _11123 = _11106 * rsqrt(fast::max(_11109, 9.9999999392252902907785028219223e-09));
                float _11141 = fast::clamp((dot(-_11123, _3172._m0[_11089].xyz) * _3164._m0[_11089].w) + _3172._m0[_11089].w, 0.0, 1.0);
                float3 _11154 = _3164._m0[_11089].xyz * ((((_11118 * _11118) * _11141) * _11141) / fast::max(_11109, 9.9999997473787516355514526367188e-05));
                float3 _37513;
                if (_5914)
                {
                    float _37462;
                    do
                    {
                        uint _11190 = uint(_382._m21.z);
                        if (_11089 < _11190)
                        {
                            float _11212 = _382._m26[_11089].z * fast::max((_382._m15[_11089] * float4(in.m_3136, 1.0)).w, 0.0);
                            float4 _11236 = _382._m15[_11089] * float4((in.m_3136 + (_5909 * (_11212 * _382._m25.x))) + (_11123 * (_11212 * _382._m25.y)), 1.0);
                            float _11238 = _11236.w;
                            if (_11238 <= 0.0)
                            {
                                _37462 = 1.0;
                                break;
                            }
                            float3 _11247 = _11236.xyz / float3(_11238);
                            float _11249 = _11247.x;
                            bool _11250 = _11249 < 0.0;
                            bool _11257;
                            if (!_11250)
                            {
                                _11257 = _11249 > 1.0;
                            }
                            else
                            {
                                _11257 = _11250;
                            }
                            bool _11264;
                            if (!_11257)
                            {
                                _11264 = _11247.y < 0.0;
                            }
                            else
                            {
                                _11264 = _11257;
                            }
                            bool _11271;
                            if (!_11264)
                            {
                                _11271 = _11247.y > 1.0;
                            }
                            else
                            {
                                _11271 = _11264;
                            }
                            bool _11278;
                            if (!_11271)
                            {
                                _11278 = _11247.z > 1.0;
                            }
                            else
                            {
                                _11278 = _11271;
                            }
                            if (_11278)
                            {
                                _37462 = 1.0;
                                break;
                            }
                            float _11284 = _11247.z;
                            float2 _11450 = _382._m22.xy * 0.5;
                            float2 _11455 = _382._m26[_11089].xy + (_11247.xy * _382._m23.zw);
                            float4 _11468 = float4(_382._m26[_11089].xy + _11450, (_382._m26[_11089].xy + _382._m23.zw) - _11450);
                            float _37461;
                            do
                            {
                                int _11494 = int(_382._m22.z);
                                if (_11494 <= 0)
                                {
                                    float2 _11504 = fast::clamp(_11455, _11468.xy, _11468.zw);
                                    _37461 = spvDepthCast(_402).sample_compare(_402Smplr, float3(_11504, _11284).xy, _11284);
                                    break;
                                }
                                float2 _11517 = (_11455 / _382._m22.xy) + float2(0.5);
                                float2 _11518 = floor(_11517);
                                float2 _11523 = _11517 - _11518;
                                float2 _11526 = _11518 - float2(0.5);
                                bool _11530 = _11494 == 1;
                                if (_11530)
                                {
                                    float2 _11533 = _11523 * 2.0;
                                    _11478[0] = float2(3.0) - _11533;
                                    _11478[1] = float2(1.0) + _11533;
                                    _11479[0] = ((float2(2.0) - _11523) / _11478[0]) - float2(1.0);
                                    _11479[1] = (_11523 / _11478[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _11560 = _11523 * 3.0;
                                    _11478[0] = float2(4.0) - _11560;
                                    _11478[1] = float2(7.0);
                                    _11478[2] = float2(1.0) + _11560;
                                    _11479[0] = ((float2(3.0) - (_11523 * 2.0)) / _11478[0]) - float2(2.0);
                                    _11479[1] = (float2(3.0) + _11523) / _11478[1];
                                    _11479[2] = (_11523 / _11478[2]) + float2(2.0);
                                }
                                int _37914 = _11530 ? 2 : 3;
                                int _37451;
                                float _37454;
                                _37454 = 0.0;
                                _37451 = 0;
                                float _37460;
                                for (; _37451 < _37914; _37454 = _37460, _37451++)
                                {
                                    _37460 = _37454;
                                    for (int _37457 = 0; _37457 < _37914; )
                                    {
                                        _37460 += ((_11478[_37457].x * _11478[_37451].y) * spvDepthCast(_402).sample_compare(_402Smplr, float3(fast::clamp(_382._m22.xy * (_11526 + float2(_11479[_37457].x, _11479[_37451].y)), _11468.xy, _11468.zw), _11284).xy, _11284));
                                        _37457++;
                                        continue;
                                    }
                                }
                                _37461 = _37454 * (_11530 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _37462 = _37461;
                            break;
                        }
                        uint _11294 = _11089 - _11190;
                        if (_11294 >= uint(_382._m21.w))
                        {
                            _37462 = 1.0;
                            break;
                        }
                        float _11315 = _382._m27[_11294].w * length(in.m_3136 - _382._m27[_11294].xyz);
                        float3 _11333 = ((in.m_3136 + (_5909 * (_11315 * _382._m25.x))) + (_11123 * (_11315 * _382._m25.y))) - _382._m27[_11294].xyz;
                        float3 _11335 = abs(_11333);
                        float _11337 = _11335.x;
                        float _11339 = _11335.y;
                        bool _11340 = _11337 >= _11339;
                        bool _11348;
                        if (_11340)
                        {
                            _11348 = _11337 >= _11335.z;
                        }
                        else
                        {
                            _11348 = _11340;
                        }
                        float _37436;
                        int _37438;
                        if (_11348)
                        {
                            _37438 = (_11333.x > 0.0) ? 0 : 1;
                            _37436 = _11337;
                        }
                        else
                        {
                            float _11360 = _11335.z;
                            bool _11361 = _11339 >= _11360;
                            int _37439;
                            if (_11361)
                            {
                                _37439 = (_11333.y > 0.0) ? 2 : 3;
                            }
                            else
                            {
                                _37439 = (_11333.z > 0.0) ? 4 : 5;
                            }
                            _37438 = _37439;
                            _37436 = _11361 ? _11339 : _11360;
                        }
                        if (_37436 <= 0.0)
                        {
                            _37462 = 1.0;
                            break;
                        }
                        float2 _11398 = float2(dot(_11333, _1060[_37438]), dot(_11333, _1069[_37438])) / float2(_37436 * _382._m24.z);
                        float _11405 = _382._m28[_11294].z + (_382._m28[_11294].w / _37436);
                        if (_11405 > 1.0)
                        {
                            _37462 = 1.0;
                            break;
                        }
                        float2 _11423 = _382._m28[_11294].xy + (float2(float(spvSMod(_37438, 3)), float(_37438 / 3)) * _382._m24.xy);
                        float2 _11663 = _382._m22.xy * 0.5;
                        float2 _11668 = _11423 + (float2(0.5 + (0.5 * _11398.x), 0.5 - (0.5 * _11398.y)) * _382._m24.xy);
                        float4 _11681 = float4(_11423 + _11663, (_11423 + _382._m24.xy) - _11663);
                        float _37450;
                        do
                        {
                            int _11707 = int(_382._m22.z);
                            if (_11707 <= 0)
                            {
                                _37450 = spvDepthCast(_402).sample_compare(_402Smplr, float3(fast::clamp(_11668, _11681.xy, _11681.zw), _11405).xy, _11405);
                                break;
                            }
                            float2 _11730 = (_11668 / _382._m22.xy) + float2(0.5);
                            float2 _11731 = floor(_11730);
                            float2 _11736 = _11730 - _11731;
                            float2 _11739 = _11731 - float2(0.5);
                            bool _11743 = _11707 == 1;
                            if (_11743)
                            {
                                float2 _11746 = _11736 * 2.0;
                                _11691[0] = float2(3.0) - _11746;
                                _11691[1] = float2(1.0) + _11746;
                                _11692[0] = ((float2(2.0) - _11736) / _11691[0]) - float2(1.0);
                                _11692[1] = (_11736 / _11691[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _11773 = _11736 * 3.0;
                                _11691[0] = float2(4.0) - _11773;
                                _11691[1] = float2(7.0);
                                _11691[2] = float2(1.0) + _11773;
                                _11692[0] = ((float2(3.0) - (_11736 * 2.0)) / _11691[0]) - float2(2.0);
                                _11692[1] = (float2(3.0) + _11736) / _11691[1];
                                _11692[2] = (_11736 / _11691[2]) + float2(2.0);
                            }
                            int _37917 = _11743 ? 2 : 3;
                            int _37440;
                            float _37443;
                            _37443 = 0.0;
                            _37440 = 0;
                            float _37449;
                            for (; _37440 < _37917; _37443 = _37449, _37440++)
                            {
                                _37449 = _37443;
                                for (int _37446 = 0; _37446 < _37917; )
                                {
                                    _37449 += ((_11691[_37446].x * _11691[_37440].y) * spvDepthCast(_402).sample_compare(_402Smplr, float3(fast::clamp(_382._m22.xy * (_11739 + float2(_11692[_37446].x, _11692[_37440].y)), _11681.xy, _11681.zw), _11405).xy, _11405));
                                    _37446++;
                                    continue;
                                }
                            }
                            _37450 = _37443 * (_11743 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _37462 = _37450;
                        break;
                    } while(false);
                    _37513 = _11154 * _37462;
                }
                else
                {
                    _37513 = _11154;
                }
                float _6120 = dot(_35548, _11123);
                _6149 = _36597 + (((_35543 * fast::max(_6120, 0.0)) * _37513) + (_37513 * ((powr(fast::max(dot(_35548, fast::normalize(_11123 + _5898)), 0.0), _2975._m1.w) * _2975._m1.z) * step(0.0, _6120))));
            }
            _36595 = _36597;
        }
        else
        {
            _36595 = _36596;
        }
        _37172 = float3(0.0);
        _36594 = _36595;
    }
    else
    {
        float4 _6159 = _6154.sample(_2632, _5676);
        float _6166 = fast::clamp(_2975._m4.x * _6159.z, 0.0, 1.0);
        float _6173 = fast::clamp(_2975._m4.y * _6159.y, 0.04500000178813934326171875, 1.0);
        float _35577;
        float _35578;
        if (_35481 > 0.0)
        {
            _35578 = mix(_6166, _35514.y, _35481);
            _35577 = mix(_6173, fast::max(_35514.x, 0.04500000178813934326171875), _35481);
        }
        else
        {
            _35578 = _6166;
            _35577 = _6173;
        }
        float3 _36598;
        float3 _37181;
        if (_3372._m1.z > 0.5)
        {
            float2 _11976 = (in.m_5100 - float2(0.5)) * 2.0;
            float _11978 = length(_11976);
            bool _11984 = _11978 > 1.0;
            float2 _36234;
            if (_11984)
            {
                _36234 = _11976 / float2(_11978);
            }
            else
            {
                _36234 = _11976;
            }
            float3 _12483;
            float3 _36235;
            do
            {
                float _12443 = asin(fast::min(length(_36234), 1.0));
                float _12446 = asin(fast::clamp(_3372._m4.w, 0.0500000007450580596923828125, 0.949999988079071044921875));
                float _12450 = fast::min(_12443 / _12446, 1.0);
                float _12454 = 1.0 - (_12450 * _12450);
                float _12466 = precise::atan2(_36234.y, _36234.x + 9.999999717180685365747194737196e-10);
                float _12468 = sin(_12443);
                float _12470 = cos(_12466);
                float _12475 = sin(_12466);
                float _12478 = cos(_12443);
                float3 _12479 = float3(_12468 * _12470, _12468 * _12475, _12478);
                float _12482 = 1.0 + ((0.07999999821186065673828125 * _12454) * _12454);
                _12483 = _12479 * _12482;
                if (_12443 >= _12446)
                {
                    _36235 = _12479;
                    break;
                }
                _36235 = fast::normalize(_12479 + ((float3(_12478 * _12470, _12478 * _12475, -_12468) * (((0.319999992847442626953125 * _12450) * _12454) / _12446)) / float3(_12482)));
                break;
            } while(false);
            float3 _36236;
            if (_11984)
            {
                _36236 = float3(_36235.xy, -_36235.z);
            }
            else
            {
                _36236 = _36235;
            }
            float3 _36239;
            float3 _36240;
            float3 _36241;
            if (dot(in.m_3051.xyz, in.m_3051.xyz) < 9.9999999600419720025001879548654e-13)
            {
                float3 _12020 = fast::normalize(cross(_5909, float3(1.0, 0.0, 0.0)) + float3(0.0, 9.9999997473787516355514526367188e-05, 0.0));
                _36241 = _5909;
                _36240 = _12020;
                _36239 = cross(_12020, _5909);
            }
            else
            {
                float3 _12026 = fast::normalize(in.m_3051.xyz);
                float3 _12032 = _5909 - (_12026 * _36236.x);
                float _12034 = length(_12032);
                float2 _12042 = _36236.yz / float2(fast::max(length(_36236.yz), 9.9999999747524270787835121154785e-07));
                float3 _36237;
                if (_12034 > 9.9999999747524270787835121154785e-07)
                {
                    _36237 = _12032 / float3(_12034);
                }
                else
                {
                    _36237 = _5909;
                }
                float3 _12056 = cross(_12026, _36237);
                float _12058 = _12042.x;
                float _12062 = _12042.y;
                _36241 = (_36237 * _12062) + (_12056 * _12058);
                _36240 = (_36237 * _12058) - (_12056 * _12062);
                _36239 = _12026;
            }
            float _12088 = 1.08000004291534423828125 - _3372._m6.z;
            bool _12090 = _11978 < 1.0;
            bool _12097;
            if (_12090)
            {
                _12097 = _12483.z > _12088;
            }
            else
            {
                _12097 = _12090;
            }
            float3 _36246;
            float _36250;
            float _36252;
            if (_12097)
            {
                float3 _12102 = refract(-float3(dot(_5898, _36239), dot(_5898, _36240), dot(_5898, _36241)), _36236, 0.7485029697418212890625);
                float _12105 = _12102.z;
                float2 _36245;
                if (_12105 < (-0.001000000047497451305389404296875))
                {
                    _36245 = _12483.xy + (_12102.xy * ((_12088 - _12483.z) / _12105));
                }
                else
                {
                    _36245 = _11976;
                }
                float _12127 = length(_36245);
                float _12128 = smoothstep(_3372._m4.w - 0.0350000001490116119384765625, _3372._m4.w + 0.014999999664723873138427734375, _12127);
                float _12540 = _12127 / _3372._m4.w;
                float _12546 = precise::atan2(_36245.y, _36245.x + 9.999999717180685365747194737196e-10);
                float2 _12551 = float2(cos(_12546), sin(_12546));
                float3 _12558 = float3(_12551 * 26.0, _12540 * 2.2000000476837158203125);
                float3 _12643 = floor(_12558);
                float3 _12646 = _12558 - _12643;
                float3 _12654 = (_12646 * _12646) * (float3(3.0) - (_12646 * 2.0));
                uint3 _12721 = uint3(int3(_12643));
                uint _12734 = (((_12721.x * 1597334677u) ^ (_12721.y * 3812015801u)) ^ (_12721.z * 2798796415u)) * 1597334677u;
                uint3 _12749 = uint3(int3(_12643 + float3(1.0, 0.0, 0.0)));
                uint _12762 = (((_12749.x * 1597334677u) ^ (_12749.y * 3812015801u)) ^ (_12749.z * 2798796415u)) * 1597334677u;
                float _12663 = _12654.x;
                uint3 _12777 = uint3(int3(_12643 + float3(0.0, 1.0, 0.0)));
                uint _12790 = (((_12777.x * 1597334677u) ^ (_12777.y * 3812015801u)) ^ (_12777.z * 2798796415u)) * 1597334677u;
                uint3 _12805 = uint3(int3(_12643 + float3(1.0, 1.0, 0.0)));
                uint _12818 = (((_12805.x * 1597334677u) ^ (_12805.y * 3812015801u)) ^ (_12805.z * 2798796415u)) * 1597334677u;
                float _12679 = _12654.y;
                uint3 _12833 = uint3(int3(_12643 + float3(0.0, 0.0, 1.0)));
                uint _12846 = (((_12833.x * 1597334677u) ^ (_12833.y * 3812015801u)) ^ (_12833.z * 2798796415u)) * 1597334677u;
                uint3 _12861 = uint3(int3(_12643 + float3(1.0, 0.0, 1.0)));
                uint _12874 = (((_12861.x * 1597334677u) ^ (_12861.y * 3812015801u)) ^ (_12861.z * 2798796415u)) * 1597334677u;
                uint3 _12889 = uint3(int3(_12643 + float3(0.0, 1.0, 1.0)));
                uint _12902 = (((_12889.x * 1597334677u) ^ (_12889.y * 3812015801u)) ^ (_12889.z * 2798796415u)) * 1597334677u;
                uint3 _12917 = uint3(int3(_12643 + float3(1.0)));
                uint _12930 = (((_12917.x * 1597334677u) ^ (_12917.y * 3812015801u)) ^ (_12917.z * 2798796415u)) * 1597334677u;
                float3 _12568 = float3(_12551 * 61.0, (_12540 * 4.0) + 7.0);
                float3 _12956 = floor(_12568);
                float3 _12959 = _12568 - _12956;
                float3 _12967 = (_12959 * _12959) * (float3(3.0) - (_12959 * 2.0));
                uint3 _13034 = uint3(int3(_12956));
                uint _13047 = (((_13034.x * 1597334677u) ^ (_13034.y * 3812015801u)) ^ (_13034.z * 2798796415u)) * 1597334677u;
                uint3 _13062 = uint3(int3(_12956 + float3(1.0, 0.0, 0.0)));
                uint _13075 = (((_13062.x * 1597334677u) ^ (_13062.y * 3812015801u)) ^ (_13062.z * 2798796415u)) * 1597334677u;
                float _12976 = _12967.x;
                uint3 _13090 = uint3(int3(_12956 + float3(0.0, 1.0, 0.0)));
                uint _13103 = (((_13090.x * 1597334677u) ^ (_13090.y * 3812015801u)) ^ (_13090.z * 2798796415u)) * 1597334677u;
                uint3 _13118 = uint3(int3(_12956 + float3(1.0, 1.0, 0.0)));
                uint _13131 = (((_13118.x * 1597334677u) ^ (_13118.y * 3812015801u)) ^ (_13118.z * 2798796415u)) * 1597334677u;
                float _12992 = _12967.y;
                uint3 _13146 = uint3(int3(_12956 + float3(0.0, 0.0, 1.0)));
                uint _13159 = (((_13146.x * 1597334677u) ^ (_13146.y * 3812015801u)) ^ (_13146.z * 2798796415u)) * 1597334677u;
                uint3 _13174 = uint3(int3(_12956 + float3(1.0, 0.0, 1.0)));
                uint _13187 = (((_13174.x * 1597334677u) ^ (_13174.y * 3812015801u)) ^ (_13174.z * 2798796415u)) * 1597334677u;
                uint3 _13202 = uint3(int3(_12956 + float3(0.0, 1.0, 1.0)));
                uint _13215 = (((_13202.x * 1597334677u) ^ (_13202.y * 3812015801u)) ^ (_13202.z * 2798796415u)) * 1597334677u;
                uint3 _13230 = uint3(int3(_12956 + float3(1.0)));
                uint _13243 = (((_13230.x * 1597334677u) ^ (_13230.y * 3812015801u)) ^ (_13230.z * 2798796415u)) * 1597334677u;
                float3 _12579 = float3(_12551 * 9.0, (_12540 * 7.0) + 3.0);
                float3 _13269 = floor(_12579);
                float3 _13272 = _12579 - _13269;
                float3 _13280 = (_13272 * _13272) * (float3(3.0) - (_13272 * 2.0));
                uint3 _13347 = uint3(int3(_13269));
                uint _13360 = (((_13347.x * 1597334677u) ^ (_13347.y * 3812015801u)) ^ (_13347.z * 2798796415u)) * 1597334677u;
                uint3 _13375 = uint3(int3(_13269 + float3(1.0, 0.0, 0.0)));
                uint _13388 = (((_13375.x * 1597334677u) ^ (_13375.y * 3812015801u)) ^ (_13375.z * 2798796415u)) * 1597334677u;
                float _13289 = _13280.x;
                uint3 _13403 = uint3(int3(_13269 + float3(0.0, 1.0, 0.0)));
                uint _13416 = (((_13403.x * 1597334677u) ^ (_13403.y * 3812015801u)) ^ (_13403.z * 2798796415u)) * 1597334677u;
                uint3 _13431 = uint3(int3(_13269 + float3(1.0, 1.0, 0.0)));
                uint _13444 = (((_13431.x * 1597334677u) ^ (_13431.y * 3812015801u)) ^ (_13431.z * 2798796415u)) * 1597334677u;
                float _13305 = _13280.y;
                uint3 _13459 = uint3(int3(_13269 + float3(0.0, 0.0, 1.0)));
                uint _13472 = (((_13459.x * 1597334677u) ^ (_13459.y * 3812015801u)) ^ (_13459.z * 2798796415u)) * 1597334677u;
                uint3 _13487 = uint3(int3(_13269 + float3(1.0, 0.0, 1.0)));
                uint _13500 = (((_13487.x * 1597334677u) ^ (_13487.y * 3812015801u)) ^ (_13487.z * 2798796415u)) * 1597334677u;
                uint3 _13515 = uint3(int3(_13269 + float3(0.0, 1.0, 1.0)));
                uint _13528 = (((_13515.x * 1597334677u) ^ (_13515.y * 3812015801u)) ^ (_13515.z * 2798796415u)) * 1597334677u;
                uint3 _13543 = uint3(int3(_13269 + float3(1.0)));
                uint _13556 = (((_13543.x * 1597334677u) ^ (_13543.y * 3812015801u)) ^ (_13543.z * 2798796415u)) * 1597334677u;
                float _12583 = 1.10000002384185791015625 * ((mix(mix(mix(float((_12734 ^ (_12734 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_12762 ^ (_12762 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _12663), mix(float((_12790 ^ (_12790 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_12818 ^ (_12818 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _12663), _12679), mix(mix(float((_12846 ^ (_12846 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_12874 ^ (_12874 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _12663), mix(float((_12902 ^ (_12902 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_12930 ^ (_12930 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _12663), _12679), _12654.z) * 0.64999997615814208984375) + (mix(mix(mix(float((_13047 ^ (_13047 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_13075 ^ (_13075 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _12976), mix(float((_13103 ^ (_13103 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_13131 ^ (_13131 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _12976), _12992), mix(mix(float((_13159 ^ (_13159 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_13187 ^ (_13187 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _12976), mix(float((_13215 ^ (_13215 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_13243 ^ (_13243 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _12976), _12992), _12967.z) * 0.3499999940395355224609375));
                float3 _12606 = mix((_3372._m4.xyz * (0.449999988079071044921875 + _12583)) * mix(0.550000011920928955078125, 1.0, smoothstep(0.25, 0.550000011920928955078125, mix(mix(mix(float((_13360 ^ (_13360 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_13388 ^ (_13388 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _13289), mix(float((_13416 ^ (_13416 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_13444 ^ (_13444 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _13289), _13305), mix(mix(float((_13472 ^ (_13472 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_13500 ^ (_13500 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _13289), mix(float((_13528 ^ (_13528 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_13556 ^ (_13556 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _13289), _13305), _13280.z))), (_3372._m4.xyz * 1.7000000476837158203125) + float3(0.0500000007450580596923828125, 0.0350000001490116119384765625, 0.0), float3(exp(-powr((_12540 - (_3372._m5.w + 0.17000000178813934326171875)) * 11.111110687255859375, 2.0)) * 0.550000011920928955078125));
                float2 _13586 = _11976 / float2(fast::max(_11978, 9.9999997473787516355514526367188e-05));
                float3 _13594 = float3(_13586 * 6.0, (_11978 * 2.2000000476837158203125) + 1.7000000476837158203125);
                float3 _13655 = floor(_13594);
                float3 _13658 = _13594 - _13655;
                float3 _13666 = (_13658 * _13658) * (float3(3.0) - (_13658 * 2.0));
                uint3 _13733 = uint3(int3(_13655));
                uint _13746 = (((_13733.x * 1597334677u) ^ (_13733.y * 3812015801u)) ^ (_13733.z * 2798796415u)) * 1597334677u;
                uint3 _13761 = uint3(int3(_13655 + float3(1.0, 0.0, 0.0)));
                uint _13774 = (((_13761.x * 1597334677u) ^ (_13761.y * 3812015801u)) ^ (_13761.z * 2798796415u)) * 1597334677u;
                float _13675 = _13666.x;
                uint3 _13789 = uint3(int3(_13655 + float3(0.0, 1.0, 0.0)));
                uint _13802 = (((_13789.x * 1597334677u) ^ (_13789.y * 3812015801u)) ^ (_13789.z * 2798796415u)) * 1597334677u;
                uint3 _13817 = uint3(int3(_13655 + float3(1.0, 1.0, 0.0)));
                uint _13830 = (((_13817.x * 1597334677u) ^ (_13817.y * 3812015801u)) ^ (_13817.z * 2798796415u)) * 1597334677u;
                float _13691 = _13666.y;
                uint3 _13845 = uint3(int3(_13655 + float3(0.0, 0.0, 1.0)));
                uint _13858 = (((_13845.x * 1597334677u) ^ (_13845.y * 3812015801u)) ^ (_13845.z * 2798796415u)) * 1597334677u;
                uint3 _13873 = uint3(int3(_13655 + float3(1.0, 0.0, 1.0)));
                uint _13886 = (((_13873.x * 1597334677u) ^ (_13873.y * 3812015801u)) ^ (_13873.z * 2798796415u)) * 1597334677u;
                uint3 _13901 = uint3(int3(_13655 + float3(0.0, 1.0, 1.0)));
                uint _13914 = (((_13901.x * 1597334677u) ^ (_13901.y * 3812015801u)) ^ (_13901.z * 2798796415u)) * 1597334677u;
                uint3 _13929 = uint3(int3(_13655 + float3(1.0)));
                uint _13942 = (((_13929.x * 1597334677u) ^ (_13929.y * 3812015801u)) ^ (_13929.z * 2798796415u)) * 1597334677u;
                float3 _13603 = float3(_13586 * 15.0, (_11978 * 5.0) + 9.30000019073486328125);
                float3 _13968 = floor(_13603);
                float3 _13971 = _13603 - _13968;
                float3 _13979 = (_13971 * _13971) * (float3(3.0) - (_13971 * 2.0));
                uint3 _14046 = uint3(int3(_13968));
                uint _14059 = (((_14046.x * 1597334677u) ^ (_14046.y * 3812015801u)) ^ (_14046.z * 2798796415u)) * 1597334677u;
                uint3 _14074 = uint3(int3(_13968 + float3(1.0, 0.0, 0.0)));
                uint _14087 = (((_14074.x * 1597334677u) ^ (_14074.y * 3812015801u)) ^ (_14074.z * 2798796415u)) * 1597334677u;
                float _13988 = _13979.x;
                uint3 _14102 = uint3(int3(_13968 + float3(0.0, 1.0, 0.0)));
                uint _14115 = (((_14102.x * 1597334677u) ^ (_14102.y * 3812015801u)) ^ (_14102.z * 2798796415u)) * 1597334677u;
                uint3 _14130 = uint3(int3(_13968 + float3(1.0, 1.0, 0.0)));
                uint _14143 = (((_14130.x * 1597334677u) ^ (_14130.y * 3812015801u)) ^ (_14130.z * 2798796415u)) * 1597334677u;
                float _14004 = _13979.y;
                uint3 _14158 = uint3(int3(_13968 + float3(0.0, 0.0, 1.0)));
                uint _14171 = (((_14158.x * 1597334677u) ^ (_14158.y * 3812015801u)) ^ (_14158.z * 2798796415u)) * 1597334677u;
                uint3 _14186 = uint3(int3(_13968 + float3(1.0, 0.0, 1.0)));
                uint _14199 = (((_14186.x * 1597334677u) ^ (_14186.y * 3812015801u)) ^ (_14186.z * 2798796415u)) * 1597334677u;
                uint3 _14214 = uint3(int3(_13968 + float3(0.0, 1.0, 1.0)));
                uint _14227 = (((_14214.x * 1597334677u) ^ (_14214.y * 3812015801u)) ^ (_14214.z * 2798796415u)) * 1597334677u;
                uint3 _14242 = uint3(int3(_13968 + float3(1.0)));
                uint _14255 = (((_14242.x * 1597334677u) ^ (_14242.y * 3812015801u)) ^ (_14242.z * 2798796415u)) * 1597334677u;
                float _13620 = (0.5 * powr(1.0 - abs((2.0 * mix(mix(mix(float((_14059 ^ (_14059 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_14087 ^ (_14087 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _13988), mix(float((_14115 ^ (_14115 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_14143 ^ (_14143 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _13988), _14004), mix(mix(float((_14171 ^ (_14171 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_14199 ^ (_14199 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _13988), mix(float((_14227 ^ (_14227 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_14255 ^ (_14255 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _13988), _14004), _13979.z)) - 1.0), 30.0)) * smoothstep(0.60000002384185791015625, 0.89999997615814208984375, _11978);
                float _13629 = (powr(1.0 - abs((2.0 * mix(mix(mix(float((_13746 ^ (_13746 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_13774 ^ (_13774 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _13675), mix(float((_13802 ^ (_13802 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_13830 ^ (_13830 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _13675), _13691), mix(mix(float((_13858 ^ (_13858 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_13886 ^ (_13886 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _13675), mix(float((_13914 ^ (_13914 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_13942 ^ (_13942 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _13675), _13691), _13666.z)) - 1.0), 24.0) + _13620) * smoothstep(_3372._m4.w + 0.07999999821186065673828125, 0.949999988079071044921875, _11978);
                _36252 = _12128;
                _36250 = 1.0 - _12128;
                _36246 = mix(mix(float3(0.0040000001899898052215576171875), _12606 * (1.0 - ((_3372._m6.x * 0.85000002384185791015625) * smoothstep(0.7200000286102294921875, 1.0, _12540))), float3(smoothstep(_3372._m5.w - 0.02500000037252902984619140625, _3372._m5.w + 0.02500000037252902984619140625, _12540))), mix(_3372._m5.xyz * mix(float3(1.0), float3(1.019999980926513671875, 0.86000001430511474609375, 0.819999992847442626953125), float3(smoothstep(0.449999988079071044921875, 1.0, _11978))), float3(0.5, 0.070000000298023223876953125, 0.0599999986588954925537109375), float3(fast::clamp((_13629 * _3372._m6.y) * 1.39999997615814208984375, 0.0, 0.800000011920928955078125))) * (1.0 - (0.60000002384185791015625 * _3372._m6.x)), float3(_12128));
            }
            else
            {
                float2 _14285 = _11976 / float2(fast::max(_11978, 9.9999997473787516355514526367188e-05));
                float3 _14293 = float3(_14285 * 6.0, (_11978 * 2.2000000476837158203125) + 1.7000000476837158203125);
                float3 _14354 = floor(_14293);
                float3 _14357 = _14293 - _14354;
                float3 _14365 = (_14357 * _14357) * (float3(3.0) - (_14357 * 2.0));
                uint3 _14432 = uint3(int3(_14354));
                uint _14445 = (((_14432.x * 1597334677u) ^ (_14432.y * 3812015801u)) ^ (_14432.z * 2798796415u)) * 1597334677u;
                uint3 _14460 = uint3(int3(_14354 + float3(1.0, 0.0, 0.0)));
                uint _14473 = (((_14460.x * 1597334677u) ^ (_14460.y * 3812015801u)) ^ (_14460.z * 2798796415u)) * 1597334677u;
                float _14374 = _14365.x;
                uint3 _14488 = uint3(int3(_14354 + float3(0.0, 1.0, 0.0)));
                uint _14501 = (((_14488.x * 1597334677u) ^ (_14488.y * 3812015801u)) ^ (_14488.z * 2798796415u)) * 1597334677u;
                uint3 _14516 = uint3(int3(_14354 + float3(1.0, 1.0, 0.0)));
                uint _14529 = (((_14516.x * 1597334677u) ^ (_14516.y * 3812015801u)) ^ (_14516.z * 2798796415u)) * 1597334677u;
                float _14390 = _14365.y;
                uint3 _14544 = uint3(int3(_14354 + float3(0.0, 0.0, 1.0)));
                uint _14557 = (((_14544.x * 1597334677u) ^ (_14544.y * 3812015801u)) ^ (_14544.z * 2798796415u)) * 1597334677u;
                uint3 _14572 = uint3(int3(_14354 + float3(1.0, 0.0, 1.0)));
                uint _14585 = (((_14572.x * 1597334677u) ^ (_14572.y * 3812015801u)) ^ (_14572.z * 2798796415u)) * 1597334677u;
                uint3 _14600 = uint3(int3(_14354 + float3(0.0, 1.0, 1.0)));
                uint _14613 = (((_14600.x * 1597334677u) ^ (_14600.y * 3812015801u)) ^ (_14600.z * 2798796415u)) * 1597334677u;
                uint3 _14628 = uint3(int3(_14354 + float3(1.0)));
                uint _14641 = (((_14628.x * 1597334677u) ^ (_14628.y * 3812015801u)) ^ (_14628.z * 2798796415u)) * 1597334677u;
                float3 _14302 = float3(_14285 * 15.0, (_11978 * 5.0) + 9.30000019073486328125);
                float3 _14667 = floor(_14302);
                float3 _14670 = _14302 - _14667;
                float3 _14678 = (_14670 * _14670) * (float3(3.0) - (_14670 * 2.0));
                uint3 _14745 = uint3(int3(_14667));
                uint _14758 = (((_14745.x * 1597334677u) ^ (_14745.y * 3812015801u)) ^ (_14745.z * 2798796415u)) * 1597334677u;
                uint3 _14773 = uint3(int3(_14667 + float3(1.0, 0.0, 0.0)));
                uint _14786 = (((_14773.x * 1597334677u) ^ (_14773.y * 3812015801u)) ^ (_14773.z * 2798796415u)) * 1597334677u;
                float _14687 = _14678.x;
                uint3 _14801 = uint3(int3(_14667 + float3(0.0, 1.0, 0.0)));
                uint _14814 = (((_14801.x * 1597334677u) ^ (_14801.y * 3812015801u)) ^ (_14801.z * 2798796415u)) * 1597334677u;
                uint3 _14829 = uint3(int3(_14667 + float3(1.0, 1.0, 0.0)));
                uint _14842 = (((_14829.x * 1597334677u) ^ (_14829.y * 3812015801u)) ^ (_14829.z * 2798796415u)) * 1597334677u;
                float _14703 = _14678.y;
                uint3 _14857 = uint3(int3(_14667 + float3(0.0, 0.0, 1.0)));
                uint _14870 = (((_14857.x * 1597334677u) ^ (_14857.y * 3812015801u)) ^ (_14857.z * 2798796415u)) * 1597334677u;
                uint3 _14885 = uint3(int3(_14667 + float3(1.0, 0.0, 1.0)));
                uint _14898 = (((_14885.x * 1597334677u) ^ (_14885.y * 3812015801u)) ^ (_14885.z * 2798796415u)) * 1597334677u;
                uint3 _14913 = uint3(int3(_14667 + float3(0.0, 1.0, 1.0)));
                uint _14926 = (((_14913.x * 1597334677u) ^ (_14913.y * 3812015801u)) ^ (_14913.z * 2798796415u)) * 1597334677u;
                uint3 _14941 = uint3(int3(_14667 + float3(1.0)));
                uint _14954 = (((_14941.x * 1597334677u) ^ (_14941.y * 3812015801u)) ^ (_14941.z * 2798796415u)) * 1597334677u;
                float _14319 = (0.5 * powr(1.0 - abs((2.0 * mix(mix(mix(float((_14758 ^ (_14758 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_14786 ^ (_14786 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _14687), mix(float((_14814 ^ (_14814 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_14842 ^ (_14842 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _14687), _14703), mix(mix(float((_14870 ^ (_14870 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_14898 ^ (_14898 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _14687), mix(float((_14926 ^ (_14926 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_14954 ^ (_14954 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _14687), _14703), _14678.z)) - 1.0), 30.0)) * smoothstep(0.60000002384185791015625, 0.89999997615814208984375, _11978);
                float _14328 = (powr(1.0 - abs((2.0 * mix(mix(mix(float((_14445 ^ (_14445 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_14473 ^ (_14473 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _14374), mix(float((_14501 ^ (_14501 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_14529 ^ (_14529 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _14374), _14390), mix(mix(float((_14557 ^ (_14557 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_14585 ^ (_14585 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _14374), mix(float((_14613 ^ (_14613 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_14641 ^ (_14641 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _14374), _14390), _14365.z)) - 1.0), 24.0) + _14319) * smoothstep(_3372._m4.w + 0.07999999821186065673828125, 0.949999988079071044921875, _11978);
                _36252 = 1.0;
                _36250 = 0.0;
                _36246 = mix(_3372._m5.xyz * mix(float3(1.0), float3(1.019999980926513671875, 0.86000001430511474609375, 0.819999992847442626953125), float3(smoothstep(0.449999988079071044921875, 1.0, _11978))), float3(0.5, 0.070000000298023223876953125, 0.0599999986588954925537109375), float3(fast::clamp((_14328 * _3372._m6.y) * 1.39999997615814208984375, 0.0, 0.800000011920928955078125))) * (1.0 - ((_3372._m6.x * 0.3499999940395355224609375) * (1.0 - smoothstep(_3372._m4.w, _3372._m4.w + 0.070000000298023223876953125, _11978))));
            }
            float _12188 = _11976.y;
            float _12203 = _11984 ? 0.20000000298023223876953125 : (((1.0 - (0.64999997615814208984375 * smoothstep(0.449999988079071044921875, 0.949999988079071044921875, abs(_11976.x)))) * (1.0 - (0.449999988079071044921875 * smoothstep(0.1500000059604644775390625, 0.60000002384185791015625, _12188)))) * (1.0 - (0.300000011920928955078125 * smoothstep(0.25, 0.699999988079071044921875, -_12188))));
            float _12205 = mix(1.0, _12203, 0.60000002384185791015625);
            float _12208 = dot(_5909, _5891);
            float3 _12242 = mix(_5909, _36241, float3(_36250));
            float3 _12246 = reflect(-_5898, _5909);
            bool _14979 = _382._m29.x > 0.5;
            float3 _36270;
            float3 _36280;
            if (_14979)
            {
                float _15066 = _12242.x;
                float _15071 = _12242.z;
                float _15073 = (_382._m29.z * _15066) - (_382._m29.w * _15071);
                float _15075 = _12242.y;
                float _15086 = (_382._m29.w * _15066) + (_382._m29.z * _15071);
                float _15104 = 1.09254801273345947265625 * _15073;
                spvUnsafeArray<float, 9> _32930 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _15075, 0.48860299587249755859375 * _15086, 0.48860299587249755859375 * _15073, _15104 * _15075, (1.09254801273345947265625 * _15075) * _15086, 0.3153919875621795654296875 * (((3.0 * _15086) * _15086) - 1.0), _15104 * _15086, 0.546274006366729736328125 * ((_15073 * _15073) - (_15075 * _15075)) });
                spvUnsafeArray<float, 9> _15018 = _32930;
                float3 _36255;
                _36255 = float3(0.0);
                for (int _36254 = 0; _36254 < 9; )
                {
                    _36255 += (_2630.read(uint2((int2(496, 256) + int2(_36254, 0))), 0).xyz * _15018[_36254]);
                    _36254++;
                    continue;
                }
                float _15199 = _12246.x;
                float _15204 = _12246.z;
                float2 _15236 = float2((precise::atan2((_382._m29.z * _15199) - (_382._m29.w * _15204), -((_382._m29.w * _15199) + (_382._m29.z * _15204))) * 0.15915493667125701904296875) + 0.5, acos(fast::clamp(_12246.y, -1.0, 1.0)) * 0.3183098733425140380859375);
                float2 _15257 = (_15236 * float2(512.0, 256.0)) - float2(0.5);
                float2 _15259 = floor(_15257);
                float2 _15262 = _15257 - _15259;
                int _15265 = int(_15259.x);
                int _15268 = int(_15259.y);
                int _36256;
                if (_15265 < 0)
                {
                    _36256 = _15265 + 512;
                }
                else
                {
                    _36256 = _15265;
                }
                int _36257;
                if (_36256 >= 512)
                {
                    _36257 = _36256 - 512;
                }
                else
                {
                    _36257 = _36256;
                }
                int _15288 = _36257 + 1;
                int _37918 = (_15288 == 512) ? 0 : _15288;
                int _15303 = min((_15268 + 1), 255);
                int _15305 = max(_15268, 0);
                float3 _15358 = float3(_15262.x);
                float2 _15390 = (_15236 * float2(256.0, 128.0)) - float2(0.5);
                float2 _15392 = floor(_15390);
                float2 _15395 = _15390 - _15392;
                int _15398 = int(_15392.x);
                int _15401 = int(_15392.y);
                int _36263;
                if (_15398 < 0)
                {
                    _36263 = _15398 + 256;
                }
                else
                {
                    _36263 = _15398;
                }
                int _36264;
                if (_36263 >= 256)
                {
                    _36264 = _36263 - 256;
                }
                else
                {
                    _36264 = _36263;
                }
                int _15421 = _36264 + 1;
                int _37919 = (_15421 == 256) ? 0 : _15421;
                int _15436 = min((_15401 + 1), 127);
                int _15438 = max(_15401, 0);
                float3 _15491 = float3(_15395.x);
                _36280 = mix(mix(mix(_2630.read(uint2(int2(_36257, _15305)), 0).xyz, _2630.read(uint2(int2(_37918, _15305)), 0).xyz, _15358), mix(_2630.read(uint2(int2(_36257, _15303)), 0).xyz, _2630.read(uint2(int2(_37918, _15303)), 0).xyz, _15358), float3(_15262.y)), mix(mix(_2630.read(uint2((int2(0, 256) + int2(_36264, _15438))), 0).xyz, _2630.read(uint2((int2(0, 256) + int2(_37919, _15438))), 0).xyz, _15491), mix(_2630.read(uint2((int2(0, 256) + int2(_36264, _15436))), 0).xyz, _2630.read(uint2((int2(0, 256) + int2(_37919, _15436))), 0).xyz, _15491), float3(_15395.y)), float3(0.3499999940395355224609375)) * _382._m29.y;
                _36270 = fast::max(_36255, float3(0.0)) * _382._m29.y;
            }
            else
            {
                float3 _15519 = mix(_382._m9.xyz, _382._m8.xyz, float3((_12242.y * 0.5) + 0.5)) * _382._m8.w;
                _36280 = mix(mix(_382._m9.xyz, _382._m8.xyz, float3((_12246.y * 0.5) + 0.5)) * _382._m8.w, _15519, float3(0.070000000298023223876953125));
                _36270 = _15519;
            }
            float3 _36371;
            if (_382._m34.y > 0.5)
            {
                int _15656 = int(_382._m34.y);
                int _15659 = int(_382._m34.x);
                float3 _36278;
                _36278 = _36270;
                float3 _37661;
                for (int _36277 = 0; _36277 < _15656; _36278 = _37661, _36277++)
                {
                    int _15671 = 8 * (_15659 + _36277);
                    float4 _15880 = as_type<float4>(_1380._m0[_15671 + 3]);
                    float4 _15924 = as_type<float4>(_1380._m0[_15671]);
                    float4 _15930 = as_type<float4>(_1380._m0[_15671 + 1]);
                    float4 _15936 = as_type<float4>(_1380._m0[_15671 + 2]);
                    float3 _15898 = _15924.xyz;
                    float _15902 = _15924.w;
                    float3 _15905 = _15930.xyz;
                    float _15909 = _15930.w;
                    float3 _15912 = _15936.xyz;
                    float _15916 = _15936.w;
                    float3 _15918 = float3(dot(_15898, in.m_3136) + _15902, dot(_15905, in.m_3136) + _15909, dot(_15912, in.m_3136) + _15916);
                    float3 _15680 = _15880.xyz;
                    float _15682 = _15880.w;
                    float _36562;
                    do
                    {
                        float3 _15948 = _15680 - abs(_15918);
                        float _15956 = fast::min(_15948.x, fast::min(_15948.y, _15948.z));
                        if (_15956 <= 0.0)
                        {
                            _36562 = 0.0;
                            break;
                        }
                        if (_15682 <= 0.0)
                        {
                            _36562 = 1.0;
                            break;
                        }
                        float _15968 = fast::min(_15956 / _15682, 1.0);
                        _36562 = (_15968 * _15968) * (3.0 - (2.0 * _15968));
                        break;
                    } while(false);
                    if (_36562 <= 0.0)
                    {
                        _37661 = _36278;
                        continue;
                    }
                    float3 _15691 = as_type<float4>(_1380._m0[_15671 + 4]).xyz;
                    float4 _15989 = as_type<float4>(_1380._m0[_15671 + 5]);
                    int _15995 = int(((device uint*)&_1380._m0[_15671 + 6])[0u]);
                    float _16005 = dot(_15898, _12242);
                    float _16011 = dot(_15905, _12242);
                    float _16017 = dot(_15912, _12242);
                    float3 _16018 = float3(_16005, _16011, _16017);
                    float3 _15711 = (in.m_3136 + (_12242 * _15989.x)) + (_5898 * _15989.y);
                    float3 _15730 = fast::clamp((((float3(dot(_15898, _15711) + _15902, dot(_15905, _15711) + _15909, dot(_15912, _15711) + _15916) + _15680) / fast::max(_15680 * 2.0, float3(9.9999999747524270787835121154785e-07))) * _15691) - float3(0.5), float3(0.0), _15691 - float3(1.0));
                    int3 _15732 = int3(_15691);
                    int3 _15739 = min(int3(_15730), max((_15732 - int3(2)), int3(0)));
                    float3 _15743 = _15730 - float3(_15739);
                    float _16098 = 0.48860299587249755859375 * _16011;
                    float _16101 = 0.48860299587249755859375 * _16017;
                    float _16104 = 0.48860299587249755859375 * _16005;
                    float _16109 = 1.09254801273345947265625 * _16005;
                    float _16112 = _16109 * _16011;
                    float _16118 = (1.09254801273345947265625 * _16011) * _16017;
                    float _16126 = 0.3153919875621795654296875 * (((3.0 * _16017) * _16017) - 1.0);
                    float _16132 = _16109 * _16017;
                    float _16146 = 0.546274006366729736328125 * ((_16005 * _16005) - (_16011 * _16011));
                    int3 _16165 = _15732 - int3(1);
                    int3 _16166 = min(_15739, _16165);
                    int _16171 = _15732.x;
                    int _16175 = _15732.y;
                    int _16183 = _15995 + ((_16166.x + (_16171 * (_16166.y + (_16175 * _16166.z)))) * 4);
                    float3 _16186 = float3(1.0) - _15743;
                    float3 _16204 = (((((float3(_16166) + float3(0.5)) / _15691) * _15680) * 2.0) - _15680) - _15918;
                    float _16214 = dot(_16204 * rsqrt(fast::max(dot(_16204, _16204), 1.0000000133514319600180897396058e-10)), _16018) + 1.0;
                    float _16217 = _16186.x;
                    float _16219 = _16186.y;
                    float _16220 = _16217 * _16219;
                    float _16222 = _16186.z;
                    int _16246 = _16183 + 3;
                    float _16232 = ((_16220 * _16222) * ((0.25 * (_16214 * _16214)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1380._m0[_16246])[1u])).y > 0.5);
                    int _16276 = _16183 + 1;
                    int _16280 = _16183 + 2;
                    float2 _16292 = float2(as_type<half2>(_1380._m0[_16183].y));
                    float2 _16301 = float2(as_type<half2>(_1380._m0[_16276].x));
                    float2 _16310 = float2(as_type<half2>(_1380._m0[_16276].w));
                    float2 _16319 = float2(as_type<half2>(_1380._m0[_16280].z));
                    float3 _16407 = (((((((float3(float2(as_type<half2>(_1380._m0[_16183].x)), _16292.x) * 0.2820949852466583251953125) + (float3(_16292.y, float2(as_type<half2>(_1380._m0[_16183].z))) * _16098)) + (float3(float2(as_type<half2>(_1380._m0[_16183].w)), _16301.x) * _16101)) + (float3(_16301.y, float2(as_type<half2>(_1380._m0[_16276].y))) * _16104)) + (float3(float2(as_type<half2>(_1380._m0[_16276].z)), _16310.x) * _16112)) + (float3(_16310.y, float2(as_type<half2>(_1380._m0[_16280].x))) * _16118)) + (float3(float2(as_type<half2>(_1380._m0[_16280].y)), _16319.x) * _16126)) + (float3(_16319.y, float2(as_type<half2>(_1380._m0[_16280].w))) * _16132);
                    int3 _16435 = min((_15739 + int3(1, 0, 0)), _16165);
                    int _16452 = _15995 + ((_16435.x + (_16171 * (_16435.y + (_16175 * _16435.z)))) * 4);
                    float3 _16473 = (((((float3(_16435) + float3(0.5)) / _15691) * _15680) * 2.0) - _15680) - _15918;
                    float _16483 = dot(_16473 * rsqrt(fast::max(dot(_16473, _16473), 1.0000000133514319600180897396058e-10)), _16018) + 1.0;
                    float _16486 = _15743.x;
                    float _16489 = _16486 * _16219;
                    int _16515 = _16452 + 3;
                    float _16501 = ((_16489 * _16222) * ((0.25 * (_16483 * _16483)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1380._m0[_16515])[1u])).y > 0.5);
                    int _16545 = _16452 + 1;
                    int _16549 = _16452 + 2;
                    float2 _16561 = float2(as_type<half2>(_1380._m0[_16452].y));
                    float2 _16570 = float2(as_type<half2>(_1380._m0[_16545].x));
                    float2 _16579 = float2(as_type<half2>(_1380._m0[_16545].w));
                    float2 _16588 = float2(as_type<half2>(_1380._m0[_16549].z));
                    float3 _16676 = (((((((float3(float2(as_type<half2>(_1380._m0[_16452].x)), _16561.x) * 0.2820949852466583251953125) + (float3(_16561.y, float2(as_type<half2>(_1380._m0[_16452].z))) * _16098)) + (float3(float2(as_type<half2>(_1380._m0[_16452].w)), _16570.x) * _16101)) + (float3(_16570.y, float2(as_type<half2>(_1380._m0[_16545].y))) * _16104)) + (float3(float2(as_type<half2>(_1380._m0[_16545].z)), _16579.x) * _16112)) + (float3(_16579.y, float2(as_type<half2>(_1380._m0[_16549].x))) * _16118)) + (float3(float2(as_type<half2>(_1380._m0[_16549].y)), _16588.x) * _16126)) + (float3(_16588.y, float2(as_type<half2>(_1380._m0[_16549].w))) * _16132);
                    int3 _16704 = min((_15739 + int3(0, 1, 0)), _16165);
                    int _16721 = _15995 + ((_16704.x + (_16171 * (_16704.y + (_16175 * _16704.z)))) * 4);
                    float3 _16742 = (((((float3(_16704) + float3(0.5)) / _15691) * _15680) * 2.0) - _15680) - _15918;
                    float _16752 = dot(_16742 * rsqrt(fast::max(dot(_16742, _16742), 1.0000000133514319600180897396058e-10)), _16018) + 1.0;
                    float _16757 = _15743.y;
                    float _16758 = _16217 * _16757;
                    int _16784 = _16721 + 3;
                    float _16770 = ((_16758 * _16222) * ((0.25 * (_16752 * _16752)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1380._m0[_16784])[1u])).y > 0.5);
                    int _16814 = _16721 + 1;
                    int _16818 = _16721 + 2;
                    float2 _16830 = float2(as_type<half2>(_1380._m0[_16721].y));
                    float2 _16839 = float2(as_type<half2>(_1380._m0[_16814].x));
                    float2 _16848 = float2(as_type<half2>(_1380._m0[_16814].w));
                    float2 _16857 = float2(as_type<half2>(_1380._m0[_16818].z));
                    float3 _16945 = (((((((float3(float2(as_type<half2>(_1380._m0[_16721].x)), _16830.x) * 0.2820949852466583251953125) + (float3(_16830.y, float2(as_type<half2>(_1380._m0[_16721].z))) * _16098)) + (float3(float2(as_type<half2>(_1380._m0[_16721].w)), _16839.x) * _16101)) + (float3(_16839.y, float2(as_type<half2>(_1380._m0[_16814].y))) * _16104)) + (float3(float2(as_type<half2>(_1380._m0[_16814].z)), _16848.x) * _16112)) + (float3(_16848.y, float2(as_type<half2>(_1380._m0[_16818].x))) * _16118)) + (float3(float2(as_type<half2>(_1380._m0[_16818].y)), _16857.x) * _16126)) + (float3(_16857.y, float2(as_type<half2>(_1380._m0[_16818].w))) * _16132);
                    int3 _16973 = min((_15739 + int3(1, 1, 0)), _16165);
                    int _16990 = _15995 + ((_16973.x + (_16171 * (_16973.y + (_16175 * _16973.z)))) * 4);
                    float3 _17011 = (((((float3(_16973) + float3(0.5)) / _15691) * _15680) * 2.0) - _15680) - _15918;
                    float _17021 = dot(_17011 * rsqrt(fast::max(dot(_17011, _17011), 1.0000000133514319600180897396058e-10)), _16018) + 1.0;
                    float _17027 = _16486 * _16757;
                    int _17053 = _16990 + 3;
                    float _17039 = ((_17027 * _16222) * ((0.25 * (_17021 * _17021)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1380._m0[_17053])[1u])).y > 0.5);
                    int _17083 = _16990 + 1;
                    int _17087 = _16990 + 2;
                    float2 _17099 = float2(as_type<half2>(_1380._m0[_16990].y));
                    float2 _17108 = float2(as_type<half2>(_1380._m0[_17083].x));
                    float2 _17117 = float2(as_type<half2>(_1380._m0[_17083].w));
                    float2 _17126 = float2(as_type<half2>(_1380._m0[_17087].z));
                    float3 _17214 = (((((((float3(float2(as_type<half2>(_1380._m0[_16990].x)), _17099.x) * 0.2820949852466583251953125) + (float3(_17099.y, float2(as_type<half2>(_1380._m0[_16990].z))) * _16098)) + (float3(float2(as_type<half2>(_1380._m0[_16990].w)), _17108.x) * _16101)) + (float3(_17108.y, float2(as_type<half2>(_1380._m0[_17083].y))) * _16104)) + (float3(float2(as_type<half2>(_1380._m0[_17083].z)), _17117.x) * _16112)) + (float3(_17117.y, float2(as_type<half2>(_1380._m0[_17087].x))) * _16118)) + (float3(float2(as_type<half2>(_1380._m0[_17087].y)), _17126.x) * _16126)) + (float3(_17126.y, float2(as_type<half2>(_1380._m0[_17087].w))) * _16132);
                    int3 _17242 = min((_15739 + int3(0, 0, 1)), _16165);
                    int _17259 = _15995 + ((_17242.x + (_16171 * (_17242.y + (_16175 * _17242.z)))) * 4);
                    float3 _17280 = (((((float3(_17242) + float3(0.5)) / _15691) * _15680) * 2.0) - _15680) - _15918;
                    float _17290 = dot(_17280 * rsqrt(fast::max(dot(_17280, _17280), 1.0000000133514319600180897396058e-10)), _16018) + 1.0;
                    float _17298 = _15743.z;
                    int _17322 = _17259 + 3;
                    float _17308 = ((_16220 * _17298) * ((0.25 * (_17290 * _17290)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1380._m0[_17322])[1u])).y > 0.5);
                    int _17352 = _17259 + 1;
                    int _17356 = _17259 + 2;
                    float2 _17368 = float2(as_type<half2>(_1380._m0[_17259].y));
                    float2 _17377 = float2(as_type<half2>(_1380._m0[_17352].x));
                    float2 _17386 = float2(as_type<half2>(_1380._m0[_17352].w));
                    float2 _17395 = float2(as_type<half2>(_1380._m0[_17356].z));
                    float3 _17483 = (((((((float3(float2(as_type<half2>(_1380._m0[_17259].x)), _17368.x) * 0.2820949852466583251953125) + (float3(_17368.y, float2(as_type<half2>(_1380._m0[_17259].z))) * _16098)) + (float3(float2(as_type<half2>(_1380._m0[_17259].w)), _17377.x) * _16101)) + (float3(_17377.y, float2(as_type<half2>(_1380._m0[_17352].y))) * _16104)) + (float3(float2(as_type<half2>(_1380._m0[_17352].z)), _17386.x) * _16112)) + (float3(_17386.y, float2(as_type<half2>(_1380._m0[_17356].x))) * _16118)) + (float3(float2(as_type<half2>(_1380._m0[_17356].y)), _17395.x) * _16126)) + (float3(_17395.y, float2(as_type<half2>(_1380._m0[_17356].w))) * _16132);
                    float4 _15810 = (((float4((_16407 + (float3(float2(as_type<half2>(_1380._m0[_16246].x)), float2(as_type<half2>(_1380._m0[_16246].y)).x) * _16146)) * _16232, _16232) + float4((_16676 + (float3(float2(as_type<half2>(_1380._m0[_16515].x)), float2(as_type<half2>(_1380._m0[_16515].y)).x) * _16146)) * _16501, _16501)) + float4((_16945 + (float3(float2(as_type<half2>(_1380._m0[_16784].x)), float2(as_type<half2>(_1380._m0[_16784].y)).x) * _16146)) * _16770, _16770)) + float4((_17214 + (float3(float2(as_type<half2>(_1380._m0[_17053].x)), float2(as_type<half2>(_1380._m0[_17053].y)).x) * _16146)) * _17039, _17039)) + float4((_17483 + (float3(float2(as_type<half2>(_1380._m0[_17322].x)), float2(as_type<half2>(_1380._m0[_17322].y)).x) * _16146)) * _17308, _17308);
                    int3 _17511 = min((_15739 + int3(1, 0, 1)), _16165);
                    int _17528 = _15995 + ((_17511.x + (_16171 * (_17511.y + (_16175 * _17511.z)))) * 4);
                    float3 _17549 = (((((float3(_17511) + float3(0.5)) / _15691) * _15680) * 2.0) - _15680) - _15918;
                    float _17559 = dot(_17549 * rsqrt(fast::max(dot(_17549, _17549), 1.0000000133514319600180897396058e-10)), _16018) + 1.0;
                    int _17591 = _17528 + 3;
                    float _17577 = ((_16489 * _17298) * ((0.25 * (_17559 * _17559)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1380._m0[_17591])[1u])).y > 0.5);
                    int _17621 = _17528 + 1;
                    int _17625 = _17528 + 2;
                    float2 _17637 = float2(as_type<half2>(_1380._m0[_17528].y));
                    float2 _17646 = float2(as_type<half2>(_1380._m0[_17621].x));
                    float2 _17655 = float2(as_type<half2>(_1380._m0[_17621].w));
                    float2 _17664 = float2(as_type<half2>(_1380._m0[_17625].z));
                    float3 _17752 = (((((((float3(float2(as_type<half2>(_1380._m0[_17528].x)), _17637.x) * 0.2820949852466583251953125) + (float3(_17637.y, float2(as_type<half2>(_1380._m0[_17528].z))) * _16098)) + (float3(float2(as_type<half2>(_1380._m0[_17528].w)), _17646.x) * _16101)) + (float3(_17646.y, float2(as_type<half2>(_1380._m0[_17621].y))) * _16104)) + (float3(float2(as_type<half2>(_1380._m0[_17621].z)), _17655.x) * _16112)) + (float3(_17655.y, float2(as_type<half2>(_1380._m0[_17625].x))) * _16118)) + (float3(float2(as_type<half2>(_1380._m0[_17625].y)), _17664.x) * _16126)) + (float3(_17664.y, float2(as_type<half2>(_1380._m0[_17625].w))) * _16132);
                    int3 _17780 = min((_15739 + int3(0, 1, 1)), _16165);
                    int _17797 = _15995 + ((_17780.x + (_16171 * (_17780.y + (_16175 * _17780.z)))) * 4);
                    float3 _17818 = (((((float3(_17780) + float3(0.5)) / _15691) * _15680) * 2.0) - _15680) - _15918;
                    float _17828 = dot(_17818 * rsqrt(fast::max(dot(_17818, _17818), 1.0000000133514319600180897396058e-10)), _16018) + 1.0;
                    int _17860 = _17797 + 3;
                    float _17846 = ((_16758 * _17298) * ((0.25 * (_17828 * _17828)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1380._m0[_17860])[1u])).y > 0.5);
                    int _17890 = _17797 + 1;
                    int _17894 = _17797 + 2;
                    float2 _17906 = float2(as_type<half2>(_1380._m0[_17797].y));
                    float2 _17915 = float2(as_type<half2>(_1380._m0[_17890].x));
                    float2 _17924 = float2(as_type<half2>(_1380._m0[_17890].w));
                    float2 _17933 = float2(as_type<half2>(_1380._m0[_17894].z));
                    float3 _18021 = (((((((float3(float2(as_type<half2>(_1380._m0[_17797].x)), _17906.x) * 0.2820949852466583251953125) + (float3(_17906.y, float2(as_type<half2>(_1380._m0[_17797].z))) * _16098)) + (float3(float2(as_type<half2>(_1380._m0[_17797].w)), _17915.x) * _16101)) + (float3(_17915.y, float2(as_type<half2>(_1380._m0[_17890].y))) * _16104)) + (float3(float2(as_type<half2>(_1380._m0[_17890].z)), _17924.x) * _16112)) + (float3(_17924.y, float2(as_type<half2>(_1380._m0[_17894].x))) * _16118)) + (float3(float2(as_type<half2>(_1380._m0[_17894].y)), _17933.x) * _16126)) + (float3(_17933.y, float2(as_type<half2>(_1380._m0[_17894].w))) * _16132);
                    int3 _18049 = min((_15739 + int3(1)), _16165);
                    int _18066 = _15995 + ((_18049.x + (_16171 * (_18049.y + (_16175 * _18049.z)))) * 4);
                    float3 _18087 = (((((float3(_18049) + float3(0.5)) / _15691) * _15680) * 2.0) - _15680) - _15918;
                    float _18097 = dot(_18087 * rsqrt(fast::max(dot(_18087, _18087), 1.0000000133514319600180897396058e-10)), _16018) + 1.0;
                    int _18129 = _18066 + 3;
                    float _18115 = ((_17027 * _17298) * ((0.25 * (_18097 * _18097)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1380._m0[_18129])[1u])).y > 0.5);
                    int _18159 = _18066 + 1;
                    int _18163 = _18066 + 2;
                    float2 _18175 = float2(as_type<half2>(_1380._m0[_18066].y));
                    float2 _18184 = float2(as_type<half2>(_1380._m0[_18159].x));
                    float2 _18193 = float2(as_type<half2>(_1380._m0[_18159].w));
                    float2 _18202 = float2(as_type<half2>(_1380._m0[_18163].z));
                    float3 _18290 = (((((((float3(float2(as_type<half2>(_1380._m0[_18066].x)), _18175.x) * 0.2820949852466583251953125) + (float3(_18175.y, float2(as_type<half2>(_1380._m0[_18066].z))) * _16098)) + (float3(float2(as_type<half2>(_1380._m0[_18066].w)), _18184.x) * _16101)) + (float3(_18184.y, float2(as_type<half2>(_1380._m0[_18159].y))) * _16104)) + (float3(float2(as_type<half2>(_1380._m0[_18159].z)), _18193.x) * _16112)) + (float3(_18193.y, float2(as_type<half2>(_1380._m0[_18163].x))) * _16118)) + (float3(float2(as_type<half2>(_1380._m0[_18163].y)), _18202.x) * _16126)) + (float3(_18202.y, float2(as_type<half2>(_1380._m0[_18163].w))) * _16132);
                    float4 _15849 = ((_15810 + float4((_17752 + (float3(float2(as_type<half2>(_1380._m0[_17591].x)), float2(as_type<half2>(_1380._m0[_17591].y)).x) * _16146)) * _17577, _17577)) + float4((_18021 + (float3(float2(as_type<half2>(_1380._m0[_17860].x)), float2(as_type<half2>(_1380._m0[_17860].y)).x) * _16146)) * _17846, _17846)) + float4((_18290 + (float3(float2(as_type<half2>(_1380._m0[_18129].x)), float2(as_type<half2>(_1380._m0[_18129].y)).x) * _16146)) * _18115, _18115);
                    float _15853 = _15849.w;
                    float3 _37662;
                    if (_15853 > 9.9999997473787516355514526367188e-06)
                    {
                        _37662 = mix(_36278, (fast::max(_15849.xyz, float3(0.0)) / float3(_15853)) * _15989.z, float3(_36562));
                    }
                    else
                    {
                        _37662 = _36278;
                    }
                    _37661 = _37662;
                }
                _36371 = _36278;
            }
            else
            {
                _36371 = _36270;
            }
            float3 _36392;
            if (_382._m34.x > 0.5)
            {
                int _18338 = int(_382._m34.x);
                float _36283;
                float3 _36349;
                _36349 = float3(0.0);
                _36283 = 0.0;
                float _37666;
                float3 _37667;
                for (int _36282 = 0; _36282 < _18338; _36349 = _37667, _36283 = _37666, _36282++)
                {
                    if (_36283 > 0.999000012874603271484375)
                    {
                        break;
                    }
                    int _18350 = _36282 * 8;
                    float4 _18465 = as_type<float4>(_1380._m0[_18350]);
                    float4 _18471 = as_type<float4>(_1380._m0[_18350 + 1]);
                    float4 _18477 = as_type<float4>(_1380._m0[_18350 + 2]);
                    float3 _18439 = _18465.xyz;
                    float3 _18446 = _18471.xyz;
                    float3 _18453 = _18477.xyz;
                    float3 _18459 = float3(dot(_18439, in.m_3136) + _18465.w, dot(_18446, in.m_3136) + _18471.w, dot(_18453, in.m_3136) + _18477.w);
                    float4 _18483 = as_type<float4>(_1380._m0[_18350 + 3]);
                    float _18361 = _18483.w;
                    float _36284;
                    do
                    {
                        float3 _18495 = _18483.xyz - abs(_18459);
                        float _18503 = fast::min(_18495.x, fast::min(_18495.y, _18495.z));
                        if (_18503 <= 0.0)
                        {
                            _36284 = 0.0;
                            break;
                        }
                        if (_18361 <= 0.0)
                        {
                            _36284 = 1.0;
                            break;
                        }
                        float _18515 = fast::min(_18503 / _18361, 1.0);
                        _36284 = (_18515 * _18515) * (3.0 - (2.0 * _18515));
                        break;
                    } while(false);
                    if (_36284 <= 0.0)
                    {
                        _37667 = _36349;
                        _37666 = _36283;
                        continue;
                    }
                    float4 _18530 = as_type<float4>(_1380._m0[_18350 + 4]);
                    float4 _18536 = as_type<float4>(_1380._m0[_18350 + 5]);
                    float3 _18559 = float3(dot(_18439, _12246), dot(_18446, _12246), dot(_18453, _12246));
                    float3 _36286;
                    if (_18530.w > 0.5)
                    {
                        float3 _18383 = _18530.xyz;
                        float3 _18589 = -_18383;
                        float3 _18591 = fast::clamp(_18459, _18589, _18383);
                        float3 _18601 = step(float3(9.9999999747524270787835121154785e-07), abs(_18559));
                        float3 _18611 = mix(float3(1000000015047466219876688855040.0), (mix(_18589, _18383, step(float3(0.0), _18559)) - _18591) / mix(float3(9.9999999747524270787835121154785e-07), _18559, _18601), _18601);
                        float3 _18627 = (_18591 + (_18559 * fast::max(fast::min(_18611.x, fast::min(_18611.y, _18611.z)), 0.0))) - _18536.xyz;
                        float3 _36285;
                        if (dot(_18627, _18627) > 9.9999999600419720025001879548654e-13)
                        {
                            _36285 = fast::normalize(_18627);
                        }
                        else
                        {
                            _36285 = _18559;
                        }
                        _36286 = _36285;
                    }
                    else
                    {
                        _36286 = _18559;
                    }
                    int _18644 = int(((device uint*)&_1380._m0[_18350 + 6])[0u]);
                    float2 _18694 = float2((precise::atan2(_36286.x, -_36286.z) * 0.15915493667125701904296875) + 0.5, acos(fast::clamp(_36286.y, -1.0, 1.0)) * 0.3183098733425140380859375);
                    float2 _18741 = (_18694 * float2(256.0, 128.0)) - float2(0.5);
                    float2 _18743 = floor(_18741);
                    float2 _18746 = _18741 - _18743;
                    int _18749 = int(_18743.x);
                    int _18752 = int(_18743.y);
                    int _36287;
                    if (_18749 < 0)
                    {
                        _36287 = _18749 + 256;
                    }
                    else
                    {
                        _36287 = _18749;
                    }
                    int _36288;
                    if (_36287 >= 256)
                    {
                        _36288 = _36287 - 256;
                    }
                    else
                    {
                        _36288 = _36287;
                    }
                    int _18772 = _36288 + 1;
                    int _37920 = (_18772 == 256) ? 0 : _18772;
                    int _18840 = _18644 + (max(_18752, 0) * 256);
                    int _18842 = _18840 + _36288;
                    int _18844 = _18842 >> 1;
                    uint2 _36294;
                    if ((_18842 & 1) == 0)
                    {
                        _36294 = _1380._m0[_18844].xy;
                    }
                    else
                    {
                        _36294 = _1380._m0[_18844].zw;
                    }
                    int _18880 = _18840 + _37920;
                    int _18882 = _18880 >> 1;
                    uint2 _36296;
                    if ((_18880 & 1) == 0)
                    {
                        _36296 = _1380._m0[_18882].xy;
                    }
                    else
                    {
                        _36296 = _1380._m0[_18882].zw;
                    }
                    int _18916 = _18644 + (min((_18752 + 1), 127) * 256);
                    int _18918 = _18916 + _36288;
                    int _18920 = _18918 >> 1;
                    uint2 _36299;
                    if ((_18918 & 1) == 0)
                    {
                        _36299 = _1380._m0[_18920].xy;
                    }
                    else
                    {
                        _36299 = _1380._m0[_18920].zw;
                    }
                    int _18956 = _18916 + _37920;
                    int _18958 = _18956 >> 1;
                    uint2 _36300;
                    if ((_18956 & 1) == 0)
                    {
                        _36300 = _1380._m0[_18958].xy;
                    }
                    else
                    {
                        _36300 = _1380._m0[_18958].zw;
                    }
                    float3 _18818 = float3(_18746.x);
                    int _19021 = _18644 + 32768;
                    float2 _19028 = (_18694 * float2(128.0, 64.0)) - float2(0.5);
                    float2 _19030 = floor(_19028);
                    float2 _19033 = _19028 - _19030;
                    int _19036 = int(_19030.x);
                    int _19039 = int(_19030.y);
                    int _36301;
                    if (_19036 < 0)
                    {
                        _36301 = _19036 + 128;
                    }
                    else
                    {
                        _36301 = _19036;
                    }
                    int _36302;
                    if (_36301 >= 128)
                    {
                        _36302 = _36301 - 128;
                    }
                    else
                    {
                        _36302 = _36301;
                    }
                    int _19059 = _36302 + 1;
                    int _37921 = (_19059 == 128) ? 0 : _19059;
                    int _19127 = _19021 + (max(_19039, 0) * 128);
                    int _19129 = _19127 + _36302;
                    int _19131 = _19129 >> 1;
                    uint2 _36308;
                    if ((_19129 & 1) == 0)
                    {
                        _36308 = _1380._m0[_19131].xy;
                    }
                    else
                    {
                        _36308 = _1380._m0[_19131].zw;
                    }
                    int _19167 = _19127 + _37921;
                    int _19169 = _19167 >> 1;
                    uint2 _36310;
                    if ((_19167 & 1) == 0)
                    {
                        _36310 = _1380._m0[_19169].xy;
                    }
                    else
                    {
                        _36310 = _1380._m0[_19169].zw;
                    }
                    int _19203 = _19021 + (min((_19039 + 1), 63) * 128);
                    int _19205 = _19203 + _36302;
                    int _19207 = _19205 >> 1;
                    uint2 _36313;
                    if ((_19205 & 1) == 0)
                    {
                        _36313 = _1380._m0[_19207].xy;
                    }
                    else
                    {
                        _36313 = _1380._m0[_19207].zw;
                    }
                    int _19243 = _19203 + _37921;
                    int _19245 = _19243 >> 1;
                    uint2 _36314;
                    if ((_19243 & 1) == 0)
                    {
                        _36314 = _1380._m0[_19245].xy;
                    }
                    else
                    {
                        _36314 = _1380._m0[_19245].zw;
                    }
                    float3 _19105 = float3(_19033.x);
                    float3 _18399 = mix(mix(mix(float3(float2(as_type<half2>(_36294.x)), float2(as_type<half2>(_36294.y)).x), float3(float2(as_type<half2>(_36296.x)), float2(as_type<half2>(_36296.y)).x), _18818), mix(float3(float2(as_type<half2>(_36299.x)), float2(as_type<half2>(_36299.y)).x), float3(float2(as_type<half2>(_36300.x)), float2(as_type<half2>(_36300.y)).x), _18818), float3(_18746.y)), mix(mix(float3(float2(as_type<half2>(_36308.x)), float2(as_type<half2>(_36308.y)).x), float3(float2(as_type<half2>(_36310.x)), float2(as_type<half2>(_36310.y)).x), _19105), mix(float3(float2(as_type<half2>(_36313.x)), float2(as_type<half2>(_36313.y)).x), float3(float2(as_type<half2>(_36314.x)), float2(as_type<half2>(_36314.y)).x), _19105), float3(_19033.y)), float3(0.3499999940395355224609375)) * _18536.w;
                    float _18403 = _36284 * (1.0 - _36283);
                    _37667 = _36349 + (_18399 * _18403);
                    _37666 = _36283 + _18403;
                }
                _36392 = _36349 + (_36280 * (1.0 - _36283));
            }
            else
            {
                _36392 = _36280;
            }
            float3 _12258 = (((float3((fast::max((dot(_36241, _5891) * 0.64999997615814208984375) + (_12208 * 0.3499999940395355224609375), 0.0) * _36250) + (fast::max((_12208 + 0.300000011920928955078125) * 0.769230782985687255859375, 0.0) * _36252)) * _5940) * _35574) * _12205) + ((_36371 * _35576) * _12203);
            float _12262 = fast::max(dot(_5909, _5898), 9.9999997473787516355514526367188e-05);
            float _12268 = fast::clamp(_12208, 0.0, 1.0);
            float _12281 = fast::clamp(dot(_5909, _5903), 0.0, 1.0);
            float _19294 = ((_12281 * _12281) * (-0.999975979328155517578125)) + 1.0;
            float _19318 = sqrt(((_12262 * _12262) * 0.999975979328155517578125) + 2.4009999833651818335056304931641e-05);
            float3 _12299 = ((((((float3(0.02500000037252902984619140625) + (float3(0.97500002384185791015625) * powr(1.0 - fast::clamp(dot(_5898, _5903), 0.0, 1.0), 5.0))) * (1.200499991682590916752815246582e-05 / (((3.1415927410125732421875 * _19294) * _19294) * fast::max((_12268 * _19318) + (_12262 * sqrt(((_12268 * _12268) * 0.999975979328155517578125) + 2.4009999833651818335056304931641e-05)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875) * _12268) * _5940) * _35574) * _12205;
            float3 _36427;
            float3 _36464;
            if (_382._m13.w > 0.5)
            {
                float2 _19363 = fast::clamp(floor(gl_FragCoord.xy * _382._m12.xy), float2(0.0), _382._m13.xy - float2(1.0));
                uint _19391 = uint((((fast::clamp(floor((log2(fast::max(dot(_382._m11.xyz, in.m_3136) + _382._m11.w, 9.9999999747524270787835121154785e-07)) * _382._m12.z) + _382._m12.w), 0.0, _382._m13.z - 1.0) * _382._m13.y) + _19363.y) * _382._m13.x) + _19363.x);
                uint _19393 = _19391 >> uint(2);
                uint _19395 = _19391 & 3u;
                uint _19399 = _3266._m0[_19393][_19395] & 65535u;
                uint _19401 = _3266._m0[_19393][_19395] >> uint(16);
                float3 _36428;
                float3 _36465;
                _36465 = _12258;
                _36428 = _12299;
                for (uint _36424 = _19399; _36424 < (_19399 + _19401); )
                {
                    uint _19407 = _36424 / 3u;
                    uint _19420 = (_3287._m0[_19407 >> uint(2)][_19407 & 3u] >> ((_36424 - (_19407 * 3u)) * 10u)) & 1023u;
                    float3 _19437 = _3129._m0[_19420].xyz - in.m_3136;
                    float _19440 = dot(_19437, _19437);
                    float _19444 = _19440 * _3129._m0[_19420].w;
                    float _19449 = fast::clamp(1.0 - (_19444 * _19444), 0.0, 1.0);
                    float3 _19454 = _19437 * rsqrt(fast::max(_19440, 9.9999999392252902907785028219223e-09));
                    float _19472 = fast::clamp((dot(-_19454, _3172._m0[_19420].xyz) * _3164._m0[_19420].w) + _3172._m0[_19420].w, 0.0, 1.0);
                    float3 _12325 = (_3164._m0[_19420].xyz * ((((_19449 * _19449) * _19472) * _19472) / fast::max(_19440, 9.9999997473787516355514526367188e-05))) * _12205;
                    float _12329 = dot(_5909, _19454);
                    float3 _12360 = fast::normalize(_19454 + _5898);
                    float _12362 = fast::clamp(_12329, 0.0, 1.0);
                    float _12375 = fast::clamp(dot(_5909, _12360), 0.0, 1.0);
                    float _19511 = ((_12375 * _12375) * (-0.999975979328155517578125)) + 1.0;
                    _36465 += (float3((fast::max((dot(_36241, _19454) * 0.64999997615814208984375) + (_12329 * 0.3499999940395355224609375), 0.0) * _36250) + (fast::max((_12329 + 0.300000011920928955078125) * 0.769230782985687255859375, 0.0) * _36252)) * _12325);
                    _36428 += (((((float3(0.02500000037252902984619140625) + (float3(0.97500002384185791015625) * powr(1.0 - fast::clamp(dot(_5898, _12360), 0.0, 1.0), 5.0))) * (1.200499991682590916752815246582e-05 / (((3.1415927410125732421875 * _19511) * _19511) * fast::max((_12362 * _19318) + (_12262 * sqrt(((_12362 * _12362) * 0.999975979328155517578125) + 2.4009999833651818335056304931641e-05)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875) * _12362) * _12325);
                    _36424++;
                    continue;
                }
                _36464 = _36465;
                _36427 = _36428;
            }
            else
            {
                _36464 = _12258;
                _36427 = _12299;
            }
            float2 _36425;
            if (_14979)
            {
                _36425 = _2731.sample(_2733, (((float2(_12262, 0.070000000298023223876953125) * 31.0) + float2(0.5)) * float2(0.03125))).xy;
            }
            else
            {
                _36425 = (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(0.86489999294281005859375, exp2((-9.27999973297119140625) * _12262)) * 0.930000007152557373046875) + 0.0405750013887882232666015625)) + float2(0.9999599456787109375, -0.0384599976241588592529296875);
            }
            float3 _12407 = (float3(0.02500000037252902984619140625) * _36425.x) + float3(_36425.y);
            float3 _12415 = _36427 + ((_12407 * _36392) * mix(1.0, _12203, 0.699999988079071044921875));
            _37181 = _12415;
            _36598 = (((_36246 * _35543) * _36464) * (float3(1.0) - _12407)) + _12415;
        }
        else
        {
            float3 _35579;
            do
            {
                if ((_3372._m3.x <= 0.0) || (_3372._m3.y <= 0.0))
                {
                    _35579 = _35548;
                    break;
                }
                float3 _20121 = dfdx(in.m_3079);
                float3 _20123 = dfdy(in.m_3079);
                float _20130 = fast::max(length(_20121), length(_20123)) * _3372._m3.y;
                float _20133 = 1.0 - smoothstep(0.25, 0.699999988079071044921875, _20130);
                if (_20133 <= 0.0)
                {
                    _35579 = _35548;
                    break;
                }
                float3 _20141 = in.m_3079 * _3372._m3.y;
                float3 _20252 = floor(_20141);
                float3 _20255 = _20141 - _20252;
                float3 _20263 = (_20255 * _20255) * (float3(3.0) - (_20255 * 2.0));
                uint3 _20462 = uint3(int3(_20252));
                uint _20475 = (((_20462.x * 1597334677u) ^ (_20462.y * 3812015801u)) ^ (_20462.z * 2798796415u)) * 1597334677u;
                float _20482 = float((_20475 ^ (_20475 >> uint(16))) & 65535u);
                float _20483 = _20482 * 1.525902189314365386962890625e-05;
                uint3 _20490 = uint3(int3(_20252 + float3(1.0, 0.0, 0.0)));
                uint _20503 = (((_20490.x * 1597334677u) ^ (_20490.y * 3812015801u)) ^ (_20490.z * 2798796415u)) * 1597334677u;
                float _20511 = float((_20503 ^ (_20503 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05;
                uint3 _20518 = uint3(int3(_20252 + float3(0.0, 1.0, 0.0)));
                uint _20531 = (((_20518.x * 1597334677u) ^ (_20518.y * 3812015801u)) ^ (_20518.z * 2798796415u)) * 1597334677u;
                float _20539 = float((_20531 ^ (_20531 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05;
                uint3 _20546 = uint3(int3(_20252 + float3(1.0, 1.0, 0.0)));
                uint _20559 = (((_20546.x * 1597334677u) ^ (_20546.y * 3812015801u)) ^ (_20546.z * 2798796415u)) * 1597334677u;
                float _20567 = float((_20559 ^ (_20559 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05;
                uint3 _20574 = uint3(int3(_20252 + float3(0.0, 0.0, 1.0)));
                uint _20587 = (((_20574.x * 1597334677u) ^ (_20574.y * 3812015801u)) ^ (_20574.z * 2798796415u)) * 1597334677u;
                float _20595 = float((_20587 ^ (_20587 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05;
                uint3 _20602 = uint3(int3(_20252 + float3(1.0, 0.0, 1.0)));
                uint _20615 = (((_20602.x * 1597334677u) ^ (_20602.y * 3812015801u)) ^ (_20602.z * 2798796415u)) * 1597334677u;
                float _20623 = float((_20615 ^ (_20615 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05;
                uint3 _20630 = uint3(int3(_20252 + float3(0.0, 1.0, 1.0)));
                uint _20643 = (((_20630.x * 1597334677u) ^ (_20630.y * 3812015801u)) ^ (_20630.z * 2798796415u)) * 1597334677u;
                float _20651 = float((_20643 ^ (_20643 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05;
                uint3 _20658 = uint3(int3(_20252 + float3(1.0)));
                uint _20671 = (((_20658.x * 1597334677u) ^ (_20658.y * 3812015801u)) ^ (_20658.z * 2798796415u)) * 1597334677u;
                float _20295 = _20511 - _20483;
                float _20298 = _20539 - _20483;
                float _20301 = _20595 - _20483;
                float _20304 = _20483 - _20511;
                float _20308 = (_20304 - _20539) + _20567;
                float _20315 = ((_20483 - _20539) - _20595) + _20651;
                float _20322 = (_20304 - _20595) + _20623;
                float _20338 = (((((((_20482 * (-1.525902189314365386962890625e-05)) + _20511) + _20539) - _20567) + _20595) - _20623) - _20651) + (float((_20671 ^ (_20671 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05);
                float _20342 = _20263.x;
                float _20347 = _20263.y;
                float _20352 = _20263.z;
                float _20358 = _20308 * _20342;
                float _20366 = _20315 * _20347;
                float _20374 = _20322 * _20352;
                float _20385 = (_20338 * _20342) * _20347;
                float _20389 = ((((((_20483 + (_20295 * _20342)) + (_20298 * _20347)) + (_20301 * _20352)) + (_20358 * _20347)) + (_20366 * _20352)) + (_20374 * _20342)) + (_20385 * _20352);
                float _20146 = 1.0 - _20389;
                float3 _20158 = (_20141 * float3(2.900000095367431640625, 2.2999999523162841796875, 2.599999904632568359375)) + float3(13.1000003814697265625, 7.69999980926513671875, 3.2999999523162841796875);
                float3 _20712 = floor(_20158);
                float3 _20715 = _20158 - _20712;
                float3 _20723 = (_20715 * _20715) * (float3(3.0) - (_20715 * 2.0));
                uint3 _20922 = uint3(int3(_20712));
                uint _20935 = (((_20922.x * 1597334677u) ^ (_20922.y * 3812015801u)) ^ (_20922.z * 2798796415u)) * 1597334677u;
                float _20942 = float((_20935 ^ (_20935 >> uint(16))) & 65535u);
                float _20943 = _20942 * 1.525902189314365386962890625e-05;
                uint3 _20950 = uint3(int3(_20712 + float3(1.0, 0.0, 0.0)));
                uint _20963 = (((_20950.x * 1597334677u) ^ (_20950.y * 3812015801u)) ^ (_20950.z * 2798796415u)) * 1597334677u;
                float _20971 = float((_20963 ^ (_20963 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05;
                uint3 _20978 = uint3(int3(_20712 + float3(0.0, 1.0, 0.0)));
                uint _20991 = (((_20978.x * 1597334677u) ^ (_20978.y * 3812015801u)) ^ (_20978.z * 2798796415u)) * 1597334677u;
                float _20999 = float((_20991 ^ (_20991 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05;
                uint3 _21006 = uint3(int3(_20712 + float3(1.0, 1.0, 0.0)));
                uint _21019 = (((_21006.x * 1597334677u) ^ (_21006.y * 3812015801u)) ^ (_21006.z * 2798796415u)) * 1597334677u;
                float _21027 = float((_21019 ^ (_21019 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05;
                uint3 _21034 = uint3(int3(_20712 + float3(0.0, 0.0, 1.0)));
                uint _21047 = (((_21034.x * 1597334677u) ^ (_21034.y * 3812015801u)) ^ (_21034.z * 2798796415u)) * 1597334677u;
                float _21055 = float((_21047 ^ (_21047 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05;
                uint3 _21062 = uint3(int3(_20712 + float3(1.0, 0.0, 1.0)));
                uint _21075 = (((_21062.x * 1597334677u) ^ (_21062.y * 3812015801u)) ^ (_21062.z * 2798796415u)) * 1597334677u;
                float _21083 = float((_21075 ^ (_21075 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05;
                uint3 _21090 = uint3(int3(_20712 + float3(0.0, 1.0, 1.0)));
                uint _21103 = (((_21090.x * 1597334677u) ^ (_21090.y * 3812015801u)) ^ (_21090.z * 2798796415u)) * 1597334677u;
                float _21111 = float((_21103 ^ (_21103 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05;
                uint3 _21118 = uint3(int3(_20712 + float3(1.0)));
                uint _21131 = (((_21118.x * 1597334677u) ^ (_21118.y * 3812015801u)) ^ (_21118.z * 2798796415u)) * 1597334677u;
                float _20764 = _20943 - _20971;
                float _20768 = (_20764 - _20999) + _21027;
                float _20775 = ((_20943 - _20999) - _21055) + _21111;
                float _20782 = (_20764 - _21055) + _21083;
                float _20798 = (((((((_20942 * (-1.525902189314365386962890625e-05)) + _20971) + _20999) - _21027) + _21055) - _21083) - _21111) + (float((_21131 ^ (_21131 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05);
                float _20802 = _20723.x;
                float _20807 = _20723.y;
                float _20812 = _20723.z;
                float3 _20175 = ((float4(_20389, ((_20255 * 6.0) * (float3(1.0) - _20255)) * float3(((_20295 + (_20308 * _20347)) + _20374) + ((_20338 * _20347) * _20352), ((_20298 + (_20315 * _20352)) + _20358) + ((_20338 * _20352) * _20342), ((_20301 + (_20322 * _20342)) + _20366) + _20385)).yzw * (((4.0 * _20146) * _20146) * _20146)) + ((float3(1.01499998569488525390625, 0.805000007152557373046875, 0.910000026226043701171875) * float4(_37892, ((_20715 * 6.0) * (float3(1.0) - _20715)) * float3((((_20971 - _20943) + (_20768 * _20807)) + (_20782 * _20812)) + ((_20798 * _20807) * _20812), (((_20999 - _20943) + (_20775 * _20812)) + (_20768 * _20802)) + ((_20798 * _20812) * _20802), (((_21055 - _20943) + (_20782 * _20802)) + (_20775 * _20807)) + ((_20798 * _20802) * _20807))).yzw) * (1.0 - smoothstep(0.20000000298023223876953125, 0.5, _20130 * 2.900000095367431640625)))) * ((0.25 * _3372._m3.x) * _20133);
                float3 _20183 = dfdx(in.m_3136);
                float3 _20185 = dfdy(in.m_3136);
                float3 _20188 = cross(_20185, _35548);
                float _20194 = dot(_20183, _20188);
                float _20196 = abs(_20194);
                if (_20196 < 9.9999996826552253889678874634872e-21)
                {
                    _35579 = _35548;
                    break;
                }
                _35579 = fast::normalize((_35548 * _20196) - (((_20188 * dot(_20175, _20121)) + (cross(_35548, _20183) * dot(_20175, _20123))) * sign(_20194)));
                break;
            } while(false);
            float _19719 = fast::max(dot(_35579, _5898), 9.9999997473787516355514526367188e-05);
            float3 _19727 = mix(float3(0.0280000008642673492431640625), _35543, float3(_35578));
            float3 _19733 = fast::clamp(float3(0.4799999892711639404296875, 0.4099999964237213134765625, 0.2800000011920928955078125) * _3372._m0.w, float3(0.0), float3(1.0));
            bool _19736 = _3372._m0.w > 0.0;
            bool _19742;
            if (_19736)
            {
                _19742 = _3372._m1.x > 0.0;
            }
            else
            {
                _19742 = _19736;
            }
            bool _19749 = _19742 && (isunordered(_3372._m1.w, 0.5) || _3372._m1.w <= 0.5);
            float _35580;
            if (_19742)
            {
                _35580 = _3372._m1.y;
            }
            else
            {
                _35580 = 0.0;
            }
            bool _19759 = _35580 > 0.0;
            float _35581;
            if (_19749 || _19759)
            {
                _35581 = fast::clamp(length(fwidth(_5909)) / fast::max(length(fwidth(in.m_3136)), 1.0000000116860974230803549289703e-07), 0.0, 400.0);
            }
            else
            {
                _35581 = 0.0;
            }
            float _19773 = fast::max(_35581, 2.0);
            spvUnsafeArray<float3, 2> _3626;
            spvUnsafeArray<float3, 2> _3634;
            spvUnsafeArray<float3, 2> _3640;
            spvUnsafeArray<float3, 2> _3647;
            if (_19749)
            {
                float3 _21152 = (_3372._m0.xyz * (_3372._m1.x * 0.5)) * _35581;
                for (int _35582 = 0; _35582 < 2; )
                {
                    float3 _21162 = _21152 * ((_35582 == 0) ? 0.519999980926513671875 : 1.7200000286102294921875);
                    float3 _21165 = _21162 * 1.35562622547149658203125;
                    _3626[_35582] = cos(_21165);
                    _3634[_35582] = sin(_21165);
                    float3 _21175 = _21162 * 2.8569700717926025390625;
                    _3640[_35582] = cos(_21175);
                    _3647[_35582] = sin(_21175);
                    _35582++;
                    continue;
                }
            }
            float3 _35588;
            if (_19749)
            {
                _35588 = fast::normalize(mix(_35579, _5909, float3(_19733.x)));
            }
            else
            {
                _35588 = _35579;
            }
            float3 _35590;
            if (_19749)
            {
                _35590 = fast::normalize(mix(_35579, _5909, float3(_19733.y * 0.60000002384185791015625)));
            }
            else
            {
                _35590 = _35579;
            }
            float3 _35592;
            if (_19749)
            {
                _35592 = fast::normalize(mix(_35579, _5909, float3(_19733.z * 0.4000000059604644775390625)));
            }
            else
            {
                _35592 = _35579;
            }
            float _19826 = dot(_35590, _5891);
            float3 _19830 = float3(dot(_35588, _5891), _19826, dot(_35592, _5891));
            float3 _35595;
            if (_19749)
            {
                float3 _21197 = fast::clamp(_19830, float3(-1.0), float3(1.0));
                float3 _21204 = sqrt(fast::max(float3(1.0) - (_21197 * _21197), float3(0.0)));
                float3 _35594;
                _35594 = float3(0.0);
                for (int _35593 = 0; _35593 < 2; )
                {
                    _35594 += ((((fast::max(_21197, float3(0.0)) * 0.533333301544189453125) + ((fast::max((_21197 * _3626[_35593]) - (_21204 * _3634[_35593]), float3(0.0)) + fast::max((_21197 * _3626[_35593]) + (_21204 * _3634[_35593]), float3(0.0))) * 0.22207589447498321533203125)) + ((fast::max((_21197 * _3640[_35593]) - (_21204 * _3647[_35593]), float3(0.0)) + fast::max((_21197 * _3640[_35593]) + (_21204 * _3647[_35593]), float3(0.0))) * 0.011257399804890155792236328125)) * ((_35593 == 0) ? 0.430000007152557373046875 : 0.569999992847442626953125));
                    _35593++;
                    continue;
                }
                _35595 = mix(fast::max(_19830, float3(0.0)), _35594, _19733);
            }
            else
            {
                _35595 = float3(fast::max(_19826, 0.0));
            }
            float3 _19847 = (_35595 * _5940) * _35574;
            float3 _35602;
            do
            {
                float _21318 = fast::clamp(dot(_35579, _5891), 0.0, 1.0);
                if (_21318 <= 0.0)
                {
                    _35602 = float3(0.0);
                    break;
                }
                float _21326 = fast::clamp(dot(_35579, _5903), 0.0, 1.0);
                float _21337 = fast::clamp(_35577 * _3372._m2.x, 0.04500000178813934326171875, 1.0);
                float _21340 = _21337 * _21337;
                float _21400 = _21340 * _21340;
                float _21403 = _21326 * _21326;
                float _21407 = (_21403 * (_21400 - 1.0)) + 1.0;
                float _21425 = _19719 * _19719;
                float _21427 = 1.0 - _21400;
                float _21436 = _21318 * _21318;
                float _21348 = (_21400 / ((3.1415927410125732421875 * _21407) * _21407)) * (0.5 / fast::max((_21318 * sqrt((_21425 * _21427) + _21400)) + (_19719 * sqrt((_21436 * _21427) + _21400)), 9.9999997473787516355514526367188e-06));
                float _35601;
                if (_3372._m2.w > 0.5)
                {
                    float _21357 = fast::clamp(_35577 * _3372._m2.y, 0.04500000178813934326171875, 1.0);
                    float _21360 = _21357 * _21357;
                    float _21455 = _21360 * _21360;
                    float _21462 = (_21403 * (_21455 - 1.0)) + 1.0;
                    float _21482 = 1.0 - _21455;
                    _35601 = mix(_21348, (_21455 / ((3.1415927410125732421875 * _21462) * _21462)) * (0.5 / fast::max((_21318 * sqrt((_21425 * _21482) + _21455)) + (_19719 * sqrt((_21436 * _21482) + _21455)), 9.9999997473787516355514526367188e-06)), _3372._m2.z);
                }
                else
                {
                    _35601 = _21348;
                }
                _35602 = (_19727 + ((float3(1.0) - _19727) * powr(1.0 - fast::clamp(dot(_5898, _5903), 0.0, 1.0), 5.0))) * ((_35601 * 3.1415927410125732421875) * _21318);
                break;
            } while(false);
            float3 _19860 = (_35602 * _5940) * _35574;
            bool _19871;
            if (_19759)
            {
                _19871 = dot(_5909, _5891) < 0.3499999940395355224609375;
            }
            else
            {
                _19871 = _19759;
            }
            bool _19877;
            if (_19871)
            {
                _19877 = _382._m4.w > 0.0;
            }
            else
            {
                _19877 = _19871;
            }
            float3 _35869;
            if (_19877)
            {
                float3 _35662;
                if (_5914)
                {
                    float3 _35661;
                    do
                    {
                        int _21531 = int(_382._m21.x);
                        if ((_382._m5.w < 0.5) || (_21531 == 0))
                        {
                            float _21639 = (1200.0 / _19773) / (0.60000002384185791015625 + (6.0 * _3372._m1.y));
                            float _21646 = (-_21639) * _21639;
                            _35661 = (((((float3(0.23299999535083770751953125, 0.4550000131130218505859375, 0.648999989032745361328125) * exp(_21646 * 156.25)) + (float3(0.100000001490116119384765625, 0.3359999954700469970703125, 0.3440000116825103759765625) * exp(_21646 * 20.6611576080322265625))) + (float3(0.1180000007152557373046875, 0.19799999892711639404296875, 0.0) * exp(_21646 * 5.3475933074951171875))) + (float3(0.112999998033046722412109375, 0.007000000216066837310791015625, 0.007000000216066837310791015625) * exp(_21646 * 1.763668537139892578125))) + (float3(0.3580000102519989013671875, 0.0040000001899898052215576171875, 0.0) * exp(_21646 * 0.50251257419586181640625))) + (float3(0.078000001609325408935546875, 0.0, 0.0) * exp(_21646 * 0.13495276868343353271484375));
                            break;
                        }
                        float _21550 = dot(_382._m20.xyz, in.m_3136) + _382._m20.w;
                        int _35607;
                        _35607 = 0;
                        for (;;)
                        {
                            bool _21556 = _35607 < (_21531 - 1);
                            bool _21564;
                            if (_21556)
                            {
                                _21564 = _21550 > _382._m16[_35607];
                            }
                            else
                            {
                                _21564 = _21556;
                            }
                            if (_21564)
                            {
                                _35607++;
                                continue;
                            }
                            else
                            {
                                break;
                            }
                        }
                        if (_21550 > _382._m16[_35607])
                        {
                            float _21684 = (1200.0 / _19773) / (0.60000002384185791015625 + (6.0 * _3372._m1.y));
                            float _21691 = (-_21684) * _21684;
                            _35661 = (((((float3(0.23299999535083770751953125, 0.4550000131130218505859375, 0.648999989032745361328125) * exp(_21691 * 156.25)) + (float3(0.100000001490116119384765625, 0.3359999954700469970703125, 0.3440000116825103759765625) * exp(_21691 * 20.6611576080322265625))) + (float3(0.1180000007152557373046875, 0.19799999892711639404296875, 0.0) * exp(_21691 * 5.3475933074951171875))) + (float3(0.112999998033046722412109375, 0.007000000216066837310791015625, 0.007000000216066837310791015625) * exp(_21691 * 1.763668537139892578125))) + (float3(0.3580000102519989013671875, 0.0040000001899898052215576171875, 0.0) * exp(_21691 * 0.50251257419586181640625))) + (float3(0.078000001609325408935546875, 0.0, 0.0) * exp(_21691 * 0.13495276868343353271484375));
                            break;
                        }
                        float4x4 _21734;
                        float3 _21588 = in.m_3136 - (_5909 * fast::max(_382._m18[_35607] * 2.0, 0.0040000001899898052215576171875));
                        float _35620;
                        do
                        {
                            _21734 = _382._m14[_35607];
                            float4 _21740 = _21734 * float4(_21588 + (_5891 * 0.0199999995529651641845703125), 1.0);
                            float _21743 = _21740.x;
                            bool _21744 = _21743 < 0.0;
                            bool _21751;
                            if (!_21744)
                            {
                                _21751 = _21743 > 1.0;
                            }
                            else
                            {
                                _21751 = _21744;
                            }
                            bool _21758;
                            if (!_21751)
                            {
                                _21758 = _21740.y < 0.0;
                            }
                            else
                            {
                                _21758 = _21751;
                            }
                            bool _21765;
                            if (!_21758)
                            {
                                _21765 = _21740.y > 1.0;
                            }
                            else
                            {
                                _21765 = _21758;
                            }
                            if (_21765)
                            {
                                _35620 = 1.0;
                                break;
                            }
                            float2 _21778 = float2(float(_35607 & 1), float(_35607 >> 1)) * _382._m23.xy;
                            float _21785 = fast::min(_21740.z, 1.0) - _382._m19[_35607];
                            float2 _21804 = _382._m22.xy * 0.5;
                            float2 _21809 = _21778 + (_21740.xy * _382._m23.xy);
                            float4 _21822 = float4(_21778 + _21804, (_21778 + _382._m23.xy) - _21804);
                            float _35619;
                            do
                            {
                                int _21848 = int(_382._m22.z);
                                if (_21848 <= 0)
                                {
                                    _35619 = spvDepthCast(_402).sample_compare(_402Smplr, float3(fast::clamp(_21809, _21822.xy, _21822.zw), _21785).xy, _21785);
                                    break;
                                }
                                float2 _21871 = (_21809 / _382._m22.xy) + float2(0.5);
                                float2 _21872 = floor(_21871);
                                float2 _21877 = _21871 - _21872;
                                float2 _21880 = _21872 - float2(0.5);
                                bool _21884 = _21848 == 1;
                                spvUnsafeArray<float2, 3> _21832;
                                spvUnsafeArray<float2, 3> _21833;
                                if (_21884)
                                {
                                    float2 _21887 = _21877 * 2.0;
                                    _21832[0] = float2(3.0) - _21887;
                                    _21832[1] = float2(1.0) + _21887;
                                    _21833[0] = ((float2(2.0) - _21877) / _21832[0]) - float2(1.0);
                                    _21833[1] = (_21877 / _21832[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _21914 = _21877 * 3.0;
                                    _21832[0] = float2(4.0) - _21914;
                                    _21832[1] = float2(7.0);
                                    _21832[2] = float2(1.0) + _21914;
                                    _21833[0] = ((float2(3.0) - (_21877 * 2.0)) / _21832[0]) - float2(2.0);
                                    _21833[1] = (float2(3.0) + _21877) / _21832[1];
                                    _21833[2] = (_21877 / _21832[2]) + float2(2.0);
                                }
                                int _37923 = _21884 ? 2 : 3;
                                int _35609;
                                float _35612;
                                _35612 = 0.0;
                                _35609 = 0;
                                float _35618;
                                for (; _35609 < _37923; _35612 = _35618, _35609++)
                                {
                                    _35618 = _35612;
                                    for (int _35615 = 0; _35615 < _37923; )
                                    {
                                        _35618 += ((_21832[_35615].x * _21832[_35609].y) * spvDepthCast(_402).sample_compare(_402Smplr, float3(fast::clamp(_382._m22.xy * (_21880 + float2(_21833[_35615].x, _21833[_35609].y)), _21822.xy, _21822.zw), _21785).xy, _21785));
                                        _35615++;
                                        continue;
                                    }
                                }
                                _35619 = _35612 * (_21884 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _35620 = _35619;
                            break;
                        } while(false);
                        if (_35620 <= 0.0)
                        {
                            _35661 = float3(0.0);
                            break;
                        }
                        float3 _35622;
                        float3 _35623;
                        _35623 = float3(1.0);
                        _35622 = float3(0.0);
                        float3 _21622;
                        float3 _22052;
                        spvUnsafeArray<float2, 3> _22164;
                        spvUnsafeArray<float2, 3> _22165;
                        for (int _35621 = 0; _35621 < 4; _35623 = _22052, _35622 = _21622, _35621++)
                        {
                            float _22016 = (_3479[_35621] * 1000.0) / (0.60000002384185791015625 + (6.0 * _3372._m1.y));
                            float _22023 = (-_22016) * _22016;
                            _22052 = (((((float3(0.23299999535083770751953125, 0.4550000131130218505859375, 0.648999989032745361328125) * exp(_22023 * 156.25)) + (float3(0.100000001490116119384765625, 0.3359999954700469970703125, 0.3440000116825103759765625) * exp(_22023 * 20.6611576080322265625))) + (float3(0.1180000007152557373046875, 0.19799999892711639404296875, 0.0) * exp(_22023 * 5.3475933074951171875))) + (float3(0.112999998033046722412109375, 0.007000000216066837310791015625, 0.007000000216066837310791015625) * exp(_22023 * 1.763668537139892578125))) + (float3(0.3580000102519989013671875, 0.0040000001899898052215576171875, 0.0) * exp(_22023 * 0.50251257419586181640625))) + (float3(0.078000001609325408935546875, 0.0, 0.0) * exp(_22023 * 0.13495276868343353271484375));
                            float _35644;
                            do
                            {
                                float4 _22072 = _21734 * float4(_21588 + (_5891 * _3479[_35621]), 1.0);
                                float _22075 = _22072.x;
                                bool _22076 = _22075 < 0.0;
                                bool _22083;
                                if (!_22076)
                                {
                                    _22083 = _22075 > 1.0;
                                }
                                else
                                {
                                    _22083 = _22076;
                                }
                                bool _22090;
                                if (!_22083)
                                {
                                    _22090 = _22072.y < 0.0;
                                }
                                else
                                {
                                    _22090 = _22083;
                                }
                                bool _22097;
                                if (!_22090)
                                {
                                    _22097 = _22072.y > 1.0;
                                }
                                else
                                {
                                    _22097 = _22090;
                                }
                                if (_22097)
                                {
                                    _35644 = 1.0;
                                    break;
                                }
                                float2 _22110 = float2(float(_35607 & 1), float(_35607 >> 1)) * _382._m23.xy;
                                float _22117 = fast::min(_22072.z, 1.0) - _382._m19[_35607];
                                float2 _22136 = _382._m22.xy * 0.5;
                                float2 _22141 = _22110 + (_22072.xy * _382._m23.xy);
                                float4 _22154 = float4(_22110 + _22136, (_22110 + _382._m23.xy) - _22136);
                                float _35643;
                                do
                                {
                                    int _22180 = int(_382._m22.z);
                                    if (_22180 <= 0)
                                    {
                                        _35643 = spvDepthCast(_402).sample_compare(_402Smplr, float3(fast::clamp(_22141, _22154.xy, _22154.zw), _22117).xy, _22117);
                                        break;
                                    }
                                    float2 _22203 = (_22141 / _382._m22.xy) + float2(0.5);
                                    float2 _22204 = floor(_22203);
                                    float2 _22209 = _22203 - _22204;
                                    float2 _22212 = _22204 - float2(0.5);
                                    bool _22216 = _22180 == 1;
                                    if (_22216)
                                    {
                                        float2 _22219 = _22209 * 2.0;
                                        _22164[0] = float2(3.0) - _22219;
                                        _22164[1] = float2(1.0) + _22219;
                                        _22165[0] = ((float2(2.0) - _22209) / _22164[0]) - float2(1.0);
                                        _22165[1] = (_22209 / _22164[1]) + float2(1.0);
                                    }
                                    else
                                    {
                                        float2 _22246 = _22209 * 3.0;
                                        _22164[0] = float2(4.0) - _22246;
                                        _22164[1] = float2(7.0);
                                        _22164[2] = float2(1.0) + _22246;
                                        _22165[0] = ((float2(3.0) - (_22209 * 2.0)) / _22164[0]) - float2(2.0);
                                        _22165[1] = (float2(3.0) + _22209) / _22164[1];
                                        _22165[2] = (_22209 / _22164[2]) + float2(2.0);
                                    }
                                    int _37925 = _22216 ? 2 : 3;
                                    int _35633;
                                    float _35636;
                                    _35636 = 0.0;
                                    _35633 = 0;
                                    float _35642;
                                    for (; _35633 < _37925; _35636 = _35642, _35633++)
                                    {
                                        _35642 = _35636;
                                        for (int _35639 = 0; _35639 < _37925; )
                                        {
                                            _35642 += ((_22164[_35639].x * _22164[_35633].y) * spvDepthCast(_402).sample_compare(_402Smplr, float3(fast::clamp(_382._m22.xy * (_22212 + float2(_22165[_35639].x, _22165[_35633].y)), _22154.xy, _22154.zw), _22117).xy, _22117));
                                            _35639++;
                                            continue;
                                        }
                                    }
                                    _35643 = _35636 * (_22216 ? 0.0625 : 0.0069444444961845874786376953125);
                                    break;
                                } while(false);
                                _35644 = _35643;
                                break;
                            } while(false);
                            _21622 = _35622 + ((_35623 - _22052) * _35644);
                        }
                        _35661 = _35622;
                        break;
                    } while(false);
                    _35662 = _35661;
                }
                else
                {
                    float _22348 = (1200.0 / _19773) / (0.60000002384185791015625 + (6.0 * _3372._m1.y));
                    float _22355 = (-_22348) * _22348;
                    _35662 = (((((float3(0.23299999535083770751953125, 0.4550000131130218505859375, 0.648999989032745361328125) * exp(_22355 * 156.25)) + (float3(0.100000001490116119384765625, 0.3359999954700469970703125, 0.3440000116825103759765625) * exp(_22355 * 20.6611576080322265625))) + (float3(0.1180000007152557373046875, 0.19799999892711639404296875, 0.0) * exp(_22355 * 5.3475933074951171875))) + (float3(0.112999998033046722412109375, 0.007000000216066837310791015625, 0.007000000216066837310791015625) * exp(_22355 * 1.763668537139892578125))) + (float3(0.3580000102519989013671875, 0.0040000001899898052215576171875, 0.0) * exp(_22355 * 0.50251257419586181640625))) + (float3(0.078000001609325408935546875, 0.0, 0.0) * exp(_22355 * 0.13495276868343353271484375));
                }
                _35869 = _19847 + ((_35662 * _5940) * ((fast::clamp(0.300000011920928955078125 - dot(_5909, _5891), 0.0, 1.0) * _35580) * 2.0));
            }
            else
            {
                _35869 = _19847;
            }
            float3 _35868;
            float3 _35903;
            if (_382._m13.w > 0.5)
            {
                float2 _22412 = fast::clamp(floor(gl_FragCoord.xy * _382._m12.xy), float2(0.0), _382._m13.xy - float2(1.0));
                uint _22440 = uint((((fast::clamp(floor((log2(fast::max(dot(_382._m11.xyz, in.m_3136) + _382._m11.w, 9.9999999747524270787835121154785e-07)) * _382._m12.z) + _382._m12.w), 0.0, _382._m13.z - 1.0) * _382._m13.y) + _22412.y) * _382._m13.x) + _22412.x);
                uint _22442 = _22440 >> uint(2);
                uint _22444 = _22440 & 3u;
                uint _22448 = _3266._m0[_22442][_22444] & 65535u;
                uint _22450 = _3266._m0[_22442][_22444] >> uint(16);
                float3 _35870;
                float3 _35928;
                _35928 = _19860;
                _35870 = _35869;
                float3 _19981;
                spvUnsafeArray<float2, 3> _22858;
                spvUnsafeArray<float2, 3> _22859;
                spvUnsafeArray<float2, 3> _23071;
                spvUnsafeArray<float2, 3> _23072;
                spvUnsafeArray<float2, 3> _24019;
                spvUnsafeArray<float2, 3> _24020;
                spvUnsafeArray<float2, 3> _24232;
                spvUnsafeArray<float2, 3> _24233;
                spvUnsafeArray<float2, 3> _24776;
                spvUnsafeArray<float2, 3> _24777;
                spvUnsafeArray<float2, 3> _24989;
                spvUnsafeArray<float2, 3> _24990;
                float3 _37611;
                for (uint _35688 = _22448; _35688 < (_22448 + _22450); _35928 = _19981, _35870 = _37611, _35688++)
                {
                    uint _22456 = _35688 / 3u;
                    uint _22469 = (_3287._m0[_22456 >> uint(2)][_22456 & 3u] >> ((_35688 - (_22456 * 3u)) * 10u)) & 1023u;
                    float3 _22486 = _3129._m0[_22469].xyz - in.m_3136;
                    float _22489 = dot(_22486, _22486);
                    float _22493 = _22489 * _3129._m0[_22469].w;
                    float _22498 = fast::clamp(1.0 - (_22493 * _22493), 0.0, 1.0);
                    float3 _22503 = _22486 * rsqrt(fast::max(_22489, 9.9999999392252902907785028219223e-09));
                    float _22521 = fast::clamp((dot(-_22503, _3172._m0[_22469].xyz) * _3164._m0[_22469].w) + _3172._m0[_22469].w, 0.0, 1.0);
                    float3 _22534 = _3164._m0[_22469].xyz * ((((_22498 * _22498) * _22521) * _22521) / fast::max(_22489, 9.9999997473787516355514526367188e-05));
                    float _35982;
                    if (_5914)
                    {
                        float _35981;
                        do
                        {
                            uint _22570 = uint(_382._m21.z);
                            if (_22469 < _22570)
                            {
                                float _22592 = _382._m26[_22469].z * fast::max((_382._m15[_22469] * float4(in.m_3136, 1.0)).w, 0.0);
                                float4 _22616 = _382._m15[_22469] * float4((in.m_3136 + (_5909 * (_22592 * _382._m25.x))) + (_22503 * (_22592 * _382._m25.y)), 1.0);
                                float _22618 = _22616.w;
                                if (_22618 <= 0.0)
                                {
                                    _35981 = 1.0;
                                    break;
                                }
                                float3 _22627 = _22616.xyz / float3(_22618);
                                float _22629 = _22627.x;
                                bool _22630 = _22629 < 0.0;
                                bool _22637;
                                if (!_22630)
                                {
                                    _22637 = _22629 > 1.0;
                                }
                                else
                                {
                                    _22637 = _22630;
                                }
                                bool _22644;
                                if (!_22637)
                                {
                                    _22644 = _22627.y < 0.0;
                                }
                                else
                                {
                                    _22644 = _22637;
                                }
                                bool _22651;
                                if (!_22644)
                                {
                                    _22651 = _22627.y > 1.0;
                                }
                                else
                                {
                                    _22651 = _22644;
                                }
                                bool _22658;
                                if (!_22651)
                                {
                                    _22658 = _22627.z > 1.0;
                                }
                                else
                                {
                                    _22658 = _22651;
                                }
                                if (_22658)
                                {
                                    _35981 = 1.0;
                                    break;
                                }
                                float _22664 = _22627.z;
                                float2 _22830 = _382._m22.xy * 0.5;
                                float2 _22835 = _382._m26[_22469].xy + (_22627.xy * _382._m23.zw);
                                float4 _22848 = float4(_382._m26[_22469].xy + _22830, (_382._m26[_22469].xy + _382._m23.zw) - _22830);
                                float _35980;
                                do
                                {
                                    int _22874 = int(_382._m22.z);
                                    if (_22874 <= 0)
                                    {
                                        float2 _22884 = fast::clamp(_22835, _22848.xy, _22848.zw);
                                        _35980 = spvDepthCast(_402).sample_compare(_402Smplr, float3(_22884, _22664).xy, _22664);
                                        break;
                                    }
                                    float2 _22897 = (_22835 / _382._m22.xy) + float2(0.5);
                                    float2 _22898 = floor(_22897);
                                    float2 _22903 = _22897 - _22898;
                                    float2 _22906 = _22898 - float2(0.5);
                                    bool _22910 = _22874 == 1;
                                    if (_22910)
                                    {
                                        float2 _22913 = _22903 * 2.0;
                                        _22858[0] = float2(3.0) - _22913;
                                        _22858[1] = float2(1.0) + _22913;
                                        _22859[0] = ((float2(2.0) - _22903) / _22858[0]) - float2(1.0);
                                        _22859[1] = (_22903 / _22858[1]) + float2(1.0);
                                    }
                                    else
                                    {
                                        float2 _22940 = _22903 * 3.0;
                                        _22858[0] = float2(4.0) - _22940;
                                        _22858[1] = float2(7.0);
                                        _22858[2] = float2(1.0) + _22940;
                                        _22859[0] = ((float2(3.0) - (_22903 * 2.0)) / _22858[0]) - float2(2.0);
                                        _22859[1] = (float2(3.0) + _22903) / _22858[1];
                                        _22859[2] = (_22903 / _22858[2]) + float2(2.0);
                                    }
                                    int _37927 = _22910 ? 2 : 3;
                                    int _35970;
                                    float _35973;
                                    _35973 = 0.0;
                                    _35970 = 0;
                                    float _35979;
                                    for (; _35970 < _37927; _35973 = _35979, _35970++)
                                    {
                                        _35979 = _35973;
                                        for (int _35976 = 0; _35976 < _37927; )
                                        {
                                            _35979 += ((_22858[_35976].x * _22858[_35970].y) * spvDepthCast(_402).sample_compare(_402Smplr, float3(fast::clamp(_382._m22.xy * (_22906 + float2(_22859[_35976].x, _22859[_35970].y)), _22848.xy, _22848.zw), _22664).xy, _22664));
                                            _35976++;
                                            continue;
                                        }
                                    }
                                    _35980 = _35973 * (_22910 ? 0.0625 : 0.0069444444961845874786376953125);
                                    break;
                                } while(false);
                                _35981 = _35980;
                                break;
                            }
                            uint _22674 = _22469 - _22570;
                            if (_22674 >= uint(_382._m21.w))
                            {
                                _35981 = 1.0;
                                break;
                            }
                            float _22695 = _382._m27[_22674].w * length(in.m_3136 - _382._m27[_22674].xyz);
                            float3 _22713 = ((in.m_3136 + (_5909 * (_22695 * _382._m25.x))) + (_22503 * (_22695 * _382._m25.y))) - _382._m27[_22674].xyz;
                            float3 _22715 = abs(_22713);
                            float _22717 = _22715.x;
                            float _22719 = _22715.y;
                            bool _22720 = _22717 >= _22719;
                            bool _22728;
                            if (_22720)
                            {
                                _22728 = _22717 >= _22715.z;
                            }
                            else
                            {
                                _22728 = _22720;
                            }
                            float _35955;
                            int _35957;
                            if (_22728)
                            {
                                _35957 = (_22713.x > 0.0) ? 0 : 1;
                                _35955 = _22717;
                            }
                            else
                            {
                                float _22740 = _22715.z;
                                bool _22741 = _22719 >= _22740;
                                int _35958;
                                if (_22741)
                                {
                                    _35958 = (_22713.y > 0.0) ? 2 : 3;
                                }
                                else
                                {
                                    _35958 = (_22713.z > 0.0) ? 4 : 5;
                                }
                                _35957 = _35958;
                                _35955 = _22741 ? _22719 : _22740;
                            }
                            if (_35955 <= 0.0)
                            {
                                _35981 = 1.0;
                                break;
                            }
                            float2 _22778 = float2(dot(_22713, _1060[_35957]), dot(_22713, _1069[_35957])) / float2(_35955 * _382._m24.z);
                            float _22785 = _382._m28[_22674].z + (_382._m28[_22674].w / _35955);
                            if (_22785 > 1.0)
                            {
                                _35981 = 1.0;
                                break;
                            }
                            float2 _22803 = _382._m28[_22674].xy + (float2(float(spvSMod(_35957, 3)), float(_35957 / 3)) * _382._m24.xy);
                            float2 _23043 = _382._m22.xy * 0.5;
                            float2 _23048 = _22803 + (float2(0.5 + (0.5 * _22778.x), 0.5 - (0.5 * _22778.y)) * _382._m24.xy);
                            float4 _23061 = float4(_22803 + _23043, (_22803 + _382._m24.xy) - _23043);
                            float _35969;
                            do
                            {
                                int _23087 = int(_382._m22.z);
                                if (_23087 <= 0)
                                {
                                    _35969 = spvDepthCast(_402).sample_compare(_402Smplr, float3(fast::clamp(_23048, _23061.xy, _23061.zw), _22785).xy, _22785);
                                    break;
                                }
                                float2 _23110 = (_23048 / _382._m22.xy) + float2(0.5);
                                float2 _23111 = floor(_23110);
                                float2 _23116 = _23110 - _23111;
                                float2 _23119 = _23111 - float2(0.5);
                                bool _23123 = _23087 == 1;
                                if (_23123)
                                {
                                    float2 _23126 = _23116 * 2.0;
                                    _23071[0] = float2(3.0) - _23126;
                                    _23071[1] = float2(1.0) + _23126;
                                    _23072[0] = ((float2(2.0) - _23116) / _23071[0]) - float2(1.0);
                                    _23072[1] = (_23116 / _23071[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _23153 = _23116 * 3.0;
                                    _23071[0] = float2(4.0) - _23153;
                                    _23071[1] = float2(7.0);
                                    _23071[2] = float2(1.0) + _23153;
                                    _23072[0] = ((float2(3.0) - (_23116 * 2.0)) / _23071[0]) - float2(2.0);
                                    _23072[1] = (float2(3.0) + _23116) / _23071[1];
                                    _23072[2] = (_23116 / _23071[2]) + float2(2.0);
                                }
                                int _37930 = _23123 ? 2 : 3;
                                int _35959;
                                float _35962;
                                _35962 = 0.0;
                                _35959 = 0;
                                float _35968;
                                for (; _35959 < _37930; _35962 = _35968, _35959++)
                                {
                                    _35968 = _35962;
                                    for (int _35965 = 0; _35965 < _37930; )
                                    {
                                        _35968 += ((_23071[_35965].x * _23071[_35959].y) * spvDepthCast(_402).sample_compare(_402Smplr, float3(fast::clamp(_382._m22.xy * (_23119 + float2(_23072[_35965].x, _23072[_35959].y)), _23061.xy, _23061.zw), _22785).xy, _22785));
                                        _35965++;
                                        continue;
                                    }
                                }
                                _35969 = _35962 * (_23123 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _35981 = _35969;
                            break;
                        } while(false);
                        _35982 = _35981;
                    }
                    else
                    {
                        _35982 = 1.0;
                    }
                    float _19945 = dot(_35590, _22503);
                    float3 _19949 = float3(dot(_35588, _22503), _19945, dot(_35592, _22503));
                    float3 _35985;
                    if (_19749)
                    {
                        float3 _23257 = fast::clamp(_19949, float3(-1.0), float3(1.0));
                        float3 _23264 = sqrt(fast::max(float3(1.0) - (_23257 * _23257), float3(0.0)));
                        float3 _35984;
                        _35984 = float3(0.0);
                        for (int _35983 = 0; _35983 < 2; )
                        {
                            _35984 += ((((fast::max(_23257, float3(0.0)) * 0.533333301544189453125) + ((fast::max((_23257 * _3626[_35983]) - (_23264 * _3634[_35983]), float3(0.0)) + fast::max((_23257 * _3626[_35983]) + (_23264 * _3634[_35983]), float3(0.0))) * 0.22207589447498321533203125)) + ((fast::max((_23257 * _3640[_35983]) - (_23264 * _3647[_35983]), float3(0.0)) + fast::max((_23257 * _3640[_35983]) + (_23264 * _3647[_35983]), float3(0.0))) * 0.011257399804890155792236328125)) * ((_35983 == 0) ? 0.430000007152557373046875 : 0.569999992847442626953125));
                            _35983++;
                            continue;
                        }
                        _35985 = mix(fast::max(_19949, float3(0.0)), _35984, _19733);
                    }
                    else
                    {
                        _35985 = float3(fast::max(_19945, 0.0));
                    }
                    float3 _19968 = _35870 + ((_35985 * _22534) * _35982);
                    float3 _36025;
                    do
                    {
                        float3 _23374 = fast::normalize(_22503 + _5898);
                        float _23378 = fast::clamp(dot(_35579, _22503), 0.0, 1.0);
                        if (_23378 <= 0.0)
                        {
                            _36025 = float3(0.0);
                            break;
                        }
                        float _23386 = fast::clamp(dot(_35579, _23374), 0.0, 1.0);
                        float _23397 = fast::clamp(_35577 * _3372._m2.x, 0.04500000178813934326171875, 1.0);
                        float _23400 = _23397 * _23397;
                        float _23460 = _23400 * _23400;
                        float _23463 = _23386 * _23386;
                        float _23467 = (_23463 * (_23460 - 1.0)) + 1.0;
                        float _23485 = _19719 * _19719;
                        float _23487 = 1.0 - _23460;
                        float _23496 = _23378 * _23378;
                        float _23408 = (_23460 / ((3.1415927410125732421875 * _23467) * _23467)) * (0.5 / fast::max((_23378 * sqrt((_23485 * _23487) + _23460)) + (_19719 * sqrt((_23496 * _23487) + _23460)), 9.9999997473787516355514526367188e-06));
                        float _36024;
                        if (_3372._m2.w > 0.5)
                        {
                            float _23417 = fast::clamp(_35577 * _3372._m2.y, 0.04500000178813934326171875, 1.0);
                            float _23420 = _23417 * _23417;
                            float _23515 = _23420 * _23420;
                            float _23522 = (_23463 * (_23515 - 1.0)) + 1.0;
                            float _23542 = 1.0 - _23515;
                            _36024 = mix(_23408, (_23515 / ((3.1415927410125732421875 * _23522) * _23522)) * (0.5 / fast::max((_23378 * sqrt((_23485 * _23542) + _23515)) + (_19719 * sqrt((_23496 * _23542) + _23515)), 9.9999997473787516355514526367188e-06)), _3372._m2.z);
                        }
                        else
                        {
                            _36024 = _23408;
                        }
                        _36025 = (_19727 + ((float3(1.0) - _19727) * powr(1.0 - fast::clamp(dot(_5898, _23374), 0.0, 1.0), 5.0))) * ((_36024 * 3.1415927410125732421875) * _23378);
                        break;
                    } while(false);
                    _19981 = _35928 + ((_36025 * _22534) * _35982);
                    bool _19990;
                    if (_19759)
                    {
                        _19990 = dot(_5909, _22503) < 0.3499999940395355224609375;
                    }
                    else
                    {
                        _19990 = _19759;
                    }
                    if (_19990)
                    {
                        float3 _36137;
                        if (_5914)
                        {
                            float3 _36136;
                            do
                            {
                                if (_22469 >= uint(_382._m21.z + _382._m21.w))
                                {
                                    float _23659 = (1200.0 / _19773) / (0.60000002384185791015625 + (6.0 * _3372._m1.y));
                                    float _23666 = (-_23659) * _23659;
                                    _36136 = (((((float3(0.23299999535083770751953125, 0.4550000131130218505859375, 0.648999989032745361328125) * exp(_23666 * 156.25)) + (float3(0.100000001490116119384765625, 0.3359999954700469970703125, 0.3440000116825103759765625) * exp(_23666 * 20.6611576080322265625))) + (float3(0.1180000007152557373046875, 0.19799999892711639404296875, 0.0) * exp(_23666 * 5.3475933074951171875))) + (float3(0.112999998033046722412109375, 0.007000000216066837310791015625, 0.007000000216066837310791015625) * exp(_23666 * 1.763668537139892578125))) + (float3(0.3580000102519989013671875, 0.0040000001899898052215576171875, 0.0) * exp(_23666 * 0.50251257419586181640625))) + (float3(0.078000001609325408935546875, 0.0, 0.0) * exp(_23666 * 0.13495276868343353271484375));
                                    break;
                                }
                                uint _23731;
                                bool _23734;
                                float3 _23604 = in.m_3136 - (_5909 * 0.0040000001899898052215576171875);
                                float3 _23608 = _23604 + (_22503 * 0.0199999995529651641845703125);
                                float _36073;
                                do
                                {
                                    _23731 = uint(_382._m21.z);
                                    _23734 = _22469 < _23731;
                                    if (_23734)
                                    {
                                        float _23753 = _382._m26[_22469].z * fast::max((_382._m15[_22469] * float4(_23608, 1.0)).w, 0.0);
                                        float4 _23777 = _382._m15[_22469] * float4((_23608 + (_5909 * (_23753 * _382._m25.x))) + (_22503 * (_23753 * _382._m25.y)), 1.0);
                                        float _23779 = _23777.w;
                                        if (_23779 <= 0.0)
                                        {
                                            _36073 = 1.0;
                                            break;
                                        }
                                        float3 _23788 = _23777.xyz / float3(_23779);
                                        float _23790 = _23788.x;
                                        bool _23791 = _23790 < 0.0;
                                        bool _23798;
                                        if (!_23791)
                                        {
                                            _23798 = _23790 > 1.0;
                                        }
                                        else
                                        {
                                            _23798 = _23791;
                                        }
                                        bool _23805;
                                        if (!_23798)
                                        {
                                            _23805 = _23788.y < 0.0;
                                        }
                                        else
                                        {
                                            _23805 = _23798;
                                        }
                                        bool _23812;
                                        if (!_23805)
                                        {
                                            _23812 = _23788.y > 1.0;
                                        }
                                        else
                                        {
                                            _23812 = _23805;
                                        }
                                        bool _23819;
                                        if (!_23812)
                                        {
                                            _23819 = _23788.z > 1.0;
                                        }
                                        else
                                        {
                                            _23819 = _23812;
                                        }
                                        if (_23819)
                                        {
                                            _36073 = 1.0;
                                            break;
                                        }
                                        float _23825 = _23788.z;
                                        float2 _23991 = _382._m22.xy * 0.5;
                                        float2 _23996 = _382._m26[_22469].xy + (_23788.xy * _382._m23.zw);
                                        float4 _24009 = float4(_382._m26[_22469].xy + _23991, (_382._m26[_22469].xy + _382._m23.zw) - _23991);
                                        float _36072;
                                        do
                                        {
                                            int _24035 = int(_382._m22.z);
                                            if (_24035 <= 0)
                                            {
                                                _36072 = spvDepthCast(_402).sample_compare(_402Smplr, float3(fast::clamp(_23996, _24009.xy, _24009.zw), _23825).xy, _23825);
                                                break;
                                            }
                                            float2 _24058 = (_23996 / _382._m22.xy) + float2(0.5);
                                            float2 _24059 = floor(_24058);
                                            float2 _24064 = _24058 - _24059;
                                            float2 _24067 = _24059 - float2(0.5);
                                            bool _24071 = _24035 == 1;
                                            if (_24071)
                                            {
                                                float2 _24074 = _24064 * 2.0;
                                                _24019[0] = float2(3.0) - _24074;
                                                _24019[1] = float2(1.0) + _24074;
                                                _24020[0] = ((float2(2.0) - _24064) / _24019[0]) - float2(1.0);
                                                _24020[1] = (_24064 / _24019[1]) + float2(1.0);
                                            }
                                            else
                                            {
                                                float2 _24101 = _24064 * 3.0;
                                                _24019[0] = float2(4.0) - _24101;
                                                _24019[1] = float2(7.0);
                                                _24019[2] = float2(1.0) + _24101;
                                                _24020[0] = ((float2(3.0) - (_24064 * 2.0)) / _24019[0]) - float2(2.0);
                                                _24020[1] = (float2(3.0) + _24064) / _24019[1];
                                                _24020[2] = (_24064 / _24019[2]) + float2(2.0);
                                            }
                                            int _37932 = _24071 ? 2 : 3;
                                            int _36062;
                                            float _36065;
                                            _36065 = 0.0;
                                            _36062 = 0;
                                            float _36071;
                                            for (; _36062 < _37932; _36065 = _36071, _36062++)
                                            {
                                                _36071 = _36065;
                                                for (int _36068 = 0; _36068 < _37932; )
                                                {
                                                    _36071 += ((_24019[_36068].x * _24019[_36062].y) * spvDepthCast(_402).sample_compare(_402Smplr, float3(fast::clamp(_382._m22.xy * (_24067 + float2(_24020[_36068].x, _24020[_36062].y)), _24009.xy, _24009.zw), _23825).xy, _23825));
                                                    _36068++;
                                                    continue;
                                                }
                                            }
                                            _36072 = _36065 * (_24071 ? 0.0625 : 0.0069444444961845874786376953125);
                                            break;
                                        } while(false);
                                        _36073 = _36072;
                                        break;
                                    }
                                    uint _23835 = _22469 - _23731;
                                    if (_23835 >= uint(_382._m21.w))
                                    {
                                        _36073 = 1.0;
                                        break;
                                    }
                                    float _23856 = _382._m27[_23835].w * length(_23608 - _382._m27[_23835].xyz);
                                    float3 _23874 = ((_23608 + (_5909 * (_23856 * _382._m25.x))) + (_22503 * (_23856 * _382._m25.y))) - _382._m27[_23835].xyz;
                                    float3 _23876 = abs(_23874);
                                    float _23878 = _23876.x;
                                    float _23880 = _23876.y;
                                    bool _23881 = _23878 >= _23880;
                                    bool _23889;
                                    if (_23881)
                                    {
                                        _23889 = _23878 >= _23876.z;
                                    }
                                    else
                                    {
                                        _23889 = _23881;
                                    }
                                    float _36047;
                                    int _36049;
                                    if (_23889)
                                    {
                                        _36049 = (_23874.x > 0.0) ? 0 : 1;
                                        _36047 = _23878;
                                    }
                                    else
                                    {
                                        float _23901 = _23876.z;
                                        bool _23902 = _23880 >= _23901;
                                        int _36050;
                                        if (_23902)
                                        {
                                            _36050 = (_23874.y > 0.0) ? 2 : 3;
                                        }
                                        else
                                        {
                                            _36050 = (_23874.z > 0.0) ? 4 : 5;
                                        }
                                        _36049 = _36050;
                                        _36047 = _23902 ? _23880 : _23901;
                                    }
                                    if (_36047 <= 0.0)
                                    {
                                        _36073 = 1.0;
                                        break;
                                    }
                                    float2 _23939 = float2(dot(_23874, _1060[_36049]), dot(_23874, _1069[_36049])) / float2(_36047 * _382._m24.z);
                                    float _23946 = _382._m28[_23835].z + (_382._m28[_23835].w / _36047);
                                    if (_23946 > 1.0)
                                    {
                                        _36073 = 1.0;
                                        break;
                                    }
                                    float2 _23964 = _382._m28[_23835].xy + (float2(float(spvSMod(_36049, 3)), float(_36049 / 3)) * _382._m24.xy);
                                    float2 _24204 = _382._m22.xy * 0.5;
                                    float2 _24209 = _23964 + (float2(0.5 + (0.5 * _23939.x), 0.5 - (0.5 * _23939.y)) * _382._m24.xy);
                                    float4 _24222 = float4(_23964 + _24204, (_23964 + _382._m24.xy) - _24204);
                                    float _36061;
                                    do
                                    {
                                        int _24248 = int(_382._m22.z);
                                        if (_24248 <= 0)
                                        {
                                            _36061 = spvDepthCast(_402).sample_compare(_402Smplr, float3(fast::clamp(_24209, _24222.xy, _24222.zw), _23946).xy, _23946);
                                            break;
                                        }
                                        float2 _24271 = (_24209 / _382._m22.xy) + float2(0.5);
                                        float2 _24272 = floor(_24271);
                                        float2 _24277 = _24271 - _24272;
                                        float2 _24280 = _24272 - float2(0.5);
                                        bool _24284 = _24248 == 1;
                                        if (_24284)
                                        {
                                            float2 _24287 = _24277 * 2.0;
                                            _24232[0] = float2(3.0) - _24287;
                                            _24232[1] = float2(1.0) + _24287;
                                            _24233[0] = ((float2(2.0) - _24277) / _24232[0]) - float2(1.0);
                                            _24233[1] = (_24277 / _24232[1]) + float2(1.0);
                                        }
                                        else
                                        {
                                            float2 _24314 = _24277 * 3.0;
                                            _24232[0] = float2(4.0) - _24314;
                                            _24232[1] = float2(7.0);
                                            _24232[2] = float2(1.0) + _24314;
                                            _24233[0] = ((float2(3.0) - (_24277 * 2.0)) / _24232[0]) - float2(2.0);
                                            _24233[1] = (float2(3.0) + _24277) / _24232[1];
                                            _24233[2] = (_24277 / _24232[2]) + float2(2.0);
                                        }
                                        int _37935 = _24284 ? 2 : 3;
                                        int _36051;
                                        float _36054;
                                        _36054 = 0.0;
                                        _36051 = 0;
                                        float _36060;
                                        for (; _36051 < _37935; _36054 = _36060, _36051++)
                                        {
                                            _36060 = _36054;
                                            for (int _36057 = 0; _36057 < _37935; )
                                            {
                                                _36060 += ((_24232[_36057].x * _24232[_36051].y) * spvDepthCast(_402).sample_compare(_402Smplr, float3(fast::clamp(_382._m22.xy * (_24280 + float2(_24233[_36057].x, _24233[_36051].y)), _24222.xy, _24222.zw), _23946).xy, _23946));
                                                _36057++;
                                                continue;
                                            }
                                        }
                                        _36061 = _36054 * (_24284 ? 0.0625 : 0.0069444444961845874786376953125);
                                        break;
                                    } while(false);
                                    _36073 = _36061;
                                    break;
                                } while(false);
                                if (_36073 <= 0.0)
                                {
                                    _36136 = float3(0.0);
                                    break;
                                }
                                float3 _36075;
                                float3 _36076;
                                _36076 = float3(1.0);
                                _36075 = float3(0.0);
                                float3 _23642;
                                float3 _24452;
                                for (int _36074 = 0; _36074 < 4; _36076 = _24452, _36075 = _23642, _36074++)
                                {
                                    float _24416 = (_3479[_36074] * 1000.0) / (0.60000002384185791015625 + (6.0 * _3372._m1.y));
                                    float _24423 = (-_24416) * _24416;
                                    _24452 = (((((float3(0.23299999535083770751953125, 0.4550000131130218505859375, 0.648999989032745361328125) * exp(_24423 * 156.25)) + (float3(0.100000001490116119384765625, 0.3359999954700469970703125, 0.3440000116825103759765625) * exp(_24423 * 20.6611576080322265625))) + (float3(0.1180000007152557373046875, 0.19799999892711639404296875, 0.0) * exp(_24423 * 5.3475933074951171875))) + (float3(0.112999998033046722412109375, 0.007000000216066837310791015625, 0.007000000216066837310791015625) * exp(_24423 * 1.763668537139892578125))) + (float3(0.3580000102519989013671875, 0.0040000001899898052215576171875, 0.0) * exp(_24423 * 0.50251257419586181640625))) + (float3(0.078000001609325408935546875, 0.0, 0.0) * exp(_24423 * 0.13495276868343353271484375));
                                    float3 _23635 = _23604 + (_22503 * _3479[_36074]);
                                    float _36103;
                                    do
                                    {
                                        if (_23734)
                                        {
                                            float _24510 = _382._m26[_22469].z * fast::max((_382._m15[_22469] * float4(_23635, 1.0)).w, 0.0);
                                            float4 _24534 = _382._m15[_22469] * float4((_23635 + (_5909 * (_24510 * _382._m25.x))) + (_22503 * (_24510 * _382._m25.y)), 1.0);
                                            float _24536 = _24534.w;
                                            if (_24536 <= 0.0)
                                            {
                                                _36103 = 1.0;
                                                break;
                                            }
                                            float3 _24545 = _24534.xyz / float3(_24536);
                                            float _24547 = _24545.x;
                                            bool _24548 = _24547 < 0.0;
                                            bool _24555;
                                            if (!_24548)
                                            {
                                                _24555 = _24547 > 1.0;
                                            }
                                            else
                                            {
                                                _24555 = _24548;
                                            }
                                            bool _24562;
                                            if (!_24555)
                                            {
                                                _24562 = _24545.y < 0.0;
                                            }
                                            else
                                            {
                                                _24562 = _24555;
                                            }
                                            bool _24569;
                                            if (!_24562)
                                            {
                                                _24569 = _24545.y > 1.0;
                                            }
                                            else
                                            {
                                                _24569 = _24562;
                                            }
                                            bool _24576;
                                            if (!_24569)
                                            {
                                                _24576 = _24545.z > 1.0;
                                            }
                                            else
                                            {
                                                _24576 = _24569;
                                            }
                                            if (_24576)
                                            {
                                                _36103 = 1.0;
                                                break;
                                            }
                                            float _24582 = _24545.z;
                                            float2 _24748 = _382._m22.xy * 0.5;
                                            float2 _24753 = _382._m26[_22469].xy + (_24545.xy * _382._m23.zw);
                                            float4 _24766 = float4(_382._m26[_22469].xy + _24748, (_382._m26[_22469].xy + _382._m23.zw) - _24748);
                                            float _36102;
                                            do
                                            {
                                                int _24792 = int(_382._m22.z);
                                                if (_24792 <= 0)
                                                {
                                                    _36102 = spvDepthCast(_402).sample_compare(_402Smplr, float3(fast::clamp(_24753, _24766.xy, _24766.zw), _24582).xy, _24582);
                                                    break;
                                                }
                                                float2 _24815 = (_24753 / _382._m22.xy) + float2(0.5);
                                                float2 _24816 = floor(_24815);
                                                float2 _24821 = _24815 - _24816;
                                                float2 _24824 = _24816 - float2(0.5);
                                                bool _24828 = _24792 == 1;
                                                if (_24828)
                                                {
                                                    float2 _24831 = _24821 * 2.0;
                                                    _24776[0] = float2(3.0) - _24831;
                                                    _24776[1] = float2(1.0) + _24831;
                                                    _24777[0] = ((float2(2.0) - _24821) / _24776[0]) - float2(1.0);
                                                    _24777[1] = (_24821 / _24776[1]) + float2(1.0);
                                                }
                                                else
                                                {
                                                    float2 _24858 = _24821 * 3.0;
                                                    _24776[0] = float2(4.0) - _24858;
                                                    _24776[1] = float2(7.0);
                                                    _24776[2] = float2(1.0) + _24858;
                                                    _24777[0] = ((float2(3.0) - (_24821 * 2.0)) / _24776[0]) - float2(2.0);
                                                    _24777[1] = (float2(3.0) + _24821) / _24776[1];
                                                    _24777[2] = (_24821 / _24776[2]) + float2(2.0);
                                                }
                                                int _37937 = _24828 ? 2 : 3;
                                                int _36092;
                                                float _36095;
                                                _36095 = 0.0;
                                                _36092 = 0;
                                                float _36101;
                                                for (; _36092 < _37937; _36095 = _36101, _36092++)
                                                {
                                                    _36101 = _36095;
                                                    for (int _36098 = 0; _36098 < _37937; )
                                                    {
                                                        _36101 += ((_24776[_36098].x * _24776[_36092].y) * spvDepthCast(_402).sample_compare(_402Smplr, float3(fast::clamp(_382._m22.xy * (_24824 + float2(_24777[_36098].x, _24777[_36092].y)), _24766.xy, _24766.zw), _24582).xy, _24582));
                                                        _36098++;
                                                        continue;
                                                    }
                                                }
                                                _36102 = _36095 * (_24828 ? 0.0625 : 0.0069444444961845874786376953125);
                                                break;
                                            } while(false);
                                            _36103 = _36102;
                                            break;
                                        }
                                        uint _24592 = _22469 - _23731;
                                        if (_24592 >= uint(_382._m21.w))
                                        {
                                            _36103 = 1.0;
                                            break;
                                        }
                                        float _24613 = _382._m27[_24592].w * length(_23635 - _382._m27[_24592].xyz);
                                        float3 _24631 = ((_23635 + (_5909 * (_24613 * _382._m25.x))) + (_22503 * (_24613 * _382._m25.y))) - _382._m27[_24592].xyz;
                                        float3 _24633 = abs(_24631);
                                        float _24635 = _24633.x;
                                        float _24637 = _24633.y;
                                        bool _24638 = _24635 >= _24637;
                                        bool _24646;
                                        if (_24638)
                                        {
                                            _24646 = _24635 >= _24633.z;
                                        }
                                        else
                                        {
                                            _24646 = _24638;
                                        }
                                        float _36077;
                                        int _36079;
                                        if (_24646)
                                        {
                                            _36079 = (_24631.x > 0.0) ? 0 : 1;
                                            _36077 = _24635;
                                        }
                                        else
                                        {
                                            float _24658 = _24633.z;
                                            bool _24659 = _24637 >= _24658;
                                            int _36080;
                                            if (_24659)
                                            {
                                                _36080 = (_24631.y > 0.0) ? 2 : 3;
                                            }
                                            else
                                            {
                                                _36080 = (_24631.z > 0.0) ? 4 : 5;
                                            }
                                            _36079 = _36080;
                                            _36077 = _24659 ? _24637 : _24658;
                                        }
                                        if (_36077 <= 0.0)
                                        {
                                            _36103 = 1.0;
                                            break;
                                        }
                                        float2 _24696 = float2(dot(_24631, _1060[_36079]), dot(_24631, _1069[_36079])) / float2(_36077 * _382._m24.z);
                                        float _24703 = _382._m28[_24592].z + (_382._m28[_24592].w / _36077);
                                        if (_24703 > 1.0)
                                        {
                                            _36103 = 1.0;
                                            break;
                                        }
                                        float2 _24721 = _382._m28[_24592].xy + (float2(float(spvSMod(_36079, 3)), float(_36079 / 3)) * _382._m24.xy);
                                        float2 _24961 = _382._m22.xy * 0.5;
                                        float2 _24966 = _24721 + (float2(0.5 + (0.5 * _24696.x), 0.5 - (0.5 * _24696.y)) * _382._m24.xy);
                                        float4 _24979 = float4(_24721 + _24961, (_24721 + _382._m24.xy) - _24961);
                                        float _36091;
                                        do
                                        {
                                            int _25005 = int(_382._m22.z);
                                            if (_25005 <= 0)
                                            {
                                                _36091 = spvDepthCast(_402).sample_compare(_402Smplr, float3(fast::clamp(_24966, _24979.xy, _24979.zw), _24703).xy, _24703);
                                                break;
                                            }
                                            float2 _25028 = (_24966 / _382._m22.xy) + float2(0.5);
                                            float2 _25029 = floor(_25028);
                                            float2 _25034 = _25028 - _25029;
                                            float2 _25037 = _25029 - float2(0.5);
                                            bool _25041 = _25005 == 1;
                                            if (_25041)
                                            {
                                                float2 _25044 = _25034 * 2.0;
                                                _24989[0] = float2(3.0) - _25044;
                                                _24989[1] = float2(1.0) + _25044;
                                                _24990[0] = ((float2(2.0) - _25034) / _24989[0]) - float2(1.0);
                                                _24990[1] = (_25034 / _24989[1]) + float2(1.0);
                                            }
                                            else
                                            {
                                                float2 _25071 = _25034 * 3.0;
                                                _24989[0] = float2(4.0) - _25071;
                                                _24989[1] = float2(7.0);
                                                _24989[2] = float2(1.0) + _25071;
                                                _24990[0] = ((float2(3.0) - (_25034 * 2.0)) / _24989[0]) - float2(2.0);
                                                _24990[1] = (float2(3.0) + _25034) / _24989[1];
                                                _24990[2] = (_25034 / _24989[2]) + float2(2.0);
                                            }
                                            int _37940 = _25041 ? 2 : 3;
                                            int _36081;
                                            float _36084;
                                            _36084 = 0.0;
                                            _36081 = 0;
                                            float _36090;
                                            for (; _36081 < _37940; _36084 = _36090, _36081++)
                                            {
                                                _36090 = _36084;
                                                for (int _36087 = 0; _36087 < _37940; )
                                                {
                                                    _36090 += ((_24989[_36087].x * _24989[_36081].y) * spvDepthCast(_402).sample_compare(_402Smplr, float3(fast::clamp(_382._m22.xy * (_25037 + float2(_24990[_36087].x, _24990[_36081].y)), _24979.xy, _24979.zw), _24703).xy, _24703));
                                                    _36087++;
                                                    continue;
                                                }
                                            }
                                            _36091 = _36084 * (_25041 ? 0.0625 : 0.0069444444961845874786376953125);
                                            break;
                                        } while(false);
                                        _36103 = _36091;
                                        break;
                                    } while(false);
                                    _23642 = _36075 + ((_36076 - _24452) * _36103);
                                }
                                _36136 = _36075;
                                break;
                            } while(false);
                            _36137 = _36136;
                        }
                        else
                        {
                            float _25173 = (1200.0 / _19773) / (0.60000002384185791015625 + (6.0 * _3372._m1.y));
                            float _25180 = (-_25173) * _25173;
                            _36137 = (((((float3(0.23299999535083770751953125, 0.4550000131130218505859375, 0.648999989032745361328125) * exp(_25180 * 156.25)) + (float3(0.100000001490116119384765625, 0.3359999954700469970703125, 0.3440000116825103759765625) * exp(_25180 * 20.6611576080322265625))) + (float3(0.1180000007152557373046875, 0.19799999892711639404296875, 0.0) * exp(_25180 * 5.3475933074951171875))) + (float3(0.112999998033046722412109375, 0.007000000216066837310791015625, 0.007000000216066837310791015625) * exp(_25180 * 1.763668537139892578125))) + (float3(0.3580000102519989013671875, 0.0040000001899898052215576171875, 0.0) * exp(_25180 * 0.50251257419586181640625))) + (float3(0.078000001609325408935546875, 0.0, 0.0) * exp(_25180 * 0.13495276868343353271484375));
                        }
                        _37611 = _19968 + ((_36137 * _22534) * ((fast::clamp(0.300000011920928955078125 - dot(_5909, _22503), 0.0, 1.0) * _35580) * 2.0));
                    }
                    else
                    {
                        _37611 = _19968;
                    }
                }
                _35903 = _35928;
                _35868 = _35870;
            }
            else
            {
                _35903 = _19860;
                _35868 = _35869;
            }
            float _20036 = fast::clamp(_35577 * mix(_3372._m2.x, _3372._m2.y, _3372._m2.z), 0.04500000178813934326171875, 1.0);
            float3 _20040 = reflect(-_5898, _35579);
            bool _25226 = _382._m29.x > 0.5;
            float3 _35733;
            float3 _35743;
            if (_25226)
            {
                float _25320 = (_382._m29.z * _35579.x) - (_382._m29.w * _35579.z);
                float _25333 = (_382._m29.w * _35579.x) + (_382._m29.z * _35579.z);
                float _25351 = 1.09254801273345947265625 * _25320;
                spvUnsafeArray<float, 9> _32792 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _35579.y, 0.48860299587249755859375 * _25333, 0.48860299587249755859375 * _25320, _25351 * _35579.y, (1.09254801273345947265625 * _35579.y) * _25333, 0.3153919875621795654296875 * (((3.0 * _25333) * _25333) - 1.0), _25351 * _25333, 0.546274006366729736328125 * ((_25320 * _25320) - (_35579.y * _35579.y)) });
                spvUnsafeArray<float, 9> _25265 = _32792;
                float3 _35718;
                _35718 = float3(0.0);
                for (int _35717 = 0; _35717 < 9; )
                {
                    _35718 += (_2630.read(uint2((int2(496, 256) + int2(_35717, 0))), 0).xyz * _25265[_35717]);
                    _35717++;
                    continue;
                }
                float _25446 = _20040.x;
                float _25451 = _20040.z;
                float2 _25483 = float2((precise::atan2((_382._m29.z * _25446) - (_382._m29.w * _25451), -((_382._m29.w * _25446) + (_382._m29.z * _25451))) * 0.15915493667125701904296875) + 0.5, acos(fast::clamp(_20040.y, -1.0, 1.0)) * 0.3183098733425140380859375);
                float _25415 = _20036 * 5.0;
                int _25418 = min(int(_25415), 4);
                float2 _25504 = (_25483 * float2(_2687[_25418].zw)) - float2(0.5);
                float2 _25506 = floor(_25504);
                float2 _25509 = _25504 - _25506;
                int _25512 = int(_25506.x);
                int _25515 = int(_25506.y);
                int _35719;
                if (_25512 < 0)
                {
                    _35719 = _25512 + _2687[_25418].z;
                }
                else
                {
                    _35719 = _25512;
                }
                int _35720;
                if (_35719 >= _2687[_25418].z)
                {
                    _35720 = _35719 - _2687[_25418].z;
                }
                else
                {
                    _35720 = _35719;
                }
                int _25535 = _35720 + 1;
                int _37941 = (_25535 == _2687[_25418].z) ? 0 : _25535;
                int _25550 = min((_25515 + 1), (_2687[_25418].w - 1));
                int _25552 = max(_25515, 0);
                float3 _25605 = float3(_25509.x);
                int _25425 = _25418 + 1;
                float2 _25637 = (_25483 * float2(_2687[_25425].zw)) - float2(0.5);
                float2 _25639 = floor(_25637);
                float2 _25642 = _25637 - _25639;
                int _25645 = int(_25639.x);
                int _25648 = int(_25639.y);
                int _35726;
                if (_25645 < 0)
                {
                    _35726 = _25645 + _2687[_25425].z;
                }
                else
                {
                    _35726 = _25645;
                }
                int _35727;
                if (_35726 >= _2687[_25425].z)
                {
                    _35727 = _35726 - _2687[_25425].z;
                }
                else
                {
                    _35727 = _35726;
                }
                int _25668 = _35727 + 1;
                int _37942 = (_25668 == _2687[_25425].z) ? 0 : _25668;
                int _25683 = min((_25648 + 1), (_2687[_25425].w - 1));
                int _25685 = max(_25648, 0);
                float3 _25738 = float3(_25642.x);
                float3 _25440 = mix(mix(mix(_2630.read(uint2((_2687[_25418].xy + int2(_35720, _25552))), 0).xyz, _2630.read(uint2((_2687[_25418].xy + int2(_37941, _25552))), 0).xyz, _25605), mix(_2630.read(uint2((_2687[_25418].xy + int2(_35720, _25550))), 0).xyz, _2630.read(uint2((_2687[_25418].xy + int2(_37941, _25550))), 0).xyz, _25605), float3(_25509.y)), mix(mix(_2630.read(uint2((_2687[_25425].xy + int2(_35727, _25685))), 0).xyz, _2630.read(uint2((_2687[_25425].xy + int2(_37942, _25685))), 0).xyz, _25738), mix(_2630.read(uint2((_2687[_25425].xy + int2(_35727, _25683))), 0).xyz, _2630.read(uint2((_2687[_25425].xy + int2(_37942, _25683))), 0).xyz, _25738), float3(_25642.y)), float3(_25415 - float(_25418))) * _382._m29.y;
                _35743 = _25440;
                _35733 = fast::max(_35718, float3(0.0)) * _382._m29.y;
            }
            else
            {
                float3 _25766 = mix(_382._m9.xyz, _382._m8.xyz, float3((_35579.y * 0.5) + 0.5)) * _382._m8.w;
                _35743 = mix(mix(_382._m9.xyz, _382._m8.xyz, float3((_20040.y * 0.5) + 0.5)) * _382._m8.w, _25766, float3(_20036));
                _35733 = _25766;
            }
            float3 _35834;
            if (_382._m34.y > 0.5)
            {
                int _25903 = int(_382._m34.y);
                int _25906 = int(_382._m34.x);
                float3 _35741;
                _35741 = _35733;
                float3 _37604;
                for (int _35740 = 0; _35740 < _25903; _35741 = _37604, _35740++)
                {
                    int _25918 = 8 * (_25906 + _35740);
                    float4 _26127 = as_type<float4>(_1380._m0[_25918 + 3]);
                    float4 _26171 = as_type<float4>(_1380._m0[_25918]);
                    float4 _26177 = as_type<float4>(_1380._m0[_25918 + 1]);
                    float4 _26183 = as_type<float4>(_1380._m0[_25918 + 2]);
                    float3 _26145 = _26171.xyz;
                    float _26149 = _26171.w;
                    float3 _26152 = _26177.xyz;
                    float _26156 = _26177.w;
                    float3 _26159 = _26183.xyz;
                    float _26163 = _26183.w;
                    float3 _26165 = float3(dot(_26145, in.m_3136) + _26149, dot(_26152, in.m_3136) + _26156, dot(_26159, in.m_3136) + _26163);
                    float3 _25927 = _26127.xyz;
                    float _25929 = _26127.w;
                    float _35950;
                    do
                    {
                        float3 _26195 = _25927 - abs(_26165);
                        float _26203 = fast::min(_26195.x, fast::min(_26195.y, _26195.z));
                        if (_26203 <= 0.0)
                        {
                            _35950 = 0.0;
                            break;
                        }
                        if (_25929 <= 0.0)
                        {
                            _35950 = 1.0;
                            break;
                        }
                        float _26215 = fast::min(_26203 / _25929, 1.0);
                        _35950 = (_26215 * _26215) * (3.0 - (2.0 * _26215));
                        break;
                    } while(false);
                    if (_35950 <= 0.0)
                    {
                        _37604 = _35741;
                        continue;
                    }
                    float3 _25938 = as_type<float4>(_1380._m0[_25918 + 4]).xyz;
                    float4 _26236 = as_type<float4>(_1380._m0[_25918 + 5]);
                    int _26242 = int(((device uint*)&_1380._m0[_25918 + 6])[0u]);
                    float _26252 = dot(_26145, _35579);
                    float _26258 = dot(_26152, _35579);
                    float _26264 = dot(_26159, _35579);
                    float3 _26265 = float3(_26252, _26258, _26264);
                    float3 _25958 = (in.m_3136 + (_35579 * _26236.x)) + (_5898 * _26236.y);
                    float3 _25977 = fast::clamp((((float3(dot(_26145, _25958) + _26149, dot(_26152, _25958) + _26156, dot(_26159, _25958) + _26163) + _25927) / fast::max(_25927 * 2.0, float3(9.9999999747524270787835121154785e-07))) * _25938) - float3(0.5), float3(0.0), _25938 - float3(1.0));
                    int3 _25979 = int3(_25938);
                    int3 _25986 = min(int3(_25977), max((_25979 - int3(2)), int3(0)));
                    float3 _25990 = _25977 - float3(_25986);
                    float _26345 = 0.48860299587249755859375 * _26258;
                    float _26348 = 0.48860299587249755859375 * _26264;
                    float _26351 = 0.48860299587249755859375 * _26252;
                    float _26356 = 1.09254801273345947265625 * _26252;
                    float _26359 = _26356 * _26258;
                    float _26365 = (1.09254801273345947265625 * _26258) * _26264;
                    float _26373 = 0.3153919875621795654296875 * (((3.0 * _26264) * _26264) - 1.0);
                    float _26379 = _26356 * _26264;
                    float _26393 = 0.546274006366729736328125 * ((_26252 * _26252) - (_26258 * _26258));
                    int3 _26412 = _25979 - int3(1);
                    int3 _26413 = min(_25986, _26412);
                    int _26418 = _25979.x;
                    int _26422 = _25979.y;
                    int _26430 = _26242 + ((_26413.x + (_26418 * (_26413.y + (_26422 * _26413.z)))) * 4);
                    float3 _26433 = float3(1.0) - _25990;
                    float3 _26451 = (((((float3(_26413) + float3(0.5)) / _25938) * _25927) * 2.0) - _25927) - _26165;
                    float _26461 = dot(_26451 * rsqrt(fast::max(dot(_26451, _26451), 1.0000000133514319600180897396058e-10)), _26265) + 1.0;
                    float _26464 = _26433.x;
                    float _26466 = _26433.y;
                    float _26467 = _26464 * _26466;
                    float _26469 = _26433.z;
                    int _26493 = _26430 + 3;
                    float _26479 = ((_26467 * _26469) * ((0.25 * (_26461 * _26461)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1380._m0[_26493])[1u])).y > 0.5);
                    int _26523 = _26430 + 1;
                    int _26527 = _26430 + 2;
                    float2 _26539 = float2(as_type<half2>(_1380._m0[_26430].y));
                    float2 _26548 = float2(as_type<half2>(_1380._m0[_26523].x));
                    float2 _26557 = float2(as_type<half2>(_1380._m0[_26523].w));
                    float2 _26566 = float2(as_type<half2>(_1380._m0[_26527].z));
                    float3 _26654 = (((((((float3(float2(as_type<half2>(_1380._m0[_26430].x)), _26539.x) * 0.2820949852466583251953125) + (float3(_26539.y, float2(as_type<half2>(_1380._m0[_26430].z))) * _26345)) + (float3(float2(as_type<half2>(_1380._m0[_26430].w)), _26548.x) * _26348)) + (float3(_26548.y, float2(as_type<half2>(_1380._m0[_26523].y))) * _26351)) + (float3(float2(as_type<half2>(_1380._m0[_26523].z)), _26557.x) * _26359)) + (float3(_26557.y, float2(as_type<half2>(_1380._m0[_26527].x))) * _26365)) + (float3(float2(as_type<half2>(_1380._m0[_26527].y)), _26566.x) * _26373)) + (float3(_26566.y, float2(as_type<half2>(_1380._m0[_26527].w))) * _26379);
                    int3 _26682 = min((_25986 + int3(1, 0, 0)), _26412);
                    int _26699 = _26242 + ((_26682.x + (_26418 * (_26682.y + (_26422 * _26682.z)))) * 4);
                    float3 _26720 = (((((float3(_26682) + float3(0.5)) / _25938) * _25927) * 2.0) - _25927) - _26165;
                    float _26730 = dot(_26720 * rsqrt(fast::max(dot(_26720, _26720), 1.0000000133514319600180897396058e-10)), _26265) + 1.0;
                    float _26736 = _25990.x * _26466;
                    int _26762 = _26699 + 3;
                    float _26748 = ((_26736 * _26469) * ((0.25 * (_26730 * _26730)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1380._m0[_26762])[1u])).y > 0.5);
                    int _26792 = _26699 + 1;
                    int _26796 = _26699 + 2;
                    float2 _26808 = float2(as_type<half2>(_1380._m0[_26699].y));
                    float2 _26817 = float2(as_type<half2>(_1380._m0[_26792].x));
                    float2 _26826 = float2(as_type<half2>(_1380._m0[_26792].w));
                    float2 _26835 = float2(as_type<half2>(_1380._m0[_26796].z));
                    float3 _26923 = (((((((float3(float2(as_type<half2>(_1380._m0[_26699].x)), _26808.x) * 0.2820949852466583251953125) + (float3(_26808.y, float2(as_type<half2>(_1380._m0[_26699].z))) * _26345)) + (float3(float2(as_type<half2>(_1380._m0[_26699].w)), _26817.x) * _26348)) + (float3(_26817.y, float2(as_type<half2>(_1380._m0[_26792].y))) * _26351)) + (float3(float2(as_type<half2>(_1380._m0[_26792].z)), _26826.x) * _26359)) + (float3(_26826.y, float2(as_type<half2>(_1380._m0[_26796].x))) * _26365)) + (float3(float2(as_type<half2>(_1380._m0[_26796].y)), _26835.x) * _26373)) + (float3(_26835.y, float2(as_type<half2>(_1380._m0[_26796].w))) * _26379);
                    int3 _26951 = min((_25986 + int3(0, 1, 0)), _26412);
                    int _26968 = _26242 + ((_26951.x + (_26418 * (_26951.y + (_26422 * _26951.z)))) * 4);
                    float3 _26989 = (((((float3(_26951) + float3(0.5)) / _25938) * _25927) * 2.0) - _25927) - _26165;
                    float _26999 = dot(_26989 * rsqrt(fast::max(dot(_26989, _26989), 1.0000000133514319600180897396058e-10)), _26265) + 1.0;
                    float _27005 = _26464 * _25990.y;
                    int _27031 = _26968 + 3;
                    float _27017 = ((_27005 * _26469) * ((0.25 * (_26999 * _26999)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1380._m0[_27031])[1u])).y > 0.5);
                    int _27061 = _26968 + 1;
                    int _27065 = _26968 + 2;
                    float2 _27077 = float2(as_type<half2>(_1380._m0[_26968].y));
                    float2 _27086 = float2(as_type<half2>(_1380._m0[_27061].x));
                    float2 _27095 = float2(as_type<half2>(_1380._m0[_27061].w));
                    float2 _27104 = float2(as_type<half2>(_1380._m0[_27065].z));
                    float3 _27192 = (((((((float3(float2(as_type<half2>(_1380._m0[_26968].x)), _27077.x) * 0.2820949852466583251953125) + (float3(_27077.y, float2(as_type<half2>(_1380._m0[_26968].z))) * _26345)) + (float3(float2(as_type<half2>(_1380._m0[_26968].w)), _27086.x) * _26348)) + (float3(_27086.y, float2(as_type<half2>(_1380._m0[_27061].y))) * _26351)) + (float3(float2(as_type<half2>(_1380._m0[_27061].z)), _27095.x) * _26359)) + (float3(_27095.y, float2(as_type<half2>(_1380._m0[_27065].x))) * _26365)) + (float3(float2(as_type<half2>(_1380._m0[_27065].y)), _27104.x) * _26373)) + (float3(_27104.y, float2(as_type<half2>(_1380._m0[_27065].w))) * _26379);
                    int3 _27220 = min((_25986 + int3(1, 1, 0)), _26412);
                    int _27237 = _26242 + ((_27220.x + (_26418 * (_27220.y + (_26422 * _27220.z)))) * 4);
                    float3 _27258 = (((((float3(_27220) + float3(0.5)) / _25938) * _25927) * 2.0) - _25927) - _26165;
                    float _27268 = dot(_27258 * rsqrt(fast::max(dot(_27258, _27258), 1.0000000133514319600180897396058e-10)), _26265) + 1.0;
                    float _27274 = _25990.x * _25990.y;
                    int _27300 = _27237 + 3;
                    float _27286 = ((_27274 * _26469) * ((0.25 * (_27268 * _27268)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1380._m0[_27300])[1u])).y > 0.5);
                    int _27330 = _27237 + 1;
                    int _27334 = _27237 + 2;
                    float2 _27346 = float2(as_type<half2>(_1380._m0[_27237].y));
                    float2 _27355 = float2(as_type<half2>(_1380._m0[_27330].x));
                    float2 _27364 = float2(as_type<half2>(_1380._m0[_27330].w));
                    float2 _27373 = float2(as_type<half2>(_1380._m0[_27334].z));
                    float3 _27461 = (((((((float3(float2(as_type<half2>(_1380._m0[_27237].x)), _27346.x) * 0.2820949852466583251953125) + (float3(_27346.y, float2(as_type<half2>(_1380._m0[_27237].z))) * _26345)) + (float3(float2(as_type<half2>(_1380._m0[_27237].w)), _27355.x) * _26348)) + (float3(_27355.y, float2(as_type<half2>(_1380._m0[_27330].y))) * _26351)) + (float3(float2(as_type<half2>(_1380._m0[_27330].z)), _27364.x) * _26359)) + (float3(_27364.y, float2(as_type<half2>(_1380._m0[_27334].x))) * _26365)) + (float3(float2(as_type<half2>(_1380._m0[_27334].y)), _27373.x) * _26373)) + (float3(_27373.y, float2(as_type<half2>(_1380._m0[_27334].w))) * _26379);
                    int3 _27489 = min((_25986 + int3(0, 0, 1)), _26412);
                    int _27506 = _26242 + ((_27489.x + (_26418 * (_27489.y + (_26422 * _27489.z)))) * 4);
                    float3 _27527 = (((((float3(_27489) + float3(0.5)) / _25938) * _25927) * 2.0) - _25927) - _26165;
                    float _27537 = dot(_27527 * rsqrt(fast::max(dot(_27527, _27527), 1.0000000133514319600180897396058e-10)), _26265) + 1.0;
                    int _27569 = _27506 + 3;
                    float _27555 = ((_26467 * _25990.z) * ((0.25 * (_27537 * _27537)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1380._m0[_27569])[1u])).y > 0.5);
                    int _27599 = _27506 + 1;
                    int _27603 = _27506 + 2;
                    float2 _27615 = float2(as_type<half2>(_1380._m0[_27506].y));
                    float2 _27624 = float2(as_type<half2>(_1380._m0[_27599].x));
                    float2 _27633 = float2(as_type<half2>(_1380._m0[_27599].w));
                    float2 _27642 = float2(as_type<half2>(_1380._m0[_27603].z));
                    float3 _27730 = (((((((float3(float2(as_type<half2>(_1380._m0[_27506].x)), _27615.x) * 0.2820949852466583251953125) + (float3(_27615.y, float2(as_type<half2>(_1380._m0[_27506].z))) * _26345)) + (float3(float2(as_type<half2>(_1380._m0[_27506].w)), _27624.x) * _26348)) + (float3(_27624.y, float2(as_type<half2>(_1380._m0[_27599].y))) * _26351)) + (float3(float2(as_type<half2>(_1380._m0[_27599].z)), _27633.x) * _26359)) + (float3(_27633.y, float2(as_type<half2>(_1380._m0[_27603].x))) * _26365)) + (float3(float2(as_type<half2>(_1380._m0[_27603].y)), _27642.x) * _26373)) + (float3(_27642.y, float2(as_type<half2>(_1380._m0[_27603].w))) * _26379);
                    float4 _26057 = (((float4((_26654 + (float3(float2(as_type<half2>(_1380._m0[_26493].x)), float2(as_type<half2>(_1380._m0[_26493].y)).x) * _26393)) * _26479, _26479) + float4((_26923 + (float3(float2(as_type<half2>(_1380._m0[_26762].x)), float2(as_type<half2>(_1380._m0[_26762].y)).x) * _26393)) * _26748, _26748)) + float4((_27192 + (float3(float2(as_type<half2>(_1380._m0[_27031].x)), float2(as_type<half2>(_1380._m0[_27031].y)).x) * _26393)) * _27017, _27017)) + float4((_27461 + (float3(float2(as_type<half2>(_1380._m0[_27300].x)), float2(as_type<half2>(_1380._m0[_27300].y)).x) * _26393)) * _27286, _27286)) + float4((_27730 + (float3(float2(as_type<half2>(_1380._m0[_27569].x)), float2(as_type<half2>(_1380._m0[_27569].y)).x) * _26393)) * _27555, _27555);
                    int3 _27758 = min((_25986 + int3(1, 0, 1)), _26412);
                    int _27775 = _26242 + ((_27758.x + (_26418 * (_27758.y + (_26422 * _27758.z)))) * 4);
                    float3 _27796 = (((((float3(_27758) + float3(0.5)) / _25938) * _25927) * 2.0) - _25927) - _26165;
                    float _27806 = dot(_27796 * rsqrt(fast::max(dot(_27796, _27796), 1.0000000133514319600180897396058e-10)), _26265) + 1.0;
                    int _27838 = _27775 + 3;
                    float _27824 = ((_26736 * _25990.z) * ((0.25 * (_27806 * _27806)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1380._m0[_27838])[1u])).y > 0.5);
                    int _27868 = _27775 + 1;
                    int _27872 = _27775 + 2;
                    float2 _27884 = float2(as_type<half2>(_1380._m0[_27775].y));
                    float2 _27893 = float2(as_type<half2>(_1380._m0[_27868].x));
                    float2 _27902 = float2(as_type<half2>(_1380._m0[_27868].w));
                    float2 _27911 = float2(as_type<half2>(_1380._m0[_27872].z));
                    float3 _27999 = (((((((float3(float2(as_type<half2>(_1380._m0[_27775].x)), _27884.x) * 0.2820949852466583251953125) + (float3(_27884.y, float2(as_type<half2>(_1380._m0[_27775].z))) * _26345)) + (float3(float2(as_type<half2>(_1380._m0[_27775].w)), _27893.x) * _26348)) + (float3(_27893.y, float2(as_type<half2>(_1380._m0[_27868].y))) * _26351)) + (float3(float2(as_type<half2>(_1380._m0[_27868].z)), _27902.x) * _26359)) + (float3(_27902.y, float2(as_type<half2>(_1380._m0[_27872].x))) * _26365)) + (float3(float2(as_type<half2>(_1380._m0[_27872].y)), _27911.x) * _26373)) + (float3(_27911.y, float2(as_type<half2>(_1380._m0[_27872].w))) * _26379);
                    int3 _28027 = min((_25986 + int3(0, 1, 1)), _26412);
                    int _28044 = _26242 + ((_28027.x + (_26418 * (_28027.y + (_26422 * _28027.z)))) * 4);
                    float3 _28065 = (((((float3(_28027) + float3(0.5)) / _25938) * _25927) * 2.0) - _25927) - _26165;
                    float _28075 = dot(_28065 * rsqrt(fast::max(dot(_28065, _28065), 1.0000000133514319600180897396058e-10)), _26265) + 1.0;
                    int _28107 = _28044 + 3;
                    float _28093 = ((_27005 * _25990.z) * ((0.25 * (_28075 * _28075)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1380._m0[_28107])[1u])).y > 0.5);
                    int _28137 = _28044 + 1;
                    int _28141 = _28044 + 2;
                    float2 _28153 = float2(as_type<half2>(_1380._m0[_28044].y));
                    float2 _28162 = float2(as_type<half2>(_1380._m0[_28137].x));
                    float2 _28171 = float2(as_type<half2>(_1380._m0[_28137].w));
                    float2 _28180 = float2(as_type<half2>(_1380._m0[_28141].z));
                    float3 _28268 = (((((((float3(float2(as_type<half2>(_1380._m0[_28044].x)), _28153.x) * 0.2820949852466583251953125) + (float3(_28153.y, float2(as_type<half2>(_1380._m0[_28044].z))) * _26345)) + (float3(float2(as_type<half2>(_1380._m0[_28044].w)), _28162.x) * _26348)) + (float3(_28162.y, float2(as_type<half2>(_1380._m0[_28137].y))) * _26351)) + (float3(float2(as_type<half2>(_1380._m0[_28137].z)), _28171.x) * _26359)) + (float3(_28171.y, float2(as_type<half2>(_1380._m0[_28141].x))) * _26365)) + (float3(float2(as_type<half2>(_1380._m0[_28141].y)), _28180.x) * _26373)) + (float3(_28180.y, float2(as_type<half2>(_1380._m0[_28141].w))) * _26379);
                    int3 _28296 = min((_25986 + int3(1)), _26412);
                    int _28313 = _26242 + ((_28296.x + (_26418 * (_28296.y + (_26422 * _28296.z)))) * 4);
                    float3 _28334 = (((((float3(_28296) + float3(0.5)) / _25938) * _25927) * 2.0) - _25927) - _26165;
                    float _28344 = dot(_28334 * rsqrt(fast::max(dot(_28334, _28334), 1.0000000133514319600180897396058e-10)), _26265) + 1.0;
                    int _28376 = _28313 + 3;
                    float _28362 = ((_27274 * _25990.z) * ((0.25 * (_28344 * _28344)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1380._m0[_28376])[1u])).y > 0.5);
                    int _28406 = _28313 + 1;
                    int _28410 = _28313 + 2;
                    float2 _28422 = float2(as_type<half2>(_1380._m0[_28313].y));
                    float2 _28431 = float2(as_type<half2>(_1380._m0[_28406].x));
                    float2 _28440 = float2(as_type<half2>(_1380._m0[_28406].w));
                    float2 _28449 = float2(as_type<half2>(_1380._m0[_28410].z));
                    float3 _28537 = (((((((float3(float2(as_type<half2>(_1380._m0[_28313].x)), _28422.x) * 0.2820949852466583251953125) + (float3(_28422.y, float2(as_type<half2>(_1380._m0[_28313].z))) * _26345)) + (float3(float2(as_type<half2>(_1380._m0[_28313].w)), _28431.x) * _26348)) + (float3(_28431.y, float2(as_type<half2>(_1380._m0[_28406].y))) * _26351)) + (float3(float2(as_type<half2>(_1380._m0[_28406].z)), _28440.x) * _26359)) + (float3(_28440.y, float2(as_type<half2>(_1380._m0[_28410].x))) * _26365)) + (float3(float2(as_type<half2>(_1380._m0[_28410].y)), _28449.x) * _26373)) + (float3(_28449.y, float2(as_type<half2>(_1380._m0[_28410].w))) * _26379);
                    float4 _26096 = ((_26057 + float4((_27999 + (float3(float2(as_type<half2>(_1380._m0[_27838].x)), float2(as_type<half2>(_1380._m0[_27838].y)).x) * _26393)) * _27824, _27824)) + float4((_28268 + (float3(float2(as_type<half2>(_1380._m0[_28107].x)), float2(as_type<half2>(_1380._m0[_28107].y)).x) * _26393)) * _28093, _28093)) + float4((_28537 + (float3(float2(as_type<half2>(_1380._m0[_28376].x)), float2(as_type<half2>(_1380._m0[_28376].y)).x) * _26393)) * _28362, _28362);
                    float _26100 = _26096.w;
                    float3 _37605;
                    if (_26100 > 9.9999997473787516355514526367188e-06)
                    {
                        _37605 = mix(_35741, (fast::max(_26096.xyz, float3(0.0)) / float3(_26100)) * _26236.z, float3(_35950));
                    }
                    else
                    {
                        _37605 = _35741;
                    }
                    _37604 = _37605;
                }
                _35834 = _35741;
            }
            else
            {
                _35834 = _35733;
            }
            float3 _35855;
            if (_382._m34.x > 0.5)
            {
                int _28585 = int(_382._m34.x);
                float _35746;
                float3 _35812;
                _35812 = float3(0.0);
                _35746 = 0.0;
                float _37609;
                float3 _37610;
                for (int _35745 = 0; _35745 < _28585; _35812 = _37610, _35746 = _37609, _35745++)
                {
                    if (_35746 > 0.999000012874603271484375)
                    {
                        break;
                    }
                    int _28597 = _35745 * 8;
                    float4 _28712 = as_type<float4>(_1380._m0[_28597]);
                    float4 _28718 = as_type<float4>(_1380._m0[_28597 + 1]);
                    float4 _28724 = as_type<float4>(_1380._m0[_28597 + 2]);
                    float3 _28686 = _28712.xyz;
                    float3 _28693 = _28718.xyz;
                    float3 _28700 = _28724.xyz;
                    float3 _28706 = float3(dot(_28686, in.m_3136) + _28712.w, dot(_28693, in.m_3136) + _28718.w, dot(_28700, in.m_3136) + _28724.w);
                    float4 _28730 = as_type<float4>(_1380._m0[_28597 + 3]);
                    float _28608 = _28730.w;
                    float _35747;
                    do
                    {
                        float3 _28742 = _28730.xyz - abs(_28706);
                        float _28750 = fast::min(_28742.x, fast::min(_28742.y, _28742.z));
                        if (_28750 <= 0.0)
                        {
                            _35747 = 0.0;
                            break;
                        }
                        if (_28608 <= 0.0)
                        {
                            _35747 = 1.0;
                            break;
                        }
                        float _28762 = fast::min(_28750 / _28608, 1.0);
                        _35747 = (_28762 * _28762) * (3.0 - (2.0 * _28762));
                        break;
                    } while(false);
                    if (_35747 <= 0.0)
                    {
                        _37610 = _35812;
                        _37609 = _35746;
                        continue;
                    }
                    float4 _28777 = as_type<float4>(_1380._m0[_28597 + 4]);
                    float4 _28783 = as_type<float4>(_1380._m0[_28597 + 5]);
                    float3 _28806 = float3(dot(_28686, _20040), dot(_28693, _20040), dot(_28700, _20040));
                    float3 _35749;
                    if (_28777.w > 0.5)
                    {
                        float3 _28630 = _28777.xyz;
                        float3 _28836 = -_28630;
                        float3 _28838 = fast::clamp(_28706, _28836, _28630);
                        float3 _28848 = step(float3(9.9999999747524270787835121154785e-07), abs(_28806));
                        float3 _28858 = mix(float3(1000000015047466219876688855040.0), (mix(_28836, _28630, step(float3(0.0), _28806)) - _28838) / mix(float3(9.9999999747524270787835121154785e-07), _28806, _28848), _28848);
                        float3 _28874 = (_28838 + (_28806 * fast::max(fast::min(_28858.x, fast::min(_28858.y, _28858.z)), 0.0))) - _28783.xyz;
                        float3 _35748;
                        if (dot(_28874, _28874) > 9.9999999600419720025001879548654e-13)
                        {
                            _35748 = fast::normalize(_28874);
                        }
                        else
                        {
                            _35748 = _28806;
                        }
                        _35749 = _35748;
                    }
                    else
                    {
                        _35749 = _28806;
                    }
                    int _28891 = int(((device uint*)&_1380._m0[_28597 + 6])[0u]);
                    float2 _28941 = float2((precise::atan2(_35749.x, -_35749.z) * 0.15915493667125701904296875) + 0.5, acos(fast::clamp(_35749.y, -1.0, 1.0)) * 0.3183098733425140380859375);
                    float _28907 = _20036 * 5.0;
                    int _28910 = min(int(_28907), 4);
                    int _28981 = _28891 + _1452[_28910].x;
                    float2 _28988 = (_28941 * float2(_1452[_28910].yz)) - float2(0.5);
                    float2 _28990 = floor(_28988);
                    float2 _28993 = _28988 - _28990;
                    int _28996 = int(_28990.x);
                    int _28999 = int(_28990.y);
                    int _35750;
                    if (_28996 < 0)
                    {
                        _35750 = _28996 + _1452[_28910].y;
                    }
                    else
                    {
                        _35750 = _28996;
                    }
                    int _35751;
                    if (_35750 >= _1452[_28910].y)
                    {
                        _35751 = _35750 - _1452[_28910].y;
                    }
                    else
                    {
                        _35751 = _35750;
                    }
                    int _29019 = _35751 + 1;
                    int _37943 = (_29019 == _1452[_28910].y) ? 0 : _29019;
                    int _29087 = _28981 + (max(_28999, 0) * _1452[_28910].y);
                    int _29089 = _29087 + _35751;
                    int _29091 = _29089 >> 1;
                    uint2 _35757;
                    if ((_29089 & 1) == 0)
                    {
                        _35757 = _1380._m0[_29091].xy;
                    }
                    else
                    {
                        _35757 = _1380._m0[_29091].zw;
                    }
                    int _29127 = _29087 + _37943;
                    int _29129 = _29127 >> 1;
                    uint2 _35759;
                    if ((_29127 & 1) == 0)
                    {
                        _35759 = _1380._m0[_29129].xy;
                    }
                    else
                    {
                        _35759 = _1380._m0[_29129].zw;
                    }
                    int _29163 = _28981 + (min((_28999 + 1), (_1452[_28910].z - 1)) * _1452[_28910].y);
                    int _29165 = _29163 + _35751;
                    int _29167 = _29165 >> 1;
                    uint2 _35762;
                    if ((_29165 & 1) == 0)
                    {
                        _35762 = _1380._m0[_29167].xy;
                    }
                    else
                    {
                        _35762 = _1380._m0[_29167].zw;
                    }
                    int _29203 = _29163 + _37943;
                    int _29205 = _29203 >> 1;
                    uint2 _35763;
                    if ((_29203 & 1) == 0)
                    {
                        _35763 = _1380._m0[_29205].xy;
                    }
                    else
                    {
                        _35763 = _1380._m0[_29205].zw;
                    }
                    float3 _29065 = float3(_28993.x);
                    int _28916 = _28910 + 1;
                    int _29268 = _28891 + _1452[_28916].x;
                    float2 _29275 = (_28941 * float2(_1452[_28916].yz)) - float2(0.5);
                    float2 _29277 = floor(_29275);
                    float2 _29280 = _29275 - _29277;
                    int _29283 = int(_29277.x);
                    int _29286 = int(_29277.y);
                    int _35764;
                    if (_29283 < 0)
                    {
                        _35764 = _29283 + _1452[_28916].y;
                    }
                    else
                    {
                        _35764 = _29283;
                    }
                    int _35765;
                    if (_35764 >= _1452[_28916].y)
                    {
                        _35765 = _35764 - _1452[_28916].y;
                    }
                    else
                    {
                        _35765 = _35764;
                    }
                    int _29306 = _35765 + 1;
                    int _37944 = (_29306 == _1452[_28916].y) ? 0 : _29306;
                    int _29374 = _29268 + (max(_29286, 0) * _1452[_28916].y);
                    int _29376 = _29374 + _35765;
                    int _29378 = _29376 >> 1;
                    uint2 _35771;
                    if ((_29376 & 1) == 0)
                    {
                        _35771 = _1380._m0[_29378].xy;
                    }
                    else
                    {
                        _35771 = _1380._m0[_29378].zw;
                    }
                    int _29414 = _29374 + _37944;
                    int _29416 = _29414 >> 1;
                    uint2 _35773;
                    if ((_29414 & 1) == 0)
                    {
                        _35773 = _1380._m0[_29416].xy;
                    }
                    else
                    {
                        _35773 = _1380._m0[_29416].zw;
                    }
                    int _29450 = _29268 + (min((_29286 + 1), (_1452[_28916].z - 1)) * _1452[_28916].y);
                    int _29452 = _29450 + _35765;
                    int _29454 = _29452 >> 1;
                    uint2 _35776;
                    if ((_29452 & 1) == 0)
                    {
                        _35776 = _1380._m0[_29454].xy;
                    }
                    else
                    {
                        _35776 = _1380._m0[_29454].zw;
                    }
                    int _29490 = _29450 + _37944;
                    int _29492 = _29490 >> 1;
                    uint2 _35777;
                    if ((_29490 & 1) == 0)
                    {
                        _35777 = _1380._m0[_29492].xy;
                    }
                    else
                    {
                        _35777 = _1380._m0[_29492].zw;
                    }
                    float3 _29352 = float3(_29280.x);
                    float3 _28646 = mix(mix(mix(float3(float2(as_type<half2>(_35757.x)), float2(as_type<half2>(_35757.y)).x), float3(float2(as_type<half2>(_35759.x)), float2(as_type<half2>(_35759.y)).x), _29065), mix(float3(float2(as_type<half2>(_35762.x)), float2(as_type<half2>(_35762.y)).x), float3(float2(as_type<half2>(_35763.x)), float2(as_type<half2>(_35763.y)).x), _29065), float3(_28993.y)), mix(mix(float3(float2(as_type<half2>(_35771.x)), float2(as_type<half2>(_35771.y)).x), float3(float2(as_type<half2>(_35773.x)), float2(as_type<half2>(_35773.y)).x), _29352), mix(float3(float2(as_type<half2>(_35776.x)), float2(as_type<half2>(_35776.y)).x), float3(float2(as_type<half2>(_35777.x)), float2(as_type<half2>(_35777.y)).x), _29352), float3(_29280.y)), float3(_28907 - float(_28910))) * _28783.w;
                    float _28650 = _35747 * (1.0 - _35746);
                    _37610 = _35812 + (_28646 * _28650);
                    _37609 = _35746 + _28650;
                }
                _35855 = _35812 + (_35743 * (1.0 - _35746));
            }
            else
            {
                _35855 = _35743;
            }
            float2 _35856;
            if (_25226)
            {
                _35856 = _2731.sample(_2733, (((float2(_19719, _20036) * 31.0) + float2(0.5)) * float2(0.03125))).xy;
            }
            else
            {
                float4 _29559 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * _20036) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);
                float _29561 = _29559.x;
                _35856 = (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_29561 * _29561, exp2((-9.27999973297119140625) * _19719)) * _29561) + _29559.y)) + _29559.zw;
            }
            float3 _20057 = (_19727 * _35856.x) + float3(_35856.y);
            float3 _20075 = _35903 + ((_20057 * _35855) * _35576);
            _37181 = _20075;
            _36598 = ((_35543 * (1.0 - _35578)) * ((_35868 * (float3(1.0) - _19727)) + (((float3(1.0) - _20057) * _35834) * _35576))) + _20075;
        }
        _37172 = _37181;
        _36594 = _36598;
    }
    float4 _6249 = _6244.sample(_2632, _5676);
    float _6267 = -length(_5897);
    float _36785;
    if (_382._m9.w != 0.0)
    {
        float _6291 = _382._m9.w * (in.m_3136 - _382._m6.xyz).y;
        float _36782;
        if (abs(_6291) < 9.9999997473787516355514526367188e-05)
        {
            _36782 = 1.0 - (0.5 * _6291);
        }
        else
        {
            _36782 = (1.0 - exp(fast::min(-_6291, 60.0))) / _6291;
        }
        _36785 = 1.0 - exp((_6267 * (_382._m7.w * exp(fast::min((-_382._m9.w) * (_382._m6.y - _382._m6.w), 30.0)))) * _36782);
    }
    else
    {
        _36785 = 1.0 - exp(_6267 * _382._m7.w);
    }
    float3 _37167;
    if (_382._m34.z > 0.5)
    {
        float3 _36973;
        if (_382._m29.x > 0.5)
        {
            float _29637 = (_382._m29.z * _35548.x) - (_382._m29.w * _35548.z);
            float _29650 = (_382._m29.w * _35548.x) + (_382._m29.z * _35548.z);
            float _29668 = 1.09254801273345947265625 * _29637;
            spvUnsafeArray<float, 9> _32654 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _35548.y, 0.48860299587249755859375 * _29650, 0.48860299587249755859375 * _29637, _29668 * _35548.y, (1.09254801273345947265625 * _35548.y) * _29650, 0.3153919875621795654296875 * (((3.0 * _29650) * _29650) - 1.0), _29668 * _29650, 0.546274006366729736328125 * ((_29637 * _29637) - (_35548.y * _35548.y)) });
            spvUnsafeArray<float, 9> _29582 = _32654;
            float3 _36972;
            _36972 = float3(0.0);
            for (int _36971 = 0; _36971 < 9; )
            {
                _36972 += (_2630.read(uint2((int2(496, 256) + int2(_36971, 0))), 0).xyz * _29582[_36971]);
                _36971++;
                continue;
            }
            _36973 = fast::max(_36972, float3(0.0)) * _382._m29.y;
        }
        else
        {
            _36973 = mix(_382._m9.xyz, _382._m8.xyz, float3((_35548.y * 0.5) + 0.5)) * _382._m8.w;
        }
        float3 _36978;
        if (_382._m34.y > 0.5)
        {
            int _29845 = int(_382._m34.y);
            int _29848 = int(_382._m34.x);
            float3 _36977;
            _36977 = _36973;
            float3 _37697;
            for (int _36976 = 0; _36976 < _29845; _36977 = _37697, _36976++)
            {
                int _29860 = 8 * (_29848 + _36976);
                float4 _30069 = as_type<float4>(_1380._m0[_29860 + 3]);
                float4 _30113 = as_type<float4>(_1380._m0[_29860]);
                float4 _30119 = as_type<float4>(_1380._m0[_29860 + 1]);
                float4 _30125 = as_type<float4>(_1380._m0[_29860 + 2]);
                float3 _30087 = _30113.xyz;
                float _30091 = _30113.w;
                float3 _30094 = _30119.xyz;
                float _30098 = _30119.w;
                float3 _30101 = _30125.xyz;
                float _30105 = _30125.w;
                float3 _30107 = float3(dot(_30087, in.m_3136) + _30091, dot(_30094, in.m_3136) + _30098, dot(_30101, in.m_3136) + _30105);
                float3 _29869 = _30069.xyz;
                float _29871 = _30069.w;
                float _37431;
                do
                {
                    float3 _30137 = _29869 - abs(_30107);
                    float _30145 = fast::min(_30137.x, fast::min(_30137.y, _30137.z));
                    if (_30145 <= 0.0)
                    {
                        _37431 = 0.0;
                        break;
                    }
                    if (_29871 <= 0.0)
                    {
                        _37431 = 1.0;
                        break;
                    }
                    float _30157 = fast::min(_30145 / _29871, 1.0);
                    _37431 = (_30157 * _30157) * (3.0 - (2.0 * _30157));
                    break;
                } while(false);
                if (_37431 <= 0.0)
                {
                    _37697 = _36977;
                    continue;
                }
                float3 _29880 = as_type<float4>(_1380._m0[_29860 + 4]).xyz;
                float4 _30178 = as_type<float4>(_1380._m0[_29860 + 5]);
                int _30184 = int(((device uint*)&_1380._m0[_29860 + 6])[0u]);
                float _30194 = dot(_30087, _35548);
                float _30200 = dot(_30094, _35548);
                float _30206 = dot(_30101, _35548);
                float3 _30207 = float3(_30194, _30200, _30206);
                float3 _29900 = (in.m_3136 + (_35548 * _30178.x)) + (_5898 * _30178.y);
                float3 _29919 = fast::clamp((((float3(dot(_30087, _29900) + _30091, dot(_30094, _29900) + _30098, dot(_30101, _29900) + _30105) + _29869) / fast::max(_29869 * 2.0, float3(9.9999999747524270787835121154785e-07))) * _29880) - float3(0.5), float3(0.0), _29880 - float3(1.0));
                int3 _29921 = int3(_29880);
                int3 _29928 = min(int3(_29919), max((_29921 - int3(2)), int3(0)));
                float3 _29932 = _29919 - float3(_29928);
                float _30287 = 0.48860299587249755859375 * _30200;
                float _30290 = 0.48860299587249755859375 * _30206;
                float _30293 = 0.48860299587249755859375 * _30194;
                float _30298 = 1.09254801273345947265625 * _30194;
                float _30301 = _30298 * _30200;
                float _30307 = (1.09254801273345947265625 * _30200) * _30206;
                float _30315 = 0.3153919875621795654296875 * (((3.0 * _30206) * _30206) - 1.0);
                float _30321 = _30298 * _30206;
                float _30335 = 0.546274006366729736328125 * ((_30194 * _30194) - (_30200 * _30200));
                int3 _30354 = _29921 - int3(1);
                int3 _30355 = min(_29928, _30354);
                int _30360 = _29921.x;
                int _30364 = _29921.y;
                int _30372 = _30184 + ((_30355.x + (_30360 * (_30355.y + (_30364 * _30355.z)))) * 4);
                float3 _30375 = float3(1.0) - _29932;
                float3 _30393 = (((((float3(_30355) + float3(0.5)) / _29880) * _29869) * 2.0) - _29869) - _30107;
                float _30403 = dot(_30393 * rsqrt(fast::max(dot(_30393, _30393), 1.0000000133514319600180897396058e-10)), _30207) + 1.0;
                float _30406 = _30375.x;
                float _30408 = _30375.y;
                float _30409 = _30406 * _30408;
                float _30411 = _30375.z;
                int _30435 = _30372 + 3;
                float _30421 = ((_30409 * _30411) * ((0.25 * (_30403 * _30403)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1380._m0[_30435])[1u])).y > 0.5);
                int _30465 = _30372 + 1;
                int _30469 = _30372 + 2;
                float2 _30481 = float2(as_type<half2>(_1380._m0[_30372].y));
                float2 _30490 = float2(as_type<half2>(_1380._m0[_30465].x));
                float2 _30499 = float2(as_type<half2>(_1380._m0[_30465].w));
                float2 _30508 = float2(as_type<half2>(_1380._m0[_30469].z));
                float3 _30596 = (((((((float3(float2(as_type<half2>(_1380._m0[_30372].x)), _30481.x) * 0.2820949852466583251953125) + (float3(_30481.y, float2(as_type<half2>(_1380._m0[_30372].z))) * _30287)) + (float3(float2(as_type<half2>(_1380._m0[_30372].w)), _30490.x) * _30290)) + (float3(_30490.y, float2(as_type<half2>(_1380._m0[_30465].y))) * _30293)) + (float3(float2(as_type<half2>(_1380._m0[_30465].z)), _30499.x) * _30301)) + (float3(_30499.y, float2(as_type<half2>(_1380._m0[_30469].x))) * _30307)) + (float3(float2(as_type<half2>(_1380._m0[_30469].y)), _30508.x) * _30315)) + (float3(_30508.y, float2(as_type<half2>(_1380._m0[_30469].w))) * _30321);
                int3 _30624 = min((_29928 + int3(1, 0, 0)), _30354);
                int _30641 = _30184 + ((_30624.x + (_30360 * (_30624.y + (_30364 * _30624.z)))) * 4);
                float3 _30662 = (((((float3(_30624) + float3(0.5)) / _29880) * _29869) * 2.0) - _29869) - _30107;
                float _30672 = dot(_30662 * rsqrt(fast::max(dot(_30662, _30662), 1.0000000133514319600180897396058e-10)), _30207) + 1.0;
                float _30678 = _29932.x * _30408;
                int _30704 = _30641 + 3;
                float _30690 = ((_30678 * _30411) * ((0.25 * (_30672 * _30672)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1380._m0[_30704])[1u])).y > 0.5);
                int _30734 = _30641 + 1;
                int _30738 = _30641 + 2;
                float2 _30750 = float2(as_type<half2>(_1380._m0[_30641].y));
                float2 _30759 = float2(as_type<half2>(_1380._m0[_30734].x));
                float2 _30768 = float2(as_type<half2>(_1380._m0[_30734].w));
                float2 _30777 = float2(as_type<half2>(_1380._m0[_30738].z));
                float3 _30865 = (((((((float3(float2(as_type<half2>(_1380._m0[_30641].x)), _30750.x) * 0.2820949852466583251953125) + (float3(_30750.y, float2(as_type<half2>(_1380._m0[_30641].z))) * _30287)) + (float3(float2(as_type<half2>(_1380._m0[_30641].w)), _30759.x) * _30290)) + (float3(_30759.y, float2(as_type<half2>(_1380._m0[_30734].y))) * _30293)) + (float3(float2(as_type<half2>(_1380._m0[_30734].z)), _30768.x) * _30301)) + (float3(_30768.y, float2(as_type<half2>(_1380._m0[_30738].x))) * _30307)) + (float3(float2(as_type<half2>(_1380._m0[_30738].y)), _30777.x) * _30315)) + (float3(_30777.y, float2(as_type<half2>(_1380._m0[_30738].w))) * _30321);
                int3 _30893 = min((_29928 + int3(0, 1, 0)), _30354);
                int _30910 = _30184 + ((_30893.x + (_30360 * (_30893.y + (_30364 * _30893.z)))) * 4);
                float3 _30931 = (((((float3(_30893) + float3(0.5)) / _29880) * _29869) * 2.0) - _29869) - _30107;
                float _30941 = dot(_30931 * rsqrt(fast::max(dot(_30931, _30931), 1.0000000133514319600180897396058e-10)), _30207) + 1.0;
                float _30947 = _30406 * _29932.y;
                int _30973 = _30910 + 3;
                float _30959 = ((_30947 * _30411) * ((0.25 * (_30941 * _30941)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1380._m0[_30973])[1u])).y > 0.5);
                int _31003 = _30910 + 1;
                int _31007 = _30910 + 2;
                float2 _31019 = float2(as_type<half2>(_1380._m0[_30910].y));
                float2 _31028 = float2(as_type<half2>(_1380._m0[_31003].x));
                float2 _31037 = float2(as_type<half2>(_1380._m0[_31003].w));
                float2 _31046 = float2(as_type<half2>(_1380._m0[_31007].z));
                float3 _31134 = (((((((float3(float2(as_type<half2>(_1380._m0[_30910].x)), _31019.x) * 0.2820949852466583251953125) + (float3(_31019.y, float2(as_type<half2>(_1380._m0[_30910].z))) * _30287)) + (float3(float2(as_type<half2>(_1380._m0[_30910].w)), _31028.x) * _30290)) + (float3(_31028.y, float2(as_type<half2>(_1380._m0[_31003].y))) * _30293)) + (float3(float2(as_type<half2>(_1380._m0[_31003].z)), _31037.x) * _30301)) + (float3(_31037.y, float2(as_type<half2>(_1380._m0[_31007].x))) * _30307)) + (float3(float2(as_type<half2>(_1380._m0[_31007].y)), _31046.x) * _30315)) + (float3(_31046.y, float2(as_type<half2>(_1380._m0[_31007].w))) * _30321);
                int3 _31162 = min((_29928 + int3(1, 1, 0)), _30354);
                int _31179 = _30184 + ((_31162.x + (_30360 * (_31162.y + (_30364 * _31162.z)))) * 4);
                float3 _31200 = (((((float3(_31162) + float3(0.5)) / _29880) * _29869) * 2.0) - _29869) - _30107;
                float _31210 = dot(_31200 * rsqrt(fast::max(dot(_31200, _31200), 1.0000000133514319600180897396058e-10)), _30207) + 1.0;
                float _31216 = _29932.x * _29932.y;
                int _31242 = _31179 + 3;
                float _31228 = ((_31216 * _30411) * ((0.25 * (_31210 * _31210)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1380._m0[_31242])[1u])).y > 0.5);
                int _31272 = _31179 + 1;
                int _31276 = _31179 + 2;
                float2 _31288 = float2(as_type<half2>(_1380._m0[_31179].y));
                float2 _31297 = float2(as_type<half2>(_1380._m0[_31272].x));
                float2 _31306 = float2(as_type<half2>(_1380._m0[_31272].w));
                float2 _31315 = float2(as_type<half2>(_1380._m0[_31276].z));
                float3 _31403 = (((((((float3(float2(as_type<half2>(_1380._m0[_31179].x)), _31288.x) * 0.2820949852466583251953125) + (float3(_31288.y, float2(as_type<half2>(_1380._m0[_31179].z))) * _30287)) + (float3(float2(as_type<half2>(_1380._m0[_31179].w)), _31297.x) * _30290)) + (float3(_31297.y, float2(as_type<half2>(_1380._m0[_31272].y))) * _30293)) + (float3(float2(as_type<half2>(_1380._m0[_31272].z)), _31306.x) * _30301)) + (float3(_31306.y, float2(as_type<half2>(_1380._m0[_31276].x))) * _30307)) + (float3(float2(as_type<half2>(_1380._m0[_31276].y)), _31315.x) * _30315)) + (float3(_31315.y, float2(as_type<half2>(_1380._m0[_31276].w))) * _30321);
                int3 _31431 = min((_29928 + int3(0, 0, 1)), _30354);
                int _31448 = _30184 + ((_31431.x + (_30360 * (_31431.y + (_30364 * _31431.z)))) * 4);
                float3 _31469 = (((((float3(_31431) + float3(0.5)) / _29880) * _29869) * 2.0) - _29869) - _30107;
                float _31479 = dot(_31469 * rsqrt(fast::max(dot(_31469, _31469), 1.0000000133514319600180897396058e-10)), _30207) + 1.0;
                int _31511 = _31448 + 3;
                float _31497 = ((_30409 * _29932.z) * ((0.25 * (_31479 * _31479)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1380._m0[_31511])[1u])).y > 0.5);
                int _31541 = _31448 + 1;
                int _31545 = _31448 + 2;
                float2 _31557 = float2(as_type<half2>(_1380._m0[_31448].y));
                float2 _31566 = float2(as_type<half2>(_1380._m0[_31541].x));
                float2 _31575 = float2(as_type<half2>(_1380._m0[_31541].w));
                float2 _31584 = float2(as_type<half2>(_1380._m0[_31545].z));
                float3 _31672 = (((((((float3(float2(as_type<half2>(_1380._m0[_31448].x)), _31557.x) * 0.2820949852466583251953125) + (float3(_31557.y, float2(as_type<half2>(_1380._m0[_31448].z))) * _30287)) + (float3(float2(as_type<half2>(_1380._m0[_31448].w)), _31566.x) * _30290)) + (float3(_31566.y, float2(as_type<half2>(_1380._m0[_31541].y))) * _30293)) + (float3(float2(as_type<half2>(_1380._m0[_31541].z)), _31575.x) * _30301)) + (float3(_31575.y, float2(as_type<half2>(_1380._m0[_31545].x))) * _30307)) + (float3(float2(as_type<half2>(_1380._m0[_31545].y)), _31584.x) * _30315)) + (float3(_31584.y, float2(as_type<half2>(_1380._m0[_31545].w))) * _30321);
                float4 _29999 = (((float4((_30596 + (float3(float2(as_type<half2>(_1380._m0[_30435].x)), float2(as_type<half2>(_1380._m0[_30435].y)).x) * _30335)) * _30421, _30421) + float4((_30865 + (float3(float2(as_type<half2>(_1380._m0[_30704].x)), float2(as_type<half2>(_1380._m0[_30704].y)).x) * _30335)) * _30690, _30690)) + float4((_31134 + (float3(float2(as_type<half2>(_1380._m0[_30973].x)), float2(as_type<half2>(_1380._m0[_30973].y)).x) * _30335)) * _30959, _30959)) + float4((_31403 + (float3(float2(as_type<half2>(_1380._m0[_31242].x)), float2(as_type<half2>(_1380._m0[_31242].y)).x) * _30335)) * _31228, _31228)) + float4((_31672 + (float3(float2(as_type<half2>(_1380._m0[_31511].x)), float2(as_type<half2>(_1380._m0[_31511].y)).x) * _30335)) * _31497, _31497);
                int3 _31700 = min((_29928 + int3(1, 0, 1)), _30354);
                int _31717 = _30184 + ((_31700.x + (_30360 * (_31700.y + (_30364 * _31700.z)))) * 4);
                float3 _31738 = (((((float3(_31700) + float3(0.5)) / _29880) * _29869) * 2.0) - _29869) - _30107;
                float _31748 = dot(_31738 * rsqrt(fast::max(dot(_31738, _31738), 1.0000000133514319600180897396058e-10)), _30207) + 1.0;
                int _31780 = _31717 + 3;
                float _31766 = ((_30678 * _29932.z) * ((0.25 * (_31748 * _31748)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1380._m0[_31780])[1u])).y > 0.5);
                int _31810 = _31717 + 1;
                int _31814 = _31717 + 2;
                float2 _31826 = float2(as_type<half2>(_1380._m0[_31717].y));
                float2 _31835 = float2(as_type<half2>(_1380._m0[_31810].x));
                float2 _31844 = float2(as_type<half2>(_1380._m0[_31810].w));
                float2 _31853 = float2(as_type<half2>(_1380._m0[_31814].z));
                float3 _31941 = (((((((float3(float2(as_type<half2>(_1380._m0[_31717].x)), _31826.x) * 0.2820949852466583251953125) + (float3(_31826.y, float2(as_type<half2>(_1380._m0[_31717].z))) * _30287)) + (float3(float2(as_type<half2>(_1380._m0[_31717].w)), _31835.x) * _30290)) + (float3(_31835.y, float2(as_type<half2>(_1380._m0[_31810].y))) * _30293)) + (float3(float2(as_type<half2>(_1380._m0[_31810].z)), _31844.x) * _30301)) + (float3(_31844.y, float2(as_type<half2>(_1380._m0[_31814].x))) * _30307)) + (float3(float2(as_type<half2>(_1380._m0[_31814].y)), _31853.x) * _30315)) + (float3(_31853.y, float2(as_type<half2>(_1380._m0[_31814].w))) * _30321);
                int3 _31969 = min((_29928 + int3(0, 1, 1)), _30354);
                int _31986 = _30184 + ((_31969.x + (_30360 * (_31969.y + (_30364 * _31969.z)))) * 4);
                float3 _32007 = (((((float3(_31969) + float3(0.5)) / _29880) * _29869) * 2.0) - _29869) - _30107;
                float _32017 = dot(_32007 * rsqrt(fast::max(dot(_32007, _32007), 1.0000000133514319600180897396058e-10)), _30207) + 1.0;
                int _32049 = _31986 + 3;
                float _32035 = ((_30947 * _29932.z) * ((0.25 * (_32017 * _32017)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1380._m0[_32049])[1u])).y > 0.5);
                int _32079 = _31986 + 1;
                int _32083 = _31986 + 2;
                float2 _32095 = float2(as_type<half2>(_1380._m0[_31986].y));
                float2 _32104 = float2(as_type<half2>(_1380._m0[_32079].x));
                float2 _32113 = float2(as_type<half2>(_1380._m0[_32079].w));
                float2 _32122 = float2(as_type<half2>(_1380._m0[_32083].z));
                float3 _32210 = (((((((float3(float2(as_type<half2>(_1380._m0[_31986].x)), _32095.x) * 0.2820949852466583251953125) + (float3(_32095.y, float2(as_type<half2>(_1380._m0[_31986].z))) * _30287)) + (float3(float2(as_type<half2>(_1380._m0[_31986].w)), _32104.x) * _30290)) + (float3(_32104.y, float2(as_type<half2>(_1380._m0[_32079].y))) * _30293)) + (float3(float2(as_type<half2>(_1380._m0[_32079].z)), _32113.x) * _30301)) + (float3(_32113.y, float2(as_type<half2>(_1380._m0[_32083].x))) * _30307)) + (float3(float2(as_type<half2>(_1380._m0[_32083].y)), _32122.x) * _30315)) + (float3(_32122.y, float2(as_type<half2>(_1380._m0[_32083].w))) * _30321);
                int3 _32238 = min((_29928 + int3(1)), _30354);
                int _32255 = _30184 + ((_32238.x + (_30360 * (_32238.y + (_30364 * _32238.z)))) * 4);
                float3 _32276 = (((((float3(_32238) + float3(0.5)) / _29880) * _29869) * 2.0) - _29869) - _30107;
                float _32286 = dot(_32276 * rsqrt(fast::max(dot(_32276, _32276), 1.0000000133514319600180897396058e-10)), _30207) + 1.0;
                int _32318 = _32255 + 3;
                float _32304 = ((_31216 * _29932.z) * ((0.25 * (_32286 * _32286)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1380._m0[_32318])[1u])).y > 0.5);
                int _32348 = _32255 + 1;
                int _32352 = _32255 + 2;
                float2 _32364 = float2(as_type<half2>(_1380._m0[_32255].y));
                float2 _32373 = float2(as_type<half2>(_1380._m0[_32348].x));
                float2 _32382 = float2(as_type<half2>(_1380._m0[_32348].w));
                float2 _32391 = float2(as_type<half2>(_1380._m0[_32352].z));
                float3 _32479 = (((((((float3(float2(as_type<half2>(_1380._m0[_32255].x)), _32364.x) * 0.2820949852466583251953125) + (float3(_32364.y, float2(as_type<half2>(_1380._m0[_32255].z))) * _30287)) + (float3(float2(as_type<half2>(_1380._m0[_32255].w)), _32373.x) * _30290)) + (float3(_32373.y, float2(as_type<half2>(_1380._m0[_32348].y))) * _30293)) + (float3(float2(as_type<half2>(_1380._m0[_32348].z)), _32382.x) * _30301)) + (float3(_32382.y, float2(as_type<half2>(_1380._m0[_32352].x))) * _30307)) + (float3(float2(as_type<half2>(_1380._m0[_32352].y)), _32391.x) * _30315)) + (float3(_32391.y, float2(as_type<half2>(_1380._m0[_32352].w))) * _30321);
                float4 _30038 = ((_29999 + float4((_31941 + (float3(float2(as_type<half2>(_1380._m0[_31780].x)), float2(as_type<half2>(_1380._m0[_31780].y)).x) * _30335)) * _31766, _31766)) + float4((_32210 + (float3(float2(as_type<half2>(_1380._m0[_32049].x)), float2(as_type<half2>(_1380._m0[_32049].y)).x) * _30335)) * _32035, _32035)) + float4((_32479 + (float3(float2(as_type<half2>(_1380._m0[_32318].x)), float2(as_type<half2>(_1380._m0[_32318].y)).x) * _30335)) * _32304, _32304);
                float _30042 = _30038.w;
                float3 _37698;
                if (_30042 > 9.9999997473787516355514526367188e-06)
                {
                    _37698 = mix(_36977, (fast::max(_30038.xyz, float3(0.0)) / float3(_30042)) * _30178.z, float3(_37431));
                }
                else
                {
                    _37698 = _36977;
                }
                _37697 = _37698;
            }
            _36978 = _36977;
        }
        else
        {
            _36978 = _36973;
        }
        _37167 = _36978 * _35576;
    }
    else
    {
        _37167 = mix(mix(_36594, _35543, float3(_2975._m1.y)) + ((_2975._m5.xyz * _6249.xyz) * (float3(1.0) + in.m_5911.yzw)), _382._m7.xyz, float3(_36785));
    }
    float3 _37196;
    if (_382._m33.w > 0.5)
    {
        _37196 = _37167 / (float3(1.0) + _37167);
    }
    else
    {
        _37196 = _37167;
    }
    bool _6392 = _3372._m1.w > 0.5;
    bool _6398;
    if (_6392)
    {
        _6398 = _382._m33.w < 0.5;
    }
    else
    {
        _6398 = _6392;
    }
    float _37197;
    if (_6398)
    {
        _37197 = (-1.0) - fast::max(dot(_37172 * (1.0 - _36785), float3(0.2125999927520751953125, 0.715200006961822509765625, 0.072200000286102294921875)), 0.0);
    }
    else
    {
        _37197 = (in.m_5685.w * _2975._m0.w) * _5683.w;
    }
    out.m_6415 = float4(_37196, _37197);
    float2 _37430;
    do
    {
        if (in.m_6425.w <= 0.0)
        {
            _37430 = float2(0.0);
            break;
        }
        _37430 = ((in.m_6425.xy / float2(in.m_6425.w)) - (in.m_6424.xy / float2(in.m_6424.w))) * float2(0.5, -0.5);
        break;
    } while(false);
    out.m_6423 = _37430;
    return out;
}

