#version 450

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
// Every read is a texelFetch (the sampler only exists to form a sampler2D) and the math is
// plain arithmetic (no filtering hardware), so Metal and Vulkan produce identical results.

// Texture n is set 2, binding 8 + n; sampler n is binding 16 + n (see `ShaderSource`).
layout(set = 2, binding = 9) uniform texture2D colorImage;     // scene color, gamma-encoded
layout(set = 2, binding = 10) uniform texture2D depthImage;    // scene depth
layout(set = 2, binding = 11) uniform texture2D motionImage;   // motion vectors (UV units)
layout(set = 2, binding = 12) uniform texture2D historyImage;  // previous output
layout(set = 2, binding = 17) uniform sampler pointSampler;

layout(push_constant) uniform PushConstants {
    vec2 inputPerOutput;  // render pixels per output pixel
    vec2 outputPerInput;
    vec2 jitter;          // this frame's jitter in render pixels
    vec2 outputSize;
    ivec2 inputMax;       // render size - 1
    ivec2 outputMax;      // output size - 1
    float reset;          // 1: no usable history
    float reversedDepth;  // 1: depth 1 is near
} pc;

layout(location = 0) out vec4 outColor;

// Cap on the history's accumulated weight: at most 1/13 of a full-weight sample is blended in per frame.
const float maxHistoryWeight = 12.0;
// Width of the clamp box, in standard deviations of the neighborhood.
const float clampSigmas = 1.25;

vec3 toYCoCg(vec3 c) {
    return vec3(c.r * 0.25 + c.g * 0.5 + c.b * 0.25, c.r * 0.5 - c.b * 0.5, c.g * 0.5 - c.r * 0.25 - c.b * 0.25);
}

vec3 toRGB(vec3 c) {
    return vec3(c.x + c.y - c.z, c.x + c.z, c.x - c.y - c.z);
}

// Smooth bump: 1 at d² = 0, falling to 0 at d² = 1 (a cheap stand-in for a Gaussian).
float bump(float d2) {
    float w = max(1.0 - d2, 0.0);
    return w * w;
}

vec3 loadHistory(ivec2 p) {
    return texelFetch(sampler2D(historyImage, pointSampler), clamp(p, ivec2(0), pc.outputMax), 0).rgb;
}

void main() {
    vec2 outPos = gl_FragCoord.xy;
    // The output pixel's center in unjittered render pixels; render pixel i was sampled at
    // i + 0.5 - jitter, so `center` is the sample nearest to it.
    vec2 renderPos = outPos * pc.inputPerOutput;
    ivec2 center = ivec2(floor(renderPos + pc.jitter));
    vec2 centerOffset = vec2(center) + 0.5 - pc.jitter - renderPos;
    bool reversed = pc.reversedDepth > 0.5;

    vec3 wideSum = vec3(0.0), narrowSum = vec3(0.0), m1 = vec3(0.0), m2 = vec3(0.0);
    vec3 lo = vec3(1e9), hi = vec3(-1e9);
    float wideWeight = 0.0, narrowWeight = 0.0;
    float nearestDepth = reversed ? -1.0 : 2.0;
    ivec2 nearest = center;
    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            ivec2 p = clamp(center + ivec2(x, y), ivec2(0), pc.inputMax);
            vec3 c = toYCoCg(texelFetch(sampler2D(colorImage, pointSampler), p, 0).rgb);
            vec2 d = centerOffset + vec2(x, y);      // in render pixels
            vec2 dOut = d * pc.outputPerInput;        // in output pixels
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
            float z = texelFetch(sampler2D(depthImage, pointSampler), p, 0).r;
            if (reversed ? z > nearestDepth : z < nearestDepth) {
                nearestDepth = z;
                nearest = p;
            }
        }
    }
    vec3 wideColor = wideSum / wideWeight;
    vec3 current = narrowWeight > 1.0 / 1024.0 ? narrowSum / narrowWeight : wideColor;
    float sampleWeight = min(narrowWeight, 1.0);

    // Where this surface was last frame, in output pixels.
    vec2 previous = outPos + texelFetch(sampler2D(motionImage, pointSampler), nearest, 0).xy * pc.outputSize;
    bool valid = pc.reset < 0.5 && all(greaterThanEqual(previous, vec2(0.0))) && all(lessThanEqual(previous, pc.outputSize));
    if (!valid) {
        outColor = vec4(toRGB(wideColor), sampleWeight);
        return;
    }

    // 4x4 Catmull-Rom around the previous position.
    vec2 t = previous - 0.5;
    vec2 f = floor(t);
    vec2 s = t - f;
    ivec2 base = ivec2(f) - 1;
    vec2 w0 = s * (-0.5 + s * (1.0 - 0.5 * s));
    vec2 w1 = 1.0 + s * s * (-2.5 + 1.5 * s);
    vec2 w2 = s * (0.5 + s * (2.0 - 1.5 * s));
    vec2 w3 = s * s * (-0.5 + 0.5 * s);
    float wx[4] = float[4](w0.x, w1.x, w2.x, w3.x);
    float wy[4] = float[4](w0.y, w1.y, w2.y, w3.y);
    vec3 h = vec3(0.0);
    for (int j = 0; j < 4; j++) {
        vec3 row = vec3(0.0);
        for (int i = 0; i < 4; i++) {
            row += loadHistory(base + ivec2(i, j)) * wx[i];
        }
        h += row * wy[j];
    }
    float historyWeight = texelFetch(sampler2D(historyImage, pointSampler),
                                     clamp(ivec2(floor(previous)), ivec2(0), pc.outputMax), 0).a;

    vec3 mean = m1 * (1.0 / 9.0);
    vec3 sigma = sqrt(max(m2 * (1.0 / 9.0) - mean * mean, vec3(0.0)));
    vec3 boxLo = max(lo, mean - sigma * clampSigmas);
    vec3 boxHi = min(hi, mean + sigma * clampSigmas);
    vec3 clamped = clamp(toYCoCg(h), boxLo, boxHi);

    float weight = min(historyWeight, maxHistoryWeight);
    float blend = sampleWeight / max(weight + sampleWeight, 1.0 / 1024.0);
    vec3 result = mix(clamped, current, blend);
    outColor = vec4(toRGB(result), min(weight + sampleWeight, maxHistoryWeight));
}
