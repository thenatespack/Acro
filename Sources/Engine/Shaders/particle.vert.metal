// Generated from particle.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: bf25164f2de3afaa
// glsl-fnv1a64: 79f4205eb434eb36

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

struct _31
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

struct _190
{
    float4 _m0;
    float4 _m1;
    float4 _m2;
};

struct _192
{
    _190 _m0[1];
};

struct _196
{
    uint _m0[1];
};

constant spvUnsafeArray<float2, 6> _222 = spvUnsafeArray<float2, 6>({ float2(-1.0), float2(1.0, -1.0), float2(1.0), float2(-1.0), float2(1.0), float2(-1.0, 1.0) });

struct vertex_main_out
{
    float2 m_399 [[user(locn0)]];
    float4 m_402 [[user(locn1)]];
    float4 m_404 [[user(locn2)]];
    float m_407 [[user(locn3)]];
    float4 gl_Position [[position]];
};

vertex vertex_main_out vertex_main(constant _31& _33 [[buffer(2)]], const device _192& _194 [[buffer(20)]], const device _196& _198 [[buffer(21)]], uint gl_InstanceIndex [[instance_id]], uint gl_VertexIndex [[vertex_id]])
{
    vertex_main_out out = {};
    float _237 = fast::clamp(_194._m0[_198._m0[int(gl_InstanceIndex)]]._m0.w / fast::max(_194._m0[_198._m0[int(gl_InstanceIndex)]]._m1.w, 9.9999997473787516355514526367188e-06), 0.0, 1.0);
    int _546 = int(_33._m7.y);
    float _729;
    _729 = _33._m4.x;
    float _730;
    for (int _726 = 1; _726 < 4; _726++, _729 = _730)
    {
        if (_726 >= _546)
        {
            break;
        }
        int _560 = _726 - 1;
        if (_237 > _33._m5[_560])
        {
            _730 = mix(_33._m4[_560], _33._m4[_726], fast::clamp((_237 - _33._m5[_560]) / fast::max(_33._m5[_726] - _33._m5[_560], 9.9999997473787516355514526367188e-06), 0.0, 1.0));
        }
        else
        {
            _730 = _729;
        }
    }
    float3 _256 = _33._m1.xyz - _194._m0[_198._m0[int(gl_InstanceIndex)]]._m0.xyz;
    float3 _731;
    if (dot(_256, _256) > 1.0000000133514319600180897396058e-10)
    {
        _731 = fast::normalize(_256);
    }
    else
    {
        _731 = float3(0.0, 0.0, 1.0);
    }
    float3 _285 = fast::normalize(cross(select(float3(1.0, 0.0, 0.0), float3(0.0, 1.0, 0.0), bool3(abs(_731.y) < 0.999000012874603271484375)), _731));
    float3 _289 = cross(_731, _285);
    float3 _302 = _194._m0[_198._m0[int(gl_InstanceIndex)]]._m1.xyz - (_731 * dot(_194._m0[_198._m0[int(gl_InstanceIndex)]]._m1.xyz, _731));
    float _305 = length(_302);
    float3 _732;
    float3 _733;
    float _734;
    if ((_33._m6.x > 0.0) && (_305 > 9.9999997473787516355514526367188e-05))
    {
        float3 _319 = _302 / float3(_305);
        _734 = 1.0 + (_33._m6.x * _305);
        _733 = _319;
        _732 = cross(_319, _731);
    }
    else
    {
        float _338 = _194._m0[_198._m0[int(gl_InstanceIndex)]]._m2.y + (_194._m0[_198._m0[int(gl_InstanceIndex)]]._m2.z * _194._m0[_198._m0[int(gl_InstanceIndex)]]._m0.w);
        float _341 = cos(_338);
        float _344 = sin(_338);
        _734 = 1.0;
        _733 = (_289 * _341) - (_285 * _344);
        _732 = (_285 * _341) + (_289 * _344);
    }
    int _602 = int(_33._m7.x);
    float4 _738;
    _738 = _33._m2[0];
    float4 _739;
    for (int _735 = 1; _735 < 4; _735++, _738 = _739)
    {
        if (_735 >= _602)
        {
            break;
        }
        int _616 = _735 - 1;
        if (_237 > _33._m3[_616])
        {
            _739 = mix(_33._m2[_616], _33._m2[_735], float4(fast::clamp((_237 - _33._m3[_616]) / fast::max(_33._m3[_735] - _33._m3[_616], 9.9999997473787516355514526367188e-06), 0.0, 1.0)));
        }
        else
        {
            _739 = _738;
        }
    }
    float3 _391 = _738.xyz * (_33._m6.y * mix(1.0, _194._m0[_198._m0[int(gl_InstanceIndex)]]._m2.w, _33._m6.z));
    float4 _717 = _738;
    _717.x = _391.x;
    _717.y = _391.y;
    _717.z = _391.z;
    out.m_399 = _222[int(gl_VertexIndex)];
    out.m_402 = _717;
    out.m_404 = float4(0.0);
    out.m_407 = 0.0;
    if (_33._m9.z > 0.5)
    {
        bool _421 = _33._m8.w > 0.0;
        float _740;
        if (_421)
        {
            _740 = _194._m0[_198._m0[int(gl_InstanceIndex)]]._m0.w * _33._m8.w;
        }
        else
        {
            _740 = _237 * _33._m8.z;
        }
        bool _437 = _33._m9.x > 0.5;
        float _742;
        if (_437)
        {
            _742 = _740 + floor(_194._m0[_198._m0[int(gl_InstanceIndex)]]._m2.w * _33._m8.z);
        }
        else
        {
            _742 = _740;
        }
        float _461 = floor(_742);
        float _743;
        if (_33._m9.y > 0.5)
        {
            _743 = _742 - _461;
        }
        else
        {
            _743 = 0.0;
        }
        out.m_407 = _743;
        float _475 = _461 + 1.0;
        float _745;
        float _746;
        if ((!_421) ? _437 : _421)
        {
            _746 = mod(_475, _33._m8.z);
            _745 = mod(_461, _33._m8.z);
        }
        else
        {
            float _488 = _33._m8.z - 1.0;
            _746 = fast::min(_475, _488);
            _745 = fast::min(_461, _488);
        }
        float2 _503 = float2((_222[int(gl_VertexIndex)].x * 0.5) + 0.5, 0.5 - (_222[int(gl_VertexIndex)].y * 0.5));
        out.m_404 = float4((float2(mod(_745, _33._m8.x), floor(_745 / _33._m8.x)) + _503) / _33._m8.xy, (float2(mod(_746, _33._m8.x), floor(_746 / _33._m8.x)) + _503) / _33._m8.xy);
    }
    out.gl_Position = _33._m0 * float4(_194._m0[_198._m0[int(gl_InstanceIndex)]]._m0.xyz + (((_732 * _222[int(gl_VertexIndex)].x) + ((_733 * _222[int(gl_VertexIndex)].y) * _734)) * (_194._m0[_198._m0[int(gl_InstanceIndex)]]._m2.x * _729)), 1.0);
    out.gl_Position.y = -out.gl_Position.y;
    out.gl_Position.y = -(out.gl_Position.y);    // Invert Y-axis for Metal
    return out;
}

