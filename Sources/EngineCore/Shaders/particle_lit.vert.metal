// Generated from particle_lit.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 86dab7c4c55cccfe
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
    float2 m_1159 [[user(locn0)]];
    float4 m_1162 [[user(locn1)]];
    float4 m_1164 [[user(locn2)]];
    float m_1167 [[user(locn3)]];
    float4 gl_Position [[position]];
};

vertex vertex_main_out vertex_main(constant _794& _796 [[buffer(2)]], constant _703& _705 [[buffer(3)]], constant _738& _740 [[buffer(4)]], constant _746& _748 [[buffer(5)]], constant _649& _651 [[buffer(6)]], constant _683& _685 [[buffer(7)]], constant _175& _177 [[buffer(15)]], const device _939& _941 [[buffer(20)]], const device _943& _945 [[buffer(21)]], texture2d<float> _398 [[texture(3)]], texture2d<float> _213 [[texture(6)]], sampler _217 [[sampler(1)]], uint gl_InstanceIndex [[instance_id]], uint gl_VertexIndex [[vertex_id]])
{
    vertex_main_out out = {};
    float _983 = fast::clamp(_941._m0[_945._m0[int(gl_InstanceIndex)]]._m0.w / fast::max(_941._m0[_945._m0[int(gl_InstanceIndex)]]._m1.w, 9.9999997473787516355514526367188e-06), 0.0, 1.0);
    int _1376 = int(_796._m7.y);
    float _2436;
    _2436 = _796._m4.x;
    float _2437;
    for (int _2433 = 1; _2433 < 4; _2433++, _2436 = _2437)
    {
        if (_2433 >= _1376)
        {
            break;
        }
        int _1390 = _2433 - 1;
        if (_983 > _796._m5[_1390])
        {
            _2437 = mix(_796._m4[_1390], _796._m4[_2433], fast::clamp((_983 - _796._m5[_1390]) / fast::max(_796._m5[_2433] - _796._m5[_1390], 9.9999997473787516355514526367188e-06), 0.0, 1.0));
        }
        else
        {
            _2437 = _2436;
        }
    }
    float3 _1000 = _796._m1.xyz - _941._m0[_945._m0[int(gl_InstanceIndex)]]._m0.xyz;
    float3 _2438;
    if (dot(_1000, _1000) > 1.0000000133514319600180897396058e-10)
    {
        _2438 = fast::normalize(_1000);
    }
    else
    {
        _2438 = float3(0.0, 0.0, 1.0);
    }
    float3 _1029 = fast::normalize(cross(select(float3(1.0, 0.0, 0.0), float3(0.0, 1.0, 0.0), bool3(abs(_2438.y) < 0.999000012874603271484375)), _2438));
    float3 _1033 = cross(_2438, _1029);
    float3 _1047 = _941._m0[_945._m0[int(gl_InstanceIndex)]]._m1.xyz - (_2438 * dot(_941._m0[_945._m0[int(gl_InstanceIndex)]]._m1.xyz, _2438));
    float _1050 = length(_1047);
    float3 _2439;
    float3 _2441;
    float _2443;
    float _2445;
    if ((_796._m6.x > 0.0) && (_1050 > 9.9999997473787516355514526367188e-05))
    {
        float3 _1062 = _1047 / float3(_1050);
        float _2444;
        float _2446;
        if (_796._m6.w > 0.5)
        {
            _2446 = (0.5 * _796._m6.x) * _1050;
            _2444 = 1.0;
        }
        else
        {
            _2446 = 0.0;
            _2444 = 1.0 + (_796._m6.x * _1050);
        }
        _2445 = _2446;
        _2443 = _2444;
        _2441 = _1062;
        _2439 = cross(_1062, _2438);
    }
    else
    {
        float _1091 = _941._m0[_945._m0[int(gl_InstanceIndex)]]._m2.y + (_941._m0[_945._m0[int(gl_InstanceIndex)]]._m2.z * _941._m0[_945._m0[int(gl_InstanceIndex)]]._m0.w);
        float _1094 = cos(_1091);
        float _1097 = sin(_1091);
        _2445 = 0.0;
        _2443 = 1.0;
        _2441 = (_1033 * _1094) - (_1029 * _1097);
        _2439 = (_1029 * _1094) + (_1033 * _1097);
    }
    float3 _1136 = (_941._m0[_945._m0[int(gl_InstanceIndex)]]._m0.xyz + (((_2439 * _969[int(gl_VertexIndex)].x) + ((_2441 * _969[int(gl_VertexIndex)].y) * _2443)) * (_941._m0[_945._m0[int(gl_InstanceIndex)]]._m2.x * _2436))) + (_2441 * (_969[int(gl_VertexIndex)].y * _2445));
    int _1432 = int(_796._m7.x);
    float4 _2450;
    _2450 = _796._m2[0];
    float4 _2451;
    for (int _2447 = 1; _2447 < 4; _2447++, _2450 = _2451)
    {
        if (_2447 >= _1432)
        {
            break;
        }
        int _1446 = _2447 - 1;
        if (_983 > _796._m3[_1446])
        {
            _2451 = mix(_796._m2[_1446], _796._m2[_2447], float4(fast::clamp((_983 - _796._m3[_1446]) / fast::max(_796._m3[_2447] - _796._m3[_1446], 9.9999997473787516355514526367188e-06), 0.0, 1.0)));
        }
        else
        {
            _2451 = _2450;
        }
    }
    float3 _1151 = _2450.xyz * (_796._m6.y * mix(1.0, _941._m0[_945._m0[int(gl_InstanceIndex)]]._m2.w, _796._m6.z));
    float4 _2373 = _2450;
    _2373.x = _1151.x;
    _2373.y = _1151.y;
    _2373.z = _1151.z;
    out.m_1159 = _969[int(gl_VertexIndex)];
    out.m_1162 = _2373;
    out.m_1164 = float4(0.0);
    out.m_1167 = 0.0;
    if (_796._m9.z > 0.5)
    {
        bool _1179 = _796._m8.w > 0.0;
        float _2452;
        if (_1179)
        {
            _2452 = _941._m0[_945._m0[int(gl_InstanceIndex)]]._m0.w * _796._m8.w;
        }
        else
        {
            _2452 = _983 * _796._m8.z;
        }
        bool _1195 = _796._m9.x > 0.5;
        float _2454;
        if (_1195)
        {
            _2454 = _2452 + floor(_941._m0[_945._m0[int(gl_InstanceIndex)]]._m2.w * _796._m8.z);
        }
        else
        {
            _2454 = _2452;
        }
        float _1218 = floor(_2454);
        float _2455;
        if (_796._m9.y > 0.5)
        {
            _2455 = _2454 - _1218;
        }
        else
        {
            _2455 = 0.0;
        }
        out.m_1167 = _2455;
        float _1232 = _1218 + 1.0;
        float _2457;
        float _2458;
        if ((!_1179) ? _1195 : _1179)
        {
            _2458 = mod(_1232, _796._m8.z);
            _2457 = mod(_1218, _796._m8.z);
        }
        else
        {
            float _1245 = _796._m8.z - 1.0;
            _2458 = fast::min(_1232, _1245);
            _2457 = fast::min(_1218, _1245);
        }
        float2 _1260 = float2((_969[int(gl_VertexIndex)].x * 0.5) + 0.5, 0.5 - (_969[int(gl_VertexIndex)].y * 0.5));
        out.m_1164 = float4((float2(mod(_2457, _796._m8.x), floor(_2457 / _796._m8.x)) + _1260) / _796._m8.xy, (float2(mod(_2458, _796._m8.x), floor(_2458 / _796._m8.x)) + _1260) / _796._m8.xy);
    }
    float4 _1286 = float4(_1136, 1.0);
    out.gl_Position = _796._m0 * _1286;
    float3 _1294 = _796._m1.xyz - _1136;
    float3 _2470;
    if (dot(_1294, _1294) > 1.0000000133514319600180897396058e-10)
    {
        _2470 = fast::normalize(_1294);
    }
    else
    {
        _2470 = _2438;
    }
    float3 _2473;
    do
    {
        if (_177._m29.x > 0.5)
        {
            float _1843 = (_177._m29.z * _2470.x) - (_177._m29.w * _2470.z);
            float _1856 = (_177._m29.w * _2470.x) + (_177._m29.z * _2470.z);
            float _1874 = 1.09254801273345947265625 * _1843;
            spvUnsafeArray<float, 9> _2348 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _2470.y, 0.48860299587249755859375 * _1856, 0.48860299587249755859375 * _1843, _1874 * _2470.y, (1.09254801273345947265625 * _2470.y) * _1856, 0.3153919875621795654296875 * (((3.0 * _1856) * _1856) - 1.0), _1874 * _1856, 0.546274006366729736328125 * ((_1843 * _1843) - (_2470.y * _2470.y)) });
            spvUnsafeArray<float, 9> _1765 = _2348;
            float3 _2472;
            _2472 = float3(0.0);
            for (int _2471 = 0; _2471 < 9; )
            {
                _2472 += (_213.read(uint2((int2(496, 256) + int2(_2471, 0))), 0).xyz * _1765[_2471]);
                _2471++;
                continue;
            }
            _2473 = fast::max(_2472, float3(0.0)) * _177._m29.y;
            break;
        }
        _2473 = mix(_177._m9.xyz, _177._m8.xyz, float3((_2470.y * 0.5) + 0.5)) * _177._m8.w;
        break;
    } while(false);
    float _2488;
    if ((_177._m5.w > 0.5) && (_796._m10.w > 0.5))
    {
        float _2487;
        do
        {
            int _1933 = int(_177._m21.x);
            float _1941 = dot(_177._m20.xyz, _1136) + _177._m20.w;
            int _2474;
            _2474 = 0;
            for (;;)
            {
                bool _1947 = _2474 < (_1933 - 1);
                bool _1955;
                if (_1947)
                {
                    _1955 = _1941 > _177._m16[_2474];
                }
                else
                {
                    _1955 = _1947;
                }
                if (_1955)
                {
                    _2474++;
                    continue;
                }
                else
                {
                    break;
                }
            }
            if (_1941 > _177._m16[_2474])
            {
                _2487 = 1.0;
                break;
            }
            float _2477;
            do
            {
                float4 _2031 = _177._m14[_2474] * _1286;
                float _2034 = _2031.x;
                bool _2035 = _2034 < 0.0;
                bool _2042;
                if (!_2035)
                {
                    _2042 = _2034 > 1.0;
                }
                else
                {
                    _2042 = _2035;
                }
                bool _2049;
                if (!_2042)
                {
                    _2049 = _2031.y < 0.0;
                }
                else
                {
                    _2049 = _2042;
                }
                bool _2056;
                if (!_2049)
                {
                    _2056 = _2031.y > 1.0;
                }
                else
                {
                    _2056 = _2049;
                }
                if (_2056)
                {
                    _2477 = 1.0;
                    break;
                }
                float2 _2063 = float2(1.0) / _177._m22.xy;
                float2 _2074 = float2(float(_2474 & 1), float(_2474 >> 1)) * _177._m23.xy;
                int2 _2080 = int2((_2074 * _2063) + float2(0.5));
                int2 _2092 = int2(((_2074 + _177._m23.xy) * _2063) + float2(0.5)) - int2(1);
                float _2099 = fast::min(_2031.z, 1.0) - _177._m19[_2474];
                float2 _2111 = ((_2074 + (_2031.xy * _177._m23.xy)) * _2063) - float2(0.5);
                float2 _2113 = floor(_2111);
                float2 _2116 = _2111 - _2113;
                spvUnsafeArray<float, 4> _2019;
                for (int _2476 = 0; _2476 < 4; )
                {
                    _2019[_2476] = float(_2099 <= _398.read(uint2(clamp(int2(_2113) + int2(_2476 & 1, _2476 >> 1), _2080, _2092)), 0).x);
                    _2476++;
                    continue;
                }
                float _2154 = _2116.x;
                _2477 = mix(mix(_2019[0], _2019[1], _2154), mix(_2019[2], _2019[3], _2154), _2116.y);
                break;
            } while(false);
            float _2486;
            if (_1941 > _177._m17[_2474])
            {
                int _1989 = _2474 + 1;
                float _2485;
                if (_1989 < _1933)
                {
                    float _2484;
                    do
                    {
                        float4 _2193 = _177._m14[_1989] * _1286;
                        float _2196 = _2193.x;
                        bool _2197 = _2196 < 0.0;
                        bool _2204;
                        if (!_2197)
                        {
                            _2204 = _2196 > 1.0;
                        }
                        else
                        {
                            _2204 = _2197;
                        }
                        bool _2211;
                        if (!_2204)
                        {
                            _2211 = _2193.y < 0.0;
                        }
                        else
                        {
                            _2211 = _2204;
                        }
                        bool _2218;
                        if (!_2211)
                        {
                            _2218 = _2193.y > 1.0;
                        }
                        else
                        {
                            _2218 = _2211;
                        }
                        if (_2218)
                        {
                            _2484 = 1.0;
                            break;
                        }
                        float2 _2225 = float2(1.0) / _177._m22.xy;
                        float2 _2236 = float2(float(_1989 & 1), float(_1989 >> 1)) * _177._m23.xy;
                        int2 _2242 = int2((_2236 * _2225) + float2(0.5));
                        int2 _2254 = int2(((_2236 + _177._m23.xy) * _2225) + float2(0.5)) - int2(1);
                        float _2261 = fast::min(_2193.z, 1.0) - _177._m19[_1989];
                        float2 _2273 = ((_2236 + (_2193.xy * _177._m23.xy)) * _2225) - float2(0.5);
                        float2 _2275 = floor(_2273);
                        float2 _2278 = _2273 - _2275;
                        spvUnsafeArray<float, 4> _2181;
                        for (int _2483 = 0; _2483 < 4; )
                        {
                            _2181[_2483] = float(_2261 <= _398.read(uint2(clamp(int2(_2275) + int2(_2483 & 1, _2483 >> 1), _2242, _2254)), 0).x);
                            _2483++;
                            continue;
                        }
                        float _2316 = _2278.x;
                        _2484 = mix(mix(_2181[0], _2181[1], _2316), mix(_2181[2], _2181[3], _2316), _2278.y);
                        break;
                    } while(false);
                    _2485 = _2484;
                }
                else
                {
                    _2485 = 1.0;
                }
                _2486 = mix(_2477, _2485, (_1941 - _177._m17[_2474]) / (_177._m16[_2474] - _177._m17[_2474]));
            }
            else
            {
                _2486 = _2477;
            }
            _2487 = _2486;
            break;
        } while(false);
        _2488 = _2487;
    }
    else
    {
        _2488 = 1.0;
    }
    float3 _1584 = _2473 + (((_177._m5.xyz * _177._m4.w) * ((dot(_2470, fast::normalize(_177._m4.xyz)) * 0.5) + 0.5)) * _2488);
    bool _1587 = _177._m13.w > 0.5;
    bool _1593;
    if (_1587)
    {
        _1593 = out.gl_Position.w > 0.0;
    }
    else
    {
        _1593 = _1587;
    }
    float3 _2506;
    if (_1593)
    {
        float2 _1629 = fast::clamp(floor(float2(((out.gl_Position.x / out.gl_Position.w) * 0.5) + 0.5, 0.5 - ((out.gl_Position.y / out.gl_Position.w) * 0.5)) * _177._m13.xy), float2(0.0), _177._m13.xy - float2(1.0));
        uint _1657 = uint((((fast::clamp(floor((log2(fast::max(dot(_177._m11.xyz, _1136) + _177._m11.w, 9.9999999747524270787835121154785e-07)) * _177._m12.z) + _177._m12.w), 0.0, _177._m13.z - 1.0) * _177._m13.y) + _1629.y) * _177._m13.x) + _1629.x);
        uint _1659 = _1657 >> uint(2);
        uint _1661 = _1657 & 3u;
        uint _1665 = _651._m0[_1659][_1661] & 65535u;
        uint _1667 = _651._m0[_1659][_1661] >> uint(16);
        float3 _2508;
        _2508 = _1584;
        for (uint _2505 = _1665; _2505 < (_1665 + _1667); )
        {
            uint _1678 = _2505 / 3u;
            uint _1691 = (_685._m0[_1678 >> uint(2)][_1678 & 3u] >> ((_2505 - (_1678 * 3u)) * 10u)) & 1023u;
            float3 _1698 = _705._m0[_1691].xyz - _1136;
            float _1701 = dot(_1698, _1698);
            float _1705 = _1701 * _705._m0[_1691].w;
            float _1710 = fast::clamp(1.0 - (_1705 * _1705), 0.0, 1.0);
            float3 _1715 = _1698 * rsqrt(fast::max(_1701, 9.9999999392252902907785028219223e-09));
            float _1733 = fast::clamp((dot(-_1715, _748._m0[_1691].xyz) * _740._m0[_1691].w) + _748._m0[_1691].w, 0.0, 1.0);
            _2508 += ((_740._m0[_1691].xyz * ((((_1710 * _1710) * _1733) * _1733) / fast::max(_1701, 9.9999997473787516355514526367188e-05))) * ((dot(_2470, _1715) * 0.5) + 0.5));
            _2505++;
            continue;
        }
        _2506 = _2508;
    }
    else
    {
        _2506 = _1584;
    }
    float4 _1319 = out.m_1162;
    float3 _1321 = _1319.xyz * _2506;
    out.m_1162.x = _1321.x;
    out.m_1162.y = _1321.y;
    out.m_1162.z = _1321.z;
    out.gl_Position.y = -out.gl_Position.y;
    out.gl_Position.y = -(out.gl_Position.y);    // Invert Y-axis for Metal
    return out;
}

