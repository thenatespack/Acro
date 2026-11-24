// Generated from mesh.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: 3b56a08836e44d27
// glsl-fnv1a64: bacf28d0113fec6f

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

fn function_() {
    let _e33 = global;
    let _e34 = global_1;
    let _e35 = global_2;
    let _e36 = global_3;
    let _e38 = global_4;
    let _e39 = global_5;
    let _e40 = global_6;
    let _e41 = global_7;
    let _e43 = global_8;
    let _e47 = vec4<f32>(_e43.x, _e43.y, _e43.z, 1f);
    let _e48 = (mat4x4<f32>(_e33, _e34, _e35, _e36) * _e47);
    let _e50 = _e33.xyz;
    let _e51 = _e34.xyz;
    let _e52 = _e35.xyz;
    let _e55 = cross(_e50, _e51);
    let _e59 = select(1f, -1f, (dot(_e55, _e52) < 0f));
    let _e61 = global_10.member;
    global_9.member = (_e61 * _e48);
    let _e66 = global_9.member[1u];
    global_9.member[1u] = -(_e66);
    global_11 = _e48.xyz;
    let _e69 = global_13;
    global_12 = ((mat3x3<f32>(cross(_e51, _e52), cross(_e52, _e50), _e55) * _e69) * _e59);
    let _e72 = global_15;
    global_14 = _e72;
    let _e73 = global_17;
    global_16 = _e73;
    let _e74 = global_19;
    global_18 = _e74;
    let _e76 = global_10.member_2;
    global_20 = (_e76 * _e48);
    let _e79 = global_10.member_3;
    global_21 = (_e79 * (mat4x4<f32>(_e38, _e39, _e40, _e41) * _e47));
    let _e94 = global_23;
    let _e96 = (mat3x3<f32>(vec3<f32>(_e33.x, _e33.y, _e33.z), vec3<f32>(_e34.x, _e34.y, _e34.z), vec3<f32>(_e35.x, _e35.y, _e35.z)) * _e94.xyz);
    let _e98 = global_23[3u];
    global_22 = vec4<f32>(_e96.x, _e96.y, _e96.z, (_e98 * _e59));
    global_24 = _e43;
    return;
}

@vertex 
fn main(@location(3) param: vec4<f32>, @location(4) param_1: vec4<f32>, @location(5) param_2: vec4<f32>, @location(6) param_3: vec4<f32>, @location(7) param_4: vec4<f32>, @location(8) param_5: vec4<f32>, @location(9) param_6: vec4<f32>, @location(10) param_7: vec4<f32>, @location(0) param_8: vec3<f32>, @location(1) param_9: vec3<f32>, @location(2) param_10: vec2<f32>, @location(11) param_11: vec4<f32>, @location(12) param_12: vec4<f32>, @location(13) param_13: vec4<f32>) -> VertexOutput {
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
    function_();
    let _e40 = global_9.member.y;
    global_9.member.y = -(_e40);
    let _e42 = global_9.member;
    let _e43 = global_11;
    let _e44 = global_12;
    let _e45 = global_14;
    let _e46 = global_16;
    let _e47 = global_18;
    let _e48 = global_20;
    let _e49 = global_21;
    let _e50 = global_22;
    let _e51 = global_24;
    return VertexOutput(_e42, _e43, _e44, _e45, _e46, _e47, _e48, _e49, _e50, _e51);
}
