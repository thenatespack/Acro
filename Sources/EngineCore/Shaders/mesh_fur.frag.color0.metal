// Generated from mesh_fur.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 739f498607fb7b57
// glsl-fnv1a64: ebbc8c74cfa1f850

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

struct _134
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

struct _1056
{
    float4 _m0[1024];
};

struct _1092
{
    float4 _m0[1024];
};

struct _1100
{
    float4 _m0[1024];
};

struct _1197
{
    uint4 _m0[1024];
};

struct _1219
{
    uint4 _m0[1024];
};

struct _1337
{
    float4 _m0[8];
    float4 _m1[8];
};

constant float _4774 = {};

constant spvUnsafeArray<float3, 4> _510 = spvUnsafeArray<float3, 4>({ float3(1.0, 0.449999988079071044921875, 0.449999988079071044921875), float3(0.449999988079071044921875, 1.0, 0.449999988079071044921875), float3(0.5, 0.60000002384185791015625, 1.0), float3(1.0, 1.0, 0.4000000059604644775390625) });
constant spvUnsafeArray<float3, 6> _814 = spvUnsafeArray<float3, 6>({ float3(0.0, 0.0, 1.0), float3(0.0, 0.0, -1.0), float3(-1.0, 0.0, 0.0), float3(-1.0, 0.0, 0.0), float3(-1.0, 0.0, 0.0), float3(1.0, 0.0, 0.0) });
constant spvUnsafeArray<float3, 6> _823 = spvUnsafeArray<float3, 6>({ float3(0.0, 1.0, 0.0), float3(0.0, 1.0, 0.0), float3(0.0, 0.0, -1.0), float3(0.0, 0.0, 1.0), float3(0.0, 1.0, 0.0), float3(0.0, 1.0, 0.0) });

struct fragment_main_out
{
    float4 m_2099 [[color(0)]];
};

struct fragment_main_in
{
    float3 m_1066 [[user(locn0)]];
    float3 m_1764 [[user(locn1)]];
    float2 m_1362 [[user(locn2)]];
    float4 m_1750 [[user(locn3)]];
    float3 m_1382 [[user(locn4)]];
    float4 m_1801 [[user(locn5)]];
    float4 m_2108 [[user(locn6)]];
    float4 m_2109 [[user(locn7)]];
    float4 m_1321 [[user(locn8)]];
    float3 m_1780 [[user(locn9)]];
    float3 m_1404 [[user(locn10)]];
};

fragment fragment_main_out fragment_main(fragment_main_in in [[stage_in]], constant _1337& _1339 [[buffer(2)]], constant _1056& _1058 [[buffer(3)]], constant _1092& _1094 [[buffer(4)]], constant _1100& _1102 [[buffer(5)]], constant _1197& _1199 [[buffer(6)]], constant _1219& _1221 [[buffer(7)]], constant _134& _136 [[buffer(15)]], texture2d<float> _156 [[texture(0)]], texture2d<float> _1357 [[texture(2)]], texture2d<float> _1020 [[texture(6)]], sampler _156Smplr [[sampler(0)]], sampler _1024 [[sampler(1)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])
{
    float2 _2107;
    fragment_main_out out = {};
    bool _1329 = in.m_1321.z > 0.5;
    bool _1333 = in.m_1321.w > 0.5;
    float _4397;
    if (_1339._m1[6].z > 0.5)
    {
        float4 _1364 = _1357.sample(_1024, in.m_1362);
        float _1365 = _1364.x;
        float _4398;
        if (_1339._m1[6].w > 0.5)
        {
            _4398 = 1.0 - _1365;
        }
        else
        {
            _4398 = _1365;
        }
        _4397 = _4398;
    }
    else
    {
        _4397 = 1.0;
    }
    float _4399;
    float _4401;
    float _4586;
    if (_1333)
    {
        if (_4397 < 0.0199999995529651641845703125)
        {
            discard_fragment();
        }
        uint3 _2169 = uint3(int3(floor(in.m_1382 / float3(fast::max(_1339._m1[0].y, 9.9999997473787516355514526367188e-06)))) + int3(1048576));
        uint _2180 = ((_2169.x * 1597334677u) ^ (_2169.y * 3812015801u)) ^ (_2169.z * 2798796415u);
        uint _2186 = (_2180 ^ (_2180 >> uint(15))) * 2246822519u;
        uint _2192 = (_2186 ^ (_2186 >> uint(13))) * 3266489917u;
        uint _2198 = (_2192 ^ (_2192 >> uint(16))) * 668265263u;
        _4586 = 1.0;
        _4401 = 0.0;
        _4399 = (float3(_4774, _4774, float((_2198 ^ (_2198 >> uint(15))) & 65535u)) * float3(1.525902189314365386962890625e-05)).z;
    }
    else
    {
        float _4400;
        float _4404;
        float _4589;
        if (!_1329)
        {
            float _1402 = fast::max(_1339._m1[0].y, 9.9999997473787516355514526367188e-06);
            float3 _1406 = fast::normalize(in.m_1404);
            float3 _4385;
            if (_1339._m1[1].x > 0.0)
            {
                float _1416 = _1402 * 4.0;
                float3 _1422 = floor(in.m_1382 / float3(_1416));
                uint3 _2224 = uint3(int3(_1422 + float3(31.0, 17.0, 5.0)) + int3(1048576));
                uint _2235 = ((_2224.x * 1597334677u) ^ (_2224.y * 3812015801u)) ^ (_2224.z * 2798796415u);
                uint _2241 = (_2235 ^ (_2235 >> uint(15))) * 2246822519u;
                uint _2245 = _2241 ^ (_2241 >> uint(13));
                uint _2247 = _2245 * 3266489917u;
                uint _2251 = _2247 ^ (_2247 >> uint(16));
                uint _2253 = _2251 * 668265263u;
                float3 _1440 = ((_1422 + float3(0.5)) + (((float3(float(_2245 & 65535u), float(_2251 & 65535u), float((_2253 ^ (_2253 >> uint(15))) & 65535u)) * float3(1.525902189314365386962890625e-05)) - float3(0.5)) * 0.60000002384185791015625)) * _1416;
                float3 _1449 = _1440 - (_1406 * dot(_1440 - in.m_1382, _1406));
                _4385 = _1449 + ((in.m_1382 - _1449) / float3(1.0 - fast::min((_1339._m1[1].x * in.m_1321.x) * 0.85000002384185791015625, 0.89999997615814208984375)));
            }
            else
            {
                _4385 = in.m_1382;
            }
            float3 _1473 = floor(_4385 / float3(_1402));
            uint3 _2279 = uint3(int3(_1473) + int3(1048576));
            uint _2290 = ((_2279.x * 1597334677u) ^ (_2279.y * 3812015801u)) ^ (_2279.z * 2798796415u);
            uint _2296 = (_2290 ^ (_2290 >> uint(15))) * 2246822519u;
            uint _2300 = _2296 ^ (_2296 >> uint(13));
            uint _2302 = _2300 * 3266489917u;
            uint _2306 = _2302 ^ (_2302 >> uint(16));
            uint _2308 = _2306 * 668265263u;
            float3 _2324 = float3(float(_2300 & 65535u), float(_2306 & 65535u), float((_2308 ^ (_2308 >> uint(15))) & 65535u)) * float3(1.525902189314365386962890625e-05);
            float3 _1488 = ((_1473 + float3(0.5)) + ((_2324 - float3(0.5)) * 0.5)) * _1402;
            float3 _4386;
            if (abs(_1406.y) < 0.89999997615814208984375)
            {
                _4386 = cross(_1406, float3(0.0, 1.0, 0.0));
            }
            else
            {
                _4386 = cross(_1406, float3(1.0, 0.0, 0.0));
            }
            float3 _1503 = fast::normalize(_4386);
            float3 _4388;
            if (_1339._m1[1].y > 0.0)
            {
                float _1521 = (in.m_1321.x * 12.5659999847412109375) + (_2324.x * 6.28299999237060546875);
                _4388 = _1488 + (((_1503 * cos(_1521)) + (cross(_1406, _1503) * sin(_1521))) * ((_1339._m1[1].y * 0.300000011920928955078125) * _1402));
            }
            else
            {
                _4388 = _1488;
            }
            float3 _4392;
            if (_1339._m1[1].z > 0.0)
            {
                float _1547 = in.m_1321.x * 4.0;
                float _1552 = floor(_1547) * 7.0;
                uint3 _2334 = uint3(int3(_1473 + float3(_1552, 3.0, 11.0)) + int3(1048576));
                uint _2345 = ((_2334.x * 1597334677u) ^ (_2334.y * 3812015801u)) ^ (_2334.z * 2798796415u);
                uint _2351 = (_2345 ^ (_2345 >> uint(15))) * 2246822519u;
                uint _2355 = _2351 ^ (_2351 >> uint(13));
                uint _2357 = _2355 * 3266489917u;
                uint _2361 = _2357 ^ (_2357 >> uint(16));
                uint _2363 = _2361 * 668265263u;
                uint3 _2389 = uint3(int3(_1473 + float3(_1552 + 7.0, 3.0, 11.0)) + int3(1048576));
                uint _2400 = ((_2389.x * 1597334677u) ^ (_2389.y * 3812015801u)) ^ (_2389.z * 2798796415u);
                uint _2406 = (_2400 ^ (_2400 >> uint(15))) * 2246822519u;
                uint _2410 = _2406 ^ (_2406 >> uint(13));
                uint _2412 = _2410 * 3266489917u;
                uint _2416 = _2412 ^ (_2412 >> uint(16));
                uint _2418 = _2416 * 668265263u;
                _4392 = _4388 + ((mix(float3(float(_2355 & 65535u), float(_2361 & 65535u), float((_2363 ^ (_2363 >> uint(15))) & 65535u)) * float3(1.525902189314365386962890625e-05), float3(float(_2410 & 65535u), float(_2416 & 65535u), float((_2418 ^ (_2418 >> uint(15))) & 65535u)) * float3(1.525902189314365386962890625e-05), float3(smoothstep(0.0, 1.0, fract(_1547)))) - float3(0.5)) * (((_1339._m1[1].z * 0.4000000059604644775390625) * _1402) * in.m_1321.x));
            }
            else
            {
                _4392 = _4388;
            }
            float3 _1590 = _4385 - _4392;
            float3 _1597 = _1590 - (_1406 * dot(_1590, _1406));
            float _1607 = (1.0 - (_1339._m1[2].y * _2324.y)) * fast::min(_4397, 1.0);
            if (in.m_1321.x > _1607)
            {
                discard_fragment();
            }
            float _1623 = in.m_1321.x / fast::max(_1607, 0.001000000047497451305389404296875);
            float _1627 = (mix(_1339._m1[0].z, _1339._m1[0].w, _1623) * 0.5) * _1402;
            if (dot(_1597, _1597) > (_1627 * _1627))
            {
                discard_fragment();
            }
            _4589 = 1.0;
            _4404 = _1623;
            _4400 = _2324.z;
        }
        else
        {
            float _1653 = in.m_1362.x * fast::max(_1339._m1[4].w, 1.0);
            uint3 _2444 = uint3(int3(float3(floor(_1653), floor(in.m_1321.y * 65535.0), 7.0)) + int3(1048576));
            uint _2455 = ((_2444.x * 1597334677u) ^ (_2444.y * 3812015801u)) ^ (_2444.z * 2798796415u);
            uint _2461 = (_2455 ^ (_2455 >> uint(15))) * 2246822519u;
            uint _2465 = _2461 ^ (_2461 >> uint(13));
            uint _2467 = _2465 * 3266489917u;
            uint _2471 = _2467 ^ (_2467 >> uint(16));
            uint _2473 = _2471 * 668265263u;
            float3 _2489 = float3(float(_2465 & 65535u), float(_2471 & 65535u), float((_2473 ^ (_2473 >> uint(15))) & 65535u)) * float3(1.525902189314365386962890625e-05);
            float _1683 = 1.0 - (_1339._m1[2].y * _2489.y);
            if (in.m_1321.x > _1683)
            {
                discard_fragment();
            }
            float _1693 = in.m_1321.x / fast::max(_1683, 0.001000000047497451305389404296875);
            float _1700 = mix(_1339._m1[0].z, _1339._m1[0].w, _1693);
            float _1714 = (1.0 - smoothstep(_1700 * 0.2750000059604644775390625, _1700 * 0.5, abs((fract(_1653) - 0.5) + ((_2489.x - 0.5) * 0.300000011920928955078125)))) * (1.0 - smoothstep(0.85000002384185791015625, 1.0, _1693));
            if (_1714 < 0.02999999932944774627685546875)
            {
                discard_fragment();
            }
            _4589 = _1714;
            _4404 = _1693;
            _4400 = _2489.z;
        }
        _4586 = _4589;
        _4401 = _4404;
        _4399 = _4400;
    }
    float _1733 = _4399 - 0.5;
    float3 _1753 = (mix(_1339._m1[3].xyz, _1339._m1[4].xyz, float3(powr(_4401, 0.800000011920928955078125))) * fast::max(1.0 + ((_1733 * 2.0) * _1339._m1[2].z), 0.0)) * in.m_1750.xyz;
    float _4405;
    if (_1333)
    {
        _4405 = 0.4000000059604644775390625;
    }
    else
    {
        _4405 = mix(0.4000000059604644775390625, 1.0, _4401);
    }
    float3 _1766 = fast::normalize(in.m_1764);
    bool _1774;
    if (_1329)
    {
        _1774 = !gl_FrontFacing;
    }
    else
    {
        _1774 = _1329;
    }
    float3 _4407;
    if (_1774)
    {
        _4407 = -_1766;
    }
    else
    {
        _4407 = _1766;
    }
    float3 _1782 = fast::normalize(in.m_1780);
    float3 _1787 = fast::normalize(_136._m4.xyz);
    float3 _1793 = _136._m6.xyz - in.m_1066;
    float3 _1799 = fast::normalize(_1787 + fast::normalize(_1793));
    bool _1804 = in.m_1801.x > 0.5;
    float3 _4560;
    float _4561;
    if ((_136._m5.w > 0.5) && _1804)
    {
        float _4463;
        float3 _4464;
        do
        {
            int _2510 = int(_136._m21.x);
            float _2518 = dot(_136._m20.xyz, in.m_1066) + _136._m20.w;
            int _4408;
            _4408 = 0;
            for (;;)
            {
                bool _2524 = _4408 < (_2510 - 1);
                bool _2532;
                if (_2524)
                {
                    _2532 = _2518 > _136._m16[_4408];
                }
                else
                {
                    _2532 = _2524;
                }
                if (_2532)
                {
                    _4408++;
                    continue;
                }
                else
                {
                    break;
                }
            }
            if (_2518 > _136._m16[_4408])
            {
                _4464 = float3(1.0);
                _4463 = 1.0;
                break;
            }
            float _4421;
            do
            {
                float4 _2634 = _136._m14[_4408] * float4(in.m_1066 + (_4407 * _136._m18[_4408]), 1.0);
                float _2637 = _2634.x;
                bool _2638 = _2637 < 0.0;
                bool _2645;
                if (!_2638)
                {
                    _2645 = _2637 > 1.0;
                }
                else
                {
                    _2645 = _2638;
                }
                bool _2652;
                if (!_2645)
                {
                    _2652 = _2634.y < 0.0;
                }
                else
                {
                    _2652 = _2645;
                }
                bool _2659;
                if (!_2652)
                {
                    _2659 = _2634.y > 1.0;
                }
                else
                {
                    _2659 = _2652;
                }
                if (_2659)
                {
                    _4421 = 1.0;
                    break;
                }
                float2 _2672 = float2(float(_4408 & 1), float(_4408 >> 1)) * _136._m23.xy;
                float _2679 = fast::min(_2634.z, 1.0) - _136._m19[_4408];
                float2 _2698 = _136._m22.xy * 0.5;
                float2 _2703 = _2672 + (_2634.xy * _136._m23.xy);
                float4 _2716 = float4(_2672 + _2698, (_2672 + _136._m23.xy) - _2698);
                float _4420;
                do
                {
                    int _2742 = int(_136._m22.z);
                    if (_2742 <= 0)
                    {
                        _4420 = spvDepthCast(_156).sample_compare(_156Smplr, float3(fast::clamp(_2703, _2716.xy, _2716.zw), _2679).xy, _2679);
                        break;
                    }
                    float2 _2765 = (_2703 / _136._m22.xy) + float2(0.5);
                    float2 _2766 = floor(_2765);
                    float2 _2771 = _2765 - _2766;
                    float2 _2774 = _2766 - float2(0.5);
                    bool _2778 = _2742 == 1;
                    spvUnsafeArray<float2, 3> _2726;
                    spvUnsafeArray<float2, 3> _2727;
                    if (_2778)
                    {
                        float2 _2781 = _2771 * 2.0;
                        _2726[0] = float2(3.0) - _2781;
                        _2726[1] = float2(1.0) + _2781;
                        _2727[0] = ((float2(2.0) - _2771) / _2726[0]) - float2(1.0);
                        _2727[1] = (_2771 / _2726[1]) + float2(1.0);
                    }
                    else
                    {
                        float2 _2808 = _2771 * 3.0;
                        _2726[0] = float2(4.0) - _2808;
                        _2726[1] = float2(7.0);
                        _2726[2] = float2(1.0) + _2808;
                        _2727[0] = ((float2(3.0) - (_2771 * 2.0)) / _2726[0]) - float2(2.0);
                        _2727[1] = (float2(3.0) + _2771) / _2726[1];
                        _2727[2] = (_2771 / _2726[2]) + float2(2.0);
                    }
                    int _4776 = _2778 ? 2 : 3;
                    int _4410;
                    float _4413;
                    _4413 = 0.0;
                    _4410 = 0;
                    float _4419;
                    for (; _4410 < _4776; _4413 = _4419, _4410++)
                    {
                        _4419 = _4413;
                        for (int _4416 = 0; _4416 < _4776; )
                        {
                            _4419 += ((_2726[_4416].x * _2726[_4410].y) * spvDepthCast(_156).sample_compare(_156Smplr, float3(fast::clamp(_136._m22.xy * (_2774 + float2(_2727[_4416].x, _2727[_4410].y)), _2716.xy, _2716.zw), _2679).xy, _2679));
                            _4416++;
                            continue;
                        }
                    }
                    _4420 = _4413 * (_2778 ? 0.0625 : 0.0069444444961845874786376953125);
                    break;
                } while(false);
                _4421 = _4420;
                break;
            } while(false);
            float3 _4458;
            float _4461;
            if (_2518 > _136._m17[_4408])
            {
                float _2572 = (_2518 - _136._m17[_4408]) / (_136._m16[_4408] - _136._m17[_4408]);
                int _2574 = _4408 + 1;
                float3 _4459;
                float _4462;
                if (_2574 < _2510)
                {
                    float _4441;
                    do
                    {
                        float4 _2921 = _136._m14[_2574] * float4(in.m_1066 + (_4407 * _136._m18[_2574]), 1.0);
                        float _2924 = _2921.x;
                        bool _2925 = _2924 < 0.0;
                        bool _2932;
                        if (!_2925)
                        {
                            _2932 = _2924 > 1.0;
                        }
                        else
                        {
                            _2932 = _2925;
                        }
                        bool _2939;
                        if (!_2932)
                        {
                            _2939 = _2921.y < 0.0;
                        }
                        else
                        {
                            _2939 = _2932;
                        }
                        bool _2946;
                        if (!_2939)
                        {
                            _2946 = _2921.y > 1.0;
                        }
                        else
                        {
                            _2946 = _2939;
                        }
                        if (_2946)
                        {
                            _4441 = 1.0;
                            break;
                        }
                        float2 _2959 = float2(float(_2574 & 1), float(_2574 >> 1)) * _136._m23.xy;
                        float _2966 = fast::min(_2921.z, 1.0) - _136._m19[_2574];
                        float2 _2985 = _136._m22.xy * 0.5;
                        float2 _2990 = _2959 + (_2921.xy * _136._m23.xy);
                        float4 _3003 = float4(_2959 + _2985, (_2959 + _136._m23.xy) - _2985);
                        float _4440;
                        do
                        {
                            int _3029 = int(_136._m22.z);
                            if (_3029 <= 0)
                            {
                                _4440 = spvDepthCast(_156).sample_compare(_156Smplr, float3(fast::clamp(_2990, _3003.xy, _3003.zw), _2966).xy, _2966);
                                break;
                            }
                            float2 _3052 = (_2990 / _136._m22.xy) + float2(0.5);
                            float2 _3053 = floor(_3052);
                            float2 _3058 = _3052 - _3053;
                            float2 _3061 = _3053 - float2(0.5);
                            bool _3065 = _3029 == 1;
                            spvUnsafeArray<float2, 3> _3013;
                            spvUnsafeArray<float2, 3> _3014;
                            if (_3065)
                            {
                                float2 _3068 = _3058 * 2.0;
                                _3013[0] = float2(3.0) - _3068;
                                _3013[1] = float2(1.0) + _3068;
                                _3014[0] = ((float2(2.0) - _3058) / _3013[0]) - float2(1.0);
                                _3014[1] = (_3058 / _3013[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _3095 = _3058 * 3.0;
                                _3013[0] = float2(4.0) - _3095;
                                _3013[1] = float2(7.0);
                                _3013[2] = float2(1.0) + _3095;
                                _3014[0] = ((float2(3.0) - (_3058 * 2.0)) / _3013[0]) - float2(2.0);
                                _3014[1] = (float2(3.0) + _3058) / _3013[1];
                                _3014[2] = (_3058 / _3013[2]) + float2(2.0);
                            }
                            int _4778 = _3065 ? 2 : 3;
                            int _4430;
                            float _4433;
                            _4433 = 0.0;
                            _4430 = 0;
                            float _4439;
                            for (; _4430 < _4778; _4433 = _4439, _4430++)
                            {
                                _4439 = _4433;
                                for (int _4436 = 0; _4436 < _4778; )
                                {
                                    _4439 += ((_3013[_4436].x * _3013[_4430].y) * spvDepthCast(_156).sample_compare(_156Smplr, float3(fast::clamp(_136._m22.xy * (_3061 + float2(_3014[_4436].x, _3014[_4430].y)), _3003.xy, _3003.zw), _2966).xy, _2966));
                                    _4436++;
                                    continue;
                                }
                            }
                            _4440 = _4433 * (_3065 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _4441 = _4440;
                        break;
                    } while(false);
                    _4462 = mix(_4421, _4441, _2572);
                    _4459 = mix(_510[_4408], _510[_2574], float3(_2572));
                }
                else
                {
                    _4462 = mix(_4421, 1.0, _2572);
                    _4459 = _510[_4408];
                }
                _4461 = _4462;
                _4458 = _4459;
            }
            else
            {
                _4461 = _4421;
                _4458 = _510[_4408];
            }
            _4464 = select(float3(1.0), _4458, bool3(_136._m22.w > 0.5));
            _4463 = _4461;
            break;
        } while(false);
        _4561 = _4463;
        _4560 = _1753 * _4464;
    }
    else
    {
        _4561 = 1.0;
        _4560 = _1753;
    }
    float _1834 = dot(_4407, _1787);
    float _1837 = fast::clamp((_1834 * 0.60000002384185791015625) + 0.4000000059604644775390625, 0.0, 1.0);
    float _1849 = _1733 * 0.300000011920928955078125;
    float _3194 = dot(fast::normalize(_1782 + (_4407 * (0.100000001490116119384765625 + _1849))), _1799);
    float _3208 = dot(fast::normalize(_1782 + (_4407 * ((-0.119999997317790985107421875) + _1849))), _1799);
    float3 _4564;
    if (_136._m29.x > 0.5)
    {
        float _3274 = (_136._m29.z * _4407.x) - (_136._m29.w * _4407.z);
        float _3287 = (_136._m29.w * _4407.x) + (_136._m29.z * _4407.z);
        float _3305 = 1.09254801273345947265625 * _3274;
        spvUnsafeArray<float, 9> _4269 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _4407.y, 0.48860299587249755859375 * _3287, 0.48860299587249755859375 * _3274, _3305 * _4407.y, (1.09254801273345947265625 * _4407.y) * _3287, 0.3153919875621795654296875 * (((3.0 * _3287) * _3287) - 1.0), _3305 * _3287, 0.546274006366729736328125 * ((_3274 * _3274) - (_4407.y * _4407.y)) });
        spvUnsafeArray<float, 9> _3219 = _4269;
        float3 _4563;
        _4563 = float3(0.0);
        for (int _4562 = 0; _4562 < 9; )
        {
            _4563 += (_1020.read(uint2((int2(496, 256) + int2(_4562, 0))), 0).xyz * _3219[_4562]);
            _4562++;
            continue;
        }
        _4564 = fast::max(_4563, float3(0.0)) * _136._m29.y;
    }
    else
    {
        _4564 = mix(_136._m9.xyz, _136._m8.xyz, float3((_4407.y * 0.5) + 0.5)) * _136._m8.w;
    }
    float3 _1935 = ((((_4560 * ((_1837 * _1837) * mix(0.75, 1.0, _4405))) + (((float3(0.2199999988079071044921875) * powr(sqrt(fast::max(1.0 - (_3194 * _3194), 0.0)), 90.0)) + ((_1339._m1[4].xyz * 0.550000011920928955078125) * powr(sqrt(fast::max(1.0 - (_3208 * _3208), 0.0)), 18.0))) * ((_1339._m1[2].w * smoothstep(-0.20000000298023223876953125, 0.3499999940395355224609375, _1834)) * _4405))) * (_136._m5.xyz * _136._m4.w)) * _4561) + ((_4560 * _4564) * _4405);
    float3 _4572;
    if (_136._m13.w > 0.5)
    {
        float2 _3390 = fast::clamp(floor(gl_FragCoord.xy * _136._m12.xy), float2(0.0), _136._m13.xy - float2(1.0));
        uint _3418 = uint((((fast::clamp(floor((log2(fast::max(dot(_136._m11.xyz, in.m_1066) + _136._m11.w, 9.9999999747524270787835121154785e-07)) * _136._m12.z) + _136._m12.w), 0.0, _136._m13.z - 1.0) * _136._m13.y) + _3390.y) * _136._m13.x) + _3390.x);
        uint _3420 = _3418 >> uint(2);
        uint _3422 = _3418 & 3u;
        uint _3426 = _1199._m0[_3420][_3422] & 65535u;
        uint _3428 = _1199._m0[_3420][_3422] >> uint(16);
        float3 _4573;
        _4573 = _1935;
        float3 _1999;
        spvUnsafeArray<float2, 3> _3836;
        spvUnsafeArray<float2, 3> _3837;
        spvUnsafeArray<float2, 3> _4049;
        spvUnsafeArray<float2, 3> _4050;
        for (uint _4569 = _3426; _4569 < (_3426 + _3428); _4573 = _1999, _4569++)
        {
            uint _3434 = _4569 / 3u;
            uint _3447 = (_1221._m0[_3434 >> uint(2)][_3434 & 3u] >> ((_4569 - (_3434 * 3u)) * 10u)) & 1023u;
            float3 _3464 = _1058._m0[_3447].xyz - in.m_1066;
            float _3467 = dot(_3464, _3464);
            float _3471 = _3467 * _1058._m0[_3447].w;
            float _3476 = fast::clamp(1.0 - (_3471 * _3471), 0.0, 1.0);
            float3 _3481 = _3464 * rsqrt(fast::max(_3467, 9.9999999392252902907785028219223e-09));
            float _3499 = fast::clamp((dot(-_3481, _1102._m0[_3447].xyz) * _1094._m0[_3447].w) + _1102._m0[_3447].w, 0.0, 1.0);
            float3 _3512 = _1094._m0[_3447].xyz * ((((_3476 * _3476) * _3499) * _3499) / fast::max(_3467, 9.9999997473787516355514526367188e-05));
            float3 _4700;
            if (_1804)
            {
                float _4648;
                do
                {
                    uint _3548 = uint(_136._m21.z);
                    if (_3447 < _3548)
                    {
                        float _3570 = _136._m26[_3447].z * fast::max((_136._m15[_3447] * float4(in.m_1066, 1.0)).w, 0.0);
                        float4 _3594 = _136._m15[_3447] * float4((in.m_1066 + (_4407 * (_3570 * _136._m25.x))) + (_3481 * (_3570 * _136._m25.y)), 1.0);
                        float _3596 = _3594.w;
                        if (_3596 <= 0.0)
                        {
                            _4648 = 1.0;
                            break;
                        }
                        float3 _3605 = _3594.xyz / float3(_3596);
                        float _3607 = _3605.x;
                        bool _3608 = _3607 < 0.0;
                        bool _3615;
                        if (!_3608)
                        {
                            _3615 = _3607 > 1.0;
                        }
                        else
                        {
                            _3615 = _3608;
                        }
                        bool _3622;
                        if (!_3615)
                        {
                            _3622 = _3605.y < 0.0;
                        }
                        else
                        {
                            _3622 = _3615;
                        }
                        bool _3629;
                        if (!_3622)
                        {
                            _3629 = _3605.y > 1.0;
                        }
                        else
                        {
                            _3629 = _3622;
                        }
                        bool _3636;
                        if (!_3629)
                        {
                            _3636 = _3605.z > 1.0;
                        }
                        else
                        {
                            _3636 = _3629;
                        }
                        if (_3636)
                        {
                            _4648 = 1.0;
                            break;
                        }
                        float _3642 = _3605.z;
                        float2 _3808 = _136._m22.xy * 0.5;
                        float2 _3813 = _136._m26[_3447].xy + (_3605.xy * _136._m23.zw);
                        float4 _3826 = float4(_136._m26[_3447].xy + _3808, (_136._m26[_3447].xy + _136._m23.zw) - _3808);
                        float _4647;
                        do
                        {
                            int _3852 = int(_136._m22.z);
                            if (_3852 <= 0)
                            {
                                float2 _3862 = fast::clamp(_3813, _3826.xy, _3826.zw);
                                _4647 = spvDepthCast(_156).sample_compare(_156Smplr, float3(_3862, _3642).xy, _3642);
                                break;
                            }
                            float2 _3875 = (_3813 / _136._m22.xy) + float2(0.5);
                            float2 _3876 = floor(_3875);
                            float2 _3881 = _3875 - _3876;
                            float2 _3884 = _3876 - float2(0.5);
                            bool _3888 = _3852 == 1;
                            if (_3888)
                            {
                                float2 _3891 = _3881 * 2.0;
                                _3836[0] = float2(3.0) - _3891;
                                _3836[1] = float2(1.0) + _3891;
                                _3837[0] = ((float2(2.0) - _3881) / _3836[0]) - float2(1.0);
                                _3837[1] = (_3881 / _3836[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _3918 = _3881 * 3.0;
                                _3836[0] = float2(4.0) - _3918;
                                _3836[1] = float2(7.0);
                                _3836[2] = float2(1.0) + _3918;
                                _3837[0] = ((float2(3.0) - (_3881 * 2.0)) / _3836[0]) - float2(2.0);
                                _3837[1] = (float2(3.0) + _3881) / _3836[1];
                                _3837[2] = (_3881 / _3836[2]) + float2(2.0);
                            }
                            int _4783 = _3888 ? 2 : 3;
                            int _4637;
                            float _4640;
                            _4640 = 0.0;
                            _4637 = 0;
                            float _4646;
                            for (; _4637 < _4783; _4640 = _4646, _4637++)
                            {
                                _4646 = _4640;
                                for (int _4643 = 0; _4643 < _4783; )
                                {
                                    _4646 += ((_3836[_4643].x * _3836[_4637].y) * spvDepthCast(_156).sample_compare(_156Smplr, float3(fast::clamp(_136._m22.xy * (_3884 + float2(_3837[_4643].x, _3837[_4637].y)), _3826.xy, _3826.zw), _3642).xy, _3642));
                                    _4643++;
                                    continue;
                                }
                            }
                            _4647 = _4640 * (_3888 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _4648 = _4647;
                        break;
                    }
                    uint _3652 = _3447 - _3548;
                    if (_3652 >= uint(_136._m21.w))
                    {
                        _4648 = 1.0;
                        break;
                    }
                    float _3673 = _136._m27[_3652].w * length(in.m_1066 - _136._m27[_3652].xyz);
                    float3 _3691 = ((in.m_1066 + (_4407 * (_3673 * _136._m25.x))) + (_3481 * (_3673 * _136._m25.y))) - _136._m27[_3652].xyz;
                    float3 _3693 = abs(_3691);
                    float _3695 = _3693.x;
                    float _3697 = _3693.y;
                    bool _3698 = _3695 >= _3697;
                    bool _3706;
                    if (_3698)
                    {
                        _3706 = _3695 >= _3693.z;
                    }
                    else
                    {
                        _3706 = _3698;
                    }
                    float _4622;
                    int _4624;
                    if (_3706)
                    {
                        _4624 = (_3691.x > 0.0) ? 0 : 1;
                        _4622 = _3695;
                    }
                    else
                    {
                        float _3718 = _3693.z;
                        bool _3719 = _3697 >= _3718;
                        int _4625;
                        if (_3719)
                        {
                            _4625 = (_3691.y > 0.0) ? 2 : 3;
                        }
                        else
                        {
                            _4625 = (_3691.z > 0.0) ? 4 : 5;
                        }
                        _4624 = _4625;
                        _4622 = _3719 ? _3697 : _3718;
                    }
                    if (_4622 <= 0.0)
                    {
                        _4648 = 1.0;
                        break;
                    }
                    float2 _3756 = float2(dot(_3691, _814[_4624]), dot(_3691, _823[_4624])) / float2(_4622 * _136._m24.z);
                    float _3763 = _136._m28[_3652].z + (_136._m28[_3652].w / _4622);
                    if (_3763 > 1.0)
                    {
                        _4648 = 1.0;
                        break;
                    }
                    float2 _3781 = _136._m28[_3652].xy + (float2(float(spvSMod(_4624, 3)), float(_4624 / 3)) * _136._m24.xy);
                    float2 _4021 = _136._m22.xy * 0.5;
                    float2 _4026 = _3781 + (float2(0.5 + (0.5 * _3756.x), 0.5 - (0.5 * _3756.y)) * _136._m24.xy);
                    float4 _4039 = float4(_3781 + _4021, (_3781 + _136._m24.xy) - _4021);
                    float _4636;
                    do
                    {
                        int _4065 = int(_136._m22.z);
                        if (_4065 <= 0)
                        {
                            _4636 = spvDepthCast(_156).sample_compare(_156Smplr, float3(fast::clamp(_4026, _4039.xy, _4039.zw), _3763).xy, _3763);
                            break;
                        }
                        float2 _4088 = (_4026 / _136._m22.xy) + float2(0.5);
                        float2 _4089 = floor(_4088);
                        float2 _4094 = _4088 - _4089;
                        float2 _4097 = _4089 - float2(0.5);
                        bool _4101 = _4065 == 1;
                        if (_4101)
                        {
                            float2 _4104 = _4094 * 2.0;
                            _4049[0] = float2(3.0) - _4104;
                            _4049[1] = float2(1.0) + _4104;
                            _4050[0] = ((float2(2.0) - _4094) / _4049[0]) - float2(1.0);
                            _4050[1] = (_4094 / _4049[1]) + float2(1.0);
                        }
                        else
                        {
                            float2 _4131 = _4094 * 3.0;
                            _4049[0] = float2(4.0) - _4131;
                            _4049[1] = float2(7.0);
                            _4049[2] = float2(1.0) + _4131;
                            _4050[0] = ((float2(3.0) - (_4094 * 2.0)) / _4049[0]) - float2(2.0);
                            _4050[1] = (float2(3.0) + _4094) / _4049[1];
                            _4050[2] = (_4094 / _4049[2]) + float2(2.0);
                        }
                        int _4786 = _4101 ? 2 : 3;
                        int _4626;
                        float _4629;
                        _4629 = 0.0;
                        _4626 = 0;
                        float _4635;
                        for (; _4626 < _4786; _4629 = _4635, _4626++)
                        {
                            _4635 = _4629;
                            for (int _4632 = 0; _4632 < _4786; )
                            {
                                _4635 += ((_4049[_4632].x * _4049[_4626].y) * spvDepthCast(_156).sample_compare(_156Smplr, float3(fast::clamp(_136._m22.xy * (_4097 + float2(_4050[_4632].x, _4050[_4626].y)), _4039.xy, _4039.zw), _3763).xy, _3763));
                                _4632++;
                                continue;
                            }
                        }
                        _4636 = _4629 * (_4101 ? 0.0625 : 0.0069444444961845874786376953125);
                        break;
                    } while(false);
                    _4648 = _4636;
                    break;
                } while(false);
                _4700 = _3512 * _4648;
            }
            else
            {
                _4700 = _3512;
            }
            float _1990 = fast::clamp((dot(_4407, _3481) * 0.60000002384185791015625) + 0.4000000059604644775390625, 0.0, 1.0);
            _1999 = _4573 + (((_4560 * _1990) * _1990) * _4700);
        }
        _4572 = _4573;
    }
    else
    {
        _4572 = _1935;
    }
    float _2011 = -length(_1793);
    float _4575;
    if (_136._m9.w != 0.0)
    {
        float _2035 = _136._m9.w * (in.m_1066 - _136._m6.xyz).y;
        float _4570;
        if (abs(_2035) < 9.9999997473787516355514526367188e-05)
        {
            _4570 = 1.0 - (0.5 * _2035);
        }
        else
        {
            _4570 = (1.0 - exp(fast::min(-_2035, 60.0))) / _2035;
        }
        _4575 = 1.0 - exp((_2011 * (_136._m7.w * exp(fast::min((-_136._m9.w) * (_136._m6.y - _136._m6.w), 30.0)))) * _4570);
    }
    else
    {
        _4575 = 1.0 - exp(_2011 * _136._m7.w);
    }
    float3 _2086 = mix(_4572, _136._m7.xyz, float3(_4575));
    float3 _4576;
    if (_136._m33.w > 0.5)
    {
        _4576 = _2086 / (float3(1.0) + _2086);
    }
    else
    {
        _4576 = _2086;
    }
    out.m_2099 = float4(_4576, _4586);
    float2 _4618;
    do
    {
        if (in.m_2109.w <= 0.0)
        {
            _4618 = float2(0.0);
            break;
        }
        _4618 = ((in.m_2109.xy / float2(in.m_2109.w)) - (in.m_2108.xy / float2(in.m_2108.w))) * float2(0.5, -0.5);
        break;
    } while(false);
    _2107 = _4618;
    return out;
}

