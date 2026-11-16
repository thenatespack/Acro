#version 450
#extension GL_GOOGLE_include_directive : require

// SceneRenderer's lit forward vertex shader for meshes with vertex paint (`VertexPaint`, vertex
// buffer 2): mesh_vertex.glsl passing the paint on to mesh_paint(_mask).frag.
#define VERTEX_PAINT
#include "mesh_vertex.glsl"
