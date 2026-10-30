#version 450

// Debug ground grid (DebugGrid): a square on the plane y = height centered under the camera,
// `fadeDistance` in each direction, from the vertex index. The fragment shader draws the lines.

layout(set = 2, binding = 2, std140) uniform Grid {
    mat4 viewProj;
    vec4 camera;  // xyz: camera position, w: grid height
    vec4 params;  // x: spacing, y: major line every n cells, z: fade distance, w: line width in pixels
    vec4 minorColor;
    vec4 majorColor;
    vec4 xAxisColor;
    vec4 zAxisColor;
} grid;

layout(location = 0) out vec3 vWorld;

const vec2 corners[6] = vec2[](vec2(-1, -1), vec2(1, -1), vec2(1, 1), vec2(-1, -1), vec2(1, 1), vec2(-1, 1));

void main() {
    vec2 offset = corners[gl_VertexIndex] * grid.params.z;
    vWorld = vec3(grid.camera.x + offset.x, grid.camera.w, grid.camera.z + offset.y);
    gl_Position = grid.viewProj * vec4(vWorld, 1.0);
    gl_Position.y = -gl_Position.y;  // clip space is y-up; see beginPass in VulkanRenderDevice
}
