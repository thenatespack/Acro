// Generated from mesh.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 93a14d21093cc782

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

struct _108
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
};

struct _342
{
    float4 _m0;
    float4 _m1;
    float4 _m2;
};

struct fragment_main_out
{
    float4 m_496 [[color(0)]];
};

struct fragment_main_in
{
    float3 m_319 [[user(locn0)]];
    float3 m_304 [[user(locn1)]];
    float2 m_340 [[user(locn2)]];
    float4 m_351 [[user(locn3)]];
    float4 m_53 [[user(locn4)]];
    float4 m_400 [[user(locn5)]];
    float4 m_511 [[user(locn6)]];
    float4 m_512 [[user(locn7)]];
};

fragment fragment_main_out fragment_main(fragment_main_in in [[stage_in]], constant _342& _344 [[buffer(2)]], constant _108& _110 [[buffer(15)]], texture2d<float> _133 [[texture(0)]], texture2d<float> _331 [[texture(1)]], sampler _133Smplr [[sampler(0)]], sampler _335 [[sampler(1)]])
{
    float2 _510;
    fragment_main_out out = {};
    float3 _306 = fast::normalize(in.m_304);
    float3 _313 = fast::normalize(_110._m4.xyz);
    float3 _321 = _110._m6.xyz - in.m_319;
    float4 _349 = _331.sample(_335, (in.m_340 * _344._m2.xy));
    float3 _360 = (in.m_351.xyz * _344._m0.xyz) * _349.xyz;
    float3 _810;
    if (_344._m1.x > 0.5)
    {
        float2 _380 = floor(in.m_319.xz * float2(0.5));
        _810 = _360 * ((mod(abs(_380.x + _380.y), 2.0) < 0.5) ? 1.0 : 0.75);
    }
    else
    {
        _810 = _360;
    }
    bool _397 = _110._m5.w > 0.5;
    bool _404;
    if (_397)
    {
        _404 = in.m_400.x > 0.5;
    }
    else
    {
        _404 = _397;
    }
    float _803;
    if (_404)
    {
        float _802;
        do
        {
            float3 _556 = in.m_53.xyz / float3(in.m_53.w);
            float _560 = (_556.x * 0.5) + 0.5;
            float _564 = 0.5 - (_556.y * 0.5);
            bool _568 = _560 < 0.0;
            bool _575;
            if (!_568)
            {
                _575 = _560 > 1.0;
            }
            else
            {
                _575 = _568;
            }
            bool _582;
            if (!_575)
            {
                _582 = _564 < 0.0;
            }
            else
            {
                _582 = _575;
            }
            bool _589;
            if (!_582)
            {
                _589 = _564 > 1.0;
            }
            else
            {
                _589 = _582;
            }
            if (_589)
            {
                _802 = 1.0;
                break;
            }
            float _597 = fast::min(_556.z, 1.0) - _110._m10.y;
            int _602 = int(_110._m10.z);
            if (_602 <= 0)
            {
                _802 = spvDepthCast(_133).sample_compare(_133Smplr, float3(_560, _564, _597).xy, _597);
                break;
            }
            float2 _621 = (float2(_560, _564) / float2(_110._m10.x)) + float2(0.5);
            float2 _622 = floor(_621);
            float2 _627 = _621 - _622;
            float2 _632 = (_622 - float2(0.5)) * _110._m10.x;
            bool _634 = _602 == 1;
            spvUnsafeArray<float2, 3> _541;
            spvUnsafeArray<float2, 3> _542;
            if (_634)
            {
                float2 _637 = _627 * 2.0;
                _541[0] = float2(3.0) - _637;
                _541[1] = float2(1.0) + _637;
                _542[0] = ((float2(2.0) - _627) / _541[0]) - float2(1.0);
                _542[1] = (_627 / _541[1]) + float2(1.0);
            }
            else
            {
                float2 _664 = _627 * 3.0;
                _541[0] = float2(4.0) - _664;
                _541[1] = float2(7.0);
                _541[2] = float2(1.0) + _664;
                _542[0] = ((float2(3.0) - (_627 * 2.0)) / _541[0]) - float2(2.0);
                _542[1] = (float2(3.0) + _627) / _541[1];
                _542[2] = (_627 / _541[2]) + float2(2.0);
            }
            int _822 = _634 ? 2 : 3;
            int _792;
            float _795;
            _795 = 0.0;
            _792 = 0;
            float _801;
            for (; _792 < _822; _795 = _801, _792++)
            {
                _801 = _795;
                for (int _798 = 0; _798 < _822; )
                {
                    _801 += ((_541[_798].x * _541[_792].y) * spvDepthCast(_133).sample_compare(_133Smplr, float3(_632 + (float2(_542[_798].x, _542[_792].y) * _110._m10.x), _597).xy, _597));
                    _798++;
                    continue;
                }
            }
            _802 = _795 * (_634 ? 0.0625 : 0.0069444444961845874786376953125);
            break;
        } while(false);
        _803 = _802;
    }
    else
    {
        _803 = 1.0;
    }
    float3 _417 = _110._m5.xyz * _110._m4.w;
    float _421 = dot(_306, _313);
    float3 _503 = mix(mix((_810 * ((mix(_110._m9.xyz, _110._m8.xyz, float3((_306.y * 0.5) + 0.5)) * _110._m8.w) + ((_417 * fast::max(_421, 0.0)) * _803))) + ((_417 * ((powr(fast::max(dot(_306, fast::normalize(_313 + fast::normalize(_321))), 0.0), _344._m1.w) * _344._m1.z) * step(0.0, _421))) * _803), _810, float3(_344._m1.y)), _110._m7.xyz, float3(1.0 - exp((-length(_321)) * _110._m7.w)));
    out.m_496 = float4(_503, (in.m_351.w * _344._m0.w) * _349.w);
    float2 _814;
    do
    {
        if (in.m_512.w <= 0.0)
        {
            _814 = float2(0.0);
            break;
        }
        _814 = ((in.m_512.xy / float2(in.m_512.w)) - (in.m_511.xy / float2(in.m_511.w))) * float2(0.5, -0.5);
        break;
    } while(false);
    _510 = _814;
    return out;
}

