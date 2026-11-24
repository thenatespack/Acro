// Generated from sprite.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: 5a32036da3536a91
// glsl-fnv1a64: b8879fade431e363

diagnostic(off, derivative_uniformity);

struct type_4 {
    @builtin(position) member: vec4<f32>,
    member_1: f32,
    member_2: array<f32, 1>,
    member_3: array<f32, 1>,
}

struct type_8 {
    member: mat4x4<f32>,
}

struct VertexOutput {
    @builtin(position) member: vec4<f32>,
    @location(0) member_1: vec2<f32>,
    @location(1) member_2: vec4<f32>,
}

var<private> global: type_4 = type_4(vec4<f32>(0f, 0f, 0f, 1f), 1f, array<f32, 1>(), array<f32, 1>());
@group(3) @binding(0) 
var<uniform> global_1: type_8;
var<private> global_2: vec3<f32>;
var<private> global_3: vec2<f32>;
var<private> global_4: vec2<f32>;
var<private> global_5: vec4<f32>;
var<private> global_6: vec4<f32>;

fn function_() {
    let _e11 = global_1.member;
    let _e12 = global_2;
    global.member = (_e11 * vec4<f32>(_e12.x, _e12.y, _e12.z, 1f));
    let _e21 = global.member[1u];
    global.member[1u] = -(_e21);
    let _e23 = global_4;
    global_3 = _e23;
    let _e24 = global_6;
    global_5 = _e24;
    return;
}

@vertex 
fn main(@location(0) param: vec3<f32>, @location(1) param_1: vec2<f32>, @location(2) param_2: vec4<f32>) -> VertexOutput {
    global_2 = param;
    global_4 = param_1;
    global_6 = param_2;
    function_();
    let _e11 = global.member.y;
    global.member.y = -(_e11);
    let _e13 = global.member;
    let _e14 = global_3;
    let _e15 = global_5;
    return VertexOutput(_e13, _e14, _e15);
}
