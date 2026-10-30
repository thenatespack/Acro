#include <metal_stdlib>
using namespace metal;

// Depth-only pass: same uniforms and vertex layout as lit.metal, no fragment stage.
struct Scene {
    float4x4 viewProj;
    float4x4 lightViewProj;
    float4 lightDir;
    float4 cameraPos;
    float4 fogColor;
    float4 shadowParams;
};

struct VertexIn {
    float3 position [[attribute(0)]];
    float4 model0   [[attribute(2)]];
    float4 model1   [[attribute(3)]];
    float4 model2   [[attribute(4)]];
    float4 model3   [[attribute(5)]];
    float4 params   [[attribute(7)]];
};

struct VertexOut {
    float4 position [[position]];
};

// Instances with params.w > 0 spin about their local Y axis (1 rad/s) and bob vertically
// (amplitude params.w, 2 rad/s), offset by phase params.z. See `Instance.animated`.
static float3x3 spin(float4 params, float time) {
    float c = cos(time + params.z), s = sin(time + params.z);
    return float3x3(float3(c, 0.0, -s), float3(0.0, 1.0, 0.0), float3(s, 0.0, c));
}

static float bob(float4 params, float time) {
    return sin(time * 2.0 + params.z) * params.w;
}

vertex VertexOut vertex_main(VertexIn in [[stage_in]], constant Scene& scene [[buffer(15)]]) {
    float4x4 model = float4x4(in.model0, in.model1, in.model2, in.model3);
    float4 world;
    if (in.params.w > 0.0) {
        world = model * float4(spin(in.params, scene.cameraPos.w) * in.position, 1.0)
            + float4(0.0, bob(in.params, scene.cameraPos.w), 0.0, 0.0);
    } else {
        world = model * float4(in.position, 1.0);
    }
    VertexOut out;
    out.position = scene.lightViewProj * world;
    return out;
}
