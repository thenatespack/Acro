// Generated from mesh.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: bbb0aa308c3daf77
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
    float4 m_2569 [[color(0)]];
};

struct fragment_main_in
{
    float3 m_1451 [[user(locn0)]];
    float3 m_1893 [[user(locn1)]];
    float2 m_1826 [[user(locn2)]];
    float4 m_1849 [[user(locn3)]];
    float4 m_2041 [[user(locn5)]];
    float4 m_2578 [[user(locn6)]];
    float4 m_2579 [[user(locn7)]];
    float4 m_1902 [[user(locn8)]];
};

fragment fragment_main_out fragment_main(fragment_main_in in [[stage_in]], constant _1819& _1821 [[buffer(2)]], constant _1441& _1443 [[buffer(3)]], constant _1477& _1479 [[buffer(4)]], constant _1485& _1487 [[buffer(5)]], constant _1582& _1584 [[buffer(6)]], constant _1604& _1606 [[buffer(7)]], constant _178& _180 [[buffer(15)]], texture2d<float> _200 [[texture(0)]], texture2d<float> _1842 [[texture(1)]], texture2d<float> _2234 [[texture(2)]], texture2d<float> _1931 [[texture(3)]], texture2d<float> _1770 [[texture(4)]], texture2d<float> _2525 [[texture(5)]], texture2d<float> _1215 [[texture(6)]], texture2d<float> _1321 [[texture(7)]], sampler _200Smplr [[sampler(0)]], sampler _1217 [[sampler(1)]], sampler _1323 [[sampler(7)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])
{
    float2 _2577;
    fragment_main_out out = {};
    float2 _1840 = float2(dot(_1821._m2.xy, in.m_1826) + _1821._m2.z, dot(_1821._m3.xy, in.m_1826) + _1821._m3.z);
    float4 _1847 = _1842.sample(_1217, _1840);
    float3 _1858 = (in.m_1849.xyz * _1821._m0.xyz) * _1847.xyz;
    float3 _6420;
    if (_1821._m1.x > 0.5)
    {
        float2 _1879 = floor(in.m_1451.xz * float2(0.5));
        _6420 = _1858 * ((mod(abs(_1879.x + _1879.y), 2.0) < 0.5) ? 1.0 : 0.75);
    }
    else
    {
        _6420 = _1858;
    }
    float3 _1895 = fast::normalize(in.m_1893);
    float3 _6334;
    if (_1821._m6.y > 0.5)
    {
        float3 _1911 = in.m_1902.xyz - (_1895 * dot(_1895, in.m_1902.xyz));
        float3 _6335;
        if (dot(_1911, _1911) > 9.9999999600419720025001879548654e-13)
        {
            float3 _1920 = fast::normalize(_1911);
            float4 _1936 = _1931.sample(_1217, _1840);
            float3 _6328;
            if (_1821._m6.z > 0.5)
            {
                float2 _6327;
                if (_1821._m6.z > 1.5)
                {
                    _6327 = _1936.xw;
                }
                else
                {
                    _6327 = _1936.xy;
                }
                float2 _1958 = (_6327 * 2.0) - float2(1.0);
                _6328 = float3(_1958, sqrt(fast::clamp(1.0 - dot(_1958, _1958), 0.0, 1.0)));
            }
            else
            {
                _6328 = (_1936.xyz * 2.0) - float3(1.0);
            }
            float2 _1980 = _6328.xy * _1821._m4.z;
            _6335 = fast::normalize(((_1920 * _1980.x) + ((cross(_1895, _1920) * ((in.m_1902.w < 0.0) ? (-1.0) : 1.0)) * _1980.y)) + (_1895 * _6328.z));
        }
        else
        {
            _6335 = _1895;
        }
        _6334 = _6335;
    }
    else
    {
        _6334 = _1895;
    }
    bool _2004 = _1821._m5.w > 0.5;
    bool _2012;
    if (_2004)
    {
        _2012 = !gl_FrontFacing;
    }
    else
    {
        _2012 = _2004;
    }
    float3 _6448;
    if (_2012)
    {
        _6448 = -_6334;
    }
    else
    {
        _6448 = _6334;
    }
    float3 _2021 = fast::normalize(_180._m4.xyz);
    float3 _2027 = _180._m6.xyz - in.m_1451;
    float3 _2028 = fast::normalize(_2027);
    float3 _2033 = fast::normalize(_2021 + _2028);
    float3 _2039 = _1895 * (gl_FrontFacing ? 1.0 : (-1.0));
    bool _2044 = in.m_2041.x > 0.5;
    float3 _6445;
    float _6472;
    if ((_180._m5.w > 0.5) && _2044)
    {
        float _6391;
        float3 _6392;
        do
        {
            int _2637 = int(_180._m21.x);
            float _2645 = dot(_180._m20.xyz, in.m_1451) + _180._m20.w;
            int _6336;
            _6336 = 0;
            for (;;)
            {
                bool _2651 = _6336 < (_2637 - 1);
                bool _2659;
                if (_2651)
                {
                    _2659 = _2645 > _180._m16[_6336];
                }
                else
                {
                    _2659 = _2651;
                }
                if (_2659)
                {
                    _6336++;
                    continue;
                }
                else
                {
                    break;
                }
            }
            if (_2645 > _180._m16[_6336])
            {
                _6392 = float3(1.0);
                _6391 = 1.0;
                break;
            }
            float _6349;
            do
            {
                float4 _2761 = _180._m14[_6336] * float4(in.m_1451 + (_2039 * _180._m18[_6336]), 1.0);
                float _2764 = _2761.x;
                bool _2765 = _2764 < 0.0;
                bool _2772;
                if (!_2765)
                {
                    _2772 = _2764 > 1.0;
                }
                else
                {
                    _2772 = _2765;
                }
                bool _2779;
                if (!_2772)
                {
                    _2779 = _2761.y < 0.0;
                }
                else
                {
                    _2779 = _2772;
                }
                bool _2786;
                if (!_2779)
                {
                    _2786 = _2761.y > 1.0;
                }
                else
                {
                    _2786 = _2779;
                }
                if (_2786)
                {
                    _6349 = 1.0;
                    break;
                }
                float2 _2799 = float2(float(_6336 & 1), float(_6336 >> 1)) * _180._m23.xy;
                float _2806 = fast::min(_2761.z, 1.0) - _180._m19[_6336];
                float2 _2825 = _180._m22.xy * 0.5;
                float2 _2830 = _2799 + (_2761.xy * _180._m23.xy);
                float4 _2843 = float4(_2799 + _2825, (_2799 + _180._m23.xy) - _2825);
                float _6348;
                do
                {
                    int _2869 = int(_180._m22.z);
                    if (_2869 <= 0)
                    {
                        _6348 = spvDepthCast(_200).sample_compare(_200Smplr, float3(fast::clamp(_2830, _2843.xy, _2843.zw), _2806).xy, _2806);
                        break;
                    }
                    float2 _2892 = (_2830 / _180._m22.xy) + float2(0.5);
                    float2 _2893 = floor(_2892);
                    float2 _2898 = _2892 - _2893;
                    float2 _2901 = _2893 - float2(0.5);
                    bool _2905 = _2869 == 1;
                    spvUnsafeArray<float2, 3> _2853;
                    spvUnsafeArray<float2, 3> _2854;
                    if (_2905)
                    {
                        float2 _2908 = _2898 * 2.0;
                        _2853[0] = float2(3.0) - _2908;
                        _2853[1] = float2(1.0) + _2908;
                        _2854[0] = ((float2(2.0) - _2898) / _2853[0]) - float2(1.0);
                        _2854[1] = (_2898 / _2853[1]) + float2(1.0);
                    }
                    else
                    {
                        float2 _2935 = _2898 * 3.0;
                        _2853[0] = float2(4.0) - _2935;
                        _2853[1] = float2(7.0);
                        _2853[2] = float2(1.0) + _2935;
                        _2854[0] = ((float2(3.0) - (_2898 * 2.0)) / _2853[0]) - float2(2.0);
                        _2854[1] = (float2(3.0) + _2898) / _2853[1];
                        _2854[2] = (_2898 / _2853[2]) + float2(2.0);
                    }
                    int _6821 = _2905 ? 2 : 3;
                    int _6338;
                    float _6341;
                    _6341 = 0.0;
                    _6338 = 0;
                    float _6347;
                    for (; _6338 < _6821; _6341 = _6347, _6338++)
                    {
                        _6347 = _6341;
                        for (int _6344 = 0; _6344 < _6821; )
                        {
                            _6347 += ((_2853[_6344].x * _2853[_6338].y) * spvDepthCast(_200).sample_compare(_200Smplr, float3(fast::clamp(_180._m22.xy * (_2901 + float2(_2854[_6344].x, _2854[_6338].y)), _2843.xy, _2843.zw), _2806).xy, _2806));
                            _6344++;
                            continue;
                        }
                    }
                    _6348 = _6341 * (_2905 ? 0.0625 : 0.0069444444961845874786376953125);
                    break;
                } while(false);
                _6349 = _6348;
                break;
            } while(false);
            float3 _6386;
            float _6389;
            if (_2645 > _180._m17[_6336])
            {
                float _2699 = (_2645 - _180._m17[_6336]) / (_180._m16[_6336] - _180._m17[_6336]);
                int _2701 = _6336 + 1;
                float3 _6387;
                float _6390;
                if (_2701 < _2637)
                {
                    float _6369;
                    do
                    {
                        float4 _3048 = _180._m14[_2701] * float4(in.m_1451 + (_2039 * _180._m18[_2701]), 1.0);
                        float _3051 = _3048.x;
                        bool _3052 = _3051 < 0.0;
                        bool _3059;
                        if (!_3052)
                        {
                            _3059 = _3051 > 1.0;
                        }
                        else
                        {
                            _3059 = _3052;
                        }
                        bool _3066;
                        if (!_3059)
                        {
                            _3066 = _3048.y < 0.0;
                        }
                        else
                        {
                            _3066 = _3059;
                        }
                        bool _3073;
                        if (!_3066)
                        {
                            _3073 = _3048.y > 1.0;
                        }
                        else
                        {
                            _3073 = _3066;
                        }
                        if (_3073)
                        {
                            _6369 = 1.0;
                            break;
                        }
                        float2 _3086 = float2(float(_2701 & 1), float(_2701 >> 1)) * _180._m23.xy;
                        float _3093 = fast::min(_3048.z, 1.0) - _180._m19[_2701];
                        float2 _3112 = _180._m22.xy * 0.5;
                        float2 _3117 = _3086 + (_3048.xy * _180._m23.xy);
                        float4 _3130 = float4(_3086 + _3112, (_3086 + _180._m23.xy) - _3112);
                        float _6368;
                        do
                        {
                            int _3156 = int(_180._m22.z);
                            if (_3156 <= 0)
                            {
                                _6368 = spvDepthCast(_200).sample_compare(_200Smplr, float3(fast::clamp(_3117, _3130.xy, _3130.zw), _3093).xy, _3093);
                                break;
                            }
                            float2 _3179 = (_3117 / _180._m22.xy) + float2(0.5);
                            float2 _3180 = floor(_3179);
                            float2 _3185 = _3179 - _3180;
                            float2 _3188 = _3180 - float2(0.5);
                            bool _3192 = _3156 == 1;
                            spvUnsafeArray<float2, 3> _3140;
                            spvUnsafeArray<float2, 3> _3141;
                            if (_3192)
                            {
                                float2 _3195 = _3185 * 2.0;
                                _3140[0] = float2(3.0) - _3195;
                                _3140[1] = float2(1.0) + _3195;
                                _3141[0] = ((float2(2.0) - _3185) / _3140[0]) - float2(1.0);
                                _3141[1] = (_3185 / _3140[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _3222 = _3185 * 3.0;
                                _3140[0] = float2(4.0) - _3222;
                                _3140[1] = float2(7.0);
                                _3140[2] = float2(1.0) + _3222;
                                _3141[0] = ((float2(3.0) - (_3185 * 2.0)) / _3140[0]) - float2(2.0);
                                _3141[1] = (float2(3.0) + _3185) / _3140[1];
                                _3141[2] = (_3185 / _3140[2]) + float2(2.0);
                            }
                            int _6823 = _3192 ? 2 : 3;
                            int _6358;
                            float _6361;
                            _6361 = 0.0;
                            _6358 = 0;
                            float _6367;
                            for (; _6358 < _6823; _6361 = _6367, _6358++)
                            {
                                _6367 = _6361;
                                for (int _6364 = 0; _6364 < _6823; )
                                {
                                    _6367 += ((_3140[_6364].x * _3140[_6358].y) * spvDepthCast(_200).sample_compare(_200Smplr, float3(fast::clamp(_180._m22.xy * (_3188 + float2(_3141[_6364].x, _3141[_6358].y)), _3130.xy, _3130.zw), _3093).xy, _3093));
                                    _6364++;
                                    continue;
                                }
                            }
                            _6368 = _6361 * (_3192 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _6369 = _6368;
                        break;
                    } while(false);
                    _6390 = mix(_6349, _6369, _2699);
                    _6387 = mix(_554[_6336], _554[_2701], float3(_2699));
                }
                else
                {
                    _6390 = mix(_6349, 1.0, _2699);
                    _6387 = _554[_6336];
                }
                _6389 = _6390;
                _6386 = _6387;
            }
            else
            {
                _6389 = _6349;
                _6386 = _554[_6336];
            }
            _6392 = select(float3(1.0), _6386, bool3(_180._m22.w > 0.5));
            _6391 = _6389;
            break;
        } while(false);
        _6472 = _6391;
        _6445 = _6420 * _6392;
    }
    else
    {
        _6472 = 1.0;
        _6445 = _6420;
    }
    float3 _2070 = _180._m5.xyz * _180._m4.w;
    bool _2074 = _1821._m6.w > 0.5;
    float _6443;
    if (_2074)
    {
        _6443 = 1.0;
    }
    else
    {
        _6443 = 1.0 + (_1821._m4.w * (_1770.sample(_1217, _1840).x - 1.0));
    }
    float3 _6637;
    if (!_2004)
    {
        float _2098 = dot(_6448, _2021);
        float3 _6631;
        if (_180._m29.x > 0.5)
        {
            float _3373 = (_180._m29.z * _6448.x) - (_180._m29.w * _6448.z);
            float _3386 = (_180._m29.w * _6448.x) + (_180._m29.z * _6448.z);
            float _3404 = 1.09254801273345947265625 * _3373;
            spvUnsafeArray<float, 9> _6136 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _6448.y, 0.48860299587249755859375 * _3386, 0.48860299587249755859375 * _3373, _3404 * _6448.y, (1.09254801273345947265625 * _6448.y) * _3386, 0.3153919875621795654296875 * (((3.0 * _3386) * _3386) - 1.0), _3404 * _3386, 0.546274006366729736328125 * ((_3373 * _3373) - (_6448.y * _6448.y)) });
            spvUnsafeArray<float, 9> _3318 = _6136;
            float3 _6630;
            _6630 = float3(0.0);
            for (int _6629 = 0; _6629 < 9; )
            {
                _6630 += (_1215.read(uint2((int2(496, 256) + int2(_6629, 0))), 0).xyz * _3318[_6629]);
                _6629++;
                continue;
            }
            _6631 = fast::max(_6630, float3(0.0)) * _180._m29.y;
        }
        else
        {
            _6631 = mix(_180._m9.xyz, _180._m8.xyz, float3((_6448.y * 0.5) + 0.5)) * _180._m8.w;
        }
        float3 _2148 = (_6445 * ((_6631 * _6443) + ((_2070 * fast::max(_2098, 0.0)) * _6472))) + ((_2070 * ((powr(fast::max(dot(_6448, _2033), 0.0), _1821._m1.w) * _1821._m1.z) * step(0.0, _2098))) * _6472);
        float3 _6638;
        if (_180._m13.w > 0.5)
        {
            float2 _3489 = fast::clamp(floor(gl_FragCoord.xy * _180._m12.xy), float2(0.0), _180._m13.xy - float2(1.0));
            uint _3517 = uint((((fast::clamp(floor((log2(fast::max(dot(_180._m11.xyz, in.m_1451) + _180._m11.w, 9.9999999747524270787835121154785e-07)) * _180._m12.z) + _180._m12.w), 0.0, _180._m13.z - 1.0) * _180._m13.y) + _3489.y) * _180._m13.x) + _3489.x);
            uint _3519 = _3517 >> uint(2);
            uint _3521 = _3517 & 3u;
            uint _3525 = _1584._m0[_3519][_3521] & 65535u;
            uint _3527 = _1584._m0[_3519][_3521] >> uint(16);
            float3 _6639;
            _6639 = _2148;
            float3 _2229;
            spvUnsafeArray<float2, 3> _3935;
            spvUnsafeArray<float2, 3> _3936;
            spvUnsafeArray<float2, 3> _4148;
            spvUnsafeArray<float2, 3> _4149;
            for (uint _6636 = _3525; _6636 < (_3525 + _3527); _6639 = _2229, _6636++)
            {
                uint _3533 = _6636 / 3u;
                uint _3546 = (_1606._m0[_3533 >> uint(2)][_3533 & 3u] >> ((_6636 - (_3533 * 3u)) * 10u)) & 1023u;
                float3 _3563 = _1443._m0[_3546].xyz - in.m_1451;
                float _3566 = dot(_3563, _3563);
                float _3570 = _3566 * _1443._m0[_3546].w;
                float _3575 = fast::clamp(1.0 - (_3570 * _3570), 0.0, 1.0);
                float3 _3580 = _3563 * rsqrt(fast::max(_3566, 9.9999999392252902907785028219223e-09));
                float _3598 = fast::clamp((dot(-_3580, _1487._m0[_3546].xyz) * _1479._m0[_3546].w) + _1487._m0[_3546].w, 0.0, 1.0);
                float3 _3611 = _1479._m0[_3546].xyz * ((((_3575 * _3575) * _3598) * _3598) / fast::max(_3566, 9.9999997473787516355514526367188e-05));
                float3 _6757;
                if (_2044)
                {
                    float _6703;
                    do
                    {
                        uint _3647 = uint(_180._m21.z);
                        if (_3546 < _3647)
                        {
                            float _3669 = _180._m26[_3546].z * fast::max((_180._m15[_3546] * float4(in.m_1451, 1.0)).w, 0.0);
                            float4 _3693 = _180._m15[_3546] * float4((in.m_1451 + (_2039 * (_3669 * _180._m25.x))) + (_3580 * (_3669 * _180._m25.y)), 1.0);
                            float _3695 = _3693.w;
                            if (_3695 <= 0.0)
                            {
                                _6703 = 1.0;
                                break;
                            }
                            float3 _3704 = _3693.xyz / float3(_3695);
                            float _3706 = _3704.x;
                            bool _3707 = _3706 < 0.0;
                            bool _3714;
                            if (!_3707)
                            {
                                _3714 = _3706 > 1.0;
                            }
                            else
                            {
                                _3714 = _3707;
                            }
                            bool _3721;
                            if (!_3714)
                            {
                                _3721 = _3704.y < 0.0;
                            }
                            else
                            {
                                _3721 = _3714;
                            }
                            bool _3728;
                            if (!_3721)
                            {
                                _3728 = _3704.y > 1.0;
                            }
                            else
                            {
                                _3728 = _3721;
                            }
                            bool _3735;
                            if (!_3728)
                            {
                                _3735 = _3704.z > 1.0;
                            }
                            else
                            {
                                _3735 = _3728;
                            }
                            if (_3735)
                            {
                                _6703 = 1.0;
                                break;
                            }
                            float _3741 = _3704.z;
                            float2 _3907 = _180._m22.xy * 0.5;
                            float2 _3912 = _180._m26[_3546].xy + (_3704.xy * _180._m23.zw);
                            float4 _3925 = float4(_180._m26[_3546].xy + _3907, (_180._m26[_3546].xy + _180._m23.zw) - _3907);
                            float _6702;
                            do
                            {
                                int _3951 = int(_180._m22.z);
                                if (_3951 <= 0)
                                {
                                    float2 _3961 = fast::clamp(_3912, _3925.xy, _3925.zw);
                                    _6702 = spvDepthCast(_200).sample_compare(_200Smplr, float3(_3961, _3741).xy, _3741);
                                    break;
                                }
                                float2 _3974 = (_3912 / _180._m22.xy) + float2(0.5);
                                float2 _3975 = floor(_3974);
                                float2 _3980 = _3974 - _3975;
                                float2 _3983 = _3975 - float2(0.5);
                                bool _3987 = _3951 == 1;
                                if (_3987)
                                {
                                    float2 _3990 = _3980 * 2.0;
                                    _3935[0] = float2(3.0) - _3990;
                                    _3935[1] = float2(1.0) + _3990;
                                    _3936[0] = ((float2(2.0) - _3980) / _3935[0]) - float2(1.0);
                                    _3936[1] = (_3980 / _3935[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _4017 = _3980 * 3.0;
                                    _3935[0] = float2(4.0) - _4017;
                                    _3935[1] = float2(7.0);
                                    _3935[2] = float2(1.0) + _4017;
                                    _3936[0] = ((float2(3.0) - (_3980 * 2.0)) / _3935[0]) - float2(2.0);
                                    _3936[1] = (float2(3.0) + _3980) / _3935[1];
                                    _3936[2] = (_3980 / _3935[2]) + float2(2.0);
                                }
                                int _6828 = _3987 ? 2 : 3;
                                int _6692;
                                float _6695;
                                _6695 = 0.0;
                                _6692 = 0;
                                float _6701;
                                for (; _6692 < _6828; _6695 = _6701, _6692++)
                                {
                                    _6701 = _6695;
                                    for (int _6698 = 0; _6698 < _6828; )
                                    {
                                        _6701 += ((_3935[_6698].x * _3935[_6692].y) * spvDepthCast(_200).sample_compare(_200Smplr, float3(fast::clamp(_180._m22.xy * (_3983 + float2(_3936[_6698].x, _3936[_6692].y)), _3925.xy, _3925.zw), _3741).xy, _3741));
                                        _6698++;
                                        continue;
                                    }
                                }
                                _6702 = _6695 * (_3987 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _6703 = _6702;
                            break;
                        }
                        uint _3751 = _3546 - _3647;
                        if (_3751 >= uint(_180._m21.w))
                        {
                            _6703 = 1.0;
                            break;
                        }
                        float _3772 = _180._m27[_3751].w * length(in.m_1451 - _180._m27[_3751].xyz);
                        float3 _3790 = ((in.m_1451 + (_2039 * (_3772 * _180._m25.x))) + (_3580 * (_3772 * _180._m25.y))) - _180._m27[_3751].xyz;
                        float3 _3792 = abs(_3790);
                        float _3794 = _3792.x;
                        float _3796 = _3792.y;
                        bool _3797 = _3794 >= _3796;
                        bool _3805;
                        if (_3797)
                        {
                            _3805 = _3794 >= _3792.z;
                        }
                        else
                        {
                            _3805 = _3797;
                        }
                        float _6677;
                        int _6679;
                        if (_3805)
                        {
                            _6679 = (_3790.x > 0.0) ? 0 : 1;
                            _6677 = _3794;
                        }
                        else
                        {
                            float _3817 = _3792.z;
                            bool _3818 = _3796 >= _3817;
                            int _6680;
                            if (_3818)
                            {
                                _6680 = (_3790.y > 0.0) ? 2 : 3;
                            }
                            else
                            {
                                _6680 = (_3790.z > 0.0) ? 4 : 5;
                            }
                            _6679 = _6680;
                            _6677 = _3818 ? _3796 : _3817;
                        }
                        if (_6677 <= 0.0)
                        {
                            _6703 = 1.0;
                            break;
                        }
                        float2 _3855 = float2(dot(_3790, _858[_6679]), dot(_3790, _867[_6679])) / float2(_6677 * _180._m24.z);
                        float _3862 = _180._m28[_3751].z + (_180._m28[_3751].w / _6677);
                        if (_3862 > 1.0)
                        {
                            _6703 = 1.0;
                            break;
                        }
                        float2 _3880 = _180._m28[_3751].xy + (float2(float(spvSMod(_6679, 3)), float(_6679 / 3)) * _180._m24.xy);
                        float2 _4120 = _180._m22.xy * 0.5;
                        float2 _4125 = _3880 + (float2(0.5 + (0.5 * _3855.x), 0.5 - (0.5 * _3855.y)) * _180._m24.xy);
                        float4 _4138 = float4(_3880 + _4120, (_3880 + _180._m24.xy) - _4120);
                        float _6691;
                        do
                        {
                            int _4164 = int(_180._m22.z);
                            if (_4164 <= 0)
                            {
                                _6691 = spvDepthCast(_200).sample_compare(_200Smplr, float3(fast::clamp(_4125, _4138.xy, _4138.zw), _3862).xy, _3862);
                                break;
                            }
                            float2 _4187 = (_4125 / _180._m22.xy) + float2(0.5);
                            float2 _4188 = floor(_4187);
                            float2 _4193 = _4187 - _4188;
                            float2 _4196 = _4188 - float2(0.5);
                            bool _4200 = _4164 == 1;
                            if (_4200)
                            {
                                float2 _4203 = _4193 * 2.0;
                                _4148[0] = float2(3.0) - _4203;
                                _4148[1] = float2(1.0) + _4203;
                                _4149[0] = ((float2(2.0) - _4193) / _4148[0]) - float2(1.0);
                                _4149[1] = (_4193 / _4148[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _4230 = _4193 * 3.0;
                                _4148[0] = float2(4.0) - _4230;
                                _4148[1] = float2(7.0);
                                _4148[2] = float2(1.0) + _4230;
                                _4149[0] = ((float2(3.0) - (_4193 * 2.0)) / _4148[0]) - float2(2.0);
                                _4149[1] = (float2(3.0) + _4193) / _4148[1];
                                _4149[2] = (_4193 / _4148[2]) + float2(2.0);
                            }
                            int _6831 = _4200 ? 2 : 3;
                            int _6681;
                            float _6684;
                            _6684 = 0.0;
                            _6681 = 0;
                            float _6690;
                            for (; _6681 < _6831; _6684 = _6690, _6681++)
                            {
                                _6690 = _6684;
                                for (int _6687 = 0; _6687 < _6831; )
                                {
                                    _6690 += ((_4148[_6687].x * _4148[_6681].y) * spvDepthCast(_200).sample_compare(_200Smplr, float3(fast::clamp(_180._m22.xy * (_4196 + float2(_4149[_6687].x, _4149[_6681].y)), _4138.xy, _4138.zw), _3862).xy, _3862));
                                    _6687++;
                                    continue;
                                }
                            }
                            _6691 = _6684 * (_4200 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _6703 = _6691;
                        break;
                    } while(false);
                    _6757 = _3611 * _6703;
                }
                else
                {
                    _6757 = _3611;
                }
                float _2200 = dot(_6448, _3580);
                _2229 = _6639 + (((_6445 * fast::max(_2200, 0.0)) * _6757) + (_6757 * ((powr(fast::max(dot(_6448, fast::normalize(_3580 + _2028)), 0.0), _1821._m1.w) * _1821._m1.z) * step(0.0, _2200))));
            }
            _6638 = _6639;
        }
        else
        {
            _6638 = _2148;
        }
        _6637 = _6638;
    }
    else
    {
        float4 _2239 = _2234.sample(_1217, _1840);
        float _2246 = fast::clamp(_1821._m4.x * _2239.z, 0.0, 1.0);
        float _2254 = fast::clamp(_1821._m4.y * _2239.y, 0.04500000178813934326171875, 1.0);
        float _2258 = _2254 * _2254;
        float3 _2263 = _6445 * (1.0 - _2246);
        float3 _2269 = mix(float3(0.039999999105930328369140625), _6445, float3(_2246));
        float _2274 = fast::max(dot(_6448, _2028), 9.9999997473787516355514526367188e-05);
        float _2279 = fast::clamp(dot(_6448, _2021), 0.0, 1.0);
        float _2284 = fast::clamp(dot(_6448, _2033), 0.0, 1.0);
        float3 _4332 = float3(1.0) - _2269;
        float3 _4335 = _2269 + (_4332 * powr(1.0 - fast::clamp(dot(_2028, _2033), 0.0, 1.0), 5.0));
        float _4342 = _2258 * _2258;
        float _4347 = _4342 - 1.0;
        float _4349 = ((_2284 * _2284) * _4347) + 1.0;
        float _4369 = 1.0 - _4342;
        float _4373 = sqrt(((_2274 * _2274) * _4369) + _4342);
        float3 _6491;
        float2 _6506;
        float3 _6518;
        if (_180._m29.x > 0.5)
        {
            float4 _4406 = _1321.sample(_1323, (((float2(_2274, _2254) * 31.0) + float2(0.5)) * float2(0.03125)));
            float _4465 = (_180._m29.z * _6448.x) - (_180._m29.w * _6448.z);
            float _4478 = (_180._m29.w * _6448.x) + (_180._m29.z * _6448.z);
            float _4496 = 1.09254801273345947265625 * _4465;
            spvUnsafeArray<float, 9> _6117 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _6448.y, 0.48860299587249755859375 * _4478, 0.48860299587249755859375 * _4465, _4496 * _6448.y, (1.09254801273345947265625 * _6448.y) * _4478, 0.3153919875621795654296875 * (((3.0 * _4478) * _4478) - 1.0), _4496 * _4478, 0.546274006366729736328125 * ((_4465 * _4465) - (_6448.y * _6448.y)) });
            spvUnsafeArray<float, 9> _4410 = _6117;
            float3 _6474;
            _6474 = float3(0.0);
            for (int _6473 = 0; _6473 < 9; )
            {
                _6474 += (_1215.read(uint2((int2(496, 256) + int2(_6473, 0))), 0).xyz * _4410[_6473]);
                _6473++;
                continue;
            }
            float3 _2345 = reflect(-_2028, _6448);
            float _4591 = _2345.x;
            float _4596 = _2345.z;
            float2 _4628 = float2((precise::atan2((_180._m29.z * _4591) - (_180._m29.w * _4596), -((_180._m29.w * _4591) + (_180._m29.z * _4596))) * 0.15915493667125701904296875) + 0.5, acos(fast::clamp(_2345.y, -1.0, 1.0)) * 0.3183098733425140380859375);
            float _4560 = _2254 * 5.0;
            int _4563 = min(int(_4560), 4);
            float2 _4649 = (_4628 * float2(_1277[_4563].zw)) - float2(0.5);
            float2 _4651 = floor(_4649);
            float2 _4654 = _4649 - _4651;
            int _4657 = int(_4651.x);
            int _4660 = int(_4651.y);
            int _6476;
            if (_4657 < 0)
            {
                _6476 = _4657 + _1277[_4563].z;
            }
            else
            {
                _6476 = _4657;
            }
            int _6477;
            if (_6476 >= _1277[_4563].z)
            {
                _6477 = _6476 - _1277[_4563].z;
            }
            else
            {
                _6477 = _6476;
            }
            int _4680 = _6477 + 1;
            int _6832 = (_4680 == _1277[_4563].z) ? 0 : _4680;
            int _4695 = min((_4660 + 1), (_1277[_4563].w - 1));
            int _4697 = max(_4660, 0);
            float3 _4750 = float3(_4654.x);
            int _4570 = _4563 + 1;
            float2 _4782 = (_4628 * float2(_1277[_4570].zw)) - float2(0.5);
            float2 _4784 = floor(_4782);
            float2 _4787 = _4782 - _4784;
            int _4790 = int(_4784.x);
            int _4793 = int(_4784.y);
            int _6483;
            if (_4790 < 0)
            {
                _6483 = _4790 + _1277[_4570].z;
            }
            else
            {
                _6483 = _4790;
            }
            int _6484;
            if (_6483 >= _1277[_4570].z)
            {
                _6484 = _6483 - _1277[_4570].z;
            }
            else
            {
                _6484 = _6483;
            }
            int _4813 = _6484 + 1;
            int _6833 = (_4813 == _1277[_4570].z) ? 0 : _4813;
            int _4828 = min((_4793 + 1), (_1277[_4570].w - 1));
            int _4830 = max(_4793, 0);
            float3 _4883 = float3(_4787.x);
            float3 _4585 = mix(mix(mix(_1215.read(uint2((_1277[_4563].xy + int2(_6477, _4697))), 0).xyz, _1215.read(uint2((_1277[_4563].xy + int2(_6832, _4697))), 0).xyz, _4750), mix(_1215.read(uint2((_1277[_4563].xy + int2(_6477, _4695))), 0).xyz, _1215.read(uint2((_1277[_4563].xy + int2(_6832, _4695))), 0).xyz, _4750), float3(_4654.y)), mix(mix(_1215.read(uint2((_1277[_4570].xy + int2(_6484, _4830))), 0).xyz, _1215.read(uint2((_1277[_4570].xy + int2(_6833, _4830))), 0).xyz, _4883), mix(_1215.read(uint2((_1277[_4570].xy + int2(_6484, _4828))), 0).xyz, _1215.read(uint2((_1277[_4570].xy + int2(_6833, _4828))), 0).xyz, _4883), float3(_4787.y)), float3(_4560 - float(_4563))) * _180._m29.y;
            _6518 = fast::max(_6474, float3(0.0)) * _180._m29.y;
            _6506 = _4406.xy;
            _6491 = _4585;
        }
        else
        {
            float4 _4901 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * _2254) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);
            float _4903 = _4901.x;
            float3 _4938 = mix(_180._m9.xyz, _180._m8.xyz, float3((_6448.y * 0.5) + 0.5)) * _180._m8.w;
            _6518 = _4938;
            _6506 = (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_4903 * _4903, exp2((-9.27999973297119140625) * _2274)) * _4903) + _4901.y)) + _4901.zw;
            _6491 = mix(mix(_180._m9.xyz, _180._m8.xyz, float3((reflect(-_2028, _6448).y * 0.5) + 0.5)) * _180._m8.w, _4938, float3(_2254));
        }
        bool _2377;
        if (_2074)
        {
            _2377 = _180._m33.z > 0.5;
        }
        else
        {
            _2377 = _2074;
        }
        float3 _6527;
        if (_2377)
        {
            float3 _6503;
            do
            {
                float _5017 = ((_180._m32.x * (1.0 - smoothstep(_180._m33.x * 0.5, _180._m33.x, abs(dot(_180._m31.xyz, in.m_1451) - _180._m31.w)))) * smoothstep(0.5, 0.89999997615814208984375, dot(_2039, _180._m31.xyz))) * (1.0 - smoothstep(_180._m32.y * 0.5, _180._m32.y, _2254));
                if (_5017 <= 0.0)
                {
                    _6503 = _6491;
                    break;
                }
                float4 _5042 = _180._m30 * float4(in.m_1451 + ((_6448 - (_180._m31.xyz * dot(_6448, _180._m31.xyz))) * _180._m32.w), 1.0);
                float2 _5055 = ((float2(_5042.x, -_5042.y) / float2(_5042.w)) * 0.5) + float2(0.5);
                float _5059 = _180._m32.z * _2254;
                float3 _6501;
                float _6502;
                _6502 = 0.0;
                _6501 = float3(0.0);
                for (int _6500 = 0; _6500 < 12; )
                {
                    float _5066 = float(_6500);
                    float _5074 = _5066 * 2.3999631404876708984375;
                    float2 _5086 = _5055 + (float2(cos(_5074) * _180._m33.y, sin(_5074)) * (sqrt((_5066 + 0.5) * 0.083333335816860198974609375) * _5059));
                    float2 _5091 = fast::min(_5086, float2(1.0) - _5086);
                    float _5097 = smoothstep(0.0, 0.039999999105930328369140625, fast::min(_5091.x, _5091.y));
                    float4 _5105 = _1770.sample(_1217, fast::clamp(_5086, float2(0.0), float2(1.0)), level(0.0));
                    float3 _5107 = _5105.xyz;
                    _6502 += (_5105.w * _5097);
                    _6501 += ((_5107 / (float3(1.0) - fast::min(_5107, float3(0.99500000476837158203125)))) * _5097);
                    _6500++;
                    continue;
                }
                _6503 = mix(_6491, (_6501 * float3(0.083333335816860198974609375)) + (_6491 * (1.0 - (_6502 * 0.083333335816860198974609375))), float3(_5017));
                break;
            } while(false);
            _6527 = _6503;
        }
        else
        {
            _6527 = _6491;
        }
        float3 _2397 = (_2269 * _6506.x) + float3(_6506.y);
        float3 _2413 = ((((((float3(1.0) - _4335) * _2263) + ((_4335 * ((_4342 / ((3.1415927410125732421875 * _4349) * _4349)) * (0.5 / fast::max((_2279 * _4373) + (_2274 * sqrt(((_2279 * _2279) * _4369) + _4342)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875)) * _2279) * _2070) * _6472) + (((((float3(1.0) - _2397) * _2263) * _6518) + (_2397 * _6527)) * _6443);
        float3 _6640;
        if (_180._m13.w > 0.5)
        {
            float2 _5171 = fast::clamp(floor(gl_FragCoord.xy * _180._m12.xy), float2(0.0), _180._m13.xy - float2(1.0));
            uint _5199 = uint((((fast::clamp(floor((log2(fast::max(dot(_180._m11.xyz, in.m_1451) + _180._m11.w, 9.9999999747524270787835121154785e-07)) * _180._m12.z) + _180._m12.w), 0.0, _180._m13.z - 1.0) * _180._m13.y) + _5171.y) * _180._m13.x) + _5171.x);
            uint _5201 = _5199 >> uint(2);
            uint _5203 = _5199 & 3u;
            uint _5207 = _1584._m0[_5201][_5203] & 65535u;
            uint _5209 = _1584._m0[_5201][_5203] >> uint(16);
            float3 _6595;
            _6595 = _2413;
            float3 _2513;
            spvUnsafeArray<float2, 3> _5617;
            spvUnsafeArray<float2, 3> _5618;
            spvUnsafeArray<float2, 3> _5830;
            spvUnsafeArray<float2, 3> _5831;
            for (uint _6528 = _5207; _6528 < (_5207 + _5209); _6595 = _2513, _6528++)
            {
                uint _5215 = _6528 / 3u;
                uint _5228 = (_1606._m0[_5215 >> uint(2)][_5215 & 3u] >> ((_6528 - (_5215 * 3u)) * 10u)) & 1023u;
                float3 _5245 = _1443._m0[_5228].xyz - in.m_1451;
                float _5248 = dot(_5245, _5245);
                float _5252 = _5248 * _1443._m0[_5228].w;
                float _5257 = fast::clamp(1.0 - (_5252 * _5252), 0.0, 1.0);
                float3 _5262 = _5245 * rsqrt(fast::max(_5248, 9.9999999392252902907785028219223e-09));
                float _5280 = fast::clamp((dot(-_5262, _1487._m0[_5228].xyz) * _1479._m0[_5228].w) + _1487._m0[_5228].w, 0.0, 1.0);
                float3 _5293 = _1479._m0[_5228].xyz * ((((_5257 * _5257) * _5280) * _5280) / fast::max(_5248, 9.9999997473787516355514526367188e-05));
                float3 _6593;
                if (_2044)
                {
                    float _6555;
                    do
                    {
                        uint _5329 = uint(_180._m21.z);
                        if (_5228 < _5329)
                        {
                            float _5351 = _180._m26[_5228].z * fast::max((_180._m15[_5228] * float4(in.m_1451, 1.0)).w, 0.0);
                            float4 _5375 = _180._m15[_5228] * float4((in.m_1451 + (_2039 * (_5351 * _180._m25.x))) + (_5262 * (_5351 * _180._m25.y)), 1.0);
                            float _5377 = _5375.w;
                            if (_5377 <= 0.0)
                            {
                                _6555 = 1.0;
                                break;
                            }
                            float3 _5386 = _5375.xyz / float3(_5377);
                            float _5388 = _5386.x;
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
                                _5403 = _5386.y < 0.0;
                            }
                            else
                            {
                                _5403 = _5396;
                            }
                            bool _5410;
                            if (!_5403)
                            {
                                _5410 = _5386.y > 1.0;
                            }
                            else
                            {
                                _5410 = _5403;
                            }
                            bool _5417;
                            if (!_5410)
                            {
                                _5417 = _5386.z > 1.0;
                            }
                            else
                            {
                                _5417 = _5410;
                            }
                            if (_5417)
                            {
                                _6555 = 1.0;
                                break;
                            }
                            float _5423 = _5386.z;
                            float2 _5589 = _180._m22.xy * 0.5;
                            float2 _5594 = _180._m26[_5228].xy + (_5386.xy * _180._m23.zw);
                            float4 _5607 = float4(_180._m26[_5228].xy + _5589, (_180._m26[_5228].xy + _180._m23.zw) - _5589);
                            float _6554;
                            do
                            {
                                int _5633 = int(_180._m22.z);
                                if (_5633 <= 0)
                                {
                                    float2 _5643 = fast::clamp(_5594, _5607.xy, _5607.zw);
                                    _6554 = spvDepthCast(_200).sample_compare(_200Smplr, float3(_5643, _5423).xy, _5423);
                                    break;
                                }
                                float2 _5656 = (_5594 / _180._m22.xy) + float2(0.5);
                                float2 _5657 = floor(_5656);
                                float2 _5662 = _5656 - _5657;
                                float2 _5665 = _5657 - float2(0.5);
                                bool _5669 = _5633 == 1;
                                if (_5669)
                                {
                                    float2 _5672 = _5662 * 2.0;
                                    _5617[0] = float2(3.0) - _5672;
                                    _5617[1] = float2(1.0) + _5672;
                                    _5618[0] = ((float2(2.0) - _5662) / _5617[0]) - float2(1.0);
                                    _5618[1] = (_5662 / _5617[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _5699 = _5662 * 3.0;
                                    _5617[0] = float2(4.0) - _5699;
                                    _5617[1] = float2(7.0);
                                    _5617[2] = float2(1.0) + _5699;
                                    _5618[0] = ((float2(3.0) - (_5662 * 2.0)) / _5617[0]) - float2(2.0);
                                    _5618[1] = (float2(3.0) + _5662) / _5617[1];
                                    _5618[2] = (_5662 / _5617[2]) + float2(2.0);
                                }
                                int _6835 = _5669 ? 2 : 3;
                                int _6544;
                                float _6547;
                                _6547 = 0.0;
                                _6544 = 0;
                                float _6553;
                                for (; _6544 < _6835; _6547 = _6553, _6544++)
                                {
                                    _6553 = _6547;
                                    for (int _6550 = 0; _6550 < _6835; )
                                    {
                                        _6553 += ((_5617[_6550].x * _5617[_6544].y) * spvDepthCast(_200).sample_compare(_200Smplr, float3(fast::clamp(_180._m22.xy * (_5665 + float2(_5618[_6550].x, _5618[_6544].y)), _5607.xy, _5607.zw), _5423).xy, _5423));
                                        _6550++;
                                        continue;
                                    }
                                }
                                _6554 = _6547 * (_5669 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _6555 = _6554;
                            break;
                        }
                        uint _5433 = _5228 - _5329;
                        if (_5433 >= uint(_180._m21.w))
                        {
                            _6555 = 1.0;
                            break;
                        }
                        float _5454 = _180._m27[_5433].w * length(in.m_1451 - _180._m27[_5433].xyz);
                        float3 _5472 = ((in.m_1451 + (_2039 * (_5454 * _180._m25.x))) + (_5262 * (_5454 * _180._m25.y))) - _180._m27[_5433].xyz;
                        float3 _5474 = abs(_5472);
                        float _5476 = _5474.x;
                        float _5478 = _5474.y;
                        bool _5479 = _5476 >= _5478;
                        bool _5487;
                        if (_5479)
                        {
                            _5487 = _5476 >= _5474.z;
                        }
                        else
                        {
                            _5487 = _5479;
                        }
                        float _6529;
                        int _6531;
                        if (_5487)
                        {
                            _6531 = (_5472.x > 0.0) ? 0 : 1;
                            _6529 = _5476;
                        }
                        else
                        {
                            float _5499 = _5474.z;
                            bool _5500 = _5478 >= _5499;
                            int _6532;
                            if (_5500)
                            {
                                _6532 = (_5472.y > 0.0) ? 2 : 3;
                            }
                            else
                            {
                                _6532 = (_5472.z > 0.0) ? 4 : 5;
                            }
                            _6531 = _6532;
                            _6529 = _5500 ? _5478 : _5499;
                        }
                        if (_6529 <= 0.0)
                        {
                            _6555 = 1.0;
                            break;
                        }
                        float2 _5537 = float2(dot(_5472, _858[_6531]), dot(_5472, _867[_6531])) / float2(_6529 * _180._m24.z);
                        float _5544 = _180._m28[_5433].z + (_180._m28[_5433].w / _6529);
                        if (_5544 > 1.0)
                        {
                            _6555 = 1.0;
                            break;
                        }
                        float2 _5562 = _180._m28[_5433].xy + (float2(float(spvSMod(_6531, 3)), float(_6531 / 3)) * _180._m24.xy);
                        float2 _5802 = _180._m22.xy * 0.5;
                        float2 _5807 = _5562 + (float2(0.5 + (0.5 * _5537.x), 0.5 - (0.5 * _5537.y)) * _180._m24.xy);
                        float4 _5820 = float4(_5562 + _5802, (_5562 + _180._m24.xy) - _5802);
                        float _6543;
                        do
                        {
                            int _5846 = int(_180._m22.z);
                            if (_5846 <= 0)
                            {
                                _6543 = spvDepthCast(_200).sample_compare(_200Smplr, float3(fast::clamp(_5807, _5820.xy, _5820.zw), _5544).xy, _5544);
                                break;
                            }
                            float2 _5869 = (_5807 / _180._m22.xy) + float2(0.5);
                            float2 _5870 = floor(_5869);
                            float2 _5875 = _5869 - _5870;
                            float2 _5878 = _5870 - float2(0.5);
                            bool _5882 = _5846 == 1;
                            if (_5882)
                            {
                                float2 _5885 = _5875 * 2.0;
                                _5830[0] = float2(3.0) - _5885;
                                _5830[1] = float2(1.0) + _5885;
                                _5831[0] = ((float2(2.0) - _5875) / _5830[0]) - float2(1.0);
                                _5831[1] = (_5875 / _5830[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _5912 = _5875 * 3.0;
                                _5830[0] = float2(4.0) - _5912;
                                _5830[1] = float2(7.0);
                                _5830[2] = float2(1.0) + _5912;
                                _5831[0] = ((float2(3.0) - (_5875 * 2.0)) / _5830[0]) - float2(2.0);
                                _5831[1] = (float2(3.0) + _5875) / _5830[1];
                                _5831[2] = (_5875 / _5830[2]) + float2(2.0);
                            }
                            int _6838 = _5882 ? 2 : 3;
                            int _6533;
                            float _6536;
                            _6536 = 0.0;
                            _6533 = 0;
                            float _6542;
                            for (; _6533 < _6838; _6536 = _6542, _6533++)
                            {
                                _6542 = _6536;
                                for (int _6539 = 0; _6539 < _6838; )
                                {
                                    _6542 += ((_5830[_6539].x * _5830[_6533].y) * spvDepthCast(_200).sample_compare(_200Smplr, float3(fast::clamp(_180._m22.xy * (_5878 + float2(_5831[_6539].x, _5831[_6533].y)), _5820.xy, _5820.zw), _5544).xy, _5544));
                                    _6539++;
                                    continue;
                                }
                            }
                            _6543 = _6536 * (_5882 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _6555 = _6543;
                        break;
                    } while(false);
                    _6593 = _5293 * _6555;
                }
                else
                {
                    _6593 = _5293;
                }
                float3 _2465 = fast::normalize(_5262 + _2028);
                float _2470 = fast::clamp(dot(_6448, _5262), 0.0, 1.0);
                float _2475 = fast::clamp(dot(_6448, _2465), 0.0, 1.0);
                float3 _6017 = _2269 + (_4332 * powr(1.0 - fast::clamp(dot(_2028, _2465), 0.0, 1.0), 5.0));
                float _6031 = ((_2475 * _2475) * _4347) + 1.0;
                _2513 = _6595 + (((((float3(1.0) - _6017) * _2263) + ((_6017 * ((_4342 / ((3.1415927410125732421875 * _6031) * _6031)) * (0.5 / fast::max((_2470 * _4373) + (_2274 * sqrt(((_2470 * _2470) * _4369) + _4342)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875)) * _2470) * _6593);
            }
            _6640 = _6595;
        }
        else
        {
            _6640 = _2413;
        }
        _6637 = _6640;
    }
    float4 _2530 = _2525.sample(_1217, _1840);
    float3 _2557 = mix(mix(_6637, _6445, float3(_1821._m1.y)) + (_1821._m5.xyz * _2530.xyz), _180._m7.xyz, float3(1.0 - exp((-length(_2027)) * _180._m7.w)));
    float3 _6675;
    if (_180._m33.w > 0.5)
    {
        _6675 = _2557 / (float3(1.0) + _2557);
    }
    else
    {
        _6675 = _2557;
    }
    out.m_2569 = float4(_6675, (in.m_1849.w * _1821._m0.w) * _1847.w);
    float2 _6676;
    do
    {
        if (in.m_2579.w <= 0.0)
        {
            _6676 = float2(0.0);
            break;
        }
        _6676 = ((in.m_2579.xy / float2(in.m_2579.w)) - (in.m_2578.xy / float2(in.m_2578.w))) * float2(0.5, -0.5);
        break;
    } while(false);
    _2577 = _6676;
    return out;
}

