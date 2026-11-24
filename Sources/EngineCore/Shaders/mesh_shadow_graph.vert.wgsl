// Generated from mesh_shadow_graph.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: 6133b9a3efa5b550
// glsl-fnv1a64: 6230ab88e9fefa9d

diagnostic(off, derivative_uniformity);

struct type_10 {
    @builtin(position) member: vec4<f32>,
    member_1: f32,
    member_2: array<f32, 1>,
    member_3: array<f32, 1>,
}

struct type_13 {
    member: mat4x4<f32>,
    member_1: mat4x4<f32>,
}

struct VertexOutput {
    @builtin(position) member: vec4<f32>,
    @location(0) member_1: vec3<f32>,
    @location(1) member_2: vec3<f32>,
    @location(2) member_3: vec2<f32>,
    @location(3) member_4: vec4<f32>,
}

var<private> global: vec4<f32>;
var<private> global_1: vec4<f32>;
var<private> global_2: vec4<f32>;
var<private> global_3: vec4<f32>;
var<private> global_4: vec3<f32>;
var<private> global_5: type_10 = type_10(vec4<f32>(0f, 0f, 0f, 1f), 1f, array<f32, 1>(), array<f32, 1>());
@group(0) @binding(0) 
var<uniform> global_6: type_13;
var<private> global_7: vec3<f32>;
var<private> global_8: vec3<f32>;
var<private> global_9: vec3<f32>;
var<private> global_10: vec2<f32>;
var<private> global_11: vec2<f32>;
var<private> global_12: vec4<f32>;
var<private> global_13: vec4<f32>;

fn function_() {
    let _e20 = global;
    let _e21 = global_1;
    let _e22 = global_2;
    let _e23 = global_3;
    let _e25 = global_4;
    let _e30 = (mat4x4<f32>(_e20, _e21, _e22, _e23) * vec4<f32>(_e25.x, _e25.y, _e25.z, 1f));
    let _e31 = _e20.xyz;
    let _e32 = _e21.xyz;
    let _e33 = _e22.xyz;
    let _e36 = cross(_e31, _e32);
    let _e42 = global_6.member_1;
    global_5.member = (_e42 * _e30);
    let _e47 = global_5.member[1u];
    global_5.member[1u] = -(_e47);
    global_7 = _e30.xyz;
    let _e50 = global_9;
    global_8 = ((mat3x3<f32>(cross(_e32, _e33), cross(_e33, _e31), _e36) * _e50) * select(1f, -1f, (dot(_e36, _e33) < 0f)));
    let _e53 = global_11;
    global_10 = _e53;
    let _e54 = global_13;
    global_12 = _e54;
    return;
}

@vertex 
fn main(@location(3) param: vec4<f32>, @location(4) param_1: vec4<f32>, @location(5) param_2: vec4<f32>, @location(6) param_3: vec4<f32>, @location(0) param_4: vec3<f32>, @location(1) param_5: vec3<f32>, @location(2) param_6: vec2<f32>, @location(11) param_7: vec4<f32>) -> VertexOutput {
    global = param;
    global_1 = param_1;
    global_2 = param_2;
    global_3 = param_3;
    global_4 = param_4;
    global_9 = param_5;
    global_11 = param_6;
    global_13 = param_7;
    function_();
    let _e23 = global_5.member.y;
    global_5.member.y = -(_e23);
    let _e25 = global_5.member;
    let _e26 = global_7;
    let _e27 = global_8;
    let _e28 = global_10;
    let _e29 = global_12;
    return VertexOutput(_e25, _e26, _e27, _e28, _e29);
}
