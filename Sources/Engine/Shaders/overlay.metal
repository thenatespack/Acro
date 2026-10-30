#include <metal_stdlib>
using namespace metal;

// 2D overlay: positions in framebuffer pixels (top-left origin), per-vertex RGBA.

struct VertexIn {
    float2 position [[attribute(0)]];
    float4 color    [[attribute(1)]];
};

struct PushConstants {
    float2 screenSize;
};

struct VertexOut {
    float4 position [[position]];
    float4 color;
};

vertex VertexOut vertex_main(VertexIn in [[stage_in]],
                             constant PushConstants& pc [[buffer(16)]]) {
    VertexOut out;
    float2 ndc = float2(in.position.x / pc.screenSize.x * 2.0 - 1.0,
                        1.0 - in.position.y / pc.screenSize.y * 2.0);
    out.position = float4(ndc, 0.0, 1.0);
    out.color = in.color;
    return out;
}

fragment float4 fragment_main(VertexOut in [[stage_in]]) {
    return in.color;
}
