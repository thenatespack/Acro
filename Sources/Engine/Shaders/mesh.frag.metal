// Generated from mesh.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: c8272897864c6f00
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
    float4 m_2289 [[color(0)]];
    float2 m_2303 [[color(1)]];
};

struct fragment_main_in
{
    float3 m_1444 [[user(locn0)]];
    float3 m_1692 [[user(locn1)]];
    float2 m_1625 [[user(locn2)]];
    float4 m_1648 [[user(locn3)]];
    float4 m_1805 [[user(locn5)]];
    float4 m_2304 [[user(locn6)]];
    float4 m_2305 [[user(locn7)]];
    float4 m_1701 [[user(locn8)]];
};

fragment fragment_main_out fragment_main(fragment_main_in in [[stage_in]], constant _1618& _1620 [[buffer(2)]], constant _1434& _1436 [[buffer(3)]], constant _1470& _1472 [[buffer(4)]], constant _1478& _1480 [[buffer(5)]], constant _1575& _1577 [[buffer(6)]], constant _1597& _1599 [[buffer(7)]], constant _171& _173 [[buffer(15)]], texture2d<float> _193 [[texture(0)]], texture2d<float> _1641 [[texture(1)]], texture2d<float> _1991 [[texture(2)]], texture2d<float> _1730 [[texture(3)]], texture2d<float> _1838 [[texture(4)]], texture2d<float> _2263 [[texture(5)]], texture2d<float> _1208 [[texture(6)]], texture2d<float> _1314 [[texture(7)]], sampler _193Smplr [[sampler(0)]], sampler _1210 [[sampler(1)]], sampler _1316 [[sampler(7)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])
{
    fragment_main_out out = {};
    float2 _1639 = float2(dot(_1620._m2.xy, in.m_1625) + _1620._m2.z, dot(_1620._m3.xy, in.m_1625) + _1620._m3.z);
    float4 _1646 = _1641.sample(_1210, _1639);
    float3 _1657 = (in.m_1648.xyz * _1620._m0.xyz) * _1646.xyz;
    float3 _5941;
    if (_1620._m1.x > 0.5)
    {
        float2 _1678 = floor(in.m_1444.xz * float2(0.5));
        _5941 = _1657 * ((mod(abs(_1678.x + _1678.y), 2.0) < 0.5) ? 1.0 : 0.75);
    }
    else
    {
        _5941 = _1657;
    }
    float3 _1694 = fast::normalize(in.m_1692);
    float3 _5855;
    if (_1620._m6.y > 0.5)
    {
        float3 _1710 = in.m_1701.xyz - (_1694 * dot(_1694, in.m_1701.xyz));
        float3 _5856;
        if (dot(_1710, _1710) > 9.9999999600419720025001879548654e-13)
        {
            float3 _1719 = fast::normalize(_1710);
            float3 _1739 = (_1730.sample(_1210, _1639).xyz * 2.0) - float3(1.0);
            float2 _1744 = _1739.xy * _1620._m4.z;
            _5856 = fast::normalize(((_1719 * _1744.x) + ((cross(_1694, _1719) * ((in.m_1701.w < 0.0) ? (-1.0) : 1.0)) * _1744.y)) + (_1694 * _1739.z));
        }
        else
        {
            _5856 = _1694;
        }
        _5855 = _5856;
    }
    else
    {
        _5855 = _1694;
    }
    bool _1768 = _1620._m5.w > 0.5;
    bool _1776;
    if (_1768)
    {
        _1776 = !gl_FrontFacing;
    }
    else
    {
        _1776 = _1768;
    }
    float3 _5964;
    if (_1776)
    {
        _5964 = -_5855;
    }
    else
    {
        _5964 = _5855;
    }
    float3 _1785 = fast::normalize(_173._m4.xyz);
    float3 _1791 = _173._m6.xyz - in.m_1444;
    float3 _1792 = fast::normalize(_1791);
    float3 _1797 = fast::normalize(_1785 + _1792);
    float3 _1803 = _1694 * (gl_FrontFacing ? 1.0 : (-1.0));
    bool _1808 = in.m_1805.x > 0.5;
    float3 _5962;
    float _5987;
    if ((_173._m5.w > 0.5) && _1808)
    {
        float _5912;
        float3 _5913;
        do
        {
            int _2358 = int(_173._m21.x);
            float _2366 = dot(_173._m20.xyz, in.m_1444) + _173._m20.w;
            int _5857;
            _5857 = 0;
            for (;;)
            {
                bool _2372 = _5857 < (_2358 - 1);
                bool _2380;
                if (_2372)
                {
                    _2380 = _2366 > _173._m16[_5857];
                }
                else
                {
                    _2380 = _2372;
                }
                if (_2380)
                {
                    _5857++;
                    continue;
                }
                else
                {
                    break;
                }
            }
            if (_2366 > _173._m16[_5857])
            {
                _5913 = float3(1.0);
                _5912 = 1.0;
                break;
            }
            float _5870;
            do
            {
                float4 _2482 = _173._m14[_5857] * float4(in.m_1444 + (_1803 * _173._m18[_5857]), 1.0);
                float _2485 = _2482.x;
                bool _2486 = _2485 < 0.0;
                bool _2493;
                if (!_2486)
                {
                    _2493 = _2485 > 1.0;
                }
                else
                {
                    _2493 = _2486;
                }
                bool _2500;
                if (!_2493)
                {
                    _2500 = _2482.y < 0.0;
                }
                else
                {
                    _2500 = _2493;
                }
                bool _2507;
                if (!_2500)
                {
                    _2507 = _2482.y > 1.0;
                }
                else
                {
                    _2507 = _2500;
                }
                if (_2507)
                {
                    _5870 = 1.0;
                    break;
                }
                float2 _2520 = float2(float(_5857 & 1), float(_5857 >> 1)) * _173._m23.xy;
                float _2527 = fast::min(_2482.z, 1.0) - _173._m19[_5857];
                float2 _2546 = _173._m22.xy * 0.5;
                float2 _2551 = _2520 + (_2482.xy * _173._m23.xy);
                float4 _2564 = float4(_2520 + _2546, (_2520 + _173._m23.xy) - _2546);
                float _5869;
                do
                {
                    int _2590 = int(_173._m22.z);
                    if (_2590 <= 0)
                    {
                        _5869 = spvDepthCast(_193).sample_compare(_193Smplr, float3(fast::clamp(_2551, _2564.xy, _2564.zw), _2527).xy, _2527);
                        break;
                    }
                    float2 _2613 = (_2551 / _173._m22.xy) + float2(0.5);
                    float2 _2614 = floor(_2613);
                    float2 _2619 = _2613 - _2614;
                    float2 _2622 = _2614 - float2(0.5);
                    bool _2626 = _2590 == 1;
                    spvUnsafeArray<float2, 3> _2574;
                    spvUnsafeArray<float2, 3> _2575;
                    if (_2626)
                    {
                        float2 _2629 = _2619 * 2.0;
                        _2574[0] = float2(3.0) - _2629;
                        _2574[1] = float2(1.0) + _2629;
                        _2575[0] = ((float2(2.0) - _2619) / _2574[0]) - float2(1.0);
                        _2575[1] = (_2619 / _2574[1]) + float2(1.0);
                    }
                    else
                    {
                        float2 _2656 = _2619 * 3.0;
                        _2574[0] = float2(4.0) - _2656;
                        _2574[1] = float2(7.0);
                        _2574[2] = float2(1.0) + _2656;
                        _2575[0] = ((float2(3.0) - (_2619 * 2.0)) / _2574[0]) - float2(2.0);
                        _2575[1] = (float2(3.0) + _2619) / _2574[1];
                        _2575[2] = (_2619 / _2574[2]) + float2(2.0);
                    }
                    int _6308 = _2626 ? 2 : 3;
                    int _5859;
                    float _5862;
                    _5862 = 0.0;
                    _5859 = 0;
                    float _5868;
                    for (; _5859 < _6308; _5862 = _5868, _5859++)
                    {
                        _5868 = _5862;
                        for (int _5865 = 0; _5865 < _6308; )
                        {
                            _5868 += ((_2574[_5865].x * _2574[_5859].y) * spvDepthCast(_193).sample_compare(_193Smplr, float3(fast::clamp(_173._m22.xy * (_2622 + float2(_2575[_5865].x, _2575[_5859].y)), _2564.xy, _2564.zw), _2527).xy, _2527));
                            _5865++;
                            continue;
                        }
                    }
                    _5869 = _5862 * (_2626 ? 0.0625 : 0.0069444444961845874786376953125);
                    break;
                } while(false);
                _5870 = _5869;
                break;
            } while(false);
            float3 _5907;
            float _5910;
            if (_2366 > _173._m17[_5857])
            {
                float _2420 = (_2366 - _173._m17[_5857]) / (_173._m16[_5857] - _173._m17[_5857]);
                int _2422 = _5857 + 1;
                float3 _5908;
                float _5911;
                if (_2422 < _2358)
                {
                    float _5890;
                    do
                    {
                        float4 _2769 = _173._m14[_2422] * float4(in.m_1444 + (_1803 * _173._m18[_2422]), 1.0);
                        float _2772 = _2769.x;
                        bool _2773 = _2772 < 0.0;
                        bool _2780;
                        if (!_2773)
                        {
                            _2780 = _2772 > 1.0;
                        }
                        else
                        {
                            _2780 = _2773;
                        }
                        bool _2787;
                        if (!_2780)
                        {
                            _2787 = _2769.y < 0.0;
                        }
                        else
                        {
                            _2787 = _2780;
                        }
                        bool _2794;
                        if (!_2787)
                        {
                            _2794 = _2769.y > 1.0;
                        }
                        else
                        {
                            _2794 = _2787;
                        }
                        if (_2794)
                        {
                            _5890 = 1.0;
                            break;
                        }
                        float2 _2807 = float2(float(_2422 & 1), float(_2422 >> 1)) * _173._m23.xy;
                        float _2814 = fast::min(_2769.z, 1.0) - _173._m19[_2422];
                        float2 _2833 = _173._m22.xy * 0.5;
                        float2 _2838 = _2807 + (_2769.xy * _173._m23.xy);
                        float4 _2851 = float4(_2807 + _2833, (_2807 + _173._m23.xy) - _2833);
                        float _5889;
                        do
                        {
                            int _2877 = int(_173._m22.z);
                            if (_2877 <= 0)
                            {
                                _5889 = spvDepthCast(_193).sample_compare(_193Smplr, float3(fast::clamp(_2838, _2851.xy, _2851.zw), _2814).xy, _2814);
                                break;
                            }
                            float2 _2900 = (_2838 / _173._m22.xy) + float2(0.5);
                            float2 _2901 = floor(_2900);
                            float2 _2906 = _2900 - _2901;
                            float2 _2909 = _2901 - float2(0.5);
                            bool _2913 = _2877 == 1;
                            spvUnsafeArray<float2, 3> _2861;
                            spvUnsafeArray<float2, 3> _2862;
                            if (_2913)
                            {
                                float2 _2916 = _2906 * 2.0;
                                _2861[0] = float2(3.0) - _2916;
                                _2861[1] = float2(1.0) + _2916;
                                _2862[0] = ((float2(2.0) - _2906) / _2861[0]) - float2(1.0);
                                _2862[1] = (_2906 / _2861[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _2943 = _2906 * 3.0;
                                _2861[0] = float2(4.0) - _2943;
                                _2861[1] = float2(7.0);
                                _2861[2] = float2(1.0) + _2943;
                                _2862[0] = ((float2(3.0) - (_2906 * 2.0)) / _2861[0]) - float2(2.0);
                                _2862[1] = (float2(3.0) + _2906) / _2861[1];
                                _2862[2] = (_2906 / _2861[2]) + float2(2.0);
                            }
                            int _6310 = _2913 ? 2 : 3;
                            int _5879;
                            float _5882;
                            _5882 = 0.0;
                            _5879 = 0;
                            float _5888;
                            for (; _5879 < _6310; _5882 = _5888, _5879++)
                            {
                                _5888 = _5882;
                                for (int _5885 = 0; _5885 < _6310; )
                                {
                                    _5888 += ((_2861[_5885].x * _2861[_5879].y) * spvDepthCast(_193).sample_compare(_193Smplr, float3(fast::clamp(_173._m22.xy * (_2909 + float2(_2862[_5885].x, _2862[_5879].y)), _2851.xy, _2851.zw), _2814).xy, _2814));
                                    _5885++;
                                    continue;
                                }
                            }
                            _5889 = _5882 * (_2913 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _5890 = _5889;
                        break;
                    } while(false);
                    _5911 = mix(_5870, _5890, _2420);
                    _5908 = mix(_547[_5857], _547[_2422], float3(_2420));
                }
                else
                {
                    _5911 = mix(_5870, 1.0, _2420);
                    _5908 = _547[_5857];
                }
                _5910 = _5911;
                _5907 = _5908;
            }
            else
            {
                _5910 = _5870;
                _5907 = _547[_5857];
            }
            _5913 = select(float3(1.0), _5907, bool3(_173._m22.w > 0.5));
            _5912 = _5910;
            break;
        } while(false);
        _5987 = _5912;
        _5962 = _5941 * _5913;
    }
    else
    {
        _5987 = 1.0;
        _5962 = _5941;
    }
    float3 _1834 = _173._m5.xyz * _173._m4.w;
    float4 _1843 = _1838.sample(_1210, _1639);
    float _1847 = 1.0 + (_1620._m4.w * (_1843.x - 1.0));
    float3 _6134;
    if (!_1768)
    {
        float _1855 = dot(_5964, _1785);
        float3 _6128;
        if (_173._m29.x > 0.5)
        {
            float _3094 = (_173._m29.z * _5964.x) - (_173._m29.w * _5964.z);
            float _3107 = (_173._m29.w * _5964.x) + (_173._m29.z * _5964.z);
            float _3125 = 1.09254801273345947265625 * _3094;
            spvUnsafeArray<float, 9> _5669 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _5964.y, 0.48860299587249755859375 * _3107, 0.48860299587249755859375 * _3094, _3125 * _5964.y, (1.09254801273345947265625 * _5964.y) * _3107, 0.3153919875621795654296875 * (((3.0 * _3107) * _3107) - 1.0), _3125 * _3107, 0.546274006366729736328125 * ((_3094 * _3094) - (_5964.y * _5964.y)) });
            spvUnsafeArray<float, 9> _3039 = _5669;
            float3 _6127;
            _6127 = float3(0.0);
            for (int _6126 = 0; _6126 < 9; )
            {
                _6127 += (_1208.read(uint2((int2(496, 256) + int2(_6126, 0))), 0).xyz * _3039[_6126]);
                _6126++;
                continue;
            }
            _6128 = fast::max(_6127, float3(0.0)) * _173._m29.y;
        }
        else
        {
            _6128 = mix(_173._m9.xyz, _173._m8.xyz, float3((_5964.y * 0.5) + 0.5)) * _173._m8.w;
        }
        float3 _1905 = (_5962 * ((_6128 * _1847) + ((_1834 * fast::max(_1855, 0.0)) * _5987))) + ((_1834 * ((powr(fast::max(dot(_5964, _1797), 0.0), _1620._m1.w) * _1620._m1.z) * step(0.0, _1855))) * _5987);
        float3 _6135;
        if (_173._m13.w > 0.5)
        {
            float2 _3210 = fast::clamp(floor(gl_FragCoord.xy * _173._m12.xy), float2(0.0), _173._m13.xy - float2(1.0));
            uint _3238 = uint((((fast::clamp(floor((log2(fast::max(dot(_173._m11.xyz, in.m_1444) + _173._m11.w, 9.9999999747524270787835121154785e-07)) * _173._m12.z) + _173._m12.w), 0.0, _173._m13.z - 1.0) * _173._m13.y) + _3210.y) * _173._m13.x) + _3210.x);
            uint _3240 = _3238 >> uint(2);
            uint _3242 = _3238 & 3u;
            uint _3246 = _1577._m0[_3240][_3242] & 65535u;
            uint _3248 = _1577._m0[_3240][_3242] >> uint(16);
            float3 _6136;
            _6136 = _1905;
            float3 _1986;
            spvUnsafeArray<float2, 3> _3656;
            spvUnsafeArray<float2, 3> _3657;
            spvUnsafeArray<float2, 3> _3869;
            spvUnsafeArray<float2, 3> _3870;
            for (uint _6133 = _3246; _6133 < (_3246 + _3248); _6136 = _1986, _6133++)
            {
                uint _3254 = _6133 / 3u;
                uint _3267 = (_1599._m0[_3254 >> uint(2)][_3254 & 3u] >> ((_6133 - (_3254 * 3u)) * 10u)) & 1023u;
                float3 _3284 = _1436._m0[_3267].xyz - in.m_1444;
                float _3287 = dot(_3284, _3284);
                float _3291 = _3287 * _1436._m0[_3267].w;
                float _3296 = fast::clamp(1.0 - (_3291 * _3291), 0.0, 1.0);
                float3 _3301 = _3284 * rsqrt(fast::max(_3287, 9.9999999392252902907785028219223e-09));
                float _3319 = fast::clamp((dot(-_3301, _1480._m0[_3267].xyz) * _1472._m0[_3267].w) + _1480._m0[_3267].w, 0.0, 1.0);
                float3 _3332 = _1472._m0[_3267].xyz * ((((_3296 * _3296) * _3319) * _3319) / fast::max(_3287, 9.9999997473787516355514526367188e-05));
                float3 _6249;
                if (_1808)
                {
                    float _6195;
                    do
                    {
                        uint _3368 = uint(_173._m21.z);
                        if (_3267 < _3368)
                        {
                            float _3390 = _173._m26[_3267].z * fast::max((_173._m15[_3267] * float4(in.m_1444, 1.0)).w, 0.0);
                            float4 _3414 = _173._m15[_3267] * float4((in.m_1444 + (_1803 * (_3390 * _173._m25.x))) + (_3301 * (_3390 * _173._m25.y)), 1.0);
                            float _3416 = _3414.w;
                            if (_3416 <= 0.0)
                            {
                                _6195 = 1.0;
                                break;
                            }
                            float3 _3425 = _3414.xyz / float3(_3416);
                            float _3427 = _3425.x;
                            bool _3428 = _3427 < 0.0;
                            bool _3435;
                            if (!_3428)
                            {
                                _3435 = _3427 > 1.0;
                            }
                            else
                            {
                                _3435 = _3428;
                            }
                            bool _3442;
                            if (!_3435)
                            {
                                _3442 = _3425.y < 0.0;
                            }
                            else
                            {
                                _3442 = _3435;
                            }
                            bool _3449;
                            if (!_3442)
                            {
                                _3449 = _3425.y > 1.0;
                            }
                            else
                            {
                                _3449 = _3442;
                            }
                            bool _3456;
                            if (!_3449)
                            {
                                _3456 = _3425.z > 1.0;
                            }
                            else
                            {
                                _3456 = _3449;
                            }
                            if (_3456)
                            {
                                _6195 = 1.0;
                                break;
                            }
                            float _3462 = _3425.z;
                            float2 _3628 = _173._m22.xy * 0.5;
                            float2 _3633 = _173._m26[_3267].xy + (_3425.xy * _173._m23.zw);
                            float4 _3646 = float4(_173._m26[_3267].xy + _3628, (_173._m26[_3267].xy + _173._m23.zw) - _3628);
                            float _6194;
                            do
                            {
                                int _3672 = int(_173._m22.z);
                                if (_3672 <= 0)
                                {
                                    float2 _3682 = fast::clamp(_3633, _3646.xy, _3646.zw);
                                    _6194 = spvDepthCast(_193).sample_compare(_193Smplr, float3(_3682, _3462).xy, _3462);
                                    break;
                                }
                                float2 _3695 = (_3633 / _173._m22.xy) + float2(0.5);
                                float2 _3696 = floor(_3695);
                                float2 _3701 = _3695 - _3696;
                                float2 _3704 = _3696 - float2(0.5);
                                bool _3708 = _3672 == 1;
                                if (_3708)
                                {
                                    float2 _3711 = _3701 * 2.0;
                                    _3656[0] = float2(3.0) - _3711;
                                    _3656[1] = float2(1.0) + _3711;
                                    _3657[0] = ((float2(2.0) - _3701) / _3656[0]) - float2(1.0);
                                    _3657[1] = (_3701 / _3656[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _3738 = _3701 * 3.0;
                                    _3656[0] = float2(4.0) - _3738;
                                    _3656[1] = float2(7.0);
                                    _3656[2] = float2(1.0) + _3738;
                                    _3657[0] = ((float2(3.0) - (_3701 * 2.0)) / _3656[0]) - float2(2.0);
                                    _3657[1] = (float2(3.0) + _3701) / _3656[1];
                                    _3657[2] = (_3701 / _3656[2]) + float2(2.0);
                                }
                                int _6315 = _3708 ? 2 : 3;
                                int _6184;
                                float _6187;
                                _6187 = 0.0;
                                _6184 = 0;
                                float _6193;
                                for (; _6184 < _6315; _6187 = _6193, _6184++)
                                {
                                    _6193 = _6187;
                                    for (int _6190 = 0; _6190 < _6315; )
                                    {
                                        _6193 += ((_3656[_6190].x * _3656[_6184].y) * spvDepthCast(_193).sample_compare(_193Smplr, float3(fast::clamp(_173._m22.xy * (_3704 + float2(_3657[_6190].x, _3657[_6184].y)), _3646.xy, _3646.zw), _3462).xy, _3462));
                                        _6190++;
                                        continue;
                                    }
                                }
                                _6194 = _6187 * (_3708 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _6195 = _6194;
                            break;
                        }
                        uint _3472 = _3267 - _3368;
                        if (_3472 >= uint(_173._m21.w))
                        {
                            _6195 = 1.0;
                            break;
                        }
                        float _3493 = _173._m27[_3472].w * length(in.m_1444 - _173._m27[_3472].xyz);
                        float3 _3511 = ((in.m_1444 + (_1803 * (_3493 * _173._m25.x))) + (_3301 * (_3493 * _173._m25.y))) - _173._m27[_3472].xyz;
                        float3 _3513 = abs(_3511);
                        float _3515 = _3513.x;
                        float _3517 = _3513.y;
                        bool _3518 = _3515 >= _3517;
                        bool _3526;
                        if (_3518)
                        {
                            _3526 = _3515 >= _3513.z;
                        }
                        else
                        {
                            _3526 = _3518;
                        }
                        float _6169;
                        int _6171;
                        if (_3526)
                        {
                            _6171 = (_3511.x > 0.0) ? 0 : 1;
                            _6169 = _3515;
                        }
                        else
                        {
                            float _3538 = _3513.z;
                            bool _3539 = _3517 >= _3538;
                            int _6172;
                            if (_3539)
                            {
                                _6172 = (_3511.y > 0.0) ? 2 : 3;
                            }
                            else
                            {
                                _6172 = (_3511.z > 0.0) ? 4 : 5;
                            }
                            _6171 = _6172;
                            _6169 = _3539 ? _3517 : _3538;
                        }
                        if (_6169 <= 0.0)
                        {
                            _6195 = 1.0;
                            break;
                        }
                        float2 _3576 = float2(dot(_3511, _851[_6171]), dot(_3511, _860[_6171])) / float2(_6169 * _173._m24.z);
                        float _3583 = _173._m28[_3472].z + (_173._m28[_3472].w / _6169);
                        if (_3583 > 1.0)
                        {
                            _6195 = 1.0;
                            break;
                        }
                        float2 _3601 = _173._m28[_3472].xy + (float2(float(spvSMod(_6171, 3)), float(_6171 / 3)) * _173._m24.xy);
                        float2 _3841 = _173._m22.xy * 0.5;
                        float2 _3846 = _3601 + (float2(0.5 + (0.5 * _3576.x), 0.5 - (0.5 * _3576.y)) * _173._m24.xy);
                        float4 _3859 = float4(_3601 + _3841, (_3601 + _173._m24.xy) - _3841);
                        float _6183;
                        do
                        {
                            int _3885 = int(_173._m22.z);
                            if (_3885 <= 0)
                            {
                                _6183 = spvDepthCast(_193).sample_compare(_193Smplr, float3(fast::clamp(_3846, _3859.xy, _3859.zw), _3583).xy, _3583);
                                break;
                            }
                            float2 _3908 = (_3846 / _173._m22.xy) + float2(0.5);
                            float2 _3909 = floor(_3908);
                            float2 _3914 = _3908 - _3909;
                            float2 _3917 = _3909 - float2(0.5);
                            bool _3921 = _3885 == 1;
                            if (_3921)
                            {
                                float2 _3924 = _3914 * 2.0;
                                _3869[0] = float2(3.0) - _3924;
                                _3869[1] = float2(1.0) + _3924;
                                _3870[0] = ((float2(2.0) - _3914) / _3869[0]) - float2(1.0);
                                _3870[1] = (_3914 / _3869[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _3951 = _3914 * 3.0;
                                _3869[0] = float2(4.0) - _3951;
                                _3869[1] = float2(7.0);
                                _3869[2] = float2(1.0) + _3951;
                                _3870[0] = ((float2(3.0) - (_3914 * 2.0)) / _3869[0]) - float2(2.0);
                                _3870[1] = (float2(3.0) + _3914) / _3869[1];
                                _3870[2] = (_3914 / _3869[2]) + float2(2.0);
                            }
                            int _6318 = _3921 ? 2 : 3;
                            int _6173;
                            float _6176;
                            _6176 = 0.0;
                            _6173 = 0;
                            float _6182;
                            for (; _6173 < _6318; _6176 = _6182, _6173++)
                            {
                                _6182 = _6176;
                                for (int _6179 = 0; _6179 < _6318; )
                                {
                                    _6182 += ((_3869[_6179].x * _3869[_6173].y) * spvDepthCast(_193).sample_compare(_193Smplr, float3(fast::clamp(_173._m22.xy * (_3917 + float2(_3870[_6179].x, _3870[_6173].y)), _3859.xy, _3859.zw), _3583).xy, _3583));
                                    _6179++;
                                    continue;
                                }
                            }
                            _6183 = _6176 * (_3921 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _6195 = _6183;
                        break;
                    } while(false);
                    _6249 = _3332 * _6195;
                }
                else
                {
                    _6249 = _3332;
                }
                float _1957 = dot(_5964, _3301);
                _1986 = _6136 + (((_5962 * fast::max(_1957, 0.0)) * _6249) + (_6249 * ((powr(fast::max(dot(_5964, fast::normalize(_3301 + _1792)), 0.0), _1620._m1.w) * _1620._m1.z) * step(0.0, _1957))));
            }
            _6135 = _6136;
        }
        else
        {
            _6135 = _1905;
        }
        _6134 = _6135;
    }
    else
    {
        float4 _1996 = _1991.sample(_1210, _1639);
        float _2003 = fast::clamp(_1620._m4.x * _1996.z, 0.0, 1.0);
        float _2011 = fast::clamp(_1620._m4.y * _1996.y, 0.04500000178813934326171875, 1.0);
        float _2015 = _2011 * _2011;
        float3 _2020 = _5962 * (1.0 - _2003);
        float3 _2027 = mix(float3(0.039999999105930328369140625), _5962, float3(_2003));
        float _2032 = fast::max(dot(_5964, _1792), 9.9999997473787516355514526367188e-05);
        float _2037 = fast::clamp(dot(_5964, _1785), 0.0, 1.0);
        float _2042 = fast::clamp(dot(_5964, _1797), 0.0, 1.0);
        float3 _4053 = float3(1.0) - _2027;
        float3 _4056 = _2027 + (_4053 * powr(1.0 - fast::clamp(dot(_1792, _1797), 0.0, 1.0), 5.0));
        float _4063 = _2015 * _2015;
        float _4068 = _4063 - 1.0;
        float _4070 = ((_2042 * _2042) * _4068) + 1.0;
        float _4090 = 1.0 - _4063;
        float _4094 = sqrt(((_2032 * _2032) * _4090) + _4063);
        float2 _6005;
        float3 _6013;
        float3 _6020;
        if (_173._m29.x > 0.5)
        {
            float4 _4127 = _1314.sample(_1316, (((float2(_2032, _2011) * 31.0) + float2(0.5)) * float2(0.03125)));
            float _4186 = (_173._m29.z * _5964.x) - (_173._m29.w * _5964.z);
            float _4199 = (_173._m29.w * _5964.x) + (_173._m29.z * _5964.z);
            float _4217 = 1.09254801273345947265625 * _4186;
            spvUnsafeArray<float, 9> _5650 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _5964.y, 0.48860299587249755859375 * _4199, 0.48860299587249755859375 * _4186, _4217 * _5964.y, (1.09254801273345947265625 * _5964.y) * _4199, 0.3153919875621795654296875 * (((3.0 * _4199) * _4199) - 1.0), _4217 * _4199, 0.546274006366729736328125 * ((_4186 * _4186) - (_5964.y * _5964.y)) });
            spvUnsafeArray<float, 9> _4131 = _5650;
            float3 _5989;
            _5989 = float3(0.0);
            for (int _5988 = 0; _5988 < 9; )
            {
                _5989 += (_1208.read(uint2((int2(496, 256) + int2(_5988, 0))), 0).xyz * _4131[_5988]);
                _5988++;
                continue;
            }
            float3 _2103 = reflect(-_1792, _5964);
            float _4312 = _2103.x;
            float _4317 = _2103.z;
            float2 _4349 = float2((precise::atan2((_173._m29.z * _4312) - (_173._m29.w * _4317), -((_173._m29.w * _4312) + (_173._m29.z * _4317))) * 0.15915493667125701904296875) + 0.5, acos(fast::clamp(_2103.y, -1.0, 1.0)) * 0.3183098733425140380859375);
            float _4281 = _2011 * 5.0;
            int _4284 = min(int(_4281), 4);
            float2 _4370 = (_4349 * float2(_1270[_4284].zw)) - float2(0.5);
            float2 _4372 = floor(_4370);
            float2 _4375 = _4370 - _4372;
            int _4378 = int(_4372.x);
            int _4381 = int(_4372.y);
            int _5991;
            if (_4378 < 0)
            {
                _5991 = _4378 + _1270[_4284].z;
            }
            else
            {
                _5991 = _4378;
            }
            int _5992;
            if (_5991 >= _1270[_4284].z)
            {
                _5992 = _5991 - _1270[_4284].z;
            }
            else
            {
                _5992 = _5991;
            }
            int _4401 = _5992 + 1;
            int _6319 = (_4401 == _1270[_4284].z) ? 0 : _4401;
            int _4416 = min((_4381 + 1), (_1270[_4284].w - 1));
            int _4418 = max(_4381, 0);
            float3 _4471 = float3(_4375.x);
            int _4291 = _4284 + 1;
            float2 _4503 = (_4349 * float2(_1270[_4291].zw)) - float2(0.5);
            float2 _4505 = floor(_4503);
            float2 _4508 = _4503 - _4505;
            int _4511 = int(_4505.x);
            int _4514 = int(_4505.y);
            int _5998;
            if (_4511 < 0)
            {
                _5998 = _4511 + _1270[_4291].z;
            }
            else
            {
                _5998 = _4511;
            }
            int _5999;
            if (_5998 >= _1270[_4291].z)
            {
                _5999 = _5998 - _1270[_4291].z;
            }
            else
            {
                _5999 = _5998;
            }
            int _4534 = _5999 + 1;
            int _6320 = (_4534 == _1270[_4291].z) ? 0 : _4534;
            int _4549 = min((_4514 + 1), (_1270[_4291].w - 1));
            int _4551 = max(_4514, 0);
            float3 _4604 = float3(_4508.x);
            float3 _4306 = mix(mix(mix(_1208.read(uint2((_1270[_4284].xy + int2(_5992, _4418))), 0).xyz, _1208.read(uint2((_1270[_4284].xy + int2(_6319, _4418))), 0).xyz, _4471), mix(_1208.read(uint2((_1270[_4284].xy + int2(_5992, _4416))), 0).xyz, _1208.read(uint2((_1270[_4284].xy + int2(_6319, _4416))), 0).xyz, _4471), float3(_4375.y)), mix(mix(_1208.read(uint2((_1270[_4291].xy + int2(_5999, _4551))), 0).xyz, _1208.read(uint2((_1270[_4291].xy + int2(_6320, _4551))), 0).xyz, _4604), mix(_1208.read(uint2((_1270[_4291].xy + int2(_5999, _4549))), 0).xyz, _1208.read(uint2((_1270[_4291].xy + int2(_6320, _4549))), 0).xyz, _4604), float3(_4508.y)), float3(_4281 - float(_4284))) * _173._m29.y;
            _6020 = _4306;
            _6013 = fast::max(_5989, float3(0.0)) * _173._m29.y;
            _6005 = _4127.xy;
        }
        else
        {
            float4 _4622 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * _2011) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);
            float _4624 = _4622.x;
            float3 _4659 = mix(_173._m9.xyz, _173._m8.xyz, float3((_5964.y * 0.5) + 0.5)) * _173._m8.w;
            _6020 = mix(mix(_173._m9.xyz, _173._m8.xyz, float3((reflect(-_1792, _5964).y * 0.5) + 0.5)) * _173._m8.w, _4659, float3(_2011));
            _6013 = _4659;
            _6005 = (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_4624 * _4624, exp2((-9.27999973297119140625) * _2032)) * _4624) + _4622.y)) + _4622.zw;
        }
        float3 _2135 = (_2027 * _6005.x) + float3(_6005.y);
        float3 _2151 = ((((((float3(1.0) - _4056) * _2020) + ((_4056 * ((_4063 / ((3.1415927410125732421875 * _4070) * _4070)) * (0.5 / fast::max((_2037 * _4094) + (_2032 * sqrt(((_2037 * _2037) * _4090) + _4063)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875)) * _2037) * _1834) * _5987) + (((((float3(1.0) - _2135) * _2020) * _6013) + (_2135 * _6020)) * _1847);
        float3 _6137;
        if (_173._m13.w > 0.5)
        {
            float2 _4704 = fast::clamp(floor(gl_FragCoord.xy * _173._m12.xy), float2(0.0), _173._m13.xy - float2(1.0));
            uint _4732 = uint((((fast::clamp(floor((log2(fast::max(dot(_173._m11.xyz, in.m_1444) + _173._m11.w, 9.9999999747524270787835121154785e-07)) * _173._m12.z) + _173._m12.w), 0.0, _173._m13.z - 1.0) * _173._m13.y) + _4704.y) * _173._m13.x) + _4704.x);
            uint _4734 = _4732 >> uint(2);
            uint _4736 = _4732 & 3u;
            uint _4740 = _1577._m0[_4734][_4736] & 65535u;
            uint _4742 = _1577._m0[_4734][_4736] >> uint(16);
            float3 _6092;
            _6092 = _2151;
            float3 _2251;
            spvUnsafeArray<float2, 3> _5150;
            spvUnsafeArray<float2, 3> _5151;
            spvUnsafeArray<float2, 3> _5363;
            spvUnsafeArray<float2, 3> _5364;
            for (uint _6021 = _4740; _6021 < (_4740 + _4742); _6092 = _2251, _6021++)
            {
                uint _4748 = _6021 / 3u;
                uint _4761 = (_1599._m0[_4748 >> uint(2)][_4748 & 3u] >> ((_6021 - (_4748 * 3u)) * 10u)) & 1023u;
                float3 _4778 = _1436._m0[_4761].xyz - in.m_1444;
                float _4781 = dot(_4778, _4778);
                float _4785 = _4781 * _1436._m0[_4761].w;
                float _4790 = fast::clamp(1.0 - (_4785 * _4785), 0.0, 1.0);
                float3 _4795 = _4778 * rsqrt(fast::max(_4781, 9.9999999392252902907785028219223e-09));
                float _4813 = fast::clamp((dot(-_4795, _1480._m0[_4761].xyz) * _1472._m0[_4761].w) + _1480._m0[_4761].w, 0.0, 1.0);
                float3 _4826 = _1472._m0[_4761].xyz * ((((_4790 * _4790) * _4813) * _4813) / fast::max(_4781, 9.9999997473787516355514526367188e-05));
                float3 _6090;
                if (_1808)
                {
                    float _6048;
                    do
                    {
                        uint _4862 = uint(_173._m21.z);
                        if (_4761 < _4862)
                        {
                            float _4884 = _173._m26[_4761].z * fast::max((_173._m15[_4761] * float4(in.m_1444, 1.0)).w, 0.0);
                            float4 _4908 = _173._m15[_4761] * float4((in.m_1444 + (_1803 * (_4884 * _173._m25.x))) + (_4795 * (_4884 * _173._m25.y)), 1.0);
                            float _4910 = _4908.w;
                            if (_4910 <= 0.0)
                            {
                                _6048 = 1.0;
                                break;
                            }
                            float3 _4919 = _4908.xyz / float3(_4910);
                            float _4921 = _4919.x;
                            bool _4922 = _4921 < 0.0;
                            bool _4929;
                            if (!_4922)
                            {
                                _4929 = _4921 > 1.0;
                            }
                            else
                            {
                                _4929 = _4922;
                            }
                            bool _4936;
                            if (!_4929)
                            {
                                _4936 = _4919.y < 0.0;
                            }
                            else
                            {
                                _4936 = _4929;
                            }
                            bool _4943;
                            if (!_4936)
                            {
                                _4943 = _4919.y > 1.0;
                            }
                            else
                            {
                                _4943 = _4936;
                            }
                            bool _4950;
                            if (!_4943)
                            {
                                _4950 = _4919.z > 1.0;
                            }
                            else
                            {
                                _4950 = _4943;
                            }
                            if (_4950)
                            {
                                _6048 = 1.0;
                                break;
                            }
                            float _4956 = _4919.z;
                            float2 _5122 = _173._m22.xy * 0.5;
                            float2 _5127 = _173._m26[_4761].xy + (_4919.xy * _173._m23.zw);
                            float4 _5140 = float4(_173._m26[_4761].xy + _5122, (_173._m26[_4761].xy + _173._m23.zw) - _5122);
                            float _6047;
                            do
                            {
                                int _5166 = int(_173._m22.z);
                                if (_5166 <= 0)
                                {
                                    float2 _5176 = fast::clamp(_5127, _5140.xy, _5140.zw);
                                    _6047 = spvDepthCast(_193).sample_compare(_193Smplr, float3(_5176, _4956).xy, _4956);
                                    break;
                                }
                                float2 _5189 = (_5127 / _173._m22.xy) + float2(0.5);
                                float2 _5190 = floor(_5189);
                                float2 _5195 = _5189 - _5190;
                                float2 _5198 = _5190 - float2(0.5);
                                bool _5202 = _5166 == 1;
                                if (_5202)
                                {
                                    float2 _5205 = _5195 * 2.0;
                                    _5150[0] = float2(3.0) - _5205;
                                    _5150[1] = float2(1.0) + _5205;
                                    _5151[0] = ((float2(2.0) - _5195) / _5150[0]) - float2(1.0);
                                    _5151[1] = (_5195 / _5150[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _5232 = _5195 * 3.0;
                                    _5150[0] = float2(4.0) - _5232;
                                    _5150[1] = float2(7.0);
                                    _5150[2] = float2(1.0) + _5232;
                                    _5151[0] = ((float2(3.0) - (_5195 * 2.0)) / _5150[0]) - float2(2.0);
                                    _5151[1] = (float2(3.0) + _5195) / _5150[1];
                                    _5151[2] = (_5195 / _5150[2]) + float2(2.0);
                                }
                                int _6322 = _5202 ? 2 : 3;
                                int _6037;
                                float _6040;
                                _6040 = 0.0;
                                _6037 = 0;
                                float _6046;
                                for (; _6037 < _6322; _6040 = _6046, _6037++)
                                {
                                    _6046 = _6040;
                                    for (int _6043 = 0; _6043 < _6322; )
                                    {
                                        _6046 += ((_5150[_6043].x * _5150[_6037].y) * spvDepthCast(_193).sample_compare(_193Smplr, float3(fast::clamp(_173._m22.xy * (_5198 + float2(_5151[_6043].x, _5151[_6037].y)), _5140.xy, _5140.zw), _4956).xy, _4956));
                                        _6043++;
                                        continue;
                                    }
                                }
                                _6047 = _6040 * (_5202 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _6048 = _6047;
                            break;
                        }
                        uint _4966 = _4761 - _4862;
                        if (_4966 >= uint(_173._m21.w))
                        {
                            _6048 = 1.0;
                            break;
                        }
                        float _4987 = _173._m27[_4966].w * length(in.m_1444 - _173._m27[_4966].xyz);
                        float3 _5005 = ((in.m_1444 + (_1803 * (_4987 * _173._m25.x))) + (_4795 * (_4987 * _173._m25.y))) - _173._m27[_4966].xyz;
                        float3 _5007 = abs(_5005);
                        float _5009 = _5007.x;
                        float _5011 = _5007.y;
                        bool _5012 = _5009 >= _5011;
                        bool _5020;
                        if (_5012)
                        {
                            _5020 = _5009 >= _5007.z;
                        }
                        else
                        {
                            _5020 = _5012;
                        }
                        float _6022;
                        int _6024;
                        if (_5020)
                        {
                            _6024 = (_5005.x > 0.0) ? 0 : 1;
                            _6022 = _5009;
                        }
                        else
                        {
                            float _5032 = _5007.z;
                            bool _5033 = _5011 >= _5032;
                            int _6025;
                            if (_5033)
                            {
                                _6025 = (_5005.y > 0.0) ? 2 : 3;
                            }
                            else
                            {
                                _6025 = (_5005.z > 0.0) ? 4 : 5;
                            }
                            _6024 = _6025;
                            _6022 = _5033 ? _5011 : _5032;
                        }
                        if (_6022 <= 0.0)
                        {
                            _6048 = 1.0;
                            break;
                        }
                        float2 _5070 = float2(dot(_5005, _851[_6024]), dot(_5005, _860[_6024])) / float2(_6022 * _173._m24.z);
                        float _5077 = _173._m28[_4966].z + (_173._m28[_4966].w / _6022);
                        if (_5077 > 1.0)
                        {
                            _6048 = 1.0;
                            break;
                        }
                        float2 _5095 = _173._m28[_4966].xy + (float2(float(spvSMod(_6024, 3)), float(_6024 / 3)) * _173._m24.xy);
                        float2 _5335 = _173._m22.xy * 0.5;
                        float2 _5340 = _5095 + (float2(0.5 + (0.5 * _5070.x), 0.5 - (0.5 * _5070.y)) * _173._m24.xy);
                        float4 _5353 = float4(_5095 + _5335, (_5095 + _173._m24.xy) - _5335);
                        float _6036;
                        do
                        {
                            int _5379 = int(_173._m22.z);
                            if (_5379 <= 0)
                            {
                                _6036 = spvDepthCast(_193).sample_compare(_193Smplr, float3(fast::clamp(_5340, _5353.xy, _5353.zw), _5077).xy, _5077);
                                break;
                            }
                            float2 _5402 = (_5340 / _173._m22.xy) + float2(0.5);
                            float2 _5403 = floor(_5402);
                            float2 _5408 = _5402 - _5403;
                            float2 _5411 = _5403 - float2(0.5);
                            bool _5415 = _5379 == 1;
                            if (_5415)
                            {
                                float2 _5418 = _5408 * 2.0;
                                _5363[0] = float2(3.0) - _5418;
                                _5363[1] = float2(1.0) + _5418;
                                _5364[0] = ((float2(2.0) - _5408) / _5363[0]) - float2(1.0);
                                _5364[1] = (_5408 / _5363[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _5445 = _5408 * 3.0;
                                _5363[0] = float2(4.0) - _5445;
                                _5363[1] = float2(7.0);
                                _5363[2] = float2(1.0) + _5445;
                                _5364[0] = ((float2(3.0) - (_5408 * 2.0)) / _5363[0]) - float2(2.0);
                                _5364[1] = (float2(3.0) + _5408) / _5363[1];
                                _5364[2] = (_5408 / _5363[2]) + float2(2.0);
                            }
                            int _6325 = _5415 ? 2 : 3;
                            int _6026;
                            float _6029;
                            _6029 = 0.0;
                            _6026 = 0;
                            float _6035;
                            for (; _6026 < _6325; _6029 = _6035, _6026++)
                            {
                                _6035 = _6029;
                                for (int _6032 = 0; _6032 < _6325; )
                                {
                                    _6035 += ((_5363[_6032].x * _5363[_6026].y) * spvDepthCast(_193).sample_compare(_193Smplr, float3(fast::clamp(_173._m22.xy * (_5411 + float2(_5364[_6032].x, _5364[_6026].y)), _5353.xy, _5353.zw), _5077).xy, _5077));
                                    _6032++;
                                    continue;
                                }
                            }
                            _6036 = _6029 * (_5415 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _6048 = _6036;
                        break;
                    } while(false);
                    _6090 = _4826 * _6048;
                }
                else
                {
                    _6090 = _4826;
                }
                float3 _2203 = fast::normalize(_4795 + _1792);
                float _2208 = fast::clamp(dot(_5964, _4795), 0.0, 1.0);
                float _2213 = fast::clamp(dot(_5964, _2203), 0.0, 1.0);
                float3 _5550 = _2027 + (_4053 * powr(1.0 - fast::clamp(dot(_1792, _2203), 0.0, 1.0), 5.0));
                float _5564 = ((_2213 * _2213) * _4068) + 1.0;
                _2251 = _6092 + (((((float3(1.0) - _5550) * _2020) + ((_5550 * ((_4063 / ((3.1415927410125732421875 * _5564) * _5564)) * (0.5 / fast::max((_2208 * _4094) + (_2032 * sqrt(((_2208 * _2208) * _4090) + _4063)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875)) * _2208) * _6090);
            }
            _6137 = _6092;
        }
        else
        {
            _6137 = _2151;
        }
        _6134 = _6137;
    }
    out.m_2289 = float4(mix(mix(_6134, _5962, float3(_1620._m1.y)) + (_1620._m5.xyz * _2263.sample(_1210, _1639).xyz), _173._m7.xyz, float3(1.0 - exp((-length(_1791)) * _173._m7.w))), (in.m_1648.w * _1620._m0.w) * _1646.w);
    float2 _6168;
    do
    {
        if (in.m_2305.w <= 0.0)
        {
            _6168 = float2(0.0);
            break;
        }
        _6168 = ((in.m_2305.xy / float2(in.m_2305.w)) - (in.m_2304.xy / float2(in.m_2304.w))) * float2(0.5, -0.5);
        break;
    } while(false);
    out.m_2303 = _6168;
    return out;
}

