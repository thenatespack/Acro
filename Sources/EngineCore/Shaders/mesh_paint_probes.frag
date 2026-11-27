#version 450
#extension GL_GOOGLE_include_directive : require
// compile-shaders: gles -DPROBE_DATA_TEXTURE

// mesh_paint.frag with the light probes (LIGHT_PROBES, see mesh_surface.glsl): what SceneRenderer draws
// with while a frame has ReflectionProbes or IrradianceVolumes.
#define LIGHT_PROBES
#define VERTEX_PAINT
#include "mesh_surface.glsl"
