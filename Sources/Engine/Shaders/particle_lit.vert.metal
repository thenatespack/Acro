// Generated from particle_lit.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: f1ef04471ec35dbd
// glsl-fnv1a64: e72c8f15689d6942

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

struct _175
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

struct _649
{
    uint4 _m0[1024];
};

struct _683
{
    uint4 _m0[1024];
};

struct _703
{
    float4 _m0[1024];
};

struct _738
{
    float4 _m0[1024];
};

struct _746
{
    float4 _m0[1024];
};

struct _794
{
    float4x4 _m0;
    float4 _m1;
    float4 _m2[4];
    float4 _m3;
    float4 _m4;
    float4 _m5;
    float4 _m6;
    float4 _m7;
    float4 _m8;
    float4 _m9;
    float4 _m10;
};

struct _937
{
    float4 _m0;
    float4 _m1;
    float4 _m2;
};

struct _939
{
    _937 _m0[1];
};

struct _943
{
    uint _m0[1];
};

constant spvUnsafeArray<float2, 6> _969 = spvUnsafeArray<float2, 6>({ float2(-1.0), float2(1.0, -1.0), float2(1.0), float2(-1.0), float2(1.0), float2(-1.0, 1.0) });

struct vertex_main_out
{
    float2 m_1140 [[user(locn0)]];
    float4 m_1143 [[user(locn1)]];
    float4 m_1145 [[user(locn2)]];
    float m_1148 [[user(locn3)]];
    float4 gl_Position [[position]];
};

vertex vertex_main_out vertex_main(constant _794& _796 [[buffer(2)]], constant _703& _705 [[buffer(3)]], constant _738& _740 [[buffer(4)]], constant _746& _748 [[buffer(5)]], constant _649& _651 [[buffer(6)]], constant _683& _685 [[buffer(7)]], constant _175& _177 [[buffer(15)]], const device _939& _941 [[buffer(20)]], const device _943& _945 [[buffer(21)]], texture2d<float> _398 [[texture(3)]], texture2d<float> _213 [[texture(6)]], sampler _217 [[sampler(1)]], uint gl_InstanceIndex [[instance_id]], uint gl_VertexIndex [[vertex_id]])
{
    vertex_main_out out = {};
    float _983 = fast::clamp(_941._m0[_945._m0[int(gl_InstanceIndex)]]._m0.w / fast::max(_941._m0[_945._m0[int(gl_InstanceIndex)]]._m1.w, 9.9999997473787516355514526367188e-06), 0.0, 1.0);
    int _1357 = int(_796._m7.y);
    float _2416;
    _2416 = _796._m4.x;
    float _2417;
    for (int _2413 = 1; _2413 < 4; _2413++, _2416 = _2417)
    {
        if (_2413 >= _1357)
        {
            break;
        }
        int _1371 = _2413 - 1;
        if (_983 > _796._m5[_1371])
        {
            _2417 = mix(_796._m4[_1371], _796._m4[_2413], fast::clamp((_983 - _796._m5[_1371]) / fast::max(_796._m5[_2413] - _796._m5[_1371], 9.9999997473787516355514526367188e-06), 0.0, 1.0));
        }
        else
        {
            _2417 = _2416;
        }
    }
    float3 _1000 = _796._m1.xyz - _941._m0[_945._m0[int(gl_InstanceIndex)]]._m0.xyz;
    float3 _2418;
    if (dot(_1000, _1000) > 1.0000000133514319600180897396058e-10)
    {
        _2418 = fast::normalize(_1000);
    }
    else
    {
        _2418 = float3(0.0, 0.0, 1.0);
    }
    float3 _1029 = fast::normalize(cross(select(float3(1.0, 0.0, 0.0), float3(0.0, 1.0, 0.0), bool3(abs(_2418.y) < 0.999000012874603271484375)), _2418));
    float3 _1033 = cross(_2418, _1029);
    float3 _1046 = _941._m0[_945._m0[int(gl_InstanceIndex)]]._m1.xyz - (_2418 * dot(_941._m0[_945._m0[int(gl_InstanceIndex)]]._m1.xyz, _2418));
    float _1049 = length(_1046);
    float3 _2419;
    float3 _2420;
    float _2421;
    if ((_796._m6.x > 0.0) && (_1049 > 9.9999997473787516355514526367188e-05))
    {
        float3 _1061 = _1046 / float3(_1049);
        _2421 = 1.0 + (_796._m6.x * _1049);
        _2420 = _1061;
        _2419 = cross(_1061, _2418);
    }
    else
    {
        float _1079 = _941._m0[_945._m0[int(gl_InstanceIndex)]]._m2.y + (_941._m0[_945._m0[int(gl_InstanceIndex)]]._m2.z * _941._m0[_945._m0[int(gl_InstanceIndex)]]._m0.w);
        float _1082 = cos(_1079);
        float _1085 = sin(_1079);
        _2421 = 1.0;
        _2420 = (_1033 * _1082) - (_1029 * _1085);
        _2419 = (_1029 * _1082) + (_1033 * _1085);
    }
    float3 _1117 = _941._m0[_945._m0[int(gl_InstanceIndex)]]._m0.xyz + (((_2419 * _969[int(gl_VertexIndex)].x) + ((_2420 * _969[int(gl_VertexIndex)].y) * _2421)) * (_941._m0[_945._m0[int(gl_InstanceIndex)]]._m2.x * _2416));
    int _1413 = int(_796._m7.x);
    float4 _2425;
    _2425 = _796._m2[0];
    float4 _2426;
    for (int _2422 = 1; _2422 < 4; _2422++, _2425 = _2426)
    {
        if (_2422 >= _1413)
        {
            break;
        }
        int _1427 = _2422 - 1;
        if (_983 > _796._m3[_1427])
        {
            _2426 = mix(_796._m2[_1427], _796._m2[_2422], float4(fast::clamp((_983 - _796._m3[_1427]) / fast::max(_796._m3[_2422] - _796._m3[_1427], 9.9999997473787516355514526367188e-06), 0.0, 1.0)));
        }
        else
        {
            _2426 = _2425;
        }
    }
    float3 _1132 = _2425.xyz * (_796._m6.y * mix(1.0, _941._m0[_945._m0[int(gl_InstanceIndex)]]._m2.w, _796._m6.z));
    float4 _2353 = _2425;
    _2353.x = _1132.x;
    _2353.y = _1132.y;
    _2353.z = _1132.z;
    out.m_1140 = _969[int(gl_VertexIndex)];
    out.m_1143 = _2353;
    out.m_1145 = float4(0.0);
    out.m_1148 = 0.0;
    if (_796._m9.z > 0.5)
    {
        bool _1160 = _796._m8.w > 0.0;
        float _2427;
        if (_1160)
        {
            _2427 = _941._m0[_945._m0[int(gl_InstanceIndex)]]._m0.w * _796._m8.w;
        }
        else
        {
            _2427 = _983 * _796._m8.z;
        }
        bool _1176 = _796._m9.x > 0.5;
        float _2429;
        if (_1176)
        {
            _2429 = _2427 + floor(_941._m0[_945._m0[int(gl_InstanceIndex)]]._m2.w * _796._m8.z);
        }
        else
        {
            _2429 = _2427;
        }
        float _1199 = floor(_2429);
        float _2430;
        if (_796._m9.y > 0.5)
        {
            _2430 = _2429 - _1199;
        }
        else
        {
            _2430 = 0.0;
        }
        out.m_1148 = _2430;
        float _1213 = _1199 + 1.0;
        float _2432;
        float _2433;
        if ((!_1160) ? _1176 : _1160)
        {
            _2433 = mod(_1213, _796._m8.z);
            _2432 = mod(_1199, _796._m8.z);
        }
        else
        {
            float _1226 = _796._m8.z - 1.0;
            _2433 = fast::min(_1213, _1226);
            _2432 = fast::min(_1199, _1226);
        }
        float2 _1241 = float2((_969[int(gl_VertexIndex)].x * 0.5) + 0.5, 0.5 - (_969[int(gl_VertexIndex)].y * 0.5));
        out.m_1145 = float4((float2(mod(_2432, _796._m8.x), floor(_2432 / _796._m8.x)) + _1241) / _796._m8.xy, (float2(mod(_2433, _796._m8.x), floor(_2433 / _796._m8.x)) + _1241) / _796._m8.xy);
    }
    float4 _1267 = float4(_1117, 1.0);
    out.gl_Position = _796._m0 * _1267;
    float3 _1275 = _796._m1.xyz - _1117;
    float3 _2444;
    if (dot(_1275, _1275) > 1.0000000133514319600180897396058e-10)
    {
        _2444 = fast::normalize(_1275);
    }
    else
    {
        _2444 = _2418;
    }
    float3 _2447;
    do
    {
        if (_177._m29.x > 0.5)
        {
            float _1824 = (_177._m29.z * _2444.x) - (_177._m29.w * _2444.z);
            float _1837 = (_177._m29.w * _2444.x) + (_177._m29.z * _2444.z);
            float _1855 = 1.09254801273345947265625 * _1824;
            spvUnsafeArray<float, 9> _2329 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _2444.y, 0.48860299587249755859375 * _1837, 0.48860299587249755859375 * _1824, _1855 * _2444.y, (1.09254801273345947265625 * _2444.y) * _1837, 0.3153919875621795654296875 * (((3.0 * _1837) * _1837) - 1.0), _1855 * _1837, 0.546274006366729736328125 * ((_1824 * _1824) - (_2444.y * _2444.y)) });
            spvUnsafeArray<float, 9> _1746 = _2329;
            float3 _2446;
            _2446 = float3(0.0);
            for (int _2445 = 0; _2445 < 9; )
            {
                _2446 += (_213.read(uint2((int2(496, 256) + int2(_2445, 0))), 0).xyz * _1746[_2445]);
                _2445++;
                continue;
            }
            _2447 = fast::max(_2446, float3(0.0)) * _177._m29.y;
            break;
        }
        _2447 = mix(_177._m9.xyz, _177._m8.xyz, float3((_2444.y * 0.5) + 0.5)) * _177._m8.w;
        break;
    } while(false);
    float _2462;
    if ((_177._m5.w > 0.5) && (_796._m10.w > 0.5))
    {
        float _2461;
        do
        {
            int _1914 = int(_177._m21.x);
            float _1922 = dot(_177._m20.xyz, _1117) + _177._m20.w;
            int _2448;
            _2448 = 0;
            for (;;)
            {
                bool _1928 = _2448 < (_1914 - 1);
                bool _1936;
                if (_1928)
                {
                    _1936 = _1922 > _177._m16[_2448];
                }
                else
                {
                    _1936 = _1928;
                }
                if (_1936)
                {
                    _2448++;
                    continue;
                }
                else
                {
                    break;
                }
            }
            if (_1922 > _177._m16[_2448])
            {
                _2461 = 1.0;
                break;
            }
            float _2451;
            do
            {
                float4 _2012 = _177._m14[_2448] * _1267;
                float _2015 = _2012.x;
                bool _2016 = _2015 < 0.0;
                bool _2023;
                if (!_2016)
                {
                    _2023 = _2015 > 1.0;
                }
                else
                {
                    _2023 = _2016;
                }
                bool _2030;
                if (!_2023)
                {
                    _2030 = _2012.y < 0.0;
                }
                else
                {
                    _2030 = _2023;
                }
                bool _2037;
                if (!_2030)
                {
                    _2037 = _2012.y > 1.0;
                }
                else
                {
                    _2037 = _2030;
                }
                if (_2037)
                {
                    _2451 = 1.0;
                    break;
                }
                float2 _2044 = float2(1.0) / _177._m22.xy;
                float2 _2055 = float2(float(_2448 & 1), float(_2448 >> 1)) * _177._m23.xy;
                int2 _2061 = int2((_2055 * _2044) + float2(0.5));
                int2 _2073 = int2(((_2055 + _177._m23.xy) * _2044) + float2(0.5)) - int2(1);
                float _2080 = fast::min(_2012.z, 1.0) - _177._m19[_2448];
                float2 _2092 = ((_2055 + (_2012.xy * _177._m23.xy)) * _2044) - float2(0.5);
                float2 _2094 = floor(_2092);
                float2 _2097 = _2092 - _2094;
                spvUnsafeArray<float, 4> _2000;
                for (int _2450 = 0; _2450 < 4; )
                {
                    _2000[_2450] = float(_2080 <= _398.read(uint2(clamp(int2(_2094) + int2(_2450 & 1, _2450 >> 1), _2061, _2073)), 0).x);
                    _2450++;
                    continue;
                }
                float _2135 = _2097.x;
                _2451 = mix(mix(_2000[0], _2000[1], _2135), mix(_2000[2], _2000[3], _2135), _2097.y);
                break;
            } while(false);
            float _2460;
            if (_1922 > _177._m17[_2448])
            {
                int _1970 = _2448 + 1;
                float _2459;
                if (_1970 < _1914)
                {
                    float _2458;
                    do
                    {
                        float4 _2174 = _177._m14[_1970] * _1267;
                        float _2177 = _2174.x;
                        bool _2178 = _2177 < 0.0;
                        bool _2185;
                        if (!_2178)
                        {
                            _2185 = _2177 > 1.0;
                        }
                        else
                        {
                            _2185 = _2178;
                        }
                        bool _2192;
                        if (!_2185)
                        {
                            _2192 = _2174.y < 0.0;
                        }
                        else
                        {
                            _2192 = _2185;
                        }
                        bool _2199;
                        if (!_2192)
                        {
                            _2199 = _2174.y > 1.0;
                        }
                        else
                        {
                            _2199 = _2192;
                        }
                        if (_2199)
                        {
                            _2458 = 1.0;
                            break;
                        }
                        float2 _2206 = float2(1.0) / _177._m22.xy;
                        float2 _2217 = float2(float(_1970 & 1), float(_1970 >> 1)) * _177._m23.xy;
                        int2 _2223 = int2((_2217 * _2206) + float2(0.5));
                        int2 _2235 = int2(((_2217 + _177._m23.xy) * _2206) + float2(0.5)) - int2(1);
                        float _2242 = fast::min(_2174.z, 1.0) - _177._m19[_1970];
                        float2 _2254 = ((_2217 + (_2174.xy * _177._m23.xy)) * _2206) - float2(0.5);
                        float2 _2256 = floor(_2254);
                        float2 _2259 = _2254 - _2256;
                        spvUnsafeArray<float, 4> _2162;
                        for (int _2457 = 0; _2457 < 4; )
                        {
                            _2162[_2457] = float(_2242 <= _398.read(uint2(clamp(int2(_2256) + int2(_2457 & 1, _2457 >> 1), _2223, _2235)), 0).x);
                            _2457++;
                            continue;
                        }
                        float _2297 = _2259.x;
                        _2458 = mix(mix(_2162[0], _2162[1], _2297), mix(_2162[2], _2162[3], _2297), _2259.y);
                        break;
                    } while(false);
                    _2459 = _2458;
                }
                else
                {
                    _2459 = 1.0;
                }
                _2460 = mix(_2451, _2459, (_1922 - _177._m17[_2448]) / (_177._m16[_2448] - _177._m17[_2448]));
            }
            else
            {
                _2460 = _2451;
            }
            _2461 = _2460;
            break;
        } while(false);
        _2462 = _2461;
    }
    else
    {
        _2462 = 1.0;
    }
    float3 _1565 = _2447 + (((_177._m5.xyz * _177._m4.w) * ((dot(_2444, fast::normalize(_177._m4.xyz)) * 0.5) + 0.5)) * _2462);
    bool _1568 = _177._m13.w > 0.5;
    bool _1574;
    if (_1568)
    {
        _1574 = out.gl_Position.w > 0.0;
    }
    else
    {
        _1574 = _1568;
    }
    float3 _2480;
    if (_1574)
    {
        float2 _1610 = fast::clamp(floor(float2(((out.gl_Position.x / out.gl_Position.w) * 0.5) + 0.5, 0.5 - ((out.gl_Position.y / out.gl_Position.w) * 0.5)) * _177._m13.xy), float2(0.0), _177._m13.xy - float2(1.0));
        uint _1638 = uint((((fast::clamp(floor((log2(fast::max(dot(_177._m11.xyz, _1117) + _177._m11.w, 9.9999999747524270787835121154785e-07)) * _177._m12.z) + _177._m12.w), 0.0, _177._m13.z - 1.0) * _177._m13.y) + _1610.y) * _177._m13.x) + _1610.x);
        uint _1640 = _1638 >> uint(2);
        uint _1642 = _1638 & 3u;
        uint _1646 = _651._m0[_1640][_1642] & 65535u;
        uint _1648 = _651._m0[_1640][_1642] >> uint(16);
        float3 _2482;
        _2482 = _1565;
        for (uint _2479 = _1646; _2479 < (_1646 + _1648); )
        {
            uint _1659 = _2479 / 3u;
            uint _1672 = (_685._m0[_1659 >> uint(2)][_1659 & 3u] >> ((_2479 - (_1659 * 3u)) * 10u)) & 1023u;
            float3 _1679 = _705._m0[_1672].xyz - _1117;
            float _1682 = dot(_1679, _1679);
            float _1686 = _1682 * _705._m0[_1672].w;
            float _1691 = fast::clamp(1.0 - (_1686 * _1686), 0.0, 1.0);
            float3 _1696 = _1679 * rsqrt(fast::max(_1682, 9.9999999392252902907785028219223e-09));
            float _1714 = fast::clamp((dot(-_1696, _748._m0[_1672].xyz) * _740._m0[_1672].w) + _748._m0[_1672].w, 0.0, 1.0);
            _2482 += ((_740._m0[_1672].xyz * ((((_1691 * _1691) * _1714) * _1714) / fast::max(_1682, 9.9999997473787516355514526367188e-05))) * ((dot(_2444, _1696) * 0.5) + 0.5));
            _2479++;
            continue;
        }
        _2480 = _2482;
    }
    else
    {
        _2480 = _1565;
    }
    float4 _1300 = out.m_1143;
    float3 _1302 = _1300.xyz * _2480;
    out.m_1143.x = _1302.x;
    out.m_1143.y = _1302.y;
    out.m_1143.z = _1302.z;
    out.gl_Position.y = -out.gl_Position.y;
    out.gl_Position.y = -(out.gl_Position.y);    // Invert Y-axis for Metal
    return out;
}

