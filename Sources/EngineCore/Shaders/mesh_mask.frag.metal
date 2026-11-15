// Generated from mesh_mask.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: f68fad0251106f56
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
    float4 m_2648 [[color(0)]];
    float2 m_2656 [[color(1)]];
};

struct fragment_main_in
{
    float3 m_1451 [[user(locn0)]];
    float3 m_1906 [[user(locn1)]];
    float2 m_1826 [[user(locn2)]];
    float4 m_1849 [[user(locn3)]];
    float4 m_2054 [[user(locn5)]];
    float4 m_2657 [[user(locn6)]];
    float4 m_2658 [[user(locn7)]];
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
    float3 _6501;
    if (_1821._m1.x > 0.5)
    {
        float2 _1892 = floor(in.m_1451.xz * float2(0.5));
        _6501 = _1858 * ((mod(abs(_1892.x + _1892.y), 2.0) < 0.5) ? 1.0 : 0.75);
    }
    else
    {
        _6501 = _1858;
    }
    float3 _1908 = fast::normalize(in.m_1906);
    float3 _6415;
    if (_1821._m6.y > 0.5)
    {
        float3 _1924 = in.m_1915.xyz - (_1908 * dot(_1908, in.m_1915.xyz));
        float3 _6416;
        if (dot(_1924, _1924) > 9.9999999600419720025001879548654e-13)
        {
            float3 _1933 = fast::normalize(_1924);
            float4 _1949 = _1944.sample(_1217, _1840);
            float3 _6409;
            if (_1821._m6.z > 0.5)
            {
                float2 _6408;
                if (_1821._m6.z > 1.5)
                {
                    _6408 = _1949.xw;
                }
                else
                {
                    _6408 = _1949.xy;
                }
                float2 _1971 = (_6408 * 2.0) - float2(1.0);
                _6409 = float3(_1971, sqrt(fast::clamp(1.0 - dot(_1971, _1971), 0.0, 1.0)));
            }
            else
            {
                _6409 = (_1949.xyz * 2.0) - float3(1.0);
            }
            float2 _1993 = _6409.xy * _1821._m4.z;
            _6416 = fast::normalize(((_1933 * _1993.x) + ((cross(_1908, _1933) * ((in.m_1915.w < 0.0) ? (-1.0) : 1.0)) * _1993.y)) + (_1908 * _6409.z));
        }
        else
        {
            _6416 = _1908;
        }
        _6415 = _6416;
    }
    else
    {
        _6415 = _1908;
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
    float3 _6529;
    if (_2025)
    {
        _6529 = -_6415;
    }
    else
    {
        _6529 = _6415;
    }
    float3 _2034 = fast::normalize(_180._m4.xyz);
    float3 _2040 = _180._m6.xyz - in.m_1451;
    float3 _2041 = fast::normalize(_2040);
    float3 _2046 = fast::normalize(_2034 + _2041);
    float3 _2052 = _1908 * (gl_FrontFacing ? 1.0 : (-1.0));
    bool _2057 = in.m_2054.x > 0.5;
    float3 _6526;
    float _6553;
    if ((_180._m5.w > 0.5) && _2057)
    {
        float _6472;
        float3 _6473;
        do
        {
            int _2716 = int(_180._m21.x);
            float _2724 = dot(_180._m20.xyz, in.m_1451) + _180._m20.w;
            int _6417;
            _6417 = 0;
            for (;;)
            {
                bool _2730 = _6417 < (_2716 - 1);
                bool _2738;
                if (_2730)
                {
                    _2738 = _2724 > _180._m16[_6417];
                }
                else
                {
                    _2738 = _2730;
                }
                if (_2738)
                {
                    _6417++;
                    continue;
                }
                else
                {
                    break;
                }
            }
            if (_2724 > _180._m16[_6417])
            {
                _6473 = float3(1.0);
                _6472 = 1.0;
                break;
            }
            float _6430;
            do
            {
                float4 _2840 = _180._m14[_6417] * float4(in.m_1451 + (_2052 * _180._m18[_6417]), 1.0);
                float _2843 = _2840.x;
                bool _2844 = _2843 < 0.0;
                bool _2851;
                if (!_2844)
                {
                    _2851 = _2843 > 1.0;
                }
                else
                {
                    _2851 = _2844;
                }
                bool _2858;
                if (!_2851)
                {
                    _2858 = _2840.y < 0.0;
                }
                else
                {
                    _2858 = _2851;
                }
                bool _2865;
                if (!_2858)
                {
                    _2865 = _2840.y > 1.0;
                }
                else
                {
                    _2865 = _2858;
                }
                if (_2865)
                {
                    _6430 = 1.0;
                    break;
                }
                float2 _2878 = float2(float(_6417 & 1), float(_6417 >> 1)) * _180._m23.xy;
                float _2885 = fast::min(_2840.z, 1.0) - _180._m19[_6417];
                float2 _2904 = _180._m22.xy * 0.5;
                float2 _2909 = _2878 + (_2840.xy * _180._m23.xy);
                float4 _2922 = float4(_2878 + _2904, (_2878 + _180._m23.xy) - _2904);
                float _6429;
                do
                {
                    int _2948 = int(_180._m22.z);
                    if (_2948 <= 0)
                    {
                        _6429 = spvDepthCast(_200).sample_compare(_200Smplr, float3(fast::clamp(_2909, _2922.xy, _2922.zw), _2885).xy, _2885);
                        break;
                    }
                    float2 _2971 = (_2909 / _180._m22.xy) + float2(0.5);
                    float2 _2972 = floor(_2971);
                    float2 _2977 = _2971 - _2972;
                    float2 _2980 = _2972 - float2(0.5);
                    bool _2984 = _2948 == 1;
                    spvUnsafeArray<float2, 3> _2932;
                    spvUnsafeArray<float2, 3> _2933;
                    if (_2984)
                    {
                        float2 _2987 = _2977 * 2.0;
                        _2932[0] = float2(3.0) - _2987;
                        _2932[1] = float2(1.0) + _2987;
                        _2933[0] = ((float2(2.0) - _2977) / _2932[0]) - float2(1.0);
                        _2933[1] = (_2977 / _2932[1]) + float2(1.0);
                    }
                    else
                    {
                        float2 _3014 = _2977 * 3.0;
                        _2932[0] = float2(4.0) - _3014;
                        _2932[1] = float2(7.0);
                        _2932[2] = float2(1.0) + _3014;
                        _2933[0] = ((float2(3.0) - (_2977 * 2.0)) / _2932[0]) - float2(2.0);
                        _2933[1] = (float2(3.0) + _2977) / _2932[1];
                        _2933[2] = (_2977 / _2932[2]) + float2(2.0);
                    }
                    int _6993 = _2984 ? 2 : 3;
                    int _6419;
                    float _6422;
                    _6422 = 0.0;
                    _6419 = 0;
                    float _6428;
                    for (; _6419 < _6993; _6422 = _6428, _6419++)
                    {
                        _6428 = _6422;
                        for (int _6425 = 0; _6425 < _6993; )
                        {
                            _6428 += ((_2932[_6425].x * _2932[_6419].y) * spvDepthCast(_200).sample_compare(_200Smplr, float3(fast::clamp(_180._m22.xy * (_2980 + float2(_2933[_6425].x, _2933[_6419].y)), _2922.xy, _2922.zw), _2885).xy, _2885));
                            _6425++;
                            continue;
                        }
                    }
                    _6429 = _6422 * (_2984 ? 0.0625 : 0.0069444444961845874786376953125);
                    break;
                } while(false);
                _6430 = _6429;
                break;
            } while(false);
            float3 _6467;
            float _6470;
            if (_2724 > _180._m17[_6417])
            {
                float _2778 = (_2724 - _180._m17[_6417]) / (_180._m16[_6417] - _180._m17[_6417]);
                int _2780 = _6417 + 1;
                float3 _6468;
                float _6471;
                if (_2780 < _2716)
                {
                    float _6450;
                    do
                    {
                        float4 _3127 = _180._m14[_2780] * float4(in.m_1451 + (_2052 * _180._m18[_2780]), 1.0);
                        float _3130 = _3127.x;
                        bool _3131 = _3130 < 0.0;
                        bool _3138;
                        if (!_3131)
                        {
                            _3138 = _3130 > 1.0;
                        }
                        else
                        {
                            _3138 = _3131;
                        }
                        bool _3145;
                        if (!_3138)
                        {
                            _3145 = _3127.y < 0.0;
                        }
                        else
                        {
                            _3145 = _3138;
                        }
                        bool _3152;
                        if (!_3145)
                        {
                            _3152 = _3127.y > 1.0;
                        }
                        else
                        {
                            _3152 = _3145;
                        }
                        if (_3152)
                        {
                            _6450 = 1.0;
                            break;
                        }
                        float2 _3165 = float2(float(_2780 & 1), float(_2780 >> 1)) * _180._m23.xy;
                        float _3172 = fast::min(_3127.z, 1.0) - _180._m19[_2780];
                        float2 _3191 = _180._m22.xy * 0.5;
                        float2 _3196 = _3165 + (_3127.xy * _180._m23.xy);
                        float4 _3209 = float4(_3165 + _3191, (_3165 + _180._m23.xy) - _3191);
                        float _6449;
                        do
                        {
                            int _3235 = int(_180._m22.z);
                            if (_3235 <= 0)
                            {
                                _6449 = spvDepthCast(_200).sample_compare(_200Smplr, float3(fast::clamp(_3196, _3209.xy, _3209.zw), _3172).xy, _3172);
                                break;
                            }
                            float2 _3258 = (_3196 / _180._m22.xy) + float2(0.5);
                            float2 _3259 = floor(_3258);
                            float2 _3264 = _3258 - _3259;
                            float2 _3267 = _3259 - float2(0.5);
                            bool _3271 = _3235 == 1;
                            spvUnsafeArray<float2, 3> _3219;
                            spvUnsafeArray<float2, 3> _3220;
                            if (_3271)
                            {
                                float2 _3274 = _3264 * 2.0;
                                _3219[0] = float2(3.0) - _3274;
                                _3219[1] = float2(1.0) + _3274;
                                _3220[0] = ((float2(2.0) - _3264) / _3219[0]) - float2(1.0);
                                _3220[1] = (_3264 / _3219[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _3301 = _3264 * 3.0;
                                _3219[0] = float2(4.0) - _3301;
                                _3219[1] = float2(7.0);
                                _3219[2] = float2(1.0) + _3301;
                                _3220[0] = ((float2(3.0) - (_3264 * 2.0)) / _3219[0]) - float2(2.0);
                                _3220[1] = (float2(3.0) + _3264) / _3219[1];
                                _3220[2] = (_3264 / _3219[2]) + float2(2.0);
                            }
                            int _6995 = _3271 ? 2 : 3;
                            int _6439;
                            float _6442;
                            _6442 = 0.0;
                            _6439 = 0;
                            float _6448;
                            for (; _6439 < _6995; _6442 = _6448, _6439++)
                            {
                                _6448 = _6442;
                                for (int _6445 = 0; _6445 < _6995; )
                                {
                                    _6448 += ((_3219[_6445].x * _3219[_6439].y) * spvDepthCast(_200).sample_compare(_200Smplr, float3(fast::clamp(_180._m22.xy * (_3267 + float2(_3220[_6445].x, _3220[_6439].y)), _3209.xy, _3209.zw), _3172).xy, _3172));
                                    _6445++;
                                    continue;
                                }
                            }
                            _6449 = _6442 * (_3271 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _6450 = _6449;
                        break;
                    } while(false);
                    _6471 = mix(_6430, _6450, _2778);
                    _6468 = mix(_554[_6417], _554[_2780], float3(_2778));
                }
                else
                {
                    _6471 = mix(_6430, 1.0, _2778);
                    _6468 = _554[_6417];
                }
                _6470 = _6471;
                _6467 = _6468;
            }
            else
            {
                _6470 = _6430;
                _6467 = _554[_6417];
            }
            _6473 = select(float3(1.0), _6467, bool3(_180._m22.w > 0.5));
            _6472 = _6470;
            break;
        } while(false);
        _6553 = _6472;
        _6526 = _6501 * _6473;
    }
    else
    {
        _6553 = 1.0;
        _6526 = _6501;
    }
    float3 _2083 = _180._m5.xyz * _180._m4.w;
    bool _2087 = _1821._m6.w > 0.5;
    float _6524;
    if (_2087)
    {
        _6524 = 1.0;
    }
    else
    {
        _6524 = 1.0 + (_1821._m4.w * (_1770.sample(_1217, _1840).x - 1.0));
    }
    float3 _6718;
    if (!_2017)
    {
        float _2111 = dot(_6529, _2034);
        float3 _6712;
        if (_180._m29.x > 0.5)
        {
            float _3452 = (_180._m29.z * _6529.x) - (_180._m29.w * _6529.z);
            float _3465 = (_180._m29.w * _6529.x) + (_180._m29.z * _6529.z);
            float _3483 = 1.09254801273345947265625 * _3452;
            spvUnsafeArray<float, 9> _6215 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _6529.y, 0.48860299587249755859375 * _3465, 0.48860299587249755859375 * _3452, _3483 * _6529.y, (1.09254801273345947265625 * _6529.y) * _3465, 0.3153919875621795654296875 * (((3.0 * _3465) * _3465) - 1.0), _3483 * _3465, 0.546274006366729736328125 * ((_3452 * _3452) - (_6529.y * _6529.y)) });
            spvUnsafeArray<float, 9> _3397 = _6215;
            float3 _6711;
            _6711 = float3(0.0);
            for (int _6710 = 0; _6710 < 9; )
            {
                _6711 += (_1215.read(uint2((int2(496, 256) + int2(_6710, 0))), 0).xyz * _3397[_6710]);
                _6710++;
                continue;
            }
            _6712 = fast::max(_6711, float3(0.0)) * _180._m29.y;
        }
        else
        {
            _6712 = mix(_180._m9.xyz, _180._m8.xyz, float3((_6529.y * 0.5) + 0.5)) * _180._m8.w;
        }
        float3 _2161 = (_6526 * ((_6712 * _6524) + ((_2083 * fast::max(_2111, 0.0)) * _6553))) + ((_2083 * ((powr(fast::max(dot(_6529, _2046), 0.0), _1821._m1.w) * _1821._m1.z) * step(0.0, _2111))) * _6553);
        float3 _6719;
        if (_180._m13.w > 0.5)
        {
            float2 _3568 = fast::clamp(floor(gl_FragCoord.xy * _180._m12.xy), float2(0.0), _180._m13.xy - float2(1.0));
            uint _3596 = uint((((fast::clamp(floor((log2(fast::max(dot(_180._m11.xyz, in.m_1451) + _180._m11.w, 9.9999999747524270787835121154785e-07)) * _180._m12.z) + _180._m12.w), 0.0, _180._m13.z - 1.0) * _180._m13.y) + _3568.y) * _180._m13.x) + _3568.x);
            uint _3598 = _3596 >> uint(2);
            uint _3600 = _3596 & 3u;
            uint _3604 = _1584._m0[_3598][_3600] & 65535u;
            uint _3606 = _1584._m0[_3598][_3600] >> uint(16);
            float3 _6720;
            _6720 = _2161;
            float3 _2242;
            spvUnsafeArray<float2, 3> _4014;
            spvUnsafeArray<float2, 3> _4015;
            spvUnsafeArray<float2, 3> _4227;
            spvUnsafeArray<float2, 3> _4228;
            for (uint _6717 = _3604; _6717 < (_3604 + _3606); _6720 = _2242, _6717++)
            {
                uint _3612 = _6717 / 3u;
                uint _3625 = (_1606._m0[_3612 >> uint(2)][_3612 & 3u] >> ((_6717 - (_3612 * 3u)) * 10u)) & 1023u;
                float3 _3642 = _1443._m0[_3625].xyz - in.m_1451;
                float _3645 = dot(_3642, _3642);
                float _3649 = _3645 * _1443._m0[_3625].w;
                float _3654 = fast::clamp(1.0 - (_3649 * _3649), 0.0, 1.0);
                float3 _3659 = _3642 * rsqrt(fast::max(_3645, 9.9999999392252902907785028219223e-09));
                float _3677 = fast::clamp((dot(-_3659, _1487._m0[_3625].xyz) * _1479._m0[_3625].w) + _1487._m0[_3625].w, 0.0, 1.0);
                float3 _3690 = _1479._m0[_3625].xyz * ((((_3654 * _3654) * _3677) * _3677) / fast::max(_3645, 9.9999997473787516355514526367188e-05));
                float3 _6912;
                if (_2057)
                {
                    float _6858;
                    do
                    {
                        uint _3726 = uint(_180._m21.z);
                        if (_3625 < _3726)
                        {
                            float _3748 = _180._m26[_3625].z * fast::max((_180._m15[_3625] * float4(in.m_1451, 1.0)).w, 0.0);
                            float4 _3772 = _180._m15[_3625] * float4((in.m_1451 + (_2052 * (_3748 * _180._m25.x))) + (_3659 * (_3748 * _180._m25.y)), 1.0);
                            float _3774 = _3772.w;
                            if (_3774 <= 0.0)
                            {
                                _6858 = 1.0;
                                break;
                            }
                            float3 _3783 = _3772.xyz / float3(_3774);
                            float _3785 = _3783.x;
                            bool _3786 = _3785 < 0.0;
                            bool _3793;
                            if (!_3786)
                            {
                                _3793 = _3785 > 1.0;
                            }
                            else
                            {
                                _3793 = _3786;
                            }
                            bool _3800;
                            if (!_3793)
                            {
                                _3800 = _3783.y < 0.0;
                            }
                            else
                            {
                                _3800 = _3793;
                            }
                            bool _3807;
                            if (!_3800)
                            {
                                _3807 = _3783.y > 1.0;
                            }
                            else
                            {
                                _3807 = _3800;
                            }
                            bool _3814;
                            if (!_3807)
                            {
                                _3814 = _3783.z > 1.0;
                            }
                            else
                            {
                                _3814 = _3807;
                            }
                            if (_3814)
                            {
                                _6858 = 1.0;
                                break;
                            }
                            float _3820 = _3783.z;
                            float2 _3986 = _180._m22.xy * 0.5;
                            float2 _3991 = _180._m26[_3625].xy + (_3783.xy * _180._m23.zw);
                            float4 _4004 = float4(_180._m26[_3625].xy + _3986, (_180._m26[_3625].xy + _180._m23.zw) - _3986);
                            float _6857;
                            do
                            {
                                int _4030 = int(_180._m22.z);
                                if (_4030 <= 0)
                                {
                                    float2 _4040 = fast::clamp(_3991, _4004.xy, _4004.zw);
                                    _6857 = spvDepthCast(_200).sample_compare(_200Smplr, float3(_4040, _3820).xy, _3820);
                                    break;
                                }
                                float2 _4053 = (_3991 / _180._m22.xy) + float2(0.5);
                                float2 _4054 = floor(_4053);
                                float2 _4059 = _4053 - _4054;
                                float2 _4062 = _4054 - float2(0.5);
                                bool _4066 = _4030 == 1;
                                if (_4066)
                                {
                                    float2 _4069 = _4059 * 2.0;
                                    _4014[0] = float2(3.0) - _4069;
                                    _4014[1] = float2(1.0) + _4069;
                                    _4015[0] = ((float2(2.0) - _4059) / _4014[0]) - float2(1.0);
                                    _4015[1] = (_4059 / _4014[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _4096 = _4059 * 3.0;
                                    _4014[0] = float2(4.0) - _4096;
                                    _4014[1] = float2(7.0);
                                    _4014[2] = float2(1.0) + _4096;
                                    _4015[0] = ((float2(3.0) - (_4059 * 2.0)) / _4014[0]) - float2(2.0);
                                    _4015[1] = (float2(3.0) + _4059) / _4014[1];
                                    _4015[2] = (_4059 / _4014[2]) + float2(2.0);
                                }
                                int _7000 = _4066 ? 2 : 3;
                                int _6847;
                                float _6850;
                                _6850 = 0.0;
                                _6847 = 0;
                                float _6856;
                                for (; _6847 < _7000; _6850 = _6856, _6847++)
                                {
                                    _6856 = _6850;
                                    for (int _6853 = 0; _6853 < _7000; )
                                    {
                                        _6856 += ((_4014[_6853].x * _4014[_6847].y) * spvDepthCast(_200).sample_compare(_200Smplr, float3(fast::clamp(_180._m22.xy * (_4062 + float2(_4015[_6853].x, _4015[_6847].y)), _4004.xy, _4004.zw), _3820).xy, _3820));
                                        _6853++;
                                        continue;
                                    }
                                }
                                _6857 = _6850 * (_4066 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _6858 = _6857;
                            break;
                        }
                        uint _3830 = _3625 - _3726;
                        if (_3830 >= uint(_180._m21.w))
                        {
                            _6858 = 1.0;
                            break;
                        }
                        float _3851 = _180._m27[_3830].w * length(in.m_1451 - _180._m27[_3830].xyz);
                        float3 _3869 = ((in.m_1451 + (_2052 * (_3851 * _180._m25.x))) + (_3659 * (_3851 * _180._m25.y))) - _180._m27[_3830].xyz;
                        float3 _3871 = abs(_3869);
                        float _3873 = _3871.x;
                        float _3875 = _3871.y;
                        bool _3876 = _3873 >= _3875;
                        bool _3884;
                        if (_3876)
                        {
                            _3884 = _3873 >= _3871.z;
                        }
                        else
                        {
                            _3884 = _3876;
                        }
                        float _6832;
                        int _6834;
                        if (_3884)
                        {
                            _6834 = (_3869.x > 0.0) ? 0 : 1;
                            _6832 = _3873;
                        }
                        else
                        {
                            float _3896 = _3871.z;
                            bool _3897 = _3875 >= _3896;
                            int _6835;
                            if (_3897)
                            {
                                _6835 = (_3869.y > 0.0) ? 2 : 3;
                            }
                            else
                            {
                                _6835 = (_3869.z > 0.0) ? 4 : 5;
                            }
                            _6834 = _6835;
                            _6832 = _3897 ? _3875 : _3896;
                        }
                        if (_6832 <= 0.0)
                        {
                            _6858 = 1.0;
                            break;
                        }
                        float2 _3934 = float2(dot(_3869, _858[_6834]), dot(_3869, _867[_6834])) / float2(_6832 * _180._m24.z);
                        float _3941 = _180._m28[_3830].z + (_180._m28[_3830].w / _6832);
                        if (_3941 > 1.0)
                        {
                            _6858 = 1.0;
                            break;
                        }
                        float2 _3959 = _180._m28[_3830].xy + (float2(float(spvSMod(_6834, 3)), float(_6834 / 3)) * _180._m24.xy);
                        float2 _4199 = _180._m22.xy * 0.5;
                        float2 _4204 = _3959 + (float2(0.5 + (0.5 * _3934.x), 0.5 - (0.5 * _3934.y)) * _180._m24.xy);
                        float4 _4217 = float4(_3959 + _4199, (_3959 + _180._m24.xy) - _4199);
                        float _6846;
                        do
                        {
                            int _4243 = int(_180._m22.z);
                            if (_4243 <= 0)
                            {
                                _6846 = spvDepthCast(_200).sample_compare(_200Smplr, float3(fast::clamp(_4204, _4217.xy, _4217.zw), _3941).xy, _3941);
                                break;
                            }
                            float2 _4266 = (_4204 / _180._m22.xy) + float2(0.5);
                            float2 _4267 = floor(_4266);
                            float2 _4272 = _4266 - _4267;
                            float2 _4275 = _4267 - float2(0.5);
                            bool _4279 = _4243 == 1;
                            if (_4279)
                            {
                                float2 _4282 = _4272 * 2.0;
                                _4227[0] = float2(3.0) - _4282;
                                _4227[1] = float2(1.0) + _4282;
                                _4228[0] = ((float2(2.0) - _4272) / _4227[0]) - float2(1.0);
                                _4228[1] = (_4272 / _4227[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _4309 = _4272 * 3.0;
                                _4227[0] = float2(4.0) - _4309;
                                _4227[1] = float2(7.0);
                                _4227[2] = float2(1.0) + _4309;
                                _4228[0] = ((float2(3.0) - (_4272 * 2.0)) / _4227[0]) - float2(2.0);
                                _4228[1] = (float2(3.0) + _4272) / _4227[1];
                                _4228[2] = (_4272 / _4227[2]) + float2(2.0);
                            }
                            int _7003 = _4279 ? 2 : 3;
                            int _6836;
                            float _6839;
                            _6839 = 0.0;
                            _6836 = 0;
                            float _6845;
                            for (; _6836 < _7003; _6839 = _6845, _6836++)
                            {
                                _6845 = _6839;
                                for (int _6842 = 0; _6842 < _7003; )
                                {
                                    _6845 += ((_4227[_6842].x * _4227[_6836].y) * spvDepthCast(_200).sample_compare(_200Smplr, float3(fast::clamp(_180._m22.xy * (_4275 + float2(_4228[_6842].x, _4228[_6836].y)), _4217.xy, _4217.zw), _3941).xy, _3941));
                                    _6842++;
                                    continue;
                                }
                            }
                            _6846 = _6839 * (_4279 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _6858 = _6846;
                        break;
                    } while(false);
                    _6912 = _3690 * _6858;
                }
                else
                {
                    _6912 = _3690;
                }
                float _2213 = dot(_6529, _3659);
                _2242 = _6720 + (((_6526 * fast::max(_2213, 0.0)) * _6912) + (_6912 * ((powr(fast::max(dot(_6529, fast::normalize(_3659 + _2041)), 0.0), _1821._m1.w) * _1821._m1.z) * step(0.0, _2213))));
            }
            _6719 = _6720;
        }
        else
        {
            _6719 = _2161;
        }
        _6718 = _6719;
    }
    else
    {
        float4 _2252 = _2247.sample(_1217, _1840);
        float _2259 = fast::clamp(_1821._m4.x * _2252.z, 0.0, 1.0);
        float _2267 = fast::clamp(_1821._m4.y * _2252.y, 0.04500000178813934326171875, 1.0);
        float _2271 = _2267 * _2267;
        float3 _2276 = _6526 * (1.0 - _2259);
        float3 _2282 = mix(float3(0.039999999105930328369140625), _6526, float3(_2259));
        float _2287 = fast::max(dot(_6529, _2041), 9.9999997473787516355514526367188e-05);
        float _2292 = fast::clamp(dot(_6529, _2034), 0.0, 1.0);
        float _2297 = fast::clamp(dot(_6529, _2046), 0.0, 1.0);
        float3 _4411 = float3(1.0) - _2282;
        float3 _4414 = _2282 + (_4411 * powr(1.0 - fast::clamp(dot(_2041, _2046), 0.0, 1.0), 5.0));
        float _4421 = _2271 * _2271;
        float _4426 = _4421 - 1.0;
        float _4428 = ((_2297 * _2297) * _4426) + 1.0;
        float _4448 = 1.0 - _4421;
        float _4452 = sqrt(((_2287 * _2287) * _4448) + _4421);
        float3 _6572;
        float2 _6587;
        float3 _6599;
        if (_180._m29.x > 0.5)
        {
            float4 _4485 = _1321.sample(_1323, (((float2(_2287, _2267) * 31.0) + float2(0.5)) * float2(0.03125)));
            float _4544 = (_180._m29.z * _6529.x) - (_180._m29.w * _6529.z);
            float _4557 = (_180._m29.w * _6529.x) + (_180._m29.z * _6529.z);
            float _4575 = 1.09254801273345947265625 * _4544;
            spvUnsafeArray<float, 9> _6196 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _6529.y, 0.48860299587249755859375 * _4557, 0.48860299587249755859375 * _4544, _4575 * _6529.y, (1.09254801273345947265625 * _6529.y) * _4557, 0.3153919875621795654296875 * (((3.0 * _4557) * _4557) - 1.0), _4575 * _4557, 0.546274006366729736328125 * ((_4544 * _4544) - (_6529.y * _6529.y)) });
            spvUnsafeArray<float, 9> _4489 = _6196;
            float3 _6555;
            _6555 = float3(0.0);
            for (int _6554 = 0; _6554 < 9; )
            {
                _6555 += (_1215.read(uint2((int2(496, 256) + int2(_6554, 0))), 0).xyz * _4489[_6554]);
                _6554++;
                continue;
            }
            float3 _2358 = reflect(-_2041, _6529);
            float _4670 = _2358.x;
            float _4675 = _2358.z;
            float2 _4707 = float2((precise::atan2((_180._m29.z * _4670) - (_180._m29.w * _4675), -((_180._m29.w * _4670) + (_180._m29.z * _4675))) * 0.15915493667125701904296875) + 0.5, acos(fast::clamp(_2358.y, -1.0, 1.0)) * 0.3183098733425140380859375);
            float _4639 = _2267 * 5.0;
            int _4642 = min(int(_4639), 4);
            float2 _4728 = (_4707 * float2(_1277[_4642].zw)) - float2(0.5);
            float2 _4730 = floor(_4728);
            float2 _4733 = _4728 - _4730;
            int _4736 = int(_4730.x);
            int _4739 = int(_4730.y);
            int _6557;
            if (_4736 < 0)
            {
                _6557 = _4736 + _1277[_4642].z;
            }
            else
            {
                _6557 = _4736;
            }
            int _6558;
            if (_6557 >= _1277[_4642].z)
            {
                _6558 = _6557 - _1277[_4642].z;
            }
            else
            {
                _6558 = _6557;
            }
            int _4759 = _6558 + 1;
            int _7004 = (_4759 == _1277[_4642].z) ? 0 : _4759;
            int _4774 = min((_4739 + 1), (_1277[_4642].w - 1));
            int _4776 = max(_4739, 0);
            float3 _4829 = float3(_4733.x);
            int _4649 = _4642 + 1;
            float2 _4861 = (_4707 * float2(_1277[_4649].zw)) - float2(0.5);
            float2 _4863 = floor(_4861);
            float2 _4866 = _4861 - _4863;
            int _4869 = int(_4863.x);
            int _4872 = int(_4863.y);
            int _6564;
            if (_4869 < 0)
            {
                _6564 = _4869 + _1277[_4649].z;
            }
            else
            {
                _6564 = _4869;
            }
            int _6565;
            if (_6564 >= _1277[_4649].z)
            {
                _6565 = _6564 - _1277[_4649].z;
            }
            else
            {
                _6565 = _6564;
            }
            int _4892 = _6565 + 1;
            int _7005 = (_4892 == _1277[_4649].z) ? 0 : _4892;
            int _4907 = min((_4872 + 1), (_1277[_4649].w - 1));
            int _4909 = max(_4872, 0);
            float3 _4962 = float3(_4866.x);
            float3 _4664 = mix(mix(mix(_1215.read(uint2((_1277[_4642].xy + int2(_6558, _4776))), 0).xyz, _1215.read(uint2((_1277[_4642].xy + int2(_7004, _4776))), 0).xyz, _4829), mix(_1215.read(uint2((_1277[_4642].xy + int2(_6558, _4774))), 0).xyz, _1215.read(uint2((_1277[_4642].xy + int2(_7004, _4774))), 0).xyz, _4829), float3(_4733.y)), mix(mix(_1215.read(uint2((_1277[_4649].xy + int2(_6565, _4909))), 0).xyz, _1215.read(uint2((_1277[_4649].xy + int2(_7005, _4909))), 0).xyz, _4962), mix(_1215.read(uint2((_1277[_4649].xy + int2(_6565, _4907))), 0).xyz, _1215.read(uint2((_1277[_4649].xy + int2(_7005, _4907))), 0).xyz, _4962), float3(_4866.y)), float3(_4639 - float(_4642))) * _180._m29.y;
            _6599 = fast::max(_6555, float3(0.0)) * _180._m29.y;
            _6587 = _4485.xy;
            _6572 = _4664;
        }
        else
        {
            float4 _4980 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * _2267) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);
            float _4982 = _4980.x;
            float3 _5017 = mix(_180._m9.xyz, _180._m8.xyz, float3((_6529.y * 0.5) + 0.5)) * _180._m8.w;
            _6599 = _5017;
            _6587 = (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_4982 * _4982, exp2((-9.27999973297119140625) * _2287)) * _4982) + _4980.y)) + _4980.zw;
            _6572 = mix(mix(_180._m9.xyz, _180._m8.xyz, float3((reflect(-_2041, _6529).y * 0.5) + 0.5)) * _180._m8.w, _5017, float3(_2267));
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
        float3 _6608;
        if (_2390)
        {
            float3 _6584;
            do
            {
                float _5096 = ((_180._m32.x * (1.0 - smoothstep(_180._m33.x * 0.5, _180._m33.x, abs(dot(_180._m31.xyz, in.m_1451) - _180._m31.w)))) * smoothstep(0.5, 0.89999997615814208984375, dot(_2052, _180._m31.xyz))) * (1.0 - smoothstep(_180._m32.y * 0.5, _180._m32.y, _2267));
                if (_5096 <= 0.0)
                {
                    _6584 = _6572;
                    break;
                }
                float4 _5121 = _180._m30 * float4(in.m_1451 + ((_6529 - (_180._m31.xyz * dot(_6529, _180._m31.xyz))) * _180._m32.w), 1.0);
                float2 _5134 = ((float2(_5121.x, -_5121.y) / float2(_5121.w)) * 0.5) + float2(0.5);
                float _5138 = _180._m32.z * _2267;
                float3 _6582;
                float _6583;
                _6583 = 0.0;
                _6582 = float3(0.0);
                for (int _6581 = 0; _6581 < 12; )
                {
                    float _5145 = float(_6581);
                    float _5153 = _5145 * 2.3999631404876708984375;
                    float2 _5165 = _5134 + (float2(cos(_5153) * _180._m33.y, sin(_5153)) * (sqrt((_5145 + 0.5) * 0.083333335816860198974609375) * _5138));
                    float2 _5170 = fast::min(_5165, float2(1.0) - _5165);
                    float _5176 = smoothstep(0.0, 0.039999999105930328369140625, fast::min(_5170.x, _5170.y));
                    float4 _5184 = _1770.sample(_1217, fast::clamp(_5165, float2(0.0), float2(1.0)), level(0.0));
                    float3 _5186 = _5184.xyz;
                    _6583 += (_5184.w * _5176);
                    _6582 += ((_5186 / (float3(1.0) - fast::min(_5186, float3(0.99500000476837158203125)))) * _5176);
                    _6581++;
                    continue;
                }
                _6584 = mix(_6572, (_6582 * float3(0.083333335816860198974609375)) + (_6572 * (1.0 - (_6583 * 0.083333335816860198974609375))), float3(_5096));
                break;
            } while(false);
            _6608 = _6584;
        }
        else
        {
            _6608 = _6572;
        }
        float3 _2410 = (_2282 * _6587.x) + float3(_6587.y);
        float3 _2426 = ((((((float3(1.0) - _4414) * _2276) + ((_4414 * ((_4421 / ((3.1415927410125732421875 * _4428) * _4428)) * (0.5 / fast::max((_2292 * _4452) + (_2287 * sqrt(((_2292 * _2292) * _4448) + _4421)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875)) * _2292) * _2083) * _6553) + (((((float3(1.0) - _2410) * _2276) * _6599) + (_2410 * _6608)) * _6524);
        float3 _6721;
        if (_180._m13.w > 0.5)
        {
            float2 _5250 = fast::clamp(floor(gl_FragCoord.xy * _180._m12.xy), float2(0.0), _180._m13.xy - float2(1.0));
            uint _5278 = uint((((fast::clamp(floor((log2(fast::max(dot(_180._m11.xyz, in.m_1451) + _180._m11.w, 9.9999999747524270787835121154785e-07)) * _180._m12.z) + _180._m12.w), 0.0, _180._m13.z - 1.0) * _180._m13.y) + _5250.y) * _180._m13.x) + _5250.x);
            uint _5280 = _5278 >> uint(2);
            uint _5282 = _5278 & 3u;
            uint _5286 = _1584._m0[_5280][_5282] & 65535u;
            uint _5288 = _1584._m0[_5280][_5282] >> uint(16);
            float3 _6676;
            _6676 = _2426;
            float3 _2526;
            spvUnsafeArray<float2, 3> _5696;
            spvUnsafeArray<float2, 3> _5697;
            spvUnsafeArray<float2, 3> _5909;
            spvUnsafeArray<float2, 3> _5910;
            for (uint _6609 = _5286; _6609 < (_5286 + _5288); _6676 = _2526, _6609++)
            {
                uint _5294 = _6609 / 3u;
                uint _5307 = (_1606._m0[_5294 >> uint(2)][_5294 & 3u] >> ((_6609 - (_5294 * 3u)) * 10u)) & 1023u;
                float3 _5324 = _1443._m0[_5307].xyz - in.m_1451;
                float _5327 = dot(_5324, _5324);
                float _5331 = _5327 * _1443._m0[_5307].w;
                float _5336 = fast::clamp(1.0 - (_5331 * _5331), 0.0, 1.0);
                float3 _5341 = _5324 * rsqrt(fast::max(_5327, 9.9999999392252902907785028219223e-09));
                float _5359 = fast::clamp((dot(-_5341, _1487._m0[_5307].xyz) * _1479._m0[_5307].w) + _1487._m0[_5307].w, 0.0, 1.0);
                float3 _5372 = _1479._m0[_5307].xyz * ((((_5336 * _5336) * _5359) * _5359) / fast::max(_5327, 9.9999997473787516355514526367188e-05));
                float3 _6674;
                if (_2057)
                {
                    float _6636;
                    do
                    {
                        uint _5408 = uint(_180._m21.z);
                        if (_5307 < _5408)
                        {
                            float _5430 = _180._m26[_5307].z * fast::max((_180._m15[_5307] * float4(in.m_1451, 1.0)).w, 0.0);
                            float4 _5454 = _180._m15[_5307] * float4((in.m_1451 + (_2052 * (_5430 * _180._m25.x))) + (_5341 * (_5430 * _180._m25.y)), 1.0);
                            float _5456 = _5454.w;
                            if (_5456 <= 0.0)
                            {
                                _6636 = 1.0;
                                break;
                            }
                            float3 _5465 = _5454.xyz / float3(_5456);
                            float _5467 = _5465.x;
                            bool _5468 = _5467 < 0.0;
                            bool _5475;
                            if (!_5468)
                            {
                                _5475 = _5467 > 1.0;
                            }
                            else
                            {
                                _5475 = _5468;
                            }
                            bool _5482;
                            if (!_5475)
                            {
                                _5482 = _5465.y < 0.0;
                            }
                            else
                            {
                                _5482 = _5475;
                            }
                            bool _5489;
                            if (!_5482)
                            {
                                _5489 = _5465.y > 1.0;
                            }
                            else
                            {
                                _5489 = _5482;
                            }
                            bool _5496;
                            if (!_5489)
                            {
                                _5496 = _5465.z > 1.0;
                            }
                            else
                            {
                                _5496 = _5489;
                            }
                            if (_5496)
                            {
                                _6636 = 1.0;
                                break;
                            }
                            float _5502 = _5465.z;
                            float2 _5668 = _180._m22.xy * 0.5;
                            float2 _5673 = _180._m26[_5307].xy + (_5465.xy * _180._m23.zw);
                            float4 _5686 = float4(_180._m26[_5307].xy + _5668, (_180._m26[_5307].xy + _180._m23.zw) - _5668);
                            float _6635;
                            do
                            {
                                int _5712 = int(_180._m22.z);
                                if (_5712 <= 0)
                                {
                                    float2 _5722 = fast::clamp(_5673, _5686.xy, _5686.zw);
                                    _6635 = spvDepthCast(_200).sample_compare(_200Smplr, float3(_5722, _5502).xy, _5502);
                                    break;
                                }
                                float2 _5735 = (_5673 / _180._m22.xy) + float2(0.5);
                                float2 _5736 = floor(_5735);
                                float2 _5741 = _5735 - _5736;
                                float2 _5744 = _5736 - float2(0.5);
                                bool _5748 = _5712 == 1;
                                if (_5748)
                                {
                                    float2 _5751 = _5741 * 2.0;
                                    _5696[0] = float2(3.0) - _5751;
                                    _5696[1] = float2(1.0) + _5751;
                                    _5697[0] = ((float2(2.0) - _5741) / _5696[0]) - float2(1.0);
                                    _5697[1] = (_5741 / _5696[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _5778 = _5741 * 3.0;
                                    _5696[0] = float2(4.0) - _5778;
                                    _5696[1] = float2(7.0);
                                    _5696[2] = float2(1.0) + _5778;
                                    _5697[0] = ((float2(3.0) - (_5741 * 2.0)) / _5696[0]) - float2(2.0);
                                    _5697[1] = (float2(3.0) + _5741) / _5696[1];
                                    _5697[2] = (_5741 / _5696[2]) + float2(2.0);
                                }
                                int _7007 = _5748 ? 2 : 3;
                                int _6625;
                                float _6628;
                                _6628 = 0.0;
                                _6625 = 0;
                                float _6634;
                                for (; _6625 < _7007; _6628 = _6634, _6625++)
                                {
                                    _6634 = _6628;
                                    for (int _6631 = 0; _6631 < _7007; )
                                    {
                                        _6634 += ((_5696[_6631].x * _5696[_6625].y) * spvDepthCast(_200).sample_compare(_200Smplr, float3(fast::clamp(_180._m22.xy * (_5744 + float2(_5697[_6631].x, _5697[_6625].y)), _5686.xy, _5686.zw), _5502).xy, _5502));
                                        _6631++;
                                        continue;
                                    }
                                }
                                _6635 = _6628 * (_5748 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _6636 = _6635;
                            break;
                        }
                        uint _5512 = _5307 - _5408;
                        if (_5512 >= uint(_180._m21.w))
                        {
                            _6636 = 1.0;
                            break;
                        }
                        float _5533 = _180._m27[_5512].w * length(in.m_1451 - _180._m27[_5512].xyz);
                        float3 _5551 = ((in.m_1451 + (_2052 * (_5533 * _180._m25.x))) + (_5341 * (_5533 * _180._m25.y))) - _180._m27[_5512].xyz;
                        float3 _5553 = abs(_5551);
                        float _5555 = _5553.x;
                        float _5557 = _5553.y;
                        bool _5558 = _5555 >= _5557;
                        bool _5566;
                        if (_5558)
                        {
                            _5566 = _5555 >= _5553.z;
                        }
                        else
                        {
                            _5566 = _5558;
                        }
                        float _6610;
                        int _6612;
                        if (_5566)
                        {
                            _6612 = (_5551.x > 0.0) ? 0 : 1;
                            _6610 = _5555;
                        }
                        else
                        {
                            float _5578 = _5553.z;
                            bool _5579 = _5557 >= _5578;
                            int _6613;
                            if (_5579)
                            {
                                _6613 = (_5551.y > 0.0) ? 2 : 3;
                            }
                            else
                            {
                                _6613 = (_5551.z > 0.0) ? 4 : 5;
                            }
                            _6612 = _6613;
                            _6610 = _5579 ? _5557 : _5578;
                        }
                        if (_6610 <= 0.0)
                        {
                            _6636 = 1.0;
                            break;
                        }
                        float2 _5616 = float2(dot(_5551, _858[_6612]), dot(_5551, _867[_6612])) / float2(_6610 * _180._m24.z);
                        float _5623 = _180._m28[_5512].z + (_180._m28[_5512].w / _6610);
                        if (_5623 > 1.0)
                        {
                            _6636 = 1.0;
                            break;
                        }
                        float2 _5641 = _180._m28[_5512].xy + (float2(float(spvSMod(_6612, 3)), float(_6612 / 3)) * _180._m24.xy);
                        float2 _5881 = _180._m22.xy * 0.5;
                        float2 _5886 = _5641 + (float2(0.5 + (0.5 * _5616.x), 0.5 - (0.5 * _5616.y)) * _180._m24.xy);
                        float4 _5899 = float4(_5641 + _5881, (_5641 + _180._m24.xy) - _5881);
                        float _6624;
                        do
                        {
                            int _5925 = int(_180._m22.z);
                            if (_5925 <= 0)
                            {
                                _6624 = spvDepthCast(_200).sample_compare(_200Smplr, float3(fast::clamp(_5886, _5899.xy, _5899.zw), _5623).xy, _5623);
                                break;
                            }
                            float2 _5948 = (_5886 / _180._m22.xy) + float2(0.5);
                            float2 _5949 = floor(_5948);
                            float2 _5954 = _5948 - _5949;
                            float2 _5957 = _5949 - float2(0.5);
                            bool _5961 = _5925 == 1;
                            if (_5961)
                            {
                                float2 _5964 = _5954 * 2.0;
                                _5909[0] = float2(3.0) - _5964;
                                _5909[1] = float2(1.0) + _5964;
                                _5910[0] = ((float2(2.0) - _5954) / _5909[0]) - float2(1.0);
                                _5910[1] = (_5954 / _5909[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _5991 = _5954 * 3.0;
                                _5909[0] = float2(4.0) - _5991;
                                _5909[1] = float2(7.0);
                                _5909[2] = float2(1.0) + _5991;
                                _5910[0] = ((float2(3.0) - (_5954 * 2.0)) / _5909[0]) - float2(2.0);
                                _5910[1] = (float2(3.0) + _5954) / _5909[1];
                                _5910[2] = (_5954 / _5909[2]) + float2(2.0);
                            }
                            int _7010 = _5961 ? 2 : 3;
                            int _6614;
                            float _6617;
                            _6617 = 0.0;
                            _6614 = 0;
                            float _6623;
                            for (; _6614 < _7010; _6617 = _6623, _6614++)
                            {
                                _6623 = _6617;
                                for (int _6620 = 0; _6620 < _7010; )
                                {
                                    _6623 += ((_5909[_6620].x * _5909[_6614].y) * spvDepthCast(_200).sample_compare(_200Smplr, float3(fast::clamp(_180._m22.xy * (_5957 + float2(_5910[_6620].x, _5910[_6614].y)), _5899.xy, _5899.zw), _5623).xy, _5623));
                                    _6620++;
                                    continue;
                                }
                            }
                            _6624 = _6617 * (_5961 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _6636 = _6624;
                        break;
                    } while(false);
                    _6674 = _5372 * _6636;
                }
                else
                {
                    _6674 = _5372;
                }
                float3 _2478 = fast::normalize(_5341 + _2041);
                float _2483 = fast::clamp(dot(_6529, _5341), 0.0, 1.0);
                float _2488 = fast::clamp(dot(_6529, _2478), 0.0, 1.0);
                float3 _6096 = _2282 + (_4411 * powr(1.0 - fast::clamp(dot(_2041, _2478), 0.0, 1.0), 5.0));
                float _6110 = ((_2488 * _2488) * _4426) + 1.0;
                _2526 = _6676 + (((((float3(1.0) - _6096) * _2276) + ((_6096 * ((_4421 / ((3.1415927410125732421875 * _6110) * _6110)) * (0.5 / fast::max((_2483 * _4452) + (_2287 * sqrt(((_2483 * _2483) * _4448) + _4421)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875)) * _2483) * _6674);
            }
            _6721 = _6676;
        }
        else
        {
            _6721 = _2426;
        }
        _6718 = _6721;
    }
    float4 _2543 = _2538.sample(_1217, _1840);
    float _2561 = -length(_2040);
    float _6759;
    if (_180._m9.w != 0.0)
    {
        float _2585 = _180._m9.w * (in.m_1451 - _180._m6.xyz).y;
        float _6756;
        if (abs(_2585) < 9.9999997473787516355514526367188e-05)
        {
            _6756 = 1.0 - (0.5 * _2585);
        }
        else
        {
            _6756 = (1.0 - exp(fast::min(-_2585, 60.0))) / _2585;
        }
        _6759 = 1.0 - exp((_2561 * (_180._m7.w * exp(fast::min((-_180._m9.w) * (_180._m6.y - _180._m6.w), 30.0)))) * _6756);
    }
    else
    {
        _6759 = 1.0 - exp(_2561 * _180._m7.w);
    }
    float3 _2636 = mix(mix(_6718, _6526, float3(_1821._m1.y)) + ((_1821._m5.xyz * _2543.xyz) * (float3(1.0) + in.m_2054.yzw)), _180._m7.xyz, float3(_6759));
    float3 _6760;
    if (_180._m33.w > 0.5)
    {
        _6760 = _2636 / (float3(1.0) + _2636);
    }
    else
    {
        _6760 = _2636;
    }
    out.m_2648 = float4(_6760, in.m_1849.w);
    float2 _6831;
    do
    {
        if (in.m_2658.w <= 0.0)
        {
            _6831 = float2(0.0);
            break;
        }
        _6831 = ((in.m_2658.xy / float2(in.m_2658.w)) - (in.m_2657.xy / float2(in.m_2657.w))) * float2(0.5, -0.5);
        break;
    } while(false);
    out.m_2656 = _6831;
    return out;
}

