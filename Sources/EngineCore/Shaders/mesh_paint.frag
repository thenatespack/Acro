#version 450
#extension GL_GOOGLE_include_directive : require

// SceneRenderer's lit forward shader for meshes with vertex paint (`VertexPaint`): mesh_surface.glsl
// with the paint's factors on albedo, opacity, roughness, metallic and emission.
#define VERTEX_PAINT
#include "mesh_surface.glsl"
