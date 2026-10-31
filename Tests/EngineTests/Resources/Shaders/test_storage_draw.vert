#version 450
// ComputeTests: positions come from a storage buffer a compute pass wrote.
layout(set = 2, binding = 24, std430) readonly buffer Positions { vec4 positions[]; };

void main() {
    gl_Position = positions[gl_VertexIndex];
    gl_Position.y = -gl_Position.y;
}
