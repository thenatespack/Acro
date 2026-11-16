// Generated from mesh.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 02d208773002676c
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
    float2 _3072;
    fragment_main_out out = {};
    float2 _2124 = float2(dot(_1579._m2.xy, in.m_2110) + _1579._m2.z, dot(_1579._m3.xy, in.m_2110) + _1579._m3.z);
    float4 _2131 = _2126.sample(_1229, _2124);
    float3 _2141 = _2131.xyz;
    float3 _2142 = (in.m_2133.xyz * _1579._m0.xyz) * _2141;
    float3 _7657;
    if (_1579._m1.x > 0.5)
    {
        float2 _2163 = floor(in.m_1741.xz * float2(0.5));
        _7657 = _2142 * ((mod(abs(_2163.x + _2163.y), 2.0) < 0.5) ? 1.0 : 0.75);
    }
    else
    {
        _7657 = _2142;
    }
    float3 _7754;
    float _7785;
    float2 _7818;
    if (_1579._m3.w > 0.5)
    {
        float3 _3175;
        float2 _3182;
        float _7655;
        do
        {
            float3 _3146 = float4(_1579._m2.w, _1579._m3.w, 0.0, 0.0).xyy;
            float3 _3149 = floor(_3146 * float3(1.52587890625e-05));
            float3 _3154 = _3146 - (_3149 * 65536.0);
            float3 _3157 = floor(_3154 * float3(0.00390625));
            float3 _3165 = _3154 - (_3157 * 256.0);
            _3175 = (float3(_3165.x, _3157.x, _3149.x) * float3(0.0039215688593685626983642578125)) * 2.0;
            _3182 = float2(_3165.y, _3157.y) * float2(0.0039215688593685626983642578125);
            float _3185 = _3149.y - 128.0;
            float _3191 = floor(_3185 * 0.03125) * 0.3333333432674407958984375;
            float3 _3197 = fast::normalize(in.m_1649);
            float _3201 = dot(_3197, in.m_1655.xyz);
            float _3213 = (_3201 / fast::max(length(in.m_1655.xyz - (_3197 * _3201)), 9.9999999747524270787835121154785e-07)) * 25.5;
            if (((-24.0) + _3213) < (-2.0))
            {
                _7655 = 0.0;
                break;
            }
            float3 _3221 = in.m_1684 * (4.0 * exp2(mod(_3185, 32.0) * 0.3333333432674407958984375));
            float3 _3265 = floor(_3221);
            float3 _3268 = _3221 - _3265;
            float3 _3276 = (_3268 * _3268) * (float3(3.0) - (_3268 * 2.0));
            uint3 _3343 = uint3(int3(_3265));
            uint _3356 = (((_3343.x * 1597334677u) ^ (_3343.y * 3812015801u)) ^ (_3343.z * 2798796415u)) * 1597334677u;
            uint3 _3371 = uint3(int3(_3265 + float3(1.0, 0.0, 0.0)));
            uint _3384 = (((_3371.x * 1597334677u) ^ (_3371.y * 3812015801u)) ^ (_3371.z * 2798796415u)) * 1597334677u;
            float _3285 = _3276.x;
            uint3 _3399 = uint3(int3(_3265 + float3(0.0, 1.0, 0.0)));
            uint _3412 = (((_3399.x * 1597334677u) ^ (_3399.y * 3812015801u)) ^ (_3399.z * 2798796415u)) * 1597334677u;
            uint3 _3427 = uint3(int3(_3265 + float3(1.0, 1.0, 0.0)));
            uint _3440 = (((_3427.x * 1597334677u) ^ (_3427.y * 3812015801u)) ^ (_3427.z * 2798796415u)) * 1597334677u;
            float _3301 = _3276.y;
            uint3 _3455 = uint3(int3(_3265 + float3(0.0, 0.0, 1.0)));
            uint _3468 = (((_3455.x * 1597334677u) ^ (_3455.y * 3812015801u)) ^ (_3455.z * 2798796415u)) * 1597334677u;
            uint3 _3483 = uint3(int3(_3265 + float3(1.0, 0.0, 1.0)));
            uint _3496 = (((_3483.x * 1597334677u) ^ (_3483.y * 3812015801u)) ^ (_3483.z * 2798796415u)) * 1597334677u;
            uint3 _3511 = uint3(int3(_3265 + float3(0.0, 1.0, 1.0)));
            uint _3524 = (((_3511.x * 1597334677u) ^ (_3511.y * 3812015801u)) ^ (_3511.z * 2798796415u)) * 1597334677u;
            uint3 _3539 = uint3(int3(_3265 + float3(1.0)));
            uint _3552 = (((_3539.x * 1597334677u) ^ (_3539.y * 3812015801u)) ^ (_3539.z * 2798796415u)) * 1597334677u;
            float3 _3227 = (_3221 * 2.7000000476837158203125) + float3(17.299999237060546875, 5.099999904632568359375, 9.69999980926513671875);
            float3 _3578 = floor(_3227);
            float3 _3581 = _3227 - _3578;
            float3 _3589 = (_3581 * _3581) * (float3(3.0) - (_3581 * 2.0));
            uint3 _3656 = uint3(int3(_3578));
            uint _3669 = (((_3656.x * 1597334677u) ^ (_3656.y * 3812015801u)) ^ (_3656.z * 2798796415u)) * 1597334677u;
            uint3 _3684 = uint3(int3(_3578 + float3(1.0, 0.0, 0.0)));
            uint _3697 = (((_3684.x * 1597334677u) ^ (_3684.y * 3812015801u)) ^ (_3684.z * 2798796415u)) * 1597334677u;
            float _3598 = _3589.x;
            uint3 _3712 = uint3(int3(_3578 + float3(0.0, 1.0, 0.0)));
            uint _3725 = (((_3712.x * 1597334677u) ^ (_3712.y * 3812015801u)) ^ (_3712.z * 2798796415u)) * 1597334677u;
            uint3 _3740 = uint3(int3(_3578 + float3(1.0, 1.0, 0.0)));
            uint _3753 = (((_3740.x * 1597334677u) ^ (_3740.y * 3812015801u)) ^ (_3740.z * 2798796415u)) * 1597334677u;
            float _3614 = _3589.y;
            uint3 _3768 = uint3(int3(_3578 + float3(0.0, 0.0, 1.0)));
            uint _3781 = (((_3768.x * 1597334677u) ^ (_3768.y * 3812015801u)) ^ (_3768.z * 2798796415u)) * 1597334677u;
            uint3 _3796 = uint3(int3(_3578 + float3(1.0, 0.0, 1.0)));
            uint _3809 = (((_3796.x * 1597334677u) ^ (_3796.y * 3812015801u)) ^ (_3796.z * 2798796415u)) * 1597334677u;
            uint3 _3824 = uint3(int3(_3578 + float3(0.0, 1.0, 1.0)));
            uint _3837 = (((_3824.x * 1597334677u) ^ (_3824.y * 3812015801u)) ^ (_3824.z * 2798796415u)) * 1597334677u;
            uint3 _3852 = uint3(int3(_3578 + float3(1.0)));
            uint _3865 = (((_3852.x * 1597334677u) ^ (_3852.y * 3812015801u)) ^ (_3852.z * 2798796415u)) * 1597334677u;
            float _3232 = mix(0.449999988079071044921875, 0.0500000007450580596923828125, _3191);
            float _3236 = ((mix(mix(mix(float((_3356 ^ (_3356 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_3384 ^ (_3384 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _3285), mix(float((_3412 ^ (_3412 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_3440 ^ (_3440 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _3285), _3301), mix(mix(float((_3468 ^ (_3468 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_3496 ^ (_3496 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _3285), mix(float((_3524 ^ (_3524 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_3552 ^ (_3552 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _3285), _3301), _3276.z) * 0.64999997615814208984375) + (mix(mix(mix(float((_3669 ^ (_3669 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_3697 ^ (_3697 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _3598), mix(float((_3725 ^ (_3725 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_3753 ^ (_3753 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _3598), _3614), mix(mix(float((_3781 ^ (_3781 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_3809 ^ (_3809 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _3598), mix(float((_3837 ^ (_3837 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_3865 ^ (_3865 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _3598), _3614), _3589.z) * 0.3499999940395355224609375)) - 0.5;
            _7655 = smoothstep(-_3232, _3232, (_3213 + (-24.450000762939453125)) + (_3236 * mix(0.800000011920928955078125, 2.2000000476837158203125, _3191)));
            break;
        } while(false);
        _7818 = _3182;
        _7785 = _7655;
        _7754 = mix(_7657, (in.m_2133.xyz * _3175) * mix(float3(1.0), _2141 * 2.0, float3(0.5)), float3(_7655));
    }
    else
    {
        _7818 = float2(0.0);
        _7785 = 0.0;
        _7754 = _7657;
    }
    float3 _2205 = fast::normalize(in.m_1649);
    float3 _7667;
    if (_1579._m6.y > 0.5)
    {
        float3 _2220 = in.m_1655.xyz - (_2205 * dot(_2205, in.m_1655.xyz));
        float3 _7668;
        if (dot(_2220, _2220) > 9.9999999600419720025001879548654e-13)
        {
            float3 _2229 = fast::normalize(_2220);
            float4 _2245 = _2240.sample(_1229, _2124);
            float3 _7659;
            if (_1579._m6.z > 0.5)
            {
                float2 _7658;
                if (_1579._m6.z > 1.5)
                {
                    _7658 = _2245.xw;
                }
                else
                {
                    _7658 = _2245.xy;
                }
                float2 _2267 = (_7658 * 2.0) - float2(1.0);
                _7659 = float3(_2267, sqrt(fast::clamp(1.0 - dot(_2267, _2267), 0.0, 1.0)));
            }
            else
            {
                _7659 = (_2245.xyz * 2.0) - float3(1.0);
            }
            float2 _2289 = _7659.xy * _1579._m4.z;
            _7668 = fast::normalize(((_2229 * _2289.x) + ((cross(_2205, _2229) * ((in.m_1655.w < 0.0) ? (-1.0) : 1.0)) * _2289.y)) + (_2205 * _7659.z));
        }
        else
        {
            _7668 = _2205;
        }
        _7667 = _7668;
    }
    else
    {
        _7667 = _2205;
    }
    bool _2313 = _1579._m5.w > 0.5;
    float _7664;
    if (_2313)
    {
        _7664 = fast::clamp(_1579._m1.z, 0.0, 1.0);
    }
    else
    {
        _7664 = 0.0;
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
    float3 _7854;
    if (_2331 && (_7664 <= 0.0))
    {
        _7854 = -_7667;
    }
    else
    {
        _7854 = _7667;
    }
    float3 _2343 = fast::normalize(_192._m4.xyz);
    float3 _2349 = _192._m6.xyz - in.m_1741;
    float3 _2350 = fast::normalize(_2349);
    float3 _2355 = fast::normalize(_2343 + _2350);
    float3 _2361 = _2205 * (gl_FrontFacing ? 1.0 : (-1.0));
    bool _2366 = in.m_2363.x > 0.5;
    float3 _7848;
    float _7888;
    if ((_192._m5.w > 0.5) && _2366)
    {
        float _7724;
        float3 _7725;
        do
        {
            int _3894 = int(_192._m21.x);
            float _3902 = dot(_192._m20.xyz, in.m_1741) + _192._m20.w;
            int _7669;
            _7669 = 0;
            for (;;)
            {
                bool _3908 = _7669 < (_3894 - 1);
                bool _3916;
                if (_3908)
                {
                    _3916 = _3902 > _192._m16[_7669];
                }
                else
                {
                    _3916 = _3908;
                }
                if (_3916)
                {
                    _7669++;
                    continue;
                }
                else
                {
                    break;
                }
            }
            if (_3902 > _192._m16[_7669])
            {
                _7725 = float3(1.0);
                _7724 = 1.0;
                break;
            }
            float _7682;
            do
            {
                float4 _4018 = _192._m14[_7669] * float4(in.m_1741 + (_2361 * _192._m18[_7669]), 1.0);
                float _4021 = _4018.x;
                bool _4022 = _4021 < 0.0;
                bool _4029;
                if (!_4022)
                {
                    _4029 = _4021 > 1.0;
                }
                else
                {
                    _4029 = _4022;
                }
                bool _4036;
                if (!_4029)
                {
                    _4036 = _4018.y < 0.0;
                }
                else
                {
                    _4036 = _4029;
                }
                bool _4043;
                if (!_4036)
                {
                    _4043 = _4018.y > 1.0;
                }
                else
                {
                    _4043 = _4036;
                }
                if (_4043)
                {
                    _7682 = 1.0;
                    break;
                }
                float2 _4056 = float2(float(_7669 & 1), float(_7669 >> 1)) * _192._m23.xy;
                float _4063 = fast::min(_4018.z, 1.0) - _192._m19[_7669];
                float2 _4082 = _192._m22.xy * 0.5;
                float2 _4087 = _4056 + (_4018.xy * _192._m23.xy);
                float4 _4100 = float4(_4056 + _4082, (_4056 + _192._m23.xy) - _4082);
                float _7681;
                do
                {
                    int _4126 = int(_192._m22.z);
                    if (_4126 <= 0)
                    {
                        _7681 = spvDepthCast(_212).sample_compare(_212Smplr, float3(fast::clamp(_4087, _4100.xy, _4100.zw), _4063).xy, _4063);
                        break;
                    }
                    float2 _4149 = (_4087 / _192._m22.xy) + float2(0.5);
                    float2 _4150 = floor(_4149);
                    float2 _4155 = _4149 - _4150;
                    float2 _4158 = _4150 - float2(0.5);
                    bool _4162 = _4126 == 1;
                    spvUnsafeArray<float2, 3> _4110;
                    spvUnsafeArray<float2, 3> _4111;
                    if (_4162)
                    {
                        float2 _4165 = _4155 * 2.0;
                        _4110[0] = float2(3.0) - _4165;
                        _4110[1] = float2(1.0) + _4165;
                        _4111[0] = ((float2(2.0) - _4155) / _4110[0]) - float2(1.0);
                        _4111[1] = (_4155 / _4110[1]) + float2(1.0);
                    }
                    else
                    {
                        float2 _4192 = _4155 * 3.0;
                        _4110[0] = float2(4.0) - _4192;
                        _4110[1] = float2(7.0);
                        _4110[2] = float2(1.0) + _4192;
                        _4111[0] = ((float2(3.0) - (_4155 * 2.0)) / _4110[0]) - float2(2.0);
                        _4111[1] = (float2(3.0) + _4155) / _4110[1];
                        _4111[2] = (_4155 / _4110[2]) + float2(2.0);
                    }
                    int _8347 = _4162 ? 2 : 3;
                    int _7671;
                    float _7674;
                    _7674 = 0.0;
                    _7671 = 0;
                    float _7680;
                    for (; _7671 < _8347; _7674 = _7680, _7671++)
                    {
                        _7680 = _7674;
                        for (int _7677 = 0; _7677 < _8347; )
                        {
                            _7680 += ((_4110[_7677].x * _4110[_7671].y) * spvDepthCast(_212).sample_compare(_212Smplr, float3(fast::clamp(_192._m22.xy * (_4158 + float2(_4111[_7677].x, _4111[_7671].y)), _4100.xy, _4100.zw), _4063).xy, _4063));
                            _7677++;
                            continue;
                        }
                    }
                    _7681 = _7674 * (_4162 ? 0.0625 : 0.0069444444961845874786376953125);
                    break;
                } while(false);
                _7682 = _7681;
                break;
            } while(false);
            float3 _7719;
            float _7722;
            if (_3902 > _192._m17[_7669])
            {
                float _3956 = (_3902 - _192._m17[_7669]) / (_192._m16[_7669] - _192._m17[_7669]);
                int _3958 = _7669 + 1;
                float3 _7720;
                float _7723;
                if (_3958 < _3894)
                {
                    float _7702;
                    do
                    {
                        float4 _4305 = _192._m14[_3958] * float4(in.m_1741 + (_2361 * _192._m18[_3958]), 1.0);
                        float _4308 = _4305.x;
                        bool _4309 = _4308 < 0.0;
                        bool _4316;
                        if (!_4309)
                        {
                            _4316 = _4308 > 1.0;
                        }
                        else
                        {
                            _4316 = _4309;
                        }
                        bool _4323;
                        if (!_4316)
                        {
                            _4323 = _4305.y < 0.0;
                        }
                        else
                        {
                            _4323 = _4316;
                        }
                        bool _4330;
                        if (!_4323)
                        {
                            _4330 = _4305.y > 1.0;
                        }
                        else
                        {
                            _4330 = _4323;
                        }
                        if (_4330)
                        {
                            _7702 = 1.0;
                            break;
                        }
                        float2 _4343 = float2(float(_3958 & 1), float(_3958 >> 1)) * _192._m23.xy;
                        float _4350 = fast::min(_4305.z, 1.0) - _192._m19[_3958];
                        float2 _4369 = _192._m22.xy * 0.5;
                        float2 _4374 = _4343 + (_4305.xy * _192._m23.xy);
                        float4 _4387 = float4(_4343 + _4369, (_4343 + _192._m23.xy) - _4369);
                        float _7701;
                        do
                        {
                            int _4413 = int(_192._m22.z);
                            if (_4413 <= 0)
                            {
                                _7701 = spvDepthCast(_212).sample_compare(_212Smplr, float3(fast::clamp(_4374, _4387.xy, _4387.zw), _4350).xy, _4350);
                                break;
                            }
                            float2 _4436 = (_4374 / _192._m22.xy) + float2(0.5);
                            float2 _4437 = floor(_4436);
                            float2 _4442 = _4436 - _4437;
                            float2 _4445 = _4437 - float2(0.5);
                            bool _4449 = _4413 == 1;
                            spvUnsafeArray<float2, 3> _4397;
                            spvUnsafeArray<float2, 3> _4398;
                            if (_4449)
                            {
                                float2 _4452 = _4442 * 2.0;
                                _4397[0] = float2(3.0) - _4452;
                                _4397[1] = float2(1.0) + _4452;
                                _4398[0] = ((float2(2.0) - _4442) / _4397[0]) - float2(1.0);
                                _4398[1] = (_4442 / _4397[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _4479 = _4442 * 3.0;
                                _4397[0] = float2(4.0) - _4479;
                                _4397[1] = float2(7.0);
                                _4397[2] = float2(1.0) + _4479;
                                _4398[0] = ((float2(3.0) - (_4442 * 2.0)) / _4397[0]) - float2(2.0);
                                _4398[1] = (float2(3.0) + _4442) / _4397[1];
                                _4398[2] = (_4442 / _4397[2]) + float2(2.0);
                            }
                            int _8349 = _4449 ? 2 : 3;
                            int _7691;
                            float _7694;
                            _7694 = 0.0;
                            _7691 = 0;
                            float _7700;
                            for (; _7691 < _8349; _7694 = _7700, _7691++)
                            {
                                _7700 = _7694;
                                for (int _7697 = 0; _7697 < _8349; )
                                {
                                    _7700 += ((_4397[_7697].x * _4397[_7691].y) * spvDepthCast(_212).sample_compare(_212Smplr, float3(fast::clamp(_192._m22.xy * (_4445 + float2(_4398[_7697].x, _4398[_7691].y)), _4387.xy, _4387.zw), _4350).xy, _4350));
                                    _7697++;
                                    continue;
                                }
                            }
                            _7701 = _7694 * (_4449 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _7702 = _7701;
                        break;
                    } while(false);
                    _7723 = mix(_7682, _7702, _3956);
                    _7720 = mix(_566[_7669], _566[_3958], float3(_3956));
                }
                else
                {
                    _7723 = mix(_7682, 1.0, _3956);
                    _7720 = _566[_7669];
                }
                _7722 = _7723;
                _7719 = _7720;
            }
            else
            {
                _7722 = _7682;
                _7719 = _566[_7669];
            }
            _7725 = select(float3(1.0), _7719, bool3(_192._m22.w > 0.5));
            _7724 = _7722;
            break;
        } while(false);
        _7888 = _7724;
        _7848 = _7754 * _7725;
    }
    else
    {
        _7888 = 1.0;
        _7848 = _7754;
    }
    float3 _2392 = _192._m5.xyz * _192._m4.w;
    bool _2396 = _1579._m6.w > 0.5;
    float _7777;
    if (_2396)
    {
        _7777 = 1.0;
    }
    else
    {
        _7777 = 1.0 + (_1579._m4.w * (_2057.sample(_1229, _2124).x - 1.0));
    }
    float _2416 = abs(in.m_1655.w);
    float _7978;
    if (_2416 > 0.0)
    {
        _7978 = _7777 * fast::min(_2416, 1.0);
    }
    else
    {
        _7978 = _7777;
    }
    float3 _8136;
    if (!_2313)
    {
        float _2432 = dot(_7854, _2343);
        float3 _8128;
        if (_192._m29.x > 0.5)
        {
            float _4630 = (_192._m29.z * _7854.x) - (_192._m29.w * _7854.z);
            float _4643 = (_192._m29.w * _7854.x) + (_192._m29.z * _7854.z);
            float _4661 = 1.09254801273345947265625 * _4630;
            spvUnsafeArray<float, 9> _7393 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _7854.y, 0.48860299587249755859375 * _4643, 0.48860299587249755859375 * _4630, _4661 * _7854.y, (1.09254801273345947265625 * _7854.y) * _4643, 0.3153919875621795654296875 * (((3.0 * _4643) * _4643) - 1.0), _4661 * _4643, 0.546274006366729736328125 * ((_4630 * _4630) - (_7854.y * _7854.y)) });
            spvUnsafeArray<float, 9> _4575 = _7393;
            float3 _8127;
            _8127 = float3(0.0);
            for (int _8126 = 0; _8126 < 9; )
            {
                _8127 += (_1227.read(uint2((int2(496, 256) + int2(_8126, 0))), 0).xyz * _4575[_8126]);
                _8126++;
                continue;
            }
            _8128 = fast::max(_8127, float3(0.0)) * _192._m29.y;
        }
        else
        {
            _8128 = mix(_192._m9.xyz, _192._m8.xyz, float3((_7854.y * 0.5) + 0.5)) * _192._m8.w;
        }
        float3 _2482 = (_7848 * ((_8128 * _7978) + ((_2392 * fast::max(_2432, 0.0)) * _7888))) + ((_2392 * ((powr(fast::max(dot(_7854, _2355), 0.0), _1579._m1.w) * _1579._m1.z) * step(0.0, _2432))) * _7888);
        float3 _8137;
        if (_192._m13.w > 0.5)
        {
            float2 _4746 = fast::clamp(floor(gl_FragCoord.xy * _192._m12.xy), float2(0.0), _192._m13.xy - float2(1.0));
            uint _4774 = uint((((fast::clamp(floor((log2(fast::max(dot(_192._m11.xyz, in.m_1741) + _192._m11.w, 9.9999999747524270787835121154785e-07)) * _192._m12.z) + _192._m12.w), 0.0, _192._m13.z - 1.0) * _192._m13.y) + _4746.y) * _192._m13.x) + _4746.x);
            uint _4776 = _4774 >> uint(2);
            uint _4778 = _4774 & 3u;
            uint _4782 = _1872._m0[_4776][_4778] & 65535u;
            uint _4784 = _1872._m0[_4776][_4778] >> uint(16);
            float3 _8138;
            _8138 = _2482;
            float3 _2563;
            spvUnsafeArray<float2, 3> _5192;
            spvUnsafeArray<float2, 3> _5193;
            spvUnsafeArray<float2, 3> _5405;
            spvUnsafeArray<float2, 3> _5406;
            for (uint _8135 = _4782; _8135 < (_4782 + _4784); _8138 = _2563, _8135++)
            {
                uint _4790 = _8135 / 3u;
                uint _4803 = (_1893._m0[_4790 >> uint(2)][_4790 & 3u] >> ((_8135 - (_4790 * 3u)) * 10u)) & 1023u;
                float3 _4820 = _1734._m0[_4803].xyz - in.m_1741;
                float _4823 = dot(_4820, _4820);
                float _4827 = _4823 * _1734._m0[_4803].w;
                float _4832 = fast::clamp(1.0 - (_4827 * _4827), 0.0, 1.0);
                float3 _4837 = _4820 * rsqrt(fast::max(_4823, 9.9999999392252902907785028219223e-09));
                float _4855 = fast::clamp((dot(-_4837, _1777._m0[_4803].xyz) * _1769._m0[_4803].w) + _1777._m0[_4803].w, 0.0, 1.0);
                float3 _4868 = _1769._m0[_4803].xyz * ((((_4832 * _4832) * _4855) * _4855) / fast::max(_4823, 9.9999997473787516355514526367188e-05));
                float3 _8264;
                if (_2366)
                {
                    float _8210;
                    do
                    {
                        uint _4904 = uint(_192._m21.z);
                        if (_4803 < _4904)
                        {
                            float _4926 = _192._m26[_4803].z * fast::max((_192._m15[_4803] * float4(in.m_1741, 1.0)).w, 0.0);
                            float4 _4950 = _192._m15[_4803] * float4((in.m_1741 + (_2361 * (_4926 * _192._m25.x))) + (_4837 * (_4926 * _192._m25.y)), 1.0);
                            float _4952 = _4950.w;
                            if (_4952 <= 0.0)
                            {
                                _8210 = 1.0;
                                break;
                            }
                            float3 _4961 = _4950.xyz / float3(_4952);
                            float _4963 = _4961.x;
                            bool _4964 = _4963 < 0.0;
                            bool _4971;
                            if (!_4964)
                            {
                                _4971 = _4963 > 1.0;
                            }
                            else
                            {
                                _4971 = _4964;
                            }
                            bool _4978;
                            if (!_4971)
                            {
                                _4978 = _4961.y < 0.0;
                            }
                            else
                            {
                                _4978 = _4971;
                            }
                            bool _4985;
                            if (!_4978)
                            {
                                _4985 = _4961.y > 1.0;
                            }
                            else
                            {
                                _4985 = _4978;
                            }
                            bool _4992;
                            if (!_4985)
                            {
                                _4992 = _4961.z > 1.0;
                            }
                            else
                            {
                                _4992 = _4985;
                            }
                            if (_4992)
                            {
                                _8210 = 1.0;
                                break;
                            }
                            float _4998 = _4961.z;
                            float2 _5164 = _192._m22.xy * 0.5;
                            float2 _5169 = _192._m26[_4803].xy + (_4961.xy * _192._m23.zw);
                            float4 _5182 = float4(_192._m26[_4803].xy + _5164, (_192._m26[_4803].xy + _192._m23.zw) - _5164);
                            float _8209;
                            do
                            {
                                int _5208 = int(_192._m22.z);
                                if (_5208 <= 0)
                                {
                                    float2 _5218 = fast::clamp(_5169, _5182.xy, _5182.zw);
                                    _8209 = spvDepthCast(_212).sample_compare(_212Smplr, float3(_5218, _4998).xy, _4998);
                                    break;
                                }
                                float2 _5231 = (_5169 / _192._m22.xy) + float2(0.5);
                                float2 _5232 = floor(_5231);
                                float2 _5237 = _5231 - _5232;
                                float2 _5240 = _5232 - float2(0.5);
                                bool _5244 = _5208 == 1;
                                if (_5244)
                                {
                                    float2 _5247 = _5237 * 2.0;
                                    _5192[0] = float2(3.0) - _5247;
                                    _5192[1] = float2(1.0) + _5247;
                                    _5193[0] = ((float2(2.0) - _5237) / _5192[0]) - float2(1.0);
                                    _5193[1] = (_5237 / _5192[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _5274 = _5237 * 3.0;
                                    _5192[0] = float2(4.0) - _5274;
                                    _5192[1] = float2(7.0);
                                    _5192[2] = float2(1.0) + _5274;
                                    _5193[0] = ((float2(3.0) - (_5237 * 2.0)) / _5192[0]) - float2(2.0);
                                    _5193[1] = (float2(3.0) + _5237) / _5192[1];
                                    _5193[2] = (_5237 / _5192[2]) + float2(2.0);
                                }
                                int _8354 = _5244 ? 2 : 3;
                                int _8199;
                                float _8202;
                                _8202 = 0.0;
                                _8199 = 0;
                                float _8208;
                                for (; _8199 < _8354; _8202 = _8208, _8199++)
                                {
                                    _8208 = _8202;
                                    for (int _8205 = 0; _8205 < _8354; )
                                    {
                                        _8208 += ((_5192[_8205].x * _5192[_8199].y) * spvDepthCast(_212).sample_compare(_212Smplr, float3(fast::clamp(_192._m22.xy * (_5240 + float2(_5193[_8205].x, _5193[_8199].y)), _5182.xy, _5182.zw), _4998).xy, _4998));
                                        _8205++;
                                        continue;
                                    }
                                }
                                _8209 = _8202 * (_5244 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _8210 = _8209;
                            break;
                        }
                        uint _5008 = _4803 - _4904;
                        if (_5008 >= uint(_192._m21.w))
                        {
                            _8210 = 1.0;
                            break;
                        }
                        float _5029 = _192._m27[_5008].w * length(in.m_1741 - _192._m27[_5008].xyz);
                        float3 _5047 = ((in.m_1741 + (_2361 * (_5029 * _192._m25.x))) + (_4837 * (_5029 * _192._m25.y))) - _192._m27[_5008].xyz;
                        float3 _5049 = abs(_5047);
                        float _5051 = _5049.x;
                        float _5053 = _5049.y;
                        bool _5054 = _5051 >= _5053;
                        bool _5062;
                        if (_5054)
                        {
                            _5062 = _5051 >= _5049.z;
                        }
                        else
                        {
                            _5062 = _5054;
                        }
                        float _8184;
                        int _8186;
                        if (_5062)
                        {
                            _8186 = (_5047.x > 0.0) ? 0 : 1;
                            _8184 = _5051;
                        }
                        else
                        {
                            float _5074 = _5049.z;
                            bool _5075 = _5053 >= _5074;
                            int _8187;
                            if (_5075)
                            {
                                _8187 = (_5047.y > 0.0) ? 2 : 3;
                            }
                            else
                            {
                                _8187 = (_5047.z > 0.0) ? 4 : 5;
                            }
                            _8186 = _8187;
                            _8184 = _5075 ? _5053 : _5074;
                        }
                        if (_8184 <= 0.0)
                        {
                            _8210 = 1.0;
                            break;
                        }
                        float2 _5112 = float2(dot(_5047, _870[_8186]), dot(_5047, _879[_8186])) / float2(_8184 * _192._m24.z);
                        float _5119 = _192._m28[_5008].z + (_192._m28[_5008].w / _8184);
                        if (_5119 > 1.0)
                        {
                            _8210 = 1.0;
                            break;
                        }
                        float2 _5137 = _192._m28[_5008].xy + (float2(float(spvSMod(_8186, 3)), float(_8186 / 3)) * _192._m24.xy);
                        float2 _5377 = _192._m22.xy * 0.5;
                        float2 _5382 = _5137 + (float2(0.5 + (0.5 * _5112.x), 0.5 - (0.5 * _5112.y)) * _192._m24.xy);
                        float4 _5395 = float4(_5137 + _5377, (_5137 + _192._m24.xy) - _5377);
                        float _8198;
                        do
                        {
                            int _5421 = int(_192._m22.z);
                            if (_5421 <= 0)
                            {
                                _8198 = spvDepthCast(_212).sample_compare(_212Smplr, float3(fast::clamp(_5382, _5395.xy, _5395.zw), _5119).xy, _5119);
                                break;
                            }
                            float2 _5444 = (_5382 / _192._m22.xy) + float2(0.5);
                            float2 _5445 = floor(_5444);
                            float2 _5450 = _5444 - _5445;
                            float2 _5453 = _5445 - float2(0.5);
                            bool _5457 = _5421 == 1;
                            if (_5457)
                            {
                                float2 _5460 = _5450 * 2.0;
                                _5405[0] = float2(3.0) - _5460;
                                _5405[1] = float2(1.0) + _5460;
                                _5406[0] = ((float2(2.0) - _5450) / _5405[0]) - float2(1.0);
                                _5406[1] = (_5450 / _5405[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _5487 = _5450 * 3.0;
                                _5405[0] = float2(4.0) - _5487;
                                _5405[1] = float2(7.0);
                                _5405[2] = float2(1.0) + _5487;
                                _5406[0] = ((float2(3.0) - (_5450 * 2.0)) / _5405[0]) - float2(2.0);
                                _5406[1] = (float2(3.0) + _5450) / _5405[1];
                                _5406[2] = (_5450 / _5405[2]) + float2(2.0);
                            }
                            int _8357 = _5457 ? 2 : 3;
                            int _8188;
                            float _8191;
                            _8191 = 0.0;
                            _8188 = 0;
                            float _8197;
                            for (; _8188 < _8357; _8191 = _8197, _8188++)
                            {
                                _8197 = _8191;
                                for (int _8194 = 0; _8194 < _8357; )
                                {
                                    _8197 += ((_5405[_8194].x * _5405[_8188].y) * spvDepthCast(_212).sample_compare(_212Smplr, float3(fast::clamp(_192._m22.xy * (_5453 + float2(_5406[_8194].x, _5406[_8188].y)), _5395.xy, _5395.zw), _5119).xy, _5119));
                                    _8194++;
                                    continue;
                                }
                            }
                            _8198 = _8191 * (_5457 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _8210 = _8198;
                        break;
                    } while(false);
                    _8264 = _4868 * _8210;
                }
                else
                {
                    _8264 = _4868;
                }
                float _2534 = dot(_7854, _4837);
                _2563 = _8138 + (((_7848 * fast::max(_2534, 0.0)) * _8264) + (_8264 * ((powr(fast::max(dot(_7854, fast::normalize(_4837 + _2350)), 0.0), _1579._m1.w) * _1579._m1.z) * step(0.0, _2534))));
            }
            _8137 = _8138;
        }
        else
        {
            _8137 = _2482;
        }
        _8136 = _8137;
    }
    else
    {
        float4 _2573 = _2568.sample(_1229, _2124);
        float _2580 = fast::clamp(_1579._m4.x * _2573.z, 0.0, 1.0);
        float _2588 = fast::clamp(_1579._m4.y * _2573.y, 0.04500000178813934326171875, 1.0);
        float _7844;
        float _7849;
        if (_7785 > 0.0)
        {
            _7849 = mix(_2580, _7818.y, _7785);
            _7844 = mix(_2588, fast::max(_7818.x, 0.04500000178813934326171875), _7785);
        }
        else
        {
            _7849 = _2580;
            _7844 = _2588;
        }
        float _2607 = _7844 * _7844;
        float3 _2612 = _7848 * (1.0 - _7849);
        float3 _2618 = mix(float3(0.039999999105930328369140625), _7848, float3(_7849));
        bool _2622 = _7664 > 0.0;
        float3 _7877;
        if (_2622)
        {
            float3 _2627 = dfdx(in.m_1741);
            float3 _2629 = dfdy(in.m_1741);
            float3 _2630 = cross(_2627, _2629);
            float3 _7878;
            if (dot(_2630, _2630) > 9.9999996826552253889678874634872e-21)
            {
                _7878 = fast::normalize((fast::normalize(_2630) * ((dot(_2630, _2350) < 0.0) ? (-1.0) : 1.0)) + (_7854 - _2205));
            }
            else
            {
                _7878 = _7854;
            }
            _7877 = _7878;
        }
        else
        {
            _7877 = _7854;
        }
        float _2656 = fast::max(dot(_7877, _2350), 9.9999997473787516355514526367188e-05);
        float _2665 = dot(_7877, _2343);
        float _2666 = fast::clamp(_2665, 0.0, 1.0);
        float _2671 = fast::clamp(dot(_7877, _2355), 0.0, 1.0);
        float _2676 = fast::clamp(dot(_2350, _2355), 0.0, 1.0);
        float _7881;
        float _7882;
        if (_2622)
        {
            _7882 = fast::max(_2656, 0.5);
            _7881 = fast::max(_2676, 0.5);
        }
        else
        {
            _7882 = _2656;
            _7881 = _2676;
        }
        float3 _5589 = float3(1.0) - _2618;
        float3 _5592 = _2618 + (_5589 * powr(1.0 - _7881, 5.0));
        float _5599 = _2607 * _2607;
        float _5604 = _5599 - 1.0;
        float _5606 = ((_2671 * _2671) * _5604) + 1.0;
        float _5626 = 1.0 - _5599;
        float _5630 = sqrt(((_7882 * _7882) * _5626) + _5599);
        float3 _2722 = (((((float3(1.0) - _5592) * _2612) * fast::clamp(dot(_7854, _2343), 0.0, 1.0)) + (((_5592 * ((_5599 / ((3.1415927410125732421875 * _5606) * _5606)) * (0.5 / fast::max((_2666 * _5630) + (_7882 * sqrt(((_2666 * _2666) * _5626) + _5599)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875) * _2666)) * _2392) * _7888;
        float3 _7992;
        if (_2622)
        {
            _7992 = _2722 + (((((_2612 * _2392) * _7888) * _7664) * fast::clamp(-_2665, 0.0, 1.0)) * (0.3499999940395355224609375 + (0.64999997615814208984375 * powr(fast::clamp(dot(-_2350, _2343), 0.0, 1.0), 3.0))));
        }
        else
        {
            _7992 = _2722;
        }
        float3 _7918;
        float2 _7942;
        float3 _7954;
        if (_192._m29.x > 0.5)
        {
            float4 _5663 = _1333.sample(_1335, (((float2(_7882, _7844) * 31.0) + float2(0.5)) * float2(0.03125)));
            float _5722 = (_192._m29.z * _7854.x) - (_192._m29.w * _7854.z);
            float _5735 = (_192._m29.w * _7854.x) + (_192._m29.z * _7854.z);
            float _5753 = 1.09254801273345947265625 * _5722;
            spvUnsafeArray<float, 9> _7374 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _7854.y, 0.48860299587249755859375 * _5735, 0.48860299587249755859375 * _5722, _5753 * _7854.y, (1.09254801273345947265625 * _7854.y) * _5735, 0.3153919875621795654296875 * (((3.0 * _5735) * _5735) - 1.0), _5753 * _5735, 0.546274006366729736328125 * ((_5722 * _5722) - (_7854.y * _7854.y)) });
            spvUnsafeArray<float, 9> _5667 = _7374;
            float3 _7900;
            _7900 = float3(0.0);
            for (int _7899 = 0; _7899 < 9; )
            {
                _7900 += (_1227.read(uint2((int2(496, 256) + int2(_7899, 0))), 0).xyz * _5667[_7899]);
                _7899++;
                continue;
            }
            float3 _2774 = reflect(-_2350, _7877);
            float _5848 = _2774.x;
            float _5853 = _2774.z;
            float2 _5885 = float2((precise::atan2((_192._m29.z * _5848) - (_192._m29.w * _5853), -((_192._m29.w * _5848) + (_192._m29.z * _5853))) * 0.15915493667125701904296875) + 0.5, acos(fast::clamp(_2774.y, -1.0, 1.0)) * 0.3183098733425140380859375);
            float _5817 = _7844 * 5.0;
            int _5820 = min(int(_5817), 4);
            float2 _5906 = (_5885 * float2(_1289[_5820].zw)) - float2(0.5);
            float2 _5908 = floor(_5906);
            float2 _5911 = _5906 - _5908;
            int _5914 = int(_5908.x);
            int _5917 = int(_5908.y);
            int _7903;
            if (_5914 < 0)
            {
                _7903 = _5914 + _1289[_5820].z;
            }
            else
            {
                _7903 = _5914;
            }
            int _7904;
            if (_7903 >= _1289[_5820].z)
            {
                _7904 = _7903 - _1289[_5820].z;
            }
            else
            {
                _7904 = _7903;
            }
            int _5937 = _7904 + 1;
            int _8358 = (_5937 == _1289[_5820].z) ? 0 : _5937;
            int _5952 = min((_5917 + 1), (_1289[_5820].w - 1));
            int _5954 = max(_5917, 0);
            float3 _6007 = float3(_5911.x);
            int _5827 = _5820 + 1;
            float2 _6039 = (_5885 * float2(_1289[_5827].zw)) - float2(0.5);
            float2 _6041 = floor(_6039);
            float2 _6044 = _6039 - _6041;
            int _6047 = int(_6041.x);
            int _6050 = int(_6041.y);
            int _7910;
            if (_6047 < 0)
            {
                _7910 = _6047 + _1289[_5827].z;
            }
            else
            {
                _7910 = _6047;
            }
            int _7911;
            if (_7910 >= _1289[_5827].z)
            {
                _7911 = _7910 - _1289[_5827].z;
            }
            else
            {
                _7911 = _7910;
            }
            int _6070 = _7911 + 1;
            int _8359 = (_6070 == _1289[_5827].z) ? 0 : _6070;
            int _6085 = min((_6050 + 1), (_1289[_5827].w - 1));
            int _6087 = max(_6050, 0);
            float3 _6140 = float3(_6044.x);
            float3 _5842 = mix(mix(mix(_1227.read(uint2((_1289[_5820].xy + int2(_7904, _5954))), 0).xyz, _1227.read(uint2((_1289[_5820].xy + int2(_8358, _5954))), 0).xyz, _6007), mix(_1227.read(uint2((_1289[_5820].xy + int2(_7904, _5952))), 0).xyz, _1227.read(uint2((_1289[_5820].xy + int2(_8358, _5952))), 0).xyz, _6007), float3(_5911.y)), mix(mix(_1227.read(uint2((_1289[_5827].xy + int2(_7911, _6087))), 0).xyz, _1227.read(uint2((_1289[_5827].xy + int2(_8359, _6087))), 0).xyz, _6140), mix(_1227.read(uint2((_1289[_5827].xy + int2(_7911, _6085))), 0).xyz, _1227.read(uint2((_1289[_5827].xy + int2(_8359, _6085))), 0).xyz, _6140), float3(_6044.y)), float3(_5817 - float(_5820))) * _192._m29.y;
            _7954 = fast::max(_7900, float3(0.0)) * _192._m29.y;
            _7942 = _5663.xy;
            _7918 = _5842;
        }
        else
        {
            float4 _6158 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * _7844) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);
            float _6160 = _6158.x;
            float3 _6195 = mix(_192._m9.xyz, _192._m8.xyz, float3((_7854.y * 0.5) + 0.5)) * _192._m8.w;
            _7954 = _6195;
            _7942 = (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_6160 * _6160, exp2((-9.27999973297119140625) * _7882)) * _6160) + _6158.y)) + _6158.zw;
            _7918 = mix(mix(_192._m9.xyz, _192._m8.xyz, float3((reflect(-_2350, _7877).y * 0.5) + 0.5)) * _192._m8.w, _6195, float3(_7844));
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
        float3 _7963;
        if (_2806)
        {
            float3 _7939;
            do
            {
                float _6274 = ((_192._m32.x * (1.0 - smoothstep(_192._m33.x * 0.5, _192._m33.x, abs(dot(_192._m31.xyz, in.m_1741) - _192._m31.w)))) * smoothstep(0.5, 0.89999997615814208984375, dot(_2361, _192._m31.xyz))) * (1.0 - smoothstep(_192._m32.y * 0.5, _192._m32.y, _7844));
                if (_6274 <= 0.0)
                {
                    _7939 = _7918;
                    break;
                }
                float4 _6299 = _192._m30 * float4(in.m_1741 + ((_7854 - (_192._m31.xyz * dot(_7854, _192._m31.xyz))) * _192._m32.w), 1.0);
                float2 _6312 = ((float2(_6299.x, -_6299.y) / float2(_6299.w)) * 0.5) + float2(0.5);
                float _6316 = _192._m32.z * _7844;
                float3 _7937;
                float _7938;
                _7938 = 0.0;
                _7937 = float3(0.0);
                for (int _7936 = 0; _7936 < 12; )
                {
                    float _6323 = float(_7936);
                    float _6331 = _6323 * 2.3999631404876708984375;
                    float2 _6343 = _6312 + (float2(cos(_6331) * _192._m33.y, sin(_6331)) * (sqrt((_6323 + 0.5) * 0.083333335816860198974609375) * _6316));
                    float2 _6348 = fast::min(_6343, float2(1.0) - _6343);
                    float _6354 = smoothstep(0.0, 0.039999999105930328369140625, fast::min(_6348.x, _6348.y));
                    float4 _6362 = _2057.sample(_1229, fast::clamp(_6343, float2(0.0), float2(1.0)), level(0.0));
                    float3 _6364 = _6362.xyz;
                    _7938 += (_6362.w * _6354);
                    _7937 += ((_6364 / (float3(1.0) - fast::min(_6364, float3(0.99500000476837158203125)))) * _6354);
                    _7936++;
                    continue;
                }
                _7939 = mix(_7918, (_7937 * float3(0.083333335816860198974609375)) + (_7918 * (1.0 - (_7938 * 0.083333335816860198974609375))), float3(_6274));
                break;
            } while(false);
            _7963 = _7939;
        }
        else
        {
            _7963 = _7918;
        }
        float3 _2826 = (_2618 * _7942.x) + float3(_7942.y);
        float3 _2842 = _7992 + (((((float3(1.0) - _2826) * _2612) * _7954) + (_2826 * _7963)) * _7978);
        float3 _8139;
        if (_192._m13.w > 0.5)
        {
            float2 _6428 = fast::clamp(floor(gl_FragCoord.xy * _192._m12.xy), float2(0.0), _192._m13.xy - float2(1.0));
            uint _6456 = uint((((fast::clamp(floor((log2(fast::max(dot(_192._m11.xyz, in.m_1741) + _192._m11.w, 9.9999999747524270787835121154785e-07)) * _192._m12.z) + _192._m12.w), 0.0, _192._m13.z - 1.0) * _192._m13.y) + _6428.y) * _192._m13.x) + _6428.x);
            uint _6458 = _6456 >> uint(2);
            uint _6460 = _6456 & 3u;
            uint _6464 = _1872._m0[_6458][_6460] & 65535u;
            uint _6466 = _1872._m0[_6458][_6460] >> uint(16);
            float3 _8092;
            _8092 = _2842;
            float3 _2942;
            spvUnsafeArray<float2, 3> _6874;
            spvUnsafeArray<float2, 3> _6875;
            spvUnsafeArray<float2, 3> _7087;
            spvUnsafeArray<float2, 3> _7088;
            for (uint _7995 = _6464; _7995 < (_6464 + _6466); _8092 = _2942, _7995++)
            {
                uint _6472 = _7995 / 3u;
                uint _6485 = (_1893._m0[_6472 >> uint(2)][_6472 & 3u] >> ((_7995 - (_6472 * 3u)) * 10u)) & 1023u;
                float3 _6502 = _1734._m0[_6485].xyz - in.m_1741;
                float _6505 = dot(_6502, _6502);
                float _6509 = _6505 * _1734._m0[_6485].w;
                float _6514 = fast::clamp(1.0 - (_6509 * _6509), 0.0, 1.0);
                float3 _6519 = _6502 * rsqrt(fast::max(_6505, 9.9999999392252902907785028219223e-09));
                float _6537 = fast::clamp((dot(-_6519, _1777._m0[_6485].xyz) * _1769._m0[_6485].w) + _1777._m0[_6485].w, 0.0, 1.0);
                float3 _6550 = _1769._m0[_6485].xyz * ((((_6514 * _6514) * _6537) * _6537) / fast::max(_6505, 9.9999997473787516355514526367188e-05));
                float3 _8090;
                if (_2366)
                {
                    float _8022;
                    do
                    {
                        uint _6586 = uint(_192._m21.z);
                        if (_6485 < _6586)
                        {
                            float _6608 = _192._m26[_6485].z * fast::max((_192._m15[_6485] * float4(in.m_1741, 1.0)).w, 0.0);
                            float4 _6632 = _192._m15[_6485] * float4((in.m_1741 + (_2361 * (_6608 * _192._m25.x))) + (_6519 * (_6608 * _192._m25.y)), 1.0);
                            float _6634 = _6632.w;
                            if (_6634 <= 0.0)
                            {
                                _8022 = 1.0;
                                break;
                            }
                            float3 _6643 = _6632.xyz / float3(_6634);
                            float _6645 = _6643.x;
                            bool _6646 = _6645 < 0.0;
                            bool _6653;
                            if (!_6646)
                            {
                                _6653 = _6645 > 1.0;
                            }
                            else
                            {
                                _6653 = _6646;
                            }
                            bool _6660;
                            if (!_6653)
                            {
                                _6660 = _6643.y < 0.0;
                            }
                            else
                            {
                                _6660 = _6653;
                            }
                            bool _6667;
                            if (!_6660)
                            {
                                _6667 = _6643.y > 1.0;
                            }
                            else
                            {
                                _6667 = _6660;
                            }
                            bool _6674;
                            if (!_6667)
                            {
                                _6674 = _6643.z > 1.0;
                            }
                            else
                            {
                                _6674 = _6667;
                            }
                            if (_6674)
                            {
                                _8022 = 1.0;
                                break;
                            }
                            float _6680 = _6643.z;
                            float2 _6846 = _192._m22.xy * 0.5;
                            float2 _6851 = _192._m26[_6485].xy + (_6643.xy * _192._m23.zw);
                            float4 _6864 = float4(_192._m26[_6485].xy + _6846, (_192._m26[_6485].xy + _192._m23.zw) - _6846);
                            float _8021;
                            do
                            {
                                int _6890 = int(_192._m22.z);
                                if (_6890 <= 0)
                                {
                                    float2 _6900 = fast::clamp(_6851, _6864.xy, _6864.zw);
                                    _8021 = spvDepthCast(_212).sample_compare(_212Smplr, float3(_6900, _6680).xy, _6680);
                                    break;
                                }
                                float2 _6913 = (_6851 / _192._m22.xy) + float2(0.5);
                                float2 _6914 = floor(_6913);
                                float2 _6919 = _6913 - _6914;
                                float2 _6922 = _6914 - float2(0.5);
                                bool _6926 = _6890 == 1;
                                if (_6926)
                                {
                                    float2 _6929 = _6919 * 2.0;
                                    _6874[0] = float2(3.0) - _6929;
                                    _6874[1] = float2(1.0) + _6929;
                                    _6875[0] = ((float2(2.0) - _6919) / _6874[0]) - float2(1.0);
                                    _6875[1] = (_6919 / _6874[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _6956 = _6919 * 3.0;
                                    _6874[0] = float2(4.0) - _6956;
                                    _6874[1] = float2(7.0);
                                    _6874[2] = float2(1.0) + _6956;
                                    _6875[0] = ((float2(3.0) - (_6919 * 2.0)) / _6874[0]) - float2(2.0);
                                    _6875[1] = (float2(3.0) + _6919) / _6874[1];
                                    _6875[2] = (_6919 / _6874[2]) + float2(2.0);
                                }
                                int _8361 = _6926 ? 2 : 3;
                                int _8011;
                                float _8014;
                                _8014 = 0.0;
                                _8011 = 0;
                                float _8020;
                                for (; _8011 < _8361; _8014 = _8020, _8011++)
                                {
                                    _8020 = _8014;
                                    for (int _8017 = 0; _8017 < _8361; )
                                    {
                                        _8020 += ((_6874[_8017].x * _6874[_8011].y) * spvDepthCast(_212).sample_compare(_212Smplr, float3(fast::clamp(_192._m22.xy * (_6922 + float2(_6875[_8017].x, _6875[_8011].y)), _6864.xy, _6864.zw), _6680).xy, _6680));
                                        _8017++;
                                        continue;
                                    }
                                }
                                _8021 = _8014 * (_6926 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _8022 = _8021;
                            break;
                        }
                        uint _6690 = _6485 - _6586;
                        if (_6690 >= uint(_192._m21.w))
                        {
                            _8022 = 1.0;
                            break;
                        }
                        float _6711 = _192._m27[_6690].w * length(in.m_1741 - _192._m27[_6690].xyz);
                        float3 _6729 = ((in.m_1741 + (_2361 * (_6711 * _192._m25.x))) + (_6519 * (_6711 * _192._m25.y))) - _192._m27[_6690].xyz;
                        float3 _6731 = abs(_6729);
                        float _6733 = _6731.x;
                        float _6735 = _6731.y;
                        bool _6736 = _6733 >= _6735;
                        bool _6744;
                        if (_6736)
                        {
                            _6744 = _6733 >= _6731.z;
                        }
                        else
                        {
                            _6744 = _6736;
                        }
                        float _7996;
                        int _7998;
                        if (_6744)
                        {
                            _7998 = (_6729.x > 0.0) ? 0 : 1;
                            _7996 = _6733;
                        }
                        else
                        {
                            float _6756 = _6731.z;
                            bool _6757 = _6735 >= _6756;
                            int _7999;
                            if (_6757)
                            {
                                _7999 = (_6729.y > 0.0) ? 2 : 3;
                            }
                            else
                            {
                                _7999 = (_6729.z > 0.0) ? 4 : 5;
                            }
                            _7998 = _7999;
                            _7996 = _6757 ? _6735 : _6756;
                        }
                        if (_7996 <= 0.0)
                        {
                            _8022 = 1.0;
                            break;
                        }
                        float2 _6794 = float2(dot(_6729, _870[_7998]), dot(_6729, _879[_7998])) / float2(_7996 * _192._m24.z);
                        float _6801 = _192._m28[_6690].z + (_192._m28[_6690].w / _7996);
                        if (_6801 > 1.0)
                        {
                            _8022 = 1.0;
                            break;
                        }
                        float2 _6819 = _192._m28[_6690].xy + (float2(float(spvSMod(_7998, 3)), float(_7998 / 3)) * _192._m24.xy);
                        float2 _7059 = _192._m22.xy * 0.5;
                        float2 _7064 = _6819 + (float2(0.5 + (0.5 * _6794.x), 0.5 - (0.5 * _6794.y)) * _192._m24.xy);
                        float4 _7077 = float4(_6819 + _7059, (_6819 + _192._m24.xy) - _7059);
                        float _8010;
                        do
                        {
                            int _7103 = int(_192._m22.z);
                            if (_7103 <= 0)
                            {
                                _8010 = spvDepthCast(_212).sample_compare(_212Smplr, float3(fast::clamp(_7064, _7077.xy, _7077.zw), _6801).xy, _6801);
                                break;
                            }
                            float2 _7126 = (_7064 / _192._m22.xy) + float2(0.5);
                            float2 _7127 = floor(_7126);
                            float2 _7132 = _7126 - _7127;
                            float2 _7135 = _7127 - float2(0.5);
                            bool _7139 = _7103 == 1;
                            if (_7139)
                            {
                                float2 _7142 = _7132 * 2.0;
                                _7087[0] = float2(3.0) - _7142;
                                _7087[1] = float2(1.0) + _7142;
                                _7088[0] = ((float2(2.0) - _7132) / _7087[0]) - float2(1.0);
                                _7088[1] = (_7132 / _7087[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _7169 = _7132 * 3.0;
                                _7087[0] = float2(4.0) - _7169;
                                _7087[1] = float2(7.0);
                                _7087[2] = float2(1.0) + _7169;
                                _7088[0] = ((float2(3.0) - (_7132 * 2.0)) / _7087[0]) - float2(2.0);
                                _7088[1] = (float2(3.0) + _7132) / _7087[1];
                                _7088[2] = (_7132 / _7087[2]) + float2(2.0);
                            }
                            int _8364 = _7139 ? 2 : 3;
                            int _8000;
                            float _8003;
                            _8003 = 0.0;
                            _8000 = 0;
                            float _8009;
                            for (; _8000 < _8364; _8003 = _8009, _8000++)
                            {
                                _8009 = _8003;
                                for (int _8006 = 0; _8006 < _8364; )
                                {
                                    _8009 += ((_7087[_8006].x * _7087[_8000].y) * spvDepthCast(_212).sample_compare(_212Smplr, float3(fast::clamp(_192._m22.xy * (_7135 + float2(_7088[_8006].x, _7088[_8000].y)), _7077.xy, _7077.zw), _6801).xy, _6801));
                                    _8006++;
                                    continue;
                                }
                            }
                            _8010 = _8003 * (_7139 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _8022 = _8010;
                        break;
                    } while(false);
                    _8090 = _6550 * _8022;
                }
                else
                {
                    _8090 = _6550;
                }
                float3 _2894 = fast::normalize(_6519 + _2350);
                float _2899 = fast::clamp(dot(_7854, _6519), 0.0, 1.0);
                float _2904 = fast::clamp(dot(_7854, _2894), 0.0, 1.0);
                float3 _7274 = _2618 + (_5589 * powr(1.0 - fast::clamp(dot(_2350, _2894), 0.0, 1.0), 5.0));
                float _7288 = ((_2904 * _2904) * _5604) + 1.0;
                _2942 = _8092 + (((((float3(1.0) - _7274) * _2612) + ((_7274 * ((_5599 / ((3.1415927410125732421875 * _7288) * _7288)) * (0.5 / fast::max((_2899 * _5630) + (_7882 * sqrt(((_2899 * _2899) * _5626) + _5599)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875)) * _2899) * _8090);
            }
            _8139 = _8092;
        }
        else
        {
            _8139 = _2842;
        }
        _8136 = _8139;
    }
    float4 _2959 = _2954.sample(_1229, _2124);
    float _2977 = -length(_2349);
    float _8181;
    if (_192._m9.w != 0.0)
    {
        float _3001 = _192._m9.w * (in.m_1741 - _192._m6.xyz).y;
        float _8178;
        if (abs(_3001) < 9.9999997473787516355514526367188e-05)
        {
            _8178 = 1.0 - (0.5 * _3001);
        }
        else
        {
            _8178 = (1.0 - exp(fast::min(-_3001, 60.0))) / _3001;
        }
        _8181 = 1.0 - exp((_2977 * (_192._m7.w * exp(fast::min((-_192._m9.w) * (_192._m6.y - _192._m6.w), 30.0)))) * _8178);
    }
    else
    {
        _8181 = 1.0 - exp(_2977 * _192._m7.w);
    }
    float3 _3052 = mix(mix(_8136, _7848, float3(_1579._m1.y)) + ((_1579._m5.xyz * _2959.xyz) * (float3(1.0) + in.m_2363.yzw)), _192._m7.xyz, float3(_8181));
    float3 _8182;
    if (_192._m33.w > 0.5)
    {
        _8182 = _3052 / (float3(1.0) + _3052);
    }
    else
    {
        _8182 = _3052;
    }
    out.m_3064 = float4(_8182, (in.m_2133.w * _1579._m0.w) * _2131.w);
    float2 _8183;
    do
    {
        if (in.m_3074.w <= 0.0)
        {
            _8183 = float2(0.0);
            break;
        }
        _8183 = ((in.m_3074.xy / float2(in.m_3074.w)) - (in.m_3073.xy / float2(in.m_3073.w))) * float2(0.5, -0.5);
        break;
    } while(false);
    _3072 = _8183;
    return out;
}

