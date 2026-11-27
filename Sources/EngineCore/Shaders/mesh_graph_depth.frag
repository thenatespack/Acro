#version 450
#extension GL_GOOGLE_include_directive : require
// compile-shaders: -O0
// compile-shaders: gles -DGRAPH_VALUES_UNIFORM=1024

// Masked material graphs (`.material` files with a `graph` and alphaMode "mask") in the depth-only
// passes: the shadow atlas and the camera depth prepass. The template whose graphSurface() body
// MaterialGraphCompiler replaces with each graph's code, as in mesh_graph.frag, so a graph's
// cut-outs (opacity below the cutoff) are cut out of its shadow and its prepass depth too.
// Pairs with mesh_shadow_graph.vert / mesh_shadow_graph_skinned.vert. Writes no color.
//
// gView points at graphPush.eye (the camera's position, also in shadow passes, so fresnel-
// driven opacity casts the shape the camera sees). Compiled without optimization so
// graphSurface stays a function of its own (and keeps its name) in SPIR-V and MSL.

// Textures 1-5 and sampler 1: the graph's texture slots, as in mesh_surface.glsl.
layout(set = 2, binding = 9) uniform texture2D baseColorMap;
layout(set = 2, binding = 10) uniform texture2D metallicRoughnessMap;
layout(set = 2, binding = 11) uniform texture2D normalMap;
layout(set = 2, binding = 12) uniform texture2D occlusionMap;
layout(set = 2, binding = 13) uniform texture2D emissiveMap;
layout(set = 2, binding = 17) uniform sampler materialSampler;

layout(location = 0) in vec3 vWorldPos;
layout(location = 1) in vec3 vNormal;
layout(location = 2) in vec2 vUV;
layout(location = 3) in vec4 vColor;

#include "material_graph.glsl"

void main() {
    gUV = vUV;
    gPosition = vWorldPos;
    gNormal = normalize(vNormal);
    gView = normalize(graphPush.eye.xyz - vWorldPos);
    gVertexColor = vColor;
    gTime = graphPush.params.x;
    graphSurface();
    // As mesh_surface.glsl's MATERIAL_GRAPH mask test.
    if (gOpacity < graphPush.params.z) discard;
}
