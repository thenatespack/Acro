// The declarations a material graph's compiled code uses (see MaterialGraphCompiler.swift), for
// the templates besides the lit one whose graphSurface() the engine replaces with a graph's
// code: mesh_graph_depth.frag (masked graphs in the shadow atlas and the depth prepass) and
// decal_graph.frag (decals drawn with a graph material). They repeat mesh_surface.glsl's
// MATERIAL_GRAPH block, by the same names and bindings, plus graphPush.eye: keep them in sync.
// The including shader declares the five texture slots (baseColorMap, metallicRoughnessMap,
// normalMap, occlusionMap, emissiveMap at bindings 9-13) and materialSampler (binding 17) first,
// and sets the g* inputs before calling graphSurface().
//
// The splice finds everything here by name (OpName in SPIR-V, parameter names in MSL), so keep
// the names, and compile the templates with -O0. Rerun Scripts/compile-shaders.sh after editing.

// The graph's editable values (`MaterialGraphProgram.values`), storage buffer 0. The GLSL ES
// (WebGL 2) variant compile-shaders.sh builds with GRAPH_VALUES_UNIFORM=<count> reads them from a
// std140 uniform block at the same binding instead (WebGL 2 has no storage buffers); the engine
// sets the array to the program's value count (`MaterialGraphCompiler.glesSettingValueCount`).
#ifdef GRAPH_VALUES_UNIFORM
layout(set = 2, binding = 24, std140) uniform MaterialGraphValues {
    vec4 values[GRAPH_VALUES_UNIFORM];
} graphValues;
#else
layout(set = 2, binding = 24, std430) readonly buffer MaterialGraphValues {
    vec4 values[];
} graphValues;
#endif
// params x: time in seconds, y: 1 to discard below the cutoff, z: the alpha cutoff (as
// mesh_surface.glsl's MaterialGraphPush).
layout(push_constant) uniform MaterialGraphPush {
    vec4 params;
    vec4 eye;  // xyz: the camera position gView points to (the depth passes' uniforms don't have it)
} graphPush;

// Inputs (set by main before graphSurface runs).
vec2 gUV;
vec3 gPosition;
vec3 gNormal;
vec3 gView;
vec4 gVertexColor;
float gTime;
// Outputs. gNormalTS is a tangent-space normal (+Z: the mesh normal).
vec3 gBaseColor;
float gOpacity;
vec3 gNormalTS;
float gMetallic;
float gRoughness;
vec3 gEmissive;
float gOcclusion;

// Replaced with the compiled graph. This placeholder reads every input and resource so each
// stays a parameter of the function after SPIRV-Cross (the MSL body is swapped by name).
void graphSurface() {
    vec4 a = texture(sampler2D(baseColorMap, materialSampler), gUV);
    vec4 b = texture(sampler2D(metallicRoughnessMap, materialSampler), gUV);
    vec4 c = texture(sampler2D(normalMap, materialSampler), gUV);
    vec4 d = texture(sampler2D(occlusionMap, materialSampler), gUV);
    vec4 e = texture(sampler2D(emissiveMap, materialSampler), gUV);
    vec4 v = graphValues.values[0];
    gBaseColor = a.rgb * gVertexColor.rgb * v.rgb + (gPosition + gNormal + gView) * gTime;
    gOpacity = a.a * v.a;
    gNormalTS = c.xyz * 2.0 - 1.0;
    gMetallic = b.b;
    gRoughness = b.g;
    gEmissive = e.rgb;
    gOcclusion = d.r;
}
