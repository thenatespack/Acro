#include <metal_stdlib>
using namespace metal;

// Draws the offscreen scene image into the window. A fullscreen triangle scaled by
// `scale` (≤ 1 per axis) letterboxes it while keeping its aspect ratio.

struct PushConstants {
    float2 scale;
};

struct VertexOut {
    float4 position [[position]];
    float2 uv;
};

vertex VertexOut vertex_main(uint vid [[vertex_id]], constant PushConstants& pc [[buffer(16)]]) {
    float2 p = float2((vid << 1) & 2, vid & 2);
    VertexOut out;
    out.position = float4((p * 2.0 - 1.0) * pc.scale, 0.0, 1.0);
    out.uv = float2(p.x, 1.0 - p.y);
    return out;
}

fragment float4 fragment_main(VertexOut in [[stage_in]], texture2d<float> image [[texture(0)]],
                              sampler imageSampler [[sampler(0)]]) {
    return float4(image.sample(imageSampler, in.uv).rgb, 1.0);
}
