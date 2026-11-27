#version 450
#extension GL_GOOGLE_include_directive : require
// compile-shaders: gles -DGRAPH_VALUES_UNIFORM=1024

// SceneRenderer's lit forward shader for terrains drawn with per-pixel layer blending
// (`TerrainSplat`, see terrain_splat.glsl): the material graph path of mesh_surface.glsl with a
// fixed graphSurface() that blends the splat-mapped layers' textures and normal maps.
#define MATERIAL_GRAPH
#define TERRAIN_SPLAT
#include "mesh_surface.glsl"
