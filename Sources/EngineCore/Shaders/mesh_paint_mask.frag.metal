// Generated from mesh_paint_mask.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 3d994c8bf5b27ac6
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
    float4 m_4445 [[color(0)]];
    float2 m_4453 [[color(1)]];
};

struct fragment_main_in
{
    float3 m_3037 [[user(locn0)]];
    float3 m_2946 [[user(locn1)]];
    float2 m_3405 [[user(locn2)]];
    float4 m_3428 [[user(locn3)]];
    float3 m_2980 [[user(locn4)]];
    float4 m_3679 [[user(locn5)]];
    float4 m_4454 [[user(locn6)]];
    float4 m_4455 [[user(locn7)]];
    float4 m_2952 [[user(locn8)]];
    float4 m_3461 [[user(locn9)]];
    float4 m_3911 [[user(locn10)]];
};

fragment fragment_main_out fragment_main(fragment_main_in in [[stage_in]], constant _2874& _2876 [[buffer(2)]], constant _3028& _3030 [[buffer(3)]], constant _3063& _3065 [[buffer(4)]], constant _3071& _3073 [[buffer(5)]], constant _3165& _3167 [[buffer(6)]], constant _3186& _3188 [[buffer(7)]], constant _281& _283 [[buffer(15)]], const device _1279& _1281 [[buffer(21)]], texture2d<float> _303 [[texture(0)]], texture2d<float> _3421 [[texture(1)]], texture2d<float> _3899 [[texture(2)]], texture2d<float> _3556 [[texture(3)]], texture2d<float> _3352 [[texture(4)]], texture2d<float> _4324 [[texture(5)]], texture2d<float> _2531 [[texture(6)]], texture2d<float> _2632 [[texture(7)]], sampler _303Smplr [[sampler(0)]], sampler _2533 [[sampler(1)]], sampler _2634 [[sampler(7)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])
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
    float3 _16521;
    if (_2876._m1.x > 0.5)
    {
        float2 _3480 = floor(in.m_3037.xz * float2(0.5));
        _16521 = _3465 * ((mod(abs(_3480.x + _3480.y), 2.0) < 0.5) ? 1.0 : 0.75);
    }
    else
    {
        _16521 = _3465;
    }
    float3 _16618;
    float _16649;
    float2 _16682;
    if (_2876._m3.w > 0.5)
    {
        float3 _4561;
        float2 _4568;
        float _16519;
        do
        {
            float3 _4532 = float4(_2876._m2.w, _2876._m3.w, 0.0, 0.0).xyy;
            float3 _4535 = floor(_4532 * float3(1.52587890625e-05));
            float3 _4540 = _4532 - (_4535 * 65536.0);
            float3 _4543 = floor(_4540 * float3(0.00390625));
            float3 _4551 = _4540 - (_4543 * 256.0);
            _4561 = (float3(_4551.x, _4543.x, _4535.x) * float3(0.0039215688593685626983642578125)) * 2.0;
            _4568 = float2(_4551.y, _4543.y) * float2(0.0039215688593685626983642578125);
            float _4571 = _4535.y - 128.0;
            float _4577 = floor(_4571 * 0.03125) * 0.3333333432674407958984375;
            float3 _4583 = fast::normalize(in.m_2946);
            float _4587 = dot(_4583, in.m_2952.xyz);
            float _4599 = (_4587 / fast::max(length(in.m_2952.xyz - (_4583 * _4587)), 9.9999999747524270787835121154785e-07)) * 25.5;
            if (((-24.0) + _4599) < (-2.0))
            {
                _16519 = 0.0;
                break;
            }
            float3 _4607 = in.m_2980 * (4.0 * exp2(mod(_4571, 32.0) * 0.3333333432674407958984375));
            float3 _4651 = floor(_4607);
            float3 _4654 = _4607 - _4651;
            float3 _4662 = (_4654 * _4654) * (float3(3.0) - (_4654 * 2.0));
            uint3 _4729 = uint3(int3(_4651));
            uint _4742 = (((_4729.x * 1597334677u) ^ (_4729.y * 3812015801u)) ^ (_4729.z * 2798796415u)) * 1597334677u;
            uint3 _4757 = uint3(int3(_4651 + float3(1.0, 0.0, 0.0)));
            uint _4770 = (((_4757.x * 1597334677u) ^ (_4757.y * 3812015801u)) ^ (_4757.z * 2798796415u)) * 1597334677u;
            float _4671 = _4662.x;
            uint3 _4785 = uint3(int3(_4651 + float3(0.0, 1.0, 0.0)));
            uint _4798 = (((_4785.x * 1597334677u) ^ (_4785.y * 3812015801u)) ^ (_4785.z * 2798796415u)) * 1597334677u;
            uint3 _4813 = uint3(int3(_4651 + float3(1.0, 1.0, 0.0)));
            uint _4826 = (((_4813.x * 1597334677u) ^ (_4813.y * 3812015801u)) ^ (_4813.z * 2798796415u)) * 1597334677u;
            float _4687 = _4662.y;
            uint3 _4841 = uint3(int3(_4651 + float3(0.0, 0.0, 1.0)));
            uint _4854 = (((_4841.x * 1597334677u) ^ (_4841.y * 3812015801u)) ^ (_4841.z * 2798796415u)) * 1597334677u;
            uint3 _4869 = uint3(int3(_4651 + float3(1.0, 0.0, 1.0)));
            uint _4882 = (((_4869.x * 1597334677u) ^ (_4869.y * 3812015801u)) ^ (_4869.z * 2798796415u)) * 1597334677u;
            uint3 _4897 = uint3(int3(_4651 + float3(0.0, 1.0, 1.0)));
            uint _4910 = (((_4897.x * 1597334677u) ^ (_4897.y * 3812015801u)) ^ (_4897.z * 2798796415u)) * 1597334677u;
            uint3 _4925 = uint3(int3(_4651 + float3(1.0)));
            uint _4938 = (((_4925.x * 1597334677u) ^ (_4925.y * 3812015801u)) ^ (_4925.z * 2798796415u)) * 1597334677u;
            float3 _4613 = (_4607 * 2.7000000476837158203125) + float3(17.299999237060546875, 5.099999904632568359375, 9.69999980926513671875);
            float3 _4964 = floor(_4613);
            float3 _4967 = _4613 - _4964;
            float3 _4975 = (_4967 * _4967) * (float3(3.0) - (_4967 * 2.0));
            uint3 _5042 = uint3(int3(_4964));
            uint _5055 = (((_5042.x * 1597334677u) ^ (_5042.y * 3812015801u)) ^ (_5042.z * 2798796415u)) * 1597334677u;
            uint3 _5070 = uint3(int3(_4964 + float3(1.0, 0.0, 0.0)));
            uint _5083 = (((_5070.x * 1597334677u) ^ (_5070.y * 3812015801u)) ^ (_5070.z * 2798796415u)) * 1597334677u;
            float _4984 = _4975.x;
            uint3 _5098 = uint3(int3(_4964 + float3(0.0, 1.0, 0.0)));
            uint _5111 = (((_5098.x * 1597334677u) ^ (_5098.y * 3812015801u)) ^ (_5098.z * 2798796415u)) * 1597334677u;
            uint3 _5126 = uint3(int3(_4964 + float3(1.0, 1.0, 0.0)));
            uint _5139 = (((_5126.x * 1597334677u) ^ (_5126.y * 3812015801u)) ^ (_5126.z * 2798796415u)) * 1597334677u;
            float _5000 = _4975.y;
            uint3 _5154 = uint3(int3(_4964 + float3(0.0, 0.0, 1.0)));
            uint _5167 = (((_5154.x * 1597334677u) ^ (_5154.y * 3812015801u)) ^ (_5154.z * 2798796415u)) * 1597334677u;
            uint3 _5182 = uint3(int3(_4964 + float3(1.0, 0.0, 1.0)));
            uint _5195 = (((_5182.x * 1597334677u) ^ (_5182.y * 3812015801u)) ^ (_5182.z * 2798796415u)) * 1597334677u;
            uint3 _5210 = uint3(int3(_4964 + float3(0.0, 1.0, 1.0)));
            uint _5223 = (((_5210.x * 1597334677u) ^ (_5210.y * 3812015801u)) ^ (_5210.z * 2798796415u)) * 1597334677u;
            uint3 _5238 = uint3(int3(_4964 + float3(1.0)));
            uint _5251 = (((_5238.x * 1597334677u) ^ (_5238.y * 3812015801u)) ^ (_5238.z * 2798796415u)) * 1597334677u;
            float _4618 = mix(0.449999988079071044921875, 0.0500000007450580596923828125, _4577);
            float _4622 = ((mix(mix(mix(float((_4742 ^ (_4742 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_4770 ^ (_4770 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _4671), mix(float((_4798 ^ (_4798 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_4826 ^ (_4826 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _4671), _4687), mix(mix(float((_4854 ^ (_4854 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_4882 ^ (_4882 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _4671), mix(float((_4910 ^ (_4910 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_4938 ^ (_4938 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _4671), _4687), _4662.z) * 0.64999997615814208984375) + (mix(mix(mix(float((_5055 ^ (_5055 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_5083 ^ (_5083 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _4984), mix(float((_5111 ^ (_5111 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_5139 ^ (_5139 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _4984), _5000), mix(mix(float((_5167 ^ (_5167 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_5195 ^ (_5195 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _4984), mix(float((_5223 ^ (_5223 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_5251 ^ (_5251 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _4984), _5000), _4975.z) * 0.3499999940395355224609375)) - 0.5;
            _16519 = smoothstep(-_4618, _4618, (_4599 + (-24.450000762939453125)) + (_4622 * mix(0.800000011920928955078125, 2.2000000476837158203125, _4577)));
            break;
        } while(false);
        _16682 = _4568;
        _16649 = _16519;
        _16618 = mix(_16521, (in.m_3428.xyz * _4561) * mix(float3(1.0), _3436 * 2.0, float3(0.5)), float3(_16519));
    }
    else
    {
        _16682 = float2(0.0);
        _16649 = 0.0;
        _16618 = _16521;
    }
    float3 _3522 = fast::normalize(in.m_2946);
    float3 _16531;
    if (_2876._m6.y > 0.5)
    {
        float3 _3537 = in.m_2952.xyz - (_3522 * dot(_3522, in.m_2952.xyz));
        float3 _16532;
        if (dot(_3537, _3537) > 9.9999999600419720025001879548654e-13)
        {
            float3 _3545 = fast::normalize(_3537);
            float4 _3561 = _3556.sample(_2533, _3419);
            float3 _16523;
            if (_2876._m6.z > 0.5)
            {
                float2 _16522;
                if (_2876._m6.z > 1.5)
                {
                    _16522 = _3561.xw;
                }
                else
                {
                    _16522 = _3561.xy;
                }
                float2 _3583 = (_16522 * 2.0) - float2(1.0);
                _16523 = float3(_3583, sqrt(fast::clamp(1.0 - dot(_3583, _3583), 0.0, 1.0)));
            }
            else
            {
                _16523 = (_3561.xyz * 2.0) - float3(1.0);
            }
            float2 _3605 = _16523.xy * _2876._m4.z;
            _16532 = fast::normalize(((_3545 * _3605.x) + ((cross(_3522, _3545) * ((in.m_2952.w < 0.0) ? (-1.0) : 1.0)) * _3605.y)) + (_3522 * _16523.z));
        }
        else
        {
            _16532 = _3522;
        }
        _16531 = _16532;
    }
    else
    {
        _16531 = _3522;
    }
    bool _3629 = _2876._m5.w > 0.5;
    float _16528;
    if (_3629)
    {
        _16528 = fast::clamp(_2876._m1.z, 0.0, 1.0);
    }
    else
    {
        _16528 = 0.0;
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
    float3 _16718;
    if (_3647 && (_16528 <= 0.0))
    {
        _16718 = -_16531;
    }
    else
    {
        _16718 = _16531;
    }
    float3 _3659 = fast::normalize(_283._m4.xyz);
    float3 _3665 = _283._m6.xyz - in.m_3037;
    float3 _3666 = fast::normalize(_3665);
    float3 _3671 = fast::normalize(_3659 + _3666);
    float3 _3677 = _3522 * (gl_FrontFacing ? 1.0 : (-1.0));
    bool _3682 = in.m_3679.x > 0.5;
    float3 _16712;
    float _16752;
    if ((_283._m5.w > 0.5) && _3682)
    {
        float _16588;
        float3 _16589;
        do
        {
            int _5280 = int(_283._m21.x);
            float _5288 = dot(_283._m20.xyz, in.m_3037) + _283._m20.w;
            int _16533;
            _16533 = 0;
            for (;;)
            {
                bool _5294 = _16533 < (_5280 - 1);
                bool _5302;
                if (_5294)
                {
                    _5302 = _5288 > _283._m16[_16533];
                }
                else
                {
                    _5302 = _5294;
                }
                if (_5302)
                {
                    _16533++;
                    continue;
                }
                else
                {
                    break;
                }
            }
            if (_5288 > _283._m16[_16533])
            {
                _16589 = float3(1.0);
                _16588 = 1.0;
                break;
            }
            float _16546;
            do
            {
                float4 _5404 = _283._m14[_16533] * float4(in.m_3037 + (_3677 * _283._m18[_16533]), 1.0);
                float _5407 = _5404.x;
                bool _5408 = _5407 < 0.0;
                bool _5415;
                if (!_5408)
                {
                    _5415 = _5407 > 1.0;
                }
                else
                {
                    _5415 = _5408;
                }
                bool _5422;
                if (!_5415)
                {
                    _5422 = _5404.y < 0.0;
                }
                else
                {
                    _5422 = _5415;
                }
                bool _5429;
                if (!_5422)
                {
                    _5429 = _5404.y > 1.0;
                }
                else
                {
                    _5429 = _5422;
                }
                if (_5429)
                {
                    _16546 = 1.0;
                    break;
                }
                float2 _5442 = float2(float(_16533 & 1), float(_16533 >> 1)) * _283._m23.xy;
                float _5449 = fast::min(_5404.z, 1.0) - _283._m19[_16533];
                float2 _5468 = _283._m22.xy * 0.5;
                float2 _5473 = _5442 + (_5404.xy * _283._m23.xy);
                float4 _5486 = float4(_5442 + _5468, (_5442 + _283._m23.xy) - _5468);
                float _16545;
                do
                {
                    int _5512 = int(_283._m22.z);
                    if (_5512 <= 0)
                    {
                        _16545 = spvDepthCast(_303).sample_compare(_303Smplr, float3(fast::clamp(_5473, _5486.xy, _5486.zw), _5449).xy, _5449);
                        break;
                    }
                    float2 _5535 = (_5473 / _283._m22.xy) + float2(0.5);
                    float2 _5536 = floor(_5535);
                    float2 _5541 = _5535 - _5536;
                    float2 _5544 = _5536 - float2(0.5);
                    bool _5548 = _5512 == 1;
                    spvUnsafeArray<float2, 3> _5496;
                    spvUnsafeArray<float2, 3> _5497;
                    if (_5548)
                    {
                        float2 _5551 = _5541 * 2.0;
                        _5496[0] = float2(3.0) - _5551;
                        _5496[1] = float2(1.0) + _5551;
                        _5497[0] = ((float2(2.0) - _5541) / _5496[0]) - float2(1.0);
                        _5497[1] = (_5541 / _5496[1]) + float2(1.0);
                    }
                    else
                    {
                        float2 _5578 = _5541 * 3.0;
                        _5496[0] = float2(4.0) - _5578;
                        _5496[1] = float2(7.0);
                        _5496[2] = float2(1.0) + _5578;
                        _5497[0] = ((float2(3.0) - (_5541 * 2.0)) / _5496[0]) - float2(2.0);
                        _5497[1] = (float2(3.0) + _5541) / _5496[1];
                        _5497[2] = (_5541 / _5496[2]) + float2(2.0);
                    }
                    int _17799 = _5548 ? 2 : 3;
                    int _16535;
                    float _16538;
                    _16538 = 0.0;
                    _16535 = 0;
                    float _16544;
                    for (; _16535 < _17799; _16538 = _16544, _16535++)
                    {
                        _16544 = _16538;
                        for (int _16541 = 0; _16541 < _17799; )
                        {
                            _16544 += ((_5496[_16541].x * _5496[_16535].y) * spvDepthCast(_303).sample_compare(_303Smplr, float3(fast::clamp(_283._m22.xy * (_5544 + float2(_5497[_16541].x, _5497[_16535].y)), _5486.xy, _5486.zw), _5449).xy, _5449));
                            _16541++;
                            continue;
                        }
                    }
                    _16545 = _16538 * (_5548 ? 0.0625 : 0.0069444444961845874786376953125);
                    break;
                } while(false);
                _16546 = _16545;
                break;
            } while(false);
            float3 _16583;
            float _16586;
            if (_5288 > _283._m17[_16533])
            {
                float _5342 = (_5288 - _283._m17[_16533]) / (_283._m16[_16533] - _283._m17[_16533]);
                int _5344 = _16533 + 1;
                float3 _16584;
                float _16587;
                if (_5344 < _5280)
                {
                    float _16566;
                    do
                    {
                        float4 _5691 = _283._m14[_5344] * float4(in.m_3037 + (_3677 * _283._m18[_5344]), 1.0);
                        float _5694 = _5691.x;
                        bool _5695 = _5694 < 0.0;
                        bool _5702;
                        if (!_5695)
                        {
                            _5702 = _5694 > 1.0;
                        }
                        else
                        {
                            _5702 = _5695;
                        }
                        bool _5709;
                        if (!_5702)
                        {
                            _5709 = _5691.y < 0.0;
                        }
                        else
                        {
                            _5709 = _5702;
                        }
                        bool _5716;
                        if (!_5709)
                        {
                            _5716 = _5691.y > 1.0;
                        }
                        else
                        {
                            _5716 = _5709;
                        }
                        if (_5716)
                        {
                            _16566 = 1.0;
                            break;
                        }
                        float2 _5729 = float2(float(_5344 & 1), float(_5344 >> 1)) * _283._m23.xy;
                        float _5736 = fast::min(_5691.z, 1.0) - _283._m19[_5344];
                        float2 _5755 = _283._m22.xy * 0.5;
                        float2 _5760 = _5729 + (_5691.xy * _283._m23.xy);
                        float4 _5773 = float4(_5729 + _5755, (_5729 + _283._m23.xy) - _5755);
                        float _16565;
                        do
                        {
                            int _5799 = int(_283._m22.z);
                            if (_5799 <= 0)
                            {
                                _16565 = spvDepthCast(_303).sample_compare(_303Smplr, float3(fast::clamp(_5760, _5773.xy, _5773.zw), _5736).xy, _5736);
                                break;
                            }
                            float2 _5822 = (_5760 / _283._m22.xy) + float2(0.5);
                            float2 _5823 = floor(_5822);
                            float2 _5828 = _5822 - _5823;
                            float2 _5831 = _5823 - float2(0.5);
                            bool _5835 = _5799 == 1;
                            spvUnsafeArray<float2, 3> _5783;
                            spvUnsafeArray<float2, 3> _5784;
                            if (_5835)
                            {
                                float2 _5838 = _5828 * 2.0;
                                _5783[0] = float2(3.0) - _5838;
                                _5783[1] = float2(1.0) + _5838;
                                _5784[0] = ((float2(2.0) - _5828) / _5783[0]) - float2(1.0);
                                _5784[1] = (_5828 / _5783[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _5865 = _5828 * 3.0;
                                _5783[0] = float2(4.0) - _5865;
                                _5783[1] = float2(7.0);
                                _5783[2] = float2(1.0) + _5865;
                                _5784[0] = ((float2(3.0) - (_5828 * 2.0)) / _5783[0]) - float2(2.0);
                                _5784[1] = (float2(3.0) + _5828) / _5783[1];
                                _5784[2] = (_5828 / _5783[2]) + float2(2.0);
                            }
                            int _17801 = _5835 ? 2 : 3;
                            int _16555;
                            float _16558;
                            _16558 = 0.0;
                            _16555 = 0;
                            float _16564;
                            for (; _16555 < _17801; _16558 = _16564, _16555++)
                            {
                                _16564 = _16558;
                                for (int _16561 = 0; _16561 < _17801; )
                                {
                                    _16564 += ((_5783[_16561].x * _5783[_16555].y) * spvDepthCast(_303).sample_compare(_303Smplr, float3(fast::clamp(_283._m22.xy * (_5831 + float2(_5784[_16561].x, _5784[_16555].y)), _5773.xy, _5773.zw), _5736).xy, _5736));
                                    _16561++;
                                    continue;
                                }
                            }
                            _16565 = _16558 * (_5835 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _16566 = _16565;
                        break;
                    } while(false);
                    _16587 = mix(_16546, _16566, _5342);
                    _16584 = mix(_657[_16533], _657[_5344], float3(_5342));
                }
                else
                {
                    _16587 = mix(_16546, 1.0, _5342);
                    _16584 = _657[_16533];
                }
                _16586 = _16587;
                _16583 = _16584;
            }
            else
            {
                _16586 = _16546;
                _16583 = _657[_16533];
            }
            _16589 = select(float3(1.0), _16583, bool3(_283._m22.w > 0.5));
            _16588 = _16586;
            break;
        } while(false);
        _16752 = _16588;
        _16712 = _16618 * _16589;
    }
    else
    {
        _16752 = 1.0;
        _16712 = _16618;
    }
    float3 _3708 = _283._m5.xyz * _283._m4.w;
    bool _3712 = _2876._m6.w > 0.5;
    float _16641;
    if (_3712)
    {
        _16641 = 1.0;
    }
    else
    {
        _16641 = 1.0 + (_2876._m4.w * (_3352.sample(_2533, _3419).x - 1.0));
    }
    float _3732 = abs(in.m_2952.w);
    float _17037;
    if (_3732 > 0.0)
    {
        _17037 = _16641 * fast::min(_3732, 1.0);
    }
    else
    {
        _17037 = _16641;
    }
    float3 _17278;
    float3 _17348;
    if (!_3629)
    {
        float _3748 = dot(_16718, _3659);
        float3 _17259;
        if (_283._m29.x > 0.5)
        {
            float _6016 = (_283._m29.z * _16718.x) - (_283._m29.w * _16718.z);
            float _6029 = (_283._m29.w * _16718.x) + (_283._m29.z * _16718.z);
            float _6047 = 1.09254801273345947265625 * _6016;
            spvUnsafeArray<float, 9> _15513 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _16718.y, 0.48860299587249755859375 * _6029, 0.48860299587249755859375 * _6016, _6047 * _16718.y, (1.09254801273345947265625 * _16718.y) * _6029, 0.3153919875621795654296875 * (((3.0 * _6029) * _6029) - 1.0), _6047 * _6029, 0.546274006366729736328125 * ((_6016 * _6016) - (_16718.y * _16718.y)) });
            spvUnsafeArray<float, 9> _5961 = _15513;
            float3 _17258;
            _17258 = float3(0.0);
            for (int _17257 = 0; _17257 < 9; )
            {
                _17258 += (_2531.read(uint2((int2(496, 256) + int2(_17257, 0))), 0).xyz * _5961[_17257]);
                _17257++;
                continue;
            }
            _17259 = fast::max(_17258, float3(0.0)) * _283._m29.y;
        }
        else
        {
            _17259 = mix(_283._m9.xyz, _283._m8.xyz, float3((_16718.y * 0.5) + 0.5)) * _283._m8.w;
        }
        float3 _17264;
        if (_283._m34.y > 0.5)
        {
            int _6224 = int(_283._m34.y);
            int _6227 = int(_283._m34.x);
            float3 _17263;
            _17263 = _17259;
            float3 _17666;
            for (int _17262 = 0; _17262 < _6224; _17263 = _17666, _17262++)
            {
                int _6239 = 8 * (_6227 + _17262);
                float4 _6448 = as_type<float4>(_1281._m0[_6239 + 3]);
                float4 _6492 = as_type<float4>(_1281._m0[_6239]);
                float4 _6498 = as_type<float4>(_1281._m0[_6239 + 1]);
                float4 _6504 = as_type<float4>(_1281._m0[_6239 + 2]);
                float3 _6466 = _6492.xyz;
                float _6470 = _6492.w;
                float3 _6473 = _6498.xyz;
                float _6477 = _6498.w;
                float3 _6480 = _6504.xyz;
                float _6484 = _6504.w;
                float3 _6486 = float3(dot(_6466, in.m_3037) + _6470, dot(_6473, in.m_3037) + _6477, dot(_6480, in.m_3037) + _6484);
                float3 _6248 = _6448.xyz;
                float _6250 = _6448.w;
                float _17629;
                do
                {
                    float3 _6516 = _6248 - abs(_6486);
                    float _6524 = fast::min(_6516.x, fast::min(_6516.y, _6516.z));
                    if (_6524 <= 0.0)
                    {
                        _17629 = 0.0;
                        break;
                    }
                    if (_6250 <= 0.0)
                    {
                        _17629 = 1.0;
                        break;
                    }
                    float _6536 = fast::min(_6524 / _6250, 1.0);
                    _17629 = (_6536 * _6536) * (3.0 - (2.0 * _6536));
                    break;
                } while(false);
                if (_17629 <= 0.0)
                {
                    _17666 = _17263;
                    continue;
                }
                float3 _6259 = as_type<float4>(_1281._m0[_6239 + 4]).xyz;
                float4 _6557 = as_type<float4>(_1281._m0[_6239 + 5]);
                int _6563 = int(((device uint*)&_1281._m0[_6239 + 6])[0u]);
                float _6573 = dot(_6466, _16718);
                float _6579 = dot(_6473, _16718);
                float _6585 = dot(_6480, _16718);
                float3 _6586 = float3(_6573, _6579, _6585);
                float3 _6279 = (in.m_3037 + (_16718 * _6557.x)) + (_3666 * _6557.y);
                float3 _6298 = fast::clamp((((float3(dot(_6466, _6279) + _6470, dot(_6473, _6279) + _6477, dot(_6480, _6279) + _6484) + _6248) / fast::max(_6248 * 2.0, float3(9.9999999747524270787835121154785e-07))) * _6259) - float3(0.5), float3(0.0), _6259 - float3(1.0));
                int3 _6300 = int3(_6259);
                int3 _6307 = min(int3(_6298), max((_6300 - int3(2)), int3(0)));
                float3 _6311 = _6298 - float3(_6307);
                float _6666 = 0.48860299587249755859375 * _6579;
                float _6669 = 0.48860299587249755859375 * _6585;
                float _6672 = 0.48860299587249755859375 * _6573;
                float _6677 = 1.09254801273345947265625 * _6573;
                float _6680 = _6677 * _6579;
                float _6686 = (1.09254801273345947265625 * _6579) * _6585;
                float _6694 = 0.3153919875621795654296875 * (((3.0 * _6585) * _6585) - 1.0);
                float _6700 = _6677 * _6585;
                float _6714 = 0.546274006366729736328125 * ((_6573 * _6573) - (_6579 * _6579));
                int3 _6733 = _6300 - int3(1);
                int3 _6734 = min(_6307, _6733);
                int _6739 = _6300.x;
                int _6743 = _6300.y;
                int _6751 = _6563 + ((_6734.x + (_6739 * (_6734.y + (_6743 * _6734.z)))) * 4);
                float3 _6754 = float3(1.0) - _6311;
                float3 _6772 = (((((float3(_6734) + float3(0.5)) / _6259) * _6248) * 2.0) - _6248) - _6486;
                float _6782 = dot(_6772 * rsqrt(fast::max(dot(_6772, _6772), 1.0000000133514319600180897396058e-10)), _6586) + 1.0;
                float _6785 = _6754.x;
                float _6787 = _6754.y;
                float _6788 = _6785 * _6787;
                float _6790 = _6754.z;
                int _6814 = _6751 + 3;
                float _6800 = ((_6788 * _6790) * ((0.25 * (_6782 * _6782)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_6814])[1u])).y > 0.5);
                int _6844 = _6751 + 1;
                int _6848 = _6751 + 2;
                float2 _6860 = float2(as_type<half2>(_1281._m0[_6751].y));
                float2 _6869 = float2(as_type<half2>(_1281._m0[_6844].x));
                float2 _6878 = float2(as_type<half2>(_1281._m0[_6844].w));
                float2 _6887 = float2(as_type<half2>(_1281._m0[_6848].z));
                float3 _6975 = (((((((float3(float2(as_type<half2>(_1281._m0[_6751].x)), _6860.x) * 0.2820949852466583251953125) + (float3(_6860.y, float2(as_type<half2>(_1281._m0[_6751].z))) * _6666)) + (float3(float2(as_type<half2>(_1281._m0[_6751].w)), _6869.x) * _6669)) + (float3(_6869.y, float2(as_type<half2>(_1281._m0[_6844].y))) * _6672)) + (float3(float2(as_type<half2>(_1281._m0[_6844].z)), _6878.x) * _6680)) + (float3(_6878.y, float2(as_type<half2>(_1281._m0[_6848].x))) * _6686)) + (float3(float2(as_type<half2>(_1281._m0[_6848].y)), _6887.x) * _6694)) + (float3(_6887.y, float2(as_type<half2>(_1281._m0[_6848].w))) * _6700);
                int3 _7003 = min((_6307 + int3(1, 0, 0)), _6733);
                int _7020 = _6563 + ((_7003.x + (_6739 * (_7003.y + (_6743 * _7003.z)))) * 4);
                float3 _7041 = (((((float3(_7003) + float3(0.5)) / _6259) * _6248) * 2.0) - _6248) - _6486;
                float _7051 = dot(_7041 * rsqrt(fast::max(dot(_7041, _7041), 1.0000000133514319600180897396058e-10)), _6586) + 1.0;
                float _7057 = _6311.x * _6787;
                int _7083 = _7020 + 3;
                float _7069 = ((_7057 * _6790) * ((0.25 * (_7051 * _7051)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_7083])[1u])).y > 0.5);
                int _7113 = _7020 + 1;
                int _7117 = _7020 + 2;
                float2 _7129 = float2(as_type<half2>(_1281._m0[_7020].y));
                float2 _7138 = float2(as_type<half2>(_1281._m0[_7113].x));
                float2 _7147 = float2(as_type<half2>(_1281._m0[_7113].w));
                float2 _7156 = float2(as_type<half2>(_1281._m0[_7117].z));
                float3 _7244 = (((((((float3(float2(as_type<half2>(_1281._m0[_7020].x)), _7129.x) * 0.2820949852466583251953125) + (float3(_7129.y, float2(as_type<half2>(_1281._m0[_7020].z))) * _6666)) + (float3(float2(as_type<half2>(_1281._m0[_7020].w)), _7138.x) * _6669)) + (float3(_7138.y, float2(as_type<half2>(_1281._m0[_7113].y))) * _6672)) + (float3(float2(as_type<half2>(_1281._m0[_7113].z)), _7147.x) * _6680)) + (float3(_7147.y, float2(as_type<half2>(_1281._m0[_7117].x))) * _6686)) + (float3(float2(as_type<half2>(_1281._m0[_7117].y)), _7156.x) * _6694)) + (float3(_7156.y, float2(as_type<half2>(_1281._m0[_7117].w))) * _6700);
                int3 _7272 = min((_6307 + int3(0, 1, 0)), _6733);
                int _7289 = _6563 + ((_7272.x + (_6739 * (_7272.y + (_6743 * _7272.z)))) * 4);
                float3 _7310 = (((((float3(_7272) + float3(0.5)) / _6259) * _6248) * 2.0) - _6248) - _6486;
                float _7320 = dot(_7310 * rsqrt(fast::max(dot(_7310, _7310), 1.0000000133514319600180897396058e-10)), _6586) + 1.0;
                float _7326 = _6785 * _6311.y;
                int _7352 = _7289 + 3;
                float _7338 = ((_7326 * _6790) * ((0.25 * (_7320 * _7320)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_7352])[1u])).y > 0.5);
                int _7382 = _7289 + 1;
                int _7386 = _7289 + 2;
                float2 _7398 = float2(as_type<half2>(_1281._m0[_7289].y));
                float2 _7407 = float2(as_type<half2>(_1281._m0[_7382].x));
                float2 _7416 = float2(as_type<half2>(_1281._m0[_7382].w));
                float2 _7425 = float2(as_type<half2>(_1281._m0[_7386].z));
                float3 _7513 = (((((((float3(float2(as_type<half2>(_1281._m0[_7289].x)), _7398.x) * 0.2820949852466583251953125) + (float3(_7398.y, float2(as_type<half2>(_1281._m0[_7289].z))) * _6666)) + (float3(float2(as_type<half2>(_1281._m0[_7289].w)), _7407.x) * _6669)) + (float3(_7407.y, float2(as_type<half2>(_1281._m0[_7382].y))) * _6672)) + (float3(float2(as_type<half2>(_1281._m0[_7382].z)), _7416.x) * _6680)) + (float3(_7416.y, float2(as_type<half2>(_1281._m0[_7386].x))) * _6686)) + (float3(float2(as_type<half2>(_1281._m0[_7386].y)), _7425.x) * _6694)) + (float3(_7425.y, float2(as_type<half2>(_1281._m0[_7386].w))) * _6700);
                int3 _7541 = min((_6307 + int3(1, 1, 0)), _6733);
                int _7558 = _6563 + ((_7541.x + (_6739 * (_7541.y + (_6743 * _7541.z)))) * 4);
                float3 _7579 = (((((float3(_7541) + float3(0.5)) / _6259) * _6248) * 2.0) - _6248) - _6486;
                float _7589 = dot(_7579 * rsqrt(fast::max(dot(_7579, _7579), 1.0000000133514319600180897396058e-10)), _6586) + 1.0;
                float _7595 = _6311.x * _6311.y;
                int _7621 = _7558 + 3;
                float _7607 = ((_7595 * _6790) * ((0.25 * (_7589 * _7589)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_7621])[1u])).y > 0.5);
                int _7651 = _7558 + 1;
                int _7655 = _7558 + 2;
                float2 _7667 = float2(as_type<half2>(_1281._m0[_7558].y));
                float2 _7676 = float2(as_type<half2>(_1281._m0[_7651].x));
                float2 _7685 = float2(as_type<half2>(_1281._m0[_7651].w));
                float2 _7694 = float2(as_type<half2>(_1281._m0[_7655].z));
                float3 _7782 = (((((((float3(float2(as_type<half2>(_1281._m0[_7558].x)), _7667.x) * 0.2820949852466583251953125) + (float3(_7667.y, float2(as_type<half2>(_1281._m0[_7558].z))) * _6666)) + (float3(float2(as_type<half2>(_1281._m0[_7558].w)), _7676.x) * _6669)) + (float3(_7676.y, float2(as_type<half2>(_1281._m0[_7651].y))) * _6672)) + (float3(float2(as_type<half2>(_1281._m0[_7651].z)), _7685.x) * _6680)) + (float3(_7685.y, float2(as_type<half2>(_1281._m0[_7655].x))) * _6686)) + (float3(float2(as_type<half2>(_1281._m0[_7655].y)), _7694.x) * _6694)) + (float3(_7694.y, float2(as_type<half2>(_1281._m0[_7655].w))) * _6700);
                int3 _7810 = min((_6307 + int3(0, 0, 1)), _6733);
                int _7827 = _6563 + ((_7810.x + (_6739 * (_7810.y + (_6743 * _7810.z)))) * 4);
                float3 _7848 = (((((float3(_7810) + float3(0.5)) / _6259) * _6248) * 2.0) - _6248) - _6486;
                float _7858 = dot(_7848 * rsqrt(fast::max(dot(_7848, _7848), 1.0000000133514319600180897396058e-10)), _6586) + 1.0;
                int _7890 = _7827 + 3;
                float _7876 = ((_6788 * _6311.z) * ((0.25 * (_7858 * _7858)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_7890])[1u])).y > 0.5);
                int _7920 = _7827 + 1;
                int _7924 = _7827 + 2;
                float2 _7936 = float2(as_type<half2>(_1281._m0[_7827].y));
                float2 _7945 = float2(as_type<half2>(_1281._m0[_7920].x));
                float2 _7954 = float2(as_type<half2>(_1281._m0[_7920].w));
                float2 _7963 = float2(as_type<half2>(_1281._m0[_7924].z));
                float3 _8051 = (((((((float3(float2(as_type<half2>(_1281._m0[_7827].x)), _7936.x) * 0.2820949852466583251953125) + (float3(_7936.y, float2(as_type<half2>(_1281._m0[_7827].z))) * _6666)) + (float3(float2(as_type<half2>(_1281._m0[_7827].w)), _7945.x) * _6669)) + (float3(_7945.y, float2(as_type<half2>(_1281._m0[_7920].y))) * _6672)) + (float3(float2(as_type<half2>(_1281._m0[_7920].z)), _7954.x) * _6680)) + (float3(_7954.y, float2(as_type<half2>(_1281._m0[_7924].x))) * _6686)) + (float3(float2(as_type<half2>(_1281._m0[_7924].y)), _7963.x) * _6694)) + (float3(_7963.y, float2(as_type<half2>(_1281._m0[_7924].w))) * _6700);
                float4 _6378 = (((float4((_6975 + (float3(float2(as_type<half2>(_1281._m0[_6814].x)), float2(as_type<half2>(_1281._m0[_6814].y)).x) * _6714)) * _6800, _6800) + float4((_7244 + (float3(float2(as_type<half2>(_1281._m0[_7083].x)), float2(as_type<half2>(_1281._m0[_7083].y)).x) * _6714)) * _7069, _7069)) + float4((_7513 + (float3(float2(as_type<half2>(_1281._m0[_7352].x)), float2(as_type<half2>(_1281._m0[_7352].y)).x) * _6714)) * _7338, _7338)) + float4((_7782 + (float3(float2(as_type<half2>(_1281._m0[_7621].x)), float2(as_type<half2>(_1281._m0[_7621].y)).x) * _6714)) * _7607, _7607)) + float4((_8051 + (float3(float2(as_type<half2>(_1281._m0[_7890].x)), float2(as_type<half2>(_1281._m0[_7890].y)).x) * _6714)) * _7876, _7876);
                int3 _8079 = min((_6307 + int3(1, 0, 1)), _6733);
                int _8096 = _6563 + ((_8079.x + (_6739 * (_8079.y + (_6743 * _8079.z)))) * 4);
                float3 _8117 = (((((float3(_8079) + float3(0.5)) / _6259) * _6248) * 2.0) - _6248) - _6486;
                float _8127 = dot(_8117 * rsqrt(fast::max(dot(_8117, _8117), 1.0000000133514319600180897396058e-10)), _6586) + 1.0;
                int _8159 = _8096 + 3;
                float _8145 = ((_7057 * _6311.z) * ((0.25 * (_8127 * _8127)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_8159])[1u])).y > 0.5);
                int _8189 = _8096 + 1;
                int _8193 = _8096 + 2;
                float2 _8205 = float2(as_type<half2>(_1281._m0[_8096].y));
                float2 _8214 = float2(as_type<half2>(_1281._m0[_8189].x));
                float2 _8223 = float2(as_type<half2>(_1281._m0[_8189].w));
                float2 _8232 = float2(as_type<half2>(_1281._m0[_8193].z));
                float3 _8320 = (((((((float3(float2(as_type<half2>(_1281._m0[_8096].x)), _8205.x) * 0.2820949852466583251953125) + (float3(_8205.y, float2(as_type<half2>(_1281._m0[_8096].z))) * _6666)) + (float3(float2(as_type<half2>(_1281._m0[_8096].w)), _8214.x) * _6669)) + (float3(_8214.y, float2(as_type<half2>(_1281._m0[_8189].y))) * _6672)) + (float3(float2(as_type<half2>(_1281._m0[_8189].z)), _8223.x) * _6680)) + (float3(_8223.y, float2(as_type<half2>(_1281._m0[_8193].x))) * _6686)) + (float3(float2(as_type<half2>(_1281._m0[_8193].y)), _8232.x) * _6694)) + (float3(_8232.y, float2(as_type<half2>(_1281._m0[_8193].w))) * _6700);
                int3 _8348 = min((_6307 + int3(0, 1, 1)), _6733);
                int _8365 = _6563 + ((_8348.x + (_6739 * (_8348.y + (_6743 * _8348.z)))) * 4);
                float3 _8386 = (((((float3(_8348) + float3(0.5)) / _6259) * _6248) * 2.0) - _6248) - _6486;
                float _8396 = dot(_8386 * rsqrt(fast::max(dot(_8386, _8386), 1.0000000133514319600180897396058e-10)), _6586) + 1.0;
                int _8428 = _8365 + 3;
                float _8414 = ((_7326 * _6311.z) * ((0.25 * (_8396 * _8396)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_8428])[1u])).y > 0.5);
                int _8458 = _8365 + 1;
                int _8462 = _8365 + 2;
                float2 _8474 = float2(as_type<half2>(_1281._m0[_8365].y));
                float2 _8483 = float2(as_type<half2>(_1281._m0[_8458].x));
                float2 _8492 = float2(as_type<half2>(_1281._m0[_8458].w));
                float2 _8501 = float2(as_type<half2>(_1281._m0[_8462].z));
                float3 _8589 = (((((((float3(float2(as_type<half2>(_1281._m0[_8365].x)), _8474.x) * 0.2820949852466583251953125) + (float3(_8474.y, float2(as_type<half2>(_1281._m0[_8365].z))) * _6666)) + (float3(float2(as_type<half2>(_1281._m0[_8365].w)), _8483.x) * _6669)) + (float3(_8483.y, float2(as_type<half2>(_1281._m0[_8458].y))) * _6672)) + (float3(float2(as_type<half2>(_1281._m0[_8458].z)), _8492.x) * _6680)) + (float3(_8492.y, float2(as_type<half2>(_1281._m0[_8462].x))) * _6686)) + (float3(float2(as_type<half2>(_1281._m0[_8462].y)), _8501.x) * _6694)) + (float3(_8501.y, float2(as_type<half2>(_1281._m0[_8462].w))) * _6700);
                int3 _8617 = min((_6307 + int3(1)), _6733);
                int _8634 = _6563 + ((_8617.x + (_6739 * (_8617.y + (_6743 * _8617.z)))) * 4);
                float3 _8655 = (((((float3(_8617) + float3(0.5)) / _6259) * _6248) * 2.0) - _6248) - _6486;
                float _8665 = dot(_8655 * rsqrt(fast::max(dot(_8655, _8655), 1.0000000133514319600180897396058e-10)), _6586) + 1.0;
                int _8697 = _8634 + 3;
                float _8683 = ((_7595 * _6311.z) * ((0.25 * (_8665 * _8665)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_8697])[1u])).y > 0.5);
                int _8727 = _8634 + 1;
                int _8731 = _8634 + 2;
                float2 _8743 = float2(as_type<half2>(_1281._m0[_8634].y));
                float2 _8752 = float2(as_type<half2>(_1281._m0[_8727].x));
                float2 _8761 = float2(as_type<half2>(_1281._m0[_8727].w));
                float2 _8770 = float2(as_type<half2>(_1281._m0[_8731].z));
                float3 _8858 = (((((((float3(float2(as_type<half2>(_1281._m0[_8634].x)), _8743.x) * 0.2820949852466583251953125) + (float3(_8743.y, float2(as_type<half2>(_1281._m0[_8634].z))) * _6666)) + (float3(float2(as_type<half2>(_1281._m0[_8634].w)), _8752.x) * _6669)) + (float3(_8752.y, float2(as_type<half2>(_1281._m0[_8727].y))) * _6672)) + (float3(float2(as_type<half2>(_1281._m0[_8727].z)), _8761.x) * _6680)) + (float3(_8761.y, float2(as_type<half2>(_1281._m0[_8731].x))) * _6686)) + (float3(float2(as_type<half2>(_1281._m0[_8731].y)), _8770.x) * _6694)) + (float3(_8770.y, float2(as_type<half2>(_1281._m0[_8731].w))) * _6700);
                float4 _6417 = ((_6378 + float4((_8320 + (float3(float2(as_type<half2>(_1281._m0[_8159].x)), float2(as_type<half2>(_1281._m0[_8159].y)).x) * _6714)) * _8145, _8145)) + float4((_8589 + (float3(float2(as_type<half2>(_1281._m0[_8428].x)), float2(as_type<half2>(_1281._m0[_8428].y)).x) * _6714)) * _8414, _8414)) + float4((_8858 + (float3(float2(as_type<half2>(_1281._m0[_8697].x)), float2(as_type<half2>(_1281._m0[_8697].y)).x) * _6714)) * _8683, _8683);
                float _6421 = _6417.w;
                float3 _17667;
                if (_6421 > 9.9999997473787516355514526367188e-06)
                {
                    _17667 = mix(_17263, (fast::max(_6417.xyz, float3(0.0)) / float3(_6421)) * _6557.z, float3(_17629));
                }
                else
                {
                    _17667 = _17263;
                }
                _17666 = _17667;
            }
            _17264 = _17263;
        }
        else
        {
            _17264 = _17259;
        }
        float3 _3814 = (_16712 * ((_17264 * _17037) + ((_3708 * fast::max(_3748, 0.0)) * _16752))) + ((_3708 * ((powr(fast::max(dot(_16718, _3671), 0.0), _2876._m1.w) * _2876._m1.z) * step(0.0, _3748))) * _16752);
        float3 _17279;
        if (_283._m13.w > 0.5)
        {
            float2 _8896 = fast::clamp(floor(gl_FragCoord.xy * _283._m12.xy), float2(0.0), _283._m13.xy - float2(1.0));
            uint _8924 = uint((((fast::clamp(floor((log2(fast::max(dot(_283._m11.xyz, in.m_3037) + _283._m11.w, 9.9999999747524270787835121154785e-07)) * _283._m12.z) + _283._m12.w), 0.0, _283._m13.z - 1.0) * _283._m13.y) + _8896.y) * _283._m13.x) + _8896.x);
            uint _8926 = _8924 >> uint(2);
            uint _8928 = _8924 & 3u;
            uint _8932 = _3167._m0[_8926][_8928] & 65535u;
            uint _8934 = _3167._m0[_8926][_8928] >> uint(16);
            float3 _17280;
            _17280 = _3814;
            float3 _3894;
            spvUnsafeArray<float2, 3> _9342;
            spvUnsafeArray<float2, 3> _9343;
            spvUnsafeArray<float2, 3> _9555;
            spvUnsafeArray<float2, 3> _9556;
            for (uint _17277 = _8932; _17277 < (_8932 + _8934); _17280 = _3894, _17277++)
            {
                uint _8940 = _17277 / 3u;
                uint _8953 = (_3188._m0[_8940 >> uint(2)][_8940 & 3u] >> ((_17277 - (_8940 * 3u)) * 10u)) & 1023u;
                float3 _8970 = _3030._m0[_8953].xyz - in.m_3037;
                float _8973 = dot(_8970, _8970);
                float _8977 = _8973 * _3030._m0[_8953].w;
                float _8982 = fast::clamp(1.0 - (_8977 * _8977), 0.0, 1.0);
                float3 _8987 = _8970 * rsqrt(fast::max(_8973, 9.9999999392252902907785028219223e-09));
                float _9005 = fast::clamp((dot(-_8987, _3073._m0[_8953].xyz) * _3065._m0[_8953].w) + _3073._m0[_8953].w, 0.0, 1.0);
                float3 _9018 = _3065._m0[_8953].xyz * ((((_8982 * _8982) * _9005) * _9005) / fast::max(_8973, 9.9999997473787516355514526367188e-05));
                float3 _17594;
                if (_3682)
                {
                    float _17540;
                    do
                    {
                        uint _9054 = uint(_283._m21.z);
                        if (_8953 < _9054)
                        {
                            float _9076 = _283._m26[_8953].z * fast::max((_283._m15[_8953] * float4(in.m_3037, 1.0)).w, 0.0);
                            float4 _9100 = _283._m15[_8953] * float4((in.m_3037 + (_3677 * (_9076 * _283._m25.x))) + (_8987 * (_9076 * _283._m25.y)), 1.0);
                            float _9102 = _9100.w;
                            if (_9102 <= 0.0)
                            {
                                _17540 = 1.0;
                                break;
                            }
                            float3 _9111 = _9100.xyz / float3(_9102);
                            float _9113 = _9111.x;
                            bool _9114 = _9113 < 0.0;
                            bool _9121;
                            if (!_9114)
                            {
                                _9121 = _9113 > 1.0;
                            }
                            else
                            {
                                _9121 = _9114;
                            }
                            bool _9128;
                            if (!_9121)
                            {
                                _9128 = _9111.y < 0.0;
                            }
                            else
                            {
                                _9128 = _9121;
                            }
                            bool _9135;
                            if (!_9128)
                            {
                                _9135 = _9111.y > 1.0;
                            }
                            else
                            {
                                _9135 = _9128;
                            }
                            bool _9142;
                            if (!_9135)
                            {
                                _9142 = _9111.z > 1.0;
                            }
                            else
                            {
                                _9142 = _9135;
                            }
                            if (_9142)
                            {
                                _17540 = 1.0;
                                break;
                            }
                            float _9148 = _9111.z;
                            float2 _9314 = _283._m22.xy * 0.5;
                            float2 _9319 = _283._m26[_8953].xy + (_9111.xy * _283._m23.zw);
                            float4 _9332 = float4(_283._m26[_8953].xy + _9314, (_283._m26[_8953].xy + _283._m23.zw) - _9314);
                            float _17539;
                            do
                            {
                                int _9358 = int(_283._m22.z);
                                if (_9358 <= 0)
                                {
                                    float2 _9368 = fast::clamp(_9319, _9332.xy, _9332.zw);
                                    _17539 = spvDepthCast(_303).sample_compare(_303Smplr, float3(_9368, _9148).xy, _9148);
                                    break;
                                }
                                float2 _9381 = (_9319 / _283._m22.xy) + float2(0.5);
                                float2 _9382 = floor(_9381);
                                float2 _9387 = _9381 - _9382;
                                float2 _9390 = _9382 - float2(0.5);
                                bool _9394 = _9358 == 1;
                                if (_9394)
                                {
                                    float2 _9397 = _9387 * 2.0;
                                    _9342[0] = float2(3.0) - _9397;
                                    _9342[1] = float2(1.0) + _9397;
                                    _9343[0] = ((float2(2.0) - _9387) / _9342[0]) - float2(1.0);
                                    _9343[1] = (_9387 / _9342[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _9424 = _9387 * 3.0;
                                    _9342[0] = float2(4.0) - _9424;
                                    _9342[1] = float2(7.0);
                                    _9342[2] = float2(1.0) + _9424;
                                    _9343[0] = ((float2(3.0) - (_9387 * 2.0)) / _9342[0]) - float2(2.0);
                                    _9343[1] = (float2(3.0) + _9387) / _9342[1];
                                    _9343[2] = (_9387 / _9342[2]) + float2(2.0);
                                }
                                int _17806 = _9394 ? 2 : 3;
                                int _17529;
                                float _17532;
                                _17532 = 0.0;
                                _17529 = 0;
                                float _17538;
                                for (; _17529 < _17806; _17532 = _17538, _17529++)
                                {
                                    _17538 = _17532;
                                    for (int _17535 = 0; _17535 < _17806; )
                                    {
                                        _17538 += ((_9342[_17535].x * _9342[_17529].y) * spvDepthCast(_303).sample_compare(_303Smplr, float3(fast::clamp(_283._m22.xy * (_9390 + float2(_9343[_17535].x, _9343[_17529].y)), _9332.xy, _9332.zw), _9148).xy, _9148));
                                        _17535++;
                                        continue;
                                    }
                                }
                                _17539 = _17532 * (_9394 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _17540 = _17539;
                            break;
                        }
                        uint _9158 = _8953 - _9054;
                        if (_9158 >= uint(_283._m21.w))
                        {
                            _17540 = 1.0;
                            break;
                        }
                        float _9179 = _283._m27[_9158].w * length(in.m_3037 - _283._m27[_9158].xyz);
                        float3 _9197 = ((in.m_3037 + (_3677 * (_9179 * _283._m25.x))) + (_8987 * (_9179 * _283._m25.y))) - _283._m27[_9158].xyz;
                        float3 _9199 = abs(_9197);
                        float _9201 = _9199.x;
                        float _9203 = _9199.y;
                        bool _9204 = _9201 >= _9203;
                        bool _9212;
                        if (_9204)
                        {
                            _9212 = _9201 >= _9199.z;
                        }
                        else
                        {
                            _9212 = _9204;
                        }
                        float _17514;
                        int _17516;
                        if (_9212)
                        {
                            _17516 = (_9197.x > 0.0) ? 0 : 1;
                            _17514 = _9201;
                        }
                        else
                        {
                            float _9224 = _9199.z;
                            bool _9225 = _9203 >= _9224;
                            int _17517;
                            if (_9225)
                            {
                                _17517 = (_9197.y > 0.0) ? 2 : 3;
                            }
                            else
                            {
                                _17517 = (_9197.z > 0.0) ? 4 : 5;
                            }
                            _17516 = _17517;
                            _17514 = _9225 ? _9203 : _9224;
                        }
                        if (_17514 <= 0.0)
                        {
                            _17540 = 1.0;
                            break;
                        }
                        float2 _9262 = float2(dot(_9197, _961[_17516]), dot(_9197, _970[_17516])) / float2(_17514 * _283._m24.z);
                        float _9269 = _283._m28[_9158].z + (_283._m28[_9158].w / _17514);
                        if (_9269 > 1.0)
                        {
                            _17540 = 1.0;
                            break;
                        }
                        float2 _9287 = _283._m28[_9158].xy + (float2(float(spvSMod(_17516, 3)), float(_17516 / 3)) * _283._m24.xy);
                        float2 _9527 = _283._m22.xy * 0.5;
                        float2 _9532 = _9287 + (float2(0.5 + (0.5 * _9262.x), 0.5 - (0.5 * _9262.y)) * _283._m24.xy);
                        float4 _9545 = float4(_9287 + _9527, (_9287 + _283._m24.xy) - _9527);
                        float _17528;
                        do
                        {
                            int _9571 = int(_283._m22.z);
                            if (_9571 <= 0)
                            {
                                _17528 = spvDepthCast(_303).sample_compare(_303Smplr, float3(fast::clamp(_9532, _9545.xy, _9545.zw), _9269).xy, _9269);
                                break;
                            }
                            float2 _9594 = (_9532 / _283._m22.xy) + float2(0.5);
                            float2 _9595 = floor(_9594);
                            float2 _9600 = _9594 - _9595;
                            float2 _9603 = _9595 - float2(0.5);
                            bool _9607 = _9571 == 1;
                            if (_9607)
                            {
                                float2 _9610 = _9600 * 2.0;
                                _9555[0] = float2(3.0) - _9610;
                                _9555[1] = float2(1.0) + _9610;
                                _9556[0] = ((float2(2.0) - _9600) / _9555[0]) - float2(1.0);
                                _9556[1] = (_9600 / _9555[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _9637 = _9600 * 3.0;
                                _9555[0] = float2(4.0) - _9637;
                                _9555[1] = float2(7.0);
                                _9555[2] = float2(1.0) + _9637;
                                _9556[0] = ((float2(3.0) - (_9600 * 2.0)) / _9555[0]) - float2(2.0);
                                _9556[1] = (float2(3.0) + _9600) / _9555[1];
                                _9556[2] = (_9600 / _9555[2]) + float2(2.0);
                            }
                            int _17809 = _9607 ? 2 : 3;
                            int _17518;
                            float _17521;
                            _17521 = 0.0;
                            _17518 = 0;
                            float _17527;
                            for (; _17518 < _17809; _17521 = _17527, _17518++)
                            {
                                _17527 = _17521;
                                for (int _17524 = 0; _17524 < _17809; )
                                {
                                    _17527 += ((_9555[_17524].x * _9555[_17518].y) * spvDepthCast(_303).sample_compare(_303Smplr, float3(fast::clamp(_283._m22.xy * (_9603 + float2(_9556[_17524].x, _9556[_17518].y)), _9545.xy, _9545.zw), _9269).xy, _9269));
                                    _17524++;
                                    continue;
                                }
                            }
                            _17528 = _17521 * (_9607 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _17540 = _17528;
                        break;
                    } while(false);
                    _17594 = _9018 * _17540;
                }
                else
                {
                    _17594 = _9018;
                }
                float _3865 = dot(_16718, _8987);
                _3894 = _17280 + (((_16712 * fast::max(_3865, 0.0)) * _17594) + (_17594 * ((powr(fast::max(dot(_16718, fast::normalize(_8987 + _3666)), 0.0), _2876._m1.w) * _2876._m1.z) * step(0.0, _3865))));
            }
            _17279 = _17280;
        }
        else
        {
            _17279 = _3814;
        }
        _17348 = _17264;
        _17278 = _17279;
    }
    else
    {
        float4 _3904 = _3899.sample(_2533, _3419);
        float _3915 = fast::clamp((_2876._m4.x * _3904.z) * in.m_3911.y, 0.0, 1.0);
        float _3926 = fast::clamp((_2876._m4.y * _3904.y) * in.m_3911.x, 0.04500000178813934326171875, 1.0);
        float _16708;
        float _16713;
        if (_16649 > 0.0)
        {
            _16713 = mix(_3915, _16682.y, _16649);
            _16708 = mix(_3926, fast::max(_16682.x, 0.04500000178813934326171875), _16649);
        }
        else
        {
            _16713 = _3915;
            _16708 = _3926;
        }
        float _3945 = _16708 * _16708;
        float3 _3950 = _16712 * (1.0 - _16713);
        float3 _3956 = mix(float3(0.039999999105930328369140625), _16712, float3(_16713));
        bool _3960 = _16528 > 0.0;
        float3 _16741;
        if (_3960)
        {
            float3 _3965 = dfdx(in.m_3037);
            float3 _3967 = dfdy(in.m_3037);
            float3 _3968 = cross(_3965, _3967);
            float3 _16742;
            if (dot(_3968, _3968) > 9.9999996826552253889678874634872e-21)
            {
                _16742 = fast::normalize((fast::normalize(_3968) * ((dot(_3968, _3666) < 0.0) ? (-1.0) : 1.0)) + (_16718 - _3522));
            }
            else
            {
                _16742 = _16718;
            }
            _16741 = _16742;
        }
        else
        {
            _16741 = _16718;
        }
        float _3994 = fast::max(dot(_16741, _3666), 9.9999997473787516355514526367188e-05);
        float _4003 = dot(_16741, _3659);
        float _4004 = fast::clamp(_4003, 0.0, 1.0);
        float _4009 = fast::clamp(dot(_16741, _3671), 0.0, 1.0);
        float _4014 = fast::clamp(dot(_3666, _3671), 0.0, 1.0);
        float _16745;
        float _16746;
        if (_3960)
        {
            _16746 = fast::max(_3994, 0.5);
            _16745 = fast::max(_4014, 0.5);
        }
        else
        {
            _16746 = _3994;
            _16745 = _4014;
        }
        float3 _9739 = float3(1.0) - _3956;
        float3 _9742 = _3956 + (_9739 * powr(1.0 - _16745, 5.0));
        float _9749 = _3945 * _3945;
        float _9754 = _9749 - 1.0;
        float _9756 = ((_4009 * _4009) * _9754) + 1.0;
        float _9776 = 1.0 - _9749;
        float _9780 = sqrt(((_16746 * _16746) * _9776) + _9749);
        float3 _4060 = (((((float3(1.0) - _9742) * _3950) * fast::clamp(dot(_16718, _3659), 0.0, 1.0)) + (((_9742 * ((_9749 / ((3.1415927410125732421875 * _9756) * _9756)) * (0.5 / fast::max((_4004 * _9780) + (_16746 * sqrt(((_4004 * _4004) * _9776) + _9749)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875) * _4004)) * _3708) * _16752;
        float3 _17074;
        if (_3960)
        {
            _17074 = _4060 + (((((_3950 * _3708) * _16752) * _16528) * fast::clamp(-_4003, 0.0, 1.0)) * (0.3499999940395355224609375 + (0.64999997615814208984375 * powr(fast::clamp(dot(-_3666, _3659), 0.0, 1.0), 3.0))));
        }
        else
        {
            _17074 = _4060;
        }
        float3 _16781;
        float3 _16808;
        float2 _16985;
        if (_283._m29.x > 0.5)
        {
            float4 _9813 = _2632.sample(_2634, (((float2(_16746, _16708) * 31.0) + float2(0.5)) * float2(0.03125)));
            float _9872 = (_283._m29.z * _16718.x) - (_283._m29.w * _16718.z);
            float _9885 = (_283._m29.w * _16718.x) + (_283._m29.z * _16718.z);
            float _9903 = 1.09254801273345947265625 * _9872;
            spvUnsafeArray<float, 9> _15375 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _16718.y, 0.48860299587249755859375 * _9885, 0.48860299587249755859375 * _9872, _9903 * _16718.y, (1.09254801273345947265625 * _16718.y) * _9885, 0.3153919875621795654296875 * (((3.0 * _9885) * _9885) - 1.0), _9903 * _9885, 0.546274006366729736328125 * ((_9872 * _9872) - (_16718.y * _16718.y)) });
            spvUnsafeArray<float, 9> _9817 = _15375;
            float3 _16764;
            _16764 = float3(0.0);
            for (int _16763 = 0; _16763 < 9; )
            {
                _16764 += (_2531.read(uint2((int2(496, 256) + int2(_16763, 0))), 0).xyz * _9817[_16763]);
                _16763++;
                continue;
            }
            float3 _4112 = reflect(-_3666, _16741);
            float _9998 = _4112.x;
            float _10003 = _4112.z;
            float2 _10035 = float2((precise::atan2((_283._m29.z * _9998) - (_283._m29.w * _10003), -((_283._m29.w * _9998) + (_283._m29.z * _10003))) * 0.15915493667125701904296875) + 0.5, acos(fast::clamp(_4112.y, -1.0, 1.0)) * 0.3183098733425140380859375);
            float _9967 = _16708 * 5.0;
            int _9970 = min(int(_9967), 4);
            float2 _10056 = (_10035 * float2(_2588[_9970].zw)) - float2(0.5);
            float2 _10058 = floor(_10056);
            float2 _10061 = _10056 - _10058;
            int _10064 = int(_10058.x);
            int _10067 = int(_10058.y);
            int _16767;
            if (_10064 < 0)
            {
                _16767 = _10064 + _2588[_9970].z;
            }
            else
            {
                _16767 = _10064;
            }
            int _16768;
            if (_16767 >= _2588[_9970].z)
            {
                _16768 = _16767 - _2588[_9970].z;
            }
            else
            {
                _16768 = _16767;
            }
            int _10087 = _16768 + 1;
            int _17810 = (_10087 == _2588[_9970].z) ? 0 : _10087;
            int _10102 = min((_10067 + 1), (_2588[_9970].w - 1));
            int _10104 = max(_10067, 0);
            float3 _10157 = float3(_10061.x);
            int _9977 = _9970 + 1;
            float2 _10189 = (_10035 * float2(_2588[_9977].zw)) - float2(0.5);
            float2 _10191 = floor(_10189);
            float2 _10194 = _10189 - _10191;
            int _10197 = int(_10191.x);
            int _10200 = int(_10191.y);
            int _16774;
            if (_10197 < 0)
            {
                _16774 = _10197 + _2588[_9977].z;
            }
            else
            {
                _16774 = _10197;
            }
            int _16775;
            if (_16774 >= _2588[_9977].z)
            {
                _16775 = _16774 - _2588[_9977].z;
            }
            else
            {
                _16775 = _16774;
            }
            int _10220 = _16775 + 1;
            int _17811 = (_10220 == _2588[_9977].z) ? 0 : _10220;
            int _10235 = min((_10200 + 1), (_2588[_9977].w - 1));
            int _10237 = max(_10200, 0);
            float3 _10290 = float3(_10194.x);
            float3 _9992 = mix(mix(mix(_2531.read(uint2((_2588[_9970].xy + int2(_16768, _10104))), 0).xyz, _2531.read(uint2((_2588[_9970].xy + int2(_17810, _10104))), 0).xyz, _10157), mix(_2531.read(uint2((_2588[_9970].xy + int2(_16768, _10102))), 0).xyz, _2531.read(uint2((_2588[_9970].xy + int2(_17810, _10102))), 0).xyz, _10157), float3(_10061.y)), mix(mix(_2531.read(uint2((_2588[_9977].xy + int2(_16775, _10237))), 0).xyz, _2531.read(uint2((_2588[_9977].xy + int2(_17811, _10237))), 0).xyz, _10290), mix(_2531.read(uint2((_2588[_9977].xy + int2(_16775, _10235))), 0).xyz, _2531.read(uint2((_2588[_9977].xy + int2(_17811, _10235))), 0).xyz, _10290), float3(_10194.y)), float3(_9967 - float(_9970))) * _283._m29.y;
            _16985 = _9813.xy;
            _16808 = _9992;
            _16781 = fast::max(_16764, float3(0.0)) * _283._m29.y;
        }
        else
        {
            float4 _10308 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * _16708) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);
            float _10310 = _10308.x;
            float3 _10345 = mix(_283._m9.xyz, _283._m8.xyz, float3((_16718.y * 0.5) + 0.5)) * _283._m8.w;
            _16985 = (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_10310 * _10310, exp2((-9.27999973297119140625) * _16746)) * _10310) + _10308.y)) + _10308.zw;
            _16808 = mix(mix(_283._m9.xyz, _283._m8.xyz, float3((reflect(-_3666, _16741).y * 0.5) + 0.5)) * _283._m8.w, _10345, float3(_16708));
            _16781 = _10345;
        }
        float3 _16908;
        if (_283._m34.y > 0.5)
        {
            int _10482 = int(_283._m34.y);
            int _10485 = int(_283._m34.x);
            float3 _16797;
            _16797 = _16781;
            float3 _17636;
            for (int _16796 = 0; _16796 < _10482; _16797 = _17636, _16796++)
            {
                int _10497 = 8 * (_10485 + _16796);
                float4 _10706 = as_type<float4>(_1281._m0[_10497 + 3]);
                float4 _10750 = as_type<float4>(_1281._m0[_10497]);
                float4 _10756 = as_type<float4>(_1281._m0[_10497 + 1]);
                float4 _10762 = as_type<float4>(_1281._m0[_10497 + 2]);
                float3 _10724 = _10750.xyz;
                float _10728 = _10750.w;
                float3 _10731 = _10756.xyz;
                float _10735 = _10756.w;
                float3 _10738 = _10762.xyz;
                float _10742 = _10762.w;
                float3 _10744 = float3(dot(_10724, in.m_3037) + _10728, dot(_10731, in.m_3037) + _10735, dot(_10738, in.m_3037) + _10742);
                float3 _10506 = _10706.xyz;
                float _10508 = _10706.w;
                float _17252;
                do
                {
                    float3 _10774 = _10506 - abs(_10744);
                    float _10782 = fast::min(_10774.x, fast::min(_10774.y, _10774.z));
                    if (_10782 <= 0.0)
                    {
                        _17252 = 0.0;
                        break;
                    }
                    if (_10508 <= 0.0)
                    {
                        _17252 = 1.0;
                        break;
                    }
                    float _10794 = fast::min(_10782 / _10508, 1.0);
                    _17252 = (_10794 * _10794) * (3.0 - (2.0 * _10794));
                    break;
                } while(false);
                if (_17252 <= 0.0)
                {
                    _17636 = _16797;
                    continue;
                }
                float3 _10517 = as_type<float4>(_1281._m0[_10497 + 4]).xyz;
                float4 _10815 = as_type<float4>(_1281._m0[_10497 + 5]);
                int _10821 = int(((device uint*)&_1281._m0[_10497 + 6])[0u]);
                float _10831 = dot(_10724, _16718);
                float _10837 = dot(_10731, _16718);
                float _10843 = dot(_10738, _16718);
                float3 _10844 = float3(_10831, _10837, _10843);
                float3 _10537 = (in.m_3037 + (_16718 * _10815.x)) + (_3666 * _10815.y);
                float3 _10556 = fast::clamp((((float3(dot(_10724, _10537) + _10728, dot(_10731, _10537) + _10735, dot(_10738, _10537) + _10742) + _10506) / fast::max(_10506 * 2.0, float3(9.9999999747524270787835121154785e-07))) * _10517) - float3(0.5), float3(0.0), _10517 - float3(1.0));
                int3 _10558 = int3(_10517);
                int3 _10565 = min(int3(_10556), max((_10558 - int3(2)), int3(0)));
                float3 _10569 = _10556 - float3(_10565);
                float _10924 = 0.48860299587249755859375 * _10837;
                float _10927 = 0.48860299587249755859375 * _10843;
                float _10930 = 0.48860299587249755859375 * _10831;
                float _10935 = 1.09254801273345947265625 * _10831;
                float _10938 = _10935 * _10837;
                float _10944 = (1.09254801273345947265625 * _10837) * _10843;
                float _10952 = 0.3153919875621795654296875 * (((3.0 * _10843) * _10843) - 1.0);
                float _10958 = _10935 * _10843;
                float _10972 = 0.546274006366729736328125 * ((_10831 * _10831) - (_10837 * _10837));
                int3 _10991 = _10558 - int3(1);
                int3 _10992 = min(_10565, _10991);
                int _10997 = _10558.x;
                int _11001 = _10558.y;
                int _11009 = _10821 + ((_10992.x + (_10997 * (_10992.y + (_11001 * _10992.z)))) * 4);
                float3 _11012 = float3(1.0) - _10569;
                float3 _11030 = (((((float3(_10992) + float3(0.5)) / _10517) * _10506) * 2.0) - _10506) - _10744;
                float _11040 = dot(_11030 * rsqrt(fast::max(dot(_11030, _11030), 1.0000000133514319600180897396058e-10)), _10844) + 1.0;
                float _11043 = _11012.x;
                float _11045 = _11012.y;
                float _11046 = _11043 * _11045;
                float _11048 = _11012.z;
                int _11072 = _11009 + 3;
                float _11058 = ((_11046 * _11048) * ((0.25 * (_11040 * _11040)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_11072])[1u])).y > 0.5);
                int _11102 = _11009 + 1;
                int _11106 = _11009 + 2;
                float2 _11118 = float2(as_type<half2>(_1281._m0[_11009].y));
                float2 _11127 = float2(as_type<half2>(_1281._m0[_11102].x));
                float2 _11136 = float2(as_type<half2>(_1281._m0[_11102].w));
                float2 _11145 = float2(as_type<half2>(_1281._m0[_11106].z));
                float3 _11233 = (((((((float3(float2(as_type<half2>(_1281._m0[_11009].x)), _11118.x) * 0.2820949852466583251953125) + (float3(_11118.y, float2(as_type<half2>(_1281._m0[_11009].z))) * _10924)) + (float3(float2(as_type<half2>(_1281._m0[_11009].w)), _11127.x) * _10927)) + (float3(_11127.y, float2(as_type<half2>(_1281._m0[_11102].y))) * _10930)) + (float3(float2(as_type<half2>(_1281._m0[_11102].z)), _11136.x) * _10938)) + (float3(_11136.y, float2(as_type<half2>(_1281._m0[_11106].x))) * _10944)) + (float3(float2(as_type<half2>(_1281._m0[_11106].y)), _11145.x) * _10952)) + (float3(_11145.y, float2(as_type<half2>(_1281._m0[_11106].w))) * _10958);
                int3 _11261 = min((_10565 + int3(1, 0, 0)), _10991);
                int _11278 = _10821 + ((_11261.x + (_10997 * (_11261.y + (_11001 * _11261.z)))) * 4);
                float3 _11299 = (((((float3(_11261) + float3(0.5)) / _10517) * _10506) * 2.0) - _10506) - _10744;
                float _11309 = dot(_11299 * rsqrt(fast::max(dot(_11299, _11299), 1.0000000133514319600180897396058e-10)), _10844) + 1.0;
                float _11315 = _10569.x * _11045;
                int _11341 = _11278 + 3;
                float _11327 = ((_11315 * _11048) * ((0.25 * (_11309 * _11309)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_11341])[1u])).y > 0.5);
                int _11371 = _11278 + 1;
                int _11375 = _11278 + 2;
                float2 _11387 = float2(as_type<half2>(_1281._m0[_11278].y));
                float2 _11396 = float2(as_type<half2>(_1281._m0[_11371].x));
                float2 _11405 = float2(as_type<half2>(_1281._m0[_11371].w));
                float2 _11414 = float2(as_type<half2>(_1281._m0[_11375].z));
                float3 _11502 = (((((((float3(float2(as_type<half2>(_1281._m0[_11278].x)), _11387.x) * 0.2820949852466583251953125) + (float3(_11387.y, float2(as_type<half2>(_1281._m0[_11278].z))) * _10924)) + (float3(float2(as_type<half2>(_1281._m0[_11278].w)), _11396.x) * _10927)) + (float3(_11396.y, float2(as_type<half2>(_1281._m0[_11371].y))) * _10930)) + (float3(float2(as_type<half2>(_1281._m0[_11371].z)), _11405.x) * _10938)) + (float3(_11405.y, float2(as_type<half2>(_1281._m0[_11375].x))) * _10944)) + (float3(float2(as_type<half2>(_1281._m0[_11375].y)), _11414.x) * _10952)) + (float3(_11414.y, float2(as_type<half2>(_1281._m0[_11375].w))) * _10958);
                int3 _11530 = min((_10565 + int3(0, 1, 0)), _10991);
                int _11547 = _10821 + ((_11530.x + (_10997 * (_11530.y + (_11001 * _11530.z)))) * 4);
                float3 _11568 = (((((float3(_11530) + float3(0.5)) / _10517) * _10506) * 2.0) - _10506) - _10744;
                float _11578 = dot(_11568 * rsqrt(fast::max(dot(_11568, _11568), 1.0000000133514319600180897396058e-10)), _10844) + 1.0;
                float _11584 = _11043 * _10569.y;
                int _11610 = _11547 + 3;
                float _11596 = ((_11584 * _11048) * ((0.25 * (_11578 * _11578)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_11610])[1u])).y > 0.5);
                int _11640 = _11547 + 1;
                int _11644 = _11547 + 2;
                float2 _11656 = float2(as_type<half2>(_1281._m0[_11547].y));
                float2 _11665 = float2(as_type<half2>(_1281._m0[_11640].x));
                float2 _11674 = float2(as_type<half2>(_1281._m0[_11640].w));
                float2 _11683 = float2(as_type<half2>(_1281._m0[_11644].z));
                float3 _11771 = (((((((float3(float2(as_type<half2>(_1281._m0[_11547].x)), _11656.x) * 0.2820949852466583251953125) + (float3(_11656.y, float2(as_type<half2>(_1281._m0[_11547].z))) * _10924)) + (float3(float2(as_type<half2>(_1281._m0[_11547].w)), _11665.x) * _10927)) + (float3(_11665.y, float2(as_type<half2>(_1281._m0[_11640].y))) * _10930)) + (float3(float2(as_type<half2>(_1281._m0[_11640].z)), _11674.x) * _10938)) + (float3(_11674.y, float2(as_type<half2>(_1281._m0[_11644].x))) * _10944)) + (float3(float2(as_type<half2>(_1281._m0[_11644].y)), _11683.x) * _10952)) + (float3(_11683.y, float2(as_type<half2>(_1281._m0[_11644].w))) * _10958);
                int3 _11799 = min((_10565 + int3(1, 1, 0)), _10991);
                int _11816 = _10821 + ((_11799.x + (_10997 * (_11799.y + (_11001 * _11799.z)))) * 4);
                float3 _11837 = (((((float3(_11799) + float3(0.5)) / _10517) * _10506) * 2.0) - _10506) - _10744;
                float _11847 = dot(_11837 * rsqrt(fast::max(dot(_11837, _11837), 1.0000000133514319600180897396058e-10)), _10844) + 1.0;
                float _11853 = _10569.x * _10569.y;
                int _11879 = _11816 + 3;
                float _11865 = ((_11853 * _11048) * ((0.25 * (_11847 * _11847)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_11879])[1u])).y > 0.5);
                int _11909 = _11816 + 1;
                int _11913 = _11816 + 2;
                float2 _11925 = float2(as_type<half2>(_1281._m0[_11816].y));
                float2 _11934 = float2(as_type<half2>(_1281._m0[_11909].x));
                float2 _11943 = float2(as_type<half2>(_1281._m0[_11909].w));
                float2 _11952 = float2(as_type<half2>(_1281._m0[_11913].z));
                float3 _12040 = (((((((float3(float2(as_type<half2>(_1281._m0[_11816].x)), _11925.x) * 0.2820949852466583251953125) + (float3(_11925.y, float2(as_type<half2>(_1281._m0[_11816].z))) * _10924)) + (float3(float2(as_type<half2>(_1281._m0[_11816].w)), _11934.x) * _10927)) + (float3(_11934.y, float2(as_type<half2>(_1281._m0[_11909].y))) * _10930)) + (float3(float2(as_type<half2>(_1281._m0[_11909].z)), _11943.x) * _10938)) + (float3(_11943.y, float2(as_type<half2>(_1281._m0[_11913].x))) * _10944)) + (float3(float2(as_type<half2>(_1281._m0[_11913].y)), _11952.x) * _10952)) + (float3(_11952.y, float2(as_type<half2>(_1281._m0[_11913].w))) * _10958);
                int3 _12068 = min((_10565 + int3(0, 0, 1)), _10991);
                int _12085 = _10821 + ((_12068.x + (_10997 * (_12068.y + (_11001 * _12068.z)))) * 4);
                float3 _12106 = (((((float3(_12068) + float3(0.5)) / _10517) * _10506) * 2.0) - _10506) - _10744;
                float _12116 = dot(_12106 * rsqrt(fast::max(dot(_12106, _12106), 1.0000000133514319600180897396058e-10)), _10844) + 1.0;
                int _12148 = _12085 + 3;
                float _12134 = ((_11046 * _10569.z) * ((0.25 * (_12116 * _12116)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_12148])[1u])).y > 0.5);
                int _12178 = _12085 + 1;
                int _12182 = _12085 + 2;
                float2 _12194 = float2(as_type<half2>(_1281._m0[_12085].y));
                float2 _12203 = float2(as_type<half2>(_1281._m0[_12178].x));
                float2 _12212 = float2(as_type<half2>(_1281._m0[_12178].w));
                float2 _12221 = float2(as_type<half2>(_1281._m0[_12182].z));
                float3 _12309 = (((((((float3(float2(as_type<half2>(_1281._m0[_12085].x)), _12194.x) * 0.2820949852466583251953125) + (float3(_12194.y, float2(as_type<half2>(_1281._m0[_12085].z))) * _10924)) + (float3(float2(as_type<half2>(_1281._m0[_12085].w)), _12203.x) * _10927)) + (float3(_12203.y, float2(as_type<half2>(_1281._m0[_12178].y))) * _10930)) + (float3(float2(as_type<half2>(_1281._m0[_12178].z)), _12212.x) * _10938)) + (float3(_12212.y, float2(as_type<half2>(_1281._m0[_12182].x))) * _10944)) + (float3(float2(as_type<half2>(_1281._m0[_12182].y)), _12221.x) * _10952)) + (float3(_12221.y, float2(as_type<half2>(_1281._m0[_12182].w))) * _10958);
                float4 _10636 = (((float4((_11233 + (float3(float2(as_type<half2>(_1281._m0[_11072].x)), float2(as_type<half2>(_1281._m0[_11072].y)).x) * _10972)) * _11058, _11058) + float4((_11502 + (float3(float2(as_type<half2>(_1281._m0[_11341].x)), float2(as_type<half2>(_1281._m0[_11341].y)).x) * _10972)) * _11327, _11327)) + float4((_11771 + (float3(float2(as_type<half2>(_1281._m0[_11610].x)), float2(as_type<half2>(_1281._m0[_11610].y)).x) * _10972)) * _11596, _11596)) + float4((_12040 + (float3(float2(as_type<half2>(_1281._m0[_11879].x)), float2(as_type<half2>(_1281._m0[_11879].y)).x) * _10972)) * _11865, _11865)) + float4((_12309 + (float3(float2(as_type<half2>(_1281._m0[_12148].x)), float2(as_type<half2>(_1281._m0[_12148].y)).x) * _10972)) * _12134, _12134);
                int3 _12337 = min((_10565 + int3(1, 0, 1)), _10991);
                int _12354 = _10821 + ((_12337.x + (_10997 * (_12337.y + (_11001 * _12337.z)))) * 4);
                float3 _12375 = (((((float3(_12337) + float3(0.5)) / _10517) * _10506) * 2.0) - _10506) - _10744;
                float _12385 = dot(_12375 * rsqrt(fast::max(dot(_12375, _12375), 1.0000000133514319600180897396058e-10)), _10844) + 1.0;
                int _12417 = _12354 + 3;
                float _12403 = ((_11315 * _10569.z) * ((0.25 * (_12385 * _12385)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_12417])[1u])).y > 0.5);
                int _12447 = _12354 + 1;
                int _12451 = _12354 + 2;
                float2 _12463 = float2(as_type<half2>(_1281._m0[_12354].y));
                float2 _12472 = float2(as_type<half2>(_1281._m0[_12447].x));
                float2 _12481 = float2(as_type<half2>(_1281._m0[_12447].w));
                float2 _12490 = float2(as_type<half2>(_1281._m0[_12451].z));
                float3 _12578 = (((((((float3(float2(as_type<half2>(_1281._m0[_12354].x)), _12463.x) * 0.2820949852466583251953125) + (float3(_12463.y, float2(as_type<half2>(_1281._m0[_12354].z))) * _10924)) + (float3(float2(as_type<half2>(_1281._m0[_12354].w)), _12472.x) * _10927)) + (float3(_12472.y, float2(as_type<half2>(_1281._m0[_12447].y))) * _10930)) + (float3(float2(as_type<half2>(_1281._m0[_12447].z)), _12481.x) * _10938)) + (float3(_12481.y, float2(as_type<half2>(_1281._m0[_12451].x))) * _10944)) + (float3(float2(as_type<half2>(_1281._m0[_12451].y)), _12490.x) * _10952)) + (float3(_12490.y, float2(as_type<half2>(_1281._m0[_12451].w))) * _10958);
                int3 _12606 = min((_10565 + int3(0, 1, 1)), _10991);
                int _12623 = _10821 + ((_12606.x + (_10997 * (_12606.y + (_11001 * _12606.z)))) * 4);
                float3 _12644 = (((((float3(_12606) + float3(0.5)) / _10517) * _10506) * 2.0) - _10506) - _10744;
                float _12654 = dot(_12644 * rsqrt(fast::max(dot(_12644, _12644), 1.0000000133514319600180897396058e-10)), _10844) + 1.0;
                int _12686 = _12623 + 3;
                float _12672 = ((_11584 * _10569.z) * ((0.25 * (_12654 * _12654)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_12686])[1u])).y > 0.5);
                int _12716 = _12623 + 1;
                int _12720 = _12623 + 2;
                float2 _12732 = float2(as_type<half2>(_1281._m0[_12623].y));
                float2 _12741 = float2(as_type<half2>(_1281._m0[_12716].x));
                float2 _12750 = float2(as_type<half2>(_1281._m0[_12716].w));
                float2 _12759 = float2(as_type<half2>(_1281._m0[_12720].z));
                float3 _12847 = (((((((float3(float2(as_type<half2>(_1281._m0[_12623].x)), _12732.x) * 0.2820949852466583251953125) + (float3(_12732.y, float2(as_type<half2>(_1281._m0[_12623].z))) * _10924)) + (float3(float2(as_type<half2>(_1281._m0[_12623].w)), _12741.x) * _10927)) + (float3(_12741.y, float2(as_type<half2>(_1281._m0[_12716].y))) * _10930)) + (float3(float2(as_type<half2>(_1281._m0[_12716].z)), _12750.x) * _10938)) + (float3(_12750.y, float2(as_type<half2>(_1281._m0[_12720].x))) * _10944)) + (float3(float2(as_type<half2>(_1281._m0[_12720].y)), _12759.x) * _10952)) + (float3(_12759.y, float2(as_type<half2>(_1281._m0[_12720].w))) * _10958);
                int3 _12875 = min((_10565 + int3(1)), _10991);
                int _12892 = _10821 + ((_12875.x + (_10997 * (_12875.y + (_11001 * _12875.z)))) * 4);
                float3 _12913 = (((((float3(_12875) + float3(0.5)) / _10517) * _10506) * 2.0) - _10506) - _10744;
                float _12923 = dot(_12913 * rsqrt(fast::max(dot(_12913, _12913), 1.0000000133514319600180897396058e-10)), _10844) + 1.0;
                int _12955 = _12892 + 3;
                float _12941 = ((_11853 * _10569.z) * ((0.25 * (_12923 * _12923)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_12955])[1u])).y > 0.5);
                int _12985 = _12892 + 1;
                int _12989 = _12892 + 2;
                float2 _13001 = float2(as_type<half2>(_1281._m0[_12892].y));
                float2 _13010 = float2(as_type<half2>(_1281._m0[_12985].x));
                float2 _13019 = float2(as_type<half2>(_1281._m0[_12985].w));
                float2 _13028 = float2(as_type<half2>(_1281._m0[_12989].z));
                float3 _13116 = (((((((float3(float2(as_type<half2>(_1281._m0[_12892].x)), _13001.x) * 0.2820949852466583251953125) + (float3(_13001.y, float2(as_type<half2>(_1281._m0[_12892].z))) * _10924)) + (float3(float2(as_type<half2>(_1281._m0[_12892].w)), _13010.x) * _10927)) + (float3(_13010.y, float2(as_type<half2>(_1281._m0[_12985].y))) * _10930)) + (float3(float2(as_type<half2>(_1281._m0[_12985].z)), _13019.x) * _10938)) + (float3(_13019.y, float2(as_type<half2>(_1281._m0[_12989].x))) * _10944)) + (float3(float2(as_type<half2>(_1281._m0[_12989].y)), _13028.x) * _10952)) + (float3(_13028.y, float2(as_type<half2>(_1281._m0[_12989].w))) * _10958);
                float4 _10675 = ((_10636 + float4((_12578 + (float3(float2(as_type<half2>(_1281._m0[_12417].x)), float2(as_type<half2>(_1281._m0[_12417].y)).x) * _10972)) * _12403, _12403)) + float4((_12847 + (float3(float2(as_type<half2>(_1281._m0[_12686].x)), float2(as_type<half2>(_1281._m0[_12686].y)).x) * _10972)) * _12672, _12672)) + float4((_13116 + (float3(float2(as_type<half2>(_1281._m0[_12955].x)), float2(as_type<half2>(_1281._m0[_12955].y)).x) * _10972)) * _12941, _12941);
                float _10679 = _10675.w;
                float3 _17637;
                if (_10679 > 9.9999997473787516355514526367188e-06)
                {
                    _17637 = mix(_16797, (fast::max(_10675.xyz, float3(0.0)) / float3(_10679)) * _10815.z, float3(_17252));
                }
                else
                {
                    _17637 = _16797;
                }
                _17636 = _17637;
            }
            _16908 = _16797;
        }
        else
        {
            _16908 = _16781;
        }
        float3 _16930;
        if (_283._m34.x > 0.5)
        {
            float3 _4158 = reflect(-_3666, _16741);
            int _13164 = int(_283._m34.x);
            float _16820;
            float3 _16886;
            _16886 = float3(0.0);
            _16820 = 0.0;
            float _17647;
            float3 _17648;
            for (int _16819 = 0; _16819 < _13164; _16886 = _17648, _16820 = _17647, _16819++)
            {
                if (_16820 > 0.999000012874603271484375)
                {
                    break;
                }
                int _13176 = _16819 * 8;
                float4 _13291 = as_type<float4>(_1281._m0[_13176]);
                float4 _13297 = as_type<float4>(_1281._m0[_13176 + 1]);
                float4 _13303 = as_type<float4>(_1281._m0[_13176 + 2]);
                float3 _13265 = _13291.xyz;
                float3 _13272 = _13297.xyz;
                float3 _13279 = _13303.xyz;
                float3 _13285 = float3(dot(_13265, in.m_3037) + _13291.w, dot(_13272, in.m_3037) + _13297.w, dot(_13279, in.m_3037) + _13303.w);
                float4 _13309 = as_type<float4>(_1281._m0[_13176 + 3]);
                float _13187 = _13309.w;
                float _16821;
                do
                {
                    float3 _13321 = _13309.xyz - abs(_13285);
                    float _13329 = fast::min(_13321.x, fast::min(_13321.y, _13321.z));
                    if (_13329 <= 0.0)
                    {
                        _16821 = 0.0;
                        break;
                    }
                    if (_13187 <= 0.0)
                    {
                        _16821 = 1.0;
                        break;
                    }
                    float _13341 = fast::min(_13329 / _13187, 1.0);
                    _16821 = (_13341 * _13341) * (3.0 - (2.0 * _13341));
                    break;
                } while(false);
                if (_16821 <= 0.0)
                {
                    _17648 = _16886;
                    _17647 = _16820;
                    continue;
                }
                float4 _13356 = as_type<float4>(_1281._m0[_13176 + 4]);
                float4 _13362 = as_type<float4>(_1281._m0[_13176 + 5]);
                float3 _13385 = float3(dot(_13265, _4158), dot(_13272, _4158), dot(_13279, _4158));
                float3 _16823;
                if (_13356.w > 0.5)
                {
                    float3 _13209 = _13356.xyz;
                    float3 _13415 = -_13209;
                    float3 _13417 = fast::clamp(_13285, _13415, _13209);
                    float3 _13427 = step(float3(9.9999999747524270787835121154785e-07), abs(_13385));
                    float3 _13437 = mix(float3(1000000015047466219876688855040.0), (mix(_13415, _13209, step(float3(0.0), _13385)) - _13417) / mix(float3(9.9999999747524270787835121154785e-07), _13385, _13427), _13427);
                    float3 _13453 = (_13417 + (_13385 * fast::max(fast::min(_13437.x, fast::min(_13437.y, _13437.z)), 0.0))) - _13362.xyz;
                    float3 _16822;
                    if (dot(_13453, _13453) > 9.9999999600419720025001879548654e-13)
                    {
                        _16822 = fast::normalize(_13453);
                    }
                    else
                    {
                        _16822 = _13385;
                    }
                    _16823 = _16822;
                }
                else
                {
                    _16823 = _13385;
                }
                int _13470 = int(((device uint*)&_1281._m0[_13176 + 6])[0u]);
                float2 _13520 = float2((precise::atan2(_16823.x, -_16823.z) * 0.15915493667125701904296875) + 0.5, acos(fast::clamp(_16823.y, -1.0, 1.0)) * 0.3183098733425140380859375);
                float _13486 = _16708 * 5.0;
                int _13489 = min(int(_13486), 4);
                int _13560 = _13470 + _1353[_13489].x;
                float2 _13567 = (_13520 * float2(_1353[_13489].yz)) - float2(0.5);
                float2 _13569 = floor(_13567);
                float2 _13572 = _13567 - _13569;
                int _13575 = int(_13569.x);
                int _13578 = int(_13569.y);
                int _16824;
                if (_13575 < 0)
                {
                    _16824 = _13575 + _1353[_13489].y;
                }
                else
                {
                    _16824 = _13575;
                }
                int _16825;
                if (_16824 >= _1353[_13489].y)
                {
                    _16825 = _16824 - _1353[_13489].y;
                }
                else
                {
                    _16825 = _16824;
                }
                int _13598 = _16825 + 1;
                int _17812 = (_13598 == _1353[_13489].y) ? 0 : _13598;
                int _13666 = _13560 + (max(_13578, 0) * _1353[_13489].y);
                int _13668 = _13666 + _16825;
                int _13670 = _13668 >> 1;
                uint2 _16831;
                if ((_13668 & 1) == 0)
                {
                    _16831 = _1281._m0[_13670].xy;
                }
                else
                {
                    _16831 = _1281._m0[_13670].zw;
                }
                int _13706 = _13666 + _17812;
                int _13708 = _13706 >> 1;
                uint2 _16833;
                if ((_13706 & 1) == 0)
                {
                    _16833 = _1281._m0[_13708].xy;
                }
                else
                {
                    _16833 = _1281._m0[_13708].zw;
                }
                int _13742 = _13560 + (min((_13578 + 1), (_1353[_13489].z - 1)) * _1353[_13489].y);
                int _13744 = _13742 + _16825;
                int _13746 = _13744 >> 1;
                uint2 _16836;
                if ((_13744 & 1) == 0)
                {
                    _16836 = _1281._m0[_13746].xy;
                }
                else
                {
                    _16836 = _1281._m0[_13746].zw;
                }
                int _13782 = _13742 + _17812;
                int _13784 = _13782 >> 1;
                uint2 _16837;
                if ((_13782 & 1) == 0)
                {
                    _16837 = _1281._m0[_13784].xy;
                }
                else
                {
                    _16837 = _1281._m0[_13784].zw;
                }
                float3 _13644 = float3(_13572.x);
                int _13495 = _13489 + 1;
                int _13847 = _13470 + _1353[_13495].x;
                float2 _13854 = (_13520 * float2(_1353[_13495].yz)) - float2(0.5);
                float2 _13856 = floor(_13854);
                float2 _13859 = _13854 - _13856;
                int _13862 = int(_13856.x);
                int _13865 = int(_13856.y);
                int _16838;
                if (_13862 < 0)
                {
                    _16838 = _13862 + _1353[_13495].y;
                }
                else
                {
                    _16838 = _13862;
                }
                int _16839;
                if (_16838 >= _1353[_13495].y)
                {
                    _16839 = _16838 - _1353[_13495].y;
                }
                else
                {
                    _16839 = _16838;
                }
                int _13885 = _16839 + 1;
                int _17813 = (_13885 == _1353[_13495].y) ? 0 : _13885;
                int _13953 = _13847 + (max(_13865, 0) * _1353[_13495].y);
                int _13955 = _13953 + _16839;
                int _13957 = _13955 >> 1;
                uint2 _16845;
                if ((_13955 & 1) == 0)
                {
                    _16845 = _1281._m0[_13957].xy;
                }
                else
                {
                    _16845 = _1281._m0[_13957].zw;
                }
                int _13993 = _13953 + _17813;
                int _13995 = _13993 >> 1;
                uint2 _16847;
                if ((_13993 & 1) == 0)
                {
                    _16847 = _1281._m0[_13995].xy;
                }
                else
                {
                    _16847 = _1281._m0[_13995].zw;
                }
                int _14029 = _13847 + (min((_13865 + 1), (_1353[_13495].z - 1)) * _1353[_13495].y);
                int _14031 = _14029 + _16839;
                int _14033 = _14031 >> 1;
                uint2 _16850;
                if ((_14031 & 1) == 0)
                {
                    _16850 = _1281._m0[_14033].xy;
                }
                else
                {
                    _16850 = _1281._m0[_14033].zw;
                }
                int _14069 = _14029 + _17813;
                int _14071 = _14069 >> 1;
                uint2 _16851;
                if ((_14069 & 1) == 0)
                {
                    _16851 = _1281._m0[_14071].xy;
                }
                else
                {
                    _16851 = _1281._m0[_14071].zw;
                }
                float3 _13931 = float3(_13859.x);
                float3 _13225 = mix(mix(mix(float3(float2(as_type<half2>(_16831.x)), float2(as_type<half2>(_16831.y)).x), float3(float2(as_type<half2>(_16833.x)), float2(as_type<half2>(_16833.y)).x), _13644), mix(float3(float2(as_type<half2>(_16836.x)), float2(as_type<half2>(_16836.y)).x), float3(float2(as_type<half2>(_16837.x)), float2(as_type<half2>(_16837.y)).x), _13644), float3(_13572.y)), mix(mix(float3(float2(as_type<half2>(_16845.x)), float2(as_type<half2>(_16845.y)).x), float3(float2(as_type<half2>(_16847.x)), float2(as_type<half2>(_16847.y)).x), _13931), mix(float3(float2(as_type<half2>(_16850.x)), float2(as_type<half2>(_16850.y)).x), float3(float2(as_type<half2>(_16851.x)), float2(as_type<half2>(_16851.y)).x), _13931), float3(_13859.y)), float3(_13486 - float(_13489))) * _13362.w;
                float _13229 = _16821 * (1.0 - _16820);
                _17648 = _16886 + (_13225 * _13229);
                _17647 = _16820 + _13229;
            }
            _16930 = _16886 + (_16808 * (1.0 - _16820));
        }
        else
        {
            _16930 = _16808;
        }
        bool _4176;
        if (_3712)
        {
            _4176 = _283._m33.z > 0.5;
        }
        else
        {
            _4176 = _3712;
        }
        float3 _17020;
        if (_4176)
        {
            float3 _16980;
            do
            {
                float _14156 = ((_283._m32.x * (1.0 - smoothstep(_283._m33.x * 0.5, _283._m33.x, abs(dot(_283._m31.xyz, in.m_3037) - _283._m31.w)))) * smoothstep(0.5, 0.89999997615814208984375, dot(_3677, _283._m31.xyz))) * (1.0 - smoothstep(_283._m32.y * 0.5, _283._m32.y, _16708));
                if (_14156 <= 0.0)
                {
                    _16980 = _16930;
                    break;
                }
                float4 _14181 = _283._m30 * float4(in.m_3037 + ((_16718 - (_283._m31.xyz * dot(_16718, _283._m31.xyz))) * _283._m32.w), 1.0);
                float2 _14194 = ((float2(_14181.x, -_14181.y) / float2(_14181.w)) * 0.5) + float2(0.5);
                float _14198 = _283._m32.z * _16708;
                float3 _16978;
                float _16979;
                _16979 = 0.0;
                _16978 = float3(0.0);
                for (int _16977 = 0; _16977 < 12; )
                {
                    float _14205 = float(_16977);
                    float _14213 = _14205 * 2.3999631404876708984375;
                    float2 _14225 = _14194 + (float2(cos(_14213) * _283._m33.y, sin(_14213)) * (sqrt((_14205 + 0.5) * 0.083333335816860198974609375) * _14198));
                    float2 _14230 = fast::min(_14225, float2(1.0) - _14225);
                    float _14236 = smoothstep(0.0, 0.039999999105930328369140625, fast::min(_14230.x, _14230.y));
                    float4 _14244 = _3352.sample(_2533, fast::clamp(_14225, float2(0.0), float2(1.0)), level(0.0));
                    float3 _14246 = _14244.xyz;
                    _16979 += (_14244.w * _14236);
                    _16978 += ((_14246 / (float3(1.0) - fast::min(_14246, float3(0.99500000476837158203125)))) * _14236);
                    _16977++;
                    continue;
                }
                _16980 = mix(_16930, (_16978 * float3(0.083333335816860198974609375)) + (_16930 * (1.0 - (_16979 * 0.083333335816860198974609375))), float3(_14156));
                break;
            } while(false);
            _17020 = _16980;
        }
        else
        {
            _17020 = _16930;
        }
        float3 _4196 = (_3956 * _16985.x) + float3(_16985.y);
        float3 _4212 = _17074 + (((((float3(1.0) - _4196) * _3950) * _16908) + (_4196 * _17020)) * _17037);
        float3 _17281;
        if (_283._m13.w > 0.5)
        {
            float2 _14310 = fast::clamp(floor(gl_FragCoord.xy * _283._m12.xy), float2(0.0), _283._m13.xy - float2(1.0));
            uint _14338 = uint((((fast::clamp(floor((log2(fast::max(dot(_283._m11.xyz, in.m_3037) + _283._m11.w, 9.9999999747524270787835121154785e-07)) * _283._m12.z) + _283._m12.w), 0.0, _283._m13.z - 1.0) * _283._m13.y) + _14310.y) * _283._m13.x) + _14310.x);
            uint _14340 = _14338 >> uint(2);
            uint _14342 = _14338 & 3u;
            uint _14346 = _3167._m0[_14340][_14342] & 65535u;
            uint _14348 = _3167._m0[_14340][_14342] >> uint(16);
            float3 _17218;
            _17218 = _4212;
            float3 _4312;
            spvUnsafeArray<float2, 3> _14756;
            spvUnsafeArray<float2, 3> _14757;
            spvUnsafeArray<float2, 3> _14969;
            spvUnsafeArray<float2, 3> _14970;
            for (uint _17098 = _14346; _17098 < (_14346 + _14348); _17218 = _4312, _17098++)
            {
                uint _14354 = _17098 / 3u;
                uint _14367 = (_3188._m0[_14354 >> uint(2)][_14354 & 3u] >> ((_17098 - (_14354 * 3u)) * 10u)) & 1023u;
                float3 _14384 = _3030._m0[_14367].xyz - in.m_3037;
                float _14387 = dot(_14384, _14384);
                float _14391 = _14387 * _3030._m0[_14367].w;
                float _14396 = fast::clamp(1.0 - (_14391 * _14391), 0.0, 1.0);
                float3 _14401 = _14384 * rsqrt(fast::max(_14387, 9.9999999392252902907785028219223e-09));
                float _14419 = fast::clamp((dot(-_14401, _3073._m0[_14367].xyz) * _3065._m0[_14367].w) + _3073._m0[_14367].w, 0.0, 1.0);
                float3 _14432 = _3065._m0[_14367].xyz * ((((_14396 * _14396) * _14419) * _14419) / fast::max(_14387, 9.9999997473787516355514526367188e-05));
                float3 _17216;
                if (_3682)
                {
                    float _17125;
                    do
                    {
                        uint _14468 = uint(_283._m21.z);
                        if (_14367 < _14468)
                        {
                            float _14490 = _283._m26[_14367].z * fast::max((_283._m15[_14367] * float4(in.m_3037, 1.0)).w, 0.0);
                            float4 _14514 = _283._m15[_14367] * float4((in.m_3037 + (_3677 * (_14490 * _283._m25.x))) + (_14401 * (_14490 * _283._m25.y)), 1.0);
                            float _14516 = _14514.w;
                            if (_14516 <= 0.0)
                            {
                                _17125 = 1.0;
                                break;
                            }
                            float3 _14525 = _14514.xyz / float3(_14516);
                            float _14527 = _14525.x;
                            bool _14528 = _14527 < 0.0;
                            bool _14535;
                            if (!_14528)
                            {
                                _14535 = _14527 > 1.0;
                            }
                            else
                            {
                                _14535 = _14528;
                            }
                            bool _14542;
                            if (!_14535)
                            {
                                _14542 = _14525.y < 0.0;
                            }
                            else
                            {
                                _14542 = _14535;
                            }
                            bool _14549;
                            if (!_14542)
                            {
                                _14549 = _14525.y > 1.0;
                            }
                            else
                            {
                                _14549 = _14542;
                            }
                            bool _14556;
                            if (!_14549)
                            {
                                _14556 = _14525.z > 1.0;
                            }
                            else
                            {
                                _14556 = _14549;
                            }
                            if (_14556)
                            {
                                _17125 = 1.0;
                                break;
                            }
                            float _14562 = _14525.z;
                            float2 _14728 = _283._m22.xy * 0.5;
                            float2 _14733 = _283._m26[_14367].xy + (_14525.xy * _283._m23.zw);
                            float4 _14746 = float4(_283._m26[_14367].xy + _14728, (_283._m26[_14367].xy + _283._m23.zw) - _14728);
                            float _17124;
                            do
                            {
                                int _14772 = int(_283._m22.z);
                                if (_14772 <= 0)
                                {
                                    float2 _14782 = fast::clamp(_14733, _14746.xy, _14746.zw);
                                    _17124 = spvDepthCast(_303).sample_compare(_303Smplr, float3(_14782, _14562).xy, _14562);
                                    break;
                                }
                                float2 _14795 = (_14733 / _283._m22.xy) + float2(0.5);
                                float2 _14796 = floor(_14795);
                                float2 _14801 = _14795 - _14796;
                                float2 _14804 = _14796 - float2(0.5);
                                bool _14808 = _14772 == 1;
                                if (_14808)
                                {
                                    float2 _14811 = _14801 * 2.0;
                                    _14756[0] = float2(3.0) - _14811;
                                    _14756[1] = float2(1.0) + _14811;
                                    _14757[0] = ((float2(2.0) - _14801) / _14756[0]) - float2(1.0);
                                    _14757[1] = (_14801 / _14756[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _14838 = _14801 * 3.0;
                                    _14756[0] = float2(4.0) - _14838;
                                    _14756[1] = float2(7.0);
                                    _14756[2] = float2(1.0) + _14838;
                                    _14757[0] = ((float2(3.0) - (_14801 * 2.0)) / _14756[0]) - float2(2.0);
                                    _14757[1] = (float2(3.0) + _14801) / _14756[1];
                                    _14757[2] = (_14801 / _14756[2]) + float2(2.0);
                                }
                                int _17815 = _14808 ? 2 : 3;
                                int _17114;
                                float _17117;
                                _17117 = 0.0;
                                _17114 = 0;
                                float _17123;
                                for (; _17114 < _17815; _17117 = _17123, _17114++)
                                {
                                    _17123 = _17117;
                                    for (int _17120 = 0; _17120 < _17815; )
                                    {
                                        _17123 += ((_14756[_17120].x * _14756[_17114].y) * spvDepthCast(_303).sample_compare(_303Smplr, float3(fast::clamp(_283._m22.xy * (_14804 + float2(_14757[_17120].x, _14757[_17114].y)), _14746.xy, _14746.zw), _14562).xy, _14562));
                                        _17120++;
                                        continue;
                                    }
                                }
                                _17124 = _17117 * (_14808 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _17125 = _17124;
                            break;
                        }
                        uint _14572 = _14367 - _14468;
                        if (_14572 >= uint(_283._m21.w))
                        {
                            _17125 = 1.0;
                            break;
                        }
                        float _14593 = _283._m27[_14572].w * length(in.m_3037 - _283._m27[_14572].xyz);
                        float3 _14611 = ((in.m_3037 + (_3677 * (_14593 * _283._m25.x))) + (_14401 * (_14593 * _283._m25.y))) - _283._m27[_14572].xyz;
                        float3 _14613 = abs(_14611);
                        float _14615 = _14613.x;
                        float _14617 = _14613.y;
                        bool _14618 = _14615 >= _14617;
                        bool _14626;
                        if (_14618)
                        {
                            _14626 = _14615 >= _14613.z;
                        }
                        else
                        {
                            _14626 = _14618;
                        }
                        float _17099;
                        int _17101;
                        if (_14626)
                        {
                            _17101 = (_14611.x > 0.0) ? 0 : 1;
                            _17099 = _14615;
                        }
                        else
                        {
                            float _14638 = _14613.z;
                            bool _14639 = _14617 >= _14638;
                            int _17102;
                            if (_14639)
                            {
                                _17102 = (_14611.y > 0.0) ? 2 : 3;
                            }
                            else
                            {
                                _17102 = (_14611.z > 0.0) ? 4 : 5;
                            }
                            _17101 = _17102;
                            _17099 = _14639 ? _14617 : _14638;
                        }
                        if (_17099 <= 0.0)
                        {
                            _17125 = 1.0;
                            break;
                        }
                        float2 _14676 = float2(dot(_14611, _961[_17101]), dot(_14611, _970[_17101])) / float2(_17099 * _283._m24.z);
                        float _14683 = _283._m28[_14572].z + (_283._m28[_14572].w / _17099);
                        if (_14683 > 1.0)
                        {
                            _17125 = 1.0;
                            break;
                        }
                        float2 _14701 = _283._m28[_14572].xy + (float2(float(spvSMod(_17101, 3)), float(_17101 / 3)) * _283._m24.xy);
                        float2 _14941 = _283._m22.xy * 0.5;
                        float2 _14946 = _14701 + (float2(0.5 + (0.5 * _14676.x), 0.5 - (0.5 * _14676.y)) * _283._m24.xy);
                        float4 _14959 = float4(_14701 + _14941, (_14701 + _283._m24.xy) - _14941);
                        float _17113;
                        do
                        {
                            int _14985 = int(_283._m22.z);
                            if (_14985 <= 0)
                            {
                                _17113 = spvDepthCast(_303).sample_compare(_303Smplr, float3(fast::clamp(_14946, _14959.xy, _14959.zw), _14683).xy, _14683);
                                break;
                            }
                            float2 _15008 = (_14946 / _283._m22.xy) + float2(0.5);
                            float2 _15009 = floor(_15008);
                            float2 _15014 = _15008 - _15009;
                            float2 _15017 = _15009 - float2(0.5);
                            bool _15021 = _14985 == 1;
                            if (_15021)
                            {
                                float2 _15024 = _15014 * 2.0;
                                _14969[0] = float2(3.0) - _15024;
                                _14969[1] = float2(1.0) + _15024;
                                _14970[0] = ((float2(2.0) - _15014) / _14969[0]) - float2(1.0);
                                _14970[1] = (_15014 / _14969[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _15051 = _15014 * 3.0;
                                _14969[0] = float2(4.0) - _15051;
                                _14969[1] = float2(7.0);
                                _14969[2] = float2(1.0) + _15051;
                                _14970[0] = ((float2(3.0) - (_15014 * 2.0)) / _14969[0]) - float2(2.0);
                                _14970[1] = (float2(3.0) + _15014) / _14969[1];
                                _14970[2] = (_15014 / _14969[2]) + float2(2.0);
                            }
                            int _17818 = _15021 ? 2 : 3;
                            int _17103;
                            float _17106;
                            _17106 = 0.0;
                            _17103 = 0;
                            float _17112;
                            for (; _17103 < _17818; _17106 = _17112, _17103++)
                            {
                                _17112 = _17106;
                                for (int _17109 = 0; _17109 < _17818; )
                                {
                                    _17112 += ((_14969[_17109].x * _14969[_17103].y) * spvDepthCast(_303).sample_compare(_303Smplr, float3(fast::clamp(_283._m22.xy * (_15017 + float2(_14970[_17109].x, _14970[_17103].y)), _14959.xy, _14959.zw), _14683).xy, _14683));
                                    _17109++;
                                    continue;
                                }
                            }
                            _17113 = _17106 * (_15021 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _17125 = _17113;
                        break;
                    } while(false);
                    _17216 = _14432 * _17125;
                }
                else
                {
                    _17216 = _14432;
                }
                float3 _4264 = fast::normalize(_14401 + _3666);
                float _4269 = fast::clamp(dot(_16718, _14401), 0.0, 1.0);
                float _4274 = fast::clamp(dot(_16718, _4264), 0.0, 1.0);
                float3 _15156 = _3956 + (_9739 * powr(1.0 - fast::clamp(dot(_3666, _4264), 0.0, 1.0), 5.0));
                float _15170 = ((_4274 * _4274) * _9754) + 1.0;
                _4312 = _17218 + (((((float3(1.0) - _15156) * _3950) + ((_15156 * ((_9749 / ((3.1415927410125732421875 * _15170) * _15170)) * (0.5 / fast::max((_4269 * _9780) + (_16746 * sqrt(((_4269 * _4269) * _9776) + _9749)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875)) * _4269) * _17216);
            }
            _17281 = _17218;
        }
        else
        {
            _17281 = _4212;
        }
        _17348 = _16908;
        _17278 = _17281;
    }
    float4 _4329 = _4324.sample(_2533, _3419);
    float _4350 = -length(_3665);
    float _17403;
    if (_283._m9.w != 0.0)
    {
        float _4374 = _283._m9.w * (in.m_3037 - _283._m6.xyz).y;
        float _17346;
        if (abs(_4374) < 9.9999997473787516355514526367188e-05)
        {
            _17346 = 1.0 - (0.5 * _4374);
        }
        else
        {
            _17346 = (1.0 - exp(fast::min(-_4374, 60.0))) / _4374;
        }
        _17403 = 1.0 - exp((_4350 * (_283._m7.w * exp(fast::min((-_283._m9.w) * (_283._m6.y - _283._m6.w), 30.0)))) * _17346);
    }
    else
    {
        _17403 = 1.0 - exp(_4350 * _283._m7.w);
    }
    bool _4420 = _283._m34.z > 0.5;
    float3 _17399;
    if (_4420)
    {
        _17399 = _17348 * _17037;
    }
    else
    {
        _17399 = mix(_17278, _16712, float3(_2876._m1.y)) + (((_2876._m5.xyz * _4329.xyz) * (float3(1.0) + in.m_3679.yzw)) * in.m_3911.z);
    }
    float3 _4433 = mix(_17399, _283._m7.xyz, float3(_4420 ? 0.0 : _17403));
    float3 _17404;
    if (_283._m33.w > 0.5)
    {
        _17404 = _4433 / (float3(1.0) + _4433);
    }
    else
    {
        _17404 = _4433;
    }
    out.m_4445 = float4(_17404, in.m_3428.w * in.m_3461.w);
    float2 _17513;
    do
    {
        if (in.m_4455.w <= 0.0)
        {
            _17513 = float2(0.0);
            break;
        }
        _17513 = ((in.m_4455.xy / float2(in.m_4455.w)) - (in.m_4454.xy / float2(in.m_4454.w))) * float2(0.5, -0.5);
        break;
    } while(false);
    out.m_4453 = _17513;
    return out;
}

