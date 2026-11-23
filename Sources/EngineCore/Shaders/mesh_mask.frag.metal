// Generated from mesh_mask.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: a0d8e9cd9a3d702b
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
    float4 m_4426 [[color(0)]];
    float2 m_4434 [[color(1)]];
};

struct fragment_main_in
{
    float3 m_3037 [[user(locn0)]];
    float3 m_2946 [[user(locn1)]];
    float2 m_3405 [[user(locn2)]];
    float4 m_3428 [[user(locn3)]];
    float3 m_2980 [[user(locn4)]];
    float4 m_3670 [[user(locn5)]];
    float4 m_4435 [[user(locn6)]];
    float4 m_4436 [[user(locn7)]];
    float4 m_2952 [[user(locn8)]];
};

fragment fragment_main_out fragment_main(fragment_main_in in [[stage_in]], constant _2874& _2876 [[buffer(2)]], constant _3028& _3030 [[buffer(3)]], constant _3063& _3065 [[buffer(4)]], constant _3071& _3073 [[buffer(5)]], constant _3165& _3167 [[buffer(6)]], constant _3186& _3188 [[buffer(7)]], constant _281& _283 [[buffer(15)]], const device _1279& _1281 [[buffer(21)]], texture2d<float> _303 [[texture(0)]], texture2d<float> _3421 [[texture(1)]], texture2d<float> _3890 [[texture(2)]], texture2d<float> _3547 [[texture(3)]], texture2d<float> _3352 [[texture(4)]], texture2d<float> _4308 [[texture(5)]], texture2d<float> _2531 [[texture(6)]], texture2d<float> _2632 [[texture(7)]], sampler _303Smplr [[sampler(0)]], sampler _2533 [[sampler(1)]], sampler _2634 [[sampler(7)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])
{
    fragment_main_out out = {};
    float2 _3419 = float2(dot(_2876._m2.xy, in.m_3405) + _2876._m2.z, dot(_2876._m3.xy, in.m_3405) + _2876._m3.z);
    float4 _3426 = _3421.sample(_2533, _3419);
    float3 _3436 = _3426.xyz;
    float3 _3437 = (in.m_3428.xyz * _2876._m0.xyz) * _3436;
    if ((_2876._m0.w * _3426.w) < _2876._m6.x)
    {
        discard_fragment();
    }
    float3 _16502;
    if (_2876._m1.x > 0.5)
    {
        float2 _3471 = floor(in.m_3037.xz * float2(0.5));
        _16502 = _3437 * ((mod(abs(_3471.x + _3471.y), 2.0) < 0.5) ? 1.0 : 0.75);
    }
    else
    {
        _16502 = _3437;
    }
    float3 _16599;
    float _16630;
    float2 _16663;
    if (_2876._m3.w > 0.5)
    {
        float3 _4542;
        float2 _4549;
        float _16500;
        do
        {
            float3 _4513 = float4(_2876._m2.w, _2876._m3.w, 0.0, 0.0).xyy;
            float3 _4516 = floor(_4513 * float3(1.52587890625e-05));
            float3 _4521 = _4513 - (_4516 * 65536.0);
            float3 _4524 = floor(_4521 * float3(0.00390625));
            float3 _4532 = _4521 - (_4524 * 256.0);
            _4542 = (float3(_4532.x, _4524.x, _4516.x) * float3(0.0039215688593685626983642578125)) * 2.0;
            _4549 = float2(_4532.y, _4524.y) * float2(0.0039215688593685626983642578125);
            float _4552 = _4516.y - 128.0;
            float _4558 = floor(_4552 * 0.03125) * 0.3333333432674407958984375;
            float3 _4564 = fast::normalize(in.m_2946);
            float _4568 = dot(_4564, in.m_2952.xyz);
            float _4580 = (_4568 / fast::max(length(in.m_2952.xyz - (_4564 * _4568)), 9.9999999747524270787835121154785e-07)) * 25.5;
            if (((-24.0) + _4580) < (-2.0))
            {
                _16500 = 0.0;
                break;
            }
            float3 _4588 = in.m_2980 * (4.0 * exp2(mod(_4552, 32.0) * 0.3333333432674407958984375));
            float3 _4632 = floor(_4588);
            float3 _4635 = _4588 - _4632;
            float3 _4643 = (_4635 * _4635) * (float3(3.0) - (_4635 * 2.0));
            uint3 _4710 = uint3(int3(_4632));
            uint _4723 = (((_4710.x * 1597334677u) ^ (_4710.y * 3812015801u)) ^ (_4710.z * 2798796415u)) * 1597334677u;
            uint3 _4738 = uint3(int3(_4632 + float3(1.0, 0.0, 0.0)));
            uint _4751 = (((_4738.x * 1597334677u) ^ (_4738.y * 3812015801u)) ^ (_4738.z * 2798796415u)) * 1597334677u;
            float _4652 = _4643.x;
            uint3 _4766 = uint3(int3(_4632 + float3(0.0, 1.0, 0.0)));
            uint _4779 = (((_4766.x * 1597334677u) ^ (_4766.y * 3812015801u)) ^ (_4766.z * 2798796415u)) * 1597334677u;
            uint3 _4794 = uint3(int3(_4632 + float3(1.0, 1.0, 0.0)));
            uint _4807 = (((_4794.x * 1597334677u) ^ (_4794.y * 3812015801u)) ^ (_4794.z * 2798796415u)) * 1597334677u;
            float _4668 = _4643.y;
            uint3 _4822 = uint3(int3(_4632 + float3(0.0, 0.0, 1.0)));
            uint _4835 = (((_4822.x * 1597334677u) ^ (_4822.y * 3812015801u)) ^ (_4822.z * 2798796415u)) * 1597334677u;
            uint3 _4850 = uint3(int3(_4632 + float3(1.0, 0.0, 1.0)));
            uint _4863 = (((_4850.x * 1597334677u) ^ (_4850.y * 3812015801u)) ^ (_4850.z * 2798796415u)) * 1597334677u;
            uint3 _4878 = uint3(int3(_4632 + float3(0.0, 1.0, 1.0)));
            uint _4891 = (((_4878.x * 1597334677u) ^ (_4878.y * 3812015801u)) ^ (_4878.z * 2798796415u)) * 1597334677u;
            uint3 _4906 = uint3(int3(_4632 + float3(1.0)));
            uint _4919 = (((_4906.x * 1597334677u) ^ (_4906.y * 3812015801u)) ^ (_4906.z * 2798796415u)) * 1597334677u;
            float3 _4594 = (_4588 * 2.7000000476837158203125) + float3(17.299999237060546875, 5.099999904632568359375, 9.69999980926513671875);
            float3 _4945 = floor(_4594);
            float3 _4948 = _4594 - _4945;
            float3 _4956 = (_4948 * _4948) * (float3(3.0) - (_4948 * 2.0));
            uint3 _5023 = uint3(int3(_4945));
            uint _5036 = (((_5023.x * 1597334677u) ^ (_5023.y * 3812015801u)) ^ (_5023.z * 2798796415u)) * 1597334677u;
            uint3 _5051 = uint3(int3(_4945 + float3(1.0, 0.0, 0.0)));
            uint _5064 = (((_5051.x * 1597334677u) ^ (_5051.y * 3812015801u)) ^ (_5051.z * 2798796415u)) * 1597334677u;
            float _4965 = _4956.x;
            uint3 _5079 = uint3(int3(_4945 + float3(0.0, 1.0, 0.0)));
            uint _5092 = (((_5079.x * 1597334677u) ^ (_5079.y * 3812015801u)) ^ (_5079.z * 2798796415u)) * 1597334677u;
            uint3 _5107 = uint3(int3(_4945 + float3(1.0, 1.0, 0.0)));
            uint _5120 = (((_5107.x * 1597334677u) ^ (_5107.y * 3812015801u)) ^ (_5107.z * 2798796415u)) * 1597334677u;
            float _4981 = _4956.y;
            uint3 _5135 = uint3(int3(_4945 + float3(0.0, 0.0, 1.0)));
            uint _5148 = (((_5135.x * 1597334677u) ^ (_5135.y * 3812015801u)) ^ (_5135.z * 2798796415u)) * 1597334677u;
            uint3 _5163 = uint3(int3(_4945 + float3(1.0, 0.0, 1.0)));
            uint _5176 = (((_5163.x * 1597334677u) ^ (_5163.y * 3812015801u)) ^ (_5163.z * 2798796415u)) * 1597334677u;
            uint3 _5191 = uint3(int3(_4945 + float3(0.0, 1.0, 1.0)));
            uint _5204 = (((_5191.x * 1597334677u) ^ (_5191.y * 3812015801u)) ^ (_5191.z * 2798796415u)) * 1597334677u;
            uint3 _5219 = uint3(int3(_4945 + float3(1.0)));
            uint _5232 = (((_5219.x * 1597334677u) ^ (_5219.y * 3812015801u)) ^ (_5219.z * 2798796415u)) * 1597334677u;
            float _4599 = mix(0.449999988079071044921875, 0.0500000007450580596923828125, _4558);
            float _4603 = ((mix(mix(mix(float((_4723 ^ (_4723 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_4751 ^ (_4751 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _4652), mix(float((_4779 ^ (_4779 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_4807 ^ (_4807 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _4652), _4668), mix(mix(float((_4835 ^ (_4835 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_4863 ^ (_4863 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _4652), mix(float((_4891 ^ (_4891 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_4919 ^ (_4919 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _4652), _4668), _4643.z) * 0.64999997615814208984375) + (mix(mix(mix(float((_5036 ^ (_5036 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_5064 ^ (_5064 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _4965), mix(float((_5092 ^ (_5092 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_5120 ^ (_5120 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _4965), _4981), mix(mix(float((_5148 ^ (_5148 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_5176 ^ (_5176 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _4965), mix(float((_5204 ^ (_5204 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_5232 ^ (_5232 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _4965), _4981), _4956.z) * 0.3499999940395355224609375)) - 0.5;
            _16500 = smoothstep(-_4599, _4599, (_4580 + (-24.450000762939453125)) + (_4603 * mix(0.800000011920928955078125, 2.2000000476837158203125, _4558)));
            break;
        } while(false);
        _16663 = _4549;
        _16630 = _16500;
        _16599 = mix(_16502, (in.m_3428.xyz * _4542) * mix(float3(1.0), _3436 * 2.0, float3(0.5)), float3(_16500));
    }
    else
    {
        _16663 = float2(0.0);
        _16630 = 0.0;
        _16599 = _16502;
    }
    float3 _3513 = fast::normalize(in.m_2946);
    float3 _16512;
    if (_2876._m6.y > 0.5)
    {
        float3 _3528 = in.m_2952.xyz - (_3513 * dot(_3513, in.m_2952.xyz));
        float3 _16513;
        if (dot(_3528, _3528) > 9.9999999600419720025001879548654e-13)
        {
            float3 _3536 = fast::normalize(_3528);
            float4 _3552 = _3547.sample(_2533, _3419);
            float3 _16504;
            if (_2876._m6.z > 0.5)
            {
                float2 _16503;
                if (_2876._m6.z > 1.5)
                {
                    _16503 = _3552.xw;
                }
                else
                {
                    _16503 = _3552.xy;
                }
                float2 _3574 = (_16503 * 2.0) - float2(1.0);
                _16504 = float3(_3574, sqrt(fast::clamp(1.0 - dot(_3574, _3574), 0.0, 1.0)));
            }
            else
            {
                _16504 = (_3552.xyz * 2.0) - float3(1.0);
            }
            float2 _3596 = _16504.xy * _2876._m4.z;
            _16513 = fast::normalize(((_3536 * _3596.x) + ((cross(_3513, _3536) * ((in.m_2952.w < 0.0) ? (-1.0) : 1.0)) * _3596.y)) + (_3513 * _16504.z));
        }
        else
        {
            _16513 = _3513;
        }
        _16512 = _16513;
    }
    else
    {
        _16512 = _3513;
    }
    bool _3620 = _2876._m5.w > 0.5;
    float _16509;
    if (_3620)
    {
        _16509 = fast::clamp(_2876._m1.z, 0.0, 1.0);
    }
    else
    {
        _16509 = 0.0;
    }
    bool _3638;
    if (_3620)
    {
        _3638 = !gl_FrontFacing;
    }
    else
    {
        _3638 = _3620;
    }
    float3 _16699;
    if (_3638 && (_16509 <= 0.0))
    {
        _16699 = -_16512;
    }
    else
    {
        _16699 = _16512;
    }
    float3 _3650 = fast::normalize(_283._m4.xyz);
    float3 _3656 = _283._m6.xyz - in.m_3037;
    float3 _3657 = fast::normalize(_3656);
    float3 _3662 = fast::normalize(_3650 + _3657);
    float3 _3668 = _3513 * (gl_FrontFacing ? 1.0 : (-1.0));
    bool _3673 = in.m_3670.x > 0.5;
    float3 _16693;
    float _16733;
    if ((_283._m5.w > 0.5) && _3673)
    {
        float _16569;
        float3 _16570;
        do
        {
            int _5261 = int(_283._m21.x);
            float _5269 = dot(_283._m20.xyz, in.m_3037) + _283._m20.w;
            int _16514;
            _16514 = 0;
            for (;;)
            {
                bool _5275 = _16514 < (_5261 - 1);
                bool _5283;
                if (_5275)
                {
                    _5283 = _5269 > _283._m16[_16514];
                }
                else
                {
                    _5283 = _5275;
                }
                if (_5283)
                {
                    _16514++;
                    continue;
                }
                else
                {
                    break;
                }
            }
            if (_5269 > _283._m16[_16514])
            {
                _16570 = float3(1.0);
                _16569 = 1.0;
                break;
            }
            float _16527;
            do
            {
                float4 _5385 = _283._m14[_16514] * float4(in.m_3037 + (_3668 * _283._m18[_16514]), 1.0);
                float _5388 = _5385.x;
                bool _5389 = _5388 < 0.0;
                bool _5396;
                if (!_5389)
                {
                    _5396 = _5388 > 1.0;
                }
                else
                {
                    _5396 = _5389;
                }
                bool _5403;
                if (!_5396)
                {
                    _5403 = _5385.y < 0.0;
                }
                else
                {
                    _5403 = _5396;
                }
                bool _5410;
                if (!_5403)
                {
                    _5410 = _5385.y > 1.0;
                }
                else
                {
                    _5410 = _5403;
                }
                if (_5410)
                {
                    _16527 = 1.0;
                    break;
                }
                float2 _5423 = float2(float(_16514 & 1), float(_16514 >> 1)) * _283._m23.xy;
                float _5430 = fast::min(_5385.z, 1.0) - _283._m19[_16514];
                float2 _5449 = _283._m22.xy * 0.5;
                float2 _5454 = _5423 + (_5385.xy * _283._m23.xy);
                float4 _5467 = float4(_5423 + _5449, (_5423 + _283._m23.xy) - _5449);
                float _16526;
                do
                {
                    int _5493 = int(_283._m22.z);
                    if (_5493 <= 0)
                    {
                        _16526 = spvDepthCast(_303).sample_compare(_303Smplr, float3(fast::clamp(_5454, _5467.xy, _5467.zw), _5430).xy, _5430);
                        break;
                    }
                    float2 _5516 = (_5454 / _283._m22.xy) + float2(0.5);
                    float2 _5517 = floor(_5516);
                    float2 _5522 = _5516 - _5517;
                    float2 _5525 = _5517 - float2(0.5);
                    bool _5529 = _5493 == 1;
                    spvUnsafeArray<float2, 3> _5477;
                    spvUnsafeArray<float2, 3> _5478;
                    if (_5529)
                    {
                        float2 _5532 = _5522 * 2.0;
                        _5477[0] = float2(3.0) - _5532;
                        _5477[1] = float2(1.0) + _5532;
                        _5478[0] = ((float2(2.0) - _5522) / _5477[0]) - float2(1.0);
                        _5478[1] = (_5522 / _5477[1]) + float2(1.0);
                    }
                    else
                    {
                        float2 _5559 = _5522 * 3.0;
                        _5477[0] = float2(4.0) - _5559;
                        _5477[1] = float2(7.0);
                        _5477[2] = float2(1.0) + _5559;
                        _5478[0] = ((float2(3.0) - (_5522 * 2.0)) / _5477[0]) - float2(2.0);
                        _5478[1] = (float2(3.0) + _5522) / _5477[1];
                        _5478[2] = (_5522 / _5477[2]) + float2(2.0);
                    }
                    int _17780 = _5529 ? 2 : 3;
                    int _16516;
                    float _16519;
                    _16519 = 0.0;
                    _16516 = 0;
                    float _16525;
                    for (; _16516 < _17780; _16519 = _16525, _16516++)
                    {
                        _16525 = _16519;
                        for (int _16522 = 0; _16522 < _17780; )
                        {
                            _16525 += ((_5477[_16522].x * _5477[_16516].y) * spvDepthCast(_303).sample_compare(_303Smplr, float3(fast::clamp(_283._m22.xy * (_5525 + float2(_5478[_16522].x, _5478[_16516].y)), _5467.xy, _5467.zw), _5430).xy, _5430));
                            _16522++;
                            continue;
                        }
                    }
                    _16526 = _16519 * (_5529 ? 0.0625 : 0.0069444444961845874786376953125);
                    break;
                } while(false);
                _16527 = _16526;
                break;
            } while(false);
            float3 _16564;
            float _16567;
            if (_5269 > _283._m17[_16514])
            {
                float _5323 = (_5269 - _283._m17[_16514]) / (_283._m16[_16514] - _283._m17[_16514]);
                int _5325 = _16514 + 1;
                float3 _16565;
                float _16568;
                if (_5325 < _5261)
                {
                    float _16547;
                    do
                    {
                        float4 _5672 = _283._m14[_5325] * float4(in.m_3037 + (_3668 * _283._m18[_5325]), 1.0);
                        float _5675 = _5672.x;
                        bool _5676 = _5675 < 0.0;
                        bool _5683;
                        if (!_5676)
                        {
                            _5683 = _5675 > 1.0;
                        }
                        else
                        {
                            _5683 = _5676;
                        }
                        bool _5690;
                        if (!_5683)
                        {
                            _5690 = _5672.y < 0.0;
                        }
                        else
                        {
                            _5690 = _5683;
                        }
                        bool _5697;
                        if (!_5690)
                        {
                            _5697 = _5672.y > 1.0;
                        }
                        else
                        {
                            _5697 = _5690;
                        }
                        if (_5697)
                        {
                            _16547 = 1.0;
                            break;
                        }
                        float2 _5710 = float2(float(_5325 & 1), float(_5325 >> 1)) * _283._m23.xy;
                        float _5717 = fast::min(_5672.z, 1.0) - _283._m19[_5325];
                        float2 _5736 = _283._m22.xy * 0.5;
                        float2 _5741 = _5710 + (_5672.xy * _283._m23.xy);
                        float4 _5754 = float4(_5710 + _5736, (_5710 + _283._m23.xy) - _5736);
                        float _16546;
                        do
                        {
                            int _5780 = int(_283._m22.z);
                            if (_5780 <= 0)
                            {
                                _16546 = spvDepthCast(_303).sample_compare(_303Smplr, float3(fast::clamp(_5741, _5754.xy, _5754.zw), _5717).xy, _5717);
                                break;
                            }
                            float2 _5803 = (_5741 / _283._m22.xy) + float2(0.5);
                            float2 _5804 = floor(_5803);
                            float2 _5809 = _5803 - _5804;
                            float2 _5812 = _5804 - float2(0.5);
                            bool _5816 = _5780 == 1;
                            spvUnsafeArray<float2, 3> _5764;
                            spvUnsafeArray<float2, 3> _5765;
                            if (_5816)
                            {
                                float2 _5819 = _5809 * 2.0;
                                _5764[0] = float2(3.0) - _5819;
                                _5764[1] = float2(1.0) + _5819;
                                _5765[0] = ((float2(2.0) - _5809) / _5764[0]) - float2(1.0);
                                _5765[1] = (_5809 / _5764[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _5846 = _5809 * 3.0;
                                _5764[0] = float2(4.0) - _5846;
                                _5764[1] = float2(7.0);
                                _5764[2] = float2(1.0) + _5846;
                                _5765[0] = ((float2(3.0) - (_5809 * 2.0)) / _5764[0]) - float2(2.0);
                                _5765[1] = (float2(3.0) + _5809) / _5764[1];
                                _5765[2] = (_5809 / _5764[2]) + float2(2.0);
                            }
                            int _17782 = _5816 ? 2 : 3;
                            int _16536;
                            float _16539;
                            _16539 = 0.0;
                            _16536 = 0;
                            float _16545;
                            for (; _16536 < _17782; _16539 = _16545, _16536++)
                            {
                                _16545 = _16539;
                                for (int _16542 = 0; _16542 < _17782; )
                                {
                                    _16545 += ((_5764[_16542].x * _5764[_16536].y) * spvDepthCast(_303).sample_compare(_303Smplr, float3(fast::clamp(_283._m22.xy * (_5812 + float2(_5765[_16542].x, _5765[_16536].y)), _5754.xy, _5754.zw), _5717).xy, _5717));
                                    _16542++;
                                    continue;
                                }
                            }
                            _16546 = _16539 * (_5816 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _16547 = _16546;
                        break;
                    } while(false);
                    _16568 = mix(_16527, _16547, _5323);
                    _16565 = mix(_657[_16514], _657[_5325], float3(_5323));
                }
                else
                {
                    _16568 = mix(_16527, 1.0, _5323);
                    _16565 = _657[_16514];
                }
                _16567 = _16568;
                _16564 = _16565;
            }
            else
            {
                _16567 = _16527;
                _16564 = _657[_16514];
            }
            _16570 = select(float3(1.0), _16564, bool3(_283._m22.w > 0.5));
            _16569 = _16567;
            break;
        } while(false);
        _16733 = _16569;
        _16693 = _16599 * _16570;
    }
    else
    {
        _16733 = 1.0;
        _16693 = _16599;
    }
    float3 _3699 = _283._m5.xyz * _283._m4.w;
    bool _3703 = _2876._m6.w > 0.5;
    float _16622;
    if (_3703)
    {
        _16622 = 1.0;
    }
    else
    {
        _16622 = 1.0 + (_2876._m4.w * (_3352.sample(_2533, _3419).x - 1.0));
    }
    float _3723 = abs(in.m_2952.w);
    float _17018;
    if (_3723 > 0.0)
    {
        _17018 = _16622 * fast::min(_3723, 1.0);
    }
    else
    {
        _17018 = _16622;
    }
    float3 _17259;
    float3 _17329;
    if (!_3620)
    {
        float _3739 = dot(_16699, _3650);
        float3 _17240;
        if (_283._m29.x > 0.5)
        {
            float _5997 = (_283._m29.z * _16699.x) - (_283._m29.w * _16699.z);
            float _6010 = (_283._m29.w * _16699.x) + (_283._m29.z * _16699.z);
            float _6028 = 1.09254801273345947265625 * _5997;
            spvUnsafeArray<float, 9> _15494 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _16699.y, 0.48860299587249755859375 * _6010, 0.48860299587249755859375 * _5997, _6028 * _16699.y, (1.09254801273345947265625 * _16699.y) * _6010, 0.3153919875621795654296875 * (((3.0 * _6010) * _6010) - 1.0), _6028 * _6010, 0.546274006366729736328125 * ((_5997 * _5997) - (_16699.y * _16699.y)) });
            spvUnsafeArray<float, 9> _5942 = _15494;
            float3 _17239;
            _17239 = float3(0.0);
            for (int _17238 = 0; _17238 < 9; )
            {
                _17239 += (_2531.read(uint2((int2(496, 256) + int2(_17238, 0))), 0).xyz * _5942[_17238]);
                _17238++;
                continue;
            }
            _17240 = fast::max(_17239, float3(0.0)) * _283._m29.y;
        }
        else
        {
            _17240 = mix(_283._m9.xyz, _283._m8.xyz, float3((_16699.y * 0.5) + 0.5)) * _283._m8.w;
        }
        float3 _17245;
        if (_283._m34.y > 0.5)
        {
            int _6205 = int(_283._m34.y);
            int _6208 = int(_283._m34.x);
            float3 _17244;
            _17244 = _17240;
            float3 _17647;
            for (int _17243 = 0; _17243 < _6205; _17244 = _17647, _17243++)
            {
                int _6220 = 8 * (_6208 + _17243);
                float4 _6429 = as_type<float4>(_1281._m0[_6220 + 3]);
                float4 _6473 = as_type<float4>(_1281._m0[_6220]);
                float4 _6479 = as_type<float4>(_1281._m0[_6220 + 1]);
                float4 _6485 = as_type<float4>(_1281._m0[_6220 + 2]);
                float3 _6447 = _6473.xyz;
                float _6451 = _6473.w;
                float3 _6454 = _6479.xyz;
                float _6458 = _6479.w;
                float3 _6461 = _6485.xyz;
                float _6465 = _6485.w;
                float3 _6467 = float3(dot(_6447, in.m_3037) + _6451, dot(_6454, in.m_3037) + _6458, dot(_6461, in.m_3037) + _6465);
                float3 _6229 = _6429.xyz;
                float _6231 = _6429.w;
                float _17610;
                do
                {
                    float3 _6497 = _6229 - abs(_6467);
                    float _6505 = fast::min(_6497.x, fast::min(_6497.y, _6497.z));
                    if (_6505 <= 0.0)
                    {
                        _17610 = 0.0;
                        break;
                    }
                    if (_6231 <= 0.0)
                    {
                        _17610 = 1.0;
                        break;
                    }
                    float _6517 = fast::min(_6505 / _6231, 1.0);
                    _17610 = (_6517 * _6517) * (3.0 - (2.0 * _6517));
                    break;
                } while(false);
                if (_17610 <= 0.0)
                {
                    _17647 = _17244;
                    continue;
                }
                float3 _6240 = as_type<float4>(_1281._m0[_6220 + 4]).xyz;
                float4 _6538 = as_type<float4>(_1281._m0[_6220 + 5]);
                int _6544 = int(((device uint*)&_1281._m0[_6220 + 6])[0u]);
                float _6554 = dot(_6447, _16699);
                float _6560 = dot(_6454, _16699);
                float _6566 = dot(_6461, _16699);
                float3 _6567 = float3(_6554, _6560, _6566);
                float3 _6260 = (in.m_3037 + (_16699 * _6538.x)) + (_3657 * _6538.y);
                float3 _6279 = fast::clamp((((float3(dot(_6447, _6260) + _6451, dot(_6454, _6260) + _6458, dot(_6461, _6260) + _6465) + _6229) / fast::max(_6229 * 2.0, float3(9.9999999747524270787835121154785e-07))) * _6240) - float3(0.5), float3(0.0), _6240 - float3(1.0));
                int3 _6281 = int3(_6240);
                int3 _6288 = min(int3(_6279), max((_6281 - int3(2)), int3(0)));
                float3 _6292 = _6279 - float3(_6288);
                float _6647 = 0.48860299587249755859375 * _6560;
                float _6650 = 0.48860299587249755859375 * _6566;
                float _6653 = 0.48860299587249755859375 * _6554;
                float _6658 = 1.09254801273345947265625 * _6554;
                float _6661 = _6658 * _6560;
                float _6667 = (1.09254801273345947265625 * _6560) * _6566;
                float _6675 = 0.3153919875621795654296875 * (((3.0 * _6566) * _6566) - 1.0);
                float _6681 = _6658 * _6566;
                float _6695 = 0.546274006366729736328125 * ((_6554 * _6554) - (_6560 * _6560));
                int3 _6714 = _6281 - int3(1);
                int3 _6715 = min(_6288, _6714);
                int _6720 = _6281.x;
                int _6724 = _6281.y;
                int _6732 = _6544 + ((_6715.x + (_6720 * (_6715.y + (_6724 * _6715.z)))) * 4);
                float3 _6735 = float3(1.0) - _6292;
                float3 _6753 = (((((float3(_6715) + float3(0.5)) / _6240) * _6229) * 2.0) - _6229) - _6467;
                float _6763 = dot(_6753 * rsqrt(fast::max(dot(_6753, _6753), 1.0000000133514319600180897396058e-10)), _6567) + 1.0;
                float _6766 = _6735.x;
                float _6768 = _6735.y;
                float _6769 = _6766 * _6768;
                float _6771 = _6735.z;
                int _6795 = _6732 + 3;
                float _6781 = ((_6769 * _6771) * ((0.25 * (_6763 * _6763)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_6795])[1u])).y > 0.5);
                int _6825 = _6732 + 1;
                int _6829 = _6732 + 2;
                float2 _6841 = float2(as_type<half2>(_1281._m0[_6732].y));
                float2 _6850 = float2(as_type<half2>(_1281._m0[_6825].x));
                float2 _6859 = float2(as_type<half2>(_1281._m0[_6825].w));
                float2 _6868 = float2(as_type<half2>(_1281._m0[_6829].z));
                float3 _6956 = (((((((float3(float2(as_type<half2>(_1281._m0[_6732].x)), _6841.x) * 0.2820949852466583251953125) + (float3(_6841.y, float2(as_type<half2>(_1281._m0[_6732].z))) * _6647)) + (float3(float2(as_type<half2>(_1281._m0[_6732].w)), _6850.x) * _6650)) + (float3(_6850.y, float2(as_type<half2>(_1281._m0[_6825].y))) * _6653)) + (float3(float2(as_type<half2>(_1281._m0[_6825].z)), _6859.x) * _6661)) + (float3(_6859.y, float2(as_type<half2>(_1281._m0[_6829].x))) * _6667)) + (float3(float2(as_type<half2>(_1281._m0[_6829].y)), _6868.x) * _6675)) + (float3(_6868.y, float2(as_type<half2>(_1281._m0[_6829].w))) * _6681);
                int3 _6984 = min((_6288 + int3(1, 0, 0)), _6714);
                int _7001 = _6544 + ((_6984.x + (_6720 * (_6984.y + (_6724 * _6984.z)))) * 4);
                float3 _7022 = (((((float3(_6984) + float3(0.5)) / _6240) * _6229) * 2.0) - _6229) - _6467;
                float _7032 = dot(_7022 * rsqrt(fast::max(dot(_7022, _7022), 1.0000000133514319600180897396058e-10)), _6567) + 1.0;
                float _7038 = _6292.x * _6768;
                int _7064 = _7001 + 3;
                float _7050 = ((_7038 * _6771) * ((0.25 * (_7032 * _7032)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_7064])[1u])).y > 0.5);
                int _7094 = _7001 + 1;
                int _7098 = _7001 + 2;
                float2 _7110 = float2(as_type<half2>(_1281._m0[_7001].y));
                float2 _7119 = float2(as_type<half2>(_1281._m0[_7094].x));
                float2 _7128 = float2(as_type<half2>(_1281._m0[_7094].w));
                float2 _7137 = float2(as_type<half2>(_1281._m0[_7098].z));
                float3 _7225 = (((((((float3(float2(as_type<half2>(_1281._m0[_7001].x)), _7110.x) * 0.2820949852466583251953125) + (float3(_7110.y, float2(as_type<half2>(_1281._m0[_7001].z))) * _6647)) + (float3(float2(as_type<half2>(_1281._m0[_7001].w)), _7119.x) * _6650)) + (float3(_7119.y, float2(as_type<half2>(_1281._m0[_7094].y))) * _6653)) + (float3(float2(as_type<half2>(_1281._m0[_7094].z)), _7128.x) * _6661)) + (float3(_7128.y, float2(as_type<half2>(_1281._m0[_7098].x))) * _6667)) + (float3(float2(as_type<half2>(_1281._m0[_7098].y)), _7137.x) * _6675)) + (float3(_7137.y, float2(as_type<half2>(_1281._m0[_7098].w))) * _6681);
                int3 _7253 = min((_6288 + int3(0, 1, 0)), _6714);
                int _7270 = _6544 + ((_7253.x + (_6720 * (_7253.y + (_6724 * _7253.z)))) * 4);
                float3 _7291 = (((((float3(_7253) + float3(0.5)) / _6240) * _6229) * 2.0) - _6229) - _6467;
                float _7301 = dot(_7291 * rsqrt(fast::max(dot(_7291, _7291), 1.0000000133514319600180897396058e-10)), _6567) + 1.0;
                float _7307 = _6766 * _6292.y;
                int _7333 = _7270 + 3;
                float _7319 = ((_7307 * _6771) * ((0.25 * (_7301 * _7301)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_7333])[1u])).y > 0.5);
                int _7363 = _7270 + 1;
                int _7367 = _7270 + 2;
                float2 _7379 = float2(as_type<half2>(_1281._m0[_7270].y));
                float2 _7388 = float2(as_type<half2>(_1281._m0[_7363].x));
                float2 _7397 = float2(as_type<half2>(_1281._m0[_7363].w));
                float2 _7406 = float2(as_type<half2>(_1281._m0[_7367].z));
                float3 _7494 = (((((((float3(float2(as_type<half2>(_1281._m0[_7270].x)), _7379.x) * 0.2820949852466583251953125) + (float3(_7379.y, float2(as_type<half2>(_1281._m0[_7270].z))) * _6647)) + (float3(float2(as_type<half2>(_1281._m0[_7270].w)), _7388.x) * _6650)) + (float3(_7388.y, float2(as_type<half2>(_1281._m0[_7363].y))) * _6653)) + (float3(float2(as_type<half2>(_1281._m0[_7363].z)), _7397.x) * _6661)) + (float3(_7397.y, float2(as_type<half2>(_1281._m0[_7367].x))) * _6667)) + (float3(float2(as_type<half2>(_1281._m0[_7367].y)), _7406.x) * _6675)) + (float3(_7406.y, float2(as_type<half2>(_1281._m0[_7367].w))) * _6681);
                int3 _7522 = min((_6288 + int3(1, 1, 0)), _6714);
                int _7539 = _6544 + ((_7522.x + (_6720 * (_7522.y + (_6724 * _7522.z)))) * 4);
                float3 _7560 = (((((float3(_7522) + float3(0.5)) / _6240) * _6229) * 2.0) - _6229) - _6467;
                float _7570 = dot(_7560 * rsqrt(fast::max(dot(_7560, _7560), 1.0000000133514319600180897396058e-10)), _6567) + 1.0;
                float _7576 = _6292.x * _6292.y;
                int _7602 = _7539 + 3;
                float _7588 = ((_7576 * _6771) * ((0.25 * (_7570 * _7570)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_7602])[1u])).y > 0.5);
                int _7632 = _7539 + 1;
                int _7636 = _7539 + 2;
                float2 _7648 = float2(as_type<half2>(_1281._m0[_7539].y));
                float2 _7657 = float2(as_type<half2>(_1281._m0[_7632].x));
                float2 _7666 = float2(as_type<half2>(_1281._m0[_7632].w));
                float2 _7675 = float2(as_type<half2>(_1281._m0[_7636].z));
                float3 _7763 = (((((((float3(float2(as_type<half2>(_1281._m0[_7539].x)), _7648.x) * 0.2820949852466583251953125) + (float3(_7648.y, float2(as_type<half2>(_1281._m0[_7539].z))) * _6647)) + (float3(float2(as_type<half2>(_1281._m0[_7539].w)), _7657.x) * _6650)) + (float3(_7657.y, float2(as_type<half2>(_1281._m0[_7632].y))) * _6653)) + (float3(float2(as_type<half2>(_1281._m0[_7632].z)), _7666.x) * _6661)) + (float3(_7666.y, float2(as_type<half2>(_1281._m0[_7636].x))) * _6667)) + (float3(float2(as_type<half2>(_1281._m0[_7636].y)), _7675.x) * _6675)) + (float3(_7675.y, float2(as_type<half2>(_1281._m0[_7636].w))) * _6681);
                int3 _7791 = min((_6288 + int3(0, 0, 1)), _6714);
                int _7808 = _6544 + ((_7791.x + (_6720 * (_7791.y + (_6724 * _7791.z)))) * 4);
                float3 _7829 = (((((float3(_7791) + float3(0.5)) / _6240) * _6229) * 2.0) - _6229) - _6467;
                float _7839 = dot(_7829 * rsqrt(fast::max(dot(_7829, _7829), 1.0000000133514319600180897396058e-10)), _6567) + 1.0;
                int _7871 = _7808 + 3;
                float _7857 = ((_6769 * _6292.z) * ((0.25 * (_7839 * _7839)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_7871])[1u])).y > 0.5);
                int _7901 = _7808 + 1;
                int _7905 = _7808 + 2;
                float2 _7917 = float2(as_type<half2>(_1281._m0[_7808].y));
                float2 _7926 = float2(as_type<half2>(_1281._m0[_7901].x));
                float2 _7935 = float2(as_type<half2>(_1281._m0[_7901].w));
                float2 _7944 = float2(as_type<half2>(_1281._m0[_7905].z));
                float3 _8032 = (((((((float3(float2(as_type<half2>(_1281._m0[_7808].x)), _7917.x) * 0.2820949852466583251953125) + (float3(_7917.y, float2(as_type<half2>(_1281._m0[_7808].z))) * _6647)) + (float3(float2(as_type<half2>(_1281._m0[_7808].w)), _7926.x) * _6650)) + (float3(_7926.y, float2(as_type<half2>(_1281._m0[_7901].y))) * _6653)) + (float3(float2(as_type<half2>(_1281._m0[_7901].z)), _7935.x) * _6661)) + (float3(_7935.y, float2(as_type<half2>(_1281._m0[_7905].x))) * _6667)) + (float3(float2(as_type<half2>(_1281._m0[_7905].y)), _7944.x) * _6675)) + (float3(_7944.y, float2(as_type<half2>(_1281._m0[_7905].w))) * _6681);
                float4 _6359 = (((float4((_6956 + (float3(float2(as_type<half2>(_1281._m0[_6795].x)), float2(as_type<half2>(_1281._m0[_6795].y)).x) * _6695)) * _6781, _6781) + float4((_7225 + (float3(float2(as_type<half2>(_1281._m0[_7064].x)), float2(as_type<half2>(_1281._m0[_7064].y)).x) * _6695)) * _7050, _7050)) + float4((_7494 + (float3(float2(as_type<half2>(_1281._m0[_7333].x)), float2(as_type<half2>(_1281._m0[_7333].y)).x) * _6695)) * _7319, _7319)) + float4((_7763 + (float3(float2(as_type<half2>(_1281._m0[_7602].x)), float2(as_type<half2>(_1281._m0[_7602].y)).x) * _6695)) * _7588, _7588)) + float4((_8032 + (float3(float2(as_type<half2>(_1281._m0[_7871].x)), float2(as_type<half2>(_1281._m0[_7871].y)).x) * _6695)) * _7857, _7857);
                int3 _8060 = min((_6288 + int3(1, 0, 1)), _6714);
                int _8077 = _6544 + ((_8060.x + (_6720 * (_8060.y + (_6724 * _8060.z)))) * 4);
                float3 _8098 = (((((float3(_8060) + float3(0.5)) / _6240) * _6229) * 2.0) - _6229) - _6467;
                float _8108 = dot(_8098 * rsqrt(fast::max(dot(_8098, _8098), 1.0000000133514319600180897396058e-10)), _6567) + 1.0;
                int _8140 = _8077 + 3;
                float _8126 = ((_7038 * _6292.z) * ((0.25 * (_8108 * _8108)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_8140])[1u])).y > 0.5);
                int _8170 = _8077 + 1;
                int _8174 = _8077 + 2;
                float2 _8186 = float2(as_type<half2>(_1281._m0[_8077].y));
                float2 _8195 = float2(as_type<half2>(_1281._m0[_8170].x));
                float2 _8204 = float2(as_type<half2>(_1281._m0[_8170].w));
                float2 _8213 = float2(as_type<half2>(_1281._m0[_8174].z));
                float3 _8301 = (((((((float3(float2(as_type<half2>(_1281._m0[_8077].x)), _8186.x) * 0.2820949852466583251953125) + (float3(_8186.y, float2(as_type<half2>(_1281._m0[_8077].z))) * _6647)) + (float3(float2(as_type<half2>(_1281._m0[_8077].w)), _8195.x) * _6650)) + (float3(_8195.y, float2(as_type<half2>(_1281._m0[_8170].y))) * _6653)) + (float3(float2(as_type<half2>(_1281._m0[_8170].z)), _8204.x) * _6661)) + (float3(_8204.y, float2(as_type<half2>(_1281._m0[_8174].x))) * _6667)) + (float3(float2(as_type<half2>(_1281._m0[_8174].y)), _8213.x) * _6675)) + (float3(_8213.y, float2(as_type<half2>(_1281._m0[_8174].w))) * _6681);
                int3 _8329 = min((_6288 + int3(0, 1, 1)), _6714);
                int _8346 = _6544 + ((_8329.x + (_6720 * (_8329.y + (_6724 * _8329.z)))) * 4);
                float3 _8367 = (((((float3(_8329) + float3(0.5)) / _6240) * _6229) * 2.0) - _6229) - _6467;
                float _8377 = dot(_8367 * rsqrt(fast::max(dot(_8367, _8367), 1.0000000133514319600180897396058e-10)), _6567) + 1.0;
                int _8409 = _8346 + 3;
                float _8395 = ((_7307 * _6292.z) * ((0.25 * (_8377 * _8377)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_8409])[1u])).y > 0.5);
                int _8439 = _8346 + 1;
                int _8443 = _8346 + 2;
                float2 _8455 = float2(as_type<half2>(_1281._m0[_8346].y));
                float2 _8464 = float2(as_type<half2>(_1281._m0[_8439].x));
                float2 _8473 = float2(as_type<half2>(_1281._m0[_8439].w));
                float2 _8482 = float2(as_type<half2>(_1281._m0[_8443].z));
                float3 _8570 = (((((((float3(float2(as_type<half2>(_1281._m0[_8346].x)), _8455.x) * 0.2820949852466583251953125) + (float3(_8455.y, float2(as_type<half2>(_1281._m0[_8346].z))) * _6647)) + (float3(float2(as_type<half2>(_1281._m0[_8346].w)), _8464.x) * _6650)) + (float3(_8464.y, float2(as_type<half2>(_1281._m0[_8439].y))) * _6653)) + (float3(float2(as_type<half2>(_1281._m0[_8439].z)), _8473.x) * _6661)) + (float3(_8473.y, float2(as_type<half2>(_1281._m0[_8443].x))) * _6667)) + (float3(float2(as_type<half2>(_1281._m0[_8443].y)), _8482.x) * _6675)) + (float3(_8482.y, float2(as_type<half2>(_1281._m0[_8443].w))) * _6681);
                int3 _8598 = min((_6288 + int3(1)), _6714);
                int _8615 = _6544 + ((_8598.x + (_6720 * (_8598.y + (_6724 * _8598.z)))) * 4);
                float3 _8636 = (((((float3(_8598) + float3(0.5)) / _6240) * _6229) * 2.0) - _6229) - _6467;
                float _8646 = dot(_8636 * rsqrt(fast::max(dot(_8636, _8636), 1.0000000133514319600180897396058e-10)), _6567) + 1.0;
                int _8678 = _8615 + 3;
                float _8664 = ((_7576 * _6292.z) * ((0.25 * (_8646 * _8646)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_8678])[1u])).y > 0.5);
                int _8708 = _8615 + 1;
                int _8712 = _8615 + 2;
                float2 _8724 = float2(as_type<half2>(_1281._m0[_8615].y));
                float2 _8733 = float2(as_type<half2>(_1281._m0[_8708].x));
                float2 _8742 = float2(as_type<half2>(_1281._m0[_8708].w));
                float2 _8751 = float2(as_type<half2>(_1281._m0[_8712].z));
                float3 _8839 = (((((((float3(float2(as_type<half2>(_1281._m0[_8615].x)), _8724.x) * 0.2820949852466583251953125) + (float3(_8724.y, float2(as_type<half2>(_1281._m0[_8615].z))) * _6647)) + (float3(float2(as_type<half2>(_1281._m0[_8615].w)), _8733.x) * _6650)) + (float3(_8733.y, float2(as_type<half2>(_1281._m0[_8708].y))) * _6653)) + (float3(float2(as_type<half2>(_1281._m0[_8708].z)), _8742.x) * _6661)) + (float3(_8742.y, float2(as_type<half2>(_1281._m0[_8712].x))) * _6667)) + (float3(float2(as_type<half2>(_1281._m0[_8712].y)), _8751.x) * _6675)) + (float3(_8751.y, float2(as_type<half2>(_1281._m0[_8712].w))) * _6681);
                float4 _6398 = ((_6359 + float4((_8301 + (float3(float2(as_type<half2>(_1281._m0[_8140].x)), float2(as_type<half2>(_1281._m0[_8140].y)).x) * _6695)) * _8126, _8126)) + float4((_8570 + (float3(float2(as_type<half2>(_1281._m0[_8409].x)), float2(as_type<half2>(_1281._m0[_8409].y)).x) * _6695)) * _8395, _8395)) + float4((_8839 + (float3(float2(as_type<half2>(_1281._m0[_8678].x)), float2(as_type<half2>(_1281._m0[_8678].y)).x) * _6695)) * _8664, _8664);
                float _6402 = _6398.w;
                float3 _17648;
                if (_6402 > 9.9999997473787516355514526367188e-06)
                {
                    _17648 = mix(_17244, (fast::max(_6398.xyz, float3(0.0)) / float3(_6402)) * _6538.z, float3(_17610));
                }
                else
                {
                    _17648 = _17244;
                }
                _17647 = _17648;
            }
            _17245 = _17244;
        }
        else
        {
            _17245 = _17240;
        }
        float3 _3805 = (_16693 * ((_17245 * _17018) + ((_3699 * fast::max(_3739, 0.0)) * _16733))) + ((_3699 * ((powr(fast::max(dot(_16699, _3662), 0.0), _2876._m1.w) * _2876._m1.z) * step(0.0, _3739))) * _16733);
        float3 _17260;
        if (_283._m13.w > 0.5)
        {
            float2 _8877 = fast::clamp(floor(gl_FragCoord.xy * _283._m12.xy), float2(0.0), _283._m13.xy - float2(1.0));
            uint _8905 = uint((((fast::clamp(floor((log2(fast::max(dot(_283._m11.xyz, in.m_3037) + _283._m11.w, 9.9999999747524270787835121154785e-07)) * _283._m12.z) + _283._m12.w), 0.0, _283._m13.z - 1.0) * _283._m13.y) + _8877.y) * _283._m13.x) + _8877.x);
            uint _8907 = _8905 >> uint(2);
            uint _8909 = _8905 & 3u;
            uint _8913 = _3167._m0[_8907][_8909] & 65535u;
            uint _8915 = _3167._m0[_8907][_8909] >> uint(16);
            float3 _17261;
            _17261 = _3805;
            float3 _3885;
            spvUnsafeArray<float2, 3> _9323;
            spvUnsafeArray<float2, 3> _9324;
            spvUnsafeArray<float2, 3> _9536;
            spvUnsafeArray<float2, 3> _9537;
            for (uint _17258 = _8913; _17258 < (_8913 + _8915); _17261 = _3885, _17258++)
            {
                uint _8921 = _17258 / 3u;
                uint _8934 = (_3188._m0[_8921 >> uint(2)][_8921 & 3u] >> ((_17258 - (_8921 * 3u)) * 10u)) & 1023u;
                float3 _8951 = _3030._m0[_8934].xyz - in.m_3037;
                float _8954 = dot(_8951, _8951);
                float _8958 = _8954 * _3030._m0[_8934].w;
                float _8963 = fast::clamp(1.0 - (_8958 * _8958), 0.0, 1.0);
                float3 _8968 = _8951 * rsqrt(fast::max(_8954, 9.9999999392252902907785028219223e-09));
                float _8986 = fast::clamp((dot(-_8968, _3073._m0[_8934].xyz) * _3065._m0[_8934].w) + _3073._m0[_8934].w, 0.0, 1.0);
                float3 _8999 = _3065._m0[_8934].xyz * ((((_8963 * _8963) * _8986) * _8986) / fast::max(_8954, 9.9999997473787516355514526367188e-05));
                float3 _17575;
                if (_3673)
                {
                    float _17521;
                    do
                    {
                        uint _9035 = uint(_283._m21.z);
                        if (_8934 < _9035)
                        {
                            float _9057 = _283._m26[_8934].z * fast::max((_283._m15[_8934] * float4(in.m_3037, 1.0)).w, 0.0);
                            float4 _9081 = _283._m15[_8934] * float4((in.m_3037 + (_3668 * (_9057 * _283._m25.x))) + (_8968 * (_9057 * _283._m25.y)), 1.0);
                            float _9083 = _9081.w;
                            if (_9083 <= 0.0)
                            {
                                _17521 = 1.0;
                                break;
                            }
                            float3 _9092 = _9081.xyz / float3(_9083);
                            float _9094 = _9092.x;
                            bool _9095 = _9094 < 0.0;
                            bool _9102;
                            if (!_9095)
                            {
                                _9102 = _9094 > 1.0;
                            }
                            else
                            {
                                _9102 = _9095;
                            }
                            bool _9109;
                            if (!_9102)
                            {
                                _9109 = _9092.y < 0.0;
                            }
                            else
                            {
                                _9109 = _9102;
                            }
                            bool _9116;
                            if (!_9109)
                            {
                                _9116 = _9092.y > 1.0;
                            }
                            else
                            {
                                _9116 = _9109;
                            }
                            bool _9123;
                            if (!_9116)
                            {
                                _9123 = _9092.z > 1.0;
                            }
                            else
                            {
                                _9123 = _9116;
                            }
                            if (_9123)
                            {
                                _17521 = 1.0;
                                break;
                            }
                            float _9129 = _9092.z;
                            float2 _9295 = _283._m22.xy * 0.5;
                            float2 _9300 = _283._m26[_8934].xy + (_9092.xy * _283._m23.zw);
                            float4 _9313 = float4(_283._m26[_8934].xy + _9295, (_283._m26[_8934].xy + _283._m23.zw) - _9295);
                            float _17520;
                            do
                            {
                                int _9339 = int(_283._m22.z);
                                if (_9339 <= 0)
                                {
                                    float2 _9349 = fast::clamp(_9300, _9313.xy, _9313.zw);
                                    _17520 = spvDepthCast(_303).sample_compare(_303Smplr, float3(_9349, _9129).xy, _9129);
                                    break;
                                }
                                float2 _9362 = (_9300 / _283._m22.xy) + float2(0.5);
                                float2 _9363 = floor(_9362);
                                float2 _9368 = _9362 - _9363;
                                float2 _9371 = _9363 - float2(0.5);
                                bool _9375 = _9339 == 1;
                                if (_9375)
                                {
                                    float2 _9378 = _9368 * 2.0;
                                    _9323[0] = float2(3.0) - _9378;
                                    _9323[1] = float2(1.0) + _9378;
                                    _9324[0] = ((float2(2.0) - _9368) / _9323[0]) - float2(1.0);
                                    _9324[1] = (_9368 / _9323[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _9405 = _9368 * 3.0;
                                    _9323[0] = float2(4.0) - _9405;
                                    _9323[1] = float2(7.0);
                                    _9323[2] = float2(1.0) + _9405;
                                    _9324[0] = ((float2(3.0) - (_9368 * 2.0)) / _9323[0]) - float2(2.0);
                                    _9324[1] = (float2(3.0) + _9368) / _9323[1];
                                    _9324[2] = (_9368 / _9323[2]) + float2(2.0);
                                }
                                int _17787 = _9375 ? 2 : 3;
                                int _17510;
                                float _17513;
                                _17513 = 0.0;
                                _17510 = 0;
                                float _17519;
                                for (; _17510 < _17787; _17513 = _17519, _17510++)
                                {
                                    _17519 = _17513;
                                    for (int _17516 = 0; _17516 < _17787; )
                                    {
                                        _17519 += ((_9323[_17516].x * _9323[_17510].y) * spvDepthCast(_303).sample_compare(_303Smplr, float3(fast::clamp(_283._m22.xy * (_9371 + float2(_9324[_17516].x, _9324[_17510].y)), _9313.xy, _9313.zw), _9129).xy, _9129));
                                        _17516++;
                                        continue;
                                    }
                                }
                                _17520 = _17513 * (_9375 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _17521 = _17520;
                            break;
                        }
                        uint _9139 = _8934 - _9035;
                        if (_9139 >= uint(_283._m21.w))
                        {
                            _17521 = 1.0;
                            break;
                        }
                        float _9160 = _283._m27[_9139].w * length(in.m_3037 - _283._m27[_9139].xyz);
                        float3 _9178 = ((in.m_3037 + (_3668 * (_9160 * _283._m25.x))) + (_8968 * (_9160 * _283._m25.y))) - _283._m27[_9139].xyz;
                        float3 _9180 = abs(_9178);
                        float _9182 = _9180.x;
                        float _9184 = _9180.y;
                        bool _9185 = _9182 >= _9184;
                        bool _9193;
                        if (_9185)
                        {
                            _9193 = _9182 >= _9180.z;
                        }
                        else
                        {
                            _9193 = _9185;
                        }
                        float _17495;
                        int _17497;
                        if (_9193)
                        {
                            _17497 = (_9178.x > 0.0) ? 0 : 1;
                            _17495 = _9182;
                        }
                        else
                        {
                            float _9205 = _9180.z;
                            bool _9206 = _9184 >= _9205;
                            int _17498;
                            if (_9206)
                            {
                                _17498 = (_9178.y > 0.0) ? 2 : 3;
                            }
                            else
                            {
                                _17498 = (_9178.z > 0.0) ? 4 : 5;
                            }
                            _17497 = _17498;
                            _17495 = _9206 ? _9184 : _9205;
                        }
                        if (_17495 <= 0.0)
                        {
                            _17521 = 1.0;
                            break;
                        }
                        float2 _9243 = float2(dot(_9178, _961[_17497]), dot(_9178, _970[_17497])) / float2(_17495 * _283._m24.z);
                        float _9250 = _283._m28[_9139].z + (_283._m28[_9139].w / _17495);
                        if (_9250 > 1.0)
                        {
                            _17521 = 1.0;
                            break;
                        }
                        float2 _9268 = _283._m28[_9139].xy + (float2(float(spvSMod(_17497, 3)), float(_17497 / 3)) * _283._m24.xy);
                        float2 _9508 = _283._m22.xy * 0.5;
                        float2 _9513 = _9268 + (float2(0.5 + (0.5 * _9243.x), 0.5 - (0.5 * _9243.y)) * _283._m24.xy);
                        float4 _9526 = float4(_9268 + _9508, (_9268 + _283._m24.xy) - _9508);
                        float _17509;
                        do
                        {
                            int _9552 = int(_283._m22.z);
                            if (_9552 <= 0)
                            {
                                _17509 = spvDepthCast(_303).sample_compare(_303Smplr, float3(fast::clamp(_9513, _9526.xy, _9526.zw), _9250).xy, _9250);
                                break;
                            }
                            float2 _9575 = (_9513 / _283._m22.xy) + float2(0.5);
                            float2 _9576 = floor(_9575);
                            float2 _9581 = _9575 - _9576;
                            float2 _9584 = _9576 - float2(0.5);
                            bool _9588 = _9552 == 1;
                            if (_9588)
                            {
                                float2 _9591 = _9581 * 2.0;
                                _9536[0] = float2(3.0) - _9591;
                                _9536[1] = float2(1.0) + _9591;
                                _9537[0] = ((float2(2.0) - _9581) / _9536[0]) - float2(1.0);
                                _9537[1] = (_9581 / _9536[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _9618 = _9581 * 3.0;
                                _9536[0] = float2(4.0) - _9618;
                                _9536[1] = float2(7.0);
                                _9536[2] = float2(1.0) + _9618;
                                _9537[0] = ((float2(3.0) - (_9581 * 2.0)) / _9536[0]) - float2(2.0);
                                _9537[1] = (float2(3.0) + _9581) / _9536[1];
                                _9537[2] = (_9581 / _9536[2]) + float2(2.0);
                            }
                            int _17790 = _9588 ? 2 : 3;
                            int _17499;
                            float _17502;
                            _17502 = 0.0;
                            _17499 = 0;
                            float _17508;
                            for (; _17499 < _17790; _17502 = _17508, _17499++)
                            {
                                _17508 = _17502;
                                for (int _17505 = 0; _17505 < _17790; )
                                {
                                    _17508 += ((_9536[_17505].x * _9536[_17499].y) * spvDepthCast(_303).sample_compare(_303Smplr, float3(fast::clamp(_283._m22.xy * (_9584 + float2(_9537[_17505].x, _9537[_17499].y)), _9526.xy, _9526.zw), _9250).xy, _9250));
                                    _17505++;
                                    continue;
                                }
                            }
                            _17509 = _17502 * (_9588 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _17521 = _17509;
                        break;
                    } while(false);
                    _17575 = _8999 * _17521;
                }
                else
                {
                    _17575 = _8999;
                }
                float _3856 = dot(_16699, _8968);
                _3885 = _17261 + (((_16693 * fast::max(_3856, 0.0)) * _17575) + (_17575 * ((powr(fast::max(dot(_16699, fast::normalize(_8968 + _3657)), 0.0), _2876._m1.w) * _2876._m1.z) * step(0.0, _3856))));
            }
            _17260 = _17261;
        }
        else
        {
            _17260 = _3805;
        }
        _17329 = _17245;
        _17259 = _17260;
    }
    else
    {
        float4 _3895 = _3890.sample(_2533, _3419);
        float _3902 = fast::clamp(_2876._m4.x * _3895.z, 0.0, 1.0);
        float _3910 = fast::clamp(_2876._m4.y * _3895.y, 0.04500000178813934326171875, 1.0);
        float _16689;
        float _16694;
        if (_16630 > 0.0)
        {
            _16694 = mix(_3902, _16663.y, _16630);
            _16689 = mix(_3910, fast::max(_16663.x, 0.04500000178813934326171875), _16630);
        }
        else
        {
            _16694 = _3902;
            _16689 = _3910;
        }
        float _3929 = _16689 * _16689;
        float3 _3934 = _16693 * (1.0 - _16694);
        float3 _3940 = mix(float3(0.039999999105930328369140625), _16693, float3(_16694));
        bool _3944 = _16509 > 0.0;
        float3 _16722;
        if (_3944)
        {
            float3 _3949 = dfdx(in.m_3037);
            float3 _3951 = dfdy(in.m_3037);
            float3 _3952 = cross(_3949, _3951);
            float3 _16723;
            if (dot(_3952, _3952) > 9.9999996826552253889678874634872e-21)
            {
                _16723 = fast::normalize((fast::normalize(_3952) * ((dot(_3952, _3657) < 0.0) ? (-1.0) : 1.0)) + (_16699 - _3513));
            }
            else
            {
                _16723 = _16699;
            }
            _16722 = _16723;
        }
        else
        {
            _16722 = _16699;
        }
        float _3978 = fast::max(dot(_16722, _3657), 9.9999997473787516355514526367188e-05);
        float _3987 = dot(_16722, _3650);
        float _3988 = fast::clamp(_3987, 0.0, 1.0);
        float _3993 = fast::clamp(dot(_16722, _3662), 0.0, 1.0);
        float _3998 = fast::clamp(dot(_3657, _3662), 0.0, 1.0);
        float _16726;
        float _16727;
        if (_3944)
        {
            _16727 = fast::max(_3978, 0.5);
            _16726 = fast::max(_3998, 0.5);
        }
        else
        {
            _16727 = _3978;
            _16726 = _3998;
        }
        float3 _9720 = float3(1.0) - _3940;
        float3 _9723 = _3940 + (_9720 * powr(1.0 - _16726, 5.0));
        float _9730 = _3929 * _3929;
        float _9735 = _9730 - 1.0;
        float _9737 = ((_3993 * _3993) * _9735) + 1.0;
        float _9757 = 1.0 - _9730;
        float _9761 = sqrt(((_16727 * _16727) * _9757) + _9730);
        float3 _4044 = (((((float3(1.0) - _9723) * _3934) * fast::clamp(dot(_16699, _3650), 0.0, 1.0)) + (((_9723 * ((_9730 / ((3.1415927410125732421875 * _9737) * _9737)) * (0.5 / fast::max((_3988 * _9761) + (_16727 * sqrt(((_3988 * _3988) * _9757) + _9730)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875) * _3988)) * _3699) * _16733;
        float3 _17055;
        if (_3944)
        {
            _17055 = _4044 + (((((_3934 * _3699) * _16733) * _16509) * fast::clamp(-_3987, 0.0, 1.0)) * (0.3499999940395355224609375 + (0.64999997615814208984375 * powr(fast::clamp(dot(-_3657, _3650), 0.0, 1.0), 3.0))));
        }
        else
        {
            _17055 = _4044;
        }
        float3 _16762;
        float3 _16789;
        float2 _16966;
        if (_283._m29.x > 0.5)
        {
            float4 _9794 = _2632.sample(_2634, (((float2(_16727, _16689) * 31.0) + float2(0.5)) * float2(0.03125)));
            float _9853 = (_283._m29.z * _16699.x) - (_283._m29.w * _16699.z);
            float _9866 = (_283._m29.w * _16699.x) + (_283._m29.z * _16699.z);
            float _9884 = 1.09254801273345947265625 * _9853;
            spvUnsafeArray<float, 9> _15356 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _16699.y, 0.48860299587249755859375 * _9866, 0.48860299587249755859375 * _9853, _9884 * _16699.y, (1.09254801273345947265625 * _16699.y) * _9866, 0.3153919875621795654296875 * (((3.0 * _9866) * _9866) - 1.0), _9884 * _9866, 0.546274006366729736328125 * ((_9853 * _9853) - (_16699.y * _16699.y)) });
            spvUnsafeArray<float, 9> _9798 = _15356;
            float3 _16745;
            _16745 = float3(0.0);
            for (int _16744 = 0; _16744 < 9; )
            {
                _16745 += (_2531.read(uint2((int2(496, 256) + int2(_16744, 0))), 0).xyz * _9798[_16744]);
                _16744++;
                continue;
            }
            float3 _4096 = reflect(-_3657, _16722);
            float _9979 = _4096.x;
            float _9984 = _4096.z;
            float2 _10016 = float2((precise::atan2((_283._m29.z * _9979) - (_283._m29.w * _9984), -((_283._m29.w * _9979) + (_283._m29.z * _9984))) * 0.15915493667125701904296875) + 0.5, acos(fast::clamp(_4096.y, -1.0, 1.0)) * 0.3183098733425140380859375);
            float _9948 = _16689 * 5.0;
            int _9951 = min(int(_9948), 4);
            float2 _10037 = (_10016 * float2(_2588[_9951].zw)) - float2(0.5);
            float2 _10039 = floor(_10037);
            float2 _10042 = _10037 - _10039;
            int _10045 = int(_10039.x);
            int _10048 = int(_10039.y);
            int _16748;
            if (_10045 < 0)
            {
                _16748 = _10045 + _2588[_9951].z;
            }
            else
            {
                _16748 = _10045;
            }
            int _16749;
            if (_16748 >= _2588[_9951].z)
            {
                _16749 = _16748 - _2588[_9951].z;
            }
            else
            {
                _16749 = _16748;
            }
            int _10068 = _16749 + 1;
            int _17791 = (_10068 == _2588[_9951].z) ? 0 : _10068;
            int _10083 = min((_10048 + 1), (_2588[_9951].w - 1));
            int _10085 = max(_10048, 0);
            float3 _10138 = float3(_10042.x);
            int _9958 = _9951 + 1;
            float2 _10170 = (_10016 * float2(_2588[_9958].zw)) - float2(0.5);
            float2 _10172 = floor(_10170);
            float2 _10175 = _10170 - _10172;
            int _10178 = int(_10172.x);
            int _10181 = int(_10172.y);
            int _16755;
            if (_10178 < 0)
            {
                _16755 = _10178 + _2588[_9958].z;
            }
            else
            {
                _16755 = _10178;
            }
            int _16756;
            if (_16755 >= _2588[_9958].z)
            {
                _16756 = _16755 - _2588[_9958].z;
            }
            else
            {
                _16756 = _16755;
            }
            int _10201 = _16756 + 1;
            int _17792 = (_10201 == _2588[_9958].z) ? 0 : _10201;
            int _10216 = min((_10181 + 1), (_2588[_9958].w - 1));
            int _10218 = max(_10181, 0);
            float3 _10271 = float3(_10175.x);
            float3 _9973 = mix(mix(mix(_2531.read(uint2((_2588[_9951].xy + int2(_16749, _10085))), 0).xyz, _2531.read(uint2((_2588[_9951].xy + int2(_17791, _10085))), 0).xyz, _10138), mix(_2531.read(uint2((_2588[_9951].xy + int2(_16749, _10083))), 0).xyz, _2531.read(uint2((_2588[_9951].xy + int2(_17791, _10083))), 0).xyz, _10138), float3(_10042.y)), mix(mix(_2531.read(uint2((_2588[_9958].xy + int2(_16756, _10218))), 0).xyz, _2531.read(uint2((_2588[_9958].xy + int2(_17792, _10218))), 0).xyz, _10271), mix(_2531.read(uint2((_2588[_9958].xy + int2(_16756, _10216))), 0).xyz, _2531.read(uint2((_2588[_9958].xy + int2(_17792, _10216))), 0).xyz, _10271), float3(_10175.y)), float3(_9948 - float(_9951))) * _283._m29.y;
            _16966 = _9794.xy;
            _16789 = _9973;
            _16762 = fast::max(_16745, float3(0.0)) * _283._m29.y;
        }
        else
        {
            float4 _10289 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * _16689) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);
            float _10291 = _10289.x;
            float3 _10326 = mix(_283._m9.xyz, _283._m8.xyz, float3((_16699.y * 0.5) + 0.5)) * _283._m8.w;
            _16966 = (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_10291 * _10291, exp2((-9.27999973297119140625) * _16727)) * _10291) + _10289.y)) + _10289.zw;
            _16789 = mix(mix(_283._m9.xyz, _283._m8.xyz, float3((reflect(-_3657, _16722).y * 0.5) + 0.5)) * _283._m8.w, _10326, float3(_16689));
            _16762 = _10326;
        }
        float3 _16889;
        if (_283._m34.y > 0.5)
        {
            int _10463 = int(_283._m34.y);
            int _10466 = int(_283._m34.x);
            float3 _16778;
            _16778 = _16762;
            float3 _17617;
            for (int _16777 = 0; _16777 < _10463; _16778 = _17617, _16777++)
            {
                int _10478 = 8 * (_10466 + _16777);
                float4 _10687 = as_type<float4>(_1281._m0[_10478 + 3]);
                float4 _10731 = as_type<float4>(_1281._m0[_10478]);
                float4 _10737 = as_type<float4>(_1281._m0[_10478 + 1]);
                float4 _10743 = as_type<float4>(_1281._m0[_10478 + 2]);
                float3 _10705 = _10731.xyz;
                float _10709 = _10731.w;
                float3 _10712 = _10737.xyz;
                float _10716 = _10737.w;
                float3 _10719 = _10743.xyz;
                float _10723 = _10743.w;
                float3 _10725 = float3(dot(_10705, in.m_3037) + _10709, dot(_10712, in.m_3037) + _10716, dot(_10719, in.m_3037) + _10723);
                float3 _10487 = _10687.xyz;
                float _10489 = _10687.w;
                float _17233;
                do
                {
                    float3 _10755 = _10487 - abs(_10725);
                    float _10763 = fast::min(_10755.x, fast::min(_10755.y, _10755.z));
                    if (_10763 <= 0.0)
                    {
                        _17233 = 0.0;
                        break;
                    }
                    if (_10489 <= 0.0)
                    {
                        _17233 = 1.0;
                        break;
                    }
                    float _10775 = fast::min(_10763 / _10489, 1.0);
                    _17233 = (_10775 * _10775) * (3.0 - (2.0 * _10775));
                    break;
                } while(false);
                if (_17233 <= 0.0)
                {
                    _17617 = _16778;
                    continue;
                }
                float3 _10498 = as_type<float4>(_1281._m0[_10478 + 4]).xyz;
                float4 _10796 = as_type<float4>(_1281._m0[_10478 + 5]);
                int _10802 = int(((device uint*)&_1281._m0[_10478 + 6])[0u]);
                float _10812 = dot(_10705, _16699);
                float _10818 = dot(_10712, _16699);
                float _10824 = dot(_10719, _16699);
                float3 _10825 = float3(_10812, _10818, _10824);
                float3 _10518 = (in.m_3037 + (_16699 * _10796.x)) + (_3657 * _10796.y);
                float3 _10537 = fast::clamp((((float3(dot(_10705, _10518) + _10709, dot(_10712, _10518) + _10716, dot(_10719, _10518) + _10723) + _10487) / fast::max(_10487 * 2.0, float3(9.9999999747524270787835121154785e-07))) * _10498) - float3(0.5), float3(0.0), _10498 - float3(1.0));
                int3 _10539 = int3(_10498);
                int3 _10546 = min(int3(_10537), max((_10539 - int3(2)), int3(0)));
                float3 _10550 = _10537 - float3(_10546);
                float _10905 = 0.48860299587249755859375 * _10818;
                float _10908 = 0.48860299587249755859375 * _10824;
                float _10911 = 0.48860299587249755859375 * _10812;
                float _10916 = 1.09254801273345947265625 * _10812;
                float _10919 = _10916 * _10818;
                float _10925 = (1.09254801273345947265625 * _10818) * _10824;
                float _10933 = 0.3153919875621795654296875 * (((3.0 * _10824) * _10824) - 1.0);
                float _10939 = _10916 * _10824;
                float _10953 = 0.546274006366729736328125 * ((_10812 * _10812) - (_10818 * _10818));
                int3 _10972 = _10539 - int3(1);
                int3 _10973 = min(_10546, _10972);
                int _10978 = _10539.x;
                int _10982 = _10539.y;
                int _10990 = _10802 + ((_10973.x + (_10978 * (_10973.y + (_10982 * _10973.z)))) * 4);
                float3 _10993 = float3(1.0) - _10550;
                float3 _11011 = (((((float3(_10973) + float3(0.5)) / _10498) * _10487) * 2.0) - _10487) - _10725;
                float _11021 = dot(_11011 * rsqrt(fast::max(dot(_11011, _11011), 1.0000000133514319600180897396058e-10)), _10825) + 1.0;
                float _11024 = _10993.x;
                float _11026 = _10993.y;
                float _11027 = _11024 * _11026;
                float _11029 = _10993.z;
                int _11053 = _10990 + 3;
                float _11039 = ((_11027 * _11029) * ((0.25 * (_11021 * _11021)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_11053])[1u])).y > 0.5);
                int _11083 = _10990 + 1;
                int _11087 = _10990 + 2;
                float2 _11099 = float2(as_type<half2>(_1281._m0[_10990].y));
                float2 _11108 = float2(as_type<half2>(_1281._m0[_11083].x));
                float2 _11117 = float2(as_type<half2>(_1281._m0[_11083].w));
                float2 _11126 = float2(as_type<half2>(_1281._m0[_11087].z));
                float3 _11214 = (((((((float3(float2(as_type<half2>(_1281._m0[_10990].x)), _11099.x) * 0.2820949852466583251953125) + (float3(_11099.y, float2(as_type<half2>(_1281._m0[_10990].z))) * _10905)) + (float3(float2(as_type<half2>(_1281._m0[_10990].w)), _11108.x) * _10908)) + (float3(_11108.y, float2(as_type<half2>(_1281._m0[_11083].y))) * _10911)) + (float3(float2(as_type<half2>(_1281._m0[_11083].z)), _11117.x) * _10919)) + (float3(_11117.y, float2(as_type<half2>(_1281._m0[_11087].x))) * _10925)) + (float3(float2(as_type<half2>(_1281._m0[_11087].y)), _11126.x) * _10933)) + (float3(_11126.y, float2(as_type<half2>(_1281._m0[_11087].w))) * _10939);
                int3 _11242 = min((_10546 + int3(1, 0, 0)), _10972);
                int _11259 = _10802 + ((_11242.x + (_10978 * (_11242.y + (_10982 * _11242.z)))) * 4);
                float3 _11280 = (((((float3(_11242) + float3(0.5)) / _10498) * _10487) * 2.0) - _10487) - _10725;
                float _11290 = dot(_11280 * rsqrt(fast::max(dot(_11280, _11280), 1.0000000133514319600180897396058e-10)), _10825) + 1.0;
                float _11296 = _10550.x * _11026;
                int _11322 = _11259 + 3;
                float _11308 = ((_11296 * _11029) * ((0.25 * (_11290 * _11290)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_11322])[1u])).y > 0.5);
                int _11352 = _11259 + 1;
                int _11356 = _11259 + 2;
                float2 _11368 = float2(as_type<half2>(_1281._m0[_11259].y));
                float2 _11377 = float2(as_type<half2>(_1281._m0[_11352].x));
                float2 _11386 = float2(as_type<half2>(_1281._m0[_11352].w));
                float2 _11395 = float2(as_type<half2>(_1281._m0[_11356].z));
                float3 _11483 = (((((((float3(float2(as_type<half2>(_1281._m0[_11259].x)), _11368.x) * 0.2820949852466583251953125) + (float3(_11368.y, float2(as_type<half2>(_1281._m0[_11259].z))) * _10905)) + (float3(float2(as_type<half2>(_1281._m0[_11259].w)), _11377.x) * _10908)) + (float3(_11377.y, float2(as_type<half2>(_1281._m0[_11352].y))) * _10911)) + (float3(float2(as_type<half2>(_1281._m0[_11352].z)), _11386.x) * _10919)) + (float3(_11386.y, float2(as_type<half2>(_1281._m0[_11356].x))) * _10925)) + (float3(float2(as_type<half2>(_1281._m0[_11356].y)), _11395.x) * _10933)) + (float3(_11395.y, float2(as_type<half2>(_1281._m0[_11356].w))) * _10939);
                int3 _11511 = min((_10546 + int3(0, 1, 0)), _10972);
                int _11528 = _10802 + ((_11511.x + (_10978 * (_11511.y + (_10982 * _11511.z)))) * 4);
                float3 _11549 = (((((float3(_11511) + float3(0.5)) / _10498) * _10487) * 2.0) - _10487) - _10725;
                float _11559 = dot(_11549 * rsqrt(fast::max(dot(_11549, _11549), 1.0000000133514319600180897396058e-10)), _10825) + 1.0;
                float _11565 = _11024 * _10550.y;
                int _11591 = _11528 + 3;
                float _11577 = ((_11565 * _11029) * ((0.25 * (_11559 * _11559)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_11591])[1u])).y > 0.5);
                int _11621 = _11528 + 1;
                int _11625 = _11528 + 2;
                float2 _11637 = float2(as_type<half2>(_1281._m0[_11528].y));
                float2 _11646 = float2(as_type<half2>(_1281._m0[_11621].x));
                float2 _11655 = float2(as_type<half2>(_1281._m0[_11621].w));
                float2 _11664 = float2(as_type<half2>(_1281._m0[_11625].z));
                float3 _11752 = (((((((float3(float2(as_type<half2>(_1281._m0[_11528].x)), _11637.x) * 0.2820949852466583251953125) + (float3(_11637.y, float2(as_type<half2>(_1281._m0[_11528].z))) * _10905)) + (float3(float2(as_type<half2>(_1281._m0[_11528].w)), _11646.x) * _10908)) + (float3(_11646.y, float2(as_type<half2>(_1281._m0[_11621].y))) * _10911)) + (float3(float2(as_type<half2>(_1281._m0[_11621].z)), _11655.x) * _10919)) + (float3(_11655.y, float2(as_type<half2>(_1281._m0[_11625].x))) * _10925)) + (float3(float2(as_type<half2>(_1281._m0[_11625].y)), _11664.x) * _10933)) + (float3(_11664.y, float2(as_type<half2>(_1281._m0[_11625].w))) * _10939);
                int3 _11780 = min((_10546 + int3(1, 1, 0)), _10972);
                int _11797 = _10802 + ((_11780.x + (_10978 * (_11780.y + (_10982 * _11780.z)))) * 4);
                float3 _11818 = (((((float3(_11780) + float3(0.5)) / _10498) * _10487) * 2.0) - _10487) - _10725;
                float _11828 = dot(_11818 * rsqrt(fast::max(dot(_11818, _11818), 1.0000000133514319600180897396058e-10)), _10825) + 1.0;
                float _11834 = _10550.x * _10550.y;
                int _11860 = _11797 + 3;
                float _11846 = ((_11834 * _11029) * ((0.25 * (_11828 * _11828)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_11860])[1u])).y > 0.5);
                int _11890 = _11797 + 1;
                int _11894 = _11797 + 2;
                float2 _11906 = float2(as_type<half2>(_1281._m0[_11797].y));
                float2 _11915 = float2(as_type<half2>(_1281._m0[_11890].x));
                float2 _11924 = float2(as_type<half2>(_1281._m0[_11890].w));
                float2 _11933 = float2(as_type<half2>(_1281._m0[_11894].z));
                float3 _12021 = (((((((float3(float2(as_type<half2>(_1281._m0[_11797].x)), _11906.x) * 0.2820949852466583251953125) + (float3(_11906.y, float2(as_type<half2>(_1281._m0[_11797].z))) * _10905)) + (float3(float2(as_type<half2>(_1281._m0[_11797].w)), _11915.x) * _10908)) + (float3(_11915.y, float2(as_type<half2>(_1281._m0[_11890].y))) * _10911)) + (float3(float2(as_type<half2>(_1281._m0[_11890].z)), _11924.x) * _10919)) + (float3(_11924.y, float2(as_type<half2>(_1281._m0[_11894].x))) * _10925)) + (float3(float2(as_type<half2>(_1281._m0[_11894].y)), _11933.x) * _10933)) + (float3(_11933.y, float2(as_type<half2>(_1281._m0[_11894].w))) * _10939);
                int3 _12049 = min((_10546 + int3(0, 0, 1)), _10972);
                int _12066 = _10802 + ((_12049.x + (_10978 * (_12049.y + (_10982 * _12049.z)))) * 4);
                float3 _12087 = (((((float3(_12049) + float3(0.5)) / _10498) * _10487) * 2.0) - _10487) - _10725;
                float _12097 = dot(_12087 * rsqrt(fast::max(dot(_12087, _12087), 1.0000000133514319600180897396058e-10)), _10825) + 1.0;
                int _12129 = _12066 + 3;
                float _12115 = ((_11027 * _10550.z) * ((0.25 * (_12097 * _12097)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_12129])[1u])).y > 0.5);
                int _12159 = _12066 + 1;
                int _12163 = _12066 + 2;
                float2 _12175 = float2(as_type<half2>(_1281._m0[_12066].y));
                float2 _12184 = float2(as_type<half2>(_1281._m0[_12159].x));
                float2 _12193 = float2(as_type<half2>(_1281._m0[_12159].w));
                float2 _12202 = float2(as_type<half2>(_1281._m0[_12163].z));
                float3 _12290 = (((((((float3(float2(as_type<half2>(_1281._m0[_12066].x)), _12175.x) * 0.2820949852466583251953125) + (float3(_12175.y, float2(as_type<half2>(_1281._m0[_12066].z))) * _10905)) + (float3(float2(as_type<half2>(_1281._m0[_12066].w)), _12184.x) * _10908)) + (float3(_12184.y, float2(as_type<half2>(_1281._m0[_12159].y))) * _10911)) + (float3(float2(as_type<half2>(_1281._m0[_12159].z)), _12193.x) * _10919)) + (float3(_12193.y, float2(as_type<half2>(_1281._m0[_12163].x))) * _10925)) + (float3(float2(as_type<half2>(_1281._m0[_12163].y)), _12202.x) * _10933)) + (float3(_12202.y, float2(as_type<half2>(_1281._m0[_12163].w))) * _10939);
                float4 _10617 = (((float4((_11214 + (float3(float2(as_type<half2>(_1281._m0[_11053].x)), float2(as_type<half2>(_1281._m0[_11053].y)).x) * _10953)) * _11039, _11039) + float4((_11483 + (float3(float2(as_type<half2>(_1281._m0[_11322].x)), float2(as_type<half2>(_1281._m0[_11322].y)).x) * _10953)) * _11308, _11308)) + float4((_11752 + (float3(float2(as_type<half2>(_1281._m0[_11591].x)), float2(as_type<half2>(_1281._m0[_11591].y)).x) * _10953)) * _11577, _11577)) + float4((_12021 + (float3(float2(as_type<half2>(_1281._m0[_11860].x)), float2(as_type<half2>(_1281._m0[_11860].y)).x) * _10953)) * _11846, _11846)) + float4((_12290 + (float3(float2(as_type<half2>(_1281._m0[_12129].x)), float2(as_type<half2>(_1281._m0[_12129].y)).x) * _10953)) * _12115, _12115);
                int3 _12318 = min((_10546 + int3(1, 0, 1)), _10972);
                int _12335 = _10802 + ((_12318.x + (_10978 * (_12318.y + (_10982 * _12318.z)))) * 4);
                float3 _12356 = (((((float3(_12318) + float3(0.5)) / _10498) * _10487) * 2.0) - _10487) - _10725;
                float _12366 = dot(_12356 * rsqrt(fast::max(dot(_12356, _12356), 1.0000000133514319600180897396058e-10)), _10825) + 1.0;
                int _12398 = _12335 + 3;
                float _12384 = ((_11296 * _10550.z) * ((0.25 * (_12366 * _12366)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_12398])[1u])).y > 0.5);
                int _12428 = _12335 + 1;
                int _12432 = _12335 + 2;
                float2 _12444 = float2(as_type<half2>(_1281._m0[_12335].y));
                float2 _12453 = float2(as_type<half2>(_1281._m0[_12428].x));
                float2 _12462 = float2(as_type<half2>(_1281._m0[_12428].w));
                float2 _12471 = float2(as_type<half2>(_1281._m0[_12432].z));
                float3 _12559 = (((((((float3(float2(as_type<half2>(_1281._m0[_12335].x)), _12444.x) * 0.2820949852466583251953125) + (float3(_12444.y, float2(as_type<half2>(_1281._m0[_12335].z))) * _10905)) + (float3(float2(as_type<half2>(_1281._m0[_12335].w)), _12453.x) * _10908)) + (float3(_12453.y, float2(as_type<half2>(_1281._m0[_12428].y))) * _10911)) + (float3(float2(as_type<half2>(_1281._m0[_12428].z)), _12462.x) * _10919)) + (float3(_12462.y, float2(as_type<half2>(_1281._m0[_12432].x))) * _10925)) + (float3(float2(as_type<half2>(_1281._m0[_12432].y)), _12471.x) * _10933)) + (float3(_12471.y, float2(as_type<half2>(_1281._m0[_12432].w))) * _10939);
                int3 _12587 = min((_10546 + int3(0, 1, 1)), _10972);
                int _12604 = _10802 + ((_12587.x + (_10978 * (_12587.y + (_10982 * _12587.z)))) * 4);
                float3 _12625 = (((((float3(_12587) + float3(0.5)) / _10498) * _10487) * 2.0) - _10487) - _10725;
                float _12635 = dot(_12625 * rsqrt(fast::max(dot(_12625, _12625), 1.0000000133514319600180897396058e-10)), _10825) + 1.0;
                int _12667 = _12604 + 3;
                float _12653 = ((_11565 * _10550.z) * ((0.25 * (_12635 * _12635)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_12667])[1u])).y > 0.5);
                int _12697 = _12604 + 1;
                int _12701 = _12604 + 2;
                float2 _12713 = float2(as_type<half2>(_1281._m0[_12604].y));
                float2 _12722 = float2(as_type<half2>(_1281._m0[_12697].x));
                float2 _12731 = float2(as_type<half2>(_1281._m0[_12697].w));
                float2 _12740 = float2(as_type<half2>(_1281._m0[_12701].z));
                float3 _12828 = (((((((float3(float2(as_type<half2>(_1281._m0[_12604].x)), _12713.x) * 0.2820949852466583251953125) + (float3(_12713.y, float2(as_type<half2>(_1281._m0[_12604].z))) * _10905)) + (float3(float2(as_type<half2>(_1281._m0[_12604].w)), _12722.x) * _10908)) + (float3(_12722.y, float2(as_type<half2>(_1281._m0[_12697].y))) * _10911)) + (float3(float2(as_type<half2>(_1281._m0[_12697].z)), _12731.x) * _10919)) + (float3(_12731.y, float2(as_type<half2>(_1281._m0[_12701].x))) * _10925)) + (float3(float2(as_type<half2>(_1281._m0[_12701].y)), _12740.x) * _10933)) + (float3(_12740.y, float2(as_type<half2>(_1281._m0[_12701].w))) * _10939);
                int3 _12856 = min((_10546 + int3(1)), _10972);
                int _12873 = _10802 + ((_12856.x + (_10978 * (_12856.y + (_10982 * _12856.z)))) * 4);
                float3 _12894 = (((((float3(_12856) + float3(0.5)) / _10498) * _10487) * 2.0) - _10487) - _10725;
                float _12904 = dot(_12894 * rsqrt(fast::max(dot(_12894, _12894), 1.0000000133514319600180897396058e-10)), _10825) + 1.0;
                int _12936 = _12873 + 3;
                float _12922 = ((_11834 * _10550.z) * ((0.25 * (_12904 * _12904)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_12936])[1u])).y > 0.5);
                int _12966 = _12873 + 1;
                int _12970 = _12873 + 2;
                float2 _12982 = float2(as_type<half2>(_1281._m0[_12873].y));
                float2 _12991 = float2(as_type<half2>(_1281._m0[_12966].x));
                float2 _13000 = float2(as_type<half2>(_1281._m0[_12966].w));
                float2 _13009 = float2(as_type<half2>(_1281._m0[_12970].z));
                float3 _13097 = (((((((float3(float2(as_type<half2>(_1281._m0[_12873].x)), _12982.x) * 0.2820949852466583251953125) + (float3(_12982.y, float2(as_type<half2>(_1281._m0[_12873].z))) * _10905)) + (float3(float2(as_type<half2>(_1281._m0[_12873].w)), _12991.x) * _10908)) + (float3(_12991.y, float2(as_type<half2>(_1281._m0[_12966].y))) * _10911)) + (float3(float2(as_type<half2>(_1281._m0[_12966].z)), _13000.x) * _10919)) + (float3(_13000.y, float2(as_type<half2>(_1281._m0[_12970].x))) * _10925)) + (float3(float2(as_type<half2>(_1281._m0[_12970].y)), _13009.x) * _10933)) + (float3(_13009.y, float2(as_type<half2>(_1281._m0[_12970].w))) * _10939);
                float4 _10656 = ((_10617 + float4((_12559 + (float3(float2(as_type<half2>(_1281._m0[_12398].x)), float2(as_type<half2>(_1281._m0[_12398].y)).x) * _10953)) * _12384, _12384)) + float4((_12828 + (float3(float2(as_type<half2>(_1281._m0[_12667].x)), float2(as_type<half2>(_1281._m0[_12667].y)).x) * _10953)) * _12653, _12653)) + float4((_13097 + (float3(float2(as_type<half2>(_1281._m0[_12936].x)), float2(as_type<half2>(_1281._m0[_12936].y)).x) * _10953)) * _12922, _12922);
                float _10660 = _10656.w;
                float3 _17618;
                if (_10660 > 9.9999997473787516355514526367188e-06)
                {
                    _17618 = mix(_16778, (fast::max(_10656.xyz, float3(0.0)) / float3(_10660)) * _10796.z, float3(_17233));
                }
                else
                {
                    _17618 = _16778;
                }
                _17617 = _17618;
            }
            _16889 = _16778;
        }
        else
        {
            _16889 = _16762;
        }
        float3 _16911;
        if (_283._m34.x > 0.5)
        {
            float3 _4142 = reflect(-_3657, _16722);
            int _13145 = int(_283._m34.x);
            float _16801;
            float3 _16867;
            _16867 = float3(0.0);
            _16801 = 0.0;
            float _17628;
            float3 _17629;
            for (int _16800 = 0; _16800 < _13145; _16867 = _17629, _16801 = _17628, _16800++)
            {
                if (_16801 > 0.999000012874603271484375)
                {
                    break;
                }
                int _13157 = _16800 * 8;
                float4 _13272 = as_type<float4>(_1281._m0[_13157]);
                float4 _13278 = as_type<float4>(_1281._m0[_13157 + 1]);
                float4 _13284 = as_type<float4>(_1281._m0[_13157 + 2]);
                float3 _13246 = _13272.xyz;
                float3 _13253 = _13278.xyz;
                float3 _13260 = _13284.xyz;
                float3 _13266 = float3(dot(_13246, in.m_3037) + _13272.w, dot(_13253, in.m_3037) + _13278.w, dot(_13260, in.m_3037) + _13284.w);
                float4 _13290 = as_type<float4>(_1281._m0[_13157 + 3]);
                float _13168 = _13290.w;
                float _16802;
                do
                {
                    float3 _13302 = _13290.xyz - abs(_13266);
                    float _13310 = fast::min(_13302.x, fast::min(_13302.y, _13302.z));
                    if (_13310 <= 0.0)
                    {
                        _16802 = 0.0;
                        break;
                    }
                    if (_13168 <= 0.0)
                    {
                        _16802 = 1.0;
                        break;
                    }
                    float _13322 = fast::min(_13310 / _13168, 1.0);
                    _16802 = (_13322 * _13322) * (3.0 - (2.0 * _13322));
                    break;
                } while(false);
                if (_16802 <= 0.0)
                {
                    _17629 = _16867;
                    _17628 = _16801;
                    continue;
                }
                float4 _13337 = as_type<float4>(_1281._m0[_13157 + 4]);
                float4 _13343 = as_type<float4>(_1281._m0[_13157 + 5]);
                float3 _13366 = float3(dot(_13246, _4142), dot(_13253, _4142), dot(_13260, _4142));
                float3 _16804;
                if (_13337.w > 0.5)
                {
                    float3 _13190 = _13337.xyz;
                    float3 _13396 = -_13190;
                    float3 _13398 = fast::clamp(_13266, _13396, _13190);
                    float3 _13408 = step(float3(9.9999999747524270787835121154785e-07), abs(_13366));
                    float3 _13418 = mix(float3(1000000015047466219876688855040.0), (mix(_13396, _13190, step(float3(0.0), _13366)) - _13398) / mix(float3(9.9999999747524270787835121154785e-07), _13366, _13408), _13408);
                    float3 _13434 = (_13398 + (_13366 * fast::max(fast::min(_13418.x, fast::min(_13418.y, _13418.z)), 0.0))) - _13343.xyz;
                    float3 _16803;
                    if (dot(_13434, _13434) > 9.9999999600419720025001879548654e-13)
                    {
                        _16803 = fast::normalize(_13434);
                    }
                    else
                    {
                        _16803 = _13366;
                    }
                    _16804 = _16803;
                }
                else
                {
                    _16804 = _13366;
                }
                int _13451 = int(((device uint*)&_1281._m0[_13157 + 6])[0u]);
                float2 _13501 = float2((precise::atan2(_16804.x, -_16804.z) * 0.15915493667125701904296875) + 0.5, acos(fast::clamp(_16804.y, -1.0, 1.0)) * 0.3183098733425140380859375);
                float _13467 = _16689 * 5.0;
                int _13470 = min(int(_13467), 4);
                int _13541 = _13451 + _1353[_13470].x;
                float2 _13548 = (_13501 * float2(_1353[_13470].yz)) - float2(0.5);
                float2 _13550 = floor(_13548);
                float2 _13553 = _13548 - _13550;
                int _13556 = int(_13550.x);
                int _13559 = int(_13550.y);
                int _16805;
                if (_13556 < 0)
                {
                    _16805 = _13556 + _1353[_13470].y;
                }
                else
                {
                    _16805 = _13556;
                }
                int _16806;
                if (_16805 >= _1353[_13470].y)
                {
                    _16806 = _16805 - _1353[_13470].y;
                }
                else
                {
                    _16806 = _16805;
                }
                int _13579 = _16806 + 1;
                int _17793 = (_13579 == _1353[_13470].y) ? 0 : _13579;
                int _13647 = _13541 + (max(_13559, 0) * _1353[_13470].y);
                int _13649 = _13647 + _16806;
                int _13651 = _13649 >> 1;
                uint2 _16812;
                if ((_13649 & 1) == 0)
                {
                    _16812 = _1281._m0[_13651].xy;
                }
                else
                {
                    _16812 = _1281._m0[_13651].zw;
                }
                int _13687 = _13647 + _17793;
                int _13689 = _13687 >> 1;
                uint2 _16814;
                if ((_13687 & 1) == 0)
                {
                    _16814 = _1281._m0[_13689].xy;
                }
                else
                {
                    _16814 = _1281._m0[_13689].zw;
                }
                int _13723 = _13541 + (min((_13559 + 1), (_1353[_13470].z - 1)) * _1353[_13470].y);
                int _13725 = _13723 + _16806;
                int _13727 = _13725 >> 1;
                uint2 _16817;
                if ((_13725 & 1) == 0)
                {
                    _16817 = _1281._m0[_13727].xy;
                }
                else
                {
                    _16817 = _1281._m0[_13727].zw;
                }
                int _13763 = _13723 + _17793;
                int _13765 = _13763 >> 1;
                uint2 _16818;
                if ((_13763 & 1) == 0)
                {
                    _16818 = _1281._m0[_13765].xy;
                }
                else
                {
                    _16818 = _1281._m0[_13765].zw;
                }
                float3 _13625 = float3(_13553.x);
                int _13476 = _13470 + 1;
                int _13828 = _13451 + _1353[_13476].x;
                float2 _13835 = (_13501 * float2(_1353[_13476].yz)) - float2(0.5);
                float2 _13837 = floor(_13835);
                float2 _13840 = _13835 - _13837;
                int _13843 = int(_13837.x);
                int _13846 = int(_13837.y);
                int _16819;
                if (_13843 < 0)
                {
                    _16819 = _13843 + _1353[_13476].y;
                }
                else
                {
                    _16819 = _13843;
                }
                int _16820;
                if (_16819 >= _1353[_13476].y)
                {
                    _16820 = _16819 - _1353[_13476].y;
                }
                else
                {
                    _16820 = _16819;
                }
                int _13866 = _16820 + 1;
                int _17794 = (_13866 == _1353[_13476].y) ? 0 : _13866;
                int _13934 = _13828 + (max(_13846, 0) * _1353[_13476].y);
                int _13936 = _13934 + _16820;
                int _13938 = _13936 >> 1;
                uint2 _16826;
                if ((_13936 & 1) == 0)
                {
                    _16826 = _1281._m0[_13938].xy;
                }
                else
                {
                    _16826 = _1281._m0[_13938].zw;
                }
                int _13974 = _13934 + _17794;
                int _13976 = _13974 >> 1;
                uint2 _16828;
                if ((_13974 & 1) == 0)
                {
                    _16828 = _1281._m0[_13976].xy;
                }
                else
                {
                    _16828 = _1281._m0[_13976].zw;
                }
                int _14010 = _13828 + (min((_13846 + 1), (_1353[_13476].z - 1)) * _1353[_13476].y);
                int _14012 = _14010 + _16820;
                int _14014 = _14012 >> 1;
                uint2 _16831;
                if ((_14012 & 1) == 0)
                {
                    _16831 = _1281._m0[_14014].xy;
                }
                else
                {
                    _16831 = _1281._m0[_14014].zw;
                }
                int _14050 = _14010 + _17794;
                int _14052 = _14050 >> 1;
                uint2 _16832;
                if ((_14050 & 1) == 0)
                {
                    _16832 = _1281._m0[_14052].xy;
                }
                else
                {
                    _16832 = _1281._m0[_14052].zw;
                }
                float3 _13912 = float3(_13840.x);
                float3 _13206 = mix(mix(mix(float3(float2(as_type<half2>(_16812.x)), float2(as_type<half2>(_16812.y)).x), float3(float2(as_type<half2>(_16814.x)), float2(as_type<half2>(_16814.y)).x), _13625), mix(float3(float2(as_type<half2>(_16817.x)), float2(as_type<half2>(_16817.y)).x), float3(float2(as_type<half2>(_16818.x)), float2(as_type<half2>(_16818.y)).x), _13625), float3(_13553.y)), mix(mix(float3(float2(as_type<half2>(_16826.x)), float2(as_type<half2>(_16826.y)).x), float3(float2(as_type<half2>(_16828.x)), float2(as_type<half2>(_16828.y)).x), _13912), mix(float3(float2(as_type<half2>(_16831.x)), float2(as_type<half2>(_16831.y)).x), float3(float2(as_type<half2>(_16832.x)), float2(as_type<half2>(_16832.y)).x), _13912), float3(_13840.y)), float3(_13467 - float(_13470))) * _13343.w;
                float _13210 = _16802 * (1.0 - _16801);
                _17629 = _16867 + (_13206 * _13210);
                _17628 = _16801 + _13210;
            }
            _16911 = _16867 + (_16789 * (1.0 - _16801));
        }
        else
        {
            _16911 = _16789;
        }
        bool _4160;
        if (_3703)
        {
            _4160 = _283._m33.z > 0.5;
        }
        else
        {
            _4160 = _3703;
        }
        float3 _17001;
        if (_4160)
        {
            float3 _16961;
            do
            {
                float _14137 = ((_283._m32.x * (1.0 - smoothstep(_283._m33.x * 0.5, _283._m33.x, abs(dot(_283._m31.xyz, in.m_3037) - _283._m31.w)))) * smoothstep(0.5, 0.89999997615814208984375, dot(_3668, _283._m31.xyz))) * (1.0 - smoothstep(_283._m32.y * 0.5, _283._m32.y, _16689));
                if (_14137 <= 0.0)
                {
                    _16961 = _16911;
                    break;
                }
                float4 _14162 = _283._m30 * float4(in.m_3037 + ((_16699 - (_283._m31.xyz * dot(_16699, _283._m31.xyz))) * _283._m32.w), 1.0);
                float2 _14175 = ((float2(_14162.x, -_14162.y) / float2(_14162.w)) * 0.5) + float2(0.5);
                float _14179 = _283._m32.z * _16689;
                float3 _16959;
                float _16960;
                _16960 = 0.0;
                _16959 = float3(0.0);
                for (int _16958 = 0; _16958 < 12; )
                {
                    float _14186 = float(_16958);
                    float _14194 = _14186 * 2.3999631404876708984375;
                    float2 _14206 = _14175 + (float2(cos(_14194) * _283._m33.y, sin(_14194)) * (sqrt((_14186 + 0.5) * 0.083333335816860198974609375) * _14179));
                    float2 _14211 = fast::min(_14206, float2(1.0) - _14206);
                    float _14217 = smoothstep(0.0, 0.039999999105930328369140625, fast::min(_14211.x, _14211.y));
                    float4 _14225 = _3352.sample(_2533, fast::clamp(_14206, float2(0.0), float2(1.0)), level(0.0));
                    float3 _14227 = _14225.xyz;
                    _16960 += (_14225.w * _14217);
                    _16959 += ((_14227 / (float3(1.0) - fast::min(_14227, float3(0.99500000476837158203125)))) * _14217);
                    _16958++;
                    continue;
                }
                _16961 = mix(_16911, (_16959 * float3(0.083333335816860198974609375)) + (_16911 * (1.0 - (_16960 * 0.083333335816860198974609375))), float3(_14137));
                break;
            } while(false);
            _17001 = _16961;
        }
        else
        {
            _17001 = _16911;
        }
        float3 _4180 = (_3940 * _16966.x) + float3(_16966.y);
        float3 _4196 = _17055 + (((((float3(1.0) - _4180) * _3934) * _16889) + (_4180 * _17001)) * _17018);
        float3 _17262;
        if (_283._m13.w > 0.5)
        {
            float2 _14291 = fast::clamp(floor(gl_FragCoord.xy * _283._m12.xy), float2(0.0), _283._m13.xy - float2(1.0));
            uint _14319 = uint((((fast::clamp(floor((log2(fast::max(dot(_283._m11.xyz, in.m_3037) + _283._m11.w, 9.9999999747524270787835121154785e-07)) * _283._m12.z) + _283._m12.w), 0.0, _283._m13.z - 1.0) * _283._m13.y) + _14291.y) * _283._m13.x) + _14291.x);
            uint _14321 = _14319 >> uint(2);
            uint _14323 = _14319 & 3u;
            uint _14327 = _3167._m0[_14321][_14323] & 65535u;
            uint _14329 = _3167._m0[_14321][_14323] >> uint(16);
            float3 _17199;
            _17199 = _4196;
            float3 _4296;
            spvUnsafeArray<float2, 3> _14737;
            spvUnsafeArray<float2, 3> _14738;
            spvUnsafeArray<float2, 3> _14950;
            spvUnsafeArray<float2, 3> _14951;
            for (uint _17079 = _14327; _17079 < (_14327 + _14329); _17199 = _4296, _17079++)
            {
                uint _14335 = _17079 / 3u;
                uint _14348 = (_3188._m0[_14335 >> uint(2)][_14335 & 3u] >> ((_17079 - (_14335 * 3u)) * 10u)) & 1023u;
                float3 _14365 = _3030._m0[_14348].xyz - in.m_3037;
                float _14368 = dot(_14365, _14365);
                float _14372 = _14368 * _3030._m0[_14348].w;
                float _14377 = fast::clamp(1.0 - (_14372 * _14372), 0.0, 1.0);
                float3 _14382 = _14365 * rsqrt(fast::max(_14368, 9.9999999392252902907785028219223e-09));
                float _14400 = fast::clamp((dot(-_14382, _3073._m0[_14348].xyz) * _3065._m0[_14348].w) + _3073._m0[_14348].w, 0.0, 1.0);
                float3 _14413 = _3065._m0[_14348].xyz * ((((_14377 * _14377) * _14400) * _14400) / fast::max(_14368, 9.9999997473787516355514526367188e-05));
                float3 _17197;
                if (_3673)
                {
                    float _17106;
                    do
                    {
                        uint _14449 = uint(_283._m21.z);
                        if (_14348 < _14449)
                        {
                            float _14471 = _283._m26[_14348].z * fast::max((_283._m15[_14348] * float4(in.m_3037, 1.0)).w, 0.0);
                            float4 _14495 = _283._m15[_14348] * float4((in.m_3037 + (_3668 * (_14471 * _283._m25.x))) + (_14382 * (_14471 * _283._m25.y)), 1.0);
                            float _14497 = _14495.w;
                            if (_14497 <= 0.0)
                            {
                                _17106 = 1.0;
                                break;
                            }
                            float3 _14506 = _14495.xyz / float3(_14497);
                            float _14508 = _14506.x;
                            bool _14509 = _14508 < 0.0;
                            bool _14516;
                            if (!_14509)
                            {
                                _14516 = _14508 > 1.0;
                            }
                            else
                            {
                                _14516 = _14509;
                            }
                            bool _14523;
                            if (!_14516)
                            {
                                _14523 = _14506.y < 0.0;
                            }
                            else
                            {
                                _14523 = _14516;
                            }
                            bool _14530;
                            if (!_14523)
                            {
                                _14530 = _14506.y > 1.0;
                            }
                            else
                            {
                                _14530 = _14523;
                            }
                            bool _14537;
                            if (!_14530)
                            {
                                _14537 = _14506.z > 1.0;
                            }
                            else
                            {
                                _14537 = _14530;
                            }
                            if (_14537)
                            {
                                _17106 = 1.0;
                                break;
                            }
                            float _14543 = _14506.z;
                            float2 _14709 = _283._m22.xy * 0.5;
                            float2 _14714 = _283._m26[_14348].xy + (_14506.xy * _283._m23.zw);
                            float4 _14727 = float4(_283._m26[_14348].xy + _14709, (_283._m26[_14348].xy + _283._m23.zw) - _14709);
                            float _17105;
                            do
                            {
                                int _14753 = int(_283._m22.z);
                                if (_14753 <= 0)
                                {
                                    float2 _14763 = fast::clamp(_14714, _14727.xy, _14727.zw);
                                    _17105 = spvDepthCast(_303).sample_compare(_303Smplr, float3(_14763, _14543).xy, _14543);
                                    break;
                                }
                                float2 _14776 = (_14714 / _283._m22.xy) + float2(0.5);
                                float2 _14777 = floor(_14776);
                                float2 _14782 = _14776 - _14777;
                                float2 _14785 = _14777 - float2(0.5);
                                bool _14789 = _14753 == 1;
                                if (_14789)
                                {
                                    float2 _14792 = _14782 * 2.0;
                                    _14737[0] = float2(3.0) - _14792;
                                    _14737[1] = float2(1.0) + _14792;
                                    _14738[0] = ((float2(2.0) - _14782) / _14737[0]) - float2(1.0);
                                    _14738[1] = (_14782 / _14737[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _14819 = _14782 * 3.0;
                                    _14737[0] = float2(4.0) - _14819;
                                    _14737[1] = float2(7.0);
                                    _14737[2] = float2(1.0) + _14819;
                                    _14738[0] = ((float2(3.0) - (_14782 * 2.0)) / _14737[0]) - float2(2.0);
                                    _14738[1] = (float2(3.0) + _14782) / _14737[1];
                                    _14738[2] = (_14782 / _14737[2]) + float2(2.0);
                                }
                                int _17796 = _14789 ? 2 : 3;
                                int _17095;
                                float _17098;
                                _17098 = 0.0;
                                _17095 = 0;
                                float _17104;
                                for (; _17095 < _17796; _17098 = _17104, _17095++)
                                {
                                    _17104 = _17098;
                                    for (int _17101 = 0; _17101 < _17796; )
                                    {
                                        _17104 += ((_14737[_17101].x * _14737[_17095].y) * spvDepthCast(_303).sample_compare(_303Smplr, float3(fast::clamp(_283._m22.xy * (_14785 + float2(_14738[_17101].x, _14738[_17095].y)), _14727.xy, _14727.zw), _14543).xy, _14543));
                                        _17101++;
                                        continue;
                                    }
                                }
                                _17105 = _17098 * (_14789 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _17106 = _17105;
                            break;
                        }
                        uint _14553 = _14348 - _14449;
                        if (_14553 >= uint(_283._m21.w))
                        {
                            _17106 = 1.0;
                            break;
                        }
                        float _14574 = _283._m27[_14553].w * length(in.m_3037 - _283._m27[_14553].xyz);
                        float3 _14592 = ((in.m_3037 + (_3668 * (_14574 * _283._m25.x))) + (_14382 * (_14574 * _283._m25.y))) - _283._m27[_14553].xyz;
                        float3 _14594 = abs(_14592);
                        float _14596 = _14594.x;
                        float _14598 = _14594.y;
                        bool _14599 = _14596 >= _14598;
                        bool _14607;
                        if (_14599)
                        {
                            _14607 = _14596 >= _14594.z;
                        }
                        else
                        {
                            _14607 = _14599;
                        }
                        float _17080;
                        int _17082;
                        if (_14607)
                        {
                            _17082 = (_14592.x > 0.0) ? 0 : 1;
                            _17080 = _14596;
                        }
                        else
                        {
                            float _14619 = _14594.z;
                            bool _14620 = _14598 >= _14619;
                            int _17083;
                            if (_14620)
                            {
                                _17083 = (_14592.y > 0.0) ? 2 : 3;
                            }
                            else
                            {
                                _17083 = (_14592.z > 0.0) ? 4 : 5;
                            }
                            _17082 = _17083;
                            _17080 = _14620 ? _14598 : _14619;
                        }
                        if (_17080 <= 0.0)
                        {
                            _17106 = 1.0;
                            break;
                        }
                        float2 _14657 = float2(dot(_14592, _961[_17082]), dot(_14592, _970[_17082])) / float2(_17080 * _283._m24.z);
                        float _14664 = _283._m28[_14553].z + (_283._m28[_14553].w / _17080);
                        if (_14664 > 1.0)
                        {
                            _17106 = 1.0;
                            break;
                        }
                        float2 _14682 = _283._m28[_14553].xy + (float2(float(spvSMod(_17082, 3)), float(_17082 / 3)) * _283._m24.xy);
                        float2 _14922 = _283._m22.xy * 0.5;
                        float2 _14927 = _14682 + (float2(0.5 + (0.5 * _14657.x), 0.5 - (0.5 * _14657.y)) * _283._m24.xy);
                        float4 _14940 = float4(_14682 + _14922, (_14682 + _283._m24.xy) - _14922);
                        float _17094;
                        do
                        {
                            int _14966 = int(_283._m22.z);
                            if (_14966 <= 0)
                            {
                                _17094 = spvDepthCast(_303).sample_compare(_303Smplr, float3(fast::clamp(_14927, _14940.xy, _14940.zw), _14664).xy, _14664);
                                break;
                            }
                            float2 _14989 = (_14927 / _283._m22.xy) + float2(0.5);
                            float2 _14990 = floor(_14989);
                            float2 _14995 = _14989 - _14990;
                            float2 _14998 = _14990 - float2(0.5);
                            bool _15002 = _14966 == 1;
                            if (_15002)
                            {
                                float2 _15005 = _14995 * 2.0;
                                _14950[0] = float2(3.0) - _15005;
                                _14950[1] = float2(1.0) + _15005;
                                _14951[0] = ((float2(2.0) - _14995) / _14950[0]) - float2(1.0);
                                _14951[1] = (_14995 / _14950[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _15032 = _14995 * 3.0;
                                _14950[0] = float2(4.0) - _15032;
                                _14950[1] = float2(7.0);
                                _14950[2] = float2(1.0) + _15032;
                                _14951[0] = ((float2(3.0) - (_14995 * 2.0)) / _14950[0]) - float2(2.0);
                                _14951[1] = (float2(3.0) + _14995) / _14950[1];
                                _14951[2] = (_14995 / _14950[2]) + float2(2.0);
                            }
                            int _17799 = _15002 ? 2 : 3;
                            int _17084;
                            float _17087;
                            _17087 = 0.0;
                            _17084 = 0;
                            float _17093;
                            for (; _17084 < _17799; _17087 = _17093, _17084++)
                            {
                                _17093 = _17087;
                                for (int _17090 = 0; _17090 < _17799; )
                                {
                                    _17093 += ((_14950[_17090].x * _14950[_17084].y) * spvDepthCast(_303).sample_compare(_303Smplr, float3(fast::clamp(_283._m22.xy * (_14998 + float2(_14951[_17090].x, _14951[_17084].y)), _14940.xy, _14940.zw), _14664).xy, _14664));
                                    _17090++;
                                    continue;
                                }
                            }
                            _17094 = _17087 * (_15002 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _17106 = _17094;
                        break;
                    } while(false);
                    _17197 = _14413 * _17106;
                }
                else
                {
                    _17197 = _14413;
                }
                float3 _4248 = fast::normalize(_14382 + _3657);
                float _4253 = fast::clamp(dot(_16699, _14382), 0.0, 1.0);
                float _4258 = fast::clamp(dot(_16699, _4248), 0.0, 1.0);
                float3 _15137 = _3940 + (_9720 * powr(1.0 - fast::clamp(dot(_3657, _4248), 0.0, 1.0), 5.0));
                float _15151 = ((_4258 * _4258) * _9735) + 1.0;
                _4296 = _17199 + (((((float3(1.0) - _15137) * _3934) + ((_15137 * ((_9730 / ((3.1415927410125732421875 * _15151) * _15151)) * (0.5 / fast::max((_4253 * _9761) + (_16727 * sqrt(((_4253 * _4253) * _9757) + _9730)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875)) * _4253) * _17197);
            }
            _17262 = _17199;
        }
        else
        {
            _17262 = _4196;
        }
        _17329 = _16889;
        _17259 = _17262;
    }
    float4 _4313 = _4308.sample(_2533, _3419);
    float _4331 = -length(_3656);
    float _17384;
    if (_283._m9.w != 0.0)
    {
        float _4355 = _283._m9.w * (in.m_3037 - _283._m6.xyz).y;
        float _17327;
        if (abs(_4355) < 9.9999997473787516355514526367188e-05)
        {
            _17327 = 1.0 - (0.5 * _4355);
        }
        else
        {
            _17327 = (1.0 - exp(fast::min(-_4355, 60.0))) / _4355;
        }
        _17384 = 1.0 - exp((_4331 * (_283._m7.w * exp(fast::min((-_283._m9.w) * (_283._m6.y - _283._m6.w), 30.0)))) * _17327);
    }
    else
    {
        _17384 = 1.0 - exp(_4331 * _283._m7.w);
    }
    bool _4401 = _283._m34.z > 0.5;
    float3 _17380;
    if (_4401)
    {
        _17380 = _17329 * _17018;
    }
    else
    {
        _17380 = mix(_17259, _16693, float3(_2876._m1.y)) + ((_2876._m5.xyz * _4313.xyz) * (float3(1.0) + in.m_3670.yzw));
    }
    float3 _4414 = mix(_17380, _283._m7.xyz, float3(_4401 ? 0.0 : _17384));
    float3 _17385;
    if (_283._m33.w > 0.5)
    {
        _17385 = _4414 / (float3(1.0) + _4414);
    }
    else
    {
        _17385 = _4414;
    }
    out.m_4426 = float4(_17385, in.m_3428.w);
    float2 _17494;
    do
    {
        if (in.m_4436.w <= 0.0)
        {
            _17494 = float2(0.0);
            break;
        }
        _17494 = ((in.m_4436.xy / float2(in.m_4436.w)) - (in.m_4435.xy / float2(in.m_4435.w))) * float2(0.5, -0.5);
        break;
    } while(false);
    out.m_4434 = _17494;
    return out;
}

