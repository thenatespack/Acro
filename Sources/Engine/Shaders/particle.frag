#version 450

// A soft round particle: alpha falls off smoothly to the quad's inscribed circle. Output is
// straight alpha, blended additively (color × alpha added) or over the scene (sorted).

layout(location = 0) in vec2 vCorner;
layout(location = 1) in vec4 vColor;

layout(location = 0) out vec4 outColor;

void main() {
    float falloff = clamp(1.0 - dot(vCorner, vCorner), 0.0, 1.0);
    outColor = vec4(vColor.rgb, vColor.a * falloff * falloff);
}
