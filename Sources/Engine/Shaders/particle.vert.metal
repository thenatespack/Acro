// Generated from particle.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: a3781f0a01d7fe6b
// glsl-fnv1a64: 5ec8cf158eeef8db

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

struct _24
{
    float4x4 _m0;
    float4 _m1;
    float4 _m2[4];
    float4 _m3;
    float4 _m4;
    float4 _m5;
    float4 _m6;
    float4 _m7;
};

struct _160
{
    float4 _m0;
    float4 _m1;
    float4 _m2;
};

struct _162
{
    _160 _m0[1];
};

struct _166
{
    uint _m0[1];
};

constant spvUnsafeArray<float2, 6> _194 = spvUnsafeArray<float2, 6>({ float2(-1.0), float2(1.0, -1.0), float2(1.0), float2(-1.0), float2(1.0), float2(-1.0, 1.0) });

struct vertex_main_out
{
    float2 m_371 [[user(locn0)]];
    float4 m_374 [[user(locn1)]];
    float4 gl_Position [[position]];
};

vertex vertex_main_out vertex_main(constant _24& _26 [[buffer(2)]], const device _162& _164 [[buffer(20)]], const device _166& _168 [[buffer(21)]], uint gl_InstanceIndex [[instance_id]], uint gl_VertexIndex [[vertex_id]])
{
    vertex_main_out out = {};
    float _209 = fast::clamp(_164._m0[_168._m0[int(gl_InstanceIndex)]]._m0.w / fast::max(_164._m0[_168._m0[int(gl_InstanceIndex)]]._m1.w, 9.9999997473787516355514526367188e-06), 0.0, 1.0);
    int _404 = int(_26._m7.y);
    float _537;
    _537 = _26._m4.x;
    float _538;
    for (int _534 = 1; _534 < 4; _534++, _537 = _538)
    {
        if (_534 >= _404)
        {
            break;
        }
        int _418 = _534 - 1;
        if (_209 > _26._m5[_418])
        {
            _538 = mix(_26._m4[_418], _26._m4[_534], fast::clamp((_209 - _26._m5[_418]) / fast::max(_26._m5[_534] - _26._m5[_418], 9.9999997473787516355514526367188e-06), 0.0, 1.0));
        }
        else
        {
            _538 = _537;
        }
    }
    float3 _228 = _26._m1.xyz - _164._m0[_168._m0[int(gl_InstanceIndex)]]._m0.xyz;
    float3 _539;
    if (dot(_228, _228) > 1.0000000133514319600180897396058e-10)
    {
        _539 = fast::normalize(_228);
    }
    else
    {
        _539 = float3(0.0, 0.0, 1.0);
    }
    float3 _257 = fast::normalize(cross(select(float3(1.0, 0.0, 0.0), float3(0.0, 1.0, 0.0), bool3(abs(_539.y) < 0.999000012874603271484375)), _539));
    float3 _261 = cross(_539, _257);
    float3 _274 = _164._m0[_168._m0[int(gl_InstanceIndex)]]._m1.xyz - (_539 * dot(_164._m0[_168._m0[int(gl_InstanceIndex)]]._m1.xyz, _539));
    float _277 = length(_274);
    float3 _540;
    float3 _541;
    float _542;
    if ((_26._m6.x > 0.0) && (_277 > 9.9999997473787516355514526367188e-05))
    {
        float3 _291 = _274 / float3(_277);
        _542 = 1.0 + (_26._m6.x * _277);
        _541 = _291;
        _540 = cross(_291, _539);
    }
    else
    {
        float _310 = _164._m0[_168._m0[int(gl_InstanceIndex)]]._m2.y + (_164._m0[_168._m0[int(gl_InstanceIndex)]]._m2.z * _164._m0[_168._m0[int(gl_InstanceIndex)]]._m0.w);
        float _313 = cos(_310);
        float _316 = sin(_310);
        _542 = 1.0;
        _541 = (_261 * _313) - (_257 * _316);
        _540 = (_257 * _313) + (_261 * _316);
    }
    int _460 = int(_26._m7.x);
    float4 _546;
    _546 = _26._m2[0];
    float4 _547;
    for (int _543 = 1; _543 < 4; _543++, _546 = _547)
    {
        if (_543 >= _460)
        {
            break;
        }
        int _474 = _543 - 1;
        if (_209 > _26._m3[_474])
        {
            _547 = mix(_26._m2[_474], _26._m2[_543], float4(fast::clamp((_209 - _26._m3[_474]) / fast::max(_26._m3[_543] - _26._m3[_474], 9.9999997473787516355514526367188e-06), 0.0, 1.0)));
        }
        else
        {
            _547 = _546;
        }
    }
    float3 _363 = _546.xyz * (_26._m6.y * mix(1.0, _164._m0[_168._m0[int(gl_InstanceIndex)]]._m2.w, _26._m6.z));
    float4 _529 = _546;
    _529.x = _363.x;
    _529.y = _363.y;
    _529.z = _363.z;
    out.m_371 = _194[int(gl_VertexIndex)];
    out.m_374 = _529;
    out.gl_Position = _26._m0 * float4(_164._m0[_168._m0[int(gl_InstanceIndex)]]._m0.xyz + (((_540 * _194[int(gl_VertexIndex)].x) + ((_541 * _194[int(gl_VertexIndex)].y) * _542)) * (_164._m0[_168._m0[int(gl_InstanceIndex)]]._m2.x * _537)), 1.0);
    out.gl_Position.y = -out.gl_Position.y;
    out.gl_Position.y = -(out.gl_Position.y);    // Invert Y-axis for Metal
    return out;
}

