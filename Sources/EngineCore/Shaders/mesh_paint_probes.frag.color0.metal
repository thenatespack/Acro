// Generated from mesh_paint_probes.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: c087786f762a3e54
// glsl-fnv1a64: 811456345029bd61

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
    float4 m_4561 [[color(0)]];
};

struct fragment_main_in
{
    float3 m_3037 [[user(locn0)]];
    float3 m_2946 [[user(locn1)]];
    float2 m_3405 [[user(locn2)]];
    float4 m_3428 [[user(locn3)]];
    float3 m_2980 [[user(locn4)]];
    float4 m_3666 [[user(locn5)]];
    float4 m_4570 [[user(locn6)]];
    float4 m_4571 [[user(locn7)]];
    float4 m_2952 [[user(locn8)]];
    float4 m_3448 [[user(locn9)]];
    float4 m_3919 [[user(locn10)]];
};

fragment fragment_main_out fragment_main(fragment_main_in in [[stage_in]], constant _2874& _2876 [[buffer(2)]], constant _3028& _3030 [[buffer(3)]], constant _3063& _3065 [[buffer(4)]], constant _3071& _3073 [[buffer(5)]], constant _3165& _3167 [[buffer(6)]], constant _3186& _3188 [[buffer(7)]], constant _281& _283 [[buffer(15)]], const device _1279& _1281 [[buffer(21)]], texture2d<float> _303 [[texture(0)]], texture2d<float> _3421 [[texture(1)]], texture2d<float> _3907 [[texture(2)]], texture2d<float> _3543 [[texture(3)]], texture2d<float> _3352 [[texture(4)]], texture2d<float> _4411 [[texture(5)]], texture2d<float> _2531 [[texture(6)]], texture2d<float> _2632 [[texture(7)]], sampler _303Smplr [[sampler(0)]], sampler _2533 [[sampler(1)]], sampler _2634 [[sampler(7)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])
{
    float2 _4569;
    fragment_main_out out = {};
    float2 _3419 = float2(dot(_2876._m2.xy, in.m_3405) + _2876._m2.z, dot(_2876._m3.xy, in.m_3405) + _2876._m3.z);
    float4 _3426 = _3421.sample(_2533, _3419);
    float3 _3436 = _3426.xyz;
    float3 _3452 = ((in.m_3428.xyz * _2876._m0.xyz) * _3436) * in.m_3448.xyz;
    float3 _20842;
    if (_2876._m1.x > 0.5)
    {
        float2 _3467 = floor(in.m_3037.xz * float2(0.5));
        _20842 = _3452 * ((mod(abs(_3467.x + _3467.y), 2.0) < 0.5) ? 1.0 : 0.75);
    }
    else
    {
        _20842 = _3452;
    }
    float3 _20939;
    float _20970;
    float2 _21003;
    if (_2876._m3.w > 0.5)
    {
        float3 _4677;
        float2 _4684;
        float _20840;
        do
        {
            float3 _4648 = float4(_2876._m2.w, _2876._m3.w, 0.0, 0.0).xyy;
            float3 _4651 = floor(_4648 * float3(1.52587890625e-05));
            float3 _4656 = _4648 - (_4651 * 65536.0);
            float3 _4659 = floor(_4656 * float3(0.00390625));
            float3 _4667 = _4656 - (_4659 * 256.0);
            _4677 = (float3(_4667.x, _4659.x, _4651.x) * float3(0.0039215688593685626983642578125)) * 2.0;
            _4684 = float2(_4667.y, _4659.y) * float2(0.0039215688593685626983642578125);
            float _4687 = _4651.y - 128.0;
            float _4693 = floor(_4687 * 0.03125) * 0.3333333432674407958984375;
            float3 _4699 = fast::normalize(in.m_2946);
            float _4703 = dot(_4699, in.m_2952.xyz);
            float _4715 = (_4703 / fast::max(length(in.m_2952.xyz - (_4699 * _4703)), 9.9999999747524270787835121154785e-07)) * 25.5;
            if (((-24.0) + _4715) < (-2.0))
            {
                _20840 = 0.0;
                break;
            }
            float3 _4723 = in.m_2980 * (4.0 * exp2(mod(_4687, 32.0) * 0.3333333432674407958984375));
            float3 _4767 = floor(_4723);
            float3 _4770 = _4723 - _4767;
            float3 _4778 = (_4770 * _4770) * (float3(3.0) - (_4770 * 2.0));
            uint3 _4845 = uint3(int3(_4767));
            uint _4858 = (((_4845.x * 1597334677u) ^ (_4845.y * 3812015801u)) ^ (_4845.z * 2798796415u)) * 1597334677u;
            uint3 _4873 = uint3(int3(_4767 + float3(1.0, 0.0, 0.0)));
            uint _4886 = (((_4873.x * 1597334677u) ^ (_4873.y * 3812015801u)) ^ (_4873.z * 2798796415u)) * 1597334677u;
            float _4787 = _4778.x;
            uint3 _4901 = uint3(int3(_4767 + float3(0.0, 1.0, 0.0)));
            uint _4914 = (((_4901.x * 1597334677u) ^ (_4901.y * 3812015801u)) ^ (_4901.z * 2798796415u)) * 1597334677u;
            uint3 _4929 = uint3(int3(_4767 + float3(1.0, 1.0, 0.0)));
            uint _4942 = (((_4929.x * 1597334677u) ^ (_4929.y * 3812015801u)) ^ (_4929.z * 2798796415u)) * 1597334677u;
            float _4803 = _4778.y;
            uint3 _4957 = uint3(int3(_4767 + float3(0.0, 0.0, 1.0)));
            uint _4970 = (((_4957.x * 1597334677u) ^ (_4957.y * 3812015801u)) ^ (_4957.z * 2798796415u)) * 1597334677u;
            uint3 _4985 = uint3(int3(_4767 + float3(1.0, 0.0, 1.0)));
            uint _4998 = (((_4985.x * 1597334677u) ^ (_4985.y * 3812015801u)) ^ (_4985.z * 2798796415u)) * 1597334677u;
            uint3 _5013 = uint3(int3(_4767 + float3(0.0, 1.0, 1.0)));
            uint _5026 = (((_5013.x * 1597334677u) ^ (_5013.y * 3812015801u)) ^ (_5013.z * 2798796415u)) * 1597334677u;
            uint3 _5041 = uint3(int3(_4767 + float3(1.0)));
            uint _5054 = (((_5041.x * 1597334677u) ^ (_5041.y * 3812015801u)) ^ (_5041.z * 2798796415u)) * 1597334677u;
            float3 _4729 = (_4723 * 2.7000000476837158203125) + float3(17.299999237060546875, 5.099999904632568359375, 9.69999980926513671875);
            float3 _5080 = floor(_4729);
            float3 _5083 = _4729 - _5080;
            float3 _5091 = (_5083 * _5083) * (float3(3.0) - (_5083 * 2.0));
            uint3 _5158 = uint3(int3(_5080));
            uint _5171 = (((_5158.x * 1597334677u) ^ (_5158.y * 3812015801u)) ^ (_5158.z * 2798796415u)) * 1597334677u;
            uint3 _5186 = uint3(int3(_5080 + float3(1.0, 0.0, 0.0)));
            uint _5199 = (((_5186.x * 1597334677u) ^ (_5186.y * 3812015801u)) ^ (_5186.z * 2798796415u)) * 1597334677u;
            float _5100 = _5091.x;
            uint3 _5214 = uint3(int3(_5080 + float3(0.0, 1.0, 0.0)));
            uint _5227 = (((_5214.x * 1597334677u) ^ (_5214.y * 3812015801u)) ^ (_5214.z * 2798796415u)) * 1597334677u;
            uint3 _5242 = uint3(int3(_5080 + float3(1.0, 1.0, 0.0)));
            uint _5255 = (((_5242.x * 1597334677u) ^ (_5242.y * 3812015801u)) ^ (_5242.z * 2798796415u)) * 1597334677u;
            float _5116 = _5091.y;
            uint3 _5270 = uint3(int3(_5080 + float3(0.0, 0.0, 1.0)));
            uint _5283 = (((_5270.x * 1597334677u) ^ (_5270.y * 3812015801u)) ^ (_5270.z * 2798796415u)) * 1597334677u;
            uint3 _5298 = uint3(int3(_5080 + float3(1.0, 0.0, 1.0)));
            uint _5311 = (((_5298.x * 1597334677u) ^ (_5298.y * 3812015801u)) ^ (_5298.z * 2798796415u)) * 1597334677u;
            uint3 _5326 = uint3(int3(_5080 + float3(0.0, 1.0, 1.0)));
            uint _5339 = (((_5326.x * 1597334677u) ^ (_5326.y * 3812015801u)) ^ (_5326.z * 2798796415u)) * 1597334677u;
            uint3 _5354 = uint3(int3(_5080 + float3(1.0)));
            uint _5367 = (((_5354.x * 1597334677u) ^ (_5354.y * 3812015801u)) ^ (_5354.z * 2798796415u)) * 1597334677u;
            float _4734 = mix(0.449999988079071044921875, 0.0500000007450580596923828125, _4693);
            float _4738 = ((mix(mix(mix(float((_4858 ^ (_4858 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_4886 ^ (_4886 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _4787), mix(float((_4914 ^ (_4914 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_4942 ^ (_4942 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _4787), _4803), mix(mix(float((_4970 ^ (_4970 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_4998 ^ (_4998 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _4787), mix(float((_5026 ^ (_5026 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_5054 ^ (_5054 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _4787), _4803), _4778.z) * 0.64999997615814208984375) + (mix(mix(mix(float((_5171 ^ (_5171 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_5199 ^ (_5199 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _5100), mix(float((_5227 ^ (_5227 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_5255 ^ (_5255 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _5100), _5116), mix(mix(float((_5283 ^ (_5283 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_5311 ^ (_5311 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _5100), mix(float((_5339 ^ (_5339 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_5367 ^ (_5367 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _5100), _5116), _5091.z) * 0.3499999940395355224609375)) - 0.5;
            _20840 = smoothstep(-_4734, _4734, (_4715 + (-24.450000762939453125)) + (_4738 * mix(0.800000011920928955078125, 2.2000000476837158203125, _4693)));
            break;
        } while(false);
        _21003 = _4684;
        _20970 = _20840;
        _20939 = mix(_20842, (in.m_3428.xyz * _4677) * mix(float3(1.0), _3436 * 2.0, float3(0.5)), float3(_20840));
    }
    else
    {
        _21003 = float2(0.0);
        _20970 = 0.0;
        _20939 = _20842;
    }
    float3 _3509 = fast::normalize(in.m_2946);
    float3 _20852;
    if (_2876._m6.y > 0.5)
    {
        float3 _3524 = in.m_2952.xyz - (_3509 * dot(_3509, in.m_2952.xyz));
        float3 _20853;
        if (dot(_3524, _3524) > 9.9999999600419720025001879548654e-13)
        {
            float3 _3532 = fast::normalize(_3524);
            float4 _3548 = _3543.sample(_2533, _3419);
            float3 _20844;
            if (_2876._m6.z > 0.5)
            {
                float2 _20843;
                if (_2876._m6.z > 1.5)
                {
                    _20843 = _3548.xw;
                }
                else
                {
                    _20843 = _3548.xy;
                }
                float2 _3570 = (_20843 * 2.0) - float2(1.0);
                _20844 = float3(_3570, sqrt(fast::clamp(1.0 - dot(_3570, _3570), 0.0, 1.0)));
            }
            else
            {
                _20844 = (_3548.xyz * 2.0) - float3(1.0);
            }
            float2 _3592 = _20844.xy * _2876._m4.z;
            _20853 = fast::normalize(((_3532 * _3592.x) + ((cross(_3509, _3532) * ((in.m_2952.w < 0.0) ? (-1.0) : 1.0)) * _3592.y)) + (_3509 * _20844.z));
        }
        else
        {
            _20853 = _3509;
        }
        _20852 = _20853;
    }
    else
    {
        _20852 = _3509;
    }
    bool _3616 = _2876._m5.w > 0.5;
    float _20849;
    if (_3616)
    {
        _20849 = fast::clamp(_2876._m1.z, 0.0, 1.0);
    }
    else
    {
        _20849 = 0.0;
    }
    bool _3634;
    if (_3616)
    {
        _3634 = !gl_FrontFacing;
    }
    else
    {
        _3634 = _3616;
    }
    float3 _21039;
    if (_3634 && (_20849 <= 0.0))
    {
        _21039 = -_20852;
    }
    else
    {
        _21039 = _20852;
    }
    float3 _3646 = fast::normalize(_283._m4.xyz);
    float3 _3652 = _283._m6.xyz - in.m_3037;
    float3 _3653 = fast::normalize(_3652);
    float3 _3658 = fast::normalize(_3646 + _3653);
    float3 _3664 = _3509 * (gl_FrontFacing ? 1.0 : (-1.0));
    bool _3669 = in.m_3666.x > 0.5;
    float3 _21033;
    float _21073;
    if ((_283._m5.w > 0.5) && _3669)
    {
        float _20909;
        float3 _20910;
        do
        {
            int _5396 = int(_283._m21.x);
            float _5404 = dot(_283._m20.xyz, in.m_3037) + _283._m20.w;
            int _20854;
            _20854 = 0;
            for (;;)
            {
                bool _5410 = _20854 < (_5396 - 1);
                bool _5418;
                if (_5410)
                {
                    _5418 = _5404 > _283._m16[_20854];
                }
                else
                {
                    _5418 = _5410;
                }
                if (_5418)
                {
                    _20854++;
                    continue;
                }
                else
                {
                    break;
                }
            }
            if (_5404 > _283._m16[_20854])
            {
                _20910 = float3(1.0);
                _20909 = 1.0;
                break;
            }
            float _20867;
            do
            {
                float4 _5520 = _283._m14[_20854] * float4(in.m_3037 + (_3664 * _283._m18[_20854]), 1.0);
                float _5523 = _5520.x;
                bool _5524 = _5523 < 0.0;
                bool _5531;
                if (!_5524)
                {
                    _5531 = _5523 > 1.0;
                }
                else
                {
                    _5531 = _5524;
                }
                bool _5538;
                if (!_5531)
                {
                    _5538 = _5520.y < 0.0;
                }
                else
                {
                    _5538 = _5531;
                }
                bool _5545;
                if (!_5538)
                {
                    _5545 = _5520.y > 1.0;
                }
                else
                {
                    _5545 = _5538;
                }
                if (_5545)
                {
                    _20867 = 1.0;
                    break;
                }
                float2 _5558 = float2(float(_20854 & 1), float(_20854 >> 1)) * _283._m23.xy;
                float _5565 = fast::min(_5520.z, 1.0) - _283._m19[_20854];
                float2 _5584 = _283._m22.xy * 0.5;
                float2 _5589 = _5558 + (_5520.xy * _283._m23.xy);
                float4 _5602 = float4(_5558 + _5584, (_5558 + _283._m23.xy) - _5584);
                float _20866;
                do
                {
                    int _5628 = int(_283._m22.z);
                    if (_5628 <= 0)
                    {
                        _20866 = spvDepthCast(_303).sample_compare(_303Smplr, float3(fast::clamp(_5589, _5602.xy, _5602.zw), _5565).xy, _5565);
                        break;
                    }
                    float2 _5651 = (_5589 / _283._m22.xy) + float2(0.5);
                    float2 _5652 = floor(_5651);
                    float2 _5657 = _5651 - _5652;
                    float2 _5660 = _5652 - float2(0.5);
                    bool _5664 = _5628 == 1;
                    spvUnsafeArray<float2, 3> _5612;
                    spvUnsafeArray<float2, 3> _5613;
                    if (_5664)
                    {
                        float2 _5667 = _5657 * 2.0;
                        _5612[0] = float2(3.0) - _5667;
                        _5612[1] = float2(1.0) + _5667;
                        _5613[0] = ((float2(2.0) - _5657) / _5612[0]) - float2(1.0);
                        _5613[1] = (_5657 / _5612[1]) + float2(1.0);
                    }
                    else
                    {
                        float2 _5694 = _5657 * 3.0;
                        _5612[0] = float2(4.0) - _5694;
                        _5612[1] = float2(7.0);
                        _5612[2] = float2(1.0) + _5694;
                        _5613[0] = ((float2(3.0) - (_5657 * 2.0)) / _5612[0]) - float2(2.0);
                        _5613[1] = (float2(3.0) + _5657) / _5612[1];
                        _5613[2] = (_5657 / _5612[2]) + float2(2.0);
                    }
                    int _22116 = _5664 ? 2 : 3;
                    int _20856;
                    float _20859;
                    _20859 = 0.0;
                    _20856 = 0;
                    float _20865;
                    for (; _20856 < _22116; _20859 = _20865, _20856++)
                    {
                        _20865 = _20859;
                        for (int _20862 = 0; _20862 < _22116; )
                        {
                            _20865 += ((_5612[_20862].x * _5612[_20856].y) * spvDepthCast(_303).sample_compare(_303Smplr, float3(fast::clamp(_283._m22.xy * (_5660 + float2(_5613[_20862].x, _5613[_20856].y)), _5602.xy, _5602.zw), _5565).xy, _5565));
                            _20862++;
                            continue;
                        }
                    }
                    _20866 = _20859 * (_5664 ? 0.0625 : 0.0069444444961845874786376953125);
                    break;
                } while(false);
                _20867 = _20866;
                break;
            } while(false);
            float3 _20904;
            float _20907;
            if (_5404 > _283._m17[_20854])
            {
                float _5458 = (_5404 - _283._m17[_20854]) / (_283._m16[_20854] - _283._m17[_20854]);
                int _5460 = _20854 + 1;
                float3 _20905;
                float _20908;
                if (_5460 < _5396)
                {
                    float _20887;
                    do
                    {
                        float4 _5807 = _283._m14[_5460] * float4(in.m_3037 + (_3664 * _283._m18[_5460]), 1.0);
                        float _5810 = _5807.x;
                        bool _5811 = _5810 < 0.0;
                        bool _5818;
                        if (!_5811)
                        {
                            _5818 = _5810 > 1.0;
                        }
                        else
                        {
                            _5818 = _5811;
                        }
                        bool _5825;
                        if (!_5818)
                        {
                            _5825 = _5807.y < 0.0;
                        }
                        else
                        {
                            _5825 = _5818;
                        }
                        bool _5832;
                        if (!_5825)
                        {
                            _5832 = _5807.y > 1.0;
                        }
                        else
                        {
                            _5832 = _5825;
                        }
                        if (_5832)
                        {
                            _20887 = 1.0;
                            break;
                        }
                        float2 _5845 = float2(float(_5460 & 1), float(_5460 >> 1)) * _283._m23.xy;
                        float _5852 = fast::min(_5807.z, 1.0) - _283._m19[_5460];
                        float2 _5871 = _283._m22.xy * 0.5;
                        float2 _5876 = _5845 + (_5807.xy * _283._m23.xy);
                        float4 _5889 = float4(_5845 + _5871, (_5845 + _283._m23.xy) - _5871);
                        float _20886;
                        do
                        {
                            int _5915 = int(_283._m22.z);
                            if (_5915 <= 0)
                            {
                                _20886 = spvDepthCast(_303).sample_compare(_303Smplr, float3(fast::clamp(_5876, _5889.xy, _5889.zw), _5852).xy, _5852);
                                break;
                            }
                            float2 _5938 = (_5876 / _283._m22.xy) + float2(0.5);
                            float2 _5939 = floor(_5938);
                            float2 _5944 = _5938 - _5939;
                            float2 _5947 = _5939 - float2(0.5);
                            bool _5951 = _5915 == 1;
                            spvUnsafeArray<float2, 3> _5899;
                            spvUnsafeArray<float2, 3> _5900;
                            if (_5951)
                            {
                                float2 _5954 = _5944 * 2.0;
                                _5899[0] = float2(3.0) - _5954;
                                _5899[1] = float2(1.0) + _5954;
                                _5900[0] = ((float2(2.0) - _5944) / _5899[0]) - float2(1.0);
                                _5900[1] = (_5944 / _5899[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _5981 = _5944 * 3.0;
                                _5899[0] = float2(4.0) - _5981;
                                _5899[1] = float2(7.0);
                                _5899[2] = float2(1.0) + _5981;
                                _5900[0] = ((float2(3.0) - (_5944 * 2.0)) / _5899[0]) - float2(2.0);
                                _5900[1] = (float2(3.0) + _5944) / _5899[1];
                                _5900[2] = (_5944 / _5899[2]) + float2(2.0);
                            }
                            int _22118 = _5951 ? 2 : 3;
                            int _20876;
                            float _20879;
                            _20879 = 0.0;
                            _20876 = 0;
                            float _20885;
                            for (; _20876 < _22118; _20879 = _20885, _20876++)
                            {
                                _20885 = _20879;
                                for (int _20882 = 0; _20882 < _22118; )
                                {
                                    _20885 += ((_5899[_20882].x * _5899[_20876].y) * spvDepthCast(_303).sample_compare(_303Smplr, float3(fast::clamp(_283._m22.xy * (_5947 + float2(_5900[_20882].x, _5900[_20876].y)), _5889.xy, _5889.zw), _5852).xy, _5852));
                                    _20882++;
                                    continue;
                                }
                            }
                            _20886 = _20879 * (_5951 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _20887 = _20886;
                        break;
                    } while(false);
                    _20908 = mix(_20867, _20887, _5458);
                    _20905 = mix(_657[_20854], _657[_5460], float3(_5458));
                }
                else
                {
                    _20908 = mix(_20867, 1.0, _5458);
                    _20905 = _657[_20854];
                }
                _20907 = _20908;
                _20904 = _20905;
            }
            else
            {
                _20907 = _20867;
                _20904 = _657[_20854];
            }
            _20910 = select(float3(1.0), _20904, bool3(_283._m22.w > 0.5));
            _20909 = _20907;
            break;
        } while(false);
        _21073 = _20909;
        _21033 = _20939 * _20910;
    }
    else
    {
        _21073 = 1.0;
        _21033 = _20939;
    }
    float3 _3695 = _283._m5.xyz * _283._m4.w;
    bool _3699 = _2876._m6.w > 0.5;
    float _20962;
    if (_3699)
    {
        _20962 = 1.0;
    }
    else
    {
        _20962 = 1.0 + (_2876._m4.w * (_3352.sample(_2533, _3419).x - 1.0));
    }
    float _3719 = abs(in.m_2952.w);
    float _21163;
    if (_3719 > 0.0)
    {
        _21163 = _20962 * fast::min(_3719, 1.0);
    }
    else
    {
        _21163 = _20962;
    }
    float3 _21716;
    if (!_3616)
    {
        float _3735 = dot(_21039, _3646);
        bool _3760 = _283._m29.x > 0.5;
        float3 _21691;
        if (_3760)
        {
            float _6132 = (_283._m29.z * _21039.x) - (_283._m29.w * _21039.z);
            float _6145 = (_283._m29.w * _21039.x) + (_283._m29.z * _21039.z);
            float _6163 = 1.09254801273345947265625 * _6132;
            spvUnsafeArray<float, 9> _19405 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _21039.y, 0.48860299587249755859375 * _6145, 0.48860299587249755859375 * _6132, _6163 * _21039.y, (1.09254801273345947265625 * _21039.y) * _6145, 0.3153919875621795654296875 * (((3.0 * _6145) * _6145) - 1.0), _6163 * _6145, 0.546274006366729736328125 * ((_6132 * _6132) - (_21039.y * _21039.y)) });
            spvUnsafeArray<float, 9> _6077 = _19405;
            float3 _21690;
            _21690 = float3(0.0);
            for (int _21689 = 0; _21689 < 9; )
            {
                _21690 += (_2531.read(uint2((int2(496, 256) + int2(_21689, 0))), 0).xyz * _6077[_21689]);
                _21689++;
                continue;
            }
            _21691 = fast::max(_21690, float3(0.0)) * _283._m29.y;
        }
        else
        {
            _21691 = mix(_283._m9.xyz, _283._m8.xyz, float3((_21039.y * 0.5) + 0.5)) * _283._m8.w;
        }
        float3 _3785 = (_21033 * ((_21691 * _21163) + ((_3695 * fast::max(_3735, 0.0)) * _21073))) + ((_3695 * ((powr(fast::max(dot(_21039, _3658), 0.0), _2876._m1.w) * _2876._m1.z) * step(0.0, _3735))) * _21073);
        float3 _21718;
        if (_283._m34.y > 0.5)
        {
            float3 _21702;
            if (_3760)
            {
                float _6278 = (_283._m29.z * _21039.x) - (_283._m29.w * _21039.z);
                float _6291 = (_283._m29.w * _21039.x) + (_283._m29.z * _21039.z);
                float _6309 = 1.09254801273345947265625 * _6278;
                spvUnsafeArray<float, 9> _19386 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _21039.y, 0.48860299587249755859375 * _6291, 0.48860299587249755859375 * _6278, _6309 * _21039.y, (1.09254801273345947265625 * _21039.y) * _6291, 0.3153919875621795654296875 * (((3.0 * _6291) * _6291) - 1.0), _6309 * _6291, 0.546274006366729736328125 * ((_6278 * _6278) - (_21039.y * _21039.y)) });
                spvUnsafeArray<float, 9> _6223 = _19386;
                float3 _21701;
                _21701 = float3(0.0);
                for (int _21700 = 0; _21700 < 9; )
                {
                    _21701 += (_2531.read(uint2((int2(496, 256) + int2(_21700, 0))), 0).xyz * _6223[_21700]);
                    _21700++;
                    continue;
                }
                _21702 = fast::max(_21701, float3(0.0)) * _283._m29.y;
            }
            else
            {
                _21702 = mix(_283._m9.xyz, _283._m8.xyz, float3((_21039.y * 0.5) + 0.5)) * _283._m8.w;
            }
            int _6486 = int(_283._m34.y);
            int _6489 = int(_283._m34.x);
            float3 _21708;
            _21708 = _21702;
            float3 _22006;
            for (int _21707 = 0; _21707 < _6486; _21708 = _22006, _21707++)
            {
                int _6501 = 8 * (_6489 + _21707);
                float4 _6710 = as_type<float4>(_1281._m0[_6501 + 3]);
                float4 _6754 = as_type<float4>(_1281._m0[_6501]);
                float4 _6760 = as_type<float4>(_1281._m0[_6501 + 1]);
                float4 _6766 = as_type<float4>(_1281._m0[_6501 + 2]);
                float3 _6728 = _6754.xyz;
                float _6732 = _6754.w;
                float3 _6735 = _6760.xyz;
                float _6739 = _6760.w;
                float3 _6742 = _6766.xyz;
                float _6746 = _6766.w;
                float3 _6748 = float3(dot(_6728, in.m_3037) + _6732, dot(_6735, in.m_3037) + _6739, dot(_6742, in.m_3037) + _6746);
                float3 _6510 = _6710.xyz;
                float _6512 = _6710.w;
                float _21969;
                do
                {
                    float3 _6778 = _6510 - abs(_6748);
                    float _6786 = fast::min(_6778.x, fast::min(_6778.y, _6778.z));
                    if (_6786 <= 0.0)
                    {
                        _21969 = 0.0;
                        break;
                    }
                    if (_6512 <= 0.0)
                    {
                        _21969 = 1.0;
                        break;
                    }
                    float _6798 = fast::min(_6786 / _6512, 1.0);
                    _21969 = (_6798 * _6798) * (3.0 - (2.0 * _6798));
                    break;
                } while(false);
                if (_21969 <= 0.0)
                {
                    _22006 = _21708;
                    continue;
                }
                float3 _6521 = as_type<float4>(_1281._m0[_6501 + 4]).xyz;
                float4 _6819 = as_type<float4>(_1281._m0[_6501 + 5]);
                int _6825 = int(((device uint*)&_1281._m0[_6501 + 6])[0u]);
                float _6835 = dot(_6728, _21039);
                float _6841 = dot(_6735, _21039);
                float _6847 = dot(_6742, _21039);
                float3 _6848 = float3(_6835, _6841, _6847);
                float3 _6541 = (in.m_3037 + (_21039 * _6819.x)) + (_3653 * _6819.y);
                float3 _6560 = fast::clamp((((float3(dot(_6728, _6541) + _6732, dot(_6735, _6541) + _6739, dot(_6742, _6541) + _6746) + _6510) / fast::max(_6510 * 2.0, float3(9.9999999747524270787835121154785e-07))) * _6521) - float3(0.5), float3(0.0), _6521 - float3(1.0));
                int3 _6562 = int3(_6521);
                int3 _6569 = min(int3(_6560), max((_6562 - int3(2)), int3(0)));
                float3 _6573 = _6560 - float3(_6569);
                float _6928 = 0.48860299587249755859375 * _6841;
                float _6931 = 0.48860299587249755859375 * _6847;
                float _6934 = 0.48860299587249755859375 * _6835;
                float _6939 = 1.09254801273345947265625 * _6835;
                float _6942 = _6939 * _6841;
                float _6948 = (1.09254801273345947265625 * _6841) * _6847;
                float _6956 = 0.3153919875621795654296875 * (((3.0 * _6847) * _6847) - 1.0);
                float _6962 = _6939 * _6847;
                float _6976 = 0.546274006366729736328125 * ((_6835 * _6835) - (_6841 * _6841));
                int3 _6995 = _6562 - int3(1);
                int3 _6996 = min(_6569, _6995);
                int _7001 = _6562.x;
                int _7005 = _6562.y;
                int _7013 = _6825 + ((_6996.x + (_7001 * (_6996.y + (_7005 * _6996.z)))) * 4);
                float3 _7016 = float3(1.0) - _6573;
                float3 _7034 = (((((float3(_6996) + float3(0.5)) / _6521) * _6510) * 2.0) - _6510) - _6748;
                float _7044 = dot(_7034 * rsqrt(fast::max(dot(_7034, _7034), 1.0000000133514319600180897396058e-10)), _6848) + 1.0;
                float _7047 = _7016.x;
                float _7049 = _7016.y;
                float _7050 = _7047 * _7049;
                float _7052 = _7016.z;
                int _7076 = _7013 + 3;
                float _7062 = ((_7050 * _7052) * ((0.25 * (_7044 * _7044)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_7076])[1u])).y > 0.5);
                int _7106 = _7013 + 1;
                int _7110 = _7013 + 2;
                float2 _7122 = float2(as_type<half2>(_1281._m0[_7013].y));
                float2 _7131 = float2(as_type<half2>(_1281._m0[_7106].x));
                float2 _7140 = float2(as_type<half2>(_1281._m0[_7106].w));
                float2 _7149 = float2(as_type<half2>(_1281._m0[_7110].z));
                float3 _7237 = (((((((float3(float2(as_type<half2>(_1281._m0[_7013].x)), _7122.x) * 0.2820949852466583251953125) + (float3(_7122.y, float2(as_type<half2>(_1281._m0[_7013].z))) * _6928)) + (float3(float2(as_type<half2>(_1281._m0[_7013].w)), _7131.x) * _6931)) + (float3(_7131.y, float2(as_type<half2>(_1281._m0[_7106].y))) * _6934)) + (float3(float2(as_type<half2>(_1281._m0[_7106].z)), _7140.x) * _6942)) + (float3(_7140.y, float2(as_type<half2>(_1281._m0[_7110].x))) * _6948)) + (float3(float2(as_type<half2>(_1281._m0[_7110].y)), _7149.x) * _6956)) + (float3(_7149.y, float2(as_type<half2>(_1281._m0[_7110].w))) * _6962);
                int3 _7265 = min((_6569 + int3(1, 0, 0)), _6995);
                int _7282 = _6825 + ((_7265.x + (_7001 * (_7265.y + (_7005 * _7265.z)))) * 4);
                float3 _7303 = (((((float3(_7265) + float3(0.5)) / _6521) * _6510) * 2.0) - _6510) - _6748;
                float _7313 = dot(_7303 * rsqrt(fast::max(dot(_7303, _7303), 1.0000000133514319600180897396058e-10)), _6848) + 1.0;
                float _7319 = _6573.x * _7049;
                int _7345 = _7282 + 3;
                float _7331 = ((_7319 * _7052) * ((0.25 * (_7313 * _7313)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_7345])[1u])).y > 0.5);
                int _7375 = _7282 + 1;
                int _7379 = _7282 + 2;
                float2 _7391 = float2(as_type<half2>(_1281._m0[_7282].y));
                float2 _7400 = float2(as_type<half2>(_1281._m0[_7375].x));
                float2 _7409 = float2(as_type<half2>(_1281._m0[_7375].w));
                float2 _7418 = float2(as_type<half2>(_1281._m0[_7379].z));
                float3 _7506 = (((((((float3(float2(as_type<half2>(_1281._m0[_7282].x)), _7391.x) * 0.2820949852466583251953125) + (float3(_7391.y, float2(as_type<half2>(_1281._m0[_7282].z))) * _6928)) + (float3(float2(as_type<half2>(_1281._m0[_7282].w)), _7400.x) * _6931)) + (float3(_7400.y, float2(as_type<half2>(_1281._m0[_7375].y))) * _6934)) + (float3(float2(as_type<half2>(_1281._m0[_7375].z)), _7409.x) * _6942)) + (float3(_7409.y, float2(as_type<half2>(_1281._m0[_7379].x))) * _6948)) + (float3(float2(as_type<half2>(_1281._m0[_7379].y)), _7418.x) * _6956)) + (float3(_7418.y, float2(as_type<half2>(_1281._m0[_7379].w))) * _6962);
                int3 _7534 = min((_6569 + int3(0, 1, 0)), _6995);
                int _7551 = _6825 + ((_7534.x + (_7001 * (_7534.y + (_7005 * _7534.z)))) * 4);
                float3 _7572 = (((((float3(_7534) + float3(0.5)) / _6521) * _6510) * 2.0) - _6510) - _6748;
                float _7582 = dot(_7572 * rsqrt(fast::max(dot(_7572, _7572), 1.0000000133514319600180897396058e-10)), _6848) + 1.0;
                float _7588 = _7047 * _6573.y;
                int _7614 = _7551 + 3;
                float _7600 = ((_7588 * _7052) * ((0.25 * (_7582 * _7582)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_7614])[1u])).y > 0.5);
                int _7644 = _7551 + 1;
                int _7648 = _7551 + 2;
                float2 _7660 = float2(as_type<half2>(_1281._m0[_7551].y));
                float2 _7669 = float2(as_type<half2>(_1281._m0[_7644].x));
                float2 _7678 = float2(as_type<half2>(_1281._m0[_7644].w));
                float2 _7687 = float2(as_type<half2>(_1281._m0[_7648].z));
                float3 _7775 = (((((((float3(float2(as_type<half2>(_1281._m0[_7551].x)), _7660.x) * 0.2820949852466583251953125) + (float3(_7660.y, float2(as_type<half2>(_1281._m0[_7551].z))) * _6928)) + (float3(float2(as_type<half2>(_1281._m0[_7551].w)), _7669.x) * _6931)) + (float3(_7669.y, float2(as_type<half2>(_1281._m0[_7644].y))) * _6934)) + (float3(float2(as_type<half2>(_1281._m0[_7644].z)), _7678.x) * _6942)) + (float3(_7678.y, float2(as_type<half2>(_1281._m0[_7648].x))) * _6948)) + (float3(float2(as_type<half2>(_1281._m0[_7648].y)), _7687.x) * _6956)) + (float3(_7687.y, float2(as_type<half2>(_1281._m0[_7648].w))) * _6962);
                int3 _7803 = min((_6569 + int3(1, 1, 0)), _6995);
                int _7820 = _6825 + ((_7803.x + (_7001 * (_7803.y + (_7005 * _7803.z)))) * 4);
                float3 _7841 = (((((float3(_7803) + float3(0.5)) / _6521) * _6510) * 2.0) - _6510) - _6748;
                float _7851 = dot(_7841 * rsqrt(fast::max(dot(_7841, _7841), 1.0000000133514319600180897396058e-10)), _6848) + 1.0;
                float _7857 = _6573.x * _6573.y;
                int _7883 = _7820 + 3;
                float _7869 = ((_7857 * _7052) * ((0.25 * (_7851 * _7851)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_7883])[1u])).y > 0.5);
                int _7913 = _7820 + 1;
                int _7917 = _7820 + 2;
                float2 _7929 = float2(as_type<half2>(_1281._m0[_7820].y));
                float2 _7938 = float2(as_type<half2>(_1281._m0[_7913].x));
                float2 _7947 = float2(as_type<half2>(_1281._m0[_7913].w));
                float2 _7956 = float2(as_type<half2>(_1281._m0[_7917].z));
                float3 _8044 = (((((((float3(float2(as_type<half2>(_1281._m0[_7820].x)), _7929.x) * 0.2820949852466583251953125) + (float3(_7929.y, float2(as_type<half2>(_1281._m0[_7820].z))) * _6928)) + (float3(float2(as_type<half2>(_1281._m0[_7820].w)), _7938.x) * _6931)) + (float3(_7938.y, float2(as_type<half2>(_1281._m0[_7913].y))) * _6934)) + (float3(float2(as_type<half2>(_1281._m0[_7913].z)), _7947.x) * _6942)) + (float3(_7947.y, float2(as_type<half2>(_1281._m0[_7917].x))) * _6948)) + (float3(float2(as_type<half2>(_1281._m0[_7917].y)), _7956.x) * _6956)) + (float3(_7956.y, float2(as_type<half2>(_1281._m0[_7917].w))) * _6962);
                int3 _8072 = min((_6569 + int3(0, 0, 1)), _6995);
                int _8089 = _6825 + ((_8072.x + (_7001 * (_8072.y + (_7005 * _8072.z)))) * 4);
                float3 _8110 = (((((float3(_8072) + float3(0.5)) / _6521) * _6510) * 2.0) - _6510) - _6748;
                float _8120 = dot(_8110 * rsqrt(fast::max(dot(_8110, _8110), 1.0000000133514319600180897396058e-10)), _6848) + 1.0;
                int _8152 = _8089 + 3;
                float _8138 = ((_7050 * _6573.z) * ((0.25 * (_8120 * _8120)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_8152])[1u])).y > 0.5);
                int _8182 = _8089 + 1;
                int _8186 = _8089 + 2;
                float2 _8198 = float2(as_type<half2>(_1281._m0[_8089].y));
                float2 _8207 = float2(as_type<half2>(_1281._m0[_8182].x));
                float2 _8216 = float2(as_type<half2>(_1281._m0[_8182].w));
                float2 _8225 = float2(as_type<half2>(_1281._m0[_8186].z));
                float3 _8313 = (((((((float3(float2(as_type<half2>(_1281._m0[_8089].x)), _8198.x) * 0.2820949852466583251953125) + (float3(_8198.y, float2(as_type<half2>(_1281._m0[_8089].z))) * _6928)) + (float3(float2(as_type<half2>(_1281._m0[_8089].w)), _8207.x) * _6931)) + (float3(_8207.y, float2(as_type<half2>(_1281._m0[_8182].y))) * _6934)) + (float3(float2(as_type<half2>(_1281._m0[_8182].z)), _8216.x) * _6942)) + (float3(_8216.y, float2(as_type<half2>(_1281._m0[_8186].x))) * _6948)) + (float3(float2(as_type<half2>(_1281._m0[_8186].y)), _8225.x) * _6956)) + (float3(_8225.y, float2(as_type<half2>(_1281._m0[_8186].w))) * _6962);
                float4 _6640 = (((float4((_7237 + (float3(float2(as_type<half2>(_1281._m0[_7076].x)), float2(as_type<half2>(_1281._m0[_7076].y)).x) * _6976)) * _7062, _7062) + float4((_7506 + (float3(float2(as_type<half2>(_1281._m0[_7345].x)), float2(as_type<half2>(_1281._m0[_7345].y)).x) * _6976)) * _7331, _7331)) + float4((_7775 + (float3(float2(as_type<half2>(_1281._m0[_7614].x)), float2(as_type<half2>(_1281._m0[_7614].y)).x) * _6976)) * _7600, _7600)) + float4((_8044 + (float3(float2(as_type<half2>(_1281._m0[_7883].x)), float2(as_type<half2>(_1281._m0[_7883].y)).x) * _6976)) * _7869, _7869)) + float4((_8313 + (float3(float2(as_type<half2>(_1281._m0[_8152].x)), float2(as_type<half2>(_1281._m0[_8152].y)).x) * _6976)) * _8138, _8138);
                int3 _8341 = min((_6569 + int3(1, 0, 1)), _6995);
                int _8358 = _6825 + ((_8341.x + (_7001 * (_8341.y + (_7005 * _8341.z)))) * 4);
                float3 _8379 = (((((float3(_8341) + float3(0.5)) / _6521) * _6510) * 2.0) - _6510) - _6748;
                float _8389 = dot(_8379 * rsqrt(fast::max(dot(_8379, _8379), 1.0000000133514319600180897396058e-10)), _6848) + 1.0;
                int _8421 = _8358 + 3;
                float _8407 = ((_7319 * _6573.z) * ((0.25 * (_8389 * _8389)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_8421])[1u])).y > 0.5);
                int _8451 = _8358 + 1;
                int _8455 = _8358 + 2;
                float2 _8467 = float2(as_type<half2>(_1281._m0[_8358].y));
                float2 _8476 = float2(as_type<half2>(_1281._m0[_8451].x));
                float2 _8485 = float2(as_type<half2>(_1281._m0[_8451].w));
                float2 _8494 = float2(as_type<half2>(_1281._m0[_8455].z));
                float3 _8582 = (((((((float3(float2(as_type<half2>(_1281._m0[_8358].x)), _8467.x) * 0.2820949852466583251953125) + (float3(_8467.y, float2(as_type<half2>(_1281._m0[_8358].z))) * _6928)) + (float3(float2(as_type<half2>(_1281._m0[_8358].w)), _8476.x) * _6931)) + (float3(_8476.y, float2(as_type<half2>(_1281._m0[_8451].y))) * _6934)) + (float3(float2(as_type<half2>(_1281._m0[_8451].z)), _8485.x) * _6942)) + (float3(_8485.y, float2(as_type<half2>(_1281._m0[_8455].x))) * _6948)) + (float3(float2(as_type<half2>(_1281._m0[_8455].y)), _8494.x) * _6956)) + (float3(_8494.y, float2(as_type<half2>(_1281._m0[_8455].w))) * _6962);
                int3 _8610 = min((_6569 + int3(0, 1, 1)), _6995);
                int _8627 = _6825 + ((_8610.x + (_7001 * (_8610.y + (_7005 * _8610.z)))) * 4);
                float3 _8648 = (((((float3(_8610) + float3(0.5)) / _6521) * _6510) * 2.0) - _6510) - _6748;
                float _8658 = dot(_8648 * rsqrt(fast::max(dot(_8648, _8648), 1.0000000133514319600180897396058e-10)), _6848) + 1.0;
                int _8690 = _8627 + 3;
                float _8676 = ((_7588 * _6573.z) * ((0.25 * (_8658 * _8658)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_8690])[1u])).y > 0.5);
                int _8720 = _8627 + 1;
                int _8724 = _8627 + 2;
                float2 _8736 = float2(as_type<half2>(_1281._m0[_8627].y));
                float2 _8745 = float2(as_type<half2>(_1281._m0[_8720].x));
                float2 _8754 = float2(as_type<half2>(_1281._m0[_8720].w));
                float2 _8763 = float2(as_type<half2>(_1281._m0[_8724].z));
                float3 _8851 = (((((((float3(float2(as_type<half2>(_1281._m0[_8627].x)), _8736.x) * 0.2820949852466583251953125) + (float3(_8736.y, float2(as_type<half2>(_1281._m0[_8627].z))) * _6928)) + (float3(float2(as_type<half2>(_1281._m0[_8627].w)), _8745.x) * _6931)) + (float3(_8745.y, float2(as_type<half2>(_1281._m0[_8720].y))) * _6934)) + (float3(float2(as_type<half2>(_1281._m0[_8720].z)), _8754.x) * _6942)) + (float3(_8754.y, float2(as_type<half2>(_1281._m0[_8724].x))) * _6948)) + (float3(float2(as_type<half2>(_1281._m0[_8724].y)), _8763.x) * _6956)) + (float3(_8763.y, float2(as_type<half2>(_1281._m0[_8724].w))) * _6962);
                int3 _8879 = min((_6569 + int3(1)), _6995);
                int _8896 = _6825 + ((_8879.x + (_7001 * (_8879.y + (_7005 * _8879.z)))) * 4);
                float3 _8917 = (((((float3(_8879) + float3(0.5)) / _6521) * _6510) * 2.0) - _6510) - _6748;
                float _8927 = dot(_8917 * rsqrt(fast::max(dot(_8917, _8917), 1.0000000133514319600180897396058e-10)), _6848) + 1.0;
                int _8959 = _8896 + 3;
                float _8945 = ((_7857 * _6573.z) * ((0.25 * (_8927 * _8927)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_8959])[1u])).y > 0.5);
                int _8989 = _8896 + 1;
                int _8993 = _8896 + 2;
                float2 _9005 = float2(as_type<half2>(_1281._m0[_8896].y));
                float2 _9014 = float2(as_type<half2>(_1281._m0[_8989].x));
                float2 _9023 = float2(as_type<half2>(_1281._m0[_8989].w));
                float2 _9032 = float2(as_type<half2>(_1281._m0[_8993].z));
                float3 _9120 = (((((((float3(float2(as_type<half2>(_1281._m0[_8896].x)), _9005.x) * 0.2820949852466583251953125) + (float3(_9005.y, float2(as_type<half2>(_1281._m0[_8896].z))) * _6928)) + (float3(float2(as_type<half2>(_1281._m0[_8896].w)), _9014.x) * _6931)) + (float3(_9014.y, float2(as_type<half2>(_1281._m0[_8989].y))) * _6934)) + (float3(float2(as_type<half2>(_1281._m0[_8989].z)), _9023.x) * _6942)) + (float3(_9023.y, float2(as_type<half2>(_1281._m0[_8993].x))) * _6948)) + (float3(float2(as_type<half2>(_1281._m0[_8993].y)), _9032.x) * _6956)) + (float3(_9032.y, float2(as_type<half2>(_1281._m0[_8993].w))) * _6962);
                float4 _6679 = ((_6640 + float4((_8582 + (float3(float2(as_type<half2>(_1281._m0[_8421].x)), float2(as_type<half2>(_1281._m0[_8421].y)).x) * _6976)) * _8407, _8407)) + float4((_8851 + (float3(float2(as_type<half2>(_1281._m0[_8690].x)), float2(as_type<half2>(_1281._m0[_8690].y)).x) * _6976)) * _8676, _8676)) + float4((_9120 + (float3(float2(as_type<half2>(_1281._m0[_8959].x)), float2(as_type<half2>(_1281._m0[_8959].y)).x) * _6976)) * _8945, _8945);
                float _6683 = _6679.w;
                float3 _22007;
                if (_6683 > 9.9999997473787516355514526367188e-06)
                {
                    _22007 = mix(_21708, (fast::max(_6679.xyz, float3(0.0)) / float3(_6683)) * _6819.z, float3(_21969));
                }
                else
                {
                    _22007 = _21708;
                }
                _22006 = _22007;
            }
            _21718 = _3785 + ((_21033 * (_21708 - _21702)) * _21163);
        }
        else
        {
            _21718 = _3785;
        }
        float3 _21717;
        if (_283._m13.w > 0.5)
        {
            float2 _9158 = fast::clamp(floor(gl_FragCoord.xy * _283._m12.xy), float2(0.0), _283._m13.xy - float2(1.0));
            uint _9186 = uint((((fast::clamp(floor((log2(fast::max(dot(_283._m11.xyz, in.m_3037) + _283._m11.w, 9.9999999747524270787835121154785e-07)) * _283._m12.z) + _283._m12.w), 0.0, _283._m13.z - 1.0) * _283._m13.y) + _9158.y) * _283._m13.x) + _9158.x);
            uint _9188 = _9186 >> uint(2);
            uint _9190 = _9186 & 3u;
            uint _9194 = _3167._m0[_9188][_9190] & 65535u;
            uint _9196 = _3167._m0[_9188][_9190] >> uint(16);
            float3 _21719;
            _21719 = _21718;
            float3 _3902;
            spvUnsafeArray<float2, 3> _9604;
            spvUnsafeArray<float2, 3> _9605;
            spvUnsafeArray<float2, 3> _9817;
            spvUnsafeArray<float2, 3> _9818;
            for (uint _21715 = _9194; _21715 < (_9194 + _9196); _21719 = _3902, _21715++)
            {
                uint _9202 = _21715 / 3u;
                uint _9215 = (_3188._m0[_9202 >> uint(2)][_9202 & 3u] >> ((_21715 - (_9202 * 3u)) * 10u)) & 1023u;
                float3 _9232 = _3030._m0[_9215].xyz - in.m_3037;
                float _9235 = dot(_9232, _9232);
                float _9239 = _9235 * _3030._m0[_9215].w;
                float _9244 = fast::clamp(1.0 - (_9239 * _9239), 0.0, 1.0);
                float3 _9249 = _9232 * rsqrt(fast::max(_9235, 9.9999999392252902907785028219223e-09));
                float _9267 = fast::clamp((dot(-_9249, _3073._m0[_9215].xyz) * _3065._m0[_9215].w) + _3073._m0[_9215].w, 0.0, 1.0);
                float3 _9280 = _3065._m0[_9215].xyz * ((((_9244 * _9244) * _9267) * _9267) / fast::max(_9235, 9.9999997473787516355514526367188e-05));
                float3 _21934;
                if (_3669)
                {
                    float _21883;
                    do
                    {
                        uint _9316 = uint(_283._m21.z);
                        if (_9215 < _9316)
                        {
                            float _9338 = _283._m26[_9215].z * fast::max((_283._m15[_9215] * float4(in.m_3037, 1.0)).w, 0.0);
                            float4 _9362 = _283._m15[_9215] * float4((in.m_3037 + (_3664 * (_9338 * _283._m25.x))) + (_9249 * (_9338 * _283._m25.y)), 1.0);
                            float _9364 = _9362.w;
                            if (_9364 <= 0.0)
                            {
                                _21883 = 1.0;
                                break;
                            }
                            float3 _9373 = _9362.xyz / float3(_9364);
                            float _9375 = _9373.x;
                            bool _9376 = _9375 < 0.0;
                            bool _9383;
                            if (!_9376)
                            {
                                _9383 = _9375 > 1.0;
                            }
                            else
                            {
                                _9383 = _9376;
                            }
                            bool _9390;
                            if (!_9383)
                            {
                                _9390 = _9373.y < 0.0;
                            }
                            else
                            {
                                _9390 = _9383;
                            }
                            bool _9397;
                            if (!_9390)
                            {
                                _9397 = _9373.y > 1.0;
                            }
                            else
                            {
                                _9397 = _9390;
                            }
                            bool _9404;
                            if (!_9397)
                            {
                                _9404 = _9373.z > 1.0;
                            }
                            else
                            {
                                _9404 = _9397;
                            }
                            if (_9404)
                            {
                                _21883 = 1.0;
                                break;
                            }
                            float _9410 = _9373.z;
                            float2 _9576 = _283._m22.xy * 0.5;
                            float2 _9581 = _283._m26[_9215].xy + (_9373.xy * _283._m23.zw);
                            float4 _9594 = float4(_283._m26[_9215].xy + _9576, (_283._m26[_9215].xy + _283._m23.zw) - _9576);
                            float _21882;
                            do
                            {
                                int _9620 = int(_283._m22.z);
                                if (_9620 <= 0)
                                {
                                    float2 _9630 = fast::clamp(_9581, _9594.xy, _9594.zw);
                                    _21882 = spvDepthCast(_303).sample_compare(_303Smplr, float3(_9630, _9410).xy, _9410);
                                    break;
                                }
                                float2 _9643 = (_9581 / _283._m22.xy) + float2(0.5);
                                float2 _9644 = floor(_9643);
                                float2 _9649 = _9643 - _9644;
                                float2 _9652 = _9644 - float2(0.5);
                                bool _9656 = _9620 == 1;
                                if (_9656)
                                {
                                    float2 _9659 = _9649 * 2.0;
                                    _9604[0] = float2(3.0) - _9659;
                                    _9604[1] = float2(1.0) + _9659;
                                    _9605[0] = ((float2(2.0) - _9649) / _9604[0]) - float2(1.0);
                                    _9605[1] = (_9649 / _9604[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _9686 = _9649 * 3.0;
                                    _9604[0] = float2(4.0) - _9686;
                                    _9604[1] = float2(7.0);
                                    _9604[2] = float2(1.0) + _9686;
                                    _9605[0] = ((float2(3.0) - (_9649 * 2.0)) / _9604[0]) - float2(2.0);
                                    _9605[1] = (float2(3.0) + _9649) / _9604[1];
                                    _9605[2] = (_9649 / _9604[2]) + float2(2.0);
                                }
                                int _22123 = _9656 ? 2 : 3;
                                int _21872;
                                float _21875;
                                _21875 = 0.0;
                                _21872 = 0;
                                float _21881;
                                for (; _21872 < _22123; _21875 = _21881, _21872++)
                                {
                                    _21881 = _21875;
                                    for (int _21878 = 0; _21878 < _22123; )
                                    {
                                        _21881 += ((_9604[_21878].x * _9604[_21872].y) * spvDepthCast(_303).sample_compare(_303Smplr, float3(fast::clamp(_283._m22.xy * (_9652 + float2(_9605[_21878].x, _9605[_21872].y)), _9594.xy, _9594.zw), _9410).xy, _9410));
                                        _21878++;
                                        continue;
                                    }
                                }
                                _21882 = _21875 * (_9656 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _21883 = _21882;
                            break;
                        }
                        uint _9420 = _9215 - _9316;
                        if (_9420 >= uint(_283._m21.w))
                        {
                            _21883 = 1.0;
                            break;
                        }
                        float _9441 = _283._m27[_9420].w * length(in.m_3037 - _283._m27[_9420].xyz);
                        float3 _9459 = ((in.m_3037 + (_3664 * (_9441 * _283._m25.x))) + (_9249 * (_9441 * _283._m25.y))) - _283._m27[_9420].xyz;
                        float3 _9461 = abs(_9459);
                        float _9463 = _9461.x;
                        float _9465 = _9461.y;
                        bool _9466 = _9463 >= _9465;
                        bool _9474;
                        if (_9466)
                        {
                            _9474 = _9463 >= _9461.z;
                        }
                        else
                        {
                            _9474 = _9466;
                        }
                        float _21857;
                        int _21859;
                        if (_9474)
                        {
                            _21859 = (_9459.x > 0.0) ? 0 : 1;
                            _21857 = _9463;
                        }
                        else
                        {
                            float _9486 = _9461.z;
                            bool _9487 = _9465 >= _9486;
                            int _21860;
                            if (_9487)
                            {
                                _21860 = (_9459.y > 0.0) ? 2 : 3;
                            }
                            else
                            {
                                _21860 = (_9459.z > 0.0) ? 4 : 5;
                            }
                            _21859 = _21860;
                            _21857 = _9487 ? _9465 : _9486;
                        }
                        if (_21857 <= 0.0)
                        {
                            _21883 = 1.0;
                            break;
                        }
                        float2 _9524 = float2(dot(_9459, _961[_21859]), dot(_9459, _970[_21859])) / float2(_21857 * _283._m24.z);
                        float _9531 = _283._m28[_9420].z + (_283._m28[_9420].w / _21857);
                        if (_9531 > 1.0)
                        {
                            _21883 = 1.0;
                            break;
                        }
                        float2 _9549 = _283._m28[_9420].xy + (float2(float(spvSMod(_21859, 3)), float(_21859 / 3)) * _283._m24.xy);
                        float2 _9789 = _283._m22.xy * 0.5;
                        float2 _9794 = _9549 + (float2(0.5 + (0.5 * _9524.x), 0.5 - (0.5 * _9524.y)) * _283._m24.xy);
                        float4 _9807 = float4(_9549 + _9789, (_9549 + _283._m24.xy) - _9789);
                        float _21871;
                        do
                        {
                            int _9833 = int(_283._m22.z);
                            if (_9833 <= 0)
                            {
                                _21871 = spvDepthCast(_303).sample_compare(_303Smplr, float3(fast::clamp(_9794, _9807.xy, _9807.zw), _9531).xy, _9531);
                                break;
                            }
                            float2 _9856 = (_9794 / _283._m22.xy) + float2(0.5);
                            float2 _9857 = floor(_9856);
                            float2 _9862 = _9856 - _9857;
                            float2 _9865 = _9857 - float2(0.5);
                            bool _9869 = _9833 == 1;
                            if (_9869)
                            {
                                float2 _9872 = _9862 * 2.0;
                                _9817[0] = float2(3.0) - _9872;
                                _9817[1] = float2(1.0) + _9872;
                                _9818[0] = ((float2(2.0) - _9862) / _9817[0]) - float2(1.0);
                                _9818[1] = (_9862 / _9817[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _9899 = _9862 * 3.0;
                                _9817[0] = float2(4.0) - _9899;
                                _9817[1] = float2(7.0);
                                _9817[2] = float2(1.0) + _9899;
                                _9818[0] = ((float2(3.0) - (_9862 * 2.0)) / _9817[0]) - float2(2.0);
                                _9818[1] = (float2(3.0) + _9862) / _9817[1];
                                _9818[2] = (_9862 / _9817[2]) + float2(2.0);
                            }
                            int _22126 = _9869 ? 2 : 3;
                            int _21861;
                            float _21864;
                            _21864 = 0.0;
                            _21861 = 0;
                            float _21870;
                            for (; _21861 < _22126; _21864 = _21870, _21861++)
                            {
                                _21870 = _21864;
                                for (int _21867 = 0; _21867 < _22126; )
                                {
                                    _21870 += ((_9817[_21867].x * _9817[_21861].y) * spvDepthCast(_303).sample_compare(_303Smplr, float3(fast::clamp(_283._m22.xy * (_9865 + float2(_9818[_21867].x, _9818[_21861].y)), _9807.xy, _9807.zw), _9531).xy, _9531));
                                    _21867++;
                                    continue;
                                }
                            }
                            _21871 = _21864 * (_9869 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _21883 = _21871;
                        break;
                    } while(false);
                    _21934 = _9280 * _21883;
                }
                else
                {
                    _21934 = _9280;
                }
                float _3873 = dot(_21039, _9249);
                _3902 = _21719 + (((_21033 * fast::max(_3873, 0.0)) * _21934) + (_21934 * ((powr(fast::max(dot(_21039, fast::normalize(_9249 + _3653)), 0.0), _2876._m1.w) * _2876._m1.z) * step(0.0, _3873))));
            }
            _21717 = _21719;
        }
        else
        {
            _21717 = _21718;
        }
        _21716 = _21717;
    }
    else
    {
        float4 _3912 = _3907.sample(_2533, _3419);
        float _3923 = fast::clamp((_2876._m4.x * _3912.z) * in.m_3919.y, 0.0, 1.0);
        float _3934 = fast::clamp((_2876._m4.y * _3912.y) * in.m_3919.x, 0.04500000178813934326171875, 1.0);
        float _21029;
        float _21034;
        if (_20970 > 0.0)
        {
            _21034 = mix(_3923, _21003.y, _20970);
            _21029 = mix(_3934, fast::max(_21003.x, 0.04500000178813934326171875), _20970);
        }
        else
        {
            _21034 = _3923;
            _21029 = _3934;
        }
        float _3953 = _21029 * _21029;
        float3 _3958 = _21033 * (1.0 - _21034);
        float3 _3964 = mix(float3(0.039999999105930328369140625), _21033, float3(_21034));
        bool _3968 = _20849 > 0.0;
        float3 _21062;
        if (_3968)
        {
            float3 _3973 = dfdx(in.m_3037);
            float3 _3975 = dfdy(in.m_3037);
            float3 _3976 = cross(_3973, _3975);
            float3 _21063;
            if (dot(_3976, _3976) > 9.9999996826552253889678874634872e-21)
            {
                _21063 = fast::normalize((fast::normalize(_3976) * ((dot(_3976, _3653) < 0.0) ? (-1.0) : 1.0)) + (_21039 - _3509));
            }
            else
            {
                _21063 = _21039;
            }
            _21062 = _21063;
        }
        else
        {
            _21062 = _21039;
        }
        float _4002 = fast::max(dot(_21062, _3653), 9.9999997473787516355514526367188e-05);
        float _4011 = dot(_21062, _3646);
        float _4012 = fast::clamp(_4011, 0.0, 1.0);
        float _4017 = fast::clamp(dot(_21062, _3658), 0.0, 1.0);
        float _4022 = fast::clamp(dot(_3653, _3658), 0.0, 1.0);
        float _21066;
        float _21067;
        if (_3968)
        {
            _21067 = fast::max(_4002, 0.5);
            _21066 = fast::max(_4022, 0.5);
        }
        else
        {
            _21067 = _4002;
            _21066 = _4022;
        }
        float3 _10001 = float3(1.0) - _3964;
        float3 _10004 = _3964 + (_10001 * powr(1.0 - _21066, 5.0));
        float _10011 = _3953 * _3953;
        float _10016 = _10011 - 1.0;
        float _10018 = ((_4017 * _4017) * _10016) + 1.0;
        float _10038 = 1.0 - _10011;
        float _10042 = sqrt(((_21067 * _21067) * _10038) + _10011);
        float3 _4068 = (((((float3(1.0) - _10004) * _3958) * fast::clamp(dot(_21039, _3646), 0.0, 1.0)) + (((_10004 * ((_10011 / ((3.1415927410125732421875 * _10018) * _10018)) * (0.5 / fast::max((_4012 * _10042) + (_21067 * sqrt(((_4012 * _4012) * _10038) + _10011)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875) * _4012)) * _3695) * _21073;
        float3 _21177;
        if (_3968)
        {
            _21177 = _4068 + (((((_3958 * _3695) * _21073) * _20849) * fast::clamp(-_4011, 0.0, 1.0)) * (0.3499999940395355224609375 + (0.64999997615814208984375 * powr(fast::clamp(dot(-_3653, _3646), 0.0, 1.0), 3.0))));
        }
        else
        {
            _21177 = _4068;
        }
        bool _4103 = _283._m29.x > 0.5;
        float3 _21103;
        float2 _21127;
        float3 _21139;
        if (_4103)
        {
            float4 _10075 = _2632.sample(_2634, (((float2(_21067, _21029) * 31.0) + float2(0.5)) * float2(0.03125)));
            float _10134 = (_283._m29.z * _21039.x) - (_283._m29.w * _21039.z);
            float _10147 = (_283._m29.w * _21039.x) + (_283._m29.z * _21039.z);
            float _10165 = 1.09254801273345947265625 * _10134;
            spvUnsafeArray<float, 9> _19248 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _21039.y, 0.48860299587249755859375 * _10147, 0.48860299587249755859375 * _10134, _10165 * _21039.y, (1.09254801273345947265625 * _21039.y) * _10147, 0.3153919875621795654296875 * (((3.0 * _10147) * _10147) - 1.0), _10165 * _10147, 0.546274006366729736328125 * ((_10134 * _10134) - (_21039.y * _21039.y)) });
            spvUnsafeArray<float, 9> _10079 = _19248;
            float3 _21085;
            _21085 = float3(0.0);
            for (int _21084 = 0; _21084 < 9; )
            {
                _21085 += (_2531.read(uint2((int2(496, 256) + int2(_21084, 0))), 0).xyz * _10079[_21084]);
                _21084++;
                continue;
            }
            float3 _4120 = reflect(-_3653, _21062);
            float _10260 = _4120.x;
            float _10265 = _4120.z;
            float2 _10297 = float2((precise::atan2((_283._m29.z * _10260) - (_283._m29.w * _10265), -((_283._m29.w * _10260) + (_283._m29.z * _10265))) * 0.15915493667125701904296875) + 0.5, acos(fast::clamp(_4120.y, -1.0, 1.0)) * 0.3183098733425140380859375);
            float _10229 = _21029 * 5.0;
            int _10232 = min(int(_10229), 4);
            float2 _10318 = (_10297 * float2(_2588[_10232].zw)) - float2(0.5);
            float2 _10320 = floor(_10318);
            float2 _10323 = _10318 - _10320;
            int _10326 = int(_10320.x);
            int _10329 = int(_10320.y);
            int _21088;
            if (_10326 < 0)
            {
                _21088 = _10326 + _2588[_10232].z;
            }
            else
            {
                _21088 = _10326;
            }
            int _21089;
            if (_21088 >= _2588[_10232].z)
            {
                _21089 = _21088 - _2588[_10232].z;
            }
            else
            {
                _21089 = _21088;
            }
            int _10349 = _21089 + 1;
            int _22127 = (_10349 == _2588[_10232].z) ? 0 : _10349;
            int _10364 = min((_10329 + 1), (_2588[_10232].w - 1));
            int _10366 = max(_10329, 0);
            float3 _10419 = float3(_10323.x);
            int _10239 = _10232 + 1;
            float2 _10451 = (_10297 * float2(_2588[_10239].zw)) - float2(0.5);
            float2 _10453 = floor(_10451);
            float2 _10456 = _10451 - _10453;
            int _10459 = int(_10453.x);
            int _10462 = int(_10453.y);
            int _21095;
            if (_10459 < 0)
            {
                _21095 = _10459 + _2588[_10239].z;
            }
            else
            {
                _21095 = _10459;
            }
            int _21096;
            if (_21095 >= _2588[_10239].z)
            {
                _21096 = _21095 - _2588[_10239].z;
            }
            else
            {
                _21096 = _21095;
            }
            int _10482 = _21096 + 1;
            int _22128 = (_10482 == _2588[_10239].z) ? 0 : _10482;
            int _10497 = min((_10462 + 1), (_2588[_10239].w - 1));
            int _10499 = max(_10462, 0);
            float3 _10552 = float3(_10456.x);
            float3 _10254 = mix(mix(mix(_2531.read(uint2((_2588[_10232].xy + int2(_21089, _10366))), 0).xyz, _2531.read(uint2((_2588[_10232].xy + int2(_22127, _10366))), 0).xyz, _10419), mix(_2531.read(uint2((_2588[_10232].xy + int2(_21089, _10364))), 0).xyz, _2531.read(uint2((_2588[_10232].xy + int2(_22127, _10364))), 0).xyz, _10419), float3(_10323.y)), mix(mix(_2531.read(uint2((_2588[_10239].xy + int2(_21096, _10499))), 0).xyz, _2531.read(uint2((_2588[_10239].xy + int2(_22128, _10499))), 0).xyz, _10552), mix(_2531.read(uint2((_2588[_10239].xy + int2(_21096, _10497))), 0).xyz, _2531.read(uint2((_2588[_10239].xy + int2(_22128, _10497))), 0).xyz, _10552), float3(_10456.y)), float3(_10229 - float(_10232))) * _283._m29.y;
            _21139 = fast::max(_21085, float3(0.0)) * _283._m29.y;
            _21127 = _10075.xy;
            _21103 = _10254;
        }
        else
        {
            float4 _10570 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * _21029) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);
            float _10572 = _10570.x;
            float3 _10607 = mix(_283._m9.xyz, _283._m8.xyz, float3((_21039.y * 0.5) + 0.5)) * _283._m8.w;
            _21139 = _10607;
            _21127 = (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_10572 * _10572, exp2((-9.27999973297119140625) * _21067)) * _10572) + _10570.y)) + _10570.zw;
            _21103 = mix(mix(_283._m9.xyz, _283._m8.xyz, float3((reflect(-_3653, _21062).y * 0.5) + 0.5)) * _283._m8.w, _10607, float3(_21029));
        }
        bool _4152;
        if (_3699)
        {
            _4152 = _283._m33.z > 0.5;
        }
        else
        {
            _4152 = _3699;
        }
        float3 _21148;
        if (_4152)
        {
            float3 _21124;
            do
            {
                float _10686 = ((_283._m32.x * (1.0 - smoothstep(_283._m33.x * 0.5, _283._m33.x, abs(dot(_283._m31.xyz, in.m_3037) - _283._m31.w)))) * smoothstep(0.5, 0.89999997615814208984375, dot(_3664, _283._m31.xyz))) * (1.0 - smoothstep(_283._m32.y * 0.5, _283._m32.y, _21029));
                if (_10686 <= 0.0)
                {
                    _21124 = _21103;
                    break;
                }
                float4 _10711 = _283._m30 * float4(in.m_3037 + ((_21039 - (_283._m31.xyz * dot(_21039, _283._m31.xyz))) * _283._m32.w), 1.0);
                float2 _10724 = ((float2(_10711.x, -_10711.y) / float2(_10711.w)) * 0.5) + float2(0.5);
                float _10728 = _283._m32.z * _21029;
                float3 _21122;
                float _21123;
                _21123 = 0.0;
                _21122 = float3(0.0);
                for (int _21121 = 0; _21121 < 12; )
                {
                    float _10735 = float(_21121);
                    float _10743 = _10735 * 2.3999631404876708984375;
                    float2 _10755 = _10724 + (float2(cos(_10743) * _283._m33.y, sin(_10743)) * (sqrt((_10735 + 0.5) * 0.083333335816860198974609375) * _10728));
                    float2 _10760 = fast::min(_10755, float2(1.0) - _10755);
                    float _10766 = smoothstep(0.0, 0.039999999105930328369140625, fast::min(_10760.x, _10760.y));
                    float4 _10774 = _3352.sample(_2533, fast::clamp(_10755, float2(0.0), float2(1.0)), level(0.0));
                    float3 _10776 = _10774.xyz;
                    _21123 += (_10774.w * _10766);
                    _21122 += ((_10776 / (float3(1.0) - fast::min(_10776, float3(0.99500000476837158203125)))) * _10766);
                    _21121++;
                    continue;
                }
                _21124 = mix(_21103, (_21122 * float3(0.083333335816860198974609375)) + (_21103 * (1.0 - (_21123 * 0.083333335816860198974609375))), float3(_10686));
                break;
            } while(false);
            _21148 = _21124;
        }
        else
        {
            _21148 = _21103;
        }
        float3 _4172 = (_3964 * _21127.x) + float3(_21127.y);
        float3 _4177 = (float3(1.0) - _4172) * _3958;
        float3 _4188 = _21177 + (((_4177 * _21139) + (_4172 * _21148)) * _21163);
        float3 _21650;
        if ((_283._m34.x + _283._m34.y) > 0.5)
        {
            float3 _21185;
            if (_283._m34.y > 0.5)
            {
                int _10932 = int(_283._m34.y);
                int _10935 = int(_283._m34.x);
                float3 _21184;
                _21184 = _21139;
                float3 _21976;
                for (int _21183 = 0; _21183 < _10932; _21184 = _21976, _21183++)
                {
                    int _10947 = 8 * (_10935 + _21183);
                    float4 _11156 = as_type<float4>(_1281._m0[_10947 + 3]);
                    float4 _11200 = as_type<float4>(_1281._m0[_10947]);
                    float4 _11206 = as_type<float4>(_1281._m0[_10947 + 1]);
                    float4 _11212 = as_type<float4>(_1281._m0[_10947 + 2]);
                    float3 _11174 = _11200.xyz;
                    float _11178 = _11200.w;
                    float3 _11181 = _11206.xyz;
                    float _11185 = _11206.w;
                    float3 _11188 = _11212.xyz;
                    float _11192 = _11212.w;
                    float3 _11194 = float3(dot(_11174, in.m_3037) + _11178, dot(_11181, in.m_3037) + _11185, dot(_11188, in.m_3037) + _11192);
                    float3 _10956 = _11156.xyz;
                    float _10958 = _11156.w;
                    float _21684;
                    do
                    {
                        float3 _11224 = _10956 - abs(_11194);
                        float _11232 = fast::min(_11224.x, fast::min(_11224.y, _11224.z));
                        if (_11232 <= 0.0)
                        {
                            _21684 = 0.0;
                            break;
                        }
                        if (_10958 <= 0.0)
                        {
                            _21684 = 1.0;
                            break;
                        }
                        float _11244 = fast::min(_11232 / _10958, 1.0);
                        _21684 = (_11244 * _11244) * (3.0 - (2.0 * _11244));
                        break;
                    } while(false);
                    if (_21684 <= 0.0)
                    {
                        _21976 = _21184;
                        continue;
                    }
                    float3 _10967 = as_type<float4>(_1281._m0[_10947 + 4]).xyz;
                    float4 _11265 = as_type<float4>(_1281._m0[_10947 + 5]);
                    int _11271 = int(((device uint*)&_1281._m0[_10947 + 6])[0u]);
                    float _11281 = dot(_11174, _21039);
                    float _11287 = dot(_11181, _21039);
                    float _11293 = dot(_11188, _21039);
                    float3 _11294 = float3(_11281, _11287, _11293);
                    float3 _10987 = (in.m_3037 + (_21039 * _11265.x)) + (_3653 * _11265.y);
                    float3 _11006 = fast::clamp((((float3(dot(_11174, _10987) + _11178, dot(_11181, _10987) + _11185, dot(_11188, _10987) + _11192) + _10956) / fast::max(_10956 * 2.0, float3(9.9999999747524270787835121154785e-07))) * _10967) - float3(0.5), float3(0.0), _10967 - float3(1.0));
                    int3 _11008 = int3(_10967);
                    int3 _11015 = min(int3(_11006), max((_11008 - int3(2)), int3(0)));
                    float3 _11019 = _11006 - float3(_11015);
                    float _11374 = 0.48860299587249755859375 * _11287;
                    float _11377 = 0.48860299587249755859375 * _11293;
                    float _11380 = 0.48860299587249755859375 * _11281;
                    float _11385 = 1.09254801273345947265625 * _11281;
                    float _11388 = _11385 * _11287;
                    float _11394 = (1.09254801273345947265625 * _11287) * _11293;
                    float _11402 = 0.3153919875621795654296875 * (((3.0 * _11293) * _11293) - 1.0);
                    float _11408 = _11385 * _11293;
                    float _11422 = 0.546274006366729736328125 * ((_11281 * _11281) - (_11287 * _11287));
                    int3 _11441 = _11008 - int3(1);
                    int3 _11442 = min(_11015, _11441);
                    int _11447 = _11008.x;
                    int _11451 = _11008.y;
                    int _11459 = _11271 + ((_11442.x + (_11447 * (_11442.y + (_11451 * _11442.z)))) * 4);
                    float3 _11462 = float3(1.0) - _11019;
                    float3 _11480 = (((((float3(_11442) + float3(0.5)) / _10967) * _10956) * 2.0) - _10956) - _11194;
                    float _11490 = dot(_11480 * rsqrt(fast::max(dot(_11480, _11480), 1.0000000133514319600180897396058e-10)), _11294) + 1.0;
                    float _11493 = _11462.x;
                    float _11495 = _11462.y;
                    float _11496 = _11493 * _11495;
                    float _11498 = _11462.z;
                    int _11522 = _11459 + 3;
                    float _11508 = ((_11496 * _11498) * ((0.25 * (_11490 * _11490)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_11522])[1u])).y > 0.5);
                    int _11552 = _11459 + 1;
                    int _11556 = _11459 + 2;
                    float2 _11568 = float2(as_type<half2>(_1281._m0[_11459].y));
                    float2 _11577 = float2(as_type<half2>(_1281._m0[_11552].x));
                    float2 _11586 = float2(as_type<half2>(_1281._m0[_11552].w));
                    float2 _11595 = float2(as_type<half2>(_1281._m0[_11556].z));
                    float3 _11683 = (((((((float3(float2(as_type<half2>(_1281._m0[_11459].x)), _11568.x) * 0.2820949852466583251953125) + (float3(_11568.y, float2(as_type<half2>(_1281._m0[_11459].z))) * _11374)) + (float3(float2(as_type<half2>(_1281._m0[_11459].w)), _11577.x) * _11377)) + (float3(_11577.y, float2(as_type<half2>(_1281._m0[_11552].y))) * _11380)) + (float3(float2(as_type<half2>(_1281._m0[_11552].z)), _11586.x) * _11388)) + (float3(_11586.y, float2(as_type<half2>(_1281._m0[_11556].x))) * _11394)) + (float3(float2(as_type<half2>(_1281._m0[_11556].y)), _11595.x) * _11402)) + (float3(_11595.y, float2(as_type<half2>(_1281._m0[_11556].w))) * _11408);
                    int3 _11711 = min((_11015 + int3(1, 0, 0)), _11441);
                    int _11728 = _11271 + ((_11711.x + (_11447 * (_11711.y + (_11451 * _11711.z)))) * 4);
                    float3 _11749 = (((((float3(_11711) + float3(0.5)) / _10967) * _10956) * 2.0) - _10956) - _11194;
                    float _11759 = dot(_11749 * rsqrt(fast::max(dot(_11749, _11749), 1.0000000133514319600180897396058e-10)), _11294) + 1.0;
                    float _11765 = _11019.x * _11495;
                    int _11791 = _11728 + 3;
                    float _11777 = ((_11765 * _11498) * ((0.25 * (_11759 * _11759)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_11791])[1u])).y > 0.5);
                    int _11821 = _11728 + 1;
                    int _11825 = _11728 + 2;
                    float2 _11837 = float2(as_type<half2>(_1281._m0[_11728].y));
                    float2 _11846 = float2(as_type<half2>(_1281._m0[_11821].x));
                    float2 _11855 = float2(as_type<half2>(_1281._m0[_11821].w));
                    float2 _11864 = float2(as_type<half2>(_1281._m0[_11825].z));
                    float3 _11952 = (((((((float3(float2(as_type<half2>(_1281._m0[_11728].x)), _11837.x) * 0.2820949852466583251953125) + (float3(_11837.y, float2(as_type<half2>(_1281._m0[_11728].z))) * _11374)) + (float3(float2(as_type<half2>(_1281._m0[_11728].w)), _11846.x) * _11377)) + (float3(_11846.y, float2(as_type<half2>(_1281._m0[_11821].y))) * _11380)) + (float3(float2(as_type<half2>(_1281._m0[_11821].z)), _11855.x) * _11388)) + (float3(_11855.y, float2(as_type<half2>(_1281._m0[_11825].x))) * _11394)) + (float3(float2(as_type<half2>(_1281._m0[_11825].y)), _11864.x) * _11402)) + (float3(_11864.y, float2(as_type<half2>(_1281._m0[_11825].w))) * _11408);
                    int3 _11980 = min((_11015 + int3(0, 1, 0)), _11441);
                    int _11997 = _11271 + ((_11980.x + (_11447 * (_11980.y + (_11451 * _11980.z)))) * 4);
                    float3 _12018 = (((((float3(_11980) + float3(0.5)) / _10967) * _10956) * 2.0) - _10956) - _11194;
                    float _12028 = dot(_12018 * rsqrt(fast::max(dot(_12018, _12018), 1.0000000133514319600180897396058e-10)), _11294) + 1.0;
                    float _12034 = _11493 * _11019.y;
                    int _12060 = _11997 + 3;
                    float _12046 = ((_12034 * _11498) * ((0.25 * (_12028 * _12028)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_12060])[1u])).y > 0.5);
                    int _12090 = _11997 + 1;
                    int _12094 = _11997 + 2;
                    float2 _12106 = float2(as_type<half2>(_1281._m0[_11997].y));
                    float2 _12115 = float2(as_type<half2>(_1281._m0[_12090].x));
                    float2 _12124 = float2(as_type<half2>(_1281._m0[_12090].w));
                    float2 _12133 = float2(as_type<half2>(_1281._m0[_12094].z));
                    float3 _12221 = (((((((float3(float2(as_type<half2>(_1281._m0[_11997].x)), _12106.x) * 0.2820949852466583251953125) + (float3(_12106.y, float2(as_type<half2>(_1281._m0[_11997].z))) * _11374)) + (float3(float2(as_type<half2>(_1281._m0[_11997].w)), _12115.x) * _11377)) + (float3(_12115.y, float2(as_type<half2>(_1281._m0[_12090].y))) * _11380)) + (float3(float2(as_type<half2>(_1281._m0[_12090].z)), _12124.x) * _11388)) + (float3(_12124.y, float2(as_type<half2>(_1281._m0[_12094].x))) * _11394)) + (float3(float2(as_type<half2>(_1281._m0[_12094].y)), _12133.x) * _11402)) + (float3(_12133.y, float2(as_type<half2>(_1281._m0[_12094].w))) * _11408);
                    int3 _12249 = min((_11015 + int3(1, 1, 0)), _11441);
                    int _12266 = _11271 + ((_12249.x + (_11447 * (_12249.y + (_11451 * _12249.z)))) * 4);
                    float3 _12287 = (((((float3(_12249) + float3(0.5)) / _10967) * _10956) * 2.0) - _10956) - _11194;
                    float _12297 = dot(_12287 * rsqrt(fast::max(dot(_12287, _12287), 1.0000000133514319600180897396058e-10)), _11294) + 1.0;
                    float _12303 = _11019.x * _11019.y;
                    int _12329 = _12266 + 3;
                    float _12315 = ((_12303 * _11498) * ((0.25 * (_12297 * _12297)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_12329])[1u])).y > 0.5);
                    int _12359 = _12266 + 1;
                    int _12363 = _12266 + 2;
                    float2 _12375 = float2(as_type<half2>(_1281._m0[_12266].y));
                    float2 _12384 = float2(as_type<half2>(_1281._m0[_12359].x));
                    float2 _12393 = float2(as_type<half2>(_1281._m0[_12359].w));
                    float2 _12402 = float2(as_type<half2>(_1281._m0[_12363].z));
                    float3 _12490 = (((((((float3(float2(as_type<half2>(_1281._m0[_12266].x)), _12375.x) * 0.2820949852466583251953125) + (float3(_12375.y, float2(as_type<half2>(_1281._m0[_12266].z))) * _11374)) + (float3(float2(as_type<half2>(_1281._m0[_12266].w)), _12384.x) * _11377)) + (float3(_12384.y, float2(as_type<half2>(_1281._m0[_12359].y))) * _11380)) + (float3(float2(as_type<half2>(_1281._m0[_12359].z)), _12393.x) * _11388)) + (float3(_12393.y, float2(as_type<half2>(_1281._m0[_12363].x))) * _11394)) + (float3(float2(as_type<half2>(_1281._m0[_12363].y)), _12402.x) * _11402)) + (float3(_12402.y, float2(as_type<half2>(_1281._m0[_12363].w))) * _11408);
                    int3 _12518 = min((_11015 + int3(0, 0, 1)), _11441);
                    int _12535 = _11271 + ((_12518.x + (_11447 * (_12518.y + (_11451 * _12518.z)))) * 4);
                    float3 _12556 = (((((float3(_12518) + float3(0.5)) / _10967) * _10956) * 2.0) - _10956) - _11194;
                    float _12566 = dot(_12556 * rsqrt(fast::max(dot(_12556, _12556), 1.0000000133514319600180897396058e-10)), _11294) + 1.0;
                    int _12598 = _12535 + 3;
                    float _12584 = ((_11496 * _11019.z) * ((0.25 * (_12566 * _12566)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_12598])[1u])).y > 0.5);
                    int _12628 = _12535 + 1;
                    int _12632 = _12535 + 2;
                    float2 _12644 = float2(as_type<half2>(_1281._m0[_12535].y));
                    float2 _12653 = float2(as_type<half2>(_1281._m0[_12628].x));
                    float2 _12662 = float2(as_type<half2>(_1281._m0[_12628].w));
                    float2 _12671 = float2(as_type<half2>(_1281._m0[_12632].z));
                    float3 _12759 = (((((((float3(float2(as_type<half2>(_1281._m0[_12535].x)), _12644.x) * 0.2820949852466583251953125) + (float3(_12644.y, float2(as_type<half2>(_1281._m0[_12535].z))) * _11374)) + (float3(float2(as_type<half2>(_1281._m0[_12535].w)), _12653.x) * _11377)) + (float3(_12653.y, float2(as_type<half2>(_1281._m0[_12628].y))) * _11380)) + (float3(float2(as_type<half2>(_1281._m0[_12628].z)), _12662.x) * _11388)) + (float3(_12662.y, float2(as_type<half2>(_1281._m0[_12632].x))) * _11394)) + (float3(float2(as_type<half2>(_1281._m0[_12632].y)), _12671.x) * _11402)) + (float3(_12671.y, float2(as_type<half2>(_1281._m0[_12632].w))) * _11408);
                    float4 _11086 = (((float4((_11683 + (float3(float2(as_type<half2>(_1281._m0[_11522].x)), float2(as_type<half2>(_1281._m0[_11522].y)).x) * _11422)) * _11508, _11508) + float4((_11952 + (float3(float2(as_type<half2>(_1281._m0[_11791].x)), float2(as_type<half2>(_1281._m0[_11791].y)).x) * _11422)) * _11777, _11777)) + float4((_12221 + (float3(float2(as_type<half2>(_1281._m0[_12060].x)), float2(as_type<half2>(_1281._m0[_12060].y)).x) * _11422)) * _12046, _12046)) + float4((_12490 + (float3(float2(as_type<half2>(_1281._m0[_12329].x)), float2(as_type<half2>(_1281._m0[_12329].y)).x) * _11422)) * _12315, _12315)) + float4((_12759 + (float3(float2(as_type<half2>(_1281._m0[_12598].x)), float2(as_type<half2>(_1281._m0[_12598].y)).x) * _11422)) * _12584, _12584);
                    int3 _12787 = min((_11015 + int3(1, 0, 1)), _11441);
                    int _12804 = _11271 + ((_12787.x + (_11447 * (_12787.y + (_11451 * _12787.z)))) * 4);
                    float3 _12825 = (((((float3(_12787) + float3(0.5)) / _10967) * _10956) * 2.0) - _10956) - _11194;
                    float _12835 = dot(_12825 * rsqrt(fast::max(dot(_12825, _12825), 1.0000000133514319600180897396058e-10)), _11294) + 1.0;
                    int _12867 = _12804 + 3;
                    float _12853 = ((_11765 * _11019.z) * ((0.25 * (_12835 * _12835)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_12867])[1u])).y > 0.5);
                    int _12897 = _12804 + 1;
                    int _12901 = _12804 + 2;
                    float2 _12913 = float2(as_type<half2>(_1281._m0[_12804].y));
                    float2 _12922 = float2(as_type<half2>(_1281._m0[_12897].x));
                    float2 _12931 = float2(as_type<half2>(_1281._m0[_12897].w));
                    float2 _12940 = float2(as_type<half2>(_1281._m0[_12901].z));
                    float3 _13028 = (((((((float3(float2(as_type<half2>(_1281._m0[_12804].x)), _12913.x) * 0.2820949852466583251953125) + (float3(_12913.y, float2(as_type<half2>(_1281._m0[_12804].z))) * _11374)) + (float3(float2(as_type<half2>(_1281._m0[_12804].w)), _12922.x) * _11377)) + (float3(_12922.y, float2(as_type<half2>(_1281._m0[_12897].y))) * _11380)) + (float3(float2(as_type<half2>(_1281._m0[_12897].z)), _12931.x) * _11388)) + (float3(_12931.y, float2(as_type<half2>(_1281._m0[_12901].x))) * _11394)) + (float3(float2(as_type<half2>(_1281._m0[_12901].y)), _12940.x) * _11402)) + (float3(_12940.y, float2(as_type<half2>(_1281._m0[_12901].w))) * _11408);
                    int3 _13056 = min((_11015 + int3(0, 1, 1)), _11441);
                    int _13073 = _11271 + ((_13056.x + (_11447 * (_13056.y + (_11451 * _13056.z)))) * 4);
                    float3 _13094 = (((((float3(_13056) + float3(0.5)) / _10967) * _10956) * 2.0) - _10956) - _11194;
                    float _13104 = dot(_13094 * rsqrt(fast::max(dot(_13094, _13094), 1.0000000133514319600180897396058e-10)), _11294) + 1.0;
                    int _13136 = _13073 + 3;
                    float _13122 = ((_12034 * _11019.z) * ((0.25 * (_13104 * _13104)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_13136])[1u])).y > 0.5);
                    int _13166 = _13073 + 1;
                    int _13170 = _13073 + 2;
                    float2 _13182 = float2(as_type<half2>(_1281._m0[_13073].y));
                    float2 _13191 = float2(as_type<half2>(_1281._m0[_13166].x));
                    float2 _13200 = float2(as_type<half2>(_1281._m0[_13166].w));
                    float2 _13209 = float2(as_type<half2>(_1281._m0[_13170].z));
                    float3 _13297 = (((((((float3(float2(as_type<half2>(_1281._m0[_13073].x)), _13182.x) * 0.2820949852466583251953125) + (float3(_13182.y, float2(as_type<half2>(_1281._m0[_13073].z))) * _11374)) + (float3(float2(as_type<half2>(_1281._m0[_13073].w)), _13191.x) * _11377)) + (float3(_13191.y, float2(as_type<half2>(_1281._m0[_13166].y))) * _11380)) + (float3(float2(as_type<half2>(_1281._m0[_13166].z)), _13200.x) * _11388)) + (float3(_13200.y, float2(as_type<half2>(_1281._m0[_13170].x))) * _11394)) + (float3(float2(as_type<half2>(_1281._m0[_13170].y)), _13209.x) * _11402)) + (float3(_13209.y, float2(as_type<half2>(_1281._m0[_13170].w))) * _11408);
                    int3 _13325 = min((_11015 + int3(1)), _11441);
                    int _13342 = _11271 + ((_13325.x + (_11447 * (_13325.y + (_11451 * _13325.z)))) * 4);
                    float3 _13363 = (((((float3(_13325) + float3(0.5)) / _10967) * _10956) * 2.0) - _10956) - _11194;
                    float _13373 = dot(_13363 * rsqrt(fast::max(dot(_13363, _13363), 1.0000000133514319600180897396058e-10)), _11294) + 1.0;
                    int _13405 = _13342 + 3;
                    float _13391 = ((_12303 * _11019.z) * ((0.25 * (_13373 * _13373)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_13405])[1u])).y > 0.5);
                    int _13435 = _13342 + 1;
                    int _13439 = _13342 + 2;
                    float2 _13451 = float2(as_type<half2>(_1281._m0[_13342].y));
                    float2 _13460 = float2(as_type<half2>(_1281._m0[_13435].x));
                    float2 _13469 = float2(as_type<half2>(_1281._m0[_13435].w));
                    float2 _13478 = float2(as_type<half2>(_1281._m0[_13439].z));
                    float3 _13566 = (((((((float3(float2(as_type<half2>(_1281._m0[_13342].x)), _13451.x) * 0.2820949852466583251953125) + (float3(_13451.y, float2(as_type<half2>(_1281._m0[_13342].z))) * _11374)) + (float3(float2(as_type<half2>(_1281._m0[_13342].w)), _13460.x) * _11377)) + (float3(_13460.y, float2(as_type<half2>(_1281._m0[_13435].y))) * _11380)) + (float3(float2(as_type<half2>(_1281._m0[_13435].z)), _13469.x) * _11388)) + (float3(_13469.y, float2(as_type<half2>(_1281._m0[_13439].x))) * _11394)) + (float3(float2(as_type<half2>(_1281._m0[_13439].y)), _13478.x) * _11402)) + (float3(_13478.y, float2(as_type<half2>(_1281._m0[_13439].w))) * _11408);
                    float4 _11125 = ((_11086 + float4((_13028 + (float3(float2(as_type<half2>(_1281._m0[_12867].x)), float2(as_type<half2>(_1281._m0[_12867].y)).x) * _11422)) * _12853, _12853)) + float4((_13297 + (float3(float2(as_type<half2>(_1281._m0[_13136].x)), float2(as_type<half2>(_1281._m0[_13136].y)).x) * _11422)) * _13122, _13122)) + float4((_13566 + (float3(float2(as_type<half2>(_1281._m0[_13405].x)), float2(as_type<half2>(_1281._m0[_13405].y)).x) * _11422)) * _13391, _13391);
                    float _11129 = _11125.w;
                    float3 _21977;
                    if (_11129 > 9.9999997473787516355514526367188e-06)
                    {
                        _21977 = mix(_21184, (fast::max(_11125.xyz, float3(0.0)) / float3(_11129)) * _11265.z, float3(_21684));
                    }
                    else
                    {
                        _21977 = _21184;
                    }
                    _21976 = _21977;
                }
                _21185 = _21184;
            }
            else
            {
                _21185 = _21139;
            }
            float3 _21413;
            if (_283._m34.x > 0.5)
            {
                float3 _21222;
                if (_4103)
                {
                    float3 _4233 = reflect(-_3653, _21062);
                    float _13631 = _4233.x;
                    float _13636 = _4233.z;
                    float2 _13668 = float2((precise::atan2((_283._m29.z * _13631) - (_283._m29.w * _13636), -((_283._m29.w * _13631) + (_283._m29.z * _13636))) * 0.15915493667125701904296875) + 0.5, acos(fast::clamp(_4233.y, -1.0, 1.0)) * 0.3183098733425140380859375);
                    float _13600 = _21029 * 5.0;
                    int _13603 = min(int(_13600), 4);
                    float2 _13689 = (_13668 * float2(_2588[_13603].zw)) - float2(0.5);
                    float2 _13691 = floor(_13689);
                    float2 _13694 = _13689 - _13691;
                    int _13697 = int(_13691.x);
                    int _13700 = int(_13691.y);
                    int _21208;
                    if (_13697 < 0)
                    {
                        _21208 = _13697 + _2588[_13603].z;
                    }
                    else
                    {
                        _21208 = _13697;
                    }
                    int _21209;
                    if (_21208 >= _2588[_13603].z)
                    {
                        _21209 = _21208 - _2588[_13603].z;
                    }
                    else
                    {
                        _21209 = _21208;
                    }
                    int _13720 = _21209 + 1;
                    int _22129 = (_13720 == _2588[_13603].z) ? 0 : _13720;
                    int _13735 = min((_13700 + 1), (_2588[_13603].w - 1));
                    int _13737 = max(_13700, 0);
                    float3 _13790 = float3(_13694.x);
                    int _13610 = _13603 + 1;
                    float2 _13822 = (_13668 * float2(_2588[_13610].zw)) - float2(0.5);
                    float2 _13824 = floor(_13822);
                    float2 _13827 = _13822 - _13824;
                    int _13830 = int(_13824.x);
                    int _13833 = int(_13824.y);
                    int _21215;
                    if (_13830 < 0)
                    {
                        _21215 = _13830 + _2588[_13610].z;
                    }
                    else
                    {
                        _21215 = _13830;
                    }
                    int _21216;
                    if (_21215 >= _2588[_13610].z)
                    {
                        _21216 = _21215 - _2588[_13610].z;
                    }
                    else
                    {
                        _21216 = _21215;
                    }
                    int _13853 = _21216 + 1;
                    int _22130 = (_13853 == _2588[_13610].z) ? 0 : _13853;
                    int _13868 = min((_13833 + 1), (_2588[_13610].w - 1));
                    int _13870 = max(_13833, 0);
                    float3 _13923 = float3(_13827.x);
                    float3 _13625 = mix(mix(mix(_2531.read(uint2((_2588[_13603].xy + int2(_21209, _13737))), 0).xyz, _2531.read(uint2((_2588[_13603].xy + int2(_22129, _13737))), 0).xyz, _13790), mix(_2531.read(uint2((_2588[_13603].xy + int2(_21209, _13735))), 0).xyz, _2531.read(uint2((_2588[_13603].xy + int2(_22129, _13735))), 0).xyz, _13790), float3(_13694.y)), mix(mix(_2531.read(uint2((_2588[_13610].xy + int2(_21216, _13870))), 0).xyz, _2531.read(uint2((_2588[_13610].xy + int2(_22130, _13870))), 0).xyz, _13923), mix(_2531.read(uint2((_2588[_13610].xy + int2(_21216, _13868))), 0).xyz, _2531.read(uint2((_2588[_13610].xy + int2(_22130, _13868))), 0).xyz, _13923), float3(_13827.y)), float3(_13600 - float(_13603))) * _283._m29.y;
                    _21222 = _13625;
                }
                else
                {
                    _21222 = mix(mix(_283._m9.xyz, _283._m8.xyz, float3((reflect(-_3653, _21062).y * 0.5) + 0.5)) * _283._m8.w, _21139, float3(_21029));
                }
                float3 _4253 = reflect(-_3653, _21062);
                int _13989 = int(_283._m34.x);
                float _21238;
                float3 _21304;
                _21304 = float3(0.0);
                _21238 = 0.0;
                float _21990;
                float3 _21991;
                for (int _21237 = 0; _21237 < _13989; _21304 = _21991, _21238 = _21990, _21237++)
                {
                    if (_21238 > 0.999000012874603271484375)
                    {
                        break;
                    }
                    int _14001 = _21237 * 8;
                    float4 _14116 = as_type<float4>(_1281._m0[_14001]);
                    float4 _14122 = as_type<float4>(_1281._m0[_14001 + 1]);
                    float4 _14128 = as_type<float4>(_1281._m0[_14001 + 2]);
                    float3 _14090 = _14116.xyz;
                    float3 _14097 = _14122.xyz;
                    float3 _14104 = _14128.xyz;
                    float3 _14110 = float3(dot(_14090, in.m_3037) + _14116.w, dot(_14097, in.m_3037) + _14122.w, dot(_14104, in.m_3037) + _14128.w);
                    float4 _14134 = as_type<float4>(_1281._m0[_14001 + 3]);
                    float _14012 = _14134.w;
                    float _21239;
                    do
                    {
                        float3 _14146 = _14134.xyz - abs(_14110);
                        float _14154 = fast::min(_14146.x, fast::min(_14146.y, _14146.z));
                        if (_14154 <= 0.0)
                        {
                            _21239 = 0.0;
                            break;
                        }
                        if (_14012 <= 0.0)
                        {
                            _21239 = 1.0;
                            break;
                        }
                        float _14166 = fast::min(_14154 / _14012, 1.0);
                        _21239 = (_14166 * _14166) * (3.0 - (2.0 * _14166));
                        break;
                    } while(false);
                    if (_21239 <= 0.0)
                    {
                        _21991 = _21304;
                        _21990 = _21238;
                        continue;
                    }
                    float4 _14181 = as_type<float4>(_1281._m0[_14001 + 4]);
                    float4 _14187 = as_type<float4>(_1281._m0[_14001 + 5]);
                    float3 _14210 = float3(dot(_14090, _4253), dot(_14097, _4253), dot(_14104, _4253));
                    float3 _21241;
                    if (_14181.w > 0.5)
                    {
                        float3 _14034 = _14181.xyz;
                        float3 _14240 = -_14034;
                        float3 _14242 = fast::clamp(_14110, _14240, _14034);
                        float3 _14252 = step(float3(9.9999999747524270787835121154785e-07), abs(_14210));
                        float3 _14262 = mix(float3(1000000015047466219876688855040.0), (mix(_14240, _14034, step(float3(0.0), _14210)) - _14242) / mix(float3(9.9999999747524270787835121154785e-07), _14210, _14252), _14252);
                        float3 _14278 = (_14242 + (_14210 * fast::max(fast::min(_14262.x, fast::min(_14262.y, _14262.z)), 0.0))) - _14187.xyz;
                        float3 _21240;
                        if (dot(_14278, _14278) > 9.9999999600419720025001879548654e-13)
                        {
                            _21240 = fast::normalize(_14278);
                        }
                        else
                        {
                            _21240 = _14210;
                        }
                        _21241 = _21240;
                    }
                    else
                    {
                        _21241 = _14210;
                    }
                    int _14295 = int(((device uint*)&_1281._m0[_14001 + 6])[0u]);
                    float2 _14345 = float2((precise::atan2(_21241.x, -_21241.z) * 0.15915493667125701904296875) + 0.5, acos(fast::clamp(_21241.y, -1.0, 1.0)) * 0.3183098733425140380859375);
                    float _14311 = _21029 * 5.0;
                    int _14314 = min(int(_14311), 4);
                    int _14385 = _14295 + _1353[_14314].x;
                    float2 _14392 = (_14345 * float2(_1353[_14314].yz)) - float2(0.5);
                    float2 _14394 = floor(_14392);
                    float2 _14397 = _14392 - _14394;
                    int _14400 = int(_14394.x);
                    int _14403 = int(_14394.y);
                    int _21242;
                    if (_14400 < 0)
                    {
                        _21242 = _14400 + _1353[_14314].y;
                    }
                    else
                    {
                        _21242 = _14400;
                    }
                    int _21243;
                    if (_21242 >= _1353[_14314].y)
                    {
                        _21243 = _21242 - _1353[_14314].y;
                    }
                    else
                    {
                        _21243 = _21242;
                    }
                    int _14423 = _21243 + 1;
                    int _22131 = (_14423 == _1353[_14314].y) ? 0 : _14423;
                    int _14491 = _14385 + (max(_14403, 0) * _1353[_14314].y);
                    int _14493 = _14491 + _21243;
                    int _14495 = _14493 >> 1;
                    uint2 _21249;
                    if ((_14493 & 1) == 0)
                    {
                        _21249 = _1281._m0[_14495].xy;
                    }
                    else
                    {
                        _21249 = _1281._m0[_14495].zw;
                    }
                    int _14531 = _14491 + _22131;
                    int _14533 = _14531 >> 1;
                    uint2 _21251;
                    if ((_14531 & 1) == 0)
                    {
                        _21251 = _1281._m0[_14533].xy;
                    }
                    else
                    {
                        _21251 = _1281._m0[_14533].zw;
                    }
                    int _14567 = _14385 + (min((_14403 + 1), (_1353[_14314].z - 1)) * _1353[_14314].y);
                    int _14569 = _14567 + _21243;
                    int _14571 = _14569 >> 1;
                    uint2 _21254;
                    if ((_14569 & 1) == 0)
                    {
                        _21254 = _1281._m0[_14571].xy;
                    }
                    else
                    {
                        _21254 = _1281._m0[_14571].zw;
                    }
                    int _14607 = _14567 + _22131;
                    int _14609 = _14607 >> 1;
                    uint2 _21255;
                    if ((_14607 & 1) == 0)
                    {
                        _21255 = _1281._m0[_14609].xy;
                    }
                    else
                    {
                        _21255 = _1281._m0[_14609].zw;
                    }
                    float3 _14469 = float3(_14397.x);
                    int _14320 = _14314 + 1;
                    int _14672 = _14295 + _1353[_14320].x;
                    float2 _14679 = (_14345 * float2(_1353[_14320].yz)) - float2(0.5);
                    float2 _14681 = floor(_14679);
                    float2 _14684 = _14679 - _14681;
                    int _14687 = int(_14681.x);
                    int _14690 = int(_14681.y);
                    int _21256;
                    if (_14687 < 0)
                    {
                        _21256 = _14687 + _1353[_14320].y;
                    }
                    else
                    {
                        _21256 = _14687;
                    }
                    int _21257;
                    if (_21256 >= _1353[_14320].y)
                    {
                        _21257 = _21256 - _1353[_14320].y;
                    }
                    else
                    {
                        _21257 = _21256;
                    }
                    int _14710 = _21257 + 1;
                    int _22132 = (_14710 == _1353[_14320].y) ? 0 : _14710;
                    int _14778 = _14672 + (max(_14690, 0) * _1353[_14320].y);
                    int _14780 = _14778 + _21257;
                    int _14782 = _14780 >> 1;
                    uint2 _21263;
                    if ((_14780 & 1) == 0)
                    {
                        _21263 = _1281._m0[_14782].xy;
                    }
                    else
                    {
                        _21263 = _1281._m0[_14782].zw;
                    }
                    int _14818 = _14778 + _22132;
                    int _14820 = _14818 >> 1;
                    uint2 _21265;
                    if ((_14818 & 1) == 0)
                    {
                        _21265 = _1281._m0[_14820].xy;
                    }
                    else
                    {
                        _21265 = _1281._m0[_14820].zw;
                    }
                    int _14854 = _14672 + (min((_14690 + 1), (_1353[_14320].z - 1)) * _1353[_14320].y);
                    int _14856 = _14854 + _21257;
                    int _14858 = _14856 >> 1;
                    uint2 _21268;
                    if ((_14856 & 1) == 0)
                    {
                        _21268 = _1281._m0[_14858].xy;
                    }
                    else
                    {
                        _21268 = _1281._m0[_14858].zw;
                    }
                    int _14894 = _14854 + _22132;
                    int _14896 = _14894 >> 1;
                    uint2 _21269;
                    if ((_14894 & 1) == 0)
                    {
                        _21269 = _1281._m0[_14896].xy;
                    }
                    else
                    {
                        _21269 = _1281._m0[_14896].zw;
                    }
                    float3 _14756 = float3(_14684.x);
                    float3 _14050 = mix(mix(mix(float3(float2(as_type<half2>(_21249.x)), float2(as_type<half2>(_21249.y)).x), float3(float2(as_type<half2>(_21251.x)), float2(as_type<half2>(_21251.y)).x), _14469), mix(float3(float2(as_type<half2>(_21254.x)), float2(as_type<half2>(_21254.y)).x), float3(float2(as_type<half2>(_21255.x)), float2(as_type<half2>(_21255.y)).x), _14469), float3(_14397.y)), mix(mix(float3(float2(as_type<half2>(_21263.x)), float2(as_type<half2>(_21263.y)).x), float3(float2(as_type<half2>(_21265.x)), float2(as_type<half2>(_21265.y)).x), _14756), mix(float3(float2(as_type<half2>(_21268.x)), float2(as_type<half2>(_21268.y)).x), float3(float2(as_type<half2>(_21269.x)), float2(as_type<half2>(_21269.y)).x), _14756), float3(_14684.y)), float3(_14311 - float(_14314))) * _14187.w;
                    float _14054 = _21239 * (1.0 - _21238);
                    _21991 = _21304 + (_14050 * _14054);
                    _21990 = _21238 + _14054;
                }
                float3 _14072 = _21304 + (_21222 * (1.0 - _21238));
                bool _4270;
                if (_3699)
                {
                    _4270 = _283._m33.z > 0.5;
                }
                else
                {
                    _4270 = _3699;
                }
                float3 _21414;
                if (_4270)
                {
                    float3 _21380;
                    do
                    {
                        float _14981 = ((_283._m32.x * (1.0 - smoothstep(_283._m33.x * 0.5, _283._m33.x, abs(dot(_283._m31.xyz, in.m_3037) - _283._m31.w)))) * smoothstep(0.5, 0.89999997615814208984375, dot(_3664, _283._m31.xyz))) * (1.0 - smoothstep(_283._m32.y * 0.5, _283._m32.y, _21029));
                        if (_14981 <= 0.0)
                        {
                            _21380 = _14072;
                            break;
                        }
                        float4 _15006 = _283._m30 * float4(in.m_3037 + ((_21039 - (_283._m31.xyz * dot(_21039, _283._m31.xyz))) * _283._m32.w), 1.0);
                        float2 _15019 = ((float2(_15006.x, -_15006.y) / float2(_15006.w)) * 0.5) + float2(0.5);
                        float _15023 = _283._m32.z * _21029;
                        float3 _21378;
                        float _21379;
                        _21379 = 0.0;
                        _21378 = float3(0.0);
                        for (int _21377 = 0; _21377 < 12; )
                        {
                            float _15030 = float(_21377);
                            float _15038 = _15030 * 2.3999631404876708984375;
                            float2 _15050 = _15019 + (float2(cos(_15038) * _283._m33.y, sin(_15038)) * (sqrt((_15030 + 0.5) * 0.083333335816860198974609375) * _15023));
                            float2 _15055 = fast::min(_15050, float2(1.0) - _15050);
                            float _15061 = smoothstep(0.0, 0.039999999105930328369140625, fast::min(_15055.x, _15055.y));
                            float4 _15069 = _3352.sample(_2533, fast::clamp(_15050, float2(0.0), float2(1.0)), level(0.0));
                            float3 _15071 = _15069.xyz;
                            _21379 += (_15069.w * _15061);
                            _21378 += ((_15071 / (float3(1.0) - fast::min(_15071, float3(0.99500000476837158203125)))) * _15061);
                            _21377++;
                            continue;
                        }
                        _21380 = mix(_14072, (_21378 * float3(0.083333335816860198974609375)) + (_14072 * (1.0 - (_21379 * 0.083333335816860198974609375))), float3(_14981));
                        break;
                    } while(false);
                    _21414 = _21380;
                }
                else
                {
                    _21414 = _14072;
                }
                _21413 = _21414;
            }
            else
            {
                _21413 = _21148;
            }
            _21650 = _4188 + (((_4177 * (_21185 - _21139)) + (_4172 * (_21413 - _21148))) * _21163);
        }
        else
        {
            _21650 = _4188;
        }
        float3 _21720;
        if (_283._m13.w > 0.5)
        {
            float2 _15135 = fast::clamp(floor(gl_FragCoord.xy * _283._m12.xy), float2(0.0), _283._m13.xy - float2(1.0));
            uint _15163 = uint((((fast::clamp(floor((log2(fast::max(dot(_283._m11.xyz, in.m_3037) + _283._m11.w, 9.9999999747524270787835121154785e-07)) * _283._m12.z) + _283._m12.w), 0.0, _283._m13.z - 1.0) * _283._m13.y) + _15135.y) * _283._m13.x) + _15135.x);
            uint _15165 = _15163 >> uint(2);
            uint _15167 = _15163 & 3u;
            uint _15171 = _3167._m0[_15165][_15167] & 65535u;
            uint _15173 = _3167._m0[_15165][_15167] >> uint(16);
            float3 _21649;
            _21649 = _21650;
            float3 _4399;
            spvUnsafeArray<float2, 3> _15581;
            spvUnsafeArray<float2, 3> _15582;
            spvUnsafeArray<float2, 3> _15794;
            spvUnsafeArray<float2, 3> _15795;
            for (uint _21515 = _15171; _21515 < (_15171 + _15173); _21649 = _4399, _21515++)
            {
                uint _15179 = _21515 / 3u;
                uint _15192 = (_3188._m0[_15179 >> uint(2)][_15179 & 3u] >> ((_21515 - (_15179 * 3u)) * 10u)) & 1023u;
                float3 _15209 = _3030._m0[_15192].xyz - in.m_3037;
                float _15212 = dot(_15209, _15209);
                float _15216 = _15212 * _3030._m0[_15192].w;
                float _15221 = fast::clamp(1.0 - (_15216 * _15216), 0.0, 1.0);
                float3 _15226 = _15209 * rsqrt(fast::max(_15212, 9.9999999392252902907785028219223e-09));
                float _15244 = fast::clamp((dot(-_15226, _3073._m0[_15192].xyz) * _3065._m0[_15192].w) + _3073._m0[_15192].w, 0.0, 1.0);
                float3 _15257 = _3065._m0[_15192].xyz * ((((_15221 * _15221) * _15244) * _15244) / fast::max(_15212, 9.9999997473787516355514526367188e-05));
                float3 _21647;
                if (_3669)
                {
                    float _21542;
                    do
                    {
                        uint _15293 = uint(_283._m21.z);
                        if (_15192 < _15293)
                        {
                            float _15315 = _283._m26[_15192].z * fast::max((_283._m15[_15192] * float4(in.m_3037, 1.0)).w, 0.0);
                            float4 _15339 = _283._m15[_15192] * float4((in.m_3037 + (_3664 * (_15315 * _283._m25.x))) + (_15226 * (_15315 * _283._m25.y)), 1.0);
                            float _15341 = _15339.w;
                            if (_15341 <= 0.0)
                            {
                                _21542 = 1.0;
                                break;
                            }
                            float3 _15350 = _15339.xyz / float3(_15341);
                            float _15352 = _15350.x;
                            bool _15353 = _15352 < 0.0;
                            bool _15360;
                            if (!_15353)
                            {
                                _15360 = _15352 > 1.0;
                            }
                            else
                            {
                                _15360 = _15353;
                            }
                            bool _15367;
                            if (!_15360)
                            {
                                _15367 = _15350.y < 0.0;
                            }
                            else
                            {
                                _15367 = _15360;
                            }
                            bool _15374;
                            if (!_15367)
                            {
                                _15374 = _15350.y > 1.0;
                            }
                            else
                            {
                                _15374 = _15367;
                            }
                            bool _15381;
                            if (!_15374)
                            {
                                _15381 = _15350.z > 1.0;
                            }
                            else
                            {
                                _15381 = _15374;
                            }
                            if (_15381)
                            {
                                _21542 = 1.0;
                                break;
                            }
                            float _15387 = _15350.z;
                            float2 _15553 = _283._m22.xy * 0.5;
                            float2 _15558 = _283._m26[_15192].xy + (_15350.xy * _283._m23.zw);
                            float4 _15571 = float4(_283._m26[_15192].xy + _15553, (_283._m26[_15192].xy + _283._m23.zw) - _15553);
                            float _21541;
                            do
                            {
                                int _15597 = int(_283._m22.z);
                                if (_15597 <= 0)
                                {
                                    float2 _15607 = fast::clamp(_15558, _15571.xy, _15571.zw);
                                    _21541 = spvDepthCast(_303).sample_compare(_303Smplr, float3(_15607, _15387).xy, _15387);
                                    break;
                                }
                                float2 _15620 = (_15558 / _283._m22.xy) + float2(0.5);
                                float2 _15621 = floor(_15620);
                                float2 _15626 = _15620 - _15621;
                                float2 _15629 = _15621 - float2(0.5);
                                bool _15633 = _15597 == 1;
                                if (_15633)
                                {
                                    float2 _15636 = _15626 * 2.0;
                                    _15581[0] = float2(3.0) - _15636;
                                    _15581[1] = float2(1.0) + _15636;
                                    _15582[0] = ((float2(2.0) - _15626) / _15581[0]) - float2(1.0);
                                    _15582[1] = (_15626 / _15581[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _15663 = _15626 * 3.0;
                                    _15581[0] = float2(4.0) - _15663;
                                    _15581[1] = float2(7.0);
                                    _15581[2] = float2(1.0) + _15663;
                                    _15582[0] = ((float2(3.0) - (_15626 * 2.0)) / _15581[0]) - float2(2.0);
                                    _15582[1] = (float2(3.0) + _15626) / _15581[1];
                                    _15582[2] = (_15626 / _15581[2]) + float2(2.0);
                                }
                                int _22134 = _15633 ? 2 : 3;
                                int _21531;
                                float _21534;
                                _21534 = 0.0;
                                _21531 = 0;
                                float _21540;
                                for (; _21531 < _22134; _21534 = _21540, _21531++)
                                {
                                    _21540 = _21534;
                                    for (int _21537 = 0; _21537 < _22134; )
                                    {
                                        _21540 += ((_15581[_21537].x * _15581[_21531].y) * spvDepthCast(_303).sample_compare(_303Smplr, float3(fast::clamp(_283._m22.xy * (_15629 + float2(_15582[_21537].x, _15582[_21531].y)), _15571.xy, _15571.zw), _15387).xy, _15387));
                                        _21537++;
                                        continue;
                                    }
                                }
                                _21541 = _21534 * (_15633 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _21542 = _21541;
                            break;
                        }
                        uint _15397 = _15192 - _15293;
                        if (_15397 >= uint(_283._m21.w))
                        {
                            _21542 = 1.0;
                            break;
                        }
                        float _15418 = _283._m27[_15397].w * length(in.m_3037 - _283._m27[_15397].xyz);
                        float3 _15436 = ((in.m_3037 + (_3664 * (_15418 * _283._m25.x))) + (_15226 * (_15418 * _283._m25.y))) - _283._m27[_15397].xyz;
                        float3 _15438 = abs(_15436);
                        float _15440 = _15438.x;
                        float _15442 = _15438.y;
                        bool _15443 = _15440 >= _15442;
                        bool _15451;
                        if (_15443)
                        {
                            _15451 = _15440 >= _15438.z;
                        }
                        else
                        {
                            _15451 = _15443;
                        }
                        float _21516;
                        int _21518;
                        if (_15451)
                        {
                            _21518 = (_15436.x > 0.0) ? 0 : 1;
                            _21516 = _15440;
                        }
                        else
                        {
                            float _15463 = _15438.z;
                            bool _15464 = _15442 >= _15463;
                            int _21519;
                            if (_15464)
                            {
                                _21519 = (_15436.y > 0.0) ? 2 : 3;
                            }
                            else
                            {
                                _21519 = (_15436.z > 0.0) ? 4 : 5;
                            }
                            _21518 = _21519;
                            _21516 = _15464 ? _15442 : _15463;
                        }
                        if (_21516 <= 0.0)
                        {
                            _21542 = 1.0;
                            break;
                        }
                        float2 _15501 = float2(dot(_15436, _961[_21518]), dot(_15436, _970[_21518])) / float2(_21516 * _283._m24.z);
                        float _15508 = _283._m28[_15397].z + (_283._m28[_15397].w / _21516);
                        if (_15508 > 1.0)
                        {
                            _21542 = 1.0;
                            break;
                        }
                        float2 _15526 = _283._m28[_15397].xy + (float2(float(spvSMod(_21518, 3)), float(_21518 / 3)) * _283._m24.xy);
                        float2 _15766 = _283._m22.xy * 0.5;
                        float2 _15771 = _15526 + (float2(0.5 + (0.5 * _15501.x), 0.5 - (0.5 * _15501.y)) * _283._m24.xy);
                        float4 _15784 = float4(_15526 + _15766, (_15526 + _283._m24.xy) - _15766);
                        float _21530;
                        do
                        {
                            int _15810 = int(_283._m22.z);
                            if (_15810 <= 0)
                            {
                                _21530 = spvDepthCast(_303).sample_compare(_303Smplr, float3(fast::clamp(_15771, _15784.xy, _15784.zw), _15508).xy, _15508);
                                break;
                            }
                            float2 _15833 = (_15771 / _283._m22.xy) + float2(0.5);
                            float2 _15834 = floor(_15833);
                            float2 _15839 = _15833 - _15834;
                            float2 _15842 = _15834 - float2(0.5);
                            bool _15846 = _15810 == 1;
                            if (_15846)
                            {
                                float2 _15849 = _15839 * 2.0;
                                _15794[0] = float2(3.0) - _15849;
                                _15794[1] = float2(1.0) + _15849;
                                _15795[0] = ((float2(2.0) - _15839) / _15794[0]) - float2(1.0);
                                _15795[1] = (_15839 / _15794[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _15876 = _15839 * 3.0;
                                _15794[0] = float2(4.0) - _15876;
                                _15794[1] = float2(7.0);
                                _15794[2] = float2(1.0) + _15876;
                                _15795[0] = ((float2(3.0) - (_15839 * 2.0)) / _15794[0]) - float2(2.0);
                                _15795[1] = (float2(3.0) + _15839) / _15794[1];
                                _15795[2] = (_15839 / _15794[2]) + float2(2.0);
                            }
                            int _22137 = _15846 ? 2 : 3;
                            int _21520;
                            float _21523;
                            _21523 = 0.0;
                            _21520 = 0;
                            float _21529;
                            for (; _21520 < _22137; _21523 = _21529, _21520++)
                            {
                                _21529 = _21523;
                                for (int _21526 = 0; _21526 < _22137; )
                                {
                                    _21529 += ((_15794[_21526].x * _15794[_21520].y) * spvDepthCast(_303).sample_compare(_303Smplr, float3(fast::clamp(_283._m22.xy * (_15842 + float2(_15795[_21526].x, _15795[_21520].y)), _15784.xy, _15784.zw), _15508).xy, _15508));
                                    _21526++;
                                    continue;
                                }
                            }
                            _21530 = _21523 * (_15846 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _21542 = _21530;
                        break;
                    } while(false);
                    _21647 = _15257 * _21542;
                }
                else
                {
                    _21647 = _15257;
                }
                float3 _4351 = fast::normalize(_15226 + _3653);
                float _4356 = fast::clamp(dot(_21039, _15226), 0.0, 1.0);
                float _4361 = fast::clamp(dot(_21039, _4351), 0.0, 1.0);
                float3 _15981 = _3964 + (_10001 * powr(1.0 - fast::clamp(dot(_3653, _4351), 0.0, 1.0), 5.0));
                float _15995 = ((_4361 * _4361) * _10016) + 1.0;
                _4399 = _21649 + (((((float3(1.0) - _15981) * _3958) + ((_15981 * ((_10011 / ((3.1415927410125732421875 * _15995) * _15995)) * (0.5 / fast::max((_4356 * _10042) + (_21067 * sqrt(((_4356 * _4356) * _10038) + _10011)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875)) * _4356) * _21647);
            }
            _21720 = _21649;
        }
        else
        {
            _21720 = _21650;
        }
        _21716 = _21720;
    }
    float4 _4416 = _4411.sample(_2533, _3419);
    float _4437 = -length(_3652);
    float _21802;
    if (_283._m9.w != 0.0)
    {
        float _4461 = _283._m9.w * (in.m_3037 - _283._m6.xyz).y;
        float _21799;
        if (abs(_4461) < 9.9999997473787516355514526367188e-05)
        {
            _21799 = 1.0 - (0.5 * _4461);
        }
        else
        {
            _21799 = (1.0 - exp(fast::min(-_4461, 60.0))) / _4461;
        }
        _21802 = 1.0 - exp((_4437 * (_283._m7.w * exp(fast::min((-_283._m9.w) * (_283._m6.y - _283._m6.w), 30.0)))) * _21799);
    }
    else
    {
        _21802 = 1.0 - exp(_4437 * _283._m7.w);
    }
    float3 _21849;
    if (_283._m34.z > 0.5)
    {
        float3 _21813;
        if (_283._m29.x > 0.5)
        {
            float _16094 = (_283._m29.z * _21039.x) - (_283._m29.w * _21039.z);
            float _16107 = (_283._m29.w * _21039.x) + (_283._m29.z * _21039.z);
            float _16125 = 1.09254801273345947265625 * _16094;
            spvUnsafeArray<float, 9> _19110 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _21039.y, 0.48860299587249755859375 * _16107, 0.48860299587249755859375 * _16094, _16125 * _21039.y, (1.09254801273345947265625 * _21039.y) * _16107, 0.3153919875621795654296875 * (((3.0 * _16107) * _16107) - 1.0), _16125 * _16107, 0.546274006366729736328125 * ((_16094 * _16094) - (_21039.y * _21039.y)) });
            spvUnsafeArray<float, 9> _16039 = _19110;
            float3 _21812;
            _21812 = float3(0.0);
            for (int _21811 = 0; _21811 < 9; )
            {
                _21812 += (_2531.read(uint2((int2(496, 256) + int2(_21811, 0))), 0).xyz * _16039[_21811]);
                _21811++;
                continue;
            }
            _21813 = fast::max(_21812, float3(0.0)) * _283._m29.y;
        }
        else
        {
            _21813 = mix(_283._m9.xyz, _283._m8.xyz, float3((_21039.y * 0.5) + 0.5)) * _283._m8.w;
        }
        float3 _21818;
        if (_283._m34.y > 0.5)
        {
            int _16302 = int(_283._m34.y);
            int _16305 = int(_283._m34.x);
            float3 _21817;
            _21817 = _21813;
            float3 _22020;
            for (int _21816 = 0; _21816 < _16302; _21817 = _22020, _21816++)
            {
                int _16317 = 8 * (_16305 + _21816);
                float4 _16526 = as_type<float4>(_1281._m0[_16317 + 3]);
                float4 _16570 = as_type<float4>(_1281._m0[_16317]);
                float4 _16576 = as_type<float4>(_1281._m0[_16317 + 1]);
                float4 _16582 = as_type<float4>(_1281._m0[_16317 + 2]);
                float3 _16544 = _16570.xyz;
                float _16548 = _16570.w;
                float3 _16551 = _16576.xyz;
                float _16555 = _16576.w;
                float3 _16558 = _16582.xyz;
                float _16562 = _16582.w;
                float3 _16564 = float3(dot(_16544, in.m_3037) + _16548, dot(_16551, in.m_3037) + _16555, dot(_16558, in.m_3037) + _16562);
                float3 _16326 = _16526.xyz;
                float _16328 = _16526.w;
                float _21852;
                do
                {
                    float3 _16594 = _16326 - abs(_16564);
                    float _16602 = fast::min(_16594.x, fast::min(_16594.y, _16594.z));
                    if (_16602 <= 0.0)
                    {
                        _21852 = 0.0;
                        break;
                    }
                    if (_16328 <= 0.0)
                    {
                        _21852 = 1.0;
                        break;
                    }
                    float _16614 = fast::min(_16602 / _16328, 1.0);
                    _21852 = (_16614 * _16614) * (3.0 - (2.0 * _16614));
                    break;
                } while(false);
                if (_21852 <= 0.0)
                {
                    _22020 = _21817;
                    continue;
                }
                float3 _16337 = as_type<float4>(_1281._m0[_16317 + 4]).xyz;
                float4 _16635 = as_type<float4>(_1281._m0[_16317 + 5]);
                int _16641 = int(((device uint*)&_1281._m0[_16317 + 6])[0u]);
                float _16651 = dot(_16544, _21039);
                float _16657 = dot(_16551, _21039);
                float _16663 = dot(_16558, _21039);
                float3 _16664 = float3(_16651, _16657, _16663);
                float3 _16357 = (in.m_3037 + (_21039 * _16635.x)) + (_3653 * _16635.y);
                float3 _16376 = fast::clamp((((float3(dot(_16544, _16357) + _16548, dot(_16551, _16357) + _16555, dot(_16558, _16357) + _16562) + _16326) / fast::max(_16326 * 2.0, float3(9.9999999747524270787835121154785e-07))) * _16337) - float3(0.5), float3(0.0), _16337 - float3(1.0));
                int3 _16378 = int3(_16337);
                int3 _16385 = min(int3(_16376), max((_16378 - int3(2)), int3(0)));
                float3 _16389 = _16376 - float3(_16385);
                float _16744 = 0.48860299587249755859375 * _16657;
                float _16747 = 0.48860299587249755859375 * _16663;
                float _16750 = 0.48860299587249755859375 * _16651;
                float _16755 = 1.09254801273345947265625 * _16651;
                float _16758 = _16755 * _16657;
                float _16764 = (1.09254801273345947265625 * _16657) * _16663;
                float _16772 = 0.3153919875621795654296875 * (((3.0 * _16663) * _16663) - 1.0);
                float _16778 = _16755 * _16663;
                float _16792 = 0.546274006366729736328125 * ((_16651 * _16651) - (_16657 * _16657));
                int3 _16811 = _16378 - int3(1);
                int3 _16812 = min(_16385, _16811);
                int _16817 = _16378.x;
                int _16821 = _16378.y;
                int _16829 = _16641 + ((_16812.x + (_16817 * (_16812.y + (_16821 * _16812.z)))) * 4);
                float3 _16832 = float3(1.0) - _16389;
                float3 _16850 = (((((float3(_16812) + float3(0.5)) / _16337) * _16326) * 2.0) - _16326) - _16564;
                float _16860 = dot(_16850 * rsqrt(fast::max(dot(_16850, _16850), 1.0000000133514319600180897396058e-10)), _16664) + 1.0;
                float _16863 = _16832.x;
                float _16865 = _16832.y;
                float _16866 = _16863 * _16865;
                float _16868 = _16832.z;
                int _16892 = _16829 + 3;
                float _16878 = ((_16866 * _16868) * ((0.25 * (_16860 * _16860)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_16892])[1u])).y > 0.5);
                int _16922 = _16829 + 1;
                int _16926 = _16829 + 2;
                float2 _16938 = float2(as_type<half2>(_1281._m0[_16829].y));
                float2 _16947 = float2(as_type<half2>(_1281._m0[_16922].x));
                float2 _16956 = float2(as_type<half2>(_1281._m0[_16922].w));
                float2 _16965 = float2(as_type<half2>(_1281._m0[_16926].z));
                float3 _17053 = (((((((float3(float2(as_type<half2>(_1281._m0[_16829].x)), _16938.x) * 0.2820949852466583251953125) + (float3(_16938.y, float2(as_type<half2>(_1281._m0[_16829].z))) * _16744)) + (float3(float2(as_type<half2>(_1281._m0[_16829].w)), _16947.x) * _16747)) + (float3(_16947.y, float2(as_type<half2>(_1281._m0[_16922].y))) * _16750)) + (float3(float2(as_type<half2>(_1281._m0[_16922].z)), _16956.x) * _16758)) + (float3(_16956.y, float2(as_type<half2>(_1281._m0[_16926].x))) * _16764)) + (float3(float2(as_type<half2>(_1281._m0[_16926].y)), _16965.x) * _16772)) + (float3(_16965.y, float2(as_type<half2>(_1281._m0[_16926].w))) * _16778);
                int3 _17081 = min((_16385 + int3(1, 0, 0)), _16811);
                int _17098 = _16641 + ((_17081.x + (_16817 * (_17081.y + (_16821 * _17081.z)))) * 4);
                float3 _17119 = (((((float3(_17081) + float3(0.5)) / _16337) * _16326) * 2.0) - _16326) - _16564;
                float _17129 = dot(_17119 * rsqrt(fast::max(dot(_17119, _17119), 1.0000000133514319600180897396058e-10)), _16664) + 1.0;
                float _17135 = _16389.x * _16865;
                int _17161 = _17098 + 3;
                float _17147 = ((_17135 * _16868) * ((0.25 * (_17129 * _17129)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_17161])[1u])).y > 0.5);
                int _17191 = _17098 + 1;
                int _17195 = _17098 + 2;
                float2 _17207 = float2(as_type<half2>(_1281._m0[_17098].y));
                float2 _17216 = float2(as_type<half2>(_1281._m0[_17191].x));
                float2 _17225 = float2(as_type<half2>(_1281._m0[_17191].w));
                float2 _17234 = float2(as_type<half2>(_1281._m0[_17195].z));
                float3 _17322 = (((((((float3(float2(as_type<half2>(_1281._m0[_17098].x)), _17207.x) * 0.2820949852466583251953125) + (float3(_17207.y, float2(as_type<half2>(_1281._m0[_17098].z))) * _16744)) + (float3(float2(as_type<half2>(_1281._m0[_17098].w)), _17216.x) * _16747)) + (float3(_17216.y, float2(as_type<half2>(_1281._m0[_17191].y))) * _16750)) + (float3(float2(as_type<half2>(_1281._m0[_17191].z)), _17225.x) * _16758)) + (float3(_17225.y, float2(as_type<half2>(_1281._m0[_17195].x))) * _16764)) + (float3(float2(as_type<half2>(_1281._m0[_17195].y)), _17234.x) * _16772)) + (float3(_17234.y, float2(as_type<half2>(_1281._m0[_17195].w))) * _16778);
                int3 _17350 = min((_16385 + int3(0, 1, 0)), _16811);
                int _17367 = _16641 + ((_17350.x + (_16817 * (_17350.y + (_16821 * _17350.z)))) * 4);
                float3 _17388 = (((((float3(_17350) + float3(0.5)) / _16337) * _16326) * 2.0) - _16326) - _16564;
                float _17398 = dot(_17388 * rsqrt(fast::max(dot(_17388, _17388), 1.0000000133514319600180897396058e-10)), _16664) + 1.0;
                float _17404 = _16863 * _16389.y;
                int _17430 = _17367 + 3;
                float _17416 = ((_17404 * _16868) * ((0.25 * (_17398 * _17398)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_17430])[1u])).y > 0.5);
                int _17460 = _17367 + 1;
                int _17464 = _17367 + 2;
                float2 _17476 = float2(as_type<half2>(_1281._m0[_17367].y));
                float2 _17485 = float2(as_type<half2>(_1281._m0[_17460].x));
                float2 _17494 = float2(as_type<half2>(_1281._m0[_17460].w));
                float2 _17503 = float2(as_type<half2>(_1281._m0[_17464].z));
                float3 _17591 = (((((((float3(float2(as_type<half2>(_1281._m0[_17367].x)), _17476.x) * 0.2820949852466583251953125) + (float3(_17476.y, float2(as_type<half2>(_1281._m0[_17367].z))) * _16744)) + (float3(float2(as_type<half2>(_1281._m0[_17367].w)), _17485.x) * _16747)) + (float3(_17485.y, float2(as_type<half2>(_1281._m0[_17460].y))) * _16750)) + (float3(float2(as_type<half2>(_1281._m0[_17460].z)), _17494.x) * _16758)) + (float3(_17494.y, float2(as_type<half2>(_1281._m0[_17464].x))) * _16764)) + (float3(float2(as_type<half2>(_1281._m0[_17464].y)), _17503.x) * _16772)) + (float3(_17503.y, float2(as_type<half2>(_1281._m0[_17464].w))) * _16778);
                int3 _17619 = min((_16385 + int3(1, 1, 0)), _16811);
                int _17636 = _16641 + ((_17619.x + (_16817 * (_17619.y + (_16821 * _17619.z)))) * 4);
                float3 _17657 = (((((float3(_17619) + float3(0.5)) / _16337) * _16326) * 2.0) - _16326) - _16564;
                float _17667 = dot(_17657 * rsqrt(fast::max(dot(_17657, _17657), 1.0000000133514319600180897396058e-10)), _16664) + 1.0;
                float _17673 = _16389.x * _16389.y;
                int _17699 = _17636 + 3;
                float _17685 = ((_17673 * _16868) * ((0.25 * (_17667 * _17667)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_17699])[1u])).y > 0.5);
                int _17729 = _17636 + 1;
                int _17733 = _17636 + 2;
                float2 _17745 = float2(as_type<half2>(_1281._m0[_17636].y));
                float2 _17754 = float2(as_type<half2>(_1281._m0[_17729].x));
                float2 _17763 = float2(as_type<half2>(_1281._m0[_17729].w));
                float2 _17772 = float2(as_type<half2>(_1281._m0[_17733].z));
                float3 _17860 = (((((((float3(float2(as_type<half2>(_1281._m0[_17636].x)), _17745.x) * 0.2820949852466583251953125) + (float3(_17745.y, float2(as_type<half2>(_1281._m0[_17636].z))) * _16744)) + (float3(float2(as_type<half2>(_1281._m0[_17636].w)), _17754.x) * _16747)) + (float3(_17754.y, float2(as_type<half2>(_1281._m0[_17729].y))) * _16750)) + (float3(float2(as_type<half2>(_1281._m0[_17729].z)), _17763.x) * _16758)) + (float3(_17763.y, float2(as_type<half2>(_1281._m0[_17733].x))) * _16764)) + (float3(float2(as_type<half2>(_1281._m0[_17733].y)), _17772.x) * _16772)) + (float3(_17772.y, float2(as_type<half2>(_1281._m0[_17733].w))) * _16778);
                int3 _17888 = min((_16385 + int3(0, 0, 1)), _16811);
                int _17905 = _16641 + ((_17888.x + (_16817 * (_17888.y + (_16821 * _17888.z)))) * 4);
                float3 _17926 = (((((float3(_17888) + float3(0.5)) / _16337) * _16326) * 2.0) - _16326) - _16564;
                float _17936 = dot(_17926 * rsqrt(fast::max(dot(_17926, _17926), 1.0000000133514319600180897396058e-10)), _16664) + 1.0;
                int _17968 = _17905 + 3;
                float _17954 = ((_16866 * _16389.z) * ((0.25 * (_17936 * _17936)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_17968])[1u])).y > 0.5);
                int _17998 = _17905 + 1;
                int _18002 = _17905 + 2;
                float2 _18014 = float2(as_type<half2>(_1281._m0[_17905].y));
                float2 _18023 = float2(as_type<half2>(_1281._m0[_17998].x));
                float2 _18032 = float2(as_type<half2>(_1281._m0[_17998].w));
                float2 _18041 = float2(as_type<half2>(_1281._m0[_18002].z));
                float3 _18129 = (((((((float3(float2(as_type<half2>(_1281._m0[_17905].x)), _18014.x) * 0.2820949852466583251953125) + (float3(_18014.y, float2(as_type<half2>(_1281._m0[_17905].z))) * _16744)) + (float3(float2(as_type<half2>(_1281._m0[_17905].w)), _18023.x) * _16747)) + (float3(_18023.y, float2(as_type<half2>(_1281._m0[_17998].y))) * _16750)) + (float3(float2(as_type<half2>(_1281._m0[_17998].z)), _18032.x) * _16758)) + (float3(_18032.y, float2(as_type<half2>(_1281._m0[_18002].x))) * _16764)) + (float3(float2(as_type<half2>(_1281._m0[_18002].y)), _18041.x) * _16772)) + (float3(_18041.y, float2(as_type<half2>(_1281._m0[_18002].w))) * _16778);
                float4 _16456 = (((float4((_17053 + (float3(float2(as_type<half2>(_1281._m0[_16892].x)), float2(as_type<half2>(_1281._m0[_16892].y)).x) * _16792)) * _16878, _16878) + float4((_17322 + (float3(float2(as_type<half2>(_1281._m0[_17161].x)), float2(as_type<half2>(_1281._m0[_17161].y)).x) * _16792)) * _17147, _17147)) + float4((_17591 + (float3(float2(as_type<half2>(_1281._m0[_17430].x)), float2(as_type<half2>(_1281._m0[_17430].y)).x) * _16792)) * _17416, _17416)) + float4((_17860 + (float3(float2(as_type<half2>(_1281._m0[_17699].x)), float2(as_type<half2>(_1281._m0[_17699].y)).x) * _16792)) * _17685, _17685)) + float4((_18129 + (float3(float2(as_type<half2>(_1281._m0[_17968].x)), float2(as_type<half2>(_1281._m0[_17968].y)).x) * _16792)) * _17954, _17954);
                int3 _18157 = min((_16385 + int3(1, 0, 1)), _16811);
                int _18174 = _16641 + ((_18157.x + (_16817 * (_18157.y + (_16821 * _18157.z)))) * 4);
                float3 _18195 = (((((float3(_18157) + float3(0.5)) / _16337) * _16326) * 2.0) - _16326) - _16564;
                float _18205 = dot(_18195 * rsqrt(fast::max(dot(_18195, _18195), 1.0000000133514319600180897396058e-10)), _16664) + 1.0;
                int _18237 = _18174 + 3;
                float _18223 = ((_17135 * _16389.z) * ((0.25 * (_18205 * _18205)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_18237])[1u])).y > 0.5);
                int _18267 = _18174 + 1;
                int _18271 = _18174 + 2;
                float2 _18283 = float2(as_type<half2>(_1281._m0[_18174].y));
                float2 _18292 = float2(as_type<half2>(_1281._m0[_18267].x));
                float2 _18301 = float2(as_type<half2>(_1281._m0[_18267].w));
                float2 _18310 = float2(as_type<half2>(_1281._m0[_18271].z));
                float3 _18398 = (((((((float3(float2(as_type<half2>(_1281._m0[_18174].x)), _18283.x) * 0.2820949852466583251953125) + (float3(_18283.y, float2(as_type<half2>(_1281._m0[_18174].z))) * _16744)) + (float3(float2(as_type<half2>(_1281._m0[_18174].w)), _18292.x) * _16747)) + (float3(_18292.y, float2(as_type<half2>(_1281._m0[_18267].y))) * _16750)) + (float3(float2(as_type<half2>(_1281._m0[_18267].z)), _18301.x) * _16758)) + (float3(_18301.y, float2(as_type<half2>(_1281._m0[_18271].x))) * _16764)) + (float3(float2(as_type<half2>(_1281._m0[_18271].y)), _18310.x) * _16772)) + (float3(_18310.y, float2(as_type<half2>(_1281._m0[_18271].w))) * _16778);
                int3 _18426 = min((_16385 + int3(0, 1, 1)), _16811);
                int _18443 = _16641 + ((_18426.x + (_16817 * (_18426.y + (_16821 * _18426.z)))) * 4);
                float3 _18464 = (((((float3(_18426) + float3(0.5)) / _16337) * _16326) * 2.0) - _16326) - _16564;
                float _18474 = dot(_18464 * rsqrt(fast::max(dot(_18464, _18464), 1.0000000133514319600180897396058e-10)), _16664) + 1.0;
                int _18506 = _18443 + 3;
                float _18492 = ((_17404 * _16389.z) * ((0.25 * (_18474 * _18474)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_18506])[1u])).y > 0.5);
                int _18536 = _18443 + 1;
                int _18540 = _18443 + 2;
                float2 _18552 = float2(as_type<half2>(_1281._m0[_18443].y));
                float2 _18561 = float2(as_type<half2>(_1281._m0[_18536].x));
                float2 _18570 = float2(as_type<half2>(_1281._m0[_18536].w));
                float2 _18579 = float2(as_type<half2>(_1281._m0[_18540].z));
                float3 _18667 = (((((((float3(float2(as_type<half2>(_1281._m0[_18443].x)), _18552.x) * 0.2820949852466583251953125) + (float3(_18552.y, float2(as_type<half2>(_1281._m0[_18443].z))) * _16744)) + (float3(float2(as_type<half2>(_1281._m0[_18443].w)), _18561.x) * _16747)) + (float3(_18561.y, float2(as_type<half2>(_1281._m0[_18536].y))) * _16750)) + (float3(float2(as_type<half2>(_1281._m0[_18536].z)), _18570.x) * _16758)) + (float3(_18570.y, float2(as_type<half2>(_1281._m0[_18540].x))) * _16764)) + (float3(float2(as_type<half2>(_1281._m0[_18540].y)), _18579.x) * _16772)) + (float3(_18579.y, float2(as_type<half2>(_1281._m0[_18540].w))) * _16778);
                int3 _18695 = min((_16385 + int3(1)), _16811);
                int _18712 = _16641 + ((_18695.x + (_16817 * (_18695.y + (_16821 * _18695.z)))) * 4);
                float3 _18733 = (((((float3(_18695) + float3(0.5)) / _16337) * _16326) * 2.0) - _16326) - _16564;
                float _18743 = dot(_18733 * rsqrt(fast::max(dot(_18733, _18733), 1.0000000133514319600180897396058e-10)), _16664) + 1.0;
                int _18775 = _18712 + 3;
                float _18761 = ((_17673 * _16389.z) * ((0.25 * (_18743 * _18743)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_18775])[1u])).y > 0.5);
                int _18805 = _18712 + 1;
                int _18809 = _18712 + 2;
                float2 _18821 = float2(as_type<half2>(_1281._m0[_18712].y));
                float2 _18830 = float2(as_type<half2>(_1281._m0[_18805].x));
                float2 _18839 = float2(as_type<half2>(_1281._m0[_18805].w));
                float2 _18848 = float2(as_type<half2>(_1281._m0[_18809].z));
                float3 _18936 = (((((((float3(float2(as_type<half2>(_1281._m0[_18712].x)), _18821.x) * 0.2820949852466583251953125) + (float3(_18821.y, float2(as_type<half2>(_1281._m0[_18712].z))) * _16744)) + (float3(float2(as_type<half2>(_1281._m0[_18712].w)), _18830.x) * _16747)) + (float3(_18830.y, float2(as_type<half2>(_1281._m0[_18805].y))) * _16750)) + (float3(float2(as_type<half2>(_1281._m0[_18805].z)), _18839.x) * _16758)) + (float3(_18839.y, float2(as_type<half2>(_1281._m0[_18809].x))) * _16764)) + (float3(float2(as_type<half2>(_1281._m0[_18809].y)), _18848.x) * _16772)) + (float3(_18848.y, float2(as_type<half2>(_1281._m0[_18809].w))) * _16778);
                float4 _16495 = ((_16456 + float4((_18398 + (float3(float2(as_type<half2>(_1281._m0[_18237].x)), float2(as_type<half2>(_1281._m0[_18237].y)).x) * _16792)) * _18223, _18223)) + float4((_18667 + (float3(float2(as_type<half2>(_1281._m0[_18506].x)), float2(as_type<half2>(_1281._m0[_18506].y)).x) * _16792)) * _18492, _18492)) + float4((_18936 + (float3(float2(as_type<half2>(_1281._m0[_18775].x)), float2(as_type<half2>(_1281._m0[_18775].y)).x) * _16792)) * _18761, _18761);
                float _16499 = _16495.w;
                float3 _22021;
                if (_16499 > 9.9999997473787516355514526367188e-06)
                {
                    _22021 = mix(_21817, (fast::max(_16495.xyz, float3(0.0)) / float3(_16499)) * _16635.z, float3(_21852));
                }
                else
                {
                    _22021 = _21817;
                }
                _22020 = _22021;
            }
            _21818 = _21817;
        }
        else
        {
            _21818 = _21813;
        }
        _21849 = _21818 * _21163;
    }
    else
    {
        _21849 = mix(mix(_21716, _21033, float3(_2876._m1.y)) + (((_2876._m5.xyz * _4416.xyz) * (float3(1.0) + in.m_3666.yzw)) * in.m_3919.z), _283._m7.xyz, float3(_21802));
    }
    float3 _21850;
    if (_283._m33.w > 0.5)
    {
        _21850 = _21849 / (float3(1.0) + _21849);
    }
    else
    {
        _21850 = _21849;
    }
    out.m_4561 = float4(_21850, ((in.m_3428.w * _2876._m0.w) * _3426.w) * in.m_3448.w);
    float2 _21851;
    do
    {
        if (in.m_4571.w <= 0.0)
        {
            _21851 = float2(0.0);
            break;
        }
        _21851 = ((in.m_4571.xy / float2(in.m_4571.w)) - (in.m_4570.xy / float2(in.m_4570.w))) * float2(0.5, -0.5);
        break;
    } while(false);
    _4569 = _21851;
    return out;
}

