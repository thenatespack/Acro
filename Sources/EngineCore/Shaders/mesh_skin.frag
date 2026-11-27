#version 450
#extension GL_GOOGLE_include_directive : require

// mesh.frag with skin and eye shading (SKIN_SHADING, skin.glsl): what SceneRenderer draws
// materials with a subsurface, specularLobes, detailNormal or eye block with.
#define SKIN_SHADING
#include "mesh_surface.glsl"
