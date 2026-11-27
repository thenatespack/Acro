// Generated from mesh_fur.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: c899b7728ebfdc0d
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
var<private> global_18: vec4<f32>;
var<private> global_19: vec4<f32>;
var<private> global_20: vec4<f32>;
var<private> global_21: vec3<f32>;
var<private> global_22: vec3<f32>;
var<private> global_23: vec4<f32>;
var<private> global_24: vec4<f32>;
var<private> global_25: vec4<f32>;
var<private> global_26: vec4<f32>;
var<private> global_27: vec3<f32>;

fn function_() {
    var phi_1398_: f32;
    var phi_1399_: vec3<f32>;
    var phi_1401_: vec3<f32>;
    var phi_1400_: vec3<f32>;
    var local: bool;
    var phi_514_: bool;
    var local_1: bool;
    var phi_1403_: f32;
    var local_2: bool;
    var phi_1404_: f32;
    var local_3: bool;
    var phi_1405_: f32;
    var phi_552_: bool;
    var local_4: vec3<f32>;
    var local_5: vec3<f32>;
    var local_6: vec4<f32>;
    var local_7: vec3<f32>;
    var local_8: vec2<f32>;
    var local_9: f32;
    var local_10: f32;
    var local_11: vec3<f32>;
    var local_12: vec3<f32>;
    var local_13: f32;
    var local_14: bool;
    var local_15: f32;
    var phi_1406_: f32;
    var local_16: f32;
    var phi_1407_: vec3<f32>;
    var phi_1408_: vec3<f32>;
    var local_17: vec3<f32>;
    var local_18: vec3<f32>;
    var local_19: mat3x3<f32>;
    var local_20: vec3<f32>;

    let _e70 = global_7;
    let _e71 = global_8;
    let _e72 = global_9;
    let _e73 = global_10;
    let _e78 = global_1.member_1[6i][0u];
    switch bitcast<i32>(0u) {
        default: {
            let _e80 = global_2;
            let _e84 = vec4<f32>(_e80.x, _e80.y, _e80.z, 1f);
            let _e86 = (mat4x4<f32>(_e70, _e71, _e72, _e73) * _e84).xyz;
            let _e87 = _e70.xyz;
            let _e88 = _e71.xyz;
            let _e89 = _e72.xyz;
            let _e92 = cross(_e87, _e88);
            let _e93 = mat3x3<f32>(cross(_e88, _e89), cross(_e89, _e87), _e92);
            let _e97 = global_3;
            let _e100 = normalize(((_e93 * _e97) * select(1f, -1f, (dot(_e92, _e89) < 0f))));
            let _e104 = global_1.member_1[2i][0u];
            let _e108 = global_1.member_1[3i][3u];
            let _e109 = (_e108 > 0.5f);
            let _e111 = global_4[3u];
            let _e117 = global_1.member_1[5i];
            let _e118 = _e117.xy;
            let _e119 = _e73.xz;
            let _e124 = ((dot(_e119, _e118) * 0.35f) + (dot(_e119, vec2<f32>(0.83f, -0.57f)) * 1.7f));
            let _e138 = global_1.member_1[5i][3u];
            let _e144 = (dot(_e73.xyz, vec3<f32>(3.1f, 2.3f, 2.7f)) * 3f);
            let _e157 = vec3<f32>(_e117.x, 0f, _e117.y);
            let _e161 = global_1.member_1[5i][2u];
            let _e167 = global[2u];
            let _e169 = global[3u];
            let _e174 = global_1.member_1[0i][0u];
            let _e177 = (vec3<f32>(_e167, 0f, _e169) / vec3(max(_e174, 0.001f)));
            let _e179 = (_e104 * select(1f, 0f, (_e111 < -0.5f)));
            let _e180 = (((_e157 * (((_e161 * (1f + (_e138 * (((0.5f + ((0.5f * sin(((_e78 * 0.61f) + _e124))) * sin(((_e78 * 0.23f) + (_e124 * 0.7f))))) * 1.6f) - 0.6f)))) * (0.7f + ((0.3f * sin(((_e78 * 4.7f) + _e144))) * sin(((_e78 * 2.9f) + (_e144 * 0.37f)))))) * 0.35f)) + _e177) * _e179);
            local = _e109;
            local_1 = _e109;
            local_2 = _e109;
            local_3 = _e109;
            local_4 = _e80;
            local_5 = _e97;
            local_6 = _e84;
            local_7 = _e97;
            local_8 = _e118;
            local_9 = _e138;
            local_10 = _e161;
            local_11 = _e157;
            local_12 = _e177;
            local_13 = _e179;
            local_14 = _e109;
            local_15 = _e174;
            local_16 = _e174;
            local_17 = _e92;
            local_18 = _e89;
            local_19 = _e93;
            local_20 = _e97;
            if _e109 {
                let _e182 = global_5[1u];
                let _e196 = global_6;
                phi_1401_ = normalize(((mat3x3<f32>(vec3<f32>(_e70.x, _e70.y, _e70.z), vec3<f32>(_e71.x, _e71.y, _e71.z), vec3<f32>(_e72.x, _e72.y, _e72.z)) * _e196.xyz) + (_e180 * (2f * _e182))));
                phi_1400_ = (_e86 + (_e180 * ((_e174 * _e182) * _e182)));
                break;
            }
            let _e208 = global[1u];
            let _e209 = (_e208 > 1.5f);
            if _e209 {
                let _e211 = global_5[1u];
                phi_1398_ = _e211;
            } else {
                phi_1398_ = _e208;
            }
            let _e213 = phi_1398_;
            let _e215 = global_6[3u];
            let _e218 = (_e174 * max((_e215 - 1f), 0f));
            if ((_e213 <= 0f) && !(_e209)) {
                phi_1401_ = _e100;
                phi_1400_ = (_e86 + (_e100 * ((_e218 * 0.04f) + 0.0004f)));
                break;
            }
            let _e239 = global_6;
            let _e241 = (mat3x3<f32>(vec3<f32>(_e70.x, _e70.y, _e70.z), vec3<f32>(_e71.x, _e71.y, _e71.z), vec3<f32>(_e72.x, _e72.y, _e72.z)) * _e239.xyz);
            let _e243 = min(length(_e241), 1f);
            let _e247 = global_1.member_1[1i][3u];
            let _e250 = (vec3<f32>(0f, -(_e247), 0f) + _e180);
            let _e264 = (_e218 * _e213);
            let _e265 = (normalize((((_e100 * (1f - _e243)) + _e241) + (_e250 * (0.5f * _e213)))) * _e264);
            let _e266 = dot(_e265, _e100);
            let _e267 = (_e264 * 0.12f);
            phi_1399_ = _e265;
            if (_e266 < _e267) {
                phi_1399_ = (_e265 + (_e100 * (_e267 - _e266)));
            }
            let _e273 = phi_1399_;
            phi_1401_ = normalize((((_e100 * (1f - _e243)) + _e241) + (_e250 * _e213)));
            phi_1400_ = (_e86 + _e273);
            break;
        }
    }
    let _e276 = phi_1401_;
    let _e278 = phi_1400_;
    let _e280 = global_11.member;
    let _e284 = vec4<f32>(_e278.x, _e278.y, _e278.z, 1f);
    global_12.member = (_e280 * _e284);
    let _e289 = global_12.member[1u];
    global_12.member[1u] = -(_e289);
    let _e292 = local;
    let _e293 = !(_e292);
    phi_514_ = _e293;
    if _e293 {
        let _e295 = global[1u];
        phi_514_ = (_e295 > 1.5f);
    }
    let _e298 = phi_514_;
    let _e300 = local_1;
    if (_e300 || _e298) {
        let _e303 = global_5[1u];
        phi_1403_ = _e303;
    } else {
        let _e305 = global[1u];
        phi_1403_ = _e305;
    }
    let _e307 = phi_1403_;
    let _e309 = local_2;
    if _e309 {
        let _e311 = global_6[3u];
        phi_1404_ = fract(_e311);
    } else {
        phi_1404_ = 0f;
    }
    let _e314 = phi_1404_;
    let _e316 = local_3;
    if _e316 {
        phi_1405_ = 1f;
    } else {
        phi_1405_ = select(0f, 2f, _e298);
    }
    let _e319 = phi_1405_;
    phi_552_ = _e293;
    if _e293 {
        let _e321 = global[1u];
        phi_552_ = (_e321 <= 0f);
    }
    let _e324 = phi_552_;
    global_13 = vec4<f32>(_e307, _e314, _e319, select(0f, 1f, _e324));
    let _e327 = global_5;
    global_14 = _e327;
    let _e329 = local_4;
    global_15 = _e329;
    let _e331 = local_5;
    global_16 = _e331;
    let _e332 = global_17;
    let _e333 = global_18;
    let _e334 = global_19;
    let _e335 = global_20;
    let _e340 = global_1.member_1[6i][1u];
    switch bitcast<i32>(0u) {
        default: {
            let _e343 = local_6;
            let _e345 = (mat4x4<f32>(_e332, _e333, _e334, _e335) * _e343).xyz;
            let _e346 = _e332.xyz;
            let _e347 = _e333.xyz;
            let _e348 = _e334.xyz;
            let _e351 = cross(_e346, _e347);
            let _e357 = local_7;
            let _e360 = normalize(((mat3x3<f32>(cross(_e347, _e348), cross(_e348, _e346), _e351) * _e357) * select(1f, -1f, (dot(_e351, _e348) < 0f))));
            let _e362 = _e335.xz;
            let _e364 = local_8;
            let _e369 = ((dot(_e362, _e364) * 0.35f) + (dot(_e362, vec2<f32>(0.83f, -0.57f)) * 1.7f));
            let _e383 = local_9;
            let _e387 = (dot(_e335.xyz, vec3<f32>(3.1f, 2.3f, 2.7f)) * 3f);
            let _e399 = local_10;
            let _e404 = local_11;
            let _e407 = local_12;
            let _e410 = local_13;
            let _e411 = (((_e404 * (((_e399 * (1f + (_e383 * (((0.5f + ((0.5f * sin(((_e340 * 0.61f) + _e369))) * sin(((_e340 * 0.23f) + (_e369 * 0.7f))))) * 1.6f) - 0.6f)))) * (0.7f + ((0.3f * sin(((_e340 * 4.7f) + _e387))) * sin(((_e340 * 2.9f) + (_e387 * 0.37f)))))) * 0.35f)) + _e407) * _e410);
            let _e413 = local_14;
            if _e413 {
                let _e415 = global_5[1u];
                let _e417 = local_15;
                phi_1408_ = (_e345 + (_e411 * ((_e417 * _e415) * _e415)));
                break;
            }
            let _e423 = global[1u];
            let _e424 = (_e423 > 1.5f);
            if _e424 {
                let _e426 = global_5[1u];
                phi_1406_ = _e426;
            } else {
                phi_1406_ = _e423;
            }
            let _e428 = phi_1406_;
            let _e430 = global_6[3u];
            let _e434 = local_16;
            let _e435 = (_e434 * max((_e430 - 1f), 0f));
            if ((_e428 <= 0f) && !(_e424)) {
                phi_1408_ = (_e345 + (_e360 * ((_e435 * 0.04f) + 0.0004f)));
                break;
            }
            let _e456 = global_6;
            let _e458 = (mat3x3<f32>(vec3<f32>(_e332.x, _e332.y, _e332.z), vec3<f32>(_e333.x, _e333.y, _e333.z), vec3<f32>(_e334.x, _e334.y, _e334.z)) * _e456.xyz);
            let _e464 = global_1.member_1[1i][3u];
            let _e475 = (_e435 * _e428);
            let _e476 = (normalize((((_e360 * (1f - min(length(_e458), 1f))) + _e458) + ((vec3<f32>(0f, -(_e464), 0f) + _e411) * (0.5f * _e428)))) * _e475);
            let _e477 = dot(_e476, _e360);
            let _e478 = (_e475 * 0.12f);
            phi_1407_ = _e476;
            if (_e477 < _e478) {
                phi_1407_ = (_e476 + (_e360 * (_e478 - _e477)));
            }
            let _e484 = phi_1407_;
            phi_1408_ = (_e345 + _e484);
            break;
        }
    }
    let _e487 = phi_1408_;
    let _e489 = local_17;
    let _e491 = local_18;
    global_21 = _e278;
    let _e496 = local_19;
    let _e498 = local_20;
    global_22 = ((_e496 * _e498) * select(1f, -1f, (dot(_e489, _e491) < 0f)));
    let _e501 = global_4;
    global_23 = _e501;
    let _e503 = global[0u];
    global_24 = vec4<f32>(_e503, 0f, 0f, 0f);
    let _e506 = global_11.member_2;
    let _e509 = global_11.member_3;
    global_25 = (_e506 * _e284);
    global_26 = (_e509 * vec4<f32>(_e487.x, _e487.y, _e487.z, 1f));
    global_27 = _e276;
    return;
}

@vertex 
fn main(@location(12) param: vec4<f32>, @location(0) param_1: vec3<f32>, @location(1) param_2: vec3<f32>, @location(11) param_3: vec4<f32>, @location(2) param_4: vec2<f32>, @location(13) param_5: vec4<f32>, @location(3) param_6: vec4<f32>, @location(4) param_7: vec4<f32>, @location(5) param_8: vec4<f32>, @location(6) param_9: vec4<f32>, @location(7) param_10: vec4<f32>, @location(8) param_11: vec4<f32>, @location(9) param_12: vec4<f32>, @location(10) param_13: vec4<f32>) -> VertexOutput {
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
    global_18 = param_11;
    global_19 = param_12;
    global_20 = param_13;
    function_();
    let _e42 = global_12.member.y;
    global_12.member.y = -(_e42);
    let _e44 = global_12.member;
    let _e45 = global_13;
    let _e46 = global_14;
    let _e47 = global_15;
    let _e48 = global_16;
    let _e49 = global_21;
    let _e50 = global_22;
    let _e51 = global_23;
    let _e52 = global_24;
    let _e53 = global_25;
    let _e54 = global_26;
    let _e55 = global_27;
    return VertexOutput(_e44, _e45, _e46, _e47, _e48, _e49, _e50, _e51, _e52, _e53, _e54, _e55);
}
