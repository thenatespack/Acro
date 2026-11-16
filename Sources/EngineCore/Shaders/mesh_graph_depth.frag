#version 450
// compile-shaders: -O0

// Masked material graphs (`.material` files with a `graph` and alphaMode "mask") in the depth-only
// passes: the shadow atlas and the camera depth prepass. The template whose graphSurface() body
// MaterialGraphCompiler replaces with each graph's code, as in mesh_graph.frag, so a graph's
// cut-outs (opacity below the cutoff) are cut out of its shadow and its prepass depth too.
// Pairs with mesh_shadow_graph.vert / mesh_shadow_graph_skinned.vert. Writes no color.
//
// gView points at graphPush.eye (the camera's position, also in shadow passes, so fresnel-
// driven opacity casts the shape the camera sees). Compiled without optimization so
// graphSurface stays a function of its own (and keeps its name) in SPIR-V and MSL.
//
// The declarations below repeat mesh_surface.glsl's MATERIAL_GRAPH block by the same names and
// bindings (the splice finds them by OpName in SPIR-V and by parameter name in MSL), plus
// graphPush.eye: keep the two in sync, and rerun Scripts/compile-shaders.sh after editing.

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

// The graph's editable values (`MaterialGraphProgram.values`), storage buffer 0.
layout(set = 2, binding = 24, std430) readonly buffer MaterialGraphValues {
    vec4 values[];
} graphValues;
// params x: time in seconds, y: 1, z: the alpha cutoff (as mesh_surface.glsl's MaterialGraphPush).
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
