// Generated from textures.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: a1e636f739047e9e
// glsl-fnv1a64: d485bc52c10c6349

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct _112
{
    float4x4 _m0;
    float4x4 _m1;
    float4 _m2;
    float4 _m3;
    float4 _m4;
    float4 _m5;
    float4x4 _m6;
    float4x4 _m7;
};

struct _142
{
    float4 _m0;
    float4 _m1;
};

struct _150
{
    float4 _m0;
};

struct vertex_main_out
{
    float3 m_128 [[user(locn0)]];
    float3 m_131 [[user(locn1)]];
    float2 m_135 [[user(locn2)]];
    float4 m_157 [[user(locn3)]];
    float4 m_163 [[user(locn4)]];
    float4 gl_Position [[position]];
};

struct vertex_main_in
{
    float3 m_99 [[attribute(0)]];
    float3 m_132 [[attribute(1)]];
    float4 m_64 [[attribute(2)]];
    float4 m_66 [[attribute(3)]];
    float4 m_68 [[attribute(4)]];
    float4 m_70 [[attribute(5)]];
};

vertex vertex_main_out vertex_main(vertex_main_in in [[stage_in]], constant _142& _144 [[buffer(2)]], constant _150& _152 [[buffer(3)]], constant _112& _114 [[buffer(15)]])
{
    vertex_main_out out = {};
    float4 _105 = float4x4(in.m_64, in.m_66, in.m_68, in.m_70) * float4(in.m_99, 1.0);
    out.gl_Position = _114._m0 * _105;
    out.gl_Position.y = -out.gl_Position.y;
    out.m_128 = _105.xyz;
    out.m_131 = in.m_132;
    float2 _225;
    do
    {
        float3 _185 = abs(in.m_132);
        float _187 = _185.y;
        float _189 = _185.x;
        bool _190 = _187 >= _189;
        bool _198;
        if (_190)
        {
            _198 = _187 >= _185.z;
        }
        else
        {
            _198 = _190;
        }
        if (_198)
        {
            _225 = _105.xz;
            break;
        }
        float2 _224;
        if (_189 >= _185.z)
        {
            _224 = _105.zy;
        }
        else
        {
            _224 = _105.xy;
        }
        _225 = _224;
        break;
    } while(false);
    out.m_135 = (_225 * _144._m0.xy) + _152._m0.xy;
    out.m_157 = _114._m6 * _105;
    out.m_163 = _114._m7 * _105;
    out.gl_Position.y = -(out.gl_Position.y);    // Invert Y-axis for Metal
    return out;
}

