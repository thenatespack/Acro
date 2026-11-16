// Generated from mesh_mask.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 3456fe42f5a7d734
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
    float4 m_2755 [[color(0)]];
    float2 m_2763 [[color(1)]];
};

struct fragment_main_in
{
    float3 m_1451 [[user(locn0)]];
    float3 m_1906 [[user(locn1)]];
    float2 m_1826 [[user(locn2)]];
    float4 m_1849 [[user(locn3)]];
    float4 m_2067 [[user(locn5)]];
    float4 m_2764 [[user(locn6)]];
    float4 m_2765 [[user(locn7)]];
    float4 m_1915 [[user(locn8)]];
};

fragment fragment_main_out fragment_main(fragment_main_in in [[stage_in]], constant _1819& _1821 [[buffer(2)]], constant _1441& _1443 [[buffer(3)]], constant _1477& _1479 [[buffer(4)]], constant _1485& _1487 [[buffer(5)]], constant _1582& _1584 [[buffer(6)]], constant _1604& _1606 [[buffer(7)]], constant _178& _180 [[buffer(15)]], texture2d<float> _200 [[texture(0)]], texture2d<float> _1842 [[texture(1)]], texture2d<float> _2272 [[texture(2)]], texture2d<float> _1944 [[texture(3)]], texture2d<float> _1770 [[texture(4)]], texture2d<float> _2645 [[texture(5)]], texture2d<float> _1215 [[texture(6)]], texture2d<float> _1321 [[texture(7)]], sampler _200Smplr [[sampler(0)]], sampler _1217 [[sampler(1)]], sampler _1323 [[sampler(7)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])
{
    fragment_main_out out = {};
    float2 _1840 = float2(dot(_1821._m2.xy, in.m_1826) + _1821._m2.z, dot(_1821._m3.xy, in.m_1826) + _1821._m3.z);
    float4 _1847 = _1842.sample(_1217, _1840);
    float3 _1858 = (in.m_1849.xyz * _1821._m0.xyz) * _1847.xyz;
    if ((_1821._m0.w * _1847.w) < _1821._m6.x)
    {
        discard_fragment();
    }
    float3 _6611;
    if (_1821._m1.x > 0.5)
    {
        float2 _1892 = floor(in.m_1451.xz * float2(0.5));
        _6611 = _1858 * ((mod(abs(_1892.x + _1892.y), 2.0) < 0.5) ? 1.0 : 0.75);
    }
    else
    {
        _6611 = _1858;
    }
    float3 _1908 = fast::normalize(in.m_1906);
    float3 _6524;
    if (_1821._m6.y > 0.5)
    {
        float3 _1924 = in.m_1915.xyz - (_1908 * dot(_1908, in.m_1915.xyz));
        float3 _6525;
        if (dot(_1924, _1924) > 9.9999999600419720025001879548654e-13)
        {
            float3 _1933 = fast::normalize(_1924);
            float4 _1949 = _1944.sample(_1217, _1840);
            float3 _6516;
            if (_1821._m6.z > 0.5)
            {
                float2 _6515;
                if (_1821._m6.z > 1.5)
                {
                    _6515 = _1949.xw;
                }
                else
                {
                    _6515 = _1949.xy;
                }
                float2 _1971 = (_6515 * 2.0) - float2(1.0);
                _6516 = float3(_1971, sqrt(fast::clamp(1.0 - dot(_1971, _1971), 0.0, 1.0)));
            }
            else
            {
                _6516 = (_1949.xyz * 2.0) - float3(1.0);
            }
            float2 _1993 = _6516.xy * _1821._m4.z;
            _6525 = fast::normalize(((_1933 * _1993.x) + ((cross(_1908, _1933) * ((in.m_1915.w < 0.0) ? (-1.0) : 1.0)) * _1993.y)) + (_1908 * _6516.z));
        }
        else
        {
            _6525 = _1908;
        }
        _6524 = _6525;
    }
    else
    {
        _6524 = _1908;
    }
    bool _2017 = _1821._m5.w > 0.5;
    float _6521;
    if (_2017)
    {
        _6521 = fast::clamp(_1821._m1.z, 0.0, 1.0);
    }
    else
    {
        _6521 = 0.0;
    }
    bool _2035;
    if (_2017)
    {
        _2035 = !gl_FrontFacing;
    }
    else
    {
        _2035 = _2017;
    }
    float3 _6641;
    if (_2035 && (_6521 <= 0.0))
    {
        _6641 = -_6524;
    }
    else
    {
        _6641 = _6524;
    }
    float3 _2047 = fast::normalize(_180._m4.xyz);
    float3 _2053 = _180._m6.xyz - in.m_1451;
    float3 _2054 = fast::normalize(_2053);
    float3 _2059 = fast::normalize(_2047 + _2054);
    float3 _2065 = _1908 * (gl_FrontFacing ? 1.0 : (-1.0));
    bool _2070 = in.m_2067.x > 0.5;
    float3 _6637;
    float _6674;
    if ((_180._m5.w > 0.5) && _2070)
    {
        float _6581;
        float3 _6582;
        do
        {
            int _2823 = int(_180._m21.x);
            float _2831 = dot(_180._m20.xyz, in.m_1451) + _180._m20.w;
            int _6526;
            _6526 = 0;
            for (;;)
            {
                bool _2837 = _6526 < (_2823 - 1);
                bool _2845;
                if (_2837)
                {
                    _2845 = _2831 > _180._m16[_6526];
                }
                else
                {
                    _2845 = _2837;
                }
                if (_2845)
                {
                    _6526++;
                    continue;
                }
                else
                {
                    break;
                }
            }
            if (_2831 > _180._m16[_6526])
            {
                _6582 = float3(1.0);
                _6581 = 1.0;
                break;
            }
            float _6539;
            do
            {
                float4 _2947 = _180._m14[_6526] * float4(in.m_1451 + (_2065 * _180._m18[_6526]), 1.0);
                float _2950 = _2947.x;
                bool _2951 = _2950 < 0.0;
                bool _2958;
                if (!_2951)
                {
                    _2958 = _2950 > 1.0;
                }
                else
                {
                    _2958 = _2951;
                }
                bool _2965;
                if (!_2958)
                {
                    _2965 = _2947.y < 0.0;
                }
                else
                {
                    _2965 = _2958;
                }
                bool _2972;
                if (!_2965)
                {
                    _2972 = _2947.y > 1.0;
                }
                else
                {
                    _2972 = _2965;
                }
                if (_2972)
                {
                    _6539 = 1.0;
                    break;
                }
                float2 _2985 = float2(float(_6526 & 1), float(_6526 >> 1)) * _180._m23.xy;
                float _2992 = fast::min(_2947.z, 1.0) - _180._m19[_6526];
                float2 _3011 = _180._m22.xy * 0.5;
                float2 _3016 = _2985 + (_2947.xy * _180._m23.xy);
                float4 _3029 = float4(_2985 + _3011, (_2985 + _180._m23.xy) - _3011);
                float _6538;
                do
                {
                    int _3055 = int(_180._m22.z);
                    if (_3055 <= 0)
                    {
                        _6538 = spvDepthCast(_200).sample_compare(_200Smplr, float3(fast::clamp(_3016, _3029.xy, _3029.zw), _2992).xy, _2992);
                        break;
                    }
                    float2 _3078 = (_3016 / _180._m22.xy) + float2(0.5);
                    float2 _3079 = floor(_3078);
                    float2 _3084 = _3078 - _3079;
                    float2 _3087 = _3079 - float2(0.5);
                    bool _3091 = _3055 == 1;
                    spvUnsafeArray<float2, 3> _3039;
                    spvUnsafeArray<float2, 3> _3040;
                    if (_3091)
                    {
                        float2 _3094 = _3084 * 2.0;
                        _3039[0] = float2(3.0) - _3094;
                        _3039[1] = float2(1.0) + _3094;
                        _3040[0] = ((float2(2.0) - _3084) / _3039[0]) - float2(1.0);
                        _3040[1] = (_3084 / _3039[1]) + float2(1.0);
                    }
                    else
                    {
                        float2 _3121 = _3084 * 3.0;
                        _3039[0] = float2(4.0) - _3121;
                        _3039[1] = float2(7.0);
                        _3039[2] = float2(1.0) + _3121;
                        _3040[0] = ((float2(3.0) - (_3084 * 2.0)) / _3039[0]) - float2(2.0);
                        _3040[1] = (float2(3.0) + _3084) / _3039[1];
                        _3040[2] = (_3084 / _3039[2]) + float2(2.0);
                    }
                    int _7193 = _3091 ? 2 : 3;
                    int _6528;
                    float _6531;
                    _6531 = 0.0;
                    _6528 = 0;
                    float _6537;
                    for (; _6528 < _7193; _6531 = _6537, _6528++)
                    {
                        _6537 = _6531;
                        for (int _6534 = 0; _6534 < _7193; )
                        {
                            _6537 += ((_3039[_6534].x * _3039[_6528].y) * spvDepthCast(_200).sample_compare(_200Smplr, float3(fast::clamp(_180._m22.xy * (_3087 + float2(_3040[_6534].x, _3040[_6528].y)), _3029.xy, _3029.zw), _2992).xy, _2992));
                            _6534++;
                            continue;
                        }
                    }
                    _6538 = _6531 * (_3091 ? 0.0625 : 0.0069444444961845874786376953125);
                    break;
                } while(false);
                _6539 = _6538;
                break;
            } while(false);
            float3 _6576;
            float _6579;
            if (_2831 > _180._m17[_6526])
            {
                float _2885 = (_2831 - _180._m17[_6526]) / (_180._m16[_6526] - _180._m17[_6526]);
                int _2887 = _6526 + 1;
                float3 _6577;
                float _6580;
                if (_2887 < _2823)
                {
                    float _6559;
                    do
                    {
                        float4 _3234 = _180._m14[_2887] * float4(in.m_1451 + (_2065 * _180._m18[_2887]), 1.0);
                        float _3237 = _3234.x;
                        bool _3238 = _3237 < 0.0;
                        bool _3245;
                        if (!_3238)
                        {
                            _3245 = _3237 > 1.0;
                        }
                        else
                        {
                            _3245 = _3238;
                        }
                        bool _3252;
                        if (!_3245)
                        {
                            _3252 = _3234.y < 0.0;
                        }
                        else
                        {
                            _3252 = _3245;
                        }
                        bool _3259;
                        if (!_3252)
                        {
                            _3259 = _3234.y > 1.0;
                        }
                        else
                        {
                            _3259 = _3252;
                        }
                        if (_3259)
                        {
                            _6559 = 1.0;
                            break;
                        }
                        float2 _3272 = float2(float(_2887 & 1), float(_2887 >> 1)) * _180._m23.xy;
                        float _3279 = fast::min(_3234.z, 1.0) - _180._m19[_2887];
                        float2 _3298 = _180._m22.xy * 0.5;
                        float2 _3303 = _3272 + (_3234.xy * _180._m23.xy);
                        float4 _3316 = float4(_3272 + _3298, (_3272 + _180._m23.xy) - _3298);
                        float _6558;
                        do
                        {
                            int _3342 = int(_180._m22.z);
                            if (_3342 <= 0)
                            {
                                _6558 = spvDepthCast(_200).sample_compare(_200Smplr, float3(fast::clamp(_3303, _3316.xy, _3316.zw), _3279).xy, _3279);
                                break;
                            }
                            float2 _3365 = (_3303 / _180._m22.xy) + float2(0.5);
                            float2 _3366 = floor(_3365);
                            float2 _3371 = _3365 - _3366;
                            float2 _3374 = _3366 - float2(0.5);
                            bool _3378 = _3342 == 1;
                            spvUnsafeArray<float2, 3> _3326;
                            spvUnsafeArray<float2, 3> _3327;
                            if (_3378)
                            {
                                float2 _3381 = _3371 * 2.0;
                                _3326[0] = float2(3.0) - _3381;
                                _3326[1] = float2(1.0) + _3381;
                                _3327[0] = ((float2(2.0) - _3371) / _3326[0]) - float2(1.0);
                                _3327[1] = (_3371 / _3326[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _3408 = _3371 * 3.0;
                                _3326[0] = float2(4.0) - _3408;
                                _3326[1] = float2(7.0);
                                _3326[2] = float2(1.0) + _3408;
                                _3327[0] = ((float2(3.0) - (_3371 * 2.0)) / _3326[0]) - float2(2.0);
                                _3327[1] = (float2(3.0) + _3371) / _3326[1];
                                _3327[2] = (_3371 / _3326[2]) + float2(2.0);
                            }
                            int _7195 = _3378 ? 2 : 3;
                            int _6548;
                            float _6551;
                            _6551 = 0.0;
                            _6548 = 0;
                            float _6557;
                            for (; _6548 < _7195; _6551 = _6557, _6548++)
                            {
                                _6557 = _6551;
                                for (int _6554 = 0; _6554 < _7195; )
                                {
                                    _6557 += ((_3326[_6554].x * _3326[_6548].y) * spvDepthCast(_200).sample_compare(_200Smplr, float3(fast::clamp(_180._m22.xy * (_3374 + float2(_3327[_6554].x, _3327[_6548].y)), _3316.xy, _3316.zw), _3279).xy, _3279));
                                    _6554++;
                                    continue;
                                }
                            }
                            _6558 = _6551 * (_3378 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _6559 = _6558;
                        break;
                    } while(false);
                    _6580 = mix(_6539, _6559, _2885);
                    _6577 = mix(_554[_6526], _554[_2887], float3(_2885));
                }
                else
                {
                    _6580 = mix(_6539, 1.0, _2885);
                    _6577 = _554[_6526];
                }
                _6579 = _6580;
                _6576 = _6577;
            }
            else
            {
                _6579 = _6539;
                _6576 = _554[_6526];
            }
            _6582 = select(float3(1.0), _6576, bool3(_180._m22.w > 0.5));
            _6581 = _6579;
            break;
        } while(false);
        _6674 = _6581;
        _6637 = _6611 * _6582;
    }
    else
    {
        _6674 = 1.0;
        _6637 = _6611;
    }
    float3 _2096 = _180._m5.xyz * _180._m4.w;
    bool _2100 = _1821._m6.w > 0.5;
    float _6634;
    if (_2100)
    {
        _6634 = 1.0;
    }
    else
    {
        _6634 = 1.0 + (_1821._m4.w * (_1770.sample(_1217, _1840).x - 1.0));
    }
    float _2120 = abs(in.m_1915.w);
    float _6750;
    if (_2120 > 0.0)
    {
        _6750 = _6634 * fast::min(_2120, 1.0);
    }
    else
    {
        _6750 = _6634;
    }
    float3 _6908;
    if (!_2017)
    {
        float _2136 = dot(_6641, _2047);
        float3 _6900;
        if (_180._m29.x > 0.5)
        {
            float _3559 = (_180._m29.z * _6641.x) - (_180._m29.w * _6641.z);
            float _3572 = (_180._m29.w * _6641.x) + (_180._m29.z * _6641.z);
            float _3590 = 1.09254801273345947265625 * _3559;
            spvUnsafeArray<float, 9> _6322 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _6641.y, 0.48860299587249755859375 * _3572, 0.48860299587249755859375 * _3559, _3590 * _6641.y, (1.09254801273345947265625 * _6641.y) * _3572, 0.3153919875621795654296875 * (((3.0 * _3572) * _3572) - 1.0), _3590 * _3572, 0.546274006366729736328125 * ((_3559 * _3559) - (_6641.y * _6641.y)) });
            spvUnsafeArray<float, 9> _3504 = _6322;
            float3 _6899;
            _6899 = float3(0.0);
            for (int _6898 = 0; _6898 < 9; )
            {
                _6899 += (_1215.read(uint2((int2(496, 256) + int2(_6898, 0))), 0).xyz * _3504[_6898]);
                _6898++;
                continue;
            }
            _6900 = fast::max(_6899, float3(0.0)) * _180._m29.y;
        }
        else
        {
            _6900 = mix(_180._m9.xyz, _180._m8.xyz, float3((_6641.y * 0.5) + 0.5)) * _180._m8.w;
        }
        float3 _2186 = (_6637 * ((_6900 * _6750) + ((_2096 * fast::max(_2136, 0.0)) * _6674))) + ((_2096 * ((powr(fast::max(dot(_6641, _2059), 0.0), _1821._m1.w) * _1821._m1.z) * step(0.0, _2136))) * _6674);
        float3 _6909;
        if (_180._m13.w > 0.5)
        {
            float2 _3675 = fast::clamp(floor(gl_FragCoord.xy * _180._m12.xy), float2(0.0), _180._m13.xy - float2(1.0));
            uint _3703 = uint((((fast::clamp(floor((log2(fast::max(dot(_180._m11.xyz, in.m_1451) + _180._m11.w, 9.9999999747524270787835121154785e-07)) * _180._m12.z) + _180._m12.w), 0.0, _180._m13.z - 1.0) * _180._m13.y) + _3675.y) * _180._m13.x) + _3675.x);
            uint _3705 = _3703 >> uint(2);
            uint _3707 = _3703 & 3u;
            uint _3711 = _1584._m0[_3705][_3707] & 65535u;
            uint _3713 = _1584._m0[_3705][_3707] >> uint(16);
            float3 _6910;
            _6910 = _2186;
            float3 _2267;
            spvUnsafeArray<float2, 3> _4121;
            spvUnsafeArray<float2, 3> _4122;
            spvUnsafeArray<float2, 3> _4334;
            spvUnsafeArray<float2, 3> _4335;
            for (uint _6907 = _3711; _6907 < (_3711 + _3713); _6910 = _2267, _6907++)
            {
                uint _3719 = _6907 / 3u;
                uint _3732 = (_1606._m0[_3719 >> uint(2)][_3719 & 3u] >> ((_6907 - (_3719 * 3u)) * 10u)) & 1023u;
                float3 _3749 = _1443._m0[_3732].xyz - in.m_1451;
                float _3752 = dot(_3749, _3749);
                float _3756 = _3752 * _1443._m0[_3732].w;
                float _3761 = fast::clamp(1.0 - (_3756 * _3756), 0.0, 1.0);
                float3 _3766 = _3749 * rsqrt(fast::max(_3752, 9.9999999392252902907785028219223e-09));
                float _3784 = fast::clamp((dot(-_3766, _1487._m0[_3732].xyz) * _1479._m0[_3732].w) + _1487._m0[_3732].w, 0.0, 1.0);
                float3 _3797 = _1479._m0[_3732].xyz * ((((_3761 * _3761) * _3784) * _3784) / fast::max(_3752, 9.9999997473787516355514526367188e-05));
                float3 _7112;
                if (_2070)
                {
                    float _7058;
                    do
                    {
                        uint _3833 = uint(_180._m21.z);
                        if (_3732 < _3833)
                        {
                            float _3855 = _180._m26[_3732].z * fast::max((_180._m15[_3732] * float4(in.m_1451, 1.0)).w, 0.0);
                            float4 _3879 = _180._m15[_3732] * float4((in.m_1451 + (_2065 * (_3855 * _180._m25.x))) + (_3766 * (_3855 * _180._m25.y)), 1.0);
                            float _3881 = _3879.w;
                            if (_3881 <= 0.0)
                            {
                                _7058 = 1.0;
                                break;
                            }
                            float3 _3890 = _3879.xyz / float3(_3881);
                            float _3892 = _3890.x;
                            bool _3893 = _3892 < 0.0;
                            bool _3900;
                            if (!_3893)
                            {
                                _3900 = _3892 > 1.0;
                            }
                            else
                            {
                                _3900 = _3893;
                            }
                            bool _3907;
                            if (!_3900)
                            {
                                _3907 = _3890.y < 0.0;
                            }
                            else
                            {
                                _3907 = _3900;
                            }
                            bool _3914;
                            if (!_3907)
                            {
                                _3914 = _3890.y > 1.0;
                            }
                            else
                            {
                                _3914 = _3907;
                            }
                            bool _3921;
                            if (!_3914)
                            {
                                _3921 = _3890.z > 1.0;
                            }
                            else
                            {
                                _3921 = _3914;
                            }
                            if (_3921)
                            {
                                _7058 = 1.0;
                                break;
                            }
                            float _3927 = _3890.z;
                            float2 _4093 = _180._m22.xy * 0.5;
                            float2 _4098 = _180._m26[_3732].xy + (_3890.xy * _180._m23.zw);
                            float4 _4111 = float4(_180._m26[_3732].xy + _4093, (_180._m26[_3732].xy + _180._m23.zw) - _4093);
                            float _7057;
                            do
                            {
                                int _4137 = int(_180._m22.z);
                                if (_4137 <= 0)
                                {
                                    float2 _4147 = fast::clamp(_4098, _4111.xy, _4111.zw);
                                    _7057 = spvDepthCast(_200).sample_compare(_200Smplr, float3(_4147, _3927).xy, _3927);
                                    break;
                                }
                                float2 _4160 = (_4098 / _180._m22.xy) + float2(0.5);
                                float2 _4161 = floor(_4160);
                                float2 _4166 = _4160 - _4161;
                                float2 _4169 = _4161 - float2(0.5);
                                bool _4173 = _4137 == 1;
                                if (_4173)
                                {
                                    float2 _4176 = _4166 * 2.0;
                                    _4121[0] = float2(3.0) - _4176;
                                    _4121[1] = float2(1.0) + _4176;
                                    _4122[0] = ((float2(2.0) - _4166) / _4121[0]) - float2(1.0);
                                    _4122[1] = (_4166 / _4121[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _4203 = _4166 * 3.0;
                                    _4121[0] = float2(4.0) - _4203;
                                    _4121[1] = float2(7.0);
                                    _4121[2] = float2(1.0) + _4203;
                                    _4122[0] = ((float2(3.0) - (_4166 * 2.0)) / _4121[0]) - float2(2.0);
                                    _4122[1] = (float2(3.0) + _4166) / _4121[1];
                                    _4122[2] = (_4166 / _4121[2]) + float2(2.0);
                                }
                                int _7200 = _4173 ? 2 : 3;
                                int _7047;
                                float _7050;
                                _7050 = 0.0;
                                _7047 = 0;
                                float _7056;
                                for (; _7047 < _7200; _7050 = _7056, _7047++)
                                {
                                    _7056 = _7050;
                                    for (int _7053 = 0; _7053 < _7200; )
                                    {
                                        _7056 += ((_4121[_7053].x * _4121[_7047].y) * spvDepthCast(_200).sample_compare(_200Smplr, float3(fast::clamp(_180._m22.xy * (_4169 + float2(_4122[_7053].x, _4122[_7047].y)), _4111.xy, _4111.zw), _3927).xy, _3927));
                                        _7053++;
                                        continue;
                                    }
                                }
                                _7057 = _7050 * (_4173 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _7058 = _7057;
                            break;
                        }
                        uint _3937 = _3732 - _3833;
                        if (_3937 >= uint(_180._m21.w))
                        {
                            _7058 = 1.0;
                            break;
                        }
                        float _3958 = _180._m27[_3937].w * length(in.m_1451 - _180._m27[_3937].xyz);
                        float3 _3976 = ((in.m_1451 + (_2065 * (_3958 * _180._m25.x))) + (_3766 * (_3958 * _180._m25.y))) - _180._m27[_3937].xyz;
                        float3 _3978 = abs(_3976);
                        float _3980 = _3978.x;
                        float _3982 = _3978.y;
                        bool _3983 = _3980 >= _3982;
                        bool _3991;
                        if (_3983)
                        {
                            _3991 = _3980 >= _3978.z;
                        }
                        else
                        {
                            _3991 = _3983;
                        }
                        float _7032;
                        int _7034;
                        if (_3991)
                        {
                            _7034 = (_3976.x > 0.0) ? 0 : 1;
                            _7032 = _3980;
                        }
                        else
                        {
                            float _4003 = _3978.z;
                            bool _4004 = _3982 >= _4003;
                            int _7035;
                            if (_4004)
                            {
                                _7035 = (_3976.y > 0.0) ? 2 : 3;
                            }
                            else
                            {
                                _7035 = (_3976.z > 0.0) ? 4 : 5;
                            }
                            _7034 = _7035;
                            _7032 = _4004 ? _3982 : _4003;
                        }
                        if (_7032 <= 0.0)
                        {
                            _7058 = 1.0;
                            break;
                        }
                        float2 _4041 = float2(dot(_3976, _858[_7034]), dot(_3976, _867[_7034])) / float2(_7032 * _180._m24.z);
                        float _4048 = _180._m28[_3937].z + (_180._m28[_3937].w / _7032);
                        if (_4048 > 1.0)
                        {
                            _7058 = 1.0;
                            break;
                        }
                        float2 _4066 = _180._m28[_3937].xy + (float2(float(spvSMod(_7034, 3)), float(_7034 / 3)) * _180._m24.xy);
                        float2 _4306 = _180._m22.xy * 0.5;
                        float2 _4311 = _4066 + (float2(0.5 + (0.5 * _4041.x), 0.5 - (0.5 * _4041.y)) * _180._m24.xy);
                        float4 _4324 = float4(_4066 + _4306, (_4066 + _180._m24.xy) - _4306);
                        float _7046;
                        do
                        {
                            int _4350 = int(_180._m22.z);
                            if (_4350 <= 0)
                            {
                                _7046 = spvDepthCast(_200).sample_compare(_200Smplr, float3(fast::clamp(_4311, _4324.xy, _4324.zw), _4048).xy, _4048);
                                break;
                            }
                            float2 _4373 = (_4311 / _180._m22.xy) + float2(0.5);
                            float2 _4374 = floor(_4373);
                            float2 _4379 = _4373 - _4374;
                            float2 _4382 = _4374 - float2(0.5);
                            bool _4386 = _4350 == 1;
                            if (_4386)
                            {
                                float2 _4389 = _4379 * 2.0;
                                _4334[0] = float2(3.0) - _4389;
                                _4334[1] = float2(1.0) + _4389;
                                _4335[0] = ((float2(2.0) - _4379) / _4334[0]) - float2(1.0);
                                _4335[1] = (_4379 / _4334[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _4416 = _4379 * 3.0;
                                _4334[0] = float2(4.0) - _4416;
                                _4334[1] = float2(7.0);
                                _4334[2] = float2(1.0) + _4416;
                                _4335[0] = ((float2(3.0) - (_4379 * 2.0)) / _4334[0]) - float2(2.0);
                                _4335[1] = (float2(3.0) + _4379) / _4334[1];
                                _4335[2] = (_4379 / _4334[2]) + float2(2.0);
                            }
                            int _7203 = _4386 ? 2 : 3;
                            int _7036;
                            float _7039;
                            _7039 = 0.0;
                            _7036 = 0;
                            float _7045;
                            for (; _7036 < _7203; _7039 = _7045, _7036++)
                            {
                                _7045 = _7039;
                                for (int _7042 = 0; _7042 < _7203; )
                                {
                                    _7045 += ((_4334[_7042].x * _4334[_7036].y) * spvDepthCast(_200).sample_compare(_200Smplr, float3(fast::clamp(_180._m22.xy * (_4382 + float2(_4335[_7042].x, _4335[_7036].y)), _4324.xy, _4324.zw), _4048).xy, _4048));
                                    _7042++;
                                    continue;
                                }
                            }
                            _7046 = _7039 * (_4386 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _7058 = _7046;
                        break;
                    } while(false);
                    _7112 = _3797 * _7058;
                }
                else
                {
                    _7112 = _3797;
                }
                float _2238 = dot(_6641, _3766);
                _2267 = _6910 + (((_6637 * fast::max(_2238, 0.0)) * _7112) + (_7112 * ((powr(fast::max(dot(_6641, fast::normalize(_3766 + _2054)), 0.0), _1821._m1.w) * _1821._m1.z) * step(0.0, _2238))));
            }
            _6909 = _6910;
        }
        else
        {
            _6909 = _2186;
        }
        _6908 = _6909;
    }
    else
    {
        float4 _2277 = _2272.sample(_1217, _1840);
        float _2284 = fast::clamp(_1821._m4.x * _2277.z, 0.0, 1.0);
        float _2292 = fast::clamp(_1821._m4.y * _2277.y, 0.04500000178813934326171875, 1.0);
        float _2296 = _2292 * _2292;
        float3 _2301 = _6637 * (1.0 - _2284);
        float3 _2307 = mix(float3(0.039999999105930328369140625), _6637, float3(_2284));
        bool _2311 = _6521 > 0.0;
        float3 _6664;
        if (_2311)
        {
            float3 _2316 = dfdx(in.m_1451);
            float3 _2318 = dfdy(in.m_1451);
            float3 _2319 = cross(_2316, _2318);
            float3 _6665;
            if (dot(_2319, _2319) > 9.9999996826552253889678874634872e-21)
            {
                _6665 = fast::normalize((fast::normalize(_2319) * ((dot(_2319, _2054) < 0.0) ? (-1.0) : 1.0)) + (_6641 - _1908));
            }
            else
            {
                _6665 = _6641;
            }
            _6664 = _6665;
        }
        else
        {
            _6664 = _6641;
        }
        float _2345 = fast::max(dot(_6664, _2054), 9.9999997473787516355514526367188e-05);
        float _2354 = dot(_6664, _2047);
        float _2355 = fast::clamp(_2354, 0.0, 1.0);
        float _2360 = fast::clamp(dot(_6664, _2059), 0.0, 1.0);
        float _2365 = fast::clamp(dot(_2054, _2059), 0.0, 1.0);
        float _6668;
        float _6669;
        if (_2311)
        {
            _6669 = fast::max(_2345, 0.5);
            _6668 = fast::max(_2365, 0.5);
        }
        else
        {
            _6669 = _2345;
            _6668 = _2365;
        }
        float3 _4518 = float3(1.0) - _2307;
        float3 _4521 = _2307 + (_4518 * powr(1.0 - _6668, 5.0));
        float _4528 = _2296 * _2296;
        float _4533 = _4528 - 1.0;
        float _4535 = ((_2360 * _2360) * _4533) + 1.0;
        float _4555 = 1.0 - _4528;
        float _4559 = sqrt(((_6669 * _6669) * _4555) + _4528);
        float3 _2411 = (((((float3(1.0) - _4521) * _2301) * fast::clamp(dot(_6641, _2047), 0.0, 1.0)) + (((_4521 * ((_4528 / ((3.1415927410125732421875 * _4535) * _4535)) * (0.5 / fast::max((_2355 * _4559) + (_6669 * sqrt(((_2355 * _2355) * _4555) + _4528)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875) * _2355)) * _2096) * _6674;
        float3 _6764;
        if (_2311)
        {
            _6764 = _2411 + (((((_2301 * _2096) * _6674) * _6521) * fast::clamp(-_2354, 0.0, 1.0)) * (0.3499999940395355224609375 + (0.64999997615814208984375 * powr(fast::clamp(dot(-_2054, _2047), 0.0, 1.0), 3.0))));
        }
        else
        {
            _6764 = _2411;
        }
        float3 _6699;
        float2 _6715;
        float3 _6727;
        if (_180._m29.x > 0.5)
        {
            float4 _4592 = _1321.sample(_1323, (((float2(_6669, _2292) * 31.0) + float2(0.5)) * float2(0.03125)));
            float _4651 = (_180._m29.z * _6641.x) - (_180._m29.w * _6641.z);
            float _4664 = (_180._m29.w * _6641.x) + (_180._m29.z * _6641.z);
            float _4682 = 1.09254801273345947265625 * _4651;
            spvUnsafeArray<float, 9> _6303 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _6641.y, 0.48860299587249755859375 * _4664, 0.48860299587249755859375 * _4651, _4682 * _6641.y, (1.09254801273345947265625 * _6641.y) * _4664, 0.3153919875621795654296875 * (((3.0 * _4664) * _4664) - 1.0), _4682 * _4664, 0.546274006366729736328125 * ((_4651 * _4651) - (_6641.y * _6641.y)) });
            spvUnsafeArray<float, 9> _4596 = _6303;
            float3 _6682;
            _6682 = float3(0.0);
            for (int _6681 = 0; _6681 < 9; )
            {
                _6682 += (_1215.read(uint2((int2(496, 256) + int2(_6681, 0))), 0).xyz * _4596[_6681]);
                _6681++;
                continue;
            }
            float3 _2465 = reflect(-_2054, _6664);
            float _4777 = _2465.x;
            float _4782 = _2465.z;
            float2 _4814 = float2((precise::atan2((_180._m29.z * _4777) - (_180._m29.w * _4782), -((_180._m29.w * _4777) + (_180._m29.z * _4782))) * 0.15915493667125701904296875) + 0.5, acos(fast::clamp(_2465.y, -1.0, 1.0)) * 0.3183098733425140380859375);
            float _4746 = _2292 * 5.0;
            int _4749 = min(int(_4746), 4);
            float2 _4835 = (_4814 * float2(_1277[_4749].zw)) - float2(0.5);
            float2 _4837 = floor(_4835);
            float2 _4840 = _4835 - _4837;
            int _4843 = int(_4837.x);
            int _4846 = int(_4837.y);
            int _6684;
            if (_4843 < 0)
            {
                _6684 = _4843 + _1277[_4749].z;
            }
            else
            {
                _6684 = _4843;
            }
            int _6685;
            if (_6684 >= _1277[_4749].z)
            {
                _6685 = _6684 - _1277[_4749].z;
            }
            else
            {
                _6685 = _6684;
            }
            int _4866 = _6685 + 1;
            int _7204 = (_4866 == _1277[_4749].z) ? 0 : _4866;
            int _4881 = min((_4846 + 1), (_1277[_4749].w - 1));
            int _4883 = max(_4846, 0);
            float3 _4936 = float3(_4840.x);
            int _4756 = _4749 + 1;
            float2 _4968 = (_4814 * float2(_1277[_4756].zw)) - float2(0.5);
            float2 _4970 = floor(_4968);
            float2 _4973 = _4968 - _4970;
            int _4976 = int(_4970.x);
            int _4979 = int(_4970.y);
            int _6691;
            if (_4976 < 0)
            {
                _6691 = _4976 + _1277[_4756].z;
            }
            else
            {
                _6691 = _4976;
            }
            int _6692;
            if (_6691 >= _1277[_4756].z)
            {
                _6692 = _6691 - _1277[_4756].z;
            }
            else
            {
                _6692 = _6691;
            }
            int _4999 = _6692 + 1;
            int _7205 = (_4999 == _1277[_4756].z) ? 0 : _4999;
            int _5014 = min((_4979 + 1), (_1277[_4756].w - 1));
            int _5016 = max(_4979, 0);
            float3 _5069 = float3(_4973.x);
            float3 _4771 = mix(mix(mix(_1215.read(uint2((_1277[_4749].xy + int2(_6685, _4883))), 0).xyz, _1215.read(uint2((_1277[_4749].xy + int2(_7204, _4883))), 0).xyz, _4936), mix(_1215.read(uint2((_1277[_4749].xy + int2(_6685, _4881))), 0).xyz, _1215.read(uint2((_1277[_4749].xy + int2(_7204, _4881))), 0).xyz, _4936), float3(_4840.y)), mix(mix(_1215.read(uint2((_1277[_4756].xy + int2(_6692, _5016))), 0).xyz, _1215.read(uint2((_1277[_4756].xy + int2(_7205, _5016))), 0).xyz, _5069), mix(_1215.read(uint2((_1277[_4756].xy + int2(_6692, _5014))), 0).xyz, _1215.read(uint2((_1277[_4756].xy + int2(_7205, _5014))), 0).xyz, _5069), float3(_4973.y)), float3(_4746 - float(_4749))) * _180._m29.y;
            _6727 = fast::max(_6682, float3(0.0)) * _180._m29.y;
            _6715 = _4592.xy;
            _6699 = _4771;
        }
        else
        {
            float4 _5087 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * _2292) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);
            float _5089 = _5087.x;
            float3 _5124 = mix(_180._m9.xyz, _180._m8.xyz, float3((_6641.y * 0.5) + 0.5)) * _180._m8.w;
            _6727 = _5124;
            _6715 = (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_5089 * _5089, exp2((-9.27999973297119140625) * _6669)) * _5089) + _5087.y)) + _5087.zw;
            _6699 = mix(mix(_180._m9.xyz, _180._m8.xyz, float3((reflect(-_2054, _6664).y * 0.5) + 0.5)) * _180._m8.w, _5124, float3(_2292));
        }
        bool _2497;
        if (_2100)
        {
            _2497 = _180._m33.z > 0.5;
        }
        else
        {
            _2497 = _2100;
        }
        float3 _6736;
        if (_2497)
        {
            float3 _6712;
            do
            {
                float _5203 = ((_180._m32.x * (1.0 - smoothstep(_180._m33.x * 0.5, _180._m33.x, abs(dot(_180._m31.xyz, in.m_1451) - _180._m31.w)))) * smoothstep(0.5, 0.89999997615814208984375, dot(_2065, _180._m31.xyz))) * (1.0 - smoothstep(_180._m32.y * 0.5, _180._m32.y, _2292));
                if (_5203 <= 0.0)
                {
                    _6712 = _6699;
                    break;
                }
                float4 _5228 = _180._m30 * float4(in.m_1451 + ((_6641 - (_180._m31.xyz * dot(_6641, _180._m31.xyz))) * _180._m32.w), 1.0);
                float2 _5241 = ((float2(_5228.x, -_5228.y) / float2(_5228.w)) * 0.5) + float2(0.5);
                float _5245 = _180._m32.z * _2292;
                float3 _6710;
                float _6711;
                _6711 = 0.0;
                _6710 = float3(0.0);
                for (int _6709 = 0; _6709 < 12; )
                {
                    float _5252 = float(_6709);
                    float _5260 = _5252 * 2.3999631404876708984375;
                    float2 _5272 = _5241 + (float2(cos(_5260) * _180._m33.y, sin(_5260)) * (sqrt((_5252 + 0.5) * 0.083333335816860198974609375) * _5245));
                    float2 _5277 = fast::min(_5272, float2(1.0) - _5272);
                    float _5283 = smoothstep(0.0, 0.039999999105930328369140625, fast::min(_5277.x, _5277.y));
                    float4 _5291 = _1770.sample(_1217, fast::clamp(_5272, float2(0.0), float2(1.0)), level(0.0));
                    float3 _5293 = _5291.xyz;
                    _6711 += (_5291.w * _5283);
                    _6710 += ((_5293 / (float3(1.0) - fast::min(_5293, float3(0.99500000476837158203125)))) * _5283);
                    _6709++;
                    continue;
                }
                _6712 = mix(_6699, (_6710 * float3(0.083333335816860198974609375)) + (_6699 * (1.0 - (_6711 * 0.083333335816860198974609375))), float3(_5203));
                break;
            } while(false);
            _6736 = _6712;
        }
        else
        {
            _6736 = _6699;
        }
        float3 _2517 = (_2307 * _6715.x) + float3(_6715.y);
        float3 _2533 = _6764 + (((((float3(1.0) - _2517) * _2301) * _6727) + (_2517 * _6736)) * _6750);
        float3 _6911;
        if (_180._m13.w > 0.5)
        {
            float2 _5357 = fast::clamp(floor(gl_FragCoord.xy * _180._m12.xy), float2(0.0), _180._m13.xy - float2(1.0));
            uint _5385 = uint((((fast::clamp(floor((log2(fast::max(dot(_180._m11.xyz, in.m_1451) + _180._m11.w, 9.9999999747524270787835121154785e-07)) * _180._m12.z) + _180._m12.w), 0.0, _180._m13.z - 1.0) * _180._m13.y) + _5357.y) * _180._m13.x) + _5357.x);
            uint _5387 = _5385 >> uint(2);
            uint _5389 = _5385 & 3u;
            uint _5393 = _1584._m0[_5387][_5389] & 65535u;
            uint _5395 = _1584._m0[_5387][_5389] >> uint(16);
            float3 _6864;
            _6864 = _2533;
            float3 _2633;
            spvUnsafeArray<float2, 3> _5803;
            spvUnsafeArray<float2, 3> _5804;
            spvUnsafeArray<float2, 3> _6016;
            spvUnsafeArray<float2, 3> _6017;
            for (uint _6767 = _5393; _6767 < (_5393 + _5395); _6864 = _2633, _6767++)
            {
                uint _5401 = _6767 / 3u;
                uint _5414 = (_1606._m0[_5401 >> uint(2)][_5401 & 3u] >> ((_6767 - (_5401 * 3u)) * 10u)) & 1023u;
                float3 _5431 = _1443._m0[_5414].xyz - in.m_1451;
                float _5434 = dot(_5431, _5431);
                float _5438 = _5434 * _1443._m0[_5414].w;
                float _5443 = fast::clamp(1.0 - (_5438 * _5438), 0.0, 1.0);
                float3 _5448 = _5431 * rsqrt(fast::max(_5434, 9.9999999392252902907785028219223e-09));
                float _5466 = fast::clamp((dot(-_5448, _1487._m0[_5414].xyz) * _1479._m0[_5414].w) + _1487._m0[_5414].w, 0.0, 1.0);
                float3 _5479 = _1479._m0[_5414].xyz * ((((_5443 * _5443) * _5466) * _5466) / fast::max(_5434, 9.9999997473787516355514526367188e-05));
                float3 _6862;
                if (_2070)
                {
                    float _6794;
                    do
                    {
                        uint _5515 = uint(_180._m21.z);
                        if (_5414 < _5515)
                        {
                            float _5537 = _180._m26[_5414].z * fast::max((_180._m15[_5414] * float4(in.m_1451, 1.0)).w, 0.0);
                            float4 _5561 = _180._m15[_5414] * float4((in.m_1451 + (_2065 * (_5537 * _180._m25.x))) + (_5448 * (_5537 * _180._m25.y)), 1.0);
                            float _5563 = _5561.w;
                            if (_5563 <= 0.0)
                            {
                                _6794 = 1.0;
                                break;
                            }
                            float3 _5572 = _5561.xyz / float3(_5563);
                            float _5574 = _5572.x;
                            bool _5575 = _5574 < 0.0;
                            bool _5582;
                            if (!_5575)
                            {
                                _5582 = _5574 > 1.0;
                            }
                            else
                            {
                                _5582 = _5575;
                            }
                            bool _5589;
                            if (!_5582)
                            {
                                _5589 = _5572.y < 0.0;
                            }
                            else
                            {
                                _5589 = _5582;
                            }
                            bool _5596;
                            if (!_5589)
                            {
                                _5596 = _5572.y > 1.0;
                            }
                            else
                            {
                                _5596 = _5589;
                            }
                            bool _5603;
                            if (!_5596)
                            {
                                _5603 = _5572.z > 1.0;
                            }
                            else
                            {
                                _5603 = _5596;
                            }
                            if (_5603)
                            {
                                _6794 = 1.0;
                                break;
                            }
                            float _5609 = _5572.z;
                            float2 _5775 = _180._m22.xy * 0.5;
                            float2 _5780 = _180._m26[_5414].xy + (_5572.xy * _180._m23.zw);
                            float4 _5793 = float4(_180._m26[_5414].xy + _5775, (_180._m26[_5414].xy + _180._m23.zw) - _5775);
                            float _6793;
                            do
                            {
                                int _5819 = int(_180._m22.z);
                                if (_5819 <= 0)
                                {
                                    float2 _5829 = fast::clamp(_5780, _5793.xy, _5793.zw);
                                    _6793 = spvDepthCast(_200).sample_compare(_200Smplr, float3(_5829, _5609).xy, _5609);
                                    break;
                                }
                                float2 _5842 = (_5780 / _180._m22.xy) + float2(0.5);
                                float2 _5843 = floor(_5842);
                                float2 _5848 = _5842 - _5843;
                                float2 _5851 = _5843 - float2(0.5);
                                bool _5855 = _5819 == 1;
                                if (_5855)
                                {
                                    float2 _5858 = _5848 * 2.0;
                                    _5803[0] = float2(3.0) - _5858;
                                    _5803[1] = float2(1.0) + _5858;
                                    _5804[0] = ((float2(2.0) - _5848) / _5803[0]) - float2(1.0);
                                    _5804[1] = (_5848 / _5803[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _5885 = _5848 * 3.0;
                                    _5803[0] = float2(4.0) - _5885;
                                    _5803[1] = float2(7.0);
                                    _5803[2] = float2(1.0) + _5885;
                                    _5804[0] = ((float2(3.0) - (_5848 * 2.0)) / _5803[0]) - float2(2.0);
                                    _5804[1] = (float2(3.0) + _5848) / _5803[1];
                                    _5804[2] = (_5848 / _5803[2]) + float2(2.0);
                                }
                                int _7207 = _5855 ? 2 : 3;
                                int _6783;
                                float _6786;
                                _6786 = 0.0;
                                _6783 = 0;
                                float _6792;
                                for (; _6783 < _7207; _6786 = _6792, _6783++)
                                {
                                    _6792 = _6786;
                                    for (int _6789 = 0; _6789 < _7207; )
                                    {
                                        _6792 += ((_5803[_6789].x * _5803[_6783].y) * spvDepthCast(_200).sample_compare(_200Smplr, float3(fast::clamp(_180._m22.xy * (_5851 + float2(_5804[_6789].x, _5804[_6783].y)), _5793.xy, _5793.zw), _5609).xy, _5609));
                                        _6789++;
                                        continue;
                                    }
                                }
                                _6793 = _6786 * (_5855 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _6794 = _6793;
                            break;
                        }
                        uint _5619 = _5414 - _5515;
                        if (_5619 >= uint(_180._m21.w))
                        {
                            _6794 = 1.0;
                            break;
                        }
                        float _5640 = _180._m27[_5619].w * length(in.m_1451 - _180._m27[_5619].xyz);
                        float3 _5658 = ((in.m_1451 + (_2065 * (_5640 * _180._m25.x))) + (_5448 * (_5640 * _180._m25.y))) - _180._m27[_5619].xyz;
                        float3 _5660 = abs(_5658);
                        float _5662 = _5660.x;
                        float _5664 = _5660.y;
                        bool _5665 = _5662 >= _5664;
                        bool _5673;
                        if (_5665)
                        {
                            _5673 = _5662 >= _5660.z;
                        }
                        else
                        {
                            _5673 = _5665;
                        }
                        float _6768;
                        int _6770;
                        if (_5673)
                        {
                            _6770 = (_5658.x > 0.0) ? 0 : 1;
                            _6768 = _5662;
                        }
                        else
                        {
                            float _5685 = _5660.z;
                            bool _5686 = _5664 >= _5685;
                            int _6771;
                            if (_5686)
                            {
                                _6771 = (_5658.y > 0.0) ? 2 : 3;
                            }
                            else
                            {
                                _6771 = (_5658.z > 0.0) ? 4 : 5;
                            }
                            _6770 = _6771;
                            _6768 = _5686 ? _5664 : _5685;
                        }
                        if (_6768 <= 0.0)
                        {
                            _6794 = 1.0;
                            break;
                        }
                        float2 _5723 = float2(dot(_5658, _858[_6770]), dot(_5658, _867[_6770])) / float2(_6768 * _180._m24.z);
                        float _5730 = _180._m28[_5619].z + (_180._m28[_5619].w / _6768);
                        if (_5730 > 1.0)
                        {
                            _6794 = 1.0;
                            break;
                        }
                        float2 _5748 = _180._m28[_5619].xy + (float2(float(spvSMod(_6770, 3)), float(_6770 / 3)) * _180._m24.xy);
                        float2 _5988 = _180._m22.xy * 0.5;
                        float2 _5993 = _5748 + (float2(0.5 + (0.5 * _5723.x), 0.5 - (0.5 * _5723.y)) * _180._m24.xy);
                        float4 _6006 = float4(_5748 + _5988, (_5748 + _180._m24.xy) - _5988);
                        float _6782;
                        do
                        {
                            int _6032 = int(_180._m22.z);
                            if (_6032 <= 0)
                            {
                                _6782 = spvDepthCast(_200).sample_compare(_200Smplr, float3(fast::clamp(_5993, _6006.xy, _6006.zw), _5730).xy, _5730);
                                break;
                            }
                            float2 _6055 = (_5993 / _180._m22.xy) + float2(0.5);
                            float2 _6056 = floor(_6055);
                            float2 _6061 = _6055 - _6056;
                            float2 _6064 = _6056 - float2(0.5);
                            bool _6068 = _6032 == 1;
                            if (_6068)
                            {
                                float2 _6071 = _6061 * 2.0;
                                _6016[0] = float2(3.0) - _6071;
                                _6016[1] = float2(1.0) + _6071;
                                _6017[0] = ((float2(2.0) - _6061) / _6016[0]) - float2(1.0);
                                _6017[1] = (_6061 / _6016[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _6098 = _6061 * 3.0;
                                _6016[0] = float2(4.0) - _6098;
                                _6016[1] = float2(7.0);
                                _6016[2] = float2(1.0) + _6098;
                                _6017[0] = ((float2(3.0) - (_6061 * 2.0)) / _6016[0]) - float2(2.0);
                                _6017[1] = (float2(3.0) + _6061) / _6016[1];
                                _6017[2] = (_6061 / _6016[2]) + float2(2.0);
                            }
                            int _7210 = _6068 ? 2 : 3;
                            int _6772;
                            float _6775;
                            _6775 = 0.0;
                            _6772 = 0;
                            float _6781;
                            for (; _6772 < _7210; _6775 = _6781, _6772++)
                            {
                                _6781 = _6775;
                                for (int _6778 = 0; _6778 < _7210; )
                                {
                                    _6781 += ((_6016[_6778].x * _6016[_6772].y) * spvDepthCast(_200).sample_compare(_200Smplr, float3(fast::clamp(_180._m22.xy * (_6064 + float2(_6017[_6778].x, _6017[_6772].y)), _6006.xy, _6006.zw), _5730).xy, _5730));
                                    _6778++;
                                    continue;
                                }
                            }
                            _6782 = _6775 * (_6068 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _6794 = _6782;
                        break;
                    } while(false);
                    _6862 = _5479 * _6794;
                }
                else
                {
                    _6862 = _5479;
                }
                float3 _2585 = fast::normalize(_5448 + _2054);
                float _2590 = fast::clamp(dot(_6641, _5448), 0.0, 1.0);
                float _2595 = fast::clamp(dot(_6641, _2585), 0.0, 1.0);
                float3 _6203 = _2307 + (_4518 * powr(1.0 - fast::clamp(dot(_2054, _2585), 0.0, 1.0), 5.0));
                float _6217 = ((_2595 * _2595) * _4533) + 1.0;
                _2633 = _6864 + (((((float3(1.0) - _6203) * _2301) + ((_6203 * ((_4528 / ((3.1415927410125732421875 * _6217) * _6217)) * (0.5 / fast::max((_2590 * _4559) + (_6669 * sqrt(((_2590 * _2590) * _4555) + _4528)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875)) * _2590) * _6862);
            }
            _6911 = _6864;
        }
        else
        {
            _6911 = _2533;
        }
        _6908 = _6911;
    }
    float4 _2650 = _2645.sample(_1217, _1840);
    float _2668 = -length(_2053);
    float _6953;
    if (_180._m9.w != 0.0)
    {
        float _2692 = _180._m9.w * (in.m_1451 - _180._m6.xyz).y;
        float _6950;
        if (abs(_2692) < 9.9999997473787516355514526367188e-05)
        {
            _6950 = 1.0 - (0.5 * _2692);
        }
        else
        {
            _6950 = (1.0 - exp(fast::min(-_2692, 60.0))) / _2692;
        }
        _6953 = 1.0 - exp((_2668 * (_180._m7.w * exp(fast::min((-_180._m9.w) * (_180._m6.y - _180._m6.w), 30.0)))) * _6950);
    }
    else
    {
        _6953 = 1.0 - exp(_2668 * _180._m7.w);
    }
    float3 _2743 = mix(mix(_6908, _6637, float3(_1821._m1.y)) + ((_1821._m5.xyz * _2650.xyz) * (float3(1.0) + in.m_2067.yzw)), _180._m7.xyz, float3(_6953));
    float3 _6954;
    if (_180._m33.w > 0.5)
    {
        _6954 = _2743 / (float3(1.0) + _2743);
    }
    else
    {
        _6954 = _2743;
    }
    out.m_2755 = float4(_6954, in.m_1849.w);
    float2 _7031;
    do
    {
        if (in.m_2765.w <= 0.0)
        {
            _7031 = float2(0.0);
            break;
        }
        _7031 = ((in.m_2765.xy / float2(in.m_2765.w)) - (in.m_2764.xy / float2(in.m_2764.w))) * float2(0.5, -0.5);
        break;
    } while(false);
    out.m_2763 = _7031;
    return out;
}

