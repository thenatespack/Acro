#version 450

// SceneRenderer's depth-only passes (shadow atlas, depth prepass) for masked material graphs:
// mesh_shadow.vert plus what a graph reads (mesh_graph_depth.frag): world position, normal, UV
// and the instance color, at mesh.vert's output locations.
layout(set = 0, binding = 0, std140) uniform Frame {
    mat4 viewProj;
    mat4 lightViewProj;
} frame;

layout(location = 0) in vec3 inPosition;
layout(location = 1) in vec3 inNormal;
layout(location = 2) in vec2 inUV;
layout(location = 3) in vec4 model0;
layout(location = 4) in vec4 model1;
layout(location = 5) in vec4 model2;
layout(location = 6) in vec4 model3;
layout(location = 11) in vec4 inColor;

layout(location = 0) out vec3 vWorldPos;
layout(location = 1) out vec3 vNormal;
layout(location = 2) out vec2 vUV;
layout(location = 3) out vec4 vColor;

void main() {
    mat4 model = mat4(model0, model1, model2, model3);
    vec4 world = model * vec4(inPosition, 1.0);
    // Normals by the cofactor matrix, as in mesh.vert.
    vec3 a = model0.xyz, b = model1.xyz, c = model2.xyz;
    mat3 cofactor = mat3(cross(b, c), cross(c, a), cross(a, b));
    float handedness = dot(cross(a, b), c) < 0.0 ? -1.0 : 1.0;
    gl_Position = frame.lightViewProj * world;
    gl_Position.y = -gl_Position.y;  // clip space is y-up; see beginPass in VulkanRenderDevice
    vWorldPos = world.xyz;
    vNormal = cofactor * inNormal * handedness;
    vUV = inUV;
    vColor = inColor;
}
