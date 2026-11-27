// Generated from mesh_paint_mask_probes.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: a432f0f1030d456d
// glsl-fnv1a64: e309292037e28414

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

struct _281
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

struct _1279
{
    uint4 _m0[1];
};

struct _2874
{
    float4 _m0;
    float4 _m1;
    float4 _m2;
    float4 _m3;
    float4 _m4;
    float4 _m5;
    float4 _m6;
};

struct _3028
{
    float4 _m0[1024];
};

struct _3063
{
    float4 _m0[1024];
};

struct _3071
{
    float4 _m0[1024];
};

struct _3165
{
    uint4 _m0[1024];
};

struct _3186
{
    uint4 _m0[1024];
};

constant spvUnsafeArray<float3, 4> _657 = spvUnsafeArray<float3, 4>({ float3(1.0, 0.449999988079071044921875, 0.449999988079071044921875), float3(0.449999988079071044921875, 1.0, 0.449999988079071044921875), float3(0.5, 0.60000002384185791015625, 1.0), float3(1.0, 1.0, 0.4000000059604644775390625) });
constant spvUnsafeArray<float3, 6> _961 = spvUnsafeArray<float3, 6>({ float3(0.0, 0.0, 1.0), float3(0.0, 0.0, -1.0), float3(-1.0, 0.0, 0.0), float3(-1.0, 0.0, 0.0), float3(-1.0, 0.0, 0.0), float3(1.0, 0.0, 0.0) });
constant spvUnsafeArray<float3, 6> _970 = spvUnsafeArray<float3, 6>({ float3(0.0, 1.0, 0.0), float3(0.0, 1.0, 0.0), float3(0.0, 0.0, -1.0), float3(0.0, 0.0, 1.0), float3(0.0, 1.0, 0.0), float3(0.0, 1.0, 0.0) });
constant spvUnsafeArray<int3, 6> _1353 = spvUnsafeArray<int3, 6>({ int3(0, 256, 128), int3(32768, 128, 64), int3(40960, 64, 32), int3(43008, 32, 16), int3(43520, 16, 8), int3(43648, 8, 4) });
constant spvUnsafeArray<int4, 6> _2588 = spvUnsafeArray<int4, 6>({ int4(0, 0, 512, 256), int4(0, 256, 256, 128), int4(256, 256, 128, 64), int4(384, 256, 64, 32), int4(448, 256, 32, 16), int4(480, 256, 16, 8) });

struct fragment_main_out
{
    float4 m_4574 [[color(0)]];
    float2 m_4582 [[color(1)]];
};

struct fragment_main_in
{
    float3 m_3037 [[user(locn0)]];
    float3 m_2946 [[user(locn1)]];
    float2 m_3405 [[user(locn2)]];
    float4 m_3428 [[user(locn3)]];
    float3 m_2980 [[user(locn4)]];
    float4 m_3679 [[user(locn5)]];
    float4 m_4583 [[user(locn6)]];
    float4 m_4584 [[user(locn7)]];
    float4 m_2952 [[user(locn8)]];
    float4 m_3461 [[user(locn9)]];
    float4 m_3932 [[user(locn10)]];
};

fragment fragment_main_out fragment_main(fragment_main_in in [[stage_in]], constant _2874& _2876 [[buffer(2)]], constant _3028& _3030 [[buffer(3)]], constant _3063& _3065 [[buffer(4)]], constant _3071& _3073 [[buffer(5)]], constant _3165& _3167 [[buffer(6)]], constant _3186& _3188 [[buffer(7)]], constant _281& _283 [[buffer(15)]], const device _1279& _1281 [[buffer(21)]], texture2d<float> _303 [[texture(0)]], texture2d<float> _3421 [[texture(1)]], texture2d<float> _3920 [[texture(2)]], texture2d<float> _3556 [[texture(3)]], texture2d<float> _3352 [[texture(4)]], texture2d<float> _4424 [[texture(5)]], texture2d<float> _2531 [[texture(6)]], texture2d<float> _2632 [[texture(7)]], sampler _303Smplr [[sampler(0)]], sampler _2533 [[sampler(1)]], sampler _2634 [[sampler(7)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])
{
    fragment_main_out out = {};
    float2 _3419 = float2(dot(_2876._m2.xy, in.m_3405) + _2876._m2.z, dot(_2876._m3.xy, in.m_3405) + _2876._m3.z);
    float4 _3426 = _3421.sample(_2533, _3419);
    float3 _3436 = _3426.xyz;
    if ((_2876._m0.w * _3426.w) < _2876._m6.x)
    {
        discard_fragment();
    }
    float3 _3465 = ((in.m_3428.xyz * _2876._m0.xyz) * _3436) * in.m_3461.xyz;
    float3 _20856;
    if (_2876._m1.x > 0.5)
    {
        float2 _3480 = floor(in.m_3037.xz * float2(0.5));
        _20856 = _3465 * ((mod(abs(_3480.x + _3480.y), 2.0) < 0.5) ? 1.0 : 0.75);
    }
    else
    {
        _20856 = _3465;
    }
    float3 _20953;
    float _20984;
    float2 _21017;
    if (_2876._m3.w > 0.5)
    {
        float3 _4690;
        float2 _4697;
        float _20854;
        do
        {
            float3 _4661 = float4(_2876._m2.w, _2876._m3.w, 0.0, 0.0).xyy;
            float3 _4664 = floor(_4661 * float3(1.52587890625e-05));
            float3 _4669 = _4661 - (_4664 * 65536.0);
            float3 _4672 = floor(_4669 * float3(0.00390625));
            float3 _4680 = _4669 - (_4672 * 256.0);
            _4690 = (float3(_4680.x, _4672.x, _4664.x) * float3(0.0039215688593685626983642578125)) * 2.0;
            _4697 = float2(_4680.y, _4672.y) * float2(0.0039215688593685626983642578125);
            float _4700 = _4664.y - 128.0;
            float _4706 = floor(_4700 * 0.03125) * 0.3333333432674407958984375;
            float3 _4712 = fast::normalize(in.m_2946);
            float _4716 = dot(_4712, in.m_2952.xyz);
            float _4728 = (_4716 / fast::max(length(in.m_2952.xyz - (_4712 * _4716)), 9.9999999747524270787835121154785e-07)) * 25.5;
            if (((-24.0) + _4728) < (-2.0))
            {
                _20854 = 0.0;
                break;
            }
            float3 _4736 = in.m_2980 * (4.0 * exp2(mod(_4700, 32.0) * 0.3333333432674407958984375));
            float3 _4780 = floor(_4736);
            float3 _4783 = _4736 - _4780;
            float3 _4791 = (_4783 * _4783) * (float3(3.0) - (_4783 * 2.0));
            uint3 _4858 = uint3(int3(_4780));
            uint _4871 = (((_4858.x * 1597334677u) ^ (_4858.y * 3812015801u)) ^ (_4858.z * 2798796415u)) * 1597334677u;
            uint3 _4886 = uint3(int3(_4780 + float3(1.0, 0.0, 0.0)));
            uint _4899 = (((_4886.x * 1597334677u) ^ (_4886.y * 3812015801u)) ^ (_4886.z * 2798796415u)) * 1597334677u;
            float _4800 = _4791.x;
            uint3 _4914 = uint3(int3(_4780 + float3(0.0, 1.0, 0.0)));
            uint _4927 = (((_4914.x * 1597334677u) ^ (_4914.y * 3812015801u)) ^ (_4914.z * 2798796415u)) * 1597334677u;
            uint3 _4942 = uint3(int3(_4780 + float3(1.0, 1.0, 0.0)));
            uint _4955 = (((_4942.x * 1597334677u) ^ (_4942.y * 3812015801u)) ^ (_4942.z * 2798796415u)) * 1597334677u;
            float _4816 = _4791.y;
            uint3 _4970 = uint3(int3(_4780 + float3(0.0, 0.0, 1.0)));
            uint _4983 = (((_4970.x * 1597334677u) ^ (_4970.y * 3812015801u)) ^ (_4970.z * 2798796415u)) * 1597334677u;
            uint3 _4998 = uint3(int3(_4780 + float3(1.0, 0.0, 1.0)));
            uint _5011 = (((_4998.x * 1597334677u) ^ (_4998.y * 3812015801u)) ^ (_4998.z * 2798796415u)) * 1597334677u;
            uint3 _5026 = uint3(int3(_4780 + float3(0.0, 1.0, 1.0)));
            uint _5039 = (((_5026.x * 1597334677u) ^ (_5026.y * 3812015801u)) ^ (_5026.z * 2798796415u)) * 1597334677u;
            uint3 _5054 = uint3(int3(_4780 + float3(1.0)));
            uint _5067 = (((_5054.x * 1597334677u) ^ (_5054.y * 3812015801u)) ^ (_5054.z * 2798796415u)) * 1597334677u;
            float3 _4742 = (_4736 * 2.7000000476837158203125) + float3(17.299999237060546875, 5.099999904632568359375, 9.69999980926513671875);
            float3 _5093 = floor(_4742);
            float3 _5096 = _4742 - _5093;
            float3 _5104 = (_5096 * _5096) * (float3(3.0) - (_5096 * 2.0));
            uint3 _5171 = uint3(int3(_5093));
            uint _5184 = (((_5171.x * 1597334677u) ^ (_5171.y * 3812015801u)) ^ (_5171.z * 2798796415u)) * 1597334677u;
            uint3 _5199 = uint3(int3(_5093 + float3(1.0, 0.0, 0.0)));
            uint _5212 = (((_5199.x * 1597334677u) ^ (_5199.y * 3812015801u)) ^ (_5199.z * 2798796415u)) * 1597334677u;
            float _5113 = _5104.x;
            uint3 _5227 = uint3(int3(_5093 + float3(0.0, 1.0, 0.0)));
            uint _5240 = (((_5227.x * 1597334677u) ^ (_5227.y * 3812015801u)) ^ (_5227.z * 2798796415u)) * 1597334677u;
            uint3 _5255 = uint3(int3(_5093 + float3(1.0, 1.0, 0.0)));
            uint _5268 = (((_5255.x * 1597334677u) ^ (_5255.y * 3812015801u)) ^ (_5255.z * 2798796415u)) * 1597334677u;
            float _5129 = _5104.y;
            uint3 _5283 = uint3(int3(_5093 + float3(0.0, 0.0, 1.0)));
            uint _5296 = (((_5283.x * 1597334677u) ^ (_5283.y * 3812015801u)) ^ (_5283.z * 2798796415u)) * 1597334677u;
            uint3 _5311 = uint3(int3(_5093 + float3(1.0, 0.0, 1.0)));
            uint _5324 = (((_5311.x * 1597334677u) ^ (_5311.y * 3812015801u)) ^ (_5311.z * 2798796415u)) * 1597334677u;
            uint3 _5339 = uint3(int3(_5093 + float3(0.0, 1.0, 1.0)));
            uint _5352 = (((_5339.x * 1597334677u) ^ (_5339.y * 3812015801u)) ^ (_5339.z * 2798796415u)) * 1597334677u;
            uint3 _5367 = uint3(int3(_5093 + float3(1.0)));
            uint _5380 = (((_5367.x * 1597334677u) ^ (_5367.y * 3812015801u)) ^ (_5367.z * 2798796415u)) * 1597334677u;
            float _4747 = mix(0.449999988079071044921875, 0.0500000007450580596923828125, _4706);
            float _4751 = ((mix(mix(mix(float((_4871 ^ (_4871 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_4899 ^ (_4899 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _4800), mix(float((_4927 ^ (_4927 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_4955 ^ (_4955 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _4800), _4816), mix(mix(float((_4983 ^ (_4983 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_5011 ^ (_5011 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _4800), mix(float((_5039 ^ (_5039 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_5067 ^ (_5067 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _4800), _4816), _4791.z) * 0.64999997615814208984375) + (mix(mix(mix(float((_5184 ^ (_5184 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_5212 ^ (_5212 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _5113), mix(float((_5240 ^ (_5240 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_5268 ^ (_5268 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _5113), _5129), mix(mix(float((_5296 ^ (_5296 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_5324 ^ (_5324 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _5113), mix(float((_5352 ^ (_5352 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_5380 ^ (_5380 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _5113), _5129), _5104.z) * 0.3499999940395355224609375)) - 0.5;
            _20854 = smoothstep(-_4747, _4747, (_4728 + (-24.450000762939453125)) + (_4751 * mix(0.800000011920928955078125, 2.2000000476837158203125, _4706)));
            break;
        } while(false);
        _21017 = _4697;
        _20984 = _20854;
        _20953 = mix(_20856, (in.m_3428.xyz * _4690) * mix(float3(1.0), _3436 * 2.0, float3(0.5)), float3(_20854));
    }
    else
    {
        _21017 = float2(0.0);
        _20984 = 0.0;
        _20953 = _20856;
    }
    float3 _3522 = fast::normalize(in.m_2946);
    float3 _20866;
    if (_2876._m6.y > 0.5)
    {
        float3 _3537 = in.m_2952.xyz - (_3522 * dot(_3522, in.m_2952.xyz));
        float3 _20867;
        if (dot(_3537, _3537) > 9.9999999600419720025001879548654e-13)
        {
            float3 _3545 = fast::normalize(_3537);
            float4 _3561 = _3556.sample(_2533, _3419);
            float3 _20858;
            if (_2876._m6.z > 0.5)
            {
                float2 _20857;
                if (_2876._m6.z > 1.5)
                {
                    _20857 = _3561.xw;
                }
                else
                {
                    _20857 = _3561.xy;
                }
                float2 _3583 = (_20857 * 2.0) - float2(1.0);
                _20858 = float3(_3583, sqrt(fast::clamp(1.0 - dot(_3583, _3583), 0.0, 1.0)));
            }
            else
            {
                _20858 = (_3561.xyz * 2.0) - float3(1.0);
            }
            float2 _3605 = _20858.xy * _2876._m4.z;
            _20867 = fast::normalize(((_3545 * _3605.x) + ((cross(_3522, _3545) * ((in.m_2952.w < 0.0) ? (-1.0) : 1.0)) * _3605.y)) + (_3522 * _20858.z));
        }
        else
        {
            _20867 = _3522;
        }
        _20866 = _20867;
    }
    else
    {
        _20866 = _3522;
    }
    bool _3629 = _2876._m5.w > 0.5;
    float _20863;
    if (_3629)
    {
        _20863 = fast::clamp(_2876._m1.z, 0.0, 1.0);
    }
    else
    {
        _20863 = 0.0;
    }
    bool _3647;
    if (_3629)
    {
        _3647 = !gl_FrontFacing;
    }
    else
    {
        _3647 = _3629;
    }
    float3 _21053;
    if (_3647 && (_20863 <= 0.0))
    {
        _21053 = -_20866;
    }
    else
    {
        _21053 = _20866;
    }
    float3 _3659 = fast::normalize(_283._m4.xyz);
    float3 _3665 = _283._m6.xyz - in.m_3037;
    float3 _3666 = fast::normalize(_3665);
    float3 _3671 = fast::normalize(_3659 + _3666);
    float3 _3677 = _3522 * (gl_FrontFacing ? 1.0 : (-1.0));
    bool _3682 = in.m_3679.x > 0.5;
    float3 _21047;
    float _21087;
    if ((_283._m5.w > 0.5) && _3682)
    {
        float _20923;
        float3 _20924;
        do
        {
            int _5409 = int(_283._m21.x);
            float _5417 = dot(_283._m20.xyz, in.m_3037) + _283._m20.w;
            int _20868;
            _20868 = 0;
            for (;;)
            {
                bool _5423 = _20868 < (_5409 - 1);
                bool _5431;
                if (_5423)
                {
                    _5431 = _5417 > _283._m16[_20868];
                }
                else
                {
                    _5431 = _5423;
                }
                if (_5431)
                {
                    _20868++;
                    continue;
                }
                else
                {
                    break;
                }
            }
            if (_5417 > _283._m16[_20868])
            {
                _20924 = float3(1.0);
                _20923 = 1.0;
                break;
            }
            float _20881;
            do
            {
                float4 _5533 = _283._m14[_20868] * float4(in.m_3037 + (_3677 * _283._m18[_20868]), 1.0);
                float _5536 = _5533.x;
                bool _5537 = _5536 < 0.0;
                bool _5544;
                if (!_5537)
                {
                    _5544 = _5536 > 1.0;
                }
                else
                {
                    _5544 = _5537;
                }
                bool _5551;
                if (!_5544)
                {
                    _5551 = _5533.y < 0.0;
                }
                else
                {
                    _5551 = _5544;
                }
                bool _5558;
                if (!_5551)
                {
                    _5558 = _5533.y > 1.0;
                }
                else
                {
                    _5558 = _5551;
                }
                if (_5558)
                {
                    _20881 = 1.0;
                    break;
                }
                float2 _5571 = float2(float(_20868 & 1), float(_20868 >> 1)) * _283._m23.xy;
                float _5578 = fast::min(_5533.z, 1.0) - _283._m19[_20868];
                float2 _5597 = _283._m22.xy * 0.5;
                float2 _5602 = _5571 + (_5533.xy * _283._m23.xy);
                float4 _5615 = float4(_5571 + _5597, (_5571 + _283._m23.xy) - _5597);
                float _20880;
                do
                {
                    int _5641 = int(_283._m22.z);
                    if (_5641 <= 0)
                    {
                        _20880 = spvDepthCast(_303).sample_compare(_303Smplr, float3(fast::clamp(_5602, _5615.xy, _5615.zw), _5578).xy, _5578);
                        break;
                    }
                    float2 _5664 = (_5602 / _283._m22.xy) + float2(0.5);
                    float2 _5665 = floor(_5664);
                    float2 _5670 = _5664 - _5665;
                    float2 _5673 = _5665 - float2(0.5);
                    bool _5677 = _5641 == 1;
                    spvUnsafeArray<float2, 3> _5625;
                    spvUnsafeArray<float2, 3> _5626;
                    if (_5677)
                    {
                        float2 _5680 = _5670 * 2.0;
                        _5625[0] = float2(3.0) - _5680;
                        _5625[1] = float2(1.0) + _5680;
                        _5626[0] = ((float2(2.0) - _5670) / _5625[0]) - float2(1.0);
                        _5626[1] = (_5670 / _5625[1]) + float2(1.0);
                    }
                    else
                    {
                        float2 _5707 = _5670 * 3.0;
                        _5625[0] = float2(4.0) - _5707;
                        _5625[1] = float2(7.0);
                        _5625[2] = float2(1.0) + _5707;
                        _5626[0] = ((float2(3.0) - (_5670 * 2.0)) / _5625[0]) - float2(2.0);
                        _5626[1] = (float2(3.0) + _5670) / _5625[1];
                        _5626[2] = (_5670 / _5625[2]) + float2(2.0);
                    }
                    int _22279 = _5677 ? 2 : 3;
                    int _20870;
                    float _20873;
                    _20873 = 0.0;
                    _20870 = 0;
                    float _20879;
                    for (; _20870 < _22279; _20873 = _20879, _20870++)
                    {
                        _20879 = _20873;
                        for (int _20876 = 0; _20876 < _22279; )
                        {
                            _20879 += ((_5625[_20876].x * _5625[_20870].y) * spvDepthCast(_303).sample_compare(_303Smplr, float3(fast::clamp(_283._m22.xy * (_5673 + float2(_5626[_20876].x, _5626[_20870].y)), _5615.xy, _5615.zw), _5578).xy, _5578));
                            _20876++;
                            continue;
                        }
                    }
                    _20880 = _20873 * (_5677 ? 0.0625 : 0.0069444444961845874786376953125);
                    break;
                } while(false);
                _20881 = _20880;
                break;
            } while(false);
            float3 _20918;
            float _20921;
            if (_5417 > _283._m17[_20868])
            {
                float _5471 = (_5417 - _283._m17[_20868]) / (_283._m16[_20868] - _283._m17[_20868]);
                int _5473 = _20868 + 1;
                float3 _20919;
                float _20922;
                if (_5473 < _5409)
                {
                    float _20901;
                    do
                    {
                        float4 _5820 = _283._m14[_5473] * float4(in.m_3037 + (_3677 * _283._m18[_5473]), 1.0);
                        float _5823 = _5820.x;
                        bool _5824 = _5823 < 0.0;
                        bool _5831;
                        if (!_5824)
                        {
                            _5831 = _5823 > 1.0;
                        }
                        else
                        {
                            _5831 = _5824;
                        }
                        bool _5838;
                        if (!_5831)
                        {
                            _5838 = _5820.y < 0.0;
                        }
                        else
                        {
                            _5838 = _5831;
                        }
                        bool _5845;
                        if (!_5838)
                        {
                            _5845 = _5820.y > 1.0;
                        }
                        else
                        {
                            _5845 = _5838;
                        }
                        if (_5845)
                        {
                            _20901 = 1.0;
                            break;
                        }
                        float2 _5858 = float2(float(_5473 & 1), float(_5473 >> 1)) * _283._m23.xy;
                        float _5865 = fast::min(_5820.z, 1.0) - _283._m19[_5473];
                        float2 _5884 = _283._m22.xy * 0.5;
                        float2 _5889 = _5858 + (_5820.xy * _283._m23.xy);
                        float4 _5902 = float4(_5858 + _5884, (_5858 + _283._m23.xy) - _5884);
                        float _20900;
                        do
                        {
                            int _5928 = int(_283._m22.z);
                            if (_5928 <= 0)
                            {
                                _20900 = spvDepthCast(_303).sample_compare(_303Smplr, float3(fast::clamp(_5889, _5902.xy, _5902.zw), _5865).xy, _5865);
                                break;
                            }
                            float2 _5951 = (_5889 / _283._m22.xy) + float2(0.5);
                            float2 _5952 = floor(_5951);
                            float2 _5957 = _5951 - _5952;
                            float2 _5960 = _5952 - float2(0.5);
                            bool _5964 = _5928 == 1;
                            spvUnsafeArray<float2, 3> _5912;
                            spvUnsafeArray<float2, 3> _5913;
                            if (_5964)
                            {
                                float2 _5967 = _5957 * 2.0;
                                _5912[0] = float2(3.0) - _5967;
                                _5912[1] = float2(1.0) + _5967;
                                _5913[0] = ((float2(2.0) - _5957) / _5912[0]) - float2(1.0);
                                _5913[1] = (_5957 / _5912[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _5994 = _5957 * 3.0;
                                _5912[0] = float2(4.0) - _5994;
                                _5912[1] = float2(7.0);
                                _5912[2] = float2(1.0) + _5994;
                                _5913[0] = ((float2(3.0) - (_5957 * 2.0)) / _5912[0]) - float2(2.0);
                                _5913[1] = (float2(3.0) + _5957) / _5912[1];
                                _5913[2] = (_5957 / _5912[2]) + float2(2.0);
                            }
                            int _22281 = _5964 ? 2 : 3;
                            int _20890;
                            float _20893;
                            _20893 = 0.0;
                            _20890 = 0;
                            float _20899;
                            for (; _20890 < _22281; _20893 = _20899, _20890++)
                            {
                                _20899 = _20893;
                                for (int _20896 = 0; _20896 < _22281; )
                                {
                                    _20899 += ((_5912[_20896].x * _5912[_20890].y) * spvDepthCast(_303).sample_compare(_303Smplr, float3(fast::clamp(_283._m22.xy * (_5960 + float2(_5913[_20896].x, _5913[_20890].y)), _5902.xy, _5902.zw), _5865).xy, _5865));
                                    _20896++;
                                    continue;
                                }
                            }
                            _20900 = _20893 * (_5964 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _20901 = _20900;
                        break;
                    } while(false);
                    _20922 = mix(_20881, _20901, _5471);
                    _20919 = mix(_657[_20868], _657[_5473], float3(_5471));
                }
                else
                {
                    _20922 = mix(_20881, 1.0, _5471);
                    _20919 = _657[_20868];
                }
                _20921 = _20922;
                _20918 = _20919;
            }
            else
            {
                _20921 = _20881;
                _20918 = _657[_20868];
            }
            _20924 = select(float3(1.0), _20918, bool3(_283._m22.w > 0.5));
            _20923 = _20921;
            break;
        } while(false);
        _21087 = _20923;
        _21047 = _20953 * _20924;
    }
    else
    {
        _21087 = 1.0;
        _21047 = _20953;
    }
    float3 _3708 = _283._m5.xyz * _283._m4.w;
    bool _3712 = _2876._m6.w > 0.5;
    float _20976;
    if (_3712)
    {
        _20976 = 1.0;
    }
    else
    {
        _20976 = 1.0 + (_2876._m4.w * (_3352.sample(_2533, _3419).x - 1.0));
    }
    float _3732 = abs(in.m_2952.w);
    float _21177;
    if (_3732 > 0.0)
    {
        _21177 = _20976 * fast::min(_3732, 1.0);
    }
    else
    {
        _21177 = _20976;
    }
    float3 _21730;
    if (!_3629)
    {
        float _3748 = dot(_21053, _3659);
        bool _3773 = _283._m29.x > 0.5;
        float3 _21705;
        if (_3773)
        {
            float _6145 = (_283._m29.z * _21053.x) - (_283._m29.w * _21053.z);
            float _6158 = (_283._m29.w * _21053.x) + (_283._m29.z * _21053.z);
            float _6176 = 1.09254801273345947265625 * _6145;
            spvUnsafeArray<float, 9> _19418 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _21053.y, 0.48860299587249755859375 * _6158, 0.48860299587249755859375 * _6145, _6176 * _21053.y, (1.09254801273345947265625 * _21053.y) * _6158, 0.3153919875621795654296875 * (((3.0 * _6158) * _6158) - 1.0), _6176 * _6158, 0.546274006366729736328125 * ((_6145 * _6145) - (_21053.y * _21053.y)) });
            spvUnsafeArray<float, 9> _6090 = _19418;
            float3 _21704;
            _21704 = float3(0.0);
            for (int _21703 = 0; _21703 < 9; )
            {
                _21704 += (_2531.read(uint2((int2(496, 256) + int2(_21703, 0))), 0).xyz * _6090[_21703]);
                _21703++;
                continue;
            }
            _21705 = fast::max(_21704, float3(0.0)) * _283._m29.y;
        }
        else
        {
            _21705 = mix(_283._m9.xyz, _283._m8.xyz, float3((_21053.y * 0.5) + 0.5)) * _283._m8.w;
        }
        float3 _3798 = (_21047 * ((_21705 * _21177) + ((_3708 * fast::max(_3748, 0.0)) * _21087))) + ((_3708 * ((powr(fast::max(dot(_21053, _3671), 0.0), _2876._m1.w) * _2876._m1.z) * step(0.0, _3748))) * _21087);
        float3 _21732;
        if (_283._m34.y > 0.5)
        {
            float3 _21716;
            if (_3773)
            {
                float _6291 = (_283._m29.z * _21053.x) - (_283._m29.w * _21053.z);
                float _6304 = (_283._m29.w * _21053.x) + (_283._m29.z * _21053.z);
                float _6322 = 1.09254801273345947265625 * _6291;
                spvUnsafeArray<float, 9> _19399 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _21053.y, 0.48860299587249755859375 * _6304, 0.48860299587249755859375 * _6291, _6322 * _21053.y, (1.09254801273345947265625 * _21053.y) * _6304, 0.3153919875621795654296875 * (((3.0 * _6304) * _6304) - 1.0), _6322 * _6304, 0.546274006366729736328125 * ((_6291 * _6291) - (_21053.y * _21053.y)) });
                spvUnsafeArray<float, 9> _6236 = _19399;
                float3 _21715;
                _21715 = float3(0.0);
                for (int _21714 = 0; _21714 < 9; )
                {
                    _21715 += (_2531.read(uint2((int2(496, 256) + int2(_21714, 0))), 0).xyz * _6236[_21714]);
                    _21714++;
                    continue;
                }
                _21716 = fast::max(_21715, float3(0.0)) * _283._m29.y;
            }
            else
            {
                _21716 = mix(_283._m9.xyz, _283._m8.xyz, float3((_21053.y * 0.5) + 0.5)) * _283._m8.w;
            }
            int _6499 = int(_283._m34.y);
            int _6502 = int(_283._m34.x);
            float3 _21722;
            _21722 = _21716;
            float3 _22146;
            for (int _21721 = 0; _21721 < _6499; _21722 = _22146, _21721++)
            {
                int _6514 = 8 * (_6502 + _21721);
                float4 _6723 = as_type<float4>(_1281._m0[_6514 + 3]);
                float4 _6767 = as_type<float4>(_1281._m0[_6514]);
                float4 _6773 = as_type<float4>(_1281._m0[_6514 + 1]);
                float4 _6779 = as_type<float4>(_1281._m0[_6514 + 2]);
                float3 _6741 = _6767.xyz;
                float _6745 = _6767.w;
                float3 _6748 = _6773.xyz;
                float _6752 = _6773.w;
                float3 _6755 = _6779.xyz;
                float _6759 = _6779.w;
                float3 _6761 = float3(dot(_6741, in.m_3037) + _6745, dot(_6748, in.m_3037) + _6752, dot(_6755, in.m_3037) + _6759);
                float3 _6523 = _6723.xyz;
                float _6525 = _6723.w;
                float _22109;
                do
                {
                    float3 _6791 = _6523 - abs(_6761);
                    float _6799 = fast::min(_6791.x, fast::min(_6791.y, _6791.z));
                    if (_6799 <= 0.0)
                    {
                        _22109 = 0.0;
                        break;
                    }
                    if (_6525 <= 0.0)
                    {
                        _22109 = 1.0;
                        break;
                    }
                    float _6811 = fast::min(_6799 / _6525, 1.0);
                    _22109 = (_6811 * _6811) * (3.0 - (2.0 * _6811));
                    break;
                } while(false);
                if (_22109 <= 0.0)
                {
                    _22146 = _21722;
                    continue;
                }
                float3 _6534 = as_type<float4>(_1281._m0[_6514 + 4]).xyz;
                float4 _6832 = as_type<float4>(_1281._m0[_6514 + 5]);
                int _6838 = int(((device uint*)&_1281._m0[_6514 + 6])[0u]);
                float _6848 = dot(_6741, _21053);
                float _6854 = dot(_6748, _21053);
                float _6860 = dot(_6755, _21053);
                float3 _6861 = float3(_6848, _6854, _6860);
                float3 _6554 = (in.m_3037 + (_21053 * _6832.x)) + (_3666 * _6832.y);
                float3 _6573 = fast::clamp((((float3(dot(_6741, _6554) + _6745, dot(_6748, _6554) + _6752, dot(_6755, _6554) + _6759) + _6523) / fast::max(_6523 * 2.0, float3(9.9999999747524270787835121154785e-07))) * _6534) - float3(0.5), float3(0.0), _6534 - float3(1.0));
                int3 _6575 = int3(_6534);
                int3 _6582 = min(int3(_6573), max((_6575 - int3(2)), int3(0)));
                float3 _6586 = _6573 - float3(_6582);
                float _6941 = 0.48860299587249755859375 * _6854;
                float _6944 = 0.48860299587249755859375 * _6860;
                float _6947 = 0.48860299587249755859375 * _6848;
                float _6952 = 1.09254801273345947265625 * _6848;
                float _6955 = _6952 * _6854;
                float _6961 = (1.09254801273345947265625 * _6854) * _6860;
                float _6969 = 0.3153919875621795654296875 * (((3.0 * _6860) * _6860) - 1.0);
                float _6975 = _6952 * _6860;
                float _6989 = 0.546274006366729736328125 * ((_6848 * _6848) - (_6854 * _6854));
                int3 _7008 = _6575 - int3(1);
                int3 _7009 = min(_6582, _7008);
                int _7014 = _6575.x;
                int _7018 = _6575.y;
                int _7026 = _6838 + ((_7009.x + (_7014 * (_7009.y + (_7018 * _7009.z)))) * 4);
                float3 _7029 = float3(1.0) - _6586;
                float3 _7047 = (((((float3(_7009) + float3(0.5)) / _6534) * _6523) * 2.0) - _6523) - _6761;
                float _7057 = dot(_7047 * rsqrt(fast::max(dot(_7047, _7047), 1.0000000133514319600180897396058e-10)), _6861) + 1.0;
                float _7060 = _7029.x;
                float _7062 = _7029.y;
                float _7063 = _7060 * _7062;
                float _7065 = _7029.z;
                int _7089 = _7026 + 3;
                float _7075 = ((_7063 * _7065) * ((0.25 * (_7057 * _7057)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_7089])[1u])).y > 0.5);
                int _7119 = _7026 + 1;
                int _7123 = _7026 + 2;
                float2 _7135 = float2(as_type<half2>(_1281._m0[_7026].y));
                float2 _7144 = float2(as_type<half2>(_1281._m0[_7119].x));
                float2 _7153 = float2(as_type<half2>(_1281._m0[_7119].w));
                float2 _7162 = float2(as_type<half2>(_1281._m0[_7123].z));
                float3 _7250 = (((((((float3(float2(as_type<half2>(_1281._m0[_7026].x)), _7135.x) * 0.2820949852466583251953125) + (float3(_7135.y, float2(as_type<half2>(_1281._m0[_7026].z))) * _6941)) + (float3(float2(as_type<half2>(_1281._m0[_7026].w)), _7144.x) * _6944)) + (float3(_7144.y, float2(as_type<half2>(_1281._m0[_7119].y))) * _6947)) + (float3(float2(as_type<half2>(_1281._m0[_7119].z)), _7153.x) * _6955)) + (float3(_7153.y, float2(as_type<half2>(_1281._m0[_7123].x))) * _6961)) + (float3(float2(as_type<half2>(_1281._m0[_7123].y)), _7162.x) * _6969)) + (float3(_7162.y, float2(as_type<half2>(_1281._m0[_7123].w))) * _6975);
                int3 _7278 = min((_6582 + int3(1, 0, 0)), _7008);
                int _7295 = _6838 + ((_7278.x + (_7014 * (_7278.y + (_7018 * _7278.z)))) * 4);
                float3 _7316 = (((((float3(_7278) + float3(0.5)) / _6534) * _6523) * 2.0) - _6523) - _6761;
                float _7326 = dot(_7316 * rsqrt(fast::max(dot(_7316, _7316), 1.0000000133514319600180897396058e-10)), _6861) + 1.0;
                float _7332 = _6586.x * _7062;
                int _7358 = _7295 + 3;
                float _7344 = ((_7332 * _7065) * ((0.25 * (_7326 * _7326)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_7358])[1u])).y > 0.5);
                int _7388 = _7295 + 1;
                int _7392 = _7295 + 2;
                float2 _7404 = float2(as_type<half2>(_1281._m0[_7295].y));
                float2 _7413 = float2(as_type<half2>(_1281._m0[_7388].x));
                float2 _7422 = float2(as_type<half2>(_1281._m0[_7388].w));
                float2 _7431 = float2(as_type<half2>(_1281._m0[_7392].z));
                float3 _7519 = (((((((float3(float2(as_type<half2>(_1281._m0[_7295].x)), _7404.x) * 0.2820949852466583251953125) + (float3(_7404.y, float2(as_type<half2>(_1281._m0[_7295].z))) * _6941)) + (float3(float2(as_type<half2>(_1281._m0[_7295].w)), _7413.x) * _6944)) + (float3(_7413.y, float2(as_type<half2>(_1281._m0[_7388].y))) * _6947)) + (float3(float2(as_type<half2>(_1281._m0[_7388].z)), _7422.x) * _6955)) + (float3(_7422.y, float2(as_type<half2>(_1281._m0[_7392].x))) * _6961)) + (float3(float2(as_type<half2>(_1281._m0[_7392].y)), _7431.x) * _6969)) + (float3(_7431.y, float2(as_type<half2>(_1281._m0[_7392].w))) * _6975);
                int3 _7547 = min((_6582 + int3(0, 1, 0)), _7008);
                int _7564 = _6838 + ((_7547.x + (_7014 * (_7547.y + (_7018 * _7547.z)))) * 4);
                float3 _7585 = (((((float3(_7547) + float3(0.5)) / _6534) * _6523) * 2.0) - _6523) - _6761;
                float _7595 = dot(_7585 * rsqrt(fast::max(dot(_7585, _7585), 1.0000000133514319600180897396058e-10)), _6861) + 1.0;
                float _7601 = _7060 * _6586.y;
                int _7627 = _7564 + 3;
                float _7613 = ((_7601 * _7065) * ((0.25 * (_7595 * _7595)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_7627])[1u])).y > 0.5);
                int _7657 = _7564 + 1;
                int _7661 = _7564 + 2;
                float2 _7673 = float2(as_type<half2>(_1281._m0[_7564].y));
                float2 _7682 = float2(as_type<half2>(_1281._m0[_7657].x));
                float2 _7691 = float2(as_type<half2>(_1281._m0[_7657].w));
                float2 _7700 = float2(as_type<half2>(_1281._m0[_7661].z));
                float3 _7788 = (((((((float3(float2(as_type<half2>(_1281._m0[_7564].x)), _7673.x) * 0.2820949852466583251953125) + (float3(_7673.y, float2(as_type<half2>(_1281._m0[_7564].z))) * _6941)) + (float3(float2(as_type<half2>(_1281._m0[_7564].w)), _7682.x) * _6944)) + (float3(_7682.y, float2(as_type<half2>(_1281._m0[_7657].y))) * _6947)) + (float3(float2(as_type<half2>(_1281._m0[_7657].z)), _7691.x) * _6955)) + (float3(_7691.y, float2(as_type<half2>(_1281._m0[_7661].x))) * _6961)) + (float3(float2(as_type<half2>(_1281._m0[_7661].y)), _7700.x) * _6969)) + (float3(_7700.y, float2(as_type<half2>(_1281._m0[_7661].w))) * _6975);
                int3 _7816 = min((_6582 + int3(1, 1, 0)), _7008);
                int _7833 = _6838 + ((_7816.x + (_7014 * (_7816.y + (_7018 * _7816.z)))) * 4);
                float3 _7854 = (((((float3(_7816) + float3(0.5)) / _6534) * _6523) * 2.0) - _6523) - _6761;
                float _7864 = dot(_7854 * rsqrt(fast::max(dot(_7854, _7854), 1.0000000133514319600180897396058e-10)), _6861) + 1.0;
                float _7870 = _6586.x * _6586.y;
                int _7896 = _7833 + 3;
                float _7882 = ((_7870 * _7065) * ((0.25 * (_7864 * _7864)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_7896])[1u])).y > 0.5);
                int _7926 = _7833 + 1;
                int _7930 = _7833 + 2;
                float2 _7942 = float2(as_type<half2>(_1281._m0[_7833].y));
                float2 _7951 = float2(as_type<half2>(_1281._m0[_7926].x));
                float2 _7960 = float2(as_type<half2>(_1281._m0[_7926].w));
                float2 _7969 = float2(as_type<half2>(_1281._m0[_7930].z));
                float3 _8057 = (((((((float3(float2(as_type<half2>(_1281._m0[_7833].x)), _7942.x) * 0.2820949852466583251953125) + (float3(_7942.y, float2(as_type<half2>(_1281._m0[_7833].z))) * _6941)) + (float3(float2(as_type<half2>(_1281._m0[_7833].w)), _7951.x) * _6944)) + (float3(_7951.y, float2(as_type<half2>(_1281._m0[_7926].y))) * _6947)) + (float3(float2(as_type<half2>(_1281._m0[_7926].z)), _7960.x) * _6955)) + (float3(_7960.y, float2(as_type<half2>(_1281._m0[_7930].x))) * _6961)) + (float3(float2(as_type<half2>(_1281._m0[_7930].y)), _7969.x) * _6969)) + (float3(_7969.y, float2(as_type<half2>(_1281._m0[_7930].w))) * _6975);
                int3 _8085 = min((_6582 + int3(0, 0, 1)), _7008);
                int _8102 = _6838 + ((_8085.x + (_7014 * (_8085.y + (_7018 * _8085.z)))) * 4);
                float3 _8123 = (((((float3(_8085) + float3(0.5)) / _6534) * _6523) * 2.0) - _6523) - _6761;
                float _8133 = dot(_8123 * rsqrt(fast::max(dot(_8123, _8123), 1.0000000133514319600180897396058e-10)), _6861) + 1.0;
                int _8165 = _8102 + 3;
                float _8151 = ((_7063 * _6586.z) * ((0.25 * (_8133 * _8133)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_8165])[1u])).y > 0.5);
                int _8195 = _8102 + 1;
                int _8199 = _8102 + 2;
                float2 _8211 = float2(as_type<half2>(_1281._m0[_8102].y));
                float2 _8220 = float2(as_type<half2>(_1281._m0[_8195].x));
                float2 _8229 = float2(as_type<half2>(_1281._m0[_8195].w));
                float2 _8238 = float2(as_type<half2>(_1281._m0[_8199].z));
                float3 _8326 = (((((((float3(float2(as_type<half2>(_1281._m0[_8102].x)), _8211.x) * 0.2820949852466583251953125) + (float3(_8211.y, float2(as_type<half2>(_1281._m0[_8102].z))) * _6941)) + (float3(float2(as_type<half2>(_1281._m0[_8102].w)), _8220.x) * _6944)) + (float3(_8220.y, float2(as_type<half2>(_1281._m0[_8195].y))) * _6947)) + (float3(float2(as_type<half2>(_1281._m0[_8195].z)), _8229.x) * _6955)) + (float3(_8229.y, float2(as_type<half2>(_1281._m0[_8199].x))) * _6961)) + (float3(float2(as_type<half2>(_1281._m0[_8199].y)), _8238.x) * _6969)) + (float3(_8238.y, float2(as_type<half2>(_1281._m0[_8199].w))) * _6975);
                float4 _6653 = (((float4((_7250 + (float3(float2(as_type<half2>(_1281._m0[_7089].x)), float2(as_type<half2>(_1281._m0[_7089].y)).x) * _6989)) * _7075, _7075) + float4((_7519 + (float3(float2(as_type<half2>(_1281._m0[_7358].x)), float2(as_type<half2>(_1281._m0[_7358].y)).x) * _6989)) * _7344, _7344)) + float4((_7788 + (float3(float2(as_type<half2>(_1281._m0[_7627].x)), float2(as_type<half2>(_1281._m0[_7627].y)).x) * _6989)) * _7613, _7613)) + float4((_8057 + (float3(float2(as_type<half2>(_1281._m0[_7896].x)), float2(as_type<half2>(_1281._m0[_7896].y)).x) * _6989)) * _7882, _7882)) + float4((_8326 + (float3(float2(as_type<half2>(_1281._m0[_8165].x)), float2(as_type<half2>(_1281._m0[_8165].y)).x) * _6989)) * _8151, _8151);
                int3 _8354 = min((_6582 + int3(1, 0, 1)), _7008);
                int _8371 = _6838 + ((_8354.x + (_7014 * (_8354.y + (_7018 * _8354.z)))) * 4);
                float3 _8392 = (((((float3(_8354) + float3(0.5)) / _6534) * _6523) * 2.0) - _6523) - _6761;
                float _8402 = dot(_8392 * rsqrt(fast::max(dot(_8392, _8392), 1.0000000133514319600180897396058e-10)), _6861) + 1.0;
                int _8434 = _8371 + 3;
                float _8420 = ((_7332 * _6586.z) * ((0.25 * (_8402 * _8402)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_8434])[1u])).y > 0.5);
                int _8464 = _8371 + 1;
                int _8468 = _8371 + 2;
                float2 _8480 = float2(as_type<half2>(_1281._m0[_8371].y));
                float2 _8489 = float2(as_type<half2>(_1281._m0[_8464].x));
                float2 _8498 = float2(as_type<half2>(_1281._m0[_8464].w));
                float2 _8507 = float2(as_type<half2>(_1281._m0[_8468].z));
                float3 _8595 = (((((((float3(float2(as_type<half2>(_1281._m0[_8371].x)), _8480.x) * 0.2820949852466583251953125) + (float3(_8480.y, float2(as_type<half2>(_1281._m0[_8371].z))) * _6941)) + (float3(float2(as_type<half2>(_1281._m0[_8371].w)), _8489.x) * _6944)) + (float3(_8489.y, float2(as_type<half2>(_1281._m0[_8464].y))) * _6947)) + (float3(float2(as_type<half2>(_1281._m0[_8464].z)), _8498.x) * _6955)) + (float3(_8498.y, float2(as_type<half2>(_1281._m0[_8468].x))) * _6961)) + (float3(float2(as_type<half2>(_1281._m0[_8468].y)), _8507.x) * _6969)) + (float3(_8507.y, float2(as_type<half2>(_1281._m0[_8468].w))) * _6975);
                int3 _8623 = min((_6582 + int3(0, 1, 1)), _7008);
                int _8640 = _6838 + ((_8623.x + (_7014 * (_8623.y + (_7018 * _8623.z)))) * 4);
                float3 _8661 = (((((float3(_8623) + float3(0.5)) / _6534) * _6523) * 2.0) - _6523) - _6761;
                float _8671 = dot(_8661 * rsqrt(fast::max(dot(_8661, _8661), 1.0000000133514319600180897396058e-10)), _6861) + 1.0;
                int _8703 = _8640 + 3;
                float _8689 = ((_7601 * _6586.z) * ((0.25 * (_8671 * _8671)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_8703])[1u])).y > 0.5);
                int _8733 = _8640 + 1;
                int _8737 = _8640 + 2;
                float2 _8749 = float2(as_type<half2>(_1281._m0[_8640].y));
                float2 _8758 = float2(as_type<half2>(_1281._m0[_8733].x));
                float2 _8767 = float2(as_type<half2>(_1281._m0[_8733].w));
                float2 _8776 = float2(as_type<half2>(_1281._m0[_8737].z));
                float3 _8864 = (((((((float3(float2(as_type<half2>(_1281._m0[_8640].x)), _8749.x) * 0.2820949852466583251953125) + (float3(_8749.y, float2(as_type<half2>(_1281._m0[_8640].z))) * _6941)) + (float3(float2(as_type<half2>(_1281._m0[_8640].w)), _8758.x) * _6944)) + (float3(_8758.y, float2(as_type<half2>(_1281._m0[_8733].y))) * _6947)) + (float3(float2(as_type<half2>(_1281._m0[_8733].z)), _8767.x) * _6955)) + (float3(_8767.y, float2(as_type<half2>(_1281._m0[_8737].x))) * _6961)) + (float3(float2(as_type<half2>(_1281._m0[_8737].y)), _8776.x) * _6969)) + (float3(_8776.y, float2(as_type<half2>(_1281._m0[_8737].w))) * _6975);
                int3 _8892 = min((_6582 + int3(1)), _7008);
                int _8909 = _6838 + ((_8892.x + (_7014 * (_8892.y + (_7018 * _8892.z)))) * 4);
                float3 _8930 = (((((float3(_8892) + float3(0.5)) / _6534) * _6523) * 2.0) - _6523) - _6761;
                float _8940 = dot(_8930 * rsqrt(fast::max(dot(_8930, _8930), 1.0000000133514319600180897396058e-10)), _6861) + 1.0;
                int _8972 = _8909 + 3;
                float _8958 = ((_7870 * _6586.z) * ((0.25 * (_8940 * _8940)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_8972])[1u])).y > 0.5);
                int _9002 = _8909 + 1;
                int _9006 = _8909 + 2;
                float2 _9018 = float2(as_type<half2>(_1281._m0[_8909].y));
                float2 _9027 = float2(as_type<half2>(_1281._m0[_9002].x));
                float2 _9036 = float2(as_type<half2>(_1281._m0[_9002].w));
                float2 _9045 = float2(as_type<half2>(_1281._m0[_9006].z));
                float3 _9133 = (((((((float3(float2(as_type<half2>(_1281._m0[_8909].x)), _9018.x) * 0.2820949852466583251953125) + (float3(_9018.y, float2(as_type<half2>(_1281._m0[_8909].z))) * _6941)) + (float3(float2(as_type<half2>(_1281._m0[_8909].w)), _9027.x) * _6944)) + (float3(_9027.y, float2(as_type<half2>(_1281._m0[_9002].y))) * _6947)) + (float3(float2(as_type<half2>(_1281._m0[_9002].z)), _9036.x) * _6955)) + (float3(_9036.y, float2(as_type<half2>(_1281._m0[_9006].x))) * _6961)) + (float3(float2(as_type<half2>(_1281._m0[_9006].y)), _9045.x) * _6969)) + (float3(_9045.y, float2(as_type<half2>(_1281._m0[_9006].w))) * _6975);
                float4 _6692 = ((_6653 + float4((_8595 + (float3(float2(as_type<half2>(_1281._m0[_8434].x)), float2(as_type<half2>(_1281._m0[_8434].y)).x) * _6989)) * _8420, _8420)) + float4((_8864 + (float3(float2(as_type<half2>(_1281._m0[_8703].x)), float2(as_type<half2>(_1281._m0[_8703].y)).x) * _6989)) * _8689, _8689)) + float4((_9133 + (float3(float2(as_type<half2>(_1281._m0[_8972].x)), float2(as_type<half2>(_1281._m0[_8972].y)).x) * _6989)) * _8958, _8958);
                float _6696 = _6692.w;
                float3 _22147;
                if (_6696 > 9.9999997473787516355514526367188e-06)
                {
                    _22147 = mix(_21722, (fast::max(_6692.xyz, float3(0.0)) / float3(_6696)) * _6832.z, float3(_22109));
                }
                else
                {
                    _22147 = _21722;
                }
                _22146 = _22147;
            }
            _21732 = _3798 + ((_21047 * (_21722 - _21716)) * _21177);
        }
        else
        {
            _21732 = _3798;
        }
        float3 _21731;
        if (_283._m13.w > 0.5)
        {
            float2 _9171 = fast::clamp(floor(gl_FragCoord.xy * _283._m12.xy), float2(0.0), _283._m13.xy - float2(1.0));
            uint _9199 = uint((((fast::clamp(floor((log2(fast::max(dot(_283._m11.xyz, in.m_3037) + _283._m11.w, 9.9999999747524270787835121154785e-07)) * _283._m12.z) + _283._m12.w), 0.0, _283._m13.z - 1.0) * _283._m13.y) + _9171.y) * _283._m13.x) + _9171.x);
            uint _9201 = _9199 >> uint(2);
            uint _9203 = _9199 & 3u;
            uint _9207 = _3167._m0[_9201][_9203] & 65535u;
            uint _9209 = _3167._m0[_9201][_9203] >> uint(16);
            float3 _21733;
            _21733 = _21732;
            float3 _3915;
            spvUnsafeArray<float2, 3> _9617;
            spvUnsafeArray<float2, 3> _9618;
            spvUnsafeArray<float2, 3> _9830;
            spvUnsafeArray<float2, 3> _9831;
            for (uint _21729 = _9207; _21729 < (_9207 + _9209); _21733 = _3915, _21729++)
            {
                uint _9215 = _21729 / 3u;
                uint _9228 = (_3188._m0[_9215 >> uint(2)][_9215 & 3u] >> ((_21729 - (_9215 * 3u)) * 10u)) & 1023u;
                float3 _9245 = _3030._m0[_9228].xyz - in.m_3037;
                float _9248 = dot(_9245, _9245);
                float _9252 = _9248 * _3030._m0[_9228].w;
                float _9257 = fast::clamp(1.0 - (_9252 * _9252), 0.0, 1.0);
                float3 _9262 = _9245 * rsqrt(fast::max(_9248, 9.9999999392252902907785028219223e-09));
                float _9280 = fast::clamp((dot(-_9262, _3073._m0[_9228].xyz) * _3065._m0[_9228].w) + _3073._m0[_9228].w, 0.0, 1.0);
                float3 _9293 = _3065._m0[_9228].xyz * ((((_9257 * _9257) * _9280) * _9280) / fast::max(_9248, 9.9999997473787516355514526367188e-05));
                float3 _22074;
                if (_3682)
                {
                    float _22023;
                    do
                    {
                        uint _9329 = uint(_283._m21.z);
                        if (_9228 < _9329)
                        {
                            float _9351 = _283._m26[_9228].z * fast::max((_283._m15[_9228] * float4(in.m_3037, 1.0)).w, 0.0);
                            float4 _9375 = _283._m15[_9228] * float4((in.m_3037 + (_3677 * (_9351 * _283._m25.x))) + (_9262 * (_9351 * _283._m25.y)), 1.0);
                            float _9377 = _9375.w;
                            if (_9377 <= 0.0)
                            {
                                _22023 = 1.0;
                                break;
                            }
                            float3 _9386 = _9375.xyz / float3(_9377);
                            float _9388 = _9386.x;
                            bool _9389 = _9388 < 0.0;
                            bool _9396;
                            if (!_9389)
                            {
                                _9396 = _9388 > 1.0;
                            }
                            else
                            {
                                _9396 = _9389;
                            }
                            bool _9403;
                            if (!_9396)
                            {
                                _9403 = _9386.y < 0.0;
                            }
                            else
                            {
                                _9403 = _9396;
                            }
                            bool _9410;
                            if (!_9403)
                            {
                                _9410 = _9386.y > 1.0;
                            }
                            else
                            {
                                _9410 = _9403;
                            }
                            bool _9417;
                            if (!_9410)
                            {
                                _9417 = _9386.z > 1.0;
                            }
                            else
                            {
                                _9417 = _9410;
                            }
                            if (_9417)
                            {
                                _22023 = 1.0;
                                break;
                            }
                            float _9423 = _9386.z;
                            float2 _9589 = _283._m22.xy * 0.5;
                            float2 _9594 = _283._m26[_9228].xy + (_9386.xy * _283._m23.zw);
                            float4 _9607 = float4(_283._m26[_9228].xy + _9589, (_283._m26[_9228].xy + _283._m23.zw) - _9589);
                            float _22022;
                            do
                            {
                                int _9633 = int(_283._m22.z);
                                if (_9633 <= 0)
                                {
                                    float2 _9643 = fast::clamp(_9594, _9607.xy, _9607.zw);
                                    _22022 = spvDepthCast(_303).sample_compare(_303Smplr, float3(_9643, _9423).xy, _9423);
                                    break;
                                }
                                float2 _9656 = (_9594 / _283._m22.xy) + float2(0.5);
                                float2 _9657 = floor(_9656);
                                float2 _9662 = _9656 - _9657;
                                float2 _9665 = _9657 - float2(0.5);
                                bool _9669 = _9633 == 1;
                                if (_9669)
                                {
                                    float2 _9672 = _9662 * 2.0;
                                    _9617[0] = float2(3.0) - _9672;
                                    _9617[1] = float2(1.0) + _9672;
                                    _9618[0] = ((float2(2.0) - _9662) / _9617[0]) - float2(1.0);
                                    _9618[1] = (_9662 / _9617[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _9699 = _9662 * 3.0;
                                    _9617[0] = float2(4.0) - _9699;
                                    _9617[1] = float2(7.0);
                                    _9617[2] = float2(1.0) + _9699;
                                    _9618[0] = ((float2(3.0) - (_9662 * 2.0)) / _9617[0]) - float2(2.0);
                                    _9618[1] = (float2(3.0) + _9662) / _9617[1];
                                    _9618[2] = (_9662 / _9617[2]) + float2(2.0);
                                }
                                int _22286 = _9669 ? 2 : 3;
                                int _22012;
                                float _22015;
                                _22015 = 0.0;
                                _22012 = 0;
                                float _22021;
                                for (; _22012 < _22286; _22015 = _22021, _22012++)
                                {
                                    _22021 = _22015;
                                    for (int _22018 = 0; _22018 < _22286; )
                                    {
                                        _22021 += ((_9617[_22018].x * _9617[_22012].y) * spvDepthCast(_303).sample_compare(_303Smplr, float3(fast::clamp(_283._m22.xy * (_9665 + float2(_9618[_22018].x, _9618[_22012].y)), _9607.xy, _9607.zw), _9423).xy, _9423));
                                        _22018++;
                                        continue;
                                    }
                                }
                                _22022 = _22015 * (_9669 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _22023 = _22022;
                            break;
                        }
                        uint _9433 = _9228 - _9329;
                        if (_9433 >= uint(_283._m21.w))
                        {
                            _22023 = 1.0;
                            break;
                        }
                        float _9454 = _283._m27[_9433].w * length(in.m_3037 - _283._m27[_9433].xyz);
                        float3 _9472 = ((in.m_3037 + (_3677 * (_9454 * _283._m25.x))) + (_9262 * (_9454 * _283._m25.y))) - _283._m27[_9433].xyz;
                        float3 _9474 = abs(_9472);
                        float _9476 = _9474.x;
                        float _9478 = _9474.y;
                        bool _9479 = _9476 >= _9478;
                        bool _9487;
                        if (_9479)
                        {
                            _9487 = _9476 >= _9474.z;
                        }
                        else
                        {
                            _9487 = _9479;
                        }
                        float _21997;
                        int _21999;
                        if (_9487)
                        {
                            _21999 = (_9472.x > 0.0) ? 0 : 1;
                            _21997 = _9476;
                        }
                        else
                        {
                            float _9499 = _9474.z;
                            bool _9500 = _9478 >= _9499;
                            int _22000;
                            if (_9500)
                            {
                                _22000 = (_9472.y > 0.0) ? 2 : 3;
                            }
                            else
                            {
                                _22000 = (_9472.z > 0.0) ? 4 : 5;
                            }
                            _21999 = _22000;
                            _21997 = _9500 ? _9478 : _9499;
                        }
                        if (_21997 <= 0.0)
                        {
                            _22023 = 1.0;
                            break;
                        }
                        float2 _9537 = float2(dot(_9472, _961[_21999]), dot(_9472, _970[_21999])) / float2(_21997 * _283._m24.z);
                        float _9544 = _283._m28[_9433].z + (_283._m28[_9433].w / _21997);
                        if (_9544 > 1.0)
                        {
                            _22023 = 1.0;
                            break;
                        }
                        float2 _9562 = _283._m28[_9433].xy + (float2(float(spvSMod(_21999, 3)), float(_21999 / 3)) * _283._m24.xy);
                        float2 _9802 = _283._m22.xy * 0.5;
                        float2 _9807 = _9562 + (float2(0.5 + (0.5 * _9537.x), 0.5 - (0.5 * _9537.y)) * _283._m24.xy);
                        float4 _9820 = float4(_9562 + _9802, (_9562 + _283._m24.xy) - _9802);
                        float _22011;
                        do
                        {
                            int _9846 = int(_283._m22.z);
                            if (_9846 <= 0)
                            {
                                _22011 = spvDepthCast(_303).sample_compare(_303Smplr, float3(fast::clamp(_9807, _9820.xy, _9820.zw), _9544).xy, _9544);
                                break;
                            }
                            float2 _9869 = (_9807 / _283._m22.xy) + float2(0.5);
                            float2 _9870 = floor(_9869);
                            float2 _9875 = _9869 - _9870;
                            float2 _9878 = _9870 - float2(0.5);
                            bool _9882 = _9846 == 1;
                            if (_9882)
                            {
                                float2 _9885 = _9875 * 2.0;
                                _9830[0] = float2(3.0) - _9885;
                                _9830[1] = float2(1.0) + _9885;
                                _9831[0] = ((float2(2.0) - _9875) / _9830[0]) - float2(1.0);
                                _9831[1] = (_9875 / _9830[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _9912 = _9875 * 3.0;
                                _9830[0] = float2(4.0) - _9912;
                                _9830[1] = float2(7.0);
                                _9830[2] = float2(1.0) + _9912;
                                _9831[0] = ((float2(3.0) - (_9875 * 2.0)) / _9830[0]) - float2(2.0);
                                _9831[1] = (float2(3.0) + _9875) / _9830[1];
                                _9831[2] = (_9875 / _9830[2]) + float2(2.0);
                            }
                            int _22289 = _9882 ? 2 : 3;
                            int _22001;
                            float _22004;
                            _22004 = 0.0;
                            _22001 = 0;
                            float _22010;
                            for (; _22001 < _22289; _22004 = _22010, _22001++)
                            {
                                _22010 = _22004;
                                for (int _22007 = 0; _22007 < _22289; )
                                {
                                    _22010 += ((_9830[_22007].x * _9830[_22001].y) * spvDepthCast(_303).sample_compare(_303Smplr, float3(fast::clamp(_283._m22.xy * (_9878 + float2(_9831[_22007].x, _9831[_22001].y)), _9820.xy, _9820.zw), _9544).xy, _9544));
                                    _22007++;
                                    continue;
                                }
                            }
                            _22011 = _22004 * (_9882 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _22023 = _22011;
                        break;
                    } while(false);
                    _22074 = _9293 * _22023;
                }
                else
                {
                    _22074 = _9293;
                }
                float _3886 = dot(_21053, _9262);
                _3915 = _21733 + (((_21047 * fast::max(_3886, 0.0)) * _22074) + (_22074 * ((powr(fast::max(dot(_21053, fast::normalize(_9262 + _3666)), 0.0), _2876._m1.w) * _2876._m1.z) * step(0.0, _3886))));
            }
            _21731 = _21733;
        }
        else
        {
            _21731 = _21732;
        }
        _21730 = _21731;
    }
    else
    {
        float4 _3925 = _3920.sample(_2533, _3419);
        float _3936 = fast::clamp((_2876._m4.x * _3925.z) * in.m_3932.y, 0.0, 1.0);
        float _3947 = fast::clamp((_2876._m4.y * _3925.y) * in.m_3932.x, 0.04500000178813934326171875, 1.0);
        float _21043;
        float _21048;
        if (_20984 > 0.0)
        {
            _21048 = mix(_3936, _21017.y, _20984);
            _21043 = mix(_3947, fast::max(_21017.x, 0.04500000178813934326171875), _20984);
        }
        else
        {
            _21048 = _3936;
            _21043 = _3947;
        }
        float _3966 = _21043 * _21043;
        float3 _3971 = _21047 * (1.0 - _21048);
        float3 _3977 = mix(float3(0.039999999105930328369140625), _21047, float3(_21048));
        bool _3981 = _20863 > 0.0;
        float3 _21076;
        if (_3981)
        {
            float3 _3986 = dfdx(in.m_3037);
            float3 _3988 = dfdy(in.m_3037);
            float3 _3989 = cross(_3986, _3988);
            float3 _21077;
            if (dot(_3989, _3989) > 9.9999996826552253889678874634872e-21)
            {
                _21077 = fast::normalize((fast::normalize(_3989) * ((dot(_3989, _3666) < 0.0) ? (-1.0) : 1.0)) + (_21053 - _3522));
            }
            else
            {
                _21077 = _21053;
            }
            _21076 = _21077;
        }
        else
        {
            _21076 = _21053;
        }
        float _4015 = fast::max(dot(_21076, _3666), 9.9999997473787516355514526367188e-05);
        float _4024 = dot(_21076, _3659);
        float _4025 = fast::clamp(_4024, 0.0, 1.0);
        float _4030 = fast::clamp(dot(_21076, _3671), 0.0, 1.0);
        float _4035 = fast::clamp(dot(_3666, _3671), 0.0, 1.0);
        float _21080;
        float _21081;
        if (_3981)
        {
            _21081 = fast::max(_4015, 0.5);
            _21080 = fast::max(_4035, 0.5);
        }
        else
        {
            _21081 = _4015;
            _21080 = _4035;
        }
        float3 _10014 = float3(1.0) - _3977;
        float3 _10017 = _3977 + (_10014 * powr(1.0 - _21080, 5.0));
        float _10024 = _3966 * _3966;
        float _10029 = _10024 - 1.0;
        float _10031 = ((_4030 * _4030) * _10029) + 1.0;
        float _10051 = 1.0 - _10024;
        float _10055 = sqrt(((_21081 * _21081) * _10051) + _10024);
        float3 _4081 = (((((float3(1.0) - _10017) * _3971) * fast::clamp(dot(_21053, _3659), 0.0, 1.0)) + (((_10017 * ((_10024 / ((3.1415927410125732421875 * _10031) * _10031)) * (0.5 / fast::max((_4025 * _10055) + (_21081 * sqrt(((_4025 * _4025) * _10051) + _10024)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875) * _4025)) * _3708) * _21087;
        float3 _21191;
        if (_3981)
        {
            _21191 = _4081 + (((((_3971 * _3708) * _21087) * _20863) * fast::clamp(-_4024, 0.0, 1.0)) * (0.3499999940395355224609375 + (0.64999997615814208984375 * powr(fast::clamp(dot(-_3666, _3659), 0.0, 1.0), 3.0))));
        }
        else
        {
            _21191 = _4081;
        }
        bool _4116 = _283._m29.x > 0.5;
        float3 _21117;
        float2 _21141;
        float3 _21153;
        if (_4116)
        {
            float4 _10088 = _2632.sample(_2634, (((float2(_21081, _21043) * 31.0) + float2(0.5)) * float2(0.03125)));
            float _10147 = (_283._m29.z * _21053.x) - (_283._m29.w * _21053.z);
            float _10160 = (_283._m29.w * _21053.x) + (_283._m29.z * _21053.z);
            float _10178 = 1.09254801273345947265625 * _10147;
            spvUnsafeArray<float, 9> _19261 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _21053.y, 0.48860299587249755859375 * _10160, 0.48860299587249755859375 * _10147, _10178 * _21053.y, (1.09254801273345947265625 * _21053.y) * _10160, 0.3153919875621795654296875 * (((3.0 * _10160) * _10160) - 1.0), _10178 * _10160, 0.546274006366729736328125 * ((_10147 * _10147) - (_21053.y * _21053.y)) });
            spvUnsafeArray<float, 9> _10092 = _19261;
            float3 _21099;
            _21099 = float3(0.0);
            for (int _21098 = 0; _21098 < 9; )
            {
                _21099 += (_2531.read(uint2((int2(496, 256) + int2(_21098, 0))), 0).xyz * _10092[_21098]);
                _21098++;
                continue;
            }
            float3 _4133 = reflect(-_3666, _21076);
            float _10273 = _4133.x;
            float _10278 = _4133.z;
            float2 _10310 = float2((precise::atan2((_283._m29.z * _10273) - (_283._m29.w * _10278), -((_283._m29.w * _10273) + (_283._m29.z * _10278))) * 0.15915493667125701904296875) + 0.5, acos(fast::clamp(_4133.y, -1.0, 1.0)) * 0.3183098733425140380859375);
            float _10242 = _21043 * 5.0;
            int _10245 = min(int(_10242), 4);
            float2 _10331 = (_10310 * float2(_2588[_10245].zw)) - float2(0.5);
            float2 _10333 = floor(_10331);
            float2 _10336 = _10331 - _10333;
            int _10339 = int(_10333.x);
            int _10342 = int(_10333.y);
            int _21102;
            if (_10339 < 0)
            {
                _21102 = _10339 + _2588[_10245].z;
            }
            else
            {
                _21102 = _10339;
            }
            int _21103;
            if (_21102 >= _2588[_10245].z)
            {
                _21103 = _21102 - _2588[_10245].z;
            }
            else
            {
                _21103 = _21102;
            }
            int _10362 = _21103 + 1;
            int _22290 = (_10362 == _2588[_10245].z) ? 0 : _10362;
            int _10377 = min((_10342 + 1), (_2588[_10245].w - 1));
            int _10379 = max(_10342, 0);
            float3 _10432 = float3(_10336.x);
            int _10252 = _10245 + 1;
            float2 _10464 = (_10310 * float2(_2588[_10252].zw)) - float2(0.5);
            float2 _10466 = floor(_10464);
            float2 _10469 = _10464 - _10466;
            int _10472 = int(_10466.x);
            int _10475 = int(_10466.y);
            int _21109;
            if (_10472 < 0)
            {
                _21109 = _10472 + _2588[_10252].z;
            }
            else
            {
                _21109 = _10472;
            }
            int _21110;
            if (_21109 >= _2588[_10252].z)
            {
                _21110 = _21109 - _2588[_10252].z;
            }
            else
            {
                _21110 = _21109;
            }
            int _10495 = _21110 + 1;
            int _22291 = (_10495 == _2588[_10252].z) ? 0 : _10495;
            int _10510 = min((_10475 + 1), (_2588[_10252].w - 1));
            int _10512 = max(_10475, 0);
            float3 _10565 = float3(_10469.x);
            float3 _10267 = mix(mix(mix(_2531.read(uint2((_2588[_10245].xy + int2(_21103, _10379))), 0).xyz, _2531.read(uint2((_2588[_10245].xy + int2(_22290, _10379))), 0).xyz, _10432), mix(_2531.read(uint2((_2588[_10245].xy + int2(_21103, _10377))), 0).xyz, _2531.read(uint2((_2588[_10245].xy + int2(_22290, _10377))), 0).xyz, _10432), float3(_10336.y)), mix(mix(_2531.read(uint2((_2588[_10252].xy + int2(_21110, _10512))), 0).xyz, _2531.read(uint2((_2588[_10252].xy + int2(_22291, _10512))), 0).xyz, _10565), mix(_2531.read(uint2((_2588[_10252].xy + int2(_21110, _10510))), 0).xyz, _2531.read(uint2((_2588[_10252].xy + int2(_22291, _10510))), 0).xyz, _10565), float3(_10469.y)), float3(_10242 - float(_10245))) * _283._m29.y;
            _21153 = fast::max(_21099, float3(0.0)) * _283._m29.y;
            _21141 = _10088.xy;
            _21117 = _10267;
        }
        else
        {
            float4 _10583 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * _21043) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);
            float _10585 = _10583.x;
            float3 _10620 = mix(_283._m9.xyz, _283._m8.xyz, float3((_21053.y * 0.5) + 0.5)) * _283._m8.w;
            _21153 = _10620;
            _21141 = (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_10585 * _10585, exp2((-9.27999973297119140625) * _21081)) * _10585) + _10583.y)) + _10583.zw;
            _21117 = mix(mix(_283._m9.xyz, _283._m8.xyz, float3((reflect(-_3666, _21076).y * 0.5) + 0.5)) * _283._m8.w, _10620, float3(_21043));
        }
        bool _4165;
        if (_3712)
        {
            _4165 = _283._m33.z > 0.5;
        }
        else
        {
            _4165 = _3712;
        }
        float3 _21162;
        if (_4165)
        {
            float3 _21138;
            do
            {
                float _10699 = ((_283._m32.x * (1.0 - smoothstep(_283._m33.x * 0.5, _283._m33.x, abs(dot(_283._m31.xyz, in.m_3037) - _283._m31.w)))) * smoothstep(0.5, 0.89999997615814208984375, dot(_3677, _283._m31.xyz))) * (1.0 - smoothstep(_283._m32.y * 0.5, _283._m32.y, _21043));
                if (_10699 <= 0.0)
                {
                    _21138 = _21117;
                    break;
                }
                float4 _10724 = _283._m30 * float4(in.m_3037 + ((_21053 - (_283._m31.xyz * dot(_21053, _283._m31.xyz))) * _283._m32.w), 1.0);
                float2 _10737 = ((float2(_10724.x, -_10724.y) / float2(_10724.w)) * 0.5) + float2(0.5);
                float _10741 = _283._m32.z * _21043;
                float3 _21136;
                float _21137;
                _21137 = 0.0;
                _21136 = float3(0.0);
                for (int _21135 = 0; _21135 < 12; )
                {
                    float _10748 = float(_21135);
                    float _10756 = _10748 * 2.3999631404876708984375;
                    float2 _10768 = _10737 + (float2(cos(_10756) * _283._m33.y, sin(_10756)) * (sqrt((_10748 + 0.5) * 0.083333335816860198974609375) * _10741));
                    float2 _10773 = fast::min(_10768, float2(1.0) - _10768);
                    float _10779 = smoothstep(0.0, 0.039999999105930328369140625, fast::min(_10773.x, _10773.y));
                    float4 _10787 = _3352.sample(_2533, fast::clamp(_10768, float2(0.0), float2(1.0)), level(0.0));
                    float3 _10789 = _10787.xyz;
                    _21137 += (_10787.w * _10779);
                    _21136 += ((_10789 / (float3(1.0) - fast::min(_10789, float3(0.99500000476837158203125)))) * _10779);
                    _21135++;
                    continue;
                }
                _21138 = mix(_21117, (_21136 * float3(0.083333335816860198974609375)) + (_21117 * (1.0 - (_21137 * 0.083333335816860198974609375))), float3(_10699));
                break;
            } while(false);
            _21162 = _21138;
        }
        else
        {
            _21162 = _21117;
        }
        float3 _4185 = (_3977 * _21141.x) + float3(_21141.y);
        float3 _4190 = (float3(1.0) - _4185) * _3971;
        float3 _4201 = _21191 + (((_4190 * _21153) + (_4185 * _21162)) * _21177);
        float3 _21664;
        if ((_283._m34.x + _283._m34.y) > 0.5)
        {
            float3 _21199;
            if (_283._m34.y > 0.5)
            {
                int _10945 = int(_283._m34.y);
                int _10948 = int(_283._m34.x);
                float3 _21198;
                _21198 = _21153;
                float3 _22116;
                for (int _21197 = 0; _21197 < _10945; _21198 = _22116, _21197++)
                {
                    int _10960 = 8 * (_10948 + _21197);
                    float4 _11169 = as_type<float4>(_1281._m0[_10960 + 3]);
                    float4 _11213 = as_type<float4>(_1281._m0[_10960]);
                    float4 _11219 = as_type<float4>(_1281._m0[_10960 + 1]);
                    float4 _11225 = as_type<float4>(_1281._m0[_10960 + 2]);
                    float3 _11187 = _11213.xyz;
                    float _11191 = _11213.w;
                    float3 _11194 = _11219.xyz;
                    float _11198 = _11219.w;
                    float3 _11201 = _11225.xyz;
                    float _11205 = _11225.w;
                    float3 _11207 = float3(dot(_11187, in.m_3037) + _11191, dot(_11194, in.m_3037) + _11198, dot(_11201, in.m_3037) + _11205);
                    float3 _10969 = _11169.xyz;
                    float _10971 = _11169.w;
                    float _21698;
                    do
                    {
                        float3 _11237 = _10969 - abs(_11207);
                        float _11245 = fast::min(_11237.x, fast::min(_11237.y, _11237.z));
                        if (_11245 <= 0.0)
                        {
                            _21698 = 0.0;
                            break;
                        }
                        if (_10971 <= 0.0)
                        {
                            _21698 = 1.0;
                            break;
                        }
                        float _11257 = fast::min(_11245 / _10971, 1.0);
                        _21698 = (_11257 * _11257) * (3.0 - (2.0 * _11257));
                        break;
                    } while(false);
                    if (_21698 <= 0.0)
                    {
                        _22116 = _21198;
                        continue;
                    }
                    float3 _10980 = as_type<float4>(_1281._m0[_10960 + 4]).xyz;
                    float4 _11278 = as_type<float4>(_1281._m0[_10960 + 5]);
                    int _11284 = int(((device uint*)&_1281._m0[_10960 + 6])[0u]);
                    float _11294 = dot(_11187, _21053);
                    float _11300 = dot(_11194, _21053);
                    float _11306 = dot(_11201, _21053);
                    float3 _11307 = float3(_11294, _11300, _11306);
                    float3 _11000 = (in.m_3037 + (_21053 * _11278.x)) + (_3666 * _11278.y);
                    float3 _11019 = fast::clamp((((float3(dot(_11187, _11000) + _11191, dot(_11194, _11000) + _11198, dot(_11201, _11000) + _11205) + _10969) / fast::max(_10969 * 2.0, float3(9.9999999747524270787835121154785e-07))) * _10980) - float3(0.5), float3(0.0), _10980 - float3(1.0));
                    int3 _11021 = int3(_10980);
                    int3 _11028 = min(int3(_11019), max((_11021 - int3(2)), int3(0)));
                    float3 _11032 = _11019 - float3(_11028);
                    float _11387 = 0.48860299587249755859375 * _11300;
                    float _11390 = 0.48860299587249755859375 * _11306;
                    float _11393 = 0.48860299587249755859375 * _11294;
                    float _11398 = 1.09254801273345947265625 * _11294;
                    float _11401 = _11398 * _11300;
                    float _11407 = (1.09254801273345947265625 * _11300) * _11306;
                    float _11415 = 0.3153919875621795654296875 * (((3.0 * _11306) * _11306) - 1.0);
                    float _11421 = _11398 * _11306;
                    float _11435 = 0.546274006366729736328125 * ((_11294 * _11294) - (_11300 * _11300));
                    int3 _11454 = _11021 - int3(1);
                    int3 _11455 = min(_11028, _11454);
                    int _11460 = _11021.x;
                    int _11464 = _11021.y;
                    int _11472 = _11284 + ((_11455.x + (_11460 * (_11455.y + (_11464 * _11455.z)))) * 4);
                    float3 _11475 = float3(1.0) - _11032;
                    float3 _11493 = (((((float3(_11455) + float3(0.5)) / _10980) * _10969) * 2.0) - _10969) - _11207;
                    float _11503 = dot(_11493 * rsqrt(fast::max(dot(_11493, _11493), 1.0000000133514319600180897396058e-10)), _11307) + 1.0;
                    float _11506 = _11475.x;
                    float _11508 = _11475.y;
                    float _11509 = _11506 * _11508;
                    float _11511 = _11475.z;
                    int _11535 = _11472 + 3;
                    float _11521 = ((_11509 * _11511) * ((0.25 * (_11503 * _11503)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_11535])[1u])).y > 0.5);
                    int _11565 = _11472 + 1;
                    int _11569 = _11472 + 2;
                    float2 _11581 = float2(as_type<half2>(_1281._m0[_11472].y));
                    float2 _11590 = float2(as_type<half2>(_1281._m0[_11565].x));
                    float2 _11599 = float2(as_type<half2>(_1281._m0[_11565].w));
                    float2 _11608 = float2(as_type<half2>(_1281._m0[_11569].z));
                    float3 _11696 = (((((((float3(float2(as_type<half2>(_1281._m0[_11472].x)), _11581.x) * 0.2820949852466583251953125) + (float3(_11581.y, float2(as_type<half2>(_1281._m0[_11472].z))) * _11387)) + (float3(float2(as_type<half2>(_1281._m0[_11472].w)), _11590.x) * _11390)) + (float3(_11590.y, float2(as_type<half2>(_1281._m0[_11565].y))) * _11393)) + (float3(float2(as_type<half2>(_1281._m0[_11565].z)), _11599.x) * _11401)) + (float3(_11599.y, float2(as_type<half2>(_1281._m0[_11569].x))) * _11407)) + (float3(float2(as_type<half2>(_1281._m0[_11569].y)), _11608.x) * _11415)) + (float3(_11608.y, float2(as_type<half2>(_1281._m0[_11569].w))) * _11421);
                    int3 _11724 = min((_11028 + int3(1, 0, 0)), _11454);
                    int _11741 = _11284 + ((_11724.x + (_11460 * (_11724.y + (_11464 * _11724.z)))) * 4);
                    float3 _11762 = (((((float3(_11724) + float3(0.5)) / _10980) * _10969) * 2.0) - _10969) - _11207;
                    float _11772 = dot(_11762 * rsqrt(fast::max(dot(_11762, _11762), 1.0000000133514319600180897396058e-10)), _11307) + 1.0;
                    float _11778 = _11032.x * _11508;
                    int _11804 = _11741 + 3;
                    float _11790 = ((_11778 * _11511) * ((0.25 * (_11772 * _11772)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_11804])[1u])).y > 0.5);
                    int _11834 = _11741 + 1;
                    int _11838 = _11741 + 2;
                    float2 _11850 = float2(as_type<half2>(_1281._m0[_11741].y));
                    float2 _11859 = float2(as_type<half2>(_1281._m0[_11834].x));
                    float2 _11868 = float2(as_type<half2>(_1281._m0[_11834].w));
                    float2 _11877 = float2(as_type<half2>(_1281._m0[_11838].z));
                    float3 _11965 = (((((((float3(float2(as_type<half2>(_1281._m0[_11741].x)), _11850.x) * 0.2820949852466583251953125) + (float3(_11850.y, float2(as_type<half2>(_1281._m0[_11741].z))) * _11387)) + (float3(float2(as_type<half2>(_1281._m0[_11741].w)), _11859.x) * _11390)) + (float3(_11859.y, float2(as_type<half2>(_1281._m0[_11834].y))) * _11393)) + (float3(float2(as_type<half2>(_1281._m0[_11834].z)), _11868.x) * _11401)) + (float3(_11868.y, float2(as_type<half2>(_1281._m0[_11838].x))) * _11407)) + (float3(float2(as_type<half2>(_1281._m0[_11838].y)), _11877.x) * _11415)) + (float3(_11877.y, float2(as_type<half2>(_1281._m0[_11838].w))) * _11421);
                    int3 _11993 = min((_11028 + int3(0, 1, 0)), _11454);
                    int _12010 = _11284 + ((_11993.x + (_11460 * (_11993.y + (_11464 * _11993.z)))) * 4);
                    float3 _12031 = (((((float3(_11993) + float3(0.5)) / _10980) * _10969) * 2.0) - _10969) - _11207;
                    float _12041 = dot(_12031 * rsqrt(fast::max(dot(_12031, _12031), 1.0000000133514319600180897396058e-10)), _11307) + 1.0;
                    float _12047 = _11506 * _11032.y;
                    int _12073 = _12010 + 3;
                    float _12059 = ((_12047 * _11511) * ((0.25 * (_12041 * _12041)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_12073])[1u])).y > 0.5);
                    int _12103 = _12010 + 1;
                    int _12107 = _12010 + 2;
                    float2 _12119 = float2(as_type<half2>(_1281._m0[_12010].y));
                    float2 _12128 = float2(as_type<half2>(_1281._m0[_12103].x));
                    float2 _12137 = float2(as_type<half2>(_1281._m0[_12103].w));
                    float2 _12146 = float2(as_type<half2>(_1281._m0[_12107].z));
                    float3 _12234 = (((((((float3(float2(as_type<half2>(_1281._m0[_12010].x)), _12119.x) * 0.2820949852466583251953125) + (float3(_12119.y, float2(as_type<half2>(_1281._m0[_12010].z))) * _11387)) + (float3(float2(as_type<half2>(_1281._m0[_12010].w)), _12128.x) * _11390)) + (float3(_12128.y, float2(as_type<half2>(_1281._m0[_12103].y))) * _11393)) + (float3(float2(as_type<half2>(_1281._m0[_12103].z)), _12137.x) * _11401)) + (float3(_12137.y, float2(as_type<half2>(_1281._m0[_12107].x))) * _11407)) + (float3(float2(as_type<half2>(_1281._m0[_12107].y)), _12146.x) * _11415)) + (float3(_12146.y, float2(as_type<half2>(_1281._m0[_12107].w))) * _11421);
                    int3 _12262 = min((_11028 + int3(1, 1, 0)), _11454);
                    int _12279 = _11284 + ((_12262.x + (_11460 * (_12262.y + (_11464 * _12262.z)))) * 4);
                    float3 _12300 = (((((float3(_12262) + float3(0.5)) / _10980) * _10969) * 2.0) - _10969) - _11207;
                    float _12310 = dot(_12300 * rsqrt(fast::max(dot(_12300, _12300), 1.0000000133514319600180897396058e-10)), _11307) + 1.0;
                    float _12316 = _11032.x * _11032.y;
                    int _12342 = _12279 + 3;
                    float _12328 = ((_12316 * _11511) * ((0.25 * (_12310 * _12310)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_12342])[1u])).y > 0.5);
                    int _12372 = _12279 + 1;
                    int _12376 = _12279 + 2;
                    float2 _12388 = float2(as_type<half2>(_1281._m0[_12279].y));
                    float2 _12397 = float2(as_type<half2>(_1281._m0[_12372].x));
                    float2 _12406 = float2(as_type<half2>(_1281._m0[_12372].w));
                    float2 _12415 = float2(as_type<half2>(_1281._m0[_12376].z));
                    float3 _12503 = (((((((float3(float2(as_type<half2>(_1281._m0[_12279].x)), _12388.x) * 0.2820949852466583251953125) + (float3(_12388.y, float2(as_type<half2>(_1281._m0[_12279].z))) * _11387)) + (float3(float2(as_type<half2>(_1281._m0[_12279].w)), _12397.x) * _11390)) + (float3(_12397.y, float2(as_type<half2>(_1281._m0[_12372].y))) * _11393)) + (float3(float2(as_type<half2>(_1281._m0[_12372].z)), _12406.x) * _11401)) + (float3(_12406.y, float2(as_type<half2>(_1281._m0[_12376].x))) * _11407)) + (float3(float2(as_type<half2>(_1281._m0[_12376].y)), _12415.x) * _11415)) + (float3(_12415.y, float2(as_type<half2>(_1281._m0[_12376].w))) * _11421);
                    int3 _12531 = min((_11028 + int3(0, 0, 1)), _11454);
                    int _12548 = _11284 + ((_12531.x + (_11460 * (_12531.y + (_11464 * _12531.z)))) * 4);
                    float3 _12569 = (((((float3(_12531) + float3(0.5)) / _10980) * _10969) * 2.0) - _10969) - _11207;
                    float _12579 = dot(_12569 * rsqrt(fast::max(dot(_12569, _12569), 1.0000000133514319600180897396058e-10)), _11307) + 1.0;
                    int _12611 = _12548 + 3;
                    float _12597 = ((_11509 * _11032.z) * ((0.25 * (_12579 * _12579)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_12611])[1u])).y > 0.5);
                    int _12641 = _12548 + 1;
                    int _12645 = _12548 + 2;
                    float2 _12657 = float2(as_type<half2>(_1281._m0[_12548].y));
                    float2 _12666 = float2(as_type<half2>(_1281._m0[_12641].x));
                    float2 _12675 = float2(as_type<half2>(_1281._m0[_12641].w));
                    float2 _12684 = float2(as_type<half2>(_1281._m0[_12645].z));
                    float3 _12772 = (((((((float3(float2(as_type<half2>(_1281._m0[_12548].x)), _12657.x) * 0.2820949852466583251953125) + (float3(_12657.y, float2(as_type<half2>(_1281._m0[_12548].z))) * _11387)) + (float3(float2(as_type<half2>(_1281._m0[_12548].w)), _12666.x) * _11390)) + (float3(_12666.y, float2(as_type<half2>(_1281._m0[_12641].y))) * _11393)) + (float3(float2(as_type<half2>(_1281._m0[_12641].z)), _12675.x) * _11401)) + (float3(_12675.y, float2(as_type<half2>(_1281._m0[_12645].x))) * _11407)) + (float3(float2(as_type<half2>(_1281._m0[_12645].y)), _12684.x) * _11415)) + (float3(_12684.y, float2(as_type<half2>(_1281._m0[_12645].w))) * _11421);
                    float4 _11099 = (((float4((_11696 + (float3(float2(as_type<half2>(_1281._m0[_11535].x)), float2(as_type<half2>(_1281._m0[_11535].y)).x) * _11435)) * _11521, _11521) + float4((_11965 + (float3(float2(as_type<half2>(_1281._m0[_11804].x)), float2(as_type<half2>(_1281._m0[_11804].y)).x) * _11435)) * _11790, _11790)) + float4((_12234 + (float3(float2(as_type<half2>(_1281._m0[_12073].x)), float2(as_type<half2>(_1281._m0[_12073].y)).x) * _11435)) * _12059, _12059)) + float4((_12503 + (float3(float2(as_type<half2>(_1281._m0[_12342].x)), float2(as_type<half2>(_1281._m0[_12342].y)).x) * _11435)) * _12328, _12328)) + float4((_12772 + (float3(float2(as_type<half2>(_1281._m0[_12611].x)), float2(as_type<half2>(_1281._m0[_12611].y)).x) * _11435)) * _12597, _12597);
                    int3 _12800 = min((_11028 + int3(1, 0, 1)), _11454);
                    int _12817 = _11284 + ((_12800.x + (_11460 * (_12800.y + (_11464 * _12800.z)))) * 4);
                    float3 _12838 = (((((float3(_12800) + float3(0.5)) / _10980) * _10969) * 2.0) - _10969) - _11207;
                    float _12848 = dot(_12838 * rsqrt(fast::max(dot(_12838, _12838), 1.0000000133514319600180897396058e-10)), _11307) + 1.0;
                    int _12880 = _12817 + 3;
                    float _12866 = ((_11778 * _11032.z) * ((0.25 * (_12848 * _12848)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_12880])[1u])).y > 0.5);
                    int _12910 = _12817 + 1;
                    int _12914 = _12817 + 2;
                    float2 _12926 = float2(as_type<half2>(_1281._m0[_12817].y));
                    float2 _12935 = float2(as_type<half2>(_1281._m0[_12910].x));
                    float2 _12944 = float2(as_type<half2>(_1281._m0[_12910].w));
                    float2 _12953 = float2(as_type<half2>(_1281._m0[_12914].z));
                    float3 _13041 = (((((((float3(float2(as_type<half2>(_1281._m0[_12817].x)), _12926.x) * 0.2820949852466583251953125) + (float3(_12926.y, float2(as_type<half2>(_1281._m0[_12817].z))) * _11387)) + (float3(float2(as_type<half2>(_1281._m0[_12817].w)), _12935.x) * _11390)) + (float3(_12935.y, float2(as_type<half2>(_1281._m0[_12910].y))) * _11393)) + (float3(float2(as_type<half2>(_1281._m0[_12910].z)), _12944.x) * _11401)) + (float3(_12944.y, float2(as_type<half2>(_1281._m0[_12914].x))) * _11407)) + (float3(float2(as_type<half2>(_1281._m0[_12914].y)), _12953.x) * _11415)) + (float3(_12953.y, float2(as_type<half2>(_1281._m0[_12914].w))) * _11421);
                    int3 _13069 = min((_11028 + int3(0, 1, 1)), _11454);
                    int _13086 = _11284 + ((_13069.x + (_11460 * (_13069.y + (_11464 * _13069.z)))) * 4);
                    float3 _13107 = (((((float3(_13069) + float3(0.5)) / _10980) * _10969) * 2.0) - _10969) - _11207;
                    float _13117 = dot(_13107 * rsqrt(fast::max(dot(_13107, _13107), 1.0000000133514319600180897396058e-10)), _11307) + 1.0;
                    int _13149 = _13086 + 3;
                    float _13135 = ((_12047 * _11032.z) * ((0.25 * (_13117 * _13117)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_13149])[1u])).y > 0.5);
                    int _13179 = _13086 + 1;
                    int _13183 = _13086 + 2;
                    float2 _13195 = float2(as_type<half2>(_1281._m0[_13086].y));
                    float2 _13204 = float2(as_type<half2>(_1281._m0[_13179].x));
                    float2 _13213 = float2(as_type<half2>(_1281._m0[_13179].w));
                    float2 _13222 = float2(as_type<half2>(_1281._m0[_13183].z));
                    float3 _13310 = (((((((float3(float2(as_type<half2>(_1281._m0[_13086].x)), _13195.x) * 0.2820949852466583251953125) + (float3(_13195.y, float2(as_type<half2>(_1281._m0[_13086].z))) * _11387)) + (float3(float2(as_type<half2>(_1281._m0[_13086].w)), _13204.x) * _11390)) + (float3(_13204.y, float2(as_type<half2>(_1281._m0[_13179].y))) * _11393)) + (float3(float2(as_type<half2>(_1281._m0[_13179].z)), _13213.x) * _11401)) + (float3(_13213.y, float2(as_type<half2>(_1281._m0[_13183].x))) * _11407)) + (float3(float2(as_type<half2>(_1281._m0[_13183].y)), _13222.x) * _11415)) + (float3(_13222.y, float2(as_type<half2>(_1281._m0[_13183].w))) * _11421);
                    int3 _13338 = min((_11028 + int3(1)), _11454);
                    int _13355 = _11284 + ((_13338.x + (_11460 * (_13338.y + (_11464 * _13338.z)))) * 4);
                    float3 _13376 = (((((float3(_13338) + float3(0.5)) / _10980) * _10969) * 2.0) - _10969) - _11207;
                    float _13386 = dot(_13376 * rsqrt(fast::max(dot(_13376, _13376), 1.0000000133514319600180897396058e-10)), _11307) + 1.0;
                    int _13418 = _13355 + 3;
                    float _13404 = ((_12316 * _11032.z) * ((0.25 * (_13386 * _13386)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_13418])[1u])).y > 0.5);
                    int _13448 = _13355 + 1;
                    int _13452 = _13355 + 2;
                    float2 _13464 = float2(as_type<half2>(_1281._m0[_13355].y));
                    float2 _13473 = float2(as_type<half2>(_1281._m0[_13448].x));
                    float2 _13482 = float2(as_type<half2>(_1281._m0[_13448].w));
                    float2 _13491 = float2(as_type<half2>(_1281._m0[_13452].z));
                    float3 _13579 = (((((((float3(float2(as_type<half2>(_1281._m0[_13355].x)), _13464.x) * 0.2820949852466583251953125) + (float3(_13464.y, float2(as_type<half2>(_1281._m0[_13355].z))) * _11387)) + (float3(float2(as_type<half2>(_1281._m0[_13355].w)), _13473.x) * _11390)) + (float3(_13473.y, float2(as_type<half2>(_1281._m0[_13448].y))) * _11393)) + (float3(float2(as_type<half2>(_1281._m0[_13448].z)), _13482.x) * _11401)) + (float3(_13482.y, float2(as_type<half2>(_1281._m0[_13452].x))) * _11407)) + (float3(float2(as_type<half2>(_1281._m0[_13452].y)), _13491.x) * _11415)) + (float3(_13491.y, float2(as_type<half2>(_1281._m0[_13452].w))) * _11421);
                    float4 _11138 = ((_11099 + float4((_13041 + (float3(float2(as_type<half2>(_1281._m0[_12880].x)), float2(as_type<half2>(_1281._m0[_12880].y)).x) * _11435)) * _12866, _12866)) + float4((_13310 + (float3(float2(as_type<half2>(_1281._m0[_13149].x)), float2(as_type<half2>(_1281._m0[_13149].y)).x) * _11435)) * _13135, _13135)) + float4((_13579 + (float3(float2(as_type<half2>(_1281._m0[_13418].x)), float2(as_type<half2>(_1281._m0[_13418].y)).x) * _11435)) * _13404, _13404);
                    float _11142 = _11138.w;
                    float3 _22117;
                    if (_11142 > 9.9999997473787516355514526367188e-06)
                    {
                        _22117 = mix(_21198, (fast::max(_11138.xyz, float3(0.0)) / float3(_11142)) * _11278.z, float3(_21698));
                    }
                    else
                    {
                        _22117 = _21198;
                    }
                    _22116 = _22117;
                }
                _21199 = _21198;
            }
            else
            {
                _21199 = _21153;
            }
            float3 _21427;
            if (_283._m34.x > 0.5)
            {
                float3 _21236;
                if (_4116)
                {
                    float3 _4246 = reflect(-_3666, _21076);
                    float _13644 = _4246.x;
                    float _13649 = _4246.z;
                    float2 _13681 = float2((precise::atan2((_283._m29.z * _13644) - (_283._m29.w * _13649), -((_283._m29.w * _13644) + (_283._m29.z * _13649))) * 0.15915493667125701904296875) + 0.5, acos(fast::clamp(_4246.y, -1.0, 1.0)) * 0.3183098733425140380859375);
                    float _13613 = _21043 * 5.0;
                    int _13616 = min(int(_13613), 4);
                    float2 _13702 = (_13681 * float2(_2588[_13616].zw)) - float2(0.5);
                    float2 _13704 = floor(_13702);
                    float2 _13707 = _13702 - _13704;
                    int _13710 = int(_13704.x);
                    int _13713 = int(_13704.y);
                    int _21222;
                    if (_13710 < 0)
                    {
                        _21222 = _13710 + _2588[_13616].z;
                    }
                    else
                    {
                        _21222 = _13710;
                    }
                    int _21223;
                    if (_21222 >= _2588[_13616].z)
                    {
                        _21223 = _21222 - _2588[_13616].z;
                    }
                    else
                    {
                        _21223 = _21222;
                    }
                    int _13733 = _21223 + 1;
                    int _22292 = (_13733 == _2588[_13616].z) ? 0 : _13733;
                    int _13748 = min((_13713 + 1), (_2588[_13616].w - 1));
                    int _13750 = max(_13713, 0);
                    float3 _13803 = float3(_13707.x);
                    int _13623 = _13616 + 1;
                    float2 _13835 = (_13681 * float2(_2588[_13623].zw)) - float2(0.5);
                    float2 _13837 = floor(_13835);
                    float2 _13840 = _13835 - _13837;
                    int _13843 = int(_13837.x);
                    int _13846 = int(_13837.y);
                    int _21229;
                    if (_13843 < 0)
                    {
                        _21229 = _13843 + _2588[_13623].z;
                    }
                    else
                    {
                        _21229 = _13843;
                    }
                    int _21230;
                    if (_21229 >= _2588[_13623].z)
                    {
                        _21230 = _21229 - _2588[_13623].z;
                    }
                    else
                    {
                        _21230 = _21229;
                    }
                    int _13866 = _21230 + 1;
                    int _22293 = (_13866 == _2588[_13623].z) ? 0 : _13866;
                    int _13881 = min((_13846 + 1), (_2588[_13623].w - 1));
                    int _13883 = max(_13846, 0);
                    float3 _13936 = float3(_13840.x);
                    float3 _13638 = mix(mix(mix(_2531.read(uint2((_2588[_13616].xy + int2(_21223, _13750))), 0).xyz, _2531.read(uint2((_2588[_13616].xy + int2(_22292, _13750))), 0).xyz, _13803), mix(_2531.read(uint2((_2588[_13616].xy + int2(_21223, _13748))), 0).xyz, _2531.read(uint2((_2588[_13616].xy + int2(_22292, _13748))), 0).xyz, _13803), float3(_13707.y)), mix(mix(_2531.read(uint2((_2588[_13623].xy + int2(_21230, _13883))), 0).xyz, _2531.read(uint2((_2588[_13623].xy + int2(_22293, _13883))), 0).xyz, _13936), mix(_2531.read(uint2((_2588[_13623].xy + int2(_21230, _13881))), 0).xyz, _2531.read(uint2((_2588[_13623].xy + int2(_22293, _13881))), 0).xyz, _13936), float3(_13840.y)), float3(_13613 - float(_13616))) * _283._m29.y;
                    _21236 = _13638;
                }
                else
                {
                    _21236 = mix(mix(_283._m9.xyz, _283._m8.xyz, float3((reflect(-_3666, _21076).y * 0.5) + 0.5)) * _283._m8.w, _21153, float3(_21043));
                }
                float3 _4266 = reflect(-_3666, _21076);
                int _14002 = int(_283._m34.x);
                float _21252;
                float3 _21318;
                _21318 = float3(0.0);
                _21252 = 0.0;
                float _22130;
                float3 _22131;
                for (int _21251 = 0; _21251 < _14002; _21318 = _22131, _21252 = _22130, _21251++)
                {
                    if (_21252 > 0.999000012874603271484375)
                    {
                        break;
                    }
                    int _14014 = _21251 * 8;
                    float4 _14129 = as_type<float4>(_1281._m0[_14014]);
                    float4 _14135 = as_type<float4>(_1281._m0[_14014 + 1]);
                    float4 _14141 = as_type<float4>(_1281._m0[_14014 + 2]);
                    float3 _14103 = _14129.xyz;
                    float3 _14110 = _14135.xyz;
                    float3 _14117 = _14141.xyz;
                    float3 _14123 = float3(dot(_14103, in.m_3037) + _14129.w, dot(_14110, in.m_3037) + _14135.w, dot(_14117, in.m_3037) + _14141.w);
                    float4 _14147 = as_type<float4>(_1281._m0[_14014 + 3]);
                    float _14025 = _14147.w;
                    float _21253;
                    do
                    {
                        float3 _14159 = _14147.xyz - abs(_14123);
                        float _14167 = fast::min(_14159.x, fast::min(_14159.y, _14159.z));
                        if (_14167 <= 0.0)
                        {
                            _21253 = 0.0;
                            break;
                        }
                        if (_14025 <= 0.0)
                        {
                            _21253 = 1.0;
                            break;
                        }
                        float _14179 = fast::min(_14167 / _14025, 1.0);
                        _21253 = (_14179 * _14179) * (3.0 - (2.0 * _14179));
                        break;
                    } while(false);
                    if (_21253 <= 0.0)
                    {
                        _22131 = _21318;
                        _22130 = _21252;
                        continue;
                    }
                    float4 _14194 = as_type<float4>(_1281._m0[_14014 + 4]);
                    float4 _14200 = as_type<float4>(_1281._m0[_14014 + 5]);
                    float3 _14223 = float3(dot(_14103, _4266), dot(_14110, _4266), dot(_14117, _4266));
                    float3 _21255;
                    if (_14194.w > 0.5)
                    {
                        float3 _14047 = _14194.xyz;
                        float3 _14253 = -_14047;
                        float3 _14255 = fast::clamp(_14123, _14253, _14047);
                        float3 _14265 = step(float3(9.9999999747524270787835121154785e-07), abs(_14223));
                        float3 _14275 = mix(float3(1000000015047466219876688855040.0), (mix(_14253, _14047, step(float3(0.0), _14223)) - _14255) / mix(float3(9.9999999747524270787835121154785e-07), _14223, _14265), _14265);
                        float3 _14291 = (_14255 + (_14223 * fast::max(fast::min(_14275.x, fast::min(_14275.y, _14275.z)), 0.0))) - _14200.xyz;
                        float3 _21254;
                        if (dot(_14291, _14291) > 9.9999999600419720025001879548654e-13)
                        {
                            _21254 = fast::normalize(_14291);
                        }
                        else
                        {
                            _21254 = _14223;
                        }
                        _21255 = _21254;
                    }
                    else
                    {
                        _21255 = _14223;
                    }
                    int _14308 = int(((device uint*)&_1281._m0[_14014 + 6])[0u]);
                    float2 _14358 = float2((precise::atan2(_21255.x, -_21255.z) * 0.15915493667125701904296875) + 0.5, acos(fast::clamp(_21255.y, -1.0, 1.0)) * 0.3183098733425140380859375);
                    float _14324 = _21043 * 5.0;
                    int _14327 = min(int(_14324), 4);
                    int _14398 = _14308 + _1353[_14327].x;
                    float2 _14405 = (_14358 * float2(_1353[_14327].yz)) - float2(0.5);
                    float2 _14407 = floor(_14405);
                    float2 _14410 = _14405 - _14407;
                    int _14413 = int(_14407.x);
                    int _14416 = int(_14407.y);
                    int _21256;
                    if (_14413 < 0)
                    {
                        _21256 = _14413 + _1353[_14327].y;
                    }
                    else
                    {
                        _21256 = _14413;
                    }
                    int _21257;
                    if (_21256 >= _1353[_14327].y)
                    {
                        _21257 = _21256 - _1353[_14327].y;
                    }
                    else
                    {
                        _21257 = _21256;
                    }
                    int _14436 = _21257 + 1;
                    int _22294 = (_14436 == _1353[_14327].y) ? 0 : _14436;
                    int _14504 = _14398 + (max(_14416, 0) * _1353[_14327].y);
                    int _14506 = _14504 + _21257;
                    int _14508 = _14506 >> 1;
                    uint2 _21263;
                    if ((_14506 & 1) == 0)
                    {
                        _21263 = _1281._m0[_14508].xy;
                    }
                    else
                    {
                        _21263 = _1281._m0[_14508].zw;
                    }
                    int _14544 = _14504 + _22294;
                    int _14546 = _14544 >> 1;
                    uint2 _21265;
                    if ((_14544 & 1) == 0)
                    {
                        _21265 = _1281._m0[_14546].xy;
                    }
                    else
                    {
                        _21265 = _1281._m0[_14546].zw;
                    }
                    int _14580 = _14398 + (min((_14416 + 1), (_1353[_14327].z - 1)) * _1353[_14327].y);
                    int _14582 = _14580 + _21257;
                    int _14584 = _14582 >> 1;
                    uint2 _21268;
                    if ((_14582 & 1) == 0)
                    {
                        _21268 = _1281._m0[_14584].xy;
                    }
                    else
                    {
                        _21268 = _1281._m0[_14584].zw;
                    }
                    int _14620 = _14580 + _22294;
                    int _14622 = _14620 >> 1;
                    uint2 _21269;
                    if ((_14620 & 1) == 0)
                    {
                        _21269 = _1281._m0[_14622].xy;
                    }
                    else
                    {
                        _21269 = _1281._m0[_14622].zw;
                    }
                    float3 _14482 = float3(_14410.x);
                    int _14333 = _14327 + 1;
                    int _14685 = _14308 + _1353[_14333].x;
                    float2 _14692 = (_14358 * float2(_1353[_14333].yz)) - float2(0.5);
                    float2 _14694 = floor(_14692);
                    float2 _14697 = _14692 - _14694;
                    int _14700 = int(_14694.x);
                    int _14703 = int(_14694.y);
                    int _21270;
                    if (_14700 < 0)
                    {
                        _21270 = _14700 + _1353[_14333].y;
                    }
                    else
                    {
                        _21270 = _14700;
                    }
                    int _21271;
                    if (_21270 >= _1353[_14333].y)
                    {
                        _21271 = _21270 - _1353[_14333].y;
                    }
                    else
                    {
                        _21271 = _21270;
                    }
                    int _14723 = _21271 + 1;
                    int _22295 = (_14723 == _1353[_14333].y) ? 0 : _14723;
                    int _14791 = _14685 + (max(_14703, 0) * _1353[_14333].y);
                    int _14793 = _14791 + _21271;
                    int _14795 = _14793 >> 1;
                    uint2 _21277;
                    if ((_14793 & 1) == 0)
                    {
                        _21277 = _1281._m0[_14795].xy;
                    }
                    else
                    {
                        _21277 = _1281._m0[_14795].zw;
                    }
                    int _14831 = _14791 + _22295;
                    int _14833 = _14831 >> 1;
                    uint2 _21279;
                    if ((_14831 & 1) == 0)
                    {
                        _21279 = _1281._m0[_14833].xy;
                    }
                    else
                    {
                        _21279 = _1281._m0[_14833].zw;
                    }
                    int _14867 = _14685 + (min((_14703 + 1), (_1353[_14333].z - 1)) * _1353[_14333].y);
                    int _14869 = _14867 + _21271;
                    int _14871 = _14869 >> 1;
                    uint2 _21282;
                    if ((_14869 & 1) == 0)
                    {
                        _21282 = _1281._m0[_14871].xy;
                    }
                    else
                    {
                        _21282 = _1281._m0[_14871].zw;
                    }
                    int _14907 = _14867 + _22295;
                    int _14909 = _14907 >> 1;
                    uint2 _21283;
                    if ((_14907 & 1) == 0)
                    {
                        _21283 = _1281._m0[_14909].xy;
                    }
                    else
                    {
                        _21283 = _1281._m0[_14909].zw;
                    }
                    float3 _14769 = float3(_14697.x);
                    float3 _14063 = mix(mix(mix(float3(float2(as_type<half2>(_21263.x)), float2(as_type<half2>(_21263.y)).x), float3(float2(as_type<half2>(_21265.x)), float2(as_type<half2>(_21265.y)).x), _14482), mix(float3(float2(as_type<half2>(_21268.x)), float2(as_type<half2>(_21268.y)).x), float3(float2(as_type<half2>(_21269.x)), float2(as_type<half2>(_21269.y)).x), _14482), float3(_14410.y)), mix(mix(float3(float2(as_type<half2>(_21277.x)), float2(as_type<half2>(_21277.y)).x), float3(float2(as_type<half2>(_21279.x)), float2(as_type<half2>(_21279.y)).x), _14769), mix(float3(float2(as_type<half2>(_21282.x)), float2(as_type<half2>(_21282.y)).x), float3(float2(as_type<half2>(_21283.x)), float2(as_type<half2>(_21283.y)).x), _14769), float3(_14697.y)), float3(_14324 - float(_14327))) * _14200.w;
                    float _14067 = _21253 * (1.0 - _21252);
                    _22131 = _21318 + (_14063 * _14067);
                    _22130 = _21252 + _14067;
                }
                float3 _14085 = _21318 + (_21236 * (1.0 - _21252));
                bool _4283;
                if (_3712)
                {
                    _4283 = _283._m33.z > 0.5;
                }
                else
                {
                    _4283 = _3712;
                }
                float3 _21428;
                if (_4283)
                {
                    float3 _21394;
                    do
                    {
                        float _14994 = ((_283._m32.x * (1.0 - smoothstep(_283._m33.x * 0.5, _283._m33.x, abs(dot(_283._m31.xyz, in.m_3037) - _283._m31.w)))) * smoothstep(0.5, 0.89999997615814208984375, dot(_3677, _283._m31.xyz))) * (1.0 - smoothstep(_283._m32.y * 0.5, _283._m32.y, _21043));
                        if (_14994 <= 0.0)
                        {
                            _21394 = _14085;
                            break;
                        }
                        float4 _15019 = _283._m30 * float4(in.m_3037 + ((_21053 - (_283._m31.xyz * dot(_21053, _283._m31.xyz))) * _283._m32.w), 1.0);
                        float2 _15032 = ((float2(_15019.x, -_15019.y) / float2(_15019.w)) * 0.5) + float2(0.5);
                        float _15036 = _283._m32.z * _21043;
                        float3 _21392;
                        float _21393;
                        _21393 = 0.0;
                        _21392 = float3(0.0);
                        for (int _21391 = 0; _21391 < 12; )
                        {
                            float _15043 = float(_21391);
                            float _15051 = _15043 * 2.3999631404876708984375;
                            float2 _15063 = _15032 + (float2(cos(_15051) * _283._m33.y, sin(_15051)) * (sqrt((_15043 + 0.5) * 0.083333335816860198974609375) * _15036));
                            float2 _15068 = fast::min(_15063, float2(1.0) - _15063);
                            float _15074 = smoothstep(0.0, 0.039999999105930328369140625, fast::min(_15068.x, _15068.y));
                            float4 _15082 = _3352.sample(_2533, fast::clamp(_15063, float2(0.0), float2(1.0)), level(0.0));
                            float3 _15084 = _15082.xyz;
                            _21393 += (_15082.w * _15074);
                            _21392 += ((_15084 / (float3(1.0) - fast::min(_15084, float3(0.99500000476837158203125)))) * _15074);
                            _21391++;
                            continue;
                        }
                        _21394 = mix(_14085, (_21392 * float3(0.083333335816860198974609375)) + (_14085 * (1.0 - (_21393 * 0.083333335816860198974609375))), float3(_14994));
                        break;
                    } while(false);
                    _21428 = _21394;
                }
                else
                {
                    _21428 = _14085;
                }
                _21427 = _21428;
            }
            else
            {
                _21427 = _21162;
            }
            _21664 = _4201 + (((_4190 * (_21199 - _21153)) + (_4185 * (_21427 - _21162))) * _21177);
        }
        else
        {
            _21664 = _4201;
        }
        float3 _21734;
        if (_283._m13.w > 0.5)
        {
            float2 _15148 = fast::clamp(floor(gl_FragCoord.xy * _283._m12.xy), float2(0.0), _283._m13.xy - float2(1.0));
            uint _15176 = uint((((fast::clamp(floor((log2(fast::max(dot(_283._m11.xyz, in.m_3037) + _283._m11.w, 9.9999999747524270787835121154785e-07)) * _283._m12.z) + _283._m12.w), 0.0, _283._m13.z - 1.0) * _283._m13.y) + _15148.y) * _283._m13.x) + _15148.x);
            uint _15178 = _15176 >> uint(2);
            uint _15180 = _15176 & 3u;
            uint _15184 = _3167._m0[_15178][_15180] & 65535u;
            uint _15186 = _3167._m0[_15178][_15180] >> uint(16);
            float3 _21663;
            _21663 = _21664;
            float3 _4412;
            spvUnsafeArray<float2, 3> _15594;
            spvUnsafeArray<float2, 3> _15595;
            spvUnsafeArray<float2, 3> _15807;
            spvUnsafeArray<float2, 3> _15808;
            for (uint _21529 = _15184; _21529 < (_15184 + _15186); _21663 = _4412, _21529++)
            {
                uint _15192 = _21529 / 3u;
                uint _15205 = (_3188._m0[_15192 >> uint(2)][_15192 & 3u] >> ((_21529 - (_15192 * 3u)) * 10u)) & 1023u;
                float3 _15222 = _3030._m0[_15205].xyz - in.m_3037;
                float _15225 = dot(_15222, _15222);
                float _15229 = _15225 * _3030._m0[_15205].w;
                float _15234 = fast::clamp(1.0 - (_15229 * _15229), 0.0, 1.0);
                float3 _15239 = _15222 * rsqrt(fast::max(_15225, 9.9999999392252902907785028219223e-09));
                float _15257 = fast::clamp((dot(-_15239, _3073._m0[_15205].xyz) * _3065._m0[_15205].w) + _3073._m0[_15205].w, 0.0, 1.0);
                float3 _15270 = _3065._m0[_15205].xyz * ((((_15234 * _15234) * _15257) * _15257) / fast::max(_15225, 9.9999997473787516355514526367188e-05));
                float3 _21661;
                if (_3682)
                {
                    float _21556;
                    do
                    {
                        uint _15306 = uint(_283._m21.z);
                        if (_15205 < _15306)
                        {
                            float _15328 = _283._m26[_15205].z * fast::max((_283._m15[_15205] * float4(in.m_3037, 1.0)).w, 0.0);
                            float4 _15352 = _283._m15[_15205] * float4((in.m_3037 + (_3677 * (_15328 * _283._m25.x))) + (_15239 * (_15328 * _283._m25.y)), 1.0);
                            float _15354 = _15352.w;
                            if (_15354 <= 0.0)
                            {
                                _21556 = 1.0;
                                break;
                            }
                            float3 _15363 = _15352.xyz / float3(_15354);
                            float _15365 = _15363.x;
                            bool _15366 = _15365 < 0.0;
                            bool _15373;
                            if (!_15366)
                            {
                                _15373 = _15365 > 1.0;
                            }
                            else
                            {
                                _15373 = _15366;
                            }
                            bool _15380;
                            if (!_15373)
                            {
                                _15380 = _15363.y < 0.0;
                            }
                            else
                            {
                                _15380 = _15373;
                            }
                            bool _15387;
                            if (!_15380)
                            {
                                _15387 = _15363.y > 1.0;
                            }
                            else
                            {
                                _15387 = _15380;
                            }
                            bool _15394;
                            if (!_15387)
                            {
                                _15394 = _15363.z > 1.0;
                            }
                            else
                            {
                                _15394 = _15387;
                            }
                            if (_15394)
                            {
                                _21556 = 1.0;
                                break;
                            }
                            float _15400 = _15363.z;
                            float2 _15566 = _283._m22.xy * 0.5;
                            float2 _15571 = _283._m26[_15205].xy + (_15363.xy * _283._m23.zw);
                            float4 _15584 = float4(_283._m26[_15205].xy + _15566, (_283._m26[_15205].xy + _283._m23.zw) - _15566);
                            float _21555;
                            do
                            {
                                int _15610 = int(_283._m22.z);
                                if (_15610 <= 0)
                                {
                                    float2 _15620 = fast::clamp(_15571, _15584.xy, _15584.zw);
                                    _21555 = spvDepthCast(_303).sample_compare(_303Smplr, float3(_15620, _15400).xy, _15400);
                                    break;
                                }
                                float2 _15633 = (_15571 / _283._m22.xy) + float2(0.5);
                                float2 _15634 = floor(_15633);
                                float2 _15639 = _15633 - _15634;
                                float2 _15642 = _15634 - float2(0.5);
                                bool _15646 = _15610 == 1;
                                if (_15646)
                                {
                                    float2 _15649 = _15639 * 2.0;
                                    _15594[0] = float2(3.0) - _15649;
                                    _15594[1] = float2(1.0) + _15649;
                                    _15595[0] = ((float2(2.0) - _15639) / _15594[0]) - float2(1.0);
                                    _15595[1] = (_15639 / _15594[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _15676 = _15639 * 3.0;
                                    _15594[0] = float2(4.0) - _15676;
                                    _15594[1] = float2(7.0);
                                    _15594[2] = float2(1.0) + _15676;
                                    _15595[0] = ((float2(3.0) - (_15639 * 2.0)) / _15594[0]) - float2(2.0);
                                    _15595[1] = (float2(3.0) + _15639) / _15594[1];
                                    _15595[2] = (_15639 / _15594[2]) + float2(2.0);
                                }
                                int _22297 = _15646 ? 2 : 3;
                                int _21545;
                                float _21548;
                                _21548 = 0.0;
                                _21545 = 0;
                                float _21554;
                                for (; _21545 < _22297; _21548 = _21554, _21545++)
                                {
                                    _21554 = _21548;
                                    for (int _21551 = 0; _21551 < _22297; )
                                    {
                                        _21554 += ((_15594[_21551].x * _15594[_21545].y) * spvDepthCast(_303).sample_compare(_303Smplr, float3(fast::clamp(_283._m22.xy * (_15642 + float2(_15595[_21551].x, _15595[_21545].y)), _15584.xy, _15584.zw), _15400).xy, _15400));
                                        _21551++;
                                        continue;
                                    }
                                }
                                _21555 = _21548 * (_15646 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _21556 = _21555;
                            break;
                        }
                        uint _15410 = _15205 - _15306;
                        if (_15410 >= uint(_283._m21.w))
                        {
                            _21556 = 1.0;
                            break;
                        }
                        float _15431 = _283._m27[_15410].w * length(in.m_3037 - _283._m27[_15410].xyz);
                        float3 _15449 = ((in.m_3037 + (_3677 * (_15431 * _283._m25.x))) + (_15239 * (_15431 * _283._m25.y))) - _283._m27[_15410].xyz;
                        float3 _15451 = abs(_15449);
                        float _15453 = _15451.x;
                        float _15455 = _15451.y;
                        bool _15456 = _15453 >= _15455;
                        bool _15464;
                        if (_15456)
                        {
                            _15464 = _15453 >= _15451.z;
                        }
                        else
                        {
                            _15464 = _15456;
                        }
                        float _21530;
                        int _21532;
                        if (_15464)
                        {
                            _21532 = (_15449.x > 0.0) ? 0 : 1;
                            _21530 = _15453;
                        }
                        else
                        {
                            float _15476 = _15451.z;
                            bool _15477 = _15455 >= _15476;
                            int _21533;
                            if (_15477)
                            {
                                _21533 = (_15449.y > 0.0) ? 2 : 3;
                            }
                            else
                            {
                                _21533 = (_15449.z > 0.0) ? 4 : 5;
                            }
                            _21532 = _21533;
                            _21530 = _15477 ? _15455 : _15476;
                        }
                        if (_21530 <= 0.0)
                        {
                            _21556 = 1.0;
                            break;
                        }
                        float2 _15514 = float2(dot(_15449, _961[_21532]), dot(_15449, _970[_21532])) / float2(_21530 * _283._m24.z);
                        float _15521 = _283._m28[_15410].z + (_283._m28[_15410].w / _21530);
                        if (_15521 > 1.0)
                        {
                            _21556 = 1.0;
                            break;
                        }
                        float2 _15539 = _283._m28[_15410].xy + (float2(float(spvSMod(_21532, 3)), float(_21532 / 3)) * _283._m24.xy);
                        float2 _15779 = _283._m22.xy * 0.5;
                        float2 _15784 = _15539 + (float2(0.5 + (0.5 * _15514.x), 0.5 - (0.5 * _15514.y)) * _283._m24.xy);
                        float4 _15797 = float4(_15539 + _15779, (_15539 + _283._m24.xy) - _15779);
                        float _21544;
                        do
                        {
                            int _15823 = int(_283._m22.z);
                            if (_15823 <= 0)
                            {
                                _21544 = spvDepthCast(_303).sample_compare(_303Smplr, float3(fast::clamp(_15784, _15797.xy, _15797.zw), _15521).xy, _15521);
                                break;
                            }
                            float2 _15846 = (_15784 / _283._m22.xy) + float2(0.5);
                            float2 _15847 = floor(_15846);
                            float2 _15852 = _15846 - _15847;
                            float2 _15855 = _15847 - float2(0.5);
                            bool _15859 = _15823 == 1;
                            if (_15859)
                            {
                                float2 _15862 = _15852 * 2.0;
                                _15807[0] = float2(3.0) - _15862;
                                _15807[1] = float2(1.0) + _15862;
                                _15808[0] = ((float2(2.0) - _15852) / _15807[0]) - float2(1.0);
                                _15808[1] = (_15852 / _15807[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _15889 = _15852 * 3.0;
                                _15807[0] = float2(4.0) - _15889;
                                _15807[1] = float2(7.0);
                                _15807[2] = float2(1.0) + _15889;
                                _15808[0] = ((float2(3.0) - (_15852 * 2.0)) / _15807[0]) - float2(2.0);
                                _15808[1] = (float2(3.0) + _15852) / _15807[1];
                                _15808[2] = (_15852 / _15807[2]) + float2(2.0);
                            }
                            int _22300 = _15859 ? 2 : 3;
                            int _21534;
                            float _21537;
                            _21537 = 0.0;
                            _21534 = 0;
                            float _21543;
                            for (; _21534 < _22300; _21537 = _21543, _21534++)
                            {
                                _21543 = _21537;
                                for (int _21540 = 0; _21540 < _22300; )
                                {
                                    _21543 += ((_15807[_21540].x * _15807[_21534].y) * spvDepthCast(_303).sample_compare(_303Smplr, float3(fast::clamp(_283._m22.xy * (_15855 + float2(_15808[_21540].x, _15808[_21534].y)), _15797.xy, _15797.zw), _15521).xy, _15521));
                                    _21540++;
                                    continue;
                                }
                            }
                            _21544 = _21537 * (_15859 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _21556 = _21544;
                        break;
                    } while(false);
                    _21661 = _15270 * _21556;
                }
                else
                {
                    _21661 = _15270;
                }
                float3 _4364 = fast::normalize(_15239 + _3666);
                float _4369 = fast::clamp(dot(_21053, _15239), 0.0, 1.0);
                float _4374 = fast::clamp(dot(_21053, _4364), 0.0, 1.0);
                float3 _15994 = _3977 + (_10014 * powr(1.0 - fast::clamp(dot(_3666, _4364), 0.0, 1.0), 5.0));
                float _16008 = ((_4374 * _4374) * _10029) + 1.0;
                _4412 = _21663 + (((((float3(1.0) - _15994) * _3971) + ((_15994 * ((_10024 / ((3.1415927410125732421875 * _16008) * _16008)) * (0.5 / fast::max((_4369 * _10055) + (_21081 * sqrt(((_4369 * _4369) * _10051) + _10024)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875)) * _4369) * _21661);
            }
            _21734 = _21663;
        }
        else
        {
            _21734 = _21664;
        }
        _21730 = _21734;
    }
    float4 _4429 = _4424.sample(_2533, _3419);
    float _4450 = -length(_3665);
    float _21816;
    if (_283._m9.w != 0.0)
    {
        float _4474 = _283._m9.w * (in.m_3037 - _283._m6.xyz).y;
        float _21813;
        if (abs(_4474) < 9.9999997473787516355514526367188e-05)
        {
            _21813 = 1.0 - (0.5 * _4474);
        }
        else
        {
            _21813 = (1.0 - exp(fast::min(-_4474, 60.0))) / _4474;
        }
        _21816 = 1.0 - exp((_4450 * (_283._m7.w * exp(fast::min((-_283._m9.w) * (_283._m6.y - _283._m6.w), 30.0)))) * _21813);
    }
    else
    {
        _21816 = 1.0 - exp(_4450 * _283._m7.w);
    }
    float3 _21863;
    if (_283._m34.z > 0.5)
    {
        float3 _21827;
        if (_283._m29.x > 0.5)
        {
            float _16107 = (_283._m29.z * _21053.x) - (_283._m29.w * _21053.z);
            float _16120 = (_283._m29.w * _21053.x) + (_283._m29.z * _21053.z);
            float _16138 = 1.09254801273345947265625 * _16107;
            spvUnsafeArray<float, 9> _19123 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _21053.y, 0.48860299587249755859375 * _16120, 0.48860299587249755859375 * _16107, _16138 * _21053.y, (1.09254801273345947265625 * _21053.y) * _16120, 0.3153919875621795654296875 * (((3.0 * _16120) * _16120) - 1.0), _16138 * _16120, 0.546274006366729736328125 * ((_16107 * _16107) - (_21053.y * _21053.y)) });
            spvUnsafeArray<float, 9> _16052 = _19123;
            float3 _21826;
            _21826 = float3(0.0);
            for (int _21825 = 0; _21825 < 9; )
            {
                _21826 += (_2531.read(uint2((int2(496, 256) + int2(_21825, 0))), 0).xyz * _16052[_21825]);
                _21825++;
                continue;
            }
            _21827 = fast::max(_21826, float3(0.0)) * _283._m29.y;
        }
        else
        {
            _21827 = mix(_283._m9.xyz, _283._m8.xyz, float3((_21053.y * 0.5) + 0.5)) * _283._m8.w;
        }
        float3 _21832;
        if (_283._m34.y > 0.5)
        {
            int _16315 = int(_283._m34.y);
            int _16318 = int(_283._m34.x);
            float3 _21831;
            _21831 = _21827;
            float3 _22160;
            for (int _21830 = 0; _21830 < _16315; _21831 = _22160, _21830++)
            {
                int _16330 = 8 * (_16318 + _21830);
                float4 _16539 = as_type<float4>(_1281._m0[_16330 + 3]);
                float4 _16583 = as_type<float4>(_1281._m0[_16330]);
                float4 _16589 = as_type<float4>(_1281._m0[_16330 + 1]);
                float4 _16595 = as_type<float4>(_1281._m0[_16330 + 2]);
                float3 _16557 = _16583.xyz;
                float _16561 = _16583.w;
                float3 _16564 = _16589.xyz;
                float _16568 = _16589.w;
                float3 _16571 = _16595.xyz;
                float _16575 = _16595.w;
                float3 _16577 = float3(dot(_16557, in.m_3037) + _16561, dot(_16564, in.m_3037) + _16568, dot(_16571, in.m_3037) + _16575);
                float3 _16339 = _16539.xyz;
                float _16341 = _16539.w;
                float _21992;
                do
                {
                    float3 _16607 = _16339 - abs(_16577);
                    float _16615 = fast::min(_16607.x, fast::min(_16607.y, _16607.z));
                    if (_16615 <= 0.0)
                    {
                        _21992 = 0.0;
                        break;
                    }
                    if (_16341 <= 0.0)
                    {
                        _21992 = 1.0;
                        break;
                    }
                    float _16627 = fast::min(_16615 / _16341, 1.0);
                    _21992 = (_16627 * _16627) * (3.0 - (2.0 * _16627));
                    break;
                } while(false);
                if (_21992 <= 0.0)
                {
                    _22160 = _21831;
                    continue;
                }
                float3 _16350 = as_type<float4>(_1281._m0[_16330 + 4]).xyz;
                float4 _16648 = as_type<float4>(_1281._m0[_16330 + 5]);
                int _16654 = int(((device uint*)&_1281._m0[_16330 + 6])[0u]);
                float _16664 = dot(_16557, _21053);
                float _16670 = dot(_16564, _21053);
                float _16676 = dot(_16571, _21053);
                float3 _16677 = float3(_16664, _16670, _16676);
                float3 _16370 = (in.m_3037 + (_21053 * _16648.x)) + (_3666 * _16648.y);
                float3 _16389 = fast::clamp((((float3(dot(_16557, _16370) + _16561, dot(_16564, _16370) + _16568, dot(_16571, _16370) + _16575) + _16339) / fast::max(_16339 * 2.0, float3(9.9999999747524270787835121154785e-07))) * _16350) - float3(0.5), float3(0.0), _16350 - float3(1.0));
                int3 _16391 = int3(_16350);
                int3 _16398 = min(int3(_16389), max((_16391 - int3(2)), int3(0)));
                float3 _16402 = _16389 - float3(_16398);
                float _16757 = 0.48860299587249755859375 * _16670;
                float _16760 = 0.48860299587249755859375 * _16676;
                float _16763 = 0.48860299587249755859375 * _16664;
                float _16768 = 1.09254801273345947265625 * _16664;
                float _16771 = _16768 * _16670;
                float _16777 = (1.09254801273345947265625 * _16670) * _16676;
                float _16785 = 0.3153919875621795654296875 * (((3.0 * _16676) * _16676) - 1.0);
                float _16791 = _16768 * _16676;
                float _16805 = 0.546274006366729736328125 * ((_16664 * _16664) - (_16670 * _16670));
                int3 _16824 = _16391 - int3(1);
                int3 _16825 = min(_16398, _16824);
                int _16830 = _16391.x;
                int _16834 = _16391.y;
                int _16842 = _16654 + ((_16825.x + (_16830 * (_16825.y + (_16834 * _16825.z)))) * 4);
                float3 _16845 = float3(1.0) - _16402;
                float3 _16863 = (((((float3(_16825) + float3(0.5)) / _16350) * _16339) * 2.0) - _16339) - _16577;
                float _16873 = dot(_16863 * rsqrt(fast::max(dot(_16863, _16863), 1.0000000133514319600180897396058e-10)), _16677) + 1.0;
                float _16876 = _16845.x;
                float _16878 = _16845.y;
                float _16879 = _16876 * _16878;
                float _16881 = _16845.z;
                int _16905 = _16842 + 3;
                float _16891 = ((_16879 * _16881) * ((0.25 * (_16873 * _16873)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_16905])[1u])).y > 0.5);
                int _16935 = _16842 + 1;
                int _16939 = _16842 + 2;
                float2 _16951 = float2(as_type<half2>(_1281._m0[_16842].y));
                float2 _16960 = float2(as_type<half2>(_1281._m0[_16935].x));
                float2 _16969 = float2(as_type<half2>(_1281._m0[_16935].w));
                float2 _16978 = float2(as_type<half2>(_1281._m0[_16939].z));
                float3 _17066 = (((((((float3(float2(as_type<half2>(_1281._m0[_16842].x)), _16951.x) * 0.2820949852466583251953125) + (float3(_16951.y, float2(as_type<half2>(_1281._m0[_16842].z))) * _16757)) + (float3(float2(as_type<half2>(_1281._m0[_16842].w)), _16960.x) * _16760)) + (float3(_16960.y, float2(as_type<half2>(_1281._m0[_16935].y))) * _16763)) + (float3(float2(as_type<half2>(_1281._m0[_16935].z)), _16969.x) * _16771)) + (float3(_16969.y, float2(as_type<half2>(_1281._m0[_16939].x))) * _16777)) + (float3(float2(as_type<half2>(_1281._m0[_16939].y)), _16978.x) * _16785)) + (float3(_16978.y, float2(as_type<half2>(_1281._m0[_16939].w))) * _16791);
                int3 _17094 = min((_16398 + int3(1, 0, 0)), _16824);
                int _17111 = _16654 + ((_17094.x + (_16830 * (_17094.y + (_16834 * _17094.z)))) * 4);
                float3 _17132 = (((((float3(_17094) + float3(0.5)) / _16350) * _16339) * 2.0) - _16339) - _16577;
                float _17142 = dot(_17132 * rsqrt(fast::max(dot(_17132, _17132), 1.0000000133514319600180897396058e-10)), _16677) + 1.0;
                float _17148 = _16402.x * _16878;
                int _17174 = _17111 + 3;
                float _17160 = ((_17148 * _16881) * ((0.25 * (_17142 * _17142)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_17174])[1u])).y > 0.5);
                int _17204 = _17111 + 1;
                int _17208 = _17111 + 2;
                float2 _17220 = float2(as_type<half2>(_1281._m0[_17111].y));
                float2 _17229 = float2(as_type<half2>(_1281._m0[_17204].x));
                float2 _17238 = float2(as_type<half2>(_1281._m0[_17204].w));
                float2 _17247 = float2(as_type<half2>(_1281._m0[_17208].z));
                float3 _17335 = (((((((float3(float2(as_type<half2>(_1281._m0[_17111].x)), _17220.x) * 0.2820949852466583251953125) + (float3(_17220.y, float2(as_type<half2>(_1281._m0[_17111].z))) * _16757)) + (float3(float2(as_type<half2>(_1281._m0[_17111].w)), _17229.x) * _16760)) + (float3(_17229.y, float2(as_type<half2>(_1281._m0[_17204].y))) * _16763)) + (float3(float2(as_type<half2>(_1281._m0[_17204].z)), _17238.x) * _16771)) + (float3(_17238.y, float2(as_type<half2>(_1281._m0[_17208].x))) * _16777)) + (float3(float2(as_type<half2>(_1281._m0[_17208].y)), _17247.x) * _16785)) + (float3(_17247.y, float2(as_type<half2>(_1281._m0[_17208].w))) * _16791);
                int3 _17363 = min((_16398 + int3(0, 1, 0)), _16824);
                int _17380 = _16654 + ((_17363.x + (_16830 * (_17363.y + (_16834 * _17363.z)))) * 4);
                float3 _17401 = (((((float3(_17363) + float3(0.5)) / _16350) * _16339) * 2.0) - _16339) - _16577;
                float _17411 = dot(_17401 * rsqrt(fast::max(dot(_17401, _17401), 1.0000000133514319600180897396058e-10)), _16677) + 1.0;
                float _17417 = _16876 * _16402.y;
                int _17443 = _17380 + 3;
                float _17429 = ((_17417 * _16881) * ((0.25 * (_17411 * _17411)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_17443])[1u])).y > 0.5);
                int _17473 = _17380 + 1;
                int _17477 = _17380 + 2;
                float2 _17489 = float2(as_type<half2>(_1281._m0[_17380].y));
                float2 _17498 = float2(as_type<half2>(_1281._m0[_17473].x));
                float2 _17507 = float2(as_type<half2>(_1281._m0[_17473].w));
                float2 _17516 = float2(as_type<half2>(_1281._m0[_17477].z));
                float3 _17604 = (((((((float3(float2(as_type<half2>(_1281._m0[_17380].x)), _17489.x) * 0.2820949852466583251953125) + (float3(_17489.y, float2(as_type<half2>(_1281._m0[_17380].z))) * _16757)) + (float3(float2(as_type<half2>(_1281._m0[_17380].w)), _17498.x) * _16760)) + (float3(_17498.y, float2(as_type<half2>(_1281._m0[_17473].y))) * _16763)) + (float3(float2(as_type<half2>(_1281._m0[_17473].z)), _17507.x) * _16771)) + (float3(_17507.y, float2(as_type<half2>(_1281._m0[_17477].x))) * _16777)) + (float3(float2(as_type<half2>(_1281._m0[_17477].y)), _17516.x) * _16785)) + (float3(_17516.y, float2(as_type<half2>(_1281._m0[_17477].w))) * _16791);
                int3 _17632 = min((_16398 + int3(1, 1, 0)), _16824);
                int _17649 = _16654 + ((_17632.x + (_16830 * (_17632.y + (_16834 * _17632.z)))) * 4);
                float3 _17670 = (((((float3(_17632) + float3(0.5)) / _16350) * _16339) * 2.0) - _16339) - _16577;
                float _17680 = dot(_17670 * rsqrt(fast::max(dot(_17670, _17670), 1.0000000133514319600180897396058e-10)), _16677) + 1.0;
                float _17686 = _16402.x * _16402.y;
                int _17712 = _17649 + 3;
                float _17698 = ((_17686 * _16881) * ((0.25 * (_17680 * _17680)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_17712])[1u])).y > 0.5);
                int _17742 = _17649 + 1;
                int _17746 = _17649 + 2;
                float2 _17758 = float2(as_type<half2>(_1281._m0[_17649].y));
                float2 _17767 = float2(as_type<half2>(_1281._m0[_17742].x));
                float2 _17776 = float2(as_type<half2>(_1281._m0[_17742].w));
                float2 _17785 = float2(as_type<half2>(_1281._m0[_17746].z));
                float3 _17873 = (((((((float3(float2(as_type<half2>(_1281._m0[_17649].x)), _17758.x) * 0.2820949852466583251953125) + (float3(_17758.y, float2(as_type<half2>(_1281._m0[_17649].z))) * _16757)) + (float3(float2(as_type<half2>(_1281._m0[_17649].w)), _17767.x) * _16760)) + (float3(_17767.y, float2(as_type<half2>(_1281._m0[_17742].y))) * _16763)) + (float3(float2(as_type<half2>(_1281._m0[_17742].z)), _17776.x) * _16771)) + (float3(_17776.y, float2(as_type<half2>(_1281._m0[_17746].x))) * _16777)) + (float3(float2(as_type<half2>(_1281._m0[_17746].y)), _17785.x) * _16785)) + (float3(_17785.y, float2(as_type<half2>(_1281._m0[_17746].w))) * _16791);
                int3 _17901 = min((_16398 + int3(0, 0, 1)), _16824);
                int _17918 = _16654 + ((_17901.x + (_16830 * (_17901.y + (_16834 * _17901.z)))) * 4);
                float3 _17939 = (((((float3(_17901) + float3(0.5)) / _16350) * _16339) * 2.0) - _16339) - _16577;
                float _17949 = dot(_17939 * rsqrt(fast::max(dot(_17939, _17939), 1.0000000133514319600180897396058e-10)), _16677) + 1.0;
                int _17981 = _17918 + 3;
                float _17967 = ((_16879 * _16402.z) * ((0.25 * (_17949 * _17949)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_17981])[1u])).y > 0.5);
                int _18011 = _17918 + 1;
                int _18015 = _17918 + 2;
                float2 _18027 = float2(as_type<half2>(_1281._m0[_17918].y));
                float2 _18036 = float2(as_type<half2>(_1281._m0[_18011].x));
                float2 _18045 = float2(as_type<half2>(_1281._m0[_18011].w));
                float2 _18054 = float2(as_type<half2>(_1281._m0[_18015].z));
                float3 _18142 = (((((((float3(float2(as_type<half2>(_1281._m0[_17918].x)), _18027.x) * 0.2820949852466583251953125) + (float3(_18027.y, float2(as_type<half2>(_1281._m0[_17918].z))) * _16757)) + (float3(float2(as_type<half2>(_1281._m0[_17918].w)), _18036.x) * _16760)) + (float3(_18036.y, float2(as_type<half2>(_1281._m0[_18011].y))) * _16763)) + (float3(float2(as_type<half2>(_1281._m0[_18011].z)), _18045.x) * _16771)) + (float3(_18045.y, float2(as_type<half2>(_1281._m0[_18015].x))) * _16777)) + (float3(float2(as_type<half2>(_1281._m0[_18015].y)), _18054.x) * _16785)) + (float3(_18054.y, float2(as_type<half2>(_1281._m0[_18015].w))) * _16791);
                float4 _16469 = (((float4((_17066 + (float3(float2(as_type<half2>(_1281._m0[_16905].x)), float2(as_type<half2>(_1281._m0[_16905].y)).x) * _16805)) * _16891, _16891) + float4((_17335 + (float3(float2(as_type<half2>(_1281._m0[_17174].x)), float2(as_type<half2>(_1281._m0[_17174].y)).x) * _16805)) * _17160, _17160)) + float4((_17604 + (float3(float2(as_type<half2>(_1281._m0[_17443].x)), float2(as_type<half2>(_1281._m0[_17443].y)).x) * _16805)) * _17429, _17429)) + float4((_17873 + (float3(float2(as_type<half2>(_1281._m0[_17712].x)), float2(as_type<half2>(_1281._m0[_17712].y)).x) * _16805)) * _17698, _17698)) + float4((_18142 + (float3(float2(as_type<half2>(_1281._m0[_17981].x)), float2(as_type<half2>(_1281._m0[_17981].y)).x) * _16805)) * _17967, _17967);
                int3 _18170 = min((_16398 + int3(1, 0, 1)), _16824);
                int _18187 = _16654 + ((_18170.x + (_16830 * (_18170.y + (_16834 * _18170.z)))) * 4);
                float3 _18208 = (((((float3(_18170) + float3(0.5)) / _16350) * _16339) * 2.0) - _16339) - _16577;
                float _18218 = dot(_18208 * rsqrt(fast::max(dot(_18208, _18208), 1.0000000133514319600180897396058e-10)), _16677) + 1.0;
                int _18250 = _18187 + 3;
                float _18236 = ((_17148 * _16402.z) * ((0.25 * (_18218 * _18218)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_18250])[1u])).y > 0.5);
                int _18280 = _18187 + 1;
                int _18284 = _18187 + 2;
                float2 _18296 = float2(as_type<half2>(_1281._m0[_18187].y));
                float2 _18305 = float2(as_type<half2>(_1281._m0[_18280].x));
                float2 _18314 = float2(as_type<half2>(_1281._m0[_18280].w));
                float2 _18323 = float2(as_type<half2>(_1281._m0[_18284].z));
                float3 _18411 = (((((((float3(float2(as_type<half2>(_1281._m0[_18187].x)), _18296.x) * 0.2820949852466583251953125) + (float3(_18296.y, float2(as_type<half2>(_1281._m0[_18187].z))) * _16757)) + (float3(float2(as_type<half2>(_1281._m0[_18187].w)), _18305.x) * _16760)) + (float3(_18305.y, float2(as_type<half2>(_1281._m0[_18280].y))) * _16763)) + (float3(float2(as_type<half2>(_1281._m0[_18280].z)), _18314.x) * _16771)) + (float3(_18314.y, float2(as_type<half2>(_1281._m0[_18284].x))) * _16777)) + (float3(float2(as_type<half2>(_1281._m0[_18284].y)), _18323.x) * _16785)) + (float3(_18323.y, float2(as_type<half2>(_1281._m0[_18284].w))) * _16791);
                int3 _18439 = min((_16398 + int3(0, 1, 1)), _16824);
                int _18456 = _16654 + ((_18439.x + (_16830 * (_18439.y + (_16834 * _18439.z)))) * 4);
                float3 _18477 = (((((float3(_18439) + float3(0.5)) / _16350) * _16339) * 2.0) - _16339) - _16577;
                float _18487 = dot(_18477 * rsqrt(fast::max(dot(_18477, _18477), 1.0000000133514319600180897396058e-10)), _16677) + 1.0;
                int _18519 = _18456 + 3;
                float _18505 = ((_17417 * _16402.z) * ((0.25 * (_18487 * _18487)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_18519])[1u])).y > 0.5);
                int _18549 = _18456 + 1;
                int _18553 = _18456 + 2;
                float2 _18565 = float2(as_type<half2>(_1281._m0[_18456].y));
                float2 _18574 = float2(as_type<half2>(_1281._m0[_18549].x));
                float2 _18583 = float2(as_type<half2>(_1281._m0[_18549].w));
                float2 _18592 = float2(as_type<half2>(_1281._m0[_18553].z));
                float3 _18680 = (((((((float3(float2(as_type<half2>(_1281._m0[_18456].x)), _18565.x) * 0.2820949852466583251953125) + (float3(_18565.y, float2(as_type<half2>(_1281._m0[_18456].z))) * _16757)) + (float3(float2(as_type<half2>(_1281._m0[_18456].w)), _18574.x) * _16760)) + (float3(_18574.y, float2(as_type<half2>(_1281._m0[_18549].y))) * _16763)) + (float3(float2(as_type<half2>(_1281._m0[_18549].z)), _18583.x) * _16771)) + (float3(_18583.y, float2(as_type<half2>(_1281._m0[_18553].x))) * _16777)) + (float3(float2(as_type<half2>(_1281._m0[_18553].y)), _18592.x) * _16785)) + (float3(_18592.y, float2(as_type<half2>(_1281._m0[_18553].w))) * _16791);
                int3 _18708 = min((_16398 + int3(1)), _16824);
                int _18725 = _16654 + ((_18708.x + (_16830 * (_18708.y + (_16834 * _18708.z)))) * 4);
                float3 _18746 = (((((float3(_18708) + float3(0.5)) / _16350) * _16339) * 2.0) - _16339) - _16577;
                float _18756 = dot(_18746 * rsqrt(fast::max(dot(_18746, _18746), 1.0000000133514319600180897396058e-10)), _16677) + 1.0;
                int _18788 = _18725 + 3;
                float _18774 = ((_17686 * _16402.z) * ((0.25 * (_18756 * _18756)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_18788])[1u])).y > 0.5);
                int _18818 = _18725 + 1;
                int _18822 = _18725 + 2;
                float2 _18834 = float2(as_type<half2>(_1281._m0[_18725].y));
                float2 _18843 = float2(as_type<half2>(_1281._m0[_18818].x));
                float2 _18852 = float2(as_type<half2>(_1281._m0[_18818].w));
                float2 _18861 = float2(as_type<half2>(_1281._m0[_18822].z));
                float3 _18949 = (((((((float3(float2(as_type<half2>(_1281._m0[_18725].x)), _18834.x) * 0.2820949852466583251953125) + (float3(_18834.y, float2(as_type<half2>(_1281._m0[_18725].z))) * _16757)) + (float3(float2(as_type<half2>(_1281._m0[_18725].w)), _18843.x) * _16760)) + (float3(_18843.y, float2(as_type<half2>(_1281._m0[_18818].y))) * _16763)) + (float3(float2(as_type<half2>(_1281._m0[_18818].z)), _18852.x) * _16771)) + (float3(_18852.y, float2(as_type<half2>(_1281._m0[_18822].x))) * _16777)) + (float3(float2(as_type<half2>(_1281._m0[_18822].y)), _18861.x) * _16785)) + (float3(_18861.y, float2(as_type<half2>(_1281._m0[_18822].w))) * _16791);
                float4 _16508 = ((_16469 + float4((_18411 + (float3(float2(as_type<half2>(_1281._m0[_18250].x)), float2(as_type<half2>(_1281._m0[_18250].y)).x) * _16805)) * _18236, _18236)) + float4((_18680 + (float3(float2(as_type<half2>(_1281._m0[_18519].x)), float2(as_type<half2>(_1281._m0[_18519].y)).x) * _16805)) * _18505, _18505)) + float4((_18949 + (float3(float2(as_type<half2>(_1281._m0[_18788].x)), float2(as_type<half2>(_1281._m0[_18788].y)).x) * _16805)) * _18774, _18774);
                float _16512 = _16508.w;
                float3 _22161;
                if (_16512 > 9.9999997473787516355514526367188e-06)
                {
                    _22161 = mix(_21831, (fast::max(_16508.xyz, float3(0.0)) / float3(_16512)) * _16648.z, float3(_21992));
                }
                else
                {
                    _22161 = _21831;
                }
                _22160 = _22161;
            }
            _21832 = _21831;
        }
        else
        {
            _21832 = _21827;
        }
        _21863 = _21832 * _21177;
    }
    else
    {
        _21863 = mix(mix(_21730, _21047, float3(_2876._m1.y)) + (((_2876._m5.xyz * _4429.xyz) * (float3(1.0) + in.m_3679.yzw)) * in.m_3932.z), _283._m7.xyz, float3(_21816));
    }
    float3 _21864;
    if (_283._m33.w > 0.5)
    {
        _21864 = _21863 / (float3(1.0) + _21863);
    }
    else
    {
        _21864 = _21863;
    }
    out.m_4574 = float4(_21864, in.m_3428.w * in.m_3461.w);
    float2 _21991;
    do
    {
        if (in.m_4584.w <= 0.0)
        {
            _21991 = float2(0.0);
            break;
        }
        _21991 = ((in.m_4584.xy / float2(in.m_4584.w)) - (in.m_4583.xy / float2(in.m_4583.w))) * float2(0.5, -0.5);
        break;
    } while(false);
    out.m_4582 = _21991;
    return out;
}

