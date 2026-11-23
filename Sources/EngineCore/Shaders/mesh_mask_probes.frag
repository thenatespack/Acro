#version 450
#extension GL_GOOGLE_include_directive : require

// mesh_mask.frag with the light probes (LIGHT_PROBES, see mesh_surface.glsl): what SceneRenderer draws
// with while a frame has ReflectionProbes or IrradianceVolumes.
#define LIGHT_PROBES
#define ALPHA_MASK
#include "mesh_surface.glsl"
