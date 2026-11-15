#version 450

// Selection outline, mask pass (SelectionOutlineRenderer): SceneRenderer meshes drawn with
// their instances' model matrices and one flat color per draw. Only the position and the model
// matrix are read (MeshVertex / MeshInstance layouts).

layout(location = 0) in vec3 inPosition;
layout(location = 3) in vec4 inModel0;
layout(location = 4) in vec4 inModel1;
layout(location = 5) in vec4 inModel2;
layout(location = 6) in vec4 inModel3;

layout(push_constant) uniform PushConstants {
    mat4 viewProj;
    vec4 color;  // r: selected, g: visible (in front of unselected geometry), b: primary selection
} pc;

void main() {
    mat4 model = mat4(inModel0, inModel1, inModel2, inModel3);
    gl_Position = pc.viewProj * (model * vec4(inPosition, 1.0));
    gl_Position.y = -gl_Position.y;  // clip space is y-up; see beginPass in VulkanRenderDevice
}
