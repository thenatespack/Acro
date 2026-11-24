// Generated from blit.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: fa787a348664c466
// glsl-fnv1a64: 40889789fe220612

diagnostic(off, derivative_uniformity);

struct type_7 {
    @builtin(position) member: vec4<f32>,
    member_1: f32,
    member_2: array<f32, 1>,
    member_3: array<f32, 1>,
}

struct type_10 {
    member: vec2<f32>,
    member_1: vec2<i32>,
    member_2: vec2<i32>,
    member_3: vec2<i32>,
}

struct VertexOutput {
    @builtin(position) member: vec4<f32>,
    @location(0) member_1: vec2<f32>,
}

var<private> global: i32;
var<private> global_1: type_7 = type_7(vec4<f32>(0f, 0f, 0f, 1f), 1f, array<f32, 1>(), array<f32, 1>());
@group(3) @binding(0) 
var<uniform> global_2: type_10;
var<private> global_3: vec2<f32>;

fn function_() {
    let _e12 = global;
    let _e16 = f32(((_e12 << bitcast<u32>(1i)) & 2i));
    let _e18 = f32((_e12 & 2i));
    let _e23 = global_2.member;
    let _e24 = (((vec2<f32>(_e16, _e18) * 2f) - vec2<f32>(1f, 1f)) * _e23);
    global_1.member = vec4<f32>(_e24.x, _e24.y, 0f, 1f);
    let _e31 = global_1.member[1u];
    global_1.member[1u] = -(_e31);
    global_3 = vec2<f32>(_e16, (1f - _e18));
    return;
}

@vertex 
fn main(@builtin(vertex_index) param: u32) -> VertexOutput {
    global = i32(param);
    function_();
    let _e7 = global_1.member.y;
    global_1.member.y = -(_e7);
    let _e9 = global_1.member;
    let _e10 = global_3;
    return VertexOutput(_e9, _e10);
}
