#version 450
#extension GL_GOOGLE_include_directive : require

// Particle fragments, for unlit and lit particles alike (lit ones arrive with their light in
// the color, see particle_lighting.glsl):
//
// - Shape: a soft round disc (alpha falls off smoothly to the quad's inscribed circle), or the
//   texture atlas's cell (flipbook), optionally blended with the next frame's.
// - Soft fade: near opaque geometry, alpha fades with the distance (view depth) between the
//   fragment and the scene behind it, read from the depth prepass texture at this pixel.
//
// Output is straight alpha, blended additively (color × alpha added) or over the scene (sorted).

#include "particle_draw.glsl"

layout(set = 2, binding = 9) uniform texture2D particleTexture;
layout(set = 2, binding = 10) uniform texture2D sceneDepth;
layout(set = 2, binding = 17) uniform sampler materialSampler;

layout(location = 0) in vec2 vCorner;
layout(location = 1) in vec4 vColor;
layout(location = 2) in vec4 vUV;
layout(location = 3) in float vBlend;

layout(location = 0) out vec4 outColor;

void main() {
    vec4 color = vColor;
    if (draw.atlasFlags.z > 0.5) {
        vec4 texel = texture(sampler2D(particleTexture, materialSampler), vUV.xy);
        if (vBlend > 0.0) texel = mix(texel, texture(sampler2D(particleTexture, materialSampler), vUV.zw), vBlend);
        color *= texel;
    } else {
        float falloff = clamp(1.0 - dot(vCorner, vCorner), 0.0, 1.0);
        color.a *= falloff * falloff;
    }
    if (draw.soft.x > 0.0) {
        // View depths from depth values: y / (d + z) (perspective; standard or reversed Z).
        float scene = texelFetch(sampler2D(sceneDepth, materialSampler), ivec2(gl_FragCoord.xy), 0).r;
        float behind = draw.soft.y / (scene + draw.soft.z) - draw.soft.y / (gl_FragCoord.z + draw.soft.z);
        color.a *= clamp(behind * draw.soft.x, 0.0, 1.0);
    }
    outColor = color;
}
