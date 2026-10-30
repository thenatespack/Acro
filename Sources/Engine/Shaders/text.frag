#version 450

// Signed-distance-field text. The atlas stores distance in the red channel, 0.5 on the glyph
// outline, rising inside. The edge is antialiased over about one screen pixel, using the
// screen-space derivative of the distance, so text stays crisp at any scale.
// Output is straight (non-premultiplied) alpha; the pipeline uses standard alpha blending.

layout(set = 2, binding = 9) uniform texture2D atlas;
layout(set = 2, binding = 17) uniform sampler atlasSampler;

layout(location = 0) in vec2 vUV;
layout(location = 1) in vec4 vColor;
layout(location = 0) out vec4 outColor;

void main() {
    float distance = texture(sampler2D(atlas, atlasSampler), vUV).r;
    float width = max(fwidth(distance) * 0.5, 1.0 / 512.0);
    float alpha = smoothstep(0.5 - width, 0.5 + width, distance);
    outColor = vec4(vColor.rgb, vColor.a * alpha);
}
