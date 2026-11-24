// Generated from taau.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: 5e5203b53f286cc8
// glsl-fnv1a64: 76eadab7dc82f085

diagnostic(off, derivative_uniformity);

struct type_7 {
    @builtin(position) member: vec4<f32>,
    member_1: f32,
    member_2: array<f32, 1>,
    member_3: array<f32, 1>,
}

var<private> global: i32;
var<private> global_1: type_7 = type_7(vec4<f32>(0f, 0f, 0f, 1f), 1f, array<f32, 1>(), array<f32, 1>());

fn function_() {
    let _e10 = global;
    let _e19 = ((vec2<f32>(f32(((_e10 << bitcast<u32>(1i)) & 2i)), f32((_e10 & 2i))) * 2f) - vec2<f32>(1f, 1f));
    global_1.member = vec4<f32>(_e19.x, _e19.y, 0f, 1f);
    let _e26 = global_1.member[1u];
    global_1.member[1u] = -(_e26);
    return;
}

@vertex 
fn main(@builtin(vertex_index) param: u32) -> @builtin(position) vec4<f32> {
    global = i32(param);
    function_();
    let _e6 = global_1.member.y;
    global_1.member.y = -(_e6);
    let _e8 = global_1.member;
    return _e8;
}
