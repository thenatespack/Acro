// Generated from mesh_fur_skinned.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: bfe5988631990025
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
var<private> global_5: vec2<f32>;
var<private> global_6: vec4<f32>;
var<private> global_7: vec4<f32>;
var<private> global_8: vec4<f32>;
var<private> global_9: vec4<f32>;
var<private> global_10: vec4<f32>;
var<private> global_11: vec4<f32>;
@group(0) @binding(0) 
var<uniform> global_12: type_20;
var<private> global_13: type_24 = type_24(vec4<f32>(0f, 0f, 0f, 1f), 1f, array<f32, 1>(), array<f32, 1>());
var<private> global_14: vec4<f32>;
var<private> global_15: vec2<f32>;
var<private> global_16: vec3<f32>;
var<private> global_17: vec3<f32>;
var<private> global_18: vec4<f32>;
var<private> global_19: vec4<f32>;
var<private> global_20: vec4<f32>;
var<private> global_21: vec4<f32>;
var<private> global_22: vec3<f32>;
var<private> global_23: vec3<f32>;
var<private> global_24: vec4<f32>;
var<private> global_25: vec4<f32>;
var<private> global_26: vec4<f32>;
var<private> global_27: vec4<f32>;
var<private> global_28: vec4<f32>;
var<private> global_29: vec3<f32>;

fn function_() {
    var phi_1699_: vec4<f32>;
    var phi_1698_: vec4<f32>;
    var phi_1697_: vec4<f32>;
    var phi_1696_: i32;
    var local: vec4<f32>;
    var local_1: vec4<f32>;
    var local_2: vec4<f32>;
    var phi_1701_: vec3<f32>;
    var phi_1700_: i32;
    var local_3: vec3<f32>;
    var phi_1702_: vec3<f32>;
    var phi_1704_: vec3<f32>;
    var phi_1703_: vec3<f32>;
    var local_4: bool;
    var phi_1706_: f32;
    var local_5: bool;
    var phi_1707_: f32;
    var local_6: bool;
    var local_7: bool;
    var phi_700_: bool;
    var local_8: vec3<f32>;
    var local_9: vec3<f32>;
    var phi_1711_: vec4<f32>;
    var phi_1710_: vec4<f32>;
    var phi_1709_: vec4<f32>;
    var phi_1708_: i32;
    var local_10: vec4<f32>;
    var local_11: vec4<f32>;
    var local_12: vec4<f32>;
    var local_13: vec4<f32>;
    var local_14: vec3<f32>;
    var local_15: vec2<f32>;
    var local_16: f32;
    var local_17: f32;
    var local_18: vec3<f32>;
    var phi_1713_: vec3<f32>;
    var phi_1712_: i32;
    var local_19: vec3<f32>;
    var local_20: vec3<f32>;
    var local_21: f32;
    var local_22: bool;
    var local_23: f32;
    var local_24: f32;
    var phi_1714_: vec3<f32>;
    var phi_1715_: vec3<f32>;
    var local_25: vec3<f32>;
    var local_26: vec3<f32>;
    var local_27: mat3x3<f32>;
    var local_28: vec3<f32>;

    let _e76 = global_8;
    let _e77 = global_9;
    let _e78 = global_10;
    let _e79 = global_11;
    phi_1699_ = vec4<f32>(0f, 0f, 0f, 0f);
    phi_1698_ = vec4<f32>(0f, 0f, 0f, 0f);
    phi_1697_ = vec4<f32>(0f, 0f, 0f, 0f);
    phi_1696_ = 0i;
    loop {
        let _e82 = phi_1699_;
        let _e84 = phi_1698_;
        let _e86 = phi_1697_;
        let _e88 = phi_1696_;
        local = _e86;
        local_1 = _e84;
        local_2 = _e82;
        if (_e88 < 4i) {
            continue;
        } else {
            break;
        }
        continuing {
            let _e91 = global[_e88];
            let _e93 = (i32(_e91) * 3i);
            let _e96 = global_1.member_3[_e93];
            let _e98 = global_2[_e88];
            let _e104 = global_1.member_3[(_e93 + 1i)];
            let _e110 = global_1.member_3[(_e93 + 2i)];
            phi_1699_ = (_e82 + (_e110 * _e98));
            phi_1698_ = (_e84 + (_e104 * _e98));
            phi_1697_ = (_e86 + (_e96 * _e98));
            phi_1696_ = (_e88 + 1i);
        }
    }
    let _e115 = local;
    let _e117 = local_1;
    let _e119 = local_2;
    let _e122 = (mat4x4<f32>(_e76, _e77, _e78, _e79) * transpose(mat4x4<f32>(_e115, _e117, _e119, vec4<f32>(0f, 0f, 0f, 1f))));
    let _e126 = global_1.member_1[6i][0u];
    switch bitcast<i32>(0u) {
        default: {
            let _e128 = global_3;
            let _e132 = vec4<f32>(_e128.x, _e128.y, _e128.z, 1f);
            let _e134 = (_e122 * _e132).xyz;
            let _e136 = _e122[0].xyz;
            let _e138 = _e122[1].xyz;
            let _e140 = _e122[2].xyz;
            let _e143 = cross(_e136, _e138);
            let _e144 = mat3x3<f32>(cross(_e138, _e140), cross(_e140, _e136), _e143);
            let _e148 = global_4;
            let _e151 = normalize(((_e144 * _e148) * select(1f, -1f, (dot(_e143, _e140) < 0f))));
            let _e155 = global_1.member_1[2i][0u];
            let _e159 = global_1.member_1[3i][3u];
            let _e160 = (_e159 > 0.5f);
            let _e165 = global_1.member_1[5i];
            let _e166 = _e165.xy;
            let _e167 = _e122[3].xz;
            let _e172 = ((dot(_e167, _e166) * 0.35f) + (dot(_e167, vec2<f32>(0.83f, -0.57f)) * 1.7f));
            let _e186 = global_1.member_1[5i][3u];
            let _e192 = (dot(_e122[3].xyz, vec3<f32>(3.1f, 2.3f, 2.7f)) * 3f);
            let _e205 = vec3<f32>(_e165.x, 0f, _e165.y);
            let _e209 = global_1.member_1[5i][2u];
            phi_1701_ = vec3<f32>(0f, 0f, 0f);
            phi_1700_ = 0i;
            local_4 = _e160;
            local_5 = _e160;
            local_6 = _e160;
            local_7 = _e160;
            local_8 = _e128;
            local_9 = _e148;
            local_13 = _e132;
            local_14 = _e148;
            local_15 = _e166;
            local_16 = _e186;
            local_17 = _e209;
            local_18 = _e205;
            local_21 = _e155;
            local_22 = _e160;
            local_25 = _e143;
            local_26 = _e140;
            local_27 = _e144;
            local_28 = _e148;
            loop {
                let _e215 = phi_1701_;
                let _e217 = phi_1700_;
                local_3 = _e215;
                if (_e217 < 4i) {
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e220 = global[_e217];
                    let _e224 = global_1.member_2[i32(_e220)];
                    let _e227 = global_2[_e217];
                    phi_1701_ = (_e215 + (_e224.xyz * _e227));
                    phi_1700_ = (_e217 + 1i);
                }
            }
            let _e234 = global_1.member_1[0i][0u];
            let _e236 = vec3(max(_e234, 0.001f));
            let _e238 = local_3;
            let _e241 = (((_e205 * (((_e209 * (1f + (_e186 * (((0.5f + ((0.5f * sin(((_e126 * 0.61f) + _e172))) * sin(((_e126 * 0.23f) + (_e172 * 0.7f))))) * 1.6f) - 0.6f)))) * (0.7f + ((0.3f * sin(((_e126 * 4.7f) + _e192))) * sin(((_e126 * 2.9f) + (_e192 * 0.37f)))))) * 0.35f)) + (_e238 / _e236)) * _e155);
            local_20 = _e236;
            local_23 = _e234;
            local_24 = _e234;
            if _e160 {
                let _e243 = global_5[1u];
                let _e257 = global_6;
                phi_1704_ = normalize(((mat3x3<f32>(vec3<f32>(_e122[0].x, _e122[0].y, _e122[0].z), vec3<f32>(_e122[1].x, _e122[1].y, _e122[1].z), vec3<f32>(_e122[2].x, _e122[2].y, _e122[2].z)) * _e257.xyz) + (_e241 * (2f * _e243))));
                phi_1703_ = (_e134 + (_e241 * ((_e234 * _e243) * _e243)));
                break;
            }
            let _e269 = global_7[1u];
            let _e271 = global_6[3u];
            let _e274 = (_e234 * max((_e271 - 1f), 0f));
            if (_e269 <= 0f) {
                phi_1704_ = _e151;
                phi_1703_ = (_e134 + (_e151 * ((_e274 * 0.04f) + 0.0004f)));
                break;
            }
            let _e293 = global_6;
            let _e295 = (mat3x3<f32>(vec3<f32>(_e122[0].x, _e122[0].y, _e122[0].z), vec3<f32>(_e122[1].x, _e122[1].y, _e122[1].z), vec3<f32>(_e122[2].x, _e122[2].y, _e122[2].z)) * _e293.xyz);
            let _e297 = min(length(_e295), 1f);
            let _e301 = global_1.member_1[1i][3u];
            let _e304 = (vec3<f32>(0f, -(_e301), 0f) + _e241);
            let _e318 = (_e274 * _e269);
            let _e319 = (normalize((((_e151 * (1f - _e297)) + _e295) + (_e304 * (0.5f * _e269)))) * _e318);
            let _e320 = dot(_e319, _e151);
            let _e321 = (_e318 * 0.12f);
            phi_1702_ = _e319;
            if (_e320 < _e321) {
                phi_1702_ = (_e319 + (_e151 * (_e321 - _e320)));
            }
            let _e327 = phi_1702_;
            phi_1704_ = normalize((((_e151 * (1f - _e297)) + _e295) + (_e304 * _e269)));
            phi_1703_ = (_e134 + _e327);
            break;
        }
    }
    let _e330 = phi_1704_;
    let _e332 = phi_1703_;
    let _e334 = global_12.member;
    let _e338 = vec4<f32>(_e332.x, _e332.y, _e332.z, 1f);
    global_13.member = (_e334 * _e338);
    let _e343 = global_13.member[1u];
    global_13.member[1u] = -(_e343);
    let _e346 = local_4;
    if _e346 {
        let _e348 = global_5[1u];
        phi_1706_ = _e348;
    } else {
        let _e350 = global_7[1u];
        phi_1706_ = _e350;
    }
    let _e352 = phi_1706_;
    let _e354 = local_5;
    if _e354 {
        let _e356 = global_6[3u];
        phi_1707_ = fract(_e356);
    } else {
        phi_1707_ = 0f;
    }
    let _e359 = phi_1707_;
    let _e361 = local_6;
    let _e364 = local_7;
    let _e365 = !(_e364);
    phi_700_ = _e365;
    if _e365 {
        let _e367 = global_7[1u];
        phi_700_ = (_e367 <= 0f);
    }
    let _e370 = phi_700_;
    global_14 = vec4<f32>(_e352, _e359, select(0f, 1f, _e361), select(0f, 1f, _e370));
    let _e373 = global_5;
    global_15 = _e373;
    let _e375 = local_8;
    global_16 = _e375;
    let _e377 = local_9;
    global_17 = _e377;
    let _e378 = global_18;
    let _e379 = global_19;
    let _e380 = global_20;
    let _e381 = global_21;
    phi_1711_ = vec4<f32>(0f, 0f, 0f, 0f);
    phi_1710_ = vec4<f32>(0f, 0f, 0f, 0f);
    phi_1709_ = vec4<f32>(0f, 0f, 0f, 0f);
    phi_1708_ = 0i;
    loop {
        let _e384 = phi_1711_;
        let _e386 = phi_1710_;
        let _e388 = phi_1709_;
        let _e390 = phi_1708_;
        local_10 = _e388;
        local_11 = _e386;
        local_12 = _e384;
        if (_e390 < 4i) {
            continue;
        } else {
            break;
        }
        continuing {
            let _e393 = global[_e390];
            let _e395 = (i32(_e393) * 3i);
            let _e398 = global_1.member_4[_e395];
            let _e400 = global_2[_e390];
            let _e406 = global_1.member_4[(_e395 + 1i)];
            let _e412 = global_1.member_4[(_e395 + 2i)];
            phi_1711_ = (_e384 + (_e412 * _e400));
            phi_1710_ = (_e386 + (_e406 * _e400));
            phi_1709_ = (_e388 + (_e398 * _e400));
            phi_1708_ = (_e390 + 1i);
        }
    }
    let _e417 = local_10;
    let _e419 = local_11;
    let _e421 = local_12;
    let _e424 = (mat4x4<f32>(_e378, _e379, _e380, _e381) * transpose(mat4x4<f32>(_e417, _e419, _e421, vec4<f32>(0f, 0f, 0f, 1f))));
    let _e428 = global_1.member_1[6i][1u];
    switch bitcast<i32>(0u) {
        default: {
            let _e431 = local_13;
            let _e433 = (_e424 * _e431).xyz;
            let _e435 = _e424[0].xyz;
            let _e437 = _e424[1].xyz;
            let _e439 = _e424[2].xyz;
            let _e442 = cross(_e435, _e437);
            let _e448 = local_14;
            let _e451 = normalize(((mat3x3<f32>(cross(_e437, _e439), cross(_e439, _e435), _e442) * _e448) * select(1f, -1f, (dot(_e442, _e439) < 0f))));
            let _e454 = _e424[3].xz;
            let _e456 = local_15;
            let _e461 = ((dot(_e454, _e456) * 0.35f) + (dot(_e454, vec2<f32>(0.83f, -0.57f)) * 1.7f));
            let _e475 = local_16;
            let _e479 = (dot(_e424[3].xyz, vec3<f32>(3.1f, 2.3f, 2.7f)) * 3f);
            let _e491 = local_17;
            let _e496 = local_18;
            phi_1713_ = vec3<f32>(0f, 0f, 0f);
            phi_1712_ = 0i;
            loop {
                let _e499 = phi_1713_;
                let _e501 = phi_1712_;
                local_19 = _e499;
                if (_e501 < 4i) {
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e504 = global[_e501];
                    let _e508 = global_1.member_2[i32(_e504)];
                    let _e511 = global_2[_e501];
                    phi_1713_ = (_e499 + (_e508.xyz * _e511));
                    phi_1712_ = (_e501 + 1i);
                }
            }
            let _e516 = local_19;
            let _e518 = local_20;
            let _e522 = local_21;
            let _e523 = (((_e496 * (((_e491 * (1f + (_e475 * (((0.5f + ((0.5f * sin(((_e428 * 0.61f) + _e461))) * sin(((_e428 * 0.23f) + (_e461 * 0.7f))))) * 1.6f) - 0.6f)))) * (0.7f + ((0.3f * sin(((_e428 * 4.7f) + _e479))) * sin(((_e428 * 2.9f) + (_e479 * 0.37f)))))) * 0.35f)) + (_e516 / _e518)) * _e522);
            let _e525 = local_22;
            if _e525 {
                let _e527 = global_5[1u];
                let _e529 = local_23;
                phi_1715_ = (_e433 + (_e523 * ((_e529 * _e527) * _e527)));
                break;
            }
            let _e535 = global_7[1u];
            let _e537 = global_6[3u];
            let _e541 = local_24;
            let _e542 = (_e541 * max((_e537 - 1f), 0f));
            if (_e535 <= 0f) {
                phi_1715_ = (_e433 + (_e451 * ((_e542 * 0.04f) + 0.0004f)));
                break;
            }
            let _e561 = global_6;
            let _e563 = (mat3x3<f32>(vec3<f32>(_e424[0].x, _e424[0].y, _e424[0].z), vec3<f32>(_e424[1].x, _e424[1].y, _e424[1].z), vec3<f32>(_e424[2].x, _e424[2].y, _e424[2].z)) * _e561.xyz);
            let _e569 = global_1.member_1[1i][3u];
            let _e580 = (_e542 * _e535);
            let _e581 = (normalize((((_e451 * (1f - min(length(_e563), 1f))) + _e563) + ((vec3<f32>(0f, -(_e569), 0f) + _e523) * (0.5f * _e535)))) * _e580);
            let _e582 = dot(_e581, _e451);
            let _e583 = (_e580 * 0.12f);
            phi_1714_ = _e581;
            if (_e582 < _e583) {
                phi_1714_ = (_e581 + (_e451 * (_e583 - _e582)));
            }
            let _e589 = phi_1714_;
            phi_1715_ = (_e433 + _e589);
            break;
        }
    }
    let _e592 = phi_1715_;
    let _e594 = local_25;
    let _e596 = local_26;
    global_22 = _e332;
    let _e601 = local_27;
    let _e603 = local_28;
    global_23 = ((_e601 * _e603) * select(1f, -1f, (dot(_e594, _e596) < 0f)));
    let _e606 = global_25;
    global_24 = _e606;
    let _e608 = global_7[0u];
    global_26 = vec4<f32>(_e608, 0f, 0f, 0f);
    let _e611 = global_12.member_2;
    let _e614 = global_12.member_3;
    global_27 = (_e611 * _e338);
    global_28 = (_e614 * vec4<f32>(_e592.x, _e592.y, _e592.z, 1f));
    global_29 = _e330;
    return;
}

@vertex 
fn main(@location(14) param: vec4<f32>, @location(15) param_1: vec4<f32>, @location(0) param_2: vec3<f32>, @location(1) param_3: vec3<f32>, @location(2) param_4: vec2<f32>, @location(13) param_5: vec4<f32>, @location(12) param_6: vec4<f32>, @location(3) param_7: vec4<f32>, @location(4) param_8: vec4<f32>, @location(5) param_9: vec4<f32>, @location(6) param_10: vec4<f32>, @location(7) param_11: vec4<f32>, @location(8) param_12: vec4<f32>, @location(9) param_13: vec4<f32>, @location(10) param_14: vec4<f32>, @location(11) param_15: vec4<f32>) -> VertexOutput {
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
    global_18 = param_11;
    global_19 = param_12;
    global_20 = param_13;
    global_21 = param_14;
    global_25 = param_15;
    function_();
    let _e46 = global_13.member.y;
    global_13.member.y = -(_e46);
    let _e48 = global_13.member;
    let _e49 = global_14;
    let _e50 = global_15;
    let _e51 = global_16;
    let _e52 = global_17;
    let _e53 = global_22;
    let _e54 = global_23;
    let _e55 = global_24;
    let _e56 = global_26;
    let _e57 = global_27;
    let _e58 = global_28;
    let _e59 = global_29;
    return VertexOutput(_e48, _e49, _e50, _e51, _e52, _e53, _e54, _e55, _e56, _e57, _e58, _e59);
}
