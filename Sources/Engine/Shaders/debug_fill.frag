#version 450

// Filled debug triangles: the instance color, straight alpha, standard blending.

layout(location = 0) in vec4 vColor;
layout(location = 0) out vec4 outColor;

void main() {
    outColor = vColor;
}
