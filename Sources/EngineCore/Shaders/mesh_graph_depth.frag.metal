// Generated from mesh_graph_depth.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 0bd754cb995ec690
// glsl-fnv1a64: e95aa0259a7e4a0f

#pragma clang diagnostic ignored "-Wmissing-prototypes"

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct MaterialGraphValues
{
    float4 values[1];
};

struct MaterialGraphPush
{
    float4 params;
    float4 eye;
};

struct fragment_main_in
{
    float3 vWorldPos [[user(locn0)]];
    float3 vNormal [[user(locn1)]];
    float2 vUV [[user(locn2)]];
    float4 vColor [[user(locn3)]];
};

static inline __attribute__((always_inline))
void graphSurface(texture2d<float> baseColorMap, sampler materialSampler, thread float2& gUV, texture2d<float> metallicRoughnessMap, texture2d<float> normalMap, texture2d<float> occlusionMap, texture2d<float> emissiveMap, const device MaterialGraphValues& graphValues, thread float3& gBaseColor, thread float4& gVertexColor, thread float3& gPosition, thread float3& gNormal, thread float3& gView, thread float& gTime, thread float& gOpacity, thread float3& gNormalTS, thread float& gMetallic, thread float& gRoughness, thread float3& gEmissive, thread float& gOcclusion)
{
    float4 a = baseColorMap.sample(materialSampler, gUV);
    float4 b = metallicRoughnessMap.sample(materialSampler, gUV);
    float4 c = normalMap.sample(materialSampler, gUV);
    float4 d = occlusionMap.sample(materialSampler, gUV);
    float4 e = emissiveMap.sample(materialSampler, gUV);
    float4 v = graphValues.values[0];
    gBaseColor = ((a.xyz * gVertexColor.xyz) * v.xyz) + (((gPosition + gNormal) + gView) * gTime);
    gOpacity = a.w * v.w;
    gNormalTS = (c.xyz * 2.0) - float3(1.0);
    gMetallic = b.z;
    gRoughness = b.y;
    gEmissive = e.xyz;
    gOcclusion = d.x;
}

fragment void fragment_main(fragment_main_in in [[stage_in]], constant MaterialGraphPush& graphPush [[buffer(16)]], const device MaterialGraphValues& graphValues [[buffer(20)]], texture2d<float> baseColorMap [[texture(1)]], texture2d<float> metallicRoughnessMap [[texture(2)]], texture2d<float> normalMap [[texture(3)]], texture2d<float> occlusionMap [[texture(4)]], texture2d<float> emissiveMap [[texture(5)]], sampler materialSampler [[sampler(1)]])
{
    float2 gUV = in.vUV;
    float3 gPosition = in.vWorldPos;
    float3 gNormal = fast::normalize(in.vNormal);
    float3 gView = fast::normalize(graphPush.eye.xyz - in.vWorldPos);
    float4 gVertexColor = in.vColor;
    float gTime = graphPush.params.x;
    float3 gBaseColor;
    float gOpacity;
    float3 gNormalTS;
    float gMetallic;
    float gRoughness;
    float3 gEmissive;
    float gOcclusion;
    graphSurface(baseColorMap, materialSampler, gUV, metallicRoughnessMap, normalMap, occlusionMap, emissiveMap, graphValues, gBaseColor, gVertexColor, gPosition, gNormal, gView, gTime, gOpacity, gNormalTS, gMetallic, gRoughness, gEmissive, gOcclusion);
    if (gOpacity < graphPush.params.z)
    {
        discard_fragment();
    }
}

