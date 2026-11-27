// Generated from lit.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: b3b642b378acd82f
// glsl-fnv1a64: d682e5fe29f57afc

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

struct _115
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
    float4 m_433 [[color(0)]];
    float2 m_448 [[color(1)]];
};

struct fragment_main_in
{
    float3 m_314 [[user(locn0)]];
    float3 m_301 [[user(locn1)]];
    float4 m_324 [[user(locn2)]];
    float4 m_89 [[user(locn3)]];
    float4 m_327 [[user(locn4)]];
    float4 m_449 [[user(locn5)]];
    float4 m_450 [[user(locn6)]];
};

fragment fragment_main_out fragment_main(fragment_main_in in [[stage_in]], constant _115& _117 [[buffer(15)]], texture2d<float> _74 [[texture(0)]], sampler _74Smplr [[sampler(0)]])
{
    fragment_main_out out = {};
    float3 _303 = fast::normalize(in.m_301);
    float3 _309 = fast::normalize(_117._m2.xyz);
    float3 _316 = _117._m3.xyz - in.m_314;
    float3 _772;
    if (in.m_327.x > 0.5)
    {
        float2 _338 = floor(in.m_314.xz * float2(0.5));
        _772 = in.m_324.xyz * ((mod(abs(_338.x + _338.y), 2.0) < 0.5) ? 1.0 : 0.75);
    }
    else
    {
        _772 = in.m_324.xyz;
    }
    float _768;
    do
    {
        float3 _503 = in.m_89.xyz / float3(in.m_89.w);
        float _507 = (_503.x * 0.5) + 0.5;
        float _511 = 0.5 - (_503.y * 0.5);
        float2 _512 = float2(_507, _511);
        float _518 = fast::min(_503.z, 1.0) - _117._m5.y;
        int _523 = int(_117._m5.z);
        if (_523 <= 0)
        {
            float _767;
            do
            {
                bool _670 = any(_512 < float2(0.0));
                bool _677;
                if (!_670)
                {
                    _677 = any(_512 > float2(1.0));
                }
                else
                {
                    _677 = _670;
                }
                if (_677)
                {
                    _767 = 1.0;
                    break;
                }
                _767 = spvDepthCast(_74).sample_compare(_74Smplr, float3(_507, _511, _518).xy, _518);
                break;
            } while(false);
            _768 = _767;
            break;
        }
        float2 _537 = (_512 / float2(_117._m5.x)) + float2(0.5);
        float2 _538 = floor(_537);
        float2 _543 = _537 - _538;
        float2 _548 = (_538 - float2(0.5)) * _117._m5.x;
        bool _550 = _523 == 1;
        spvUnsafeArray<float2, 3> _486;
        spvUnsafeArray<float2, 3> _487;
        if (_550)
        {
            float2 _553 = _543 * 2.0;
            _486[0] = float2(3.0) - _553;
            _486[1] = float2(1.0) + _553;
            _487[0] = ((float2(2.0) - _543) / _486[0]) - float2(1.0);
            _487[1] = (_543 / _486[1]) + float2(1.0);
        }
        else
        {
            float2 _580 = _543 * 3.0;
            _486[0] = float2(4.0) - _580;
            _486[1] = float2(7.0);
            _486[2] = float2(1.0) + _580;
            _487[0] = ((float2(3.0) - (_543 * 2.0)) / _486[0]) - float2(2.0);
            _487[1] = (float2(3.0) + _543) / _486[1];
            _487[2] = (_543 / _486[2]) + float2(2.0);
        }
        int _791 = _550 ? 2 : 3;
        float _755;
        _755 = 0.0;
        float _764;
        for (int _752 = 0; _752 < _791; _755 = _764, _752++)
        {
            _764 = _755;
            float _649;
            for (int _758 = 0; _758 < _791; _764 = _649, _758++)
            {
                float2 _644 = _548 + (float2(_487[_758].x, _487[_752].y) * _117._m5.x);
                float _761;
                do
                {
                    bool _697 = any(_644 < float2(0.0));
                    bool _704;
                    if (!_697)
                    {
                        _704 = any(_644 > float2(1.0));
                    }
                    else
                    {
                        _704 = _697;
                    }
                    if (_704)
                    {
                        _761 = 1.0;
                        break;
                    }
                    _761 = spvDepthCast(_74).sample_compare(_74Smplr, float3(_644, _518).xy, _518);
                    break;
                } while(false);
                _649 = _764 + ((_486[_758].x * _486[_752].y) * _761);
            }
        }
        _768 = _755 * (_550 ? 0.0625 : 0.0069444444961845874786376953125);
        break;
    } while(false);
    float _356 = dot(_303, _309);
    out.m_433 = float4(mix(mix((_772 * ((mix(float3(0.119999997317790985107421875, 0.100000001490116119384765625, 0.0900000035762786865234375), float3(0.550000011920928955078125, 0.64999997615814208984375, 0.85000002384185791015625), float3((_303.y * 0.5) + 0.5)) * 0.300000011920928955078125) + float3((fast::max(_356, 0.0) * _117._m2.w) * _768))) + float3(((powr(fast::max(dot(_303, fast::normalize(_309 + fast::normalize(_316))), 0.0), 48.0) * 0.3499999940395355224609375) * step(0.0, _356)) * _768), _772, float3(in.m_327.y)), _117._m4.xyz, float3(1.0 - exp((-length(_316)) * _117._m4.w))), in.m_324.w);
    float2 _778;
    do
    {
        if (in.m_450.w <= 0.0)
        {
            _778 = float2(0.0);
            break;
        }
        _778 = ((in.m_450.xy / float2(in.m_450.w)) - (in.m_449.xy / float2(in.m_449.w))) * float2(0.5, -0.5);
        break;
    } while(false);
    out.m_448 = _778;
    return out;
}

