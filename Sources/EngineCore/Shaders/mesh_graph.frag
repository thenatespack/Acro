#version 450
#extension GL_GOOGLE_include_directive : require
// compile-shaders: -O0
// compile-shaders: gles -DGRAPH_VALUES_UNIFORM=1024

// SceneRenderer's lit forward shader for material graphs (`.material` files with a `graph`): the
// template whose graphSurface() body MaterialGraphCompiler replaces, in this SPIR-V and in its
// MSL, with each graph's code. Compiled without optimization so graphSurface stays a function of
// its own (and keeps its name) in both.
#define MATERIAL_GRAPH
#include "mesh_surface.glsl"
