// Generated from mesh.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: ab98395f9b076993
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

struct _130
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
};

struct _1012
{
    float4 _m0[1024];
};

struct _1048
{
    float4 _m0[1024];
};

struct _1056
{
    float4 _m0[1024];
};

struct _1153
{
    uint4 _m0[1024];
};

struct _1175
{
    uint4 _m0[1024];
};

struct _1196
{
    float4 _m0;
    float4 _m1;
    float4 _m2;
    float4 _m3;
    float4 _m4;
    float4 _m5;
    float4 _m6;
};

constant spvUnsafeArray<float3, 4> _506 = spvUnsafeArray<float3, 4>({ float3(1.0, 0.449999988079071044921875, 0.449999988079071044921875), float3(0.449999988079071044921875, 1.0, 0.449999988079071044921875), float3(0.5, 0.60000002384185791015625, 1.0), float3(1.0, 1.0, 0.4000000059604644775390625) });
constant spvUnsafeArray<float3, 6> _810 = spvUnsafeArray<float3, 6>({ float3(0.0, 0.0, 1.0), float3(0.0, 0.0, -1.0), float3(-1.0, 0.0, 0.0), float3(-1.0, 0.0, 0.0), float3(-1.0, 0.0, 0.0), float3(1.0, 0.0, 0.0) });
constant spvUnsafeArray<float3, 6> _819 = spvUnsafeArray<float3, 6>({ float3(0.0, 1.0, 0.0), float3(0.0, 1.0, 0.0), float3(0.0, 0.0, -1.0), float3(0.0, 0.0, 1.0), float3(0.0, 1.0, 0.0), float3(0.0, 1.0, 0.0) });

struct fragment_main_out
{
    float4 m_1842 [[color(0)]];
};

struct fragment_main_in
{
    float3 m_1022 [[user(locn0)]];
    float3 m_1276 [[user(locn1)]];
    float2 m_1203 [[user(locn2)]];
    float4 m_1232 [[user(locn3)]];
    float4 m_1390 [[user(locn5)]];
    float4 m_1857 [[user(locn6)]];
    float4 m_1858 [[user(locn7)]];
    float4 m_1286 [[user(locn8)]];
};

fragment fragment_main_out fragment_main(fragment_main_in in [[stage_in]], constant _1196& _1198 [[buffer(2)]], constant _1012& _1014 [[buffer(3)]], constant _1048& _1050 [[buffer(4)]], constant _1056& _1058 [[buffer(5)]], constant _1153& _1155 [[buffer(6)]], constant _1175& _1177 [[buffer(7)]], constant _130& _132 [[buffer(15)]], texture2d<float> _152 [[texture(0)]], texture2d<float> _1221 [[texture(1)]], texture2d<float> _1565 [[texture(2)]], texture2d<float> _1315 [[texture(3)]], texture2d<float> _1423 [[texture(4)]], texture2d<float> _1815 [[texture(5)]], sampler _152Smplr [[sampler(0)]], sampler _1225 [[sampler(1)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])
{
    float2 _1856;
    fragment_main_out out = {};
    float2 _1217 = float2(dot(_1198._m2.xy, in.m_1203) + _1198._m2.z, dot(_1198._m3.xy, in.m_1203) + _1198._m3.z);
    float4 _1230 = _1221.sample(_1225, _1217);
    float3 _1241 = (in.m_1232.xyz * _1198._m0.xyz) * _1230.xyz;
    float3 _4743;
    if (_1198._m1.x > 0.5)
    {
        float2 _1262 = floor(in.m_1022.xz * float2(0.5));
        _4743 = _1241 * ((mod(abs(_1262.x + _1262.y), 2.0) < 0.5) ? 1.0 : 0.75);
    }
    else
    {
        _4743 = _1241;
    }
    float3 _1278 = fast::normalize(in.m_1276);
    float3 _4657;
    if (_1198._m6.y > 0.5)
    {
        float3 _1295 = in.m_1286.xyz - (_1278 * dot(_1278, in.m_1286.xyz));
        float3 _4658;
        if (dot(_1295, _1295) > 9.9999999600419720025001879548654e-13)
        {
            float3 _1304 = fast::normalize(_1295);
            float3 _1324 = (_1315.sample(_1225, _1217).xyz * 2.0) - float3(1.0);
            float2 _1329 = _1324.xy * _1198._m4.z;
            _4658 = fast::normalize(((_1304 * _1329.x) + ((cross(_1278, _1304) * ((in.m_1286.w < 0.0) ? (-1.0) : 1.0)) * _1329.y)) + (_1278 * _1324.z));
        }
        else
        {
            _4658 = _1278;
        }
        _4657 = _4658;
    }
    else
    {
        _4657 = _1278;
    }
    bool _1353 = _1198._m5.w > 0.5;
    bool _1361;
    if (_1353)
    {
        _1361 = !gl_FrontFacing;
    }
    else
    {
        _1361 = _1353;
    }
    float3 _4766;
    if (_1361)
    {
        _4766 = -_4657;
    }
    else
    {
        _4766 = _4657;
    }
    float3 _1370 = fast::normalize(_132._m4.xyz);
    float3 _1376 = _132._m6.xyz - in.m_1022;
    float3 _1377 = fast::normalize(_1376);
    float3 _1382 = fast::normalize(_1370 + _1377);
    float3 _1388 = _1278 * (gl_FrontFacing ? 1.0 : (-1.0));
    bool _1393 = in.m_1390.x > 0.5;
    float3 _4764;
    float _4789;
    if ((_132._m5.w > 0.5) && _1393)
    {
        float _4714;
        float3 _4715;
        do
        {
            int _1911 = int(_132._m21.x);
            float _1919 = dot(_132._m20.xyz, in.m_1022) + _132._m20.w;
            int _4659;
            _4659 = 0;
            for (;;)
            {
                bool _1925 = _4659 < (_1911 - 1);
                bool _1933;
                if (_1925)
                {
                    _1933 = _1919 > _132._m16[_4659];
                }
                else
                {
                    _1933 = _1925;
                }
                if (_1933)
                {
                    _4659++;
                    continue;
                }
                else
                {
                    break;
                }
            }
            if (_1919 > _132._m16[_4659])
            {
                _4715 = float3(1.0);
                _4714 = 1.0;
                break;
            }
            float _4672;
            do
            {
                float4 _2035 = _132._m14[_4659] * float4(in.m_1022 + (_1388 * _132._m18[_4659]), 1.0);
                float _2038 = _2035.x;
                bool _2039 = _2038 < 0.0;
                bool _2046;
                if (!_2039)
                {
                    _2046 = _2038 > 1.0;
                }
                else
                {
                    _2046 = _2039;
                }
                bool _2053;
                if (!_2046)
                {
                    _2053 = _2035.y < 0.0;
                }
                else
                {
                    _2053 = _2046;
                }
                bool _2060;
                if (!_2053)
                {
                    _2060 = _2035.y > 1.0;
                }
                else
                {
                    _2060 = _2053;
                }
                if (_2060)
                {
                    _4672 = 1.0;
                    break;
                }
                float2 _2073 = float2(float(_4659 & 1), float(_4659 >> 1)) * _132._m23.xy;
                float _2080 = fast::min(_2035.z, 1.0) - _132._m19[_4659];
                float2 _2099 = _132._m22.xy * 0.5;
                float2 _2104 = _2073 + (_2035.xy * _132._m23.xy);
                float4 _2117 = float4(_2073 + _2099, (_2073 + _132._m23.xy) - _2099);
                float _4671;
                do
                {
                    int _2143 = int(_132._m22.z);
                    if (_2143 <= 0)
                    {
                        _4671 = spvDepthCast(_152).sample_compare(_152Smplr, float3(fast::clamp(_2104, _2117.xy, _2117.zw), _2080).xy, _2080);
                        break;
                    }
                    float2 _2166 = (_2104 / _132._m22.xy) + float2(0.5);
                    float2 _2167 = floor(_2166);
                    float2 _2172 = _2166 - _2167;
                    float2 _2175 = _2167 - float2(0.5);
                    bool _2179 = _2143 == 1;
                    spvUnsafeArray<float2, 3> _2127;
                    spvUnsafeArray<float2, 3> _2128;
                    if (_2179)
                    {
                        float2 _2182 = _2172 * 2.0;
                        _2127[0] = float2(3.0) - _2182;
                        _2127[1] = float2(1.0) + _2182;
                        _2128[0] = ((float2(2.0) - _2172) / _2127[0]) - float2(1.0);
                        _2128[1] = (_2172 / _2127[1]) + float2(1.0);
                    }
                    else
                    {
                        float2 _2209 = _2172 * 3.0;
                        _2127[0] = float2(4.0) - _2209;
                        _2127[1] = float2(7.0);
                        _2127[2] = float2(1.0) + _2209;
                        _2128[0] = ((float2(3.0) - (_2172 * 2.0)) / _2127[0]) - float2(2.0);
                        _2128[1] = (float2(3.0) + _2172) / _2127[1];
                        _2128[2] = (_2172 / _2127[2]) + float2(2.0);
                    }
                    int _5048 = _2179 ? 2 : 3;
                    int _4661;
                    float _4664;
                    _4664 = 0.0;
                    _4661 = 0;
                    float _4670;
                    for (; _4661 < _5048; _4664 = _4670, _4661++)
                    {
                        _4670 = _4664;
                        for (int _4667 = 0; _4667 < _5048; )
                        {
                            _4670 += ((_2127[_4667].x * _2127[_4661].y) * spvDepthCast(_152).sample_compare(_152Smplr, float3(fast::clamp(_132._m22.xy * (_2175 + float2(_2128[_4667].x, _2128[_4661].y)), _2117.xy, _2117.zw), _2080).xy, _2080));
                            _4667++;
                            continue;
                        }
                    }
                    _4671 = _4664 * (_2179 ? 0.0625 : 0.0069444444961845874786376953125);
                    break;
                } while(false);
                _4672 = _4671;
                break;
            } while(false);
            float3 _4709;
            float _4712;
            if (_1919 > _132._m17[_4659])
            {
                float _1973 = (_1919 - _132._m17[_4659]) / (_132._m16[_4659] - _132._m17[_4659]);
                int _1975 = _4659 + 1;
                float3 _4710;
                float _4713;
                if (_1975 < _1911)
                {
                    float _4692;
                    do
                    {
                        float4 _2322 = _132._m14[_1975] * float4(in.m_1022 + (_1388 * _132._m18[_1975]), 1.0);
                        float _2325 = _2322.x;
                        bool _2326 = _2325 < 0.0;
                        bool _2333;
                        if (!_2326)
                        {
                            _2333 = _2325 > 1.0;
                        }
                        else
                        {
                            _2333 = _2326;
                        }
                        bool _2340;
                        if (!_2333)
                        {
                            _2340 = _2322.y < 0.0;
                        }
                        else
                        {
                            _2340 = _2333;
                        }
                        bool _2347;
                        if (!_2340)
                        {
                            _2347 = _2322.y > 1.0;
                        }
                        else
                        {
                            _2347 = _2340;
                        }
                        if (_2347)
                        {
                            _4692 = 1.0;
                            break;
                        }
                        float2 _2360 = float2(float(_1975 & 1), float(_1975 >> 1)) * _132._m23.xy;
                        float _2367 = fast::min(_2322.z, 1.0) - _132._m19[_1975];
                        float2 _2386 = _132._m22.xy * 0.5;
                        float2 _2391 = _2360 + (_2322.xy * _132._m23.xy);
                        float4 _2404 = float4(_2360 + _2386, (_2360 + _132._m23.xy) - _2386);
                        float _4691;
                        do
                        {
                            int _2430 = int(_132._m22.z);
                            if (_2430 <= 0)
                            {
                                _4691 = spvDepthCast(_152).sample_compare(_152Smplr, float3(fast::clamp(_2391, _2404.xy, _2404.zw), _2367).xy, _2367);
                                break;
                            }
                            float2 _2453 = (_2391 / _132._m22.xy) + float2(0.5);
                            float2 _2454 = floor(_2453);
                            float2 _2459 = _2453 - _2454;
                            float2 _2462 = _2454 - float2(0.5);
                            bool _2466 = _2430 == 1;
                            spvUnsafeArray<float2, 3> _2414;
                            spvUnsafeArray<float2, 3> _2415;
                            if (_2466)
                            {
                                float2 _2469 = _2459 * 2.0;
                                _2414[0] = float2(3.0) - _2469;
                                _2414[1] = float2(1.0) + _2469;
                                _2415[0] = ((float2(2.0) - _2459) / _2414[0]) - float2(1.0);
                                _2415[1] = (_2459 / _2414[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _2496 = _2459 * 3.0;
                                _2414[0] = float2(4.0) - _2496;
                                _2414[1] = float2(7.0);
                                _2414[2] = float2(1.0) + _2496;
                                _2415[0] = ((float2(3.0) - (_2459 * 2.0)) / _2414[0]) - float2(2.0);
                                _2415[1] = (float2(3.0) + _2459) / _2414[1];
                                _2415[2] = (_2459 / _2414[2]) + float2(2.0);
                            }
                            int _5050 = _2466 ? 2 : 3;
                            int _4681;
                            float _4684;
                            _4684 = 0.0;
                            _4681 = 0;
                            float _4690;
                            for (; _4681 < _5050; _4684 = _4690, _4681++)
                            {
                                _4690 = _4684;
                                for (int _4687 = 0; _4687 < _5050; )
                                {
                                    _4690 += ((_2414[_4687].x * _2414[_4681].y) * spvDepthCast(_152).sample_compare(_152Smplr, float3(fast::clamp(_132._m22.xy * (_2462 + float2(_2415[_4687].x, _2415[_4681].y)), _2404.xy, _2404.zw), _2367).xy, _2367));
                                    _4687++;
                                    continue;
                                }
                            }
                            _4691 = _4684 * (_2466 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _4692 = _4691;
                        break;
                    } while(false);
                    _4713 = mix(_4672, _4692, _1973);
                    _4710 = mix(_506[_4659], _506[_1975], float3(_1973));
                }
                else
                {
                    _4713 = mix(_4672, 1.0, _1973);
                    _4710 = _506[_4659];
                }
                _4712 = _4713;
                _4709 = _4710;
            }
            else
            {
                _4712 = _4672;
                _4709 = _506[_4659];
            }
            _4715 = select(float3(1.0), _4709, bool3(_132._m22.w > 0.5));
            _4714 = _4712;
            break;
        } while(false);
        _4789 = _4714;
        _4764 = _4743 * _4715;
    }
    else
    {
        _4789 = 1.0;
        _4764 = _4743;
    }
    float3 _1419 = _132._m5.xyz * _132._m4.w;
    float4 _1428 = _1423.sample(_1225, _1217);
    float _1432 = 1.0 + (_1198._m4.w * (_1428.x - 1.0));
    float3 _4889;
    if (!_1353)
    {
        float _1440 = dot(_4766, _1370);
        float3 _1479 = (_4764 * (((mix(_132._m9.xyz, _132._m8.xyz, float3((_4766.y * 0.5) + 0.5)) * _132._m8.w) * _1432) + ((_1419 * fast::max(_1440, 0.0)) * _4789))) + ((_1419 * ((powr(fast::max(dot(_4766, _1382), 0.0), _1198._m1.w) * _1198._m1.z) * step(0.0, _1440))) * _4789);
        float3 _4890;
        if (_132._m13.w > 0.5)
        {
            float2 _2634 = fast::clamp(floor(gl_FragCoord.xy * _132._m12.xy), float2(0.0), _132._m13.xy - float2(1.0));
            uint _2662 = uint((((fast::clamp(floor((log2(fast::max(dot(_132._m11.xyz, in.m_1022) + _132._m11.w, 9.9999999747524270787835121154785e-07)) * _132._m12.z) + _132._m12.w), 0.0, _132._m13.z - 1.0) * _132._m13.y) + _2634.y) * _132._m13.x) + _2634.x);
            uint _2664 = _2662 >> uint(2);
            uint _2666 = _2662 & 3u;
            uint _2670 = _1155._m0[_2664][_2666] & 65535u;
            uint _2672 = _1155._m0[_2664][_2666] >> uint(16);
            float3 _4891;
            _4891 = _1479;
            float3 _1560;
            spvUnsafeArray<float2, 3> _3080;
            spvUnsafeArray<float2, 3> _3081;
            spvUnsafeArray<float2, 3> _3293;
            spvUnsafeArray<float2, 3> _3294;
            for (uint _4888 = _2670; _4888 < (_2670 + _2672); _4891 = _1560, _4888++)
            {
                uint _2678 = _4888 / 3u;
                uint _2691 = (_1177._m0[_2678 >> uint(2)][_2678 & 3u] >> ((_4888 - (_2678 * 3u)) * 10u)) & 1023u;
                float3 _2708 = _1014._m0[_2691].xyz - in.m_1022;
                float _2711 = dot(_2708, _2708);
                float _2715 = _2711 * _1014._m0[_2691].w;
                float _2720 = fast::clamp(1.0 - (_2715 * _2715), 0.0, 1.0);
                float3 _2725 = _2708 * rsqrt(fast::max(_2711, 9.9999999392252902907785028219223e-09));
                float _2743 = fast::clamp((dot(-_2725, _1058._m0[_2691].xyz) * _1050._m0[_2691].w) + _1058._m0[_2691].w, 0.0, 1.0);
                float3 _2756 = _1050._m0[_2691].xyz * ((((_2720 * _2720) * _2743) * _2743) / fast::max(_2711, 9.9999997473787516355514526367188e-05));
                float3 _4994;
                if (_1393)
                {
                    float _4942;
                    do
                    {
                        uint _2792 = uint(_132._m21.z);
                        if (_2691 < _2792)
                        {
                            float _2814 = _132._m26[_2691].z * fast::max((_132._m15[_2691] * float4(in.m_1022, 1.0)).w, 0.0);
                            float4 _2838 = _132._m15[_2691] * float4((in.m_1022 + (_1388 * (_2814 * _132._m25.x))) + (_2725 * (_2814 * _132._m25.y)), 1.0);
                            float _2840 = _2838.w;
                            if (_2840 <= 0.0)
                            {
                                _4942 = 1.0;
                                break;
                            }
                            float3 _2849 = _2838.xyz / float3(_2840);
                            float _2851 = _2849.x;
                            bool _2852 = _2851 < 0.0;
                            bool _2859;
                            if (!_2852)
                            {
                                _2859 = _2851 > 1.0;
                            }
                            else
                            {
                                _2859 = _2852;
                            }
                            bool _2866;
                            if (!_2859)
                            {
                                _2866 = _2849.y < 0.0;
                            }
                            else
                            {
                                _2866 = _2859;
                            }
                            bool _2873;
                            if (!_2866)
                            {
                                _2873 = _2849.y > 1.0;
                            }
                            else
                            {
                                _2873 = _2866;
                            }
                            bool _2880;
                            if (!_2873)
                            {
                                _2880 = _2849.z > 1.0;
                            }
                            else
                            {
                                _2880 = _2873;
                            }
                            if (_2880)
                            {
                                _4942 = 1.0;
                                break;
                            }
                            float _2886 = _2849.z;
                            float2 _3052 = _132._m22.xy * 0.5;
                            float2 _3057 = _132._m26[_2691].xy + (_2849.xy * _132._m23.zw);
                            float4 _3070 = float4(_132._m26[_2691].xy + _3052, (_132._m26[_2691].xy + _132._m23.zw) - _3052);
                            float _4941;
                            do
                            {
                                int _3096 = int(_132._m22.z);
                                if (_3096 <= 0)
                                {
                                    float2 _3106 = fast::clamp(_3057, _3070.xy, _3070.zw);
                                    _4941 = spvDepthCast(_152).sample_compare(_152Smplr, float3(_3106, _2886).xy, _2886);
                                    break;
                                }
                                float2 _3119 = (_3057 / _132._m22.xy) + float2(0.5);
                                float2 _3120 = floor(_3119);
                                float2 _3125 = _3119 - _3120;
                                float2 _3128 = _3120 - float2(0.5);
                                bool _3132 = _3096 == 1;
                                if (_3132)
                                {
                                    float2 _3135 = _3125 * 2.0;
                                    _3080[0] = float2(3.0) - _3135;
                                    _3080[1] = float2(1.0) + _3135;
                                    _3081[0] = ((float2(2.0) - _3125) / _3080[0]) - float2(1.0);
                                    _3081[1] = (_3125 / _3080[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _3162 = _3125 * 3.0;
                                    _3080[0] = float2(4.0) - _3162;
                                    _3080[1] = float2(7.0);
                                    _3080[2] = float2(1.0) + _3162;
                                    _3081[0] = ((float2(3.0) - (_3125 * 2.0)) / _3080[0]) - float2(2.0);
                                    _3081[1] = (float2(3.0) + _3125) / _3080[1];
                                    _3081[2] = (_3125 / _3080[2]) + float2(2.0);
                                }
                                int _5055 = _3132 ? 2 : 3;
                                int _4931;
                                float _4934;
                                _4934 = 0.0;
                                _4931 = 0;
                                float _4940;
                                for (; _4931 < _5055; _4934 = _4940, _4931++)
                                {
                                    _4940 = _4934;
                                    for (int _4937 = 0; _4937 < _5055; )
                                    {
                                        _4940 += ((_3080[_4937].x * _3080[_4931].y) * spvDepthCast(_152).sample_compare(_152Smplr, float3(fast::clamp(_132._m22.xy * (_3128 + float2(_3081[_4937].x, _3081[_4931].y)), _3070.xy, _3070.zw), _2886).xy, _2886));
                                        _4937++;
                                        continue;
                                    }
                                }
                                _4941 = _4934 * (_3132 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _4942 = _4941;
                            break;
                        }
                        uint _2896 = _2691 - _2792;
                        if (_2896 >= uint(_132._m21.w))
                        {
                            _4942 = 1.0;
                            break;
                        }
                        float _2917 = _132._m27[_2896].w * length(in.m_1022 - _132._m27[_2896].xyz);
                        float3 _2935 = ((in.m_1022 + (_1388 * (_2917 * _132._m25.x))) + (_2725 * (_2917 * _132._m25.y))) - _132._m27[_2896].xyz;
                        float3 _2937 = abs(_2935);
                        float _2939 = _2937.x;
                        float _2941 = _2937.y;
                        bool _2942 = _2939 >= _2941;
                        bool _2950;
                        if (_2942)
                        {
                            _2950 = _2939 >= _2937.z;
                        }
                        else
                        {
                            _2950 = _2942;
                        }
                        float _4916;
                        int _4918;
                        if (_2950)
                        {
                            _4918 = (_2935.x > 0.0) ? 0 : 1;
                            _4916 = _2939;
                        }
                        else
                        {
                            float _2962 = _2937.z;
                            bool _2963 = _2941 >= _2962;
                            int _4919;
                            if (_2963)
                            {
                                _4919 = (_2935.y > 0.0) ? 2 : 3;
                            }
                            else
                            {
                                _4919 = (_2935.z > 0.0) ? 4 : 5;
                            }
                            _4918 = _4919;
                            _4916 = _2963 ? _2941 : _2962;
                        }
                        if (_4916 <= 0.0)
                        {
                            _4942 = 1.0;
                            break;
                        }
                        float2 _3000 = float2(dot(_2935, _810[_4918]), dot(_2935, _819[_4918])) / float2(_4916 * _132._m24.z);
                        float _3007 = _132._m28[_2896].z + (_132._m28[_2896].w / _4916);
                        if (_3007 > 1.0)
                        {
                            _4942 = 1.0;
                            break;
                        }
                        float2 _3025 = _132._m28[_2896].xy + (float2(float(spvSMod(_4918, 3)), float(_4918 / 3)) * _132._m24.xy);
                        float2 _3265 = _132._m22.xy * 0.5;
                        float2 _3270 = _3025 + (float2(0.5 + (0.5 * _3000.x), 0.5 - (0.5 * _3000.y)) * _132._m24.xy);
                        float4 _3283 = float4(_3025 + _3265, (_3025 + _132._m24.xy) - _3265);
                        float _4930;
                        do
                        {
                            int _3309 = int(_132._m22.z);
                            if (_3309 <= 0)
                            {
                                _4930 = spvDepthCast(_152).sample_compare(_152Smplr, float3(fast::clamp(_3270, _3283.xy, _3283.zw), _3007).xy, _3007);
                                break;
                            }
                            float2 _3332 = (_3270 / _132._m22.xy) + float2(0.5);
                            float2 _3333 = floor(_3332);
                            float2 _3338 = _3332 - _3333;
                            float2 _3341 = _3333 - float2(0.5);
                            bool _3345 = _3309 == 1;
                            if (_3345)
                            {
                                float2 _3348 = _3338 * 2.0;
                                _3293[0] = float2(3.0) - _3348;
                                _3293[1] = float2(1.0) + _3348;
                                _3294[0] = ((float2(2.0) - _3338) / _3293[0]) - float2(1.0);
                                _3294[1] = (_3338 / _3293[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _3375 = _3338 * 3.0;
                                _3293[0] = float2(4.0) - _3375;
                                _3293[1] = float2(7.0);
                                _3293[2] = float2(1.0) + _3375;
                                _3294[0] = ((float2(3.0) - (_3338 * 2.0)) / _3293[0]) - float2(2.0);
                                _3294[1] = (float2(3.0) + _3338) / _3293[1];
                                _3294[2] = (_3338 / _3293[2]) + float2(2.0);
                            }
                            int _5058 = _3345 ? 2 : 3;
                            int _4920;
                            float _4923;
                            _4923 = 0.0;
                            _4920 = 0;
                            float _4929;
                            for (; _4920 < _5058; _4923 = _4929, _4920++)
                            {
                                _4929 = _4923;
                                for (int _4926 = 0; _4926 < _5058; )
                                {
                                    _4929 += ((_3293[_4926].x * _3293[_4920].y) * spvDepthCast(_152).sample_compare(_152Smplr, float3(fast::clamp(_132._m22.xy * (_3341 + float2(_3294[_4926].x, _3294[_4920].y)), _3283.xy, _3283.zw), _3007).xy, _3007));
                                    _4926++;
                                    continue;
                                }
                            }
                            _4930 = _4923 * (_3345 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _4942 = _4930;
                        break;
                    } while(false);
                    _4994 = _2756 * _4942;
                }
                else
                {
                    _4994 = _2756;
                }
                float _1531 = dot(_4766, _2725);
                _1560 = _4891 + (((_4764 * fast::max(_1531, 0.0)) * _4994) + (_4994 * ((powr(fast::max(dot(_4766, fast::normalize(_2725 + _1377)), 0.0), _1198._m1.w) * _1198._m1.z) * step(0.0, _1531))));
            }
            _4890 = _4891;
        }
        else
        {
            _4890 = _1479;
        }
        _4889 = _4890;
    }
    else
    {
        float4 _1570 = _1565.sample(_1225, _1217);
        float _1577 = fast::clamp(_1198._m4.x * _1570.z, 0.0, 1.0);
        float _1585 = fast::clamp(_1198._m4.y * _1570.y, 0.04500000178813934326171875, 1.0);
        float _1589 = _1585 * _1585;
        float3 _1594 = _4764 * (1.0 - _1577);
        float3 _1601 = mix(float3(0.039999999105930328369140625), _4764, float3(_1577));
        float _1606 = fast::max(dot(_4766, _1377), 9.9999997473787516355514526367188e-05);
        float _1611 = fast::clamp(dot(_4766, _1370), 0.0, 1.0);
        float _1616 = fast::clamp(dot(_4766, _1382), 0.0, 1.0);
        float3 _3477 = float3(1.0) - _1601;
        float3 _3480 = _1601 + (_3477 * powr(1.0 - fast::clamp(dot(_1377, _1382), 0.0, 1.0), 5.0));
        float _3487 = _1589 * _1589;
        float _3492 = _3487 - 1.0;
        float _3494 = ((_1616 * _1616) * _3492) + 1.0;
        float _3514 = 1.0 - _3487;
        float _3518 = sqrt(((_1606 * _1606) * _3514) + _3487);
        float4 _3542 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * _1585) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);
        float _3544 = _3542.x;
        float2 _3562 = (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_3544 * _3544, exp2((-9.27999973297119140625) * _1606)) * _3544) + _3542.y)) + _3542.zw;
        float3 _1672 = (_1601 * _3562.x) + float3(_3562.y);
        float3 _3579 = mix(_132._m9.xyz, _132._m8.xyz, float3((_4766.y * 0.5) + 0.5)) * _132._m8.w;
        float3 _1703 = ((((((float3(1.0) - _3480) * _1594) + ((_3480 * ((_3487 / ((3.1415927410125732421875 * _3494) * _3494)) * (0.5 / fast::max((_1611 * _3518) + (_1606 * sqrt(((_1611 * _1611) * _3514) + _3487)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875)) * _1611) * _1419) * _4789) + (((((float3(1.0) - _1672) * _1594) * _3579) + (_1672 * mix(mix(_132._m9.xyz, _132._m8.xyz, float3((reflect(-_1377, _4766).y * 0.5) + 0.5)) * _132._m8.w, _3579, float3(_1585)))) * _1432);
        float3 _4892;
        if (_132._m13.w > 0.5)
        {
            float2 _3624 = fast::clamp(floor(gl_FragCoord.xy * _132._m12.xy), float2(0.0), _132._m13.xy - float2(1.0));
            uint _3652 = uint((((fast::clamp(floor((log2(fast::max(dot(_132._m11.xyz, in.m_1022) + _132._m11.w, 9.9999999747524270787835121154785e-07)) * _132._m12.z) + _132._m12.w), 0.0, _132._m13.z - 1.0) * _132._m13.y) + _3624.y) * _132._m13.x) + _3624.x);
            uint _3654 = _3652 >> uint(2);
            uint _3656 = _3652 & 3u;
            uint _3660 = _1155._m0[_3654][_3656] & 65535u;
            uint _3662 = _1155._m0[_3654][_3656] >> uint(16);
            float3 _4854;
            _4854 = _1703;
            float3 _1803;
            spvUnsafeArray<float2, 3> _4070;
            spvUnsafeArray<float2, 3> _4071;
            spvUnsafeArray<float2, 3> _4283;
            spvUnsafeArray<float2, 3> _4284;
            for (uint _4790 = _3660; _4790 < (_3660 + _3662); _4854 = _1803, _4790++)
            {
                uint _3668 = _4790 / 3u;
                uint _3681 = (_1177._m0[_3668 >> uint(2)][_3668 & 3u] >> ((_4790 - (_3668 * 3u)) * 10u)) & 1023u;
                float3 _3698 = _1014._m0[_3681].xyz - in.m_1022;
                float _3701 = dot(_3698, _3698);
                float _3705 = _3701 * _1014._m0[_3681].w;
                float _3710 = fast::clamp(1.0 - (_3705 * _3705), 0.0, 1.0);
                float3 _3715 = _3698 * rsqrt(fast::max(_3701, 9.9999999392252902907785028219223e-09));
                float _3733 = fast::clamp((dot(-_3715, _1058._m0[_3681].xyz) * _1050._m0[_3681].w) + _1058._m0[_3681].w, 0.0, 1.0);
                float3 _3746 = _1050._m0[_3681].xyz * ((((_3710 * _3710) * _3733) * _3733) / fast::max(_3701, 9.9999997473787516355514526367188e-05));
                float3 _4852;
                if (_1393)
                {
                    float _4817;
                    do
                    {
                        uint _3782 = uint(_132._m21.z);
                        if (_3681 < _3782)
                        {
                            float _3804 = _132._m26[_3681].z * fast::max((_132._m15[_3681] * float4(in.m_1022, 1.0)).w, 0.0);
                            float4 _3828 = _132._m15[_3681] * float4((in.m_1022 + (_1388 * (_3804 * _132._m25.x))) + (_3715 * (_3804 * _132._m25.y)), 1.0);
                            float _3830 = _3828.w;
                            if (_3830 <= 0.0)
                            {
                                _4817 = 1.0;
                                break;
                            }
                            float3 _3839 = _3828.xyz / float3(_3830);
                            float _3841 = _3839.x;
                            bool _3842 = _3841 < 0.0;
                            bool _3849;
                            if (!_3842)
                            {
                                _3849 = _3841 > 1.0;
                            }
                            else
                            {
                                _3849 = _3842;
                            }
                            bool _3856;
                            if (!_3849)
                            {
                                _3856 = _3839.y < 0.0;
                            }
                            else
                            {
                                _3856 = _3849;
                            }
                            bool _3863;
                            if (!_3856)
                            {
                                _3863 = _3839.y > 1.0;
                            }
                            else
                            {
                                _3863 = _3856;
                            }
                            bool _3870;
                            if (!_3863)
                            {
                                _3870 = _3839.z > 1.0;
                            }
                            else
                            {
                                _3870 = _3863;
                            }
                            if (_3870)
                            {
                                _4817 = 1.0;
                                break;
                            }
                            float _3876 = _3839.z;
                            float2 _4042 = _132._m22.xy * 0.5;
                            float2 _4047 = _132._m26[_3681].xy + (_3839.xy * _132._m23.zw);
                            float4 _4060 = float4(_132._m26[_3681].xy + _4042, (_132._m26[_3681].xy + _132._m23.zw) - _4042);
                            float _4816;
                            do
                            {
                                int _4086 = int(_132._m22.z);
                                if (_4086 <= 0)
                                {
                                    float2 _4096 = fast::clamp(_4047, _4060.xy, _4060.zw);
                                    _4816 = spvDepthCast(_152).sample_compare(_152Smplr, float3(_4096, _3876).xy, _3876);
                                    break;
                                }
                                float2 _4109 = (_4047 / _132._m22.xy) + float2(0.5);
                                float2 _4110 = floor(_4109);
                                float2 _4115 = _4109 - _4110;
                                float2 _4118 = _4110 - float2(0.5);
                                bool _4122 = _4086 == 1;
                                if (_4122)
                                {
                                    float2 _4125 = _4115 * 2.0;
                                    _4070[0] = float2(3.0) - _4125;
                                    _4070[1] = float2(1.0) + _4125;
                                    _4071[0] = ((float2(2.0) - _4115) / _4070[0]) - float2(1.0);
                                    _4071[1] = (_4115 / _4070[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _4152 = _4115 * 3.0;
                                    _4070[0] = float2(4.0) - _4152;
                                    _4070[1] = float2(7.0);
                                    _4070[2] = float2(1.0) + _4152;
                                    _4071[0] = ((float2(3.0) - (_4115 * 2.0)) / _4070[0]) - float2(2.0);
                                    _4071[1] = (float2(3.0) + _4115) / _4070[1];
                                    _4071[2] = (_4115 / _4070[2]) + float2(2.0);
                                }
                                int _5060 = _4122 ? 2 : 3;
                                int _4806;
                                float _4809;
                                _4809 = 0.0;
                                _4806 = 0;
                                float _4815;
                                for (; _4806 < _5060; _4809 = _4815, _4806++)
                                {
                                    _4815 = _4809;
                                    for (int _4812 = 0; _4812 < _5060; )
                                    {
                                        _4815 += ((_4070[_4812].x * _4070[_4806].y) * spvDepthCast(_152).sample_compare(_152Smplr, float3(fast::clamp(_132._m22.xy * (_4118 + float2(_4071[_4812].x, _4071[_4806].y)), _4060.xy, _4060.zw), _3876).xy, _3876));
                                        _4812++;
                                        continue;
                                    }
                                }
                                _4816 = _4809 * (_4122 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _4817 = _4816;
                            break;
                        }
                        uint _3886 = _3681 - _3782;
                        if (_3886 >= uint(_132._m21.w))
                        {
                            _4817 = 1.0;
                            break;
                        }
                        float _3907 = _132._m27[_3886].w * length(in.m_1022 - _132._m27[_3886].xyz);
                        float3 _3925 = ((in.m_1022 + (_1388 * (_3907 * _132._m25.x))) + (_3715 * (_3907 * _132._m25.y))) - _132._m27[_3886].xyz;
                        float3 _3927 = abs(_3925);
                        float _3929 = _3927.x;
                        float _3931 = _3927.y;
                        bool _3932 = _3929 >= _3931;
                        bool _3940;
                        if (_3932)
                        {
                            _3940 = _3929 >= _3927.z;
                        }
                        else
                        {
                            _3940 = _3932;
                        }
                        float _4791;
                        int _4793;
                        if (_3940)
                        {
                            _4793 = (_3925.x > 0.0) ? 0 : 1;
                            _4791 = _3929;
                        }
                        else
                        {
                            float _3952 = _3927.z;
                            bool _3953 = _3931 >= _3952;
                            int _4794;
                            if (_3953)
                            {
                                _4794 = (_3925.y > 0.0) ? 2 : 3;
                            }
                            else
                            {
                                _4794 = (_3925.z > 0.0) ? 4 : 5;
                            }
                            _4793 = _4794;
                            _4791 = _3953 ? _3931 : _3952;
                        }
                        if (_4791 <= 0.0)
                        {
                            _4817 = 1.0;
                            break;
                        }
                        float2 _3990 = float2(dot(_3925, _810[_4793]), dot(_3925, _819[_4793])) / float2(_4791 * _132._m24.z);
                        float _3997 = _132._m28[_3886].z + (_132._m28[_3886].w / _4791);
                        if (_3997 > 1.0)
                        {
                            _4817 = 1.0;
                            break;
                        }
                        float2 _4015 = _132._m28[_3886].xy + (float2(float(spvSMod(_4793, 3)), float(_4793 / 3)) * _132._m24.xy);
                        float2 _4255 = _132._m22.xy * 0.5;
                        float2 _4260 = _4015 + (float2(0.5 + (0.5 * _3990.x), 0.5 - (0.5 * _3990.y)) * _132._m24.xy);
                        float4 _4273 = float4(_4015 + _4255, (_4015 + _132._m24.xy) - _4255);
                        float _4805;
                        do
                        {
                            int _4299 = int(_132._m22.z);
                            if (_4299 <= 0)
                            {
                                _4805 = spvDepthCast(_152).sample_compare(_152Smplr, float3(fast::clamp(_4260, _4273.xy, _4273.zw), _3997).xy, _3997);
                                break;
                            }
                            float2 _4322 = (_4260 / _132._m22.xy) + float2(0.5);
                            float2 _4323 = floor(_4322);
                            float2 _4328 = _4322 - _4323;
                            float2 _4331 = _4323 - float2(0.5);
                            bool _4335 = _4299 == 1;
                            if (_4335)
                            {
                                float2 _4338 = _4328 * 2.0;
                                _4283[0] = float2(3.0) - _4338;
                                _4283[1] = float2(1.0) + _4338;
                                _4284[0] = ((float2(2.0) - _4328) / _4283[0]) - float2(1.0);
                                _4284[1] = (_4328 / _4283[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _4365 = _4328 * 3.0;
                                _4283[0] = float2(4.0) - _4365;
                                _4283[1] = float2(7.0);
                                _4283[2] = float2(1.0) + _4365;
                                _4284[0] = ((float2(3.0) - (_4328 * 2.0)) / _4283[0]) - float2(2.0);
                                _4284[1] = (float2(3.0) + _4328) / _4283[1];
                                _4284[2] = (_4328 / _4283[2]) + float2(2.0);
                            }
                            int _5063 = _4335 ? 2 : 3;
                            int _4795;
                            float _4798;
                            _4798 = 0.0;
                            _4795 = 0;
                            float _4804;
                            for (; _4795 < _5063; _4798 = _4804, _4795++)
                            {
                                _4804 = _4798;
                                for (int _4801 = 0; _4801 < _5063; )
                                {
                                    _4804 += ((_4283[_4801].x * _4283[_4795].y) * spvDepthCast(_152).sample_compare(_152Smplr, float3(fast::clamp(_132._m22.xy * (_4331 + float2(_4284[_4801].x, _4284[_4795].y)), _4273.xy, _4273.zw), _3997).xy, _3997));
                                    _4801++;
                                    continue;
                                }
                            }
                            _4805 = _4798 * (_4335 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _4817 = _4805;
                        break;
                    } while(false);
                    _4852 = _3746 * _4817;
                }
                else
                {
                    _4852 = _3746;
                }
                float3 _1755 = fast::normalize(_3715 + _1377);
                float _1760 = fast::clamp(dot(_4766, _3715), 0.0, 1.0);
                float _1765 = fast::clamp(dot(_4766, _1755), 0.0, 1.0);
                float3 _4470 = _1601 + (_3477 * powr(1.0 - fast::clamp(dot(_1377, _1755), 0.0, 1.0), 5.0));
                float _4484 = ((_1765 * _1765) * _3492) + 1.0;
                _1803 = _4854 + (((((float3(1.0) - _4470) * _1594) + ((_4470 * ((_3487 / ((3.1415927410125732421875 * _4484) * _4484)) * (0.5 / fast::max((_1760 * _3518) + (_1606 * sqrt(((_1760 * _1760) * _3514) + _3487)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875)) * _1760) * _4852);
            }
            _4892 = _4854;
        }
        else
        {
            _4892 = _1703;
        }
        _4889 = _4892;
    }
    out.m_1842 = float4(mix(mix(_4889, _4764, float3(_1198._m1.y)) + (_1198._m5.xyz * _1815.sample(_1225, _1217).xyz), _132._m7.xyz, float3(1.0 - exp((-length(_1376)) * _132._m7.w))), (in.m_1232.w * _1198._m0.w) * _1230.w);
    float2 _4915;
    do
    {
        if (in.m_1858.w <= 0.0)
        {
            _4915 = float2(0.0);
            break;
        }
        _4915 = ((in.m_1858.xy / float2(in.m_1858.w)) - (in.m_1857.xy / float2(in.m_1857.w))) * float2(0.5, -0.5);
        break;
    } while(false);
    _1856 = _4915;
    return out;
}

