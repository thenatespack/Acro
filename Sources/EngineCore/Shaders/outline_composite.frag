#version 450

// Selection outline, composite (SelectionOutlineRenderer): for each pixel outside the selected
// silhouettes, the distance to the nearest selected mask texel within the outline width gives
// the coverage (a constant pixel width, antialiased over about one pixel). Where the nearest
// texel of a visible part is close enough the outline is opaque; where only hidden parts (behind
// unselected geometry) are, it is drawn at the hidden opacity. The nearest texel's primary flag
// picks the color. Texel loads only, so both backends compute the same bytes.
// Keep in sync with SelectionOutline.coverage (the CPU reference used by the tests).

layout(set = 2, binding = 9) uniform texture2D mask;       // texture 1: r selected, g visible, b primary
layout(set = 2, binding = 17) uniform sampler maskSampler;  // sampler 1 (unused by texelFetch's filtering)

layout(push_constant) uniform PushConstants {
    vec4 primaryColor;    // linear RGBA
    vec4 secondaryColor;
    vec4 params;          // x: width in pixels, y: hidden opacity, z: search radius in pixels
    ivec4 maskMax;        // xy: mask size - 1
} pc;

layout(location = 0) out vec4 outColor;

void main() {
    ivec2 p = ivec2(gl_FragCoord.xy);
    if (texelFetch(sampler2D(mask, maskSampler), p, 0).r > 0.5) discard;  // inside: no outline

    int radius = int(pc.params.z);
    float nearest = 1e9, nearestVisible = 1e9, nearestPrimary = 1e9;
    for (int dy = -radius; dy <= radius; dy++) {
        for (int dx = -radius; dx <= radius; dx++) {
            ivec2 q = p + ivec2(dx, dy);
            if (q.x < 0 || q.y < 0 || q.x > pc.maskMax.x || q.y > pc.maskMax.y) continue;
            vec4 m = texelFetch(sampler2D(mask, maskSampler), q, 0);
            if (m.r < 0.5) continue;
            float d = sqrt(float(dx * dx + dy * dy));
            nearest = min(nearest, d);
            if (m.g > 0.5) nearestVisible = min(nearestVisible, d);
            if (m.b > 0.5) nearestPrimary = min(nearestPrimary, d);
        }
    }
    // A texel d pixels away has its edge about d - 0.5 away: full coverage up to the width.
    float width = pc.params.x;
    float visible = clamp(width + 1.0 - nearestVisible, 0.0, 1.0);
    float hidden = clamp(width + 1.0 - nearest, 0.0, 1.0) * pc.params.y;
    float alpha = max(visible, hidden);
    if (alpha <= 0.0) discard;
    vec4 color = nearestPrimary <= nearest ? pc.primaryColor : pc.secondaryColor;
    outColor = vec4(color.rgb, color.a * alpha);
}
