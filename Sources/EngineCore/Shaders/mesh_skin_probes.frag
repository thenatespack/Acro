#version 450
#extension GL_GOOGLE_include_directive : require
// compile-shaders: gles -DPROBE_DATA_TEXTURE

// mesh_skin.frag with the light probes (LIGHT_PROBES, see mesh_surface.glsl): skin and eyes
// while a frame has ReflectionProbes or IrradianceVolumes.
#define LIGHT_PROBES
#define SKIN_SHADING
#include "mesh_surface.glsl"
