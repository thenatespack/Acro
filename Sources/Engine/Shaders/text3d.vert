#version 450

// World-space SDF text (`TextMesh`): glyph corners in the entity's local XY plane, placed by its
// model matrix, or turned to face the camera for billboards. A prefix of SceneRenderer.FrameUniforms
// (set 0) gives the view-projection, camera and fog.

layout(set = 0, binding = 0, std140) uniform Frame {
    mat4 viewProj;
    mat4 lightViewProj;
    mat4 currentViewProj;
    mat4 previousViewProj;
    vec4 lightDir;
    vec4 lightColor;
    vec4 cameraPos;   // xyz: eye
    vec4 fogColor;    // rgb: fog color, w: density
} frame;

// Must match WorldTextRenderer.DrawUniforms.
layout(set = 2, binding = 2, std140) uniform Text {
    mat4 model;
    vec4 right;        // xyz camera right, w 1 for a billboard
    vec4 up;           // xyz camera up, w 1 when only the front is visible
    vec4 color;        // rgb linear color, a opacity
    vec4 emissive;     // rgb emissive color x strength
    vec4 outlineColor; // rgb color, w width in distance-field units
    vec4 glowColor;    // rgb color x strength, w extent in distance-field units
} text;

layout(location = 0) in vec2 inPosition;
layout(location = 1) in vec2 inUV;

layout(location = 0) out vec2 vUV;
layout(location = 1) out float vDistance;
layout(location = 2) flat out float vVisible;

void main() {
    vec3 origin = text.model[3].xyz;
    vec3 toCamera = frame.cameraPos.xyz - origin;
    vec3 world;
    float facing;
    if (text.right.w > 0.5) {
        float sx = length(text.model[0].xyz);
        float sy = length(text.model[1].xyz);
        world = origin + text.right.xyz * (inPosition.x * sx) + text.up.xyz * (inPosition.y * sy);
        facing = 1.0;
    } else {
        world = (text.model * vec4(inPosition, 0.0, 1.0)).xyz;
        facing = dot(cross(text.model[0].xyz, text.model[1].xyz), toCamera);
    }
    vVisible = (text.up.w < 0.5 || facing >= 0.0) ? 1.0 : 0.0;
    gl_Position = frame.viewProj * vec4(world, 1.0);
    gl_Position.y = -gl_Position.y;  // clip space is y-up; see beginPass in VulkanRenderDevice
    vUV = inUV;
    vDistance = length(frame.cameraPos.xyz - world);
}
