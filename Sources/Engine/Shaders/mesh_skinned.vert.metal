// Generated from mesh_skinned.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 324a672aa349d113
// glsl-fnv1a64: 46a53aeac7adbf40

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct _49
{
    float4 _m0[8];
    float4 _m1[384];
    float4 _m2[384];
};

struct _328
{
    float4x4 _m0;
    float4x4 _m1;
    float4x4 _m2;
    float4x4 _m3;
};

struct vertex_main_out
{
    float3 m_344 [[user(locn0)]];
    float3 m_347 [[user(locn1)]];
    float2 m_356 [[user(locn2)]];
    float4 m_360 [[user(locn3)]];
    float4 m_363 [[user(locn5)]];
    float4 m_366 [[user(locn6)]];
    float4 m_371 [[user(locn7)]];
    float4 m_376 [[user(locn8)]];
    float4 gl_Position [[position]];
};

struct vertex_main_in
{
    float3 m_260 [[attribute(0)]];
    float3 m_349 [[attribute(1)]];
    float2 m_358 [[attribute(2)]];
    float4 m_193 [[attribute(3)]];
    float4 m_195 [[attribute(4)]];
    float4 m_197 [[attribute(5)]];
    float4 m_199 [[attribute(6)]];
    float4 m_225 [[attribute(7)]];
    float4 m_227 [[attribute(8)]];
    float4 m_229 [[attribute(9)]];
    float4 m_231 [[attribute(10)]];
    float4 m_361 [[attribute(11)]];
    float4 m_364 [[attribute(12)]];
    float4 m_393 [[attribute(13)]];
    float4 m_35 [[attribute(14)]];
    float4 m_57 [[attribute(15)]];
};

vertex vertex_main_out vertex_main(vertex_main_in in [[stage_in]], constant _49& _51 [[buffer(2)]], constant _328& _330 [[buffer(15)]])
{
    vertex_main_out out = {};
    float4 _560;
    float4 _561;
    float4 _562;
    _562 = float4(0.0);
    _561 = float4(0.0);
    _560 = float4(0.0);
    for (int _559 = 0; _559 < 4; )
    {
        int _422 = int(in.m_35[_559]) * 3;
        _562 += (_51._m1[_422 + 2] * in.m_57[_559]);
        _561 += (_51._m1[_422 + 1] * in.m_57[_559]);
        _560 += (_51._m1[_422] * in.m_57[_559]);
        _559++;
        continue;
    }
    float4x4 _223 = float4x4(in.m_193, in.m_195, in.m_197, in.m_199) * transpose(float4x4(_560, _561, _562, float4(0.0, 0.0, 0.0, 1.0)));
    float4 _564;
    float4 _565;
    float4 _566;
    _566 = float4(0.0);
    _565 = float4(0.0);
    _564 = float4(0.0);
    for (int _563 = 0; _563 < 4; )
    {
        int _497 = int(in.m_35[_563]) * 3;
        _566 += (_51._m2[_497 + 2] * in.m_57[_563]);
        _565 += (_51._m2[_497 + 1] * in.m_57[_563]);
        _564 += (_51._m2[_497] * in.m_57[_563]);
        _563++;
        continue;
    }
    float4 _265 = float4(in.m_260, 1.0);
    float4 _266 = _223 * _265;
    float4 _278 = _223[0];
    float3 _279 = _278.xyz;
    float4 _282 = _223[1];
    float3 _283 = _282.xyz;
    float4 _286 = _223[2];
    float3 _287 = _286.xyz;
    float3 _299 = cross(_279, _283);
    float _322 = (dot(_299, _287) < 0.0) ? (-1.0) : 1.0;
    out.gl_Position = _330._m0 * _266;
    out.gl_Position.y = -out.gl_Position.y;
    out.m_344 = _266.xyz;
    out.m_347 = (float3x3(cross(_283, _287), cross(_287, _279), _299) * in.m_349) * _322;
    out.m_356 = in.m_358;
    out.m_360 = in.m_361;
    out.m_363 = in.m_364;
    out.m_366 = _330._m2 * _266;
    out.m_371 = _330._m3 * ((float4x4(in.m_225, in.m_227, in.m_229, in.m_231) * transpose(float4x4(_564, _565, _566, float4(0.0, 0.0, 0.0, 1.0)))) * _265);
    out.m_376 = float4(float3x3(float3(_278.xyz), float3(_282.xyz), float3(_286.xyz)) * in.m_393.xyz, in.m_393.w * _322);
    out.gl_Position.y = -(out.gl_Position.y);    // Invert Y-axis for Metal
    return out;
}

