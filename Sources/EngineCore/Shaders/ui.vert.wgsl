// Generated from ui.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: 365ff86fa6efada9
// glsl-fnv1a64: eaea6046697bd6ea

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
    @location(2) member_3: vec2<f32>,
    @location(3) @interpolate(flat) member_4: vec2<f32>,
    @location(4) @interpolate(flat) member_5: vec4<f32>,
    @location(5) @interpolate(flat) member_6: vec4<f32>,
}

var<private> global: vec2<f32>;
@group(3) @binding(0) 
var<uniform> global_1: type_5;
var<private> global_2: type_11 = type_11(vec4<f32>(0f, 0f, 0f, 1f), 1f, array<f32, 1>(), array<f32, 1>());
var<private> global_3: vec2<f32>;
var<private> global_4: vec2<f32>;
var<private> global_5: vec4<f32>;
var<private> global_6: vec4<f32>;
var<private> global_7: vec2<f32>;
var<private> global_8: vec2<f32>;
var<private> global_9: vec2<f32>;
var<private> global_10: vec2<f32>;
var<private> global_11: vec4<f32>;
var<private> global_12: vec4<f32>;
var<private> global_13: vec4<f32>;
var<private> global_14: vec4<f32>;

fn function_() {
    let _e22 = global[0u];
    let _e25 = global_1.member[0u];
    let _e30 = global[1u];
    let _e33 = global_1.member[1u];
    global_2.member = vec4<f32>((((_e22 / _e25) * 2f) - 1f), (1f - ((_e30 / _e33) * 2f)), 0f, 1f);
    let _e41 = global_2.member[1u];
    global_2.member[1u] = -(_e41);
    let _e43 = global_4;
    global_3 = _e43;
    let _e44 = global_6;
    global_5 = _e44;
    let _e45 = global_8;
    global_7 = _e45;
    let _e46 = global_10;
    global_9 = _e46;
    let _e47 = global_12;
    global_11 = _e47;
    let _e48 = global_14;
    global_13 = _e48;
    return;
}

@vertex 
fn main(@location(0) param: vec2<f32>, @location(1) param_1: vec2<f32>, @location(2) param_2: vec4<f32>, @location(3) param_3: vec2<f32>, @location(4) param_4: vec2<f32>, @location(5) param_5: vec4<f32>, @location(6) param_6: vec4<f32>) -> VertexOutput {
    global = param;
    global_4 = param_1;
    global_6 = param_2;
    global_8 = param_3;
    global_10 = param_4;
    global_12 = param_5;
    global_14 = param_6;
    function_();
    let _e23 = global_2.member.y;
    global_2.member.y = -(_e23);
    let _e25 = global_2.member;
    let _e26 = global_3;
    let _e27 = global_5;
    let _e28 = global_7;
    let _e29 = global_9;
    let _e30 = global_11;
    let _e31 = global_13;
    return VertexOutput(_e25, _e26, _e27, _e28, _e29, _e30, _e31);
}
