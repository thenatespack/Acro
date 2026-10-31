// Uniform buffer 2 of sky.vert / sky.frag and env_base.frag, must match `SkyUniforms` (see
// EnvironmentLighting.swift). Include after environment.glsl. Not compiled on its own.
layout(set = 2, binding = 2, std140) uniform SkyData {
    mat4 inverseViewProj;  // clip -> world direction (the view's rotation only; jittered like the scene)
    vec4 params;           // x: 1 equirectangular map, 0 procedural; y: intensity; z, w: cos, sin of the rotation
    vec4 extra;            // x: far-plane depth (1, or 0 with reversed-Z); y: map mip level (env_base); zw: target size (env_base)
    vec4 zenith;
    vec4 horizon;
    vec4 ground;
    vec4 sunDirection;     // toward the sun
    vec4 sunColor;         // the directional light's color x intensity
    vec4 sun;              // x, y: cos of the disk's outer / inner edge, z: disk radiance scale, w: glow
} skyData;

Sky skyParameters() {
    return Sky(skyData.zenith.rgb, skyData.horizon.rgb, skyData.ground.rgb, skyData.sunDirection.xyz, skyData.sunColor.rgb,
               skyData.sun);
}
