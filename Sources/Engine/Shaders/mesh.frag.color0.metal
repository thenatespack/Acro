// Generated from mesh.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 7cafb1043d106b34
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
    float4 m_2635 [[color(0)]];
};

struct fragment_main_in
{
    float3 m_1451 [[user(locn0)]];
    float3 m_1893 [[user(locn1)]];
    float2 m_1826 [[user(locn2)]];
    float4 m_1849 [[user(locn3)]];
    float4 m_2041 [[user(locn5)]];
    float4 m_2644 [[user(locn6)]];
    float4 m_2645 [[user(locn7)]];
    float4 m_1902 [[user(locn8)]];
};

fragment fragment_main_out fragment_main(fragment_main_in in [[stage_in]], constant _1819& _1821 [[buffer(2)]], constant _1441& _1443 [[buffer(3)]], constant _1477& _1479 [[buffer(4)]], constant _1485& _1487 [[buffer(5)]], constant _1582& _1584 [[buffer(6)]], constant _1604& _1606 [[buffer(7)]], constant _178& _180 [[buffer(15)]], texture2d<float> _200 [[texture(0)]], texture2d<float> _1842 [[texture(1)]], texture2d<float> _2234 [[texture(2)]], texture2d<float> _1931 [[texture(3)]], texture2d<float> _1770 [[texture(4)]], texture2d<float> _2525 [[texture(5)]], texture2d<float> _1215 [[texture(6)]], texture2d<float> _1321 [[texture(7)]], sampler _200Smplr [[sampler(0)]], sampler _1217 [[sampler(1)]], sampler _1323 [[sampler(7)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])
{
    float2 _2643;
    fragment_main_out out = {};
    float2 _1840 = float2(dot(_1821._m2.xy, in.m_1826) + _1821._m2.z, dot(_1821._m3.xy, in.m_1826) + _1821._m3.z);
    float4 _1847 = _1842.sample(_1217, _1840);
    float3 _1858 = (in.m_1849.xyz * _1821._m0.xyz) * _1847.xyz;
    float3 _6487;
    if (_1821._m1.x > 0.5)
    {
        float2 _1879 = floor(in.m_1451.xz * float2(0.5));
        _6487 = _1858 * ((mod(abs(_1879.x + _1879.y), 2.0) < 0.5) ? 1.0 : 0.75);
    }
    else
    {
        _6487 = _1858;
    }
    float3 _1895 = fast::normalize(in.m_1893);
    float3 _6401;
    if (_1821._m6.y > 0.5)
    {
        float3 _1911 = in.m_1902.xyz - (_1895 * dot(_1895, in.m_1902.xyz));
        float3 _6402;
        if (dot(_1911, _1911) > 9.9999999600419720025001879548654e-13)
        {
            float3 _1920 = fast::normalize(_1911);
            float4 _1936 = _1931.sample(_1217, _1840);
            float3 _6395;
            if (_1821._m6.z > 0.5)
            {
                float2 _6394;
                if (_1821._m6.z > 1.5)
                {
                    _6394 = _1936.xw;
                }
                else
                {
                    _6394 = _1936.xy;
                }
                float2 _1958 = (_6394 * 2.0) - float2(1.0);
                _6395 = float3(_1958, sqrt(fast::clamp(1.0 - dot(_1958, _1958), 0.0, 1.0)));
            }
            else
            {
                _6395 = (_1936.xyz * 2.0) - float3(1.0);
            }
            float2 _1980 = _6395.xy * _1821._m4.z;
            _6402 = fast::normalize(((_1920 * _1980.x) + ((cross(_1895, _1920) * ((in.m_1902.w < 0.0) ? (-1.0) : 1.0)) * _1980.y)) + (_1895 * _6395.z));
        }
        else
        {
            _6402 = _1895;
        }
        _6401 = _6402;
    }
    else
    {
        _6401 = _1895;
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
    float3 _6515;
    if (_2012)
    {
        _6515 = -_6401;
    }
    else
    {
        _6515 = _6401;
    }
    float3 _2021 = fast::normalize(_180._m4.xyz);
    float3 _2027 = _180._m6.xyz - in.m_1451;
    float3 _2028 = fast::normalize(_2027);
    float3 _2033 = fast::normalize(_2021 + _2028);
    float3 _2039 = _1895 * (gl_FrontFacing ? 1.0 : (-1.0));
    bool _2044 = in.m_2041.x > 0.5;
    float3 _6512;
    float _6539;
    if ((_180._m5.w > 0.5) && _2044)
    {
        float _6458;
        float3 _6459;
        do
        {
            int _2703 = int(_180._m21.x);
            float _2711 = dot(_180._m20.xyz, in.m_1451) + _180._m20.w;
            int _6403;
            _6403 = 0;
            for (;;)
            {
                bool _2717 = _6403 < (_2703 - 1);
                bool _2725;
                if (_2717)
                {
                    _2725 = _2711 > _180._m16[_6403];
                }
                else
                {
                    _2725 = _2717;
                }
                if (_2725)
                {
                    _6403++;
                    continue;
                }
                else
                {
                    break;
                }
            }
            if (_2711 > _180._m16[_6403])
            {
                _6459 = float3(1.0);
                _6458 = 1.0;
                break;
            }
            float _6416;
            do
            {
                float4 _2827 = _180._m14[_6403] * float4(in.m_1451 + (_2039 * _180._m18[_6403]), 1.0);
                float _2830 = _2827.x;
                bool _2831 = _2830 < 0.0;
                bool _2838;
                if (!_2831)
                {
                    _2838 = _2830 > 1.0;
                }
                else
                {
                    _2838 = _2831;
                }
                bool _2845;
                if (!_2838)
                {
                    _2845 = _2827.y < 0.0;
                }
                else
                {
                    _2845 = _2838;
                }
                bool _2852;
                if (!_2845)
                {
                    _2852 = _2827.y > 1.0;
                }
                else
                {
                    _2852 = _2845;
                }
                if (_2852)
                {
                    _6416 = 1.0;
                    break;
                }
                float2 _2865 = float2(float(_6403 & 1), float(_6403 >> 1)) * _180._m23.xy;
                float _2872 = fast::min(_2827.z, 1.0) - _180._m19[_6403];
                float2 _2891 = _180._m22.xy * 0.5;
                float2 _2896 = _2865 + (_2827.xy * _180._m23.xy);
                float4 _2909 = float4(_2865 + _2891, (_2865 + _180._m23.xy) - _2891);
                float _6415;
                do
                {
                    int _2935 = int(_180._m22.z);
                    if (_2935 <= 0)
                    {
                        _6415 = spvDepthCast(_200).sample_compare(_200Smplr, float3(fast::clamp(_2896, _2909.xy, _2909.zw), _2872).xy, _2872);
                        break;
                    }
                    float2 _2958 = (_2896 / _180._m22.xy) + float2(0.5);
                    float2 _2959 = floor(_2958);
                    float2 _2964 = _2958 - _2959;
                    float2 _2967 = _2959 - float2(0.5);
                    bool _2971 = _2935 == 1;
                    spvUnsafeArray<float2, 3> _2919;
                    spvUnsafeArray<float2, 3> _2920;
                    if (_2971)
                    {
                        float2 _2974 = _2964 * 2.0;
                        _2919[0] = float2(3.0) - _2974;
                        _2919[1] = float2(1.0) + _2974;
                        _2920[0] = ((float2(2.0) - _2964) / _2919[0]) - float2(1.0);
                        _2920[1] = (_2964 / _2919[1]) + float2(1.0);
                    }
                    else
                    {
                        float2 _3001 = _2964 * 3.0;
                        _2919[0] = float2(4.0) - _3001;
                        _2919[1] = float2(7.0);
                        _2919[2] = float2(1.0) + _3001;
                        _2920[0] = ((float2(3.0) - (_2964 * 2.0)) / _2919[0]) - float2(2.0);
                        _2920[1] = (float2(3.0) + _2964) / _2919[1];
                        _2920[2] = (_2964 / _2919[2]) + float2(2.0);
                    }
                    int _6892 = _2971 ? 2 : 3;
                    int _6405;
                    float _6408;
                    _6408 = 0.0;
                    _6405 = 0;
                    float _6414;
                    for (; _6405 < _6892; _6408 = _6414, _6405++)
                    {
                        _6414 = _6408;
                        for (int _6411 = 0; _6411 < _6892; )
                        {
                            _6414 += ((_2919[_6411].x * _2919[_6405].y) * spvDepthCast(_200).sample_compare(_200Smplr, float3(fast::clamp(_180._m22.xy * (_2967 + float2(_2920[_6411].x, _2920[_6405].y)), _2909.xy, _2909.zw), _2872).xy, _2872));
                            _6411++;
                            continue;
                        }
                    }
                    _6415 = _6408 * (_2971 ? 0.0625 : 0.0069444444961845874786376953125);
                    break;
                } while(false);
                _6416 = _6415;
                break;
            } while(false);
            float3 _6453;
            float _6456;
            if (_2711 > _180._m17[_6403])
            {
                float _2765 = (_2711 - _180._m17[_6403]) / (_180._m16[_6403] - _180._m17[_6403]);
                int _2767 = _6403 + 1;
                float3 _6454;
                float _6457;
                if (_2767 < _2703)
                {
                    float _6436;
                    do
                    {
                        float4 _3114 = _180._m14[_2767] * float4(in.m_1451 + (_2039 * _180._m18[_2767]), 1.0);
                        float _3117 = _3114.x;
                        bool _3118 = _3117 < 0.0;
                        bool _3125;
                        if (!_3118)
                        {
                            _3125 = _3117 > 1.0;
                        }
                        else
                        {
                            _3125 = _3118;
                        }
                        bool _3132;
                        if (!_3125)
                        {
                            _3132 = _3114.y < 0.0;
                        }
                        else
                        {
                            _3132 = _3125;
                        }
                        bool _3139;
                        if (!_3132)
                        {
                            _3139 = _3114.y > 1.0;
                        }
                        else
                        {
                            _3139 = _3132;
                        }
                        if (_3139)
                        {
                            _6436 = 1.0;
                            break;
                        }
                        float2 _3152 = float2(float(_2767 & 1), float(_2767 >> 1)) * _180._m23.xy;
                        float _3159 = fast::min(_3114.z, 1.0) - _180._m19[_2767];
                        float2 _3178 = _180._m22.xy * 0.5;
                        float2 _3183 = _3152 + (_3114.xy * _180._m23.xy);
                        float4 _3196 = float4(_3152 + _3178, (_3152 + _180._m23.xy) - _3178);
                        float _6435;
                        do
                        {
                            int _3222 = int(_180._m22.z);
                            if (_3222 <= 0)
                            {
                                _6435 = spvDepthCast(_200).sample_compare(_200Smplr, float3(fast::clamp(_3183, _3196.xy, _3196.zw), _3159).xy, _3159);
                                break;
                            }
                            float2 _3245 = (_3183 / _180._m22.xy) + float2(0.5);
                            float2 _3246 = floor(_3245);
                            float2 _3251 = _3245 - _3246;
                            float2 _3254 = _3246 - float2(0.5);
                            bool _3258 = _3222 == 1;
                            spvUnsafeArray<float2, 3> _3206;
                            spvUnsafeArray<float2, 3> _3207;
                            if (_3258)
                            {
                                float2 _3261 = _3251 * 2.0;
                                _3206[0] = float2(3.0) - _3261;
                                _3206[1] = float2(1.0) + _3261;
                                _3207[0] = ((float2(2.0) - _3251) / _3206[0]) - float2(1.0);
                                _3207[1] = (_3251 / _3206[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _3288 = _3251 * 3.0;
                                _3206[0] = float2(4.0) - _3288;
                                _3206[1] = float2(7.0);
                                _3206[2] = float2(1.0) + _3288;
                                _3207[0] = ((float2(3.0) - (_3251 * 2.0)) / _3206[0]) - float2(2.0);
                                _3207[1] = (float2(3.0) + _3251) / _3206[1];
                                _3207[2] = (_3251 / _3206[2]) + float2(2.0);
                            }
                            int _6894 = _3258 ? 2 : 3;
                            int _6425;
                            float _6428;
                            _6428 = 0.0;
                            _6425 = 0;
                            float _6434;
                            for (; _6425 < _6894; _6428 = _6434, _6425++)
                            {
                                _6434 = _6428;
                                for (int _6431 = 0; _6431 < _6894; )
                                {
                                    _6434 += ((_3206[_6431].x * _3206[_6425].y) * spvDepthCast(_200).sample_compare(_200Smplr, float3(fast::clamp(_180._m22.xy * (_3254 + float2(_3207[_6431].x, _3207[_6425].y)), _3196.xy, _3196.zw), _3159).xy, _3159));
                                    _6431++;
                                    continue;
                                }
                            }
                            _6435 = _6428 * (_3258 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _6436 = _6435;
                        break;
                    } while(false);
                    _6457 = mix(_6416, _6436, _2765);
                    _6454 = mix(_554[_6403], _554[_2767], float3(_2765));
                }
                else
                {
                    _6457 = mix(_6416, 1.0, _2765);
                    _6454 = _554[_6403];
                }
                _6456 = _6457;
                _6453 = _6454;
            }
            else
            {
                _6456 = _6416;
                _6453 = _554[_6403];
            }
            _6459 = select(float3(1.0), _6453, bool3(_180._m22.w > 0.5));
            _6458 = _6456;
            break;
        } while(false);
        _6539 = _6458;
        _6512 = _6487 * _6459;
    }
    else
    {
        _6539 = 1.0;
        _6512 = _6487;
    }
    float3 _2070 = _180._m5.xyz * _180._m4.w;
    bool _2074 = _1821._m6.w > 0.5;
    float _6510;
    if (_2074)
    {
        _6510 = 1.0;
    }
    else
    {
        _6510 = 1.0 + (_1821._m4.w * (_1770.sample(_1217, _1840).x - 1.0));
    }
    float3 _6704;
    if (!_2004)
    {
        float _2098 = dot(_6515, _2021);
        float3 _6698;
        if (_180._m29.x > 0.5)
        {
            float _3439 = (_180._m29.z * _6515.x) - (_180._m29.w * _6515.z);
            float _3452 = (_180._m29.w * _6515.x) + (_180._m29.z * _6515.z);
            float _3470 = 1.09254801273345947265625 * _3439;
            spvUnsafeArray<float, 9> _6202 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _6515.y, 0.48860299587249755859375 * _3452, 0.48860299587249755859375 * _3439, _3470 * _6515.y, (1.09254801273345947265625 * _6515.y) * _3452, 0.3153919875621795654296875 * (((3.0 * _3452) * _3452) - 1.0), _3470 * _3452, 0.546274006366729736328125 * ((_3439 * _3439) - (_6515.y * _6515.y)) });
            spvUnsafeArray<float, 9> _3384 = _6202;
            float3 _6697;
            _6697 = float3(0.0);
            for (int _6696 = 0; _6696 < 9; )
            {
                _6697 += (_1215.read(uint2((int2(496, 256) + int2(_6696, 0))), 0).xyz * _3384[_6696]);
                _6696++;
                continue;
            }
            _6698 = fast::max(_6697, float3(0.0)) * _180._m29.y;
        }
        else
        {
            _6698 = mix(_180._m9.xyz, _180._m8.xyz, float3((_6515.y * 0.5) + 0.5)) * _180._m8.w;
        }
        float3 _2148 = (_6512 * ((_6698 * _6510) + ((_2070 * fast::max(_2098, 0.0)) * _6539))) + ((_2070 * ((powr(fast::max(dot(_6515, _2033), 0.0), _1821._m1.w) * _1821._m1.z) * step(0.0, _2098))) * _6539);
        float3 _6705;
        if (_180._m13.w > 0.5)
        {
            float2 _3555 = fast::clamp(floor(gl_FragCoord.xy * _180._m12.xy), float2(0.0), _180._m13.xy - float2(1.0));
            uint _3583 = uint((((fast::clamp(floor((log2(fast::max(dot(_180._m11.xyz, in.m_1451) + _180._m11.w, 9.9999999747524270787835121154785e-07)) * _180._m12.z) + _180._m12.w), 0.0, _180._m13.z - 1.0) * _180._m13.y) + _3555.y) * _180._m13.x) + _3555.x);
            uint _3585 = _3583 >> uint(2);
            uint _3587 = _3583 & 3u;
            uint _3591 = _1584._m0[_3585][_3587] & 65535u;
            uint _3593 = _1584._m0[_3585][_3587] >> uint(16);
            float3 _6706;
            _6706 = _2148;
            float3 _2229;
            spvUnsafeArray<float2, 3> _4001;
            spvUnsafeArray<float2, 3> _4002;
            spvUnsafeArray<float2, 3> _4214;
            spvUnsafeArray<float2, 3> _4215;
            for (uint _6703 = _3591; _6703 < (_3591 + _3593); _6706 = _2229, _6703++)
            {
                uint _3599 = _6703 / 3u;
                uint _3612 = (_1606._m0[_3599 >> uint(2)][_3599 & 3u] >> ((_6703 - (_3599 * 3u)) * 10u)) & 1023u;
                float3 _3629 = _1443._m0[_3612].xyz - in.m_1451;
                float _3632 = dot(_3629, _3629);
                float _3636 = _3632 * _1443._m0[_3612].w;
                float _3641 = fast::clamp(1.0 - (_3636 * _3636), 0.0, 1.0);
                float3 _3646 = _3629 * rsqrt(fast::max(_3632, 9.9999999392252902907785028219223e-09));
                float _3664 = fast::clamp((dot(-_3646, _1487._m0[_3612].xyz) * _1479._m0[_3612].w) + _1487._m0[_3612].w, 0.0, 1.0);
                float3 _3677 = _1479._m0[_3612].xyz * ((((_3641 * _3641) * _3664) * _3664) / fast::max(_3632, 9.9999997473787516355514526367188e-05));
                float3 _6828;
                if (_2044)
                {
                    float _6774;
                    do
                    {
                        uint _3713 = uint(_180._m21.z);
                        if (_3612 < _3713)
                        {
                            float _3735 = _180._m26[_3612].z * fast::max((_180._m15[_3612] * float4(in.m_1451, 1.0)).w, 0.0);
                            float4 _3759 = _180._m15[_3612] * float4((in.m_1451 + (_2039 * (_3735 * _180._m25.x))) + (_3646 * (_3735 * _180._m25.y)), 1.0);
                            float _3761 = _3759.w;
                            if (_3761 <= 0.0)
                            {
                                _6774 = 1.0;
                                break;
                            }
                            float3 _3770 = _3759.xyz / float3(_3761);
                            float _3772 = _3770.x;
                            bool _3773 = _3772 < 0.0;
                            bool _3780;
                            if (!_3773)
                            {
                                _3780 = _3772 > 1.0;
                            }
                            else
                            {
                                _3780 = _3773;
                            }
                            bool _3787;
                            if (!_3780)
                            {
                                _3787 = _3770.y < 0.0;
                            }
                            else
                            {
                                _3787 = _3780;
                            }
                            bool _3794;
                            if (!_3787)
                            {
                                _3794 = _3770.y > 1.0;
                            }
                            else
                            {
                                _3794 = _3787;
                            }
                            bool _3801;
                            if (!_3794)
                            {
                                _3801 = _3770.z > 1.0;
                            }
                            else
                            {
                                _3801 = _3794;
                            }
                            if (_3801)
                            {
                                _6774 = 1.0;
                                break;
                            }
                            float _3807 = _3770.z;
                            float2 _3973 = _180._m22.xy * 0.5;
                            float2 _3978 = _180._m26[_3612].xy + (_3770.xy * _180._m23.zw);
                            float4 _3991 = float4(_180._m26[_3612].xy + _3973, (_180._m26[_3612].xy + _180._m23.zw) - _3973);
                            float _6773;
                            do
                            {
                                int _4017 = int(_180._m22.z);
                                if (_4017 <= 0)
                                {
                                    float2 _4027 = fast::clamp(_3978, _3991.xy, _3991.zw);
                                    _6773 = spvDepthCast(_200).sample_compare(_200Smplr, float3(_4027, _3807).xy, _3807);
                                    break;
                                }
                                float2 _4040 = (_3978 / _180._m22.xy) + float2(0.5);
                                float2 _4041 = floor(_4040);
                                float2 _4046 = _4040 - _4041;
                                float2 _4049 = _4041 - float2(0.5);
                                bool _4053 = _4017 == 1;
                                if (_4053)
                                {
                                    float2 _4056 = _4046 * 2.0;
                                    _4001[0] = float2(3.0) - _4056;
                                    _4001[1] = float2(1.0) + _4056;
                                    _4002[0] = ((float2(2.0) - _4046) / _4001[0]) - float2(1.0);
                                    _4002[1] = (_4046 / _4001[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _4083 = _4046 * 3.0;
                                    _4001[0] = float2(4.0) - _4083;
                                    _4001[1] = float2(7.0);
                                    _4001[2] = float2(1.0) + _4083;
                                    _4002[0] = ((float2(3.0) - (_4046 * 2.0)) / _4001[0]) - float2(2.0);
                                    _4002[1] = (float2(3.0) + _4046) / _4001[1];
                                    _4002[2] = (_4046 / _4001[2]) + float2(2.0);
                                }
                                int _6899 = _4053 ? 2 : 3;
                                int _6763;
                                float _6766;
                                _6766 = 0.0;
                                _6763 = 0;
                                float _6772;
                                for (; _6763 < _6899; _6766 = _6772, _6763++)
                                {
                                    _6772 = _6766;
                                    for (int _6769 = 0; _6769 < _6899; )
                                    {
                                        _6772 += ((_4001[_6769].x * _4001[_6763].y) * spvDepthCast(_200).sample_compare(_200Smplr, float3(fast::clamp(_180._m22.xy * (_4049 + float2(_4002[_6769].x, _4002[_6763].y)), _3991.xy, _3991.zw), _3807).xy, _3807));
                                        _6769++;
                                        continue;
                                    }
                                }
                                _6773 = _6766 * (_4053 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _6774 = _6773;
                            break;
                        }
                        uint _3817 = _3612 - _3713;
                        if (_3817 >= uint(_180._m21.w))
                        {
                            _6774 = 1.0;
                            break;
                        }
                        float _3838 = _180._m27[_3817].w * length(in.m_1451 - _180._m27[_3817].xyz);
                        float3 _3856 = ((in.m_1451 + (_2039 * (_3838 * _180._m25.x))) + (_3646 * (_3838 * _180._m25.y))) - _180._m27[_3817].xyz;
                        float3 _3858 = abs(_3856);
                        float _3860 = _3858.x;
                        float _3862 = _3858.y;
                        bool _3863 = _3860 >= _3862;
                        bool _3871;
                        if (_3863)
                        {
                            _3871 = _3860 >= _3858.z;
                        }
                        else
                        {
                            _3871 = _3863;
                        }
                        float _6748;
                        int _6750;
                        if (_3871)
                        {
                            _6750 = (_3856.x > 0.0) ? 0 : 1;
                            _6748 = _3860;
                        }
                        else
                        {
                            float _3883 = _3858.z;
                            bool _3884 = _3862 >= _3883;
                            int _6751;
                            if (_3884)
                            {
                                _6751 = (_3856.y > 0.0) ? 2 : 3;
                            }
                            else
                            {
                                _6751 = (_3856.z > 0.0) ? 4 : 5;
                            }
                            _6750 = _6751;
                            _6748 = _3884 ? _3862 : _3883;
                        }
                        if (_6748 <= 0.0)
                        {
                            _6774 = 1.0;
                            break;
                        }
                        float2 _3921 = float2(dot(_3856, _858[_6750]), dot(_3856, _867[_6750])) / float2(_6748 * _180._m24.z);
                        float _3928 = _180._m28[_3817].z + (_180._m28[_3817].w / _6748);
                        if (_3928 > 1.0)
                        {
                            _6774 = 1.0;
                            break;
                        }
                        float2 _3946 = _180._m28[_3817].xy + (float2(float(spvSMod(_6750, 3)), float(_6750 / 3)) * _180._m24.xy);
                        float2 _4186 = _180._m22.xy * 0.5;
                        float2 _4191 = _3946 + (float2(0.5 + (0.5 * _3921.x), 0.5 - (0.5 * _3921.y)) * _180._m24.xy);
                        float4 _4204 = float4(_3946 + _4186, (_3946 + _180._m24.xy) - _4186);
                        float _6762;
                        do
                        {
                            int _4230 = int(_180._m22.z);
                            if (_4230 <= 0)
                            {
                                _6762 = spvDepthCast(_200).sample_compare(_200Smplr, float3(fast::clamp(_4191, _4204.xy, _4204.zw), _3928).xy, _3928);
                                break;
                            }
                            float2 _4253 = (_4191 / _180._m22.xy) + float2(0.5);
                            float2 _4254 = floor(_4253);
                            float2 _4259 = _4253 - _4254;
                            float2 _4262 = _4254 - float2(0.5);
                            bool _4266 = _4230 == 1;
                            if (_4266)
                            {
                                float2 _4269 = _4259 * 2.0;
                                _4214[0] = float2(3.0) - _4269;
                                _4214[1] = float2(1.0) + _4269;
                                _4215[0] = ((float2(2.0) - _4259) / _4214[0]) - float2(1.0);
                                _4215[1] = (_4259 / _4214[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _4296 = _4259 * 3.0;
                                _4214[0] = float2(4.0) - _4296;
                                _4214[1] = float2(7.0);
                                _4214[2] = float2(1.0) + _4296;
                                _4215[0] = ((float2(3.0) - (_4259 * 2.0)) / _4214[0]) - float2(2.0);
                                _4215[1] = (float2(3.0) + _4259) / _4214[1];
                                _4215[2] = (_4259 / _4214[2]) + float2(2.0);
                            }
                            int _6902 = _4266 ? 2 : 3;
                            int _6752;
                            float _6755;
                            _6755 = 0.0;
                            _6752 = 0;
                            float _6761;
                            for (; _6752 < _6902; _6755 = _6761, _6752++)
                            {
                                _6761 = _6755;
                                for (int _6758 = 0; _6758 < _6902; )
                                {
                                    _6761 += ((_4214[_6758].x * _4214[_6752].y) * spvDepthCast(_200).sample_compare(_200Smplr, float3(fast::clamp(_180._m22.xy * (_4262 + float2(_4215[_6758].x, _4215[_6752].y)), _4204.xy, _4204.zw), _3928).xy, _3928));
                                    _6758++;
                                    continue;
                                }
                            }
                            _6762 = _6755 * (_4266 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _6774 = _6762;
                        break;
                    } while(false);
                    _6828 = _3677 * _6774;
                }
                else
                {
                    _6828 = _3677;
                }
                float _2200 = dot(_6515, _3646);
                _2229 = _6706 + (((_6512 * fast::max(_2200, 0.0)) * _6828) + (_6828 * ((powr(fast::max(dot(_6515, fast::normalize(_3646 + _2028)), 0.0), _1821._m1.w) * _1821._m1.z) * step(0.0, _2200))));
            }
            _6705 = _6706;
        }
        else
        {
            _6705 = _2148;
        }
        _6704 = _6705;
    }
    else
    {
        float4 _2239 = _2234.sample(_1217, _1840);
        float _2246 = fast::clamp(_1821._m4.x * _2239.z, 0.0, 1.0);
        float _2254 = fast::clamp(_1821._m4.y * _2239.y, 0.04500000178813934326171875, 1.0);
        float _2258 = _2254 * _2254;
        float3 _2263 = _6512 * (1.0 - _2246);
        float3 _2269 = mix(float3(0.039999999105930328369140625), _6512, float3(_2246));
        float _2274 = fast::max(dot(_6515, _2028), 9.9999997473787516355514526367188e-05);
        float _2279 = fast::clamp(dot(_6515, _2021), 0.0, 1.0);
        float _2284 = fast::clamp(dot(_6515, _2033), 0.0, 1.0);
        float3 _4398 = float3(1.0) - _2269;
        float3 _4401 = _2269 + (_4398 * powr(1.0 - fast::clamp(dot(_2028, _2033), 0.0, 1.0), 5.0));
        float _4408 = _2258 * _2258;
        float _4413 = _4408 - 1.0;
        float _4415 = ((_2284 * _2284) * _4413) + 1.0;
        float _4435 = 1.0 - _4408;
        float _4439 = sqrt(((_2274 * _2274) * _4435) + _4408);
        float3 _6558;
        float2 _6573;
        float3 _6585;
        if (_180._m29.x > 0.5)
        {
            float4 _4472 = _1321.sample(_1323, (((float2(_2274, _2254) * 31.0) + float2(0.5)) * float2(0.03125)));
            float _4531 = (_180._m29.z * _6515.x) - (_180._m29.w * _6515.z);
            float _4544 = (_180._m29.w * _6515.x) + (_180._m29.z * _6515.z);
            float _4562 = 1.09254801273345947265625 * _4531;
            spvUnsafeArray<float, 9> _6183 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _6515.y, 0.48860299587249755859375 * _4544, 0.48860299587249755859375 * _4531, _4562 * _6515.y, (1.09254801273345947265625 * _6515.y) * _4544, 0.3153919875621795654296875 * (((3.0 * _4544) * _4544) - 1.0), _4562 * _4544, 0.546274006366729736328125 * ((_4531 * _4531) - (_6515.y * _6515.y)) });
            spvUnsafeArray<float, 9> _4476 = _6183;
            float3 _6541;
            _6541 = float3(0.0);
            for (int _6540 = 0; _6540 < 9; )
            {
                _6541 += (_1215.read(uint2((int2(496, 256) + int2(_6540, 0))), 0).xyz * _4476[_6540]);
                _6540++;
                continue;
            }
            float3 _2345 = reflect(-_2028, _6515);
            float _4657 = _2345.x;
            float _4662 = _2345.z;
            float2 _4694 = float2((precise::atan2((_180._m29.z * _4657) - (_180._m29.w * _4662), -((_180._m29.w * _4657) + (_180._m29.z * _4662))) * 0.15915493667125701904296875) + 0.5, acos(fast::clamp(_2345.y, -1.0, 1.0)) * 0.3183098733425140380859375);
            float _4626 = _2254 * 5.0;
            int _4629 = min(int(_4626), 4);
            float2 _4715 = (_4694 * float2(_1277[_4629].zw)) - float2(0.5);
            float2 _4717 = floor(_4715);
            float2 _4720 = _4715 - _4717;
            int _4723 = int(_4717.x);
            int _4726 = int(_4717.y);
            int _6543;
            if (_4723 < 0)
            {
                _6543 = _4723 + _1277[_4629].z;
            }
            else
            {
                _6543 = _4723;
            }
            int _6544;
            if (_6543 >= _1277[_4629].z)
            {
                _6544 = _6543 - _1277[_4629].z;
            }
            else
            {
                _6544 = _6543;
            }
            int _4746 = _6544 + 1;
            int _6903 = (_4746 == _1277[_4629].z) ? 0 : _4746;
            int _4761 = min((_4726 + 1), (_1277[_4629].w - 1));
            int _4763 = max(_4726, 0);
            float3 _4816 = float3(_4720.x);
            int _4636 = _4629 + 1;
            float2 _4848 = (_4694 * float2(_1277[_4636].zw)) - float2(0.5);
            float2 _4850 = floor(_4848);
            float2 _4853 = _4848 - _4850;
            int _4856 = int(_4850.x);
            int _4859 = int(_4850.y);
            int _6550;
            if (_4856 < 0)
            {
                _6550 = _4856 + _1277[_4636].z;
            }
            else
            {
                _6550 = _4856;
            }
            int _6551;
            if (_6550 >= _1277[_4636].z)
            {
                _6551 = _6550 - _1277[_4636].z;
            }
            else
            {
                _6551 = _6550;
            }
            int _4879 = _6551 + 1;
            int _6904 = (_4879 == _1277[_4636].z) ? 0 : _4879;
            int _4894 = min((_4859 + 1), (_1277[_4636].w - 1));
            int _4896 = max(_4859, 0);
            float3 _4949 = float3(_4853.x);
            float3 _4651 = mix(mix(mix(_1215.read(uint2((_1277[_4629].xy + int2(_6544, _4763))), 0).xyz, _1215.read(uint2((_1277[_4629].xy + int2(_6903, _4763))), 0).xyz, _4816), mix(_1215.read(uint2((_1277[_4629].xy + int2(_6544, _4761))), 0).xyz, _1215.read(uint2((_1277[_4629].xy + int2(_6903, _4761))), 0).xyz, _4816), float3(_4720.y)), mix(mix(_1215.read(uint2((_1277[_4636].xy + int2(_6551, _4896))), 0).xyz, _1215.read(uint2((_1277[_4636].xy + int2(_6904, _4896))), 0).xyz, _4949), mix(_1215.read(uint2((_1277[_4636].xy + int2(_6551, _4894))), 0).xyz, _1215.read(uint2((_1277[_4636].xy + int2(_6904, _4894))), 0).xyz, _4949), float3(_4853.y)), float3(_4626 - float(_4629))) * _180._m29.y;
            _6585 = fast::max(_6541, float3(0.0)) * _180._m29.y;
            _6573 = _4472.xy;
            _6558 = _4651;
        }
        else
        {
            float4 _4967 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * _2254) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);
            float _4969 = _4967.x;
            float3 _5004 = mix(_180._m9.xyz, _180._m8.xyz, float3((_6515.y * 0.5) + 0.5)) * _180._m8.w;
            _6585 = _5004;
            _6573 = (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_4969 * _4969, exp2((-9.27999973297119140625) * _2274)) * _4969) + _4967.y)) + _4967.zw;
            _6558 = mix(mix(_180._m9.xyz, _180._m8.xyz, float3((reflect(-_2028, _6515).y * 0.5) + 0.5)) * _180._m8.w, _5004, float3(_2254));
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
        float3 _6594;
        if (_2377)
        {
            float3 _6570;
            do
            {
                float _5083 = ((_180._m32.x * (1.0 - smoothstep(_180._m33.x * 0.5, _180._m33.x, abs(dot(_180._m31.xyz, in.m_1451) - _180._m31.w)))) * smoothstep(0.5, 0.89999997615814208984375, dot(_2039, _180._m31.xyz))) * (1.0 - smoothstep(_180._m32.y * 0.5, _180._m32.y, _2254));
                if (_5083 <= 0.0)
                {
                    _6570 = _6558;
                    break;
                }
                float4 _5108 = _180._m30 * float4(in.m_1451 + ((_6515 - (_180._m31.xyz * dot(_6515, _180._m31.xyz))) * _180._m32.w), 1.0);
                float2 _5121 = ((float2(_5108.x, -_5108.y) / float2(_5108.w)) * 0.5) + float2(0.5);
                float _5125 = _180._m32.z * _2254;
                float3 _6568;
                float _6569;
                _6569 = 0.0;
                _6568 = float3(0.0);
                for (int _6567 = 0; _6567 < 12; )
                {
                    float _5132 = float(_6567);
                    float _5140 = _5132 * 2.3999631404876708984375;
                    float2 _5152 = _5121 + (float2(cos(_5140) * _180._m33.y, sin(_5140)) * (sqrt((_5132 + 0.5) * 0.083333335816860198974609375) * _5125));
                    float2 _5157 = fast::min(_5152, float2(1.0) - _5152);
                    float _5163 = smoothstep(0.0, 0.039999999105930328369140625, fast::min(_5157.x, _5157.y));
                    float4 _5171 = _1770.sample(_1217, fast::clamp(_5152, float2(0.0), float2(1.0)), level(0.0));
                    float3 _5173 = _5171.xyz;
                    _6569 += (_5171.w * _5163);
                    _6568 += ((_5173 / (float3(1.0) - fast::min(_5173, float3(0.99500000476837158203125)))) * _5163);
                    _6567++;
                    continue;
                }
                _6570 = mix(_6558, (_6568 * float3(0.083333335816860198974609375)) + (_6558 * (1.0 - (_6569 * 0.083333335816860198974609375))), float3(_5083));
                break;
            } while(false);
            _6594 = _6570;
        }
        else
        {
            _6594 = _6558;
        }
        float3 _2397 = (_2269 * _6573.x) + float3(_6573.y);
        float3 _2413 = ((((((float3(1.0) - _4401) * _2263) + ((_4401 * ((_4408 / ((3.1415927410125732421875 * _4415) * _4415)) * (0.5 / fast::max((_2279 * _4439) + (_2274 * sqrt(((_2279 * _2279) * _4435) + _4408)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875)) * _2279) * _2070) * _6539) + (((((float3(1.0) - _2397) * _2263) * _6585) + (_2397 * _6594)) * _6510);
        float3 _6707;
        if (_180._m13.w > 0.5)
        {
            float2 _5237 = fast::clamp(floor(gl_FragCoord.xy * _180._m12.xy), float2(0.0), _180._m13.xy - float2(1.0));
            uint _5265 = uint((((fast::clamp(floor((log2(fast::max(dot(_180._m11.xyz, in.m_1451) + _180._m11.w, 9.9999999747524270787835121154785e-07)) * _180._m12.z) + _180._m12.w), 0.0, _180._m13.z - 1.0) * _180._m13.y) + _5237.y) * _180._m13.x) + _5237.x);
            uint _5267 = _5265 >> uint(2);
            uint _5269 = _5265 & 3u;
            uint _5273 = _1584._m0[_5267][_5269] & 65535u;
            uint _5275 = _1584._m0[_5267][_5269] >> uint(16);
            float3 _6662;
            _6662 = _2413;
            float3 _2513;
            spvUnsafeArray<float2, 3> _5683;
            spvUnsafeArray<float2, 3> _5684;
            spvUnsafeArray<float2, 3> _5896;
            spvUnsafeArray<float2, 3> _5897;
            for (uint _6595 = _5273; _6595 < (_5273 + _5275); _6662 = _2513, _6595++)
            {
                uint _5281 = _6595 / 3u;
                uint _5294 = (_1606._m0[_5281 >> uint(2)][_5281 & 3u] >> ((_6595 - (_5281 * 3u)) * 10u)) & 1023u;
                float3 _5311 = _1443._m0[_5294].xyz - in.m_1451;
                float _5314 = dot(_5311, _5311);
                float _5318 = _5314 * _1443._m0[_5294].w;
                float _5323 = fast::clamp(1.0 - (_5318 * _5318), 0.0, 1.0);
                float3 _5328 = _5311 * rsqrt(fast::max(_5314, 9.9999999392252902907785028219223e-09));
                float _5346 = fast::clamp((dot(-_5328, _1487._m0[_5294].xyz) * _1479._m0[_5294].w) + _1487._m0[_5294].w, 0.0, 1.0);
                float3 _5359 = _1479._m0[_5294].xyz * ((((_5323 * _5323) * _5346) * _5346) / fast::max(_5314, 9.9999997473787516355514526367188e-05));
                float3 _6660;
                if (_2044)
                {
                    float _6622;
                    do
                    {
                        uint _5395 = uint(_180._m21.z);
                        if (_5294 < _5395)
                        {
                            float _5417 = _180._m26[_5294].z * fast::max((_180._m15[_5294] * float4(in.m_1451, 1.0)).w, 0.0);
                            float4 _5441 = _180._m15[_5294] * float4((in.m_1451 + (_2039 * (_5417 * _180._m25.x))) + (_5328 * (_5417 * _180._m25.y)), 1.0);
                            float _5443 = _5441.w;
                            if (_5443 <= 0.0)
                            {
                                _6622 = 1.0;
                                break;
                            }
                            float3 _5452 = _5441.xyz / float3(_5443);
                            float _5454 = _5452.x;
                            bool _5455 = _5454 < 0.0;
                            bool _5462;
                            if (!_5455)
                            {
                                _5462 = _5454 > 1.0;
                            }
                            else
                            {
                                _5462 = _5455;
                            }
                            bool _5469;
                            if (!_5462)
                            {
                                _5469 = _5452.y < 0.0;
                            }
                            else
                            {
                                _5469 = _5462;
                            }
                            bool _5476;
                            if (!_5469)
                            {
                                _5476 = _5452.y > 1.0;
                            }
                            else
                            {
                                _5476 = _5469;
                            }
                            bool _5483;
                            if (!_5476)
                            {
                                _5483 = _5452.z > 1.0;
                            }
                            else
                            {
                                _5483 = _5476;
                            }
                            if (_5483)
                            {
                                _6622 = 1.0;
                                break;
                            }
                            float _5489 = _5452.z;
                            float2 _5655 = _180._m22.xy * 0.5;
                            float2 _5660 = _180._m26[_5294].xy + (_5452.xy * _180._m23.zw);
                            float4 _5673 = float4(_180._m26[_5294].xy + _5655, (_180._m26[_5294].xy + _180._m23.zw) - _5655);
                            float _6621;
                            do
                            {
                                int _5699 = int(_180._m22.z);
                                if (_5699 <= 0)
                                {
                                    float2 _5709 = fast::clamp(_5660, _5673.xy, _5673.zw);
                                    _6621 = spvDepthCast(_200).sample_compare(_200Smplr, float3(_5709, _5489).xy, _5489);
                                    break;
                                }
                                float2 _5722 = (_5660 / _180._m22.xy) + float2(0.5);
                                float2 _5723 = floor(_5722);
                                float2 _5728 = _5722 - _5723;
                                float2 _5731 = _5723 - float2(0.5);
                                bool _5735 = _5699 == 1;
                                if (_5735)
                                {
                                    float2 _5738 = _5728 * 2.0;
                                    _5683[0] = float2(3.0) - _5738;
                                    _5683[1] = float2(1.0) + _5738;
                                    _5684[0] = ((float2(2.0) - _5728) / _5683[0]) - float2(1.0);
                                    _5684[1] = (_5728 / _5683[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _5765 = _5728 * 3.0;
                                    _5683[0] = float2(4.0) - _5765;
                                    _5683[1] = float2(7.0);
                                    _5683[2] = float2(1.0) + _5765;
                                    _5684[0] = ((float2(3.0) - (_5728 * 2.0)) / _5683[0]) - float2(2.0);
                                    _5684[1] = (float2(3.0) + _5728) / _5683[1];
                                    _5684[2] = (_5728 / _5683[2]) + float2(2.0);
                                }
                                int _6906 = _5735 ? 2 : 3;
                                int _6611;
                                float _6614;
                                _6614 = 0.0;
                                _6611 = 0;
                                float _6620;
                                for (; _6611 < _6906; _6614 = _6620, _6611++)
                                {
                                    _6620 = _6614;
                                    for (int _6617 = 0; _6617 < _6906; )
                                    {
                                        _6620 += ((_5683[_6617].x * _5683[_6611].y) * spvDepthCast(_200).sample_compare(_200Smplr, float3(fast::clamp(_180._m22.xy * (_5731 + float2(_5684[_6617].x, _5684[_6611].y)), _5673.xy, _5673.zw), _5489).xy, _5489));
                                        _6617++;
                                        continue;
                                    }
                                }
                                _6621 = _6614 * (_5735 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _6622 = _6621;
                            break;
                        }
                        uint _5499 = _5294 - _5395;
                        if (_5499 >= uint(_180._m21.w))
                        {
                            _6622 = 1.0;
                            break;
                        }
                        float _5520 = _180._m27[_5499].w * length(in.m_1451 - _180._m27[_5499].xyz);
                        float3 _5538 = ((in.m_1451 + (_2039 * (_5520 * _180._m25.x))) + (_5328 * (_5520 * _180._m25.y))) - _180._m27[_5499].xyz;
                        float3 _5540 = abs(_5538);
                        float _5542 = _5540.x;
                        float _5544 = _5540.y;
                        bool _5545 = _5542 >= _5544;
                        bool _5553;
                        if (_5545)
                        {
                            _5553 = _5542 >= _5540.z;
                        }
                        else
                        {
                            _5553 = _5545;
                        }
                        float _6596;
                        int _6598;
                        if (_5553)
                        {
                            _6598 = (_5538.x > 0.0) ? 0 : 1;
                            _6596 = _5542;
                        }
                        else
                        {
                            float _5565 = _5540.z;
                            bool _5566 = _5544 >= _5565;
                            int _6599;
                            if (_5566)
                            {
                                _6599 = (_5538.y > 0.0) ? 2 : 3;
                            }
                            else
                            {
                                _6599 = (_5538.z > 0.0) ? 4 : 5;
                            }
                            _6598 = _6599;
                            _6596 = _5566 ? _5544 : _5565;
                        }
                        if (_6596 <= 0.0)
                        {
                            _6622 = 1.0;
                            break;
                        }
                        float2 _5603 = float2(dot(_5538, _858[_6598]), dot(_5538, _867[_6598])) / float2(_6596 * _180._m24.z);
                        float _5610 = _180._m28[_5499].z + (_180._m28[_5499].w / _6596);
                        if (_5610 > 1.0)
                        {
                            _6622 = 1.0;
                            break;
                        }
                        float2 _5628 = _180._m28[_5499].xy + (float2(float(spvSMod(_6598, 3)), float(_6598 / 3)) * _180._m24.xy);
                        float2 _5868 = _180._m22.xy * 0.5;
                        float2 _5873 = _5628 + (float2(0.5 + (0.5 * _5603.x), 0.5 - (0.5 * _5603.y)) * _180._m24.xy);
                        float4 _5886 = float4(_5628 + _5868, (_5628 + _180._m24.xy) - _5868);
                        float _6610;
                        do
                        {
                            int _5912 = int(_180._m22.z);
                            if (_5912 <= 0)
                            {
                                _6610 = spvDepthCast(_200).sample_compare(_200Smplr, float3(fast::clamp(_5873, _5886.xy, _5886.zw), _5610).xy, _5610);
                                break;
                            }
                            float2 _5935 = (_5873 / _180._m22.xy) + float2(0.5);
                            float2 _5936 = floor(_5935);
                            float2 _5941 = _5935 - _5936;
                            float2 _5944 = _5936 - float2(0.5);
                            bool _5948 = _5912 == 1;
                            if (_5948)
                            {
                                float2 _5951 = _5941 * 2.0;
                                _5896[0] = float2(3.0) - _5951;
                                _5896[1] = float2(1.0) + _5951;
                                _5897[0] = ((float2(2.0) - _5941) / _5896[0]) - float2(1.0);
                                _5897[1] = (_5941 / _5896[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _5978 = _5941 * 3.0;
                                _5896[0] = float2(4.0) - _5978;
                                _5896[1] = float2(7.0);
                                _5896[2] = float2(1.0) + _5978;
                                _5897[0] = ((float2(3.0) - (_5941 * 2.0)) / _5896[0]) - float2(2.0);
                                _5897[1] = (float2(3.0) + _5941) / _5896[1];
                                _5897[2] = (_5941 / _5896[2]) + float2(2.0);
                            }
                            int _6909 = _5948 ? 2 : 3;
                            int _6600;
                            float _6603;
                            _6603 = 0.0;
                            _6600 = 0;
                            float _6609;
                            for (; _6600 < _6909; _6603 = _6609, _6600++)
                            {
                                _6609 = _6603;
                                for (int _6606 = 0; _6606 < _6909; )
                                {
                                    _6609 += ((_5896[_6606].x * _5896[_6600].y) * spvDepthCast(_200).sample_compare(_200Smplr, float3(fast::clamp(_180._m22.xy * (_5944 + float2(_5897[_6606].x, _5897[_6600].y)), _5886.xy, _5886.zw), _5610).xy, _5610));
                                    _6606++;
                                    continue;
                                }
                            }
                            _6610 = _6603 * (_5948 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _6622 = _6610;
                        break;
                    } while(false);
                    _6660 = _5359 * _6622;
                }
                else
                {
                    _6660 = _5359;
                }
                float3 _2465 = fast::normalize(_5328 + _2028);
                float _2470 = fast::clamp(dot(_6515, _5328), 0.0, 1.0);
                float _2475 = fast::clamp(dot(_6515, _2465), 0.0, 1.0);
                float3 _6083 = _2269 + (_4398 * powr(1.0 - fast::clamp(dot(_2028, _2465), 0.0, 1.0), 5.0));
                float _6097 = ((_2475 * _2475) * _4413) + 1.0;
                _2513 = _6662 + (((((float3(1.0) - _6083) * _2263) + ((_6083 * ((_4408 / ((3.1415927410125732421875 * _6097) * _6097)) * (0.5 / fast::max((_2470 * _4439) + (_2274 * sqrt(((_2470 * _2470) * _4435) + _4408)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875)) * _2470) * _6660);
            }
            _6707 = _6662;
        }
        else
        {
            _6707 = _2413;
        }
        _6704 = _6707;
    }
    float4 _2530 = _2525.sample(_1217, _1840);
    float _2548 = -length(_2027);
    float _6745;
    if (_180._m9.w != 0.0)
    {
        float _2572 = _180._m9.w * (in.m_1451 - _180._m6.xyz).y;
        float _6742;
        if (abs(_2572) < 9.9999997473787516355514526367188e-05)
        {
            _6742 = 1.0 - (0.5 * _2572);
        }
        else
        {
            _6742 = (1.0 - exp(fast::min(-_2572, 60.0))) / _2572;
        }
        _6745 = 1.0 - exp((_2548 * (_180._m7.w * exp(fast::min((-_180._m9.w) * (_180._m6.y - _180._m6.w), 30.0)))) * _6742);
    }
    else
    {
        _6745 = 1.0 - exp(_2548 * _180._m7.w);
    }
    float3 _2623 = mix(mix(_6704, _6512, float3(_1821._m1.y)) + ((_1821._m5.xyz * _2530.xyz) * (float3(1.0) + in.m_2041.yzw)), _180._m7.xyz, float3(_6745));
    float3 _6746;
    if (_180._m33.w > 0.5)
    {
        _6746 = _2623 / (float3(1.0) + _2623);
    }
    else
    {
        _6746 = _2623;
    }
    out.m_2635 = float4(_6746, (in.m_1849.w * _1821._m0.w) * _1847.w);
    float2 _6747;
    do
    {
        if (in.m_2645.w <= 0.0)
        {
            _6747 = float2(0.0);
            break;
        }
        _6747 = ((in.m_2645.xy / float2(in.m_2645.w)) - (in.m_2644.xy / float2(in.m_2644.w))) * float2(0.5, -0.5);
        break;
    } while(false);
    _2643 = _6747;
    return out;
}

