// Generated from mesh_skinned.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: acd4e7dc470d319a
// glsl-fnv1a64: d5e47112554e85b0

diagnostic(off, derivative_uniformity);

struct type_10 {
    member: array<vec4<f32>, 8>,
    member_1: array<vec4<f32>, 384>,
    member_2: array<vec4<f32>, 384>,
}

struct type_16 {
    member: mat4x4<f32>,
    member_1: mat4x4<f32>,
    member_2: mat4x4<f32>,
    member_3: mat4x4<f32>,
}

struct type_20 {
    @builtin(position) member: vec4<f32>,
    member_1: f32,
    member_2: array<f32, 1>,
    member_3: array<f32, 1>,
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
@group(2) @binding(2) 
var<uniform> global_1: type_10;
var<private> global_2: vec4<f32>;
var<private> global_3: vec4<f32>;
var<private> global_4: vec4<f32>;
var<private> global_5: vec4<f32>;
var<private> global_6: vec4<f32>;
var<private> global_7: vec4<f32>;
var<private> global_8: vec4<f32>;
var<private> global_9: vec4<f32>;
var<private> global_10: vec4<f32>;
var<private> global_11: vec3<f32>;
@group(0) @binding(0) 
var<uniform> global_12: type_16;
var<private> global_13: type_20 = type_20(vec4<f32>(0f, 0f, 0f, 1f), 1f, array<f32, 1>(), array<f32, 1>());
var<private> global_14: vec3<f32>;
var<private> global_15: vec3<f32>;
var<private> global_16: vec3<f32>;
var<private> global_17: vec2<f32>;
var<private> global_18: vec2<f32>;
var<private> global_19: vec4<f32>;
var<private> global_20: vec4<f32>;
var<private> global_21: vec4<f32>;
var<private> global_22: vec4<f32>;
var<private> global_23: vec4<f32>;
var<private> global_24: vec4<f32>;
var<private> global_25: vec4<f32>;
var<private> global_26: vec4<f32>;
var<private> global_27: vec3<f32>;

fn function_() {
    var phi_570_: vec4<f32>;
    var phi_569_: vec4<f32>;
    var phi_568_: vec4<f32>;
    var phi_567_: i32;
    var local: vec4<f32>;
    var local_1: vec4<f32>;
    var local_2: vec4<f32>;
    var phi_574_: vec4<f32>;
    var phi_573_: vec4<f32>;
    var phi_572_: vec4<f32>;
    var phi_571_: i32;
    var local_3: vec4<f32>;
    var local_4: vec4<f32>;
    var local_5: vec4<f32>;

    let _e42 = global_3;
    let _e43 = global_4;
    let _e44 = global_5;
    let _e45 = global_6;
    phi_570_ = vec4<f32>(0f, 0f, 0f, 0f);
    phi_569_ = vec4<f32>(0f, 0f, 0f, 0f);
    phi_568_ = vec4<f32>(0f, 0f, 0f, 0f);
    phi_567_ = 0i;
    loop {
        let _e48 = phi_570_;
        let _e50 = phi_569_;
        let _e52 = phi_568_;
        let _e54 = phi_567_;
        local = _e52;
        local_1 = _e50;
        local_2 = _e48;
        if (_e54 < 4i) {
            continue;
        } else {
            break;
        }
        continuing {
            let _e57 = global[_e54];
            let _e59 = (i32(_e57) * 3i);
            let _e62 = global_1.member_1[_e59];
            let _e64 = global_2[_e54];
            let _e70 = global_1.member_1[(_e59 + 1i)];
            let _e76 = global_1.member_1[(_e59 + 2i)];
            phi_570_ = (_e48 + (_e76 * _e64));
            phi_569_ = (_e50 + (_e70 * _e64));
            phi_568_ = (_e52 + (_e62 * _e64));
            phi_567_ = (_e54 + 1i);
        }
    }
    let _e81 = local;
    let _e83 = local_1;
    let _e85 = local_2;
    let _e88 = (mat4x4<f32>(_e42, _e43, _e44, _e45) * transpose(mat4x4<f32>(_e81, _e83, _e85, vec4<f32>(0f, 0f, 0f, 1f))));
    let _e89 = global_7;
    let _e90 = global_8;
    let _e91 = global_9;
    let _e92 = global_10;
    phi_574_ = vec4<f32>(0f, 0f, 0f, 0f);
    phi_573_ = vec4<f32>(0f, 0f, 0f, 0f);
    phi_572_ = vec4<f32>(0f, 0f, 0f, 0f);
    phi_571_ = 0i;
    loop {
        let _e95 = phi_574_;
        let _e97 = phi_573_;
        let _e99 = phi_572_;
        let _e101 = phi_571_;
        local_3 = _e99;
        local_4 = _e97;
        local_5 = _e95;
        if (_e101 < 4i) {
            continue;
        } else {
            break;
        }
        continuing {
            let _e104 = global[_e101];
            let _e106 = (i32(_e104) * 3i);
            let _e109 = global_1.member_2[_e106];
            let _e111 = global_2[_e101];
            let _e117 = global_1.member_2[(_e106 + 1i)];
            let _e123 = global_1.member_2[(_e106 + 2i)];
            phi_574_ = (_e95 + (_e123 * _e111));
            phi_573_ = (_e97 + (_e117 * _e111));
            phi_572_ = (_e99 + (_e109 * _e111));
            phi_571_ = (_e101 + 1i);
        }
    }
    let _e128 = local_3;
    let _e130 = local_4;
    let _e132 = local_5;
    let _e136 = global_11;
    let _e140 = vec4<f32>(_e136.x, _e136.y, _e136.z, 1f);
    let _e141 = (_e88 * _e140);
    let _e144 = _e88[0].xyz;
    let _e146 = _e88[1].xyz;
    let _e148 = _e88[2].xyz;
    let _e151 = cross(_e144, _e146);
    let _e155 = select(1f, -1f, (dot(_e151, _e148) < 0f));
    let _e157 = global_12.member;
    global_13.member = (_e157 * _e141);
    let _e162 = global_13.member[1u];
    global_13.member[1u] = -(_e162);
    global_14 = _e141.xyz;
    let _e165 = global_16;
    global_15 = ((mat3x3<f32>(cross(_e146, _e148), cross(_e148, _e144), _e151) * _e165) * _e155);
    let _e168 = global_18;
    global_17 = _e168;
    let _e169 = global_20;
    global_19 = _e169;
    let _e170 = global_22;
    global_21 = _e170;
    let _e172 = global_12.member_2;
    let _e175 = global_12.member_3;
    global_23 = (_e172 * _e141);
    global_24 = (_e175 * ((mat4x4<f32>(_e89, _e90, _e91, _e92) * transpose(mat4x4<f32>(_e128, _e130, _e132, vec4<f32>(0f, 0f, 0f, 1f)))) * _e140));
    let _e190 = global_26;
    let _e192 = (mat3x3<f32>(vec3<f32>(_e88[0].x, _e88[0].y, _e88[0].z), vec3<f32>(_e88[1].x, _e88[1].y, _e88[1].z), vec3<f32>(_e88[2].x, _e88[2].y, _e88[2].z)) * _e190.xyz);
    let _e194 = global_26[3u];
    global_25 = vec4<f32>(_e192.x, _e192.y, _e192.z, (_e194 * _e155));
    global_27 = _e136;
    return;
}

@vertex 
fn main(@location(14) param: vec4<f32>, @location(15) param_1: vec4<f32>, @location(3) param_2: vec4<f32>, @location(4) param_3: vec4<f32>, @location(5) param_4: vec4<f32>, @location(6) param_5: vec4<f32>, @location(7) param_6: vec4<f32>, @location(8) param_7: vec4<f32>, @location(9) param_8: vec4<f32>, @location(10) param_9: vec4<f32>, @location(0) param_10: vec3<f32>, @location(1) param_11: vec3<f32>, @location(2) param_12: vec2<f32>, @location(11) param_13: vec4<f32>, @location(12) param_14: vec4<f32>, @location(13) param_15: vec4<f32>) -> VertexOutput {
    global = param;
    global_2 = param_1;
    global_3 = param_2;
    global_4 = param_3;
    global_5 = param_4;
    global_6 = param_5;
    global_7 = param_6;
    global_8 = param_7;
    global_9 = param_8;
    global_10 = param_9;
    global_11 = param_10;
    global_16 = param_11;
    global_18 = param_12;
    global_20 = param_13;
    global_22 = param_14;
    global_26 = param_15;
    function_();
    let _e44 = global_13.member.y;
    global_13.member.y = -(_e44);
    let _e46 = global_13.member;
    let _e47 = global_14;
    let _e48 = global_15;
    let _e49 = global_17;
    let _e50 = global_19;
    let _e51 = global_21;
    let _e52 = global_23;
    let _e53 = global_24;
    let _e54 = global_25;
    let _e55 = global_27;
    return VertexOutput(_e46, _e47, _e48, _e49, _e50, _e51, _e52, _e53, _e54, _e55);
}
