#version 450

// Debug lines: coverage from the distance to the center line, antialiased over one pixel.
// Lines thinner than a pixel fade out instead of breaking up. Straight alpha, standard blending.

layout(location = 0) in vec4 vColor;
layout(location = 1) noperspective in vec2 vEdge;
layout(location = 0) out vec4 outColor;

void main() {
    float halfWidth = vEdge.y;
    float coverage = clamp(max(halfWidth, 0.5) + 0.5 - abs(vEdge.x), 0.0, 1.0) * min(halfWidth * 2.0, 1.0);
    outColor = vec4(vColor.rgb, vColor.a * coverage);
}
