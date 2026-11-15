#version 450

// World-space SDF text (`TextMesh`), unlit. The atlas stores distance in the red channel: 0.5 on the
// glyph outline, rising inside by 4 per em (6 of 48 pixels of padding span 0.5). The fill, an
// optional outline and an optional glow (distance falling off outside the glyph) are composed in HDR
// (color + emissive, so strengths above 1 bloom), then fogged like the meshes. Output is straight
// alpha for the pipeline's alpha blending.

layout(set = 0, binding = 0, std140) uniform Frame {
    mat4 viewProj;
    mat4 lightViewProj;
    mat4 currentViewProj;
    mat4 previousViewProj;
    vec4 lightDir;
    vec4 lightColor;
    vec4 cameraPos;
    vec4 fogColor;    // rgb: fog color, w: density
} frame;

// Must match WorldTextRenderer.DrawUniforms.
layout(set = 2, binding = 2, std140) uniform Text {
    mat4 model;
    vec4 right;
    vec4 up;
    vec4 color;        // rgb linear color, a opacity
    vec4 emissive;     // rgb emissive color x strength
    vec4 outlineColor; // rgb color, w width in distance-field units
    vec4 glowColor;    // rgb color x strength, w extent in distance-field units
} text;

layout(set = 2, binding = 9) uniform texture2D atlas;
layout(set = 2, binding = 17) uniform sampler atlasSampler;

layout(location = 0) in vec2 vUV;
layout(location = 1) in float vDistance;
layout(location = 2) flat in float vVisible;
layout(location = 0) out vec4 outColor;

void main() {
    if (vVisible < 0.5) discard;
    float d = texture(sampler2D(atlas, atlasSampler), vUV).r;
    float w = max(fwidth(d) * 0.5, 1.0 / 512.0);
    float fill = smoothstep(0.5 - w, 0.5 + w, d);
    vec3 rgb = text.color.rgb + text.emissive.rgb;
    float alpha = fill;

    float outline = text.outlineColor.w;
    if (outline > 0.0) {
        alpha = smoothstep(0.5 - outline - w, 0.5 - outline + w, d);
        rgb = mix(text.outlineColor.rgb, rgb, fill);
    }
    float extent = text.glowColor.w;
    if (extent > 0.0) {
        float t = clamp((d - (0.5 - extent)) / extent, 0.0, 1.0);
        float glow = t * t * (1.0 - alpha);
        float total = alpha + glow;
        rgb = (rgb * alpha + text.glowColor.rgb * glow) / max(total, 1e-5);
        alpha = total;
    }
    alpha *= text.color.a;
    if (alpha <= 0.0) discard;

    float fog = 1.0 - exp(-vDistance * frame.fogColor.w);
    outColor = vec4(mix(rgb, frame.fogColor.rgb, fog), alpha);
}
