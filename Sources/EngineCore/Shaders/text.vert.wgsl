// Generated from text.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: bc688fff75e73d03
// glsl-fnv1a64: b8746969b989bf75

diagnostic(off, derivative_uniformity);

struct type_5 {
    member: vec2<f32>,
}

struct type_11 {
    @builtin(position) member: vec4<f32>,
    member_1: f32,
    member_2: array<f32, 1>,
    member_3: array<f32, 1>,
}

struct VertexOutput {
    @builtin(position) member: vec4<f32>,
    @location(0) member_1: vec2<f32>,
    @location(1) member_2: vec4<f32>,
}

var<private> global: vec2<f32>;
@group(3) @binding(0) 
var<uniform> global_1: type_5;
var<private> global_2: type_11 = type_11(vec4<f32>(0f, 0f, 0f, 1f), 1f, array<f32, 1>(), array<f32, 1>());
var<private> global_3: vec2<f32>;
var<private> global_4: vec2<f32>;
var<private> global_5: vec4<f32>;
var<private> global_6: vec4<f32>;

fn function_() {
    let _e14 = global[0u];
    let _e17 = global_1.member[0u];
    let _e22 = global[1u];
    let _e25 = global_1.member[1u];
    global_2.member = vec4<f32>((((_e14 / _e17) * 2f) - 1f), (1f - ((_e22 / _e25) * 2f)), 0f, 1f);
    let _e33 = global_2.member[1u];
    global_2.member[1u] = -(_e33);
    let _e35 = global_4;
    global_3 = _e35;
    let _e36 = global_6;
    global_5 = _e36;
    return;
}

@vertex 
fn main(@location(0) param: vec2<f32>, @location(1) param_1: vec2<f32>, @location(2) param_2: vec4<f32>) -> VertexOutput {
    global = param;
    global_4 = param_1;
    global_6 = param_2;
    function_();
    let _e11 = global_2.member.y;
    global_2.member.y = -(_e11);
    let _e13 = global_2.member;
    let _e14 = global_3;
    let _e15 = global_5;
    return VertexOutput(_e13, _e14, _e15);
}
