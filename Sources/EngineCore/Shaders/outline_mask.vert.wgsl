// Generated from outline_mask.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: ed441242b7c519be
// glsl-fnv1a64: 4e6b65dc72c0e978

diagnostic(off, derivative_uniformity);

struct type_6 {
    @builtin(position) member: vec4<f32>,
    member_1: f32,
    member_2: array<f32, 1>,
    member_3: array<f32, 1>,
}

struct type_9 {
    member: mat4x4<f32>,
    member_1: vec4<f32>,
}

var<private> global: vec4<f32>;
var<private> global_1: vec4<f32>;
var<private> global_2: vec4<f32>;
var<private> global_3: vec4<f32>;
var<private> global_4: type_6 = type_6(vec4<f32>(0f, 0f, 0f, 1f), 1f, array<f32, 1>(), array<f32, 1>());
@group(3) @binding(0) 
var<uniform> global_5: type_9;
var<private> global_6: vec3<f32>;

fn function_() {
    let _e10 = global;
    let _e11 = global_1;
    let _e12 = global_2;
    let _e13 = global_3;
    let _e16 = global_5.member;
    let _e17 = global_6;
    global_4.member = (_e16 * (mat4x4<f32>(_e10, _e11, _e12, _e13) * vec4<f32>(_e17.x, _e17.y, _e17.z, 1f)));
    let _e27 = global_4.member[1u];
    global_4.member[1u] = -(_e27);
    return;
}

@vertex 
fn main(@location(3) param: vec4<f32>, @location(4) param_1: vec4<f32>, @location(5) param_2: vec4<f32>, @location(6) param_3: vec4<f32>, @location(0) param_4: vec3<f32>) -> @builtin(position) vec4<f32> {
    global = param;
    global_1 = param_1;
    global_2 = param_2;
    global_3 = param_3;
    global_6 = param_4;
    function_();
    let _e13 = global_4.member.y;
    global_4.member.y = -(_e13);
    let _e15 = global_4.member;
    return _e15;
}
