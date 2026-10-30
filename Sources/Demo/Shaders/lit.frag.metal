// Generated from lit.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 2ebfa28bda9a2685

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

struct _81
{
    float4x4 _m0;
    float4x4 _m1;
    float4 _m2;
    float4 _m3;
    float4 _m4;
    float4 _m5;
};

struct fragment_main_out
{
    float4 m_409 [[color(0)]];
    float2 m_424 [[color(1)]];
};

struct fragment_main_in
{
    float3 m_290 [[user(locn0)]];
    float3 m_277 [[user(locn1)]];
    float4 m_300 [[user(locn2)]];
    float4 m_53 [[user(locn3)]];
    float4 m_303 [[user(locn4)]];
    float4 m_425 [[user(locn5)]];
    float4 m_426 [[user(locn6)]];
};

fragment fragment_main_out fragment_main(fragment_main_in in [[stage_in]], constant _81& _83 [[buffer(15)]], texture2d<float> _106 [[texture(0)]], sampler _106Smplr [[sampler(0)]])
{
    fragment_main_out out = {};
    float3 _279 = fast::normalize(in.m_277);
    float3 _285 = fast::normalize(_83._m2.xyz);
    float3 _292 = _83._m3.xyz - in.m_290;
    float3 _687;
    if (in.m_303.x > 0.5)
    {
        float2 _314 = floor(in.m_290.xz * float2(0.5));
        _687 = in.m_300.xyz * ((mod(abs(_314.x + _314.y), 2.0) < 0.5) ? 1.0 : 0.75);
    }
    else
    {
        _687 = in.m_300.xyz;
    }
    float _685;
    do
    {
        float3 _470 = in.m_53.xyz / float3(in.m_53.w);
        float _474 = (_470.x * 0.5) + 0.5;
        float _478 = 0.5 - (_470.y * 0.5);
        float _485 = fast::min(_470.z, 1.0) - _83._m5.y;
        int _490 = int(_83._m5.z);
        if (_490 <= 0)
        {
            _685 = spvDepthCast(_106).sample_compare(_106Smplr, float3(_474, _478, _485).xy, _485);
            break;
        }
        float2 _509 = (float2(_474, _478) / float2(_83._m5.x)) + float2(0.5);
        float2 _510 = floor(_509);
        float2 _515 = _509 - _510;
        float2 _520 = (_510 - float2(0.5)) * _83._m5.x;
        bool _522 = _490 == 1;
        spvUnsafeArray<float2, 3> _455;
        spvUnsafeArray<float2, 3> _456;
        if (_522)
        {
            float2 _525 = _515 * 2.0;
            _455[0] = float2(3.0) - _525;
            _455[1] = float2(1.0) + _525;
            _456[0] = ((float2(2.0) - _515) / _455[0]) - float2(1.0);
            _456[1] = (_515 / _455[1]) + float2(1.0);
        }
        else
        {
            float2 _552 = _515 * 3.0;
            _455[0] = float2(4.0) - _552;
            _455[1] = float2(7.0);
            _455[2] = float2(1.0) + _552;
            _456[0] = ((float2(3.0) - (_515 * 2.0)) / _455[0]) - float2(2.0);
            _456[1] = (float2(3.0) + _515) / _455[1];
            _456[2] = (_515 / _455[2]) + float2(2.0);
        }
        int _699 = _522 ? 2 : 3;
        int _675;
        float _678;
        _678 = 0.0;
        _675 = 0;
        float _684;
        for (; _675 < _699; _678 = _684, _675++)
        {
            _684 = _678;
            for (int _681 = 0; _681 < _699; )
            {
                _684 += ((_455[_681].x * _455[_675].y) * spvDepthCast(_106).sample_compare(_106Smplr, float3(_520 + (float2(_456[_681].x, _456[_675].y) * _83._m5.x), _485).xy, _485));
                _681++;
                continue;
            }
        }
        _685 = _678 * (_522 ? 0.0625 : 0.0069444444961845874786376953125);
        break;
    } while(false);
    float _332 = dot(_279, _285);
    out.m_409 = float4(mix(mix((_687 * ((mix(float3(0.119999997317790985107421875, 0.100000001490116119384765625, 0.0900000035762786865234375), float3(0.550000011920928955078125, 0.64999997615814208984375, 0.85000002384185791015625), float3((_279.y * 0.5) + 0.5)) * 0.300000011920928955078125) + float3((fast::max(_332, 0.0) * _83._m2.w) * _685))) + float3(((powr(fast::max(dot(_279, fast::normalize(_285 + fast::normalize(_292))), 0.0), 48.0) * 0.3499999940395355224609375) * step(0.0, _332)) * _685), _687, float3(in.m_303.y)), _83._m4.xyz, float3(1.0 - exp((-length(_292)) * _83._m4.w))), in.m_300.w);
    float2 _691;
    do
    {
        if (in.m_426.w <= 0.0)
        {
            _691 = float2(0.0);
            break;
        }
        _691 = ((in.m_426.xy / float2(in.m_426.w)) - (in.m_425.xy / float2(in.m_425.w))) * float2(0.5, -0.5);
        break;
    } while(false);
    out.m_424 = _691;
    return out;
}

