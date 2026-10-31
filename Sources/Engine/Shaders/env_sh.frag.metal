// Generated from env_sh.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: af5b83d3820d2e9d
// glsl-fnv1a64: 1e55f120453b1744

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

struct _141
{
    int2 _m0;
};

struct fragment_main_out
{
    float4 m_258 [[color(0)]];
};

fragment fragment_main_out fragment_main(constant _141& _143 [[buffer(16)]], texture2d<float> _215 [[texture(1)]], sampler _219 [[sampler(1)]], float4 gl_FragCoord [[position]])
{
    fragment_main_out out = {};
    int _138 = int(gl_FragCoord.x);
    float2 _147 = float2(_143._m0);
    float _151 = 6.283185482025146484375 / _147.x;
    int _410;
    float3 _413;
    _413 = float3(0.0);
    _410 = 0;
    int _177;
    float3 _241;
    spvUnsafeArray<float, 9> _208;
    for (; _410 < _143._m0.y; _413 = _241, _410 = _177)
    {
        float _170 = float(_410);
        float _172 = _147.y;
        _177 = _410 + 1;
        float3 _415;
        _415 = float3(0.0);
        for (int _414 = 0; _414 < _143._m0.x; )
        {
            float2 _205 = (float2(float(_414), _170) + float2(0.5)) / _147;
            float _296 = (_205.x - 0.5) * 6.283185482025146484375;
            float _299 = _205.y * 3.1415927410125732421875;
            float _301 = sin(_299);
            float _305 = _301 * sin(_296);
            float _307 = cos(_299);
            float _312 = (-_301) * cos(_296);
            float _330 = 1.09254801273345947265625 * _305;
            spvUnsafeArray<float, 9> _389 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _307, 0.48860299587249755859375 * _312, 0.48860299587249755859375 * _305, _330 * _307, (1.09254801273345947265625 * _307) * _312, 0.3153919875621795654296875 * (((3.0 * _312) * _312) - 1.0), _330 * _312, 0.546274006366729736328125 * ((_305 * _305) - (_307 * _307)) });
            _208 = _389;
            _415 += (_215.read(uint2(int2(_414, _410)), 0).xyz * _208[_138]);
            _414++;
            continue;
        }
        _241 = _413 + (_415 * (_151 * (cos((_170 / _172) * 3.1415927410125732421875) - cos((float(_177) / _172) * 3.1415927410125732421875))));
    }
    float _411;
    if (_138 == 0)
    {
        _411 = 1.0;
    }
    else
    {
        _411 = (_138 < 4) ? 0.666666686534881591796875 : 0.25;
    }
    out.m_258 = float4(_413 * _411, 1.0);
    return out;
}

