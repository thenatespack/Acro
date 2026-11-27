// Generated from mesh_fur_skinned.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: 120ab4424b2a5b08
// glsl-fnv1a64: b04aa777f9f00a8c

diagnostic(off, derivative_uniformity);

struct type_12 {
    member: array<vec4<f32>, 8>,
    member_1: array<vec4<f32>, 8>,
    member_2: array<vec4<f32>, 128>,
    member_3: array<vec4<f32>, 384>,
    member_4: array<vec4<f32>, 384>,
}

struct type_20 {
    member: mat4x4<f32>,
    member_1: mat4x4<f32>,
    member_2: mat4x4<f32>,
    member_3: mat4x4<f32>,
}

struct type_24 {
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
var<uniform> global_1: type_12;
var<private> global_2: vec4<f32>;
var<private> global_3: vec3<f32>;
var<private> global_4: vec3<f32>;
var<private> global_5: vec4<f32>;
var<private> global_6: vec2<f32>;
var<private> global_7: vec4<f32>;
var<private> global_8: vec4<f32>;
var<private> global_9: vec4<f32>;
var<private> global_10: vec4<f32>;
var<private> global_11: vec4<f32>;
var<private> global_12: vec4<f32>;
@group(0) @binding(0) 
var<uniform> global_13: type_20;
var<private> global_14: type_24 = type_24(vec4<f32>(0f, 0f, 0f, 1f), 1f, array<f32, 1>(), array<f32, 1>());
var<private> global_15: vec4<f32>;
var<private> global_16: vec2<f32>;
var<private> global_17: vec3<f32>;
var<private> global_18: vec3<f32>;
var<private> global_19: vec4<f32>;
var<private> global_20: vec4<f32>;
var<private> global_21: vec4<f32>;
var<private> global_22: vec4<f32>;
var<private> global_23: vec3<f32>;
var<private> global_24: vec3<f32>;
var<private> global_25: vec4<f32>;
var<private> global_26: vec4<f32>;
var<private> global_27: vec4<f32>;
var<private> global_28: vec4<f32>;
var<private> global_29: vec3<f32>;

fn function_() {
    var phi_1784_: vec4<f32>;
    var phi_1783_: vec4<f32>;
    var phi_1782_: vec4<f32>;
    var phi_1781_: i32;
    var local: vec4<f32>;
    var local_1: vec4<f32>;
    var local_2: vec4<f32>;
    var phi_1786_: vec3<f32>;
    var phi_1785_: i32;
    var local_3: vec3<f32>;
    var phi_1787_: f32;
    var phi_1788_: vec3<f32>;
    var phi_1790_: vec3<f32>;
    var phi_1789_: vec3<f32>;
    var local_4: bool;
    var phi_704_: bool;
    var local_5: bool;
    var phi_1792_: f32;
    var local_6: bool;
    var phi_1793_: f32;
    var local_7: bool;
    var phi_1794_: f32;
    var phi_742_: bool;
    var local_8: vec3<f32>;
    var local_9: vec3<f32>;
    var phi_1798_: vec4<f32>;
    var phi_1797_: vec4<f32>;
    var phi_1796_: vec4<f32>;
    var phi_1795_: i32;
    var local_10: vec4<f32>;
    var local_11: vec4<f32>;
    var local_12: vec4<f32>;
    var local_13: vec4<f32>;
    var local_14: vec3<f32>;
    var local_15: vec2<f32>;
    var local_16: f32;
    var local_17: f32;
    var local_18: vec3<f32>;
    var phi_1800_: vec3<f32>;
    var phi_1799_: i32;
    var local_19: vec3<f32>;
    var local_20: vec3<f32>;
    var local_21: f32;
    var local_22: bool;
    var local_23: f32;
    var phi_1801_: f32;
    var local_24: f32;
    var phi_1802_: vec3<f32>;
    var phi_1803_: vec3<f32>;
    var local_25: vec3<f32>;
    var local_26: vec3<f32>;
    var local_27: mat3x3<f32>;
    var local_28: vec3<f32>;

    let _e78 = global_9;
    let _e79 = global_10;
    let _e80 = global_11;
    let _e81 = global_12;
    phi_1784_ = vec4<f32>(0f, 0f, 0f, 0f);
    phi_1783_ = vec4<f32>(0f, 0f, 0f, 0f);
    phi_1782_ = vec4<f32>(0f, 0f, 0f, 0f);
    phi_1781_ = 0i;
    loop {
        let _e84 = phi_1784_;
        let _e86 = phi_1783_;
        let _e88 = phi_1782_;
        let _e90 = phi_1781_;
        local = _e88;
        local_1 = _e86;
        local_2 = _e84;
        if (_e90 < 4i) {
            continue;
        } else {
            break;
        }
        continuing {
            let _e93 = global[_e90];
            let _e95 = (i32(_e93) * 3i);
            let _e98 = global_1.member_3[_e95];
            let _e100 = global_2[_e90];
            let _e106 = global_1.member_3[(_e95 + 1i)];
            let _e112 = global_1.member_3[(_e95 + 2i)];
            phi_1784_ = (_e84 + (_e112 * _e100));
            phi_1783_ = (_e86 + (_e106 * _e100));
            phi_1782_ = (_e88 + (_e98 * _e100));
            phi_1781_ = (_e90 + 1i);
        }
    }
    let _e117 = local;
    let _e119 = local_1;
    let _e121 = local_2;
    let _e124 = (mat4x4<f32>(_e78, _e79, _e80, _e81) * transpose(mat4x4<f32>(_e117, _e119, _e121, vec4<f32>(0f, 0f, 0f, 1f))));
    let _e128 = global_1.member_1[6i][0u];
    switch bitcast<i32>(0u) {
        default: {
            let _e130 = global_3;
            let _e134 = vec4<f32>(_e130.x, _e130.y, _e130.z, 1f);
            let _e136 = (_e124 * _e134).xyz;
            let _e138 = _e124[0].xyz;
            let _e140 = _e124[1].xyz;
            let _e142 = _e124[2].xyz;
            let _e145 = cross(_e138, _e140);
            let _e146 = mat3x3<f32>(cross(_e140, _e142), cross(_e142, _e138), _e145);
            let _e150 = global_4;
            let _e153 = normalize(((_e146 * _e150) * select(1f, -1f, (dot(_e145, _e142) < 0f))));
            let _e157 = global_1.member_1[2i][0u];
            let _e161 = global_1.member_1[3i][3u];
            let _e162 = (_e161 > 0.5f);
            let _e164 = global_5[3u];
            let _e171 = global_1.member_1[5i];
            let _e172 = _e171.xy;
            let _e173 = _e124[3].xz;
            let _e178 = ((dot(_e173, _e172) * 0.35f) + (dot(_e173, vec2<f32>(0.83f, -0.57f)) * 1.7f));
            let _e192 = global_1.member_1[5i][3u];
            let _e198 = (dot(_e124[3].xyz, vec3<f32>(3.1f, 2.3f, 2.7f)) * 3f);
            let _e211 = vec3<f32>(_e171.x, 0f, _e171.y);
            let _e215 = global_1.member_1[5i][2u];
            phi_1786_ = vec3<f32>(0f, 0f, 0f);
            phi_1785_ = 0i;
            local_4 = _e162;
            local_5 = _e162;
            local_6 = _e162;
            local_7 = _e162;
            local_8 = _e130;
            local_9 = _e150;
            local_13 = _e134;
            local_14 = _e150;
            local_15 = _e172;
            local_16 = _e192;
            local_17 = _e215;
            local_18 = _e211;
            local_22 = _e162;
            local_25 = _e145;
            local_26 = _e142;
            local_27 = _e146;
            local_28 = _e150;
            loop {
                let _e221 = phi_1786_;
                let _e223 = phi_1785_;
                local_3 = _e221;
                if (_e223 < 4i) {
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e226 = global[_e223];
                    let _e230 = global_1.member_2[i32(_e226)];
                    let _e233 = global_2[_e223];
                    phi_1786_ = (_e221 + (_e230.xyz * _e233));
                    phi_1785_ = (_e223 + 1i);
                }
            }
            let _e240 = global_1.member_1[0i][0u];
            let _e242 = vec3(max(_e240, 0.001f));
            let _e244 = local_3;
            let _e247 = (_e157 * select(1f, 0f, (_e164 < -0.5f)));
            let _e248 = (((_e211 * (((_e215 * (1f + (_e192 * (((0.5f + ((0.5f * sin(((_e128 * 0.61f) + _e178))) * sin(((_e128 * 0.23f) + (_e178 * 0.7f))))) * 1.6f) - 0.6f)))) * (0.7f + ((0.3f * sin(((_e128 * 4.7f) + _e198))) * sin(((_e128 * 2.9f) + (_e198 * 0.37f)))))) * 0.35f)) + (_e244 / _e242)) * _e247);
            local_20 = _e242;
            local_21 = _e247;
            local_23 = _e240;
            local_24 = _e240;
            if _e162 {
                let _e250 = global_6[1u];
                let _e264 = global_7;
                phi_1790_ = normalize(((mat3x3<f32>(vec3<f32>(_e124[0].x, _e124[0].y, _e124[0].z), vec3<f32>(_e124[1].x, _e124[1].y, _e124[1].z), vec3<f32>(_e124[2].x, _e124[2].y, _e124[2].z)) * _e264.xyz) + (_e248 * (2f * _e250))));
                phi_1789_ = (_e136 + (_e248 * ((_e240 * _e250) * _e250)));
                break;
            }
            let _e276 = global_8[1u];
            let _e277 = (_e276 > 1.5f);
            if _e277 {
                let _e279 = global_6[1u];
                phi_1787_ = _e279;
            } else {
                phi_1787_ = _e276;
            }
            let _e281 = phi_1787_;
            let _e283 = global_7[3u];
            let _e286 = (_e240 * max((_e283 - 1f), 0f));
            if ((_e281 <= 0f) && !(_e277)) {
                phi_1790_ = _e153;
                phi_1789_ = (_e136 + (_e153 * ((_e286 * 0.04f) + 0.0004f)));
                break;
            }
            let _e307 = global_7;
            let _e309 = (mat3x3<f32>(vec3<f32>(_e124[0].x, _e124[0].y, _e124[0].z), vec3<f32>(_e124[1].x, _e124[1].y, _e124[1].z), vec3<f32>(_e124[2].x, _e124[2].y, _e124[2].z)) * _e307.xyz);
            let _e311 = min(length(_e309), 1f);
            let _e315 = global_1.member_1[1i][3u];
            let _e318 = (vec3<f32>(0f, -(_e315), 0f) + _e248);
            let _e332 = (_e286 * _e281);
            let _e333 = (normalize((((_e153 * (1f - _e311)) + _e309) + (_e318 * (0.5f * _e281)))) * _e332);
            let _e334 = dot(_e333, _e153);
            let _e335 = (_e332 * 0.12f);
            phi_1788_ = _e333;
            if (_e334 < _e335) {
                phi_1788_ = (_e333 + (_e153 * (_e335 - _e334)));
            }
            let _e341 = phi_1788_;
            phi_1790_ = normalize((((_e153 * (1f - _e311)) + _e309) + (_e318 * _e281)));
            phi_1789_ = (_e136 + _e341);
            break;
        }
    }
    let _e344 = phi_1790_;
    let _e346 = phi_1789_;
    let _e348 = global_13.member;
    let _e352 = vec4<f32>(_e346.x, _e346.y, _e346.z, 1f);
    global_14.member = (_e348 * _e352);
    let _e357 = global_14.member[1u];
    global_14.member[1u] = -(_e357);
    let _e360 = local_4;
    let _e361 = !(_e360);
    phi_704_ = _e361;
    if _e361 {
        let _e363 = global_8[1u];
        phi_704_ = (_e363 > 1.5f);
    }
    let _e366 = phi_704_;
    let _e368 = local_5;
    if (_e368 || _e366) {
        let _e371 = global_6[1u];
        phi_1792_ = _e371;
    } else {
        let _e373 = global_8[1u];
        phi_1792_ = _e373;
    }
    let _e375 = phi_1792_;
    let _e377 = local_6;
    if _e377 {
        let _e379 = global_7[3u];
        phi_1793_ = fract(_e379);
    } else {
        phi_1793_ = 0f;
    }
    let _e382 = phi_1793_;
    let _e384 = local_7;
    if _e384 {
        phi_1794_ = 1f;
    } else {
        phi_1794_ = select(0f, 2f, _e366);
    }
    let _e387 = phi_1794_;
    phi_742_ = _e361;
    if _e361 {
        let _e389 = global_8[1u];
        phi_742_ = (_e389 <= 0f);
    }
    let _e392 = phi_742_;
    global_15 = vec4<f32>(_e375, _e382, _e387, select(0f, 1f, _e392));
    let _e395 = global_6;
    global_16 = _e395;
    let _e397 = local_8;
    global_17 = _e397;
    let _e399 = local_9;
    global_18 = _e399;
    let _e400 = global_19;
    let _e401 = global_20;
    let _e402 = global_21;
    let _e403 = global_22;
    phi_1798_ = vec4<f32>(0f, 0f, 0f, 0f);
    phi_1797_ = vec4<f32>(0f, 0f, 0f, 0f);
    phi_1796_ = vec4<f32>(0f, 0f, 0f, 0f);
    phi_1795_ = 0i;
    loop {
        let _e406 = phi_1798_;
        let _e408 = phi_1797_;
        let _e410 = phi_1796_;
        let _e412 = phi_1795_;
        local_10 = _e410;
        local_11 = _e408;
        local_12 = _e406;
        if (_e412 < 4i) {
            continue;
        } else {
            break;
        }
        continuing {
            let _e415 = global[_e412];
            let _e417 = (i32(_e415) * 3i);
            let _e420 = global_1.member_4[_e417];
            let _e422 = global_2[_e412];
            let _e428 = global_1.member_4[(_e417 + 1i)];
            let _e434 = global_1.member_4[(_e417 + 2i)];
            phi_1798_ = (_e406 + (_e434 * _e422));
            phi_1797_ = (_e408 + (_e428 * _e422));
            phi_1796_ = (_e410 + (_e420 * _e422));
            phi_1795_ = (_e412 + 1i);
        }
    }
    let _e439 = local_10;
    let _e441 = local_11;
    let _e443 = local_12;
    let _e446 = (mat4x4<f32>(_e400, _e401, _e402, _e403) * transpose(mat4x4<f32>(_e439, _e441, _e443, vec4<f32>(0f, 0f, 0f, 1f))));
    let _e450 = global_1.member_1[6i][1u];
    switch bitcast<i32>(0u) {
        default: {
            let _e453 = local_13;
            let _e455 = (_e446 * _e453).xyz;
            let _e457 = _e446[0].xyz;
            let _e459 = _e446[1].xyz;
            let _e461 = _e446[2].xyz;
            let _e464 = cross(_e457, _e459);
            let _e470 = local_14;
            let _e473 = normalize(((mat3x3<f32>(cross(_e459, _e461), cross(_e461, _e457), _e464) * _e470) * select(1f, -1f, (dot(_e464, _e461) < 0f))));
            let _e476 = _e446[3].xz;
            let _e478 = local_15;
            let _e483 = ((dot(_e476, _e478) * 0.35f) + (dot(_e476, vec2<f32>(0.83f, -0.57f)) * 1.7f));
            let _e497 = local_16;
            let _e501 = (dot(_e446[3].xyz, vec3<f32>(3.1f, 2.3f, 2.7f)) * 3f);
            let _e513 = local_17;
            let _e518 = local_18;
            phi_1800_ = vec3<f32>(0f, 0f, 0f);
            phi_1799_ = 0i;
            loop {
                let _e521 = phi_1800_;
                let _e523 = phi_1799_;
                local_19 = _e521;
                if (_e523 < 4i) {
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e526 = global[_e523];
                    let _e530 = global_1.member_2[i32(_e526)];
                    let _e533 = global_2[_e523];
                    phi_1800_ = (_e521 + (_e530.xyz * _e533));
                    phi_1799_ = (_e523 + 1i);
                }
            }
            let _e538 = local_19;
            let _e540 = local_20;
            let _e544 = local_21;
            let _e545 = (((_e518 * (((_e513 * (1f + (_e497 * (((0.5f + ((0.5f * sin(((_e450 * 0.61f) + _e483))) * sin(((_e450 * 0.23f) + (_e483 * 0.7f))))) * 1.6f) - 0.6f)))) * (0.7f + ((0.3f * sin(((_e450 * 4.7f) + _e501))) * sin(((_e450 * 2.9f) + (_e501 * 0.37f)))))) * 0.35f)) + (_e538 / _e540)) * _e544);
            let _e547 = local_22;
            if _e547 {
                let _e549 = global_6[1u];
                let _e551 = local_23;
                phi_1803_ = (_e455 + (_e545 * ((_e551 * _e549) * _e549)));
                break;
            }
            let _e557 = global_8[1u];
            let _e558 = (_e557 > 1.5f);
            if _e558 {
                let _e560 = global_6[1u];
                phi_1801_ = _e560;
            } else {
                phi_1801_ = _e557;
            }
            let _e562 = phi_1801_;
            let _e564 = global_7[3u];
            let _e568 = local_24;
            let _e569 = (_e568 * max((_e564 - 1f), 0f));
            if ((_e562 <= 0f) && !(_e558)) {
                phi_1803_ = (_e455 + (_e473 * ((_e569 * 0.04f) + 0.0004f)));
                break;
            }
            let _e590 = global_7;
            let _e592 = (mat3x3<f32>(vec3<f32>(_e446[0].x, _e446[0].y, _e446[0].z), vec3<f32>(_e446[1].x, _e446[1].y, _e446[1].z), vec3<f32>(_e446[2].x, _e446[2].y, _e446[2].z)) * _e590.xyz);
            let _e598 = global_1.member_1[1i][3u];
            let _e609 = (_e569 * _e562);
            let _e610 = (normalize((((_e473 * (1f - min(length(_e592), 1f))) + _e592) + ((vec3<f32>(0f, -(_e598), 0f) + _e545) * (0.5f * _e562)))) * _e609);
            let _e611 = dot(_e610, _e473);
            let _e612 = (_e609 * 0.12f);
            phi_1802_ = _e610;
            if (_e611 < _e612) {
                phi_1802_ = (_e610 + (_e473 * (_e612 - _e611)));
            }
            let _e618 = phi_1802_;
            phi_1803_ = (_e455 + _e618);
            break;
        }
    }
    let _e621 = phi_1803_;
    let _e623 = local_25;
    let _e625 = local_26;
    global_23 = _e346;
    let _e630 = local_27;
    let _e632 = local_28;
    global_24 = ((_e630 * _e632) * select(1f, -1f, (dot(_e623, _e625) < 0f)));
    let _e635 = global_5;
    global_25 = _e635;
    let _e637 = global_8[0u];
    global_26 = vec4<f32>(_e637, 0f, 0f, 0f);
    let _e640 = global_13.member_2;
    let _e643 = global_13.member_3;
    global_27 = (_e640 * _e352);
    global_28 = (_e643 * vec4<f32>(_e621.x, _e621.y, _e621.z, 1f));
    global_29 = _e344;
    return;
}

@vertex 
fn main(@location(14) param: vec4<f32>, @location(15) param_1: vec4<f32>, @location(0) param_2: vec3<f32>, @location(1) param_3: vec3<f32>, @location(11) param_4: vec4<f32>, @location(2) param_5: vec2<f32>, @location(13) param_6: vec4<f32>, @location(12) param_7: vec4<f32>, @location(3) param_8: vec4<f32>, @location(4) param_9: vec4<f32>, @location(5) param_10: vec4<f32>, @location(6) param_11: vec4<f32>, @location(7) param_12: vec4<f32>, @location(8) param_13: vec4<f32>, @location(9) param_14: vec4<f32>, @location(10) param_15: vec4<f32>) -> VertexOutput {
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
    global_19 = param_12;
    global_20 = param_13;
    global_21 = param_14;
    global_22 = param_15;
    function_();
    let _e46 = global_14.member.y;
    global_14.member.y = -(_e46);
    let _e48 = global_14.member;
    let _e49 = global_15;
    let _e50 = global_16;
    let _e51 = global_17;
    let _e52 = global_18;
    let _e53 = global_23;
    let _e54 = global_24;
    let _e55 = global_25;
    let _e56 = global_26;
    let _e57 = global_27;
    let _e58 = global_28;
    let _e59 = global_29;
    return VertexOutput(_e48, _e49, _e50, _e51, _e52, _e53, _e54, _e55, _e56, _e57, _e58, _e59);
}
