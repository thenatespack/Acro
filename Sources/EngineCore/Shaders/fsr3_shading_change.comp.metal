// Generated from fsr3_shading_change.comp by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 7d660e3a16fb83a7
// glsl-fnv1a64: 895ddad126b5d2b3

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

struct _103
{
    int2 _m0;
    int2 _m1;
    int2 _m2;
    int2 _m3;
    float4 _m4;
    float2 _m5;
    float2 _m6;
    float2 _m7;
    float _m8;
    float _m9;
    float _m10;
    float _m11;
    float _m12;
    float _m13;
    float _m14;
    float _m15;
    float _m16;
    float _m17;
    float _m18;
    uint2 _m19;
};

constant uint3 gl_WorkGroupSize [[maybe_unused]] = uint3(8u, 8u, 1u);

kernel void compute_main(constant _103& _105 [[buffer(16)]], texture2d<float> _126 [[texture(1)]], texture2d<float> _136 [[texture(2)]], texture2d<float> _140 [[texture(3)]], texture2d<float, access::write> _185 [[texture(8)]], sampler _154 [[sampler(1)]], uint3 gl_GlobalInvocationID [[thread_position_in_grid]])
{
    int2 _346 = int2(gl_GlobalInvocationID.xy);
    float2 _436 = float2(_105._m0);
    int2 _438 = int2(_436 * 0.5);
    if (all(gl_GlobalInvocationID.xy < uint2(_438)))
    {
        float2 _395 = float2(_438);
        float2 _571 = fast::max(float2(0.5), fast::min((((float2(_346) + float2(0.5)) / _395) + (_105._m5 / _436)) * _395, _395 - float2(0.5))) / float2(int2(_126.get_width(), _126.get_height()));
        spvUnsafeArray<float, 3> _640;
        for (int _652 = 0; _652 < 3; _652++)
        {
            uint _501 = uint(_652);
            float2 _656;
            do
            {
                if (_501 == 0u)
                {
                    _656 = _126.sample(_154, _571, level(0.0)).xy;
                    break;
                }
                if (_501 == 1u)
                {
                    _656 = _136.sample(_154, _571, level(0.0)).xy;
                    break;
                }
                _656 = _140.sample(_154, _571, level(0.0)).xy;
                break;
            } while(false);
            _640[_652] = abs(_656.x * _656.y);
        }
        spvUnsafeArray<float, 3> _644 = _640;
        float _654;
        _654 = 0.0;
        float _658;
        for (int _653 = 0; _653 < 3; _654 = _658, _653++)
        {
            if (_644[_653] > 0.0)
            {
                _658 = fast::max(_654, _644[_653]);
            }
            else
            {
                _658 = _654;
            }
        }
        if (all(gl_GlobalInvocationID.xy < uint2(int2(_185.get_width(), _185.get_height()))))
        {
            _185.write(float4(fast::clamp(_654, 0.0, 1.0), 0.0, 0.0, 0.0), uint2(_346));
        }
    }
}

