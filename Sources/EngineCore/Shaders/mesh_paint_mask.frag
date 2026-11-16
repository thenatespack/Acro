#version 450
#extension GL_GOOGLE_include_directive : require

// mesh_paint.frag for alpha-tested materials (AlphaMode.mask), as mesh_mask.frag is to mesh.frag.
#define VERTEX_PAINT
#define ALPHA_MASK
#include "mesh_surface.glsl"
