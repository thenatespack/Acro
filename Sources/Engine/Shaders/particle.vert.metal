// Generated from particle.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: d1b36d15948f0ddb
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
    float2 m_419 [[user(locn0)]];
    float4 m_422 [[user(locn1)]];
    float4 m_424 [[user(locn2)]];
    float m_427 [[user(locn3)]];
    float4 gl_Position [[position]];
};

vertex vertex_main_out vertex_main(constant _31& _33 [[buffer(2)]], const device _192& _194 [[buffer(20)]], const device _196& _198 [[buffer(21)]], uint gl_InstanceIndex [[instance_id]], uint gl_VertexIndex [[vertex_id]])
{
    vertex_main_out out = {};
    float _237 = fast::clamp(_194._m0[_198._m0[int(gl_InstanceIndex)]]._m0.w / fast::max(_194._m0[_198._m0[int(gl_InstanceIndex)]]._m1.w, 9.9999997473787516355514526367188e-06), 0.0, 1.0);
    int _565 = int(_33._m7.y);
    float _749;
    _749 = _33._m4.x;
    float _750;
    for (int _746 = 1; _746 < 4; _746++, _749 = _750)
    {
        if (_746 >= _565)
        {
            break;
        }
        int _579 = _746 - 1;
        if (_237 > _33._m5[_579])
        {
            _750 = mix(_33._m4[_579], _33._m4[_746], fast::clamp((_237 - _33._m5[_579]) / fast::max(_33._m5[_746] - _33._m5[_579], 9.9999997473787516355514526367188e-06), 0.0, 1.0));
        }
        else
        {
            _750 = _749;
        }
    }
    float3 _256 = _33._m1.xyz - _194._m0[_198._m0[int(gl_InstanceIndex)]]._m0.xyz;
    float3 _751;
    if (dot(_256, _256) > 1.0000000133514319600180897396058e-10)
    {
        _751 = fast::normalize(_256);
    }
    else
    {
        _751 = float3(0.0, 0.0, 1.0);
    }
    float3 _285 = fast::normalize(cross(select(float3(1.0, 0.0, 0.0), float3(0.0, 1.0, 0.0), bool3(abs(_751.y) < 0.999000012874603271484375)), _751));
    float3 _289 = cross(_751, _285);
    float3 _303 = _194._m0[_198._m0[int(gl_InstanceIndex)]]._m1.xyz - (_751 * dot(_194._m0[_198._m0[int(gl_InstanceIndex)]]._m1.xyz, _751));
    float _306 = length(_303);
    float3 _752;
    float3 _754;
    float _756;
    float _758;
    if ((_33._m6.x > 0.0) && (_306 > 9.9999997473787516355514526367188e-05))
    {
        float3 _320 = _303 / float3(_306);
        float _757;
        float _759;
        if (_33._m6.w > 0.5)
        {
            _759 = (0.5 * _33._m6.x) * _306;
            _757 = 1.0;
        }
        else
        {
            _759 = 0.0;
            _757 = 1.0 + (_33._m6.x * _306);
        }
        _758 = _759;
        _756 = _757;
        _754 = _320;
        _752 = cross(_320, _751);
    }
    else
    {
        float _351 = _194._m0[_198._m0[int(gl_InstanceIndex)]]._m2.y + (_194._m0[_198._m0[int(gl_InstanceIndex)]]._m2.z * _194._m0[_198._m0[int(gl_InstanceIndex)]]._m0.w);
        float _354 = cos(_351);
        float _357 = sin(_351);
        _758 = 0.0;
        _756 = 1.0;
        _754 = (_289 * _354) - (_285 * _357);
        _752 = (_285 * _354) + (_289 * _357);
    }
    int _621 = int(_33._m7.x);
    float4 _763;
    _763 = _33._m2[0];
    float4 _764;
    for (int _760 = 1; _760 < 4; _760++, _763 = _764)
    {
        if (_760 >= _621)
        {
            break;
        }
        int _635 = _760 - 1;
        if (_237 > _33._m3[_635])
        {
            _764 = mix(_33._m2[_635], _33._m2[_760], float4(fast::clamp((_237 - _33._m3[_635]) / fast::max(_33._m3[_760] - _33._m3[_635], 9.9999997473787516355514526367188e-06), 0.0, 1.0)));
        }
        else
        {
            _764 = _763;
        }
    }
    float3 _411 = _763.xyz * (_33._m6.y * mix(1.0, _194._m0[_198._m0[int(gl_InstanceIndex)]]._m2.w, _33._m6.z));
    float4 _737 = _763;
    _737.x = _411.x;
    _737.y = _411.y;
    _737.z = _411.z;
    out.m_419 = _222[int(gl_VertexIndex)];
    out.m_422 = _737;
    out.m_424 = float4(0.0);
    out.m_427 = 0.0;
    if (_33._m9.z > 0.5)
    {
        bool _440 = _33._m8.w > 0.0;
        float _765;
        if (_440)
        {
            _765 = _194._m0[_198._m0[int(gl_InstanceIndex)]]._m0.w * _33._m8.w;
        }
        else
        {
            _765 = _237 * _33._m8.z;
        }
        bool _456 = _33._m9.x > 0.5;
        float _767;
        if (_456)
        {
            _767 = _765 + floor(_194._m0[_198._m0[int(gl_InstanceIndex)]]._m2.w * _33._m8.z);
        }
        else
        {
            _767 = _765;
        }
        float _480 = floor(_767);
        float _768;
        if (_33._m9.y > 0.5)
        {
            _768 = _767 - _480;
        }
        else
        {
            _768 = 0.0;
        }
        out.m_427 = _768;
        float _494 = _480 + 1.0;
        float _770;
        float _771;
        if ((!_440) ? _456 : _440)
        {
            _771 = mod(_494, _33._m8.z);
            _770 = mod(_480, _33._m8.z);
        }
        else
        {
            float _507 = _33._m8.z - 1.0;
            _771 = fast::min(_494, _507);
            _770 = fast::min(_480, _507);
        }
        float2 _522 = float2((_222[int(gl_VertexIndex)].x * 0.5) + 0.5, 0.5 - (_222[int(gl_VertexIndex)].y * 0.5));
        out.m_424 = float4((float2(mod(_770, _33._m8.x), floor(_770 / _33._m8.x)) + _522) / _33._m8.xy, (float2(mod(_771, _33._m8.x), floor(_771 / _33._m8.x)) + _522) / _33._m8.xy);
    }
    out.gl_Position = _33._m0 * float4((_194._m0[_198._m0[int(gl_InstanceIndex)]]._m0.xyz + (((_752 * _222[int(gl_VertexIndex)].x) + ((_754 * _222[int(gl_VertexIndex)].y) * _756)) * (_194._m0[_198._m0[int(gl_InstanceIndex)]]._m2.x * _749))) + (_754 * (_222[int(gl_VertexIndex)].y * _758)), 1.0);
    out.gl_Position.y = -out.gl_Position.y;
    out.gl_Position.y = -(out.gl_Position.y);    // Invert Y-axis for Metal
    return out;
}

