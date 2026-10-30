#include <metal_stdlib>
using namespace metal;

// Must match `SceneUniforms` in Renderer.swift (buffer 15, set by `Renderer.bind`).
struct Scene {
    float4x4 viewProj;
    float4x4 lightViewProj;
    float4 lightDir;      // xyz: direction toward the light, w: intensity
    float4 cameraPos;     // xyz: eye, w: time
    float4 fogColor;      // rgb: fog/sky color, w: density
    float4 shadowParams;
    float4x4 currentViewProj;   // unjittered, for motion vectors
    float4x4 previousViewProj;  // last frame's, unjittered
};

// Uniform buffers bound by the scene: `Params` at buffer(2) (static GPUBuffer), `FrameData` at
// buffer(3) (per-frame data). Texture and sampler at index 1.
struct Params {
    float4 uvScale;  // xy: world-to-UV scale
    float4 tint;
};

struct FrameData {
    float4 scroll;   // xy: UV offset
};

struct VertexIn {
    float3 position [[attribute(0)]];
    float3 normal   [[attribute(1)]];
    float4 model0   [[attribute(2)]];
    float4 model1   [[attribute(3)]];
    float4 model2   [[attribute(4)]];
    float4 model3   [[attribute(5)]];
    float4 color    [[attribute(6)]];
};

struct VertexOut {
    float4 position [[position]];
    float3 worldPos;
    float3 normal;
    float2 uv;
    float4 currentClip;   // unjittered, for motion vectors
    float4 previousClip;
};

struct FragmentOut {
    float4 color [[color(0)]];
    float2 motion [[color(1)]];  // see `PipelineDescriptor.writesMotionVectors`
};

// Planar projection along the dominant axis of the (axis-aligned) face normal.
static float2 projectUV(float3 world, float3 normal) {
    float3 a = abs(normal);
    if (a.y >= a.x && a.y >= a.z) return world.xz;
    return a.x >= a.z ? world.zy : world.xy;
}

vertex VertexOut vertex_main(VertexIn in [[stage_in]], constant Scene& scene [[buffer(15)]],
                             constant Params& params [[buffer(2)]], constant FrameData& frame [[buffer(3)]]) {
    float4x4 model = float4x4(in.model0, in.model1, in.model2, in.model3);
    float4 world = model * float4(in.position, 1.0);
    VertexOut out;
    out.position = scene.viewProj * world;
    out.worldPos = world.xyz;
    out.normal = in.normal;
    out.uv = projectUV(world.xyz, in.normal) * params.uvScale.xy + frame.scroll.xy;
    // Static geometry: only the camera moves.
    out.currentClip = scene.currentViewProj * world;
    out.previousClip = scene.previousViewProj * world;
    return out;
}

fragment FragmentOut fragment_main(VertexOut in [[stage_in]], constant Scene& scene [[buffer(15)]],
                                   constant Params& params [[buffer(2)]],
                                   texture2d<float> albedoMap [[texture(1)]], sampler albedoSampler [[sampler(1)]]) {
    float3 albedo = albedoMap.sample(albedoSampler, in.uv).rgb * params.tint.rgb;
    float3 n = normalize(in.normal);
    float3 l = normalize(scene.lightDir.xyz);
    float diffuse = max(dot(n, l), 0.0) * scene.lightDir.w;
    float3 sky = float3(0.55, 0.65, 0.85), ground = float3(0.12, 0.1, 0.09);
    float3 ambient = mix(ground, sky, n.y * 0.5 + 0.5) * 0.3;
    float3 color = albedo * (ambient + diffuse);
    float dist = length(scene.cameraPos.xyz - in.worldPos);
    float fog = 1.0 - exp(-dist * scene.fogColor.w);
    FragmentOut out;
    out.color = float4(mix(color, scene.fogColor.rgb, fog), 1.0);
    float4 current = in.currentClip, previous = in.previousClip;
    out.motion = previous.w > 0.0 ? (previous.xy / previous.w - current.xy / current.w) * float2(0.5, -0.5) : float2(0.0);
    return out;
}
