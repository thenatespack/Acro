#version 450

// Sprites: texture * tint. The texture samples as linear light when it is .rgba8Srgb. Output
// is straight alpha; the alpha-blend pipeline uses standard blending, the opaque one none.

layout(set = 2, binding = 9) uniform texture2D spriteTexture;
layout(set = 2, binding = 17) uniform sampler spriteSampler;

layout(location = 0) in vec2 vUV;
layout(location = 1) in vec4 vColor;
layout(location = 0) out vec4 outColor;

void main() {
    outColor = texture(sampler2D(spriteTexture, spriteSampler), vUV) * vColor;
}
