#version 450
#extension GL_GOOGLE_include_directive : require

// SceneRenderer's lit forward vertex shader for swaying meshes with vertex paint (leaf cards with
// per-card variation, painted sculpt pieces with wind): mesh_vertex.glsl with both VERTEX_PAINT
// and WIND. Pairs with mesh_paint.frag and mesh_paint_mask.frag.
#define VERTEX_PAINT
#define WIND
#include "mesh_vertex.glsl"
