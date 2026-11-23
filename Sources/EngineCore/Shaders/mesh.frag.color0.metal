// Generated from mesh.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 28933d8ed7d59bf7
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
    float4 m_4413 [[color(0)]];
};

struct fragment_main_in
{
    float3 m_3037 [[user(locn0)]];
    float3 m_2946 [[user(locn1)]];
    float2 m_3405 [[user(locn2)]];
    float4 m_3428 [[user(locn3)]];
    float3 m_2980 [[user(locn4)]];
    float4 m_3657 [[user(locn5)]];
    float4 m_4422 [[user(locn6)]];
    float4 m_4423 [[user(locn7)]];
    float4 m_2952 [[user(locn8)]];
};

fragment fragment_main_out fragment_main(fragment_main_in in [[stage_in]], constant _2874& _2876 [[buffer(2)]], constant _3028& _3030 [[buffer(3)]], constant _3063& _3065 [[buffer(4)]], constant _3071& _3073 [[buffer(5)]], constant _3165& _3167 [[buffer(6)]], constant _3186& _3188 [[buffer(7)]], constant _281& _283 [[buffer(15)]], const device _1279& _1281 [[buffer(21)]], texture2d<float> _303 [[texture(0)]], texture2d<float> _3421 [[texture(1)]], texture2d<float> _3877 [[texture(2)]], texture2d<float> _3534 [[texture(3)]], texture2d<float> _3352 [[texture(4)]], texture2d<float> _4295 [[texture(5)]], texture2d<float> _2531 [[texture(6)]], texture2d<float> _2632 [[texture(7)]], sampler _303Smplr [[sampler(0)]], sampler _2533 [[sampler(1)]], sampler _2634 [[sampler(7)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])
{
    float2 _4421;
    fragment_main_out out = {};
    float2 _3419 = float2(dot(_2876._m2.xy, in.m_3405) + _2876._m2.z, dot(_2876._m3.xy, in.m_3405) + _2876._m3.z);
    float4 _3426 = _3421.sample(_2533, _3419);
    float3 _3436 = _3426.xyz;
    float3 _3437 = (in.m_3428.xyz * _2876._m0.xyz) * _3436;
    float3 _16488;
    if (_2876._m1.x > 0.5)
    {
        float2 _3458 = floor(in.m_3037.xz * float2(0.5));
        _16488 = _3437 * ((mod(abs(_3458.x + _3458.y), 2.0) < 0.5) ? 1.0 : 0.75);
    }
    else
    {
        _16488 = _3437;
    }
    float3 _16585;
    float _16616;
    float2 _16649;
    if (_2876._m3.w > 0.5)
    {
        float3 _4529;
        float2 _4536;
        float _16486;
        do
        {
            float3 _4500 = float4(_2876._m2.w, _2876._m3.w, 0.0, 0.0).xyy;
            float3 _4503 = floor(_4500 * float3(1.52587890625e-05));
            float3 _4508 = _4500 - (_4503 * 65536.0);
            float3 _4511 = floor(_4508 * float3(0.00390625));
            float3 _4519 = _4508 - (_4511 * 256.0);
            _4529 = (float3(_4519.x, _4511.x, _4503.x) * float3(0.0039215688593685626983642578125)) * 2.0;
            _4536 = float2(_4519.y, _4511.y) * float2(0.0039215688593685626983642578125);
            float _4539 = _4503.y - 128.0;
            float _4545 = floor(_4539 * 0.03125) * 0.3333333432674407958984375;
            float3 _4551 = fast::normalize(in.m_2946);
            float _4555 = dot(_4551, in.m_2952.xyz);
            float _4567 = (_4555 / fast::max(length(in.m_2952.xyz - (_4551 * _4555)), 9.9999999747524270787835121154785e-07)) * 25.5;
            if (((-24.0) + _4567) < (-2.0))
            {
                _16486 = 0.0;
                break;
            }
            float3 _4575 = in.m_2980 * (4.0 * exp2(mod(_4539, 32.0) * 0.3333333432674407958984375));
            float3 _4619 = floor(_4575);
            float3 _4622 = _4575 - _4619;
            float3 _4630 = (_4622 * _4622) * (float3(3.0) - (_4622 * 2.0));
            uint3 _4697 = uint3(int3(_4619));
            uint _4710 = (((_4697.x * 1597334677u) ^ (_4697.y * 3812015801u)) ^ (_4697.z * 2798796415u)) * 1597334677u;
            uint3 _4725 = uint3(int3(_4619 + float3(1.0, 0.0, 0.0)));
            uint _4738 = (((_4725.x * 1597334677u) ^ (_4725.y * 3812015801u)) ^ (_4725.z * 2798796415u)) * 1597334677u;
            float _4639 = _4630.x;
            uint3 _4753 = uint3(int3(_4619 + float3(0.0, 1.0, 0.0)));
            uint _4766 = (((_4753.x * 1597334677u) ^ (_4753.y * 3812015801u)) ^ (_4753.z * 2798796415u)) * 1597334677u;
            uint3 _4781 = uint3(int3(_4619 + float3(1.0, 1.0, 0.0)));
            uint _4794 = (((_4781.x * 1597334677u) ^ (_4781.y * 3812015801u)) ^ (_4781.z * 2798796415u)) * 1597334677u;
            float _4655 = _4630.y;
            uint3 _4809 = uint3(int3(_4619 + float3(0.0, 0.0, 1.0)));
            uint _4822 = (((_4809.x * 1597334677u) ^ (_4809.y * 3812015801u)) ^ (_4809.z * 2798796415u)) * 1597334677u;
            uint3 _4837 = uint3(int3(_4619 + float3(1.0, 0.0, 1.0)));
            uint _4850 = (((_4837.x * 1597334677u) ^ (_4837.y * 3812015801u)) ^ (_4837.z * 2798796415u)) * 1597334677u;
            uint3 _4865 = uint3(int3(_4619 + float3(0.0, 1.0, 1.0)));
            uint _4878 = (((_4865.x * 1597334677u) ^ (_4865.y * 3812015801u)) ^ (_4865.z * 2798796415u)) * 1597334677u;
            uint3 _4893 = uint3(int3(_4619 + float3(1.0)));
            uint _4906 = (((_4893.x * 1597334677u) ^ (_4893.y * 3812015801u)) ^ (_4893.z * 2798796415u)) * 1597334677u;
            float3 _4581 = (_4575 * 2.7000000476837158203125) + float3(17.299999237060546875, 5.099999904632568359375, 9.69999980926513671875);
            float3 _4932 = floor(_4581);
            float3 _4935 = _4581 - _4932;
            float3 _4943 = (_4935 * _4935) * (float3(3.0) - (_4935 * 2.0));
            uint3 _5010 = uint3(int3(_4932));
            uint _5023 = (((_5010.x * 1597334677u) ^ (_5010.y * 3812015801u)) ^ (_5010.z * 2798796415u)) * 1597334677u;
            uint3 _5038 = uint3(int3(_4932 + float3(1.0, 0.0, 0.0)));
            uint _5051 = (((_5038.x * 1597334677u) ^ (_5038.y * 3812015801u)) ^ (_5038.z * 2798796415u)) * 1597334677u;
            float _4952 = _4943.x;
            uint3 _5066 = uint3(int3(_4932 + float3(0.0, 1.0, 0.0)));
            uint _5079 = (((_5066.x * 1597334677u) ^ (_5066.y * 3812015801u)) ^ (_5066.z * 2798796415u)) * 1597334677u;
            uint3 _5094 = uint3(int3(_4932 + float3(1.0, 1.0, 0.0)));
            uint _5107 = (((_5094.x * 1597334677u) ^ (_5094.y * 3812015801u)) ^ (_5094.z * 2798796415u)) * 1597334677u;
            float _4968 = _4943.y;
            uint3 _5122 = uint3(int3(_4932 + float3(0.0, 0.0, 1.0)));
            uint _5135 = (((_5122.x * 1597334677u) ^ (_5122.y * 3812015801u)) ^ (_5122.z * 2798796415u)) * 1597334677u;
            uint3 _5150 = uint3(int3(_4932 + float3(1.0, 0.0, 1.0)));
            uint _5163 = (((_5150.x * 1597334677u) ^ (_5150.y * 3812015801u)) ^ (_5150.z * 2798796415u)) * 1597334677u;
            uint3 _5178 = uint3(int3(_4932 + float3(0.0, 1.0, 1.0)));
            uint _5191 = (((_5178.x * 1597334677u) ^ (_5178.y * 3812015801u)) ^ (_5178.z * 2798796415u)) * 1597334677u;
            uint3 _5206 = uint3(int3(_4932 + float3(1.0)));
            uint _5219 = (((_5206.x * 1597334677u) ^ (_5206.y * 3812015801u)) ^ (_5206.z * 2798796415u)) * 1597334677u;
            float _4586 = mix(0.449999988079071044921875, 0.0500000007450580596923828125, _4545);
            float _4590 = ((mix(mix(mix(float((_4710 ^ (_4710 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_4738 ^ (_4738 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _4639), mix(float((_4766 ^ (_4766 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_4794 ^ (_4794 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _4639), _4655), mix(mix(float((_4822 ^ (_4822 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_4850 ^ (_4850 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _4639), mix(float((_4878 ^ (_4878 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_4906 ^ (_4906 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _4639), _4655), _4630.z) * 0.64999997615814208984375) + (mix(mix(mix(float((_5023 ^ (_5023 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_5051 ^ (_5051 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _4952), mix(float((_5079 ^ (_5079 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_5107 ^ (_5107 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _4952), _4968), mix(mix(float((_5135 ^ (_5135 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_5163 ^ (_5163 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _4952), mix(float((_5191 ^ (_5191 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_5219 ^ (_5219 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _4952), _4968), _4943.z) * 0.3499999940395355224609375)) - 0.5;
            _16486 = smoothstep(-_4586, _4586, (_4567 + (-24.450000762939453125)) + (_4590 * mix(0.800000011920928955078125, 2.2000000476837158203125, _4545)));
            break;
        } while(false);
        _16649 = _4536;
        _16616 = _16486;
        _16585 = mix(_16488, (in.m_3428.xyz * _4529) * mix(float3(1.0), _3436 * 2.0, float3(0.5)), float3(_16486));
    }
    else
    {
        _16649 = float2(0.0);
        _16616 = 0.0;
        _16585 = _16488;
    }
    float3 _3500 = fast::normalize(in.m_2946);
    float3 _16498;
    if (_2876._m6.y > 0.5)
    {
        float3 _3515 = in.m_2952.xyz - (_3500 * dot(_3500, in.m_2952.xyz));
        float3 _16499;
        if (dot(_3515, _3515) > 9.9999999600419720025001879548654e-13)
        {
            float3 _3523 = fast::normalize(_3515);
            float4 _3539 = _3534.sample(_2533, _3419);
            float3 _16490;
            if (_2876._m6.z > 0.5)
            {
                float2 _16489;
                if (_2876._m6.z > 1.5)
                {
                    _16489 = _3539.xw;
                }
                else
                {
                    _16489 = _3539.xy;
                }
                float2 _3561 = (_16489 * 2.0) - float2(1.0);
                _16490 = float3(_3561, sqrt(fast::clamp(1.0 - dot(_3561, _3561), 0.0, 1.0)));
            }
            else
            {
                _16490 = (_3539.xyz * 2.0) - float3(1.0);
            }
            float2 _3583 = _16490.xy * _2876._m4.z;
            _16499 = fast::normalize(((_3523 * _3583.x) + ((cross(_3500, _3523) * ((in.m_2952.w < 0.0) ? (-1.0) : 1.0)) * _3583.y)) + (_3500 * _16490.z));
        }
        else
        {
            _16499 = _3500;
        }
        _16498 = _16499;
    }
    else
    {
        _16498 = _3500;
    }
    bool _3607 = _2876._m5.w > 0.5;
    float _16495;
    if (_3607)
    {
        _16495 = fast::clamp(_2876._m1.z, 0.0, 1.0);
    }
    else
    {
        _16495 = 0.0;
    }
    bool _3625;
    if (_3607)
    {
        _3625 = !gl_FrontFacing;
    }
    else
    {
        _3625 = _3607;
    }
    float3 _16685;
    if (_3625 && (_16495 <= 0.0))
    {
        _16685 = -_16498;
    }
    else
    {
        _16685 = _16498;
    }
    float3 _3637 = fast::normalize(_283._m4.xyz);
    float3 _3643 = _283._m6.xyz - in.m_3037;
    float3 _3644 = fast::normalize(_3643);
    float3 _3649 = fast::normalize(_3637 + _3644);
    float3 _3655 = _3500 * (gl_FrontFacing ? 1.0 : (-1.0));
    bool _3660 = in.m_3657.x > 0.5;
    float3 _16679;
    float _16719;
    if ((_283._m5.w > 0.5) && _3660)
    {
        float _16555;
        float3 _16556;
        do
        {
            int _5248 = int(_283._m21.x);
            float _5256 = dot(_283._m20.xyz, in.m_3037) + _283._m20.w;
            int _16500;
            _16500 = 0;
            for (;;)
            {
                bool _5262 = _16500 < (_5248 - 1);
                bool _5270;
                if (_5262)
                {
                    _5270 = _5256 > _283._m16[_16500];
                }
                else
                {
                    _5270 = _5262;
                }
                if (_5270)
                {
                    _16500++;
                    continue;
                }
                else
                {
                    break;
                }
            }
            if (_5256 > _283._m16[_16500])
            {
                _16556 = float3(1.0);
                _16555 = 1.0;
                break;
            }
            float _16513;
            do
            {
                float4 _5372 = _283._m14[_16500] * float4(in.m_3037 + (_3655 * _283._m18[_16500]), 1.0);
                float _5375 = _5372.x;
                bool _5376 = _5375 < 0.0;
                bool _5383;
                if (!_5376)
                {
                    _5383 = _5375 > 1.0;
                }
                else
                {
                    _5383 = _5376;
                }
                bool _5390;
                if (!_5383)
                {
                    _5390 = _5372.y < 0.0;
                }
                else
                {
                    _5390 = _5383;
                }
                bool _5397;
                if (!_5390)
                {
                    _5397 = _5372.y > 1.0;
                }
                else
                {
                    _5397 = _5390;
                }
                if (_5397)
                {
                    _16513 = 1.0;
                    break;
                }
                float2 _5410 = float2(float(_16500 & 1), float(_16500 >> 1)) * _283._m23.xy;
                float _5417 = fast::min(_5372.z, 1.0) - _283._m19[_16500];
                float2 _5436 = _283._m22.xy * 0.5;
                float2 _5441 = _5410 + (_5372.xy * _283._m23.xy);
                float4 _5454 = float4(_5410 + _5436, (_5410 + _283._m23.xy) - _5436);
                float _16512;
                do
                {
                    int _5480 = int(_283._m22.z);
                    if (_5480 <= 0)
                    {
                        _16512 = spvDepthCast(_303).sample_compare(_303Smplr, float3(fast::clamp(_5441, _5454.xy, _5454.zw), _5417).xy, _5417);
                        break;
                    }
                    float2 _5503 = (_5441 / _283._m22.xy) + float2(0.5);
                    float2 _5504 = floor(_5503);
                    float2 _5509 = _5503 - _5504;
                    float2 _5512 = _5504 - float2(0.5);
                    bool _5516 = _5480 == 1;
                    spvUnsafeArray<float2, 3> _5464;
                    spvUnsafeArray<float2, 3> _5465;
                    if (_5516)
                    {
                        float2 _5519 = _5509 * 2.0;
                        _5464[0] = float2(3.0) - _5519;
                        _5464[1] = float2(1.0) + _5519;
                        _5465[0] = ((float2(2.0) - _5509) / _5464[0]) - float2(1.0);
                        _5465[1] = (_5509 / _5464[1]) + float2(1.0);
                    }
                    else
                    {
                        float2 _5546 = _5509 * 3.0;
                        _5464[0] = float2(4.0) - _5546;
                        _5464[1] = float2(7.0);
                        _5464[2] = float2(1.0) + _5546;
                        _5465[0] = ((float2(3.0) - (_5509 * 2.0)) / _5464[0]) - float2(2.0);
                        _5465[1] = (float2(3.0) + _5509) / _5464[1];
                        _5465[2] = (_5509 / _5464[2]) + float2(2.0);
                    }
                    int _17638 = _5516 ? 2 : 3;
                    int _16502;
                    float _16505;
                    _16505 = 0.0;
                    _16502 = 0;
                    float _16511;
                    for (; _16502 < _17638; _16505 = _16511, _16502++)
                    {
                        _16511 = _16505;
                        for (int _16508 = 0; _16508 < _17638; )
                        {
                            _16511 += ((_5464[_16508].x * _5464[_16502].y) * spvDepthCast(_303).sample_compare(_303Smplr, float3(fast::clamp(_283._m22.xy * (_5512 + float2(_5465[_16508].x, _5465[_16502].y)), _5454.xy, _5454.zw), _5417).xy, _5417));
                            _16508++;
                            continue;
                        }
                    }
                    _16512 = _16505 * (_5516 ? 0.0625 : 0.0069444444961845874786376953125);
                    break;
                } while(false);
                _16513 = _16512;
                break;
            } while(false);
            float3 _16550;
            float _16553;
            if (_5256 > _283._m17[_16500])
            {
                float _5310 = (_5256 - _283._m17[_16500]) / (_283._m16[_16500] - _283._m17[_16500]);
                int _5312 = _16500 + 1;
                float3 _16551;
                float _16554;
                if (_5312 < _5248)
                {
                    float _16533;
                    do
                    {
                        float4 _5659 = _283._m14[_5312] * float4(in.m_3037 + (_3655 * _283._m18[_5312]), 1.0);
                        float _5662 = _5659.x;
                        bool _5663 = _5662 < 0.0;
                        bool _5670;
                        if (!_5663)
                        {
                            _5670 = _5662 > 1.0;
                        }
                        else
                        {
                            _5670 = _5663;
                        }
                        bool _5677;
                        if (!_5670)
                        {
                            _5677 = _5659.y < 0.0;
                        }
                        else
                        {
                            _5677 = _5670;
                        }
                        bool _5684;
                        if (!_5677)
                        {
                            _5684 = _5659.y > 1.0;
                        }
                        else
                        {
                            _5684 = _5677;
                        }
                        if (_5684)
                        {
                            _16533 = 1.0;
                            break;
                        }
                        float2 _5697 = float2(float(_5312 & 1), float(_5312 >> 1)) * _283._m23.xy;
                        float _5704 = fast::min(_5659.z, 1.0) - _283._m19[_5312];
                        float2 _5723 = _283._m22.xy * 0.5;
                        float2 _5728 = _5697 + (_5659.xy * _283._m23.xy);
                        float4 _5741 = float4(_5697 + _5723, (_5697 + _283._m23.xy) - _5723);
                        float _16532;
                        do
                        {
                            int _5767 = int(_283._m22.z);
                            if (_5767 <= 0)
                            {
                                _16532 = spvDepthCast(_303).sample_compare(_303Smplr, float3(fast::clamp(_5728, _5741.xy, _5741.zw), _5704).xy, _5704);
                                break;
                            }
                            float2 _5790 = (_5728 / _283._m22.xy) + float2(0.5);
                            float2 _5791 = floor(_5790);
                            float2 _5796 = _5790 - _5791;
                            float2 _5799 = _5791 - float2(0.5);
                            bool _5803 = _5767 == 1;
                            spvUnsafeArray<float2, 3> _5751;
                            spvUnsafeArray<float2, 3> _5752;
                            if (_5803)
                            {
                                float2 _5806 = _5796 * 2.0;
                                _5751[0] = float2(3.0) - _5806;
                                _5751[1] = float2(1.0) + _5806;
                                _5752[0] = ((float2(2.0) - _5796) / _5751[0]) - float2(1.0);
                                _5752[1] = (_5796 / _5751[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _5833 = _5796 * 3.0;
                                _5751[0] = float2(4.0) - _5833;
                                _5751[1] = float2(7.0);
                                _5751[2] = float2(1.0) + _5833;
                                _5752[0] = ((float2(3.0) - (_5796 * 2.0)) / _5751[0]) - float2(2.0);
                                _5752[1] = (float2(3.0) + _5796) / _5751[1];
                                _5752[2] = (_5796 / _5751[2]) + float2(2.0);
                            }
                            int _17640 = _5803 ? 2 : 3;
                            int _16522;
                            float _16525;
                            _16525 = 0.0;
                            _16522 = 0;
                            float _16531;
                            for (; _16522 < _17640; _16525 = _16531, _16522++)
                            {
                                _16531 = _16525;
                                for (int _16528 = 0; _16528 < _17640; )
                                {
                                    _16531 += ((_5751[_16528].x * _5751[_16522].y) * spvDepthCast(_303).sample_compare(_303Smplr, float3(fast::clamp(_283._m22.xy * (_5799 + float2(_5752[_16528].x, _5752[_16522].y)), _5741.xy, _5741.zw), _5704).xy, _5704));
                                    _16528++;
                                    continue;
                                }
                            }
                            _16532 = _16525 * (_5803 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _16533 = _16532;
                        break;
                    } while(false);
                    _16554 = mix(_16513, _16533, _5310);
                    _16551 = mix(_657[_16500], _657[_5312], float3(_5310));
                }
                else
                {
                    _16554 = mix(_16513, 1.0, _5310);
                    _16551 = _657[_16500];
                }
                _16553 = _16554;
                _16550 = _16551;
            }
            else
            {
                _16553 = _16513;
                _16550 = _657[_16500];
            }
            _16556 = select(float3(1.0), _16550, bool3(_283._m22.w > 0.5));
            _16555 = _16553;
            break;
        } while(false);
        _16719 = _16555;
        _16679 = _16585 * _16556;
    }
    else
    {
        _16719 = 1.0;
        _16679 = _16585;
    }
    float3 _3686 = _283._m5.xyz * _283._m4.w;
    bool _3690 = _2876._m6.w > 0.5;
    float _16608;
    if (_3690)
    {
        _16608 = 1.0;
    }
    else
    {
        _16608 = 1.0 + (_2876._m4.w * (_3352.sample(_2533, _3419).x - 1.0));
    }
    float _3710 = abs(in.m_2952.w);
    float _17004;
    if (_3710 > 0.0)
    {
        _17004 = _16608 * fast::min(_3710, 1.0);
    }
    else
    {
        _17004 = _16608;
    }
    float3 _17245;
    float3 _17315;
    if (!_3607)
    {
        float _3726 = dot(_16685, _3637);
        float3 _17226;
        if (_283._m29.x > 0.5)
        {
            float _5984 = (_283._m29.z * _16685.x) - (_283._m29.w * _16685.z);
            float _5997 = (_283._m29.w * _16685.x) + (_283._m29.z * _16685.z);
            float _6015 = 1.09254801273345947265625 * _5984;
            spvUnsafeArray<float, 9> _15481 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _16685.y, 0.48860299587249755859375 * _5997, 0.48860299587249755859375 * _5984, _6015 * _16685.y, (1.09254801273345947265625 * _16685.y) * _5997, 0.3153919875621795654296875 * (((3.0 * _5997) * _5997) - 1.0), _6015 * _5997, 0.546274006366729736328125 * ((_5984 * _5984) - (_16685.y * _16685.y)) });
            spvUnsafeArray<float, 9> _5929 = _15481;
            float3 _17225;
            _17225 = float3(0.0);
            for (int _17224 = 0; _17224 < 9; )
            {
                _17225 += (_2531.read(uint2((int2(496, 256) + int2(_17224, 0))), 0).xyz * _5929[_17224]);
                _17224++;
                continue;
            }
            _17226 = fast::max(_17225, float3(0.0)) * _283._m29.y;
        }
        else
        {
            _17226 = mix(_283._m9.xyz, _283._m8.xyz, float3((_16685.y * 0.5) + 0.5)) * _283._m8.w;
        }
        float3 _17231;
        if (_283._m34.y > 0.5)
        {
            int _6192 = int(_283._m34.y);
            int _6195 = int(_283._m34.x);
            float3 _17230;
            _17230 = _17226;
            float3 _17525;
            for (int _17229 = 0; _17229 < _6192; _17230 = _17525, _17229++)
            {
                int _6207 = 8 * (_6195 + _17229);
                float4 _6416 = as_type<float4>(_1281._m0[_6207 + 3]);
                float4 _6460 = as_type<float4>(_1281._m0[_6207]);
                float4 _6466 = as_type<float4>(_1281._m0[_6207 + 1]);
                float4 _6472 = as_type<float4>(_1281._m0[_6207 + 2]);
                float3 _6434 = _6460.xyz;
                float _6438 = _6460.w;
                float3 _6441 = _6466.xyz;
                float _6445 = _6466.w;
                float3 _6448 = _6472.xyz;
                float _6452 = _6472.w;
                float3 _6454 = float3(dot(_6434, in.m_3037) + _6438, dot(_6441, in.m_3037) + _6445, dot(_6448, in.m_3037) + _6452);
                float3 _6216 = _6416.xyz;
                float _6218 = _6416.w;
                float _17488;
                do
                {
                    float3 _6484 = _6216 - abs(_6454);
                    float _6492 = fast::min(_6484.x, fast::min(_6484.y, _6484.z));
                    if (_6492 <= 0.0)
                    {
                        _17488 = 0.0;
                        break;
                    }
                    if (_6218 <= 0.0)
                    {
                        _17488 = 1.0;
                        break;
                    }
                    float _6504 = fast::min(_6492 / _6218, 1.0);
                    _17488 = (_6504 * _6504) * (3.0 - (2.0 * _6504));
                    break;
                } while(false);
                if (_17488 <= 0.0)
                {
                    _17525 = _17230;
                    continue;
                }
                float3 _6227 = as_type<float4>(_1281._m0[_6207 + 4]).xyz;
                float4 _6525 = as_type<float4>(_1281._m0[_6207 + 5]);
                int _6531 = int(((device uint*)&_1281._m0[_6207 + 6])[0u]);
                float _6541 = dot(_6434, _16685);
                float _6547 = dot(_6441, _16685);
                float _6553 = dot(_6448, _16685);
                float3 _6554 = float3(_6541, _6547, _6553);
                float3 _6247 = (in.m_3037 + (_16685 * _6525.x)) + (_3644 * _6525.y);
                float3 _6266 = fast::clamp((((float3(dot(_6434, _6247) + _6438, dot(_6441, _6247) + _6445, dot(_6448, _6247) + _6452) + _6216) / fast::max(_6216 * 2.0, float3(9.9999999747524270787835121154785e-07))) * _6227) - float3(0.5), float3(0.0), _6227 - float3(1.0));
                int3 _6268 = int3(_6227);
                int3 _6275 = min(int3(_6266), max((_6268 - int3(2)), int3(0)));
                float3 _6279 = _6266 - float3(_6275);
                float _6634 = 0.48860299587249755859375 * _6547;
                float _6637 = 0.48860299587249755859375 * _6553;
                float _6640 = 0.48860299587249755859375 * _6541;
                float _6645 = 1.09254801273345947265625 * _6541;
                float _6648 = _6645 * _6547;
                float _6654 = (1.09254801273345947265625 * _6547) * _6553;
                float _6662 = 0.3153919875621795654296875 * (((3.0 * _6553) * _6553) - 1.0);
                float _6668 = _6645 * _6553;
                float _6682 = 0.546274006366729736328125 * ((_6541 * _6541) - (_6547 * _6547));
                int3 _6701 = _6268 - int3(1);
                int3 _6702 = min(_6275, _6701);
                int _6707 = _6268.x;
                int _6711 = _6268.y;
                int _6719 = _6531 + ((_6702.x + (_6707 * (_6702.y + (_6711 * _6702.z)))) * 4);
                float3 _6722 = float3(1.0) - _6279;
                float3 _6740 = (((((float3(_6702) + float3(0.5)) / _6227) * _6216) * 2.0) - _6216) - _6454;
                float _6750 = dot(_6740 * rsqrt(fast::max(dot(_6740, _6740), 1.0000000133514319600180897396058e-10)), _6554) + 1.0;
                float _6753 = _6722.x;
                float _6755 = _6722.y;
                float _6756 = _6753 * _6755;
                float _6758 = _6722.z;
                int _6782 = _6719 + 3;
                float _6768 = ((_6756 * _6758) * ((0.25 * (_6750 * _6750)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_6782])[1u])).y > 0.5);
                int _6812 = _6719 + 1;
                int _6816 = _6719 + 2;
                float2 _6828 = float2(as_type<half2>(_1281._m0[_6719].y));
                float2 _6837 = float2(as_type<half2>(_1281._m0[_6812].x));
                float2 _6846 = float2(as_type<half2>(_1281._m0[_6812].w));
                float2 _6855 = float2(as_type<half2>(_1281._m0[_6816].z));
                float3 _6943 = (((((((float3(float2(as_type<half2>(_1281._m0[_6719].x)), _6828.x) * 0.2820949852466583251953125) + (float3(_6828.y, float2(as_type<half2>(_1281._m0[_6719].z))) * _6634)) + (float3(float2(as_type<half2>(_1281._m0[_6719].w)), _6837.x) * _6637)) + (float3(_6837.y, float2(as_type<half2>(_1281._m0[_6812].y))) * _6640)) + (float3(float2(as_type<half2>(_1281._m0[_6812].z)), _6846.x) * _6648)) + (float3(_6846.y, float2(as_type<half2>(_1281._m0[_6816].x))) * _6654)) + (float3(float2(as_type<half2>(_1281._m0[_6816].y)), _6855.x) * _6662)) + (float3(_6855.y, float2(as_type<half2>(_1281._m0[_6816].w))) * _6668);
                int3 _6971 = min((_6275 + int3(1, 0, 0)), _6701);
                int _6988 = _6531 + ((_6971.x + (_6707 * (_6971.y + (_6711 * _6971.z)))) * 4);
                float3 _7009 = (((((float3(_6971) + float3(0.5)) / _6227) * _6216) * 2.0) - _6216) - _6454;
                float _7019 = dot(_7009 * rsqrt(fast::max(dot(_7009, _7009), 1.0000000133514319600180897396058e-10)), _6554) + 1.0;
                float _7025 = _6279.x * _6755;
                int _7051 = _6988 + 3;
                float _7037 = ((_7025 * _6758) * ((0.25 * (_7019 * _7019)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_7051])[1u])).y > 0.5);
                int _7081 = _6988 + 1;
                int _7085 = _6988 + 2;
                float2 _7097 = float2(as_type<half2>(_1281._m0[_6988].y));
                float2 _7106 = float2(as_type<half2>(_1281._m0[_7081].x));
                float2 _7115 = float2(as_type<half2>(_1281._m0[_7081].w));
                float2 _7124 = float2(as_type<half2>(_1281._m0[_7085].z));
                float3 _7212 = (((((((float3(float2(as_type<half2>(_1281._m0[_6988].x)), _7097.x) * 0.2820949852466583251953125) + (float3(_7097.y, float2(as_type<half2>(_1281._m0[_6988].z))) * _6634)) + (float3(float2(as_type<half2>(_1281._m0[_6988].w)), _7106.x) * _6637)) + (float3(_7106.y, float2(as_type<half2>(_1281._m0[_7081].y))) * _6640)) + (float3(float2(as_type<half2>(_1281._m0[_7081].z)), _7115.x) * _6648)) + (float3(_7115.y, float2(as_type<half2>(_1281._m0[_7085].x))) * _6654)) + (float3(float2(as_type<half2>(_1281._m0[_7085].y)), _7124.x) * _6662)) + (float3(_7124.y, float2(as_type<half2>(_1281._m0[_7085].w))) * _6668);
                int3 _7240 = min((_6275 + int3(0, 1, 0)), _6701);
                int _7257 = _6531 + ((_7240.x + (_6707 * (_7240.y + (_6711 * _7240.z)))) * 4);
                float3 _7278 = (((((float3(_7240) + float3(0.5)) / _6227) * _6216) * 2.0) - _6216) - _6454;
                float _7288 = dot(_7278 * rsqrt(fast::max(dot(_7278, _7278), 1.0000000133514319600180897396058e-10)), _6554) + 1.0;
                float _7294 = _6753 * _6279.y;
                int _7320 = _7257 + 3;
                float _7306 = ((_7294 * _6758) * ((0.25 * (_7288 * _7288)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_7320])[1u])).y > 0.5);
                int _7350 = _7257 + 1;
                int _7354 = _7257 + 2;
                float2 _7366 = float2(as_type<half2>(_1281._m0[_7257].y));
                float2 _7375 = float2(as_type<half2>(_1281._m0[_7350].x));
                float2 _7384 = float2(as_type<half2>(_1281._m0[_7350].w));
                float2 _7393 = float2(as_type<half2>(_1281._m0[_7354].z));
                float3 _7481 = (((((((float3(float2(as_type<half2>(_1281._m0[_7257].x)), _7366.x) * 0.2820949852466583251953125) + (float3(_7366.y, float2(as_type<half2>(_1281._m0[_7257].z))) * _6634)) + (float3(float2(as_type<half2>(_1281._m0[_7257].w)), _7375.x) * _6637)) + (float3(_7375.y, float2(as_type<half2>(_1281._m0[_7350].y))) * _6640)) + (float3(float2(as_type<half2>(_1281._m0[_7350].z)), _7384.x) * _6648)) + (float3(_7384.y, float2(as_type<half2>(_1281._m0[_7354].x))) * _6654)) + (float3(float2(as_type<half2>(_1281._m0[_7354].y)), _7393.x) * _6662)) + (float3(_7393.y, float2(as_type<half2>(_1281._m0[_7354].w))) * _6668);
                int3 _7509 = min((_6275 + int3(1, 1, 0)), _6701);
                int _7526 = _6531 + ((_7509.x + (_6707 * (_7509.y + (_6711 * _7509.z)))) * 4);
                float3 _7547 = (((((float3(_7509) + float3(0.5)) / _6227) * _6216) * 2.0) - _6216) - _6454;
                float _7557 = dot(_7547 * rsqrt(fast::max(dot(_7547, _7547), 1.0000000133514319600180897396058e-10)), _6554) + 1.0;
                float _7563 = _6279.x * _6279.y;
                int _7589 = _7526 + 3;
                float _7575 = ((_7563 * _6758) * ((0.25 * (_7557 * _7557)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_7589])[1u])).y > 0.5);
                int _7619 = _7526 + 1;
                int _7623 = _7526 + 2;
                float2 _7635 = float2(as_type<half2>(_1281._m0[_7526].y));
                float2 _7644 = float2(as_type<half2>(_1281._m0[_7619].x));
                float2 _7653 = float2(as_type<half2>(_1281._m0[_7619].w));
                float2 _7662 = float2(as_type<half2>(_1281._m0[_7623].z));
                float3 _7750 = (((((((float3(float2(as_type<half2>(_1281._m0[_7526].x)), _7635.x) * 0.2820949852466583251953125) + (float3(_7635.y, float2(as_type<half2>(_1281._m0[_7526].z))) * _6634)) + (float3(float2(as_type<half2>(_1281._m0[_7526].w)), _7644.x) * _6637)) + (float3(_7644.y, float2(as_type<half2>(_1281._m0[_7619].y))) * _6640)) + (float3(float2(as_type<half2>(_1281._m0[_7619].z)), _7653.x) * _6648)) + (float3(_7653.y, float2(as_type<half2>(_1281._m0[_7623].x))) * _6654)) + (float3(float2(as_type<half2>(_1281._m0[_7623].y)), _7662.x) * _6662)) + (float3(_7662.y, float2(as_type<half2>(_1281._m0[_7623].w))) * _6668);
                int3 _7778 = min((_6275 + int3(0, 0, 1)), _6701);
                int _7795 = _6531 + ((_7778.x + (_6707 * (_7778.y + (_6711 * _7778.z)))) * 4);
                float3 _7816 = (((((float3(_7778) + float3(0.5)) / _6227) * _6216) * 2.0) - _6216) - _6454;
                float _7826 = dot(_7816 * rsqrt(fast::max(dot(_7816, _7816), 1.0000000133514319600180897396058e-10)), _6554) + 1.0;
                int _7858 = _7795 + 3;
                float _7844 = ((_6756 * _6279.z) * ((0.25 * (_7826 * _7826)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_7858])[1u])).y > 0.5);
                int _7888 = _7795 + 1;
                int _7892 = _7795 + 2;
                float2 _7904 = float2(as_type<half2>(_1281._m0[_7795].y));
                float2 _7913 = float2(as_type<half2>(_1281._m0[_7888].x));
                float2 _7922 = float2(as_type<half2>(_1281._m0[_7888].w));
                float2 _7931 = float2(as_type<half2>(_1281._m0[_7892].z));
                float3 _8019 = (((((((float3(float2(as_type<half2>(_1281._m0[_7795].x)), _7904.x) * 0.2820949852466583251953125) + (float3(_7904.y, float2(as_type<half2>(_1281._m0[_7795].z))) * _6634)) + (float3(float2(as_type<half2>(_1281._m0[_7795].w)), _7913.x) * _6637)) + (float3(_7913.y, float2(as_type<half2>(_1281._m0[_7888].y))) * _6640)) + (float3(float2(as_type<half2>(_1281._m0[_7888].z)), _7922.x) * _6648)) + (float3(_7922.y, float2(as_type<half2>(_1281._m0[_7892].x))) * _6654)) + (float3(float2(as_type<half2>(_1281._m0[_7892].y)), _7931.x) * _6662)) + (float3(_7931.y, float2(as_type<half2>(_1281._m0[_7892].w))) * _6668);
                float4 _6346 = (((float4((_6943 + (float3(float2(as_type<half2>(_1281._m0[_6782].x)), float2(as_type<half2>(_1281._m0[_6782].y)).x) * _6682)) * _6768, _6768) + float4((_7212 + (float3(float2(as_type<half2>(_1281._m0[_7051].x)), float2(as_type<half2>(_1281._m0[_7051].y)).x) * _6682)) * _7037, _7037)) + float4((_7481 + (float3(float2(as_type<half2>(_1281._m0[_7320].x)), float2(as_type<half2>(_1281._m0[_7320].y)).x) * _6682)) * _7306, _7306)) + float4((_7750 + (float3(float2(as_type<half2>(_1281._m0[_7589].x)), float2(as_type<half2>(_1281._m0[_7589].y)).x) * _6682)) * _7575, _7575)) + float4((_8019 + (float3(float2(as_type<half2>(_1281._m0[_7858].x)), float2(as_type<half2>(_1281._m0[_7858].y)).x) * _6682)) * _7844, _7844);
                int3 _8047 = min((_6275 + int3(1, 0, 1)), _6701);
                int _8064 = _6531 + ((_8047.x + (_6707 * (_8047.y + (_6711 * _8047.z)))) * 4);
                float3 _8085 = (((((float3(_8047) + float3(0.5)) / _6227) * _6216) * 2.0) - _6216) - _6454;
                float _8095 = dot(_8085 * rsqrt(fast::max(dot(_8085, _8085), 1.0000000133514319600180897396058e-10)), _6554) + 1.0;
                int _8127 = _8064 + 3;
                float _8113 = ((_7025 * _6279.z) * ((0.25 * (_8095 * _8095)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_8127])[1u])).y > 0.5);
                int _8157 = _8064 + 1;
                int _8161 = _8064 + 2;
                float2 _8173 = float2(as_type<half2>(_1281._m0[_8064].y));
                float2 _8182 = float2(as_type<half2>(_1281._m0[_8157].x));
                float2 _8191 = float2(as_type<half2>(_1281._m0[_8157].w));
                float2 _8200 = float2(as_type<half2>(_1281._m0[_8161].z));
                float3 _8288 = (((((((float3(float2(as_type<half2>(_1281._m0[_8064].x)), _8173.x) * 0.2820949852466583251953125) + (float3(_8173.y, float2(as_type<half2>(_1281._m0[_8064].z))) * _6634)) + (float3(float2(as_type<half2>(_1281._m0[_8064].w)), _8182.x) * _6637)) + (float3(_8182.y, float2(as_type<half2>(_1281._m0[_8157].y))) * _6640)) + (float3(float2(as_type<half2>(_1281._m0[_8157].z)), _8191.x) * _6648)) + (float3(_8191.y, float2(as_type<half2>(_1281._m0[_8161].x))) * _6654)) + (float3(float2(as_type<half2>(_1281._m0[_8161].y)), _8200.x) * _6662)) + (float3(_8200.y, float2(as_type<half2>(_1281._m0[_8161].w))) * _6668);
                int3 _8316 = min((_6275 + int3(0, 1, 1)), _6701);
                int _8333 = _6531 + ((_8316.x + (_6707 * (_8316.y + (_6711 * _8316.z)))) * 4);
                float3 _8354 = (((((float3(_8316) + float3(0.5)) / _6227) * _6216) * 2.0) - _6216) - _6454;
                float _8364 = dot(_8354 * rsqrt(fast::max(dot(_8354, _8354), 1.0000000133514319600180897396058e-10)), _6554) + 1.0;
                int _8396 = _8333 + 3;
                float _8382 = ((_7294 * _6279.z) * ((0.25 * (_8364 * _8364)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_8396])[1u])).y > 0.5);
                int _8426 = _8333 + 1;
                int _8430 = _8333 + 2;
                float2 _8442 = float2(as_type<half2>(_1281._m0[_8333].y));
                float2 _8451 = float2(as_type<half2>(_1281._m0[_8426].x));
                float2 _8460 = float2(as_type<half2>(_1281._m0[_8426].w));
                float2 _8469 = float2(as_type<half2>(_1281._m0[_8430].z));
                float3 _8557 = (((((((float3(float2(as_type<half2>(_1281._m0[_8333].x)), _8442.x) * 0.2820949852466583251953125) + (float3(_8442.y, float2(as_type<half2>(_1281._m0[_8333].z))) * _6634)) + (float3(float2(as_type<half2>(_1281._m0[_8333].w)), _8451.x) * _6637)) + (float3(_8451.y, float2(as_type<half2>(_1281._m0[_8426].y))) * _6640)) + (float3(float2(as_type<half2>(_1281._m0[_8426].z)), _8460.x) * _6648)) + (float3(_8460.y, float2(as_type<half2>(_1281._m0[_8430].x))) * _6654)) + (float3(float2(as_type<half2>(_1281._m0[_8430].y)), _8469.x) * _6662)) + (float3(_8469.y, float2(as_type<half2>(_1281._m0[_8430].w))) * _6668);
                int3 _8585 = min((_6275 + int3(1)), _6701);
                int _8602 = _6531 + ((_8585.x + (_6707 * (_8585.y + (_6711 * _8585.z)))) * 4);
                float3 _8623 = (((((float3(_8585) + float3(0.5)) / _6227) * _6216) * 2.0) - _6216) - _6454;
                float _8633 = dot(_8623 * rsqrt(fast::max(dot(_8623, _8623), 1.0000000133514319600180897396058e-10)), _6554) + 1.0;
                int _8665 = _8602 + 3;
                float _8651 = ((_7563 * _6279.z) * ((0.25 * (_8633 * _8633)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_8665])[1u])).y > 0.5);
                int _8695 = _8602 + 1;
                int _8699 = _8602 + 2;
                float2 _8711 = float2(as_type<half2>(_1281._m0[_8602].y));
                float2 _8720 = float2(as_type<half2>(_1281._m0[_8695].x));
                float2 _8729 = float2(as_type<half2>(_1281._m0[_8695].w));
                float2 _8738 = float2(as_type<half2>(_1281._m0[_8699].z));
                float3 _8826 = (((((((float3(float2(as_type<half2>(_1281._m0[_8602].x)), _8711.x) * 0.2820949852466583251953125) + (float3(_8711.y, float2(as_type<half2>(_1281._m0[_8602].z))) * _6634)) + (float3(float2(as_type<half2>(_1281._m0[_8602].w)), _8720.x) * _6637)) + (float3(_8720.y, float2(as_type<half2>(_1281._m0[_8695].y))) * _6640)) + (float3(float2(as_type<half2>(_1281._m0[_8695].z)), _8729.x) * _6648)) + (float3(_8729.y, float2(as_type<half2>(_1281._m0[_8699].x))) * _6654)) + (float3(float2(as_type<half2>(_1281._m0[_8699].y)), _8738.x) * _6662)) + (float3(_8738.y, float2(as_type<half2>(_1281._m0[_8699].w))) * _6668);
                float4 _6385 = ((_6346 + float4((_8288 + (float3(float2(as_type<half2>(_1281._m0[_8127].x)), float2(as_type<half2>(_1281._m0[_8127].y)).x) * _6682)) * _8113, _8113)) + float4((_8557 + (float3(float2(as_type<half2>(_1281._m0[_8396].x)), float2(as_type<half2>(_1281._m0[_8396].y)).x) * _6682)) * _8382, _8382)) + float4((_8826 + (float3(float2(as_type<half2>(_1281._m0[_8665].x)), float2(as_type<half2>(_1281._m0[_8665].y)).x) * _6682)) * _8651, _8651);
                float _6389 = _6385.w;
                float3 _17526;
                if (_6389 > 9.9999997473787516355514526367188e-06)
                {
                    _17526 = mix(_17230, (fast::max(_6385.xyz, float3(0.0)) / float3(_6389)) * _6525.z, float3(_17488));
                }
                else
                {
                    _17526 = _17230;
                }
                _17525 = _17526;
            }
            _17231 = _17230;
        }
        else
        {
            _17231 = _17226;
        }
        float3 _3792 = (_16679 * ((_17231 * _17004) + ((_3686 * fast::max(_3726, 0.0)) * _16719))) + ((_3686 * ((powr(fast::max(dot(_16685, _3649), 0.0), _2876._m1.w) * _2876._m1.z) * step(0.0, _3726))) * _16719);
        float3 _17246;
        if (_283._m13.w > 0.5)
        {
            float2 _8864 = fast::clamp(floor(gl_FragCoord.xy * _283._m12.xy), float2(0.0), _283._m13.xy - float2(1.0));
            uint _8892 = uint((((fast::clamp(floor((log2(fast::max(dot(_283._m11.xyz, in.m_3037) + _283._m11.w, 9.9999999747524270787835121154785e-07)) * _283._m12.z) + _283._m12.w), 0.0, _283._m13.z - 1.0) * _283._m13.y) + _8864.y) * _283._m13.x) + _8864.x);
            uint _8894 = _8892 >> uint(2);
            uint _8896 = _8892 & 3u;
            uint _8900 = _3167._m0[_8894][_8896] & 65535u;
            uint _8902 = _3167._m0[_8894][_8896] >> uint(16);
            float3 _17247;
            _17247 = _3792;
            float3 _3872;
            spvUnsafeArray<float2, 3> _9310;
            spvUnsafeArray<float2, 3> _9311;
            spvUnsafeArray<float2, 3> _9523;
            spvUnsafeArray<float2, 3> _9524;
            for (uint _17244 = _8900; _17244 < (_8900 + _8902); _17247 = _3872, _17244++)
            {
                uint _8908 = _17244 / 3u;
                uint _8921 = (_3188._m0[_8908 >> uint(2)][_8908 & 3u] >> ((_17244 - (_8908 * 3u)) * 10u)) & 1023u;
                float3 _8938 = _3030._m0[_8921].xyz - in.m_3037;
                float _8941 = dot(_8938, _8938);
                float _8945 = _8941 * _3030._m0[_8921].w;
                float _8950 = fast::clamp(1.0 - (_8945 * _8945), 0.0, 1.0);
                float3 _8955 = _8938 * rsqrt(fast::max(_8941, 9.9999999392252902907785028219223e-09));
                float _8973 = fast::clamp((dot(-_8955, _3073._m0[_8921].xyz) * _3065._m0[_8921].w) + _3073._m0[_8921].w, 0.0, 1.0);
                float3 _8986 = _3065._m0[_8921].xyz * ((((_8950 * _8950) * _8973) * _8973) / fast::max(_8941, 9.9999997473787516355514526367188e-05));
                float3 _17453;
                if (_3660)
                {
                    float _17399;
                    do
                    {
                        uint _9022 = uint(_283._m21.z);
                        if (_8921 < _9022)
                        {
                            float _9044 = _283._m26[_8921].z * fast::max((_283._m15[_8921] * float4(in.m_3037, 1.0)).w, 0.0);
                            float4 _9068 = _283._m15[_8921] * float4((in.m_3037 + (_3655 * (_9044 * _283._m25.x))) + (_8955 * (_9044 * _283._m25.y)), 1.0);
                            float _9070 = _9068.w;
                            if (_9070 <= 0.0)
                            {
                                _17399 = 1.0;
                                break;
                            }
                            float3 _9079 = _9068.xyz / float3(_9070);
                            float _9081 = _9079.x;
                            bool _9082 = _9081 < 0.0;
                            bool _9089;
                            if (!_9082)
                            {
                                _9089 = _9081 > 1.0;
                            }
                            else
                            {
                                _9089 = _9082;
                            }
                            bool _9096;
                            if (!_9089)
                            {
                                _9096 = _9079.y < 0.0;
                            }
                            else
                            {
                                _9096 = _9089;
                            }
                            bool _9103;
                            if (!_9096)
                            {
                                _9103 = _9079.y > 1.0;
                            }
                            else
                            {
                                _9103 = _9096;
                            }
                            bool _9110;
                            if (!_9103)
                            {
                                _9110 = _9079.z > 1.0;
                            }
                            else
                            {
                                _9110 = _9103;
                            }
                            if (_9110)
                            {
                                _17399 = 1.0;
                                break;
                            }
                            float _9116 = _9079.z;
                            float2 _9282 = _283._m22.xy * 0.5;
                            float2 _9287 = _283._m26[_8921].xy + (_9079.xy * _283._m23.zw);
                            float4 _9300 = float4(_283._m26[_8921].xy + _9282, (_283._m26[_8921].xy + _283._m23.zw) - _9282);
                            float _17398;
                            do
                            {
                                int _9326 = int(_283._m22.z);
                                if (_9326 <= 0)
                                {
                                    float2 _9336 = fast::clamp(_9287, _9300.xy, _9300.zw);
                                    _17398 = spvDepthCast(_303).sample_compare(_303Smplr, float3(_9336, _9116).xy, _9116);
                                    break;
                                }
                                float2 _9349 = (_9287 / _283._m22.xy) + float2(0.5);
                                float2 _9350 = floor(_9349);
                                float2 _9355 = _9349 - _9350;
                                float2 _9358 = _9350 - float2(0.5);
                                bool _9362 = _9326 == 1;
                                if (_9362)
                                {
                                    float2 _9365 = _9355 * 2.0;
                                    _9310[0] = float2(3.0) - _9365;
                                    _9310[1] = float2(1.0) + _9365;
                                    _9311[0] = ((float2(2.0) - _9355) / _9310[0]) - float2(1.0);
                                    _9311[1] = (_9355 / _9310[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _9392 = _9355 * 3.0;
                                    _9310[0] = float2(4.0) - _9392;
                                    _9310[1] = float2(7.0);
                                    _9310[2] = float2(1.0) + _9392;
                                    _9311[0] = ((float2(3.0) - (_9355 * 2.0)) / _9310[0]) - float2(2.0);
                                    _9311[1] = (float2(3.0) + _9355) / _9310[1];
                                    _9311[2] = (_9355 / _9310[2]) + float2(2.0);
                                }
                                int _17645 = _9362 ? 2 : 3;
                                int _17388;
                                float _17391;
                                _17391 = 0.0;
                                _17388 = 0;
                                float _17397;
                                for (; _17388 < _17645; _17391 = _17397, _17388++)
                                {
                                    _17397 = _17391;
                                    for (int _17394 = 0; _17394 < _17645; )
                                    {
                                        _17397 += ((_9310[_17394].x * _9310[_17388].y) * spvDepthCast(_303).sample_compare(_303Smplr, float3(fast::clamp(_283._m22.xy * (_9358 + float2(_9311[_17394].x, _9311[_17388].y)), _9300.xy, _9300.zw), _9116).xy, _9116));
                                        _17394++;
                                        continue;
                                    }
                                }
                                _17398 = _17391 * (_9362 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _17399 = _17398;
                            break;
                        }
                        uint _9126 = _8921 - _9022;
                        if (_9126 >= uint(_283._m21.w))
                        {
                            _17399 = 1.0;
                            break;
                        }
                        float _9147 = _283._m27[_9126].w * length(in.m_3037 - _283._m27[_9126].xyz);
                        float3 _9165 = ((in.m_3037 + (_3655 * (_9147 * _283._m25.x))) + (_8955 * (_9147 * _283._m25.y))) - _283._m27[_9126].xyz;
                        float3 _9167 = abs(_9165);
                        float _9169 = _9167.x;
                        float _9171 = _9167.y;
                        bool _9172 = _9169 >= _9171;
                        bool _9180;
                        if (_9172)
                        {
                            _9180 = _9169 >= _9167.z;
                        }
                        else
                        {
                            _9180 = _9172;
                        }
                        float _17373;
                        int _17375;
                        if (_9180)
                        {
                            _17375 = (_9165.x > 0.0) ? 0 : 1;
                            _17373 = _9169;
                        }
                        else
                        {
                            float _9192 = _9167.z;
                            bool _9193 = _9171 >= _9192;
                            int _17376;
                            if (_9193)
                            {
                                _17376 = (_9165.y > 0.0) ? 2 : 3;
                            }
                            else
                            {
                                _17376 = (_9165.z > 0.0) ? 4 : 5;
                            }
                            _17375 = _17376;
                            _17373 = _9193 ? _9171 : _9192;
                        }
                        if (_17373 <= 0.0)
                        {
                            _17399 = 1.0;
                            break;
                        }
                        float2 _9230 = float2(dot(_9165, _961[_17375]), dot(_9165, _970[_17375])) / float2(_17373 * _283._m24.z);
                        float _9237 = _283._m28[_9126].z + (_283._m28[_9126].w / _17373);
                        if (_9237 > 1.0)
                        {
                            _17399 = 1.0;
                            break;
                        }
                        float2 _9255 = _283._m28[_9126].xy + (float2(float(spvSMod(_17375, 3)), float(_17375 / 3)) * _283._m24.xy);
                        float2 _9495 = _283._m22.xy * 0.5;
                        float2 _9500 = _9255 + (float2(0.5 + (0.5 * _9230.x), 0.5 - (0.5 * _9230.y)) * _283._m24.xy);
                        float4 _9513 = float4(_9255 + _9495, (_9255 + _283._m24.xy) - _9495);
                        float _17387;
                        do
                        {
                            int _9539 = int(_283._m22.z);
                            if (_9539 <= 0)
                            {
                                _17387 = spvDepthCast(_303).sample_compare(_303Smplr, float3(fast::clamp(_9500, _9513.xy, _9513.zw), _9237).xy, _9237);
                                break;
                            }
                            float2 _9562 = (_9500 / _283._m22.xy) + float2(0.5);
                            float2 _9563 = floor(_9562);
                            float2 _9568 = _9562 - _9563;
                            float2 _9571 = _9563 - float2(0.5);
                            bool _9575 = _9539 == 1;
                            if (_9575)
                            {
                                float2 _9578 = _9568 * 2.0;
                                _9523[0] = float2(3.0) - _9578;
                                _9523[1] = float2(1.0) + _9578;
                                _9524[0] = ((float2(2.0) - _9568) / _9523[0]) - float2(1.0);
                                _9524[1] = (_9568 / _9523[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _9605 = _9568 * 3.0;
                                _9523[0] = float2(4.0) - _9605;
                                _9523[1] = float2(7.0);
                                _9523[2] = float2(1.0) + _9605;
                                _9524[0] = ((float2(3.0) - (_9568 * 2.0)) / _9523[0]) - float2(2.0);
                                _9524[1] = (float2(3.0) + _9568) / _9523[1];
                                _9524[2] = (_9568 / _9523[2]) + float2(2.0);
                            }
                            int _17648 = _9575 ? 2 : 3;
                            int _17377;
                            float _17380;
                            _17380 = 0.0;
                            _17377 = 0;
                            float _17386;
                            for (; _17377 < _17648; _17380 = _17386, _17377++)
                            {
                                _17386 = _17380;
                                for (int _17383 = 0; _17383 < _17648; )
                                {
                                    _17386 += ((_9523[_17383].x * _9523[_17377].y) * spvDepthCast(_303).sample_compare(_303Smplr, float3(fast::clamp(_283._m22.xy * (_9571 + float2(_9524[_17383].x, _9524[_17377].y)), _9513.xy, _9513.zw), _9237).xy, _9237));
                                    _17383++;
                                    continue;
                                }
                            }
                            _17387 = _17380 * (_9575 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _17399 = _17387;
                        break;
                    } while(false);
                    _17453 = _8986 * _17399;
                }
                else
                {
                    _17453 = _8986;
                }
                float _3843 = dot(_16685, _8955);
                _3872 = _17247 + (((_16679 * fast::max(_3843, 0.0)) * _17453) + (_17453 * ((powr(fast::max(dot(_16685, fast::normalize(_8955 + _3644)), 0.0), _2876._m1.w) * _2876._m1.z) * step(0.0, _3843))));
            }
            _17246 = _17247;
        }
        else
        {
            _17246 = _3792;
        }
        _17315 = _17231;
        _17245 = _17246;
    }
    else
    {
        float4 _3882 = _3877.sample(_2533, _3419);
        float _3889 = fast::clamp(_2876._m4.x * _3882.z, 0.0, 1.0);
        float _3897 = fast::clamp(_2876._m4.y * _3882.y, 0.04500000178813934326171875, 1.0);
        float _16675;
        float _16680;
        if (_16616 > 0.0)
        {
            _16680 = mix(_3889, _16649.y, _16616);
            _16675 = mix(_3897, fast::max(_16649.x, 0.04500000178813934326171875), _16616);
        }
        else
        {
            _16680 = _3889;
            _16675 = _3897;
        }
        float _3916 = _16675 * _16675;
        float3 _3921 = _16679 * (1.0 - _16680);
        float3 _3927 = mix(float3(0.039999999105930328369140625), _16679, float3(_16680));
        bool _3931 = _16495 > 0.0;
        float3 _16708;
        if (_3931)
        {
            float3 _3936 = dfdx(in.m_3037);
            float3 _3938 = dfdy(in.m_3037);
            float3 _3939 = cross(_3936, _3938);
            float3 _16709;
            if (dot(_3939, _3939) > 9.9999996826552253889678874634872e-21)
            {
                _16709 = fast::normalize((fast::normalize(_3939) * ((dot(_3939, _3644) < 0.0) ? (-1.0) : 1.0)) + (_16685 - _3500));
            }
            else
            {
                _16709 = _16685;
            }
            _16708 = _16709;
        }
        else
        {
            _16708 = _16685;
        }
        float _3965 = fast::max(dot(_16708, _3644), 9.9999997473787516355514526367188e-05);
        float _3974 = dot(_16708, _3637);
        float _3975 = fast::clamp(_3974, 0.0, 1.0);
        float _3980 = fast::clamp(dot(_16708, _3649), 0.0, 1.0);
        float _3985 = fast::clamp(dot(_3644, _3649), 0.0, 1.0);
        float _16712;
        float _16713;
        if (_3931)
        {
            _16713 = fast::max(_3965, 0.5);
            _16712 = fast::max(_3985, 0.5);
        }
        else
        {
            _16713 = _3965;
            _16712 = _3985;
        }
        float3 _9707 = float3(1.0) - _3927;
        float3 _9710 = _3927 + (_9707 * powr(1.0 - _16712, 5.0));
        float _9717 = _3916 * _3916;
        float _9722 = _9717 - 1.0;
        float _9724 = ((_3980 * _3980) * _9722) + 1.0;
        float _9744 = 1.0 - _9717;
        float _9748 = sqrt(((_16713 * _16713) * _9744) + _9717);
        float3 _4031 = (((((float3(1.0) - _9710) * _3921) * fast::clamp(dot(_16685, _3637), 0.0, 1.0)) + (((_9710 * ((_9717 / ((3.1415927410125732421875 * _9724) * _9724)) * (0.5 / fast::max((_3975 * _9748) + (_16713 * sqrt(((_3975 * _3975) * _9744) + _9717)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875) * _3975)) * _3686) * _16719;
        float3 _17041;
        if (_3931)
        {
            _17041 = _4031 + (((((_3921 * _3686) * _16719) * _16495) * fast::clamp(-_3974, 0.0, 1.0)) * (0.3499999940395355224609375 + (0.64999997615814208984375 * powr(fast::clamp(dot(-_3644, _3637), 0.0, 1.0), 3.0))));
        }
        else
        {
            _17041 = _4031;
        }
        float3 _16748;
        float3 _16775;
        float2 _16952;
        if (_283._m29.x > 0.5)
        {
            float4 _9781 = _2632.sample(_2634, (((float2(_16713, _16675) * 31.0) + float2(0.5)) * float2(0.03125)));
            float _9840 = (_283._m29.z * _16685.x) - (_283._m29.w * _16685.z);
            float _9853 = (_283._m29.w * _16685.x) + (_283._m29.z * _16685.z);
            float _9871 = 1.09254801273345947265625 * _9840;
            spvUnsafeArray<float, 9> _15343 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _16685.y, 0.48860299587249755859375 * _9853, 0.48860299587249755859375 * _9840, _9871 * _16685.y, (1.09254801273345947265625 * _16685.y) * _9853, 0.3153919875621795654296875 * (((3.0 * _9853) * _9853) - 1.0), _9871 * _9853, 0.546274006366729736328125 * ((_9840 * _9840) - (_16685.y * _16685.y)) });
            spvUnsafeArray<float, 9> _9785 = _15343;
            float3 _16731;
            _16731 = float3(0.0);
            for (int _16730 = 0; _16730 < 9; )
            {
                _16731 += (_2531.read(uint2((int2(496, 256) + int2(_16730, 0))), 0).xyz * _9785[_16730]);
                _16730++;
                continue;
            }
            float3 _4083 = reflect(-_3644, _16708);
            float _9966 = _4083.x;
            float _9971 = _4083.z;
            float2 _10003 = float2((precise::atan2((_283._m29.z * _9966) - (_283._m29.w * _9971), -((_283._m29.w * _9966) + (_283._m29.z * _9971))) * 0.15915493667125701904296875) + 0.5, acos(fast::clamp(_4083.y, -1.0, 1.0)) * 0.3183098733425140380859375);
            float _9935 = _16675 * 5.0;
            int _9938 = min(int(_9935), 4);
            float2 _10024 = (_10003 * float2(_2588[_9938].zw)) - float2(0.5);
            float2 _10026 = floor(_10024);
            float2 _10029 = _10024 - _10026;
            int _10032 = int(_10026.x);
            int _10035 = int(_10026.y);
            int _16734;
            if (_10032 < 0)
            {
                _16734 = _10032 + _2588[_9938].z;
            }
            else
            {
                _16734 = _10032;
            }
            int _16735;
            if (_16734 >= _2588[_9938].z)
            {
                _16735 = _16734 - _2588[_9938].z;
            }
            else
            {
                _16735 = _16734;
            }
            int _10055 = _16735 + 1;
            int _17649 = (_10055 == _2588[_9938].z) ? 0 : _10055;
            int _10070 = min((_10035 + 1), (_2588[_9938].w - 1));
            int _10072 = max(_10035, 0);
            float3 _10125 = float3(_10029.x);
            int _9945 = _9938 + 1;
            float2 _10157 = (_10003 * float2(_2588[_9945].zw)) - float2(0.5);
            float2 _10159 = floor(_10157);
            float2 _10162 = _10157 - _10159;
            int _10165 = int(_10159.x);
            int _10168 = int(_10159.y);
            int _16741;
            if (_10165 < 0)
            {
                _16741 = _10165 + _2588[_9945].z;
            }
            else
            {
                _16741 = _10165;
            }
            int _16742;
            if (_16741 >= _2588[_9945].z)
            {
                _16742 = _16741 - _2588[_9945].z;
            }
            else
            {
                _16742 = _16741;
            }
            int _10188 = _16742 + 1;
            int _17650 = (_10188 == _2588[_9945].z) ? 0 : _10188;
            int _10203 = min((_10168 + 1), (_2588[_9945].w - 1));
            int _10205 = max(_10168, 0);
            float3 _10258 = float3(_10162.x);
            float3 _9960 = mix(mix(mix(_2531.read(uint2((_2588[_9938].xy + int2(_16735, _10072))), 0).xyz, _2531.read(uint2((_2588[_9938].xy + int2(_17649, _10072))), 0).xyz, _10125), mix(_2531.read(uint2((_2588[_9938].xy + int2(_16735, _10070))), 0).xyz, _2531.read(uint2((_2588[_9938].xy + int2(_17649, _10070))), 0).xyz, _10125), float3(_10029.y)), mix(mix(_2531.read(uint2((_2588[_9945].xy + int2(_16742, _10205))), 0).xyz, _2531.read(uint2((_2588[_9945].xy + int2(_17650, _10205))), 0).xyz, _10258), mix(_2531.read(uint2((_2588[_9945].xy + int2(_16742, _10203))), 0).xyz, _2531.read(uint2((_2588[_9945].xy + int2(_17650, _10203))), 0).xyz, _10258), float3(_10162.y)), float3(_9935 - float(_9938))) * _283._m29.y;
            _16952 = _9781.xy;
            _16775 = _9960;
            _16748 = fast::max(_16731, float3(0.0)) * _283._m29.y;
        }
        else
        {
            float4 _10276 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * _16675) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);
            float _10278 = _10276.x;
            float3 _10313 = mix(_283._m9.xyz, _283._m8.xyz, float3((_16685.y * 0.5) + 0.5)) * _283._m8.w;
            _16952 = (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_10278 * _10278, exp2((-9.27999973297119140625) * _16713)) * _10278) + _10276.y)) + _10276.zw;
            _16775 = mix(mix(_283._m9.xyz, _283._m8.xyz, float3((reflect(-_3644, _16708).y * 0.5) + 0.5)) * _283._m8.w, _10313, float3(_16675));
            _16748 = _10313;
        }
        float3 _16875;
        if (_283._m34.y > 0.5)
        {
            int _10450 = int(_283._m34.y);
            int _10453 = int(_283._m34.x);
            float3 _16764;
            _16764 = _16748;
            float3 _17495;
            for (int _16763 = 0; _16763 < _10450; _16764 = _17495, _16763++)
            {
                int _10465 = 8 * (_10453 + _16763);
                float4 _10674 = as_type<float4>(_1281._m0[_10465 + 3]);
                float4 _10718 = as_type<float4>(_1281._m0[_10465]);
                float4 _10724 = as_type<float4>(_1281._m0[_10465 + 1]);
                float4 _10730 = as_type<float4>(_1281._m0[_10465 + 2]);
                float3 _10692 = _10718.xyz;
                float _10696 = _10718.w;
                float3 _10699 = _10724.xyz;
                float _10703 = _10724.w;
                float3 _10706 = _10730.xyz;
                float _10710 = _10730.w;
                float3 _10712 = float3(dot(_10692, in.m_3037) + _10696, dot(_10699, in.m_3037) + _10703, dot(_10706, in.m_3037) + _10710);
                float3 _10474 = _10674.xyz;
                float _10476 = _10674.w;
                float _17219;
                do
                {
                    float3 _10742 = _10474 - abs(_10712);
                    float _10750 = fast::min(_10742.x, fast::min(_10742.y, _10742.z));
                    if (_10750 <= 0.0)
                    {
                        _17219 = 0.0;
                        break;
                    }
                    if (_10476 <= 0.0)
                    {
                        _17219 = 1.0;
                        break;
                    }
                    float _10762 = fast::min(_10750 / _10476, 1.0);
                    _17219 = (_10762 * _10762) * (3.0 - (2.0 * _10762));
                    break;
                } while(false);
                if (_17219 <= 0.0)
                {
                    _17495 = _16764;
                    continue;
                }
                float3 _10485 = as_type<float4>(_1281._m0[_10465 + 4]).xyz;
                float4 _10783 = as_type<float4>(_1281._m0[_10465 + 5]);
                int _10789 = int(((device uint*)&_1281._m0[_10465 + 6])[0u]);
                float _10799 = dot(_10692, _16685);
                float _10805 = dot(_10699, _16685);
                float _10811 = dot(_10706, _16685);
                float3 _10812 = float3(_10799, _10805, _10811);
                float3 _10505 = (in.m_3037 + (_16685 * _10783.x)) + (_3644 * _10783.y);
                float3 _10524 = fast::clamp((((float3(dot(_10692, _10505) + _10696, dot(_10699, _10505) + _10703, dot(_10706, _10505) + _10710) + _10474) / fast::max(_10474 * 2.0, float3(9.9999999747524270787835121154785e-07))) * _10485) - float3(0.5), float3(0.0), _10485 - float3(1.0));
                int3 _10526 = int3(_10485);
                int3 _10533 = min(int3(_10524), max((_10526 - int3(2)), int3(0)));
                float3 _10537 = _10524 - float3(_10533);
                float _10892 = 0.48860299587249755859375 * _10805;
                float _10895 = 0.48860299587249755859375 * _10811;
                float _10898 = 0.48860299587249755859375 * _10799;
                float _10903 = 1.09254801273345947265625 * _10799;
                float _10906 = _10903 * _10805;
                float _10912 = (1.09254801273345947265625 * _10805) * _10811;
                float _10920 = 0.3153919875621795654296875 * (((3.0 * _10811) * _10811) - 1.0);
                float _10926 = _10903 * _10811;
                float _10940 = 0.546274006366729736328125 * ((_10799 * _10799) - (_10805 * _10805));
                int3 _10959 = _10526 - int3(1);
                int3 _10960 = min(_10533, _10959);
                int _10965 = _10526.x;
                int _10969 = _10526.y;
                int _10977 = _10789 + ((_10960.x + (_10965 * (_10960.y + (_10969 * _10960.z)))) * 4);
                float3 _10980 = float3(1.0) - _10537;
                float3 _10998 = (((((float3(_10960) + float3(0.5)) / _10485) * _10474) * 2.0) - _10474) - _10712;
                float _11008 = dot(_10998 * rsqrt(fast::max(dot(_10998, _10998), 1.0000000133514319600180897396058e-10)), _10812) + 1.0;
                float _11011 = _10980.x;
                float _11013 = _10980.y;
                float _11014 = _11011 * _11013;
                float _11016 = _10980.z;
                int _11040 = _10977 + 3;
                float _11026 = ((_11014 * _11016) * ((0.25 * (_11008 * _11008)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_11040])[1u])).y > 0.5);
                int _11070 = _10977 + 1;
                int _11074 = _10977 + 2;
                float2 _11086 = float2(as_type<half2>(_1281._m0[_10977].y));
                float2 _11095 = float2(as_type<half2>(_1281._m0[_11070].x));
                float2 _11104 = float2(as_type<half2>(_1281._m0[_11070].w));
                float2 _11113 = float2(as_type<half2>(_1281._m0[_11074].z));
                float3 _11201 = (((((((float3(float2(as_type<half2>(_1281._m0[_10977].x)), _11086.x) * 0.2820949852466583251953125) + (float3(_11086.y, float2(as_type<half2>(_1281._m0[_10977].z))) * _10892)) + (float3(float2(as_type<half2>(_1281._m0[_10977].w)), _11095.x) * _10895)) + (float3(_11095.y, float2(as_type<half2>(_1281._m0[_11070].y))) * _10898)) + (float3(float2(as_type<half2>(_1281._m0[_11070].z)), _11104.x) * _10906)) + (float3(_11104.y, float2(as_type<half2>(_1281._m0[_11074].x))) * _10912)) + (float3(float2(as_type<half2>(_1281._m0[_11074].y)), _11113.x) * _10920)) + (float3(_11113.y, float2(as_type<half2>(_1281._m0[_11074].w))) * _10926);
                int3 _11229 = min((_10533 + int3(1, 0, 0)), _10959);
                int _11246 = _10789 + ((_11229.x + (_10965 * (_11229.y + (_10969 * _11229.z)))) * 4);
                float3 _11267 = (((((float3(_11229) + float3(0.5)) / _10485) * _10474) * 2.0) - _10474) - _10712;
                float _11277 = dot(_11267 * rsqrt(fast::max(dot(_11267, _11267), 1.0000000133514319600180897396058e-10)), _10812) + 1.0;
                float _11283 = _10537.x * _11013;
                int _11309 = _11246 + 3;
                float _11295 = ((_11283 * _11016) * ((0.25 * (_11277 * _11277)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_11309])[1u])).y > 0.5);
                int _11339 = _11246 + 1;
                int _11343 = _11246 + 2;
                float2 _11355 = float2(as_type<half2>(_1281._m0[_11246].y));
                float2 _11364 = float2(as_type<half2>(_1281._m0[_11339].x));
                float2 _11373 = float2(as_type<half2>(_1281._m0[_11339].w));
                float2 _11382 = float2(as_type<half2>(_1281._m0[_11343].z));
                float3 _11470 = (((((((float3(float2(as_type<half2>(_1281._m0[_11246].x)), _11355.x) * 0.2820949852466583251953125) + (float3(_11355.y, float2(as_type<half2>(_1281._m0[_11246].z))) * _10892)) + (float3(float2(as_type<half2>(_1281._m0[_11246].w)), _11364.x) * _10895)) + (float3(_11364.y, float2(as_type<half2>(_1281._m0[_11339].y))) * _10898)) + (float3(float2(as_type<half2>(_1281._m0[_11339].z)), _11373.x) * _10906)) + (float3(_11373.y, float2(as_type<half2>(_1281._m0[_11343].x))) * _10912)) + (float3(float2(as_type<half2>(_1281._m0[_11343].y)), _11382.x) * _10920)) + (float3(_11382.y, float2(as_type<half2>(_1281._m0[_11343].w))) * _10926);
                int3 _11498 = min((_10533 + int3(0, 1, 0)), _10959);
                int _11515 = _10789 + ((_11498.x + (_10965 * (_11498.y + (_10969 * _11498.z)))) * 4);
                float3 _11536 = (((((float3(_11498) + float3(0.5)) / _10485) * _10474) * 2.0) - _10474) - _10712;
                float _11546 = dot(_11536 * rsqrt(fast::max(dot(_11536, _11536), 1.0000000133514319600180897396058e-10)), _10812) + 1.0;
                float _11552 = _11011 * _10537.y;
                int _11578 = _11515 + 3;
                float _11564 = ((_11552 * _11016) * ((0.25 * (_11546 * _11546)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_11578])[1u])).y > 0.5);
                int _11608 = _11515 + 1;
                int _11612 = _11515 + 2;
                float2 _11624 = float2(as_type<half2>(_1281._m0[_11515].y));
                float2 _11633 = float2(as_type<half2>(_1281._m0[_11608].x));
                float2 _11642 = float2(as_type<half2>(_1281._m0[_11608].w));
                float2 _11651 = float2(as_type<half2>(_1281._m0[_11612].z));
                float3 _11739 = (((((((float3(float2(as_type<half2>(_1281._m0[_11515].x)), _11624.x) * 0.2820949852466583251953125) + (float3(_11624.y, float2(as_type<half2>(_1281._m0[_11515].z))) * _10892)) + (float3(float2(as_type<half2>(_1281._m0[_11515].w)), _11633.x) * _10895)) + (float3(_11633.y, float2(as_type<half2>(_1281._m0[_11608].y))) * _10898)) + (float3(float2(as_type<half2>(_1281._m0[_11608].z)), _11642.x) * _10906)) + (float3(_11642.y, float2(as_type<half2>(_1281._m0[_11612].x))) * _10912)) + (float3(float2(as_type<half2>(_1281._m0[_11612].y)), _11651.x) * _10920)) + (float3(_11651.y, float2(as_type<half2>(_1281._m0[_11612].w))) * _10926);
                int3 _11767 = min((_10533 + int3(1, 1, 0)), _10959);
                int _11784 = _10789 + ((_11767.x + (_10965 * (_11767.y + (_10969 * _11767.z)))) * 4);
                float3 _11805 = (((((float3(_11767) + float3(0.5)) / _10485) * _10474) * 2.0) - _10474) - _10712;
                float _11815 = dot(_11805 * rsqrt(fast::max(dot(_11805, _11805), 1.0000000133514319600180897396058e-10)), _10812) + 1.0;
                float _11821 = _10537.x * _10537.y;
                int _11847 = _11784 + 3;
                float _11833 = ((_11821 * _11016) * ((0.25 * (_11815 * _11815)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_11847])[1u])).y > 0.5);
                int _11877 = _11784 + 1;
                int _11881 = _11784 + 2;
                float2 _11893 = float2(as_type<half2>(_1281._m0[_11784].y));
                float2 _11902 = float2(as_type<half2>(_1281._m0[_11877].x));
                float2 _11911 = float2(as_type<half2>(_1281._m0[_11877].w));
                float2 _11920 = float2(as_type<half2>(_1281._m0[_11881].z));
                float3 _12008 = (((((((float3(float2(as_type<half2>(_1281._m0[_11784].x)), _11893.x) * 0.2820949852466583251953125) + (float3(_11893.y, float2(as_type<half2>(_1281._m0[_11784].z))) * _10892)) + (float3(float2(as_type<half2>(_1281._m0[_11784].w)), _11902.x) * _10895)) + (float3(_11902.y, float2(as_type<half2>(_1281._m0[_11877].y))) * _10898)) + (float3(float2(as_type<half2>(_1281._m0[_11877].z)), _11911.x) * _10906)) + (float3(_11911.y, float2(as_type<half2>(_1281._m0[_11881].x))) * _10912)) + (float3(float2(as_type<half2>(_1281._m0[_11881].y)), _11920.x) * _10920)) + (float3(_11920.y, float2(as_type<half2>(_1281._m0[_11881].w))) * _10926);
                int3 _12036 = min((_10533 + int3(0, 0, 1)), _10959);
                int _12053 = _10789 + ((_12036.x + (_10965 * (_12036.y + (_10969 * _12036.z)))) * 4);
                float3 _12074 = (((((float3(_12036) + float3(0.5)) / _10485) * _10474) * 2.0) - _10474) - _10712;
                float _12084 = dot(_12074 * rsqrt(fast::max(dot(_12074, _12074), 1.0000000133514319600180897396058e-10)), _10812) + 1.0;
                int _12116 = _12053 + 3;
                float _12102 = ((_11014 * _10537.z) * ((0.25 * (_12084 * _12084)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_12116])[1u])).y > 0.5);
                int _12146 = _12053 + 1;
                int _12150 = _12053 + 2;
                float2 _12162 = float2(as_type<half2>(_1281._m0[_12053].y));
                float2 _12171 = float2(as_type<half2>(_1281._m0[_12146].x));
                float2 _12180 = float2(as_type<half2>(_1281._m0[_12146].w));
                float2 _12189 = float2(as_type<half2>(_1281._m0[_12150].z));
                float3 _12277 = (((((((float3(float2(as_type<half2>(_1281._m0[_12053].x)), _12162.x) * 0.2820949852466583251953125) + (float3(_12162.y, float2(as_type<half2>(_1281._m0[_12053].z))) * _10892)) + (float3(float2(as_type<half2>(_1281._m0[_12053].w)), _12171.x) * _10895)) + (float3(_12171.y, float2(as_type<half2>(_1281._m0[_12146].y))) * _10898)) + (float3(float2(as_type<half2>(_1281._m0[_12146].z)), _12180.x) * _10906)) + (float3(_12180.y, float2(as_type<half2>(_1281._m0[_12150].x))) * _10912)) + (float3(float2(as_type<half2>(_1281._m0[_12150].y)), _12189.x) * _10920)) + (float3(_12189.y, float2(as_type<half2>(_1281._m0[_12150].w))) * _10926);
                float4 _10604 = (((float4((_11201 + (float3(float2(as_type<half2>(_1281._m0[_11040].x)), float2(as_type<half2>(_1281._m0[_11040].y)).x) * _10940)) * _11026, _11026) + float4((_11470 + (float3(float2(as_type<half2>(_1281._m0[_11309].x)), float2(as_type<half2>(_1281._m0[_11309].y)).x) * _10940)) * _11295, _11295)) + float4((_11739 + (float3(float2(as_type<half2>(_1281._m0[_11578].x)), float2(as_type<half2>(_1281._m0[_11578].y)).x) * _10940)) * _11564, _11564)) + float4((_12008 + (float3(float2(as_type<half2>(_1281._m0[_11847].x)), float2(as_type<half2>(_1281._m0[_11847].y)).x) * _10940)) * _11833, _11833)) + float4((_12277 + (float3(float2(as_type<half2>(_1281._m0[_12116].x)), float2(as_type<half2>(_1281._m0[_12116].y)).x) * _10940)) * _12102, _12102);
                int3 _12305 = min((_10533 + int3(1, 0, 1)), _10959);
                int _12322 = _10789 + ((_12305.x + (_10965 * (_12305.y + (_10969 * _12305.z)))) * 4);
                float3 _12343 = (((((float3(_12305) + float3(0.5)) / _10485) * _10474) * 2.0) - _10474) - _10712;
                float _12353 = dot(_12343 * rsqrt(fast::max(dot(_12343, _12343), 1.0000000133514319600180897396058e-10)), _10812) + 1.0;
                int _12385 = _12322 + 3;
                float _12371 = ((_11283 * _10537.z) * ((0.25 * (_12353 * _12353)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_12385])[1u])).y > 0.5);
                int _12415 = _12322 + 1;
                int _12419 = _12322 + 2;
                float2 _12431 = float2(as_type<half2>(_1281._m0[_12322].y));
                float2 _12440 = float2(as_type<half2>(_1281._m0[_12415].x));
                float2 _12449 = float2(as_type<half2>(_1281._m0[_12415].w));
                float2 _12458 = float2(as_type<half2>(_1281._m0[_12419].z));
                float3 _12546 = (((((((float3(float2(as_type<half2>(_1281._m0[_12322].x)), _12431.x) * 0.2820949852466583251953125) + (float3(_12431.y, float2(as_type<half2>(_1281._m0[_12322].z))) * _10892)) + (float3(float2(as_type<half2>(_1281._m0[_12322].w)), _12440.x) * _10895)) + (float3(_12440.y, float2(as_type<half2>(_1281._m0[_12415].y))) * _10898)) + (float3(float2(as_type<half2>(_1281._m0[_12415].z)), _12449.x) * _10906)) + (float3(_12449.y, float2(as_type<half2>(_1281._m0[_12419].x))) * _10912)) + (float3(float2(as_type<half2>(_1281._m0[_12419].y)), _12458.x) * _10920)) + (float3(_12458.y, float2(as_type<half2>(_1281._m0[_12419].w))) * _10926);
                int3 _12574 = min((_10533 + int3(0, 1, 1)), _10959);
                int _12591 = _10789 + ((_12574.x + (_10965 * (_12574.y + (_10969 * _12574.z)))) * 4);
                float3 _12612 = (((((float3(_12574) + float3(0.5)) / _10485) * _10474) * 2.0) - _10474) - _10712;
                float _12622 = dot(_12612 * rsqrt(fast::max(dot(_12612, _12612), 1.0000000133514319600180897396058e-10)), _10812) + 1.0;
                int _12654 = _12591 + 3;
                float _12640 = ((_11552 * _10537.z) * ((0.25 * (_12622 * _12622)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_12654])[1u])).y > 0.5);
                int _12684 = _12591 + 1;
                int _12688 = _12591 + 2;
                float2 _12700 = float2(as_type<half2>(_1281._m0[_12591].y));
                float2 _12709 = float2(as_type<half2>(_1281._m0[_12684].x));
                float2 _12718 = float2(as_type<half2>(_1281._m0[_12684].w));
                float2 _12727 = float2(as_type<half2>(_1281._m0[_12688].z));
                float3 _12815 = (((((((float3(float2(as_type<half2>(_1281._m0[_12591].x)), _12700.x) * 0.2820949852466583251953125) + (float3(_12700.y, float2(as_type<half2>(_1281._m0[_12591].z))) * _10892)) + (float3(float2(as_type<half2>(_1281._m0[_12591].w)), _12709.x) * _10895)) + (float3(_12709.y, float2(as_type<half2>(_1281._m0[_12684].y))) * _10898)) + (float3(float2(as_type<half2>(_1281._m0[_12684].z)), _12718.x) * _10906)) + (float3(_12718.y, float2(as_type<half2>(_1281._m0[_12688].x))) * _10912)) + (float3(float2(as_type<half2>(_1281._m0[_12688].y)), _12727.x) * _10920)) + (float3(_12727.y, float2(as_type<half2>(_1281._m0[_12688].w))) * _10926);
                int3 _12843 = min((_10533 + int3(1)), _10959);
                int _12860 = _10789 + ((_12843.x + (_10965 * (_12843.y + (_10969 * _12843.z)))) * 4);
                float3 _12881 = (((((float3(_12843) + float3(0.5)) / _10485) * _10474) * 2.0) - _10474) - _10712;
                float _12891 = dot(_12881 * rsqrt(fast::max(dot(_12881, _12881), 1.0000000133514319600180897396058e-10)), _10812) + 1.0;
                int _12923 = _12860 + 3;
                float _12909 = ((_11821 * _10537.z) * ((0.25 * (_12891 * _12891)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_12923])[1u])).y > 0.5);
                int _12953 = _12860 + 1;
                int _12957 = _12860 + 2;
                float2 _12969 = float2(as_type<half2>(_1281._m0[_12860].y));
                float2 _12978 = float2(as_type<half2>(_1281._m0[_12953].x));
                float2 _12987 = float2(as_type<half2>(_1281._m0[_12953].w));
                float2 _12996 = float2(as_type<half2>(_1281._m0[_12957].z));
                float3 _13084 = (((((((float3(float2(as_type<half2>(_1281._m0[_12860].x)), _12969.x) * 0.2820949852466583251953125) + (float3(_12969.y, float2(as_type<half2>(_1281._m0[_12860].z))) * _10892)) + (float3(float2(as_type<half2>(_1281._m0[_12860].w)), _12978.x) * _10895)) + (float3(_12978.y, float2(as_type<half2>(_1281._m0[_12953].y))) * _10898)) + (float3(float2(as_type<half2>(_1281._m0[_12953].z)), _12987.x) * _10906)) + (float3(_12987.y, float2(as_type<half2>(_1281._m0[_12957].x))) * _10912)) + (float3(float2(as_type<half2>(_1281._m0[_12957].y)), _12996.x) * _10920)) + (float3(_12996.y, float2(as_type<half2>(_1281._m0[_12957].w))) * _10926);
                float4 _10643 = ((_10604 + float4((_12546 + (float3(float2(as_type<half2>(_1281._m0[_12385].x)), float2(as_type<half2>(_1281._m0[_12385].y)).x) * _10940)) * _12371, _12371)) + float4((_12815 + (float3(float2(as_type<half2>(_1281._m0[_12654].x)), float2(as_type<half2>(_1281._m0[_12654].y)).x) * _10940)) * _12640, _12640)) + float4((_13084 + (float3(float2(as_type<half2>(_1281._m0[_12923].x)), float2(as_type<half2>(_1281._m0[_12923].y)).x) * _10940)) * _12909, _12909);
                float _10647 = _10643.w;
                float3 _17496;
                if (_10647 > 9.9999997473787516355514526367188e-06)
                {
                    _17496 = mix(_16764, (fast::max(_10643.xyz, float3(0.0)) / float3(_10647)) * _10783.z, float3(_17219));
                }
                else
                {
                    _17496 = _16764;
                }
                _17495 = _17496;
            }
            _16875 = _16764;
        }
        else
        {
            _16875 = _16748;
        }
        float3 _16897;
        if (_283._m34.x > 0.5)
        {
            float3 _4129 = reflect(-_3644, _16708);
            int _13132 = int(_283._m34.x);
            float _16787;
            float3 _16853;
            _16853 = float3(0.0);
            _16787 = 0.0;
            float _17506;
            float3 _17507;
            for (int _16786 = 0; _16786 < _13132; _16853 = _17507, _16787 = _17506, _16786++)
            {
                if (_16787 > 0.999000012874603271484375)
                {
                    break;
                }
                int _13144 = _16786 * 8;
                float4 _13259 = as_type<float4>(_1281._m0[_13144]);
                float4 _13265 = as_type<float4>(_1281._m0[_13144 + 1]);
                float4 _13271 = as_type<float4>(_1281._m0[_13144 + 2]);
                float3 _13233 = _13259.xyz;
                float3 _13240 = _13265.xyz;
                float3 _13247 = _13271.xyz;
                float3 _13253 = float3(dot(_13233, in.m_3037) + _13259.w, dot(_13240, in.m_3037) + _13265.w, dot(_13247, in.m_3037) + _13271.w);
                float4 _13277 = as_type<float4>(_1281._m0[_13144 + 3]);
                float _13155 = _13277.w;
                float _16788;
                do
                {
                    float3 _13289 = _13277.xyz - abs(_13253);
                    float _13297 = fast::min(_13289.x, fast::min(_13289.y, _13289.z));
                    if (_13297 <= 0.0)
                    {
                        _16788 = 0.0;
                        break;
                    }
                    if (_13155 <= 0.0)
                    {
                        _16788 = 1.0;
                        break;
                    }
                    float _13309 = fast::min(_13297 / _13155, 1.0);
                    _16788 = (_13309 * _13309) * (3.0 - (2.0 * _13309));
                    break;
                } while(false);
                if (_16788 <= 0.0)
                {
                    _17507 = _16853;
                    _17506 = _16787;
                    continue;
                }
                float4 _13324 = as_type<float4>(_1281._m0[_13144 + 4]);
                float4 _13330 = as_type<float4>(_1281._m0[_13144 + 5]);
                float3 _13353 = float3(dot(_13233, _4129), dot(_13240, _4129), dot(_13247, _4129));
                float3 _16790;
                if (_13324.w > 0.5)
                {
                    float3 _13177 = _13324.xyz;
                    float3 _13383 = -_13177;
                    float3 _13385 = fast::clamp(_13253, _13383, _13177);
                    float3 _13395 = step(float3(9.9999999747524270787835121154785e-07), abs(_13353));
                    float3 _13405 = mix(float3(1000000015047466219876688855040.0), (mix(_13383, _13177, step(float3(0.0), _13353)) - _13385) / mix(float3(9.9999999747524270787835121154785e-07), _13353, _13395), _13395);
                    float3 _13421 = (_13385 + (_13353 * fast::max(fast::min(_13405.x, fast::min(_13405.y, _13405.z)), 0.0))) - _13330.xyz;
                    float3 _16789;
                    if (dot(_13421, _13421) > 9.9999999600419720025001879548654e-13)
                    {
                        _16789 = fast::normalize(_13421);
                    }
                    else
                    {
                        _16789 = _13353;
                    }
                    _16790 = _16789;
                }
                else
                {
                    _16790 = _13353;
                }
                int _13438 = int(((device uint*)&_1281._m0[_13144 + 6])[0u]);
                float2 _13488 = float2((precise::atan2(_16790.x, -_16790.z) * 0.15915493667125701904296875) + 0.5, acos(fast::clamp(_16790.y, -1.0, 1.0)) * 0.3183098733425140380859375);
                float _13454 = _16675 * 5.0;
                int _13457 = min(int(_13454), 4);
                int _13528 = _13438 + _1353[_13457].x;
                float2 _13535 = (_13488 * float2(_1353[_13457].yz)) - float2(0.5);
                float2 _13537 = floor(_13535);
                float2 _13540 = _13535 - _13537;
                int _13543 = int(_13537.x);
                int _13546 = int(_13537.y);
                int _16791;
                if (_13543 < 0)
                {
                    _16791 = _13543 + _1353[_13457].y;
                }
                else
                {
                    _16791 = _13543;
                }
                int _16792;
                if (_16791 >= _1353[_13457].y)
                {
                    _16792 = _16791 - _1353[_13457].y;
                }
                else
                {
                    _16792 = _16791;
                }
                int _13566 = _16792 + 1;
                int _17651 = (_13566 == _1353[_13457].y) ? 0 : _13566;
                int _13634 = _13528 + (max(_13546, 0) * _1353[_13457].y);
                int _13636 = _13634 + _16792;
                int _13638 = _13636 >> 1;
                uint2 _16798;
                if ((_13636 & 1) == 0)
                {
                    _16798 = _1281._m0[_13638].xy;
                }
                else
                {
                    _16798 = _1281._m0[_13638].zw;
                }
                int _13674 = _13634 + _17651;
                int _13676 = _13674 >> 1;
                uint2 _16800;
                if ((_13674 & 1) == 0)
                {
                    _16800 = _1281._m0[_13676].xy;
                }
                else
                {
                    _16800 = _1281._m0[_13676].zw;
                }
                int _13710 = _13528 + (min((_13546 + 1), (_1353[_13457].z - 1)) * _1353[_13457].y);
                int _13712 = _13710 + _16792;
                int _13714 = _13712 >> 1;
                uint2 _16803;
                if ((_13712 & 1) == 0)
                {
                    _16803 = _1281._m0[_13714].xy;
                }
                else
                {
                    _16803 = _1281._m0[_13714].zw;
                }
                int _13750 = _13710 + _17651;
                int _13752 = _13750 >> 1;
                uint2 _16804;
                if ((_13750 & 1) == 0)
                {
                    _16804 = _1281._m0[_13752].xy;
                }
                else
                {
                    _16804 = _1281._m0[_13752].zw;
                }
                float3 _13612 = float3(_13540.x);
                int _13463 = _13457 + 1;
                int _13815 = _13438 + _1353[_13463].x;
                float2 _13822 = (_13488 * float2(_1353[_13463].yz)) - float2(0.5);
                float2 _13824 = floor(_13822);
                float2 _13827 = _13822 - _13824;
                int _13830 = int(_13824.x);
                int _13833 = int(_13824.y);
                int _16805;
                if (_13830 < 0)
                {
                    _16805 = _13830 + _1353[_13463].y;
                }
                else
                {
                    _16805 = _13830;
                }
                int _16806;
                if (_16805 >= _1353[_13463].y)
                {
                    _16806 = _16805 - _1353[_13463].y;
                }
                else
                {
                    _16806 = _16805;
                }
                int _13853 = _16806 + 1;
                int _17652 = (_13853 == _1353[_13463].y) ? 0 : _13853;
                int _13921 = _13815 + (max(_13833, 0) * _1353[_13463].y);
                int _13923 = _13921 + _16806;
                int _13925 = _13923 >> 1;
                uint2 _16812;
                if ((_13923 & 1) == 0)
                {
                    _16812 = _1281._m0[_13925].xy;
                }
                else
                {
                    _16812 = _1281._m0[_13925].zw;
                }
                int _13961 = _13921 + _17652;
                int _13963 = _13961 >> 1;
                uint2 _16814;
                if ((_13961 & 1) == 0)
                {
                    _16814 = _1281._m0[_13963].xy;
                }
                else
                {
                    _16814 = _1281._m0[_13963].zw;
                }
                int _13997 = _13815 + (min((_13833 + 1), (_1353[_13463].z - 1)) * _1353[_13463].y);
                int _13999 = _13997 + _16806;
                int _14001 = _13999 >> 1;
                uint2 _16817;
                if ((_13999 & 1) == 0)
                {
                    _16817 = _1281._m0[_14001].xy;
                }
                else
                {
                    _16817 = _1281._m0[_14001].zw;
                }
                int _14037 = _13997 + _17652;
                int _14039 = _14037 >> 1;
                uint2 _16818;
                if ((_14037 & 1) == 0)
                {
                    _16818 = _1281._m0[_14039].xy;
                }
                else
                {
                    _16818 = _1281._m0[_14039].zw;
                }
                float3 _13899 = float3(_13827.x);
                float3 _13193 = mix(mix(mix(float3(float2(as_type<half2>(_16798.x)), float2(as_type<half2>(_16798.y)).x), float3(float2(as_type<half2>(_16800.x)), float2(as_type<half2>(_16800.y)).x), _13612), mix(float3(float2(as_type<half2>(_16803.x)), float2(as_type<half2>(_16803.y)).x), float3(float2(as_type<half2>(_16804.x)), float2(as_type<half2>(_16804.y)).x), _13612), float3(_13540.y)), mix(mix(float3(float2(as_type<half2>(_16812.x)), float2(as_type<half2>(_16812.y)).x), float3(float2(as_type<half2>(_16814.x)), float2(as_type<half2>(_16814.y)).x), _13899), mix(float3(float2(as_type<half2>(_16817.x)), float2(as_type<half2>(_16817.y)).x), float3(float2(as_type<half2>(_16818.x)), float2(as_type<half2>(_16818.y)).x), _13899), float3(_13827.y)), float3(_13454 - float(_13457))) * _13330.w;
                float _13197 = _16788 * (1.0 - _16787);
                _17507 = _16853 + (_13193 * _13197);
                _17506 = _16787 + _13197;
            }
            _16897 = _16853 + (_16775 * (1.0 - _16787));
        }
        else
        {
            _16897 = _16775;
        }
        bool _4147;
        if (_3690)
        {
            _4147 = _283._m33.z > 0.5;
        }
        else
        {
            _4147 = _3690;
        }
        float3 _16987;
        if (_4147)
        {
            float3 _16947;
            do
            {
                float _14124 = ((_283._m32.x * (1.0 - smoothstep(_283._m33.x * 0.5, _283._m33.x, abs(dot(_283._m31.xyz, in.m_3037) - _283._m31.w)))) * smoothstep(0.5, 0.89999997615814208984375, dot(_3655, _283._m31.xyz))) * (1.0 - smoothstep(_283._m32.y * 0.5, _283._m32.y, _16675));
                if (_14124 <= 0.0)
                {
                    _16947 = _16897;
                    break;
                }
                float4 _14149 = _283._m30 * float4(in.m_3037 + ((_16685 - (_283._m31.xyz * dot(_16685, _283._m31.xyz))) * _283._m32.w), 1.0);
                float2 _14162 = ((float2(_14149.x, -_14149.y) / float2(_14149.w)) * 0.5) + float2(0.5);
                float _14166 = _283._m32.z * _16675;
                float3 _16945;
                float _16946;
                _16946 = 0.0;
                _16945 = float3(0.0);
                for (int _16944 = 0; _16944 < 12; )
                {
                    float _14173 = float(_16944);
                    float _14181 = _14173 * 2.3999631404876708984375;
                    float2 _14193 = _14162 + (float2(cos(_14181) * _283._m33.y, sin(_14181)) * (sqrt((_14173 + 0.5) * 0.083333335816860198974609375) * _14166));
                    float2 _14198 = fast::min(_14193, float2(1.0) - _14193);
                    float _14204 = smoothstep(0.0, 0.039999999105930328369140625, fast::min(_14198.x, _14198.y));
                    float4 _14212 = _3352.sample(_2533, fast::clamp(_14193, float2(0.0), float2(1.0)), level(0.0));
                    float3 _14214 = _14212.xyz;
                    _16946 += (_14212.w * _14204);
                    _16945 += ((_14214 / (float3(1.0) - fast::min(_14214, float3(0.99500000476837158203125)))) * _14204);
                    _16944++;
                    continue;
                }
                _16947 = mix(_16897, (_16945 * float3(0.083333335816860198974609375)) + (_16897 * (1.0 - (_16946 * 0.083333335816860198974609375))), float3(_14124));
                break;
            } while(false);
            _16987 = _16947;
        }
        else
        {
            _16987 = _16897;
        }
        float3 _4167 = (_3927 * _16952.x) + float3(_16952.y);
        float3 _4183 = _17041 + (((((float3(1.0) - _4167) * _3921) * _16875) + (_4167 * _16987)) * _17004);
        float3 _17248;
        if (_283._m13.w > 0.5)
        {
            float2 _14278 = fast::clamp(floor(gl_FragCoord.xy * _283._m12.xy), float2(0.0), _283._m13.xy - float2(1.0));
            uint _14306 = uint((((fast::clamp(floor((log2(fast::max(dot(_283._m11.xyz, in.m_3037) + _283._m11.w, 9.9999999747524270787835121154785e-07)) * _283._m12.z) + _283._m12.w), 0.0, _283._m13.z - 1.0) * _283._m13.y) + _14278.y) * _283._m13.x) + _14278.x);
            uint _14308 = _14306 >> uint(2);
            uint _14310 = _14306 & 3u;
            uint _14314 = _3167._m0[_14308][_14310] & 65535u;
            uint _14316 = _3167._m0[_14308][_14310] >> uint(16);
            float3 _17185;
            _17185 = _4183;
            float3 _4283;
            spvUnsafeArray<float2, 3> _14724;
            spvUnsafeArray<float2, 3> _14725;
            spvUnsafeArray<float2, 3> _14937;
            spvUnsafeArray<float2, 3> _14938;
            for (uint _17065 = _14314; _17065 < (_14314 + _14316); _17185 = _4283, _17065++)
            {
                uint _14322 = _17065 / 3u;
                uint _14335 = (_3188._m0[_14322 >> uint(2)][_14322 & 3u] >> ((_17065 - (_14322 * 3u)) * 10u)) & 1023u;
                float3 _14352 = _3030._m0[_14335].xyz - in.m_3037;
                float _14355 = dot(_14352, _14352);
                float _14359 = _14355 * _3030._m0[_14335].w;
                float _14364 = fast::clamp(1.0 - (_14359 * _14359), 0.0, 1.0);
                float3 _14369 = _14352 * rsqrt(fast::max(_14355, 9.9999999392252902907785028219223e-09));
                float _14387 = fast::clamp((dot(-_14369, _3073._m0[_14335].xyz) * _3065._m0[_14335].w) + _3073._m0[_14335].w, 0.0, 1.0);
                float3 _14400 = _3065._m0[_14335].xyz * ((((_14364 * _14364) * _14387) * _14387) / fast::max(_14355, 9.9999997473787516355514526367188e-05));
                float3 _17183;
                if (_3660)
                {
                    float _17092;
                    do
                    {
                        uint _14436 = uint(_283._m21.z);
                        if (_14335 < _14436)
                        {
                            float _14458 = _283._m26[_14335].z * fast::max((_283._m15[_14335] * float4(in.m_3037, 1.0)).w, 0.0);
                            float4 _14482 = _283._m15[_14335] * float4((in.m_3037 + (_3655 * (_14458 * _283._m25.x))) + (_14369 * (_14458 * _283._m25.y)), 1.0);
                            float _14484 = _14482.w;
                            if (_14484 <= 0.0)
                            {
                                _17092 = 1.0;
                                break;
                            }
                            float3 _14493 = _14482.xyz / float3(_14484);
                            float _14495 = _14493.x;
                            bool _14496 = _14495 < 0.0;
                            bool _14503;
                            if (!_14496)
                            {
                                _14503 = _14495 > 1.0;
                            }
                            else
                            {
                                _14503 = _14496;
                            }
                            bool _14510;
                            if (!_14503)
                            {
                                _14510 = _14493.y < 0.0;
                            }
                            else
                            {
                                _14510 = _14503;
                            }
                            bool _14517;
                            if (!_14510)
                            {
                                _14517 = _14493.y > 1.0;
                            }
                            else
                            {
                                _14517 = _14510;
                            }
                            bool _14524;
                            if (!_14517)
                            {
                                _14524 = _14493.z > 1.0;
                            }
                            else
                            {
                                _14524 = _14517;
                            }
                            if (_14524)
                            {
                                _17092 = 1.0;
                                break;
                            }
                            float _14530 = _14493.z;
                            float2 _14696 = _283._m22.xy * 0.5;
                            float2 _14701 = _283._m26[_14335].xy + (_14493.xy * _283._m23.zw);
                            float4 _14714 = float4(_283._m26[_14335].xy + _14696, (_283._m26[_14335].xy + _283._m23.zw) - _14696);
                            float _17091;
                            do
                            {
                                int _14740 = int(_283._m22.z);
                                if (_14740 <= 0)
                                {
                                    float2 _14750 = fast::clamp(_14701, _14714.xy, _14714.zw);
                                    _17091 = spvDepthCast(_303).sample_compare(_303Smplr, float3(_14750, _14530).xy, _14530);
                                    break;
                                }
                                float2 _14763 = (_14701 / _283._m22.xy) + float2(0.5);
                                float2 _14764 = floor(_14763);
                                float2 _14769 = _14763 - _14764;
                                float2 _14772 = _14764 - float2(0.5);
                                bool _14776 = _14740 == 1;
                                if (_14776)
                                {
                                    float2 _14779 = _14769 * 2.0;
                                    _14724[0] = float2(3.0) - _14779;
                                    _14724[1] = float2(1.0) + _14779;
                                    _14725[0] = ((float2(2.0) - _14769) / _14724[0]) - float2(1.0);
                                    _14725[1] = (_14769 / _14724[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _14806 = _14769 * 3.0;
                                    _14724[0] = float2(4.0) - _14806;
                                    _14724[1] = float2(7.0);
                                    _14724[2] = float2(1.0) + _14806;
                                    _14725[0] = ((float2(3.0) - (_14769 * 2.0)) / _14724[0]) - float2(2.0);
                                    _14725[1] = (float2(3.0) + _14769) / _14724[1];
                                    _14725[2] = (_14769 / _14724[2]) + float2(2.0);
                                }
                                int _17654 = _14776 ? 2 : 3;
                                int _17081;
                                float _17084;
                                _17084 = 0.0;
                                _17081 = 0;
                                float _17090;
                                for (; _17081 < _17654; _17084 = _17090, _17081++)
                                {
                                    _17090 = _17084;
                                    for (int _17087 = 0; _17087 < _17654; )
                                    {
                                        _17090 += ((_14724[_17087].x * _14724[_17081].y) * spvDepthCast(_303).sample_compare(_303Smplr, float3(fast::clamp(_283._m22.xy * (_14772 + float2(_14725[_17087].x, _14725[_17081].y)), _14714.xy, _14714.zw), _14530).xy, _14530));
                                        _17087++;
                                        continue;
                                    }
                                }
                                _17091 = _17084 * (_14776 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _17092 = _17091;
                            break;
                        }
                        uint _14540 = _14335 - _14436;
                        if (_14540 >= uint(_283._m21.w))
                        {
                            _17092 = 1.0;
                            break;
                        }
                        float _14561 = _283._m27[_14540].w * length(in.m_3037 - _283._m27[_14540].xyz);
                        float3 _14579 = ((in.m_3037 + (_3655 * (_14561 * _283._m25.x))) + (_14369 * (_14561 * _283._m25.y))) - _283._m27[_14540].xyz;
                        float3 _14581 = abs(_14579);
                        float _14583 = _14581.x;
                        float _14585 = _14581.y;
                        bool _14586 = _14583 >= _14585;
                        bool _14594;
                        if (_14586)
                        {
                            _14594 = _14583 >= _14581.z;
                        }
                        else
                        {
                            _14594 = _14586;
                        }
                        float _17066;
                        int _17068;
                        if (_14594)
                        {
                            _17068 = (_14579.x > 0.0) ? 0 : 1;
                            _17066 = _14583;
                        }
                        else
                        {
                            float _14606 = _14581.z;
                            bool _14607 = _14585 >= _14606;
                            int _17069;
                            if (_14607)
                            {
                                _17069 = (_14579.y > 0.0) ? 2 : 3;
                            }
                            else
                            {
                                _17069 = (_14579.z > 0.0) ? 4 : 5;
                            }
                            _17068 = _17069;
                            _17066 = _14607 ? _14585 : _14606;
                        }
                        if (_17066 <= 0.0)
                        {
                            _17092 = 1.0;
                            break;
                        }
                        float2 _14644 = float2(dot(_14579, _961[_17068]), dot(_14579, _970[_17068])) / float2(_17066 * _283._m24.z);
                        float _14651 = _283._m28[_14540].z + (_283._m28[_14540].w / _17066);
                        if (_14651 > 1.0)
                        {
                            _17092 = 1.0;
                            break;
                        }
                        float2 _14669 = _283._m28[_14540].xy + (float2(float(spvSMod(_17068, 3)), float(_17068 / 3)) * _283._m24.xy);
                        float2 _14909 = _283._m22.xy * 0.5;
                        float2 _14914 = _14669 + (float2(0.5 + (0.5 * _14644.x), 0.5 - (0.5 * _14644.y)) * _283._m24.xy);
                        float4 _14927 = float4(_14669 + _14909, (_14669 + _283._m24.xy) - _14909);
                        float _17080;
                        do
                        {
                            int _14953 = int(_283._m22.z);
                            if (_14953 <= 0)
                            {
                                _17080 = spvDepthCast(_303).sample_compare(_303Smplr, float3(fast::clamp(_14914, _14927.xy, _14927.zw), _14651).xy, _14651);
                                break;
                            }
                            float2 _14976 = (_14914 / _283._m22.xy) + float2(0.5);
                            float2 _14977 = floor(_14976);
                            float2 _14982 = _14976 - _14977;
                            float2 _14985 = _14977 - float2(0.5);
                            bool _14989 = _14953 == 1;
                            if (_14989)
                            {
                                float2 _14992 = _14982 * 2.0;
                                _14937[0] = float2(3.0) - _14992;
                                _14937[1] = float2(1.0) + _14992;
                                _14938[0] = ((float2(2.0) - _14982) / _14937[0]) - float2(1.0);
                                _14938[1] = (_14982 / _14937[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _15019 = _14982 * 3.0;
                                _14937[0] = float2(4.0) - _15019;
                                _14937[1] = float2(7.0);
                                _14937[2] = float2(1.0) + _15019;
                                _14938[0] = ((float2(3.0) - (_14982 * 2.0)) / _14937[0]) - float2(2.0);
                                _14938[1] = (float2(3.0) + _14982) / _14937[1];
                                _14938[2] = (_14982 / _14937[2]) + float2(2.0);
                            }
                            int _17657 = _14989 ? 2 : 3;
                            int _17070;
                            float _17073;
                            _17073 = 0.0;
                            _17070 = 0;
                            float _17079;
                            for (; _17070 < _17657; _17073 = _17079, _17070++)
                            {
                                _17079 = _17073;
                                for (int _17076 = 0; _17076 < _17657; )
                                {
                                    _17079 += ((_14937[_17076].x * _14937[_17070].y) * spvDepthCast(_303).sample_compare(_303Smplr, float3(fast::clamp(_283._m22.xy * (_14985 + float2(_14938[_17076].x, _14938[_17070].y)), _14927.xy, _14927.zw), _14651).xy, _14651));
                                    _17076++;
                                    continue;
                                }
                            }
                            _17080 = _17073 * (_14989 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _17092 = _17080;
                        break;
                    } while(false);
                    _17183 = _14400 * _17092;
                }
                else
                {
                    _17183 = _14400;
                }
                float3 _4235 = fast::normalize(_14369 + _3644);
                float _4240 = fast::clamp(dot(_16685, _14369), 0.0, 1.0);
                float _4245 = fast::clamp(dot(_16685, _4235), 0.0, 1.0);
                float3 _15124 = _3927 + (_9707 * powr(1.0 - fast::clamp(dot(_3644, _4235), 0.0, 1.0), 5.0));
                float _15138 = ((_4245 * _4245) * _9722) + 1.0;
                _4283 = _17185 + (((((float3(1.0) - _15124) * _3921) + ((_15124 * ((_9717 / ((3.1415927410125732421875 * _15138) * _15138)) * (0.5 / fast::max((_4240 * _9748) + (_16713 * sqrt(((_4240 * _4240) * _9744) + _9717)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875)) * _4240) * _17183);
            }
            _17248 = _17185;
        }
        else
        {
            _17248 = _4183;
        }
        _17315 = _16875;
        _17245 = _17248;
    }
    float4 _4300 = _4295.sample(_2533, _3419);
    float _4318 = -length(_3643);
    float _17370;
    if (_283._m9.w != 0.0)
    {
        float _4342 = _283._m9.w * (in.m_3037 - _283._m6.xyz).y;
        float _17313;
        if (abs(_4342) < 9.9999997473787516355514526367188e-05)
        {
            _17313 = 1.0 - (0.5 * _4342);
        }
        else
        {
            _17313 = (1.0 - exp(fast::min(-_4342, 60.0))) / _4342;
        }
        _17370 = 1.0 - exp((_4318 * (_283._m7.w * exp(fast::min((-_283._m9.w) * (_283._m6.y - _283._m6.w), 30.0)))) * _17313);
    }
    else
    {
        _17370 = 1.0 - exp(_4318 * _283._m7.w);
    }
    bool _4388 = _283._m34.z > 0.5;
    float3 _17366;
    if (_4388)
    {
        _17366 = _17315 * _17004;
    }
    else
    {
        _17366 = mix(_17245, _16679, float3(_2876._m1.y)) + ((_2876._m5.xyz * _4300.xyz) * (float3(1.0) + in.m_3657.yzw));
    }
    float3 _4401 = mix(_17366, _283._m7.xyz, float3(_4388 ? 0.0 : _17370));
    float3 _17371;
    if (_283._m33.w > 0.5)
    {
        _17371 = _4401 / (float3(1.0) + _4401);
    }
    else
    {
        _17371 = _4401;
    }
    out.m_4413 = float4(_17371, (in.m_3428.w * _2876._m0.w) * _3426.w);
    float2 _17372;
    do
    {
        if (in.m_4423.w <= 0.0)
        {
            _17372 = float2(0.0);
            break;
        }
        _17372 = ((in.m_4423.xy / float2(in.m_4423.w)) - (in.m_4422.xy / float2(in.m_4422.w))) * float2(0.5, -0.5);
        break;
    } while(false);
    _4421 = _17372;
    return out;
}

