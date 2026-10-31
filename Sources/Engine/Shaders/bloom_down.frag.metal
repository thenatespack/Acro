// Generated from bloom_down.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: b8ce6e378d5bb77b
// glsl-fnv1a64: f717ae6753dfb26a

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

struct _56
{
    int2 _m0;
    float _m1;
    float _m2;
};

constant spvUnsafeArray<float, 5> _260 = spvUnsafeArray<float, 5>({ 0.5, 0.125, 0.125, 0.125, 0.125 });

struct fragment_main_out
{
    float4 m_313 [[color(0)]];
};

fragment fragment_main_out fragment_main(constant _56& _58 [[buffer(16)]], texture2d<float> _55 [[texture(1)]], sampler _39 [[sampler(1)]], float4 gl_FragCoord [[position]])
{
    fragment_main_out out = {};
    int2 _131 = int2(gl_FragCoord.xy) * int2(2);
    float3 _342 = float3(_58._m2);
    int2 _419 = clamp(_131 + int2(-1), int2(0), _58._m0);
    int2 _509 = clamp(_131 + int2(0, -1), int2(0), _58._m0);
    int2 _520 = clamp(_131 + int2(1, -1), int2(0), _58._m0);
    float3 _479 = (((fast::min(_55.read(uint2(clamp(_131 + int2(0, -2), int2(0), _58._m0)), 0).xyz, _342) + fast::min(_55.read(uint2(clamp(_131 + int2(1, -2), int2(0), _58._m0)), 0).xyz, _342)) + fast::min(_55.read(uint2(_509), 0).xyz, _342)) + fast::min(_55.read(uint2(_520), 0).xyz, _342)) * 0.25;
    int2 _610 = clamp(_131 + int2(2, -1), int2(0), _58._m0);
    int2 _711 = clamp(_131 + int2(-1, 0), int2(0), _58._m0);
    int2 _722 = clamp(_131, int2(0), _58._m0);
    int2 _812 = clamp(_131 + int2(1, 0), int2(0), _58._m0);
    int2 _823 = clamp(_131 + int2(2, 0), int2(0), _58._m0);
    int2 _924 = clamp(_131 + int2(-1, 1), int2(0), _58._m0);
    float3 _883 = (((fast::min(_55.read(uint2(clamp(_131 + int2(-2, 0), int2(0), _58._m0)), 0).xyz, _342) + fast::min(_55.read(uint2(_711), 0).xyz, _342)) + fast::min(_55.read(uint2(clamp(_131 + int2(-2, 1), int2(0), _58._m0)), 0).xyz, _342)) + fast::min(_55.read(uint2(_924), 0).xyz, _342)) * 0.25;
    int2 _1014 = clamp(_131 + int2(0, 1), int2(0), _58._m0);
    int2 _1025 = clamp(_131 + int2(1), int2(0), _58._m0);
    float3 _984 = (((fast::min(_55.read(uint2(_722), 0).xyz, _342) + fast::min(_55.read(uint2(_812), 0).xyz, _342)) + fast::min(_55.read(uint2(_1014), 0).xyz, _342)) + fast::min(_55.read(uint2(_1025), 0).xyz, _342)) * 0.25;
    int2 _1115 = clamp(_131 + int2(2, 1), int2(0), _58._m0);
    float3 _1085 = (((fast::min(_55.read(uint2(_823), 0).xyz, _342) + fast::min(_55.read(uint2(clamp(_131 + int2(3, 0), int2(0), _58._m0)), 0).xyz, _342)) + fast::min(_55.read(uint2(_1115), 0).xyz, _342)) + fast::min(_55.read(uint2(clamp(_131 + int2(3, 1), int2(0), _58._m0)), 0).xyz, _342)) * 0.25;
    int2 _1216 = clamp(_131 + int2(-1, 2), int2(0), _58._m0);
    int2 _1227 = clamp(_131 + int2(0, 2), int2(0), _58._m0);
    int2 _1317 = clamp(_131 + int2(1, 2), int2(0), _58._m0);
    int2 _1328 = clamp(_131 + int2(2), int2(0), _58._m0);
    float3 _1489 = (((fast::min(_55.read(uint2(_1227), 0).xyz, _342) + fast::min(_55.read(uint2(_1317), 0).xyz, _342)) + fast::min(_55.read(uint2(clamp(_131 + int2(0, 3), int2(0), _58._m0)), 0).xyz, _342)) + fast::min(_55.read(uint2(clamp(_131 + int2(1, 3), int2(0), _58._m0)), 0).xyz, _342)) * 0.25;
    float3 _221 = (((((((fast::min(_55.read(uint2(_419), 0).xyz, _342) + fast::min(_55.read(uint2(_509), 0).xyz, _342)) + fast::min(_55.read(uint2(_711), 0).xyz, _342)) + fast::min(_55.read(uint2(_722), 0).xyz, _342)) * 0.25) + ((((fast::min(_55.read(uint2(_520), 0).xyz, _342) + fast::min(_55.read(uint2(_610), 0).xyz, _342)) + fast::min(_55.read(uint2(_812), 0).xyz, _342)) + fast::min(_55.read(uint2(_823), 0).xyz, _342)) * 0.25)) + ((((fast::min(_55.read(uint2(_924), 0).xyz, _342) + fast::min(_55.read(uint2(_1014), 0).xyz, _342)) + fast::min(_55.read(uint2(_1216), 0).xyz, _342)) + fast::min(_55.read(uint2(_1227), 0).xyz, _342)) * 0.25)) + ((((fast::min(_55.read(uint2(_1025), 0).xyz, _342) + fast::min(_55.read(uint2(_1115), 0).xyz, _342)) + fast::min(_55.read(uint2(_1317), 0).xyz, _342)) + fast::min(_55.read(uint2(_1328), 0).xyz, _342)) * 0.25)) * 0.25;
    spvUnsafeArray<float3, 5> _254 = spvUnsafeArray<float3, 5>({ _221, (((((((fast::min(_55.read(uint2(clamp(_131 + int2(-2), int2(0), _58._m0)), 0).xyz, _342) + fast::min(_55.read(uint2(clamp(_131 + int2(-1, -2), int2(0), _58._m0)), 0).xyz, _342)) + fast::min(_55.read(uint2(clamp(_131 + int2(-2, -1), int2(0), _58._m0)), 0).xyz, _342)) + fast::min(_55.read(uint2(_419), 0).xyz, _342)) * 0.25) + _479) + _883) + _984) * 0.25, (((_479 + ((((fast::min(_55.read(uint2(clamp(_131 + int2(2, -2), int2(0), _58._m0)), 0).xyz, _342) + fast::min(_55.read(uint2(clamp(_131 + int2(3, -2), int2(0), _58._m0)), 0).xyz, _342)) + fast::min(_55.read(uint2(_610), 0).xyz, _342)) + fast::min(_55.read(uint2(clamp(_131 + int2(3, -1), int2(0), _58._m0)), 0).xyz, _342)) * 0.25)) + _984) + _1085) * 0.25, (((_883 + _984) + ((((fast::min(_55.read(uint2(clamp(_131 + int2(-2, 2), int2(0), _58._m0)), 0).xyz, _342) + fast::min(_55.read(uint2(_1216), 0).xyz, _342)) + fast::min(_55.read(uint2(clamp(_131 + int2(-2, 3), int2(0), _58._m0)), 0).xyz, _342)) + fast::min(_55.read(uint2(clamp(_131 + int2(-1, 3), int2(0), _58._m0)), 0).xyz, _342)) * 0.25)) + _1489) * 0.25, (((_984 + _1085) + _1489) + ((((fast::min(_55.read(uint2(_1328), 0).xyz, _342) + fast::min(_55.read(uint2(clamp(_131 + int2(3, 2), int2(0), _58._m0)), 0).xyz, _342)) + fast::min(_55.read(uint2(clamp(_131 + int2(2, 3), int2(0), _58._m0)), 0).xyz, _342)) + fast::min(_55.read(uint2(clamp(_131 + int2(3), int2(0), _58._m0)), 0).xyz, _342)) * 0.25)) * 0.25 });
    spvUnsafeArray<float3, 5> _213 = _254;
    float3 _1640;
    float _1641;
    _1641 = 0.0;
    _1640 = float3(0.0);
    float3 _306;
    float _309;
    for (int _1639 = 0; _1639 < 5; _1641 = _309, _1640 = _306, _1639++)
    {
        float _1642;
        if (_58._m1 > 0.5)
        {
            _1642 = _260[_1639] / (1.0 + dot(_213[_1639], float3(0.2125999927520751953125, 0.715200006961822509765625, 0.072200000286102294921875)));
        }
        else
        {
            _1642 = _260[_1639];
        }
        _306 = _1640 + (_213[_1639] * _1642);
        _309 = _1641 + _1642;
    }
    out.m_313 = float4(_1640 / float3(_1641), 1.0);
    return out;
}

