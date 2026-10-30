#version 450

layout(set = 1, binding = 0) uniform sampler2D image;

layout(location = 0) in vec2 vUV;
layout(location = 0) out vec4 outColor;

void main() {
    outColor = vec4(texture(image, vUV).rgb, 1.0);
}
