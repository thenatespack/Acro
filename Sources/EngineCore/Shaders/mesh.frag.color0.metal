// Generated from mesh.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: f689d8b5f69e2a30
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
    float4 m_2647 [[color(0)]];
};

struct fragment_main_in
{
    float3 m_1451 [[user(locn0)]];
    float3 m_1893 [[user(locn1)]];
    float2 m_1826 [[user(locn2)]];
    float4 m_1849 [[user(locn3)]];
    float4 m_2041 [[user(locn5)]];
    float4 m_2656 [[user(locn6)]];
    float4 m_2657 [[user(locn7)]];
    float4 m_1902 [[user(locn8)]];
};

fragment fragment_main_out fragment_main(fragment_main_in in [[stage_in]], constant _1819& _1821 [[buffer(2)]], constant _1441& _1443 [[buffer(3)]], constant _1477& _1479 [[buffer(4)]], constant _1485& _1487 [[buffer(5)]], constant _1582& _1584 [[buffer(6)]], constant _1604& _1606 [[buffer(7)]], constant _178& _180 [[buffer(15)]], texture2d<float> _200 [[texture(0)]], texture2d<float> _1842 [[texture(1)]], texture2d<float> _2246 [[texture(2)]], texture2d<float> _1931 [[texture(3)]], texture2d<float> _1770 [[texture(4)]], texture2d<float> _2537 [[texture(5)]], texture2d<float> _1215 [[texture(6)]], texture2d<float> _1321 [[texture(7)]], sampler _200Smplr [[sampler(0)]], sampler _1217 [[sampler(1)]], sampler _1323 [[sampler(7)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])
{
    float2 _2655;
    fragment_main_out out = {};
    float2 _1840 = float2(dot(_1821._m2.xy, in.m_1826) + _1821._m2.z, dot(_1821._m3.xy, in.m_1826) + _1821._m3.z);
    float4 _1847 = _1842.sample(_1217, _1840);
    float3 _1858 = (in.m_1849.xyz * _1821._m0.xyz) * _1847.xyz;
    float3 _6499;
    if (_1821._m1.x > 0.5)
    {
        float2 _1879 = floor(in.m_1451.xz * float2(0.5));
        _6499 = _1858 * ((mod(abs(_1879.x + _1879.y), 2.0) < 0.5) ? 1.0 : 0.75);
    }
    else
    {
        _6499 = _1858;
    }
    float3 _1895 = fast::normalize(in.m_1893);
    float3 _6413;
    if (_1821._m6.y > 0.5)
    {
        float3 _1911 = in.m_1902.xyz - (_1895 * dot(_1895, in.m_1902.xyz));
        float3 _6414;
        if (dot(_1911, _1911) > 9.9999999600419720025001879548654e-13)
        {
            float3 _1920 = fast::normalize(_1911);
            float4 _1936 = _1931.sample(_1217, _1840);
            float3 _6407;
            if (_1821._m6.z > 0.5)
            {
                float2 _6406;
                if (_1821._m6.z > 1.5)
                {
                    _6406 = _1936.xw;
                }
                else
                {
                    _6406 = _1936.xy;
                }
                float2 _1958 = (_6406 * 2.0) - float2(1.0);
                _6407 = float3(_1958, sqrt(fast::clamp(1.0 - dot(_1958, _1958), 0.0, 1.0)));
            }
            else
            {
                _6407 = (_1936.xyz * 2.0) - float3(1.0);
            }
            float2 _1980 = _6407.xy * _1821._m4.z;
            _6414 = fast::normalize(((_1920 * _1980.x) + ((cross(_1895, _1920) * ((in.m_1902.w < 0.0) ? (-1.0) : 1.0)) * _1980.y)) + (_1895 * _6407.z));
        }
        else
        {
            _6414 = _1895;
        }
        _6413 = _6414;
    }
    else
    {
        _6413 = _1895;
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
    float3 _6529;
    if (_2012)
    {
        _6529 = -_6413;
    }
    else
    {
        _6529 = _6413;
    }
    float3 _2021 = fast::normalize(_180._m4.xyz);
    float3 _2027 = _180._m6.xyz - in.m_1451;
    float3 _2028 = fast::normalize(_2027);
    float3 _2033 = fast::normalize(_2021 + _2028);
    float3 _2039 = _1895 * (gl_FrontFacing ? 1.0 : (-1.0));
    bool _2044 = in.m_2041.x > 0.5;
    float3 _6525;
    float _6554;
    if ((_180._m5.w > 0.5) && _2044)
    {
        float _6470;
        float3 _6471;
        do
        {
            int _2715 = int(_180._m21.x);
            float _2723 = dot(_180._m20.xyz, in.m_1451) + _180._m20.w;
            int _6415;
            _6415 = 0;
            for (;;)
            {
                bool _2729 = _6415 < (_2715 - 1);
                bool _2737;
                if (_2729)
                {
                    _2737 = _2723 > _180._m16[_6415];
                }
                else
                {
                    _2737 = _2729;
                }
                if (_2737)
                {
                    _6415++;
                    continue;
                }
                else
                {
                    break;
                }
            }
            if (_2723 > _180._m16[_6415])
            {
                _6471 = float3(1.0);
                _6470 = 1.0;
                break;
            }
            float _6428;
            do
            {
                float4 _2839 = _180._m14[_6415] * float4(in.m_1451 + (_2039 * _180._m18[_6415]), 1.0);
                float _2842 = _2839.x;
                bool _2843 = _2842 < 0.0;
                bool _2850;
                if (!_2843)
                {
                    _2850 = _2842 > 1.0;
                }
                else
                {
                    _2850 = _2843;
                }
                bool _2857;
                if (!_2850)
                {
                    _2857 = _2839.y < 0.0;
                }
                else
                {
                    _2857 = _2850;
                }
                bool _2864;
                if (!_2857)
                {
                    _2864 = _2839.y > 1.0;
                }
                else
                {
                    _2864 = _2857;
                }
                if (_2864)
                {
                    _6428 = 1.0;
                    break;
                }
                float2 _2877 = float2(float(_6415 & 1), float(_6415 >> 1)) * _180._m23.xy;
                float _2884 = fast::min(_2839.z, 1.0) - _180._m19[_6415];
                float2 _2903 = _180._m22.xy * 0.5;
                float2 _2908 = _2877 + (_2839.xy * _180._m23.xy);
                float4 _2921 = float4(_2877 + _2903, (_2877 + _180._m23.xy) - _2903);
                float _6427;
                do
                {
                    int _2947 = int(_180._m22.z);
                    if (_2947 <= 0)
                    {
                        _6427 = spvDepthCast(_200).sample_compare(_200Smplr, float3(fast::clamp(_2908, _2921.xy, _2921.zw), _2884).xy, _2884);
                        break;
                    }
                    float2 _2970 = (_2908 / _180._m22.xy) + float2(0.5);
                    float2 _2971 = floor(_2970);
                    float2 _2976 = _2970 - _2971;
                    float2 _2979 = _2971 - float2(0.5);
                    bool _2983 = _2947 == 1;
                    spvUnsafeArray<float2, 3> _2931;
                    spvUnsafeArray<float2, 3> _2932;
                    if (_2983)
                    {
                        float2 _2986 = _2976 * 2.0;
                        _2931[0] = float2(3.0) - _2986;
                        _2931[1] = float2(1.0) + _2986;
                        _2932[0] = ((float2(2.0) - _2976) / _2931[0]) - float2(1.0);
                        _2932[1] = (_2976 / _2931[1]) + float2(1.0);
                    }
                    else
                    {
                        float2 _3013 = _2976 * 3.0;
                        _2931[0] = float2(4.0) - _3013;
                        _2931[1] = float2(7.0);
                        _2931[2] = float2(1.0) + _3013;
                        _2932[0] = ((float2(3.0) - (_2976 * 2.0)) / _2931[0]) - float2(2.0);
                        _2932[1] = (float2(3.0) + _2976) / _2931[1];
                        _2932[2] = (_2976 / _2931[2]) + float2(2.0);
                    }
                    int _6922 = _2983 ? 2 : 3;
                    int _6417;
                    float _6420;
                    _6420 = 0.0;
                    _6417 = 0;
                    float _6426;
                    for (; _6417 < _6922; _6420 = _6426, _6417++)
                    {
                        _6426 = _6420;
                        for (int _6423 = 0; _6423 < _6922; )
                        {
                            _6426 += ((_2931[_6423].x * _2931[_6417].y) * spvDepthCast(_200).sample_compare(_200Smplr, float3(fast::clamp(_180._m22.xy * (_2979 + float2(_2932[_6423].x, _2932[_6417].y)), _2921.xy, _2921.zw), _2884).xy, _2884));
                            _6423++;
                            continue;
                        }
                    }
                    _6427 = _6420 * (_2983 ? 0.0625 : 0.0069444444961845874786376953125);
                    break;
                } while(false);
                _6428 = _6427;
                break;
            } while(false);
            float3 _6465;
            float _6468;
            if (_2723 > _180._m17[_6415])
            {
                float _2777 = (_2723 - _180._m17[_6415]) / (_180._m16[_6415] - _180._m17[_6415]);
                int _2779 = _6415 + 1;
                float3 _6466;
                float _6469;
                if (_2779 < _2715)
                {
                    float _6448;
                    do
                    {
                        float4 _3126 = _180._m14[_2779] * float4(in.m_1451 + (_2039 * _180._m18[_2779]), 1.0);
                        float _3129 = _3126.x;
                        bool _3130 = _3129 < 0.0;
                        bool _3137;
                        if (!_3130)
                        {
                            _3137 = _3129 > 1.0;
                        }
                        else
                        {
                            _3137 = _3130;
                        }
                        bool _3144;
                        if (!_3137)
                        {
                            _3144 = _3126.y < 0.0;
                        }
                        else
                        {
                            _3144 = _3137;
                        }
                        bool _3151;
                        if (!_3144)
                        {
                            _3151 = _3126.y > 1.0;
                        }
                        else
                        {
                            _3151 = _3144;
                        }
                        if (_3151)
                        {
                            _6448 = 1.0;
                            break;
                        }
                        float2 _3164 = float2(float(_2779 & 1), float(_2779 >> 1)) * _180._m23.xy;
                        float _3171 = fast::min(_3126.z, 1.0) - _180._m19[_2779];
                        float2 _3190 = _180._m22.xy * 0.5;
                        float2 _3195 = _3164 + (_3126.xy * _180._m23.xy);
                        float4 _3208 = float4(_3164 + _3190, (_3164 + _180._m23.xy) - _3190);
                        float _6447;
                        do
                        {
                            int _3234 = int(_180._m22.z);
                            if (_3234 <= 0)
                            {
                                _6447 = spvDepthCast(_200).sample_compare(_200Smplr, float3(fast::clamp(_3195, _3208.xy, _3208.zw), _3171).xy, _3171);
                                break;
                            }
                            float2 _3257 = (_3195 / _180._m22.xy) + float2(0.5);
                            float2 _3258 = floor(_3257);
                            float2 _3263 = _3257 - _3258;
                            float2 _3266 = _3258 - float2(0.5);
                            bool _3270 = _3234 == 1;
                            spvUnsafeArray<float2, 3> _3218;
                            spvUnsafeArray<float2, 3> _3219;
                            if (_3270)
                            {
                                float2 _3273 = _3263 * 2.0;
                                _3218[0] = float2(3.0) - _3273;
                                _3218[1] = float2(1.0) + _3273;
                                _3219[0] = ((float2(2.0) - _3263) / _3218[0]) - float2(1.0);
                                _3219[1] = (_3263 / _3218[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _3300 = _3263 * 3.0;
                                _3218[0] = float2(4.0) - _3300;
                                _3218[1] = float2(7.0);
                                _3218[2] = float2(1.0) + _3300;
                                _3219[0] = ((float2(3.0) - (_3263 * 2.0)) / _3218[0]) - float2(2.0);
                                _3219[1] = (float2(3.0) + _3263) / _3218[1];
                                _3219[2] = (_3263 / _3218[2]) + float2(2.0);
                            }
                            int _6924 = _3270 ? 2 : 3;
                            int _6437;
                            float _6440;
                            _6440 = 0.0;
                            _6437 = 0;
                            float _6446;
                            for (; _6437 < _6924; _6440 = _6446, _6437++)
                            {
                                _6446 = _6440;
                                for (int _6443 = 0; _6443 < _6924; )
                                {
                                    _6446 += ((_3218[_6443].x * _3218[_6437].y) * spvDepthCast(_200).sample_compare(_200Smplr, float3(fast::clamp(_180._m22.xy * (_3266 + float2(_3219[_6443].x, _3219[_6437].y)), _3208.xy, _3208.zw), _3171).xy, _3171));
                                    _6443++;
                                    continue;
                                }
                            }
                            _6447 = _6440 * (_3270 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _6448 = _6447;
                        break;
                    } while(false);
                    _6469 = mix(_6428, _6448, _2777);
                    _6466 = mix(_554[_6415], _554[_2779], float3(_2777));
                }
                else
                {
                    _6469 = mix(_6428, 1.0, _2777);
                    _6466 = _554[_6415];
                }
                _6468 = _6469;
                _6465 = _6466;
            }
            else
            {
                _6468 = _6428;
                _6465 = _554[_6415];
            }
            _6471 = select(float3(1.0), _6465, bool3(_180._m22.w > 0.5));
            _6470 = _6468;
            break;
        } while(false);
        _6554 = _6470;
        _6525 = _6499 * _6471;
    }
    else
    {
        _6554 = 1.0;
        _6525 = _6499;
    }
    float3 _2070 = _180._m5.xyz * _180._m4.w;
    bool _2074 = _1821._m6.w > 0.5;
    float _6522;
    if (_2074)
    {
        _6522 = 1.0;
    }
    else
    {
        _6522 = 1.0 + (_1821._m4.w * (_1770.sample(_1217, _1840).x - 1.0));
    }
    float _2094 = abs(in.m_1902.w);
    float _6620;
    if (_2094 > 0.0)
    {
        _6620 = _6522 * fast::min(_2094, 1.0);
    }
    else
    {
        _6620 = _6522;
    }
    float3 _6734;
    if (!_2004)
    {
        float _2110 = dot(_6529, _2021);
        float3 _6726;
        if (_180._m29.x > 0.5)
        {
            float _3451 = (_180._m29.z * _6529.x) - (_180._m29.w * _6529.z);
            float _3464 = (_180._m29.w * _6529.x) + (_180._m29.z * _6529.z);
            float _3482 = 1.09254801273345947265625 * _3451;
            spvUnsafeArray<float, 9> _6214 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _6529.y, 0.48860299587249755859375 * _3464, 0.48860299587249755859375 * _3451, _3482 * _6529.y, (1.09254801273345947265625 * _6529.y) * _3464, 0.3153919875621795654296875 * (((3.0 * _3464) * _3464) - 1.0), _3482 * _3464, 0.546274006366729736328125 * ((_3451 * _3451) - (_6529.y * _6529.y)) });
            spvUnsafeArray<float, 9> _3396 = _6214;
            float3 _6725;
            _6725 = float3(0.0);
            for (int _6724 = 0; _6724 < 9; )
            {
                _6725 += (_1215.read(uint2((int2(496, 256) + int2(_6724, 0))), 0).xyz * _3396[_6724]);
                _6724++;
                continue;
            }
            _6726 = fast::max(_6725, float3(0.0)) * _180._m29.y;
        }
        else
        {
            _6726 = mix(_180._m9.xyz, _180._m8.xyz, float3((_6529.y * 0.5) + 0.5)) * _180._m8.w;
        }
        float3 _2160 = (_6525 * ((_6726 * _6620) + ((_2070 * fast::max(_2110, 0.0)) * _6554))) + ((_2070 * ((powr(fast::max(dot(_6529, _2033), 0.0), _1821._m1.w) * _1821._m1.z) * step(0.0, _2110))) * _6554);
        float3 _6735;
        if (_180._m13.w > 0.5)
        {
            float2 _3567 = fast::clamp(floor(gl_FragCoord.xy * _180._m12.xy), float2(0.0), _180._m13.xy - float2(1.0));
            uint _3595 = uint((((fast::clamp(floor((log2(fast::max(dot(_180._m11.xyz, in.m_1451) + _180._m11.w, 9.9999999747524270787835121154785e-07)) * _180._m12.z) + _180._m12.w), 0.0, _180._m13.z - 1.0) * _180._m13.y) + _3567.y) * _180._m13.x) + _3567.x);
            uint _3597 = _3595 >> uint(2);
            uint _3599 = _3595 & 3u;
            uint _3603 = _1584._m0[_3597][_3599] & 65535u;
            uint _3605 = _1584._m0[_3597][_3599] >> uint(16);
            float3 _6736;
            _6736 = _2160;
            float3 _2241;
            spvUnsafeArray<float2, 3> _4013;
            spvUnsafeArray<float2, 3> _4014;
            spvUnsafeArray<float2, 3> _4226;
            spvUnsafeArray<float2, 3> _4227;
            for (uint _6733 = _3603; _6733 < (_3603 + _3605); _6736 = _2241, _6733++)
            {
                uint _3611 = _6733 / 3u;
                uint _3624 = (_1606._m0[_3611 >> uint(2)][_3611 & 3u] >> ((_6733 - (_3611 * 3u)) * 10u)) & 1023u;
                float3 _3641 = _1443._m0[_3624].xyz - in.m_1451;
                float _3644 = dot(_3641, _3641);
                float _3648 = _3644 * _1443._m0[_3624].w;
                float _3653 = fast::clamp(1.0 - (_3648 * _3648), 0.0, 1.0);
                float3 _3658 = _3641 * rsqrt(fast::max(_3644, 9.9999999392252902907785028219223e-09));
                float _3676 = fast::clamp((dot(-_3658, _1487._m0[_3624].xyz) * _1479._m0[_3624].w) + _1487._m0[_3624].w, 0.0, 1.0);
                float3 _3689 = _1479._m0[_3624].xyz * ((((_3653 * _3653) * _3676) * _3676) / fast::max(_3644, 9.9999997473787516355514526367188e-05));
                float3 _6858;
                if (_2044)
                {
                    float _6804;
                    do
                    {
                        uint _3725 = uint(_180._m21.z);
                        if (_3624 < _3725)
                        {
                            float _3747 = _180._m26[_3624].z * fast::max((_180._m15[_3624] * float4(in.m_1451, 1.0)).w, 0.0);
                            float4 _3771 = _180._m15[_3624] * float4((in.m_1451 + (_2039 * (_3747 * _180._m25.x))) + (_3658 * (_3747 * _180._m25.y)), 1.0);
                            float _3773 = _3771.w;
                            if (_3773 <= 0.0)
                            {
                                _6804 = 1.0;
                                break;
                            }
                            float3 _3782 = _3771.xyz / float3(_3773);
                            float _3784 = _3782.x;
                            bool _3785 = _3784 < 0.0;
                            bool _3792;
                            if (!_3785)
                            {
                                _3792 = _3784 > 1.0;
                            }
                            else
                            {
                                _3792 = _3785;
                            }
                            bool _3799;
                            if (!_3792)
                            {
                                _3799 = _3782.y < 0.0;
                            }
                            else
                            {
                                _3799 = _3792;
                            }
                            bool _3806;
                            if (!_3799)
                            {
                                _3806 = _3782.y > 1.0;
                            }
                            else
                            {
                                _3806 = _3799;
                            }
                            bool _3813;
                            if (!_3806)
                            {
                                _3813 = _3782.z > 1.0;
                            }
                            else
                            {
                                _3813 = _3806;
                            }
                            if (_3813)
                            {
                                _6804 = 1.0;
                                break;
                            }
                            float _3819 = _3782.z;
                            float2 _3985 = _180._m22.xy * 0.5;
                            float2 _3990 = _180._m26[_3624].xy + (_3782.xy * _180._m23.zw);
                            float4 _4003 = float4(_180._m26[_3624].xy + _3985, (_180._m26[_3624].xy + _180._m23.zw) - _3985);
                            float _6803;
                            do
                            {
                                int _4029 = int(_180._m22.z);
                                if (_4029 <= 0)
                                {
                                    float2 _4039 = fast::clamp(_3990, _4003.xy, _4003.zw);
                                    _6803 = spvDepthCast(_200).sample_compare(_200Smplr, float3(_4039, _3819).xy, _3819);
                                    break;
                                }
                                float2 _4052 = (_3990 / _180._m22.xy) + float2(0.5);
                                float2 _4053 = floor(_4052);
                                float2 _4058 = _4052 - _4053;
                                float2 _4061 = _4053 - float2(0.5);
                                bool _4065 = _4029 == 1;
                                if (_4065)
                                {
                                    float2 _4068 = _4058 * 2.0;
                                    _4013[0] = float2(3.0) - _4068;
                                    _4013[1] = float2(1.0) + _4068;
                                    _4014[0] = ((float2(2.0) - _4058) / _4013[0]) - float2(1.0);
                                    _4014[1] = (_4058 / _4013[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _4095 = _4058 * 3.0;
                                    _4013[0] = float2(4.0) - _4095;
                                    _4013[1] = float2(7.0);
                                    _4013[2] = float2(1.0) + _4095;
                                    _4014[0] = ((float2(3.0) - (_4058 * 2.0)) / _4013[0]) - float2(2.0);
                                    _4014[1] = (float2(3.0) + _4058) / _4013[1];
                                    _4014[2] = (_4058 / _4013[2]) + float2(2.0);
                                }
                                int _6929 = _4065 ? 2 : 3;
                                int _6793;
                                float _6796;
                                _6796 = 0.0;
                                _6793 = 0;
                                float _6802;
                                for (; _6793 < _6929; _6796 = _6802, _6793++)
                                {
                                    _6802 = _6796;
                                    for (int _6799 = 0; _6799 < _6929; )
                                    {
                                        _6802 += ((_4013[_6799].x * _4013[_6793].y) * spvDepthCast(_200).sample_compare(_200Smplr, float3(fast::clamp(_180._m22.xy * (_4061 + float2(_4014[_6799].x, _4014[_6793].y)), _4003.xy, _4003.zw), _3819).xy, _3819));
                                        _6799++;
                                        continue;
                                    }
                                }
                                _6803 = _6796 * (_4065 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _6804 = _6803;
                            break;
                        }
                        uint _3829 = _3624 - _3725;
                        if (_3829 >= uint(_180._m21.w))
                        {
                            _6804 = 1.0;
                            break;
                        }
                        float _3850 = _180._m27[_3829].w * length(in.m_1451 - _180._m27[_3829].xyz);
                        float3 _3868 = ((in.m_1451 + (_2039 * (_3850 * _180._m25.x))) + (_3658 * (_3850 * _180._m25.y))) - _180._m27[_3829].xyz;
                        float3 _3870 = abs(_3868);
                        float _3872 = _3870.x;
                        float _3874 = _3870.y;
                        bool _3875 = _3872 >= _3874;
                        bool _3883;
                        if (_3875)
                        {
                            _3883 = _3872 >= _3870.z;
                        }
                        else
                        {
                            _3883 = _3875;
                        }
                        float _6778;
                        int _6780;
                        if (_3883)
                        {
                            _6780 = (_3868.x > 0.0) ? 0 : 1;
                            _6778 = _3872;
                        }
                        else
                        {
                            float _3895 = _3870.z;
                            bool _3896 = _3874 >= _3895;
                            int _6781;
                            if (_3896)
                            {
                                _6781 = (_3868.y > 0.0) ? 2 : 3;
                            }
                            else
                            {
                                _6781 = (_3868.z > 0.0) ? 4 : 5;
                            }
                            _6780 = _6781;
                            _6778 = _3896 ? _3874 : _3895;
                        }
                        if (_6778 <= 0.0)
                        {
                            _6804 = 1.0;
                            break;
                        }
                        float2 _3933 = float2(dot(_3868, _858[_6780]), dot(_3868, _867[_6780])) / float2(_6778 * _180._m24.z);
                        float _3940 = _180._m28[_3829].z + (_180._m28[_3829].w / _6778);
                        if (_3940 > 1.0)
                        {
                            _6804 = 1.0;
                            break;
                        }
                        float2 _3958 = _180._m28[_3829].xy + (float2(float(spvSMod(_6780, 3)), float(_6780 / 3)) * _180._m24.xy);
                        float2 _4198 = _180._m22.xy * 0.5;
                        float2 _4203 = _3958 + (float2(0.5 + (0.5 * _3933.x), 0.5 - (0.5 * _3933.y)) * _180._m24.xy);
                        float4 _4216 = float4(_3958 + _4198, (_3958 + _180._m24.xy) - _4198);
                        float _6792;
                        do
                        {
                            int _4242 = int(_180._m22.z);
                            if (_4242 <= 0)
                            {
                                _6792 = spvDepthCast(_200).sample_compare(_200Smplr, float3(fast::clamp(_4203, _4216.xy, _4216.zw), _3940).xy, _3940);
                                break;
                            }
                            float2 _4265 = (_4203 / _180._m22.xy) + float2(0.5);
                            float2 _4266 = floor(_4265);
                            float2 _4271 = _4265 - _4266;
                            float2 _4274 = _4266 - float2(0.5);
                            bool _4278 = _4242 == 1;
                            if (_4278)
                            {
                                float2 _4281 = _4271 * 2.0;
                                _4226[0] = float2(3.0) - _4281;
                                _4226[1] = float2(1.0) + _4281;
                                _4227[0] = ((float2(2.0) - _4271) / _4226[0]) - float2(1.0);
                                _4227[1] = (_4271 / _4226[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _4308 = _4271 * 3.0;
                                _4226[0] = float2(4.0) - _4308;
                                _4226[1] = float2(7.0);
                                _4226[2] = float2(1.0) + _4308;
                                _4227[0] = ((float2(3.0) - (_4271 * 2.0)) / _4226[0]) - float2(2.0);
                                _4227[1] = (float2(3.0) + _4271) / _4226[1];
                                _4227[2] = (_4271 / _4226[2]) + float2(2.0);
                            }
                            int _6932 = _4278 ? 2 : 3;
                            int _6782;
                            float _6785;
                            _6785 = 0.0;
                            _6782 = 0;
                            float _6791;
                            for (; _6782 < _6932; _6785 = _6791, _6782++)
                            {
                                _6791 = _6785;
                                for (int _6788 = 0; _6788 < _6932; )
                                {
                                    _6791 += ((_4226[_6788].x * _4226[_6782].y) * spvDepthCast(_200).sample_compare(_200Smplr, float3(fast::clamp(_180._m22.xy * (_4274 + float2(_4227[_6788].x, _4227[_6782].y)), _4216.xy, _4216.zw), _3940).xy, _3940));
                                    _6788++;
                                    continue;
                                }
                            }
                            _6792 = _6785 * (_4278 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _6804 = _6792;
                        break;
                    } while(false);
                    _6858 = _3689 * _6804;
                }
                else
                {
                    _6858 = _3689;
                }
                float _2212 = dot(_6529, _3658);
                _2241 = _6736 + (((_6525 * fast::max(_2212, 0.0)) * _6858) + (_6858 * ((powr(fast::max(dot(_6529, fast::normalize(_3658 + _2028)), 0.0), _1821._m1.w) * _1821._m1.z) * step(0.0, _2212))));
            }
            _6735 = _6736;
        }
        else
        {
            _6735 = _2160;
        }
        _6734 = _6735;
    }
    else
    {
        float4 _2251 = _2246.sample(_1217, _1840);
        float _2258 = fast::clamp(_1821._m4.x * _2251.z, 0.0, 1.0);
        float _2266 = fast::clamp(_1821._m4.y * _2251.y, 0.04500000178813934326171875, 1.0);
        float _2270 = _2266 * _2266;
        float3 _2275 = _6525 * (1.0 - _2258);
        float3 _2281 = mix(float3(0.039999999105930328369140625), _6525, float3(_2258));
        float _2286 = fast::max(dot(_6529, _2028), 9.9999997473787516355514526367188e-05);
        float _2291 = fast::clamp(dot(_6529, _2021), 0.0, 1.0);
        float _2296 = fast::clamp(dot(_6529, _2033), 0.0, 1.0);
        float3 _4410 = float3(1.0) - _2281;
        float3 _4413 = _2281 + (_4410 * powr(1.0 - fast::clamp(dot(_2028, _2033), 0.0, 1.0), 5.0));
        float _4420 = _2270 * _2270;
        float _4425 = _4420 - 1.0;
        float _4427 = ((_2296 * _2296) * _4425) + 1.0;
        float _4447 = 1.0 - _4420;
        float _4451 = sqrt(((_2286 * _2286) * _4447) + _4420);
        float3 _6573;
        float2 _6588;
        float3 _6600;
        if (_180._m29.x > 0.5)
        {
            float4 _4484 = _1321.sample(_1323, (((float2(_2286, _2266) * 31.0) + float2(0.5)) * float2(0.03125)));
            float _4543 = (_180._m29.z * _6529.x) - (_180._m29.w * _6529.z);
            float _4556 = (_180._m29.w * _6529.x) + (_180._m29.z * _6529.z);
            float _4574 = 1.09254801273345947265625 * _4543;
            spvUnsafeArray<float, 9> _6195 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _6529.y, 0.48860299587249755859375 * _4556, 0.48860299587249755859375 * _4543, _4574 * _6529.y, (1.09254801273345947265625 * _6529.y) * _4556, 0.3153919875621795654296875 * (((3.0 * _4556) * _4556) - 1.0), _4574 * _4556, 0.546274006366729736328125 * ((_4543 * _4543) - (_6529.y * _6529.y)) });
            spvUnsafeArray<float, 9> _4488 = _6195;
            float3 _6556;
            _6556 = float3(0.0);
            for (int _6555 = 0; _6555 < 9; )
            {
                _6556 += (_1215.read(uint2((int2(496, 256) + int2(_6555, 0))), 0).xyz * _4488[_6555]);
                _6555++;
                continue;
            }
            float3 _2357 = reflect(-_2028, _6529);
            float _4669 = _2357.x;
            float _4674 = _2357.z;
            float2 _4706 = float2((precise::atan2((_180._m29.z * _4669) - (_180._m29.w * _4674), -((_180._m29.w * _4669) + (_180._m29.z * _4674))) * 0.15915493667125701904296875) + 0.5, acos(fast::clamp(_2357.y, -1.0, 1.0)) * 0.3183098733425140380859375);
            float _4638 = _2266 * 5.0;
            int _4641 = min(int(_4638), 4);
            float2 _4727 = (_4706 * float2(_1277[_4641].zw)) - float2(0.5);
            float2 _4729 = floor(_4727);
            float2 _4732 = _4727 - _4729;
            int _4735 = int(_4729.x);
            int _4738 = int(_4729.y);
            int _6558;
            if (_4735 < 0)
            {
                _6558 = _4735 + _1277[_4641].z;
            }
            else
            {
                _6558 = _4735;
            }
            int _6559;
            if (_6558 >= _1277[_4641].z)
            {
                _6559 = _6558 - _1277[_4641].z;
            }
            else
            {
                _6559 = _6558;
            }
            int _4758 = _6559 + 1;
            int _6933 = (_4758 == _1277[_4641].z) ? 0 : _4758;
            int _4773 = min((_4738 + 1), (_1277[_4641].w - 1));
            int _4775 = max(_4738, 0);
            float3 _4828 = float3(_4732.x);
            int _4648 = _4641 + 1;
            float2 _4860 = (_4706 * float2(_1277[_4648].zw)) - float2(0.5);
            float2 _4862 = floor(_4860);
            float2 _4865 = _4860 - _4862;
            int _4868 = int(_4862.x);
            int _4871 = int(_4862.y);
            int _6565;
            if (_4868 < 0)
            {
                _6565 = _4868 + _1277[_4648].z;
            }
            else
            {
                _6565 = _4868;
            }
            int _6566;
            if (_6565 >= _1277[_4648].z)
            {
                _6566 = _6565 - _1277[_4648].z;
            }
            else
            {
                _6566 = _6565;
            }
            int _4891 = _6566 + 1;
            int _6934 = (_4891 == _1277[_4648].z) ? 0 : _4891;
            int _4906 = min((_4871 + 1), (_1277[_4648].w - 1));
            int _4908 = max(_4871, 0);
            float3 _4961 = float3(_4865.x);
            float3 _4663 = mix(mix(mix(_1215.read(uint2((_1277[_4641].xy + int2(_6559, _4775))), 0).xyz, _1215.read(uint2((_1277[_4641].xy + int2(_6933, _4775))), 0).xyz, _4828), mix(_1215.read(uint2((_1277[_4641].xy + int2(_6559, _4773))), 0).xyz, _1215.read(uint2((_1277[_4641].xy + int2(_6933, _4773))), 0).xyz, _4828), float3(_4732.y)), mix(mix(_1215.read(uint2((_1277[_4648].xy + int2(_6566, _4908))), 0).xyz, _1215.read(uint2((_1277[_4648].xy + int2(_6934, _4908))), 0).xyz, _4961), mix(_1215.read(uint2((_1277[_4648].xy + int2(_6566, _4906))), 0).xyz, _1215.read(uint2((_1277[_4648].xy + int2(_6934, _4906))), 0).xyz, _4961), float3(_4865.y)), float3(_4638 - float(_4641))) * _180._m29.y;
            _6600 = fast::max(_6556, float3(0.0)) * _180._m29.y;
            _6588 = _4484.xy;
            _6573 = _4663;
        }
        else
        {
            float4 _4979 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * _2266) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);
            float _4981 = _4979.x;
            float3 _5016 = mix(_180._m9.xyz, _180._m8.xyz, float3((_6529.y * 0.5) + 0.5)) * _180._m8.w;
            _6600 = _5016;
            _6588 = (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_4981 * _4981, exp2((-9.27999973297119140625) * _2286)) * _4981) + _4979.y)) + _4979.zw;
            _6573 = mix(mix(_180._m9.xyz, _180._m8.xyz, float3((reflect(-_2028, _6529).y * 0.5) + 0.5)) * _180._m8.w, _5016, float3(_2266));
        }
        bool _2389;
        if (_2074)
        {
            _2389 = _180._m33.z > 0.5;
        }
        else
        {
            _2389 = _2074;
        }
        float3 _6609;
        if (_2389)
        {
            float3 _6585;
            do
            {
                float _5095 = ((_180._m32.x * (1.0 - smoothstep(_180._m33.x * 0.5, _180._m33.x, abs(dot(_180._m31.xyz, in.m_1451) - _180._m31.w)))) * smoothstep(0.5, 0.89999997615814208984375, dot(_2039, _180._m31.xyz))) * (1.0 - smoothstep(_180._m32.y * 0.5, _180._m32.y, _2266));
                if (_5095 <= 0.0)
                {
                    _6585 = _6573;
                    break;
                }
                float4 _5120 = _180._m30 * float4(in.m_1451 + ((_6529 - (_180._m31.xyz * dot(_6529, _180._m31.xyz))) * _180._m32.w), 1.0);
                float2 _5133 = ((float2(_5120.x, -_5120.y) / float2(_5120.w)) * 0.5) + float2(0.5);
                float _5137 = _180._m32.z * _2266;
                float3 _6583;
                float _6584;
                _6584 = 0.0;
                _6583 = float3(0.0);
                for (int _6582 = 0; _6582 < 12; )
                {
                    float _5144 = float(_6582);
                    float _5152 = _5144 * 2.3999631404876708984375;
                    float2 _5164 = _5133 + (float2(cos(_5152) * _180._m33.y, sin(_5152)) * (sqrt((_5144 + 0.5) * 0.083333335816860198974609375) * _5137));
                    float2 _5169 = fast::min(_5164, float2(1.0) - _5164);
                    float _5175 = smoothstep(0.0, 0.039999999105930328369140625, fast::min(_5169.x, _5169.y));
                    float4 _5183 = _1770.sample(_1217, fast::clamp(_5164, float2(0.0), float2(1.0)), level(0.0));
                    float3 _5185 = _5183.xyz;
                    _6584 += (_5183.w * _5175);
                    _6583 += ((_5185 / (float3(1.0) - fast::min(_5185, float3(0.99500000476837158203125)))) * _5175);
                    _6582++;
                    continue;
                }
                _6585 = mix(_6573, (_6583 * float3(0.083333335816860198974609375)) + (_6573 * (1.0 - (_6584 * 0.083333335816860198974609375))), float3(_5095));
                break;
            } while(false);
            _6609 = _6585;
        }
        else
        {
            _6609 = _6573;
        }
        float3 _2409 = (_2281 * _6588.x) + float3(_6588.y);
        float3 _2425 = ((((((float3(1.0) - _4413) * _2275) + ((_4413 * ((_4420 / ((3.1415927410125732421875 * _4427) * _4427)) * (0.5 / fast::max((_2291 * _4451) + (_2286 * sqrt(((_2291 * _2291) * _4447) + _4420)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875)) * _2291) * _2070) * _6554) + (((((float3(1.0) - _2409) * _2275) * _6600) + (_2409 * _6609)) * _6620);
        float3 _6737;
        if (_180._m13.w > 0.5)
        {
            float2 _5249 = fast::clamp(floor(gl_FragCoord.xy * _180._m12.xy), float2(0.0), _180._m13.xy - float2(1.0));
            uint _5277 = uint((((fast::clamp(floor((log2(fast::max(dot(_180._m11.xyz, in.m_1451) + _180._m11.w, 9.9999999747524270787835121154785e-07)) * _180._m12.z) + _180._m12.w), 0.0, _180._m13.z - 1.0) * _180._m13.y) + _5249.y) * _180._m13.x) + _5249.x);
            uint _5279 = _5277 >> uint(2);
            uint _5281 = _5277 & 3u;
            uint _5285 = _1584._m0[_5279][_5281] & 65535u;
            uint _5287 = _1584._m0[_5279][_5281] >> uint(16);
            float3 _6690;
            _6690 = _2425;
            float3 _2525;
            spvUnsafeArray<float2, 3> _5695;
            spvUnsafeArray<float2, 3> _5696;
            spvUnsafeArray<float2, 3> _5908;
            spvUnsafeArray<float2, 3> _5909;
            for (uint _6623 = _5285; _6623 < (_5285 + _5287); _6690 = _2525, _6623++)
            {
                uint _5293 = _6623 / 3u;
                uint _5306 = (_1606._m0[_5293 >> uint(2)][_5293 & 3u] >> ((_6623 - (_5293 * 3u)) * 10u)) & 1023u;
                float3 _5323 = _1443._m0[_5306].xyz - in.m_1451;
                float _5326 = dot(_5323, _5323);
                float _5330 = _5326 * _1443._m0[_5306].w;
                float _5335 = fast::clamp(1.0 - (_5330 * _5330), 0.0, 1.0);
                float3 _5340 = _5323 * rsqrt(fast::max(_5326, 9.9999999392252902907785028219223e-09));
                float _5358 = fast::clamp((dot(-_5340, _1487._m0[_5306].xyz) * _1479._m0[_5306].w) + _1487._m0[_5306].w, 0.0, 1.0);
                float3 _5371 = _1479._m0[_5306].xyz * ((((_5335 * _5335) * _5358) * _5358) / fast::max(_5326, 9.9999997473787516355514526367188e-05));
                float3 _6688;
                if (_2044)
                {
                    float _6650;
                    do
                    {
                        uint _5407 = uint(_180._m21.z);
                        if (_5306 < _5407)
                        {
                            float _5429 = _180._m26[_5306].z * fast::max((_180._m15[_5306] * float4(in.m_1451, 1.0)).w, 0.0);
                            float4 _5453 = _180._m15[_5306] * float4((in.m_1451 + (_2039 * (_5429 * _180._m25.x))) + (_5340 * (_5429 * _180._m25.y)), 1.0);
                            float _5455 = _5453.w;
                            if (_5455 <= 0.0)
                            {
                                _6650 = 1.0;
                                break;
                            }
                            float3 _5464 = _5453.xyz / float3(_5455);
                            float _5466 = _5464.x;
                            bool _5467 = _5466 < 0.0;
                            bool _5474;
                            if (!_5467)
                            {
                                _5474 = _5466 > 1.0;
                            }
                            else
                            {
                                _5474 = _5467;
                            }
                            bool _5481;
                            if (!_5474)
                            {
                                _5481 = _5464.y < 0.0;
                            }
                            else
                            {
                                _5481 = _5474;
                            }
                            bool _5488;
                            if (!_5481)
                            {
                                _5488 = _5464.y > 1.0;
                            }
                            else
                            {
                                _5488 = _5481;
                            }
                            bool _5495;
                            if (!_5488)
                            {
                                _5495 = _5464.z > 1.0;
                            }
                            else
                            {
                                _5495 = _5488;
                            }
                            if (_5495)
                            {
                                _6650 = 1.0;
                                break;
                            }
                            float _5501 = _5464.z;
                            float2 _5667 = _180._m22.xy * 0.5;
                            float2 _5672 = _180._m26[_5306].xy + (_5464.xy * _180._m23.zw);
                            float4 _5685 = float4(_180._m26[_5306].xy + _5667, (_180._m26[_5306].xy + _180._m23.zw) - _5667);
                            float _6649;
                            do
                            {
                                int _5711 = int(_180._m22.z);
                                if (_5711 <= 0)
                                {
                                    float2 _5721 = fast::clamp(_5672, _5685.xy, _5685.zw);
                                    _6649 = spvDepthCast(_200).sample_compare(_200Smplr, float3(_5721, _5501).xy, _5501);
                                    break;
                                }
                                float2 _5734 = (_5672 / _180._m22.xy) + float2(0.5);
                                float2 _5735 = floor(_5734);
                                float2 _5740 = _5734 - _5735;
                                float2 _5743 = _5735 - float2(0.5);
                                bool _5747 = _5711 == 1;
                                if (_5747)
                                {
                                    float2 _5750 = _5740 * 2.0;
                                    _5695[0] = float2(3.0) - _5750;
                                    _5695[1] = float2(1.0) + _5750;
                                    _5696[0] = ((float2(2.0) - _5740) / _5695[0]) - float2(1.0);
                                    _5696[1] = (_5740 / _5695[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _5777 = _5740 * 3.0;
                                    _5695[0] = float2(4.0) - _5777;
                                    _5695[1] = float2(7.0);
                                    _5695[2] = float2(1.0) + _5777;
                                    _5696[0] = ((float2(3.0) - (_5740 * 2.0)) / _5695[0]) - float2(2.0);
                                    _5696[1] = (float2(3.0) + _5740) / _5695[1];
                                    _5696[2] = (_5740 / _5695[2]) + float2(2.0);
                                }
                                int _6936 = _5747 ? 2 : 3;
                                int _6639;
                                float _6642;
                                _6642 = 0.0;
                                _6639 = 0;
                                float _6648;
                                for (; _6639 < _6936; _6642 = _6648, _6639++)
                                {
                                    _6648 = _6642;
                                    for (int _6645 = 0; _6645 < _6936; )
                                    {
                                        _6648 += ((_5695[_6645].x * _5695[_6639].y) * spvDepthCast(_200).sample_compare(_200Smplr, float3(fast::clamp(_180._m22.xy * (_5743 + float2(_5696[_6645].x, _5696[_6639].y)), _5685.xy, _5685.zw), _5501).xy, _5501));
                                        _6645++;
                                        continue;
                                    }
                                }
                                _6649 = _6642 * (_5747 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _6650 = _6649;
                            break;
                        }
                        uint _5511 = _5306 - _5407;
                        if (_5511 >= uint(_180._m21.w))
                        {
                            _6650 = 1.0;
                            break;
                        }
                        float _5532 = _180._m27[_5511].w * length(in.m_1451 - _180._m27[_5511].xyz);
                        float3 _5550 = ((in.m_1451 + (_2039 * (_5532 * _180._m25.x))) + (_5340 * (_5532 * _180._m25.y))) - _180._m27[_5511].xyz;
                        float3 _5552 = abs(_5550);
                        float _5554 = _5552.x;
                        float _5556 = _5552.y;
                        bool _5557 = _5554 >= _5556;
                        bool _5565;
                        if (_5557)
                        {
                            _5565 = _5554 >= _5552.z;
                        }
                        else
                        {
                            _5565 = _5557;
                        }
                        float _6624;
                        int _6626;
                        if (_5565)
                        {
                            _6626 = (_5550.x > 0.0) ? 0 : 1;
                            _6624 = _5554;
                        }
                        else
                        {
                            float _5577 = _5552.z;
                            bool _5578 = _5556 >= _5577;
                            int _6627;
                            if (_5578)
                            {
                                _6627 = (_5550.y > 0.0) ? 2 : 3;
                            }
                            else
                            {
                                _6627 = (_5550.z > 0.0) ? 4 : 5;
                            }
                            _6626 = _6627;
                            _6624 = _5578 ? _5556 : _5577;
                        }
                        if (_6624 <= 0.0)
                        {
                            _6650 = 1.0;
                            break;
                        }
                        float2 _5615 = float2(dot(_5550, _858[_6626]), dot(_5550, _867[_6626])) / float2(_6624 * _180._m24.z);
                        float _5622 = _180._m28[_5511].z + (_180._m28[_5511].w / _6624);
                        if (_5622 > 1.0)
                        {
                            _6650 = 1.0;
                            break;
                        }
                        float2 _5640 = _180._m28[_5511].xy + (float2(float(spvSMod(_6626, 3)), float(_6626 / 3)) * _180._m24.xy);
                        float2 _5880 = _180._m22.xy * 0.5;
                        float2 _5885 = _5640 + (float2(0.5 + (0.5 * _5615.x), 0.5 - (0.5 * _5615.y)) * _180._m24.xy);
                        float4 _5898 = float4(_5640 + _5880, (_5640 + _180._m24.xy) - _5880);
                        float _6638;
                        do
                        {
                            int _5924 = int(_180._m22.z);
                            if (_5924 <= 0)
                            {
                                _6638 = spvDepthCast(_200).sample_compare(_200Smplr, float3(fast::clamp(_5885, _5898.xy, _5898.zw), _5622).xy, _5622);
                                break;
                            }
                            float2 _5947 = (_5885 / _180._m22.xy) + float2(0.5);
                            float2 _5948 = floor(_5947);
                            float2 _5953 = _5947 - _5948;
                            float2 _5956 = _5948 - float2(0.5);
                            bool _5960 = _5924 == 1;
                            if (_5960)
                            {
                                float2 _5963 = _5953 * 2.0;
                                _5908[0] = float2(3.0) - _5963;
                                _5908[1] = float2(1.0) + _5963;
                                _5909[0] = ((float2(2.0) - _5953) / _5908[0]) - float2(1.0);
                                _5909[1] = (_5953 / _5908[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _5990 = _5953 * 3.0;
                                _5908[0] = float2(4.0) - _5990;
                                _5908[1] = float2(7.0);
                                _5908[2] = float2(1.0) + _5990;
                                _5909[0] = ((float2(3.0) - (_5953 * 2.0)) / _5908[0]) - float2(2.0);
                                _5909[1] = (float2(3.0) + _5953) / _5908[1];
                                _5909[2] = (_5953 / _5908[2]) + float2(2.0);
                            }
                            int _6939 = _5960 ? 2 : 3;
                            int _6628;
                            float _6631;
                            _6631 = 0.0;
                            _6628 = 0;
                            float _6637;
                            for (; _6628 < _6939; _6631 = _6637, _6628++)
                            {
                                _6637 = _6631;
                                for (int _6634 = 0; _6634 < _6939; )
                                {
                                    _6637 += ((_5908[_6634].x * _5908[_6628].y) * spvDepthCast(_200).sample_compare(_200Smplr, float3(fast::clamp(_180._m22.xy * (_5956 + float2(_5909[_6634].x, _5909[_6628].y)), _5898.xy, _5898.zw), _5622).xy, _5622));
                                    _6634++;
                                    continue;
                                }
                            }
                            _6638 = _6631 * (_5960 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _6650 = _6638;
                        break;
                    } while(false);
                    _6688 = _5371 * _6650;
                }
                else
                {
                    _6688 = _5371;
                }
                float3 _2477 = fast::normalize(_5340 + _2028);
                float _2482 = fast::clamp(dot(_6529, _5340), 0.0, 1.0);
                float _2487 = fast::clamp(dot(_6529, _2477), 0.0, 1.0);
                float3 _6095 = _2281 + (_4410 * powr(1.0 - fast::clamp(dot(_2028, _2477), 0.0, 1.0), 5.0));
                float _6109 = ((_2487 * _2487) * _4425) + 1.0;
                _2525 = _6690 + (((((float3(1.0) - _6095) * _2275) + ((_6095 * ((_4420 / ((3.1415927410125732421875 * _6109) * _6109)) * (0.5 / fast::max((_2482 * _4451) + (_2286 * sqrt(((_2482 * _2482) * _4447) + _4420)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875)) * _2482) * _6688);
            }
            _6737 = _6690;
        }
        else
        {
            _6737 = _2425;
        }
        _6734 = _6737;
    }
    float4 _2542 = _2537.sample(_1217, _1840);
    float _2560 = -length(_2027);
    float _6775;
    if (_180._m9.w != 0.0)
    {
        float _2584 = _180._m9.w * (in.m_1451 - _180._m6.xyz).y;
        float _6772;
        if (abs(_2584) < 9.9999997473787516355514526367188e-05)
        {
            _6772 = 1.0 - (0.5 * _2584);
        }
        else
        {
            _6772 = (1.0 - exp(fast::min(-_2584, 60.0))) / _2584;
        }
        _6775 = 1.0 - exp((_2560 * (_180._m7.w * exp(fast::min((-_180._m9.w) * (_180._m6.y - _180._m6.w), 30.0)))) * _6772);
    }
    else
    {
        _6775 = 1.0 - exp(_2560 * _180._m7.w);
    }
    float3 _2635 = mix(mix(_6734, _6525, float3(_1821._m1.y)) + ((_1821._m5.xyz * _2542.xyz) * (float3(1.0) + in.m_2041.yzw)), _180._m7.xyz, float3(_6775));
    float3 _6776;
    if (_180._m33.w > 0.5)
    {
        _6776 = _2635 / (float3(1.0) + _2635);
    }
    else
    {
        _6776 = _2635;
    }
    out.m_2647 = float4(_6776, (in.m_1849.w * _1821._m0.w) * _1847.w);
    float2 _6777;
    do
    {
        if (in.m_2657.w <= 0.0)
        {
            _6777 = float2(0.0);
            break;
        }
        _6777 = ((in.m_2657.xy / float2(in.m_2657.w)) - (in.m_2656.xy / float2(in.m_2656.w))) * float2(0.5, -0.5);
        break;
    } while(false);
    _2655 = _6777;
    return out;
}

