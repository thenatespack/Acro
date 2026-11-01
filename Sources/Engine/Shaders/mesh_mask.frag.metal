// Generated from mesh_mask.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 73521c4c2be7f487
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
    float4 m_2582 [[color(0)]];
    float2 m_2590 [[color(1)]];
};

struct fragment_main_in
{
    float3 m_1451 [[user(locn0)]];
    float3 m_1906 [[user(locn1)]];
    float2 m_1826 [[user(locn2)]];
    float4 m_1849 [[user(locn3)]];
    float4 m_2054 [[user(locn5)]];
    float4 m_2591 [[user(locn6)]];
    float4 m_2592 [[user(locn7)]];
    float4 m_1915 [[user(locn8)]];
};

fragment fragment_main_out fragment_main(fragment_main_in in [[stage_in]], constant _1819& _1821 [[buffer(2)]], constant _1441& _1443 [[buffer(3)]], constant _1477& _1479 [[buffer(4)]], constant _1485& _1487 [[buffer(5)]], constant _1582& _1584 [[buffer(6)]], constant _1604& _1606 [[buffer(7)]], constant _178& _180 [[buffer(15)]], texture2d<float> _200 [[texture(0)]], texture2d<float> _1842 [[texture(1)]], texture2d<float> _2247 [[texture(2)]], texture2d<float> _1944 [[texture(3)]], texture2d<float> _1770 [[texture(4)]], texture2d<float> _2538 [[texture(5)]], texture2d<float> _1215 [[texture(6)]], texture2d<float> _1321 [[texture(7)]], sampler _200Smplr [[sampler(0)]], sampler _1217 [[sampler(1)]], sampler _1323 [[sampler(7)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])
{
    fragment_main_out out = {};
    float2 _1840 = float2(dot(_1821._m2.xy, in.m_1826) + _1821._m2.z, dot(_1821._m3.xy, in.m_1826) + _1821._m3.z);
    float4 _1847 = _1842.sample(_1217, _1840);
    float3 _1858 = (in.m_1849.xyz * _1821._m0.xyz) * _1847.xyz;
    if ((_1821._m0.w * _1847.w) < _1821._m6.x)
    {
        discard_fragment();
    }
    float3 _6434;
    if (_1821._m1.x > 0.5)
    {
        float2 _1892 = floor(in.m_1451.xz * float2(0.5));
        _6434 = _1858 * ((mod(abs(_1892.x + _1892.y), 2.0) < 0.5) ? 1.0 : 0.75);
    }
    else
    {
        _6434 = _1858;
    }
    float3 _1908 = fast::normalize(in.m_1906);
    float3 _6348;
    if (_1821._m6.y > 0.5)
    {
        float3 _1924 = in.m_1915.xyz - (_1908 * dot(_1908, in.m_1915.xyz));
        float3 _6349;
        if (dot(_1924, _1924) > 9.9999999600419720025001879548654e-13)
        {
            float3 _1933 = fast::normalize(_1924);
            float4 _1949 = _1944.sample(_1217, _1840);
            float3 _6342;
            if (_1821._m6.z > 0.5)
            {
                float2 _6341;
                if (_1821._m6.z > 1.5)
                {
                    _6341 = _1949.xw;
                }
                else
                {
                    _6341 = _1949.xy;
                }
                float2 _1971 = (_6341 * 2.0) - float2(1.0);
                _6342 = float3(_1971, sqrt(fast::clamp(1.0 - dot(_1971, _1971), 0.0, 1.0)));
            }
            else
            {
                _6342 = (_1949.xyz * 2.0) - float3(1.0);
            }
            float2 _1993 = _6342.xy * _1821._m4.z;
            _6349 = fast::normalize(((_1933 * _1993.x) + ((cross(_1908, _1933) * ((in.m_1915.w < 0.0) ? (-1.0) : 1.0)) * _1993.y)) + (_1908 * _6342.z));
        }
        else
        {
            _6349 = _1908;
        }
        _6348 = _6349;
    }
    else
    {
        _6348 = _1908;
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
    float3 _6462;
    if (_2025)
    {
        _6462 = -_6348;
    }
    else
    {
        _6462 = _6348;
    }
    float3 _2034 = fast::normalize(_180._m4.xyz);
    float3 _2040 = _180._m6.xyz - in.m_1451;
    float3 _2041 = fast::normalize(_2040);
    float3 _2046 = fast::normalize(_2034 + _2041);
    float3 _2052 = _1908 * (gl_FrontFacing ? 1.0 : (-1.0));
    bool _2057 = in.m_2054.x > 0.5;
    float3 _6459;
    float _6486;
    if ((_180._m5.w > 0.5) && _2057)
    {
        float _6405;
        float3 _6406;
        do
        {
            int _2650 = int(_180._m21.x);
            float _2658 = dot(_180._m20.xyz, in.m_1451) + _180._m20.w;
            int _6350;
            _6350 = 0;
            for (;;)
            {
                bool _2664 = _6350 < (_2650 - 1);
                bool _2672;
                if (_2664)
                {
                    _2672 = _2658 > _180._m16[_6350];
                }
                else
                {
                    _2672 = _2664;
                }
                if (_2672)
                {
                    _6350++;
                    continue;
                }
                else
                {
                    break;
                }
            }
            if (_2658 > _180._m16[_6350])
            {
                _6406 = float3(1.0);
                _6405 = 1.0;
                break;
            }
            float _6363;
            do
            {
                float4 _2774 = _180._m14[_6350] * float4(in.m_1451 + (_2052 * _180._m18[_6350]), 1.0);
                float _2777 = _2774.x;
                bool _2778 = _2777 < 0.0;
                bool _2785;
                if (!_2778)
                {
                    _2785 = _2777 > 1.0;
                }
                else
                {
                    _2785 = _2778;
                }
                bool _2792;
                if (!_2785)
                {
                    _2792 = _2774.y < 0.0;
                }
                else
                {
                    _2792 = _2785;
                }
                bool _2799;
                if (!_2792)
                {
                    _2799 = _2774.y > 1.0;
                }
                else
                {
                    _2799 = _2792;
                }
                if (_2799)
                {
                    _6363 = 1.0;
                    break;
                }
                float2 _2812 = float2(float(_6350 & 1), float(_6350 >> 1)) * _180._m23.xy;
                float _2819 = fast::min(_2774.z, 1.0) - _180._m19[_6350];
                float2 _2838 = _180._m22.xy * 0.5;
                float2 _2843 = _2812 + (_2774.xy * _180._m23.xy);
                float4 _2856 = float4(_2812 + _2838, (_2812 + _180._m23.xy) - _2838);
                float _6362;
                do
                {
                    int _2882 = int(_180._m22.z);
                    if (_2882 <= 0)
                    {
                        _6362 = spvDepthCast(_200).sample_compare(_200Smplr, float3(fast::clamp(_2843, _2856.xy, _2856.zw), _2819).xy, _2819);
                        break;
                    }
                    float2 _2905 = (_2843 / _180._m22.xy) + float2(0.5);
                    float2 _2906 = floor(_2905);
                    float2 _2911 = _2905 - _2906;
                    float2 _2914 = _2906 - float2(0.5);
                    bool _2918 = _2882 == 1;
                    spvUnsafeArray<float2, 3> _2866;
                    spvUnsafeArray<float2, 3> _2867;
                    if (_2918)
                    {
                        float2 _2921 = _2911 * 2.0;
                        _2866[0] = float2(3.0) - _2921;
                        _2866[1] = float2(1.0) + _2921;
                        _2867[0] = ((float2(2.0) - _2911) / _2866[0]) - float2(1.0);
                        _2867[1] = (_2911 / _2866[1]) + float2(1.0);
                    }
                    else
                    {
                        float2 _2948 = _2911 * 3.0;
                        _2866[0] = float2(4.0) - _2948;
                        _2866[1] = float2(7.0);
                        _2866[2] = float2(1.0) + _2948;
                        _2867[0] = ((float2(3.0) - (_2911 * 2.0)) / _2866[0]) - float2(2.0);
                        _2867[1] = (float2(3.0) + _2911) / _2866[1];
                        _2867[2] = (_2911 / _2866[2]) + float2(2.0);
                    }
                    int _6920 = _2918 ? 2 : 3;
                    int _6352;
                    float _6355;
                    _6355 = 0.0;
                    _6352 = 0;
                    float _6361;
                    for (; _6352 < _6920; _6355 = _6361, _6352++)
                    {
                        _6361 = _6355;
                        for (int _6358 = 0; _6358 < _6920; )
                        {
                            _6361 += ((_2866[_6358].x * _2866[_6352].y) * spvDepthCast(_200).sample_compare(_200Smplr, float3(fast::clamp(_180._m22.xy * (_2914 + float2(_2867[_6358].x, _2867[_6352].y)), _2856.xy, _2856.zw), _2819).xy, _2819));
                            _6358++;
                            continue;
                        }
                    }
                    _6362 = _6355 * (_2918 ? 0.0625 : 0.0069444444961845874786376953125);
                    break;
                } while(false);
                _6363 = _6362;
                break;
            } while(false);
            float3 _6400;
            float _6403;
            if (_2658 > _180._m17[_6350])
            {
                float _2712 = (_2658 - _180._m17[_6350]) / (_180._m16[_6350] - _180._m17[_6350]);
                int _2714 = _6350 + 1;
                float3 _6401;
                float _6404;
                if (_2714 < _2650)
                {
                    float _6383;
                    do
                    {
                        float4 _3061 = _180._m14[_2714] * float4(in.m_1451 + (_2052 * _180._m18[_2714]), 1.0);
                        float _3064 = _3061.x;
                        bool _3065 = _3064 < 0.0;
                        bool _3072;
                        if (!_3065)
                        {
                            _3072 = _3064 > 1.0;
                        }
                        else
                        {
                            _3072 = _3065;
                        }
                        bool _3079;
                        if (!_3072)
                        {
                            _3079 = _3061.y < 0.0;
                        }
                        else
                        {
                            _3079 = _3072;
                        }
                        bool _3086;
                        if (!_3079)
                        {
                            _3086 = _3061.y > 1.0;
                        }
                        else
                        {
                            _3086 = _3079;
                        }
                        if (_3086)
                        {
                            _6383 = 1.0;
                            break;
                        }
                        float2 _3099 = float2(float(_2714 & 1), float(_2714 >> 1)) * _180._m23.xy;
                        float _3106 = fast::min(_3061.z, 1.0) - _180._m19[_2714];
                        float2 _3125 = _180._m22.xy * 0.5;
                        float2 _3130 = _3099 + (_3061.xy * _180._m23.xy);
                        float4 _3143 = float4(_3099 + _3125, (_3099 + _180._m23.xy) - _3125);
                        float _6382;
                        do
                        {
                            int _3169 = int(_180._m22.z);
                            if (_3169 <= 0)
                            {
                                _6382 = spvDepthCast(_200).sample_compare(_200Smplr, float3(fast::clamp(_3130, _3143.xy, _3143.zw), _3106).xy, _3106);
                                break;
                            }
                            float2 _3192 = (_3130 / _180._m22.xy) + float2(0.5);
                            float2 _3193 = floor(_3192);
                            float2 _3198 = _3192 - _3193;
                            float2 _3201 = _3193 - float2(0.5);
                            bool _3205 = _3169 == 1;
                            spvUnsafeArray<float2, 3> _3153;
                            spvUnsafeArray<float2, 3> _3154;
                            if (_3205)
                            {
                                float2 _3208 = _3198 * 2.0;
                                _3153[0] = float2(3.0) - _3208;
                                _3153[1] = float2(1.0) + _3208;
                                _3154[0] = ((float2(2.0) - _3198) / _3153[0]) - float2(1.0);
                                _3154[1] = (_3198 / _3153[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _3235 = _3198 * 3.0;
                                _3153[0] = float2(4.0) - _3235;
                                _3153[1] = float2(7.0);
                                _3153[2] = float2(1.0) + _3235;
                                _3154[0] = ((float2(3.0) - (_3198 * 2.0)) / _3153[0]) - float2(2.0);
                                _3154[1] = (float2(3.0) + _3198) / _3153[1];
                                _3154[2] = (_3198 / _3153[2]) + float2(2.0);
                            }
                            int _6922 = _3205 ? 2 : 3;
                            int _6372;
                            float _6375;
                            _6375 = 0.0;
                            _6372 = 0;
                            float _6381;
                            for (; _6372 < _6922; _6375 = _6381, _6372++)
                            {
                                _6381 = _6375;
                                for (int _6378 = 0; _6378 < _6922; )
                                {
                                    _6381 += ((_3153[_6378].x * _3153[_6372].y) * spvDepthCast(_200).sample_compare(_200Smplr, float3(fast::clamp(_180._m22.xy * (_3201 + float2(_3154[_6378].x, _3154[_6372].y)), _3143.xy, _3143.zw), _3106).xy, _3106));
                                    _6378++;
                                    continue;
                                }
                            }
                            _6382 = _6375 * (_3205 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _6383 = _6382;
                        break;
                    } while(false);
                    _6404 = mix(_6363, _6383, _2712);
                    _6401 = mix(_554[_6350], _554[_2714], float3(_2712));
                }
                else
                {
                    _6404 = mix(_6363, 1.0, _2712);
                    _6401 = _554[_6350];
                }
                _6403 = _6404;
                _6400 = _6401;
            }
            else
            {
                _6403 = _6363;
                _6400 = _554[_6350];
            }
            _6406 = select(float3(1.0), _6400, bool3(_180._m22.w > 0.5));
            _6405 = _6403;
            break;
        } while(false);
        _6486 = _6405;
        _6459 = _6434 * _6406;
    }
    else
    {
        _6486 = 1.0;
        _6459 = _6434;
    }
    float3 _2083 = _180._m5.xyz * _180._m4.w;
    bool _2087 = _1821._m6.w > 0.5;
    float _6457;
    if (_2087)
    {
        _6457 = 1.0;
    }
    else
    {
        _6457 = 1.0 + (_1821._m4.w * (_1770.sample(_1217, _1840).x - 1.0));
    }
    float3 _6651;
    if (!_2017)
    {
        float _2111 = dot(_6462, _2034);
        float3 _6645;
        if (_180._m29.x > 0.5)
        {
            float _3386 = (_180._m29.z * _6462.x) - (_180._m29.w * _6462.z);
            float _3399 = (_180._m29.w * _6462.x) + (_180._m29.z * _6462.z);
            float _3417 = 1.09254801273345947265625 * _3386;
            spvUnsafeArray<float, 9> _6149 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _6462.y, 0.48860299587249755859375 * _3399, 0.48860299587249755859375 * _3386, _3417 * _6462.y, (1.09254801273345947265625 * _6462.y) * _3399, 0.3153919875621795654296875 * (((3.0 * _3399) * _3399) - 1.0), _3417 * _3399, 0.546274006366729736328125 * ((_3386 * _3386) - (_6462.y * _6462.y)) });
            spvUnsafeArray<float, 9> _3331 = _6149;
            float3 _6644;
            _6644 = float3(0.0);
            for (int _6643 = 0; _6643 < 9; )
            {
                _6644 += (_1215.read(uint2((int2(496, 256) + int2(_6643, 0))), 0).xyz * _3331[_6643]);
                _6643++;
                continue;
            }
            _6645 = fast::max(_6644, float3(0.0)) * _180._m29.y;
        }
        else
        {
            _6645 = mix(_180._m9.xyz, _180._m8.xyz, float3((_6462.y * 0.5) + 0.5)) * _180._m8.w;
        }
        float3 _2161 = (_6459 * ((_6645 * _6457) + ((_2083 * fast::max(_2111, 0.0)) * _6486))) + ((_2083 * ((powr(fast::max(dot(_6462, _2046), 0.0), _1821._m1.w) * _1821._m1.z) * step(0.0, _2111))) * _6486);
        float3 _6652;
        if (_180._m13.w > 0.5)
        {
            float2 _3502 = fast::clamp(floor(gl_FragCoord.xy * _180._m12.xy), float2(0.0), _180._m13.xy - float2(1.0));
            uint _3530 = uint((((fast::clamp(floor((log2(fast::max(dot(_180._m11.xyz, in.m_1451) + _180._m11.w, 9.9999999747524270787835121154785e-07)) * _180._m12.z) + _180._m12.w), 0.0, _180._m13.z - 1.0) * _180._m13.y) + _3502.y) * _180._m13.x) + _3502.x);
            uint _3532 = _3530 >> uint(2);
            uint _3534 = _3530 & 3u;
            uint _3538 = _1584._m0[_3532][_3534] & 65535u;
            uint _3540 = _1584._m0[_3532][_3534] >> uint(16);
            float3 _6653;
            _6653 = _2161;
            float3 _2242;
            spvUnsafeArray<float2, 3> _3948;
            spvUnsafeArray<float2, 3> _3949;
            spvUnsafeArray<float2, 3> _4161;
            spvUnsafeArray<float2, 3> _4162;
            for (uint _6650 = _3538; _6650 < (_3538 + _3540); _6653 = _2242, _6650++)
            {
                uint _3546 = _6650 / 3u;
                uint _3559 = (_1606._m0[_3546 >> uint(2)][_3546 & 3u] >> ((_6650 - (_3546 * 3u)) * 10u)) & 1023u;
                float3 _3576 = _1443._m0[_3559].xyz - in.m_1451;
                float _3579 = dot(_3576, _3576);
                float _3583 = _3579 * _1443._m0[_3559].w;
                float _3588 = fast::clamp(1.0 - (_3583 * _3583), 0.0, 1.0);
                float3 _3593 = _3576 * rsqrt(fast::max(_3579, 9.9999999392252902907785028219223e-09));
                float _3611 = fast::clamp((dot(-_3593, _1487._m0[_3559].xyz) * _1479._m0[_3559].w) + _1487._m0[_3559].w, 0.0, 1.0);
                float3 _3624 = _1479._m0[_3559].xyz * ((((_3588 * _3588) * _3611) * _3611) / fast::max(_3579, 9.9999997473787516355514526367188e-05));
                float3 _6839;
                if (_2057)
                {
                    float _6785;
                    do
                    {
                        uint _3660 = uint(_180._m21.z);
                        if (_3559 < _3660)
                        {
                            float _3682 = _180._m26[_3559].z * fast::max((_180._m15[_3559] * float4(in.m_1451, 1.0)).w, 0.0);
                            float4 _3706 = _180._m15[_3559] * float4((in.m_1451 + (_2052 * (_3682 * _180._m25.x))) + (_3593 * (_3682 * _180._m25.y)), 1.0);
                            float _3708 = _3706.w;
                            if (_3708 <= 0.0)
                            {
                                _6785 = 1.0;
                                break;
                            }
                            float3 _3717 = _3706.xyz / float3(_3708);
                            float _3719 = _3717.x;
                            bool _3720 = _3719 < 0.0;
                            bool _3727;
                            if (!_3720)
                            {
                                _3727 = _3719 > 1.0;
                            }
                            else
                            {
                                _3727 = _3720;
                            }
                            bool _3734;
                            if (!_3727)
                            {
                                _3734 = _3717.y < 0.0;
                            }
                            else
                            {
                                _3734 = _3727;
                            }
                            bool _3741;
                            if (!_3734)
                            {
                                _3741 = _3717.y > 1.0;
                            }
                            else
                            {
                                _3741 = _3734;
                            }
                            bool _3748;
                            if (!_3741)
                            {
                                _3748 = _3717.z > 1.0;
                            }
                            else
                            {
                                _3748 = _3741;
                            }
                            if (_3748)
                            {
                                _6785 = 1.0;
                                break;
                            }
                            float _3754 = _3717.z;
                            float2 _3920 = _180._m22.xy * 0.5;
                            float2 _3925 = _180._m26[_3559].xy + (_3717.xy * _180._m23.zw);
                            float4 _3938 = float4(_180._m26[_3559].xy + _3920, (_180._m26[_3559].xy + _180._m23.zw) - _3920);
                            float _6784;
                            do
                            {
                                int _3964 = int(_180._m22.z);
                                if (_3964 <= 0)
                                {
                                    float2 _3974 = fast::clamp(_3925, _3938.xy, _3938.zw);
                                    _6784 = spvDepthCast(_200).sample_compare(_200Smplr, float3(_3974, _3754).xy, _3754);
                                    break;
                                }
                                float2 _3987 = (_3925 / _180._m22.xy) + float2(0.5);
                                float2 _3988 = floor(_3987);
                                float2 _3993 = _3987 - _3988;
                                float2 _3996 = _3988 - float2(0.5);
                                bool _4000 = _3964 == 1;
                                if (_4000)
                                {
                                    float2 _4003 = _3993 * 2.0;
                                    _3948[0] = float2(3.0) - _4003;
                                    _3948[1] = float2(1.0) + _4003;
                                    _3949[0] = ((float2(2.0) - _3993) / _3948[0]) - float2(1.0);
                                    _3949[1] = (_3993 / _3948[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _4030 = _3993 * 3.0;
                                    _3948[0] = float2(4.0) - _4030;
                                    _3948[1] = float2(7.0);
                                    _3948[2] = float2(1.0) + _4030;
                                    _3949[0] = ((float2(3.0) - (_3993 * 2.0)) / _3948[0]) - float2(2.0);
                                    _3949[1] = (float2(3.0) + _3993) / _3948[1];
                                    _3949[2] = (_3993 / _3948[2]) + float2(2.0);
                                }
                                int _6927 = _4000 ? 2 : 3;
                                int _6774;
                                float _6777;
                                _6777 = 0.0;
                                _6774 = 0;
                                float _6783;
                                for (; _6774 < _6927; _6777 = _6783, _6774++)
                                {
                                    _6783 = _6777;
                                    for (int _6780 = 0; _6780 < _6927; )
                                    {
                                        _6783 += ((_3948[_6780].x * _3948[_6774].y) * spvDepthCast(_200).sample_compare(_200Smplr, float3(fast::clamp(_180._m22.xy * (_3996 + float2(_3949[_6780].x, _3949[_6774].y)), _3938.xy, _3938.zw), _3754).xy, _3754));
                                        _6780++;
                                        continue;
                                    }
                                }
                                _6784 = _6777 * (_4000 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _6785 = _6784;
                            break;
                        }
                        uint _3764 = _3559 - _3660;
                        if (_3764 >= uint(_180._m21.w))
                        {
                            _6785 = 1.0;
                            break;
                        }
                        float _3785 = _180._m27[_3764].w * length(in.m_1451 - _180._m27[_3764].xyz);
                        float3 _3803 = ((in.m_1451 + (_2052 * (_3785 * _180._m25.x))) + (_3593 * (_3785 * _180._m25.y))) - _180._m27[_3764].xyz;
                        float3 _3805 = abs(_3803);
                        float _3807 = _3805.x;
                        float _3809 = _3805.y;
                        bool _3810 = _3807 >= _3809;
                        bool _3818;
                        if (_3810)
                        {
                            _3818 = _3807 >= _3805.z;
                        }
                        else
                        {
                            _3818 = _3810;
                        }
                        float _6759;
                        int _6761;
                        if (_3818)
                        {
                            _6761 = (_3803.x > 0.0) ? 0 : 1;
                            _6759 = _3807;
                        }
                        else
                        {
                            float _3830 = _3805.z;
                            bool _3831 = _3809 >= _3830;
                            int _6762;
                            if (_3831)
                            {
                                _6762 = (_3803.y > 0.0) ? 2 : 3;
                            }
                            else
                            {
                                _6762 = (_3803.z > 0.0) ? 4 : 5;
                            }
                            _6761 = _6762;
                            _6759 = _3831 ? _3809 : _3830;
                        }
                        if (_6759 <= 0.0)
                        {
                            _6785 = 1.0;
                            break;
                        }
                        float2 _3868 = float2(dot(_3803, _858[_6761]), dot(_3803, _867[_6761])) / float2(_6759 * _180._m24.z);
                        float _3875 = _180._m28[_3764].z + (_180._m28[_3764].w / _6759);
                        if (_3875 > 1.0)
                        {
                            _6785 = 1.0;
                            break;
                        }
                        float2 _3893 = _180._m28[_3764].xy + (float2(float(spvSMod(_6761, 3)), float(_6761 / 3)) * _180._m24.xy);
                        float2 _4133 = _180._m22.xy * 0.5;
                        float2 _4138 = _3893 + (float2(0.5 + (0.5 * _3868.x), 0.5 - (0.5 * _3868.y)) * _180._m24.xy);
                        float4 _4151 = float4(_3893 + _4133, (_3893 + _180._m24.xy) - _4133);
                        float _6773;
                        do
                        {
                            int _4177 = int(_180._m22.z);
                            if (_4177 <= 0)
                            {
                                _6773 = spvDepthCast(_200).sample_compare(_200Smplr, float3(fast::clamp(_4138, _4151.xy, _4151.zw), _3875).xy, _3875);
                                break;
                            }
                            float2 _4200 = (_4138 / _180._m22.xy) + float2(0.5);
                            float2 _4201 = floor(_4200);
                            float2 _4206 = _4200 - _4201;
                            float2 _4209 = _4201 - float2(0.5);
                            bool _4213 = _4177 == 1;
                            if (_4213)
                            {
                                float2 _4216 = _4206 * 2.0;
                                _4161[0] = float2(3.0) - _4216;
                                _4161[1] = float2(1.0) + _4216;
                                _4162[0] = ((float2(2.0) - _4206) / _4161[0]) - float2(1.0);
                                _4162[1] = (_4206 / _4161[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _4243 = _4206 * 3.0;
                                _4161[0] = float2(4.0) - _4243;
                                _4161[1] = float2(7.0);
                                _4161[2] = float2(1.0) + _4243;
                                _4162[0] = ((float2(3.0) - (_4206 * 2.0)) / _4161[0]) - float2(2.0);
                                _4162[1] = (float2(3.0) + _4206) / _4161[1];
                                _4162[2] = (_4206 / _4161[2]) + float2(2.0);
                            }
                            int _6930 = _4213 ? 2 : 3;
                            int _6763;
                            float _6766;
                            _6766 = 0.0;
                            _6763 = 0;
                            float _6772;
                            for (; _6763 < _6930; _6766 = _6772, _6763++)
                            {
                                _6772 = _6766;
                                for (int _6769 = 0; _6769 < _6930; )
                                {
                                    _6772 += ((_4161[_6769].x * _4161[_6763].y) * spvDepthCast(_200).sample_compare(_200Smplr, float3(fast::clamp(_180._m22.xy * (_4209 + float2(_4162[_6769].x, _4162[_6763].y)), _4151.xy, _4151.zw), _3875).xy, _3875));
                                    _6769++;
                                    continue;
                                }
                            }
                            _6773 = _6766 * (_4213 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _6785 = _6773;
                        break;
                    } while(false);
                    _6839 = _3624 * _6785;
                }
                else
                {
                    _6839 = _3624;
                }
                float _2213 = dot(_6462, _3593);
                _2242 = _6653 + (((_6459 * fast::max(_2213, 0.0)) * _6839) + (_6839 * ((powr(fast::max(dot(_6462, fast::normalize(_3593 + _2041)), 0.0), _1821._m1.w) * _1821._m1.z) * step(0.0, _2213))));
            }
            _6652 = _6653;
        }
        else
        {
            _6652 = _2161;
        }
        _6651 = _6652;
    }
    else
    {
        float4 _2252 = _2247.sample(_1217, _1840);
        float _2259 = fast::clamp(_1821._m4.x * _2252.z, 0.0, 1.0);
        float _2267 = fast::clamp(_1821._m4.y * _2252.y, 0.04500000178813934326171875, 1.0);
        float _2271 = _2267 * _2267;
        float3 _2276 = _6459 * (1.0 - _2259);
        float3 _2282 = mix(float3(0.039999999105930328369140625), _6459, float3(_2259));
        float _2287 = fast::max(dot(_6462, _2041), 9.9999997473787516355514526367188e-05);
        float _2292 = fast::clamp(dot(_6462, _2034), 0.0, 1.0);
        float _2297 = fast::clamp(dot(_6462, _2046), 0.0, 1.0);
        float3 _4345 = float3(1.0) - _2282;
        float3 _4348 = _2282 + (_4345 * powr(1.0 - fast::clamp(dot(_2041, _2046), 0.0, 1.0), 5.0));
        float _4355 = _2271 * _2271;
        float _4360 = _4355 - 1.0;
        float _4362 = ((_2297 * _2297) * _4360) + 1.0;
        float _4382 = 1.0 - _4355;
        float _4386 = sqrt(((_2287 * _2287) * _4382) + _4355);
        float3 _6505;
        float2 _6520;
        float3 _6532;
        if (_180._m29.x > 0.5)
        {
            float4 _4419 = _1321.sample(_1323, (((float2(_2287, _2267) * 31.0) + float2(0.5)) * float2(0.03125)));
            float _4478 = (_180._m29.z * _6462.x) - (_180._m29.w * _6462.z);
            float _4491 = (_180._m29.w * _6462.x) + (_180._m29.z * _6462.z);
            float _4509 = 1.09254801273345947265625 * _4478;
            spvUnsafeArray<float, 9> _6130 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _6462.y, 0.48860299587249755859375 * _4491, 0.48860299587249755859375 * _4478, _4509 * _6462.y, (1.09254801273345947265625 * _6462.y) * _4491, 0.3153919875621795654296875 * (((3.0 * _4491) * _4491) - 1.0), _4509 * _4491, 0.546274006366729736328125 * ((_4478 * _4478) - (_6462.y * _6462.y)) });
            spvUnsafeArray<float, 9> _4423 = _6130;
            float3 _6488;
            _6488 = float3(0.0);
            for (int _6487 = 0; _6487 < 9; )
            {
                _6488 += (_1215.read(uint2((int2(496, 256) + int2(_6487, 0))), 0).xyz * _4423[_6487]);
                _6487++;
                continue;
            }
            float3 _2358 = reflect(-_2041, _6462);
            float _4604 = _2358.x;
            float _4609 = _2358.z;
            float2 _4641 = float2((precise::atan2((_180._m29.z * _4604) - (_180._m29.w * _4609), -((_180._m29.w * _4604) + (_180._m29.z * _4609))) * 0.15915493667125701904296875) + 0.5, acos(fast::clamp(_2358.y, -1.0, 1.0)) * 0.3183098733425140380859375);
            float _4573 = _2267 * 5.0;
            int _4576 = min(int(_4573), 4);
            float2 _4662 = (_4641 * float2(_1277[_4576].zw)) - float2(0.5);
            float2 _4664 = floor(_4662);
            float2 _4667 = _4662 - _4664;
            int _4670 = int(_4664.x);
            int _4673 = int(_4664.y);
            int _6490;
            if (_4670 < 0)
            {
                _6490 = _4670 + _1277[_4576].z;
            }
            else
            {
                _6490 = _4670;
            }
            int _6491;
            if (_6490 >= _1277[_4576].z)
            {
                _6491 = _6490 - _1277[_4576].z;
            }
            else
            {
                _6491 = _6490;
            }
            int _4693 = _6491 + 1;
            int _6931 = (_4693 == _1277[_4576].z) ? 0 : _4693;
            int _4708 = min((_4673 + 1), (_1277[_4576].w - 1));
            int _4710 = max(_4673, 0);
            float3 _4763 = float3(_4667.x);
            int _4583 = _4576 + 1;
            float2 _4795 = (_4641 * float2(_1277[_4583].zw)) - float2(0.5);
            float2 _4797 = floor(_4795);
            float2 _4800 = _4795 - _4797;
            int _4803 = int(_4797.x);
            int _4806 = int(_4797.y);
            int _6497;
            if (_4803 < 0)
            {
                _6497 = _4803 + _1277[_4583].z;
            }
            else
            {
                _6497 = _4803;
            }
            int _6498;
            if (_6497 >= _1277[_4583].z)
            {
                _6498 = _6497 - _1277[_4583].z;
            }
            else
            {
                _6498 = _6497;
            }
            int _4826 = _6498 + 1;
            int _6932 = (_4826 == _1277[_4583].z) ? 0 : _4826;
            int _4841 = min((_4806 + 1), (_1277[_4583].w - 1));
            int _4843 = max(_4806, 0);
            float3 _4896 = float3(_4800.x);
            float3 _4598 = mix(mix(mix(_1215.read(uint2((_1277[_4576].xy + int2(_6491, _4710))), 0).xyz, _1215.read(uint2((_1277[_4576].xy + int2(_6931, _4710))), 0).xyz, _4763), mix(_1215.read(uint2((_1277[_4576].xy + int2(_6491, _4708))), 0).xyz, _1215.read(uint2((_1277[_4576].xy + int2(_6931, _4708))), 0).xyz, _4763), float3(_4667.y)), mix(mix(_1215.read(uint2((_1277[_4583].xy + int2(_6498, _4843))), 0).xyz, _1215.read(uint2((_1277[_4583].xy + int2(_6932, _4843))), 0).xyz, _4896), mix(_1215.read(uint2((_1277[_4583].xy + int2(_6498, _4841))), 0).xyz, _1215.read(uint2((_1277[_4583].xy + int2(_6932, _4841))), 0).xyz, _4896), float3(_4800.y)), float3(_4573 - float(_4576))) * _180._m29.y;
            _6532 = fast::max(_6488, float3(0.0)) * _180._m29.y;
            _6520 = _4419.xy;
            _6505 = _4598;
        }
        else
        {
            float4 _4914 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * _2267) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);
            float _4916 = _4914.x;
            float3 _4951 = mix(_180._m9.xyz, _180._m8.xyz, float3((_6462.y * 0.5) + 0.5)) * _180._m8.w;
            _6532 = _4951;
            _6520 = (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_4916 * _4916, exp2((-9.27999973297119140625) * _2287)) * _4916) + _4914.y)) + _4914.zw;
            _6505 = mix(mix(_180._m9.xyz, _180._m8.xyz, float3((reflect(-_2041, _6462).y * 0.5) + 0.5)) * _180._m8.w, _4951, float3(_2267));
        }
        bool _2390;
        if (_2087)
        {
            _2390 = _180._m33.z > 0.5;
        }
        else
        {
            _2390 = _2087;
        }
        float3 _6541;
        if (_2390)
        {
            float3 _6517;
            do
            {
                float _5030 = ((_180._m32.x * (1.0 - smoothstep(_180._m33.x * 0.5, _180._m33.x, abs(dot(_180._m31.xyz, in.m_1451) - _180._m31.w)))) * smoothstep(0.5, 0.89999997615814208984375, dot(_2052, _180._m31.xyz))) * (1.0 - smoothstep(_180._m32.y * 0.5, _180._m32.y, _2267));
                if (_5030 <= 0.0)
                {
                    _6517 = _6505;
                    break;
                }
                float4 _5055 = _180._m30 * float4(in.m_1451 + ((_6462 - (_180._m31.xyz * dot(_6462, _180._m31.xyz))) * _180._m32.w), 1.0);
                float2 _5068 = ((float2(_5055.x, -_5055.y) / float2(_5055.w)) * 0.5) + float2(0.5);
                float _5072 = _180._m32.z * _2267;
                float3 _6515;
                float _6516;
                _6516 = 0.0;
                _6515 = float3(0.0);
                for (int _6514 = 0; _6514 < 12; )
                {
                    float _5079 = float(_6514);
                    float _5087 = _5079 * 2.3999631404876708984375;
                    float2 _5099 = _5068 + (float2(cos(_5087) * _180._m33.y, sin(_5087)) * (sqrt((_5079 + 0.5) * 0.083333335816860198974609375) * _5072));
                    float2 _5104 = fast::min(_5099, float2(1.0) - _5099);
                    float _5110 = smoothstep(0.0, 0.039999999105930328369140625, fast::min(_5104.x, _5104.y));
                    float4 _5118 = _1770.sample(_1217, fast::clamp(_5099, float2(0.0), float2(1.0)), level(0.0));
                    float3 _5120 = _5118.xyz;
                    _6516 += (_5118.w * _5110);
                    _6515 += ((_5120 / (float3(1.0) - fast::min(_5120, float3(0.99500000476837158203125)))) * _5110);
                    _6514++;
                    continue;
                }
                _6517 = mix(_6505, (_6515 * float3(0.083333335816860198974609375)) + (_6505 * (1.0 - (_6516 * 0.083333335816860198974609375))), float3(_5030));
                break;
            } while(false);
            _6541 = _6517;
        }
        else
        {
            _6541 = _6505;
        }
        float3 _2410 = (_2282 * _6520.x) + float3(_6520.y);
        float3 _2426 = ((((((float3(1.0) - _4348) * _2276) + ((_4348 * ((_4355 / ((3.1415927410125732421875 * _4362) * _4362)) * (0.5 / fast::max((_2292 * _4386) + (_2287 * sqrt(((_2292 * _2292) * _4382) + _4355)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875)) * _2292) * _2083) * _6486) + (((((float3(1.0) - _2410) * _2276) * _6532) + (_2410 * _6541)) * _6457);
        float3 _6654;
        if (_180._m13.w > 0.5)
        {
            float2 _5184 = fast::clamp(floor(gl_FragCoord.xy * _180._m12.xy), float2(0.0), _180._m13.xy - float2(1.0));
            uint _5212 = uint((((fast::clamp(floor((log2(fast::max(dot(_180._m11.xyz, in.m_1451) + _180._m11.w, 9.9999999747524270787835121154785e-07)) * _180._m12.z) + _180._m12.w), 0.0, _180._m13.z - 1.0) * _180._m13.y) + _5184.y) * _180._m13.x) + _5184.x);
            uint _5214 = _5212 >> uint(2);
            uint _5216 = _5212 & 3u;
            uint _5220 = _1584._m0[_5214][_5216] & 65535u;
            uint _5222 = _1584._m0[_5214][_5216] >> uint(16);
            float3 _6609;
            _6609 = _2426;
            float3 _2526;
            spvUnsafeArray<float2, 3> _5630;
            spvUnsafeArray<float2, 3> _5631;
            spvUnsafeArray<float2, 3> _5843;
            spvUnsafeArray<float2, 3> _5844;
            for (uint _6542 = _5220; _6542 < (_5220 + _5222); _6609 = _2526, _6542++)
            {
                uint _5228 = _6542 / 3u;
                uint _5241 = (_1606._m0[_5228 >> uint(2)][_5228 & 3u] >> ((_6542 - (_5228 * 3u)) * 10u)) & 1023u;
                float3 _5258 = _1443._m0[_5241].xyz - in.m_1451;
                float _5261 = dot(_5258, _5258);
                float _5265 = _5261 * _1443._m0[_5241].w;
                float _5270 = fast::clamp(1.0 - (_5265 * _5265), 0.0, 1.0);
                float3 _5275 = _5258 * rsqrt(fast::max(_5261, 9.9999999392252902907785028219223e-09));
                float _5293 = fast::clamp((dot(-_5275, _1487._m0[_5241].xyz) * _1479._m0[_5241].w) + _1487._m0[_5241].w, 0.0, 1.0);
                float3 _5306 = _1479._m0[_5241].xyz * ((((_5270 * _5270) * _5293) * _5293) / fast::max(_5261, 9.9999997473787516355514526367188e-05));
                float3 _6607;
                if (_2057)
                {
                    float _6569;
                    do
                    {
                        uint _5342 = uint(_180._m21.z);
                        if (_5241 < _5342)
                        {
                            float _5364 = _180._m26[_5241].z * fast::max((_180._m15[_5241] * float4(in.m_1451, 1.0)).w, 0.0);
                            float4 _5388 = _180._m15[_5241] * float4((in.m_1451 + (_2052 * (_5364 * _180._m25.x))) + (_5275 * (_5364 * _180._m25.y)), 1.0);
                            float _5390 = _5388.w;
                            if (_5390 <= 0.0)
                            {
                                _6569 = 1.0;
                                break;
                            }
                            float3 _5399 = _5388.xyz / float3(_5390);
                            float _5401 = _5399.x;
                            bool _5402 = _5401 < 0.0;
                            bool _5409;
                            if (!_5402)
                            {
                                _5409 = _5401 > 1.0;
                            }
                            else
                            {
                                _5409 = _5402;
                            }
                            bool _5416;
                            if (!_5409)
                            {
                                _5416 = _5399.y < 0.0;
                            }
                            else
                            {
                                _5416 = _5409;
                            }
                            bool _5423;
                            if (!_5416)
                            {
                                _5423 = _5399.y > 1.0;
                            }
                            else
                            {
                                _5423 = _5416;
                            }
                            bool _5430;
                            if (!_5423)
                            {
                                _5430 = _5399.z > 1.0;
                            }
                            else
                            {
                                _5430 = _5423;
                            }
                            if (_5430)
                            {
                                _6569 = 1.0;
                                break;
                            }
                            float _5436 = _5399.z;
                            float2 _5602 = _180._m22.xy * 0.5;
                            float2 _5607 = _180._m26[_5241].xy + (_5399.xy * _180._m23.zw);
                            float4 _5620 = float4(_180._m26[_5241].xy + _5602, (_180._m26[_5241].xy + _180._m23.zw) - _5602);
                            float _6568;
                            do
                            {
                                int _5646 = int(_180._m22.z);
                                if (_5646 <= 0)
                                {
                                    float2 _5656 = fast::clamp(_5607, _5620.xy, _5620.zw);
                                    _6568 = spvDepthCast(_200).sample_compare(_200Smplr, float3(_5656, _5436).xy, _5436);
                                    break;
                                }
                                float2 _5669 = (_5607 / _180._m22.xy) + float2(0.5);
                                float2 _5670 = floor(_5669);
                                float2 _5675 = _5669 - _5670;
                                float2 _5678 = _5670 - float2(0.5);
                                bool _5682 = _5646 == 1;
                                if (_5682)
                                {
                                    float2 _5685 = _5675 * 2.0;
                                    _5630[0] = float2(3.0) - _5685;
                                    _5630[1] = float2(1.0) + _5685;
                                    _5631[0] = ((float2(2.0) - _5675) / _5630[0]) - float2(1.0);
                                    _5631[1] = (_5675 / _5630[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _5712 = _5675 * 3.0;
                                    _5630[0] = float2(4.0) - _5712;
                                    _5630[1] = float2(7.0);
                                    _5630[2] = float2(1.0) + _5712;
                                    _5631[0] = ((float2(3.0) - (_5675 * 2.0)) / _5630[0]) - float2(2.0);
                                    _5631[1] = (float2(3.0) + _5675) / _5630[1];
                                    _5631[2] = (_5675 / _5630[2]) + float2(2.0);
                                }
                                int _6934 = _5682 ? 2 : 3;
                                int _6558;
                                float _6561;
                                _6561 = 0.0;
                                _6558 = 0;
                                float _6567;
                                for (; _6558 < _6934; _6561 = _6567, _6558++)
                                {
                                    _6567 = _6561;
                                    for (int _6564 = 0; _6564 < _6934; )
                                    {
                                        _6567 += ((_5630[_6564].x * _5630[_6558].y) * spvDepthCast(_200).sample_compare(_200Smplr, float3(fast::clamp(_180._m22.xy * (_5678 + float2(_5631[_6564].x, _5631[_6558].y)), _5620.xy, _5620.zw), _5436).xy, _5436));
                                        _6564++;
                                        continue;
                                    }
                                }
                                _6568 = _6561 * (_5682 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _6569 = _6568;
                            break;
                        }
                        uint _5446 = _5241 - _5342;
                        if (_5446 >= uint(_180._m21.w))
                        {
                            _6569 = 1.0;
                            break;
                        }
                        float _5467 = _180._m27[_5446].w * length(in.m_1451 - _180._m27[_5446].xyz);
                        float3 _5485 = ((in.m_1451 + (_2052 * (_5467 * _180._m25.x))) + (_5275 * (_5467 * _180._m25.y))) - _180._m27[_5446].xyz;
                        float3 _5487 = abs(_5485);
                        float _5489 = _5487.x;
                        float _5491 = _5487.y;
                        bool _5492 = _5489 >= _5491;
                        bool _5500;
                        if (_5492)
                        {
                            _5500 = _5489 >= _5487.z;
                        }
                        else
                        {
                            _5500 = _5492;
                        }
                        float _6543;
                        int _6545;
                        if (_5500)
                        {
                            _6545 = (_5485.x > 0.0) ? 0 : 1;
                            _6543 = _5489;
                        }
                        else
                        {
                            float _5512 = _5487.z;
                            bool _5513 = _5491 >= _5512;
                            int _6546;
                            if (_5513)
                            {
                                _6546 = (_5485.y > 0.0) ? 2 : 3;
                            }
                            else
                            {
                                _6546 = (_5485.z > 0.0) ? 4 : 5;
                            }
                            _6545 = _6546;
                            _6543 = _5513 ? _5491 : _5512;
                        }
                        if (_6543 <= 0.0)
                        {
                            _6569 = 1.0;
                            break;
                        }
                        float2 _5550 = float2(dot(_5485, _858[_6545]), dot(_5485, _867[_6545])) / float2(_6543 * _180._m24.z);
                        float _5557 = _180._m28[_5446].z + (_180._m28[_5446].w / _6543);
                        if (_5557 > 1.0)
                        {
                            _6569 = 1.0;
                            break;
                        }
                        float2 _5575 = _180._m28[_5446].xy + (float2(float(spvSMod(_6545, 3)), float(_6545 / 3)) * _180._m24.xy);
                        float2 _5815 = _180._m22.xy * 0.5;
                        float2 _5820 = _5575 + (float2(0.5 + (0.5 * _5550.x), 0.5 - (0.5 * _5550.y)) * _180._m24.xy);
                        float4 _5833 = float4(_5575 + _5815, (_5575 + _180._m24.xy) - _5815);
                        float _6557;
                        do
                        {
                            int _5859 = int(_180._m22.z);
                            if (_5859 <= 0)
                            {
                                _6557 = spvDepthCast(_200).sample_compare(_200Smplr, float3(fast::clamp(_5820, _5833.xy, _5833.zw), _5557).xy, _5557);
                                break;
                            }
                            float2 _5882 = (_5820 / _180._m22.xy) + float2(0.5);
                            float2 _5883 = floor(_5882);
                            float2 _5888 = _5882 - _5883;
                            float2 _5891 = _5883 - float2(0.5);
                            bool _5895 = _5859 == 1;
                            if (_5895)
                            {
                                float2 _5898 = _5888 * 2.0;
                                _5843[0] = float2(3.0) - _5898;
                                _5843[1] = float2(1.0) + _5898;
                                _5844[0] = ((float2(2.0) - _5888) / _5843[0]) - float2(1.0);
                                _5844[1] = (_5888 / _5843[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _5925 = _5888 * 3.0;
                                _5843[0] = float2(4.0) - _5925;
                                _5843[1] = float2(7.0);
                                _5843[2] = float2(1.0) + _5925;
                                _5844[0] = ((float2(3.0) - (_5888 * 2.0)) / _5843[0]) - float2(2.0);
                                _5844[1] = (float2(3.0) + _5888) / _5843[1];
                                _5844[2] = (_5888 / _5843[2]) + float2(2.0);
                            }
                            int _6937 = _5895 ? 2 : 3;
                            int _6547;
                            float _6550;
                            _6550 = 0.0;
                            _6547 = 0;
                            float _6556;
                            for (; _6547 < _6937; _6550 = _6556, _6547++)
                            {
                                _6556 = _6550;
                                for (int _6553 = 0; _6553 < _6937; )
                                {
                                    _6556 += ((_5843[_6553].x * _5843[_6547].y) * spvDepthCast(_200).sample_compare(_200Smplr, float3(fast::clamp(_180._m22.xy * (_5891 + float2(_5844[_6553].x, _5844[_6547].y)), _5833.xy, _5833.zw), _5557).xy, _5557));
                                    _6553++;
                                    continue;
                                }
                            }
                            _6557 = _6550 * (_5895 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _6569 = _6557;
                        break;
                    } while(false);
                    _6607 = _5306 * _6569;
                }
                else
                {
                    _6607 = _5306;
                }
                float3 _2478 = fast::normalize(_5275 + _2041);
                float _2483 = fast::clamp(dot(_6462, _5275), 0.0, 1.0);
                float _2488 = fast::clamp(dot(_6462, _2478), 0.0, 1.0);
                float3 _6030 = _2282 + (_4345 * powr(1.0 - fast::clamp(dot(_2041, _2478), 0.0, 1.0), 5.0));
                float _6044 = ((_2488 * _2488) * _4360) + 1.0;
                _2526 = _6609 + (((((float3(1.0) - _6030) * _2276) + ((_6030 * ((_4355 / ((3.1415927410125732421875 * _6044) * _6044)) * (0.5 / fast::max((_2483 * _4386) + (_2287 * sqrt(((_2483 * _2483) * _4382) + _4355)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875)) * _2483) * _6607);
            }
            _6654 = _6609;
        }
        else
        {
            _6654 = _2426;
        }
        _6651 = _6654;
    }
    float4 _2543 = _2538.sample(_1217, _1840);
    float3 _2570 = mix(mix(_6651, _6459, float3(_1821._m1.y)) + (_1821._m5.xyz * _2543.xyz), _180._m7.xyz, float3(1.0 - exp((-length(_2040)) * _180._m7.w)));
    float3 _6689;
    if (_180._m33.w > 0.5)
    {
        _6689 = _2570 / (float3(1.0) + _2570);
    }
    else
    {
        _6689 = _2570;
    }
    out.m_2582 = float4(_6689, in.m_1849.w);
    float2 _6758;
    do
    {
        if (in.m_2592.w <= 0.0)
        {
            _6758 = float2(0.0);
            break;
        }
        _6758 = ((in.m_2592.xy / float2(in.m_2592.w)) - (in.m_2591.xy / float2(in.m_2591.w))) * float2(0.5, -0.5);
        break;
    } while(false);
    out.m_2590 = _6758;
    return out;
}

