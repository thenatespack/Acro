// Generated from mesh_paint.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 0afcc2238fe40a48
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
    float4 m_4432 [[color(0)]];
    float2 m_4440 [[color(1)]];
};

struct fragment_main_in
{
    float3 m_3037 [[user(locn0)]];
    float3 m_2946 [[user(locn1)]];
    float2 m_3405 [[user(locn2)]];
    float4 m_3428 [[user(locn3)]];
    float3 m_2980 [[user(locn4)]];
    float4 m_3666 [[user(locn5)]];
    float4 m_4441 [[user(locn6)]];
    float4 m_4442 [[user(locn7)]];
    float4 m_2952 [[user(locn8)]];
    float4 m_3448 [[user(locn9)]];
    float4 m_3898 [[user(locn10)]];
};

fragment fragment_main_out fragment_main(fragment_main_in in [[stage_in]], constant _2874& _2876 [[buffer(2)]], constant _3028& _3030 [[buffer(3)]], constant _3063& _3065 [[buffer(4)]], constant _3071& _3073 [[buffer(5)]], constant _3165& _3167 [[buffer(6)]], constant _3186& _3188 [[buffer(7)]], constant _281& _283 [[buffer(15)]], const device _1279& _1281 [[buffer(21)]], texture2d<float> _303 [[texture(0)]], texture2d<float> _3421 [[texture(1)]], texture2d<float> _3886 [[texture(2)]], texture2d<float> _3543 [[texture(3)]], texture2d<float> _3352 [[texture(4)]], texture2d<float> _4311 [[texture(5)]], texture2d<float> _2531 [[texture(6)]], texture2d<float> _2632 [[texture(7)]], sampler _303Smplr [[sampler(0)]], sampler _2533 [[sampler(1)]], sampler _2634 [[sampler(7)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])
{
    fragment_main_out out = {};
    float2 _3419 = float2(dot(_2876._m2.xy, in.m_3405) + _2876._m2.z, dot(_2876._m3.xy, in.m_3405) + _2876._m3.z);
    float4 _3426 = _3421.sample(_2533, _3419);
    float3 _3436 = _3426.xyz;
    float3 _3452 = ((in.m_3428.xyz * _2876._m0.xyz) * _3436) * in.m_3448.xyz;
    float3 _16507;
    if (_2876._m1.x > 0.5)
    {
        float2 _3467 = floor(in.m_3037.xz * float2(0.5));
        _16507 = _3452 * ((mod(abs(_3467.x + _3467.y), 2.0) < 0.5) ? 1.0 : 0.75);
    }
    else
    {
        _16507 = _3452;
    }
    float3 _16604;
    float _16635;
    float2 _16668;
    if (_2876._m3.w > 0.5)
    {
        float3 _4548;
        float2 _4555;
        float _16505;
        do
        {
            float3 _4519 = float4(_2876._m2.w, _2876._m3.w, 0.0, 0.0).xyy;
            float3 _4522 = floor(_4519 * float3(1.52587890625e-05));
            float3 _4527 = _4519 - (_4522 * 65536.0);
            float3 _4530 = floor(_4527 * float3(0.00390625));
            float3 _4538 = _4527 - (_4530 * 256.0);
            _4548 = (float3(_4538.x, _4530.x, _4522.x) * float3(0.0039215688593685626983642578125)) * 2.0;
            _4555 = float2(_4538.y, _4530.y) * float2(0.0039215688593685626983642578125);
            float _4558 = _4522.y - 128.0;
            float _4564 = floor(_4558 * 0.03125) * 0.3333333432674407958984375;
            float3 _4570 = fast::normalize(in.m_2946);
            float _4574 = dot(_4570, in.m_2952.xyz);
            float _4586 = (_4574 / fast::max(length(in.m_2952.xyz - (_4570 * _4574)), 9.9999999747524270787835121154785e-07)) * 25.5;
            if (((-24.0) + _4586) < (-2.0))
            {
                _16505 = 0.0;
                break;
            }
            float3 _4594 = in.m_2980 * (4.0 * exp2(mod(_4558, 32.0) * 0.3333333432674407958984375));
            float3 _4638 = floor(_4594);
            float3 _4641 = _4594 - _4638;
            float3 _4649 = (_4641 * _4641) * (float3(3.0) - (_4641 * 2.0));
            uint3 _4716 = uint3(int3(_4638));
            uint _4729 = (((_4716.x * 1597334677u) ^ (_4716.y * 3812015801u)) ^ (_4716.z * 2798796415u)) * 1597334677u;
            uint3 _4744 = uint3(int3(_4638 + float3(1.0, 0.0, 0.0)));
            uint _4757 = (((_4744.x * 1597334677u) ^ (_4744.y * 3812015801u)) ^ (_4744.z * 2798796415u)) * 1597334677u;
            float _4658 = _4649.x;
            uint3 _4772 = uint3(int3(_4638 + float3(0.0, 1.0, 0.0)));
            uint _4785 = (((_4772.x * 1597334677u) ^ (_4772.y * 3812015801u)) ^ (_4772.z * 2798796415u)) * 1597334677u;
            uint3 _4800 = uint3(int3(_4638 + float3(1.0, 1.0, 0.0)));
            uint _4813 = (((_4800.x * 1597334677u) ^ (_4800.y * 3812015801u)) ^ (_4800.z * 2798796415u)) * 1597334677u;
            float _4674 = _4649.y;
            uint3 _4828 = uint3(int3(_4638 + float3(0.0, 0.0, 1.0)));
            uint _4841 = (((_4828.x * 1597334677u) ^ (_4828.y * 3812015801u)) ^ (_4828.z * 2798796415u)) * 1597334677u;
            uint3 _4856 = uint3(int3(_4638 + float3(1.0, 0.0, 1.0)));
            uint _4869 = (((_4856.x * 1597334677u) ^ (_4856.y * 3812015801u)) ^ (_4856.z * 2798796415u)) * 1597334677u;
            uint3 _4884 = uint3(int3(_4638 + float3(0.0, 1.0, 1.0)));
            uint _4897 = (((_4884.x * 1597334677u) ^ (_4884.y * 3812015801u)) ^ (_4884.z * 2798796415u)) * 1597334677u;
            uint3 _4912 = uint3(int3(_4638 + float3(1.0)));
            uint _4925 = (((_4912.x * 1597334677u) ^ (_4912.y * 3812015801u)) ^ (_4912.z * 2798796415u)) * 1597334677u;
            float3 _4600 = (_4594 * 2.7000000476837158203125) + float3(17.299999237060546875, 5.099999904632568359375, 9.69999980926513671875);
            float3 _4951 = floor(_4600);
            float3 _4954 = _4600 - _4951;
            float3 _4962 = (_4954 * _4954) * (float3(3.0) - (_4954 * 2.0));
            uint3 _5029 = uint3(int3(_4951));
            uint _5042 = (((_5029.x * 1597334677u) ^ (_5029.y * 3812015801u)) ^ (_5029.z * 2798796415u)) * 1597334677u;
            uint3 _5057 = uint3(int3(_4951 + float3(1.0, 0.0, 0.0)));
            uint _5070 = (((_5057.x * 1597334677u) ^ (_5057.y * 3812015801u)) ^ (_5057.z * 2798796415u)) * 1597334677u;
            float _4971 = _4962.x;
            uint3 _5085 = uint3(int3(_4951 + float3(0.0, 1.0, 0.0)));
            uint _5098 = (((_5085.x * 1597334677u) ^ (_5085.y * 3812015801u)) ^ (_5085.z * 2798796415u)) * 1597334677u;
            uint3 _5113 = uint3(int3(_4951 + float3(1.0, 1.0, 0.0)));
            uint _5126 = (((_5113.x * 1597334677u) ^ (_5113.y * 3812015801u)) ^ (_5113.z * 2798796415u)) * 1597334677u;
            float _4987 = _4962.y;
            uint3 _5141 = uint3(int3(_4951 + float3(0.0, 0.0, 1.0)));
            uint _5154 = (((_5141.x * 1597334677u) ^ (_5141.y * 3812015801u)) ^ (_5141.z * 2798796415u)) * 1597334677u;
            uint3 _5169 = uint3(int3(_4951 + float3(1.0, 0.0, 1.0)));
            uint _5182 = (((_5169.x * 1597334677u) ^ (_5169.y * 3812015801u)) ^ (_5169.z * 2798796415u)) * 1597334677u;
            uint3 _5197 = uint3(int3(_4951 + float3(0.0, 1.0, 1.0)));
            uint _5210 = (((_5197.x * 1597334677u) ^ (_5197.y * 3812015801u)) ^ (_5197.z * 2798796415u)) * 1597334677u;
            uint3 _5225 = uint3(int3(_4951 + float3(1.0)));
            uint _5238 = (((_5225.x * 1597334677u) ^ (_5225.y * 3812015801u)) ^ (_5225.z * 2798796415u)) * 1597334677u;
            float _4605 = mix(0.449999988079071044921875, 0.0500000007450580596923828125, _4564);
            float _4609 = ((mix(mix(mix(float((_4729 ^ (_4729 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_4757 ^ (_4757 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _4658), mix(float((_4785 ^ (_4785 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_4813 ^ (_4813 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _4658), _4674), mix(mix(float((_4841 ^ (_4841 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_4869 ^ (_4869 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _4658), mix(float((_4897 ^ (_4897 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_4925 ^ (_4925 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _4658), _4674), _4649.z) * 0.64999997615814208984375) + (mix(mix(mix(float((_5042 ^ (_5042 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_5070 ^ (_5070 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _4971), mix(float((_5098 ^ (_5098 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_5126 ^ (_5126 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _4971), _4987), mix(mix(float((_5154 ^ (_5154 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_5182 ^ (_5182 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _4971), mix(float((_5210 ^ (_5210 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_5238 ^ (_5238 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _4971), _4987), _4962.z) * 0.3499999940395355224609375)) - 0.5;
            _16505 = smoothstep(-_4605, _4605, (_4586 + (-24.450000762939453125)) + (_4609 * mix(0.800000011920928955078125, 2.2000000476837158203125, _4564)));
            break;
        } while(false);
        _16668 = _4555;
        _16635 = _16505;
        _16604 = mix(_16507, (in.m_3428.xyz * _4548) * mix(float3(1.0), _3436 * 2.0, float3(0.5)), float3(_16505));
    }
    else
    {
        _16668 = float2(0.0);
        _16635 = 0.0;
        _16604 = _16507;
    }
    float3 _3509 = fast::normalize(in.m_2946);
    float3 _16517;
    if (_2876._m6.y > 0.5)
    {
        float3 _3524 = in.m_2952.xyz - (_3509 * dot(_3509, in.m_2952.xyz));
        float3 _16518;
        if (dot(_3524, _3524) > 9.9999999600419720025001879548654e-13)
        {
            float3 _3532 = fast::normalize(_3524);
            float4 _3548 = _3543.sample(_2533, _3419);
            float3 _16509;
            if (_2876._m6.z > 0.5)
            {
                float2 _16508;
                if (_2876._m6.z > 1.5)
                {
                    _16508 = _3548.xw;
                }
                else
                {
                    _16508 = _3548.xy;
                }
                float2 _3570 = (_16508 * 2.0) - float2(1.0);
                _16509 = float3(_3570, sqrt(fast::clamp(1.0 - dot(_3570, _3570), 0.0, 1.0)));
            }
            else
            {
                _16509 = (_3548.xyz * 2.0) - float3(1.0);
            }
            float2 _3592 = _16509.xy * _2876._m4.z;
            _16518 = fast::normalize(((_3532 * _3592.x) + ((cross(_3509, _3532) * ((in.m_2952.w < 0.0) ? (-1.0) : 1.0)) * _3592.y)) + (_3509 * _16509.z));
        }
        else
        {
            _16518 = _3509;
        }
        _16517 = _16518;
    }
    else
    {
        _16517 = _3509;
    }
    bool _3616 = _2876._m5.w > 0.5;
    float _16514;
    if (_3616)
    {
        _16514 = fast::clamp(_2876._m1.z, 0.0, 1.0);
    }
    else
    {
        _16514 = 0.0;
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
    float3 _16704;
    if (_3634 && (_16514 <= 0.0))
    {
        _16704 = -_16517;
    }
    else
    {
        _16704 = _16517;
    }
    float3 _3646 = fast::normalize(_283._m4.xyz);
    float3 _3652 = _283._m6.xyz - in.m_3037;
    float3 _3653 = fast::normalize(_3652);
    float3 _3658 = fast::normalize(_3646 + _3653);
    float3 _3664 = _3509 * (gl_FrontFacing ? 1.0 : (-1.0));
    bool _3669 = in.m_3666.x > 0.5;
    float3 _16698;
    float _16738;
    if ((_283._m5.w > 0.5) && _3669)
    {
        float _16574;
        float3 _16575;
        do
        {
            int _5267 = int(_283._m21.x);
            float _5275 = dot(_283._m20.xyz, in.m_3037) + _283._m20.w;
            int _16519;
            _16519 = 0;
            for (;;)
            {
                bool _5281 = _16519 < (_5267 - 1);
                bool _5289;
                if (_5281)
                {
                    _5289 = _5275 > _283._m16[_16519];
                }
                else
                {
                    _5289 = _5281;
                }
                if (_5289)
                {
                    _16519++;
                    continue;
                }
                else
                {
                    break;
                }
            }
            if (_5275 > _283._m16[_16519])
            {
                _16575 = float3(1.0);
                _16574 = 1.0;
                break;
            }
            float _16532;
            do
            {
                float4 _5391 = _283._m14[_16519] * float4(in.m_3037 + (_3664 * _283._m18[_16519]), 1.0);
                float _5394 = _5391.x;
                bool _5395 = _5394 < 0.0;
                bool _5402;
                if (!_5395)
                {
                    _5402 = _5394 > 1.0;
                }
                else
                {
                    _5402 = _5395;
                }
                bool _5409;
                if (!_5402)
                {
                    _5409 = _5391.y < 0.0;
                }
                else
                {
                    _5409 = _5402;
                }
                bool _5416;
                if (!_5409)
                {
                    _5416 = _5391.y > 1.0;
                }
                else
                {
                    _5416 = _5409;
                }
                if (_5416)
                {
                    _16532 = 1.0;
                    break;
                }
                float2 _5429 = float2(float(_16519 & 1), float(_16519 >> 1)) * _283._m23.xy;
                float _5436 = fast::min(_5391.z, 1.0) - _283._m19[_16519];
                float2 _5455 = _283._m22.xy * 0.5;
                float2 _5460 = _5429 + (_5391.xy * _283._m23.xy);
                float4 _5473 = float4(_5429 + _5455, (_5429 + _283._m23.xy) - _5455);
                float _16531;
                do
                {
                    int _5499 = int(_283._m22.z);
                    if (_5499 <= 0)
                    {
                        _16531 = spvDepthCast(_303).sample_compare(_303Smplr, float3(fast::clamp(_5460, _5473.xy, _5473.zw), _5436).xy, _5436);
                        break;
                    }
                    float2 _5522 = (_5460 / _283._m22.xy) + float2(0.5);
                    float2 _5523 = floor(_5522);
                    float2 _5528 = _5522 - _5523;
                    float2 _5531 = _5523 - float2(0.5);
                    bool _5535 = _5499 == 1;
                    spvUnsafeArray<float2, 3> _5483;
                    spvUnsafeArray<float2, 3> _5484;
                    if (_5535)
                    {
                        float2 _5538 = _5528 * 2.0;
                        _5483[0] = float2(3.0) - _5538;
                        _5483[1] = float2(1.0) + _5538;
                        _5484[0] = ((float2(2.0) - _5528) / _5483[0]) - float2(1.0);
                        _5484[1] = (_5528 / _5483[1]) + float2(1.0);
                    }
                    else
                    {
                        float2 _5565 = _5528 * 3.0;
                        _5483[0] = float2(4.0) - _5565;
                        _5483[1] = float2(7.0);
                        _5483[2] = float2(1.0) + _5565;
                        _5484[0] = ((float2(3.0) - (_5528 * 2.0)) / _5483[0]) - float2(2.0);
                        _5484[1] = (float2(3.0) + _5528) / _5483[1];
                        _5484[2] = (_5528 / _5483[2]) + float2(2.0);
                    }
                    int _17657 = _5535 ? 2 : 3;
                    int _16521;
                    float _16524;
                    _16524 = 0.0;
                    _16521 = 0;
                    float _16530;
                    for (; _16521 < _17657; _16524 = _16530, _16521++)
                    {
                        _16530 = _16524;
                        for (int _16527 = 0; _16527 < _17657; )
                        {
                            _16530 += ((_5483[_16527].x * _5483[_16521].y) * spvDepthCast(_303).sample_compare(_303Smplr, float3(fast::clamp(_283._m22.xy * (_5531 + float2(_5484[_16527].x, _5484[_16521].y)), _5473.xy, _5473.zw), _5436).xy, _5436));
                            _16527++;
                            continue;
                        }
                    }
                    _16531 = _16524 * (_5535 ? 0.0625 : 0.0069444444961845874786376953125);
                    break;
                } while(false);
                _16532 = _16531;
                break;
            } while(false);
            float3 _16569;
            float _16572;
            if (_5275 > _283._m17[_16519])
            {
                float _5329 = (_5275 - _283._m17[_16519]) / (_283._m16[_16519] - _283._m17[_16519]);
                int _5331 = _16519 + 1;
                float3 _16570;
                float _16573;
                if (_5331 < _5267)
                {
                    float _16552;
                    do
                    {
                        float4 _5678 = _283._m14[_5331] * float4(in.m_3037 + (_3664 * _283._m18[_5331]), 1.0);
                        float _5681 = _5678.x;
                        bool _5682 = _5681 < 0.0;
                        bool _5689;
                        if (!_5682)
                        {
                            _5689 = _5681 > 1.0;
                        }
                        else
                        {
                            _5689 = _5682;
                        }
                        bool _5696;
                        if (!_5689)
                        {
                            _5696 = _5678.y < 0.0;
                        }
                        else
                        {
                            _5696 = _5689;
                        }
                        bool _5703;
                        if (!_5696)
                        {
                            _5703 = _5678.y > 1.0;
                        }
                        else
                        {
                            _5703 = _5696;
                        }
                        if (_5703)
                        {
                            _16552 = 1.0;
                            break;
                        }
                        float2 _5716 = float2(float(_5331 & 1), float(_5331 >> 1)) * _283._m23.xy;
                        float _5723 = fast::min(_5678.z, 1.0) - _283._m19[_5331];
                        float2 _5742 = _283._m22.xy * 0.5;
                        float2 _5747 = _5716 + (_5678.xy * _283._m23.xy);
                        float4 _5760 = float4(_5716 + _5742, (_5716 + _283._m23.xy) - _5742);
                        float _16551;
                        do
                        {
                            int _5786 = int(_283._m22.z);
                            if (_5786 <= 0)
                            {
                                _16551 = spvDepthCast(_303).sample_compare(_303Smplr, float3(fast::clamp(_5747, _5760.xy, _5760.zw), _5723).xy, _5723);
                                break;
                            }
                            float2 _5809 = (_5747 / _283._m22.xy) + float2(0.5);
                            float2 _5810 = floor(_5809);
                            float2 _5815 = _5809 - _5810;
                            float2 _5818 = _5810 - float2(0.5);
                            bool _5822 = _5786 == 1;
                            spvUnsafeArray<float2, 3> _5770;
                            spvUnsafeArray<float2, 3> _5771;
                            if (_5822)
                            {
                                float2 _5825 = _5815 * 2.0;
                                _5770[0] = float2(3.0) - _5825;
                                _5770[1] = float2(1.0) + _5825;
                                _5771[0] = ((float2(2.0) - _5815) / _5770[0]) - float2(1.0);
                                _5771[1] = (_5815 / _5770[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _5852 = _5815 * 3.0;
                                _5770[0] = float2(4.0) - _5852;
                                _5770[1] = float2(7.0);
                                _5770[2] = float2(1.0) + _5852;
                                _5771[0] = ((float2(3.0) - (_5815 * 2.0)) / _5770[0]) - float2(2.0);
                                _5771[1] = (float2(3.0) + _5815) / _5770[1];
                                _5771[2] = (_5815 / _5770[2]) + float2(2.0);
                            }
                            int _17659 = _5822 ? 2 : 3;
                            int _16541;
                            float _16544;
                            _16544 = 0.0;
                            _16541 = 0;
                            float _16550;
                            for (; _16541 < _17659; _16544 = _16550, _16541++)
                            {
                                _16550 = _16544;
                                for (int _16547 = 0; _16547 < _17659; )
                                {
                                    _16550 += ((_5770[_16547].x * _5770[_16541].y) * spvDepthCast(_303).sample_compare(_303Smplr, float3(fast::clamp(_283._m22.xy * (_5818 + float2(_5771[_16547].x, _5771[_16541].y)), _5760.xy, _5760.zw), _5723).xy, _5723));
                                    _16547++;
                                    continue;
                                }
                            }
                            _16551 = _16544 * (_5822 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _16552 = _16551;
                        break;
                    } while(false);
                    _16573 = mix(_16532, _16552, _5329);
                    _16570 = mix(_657[_16519], _657[_5331], float3(_5329));
                }
                else
                {
                    _16573 = mix(_16532, 1.0, _5329);
                    _16570 = _657[_16519];
                }
                _16572 = _16573;
                _16569 = _16570;
            }
            else
            {
                _16572 = _16532;
                _16569 = _657[_16519];
            }
            _16575 = select(float3(1.0), _16569, bool3(_283._m22.w > 0.5));
            _16574 = _16572;
            break;
        } while(false);
        _16738 = _16574;
        _16698 = _16604 * _16575;
    }
    else
    {
        _16738 = 1.0;
        _16698 = _16604;
    }
    float3 _3695 = _283._m5.xyz * _283._m4.w;
    bool _3699 = _2876._m6.w > 0.5;
    float _16627;
    if (_3699)
    {
        _16627 = 1.0;
    }
    else
    {
        _16627 = 1.0 + (_2876._m4.w * (_3352.sample(_2533, _3419).x - 1.0));
    }
    float _3719 = abs(in.m_2952.w);
    float _17023;
    if (_3719 > 0.0)
    {
        _17023 = _16627 * fast::min(_3719, 1.0);
    }
    else
    {
        _17023 = _16627;
    }
    float3 _17264;
    float3 _17334;
    if (!_3616)
    {
        float _3735 = dot(_16704, _3646);
        float3 _17245;
        if (_283._m29.x > 0.5)
        {
            float _6003 = (_283._m29.z * _16704.x) - (_283._m29.w * _16704.z);
            float _6016 = (_283._m29.w * _16704.x) + (_283._m29.z * _16704.z);
            float _6034 = 1.09254801273345947265625 * _6003;
            spvUnsafeArray<float, 9> _15500 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _16704.y, 0.48860299587249755859375 * _6016, 0.48860299587249755859375 * _6003, _6034 * _16704.y, (1.09254801273345947265625 * _16704.y) * _6016, 0.3153919875621795654296875 * (((3.0 * _6016) * _6016) - 1.0), _6034 * _6016, 0.546274006366729736328125 * ((_6003 * _6003) - (_16704.y * _16704.y)) });
            spvUnsafeArray<float, 9> _5948 = _15500;
            float3 _17244;
            _17244 = float3(0.0);
            for (int _17243 = 0; _17243 < 9; )
            {
                _17244 += (_2531.read(uint2((int2(496, 256) + int2(_17243, 0))), 0).xyz * _5948[_17243]);
                _17243++;
                continue;
            }
            _17245 = fast::max(_17244, float3(0.0)) * _283._m29.y;
        }
        else
        {
            _17245 = mix(_283._m9.xyz, _283._m8.xyz, float3((_16704.y * 0.5) + 0.5)) * _283._m8.w;
        }
        float3 _17250;
        if (_283._m34.y > 0.5)
        {
            int _6211 = int(_283._m34.y);
            int _6214 = int(_283._m34.x);
            float3 _17249;
            _17249 = _17245;
            float3 _17544;
            for (int _17248 = 0; _17248 < _6211; _17249 = _17544, _17248++)
            {
                int _6226 = 8 * (_6214 + _17248);
                float4 _6435 = as_type<float4>(_1281._m0[_6226 + 3]);
                float4 _6479 = as_type<float4>(_1281._m0[_6226]);
                float4 _6485 = as_type<float4>(_1281._m0[_6226 + 1]);
                float4 _6491 = as_type<float4>(_1281._m0[_6226 + 2]);
                float3 _6453 = _6479.xyz;
                float _6457 = _6479.w;
                float3 _6460 = _6485.xyz;
                float _6464 = _6485.w;
                float3 _6467 = _6491.xyz;
                float _6471 = _6491.w;
                float3 _6473 = float3(dot(_6453, in.m_3037) + _6457, dot(_6460, in.m_3037) + _6464, dot(_6467, in.m_3037) + _6471);
                float3 _6235 = _6435.xyz;
                float _6237 = _6435.w;
                float _17507;
                do
                {
                    float3 _6503 = _6235 - abs(_6473);
                    float _6511 = fast::min(_6503.x, fast::min(_6503.y, _6503.z));
                    if (_6511 <= 0.0)
                    {
                        _17507 = 0.0;
                        break;
                    }
                    if (_6237 <= 0.0)
                    {
                        _17507 = 1.0;
                        break;
                    }
                    float _6523 = fast::min(_6511 / _6237, 1.0);
                    _17507 = (_6523 * _6523) * (3.0 - (2.0 * _6523));
                    break;
                } while(false);
                if (_17507 <= 0.0)
                {
                    _17544 = _17249;
                    continue;
                }
                float3 _6246 = as_type<float4>(_1281._m0[_6226 + 4]).xyz;
                float4 _6544 = as_type<float4>(_1281._m0[_6226 + 5]);
                int _6550 = int(((device uint*)&_1281._m0[_6226 + 6])[0u]);
                float _6560 = dot(_6453, _16704);
                float _6566 = dot(_6460, _16704);
                float _6572 = dot(_6467, _16704);
                float3 _6573 = float3(_6560, _6566, _6572);
                float3 _6266 = (in.m_3037 + (_16704 * _6544.x)) + (_3653 * _6544.y);
                float3 _6285 = fast::clamp((((float3(dot(_6453, _6266) + _6457, dot(_6460, _6266) + _6464, dot(_6467, _6266) + _6471) + _6235) / fast::max(_6235 * 2.0, float3(9.9999999747524270787835121154785e-07))) * _6246) - float3(0.5), float3(0.0), _6246 - float3(1.0));
                int3 _6287 = int3(_6246);
                int3 _6294 = min(int3(_6285), max((_6287 - int3(2)), int3(0)));
                float3 _6298 = _6285 - float3(_6294);
                float _6653 = 0.48860299587249755859375 * _6566;
                float _6656 = 0.48860299587249755859375 * _6572;
                float _6659 = 0.48860299587249755859375 * _6560;
                float _6664 = 1.09254801273345947265625 * _6560;
                float _6667 = _6664 * _6566;
                float _6673 = (1.09254801273345947265625 * _6566) * _6572;
                float _6681 = 0.3153919875621795654296875 * (((3.0 * _6572) * _6572) - 1.0);
                float _6687 = _6664 * _6572;
                float _6701 = 0.546274006366729736328125 * ((_6560 * _6560) - (_6566 * _6566));
                int3 _6720 = _6287 - int3(1);
                int3 _6721 = min(_6294, _6720);
                int _6726 = _6287.x;
                int _6730 = _6287.y;
                int _6738 = _6550 + ((_6721.x + (_6726 * (_6721.y + (_6730 * _6721.z)))) * 4);
                float3 _6741 = float3(1.0) - _6298;
                float3 _6759 = (((((float3(_6721) + float3(0.5)) / _6246) * _6235) * 2.0) - _6235) - _6473;
                float _6769 = dot(_6759 * rsqrt(fast::max(dot(_6759, _6759), 1.0000000133514319600180897396058e-10)), _6573) + 1.0;
                float _6772 = _6741.x;
                float _6774 = _6741.y;
                float _6775 = _6772 * _6774;
                float _6777 = _6741.z;
                int _6801 = _6738 + 3;
                float _6787 = ((_6775 * _6777) * ((0.25 * (_6769 * _6769)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_6801])[1u])).y > 0.5);
                int _6831 = _6738 + 1;
                int _6835 = _6738 + 2;
                float2 _6847 = float2(as_type<half2>(_1281._m0[_6738].y));
                float2 _6856 = float2(as_type<half2>(_1281._m0[_6831].x));
                float2 _6865 = float2(as_type<half2>(_1281._m0[_6831].w));
                float2 _6874 = float2(as_type<half2>(_1281._m0[_6835].z));
                float3 _6962 = (((((((float3(float2(as_type<half2>(_1281._m0[_6738].x)), _6847.x) * 0.2820949852466583251953125) + (float3(_6847.y, float2(as_type<half2>(_1281._m0[_6738].z))) * _6653)) + (float3(float2(as_type<half2>(_1281._m0[_6738].w)), _6856.x) * _6656)) + (float3(_6856.y, float2(as_type<half2>(_1281._m0[_6831].y))) * _6659)) + (float3(float2(as_type<half2>(_1281._m0[_6831].z)), _6865.x) * _6667)) + (float3(_6865.y, float2(as_type<half2>(_1281._m0[_6835].x))) * _6673)) + (float3(float2(as_type<half2>(_1281._m0[_6835].y)), _6874.x) * _6681)) + (float3(_6874.y, float2(as_type<half2>(_1281._m0[_6835].w))) * _6687);
                int3 _6990 = min((_6294 + int3(1, 0, 0)), _6720);
                int _7007 = _6550 + ((_6990.x + (_6726 * (_6990.y + (_6730 * _6990.z)))) * 4);
                float3 _7028 = (((((float3(_6990) + float3(0.5)) / _6246) * _6235) * 2.0) - _6235) - _6473;
                float _7038 = dot(_7028 * rsqrt(fast::max(dot(_7028, _7028), 1.0000000133514319600180897396058e-10)), _6573) + 1.0;
                float _7044 = _6298.x * _6774;
                int _7070 = _7007 + 3;
                float _7056 = ((_7044 * _6777) * ((0.25 * (_7038 * _7038)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_7070])[1u])).y > 0.5);
                int _7100 = _7007 + 1;
                int _7104 = _7007 + 2;
                float2 _7116 = float2(as_type<half2>(_1281._m0[_7007].y));
                float2 _7125 = float2(as_type<half2>(_1281._m0[_7100].x));
                float2 _7134 = float2(as_type<half2>(_1281._m0[_7100].w));
                float2 _7143 = float2(as_type<half2>(_1281._m0[_7104].z));
                float3 _7231 = (((((((float3(float2(as_type<half2>(_1281._m0[_7007].x)), _7116.x) * 0.2820949852466583251953125) + (float3(_7116.y, float2(as_type<half2>(_1281._m0[_7007].z))) * _6653)) + (float3(float2(as_type<half2>(_1281._m0[_7007].w)), _7125.x) * _6656)) + (float3(_7125.y, float2(as_type<half2>(_1281._m0[_7100].y))) * _6659)) + (float3(float2(as_type<half2>(_1281._m0[_7100].z)), _7134.x) * _6667)) + (float3(_7134.y, float2(as_type<half2>(_1281._m0[_7104].x))) * _6673)) + (float3(float2(as_type<half2>(_1281._m0[_7104].y)), _7143.x) * _6681)) + (float3(_7143.y, float2(as_type<half2>(_1281._m0[_7104].w))) * _6687);
                int3 _7259 = min((_6294 + int3(0, 1, 0)), _6720);
                int _7276 = _6550 + ((_7259.x + (_6726 * (_7259.y + (_6730 * _7259.z)))) * 4);
                float3 _7297 = (((((float3(_7259) + float3(0.5)) / _6246) * _6235) * 2.0) - _6235) - _6473;
                float _7307 = dot(_7297 * rsqrt(fast::max(dot(_7297, _7297), 1.0000000133514319600180897396058e-10)), _6573) + 1.0;
                float _7313 = _6772 * _6298.y;
                int _7339 = _7276 + 3;
                float _7325 = ((_7313 * _6777) * ((0.25 * (_7307 * _7307)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_7339])[1u])).y > 0.5);
                int _7369 = _7276 + 1;
                int _7373 = _7276 + 2;
                float2 _7385 = float2(as_type<half2>(_1281._m0[_7276].y));
                float2 _7394 = float2(as_type<half2>(_1281._m0[_7369].x));
                float2 _7403 = float2(as_type<half2>(_1281._m0[_7369].w));
                float2 _7412 = float2(as_type<half2>(_1281._m0[_7373].z));
                float3 _7500 = (((((((float3(float2(as_type<half2>(_1281._m0[_7276].x)), _7385.x) * 0.2820949852466583251953125) + (float3(_7385.y, float2(as_type<half2>(_1281._m0[_7276].z))) * _6653)) + (float3(float2(as_type<half2>(_1281._m0[_7276].w)), _7394.x) * _6656)) + (float3(_7394.y, float2(as_type<half2>(_1281._m0[_7369].y))) * _6659)) + (float3(float2(as_type<half2>(_1281._m0[_7369].z)), _7403.x) * _6667)) + (float3(_7403.y, float2(as_type<half2>(_1281._m0[_7373].x))) * _6673)) + (float3(float2(as_type<half2>(_1281._m0[_7373].y)), _7412.x) * _6681)) + (float3(_7412.y, float2(as_type<half2>(_1281._m0[_7373].w))) * _6687);
                int3 _7528 = min((_6294 + int3(1, 1, 0)), _6720);
                int _7545 = _6550 + ((_7528.x + (_6726 * (_7528.y + (_6730 * _7528.z)))) * 4);
                float3 _7566 = (((((float3(_7528) + float3(0.5)) / _6246) * _6235) * 2.0) - _6235) - _6473;
                float _7576 = dot(_7566 * rsqrt(fast::max(dot(_7566, _7566), 1.0000000133514319600180897396058e-10)), _6573) + 1.0;
                float _7582 = _6298.x * _6298.y;
                int _7608 = _7545 + 3;
                float _7594 = ((_7582 * _6777) * ((0.25 * (_7576 * _7576)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_7608])[1u])).y > 0.5);
                int _7638 = _7545 + 1;
                int _7642 = _7545 + 2;
                float2 _7654 = float2(as_type<half2>(_1281._m0[_7545].y));
                float2 _7663 = float2(as_type<half2>(_1281._m0[_7638].x));
                float2 _7672 = float2(as_type<half2>(_1281._m0[_7638].w));
                float2 _7681 = float2(as_type<half2>(_1281._m0[_7642].z));
                float3 _7769 = (((((((float3(float2(as_type<half2>(_1281._m0[_7545].x)), _7654.x) * 0.2820949852466583251953125) + (float3(_7654.y, float2(as_type<half2>(_1281._m0[_7545].z))) * _6653)) + (float3(float2(as_type<half2>(_1281._m0[_7545].w)), _7663.x) * _6656)) + (float3(_7663.y, float2(as_type<half2>(_1281._m0[_7638].y))) * _6659)) + (float3(float2(as_type<half2>(_1281._m0[_7638].z)), _7672.x) * _6667)) + (float3(_7672.y, float2(as_type<half2>(_1281._m0[_7642].x))) * _6673)) + (float3(float2(as_type<half2>(_1281._m0[_7642].y)), _7681.x) * _6681)) + (float3(_7681.y, float2(as_type<half2>(_1281._m0[_7642].w))) * _6687);
                int3 _7797 = min((_6294 + int3(0, 0, 1)), _6720);
                int _7814 = _6550 + ((_7797.x + (_6726 * (_7797.y + (_6730 * _7797.z)))) * 4);
                float3 _7835 = (((((float3(_7797) + float3(0.5)) / _6246) * _6235) * 2.0) - _6235) - _6473;
                float _7845 = dot(_7835 * rsqrt(fast::max(dot(_7835, _7835), 1.0000000133514319600180897396058e-10)), _6573) + 1.0;
                int _7877 = _7814 + 3;
                float _7863 = ((_6775 * _6298.z) * ((0.25 * (_7845 * _7845)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_7877])[1u])).y > 0.5);
                int _7907 = _7814 + 1;
                int _7911 = _7814 + 2;
                float2 _7923 = float2(as_type<half2>(_1281._m0[_7814].y));
                float2 _7932 = float2(as_type<half2>(_1281._m0[_7907].x));
                float2 _7941 = float2(as_type<half2>(_1281._m0[_7907].w));
                float2 _7950 = float2(as_type<half2>(_1281._m0[_7911].z));
                float3 _8038 = (((((((float3(float2(as_type<half2>(_1281._m0[_7814].x)), _7923.x) * 0.2820949852466583251953125) + (float3(_7923.y, float2(as_type<half2>(_1281._m0[_7814].z))) * _6653)) + (float3(float2(as_type<half2>(_1281._m0[_7814].w)), _7932.x) * _6656)) + (float3(_7932.y, float2(as_type<half2>(_1281._m0[_7907].y))) * _6659)) + (float3(float2(as_type<half2>(_1281._m0[_7907].z)), _7941.x) * _6667)) + (float3(_7941.y, float2(as_type<half2>(_1281._m0[_7911].x))) * _6673)) + (float3(float2(as_type<half2>(_1281._m0[_7911].y)), _7950.x) * _6681)) + (float3(_7950.y, float2(as_type<half2>(_1281._m0[_7911].w))) * _6687);
                float4 _6365 = (((float4((_6962 + (float3(float2(as_type<half2>(_1281._m0[_6801].x)), float2(as_type<half2>(_1281._m0[_6801].y)).x) * _6701)) * _6787, _6787) + float4((_7231 + (float3(float2(as_type<half2>(_1281._m0[_7070].x)), float2(as_type<half2>(_1281._m0[_7070].y)).x) * _6701)) * _7056, _7056)) + float4((_7500 + (float3(float2(as_type<half2>(_1281._m0[_7339].x)), float2(as_type<half2>(_1281._m0[_7339].y)).x) * _6701)) * _7325, _7325)) + float4((_7769 + (float3(float2(as_type<half2>(_1281._m0[_7608].x)), float2(as_type<half2>(_1281._m0[_7608].y)).x) * _6701)) * _7594, _7594)) + float4((_8038 + (float3(float2(as_type<half2>(_1281._m0[_7877].x)), float2(as_type<half2>(_1281._m0[_7877].y)).x) * _6701)) * _7863, _7863);
                int3 _8066 = min((_6294 + int3(1, 0, 1)), _6720);
                int _8083 = _6550 + ((_8066.x + (_6726 * (_8066.y + (_6730 * _8066.z)))) * 4);
                float3 _8104 = (((((float3(_8066) + float3(0.5)) / _6246) * _6235) * 2.0) - _6235) - _6473;
                float _8114 = dot(_8104 * rsqrt(fast::max(dot(_8104, _8104), 1.0000000133514319600180897396058e-10)), _6573) + 1.0;
                int _8146 = _8083 + 3;
                float _8132 = ((_7044 * _6298.z) * ((0.25 * (_8114 * _8114)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_8146])[1u])).y > 0.5);
                int _8176 = _8083 + 1;
                int _8180 = _8083 + 2;
                float2 _8192 = float2(as_type<half2>(_1281._m0[_8083].y));
                float2 _8201 = float2(as_type<half2>(_1281._m0[_8176].x));
                float2 _8210 = float2(as_type<half2>(_1281._m0[_8176].w));
                float2 _8219 = float2(as_type<half2>(_1281._m0[_8180].z));
                float3 _8307 = (((((((float3(float2(as_type<half2>(_1281._m0[_8083].x)), _8192.x) * 0.2820949852466583251953125) + (float3(_8192.y, float2(as_type<half2>(_1281._m0[_8083].z))) * _6653)) + (float3(float2(as_type<half2>(_1281._m0[_8083].w)), _8201.x) * _6656)) + (float3(_8201.y, float2(as_type<half2>(_1281._m0[_8176].y))) * _6659)) + (float3(float2(as_type<half2>(_1281._m0[_8176].z)), _8210.x) * _6667)) + (float3(_8210.y, float2(as_type<half2>(_1281._m0[_8180].x))) * _6673)) + (float3(float2(as_type<half2>(_1281._m0[_8180].y)), _8219.x) * _6681)) + (float3(_8219.y, float2(as_type<half2>(_1281._m0[_8180].w))) * _6687);
                int3 _8335 = min((_6294 + int3(0, 1, 1)), _6720);
                int _8352 = _6550 + ((_8335.x + (_6726 * (_8335.y + (_6730 * _8335.z)))) * 4);
                float3 _8373 = (((((float3(_8335) + float3(0.5)) / _6246) * _6235) * 2.0) - _6235) - _6473;
                float _8383 = dot(_8373 * rsqrt(fast::max(dot(_8373, _8373), 1.0000000133514319600180897396058e-10)), _6573) + 1.0;
                int _8415 = _8352 + 3;
                float _8401 = ((_7313 * _6298.z) * ((0.25 * (_8383 * _8383)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_8415])[1u])).y > 0.5);
                int _8445 = _8352 + 1;
                int _8449 = _8352 + 2;
                float2 _8461 = float2(as_type<half2>(_1281._m0[_8352].y));
                float2 _8470 = float2(as_type<half2>(_1281._m0[_8445].x));
                float2 _8479 = float2(as_type<half2>(_1281._m0[_8445].w));
                float2 _8488 = float2(as_type<half2>(_1281._m0[_8449].z));
                float3 _8576 = (((((((float3(float2(as_type<half2>(_1281._m0[_8352].x)), _8461.x) * 0.2820949852466583251953125) + (float3(_8461.y, float2(as_type<half2>(_1281._m0[_8352].z))) * _6653)) + (float3(float2(as_type<half2>(_1281._m0[_8352].w)), _8470.x) * _6656)) + (float3(_8470.y, float2(as_type<half2>(_1281._m0[_8445].y))) * _6659)) + (float3(float2(as_type<half2>(_1281._m0[_8445].z)), _8479.x) * _6667)) + (float3(_8479.y, float2(as_type<half2>(_1281._m0[_8449].x))) * _6673)) + (float3(float2(as_type<half2>(_1281._m0[_8449].y)), _8488.x) * _6681)) + (float3(_8488.y, float2(as_type<half2>(_1281._m0[_8449].w))) * _6687);
                int3 _8604 = min((_6294 + int3(1)), _6720);
                int _8621 = _6550 + ((_8604.x + (_6726 * (_8604.y + (_6730 * _8604.z)))) * 4);
                float3 _8642 = (((((float3(_8604) + float3(0.5)) / _6246) * _6235) * 2.0) - _6235) - _6473;
                float _8652 = dot(_8642 * rsqrt(fast::max(dot(_8642, _8642), 1.0000000133514319600180897396058e-10)), _6573) + 1.0;
                int _8684 = _8621 + 3;
                float _8670 = ((_7582 * _6298.z) * ((0.25 * (_8652 * _8652)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_8684])[1u])).y > 0.5);
                int _8714 = _8621 + 1;
                int _8718 = _8621 + 2;
                float2 _8730 = float2(as_type<half2>(_1281._m0[_8621].y));
                float2 _8739 = float2(as_type<half2>(_1281._m0[_8714].x));
                float2 _8748 = float2(as_type<half2>(_1281._m0[_8714].w));
                float2 _8757 = float2(as_type<half2>(_1281._m0[_8718].z));
                float3 _8845 = (((((((float3(float2(as_type<half2>(_1281._m0[_8621].x)), _8730.x) * 0.2820949852466583251953125) + (float3(_8730.y, float2(as_type<half2>(_1281._m0[_8621].z))) * _6653)) + (float3(float2(as_type<half2>(_1281._m0[_8621].w)), _8739.x) * _6656)) + (float3(_8739.y, float2(as_type<half2>(_1281._m0[_8714].y))) * _6659)) + (float3(float2(as_type<half2>(_1281._m0[_8714].z)), _8748.x) * _6667)) + (float3(_8748.y, float2(as_type<half2>(_1281._m0[_8718].x))) * _6673)) + (float3(float2(as_type<half2>(_1281._m0[_8718].y)), _8757.x) * _6681)) + (float3(_8757.y, float2(as_type<half2>(_1281._m0[_8718].w))) * _6687);
                float4 _6404 = ((_6365 + float4((_8307 + (float3(float2(as_type<half2>(_1281._m0[_8146].x)), float2(as_type<half2>(_1281._m0[_8146].y)).x) * _6701)) * _8132, _8132)) + float4((_8576 + (float3(float2(as_type<half2>(_1281._m0[_8415].x)), float2(as_type<half2>(_1281._m0[_8415].y)).x) * _6701)) * _8401, _8401)) + float4((_8845 + (float3(float2(as_type<half2>(_1281._m0[_8684].x)), float2(as_type<half2>(_1281._m0[_8684].y)).x) * _6701)) * _8670, _8670);
                float _6408 = _6404.w;
                float3 _17545;
                if (_6408 > 9.9999997473787516355514526367188e-06)
                {
                    _17545 = mix(_17249, (fast::max(_6404.xyz, float3(0.0)) / float3(_6408)) * _6544.z, float3(_17507));
                }
                else
                {
                    _17545 = _17249;
                }
                _17544 = _17545;
            }
            _17250 = _17249;
        }
        else
        {
            _17250 = _17245;
        }
        float3 _3801 = (_16698 * ((_17250 * _17023) + ((_3695 * fast::max(_3735, 0.0)) * _16738))) + ((_3695 * ((powr(fast::max(dot(_16704, _3658), 0.0), _2876._m1.w) * _2876._m1.z) * step(0.0, _3735))) * _16738);
        float3 _17265;
        if (_283._m13.w > 0.5)
        {
            float2 _8883 = fast::clamp(floor(gl_FragCoord.xy * _283._m12.xy), float2(0.0), _283._m13.xy - float2(1.0));
            uint _8911 = uint((((fast::clamp(floor((log2(fast::max(dot(_283._m11.xyz, in.m_3037) + _283._m11.w, 9.9999999747524270787835121154785e-07)) * _283._m12.z) + _283._m12.w), 0.0, _283._m13.z - 1.0) * _283._m13.y) + _8883.y) * _283._m13.x) + _8883.x);
            uint _8913 = _8911 >> uint(2);
            uint _8915 = _8911 & 3u;
            uint _8919 = _3167._m0[_8913][_8915] & 65535u;
            uint _8921 = _3167._m0[_8913][_8915] >> uint(16);
            float3 _17266;
            _17266 = _3801;
            float3 _3881;
            spvUnsafeArray<float2, 3> _9329;
            spvUnsafeArray<float2, 3> _9330;
            spvUnsafeArray<float2, 3> _9542;
            spvUnsafeArray<float2, 3> _9543;
            for (uint _17263 = _8919; _17263 < (_8919 + _8921); _17266 = _3881, _17263++)
            {
                uint _8927 = _17263 / 3u;
                uint _8940 = (_3188._m0[_8927 >> uint(2)][_8927 & 3u] >> ((_17263 - (_8927 * 3u)) * 10u)) & 1023u;
                float3 _8957 = _3030._m0[_8940].xyz - in.m_3037;
                float _8960 = dot(_8957, _8957);
                float _8964 = _8960 * _3030._m0[_8940].w;
                float _8969 = fast::clamp(1.0 - (_8964 * _8964), 0.0, 1.0);
                float3 _8974 = _8957 * rsqrt(fast::max(_8960, 9.9999999392252902907785028219223e-09));
                float _8992 = fast::clamp((dot(-_8974, _3073._m0[_8940].xyz) * _3065._m0[_8940].w) + _3073._m0[_8940].w, 0.0, 1.0);
                float3 _9005 = _3065._m0[_8940].xyz * ((((_8969 * _8969) * _8992) * _8992) / fast::max(_8960, 9.9999997473787516355514526367188e-05));
                float3 _17472;
                if (_3669)
                {
                    float _17418;
                    do
                    {
                        uint _9041 = uint(_283._m21.z);
                        if (_8940 < _9041)
                        {
                            float _9063 = _283._m26[_8940].z * fast::max((_283._m15[_8940] * float4(in.m_3037, 1.0)).w, 0.0);
                            float4 _9087 = _283._m15[_8940] * float4((in.m_3037 + (_3664 * (_9063 * _283._m25.x))) + (_8974 * (_9063 * _283._m25.y)), 1.0);
                            float _9089 = _9087.w;
                            if (_9089 <= 0.0)
                            {
                                _17418 = 1.0;
                                break;
                            }
                            float3 _9098 = _9087.xyz / float3(_9089);
                            float _9100 = _9098.x;
                            bool _9101 = _9100 < 0.0;
                            bool _9108;
                            if (!_9101)
                            {
                                _9108 = _9100 > 1.0;
                            }
                            else
                            {
                                _9108 = _9101;
                            }
                            bool _9115;
                            if (!_9108)
                            {
                                _9115 = _9098.y < 0.0;
                            }
                            else
                            {
                                _9115 = _9108;
                            }
                            bool _9122;
                            if (!_9115)
                            {
                                _9122 = _9098.y > 1.0;
                            }
                            else
                            {
                                _9122 = _9115;
                            }
                            bool _9129;
                            if (!_9122)
                            {
                                _9129 = _9098.z > 1.0;
                            }
                            else
                            {
                                _9129 = _9122;
                            }
                            if (_9129)
                            {
                                _17418 = 1.0;
                                break;
                            }
                            float _9135 = _9098.z;
                            float2 _9301 = _283._m22.xy * 0.5;
                            float2 _9306 = _283._m26[_8940].xy + (_9098.xy * _283._m23.zw);
                            float4 _9319 = float4(_283._m26[_8940].xy + _9301, (_283._m26[_8940].xy + _283._m23.zw) - _9301);
                            float _17417;
                            do
                            {
                                int _9345 = int(_283._m22.z);
                                if (_9345 <= 0)
                                {
                                    float2 _9355 = fast::clamp(_9306, _9319.xy, _9319.zw);
                                    _17417 = spvDepthCast(_303).sample_compare(_303Smplr, float3(_9355, _9135).xy, _9135);
                                    break;
                                }
                                float2 _9368 = (_9306 / _283._m22.xy) + float2(0.5);
                                float2 _9369 = floor(_9368);
                                float2 _9374 = _9368 - _9369;
                                float2 _9377 = _9369 - float2(0.5);
                                bool _9381 = _9345 == 1;
                                if (_9381)
                                {
                                    float2 _9384 = _9374 * 2.0;
                                    _9329[0] = float2(3.0) - _9384;
                                    _9329[1] = float2(1.0) + _9384;
                                    _9330[0] = ((float2(2.0) - _9374) / _9329[0]) - float2(1.0);
                                    _9330[1] = (_9374 / _9329[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _9411 = _9374 * 3.0;
                                    _9329[0] = float2(4.0) - _9411;
                                    _9329[1] = float2(7.0);
                                    _9329[2] = float2(1.0) + _9411;
                                    _9330[0] = ((float2(3.0) - (_9374 * 2.0)) / _9329[0]) - float2(2.0);
                                    _9330[1] = (float2(3.0) + _9374) / _9329[1];
                                    _9330[2] = (_9374 / _9329[2]) + float2(2.0);
                                }
                                int _17664 = _9381 ? 2 : 3;
                                int _17407;
                                float _17410;
                                _17410 = 0.0;
                                _17407 = 0;
                                float _17416;
                                for (; _17407 < _17664; _17410 = _17416, _17407++)
                                {
                                    _17416 = _17410;
                                    for (int _17413 = 0; _17413 < _17664; )
                                    {
                                        _17416 += ((_9329[_17413].x * _9329[_17407].y) * spvDepthCast(_303).sample_compare(_303Smplr, float3(fast::clamp(_283._m22.xy * (_9377 + float2(_9330[_17413].x, _9330[_17407].y)), _9319.xy, _9319.zw), _9135).xy, _9135));
                                        _17413++;
                                        continue;
                                    }
                                }
                                _17417 = _17410 * (_9381 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _17418 = _17417;
                            break;
                        }
                        uint _9145 = _8940 - _9041;
                        if (_9145 >= uint(_283._m21.w))
                        {
                            _17418 = 1.0;
                            break;
                        }
                        float _9166 = _283._m27[_9145].w * length(in.m_3037 - _283._m27[_9145].xyz);
                        float3 _9184 = ((in.m_3037 + (_3664 * (_9166 * _283._m25.x))) + (_8974 * (_9166 * _283._m25.y))) - _283._m27[_9145].xyz;
                        float3 _9186 = abs(_9184);
                        float _9188 = _9186.x;
                        float _9190 = _9186.y;
                        bool _9191 = _9188 >= _9190;
                        bool _9199;
                        if (_9191)
                        {
                            _9199 = _9188 >= _9186.z;
                        }
                        else
                        {
                            _9199 = _9191;
                        }
                        float _17392;
                        int _17394;
                        if (_9199)
                        {
                            _17394 = (_9184.x > 0.0) ? 0 : 1;
                            _17392 = _9188;
                        }
                        else
                        {
                            float _9211 = _9186.z;
                            bool _9212 = _9190 >= _9211;
                            int _17395;
                            if (_9212)
                            {
                                _17395 = (_9184.y > 0.0) ? 2 : 3;
                            }
                            else
                            {
                                _17395 = (_9184.z > 0.0) ? 4 : 5;
                            }
                            _17394 = _17395;
                            _17392 = _9212 ? _9190 : _9211;
                        }
                        if (_17392 <= 0.0)
                        {
                            _17418 = 1.0;
                            break;
                        }
                        float2 _9249 = float2(dot(_9184, _961[_17394]), dot(_9184, _970[_17394])) / float2(_17392 * _283._m24.z);
                        float _9256 = _283._m28[_9145].z + (_283._m28[_9145].w / _17392);
                        if (_9256 > 1.0)
                        {
                            _17418 = 1.0;
                            break;
                        }
                        float2 _9274 = _283._m28[_9145].xy + (float2(float(spvSMod(_17394, 3)), float(_17394 / 3)) * _283._m24.xy);
                        float2 _9514 = _283._m22.xy * 0.5;
                        float2 _9519 = _9274 + (float2(0.5 + (0.5 * _9249.x), 0.5 - (0.5 * _9249.y)) * _283._m24.xy);
                        float4 _9532 = float4(_9274 + _9514, (_9274 + _283._m24.xy) - _9514);
                        float _17406;
                        do
                        {
                            int _9558 = int(_283._m22.z);
                            if (_9558 <= 0)
                            {
                                _17406 = spvDepthCast(_303).sample_compare(_303Smplr, float3(fast::clamp(_9519, _9532.xy, _9532.zw), _9256).xy, _9256);
                                break;
                            }
                            float2 _9581 = (_9519 / _283._m22.xy) + float2(0.5);
                            float2 _9582 = floor(_9581);
                            float2 _9587 = _9581 - _9582;
                            float2 _9590 = _9582 - float2(0.5);
                            bool _9594 = _9558 == 1;
                            if (_9594)
                            {
                                float2 _9597 = _9587 * 2.0;
                                _9542[0] = float2(3.0) - _9597;
                                _9542[1] = float2(1.0) + _9597;
                                _9543[0] = ((float2(2.0) - _9587) / _9542[0]) - float2(1.0);
                                _9543[1] = (_9587 / _9542[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _9624 = _9587 * 3.0;
                                _9542[0] = float2(4.0) - _9624;
                                _9542[1] = float2(7.0);
                                _9542[2] = float2(1.0) + _9624;
                                _9543[0] = ((float2(3.0) - (_9587 * 2.0)) / _9542[0]) - float2(2.0);
                                _9543[1] = (float2(3.0) + _9587) / _9542[1];
                                _9543[2] = (_9587 / _9542[2]) + float2(2.0);
                            }
                            int _17667 = _9594 ? 2 : 3;
                            int _17396;
                            float _17399;
                            _17399 = 0.0;
                            _17396 = 0;
                            float _17405;
                            for (; _17396 < _17667; _17399 = _17405, _17396++)
                            {
                                _17405 = _17399;
                                for (int _17402 = 0; _17402 < _17667; )
                                {
                                    _17405 += ((_9542[_17402].x * _9542[_17396].y) * spvDepthCast(_303).sample_compare(_303Smplr, float3(fast::clamp(_283._m22.xy * (_9590 + float2(_9543[_17402].x, _9543[_17396].y)), _9532.xy, _9532.zw), _9256).xy, _9256));
                                    _17402++;
                                    continue;
                                }
                            }
                            _17406 = _17399 * (_9594 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _17418 = _17406;
                        break;
                    } while(false);
                    _17472 = _9005 * _17418;
                }
                else
                {
                    _17472 = _9005;
                }
                float _3852 = dot(_16704, _8974);
                _3881 = _17266 + (((_16698 * fast::max(_3852, 0.0)) * _17472) + (_17472 * ((powr(fast::max(dot(_16704, fast::normalize(_8974 + _3653)), 0.0), _2876._m1.w) * _2876._m1.z) * step(0.0, _3852))));
            }
            _17265 = _17266;
        }
        else
        {
            _17265 = _3801;
        }
        _17334 = _17250;
        _17264 = _17265;
    }
    else
    {
        float4 _3891 = _3886.sample(_2533, _3419);
        float _3902 = fast::clamp((_2876._m4.x * _3891.z) * in.m_3898.y, 0.0, 1.0);
        float _3913 = fast::clamp((_2876._m4.y * _3891.y) * in.m_3898.x, 0.04500000178813934326171875, 1.0);
        float _16694;
        float _16699;
        if (_16635 > 0.0)
        {
            _16699 = mix(_3902, _16668.y, _16635);
            _16694 = mix(_3913, fast::max(_16668.x, 0.04500000178813934326171875), _16635);
        }
        else
        {
            _16699 = _3902;
            _16694 = _3913;
        }
        float _3932 = _16694 * _16694;
        float3 _3937 = _16698 * (1.0 - _16699);
        float3 _3943 = mix(float3(0.039999999105930328369140625), _16698, float3(_16699));
        bool _3947 = _16514 > 0.0;
        float3 _16727;
        if (_3947)
        {
            float3 _3952 = dfdx(in.m_3037);
            float3 _3954 = dfdy(in.m_3037);
            float3 _3955 = cross(_3952, _3954);
            float3 _16728;
            if (dot(_3955, _3955) > 9.9999996826552253889678874634872e-21)
            {
                _16728 = fast::normalize((fast::normalize(_3955) * ((dot(_3955, _3653) < 0.0) ? (-1.0) : 1.0)) + (_16704 - _3509));
            }
            else
            {
                _16728 = _16704;
            }
            _16727 = _16728;
        }
        else
        {
            _16727 = _16704;
        }
        float _3981 = fast::max(dot(_16727, _3653), 9.9999997473787516355514526367188e-05);
        float _3990 = dot(_16727, _3646);
        float _3991 = fast::clamp(_3990, 0.0, 1.0);
        float _3996 = fast::clamp(dot(_16727, _3658), 0.0, 1.0);
        float _4001 = fast::clamp(dot(_3653, _3658), 0.0, 1.0);
        float _16731;
        float _16732;
        if (_3947)
        {
            _16732 = fast::max(_3981, 0.5);
            _16731 = fast::max(_4001, 0.5);
        }
        else
        {
            _16732 = _3981;
            _16731 = _4001;
        }
        float3 _9726 = float3(1.0) - _3943;
        float3 _9729 = _3943 + (_9726 * powr(1.0 - _16731, 5.0));
        float _9736 = _3932 * _3932;
        float _9741 = _9736 - 1.0;
        float _9743 = ((_3996 * _3996) * _9741) + 1.0;
        float _9763 = 1.0 - _9736;
        float _9767 = sqrt(((_16732 * _16732) * _9763) + _9736);
        float3 _4047 = (((((float3(1.0) - _9729) * _3937) * fast::clamp(dot(_16704, _3646), 0.0, 1.0)) + (((_9729 * ((_9736 / ((3.1415927410125732421875 * _9743) * _9743)) * (0.5 / fast::max((_3991 * _9767) + (_16732 * sqrt(((_3991 * _3991) * _9763) + _9736)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875) * _3991)) * _3695) * _16738;
        float3 _17060;
        if (_3947)
        {
            _17060 = _4047 + (((((_3937 * _3695) * _16738) * _16514) * fast::clamp(-_3990, 0.0, 1.0)) * (0.3499999940395355224609375 + (0.64999997615814208984375 * powr(fast::clamp(dot(-_3653, _3646), 0.0, 1.0), 3.0))));
        }
        else
        {
            _17060 = _4047;
        }
        float3 _16767;
        float3 _16794;
        float2 _16971;
        if (_283._m29.x > 0.5)
        {
            float4 _9800 = _2632.sample(_2634, (((float2(_16732, _16694) * 31.0) + float2(0.5)) * float2(0.03125)));
            float _9859 = (_283._m29.z * _16704.x) - (_283._m29.w * _16704.z);
            float _9872 = (_283._m29.w * _16704.x) + (_283._m29.z * _16704.z);
            float _9890 = 1.09254801273345947265625 * _9859;
            spvUnsafeArray<float, 9> _15362 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _16704.y, 0.48860299587249755859375 * _9872, 0.48860299587249755859375 * _9859, _9890 * _16704.y, (1.09254801273345947265625 * _16704.y) * _9872, 0.3153919875621795654296875 * (((3.0 * _9872) * _9872) - 1.0), _9890 * _9872, 0.546274006366729736328125 * ((_9859 * _9859) - (_16704.y * _16704.y)) });
            spvUnsafeArray<float, 9> _9804 = _15362;
            float3 _16750;
            _16750 = float3(0.0);
            for (int _16749 = 0; _16749 < 9; )
            {
                _16750 += (_2531.read(uint2((int2(496, 256) + int2(_16749, 0))), 0).xyz * _9804[_16749]);
                _16749++;
                continue;
            }
            float3 _4099 = reflect(-_3653, _16727);
            float _9985 = _4099.x;
            float _9990 = _4099.z;
            float2 _10022 = float2((precise::atan2((_283._m29.z * _9985) - (_283._m29.w * _9990), -((_283._m29.w * _9985) + (_283._m29.z * _9990))) * 0.15915493667125701904296875) + 0.5, acos(fast::clamp(_4099.y, -1.0, 1.0)) * 0.3183098733425140380859375);
            float _9954 = _16694 * 5.0;
            int _9957 = min(int(_9954), 4);
            float2 _10043 = (_10022 * float2(_2588[_9957].zw)) - float2(0.5);
            float2 _10045 = floor(_10043);
            float2 _10048 = _10043 - _10045;
            int _10051 = int(_10045.x);
            int _10054 = int(_10045.y);
            int _16753;
            if (_10051 < 0)
            {
                _16753 = _10051 + _2588[_9957].z;
            }
            else
            {
                _16753 = _10051;
            }
            int _16754;
            if (_16753 >= _2588[_9957].z)
            {
                _16754 = _16753 - _2588[_9957].z;
            }
            else
            {
                _16754 = _16753;
            }
            int _10074 = _16754 + 1;
            int _17668 = (_10074 == _2588[_9957].z) ? 0 : _10074;
            int _10089 = min((_10054 + 1), (_2588[_9957].w - 1));
            int _10091 = max(_10054, 0);
            float3 _10144 = float3(_10048.x);
            int _9964 = _9957 + 1;
            float2 _10176 = (_10022 * float2(_2588[_9964].zw)) - float2(0.5);
            float2 _10178 = floor(_10176);
            float2 _10181 = _10176 - _10178;
            int _10184 = int(_10178.x);
            int _10187 = int(_10178.y);
            int _16760;
            if (_10184 < 0)
            {
                _16760 = _10184 + _2588[_9964].z;
            }
            else
            {
                _16760 = _10184;
            }
            int _16761;
            if (_16760 >= _2588[_9964].z)
            {
                _16761 = _16760 - _2588[_9964].z;
            }
            else
            {
                _16761 = _16760;
            }
            int _10207 = _16761 + 1;
            int _17669 = (_10207 == _2588[_9964].z) ? 0 : _10207;
            int _10222 = min((_10187 + 1), (_2588[_9964].w - 1));
            int _10224 = max(_10187, 0);
            float3 _10277 = float3(_10181.x);
            float3 _9979 = mix(mix(mix(_2531.read(uint2((_2588[_9957].xy + int2(_16754, _10091))), 0).xyz, _2531.read(uint2((_2588[_9957].xy + int2(_17668, _10091))), 0).xyz, _10144), mix(_2531.read(uint2((_2588[_9957].xy + int2(_16754, _10089))), 0).xyz, _2531.read(uint2((_2588[_9957].xy + int2(_17668, _10089))), 0).xyz, _10144), float3(_10048.y)), mix(mix(_2531.read(uint2((_2588[_9964].xy + int2(_16761, _10224))), 0).xyz, _2531.read(uint2((_2588[_9964].xy + int2(_17669, _10224))), 0).xyz, _10277), mix(_2531.read(uint2((_2588[_9964].xy + int2(_16761, _10222))), 0).xyz, _2531.read(uint2((_2588[_9964].xy + int2(_17669, _10222))), 0).xyz, _10277), float3(_10181.y)), float3(_9954 - float(_9957))) * _283._m29.y;
            _16971 = _9800.xy;
            _16794 = _9979;
            _16767 = fast::max(_16750, float3(0.0)) * _283._m29.y;
        }
        else
        {
            float4 _10295 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * _16694) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);
            float _10297 = _10295.x;
            float3 _10332 = mix(_283._m9.xyz, _283._m8.xyz, float3((_16704.y * 0.5) + 0.5)) * _283._m8.w;
            _16971 = (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_10297 * _10297, exp2((-9.27999973297119140625) * _16732)) * _10297) + _10295.y)) + _10295.zw;
            _16794 = mix(mix(_283._m9.xyz, _283._m8.xyz, float3((reflect(-_3653, _16727).y * 0.5) + 0.5)) * _283._m8.w, _10332, float3(_16694));
            _16767 = _10332;
        }
        float3 _16894;
        if (_283._m34.y > 0.5)
        {
            int _10469 = int(_283._m34.y);
            int _10472 = int(_283._m34.x);
            float3 _16783;
            _16783 = _16767;
            float3 _17514;
            for (int _16782 = 0; _16782 < _10469; _16783 = _17514, _16782++)
            {
                int _10484 = 8 * (_10472 + _16782);
                float4 _10693 = as_type<float4>(_1281._m0[_10484 + 3]);
                float4 _10737 = as_type<float4>(_1281._m0[_10484]);
                float4 _10743 = as_type<float4>(_1281._m0[_10484 + 1]);
                float4 _10749 = as_type<float4>(_1281._m0[_10484 + 2]);
                float3 _10711 = _10737.xyz;
                float _10715 = _10737.w;
                float3 _10718 = _10743.xyz;
                float _10722 = _10743.w;
                float3 _10725 = _10749.xyz;
                float _10729 = _10749.w;
                float3 _10731 = float3(dot(_10711, in.m_3037) + _10715, dot(_10718, in.m_3037) + _10722, dot(_10725, in.m_3037) + _10729);
                float3 _10493 = _10693.xyz;
                float _10495 = _10693.w;
                float _17238;
                do
                {
                    float3 _10761 = _10493 - abs(_10731);
                    float _10769 = fast::min(_10761.x, fast::min(_10761.y, _10761.z));
                    if (_10769 <= 0.0)
                    {
                        _17238 = 0.0;
                        break;
                    }
                    if (_10495 <= 0.0)
                    {
                        _17238 = 1.0;
                        break;
                    }
                    float _10781 = fast::min(_10769 / _10495, 1.0);
                    _17238 = (_10781 * _10781) * (3.0 - (2.0 * _10781));
                    break;
                } while(false);
                if (_17238 <= 0.0)
                {
                    _17514 = _16783;
                    continue;
                }
                float3 _10504 = as_type<float4>(_1281._m0[_10484 + 4]).xyz;
                float4 _10802 = as_type<float4>(_1281._m0[_10484 + 5]);
                int _10808 = int(((device uint*)&_1281._m0[_10484 + 6])[0u]);
                float _10818 = dot(_10711, _16704);
                float _10824 = dot(_10718, _16704);
                float _10830 = dot(_10725, _16704);
                float3 _10831 = float3(_10818, _10824, _10830);
                float3 _10524 = (in.m_3037 + (_16704 * _10802.x)) + (_3653 * _10802.y);
                float3 _10543 = fast::clamp((((float3(dot(_10711, _10524) + _10715, dot(_10718, _10524) + _10722, dot(_10725, _10524) + _10729) + _10493) / fast::max(_10493 * 2.0, float3(9.9999999747524270787835121154785e-07))) * _10504) - float3(0.5), float3(0.0), _10504 - float3(1.0));
                int3 _10545 = int3(_10504);
                int3 _10552 = min(int3(_10543), max((_10545 - int3(2)), int3(0)));
                float3 _10556 = _10543 - float3(_10552);
                float _10911 = 0.48860299587249755859375 * _10824;
                float _10914 = 0.48860299587249755859375 * _10830;
                float _10917 = 0.48860299587249755859375 * _10818;
                float _10922 = 1.09254801273345947265625 * _10818;
                float _10925 = _10922 * _10824;
                float _10931 = (1.09254801273345947265625 * _10824) * _10830;
                float _10939 = 0.3153919875621795654296875 * (((3.0 * _10830) * _10830) - 1.0);
                float _10945 = _10922 * _10830;
                float _10959 = 0.546274006366729736328125 * ((_10818 * _10818) - (_10824 * _10824));
                int3 _10978 = _10545 - int3(1);
                int3 _10979 = min(_10552, _10978);
                int _10984 = _10545.x;
                int _10988 = _10545.y;
                int _10996 = _10808 + ((_10979.x + (_10984 * (_10979.y + (_10988 * _10979.z)))) * 4);
                float3 _10999 = float3(1.0) - _10556;
                float3 _11017 = (((((float3(_10979) + float3(0.5)) / _10504) * _10493) * 2.0) - _10493) - _10731;
                float _11027 = dot(_11017 * rsqrt(fast::max(dot(_11017, _11017), 1.0000000133514319600180897396058e-10)), _10831) + 1.0;
                float _11030 = _10999.x;
                float _11032 = _10999.y;
                float _11033 = _11030 * _11032;
                float _11035 = _10999.z;
                int _11059 = _10996 + 3;
                float _11045 = ((_11033 * _11035) * ((0.25 * (_11027 * _11027)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_11059])[1u])).y > 0.5);
                int _11089 = _10996 + 1;
                int _11093 = _10996 + 2;
                float2 _11105 = float2(as_type<half2>(_1281._m0[_10996].y));
                float2 _11114 = float2(as_type<half2>(_1281._m0[_11089].x));
                float2 _11123 = float2(as_type<half2>(_1281._m0[_11089].w));
                float2 _11132 = float2(as_type<half2>(_1281._m0[_11093].z));
                float3 _11220 = (((((((float3(float2(as_type<half2>(_1281._m0[_10996].x)), _11105.x) * 0.2820949852466583251953125) + (float3(_11105.y, float2(as_type<half2>(_1281._m0[_10996].z))) * _10911)) + (float3(float2(as_type<half2>(_1281._m0[_10996].w)), _11114.x) * _10914)) + (float3(_11114.y, float2(as_type<half2>(_1281._m0[_11089].y))) * _10917)) + (float3(float2(as_type<half2>(_1281._m0[_11089].z)), _11123.x) * _10925)) + (float3(_11123.y, float2(as_type<half2>(_1281._m0[_11093].x))) * _10931)) + (float3(float2(as_type<half2>(_1281._m0[_11093].y)), _11132.x) * _10939)) + (float3(_11132.y, float2(as_type<half2>(_1281._m0[_11093].w))) * _10945);
                int3 _11248 = min((_10552 + int3(1, 0, 0)), _10978);
                int _11265 = _10808 + ((_11248.x + (_10984 * (_11248.y + (_10988 * _11248.z)))) * 4);
                float3 _11286 = (((((float3(_11248) + float3(0.5)) / _10504) * _10493) * 2.0) - _10493) - _10731;
                float _11296 = dot(_11286 * rsqrt(fast::max(dot(_11286, _11286), 1.0000000133514319600180897396058e-10)), _10831) + 1.0;
                float _11302 = _10556.x * _11032;
                int _11328 = _11265 + 3;
                float _11314 = ((_11302 * _11035) * ((0.25 * (_11296 * _11296)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_11328])[1u])).y > 0.5);
                int _11358 = _11265 + 1;
                int _11362 = _11265 + 2;
                float2 _11374 = float2(as_type<half2>(_1281._m0[_11265].y));
                float2 _11383 = float2(as_type<half2>(_1281._m0[_11358].x));
                float2 _11392 = float2(as_type<half2>(_1281._m0[_11358].w));
                float2 _11401 = float2(as_type<half2>(_1281._m0[_11362].z));
                float3 _11489 = (((((((float3(float2(as_type<half2>(_1281._m0[_11265].x)), _11374.x) * 0.2820949852466583251953125) + (float3(_11374.y, float2(as_type<half2>(_1281._m0[_11265].z))) * _10911)) + (float3(float2(as_type<half2>(_1281._m0[_11265].w)), _11383.x) * _10914)) + (float3(_11383.y, float2(as_type<half2>(_1281._m0[_11358].y))) * _10917)) + (float3(float2(as_type<half2>(_1281._m0[_11358].z)), _11392.x) * _10925)) + (float3(_11392.y, float2(as_type<half2>(_1281._m0[_11362].x))) * _10931)) + (float3(float2(as_type<half2>(_1281._m0[_11362].y)), _11401.x) * _10939)) + (float3(_11401.y, float2(as_type<half2>(_1281._m0[_11362].w))) * _10945);
                int3 _11517 = min((_10552 + int3(0, 1, 0)), _10978);
                int _11534 = _10808 + ((_11517.x + (_10984 * (_11517.y + (_10988 * _11517.z)))) * 4);
                float3 _11555 = (((((float3(_11517) + float3(0.5)) / _10504) * _10493) * 2.0) - _10493) - _10731;
                float _11565 = dot(_11555 * rsqrt(fast::max(dot(_11555, _11555), 1.0000000133514319600180897396058e-10)), _10831) + 1.0;
                float _11571 = _11030 * _10556.y;
                int _11597 = _11534 + 3;
                float _11583 = ((_11571 * _11035) * ((0.25 * (_11565 * _11565)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_11597])[1u])).y > 0.5);
                int _11627 = _11534 + 1;
                int _11631 = _11534 + 2;
                float2 _11643 = float2(as_type<half2>(_1281._m0[_11534].y));
                float2 _11652 = float2(as_type<half2>(_1281._m0[_11627].x));
                float2 _11661 = float2(as_type<half2>(_1281._m0[_11627].w));
                float2 _11670 = float2(as_type<half2>(_1281._m0[_11631].z));
                float3 _11758 = (((((((float3(float2(as_type<half2>(_1281._m0[_11534].x)), _11643.x) * 0.2820949852466583251953125) + (float3(_11643.y, float2(as_type<half2>(_1281._m0[_11534].z))) * _10911)) + (float3(float2(as_type<half2>(_1281._m0[_11534].w)), _11652.x) * _10914)) + (float3(_11652.y, float2(as_type<half2>(_1281._m0[_11627].y))) * _10917)) + (float3(float2(as_type<half2>(_1281._m0[_11627].z)), _11661.x) * _10925)) + (float3(_11661.y, float2(as_type<half2>(_1281._m0[_11631].x))) * _10931)) + (float3(float2(as_type<half2>(_1281._m0[_11631].y)), _11670.x) * _10939)) + (float3(_11670.y, float2(as_type<half2>(_1281._m0[_11631].w))) * _10945);
                int3 _11786 = min((_10552 + int3(1, 1, 0)), _10978);
                int _11803 = _10808 + ((_11786.x + (_10984 * (_11786.y + (_10988 * _11786.z)))) * 4);
                float3 _11824 = (((((float3(_11786) + float3(0.5)) / _10504) * _10493) * 2.0) - _10493) - _10731;
                float _11834 = dot(_11824 * rsqrt(fast::max(dot(_11824, _11824), 1.0000000133514319600180897396058e-10)), _10831) + 1.0;
                float _11840 = _10556.x * _10556.y;
                int _11866 = _11803 + 3;
                float _11852 = ((_11840 * _11035) * ((0.25 * (_11834 * _11834)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_11866])[1u])).y > 0.5);
                int _11896 = _11803 + 1;
                int _11900 = _11803 + 2;
                float2 _11912 = float2(as_type<half2>(_1281._m0[_11803].y));
                float2 _11921 = float2(as_type<half2>(_1281._m0[_11896].x));
                float2 _11930 = float2(as_type<half2>(_1281._m0[_11896].w));
                float2 _11939 = float2(as_type<half2>(_1281._m0[_11900].z));
                float3 _12027 = (((((((float3(float2(as_type<half2>(_1281._m0[_11803].x)), _11912.x) * 0.2820949852466583251953125) + (float3(_11912.y, float2(as_type<half2>(_1281._m0[_11803].z))) * _10911)) + (float3(float2(as_type<half2>(_1281._m0[_11803].w)), _11921.x) * _10914)) + (float3(_11921.y, float2(as_type<half2>(_1281._m0[_11896].y))) * _10917)) + (float3(float2(as_type<half2>(_1281._m0[_11896].z)), _11930.x) * _10925)) + (float3(_11930.y, float2(as_type<half2>(_1281._m0[_11900].x))) * _10931)) + (float3(float2(as_type<half2>(_1281._m0[_11900].y)), _11939.x) * _10939)) + (float3(_11939.y, float2(as_type<half2>(_1281._m0[_11900].w))) * _10945);
                int3 _12055 = min((_10552 + int3(0, 0, 1)), _10978);
                int _12072 = _10808 + ((_12055.x + (_10984 * (_12055.y + (_10988 * _12055.z)))) * 4);
                float3 _12093 = (((((float3(_12055) + float3(0.5)) / _10504) * _10493) * 2.0) - _10493) - _10731;
                float _12103 = dot(_12093 * rsqrt(fast::max(dot(_12093, _12093), 1.0000000133514319600180897396058e-10)), _10831) + 1.0;
                int _12135 = _12072 + 3;
                float _12121 = ((_11033 * _10556.z) * ((0.25 * (_12103 * _12103)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_12135])[1u])).y > 0.5);
                int _12165 = _12072 + 1;
                int _12169 = _12072 + 2;
                float2 _12181 = float2(as_type<half2>(_1281._m0[_12072].y));
                float2 _12190 = float2(as_type<half2>(_1281._m0[_12165].x));
                float2 _12199 = float2(as_type<half2>(_1281._m0[_12165].w));
                float2 _12208 = float2(as_type<half2>(_1281._m0[_12169].z));
                float3 _12296 = (((((((float3(float2(as_type<half2>(_1281._m0[_12072].x)), _12181.x) * 0.2820949852466583251953125) + (float3(_12181.y, float2(as_type<half2>(_1281._m0[_12072].z))) * _10911)) + (float3(float2(as_type<half2>(_1281._m0[_12072].w)), _12190.x) * _10914)) + (float3(_12190.y, float2(as_type<half2>(_1281._m0[_12165].y))) * _10917)) + (float3(float2(as_type<half2>(_1281._m0[_12165].z)), _12199.x) * _10925)) + (float3(_12199.y, float2(as_type<half2>(_1281._m0[_12169].x))) * _10931)) + (float3(float2(as_type<half2>(_1281._m0[_12169].y)), _12208.x) * _10939)) + (float3(_12208.y, float2(as_type<half2>(_1281._m0[_12169].w))) * _10945);
                float4 _10623 = (((float4((_11220 + (float3(float2(as_type<half2>(_1281._m0[_11059].x)), float2(as_type<half2>(_1281._m0[_11059].y)).x) * _10959)) * _11045, _11045) + float4((_11489 + (float3(float2(as_type<half2>(_1281._m0[_11328].x)), float2(as_type<half2>(_1281._m0[_11328].y)).x) * _10959)) * _11314, _11314)) + float4((_11758 + (float3(float2(as_type<half2>(_1281._m0[_11597].x)), float2(as_type<half2>(_1281._m0[_11597].y)).x) * _10959)) * _11583, _11583)) + float4((_12027 + (float3(float2(as_type<half2>(_1281._m0[_11866].x)), float2(as_type<half2>(_1281._m0[_11866].y)).x) * _10959)) * _11852, _11852)) + float4((_12296 + (float3(float2(as_type<half2>(_1281._m0[_12135].x)), float2(as_type<half2>(_1281._m0[_12135].y)).x) * _10959)) * _12121, _12121);
                int3 _12324 = min((_10552 + int3(1, 0, 1)), _10978);
                int _12341 = _10808 + ((_12324.x + (_10984 * (_12324.y + (_10988 * _12324.z)))) * 4);
                float3 _12362 = (((((float3(_12324) + float3(0.5)) / _10504) * _10493) * 2.0) - _10493) - _10731;
                float _12372 = dot(_12362 * rsqrt(fast::max(dot(_12362, _12362), 1.0000000133514319600180897396058e-10)), _10831) + 1.0;
                int _12404 = _12341 + 3;
                float _12390 = ((_11302 * _10556.z) * ((0.25 * (_12372 * _12372)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_12404])[1u])).y > 0.5);
                int _12434 = _12341 + 1;
                int _12438 = _12341 + 2;
                float2 _12450 = float2(as_type<half2>(_1281._m0[_12341].y));
                float2 _12459 = float2(as_type<half2>(_1281._m0[_12434].x));
                float2 _12468 = float2(as_type<half2>(_1281._m0[_12434].w));
                float2 _12477 = float2(as_type<half2>(_1281._m0[_12438].z));
                float3 _12565 = (((((((float3(float2(as_type<half2>(_1281._m0[_12341].x)), _12450.x) * 0.2820949852466583251953125) + (float3(_12450.y, float2(as_type<half2>(_1281._m0[_12341].z))) * _10911)) + (float3(float2(as_type<half2>(_1281._m0[_12341].w)), _12459.x) * _10914)) + (float3(_12459.y, float2(as_type<half2>(_1281._m0[_12434].y))) * _10917)) + (float3(float2(as_type<half2>(_1281._m0[_12434].z)), _12468.x) * _10925)) + (float3(_12468.y, float2(as_type<half2>(_1281._m0[_12438].x))) * _10931)) + (float3(float2(as_type<half2>(_1281._m0[_12438].y)), _12477.x) * _10939)) + (float3(_12477.y, float2(as_type<half2>(_1281._m0[_12438].w))) * _10945);
                int3 _12593 = min((_10552 + int3(0, 1, 1)), _10978);
                int _12610 = _10808 + ((_12593.x + (_10984 * (_12593.y + (_10988 * _12593.z)))) * 4);
                float3 _12631 = (((((float3(_12593) + float3(0.5)) / _10504) * _10493) * 2.0) - _10493) - _10731;
                float _12641 = dot(_12631 * rsqrt(fast::max(dot(_12631, _12631), 1.0000000133514319600180897396058e-10)), _10831) + 1.0;
                int _12673 = _12610 + 3;
                float _12659 = ((_11571 * _10556.z) * ((0.25 * (_12641 * _12641)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_12673])[1u])).y > 0.5);
                int _12703 = _12610 + 1;
                int _12707 = _12610 + 2;
                float2 _12719 = float2(as_type<half2>(_1281._m0[_12610].y));
                float2 _12728 = float2(as_type<half2>(_1281._m0[_12703].x));
                float2 _12737 = float2(as_type<half2>(_1281._m0[_12703].w));
                float2 _12746 = float2(as_type<half2>(_1281._m0[_12707].z));
                float3 _12834 = (((((((float3(float2(as_type<half2>(_1281._m0[_12610].x)), _12719.x) * 0.2820949852466583251953125) + (float3(_12719.y, float2(as_type<half2>(_1281._m0[_12610].z))) * _10911)) + (float3(float2(as_type<half2>(_1281._m0[_12610].w)), _12728.x) * _10914)) + (float3(_12728.y, float2(as_type<half2>(_1281._m0[_12703].y))) * _10917)) + (float3(float2(as_type<half2>(_1281._m0[_12703].z)), _12737.x) * _10925)) + (float3(_12737.y, float2(as_type<half2>(_1281._m0[_12707].x))) * _10931)) + (float3(float2(as_type<half2>(_1281._m0[_12707].y)), _12746.x) * _10939)) + (float3(_12746.y, float2(as_type<half2>(_1281._m0[_12707].w))) * _10945);
                int3 _12862 = min((_10552 + int3(1)), _10978);
                int _12879 = _10808 + ((_12862.x + (_10984 * (_12862.y + (_10988 * _12862.z)))) * 4);
                float3 _12900 = (((((float3(_12862) + float3(0.5)) / _10504) * _10493) * 2.0) - _10493) - _10731;
                float _12910 = dot(_12900 * rsqrt(fast::max(dot(_12900, _12900), 1.0000000133514319600180897396058e-10)), _10831) + 1.0;
                int _12942 = _12879 + 3;
                float _12928 = ((_11840 * _10556.z) * ((0.25 * (_12910 * _12910)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_12942])[1u])).y > 0.5);
                int _12972 = _12879 + 1;
                int _12976 = _12879 + 2;
                float2 _12988 = float2(as_type<half2>(_1281._m0[_12879].y));
                float2 _12997 = float2(as_type<half2>(_1281._m0[_12972].x));
                float2 _13006 = float2(as_type<half2>(_1281._m0[_12972].w));
                float2 _13015 = float2(as_type<half2>(_1281._m0[_12976].z));
                float3 _13103 = (((((((float3(float2(as_type<half2>(_1281._m0[_12879].x)), _12988.x) * 0.2820949852466583251953125) + (float3(_12988.y, float2(as_type<half2>(_1281._m0[_12879].z))) * _10911)) + (float3(float2(as_type<half2>(_1281._m0[_12879].w)), _12997.x) * _10914)) + (float3(_12997.y, float2(as_type<half2>(_1281._m0[_12972].y))) * _10917)) + (float3(float2(as_type<half2>(_1281._m0[_12972].z)), _13006.x) * _10925)) + (float3(_13006.y, float2(as_type<half2>(_1281._m0[_12976].x))) * _10931)) + (float3(float2(as_type<half2>(_1281._m0[_12976].y)), _13015.x) * _10939)) + (float3(_13015.y, float2(as_type<half2>(_1281._m0[_12976].w))) * _10945);
                float4 _10662 = ((_10623 + float4((_12565 + (float3(float2(as_type<half2>(_1281._m0[_12404].x)), float2(as_type<half2>(_1281._m0[_12404].y)).x) * _10959)) * _12390, _12390)) + float4((_12834 + (float3(float2(as_type<half2>(_1281._m0[_12673].x)), float2(as_type<half2>(_1281._m0[_12673].y)).x) * _10959)) * _12659, _12659)) + float4((_13103 + (float3(float2(as_type<half2>(_1281._m0[_12942].x)), float2(as_type<half2>(_1281._m0[_12942].y)).x) * _10959)) * _12928, _12928);
                float _10666 = _10662.w;
                float3 _17515;
                if (_10666 > 9.9999997473787516355514526367188e-06)
                {
                    _17515 = mix(_16783, (fast::max(_10662.xyz, float3(0.0)) / float3(_10666)) * _10802.z, float3(_17238));
                }
                else
                {
                    _17515 = _16783;
                }
                _17514 = _17515;
            }
            _16894 = _16783;
        }
        else
        {
            _16894 = _16767;
        }
        float3 _16916;
        if (_283._m34.x > 0.5)
        {
            float3 _4145 = reflect(-_3653, _16727);
            int _13151 = int(_283._m34.x);
            float _16806;
            float3 _16872;
            _16872 = float3(0.0);
            _16806 = 0.0;
            float _17525;
            float3 _17526;
            for (int _16805 = 0; _16805 < _13151; _16872 = _17526, _16806 = _17525, _16805++)
            {
                if (_16806 > 0.999000012874603271484375)
                {
                    break;
                }
                int _13163 = _16805 * 8;
                float4 _13278 = as_type<float4>(_1281._m0[_13163]);
                float4 _13284 = as_type<float4>(_1281._m0[_13163 + 1]);
                float4 _13290 = as_type<float4>(_1281._m0[_13163 + 2]);
                float3 _13252 = _13278.xyz;
                float3 _13259 = _13284.xyz;
                float3 _13266 = _13290.xyz;
                float3 _13272 = float3(dot(_13252, in.m_3037) + _13278.w, dot(_13259, in.m_3037) + _13284.w, dot(_13266, in.m_3037) + _13290.w);
                float4 _13296 = as_type<float4>(_1281._m0[_13163 + 3]);
                float _13174 = _13296.w;
                float _16807;
                do
                {
                    float3 _13308 = _13296.xyz - abs(_13272);
                    float _13316 = fast::min(_13308.x, fast::min(_13308.y, _13308.z));
                    if (_13316 <= 0.0)
                    {
                        _16807 = 0.0;
                        break;
                    }
                    if (_13174 <= 0.0)
                    {
                        _16807 = 1.0;
                        break;
                    }
                    float _13328 = fast::min(_13316 / _13174, 1.0);
                    _16807 = (_13328 * _13328) * (3.0 - (2.0 * _13328));
                    break;
                } while(false);
                if (_16807 <= 0.0)
                {
                    _17526 = _16872;
                    _17525 = _16806;
                    continue;
                }
                float4 _13343 = as_type<float4>(_1281._m0[_13163 + 4]);
                float4 _13349 = as_type<float4>(_1281._m0[_13163 + 5]);
                float3 _13372 = float3(dot(_13252, _4145), dot(_13259, _4145), dot(_13266, _4145));
                float3 _16809;
                if (_13343.w > 0.5)
                {
                    float3 _13196 = _13343.xyz;
                    float3 _13402 = -_13196;
                    float3 _13404 = fast::clamp(_13272, _13402, _13196);
                    float3 _13414 = step(float3(9.9999999747524270787835121154785e-07), abs(_13372));
                    float3 _13424 = mix(float3(1000000015047466219876688855040.0), (mix(_13402, _13196, step(float3(0.0), _13372)) - _13404) / mix(float3(9.9999999747524270787835121154785e-07), _13372, _13414), _13414);
                    float3 _13440 = (_13404 + (_13372 * fast::max(fast::min(_13424.x, fast::min(_13424.y, _13424.z)), 0.0))) - _13349.xyz;
                    float3 _16808;
                    if (dot(_13440, _13440) > 9.9999999600419720025001879548654e-13)
                    {
                        _16808 = fast::normalize(_13440);
                    }
                    else
                    {
                        _16808 = _13372;
                    }
                    _16809 = _16808;
                }
                else
                {
                    _16809 = _13372;
                }
                int _13457 = int(((device uint*)&_1281._m0[_13163 + 6])[0u]);
                float2 _13507 = float2((precise::atan2(_16809.x, -_16809.z) * 0.15915493667125701904296875) + 0.5, acos(fast::clamp(_16809.y, -1.0, 1.0)) * 0.3183098733425140380859375);
                float _13473 = _16694 * 5.0;
                int _13476 = min(int(_13473), 4);
                int _13547 = _13457 + _1353[_13476].x;
                float2 _13554 = (_13507 * float2(_1353[_13476].yz)) - float2(0.5);
                float2 _13556 = floor(_13554);
                float2 _13559 = _13554 - _13556;
                int _13562 = int(_13556.x);
                int _13565 = int(_13556.y);
                int _16810;
                if (_13562 < 0)
                {
                    _16810 = _13562 + _1353[_13476].y;
                }
                else
                {
                    _16810 = _13562;
                }
                int _16811;
                if (_16810 >= _1353[_13476].y)
                {
                    _16811 = _16810 - _1353[_13476].y;
                }
                else
                {
                    _16811 = _16810;
                }
                int _13585 = _16811 + 1;
                int _17670 = (_13585 == _1353[_13476].y) ? 0 : _13585;
                int _13653 = _13547 + (max(_13565, 0) * _1353[_13476].y);
                int _13655 = _13653 + _16811;
                int _13657 = _13655 >> 1;
                uint2 _16817;
                if ((_13655 & 1) == 0)
                {
                    _16817 = _1281._m0[_13657].xy;
                }
                else
                {
                    _16817 = _1281._m0[_13657].zw;
                }
                int _13693 = _13653 + _17670;
                int _13695 = _13693 >> 1;
                uint2 _16819;
                if ((_13693 & 1) == 0)
                {
                    _16819 = _1281._m0[_13695].xy;
                }
                else
                {
                    _16819 = _1281._m0[_13695].zw;
                }
                int _13729 = _13547 + (min((_13565 + 1), (_1353[_13476].z - 1)) * _1353[_13476].y);
                int _13731 = _13729 + _16811;
                int _13733 = _13731 >> 1;
                uint2 _16822;
                if ((_13731 & 1) == 0)
                {
                    _16822 = _1281._m0[_13733].xy;
                }
                else
                {
                    _16822 = _1281._m0[_13733].zw;
                }
                int _13769 = _13729 + _17670;
                int _13771 = _13769 >> 1;
                uint2 _16823;
                if ((_13769 & 1) == 0)
                {
                    _16823 = _1281._m0[_13771].xy;
                }
                else
                {
                    _16823 = _1281._m0[_13771].zw;
                }
                float3 _13631 = float3(_13559.x);
                int _13482 = _13476 + 1;
                int _13834 = _13457 + _1353[_13482].x;
                float2 _13841 = (_13507 * float2(_1353[_13482].yz)) - float2(0.5);
                float2 _13843 = floor(_13841);
                float2 _13846 = _13841 - _13843;
                int _13849 = int(_13843.x);
                int _13852 = int(_13843.y);
                int _16824;
                if (_13849 < 0)
                {
                    _16824 = _13849 + _1353[_13482].y;
                }
                else
                {
                    _16824 = _13849;
                }
                int _16825;
                if (_16824 >= _1353[_13482].y)
                {
                    _16825 = _16824 - _1353[_13482].y;
                }
                else
                {
                    _16825 = _16824;
                }
                int _13872 = _16825 + 1;
                int _17671 = (_13872 == _1353[_13482].y) ? 0 : _13872;
                int _13940 = _13834 + (max(_13852, 0) * _1353[_13482].y);
                int _13942 = _13940 + _16825;
                int _13944 = _13942 >> 1;
                uint2 _16831;
                if ((_13942 & 1) == 0)
                {
                    _16831 = _1281._m0[_13944].xy;
                }
                else
                {
                    _16831 = _1281._m0[_13944].zw;
                }
                int _13980 = _13940 + _17671;
                int _13982 = _13980 >> 1;
                uint2 _16833;
                if ((_13980 & 1) == 0)
                {
                    _16833 = _1281._m0[_13982].xy;
                }
                else
                {
                    _16833 = _1281._m0[_13982].zw;
                }
                int _14016 = _13834 + (min((_13852 + 1), (_1353[_13482].z - 1)) * _1353[_13482].y);
                int _14018 = _14016 + _16825;
                int _14020 = _14018 >> 1;
                uint2 _16836;
                if ((_14018 & 1) == 0)
                {
                    _16836 = _1281._m0[_14020].xy;
                }
                else
                {
                    _16836 = _1281._m0[_14020].zw;
                }
                int _14056 = _14016 + _17671;
                int _14058 = _14056 >> 1;
                uint2 _16837;
                if ((_14056 & 1) == 0)
                {
                    _16837 = _1281._m0[_14058].xy;
                }
                else
                {
                    _16837 = _1281._m0[_14058].zw;
                }
                float3 _13918 = float3(_13846.x);
                float3 _13212 = mix(mix(mix(float3(float2(as_type<half2>(_16817.x)), float2(as_type<half2>(_16817.y)).x), float3(float2(as_type<half2>(_16819.x)), float2(as_type<half2>(_16819.y)).x), _13631), mix(float3(float2(as_type<half2>(_16822.x)), float2(as_type<half2>(_16822.y)).x), float3(float2(as_type<half2>(_16823.x)), float2(as_type<half2>(_16823.y)).x), _13631), float3(_13559.y)), mix(mix(float3(float2(as_type<half2>(_16831.x)), float2(as_type<half2>(_16831.y)).x), float3(float2(as_type<half2>(_16833.x)), float2(as_type<half2>(_16833.y)).x), _13918), mix(float3(float2(as_type<half2>(_16836.x)), float2(as_type<half2>(_16836.y)).x), float3(float2(as_type<half2>(_16837.x)), float2(as_type<half2>(_16837.y)).x), _13918), float3(_13846.y)), float3(_13473 - float(_13476))) * _13349.w;
                float _13216 = _16807 * (1.0 - _16806);
                _17526 = _16872 + (_13212 * _13216);
                _17525 = _16806 + _13216;
            }
            _16916 = _16872 + (_16794 * (1.0 - _16806));
        }
        else
        {
            _16916 = _16794;
        }
        bool _4163;
        if (_3699)
        {
            _4163 = _283._m33.z > 0.5;
        }
        else
        {
            _4163 = _3699;
        }
        float3 _17006;
        if (_4163)
        {
            float3 _16966;
            do
            {
                float _14143 = ((_283._m32.x * (1.0 - smoothstep(_283._m33.x * 0.5, _283._m33.x, abs(dot(_283._m31.xyz, in.m_3037) - _283._m31.w)))) * smoothstep(0.5, 0.89999997615814208984375, dot(_3664, _283._m31.xyz))) * (1.0 - smoothstep(_283._m32.y * 0.5, _283._m32.y, _16694));
                if (_14143 <= 0.0)
                {
                    _16966 = _16916;
                    break;
                }
                float4 _14168 = _283._m30 * float4(in.m_3037 + ((_16704 - (_283._m31.xyz * dot(_16704, _283._m31.xyz))) * _283._m32.w), 1.0);
                float2 _14181 = ((float2(_14168.x, -_14168.y) / float2(_14168.w)) * 0.5) + float2(0.5);
                float _14185 = _283._m32.z * _16694;
                float3 _16964;
                float _16965;
                _16965 = 0.0;
                _16964 = float3(0.0);
                for (int _16963 = 0; _16963 < 12; )
                {
                    float _14192 = float(_16963);
                    float _14200 = _14192 * 2.3999631404876708984375;
                    float2 _14212 = _14181 + (float2(cos(_14200) * _283._m33.y, sin(_14200)) * (sqrt((_14192 + 0.5) * 0.083333335816860198974609375) * _14185));
                    float2 _14217 = fast::min(_14212, float2(1.0) - _14212);
                    float _14223 = smoothstep(0.0, 0.039999999105930328369140625, fast::min(_14217.x, _14217.y));
                    float4 _14231 = _3352.sample(_2533, fast::clamp(_14212, float2(0.0), float2(1.0)), level(0.0));
                    float3 _14233 = _14231.xyz;
                    _16965 += (_14231.w * _14223);
                    _16964 += ((_14233 / (float3(1.0) - fast::min(_14233, float3(0.99500000476837158203125)))) * _14223);
                    _16963++;
                    continue;
                }
                _16966 = mix(_16916, (_16964 * float3(0.083333335816860198974609375)) + (_16916 * (1.0 - (_16965 * 0.083333335816860198974609375))), float3(_14143));
                break;
            } while(false);
            _17006 = _16966;
        }
        else
        {
            _17006 = _16916;
        }
        float3 _4183 = (_3943 * _16971.x) + float3(_16971.y);
        float3 _4199 = _17060 + (((((float3(1.0) - _4183) * _3937) * _16894) + (_4183 * _17006)) * _17023);
        float3 _17267;
        if (_283._m13.w > 0.5)
        {
            float2 _14297 = fast::clamp(floor(gl_FragCoord.xy * _283._m12.xy), float2(0.0), _283._m13.xy - float2(1.0));
            uint _14325 = uint((((fast::clamp(floor((log2(fast::max(dot(_283._m11.xyz, in.m_3037) + _283._m11.w, 9.9999999747524270787835121154785e-07)) * _283._m12.z) + _283._m12.w), 0.0, _283._m13.z - 1.0) * _283._m13.y) + _14297.y) * _283._m13.x) + _14297.x);
            uint _14327 = _14325 >> uint(2);
            uint _14329 = _14325 & 3u;
            uint _14333 = _3167._m0[_14327][_14329] & 65535u;
            uint _14335 = _3167._m0[_14327][_14329] >> uint(16);
            float3 _17204;
            _17204 = _4199;
            float3 _4299;
            spvUnsafeArray<float2, 3> _14743;
            spvUnsafeArray<float2, 3> _14744;
            spvUnsafeArray<float2, 3> _14956;
            spvUnsafeArray<float2, 3> _14957;
            for (uint _17084 = _14333; _17084 < (_14333 + _14335); _17204 = _4299, _17084++)
            {
                uint _14341 = _17084 / 3u;
                uint _14354 = (_3188._m0[_14341 >> uint(2)][_14341 & 3u] >> ((_17084 - (_14341 * 3u)) * 10u)) & 1023u;
                float3 _14371 = _3030._m0[_14354].xyz - in.m_3037;
                float _14374 = dot(_14371, _14371);
                float _14378 = _14374 * _3030._m0[_14354].w;
                float _14383 = fast::clamp(1.0 - (_14378 * _14378), 0.0, 1.0);
                float3 _14388 = _14371 * rsqrt(fast::max(_14374, 9.9999999392252902907785028219223e-09));
                float _14406 = fast::clamp((dot(-_14388, _3073._m0[_14354].xyz) * _3065._m0[_14354].w) + _3073._m0[_14354].w, 0.0, 1.0);
                float3 _14419 = _3065._m0[_14354].xyz * ((((_14383 * _14383) * _14406) * _14406) / fast::max(_14374, 9.9999997473787516355514526367188e-05));
                float3 _17202;
                if (_3669)
                {
                    float _17111;
                    do
                    {
                        uint _14455 = uint(_283._m21.z);
                        if (_14354 < _14455)
                        {
                            float _14477 = _283._m26[_14354].z * fast::max((_283._m15[_14354] * float4(in.m_3037, 1.0)).w, 0.0);
                            float4 _14501 = _283._m15[_14354] * float4((in.m_3037 + (_3664 * (_14477 * _283._m25.x))) + (_14388 * (_14477 * _283._m25.y)), 1.0);
                            float _14503 = _14501.w;
                            if (_14503 <= 0.0)
                            {
                                _17111 = 1.0;
                                break;
                            }
                            float3 _14512 = _14501.xyz / float3(_14503);
                            float _14514 = _14512.x;
                            bool _14515 = _14514 < 0.0;
                            bool _14522;
                            if (!_14515)
                            {
                                _14522 = _14514 > 1.0;
                            }
                            else
                            {
                                _14522 = _14515;
                            }
                            bool _14529;
                            if (!_14522)
                            {
                                _14529 = _14512.y < 0.0;
                            }
                            else
                            {
                                _14529 = _14522;
                            }
                            bool _14536;
                            if (!_14529)
                            {
                                _14536 = _14512.y > 1.0;
                            }
                            else
                            {
                                _14536 = _14529;
                            }
                            bool _14543;
                            if (!_14536)
                            {
                                _14543 = _14512.z > 1.0;
                            }
                            else
                            {
                                _14543 = _14536;
                            }
                            if (_14543)
                            {
                                _17111 = 1.0;
                                break;
                            }
                            float _14549 = _14512.z;
                            float2 _14715 = _283._m22.xy * 0.5;
                            float2 _14720 = _283._m26[_14354].xy + (_14512.xy * _283._m23.zw);
                            float4 _14733 = float4(_283._m26[_14354].xy + _14715, (_283._m26[_14354].xy + _283._m23.zw) - _14715);
                            float _17110;
                            do
                            {
                                int _14759 = int(_283._m22.z);
                                if (_14759 <= 0)
                                {
                                    float2 _14769 = fast::clamp(_14720, _14733.xy, _14733.zw);
                                    _17110 = spvDepthCast(_303).sample_compare(_303Smplr, float3(_14769, _14549).xy, _14549);
                                    break;
                                }
                                float2 _14782 = (_14720 / _283._m22.xy) + float2(0.5);
                                float2 _14783 = floor(_14782);
                                float2 _14788 = _14782 - _14783;
                                float2 _14791 = _14783 - float2(0.5);
                                bool _14795 = _14759 == 1;
                                if (_14795)
                                {
                                    float2 _14798 = _14788 * 2.0;
                                    _14743[0] = float2(3.0) - _14798;
                                    _14743[1] = float2(1.0) + _14798;
                                    _14744[0] = ((float2(2.0) - _14788) / _14743[0]) - float2(1.0);
                                    _14744[1] = (_14788 / _14743[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _14825 = _14788 * 3.0;
                                    _14743[0] = float2(4.0) - _14825;
                                    _14743[1] = float2(7.0);
                                    _14743[2] = float2(1.0) + _14825;
                                    _14744[0] = ((float2(3.0) - (_14788 * 2.0)) / _14743[0]) - float2(2.0);
                                    _14744[1] = (float2(3.0) + _14788) / _14743[1];
                                    _14744[2] = (_14788 / _14743[2]) + float2(2.0);
                                }
                                int _17673 = _14795 ? 2 : 3;
                                int _17100;
                                float _17103;
                                _17103 = 0.0;
                                _17100 = 0;
                                float _17109;
                                for (; _17100 < _17673; _17103 = _17109, _17100++)
                                {
                                    _17109 = _17103;
                                    for (int _17106 = 0; _17106 < _17673; )
                                    {
                                        _17109 += ((_14743[_17106].x * _14743[_17100].y) * spvDepthCast(_303).sample_compare(_303Smplr, float3(fast::clamp(_283._m22.xy * (_14791 + float2(_14744[_17106].x, _14744[_17100].y)), _14733.xy, _14733.zw), _14549).xy, _14549));
                                        _17106++;
                                        continue;
                                    }
                                }
                                _17110 = _17103 * (_14795 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _17111 = _17110;
                            break;
                        }
                        uint _14559 = _14354 - _14455;
                        if (_14559 >= uint(_283._m21.w))
                        {
                            _17111 = 1.0;
                            break;
                        }
                        float _14580 = _283._m27[_14559].w * length(in.m_3037 - _283._m27[_14559].xyz);
                        float3 _14598 = ((in.m_3037 + (_3664 * (_14580 * _283._m25.x))) + (_14388 * (_14580 * _283._m25.y))) - _283._m27[_14559].xyz;
                        float3 _14600 = abs(_14598);
                        float _14602 = _14600.x;
                        float _14604 = _14600.y;
                        bool _14605 = _14602 >= _14604;
                        bool _14613;
                        if (_14605)
                        {
                            _14613 = _14602 >= _14600.z;
                        }
                        else
                        {
                            _14613 = _14605;
                        }
                        float _17085;
                        int _17087;
                        if (_14613)
                        {
                            _17087 = (_14598.x > 0.0) ? 0 : 1;
                            _17085 = _14602;
                        }
                        else
                        {
                            float _14625 = _14600.z;
                            bool _14626 = _14604 >= _14625;
                            int _17088;
                            if (_14626)
                            {
                                _17088 = (_14598.y > 0.0) ? 2 : 3;
                            }
                            else
                            {
                                _17088 = (_14598.z > 0.0) ? 4 : 5;
                            }
                            _17087 = _17088;
                            _17085 = _14626 ? _14604 : _14625;
                        }
                        if (_17085 <= 0.0)
                        {
                            _17111 = 1.0;
                            break;
                        }
                        float2 _14663 = float2(dot(_14598, _961[_17087]), dot(_14598, _970[_17087])) / float2(_17085 * _283._m24.z);
                        float _14670 = _283._m28[_14559].z + (_283._m28[_14559].w / _17085);
                        if (_14670 > 1.0)
                        {
                            _17111 = 1.0;
                            break;
                        }
                        float2 _14688 = _283._m28[_14559].xy + (float2(float(spvSMod(_17087, 3)), float(_17087 / 3)) * _283._m24.xy);
                        float2 _14928 = _283._m22.xy * 0.5;
                        float2 _14933 = _14688 + (float2(0.5 + (0.5 * _14663.x), 0.5 - (0.5 * _14663.y)) * _283._m24.xy);
                        float4 _14946 = float4(_14688 + _14928, (_14688 + _283._m24.xy) - _14928);
                        float _17099;
                        do
                        {
                            int _14972 = int(_283._m22.z);
                            if (_14972 <= 0)
                            {
                                _17099 = spvDepthCast(_303).sample_compare(_303Smplr, float3(fast::clamp(_14933, _14946.xy, _14946.zw), _14670).xy, _14670);
                                break;
                            }
                            float2 _14995 = (_14933 / _283._m22.xy) + float2(0.5);
                            float2 _14996 = floor(_14995);
                            float2 _15001 = _14995 - _14996;
                            float2 _15004 = _14996 - float2(0.5);
                            bool _15008 = _14972 == 1;
                            if (_15008)
                            {
                                float2 _15011 = _15001 * 2.0;
                                _14956[0] = float2(3.0) - _15011;
                                _14956[1] = float2(1.0) + _15011;
                                _14957[0] = ((float2(2.0) - _15001) / _14956[0]) - float2(1.0);
                                _14957[1] = (_15001 / _14956[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _15038 = _15001 * 3.0;
                                _14956[0] = float2(4.0) - _15038;
                                _14956[1] = float2(7.0);
                                _14956[2] = float2(1.0) + _15038;
                                _14957[0] = ((float2(3.0) - (_15001 * 2.0)) / _14956[0]) - float2(2.0);
                                _14957[1] = (float2(3.0) + _15001) / _14956[1];
                                _14957[2] = (_15001 / _14956[2]) + float2(2.0);
                            }
                            int _17676 = _15008 ? 2 : 3;
                            int _17089;
                            float _17092;
                            _17092 = 0.0;
                            _17089 = 0;
                            float _17098;
                            for (; _17089 < _17676; _17092 = _17098, _17089++)
                            {
                                _17098 = _17092;
                                for (int _17095 = 0; _17095 < _17676; )
                                {
                                    _17098 += ((_14956[_17095].x * _14956[_17089].y) * spvDepthCast(_303).sample_compare(_303Smplr, float3(fast::clamp(_283._m22.xy * (_15004 + float2(_14957[_17095].x, _14957[_17089].y)), _14946.xy, _14946.zw), _14670).xy, _14670));
                                    _17095++;
                                    continue;
                                }
                            }
                            _17099 = _17092 * (_15008 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _17111 = _17099;
                        break;
                    } while(false);
                    _17202 = _14419 * _17111;
                }
                else
                {
                    _17202 = _14419;
                }
                float3 _4251 = fast::normalize(_14388 + _3653);
                float _4256 = fast::clamp(dot(_16704, _14388), 0.0, 1.0);
                float _4261 = fast::clamp(dot(_16704, _4251), 0.0, 1.0);
                float3 _15143 = _3943 + (_9726 * powr(1.0 - fast::clamp(dot(_3653, _4251), 0.0, 1.0), 5.0));
                float _15157 = ((_4261 * _4261) * _9741) + 1.0;
                _4299 = _17204 + (((((float3(1.0) - _15143) * _3937) + ((_15143 * ((_9736 / ((3.1415927410125732421875 * _15157) * _15157)) * (0.5 / fast::max((_4256 * _9767) + (_16732 * sqrt(((_4256 * _4256) * _9763) + _9736)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875)) * _4256) * _17202);
            }
            _17267 = _17204;
        }
        else
        {
            _17267 = _4199;
        }
        _17334 = _16894;
        _17264 = _17267;
    }
    float4 _4316 = _4311.sample(_2533, _3419);
    float _4337 = -length(_3652);
    float _17389;
    if (_283._m9.w != 0.0)
    {
        float _4361 = _283._m9.w * (in.m_3037 - _283._m6.xyz).y;
        float _17332;
        if (abs(_4361) < 9.9999997473787516355514526367188e-05)
        {
            _17332 = 1.0 - (0.5 * _4361);
        }
        else
        {
            _17332 = (1.0 - exp(fast::min(-_4361, 60.0))) / _4361;
        }
        _17389 = 1.0 - exp((_4337 * (_283._m7.w * exp(fast::min((-_283._m9.w) * (_283._m6.y - _283._m6.w), 30.0)))) * _17332);
    }
    else
    {
        _17389 = 1.0 - exp(_4337 * _283._m7.w);
    }
    bool _4407 = _283._m34.z > 0.5;
    float3 _17385;
    if (_4407)
    {
        _17385 = _17334 * _17023;
    }
    else
    {
        _17385 = mix(_17264, _16698, float3(_2876._m1.y)) + (((_2876._m5.xyz * _4316.xyz) * (float3(1.0) + in.m_3666.yzw)) * in.m_3898.z);
    }
    float3 _4420 = mix(_17385, _283._m7.xyz, float3(_4407 ? 0.0 : _17389));
    float3 _17390;
    if (_283._m33.w > 0.5)
    {
        _17390 = _4420 / (float3(1.0) + _4420);
    }
    else
    {
        _17390 = _4420;
    }
    out.m_4432 = float4(_17390, ((in.m_3428.w * _2876._m0.w) * _3426.w) * in.m_3448.w);
    float2 _17391;
    do
    {
        if (in.m_4442.w <= 0.0)
        {
            _17391 = float2(0.0);
            break;
        }
        _17391 = ((in.m_4442.xy / float2(in.m_4442.w)) - (in.m_4441.xy / float2(in.m_4441.w))) * float2(0.5, -0.5);
        break;
    } while(false);
    out.m_4440 = _17391;
    return out;
}

