// Generated from overlay.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: e4d11cc417eff009
// glsl-fnv1a64: d54f12e6c32e8234

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
    @location(0) member_1: vec4<f32>,
}

var<private> global: vec2<f32>;
@group(3) @binding(0) 
var<uniform> global_1: type_5;
var<private> global_2: type_11 = type_11(vec4<f32>(0f, 0f, 0f, 1f), 1f, array<f32, 1>(), array<f32, 1>());
var<private> global_3: vec4<f32>;
var<private> global_4: vec4<f32>;

fn function_() {
    let _e12 = global[0u];
    let _e15 = global_1.member[0u];
    let _e20 = global[1u];
    let _e23 = global_1.member[1u];
    global_2.member = vec4<f32>((((_e12 / _e15) * 2f) - 1f), (1f - ((_e20 / _e23) * 2f)), 0f, 1f);
    let _e31 = global_2.member[1u];
    global_2.member[1u] = -(_e31);
    let _e33 = global_4;
    global_3 = _e33;
    return;
}

@vertex 
fn main(@location(0) param: vec2<f32>, @location(1) param_1: vec4<f32>) -> VertexOutput {
    global = param;
    global_4 = param_1;
    function_();
    let _e8 = global_2.member.y;
    global_2.member.y = -(_e8);
    let _e10 = global_2.member;
    let _e11 = global_3;
    return VertexOutput(_e10, _e11);
}
