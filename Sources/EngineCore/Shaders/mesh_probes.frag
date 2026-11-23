#version 450
#extension GL_GOOGLE_include_directive : require

// mesh.frag with the light probes (LIGHT_PROBES, see mesh_surface.glsl): what SceneRenderer draws
// with while a frame has ReflectionProbes or IrradianceVolumes.
#define LIGHT_PROBES
#include "mesh_surface.glsl"
