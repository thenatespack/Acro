#version 450
#extension GL_GOOGLE_include_directive : require

// SceneRenderer's lit forward vertex shader for materials with wind (`Material.wind`):
// mesh_vertex.glsl with the object-space position swayed first (wind.glsl). Pairs with mesh.frag
// and mesh_mask.frag.
#define WIND
#include "mesh_vertex.glsl"
