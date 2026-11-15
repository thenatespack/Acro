#version 450

// A decal's projector box (see decal.frag): the unit cube -0.5...0.5 under the decal's model
// matrix, 12 triangles from gl_VertexIndex, counter-clockwise seen from outside. Must match
// `SceneRenderer.FrameUniforms` (a prefix) and `DecalRenderer.Uniforms`.
layout(set = 0, binding = 0, std140) uniform Frame {
    mat4 viewProj;
} frame;

layout(set = 2, binding = 2, std140) uniform DecalData {
    mat4 model;
    mat4 inverseModel;
    mat4 inverseViewProj;
    vec4 color;   // rgb: tint, a: opacity
    vec4 params;  // x: emissive, y: roughness, z: angle fade, w: 1 with a texture
    vec4 axis;    // xyz: unit world direction the decal projects along
} decal;

const vec3 corners[8] = vec3[](
    vec3(-0.5, -0.5, -0.5), vec3(0.5, -0.5, -0.5), vec3(-0.5, 0.5, -0.5), vec3(0.5, 0.5, -0.5),
    vec3(-0.5, -0.5, 0.5), vec3(0.5, -0.5, 0.5), vec3(-0.5, 0.5, 0.5), vec3(0.5, 0.5, 0.5));
// Corner bits: x 1, y 2, z 4.
const int indices[36] = int[](
    1, 3, 7, 1, 7, 5,   // +x
    0, 4, 6, 0, 6, 2,   // -x
    2, 6, 7, 2, 7, 3,   // +y
    0, 1, 5, 0, 5, 4,   // -y
    4, 5, 7, 4, 7, 6,   // +z
    0, 2, 3, 0, 3, 1);  // -z

void main() {
    vec4 world = decal.model * vec4(corners[indices[gl_VertexIndex]], 1.0);
    gl_Position = frame.viewProj * world;
    gl_Position.y = -gl_Position.y;  // clip space is y-up; see mesh.vert
}
