#version 450

// Fullscreen triangle for the post-processing passes (bloom_*, exposure_*, tonemap). They read
// texels by pixel position (gl_FragCoord), so no UVs are needed.
void main() {
    vec2 p = vec2((gl_VertexIndex << 1) & 2, gl_VertexIndex & 2);
    gl_Position = vec4(p * 2.0 - 1.0, 0.0, 1.0);
    gl_Position.y = -gl_Position.y;  // clip space is y-up; see beginPass in VulkanRenderDevice
}
