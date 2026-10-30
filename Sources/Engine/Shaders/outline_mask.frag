#version 450

// Selection outline, mask pass: the draw's flat mask value (exactly 0 or 1 per channel, so the
// sRGB target stores it unchanged).

layout(push_constant) uniform PushConstants {
    mat4 viewProj;
    vec4 color;
} pc;

layout(location = 0) out vec4 outColor;

void main() {
    outColor = pc.color;
}
