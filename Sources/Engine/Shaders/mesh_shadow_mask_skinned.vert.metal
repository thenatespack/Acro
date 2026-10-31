// Generated from mesh_shadow_mask_skinned.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: b184a6e38a740ade
// glsl-fnv1a64: 5613634b618901fa

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct _47
{
    float4 _m0[8];
    float4 _m1[384];
    float4 _m2[384];
};

struct _152
{
    float4x4 _m0;
    float4x4 _m1;
};

struct vertex_main_out
{
    float2 m_178 [[user(locn0)]];
    float4 gl_Position [[position]];
};

struct vertex_main_in
{
    float3 m_161 [[attribute(0)]];
    float2 m_180 [[attribute(2)]];
    float4 m_116 [[attribute(3)]];
    float4 m_118 [[attribute(4)]];
    float4 m_120 [[attribute(5)]];
    float4 m_122 [[attribute(6)]];
    float4 m_33 [[attribute(14)]];
    float4 m_55 [[attribute(15)]];
};

vertex vertex_main_out vertex_main(vertex_main_in in [[stage_in]], constant _47& _49 [[buffer(2)]], constant _152& _154 [[buffer(15)]])
{
    vertex_main_out out = {};
    float4 _258;
    float4 _259;
    float4 _260;
    _260 = float4(0.0);
    _259 = float4(0.0);
    _258 = float4(0.0);
    for (int _257 = 0; _257 < 4; )
    {
        int _198 = int(in.m_33[_257]) * 3;
        _260 += (_49._m1[_198 + 2] * in.m_55[_257]);
        _259 += (_49._m1[_198 + 1] * in.m_55[_257]);
        _258 += (_49._m1[_198] * in.m_55[_257]);
        _257++;
        continue;
    }
    out.gl_Position = _154._m1 * ((float4x4(in.m_116, in.m_118, in.m_120, in.m_122) * transpose(float4x4(_258, _259, _260, float4(0.0, 0.0, 0.0, 1.0)))) * float4(in.m_161, 1.0));
    out.gl_Position.y = -out.gl_Position.y;
    out.m_178 = in.m_180;
    out.gl_Position.y = -(out.gl_Position.y);    // Invert Y-axis for Metal
    return out;
}

