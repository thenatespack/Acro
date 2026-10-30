#version 450

// 2D UI: analytic antialiasing from the signed distance to a rounded box (per-corner radii),
// so edges are smooth at any scale without MSAA. All distances are in framebuffer pixels:
// coverage = clamp(0.5 - d, 0, 1) is the exact area of a pixel inside a straight edge.
//
// Colors arrive in sRGB (straight alpha) and are interpolated that way, so gradients look
// like they do in CSS. They are converted to linear here, and the sRGB window target
// encodes the result back after blending, which therefore happens in linear light.
// Textures bound as .rgba8Srgb already sample as linear; .rgba8Unorm ones are used as is.

layout(set = 2, binding = 9) uniform texture2D uiTexture;
layout(set = 2, binding = 17) uniform sampler uiSampler;

layout(location = 0) in vec2 vUV;
layout(location = 1) in vec4 vColor;
layout(location = 2) in vec2 vLocal;
layout(location = 3) flat in vec2 vHalfSize;
layout(location = 4) flat in vec4 vRadii;
layout(location = 5) flat in vec4 vParams;

layout(location = 0) out vec4 outColor;

const int MODE_SOLID = 0;  // vertex color
const int MODE_IMAGE = 1;  // texture * vertex color (tint)
const int MODE_MASK = 2;   // vertex color, coverage from the texture's alpha (glyph atlases)
const int MODE_SDF = 3;    // like MASK, but the alpha is a distance field (SDF text), see below

vec3 srgbToLinear(vec3 c) {
    return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(0.04045, c));
}

// Signed distance to a box of half extents `h` centered at the origin, with a radius per corner.
float roundedBoxDistance(vec2 p, vec2 h, vec4 radii) {
    float r = p.x < 0.0 ? (p.y < 0.0 ? radii.x : radii.w) : (p.y < 0.0 ? radii.y : radii.z);
    vec2 q = abs(p) - h + r;
    return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r;
}

void main() {
    // Sampled unconditionally: derivatives (mip selection) need uniform control flow.
    vec4 texel = texture(sampler2D(uiTexture, uiSampler), vUV);

    int mode = int(vParams.y + 0.5);
    float strokeWidth = vParams.x;

    float d = roundedBoxDistance(vLocal, vHalfSize, vRadii);
    float coverage;
    if (strokeWidth > 0.0) {
        // A band of `strokeWidth` just inside the edge.
        coverage = clamp(0.5 - (abs(d + 0.5 * strokeWidth) - 0.5 * strokeWidth), 0.0, 1.0);
    } else {
        coverage = clamp(0.5 - d, 0.0, 1.0);
    }

    // Vertex colors are extrapolated into the antialiasing margin, so clamp them.
    vec4 srgb = clamp(vColor, 0.0, 1.0);
    vec4 color = vec4(srgbToLinear(srgb.rgb), srgb.a);
    if (mode == MODE_IMAGE) {
        color *= texel;
    } else if (mode == MODE_MASK) {
        color.a *= texel.a;
    } else if (mode == MODE_SDF) {
        // Hook for SDF text: the atlas stores the distance in alpha (0.5 on the outline,
        // larger inside) and vParams.z is the smoothing width in distance units (about
        // 0.7 / (spread * scale)). The text renderer can emit quads with this mode.
        color.a *= clamp((texel.a - 0.5) / max(vParams.z, 1e-4) + 0.5, 0.0, 1.0);
    }
    outColor = vec4(color.rgb, color.a * coverage);
}
