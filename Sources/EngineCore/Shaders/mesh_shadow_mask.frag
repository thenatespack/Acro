#version 450

// Alpha-tested shadow casters: discards where the material's base color alpha is below the
// cutoff, like mesh_mask.frag. Writes no color (depth-only pass).

// Must match `SceneRenderer.MaterialUniforms` (see mesh_surface.glsl).
layout(set = 2, binding = 2, std140) uniform MaterialData {
    vec4 baseColor;
    vec4 params;
    vec4 uvRow0;
    vec4 uvRow1;
    vec4 surface;
    vec4 emissive;
    vec4 flags;  // x: alpha cutoff
} material;

layout(set = 2, binding = 9) uniform texture2D baseColorMap;
layout(set = 2, binding = 17) uniform sampler materialSampler;

layout(location = 0) in vec2 vUV;

void main() {
    vec2 uv = vec2(dot(material.uvRow0.xy, vUV) + material.uvRow0.z, dot(material.uvRow1.xy, vUV) + material.uvRow1.z);
    if (material.baseColor.a * texture(sampler2D(baseColorMap, materialSampler), uv).a < material.flags.x) discard;
}
