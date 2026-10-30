#include <metal_stdlib>
using namespace metal;

// Must match `SceneUniforms` in main.swift.
struct Scene {
    float4x4 viewProj;
    float4x4 lightViewProj;
    float4 lightDir;      // xyz: direction toward the light, w: intensity
    float4 cameraPos;     // xyz: eye, w: time
    float4 fogColor;      // rgb: fog/sky color, w: density
    float4 shadowParams;  // x: shadow-map texel size, y: depth bias, z: PCF radius in texels
};

struct VertexIn {
    float3 position [[attribute(0)]];
    float3 normal   [[attribute(1)]];
    float4 model0   [[attribute(2)]];
    float4 model1   [[attribute(3)]];
    float4 model2   [[attribute(4)]];
    float4 model3   [[attribute(5)]];
    float4 color    [[attribute(6)]];  // a: opacity
    float4 params   [[attribute(7)]];  // x: checkerboard, y: emissive (0 lit .. 1 unlit)
};

struct VertexOut {
    float4 position [[position]];
    float3 worldPos;
    float3 normal;
    float4 color;
    float4 params;
    float4 lightClip;
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
    float3 position = in.position, normal = in.normal;
    float4 world;
    if (in.params.w > 0.0) {
        float3x3 r = spin(in.params, scene.cameraPos.w);
        position = r * position;
        normal = r * normal;
        world = model * float4(position, 1.0) + float4(0.0, bob(in.params, scene.cameraPos.w), 0.0, 0.0);
    } else {
        world = model * float4(position, 1.0);
    }
    // model = T * R * S, so R * (n / s) is the correctly transformed normal.
    float3 scaleSq = float3(dot(in.model0.xyz, in.model0.xyz), dot(in.model1.xyz, in.model1.xyz),
                            dot(in.model2.xyz, in.model2.xyz));
    float3x3 m3 = float3x3(in.model0.xyz, in.model1.xyz, in.model2.xyz);

    VertexOut out;
    out.position = scene.viewProj * world;
    out.worldPos = world.xyz;
    out.normal = m3 * (normal / scaleSq);
    out.color = in.color;
    out.params = in.params;
    out.lightClip = scene.lightViewProj * world;
    return out;
}

static float shadowFactor(constant Scene& scene, float4 lightClip, depth2d<float> shadowMap, sampler s) {
    float3 ndc = lightClip.xyz / lightClip.w;
    float2 uv = float2(ndc.x * 0.5 + 0.5, 0.5 - ndc.y * 0.5);
    float ref = min(ndc.z, 1.0) - scene.shadowParams.y;
    float texel = scene.shadowParams.x;
    int radius = int(scene.shadowParams.z);
    float sum = 0.0;
    for (int y = -radius; y <= radius; y++) {
        for (int x = -radius; x <= radius; x++) {
            sum += shadowMap.sample_compare(s, uv + float2(x, y) * texel, ref);
        }
    }
    float taps = float(2 * radius + 1);
    return sum / (taps * taps);
}

fragment float4 fragment_main(VertexOut in [[stage_in]], constant Scene& scene [[buffer(15)]],
                              depth2d<float> shadowMap [[texture(0)]], sampler shadowSampler [[sampler(0)]]) {
    float3 n = normalize(in.normal);
    float3 l = normalize(scene.lightDir.xyz);
    float3 v = normalize(scene.cameraPos.xyz - in.worldPos);
    float3 h = normalize(l + v);

    float3 albedo = in.color.rgb;
    if (in.params.x > 0.5) {
        float2 cell = floor(in.worldPos.xz / 2.0);
        albedo *= (fmod(abs(cell.x + cell.y), 2.0) < 0.5) ? 1.0 : 0.75;
    }

    float shadow = shadowFactor(scene, in.lightClip, shadowMap, shadowSampler);
    float diffuse = max(dot(n, l), 0.0) * scene.lightDir.w;
    float specular = pow(max(dot(n, h), 0.0), 48.0) * 0.35 * step(0.0, dot(n, l));
    float3 sky = float3(0.55, 0.65, 0.85), ground = float3(0.12, 0.1, 0.09);
    float3 ambient = mix(ground, sky, n.y * 0.5 + 0.5) * 0.3;

    float3 color = albedo * (ambient + diffuse * shadow) + specular * shadow;
    color = mix(color, albedo, in.params.y);
    float dist = length(scene.cameraPos.xyz - in.worldPos);
    float fog = 1.0 - exp(-dist * scene.fogColor.w);
    return float4(mix(color, scene.fogColor.rgb, fog), in.color.a);
}
