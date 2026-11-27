// Generated from mesh_fur_sim.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: 59c341b95e6b5bcd
// glsl-fnv1a64: d6a224587197e062

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
    @location(8) member_1: vec4<f32>,
    @location(2) member_2: vec2<f32>,
    @location(4) member_3: vec3<f32>,
    @location(10) member_4: vec3<f32>,
    @location(0) member_5: vec3<f32>,
    @location(1) member_6: vec3<f32>,
    @location(3) member_7: vec4<f32>,
    @location(5) member_8: vec4<f32>,
    @location(6) member_9: vec4<f32>,
    @location(7) member_10: vec4<f32>,
    @location(9) member_11: vec3<f32>,
}

var<private> global: vec4<f32>;
@group(2) @binding(2) 
var<uniform> global_1: type_9;
var<private> global_2: vec3<f32>;
var<private> global_3: vec3<f32>;
var<private> global_4: vec4<f32>;
var<private> global_5: vec2<f32>;
var<private> global_6: vec4<f32>;
var<private> global_7: vec4<f32>;
var<private> global_8: vec4<f32>;
var<private> global_9: vec4<f32>;
var<private> global_10: vec4<f32>;
@group(0) @binding(0) 
var<uniform> global_11: type_18;
var<private> global_12: type_22 = type_22(vec4<f32>(0f, 0f, 0f, 1f), 1f, array<f32, 1>(), array<f32, 1>());
var<private> global_13: vec4<f32>;
var<private> global_14: vec2<f32>;
var<private> global_15: vec3<f32>;
var<private> global_16: vec3<f32>;
var<private> global_17: vec4<f32>;
var<private> global_18: vec3<f32>;
var<private> global_19: vec3<f32>;
var<private> global_20: vec4<f32>;
var<private> global_21: vec4<f32>;
var<private> global_22: vec4<f32>;
var<private> global_23: vec4<f32>;
var<private> global_24: vec3<f32>;

fn function_() {
    var phi_1040_: f32;
    var phi_1041_: vec3<f32>;
    var phi_1043_: vec3<f32>;
    var phi_1042_: vec3<f32>;
    var local: bool;
    var phi_514_: bool;
    var local_1: bool;
    var phi_1045_: f32;
    var local_2: bool;
    var phi_1046_: f32;
    var local_3: bool;
    var phi_1047_: f32;
    var phi_552_: bool;
    var local_4: vec3<f32>;
    var local_5: vec3<f32>;
    var local_6: vec3<f32>;
    var local_7: vec3<f32>;
    var local_8: mat3x3<f32>;
    var local_9: vec3<f32>;

    let _e67 = global_7;
    let _e68 = global_8;
    let _e69 = global_9;
    let _e70 = global_10;
    let _e75 = global_1.member_1[6i][0u];
    switch bitcast<i32>(0u) {
        default: {
            let _e77 = global_2;
            let _e83 = (mat4x4<f32>(_e67, _e68, _e69, _e70) * vec4<f32>(_e77.x, _e77.y, _e77.z, 1f)).xyz;
            let _e84 = _e67.xyz;
            let _e85 = _e68.xyz;
            let _e86 = _e69.xyz;
            let _e89 = cross(_e84, _e85);
            let _e90 = mat3x3<f32>(cross(_e85, _e86), cross(_e86, _e84), _e89);
            let _e94 = global_3;
            let _e97 = normalize(((_e90 * _e94) * select(1f, -1f, (dot(_e89, _e86) < 0f))));
            let _e101 = global_1.member_1[2i][0u];
            let _e105 = global_1.member_1[3i][3u];
            let _e106 = (_e105 > 0.5f);
            let _e108 = global_4[3u];
            let _e114 = global_1.member_1[5i];
            let _e116 = _e70.xz;
            let _e121 = ((dot(_e116, _e114.xy) * 0.35f) + (dot(_e116, vec2<f32>(0.83f, -0.57f)) * 1.7f));
            let _e135 = global_1.member_1[5i][3u];
            let _e141 = (dot(_e70.xyz, vec3<f32>(3.1f, 2.3f, 2.7f)) * 3f);
            let _e158 = global_1.member_1[5i][2u];
            let _e164 = global[2u];
            let _e166 = global[3u];
            let _e171 = global_1.member_1[0i][0u];
            let _e177 = (((vec3<f32>(_e114.x, 0f, _e114.y) * (((_e158 * (1f + (_e135 * (((0.5f + ((0.5f * sin(((_e75 * 0.61f) + _e121))) * sin(((_e75 * 0.23f) + (_e121 * 0.7f))))) * 1.6f) - 0.6f)))) * (0.7f + ((0.3f * sin(((_e75 * 4.7f) + _e141))) * sin(((_e75 * 2.9f) + (_e141 * 0.37f)))))) * 0.35f)) + (vec3<f32>(_e164, 0f, _e166) / vec3(max(_e171, 0.001f)))) * (_e101 * select(1f, 0f, (_e108 < -0.5f))));
            local = _e106;
            local_1 = _e106;
            local_2 = _e106;
            local_3 = _e106;
            local_4 = _e77;
            local_5 = _e94;
            local_6 = _e89;
            local_7 = _e86;
            local_8 = _e90;
            local_9 = _e94;
            if _e106 {
                let _e179 = global_5[1u];
                let _e193 = global_6;
                phi_1043_ = normalize(((mat3x3<f32>(vec3<f32>(_e67.x, _e67.y, _e67.z), vec3<f32>(_e68.x, _e68.y, _e68.z), vec3<f32>(_e69.x, _e69.y, _e69.z)) * _e193.xyz) + (_e177 * (2f * _e179))));
                phi_1042_ = (_e83 + (_e177 * ((_e171 * _e179) * _e179)));
                break;
            }
            let _e205 = global[1u];
            let _e206 = (_e205 > 1.5f);
            if _e206 {
                let _e208 = global_5[1u];
                phi_1040_ = _e208;
            } else {
                phi_1040_ = _e205;
            }
            let _e210 = phi_1040_;
            let _e212 = global_6[3u];
            let _e215 = (_e171 * max((_e212 - 1f), 0f));
            if ((_e210 <= 0f) && !(_e206)) {
                phi_1043_ = _e97;
                phi_1042_ = (_e83 + (_e97 * ((_e215 * 0.04f) + 0.0004f)));
                break;
            }
            let _e236 = global_6;
            let _e238 = (mat3x3<f32>(vec3<f32>(_e67.x, _e67.y, _e67.z), vec3<f32>(_e68.x, _e68.y, _e68.z), vec3<f32>(_e69.x, _e69.y, _e69.z)) * _e236.xyz);
            let _e240 = min(length(_e238), 1f);
            let _e244 = global_1.member_1[1i][3u];
            let _e247 = (vec3<f32>(0f, -(_e244), 0f) + _e177);
            let _e261 = (_e215 * _e210);
            let _e262 = (normalize((((_e97 * (1f - _e240)) + _e238) + (_e247 * (0.5f * _e210)))) * _e261);
            let _e263 = dot(_e262, _e97);
            let _e264 = (_e261 * 0.12f);
            phi_1041_ = _e262;
            if (_e263 < _e264) {
                phi_1041_ = (_e262 + (_e97 * (_e264 - _e263)));
            }
            let _e270 = phi_1041_;
            phi_1043_ = normalize((((_e97 * (1f - _e240)) + _e238) + (_e247 * _e210)));
            phi_1042_ = (_e83 + _e270);
            break;
        }
    }
    let _e273 = phi_1043_;
    let _e275 = phi_1042_;
    let _e277 = global_11.member;
    let _e281 = vec4<f32>(_e275.x, _e275.y, _e275.z, 1f);
    global_12.member = (_e277 * _e281);
    let _e286 = global_12.member[1u];
    global_12.member[1u] = -(_e286);
    let _e289 = local;
    let _e290 = !(_e289);
    phi_514_ = _e290;
    if _e290 {
        let _e292 = global[1u];
        phi_514_ = (_e292 > 1.5f);
    }
    let _e295 = phi_514_;
    let _e297 = local_1;
    if (_e297 || _e295) {
        let _e300 = global_5[1u];
        phi_1045_ = _e300;
    } else {
        let _e302 = global[1u];
        phi_1045_ = _e302;
    }
    let _e304 = phi_1045_;
    let _e306 = local_2;
    if _e306 {
        let _e308 = global_6[3u];
        phi_1046_ = fract(_e308);
    } else {
        phi_1046_ = 0f;
    }
    let _e311 = phi_1046_;
    let _e313 = local_3;
    if _e313 {
        phi_1047_ = 1f;
    } else {
        phi_1047_ = select(0f, 2f, _e295);
    }
    let _e316 = phi_1047_;
    phi_552_ = _e290;
    if _e290 {
        let _e318 = global[1u];
        phi_552_ = (_e318 <= 0f);
    }
    let _e321 = phi_552_;
    global_13 = vec4<f32>(_e304, _e311, _e316, select(0f, 1f, _e321));
    let _e324 = global_5;
    global_14 = _e324;
    let _e326 = local_4;
    global_15 = _e326;
    let _e328 = local_5;
    global_16 = _e328;
    let _e329 = global_17;
    let _e331 = local_6;
    let _e333 = local_7;
    global_18 = _e275;
    let _e338 = local_8;
    let _e340 = local_9;
    global_19 = ((_e338 * _e340) * select(1f, -1f, (dot(_e331, _e333) < 0f)));
    let _e343 = global_4;
    global_20 = _e343;
    let _e345 = global[0u];
    global_21 = vec4<f32>(_e345, 0f, 0f, 0f);
    let _e348 = global_11.member_2;
    let _e351 = global_11.member_3;
    global_22 = (_e348 * _e281);
    global_23 = (_e351 * vec4<f32>(_e329.x, _e329.y, _e329.z, 1f));
    global_24 = _e273;
    return;
}

@vertex 
fn main(@location(12) param: vec4<f32>, @location(0) param_1: vec3<f32>, @location(1) param_2: vec3<f32>, @location(11) param_3: vec4<f32>, @location(2) param_4: vec2<f32>, @location(13) param_5: vec4<f32>, @location(3) param_6: vec4<f32>, @location(4) param_7: vec4<f32>, @location(5) param_8: vec4<f32>, @location(6) param_9: vec4<f32>, @location(14) param_10: vec4<f32>) -> VertexOutput {
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
    global_17 = param_10;
    function_();
    let _e36 = global_12.member.y;
    global_12.member.y = -(_e36);
    let _e38 = global_12.member;
    let _e39 = global_13;
    let _e40 = global_14;
    let _e41 = global_15;
    let _e42 = global_16;
    let _e43 = global_18;
    let _e44 = global_19;
    let _e45 = global_20;
    let _e46 = global_21;
    let _e47 = global_22;
    let _e48 = global_23;
    let _e49 = global_24;
    return VertexOutput(_e38, _e39, _e40, _e41, _e42, _e43, _e44, _e45, _e46, _e47, _e48, _e49);
}
