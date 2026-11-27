#version 450
#extension GL_GOOGLE_include_directive : require
// compile-shaders: -O0
// compile-shaders: gles -DGRAPH_VALUES_UNIFORM=1024

// Decals with a material graph (`Decal.material` naming a `.material` with a `graph`): decal.frag
// with the graph's surface instead of the decal texture. Its graphSurface() body is replaced
// with each graph's code (MaterialGraphCompiler, as mesh_graph.frag); it sees the decal's UV,
// the painted surface's position and normal, and the decal's tint and opacity as its vertex
// color. Base color x tint is the albedo, opacity x the decal's opacity (and angle fade) the
// coverage; metallic, roughness, the tangent-space normal (u along the box's x, "up" along its
// y), emissive and occlusion shade it as on a mesh. The decal's emissive still adds its albedo.
// The depth prepass is in texture slot 7 (the BRDF table's), so environment specular uses the
// analytic fit. Compiled without optimization so graphSurface keeps its name.

#define DECAL_GRAPH
#include "decal_surface.glsl"
