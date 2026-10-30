#include <metal_stdlib>
using namespace metal;

// Temporal anti-aliasing upsample (TAAU). Runs at the output size and writes the next history:
// rgb = gamma-encoded color, a = accumulated sample weight. For each output pixel:
// 1. Load the 3x3 render pixels around it. Each was sampled at its center minus this frame's
//    jitter, so its distance to the output pixel is known.
// 2. Current estimate: their weighted average, with a narrow kernel in output pixels, so a
//    sample only counts toward output pixels it lands near. Over the jitter sequence that
//    resolves detail finer than a render pixel. A wide kernel (in render pixels) fills in
//    where there is no history yet.
// 3. Reproject: the motion vector of the nearest surface in the 3x3 (depth dilation, so edges
//    move with the foreground) gives the pixel's position last frame. The history is
//    resampled there with a 4x4 Catmull-Rom filter.
// 4. Clamp the history to the current neighborhood's color box in YCoCg (variance clipping,
//    within min/max) to reject stale colors: disocclusions, shading changes, and objects that
//    moved without motion vectors.
// 5. Blend by weight: the new sample's against the history's, capped so the history keeps
//    adapting.
// Every read is a texel load and the math is plain arithmetic (no filtering hardware), so
// Metal and Vulkan produce identical results. Keep in sync with taau.frag.

struct PushConstants {
    float2 inputPerOutput;  // render pixels per output pixel
    float2 outputPerInput;
    float2 jitter;          // this frame's jitter in render pixels
    float2 outputSize;
    int2 inputMax;          // render size - 1
    int2 outputMax;         // output size - 1
    float reset;            // 1: no usable history
    float reversedDepth;    // 1: depth 1 is near
};

struct VertexOut {
    float4 position [[position]];
};

// Fullscreen triangle (reads texels by pixel position, so no UVs needed).
vertex VertexOut vertex_main(uint vid [[vertex_id]]) {
    float2 p = float2((vid << 1) & 2, vid & 2);
    VertexOut out;
    out.position = float4(p * 2.0 - 1.0, 0.0, 1.0);
    return out;
}

// Cap on the history's accumulated weight: at most 1/13 of a full-weight sample is blended in per frame.
constant float maxHistoryWeight = 12.0;
// Width of the clamp box, in standard deviations of the neighborhood.
constant float clampSigmas = 1.25;

static float3 toYCoCg(float3 c) {
    return float3(c.r * 0.25 + c.g * 0.5 + c.b * 0.25, c.r * 0.5 - c.b * 0.5, c.g * 0.5 - c.r * 0.25 - c.b * 0.25);
}

static float3 toRGB(float3 c) {
    return float3(c.x + c.y - c.z, c.x + c.z, c.x - c.y - c.z);
}

// Smooth bump: 1 at d² = 0, falling to 0 at d² = 1 (a cheap stand-in for a Gaussian).
static float bump(float d2) {
    float w = max(1.0 - d2, 0.0);
    return w * w;
}

static float3 loadHistory(texture2d<float> history, int2 p, int2 outputMax) {
    return history.read(uint2(clamp(p, int2(0), outputMax))).rgb;
}

fragment float4 fragment_main(VertexOut in [[stage_in]], constant PushConstants& pc [[buffer(16)]],
                              texture2d<float> color [[texture(1)]], depth2d<float> depth [[texture(2)]],
                              texture2d<float> motion [[texture(3)]], texture2d<float> history [[texture(4)]]) {
    float2 outPos = in.position.xy;
    // The output pixel's center in unjittered render pixels; render pixel i was sampled at
    // i + 0.5 - jitter, so `center` is the sample nearest to it.
    float2 renderPos = outPos * pc.inputPerOutput;
    int2 center = int2(floor(renderPos + pc.jitter));
    float2 centerOffset = float2(center) + 0.5 - pc.jitter - renderPos;
    bool reversed = pc.reversedDepth > 0.5;

    float3 wideSum = float3(0.0), narrowSum = float3(0.0), m1 = float3(0.0), m2 = float3(0.0);
    float3 lo = float3(1e9), hi = float3(-1e9);
    float wideWeight = 0.0, narrowWeight = 0.0;
    float nearestDepth = reversed ? -1.0 : 2.0;
    int2 nearest = center;
    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            int2 p = clamp(center + int2(x, y), int2(0), pc.inputMax);
            float3 c = toYCoCg(color.read(uint2(p)).rgb);
            float2 d = centerOffset + float2(x, y);      // in render pixels
            float2 dOut = d * pc.outputPerInput;          // in output pixels
            float wide = bump(dot(d, d) * (1.0 / 2.25)); // radius 1.5 render pixels
            float narrow = bump(dot(dOut, dOut));        // radius 1 output pixel
            wideSum += c * wide;
            wideWeight += wide;
            narrowSum += c * narrow;
            narrowWeight += narrow;
            m1 += c;
            m2 += c * c;
            lo = min(lo, c);
            hi = max(hi, c);
            float z = depth.read(uint2(p));
            if (reversed ? z > nearestDepth : z < nearestDepth) {
                nearestDepth = z;
                nearest = p;
            }
        }
    }
    float3 wideColor = wideSum / wideWeight;
    float3 current = narrowWeight > 1.0 / 1024.0 ? narrowSum / narrowWeight : wideColor;
    float sampleWeight = min(narrowWeight, 1.0);

    // Where this surface was last frame, in output pixels.
    float2 previous = outPos + motion.read(uint2(nearest)).xy * pc.outputSize;
    bool valid = pc.reset < 0.5 && all(previous >= float2(0.0)) && all(previous <= pc.outputSize);
    if (!valid) {
        return float4(toRGB(wideColor), sampleWeight);
    }

    // 4x4 Catmull-Rom around the previous position.
    float2 t = previous - 0.5;
    float2 f = floor(t);
    float2 s = t - f;
    int2 base = int2(f) - 1;
    float2 w0 = s * (-0.5 + s * (1.0 - 0.5 * s));
    float2 w1 = 1.0 + s * s * (-2.5 + 1.5 * s);
    float2 w2 = s * (0.5 + s * (2.0 - 1.5 * s));
    float2 w3 = s * s * (-0.5 + 0.5 * s);
    float wx[4] = {w0.x, w1.x, w2.x, w3.x};
    float wy[4] = {w0.y, w1.y, w2.y, w3.y};
    float3 h = float3(0.0);
    for (int j = 0; j < 4; j++) {
        float3 row = float3(0.0);
        for (int i = 0; i < 4; i++) {
            row += loadHistory(history, base + int2(i, j), pc.outputMax) * wx[i];
        }
        h += row * wy[j];
    }
    float historyWeight = history.read(uint2(clamp(int2(floor(previous)), int2(0), pc.outputMax))).a;

    float3 mean = m1 * (1.0 / 9.0);
    float3 sigma = sqrt(max(m2 * (1.0 / 9.0) - mean * mean, float3(0.0)));
    float3 boxLo = max(lo, mean - sigma * clampSigmas);
    float3 boxHi = min(hi, mean + sigma * clampSigmas);
    float3 clamped = clamp(toYCoCg(h), boxLo, boxHi);

    float weight = min(historyWeight, maxHistoryWeight);
    float blend = sampleWeight / max(weight + sampleWeight, 1.0 / 1024.0);
    float3 result = mix(clamped, current, blend);
    return float4(toRGB(result), min(weight + sampleWeight, maxHistoryWeight));
}
