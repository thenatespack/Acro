#version 450

// Selection outline, composite: a fullscreen triangle (the fragment shader reads mask texels by
// pixel position, and a scissor limits it to the selection's screen rectangle).
void main() {
    vec2 p = vec2((gl_VertexIndex << 1) & 2, gl_VertexIndex & 2);
    gl_Position = vec4(p * 2.0 - 1.0, 0.0, 1.0);
    gl_Position.y = -gl_Position.y;  // clip space is y-up; see beginPass in VulkanRenderDevice
}
