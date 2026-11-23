// Generated from mesh_mask.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 5fd77116879aa74d
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
    float3 _7688;
    if (_1579._m1.x > 0.5)
    {
        float2 _2176 = floor(in.m_1741.xz * float2(0.5));
        _7688 = _2142 * ((mod(abs(_2176.x + _2176.y), 2.0) < 0.5) ? 1.0 : 0.75);
    }
    else
    {
        _7688 = _2142;
    }
    float3 _7785;
    float _7816;
    float2 _7849;
    if (_1579._m3.w > 0.5)
    {
        float3 _3205;
        float2 _3212;
        float _7686;
        do
        {
            float3 _3176 = float4(_1579._m2.w, _1579._m3.w, 0.0, 0.0).xyy;
            float3 _3179 = floor(_3176 * float3(1.52587890625e-05));
            float3 _3184 = _3176 - (_3179 * 65536.0);
            float3 _3187 = floor(_3184 * float3(0.00390625));
            float3 _3195 = _3184 - (_3187 * 256.0);
            _3205 = (float3(_3195.x, _3187.x, _3179.x) * float3(0.0039215688593685626983642578125)) * 2.0;
            _3212 = float2(_3195.y, _3187.y) * float2(0.0039215688593685626983642578125);
            float _3215 = _3179.y - 128.0;
            float _3221 = floor(_3215 * 0.03125) * 0.3333333432674407958984375;
            float3 _3227 = fast::normalize(in.m_1649);
            float _3231 = dot(_3227, in.m_1655.xyz);
            float _3243 = (_3231 / fast::max(length(in.m_1655.xyz - (_3227 * _3231)), 9.9999999747524270787835121154785e-07)) * 25.5;
            if (((-24.0) + _3243) < (-2.0))
            {
                _7686 = 0.0;
                break;
            }
            float3 _3251 = in.m_1684 * (4.0 * exp2(mod(_3215, 32.0) * 0.3333333432674407958984375));
            float3 _3295 = floor(_3251);
            float3 _3298 = _3251 - _3295;
            float3 _3306 = (_3298 * _3298) * (float3(3.0) - (_3298 * 2.0));
            uint3 _3373 = uint3(int3(_3295));
            uint _3386 = (((_3373.x * 1597334677u) ^ (_3373.y * 3812015801u)) ^ (_3373.z * 2798796415u)) * 1597334677u;
            uint3 _3401 = uint3(int3(_3295 + float3(1.0, 0.0, 0.0)));
            uint _3414 = (((_3401.x * 1597334677u) ^ (_3401.y * 3812015801u)) ^ (_3401.z * 2798796415u)) * 1597334677u;
            float _3315 = _3306.x;
            uint3 _3429 = uint3(int3(_3295 + float3(0.0, 1.0, 0.0)));
            uint _3442 = (((_3429.x * 1597334677u) ^ (_3429.y * 3812015801u)) ^ (_3429.z * 2798796415u)) * 1597334677u;
            uint3 _3457 = uint3(int3(_3295 + float3(1.0, 1.0, 0.0)));
            uint _3470 = (((_3457.x * 1597334677u) ^ (_3457.y * 3812015801u)) ^ (_3457.z * 2798796415u)) * 1597334677u;
            float _3331 = _3306.y;
            uint3 _3485 = uint3(int3(_3295 + float3(0.0, 0.0, 1.0)));
            uint _3498 = (((_3485.x * 1597334677u) ^ (_3485.y * 3812015801u)) ^ (_3485.z * 2798796415u)) * 1597334677u;
            uint3 _3513 = uint3(int3(_3295 + float3(1.0, 0.0, 1.0)));
            uint _3526 = (((_3513.x * 1597334677u) ^ (_3513.y * 3812015801u)) ^ (_3513.z * 2798796415u)) * 1597334677u;
            uint3 _3541 = uint3(int3(_3295 + float3(0.0, 1.0, 1.0)));
            uint _3554 = (((_3541.x * 1597334677u) ^ (_3541.y * 3812015801u)) ^ (_3541.z * 2798796415u)) * 1597334677u;
            uint3 _3569 = uint3(int3(_3295 + float3(1.0)));
            uint _3582 = (((_3569.x * 1597334677u) ^ (_3569.y * 3812015801u)) ^ (_3569.z * 2798796415u)) * 1597334677u;
            float3 _3257 = (_3251 * 2.7000000476837158203125) + float3(17.299999237060546875, 5.099999904632568359375, 9.69999980926513671875);
            float3 _3608 = floor(_3257);
            float3 _3611 = _3257 - _3608;
            float3 _3619 = (_3611 * _3611) * (float3(3.0) - (_3611 * 2.0));
            uint3 _3686 = uint3(int3(_3608));
            uint _3699 = (((_3686.x * 1597334677u) ^ (_3686.y * 3812015801u)) ^ (_3686.z * 2798796415u)) * 1597334677u;
            uint3 _3714 = uint3(int3(_3608 + float3(1.0, 0.0, 0.0)));
            uint _3727 = (((_3714.x * 1597334677u) ^ (_3714.y * 3812015801u)) ^ (_3714.z * 2798796415u)) * 1597334677u;
            float _3628 = _3619.x;
            uint3 _3742 = uint3(int3(_3608 + float3(0.0, 1.0, 0.0)));
            uint _3755 = (((_3742.x * 1597334677u) ^ (_3742.y * 3812015801u)) ^ (_3742.z * 2798796415u)) * 1597334677u;
            uint3 _3770 = uint3(int3(_3608 + float3(1.0, 1.0, 0.0)));
            uint _3783 = (((_3770.x * 1597334677u) ^ (_3770.y * 3812015801u)) ^ (_3770.z * 2798796415u)) * 1597334677u;
            float _3644 = _3619.y;
            uint3 _3798 = uint3(int3(_3608 + float3(0.0, 0.0, 1.0)));
            uint _3811 = (((_3798.x * 1597334677u) ^ (_3798.y * 3812015801u)) ^ (_3798.z * 2798796415u)) * 1597334677u;
            uint3 _3826 = uint3(int3(_3608 + float3(1.0, 0.0, 1.0)));
            uint _3839 = (((_3826.x * 1597334677u) ^ (_3826.y * 3812015801u)) ^ (_3826.z * 2798796415u)) * 1597334677u;
            uint3 _3854 = uint3(int3(_3608 + float3(0.0, 1.0, 1.0)));
            uint _3867 = (((_3854.x * 1597334677u) ^ (_3854.y * 3812015801u)) ^ (_3854.z * 2798796415u)) * 1597334677u;
            uint3 _3882 = uint3(int3(_3608 + float3(1.0)));
            uint _3895 = (((_3882.x * 1597334677u) ^ (_3882.y * 3812015801u)) ^ (_3882.z * 2798796415u)) * 1597334677u;
            float _3262 = mix(0.449999988079071044921875, 0.0500000007450580596923828125, _3221);
            float _3266 = ((mix(mix(mix(float((_3386 ^ (_3386 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_3414 ^ (_3414 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _3315), mix(float((_3442 ^ (_3442 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_3470 ^ (_3470 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _3315), _3331), mix(mix(float((_3498 ^ (_3498 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_3526 ^ (_3526 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _3315), mix(float((_3554 ^ (_3554 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_3582 ^ (_3582 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _3315), _3331), _3306.z) * 0.64999997615814208984375) + (mix(mix(mix(float((_3699 ^ (_3699 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_3727 ^ (_3727 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _3628), mix(float((_3755 ^ (_3755 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_3783 ^ (_3783 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _3628), _3644), mix(mix(float((_3811 ^ (_3811 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_3839 ^ (_3839 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _3628), mix(float((_3867 ^ (_3867 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_3895 ^ (_3895 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _3628), _3644), _3619.z) * 0.3499999940395355224609375)) - 0.5;
            _7686 = smoothstep(-_3262, _3262, (_3243 + (-24.450000762939453125)) + (_3266 * mix(0.800000011920928955078125, 2.2000000476837158203125, _3221)));
            break;
        } while(false);
        _7849 = _3212;
        _7816 = _7686;
        _7785 = mix(_7688, (in.m_2133.xyz * _3205) * mix(float3(1.0), _2141 * 2.0, float3(0.5)), float3(_7686));
    }
    else
    {
        _7849 = float2(0.0);
        _7816 = 0.0;
        _7785 = _7688;
    }
    float3 _2218 = fast::normalize(in.m_1649);
    float3 _7698;
    if (_1579._m6.y > 0.5)
    {
        float3 _2233 = in.m_1655.xyz - (_2218 * dot(_2218, in.m_1655.xyz));
        float3 _7699;
        if (dot(_2233, _2233) > 9.9999999600419720025001879548654e-13)
        {
            float3 _2242 = fast::normalize(_2233);
            float4 _2258 = _2253.sample(_1229, _2124);
            float3 _7690;
            if (_1579._m6.z > 0.5)
            {
                float2 _7689;
                if (_1579._m6.z > 1.5)
                {
                    _7689 = _2258.xw;
                }
                else
                {
                    _7689 = _2258.xy;
                }
                float2 _2280 = (_7689 * 2.0) - float2(1.0);
                _7690 = float3(_2280, sqrt(fast::clamp(1.0 - dot(_2280, _2280), 0.0, 1.0)));
            }
            else
            {
                _7690 = (_2258.xyz * 2.0) - float3(1.0);
            }
            float2 _2302 = _7690.xy * _1579._m4.z;
            _7699 = fast::normalize(((_2242 * _2302.x) + ((cross(_2218, _2242) * ((in.m_1655.w < 0.0) ? (-1.0) : 1.0)) * _2302.y)) + (_2218 * _7690.z));
        }
        else
        {
            _7699 = _2218;
        }
        _7698 = _7699;
    }
    else
    {
        _7698 = _2218;
    }
    bool _2326 = _1579._m5.w > 0.5;
    float _7695;
    if (_2326)
    {
        _7695 = fast::clamp(_1579._m1.z, 0.0, 1.0);
    }
    else
    {
        _7695 = 0.0;
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
    float3 _7885;
    if (_2344 && (_7695 <= 0.0))
    {
        _7885 = -_7698;
    }
    else
    {
        _7885 = _7698;
    }
    float3 _2356 = fast::normalize(_192._m4.xyz);
    float3 _2362 = _192._m6.xyz - in.m_1741;
    float3 _2363 = fast::normalize(_2362);
    float3 _2368 = fast::normalize(_2356 + _2363);
    float3 _2374 = _2218 * (gl_FrontFacing ? 1.0 : (-1.0));
    bool _2379 = in.m_2376.x > 0.5;
    float3 _7879;
    float _7919;
    if ((_192._m5.w > 0.5) && _2379)
    {
        float _7755;
        float3 _7756;
        do
        {
            int _3924 = int(_192._m21.x);
            float _3932 = dot(_192._m20.xyz, in.m_1741) + _192._m20.w;
            int _7700;
            _7700 = 0;
            for (;;)
            {
                bool _3938 = _7700 < (_3924 - 1);
                bool _3946;
                if (_3938)
                {
                    _3946 = _3932 > _192._m16[_7700];
                }
                else
                {
                    _3946 = _3938;
                }
                if (_3946)
                {
                    _7700++;
                    continue;
                }
                else
                {
                    break;
                }
            }
            if (_3932 > _192._m16[_7700])
            {
                _7756 = float3(1.0);
                _7755 = 1.0;
                break;
            }
            float _7713;
            do
            {
                float4 _4048 = _192._m14[_7700] * float4(in.m_1741 + (_2374 * _192._m18[_7700]), 1.0);
                float _4051 = _4048.x;
                bool _4052 = _4051 < 0.0;
                bool _4059;
                if (!_4052)
                {
                    _4059 = _4051 > 1.0;
                }
                else
                {
                    _4059 = _4052;
                }
                bool _4066;
                if (!_4059)
                {
                    _4066 = _4048.y < 0.0;
                }
                else
                {
                    _4066 = _4059;
                }
                bool _4073;
                if (!_4066)
                {
                    _4073 = _4048.y > 1.0;
                }
                else
                {
                    _4073 = _4066;
                }
                if (_4073)
                {
                    _7713 = 1.0;
                    break;
                }
                float2 _4086 = float2(float(_7700 & 1), float(_7700 >> 1)) * _192._m23.xy;
                float _4093 = fast::min(_4048.z, 1.0) - _192._m19[_7700];
                float2 _4112 = _192._m22.xy * 0.5;
                float2 _4117 = _4086 + (_4048.xy * _192._m23.xy);
                float4 _4130 = float4(_4086 + _4112, (_4086 + _192._m23.xy) - _4112);
                float _7712;
                do
                {
                    int _4156 = int(_192._m22.z);
                    if (_4156 <= 0)
                    {
                        _7712 = spvDepthCast(_212).sample_compare(_212Smplr, float3(fast::clamp(_4117, _4130.xy, _4130.zw), _4093).xy, _4093);
                        break;
                    }
                    float2 _4179 = (_4117 / _192._m22.xy) + float2(0.5);
                    float2 _4180 = floor(_4179);
                    float2 _4185 = _4179 - _4180;
                    float2 _4188 = _4180 - float2(0.5);
                    bool _4192 = _4156 == 1;
                    spvUnsafeArray<float2, 3> _4140;
                    spvUnsafeArray<float2, 3> _4141;
                    if (_4192)
                    {
                        float2 _4195 = _4185 * 2.0;
                        _4140[0] = float2(3.0) - _4195;
                        _4140[1] = float2(1.0) + _4195;
                        _4141[0] = ((float2(2.0) - _4185) / _4140[0]) - float2(1.0);
                        _4141[1] = (_4185 / _4140[1]) + float2(1.0);
                    }
                    else
                    {
                        float2 _4222 = _4185 * 3.0;
                        _4140[0] = float2(4.0) - _4222;
                        _4140[1] = float2(7.0);
                        _4140[2] = float2(1.0) + _4222;
                        _4141[0] = ((float2(3.0) - (_4185 * 2.0)) / _4140[0]) - float2(2.0);
                        _4141[1] = (float2(3.0) + _4185) / _4140[1];
                        _4141[2] = (_4185 / _4140[2]) + float2(2.0);
                    }
                    int _8474 = _4192 ? 2 : 3;
                    int _7702;
                    float _7705;
                    _7705 = 0.0;
                    _7702 = 0;
                    float _7711;
                    for (; _7702 < _8474; _7705 = _7711, _7702++)
                    {
                        _7711 = _7705;
                        for (int _7708 = 0; _7708 < _8474; )
                        {
                            _7711 += ((_4140[_7708].x * _4140[_7702].y) * spvDepthCast(_212).sample_compare(_212Smplr, float3(fast::clamp(_192._m22.xy * (_4188 + float2(_4141[_7708].x, _4141[_7702].y)), _4130.xy, _4130.zw), _4093).xy, _4093));
                            _7708++;
                            continue;
                        }
                    }
                    _7712 = _7705 * (_4192 ? 0.0625 : 0.0069444444961845874786376953125);
                    break;
                } while(false);
                _7713 = _7712;
                break;
            } while(false);
            float3 _7750;
            float _7753;
            if (_3932 > _192._m17[_7700])
            {
                float _3986 = (_3932 - _192._m17[_7700]) / (_192._m16[_7700] - _192._m17[_7700]);
                int _3988 = _7700 + 1;
                float3 _7751;
                float _7754;
                if (_3988 < _3924)
                {
                    float _7733;
                    do
                    {
                        float4 _4335 = _192._m14[_3988] * float4(in.m_1741 + (_2374 * _192._m18[_3988]), 1.0);
                        float _4338 = _4335.x;
                        bool _4339 = _4338 < 0.0;
                        bool _4346;
                        if (!_4339)
                        {
                            _4346 = _4338 > 1.0;
                        }
                        else
                        {
                            _4346 = _4339;
                        }
                        bool _4353;
                        if (!_4346)
                        {
                            _4353 = _4335.y < 0.0;
                        }
                        else
                        {
                            _4353 = _4346;
                        }
                        bool _4360;
                        if (!_4353)
                        {
                            _4360 = _4335.y > 1.0;
                        }
                        else
                        {
                            _4360 = _4353;
                        }
                        if (_4360)
                        {
                            _7733 = 1.0;
                            break;
                        }
                        float2 _4373 = float2(float(_3988 & 1), float(_3988 >> 1)) * _192._m23.xy;
                        float _4380 = fast::min(_4335.z, 1.0) - _192._m19[_3988];
                        float2 _4399 = _192._m22.xy * 0.5;
                        float2 _4404 = _4373 + (_4335.xy * _192._m23.xy);
                        float4 _4417 = float4(_4373 + _4399, (_4373 + _192._m23.xy) - _4399);
                        float _7732;
                        do
                        {
                            int _4443 = int(_192._m22.z);
                            if (_4443 <= 0)
                            {
                                _7732 = spvDepthCast(_212).sample_compare(_212Smplr, float3(fast::clamp(_4404, _4417.xy, _4417.zw), _4380).xy, _4380);
                                break;
                            }
                            float2 _4466 = (_4404 / _192._m22.xy) + float2(0.5);
                            float2 _4467 = floor(_4466);
                            float2 _4472 = _4466 - _4467;
                            float2 _4475 = _4467 - float2(0.5);
                            bool _4479 = _4443 == 1;
                            spvUnsafeArray<float2, 3> _4427;
                            spvUnsafeArray<float2, 3> _4428;
                            if (_4479)
                            {
                                float2 _4482 = _4472 * 2.0;
                                _4427[0] = float2(3.0) - _4482;
                                _4427[1] = float2(1.0) + _4482;
                                _4428[0] = ((float2(2.0) - _4472) / _4427[0]) - float2(1.0);
                                _4428[1] = (_4472 / _4427[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _4509 = _4472 * 3.0;
                                _4427[0] = float2(4.0) - _4509;
                                _4427[1] = float2(7.0);
                                _4427[2] = float2(1.0) + _4509;
                                _4428[0] = ((float2(3.0) - (_4472 * 2.0)) / _4427[0]) - float2(2.0);
                                _4428[1] = (float2(3.0) + _4472) / _4427[1];
                                _4428[2] = (_4472 / _4427[2]) + float2(2.0);
                            }
                            int _8476 = _4479 ? 2 : 3;
                            int _7722;
                            float _7725;
                            _7725 = 0.0;
                            _7722 = 0;
                            float _7731;
                            for (; _7722 < _8476; _7725 = _7731, _7722++)
                            {
                                _7731 = _7725;
                                for (int _7728 = 0; _7728 < _8476; )
                                {
                                    _7731 += ((_4427[_7728].x * _4427[_7722].y) * spvDepthCast(_212).sample_compare(_212Smplr, float3(fast::clamp(_192._m22.xy * (_4475 + float2(_4428[_7728].x, _4428[_7722].y)), _4417.xy, _4417.zw), _4380).xy, _4380));
                                    _7728++;
                                    continue;
                                }
                            }
                            _7732 = _7725 * (_4479 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _7733 = _7732;
                        break;
                    } while(false);
                    _7754 = mix(_7713, _7733, _3986);
                    _7751 = mix(_566[_7700], _566[_3988], float3(_3986));
                }
                else
                {
                    _7754 = mix(_7713, 1.0, _3986);
                    _7751 = _566[_7700];
                }
                _7753 = _7754;
                _7750 = _7751;
            }
            else
            {
                _7753 = _7713;
                _7750 = _566[_7700];
            }
            _7756 = select(float3(1.0), _7750, bool3(_192._m22.w > 0.5));
            _7755 = _7753;
            break;
        } while(false);
        _7919 = _7755;
        _7879 = _7785 * _7756;
    }
    else
    {
        _7919 = 1.0;
        _7879 = _7785;
    }
    float3 _2405 = _192._m5.xyz * _192._m4.w;
    bool _2409 = _1579._m6.w > 0.5;
    float _7808;
    if (_2409)
    {
        _7808 = 1.0;
    }
    else
    {
        _7808 = 1.0 + (_1579._m4.w * (_2057.sample(_1229, _2124).x - 1.0));
    }
    float _2429 = abs(in.m_1655.w);
    float _8009;
    if (_2429 > 0.0)
    {
        _8009 = _7808 * fast::min(_2429, 1.0);
    }
    else
    {
        _8009 = _7808;
    }
    float3 _8167;
    if (!_2326)
    {
        float _2445 = dot(_7885, _2356);
        float3 _8159;
        if (_192._m29.x > 0.5)
        {
            float _4660 = (_192._m29.z * _7885.x) - (_192._m29.w * _7885.z);
            float _4673 = (_192._m29.w * _7885.x) + (_192._m29.z * _7885.z);
            float _4691 = 1.09254801273345947265625 * _4660;
            spvUnsafeArray<float, 9> _7423 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _7885.y, 0.48860299587249755859375 * _4673, 0.48860299587249755859375 * _4660, _4691 * _7885.y, (1.09254801273345947265625 * _7885.y) * _4673, 0.3153919875621795654296875 * (((3.0 * _4673) * _4673) - 1.0), _4691 * _4673, 0.546274006366729736328125 * ((_4660 * _4660) - (_7885.y * _7885.y)) });
            spvUnsafeArray<float, 9> _4605 = _7423;
            float3 _8158;
            _8158 = float3(0.0);
            for (int _8157 = 0; _8157 < 9; )
            {
                _8158 += (_1227.read(uint2((int2(496, 256) + int2(_8157, 0))), 0).xyz * _4605[_8157]);
                _8157++;
                continue;
            }
            _8159 = fast::max(_8158, float3(0.0)) * _192._m29.y;
        }
        else
        {
            _8159 = mix(_192._m9.xyz, _192._m8.xyz, float3((_7885.y * 0.5) + 0.5)) * _192._m8.w;
        }
        float3 _2495 = (_7879 * ((_8159 * _8009) + ((_2405 * fast::max(_2445, 0.0)) * _7919))) + ((_2405 * ((powr(fast::max(dot(_7885, _2368), 0.0), _1579._m1.w) * _1579._m1.z) * step(0.0, _2445))) * _7919);
        float3 _8168;
        if (_192._m13.w > 0.5)
        {
            float2 _4776 = fast::clamp(floor(gl_FragCoord.xy * _192._m12.xy), float2(0.0), _192._m13.xy - float2(1.0));
            uint _4804 = uint((((fast::clamp(floor((log2(fast::max(dot(_192._m11.xyz, in.m_1741) + _192._m11.w, 9.9999999747524270787835121154785e-07)) * _192._m12.z) + _192._m12.w), 0.0, _192._m13.z - 1.0) * _192._m13.y) + _4776.y) * _192._m13.x) + _4776.x);
            uint _4806 = _4804 >> uint(2);
            uint _4808 = _4804 & 3u;
            uint _4812 = _1872._m0[_4806][_4808] & 65535u;
            uint _4814 = _1872._m0[_4806][_4808] >> uint(16);
            float3 _8169;
            _8169 = _2495;
            float3 _2576;
            spvUnsafeArray<float2, 3> _5222;
            spvUnsafeArray<float2, 3> _5223;
            spvUnsafeArray<float2, 3> _5435;
            spvUnsafeArray<float2, 3> _5436;
            for (uint _8166 = _4812; _8166 < (_4812 + _4814); _8169 = _2576, _8166++)
            {
                uint _4820 = _8166 / 3u;
                uint _4833 = (_1893._m0[_4820 >> uint(2)][_4820 & 3u] >> ((_8166 - (_4820 * 3u)) * 10u)) & 1023u;
                float3 _4850 = _1734._m0[_4833].xyz - in.m_1741;
                float _4853 = dot(_4850, _4850);
                float _4857 = _4853 * _1734._m0[_4833].w;
                float _4862 = fast::clamp(1.0 - (_4857 * _4857), 0.0, 1.0);
                float3 _4867 = _4850 * rsqrt(fast::max(_4853, 9.9999999392252902907785028219223e-09));
                float _4885 = fast::clamp((dot(-_4867, _1777._m0[_4833].xyz) * _1769._m0[_4833].w) + _1777._m0[_4833].w, 0.0, 1.0);
                float3 _4898 = _1769._m0[_4833].xyz * ((((_4862 * _4862) * _4885) * _4885) / fast::max(_4853, 9.9999997473787516355514526367188e-05));
                float3 _8374;
                if (_2379)
                {
                    float _8320;
                    do
                    {
                        uint _4934 = uint(_192._m21.z);
                        if (_4833 < _4934)
                        {
                            float _4956 = _192._m26[_4833].z * fast::max((_192._m15[_4833] * float4(in.m_1741, 1.0)).w, 0.0);
                            float4 _4980 = _192._m15[_4833] * float4((in.m_1741 + (_2374 * (_4956 * _192._m25.x))) + (_4867 * (_4956 * _192._m25.y)), 1.0);
                            float _4982 = _4980.w;
                            if (_4982 <= 0.0)
                            {
                                _8320 = 1.0;
                                break;
                            }
                            float3 _4991 = _4980.xyz / float3(_4982);
                            float _4993 = _4991.x;
                            bool _4994 = _4993 < 0.0;
                            bool _5001;
                            if (!_4994)
                            {
                                _5001 = _4993 > 1.0;
                            }
                            else
                            {
                                _5001 = _4994;
                            }
                            bool _5008;
                            if (!_5001)
                            {
                                _5008 = _4991.y < 0.0;
                            }
                            else
                            {
                                _5008 = _5001;
                            }
                            bool _5015;
                            if (!_5008)
                            {
                                _5015 = _4991.y > 1.0;
                            }
                            else
                            {
                                _5015 = _5008;
                            }
                            bool _5022;
                            if (!_5015)
                            {
                                _5022 = _4991.z > 1.0;
                            }
                            else
                            {
                                _5022 = _5015;
                            }
                            if (_5022)
                            {
                                _8320 = 1.0;
                                break;
                            }
                            float _5028 = _4991.z;
                            float2 _5194 = _192._m22.xy * 0.5;
                            float2 _5199 = _192._m26[_4833].xy + (_4991.xy * _192._m23.zw);
                            float4 _5212 = float4(_192._m26[_4833].xy + _5194, (_192._m26[_4833].xy + _192._m23.zw) - _5194);
                            float _8319;
                            do
                            {
                                int _5238 = int(_192._m22.z);
                                if (_5238 <= 0)
                                {
                                    float2 _5248 = fast::clamp(_5199, _5212.xy, _5212.zw);
                                    _8319 = spvDepthCast(_212).sample_compare(_212Smplr, float3(_5248, _5028).xy, _5028);
                                    break;
                                }
                                float2 _5261 = (_5199 / _192._m22.xy) + float2(0.5);
                                float2 _5262 = floor(_5261);
                                float2 _5267 = _5261 - _5262;
                                float2 _5270 = _5262 - float2(0.5);
                                bool _5274 = _5238 == 1;
                                if (_5274)
                                {
                                    float2 _5277 = _5267 * 2.0;
                                    _5222[0] = float2(3.0) - _5277;
                                    _5222[1] = float2(1.0) + _5277;
                                    _5223[0] = ((float2(2.0) - _5267) / _5222[0]) - float2(1.0);
                                    _5223[1] = (_5267 / _5222[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _5304 = _5267 * 3.0;
                                    _5222[0] = float2(4.0) - _5304;
                                    _5222[1] = float2(7.0);
                                    _5222[2] = float2(1.0) + _5304;
                                    _5223[0] = ((float2(3.0) - (_5267 * 2.0)) / _5222[0]) - float2(2.0);
                                    _5223[1] = (float2(3.0) + _5267) / _5222[1];
                                    _5223[2] = (_5267 / _5222[2]) + float2(2.0);
                                }
                                int _8481 = _5274 ? 2 : 3;
                                int _8309;
                                float _8312;
                                _8312 = 0.0;
                                _8309 = 0;
                                float _8318;
                                for (; _8309 < _8481; _8312 = _8318, _8309++)
                                {
                                    _8318 = _8312;
                                    for (int _8315 = 0; _8315 < _8481; )
                                    {
                                        _8318 += ((_5222[_8315].x * _5222[_8309].y) * spvDepthCast(_212).sample_compare(_212Smplr, float3(fast::clamp(_192._m22.xy * (_5270 + float2(_5223[_8315].x, _5223[_8309].y)), _5212.xy, _5212.zw), _5028).xy, _5028));
                                        _8315++;
                                        continue;
                                    }
                                }
                                _8319 = _8312 * (_5274 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _8320 = _8319;
                            break;
                        }
                        uint _5038 = _4833 - _4934;
                        if (_5038 >= uint(_192._m21.w))
                        {
                            _8320 = 1.0;
                            break;
                        }
                        float _5059 = _192._m27[_5038].w * length(in.m_1741 - _192._m27[_5038].xyz);
                        float3 _5077 = ((in.m_1741 + (_2374 * (_5059 * _192._m25.x))) + (_4867 * (_5059 * _192._m25.y))) - _192._m27[_5038].xyz;
                        float3 _5079 = abs(_5077);
                        float _5081 = _5079.x;
                        float _5083 = _5079.y;
                        bool _5084 = _5081 >= _5083;
                        bool _5092;
                        if (_5084)
                        {
                            _5092 = _5081 >= _5079.z;
                        }
                        else
                        {
                            _5092 = _5084;
                        }
                        float _8294;
                        int _8296;
                        if (_5092)
                        {
                            _8296 = (_5077.x > 0.0) ? 0 : 1;
                            _8294 = _5081;
                        }
                        else
                        {
                            float _5104 = _5079.z;
                            bool _5105 = _5083 >= _5104;
                            int _8297;
                            if (_5105)
                            {
                                _8297 = (_5077.y > 0.0) ? 2 : 3;
                            }
                            else
                            {
                                _8297 = (_5077.z > 0.0) ? 4 : 5;
                            }
                            _8296 = _8297;
                            _8294 = _5105 ? _5083 : _5104;
                        }
                        if (_8294 <= 0.0)
                        {
                            _8320 = 1.0;
                            break;
                        }
                        float2 _5142 = float2(dot(_5077, _870[_8296]), dot(_5077, _879[_8296])) / float2(_8294 * _192._m24.z);
                        float _5149 = _192._m28[_5038].z + (_192._m28[_5038].w / _8294);
                        if (_5149 > 1.0)
                        {
                            _8320 = 1.0;
                            break;
                        }
                        float2 _5167 = _192._m28[_5038].xy + (float2(float(spvSMod(_8296, 3)), float(_8296 / 3)) * _192._m24.xy);
                        float2 _5407 = _192._m22.xy * 0.5;
                        float2 _5412 = _5167 + (float2(0.5 + (0.5 * _5142.x), 0.5 - (0.5 * _5142.y)) * _192._m24.xy);
                        float4 _5425 = float4(_5167 + _5407, (_5167 + _192._m24.xy) - _5407);
                        float _8308;
                        do
                        {
                            int _5451 = int(_192._m22.z);
                            if (_5451 <= 0)
                            {
                                _8308 = spvDepthCast(_212).sample_compare(_212Smplr, float3(fast::clamp(_5412, _5425.xy, _5425.zw), _5149).xy, _5149);
                                break;
                            }
                            float2 _5474 = (_5412 / _192._m22.xy) + float2(0.5);
                            float2 _5475 = floor(_5474);
                            float2 _5480 = _5474 - _5475;
                            float2 _5483 = _5475 - float2(0.5);
                            bool _5487 = _5451 == 1;
                            if (_5487)
                            {
                                float2 _5490 = _5480 * 2.0;
                                _5435[0] = float2(3.0) - _5490;
                                _5435[1] = float2(1.0) + _5490;
                                _5436[0] = ((float2(2.0) - _5480) / _5435[0]) - float2(1.0);
                                _5436[1] = (_5480 / _5435[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _5517 = _5480 * 3.0;
                                _5435[0] = float2(4.0) - _5517;
                                _5435[1] = float2(7.0);
                                _5435[2] = float2(1.0) + _5517;
                                _5436[0] = ((float2(3.0) - (_5480 * 2.0)) / _5435[0]) - float2(2.0);
                                _5436[1] = (float2(3.0) + _5480) / _5435[1];
                                _5436[2] = (_5480 / _5435[2]) + float2(2.0);
                            }
                            int _8484 = _5487 ? 2 : 3;
                            int _8298;
                            float _8301;
                            _8301 = 0.0;
                            _8298 = 0;
                            float _8307;
                            for (; _8298 < _8484; _8301 = _8307, _8298++)
                            {
                                _8307 = _8301;
                                for (int _8304 = 0; _8304 < _8484; )
                                {
                                    _8307 += ((_5435[_8304].x * _5435[_8298].y) * spvDepthCast(_212).sample_compare(_212Smplr, float3(fast::clamp(_192._m22.xy * (_5483 + float2(_5436[_8304].x, _5436[_8298].y)), _5425.xy, _5425.zw), _5149).xy, _5149));
                                    _8304++;
                                    continue;
                                }
                            }
                            _8308 = _8301 * (_5487 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _8320 = _8308;
                        break;
                    } while(false);
                    _8374 = _4898 * _8320;
                }
                else
                {
                    _8374 = _4898;
                }
                float _2547 = dot(_7885, _4867);
                _2576 = _8169 + (((_7879 * fast::max(_2547, 0.0)) * _8374) + (_8374 * ((powr(fast::max(dot(_7885, fast::normalize(_4867 + _2363)), 0.0), _1579._m1.w) * _1579._m1.z) * step(0.0, _2547))));
            }
            _8168 = _8169;
        }
        else
        {
            _8168 = _2495;
        }
        _8167 = _8168;
    }
    else
    {
        float4 _2586 = _2581.sample(_1229, _2124);
        float _2593 = fast::clamp(_1579._m4.x * _2586.z, 0.0, 1.0);
        float _2601 = fast::clamp(_1579._m4.y * _2586.y, 0.04500000178813934326171875, 1.0);
        float _7875;
        float _7880;
        if (_7816 > 0.0)
        {
            _7880 = mix(_2593, _7849.y, _7816);
            _7875 = mix(_2601, fast::max(_7849.x, 0.04500000178813934326171875), _7816);
        }
        else
        {
            _7880 = _2593;
            _7875 = _2601;
        }
        float _2620 = _7875 * _7875;
        float3 _2625 = _7879 * (1.0 - _7880);
        float3 _2631 = mix(float3(0.039999999105930328369140625), _7879, float3(_7880));
        bool _2635 = _7695 > 0.0;
        float3 _7908;
        if (_2635)
        {
            float3 _2640 = dfdx(in.m_1741);
            float3 _2642 = dfdy(in.m_1741);
            float3 _2643 = cross(_2640, _2642);
            float3 _7909;
            if (dot(_2643, _2643) > 9.9999996826552253889678874634872e-21)
            {
                _7909 = fast::normalize((fast::normalize(_2643) * ((dot(_2643, _2363) < 0.0) ? (-1.0) : 1.0)) + (_7885 - _2218));
            }
            else
            {
                _7909 = _7885;
            }
            _7908 = _7909;
        }
        else
        {
            _7908 = _7885;
        }
        float _2669 = fast::max(dot(_7908, _2363), 9.9999997473787516355514526367188e-05);
        float _2678 = dot(_7908, _2356);
        float _2679 = fast::clamp(_2678, 0.0, 1.0);
        float _2684 = fast::clamp(dot(_7908, _2368), 0.0, 1.0);
        float _2689 = fast::clamp(dot(_2363, _2368), 0.0, 1.0);
        float _7912;
        float _7913;
        if (_2635)
        {
            _7913 = fast::max(_2669, 0.5);
            _7912 = fast::max(_2689, 0.5);
        }
        else
        {
            _7913 = _2669;
            _7912 = _2689;
        }
        float3 _5619 = float3(1.0) - _2631;
        float3 _5622 = _2631 + (_5619 * powr(1.0 - _7912, 5.0));
        float _5629 = _2620 * _2620;
        float _5634 = _5629 - 1.0;
        float _5636 = ((_2684 * _2684) * _5634) + 1.0;
        float _5656 = 1.0 - _5629;
        float _5660 = sqrt(((_7913 * _7913) * _5656) + _5629);
        float3 _2735 = (((((float3(1.0) - _5622) * _2625) * fast::clamp(dot(_7885, _2356), 0.0, 1.0)) + (((_5622 * ((_5629 / ((3.1415927410125732421875 * _5636) * _5636)) * (0.5 / fast::max((_2679 * _5660) + (_7913 * sqrt(((_2679 * _2679) * _5656) + _5629)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875) * _2679)) * _2405) * _7919;
        float3 _8023;
        if (_2635)
        {
            _8023 = _2735 + (((((_2625 * _2405) * _7919) * _7695) * fast::clamp(-_2678, 0.0, 1.0)) * (0.3499999940395355224609375 + (0.64999997615814208984375 * powr(fast::clamp(dot(-_2363, _2356), 0.0, 1.0), 3.0))));
        }
        else
        {
            _8023 = _2735;
        }
        float3 _7949;
        float2 _7973;
        float3 _7985;
        if (_192._m29.x > 0.5)
        {
            float4 _5693 = _1333.sample(_1335, (((float2(_7913, _7875) * 31.0) + float2(0.5)) * float2(0.03125)));
            float _5752 = (_192._m29.z * _7885.x) - (_192._m29.w * _7885.z);
            float _5765 = (_192._m29.w * _7885.x) + (_192._m29.z * _7885.z);
            float _5783 = 1.09254801273345947265625 * _5752;
            spvUnsafeArray<float, 9> _7404 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _7885.y, 0.48860299587249755859375 * _5765, 0.48860299587249755859375 * _5752, _5783 * _7885.y, (1.09254801273345947265625 * _7885.y) * _5765, 0.3153919875621795654296875 * (((3.0 * _5765) * _5765) - 1.0), _5783 * _5765, 0.546274006366729736328125 * ((_5752 * _5752) - (_7885.y * _7885.y)) });
            spvUnsafeArray<float, 9> _5697 = _7404;
            float3 _7931;
            _7931 = float3(0.0);
            for (int _7930 = 0; _7930 < 9; )
            {
                _7931 += (_1227.read(uint2((int2(496, 256) + int2(_7930, 0))), 0).xyz * _5697[_7930]);
                _7930++;
                continue;
            }
            float3 _2787 = reflect(-_2363, _7908);
            float _5878 = _2787.x;
            float _5883 = _2787.z;
            float2 _5915 = float2((precise::atan2((_192._m29.z * _5878) - (_192._m29.w * _5883), -((_192._m29.w * _5878) + (_192._m29.z * _5883))) * 0.15915493667125701904296875) + 0.5, acos(fast::clamp(_2787.y, -1.0, 1.0)) * 0.3183098733425140380859375);
            float _5847 = _7875 * 5.0;
            int _5850 = min(int(_5847), 4);
            float2 _5936 = (_5915 * float2(_1289[_5850].zw)) - float2(0.5);
            float2 _5938 = floor(_5936);
            float2 _5941 = _5936 - _5938;
            int _5944 = int(_5938.x);
            int _5947 = int(_5938.y);
            int _7934;
            if (_5944 < 0)
            {
                _7934 = _5944 + _1289[_5850].z;
            }
            else
            {
                _7934 = _5944;
            }
            int _7935;
            if (_7934 >= _1289[_5850].z)
            {
                _7935 = _7934 - _1289[_5850].z;
            }
            else
            {
                _7935 = _7934;
            }
            int _5967 = _7935 + 1;
            int _8485 = (_5967 == _1289[_5850].z) ? 0 : _5967;
            int _5982 = min((_5947 + 1), (_1289[_5850].w - 1));
            int _5984 = max(_5947, 0);
            float3 _6037 = float3(_5941.x);
            int _5857 = _5850 + 1;
            float2 _6069 = (_5915 * float2(_1289[_5857].zw)) - float2(0.5);
            float2 _6071 = floor(_6069);
            float2 _6074 = _6069 - _6071;
            int _6077 = int(_6071.x);
            int _6080 = int(_6071.y);
            int _7941;
            if (_6077 < 0)
            {
                _7941 = _6077 + _1289[_5857].z;
            }
            else
            {
                _7941 = _6077;
            }
            int _7942;
            if (_7941 >= _1289[_5857].z)
            {
                _7942 = _7941 - _1289[_5857].z;
            }
            else
            {
                _7942 = _7941;
            }
            int _6100 = _7942 + 1;
            int _8486 = (_6100 == _1289[_5857].z) ? 0 : _6100;
            int _6115 = min((_6080 + 1), (_1289[_5857].w - 1));
            int _6117 = max(_6080, 0);
            float3 _6170 = float3(_6074.x);
            float3 _5872 = mix(mix(mix(_1227.read(uint2((_1289[_5850].xy + int2(_7935, _5984))), 0).xyz, _1227.read(uint2((_1289[_5850].xy + int2(_8485, _5984))), 0).xyz, _6037), mix(_1227.read(uint2((_1289[_5850].xy + int2(_7935, _5982))), 0).xyz, _1227.read(uint2((_1289[_5850].xy + int2(_8485, _5982))), 0).xyz, _6037), float3(_5941.y)), mix(mix(_1227.read(uint2((_1289[_5857].xy + int2(_7942, _6117))), 0).xyz, _1227.read(uint2((_1289[_5857].xy + int2(_8486, _6117))), 0).xyz, _6170), mix(_1227.read(uint2((_1289[_5857].xy + int2(_7942, _6115))), 0).xyz, _1227.read(uint2((_1289[_5857].xy + int2(_8486, _6115))), 0).xyz, _6170), float3(_6074.y)), float3(_5847 - float(_5850))) * _192._m29.y;
            _7985 = fast::max(_7931, float3(0.0)) * _192._m29.y;
            _7973 = _5693.xy;
            _7949 = _5872;
        }
        else
        {
            float4 _6188 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * _7875) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);
            float _6190 = _6188.x;
            float3 _6225 = mix(_192._m9.xyz, _192._m8.xyz, float3((_7885.y * 0.5) + 0.5)) * _192._m8.w;
            _7985 = _6225;
            _7973 = (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_6190 * _6190, exp2((-9.27999973297119140625) * _7913)) * _6190) + _6188.y)) + _6188.zw;
            _7949 = mix(mix(_192._m9.xyz, _192._m8.xyz, float3((reflect(-_2363, _7908).y * 0.5) + 0.5)) * _192._m8.w, _6225, float3(_7875));
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
        float3 _7994;
        if (_2819)
        {
            float3 _7970;
            do
            {
                float _6304 = ((_192._m32.x * (1.0 - smoothstep(_192._m33.x * 0.5, _192._m33.x, abs(dot(_192._m31.xyz, in.m_1741) - _192._m31.w)))) * smoothstep(0.5, 0.89999997615814208984375, dot(_2374, _192._m31.xyz))) * (1.0 - smoothstep(_192._m32.y * 0.5, _192._m32.y, _7875));
                if (_6304 <= 0.0)
                {
                    _7970 = _7949;
                    break;
                }
                float4 _6329 = _192._m30 * float4(in.m_1741 + ((_7885 - (_192._m31.xyz * dot(_7885, _192._m31.xyz))) * _192._m32.w), 1.0);
                float2 _6342 = ((float2(_6329.x, -_6329.y) / float2(_6329.w)) * 0.5) + float2(0.5);
                float _6346 = _192._m32.z * _7875;
                float3 _7968;
                float _7969;
                _7969 = 0.0;
                _7968 = float3(0.0);
                for (int _7967 = 0; _7967 < 12; )
                {
                    float _6353 = float(_7967);
                    float _6361 = _6353 * 2.3999631404876708984375;
                    float2 _6373 = _6342 + (float2(cos(_6361) * _192._m33.y, sin(_6361)) * (sqrt((_6353 + 0.5) * 0.083333335816860198974609375) * _6346));
                    float2 _6378 = fast::min(_6373, float2(1.0) - _6373);
                    float _6384 = smoothstep(0.0, 0.039999999105930328369140625, fast::min(_6378.x, _6378.y));
                    float4 _6392 = _2057.sample(_1229, fast::clamp(_6373, float2(0.0), float2(1.0)), level(0.0));
                    float3 _6394 = _6392.xyz;
                    _7969 += (_6392.w * _6384);
                    _7968 += ((_6394 / (float3(1.0) - fast::min(_6394, float3(0.99500000476837158203125)))) * _6384);
                    _7967++;
                    continue;
                }
                _7970 = mix(_7949, (_7968 * float3(0.083333335816860198974609375)) + (_7949 * (1.0 - (_7969 * 0.083333335816860198974609375))), float3(_6304));
                break;
            } while(false);
            _7994 = _7970;
        }
        else
        {
            _7994 = _7949;
        }
        float3 _2839 = (_2631 * _7973.x) + float3(_7973.y);
        float3 _2855 = _8023 + (((((float3(1.0) - _2839) * _2625) * _7985) + (_2839 * _7994)) * _8009);
        float3 _8170;
        if (_192._m13.w > 0.5)
        {
            float2 _6458 = fast::clamp(floor(gl_FragCoord.xy * _192._m12.xy), float2(0.0), _192._m13.xy - float2(1.0));
            uint _6486 = uint((((fast::clamp(floor((log2(fast::max(dot(_192._m11.xyz, in.m_1741) + _192._m11.w, 9.9999999747524270787835121154785e-07)) * _192._m12.z) + _192._m12.w), 0.0, _192._m13.z - 1.0) * _192._m13.y) + _6458.y) * _192._m13.x) + _6458.x);
            uint _6488 = _6486 >> uint(2);
            uint _6490 = _6486 & 3u;
            uint _6494 = _1872._m0[_6488][_6490] & 65535u;
            uint _6496 = _1872._m0[_6488][_6490] >> uint(16);
            float3 _8123;
            _8123 = _2855;
            float3 _2955;
            spvUnsafeArray<float2, 3> _6904;
            spvUnsafeArray<float2, 3> _6905;
            spvUnsafeArray<float2, 3> _7117;
            spvUnsafeArray<float2, 3> _7118;
            for (uint _8026 = _6494; _8026 < (_6494 + _6496); _8123 = _2955, _8026++)
            {
                uint _6502 = _8026 / 3u;
                uint _6515 = (_1893._m0[_6502 >> uint(2)][_6502 & 3u] >> ((_8026 - (_6502 * 3u)) * 10u)) & 1023u;
                float3 _6532 = _1734._m0[_6515].xyz - in.m_1741;
                float _6535 = dot(_6532, _6532);
                float _6539 = _6535 * _1734._m0[_6515].w;
                float _6544 = fast::clamp(1.0 - (_6539 * _6539), 0.0, 1.0);
                float3 _6549 = _6532 * rsqrt(fast::max(_6535, 9.9999999392252902907785028219223e-09));
                float _6567 = fast::clamp((dot(-_6549, _1777._m0[_6515].xyz) * _1769._m0[_6515].w) + _1777._m0[_6515].w, 0.0, 1.0);
                float3 _6580 = _1769._m0[_6515].xyz * ((((_6544 * _6544) * _6567) * _6567) / fast::max(_6535, 9.9999997473787516355514526367188e-05));
                float3 _8121;
                if (_2379)
                {
                    float _8053;
                    do
                    {
                        uint _6616 = uint(_192._m21.z);
                        if (_6515 < _6616)
                        {
                            float _6638 = _192._m26[_6515].z * fast::max((_192._m15[_6515] * float4(in.m_1741, 1.0)).w, 0.0);
                            float4 _6662 = _192._m15[_6515] * float4((in.m_1741 + (_2374 * (_6638 * _192._m25.x))) + (_6549 * (_6638 * _192._m25.y)), 1.0);
                            float _6664 = _6662.w;
                            if (_6664 <= 0.0)
                            {
                                _8053 = 1.0;
                                break;
                            }
                            float3 _6673 = _6662.xyz / float3(_6664);
                            float _6675 = _6673.x;
                            bool _6676 = _6675 < 0.0;
                            bool _6683;
                            if (!_6676)
                            {
                                _6683 = _6675 > 1.0;
                            }
                            else
                            {
                                _6683 = _6676;
                            }
                            bool _6690;
                            if (!_6683)
                            {
                                _6690 = _6673.y < 0.0;
                            }
                            else
                            {
                                _6690 = _6683;
                            }
                            bool _6697;
                            if (!_6690)
                            {
                                _6697 = _6673.y > 1.0;
                            }
                            else
                            {
                                _6697 = _6690;
                            }
                            bool _6704;
                            if (!_6697)
                            {
                                _6704 = _6673.z > 1.0;
                            }
                            else
                            {
                                _6704 = _6697;
                            }
                            if (_6704)
                            {
                                _8053 = 1.0;
                                break;
                            }
                            float _6710 = _6673.z;
                            float2 _6876 = _192._m22.xy * 0.5;
                            float2 _6881 = _192._m26[_6515].xy + (_6673.xy * _192._m23.zw);
                            float4 _6894 = float4(_192._m26[_6515].xy + _6876, (_192._m26[_6515].xy + _192._m23.zw) - _6876);
                            float _8052;
                            do
                            {
                                int _6920 = int(_192._m22.z);
                                if (_6920 <= 0)
                                {
                                    float2 _6930 = fast::clamp(_6881, _6894.xy, _6894.zw);
                                    _8052 = spvDepthCast(_212).sample_compare(_212Smplr, float3(_6930, _6710).xy, _6710);
                                    break;
                                }
                                float2 _6943 = (_6881 / _192._m22.xy) + float2(0.5);
                                float2 _6944 = floor(_6943);
                                float2 _6949 = _6943 - _6944;
                                float2 _6952 = _6944 - float2(0.5);
                                bool _6956 = _6920 == 1;
                                if (_6956)
                                {
                                    float2 _6959 = _6949 * 2.0;
                                    _6904[0] = float2(3.0) - _6959;
                                    _6904[1] = float2(1.0) + _6959;
                                    _6905[0] = ((float2(2.0) - _6949) / _6904[0]) - float2(1.0);
                                    _6905[1] = (_6949 / _6904[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _6986 = _6949 * 3.0;
                                    _6904[0] = float2(4.0) - _6986;
                                    _6904[1] = float2(7.0);
                                    _6904[2] = float2(1.0) + _6986;
                                    _6905[0] = ((float2(3.0) - (_6949 * 2.0)) / _6904[0]) - float2(2.0);
                                    _6905[1] = (float2(3.0) + _6949) / _6904[1];
                                    _6905[2] = (_6949 / _6904[2]) + float2(2.0);
                                }
                                int _8488 = _6956 ? 2 : 3;
                                int _8042;
                                float _8045;
                                _8045 = 0.0;
                                _8042 = 0;
                                float _8051;
                                for (; _8042 < _8488; _8045 = _8051, _8042++)
                                {
                                    _8051 = _8045;
                                    for (int _8048 = 0; _8048 < _8488; )
                                    {
                                        _8051 += ((_6904[_8048].x * _6904[_8042].y) * spvDepthCast(_212).sample_compare(_212Smplr, float3(fast::clamp(_192._m22.xy * (_6952 + float2(_6905[_8048].x, _6905[_8042].y)), _6894.xy, _6894.zw), _6710).xy, _6710));
                                        _8048++;
                                        continue;
                                    }
                                }
                                _8052 = _8045 * (_6956 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _8053 = _8052;
                            break;
                        }
                        uint _6720 = _6515 - _6616;
                        if (_6720 >= uint(_192._m21.w))
                        {
                            _8053 = 1.0;
                            break;
                        }
                        float _6741 = _192._m27[_6720].w * length(in.m_1741 - _192._m27[_6720].xyz);
                        float3 _6759 = ((in.m_1741 + (_2374 * (_6741 * _192._m25.x))) + (_6549 * (_6741 * _192._m25.y))) - _192._m27[_6720].xyz;
                        float3 _6761 = abs(_6759);
                        float _6763 = _6761.x;
                        float _6765 = _6761.y;
                        bool _6766 = _6763 >= _6765;
                        bool _6774;
                        if (_6766)
                        {
                            _6774 = _6763 >= _6761.z;
                        }
                        else
                        {
                            _6774 = _6766;
                        }
                        float _8027;
                        int _8029;
                        if (_6774)
                        {
                            _8029 = (_6759.x > 0.0) ? 0 : 1;
                            _8027 = _6763;
                        }
                        else
                        {
                            float _6786 = _6761.z;
                            bool _6787 = _6765 >= _6786;
                            int _8030;
                            if (_6787)
                            {
                                _8030 = (_6759.y > 0.0) ? 2 : 3;
                            }
                            else
                            {
                                _8030 = (_6759.z > 0.0) ? 4 : 5;
                            }
                            _8029 = _8030;
                            _8027 = _6787 ? _6765 : _6786;
                        }
                        if (_8027 <= 0.0)
                        {
                            _8053 = 1.0;
                            break;
                        }
                        float2 _6824 = float2(dot(_6759, _870[_8029]), dot(_6759, _879[_8029])) / float2(_8027 * _192._m24.z);
                        float _6831 = _192._m28[_6720].z + (_192._m28[_6720].w / _8027);
                        if (_6831 > 1.0)
                        {
                            _8053 = 1.0;
                            break;
                        }
                        float2 _6849 = _192._m28[_6720].xy + (float2(float(spvSMod(_8029, 3)), float(_8029 / 3)) * _192._m24.xy);
                        float2 _7089 = _192._m22.xy * 0.5;
                        float2 _7094 = _6849 + (float2(0.5 + (0.5 * _6824.x), 0.5 - (0.5 * _6824.y)) * _192._m24.xy);
                        float4 _7107 = float4(_6849 + _7089, (_6849 + _192._m24.xy) - _7089);
                        float _8041;
                        do
                        {
                            int _7133 = int(_192._m22.z);
                            if (_7133 <= 0)
                            {
                                _8041 = spvDepthCast(_212).sample_compare(_212Smplr, float3(fast::clamp(_7094, _7107.xy, _7107.zw), _6831).xy, _6831);
                                break;
                            }
                            float2 _7156 = (_7094 / _192._m22.xy) + float2(0.5);
                            float2 _7157 = floor(_7156);
                            float2 _7162 = _7156 - _7157;
                            float2 _7165 = _7157 - float2(0.5);
                            bool _7169 = _7133 == 1;
                            if (_7169)
                            {
                                float2 _7172 = _7162 * 2.0;
                                _7117[0] = float2(3.0) - _7172;
                                _7117[1] = float2(1.0) + _7172;
                                _7118[0] = ((float2(2.0) - _7162) / _7117[0]) - float2(1.0);
                                _7118[1] = (_7162 / _7117[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _7199 = _7162 * 3.0;
                                _7117[0] = float2(4.0) - _7199;
                                _7117[1] = float2(7.0);
                                _7117[2] = float2(1.0) + _7199;
                                _7118[0] = ((float2(3.0) - (_7162 * 2.0)) / _7117[0]) - float2(2.0);
                                _7118[1] = (float2(3.0) + _7162) / _7117[1];
                                _7118[2] = (_7162 / _7117[2]) + float2(2.0);
                            }
                            int _8491 = _7169 ? 2 : 3;
                            int _8031;
                            float _8034;
                            _8034 = 0.0;
                            _8031 = 0;
                            float _8040;
                            for (; _8031 < _8491; _8034 = _8040, _8031++)
                            {
                                _8040 = _8034;
                                for (int _8037 = 0; _8037 < _8491; )
                                {
                                    _8040 += ((_7117[_8037].x * _7117[_8031].y) * spvDepthCast(_212).sample_compare(_212Smplr, float3(fast::clamp(_192._m22.xy * (_7165 + float2(_7118[_8037].x, _7118[_8031].y)), _7107.xy, _7107.zw), _6831).xy, _6831));
                                    _8037++;
                                    continue;
                                }
                            }
                            _8041 = _8034 * (_7169 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _8053 = _8041;
                        break;
                    } while(false);
                    _8121 = _6580 * _8053;
                }
                else
                {
                    _8121 = _6580;
                }
                float3 _2907 = fast::normalize(_6549 + _2363);
                float _2912 = fast::clamp(dot(_7885, _6549), 0.0, 1.0);
                float _2917 = fast::clamp(dot(_7885, _2907), 0.0, 1.0);
                float3 _7304 = _2631 + (_5619 * powr(1.0 - fast::clamp(dot(_2363, _2907), 0.0, 1.0), 5.0));
                float _7318 = ((_2917 * _2917) * _5634) + 1.0;
                _2955 = _8123 + (((((float3(1.0) - _7304) * _2625) + ((_7304 * ((_5629 / ((3.1415927410125732421875 * _7318) * _7318)) * (0.5 / fast::max((_2912 * _5660) + (_7913 * sqrt(((_2912 * _2912) * _5656) + _5629)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875)) * _2912) * _8121);
            }
            _8170 = _8123;
        }
        else
        {
            _8170 = _2855;
        }
        _8167 = _8170;
    }
    float4 _2972 = _2967.sample(_1229, _2124);
    float _2990 = -length(_2362);
    float _8212;
    if (_192._m9.w != 0.0)
    {
        float _3014 = _192._m9.w * (in.m_1741 - _192._m6.xyz).y;
        float _8209;
        if (abs(_3014) < 9.9999997473787516355514526367188e-05)
        {
            _8209 = 1.0 - (0.5 * _3014);
        }
        else
        {
            _8209 = (1.0 - exp(fast::min(-_3014, 60.0))) / _3014;
        }
        _8212 = 1.0 - exp((_2990 * (_192._m7.w * exp(fast::min((-_192._m9.w) * (_192._m6.y - _192._m6.w), 30.0)))) * _8209);
    }
    else
    {
        _8212 = 1.0 - exp(_2990 * _192._m7.w);
    }
    float3 _3065 = mix(mix(_8167, _7879, float3(_1579._m1.y)) + ((_1579._m5.xyz * _2972.xyz) * (float3(1.0) + in.m_2376.yzw)), _192._m7.xyz, float3(_8212));
    float3 _8213;
    if (_192._m33.w > 0.5)
    {
        _8213 = _3065 / (float3(1.0) + _3065);
    }
    else
    {
        _8213 = _3065;
    }
    out.m_3077 = float4(_8213, in.m_2133.w);
    float2 _8293;
    do
    {
        if (in.m_3087.w <= 0.0)
        {
            _8293 = float2(0.0);
            break;
        }
        _8293 = ((in.m_3087.xy / float2(in.m_3087.w)) - (in.m_3086.xy / float2(in.m_3086.w))) * float2(0.5, -0.5);
        break;
    } while(false);
    out.m_3085 = _8293;
    return out;
}

