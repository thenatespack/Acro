// Generated from mesh_mask.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 24b737b1431abdb0
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
    float4 m_1855 [[color(0)]];
    float2 m_1869 [[color(1)]];
};

struct fragment_main_in
{
    float3 m_1022 [[user(locn0)]];
    float3 m_1290 [[user(locn1)]];
    float2 m_1203 [[user(locn2)]];
    float4 m_1232 [[user(locn3)]];
    float4 m_1403 [[user(locn5)]];
    float4 m_1870 [[user(locn6)]];
    float4 m_1871 [[user(locn7)]];
    float4 m_1299 [[user(locn8)]];
};

fragment fragment_main_out fragment_main(fragment_main_in in [[stage_in]], constant _1196& _1198 [[buffer(2)]], constant _1012& _1014 [[buffer(3)]], constant _1048& _1050 [[buffer(4)]], constant _1056& _1058 [[buffer(5)]], constant _1153& _1155 [[buffer(6)]], constant _1175& _1177 [[buffer(7)]], constant _130& _132 [[buffer(15)]], texture2d<float> _152 [[texture(0)]], texture2d<float> _1221 [[texture(1)]], texture2d<float> _1578 [[texture(2)]], texture2d<float> _1328 [[texture(3)]], texture2d<float> _1436 [[texture(4)]], texture2d<float> _1828 [[texture(5)]], sampler _152Smplr [[sampler(0)]], sampler _1225 [[sampler(1)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])
{
    fragment_main_out out = {};
    float2 _1217 = float2(dot(_1198._m2.xy, in.m_1203) + _1198._m2.z, dot(_1198._m3.xy, in.m_1203) + _1198._m3.z);
    float4 _1230 = _1221.sample(_1225, _1217);
    float3 _1241 = (in.m_1232.xyz * _1198._m0.xyz) * _1230.xyz;
    if ((_1198._m0.w * _1230.w) < _1198._m6.x)
    {
        discard_fragment();
    }
    float3 _4757;
    if (_1198._m1.x > 0.5)
    {
        float2 _1276 = floor(in.m_1022.xz * float2(0.5));
        _4757 = _1241 * ((mod(abs(_1276.x + _1276.y), 2.0) < 0.5) ? 1.0 : 0.75);
    }
    else
    {
        _4757 = _1241;
    }
    float3 _1292 = fast::normalize(in.m_1290);
    float3 _4671;
    if (_1198._m6.y > 0.5)
    {
        float3 _1308 = in.m_1299.xyz - (_1292 * dot(_1292, in.m_1299.xyz));
        float3 _4672;
        if (dot(_1308, _1308) > 9.9999999600419720025001879548654e-13)
        {
            float3 _1317 = fast::normalize(_1308);
            float3 _1337 = (_1328.sample(_1225, _1217).xyz * 2.0) - float3(1.0);
            float2 _1342 = _1337.xy * _1198._m4.z;
            _4672 = fast::normalize(((_1317 * _1342.x) + ((cross(_1292, _1317) * ((in.m_1299.w < 0.0) ? (-1.0) : 1.0)) * _1342.y)) + (_1292 * _1337.z));
        }
        else
        {
            _4672 = _1292;
        }
        _4671 = _4672;
    }
    else
    {
        _4671 = _1292;
    }
    bool _1366 = _1198._m5.w > 0.5;
    bool _1374;
    if (_1366)
    {
        _1374 = !gl_FrontFacing;
    }
    else
    {
        _1374 = _1366;
    }
    float3 _4780;
    if (_1374)
    {
        _4780 = -_4671;
    }
    else
    {
        _4780 = _4671;
    }
    float3 _1383 = fast::normalize(_132._m4.xyz);
    float3 _1389 = _132._m6.xyz - in.m_1022;
    float3 _1390 = fast::normalize(_1389);
    float3 _1395 = fast::normalize(_1383 + _1390);
    float3 _1401 = _1292 * (gl_FrontFacing ? 1.0 : (-1.0));
    bool _1406 = in.m_1403.x > 0.5;
    float3 _4778;
    float _4803;
    if ((_132._m5.w > 0.5) && _1406)
    {
        float _4728;
        float3 _4729;
        do
        {
            int _1924 = int(_132._m21.x);
            float _1932 = dot(_132._m20.xyz, in.m_1022) + _132._m20.w;
            int _4673;
            _4673 = 0;
            for (;;)
            {
                bool _1938 = _4673 < (_1924 - 1);
                bool _1946;
                if (_1938)
                {
                    _1946 = _1932 > _132._m16[_4673];
                }
                else
                {
                    _1946 = _1938;
                }
                if (_1946)
                {
                    _4673++;
                    continue;
                }
                else
                {
                    break;
                }
            }
            if (_1932 > _132._m16[_4673])
            {
                _4729 = float3(1.0);
                _4728 = 1.0;
                break;
            }
            float _4686;
            do
            {
                float4 _2048 = _132._m14[_4673] * float4(in.m_1022 + (_1401 * _132._m18[_4673]), 1.0);
                float _2051 = _2048.x;
                bool _2052 = _2051 < 0.0;
                bool _2059;
                if (!_2052)
                {
                    _2059 = _2051 > 1.0;
                }
                else
                {
                    _2059 = _2052;
                }
                bool _2066;
                if (!_2059)
                {
                    _2066 = _2048.y < 0.0;
                }
                else
                {
                    _2066 = _2059;
                }
                bool _2073;
                if (!_2066)
                {
                    _2073 = _2048.y > 1.0;
                }
                else
                {
                    _2073 = _2066;
                }
                if (_2073)
                {
                    _4686 = 1.0;
                    break;
                }
                float2 _2086 = float2(float(_4673 & 1), float(_4673 >> 1)) * _132._m23.xy;
                float _2093 = fast::min(_2048.z, 1.0) - _132._m19[_4673];
                float2 _2112 = _132._m22.xy * 0.5;
                float2 _2117 = _2086 + (_2048.xy * _132._m23.xy);
                float4 _2130 = float4(_2086 + _2112, (_2086 + _132._m23.xy) - _2112);
                float _4685;
                do
                {
                    int _2156 = int(_132._m22.z);
                    if (_2156 <= 0)
                    {
                        _4685 = spvDepthCast(_152).sample_compare(_152Smplr, float3(fast::clamp(_2117, _2130.xy, _2130.zw), _2093).xy, _2093);
                        break;
                    }
                    float2 _2179 = (_2117 / _132._m22.xy) + float2(0.5);
                    float2 _2180 = floor(_2179);
                    float2 _2185 = _2179 - _2180;
                    float2 _2188 = _2180 - float2(0.5);
                    bool _2192 = _2156 == 1;
                    spvUnsafeArray<float2, 3> _2140;
                    spvUnsafeArray<float2, 3> _2141;
                    if (_2192)
                    {
                        float2 _2195 = _2185 * 2.0;
                        _2140[0] = float2(3.0) - _2195;
                        _2140[1] = float2(1.0) + _2195;
                        _2141[0] = ((float2(2.0) - _2185) / _2140[0]) - float2(1.0);
                        _2141[1] = (_2185 / _2140[1]) + float2(1.0);
                    }
                    else
                    {
                        float2 _2222 = _2185 * 3.0;
                        _2140[0] = float2(4.0) - _2222;
                        _2140[1] = float2(7.0);
                        _2140[2] = float2(1.0) + _2222;
                        _2141[0] = ((float2(3.0) - (_2185 * 2.0)) / _2140[0]) - float2(2.0);
                        _2141[1] = (float2(3.0) + _2185) / _2140[1];
                        _2141[2] = (_2185 / _2140[2]) + float2(2.0);
                    }
                    int _5129 = _2192 ? 2 : 3;
                    int _4675;
                    float _4678;
                    _4678 = 0.0;
                    _4675 = 0;
                    float _4684;
                    for (; _4675 < _5129; _4678 = _4684, _4675++)
                    {
                        _4684 = _4678;
                        for (int _4681 = 0; _4681 < _5129; )
                        {
                            _4684 += ((_2140[_4681].x * _2140[_4675].y) * spvDepthCast(_152).sample_compare(_152Smplr, float3(fast::clamp(_132._m22.xy * (_2188 + float2(_2141[_4681].x, _2141[_4675].y)), _2130.xy, _2130.zw), _2093).xy, _2093));
                            _4681++;
                            continue;
                        }
                    }
                    _4685 = _4678 * (_2192 ? 0.0625 : 0.0069444444961845874786376953125);
                    break;
                } while(false);
                _4686 = _4685;
                break;
            } while(false);
            float3 _4723;
            float _4726;
            if (_1932 > _132._m17[_4673])
            {
                float _1986 = (_1932 - _132._m17[_4673]) / (_132._m16[_4673] - _132._m17[_4673]);
                int _1988 = _4673 + 1;
                float3 _4724;
                float _4727;
                if (_1988 < _1924)
                {
                    float _4706;
                    do
                    {
                        float4 _2335 = _132._m14[_1988] * float4(in.m_1022 + (_1401 * _132._m18[_1988]), 1.0);
                        float _2338 = _2335.x;
                        bool _2339 = _2338 < 0.0;
                        bool _2346;
                        if (!_2339)
                        {
                            _2346 = _2338 > 1.0;
                        }
                        else
                        {
                            _2346 = _2339;
                        }
                        bool _2353;
                        if (!_2346)
                        {
                            _2353 = _2335.y < 0.0;
                        }
                        else
                        {
                            _2353 = _2346;
                        }
                        bool _2360;
                        if (!_2353)
                        {
                            _2360 = _2335.y > 1.0;
                        }
                        else
                        {
                            _2360 = _2353;
                        }
                        if (_2360)
                        {
                            _4706 = 1.0;
                            break;
                        }
                        float2 _2373 = float2(float(_1988 & 1), float(_1988 >> 1)) * _132._m23.xy;
                        float _2380 = fast::min(_2335.z, 1.0) - _132._m19[_1988];
                        float2 _2399 = _132._m22.xy * 0.5;
                        float2 _2404 = _2373 + (_2335.xy * _132._m23.xy);
                        float4 _2417 = float4(_2373 + _2399, (_2373 + _132._m23.xy) - _2399);
                        float _4705;
                        do
                        {
                            int _2443 = int(_132._m22.z);
                            if (_2443 <= 0)
                            {
                                _4705 = spvDepthCast(_152).sample_compare(_152Smplr, float3(fast::clamp(_2404, _2417.xy, _2417.zw), _2380).xy, _2380);
                                break;
                            }
                            float2 _2466 = (_2404 / _132._m22.xy) + float2(0.5);
                            float2 _2467 = floor(_2466);
                            float2 _2472 = _2466 - _2467;
                            float2 _2475 = _2467 - float2(0.5);
                            bool _2479 = _2443 == 1;
                            spvUnsafeArray<float2, 3> _2427;
                            spvUnsafeArray<float2, 3> _2428;
                            if (_2479)
                            {
                                float2 _2482 = _2472 * 2.0;
                                _2427[0] = float2(3.0) - _2482;
                                _2427[1] = float2(1.0) + _2482;
                                _2428[0] = ((float2(2.0) - _2472) / _2427[0]) - float2(1.0);
                                _2428[1] = (_2472 / _2427[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _2509 = _2472 * 3.0;
                                _2427[0] = float2(4.0) - _2509;
                                _2427[1] = float2(7.0);
                                _2427[2] = float2(1.0) + _2509;
                                _2428[0] = ((float2(3.0) - (_2472 * 2.0)) / _2427[0]) - float2(2.0);
                                _2428[1] = (float2(3.0) + _2472) / _2427[1];
                                _2428[2] = (_2472 / _2427[2]) + float2(2.0);
                            }
                            int _5131 = _2479 ? 2 : 3;
                            int _4695;
                            float _4698;
                            _4698 = 0.0;
                            _4695 = 0;
                            float _4704;
                            for (; _4695 < _5131; _4698 = _4704, _4695++)
                            {
                                _4704 = _4698;
                                for (int _4701 = 0; _4701 < _5131; )
                                {
                                    _4704 += ((_2427[_4701].x * _2427[_4695].y) * spvDepthCast(_152).sample_compare(_152Smplr, float3(fast::clamp(_132._m22.xy * (_2475 + float2(_2428[_4701].x, _2428[_4695].y)), _2417.xy, _2417.zw), _2380).xy, _2380));
                                    _4701++;
                                    continue;
                                }
                            }
                            _4705 = _4698 * (_2479 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _4706 = _4705;
                        break;
                    } while(false);
                    _4727 = mix(_4686, _4706, _1986);
                    _4724 = mix(_506[_4673], _506[_1988], float3(_1986));
                }
                else
                {
                    _4727 = mix(_4686, 1.0, _1986);
                    _4724 = _506[_4673];
                }
                _4726 = _4727;
                _4723 = _4724;
            }
            else
            {
                _4726 = _4686;
                _4723 = _506[_4673];
            }
            _4729 = select(float3(1.0), _4723, bool3(_132._m22.w > 0.5));
            _4728 = _4726;
            break;
        } while(false);
        _4803 = _4728;
        _4778 = _4757 * _4729;
    }
    else
    {
        _4803 = 1.0;
        _4778 = _4757;
    }
    float3 _1432 = _132._m5.xyz * _132._m4.w;
    float4 _1441 = _1436.sample(_1225, _1217);
    float _1445 = 1.0 + (_1198._m4.w * (_1441.x - 1.0));
    float3 _4903;
    if (!_1366)
    {
        float _1453 = dot(_4780, _1383);
        float3 _1492 = (_4778 * (((mix(_132._m9.xyz, _132._m8.xyz, float3((_4780.y * 0.5) + 0.5)) * _132._m8.w) * _1445) + ((_1432 * fast::max(_1453, 0.0)) * _4803))) + ((_1432 * ((powr(fast::max(dot(_4780, _1395), 0.0), _1198._m1.w) * _1198._m1.z) * step(0.0, _1453))) * _4803);
        float3 _4904;
        if (_132._m13.w > 0.5)
        {
            float2 _2647 = fast::clamp(floor(gl_FragCoord.xy * _132._m12.xy), float2(0.0), _132._m13.xy - float2(1.0));
            uint _2675 = uint((((fast::clamp(floor((log2(fast::max(dot(_132._m11.xyz, in.m_1022) + _132._m11.w, 9.9999999747524270787835121154785e-07)) * _132._m12.z) + _132._m12.w), 0.0, _132._m13.z - 1.0) * _132._m13.y) + _2647.y) * _132._m13.x) + _2647.x);
            uint _2677 = _2675 >> uint(2);
            uint _2679 = _2675 & 3u;
            uint _2683 = _1155._m0[_2677][_2679] & 65535u;
            uint _2685 = _1155._m0[_2677][_2679] >> uint(16);
            float3 _4905;
            _4905 = _1492;
            float3 _1573;
            spvUnsafeArray<float2, 3> _3093;
            spvUnsafeArray<float2, 3> _3094;
            spvUnsafeArray<float2, 3> _3306;
            spvUnsafeArray<float2, 3> _3307;
            for (uint _4902 = _2683; _4902 < (_2683 + _2685); _4905 = _1573, _4902++)
            {
                uint _2691 = _4902 / 3u;
                uint _2704 = (_1177._m0[_2691 >> uint(2)][_2691 & 3u] >> ((_4902 - (_2691 * 3u)) * 10u)) & 1023u;
                float3 _2721 = _1014._m0[_2704].xyz - in.m_1022;
                float _2724 = dot(_2721, _2721);
                float _2728 = _2724 * _1014._m0[_2704].w;
                float _2733 = fast::clamp(1.0 - (_2728 * _2728), 0.0, 1.0);
                float3 _2738 = _2721 * rsqrt(fast::max(_2724, 9.9999999392252902907785028219223e-09));
                float _2756 = fast::clamp((dot(-_2738, _1058._m0[_2704].xyz) * _1050._m0[_2704].w) + _1058._m0[_2704].w, 0.0, 1.0);
                float3 _2769 = _1050._m0[_2704].xyz * ((((_2733 * _2733) * _2756) * _2756) / fast::max(_2724, 9.9999997473787516355514526367188e-05));
                float3 _5058;
                if (_1406)
                {
                    float _5006;
                    do
                    {
                        uint _2805 = uint(_132._m21.z);
                        if (_2704 < _2805)
                        {
                            float _2827 = _132._m26[_2704].z * fast::max((_132._m15[_2704] * float4(in.m_1022, 1.0)).w, 0.0);
                            float4 _2851 = _132._m15[_2704] * float4((in.m_1022 + (_1401 * (_2827 * _132._m25.x))) + (_2738 * (_2827 * _132._m25.y)), 1.0);
                            float _2853 = _2851.w;
                            if (_2853 <= 0.0)
                            {
                                _5006 = 1.0;
                                break;
                            }
                            float3 _2862 = _2851.xyz / float3(_2853);
                            float _2864 = _2862.x;
                            bool _2865 = _2864 < 0.0;
                            bool _2872;
                            if (!_2865)
                            {
                                _2872 = _2864 > 1.0;
                            }
                            else
                            {
                                _2872 = _2865;
                            }
                            bool _2879;
                            if (!_2872)
                            {
                                _2879 = _2862.y < 0.0;
                            }
                            else
                            {
                                _2879 = _2872;
                            }
                            bool _2886;
                            if (!_2879)
                            {
                                _2886 = _2862.y > 1.0;
                            }
                            else
                            {
                                _2886 = _2879;
                            }
                            bool _2893;
                            if (!_2886)
                            {
                                _2893 = _2862.z > 1.0;
                            }
                            else
                            {
                                _2893 = _2886;
                            }
                            if (_2893)
                            {
                                _5006 = 1.0;
                                break;
                            }
                            float _2899 = _2862.z;
                            float2 _3065 = _132._m22.xy * 0.5;
                            float2 _3070 = _132._m26[_2704].xy + (_2862.xy * _132._m23.zw);
                            float4 _3083 = float4(_132._m26[_2704].xy + _3065, (_132._m26[_2704].xy + _132._m23.zw) - _3065);
                            float _5005;
                            do
                            {
                                int _3109 = int(_132._m22.z);
                                if (_3109 <= 0)
                                {
                                    float2 _3119 = fast::clamp(_3070, _3083.xy, _3083.zw);
                                    _5005 = spvDepthCast(_152).sample_compare(_152Smplr, float3(_3119, _2899).xy, _2899);
                                    break;
                                }
                                float2 _3132 = (_3070 / _132._m22.xy) + float2(0.5);
                                float2 _3133 = floor(_3132);
                                float2 _3138 = _3132 - _3133;
                                float2 _3141 = _3133 - float2(0.5);
                                bool _3145 = _3109 == 1;
                                if (_3145)
                                {
                                    float2 _3148 = _3138 * 2.0;
                                    _3093[0] = float2(3.0) - _3148;
                                    _3093[1] = float2(1.0) + _3148;
                                    _3094[0] = ((float2(2.0) - _3138) / _3093[0]) - float2(1.0);
                                    _3094[1] = (_3138 / _3093[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _3175 = _3138 * 3.0;
                                    _3093[0] = float2(4.0) - _3175;
                                    _3093[1] = float2(7.0);
                                    _3093[2] = float2(1.0) + _3175;
                                    _3094[0] = ((float2(3.0) - (_3138 * 2.0)) / _3093[0]) - float2(2.0);
                                    _3094[1] = (float2(3.0) + _3138) / _3093[1];
                                    _3094[2] = (_3138 / _3093[2]) + float2(2.0);
                                }
                                int _5136 = _3145 ? 2 : 3;
                                int _4995;
                                float _4998;
                                _4998 = 0.0;
                                _4995 = 0;
                                float _5004;
                                for (; _4995 < _5136; _4998 = _5004, _4995++)
                                {
                                    _5004 = _4998;
                                    for (int _5001 = 0; _5001 < _5136; )
                                    {
                                        _5004 += ((_3093[_5001].x * _3093[_4995].y) * spvDepthCast(_152).sample_compare(_152Smplr, float3(fast::clamp(_132._m22.xy * (_3141 + float2(_3094[_5001].x, _3094[_4995].y)), _3083.xy, _3083.zw), _2899).xy, _2899));
                                        _5001++;
                                        continue;
                                    }
                                }
                                _5005 = _4998 * (_3145 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _5006 = _5005;
                            break;
                        }
                        uint _2909 = _2704 - _2805;
                        if (_2909 >= uint(_132._m21.w))
                        {
                            _5006 = 1.0;
                            break;
                        }
                        float _2930 = _132._m27[_2909].w * length(in.m_1022 - _132._m27[_2909].xyz);
                        float3 _2948 = ((in.m_1022 + (_1401 * (_2930 * _132._m25.x))) + (_2738 * (_2930 * _132._m25.y))) - _132._m27[_2909].xyz;
                        float3 _2950 = abs(_2948);
                        float _2952 = _2950.x;
                        float _2954 = _2950.y;
                        bool _2955 = _2952 >= _2954;
                        bool _2963;
                        if (_2955)
                        {
                            _2963 = _2952 >= _2950.z;
                        }
                        else
                        {
                            _2963 = _2955;
                        }
                        float _4980;
                        int _4982;
                        if (_2963)
                        {
                            _4982 = (_2948.x > 0.0) ? 0 : 1;
                            _4980 = _2952;
                        }
                        else
                        {
                            float _2975 = _2950.z;
                            bool _2976 = _2954 >= _2975;
                            int _4983;
                            if (_2976)
                            {
                                _4983 = (_2948.y > 0.0) ? 2 : 3;
                            }
                            else
                            {
                                _4983 = (_2948.z > 0.0) ? 4 : 5;
                            }
                            _4982 = _4983;
                            _4980 = _2976 ? _2954 : _2975;
                        }
                        if (_4980 <= 0.0)
                        {
                            _5006 = 1.0;
                            break;
                        }
                        float2 _3013 = float2(dot(_2948, _810[_4982]), dot(_2948, _819[_4982])) / float2(_4980 * _132._m24.z);
                        float _3020 = _132._m28[_2909].z + (_132._m28[_2909].w / _4980);
                        if (_3020 > 1.0)
                        {
                            _5006 = 1.0;
                            break;
                        }
                        float2 _3038 = _132._m28[_2909].xy + (float2(float(spvSMod(_4982, 3)), float(_4982 / 3)) * _132._m24.xy);
                        float2 _3278 = _132._m22.xy * 0.5;
                        float2 _3283 = _3038 + (float2(0.5 + (0.5 * _3013.x), 0.5 - (0.5 * _3013.y)) * _132._m24.xy);
                        float4 _3296 = float4(_3038 + _3278, (_3038 + _132._m24.xy) - _3278);
                        float _4994;
                        do
                        {
                            int _3322 = int(_132._m22.z);
                            if (_3322 <= 0)
                            {
                                _4994 = spvDepthCast(_152).sample_compare(_152Smplr, float3(fast::clamp(_3283, _3296.xy, _3296.zw), _3020).xy, _3020);
                                break;
                            }
                            float2 _3345 = (_3283 / _132._m22.xy) + float2(0.5);
                            float2 _3346 = floor(_3345);
                            float2 _3351 = _3345 - _3346;
                            float2 _3354 = _3346 - float2(0.5);
                            bool _3358 = _3322 == 1;
                            if (_3358)
                            {
                                float2 _3361 = _3351 * 2.0;
                                _3306[0] = float2(3.0) - _3361;
                                _3306[1] = float2(1.0) + _3361;
                                _3307[0] = ((float2(2.0) - _3351) / _3306[0]) - float2(1.0);
                                _3307[1] = (_3351 / _3306[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _3388 = _3351 * 3.0;
                                _3306[0] = float2(4.0) - _3388;
                                _3306[1] = float2(7.0);
                                _3306[2] = float2(1.0) + _3388;
                                _3307[0] = ((float2(3.0) - (_3351 * 2.0)) / _3306[0]) - float2(2.0);
                                _3307[1] = (float2(3.0) + _3351) / _3306[1];
                                _3307[2] = (_3351 / _3306[2]) + float2(2.0);
                            }
                            int _5139 = _3358 ? 2 : 3;
                            int _4984;
                            float _4987;
                            _4987 = 0.0;
                            _4984 = 0;
                            float _4993;
                            for (; _4984 < _5139; _4987 = _4993, _4984++)
                            {
                                _4993 = _4987;
                                for (int _4990 = 0; _4990 < _5139; )
                                {
                                    _4993 += ((_3306[_4990].x * _3306[_4984].y) * spvDepthCast(_152).sample_compare(_152Smplr, float3(fast::clamp(_132._m22.xy * (_3354 + float2(_3307[_4990].x, _3307[_4984].y)), _3296.xy, _3296.zw), _3020).xy, _3020));
                                    _4990++;
                                    continue;
                                }
                            }
                            _4994 = _4987 * (_3358 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _5006 = _4994;
                        break;
                    } while(false);
                    _5058 = _2769 * _5006;
                }
                else
                {
                    _5058 = _2769;
                }
                float _1544 = dot(_4780, _2738);
                _1573 = _4905 + (((_4778 * fast::max(_1544, 0.0)) * _5058) + (_5058 * ((powr(fast::max(dot(_4780, fast::normalize(_2738 + _1390)), 0.0), _1198._m1.w) * _1198._m1.z) * step(0.0, _1544))));
            }
            _4904 = _4905;
        }
        else
        {
            _4904 = _1492;
        }
        _4903 = _4904;
    }
    else
    {
        float4 _1583 = _1578.sample(_1225, _1217);
        float _1590 = fast::clamp(_1198._m4.x * _1583.z, 0.0, 1.0);
        float _1598 = fast::clamp(_1198._m4.y * _1583.y, 0.04500000178813934326171875, 1.0);
        float _1602 = _1598 * _1598;
        float3 _1607 = _4778 * (1.0 - _1590);
        float3 _1614 = mix(float3(0.039999999105930328369140625), _4778, float3(_1590));
        float _1619 = fast::max(dot(_4780, _1390), 9.9999997473787516355514526367188e-05);
        float _1624 = fast::clamp(dot(_4780, _1383), 0.0, 1.0);
        float _1629 = fast::clamp(dot(_4780, _1395), 0.0, 1.0);
        float3 _3490 = float3(1.0) - _1614;
        float3 _3493 = _1614 + (_3490 * powr(1.0 - fast::clamp(dot(_1390, _1395), 0.0, 1.0), 5.0));
        float _3500 = _1602 * _1602;
        float _3505 = _3500 - 1.0;
        float _3507 = ((_1629 * _1629) * _3505) + 1.0;
        float _3527 = 1.0 - _3500;
        float _3531 = sqrt(((_1619 * _1619) * _3527) + _3500);
        float4 _3555 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * _1598) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);
        float _3557 = _3555.x;
        float2 _3575 = (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_3557 * _3557, exp2((-9.27999973297119140625) * _1619)) * _3557) + _3555.y)) + _3555.zw;
        float3 _1685 = (_1614 * _3575.x) + float3(_3575.y);
        float3 _3592 = mix(_132._m9.xyz, _132._m8.xyz, float3((_4780.y * 0.5) + 0.5)) * _132._m8.w;
        float3 _1716 = ((((((float3(1.0) - _3493) * _1607) + ((_3493 * ((_3500 / ((3.1415927410125732421875 * _3507) * _3507)) * (0.5 / fast::max((_1624 * _3531) + (_1619 * sqrt(((_1624 * _1624) * _3527) + _3500)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875)) * _1624) * _1432) * _4803) + (((((float3(1.0) - _1685) * _1607) * _3592) + (_1685 * mix(mix(_132._m9.xyz, _132._m8.xyz, float3((reflect(-_1390, _4780).y * 0.5) + 0.5)) * _132._m8.w, _3592, float3(_1598)))) * _1445);
        float3 _4906;
        if (_132._m13.w > 0.5)
        {
            float2 _3637 = fast::clamp(floor(gl_FragCoord.xy * _132._m12.xy), float2(0.0), _132._m13.xy - float2(1.0));
            uint _3665 = uint((((fast::clamp(floor((log2(fast::max(dot(_132._m11.xyz, in.m_1022) + _132._m11.w, 9.9999999747524270787835121154785e-07)) * _132._m12.z) + _132._m12.w), 0.0, _132._m13.z - 1.0) * _132._m13.y) + _3637.y) * _132._m13.x) + _3637.x);
            uint _3667 = _3665 >> uint(2);
            uint _3669 = _3665 & 3u;
            uint _3673 = _1155._m0[_3667][_3669] & 65535u;
            uint _3675 = _1155._m0[_3667][_3669] >> uint(16);
            float3 _4868;
            _4868 = _1716;
            float3 _1816;
            spvUnsafeArray<float2, 3> _4083;
            spvUnsafeArray<float2, 3> _4084;
            spvUnsafeArray<float2, 3> _4296;
            spvUnsafeArray<float2, 3> _4297;
            for (uint _4804 = _3673; _4804 < (_3673 + _3675); _4868 = _1816, _4804++)
            {
                uint _3681 = _4804 / 3u;
                uint _3694 = (_1177._m0[_3681 >> uint(2)][_3681 & 3u] >> ((_4804 - (_3681 * 3u)) * 10u)) & 1023u;
                float3 _3711 = _1014._m0[_3694].xyz - in.m_1022;
                float _3714 = dot(_3711, _3711);
                float _3718 = _3714 * _1014._m0[_3694].w;
                float _3723 = fast::clamp(1.0 - (_3718 * _3718), 0.0, 1.0);
                float3 _3728 = _3711 * rsqrt(fast::max(_3714, 9.9999999392252902907785028219223e-09));
                float _3746 = fast::clamp((dot(-_3728, _1058._m0[_3694].xyz) * _1050._m0[_3694].w) + _1058._m0[_3694].w, 0.0, 1.0);
                float3 _3759 = _1050._m0[_3694].xyz * ((((_3723 * _3723) * _3746) * _3746) / fast::max(_3714, 9.9999997473787516355514526367188e-05));
                float3 _4866;
                if (_1406)
                {
                    float _4831;
                    do
                    {
                        uint _3795 = uint(_132._m21.z);
                        if (_3694 < _3795)
                        {
                            float _3817 = _132._m26[_3694].z * fast::max((_132._m15[_3694] * float4(in.m_1022, 1.0)).w, 0.0);
                            float4 _3841 = _132._m15[_3694] * float4((in.m_1022 + (_1401 * (_3817 * _132._m25.x))) + (_3728 * (_3817 * _132._m25.y)), 1.0);
                            float _3843 = _3841.w;
                            if (_3843 <= 0.0)
                            {
                                _4831 = 1.0;
                                break;
                            }
                            float3 _3852 = _3841.xyz / float3(_3843);
                            float _3854 = _3852.x;
                            bool _3855 = _3854 < 0.0;
                            bool _3862;
                            if (!_3855)
                            {
                                _3862 = _3854 > 1.0;
                            }
                            else
                            {
                                _3862 = _3855;
                            }
                            bool _3869;
                            if (!_3862)
                            {
                                _3869 = _3852.y < 0.0;
                            }
                            else
                            {
                                _3869 = _3862;
                            }
                            bool _3876;
                            if (!_3869)
                            {
                                _3876 = _3852.y > 1.0;
                            }
                            else
                            {
                                _3876 = _3869;
                            }
                            bool _3883;
                            if (!_3876)
                            {
                                _3883 = _3852.z > 1.0;
                            }
                            else
                            {
                                _3883 = _3876;
                            }
                            if (_3883)
                            {
                                _4831 = 1.0;
                                break;
                            }
                            float _3889 = _3852.z;
                            float2 _4055 = _132._m22.xy * 0.5;
                            float2 _4060 = _132._m26[_3694].xy + (_3852.xy * _132._m23.zw);
                            float4 _4073 = float4(_132._m26[_3694].xy + _4055, (_132._m26[_3694].xy + _132._m23.zw) - _4055);
                            float _4830;
                            do
                            {
                                int _4099 = int(_132._m22.z);
                                if (_4099 <= 0)
                                {
                                    float2 _4109 = fast::clamp(_4060, _4073.xy, _4073.zw);
                                    _4830 = spvDepthCast(_152).sample_compare(_152Smplr, float3(_4109, _3889).xy, _3889);
                                    break;
                                }
                                float2 _4122 = (_4060 / _132._m22.xy) + float2(0.5);
                                float2 _4123 = floor(_4122);
                                float2 _4128 = _4122 - _4123;
                                float2 _4131 = _4123 - float2(0.5);
                                bool _4135 = _4099 == 1;
                                if (_4135)
                                {
                                    float2 _4138 = _4128 * 2.0;
                                    _4083[0] = float2(3.0) - _4138;
                                    _4083[1] = float2(1.0) + _4138;
                                    _4084[0] = ((float2(2.0) - _4128) / _4083[0]) - float2(1.0);
                                    _4084[1] = (_4128 / _4083[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _4165 = _4128 * 3.0;
                                    _4083[0] = float2(4.0) - _4165;
                                    _4083[1] = float2(7.0);
                                    _4083[2] = float2(1.0) + _4165;
                                    _4084[0] = ((float2(3.0) - (_4128 * 2.0)) / _4083[0]) - float2(2.0);
                                    _4084[1] = (float2(3.0) + _4128) / _4083[1];
                                    _4084[2] = (_4128 / _4083[2]) + float2(2.0);
                                }
                                int _5141 = _4135 ? 2 : 3;
                                int _4820;
                                float _4823;
                                _4823 = 0.0;
                                _4820 = 0;
                                float _4829;
                                for (; _4820 < _5141; _4823 = _4829, _4820++)
                                {
                                    _4829 = _4823;
                                    for (int _4826 = 0; _4826 < _5141; )
                                    {
                                        _4829 += ((_4083[_4826].x * _4083[_4820].y) * spvDepthCast(_152).sample_compare(_152Smplr, float3(fast::clamp(_132._m22.xy * (_4131 + float2(_4084[_4826].x, _4084[_4820].y)), _4073.xy, _4073.zw), _3889).xy, _3889));
                                        _4826++;
                                        continue;
                                    }
                                }
                                _4830 = _4823 * (_4135 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _4831 = _4830;
                            break;
                        }
                        uint _3899 = _3694 - _3795;
                        if (_3899 >= uint(_132._m21.w))
                        {
                            _4831 = 1.0;
                            break;
                        }
                        float _3920 = _132._m27[_3899].w * length(in.m_1022 - _132._m27[_3899].xyz);
                        float3 _3938 = ((in.m_1022 + (_1401 * (_3920 * _132._m25.x))) + (_3728 * (_3920 * _132._m25.y))) - _132._m27[_3899].xyz;
                        float3 _3940 = abs(_3938);
                        float _3942 = _3940.x;
                        float _3944 = _3940.y;
                        bool _3945 = _3942 >= _3944;
                        bool _3953;
                        if (_3945)
                        {
                            _3953 = _3942 >= _3940.z;
                        }
                        else
                        {
                            _3953 = _3945;
                        }
                        float _4805;
                        int _4807;
                        if (_3953)
                        {
                            _4807 = (_3938.x > 0.0) ? 0 : 1;
                            _4805 = _3942;
                        }
                        else
                        {
                            float _3965 = _3940.z;
                            bool _3966 = _3944 >= _3965;
                            int _4808;
                            if (_3966)
                            {
                                _4808 = (_3938.y > 0.0) ? 2 : 3;
                            }
                            else
                            {
                                _4808 = (_3938.z > 0.0) ? 4 : 5;
                            }
                            _4807 = _4808;
                            _4805 = _3966 ? _3944 : _3965;
                        }
                        if (_4805 <= 0.0)
                        {
                            _4831 = 1.0;
                            break;
                        }
                        float2 _4003 = float2(dot(_3938, _810[_4807]), dot(_3938, _819[_4807])) / float2(_4805 * _132._m24.z);
                        float _4010 = _132._m28[_3899].z + (_132._m28[_3899].w / _4805);
                        if (_4010 > 1.0)
                        {
                            _4831 = 1.0;
                            break;
                        }
                        float2 _4028 = _132._m28[_3899].xy + (float2(float(spvSMod(_4807, 3)), float(_4807 / 3)) * _132._m24.xy);
                        float2 _4268 = _132._m22.xy * 0.5;
                        float2 _4273 = _4028 + (float2(0.5 + (0.5 * _4003.x), 0.5 - (0.5 * _4003.y)) * _132._m24.xy);
                        float4 _4286 = float4(_4028 + _4268, (_4028 + _132._m24.xy) - _4268);
                        float _4819;
                        do
                        {
                            int _4312 = int(_132._m22.z);
                            if (_4312 <= 0)
                            {
                                _4819 = spvDepthCast(_152).sample_compare(_152Smplr, float3(fast::clamp(_4273, _4286.xy, _4286.zw), _4010).xy, _4010);
                                break;
                            }
                            float2 _4335 = (_4273 / _132._m22.xy) + float2(0.5);
                            float2 _4336 = floor(_4335);
                            float2 _4341 = _4335 - _4336;
                            float2 _4344 = _4336 - float2(0.5);
                            bool _4348 = _4312 == 1;
                            if (_4348)
                            {
                                float2 _4351 = _4341 * 2.0;
                                _4296[0] = float2(3.0) - _4351;
                                _4296[1] = float2(1.0) + _4351;
                                _4297[0] = ((float2(2.0) - _4341) / _4296[0]) - float2(1.0);
                                _4297[1] = (_4341 / _4296[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _4378 = _4341 * 3.0;
                                _4296[0] = float2(4.0) - _4378;
                                _4296[1] = float2(7.0);
                                _4296[2] = float2(1.0) + _4378;
                                _4297[0] = ((float2(3.0) - (_4341 * 2.0)) / _4296[0]) - float2(2.0);
                                _4297[1] = (float2(3.0) + _4341) / _4296[1];
                                _4297[2] = (_4341 / _4296[2]) + float2(2.0);
                            }
                            int _5144 = _4348 ? 2 : 3;
                            int _4809;
                            float _4812;
                            _4812 = 0.0;
                            _4809 = 0;
                            float _4818;
                            for (; _4809 < _5144; _4812 = _4818, _4809++)
                            {
                                _4818 = _4812;
                                for (int _4815 = 0; _4815 < _5144; )
                                {
                                    _4818 += ((_4296[_4815].x * _4296[_4809].y) * spvDepthCast(_152).sample_compare(_152Smplr, float3(fast::clamp(_132._m22.xy * (_4344 + float2(_4297[_4815].x, _4297[_4809].y)), _4286.xy, _4286.zw), _4010).xy, _4010));
                                    _4815++;
                                    continue;
                                }
                            }
                            _4819 = _4812 * (_4348 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _4831 = _4819;
                        break;
                    } while(false);
                    _4866 = _3759 * _4831;
                }
                else
                {
                    _4866 = _3759;
                }
                float3 _1768 = fast::normalize(_3728 + _1390);
                float _1773 = fast::clamp(dot(_4780, _3728), 0.0, 1.0);
                float _1778 = fast::clamp(dot(_4780, _1768), 0.0, 1.0);
                float3 _4483 = _1614 + (_3490 * powr(1.0 - fast::clamp(dot(_1390, _1768), 0.0, 1.0), 5.0));
                float _4497 = ((_1778 * _1778) * _3505) + 1.0;
                _1816 = _4868 + (((((float3(1.0) - _4483) * _1607) + ((_4483 * ((_3500 / ((3.1415927410125732421875 * _4497) * _4497)) * (0.5 / fast::max((_1773 * _3531) + (_1619 * sqrt(((_1773 * _1773) * _3527) + _3500)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875)) * _1773) * _4866);
            }
            _4906 = _4868;
        }
        else
        {
            _4906 = _1716;
        }
        _4903 = _4906;
    }
    out.m_1855 = float4(mix(mix(_4903, _4778, float3(_1198._m1.y)) + (_1198._m5.xyz * _1828.sample(_1225, _1217).xyz), _132._m7.xyz, float3(1.0 - exp((-length(_1389)) * _132._m7.w))), in.m_1232.w);
    float2 _4979;
    do
    {
        if (in.m_1871.w <= 0.0)
        {
            _4979 = float2(0.0);
            break;
        }
        _4979 = ((in.m_1871.xy / float2(in.m_1871.w)) - (in.m_1870.xy / float2(in.m_1870.w))) * float2(0.5, -0.5);
        break;
    } while(false);
    out.m_1869 = _4979;
    return out;
}

