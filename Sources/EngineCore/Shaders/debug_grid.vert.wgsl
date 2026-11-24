// Generated from debug_grid.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: c20cafa6caa0cedf
// glsl-fnv1a64: 7ed243f89614a799

diagnostic(off, derivative_uniformity);

struct type_10 {
    member: mat4x4<f32>,
    member_1: vec4<f32>,
    member_2: vec4<f32>,
    member_3: vec4<f32>,
    member_4: vec4<f32>,
    member_5: vec4<f32>,
    member_6: vec4<f32>,
}

struct type_16 {
    @builtin(position) member: vec4<f32>,
    member_1: f32,
    member_2: array<f32, 1>,
    member_3: array<f32, 1>,
}

struct VertexOutput {
    @location(0) member: vec3<f32>,
    @builtin(position) member_1: vec4<f32>,
}

var<private> global: i32;
@group(2) @binding(2) 
var<uniform> global_1: type_10;
var<private> global_2: vec3<f32>;
var<private> global_3: type_16 = type_16(vec4<f32>(0f, 0f, 0f, 1f), 1f, array<f32, 1>(), array<f32, 1>());

fn function_() {
    var local: array<vec2<f32>, 6>;

    let _e20 = global;
    local = array<vec2<f32>, 6>(vec2<f32>(-1f, -1f), vec2<f32>(1f, -1f), vec2<f32>(1f, 1f), vec2<f32>(-1f, -1f), vec2<f32>(1f, 1f), vec2<f32>(-1f, 1f));
    let _e22 = local[_e20];
    let _e25 = global_1.member_2[2u];
    let _e26 = (_e22 * _e25);
    let _e29 = global_1.member_1[0u];
    let _e34 = global_1.member_1[3u];
    let _e37 = global_1.member_1[2u];
    global_2 = vec3<f32>((_e29 + _e26.x), _e34, (_e37 + _e26.y));
    let _e42 = global_1.member;
    let _e43 = global_2;
    global_3.member = (_e42 * vec4<f32>(_e43.x, _e43.y, _e43.z, 1f));
    let _e52 = global_3.member[1u];
    global_3.member[1u] = -(_e52);
    return;
}

@vertex 
fn main(@builtin(vertex_index) param: u32) -> VertexOutput {
    global = i32(param);
    function_();
    let _e7 = global_3.member.y;
    global_3.member.y = -(_e7);
    let _e9 = global_2;
    let _e10 = global_3.member;
    return VertexOutput(_e9, _e10);
}
