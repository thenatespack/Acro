// Generated from mesh_fur.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: 9cc1befe1d69ec6a
// glsl-fnv1a64: c770a578588d3aa5

diagnostic(off, derivative_uniformity);

struct type_9 {
    member: array<vec4<f32>, 8>,
    member_1: array<vec4<f32>, 8>,
}

struct type_18 {
    member: mat4x4<f32>,
    member_1: mat4x4<f32>,
    member_2: mat4x4<f32>,
    member_3: mat4x4<f32>,
}

struct type_22 {
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
    @location(9) member_9: vec3<f32>,
    @location(4) member_10: vec3<f32>,
    @location(10) member_11: vec3<f32>,
}

var<private> global: vec4<f32>;
@group(2) @binding(2) 
var<uniform> global_1: type_9;
var<private> global_2: vec3<f32>;
var<private> global_3: vec3<f32>;
var<private> global_4: vec2<f32>;
var<private> global_5: vec4<f32>;
var<private> global_6: vec4<f32>;
var<private> global_7: vec4<f32>;
var<private> global_8: vec4<f32>;
var<private> global_9: vec4<f32>;
var<private> global_10: vec4<f32>;
var<private> global_11: vec4<f32>;
var<private> global_12: vec4<f32>;
var<private> global_13: vec4<f32>;
@group(0) @binding(0) 
var<uniform> global_14: type_18;
var<private> global_15: type_22 = type_22(vec4<f32>(0f, 0f, 0f, 1f), 1f, array<f32, 1>(), array<f32, 1>());
var<private> global_16: vec3<f32>;
var<private> global_17: vec3<f32>;
var<private> global_18: vec2<f32>;
var<private> global_19: vec4<f32>;
var<private> global_20: vec4<f32>;
var<private> global_21: vec4<f32>;
var<private> global_22: vec4<f32>;
var<private> global_23: vec4<f32>;
var<private> global_24: vec4<f32>;
var<private> global_25: vec3<f32>;
var<private> global_26: vec3<f32>;
var<private> global_27: vec3<f32>;

fn function_() {
    var phi_1313_: vec3<f32>;
    var phi_1315_: vec3<f32>;
    var phi_1314_: vec3<f32>;
    var local: vec4<f32>;
    var local_1: vec3<f32>;
    var local_2: vec2<f32>;
    var local_3: f32;
    var local_4: f32;
    var local_5: vec3<f32>;
    var local_6: vec3<f32>;
    var local_7: f32;
    var local_8: bool;
    var local_9: f32;
    var local_10: f32;
    var phi_1317_: vec3<f32>;
    var phi_1318_: vec3<f32>;
    var local_11: vec3<f32>;
    var local_12: vec3<f32>;
    var local_13: mat3x3<f32>;
    var local_14: vec3<f32>;
    var local_15: bool;
    var phi_1319_: f32;
    var local_16: bool;
    var phi_1320_: f32;
    var local_17: bool;
    var local_18: bool;
    var phi_634_: bool;
    var local_19: vec3<f32>;
    var local_20: vec3<f32>;

    let _e68 = global_6;
    let _e69 = global_7;
    let _e70 = global_8;
    let _e71 = global_9;
    let _e73 = global_10;
    let _e74 = global_11;
    let _e75 = global_12;
    let _e76 = global_13;
    let _e81 = global_1.member_1[6i][0u];
    switch bitcast<i32>(0u) {
        default: {
            let _e83 = global_2;
            let _e87 = vec4<f32>(_e83.x, _e83.y, _e83.z, 1f);
            let _e89 = (mat4x4<f32>(_e68, _e69, _e70, _e71) * _e87).xyz;
            let _e90 = _e68.xyz;
            let _e91 = _e69.xyz;
            let _e92 = _e70.xyz;
            let _e95 = cross(_e90, _e91);
            let _e96 = mat3x3<f32>(cross(_e91, _e92), cross(_e92, _e90), _e95);
            let _e100 = global_3;
            let _e103 = normalize(((_e96 * _e100) * select(1f, -1f, (dot(_e95, _e92) < 0f))));
            let _e107 = global_1.member_1[2i][0u];
            let _e111 = global_1.member_1[3i][3u];
            let _e112 = (_e111 > 0.5f);
            let _e116 = global_1.member_1[5i];
            let _e117 = _e116.xy;
            let _e118 = _e71.xz;
            let _e123 = ((dot(_e118, _e117) * 0.35f) + (dot(_e118, vec2<f32>(0.83f, -0.57f)) * 1.7f));
            let _e137 = global_1.member_1[5i][3u];
            let _e143 = (dot(_e71.xyz, vec3<f32>(3.1f, 2.3f, 2.7f)) * 3f);
            let _e156 = vec3<f32>(_e116.x, 0f, _e116.y);
            let _e160 = global_1.member_1[5i][2u];
            let _e166 = global[2u];
            let _e168 = global[3u];
            let _e173 = global_1.member_1[0i][0u];
            let _e176 = (vec3<f32>(_e166, 0f, _e168) / vec3(max(_e173, 0.001f)));
            let _e178 = (((_e156 * (((_e160 * (1f + (_e137 * (((0.5f + ((0.5f * sin(((_e81 * 0.61f) + _e123))) * sin(((_e81 * 0.23f) + (_e123 * 0.7f))))) * 1.6f) - 0.6f)))) * (0.7f + ((0.3f * sin(((_e81 * 4.7f) + _e143))) * sin(((_e81 * 2.9f) + (_e143 * 0.37f)))))) * 0.35f)) + _e176) * _e107);
            local = _e87;
            local_1 = _e100;
            local_2 = _e117;
            local_3 = _e137;
            local_4 = _e160;
            local_5 = _e156;
            local_6 = _e176;
            local_7 = _e107;
            local_8 = _e112;
            local_9 = _e173;
            local_10 = _e173;
            local_11 = _e95;
            local_12 = _e92;
            local_13 = _e96;
            local_14 = _e100;
            local_15 = _e112;
            local_16 = _e112;
            local_17 = _e112;
            local_18 = _e112;
            local_19 = _e83;
            local_20 = _e100;
            if _e112 {
                let _e180 = global_4[1u];
                let _e194 = global_5;
                phi_1315_ = normalize(((mat3x3<f32>(vec3<f32>(_e68.x, _e68.y, _e68.z), vec3<f32>(_e69.x, _e69.y, _e69.z), vec3<f32>(_e70.x, _e70.y, _e70.z)) * _e194.xyz) + (_e178 * (2f * _e180))));
                phi_1314_ = (_e89 + (_e178 * ((_e173 * _e180) * _e180)));
                break;
            }
            let _e206 = global[1u];
            let _e208 = global_5[3u];
            let _e211 = (_e173 * max((_e208 - 1f), 0f));
            if (_e206 <= 0f) {
                phi_1315_ = _e103;
                phi_1314_ = (_e89 + (_e103 * ((_e211 * 0.04f) + 0.0004f)));
                break;
            }
            let _e230 = global_5;
            let _e232 = (mat3x3<f32>(vec3<f32>(_e68.x, _e68.y, _e68.z), vec3<f32>(_e69.x, _e69.y, _e69.z), vec3<f32>(_e70.x, _e70.y, _e70.z)) * _e230.xyz);
            let _e234 = min(length(_e232), 1f);
            let _e238 = global_1.member_1[1i][3u];
            let _e241 = (vec3<f32>(0f, -(_e238), 0f) + _e178);
            let _e255 = (_e211 * _e206);
            let _e256 = (normalize((((_e103 * (1f - _e234)) + _e232) + (_e241 * (0.5f * _e206)))) * _e255);
            let _e257 = dot(_e256, _e103);
            let _e258 = (_e255 * 0.12f);
            phi_1313_ = _e256;
            if (_e257 < _e258) {
                phi_1313_ = (_e256 + (_e103 * (_e258 - _e257)));
            }
            let _e264 = phi_1313_;
            phi_1315_ = normalize((((_e103 * (1f - _e234)) + _e232) + (_e241 * _e206)));
            phi_1314_ = (_e89 + _e264);
            break;
        }
    }
    let _e267 = phi_1315_;
    let _e269 = phi_1314_;
    let _e273 = global_1.member_1[6i][1u];
    switch bitcast<i32>(0u) {
        default: {
            let _e276 = local;
            let _e278 = (mat4x4<f32>(_e73, _e74, _e75, _e76) * _e276).xyz;
            let _e279 = _e73.xyz;
            let _e280 = _e74.xyz;
            let _e281 = _e75.xyz;
            let _e284 = cross(_e279, _e280);
            let _e290 = local_1;
            let _e293 = normalize(((mat3x3<f32>(cross(_e280, _e281), cross(_e281, _e279), _e284) * _e290) * select(1f, -1f, (dot(_e284, _e281) < 0f))));
            let _e295 = _e76.xz;
            let _e297 = local_2;
            let _e302 = ((dot(_e295, _e297) * 0.35f) + (dot(_e295, vec2<f32>(0.83f, -0.57f)) * 1.7f));
            let _e316 = local_3;
            let _e320 = (dot(_e76.xyz, vec3<f32>(3.1f, 2.3f, 2.7f)) * 3f);
            let _e332 = local_4;
            let _e337 = local_5;
            let _e340 = local_6;
            let _e343 = local_7;
            let _e344 = (((_e337 * (((_e332 * (1f + (_e316 * (((0.5f + ((0.5f * sin(((_e273 * 0.61f) + _e302))) * sin(((_e273 * 0.23f) + (_e302 * 0.7f))))) * 1.6f) - 0.6f)))) * (0.7f + ((0.3f * sin(((_e273 * 4.7f) + _e320))) * sin(((_e273 * 2.9f) + (_e320 * 0.37f)))))) * 0.35f)) + _e340) * _e343);
            let _e346 = local_8;
            if _e346 {
                let _e348 = global_4[1u];
                let _e350 = local_9;
                phi_1318_ = (_e278 + (_e344 * ((_e350 * _e348) * _e348)));
                break;
            }
            let _e356 = global[1u];
            let _e358 = global_5[3u];
            let _e362 = local_10;
            let _e363 = (_e362 * max((_e358 - 1f), 0f));
            if (_e356 <= 0f) {
                phi_1318_ = (_e278 + (_e293 * ((_e363 * 0.04f) + 0.0004f)));
                break;
            }
            let _e382 = global_5;
            let _e384 = (mat3x3<f32>(vec3<f32>(_e73.x, _e73.y, _e73.z), vec3<f32>(_e74.x, _e74.y, _e74.z), vec3<f32>(_e75.x, _e75.y, _e75.z)) * _e382.xyz);
            let _e390 = global_1.member_1[1i][3u];
            let _e401 = (_e363 * _e356);
            let _e402 = (normalize((((_e293 * (1f - min(length(_e384), 1f))) + _e384) + ((vec3<f32>(0f, -(_e390), 0f) + _e344) * (0.5f * _e356)))) * _e401);
            let _e403 = dot(_e402, _e293);
            let _e404 = (_e401 * 0.12f);
            phi_1317_ = _e402;
            if (_e403 < _e404) {
                phi_1317_ = (_e402 + (_e293 * (_e404 - _e403)));
            }
            let _e410 = phi_1317_;
            phi_1318_ = (_e278 + _e410);
            break;
        }
    }
    let _e413 = phi_1318_;
    let _e415 = local_11;
    let _e417 = local_12;
    let _e422 = global_14.member;
    let _e426 = vec4<f32>(_e269.x, _e269.y, _e269.z, 1f);
    global_15.member = (_e422 * _e426);
    let _e431 = global_15.member[1u];
    global_15.member[1u] = -(_e431);
    global_16 = _e269;
    let _e434 = local_13;
    let _e436 = local_14;
    global_17 = ((_e434 * _e436) * select(1f, -1f, (dot(_e415, _e417) < 0f)));
    let _e439 = global_4;
    global_18 = _e439;
    let _e440 = global_20;
    global_19 = _e440;
    let _e442 = global[0u];
    global_21 = vec4<f32>(_e442, 0f, 0f, 0f);
    let _e445 = global_14.member_2;
    let _e448 = global_14.member_3;
    global_22 = (_e445 * _e426);
    global_23 = (_e448 * vec4<f32>(_e413.x, _e413.y, _e413.z, 1f));
    let _e455 = local_15;
    if _e455 {
        let _e457 = global_4[1u];
        phi_1319_ = _e457;
    } else {
        let _e459 = global[1u];
        phi_1319_ = _e459;
    }
    let _e461 = phi_1319_;
    let _e463 = local_16;
    if _e463 {
        let _e465 = global_5[3u];
        phi_1320_ = fract(_e465);
    } else {
        phi_1320_ = 0f;
    }
    let _e468 = phi_1320_;
    let _e470 = local_17;
    let _e473 = local_18;
    let _e474 = !(_e473);
    phi_634_ = _e474;
    if _e474 {
        let _e476 = global[1u];
        phi_634_ = (_e476 <= 0f);
    }
    let _e479 = phi_634_;
    global_24 = vec4<f32>(_e461, _e468, select(0f, 1f, _e470), select(0f, 1f, _e479));
    global_25 = _e267;
    let _e483 = local_19;
    global_26 = _e483;
    let _e485 = local_20;
    global_27 = _e485;
    return;
}

@vertex 
fn main(@location(12) param: vec4<f32>, @location(0) param_1: vec3<f32>, @location(1) param_2: vec3<f32>, @location(2) param_3: vec2<f32>, @location(13) param_4: vec4<f32>, @location(3) param_5: vec4<f32>, @location(4) param_6: vec4<f32>, @location(5) param_7: vec4<f32>, @location(6) param_8: vec4<f32>, @location(7) param_9: vec4<f32>, @location(8) param_10: vec4<f32>, @location(9) param_11: vec4<f32>, @location(10) param_12: vec4<f32>, @location(11) param_13: vec4<f32>) -> VertexOutput {
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
    global_12 = param_11;
    global_13 = param_12;
    global_20 = param_13;
    function_();
    let _e42 = global_15.member.y;
    global_15.member.y = -(_e42);
    let _e44 = global_15.member;
    let _e45 = global_16;
    let _e46 = global_17;
    let _e47 = global_18;
    let _e48 = global_19;
    let _e49 = global_21;
    let _e50 = global_22;
    let _e51 = global_23;
    let _e52 = global_24;
    let _e53 = global_25;
    let _e54 = global_26;
    let _e55 = global_27;
    return VertexOutput(_e44, _e45, _e46, _e47, _e48, _e49, _e50, _e51, _e52, _e53, _e54, _e55);
}
