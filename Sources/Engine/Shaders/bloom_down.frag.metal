// Generated from bloom_down.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: bd7d81531b4ddfd1
// glsl-fnv1a64: ff8fda7b7c369a09

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

struct _96
{
    int2 _m0;
    float _m1;
    float _m2;
};

constant spvUnsafeArray<float, 5> _368 = spvUnsafeArray<float, 5>({ 0.5, 0.125, 0.125, 0.125, 0.125 });

struct fragment_main_out
{
    float4 m_418 [[color(0)]];
};

fragment fragment_main_out fragment_main(constant _96& _98 [[buffer(16)]], texture2d<float> _90 [[texture(1)]], sampler _35 [[sampler(1)]], float4 gl_FragCoord [[position]])
{
    fragment_main_out out = {};
    int2 _61 = (int2(gl_FragCoord.xy) * int2(2)) - int2(2);
    int _442;
    _442 = 0;
    spvUnsafeArray<float3, 36> _85;
    for (; _442 < 6; _442++)
    {
        for (int _450 = 0; _450 < 6; )
        {
            _85[(_442 * 6) + _450] = fast::min(_90.read(uint2(clamp(_61 + int2(_450, _442), int2(0), _98._m0)), 0).xyz, float3(_98._m2));
            _450++;
            continue;
        }
    }
    float3 _146 = (((_85[2] + _85[3]) + _85[8]) + _85[9]) * 0.25;
    float3 _209 = (((_85[12] + _85[13]) + _85[18]) + _85[19]) * 0.25;
    float3 _224 = (((_85[14] + _85[15]) + _85[20]) + _85[21]) * 0.25;
    float3 _240 = (((_85[16] + _85[17]) + _85[22]) + _85[23]) * 0.25;
    float3 _301 = (((_85[26] + _85[27]) + _85[32]) + _85[33]) * 0.25;
    spvUnsafeArray<float3, 5> _362 = spvUnsafeArray<float3, 5>({ (((((((_85[7] + _85[8]) + _85[13]) + _85[14]) * 0.25) + ((((_85[9] + _85[10]) + _85[15]) + _85[16]) * 0.25)) + ((((_85[19] + _85[20]) + _85[25]) + _85[26]) * 0.25)) + ((((_85[21] + _85[22]) + _85[27]) + _85[28]) * 0.25)) * 0.25, (((((((_85[0] + _85[1]) + _85[6]) + _85[7]) * 0.25) + _146) + _209) + _224) * 0.25, (((_146 + ((((_85[4] + _85[5]) + _85[10]) + _85[11]) * 0.25)) + _224) + _240) * 0.25, (((_209 + _224) + ((((_85[24] + _85[25]) + _85[30]) + _85[31]) * 0.25)) + _301) * 0.25, (((_224 + _240) + _301) + ((((_85[28] + _85[29]) + _85[34]) + _85[35]) * 0.25)) * 0.25 });
    spvUnsafeArray<float3, 5> _321 = _362;
    float3 _444;
    float _445;
    _445 = 0.0;
    _444 = float3(0.0);
    float3 _411;
    float _414;
    for (int _443 = 0; _443 < 5; _445 = _414, _444 = _411, _443++)
    {
        float _446;
        if (_98._m1 > 0.5)
        {
            _446 = _368[_443] / (1.0 + dot(_321[_443], float3(0.2125999927520751953125, 0.715200006961822509765625, 0.072200000286102294921875)));
        }
        else
        {
            _446 = _368[_443];
        }
        _411 = _444 + (_321[_443] * _446);
        _414 = _445 + _446;
    }
    out.m_418 = float4(_444 / float3(_445), 1.0);
    return out;
}

