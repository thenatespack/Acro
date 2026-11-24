// Generated from lit.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: 3d0088b72cef6f52
// glsl-fnv1a64: 882ebf60aa24c3fa

diagnostic(off, derivative_uniformity);

struct type_10 {
    member: mat4x4<f32>,
    member_1: mat4x4<f32>,
    member_2: vec4<f32>,
    member_3: vec4<f32>,
    member_4: vec4<f32>,
    member_5: vec4<f32>,
    member_6: mat4x4<f32>,
    member_7: mat4x4<f32>,
    member_8: vec4<f32>,
}

struct type_15 {
    @builtin(position) member: vec4<f32>,
    member_1: f32,
    member_2: array<f32, 1>,
    member_3: array<f32, 1>,
}

struct VertexOutput {
    @builtin(position) member: vec4<f32>,
    @location(0) member_1: vec3<f32>,
    @location(1) member_2: vec3<f32>,
    @location(2) member_3: vec4<f32>,
    @location(4) member_4: vec4<f32>,
    @location(3) member_5: vec4<f32>,
    @location(5) member_6: vec4<f32>,
    @location(6) member_7: vec4<f32>,
}

var<private> global: vec4<f32>;
var<private> global_1: vec4<f32>;
var<private> global_2: vec4<f32>;
var<private> global_3: vec4<f32>;
var<private> global_4: vec3<f32>;
var<private> global_5: vec3<f32>;
var<private> global_6: vec4<f32>;
@group(0) @binding(0) 
var<uniform> global_7: type_10;
var<private> global_8: type_15 = type_15(vec4<f32>(0f, 0f, 0f, 1f), 1f, array<f32, 1>(), array<f32, 1>());
var<private> global_9: vec3<f32>;
var<private> global_10: vec3<f32>;
var<private> global_11: vec4<f32>;
var<private> global_12: vec4<f32>;
var<private> global_13: vec4<f32>;
var<private> global_14: vec4<f32>;
var<private> global_15: vec4<f32>;
var<private> global_16: vec4<f32>;

fn function_() {
    var phi_348_: vec4<f32>;
    var phi_347_: vec3<f32>;
    var phi_346_: vec4<f32>;

    let _e30 = global;
    let _e31 = global_1;
    let _e32 = global_2;
    let _e33 = global_3;
    let _e34 = mat4x4<f32>(_e30, _e31, _e32, _e33);
    let _e35 = global_4;
    let _e36 = global_5;
    let _e38 = global_6[3u];
    if (_e38 > 0f) {
        let _e40 = global_6;
        let _e43 = global_7.member_3[3u];
        let _e45 = (_e43 + _e40.z);
        let _e46 = cos(_e45);
        let _e47 = sin(_e45);
        let _e51 = mat3x3<f32>(vec3<f32>(_e46, 0f, -(_e47)), vec3<f32>(0f, 1f, 0f), vec3<f32>(_e47, 0f, _e46));
        let _e52 = (_e51 * _e35);
        let _e68 = global_7.member_8[0u];
        let _e69 = (_e68 + _e40.z);
        let _e70 = cos(_e69);
        let _e71 = sin(_e69);
        let _e76 = (mat3x3<f32>(vec3<f32>(_e70, 0f, -(_e71)), vec3<f32>(0f, 1f, 0f), vec3<f32>(_e71, 0f, _e70)) * _e35);
        phi_348_ = ((_e34 * vec4<f32>(_e76.x, _e76.y, _e76.z, 1f)) + vec4<f32>(0f, (sin(((_e68 * 2f) + _e40.z)) * _e40.w), 0f, 0f));
        phi_347_ = (_e51 * _e36);
        phi_346_ = ((_e34 * vec4<f32>(_e52.x, _e52.y, _e52.z, 1f)) + vec4<f32>(0f, (sin(((_e43 * 2f) + _e40.z)) * _e40.w), 0f, 0f));
    } else {
        let _e92 = (_e34 * vec4<f32>(_e35.x, _e35.y, _e35.z, 1f));
        phi_348_ = _e92;
        phi_347_ = _e36;
        phi_346_ = _e92;
    }
    let _e94 = phi_348_;
    let _e96 = phi_347_;
    let _e98 = phi_346_;
    let _e99 = _e30.xyz;
    let _e101 = _e31.xyz;
    let _e103 = _e32.xyz;
    let _e120 = global_7.member;
    global_8.member = (_e120 * _e98);
    let _e125 = global_8.member[1u];
    global_8.member[1u] = -(_e125);
    global_9 = _e98.xyz;
    global_10 = (mat3x3<f32>(vec3<f32>(_e30.x, _e30.y, _e30.z), vec3<f32>(_e31.x, _e31.y, _e31.z), vec3<f32>(_e32.x, _e32.y, _e32.z)) * (_e96 / vec3<f32>(dot(_e99, _e99), dot(_e101, _e101), dot(_e103, _e103))));
    let _e130 = global_12;
    global_11 = _e130;
    let _e131 = global_6;
    global_13 = _e131;
    let _e133 = global_7.member_1;
    global_14 = (_e133 * _e98);
    let _e136 = global_7.member_6;
    global_15 = (_e136 * _e98);
    let _e139 = global_7.member_7;
    global_16 = (_e139 * _e94);
    return;
}

@vertex 
fn main(@location(2) param: vec4<f32>, @location(3) param_1: vec4<f32>, @location(4) param_2: vec4<f32>, @location(5) param_3: vec4<f32>, @location(0) param_4: vec3<f32>, @location(1) param_5: vec3<f32>, @location(7) param_6: vec4<f32>, @location(6) param_7: vec4<f32>) -> VertexOutput {
    global = param;
    global_1 = param_1;
    global_2 = param_2;
    global_3 = param_3;
    global_4 = param_4;
    global_5 = param_5;
    global_6 = param_6;
    global_12 = param_7;
    function_();
    let _e26 = global_8.member.y;
    global_8.member.y = -(_e26);
    let _e28 = global_8.member;
    let _e29 = global_9;
    let _e30 = global_10;
    let _e31 = global_11;
    let _e32 = global_13;
    let _e33 = global_14;
    let _e34 = global_15;
    let _e35 = global_16;
    return VertexOutput(_e28, _e29, _e30, _e31, _e32, _e33, _e34, _e35);
}
