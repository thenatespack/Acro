// Generated from mesh_paint.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: e5c14131eac519c0
// glsl-fnv1a64: b6f2324cb671e9d1

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
    member_2: mat4x4<f32>,
    member_3: mat4x4<f32>,
    member_4: vec4<f32>,
    member_5: vec4<f32>,
    member_6: vec4<f32>,
    member_7: vec4<f32>,
    member_8: vec4<f32>,
    member_9: vec4<f32>,
    member_10: vec4<f32>,
}

struct VertexOutput {
    @builtin(position) member: vec4<f32>,
    @location(0) member_1: vec3<f32>,
    @location(1) member_2: vec3<f32>,
    @location(2) member_3: vec2<f32>,
    @location(3) member_4: vec4<f32>,
    @location(5) member_5: vec4<f32>,
    @location(6) member_6: vec4<f32>,
    @location(7) member_7: vec4<f32>,
    @location(8) member_8: vec4<f32>,
    @location(4) member_9: vec3<f32>,
    @location(9) member_10: vec4<f32>,
    @location(10) member_11: vec4<f32>,
}

var<private> global: vec4<f32>;
var<private> global_1: vec4<f32>;
var<private> global_2: vec4<f32>;
var<private> global_3: vec4<f32>;
var<private> global_4: vec4<f32>;
var<private> global_5: vec4<f32>;
var<private> global_6: vec4<f32>;
var<private> global_7: vec4<f32>;
var<private> global_8: vec3<f32>;
var<private> global_9: type_10 = type_10(vec4<f32>(0f, 0f, 0f, 1f), 1f, array<f32, 1>(), array<f32, 1>());
@group(0) @binding(0) 
var<uniform> global_10: type_13;
var<private> global_11: vec3<f32>;
var<private> global_12: vec3<f32>;
var<private> global_13: vec3<f32>;
var<private> global_14: vec2<f32>;
var<private> global_15: vec2<f32>;
var<private> global_16: vec4<f32>;
var<private> global_17: vec4<f32>;
var<private> global_18: vec4<f32>;
var<private> global_19: vec4<f32>;
var<private> global_20: vec4<f32>;
var<private> global_21: vec4<f32>;
var<private> global_22: vec4<f32>;
var<private> global_23: vec4<f32>;
var<private> global_24: vec3<f32>;
var<private> global_25: vec4<f32>;
var<private> global_26: vec4<f32>;
var<private> global_27: vec4<f32>;
var<private> global_28: vec4<f32>;

fn function_() {
    let _e37 = global;
    let _e38 = global_1;
    let _e39 = global_2;
    let _e40 = global_3;
    let _e42 = global_4;
    let _e43 = global_5;
    let _e44 = global_6;
    let _e45 = global_7;
    let _e47 = global_8;
    let _e51 = vec4<f32>(_e47.x, _e47.y, _e47.z, 1f);
    let _e52 = (mat4x4<f32>(_e37, _e38, _e39, _e40) * _e51);
    let _e54 = _e37.xyz;
    let _e55 = _e38.xyz;
    let _e56 = _e39.xyz;
    let _e59 = cross(_e54, _e55);
    let _e63 = select(1f, -1f, (dot(_e59, _e56) < 0f));
    let _e65 = global_10.member;
    global_9.member = (_e65 * _e52);
    let _e70 = global_9.member[1u];
    global_9.member[1u] = -(_e70);
    global_11 = _e52.xyz;
    let _e73 = global_13;
    global_12 = ((mat3x3<f32>(cross(_e55, _e56), cross(_e56, _e54), _e59) * _e73) * _e63);
    let _e76 = global_15;
    global_14 = _e76;
    let _e77 = global_17;
    global_16 = _e77;
    let _e78 = global_19;
    global_18 = _e78;
    let _e80 = global_10.member_2;
    global_20 = (_e80 * _e52);
    let _e83 = global_10.member_3;
    global_21 = (_e83 * (mat4x4<f32>(_e42, _e43, _e44, _e45) * _e51));
    let _e98 = global_23;
    let _e100 = (mat3x3<f32>(vec3<f32>(_e37.x, _e37.y, _e37.z), vec3<f32>(_e38.x, _e38.y, _e38.z), vec3<f32>(_e39.x, _e39.y, _e39.z)) * _e98.xyz);
    let _e102 = global_23[3u];
    global_22 = vec4<f32>(_e100.x, _e100.y, _e100.z, (_e102 * _e63));
    global_24 = _e47;
    let _e108 = global_26;
    global_25 = _e108;
    let _e109 = global_28;
    global_27 = _e109;
    return;
}

@vertex 
fn main(@location(3) param: vec4<f32>, @location(4) param_1: vec4<f32>, @location(5) param_2: vec4<f32>, @location(6) param_3: vec4<f32>, @location(7) param_4: vec4<f32>, @location(8) param_5: vec4<f32>, @location(9) param_6: vec4<f32>, @location(10) param_7: vec4<f32>, @location(0) param_8: vec3<f32>, @location(1) param_9: vec3<f32>, @location(2) param_10: vec2<f32>, @location(11) param_11: vec4<f32>, @location(12) param_12: vec4<f32>, @location(13) param_13: vec4<f32>, @location(14) param_14: vec4<f32>, @location(15) param_15: vec4<f32>) -> VertexOutput {
    global = param;
    global_1 = param_1;
    global_2 = param_2;
    global_3 = param_3;
    global_4 = param_4;
    global_5 = param_5;
    global_6 = param_6;
    global_7 = param_7;
    global_8 = param_8;
    global_13 = param_9;
    global_15 = param_10;
    global_17 = param_11;
    global_19 = param_12;
    global_23 = param_13;
    global_26 = param_14;
    global_28 = param_15;
    function_();
    let _e46 = global_9.member.y;
    global_9.member.y = -(_e46);
    let _e48 = global_9.member;
    let _e49 = global_11;
    let _e50 = global_12;
    let _e51 = global_14;
    let _e52 = global_16;
    let _e53 = global_18;
    let _e54 = global_20;
    let _e55 = global_21;
    let _e56 = global_22;
    let _e57 = global_24;
    let _e58 = global_25;
    let _e59 = global_27;
    return VertexOutput(_e48, _e49, _e50, _e51, _e52, _e53, _e54, _e55, _e56, _e57, _e58, _e59);
}
