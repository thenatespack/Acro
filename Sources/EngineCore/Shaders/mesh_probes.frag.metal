// Generated from mesh_probes.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 1e6ed52dc75687a3
// glsl-fnv1a64: dc6b24bfa5314702

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
    float4 m_4542 [[color(0)]];
    float2 m_4550 [[color(1)]];
};

struct fragment_main_in
{
    float3 m_3037 [[user(locn0)]];
    float3 m_2946 [[user(locn1)]];
    float2 m_3405 [[user(locn2)]];
    float4 m_3428 [[user(locn3)]];
    float3 m_2980 [[user(locn4)]];
    float4 m_3657 [[user(locn5)]];
    float4 m_4551 [[user(locn6)]];
    float4 m_4552 [[user(locn7)]];
    float4 m_2952 [[user(locn8)]];
};

fragment fragment_main_out fragment_main(fragment_main_in in [[stage_in]], constant _2874& _2876 [[buffer(2)]], constant _3028& _3030 [[buffer(3)]], constant _3063& _3065 [[buffer(4)]], constant _3071& _3073 [[buffer(5)]], constant _3165& _3167 [[buffer(6)]], constant _3186& _3188 [[buffer(7)]], constant _281& _283 [[buffer(15)]], const device _1279& _1281 [[buffer(21)]], texture2d<float> _303 [[texture(0)]], texture2d<float> _3421 [[texture(1)]], texture2d<float> _3898 [[texture(2)]], texture2d<float> _3534 [[texture(3)]], texture2d<float> _3352 [[texture(4)]], texture2d<float> _4395 [[texture(5)]], texture2d<float> _2531 [[texture(6)]], texture2d<float> _2632 [[texture(7)]], sampler _303Smplr [[sampler(0)]], sampler _2533 [[sampler(1)]], sampler _2634 [[sampler(7)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])
{
    fragment_main_out out = {};
    float2 _3419 = float2(dot(_2876._m2.xy, in.m_3405) + _2876._m2.z, dot(_2876._m3.xy, in.m_3405) + _2876._m3.z);
    float4 _3426 = _3421.sample(_2533, _3419);
    float3 _3436 = _3426.xyz;
    float3 _3437 = (in.m_3428.xyz * _2876._m0.xyz) * _3436;
    float3 _20823;
    if (_2876._m1.x > 0.5)
    {
        float2 _3458 = floor(in.m_3037.xz * float2(0.5));
        _20823 = _3437 * ((mod(abs(_3458.x + _3458.y), 2.0) < 0.5) ? 1.0 : 0.75);
    }
    else
    {
        _20823 = _3437;
    }
    float3 _20920;
    float _20951;
    float2 _20984;
    if (_2876._m3.w > 0.5)
    {
        float3 _4658;
        float2 _4665;
        float _20821;
        do
        {
            float3 _4629 = float4(_2876._m2.w, _2876._m3.w, 0.0, 0.0).xyy;
            float3 _4632 = floor(_4629 * float3(1.52587890625e-05));
            float3 _4637 = _4629 - (_4632 * 65536.0);
            float3 _4640 = floor(_4637 * float3(0.00390625));
            float3 _4648 = _4637 - (_4640 * 256.0);
            _4658 = (float3(_4648.x, _4640.x, _4632.x) * float3(0.0039215688593685626983642578125)) * 2.0;
            _4665 = float2(_4648.y, _4640.y) * float2(0.0039215688593685626983642578125);
            float _4668 = _4632.y - 128.0;
            float _4674 = floor(_4668 * 0.03125) * 0.3333333432674407958984375;
            float3 _4680 = fast::normalize(in.m_2946);
            float _4684 = dot(_4680, in.m_2952.xyz);
            float _4696 = (_4684 / fast::max(length(in.m_2952.xyz - (_4680 * _4684)), 9.9999999747524270787835121154785e-07)) * 25.5;
            if (((-24.0) + _4696) < (-2.0))
            {
                _20821 = 0.0;
                break;
            }
            float3 _4704 = in.m_2980 * (4.0 * exp2(mod(_4668, 32.0) * 0.3333333432674407958984375));
            float3 _4748 = floor(_4704);
            float3 _4751 = _4704 - _4748;
            float3 _4759 = (_4751 * _4751) * (float3(3.0) - (_4751 * 2.0));
            uint3 _4826 = uint3(int3(_4748));
            uint _4839 = (((_4826.x * 1597334677u) ^ (_4826.y * 3812015801u)) ^ (_4826.z * 2798796415u)) * 1597334677u;
            uint3 _4854 = uint3(int3(_4748 + float3(1.0, 0.0, 0.0)));
            uint _4867 = (((_4854.x * 1597334677u) ^ (_4854.y * 3812015801u)) ^ (_4854.z * 2798796415u)) * 1597334677u;
            float _4768 = _4759.x;
            uint3 _4882 = uint3(int3(_4748 + float3(0.0, 1.0, 0.0)));
            uint _4895 = (((_4882.x * 1597334677u) ^ (_4882.y * 3812015801u)) ^ (_4882.z * 2798796415u)) * 1597334677u;
            uint3 _4910 = uint3(int3(_4748 + float3(1.0, 1.0, 0.0)));
            uint _4923 = (((_4910.x * 1597334677u) ^ (_4910.y * 3812015801u)) ^ (_4910.z * 2798796415u)) * 1597334677u;
            float _4784 = _4759.y;
            uint3 _4938 = uint3(int3(_4748 + float3(0.0, 0.0, 1.0)));
            uint _4951 = (((_4938.x * 1597334677u) ^ (_4938.y * 3812015801u)) ^ (_4938.z * 2798796415u)) * 1597334677u;
            uint3 _4966 = uint3(int3(_4748 + float3(1.0, 0.0, 1.0)));
            uint _4979 = (((_4966.x * 1597334677u) ^ (_4966.y * 3812015801u)) ^ (_4966.z * 2798796415u)) * 1597334677u;
            uint3 _4994 = uint3(int3(_4748 + float3(0.0, 1.0, 1.0)));
            uint _5007 = (((_4994.x * 1597334677u) ^ (_4994.y * 3812015801u)) ^ (_4994.z * 2798796415u)) * 1597334677u;
            uint3 _5022 = uint3(int3(_4748 + float3(1.0)));
            uint _5035 = (((_5022.x * 1597334677u) ^ (_5022.y * 3812015801u)) ^ (_5022.z * 2798796415u)) * 1597334677u;
            float3 _4710 = (_4704 * 2.7000000476837158203125) + float3(17.299999237060546875, 5.099999904632568359375, 9.69999980926513671875);
            float3 _5061 = floor(_4710);
            float3 _5064 = _4710 - _5061;
            float3 _5072 = (_5064 * _5064) * (float3(3.0) - (_5064 * 2.0));
            uint3 _5139 = uint3(int3(_5061));
            uint _5152 = (((_5139.x * 1597334677u) ^ (_5139.y * 3812015801u)) ^ (_5139.z * 2798796415u)) * 1597334677u;
            uint3 _5167 = uint3(int3(_5061 + float3(1.0, 0.0, 0.0)));
            uint _5180 = (((_5167.x * 1597334677u) ^ (_5167.y * 3812015801u)) ^ (_5167.z * 2798796415u)) * 1597334677u;
            float _5081 = _5072.x;
            uint3 _5195 = uint3(int3(_5061 + float3(0.0, 1.0, 0.0)));
            uint _5208 = (((_5195.x * 1597334677u) ^ (_5195.y * 3812015801u)) ^ (_5195.z * 2798796415u)) * 1597334677u;
            uint3 _5223 = uint3(int3(_5061 + float3(1.0, 1.0, 0.0)));
            uint _5236 = (((_5223.x * 1597334677u) ^ (_5223.y * 3812015801u)) ^ (_5223.z * 2798796415u)) * 1597334677u;
            float _5097 = _5072.y;
            uint3 _5251 = uint3(int3(_5061 + float3(0.0, 0.0, 1.0)));
            uint _5264 = (((_5251.x * 1597334677u) ^ (_5251.y * 3812015801u)) ^ (_5251.z * 2798796415u)) * 1597334677u;
            uint3 _5279 = uint3(int3(_5061 + float3(1.0, 0.0, 1.0)));
            uint _5292 = (((_5279.x * 1597334677u) ^ (_5279.y * 3812015801u)) ^ (_5279.z * 2798796415u)) * 1597334677u;
            uint3 _5307 = uint3(int3(_5061 + float3(0.0, 1.0, 1.0)));
            uint _5320 = (((_5307.x * 1597334677u) ^ (_5307.y * 3812015801u)) ^ (_5307.z * 2798796415u)) * 1597334677u;
            uint3 _5335 = uint3(int3(_5061 + float3(1.0)));
            uint _5348 = (((_5335.x * 1597334677u) ^ (_5335.y * 3812015801u)) ^ (_5335.z * 2798796415u)) * 1597334677u;
            float _4715 = mix(0.449999988079071044921875, 0.0500000007450580596923828125, _4674);
            float _4719 = ((mix(mix(mix(float((_4839 ^ (_4839 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_4867 ^ (_4867 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _4768), mix(float((_4895 ^ (_4895 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_4923 ^ (_4923 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _4768), _4784), mix(mix(float((_4951 ^ (_4951 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_4979 ^ (_4979 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _4768), mix(float((_5007 ^ (_5007 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_5035 ^ (_5035 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _4768), _4784), _4759.z) * 0.64999997615814208984375) + (mix(mix(mix(float((_5152 ^ (_5152 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_5180 ^ (_5180 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _5081), mix(float((_5208 ^ (_5208 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_5236 ^ (_5236 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _5081), _5097), mix(mix(float((_5264 ^ (_5264 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_5292 ^ (_5292 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _5081), mix(float((_5320 ^ (_5320 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_5348 ^ (_5348 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _5081), _5097), _5072.z) * 0.3499999940395355224609375)) - 0.5;
            _20821 = smoothstep(-_4715, _4715, (_4696 + (-24.450000762939453125)) + (_4719 * mix(0.800000011920928955078125, 2.2000000476837158203125, _4674)));
            break;
        } while(false);
        _20984 = _4665;
        _20951 = _20821;
        _20920 = mix(_20823, (in.m_3428.xyz * _4658) * mix(float3(1.0), _3436 * 2.0, float3(0.5)), float3(_20821));
    }
    else
    {
        _20984 = float2(0.0);
        _20951 = 0.0;
        _20920 = _20823;
    }
    float3 _3500 = fast::normalize(in.m_2946);
    float3 _20833;
    if (_2876._m6.y > 0.5)
    {
        float3 _3515 = in.m_2952.xyz - (_3500 * dot(_3500, in.m_2952.xyz));
        float3 _20834;
        if (dot(_3515, _3515) > 9.9999999600419720025001879548654e-13)
        {
            float3 _3523 = fast::normalize(_3515);
            float4 _3539 = _3534.sample(_2533, _3419);
            float3 _20825;
            if (_2876._m6.z > 0.5)
            {
                float2 _20824;
                if (_2876._m6.z > 1.5)
                {
                    _20824 = _3539.xw;
                }
                else
                {
                    _20824 = _3539.xy;
                }
                float2 _3561 = (_20824 * 2.0) - float2(1.0);
                _20825 = float3(_3561, sqrt(fast::clamp(1.0 - dot(_3561, _3561), 0.0, 1.0)));
            }
            else
            {
                _20825 = (_3539.xyz * 2.0) - float3(1.0);
            }
            float2 _3583 = _20825.xy * _2876._m4.z;
            _20834 = fast::normalize(((_3523 * _3583.x) + ((cross(_3500, _3523) * ((in.m_2952.w < 0.0) ? (-1.0) : 1.0)) * _3583.y)) + (_3500 * _20825.z));
        }
        else
        {
            _20834 = _3500;
        }
        _20833 = _20834;
    }
    else
    {
        _20833 = _3500;
    }
    bool _3607 = _2876._m5.w > 0.5;
    float _20830;
    if (_3607)
    {
        _20830 = fast::clamp(_2876._m1.z, 0.0, 1.0);
    }
    else
    {
        _20830 = 0.0;
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
    float3 _21020;
    if (_3625 && (_20830 <= 0.0))
    {
        _21020 = -_20833;
    }
    else
    {
        _21020 = _20833;
    }
    float3 _3637 = fast::normalize(_283._m4.xyz);
    float3 _3643 = _283._m6.xyz - in.m_3037;
    float3 _3644 = fast::normalize(_3643);
    float3 _3649 = fast::normalize(_3637 + _3644);
    float3 _3655 = _3500 * (gl_FrontFacing ? 1.0 : (-1.0));
    bool _3660 = in.m_3657.x > 0.5;
    float3 _21014;
    float _21054;
    if ((_283._m5.w > 0.5) && _3660)
    {
        float _20890;
        float3 _20891;
        do
        {
            int _5377 = int(_283._m21.x);
            float _5385 = dot(_283._m20.xyz, in.m_3037) + _283._m20.w;
            int _20835;
            _20835 = 0;
            for (;;)
            {
                bool _5391 = _20835 < (_5377 - 1);
                bool _5399;
                if (_5391)
                {
                    _5399 = _5385 > _283._m16[_20835];
                }
                else
                {
                    _5399 = _5391;
                }
                if (_5399)
                {
                    _20835++;
                    continue;
                }
                else
                {
                    break;
                }
            }
            if (_5385 > _283._m16[_20835])
            {
                _20891 = float3(1.0);
                _20890 = 1.0;
                break;
            }
            float _20848;
            do
            {
                float4 _5501 = _283._m14[_20835] * float4(in.m_3037 + (_3655 * _283._m18[_20835]), 1.0);
                float _5504 = _5501.x;
                bool _5505 = _5504 < 0.0;
                bool _5512;
                if (!_5505)
                {
                    _5512 = _5504 > 1.0;
                }
                else
                {
                    _5512 = _5505;
                }
                bool _5519;
                if (!_5512)
                {
                    _5519 = _5501.y < 0.0;
                }
                else
                {
                    _5519 = _5512;
                }
                bool _5526;
                if (!_5519)
                {
                    _5526 = _5501.y > 1.0;
                }
                else
                {
                    _5526 = _5519;
                }
                if (_5526)
                {
                    _20848 = 1.0;
                    break;
                }
                float2 _5539 = float2(float(_20835 & 1), float(_20835 >> 1)) * _283._m23.xy;
                float _5546 = fast::min(_5501.z, 1.0) - _283._m19[_20835];
                float2 _5565 = _283._m22.xy * 0.5;
                float2 _5570 = _5539 + (_5501.xy * _283._m23.xy);
                float4 _5583 = float4(_5539 + _5565, (_5539 + _283._m23.xy) - _5565);
                float _20847;
                do
                {
                    int _5609 = int(_283._m22.z);
                    if (_5609 <= 0)
                    {
                        _20847 = spvDepthCast(_303).sample_compare(_303Smplr, float3(fast::clamp(_5570, _5583.xy, _5583.zw), _5546).xy, _5546);
                        break;
                    }
                    float2 _5632 = (_5570 / _283._m22.xy) + float2(0.5);
                    float2 _5633 = floor(_5632);
                    float2 _5638 = _5632 - _5633;
                    float2 _5641 = _5633 - float2(0.5);
                    bool _5645 = _5609 == 1;
                    spvUnsafeArray<float2, 3> _5593;
                    spvUnsafeArray<float2, 3> _5594;
                    if (_5645)
                    {
                        float2 _5648 = _5638 * 2.0;
                        _5593[0] = float2(3.0) - _5648;
                        _5593[1] = float2(1.0) + _5648;
                        _5594[0] = ((float2(2.0) - _5638) / _5593[0]) - float2(1.0);
                        _5594[1] = (_5638 / _5593[1]) + float2(1.0);
                    }
                    else
                    {
                        float2 _5675 = _5638 * 3.0;
                        _5593[0] = float2(4.0) - _5675;
                        _5593[1] = float2(7.0);
                        _5593[2] = float2(1.0) + _5675;
                        _5594[0] = ((float2(3.0) - (_5638 * 2.0)) / _5593[0]) - float2(2.0);
                        _5594[1] = (float2(3.0) + _5638) / _5593[1];
                        _5594[2] = (_5638 / _5593[2]) + float2(2.0);
                    }
                    int _22097 = _5645 ? 2 : 3;
                    int _20837;
                    float _20840;
                    _20840 = 0.0;
                    _20837 = 0;
                    float _20846;
                    for (; _20837 < _22097; _20840 = _20846, _20837++)
                    {
                        _20846 = _20840;
                        for (int _20843 = 0; _20843 < _22097; )
                        {
                            _20846 += ((_5593[_20843].x * _5593[_20837].y) * spvDepthCast(_303).sample_compare(_303Smplr, float3(fast::clamp(_283._m22.xy * (_5641 + float2(_5594[_20843].x, _5594[_20837].y)), _5583.xy, _5583.zw), _5546).xy, _5546));
                            _20843++;
                            continue;
                        }
                    }
                    _20847 = _20840 * (_5645 ? 0.0625 : 0.0069444444961845874786376953125);
                    break;
                } while(false);
                _20848 = _20847;
                break;
            } while(false);
            float3 _20885;
            float _20888;
            if (_5385 > _283._m17[_20835])
            {
                float _5439 = (_5385 - _283._m17[_20835]) / (_283._m16[_20835] - _283._m17[_20835]);
                int _5441 = _20835 + 1;
                float3 _20886;
                float _20889;
                if (_5441 < _5377)
                {
                    float _20868;
                    do
                    {
                        float4 _5788 = _283._m14[_5441] * float4(in.m_3037 + (_3655 * _283._m18[_5441]), 1.0);
                        float _5791 = _5788.x;
                        bool _5792 = _5791 < 0.0;
                        bool _5799;
                        if (!_5792)
                        {
                            _5799 = _5791 > 1.0;
                        }
                        else
                        {
                            _5799 = _5792;
                        }
                        bool _5806;
                        if (!_5799)
                        {
                            _5806 = _5788.y < 0.0;
                        }
                        else
                        {
                            _5806 = _5799;
                        }
                        bool _5813;
                        if (!_5806)
                        {
                            _5813 = _5788.y > 1.0;
                        }
                        else
                        {
                            _5813 = _5806;
                        }
                        if (_5813)
                        {
                            _20868 = 1.0;
                            break;
                        }
                        float2 _5826 = float2(float(_5441 & 1), float(_5441 >> 1)) * _283._m23.xy;
                        float _5833 = fast::min(_5788.z, 1.0) - _283._m19[_5441];
                        float2 _5852 = _283._m22.xy * 0.5;
                        float2 _5857 = _5826 + (_5788.xy * _283._m23.xy);
                        float4 _5870 = float4(_5826 + _5852, (_5826 + _283._m23.xy) - _5852);
                        float _20867;
                        do
                        {
                            int _5896 = int(_283._m22.z);
                            if (_5896 <= 0)
                            {
                                _20867 = spvDepthCast(_303).sample_compare(_303Smplr, float3(fast::clamp(_5857, _5870.xy, _5870.zw), _5833).xy, _5833);
                                break;
                            }
                            float2 _5919 = (_5857 / _283._m22.xy) + float2(0.5);
                            float2 _5920 = floor(_5919);
                            float2 _5925 = _5919 - _5920;
                            float2 _5928 = _5920 - float2(0.5);
                            bool _5932 = _5896 == 1;
                            spvUnsafeArray<float2, 3> _5880;
                            spvUnsafeArray<float2, 3> _5881;
                            if (_5932)
                            {
                                float2 _5935 = _5925 * 2.0;
                                _5880[0] = float2(3.0) - _5935;
                                _5880[1] = float2(1.0) + _5935;
                                _5881[0] = ((float2(2.0) - _5925) / _5880[0]) - float2(1.0);
                                _5881[1] = (_5925 / _5880[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _5962 = _5925 * 3.0;
                                _5880[0] = float2(4.0) - _5962;
                                _5880[1] = float2(7.0);
                                _5880[2] = float2(1.0) + _5962;
                                _5881[0] = ((float2(3.0) - (_5925 * 2.0)) / _5880[0]) - float2(2.0);
                                _5881[1] = (float2(3.0) + _5925) / _5880[1];
                                _5881[2] = (_5925 / _5880[2]) + float2(2.0);
                            }
                            int _22099 = _5932 ? 2 : 3;
                            int _20857;
                            float _20860;
                            _20860 = 0.0;
                            _20857 = 0;
                            float _20866;
                            for (; _20857 < _22099; _20860 = _20866, _20857++)
                            {
                                _20866 = _20860;
                                for (int _20863 = 0; _20863 < _22099; )
                                {
                                    _20866 += ((_5880[_20863].x * _5880[_20857].y) * spvDepthCast(_303).sample_compare(_303Smplr, float3(fast::clamp(_283._m22.xy * (_5928 + float2(_5881[_20863].x, _5881[_20857].y)), _5870.xy, _5870.zw), _5833).xy, _5833));
                                    _20863++;
                                    continue;
                                }
                            }
                            _20867 = _20860 * (_5932 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _20868 = _20867;
                        break;
                    } while(false);
                    _20889 = mix(_20848, _20868, _5439);
                    _20886 = mix(_657[_20835], _657[_5441], float3(_5439));
                }
                else
                {
                    _20889 = mix(_20848, 1.0, _5439);
                    _20886 = _657[_20835];
                }
                _20888 = _20889;
                _20885 = _20886;
            }
            else
            {
                _20888 = _20848;
                _20885 = _657[_20835];
            }
            _20891 = select(float3(1.0), _20885, bool3(_283._m22.w > 0.5));
            _20890 = _20888;
            break;
        } while(false);
        _21054 = _20890;
        _21014 = _20920 * _20891;
    }
    else
    {
        _21054 = 1.0;
        _21014 = _20920;
    }
    float3 _3686 = _283._m5.xyz * _283._m4.w;
    bool _3690 = _2876._m6.w > 0.5;
    float _20943;
    if (_3690)
    {
        _20943 = 1.0;
    }
    else
    {
        _20943 = 1.0 + (_2876._m4.w * (_3352.sample(_2533, _3419).x - 1.0));
    }
    float _3710 = abs(in.m_2952.w);
    float _21144;
    if (_3710 > 0.0)
    {
        _21144 = _20943 * fast::min(_3710, 1.0);
    }
    else
    {
        _21144 = _20943;
    }
    float3 _21697;
    if (!_3607)
    {
        float _3726 = dot(_21020, _3637);
        bool _3751 = _283._m29.x > 0.5;
        float3 _21672;
        if (_3751)
        {
            float _6113 = (_283._m29.z * _21020.x) - (_283._m29.w * _21020.z);
            float _6126 = (_283._m29.w * _21020.x) + (_283._m29.z * _21020.z);
            float _6144 = 1.09254801273345947265625 * _6113;
            spvUnsafeArray<float, 9> _19386 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _21020.y, 0.48860299587249755859375 * _6126, 0.48860299587249755859375 * _6113, _6144 * _21020.y, (1.09254801273345947265625 * _21020.y) * _6126, 0.3153919875621795654296875 * (((3.0 * _6126) * _6126) - 1.0), _6144 * _6126, 0.546274006366729736328125 * ((_6113 * _6113) - (_21020.y * _21020.y)) });
            spvUnsafeArray<float, 9> _6058 = _19386;
            float3 _21671;
            _21671 = float3(0.0);
            for (int _21670 = 0; _21670 < 9; )
            {
                _21671 += (_2531.read(uint2((int2(496, 256) + int2(_21670, 0))), 0).xyz * _6058[_21670]);
                _21670++;
                continue;
            }
            _21672 = fast::max(_21671, float3(0.0)) * _283._m29.y;
        }
        else
        {
            _21672 = mix(_283._m9.xyz, _283._m8.xyz, float3((_21020.y * 0.5) + 0.5)) * _283._m8.w;
        }
        float3 _3776 = (_21014 * ((_21672 * _21144) + ((_3686 * fast::max(_3726, 0.0)) * _21054))) + ((_3686 * ((powr(fast::max(dot(_21020, _3649), 0.0), _2876._m1.w) * _2876._m1.z) * step(0.0, _3726))) * _21054);
        float3 _21699;
        if (_283._m34.y > 0.5)
        {
            float3 _21683;
            if (_3751)
            {
                float _6259 = (_283._m29.z * _21020.x) - (_283._m29.w * _21020.z);
                float _6272 = (_283._m29.w * _21020.x) + (_283._m29.z * _21020.z);
                float _6290 = 1.09254801273345947265625 * _6259;
                spvUnsafeArray<float, 9> _19367 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _21020.y, 0.48860299587249755859375 * _6272, 0.48860299587249755859375 * _6259, _6290 * _21020.y, (1.09254801273345947265625 * _21020.y) * _6272, 0.3153919875621795654296875 * (((3.0 * _6272) * _6272) - 1.0), _6290 * _6272, 0.546274006366729736328125 * ((_6259 * _6259) - (_21020.y * _21020.y)) });
                spvUnsafeArray<float, 9> _6204 = _19367;
                float3 _21682;
                _21682 = float3(0.0);
                for (int _21681 = 0; _21681 < 9; )
                {
                    _21682 += (_2531.read(uint2((int2(496, 256) + int2(_21681, 0))), 0).xyz * _6204[_21681]);
                    _21681++;
                    continue;
                }
                _21683 = fast::max(_21682, float3(0.0)) * _283._m29.y;
            }
            else
            {
                _21683 = mix(_283._m9.xyz, _283._m8.xyz, float3((_21020.y * 0.5) + 0.5)) * _283._m8.w;
            }
            int _6467 = int(_283._m34.y);
            int _6470 = int(_283._m34.x);
            float3 _21689;
            _21689 = _21683;
            float3 _21987;
            for (int _21688 = 0; _21688 < _6467; _21689 = _21987, _21688++)
            {
                int _6482 = 8 * (_6470 + _21688);
                float4 _6691 = as_type<float4>(_1281._m0[_6482 + 3]);
                float4 _6735 = as_type<float4>(_1281._m0[_6482]);
                float4 _6741 = as_type<float4>(_1281._m0[_6482 + 1]);
                float4 _6747 = as_type<float4>(_1281._m0[_6482 + 2]);
                float3 _6709 = _6735.xyz;
                float _6713 = _6735.w;
                float3 _6716 = _6741.xyz;
                float _6720 = _6741.w;
                float3 _6723 = _6747.xyz;
                float _6727 = _6747.w;
                float3 _6729 = float3(dot(_6709, in.m_3037) + _6713, dot(_6716, in.m_3037) + _6720, dot(_6723, in.m_3037) + _6727);
                float3 _6491 = _6691.xyz;
                float _6493 = _6691.w;
                float _21950;
                do
                {
                    float3 _6759 = _6491 - abs(_6729);
                    float _6767 = fast::min(_6759.x, fast::min(_6759.y, _6759.z));
                    if (_6767 <= 0.0)
                    {
                        _21950 = 0.0;
                        break;
                    }
                    if (_6493 <= 0.0)
                    {
                        _21950 = 1.0;
                        break;
                    }
                    float _6779 = fast::min(_6767 / _6493, 1.0);
                    _21950 = (_6779 * _6779) * (3.0 - (2.0 * _6779));
                    break;
                } while(false);
                if (_21950 <= 0.0)
                {
                    _21987 = _21689;
                    continue;
                }
                float3 _6502 = as_type<float4>(_1281._m0[_6482 + 4]).xyz;
                float4 _6800 = as_type<float4>(_1281._m0[_6482 + 5]);
                int _6806 = int(((device uint*)&_1281._m0[_6482 + 6])[0u]);
                float _6816 = dot(_6709, _21020);
                float _6822 = dot(_6716, _21020);
                float _6828 = dot(_6723, _21020);
                float3 _6829 = float3(_6816, _6822, _6828);
                float3 _6522 = (in.m_3037 + (_21020 * _6800.x)) + (_3644 * _6800.y);
                float3 _6541 = fast::clamp((((float3(dot(_6709, _6522) + _6713, dot(_6716, _6522) + _6720, dot(_6723, _6522) + _6727) + _6491) / fast::max(_6491 * 2.0, float3(9.9999999747524270787835121154785e-07))) * _6502) - float3(0.5), float3(0.0), _6502 - float3(1.0));
                int3 _6543 = int3(_6502);
                int3 _6550 = min(int3(_6541), max((_6543 - int3(2)), int3(0)));
                float3 _6554 = _6541 - float3(_6550);
                float _6909 = 0.48860299587249755859375 * _6822;
                float _6912 = 0.48860299587249755859375 * _6828;
                float _6915 = 0.48860299587249755859375 * _6816;
                float _6920 = 1.09254801273345947265625 * _6816;
                float _6923 = _6920 * _6822;
                float _6929 = (1.09254801273345947265625 * _6822) * _6828;
                float _6937 = 0.3153919875621795654296875 * (((3.0 * _6828) * _6828) - 1.0);
                float _6943 = _6920 * _6828;
                float _6957 = 0.546274006366729736328125 * ((_6816 * _6816) - (_6822 * _6822));
                int3 _6976 = _6543 - int3(1);
                int3 _6977 = min(_6550, _6976);
                int _6982 = _6543.x;
                int _6986 = _6543.y;
                int _6994 = _6806 + ((_6977.x + (_6982 * (_6977.y + (_6986 * _6977.z)))) * 4);
                float3 _6997 = float3(1.0) - _6554;
                float3 _7015 = (((((float3(_6977) + float3(0.5)) / _6502) * _6491) * 2.0) - _6491) - _6729;
                float _7025 = dot(_7015 * rsqrt(fast::max(dot(_7015, _7015), 1.0000000133514319600180897396058e-10)), _6829) + 1.0;
                float _7028 = _6997.x;
                float _7030 = _6997.y;
                float _7031 = _7028 * _7030;
                float _7033 = _6997.z;
                int _7057 = _6994 + 3;
                float _7043 = ((_7031 * _7033) * ((0.25 * (_7025 * _7025)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_7057])[1u])).y > 0.5);
                int _7087 = _6994 + 1;
                int _7091 = _6994 + 2;
                float2 _7103 = float2(as_type<half2>(_1281._m0[_6994].y));
                float2 _7112 = float2(as_type<half2>(_1281._m0[_7087].x));
                float2 _7121 = float2(as_type<half2>(_1281._m0[_7087].w));
                float2 _7130 = float2(as_type<half2>(_1281._m0[_7091].z));
                float3 _7218 = (((((((float3(float2(as_type<half2>(_1281._m0[_6994].x)), _7103.x) * 0.2820949852466583251953125) + (float3(_7103.y, float2(as_type<half2>(_1281._m0[_6994].z))) * _6909)) + (float3(float2(as_type<half2>(_1281._m0[_6994].w)), _7112.x) * _6912)) + (float3(_7112.y, float2(as_type<half2>(_1281._m0[_7087].y))) * _6915)) + (float3(float2(as_type<half2>(_1281._m0[_7087].z)), _7121.x) * _6923)) + (float3(_7121.y, float2(as_type<half2>(_1281._m0[_7091].x))) * _6929)) + (float3(float2(as_type<half2>(_1281._m0[_7091].y)), _7130.x) * _6937)) + (float3(_7130.y, float2(as_type<half2>(_1281._m0[_7091].w))) * _6943);
                int3 _7246 = min((_6550 + int3(1, 0, 0)), _6976);
                int _7263 = _6806 + ((_7246.x + (_6982 * (_7246.y + (_6986 * _7246.z)))) * 4);
                float3 _7284 = (((((float3(_7246) + float3(0.5)) / _6502) * _6491) * 2.0) - _6491) - _6729;
                float _7294 = dot(_7284 * rsqrt(fast::max(dot(_7284, _7284), 1.0000000133514319600180897396058e-10)), _6829) + 1.0;
                float _7300 = _6554.x * _7030;
                int _7326 = _7263 + 3;
                float _7312 = ((_7300 * _7033) * ((0.25 * (_7294 * _7294)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_7326])[1u])).y > 0.5);
                int _7356 = _7263 + 1;
                int _7360 = _7263 + 2;
                float2 _7372 = float2(as_type<half2>(_1281._m0[_7263].y));
                float2 _7381 = float2(as_type<half2>(_1281._m0[_7356].x));
                float2 _7390 = float2(as_type<half2>(_1281._m0[_7356].w));
                float2 _7399 = float2(as_type<half2>(_1281._m0[_7360].z));
                float3 _7487 = (((((((float3(float2(as_type<half2>(_1281._m0[_7263].x)), _7372.x) * 0.2820949852466583251953125) + (float3(_7372.y, float2(as_type<half2>(_1281._m0[_7263].z))) * _6909)) + (float3(float2(as_type<half2>(_1281._m0[_7263].w)), _7381.x) * _6912)) + (float3(_7381.y, float2(as_type<half2>(_1281._m0[_7356].y))) * _6915)) + (float3(float2(as_type<half2>(_1281._m0[_7356].z)), _7390.x) * _6923)) + (float3(_7390.y, float2(as_type<half2>(_1281._m0[_7360].x))) * _6929)) + (float3(float2(as_type<half2>(_1281._m0[_7360].y)), _7399.x) * _6937)) + (float3(_7399.y, float2(as_type<half2>(_1281._m0[_7360].w))) * _6943);
                int3 _7515 = min((_6550 + int3(0, 1, 0)), _6976);
                int _7532 = _6806 + ((_7515.x + (_6982 * (_7515.y + (_6986 * _7515.z)))) * 4);
                float3 _7553 = (((((float3(_7515) + float3(0.5)) / _6502) * _6491) * 2.0) - _6491) - _6729;
                float _7563 = dot(_7553 * rsqrt(fast::max(dot(_7553, _7553), 1.0000000133514319600180897396058e-10)), _6829) + 1.0;
                float _7569 = _7028 * _6554.y;
                int _7595 = _7532 + 3;
                float _7581 = ((_7569 * _7033) * ((0.25 * (_7563 * _7563)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_7595])[1u])).y > 0.5);
                int _7625 = _7532 + 1;
                int _7629 = _7532 + 2;
                float2 _7641 = float2(as_type<half2>(_1281._m0[_7532].y));
                float2 _7650 = float2(as_type<half2>(_1281._m0[_7625].x));
                float2 _7659 = float2(as_type<half2>(_1281._m0[_7625].w));
                float2 _7668 = float2(as_type<half2>(_1281._m0[_7629].z));
                float3 _7756 = (((((((float3(float2(as_type<half2>(_1281._m0[_7532].x)), _7641.x) * 0.2820949852466583251953125) + (float3(_7641.y, float2(as_type<half2>(_1281._m0[_7532].z))) * _6909)) + (float3(float2(as_type<half2>(_1281._m0[_7532].w)), _7650.x) * _6912)) + (float3(_7650.y, float2(as_type<half2>(_1281._m0[_7625].y))) * _6915)) + (float3(float2(as_type<half2>(_1281._m0[_7625].z)), _7659.x) * _6923)) + (float3(_7659.y, float2(as_type<half2>(_1281._m0[_7629].x))) * _6929)) + (float3(float2(as_type<half2>(_1281._m0[_7629].y)), _7668.x) * _6937)) + (float3(_7668.y, float2(as_type<half2>(_1281._m0[_7629].w))) * _6943);
                int3 _7784 = min((_6550 + int3(1, 1, 0)), _6976);
                int _7801 = _6806 + ((_7784.x + (_6982 * (_7784.y + (_6986 * _7784.z)))) * 4);
                float3 _7822 = (((((float3(_7784) + float3(0.5)) / _6502) * _6491) * 2.0) - _6491) - _6729;
                float _7832 = dot(_7822 * rsqrt(fast::max(dot(_7822, _7822), 1.0000000133514319600180897396058e-10)), _6829) + 1.0;
                float _7838 = _6554.x * _6554.y;
                int _7864 = _7801 + 3;
                float _7850 = ((_7838 * _7033) * ((0.25 * (_7832 * _7832)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_7864])[1u])).y > 0.5);
                int _7894 = _7801 + 1;
                int _7898 = _7801 + 2;
                float2 _7910 = float2(as_type<half2>(_1281._m0[_7801].y));
                float2 _7919 = float2(as_type<half2>(_1281._m0[_7894].x));
                float2 _7928 = float2(as_type<half2>(_1281._m0[_7894].w));
                float2 _7937 = float2(as_type<half2>(_1281._m0[_7898].z));
                float3 _8025 = (((((((float3(float2(as_type<half2>(_1281._m0[_7801].x)), _7910.x) * 0.2820949852466583251953125) + (float3(_7910.y, float2(as_type<half2>(_1281._m0[_7801].z))) * _6909)) + (float3(float2(as_type<half2>(_1281._m0[_7801].w)), _7919.x) * _6912)) + (float3(_7919.y, float2(as_type<half2>(_1281._m0[_7894].y))) * _6915)) + (float3(float2(as_type<half2>(_1281._m0[_7894].z)), _7928.x) * _6923)) + (float3(_7928.y, float2(as_type<half2>(_1281._m0[_7898].x))) * _6929)) + (float3(float2(as_type<half2>(_1281._m0[_7898].y)), _7937.x) * _6937)) + (float3(_7937.y, float2(as_type<half2>(_1281._m0[_7898].w))) * _6943);
                int3 _8053 = min((_6550 + int3(0, 0, 1)), _6976);
                int _8070 = _6806 + ((_8053.x + (_6982 * (_8053.y + (_6986 * _8053.z)))) * 4);
                float3 _8091 = (((((float3(_8053) + float3(0.5)) / _6502) * _6491) * 2.0) - _6491) - _6729;
                float _8101 = dot(_8091 * rsqrt(fast::max(dot(_8091, _8091), 1.0000000133514319600180897396058e-10)), _6829) + 1.0;
                int _8133 = _8070 + 3;
                float _8119 = ((_7031 * _6554.z) * ((0.25 * (_8101 * _8101)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_8133])[1u])).y > 0.5);
                int _8163 = _8070 + 1;
                int _8167 = _8070 + 2;
                float2 _8179 = float2(as_type<half2>(_1281._m0[_8070].y));
                float2 _8188 = float2(as_type<half2>(_1281._m0[_8163].x));
                float2 _8197 = float2(as_type<half2>(_1281._m0[_8163].w));
                float2 _8206 = float2(as_type<half2>(_1281._m0[_8167].z));
                float3 _8294 = (((((((float3(float2(as_type<half2>(_1281._m0[_8070].x)), _8179.x) * 0.2820949852466583251953125) + (float3(_8179.y, float2(as_type<half2>(_1281._m0[_8070].z))) * _6909)) + (float3(float2(as_type<half2>(_1281._m0[_8070].w)), _8188.x) * _6912)) + (float3(_8188.y, float2(as_type<half2>(_1281._m0[_8163].y))) * _6915)) + (float3(float2(as_type<half2>(_1281._m0[_8163].z)), _8197.x) * _6923)) + (float3(_8197.y, float2(as_type<half2>(_1281._m0[_8167].x))) * _6929)) + (float3(float2(as_type<half2>(_1281._m0[_8167].y)), _8206.x) * _6937)) + (float3(_8206.y, float2(as_type<half2>(_1281._m0[_8167].w))) * _6943);
                float4 _6621 = (((float4((_7218 + (float3(float2(as_type<half2>(_1281._m0[_7057].x)), float2(as_type<half2>(_1281._m0[_7057].y)).x) * _6957)) * _7043, _7043) + float4((_7487 + (float3(float2(as_type<half2>(_1281._m0[_7326].x)), float2(as_type<half2>(_1281._m0[_7326].y)).x) * _6957)) * _7312, _7312)) + float4((_7756 + (float3(float2(as_type<half2>(_1281._m0[_7595].x)), float2(as_type<half2>(_1281._m0[_7595].y)).x) * _6957)) * _7581, _7581)) + float4((_8025 + (float3(float2(as_type<half2>(_1281._m0[_7864].x)), float2(as_type<half2>(_1281._m0[_7864].y)).x) * _6957)) * _7850, _7850)) + float4((_8294 + (float3(float2(as_type<half2>(_1281._m0[_8133].x)), float2(as_type<half2>(_1281._m0[_8133].y)).x) * _6957)) * _8119, _8119);
                int3 _8322 = min((_6550 + int3(1, 0, 1)), _6976);
                int _8339 = _6806 + ((_8322.x + (_6982 * (_8322.y + (_6986 * _8322.z)))) * 4);
                float3 _8360 = (((((float3(_8322) + float3(0.5)) / _6502) * _6491) * 2.0) - _6491) - _6729;
                float _8370 = dot(_8360 * rsqrt(fast::max(dot(_8360, _8360), 1.0000000133514319600180897396058e-10)), _6829) + 1.0;
                int _8402 = _8339 + 3;
                float _8388 = ((_7300 * _6554.z) * ((0.25 * (_8370 * _8370)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_8402])[1u])).y > 0.5);
                int _8432 = _8339 + 1;
                int _8436 = _8339 + 2;
                float2 _8448 = float2(as_type<half2>(_1281._m0[_8339].y));
                float2 _8457 = float2(as_type<half2>(_1281._m0[_8432].x));
                float2 _8466 = float2(as_type<half2>(_1281._m0[_8432].w));
                float2 _8475 = float2(as_type<half2>(_1281._m0[_8436].z));
                float3 _8563 = (((((((float3(float2(as_type<half2>(_1281._m0[_8339].x)), _8448.x) * 0.2820949852466583251953125) + (float3(_8448.y, float2(as_type<half2>(_1281._m0[_8339].z))) * _6909)) + (float3(float2(as_type<half2>(_1281._m0[_8339].w)), _8457.x) * _6912)) + (float3(_8457.y, float2(as_type<half2>(_1281._m0[_8432].y))) * _6915)) + (float3(float2(as_type<half2>(_1281._m0[_8432].z)), _8466.x) * _6923)) + (float3(_8466.y, float2(as_type<half2>(_1281._m0[_8436].x))) * _6929)) + (float3(float2(as_type<half2>(_1281._m0[_8436].y)), _8475.x) * _6937)) + (float3(_8475.y, float2(as_type<half2>(_1281._m0[_8436].w))) * _6943);
                int3 _8591 = min((_6550 + int3(0, 1, 1)), _6976);
                int _8608 = _6806 + ((_8591.x + (_6982 * (_8591.y + (_6986 * _8591.z)))) * 4);
                float3 _8629 = (((((float3(_8591) + float3(0.5)) / _6502) * _6491) * 2.0) - _6491) - _6729;
                float _8639 = dot(_8629 * rsqrt(fast::max(dot(_8629, _8629), 1.0000000133514319600180897396058e-10)), _6829) + 1.0;
                int _8671 = _8608 + 3;
                float _8657 = ((_7569 * _6554.z) * ((0.25 * (_8639 * _8639)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_8671])[1u])).y > 0.5);
                int _8701 = _8608 + 1;
                int _8705 = _8608 + 2;
                float2 _8717 = float2(as_type<half2>(_1281._m0[_8608].y));
                float2 _8726 = float2(as_type<half2>(_1281._m0[_8701].x));
                float2 _8735 = float2(as_type<half2>(_1281._m0[_8701].w));
                float2 _8744 = float2(as_type<half2>(_1281._m0[_8705].z));
                float3 _8832 = (((((((float3(float2(as_type<half2>(_1281._m0[_8608].x)), _8717.x) * 0.2820949852466583251953125) + (float3(_8717.y, float2(as_type<half2>(_1281._m0[_8608].z))) * _6909)) + (float3(float2(as_type<half2>(_1281._m0[_8608].w)), _8726.x) * _6912)) + (float3(_8726.y, float2(as_type<half2>(_1281._m0[_8701].y))) * _6915)) + (float3(float2(as_type<half2>(_1281._m0[_8701].z)), _8735.x) * _6923)) + (float3(_8735.y, float2(as_type<half2>(_1281._m0[_8705].x))) * _6929)) + (float3(float2(as_type<half2>(_1281._m0[_8705].y)), _8744.x) * _6937)) + (float3(_8744.y, float2(as_type<half2>(_1281._m0[_8705].w))) * _6943);
                int3 _8860 = min((_6550 + int3(1)), _6976);
                int _8877 = _6806 + ((_8860.x + (_6982 * (_8860.y + (_6986 * _8860.z)))) * 4);
                float3 _8898 = (((((float3(_8860) + float3(0.5)) / _6502) * _6491) * 2.0) - _6491) - _6729;
                float _8908 = dot(_8898 * rsqrt(fast::max(dot(_8898, _8898), 1.0000000133514319600180897396058e-10)), _6829) + 1.0;
                int _8940 = _8877 + 3;
                float _8926 = ((_7838 * _6554.z) * ((0.25 * (_8908 * _8908)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_8940])[1u])).y > 0.5);
                int _8970 = _8877 + 1;
                int _8974 = _8877 + 2;
                float2 _8986 = float2(as_type<half2>(_1281._m0[_8877].y));
                float2 _8995 = float2(as_type<half2>(_1281._m0[_8970].x));
                float2 _9004 = float2(as_type<half2>(_1281._m0[_8970].w));
                float2 _9013 = float2(as_type<half2>(_1281._m0[_8974].z));
                float3 _9101 = (((((((float3(float2(as_type<half2>(_1281._m0[_8877].x)), _8986.x) * 0.2820949852466583251953125) + (float3(_8986.y, float2(as_type<half2>(_1281._m0[_8877].z))) * _6909)) + (float3(float2(as_type<half2>(_1281._m0[_8877].w)), _8995.x) * _6912)) + (float3(_8995.y, float2(as_type<half2>(_1281._m0[_8970].y))) * _6915)) + (float3(float2(as_type<half2>(_1281._m0[_8970].z)), _9004.x) * _6923)) + (float3(_9004.y, float2(as_type<half2>(_1281._m0[_8974].x))) * _6929)) + (float3(float2(as_type<half2>(_1281._m0[_8974].y)), _9013.x) * _6937)) + (float3(_9013.y, float2(as_type<half2>(_1281._m0[_8974].w))) * _6943);
                float4 _6660 = ((_6621 + float4((_8563 + (float3(float2(as_type<half2>(_1281._m0[_8402].x)), float2(as_type<half2>(_1281._m0[_8402].y)).x) * _6957)) * _8388, _8388)) + float4((_8832 + (float3(float2(as_type<half2>(_1281._m0[_8671].x)), float2(as_type<half2>(_1281._m0[_8671].y)).x) * _6957)) * _8657, _8657)) + float4((_9101 + (float3(float2(as_type<half2>(_1281._m0[_8940].x)), float2(as_type<half2>(_1281._m0[_8940].y)).x) * _6957)) * _8926, _8926);
                float _6664 = _6660.w;
                float3 _21988;
                if (_6664 > 9.9999997473787516355514526367188e-06)
                {
                    _21988 = mix(_21689, (fast::max(_6660.xyz, float3(0.0)) / float3(_6664)) * _6800.z, float3(_21950));
                }
                else
                {
                    _21988 = _21689;
                }
                _21987 = _21988;
            }
            _21699 = _3776 + ((_21014 * (_21689 - _21683)) * _21144);
        }
        else
        {
            _21699 = _3776;
        }
        float3 _21698;
        if (_283._m13.w > 0.5)
        {
            float2 _9139 = fast::clamp(floor(gl_FragCoord.xy * _283._m12.xy), float2(0.0), _283._m13.xy - float2(1.0));
            uint _9167 = uint((((fast::clamp(floor((log2(fast::max(dot(_283._m11.xyz, in.m_3037) + _283._m11.w, 9.9999999747524270787835121154785e-07)) * _283._m12.z) + _283._m12.w), 0.0, _283._m13.z - 1.0) * _283._m13.y) + _9139.y) * _283._m13.x) + _9139.x);
            uint _9169 = _9167 >> uint(2);
            uint _9171 = _9167 & 3u;
            uint _9175 = _3167._m0[_9169][_9171] & 65535u;
            uint _9177 = _3167._m0[_9169][_9171] >> uint(16);
            float3 _21700;
            _21700 = _21699;
            float3 _3893;
            spvUnsafeArray<float2, 3> _9585;
            spvUnsafeArray<float2, 3> _9586;
            spvUnsafeArray<float2, 3> _9798;
            spvUnsafeArray<float2, 3> _9799;
            for (uint _21696 = _9175; _21696 < (_9175 + _9177); _21700 = _3893, _21696++)
            {
                uint _9183 = _21696 / 3u;
                uint _9196 = (_3188._m0[_9183 >> uint(2)][_9183 & 3u] >> ((_21696 - (_9183 * 3u)) * 10u)) & 1023u;
                float3 _9213 = _3030._m0[_9196].xyz - in.m_3037;
                float _9216 = dot(_9213, _9213);
                float _9220 = _9216 * _3030._m0[_9196].w;
                float _9225 = fast::clamp(1.0 - (_9220 * _9220), 0.0, 1.0);
                float3 _9230 = _9213 * rsqrt(fast::max(_9216, 9.9999999392252902907785028219223e-09));
                float _9248 = fast::clamp((dot(-_9230, _3073._m0[_9196].xyz) * _3065._m0[_9196].w) + _3073._m0[_9196].w, 0.0, 1.0);
                float3 _9261 = _3065._m0[_9196].xyz * ((((_9225 * _9225) * _9248) * _9248) / fast::max(_9216, 9.9999997473787516355514526367188e-05));
                float3 _21915;
                if (_3660)
                {
                    float _21864;
                    do
                    {
                        uint _9297 = uint(_283._m21.z);
                        if (_9196 < _9297)
                        {
                            float _9319 = _283._m26[_9196].z * fast::max((_283._m15[_9196] * float4(in.m_3037, 1.0)).w, 0.0);
                            float4 _9343 = _283._m15[_9196] * float4((in.m_3037 + (_3655 * (_9319 * _283._m25.x))) + (_9230 * (_9319 * _283._m25.y)), 1.0);
                            float _9345 = _9343.w;
                            if (_9345 <= 0.0)
                            {
                                _21864 = 1.0;
                                break;
                            }
                            float3 _9354 = _9343.xyz / float3(_9345);
                            float _9356 = _9354.x;
                            bool _9357 = _9356 < 0.0;
                            bool _9364;
                            if (!_9357)
                            {
                                _9364 = _9356 > 1.0;
                            }
                            else
                            {
                                _9364 = _9357;
                            }
                            bool _9371;
                            if (!_9364)
                            {
                                _9371 = _9354.y < 0.0;
                            }
                            else
                            {
                                _9371 = _9364;
                            }
                            bool _9378;
                            if (!_9371)
                            {
                                _9378 = _9354.y > 1.0;
                            }
                            else
                            {
                                _9378 = _9371;
                            }
                            bool _9385;
                            if (!_9378)
                            {
                                _9385 = _9354.z > 1.0;
                            }
                            else
                            {
                                _9385 = _9378;
                            }
                            if (_9385)
                            {
                                _21864 = 1.0;
                                break;
                            }
                            float _9391 = _9354.z;
                            float2 _9557 = _283._m22.xy * 0.5;
                            float2 _9562 = _283._m26[_9196].xy + (_9354.xy * _283._m23.zw);
                            float4 _9575 = float4(_283._m26[_9196].xy + _9557, (_283._m26[_9196].xy + _283._m23.zw) - _9557);
                            float _21863;
                            do
                            {
                                int _9601 = int(_283._m22.z);
                                if (_9601 <= 0)
                                {
                                    float2 _9611 = fast::clamp(_9562, _9575.xy, _9575.zw);
                                    _21863 = spvDepthCast(_303).sample_compare(_303Smplr, float3(_9611, _9391).xy, _9391);
                                    break;
                                }
                                float2 _9624 = (_9562 / _283._m22.xy) + float2(0.5);
                                float2 _9625 = floor(_9624);
                                float2 _9630 = _9624 - _9625;
                                float2 _9633 = _9625 - float2(0.5);
                                bool _9637 = _9601 == 1;
                                if (_9637)
                                {
                                    float2 _9640 = _9630 * 2.0;
                                    _9585[0] = float2(3.0) - _9640;
                                    _9585[1] = float2(1.0) + _9640;
                                    _9586[0] = ((float2(2.0) - _9630) / _9585[0]) - float2(1.0);
                                    _9586[1] = (_9630 / _9585[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _9667 = _9630 * 3.0;
                                    _9585[0] = float2(4.0) - _9667;
                                    _9585[1] = float2(7.0);
                                    _9585[2] = float2(1.0) + _9667;
                                    _9586[0] = ((float2(3.0) - (_9630 * 2.0)) / _9585[0]) - float2(2.0);
                                    _9586[1] = (float2(3.0) + _9630) / _9585[1];
                                    _9586[2] = (_9630 / _9585[2]) + float2(2.0);
                                }
                                int _22104 = _9637 ? 2 : 3;
                                int _21853;
                                float _21856;
                                _21856 = 0.0;
                                _21853 = 0;
                                float _21862;
                                for (; _21853 < _22104; _21856 = _21862, _21853++)
                                {
                                    _21862 = _21856;
                                    for (int _21859 = 0; _21859 < _22104; )
                                    {
                                        _21862 += ((_9585[_21859].x * _9585[_21853].y) * spvDepthCast(_303).sample_compare(_303Smplr, float3(fast::clamp(_283._m22.xy * (_9633 + float2(_9586[_21859].x, _9586[_21853].y)), _9575.xy, _9575.zw), _9391).xy, _9391));
                                        _21859++;
                                        continue;
                                    }
                                }
                                _21863 = _21856 * (_9637 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _21864 = _21863;
                            break;
                        }
                        uint _9401 = _9196 - _9297;
                        if (_9401 >= uint(_283._m21.w))
                        {
                            _21864 = 1.0;
                            break;
                        }
                        float _9422 = _283._m27[_9401].w * length(in.m_3037 - _283._m27[_9401].xyz);
                        float3 _9440 = ((in.m_3037 + (_3655 * (_9422 * _283._m25.x))) + (_9230 * (_9422 * _283._m25.y))) - _283._m27[_9401].xyz;
                        float3 _9442 = abs(_9440);
                        float _9444 = _9442.x;
                        float _9446 = _9442.y;
                        bool _9447 = _9444 >= _9446;
                        bool _9455;
                        if (_9447)
                        {
                            _9455 = _9444 >= _9442.z;
                        }
                        else
                        {
                            _9455 = _9447;
                        }
                        float _21838;
                        int _21840;
                        if (_9455)
                        {
                            _21840 = (_9440.x > 0.0) ? 0 : 1;
                            _21838 = _9444;
                        }
                        else
                        {
                            float _9467 = _9442.z;
                            bool _9468 = _9446 >= _9467;
                            int _21841;
                            if (_9468)
                            {
                                _21841 = (_9440.y > 0.0) ? 2 : 3;
                            }
                            else
                            {
                                _21841 = (_9440.z > 0.0) ? 4 : 5;
                            }
                            _21840 = _21841;
                            _21838 = _9468 ? _9446 : _9467;
                        }
                        if (_21838 <= 0.0)
                        {
                            _21864 = 1.0;
                            break;
                        }
                        float2 _9505 = float2(dot(_9440, _961[_21840]), dot(_9440, _970[_21840])) / float2(_21838 * _283._m24.z);
                        float _9512 = _283._m28[_9401].z + (_283._m28[_9401].w / _21838);
                        if (_9512 > 1.0)
                        {
                            _21864 = 1.0;
                            break;
                        }
                        float2 _9530 = _283._m28[_9401].xy + (float2(float(spvSMod(_21840, 3)), float(_21840 / 3)) * _283._m24.xy);
                        float2 _9770 = _283._m22.xy * 0.5;
                        float2 _9775 = _9530 + (float2(0.5 + (0.5 * _9505.x), 0.5 - (0.5 * _9505.y)) * _283._m24.xy);
                        float4 _9788 = float4(_9530 + _9770, (_9530 + _283._m24.xy) - _9770);
                        float _21852;
                        do
                        {
                            int _9814 = int(_283._m22.z);
                            if (_9814 <= 0)
                            {
                                _21852 = spvDepthCast(_303).sample_compare(_303Smplr, float3(fast::clamp(_9775, _9788.xy, _9788.zw), _9512).xy, _9512);
                                break;
                            }
                            float2 _9837 = (_9775 / _283._m22.xy) + float2(0.5);
                            float2 _9838 = floor(_9837);
                            float2 _9843 = _9837 - _9838;
                            float2 _9846 = _9838 - float2(0.5);
                            bool _9850 = _9814 == 1;
                            if (_9850)
                            {
                                float2 _9853 = _9843 * 2.0;
                                _9798[0] = float2(3.0) - _9853;
                                _9798[1] = float2(1.0) + _9853;
                                _9799[0] = ((float2(2.0) - _9843) / _9798[0]) - float2(1.0);
                                _9799[1] = (_9843 / _9798[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _9880 = _9843 * 3.0;
                                _9798[0] = float2(4.0) - _9880;
                                _9798[1] = float2(7.0);
                                _9798[2] = float2(1.0) + _9880;
                                _9799[0] = ((float2(3.0) - (_9843 * 2.0)) / _9798[0]) - float2(2.0);
                                _9799[1] = (float2(3.0) + _9843) / _9798[1];
                                _9799[2] = (_9843 / _9798[2]) + float2(2.0);
                            }
                            int _22107 = _9850 ? 2 : 3;
                            int _21842;
                            float _21845;
                            _21845 = 0.0;
                            _21842 = 0;
                            float _21851;
                            for (; _21842 < _22107; _21845 = _21851, _21842++)
                            {
                                _21851 = _21845;
                                for (int _21848 = 0; _21848 < _22107; )
                                {
                                    _21851 += ((_9798[_21848].x * _9798[_21842].y) * spvDepthCast(_303).sample_compare(_303Smplr, float3(fast::clamp(_283._m22.xy * (_9846 + float2(_9799[_21848].x, _9799[_21842].y)), _9788.xy, _9788.zw), _9512).xy, _9512));
                                    _21848++;
                                    continue;
                                }
                            }
                            _21852 = _21845 * (_9850 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _21864 = _21852;
                        break;
                    } while(false);
                    _21915 = _9261 * _21864;
                }
                else
                {
                    _21915 = _9261;
                }
                float _3864 = dot(_21020, _9230);
                _3893 = _21700 + (((_21014 * fast::max(_3864, 0.0)) * _21915) + (_21915 * ((powr(fast::max(dot(_21020, fast::normalize(_9230 + _3644)), 0.0), _2876._m1.w) * _2876._m1.z) * step(0.0, _3864))));
            }
            _21698 = _21700;
        }
        else
        {
            _21698 = _21699;
        }
        _21697 = _21698;
    }
    else
    {
        float4 _3903 = _3898.sample(_2533, _3419);
        float _3910 = fast::clamp(_2876._m4.x * _3903.z, 0.0, 1.0);
        float _3918 = fast::clamp(_2876._m4.y * _3903.y, 0.04500000178813934326171875, 1.0);
        float _21010;
        float _21015;
        if (_20951 > 0.0)
        {
            _21015 = mix(_3910, _20984.y, _20951);
            _21010 = mix(_3918, fast::max(_20984.x, 0.04500000178813934326171875), _20951);
        }
        else
        {
            _21015 = _3910;
            _21010 = _3918;
        }
        float _3937 = _21010 * _21010;
        float3 _3942 = _21014 * (1.0 - _21015);
        float3 _3948 = mix(float3(0.039999999105930328369140625), _21014, float3(_21015));
        bool _3952 = _20830 > 0.0;
        float3 _21043;
        if (_3952)
        {
            float3 _3957 = dfdx(in.m_3037);
            float3 _3959 = dfdy(in.m_3037);
            float3 _3960 = cross(_3957, _3959);
            float3 _21044;
            if (dot(_3960, _3960) > 9.9999996826552253889678874634872e-21)
            {
                _21044 = fast::normalize((fast::normalize(_3960) * ((dot(_3960, _3644) < 0.0) ? (-1.0) : 1.0)) + (_21020 - _3500));
            }
            else
            {
                _21044 = _21020;
            }
            _21043 = _21044;
        }
        else
        {
            _21043 = _21020;
        }
        float _3986 = fast::max(dot(_21043, _3644), 9.9999997473787516355514526367188e-05);
        float _3995 = dot(_21043, _3637);
        float _3996 = fast::clamp(_3995, 0.0, 1.0);
        float _4001 = fast::clamp(dot(_21043, _3649), 0.0, 1.0);
        float _4006 = fast::clamp(dot(_3644, _3649), 0.0, 1.0);
        float _21047;
        float _21048;
        if (_3952)
        {
            _21048 = fast::max(_3986, 0.5);
            _21047 = fast::max(_4006, 0.5);
        }
        else
        {
            _21048 = _3986;
            _21047 = _4006;
        }
        float3 _9982 = float3(1.0) - _3948;
        float3 _9985 = _3948 + (_9982 * powr(1.0 - _21047, 5.0));
        float _9992 = _3937 * _3937;
        float _9997 = _9992 - 1.0;
        float _9999 = ((_4001 * _4001) * _9997) + 1.0;
        float _10019 = 1.0 - _9992;
        float _10023 = sqrt(((_21048 * _21048) * _10019) + _9992);
        float3 _4052 = (((((float3(1.0) - _9985) * _3942) * fast::clamp(dot(_21020, _3637), 0.0, 1.0)) + (((_9985 * ((_9992 / ((3.1415927410125732421875 * _9999) * _9999)) * (0.5 / fast::max((_3996 * _10023) + (_21048 * sqrt(((_3996 * _3996) * _10019) + _9992)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875) * _3996)) * _3686) * _21054;
        float3 _21158;
        if (_3952)
        {
            _21158 = _4052 + (((((_3942 * _3686) * _21054) * _20830) * fast::clamp(-_3995, 0.0, 1.0)) * (0.3499999940395355224609375 + (0.64999997615814208984375 * powr(fast::clamp(dot(-_3644, _3637), 0.0, 1.0), 3.0))));
        }
        else
        {
            _21158 = _4052;
        }
        bool _4087 = _283._m29.x > 0.5;
        float3 _21084;
        float2 _21108;
        float3 _21120;
        if (_4087)
        {
            float4 _10056 = _2632.sample(_2634, (((float2(_21048, _21010) * 31.0) + float2(0.5)) * float2(0.03125)));
            float _10115 = (_283._m29.z * _21020.x) - (_283._m29.w * _21020.z);
            float _10128 = (_283._m29.w * _21020.x) + (_283._m29.z * _21020.z);
            float _10146 = 1.09254801273345947265625 * _10115;
            spvUnsafeArray<float, 9> _19229 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _21020.y, 0.48860299587249755859375 * _10128, 0.48860299587249755859375 * _10115, _10146 * _21020.y, (1.09254801273345947265625 * _21020.y) * _10128, 0.3153919875621795654296875 * (((3.0 * _10128) * _10128) - 1.0), _10146 * _10128, 0.546274006366729736328125 * ((_10115 * _10115) - (_21020.y * _21020.y)) });
            spvUnsafeArray<float, 9> _10060 = _19229;
            float3 _21066;
            _21066 = float3(0.0);
            for (int _21065 = 0; _21065 < 9; )
            {
                _21066 += (_2531.read(uint2((int2(496, 256) + int2(_21065, 0))), 0).xyz * _10060[_21065]);
                _21065++;
                continue;
            }
            float3 _4104 = reflect(-_3644, _21043);
            float _10241 = _4104.x;
            float _10246 = _4104.z;
            float2 _10278 = float2((precise::atan2((_283._m29.z * _10241) - (_283._m29.w * _10246), -((_283._m29.w * _10241) + (_283._m29.z * _10246))) * 0.15915493667125701904296875) + 0.5, acos(fast::clamp(_4104.y, -1.0, 1.0)) * 0.3183098733425140380859375);
            float _10210 = _21010 * 5.0;
            int _10213 = min(int(_10210), 4);
            float2 _10299 = (_10278 * float2(_2588[_10213].zw)) - float2(0.5);
            float2 _10301 = floor(_10299);
            float2 _10304 = _10299 - _10301;
            int _10307 = int(_10301.x);
            int _10310 = int(_10301.y);
            int _21069;
            if (_10307 < 0)
            {
                _21069 = _10307 + _2588[_10213].z;
            }
            else
            {
                _21069 = _10307;
            }
            int _21070;
            if (_21069 >= _2588[_10213].z)
            {
                _21070 = _21069 - _2588[_10213].z;
            }
            else
            {
                _21070 = _21069;
            }
            int _10330 = _21070 + 1;
            int _22108 = (_10330 == _2588[_10213].z) ? 0 : _10330;
            int _10345 = min((_10310 + 1), (_2588[_10213].w - 1));
            int _10347 = max(_10310, 0);
            float3 _10400 = float3(_10304.x);
            int _10220 = _10213 + 1;
            float2 _10432 = (_10278 * float2(_2588[_10220].zw)) - float2(0.5);
            float2 _10434 = floor(_10432);
            float2 _10437 = _10432 - _10434;
            int _10440 = int(_10434.x);
            int _10443 = int(_10434.y);
            int _21076;
            if (_10440 < 0)
            {
                _21076 = _10440 + _2588[_10220].z;
            }
            else
            {
                _21076 = _10440;
            }
            int _21077;
            if (_21076 >= _2588[_10220].z)
            {
                _21077 = _21076 - _2588[_10220].z;
            }
            else
            {
                _21077 = _21076;
            }
            int _10463 = _21077 + 1;
            int _22109 = (_10463 == _2588[_10220].z) ? 0 : _10463;
            int _10478 = min((_10443 + 1), (_2588[_10220].w - 1));
            int _10480 = max(_10443, 0);
            float3 _10533 = float3(_10437.x);
            float3 _10235 = mix(mix(mix(_2531.read(uint2((_2588[_10213].xy + int2(_21070, _10347))), 0).xyz, _2531.read(uint2((_2588[_10213].xy + int2(_22108, _10347))), 0).xyz, _10400), mix(_2531.read(uint2((_2588[_10213].xy + int2(_21070, _10345))), 0).xyz, _2531.read(uint2((_2588[_10213].xy + int2(_22108, _10345))), 0).xyz, _10400), float3(_10304.y)), mix(mix(_2531.read(uint2((_2588[_10220].xy + int2(_21077, _10480))), 0).xyz, _2531.read(uint2((_2588[_10220].xy + int2(_22109, _10480))), 0).xyz, _10533), mix(_2531.read(uint2((_2588[_10220].xy + int2(_21077, _10478))), 0).xyz, _2531.read(uint2((_2588[_10220].xy + int2(_22109, _10478))), 0).xyz, _10533), float3(_10437.y)), float3(_10210 - float(_10213))) * _283._m29.y;
            _21120 = fast::max(_21066, float3(0.0)) * _283._m29.y;
            _21108 = _10056.xy;
            _21084 = _10235;
        }
        else
        {
            float4 _10551 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * _21010) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);
            float _10553 = _10551.x;
            float3 _10588 = mix(_283._m9.xyz, _283._m8.xyz, float3((_21020.y * 0.5) + 0.5)) * _283._m8.w;
            _21120 = _10588;
            _21108 = (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_10553 * _10553, exp2((-9.27999973297119140625) * _21048)) * _10553) + _10551.y)) + _10551.zw;
            _21084 = mix(mix(_283._m9.xyz, _283._m8.xyz, float3((reflect(-_3644, _21043).y * 0.5) + 0.5)) * _283._m8.w, _10588, float3(_21010));
        }
        bool _4136;
        if (_3690)
        {
            _4136 = _283._m33.z > 0.5;
        }
        else
        {
            _4136 = _3690;
        }
        float3 _21129;
        if (_4136)
        {
            float3 _21105;
            do
            {
                float _10667 = ((_283._m32.x * (1.0 - smoothstep(_283._m33.x * 0.5, _283._m33.x, abs(dot(_283._m31.xyz, in.m_3037) - _283._m31.w)))) * smoothstep(0.5, 0.89999997615814208984375, dot(_3655, _283._m31.xyz))) * (1.0 - smoothstep(_283._m32.y * 0.5, _283._m32.y, _21010));
                if (_10667 <= 0.0)
                {
                    _21105 = _21084;
                    break;
                }
                float4 _10692 = _283._m30 * float4(in.m_3037 + ((_21020 - (_283._m31.xyz * dot(_21020, _283._m31.xyz))) * _283._m32.w), 1.0);
                float2 _10705 = ((float2(_10692.x, -_10692.y) / float2(_10692.w)) * 0.5) + float2(0.5);
                float _10709 = _283._m32.z * _21010;
                float3 _21103;
                float _21104;
                _21104 = 0.0;
                _21103 = float3(0.0);
                for (int _21102 = 0; _21102 < 12; )
                {
                    float _10716 = float(_21102);
                    float _10724 = _10716 * 2.3999631404876708984375;
                    float2 _10736 = _10705 + (float2(cos(_10724) * _283._m33.y, sin(_10724)) * (sqrt((_10716 + 0.5) * 0.083333335816860198974609375) * _10709));
                    float2 _10741 = fast::min(_10736, float2(1.0) - _10736);
                    float _10747 = smoothstep(0.0, 0.039999999105930328369140625, fast::min(_10741.x, _10741.y));
                    float4 _10755 = _3352.sample(_2533, fast::clamp(_10736, float2(0.0), float2(1.0)), level(0.0));
                    float3 _10757 = _10755.xyz;
                    _21104 += (_10755.w * _10747);
                    _21103 += ((_10757 / (float3(1.0) - fast::min(_10757, float3(0.99500000476837158203125)))) * _10747);
                    _21102++;
                    continue;
                }
                _21105 = mix(_21084, (_21103 * float3(0.083333335816860198974609375)) + (_21084 * (1.0 - (_21104 * 0.083333335816860198974609375))), float3(_10667));
                break;
            } while(false);
            _21129 = _21105;
        }
        else
        {
            _21129 = _21084;
        }
        float3 _4156 = (_3948 * _21108.x) + float3(_21108.y);
        float3 _4161 = (float3(1.0) - _4156) * _3942;
        float3 _4172 = _21158 + (((_4161 * _21120) + (_4156 * _21129)) * _21144);
        float3 _21631;
        if ((_283._m34.x + _283._m34.y) > 0.5)
        {
            float3 _21166;
            if (_283._m34.y > 0.5)
            {
                int _10913 = int(_283._m34.y);
                int _10916 = int(_283._m34.x);
                float3 _21165;
                _21165 = _21120;
                float3 _21957;
                for (int _21164 = 0; _21164 < _10913; _21165 = _21957, _21164++)
                {
                    int _10928 = 8 * (_10916 + _21164);
                    float4 _11137 = as_type<float4>(_1281._m0[_10928 + 3]);
                    float4 _11181 = as_type<float4>(_1281._m0[_10928]);
                    float4 _11187 = as_type<float4>(_1281._m0[_10928 + 1]);
                    float4 _11193 = as_type<float4>(_1281._m0[_10928 + 2]);
                    float3 _11155 = _11181.xyz;
                    float _11159 = _11181.w;
                    float3 _11162 = _11187.xyz;
                    float _11166 = _11187.w;
                    float3 _11169 = _11193.xyz;
                    float _11173 = _11193.w;
                    float3 _11175 = float3(dot(_11155, in.m_3037) + _11159, dot(_11162, in.m_3037) + _11166, dot(_11169, in.m_3037) + _11173);
                    float3 _10937 = _11137.xyz;
                    float _10939 = _11137.w;
                    float _21665;
                    do
                    {
                        float3 _11205 = _10937 - abs(_11175);
                        float _11213 = fast::min(_11205.x, fast::min(_11205.y, _11205.z));
                        if (_11213 <= 0.0)
                        {
                            _21665 = 0.0;
                            break;
                        }
                        if (_10939 <= 0.0)
                        {
                            _21665 = 1.0;
                            break;
                        }
                        float _11225 = fast::min(_11213 / _10939, 1.0);
                        _21665 = (_11225 * _11225) * (3.0 - (2.0 * _11225));
                        break;
                    } while(false);
                    if (_21665 <= 0.0)
                    {
                        _21957 = _21165;
                        continue;
                    }
                    float3 _10948 = as_type<float4>(_1281._m0[_10928 + 4]).xyz;
                    float4 _11246 = as_type<float4>(_1281._m0[_10928 + 5]);
                    int _11252 = int(((device uint*)&_1281._m0[_10928 + 6])[0u]);
                    float _11262 = dot(_11155, _21020);
                    float _11268 = dot(_11162, _21020);
                    float _11274 = dot(_11169, _21020);
                    float3 _11275 = float3(_11262, _11268, _11274);
                    float3 _10968 = (in.m_3037 + (_21020 * _11246.x)) + (_3644 * _11246.y);
                    float3 _10987 = fast::clamp((((float3(dot(_11155, _10968) + _11159, dot(_11162, _10968) + _11166, dot(_11169, _10968) + _11173) + _10937) / fast::max(_10937 * 2.0, float3(9.9999999747524270787835121154785e-07))) * _10948) - float3(0.5), float3(0.0), _10948 - float3(1.0));
                    int3 _10989 = int3(_10948);
                    int3 _10996 = min(int3(_10987), max((_10989 - int3(2)), int3(0)));
                    float3 _11000 = _10987 - float3(_10996);
                    float _11355 = 0.48860299587249755859375 * _11268;
                    float _11358 = 0.48860299587249755859375 * _11274;
                    float _11361 = 0.48860299587249755859375 * _11262;
                    float _11366 = 1.09254801273345947265625 * _11262;
                    float _11369 = _11366 * _11268;
                    float _11375 = (1.09254801273345947265625 * _11268) * _11274;
                    float _11383 = 0.3153919875621795654296875 * (((3.0 * _11274) * _11274) - 1.0);
                    float _11389 = _11366 * _11274;
                    float _11403 = 0.546274006366729736328125 * ((_11262 * _11262) - (_11268 * _11268));
                    int3 _11422 = _10989 - int3(1);
                    int3 _11423 = min(_10996, _11422);
                    int _11428 = _10989.x;
                    int _11432 = _10989.y;
                    int _11440 = _11252 + ((_11423.x + (_11428 * (_11423.y + (_11432 * _11423.z)))) * 4);
                    float3 _11443 = float3(1.0) - _11000;
                    float3 _11461 = (((((float3(_11423) + float3(0.5)) / _10948) * _10937) * 2.0) - _10937) - _11175;
                    float _11471 = dot(_11461 * rsqrt(fast::max(dot(_11461, _11461), 1.0000000133514319600180897396058e-10)), _11275) + 1.0;
                    float _11474 = _11443.x;
                    float _11476 = _11443.y;
                    float _11477 = _11474 * _11476;
                    float _11479 = _11443.z;
                    int _11503 = _11440 + 3;
                    float _11489 = ((_11477 * _11479) * ((0.25 * (_11471 * _11471)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_11503])[1u])).y > 0.5);
                    int _11533 = _11440 + 1;
                    int _11537 = _11440 + 2;
                    float2 _11549 = float2(as_type<half2>(_1281._m0[_11440].y));
                    float2 _11558 = float2(as_type<half2>(_1281._m0[_11533].x));
                    float2 _11567 = float2(as_type<half2>(_1281._m0[_11533].w));
                    float2 _11576 = float2(as_type<half2>(_1281._m0[_11537].z));
                    float3 _11664 = (((((((float3(float2(as_type<half2>(_1281._m0[_11440].x)), _11549.x) * 0.2820949852466583251953125) + (float3(_11549.y, float2(as_type<half2>(_1281._m0[_11440].z))) * _11355)) + (float3(float2(as_type<half2>(_1281._m0[_11440].w)), _11558.x) * _11358)) + (float3(_11558.y, float2(as_type<half2>(_1281._m0[_11533].y))) * _11361)) + (float3(float2(as_type<half2>(_1281._m0[_11533].z)), _11567.x) * _11369)) + (float3(_11567.y, float2(as_type<half2>(_1281._m0[_11537].x))) * _11375)) + (float3(float2(as_type<half2>(_1281._m0[_11537].y)), _11576.x) * _11383)) + (float3(_11576.y, float2(as_type<half2>(_1281._m0[_11537].w))) * _11389);
                    int3 _11692 = min((_10996 + int3(1, 0, 0)), _11422);
                    int _11709 = _11252 + ((_11692.x + (_11428 * (_11692.y + (_11432 * _11692.z)))) * 4);
                    float3 _11730 = (((((float3(_11692) + float3(0.5)) / _10948) * _10937) * 2.0) - _10937) - _11175;
                    float _11740 = dot(_11730 * rsqrt(fast::max(dot(_11730, _11730), 1.0000000133514319600180897396058e-10)), _11275) + 1.0;
                    float _11746 = _11000.x * _11476;
                    int _11772 = _11709 + 3;
                    float _11758 = ((_11746 * _11479) * ((0.25 * (_11740 * _11740)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_11772])[1u])).y > 0.5);
                    int _11802 = _11709 + 1;
                    int _11806 = _11709 + 2;
                    float2 _11818 = float2(as_type<half2>(_1281._m0[_11709].y));
                    float2 _11827 = float2(as_type<half2>(_1281._m0[_11802].x));
                    float2 _11836 = float2(as_type<half2>(_1281._m0[_11802].w));
                    float2 _11845 = float2(as_type<half2>(_1281._m0[_11806].z));
                    float3 _11933 = (((((((float3(float2(as_type<half2>(_1281._m0[_11709].x)), _11818.x) * 0.2820949852466583251953125) + (float3(_11818.y, float2(as_type<half2>(_1281._m0[_11709].z))) * _11355)) + (float3(float2(as_type<half2>(_1281._m0[_11709].w)), _11827.x) * _11358)) + (float3(_11827.y, float2(as_type<half2>(_1281._m0[_11802].y))) * _11361)) + (float3(float2(as_type<half2>(_1281._m0[_11802].z)), _11836.x) * _11369)) + (float3(_11836.y, float2(as_type<half2>(_1281._m0[_11806].x))) * _11375)) + (float3(float2(as_type<half2>(_1281._m0[_11806].y)), _11845.x) * _11383)) + (float3(_11845.y, float2(as_type<half2>(_1281._m0[_11806].w))) * _11389);
                    int3 _11961 = min((_10996 + int3(0, 1, 0)), _11422);
                    int _11978 = _11252 + ((_11961.x + (_11428 * (_11961.y + (_11432 * _11961.z)))) * 4);
                    float3 _11999 = (((((float3(_11961) + float3(0.5)) / _10948) * _10937) * 2.0) - _10937) - _11175;
                    float _12009 = dot(_11999 * rsqrt(fast::max(dot(_11999, _11999), 1.0000000133514319600180897396058e-10)), _11275) + 1.0;
                    float _12015 = _11474 * _11000.y;
                    int _12041 = _11978 + 3;
                    float _12027 = ((_12015 * _11479) * ((0.25 * (_12009 * _12009)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_12041])[1u])).y > 0.5);
                    int _12071 = _11978 + 1;
                    int _12075 = _11978 + 2;
                    float2 _12087 = float2(as_type<half2>(_1281._m0[_11978].y));
                    float2 _12096 = float2(as_type<half2>(_1281._m0[_12071].x));
                    float2 _12105 = float2(as_type<half2>(_1281._m0[_12071].w));
                    float2 _12114 = float2(as_type<half2>(_1281._m0[_12075].z));
                    float3 _12202 = (((((((float3(float2(as_type<half2>(_1281._m0[_11978].x)), _12087.x) * 0.2820949852466583251953125) + (float3(_12087.y, float2(as_type<half2>(_1281._m0[_11978].z))) * _11355)) + (float3(float2(as_type<half2>(_1281._m0[_11978].w)), _12096.x) * _11358)) + (float3(_12096.y, float2(as_type<half2>(_1281._m0[_12071].y))) * _11361)) + (float3(float2(as_type<half2>(_1281._m0[_12071].z)), _12105.x) * _11369)) + (float3(_12105.y, float2(as_type<half2>(_1281._m0[_12075].x))) * _11375)) + (float3(float2(as_type<half2>(_1281._m0[_12075].y)), _12114.x) * _11383)) + (float3(_12114.y, float2(as_type<half2>(_1281._m0[_12075].w))) * _11389);
                    int3 _12230 = min((_10996 + int3(1, 1, 0)), _11422);
                    int _12247 = _11252 + ((_12230.x + (_11428 * (_12230.y + (_11432 * _12230.z)))) * 4);
                    float3 _12268 = (((((float3(_12230) + float3(0.5)) / _10948) * _10937) * 2.0) - _10937) - _11175;
                    float _12278 = dot(_12268 * rsqrt(fast::max(dot(_12268, _12268), 1.0000000133514319600180897396058e-10)), _11275) + 1.0;
                    float _12284 = _11000.x * _11000.y;
                    int _12310 = _12247 + 3;
                    float _12296 = ((_12284 * _11479) * ((0.25 * (_12278 * _12278)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_12310])[1u])).y > 0.5);
                    int _12340 = _12247 + 1;
                    int _12344 = _12247 + 2;
                    float2 _12356 = float2(as_type<half2>(_1281._m0[_12247].y));
                    float2 _12365 = float2(as_type<half2>(_1281._m0[_12340].x));
                    float2 _12374 = float2(as_type<half2>(_1281._m0[_12340].w));
                    float2 _12383 = float2(as_type<half2>(_1281._m0[_12344].z));
                    float3 _12471 = (((((((float3(float2(as_type<half2>(_1281._m0[_12247].x)), _12356.x) * 0.2820949852466583251953125) + (float3(_12356.y, float2(as_type<half2>(_1281._m0[_12247].z))) * _11355)) + (float3(float2(as_type<half2>(_1281._m0[_12247].w)), _12365.x) * _11358)) + (float3(_12365.y, float2(as_type<half2>(_1281._m0[_12340].y))) * _11361)) + (float3(float2(as_type<half2>(_1281._m0[_12340].z)), _12374.x) * _11369)) + (float3(_12374.y, float2(as_type<half2>(_1281._m0[_12344].x))) * _11375)) + (float3(float2(as_type<half2>(_1281._m0[_12344].y)), _12383.x) * _11383)) + (float3(_12383.y, float2(as_type<half2>(_1281._m0[_12344].w))) * _11389);
                    int3 _12499 = min((_10996 + int3(0, 0, 1)), _11422);
                    int _12516 = _11252 + ((_12499.x + (_11428 * (_12499.y + (_11432 * _12499.z)))) * 4);
                    float3 _12537 = (((((float3(_12499) + float3(0.5)) / _10948) * _10937) * 2.0) - _10937) - _11175;
                    float _12547 = dot(_12537 * rsqrt(fast::max(dot(_12537, _12537), 1.0000000133514319600180897396058e-10)), _11275) + 1.0;
                    int _12579 = _12516 + 3;
                    float _12565 = ((_11477 * _11000.z) * ((0.25 * (_12547 * _12547)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_12579])[1u])).y > 0.5);
                    int _12609 = _12516 + 1;
                    int _12613 = _12516 + 2;
                    float2 _12625 = float2(as_type<half2>(_1281._m0[_12516].y));
                    float2 _12634 = float2(as_type<half2>(_1281._m0[_12609].x));
                    float2 _12643 = float2(as_type<half2>(_1281._m0[_12609].w));
                    float2 _12652 = float2(as_type<half2>(_1281._m0[_12613].z));
                    float3 _12740 = (((((((float3(float2(as_type<half2>(_1281._m0[_12516].x)), _12625.x) * 0.2820949852466583251953125) + (float3(_12625.y, float2(as_type<half2>(_1281._m0[_12516].z))) * _11355)) + (float3(float2(as_type<half2>(_1281._m0[_12516].w)), _12634.x) * _11358)) + (float3(_12634.y, float2(as_type<half2>(_1281._m0[_12609].y))) * _11361)) + (float3(float2(as_type<half2>(_1281._m0[_12609].z)), _12643.x) * _11369)) + (float3(_12643.y, float2(as_type<half2>(_1281._m0[_12613].x))) * _11375)) + (float3(float2(as_type<half2>(_1281._m0[_12613].y)), _12652.x) * _11383)) + (float3(_12652.y, float2(as_type<half2>(_1281._m0[_12613].w))) * _11389);
                    float4 _11067 = (((float4((_11664 + (float3(float2(as_type<half2>(_1281._m0[_11503].x)), float2(as_type<half2>(_1281._m0[_11503].y)).x) * _11403)) * _11489, _11489) + float4((_11933 + (float3(float2(as_type<half2>(_1281._m0[_11772].x)), float2(as_type<half2>(_1281._m0[_11772].y)).x) * _11403)) * _11758, _11758)) + float4((_12202 + (float3(float2(as_type<half2>(_1281._m0[_12041].x)), float2(as_type<half2>(_1281._m0[_12041].y)).x) * _11403)) * _12027, _12027)) + float4((_12471 + (float3(float2(as_type<half2>(_1281._m0[_12310].x)), float2(as_type<half2>(_1281._m0[_12310].y)).x) * _11403)) * _12296, _12296)) + float4((_12740 + (float3(float2(as_type<half2>(_1281._m0[_12579].x)), float2(as_type<half2>(_1281._m0[_12579].y)).x) * _11403)) * _12565, _12565);
                    int3 _12768 = min((_10996 + int3(1, 0, 1)), _11422);
                    int _12785 = _11252 + ((_12768.x + (_11428 * (_12768.y + (_11432 * _12768.z)))) * 4);
                    float3 _12806 = (((((float3(_12768) + float3(0.5)) / _10948) * _10937) * 2.0) - _10937) - _11175;
                    float _12816 = dot(_12806 * rsqrt(fast::max(dot(_12806, _12806), 1.0000000133514319600180897396058e-10)), _11275) + 1.0;
                    int _12848 = _12785 + 3;
                    float _12834 = ((_11746 * _11000.z) * ((0.25 * (_12816 * _12816)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_12848])[1u])).y > 0.5);
                    int _12878 = _12785 + 1;
                    int _12882 = _12785 + 2;
                    float2 _12894 = float2(as_type<half2>(_1281._m0[_12785].y));
                    float2 _12903 = float2(as_type<half2>(_1281._m0[_12878].x));
                    float2 _12912 = float2(as_type<half2>(_1281._m0[_12878].w));
                    float2 _12921 = float2(as_type<half2>(_1281._m0[_12882].z));
                    float3 _13009 = (((((((float3(float2(as_type<half2>(_1281._m0[_12785].x)), _12894.x) * 0.2820949852466583251953125) + (float3(_12894.y, float2(as_type<half2>(_1281._m0[_12785].z))) * _11355)) + (float3(float2(as_type<half2>(_1281._m0[_12785].w)), _12903.x) * _11358)) + (float3(_12903.y, float2(as_type<half2>(_1281._m0[_12878].y))) * _11361)) + (float3(float2(as_type<half2>(_1281._m0[_12878].z)), _12912.x) * _11369)) + (float3(_12912.y, float2(as_type<half2>(_1281._m0[_12882].x))) * _11375)) + (float3(float2(as_type<half2>(_1281._m0[_12882].y)), _12921.x) * _11383)) + (float3(_12921.y, float2(as_type<half2>(_1281._m0[_12882].w))) * _11389);
                    int3 _13037 = min((_10996 + int3(0, 1, 1)), _11422);
                    int _13054 = _11252 + ((_13037.x + (_11428 * (_13037.y + (_11432 * _13037.z)))) * 4);
                    float3 _13075 = (((((float3(_13037) + float3(0.5)) / _10948) * _10937) * 2.0) - _10937) - _11175;
                    float _13085 = dot(_13075 * rsqrt(fast::max(dot(_13075, _13075), 1.0000000133514319600180897396058e-10)), _11275) + 1.0;
                    int _13117 = _13054 + 3;
                    float _13103 = ((_12015 * _11000.z) * ((0.25 * (_13085 * _13085)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_13117])[1u])).y > 0.5);
                    int _13147 = _13054 + 1;
                    int _13151 = _13054 + 2;
                    float2 _13163 = float2(as_type<half2>(_1281._m0[_13054].y));
                    float2 _13172 = float2(as_type<half2>(_1281._m0[_13147].x));
                    float2 _13181 = float2(as_type<half2>(_1281._m0[_13147].w));
                    float2 _13190 = float2(as_type<half2>(_1281._m0[_13151].z));
                    float3 _13278 = (((((((float3(float2(as_type<half2>(_1281._m0[_13054].x)), _13163.x) * 0.2820949852466583251953125) + (float3(_13163.y, float2(as_type<half2>(_1281._m0[_13054].z))) * _11355)) + (float3(float2(as_type<half2>(_1281._m0[_13054].w)), _13172.x) * _11358)) + (float3(_13172.y, float2(as_type<half2>(_1281._m0[_13147].y))) * _11361)) + (float3(float2(as_type<half2>(_1281._m0[_13147].z)), _13181.x) * _11369)) + (float3(_13181.y, float2(as_type<half2>(_1281._m0[_13151].x))) * _11375)) + (float3(float2(as_type<half2>(_1281._m0[_13151].y)), _13190.x) * _11383)) + (float3(_13190.y, float2(as_type<half2>(_1281._m0[_13151].w))) * _11389);
                    int3 _13306 = min((_10996 + int3(1)), _11422);
                    int _13323 = _11252 + ((_13306.x + (_11428 * (_13306.y + (_11432 * _13306.z)))) * 4);
                    float3 _13344 = (((((float3(_13306) + float3(0.5)) / _10948) * _10937) * 2.0) - _10937) - _11175;
                    float _13354 = dot(_13344 * rsqrt(fast::max(dot(_13344, _13344), 1.0000000133514319600180897396058e-10)), _11275) + 1.0;
                    int _13386 = _13323 + 3;
                    float _13372 = ((_12284 * _11000.z) * ((0.25 * (_13354 * _13354)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_13386])[1u])).y > 0.5);
                    int _13416 = _13323 + 1;
                    int _13420 = _13323 + 2;
                    float2 _13432 = float2(as_type<half2>(_1281._m0[_13323].y));
                    float2 _13441 = float2(as_type<half2>(_1281._m0[_13416].x));
                    float2 _13450 = float2(as_type<half2>(_1281._m0[_13416].w));
                    float2 _13459 = float2(as_type<half2>(_1281._m0[_13420].z));
                    float3 _13547 = (((((((float3(float2(as_type<half2>(_1281._m0[_13323].x)), _13432.x) * 0.2820949852466583251953125) + (float3(_13432.y, float2(as_type<half2>(_1281._m0[_13323].z))) * _11355)) + (float3(float2(as_type<half2>(_1281._m0[_13323].w)), _13441.x) * _11358)) + (float3(_13441.y, float2(as_type<half2>(_1281._m0[_13416].y))) * _11361)) + (float3(float2(as_type<half2>(_1281._m0[_13416].z)), _13450.x) * _11369)) + (float3(_13450.y, float2(as_type<half2>(_1281._m0[_13420].x))) * _11375)) + (float3(float2(as_type<half2>(_1281._m0[_13420].y)), _13459.x) * _11383)) + (float3(_13459.y, float2(as_type<half2>(_1281._m0[_13420].w))) * _11389);
                    float4 _11106 = ((_11067 + float4((_13009 + (float3(float2(as_type<half2>(_1281._m0[_12848].x)), float2(as_type<half2>(_1281._m0[_12848].y)).x) * _11403)) * _12834, _12834)) + float4((_13278 + (float3(float2(as_type<half2>(_1281._m0[_13117].x)), float2(as_type<half2>(_1281._m0[_13117].y)).x) * _11403)) * _13103, _13103)) + float4((_13547 + (float3(float2(as_type<half2>(_1281._m0[_13386].x)), float2(as_type<half2>(_1281._m0[_13386].y)).x) * _11403)) * _13372, _13372);
                    float _11110 = _11106.w;
                    float3 _21958;
                    if (_11110 > 9.9999997473787516355514526367188e-06)
                    {
                        _21958 = mix(_21165, (fast::max(_11106.xyz, float3(0.0)) / float3(_11110)) * _11246.z, float3(_21665));
                    }
                    else
                    {
                        _21958 = _21165;
                    }
                    _21957 = _21958;
                }
                _21166 = _21165;
            }
            else
            {
                _21166 = _21120;
            }
            float3 _21394;
            if (_283._m34.x > 0.5)
            {
                float3 _21203;
                if (_4087)
                {
                    float3 _4217 = reflect(-_3644, _21043);
                    float _13612 = _4217.x;
                    float _13617 = _4217.z;
                    float2 _13649 = float2((precise::atan2((_283._m29.z * _13612) - (_283._m29.w * _13617), -((_283._m29.w * _13612) + (_283._m29.z * _13617))) * 0.15915493667125701904296875) + 0.5, acos(fast::clamp(_4217.y, -1.0, 1.0)) * 0.3183098733425140380859375);
                    float _13581 = _21010 * 5.0;
                    int _13584 = min(int(_13581), 4);
                    float2 _13670 = (_13649 * float2(_2588[_13584].zw)) - float2(0.5);
                    float2 _13672 = floor(_13670);
                    float2 _13675 = _13670 - _13672;
                    int _13678 = int(_13672.x);
                    int _13681 = int(_13672.y);
                    int _21189;
                    if (_13678 < 0)
                    {
                        _21189 = _13678 + _2588[_13584].z;
                    }
                    else
                    {
                        _21189 = _13678;
                    }
                    int _21190;
                    if (_21189 >= _2588[_13584].z)
                    {
                        _21190 = _21189 - _2588[_13584].z;
                    }
                    else
                    {
                        _21190 = _21189;
                    }
                    int _13701 = _21190 + 1;
                    int _22110 = (_13701 == _2588[_13584].z) ? 0 : _13701;
                    int _13716 = min((_13681 + 1), (_2588[_13584].w - 1));
                    int _13718 = max(_13681, 0);
                    float3 _13771 = float3(_13675.x);
                    int _13591 = _13584 + 1;
                    float2 _13803 = (_13649 * float2(_2588[_13591].zw)) - float2(0.5);
                    float2 _13805 = floor(_13803);
                    float2 _13808 = _13803 - _13805;
                    int _13811 = int(_13805.x);
                    int _13814 = int(_13805.y);
                    int _21196;
                    if (_13811 < 0)
                    {
                        _21196 = _13811 + _2588[_13591].z;
                    }
                    else
                    {
                        _21196 = _13811;
                    }
                    int _21197;
                    if (_21196 >= _2588[_13591].z)
                    {
                        _21197 = _21196 - _2588[_13591].z;
                    }
                    else
                    {
                        _21197 = _21196;
                    }
                    int _13834 = _21197 + 1;
                    int _22111 = (_13834 == _2588[_13591].z) ? 0 : _13834;
                    int _13849 = min((_13814 + 1), (_2588[_13591].w - 1));
                    int _13851 = max(_13814, 0);
                    float3 _13904 = float3(_13808.x);
                    float3 _13606 = mix(mix(mix(_2531.read(uint2((_2588[_13584].xy + int2(_21190, _13718))), 0).xyz, _2531.read(uint2((_2588[_13584].xy + int2(_22110, _13718))), 0).xyz, _13771), mix(_2531.read(uint2((_2588[_13584].xy + int2(_21190, _13716))), 0).xyz, _2531.read(uint2((_2588[_13584].xy + int2(_22110, _13716))), 0).xyz, _13771), float3(_13675.y)), mix(mix(_2531.read(uint2((_2588[_13591].xy + int2(_21197, _13851))), 0).xyz, _2531.read(uint2((_2588[_13591].xy + int2(_22111, _13851))), 0).xyz, _13904), mix(_2531.read(uint2((_2588[_13591].xy + int2(_21197, _13849))), 0).xyz, _2531.read(uint2((_2588[_13591].xy + int2(_22111, _13849))), 0).xyz, _13904), float3(_13808.y)), float3(_13581 - float(_13584))) * _283._m29.y;
                    _21203 = _13606;
                }
                else
                {
                    _21203 = mix(mix(_283._m9.xyz, _283._m8.xyz, float3((reflect(-_3644, _21043).y * 0.5) + 0.5)) * _283._m8.w, _21120, float3(_21010));
                }
                float3 _4237 = reflect(-_3644, _21043);
                int _13970 = int(_283._m34.x);
                float _21219;
                float3 _21285;
                _21285 = float3(0.0);
                _21219 = 0.0;
                float _21971;
                float3 _21972;
                for (int _21218 = 0; _21218 < _13970; _21285 = _21972, _21219 = _21971, _21218++)
                {
                    if (_21219 > 0.999000012874603271484375)
                    {
                        break;
                    }
                    int _13982 = _21218 * 8;
                    float4 _14097 = as_type<float4>(_1281._m0[_13982]);
                    float4 _14103 = as_type<float4>(_1281._m0[_13982 + 1]);
                    float4 _14109 = as_type<float4>(_1281._m0[_13982 + 2]);
                    float3 _14071 = _14097.xyz;
                    float3 _14078 = _14103.xyz;
                    float3 _14085 = _14109.xyz;
                    float3 _14091 = float3(dot(_14071, in.m_3037) + _14097.w, dot(_14078, in.m_3037) + _14103.w, dot(_14085, in.m_3037) + _14109.w);
                    float4 _14115 = as_type<float4>(_1281._m0[_13982 + 3]);
                    float _13993 = _14115.w;
                    float _21220;
                    do
                    {
                        float3 _14127 = _14115.xyz - abs(_14091);
                        float _14135 = fast::min(_14127.x, fast::min(_14127.y, _14127.z));
                        if (_14135 <= 0.0)
                        {
                            _21220 = 0.0;
                            break;
                        }
                        if (_13993 <= 0.0)
                        {
                            _21220 = 1.0;
                            break;
                        }
                        float _14147 = fast::min(_14135 / _13993, 1.0);
                        _21220 = (_14147 * _14147) * (3.0 - (2.0 * _14147));
                        break;
                    } while(false);
                    if (_21220 <= 0.0)
                    {
                        _21972 = _21285;
                        _21971 = _21219;
                        continue;
                    }
                    float4 _14162 = as_type<float4>(_1281._m0[_13982 + 4]);
                    float4 _14168 = as_type<float4>(_1281._m0[_13982 + 5]);
                    float3 _14191 = float3(dot(_14071, _4237), dot(_14078, _4237), dot(_14085, _4237));
                    float3 _21222;
                    if (_14162.w > 0.5)
                    {
                        float3 _14015 = _14162.xyz;
                        float3 _14221 = -_14015;
                        float3 _14223 = fast::clamp(_14091, _14221, _14015);
                        float3 _14233 = step(float3(9.9999999747524270787835121154785e-07), abs(_14191));
                        float3 _14243 = mix(float3(1000000015047466219876688855040.0), (mix(_14221, _14015, step(float3(0.0), _14191)) - _14223) / mix(float3(9.9999999747524270787835121154785e-07), _14191, _14233), _14233);
                        float3 _14259 = (_14223 + (_14191 * fast::max(fast::min(_14243.x, fast::min(_14243.y, _14243.z)), 0.0))) - _14168.xyz;
                        float3 _21221;
                        if (dot(_14259, _14259) > 9.9999999600419720025001879548654e-13)
                        {
                            _21221 = fast::normalize(_14259);
                        }
                        else
                        {
                            _21221 = _14191;
                        }
                        _21222 = _21221;
                    }
                    else
                    {
                        _21222 = _14191;
                    }
                    int _14276 = int(((device uint*)&_1281._m0[_13982 + 6])[0u]);
                    float2 _14326 = float2((precise::atan2(_21222.x, -_21222.z) * 0.15915493667125701904296875) + 0.5, acos(fast::clamp(_21222.y, -1.0, 1.0)) * 0.3183098733425140380859375);
                    float _14292 = _21010 * 5.0;
                    int _14295 = min(int(_14292), 4);
                    int _14366 = _14276 + _1353[_14295].x;
                    float2 _14373 = (_14326 * float2(_1353[_14295].yz)) - float2(0.5);
                    float2 _14375 = floor(_14373);
                    float2 _14378 = _14373 - _14375;
                    int _14381 = int(_14375.x);
                    int _14384 = int(_14375.y);
                    int _21223;
                    if (_14381 < 0)
                    {
                        _21223 = _14381 + _1353[_14295].y;
                    }
                    else
                    {
                        _21223 = _14381;
                    }
                    int _21224;
                    if (_21223 >= _1353[_14295].y)
                    {
                        _21224 = _21223 - _1353[_14295].y;
                    }
                    else
                    {
                        _21224 = _21223;
                    }
                    int _14404 = _21224 + 1;
                    int _22112 = (_14404 == _1353[_14295].y) ? 0 : _14404;
                    int _14472 = _14366 + (max(_14384, 0) * _1353[_14295].y);
                    int _14474 = _14472 + _21224;
                    int _14476 = _14474 >> 1;
                    uint2 _21230;
                    if ((_14474 & 1) == 0)
                    {
                        _21230 = _1281._m0[_14476].xy;
                    }
                    else
                    {
                        _21230 = _1281._m0[_14476].zw;
                    }
                    int _14512 = _14472 + _22112;
                    int _14514 = _14512 >> 1;
                    uint2 _21232;
                    if ((_14512 & 1) == 0)
                    {
                        _21232 = _1281._m0[_14514].xy;
                    }
                    else
                    {
                        _21232 = _1281._m0[_14514].zw;
                    }
                    int _14548 = _14366 + (min((_14384 + 1), (_1353[_14295].z - 1)) * _1353[_14295].y);
                    int _14550 = _14548 + _21224;
                    int _14552 = _14550 >> 1;
                    uint2 _21235;
                    if ((_14550 & 1) == 0)
                    {
                        _21235 = _1281._m0[_14552].xy;
                    }
                    else
                    {
                        _21235 = _1281._m0[_14552].zw;
                    }
                    int _14588 = _14548 + _22112;
                    int _14590 = _14588 >> 1;
                    uint2 _21236;
                    if ((_14588 & 1) == 0)
                    {
                        _21236 = _1281._m0[_14590].xy;
                    }
                    else
                    {
                        _21236 = _1281._m0[_14590].zw;
                    }
                    float3 _14450 = float3(_14378.x);
                    int _14301 = _14295 + 1;
                    int _14653 = _14276 + _1353[_14301].x;
                    float2 _14660 = (_14326 * float2(_1353[_14301].yz)) - float2(0.5);
                    float2 _14662 = floor(_14660);
                    float2 _14665 = _14660 - _14662;
                    int _14668 = int(_14662.x);
                    int _14671 = int(_14662.y);
                    int _21237;
                    if (_14668 < 0)
                    {
                        _21237 = _14668 + _1353[_14301].y;
                    }
                    else
                    {
                        _21237 = _14668;
                    }
                    int _21238;
                    if (_21237 >= _1353[_14301].y)
                    {
                        _21238 = _21237 - _1353[_14301].y;
                    }
                    else
                    {
                        _21238 = _21237;
                    }
                    int _14691 = _21238 + 1;
                    int _22113 = (_14691 == _1353[_14301].y) ? 0 : _14691;
                    int _14759 = _14653 + (max(_14671, 0) * _1353[_14301].y);
                    int _14761 = _14759 + _21238;
                    int _14763 = _14761 >> 1;
                    uint2 _21244;
                    if ((_14761 & 1) == 0)
                    {
                        _21244 = _1281._m0[_14763].xy;
                    }
                    else
                    {
                        _21244 = _1281._m0[_14763].zw;
                    }
                    int _14799 = _14759 + _22113;
                    int _14801 = _14799 >> 1;
                    uint2 _21246;
                    if ((_14799 & 1) == 0)
                    {
                        _21246 = _1281._m0[_14801].xy;
                    }
                    else
                    {
                        _21246 = _1281._m0[_14801].zw;
                    }
                    int _14835 = _14653 + (min((_14671 + 1), (_1353[_14301].z - 1)) * _1353[_14301].y);
                    int _14837 = _14835 + _21238;
                    int _14839 = _14837 >> 1;
                    uint2 _21249;
                    if ((_14837 & 1) == 0)
                    {
                        _21249 = _1281._m0[_14839].xy;
                    }
                    else
                    {
                        _21249 = _1281._m0[_14839].zw;
                    }
                    int _14875 = _14835 + _22113;
                    int _14877 = _14875 >> 1;
                    uint2 _21250;
                    if ((_14875 & 1) == 0)
                    {
                        _21250 = _1281._m0[_14877].xy;
                    }
                    else
                    {
                        _21250 = _1281._m0[_14877].zw;
                    }
                    float3 _14737 = float3(_14665.x);
                    float3 _14031 = mix(mix(mix(float3(float2(as_type<half2>(_21230.x)), float2(as_type<half2>(_21230.y)).x), float3(float2(as_type<half2>(_21232.x)), float2(as_type<half2>(_21232.y)).x), _14450), mix(float3(float2(as_type<half2>(_21235.x)), float2(as_type<half2>(_21235.y)).x), float3(float2(as_type<half2>(_21236.x)), float2(as_type<half2>(_21236.y)).x), _14450), float3(_14378.y)), mix(mix(float3(float2(as_type<half2>(_21244.x)), float2(as_type<half2>(_21244.y)).x), float3(float2(as_type<half2>(_21246.x)), float2(as_type<half2>(_21246.y)).x), _14737), mix(float3(float2(as_type<half2>(_21249.x)), float2(as_type<half2>(_21249.y)).x), float3(float2(as_type<half2>(_21250.x)), float2(as_type<half2>(_21250.y)).x), _14737), float3(_14665.y)), float3(_14292 - float(_14295))) * _14168.w;
                    float _14035 = _21220 * (1.0 - _21219);
                    _21972 = _21285 + (_14031 * _14035);
                    _21971 = _21219 + _14035;
                }
                float3 _14053 = _21285 + (_21203 * (1.0 - _21219));
                bool _4254;
                if (_3690)
                {
                    _4254 = _283._m33.z > 0.5;
                }
                else
                {
                    _4254 = _3690;
                }
                float3 _21395;
                if (_4254)
                {
                    float3 _21361;
                    do
                    {
                        float _14962 = ((_283._m32.x * (1.0 - smoothstep(_283._m33.x * 0.5, _283._m33.x, abs(dot(_283._m31.xyz, in.m_3037) - _283._m31.w)))) * smoothstep(0.5, 0.89999997615814208984375, dot(_3655, _283._m31.xyz))) * (1.0 - smoothstep(_283._m32.y * 0.5, _283._m32.y, _21010));
                        if (_14962 <= 0.0)
                        {
                            _21361 = _14053;
                            break;
                        }
                        float4 _14987 = _283._m30 * float4(in.m_3037 + ((_21020 - (_283._m31.xyz * dot(_21020, _283._m31.xyz))) * _283._m32.w), 1.0);
                        float2 _15000 = ((float2(_14987.x, -_14987.y) / float2(_14987.w)) * 0.5) + float2(0.5);
                        float _15004 = _283._m32.z * _21010;
                        float3 _21359;
                        float _21360;
                        _21360 = 0.0;
                        _21359 = float3(0.0);
                        for (int _21358 = 0; _21358 < 12; )
                        {
                            float _15011 = float(_21358);
                            float _15019 = _15011 * 2.3999631404876708984375;
                            float2 _15031 = _15000 + (float2(cos(_15019) * _283._m33.y, sin(_15019)) * (sqrt((_15011 + 0.5) * 0.083333335816860198974609375) * _15004));
                            float2 _15036 = fast::min(_15031, float2(1.0) - _15031);
                            float _15042 = smoothstep(0.0, 0.039999999105930328369140625, fast::min(_15036.x, _15036.y));
                            float4 _15050 = _3352.sample(_2533, fast::clamp(_15031, float2(0.0), float2(1.0)), level(0.0));
                            float3 _15052 = _15050.xyz;
                            _21360 += (_15050.w * _15042);
                            _21359 += ((_15052 / (float3(1.0) - fast::min(_15052, float3(0.99500000476837158203125)))) * _15042);
                            _21358++;
                            continue;
                        }
                        _21361 = mix(_14053, (_21359 * float3(0.083333335816860198974609375)) + (_14053 * (1.0 - (_21360 * 0.083333335816860198974609375))), float3(_14962));
                        break;
                    } while(false);
                    _21395 = _21361;
                }
                else
                {
                    _21395 = _14053;
                }
                _21394 = _21395;
            }
            else
            {
                _21394 = _21129;
            }
            _21631 = _4172 + (((_4161 * (_21166 - _21120)) + (_4156 * (_21394 - _21129))) * _21144);
        }
        else
        {
            _21631 = _4172;
        }
        float3 _21701;
        if (_283._m13.w > 0.5)
        {
            float2 _15116 = fast::clamp(floor(gl_FragCoord.xy * _283._m12.xy), float2(0.0), _283._m13.xy - float2(1.0));
            uint _15144 = uint((((fast::clamp(floor((log2(fast::max(dot(_283._m11.xyz, in.m_3037) + _283._m11.w, 9.9999999747524270787835121154785e-07)) * _283._m12.z) + _283._m12.w), 0.0, _283._m13.z - 1.0) * _283._m13.y) + _15116.y) * _283._m13.x) + _15116.x);
            uint _15146 = _15144 >> uint(2);
            uint _15148 = _15144 & 3u;
            uint _15152 = _3167._m0[_15146][_15148] & 65535u;
            uint _15154 = _3167._m0[_15146][_15148] >> uint(16);
            float3 _21630;
            _21630 = _21631;
            float3 _4383;
            spvUnsafeArray<float2, 3> _15562;
            spvUnsafeArray<float2, 3> _15563;
            spvUnsafeArray<float2, 3> _15775;
            spvUnsafeArray<float2, 3> _15776;
            for (uint _21496 = _15152; _21496 < (_15152 + _15154); _21630 = _4383, _21496++)
            {
                uint _15160 = _21496 / 3u;
                uint _15173 = (_3188._m0[_15160 >> uint(2)][_15160 & 3u] >> ((_21496 - (_15160 * 3u)) * 10u)) & 1023u;
                float3 _15190 = _3030._m0[_15173].xyz - in.m_3037;
                float _15193 = dot(_15190, _15190);
                float _15197 = _15193 * _3030._m0[_15173].w;
                float _15202 = fast::clamp(1.0 - (_15197 * _15197), 0.0, 1.0);
                float3 _15207 = _15190 * rsqrt(fast::max(_15193, 9.9999999392252902907785028219223e-09));
                float _15225 = fast::clamp((dot(-_15207, _3073._m0[_15173].xyz) * _3065._m0[_15173].w) + _3073._m0[_15173].w, 0.0, 1.0);
                float3 _15238 = _3065._m0[_15173].xyz * ((((_15202 * _15202) * _15225) * _15225) / fast::max(_15193, 9.9999997473787516355514526367188e-05));
                float3 _21628;
                if (_3660)
                {
                    float _21523;
                    do
                    {
                        uint _15274 = uint(_283._m21.z);
                        if (_15173 < _15274)
                        {
                            float _15296 = _283._m26[_15173].z * fast::max((_283._m15[_15173] * float4(in.m_3037, 1.0)).w, 0.0);
                            float4 _15320 = _283._m15[_15173] * float4((in.m_3037 + (_3655 * (_15296 * _283._m25.x))) + (_15207 * (_15296 * _283._m25.y)), 1.0);
                            float _15322 = _15320.w;
                            if (_15322 <= 0.0)
                            {
                                _21523 = 1.0;
                                break;
                            }
                            float3 _15331 = _15320.xyz / float3(_15322);
                            float _15333 = _15331.x;
                            bool _15334 = _15333 < 0.0;
                            bool _15341;
                            if (!_15334)
                            {
                                _15341 = _15333 > 1.0;
                            }
                            else
                            {
                                _15341 = _15334;
                            }
                            bool _15348;
                            if (!_15341)
                            {
                                _15348 = _15331.y < 0.0;
                            }
                            else
                            {
                                _15348 = _15341;
                            }
                            bool _15355;
                            if (!_15348)
                            {
                                _15355 = _15331.y > 1.0;
                            }
                            else
                            {
                                _15355 = _15348;
                            }
                            bool _15362;
                            if (!_15355)
                            {
                                _15362 = _15331.z > 1.0;
                            }
                            else
                            {
                                _15362 = _15355;
                            }
                            if (_15362)
                            {
                                _21523 = 1.0;
                                break;
                            }
                            float _15368 = _15331.z;
                            float2 _15534 = _283._m22.xy * 0.5;
                            float2 _15539 = _283._m26[_15173].xy + (_15331.xy * _283._m23.zw);
                            float4 _15552 = float4(_283._m26[_15173].xy + _15534, (_283._m26[_15173].xy + _283._m23.zw) - _15534);
                            float _21522;
                            do
                            {
                                int _15578 = int(_283._m22.z);
                                if (_15578 <= 0)
                                {
                                    float2 _15588 = fast::clamp(_15539, _15552.xy, _15552.zw);
                                    _21522 = spvDepthCast(_303).sample_compare(_303Smplr, float3(_15588, _15368).xy, _15368);
                                    break;
                                }
                                float2 _15601 = (_15539 / _283._m22.xy) + float2(0.5);
                                float2 _15602 = floor(_15601);
                                float2 _15607 = _15601 - _15602;
                                float2 _15610 = _15602 - float2(0.5);
                                bool _15614 = _15578 == 1;
                                if (_15614)
                                {
                                    float2 _15617 = _15607 * 2.0;
                                    _15562[0] = float2(3.0) - _15617;
                                    _15562[1] = float2(1.0) + _15617;
                                    _15563[0] = ((float2(2.0) - _15607) / _15562[0]) - float2(1.0);
                                    _15563[1] = (_15607 / _15562[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _15644 = _15607 * 3.0;
                                    _15562[0] = float2(4.0) - _15644;
                                    _15562[1] = float2(7.0);
                                    _15562[2] = float2(1.0) + _15644;
                                    _15563[0] = ((float2(3.0) - (_15607 * 2.0)) / _15562[0]) - float2(2.0);
                                    _15563[1] = (float2(3.0) + _15607) / _15562[1];
                                    _15563[2] = (_15607 / _15562[2]) + float2(2.0);
                                }
                                int _22115 = _15614 ? 2 : 3;
                                int _21512;
                                float _21515;
                                _21515 = 0.0;
                                _21512 = 0;
                                float _21521;
                                for (; _21512 < _22115; _21515 = _21521, _21512++)
                                {
                                    _21521 = _21515;
                                    for (int _21518 = 0; _21518 < _22115; )
                                    {
                                        _21521 += ((_15562[_21518].x * _15562[_21512].y) * spvDepthCast(_303).sample_compare(_303Smplr, float3(fast::clamp(_283._m22.xy * (_15610 + float2(_15563[_21518].x, _15563[_21512].y)), _15552.xy, _15552.zw), _15368).xy, _15368));
                                        _21518++;
                                        continue;
                                    }
                                }
                                _21522 = _21515 * (_15614 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _21523 = _21522;
                            break;
                        }
                        uint _15378 = _15173 - _15274;
                        if (_15378 >= uint(_283._m21.w))
                        {
                            _21523 = 1.0;
                            break;
                        }
                        float _15399 = _283._m27[_15378].w * length(in.m_3037 - _283._m27[_15378].xyz);
                        float3 _15417 = ((in.m_3037 + (_3655 * (_15399 * _283._m25.x))) + (_15207 * (_15399 * _283._m25.y))) - _283._m27[_15378].xyz;
                        float3 _15419 = abs(_15417);
                        float _15421 = _15419.x;
                        float _15423 = _15419.y;
                        bool _15424 = _15421 >= _15423;
                        bool _15432;
                        if (_15424)
                        {
                            _15432 = _15421 >= _15419.z;
                        }
                        else
                        {
                            _15432 = _15424;
                        }
                        float _21497;
                        int _21499;
                        if (_15432)
                        {
                            _21499 = (_15417.x > 0.0) ? 0 : 1;
                            _21497 = _15421;
                        }
                        else
                        {
                            float _15444 = _15419.z;
                            bool _15445 = _15423 >= _15444;
                            int _21500;
                            if (_15445)
                            {
                                _21500 = (_15417.y > 0.0) ? 2 : 3;
                            }
                            else
                            {
                                _21500 = (_15417.z > 0.0) ? 4 : 5;
                            }
                            _21499 = _21500;
                            _21497 = _15445 ? _15423 : _15444;
                        }
                        if (_21497 <= 0.0)
                        {
                            _21523 = 1.0;
                            break;
                        }
                        float2 _15482 = float2(dot(_15417, _961[_21499]), dot(_15417, _970[_21499])) / float2(_21497 * _283._m24.z);
                        float _15489 = _283._m28[_15378].z + (_283._m28[_15378].w / _21497);
                        if (_15489 > 1.0)
                        {
                            _21523 = 1.0;
                            break;
                        }
                        float2 _15507 = _283._m28[_15378].xy + (float2(float(spvSMod(_21499, 3)), float(_21499 / 3)) * _283._m24.xy);
                        float2 _15747 = _283._m22.xy * 0.5;
                        float2 _15752 = _15507 + (float2(0.5 + (0.5 * _15482.x), 0.5 - (0.5 * _15482.y)) * _283._m24.xy);
                        float4 _15765 = float4(_15507 + _15747, (_15507 + _283._m24.xy) - _15747);
                        float _21511;
                        do
                        {
                            int _15791 = int(_283._m22.z);
                            if (_15791 <= 0)
                            {
                                _21511 = spvDepthCast(_303).sample_compare(_303Smplr, float3(fast::clamp(_15752, _15765.xy, _15765.zw), _15489).xy, _15489);
                                break;
                            }
                            float2 _15814 = (_15752 / _283._m22.xy) + float2(0.5);
                            float2 _15815 = floor(_15814);
                            float2 _15820 = _15814 - _15815;
                            float2 _15823 = _15815 - float2(0.5);
                            bool _15827 = _15791 == 1;
                            if (_15827)
                            {
                                float2 _15830 = _15820 * 2.0;
                                _15775[0] = float2(3.0) - _15830;
                                _15775[1] = float2(1.0) + _15830;
                                _15776[0] = ((float2(2.0) - _15820) / _15775[0]) - float2(1.0);
                                _15776[1] = (_15820 / _15775[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _15857 = _15820 * 3.0;
                                _15775[0] = float2(4.0) - _15857;
                                _15775[1] = float2(7.0);
                                _15775[2] = float2(1.0) + _15857;
                                _15776[0] = ((float2(3.0) - (_15820 * 2.0)) / _15775[0]) - float2(2.0);
                                _15776[1] = (float2(3.0) + _15820) / _15775[1];
                                _15776[2] = (_15820 / _15775[2]) + float2(2.0);
                            }
                            int _22118 = _15827 ? 2 : 3;
                            int _21501;
                            float _21504;
                            _21504 = 0.0;
                            _21501 = 0;
                            float _21510;
                            for (; _21501 < _22118; _21504 = _21510, _21501++)
                            {
                                _21510 = _21504;
                                for (int _21507 = 0; _21507 < _22118; )
                                {
                                    _21510 += ((_15775[_21507].x * _15775[_21501].y) * spvDepthCast(_303).sample_compare(_303Smplr, float3(fast::clamp(_283._m22.xy * (_15823 + float2(_15776[_21507].x, _15776[_21501].y)), _15765.xy, _15765.zw), _15489).xy, _15489));
                                    _21507++;
                                    continue;
                                }
                            }
                            _21511 = _21504 * (_15827 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _21523 = _21511;
                        break;
                    } while(false);
                    _21628 = _15238 * _21523;
                }
                else
                {
                    _21628 = _15238;
                }
                float3 _4335 = fast::normalize(_15207 + _3644);
                float _4340 = fast::clamp(dot(_21020, _15207), 0.0, 1.0);
                float _4345 = fast::clamp(dot(_21020, _4335), 0.0, 1.0);
                float3 _15962 = _3948 + (_9982 * powr(1.0 - fast::clamp(dot(_3644, _4335), 0.0, 1.0), 5.0));
                float _15976 = ((_4345 * _4345) * _9997) + 1.0;
                _4383 = _21630 + (((((float3(1.0) - _15962) * _3942) + ((_15962 * ((_9992 / ((3.1415927410125732421875 * _15976) * _15976)) * (0.5 / fast::max((_4340 * _10023) + (_21048 * sqrt(((_4340 * _4340) * _10019) + _9992)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875)) * _4340) * _21628);
            }
            _21701 = _21630;
        }
        else
        {
            _21701 = _21631;
        }
        _21697 = _21701;
    }
    float4 _4400 = _4395.sample(_2533, _3419);
    float _4418 = -length(_3643);
    float _21783;
    if (_283._m9.w != 0.0)
    {
        float _4442 = _283._m9.w * (in.m_3037 - _283._m6.xyz).y;
        float _21780;
        if (abs(_4442) < 9.9999997473787516355514526367188e-05)
        {
            _21780 = 1.0 - (0.5 * _4442);
        }
        else
        {
            _21780 = (1.0 - exp(fast::min(-_4442, 60.0))) / _4442;
        }
        _21783 = 1.0 - exp((_4418 * (_283._m7.w * exp(fast::min((-_283._m9.w) * (_283._m6.y - _283._m6.w), 30.0)))) * _21780);
    }
    else
    {
        _21783 = 1.0 - exp(_4418 * _283._m7.w);
    }
    float3 _21830;
    if (_283._m34.z > 0.5)
    {
        float3 _21794;
        if (_283._m29.x > 0.5)
        {
            float _16075 = (_283._m29.z * _21020.x) - (_283._m29.w * _21020.z);
            float _16088 = (_283._m29.w * _21020.x) + (_283._m29.z * _21020.z);
            float _16106 = 1.09254801273345947265625 * _16075;
            spvUnsafeArray<float, 9> _19091 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _21020.y, 0.48860299587249755859375 * _16088, 0.48860299587249755859375 * _16075, _16106 * _21020.y, (1.09254801273345947265625 * _21020.y) * _16088, 0.3153919875621795654296875 * (((3.0 * _16088) * _16088) - 1.0), _16106 * _16088, 0.546274006366729736328125 * ((_16075 * _16075) - (_21020.y * _21020.y)) });
            spvUnsafeArray<float, 9> _16020 = _19091;
            float3 _21793;
            _21793 = float3(0.0);
            for (int _21792 = 0; _21792 < 9; )
            {
                _21793 += (_2531.read(uint2((int2(496, 256) + int2(_21792, 0))), 0).xyz * _16020[_21792]);
                _21792++;
                continue;
            }
            _21794 = fast::max(_21793, float3(0.0)) * _283._m29.y;
        }
        else
        {
            _21794 = mix(_283._m9.xyz, _283._m8.xyz, float3((_21020.y * 0.5) + 0.5)) * _283._m8.w;
        }
        float3 _21799;
        if (_283._m34.y > 0.5)
        {
            int _16283 = int(_283._m34.y);
            int _16286 = int(_283._m34.x);
            float3 _21798;
            _21798 = _21794;
            float3 _22001;
            for (int _21797 = 0; _21797 < _16283; _21798 = _22001, _21797++)
            {
                int _16298 = 8 * (_16286 + _21797);
                float4 _16507 = as_type<float4>(_1281._m0[_16298 + 3]);
                float4 _16551 = as_type<float4>(_1281._m0[_16298]);
                float4 _16557 = as_type<float4>(_1281._m0[_16298 + 1]);
                float4 _16563 = as_type<float4>(_1281._m0[_16298 + 2]);
                float3 _16525 = _16551.xyz;
                float _16529 = _16551.w;
                float3 _16532 = _16557.xyz;
                float _16536 = _16557.w;
                float3 _16539 = _16563.xyz;
                float _16543 = _16563.w;
                float3 _16545 = float3(dot(_16525, in.m_3037) + _16529, dot(_16532, in.m_3037) + _16536, dot(_16539, in.m_3037) + _16543);
                float3 _16307 = _16507.xyz;
                float _16309 = _16507.w;
                float _21833;
                do
                {
                    float3 _16575 = _16307 - abs(_16545);
                    float _16583 = fast::min(_16575.x, fast::min(_16575.y, _16575.z));
                    if (_16583 <= 0.0)
                    {
                        _21833 = 0.0;
                        break;
                    }
                    if (_16309 <= 0.0)
                    {
                        _21833 = 1.0;
                        break;
                    }
                    float _16595 = fast::min(_16583 / _16309, 1.0);
                    _21833 = (_16595 * _16595) * (3.0 - (2.0 * _16595));
                    break;
                } while(false);
                if (_21833 <= 0.0)
                {
                    _22001 = _21798;
                    continue;
                }
                float3 _16318 = as_type<float4>(_1281._m0[_16298 + 4]).xyz;
                float4 _16616 = as_type<float4>(_1281._m0[_16298 + 5]);
                int _16622 = int(((device uint*)&_1281._m0[_16298 + 6])[0u]);
                float _16632 = dot(_16525, _21020);
                float _16638 = dot(_16532, _21020);
                float _16644 = dot(_16539, _21020);
                float3 _16645 = float3(_16632, _16638, _16644);
                float3 _16338 = (in.m_3037 + (_21020 * _16616.x)) + (_3644 * _16616.y);
                float3 _16357 = fast::clamp((((float3(dot(_16525, _16338) + _16529, dot(_16532, _16338) + _16536, dot(_16539, _16338) + _16543) + _16307) / fast::max(_16307 * 2.0, float3(9.9999999747524270787835121154785e-07))) * _16318) - float3(0.5), float3(0.0), _16318 - float3(1.0));
                int3 _16359 = int3(_16318);
                int3 _16366 = min(int3(_16357), max((_16359 - int3(2)), int3(0)));
                float3 _16370 = _16357 - float3(_16366);
                float _16725 = 0.48860299587249755859375 * _16638;
                float _16728 = 0.48860299587249755859375 * _16644;
                float _16731 = 0.48860299587249755859375 * _16632;
                float _16736 = 1.09254801273345947265625 * _16632;
                float _16739 = _16736 * _16638;
                float _16745 = (1.09254801273345947265625 * _16638) * _16644;
                float _16753 = 0.3153919875621795654296875 * (((3.0 * _16644) * _16644) - 1.0);
                float _16759 = _16736 * _16644;
                float _16773 = 0.546274006366729736328125 * ((_16632 * _16632) - (_16638 * _16638));
                int3 _16792 = _16359 - int3(1);
                int3 _16793 = min(_16366, _16792);
                int _16798 = _16359.x;
                int _16802 = _16359.y;
                int _16810 = _16622 + ((_16793.x + (_16798 * (_16793.y + (_16802 * _16793.z)))) * 4);
                float3 _16813 = float3(1.0) - _16370;
                float3 _16831 = (((((float3(_16793) + float3(0.5)) / _16318) * _16307) * 2.0) - _16307) - _16545;
                float _16841 = dot(_16831 * rsqrt(fast::max(dot(_16831, _16831), 1.0000000133514319600180897396058e-10)), _16645) + 1.0;
                float _16844 = _16813.x;
                float _16846 = _16813.y;
                float _16847 = _16844 * _16846;
                float _16849 = _16813.z;
                int _16873 = _16810 + 3;
                float _16859 = ((_16847 * _16849) * ((0.25 * (_16841 * _16841)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_16873])[1u])).y > 0.5);
                int _16903 = _16810 + 1;
                int _16907 = _16810 + 2;
                float2 _16919 = float2(as_type<half2>(_1281._m0[_16810].y));
                float2 _16928 = float2(as_type<half2>(_1281._m0[_16903].x));
                float2 _16937 = float2(as_type<half2>(_1281._m0[_16903].w));
                float2 _16946 = float2(as_type<half2>(_1281._m0[_16907].z));
                float3 _17034 = (((((((float3(float2(as_type<half2>(_1281._m0[_16810].x)), _16919.x) * 0.2820949852466583251953125) + (float3(_16919.y, float2(as_type<half2>(_1281._m0[_16810].z))) * _16725)) + (float3(float2(as_type<half2>(_1281._m0[_16810].w)), _16928.x) * _16728)) + (float3(_16928.y, float2(as_type<half2>(_1281._m0[_16903].y))) * _16731)) + (float3(float2(as_type<half2>(_1281._m0[_16903].z)), _16937.x) * _16739)) + (float3(_16937.y, float2(as_type<half2>(_1281._m0[_16907].x))) * _16745)) + (float3(float2(as_type<half2>(_1281._m0[_16907].y)), _16946.x) * _16753)) + (float3(_16946.y, float2(as_type<half2>(_1281._m0[_16907].w))) * _16759);
                int3 _17062 = min((_16366 + int3(1, 0, 0)), _16792);
                int _17079 = _16622 + ((_17062.x + (_16798 * (_17062.y + (_16802 * _17062.z)))) * 4);
                float3 _17100 = (((((float3(_17062) + float3(0.5)) / _16318) * _16307) * 2.0) - _16307) - _16545;
                float _17110 = dot(_17100 * rsqrt(fast::max(dot(_17100, _17100), 1.0000000133514319600180897396058e-10)), _16645) + 1.0;
                float _17116 = _16370.x * _16846;
                int _17142 = _17079 + 3;
                float _17128 = ((_17116 * _16849) * ((0.25 * (_17110 * _17110)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_17142])[1u])).y > 0.5);
                int _17172 = _17079 + 1;
                int _17176 = _17079 + 2;
                float2 _17188 = float2(as_type<half2>(_1281._m0[_17079].y));
                float2 _17197 = float2(as_type<half2>(_1281._m0[_17172].x));
                float2 _17206 = float2(as_type<half2>(_1281._m0[_17172].w));
                float2 _17215 = float2(as_type<half2>(_1281._m0[_17176].z));
                float3 _17303 = (((((((float3(float2(as_type<half2>(_1281._m0[_17079].x)), _17188.x) * 0.2820949852466583251953125) + (float3(_17188.y, float2(as_type<half2>(_1281._m0[_17079].z))) * _16725)) + (float3(float2(as_type<half2>(_1281._m0[_17079].w)), _17197.x) * _16728)) + (float3(_17197.y, float2(as_type<half2>(_1281._m0[_17172].y))) * _16731)) + (float3(float2(as_type<half2>(_1281._m0[_17172].z)), _17206.x) * _16739)) + (float3(_17206.y, float2(as_type<half2>(_1281._m0[_17176].x))) * _16745)) + (float3(float2(as_type<half2>(_1281._m0[_17176].y)), _17215.x) * _16753)) + (float3(_17215.y, float2(as_type<half2>(_1281._m0[_17176].w))) * _16759);
                int3 _17331 = min((_16366 + int3(0, 1, 0)), _16792);
                int _17348 = _16622 + ((_17331.x + (_16798 * (_17331.y + (_16802 * _17331.z)))) * 4);
                float3 _17369 = (((((float3(_17331) + float3(0.5)) / _16318) * _16307) * 2.0) - _16307) - _16545;
                float _17379 = dot(_17369 * rsqrt(fast::max(dot(_17369, _17369), 1.0000000133514319600180897396058e-10)), _16645) + 1.0;
                float _17385 = _16844 * _16370.y;
                int _17411 = _17348 + 3;
                float _17397 = ((_17385 * _16849) * ((0.25 * (_17379 * _17379)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_17411])[1u])).y > 0.5);
                int _17441 = _17348 + 1;
                int _17445 = _17348 + 2;
                float2 _17457 = float2(as_type<half2>(_1281._m0[_17348].y));
                float2 _17466 = float2(as_type<half2>(_1281._m0[_17441].x));
                float2 _17475 = float2(as_type<half2>(_1281._m0[_17441].w));
                float2 _17484 = float2(as_type<half2>(_1281._m0[_17445].z));
                float3 _17572 = (((((((float3(float2(as_type<half2>(_1281._m0[_17348].x)), _17457.x) * 0.2820949852466583251953125) + (float3(_17457.y, float2(as_type<half2>(_1281._m0[_17348].z))) * _16725)) + (float3(float2(as_type<half2>(_1281._m0[_17348].w)), _17466.x) * _16728)) + (float3(_17466.y, float2(as_type<half2>(_1281._m0[_17441].y))) * _16731)) + (float3(float2(as_type<half2>(_1281._m0[_17441].z)), _17475.x) * _16739)) + (float3(_17475.y, float2(as_type<half2>(_1281._m0[_17445].x))) * _16745)) + (float3(float2(as_type<half2>(_1281._m0[_17445].y)), _17484.x) * _16753)) + (float3(_17484.y, float2(as_type<half2>(_1281._m0[_17445].w))) * _16759);
                int3 _17600 = min((_16366 + int3(1, 1, 0)), _16792);
                int _17617 = _16622 + ((_17600.x + (_16798 * (_17600.y + (_16802 * _17600.z)))) * 4);
                float3 _17638 = (((((float3(_17600) + float3(0.5)) / _16318) * _16307) * 2.0) - _16307) - _16545;
                float _17648 = dot(_17638 * rsqrt(fast::max(dot(_17638, _17638), 1.0000000133514319600180897396058e-10)), _16645) + 1.0;
                float _17654 = _16370.x * _16370.y;
                int _17680 = _17617 + 3;
                float _17666 = ((_17654 * _16849) * ((0.25 * (_17648 * _17648)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_17680])[1u])).y > 0.5);
                int _17710 = _17617 + 1;
                int _17714 = _17617 + 2;
                float2 _17726 = float2(as_type<half2>(_1281._m0[_17617].y));
                float2 _17735 = float2(as_type<half2>(_1281._m0[_17710].x));
                float2 _17744 = float2(as_type<half2>(_1281._m0[_17710].w));
                float2 _17753 = float2(as_type<half2>(_1281._m0[_17714].z));
                float3 _17841 = (((((((float3(float2(as_type<half2>(_1281._m0[_17617].x)), _17726.x) * 0.2820949852466583251953125) + (float3(_17726.y, float2(as_type<half2>(_1281._m0[_17617].z))) * _16725)) + (float3(float2(as_type<half2>(_1281._m0[_17617].w)), _17735.x) * _16728)) + (float3(_17735.y, float2(as_type<half2>(_1281._m0[_17710].y))) * _16731)) + (float3(float2(as_type<half2>(_1281._m0[_17710].z)), _17744.x) * _16739)) + (float3(_17744.y, float2(as_type<half2>(_1281._m0[_17714].x))) * _16745)) + (float3(float2(as_type<half2>(_1281._m0[_17714].y)), _17753.x) * _16753)) + (float3(_17753.y, float2(as_type<half2>(_1281._m0[_17714].w))) * _16759);
                int3 _17869 = min((_16366 + int3(0, 0, 1)), _16792);
                int _17886 = _16622 + ((_17869.x + (_16798 * (_17869.y + (_16802 * _17869.z)))) * 4);
                float3 _17907 = (((((float3(_17869) + float3(0.5)) / _16318) * _16307) * 2.0) - _16307) - _16545;
                float _17917 = dot(_17907 * rsqrt(fast::max(dot(_17907, _17907), 1.0000000133514319600180897396058e-10)), _16645) + 1.0;
                int _17949 = _17886 + 3;
                float _17935 = ((_16847 * _16370.z) * ((0.25 * (_17917 * _17917)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_17949])[1u])).y > 0.5);
                int _17979 = _17886 + 1;
                int _17983 = _17886 + 2;
                float2 _17995 = float2(as_type<half2>(_1281._m0[_17886].y));
                float2 _18004 = float2(as_type<half2>(_1281._m0[_17979].x));
                float2 _18013 = float2(as_type<half2>(_1281._m0[_17979].w));
                float2 _18022 = float2(as_type<half2>(_1281._m0[_17983].z));
                float3 _18110 = (((((((float3(float2(as_type<half2>(_1281._m0[_17886].x)), _17995.x) * 0.2820949852466583251953125) + (float3(_17995.y, float2(as_type<half2>(_1281._m0[_17886].z))) * _16725)) + (float3(float2(as_type<half2>(_1281._m0[_17886].w)), _18004.x) * _16728)) + (float3(_18004.y, float2(as_type<half2>(_1281._m0[_17979].y))) * _16731)) + (float3(float2(as_type<half2>(_1281._m0[_17979].z)), _18013.x) * _16739)) + (float3(_18013.y, float2(as_type<half2>(_1281._m0[_17983].x))) * _16745)) + (float3(float2(as_type<half2>(_1281._m0[_17983].y)), _18022.x) * _16753)) + (float3(_18022.y, float2(as_type<half2>(_1281._m0[_17983].w))) * _16759);
                float4 _16437 = (((float4((_17034 + (float3(float2(as_type<half2>(_1281._m0[_16873].x)), float2(as_type<half2>(_1281._m0[_16873].y)).x) * _16773)) * _16859, _16859) + float4((_17303 + (float3(float2(as_type<half2>(_1281._m0[_17142].x)), float2(as_type<half2>(_1281._m0[_17142].y)).x) * _16773)) * _17128, _17128)) + float4((_17572 + (float3(float2(as_type<half2>(_1281._m0[_17411].x)), float2(as_type<half2>(_1281._m0[_17411].y)).x) * _16773)) * _17397, _17397)) + float4((_17841 + (float3(float2(as_type<half2>(_1281._m0[_17680].x)), float2(as_type<half2>(_1281._m0[_17680].y)).x) * _16773)) * _17666, _17666)) + float4((_18110 + (float3(float2(as_type<half2>(_1281._m0[_17949].x)), float2(as_type<half2>(_1281._m0[_17949].y)).x) * _16773)) * _17935, _17935);
                int3 _18138 = min((_16366 + int3(1, 0, 1)), _16792);
                int _18155 = _16622 + ((_18138.x + (_16798 * (_18138.y + (_16802 * _18138.z)))) * 4);
                float3 _18176 = (((((float3(_18138) + float3(0.5)) / _16318) * _16307) * 2.0) - _16307) - _16545;
                float _18186 = dot(_18176 * rsqrt(fast::max(dot(_18176, _18176), 1.0000000133514319600180897396058e-10)), _16645) + 1.0;
                int _18218 = _18155 + 3;
                float _18204 = ((_17116 * _16370.z) * ((0.25 * (_18186 * _18186)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_18218])[1u])).y > 0.5);
                int _18248 = _18155 + 1;
                int _18252 = _18155 + 2;
                float2 _18264 = float2(as_type<half2>(_1281._m0[_18155].y));
                float2 _18273 = float2(as_type<half2>(_1281._m0[_18248].x));
                float2 _18282 = float2(as_type<half2>(_1281._m0[_18248].w));
                float2 _18291 = float2(as_type<half2>(_1281._m0[_18252].z));
                float3 _18379 = (((((((float3(float2(as_type<half2>(_1281._m0[_18155].x)), _18264.x) * 0.2820949852466583251953125) + (float3(_18264.y, float2(as_type<half2>(_1281._m0[_18155].z))) * _16725)) + (float3(float2(as_type<half2>(_1281._m0[_18155].w)), _18273.x) * _16728)) + (float3(_18273.y, float2(as_type<half2>(_1281._m0[_18248].y))) * _16731)) + (float3(float2(as_type<half2>(_1281._m0[_18248].z)), _18282.x) * _16739)) + (float3(_18282.y, float2(as_type<half2>(_1281._m0[_18252].x))) * _16745)) + (float3(float2(as_type<half2>(_1281._m0[_18252].y)), _18291.x) * _16753)) + (float3(_18291.y, float2(as_type<half2>(_1281._m0[_18252].w))) * _16759);
                int3 _18407 = min((_16366 + int3(0, 1, 1)), _16792);
                int _18424 = _16622 + ((_18407.x + (_16798 * (_18407.y + (_16802 * _18407.z)))) * 4);
                float3 _18445 = (((((float3(_18407) + float3(0.5)) / _16318) * _16307) * 2.0) - _16307) - _16545;
                float _18455 = dot(_18445 * rsqrt(fast::max(dot(_18445, _18445), 1.0000000133514319600180897396058e-10)), _16645) + 1.0;
                int _18487 = _18424 + 3;
                float _18473 = ((_17385 * _16370.z) * ((0.25 * (_18455 * _18455)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_18487])[1u])).y > 0.5);
                int _18517 = _18424 + 1;
                int _18521 = _18424 + 2;
                float2 _18533 = float2(as_type<half2>(_1281._m0[_18424].y));
                float2 _18542 = float2(as_type<half2>(_1281._m0[_18517].x));
                float2 _18551 = float2(as_type<half2>(_1281._m0[_18517].w));
                float2 _18560 = float2(as_type<half2>(_1281._m0[_18521].z));
                float3 _18648 = (((((((float3(float2(as_type<half2>(_1281._m0[_18424].x)), _18533.x) * 0.2820949852466583251953125) + (float3(_18533.y, float2(as_type<half2>(_1281._m0[_18424].z))) * _16725)) + (float3(float2(as_type<half2>(_1281._m0[_18424].w)), _18542.x) * _16728)) + (float3(_18542.y, float2(as_type<half2>(_1281._m0[_18517].y))) * _16731)) + (float3(float2(as_type<half2>(_1281._m0[_18517].z)), _18551.x) * _16739)) + (float3(_18551.y, float2(as_type<half2>(_1281._m0[_18521].x))) * _16745)) + (float3(float2(as_type<half2>(_1281._m0[_18521].y)), _18560.x) * _16753)) + (float3(_18560.y, float2(as_type<half2>(_1281._m0[_18521].w))) * _16759);
                int3 _18676 = min((_16366 + int3(1)), _16792);
                int _18693 = _16622 + ((_18676.x + (_16798 * (_18676.y + (_16802 * _18676.z)))) * 4);
                float3 _18714 = (((((float3(_18676) + float3(0.5)) / _16318) * _16307) * 2.0) - _16307) - _16545;
                float _18724 = dot(_18714 * rsqrt(fast::max(dot(_18714, _18714), 1.0000000133514319600180897396058e-10)), _16645) + 1.0;
                int _18756 = _18693 + 3;
                float _18742 = ((_17654 * _16370.z) * ((0.25 * (_18724 * _18724)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_18756])[1u])).y > 0.5);
                int _18786 = _18693 + 1;
                int _18790 = _18693 + 2;
                float2 _18802 = float2(as_type<half2>(_1281._m0[_18693].y));
                float2 _18811 = float2(as_type<half2>(_1281._m0[_18786].x));
                float2 _18820 = float2(as_type<half2>(_1281._m0[_18786].w));
                float2 _18829 = float2(as_type<half2>(_1281._m0[_18790].z));
                float3 _18917 = (((((((float3(float2(as_type<half2>(_1281._m0[_18693].x)), _18802.x) * 0.2820949852466583251953125) + (float3(_18802.y, float2(as_type<half2>(_1281._m0[_18693].z))) * _16725)) + (float3(float2(as_type<half2>(_1281._m0[_18693].w)), _18811.x) * _16728)) + (float3(_18811.y, float2(as_type<half2>(_1281._m0[_18786].y))) * _16731)) + (float3(float2(as_type<half2>(_1281._m0[_18786].z)), _18820.x) * _16739)) + (float3(_18820.y, float2(as_type<half2>(_1281._m0[_18790].x))) * _16745)) + (float3(float2(as_type<half2>(_1281._m0[_18790].y)), _18829.x) * _16753)) + (float3(_18829.y, float2(as_type<half2>(_1281._m0[_18790].w))) * _16759);
                float4 _16476 = ((_16437 + float4((_18379 + (float3(float2(as_type<half2>(_1281._m0[_18218].x)), float2(as_type<half2>(_1281._m0[_18218].y)).x) * _16773)) * _18204, _18204)) + float4((_18648 + (float3(float2(as_type<half2>(_1281._m0[_18487].x)), float2(as_type<half2>(_1281._m0[_18487].y)).x) * _16773)) * _18473, _18473)) + float4((_18917 + (float3(float2(as_type<half2>(_1281._m0[_18756].x)), float2(as_type<half2>(_1281._m0[_18756].y)).x) * _16773)) * _18742, _18742);
                float _16480 = _16476.w;
                float3 _22002;
                if (_16480 > 9.9999997473787516355514526367188e-06)
                {
                    _22002 = mix(_21798, (fast::max(_16476.xyz, float3(0.0)) / float3(_16480)) * _16616.z, float3(_21833));
                }
                else
                {
                    _22002 = _21798;
                }
                _22001 = _22002;
            }
            _21799 = _21798;
        }
        else
        {
            _21799 = _21794;
        }
        _21830 = _21799 * _21144;
    }
    else
    {
        _21830 = mix(mix(_21697, _21014, float3(_2876._m1.y)) + ((_2876._m5.xyz * _4400.xyz) * (float3(1.0) + in.m_3657.yzw)), _283._m7.xyz, float3(_21783));
    }
    float3 _21831;
    if (_283._m33.w > 0.5)
    {
        _21831 = _21830 / (float3(1.0) + _21830);
    }
    else
    {
        _21831 = _21830;
    }
    out.m_4542 = float4(_21831, (in.m_3428.w * _2876._m0.w) * _3426.w);
    float2 _21832;
    do
    {
        if (in.m_4552.w <= 0.0)
        {
            _21832 = float2(0.0);
            break;
        }
        _21832 = ((in.m_4552.xy / float2(in.m_4552.w)) - (in.m_4551.xy / float2(in.m_4551.w))) * float2(0.5, -0.5);
        break;
    } while(false);
    out.m_4550 = _21832;
    return out;
}

