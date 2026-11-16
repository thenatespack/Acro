// Generated from mesh_mask.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: c88d723b2701429b
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

struct _178
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
};

struct _1441
{
    float4 _m0[1024];
};

struct _1477
{
    float4 _m0[1024];
};

struct _1485
{
    float4 _m0[1024];
};

struct _1582
{
    uint4 _m0[1024];
};

struct _1604
{
    uint4 _m0[1024];
};

struct _1819
{
    float4 _m0;
    float4 _m1;
    float4 _m2;
    float4 _m3;
    float4 _m4;
    float4 _m5;
    float4 _m6;
};

constant spvUnsafeArray<float3, 4> _554 = spvUnsafeArray<float3, 4>({ float3(1.0, 0.449999988079071044921875, 0.449999988079071044921875), float3(0.449999988079071044921875, 1.0, 0.449999988079071044921875), float3(0.5, 0.60000002384185791015625, 1.0), float3(1.0, 1.0, 0.4000000059604644775390625) });
constant spvUnsafeArray<float3, 6> _858 = spvUnsafeArray<float3, 6>({ float3(0.0, 0.0, 1.0), float3(0.0, 0.0, -1.0), float3(-1.0, 0.0, 0.0), float3(-1.0, 0.0, 0.0), float3(-1.0, 0.0, 0.0), float3(1.0, 0.0, 0.0) });
constant spvUnsafeArray<float3, 6> _867 = spvUnsafeArray<float3, 6>({ float3(0.0, 1.0, 0.0), float3(0.0, 1.0, 0.0), float3(0.0, 0.0, -1.0), float3(0.0, 0.0, 1.0), float3(0.0, 1.0, 0.0), float3(0.0, 1.0, 0.0) });
constant spvUnsafeArray<int4, 6> _1277 = spvUnsafeArray<int4, 6>({ int4(0, 0, 512, 256), int4(0, 256, 256, 128), int4(256, 256, 128, 64), int4(384, 256, 64, 32), int4(448, 256, 32, 16), int4(480, 256, 16, 8) });

struct fragment_main_out
{
    float4 m_2660 [[color(0)]];
    float2 m_2668 [[color(1)]];
};

struct fragment_main_in
{
    float3 m_1451 [[user(locn0)]];
    float3 m_1906 [[user(locn1)]];
    float2 m_1826 [[user(locn2)]];
    float4 m_1849 [[user(locn3)]];
    float4 m_2054 [[user(locn5)]];
    float4 m_2669 [[user(locn6)]];
    float4 m_2670 [[user(locn7)]];
    float4 m_1915 [[user(locn8)]];
};

fragment fragment_main_out fragment_main(fragment_main_in in [[stage_in]], constant _1819& _1821 [[buffer(2)]], constant _1441& _1443 [[buffer(3)]], constant _1477& _1479 [[buffer(4)]], constant _1485& _1487 [[buffer(5)]], constant _1582& _1584 [[buffer(6)]], constant _1604& _1606 [[buffer(7)]], constant _178& _180 [[buffer(15)]], texture2d<float> _200 [[texture(0)]], texture2d<float> _1842 [[texture(1)]], texture2d<float> _2259 [[texture(2)]], texture2d<float> _1944 [[texture(3)]], texture2d<float> _1770 [[texture(4)]], texture2d<float> _2550 [[texture(5)]], texture2d<float> _1215 [[texture(6)]], texture2d<float> _1321 [[texture(7)]], sampler _200Smplr [[sampler(0)]], sampler _1217 [[sampler(1)]], sampler _1323 [[sampler(7)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])
{
    fragment_main_out out = {};
    float2 _1840 = float2(dot(_1821._m2.xy, in.m_1826) + _1821._m2.z, dot(_1821._m3.xy, in.m_1826) + _1821._m3.z);
    float4 _1847 = _1842.sample(_1217, _1840);
    float3 _1858 = (in.m_1849.xyz * _1821._m0.xyz) * _1847.xyz;
    if ((_1821._m0.w * _1847.w) < _1821._m6.x)
    {
        discard_fragment();
    }
    float3 _6513;
    if (_1821._m1.x > 0.5)
    {
        float2 _1892 = floor(in.m_1451.xz * float2(0.5));
        _6513 = _1858 * ((mod(abs(_1892.x + _1892.y), 2.0) < 0.5) ? 1.0 : 0.75);
    }
    else
    {
        _6513 = _1858;
    }
    float3 _1908 = fast::normalize(in.m_1906);
    float3 _6427;
    if (_1821._m6.y > 0.5)
    {
        float3 _1924 = in.m_1915.xyz - (_1908 * dot(_1908, in.m_1915.xyz));
        float3 _6428;
        if (dot(_1924, _1924) > 9.9999999600419720025001879548654e-13)
        {
            float3 _1933 = fast::normalize(_1924);
            float4 _1949 = _1944.sample(_1217, _1840);
            float3 _6421;
            if (_1821._m6.z > 0.5)
            {
                float2 _6420;
                if (_1821._m6.z > 1.5)
                {
                    _6420 = _1949.xw;
                }
                else
                {
                    _6420 = _1949.xy;
                }
                float2 _1971 = (_6420 * 2.0) - float2(1.0);
                _6421 = float3(_1971, sqrt(fast::clamp(1.0 - dot(_1971, _1971), 0.0, 1.0)));
            }
            else
            {
                _6421 = (_1949.xyz * 2.0) - float3(1.0);
            }
            float2 _1993 = _6421.xy * _1821._m4.z;
            _6428 = fast::normalize(((_1933 * _1993.x) + ((cross(_1908, _1933) * ((in.m_1915.w < 0.0) ? (-1.0) : 1.0)) * _1993.y)) + (_1908 * _6421.z));
        }
        else
        {
            _6428 = _1908;
        }
        _6427 = _6428;
    }
    else
    {
        _6427 = _1908;
    }
    bool _2017 = _1821._m5.w > 0.5;
    bool _2025;
    if (_2017)
    {
        _2025 = !gl_FrontFacing;
    }
    else
    {
        _2025 = _2017;
    }
    float3 _6543;
    if (_2025)
    {
        _6543 = -_6427;
    }
    else
    {
        _6543 = _6427;
    }
    float3 _2034 = fast::normalize(_180._m4.xyz);
    float3 _2040 = _180._m6.xyz - in.m_1451;
    float3 _2041 = fast::normalize(_2040);
    float3 _2046 = fast::normalize(_2034 + _2041);
    float3 _2052 = _1908 * (gl_FrontFacing ? 1.0 : (-1.0));
    bool _2057 = in.m_2054.x > 0.5;
    float3 _6539;
    float _6568;
    if ((_180._m5.w > 0.5) && _2057)
    {
        float _6484;
        float3 _6485;
        do
        {
            int _2728 = int(_180._m21.x);
            float _2736 = dot(_180._m20.xyz, in.m_1451) + _180._m20.w;
            int _6429;
            _6429 = 0;
            for (;;)
            {
                bool _2742 = _6429 < (_2728 - 1);
                bool _2750;
                if (_2742)
                {
                    _2750 = _2736 > _180._m16[_6429];
                }
                else
                {
                    _2750 = _2742;
                }
                if (_2750)
                {
                    _6429++;
                    continue;
                }
                else
                {
                    break;
                }
            }
            if (_2736 > _180._m16[_6429])
            {
                _6485 = float3(1.0);
                _6484 = 1.0;
                break;
            }
            float _6442;
            do
            {
                float4 _2852 = _180._m14[_6429] * float4(in.m_1451 + (_2052 * _180._m18[_6429]), 1.0);
                float _2855 = _2852.x;
                bool _2856 = _2855 < 0.0;
                bool _2863;
                if (!_2856)
                {
                    _2863 = _2855 > 1.0;
                }
                else
                {
                    _2863 = _2856;
                }
                bool _2870;
                if (!_2863)
                {
                    _2870 = _2852.y < 0.0;
                }
                else
                {
                    _2870 = _2863;
                }
                bool _2877;
                if (!_2870)
                {
                    _2877 = _2852.y > 1.0;
                }
                else
                {
                    _2877 = _2870;
                }
                if (_2877)
                {
                    _6442 = 1.0;
                    break;
                }
                float2 _2890 = float2(float(_6429 & 1), float(_6429 >> 1)) * _180._m23.xy;
                float _2897 = fast::min(_2852.z, 1.0) - _180._m19[_6429];
                float2 _2916 = _180._m22.xy * 0.5;
                float2 _2921 = _2890 + (_2852.xy * _180._m23.xy);
                float4 _2934 = float4(_2890 + _2916, (_2890 + _180._m23.xy) - _2916);
                float _6441;
                do
                {
                    int _2960 = int(_180._m22.z);
                    if (_2960 <= 0)
                    {
                        _6441 = spvDepthCast(_200).sample_compare(_200Smplr, float3(fast::clamp(_2921, _2934.xy, _2934.zw), _2897).xy, _2897);
                        break;
                    }
                    float2 _2983 = (_2921 / _180._m22.xy) + float2(0.5);
                    float2 _2984 = floor(_2983);
                    float2 _2989 = _2983 - _2984;
                    float2 _2992 = _2984 - float2(0.5);
                    bool _2996 = _2960 == 1;
                    spvUnsafeArray<float2, 3> _2944;
                    spvUnsafeArray<float2, 3> _2945;
                    if (_2996)
                    {
                        float2 _2999 = _2989 * 2.0;
                        _2944[0] = float2(3.0) - _2999;
                        _2944[1] = float2(1.0) + _2999;
                        _2945[0] = ((float2(2.0) - _2989) / _2944[0]) - float2(1.0);
                        _2945[1] = (_2989 / _2944[1]) + float2(1.0);
                    }
                    else
                    {
                        float2 _3026 = _2989 * 3.0;
                        _2944[0] = float2(4.0) - _3026;
                        _2944[1] = float2(7.0);
                        _2944[2] = float2(1.0) + _3026;
                        _2945[0] = ((float2(3.0) - (_2989 * 2.0)) / _2944[0]) - float2(2.0);
                        _2945[1] = (float2(3.0) + _2989) / _2944[1];
                        _2945[2] = (_2989 / _2944[2]) + float2(2.0);
                    }
                    int _7024 = _2996 ? 2 : 3;
                    int _6431;
                    float _6434;
                    _6434 = 0.0;
                    _6431 = 0;
                    float _6440;
                    for (; _6431 < _7024; _6434 = _6440, _6431++)
                    {
                        _6440 = _6434;
                        for (int _6437 = 0; _6437 < _7024; )
                        {
                            _6440 += ((_2944[_6437].x * _2944[_6431].y) * spvDepthCast(_200).sample_compare(_200Smplr, float3(fast::clamp(_180._m22.xy * (_2992 + float2(_2945[_6437].x, _2945[_6431].y)), _2934.xy, _2934.zw), _2897).xy, _2897));
                            _6437++;
                            continue;
                        }
                    }
                    _6441 = _6434 * (_2996 ? 0.0625 : 0.0069444444961845874786376953125);
                    break;
                } while(false);
                _6442 = _6441;
                break;
            } while(false);
            float3 _6479;
            float _6482;
            if (_2736 > _180._m17[_6429])
            {
                float _2790 = (_2736 - _180._m17[_6429]) / (_180._m16[_6429] - _180._m17[_6429]);
                int _2792 = _6429 + 1;
                float3 _6480;
                float _6483;
                if (_2792 < _2728)
                {
                    float _6462;
                    do
                    {
                        float4 _3139 = _180._m14[_2792] * float4(in.m_1451 + (_2052 * _180._m18[_2792]), 1.0);
                        float _3142 = _3139.x;
                        bool _3143 = _3142 < 0.0;
                        bool _3150;
                        if (!_3143)
                        {
                            _3150 = _3142 > 1.0;
                        }
                        else
                        {
                            _3150 = _3143;
                        }
                        bool _3157;
                        if (!_3150)
                        {
                            _3157 = _3139.y < 0.0;
                        }
                        else
                        {
                            _3157 = _3150;
                        }
                        bool _3164;
                        if (!_3157)
                        {
                            _3164 = _3139.y > 1.0;
                        }
                        else
                        {
                            _3164 = _3157;
                        }
                        if (_3164)
                        {
                            _6462 = 1.0;
                            break;
                        }
                        float2 _3177 = float2(float(_2792 & 1), float(_2792 >> 1)) * _180._m23.xy;
                        float _3184 = fast::min(_3139.z, 1.0) - _180._m19[_2792];
                        float2 _3203 = _180._m22.xy * 0.5;
                        float2 _3208 = _3177 + (_3139.xy * _180._m23.xy);
                        float4 _3221 = float4(_3177 + _3203, (_3177 + _180._m23.xy) - _3203);
                        float _6461;
                        do
                        {
                            int _3247 = int(_180._m22.z);
                            if (_3247 <= 0)
                            {
                                _6461 = spvDepthCast(_200).sample_compare(_200Smplr, float3(fast::clamp(_3208, _3221.xy, _3221.zw), _3184).xy, _3184);
                                break;
                            }
                            float2 _3270 = (_3208 / _180._m22.xy) + float2(0.5);
                            float2 _3271 = floor(_3270);
                            float2 _3276 = _3270 - _3271;
                            float2 _3279 = _3271 - float2(0.5);
                            bool _3283 = _3247 == 1;
                            spvUnsafeArray<float2, 3> _3231;
                            spvUnsafeArray<float2, 3> _3232;
                            if (_3283)
                            {
                                float2 _3286 = _3276 * 2.0;
                                _3231[0] = float2(3.0) - _3286;
                                _3231[1] = float2(1.0) + _3286;
                                _3232[0] = ((float2(2.0) - _3276) / _3231[0]) - float2(1.0);
                                _3232[1] = (_3276 / _3231[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _3313 = _3276 * 3.0;
                                _3231[0] = float2(4.0) - _3313;
                                _3231[1] = float2(7.0);
                                _3231[2] = float2(1.0) + _3313;
                                _3232[0] = ((float2(3.0) - (_3276 * 2.0)) / _3231[0]) - float2(2.0);
                                _3232[1] = (float2(3.0) + _3276) / _3231[1];
                                _3232[2] = (_3276 / _3231[2]) + float2(2.0);
                            }
                            int _7026 = _3283 ? 2 : 3;
                            int _6451;
                            float _6454;
                            _6454 = 0.0;
                            _6451 = 0;
                            float _6460;
                            for (; _6451 < _7026; _6454 = _6460, _6451++)
                            {
                                _6460 = _6454;
                                for (int _6457 = 0; _6457 < _7026; )
                                {
                                    _6460 += ((_3231[_6457].x * _3231[_6451].y) * spvDepthCast(_200).sample_compare(_200Smplr, float3(fast::clamp(_180._m22.xy * (_3279 + float2(_3232[_6457].x, _3232[_6451].y)), _3221.xy, _3221.zw), _3184).xy, _3184));
                                    _6457++;
                                    continue;
                                }
                            }
                            _6461 = _6454 * (_3283 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _6462 = _6461;
                        break;
                    } while(false);
                    _6483 = mix(_6442, _6462, _2790);
                    _6480 = mix(_554[_6429], _554[_2792], float3(_2790));
                }
                else
                {
                    _6483 = mix(_6442, 1.0, _2790);
                    _6480 = _554[_6429];
                }
                _6482 = _6483;
                _6479 = _6480;
            }
            else
            {
                _6482 = _6442;
                _6479 = _554[_6429];
            }
            _6485 = select(float3(1.0), _6479, bool3(_180._m22.w > 0.5));
            _6484 = _6482;
            break;
        } while(false);
        _6568 = _6484;
        _6539 = _6513 * _6485;
    }
    else
    {
        _6568 = 1.0;
        _6539 = _6513;
    }
    float3 _2083 = _180._m5.xyz * _180._m4.w;
    bool _2087 = _1821._m6.w > 0.5;
    float _6536;
    if (_2087)
    {
        _6536 = 1.0;
    }
    else
    {
        _6536 = 1.0 + (_1821._m4.w * (_1770.sample(_1217, _1840).x - 1.0));
    }
    float _2107 = abs(in.m_1915.w);
    float _6634;
    if (_2107 > 0.0)
    {
        _6634 = _6536 * fast::min(_2107, 1.0);
    }
    else
    {
        _6634 = _6536;
    }
    float3 _6748;
    if (!_2017)
    {
        float _2123 = dot(_6543, _2034);
        float3 _6740;
        if (_180._m29.x > 0.5)
        {
            float _3464 = (_180._m29.z * _6543.x) - (_180._m29.w * _6543.z);
            float _3477 = (_180._m29.w * _6543.x) + (_180._m29.z * _6543.z);
            float _3495 = 1.09254801273345947265625 * _3464;
            spvUnsafeArray<float, 9> _6227 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _6543.y, 0.48860299587249755859375 * _3477, 0.48860299587249755859375 * _3464, _3495 * _6543.y, (1.09254801273345947265625 * _6543.y) * _3477, 0.3153919875621795654296875 * (((3.0 * _3477) * _3477) - 1.0), _3495 * _3477, 0.546274006366729736328125 * ((_3464 * _3464) - (_6543.y * _6543.y)) });
            spvUnsafeArray<float, 9> _3409 = _6227;
            float3 _6739;
            _6739 = float3(0.0);
            for (int _6738 = 0; _6738 < 9; )
            {
                _6739 += (_1215.read(uint2((int2(496, 256) + int2(_6738, 0))), 0).xyz * _3409[_6738]);
                _6738++;
                continue;
            }
            _6740 = fast::max(_6739, float3(0.0)) * _180._m29.y;
        }
        else
        {
            _6740 = mix(_180._m9.xyz, _180._m8.xyz, float3((_6543.y * 0.5) + 0.5)) * _180._m8.w;
        }
        float3 _2173 = (_6539 * ((_6740 * _6634) + ((_2083 * fast::max(_2123, 0.0)) * _6568))) + ((_2083 * ((powr(fast::max(dot(_6543, _2046), 0.0), _1821._m1.w) * _1821._m1.z) * step(0.0, _2123))) * _6568);
        float3 _6749;
        if (_180._m13.w > 0.5)
        {
            float2 _3580 = fast::clamp(floor(gl_FragCoord.xy * _180._m12.xy), float2(0.0), _180._m13.xy - float2(1.0));
            uint _3608 = uint((((fast::clamp(floor((log2(fast::max(dot(_180._m11.xyz, in.m_1451) + _180._m11.w, 9.9999999747524270787835121154785e-07)) * _180._m12.z) + _180._m12.w), 0.0, _180._m13.z - 1.0) * _180._m13.y) + _3580.y) * _180._m13.x) + _3580.x);
            uint _3610 = _3608 >> uint(2);
            uint _3612 = _3608 & 3u;
            uint _3616 = _1584._m0[_3610][_3612] & 65535u;
            uint _3618 = _1584._m0[_3610][_3612] >> uint(16);
            float3 _6750;
            _6750 = _2173;
            float3 _2254;
            spvUnsafeArray<float2, 3> _4026;
            spvUnsafeArray<float2, 3> _4027;
            spvUnsafeArray<float2, 3> _4239;
            spvUnsafeArray<float2, 3> _4240;
            for (uint _6747 = _3616; _6747 < (_3616 + _3618); _6750 = _2254, _6747++)
            {
                uint _3624 = _6747 / 3u;
                uint _3637 = (_1606._m0[_3624 >> uint(2)][_3624 & 3u] >> ((_6747 - (_3624 * 3u)) * 10u)) & 1023u;
                float3 _3654 = _1443._m0[_3637].xyz - in.m_1451;
                float _3657 = dot(_3654, _3654);
                float _3661 = _3657 * _1443._m0[_3637].w;
                float _3666 = fast::clamp(1.0 - (_3661 * _3661), 0.0, 1.0);
                float3 _3671 = _3654 * rsqrt(fast::max(_3657, 9.9999999392252902907785028219223e-09));
                float _3689 = fast::clamp((dot(-_3671, _1487._m0[_3637].xyz) * _1479._m0[_3637].w) + _1487._m0[_3637].w, 0.0, 1.0);
                float3 _3702 = _1479._m0[_3637].xyz * ((((_3666 * _3666) * _3689) * _3689) / fast::max(_3657, 9.9999997473787516355514526367188e-05));
                float3 _6943;
                if (_2057)
                {
                    float _6889;
                    do
                    {
                        uint _3738 = uint(_180._m21.z);
                        if (_3637 < _3738)
                        {
                            float _3760 = _180._m26[_3637].z * fast::max((_180._m15[_3637] * float4(in.m_1451, 1.0)).w, 0.0);
                            float4 _3784 = _180._m15[_3637] * float4((in.m_1451 + (_2052 * (_3760 * _180._m25.x))) + (_3671 * (_3760 * _180._m25.y)), 1.0);
                            float _3786 = _3784.w;
                            if (_3786 <= 0.0)
                            {
                                _6889 = 1.0;
                                break;
                            }
                            float3 _3795 = _3784.xyz / float3(_3786);
                            float _3797 = _3795.x;
                            bool _3798 = _3797 < 0.0;
                            bool _3805;
                            if (!_3798)
                            {
                                _3805 = _3797 > 1.0;
                            }
                            else
                            {
                                _3805 = _3798;
                            }
                            bool _3812;
                            if (!_3805)
                            {
                                _3812 = _3795.y < 0.0;
                            }
                            else
                            {
                                _3812 = _3805;
                            }
                            bool _3819;
                            if (!_3812)
                            {
                                _3819 = _3795.y > 1.0;
                            }
                            else
                            {
                                _3819 = _3812;
                            }
                            bool _3826;
                            if (!_3819)
                            {
                                _3826 = _3795.z > 1.0;
                            }
                            else
                            {
                                _3826 = _3819;
                            }
                            if (_3826)
                            {
                                _6889 = 1.0;
                                break;
                            }
                            float _3832 = _3795.z;
                            float2 _3998 = _180._m22.xy * 0.5;
                            float2 _4003 = _180._m26[_3637].xy + (_3795.xy * _180._m23.zw);
                            float4 _4016 = float4(_180._m26[_3637].xy + _3998, (_180._m26[_3637].xy + _180._m23.zw) - _3998);
                            float _6888;
                            do
                            {
                                int _4042 = int(_180._m22.z);
                                if (_4042 <= 0)
                                {
                                    float2 _4052 = fast::clamp(_4003, _4016.xy, _4016.zw);
                                    _6888 = spvDepthCast(_200).sample_compare(_200Smplr, float3(_4052, _3832).xy, _3832);
                                    break;
                                }
                                float2 _4065 = (_4003 / _180._m22.xy) + float2(0.5);
                                float2 _4066 = floor(_4065);
                                float2 _4071 = _4065 - _4066;
                                float2 _4074 = _4066 - float2(0.5);
                                bool _4078 = _4042 == 1;
                                if (_4078)
                                {
                                    float2 _4081 = _4071 * 2.0;
                                    _4026[0] = float2(3.0) - _4081;
                                    _4026[1] = float2(1.0) + _4081;
                                    _4027[0] = ((float2(2.0) - _4071) / _4026[0]) - float2(1.0);
                                    _4027[1] = (_4071 / _4026[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _4108 = _4071 * 3.0;
                                    _4026[0] = float2(4.0) - _4108;
                                    _4026[1] = float2(7.0);
                                    _4026[2] = float2(1.0) + _4108;
                                    _4027[0] = ((float2(3.0) - (_4071 * 2.0)) / _4026[0]) - float2(2.0);
                                    _4027[1] = (float2(3.0) + _4071) / _4026[1];
                                    _4027[2] = (_4071 / _4026[2]) + float2(2.0);
                                }
                                int _7031 = _4078 ? 2 : 3;
                                int _6878;
                                float _6881;
                                _6881 = 0.0;
                                _6878 = 0;
                                float _6887;
                                for (; _6878 < _7031; _6881 = _6887, _6878++)
                                {
                                    _6887 = _6881;
                                    for (int _6884 = 0; _6884 < _7031; )
                                    {
                                        _6887 += ((_4026[_6884].x * _4026[_6878].y) * spvDepthCast(_200).sample_compare(_200Smplr, float3(fast::clamp(_180._m22.xy * (_4074 + float2(_4027[_6884].x, _4027[_6878].y)), _4016.xy, _4016.zw), _3832).xy, _3832));
                                        _6884++;
                                        continue;
                                    }
                                }
                                _6888 = _6881 * (_4078 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _6889 = _6888;
                            break;
                        }
                        uint _3842 = _3637 - _3738;
                        if (_3842 >= uint(_180._m21.w))
                        {
                            _6889 = 1.0;
                            break;
                        }
                        float _3863 = _180._m27[_3842].w * length(in.m_1451 - _180._m27[_3842].xyz);
                        float3 _3881 = ((in.m_1451 + (_2052 * (_3863 * _180._m25.x))) + (_3671 * (_3863 * _180._m25.y))) - _180._m27[_3842].xyz;
                        float3 _3883 = abs(_3881);
                        float _3885 = _3883.x;
                        float _3887 = _3883.y;
                        bool _3888 = _3885 >= _3887;
                        bool _3896;
                        if (_3888)
                        {
                            _3896 = _3885 >= _3883.z;
                        }
                        else
                        {
                            _3896 = _3888;
                        }
                        float _6863;
                        int _6865;
                        if (_3896)
                        {
                            _6865 = (_3881.x > 0.0) ? 0 : 1;
                            _6863 = _3885;
                        }
                        else
                        {
                            float _3908 = _3883.z;
                            bool _3909 = _3887 >= _3908;
                            int _6866;
                            if (_3909)
                            {
                                _6866 = (_3881.y > 0.0) ? 2 : 3;
                            }
                            else
                            {
                                _6866 = (_3881.z > 0.0) ? 4 : 5;
                            }
                            _6865 = _6866;
                            _6863 = _3909 ? _3887 : _3908;
                        }
                        if (_6863 <= 0.0)
                        {
                            _6889 = 1.0;
                            break;
                        }
                        float2 _3946 = float2(dot(_3881, _858[_6865]), dot(_3881, _867[_6865])) / float2(_6863 * _180._m24.z);
                        float _3953 = _180._m28[_3842].z + (_180._m28[_3842].w / _6863);
                        if (_3953 > 1.0)
                        {
                            _6889 = 1.0;
                            break;
                        }
                        float2 _3971 = _180._m28[_3842].xy + (float2(float(spvSMod(_6865, 3)), float(_6865 / 3)) * _180._m24.xy);
                        float2 _4211 = _180._m22.xy * 0.5;
                        float2 _4216 = _3971 + (float2(0.5 + (0.5 * _3946.x), 0.5 - (0.5 * _3946.y)) * _180._m24.xy);
                        float4 _4229 = float4(_3971 + _4211, (_3971 + _180._m24.xy) - _4211);
                        float _6877;
                        do
                        {
                            int _4255 = int(_180._m22.z);
                            if (_4255 <= 0)
                            {
                                _6877 = spvDepthCast(_200).sample_compare(_200Smplr, float3(fast::clamp(_4216, _4229.xy, _4229.zw), _3953).xy, _3953);
                                break;
                            }
                            float2 _4278 = (_4216 / _180._m22.xy) + float2(0.5);
                            float2 _4279 = floor(_4278);
                            float2 _4284 = _4278 - _4279;
                            float2 _4287 = _4279 - float2(0.5);
                            bool _4291 = _4255 == 1;
                            if (_4291)
                            {
                                float2 _4294 = _4284 * 2.0;
                                _4239[0] = float2(3.0) - _4294;
                                _4239[1] = float2(1.0) + _4294;
                                _4240[0] = ((float2(2.0) - _4284) / _4239[0]) - float2(1.0);
                                _4240[1] = (_4284 / _4239[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _4321 = _4284 * 3.0;
                                _4239[0] = float2(4.0) - _4321;
                                _4239[1] = float2(7.0);
                                _4239[2] = float2(1.0) + _4321;
                                _4240[0] = ((float2(3.0) - (_4284 * 2.0)) / _4239[0]) - float2(2.0);
                                _4240[1] = (float2(3.0) + _4284) / _4239[1];
                                _4240[2] = (_4284 / _4239[2]) + float2(2.0);
                            }
                            int _7034 = _4291 ? 2 : 3;
                            int _6867;
                            float _6870;
                            _6870 = 0.0;
                            _6867 = 0;
                            float _6876;
                            for (; _6867 < _7034; _6870 = _6876, _6867++)
                            {
                                _6876 = _6870;
                                for (int _6873 = 0; _6873 < _7034; )
                                {
                                    _6876 += ((_4239[_6873].x * _4239[_6867].y) * spvDepthCast(_200).sample_compare(_200Smplr, float3(fast::clamp(_180._m22.xy * (_4287 + float2(_4240[_6873].x, _4240[_6867].y)), _4229.xy, _4229.zw), _3953).xy, _3953));
                                    _6873++;
                                    continue;
                                }
                            }
                            _6877 = _6870 * (_4291 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _6889 = _6877;
                        break;
                    } while(false);
                    _6943 = _3702 * _6889;
                }
                else
                {
                    _6943 = _3702;
                }
                float _2225 = dot(_6543, _3671);
                _2254 = _6750 + (((_6539 * fast::max(_2225, 0.0)) * _6943) + (_6943 * ((powr(fast::max(dot(_6543, fast::normalize(_3671 + _2041)), 0.0), _1821._m1.w) * _1821._m1.z) * step(0.0, _2225))));
            }
            _6749 = _6750;
        }
        else
        {
            _6749 = _2173;
        }
        _6748 = _6749;
    }
    else
    {
        float4 _2264 = _2259.sample(_1217, _1840);
        float _2271 = fast::clamp(_1821._m4.x * _2264.z, 0.0, 1.0);
        float _2279 = fast::clamp(_1821._m4.y * _2264.y, 0.04500000178813934326171875, 1.0);
        float _2283 = _2279 * _2279;
        float3 _2288 = _6539 * (1.0 - _2271);
        float3 _2294 = mix(float3(0.039999999105930328369140625), _6539, float3(_2271));
        float _2299 = fast::max(dot(_6543, _2041), 9.9999997473787516355514526367188e-05);
        float _2304 = fast::clamp(dot(_6543, _2034), 0.0, 1.0);
        float _2309 = fast::clamp(dot(_6543, _2046), 0.0, 1.0);
        float3 _4423 = float3(1.0) - _2294;
        float3 _4426 = _2294 + (_4423 * powr(1.0 - fast::clamp(dot(_2041, _2046), 0.0, 1.0), 5.0));
        float _4433 = _2283 * _2283;
        float _4438 = _4433 - 1.0;
        float _4440 = ((_2309 * _2309) * _4438) + 1.0;
        float _4460 = 1.0 - _4433;
        float _4464 = sqrt(((_2299 * _2299) * _4460) + _4433);
        float3 _6587;
        float2 _6602;
        float3 _6614;
        if (_180._m29.x > 0.5)
        {
            float4 _4497 = _1321.sample(_1323, (((float2(_2299, _2279) * 31.0) + float2(0.5)) * float2(0.03125)));
            float _4556 = (_180._m29.z * _6543.x) - (_180._m29.w * _6543.z);
            float _4569 = (_180._m29.w * _6543.x) + (_180._m29.z * _6543.z);
            float _4587 = 1.09254801273345947265625 * _4556;
            spvUnsafeArray<float, 9> _6208 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _6543.y, 0.48860299587249755859375 * _4569, 0.48860299587249755859375 * _4556, _4587 * _6543.y, (1.09254801273345947265625 * _6543.y) * _4569, 0.3153919875621795654296875 * (((3.0 * _4569) * _4569) - 1.0), _4587 * _4569, 0.546274006366729736328125 * ((_4556 * _4556) - (_6543.y * _6543.y)) });
            spvUnsafeArray<float, 9> _4501 = _6208;
            float3 _6570;
            _6570 = float3(0.0);
            for (int _6569 = 0; _6569 < 9; )
            {
                _6570 += (_1215.read(uint2((int2(496, 256) + int2(_6569, 0))), 0).xyz * _4501[_6569]);
                _6569++;
                continue;
            }
            float3 _2370 = reflect(-_2041, _6543);
            float _4682 = _2370.x;
            float _4687 = _2370.z;
            float2 _4719 = float2((precise::atan2((_180._m29.z * _4682) - (_180._m29.w * _4687), -((_180._m29.w * _4682) + (_180._m29.z * _4687))) * 0.15915493667125701904296875) + 0.5, acos(fast::clamp(_2370.y, -1.0, 1.0)) * 0.3183098733425140380859375);
            float _4651 = _2279 * 5.0;
            int _4654 = min(int(_4651), 4);
            float2 _4740 = (_4719 * float2(_1277[_4654].zw)) - float2(0.5);
            float2 _4742 = floor(_4740);
            float2 _4745 = _4740 - _4742;
            int _4748 = int(_4742.x);
            int _4751 = int(_4742.y);
            int _6572;
            if (_4748 < 0)
            {
                _6572 = _4748 + _1277[_4654].z;
            }
            else
            {
                _6572 = _4748;
            }
            int _6573;
            if (_6572 >= _1277[_4654].z)
            {
                _6573 = _6572 - _1277[_4654].z;
            }
            else
            {
                _6573 = _6572;
            }
            int _4771 = _6573 + 1;
            int _7035 = (_4771 == _1277[_4654].z) ? 0 : _4771;
            int _4786 = min((_4751 + 1), (_1277[_4654].w - 1));
            int _4788 = max(_4751, 0);
            float3 _4841 = float3(_4745.x);
            int _4661 = _4654 + 1;
            float2 _4873 = (_4719 * float2(_1277[_4661].zw)) - float2(0.5);
            float2 _4875 = floor(_4873);
            float2 _4878 = _4873 - _4875;
            int _4881 = int(_4875.x);
            int _4884 = int(_4875.y);
            int _6579;
            if (_4881 < 0)
            {
                _6579 = _4881 + _1277[_4661].z;
            }
            else
            {
                _6579 = _4881;
            }
            int _6580;
            if (_6579 >= _1277[_4661].z)
            {
                _6580 = _6579 - _1277[_4661].z;
            }
            else
            {
                _6580 = _6579;
            }
            int _4904 = _6580 + 1;
            int _7036 = (_4904 == _1277[_4661].z) ? 0 : _4904;
            int _4919 = min((_4884 + 1), (_1277[_4661].w - 1));
            int _4921 = max(_4884, 0);
            float3 _4974 = float3(_4878.x);
            float3 _4676 = mix(mix(mix(_1215.read(uint2((_1277[_4654].xy + int2(_6573, _4788))), 0).xyz, _1215.read(uint2((_1277[_4654].xy + int2(_7035, _4788))), 0).xyz, _4841), mix(_1215.read(uint2((_1277[_4654].xy + int2(_6573, _4786))), 0).xyz, _1215.read(uint2((_1277[_4654].xy + int2(_7035, _4786))), 0).xyz, _4841), float3(_4745.y)), mix(mix(_1215.read(uint2((_1277[_4661].xy + int2(_6580, _4921))), 0).xyz, _1215.read(uint2((_1277[_4661].xy + int2(_7036, _4921))), 0).xyz, _4974), mix(_1215.read(uint2((_1277[_4661].xy + int2(_6580, _4919))), 0).xyz, _1215.read(uint2((_1277[_4661].xy + int2(_7036, _4919))), 0).xyz, _4974), float3(_4878.y)), float3(_4651 - float(_4654))) * _180._m29.y;
            _6614 = fast::max(_6570, float3(0.0)) * _180._m29.y;
            _6602 = _4497.xy;
            _6587 = _4676;
        }
        else
        {
            float4 _4992 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * _2279) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);
            float _4994 = _4992.x;
            float3 _5029 = mix(_180._m9.xyz, _180._m8.xyz, float3((_6543.y * 0.5) + 0.5)) * _180._m8.w;
            _6614 = _5029;
            _6602 = (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_4994 * _4994, exp2((-9.27999973297119140625) * _2299)) * _4994) + _4992.y)) + _4992.zw;
            _6587 = mix(mix(_180._m9.xyz, _180._m8.xyz, float3((reflect(-_2041, _6543).y * 0.5) + 0.5)) * _180._m8.w, _5029, float3(_2279));
        }
        bool _2402;
        if (_2087)
        {
            _2402 = _180._m33.z > 0.5;
        }
        else
        {
            _2402 = _2087;
        }
        float3 _6623;
        if (_2402)
        {
            float3 _6599;
            do
            {
                float _5108 = ((_180._m32.x * (1.0 - smoothstep(_180._m33.x * 0.5, _180._m33.x, abs(dot(_180._m31.xyz, in.m_1451) - _180._m31.w)))) * smoothstep(0.5, 0.89999997615814208984375, dot(_2052, _180._m31.xyz))) * (1.0 - smoothstep(_180._m32.y * 0.5, _180._m32.y, _2279));
                if (_5108 <= 0.0)
                {
                    _6599 = _6587;
                    break;
                }
                float4 _5133 = _180._m30 * float4(in.m_1451 + ((_6543 - (_180._m31.xyz * dot(_6543, _180._m31.xyz))) * _180._m32.w), 1.0);
                float2 _5146 = ((float2(_5133.x, -_5133.y) / float2(_5133.w)) * 0.5) + float2(0.5);
                float _5150 = _180._m32.z * _2279;
                float3 _6597;
                float _6598;
                _6598 = 0.0;
                _6597 = float3(0.0);
                for (int _6596 = 0; _6596 < 12; )
                {
                    float _5157 = float(_6596);
                    float _5165 = _5157 * 2.3999631404876708984375;
                    float2 _5177 = _5146 + (float2(cos(_5165) * _180._m33.y, sin(_5165)) * (sqrt((_5157 + 0.5) * 0.083333335816860198974609375) * _5150));
                    float2 _5182 = fast::min(_5177, float2(1.0) - _5177);
                    float _5188 = smoothstep(0.0, 0.039999999105930328369140625, fast::min(_5182.x, _5182.y));
                    float4 _5196 = _1770.sample(_1217, fast::clamp(_5177, float2(0.0), float2(1.0)), level(0.0));
                    float3 _5198 = _5196.xyz;
                    _6598 += (_5196.w * _5188);
                    _6597 += ((_5198 / (float3(1.0) - fast::min(_5198, float3(0.99500000476837158203125)))) * _5188);
                    _6596++;
                    continue;
                }
                _6599 = mix(_6587, (_6597 * float3(0.083333335816860198974609375)) + (_6587 * (1.0 - (_6598 * 0.083333335816860198974609375))), float3(_5108));
                break;
            } while(false);
            _6623 = _6599;
        }
        else
        {
            _6623 = _6587;
        }
        float3 _2422 = (_2294 * _6602.x) + float3(_6602.y);
        float3 _2438 = ((((((float3(1.0) - _4426) * _2288) + ((_4426 * ((_4433 / ((3.1415927410125732421875 * _4440) * _4440)) * (0.5 / fast::max((_2304 * _4464) + (_2299 * sqrt(((_2304 * _2304) * _4460) + _4433)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875)) * _2304) * _2083) * _6568) + (((((float3(1.0) - _2422) * _2288) * _6614) + (_2422 * _6623)) * _6634);
        float3 _6751;
        if (_180._m13.w > 0.5)
        {
            float2 _5262 = fast::clamp(floor(gl_FragCoord.xy * _180._m12.xy), float2(0.0), _180._m13.xy - float2(1.0));
            uint _5290 = uint((((fast::clamp(floor((log2(fast::max(dot(_180._m11.xyz, in.m_1451) + _180._m11.w, 9.9999999747524270787835121154785e-07)) * _180._m12.z) + _180._m12.w), 0.0, _180._m13.z - 1.0) * _180._m13.y) + _5262.y) * _180._m13.x) + _5262.x);
            uint _5292 = _5290 >> uint(2);
            uint _5294 = _5290 & 3u;
            uint _5298 = _1584._m0[_5292][_5294] & 65535u;
            uint _5300 = _1584._m0[_5292][_5294] >> uint(16);
            float3 _6704;
            _6704 = _2438;
            float3 _2538;
            spvUnsafeArray<float2, 3> _5708;
            spvUnsafeArray<float2, 3> _5709;
            spvUnsafeArray<float2, 3> _5921;
            spvUnsafeArray<float2, 3> _5922;
            for (uint _6637 = _5298; _6637 < (_5298 + _5300); _6704 = _2538, _6637++)
            {
                uint _5306 = _6637 / 3u;
                uint _5319 = (_1606._m0[_5306 >> uint(2)][_5306 & 3u] >> ((_6637 - (_5306 * 3u)) * 10u)) & 1023u;
                float3 _5336 = _1443._m0[_5319].xyz - in.m_1451;
                float _5339 = dot(_5336, _5336);
                float _5343 = _5339 * _1443._m0[_5319].w;
                float _5348 = fast::clamp(1.0 - (_5343 * _5343), 0.0, 1.0);
                float3 _5353 = _5336 * rsqrt(fast::max(_5339, 9.9999999392252902907785028219223e-09));
                float _5371 = fast::clamp((dot(-_5353, _1487._m0[_5319].xyz) * _1479._m0[_5319].w) + _1487._m0[_5319].w, 0.0, 1.0);
                float3 _5384 = _1479._m0[_5319].xyz * ((((_5348 * _5348) * _5371) * _5371) / fast::max(_5339, 9.9999997473787516355514526367188e-05));
                float3 _6702;
                if (_2057)
                {
                    float _6664;
                    do
                    {
                        uint _5420 = uint(_180._m21.z);
                        if (_5319 < _5420)
                        {
                            float _5442 = _180._m26[_5319].z * fast::max((_180._m15[_5319] * float4(in.m_1451, 1.0)).w, 0.0);
                            float4 _5466 = _180._m15[_5319] * float4((in.m_1451 + (_2052 * (_5442 * _180._m25.x))) + (_5353 * (_5442 * _180._m25.y)), 1.0);
                            float _5468 = _5466.w;
                            if (_5468 <= 0.0)
                            {
                                _6664 = 1.0;
                                break;
                            }
                            float3 _5477 = _5466.xyz / float3(_5468);
                            float _5479 = _5477.x;
                            bool _5480 = _5479 < 0.0;
                            bool _5487;
                            if (!_5480)
                            {
                                _5487 = _5479 > 1.0;
                            }
                            else
                            {
                                _5487 = _5480;
                            }
                            bool _5494;
                            if (!_5487)
                            {
                                _5494 = _5477.y < 0.0;
                            }
                            else
                            {
                                _5494 = _5487;
                            }
                            bool _5501;
                            if (!_5494)
                            {
                                _5501 = _5477.y > 1.0;
                            }
                            else
                            {
                                _5501 = _5494;
                            }
                            bool _5508;
                            if (!_5501)
                            {
                                _5508 = _5477.z > 1.0;
                            }
                            else
                            {
                                _5508 = _5501;
                            }
                            if (_5508)
                            {
                                _6664 = 1.0;
                                break;
                            }
                            float _5514 = _5477.z;
                            float2 _5680 = _180._m22.xy * 0.5;
                            float2 _5685 = _180._m26[_5319].xy + (_5477.xy * _180._m23.zw);
                            float4 _5698 = float4(_180._m26[_5319].xy + _5680, (_180._m26[_5319].xy + _180._m23.zw) - _5680);
                            float _6663;
                            do
                            {
                                int _5724 = int(_180._m22.z);
                                if (_5724 <= 0)
                                {
                                    float2 _5734 = fast::clamp(_5685, _5698.xy, _5698.zw);
                                    _6663 = spvDepthCast(_200).sample_compare(_200Smplr, float3(_5734, _5514).xy, _5514);
                                    break;
                                }
                                float2 _5747 = (_5685 / _180._m22.xy) + float2(0.5);
                                float2 _5748 = floor(_5747);
                                float2 _5753 = _5747 - _5748;
                                float2 _5756 = _5748 - float2(0.5);
                                bool _5760 = _5724 == 1;
                                if (_5760)
                                {
                                    float2 _5763 = _5753 * 2.0;
                                    _5708[0] = float2(3.0) - _5763;
                                    _5708[1] = float2(1.0) + _5763;
                                    _5709[0] = ((float2(2.0) - _5753) / _5708[0]) - float2(1.0);
                                    _5709[1] = (_5753 / _5708[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _5790 = _5753 * 3.0;
                                    _5708[0] = float2(4.0) - _5790;
                                    _5708[1] = float2(7.0);
                                    _5708[2] = float2(1.0) + _5790;
                                    _5709[0] = ((float2(3.0) - (_5753 * 2.0)) / _5708[0]) - float2(2.0);
                                    _5709[1] = (float2(3.0) + _5753) / _5708[1];
                                    _5709[2] = (_5753 / _5708[2]) + float2(2.0);
                                }
                                int _7038 = _5760 ? 2 : 3;
                                int _6653;
                                float _6656;
                                _6656 = 0.0;
                                _6653 = 0;
                                float _6662;
                                for (; _6653 < _7038; _6656 = _6662, _6653++)
                                {
                                    _6662 = _6656;
                                    for (int _6659 = 0; _6659 < _7038; )
                                    {
                                        _6662 += ((_5708[_6659].x * _5708[_6653].y) * spvDepthCast(_200).sample_compare(_200Smplr, float3(fast::clamp(_180._m22.xy * (_5756 + float2(_5709[_6659].x, _5709[_6653].y)), _5698.xy, _5698.zw), _5514).xy, _5514));
                                        _6659++;
                                        continue;
                                    }
                                }
                                _6663 = _6656 * (_5760 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _6664 = _6663;
                            break;
                        }
                        uint _5524 = _5319 - _5420;
                        if (_5524 >= uint(_180._m21.w))
                        {
                            _6664 = 1.0;
                            break;
                        }
                        float _5545 = _180._m27[_5524].w * length(in.m_1451 - _180._m27[_5524].xyz);
                        float3 _5563 = ((in.m_1451 + (_2052 * (_5545 * _180._m25.x))) + (_5353 * (_5545 * _180._m25.y))) - _180._m27[_5524].xyz;
                        float3 _5565 = abs(_5563);
                        float _5567 = _5565.x;
                        float _5569 = _5565.y;
                        bool _5570 = _5567 >= _5569;
                        bool _5578;
                        if (_5570)
                        {
                            _5578 = _5567 >= _5565.z;
                        }
                        else
                        {
                            _5578 = _5570;
                        }
                        float _6638;
                        int _6640;
                        if (_5578)
                        {
                            _6640 = (_5563.x > 0.0) ? 0 : 1;
                            _6638 = _5567;
                        }
                        else
                        {
                            float _5590 = _5565.z;
                            bool _5591 = _5569 >= _5590;
                            int _6641;
                            if (_5591)
                            {
                                _6641 = (_5563.y > 0.0) ? 2 : 3;
                            }
                            else
                            {
                                _6641 = (_5563.z > 0.0) ? 4 : 5;
                            }
                            _6640 = _6641;
                            _6638 = _5591 ? _5569 : _5590;
                        }
                        if (_6638 <= 0.0)
                        {
                            _6664 = 1.0;
                            break;
                        }
                        float2 _5628 = float2(dot(_5563, _858[_6640]), dot(_5563, _867[_6640])) / float2(_6638 * _180._m24.z);
                        float _5635 = _180._m28[_5524].z + (_180._m28[_5524].w / _6638);
                        if (_5635 > 1.0)
                        {
                            _6664 = 1.0;
                            break;
                        }
                        float2 _5653 = _180._m28[_5524].xy + (float2(float(spvSMod(_6640, 3)), float(_6640 / 3)) * _180._m24.xy);
                        float2 _5893 = _180._m22.xy * 0.5;
                        float2 _5898 = _5653 + (float2(0.5 + (0.5 * _5628.x), 0.5 - (0.5 * _5628.y)) * _180._m24.xy);
                        float4 _5911 = float4(_5653 + _5893, (_5653 + _180._m24.xy) - _5893);
                        float _6652;
                        do
                        {
                            int _5937 = int(_180._m22.z);
                            if (_5937 <= 0)
                            {
                                _6652 = spvDepthCast(_200).sample_compare(_200Smplr, float3(fast::clamp(_5898, _5911.xy, _5911.zw), _5635).xy, _5635);
                                break;
                            }
                            float2 _5960 = (_5898 / _180._m22.xy) + float2(0.5);
                            float2 _5961 = floor(_5960);
                            float2 _5966 = _5960 - _5961;
                            float2 _5969 = _5961 - float2(0.5);
                            bool _5973 = _5937 == 1;
                            if (_5973)
                            {
                                float2 _5976 = _5966 * 2.0;
                                _5921[0] = float2(3.0) - _5976;
                                _5921[1] = float2(1.0) + _5976;
                                _5922[0] = ((float2(2.0) - _5966) / _5921[0]) - float2(1.0);
                                _5922[1] = (_5966 / _5921[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _6003 = _5966 * 3.0;
                                _5921[0] = float2(4.0) - _6003;
                                _5921[1] = float2(7.0);
                                _5921[2] = float2(1.0) + _6003;
                                _5922[0] = ((float2(3.0) - (_5966 * 2.0)) / _5921[0]) - float2(2.0);
                                _5922[1] = (float2(3.0) + _5966) / _5921[1];
                                _5922[2] = (_5966 / _5921[2]) + float2(2.0);
                            }
                            int _7041 = _5973 ? 2 : 3;
                            int _6642;
                            float _6645;
                            _6645 = 0.0;
                            _6642 = 0;
                            float _6651;
                            for (; _6642 < _7041; _6645 = _6651, _6642++)
                            {
                                _6651 = _6645;
                                for (int _6648 = 0; _6648 < _7041; )
                                {
                                    _6651 += ((_5921[_6648].x * _5921[_6642].y) * spvDepthCast(_200).sample_compare(_200Smplr, float3(fast::clamp(_180._m22.xy * (_5969 + float2(_5922[_6648].x, _5922[_6642].y)), _5911.xy, _5911.zw), _5635).xy, _5635));
                                    _6648++;
                                    continue;
                                }
                            }
                            _6652 = _6645 * (_5973 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _6664 = _6652;
                        break;
                    } while(false);
                    _6702 = _5384 * _6664;
                }
                else
                {
                    _6702 = _5384;
                }
                float3 _2490 = fast::normalize(_5353 + _2041);
                float _2495 = fast::clamp(dot(_6543, _5353), 0.0, 1.0);
                float _2500 = fast::clamp(dot(_6543, _2490), 0.0, 1.0);
                float3 _6108 = _2294 + (_4423 * powr(1.0 - fast::clamp(dot(_2041, _2490), 0.0, 1.0), 5.0));
                float _6122 = ((_2500 * _2500) * _4438) + 1.0;
                _2538 = _6704 + (((((float3(1.0) - _6108) * _2288) + ((_6108 * ((_4433 / ((3.1415927410125732421875 * _6122) * _6122)) * (0.5 / fast::max((_2495 * _4464) + (_2299 * sqrt(((_2495 * _2495) * _4460) + _4433)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875)) * _2495) * _6702);
            }
            _6751 = _6704;
        }
        else
        {
            _6751 = _2438;
        }
        _6748 = _6751;
    }
    float4 _2555 = _2550.sample(_1217, _1840);
    float _2573 = -length(_2040);
    float _6789;
    if (_180._m9.w != 0.0)
    {
        float _2597 = _180._m9.w * (in.m_1451 - _180._m6.xyz).y;
        float _6786;
        if (abs(_2597) < 9.9999997473787516355514526367188e-05)
        {
            _6786 = 1.0 - (0.5 * _2597);
        }
        else
        {
            _6786 = (1.0 - exp(fast::min(-_2597, 60.0))) / _2597;
        }
        _6789 = 1.0 - exp((_2573 * (_180._m7.w * exp(fast::min((-_180._m9.w) * (_180._m6.y - _180._m6.w), 30.0)))) * _6786);
    }
    else
    {
        _6789 = 1.0 - exp(_2573 * _180._m7.w);
    }
    float3 _2648 = mix(mix(_6748, _6539, float3(_1821._m1.y)) + ((_1821._m5.xyz * _2555.xyz) * (float3(1.0) + in.m_2054.yzw)), _180._m7.xyz, float3(_6789));
    float3 _6790;
    if (_180._m33.w > 0.5)
    {
        _6790 = _2648 / (float3(1.0) + _2648);
    }
    else
    {
        _6790 = _2648;
    }
    out.m_2660 = float4(_6790, in.m_1849.w);
    float2 _6862;
    do
    {
        if (in.m_2670.w <= 0.0)
        {
            _6862 = float2(0.0);
            break;
        }
        _6862 = ((in.m_2670.xy / float2(in.m_2670.w)) - (in.m_2669.xy / float2(in.m_2669.w))) * float2(0.5, -0.5);
        break;
    } while(false);
    out.m_2668 = _6862;
    return out;
}

