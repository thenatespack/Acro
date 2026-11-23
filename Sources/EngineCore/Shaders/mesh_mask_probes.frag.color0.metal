// Generated from mesh_mask_probes.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 01c6799f8aa23ee3
// glsl-fnv1a64: d9703b0b70dba6d1

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
    float4 m_4555 [[color(0)]];
};

struct fragment_main_in
{
    float3 m_3037 [[user(locn0)]];
    float3 m_2946 [[user(locn1)]];
    float2 m_3405 [[user(locn2)]];
    float4 m_3428 [[user(locn3)]];
    float3 m_2980 [[user(locn4)]];
    float4 m_3670 [[user(locn5)]];
    float4 m_4564 [[user(locn6)]];
    float4 m_4565 [[user(locn7)]];
    float4 m_2952 [[user(locn8)]];
};

fragment fragment_main_out fragment_main(fragment_main_in in [[stage_in]], constant _2874& _2876 [[buffer(2)]], constant _3028& _3030 [[buffer(3)]], constant _3063& _3065 [[buffer(4)]], constant _3071& _3073 [[buffer(5)]], constant _3165& _3167 [[buffer(6)]], constant _3186& _3188 [[buffer(7)]], constant _281& _283 [[buffer(15)]], const device _1279& _1281 [[buffer(21)]], texture2d<float> _303 [[texture(0)]], texture2d<float> _3421 [[texture(1)]], texture2d<float> _3911 [[texture(2)]], texture2d<float> _3547 [[texture(3)]], texture2d<float> _3352 [[texture(4)]], texture2d<float> _4408 [[texture(5)]], texture2d<float> _2531 [[texture(6)]], texture2d<float> _2632 [[texture(7)]], sampler _303Smplr [[sampler(0)]], sampler _2533 [[sampler(1)]], sampler _2634 [[sampler(7)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])
{
    float2 _4563;
    fragment_main_out out = {};
    float2 _3419 = float2(dot(_2876._m2.xy, in.m_3405) + _2876._m2.z, dot(_2876._m3.xy, in.m_3405) + _2876._m3.z);
    float4 _3426 = _3421.sample(_2533, _3419);
    float3 _3436 = _3426.xyz;
    float3 _3437 = (in.m_3428.xyz * _2876._m0.xyz) * _3436;
    if ((_2876._m0.w * _3426.w) < _2876._m6.x)
    {
        discard_fragment();
    }
    float3 _20837;
    if (_2876._m1.x > 0.5)
    {
        float2 _3471 = floor(in.m_3037.xz * float2(0.5));
        _20837 = _3437 * ((mod(abs(_3471.x + _3471.y), 2.0) < 0.5) ? 1.0 : 0.75);
    }
    else
    {
        _20837 = _3437;
    }
    float3 _20934;
    float _20965;
    float2 _20998;
    if (_2876._m3.w > 0.5)
    {
        float3 _4671;
        float2 _4678;
        float _20835;
        do
        {
            float3 _4642 = float4(_2876._m2.w, _2876._m3.w, 0.0, 0.0).xyy;
            float3 _4645 = floor(_4642 * float3(1.52587890625e-05));
            float3 _4650 = _4642 - (_4645 * 65536.0);
            float3 _4653 = floor(_4650 * float3(0.00390625));
            float3 _4661 = _4650 - (_4653 * 256.0);
            _4671 = (float3(_4661.x, _4653.x, _4645.x) * float3(0.0039215688593685626983642578125)) * 2.0;
            _4678 = float2(_4661.y, _4653.y) * float2(0.0039215688593685626983642578125);
            float _4681 = _4645.y - 128.0;
            float _4687 = floor(_4681 * 0.03125) * 0.3333333432674407958984375;
            float3 _4693 = fast::normalize(in.m_2946);
            float _4697 = dot(_4693, in.m_2952.xyz);
            float _4709 = (_4697 / fast::max(length(in.m_2952.xyz - (_4693 * _4697)), 9.9999999747524270787835121154785e-07)) * 25.5;
            if (((-24.0) + _4709) < (-2.0))
            {
                _20835 = 0.0;
                break;
            }
            float3 _4717 = in.m_2980 * (4.0 * exp2(mod(_4681, 32.0) * 0.3333333432674407958984375));
            float3 _4761 = floor(_4717);
            float3 _4764 = _4717 - _4761;
            float3 _4772 = (_4764 * _4764) * (float3(3.0) - (_4764 * 2.0));
            uint3 _4839 = uint3(int3(_4761));
            uint _4852 = (((_4839.x * 1597334677u) ^ (_4839.y * 3812015801u)) ^ (_4839.z * 2798796415u)) * 1597334677u;
            uint3 _4867 = uint3(int3(_4761 + float3(1.0, 0.0, 0.0)));
            uint _4880 = (((_4867.x * 1597334677u) ^ (_4867.y * 3812015801u)) ^ (_4867.z * 2798796415u)) * 1597334677u;
            float _4781 = _4772.x;
            uint3 _4895 = uint3(int3(_4761 + float3(0.0, 1.0, 0.0)));
            uint _4908 = (((_4895.x * 1597334677u) ^ (_4895.y * 3812015801u)) ^ (_4895.z * 2798796415u)) * 1597334677u;
            uint3 _4923 = uint3(int3(_4761 + float3(1.0, 1.0, 0.0)));
            uint _4936 = (((_4923.x * 1597334677u) ^ (_4923.y * 3812015801u)) ^ (_4923.z * 2798796415u)) * 1597334677u;
            float _4797 = _4772.y;
            uint3 _4951 = uint3(int3(_4761 + float3(0.0, 0.0, 1.0)));
            uint _4964 = (((_4951.x * 1597334677u) ^ (_4951.y * 3812015801u)) ^ (_4951.z * 2798796415u)) * 1597334677u;
            uint3 _4979 = uint3(int3(_4761 + float3(1.0, 0.0, 1.0)));
            uint _4992 = (((_4979.x * 1597334677u) ^ (_4979.y * 3812015801u)) ^ (_4979.z * 2798796415u)) * 1597334677u;
            uint3 _5007 = uint3(int3(_4761 + float3(0.0, 1.0, 1.0)));
            uint _5020 = (((_5007.x * 1597334677u) ^ (_5007.y * 3812015801u)) ^ (_5007.z * 2798796415u)) * 1597334677u;
            uint3 _5035 = uint3(int3(_4761 + float3(1.0)));
            uint _5048 = (((_5035.x * 1597334677u) ^ (_5035.y * 3812015801u)) ^ (_5035.z * 2798796415u)) * 1597334677u;
            float3 _4723 = (_4717 * 2.7000000476837158203125) + float3(17.299999237060546875, 5.099999904632568359375, 9.69999980926513671875);
            float3 _5074 = floor(_4723);
            float3 _5077 = _4723 - _5074;
            float3 _5085 = (_5077 * _5077) * (float3(3.0) - (_5077 * 2.0));
            uint3 _5152 = uint3(int3(_5074));
            uint _5165 = (((_5152.x * 1597334677u) ^ (_5152.y * 3812015801u)) ^ (_5152.z * 2798796415u)) * 1597334677u;
            uint3 _5180 = uint3(int3(_5074 + float3(1.0, 0.0, 0.0)));
            uint _5193 = (((_5180.x * 1597334677u) ^ (_5180.y * 3812015801u)) ^ (_5180.z * 2798796415u)) * 1597334677u;
            float _5094 = _5085.x;
            uint3 _5208 = uint3(int3(_5074 + float3(0.0, 1.0, 0.0)));
            uint _5221 = (((_5208.x * 1597334677u) ^ (_5208.y * 3812015801u)) ^ (_5208.z * 2798796415u)) * 1597334677u;
            uint3 _5236 = uint3(int3(_5074 + float3(1.0, 1.0, 0.0)));
            uint _5249 = (((_5236.x * 1597334677u) ^ (_5236.y * 3812015801u)) ^ (_5236.z * 2798796415u)) * 1597334677u;
            float _5110 = _5085.y;
            uint3 _5264 = uint3(int3(_5074 + float3(0.0, 0.0, 1.0)));
            uint _5277 = (((_5264.x * 1597334677u) ^ (_5264.y * 3812015801u)) ^ (_5264.z * 2798796415u)) * 1597334677u;
            uint3 _5292 = uint3(int3(_5074 + float3(1.0, 0.0, 1.0)));
            uint _5305 = (((_5292.x * 1597334677u) ^ (_5292.y * 3812015801u)) ^ (_5292.z * 2798796415u)) * 1597334677u;
            uint3 _5320 = uint3(int3(_5074 + float3(0.0, 1.0, 1.0)));
            uint _5333 = (((_5320.x * 1597334677u) ^ (_5320.y * 3812015801u)) ^ (_5320.z * 2798796415u)) * 1597334677u;
            uint3 _5348 = uint3(int3(_5074 + float3(1.0)));
            uint _5361 = (((_5348.x * 1597334677u) ^ (_5348.y * 3812015801u)) ^ (_5348.z * 2798796415u)) * 1597334677u;
            float _4728 = mix(0.449999988079071044921875, 0.0500000007450580596923828125, _4687);
            float _4732 = ((mix(mix(mix(float((_4852 ^ (_4852 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_4880 ^ (_4880 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _4781), mix(float((_4908 ^ (_4908 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_4936 ^ (_4936 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _4781), _4797), mix(mix(float((_4964 ^ (_4964 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_4992 ^ (_4992 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _4781), mix(float((_5020 ^ (_5020 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_5048 ^ (_5048 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _4781), _4797), _4772.z) * 0.64999997615814208984375) + (mix(mix(mix(float((_5165 ^ (_5165 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_5193 ^ (_5193 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _5094), mix(float((_5221 ^ (_5221 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_5249 ^ (_5249 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _5094), _5110), mix(mix(float((_5277 ^ (_5277 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_5305 ^ (_5305 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _5094), mix(float((_5333 ^ (_5333 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_5361 ^ (_5361 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _5094), _5110), _5085.z) * 0.3499999940395355224609375)) - 0.5;
            _20835 = smoothstep(-_4728, _4728, (_4709 + (-24.450000762939453125)) + (_4732 * mix(0.800000011920928955078125, 2.2000000476837158203125, _4687)));
            break;
        } while(false);
        _20998 = _4678;
        _20965 = _20835;
        _20934 = mix(_20837, (in.m_3428.xyz * _4671) * mix(float3(1.0), _3436 * 2.0, float3(0.5)), float3(_20835));
    }
    else
    {
        _20998 = float2(0.0);
        _20965 = 0.0;
        _20934 = _20837;
    }
    float3 _3513 = fast::normalize(in.m_2946);
    float3 _20847;
    if (_2876._m6.y > 0.5)
    {
        float3 _3528 = in.m_2952.xyz - (_3513 * dot(_3513, in.m_2952.xyz));
        float3 _20848;
        if (dot(_3528, _3528) > 9.9999999600419720025001879548654e-13)
        {
            float3 _3536 = fast::normalize(_3528);
            float4 _3552 = _3547.sample(_2533, _3419);
            float3 _20839;
            if (_2876._m6.z > 0.5)
            {
                float2 _20838;
                if (_2876._m6.z > 1.5)
                {
                    _20838 = _3552.xw;
                }
                else
                {
                    _20838 = _3552.xy;
                }
                float2 _3574 = (_20838 * 2.0) - float2(1.0);
                _20839 = float3(_3574, sqrt(fast::clamp(1.0 - dot(_3574, _3574), 0.0, 1.0)));
            }
            else
            {
                _20839 = (_3552.xyz * 2.0) - float3(1.0);
            }
            float2 _3596 = _20839.xy * _2876._m4.z;
            _20848 = fast::normalize(((_3536 * _3596.x) + ((cross(_3513, _3536) * ((in.m_2952.w < 0.0) ? (-1.0) : 1.0)) * _3596.y)) + (_3513 * _20839.z));
        }
        else
        {
            _20848 = _3513;
        }
        _20847 = _20848;
    }
    else
    {
        _20847 = _3513;
    }
    bool _3620 = _2876._m5.w > 0.5;
    float _20844;
    if (_3620)
    {
        _20844 = fast::clamp(_2876._m1.z, 0.0, 1.0);
    }
    else
    {
        _20844 = 0.0;
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
    float3 _21034;
    if (_3638 && (_20844 <= 0.0))
    {
        _21034 = -_20847;
    }
    else
    {
        _21034 = _20847;
    }
    float3 _3650 = fast::normalize(_283._m4.xyz);
    float3 _3656 = _283._m6.xyz - in.m_3037;
    float3 _3657 = fast::normalize(_3656);
    float3 _3662 = fast::normalize(_3650 + _3657);
    float3 _3668 = _3513 * (gl_FrontFacing ? 1.0 : (-1.0));
    bool _3673 = in.m_3670.x > 0.5;
    float3 _21028;
    float _21068;
    if ((_283._m5.w > 0.5) && _3673)
    {
        float _20904;
        float3 _20905;
        do
        {
            int _5390 = int(_283._m21.x);
            float _5398 = dot(_283._m20.xyz, in.m_3037) + _283._m20.w;
            int _20849;
            _20849 = 0;
            for (;;)
            {
                bool _5404 = _20849 < (_5390 - 1);
                bool _5412;
                if (_5404)
                {
                    _5412 = _5398 > _283._m16[_20849];
                }
                else
                {
                    _5412 = _5404;
                }
                if (_5412)
                {
                    _20849++;
                    continue;
                }
                else
                {
                    break;
                }
            }
            if (_5398 > _283._m16[_20849])
            {
                _20905 = float3(1.0);
                _20904 = 1.0;
                break;
            }
            float _20862;
            do
            {
                float4 _5514 = _283._m14[_20849] * float4(in.m_3037 + (_3668 * _283._m18[_20849]), 1.0);
                float _5517 = _5514.x;
                bool _5518 = _5517 < 0.0;
                bool _5525;
                if (!_5518)
                {
                    _5525 = _5517 > 1.0;
                }
                else
                {
                    _5525 = _5518;
                }
                bool _5532;
                if (!_5525)
                {
                    _5532 = _5514.y < 0.0;
                }
                else
                {
                    _5532 = _5525;
                }
                bool _5539;
                if (!_5532)
                {
                    _5539 = _5514.y > 1.0;
                }
                else
                {
                    _5539 = _5532;
                }
                if (_5539)
                {
                    _20862 = 1.0;
                    break;
                }
                float2 _5552 = float2(float(_20849 & 1), float(_20849 >> 1)) * _283._m23.xy;
                float _5559 = fast::min(_5514.z, 1.0) - _283._m19[_20849];
                float2 _5578 = _283._m22.xy * 0.5;
                float2 _5583 = _5552 + (_5514.xy * _283._m23.xy);
                float4 _5596 = float4(_5552 + _5578, (_5552 + _283._m23.xy) - _5578);
                float _20861;
                do
                {
                    int _5622 = int(_283._m22.z);
                    if (_5622 <= 0)
                    {
                        _20861 = spvDepthCast(_303).sample_compare(_303Smplr, float3(fast::clamp(_5583, _5596.xy, _5596.zw), _5559).xy, _5559);
                        break;
                    }
                    float2 _5645 = (_5583 / _283._m22.xy) + float2(0.5);
                    float2 _5646 = floor(_5645);
                    float2 _5651 = _5645 - _5646;
                    float2 _5654 = _5646 - float2(0.5);
                    bool _5658 = _5622 == 1;
                    spvUnsafeArray<float2, 3> _5606;
                    spvUnsafeArray<float2, 3> _5607;
                    if (_5658)
                    {
                        float2 _5661 = _5651 * 2.0;
                        _5606[0] = float2(3.0) - _5661;
                        _5606[1] = float2(1.0) + _5661;
                        _5607[0] = ((float2(2.0) - _5651) / _5606[0]) - float2(1.0);
                        _5607[1] = (_5651 / _5606[1]) + float2(1.0);
                    }
                    else
                    {
                        float2 _5688 = _5651 * 3.0;
                        _5606[0] = float2(4.0) - _5688;
                        _5606[1] = float2(7.0);
                        _5606[2] = float2(1.0) + _5688;
                        _5607[0] = ((float2(3.0) - (_5651 * 2.0)) / _5606[0]) - float2(2.0);
                        _5607[1] = (float2(3.0) + _5651) / _5606[1];
                        _5607[2] = (_5651 / _5606[2]) + float2(2.0);
                    }
                    int _22260 = _5658 ? 2 : 3;
                    int _20851;
                    float _20854;
                    _20854 = 0.0;
                    _20851 = 0;
                    float _20860;
                    for (; _20851 < _22260; _20854 = _20860, _20851++)
                    {
                        _20860 = _20854;
                        for (int _20857 = 0; _20857 < _22260; )
                        {
                            _20860 += ((_5606[_20857].x * _5606[_20851].y) * spvDepthCast(_303).sample_compare(_303Smplr, float3(fast::clamp(_283._m22.xy * (_5654 + float2(_5607[_20857].x, _5607[_20851].y)), _5596.xy, _5596.zw), _5559).xy, _5559));
                            _20857++;
                            continue;
                        }
                    }
                    _20861 = _20854 * (_5658 ? 0.0625 : 0.0069444444961845874786376953125);
                    break;
                } while(false);
                _20862 = _20861;
                break;
            } while(false);
            float3 _20899;
            float _20902;
            if (_5398 > _283._m17[_20849])
            {
                float _5452 = (_5398 - _283._m17[_20849]) / (_283._m16[_20849] - _283._m17[_20849]);
                int _5454 = _20849 + 1;
                float3 _20900;
                float _20903;
                if (_5454 < _5390)
                {
                    float _20882;
                    do
                    {
                        float4 _5801 = _283._m14[_5454] * float4(in.m_3037 + (_3668 * _283._m18[_5454]), 1.0);
                        float _5804 = _5801.x;
                        bool _5805 = _5804 < 0.0;
                        bool _5812;
                        if (!_5805)
                        {
                            _5812 = _5804 > 1.0;
                        }
                        else
                        {
                            _5812 = _5805;
                        }
                        bool _5819;
                        if (!_5812)
                        {
                            _5819 = _5801.y < 0.0;
                        }
                        else
                        {
                            _5819 = _5812;
                        }
                        bool _5826;
                        if (!_5819)
                        {
                            _5826 = _5801.y > 1.0;
                        }
                        else
                        {
                            _5826 = _5819;
                        }
                        if (_5826)
                        {
                            _20882 = 1.0;
                            break;
                        }
                        float2 _5839 = float2(float(_5454 & 1), float(_5454 >> 1)) * _283._m23.xy;
                        float _5846 = fast::min(_5801.z, 1.0) - _283._m19[_5454];
                        float2 _5865 = _283._m22.xy * 0.5;
                        float2 _5870 = _5839 + (_5801.xy * _283._m23.xy);
                        float4 _5883 = float4(_5839 + _5865, (_5839 + _283._m23.xy) - _5865);
                        float _20881;
                        do
                        {
                            int _5909 = int(_283._m22.z);
                            if (_5909 <= 0)
                            {
                                _20881 = spvDepthCast(_303).sample_compare(_303Smplr, float3(fast::clamp(_5870, _5883.xy, _5883.zw), _5846).xy, _5846);
                                break;
                            }
                            float2 _5932 = (_5870 / _283._m22.xy) + float2(0.5);
                            float2 _5933 = floor(_5932);
                            float2 _5938 = _5932 - _5933;
                            float2 _5941 = _5933 - float2(0.5);
                            bool _5945 = _5909 == 1;
                            spvUnsafeArray<float2, 3> _5893;
                            spvUnsafeArray<float2, 3> _5894;
                            if (_5945)
                            {
                                float2 _5948 = _5938 * 2.0;
                                _5893[0] = float2(3.0) - _5948;
                                _5893[1] = float2(1.0) + _5948;
                                _5894[0] = ((float2(2.0) - _5938) / _5893[0]) - float2(1.0);
                                _5894[1] = (_5938 / _5893[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _5975 = _5938 * 3.0;
                                _5893[0] = float2(4.0) - _5975;
                                _5893[1] = float2(7.0);
                                _5893[2] = float2(1.0) + _5975;
                                _5894[0] = ((float2(3.0) - (_5938 * 2.0)) / _5893[0]) - float2(2.0);
                                _5894[1] = (float2(3.0) + _5938) / _5893[1];
                                _5894[2] = (_5938 / _5893[2]) + float2(2.0);
                            }
                            int _22262 = _5945 ? 2 : 3;
                            int _20871;
                            float _20874;
                            _20874 = 0.0;
                            _20871 = 0;
                            float _20880;
                            for (; _20871 < _22262; _20874 = _20880, _20871++)
                            {
                                _20880 = _20874;
                                for (int _20877 = 0; _20877 < _22262; )
                                {
                                    _20880 += ((_5893[_20877].x * _5893[_20871].y) * spvDepthCast(_303).sample_compare(_303Smplr, float3(fast::clamp(_283._m22.xy * (_5941 + float2(_5894[_20877].x, _5894[_20871].y)), _5883.xy, _5883.zw), _5846).xy, _5846));
                                    _20877++;
                                    continue;
                                }
                            }
                            _20881 = _20874 * (_5945 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _20882 = _20881;
                        break;
                    } while(false);
                    _20903 = mix(_20862, _20882, _5452);
                    _20900 = mix(_657[_20849], _657[_5454], float3(_5452));
                }
                else
                {
                    _20903 = mix(_20862, 1.0, _5452);
                    _20900 = _657[_20849];
                }
                _20902 = _20903;
                _20899 = _20900;
            }
            else
            {
                _20902 = _20862;
                _20899 = _657[_20849];
            }
            _20905 = select(float3(1.0), _20899, bool3(_283._m22.w > 0.5));
            _20904 = _20902;
            break;
        } while(false);
        _21068 = _20904;
        _21028 = _20934 * _20905;
    }
    else
    {
        _21068 = 1.0;
        _21028 = _20934;
    }
    float3 _3699 = _283._m5.xyz * _283._m4.w;
    bool _3703 = _2876._m6.w > 0.5;
    float _20957;
    if (_3703)
    {
        _20957 = 1.0;
    }
    else
    {
        _20957 = 1.0 + (_2876._m4.w * (_3352.sample(_2533, _3419).x - 1.0));
    }
    float _3723 = abs(in.m_2952.w);
    float _21158;
    if (_3723 > 0.0)
    {
        _21158 = _20957 * fast::min(_3723, 1.0);
    }
    else
    {
        _21158 = _20957;
    }
    float3 _21711;
    if (!_3620)
    {
        float _3739 = dot(_21034, _3650);
        bool _3764 = _283._m29.x > 0.5;
        float3 _21686;
        if (_3764)
        {
            float _6126 = (_283._m29.z * _21034.x) - (_283._m29.w * _21034.z);
            float _6139 = (_283._m29.w * _21034.x) + (_283._m29.z * _21034.z);
            float _6157 = 1.09254801273345947265625 * _6126;
            spvUnsafeArray<float, 9> _19399 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _21034.y, 0.48860299587249755859375 * _6139, 0.48860299587249755859375 * _6126, _6157 * _21034.y, (1.09254801273345947265625 * _21034.y) * _6139, 0.3153919875621795654296875 * (((3.0 * _6139) * _6139) - 1.0), _6157 * _6139, 0.546274006366729736328125 * ((_6126 * _6126) - (_21034.y * _21034.y)) });
            spvUnsafeArray<float, 9> _6071 = _19399;
            float3 _21685;
            _21685 = float3(0.0);
            for (int _21684 = 0; _21684 < 9; )
            {
                _21685 += (_2531.read(uint2((int2(496, 256) + int2(_21684, 0))), 0).xyz * _6071[_21684]);
                _21684++;
                continue;
            }
            _21686 = fast::max(_21685, float3(0.0)) * _283._m29.y;
        }
        else
        {
            _21686 = mix(_283._m9.xyz, _283._m8.xyz, float3((_21034.y * 0.5) + 0.5)) * _283._m8.w;
        }
        float3 _3789 = (_21028 * ((_21686 * _21158) + ((_3699 * fast::max(_3739, 0.0)) * _21068))) + ((_3699 * ((powr(fast::max(dot(_21034, _3662), 0.0), _2876._m1.w) * _2876._m1.z) * step(0.0, _3739))) * _21068);
        float3 _21713;
        if (_283._m34.y > 0.5)
        {
            float3 _21697;
            if (_3764)
            {
                float _6272 = (_283._m29.z * _21034.x) - (_283._m29.w * _21034.z);
                float _6285 = (_283._m29.w * _21034.x) + (_283._m29.z * _21034.z);
                float _6303 = 1.09254801273345947265625 * _6272;
                spvUnsafeArray<float, 9> _19380 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _21034.y, 0.48860299587249755859375 * _6285, 0.48860299587249755859375 * _6272, _6303 * _21034.y, (1.09254801273345947265625 * _21034.y) * _6285, 0.3153919875621795654296875 * (((3.0 * _6285) * _6285) - 1.0), _6303 * _6285, 0.546274006366729736328125 * ((_6272 * _6272) - (_21034.y * _21034.y)) });
                spvUnsafeArray<float, 9> _6217 = _19380;
                float3 _21696;
                _21696 = float3(0.0);
                for (int _21695 = 0; _21695 < 9; )
                {
                    _21696 += (_2531.read(uint2((int2(496, 256) + int2(_21695, 0))), 0).xyz * _6217[_21695]);
                    _21695++;
                    continue;
                }
                _21697 = fast::max(_21696, float3(0.0)) * _283._m29.y;
            }
            else
            {
                _21697 = mix(_283._m9.xyz, _283._m8.xyz, float3((_21034.y * 0.5) + 0.5)) * _283._m8.w;
            }
            int _6480 = int(_283._m34.y);
            int _6483 = int(_283._m34.x);
            float3 _21703;
            _21703 = _21697;
            float3 _22127;
            for (int _21702 = 0; _21702 < _6480; _21703 = _22127, _21702++)
            {
                int _6495 = 8 * (_6483 + _21702);
                float4 _6704 = as_type<float4>(_1281._m0[_6495 + 3]);
                float4 _6748 = as_type<float4>(_1281._m0[_6495]);
                float4 _6754 = as_type<float4>(_1281._m0[_6495 + 1]);
                float4 _6760 = as_type<float4>(_1281._m0[_6495 + 2]);
                float3 _6722 = _6748.xyz;
                float _6726 = _6748.w;
                float3 _6729 = _6754.xyz;
                float _6733 = _6754.w;
                float3 _6736 = _6760.xyz;
                float _6740 = _6760.w;
                float3 _6742 = float3(dot(_6722, in.m_3037) + _6726, dot(_6729, in.m_3037) + _6733, dot(_6736, in.m_3037) + _6740);
                float3 _6504 = _6704.xyz;
                float _6506 = _6704.w;
                float _22090;
                do
                {
                    float3 _6772 = _6504 - abs(_6742);
                    float _6780 = fast::min(_6772.x, fast::min(_6772.y, _6772.z));
                    if (_6780 <= 0.0)
                    {
                        _22090 = 0.0;
                        break;
                    }
                    if (_6506 <= 0.0)
                    {
                        _22090 = 1.0;
                        break;
                    }
                    float _6792 = fast::min(_6780 / _6506, 1.0);
                    _22090 = (_6792 * _6792) * (3.0 - (2.0 * _6792));
                    break;
                } while(false);
                if (_22090 <= 0.0)
                {
                    _22127 = _21703;
                    continue;
                }
                float3 _6515 = as_type<float4>(_1281._m0[_6495 + 4]).xyz;
                float4 _6813 = as_type<float4>(_1281._m0[_6495 + 5]);
                int _6819 = int(((device uint*)&_1281._m0[_6495 + 6])[0u]);
                float _6829 = dot(_6722, _21034);
                float _6835 = dot(_6729, _21034);
                float _6841 = dot(_6736, _21034);
                float3 _6842 = float3(_6829, _6835, _6841);
                float3 _6535 = (in.m_3037 + (_21034 * _6813.x)) + (_3657 * _6813.y);
                float3 _6554 = fast::clamp((((float3(dot(_6722, _6535) + _6726, dot(_6729, _6535) + _6733, dot(_6736, _6535) + _6740) + _6504) / fast::max(_6504 * 2.0, float3(9.9999999747524270787835121154785e-07))) * _6515) - float3(0.5), float3(0.0), _6515 - float3(1.0));
                int3 _6556 = int3(_6515);
                int3 _6563 = min(int3(_6554), max((_6556 - int3(2)), int3(0)));
                float3 _6567 = _6554 - float3(_6563);
                float _6922 = 0.48860299587249755859375 * _6835;
                float _6925 = 0.48860299587249755859375 * _6841;
                float _6928 = 0.48860299587249755859375 * _6829;
                float _6933 = 1.09254801273345947265625 * _6829;
                float _6936 = _6933 * _6835;
                float _6942 = (1.09254801273345947265625 * _6835) * _6841;
                float _6950 = 0.3153919875621795654296875 * (((3.0 * _6841) * _6841) - 1.0);
                float _6956 = _6933 * _6841;
                float _6970 = 0.546274006366729736328125 * ((_6829 * _6829) - (_6835 * _6835));
                int3 _6989 = _6556 - int3(1);
                int3 _6990 = min(_6563, _6989);
                int _6995 = _6556.x;
                int _6999 = _6556.y;
                int _7007 = _6819 + ((_6990.x + (_6995 * (_6990.y + (_6999 * _6990.z)))) * 4);
                float3 _7010 = float3(1.0) - _6567;
                float3 _7028 = (((((float3(_6990) + float3(0.5)) / _6515) * _6504) * 2.0) - _6504) - _6742;
                float _7038 = dot(_7028 * rsqrt(fast::max(dot(_7028, _7028), 1.0000000133514319600180897396058e-10)), _6842) + 1.0;
                float _7041 = _7010.x;
                float _7043 = _7010.y;
                float _7044 = _7041 * _7043;
                float _7046 = _7010.z;
                int _7070 = _7007 + 3;
                float _7056 = ((_7044 * _7046) * ((0.25 * (_7038 * _7038)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_7070])[1u])).y > 0.5);
                int _7100 = _7007 + 1;
                int _7104 = _7007 + 2;
                float2 _7116 = float2(as_type<half2>(_1281._m0[_7007].y));
                float2 _7125 = float2(as_type<half2>(_1281._m0[_7100].x));
                float2 _7134 = float2(as_type<half2>(_1281._m0[_7100].w));
                float2 _7143 = float2(as_type<half2>(_1281._m0[_7104].z));
                float3 _7231 = (((((((float3(float2(as_type<half2>(_1281._m0[_7007].x)), _7116.x) * 0.2820949852466583251953125) + (float3(_7116.y, float2(as_type<half2>(_1281._m0[_7007].z))) * _6922)) + (float3(float2(as_type<half2>(_1281._m0[_7007].w)), _7125.x) * _6925)) + (float3(_7125.y, float2(as_type<half2>(_1281._m0[_7100].y))) * _6928)) + (float3(float2(as_type<half2>(_1281._m0[_7100].z)), _7134.x) * _6936)) + (float3(_7134.y, float2(as_type<half2>(_1281._m0[_7104].x))) * _6942)) + (float3(float2(as_type<half2>(_1281._m0[_7104].y)), _7143.x) * _6950)) + (float3(_7143.y, float2(as_type<half2>(_1281._m0[_7104].w))) * _6956);
                int3 _7259 = min((_6563 + int3(1, 0, 0)), _6989);
                int _7276 = _6819 + ((_7259.x + (_6995 * (_7259.y + (_6999 * _7259.z)))) * 4);
                float3 _7297 = (((((float3(_7259) + float3(0.5)) / _6515) * _6504) * 2.0) - _6504) - _6742;
                float _7307 = dot(_7297 * rsqrt(fast::max(dot(_7297, _7297), 1.0000000133514319600180897396058e-10)), _6842) + 1.0;
                float _7313 = _6567.x * _7043;
                int _7339 = _7276 + 3;
                float _7325 = ((_7313 * _7046) * ((0.25 * (_7307 * _7307)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_7339])[1u])).y > 0.5);
                int _7369 = _7276 + 1;
                int _7373 = _7276 + 2;
                float2 _7385 = float2(as_type<half2>(_1281._m0[_7276].y));
                float2 _7394 = float2(as_type<half2>(_1281._m0[_7369].x));
                float2 _7403 = float2(as_type<half2>(_1281._m0[_7369].w));
                float2 _7412 = float2(as_type<half2>(_1281._m0[_7373].z));
                float3 _7500 = (((((((float3(float2(as_type<half2>(_1281._m0[_7276].x)), _7385.x) * 0.2820949852466583251953125) + (float3(_7385.y, float2(as_type<half2>(_1281._m0[_7276].z))) * _6922)) + (float3(float2(as_type<half2>(_1281._m0[_7276].w)), _7394.x) * _6925)) + (float3(_7394.y, float2(as_type<half2>(_1281._m0[_7369].y))) * _6928)) + (float3(float2(as_type<half2>(_1281._m0[_7369].z)), _7403.x) * _6936)) + (float3(_7403.y, float2(as_type<half2>(_1281._m0[_7373].x))) * _6942)) + (float3(float2(as_type<half2>(_1281._m0[_7373].y)), _7412.x) * _6950)) + (float3(_7412.y, float2(as_type<half2>(_1281._m0[_7373].w))) * _6956);
                int3 _7528 = min((_6563 + int3(0, 1, 0)), _6989);
                int _7545 = _6819 + ((_7528.x + (_6995 * (_7528.y + (_6999 * _7528.z)))) * 4);
                float3 _7566 = (((((float3(_7528) + float3(0.5)) / _6515) * _6504) * 2.0) - _6504) - _6742;
                float _7576 = dot(_7566 * rsqrt(fast::max(dot(_7566, _7566), 1.0000000133514319600180897396058e-10)), _6842) + 1.0;
                float _7582 = _7041 * _6567.y;
                int _7608 = _7545 + 3;
                float _7594 = ((_7582 * _7046) * ((0.25 * (_7576 * _7576)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_7608])[1u])).y > 0.5);
                int _7638 = _7545 + 1;
                int _7642 = _7545 + 2;
                float2 _7654 = float2(as_type<half2>(_1281._m0[_7545].y));
                float2 _7663 = float2(as_type<half2>(_1281._m0[_7638].x));
                float2 _7672 = float2(as_type<half2>(_1281._m0[_7638].w));
                float2 _7681 = float2(as_type<half2>(_1281._m0[_7642].z));
                float3 _7769 = (((((((float3(float2(as_type<half2>(_1281._m0[_7545].x)), _7654.x) * 0.2820949852466583251953125) + (float3(_7654.y, float2(as_type<half2>(_1281._m0[_7545].z))) * _6922)) + (float3(float2(as_type<half2>(_1281._m0[_7545].w)), _7663.x) * _6925)) + (float3(_7663.y, float2(as_type<half2>(_1281._m0[_7638].y))) * _6928)) + (float3(float2(as_type<half2>(_1281._m0[_7638].z)), _7672.x) * _6936)) + (float3(_7672.y, float2(as_type<half2>(_1281._m0[_7642].x))) * _6942)) + (float3(float2(as_type<half2>(_1281._m0[_7642].y)), _7681.x) * _6950)) + (float3(_7681.y, float2(as_type<half2>(_1281._m0[_7642].w))) * _6956);
                int3 _7797 = min((_6563 + int3(1, 1, 0)), _6989);
                int _7814 = _6819 + ((_7797.x + (_6995 * (_7797.y + (_6999 * _7797.z)))) * 4);
                float3 _7835 = (((((float3(_7797) + float3(0.5)) / _6515) * _6504) * 2.0) - _6504) - _6742;
                float _7845 = dot(_7835 * rsqrt(fast::max(dot(_7835, _7835), 1.0000000133514319600180897396058e-10)), _6842) + 1.0;
                float _7851 = _6567.x * _6567.y;
                int _7877 = _7814 + 3;
                float _7863 = ((_7851 * _7046) * ((0.25 * (_7845 * _7845)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_7877])[1u])).y > 0.5);
                int _7907 = _7814 + 1;
                int _7911 = _7814 + 2;
                float2 _7923 = float2(as_type<half2>(_1281._m0[_7814].y));
                float2 _7932 = float2(as_type<half2>(_1281._m0[_7907].x));
                float2 _7941 = float2(as_type<half2>(_1281._m0[_7907].w));
                float2 _7950 = float2(as_type<half2>(_1281._m0[_7911].z));
                float3 _8038 = (((((((float3(float2(as_type<half2>(_1281._m0[_7814].x)), _7923.x) * 0.2820949852466583251953125) + (float3(_7923.y, float2(as_type<half2>(_1281._m0[_7814].z))) * _6922)) + (float3(float2(as_type<half2>(_1281._m0[_7814].w)), _7932.x) * _6925)) + (float3(_7932.y, float2(as_type<half2>(_1281._m0[_7907].y))) * _6928)) + (float3(float2(as_type<half2>(_1281._m0[_7907].z)), _7941.x) * _6936)) + (float3(_7941.y, float2(as_type<half2>(_1281._m0[_7911].x))) * _6942)) + (float3(float2(as_type<half2>(_1281._m0[_7911].y)), _7950.x) * _6950)) + (float3(_7950.y, float2(as_type<half2>(_1281._m0[_7911].w))) * _6956);
                int3 _8066 = min((_6563 + int3(0, 0, 1)), _6989);
                int _8083 = _6819 + ((_8066.x + (_6995 * (_8066.y + (_6999 * _8066.z)))) * 4);
                float3 _8104 = (((((float3(_8066) + float3(0.5)) / _6515) * _6504) * 2.0) - _6504) - _6742;
                float _8114 = dot(_8104 * rsqrt(fast::max(dot(_8104, _8104), 1.0000000133514319600180897396058e-10)), _6842) + 1.0;
                int _8146 = _8083 + 3;
                float _8132 = ((_7044 * _6567.z) * ((0.25 * (_8114 * _8114)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_8146])[1u])).y > 0.5);
                int _8176 = _8083 + 1;
                int _8180 = _8083 + 2;
                float2 _8192 = float2(as_type<half2>(_1281._m0[_8083].y));
                float2 _8201 = float2(as_type<half2>(_1281._m0[_8176].x));
                float2 _8210 = float2(as_type<half2>(_1281._m0[_8176].w));
                float2 _8219 = float2(as_type<half2>(_1281._m0[_8180].z));
                float3 _8307 = (((((((float3(float2(as_type<half2>(_1281._m0[_8083].x)), _8192.x) * 0.2820949852466583251953125) + (float3(_8192.y, float2(as_type<half2>(_1281._m0[_8083].z))) * _6922)) + (float3(float2(as_type<half2>(_1281._m0[_8083].w)), _8201.x) * _6925)) + (float3(_8201.y, float2(as_type<half2>(_1281._m0[_8176].y))) * _6928)) + (float3(float2(as_type<half2>(_1281._m0[_8176].z)), _8210.x) * _6936)) + (float3(_8210.y, float2(as_type<half2>(_1281._m0[_8180].x))) * _6942)) + (float3(float2(as_type<half2>(_1281._m0[_8180].y)), _8219.x) * _6950)) + (float3(_8219.y, float2(as_type<half2>(_1281._m0[_8180].w))) * _6956);
                float4 _6634 = (((float4((_7231 + (float3(float2(as_type<half2>(_1281._m0[_7070].x)), float2(as_type<half2>(_1281._m0[_7070].y)).x) * _6970)) * _7056, _7056) + float4((_7500 + (float3(float2(as_type<half2>(_1281._m0[_7339].x)), float2(as_type<half2>(_1281._m0[_7339].y)).x) * _6970)) * _7325, _7325)) + float4((_7769 + (float3(float2(as_type<half2>(_1281._m0[_7608].x)), float2(as_type<half2>(_1281._m0[_7608].y)).x) * _6970)) * _7594, _7594)) + float4((_8038 + (float3(float2(as_type<half2>(_1281._m0[_7877].x)), float2(as_type<half2>(_1281._m0[_7877].y)).x) * _6970)) * _7863, _7863)) + float4((_8307 + (float3(float2(as_type<half2>(_1281._m0[_8146].x)), float2(as_type<half2>(_1281._m0[_8146].y)).x) * _6970)) * _8132, _8132);
                int3 _8335 = min((_6563 + int3(1, 0, 1)), _6989);
                int _8352 = _6819 + ((_8335.x + (_6995 * (_8335.y + (_6999 * _8335.z)))) * 4);
                float3 _8373 = (((((float3(_8335) + float3(0.5)) / _6515) * _6504) * 2.0) - _6504) - _6742;
                float _8383 = dot(_8373 * rsqrt(fast::max(dot(_8373, _8373), 1.0000000133514319600180897396058e-10)), _6842) + 1.0;
                int _8415 = _8352 + 3;
                float _8401 = ((_7313 * _6567.z) * ((0.25 * (_8383 * _8383)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_8415])[1u])).y > 0.5);
                int _8445 = _8352 + 1;
                int _8449 = _8352 + 2;
                float2 _8461 = float2(as_type<half2>(_1281._m0[_8352].y));
                float2 _8470 = float2(as_type<half2>(_1281._m0[_8445].x));
                float2 _8479 = float2(as_type<half2>(_1281._m0[_8445].w));
                float2 _8488 = float2(as_type<half2>(_1281._m0[_8449].z));
                float3 _8576 = (((((((float3(float2(as_type<half2>(_1281._m0[_8352].x)), _8461.x) * 0.2820949852466583251953125) + (float3(_8461.y, float2(as_type<half2>(_1281._m0[_8352].z))) * _6922)) + (float3(float2(as_type<half2>(_1281._m0[_8352].w)), _8470.x) * _6925)) + (float3(_8470.y, float2(as_type<half2>(_1281._m0[_8445].y))) * _6928)) + (float3(float2(as_type<half2>(_1281._m0[_8445].z)), _8479.x) * _6936)) + (float3(_8479.y, float2(as_type<half2>(_1281._m0[_8449].x))) * _6942)) + (float3(float2(as_type<half2>(_1281._m0[_8449].y)), _8488.x) * _6950)) + (float3(_8488.y, float2(as_type<half2>(_1281._m0[_8449].w))) * _6956);
                int3 _8604 = min((_6563 + int3(0, 1, 1)), _6989);
                int _8621 = _6819 + ((_8604.x + (_6995 * (_8604.y + (_6999 * _8604.z)))) * 4);
                float3 _8642 = (((((float3(_8604) + float3(0.5)) / _6515) * _6504) * 2.0) - _6504) - _6742;
                float _8652 = dot(_8642 * rsqrt(fast::max(dot(_8642, _8642), 1.0000000133514319600180897396058e-10)), _6842) + 1.0;
                int _8684 = _8621 + 3;
                float _8670 = ((_7582 * _6567.z) * ((0.25 * (_8652 * _8652)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_8684])[1u])).y > 0.5);
                int _8714 = _8621 + 1;
                int _8718 = _8621 + 2;
                float2 _8730 = float2(as_type<half2>(_1281._m0[_8621].y));
                float2 _8739 = float2(as_type<half2>(_1281._m0[_8714].x));
                float2 _8748 = float2(as_type<half2>(_1281._m0[_8714].w));
                float2 _8757 = float2(as_type<half2>(_1281._m0[_8718].z));
                float3 _8845 = (((((((float3(float2(as_type<half2>(_1281._m0[_8621].x)), _8730.x) * 0.2820949852466583251953125) + (float3(_8730.y, float2(as_type<half2>(_1281._m0[_8621].z))) * _6922)) + (float3(float2(as_type<half2>(_1281._m0[_8621].w)), _8739.x) * _6925)) + (float3(_8739.y, float2(as_type<half2>(_1281._m0[_8714].y))) * _6928)) + (float3(float2(as_type<half2>(_1281._m0[_8714].z)), _8748.x) * _6936)) + (float3(_8748.y, float2(as_type<half2>(_1281._m0[_8718].x))) * _6942)) + (float3(float2(as_type<half2>(_1281._m0[_8718].y)), _8757.x) * _6950)) + (float3(_8757.y, float2(as_type<half2>(_1281._m0[_8718].w))) * _6956);
                int3 _8873 = min((_6563 + int3(1)), _6989);
                int _8890 = _6819 + ((_8873.x + (_6995 * (_8873.y + (_6999 * _8873.z)))) * 4);
                float3 _8911 = (((((float3(_8873) + float3(0.5)) / _6515) * _6504) * 2.0) - _6504) - _6742;
                float _8921 = dot(_8911 * rsqrt(fast::max(dot(_8911, _8911), 1.0000000133514319600180897396058e-10)), _6842) + 1.0;
                int _8953 = _8890 + 3;
                float _8939 = ((_7851 * _6567.z) * ((0.25 * (_8921 * _8921)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_8953])[1u])).y > 0.5);
                int _8983 = _8890 + 1;
                int _8987 = _8890 + 2;
                float2 _8999 = float2(as_type<half2>(_1281._m0[_8890].y));
                float2 _9008 = float2(as_type<half2>(_1281._m0[_8983].x));
                float2 _9017 = float2(as_type<half2>(_1281._m0[_8983].w));
                float2 _9026 = float2(as_type<half2>(_1281._m0[_8987].z));
                float3 _9114 = (((((((float3(float2(as_type<half2>(_1281._m0[_8890].x)), _8999.x) * 0.2820949852466583251953125) + (float3(_8999.y, float2(as_type<half2>(_1281._m0[_8890].z))) * _6922)) + (float3(float2(as_type<half2>(_1281._m0[_8890].w)), _9008.x) * _6925)) + (float3(_9008.y, float2(as_type<half2>(_1281._m0[_8983].y))) * _6928)) + (float3(float2(as_type<half2>(_1281._m0[_8983].z)), _9017.x) * _6936)) + (float3(_9017.y, float2(as_type<half2>(_1281._m0[_8987].x))) * _6942)) + (float3(float2(as_type<half2>(_1281._m0[_8987].y)), _9026.x) * _6950)) + (float3(_9026.y, float2(as_type<half2>(_1281._m0[_8987].w))) * _6956);
                float4 _6673 = ((_6634 + float4((_8576 + (float3(float2(as_type<half2>(_1281._m0[_8415].x)), float2(as_type<half2>(_1281._m0[_8415].y)).x) * _6970)) * _8401, _8401)) + float4((_8845 + (float3(float2(as_type<half2>(_1281._m0[_8684].x)), float2(as_type<half2>(_1281._m0[_8684].y)).x) * _6970)) * _8670, _8670)) + float4((_9114 + (float3(float2(as_type<half2>(_1281._m0[_8953].x)), float2(as_type<half2>(_1281._m0[_8953].y)).x) * _6970)) * _8939, _8939);
                float _6677 = _6673.w;
                float3 _22128;
                if (_6677 > 9.9999997473787516355514526367188e-06)
                {
                    _22128 = mix(_21703, (fast::max(_6673.xyz, float3(0.0)) / float3(_6677)) * _6813.z, float3(_22090));
                }
                else
                {
                    _22128 = _21703;
                }
                _22127 = _22128;
            }
            _21713 = _3789 + ((_21028 * (_21703 - _21697)) * _21158);
        }
        else
        {
            _21713 = _3789;
        }
        float3 _21712;
        if (_283._m13.w > 0.5)
        {
            float2 _9152 = fast::clamp(floor(gl_FragCoord.xy * _283._m12.xy), float2(0.0), _283._m13.xy - float2(1.0));
            uint _9180 = uint((((fast::clamp(floor((log2(fast::max(dot(_283._m11.xyz, in.m_3037) + _283._m11.w, 9.9999999747524270787835121154785e-07)) * _283._m12.z) + _283._m12.w), 0.0, _283._m13.z - 1.0) * _283._m13.y) + _9152.y) * _283._m13.x) + _9152.x);
            uint _9182 = _9180 >> uint(2);
            uint _9184 = _9180 & 3u;
            uint _9188 = _3167._m0[_9182][_9184] & 65535u;
            uint _9190 = _3167._m0[_9182][_9184] >> uint(16);
            float3 _21714;
            _21714 = _21713;
            float3 _3906;
            spvUnsafeArray<float2, 3> _9598;
            spvUnsafeArray<float2, 3> _9599;
            spvUnsafeArray<float2, 3> _9811;
            spvUnsafeArray<float2, 3> _9812;
            for (uint _21710 = _9188; _21710 < (_9188 + _9190); _21714 = _3906, _21710++)
            {
                uint _9196 = _21710 / 3u;
                uint _9209 = (_3188._m0[_9196 >> uint(2)][_9196 & 3u] >> ((_21710 - (_9196 * 3u)) * 10u)) & 1023u;
                float3 _9226 = _3030._m0[_9209].xyz - in.m_3037;
                float _9229 = dot(_9226, _9226);
                float _9233 = _9229 * _3030._m0[_9209].w;
                float _9238 = fast::clamp(1.0 - (_9233 * _9233), 0.0, 1.0);
                float3 _9243 = _9226 * rsqrt(fast::max(_9229, 9.9999999392252902907785028219223e-09));
                float _9261 = fast::clamp((dot(-_9243, _3073._m0[_9209].xyz) * _3065._m0[_9209].w) + _3073._m0[_9209].w, 0.0, 1.0);
                float3 _9274 = _3065._m0[_9209].xyz * ((((_9238 * _9238) * _9261) * _9261) / fast::max(_9229, 9.9999997473787516355514526367188e-05));
                float3 _22055;
                if (_3673)
                {
                    float _22004;
                    do
                    {
                        uint _9310 = uint(_283._m21.z);
                        if (_9209 < _9310)
                        {
                            float _9332 = _283._m26[_9209].z * fast::max((_283._m15[_9209] * float4(in.m_3037, 1.0)).w, 0.0);
                            float4 _9356 = _283._m15[_9209] * float4((in.m_3037 + (_3668 * (_9332 * _283._m25.x))) + (_9243 * (_9332 * _283._m25.y)), 1.0);
                            float _9358 = _9356.w;
                            if (_9358 <= 0.0)
                            {
                                _22004 = 1.0;
                                break;
                            }
                            float3 _9367 = _9356.xyz / float3(_9358);
                            float _9369 = _9367.x;
                            bool _9370 = _9369 < 0.0;
                            bool _9377;
                            if (!_9370)
                            {
                                _9377 = _9369 > 1.0;
                            }
                            else
                            {
                                _9377 = _9370;
                            }
                            bool _9384;
                            if (!_9377)
                            {
                                _9384 = _9367.y < 0.0;
                            }
                            else
                            {
                                _9384 = _9377;
                            }
                            bool _9391;
                            if (!_9384)
                            {
                                _9391 = _9367.y > 1.0;
                            }
                            else
                            {
                                _9391 = _9384;
                            }
                            bool _9398;
                            if (!_9391)
                            {
                                _9398 = _9367.z > 1.0;
                            }
                            else
                            {
                                _9398 = _9391;
                            }
                            if (_9398)
                            {
                                _22004 = 1.0;
                                break;
                            }
                            float _9404 = _9367.z;
                            float2 _9570 = _283._m22.xy * 0.5;
                            float2 _9575 = _283._m26[_9209].xy + (_9367.xy * _283._m23.zw);
                            float4 _9588 = float4(_283._m26[_9209].xy + _9570, (_283._m26[_9209].xy + _283._m23.zw) - _9570);
                            float _22003;
                            do
                            {
                                int _9614 = int(_283._m22.z);
                                if (_9614 <= 0)
                                {
                                    float2 _9624 = fast::clamp(_9575, _9588.xy, _9588.zw);
                                    _22003 = spvDepthCast(_303).sample_compare(_303Smplr, float3(_9624, _9404).xy, _9404);
                                    break;
                                }
                                float2 _9637 = (_9575 / _283._m22.xy) + float2(0.5);
                                float2 _9638 = floor(_9637);
                                float2 _9643 = _9637 - _9638;
                                float2 _9646 = _9638 - float2(0.5);
                                bool _9650 = _9614 == 1;
                                if (_9650)
                                {
                                    float2 _9653 = _9643 * 2.0;
                                    _9598[0] = float2(3.0) - _9653;
                                    _9598[1] = float2(1.0) + _9653;
                                    _9599[0] = ((float2(2.0) - _9643) / _9598[0]) - float2(1.0);
                                    _9599[1] = (_9643 / _9598[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _9680 = _9643 * 3.0;
                                    _9598[0] = float2(4.0) - _9680;
                                    _9598[1] = float2(7.0);
                                    _9598[2] = float2(1.0) + _9680;
                                    _9599[0] = ((float2(3.0) - (_9643 * 2.0)) / _9598[0]) - float2(2.0);
                                    _9599[1] = (float2(3.0) + _9643) / _9598[1];
                                    _9599[2] = (_9643 / _9598[2]) + float2(2.0);
                                }
                                int _22267 = _9650 ? 2 : 3;
                                int _21993;
                                float _21996;
                                _21996 = 0.0;
                                _21993 = 0;
                                float _22002;
                                for (; _21993 < _22267; _21996 = _22002, _21993++)
                                {
                                    _22002 = _21996;
                                    for (int _21999 = 0; _21999 < _22267; )
                                    {
                                        _22002 += ((_9598[_21999].x * _9598[_21993].y) * spvDepthCast(_303).sample_compare(_303Smplr, float3(fast::clamp(_283._m22.xy * (_9646 + float2(_9599[_21999].x, _9599[_21993].y)), _9588.xy, _9588.zw), _9404).xy, _9404));
                                        _21999++;
                                        continue;
                                    }
                                }
                                _22003 = _21996 * (_9650 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _22004 = _22003;
                            break;
                        }
                        uint _9414 = _9209 - _9310;
                        if (_9414 >= uint(_283._m21.w))
                        {
                            _22004 = 1.0;
                            break;
                        }
                        float _9435 = _283._m27[_9414].w * length(in.m_3037 - _283._m27[_9414].xyz);
                        float3 _9453 = ((in.m_3037 + (_3668 * (_9435 * _283._m25.x))) + (_9243 * (_9435 * _283._m25.y))) - _283._m27[_9414].xyz;
                        float3 _9455 = abs(_9453);
                        float _9457 = _9455.x;
                        float _9459 = _9455.y;
                        bool _9460 = _9457 >= _9459;
                        bool _9468;
                        if (_9460)
                        {
                            _9468 = _9457 >= _9455.z;
                        }
                        else
                        {
                            _9468 = _9460;
                        }
                        float _21978;
                        int _21980;
                        if (_9468)
                        {
                            _21980 = (_9453.x > 0.0) ? 0 : 1;
                            _21978 = _9457;
                        }
                        else
                        {
                            float _9480 = _9455.z;
                            bool _9481 = _9459 >= _9480;
                            int _21981;
                            if (_9481)
                            {
                                _21981 = (_9453.y > 0.0) ? 2 : 3;
                            }
                            else
                            {
                                _21981 = (_9453.z > 0.0) ? 4 : 5;
                            }
                            _21980 = _21981;
                            _21978 = _9481 ? _9459 : _9480;
                        }
                        if (_21978 <= 0.0)
                        {
                            _22004 = 1.0;
                            break;
                        }
                        float2 _9518 = float2(dot(_9453, _961[_21980]), dot(_9453, _970[_21980])) / float2(_21978 * _283._m24.z);
                        float _9525 = _283._m28[_9414].z + (_283._m28[_9414].w / _21978);
                        if (_9525 > 1.0)
                        {
                            _22004 = 1.0;
                            break;
                        }
                        float2 _9543 = _283._m28[_9414].xy + (float2(float(spvSMod(_21980, 3)), float(_21980 / 3)) * _283._m24.xy);
                        float2 _9783 = _283._m22.xy * 0.5;
                        float2 _9788 = _9543 + (float2(0.5 + (0.5 * _9518.x), 0.5 - (0.5 * _9518.y)) * _283._m24.xy);
                        float4 _9801 = float4(_9543 + _9783, (_9543 + _283._m24.xy) - _9783);
                        float _21992;
                        do
                        {
                            int _9827 = int(_283._m22.z);
                            if (_9827 <= 0)
                            {
                                _21992 = spvDepthCast(_303).sample_compare(_303Smplr, float3(fast::clamp(_9788, _9801.xy, _9801.zw), _9525).xy, _9525);
                                break;
                            }
                            float2 _9850 = (_9788 / _283._m22.xy) + float2(0.5);
                            float2 _9851 = floor(_9850);
                            float2 _9856 = _9850 - _9851;
                            float2 _9859 = _9851 - float2(0.5);
                            bool _9863 = _9827 == 1;
                            if (_9863)
                            {
                                float2 _9866 = _9856 * 2.0;
                                _9811[0] = float2(3.0) - _9866;
                                _9811[1] = float2(1.0) + _9866;
                                _9812[0] = ((float2(2.0) - _9856) / _9811[0]) - float2(1.0);
                                _9812[1] = (_9856 / _9811[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _9893 = _9856 * 3.0;
                                _9811[0] = float2(4.0) - _9893;
                                _9811[1] = float2(7.0);
                                _9811[2] = float2(1.0) + _9893;
                                _9812[0] = ((float2(3.0) - (_9856 * 2.0)) / _9811[0]) - float2(2.0);
                                _9812[1] = (float2(3.0) + _9856) / _9811[1];
                                _9812[2] = (_9856 / _9811[2]) + float2(2.0);
                            }
                            int _22270 = _9863 ? 2 : 3;
                            int _21982;
                            float _21985;
                            _21985 = 0.0;
                            _21982 = 0;
                            float _21991;
                            for (; _21982 < _22270; _21985 = _21991, _21982++)
                            {
                                _21991 = _21985;
                                for (int _21988 = 0; _21988 < _22270; )
                                {
                                    _21991 += ((_9811[_21988].x * _9811[_21982].y) * spvDepthCast(_303).sample_compare(_303Smplr, float3(fast::clamp(_283._m22.xy * (_9859 + float2(_9812[_21988].x, _9812[_21982].y)), _9801.xy, _9801.zw), _9525).xy, _9525));
                                    _21988++;
                                    continue;
                                }
                            }
                            _21992 = _21985 * (_9863 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _22004 = _21992;
                        break;
                    } while(false);
                    _22055 = _9274 * _22004;
                }
                else
                {
                    _22055 = _9274;
                }
                float _3877 = dot(_21034, _9243);
                _3906 = _21714 + (((_21028 * fast::max(_3877, 0.0)) * _22055) + (_22055 * ((powr(fast::max(dot(_21034, fast::normalize(_9243 + _3657)), 0.0), _2876._m1.w) * _2876._m1.z) * step(0.0, _3877))));
            }
            _21712 = _21714;
        }
        else
        {
            _21712 = _21713;
        }
        _21711 = _21712;
    }
    else
    {
        float4 _3916 = _3911.sample(_2533, _3419);
        float _3923 = fast::clamp(_2876._m4.x * _3916.z, 0.0, 1.0);
        float _3931 = fast::clamp(_2876._m4.y * _3916.y, 0.04500000178813934326171875, 1.0);
        float _21024;
        float _21029;
        if (_20965 > 0.0)
        {
            _21029 = mix(_3923, _20998.y, _20965);
            _21024 = mix(_3931, fast::max(_20998.x, 0.04500000178813934326171875), _20965);
        }
        else
        {
            _21029 = _3923;
            _21024 = _3931;
        }
        float _3950 = _21024 * _21024;
        float3 _3955 = _21028 * (1.0 - _21029);
        float3 _3961 = mix(float3(0.039999999105930328369140625), _21028, float3(_21029));
        bool _3965 = _20844 > 0.0;
        float3 _21057;
        if (_3965)
        {
            float3 _3970 = dfdx(in.m_3037);
            float3 _3972 = dfdy(in.m_3037);
            float3 _3973 = cross(_3970, _3972);
            float3 _21058;
            if (dot(_3973, _3973) > 9.9999996826552253889678874634872e-21)
            {
                _21058 = fast::normalize((fast::normalize(_3973) * ((dot(_3973, _3657) < 0.0) ? (-1.0) : 1.0)) + (_21034 - _3513));
            }
            else
            {
                _21058 = _21034;
            }
            _21057 = _21058;
        }
        else
        {
            _21057 = _21034;
        }
        float _3999 = fast::max(dot(_21057, _3657), 9.9999997473787516355514526367188e-05);
        float _4008 = dot(_21057, _3650);
        float _4009 = fast::clamp(_4008, 0.0, 1.0);
        float _4014 = fast::clamp(dot(_21057, _3662), 0.0, 1.0);
        float _4019 = fast::clamp(dot(_3657, _3662), 0.0, 1.0);
        float _21061;
        float _21062;
        if (_3965)
        {
            _21062 = fast::max(_3999, 0.5);
            _21061 = fast::max(_4019, 0.5);
        }
        else
        {
            _21062 = _3999;
            _21061 = _4019;
        }
        float3 _9995 = float3(1.0) - _3961;
        float3 _9998 = _3961 + (_9995 * powr(1.0 - _21061, 5.0));
        float _10005 = _3950 * _3950;
        float _10010 = _10005 - 1.0;
        float _10012 = ((_4014 * _4014) * _10010) + 1.0;
        float _10032 = 1.0 - _10005;
        float _10036 = sqrt(((_21062 * _21062) * _10032) + _10005);
        float3 _4065 = (((((float3(1.0) - _9998) * _3955) * fast::clamp(dot(_21034, _3650), 0.0, 1.0)) + (((_9998 * ((_10005 / ((3.1415927410125732421875 * _10012) * _10012)) * (0.5 / fast::max((_4009 * _10036) + (_21062 * sqrt(((_4009 * _4009) * _10032) + _10005)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875) * _4009)) * _3699) * _21068;
        float3 _21172;
        if (_3965)
        {
            _21172 = _4065 + (((((_3955 * _3699) * _21068) * _20844) * fast::clamp(-_4008, 0.0, 1.0)) * (0.3499999940395355224609375 + (0.64999997615814208984375 * powr(fast::clamp(dot(-_3657, _3650), 0.0, 1.0), 3.0))));
        }
        else
        {
            _21172 = _4065;
        }
        bool _4100 = _283._m29.x > 0.5;
        float3 _21098;
        float2 _21122;
        float3 _21134;
        if (_4100)
        {
            float4 _10069 = _2632.sample(_2634, (((float2(_21062, _21024) * 31.0) + float2(0.5)) * float2(0.03125)));
            float _10128 = (_283._m29.z * _21034.x) - (_283._m29.w * _21034.z);
            float _10141 = (_283._m29.w * _21034.x) + (_283._m29.z * _21034.z);
            float _10159 = 1.09254801273345947265625 * _10128;
            spvUnsafeArray<float, 9> _19242 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _21034.y, 0.48860299587249755859375 * _10141, 0.48860299587249755859375 * _10128, _10159 * _21034.y, (1.09254801273345947265625 * _21034.y) * _10141, 0.3153919875621795654296875 * (((3.0 * _10141) * _10141) - 1.0), _10159 * _10141, 0.546274006366729736328125 * ((_10128 * _10128) - (_21034.y * _21034.y)) });
            spvUnsafeArray<float, 9> _10073 = _19242;
            float3 _21080;
            _21080 = float3(0.0);
            for (int _21079 = 0; _21079 < 9; )
            {
                _21080 += (_2531.read(uint2((int2(496, 256) + int2(_21079, 0))), 0).xyz * _10073[_21079]);
                _21079++;
                continue;
            }
            float3 _4117 = reflect(-_3657, _21057);
            float _10254 = _4117.x;
            float _10259 = _4117.z;
            float2 _10291 = float2((precise::atan2((_283._m29.z * _10254) - (_283._m29.w * _10259), -((_283._m29.w * _10254) + (_283._m29.z * _10259))) * 0.15915493667125701904296875) + 0.5, acos(fast::clamp(_4117.y, -1.0, 1.0)) * 0.3183098733425140380859375);
            float _10223 = _21024 * 5.0;
            int _10226 = min(int(_10223), 4);
            float2 _10312 = (_10291 * float2(_2588[_10226].zw)) - float2(0.5);
            float2 _10314 = floor(_10312);
            float2 _10317 = _10312 - _10314;
            int _10320 = int(_10314.x);
            int _10323 = int(_10314.y);
            int _21083;
            if (_10320 < 0)
            {
                _21083 = _10320 + _2588[_10226].z;
            }
            else
            {
                _21083 = _10320;
            }
            int _21084;
            if (_21083 >= _2588[_10226].z)
            {
                _21084 = _21083 - _2588[_10226].z;
            }
            else
            {
                _21084 = _21083;
            }
            int _10343 = _21084 + 1;
            int _22271 = (_10343 == _2588[_10226].z) ? 0 : _10343;
            int _10358 = min((_10323 + 1), (_2588[_10226].w - 1));
            int _10360 = max(_10323, 0);
            float3 _10413 = float3(_10317.x);
            int _10233 = _10226 + 1;
            float2 _10445 = (_10291 * float2(_2588[_10233].zw)) - float2(0.5);
            float2 _10447 = floor(_10445);
            float2 _10450 = _10445 - _10447;
            int _10453 = int(_10447.x);
            int _10456 = int(_10447.y);
            int _21090;
            if (_10453 < 0)
            {
                _21090 = _10453 + _2588[_10233].z;
            }
            else
            {
                _21090 = _10453;
            }
            int _21091;
            if (_21090 >= _2588[_10233].z)
            {
                _21091 = _21090 - _2588[_10233].z;
            }
            else
            {
                _21091 = _21090;
            }
            int _10476 = _21091 + 1;
            int _22272 = (_10476 == _2588[_10233].z) ? 0 : _10476;
            int _10491 = min((_10456 + 1), (_2588[_10233].w - 1));
            int _10493 = max(_10456, 0);
            float3 _10546 = float3(_10450.x);
            float3 _10248 = mix(mix(mix(_2531.read(uint2((_2588[_10226].xy + int2(_21084, _10360))), 0).xyz, _2531.read(uint2((_2588[_10226].xy + int2(_22271, _10360))), 0).xyz, _10413), mix(_2531.read(uint2((_2588[_10226].xy + int2(_21084, _10358))), 0).xyz, _2531.read(uint2((_2588[_10226].xy + int2(_22271, _10358))), 0).xyz, _10413), float3(_10317.y)), mix(mix(_2531.read(uint2((_2588[_10233].xy + int2(_21091, _10493))), 0).xyz, _2531.read(uint2((_2588[_10233].xy + int2(_22272, _10493))), 0).xyz, _10546), mix(_2531.read(uint2((_2588[_10233].xy + int2(_21091, _10491))), 0).xyz, _2531.read(uint2((_2588[_10233].xy + int2(_22272, _10491))), 0).xyz, _10546), float3(_10450.y)), float3(_10223 - float(_10226))) * _283._m29.y;
            _21134 = fast::max(_21080, float3(0.0)) * _283._m29.y;
            _21122 = _10069.xy;
            _21098 = _10248;
        }
        else
        {
            float4 _10564 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * _21024) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);
            float _10566 = _10564.x;
            float3 _10601 = mix(_283._m9.xyz, _283._m8.xyz, float3((_21034.y * 0.5) + 0.5)) * _283._m8.w;
            _21134 = _10601;
            _21122 = (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_10566 * _10566, exp2((-9.27999973297119140625) * _21062)) * _10566) + _10564.y)) + _10564.zw;
            _21098 = mix(mix(_283._m9.xyz, _283._m8.xyz, float3((reflect(-_3657, _21057).y * 0.5) + 0.5)) * _283._m8.w, _10601, float3(_21024));
        }
        bool _4149;
        if (_3703)
        {
            _4149 = _283._m33.z > 0.5;
        }
        else
        {
            _4149 = _3703;
        }
        float3 _21143;
        if (_4149)
        {
            float3 _21119;
            do
            {
                float _10680 = ((_283._m32.x * (1.0 - smoothstep(_283._m33.x * 0.5, _283._m33.x, abs(dot(_283._m31.xyz, in.m_3037) - _283._m31.w)))) * smoothstep(0.5, 0.89999997615814208984375, dot(_3668, _283._m31.xyz))) * (1.0 - smoothstep(_283._m32.y * 0.5, _283._m32.y, _21024));
                if (_10680 <= 0.0)
                {
                    _21119 = _21098;
                    break;
                }
                float4 _10705 = _283._m30 * float4(in.m_3037 + ((_21034 - (_283._m31.xyz * dot(_21034, _283._m31.xyz))) * _283._m32.w), 1.0);
                float2 _10718 = ((float2(_10705.x, -_10705.y) / float2(_10705.w)) * 0.5) + float2(0.5);
                float _10722 = _283._m32.z * _21024;
                float3 _21117;
                float _21118;
                _21118 = 0.0;
                _21117 = float3(0.0);
                for (int _21116 = 0; _21116 < 12; )
                {
                    float _10729 = float(_21116);
                    float _10737 = _10729 * 2.3999631404876708984375;
                    float2 _10749 = _10718 + (float2(cos(_10737) * _283._m33.y, sin(_10737)) * (sqrt((_10729 + 0.5) * 0.083333335816860198974609375) * _10722));
                    float2 _10754 = fast::min(_10749, float2(1.0) - _10749);
                    float _10760 = smoothstep(0.0, 0.039999999105930328369140625, fast::min(_10754.x, _10754.y));
                    float4 _10768 = _3352.sample(_2533, fast::clamp(_10749, float2(0.0), float2(1.0)), level(0.0));
                    float3 _10770 = _10768.xyz;
                    _21118 += (_10768.w * _10760);
                    _21117 += ((_10770 / (float3(1.0) - fast::min(_10770, float3(0.99500000476837158203125)))) * _10760);
                    _21116++;
                    continue;
                }
                _21119 = mix(_21098, (_21117 * float3(0.083333335816860198974609375)) + (_21098 * (1.0 - (_21118 * 0.083333335816860198974609375))), float3(_10680));
                break;
            } while(false);
            _21143 = _21119;
        }
        else
        {
            _21143 = _21098;
        }
        float3 _4169 = (_3961 * _21122.x) + float3(_21122.y);
        float3 _4174 = (float3(1.0) - _4169) * _3955;
        float3 _4185 = _21172 + (((_4174 * _21134) + (_4169 * _21143)) * _21158);
        float3 _21645;
        if ((_283._m34.x + _283._m34.y) > 0.5)
        {
            float3 _21180;
            if (_283._m34.y > 0.5)
            {
                int _10926 = int(_283._m34.y);
                int _10929 = int(_283._m34.x);
                float3 _21179;
                _21179 = _21134;
                float3 _22097;
                for (int _21178 = 0; _21178 < _10926; _21179 = _22097, _21178++)
                {
                    int _10941 = 8 * (_10929 + _21178);
                    float4 _11150 = as_type<float4>(_1281._m0[_10941 + 3]);
                    float4 _11194 = as_type<float4>(_1281._m0[_10941]);
                    float4 _11200 = as_type<float4>(_1281._m0[_10941 + 1]);
                    float4 _11206 = as_type<float4>(_1281._m0[_10941 + 2]);
                    float3 _11168 = _11194.xyz;
                    float _11172 = _11194.w;
                    float3 _11175 = _11200.xyz;
                    float _11179 = _11200.w;
                    float3 _11182 = _11206.xyz;
                    float _11186 = _11206.w;
                    float3 _11188 = float3(dot(_11168, in.m_3037) + _11172, dot(_11175, in.m_3037) + _11179, dot(_11182, in.m_3037) + _11186);
                    float3 _10950 = _11150.xyz;
                    float _10952 = _11150.w;
                    float _21679;
                    do
                    {
                        float3 _11218 = _10950 - abs(_11188);
                        float _11226 = fast::min(_11218.x, fast::min(_11218.y, _11218.z));
                        if (_11226 <= 0.0)
                        {
                            _21679 = 0.0;
                            break;
                        }
                        if (_10952 <= 0.0)
                        {
                            _21679 = 1.0;
                            break;
                        }
                        float _11238 = fast::min(_11226 / _10952, 1.0);
                        _21679 = (_11238 * _11238) * (3.0 - (2.0 * _11238));
                        break;
                    } while(false);
                    if (_21679 <= 0.0)
                    {
                        _22097 = _21179;
                        continue;
                    }
                    float3 _10961 = as_type<float4>(_1281._m0[_10941 + 4]).xyz;
                    float4 _11259 = as_type<float4>(_1281._m0[_10941 + 5]);
                    int _11265 = int(((device uint*)&_1281._m0[_10941 + 6])[0u]);
                    float _11275 = dot(_11168, _21034);
                    float _11281 = dot(_11175, _21034);
                    float _11287 = dot(_11182, _21034);
                    float3 _11288 = float3(_11275, _11281, _11287);
                    float3 _10981 = (in.m_3037 + (_21034 * _11259.x)) + (_3657 * _11259.y);
                    float3 _11000 = fast::clamp((((float3(dot(_11168, _10981) + _11172, dot(_11175, _10981) + _11179, dot(_11182, _10981) + _11186) + _10950) / fast::max(_10950 * 2.0, float3(9.9999999747524270787835121154785e-07))) * _10961) - float3(0.5), float3(0.0), _10961 - float3(1.0));
                    int3 _11002 = int3(_10961);
                    int3 _11009 = min(int3(_11000), max((_11002 - int3(2)), int3(0)));
                    float3 _11013 = _11000 - float3(_11009);
                    float _11368 = 0.48860299587249755859375 * _11281;
                    float _11371 = 0.48860299587249755859375 * _11287;
                    float _11374 = 0.48860299587249755859375 * _11275;
                    float _11379 = 1.09254801273345947265625 * _11275;
                    float _11382 = _11379 * _11281;
                    float _11388 = (1.09254801273345947265625 * _11281) * _11287;
                    float _11396 = 0.3153919875621795654296875 * (((3.0 * _11287) * _11287) - 1.0);
                    float _11402 = _11379 * _11287;
                    float _11416 = 0.546274006366729736328125 * ((_11275 * _11275) - (_11281 * _11281));
                    int3 _11435 = _11002 - int3(1);
                    int3 _11436 = min(_11009, _11435);
                    int _11441 = _11002.x;
                    int _11445 = _11002.y;
                    int _11453 = _11265 + ((_11436.x + (_11441 * (_11436.y + (_11445 * _11436.z)))) * 4);
                    float3 _11456 = float3(1.0) - _11013;
                    float3 _11474 = (((((float3(_11436) + float3(0.5)) / _10961) * _10950) * 2.0) - _10950) - _11188;
                    float _11484 = dot(_11474 * rsqrt(fast::max(dot(_11474, _11474), 1.0000000133514319600180897396058e-10)), _11288) + 1.0;
                    float _11487 = _11456.x;
                    float _11489 = _11456.y;
                    float _11490 = _11487 * _11489;
                    float _11492 = _11456.z;
                    int _11516 = _11453 + 3;
                    float _11502 = ((_11490 * _11492) * ((0.25 * (_11484 * _11484)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_11516])[1u])).y > 0.5);
                    int _11546 = _11453 + 1;
                    int _11550 = _11453 + 2;
                    float2 _11562 = float2(as_type<half2>(_1281._m0[_11453].y));
                    float2 _11571 = float2(as_type<half2>(_1281._m0[_11546].x));
                    float2 _11580 = float2(as_type<half2>(_1281._m0[_11546].w));
                    float2 _11589 = float2(as_type<half2>(_1281._m0[_11550].z));
                    float3 _11677 = (((((((float3(float2(as_type<half2>(_1281._m0[_11453].x)), _11562.x) * 0.2820949852466583251953125) + (float3(_11562.y, float2(as_type<half2>(_1281._m0[_11453].z))) * _11368)) + (float3(float2(as_type<half2>(_1281._m0[_11453].w)), _11571.x) * _11371)) + (float3(_11571.y, float2(as_type<half2>(_1281._m0[_11546].y))) * _11374)) + (float3(float2(as_type<half2>(_1281._m0[_11546].z)), _11580.x) * _11382)) + (float3(_11580.y, float2(as_type<half2>(_1281._m0[_11550].x))) * _11388)) + (float3(float2(as_type<half2>(_1281._m0[_11550].y)), _11589.x) * _11396)) + (float3(_11589.y, float2(as_type<half2>(_1281._m0[_11550].w))) * _11402);
                    int3 _11705 = min((_11009 + int3(1, 0, 0)), _11435);
                    int _11722 = _11265 + ((_11705.x + (_11441 * (_11705.y + (_11445 * _11705.z)))) * 4);
                    float3 _11743 = (((((float3(_11705) + float3(0.5)) / _10961) * _10950) * 2.0) - _10950) - _11188;
                    float _11753 = dot(_11743 * rsqrt(fast::max(dot(_11743, _11743), 1.0000000133514319600180897396058e-10)), _11288) + 1.0;
                    float _11759 = _11013.x * _11489;
                    int _11785 = _11722 + 3;
                    float _11771 = ((_11759 * _11492) * ((0.25 * (_11753 * _11753)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_11785])[1u])).y > 0.5);
                    int _11815 = _11722 + 1;
                    int _11819 = _11722 + 2;
                    float2 _11831 = float2(as_type<half2>(_1281._m0[_11722].y));
                    float2 _11840 = float2(as_type<half2>(_1281._m0[_11815].x));
                    float2 _11849 = float2(as_type<half2>(_1281._m0[_11815].w));
                    float2 _11858 = float2(as_type<half2>(_1281._m0[_11819].z));
                    float3 _11946 = (((((((float3(float2(as_type<half2>(_1281._m0[_11722].x)), _11831.x) * 0.2820949852466583251953125) + (float3(_11831.y, float2(as_type<half2>(_1281._m0[_11722].z))) * _11368)) + (float3(float2(as_type<half2>(_1281._m0[_11722].w)), _11840.x) * _11371)) + (float3(_11840.y, float2(as_type<half2>(_1281._m0[_11815].y))) * _11374)) + (float3(float2(as_type<half2>(_1281._m0[_11815].z)), _11849.x) * _11382)) + (float3(_11849.y, float2(as_type<half2>(_1281._m0[_11819].x))) * _11388)) + (float3(float2(as_type<half2>(_1281._m0[_11819].y)), _11858.x) * _11396)) + (float3(_11858.y, float2(as_type<half2>(_1281._m0[_11819].w))) * _11402);
                    int3 _11974 = min((_11009 + int3(0, 1, 0)), _11435);
                    int _11991 = _11265 + ((_11974.x + (_11441 * (_11974.y + (_11445 * _11974.z)))) * 4);
                    float3 _12012 = (((((float3(_11974) + float3(0.5)) / _10961) * _10950) * 2.0) - _10950) - _11188;
                    float _12022 = dot(_12012 * rsqrt(fast::max(dot(_12012, _12012), 1.0000000133514319600180897396058e-10)), _11288) + 1.0;
                    float _12028 = _11487 * _11013.y;
                    int _12054 = _11991 + 3;
                    float _12040 = ((_12028 * _11492) * ((0.25 * (_12022 * _12022)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_12054])[1u])).y > 0.5);
                    int _12084 = _11991 + 1;
                    int _12088 = _11991 + 2;
                    float2 _12100 = float2(as_type<half2>(_1281._m0[_11991].y));
                    float2 _12109 = float2(as_type<half2>(_1281._m0[_12084].x));
                    float2 _12118 = float2(as_type<half2>(_1281._m0[_12084].w));
                    float2 _12127 = float2(as_type<half2>(_1281._m0[_12088].z));
                    float3 _12215 = (((((((float3(float2(as_type<half2>(_1281._m0[_11991].x)), _12100.x) * 0.2820949852466583251953125) + (float3(_12100.y, float2(as_type<half2>(_1281._m0[_11991].z))) * _11368)) + (float3(float2(as_type<half2>(_1281._m0[_11991].w)), _12109.x) * _11371)) + (float3(_12109.y, float2(as_type<half2>(_1281._m0[_12084].y))) * _11374)) + (float3(float2(as_type<half2>(_1281._m0[_12084].z)), _12118.x) * _11382)) + (float3(_12118.y, float2(as_type<half2>(_1281._m0[_12088].x))) * _11388)) + (float3(float2(as_type<half2>(_1281._m0[_12088].y)), _12127.x) * _11396)) + (float3(_12127.y, float2(as_type<half2>(_1281._m0[_12088].w))) * _11402);
                    int3 _12243 = min((_11009 + int3(1, 1, 0)), _11435);
                    int _12260 = _11265 + ((_12243.x + (_11441 * (_12243.y + (_11445 * _12243.z)))) * 4);
                    float3 _12281 = (((((float3(_12243) + float3(0.5)) / _10961) * _10950) * 2.0) - _10950) - _11188;
                    float _12291 = dot(_12281 * rsqrt(fast::max(dot(_12281, _12281), 1.0000000133514319600180897396058e-10)), _11288) + 1.0;
                    float _12297 = _11013.x * _11013.y;
                    int _12323 = _12260 + 3;
                    float _12309 = ((_12297 * _11492) * ((0.25 * (_12291 * _12291)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_12323])[1u])).y > 0.5);
                    int _12353 = _12260 + 1;
                    int _12357 = _12260 + 2;
                    float2 _12369 = float2(as_type<half2>(_1281._m0[_12260].y));
                    float2 _12378 = float2(as_type<half2>(_1281._m0[_12353].x));
                    float2 _12387 = float2(as_type<half2>(_1281._m0[_12353].w));
                    float2 _12396 = float2(as_type<half2>(_1281._m0[_12357].z));
                    float3 _12484 = (((((((float3(float2(as_type<half2>(_1281._m0[_12260].x)), _12369.x) * 0.2820949852466583251953125) + (float3(_12369.y, float2(as_type<half2>(_1281._m0[_12260].z))) * _11368)) + (float3(float2(as_type<half2>(_1281._m0[_12260].w)), _12378.x) * _11371)) + (float3(_12378.y, float2(as_type<half2>(_1281._m0[_12353].y))) * _11374)) + (float3(float2(as_type<half2>(_1281._m0[_12353].z)), _12387.x) * _11382)) + (float3(_12387.y, float2(as_type<half2>(_1281._m0[_12357].x))) * _11388)) + (float3(float2(as_type<half2>(_1281._m0[_12357].y)), _12396.x) * _11396)) + (float3(_12396.y, float2(as_type<half2>(_1281._m0[_12357].w))) * _11402);
                    int3 _12512 = min((_11009 + int3(0, 0, 1)), _11435);
                    int _12529 = _11265 + ((_12512.x + (_11441 * (_12512.y + (_11445 * _12512.z)))) * 4);
                    float3 _12550 = (((((float3(_12512) + float3(0.5)) / _10961) * _10950) * 2.0) - _10950) - _11188;
                    float _12560 = dot(_12550 * rsqrt(fast::max(dot(_12550, _12550), 1.0000000133514319600180897396058e-10)), _11288) + 1.0;
                    int _12592 = _12529 + 3;
                    float _12578 = ((_11490 * _11013.z) * ((0.25 * (_12560 * _12560)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_12592])[1u])).y > 0.5);
                    int _12622 = _12529 + 1;
                    int _12626 = _12529 + 2;
                    float2 _12638 = float2(as_type<half2>(_1281._m0[_12529].y));
                    float2 _12647 = float2(as_type<half2>(_1281._m0[_12622].x));
                    float2 _12656 = float2(as_type<half2>(_1281._m0[_12622].w));
                    float2 _12665 = float2(as_type<half2>(_1281._m0[_12626].z));
                    float3 _12753 = (((((((float3(float2(as_type<half2>(_1281._m0[_12529].x)), _12638.x) * 0.2820949852466583251953125) + (float3(_12638.y, float2(as_type<half2>(_1281._m0[_12529].z))) * _11368)) + (float3(float2(as_type<half2>(_1281._m0[_12529].w)), _12647.x) * _11371)) + (float3(_12647.y, float2(as_type<half2>(_1281._m0[_12622].y))) * _11374)) + (float3(float2(as_type<half2>(_1281._m0[_12622].z)), _12656.x) * _11382)) + (float3(_12656.y, float2(as_type<half2>(_1281._m0[_12626].x))) * _11388)) + (float3(float2(as_type<half2>(_1281._m0[_12626].y)), _12665.x) * _11396)) + (float3(_12665.y, float2(as_type<half2>(_1281._m0[_12626].w))) * _11402);
                    float4 _11080 = (((float4((_11677 + (float3(float2(as_type<half2>(_1281._m0[_11516].x)), float2(as_type<half2>(_1281._m0[_11516].y)).x) * _11416)) * _11502, _11502) + float4((_11946 + (float3(float2(as_type<half2>(_1281._m0[_11785].x)), float2(as_type<half2>(_1281._m0[_11785].y)).x) * _11416)) * _11771, _11771)) + float4((_12215 + (float3(float2(as_type<half2>(_1281._m0[_12054].x)), float2(as_type<half2>(_1281._m0[_12054].y)).x) * _11416)) * _12040, _12040)) + float4((_12484 + (float3(float2(as_type<half2>(_1281._m0[_12323].x)), float2(as_type<half2>(_1281._m0[_12323].y)).x) * _11416)) * _12309, _12309)) + float4((_12753 + (float3(float2(as_type<half2>(_1281._m0[_12592].x)), float2(as_type<half2>(_1281._m0[_12592].y)).x) * _11416)) * _12578, _12578);
                    int3 _12781 = min((_11009 + int3(1, 0, 1)), _11435);
                    int _12798 = _11265 + ((_12781.x + (_11441 * (_12781.y + (_11445 * _12781.z)))) * 4);
                    float3 _12819 = (((((float3(_12781) + float3(0.5)) / _10961) * _10950) * 2.0) - _10950) - _11188;
                    float _12829 = dot(_12819 * rsqrt(fast::max(dot(_12819, _12819), 1.0000000133514319600180897396058e-10)), _11288) + 1.0;
                    int _12861 = _12798 + 3;
                    float _12847 = ((_11759 * _11013.z) * ((0.25 * (_12829 * _12829)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_12861])[1u])).y > 0.5);
                    int _12891 = _12798 + 1;
                    int _12895 = _12798 + 2;
                    float2 _12907 = float2(as_type<half2>(_1281._m0[_12798].y));
                    float2 _12916 = float2(as_type<half2>(_1281._m0[_12891].x));
                    float2 _12925 = float2(as_type<half2>(_1281._m0[_12891].w));
                    float2 _12934 = float2(as_type<half2>(_1281._m0[_12895].z));
                    float3 _13022 = (((((((float3(float2(as_type<half2>(_1281._m0[_12798].x)), _12907.x) * 0.2820949852466583251953125) + (float3(_12907.y, float2(as_type<half2>(_1281._m0[_12798].z))) * _11368)) + (float3(float2(as_type<half2>(_1281._m0[_12798].w)), _12916.x) * _11371)) + (float3(_12916.y, float2(as_type<half2>(_1281._m0[_12891].y))) * _11374)) + (float3(float2(as_type<half2>(_1281._m0[_12891].z)), _12925.x) * _11382)) + (float3(_12925.y, float2(as_type<half2>(_1281._m0[_12895].x))) * _11388)) + (float3(float2(as_type<half2>(_1281._m0[_12895].y)), _12934.x) * _11396)) + (float3(_12934.y, float2(as_type<half2>(_1281._m0[_12895].w))) * _11402);
                    int3 _13050 = min((_11009 + int3(0, 1, 1)), _11435);
                    int _13067 = _11265 + ((_13050.x + (_11441 * (_13050.y + (_11445 * _13050.z)))) * 4);
                    float3 _13088 = (((((float3(_13050) + float3(0.5)) / _10961) * _10950) * 2.0) - _10950) - _11188;
                    float _13098 = dot(_13088 * rsqrt(fast::max(dot(_13088, _13088), 1.0000000133514319600180897396058e-10)), _11288) + 1.0;
                    int _13130 = _13067 + 3;
                    float _13116 = ((_12028 * _11013.z) * ((0.25 * (_13098 * _13098)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_13130])[1u])).y > 0.5);
                    int _13160 = _13067 + 1;
                    int _13164 = _13067 + 2;
                    float2 _13176 = float2(as_type<half2>(_1281._m0[_13067].y));
                    float2 _13185 = float2(as_type<half2>(_1281._m0[_13160].x));
                    float2 _13194 = float2(as_type<half2>(_1281._m0[_13160].w));
                    float2 _13203 = float2(as_type<half2>(_1281._m0[_13164].z));
                    float3 _13291 = (((((((float3(float2(as_type<half2>(_1281._m0[_13067].x)), _13176.x) * 0.2820949852466583251953125) + (float3(_13176.y, float2(as_type<half2>(_1281._m0[_13067].z))) * _11368)) + (float3(float2(as_type<half2>(_1281._m0[_13067].w)), _13185.x) * _11371)) + (float3(_13185.y, float2(as_type<half2>(_1281._m0[_13160].y))) * _11374)) + (float3(float2(as_type<half2>(_1281._m0[_13160].z)), _13194.x) * _11382)) + (float3(_13194.y, float2(as_type<half2>(_1281._m0[_13164].x))) * _11388)) + (float3(float2(as_type<half2>(_1281._m0[_13164].y)), _13203.x) * _11396)) + (float3(_13203.y, float2(as_type<half2>(_1281._m0[_13164].w))) * _11402);
                    int3 _13319 = min((_11009 + int3(1)), _11435);
                    int _13336 = _11265 + ((_13319.x + (_11441 * (_13319.y + (_11445 * _13319.z)))) * 4);
                    float3 _13357 = (((((float3(_13319) + float3(0.5)) / _10961) * _10950) * 2.0) - _10950) - _11188;
                    float _13367 = dot(_13357 * rsqrt(fast::max(dot(_13357, _13357), 1.0000000133514319600180897396058e-10)), _11288) + 1.0;
                    int _13399 = _13336 + 3;
                    float _13385 = ((_12297 * _11013.z) * ((0.25 * (_13367 * _13367)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_13399])[1u])).y > 0.5);
                    int _13429 = _13336 + 1;
                    int _13433 = _13336 + 2;
                    float2 _13445 = float2(as_type<half2>(_1281._m0[_13336].y));
                    float2 _13454 = float2(as_type<half2>(_1281._m0[_13429].x));
                    float2 _13463 = float2(as_type<half2>(_1281._m0[_13429].w));
                    float2 _13472 = float2(as_type<half2>(_1281._m0[_13433].z));
                    float3 _13560 = (((((((float3(float2(as_type<half2>(_1281._m0[_13336].x)), _13445.x) * 0.2820949852466583251953125) + (float3(_13445.y, float2(as_type<half2>(_1281._m0[_13336].z))) * _11368)) + (float3(float2(as_type<half2>(_1281._m0[_13336].w)), _13454.x) * _11371)) + (float3(_13454.y, float2(as_type<half2>(_1281._m0[_13429].y))) * _11374)) + (float3(float2(as_type<half2>(_1281._m0[_13429].z)), _13463.x) * _11382)) + (float3(_13463.y, float2(as_type<half2>(_1281._m0[_13433].x))) * _11388)) + (float3(float2(as_type<half2>(_1281._m0[_13433].y)), _13472.x) * _11396)) + (float3(_13472.y, float2(as_type<half2>(_1281._m0[_13433].w))) * _11402);
                    float4 _11119 = ((_11080 + float4((_13022 + (float3(float2(as_type<half2>(_1281._m0[_12861].x)), float2(as_type<half2>(_1281._m0[_12861].y)).x) * _11416)) * _12847, _12847)) + float4((_13291 + (float3(float2(as_type<half2>(_1281._m0[_13130].x)), float2(as_type<half2>(_1281._m0[_13130].y)).x) * _11416)) * _13116, _13116)) + float4((_13560 + (float3(float2(as_type<half2>(_1281._m0[_13399].x)), float2(as_type<half2>(_1281._m0[_13399].y)).x) * _11416)) * _13385, _13385);
                    float _11123 = _11119.w;
                    float3 _22098;
                    if (_11123 > 9.9999997473787516355514526367188e-06)
                    {
                        _22098 = mix(_21179, (fast::max(_11119.xyz, float3(0.0)) / float3(_11123)) * _11259.z, float3(_21679));
                    }
                    else
                    {
                        _22098 = _21179;
                    }
                    _22097 = _22098;
                }
                _21180 = _21179;
            }
            else
            {
                _21180 = _21134;
            }
            float3 _21408;
            if (_283._m34.x > 0.5)
            {
                float3 _21217;
                if (_4100)
                {
                    float3 _4230 = reflect(-_3657, _21057);
                    float _13625 = _4230.x;
                    float _13630 = _4230.z;
                    float2 _13662 = float2((precise::atan2((_283._m29.z * _13625) - (_283._m29.w * _13630), -((_283._m29.w * _13625) + (_283._m29.z * _13630))) * 0.15915493667125701904296875) + 0.5, acos(fast::clamp(_4230.y, -1.0, 1.0)) * 0.3183098733425140380859375);
                    float _13594 = _21024 * 5.0;
                    int _13597 = min(int(_13594), 4);
                    float2 _13683 = (_13662 * float2(_2588[_13597].zw)) - float2(0.5);
                    float2 _13685 = floor(_13683);
                    float2 _13688 = _13683 - _13685;
                    int _13691 = int(_13685.x);
                    int _13694 = int(_13685.y);
                    int _21203;
                    if (_13691 < 0)
                    {
                        _21203 = _13691 + _2588[_13597].z;
                    }
                    else
                    {
                        _21203 = _13691;
                    }
                    int _21204;
                    if (_21203 >= _2588[_13597].z)
                    {
                        _21204 = _21203 - _2588[_13597].z;
                    }
                    else
                    {
                        _21204 = _21203;
                    }
                    int _13714 = _21204 + 1;
                    int _22273 = (_13714 == _2588[_13597].z) ? 0 : _13714;
                    int _13729 = min((_13694 + 1), (_2588[_13597].w - 1));
                    int _13731 = max(_13694, 0);
                    float3 _13784 = float3(_13688.x);
                    int _13604 = _13597 + 1;
                    float2 _13816 = (_13662 * float2(_2588[_13604].zw)) - float2(0.5);
                    float2 _13818 = floor(_13816);
                    float2 _13821 = _13816 - _13818;
                    int _13824 = int(_13818.x);
                    int _13827 = int(_13818.y);
                    int _21210;
                    if (_13824 < 0)
                    {
                        _21210 = _13824 + _2588[_13604].z;
                    }
                    else
                    {
                        _21210 = _13824;
                    }
                    int _21211;
                    if (_21210 >= _2588[_13604].z)
                    {
                        _21211 = _21210 - _2588[_13604].z;
                    }
                    else
                    {
                        _21211 = _21210;
                    }
                    int _13847 = _21211 + 1;
                    int _22274 = (_13847 == _2588[_13604].z) ? 0 : _13847;
                    int _13862 = min((_13827 + 1), (_2588[_13604].w - 1));
                    int _13864 = max(_13827, 0);
                    float3 _13917 = float3(_13821.x);
                    float3 _13619 = mix(mix(mix(_2531.read(uint2((_2588[_13597].xy + int2(_21204, _13731))), 0).xyz, _2531.read(uint2((_2588[_13597].xy + int2(_22273, _13731))), 0).xyz, _13784), mix(_2531.read(uint2((_2588[_13597].xy + int2(_21204, _13729))), 0).xyz, _2531.read(uint2((_2588[_13597].xy + int2(_22273, _13729))), 0).xyz, _13784), float3(_13688.y)), mix(mix(_2531.read(uint2((_2588[_13604].xy + int2(_21211, _13864))), 0).xyz, _2531.read(uint2((_2588[_13604].xy + int2(_22274, _13864))), 0).xyz, _13917), mix(_2531.read(uint2((_2588[_13604].xy + int2(_21211, _13862))), 0).xyz, _2531.read(uint2((_2588[_13604].xy + int2(_22274, _13862))), 0).xyz, _13917), float3(_13821.y)), float3(_13594 - float(_13597))) * _283._m29.y;
                    _21217 = _13619;
                }
                else
                {
                    _21217 = mix(mix(_283._m9.xyz, _283._m8.xyz, float3((reflect(-_3657, _21057).y * 0.5) + 0.5)) * _283._m8.w, _21134, float3(_21024));
                }
                float3 _4250 = reflect(-_3657, _21057);
                int _13983 = int(_283._m34.x);
                float _21233;
                float3 _21299;
                _21299 = float3(0.0);
                _21233 = 0.0;
                float _22111;
                float3 _22112;
                for (int _21232 = 0; _21232 < _13983; _21299 = _22112, _21233 = _22111, _21232++)
                {
                    if (_21233 > 0.999000012874603271484375)
                    {
                        break;
                    }
                    int _13995 = _21232 * 8;
                    float4 _14110 = as_type<float4>(_1281._m0[_13995]);
                    float4 _14116 = as_type<float4>(_1281._m0[_13995 + 1]);
                    float4 _14122 = as_type<float4>(_1281._m0[_13995 + 2]);
                    float3 _14084 = _14110.xyz;
                    float3 _14091 = _14116.xyz;
                    float3 _14098 = _14122.xyz;
                    float3 _14104 = float3(dot(_14084, in.m_3037) + _14110.w, dot(_14091, in.m_3037) + _14116.w, dot(_14098, in.m_3037) + _14122.w);
                    float4 _14128 = as_type<float4>(_1281._m0[_13995 + 3]);
                    float _14006 = _14128.w;
                    float _21234;
                    do
                    {
                        float3 _14140 = _14128.xyz - abs(_14104);
                        float _14148 = fast::min(_14140.x, fast::min(_14140.y, _14140.z));
                        if (_14148 <= 0.0)
                        {
                            _21234 = 0.0;
                            break;
                        }
                        if (_14006 <= 0.0)
                        {
                            _21234 = 1.0;
                            break;
                        }
                        float _14160 = fast::min(_14148 / _14006, 1.0);
                        _21234 = (_14160 * _14160) * (3.0 - (2.0 * _14160));
                        break;
                    } while(false);
                    if (_21234 <= 0.0)
                    {
                        _22112 = _21299;
                        _22111 = _21233;
                        continue;
                    }
                    float4 _14175 = as_type<float4>(_1281._m0[_13995 + 4]);
                    float4 _14181 = as_type<float4>(_1281._m0[_13995 + 5]);
                    float3 _14204 = float3(dot(_14084, _4250), dot(_14091, _4250), dot(_14098, _4250));
                    float3 _21236;
                    if (_14175.w > 0.5)
                    {
                        float3 _14028 = _14175.xyz;
                        float3 _14234 = -_14028;
                        float3 _14236 = fast::clamp(_14104, _14234, _14028);
                        float3 _14246 = step(float3(9.9999999747524270787835121154785e-07), abs(_14204));
                        float3 _14256 = mix(float3(1000000015047466219876688855040.0), (mix(_14234, _14028, step(float3(0.0), _14204)) - _14236) / mix(float3(9.9999999747524270787835121154785e-07), _14204, _14246), _14246);
                        float3 _14272 = (_14236 + (_14204 * fast::max(fast::min(_14256.x, fast::min(_14256.y, _14256.z)), 0.0))) - _14181.xyz;
                        float3 _21235;
                        if (dot(_14272, _14272) > 9.9999999600419720025001879548654e-13)
                        {
                            _21235 = fast::normalize(_14272);
                        }
                        else
                        {
                            _21235 = _14204;
                        }
                        _21236 = _21235;
                    }
                    else
                    {
                        _21236 = _14204;
                    }
                    int _14289 = int(((device uint*)&_1281._m0[_13995 + 6])[0u]);
                    float2 _14339 = float2((precise::atan2(_21236.x, -_21236.z) * 0.15915493667125701904296875) + 0.5, acos(fast::clamp(_21236.y, -1.0, 1.0)) * 0.3183098733425140380859375);
                    float _14305 = _21024 * 5.0;
                    int _14308 = min(int(_14305), 4);
                    int _14379 = _14289 + _1353[_14308].x;
                    float2 _14386 = (_14339 * float2(_1353[_14308].yz)) - float2(0.5);
                    float2 _14388 = floor(_14386);
                    float2 _14391 = _14386 - _14388;
                    int _14394 = int(_14388.x);
                    int _14397 = int(_14388.y);
                    int _21237;
                    if (_14394 < 0)
                    {
                        _21237 = _14394 + _1353[_14308].y;
                    }
                    else
                    {
                        _21237 = _14394;
                    }
                    int _21238;
                    if (_21237 >= _1353[_14308].y)
                    {
                        _21238 = _21237 - _1353[_14308].y;
                    }
                    else
                    {
                        _21238 = _21237;
                    }
                    int _14417 = _21238 + 1;
                    int _22275 = (_14417 == _1353[_14308].y) ? 0 : _14417;
                    int _14485 = _14379 + (max(_14397, 0) * _1353[_14308].y);
                    int _14487 = _14485 + _21238;
                    int _14489 = _14487 >> 1;
                    uint2 _21244;
                    if ((_14487 & 1) == 0)
                    {
                        _21244 = _1281._m0[_14489].xy;
                    }
                    else
                    {
                        _21244 = _1281._m0[_14489].zw;
                    }
                    int _14525 = _14485 + _22275;
                    int _14527 = _14525 >> 1;
                    uint2 _21246;
                    if ((_14525 & 1) == 0)
                    {
                        _21246 = _1281._m0[_14527].xy;
                    }
                    else
                    {
                        _21246 = _1281._m0[_14527].zw;
                    }
                    int _14561 = _14379 + (min((_14397 + 1), (_1353[_14308].z - 1)) * _1353[_14308].y);
                    int _14563 = _14561 + _21238;
                    int _14565 = _14563 >> 1;
                    uint2 _21249;
                    if ((_14563 & 1) == 0)
                    {
                        _21249 = _1281._m0[_14565].xy;
                    }
                    else
                    {
                        _21249 = _1281._m0[_14565].zw;
                    }
                    int _14601 = _14561 + _22275;
                    int _14603 = _14601 >> 1;
                    uint2 _21250;
                    if ((_14601 & 1) == 0)
                    {
                        _21250 = _1281._m0[_14603].xy;
                    }
                    else
                    {
                        _21250 = _1281._m0[_14603].zw;
                    }
                    float3 _14463 = float3(_14391.x);
                    int _14314 = _14308 + 1;
                    int _14666 = _14289 + _1353[_14314].x;
                    float2 _14673 = (_14339 * float2(_1353[_14314].yz)) - float2(0.5);
                    float2 _14675 = floor(_14673);
                    float2 _14678 = _14673 - _14675;
                    int _14681 = int(_14675.x);
                    int _14684 = int(_14675.y);
                    int _21251;
                    if (_14681 < 0)
                    {
                        _21251 = _14681 + _1353[_14314].y;
                    }
                    else
                    {
                        _21251 = _14681;
                    }
                    int _21252;
                    if (_21251 >= _1353[_14314].y)
                    {
                        _21252 = _21251 - _1353[_14314].y;
                    }
                    else
                    {
                        _21252 = _21251;
                    }
                    int _14704 = _21252 + 1;
                    int _22276 = (_14704 == _1353[_14314].y) ? 0 : _14704;
                    int _14772 = _14666 + (max(_14684, 0) * _1353[_14314].y);
                    int _14774 = _14772 + _21252;
                    int _14776 = _14774 >> 1;
                    uint2 _21258;
                    if ((_14774 & 1) == 0)
                    {
                        _21258 = _1281._m0[_14776].xy;
                    }
                    else
                    {
                        _21258 = _1281._m0[_14776].zw;
                    }
                    int _14812 = _14772 + _22276;
                    int _14814 = _14812 >> 1;
                    uint2 _21260;
                    if ((_14812 & 1) == 0)
                    {
                        _21260 = _1281._m0[_14814].xy;
                    }
                    else
                    {
                        _21260 = _1281._m0[_14814].zw;
                    }
                    int _14848 = _14666 + (min((_14684 + 1), (_1353[_14314].z - 1)) * _1353[_14314].y);
                    int _14850 = _14848 + _21252;
                    int _14852 = _14850 >> 1;
                    uint2 _21263;
                    if ((_14850 & 1) == 0)
                    {
                        _21263 = _1281._m0[_14852].xy;
                    }
                    else
                    {
                        _21263 = _1281._m0[_14852].zw;
                    }
                    int _14888 = _14848 + _22276;
                    int _14890 = _14888 >> 1;
                    uint2 _21264;
                    if ((_14888 & 1) == 0)
                    {
                        _21264 = _1281._m0[_14890].xy;
                    }
                    else
                    {
                        _21264 = _1281._m0[_14890].zw;
                    }
                    float3 _14750 = float3(_14678.x);
                    float3 _14044 = mix(mix(mix(float3(float2(as_type<half2>(_21244.x)), float2(as_type<half2>(_21244.y)).x), float3(float2(as_type<half2>(_21246.x)), float2(as_type<half2>(_21246.y)).x), _14463), mix(float3(float2(as_type<half2>(_21249.x)), float2(as_type<half2>(_21249.y)).x), float3(float2(as_type<half2>(_21250.x)), float2(as_type<half2>(_21250.y)).x), _14463), float3(_14391.y)), mix(mix(float3(float2(as_type<half2>(_21258.x)), float2(as_type<half2>(_21258.y)).x), float3(float2(as_type<half2>(_21260.x)), float2(as_type<half2>(_21260.y)).x), _14750), mix(float3(float2(as_type<half2>(_21263.x)), float2(as_type<half2>(_21263.y)).x), float3(float2(as_type<half2>(_21264.x)), float2(as_type<half2>(_21264.y)).x), _14750), float3(_14678.y)), float3(_14305 - float(_14308))) * _14181.w;
                    float _14048 = _21234 * (1.0 - _21233);
                    _22112 = _21299 + (_14044 * _14048);
                    _22111 = _21233 + _14048;
                }
                float3 _14066 = _21299 + (_21217 * (1.0 - _21233));
                bool _4267;
                if (_3703)
                {
                    _4267 = _283._m33.z > 0.5;
                }
                else
                {
                    _4267 = _3703;
                }
                float3 _21409;
                if (_4267)
                {
                    float3 _21375;
                    do
                    {
                        float _14975 = ((_283._m32.x * (1.0 - smoothstep(_283._m33.x * 0.5, _283._m33.x, abs(dot(_283._m31.xyz, in.m_3037) - _283._m31.w)))) * smoothstep(0.5, 0.89999997615814208984375, dot(_3668, _283._m31.xyz))) * (1.0 - smoothstep(_283._m32.y * 0.5, _283._m32.y, _21024));
                        if (_14975 <= 0.0)
                        {
                            _21375 = _14066;
                            break;
                        }
                        float4 _15000 = _283._m30 * float4(in.m_3037 + ((_21034 - (_283._m31.xyz * dot(_21034, _283._m31.xyz))) * _283._m32.w), 1.0);
                        float2 _15013 = ((float2(_15000.x, -_15000.y) / float2(_15000.w)) * 0.5) + float2(0.5);
                        float _15017 = _283._m32.z * _21024;
                        float3 _21373;
                        float _21374;
                        _21374 = 0.0;
                        _21373 = float3(0.0);
                        for (int _21372 = 0; _21372 < 12; )
                        {
                            float _15024 = float(_21372);
                            float _15032 = _15024 * 2.3999631404876708984375;
                            float2 _15044 = _15013 + (float2(cos(_15032) * _283._m33.y, sin(_15032)) * (sqrt((_15024 + 0.5) * 0.083333335816860198974609375) * _15017));
                            float2 _15049 = fast::min(_15044, float2(1.0) - _15044);
                            float _15055 = smoothstep(0.0, 0.039999999105930328369140625, fast::min(_15049.x, _15049.y));
                            float4 _15063 = _3352.sample(_2533, fast::clamp(_15044, float2(0.0), float2(1.0)), level(0.0));
                            float3 _15065 = _15063.xyz;
                            _21374 += (_15063.w * _15055);
                            _21373 += ((_15065 / (float3(1.0) - fast::min(_15065, float3(0.99500000476837158203125)))) * _15055);
                            _21372++;
                            continue;
                        }
                        _21375 = mix(_14066, (_21373 * float3(0.083333335816860198974609375)) + (_14066 * (1.0 - (_21374 * 0.083333335816860198974609375))), float3(_14975));
                        break;
                    } while(false);
                    _21409 = _21375;
                }
                else
                {
                    _21409 = _14066;
                }
                _21408 = _21409;
            }
            else
            {
                _21408 = _21143;
            }
            _21645 = _4185 + (((_4174 * (_21180 - _21134)) + (_4169 * (_21408 - _21143))) * _21158);
        }
        else
        {
            _21645 = _4185;
        }
        float3 _21715;
        if (_283._m13.w > 0.5)
        {
            float2 _15129 = fast::clamp(floor(gl_FragCoord.xy * _283._m12.xy), float2(0.0), _283._m13.xy - float2(1.0));
            uint _15157 = uint((((fast::clamp(floor((log2(fast::max(dot(_283._m11.xyz, in.m_3037) + _283._m11.w, 9.9999999747524270787835121154785e-07)) * _283._m12.z) + _283._m12.w), 0.0, _283._m13.z - 1.0) * _283._m13.y) + _15129.y) * _283._m13.x) + _15129.x);
            uint _15159 = _15157 >> uint(2);
            uint _15161 = _15157 & 3u;
            uint _15165 = _3167._m0[_15159][_15161] & 65535u;
            uint _15167 = _3167._m0[_15159][_15161] >> uint(16);
            float3 _21644;
            _21644 = _21645;
            float3 _4396;
            spvUnsafeArray<float2, 3> _15575;
            spvUnsafeArray<float2, 3> _15576;
            spvUnsafeArray<float2, 3> _15788;
            spvUnsafeArray<float2, 3> _15789;
            for (uint _21510 = _15165; _21510 < (_15165 + _15167); _21644 = _4396, _21510++)
            {
                uint _15173 = _21510 / 3u;
                uint _15186 = (_3188._m0[_15173 >> uint(2)][_15173 & 3u] >> ((_21510 - (_15173 * 3u)) * 10u)) & 1023u;
                float3 _15203 = _3030._m0[_15186].xyz - in.m_3037;
                float _15206 = dot(_15203, _15203);
                float _15210 = _15206 * _3030._m0[_15186].w;
                float _15215 = fast::clamp(1.0 - (_15210 * _15210), 0.0, 1.0);
                float3 _15220 = _15203 * rsqrt(fast::max(_15206, 9.9999999392252902907785028219223e-09));
                float _15238 = fast::clamp((dot(-_15220, _3073._m0[_15186].xyz) * _3065._m0[_15186].w) + _3073._m0[_15186].w, 0.0, 1.0);
                float3 _15251 = _3065._m0[_15186].xyz * ((((_15215 * _15215) * _15238) * _15238) / fast::max(_15206, 9.9999997473787516355514526367188e-05));
                float3 _21642;
                if (_3673)
                {
                    float _21537;
                    do
                    {
                        uint _15287 = uint(_283._m21.z);
                        if (_15186 < _15287)
                        {
                            float _15309 = _283._m26[_15186].z * fast::max((_283._m15[_15186] * float4(in.m_3037, 1.0)).w, 0.0);
                            float4 _15333 = _283._m15[_15186] * float4((in.m_3037 + (_3668 * (_15309 * _283._m25.x))) + (_15220 * (_15309 * _283._m25.y)), 1.0);
                            float _15335 = _15333.w;
                            if (_15335 <= 0.0)
                            {
                                _21537 = 1.0;
                                break;
                            }
                            float3 _15344 = _15333.xyz / float3(_15335);
                            float _15346 = _15344.x;
                            bool _15347 = _15346 < 0.0;
                            bool _15354;
                            if (!_15347)
                            {
                                _15354 = _15346 > 1.0;
                            }
                            else
                            {
                                _15354 = _15347;
                            }
                            bool _15361;
                            if (!_15354)
                            {
                                _15361 = _15344.y < 0.0;
                            }
                            else
                            {
                                _15361 = _15354;
                            }
                            bool _15368;
                            if (!_15361)
                            {
                                _15368 = _15344.y > 1.0;
                            }
                            else
                            {
                                _15368 = _15361;
                            }
                            bool _15375;
                            if (!_15368)
                            {
                                _15375 = _15344.z > 1.0;
                            }
                            else
                            {
                                _15375 = _15368;
                            }
                            if (_15375)
                            {
                                _21537 = 1.0;
                                break;
                            }
                            float _15381 = _15344.z;
                            float2 _15547 = _283._m22.xy * 0.5;
                            float2 _15552 = _283._m26[_15186].xy + (_15344.xy * _283._m23.zw);
                            float4 _15565 = float4(_283._m26[_15186].xy + _15547, (_283._m26[_15186].xy + _283._m23.zw) - _15547);
                            float _21536;
                            do
                            {
                                int _15591 = int(_283._m22.z);
                                if (_15591 <= 0)
                                {
                                    float2 _15601 = fast::clamp(_15552, _15565.xy, _15565.zw);
                                    _21536 = spvDepthCast(_303).sample_compare(_303Smplr, float3(_15601, _15381).xy, _15381);
                                    break;
                                }
                                float2 _15614 = (_15552 / _283._m22.xy) + float2(0.5);
                                float2 _15615 = floor(_15614);
                                float2 _15620 = _15614 - _15615;
                                float2 _15623 = _15615 - float2(0.5);
                                bool _15627 = _15591 == 1;
                                if (_15627)
                                {
                                    float2 _15630 = _15620 * 2.0;
                                    _15575[0] = float2(3.0) - _15630;
                                    _15575[1] = float2(1.0) + _15630;
                                    _15576[0] = ((float2(2.0) - _15620) / _15575[0]) - float2(1.0);
                                    _15576[1] = (_15620 / _15575[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _15657 = _15620 * 3.0;
                                    _15575[0] = float2(4.0) - _15657;
                                    _15575[1] = float2(7.0);
                                    _15575[2] = float2(1.0) + _15657;
                                    _15576[0] = ((float2(3.0) - (_15620 * 2.0)) / _15575[0]) - float2(2.0);
                                    _15576[1] = (float2(3.0) + _15620) / _15575[1];
                                    _15576[2] = (_15620 / _15575[2]) + float2(2.0);
                                }
                                int _22278 = _15627 ? 2 : 3;
                                int _21526;
                                float _21529;
                                _21529 = 0.0;
                                _21526 = 0;
                                float _21535;
                                for (; _21526 < _22278; _21529 = _21535, _21526++)
                                {
                                    _21535 = _21529;
                                    for (int _21532 = 0; _21532 < _22278; )
                                    {
                                        _21535 += ((_15575[_21532].x * _15575[_21526].y) * spvDepthCast(_303).sample_compare(_303Smplr, float3(fast::clamp(_283._m22.xy * (_15623 + float2(_15576[_21532].x, _15576[_21526].y)), _15565.xy, _15565.zw), _15381).xy, _15381));
                                        _21532++;
                                        continue;
                                    }
                                }
                                _21536 = _21529 * (_15627 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _21537 = _21536;
                            break;
                        }
                        uint _15391 = _15186 - _15287;
                        if (_15391 >= uint(_283._m21.w))
                        {
                            _21537 = 1.0;
                            break;
                        }
                        float _15412 = _283._m27[_15391].w * length(in.m_3037 - _283._m27[_15391].xyz);
                        float3 _15430 = ((in.m_3037 + (_3668 * (_15412 * _283._m25.x))) + (_15220 * (_15412 * _283._m25.y))) - _283._m27[_15391].xyz;
                        float3 _15432 = abs(_15430);
                        float _15434 = _15432.x;
                        float _15436 = _15432.y;
                        bool _15437 = _15434 >= _15436;
                        bool _15445;
                        if (_15437)
                        {
                            _15445 = _15434 >= _15432.z;
                        }
                        else
                        {
                            _15445 = _15437;
                        }
                        float _21511;
                        int _21513;
                        if (_15445)
                        {
                            _21513 = (_15430.x > 0.0) ? 0 : 1;
                            _21511 = _15434;
                        }
                        else
                        {
                            float _15457 = _15432.z;
                            bool _15458 = _15436 >= _15457;
                            int _21514;
                            if (_15458)
                            {
                                _21514 = (_15430.y > 0.0) ? 2 : 3;
                            }
                            else
                            {
                                _21514 = (_15430.z > 0.0) ? 4 : 5;
                            }
                            _21513 = _21514;
                            _21511 = _15458 ? _15436 : _15457;
                        }
                        if (_21511 <= 0.0)
                        {
                            _21537 = 1.0;
                            break;
                        }
                        float2 _15495 = float2(dot(_15430, _961[_21513]), dot(_15430, _970[_21513])) / float2(_21511 * _283._m24.z);
                        float _15502 = _283._m28[_15391].z + (_283._m28[_15391].w / _21511);
                        if (_15502 > 1.0)
                        {
                            _21537 = 1.0;
                            break;
                        }
                        float2 _15520 = _283._m28[_15391].xy + (float2(float(spvSMod(_21513, 3)), float(_21513 / 3)) * _283._m24.xy);
                        float2 _15760 = _283._m22.xy * 0.5;
                        float2 _15765 = _15520 + (float2(0.5 + (0.5 * _15495.x), 0.5 - (0.5 * _15495.y)) * _283._m24.xy);
                        float4 _15778 = float4(_15520 + _15760, (_15520 + _283._m24.xy) - _15760);
                        float _21525;
                        do
                        {
                            int _15804 = int(_283._m22.z);
                            if (_15804 <= 0)
                            {
                                _21525 = spvDepthCast(_303).sample_compare(_303Smplr, float3(fast::clamp(_15765, _15778.xy, _15778.zw), _15502).xy, _15502);
                                break;
                            }
                            float2 _15827 = (_15765 / _283._m22.xy) + float2(0.5);
                            float2 _15828 = floor(_15827);
                            float2 _15833 = _15827 - _15828;
                            float2 _15836 = _15828 - float2(0.5);
                            bool _15840 = _15804 == 1;
                            if (_15840)
                            {
                                float2 _15843 = _15833 * 2.0;
                                _15788[0] = float2(3.0) - _15843;
                                _15788[1] = float2(1.0) + _15843;
                                _15789[0] = ((float2(2.0) - _15833) / _15788[0]) - float2(1.0);
                                _15789[1] = (_15833 / _15788[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _15870 = _15833 * 3.0;
                                _15788[0] = float2(4.0) - _15870;
                                _15788[1] = float2(7.0);
                                _15788[2] = float2(1.0) + _15870;
                                _15789[0] = ((float2(3.0) - (_15833 * 2.0)) / _15788[0]) - float2(2.0);
                                _15789[1] = (float2(3.0) + _15833) / _15788[1];
                                _15789[2] = (_15833 / _15788[2]) + float2(2.0);
                            }
                            int _22281 = _15840 ? 2 : 3;
                            int _21515;
                            float _21518;
                            _21518 = 0.0;
                            _21515 = 0;
                            float _21524;
                            for (; _21515 < _22281; _21518 = _21524, _21515++)
                            {
                                _21524 = _21518;
                                for (int _21521 = 0; _21521 < _22281; )
                                {
                                    _21524 += ((_15788[_21521].x * _15788[_21515].y) * spvDepthCast(_303).sample_compare(_303Smplr, float3(fast::clamp(_283._m22.xy * (_15836 + float2(_15789[_21521].x, _15789[_21515].y)), _15778.xy, _15778.zw), _15502).xy, _15502));
                                    _21521++;
                                    continue;
                                }
                            }
                            _21525 = _21518 * (_15840 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _21537 = _21525;
                        break;
                    } while(false);
                    _21642 = _15251 * _21537;
                }
                else
                {
                    _21642 = _15251;
                }
                float3 _4348 = fast::normalize(_15220 + _3657);
                float _4353 = fast::clamp(dot(_21034, _15220), 0.0, 1.0);
                float _4358 = fast::clamp(dot(_21034, _4348), 0.0, 1.0);
                float3 _15975 = _3961 + (_9995 * powr(1.0 - fast::clamp(dot(_3657, _4348), 0.0, 1.0), 5.0));
                float _15989 = ((_4358 * _4358) * _10010) + 1.0;
                _4396 = _21644 + (((((float3(1.0) - _15975) * _3955) + ((_15975 * ((_10005 / ((3.1415927410125732421875 * _15989) * _15989)) * (0.5 / fast::max((_4353 * _10036) + (_21062 * sqrt(((_4353 * _4353) * _10032) + _10005)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875)) * _4353) * _21642);
            }
            _21715 = _21644;
        }
        else
        {
            _21715 = _21645;
        }
        _21711 = _21715;
    }
    float4 _4413 = _4408.sample(_2533, _3419);
    float _4431 = -length(_3656);
    float _21797;
    if (_283._m9.w != 0.0)
    {
        float _4455 = _283._m9.w * (in.m_3037 - _283._m6.xyz).y;
        float _21794;
        if (abs(_4455) < 9.9999997473787516355514526367188e-05)
        {
            _21794 = 1.0 - (0.5 * _4455);
        }
        else
        {
            _21794 = (1.0 - exp(fast::min(-_4455, 60.0))) / _4455;
        }
        _21797 = 1.0 - exp((_4431 * (_283._m7.w * exp(fast::min((-_283._m9.w) * (_283._m6.y - _283._m6.w), 30.0)))) * _21794);
    }
    else
    {
        _21797 = 1.0 - exp(_4431 * _283._m7.w);
    }
    float3 _21844;
    if (_283._m34.z > 0.5)
    {
        float3 _21808;
        if (_283._m29.x > 0.5)
        {
            float _16088 = (_283._m29.z * _21034.x) - (_283._m29.w * _21034.z);
            float _16101 = (_283._m29.w * _21034.x) + (_283._m29.z * _21034.z);
            float _16119 = 1.09254801273345947265625 * _16088;
            spvUnsafeArray<float, 9> _19104 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _21034.y, 0.48860299587249755859375 * _16101, 0.48860299587249755859375 * _16088, _16119 * _21034.y, (1.09254801273345947265625 * _21034.y) * _16101, 0.3153919875621795654296875 * (((3.0 * _16101) * _16101) - 1.0), _16119 * _16101, 0.546274006366729736328125 * ((_16088 * _16088) - (_21034.y * _21034.y)) });
            spvUnsafeArray<float, 9> _16033 = _19104;
            float3 _21807;
            _21807 = float3(0.0);
            for (int _21806 = 0; _21806 < 9; )
            {
                _21807 += (_2531.read(uint2((int2(496, 256) + int2(_21806, 0))), 0).xyz * _16033[_21806]);
                _21806++;
                continue;
            }
            _21808 = fast::max(_21807, float3(0.0)) * _283._m29.y;
        }
        else
        {
            _21808 = mix(_283._m9.xyz, _283._m8.xyz, float3((_21034.y * 0.5) + 0.5)) * _283._m8.w;
        }
        float3 _21813;
        if (_283._m34.y > 0.5)
        {
            int _16296 = int(_283._m34.y);
            int _16299 = int(_283._m34.x);
            float3 _21812;
            _21812 = _21808;
            float3 _22141;
            for (int _21811 = 0; _21811 < _16296; _21812 = _22141, _21811++)
            {
                int _16311 = 8 * (_16299 + _21811);
                float4 _16520 = as_type<float4>(_1281._m0[_16311 + 3]);
                float4 _16564 = as_type<float4>(_1281._m0[_16311]);
                float4 _16570 = as_type<float4>(_1281._m0[_16311 + 1]);
                float4 _16576 = as_type<float4>(_1281._m0[_16311 + 2]);
                float3 _16538 = _16564.xyz;
                float _16542 = _16564.w;
                float3 _16545 = _16570.xyz;
                float _16549 = _16570.w;
                float3 _16552 = _16576.xyz;
                float _16556 = _16576.w;
                float3 _16558 = float3(dot(_16538, in.m_3037) + _16542, dot(_16545, in.m_3037) + _16549, dot(_16552, in.m_3037) + _16556);
                float3 _16320 = _16520.xyz;
                float _16322 = _16520.w;
                float _21973;
                do
                {
                    float3 _16588 = _16320 - abs(_16558);
                    float _16596 = fast::min(_16588.x, fast::min(_16588.y, _16588.z));
                    if (_16596 <= 0.0)
                    {
                        _21973 = 0.0;
                        break;
                    }
                    if (_16322 <= 0.0)
                    {
                        _21973 = 1.0;
                        break;
                    }
                    float _16608 = fast::min(_16596 / _16322, 1.0);
                    _21973 = (_16608 * _16608) * (3.0 - (2.0 * _16608));
                    break;
                } while(false);
                if (_21973 <= 0.0)
                {
                    _22141 = _21812;
                    continue;
                }
                float3 _16331 = as_type<float4>(_1281._m0[_16311 + 4]).xyz;
                float4 _16629 = as_type<float4>(_1281._m0[_16311 + 5]);
                int _16635 = int(((device uint*)&_1281._m0[_16311 + 6])[0u]);
                float _16645 = dot(_16538, _21034);
                float _16651 = dot(_16545, _21034);
                float _16657 = dot(_16552, _21034);
                float3 _16658 = float3(_16645, _16651, _16657);
                float3 _16351 = (in.m_3037 + (_21034 * _16629.x)) + (_3657 * _16629.y);
                float3 _16370 = fast::clamp((((float3(dot(_16538, _16351) + _16542, dot(_16545, _16351) + _16549, dot(_16552, _16351) + _16556) + _16320) / fast::max(_16320 * 2.0, float3(9.9999999747524270787835121154785e-07))) * _16331) - float3(0.5), float3(0.0), _16331 - float3(1.0));
                int3 _16372 = int3(_16331);
                int3 _16379 = min(int3(_16370), max((_16372 - int3(2)), int3(0)));
                float3 _16383 = _16370 - float3(_16379);
                float _16738 = 0.48860299587249755859375 * _16651;
                float _16741 = 0.48860299587249755859375 * _16657;
                float _16744 = 0.48860299587249755859375 * _16645;
                float _16749 = 1.09254801273345947265625 * _16645;
                float _16752 = _16749 * _16651;
                float _16758 = (1.09254801273345947265625 * _16651) * _16657;
                float _16766 = 0.3153919875621795654296875 * (((3.0 * _16657) * _16657) - 1.0);
                float _16772 = _16749 * _16657;
                float _16786 = 0.546274006366729736328125 * ((_16645 * _16645) - (_16651 * _16651));
                int3 _16805 = _16372 - int3(1);
                int3 _16806 = min(_16379, _16805);
                int _16811 = _16372.x;
                int _16815 = _16372.y;
                int _16823 = _16635 + ((_16806.x + (_16811 * (_16806.y + (_16815 * _16806.z)))) * 4);
                float3 _16826 = float3(1.0) - _16383;
                float3 _16844 = (((((float3(_16806) + float3(0.5)) / _16331) * _16320) * 2.0) - _16320) - _16558;
                float _16854 = dot(_16844 * rsqrt(fast::max(dot(_16844, _16844), 1.0000000133514319600180897396058e-10)), _16658) + 1.0;
                float _16857 = _16826.x;
                float _16859 = _16826.y;
                float _16860 = _16857 * _16859;
                float _16862 = _16826.z;
                int _16886 = _16823 + 3;
                float _16872 = ((_16860 * _16862) * ((0.25 * (_16854 * _16854)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_16886])[1u])).y > 0.5);
                int _16916 = _16823 + 1;
                int _16920 = _16823 + 2;
                float2 _16932 = float2(as_type<half2>(_1281._m0[_16823].y));
                float2 _16941 = float2(as_type<half2>(_1281._m0[_16916].x));
                float2 _16950 = float2(as_type<half2>(_1281._m0[_16916].w));
                float2 _16959 = float2(as_type<half2>(_1281._m0[_16920].z));
                float3 _17047 = (((((((float3(float2(as_type<half2>(_1281._m0[_16823].x)), _16932.x) * 0.2820949852466583251953125) + (float3(_16932.y, float2(as_type<half2>(_1281._m0[_16823].z))) * _16738)) + (float3(float2(as_type<half2>(_1281._m0[_16823].w)), _16941.x) * _16741)) + (float3(_16941.y, float2(as_type<half2>(_1281._m0[_16916].y))) * _16744)) + (float3(float2(as_type<half2>(_1281._m0[_16916].z)), _16950.x) * _16752)) + (float3(_16950.y, float2(as_type<half2>(_1281._m0[_16920].x))) * _16758)) + (float3(float2(as_type<half2>(_1281._m0[_16920].y)), _16959.x) * _16766)) + (float3(_16959.y, float2(as_type<half2>(_1281._m0[_16920].w))) * _16772);
                int3 _17075 = min((_16379 + int3(1, 0, 0)), _16805);
                int _17092 = _16635 + ((_17075.x + (_16811 * (_17075.y + (_16815 * _17075.z)))) * 4);
                float3 _17113 = (((((float3(_17075) + float3(0.5)) / _16331) * _16320) * 2.0) - _16320) - _16558;
                float _17123 = dot(_17113 * rsqrt(fast::max(dot(_17113, _17113), 1.0000000133514319600180897396058e-10)), _16658) + 1.0;
                float _17129 = _16383.x * _16859;
                int _17155 = _17092 + 3;
                float _17141 = ((_17129 * _16862) * ((0.25 * (_17123 * _17123)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_17155])[1u])).y > 0.5);
                int _17185 = _17092 + 1;
                int _17189 = _17092 + 2;
                float2 _17201 = float2(as_type<half2>(_1281._m0[_17092].y));
                float2 _17210 = float2(as_type<half2>(_1281._m0[_17185].x));
                float2 _17219 = float2(as_type<half2>(_1281._m0[_17185].w));
                float2 _17228 = float2(as_type<half2>(_1281._m0[_17189].z));
                float3 _17316 = (((((((float3(float2(as_type<half2>(_1281._m0[_17092].x)), _17201.x) * 0.2820949852466583251953125) + (float3(_17201.y, float2(as_type<half2>(_1281._m0[_17092].z))) * _16738)) + (float3(float2(as_type<half2>(_1281._m0[_17092].w)), _17210.x) * _16741)) + (float3(_17210.y, float2(as_type<half2>(_1281._m0[_17185].y))) * _16744)) + (float3(float2(as_type<half2>(_1281._m0[_17185].z)), _17219.x) * _16752)) + (float3(_17219.y, float2(as_type<half2>(_1281._m0[_17189].x))) * _16758)) + (float3(float2(as_type<half2>(_1281._m0[_17189].y)), _17228.x) * _16766)) + (float3(_17228.y, float2(as_type<half2>(_1281._m0[_17189].w))) * _16772);
                int3 _17344 = min((_16379 + int3(0, 1, 0)), _16805);
                int _17361 = _16635 + ((_17344.x + (_16811 * (_17344.y + (_16815 * _17344.z)))) * 4);
                float3 _17382 = (((((float3(_17344) + float3(0.5)) / _16331) * _16320) * 2.0) - _16320) - _16558;
                float _17392 = dot(_17382 * rsqrt(fast::max(dot(_17382, _17382), 1.0000000133514319600180897396058e-10)), _16658) + 1.0;
                float _17398 = _16857 * _16383.y;
                int _17424 = _17361 + 3;
                float _17410 = ((_17398 * _16862) * ((0.25 * (_17392 * _17392)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_17424])[1u])).y > 0.5);
                int _17454 = _17361 + 1;
                int _17458 = _17361 + 2;
                float2 _17470 = float2(as_type<half2>(_1281._m0[_17361].y));
                float2 _17479 = float2(as_type<half2>(_1281._m0[_17454].x));
                float2 _17488 = float2(as_type<half2>(_1281._m0[_17454].w));
                float2 _17497 = float2(as_type<half2>(_1281._m0[_17458].z));
                float3 _17585 = (((((((float3(float2(as_type<half2>(_1281._m0[_17361].x)), _17470.x) * 0.2820949852466583251953125) + (float3(_17470.y, float2(as_type<half2>(_1281._m0[_17361].z))) * _16738)) + (float3(float2(as_type<half2>(_1281._m0[_17361].w)), _17479.x) * _16741)) + (float3(_17479.y, float2(as_type<half2>(_1281._m0[_17454].y))) * _16744)) + (float3(float2(as_type<half2>(_1281._m0[_17454].z)), _17488.x) * _16752)) + (float3(_17488.y, float2(as_type<half2>(_1281._m0[_17458].x))) * _16758)) + (float3(float2(as_type<half2>(_1281._m0[_17458].y)), _17497.x) * _16766)) + (float3(_17497.y, float2(as_type<half2>(_1281._m0[_17458].w))) * _16772);
                int3 _17613 = min((_16379 + int3(1, 1, 0)), _16805);
                int _17630 = _16635 + ((_17613.x + (_16811 * (_17613.y + (_16815 * _17613.z)))) * 4);
                float3 _17651 = (((((float3(_17613) + float3(0.5)) / _16331) * _16320) * 2.0) - _16320) - _16558;
                float _17661 = dot(_17651 * rsqrt(fast::max(dot(_17651, _17651), 1.0000000133514319600180897396058e-10)), _16658) + 1.0;
                float _17667 = _16383.x * _16383.y;
                int _17693 = _17630 + 3;
                float _17679 = ((_17667 * _16862) * ((0.25 * (_17661 * _17661)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_17693])[1u])).y > 0.5);
                int _17723 = _17630 + 1;
                int _17727 = _17630 + 2;
                float2 _17739 = float2(as_type<half2>(_1281._m0[_17630].y));
                float2 _17748 = float2(as_type<half2>(_1281._m0[_17723].x));
                float2 _17757 = float2(as_type<half2>(_1281._m0[_17723].w));
                float2 _17766 = float2(as_type<half2>(_1281._m0[_17727].z));
                float3 _17854 = (((((((float3(float2(as_type<half2>(_1281._m0[_17630].x)), _17739.x) * 0.2820949852466583251953125) + (float3(_17739.y, float2(as_type<half2>(_1281._m0[_17630].z))) * _16738)) + (float3(float2(as_type<half2>(_1281._m0[_17630].w)), _17748.x) * _16741)) + (float3(_17748.y, float2(as_type<half2>(_1281._m0[_17723].y))) * _16744)) + (float3(float2(as_type<half2>(_1281._m0[_17723].z)), _17757.x) * _16752)) + (float3(_17757.y, float2(as_type<half2>(_1281._m0[_17727].x))) * _16758)) + (float3(float2(as_type<half2>(_1281._m0[_17727].y)), _17766.x) * _16766)) + (float3(_17766.y, float2(as_type<half2>(_1281._m0[_17727].w))) * _16772);
                int3 _17882 = min((_16379 + int3(0, 0, 1)), _16805);
                int _17899 = _16635 + ((_17882.x + (_16811 * (_17882.y + (_16815 * _17882.z)))) * 4);
                float3 _17920 = (((((float3(_17882) + float3(0.5)) / _16331) * _16320) * 2.0) - _16320) - _16558;
                float _17930 = dot(_17920 * rsqrt(fast::max(dot(_17920, _17920), 1.0000000133514319600180897396058e-10)), _16658) + 1.0;
                int _17962 = _17899 + 3;
                float _17948 = ((_16860 * _16383.z) * ((0.25 * (_17930 * _17930)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_17962])[1u])).y > 0.5);
                int _17992 = _17899 + 1;
                int _17996 = _17899 + 2;
                float2 _18008 = float2(as_type<half2>(_1281._m0[_17899].y));
                float2 _18017 = float2(as_type<half2>(_1281._m0[_17992].x));
                float2 _18026 = float2(as_type<half2>(_1281._m0[_17992].w));
                float2 _18035 = float2(as_type<half2>(_1281._m0[_17996].z));
                float3 _18123 = (((((((float3(float2(as_type<half2>(_1281._m0[_17899].x)), _18008.x) * 0.2820949852466583251953125) + (float3(_18008.y, float2(as_type<half2>(_1281._m0[_17899].z))) * _16738)) + (float3(float2(as_type<half2>(_1281._m0[_17899].w)), _18017.x) * _16741)) + (float3(_18017.y, float2(as_type<half2>(_1281._m0[_17992].y))) * _16744)) + (float3(float2(as_type<half2>(_1281._m0[_17992].z)), _18026.x) * _16752)) + (float3(_18026.y, float2(as_type<half2>(_1281._m0[_17996].x))) * _16758)) + (float3(float2(as_type<half2>(_1281._m0[_17996].y)), _18035.x) * _16766)) + (float3(_18035.y, float2(as_type<half2>(_1281._m0[_17996].w))) * _16772);
                float4 _16450 = (((float4((_17047 + (float3(float2(as_type<half2>(_1281._m0[_16886].x)), float2(as_type<half2>(_1281._m0[_16886].y)).x) * _16786)) * _16872, _16872) + float4((_17316 + (float3(float2(as_type<half2>(_1281._m0[_17155].x)), float2(as_type<half2>(_1281._m0[_17155].y)).x) * _16786)) * _17141, _17141)) + float4((_17585 + (float3(float2(as_type<half2>(_1281._m0[_17424].x)), float2(as_type<half2>(_1281._m0[_17424].y)).x) * _16786)) * _17410, _17410)) + float4((_17854 + (float3(float2(as_type<half2>(_1281._m0[_17693].x)), float2(as_type<half2>(_1281._m0[_17693].y)).x) * _16786)) * _17679, _17679)) + float4((_18123 + (float3(float2(as_type<half2>(_1281._m0[_17962].x)), float2(as_type<half2>(_1281._m0[_17962].y)).x) * _16786)) * _17948, _17948);
                int3 _18151 = min((_16379 + int3(1, 0, 1)), _16805);
                int _18168 = _16635 + ((_18151.x + (_16811 * (_18151.y + (_16815 * _18151.z)))) * 4);
                float3 _18189 = (((((float3(_18151) + float3(0.5)) / _16331) * _16320) * 2.0) - _16320) - _16558;
                float _18199 = dot(_18189 * rsqrt(fast::max(dot(_18189, _18189), 1.0000000133514319600180897396058e-10)), _16658) + 1.0;
                int _18231 = _18168 + 3;
                float _18217 = ((_17129 * _16383.z) * ((0.25 * (_18199 * _18199)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_18231])[1u])).y > 0.5);
                int _18261 = _18168 + 1;
                int _18265 = _18168 + 2;
                float2 _18277 = float2(as_type<half2>(_1281._m0[_18168].y));
                float2 _18286 = float2(as_type<half2>(_1281._m0[_18261].x));
                float2 _18295 = float2(as_type<half2>(_1281._m0[_18261].w));
                float2 _18304 = float2(as_type<half2>(_1281._m0[_18265].z));
                float3 _18392 = (((((((float3(float2(as_type<half2>(_1281._m0[_18168].x)), _18277.x) * 0.2820949852466583251953125) + (float3(_18277.y, float2(as_type<half2>(_1281._m0[_18168].z))) * _16738)) + (float3(float2(as_type<half2>(_1281._m0[_18168].w)), _18286.x) * _16741)) + (float3(_18286.y, float2(as_type<half2>(_1281._m0[_18261].y))) * _16744)) + (float3(float2(as_type<half2>(_1281._m0[_18261].z)), _18295.x) * _16752)) + (float3(_18295.y, float2(as_type<half2>(_1281._m0[_18265].x))) * _16758)) + (float3(float2(as_type<half2>(_1281._m0[_18265].y)), _18304.x) * _16766)) + (float3(_18304.y, float2(as_type<half2>(_1281._m0[_18265].w))) * _16772);
                int3 _18420 = min((_16379 + int3(0, 1, 1)), _16805);
                int _18437 = _16635 + ((_18420.x + (_16811 * (_18420.y + (_16815 * _18420.z)))) * 4);
                float3 _18458 = (((((float3(_18420) + float3(0.5)) / _16331) * _16320) * 2.0) - _16320) - _16558;
                float _18468 = dot(_18458 * rsqrt(fast::max(dot(_18458, _18458), 1.0000000133514319600180897396058e-10)), _16658) + 1.0;
                int _18500 = _18437 + 3;
                float _18486 = ((_17398 * _16383.z) * ((0.25 * (_18468 * _18468)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_18500])[1u])).y > 0.5);
                int _18530 = _18437 + 1;
                int _18534 = _18437 + 2;
                float2 _18546 = float2(as_type<half2>(_1281._m0[_18437].y));
                float2 _18555 = float2(as_type<half2>(_1281._m0[_18530].x));
                float2 _18564 = float2(as_type<half2>(_1281._m0[_18530].w));
                float2 _18573 = float2(as_type<half2>(_1281._m0[_18534].z));
                float3 _18661 = (((((((float3(float2(as_type<half2>(_1281._m0[_18437].x)), _18546.x) * 0.2820949852466583251953125) + (float3(_18546.y, float2(as_type<half2>(_1281._m0[_18437].z))) * _16738)) + (float3(float2(as_type<half2>(_1281._m0[_18437].w)), _18555.x) * _16741)) + (float3(_18555.y, float2(as_type<half2>(_1281._m0[_18530].y))) * _16744)) + (float3(float2(as_type<half2>(_1281._m0[_18530].z)), _18564.x) * _16752)) + (float3(_18564.y, float2(as_type<half2>(_1281._m0[_18534].x))) * _16758)) + (float3(float2(as_type<half2>(_1281._m0[_18534].y)), _18573.x) * _16766)) + (float3(_18573.y, float2(as_type<half2>(_1281._m0[_18534].w))) * _16772);
                int3 _18689 = min((_16379 + int3(1)), _16805);
                int _18706 = _16635 + ((_18689.x + (_16811 * (_18689.y + (_16815 * _18689.z)))) * 4);
                float3 _18727 = (((((float3(_18689) + float3(0.5)) / _16331) * _16320) * 2.0) - _16320) - _16558;
                float _18737 = dot(_18727 * rsqrt(fast::max(dot(_18727, _18727), 1.0000000133514319600180897396058e-10)), _16658) + 1.0;
                int _18769 = _18706 + 3;
                float _18755 = ((_17667 * _16383.z) * ((0.25 * (_18737 * _18737)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1281._m0[_18769])[1u])).y > 0.5);
                int _18799 = _18706 + 1;
                int _18803 = _18706 + 2;
                float2 _18815 = float2(as_type<half2>(_1281._m0[_18706].y));
                float2 _18824 = float2(as_type<half2>(_1281._m0[_18799].x));
                float2 _18833 = float2(as_type<half2>(_1281._m0[_18799].w));
                float2 _18842 = float2(as_type<half2>(_1281._m0[_18803].z));
                float3 _18930 = (((((((float3(float2(as_type<half2>(_1281._m0[_18706].x)), _18815.x) * 0.2820949852466583251953125) + (float3(_18815.y, float2(as_type<half2>(_1281._m0[_18706].z))) * _16738)) + (float3(float2(as_type<half2>(_1281._m0[_18706].w)), _18824.x) * _16741)) + (float3(_18824.y, float2(as_type<half2>(_1281._m0[_18799].y))) * _16744)) + (float3(float2(as_type<half2>(_1281._m0[_18799].z)), _18833.x) * _16752)) + (float3(_18833.y, float2(as_type<half2>(_1281._m0[_18803].x))) * _16758)) + (float3(float2(as_type<half2>(_1281._m0[_18803].y)), _18842.x) * _16766)) + (float3(_18842.y, float2(as_type<half2>(_1281._m0[_18803].w))) * _16772);
                float4 _16489 = ((_16450 + float4((_18392 + (float3(float2(as_type<half2>(_1281._m0[_18231].x)), float2(as_type<half2>(_1281._m0[_18231].y)).x) * _16786)) * _18217, _18217)) + float4((_18661 + (float3(float2(as_type<half2>(_1281._m0[_18500].x)), float2(as_type<half2>(_1281._m0[_18500].y)).x) * _16786)) * _18486, _18486)) + float4((_18930 + (float3(float2(as_type<half2>(_1281._m0[_18769].x)), float2(as_type<half2>(_1281._m0[_18769].y)).x) * _16786)) * _18755, _18755);
                float _16493 = _16489.w;
                float3 _22142;
                if (_16493 > 9.9999997473787516355514526367188e-06)
                {
                    _22142 = mix(_21812, (fast::max(_16489.xyz, float3(0.0)) / float3(_16493)) * _16629.z, float3(_21973));
                }
                else
                {
                    _22142 = _21812;
                }
                _22141 = _22142;
            }
            _21813 = _21812;
        }
        else
        {
            _21813 = _21808;
        }
        _21844 = _21813 * _21158;
    }
    else
    {
        _21844 = mix(mix(_21711, _21028, float3(_2876._m1.y)) + ((_2876._m5.xyz * _4413.xyz) * (float3(1.0) + in.m_3670.yzw)), _283._m7.xyz, float3(_21797));
    }
    float3 _21845;
    if (_283._m33.w > 0.5)
    {
        _21845 = _21844 / (float3(1.0) + _21844);
    }
    else
    {
        _21845 = _21844;
    }
    out.m_4555 = float4(_21845, in.m_3428.w);
    float2 _21972;
    do
    {
        if (in.m_4565.w <= 0.0)
        {
            _21972 = float2(0.0);
            break;
        }
        _21972 = ((in.m_4565.xy / float2(in.m_4565.w)) - (in.m_4564.xy / float2(in.m_4564.w))) * float2(0.5, -0.5);
        break;
    } while(false);
    _4563 = _21972;
    return out;
}

