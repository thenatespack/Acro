// Generated from mesh.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: e9d9a2fbecab2986
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
    float4 m_2390 [[color(0)]];
    float2 m_2404 [[color(1)]];
};

struct fragment_main_in
{
    float3 m_1444 [[user(locn0)]];
    float3 m_1692 [[user(locn1)]];
    float2 m_1625 [[user(locn2)]];
    float4 m_1648 [[user(locn3)]];
    float4 m_1840 [[user(locn5)]];
    float4 m_2405 [[user(locn6)]];
    float4 m_2406 [[user(locn7)]];
    float4 m_1701 [[user(locn8)]];
};

fragment fragment_main_out fragment_main(fragment_main_in in [[stage_in]], constant _1618& _1620 [[buffer(2)]], constant _1434& _1436 [[buffer(3)]], constant _1470& _1472 [[buffer(4)]], constant _1478& _1480 [[buffer(5)]], constant _1575& _1577 [[buffer(6)]], constant _1597& _1599 [[buffer(7)]], constant _171& _173 [[buffer(15)]], texture2d<float> _193 [[texture(0)]], texture2d<float> _1641 [[texture(1)]], texture2d<float> _2026 [[texture(2)]], texture2d<float> _1730 [[texture(3)]], texture2d<float> _1873 [[texture(4)]], texture2d<float> _2298 [[texture(5)]], texture2d<float> _1208 [[texture(6)]], texture2d<float> _1314 [[texture(7)]], sampler _193Smplr [[sampler(0)]], sampler _1210 [[sampler(1)]], sampler _1316 [[sampler(7)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])
{
    fragment_main_out out = {};
    float2 _1639 = float2(dot(_1620._m2.xy, in.m_1625) + _1620._m2.z, dot(_1620._m3.xy, in.m_1625) + _1620._m3.z);
    float4 _1646 = _1641.sample(_1210, _1639);
    float3 _1657 = (in.m_1648.xyz * _1620._m0.xyz) * _1646.xyz;
    float3 _6049;
    if (_1620._m1.x > 0.5)
    {
        float2 _1678 = floor(in.m_1444.xz * float2(0.5));
        _6049 = _1657 * ((mod(abs(_1678.x + _1678.y), 2.0) < 0.5) ? 1.0 : 0.75);
    }
    else
    {
        _6049 = _1657;
    }
    float3 _1694 = fast::normalize(in.m_1692);
    float3 _5963;
    if (_1620._m6.y > 0.5)
    {
        float3 _1710 = in.m_1701.xyz - (_1694 * dot(_1694, in.m_1701.xyz));
        float3 _5964;
        if (dot(_1710, _1710) > 9.9999999600419720025001879548654e-13)
        {
            float3 _1719 = fast::normalize(_1710);
            float4 _1735 = _1730.sample(_1210, _1639);
            float3 _5957;
            if (_1620._m6.z > 0.5)
            {
                float2 _5956;
                if (_1620._m6.z > 1.5)
                {
                    _5956 = _1735.xw;
                }
                else
                {
                    _5956 = _1735.xy;
                }
                float2 _1757 = (_5956 * 2.0) - float2(1.0);
                _5957 = float3(_1757, sqrt(fast::clamp(1.0 - dot(_1757, _1757), 0.0, 1.0)));
            }
            else
            {
                _5957 = (_1735.xyz * 2.0) - float3(1.0);
            }
            float2 _1779 = _5957.xy * _1620._m4.z;
            _5964 = fast::normalize(((_1719 * _1779.x) + ((cross(_1694, _1719) * ((in.m_1701.w < 0.0) ? (-1.0) : 1.0)) * _1779.y)) + (_1694 * _5957.z));
        }
        else
        {
            _5964 = _1694;
        }
        _5963 = _5964;
    }
    else
    {
        _5963 = _1694;
    }
    bool _1803 = _1620._m5.w > 0.5;
    bool _1811;
    if (_1803)
    {
        _1811 = !gl_FrontFacing;
    }
    else
    {
        _1811 = _1803;
    }
    float3 _6074;
    if (_1811)
    {
        _6074 = -_5963;
    }
    else
    {
        _6074 = _5963;
    }
    float3 _1820 = fast::normalize(_173._m4.xyz);
    float3 _1826 = _173._m6.xyz - in.m_1444;
    float3 _1827 = fast::normalize(_1826);
    float3 _1832 = fast::normalize(_1820 + _1827);
    float3 _1838 = _1694 * (gl_FrontFacing ? 1.0 : (-1.0));
    bool _1843 = in.m_1840.x > 0.5;
    float3 _6072;
    float _6097;
    if ((_173._m5.w > 0.5) && _1843)
    {
        float _6020;
        float3 _6021;
        do
        {
            int _2459 = int(_173._m21.x);
            float _2467 = dot(_173._m20.xyz, in.m_1444) + _173._m20.w;
            int _5965;
            _5965 = 0;
            for (;;)
            {
                bool _2473 = _5965 < (_2459 - 1);
                bool _2481;
                if (_2473)
                {
                    _2481 = _2467 > _173._m16[_5965];
                }
                else
                {
                    _2481 = _2473;
                }
                if (_2481)
                {
                    _5965++;
                    continue;
                }
                else
                {
                    break;
                }
            }
            if (_2467 > _173._m16[_5965])
            {
                _6021 = float3(1.0);
                _6020 = 1.0;
                break;
            }
            float _5978;
            do
            {
                float4 _2583 = _173._m14[_5965] * float4(in.m_1444 + (_1838 * _173._m18[_5965]), 1.0);
                float _2586 = _2583.x;
                bool _2587 = _2586 < 0.0;
                bool _2594;
                if (!_2587)
                {
                    _2594 = _2586 > 1.0;
                }
                else
                {
                    _2594 = _2587;
                }
                bool _2601;
                if (!_2594)
                {
                    _2601 = _2583.y < 0.0;
                }
                else
                {
                    _2601 = _2594;
                }
                bool _2608;
                if (!_2601)
                {
                    _2608 = _2583.y > 1.0;
                }
                else
                {
                    _2608 = _2601;
                }
                if (_2608)
                {
                    _5978 = 1.0;
                    break;
                }
                float2 _2621 = float2(float(_5965 & 1), float(_5965 >> 1)) * _173._m23.xy;
                float _2628 = fast::min(_2583.z, 1.0) - _173._m19[_5965];
                float2 _2647 = _173._m22.xy * 0.5;
                float2 _2652 = _2621 + (_2583.xy * _173._m23.xy);
                float4 _2665 = float4(_2621 + _2647, (_2621 + _173._m23.xy) - _2647);
                float _5977;
                do
                {
                    int _2691 = int(_173._m22.z);
                    if (_2691 <= 0)
                    {
                        _5977 = spvDepthCast(_193).sample_compare(_193Smplr, float3(fast::clamp(_2652, _2665.xy, _2665.zw), _2628).xy, _2628);
                        break;
                    }
                    float2 _2714 = (_2652 / _173._m22.xy) + float2(0.5);
                    float2 _2715 = floor(_2714);
                    float2 _2720 = _2714 - _2715;
                    float2 _2723 = _2715 - float2(0.5);
                    bool _2727 = _2691 == 1;
                    spvUnsafeArray<float2, 3> _2675;
                    spvUnsafeArray<float2, 3> _2676;
                    if (_2727)
                    {
                        float2 _2730 = _2720 * 2.0;
                        _2675[0] = float2(3.0) - _2730;
                        _2675[1] = float2(1.0) + _2730;
                        _2676[0] = ((float2(2.0) - _2720) / _2675[0]) - float2(1.0);
                        _2676[1] = (_2720 / _2675[1]) + float2(1.0);
                    }
                    else
                    {
                        float2 _2757 = _2720 * 3.0;
                        _2675[0] = float2(4.0) - _2757;
                        _2675[1] = float2(7.0);
                        _2675[2] = float2(1.0) + _2757;
                        _2676[0] = ((float2(3.0) - (_2720 * 2.0)) / _2675[0]) - float2(2.0);
                        _2676[1] = (float2(3.0) + _2720) / _2675[1];
                        _2676[2] = (_2720 / _2675[2]) + float2(2.0);
                    }
                    int _6422 = _2727 ? 2 : 3;
                    int _5967;
                    float _5970;
                    _5970 = 0.0;
                    _5967 = 0;
                    float _5976;
                    for (; _5967 < _6422; _5970 = _5976, _5967++)
                    {
                        _5976 = _5970;
                        for (int _5973 = 0; _5973 < _6422; )
                        {
                            _5976 += ((_2675[_5973].x * _2675[_5967].y) * spvDepthCast(_193).sample_compare(_193Smplr, float3(fast::clamp(_173._m22.xy * (_2723 + float2(_2676[_5973].x, _2676[_5967].y)), _2665.xy, _2665.zw), _2628).xy, _2628));
                            _5973++;
                            continue;
                        }
                    }
                    _5977 = _5970 * (_2727 ? 0.0625 : 0.0069444444961845874786376953125);
                    break;
                } while(false);
                _5978 = _5977;
                break;
            } while(false);
            float3 _6015;
            float _6018;
            if (_2467 > _173._m17[_5965])
            {
                float _2521 = (_2467 - _173._m17[_5965]) / (_173._m16[_5965] - _173._m17[_5965]);
                int _2523 = _5965 + 1;
                float3 _6016;
                float _6019;
                if (_2523 < _2459)
                {
                    float _5998;
                    do
                    {
                        float4 _2870 = _173._m14[_2523] * float4(in.m_1444 + (_1838 * _173._m18[_2523]), 1.0);
                        float _2873 = _2870.x;
                        bool _2874 = _2873 < 0.0;
                        bool _2881;
                        if (!_2874)
                        {
                            _2881 = _2873 > 1.0;
                        }
                        else
                        {
                            _2881 = _2874;
                        }
                        bool _2888;
                        if (!_2881)
                        {
                            _2888 = _2870.y < 0.0;
                        }
                        else
                        {
                            _2888 = _2881;
                        }
                        bool _2895;
                        if (!_2888)
                        {
                            _2895 = _2870.y > 1.0;
                        }
                        else
                        {
                            _2895 = _2888;
                        }
                        if (_2895)
                        {
                            _5998 = 1.0;
                            break;
                        }
                        float2 _2908 = float2(float(_2523 & 1), float(_2523 >> 1)) * _173._m23.xy;
                        float _2915 = fast::min(_2870.z, 1.0) - _173._m19[_2523];
                        float2 _2934 = _173._m22.xy * 0.5;
                        float2 _2939 = _2908 + (_2870.xy * _173._m23.xy);
                        float4 _2952 = float4(_2908 + _2934, (_2908 + _173._m23.xy) - _2934);
                        float _5997;
                        do
                        {
                            int _2978 = int(_173._m22.z);
                            if (_2978 <= 0)
                            {
                                _5997 = spvDepthCast(_193).sample_compare(_193Smplr, float3(fast::clamp(_2939, _2952.xy, _2952.zw), _2915).xy, _2915);
                                break;
                            }
                            float2 _3001 = (_2939 / _173._m22.xy) + float2(0.5);
                            float2 _3002 = floor(_3001);
                            float2 _3007 = _3001 - _3002;
                            float2 _3010 = _3002 - float2(0.5);
                            bool _3014 = _2978 == 1;
                            spvUnsafeArray<float2, 3> _2962;
                            spvUnsafeArray<float2, 3> _2963;
                            if (_3014)
                            {
                                float2 _3017 = _3007 * 2.0;
                                _2962[0] = float2(3.0) - _3017;
                                _2962[1] = float2(1.0) + _3017;
                                _2963[0] = ((float2(2.0) - _3007) / _2962[0]) - float2(1.0);
                                _2963[1] = (_3007 / _2962[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _3044 = _3007 * 3.0;
                                _2962[0] = float2(4.0) - _3044;
                                _2962[1] = float2(7.0);
                                _2962[2] = float2(1.0) + _3044;
                                _2963[0] = ((float2(3.0) - (_3007 * 2.0)) / _2962[0]) - float2(2.0);
                                _2963[1] = (float2(3.0) + _3007) / _2962[1];
                                _2963[2] = (_3007 / _2962[2]) + float2(2.0);
                            }
                            int _6424 = _3014 ? 2 : 3;
                            int _5987;
                            float _5990;
                            _5990 = 0.0;
                            _5987 = 0;
                            float _5996;
                            for (; _5987 < _6424; _5990 = _5996, _5987++)
                            {
                                _5996 = _5990;
                                for (int _5993 = 0; _5993 < _6424; )
                                {
                                    _5996 += ((_2962[_5993].x * _2962[_5987].y) * spvDepthCast(_193).sample_compare(_193Smplr, float3(fast::clamp(_173._m22.xy * (_3010 + float2(_2963[_5993].x, _2963[_5987].y)), _2952.xy, _2952.zw), _2915).xy, _2915));
                                    _5993++;
                                    continue;
                                }
                            }
                            _5997 = _5990 * (_3014 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _5998 = _5997;
                        break;
                    } while(false);
                    _6019 = mix(_5978, _5998, _2521);
                    _6016 = mix(_547[_5965], _547[_2523], float3(_2521));
                }
                else
                {
                    _6019 = mix(_5978, 1.0, _2521);
                    _6016 = _547[_5965];
                }
                _6018 = _6019;
                _6015 = _6016;
            }
            else
            {
                _6018 = _5978;
                _6015 = _547[_5965];
            }
            _6021 = select(float3(1.0), _6015, bool3(_173._m22.w > 0.5));
            _6020 = _6018;
            break;
        } while(false);
        _6097 = _6020;
        _6072 = _6049 * _6021;
    }
    else
    {
        _6097 = 1.0;
        _6072 = _6049;
    }
    float3 _1869 = _173._m5.xyz * _173._m4.w;
    float4 _1878 = _1873.sample(_1210, _1639);
    float _1882 = 1.0 + (_1620._m4.w * (_1878.x - 1.0));
    float3 _6244;
    if (!_1803)
    {
        float _1890 = dot(_6074, _1820);
        float3 _6238;
        if (_173._m29.x > 0.5)
        {
            float _3195 = (_173._m29.z * _6074.x) - (_173._m29.w * _6074.z);
            float _3208 = (_173._m29.w * _6074.x) + (_173._m29.z * _6074.z);
            float _3226 = 1.09254801273345947265625 * _3195;
            spvUnsafeArray<float, 9> _5770 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _6074.y, 0.48860299587249755859375 * _3208, 0.48860299587249755859375 * _3195, _3226 * _6074.y, (1.09254801273345947265625 * _6074.y) * _3208, 0.3153919875621795654296875 * (((3.0 * _3208) * _3208) - 1.0), _3226 * _3208, 0.546274006366729736328125 * ((_3195 * _3195) - (_6074.y * _6074.y)) });
            spvUnsafeArray<float, 9> _3140 = _5770;
            float3 _6237;
            _6237 = float3(0.0);
            for (int _6236 = 0; _6236 < 9; )
            {
                _6237 += (_1208.read(uint2((int2(496, 256) + int2(_6236, 0))), 0).xyz * _3140[_6236]);
                _6236++;
                continue;
            }
            _6238 = fast::max(_6237, float3(0.0)) * _173._m29.y;
        }
        else
        {
            _6238 = mix(_173._m9.xyz, _173._m8.xyz, float3((_6074.y * 0.5) + 0.5)) * _173._m8.w;
        }
        float3 _1940 = (_6072 * ((_6238 * _1882) + ((_1869 * fast::max(_1890, 0.0)) * _6097))) + ((_1869 * ((powr(fast::max(dot(_6074, _1832), 0.0), _1620._m1.w) * _1620._m1.z) * step(0.0, _1890))) * _6097);
        float3 _6245;
        if (_173._m13.w > 0.5)
        {
            float2 _3311 = fast::clamp(floor(gl_FragCoord.xy * _173._m12.xy), float2(0.0), _173._m13.xy - float2(1.0));
            uint _3339 = uint((((fast::clamp(floor((log2(fast::max(dot(_173._m11.xyz, in.m_1444) + _173._m11.w, 9.9999999747524270787835121154785e-07)) * _173._m12.z) + _173._m12.w), 0.0, _173._m13.z - 1.0) * _173._m13.y) + _3311.y) * _173._m13.x) + _3311.x);
            uint _3341 = _3339 >> uint(2);
            uint _3343 = _3339 & 3u;
            uint _3347 = _1577._m0[_3341][_3343] & 65535u;
            uint _3349 = _1577._m0[_3341][_3343] >> uint(16);
            float3 _6246;
            _6246 = _1940;
            float3 _2021;
            spvUnsafeArray<float2, 3> _3757;
            spvUnsafeArray<float2, 3> _3758;
            spvUnsafeArray<float2, 3> _3970;
            spvUnsafeArray<float2, 3> _3971;
            for (uint _6243 = _3347; _6243 < (_3347 + _3349); _6246 = _2021, _6243++)
            {
                uint _3355 = _6243 / 3u;
                uint _3368 = (_1599._m0[_3355 >> uint(2)][_3355 & 3u] >> ((_6243 - (_3355 * 3u)) * 10u)) & 1023u;
                float3 _3385 = _1436._m0[_3368].xyz - in.m_1444;
                float _3388 = dot(_3385, _3385);
                float _3392 = _3388 * _1436._m0[_3368].w;
                float _3397 = fast::clamp(1.0 - (_3392 * _3392), 0.0, 1.0);
                float3 _3402 = _3385 * rsqrt(fast::max(_3388, 9.9999999392252902907785028219223e-09));
                float _3420 = fast::clamp((dot(-_3402, _1480._m0[_3368].xyz) * _1472._m0[_3368].w) + _1480._m0[_3368].w, 0.0, 1.0);
                float3 _3433 = _1472._m0[_3368].xyz * ((((_3397 * _3397) * _3420) * _3420) / fast::max(_3388, 9.9999997473787516355514526367188e-05));
                float3 _6363;
                if (_1843)
                {
                    float _6309;
                    do
                    {
                        uint _3469 = uint(_173._m21.z);
                        if (_3368 < _3469)
                        {
                            float _3491 = _173._m26[_3368].z * fast::max((_173._m15[_3368] * float4(in.m_1444, 1.0)).w, 0.0);
                            float4 _3515 = _173._m15[_3368] * float4((in.m_1444 + (_1838 * (_3491 * _173._m25.x))) + (_3402 * (_3491 * _173._m25.y)), 1.0);
                            float _3517 = _3515.w;
                            if (_3517 <= 0.0)
                            {
                                _6309 = 1.0;
                                break;
                            }
                            float3 _3526 = _3515.xyz / float3(_3517);
                            float _3528 = _3526.x;
                            bool _3529 = _3528 < 0.0;
                            bool _3536;
                            if (!_3529)
                            {
                                _3536 = _3528 > 1.0;
                            }
                            else
                            {
                                _3536 = _3529;
                            }
                            bool _3543;
                            if (!_3536)
                            {
                                _3543 = _3526.y < 0.0;
                            }
                            else
                            {
                                _3543 = _3536;
                            }
                            bool _3550;
                            if (!_3543)
                            {
                                _3550 = _3526.y > 1.0;
                            }
                            else
                            {
                                _3550 = _3543;
                            }
                            bool _3557;
                            if (!_3550)
                            {
                                _3557 = _3526.z > 1.0;
                            }
                            else
                            {
                                _3557 = _3550;
                            }
                            if (_3557)
                            {
                                _6309 = 1.0;
                                break;
                            }
                            float _3563 = _3526.z;
                            float2 _3729 = _173._m22.xy * 0.5;
                            float2 _3734 = _173._m26[_3368].xy + (_3526.xy * _173._m23.zw);
                            float4 _3747 = float4(_173._m26[_3368].xy + _3729, (_173._m26[_3368].xy + _173._m23.zw) - _3729);
                            float _6308;
                            do
                            {
                                int _3773 = int(_173._m22.z);
                                if (_3773 <= 0)
                                {
                                    float2 _3783 = fast::clamp(_3734, _3747.xy, _3747.zw);
                                    _6308 = spvDepthCast(_193).sample_compare(_193Smplr, float3(_3783, _3563).xy, _3563);
                                    break;
                                }
                                float2 _3796 = (_3734 / _173._m22.xy) + float2(0.5);
                                float2 _3797 = floor(_3796);
                                float2 _3802 = _3796 - _3797;
                                float2 _3805 = _3797 - float2(0.5);
                                bool _3809 = _3773 == 1;
                                if (_3809)
                                {
                                    float2 _3812 = _3802 * 2.0;
                                    _3757[0] = float2(3.0) - _3812;
                                    _3757[1] = float2(1.0) + _3812;
                                    _3758[0] = ((float2(2.0) - _3802) / _3757[0]) - float2(1.0);
                                    _3758[1] = (_3802 / _3757[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _3839 = _3802 * 3.0;
                                    _3757[0] = float2(4.0) - _3839;
                                    _3757[1] = float2(7.0);
                                    _3757[2] = float2(1.0) + _3839;
                                    _3758[0] = ((float2(3.0) - (_3802 * 2.0)) / _3757[0]) - float2(2.0);
                                    _3758[1] = (float2(3.0) + _3802) / _3757[1];
                                    _3758[2] = (_3802 / _3757[2]) + float2(2.0);
                                }
                                int _6429 = _3809 ? 2 : 3;
                                int _6298;
                                float _6301;
                                _6301 = 0.0;
                                _6298 = 0;
                                float _6307;
                                for (; _6298 < _6429; _6301 = _6307, _6298++)
                                {
                                    _6307 = _6301;
                                    for (int _6304 = 0; _6304 < _6429; )
                                    {
                                        _6307 += ((_3757[_6304].x * _3757[_6298].y) * spvDepthCast(_193).sample_compare(_193Smplr, float3(fast::clamp(_173._m22.xy * (_3805 + float2(_3758[_6304].x, _3758[_6298].y)), _3747.xy, _3747.zw), _3563).xy, _3563));
                                        _6304++;
                                        continue;
                                    }
                                }
                                _6308 = _6301 * (_3809 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _6309 = _6308;
                            break;
                        }
                        uint _3573 = _3368 - _3469;
                        if (_3573 >= uint(_173._m21.w))
                        {
                            _6309 = 1.0;
                            break;
                        }
                        float _3594 = _173._m27[_3573].w * length(in.m_1444 - _173._m27[_3573].xyz);
                        float3 _3612 = ((in.m_1444 + (_1838 * (_3594 * _173._m25.x))) + (_3402 * (_3594 * _173._m25.y))) - _173._m27[_3573].xyz;
                        float3 _3614 = abs(_3612);
                        float _3616 = _3614.x;
                        float _3618 = _3614.y;
                        bool _3619 = _3616 >= _3618;
                        bool _3627;
                        if (_3619)
                        {
                            _3627 = _3616 >= _3614.z;
                        }
                        else
                        {
                            _3627 = _3619;
                        }
                        float _6283;
                        int _6285;
                        if (_3627)
                        {
                            _6285 = (_3612.x > 0.0) ? 0 : 1;
                            _6283 = _3616;
                        }
                        else
                        {
                            float _3639 = _3614.z;
                            bool _3640 = _3618 >= _3639;
                            int _6286;
                            if (_3640)
                            {
                                _6286 = (_3612.y > 0.0) ? 2 : 3;
                            }
                            else
                            {
                                _6286 = (_3612.z > 0.0) ? 4 : 5;
                            }
                            _6285 = _6286;
                            _6283 = _3640 ? _3618 : _3639;
                        }
                        if (_6283 <= 0.0)
                        {
                            _6309 = 1.0;
                            break;
                        }
                        float2 _3677 = float2(dot(_3612, _851[_6285]), dot(_3612, _860[_6285])) / float2(_6283 * _173._m24.z);
                        float _3684 = _173._m28[_3573].z + (_173._m28[_3573].w / _6283);
                        if (_3684 > 1.0)
                        {
                            _6309 = 1.0;
                            break;
                        }
                        float2 _3702 = _173._m28[_3573].xy + (float2(float(spvSMod(_6285, 3)), float(_6285 / 3)) * _173._m24.xy);
                        float2 _3942 = _173._m22.xy * 0.5;
                        float2 _3947 = _3702 + (float2(0.5 + (0.5 * _3677.x), 0.5 - (0.5 * _3677.y)) * _173._m24.xy);
                        float4 _3960 = float4(_3702 + _3942, (_3702 + _173._m24.xy) - _3942);
                        float _6297;
                        do
                        {
                            int _3986 = int(_173._m22.z);
                            if (_3986 <= 0)
                            {
                                _6297 = spvDepthCast(_193).sample_compare(_193Smplr, float3(fast::clamp(_3947, _3960.xy, _3960.zw), _3684).xy, _3684);
                                break;
                            }
                            float2 _4009 = (_3947 / _173._m22.xy) + float2(0.5);
                            float2 _4010 = floor(_4009);
                            float2 _4015 = _4009 - _4010;
                            float2 _4018 = _4010 - float2(0.5);
                            bool _4022 = _3986 == 1;
                            if (_4022)
                            {
                                float2 _4025 = _4015 * 2.0;
                                _3970[0] = float2(3.0) - _4025;
                                _3970[1] = float2(1.0) + _4025;
                                _3971[0] = ((float2(2.0) - _4015) / _3970[0]) - float2(1.0);
                                _3971[1] = (_4015 / _3970[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _4052 = _4015 * 3.0;
                                _3970[0] = float2(4.0) - _4052;
                                _3970[1] = float2(7.0);
                                _3970[2] = float2(1.0) + _4052;
                                _3971[0] = ((float2(3.0) - (_4015 * 2.0)) / _3970[0]) - float2(2.0);
                                _3971[1] = (float2(3.0) + _4015) / _3970[1];
                                _3971[2] = (_4015 / _3970[2]) + float2(2.0);
                            }
                            int _6432 = _4022 ? 2 : 3;
                            int _6287;
                            float _6290;
                            _6290 = 0.0;
                            _6287 = 0;
                            float _6296;
                            for (; _6287 < _6432; _6290 = _6296, _6287++)
                            {
                                _6296 = _6290;
                                for (int _6293 = 0; _6293 < _6432; )
                                {
                                    _6296 += ((_3970[_6293].x * _3970[_6287].y) * spvDepthCast(_193).sample_compare(_193Smplr, float3(fast::clamp(_173._m22.xy * (_4018 + float2(_3971[_6293].x, _3971[_6287].y)), _3960.xy, _3960.zw), _3684).xy, _3684));
                                    _6293++;
                                    continue;
                                }
                            }
                            _6297 = _6290 * (_4022 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _6309 = _6297;
                        break;
                    } while(false);
                    _6363 = _3433 * _6309;
                }
                else
                {
                    _6363 = _3433;
                }
                float _1992 = dot(_6074, _3402);
                _2021 = _6246 + (((_6072 * fast::max(_1992, 0.0)) * _6363) + (_6363 * ((powr(fast::max(dot(_6074, fast::normalize(_3402 + _1827)), 0.0), _1620._m1.w) * _1620._m1.z) * step(0.0, _1992))));
            }
            _6245 = _6246;
        }
        else
        {
            _6245 = _1940;
        }
        _6244 = _6245;
    }
    else
    {
        float4 _2031 = _2026.sample(_1210, _1639);
        float _2038 = fast::clamp(_1620._m4.x * _2031.z, 0.0, 1.0);
        float _2046 = fast::clamp(_1620._m4.y * _2031.y, 0.04500000178813934326171875, 1.0);
        float _2050 = _2046 * _2046;
        float3 _2055 = _6072 * (1.0 - _2038);
        float3 _2062 = mix(float3(0.039999999105930328369140625), _6072, float3(_2038));
        float _2067 = fast::max(dot(_6074, _1827), 9.9999997473787516355514526367188e-05);
        float _2072 = fast::clamp(dot(_6074, _1820), 0.0, 1.0);
        float _2077 = fast::clamp(dot(_6074, _1832), 0.0, 1.0);
        float3 _4154 = float3(1.0) - _2062;
        float3 _4157 = _2062 + (_4154 * powr(1.0 - fast::clamp(dot(_1827, _1832), 0.0, 1.0), 5.0));
        float _4164 = _2050 * _2050;
        float _4169 = _4164 - 1.0;
        float _4171 = ((_2077 * _2077) * _4169) + 1.0;
        float _4191 = 1.0 - _4164;
        float _4195 = sqrt(((_2067 * _2067) * _4191) + _4164);
        float2 _6115;
        float3 _6123;
        float3 _6130;
        if (_173._m29.x > 0.5)
        {
            float4 _4228 = _1314.sample(_1316, (((float2(_2067, _2046) * 31.0) + float2(0.5)) * float2(0.03125)));
            float _4287 = (_173._m29.z * _6074.x) - (_173._m29.w * _6074.z);
            float _4300 = (_173._m29.w * _6074.x) + (_173._m29.z * _6074.z);
            float _4318 = 1.09254801273345947265625 * _4287;
            spvUnsafeArray<float, 9> _5751 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _6074.y, 0.48860299587249755859375 * _4300, 0.48860299587249755859375 * _4287, _4318 * _6074.y, (1.09254801273345947265625 * _6074.y) * _4300, 0.3153919875621795654296875 * (((3.0 * _4300) * _4300) - 1.0), _4318 * _4300, 0.546274006366729736328125 * ((_4287 * _4287) - (_6074.y * _6074.y)) });
            spvUnsafeArray<float, 9> _4232 = _5751;
            float3 _6099;
            _6099 = float3(0.0);
            for (int _6098 = 0; _6098 < 9; )
            {
                _6099 += (_1208.read(uint2((int2(496, 256) + int2(_6098, 0))), 0).xyz * _4232[_6098]);
                _6098++;
                continue;
            }
            float3 _2138 = reflect(-_1827, _6074);
            float _4413 = _2138.x;
            float _4418 = _2138.z;
            float2 _4450 = float2((precise::atan2((_173._m29.z * _4413) - (_173._m29.w * _4418), -((_173._m29.w * _4413) + (_173._m29.z * _4418))) * 0.15915493667125701904296875) + 0.5, acos(fast::clamp(_2138.y, -1.0, 1.0)) * 0.3183098733425140380859375);
            float _4382 = _2046 * 5.0;
            int _4385 = min(int(_4382), 4);
            float2 _4471 = (_4450 * float2(_1270[_4385].zw)) - float2(0.5);
            float2 _4473 = floor(_4471);
            float2 _4476 = _4471 - _4473;
            int _4479 = int(_4473.x);
            int _4482 = int(_4473.y);
            int _6101;
            if (_4479 < 0)
            {
                _6101 = _4479 + _1270[_4385].z;
            }
            else
            {
                _6101 = _4479;
            }
            int _6102;
            if (_6101 >= _1270[_4385].z)
            {
                _6102 = _6101 - _1270[_4385].z;
            }
            else
            {
                _6102 = _6101;
            }
            int _4502 = _6102 + 1;
            int _6433 = (_4502 == _1270[_4385].z) ? 0 : _4502;
            int _4517 = min((_4482 + 1), (_1270[_4385].w - 1));
            int _4519 = max(_4482, 0);
            float3 _4572 = float3(_4476.x);
            int _4392 = _4385 + 1;
            float2 _4604 = (_4450 * float2(_1270[_4392].zw)) - float2(0.5);
            float2 _4606 = floor(_4604);
            float2 _4609 = _4604 - _4606;
            int _4612 = int(_4606.x);
            int _4615 = int(_4606.y);
            int _6108;
            if (_4612 < 0)
            {
                _6108 = _4612 + _1270[_4392].z;
            }
            else
            {
                _6108 = _4612;
            }
            int _6109;
            if (_6108 >= _1270[_4392].z)
            {
                _6109 = _6108 - _1270[_4392].z;
            }
            else
            {
                _6109 = _6108;
            }
            int _4635 = _6109 + 1;
            int _6434 = (_4635 == _1270[_4392].z) ? 0 : _4635;
            int _4650 = min((_4615 + 1), (_1270[_4392].w - 1));
            int _4652 = max(_4615, 0);
            float3 _4705 = float3(_4609.x);
            float3 _4407 = mix(mix(mix(_1208.read(uint2((_1270[_4385].xy + int2(_6102, _4519))), 0).xyz, _1208.read(uint2((_1270[_4385].xy + int2(_6433, _4519))), 0).xyz, _4572), mix(_1208.read(uint2((_1270[_4385].xy + int2(_6102, _4517))), 0).xyz, _1208.read(uint2((_1270[_4385].xy + int2(_6433, _4517))), 0).xyz, _4572), float3(_4476.y)), mix(mix(_1208.read(uint2((_1270[_4392].xy + int2(_6109, _4652))), 0).xyz, _1208.read(uint2((_1270[_4392].xy + int2(_6434, _4652))), 0).xyz, _4705), mix(_1208.read(uint2((_1270[_4392].xy + int2(_6109, _4650))), 0).xyz, _1208.read(uint2((_1270[_4392].xy + int2(_6434, _4650))), 0).xyz, _4705), float3(_4609.y)), float3(_4382 - float(_4385))) * _173._m29.y;
            _6130 = _4407;
            _6123 = fast::max(_6099, float3(0.0)) * _173._m29.y;
            _6115 = _4228.xy;
        }
        else
        {
            float4 _4723 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * _2046) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);
            float _4725 = _4723.x;
            float3 _4760 = mix(_173._m9.xyz, _173._m8.xyz, float3((_6074.y * 0.5) + 0.5)) * _173._m8.w;
            _6130 = mix(mix(_173._m9.xyz, _173._m8.xyz, float3((reflect(-_1827, _6074).y * 0.5) + 0.5)) * _173._m8.w, _4760, float3(_2046));
            _6123 = _4760;
            _6115 = (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_4725 * _4725, exp2((-9.27999973297119140625) * _2067)) * _4725) + _4723.y)) + _4723.zw;
        }
        float3 _2170 = (_2062 * _6115.x) + float3(_6115.y);
        float3 _2186 = ((((((float3(1.0) - _4157) * _2055) + ((_4157 * ((_4164 / ((3.1415927410125732421875 * _4171) * _4171)) * (0.5 / fast::max((_2072 * _4195) + (_2067 * sqrt(((_2072 * _2072) * _4191) + _4164)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875)) * _2072) * _1869) * _6097) + (((((float3(1.0) - _2170) * _2055) * _6123) + (_2170 * _6130)) * _1882);
        float3 _6247;
        if (_173._m13.w > 0.5)
        {
            float2 _4805 = fast::clamp(floor(gl_FragCoord.xy * _173._m12.xy), float2(0.0), _173._m13.xy - float2(1.0));
            uint _4833 = uint((((fast::clamp(floor((log2(fast::max(dot(_173._m11.xyz, in.m_1444) + _173._m11.w, 9.9999999747524270787835121154785e-07)) * _173._m12.z) + _173._m12.w), 0.0, _173._m13.z - 1.0) * _173._m13.y) + _4805.y) * _173._m13.x) + _4805.x);
            uint _4835 = _4833 >> uint(2);
            uint _4837 = _4833 & 3u;
            uint _4841 = _1577._m0[_4835][_4837] & 65535u;
            uint _4843 = _1577._m0[_4835][_4837] >> uint(16);
            float3 _6202;
            _6202 = _2186;
            float3 _2286;
            spvUnsafeArray<float2, 3> _5251;
            spvUnsafeArray<float2, 3> _5252;
            spvUnsafeArray<float2, 3> _5464;
            spvUnsafeArray<float2, 3> _5465;
            for (uint _6131 = _4841; _6131 < (_4841 + _4843); _6202 = _2286, _6131++)
            {
                uint _4849 = _6131 / 3u;
                uint _4862 = (_1599._m0[_4849 >> uint(2)][_4849 & 3u] >> ((_6131 - (_4849 * 3u)) * 10u)) & 1023u;
                float3 _4879 = _1436._m0[_4862].xyz - in.m_1444;
                float _4882 = dot(_4879, _4879);
                float _4886 = _4882 * _1436._m0[_4862].w;
                float _4891 = fast::clamp(1.0 - (_4886 * _4886), 0.0, 1.0);
                float3 _4896 = _4879 * rsqrt(fast::max(_4882, 9.9999999392252902907785028219223e-09));
                float _4914 = fast::clamp((dot(-_4896, _1480._m0[_4862].xyz) * _1472._m0[_4862].w) + _1480._m0[_4862].w, 0.0, 1.0);
                float3 _4927 = _1472._m0[_4862].xyz * ((((_4891 * _4891) * _4914) * _4914) / fast::max(_4882, 9.9999997473787516355514526367188e-05));
                float3 _6200;
                if (_1843)
                {
                    float _6158;
                    do
                    {
                        uint _4963 = uint(_173._m21.z);
                        if (_4862 < _4963)
                        {
                            float _4985 = _173._m26[_4862].z * fast::max((_173._m15[_4862] * float4(in.m_1444, 1.0)).w, 0.0);
                            float4 _5009 = _173._m15[_4862] * float4((in.m_1444 + (_1838 * (_4985 * _173._m25.x))) + (_4896 * (_4985 * _173._m25.y)), 1.0);
                            float _5011 = _5009.w;
                            if (_5011 <= 0.0)
                            {
                                _6158 = 1.0;
                                break;
                            }
                            float3 _5020 = _5009.xyz / float3(_5011);
                            float _5022 = _5020.x;
                            bool _5023 = _5022 < 0.0;
                            bool _5030;
                            if (!_5023)
                            {
                                _5030 = _5022 > 1.0;
                            }
                            else
                            {
                                _5030 = _5023;
                            }
                            bool _5037;
                            if (!_5030)
                            {
                                _5037 = _5020.y < 0.0;
                            }
                            else
                            {
                                _5037 = _5030;
                            }
                            bool _5044;
                            if (!_5037)
                            {
                                _5044 = _5020.y > 1.0;
                            }
                            else
                            {
                                _5044 = _5037;
                            }
                            bool _5051;
                            if (!_5044)
                            {
                                _5051 = _5020.z > 1.0;
                            }
                            else
                            {
                                _5051 = _5044;
                            }
                            if (_5051)
                            {
                                _6158 = 1.0;
                                break;
                            }
                            float _5057 = _5020.z;
                            float2 _5223 = _173._m22.xy * 0.5;
                            float2 _5228 = _173._m26[_4862].xy + (_5020.xy * _173._m23.zw);
                            float4 _5241 = float4(_173._m26[_4862].xy + _5223, (_173._m26[_4862].xy + _173._m23.zw) - _5223);
                            float _6157;
                            do
                            {
                                int _5267 = int(_173._m22.z);
                                if (_5267 <= 0)
                                {
                                    float2 _5277 = fast::clamp(_5228, _5241.xy, _5241.zw);
                                    _6157 = spvDepthCast(_193).sample_compare(_193Smplr, float3(_5277, _5057).xy, _5057);
                                    break;
                                }
                                float2 _5290 = (_5228 / _173._m22.xy) + float2(0.5);
                                float2 _5291 = floor(_5290);
                                float2 _5296 = _5290 - _5291;
                                float2 _5299 = _5291 - float2(0.5);
                                bool _5303 = _5267 == 1;
                                if (_5303)
                                {
                                    float2 _5306 = _5296 * 2.0;
                                    _5251[0] = float2(3.0) - _5306;
                                    _5251[1] = float2(1.0) + _5306;
                                    _5252[0] = ((float2(2.0) - _5296) / _5251[0]) - float2(1.0);
                                    _5252[1] = (_5296 / _5251[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _5333 = _5296 * 3.0;
                                    _5251[0] = float2(4.0) - _5333;
                                    _5251[1] = float2(7.0);
                                    _5251[2] = float2(1.0) + _5333;
                                    _5252[0] = ((float2(3.0) - (_5296 * 2.0)) / _5251[0]) - float2(2.0);
                                    _5252[1] = (float2(3.0) + _5296) / _5251[1];
                                    _5252[2] = (_5296 / _5251[2]) + float2(2.0);
                                }
                                int _6436 = _5303 ? 2 : 3;
                                int _6147;
                                float _6150;
                                _6150 = 0.0;
                                _6147 = 0;
                                float _6156;
                                for (; _6147 < _6436; _6150 = _6156, _6147++)
                                {
                                    _6156 = _6150;
                                    for (int _6153 = 0; _6153 < _6436; )
                                    {
                                        _6156 += ((_5251[_6153].x * _5251[_6147].y) * spvDepthCast(_193).sample_compare(_193Smplr, float3(fast::clamp(_173._m22.xy * (_5299 + float2(_5252[_6153].x, _5252[_6147].y)), _5241.xy, _5241.zw), _5057).xy, _5057));
                                        _6153++;
                                        continue;
                                    }
                                }
                                _6157 = _6150 * (_5303 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _6158 = _6157;
                            break;
                        }
                        uint _5067 = _4862 - _4963;
                        if (_5067 >= uint(_173._m21.w))
                        {
                            _6158 = 1.0;
                            break;
                        }
                        float _5088 = _173._m27[_5067].w * length(in.m_1444 - _173._m27[_5067].xyz);
                        float3 _5106 = ((in.m_1444 + (_1838 * (_5088 * _173._m25.x))) + (_4896 * (_5088 * _173._m25.y))) - _173._m27[_5067].xyz;
                        float3 _5108 = abs(_5106);
                        float _5110 = _5108.x;
                        float _5112 = _5108.y;
                        bool _5113 = _5110 >= _5112;
                        bool _5121;
                        if (_5113)
                        {
                            _5121 = _5110 >= _5108.z;
                        }
                        else
                        {
                            _5121 = _5113;
                        }
                        float _6132;
                        int _6134;
                        if (_5121)
                        {
                            _6134 = (_5106.x > 0.0) ? 0 : 1;
                            _6132 = _5110;
                        }
                        else
                        {
                            float _5133 = _5108.z;
                            bool _5134 = _5112 >= _5133;
                            int _6135;
                            if (_5134)
                            {
                                _6135 = (_5106.y > 0.0) ? 2 : 3;
                            }
                            else
                            {
                                _6135 = (_5106.z > 0.0) ? 4 : 5;
                            }
                            _6134 = _6135;
                            _6132 = _5134 ? _5112 : _5133;
                        }
                        if (_6132 <= 0.0)
                        {
                            _6158 = 1.0;
                            break;
                        }
                        float2 _5171 = float2(dot(_5106, _851[_6134]), dot(_5106, _860[_6134])) / float2(_6132 * _173._m24.z);
                        float _5178 = _173._m28[_5067].z + (_173._m28[_5067].w / _6132);
                        if (_5178 > 1.0)
                        {
                            _6158 = 1.0;
                            break;
                        }
                        float2 _5196 = _173._m28[_5067].xy + (float2(float(spvSMod(_6134, 3)), float(_6134 / 3)) * _173._m24.xy);
                        float2 _5436 = _173._m22.xy * 0.5;
                        float2 _5441 = _5196 + (float2(0.5 + (0.5 * _5171.x), 0.5 - (0.5 * _5171.y)) * _173._m24.xy);
                        float4 _5454 = float4(_5196 + _5436, (_5196 + _173._m24.xy) - _5436);
                        float _6146;
                        do
                        {
                            int _5480 = int(_173._m22.z);
                            if (_5480 <= 0)
                            {
                                _6146 = spvDepthCast(_193).sample_compare(_193Smplr, float3(fast::clamp(_5441, _5454.xy, _5454.zw), _5178).xy, _5178);
                                break;
                            }
                            float2 _5503 = (_5441 / _173._m22.xy) + float2(0.5);
                            float2 _5504 = floor(_5503);
                            float2 _5509 = _5503 - _5504;
                            float2 _5512 = _5504 - float2(0.5);
                            bool _5516 = _5480 == 1;
                            if (_5516)
                            {
                                float2 _5519 = _5509 * 2.0;
                                _5464[0] = float2(3.0) - _5519;
                                _5464[1] = float2(1.0) + _5519;
                                _5465[0] = ((float2(2.0) - _5509) / _5464[0]) - float2(1.0);
                                _5465[1] = (_5509 / _5464[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _5546 = _5509 * 3.0;
                                _5464[0] = float2(4.0) - _5546;
                                _5464[1] = float2(7.0);
                                _5464[2] = float2(1.0) + _5546;
                                _5465[0] = ((float2(3.0) - (_5509 * 2.0)) / _5464[0]) - float2(2.0);
                                _5465[1] = (float2(3.0) + _5509) / _5464[1];
                                _5465[2] = (_5509 / _5464[2]) + float2(2.0);
                            }
                            int _6439 = _5516 ? 2 : 3;
                            int _6136;
                            float _6139;
                            _6139 = 0.0;
                            _6136 = 0;
                            float _6145;
                            for (; _6136 < _6439; _6139 = _6145, _6136++)
                            {
                                _6145 = _6139;
                                for (int _6142 = 0; _6142 < _6439; )
                                {
                                    _6145 += ((_5464[_6142].x * _5464[_6136].y) * spvDepthCast(_193).sample_compare(_193Smplr, float3(fast::clamp(_173._m22.xy * (_5512 + float2(_5465[_6142].x, _5465[_6136].y)), _5454.xy, _5454.zw), _5178).xy, _5178));
                                    _6142++;
                                    continue;
                                }
                            }
                            _6146 = _6139 * (_5516 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _6158 = _6146;
                        break;
                    } while(false);
                    _6200 = _4927 * _6158;
                }
                else
                {
                    _6200 = _4927;
                }
                float3 _2238 = fast::normalize(_4896 + _1827);
                float _2243 = fast::clamp(dot(_6074, _4896), 0.0, 1.0);
                float _2248 = fast::clamp(dot(_6074, _2238), 0.0, 1.0);
                float3 _5651 = _2062 + (_4154 * powr(1.0 - fast::clamp(dot(_1827, _2238), 0.0, 1.0), 5.0));
                float _5665 = ((_2248 * _2248) * _4169) + 1.0;
                _2286 = _6202 + (((((float3(1.0) - _5651) * _2055) + ((_5651 * ((_4164 / ((3.1415927410125732421875 * _5665) * _5665)) * (0.5 / fast::max((_2243 * _4195) + (_2067 * sqrt(((_2243 * _2243) * _4191) + _4164)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875)) * _2243) * _6200);
            }
            _6247 = _6202;
        }
        else
        {
            _6247 = _2186;
        }
        _6244 = _6247;
    }
    float4 _2303 = _2298.sample(_1210, _1639);
    float _2321 = -length(_1826);
    float _6281;
    if (_173._m9.w != 0.0)
    {
        float _2345 = _173._m9.w * (in.m_1444 - _173._m6.xyz).y;
        float _6278;
        if (abs(_2345) < 9.9999997473787516355514526367188e-05)
        {
            _6278 = 1.0 - (0.5 * _2345);
        }
        else
        {
            _6278 = (1.0 - exp(fast::min(-_2345, 60.0))) / _2345;
        }
        _6281 = 1.0 - exp((_2321 * (_173._m7.w * exp(fast::min((-_173._m9.w) * (_173._m6.y - _173._m6.w), 30.0)))) * _6278);
    }
    else
    {
        _6281 = 1.0 - exp(_2321 * _173._m7.w);
    }
    out.m_2390 = float4(mix(mix(_6244, _6072, float3(_1620._m1.y)) + ((_1620._m5.xyz * _2303.xyz) * (float3(1.0) + in.m_1840.yzw)), _173._m7.xyz, float3(_6281)), (in.m_1648.w * _1620._m0.w) * _1646.w);
    float2 _6282;
    do
    {
        if (in.m_2406.w <= 0.0)
        {
            _6282 = float2(0.0);
            break;
        }
        _6282 = ((in.m_2406.xy / float2(in.m_2406.w)) - (in.m_2405.xy / float2(in.m_2405.w))) * float2(0.5, -0.5);
        break;
    } while(false);
    out.m_2404 = _6282;
    return out;
}

