// Generated from test_storage_draw.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: effb75d5503ba7d4
// glsl-fnv1a64: f15c6698ad57ead3

diagnostic(off, derivative_uniformity);

struct type_4 {
    @builtin(position) member: vec4<f32>,
    member_1: f32,
    member_2: array<f32, 1>,
    member_3: array<f32, 1>,
}

struct type_8 {
    member: array<vec4<f32>>,
}

var<private> global: type_4 = type_4(vec4<f32>(0f, 0f, 0f, 1f), 1f, array<f32, 1>(), array<f32, 1>());
@group(2) @binding(24) 
var<storage> global_1: type_8;
var<private> global_2: i32;

fn function_() {
    let _e5 = global_2;
    let _e8 = global_1.member[_e5];
    global.member = _e8;
    let _e12 = global.member[1u];
    global.member[1u] = -(_e12);
    return;
}

@vertex 
fn main(@builtin(vertex_index) param: u32) -> @builtin(position) vec4<f32> {
    global_2 = i32(param);
    function_();
    let _e6 = global.member.y;
    global.member.y = -(_e6);
    let _e8 = global.member;
    return _e8;
}
