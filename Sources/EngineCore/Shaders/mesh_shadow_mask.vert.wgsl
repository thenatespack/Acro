// Generated from mesh_shadow_mask.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: 1a9a30b5865feed2
// glsl-fnv1a64: be893aeac1683ffa

diagnostic(off, derivative_uniformity);

struct type_6 {
    @builtin(position) member: vec4<f32>,
    member_1: f32,
    member_2: array<f32, 1>,
    member_3: array<f32, 1>,
}

struct type_9 {
    member: mat4x4<f32>,
    member_1: mat4x4<f32>,
}

struct VertexOutput {
    @builtin(position) member: vec4<f32>,
    @location(0) member_1: vec2<f32>,
}

var<private> global: vec4<f32>;
var<private> global_1: vec4<f32>;
var<private> global_2: vec4<f32>;
var<private> global_3: vec4<f32>;
var<private> global_4: type_6 = type_6(vec4<f32>(0f, 0f, 0f, 1f), 1f, array<f32, 1>(), array<f32, 1>());
@group(0) @binding(0) 
var<uniform> global_5: type_9;
var<private> global_6: vec3<f32>;
var<private> global_7: vec2<f32>;
var<private> global_8: vec2<f32>;

fn function_() {
    let _e13 = global;
    let _e14 = global_1;
    let _e15 = global_2;
    let _e16 = global_3;
    let _e19 = global_5.member_1;
    let _e20 = global_6;
    global_4.member = (_e19 * (mat4x4<f32>(_e13, _e14, _e15, _e16) * vec4<f32>(_e20.x, _e20.y, _e20.z, 1f)));
    let _e30 = global_4.member[1u];
    global_4.member[1u] = -(_e30);
    let _e32 = global_8;
    global_7 = _e32;
    return;
}

@vertex 
fn main(@location(3) param: vec4<f32>, @location(4) param_1: vec4<f32>, @location(5) param_2: vec4<f32>, @location(6) param_3: vec4<f32>, @location(0) param_4: vec3<f32>, @location(2) param_5: vec2<f32>) -> VertexOutput {
    global = param;
    global_1 = param_1;
    global_2 = param_2;
    global_3 = param_3;
    global_6 = param_4;
    global_8 = param_5;
    function_();
    let _e16 = global_4.member.y;
    global_4.member.y = -(_e16);
    let _e18 = global_4.member;
    let _e19 = global_7;
    return VertexOutput(_e18, _e19);
}
