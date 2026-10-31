// Generated from mesh_mask.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: c649cd02f6e824bb
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

struct _171
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
};

struct _1434
{
    float4 _m0[1024];
};

struct _1470
{
    float4 _m0[1024];
};

struct _1478
{
    float4 _m0[1024];
};

struct _1575
{
    uint4 _m0[1024];
};

struct _1597
{
    uint4 _m0[1024];
};

struct _1618
{
    float4 _m0;
    float4 _m1;
    float4 _m2;
    float4 _m3;
    float4 _m4;
    float4 _m5;
    float4 _m6;
};

constant spvUnsafeArray<float3, 4> _547 = spvUnsafeArray<float3, 4>({ float3(1.0, 0.449999988079071044921875, 0.449999988079071044921875), float3(0.449999988079071044921875, 1.0, 0.449999988079071044921875), float3(0.5, 0.60000002384185791015625, 1.0), float3(1.0, 1.0, 0.4000000059604644775390625) });
constant spvUnsafeArray<float3, 6> _851 = spvUnsafeArray<float3, 6>({ float3(0.0, 0.0, 1.0), float3(0.0, 0.0, -1.0), float3(-1.0, 0.0, 0.0), float3(-1.0, 0.0, 0.0), float3(-1.0, 0.0, 0.0), float3(1.0, 0.0, 0.0) });
constant spvUnsafeArray<float3, 6> _860 = spvUnsafeArray<float3, 6>({ float3(0.0, 1.0, 0.0), float3(0.0, 1.0, 0.0), float3(0.0, 0.0, -1.0), float3(0.0, 0.0, 1.0), float3(0.0, 1.0, 0.0), float3(0.0, 1.0, 0.0) });
constant spvUnsafeArray<int4, 6> _1270 = spvUnsafeArray<int4, 6>({ int4(0, 0, 512, 256), int4(0, 256, 256, 128), int4(256, 256, 128, 64), int4(384, 256, 64, 32), int4(448, 256, 32, 16), int4(480, 256, 16, 8) });

struct fragment_main_out
{
    float4 m_2302 [[color(0)]];
    float2 m_2316 [[color(1)]];
};

struct fragment_main_in
{
    float3 m_1444 [[user(locn0)]];
    float3 m_1705 [[user(locn1)]];
    float2 m_1625 [[user(locn2)]];
    float4 m_1648 [[user(locn3)]];
    float4 m_1818 [[user(locn5)]];
    float4 m_2317 [[user(locn6)]];
    float4 m_2318 [[user(locn7)]];
    float4 m_1714 [[user(locn8)]];
};

fragment fragment_main_out fragment_main(fragment_main_in in [[stage_in]], constant _1618& _1620 [[buffer(2)]], constant _1434& _1436 [[buffer(3)]], constant _1470& _1472 [[buffer(4)]], constant _1478& _1480 [[buffer(5)]], constant _1575& _1577 [[buffer(6)]], constant _1597& _1599 [[buffer(7)]], constant _171& _173 [[buffer(15)]], texture2d<float> _193 [[texture(0)]], texture2d<float> _1641 [[texture(1)]], texture2d<float> _2004 [[texture(2)]], texture2d<float> _1743 [[texture(3)]], texture2d<float> _1851 [[texture(4)]], texture2d<float> _2276 [[texture(5)]], texture2d<float> _1208 [[texture(6)]], texture2d<float> _1314 [[texture(7)]], sampler _193Smplr [[sampler(0)]], sampler _1210 [[sampler(1)]], sampler _1316 [[sampler(7)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])
{
    fragment_main_out out = {};
    float2 _1639 = float2(dot(_1620._m2.xy, in.m_1625) + _1620._m2.z, dot(_1620._m3.xy, in.m_1625) + _1620._m3.z);
    float4 _1646 = _1641.sample(_1210, _1639);
    float3 _1657 = (in.m_1648.xyz * _1620._m0.xyz) * _1646.xyz;
    if ((_1620._m0.w * _1646.w) < _1620._m6.x)
    {
        discard_fragment();
    }
    float3 _5955;
    if (_1620._m1.x > 0.5)
    {
        float2 _1691 = floor(in.m_1444.xz * float2(0.5));
        _5955 = _1657 * ((mod(abs(_1691.x + _1691.y), 2.0) < 0.5) ? 1.0 : 0.75);
    }
    else
    {
        _5955 = _1657;
    }
    float3 _1707 = fast::normalize(in.m_1705);
    float3 _5869;
    if (_1620._m6.y > 0.5)
    {
        float3 _1723 = in.m_1714.xyz - (_1707 * dot(_1707, in.m_1714.xyz));
        float3 _5870;
        if (dot(_1723, _1723) > 9.9999999600419720025001879548654e-13)
        {
            float3 _1732 = fast::normalize(_1723);
            float3 _1752 = (_1743.sample(_1210, _1639).xyz * 2.0) - float3(1.0);
            float2 _1757 = _1752.xy * _1620._m4.z;
            _5870 = fast::normalize(((_1732 * _1757.x) + ((cross(_1707, _1732) * ((in.m_1714.w < 0.0) ? (-1.0) : 1.0)) * _1757.y)) + (_1707 * _1752.z));
        }
        else
        {
            _5870 = _1707;
        }
        _5869 = _5870;
    }
    else
    {
        _5869 = _1707;
    }
    bool _1781 = _1620._m5.w > 0.5;
    bool _1789;
    if (_1781)
    {
        _1789 = !gl_FrontFacing;
    }
    else
    {
        _1789 = _1781;
    }
    float3 _5978;
    if (_1789)
    {
        _5978 = -_5869;
    }
    else
    {
        _5978 = _5869;
    }
    float3 _1798 = fast::normalize(_173._m4.xyz);
    float3 _1804 = _173._m6.xyz - in.m_1444;
    float3 _1805 = fast::normalize(_1804);
    float3 _1810 = fast::normalize(_1798 + _1805);
    float3 _1816 = _1707 * (gl_FrontFacing ? 1.0 : (-1.0));
    bool _1821 = in.m_1818.x > 0.5;
    float3 _5976;
    float _6001;
    if ((_173._m5.w > 0.5) && _1821)
    {
        float _5926;
        float3 _5927;
        do
        {
            int _2371 = int(_173._m21.x);
            float _2379 = dot(_173._m20.xyz, in.m_1444) + _173._m20.w;
            int _5871;
            _5871 = 0;
            for (;;)
            {
                bool _2385 = _5871 < (_2371 - 1);
                bool _2393;
                if (_2385)
                {
                    _2393 = _2379 > _173._m16[_5871];
                }
                else
                {
                    _2393 = _2385;
                }
                if (_2393)
                {
                    _5871++;
                    continue;
                }
                else
                {
                    break;
                }
            }
            if (_2379 > _173._m16[_5871])
            {
                _5927 = float3(1.0);
                _5926 = 1.0;
                break;
            }
            float _5884;
            do
            {
                float4 _2495 = _173._m14[_5871] * float4(in.m_1444 + (_1816 * _173._m18[_5871]), 1.0);
                float _2498 = _2495.x;
                bool _2499 = _2498 < 0.0;
                bool _2506;
                if (!_2499)
                {
                    _2506 = _2498 > 1.0;
                }
                else
                {
                    _2506 = _2499;
                }
                bool _2513;
                if (!_2506)
                {
                    _2513 = _2495.y < 0.0;
                }
                else
                {
                    _2513 = _2506;
                }
                bool _2520;
                if (!_2513)
                {
                    _2520 = _2495.y > 1.0;
                }
                else
                {
                    _2520 = _2513;
                }
                if (_2520)
                {
                    _5884 = 1.0;
                    break;
                }
                float2 _2533 = float2(float(_5871 & 1), float(_5871 >> 1)) * _173._m23.xy;
                float _2540 = fast::min(_2495.z, 1.0) - _173._m19[_5871];
                float2 _2559 = _173._m22.xy * 0.5;
                float2 _2564 = _2533 + (_2495.xy * _173._m23.xy);
                float4 _2577 = float4(_2533 + _2559, (_2533 + _173._m23.xy) - _2559);
                float _5883;
                do
                {
                    int _2603 = int(_173._m22.z);
                    if (_2603 <= 0)
                    {
                        _5883 = spvDepthCast(_193).sample_compare(_193Smplr, float3(fast::clamp(_2564, _2577.xy, _2577.zw), _2540).xy, _2540);
                        break;
                    }
                    float2 _2626 = (_2564 / _173._m22.xy) + float2(0.5);
                    float2 _2627 = floor(_2626);
                    float2 _2632 = _2626 - _2627;
                    float2 _2635 = _2627 - float2(0.5);
                    bool _2639 = _2603 == 1;
                    spvUnsafeArray<float2, 3> _2587;
                    spvUnsafeArray<float2, 3> _2588;
                    if (_2639)
                    {
                        float2 _2642 = _2632 * 2.0;
                        _2587[0] = float2(3.0) - _2642;
                        _2587[1] = float2(1.0) + _2642;
                        _2588[0] = ((float2(2.0) - _2632) / _2587[0]) - float2(1.0);
                        _2588[1] = (_2632 / _2587[1]) + float2(1.0);
                    }
                    else
                    {
                        float2 _2669 = _2632 * 3.0;
                        _2587[0] = float2(4.0) - _2669;
                        _2587[1] = float2(7.0);
                        _2587[2] = float2(1.0) + _2669;
                        _2588[0] = ((float2(3.0) - (_2632 * 2.0)) / _2587[0]) - float2(2.0);
                        _2588[1] = (float2(3.0) + _2632) / _2587[1];
                        _2588[2] = (_2632 / _2587[2]) + float2(2.0);
                    }
                    int _6399 = _2639 ? 2 : 3;
                    int _5873;
                    float _5876;
                    _5876 = 0.0;
                    _5873 = 0;
                    float _5882;
                    for (; _5873 < _6399; _5876 = _5882, _5873++)
                    {
                        _5882 = _5876;
                        for (int _5879 = 0; _5879 < _6399; )
                        {
                            _5882 += ((_2587[_5879].x * _2587[_5873].y) * spvDepthCast(_193).sample_compare(_193Smplr, float3(fast::clamp(_173._m22.xy * (_2635 + float2(_2588[_5879].x, _2588[_5873].y)), _2577.xy, _2577.zw), _2540).xy, _2540));
                            _5879++;
                            continue;
                        }
                    }
                    _5883 = _5876 * (_2639 ? 0.0625 : 0.0069444444961845874786376953125);
                    break;
                } while(false);
                _5884 = _5883;
                break;
            } while(false);
            float3 _5921;
            float _5924;
            if (_2379 > _173._m17[_5871])
            {
                float _2433 = (_2379 - _173._m17[_5871]) / (_173._m16[_5871] - _173._m17[_5871]);
                int _2435 = _5871 + 1;
                float3 _5922;
                float _5925;
                if (_2435 < _2371)
                {
                    float _5904;
                    do
                    {
                        float4 _2782 = _173._m14[_2435] * float4(in.m_1444 + (_1816 * _173._m18[_2435]), 1.0);
                        float _2785 = _2782.x;
                        bool _2786 = _2785 < 0.0;
                        bool _2793;
                        if (!_2786)
                        {
                            _2793 = _2785 > 1.0;
                        }
                        else
                        {
                            _2793 = _2786;
                        }
                        bool _2800;
                        if (!_2793)
                        {
                            _2800 = _2782.y < 0.0;
                        }
                        else
                        {
                            _2800 = _2793;
                        }
                        bool _2807;
                        if (!_2800)
                        {
                            _2807 = _2782.y > 1.0;
                        }
                        else
                        {
                            _2807 = _2800;
                        }
                        if (_2807)
                        {
                            _5904 = 1.0;
                            break;
                        }
                        float2 _2820 = float2(float(_2435 & 1), float(_2435 >> 1)) * _173._m23.xy;
                        float _2827 = fast::min(_2782.z, 1.0) - _173._m19[_2435];
                        float2 _2846 = _173._m22.xy * 0.5;
                        float2 _2851 = _2820 + (_2782.xy * _173._m23.xy);
                        float4 _2864 = float4(_2820 + _2846, (_2820 + _173._m23.xy) - _2846);
                        float _5903;
                        do
                        {
                            int _2890 = int(_173._m22.z);
                            if (_2890 <= 0)
                            {
                                _5903 = spvDepthCast(_193).sample_compare(_193Smplr, float3(fast::clamp(_2851, _2864.xy, _2864.zw), _2827).xy, _2827);
                                break;
                            }
                            float2 _2913 = (_2851 / _173._m22.xy) + float2(0.5);
                            float2 _2914 = floor(_2913);
                            float2 _2919 = _2913 - _2914;
                            float2 _2922 = _2914 - float2(0.5);
                            bool _2926 = _2890 == 1;
                            spvUnsafeArray<float2, 3> _2874;
                            spvUnsafeArray<float2, 3> _2875;
                            if (_2926)
                            {
                                float2 _2929 = _2919 * 2.0;
                                _2874[0] = float2(3.0) - _2929;
                                _2874[1] = float2(1.0) + _2929;
                                _2875[0] = ((float2(2.0) - _2919) / _2874[0]) - float2(1.0);
                                _2875[1] = (_2919 / _2874[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _2956 = _2919 * 3.0;
                                _2874[0] = float2(4.0) - _2956;
                                _2874[1] = float2(7.0);
                                _2874[2] = float2(1.0) + _2956;
                                _2875[0] = ((float2(3.0) - (_2919 * 2.0)) / _2874[0]) - float2(2.0);
                                _2875[1] = (float2(3.0) + _2919) / _2874[1];
                                _2875[2] = (_2919 / _2874[2]) + float2(2.0);
                            }
                            int _6401 = _2926 ? 2 : 3;
                            int _5893;
                            float _5896;
                            _5896 = 0.0;
                            _5893 = 0;
                            float _5902;
                            for (; _5893 < _6401; _5896 = _5902, _5893++)
                            {
                                _5902 = _5896;
                                for (int _5899 = 0; _5899 < _6401; )
                                {
                                    _5902 += ((_2874[_5899].x * _2874[_5893].y) * spvDepthCast(_193).sample_compare(_193Smplr, float3(fast::clamp(_173._m22.xy * (_2922 + float2(_2875[_5899].x, _2875[_5893].y)), _2864.xy, _2864.zw), _2827).xy, _2827));
                                    _5899++;
                                    continue;
                                }
                            }
                            _5903 = _5896 * (_2926 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _5904 = _5903;
                        break;
                    } while(false);
                    _5925 = mix(_5884, _5904, _2433);
                    _5922 = mix(_547[_5871], _547[_2435], float3(_2433));
                }
                else
                {
                    _5925 = mix(_5884, 1.0, _2433);
                    _5922 = _547[_5871];
                }
                _5924 = _5925;
                _5921 = _5922;
            }
            else
            {
                _5924 = _5884;
                _5921 = _547[_5871];
            }
            _5927 = select(float3(1.0), _5921, bool3(_173._m22.w > 0.5));
            _5926 = _5924;
            break;
        } while(false);
        _6001 = _5926;
        _5976 = _5955 * _5927;
    }
    else
    {
        _6001 = 1.0;
        _5976 = _5955;
    }
    float3 _1847 = _173._m5.xyz * _173._m4.w;
    float4 _1856 = _1851.sample(_1210, _1639);
    float _1860 = 1.0 + (_1620._m4.w * (_1856.x - 1.0));
    float3 _6148;
    if (!_1781)
    {
        float _1868 = dot(_5978, _1798);
        float3 _6142;
        if (_173._m29.x > 0.5)
        {
            float _3107 = (_173._m29.z * _5978.x) - (_173._m29.w * _5978.z);
            float _3120 = (_173._m29.w * _5978.x) + (_173._m29.z * _5978.z);
            float _3138 = 1.09254801273345947265625 * _3107;
            spvUnsafeArray<float, 9> _5682 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _5978.y, 0.48860299587249755859375 * _3120, 0.48860299587249755859375 * _3107, _3138 * _5978.y, (1.09254801273345947265625 * _5978.y) * _3120, 0.3153919875621795654296875 * (((3.0 * _3120) * _3120) - 1.0), _3138 * _3120, 0.546274006366729736328125 * ((_3107 * _3107) - (_5978.y * _5978.y)) });
            spvUnsafeArray<float, 9> _3052 = _5682;
            float3 _6141;
            _6141 = float3(0.0);
            for (int _6140 = 0; _6140 < 9; )
            {
                _6141 += (_1208.read(uint2((int2(496, 256) + int2(_6140, 0))), 0).xyz * _3052[_6140]);
                _6140++;
                continue;
            }
            _6142 = fast::max(_6141, float3(0.0)) * _173._m29.y;
        }
        else
        {
            _6142 = mix(_173._m9.xyz, _173._m8.xyz, float3((_5978.y * 0.5) + 0.5)) * _173._m8.w;
        }
        float3 _1918 = (_5976 * ((_6142 * _1860) + ((_1847 * fast::max(_1868, 0.0)) * _6001))) + ((_1847 * ((powr(fast::max(dot(_5978, _1810), 0.0), _1620._m1.w) * _1620._m1.z) * step(0.0, _1868))) * _6001);
        float3 _6149;
        if (_173._m13.w > 0.5)
        {
            float2 _3223 = fast::clamp(floor(gl_FragCoord.xy * _173._m12.xy), float2(0.0), _173._m13.xy - float2(1.0));
            uint _3251 = uint((((fast::clamp(floor((log2(fast::max(dot(_173._m11.xyz, in.m_1444) + _173._m11.w, 9.9999999747524270787835121154785e-07)) * _173._m12.z) + _173._m12.w), 0.0, _173._m13.z - 1.0) * _173._m13.y) + _3223.y) * _173._m13.x) + _3223.x);
            uint _3253 = _3251 >> uint(2);
            uint _3255 = _3251 & 3u;
            uint _3259 = _1577._m0[_3253][_3255] & 65535u;
            uint _3261 = _1577._m0[_3253][_3255] >> uint(16);
            float3 _6150;
            _6150 = _1918;
            float3 _1999;
            spvUnsafeArray<float2, 3> _3669;
            spvUnsafeArray<float2, 3> _3670;
            spvUnsafeArray<float2, 3> _3882;
            spvUnsafeArray<float2, 3> _3883;
            for (uint _6147 = _3259; _6147 < (_3259 + _3261); _6150 = _1999, _6147++)
            {
                uint _3267 = _6147 / 3u;
                uint _3280 = (_1599._m0[_3267 >> uint(2)][_3267 & 3u] >> ((_6147 - (_3267 * 3u)) * 10u)) & 1023u;
                float3 _3297 = _1436._m0[_3280].xyz - in.m_1444;
                float _3300 = dot(_3297, _3297);
                float _3304 = _3300 * _1436._m0[_3280].w;
                float _3309 = fast::clamp(1.0 - (_3304 * _3304), 0.0, 1.0);
                float3 _3314 = _3297 * rsqrt(fast::max(_3300, 9.9999999392252902907785028219223e-09));
                float _3332 = fast::clamp((dot(-_3314, _1480._m0[_3280].xyz) * _1472._m0[_3280].w) + _1480._m0[_3280].w, 0.0, 1.0);
                float3 _3345 = _1472._m0[_3280].xyz * ((((_3309 * _3309) * _3332) * _3332) / fast::max(_3300, 9.9999997473787516355514526367188e-05));
                float3 _6323;
                if (_1821)
                {
                    float _6269;
                    do
                    {
                        uint _3381 = uint(_173._m21.z);
                        if (_3280 < _3381)
                        {
                            float _3403 = _173._m26[_3280].z * fast::max((_173._m15[_3280] * float4(in.m_1444, 1.0)).w, 0.0);
                            float4 _3427 = _173._m15[_3280] * float4((in.m_1444 + (_1816 * (_3403 * _173._m25.x))) + (_3314 * (_3403 * _173._m25.y)), 1.0);
                            float _3429 = _3427.w;
                            if (_3429 <= 0.0)
                            {
                                _6269 = 1.0;
                                break;
                            }
                            float3 _3438 = _3427.xyz / float3(_3429);
                            float _3440 = _3438.x;
                            bool _3441 = _3440 < 0.0;
                            bool _3448;
                            if (!_3441)
                            {
                                _3448 = _3440 > 1.0;
                            }
                            else
                            {
                                _3448 = _3441;
                            }
                            bool _3455;
                            if (!_3448)
                            {
                                _3455 = _3438.y < 0.0;
                            }
                            else
                            {
                                _3455 = _3448;
                            }
                            bool _3462;
                            if (!_3455)
                            {
                                _3462 = _3438.y > 1.0;
                            }
                            else
                            {
                                _3462 = _3455;
                            }
                            bool _3469;
                            if (!_3462)
                            {
                                _3469 = _3438.z > 1.0;
                            }
                            else
                            {
                                _3469 = _3462;
                            }
                            if (_3469)
                            {
                                _6269 = 1.0;
                                break;
                            }
                            float _3475 = _3438.z;
                            float2 _3641 = _173._m22.xy * 0.5;
                            float2 _3646 = _173._m26[_3280].xy + (_3438.xy * _173._m23.zw);
                            float4 _3659 = float4(_173._m26[_3280].xy + _3641, (_173._m26[_3280].xy + _173._m23.zw) - _3641);
                            float _6268;
                            do
                            {
                                int _3685 = int(_173._m22.z);
                                if (_3685 <= 0)
                                {
                                    float2 _3695 = fast::clamp(_3646, _3659.xy, _3659.zw);
                                    _6268 = spvDepthCast(_193).sample_compare(_193Smplr, float3(_3695, _3475).xy, _3475);
                                    break;
                                }
                                float2 _3708 = (_3646 / _173._m22.xy) + float2(0.5);
                                float2 _3709 = floor(_3708);
                                float2 _3714 = _3708 - _3709;
                                float2 _3717 = _3709 - float2(0.5);
                                bool _3721 = _3685 == 1;
                                if (_3721)
                                {
                                    float2 _3724 = _3714 * 2.0;
                                    _3669[0] = float2(3.0) - _3724;
                                    _3669[1] = float2(1.0) + _3724;
                                    _3670[0] = ((float2(2.0) - _3714) / _3669[0]) - float2(1.0);
                                    _3670[1] = (_3714 / _3669[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _3751 = _3714 * 3.0;
                                    _3669[0] = float2(4.0) - _3751;
                                    _3669[1] = float2(7.0);
                                    _3669[2] = float2(1.0) + _3751;
                                    _3670[0] = ((float2(3.0) - (_3714 * 2.0)) / _3669[0]) - float2(2.0);
                                    _3670[1] = (float2(3.0) + _3714) / _3669[1];
                                    _3670[2] = (_3714 / _3669[2]) + float2(2.0);
                                }
                                int _6406 = _3721 ? 2 : 3;
                                int _6258;
                                float _6261;
                                _6261 = 0.0;
                                _6258 = 0;
                                float _6267;
                                for (; _6258 < _6406; _6261 = _6267, _6258++)
                                {
                                    _6267 = _6261;
                                    for (int _6264 = 0; _6264 < _6406; )
                                    {
                                        _6267 += ((_3669[_6264].x * _3669[_6258].y) * spvDepthCast(_193).sample_compare(_193Smplr, float3(fast::clamp(_173._m22.xy * (_3717 + float2(_3670[_6264].x, _3670[_6258].y)), _3659.xy, _3659.zw), _3475).xy, _3475));
                                        _6264++;
                                        continue;
                                    }
                                }
                                _6268 = _6261 * (_3721 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _6269 = _6268;
                            break;
                        }
                        uint _3485 = _3280 - _3381;
                        if (_3485 >= uint(_173._m21.w))
                        {
                            _6269 = 1.0;
                            break;
                        }
                        float _3506 = _173._m27[_3485].w * length(in.m_1444 - _173._m27[_3485].xyz);
                        float3 _3524 = ((in.m_1444 + (_1816 * (_3506 * _173._m25.x))) + (_3314 * (_3506 * _173._m25.y))) - _173._m27[_3485].xyz;
                        float3 _3526 = abs(_3524);
                        float _3528 = _3526.x;
                        float _3530 = _3526.y;
                        bool _3531 = _3528 >= _3530;
                        bool _3539;
                        if (_3531)
                        {
                            _3539 = _3528 >= _3526.z;
                        }
                        else
                        {
                            _3539 = _3531;
                        }
                        float _6243;
                        int _6245;
                        if (_3539)
                        {
                            _6245 = (_3524.x > 0.0) ? 0 : 1;
                            _6243 = _3528;
                        }
                        else
                        {
                            float _3551 = _3526.z;
                            bool _3552 = _3530 >= _3551;
                            int _6246;
                            if (_3552)
                            {
                                _6246 = (_3524.y > 0.0) ? 2 : 3;
                            }
                            else
                            {
                                _6246 = (_3524.z > 0.0) ? 4 : 5;
                            }
                            _6245 = _6246;
                            _6243 = _3552 ? _3530 : _3551;
                        }
                        if (_6243 <= 0.0)
                        {
                            _6269 = 1.0;
                            break;
                        }
                        float2 _3589 = float2(dot(_3524, _851[_6245]), dot(_3524, _860[_6245])) / float2(_6243 * _173._m24.z);
                        float _3596 = _173._m28[_3485].z + (_173._m28[_3485].w / _6243);
                        if (_3596 > 1.0)
                        {
                            _6269 = 1.0;
                            break;
                        }
                        float2 _3614 = _173._m28[_3485].xy + (float2(float(spvSMod(_6245, 3)), float(_6245 / 3)) * _173._m24.xy);
                        float2 _3854 = _173._m22.xy * 0.5;
                        float2 _3859 = _3614 + (float2(0.5 + (0.5 * _3589.x), 0.5 - (0.5 * _3589.y)) * _173._m24.xy);
                        float4 _3872 = float4(_3614 + _3854, (_3614 + _173._m24.xy) - _3854);
                        float _6257;
                        do
                        {
                            int _3898 = int(_173._m22.z);
                            if (_3898 <= 0)
                            {
                                _6257 = spvDepthCast(_193).sample_compare(_193Smplr, float3(fast::clamp(_3859, _3872.xy, _3872.zw), _3596).xy, _3596);
                                break;
                            }
                            float2 _3921 = (_3859 / _173._m22.xy) + float2(0.5);
                            float2 _3922 = floor(_3921);
                            float2 _3927 = _3921 - _3922;
                            float2 _3930 = _3922 - float2(0.5);
                            bool _3934 = _3898 == 1;
                            if (_3934)
                            {
                                float2 _3937 = _3927 * 2.0;
                                _3882[0] = float2(3.0) - _3937;
                                _3882[1] = float2(1.0) + _3937;
                                _3883[0] = ((float2(2.0) - _3927) / _3882[0]) - float2(1.0);
                                _3883[1] = (_3927 / _3882[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _3964 = _3927 * 3.0;
                                _3882[0] = float2(4.0) - _3964;
                                _3882[1] = float2(7.0);
                                _3882[2] = float2(1.0) + _3964;
                                _3883[0] = ((float2(3.0) - (_3927 * 2.0)) / _3882[0]) - float2(2.0);
                                _3883[1] = (float2(3.0) + _3927) / _3882[1];
                                _3883[2] = (_3927 / _3882[2]) + float2(2.0);
                            }
                            int _6409 = _3934 ? 2 : 3;
                            int _6247;
                            float _6250;
                            _6250 = 0.0;
                            _6247 = 0;
                            float _6256;
                            for (; _6247 < _6409; _6250 = _6256, _6247++)
                            {
                                _6256 = _6250;
                                for (int _6253 = 0; _6253 < _6409; )
                                {
                                    _6256 += ((_3882[_6253].x * _3882[_6247].y) * spvDepthCast(_193).sample_compare(_193Smplr, float3(fast::clamp(_173._m22.xy * (_3930 + float2(_3883[_6253].x, _3883[_6247].y)), _3872.xy, _3872.zw), _3596).xy, _3596));
                                    _6253++;
                                    continue;
                                }
                            }
                            _6257 = _6250 * (_3934 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _6269 = _6257;
                        break;
                    } while(false);
                    _6323 = _3345 * _6269;
                }
                else
                {
                    _6323 = _3345;
                }
                float _1970 = dot(_5978, _3314);
                _1999 = _6150 + (((_5976 * fast::max(_1970, 0.0)) * _6323) + (_6323 * ((powr(fast::max(dot(_5978, fast::normalize(_3314 + _1805)), 0.0), _1620._m1.w) * _1620._m1.z) * step(0.0, _1970))));
            }
            _6149 = _6150;
        }
        else
        {
            _6149 = _1918;
        }
        _6148 = _6149;
    }
    else
    {
        float4 _2009 = _2004.sample(_1210, _1639);
        float _2016 = fast::clamp(_1620._m4.x * _2009.z, 0.0, 1.0);
        float _2024 = fast::clamp(_1620._m4.y * _2009.y, 0.04500000178813934326171875, 1.0);
        float _2028 = _2024 * _2024;
        float3 _2033 = _5976 * (1.0 - _2016);
        float3 _2040 = mix(float3(0.039999999105930328369140625), _5976, float3(_2016));
        float _2045 = fast::max(dot(_5978, _1805), 9.9999997473787516355514526367188e-05);
        float _2050 = fast::clamp(dot(_5978, _1798), 0.0, 1.0);
        float _2055 = fast::clamp(dot(_5978, _1810), 0.0, 1.0);
        float3 _4066 = float3(1.0) - _2040;
        float3 _4069 = _2040 + (_4066 * powr(1.0 - fast::clamp(dot(_1805, _1810), 0.0, 1.0), 5.0));
        float _4076 = _2028 * _2028;
        float _4081 = _4076 - 1.0;
        float _4083 = ((_2055 * _2055) * _4081) + 1.0;
        float _4103 = 1.0 - _4076;
        float _4107 = sqrt(((_2045 * _2045) * _4103) + _4076);
        float2 _6019;
        float3 _6027;
        float3 _6034;
        if (_173._m29.x > 0.5)
        {
            float4 _4140 = _1314.sample(_1316, (((float2(_2045, _2024) * 31.0) + float2(0.5)) * float2(0.03125)));
            float _4199 = (_173._m29.z * _5978.x) - (_173._m29.w * _5978.z);
            float _4212 = (_173._m29.w * _5978.x) + (_173._m29.z * _5978.z);
            float _4230 = 1.09254801273345947265625 * _4199;
            spvUnsafeArray<float, 9> _5663 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _5978.y, 0.48860299587249755859375 * _4212, 0.48860299587249755859375 * _4199, _4230 * _5978.y, (1.09254801273345947265625 * _5978.y) * _4212, 0.3153919875621795654296875 * (((3.0 * _4212) * _4212) - 1.0), _4230 * _4212, 0.546274006366729736328125 * ((_4199 * _4199) - (_5978.y * _5978.y)) });
            spvUnsafeArray<float, 9> _4144 = _5663;
            float3 _6003;
            _6003 = float3(0.0);
            for (int _6002 = 0; _6002 < 9; )
            {
                _6003 += (_1208.read(uint2((int2(496, 256) + int2(_6002, 0))), 0).xyz * _4144[_6002]);
                _6002++;
                continue;
            }
            float3 _2116 = reflect(-_1805, _5978);
            float _4325 = _2116.x;
            float _4330 = _2116.z;
            float2 _4362 = float2((precise::atan2((_173._m29.z * _4325) - (_173._m29.w * _4330), -((_173._m29.w * _4325) + (_173._m29.z * _4330))) * 0.15915493667125701904296875) + 0.5, acos(fast::clamp(_2116.y, -1.0, 1.0)) * 0.3183098733425140380859375);
            float _4294 = _2024 * 5.0;
            int _4297 = min(int(_4294), 4);
            float2 _4383 = (_4362 * float2(_1270[_4297].zw)) - float2(0.5);
            float2 _4385 = floor(_4383);
            float2 _4388 = _4383 - _4385;
            int _4391 = int(_4385.x);
            int _4394 = int(_4385.y);
            int _6005;
            if (_4391 < 0)
            {
                _6005 = _4391 + _1270[_4297].z;
            }
            else
            {
                _6005 = _4391;
            }
            int _6006;
            if (_6005 >= _1270[_4297].z)
            {
                _6006 = _6005 - _1270[_4297].z;
            }
            else
            {
                _6006 = _6005;
            }
            int _4414 = _6006 + 1;
            int _6410 = (_4414 == _1270[_4297].z) ? 0 : _4414;
            int _4429 = min((_4394 + 1), (_1270[_4297].w - 1));
            int _4431 = max(_4394, 0);
            float3 _4484 = float3(_4388.x);
            int _4304 = _4297 + 1;
            float2 _4516 = (_4362 * float2(_1270[_4304].zw)) - float2(0.5);
            float2 _4518 = floor(_4516);
            float2 _4521 = _4516 - _4518;
            int _4524 = int(_4518.x);
            int _4527 = int(_4518.y);
            int _6012;
            if (_4524 < 0)
            {
                _6012 = _4524 + _1270[_4304].z;
            }
            else
            {
                _6012 = _4524;
            }
            int _6013;
            if (_6012 >= _1270[_4304].z)
            {
                _6013 = _6012 - _1270[_4304].z;
            }
            else
            {
                _6013 = _6012;
            }
            int _4547 = _6013 + 1;
            int _6411 = (_4547 == _1270[_4304].z) ? 0 : _4547;
            int _4562 = min((_4527 + 1), (_1270[_4304].w - 1));
            int _4564 = max(_4527, 0);
            float3 _4617 = float3(_4521.x);
            float3 _4319 = mix(mix(mix(_1208.read(uint2((_1270[_4297].xy + int2(_6006, _4431))), 0).xyz, _1208.read(uint2((_1270[_4297].xy + int2(_6410, _4431))), 0).xyz, _4484), mix(_1208.read(uint2((_1270[_4297].xy + int2(_6006, _4429))), 0).xyz, _1208.read(uint2((_1270[_4297].xy + int2(_6410, _4429))), 0).xyz, _4484), float3(_4388.y)), mix(mix(_1208.read(uint2((_1270[_4304].xy + int2(_6013, _4564))), 0).xyz, _1208.read(uint2((_1270[_4304].xy + int2(_6411, _4564))), 0).xyz, _4617), mix(_1208.read(uint2((_1270[_4304].xy + int2(_6013, _4562))), 0).xyz, _1208.read(uint2((_1270[_4304].xy + int2(_6411, _4562))), 0).xyz, _4617), float3(_4521.y)), float3(_4294 - float(_4297))) * _173._m29.y;
            _6034 = _4319;
            _6027 = fast::max(_6003, float3(0.0)) * _173._m29.y;
            _6019 = _4140.xy;
        }
        else
        {
            float4 _4635 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * _2024) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);
            float _4637 = _4635.x;
            float3 _4672 = mix(_173._m9.xyz, _173._m8.xyz, float3((_5978.y * 0.5) + 0.5)) * _173._m8.w;
            _6034 = mix(mix(_173._m9.xyz, _173._m8.xyz, float3((reflect(-_1805, _5978).y * 0.5) + 0.5)) * _173._m8.w, _4672, float3(_2024));
            _6027 = _4672;
            _6019 = (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_4637 * _4637, exp2((-9.27999973297119140625) * _2045)) * _4637) + _4635.y)) + _4635.zw;
        }
        float3 _2148 = (_2040 * _6019.x) + float3(_6019.y);
        float3 _2164 = ((((((float3(1.0) - _4069) * _2033) + ((_4069 * ((_4076 / ((3.1415927410125732421875 * _4083) * _4083)) * (0.5 / fast::max((_2050 * _4107) + (_2045 * sqrt(((_2050 * _2050) * _4103) + _4076)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875)) * _2050) * _1847) * _6001) + (((((float3(1.0) - _2148) * _2033) * _6027) + (_2148 * _6034)) * _1860);
        float3 _6151;
        if (_173._m13.w > 0.5)
        {
            float2 _4717 = fast::clamp(floor(gl_FragCoord.xy * _173._m12.xy), float2(0.0), _173._m13.xy - float2(1.0));
            uint _4745 = uint((((fast::clamp(floor((log2(fast::max(dot(_173._m11.xyz, in.m_1444) + _173._m11.w, 9.9999999747524270787835121154785e-07)) * _173._m12.z) + _173._m12.w), 0.0, _173._m13.z - 1.0) * _173._m13.y) + _4717.y) * _173._m13.x) + _4717.x);
            uint _4747 = _4745 >> uint(2);
            uint _4749 = _4745 & 3u;
            uint _4753 = _1577._m0[_4747][_4749] & 65535u;
            uint _4755 = _1577._m0[_4747][_4749] >> uint(16);
            float3 _6106;
            _6106 = _2164;
            float3 _2264;
            spvUnsafeArray<float2, 3> _5163;
            spvUnsafeArray<float2, 3> _5164;
            spvUnsafeArray<float2, 3> _5376;
            spvUnsafeArray<float2, 3> _5377;
            for (uint _6035 = _4753; _6035 < (_4753 + _4755); _6106 = _2264, _6035++)
            {
                uint _4761 = _6035 / 3u;
                uint _4774 = (_1599._m0[_4761 >> uint(2)][_4761 & 3u] >> ((_6035 - (_4761 * 3u)) * 10u)) & 1023u;
                float3 _4791 = _1436._m0[_4774].xyz - in.m_1444;
                float _4794 = dot(_4791, _4791);
                float _4798 = _4794 * _1436._m0[_4774].w;
                float _4803 = fast::clamp(1.0 - (_4798 * _4798), 0.0, 1.0);
                float3 _4808 = _4791 * rsqrt(fast::max(_4794, 9.9999999392252902907785028219223e-09));
                float _4826 = fast::clamp((dot(-_4808, _1480._m0[_4774].xyz) * _1472._m0[_4774].w) + _1480._m0[_4774].w, 0.0, 1.0);
                float3 _4839 = _1472._m0[_4774].xyz * ((((_4803 * _4803) * _4826) * _4826) / fast::max(_4794, 9.9999997473787516355514526367188e-05));
                float3 _6104;
                if (_1821)
                {
                    float _6062;
                    do
                    {
                        uint _4875 = uint(_173._m21.z);
                        if (_4774 < _4875)
                        {
                            float _4897 = _173._m26[_4774].z * fast::max((_173._m15[_4774] * float4(in.m_1444, 1.0)).w, 0.0);
                            float4 _4921 = _173._m15[_4774] * float4((in.m_1444 + (_1816 * (_4897 * _173._m25.x))) + (_4808 * (_4897 * _173._m25.y)), 1.0);
                            float _4923 = _4921.w;
                            if (_4923 <= 0.0)
                            {
                                _6062 = 1.0;
                                break;
                            }
                            float3 _4932 = _4921.xyz / float3(_4923);
                            float _4934 = _4932.x;
                            bool _4935 = _4934 < 0.0;
                            bool _4942;
                            if (!_4935)
                            {
                                _4942 = _4934 > 1.0;
                            }
                            else
                            {
                                _4942 = _4935;
                            }
                            bool _4949;
                            if (!_4942)
                            {
                                _4949 = _4932.y < 0.0;
                            }
                            else
                            {
                                _4949 = _4942;
                            }
                            bool _4956;
                            if (!_4949)
                            {
                                _4956 = _4932.y > 1.0;
                            }
                            else
                            {
                                _4956 = _4949;
                            }
                            bool _4963;
                            if (!_4956)
                            {
                                _4963 = _4932.z > 1.0;
                            }
                            else
                            {
                                _4963 = _4956;
                            }
                            if (_4963)
                            {
                                _6062 = 1.0;
                                break;
                            }
                            float _4969 = _4932.z;
                            float2 _5135 = _173._m22.xy * 0.5;
                            float2 _5140 = _173._m26[_4774].xy + (_4932.xy * _173._m23.zw);
                            float4 _5153 = float4(_173._m26[_4774].xy + _5135, (_173._m26[_4774].xy + _173._m23.zw) - _5135);
                            float _6061;
                            do
                            {
                                int _5179 = int(_173._m22.z);
                                if (_5179 <= 0)
                                {
                                    float2 _5189 = fast::clamp(_5140, _5153.xy, _5153.zw);
                                    _6061 = spvDepthCast(_193).sample_compare(_193Smplr, float3(_5189, _4969).xy, _4969);
                                    break;
                                }
                                float2 _5202 = (_5140 / _173._m22.xy) + float2(0.5);
                                float2 _5203 = floor(_5202);
                                float2 _5208 = _5202 - _5203;
                                float2 _5211 = _5203 - float2(0.5);
                                bool _5215 = _5179 == 1;
                                if (_5215)
                                {
                                    float2 _5218 = _5208 * 2.0;
                                    _5163[0] = float2(3.0) - _5218;
                                    _5163[1] = float2(1.0) + _5218;
                                    _5164[0] = ((float2(2.0) - _5208) / _5163[0]) - float2(1.0);
                                    _5164[1] = (_5208 / _5163[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _5245 = _5208 * 3.0;
                                    _5163[0] = float2(4.0) - _5245;
                                    _5163[1] = float2(7.0);
                                    _5163[2] = float2(1.0) + _5245;
                                    _5164[0] = ((float2(3.0) - (_5208 * 2.0)) / _5163[0]) - float2(2.0);
                                    _5164[1] = (float2(3.0) + _5208) / _5163[1];
                                    _5164[2] = (_5208 / _5163[2]) + float2(2.0);
                                }
                                int _6413 = _5215 ? 2 : 3;
                                int _6051;
                                float _6054;
                                _6054 = 0.0;
                                _6051 = 0;
                                float _6060;
                                for (; _6051 < _6413; _6054 = _6060, _6051++)
                                {
                                    _6060 = _6054;
                                    for (int _6057 = 0; _6057 < _6413; )
                                    {
                                        _6060 += ((_5163[_6057].x * _5163[_6051].y) * spvDepthCast(_193).sample_compare(_193Smplr, float3(fast::clamp(_173._m22.xy * (_5211 + float2(_5164[_6057].x, _5164[_6051].y)), _5153.xy, _5153.zw), _4969).xy, _4969));
                                        _6057++;
                                        continue;
                                    }
                                }
                                _6061 = _6054 * (_5215 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _6062 = _6061;
                            break;
                        }
                        uint _4979 = _4774 - _4875;
                        if (_4979 >= uint(_173._m21.w))
                        {
                            _6062 = 1.0;
                            break;
                        }
                        float _5000 = _173._m27[_4979].w * length(in.m_1444 - _173._m27[_4979].xyz);
                        float3 _5018 = ((in.m_1444 + (_1816 * (_5000 * _173._m25.x))) + (_4808 * (_5000 * _173._m25.y))) - _173._m27[_4979].xyz;
                        float3 _5020 = abs(_5018);
                        float _5022 = _5020.x;
                        float _5024 = _5020.y;
                        bool _5025 = _5022 >= _5024;
                        bool _5033;
                        if (_5025)
                        {
                            _5033 = _5022 >= _5020.z;
                        }
                        else
                        {
                            _5033 = _5025;
                        }
                        float _6036;
                        int _6038;
                        if (_5033)
                        {
                            _6038 = (_5018.x > 0.0) ? 0 : 1;
                            _6036 = _5022;
                        }
                        else
                        {
                            float _5045 = _5020.z;
                            bool _5046 = _5024 >= _5045;
                            int _6039;
                            if (_5046)
                            {
                                _6039 = (_5018.y > 0.0) ? 2 : 3;
                            }
                            else
                            {
                                _6039 = (_5018.z > 0.0) ? 4 : 5;
                            }
                            _6038 = _6039;
                            _6036 = _5046 ? _5024 : _5045;
                        }
                        if (_6036 <= 0.0)
                        {
                            _6062 = 1.0;
                            break;
                        }
                        float2 _5083 = float2(dot(_5018, _851[_6038]), dot(_5018, _860[_6038])) / float2(_6036 * _173._m24.z);
                        float _5090 = _173._m28[_4979].z + (_173._m28[_4979].w / _6036);
                        if (_5090 > 1.0)
                        {
                            _6062 = 1.0;
                            break;
                        }
                        float2 _5108 = _173._m28[_4979].xy + (float2(float(spvSMod(_6038, 3)), float(_6038 / 3)) * _173._m24.xy);
                        float2 _5348 = _173._m22.xy * 0.5;
                        float2 _5353 = _5108 + (float2(0.5 + (0.5 * _5083.x), 0.5 - (0.5 * _5083.y)) * _173._m24.xy);
                        float4 _5366 = float4(_5108 + _5348, (_5108 + _173._m24.xy) - _5348);
                        float _6050;
                        do
                        {
                            int _5392 = int(_173._m22.z);
                            if (_5392 <= 0)
                            {
                                _6050 = spvDepthCast(_193).sample_compare(_193Smplr, float3(fast::clamp(_5353, _5366.xy, _5366.zw), _5090).xy, _5090);
                                break;
                            }
                            float2 _5415 = (_5353 / _173._m22.xy) + float2(0.5);
                            float2 _5416 = floor(_5415);
                            float2 _5421 = _5415 - _5416;
                            float2 _5424 = _5416 - float2(0.5);
                            bool _5428 = _5392 == 1;
                            if (_5428)
                            {
                                float2 _5431 = _5421 * 2.0;
                                _5376[0] = float2(3.0) - _5431;
                                _5376[1] = float2(1.0) + _5431;
                                _5377[0] = ((float2(2.0) - _5421) / _5376[0]) - float2(1.0);
                                _5377[1] = (_5421 / _5376[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _5458 = _5421 * 3.0;
                                _5376[0] = float2(4.0) - _5458;
                                _5376[1] = float2(7.0);
                                _5376[2] = float2(1.0) + _5458;
                                _5377[0] = ((float2(3.0) - (_5421 * 2.0)) / _5376[0]) - float2(2.0);
                                _5377[1] = (float2(3.0) + _5421) / _5376[1];
                                _5377[2] = (_5421 / _5376[2]) + float2(2.0);
                            }
                            int _6416 = _5428 ? 2 : 3;
                            int _6040;
                            float _6043;
                            _6043 = 0.0;
                            _6040 = 0;
                            float _6049;
                            for (; _6040 < _6416; _6043 = _6049, _6040++)
                            {
                                _6049 = _6043;
                                for (int _6046 = 0; _6046 < _6416; )
                                {
                                    _6049 += ((_5376[_6046].x * _5376[_6040].y) * spvDepthCast(_193).sample_compare(_193Smplr, float3(fast::clamp(_173._m22.xy * (_5424 + float2(_5377[_6046].x, _5377[_6040].y)), _5366.xy, _5366.zw), _5090).xy, _5090));
                                    _6046++;
                                    continue;
                                }
                            }
                            _6050 = _6043 * (_5428 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _6062 = _6050;
                        break;
                    } while(false);
                    _6104 = _4839 * _6062;
                }
                else
                {
                    _6104 = _4839;
                }
                float3 _2216 = fast::normalize(_4808 + _1805);
                float _2221 = fast::clamp(dot(_5978, _4808), 0.0, 1.0);
                float _2226 = fast::clamp(dot(_5978, _2216), 0.0, 1.0);
                float3 _5563 = _2040 + (_4066 * powr(1.0 - fast::clamp(dot(_1805, _2216), 0.0, 1.0), 5.0));
                float _5577 = ((_2226 * _2226) * _4081) + 1.0;
                _2264 = _6106 + (((((float3(1.0) - _5563) * _2033) + ((_5563 * ((_4076 / ((3.1415927410125732421875 * _5577) * _5577)) * (0.5 / fast::max((_2221 * _4107) + (_2045 * sqrt(((_2221 * _2221) * _4103) + _4076)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875)) * _2221) * _6104);
            }
            _6151 = _6106;
        }
        else
        {
            _6151 = _2164;
        }
        _6148 = _6151;
    }
    out.m_2302 = float4(mix(mix(_6148, _5976, float3(_1620._m1.y)) + (_1620._m5.xyz * _2276.sample(_1210, _1639).xyz), _173._m7.xyz, float3(1.0 - exp((-length(_1804)) * _173._m7.w))), in.m_1648.w);
    float2 _6242;
    do
    {
        if (in.m_2318.w <= 0.0)
        {
            _6242 = float2(0.0);
            break;
        }
        _6242 = ((in.m_2318.xy / float2(in.m_2318.w)) - (in.m_2317.xy / float2(in.m_2317.w))) * float2(0.5, -0.5);
        break;
    } while(false);
    out.m_2316 = _6242;
    return out;
}

