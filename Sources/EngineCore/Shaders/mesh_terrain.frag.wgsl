// Generated from mesh_terrain.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: 3bcdea22e7cd956f
// glsl-fnv1a64: a99dffffb0ba0ac6

diagnostic(off, derivative_uniformity);

struct type_17 {
    member: array<vec4<f32>>,
}

struct type_27 {
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
    member_11: vec4<f32>,
    member_12: vec4<f32>,
    member_13: vec4<f32>,
    member_14: array<mat4x4<f32>, 4>,
    member_15: array<mat4x4<f32>, 8>,
    member_16: vec4<f32>,
    member_17: vec4<f32>,
    member_18: vec4<f32>,
    member_19: vec4<f32>,
    member_20: vec4<f32>,
    member_21: vec4<f32>,
    member_22: vec4<f32>,
    member_23: vec4<f32>,
    member_24: vec4<f32>,
    member_25: vec4<f32>,
    member_26: array<vec4<f32>, 8>,
    member_27: array<vec4<f32>, 4>,
    member_28: array<vec4<f32>, 4>,
    member_29: vec4<f32>,
    member_30: mat4x4<f32>,
    member_31: vec4<f32>,
    member_32: vec4<f32>,
    member_33: vec4<f32>,
    member_34: vec4<f32>,
}

struct type_43 {
    member: array<vec4<f32>, 1024>,
}

struct type_49 {
    member: array<vec4<u32>, 1024>,
}

struct type_53 {
    member: vec4<f32>,
}

struct type_56 {
    member: vec4<f32>,
    member_1: vec4<f32>,
    member_2: vec4<f32>,
    member_3: vec4<f32>,
    member_4: vec4<f32>,
    member_5: vec4<f32>,
    member_6: vec4<f32>,
}

struct FragmentOutput {
    @location(0) member: vec4<f32>,
    @location(1) member_1: vec2<f32>,
}

@group(2) @binding(24) 
var<storage> global: type_17;
@group(2) @binding(10) 
var global_1: texture_2d<f32>;
@group(2) @binding(17) 
var global_2: sampler;
@group(2) @binding(13) 
var global_3: texture_2d<f32>;
@group(2) @binding(9) 
var global_4: texture_2d<f32>;
@group(2) @binding(11) 
var global_5: texture_2d<f32>;
@group(0) @binding(0) 
var<uniform> global_6: type_27;
@group(1) @binding(1) 
var global_7: sampler_comparison;
@group(1) @binding(0) 
var global_8: texture_depth_2d;
@group(2) @binding(14) 
var global_9: texture_2d<f32>;
@group(2) @binding(15) 
var global_10: texture_2d<f32>;
@group(2) @binding(23) 
var global_11: sampler;
@group(2) @binding(3) 
var<uniform> global_12: type_43;
var<private> global_13: vec3<f32>;
@group(2) @binding(4) 
var<uniform> global_14: type_43;
@group(2) @binding(5) 
var<uniform> global_15: type_43;
var<private> global_16: vec4<f32>;
@group(2) @binding(6) 
var<uniform> global_17: type_49;
@group(2) @binding(7) 
var<uniform> global_18: type_49;
@group(2) @binding(12) 
var global_19: texture_2d<f32>;
var<private> global_20: vec2<f32>;
var<private> global_21: vec3<f32>;
var<private> global_22: vec4<f32>;
@group(3) @binding(0) 
var<uniform> global_23: type_53;
var<private> global_24: vec4<f32>;
@group(2) @binding(2) 
var<uniform> global_25: type_56;
var<private> global_26: bool;
var<private> global_27: vec4<f32>;
var<private> global_28: vec4<f32>;
var<private> global_29: vec2<f32>;
var<private> global_30: vec4<f32>;
var<private> global_31: vec4<f32>;

fn function_() {
    var local: array<vec2<f32>, 3>;
    var local_1: array<vec2<f32>, 3>;
    var local_2: array<vec2<f32>, 3>;
    var local_3: array<vec2<f32>, 3>;
    var local_4: array<vec3<f32>, 6>;
    var local_5: array<vec3<f32>, 6>;
    var local_6: array<vec4<i32>, 6>;
    var local_7: array<vec4<i32>, 6>;
    var local_8: array<f32, 9>;
    var local_9: array<vec2<f32>, 3>;
    var local_10: array<vec2<f32>, 3>;
    var local_11: array<vec2<f32>, 3>;
    var local_12: array<vec2<f32>, 3>;
    var local_13: array<vec3<f32>, 6>;
    var local_14: array<vec3<f32>, 6>;
    var local_15: array<f32, 9>;
    var local_16: array<vec2<f32>, 3>;
    var local_17: array<vec2<f32>, 3>;
    var local_18: array<vec2<f32>, 3>;
    var local_19: array<vec2<f32>, 3>;
    var local_20: array<vec3<f32>, 4>;
    var local_21: array<vec3<f32>, 4>;
    var local_22: vec4<f32>;
    var local_23: vec4<f32>;
    var phi_6992_: vec4<f32>;
    var phi_7004_: f32;
    var phi_7001_: vec3<f32>;
    var phi_6997_: vec3<f32>;
    var phi_6993_: i32;
    var phi_6994_: f32;
    var phi_6998_: vec3<f32>;
    var phi_7636_: f32;
    var phi_7635_: vec3<f32>;
    var phi_7633_: vec3<f32>;
    var local_24: f32;
    var local_25: f32;
    var phi_7008_: f32;
    var local_26: vec3<f32>;
    var local_27: vec3<f32>;
    var phi_7014_: vec3<f32>;
    var phi_2205_: bool;
    var phi_7020_: vec3<f32>;
    var phi_7017_: f32;
    var phi_2262_: bool;
    var phi_7131_: vec3<f32>;
    var phi_7021_: i32;
    var phi_3318_: bool;
    var local_28: i32;
    var local_29: i32;
    var local_30: i32;
    var phi_3431_: bool;
    var phi_3438_: bool;
    var phi_3445_: bool;
    var local_31: i32;
    var local_32: i32;
    var local_33: i32;
    var phi_7026_: f32;
    var phi_7023_: i32;
    var phi_7032_: f32;
    var phi_7029_: i32;
    var local_34: f32;
    var phi_7033_: f32;
    var phi_7034_: f32;
    var local_35: i32;
    var local_36: i32;
    var local_37: i32;
    var phi_3718_: bool;
    var phi_3725_: bool;
    var phi_3732_: bool;
    var phi_7046_: f32;
    var phi_7043_: i32;
    var phi_7052_: f32;
    var phi_7049_: i32;
    var local_38: f32;
    var phi_7053_: f32;
    var phi_7054_: f32;
    var phi_7075_: f32;
    var phi_7072_: vec3<f32>;
    var phi_7074_: f32;
    var phi_7071_: vec3<f32>;
    var phi_7077_: vec3<f32>;
    var phi_7076_: f32;
    var phi_7163_: f32;
    var phi_7128_: vec3<f32>;
    var phi_7239_: f32;
    var phi_7388_: vec3<f32>;
    var phi_7387_: i32;
    var local_39: vec3<f32>;
    var phi_7389_: vec3<f32>;
    var phi_7399_: vec3<f32>;
    var phi_7396_: u32;
    var phi_4373_: bool;
    var phi_4380_: bool;
    var phi_4387_: bool;
    var phi_4394_: bool;
    var phi_7536_: f32;
    var phi_7533_: i32;
    var phi_7542_: f32;
    var phi_7539_: i32;
    var local_40: f32;
    var phi_7543_: f32;
    var phi_4464_: bool;
    var phi_7521_: i32;
    var phi_7520_: i32;
    var phi_7518_: f32;
    var phi_7525_: f32;
    var phi_7522_: i32;
    var phi_7531_: f32;
    var phi_7528_: i32;
    var local_41: f32;
    var phi_7532_: f32;
    var phi_7544_: f32;
    var phi_7598_: vec3<f32>;
    var phi_7398_: vec3<f32>;
    var phi_7155_: vec3<f32>;
    var phi_7154_: vec3<f32>;
    var phi_7159_: f32;
    var phi_7158_: f32;
    var phi_7253_: vec3<f32>;
    var phi_7171_: vec3<f32>;
    var phi_7170_: i32;
    var local_42: vec3<f32>;
    var phi_7173_: i32;
    var phi_7174_: i32;
    var phi_7180_: i32;
    var phi_7181_: i32;
    var phi_7216_: vec3<f32>;
    var phi_7204_: vec2<f32>;
    var phi_7188_: vec3<f32>;
    var phi_2692_: bool;
    var phi_7200_: f32;
    var phi_7199_: vec3<f32>;
    var phi_7198_: i32;
    var local_43: vec3<f32>;
    var local_44: f32;
    var phi_7201_: vec3<f32>;
    var phi_7225_: vec3<f32>;
    var phi_7353_: vec3<f32>;
    var phi_7256_: u32;
    var phi_6055_: bool;
    var phi_6062_: bool;
    var phi_6069_: bool;
    var phi_6076_: bool;
    var phi_7275_: f32;
    var phi_7272_: i32;
    var phi_7281_: f32;
    var phi_7278_: i32;
    var local_45: f32;
    var phi_7282_: f32;
    var phi_6146_: bool;
    var phi_7260_: i32;
    var phi_7259_: i32;
    var phi_7257_: f32;
    var phi_7264_: f32;
    var phi_7261_: i32;
    var phi_7270_: f32;
    var phi_7267_: i32;
    var local_46: f32;
    var phi_7271_: f32;
    var phi_7283_: f32;
    var phi_7351_: vec3<f32>;
    var phi_7400_: vec3<f32>;
    var phi_7397_: vec3<f32>;
    var phi_7439_: f32;
    var phi_7442_: f32;
    var phi_7443_: vec3<f32>;
    var phi_7517_: vec2<f32>;
    var local_47: f32;
    var local_48: f32;
    var local_49: vec3<f32>;
    var local_50: f32;
    var local_51: f32;
    var local_52: vec3<f32>;
    var local_53: vec3<f32>;
    var local_54: f32;
    var local_55: f32;
    var local_56: vec3<f32>;

    let _e198 = global_20;
    let _e201 = global.member[0i];
    let _e204 = global.member[1i];
    let _e207 = global.member[2i];
    let _e210 = i32((_e201.x + 0.5f));
    let _e218 = ((_e198 * _e201.z) + vec2(_e201.w));
    let _e219 = textureSampleLevel(global_1, global_2, _e218, 0f);
    local_22 = _e219;
    if (_e210 > 4i) {
        let _e221 = textureSampleLevel(global_3, global_2, _e218, 0f);
        phi_6992_ = _e221;
    } else {
        phi_6992_ = vec4<f32>(0f, 0f, 0f, 0f);
    }
    let _e223 = phi_6992_;
    local_23 = _e223;
    let _e226 = ((_e198 - vec2<f32>(0.5f, 0.5f)) * _e204.xy);
    let _e227 = dpdx(_e226);
    let _e228 = dpdy(_e226);
    phi_7004_ = 0f;
    phi_7001_ = vec3<f32>(0f, 0f, 0f);
    phi_6997_ = vec3<f32>(0f, 0f, 0f);
    phi_6993_ = 0i;
    loop {
        let _e230 = phi_7004_;
        let _e232 = phi_7001_;
        let _e234 = phi_6997_;
        let _e236 = phi_6993_;
        local_24 = _e230;
        local_25 = _e230;
        local_26 = _e234;
        local_27 = _e232;
        if (_e236 < 8i) {
            if (_e236 >= _e210) {
                break;
            }
            if (_e236 < 4i) {
                let _e241 = local_22[_e236];
                phi_6994_ = _e241;
            } else {
                let _e244 = local_23[(_e236 - 4i)];
                phi_6994_ = _e244;
            }
            let _e246 = phi_6994_;
            if (_e246 < 0.001953125f) {
                phi_7636_ = _e230;
                phi_7635_ = _e232;
                phi_7633_ = _e234;
                continue;
            }
            let _e260 = global.member[(3i + (_e236 / 4i))][(_e236 - (i32(floor((f32(_e236) / f32(4i)))) * 4i))];
            let _e262 = (_e227 * _e260);
            let _e263 = (_e228 * _e260);
            let _e276 = clamp((0.5f * log2(max(((max(dot(_e262, _e262), dot(_e263, _e263)) * _e207.w) * _e207.w), 0.00000001f))), 0f, max((log2(_e207.w) - 2f), 0f));
            let _e278 = f32(_e236);
            let _e289 = ((0.5f * exp2(ceil(_e276))) / _e207.w);
            let _e297 = ((vec2<f32>((_e278 - (floor((_e278 / _e207.y)) * _e207.y)), floor((_e278 / _e207.y))) + clamp(fract((_e226 * _e260)), vec2(_e289), vec2((1f - _e289)))) / _e207.yz);
            let _e298 = textureSampleLevel(global_4, global_2, _e297, _e276);
            phi_6998_ = vec3<f32>(0f, 0f, 1f);
            if (((i32((_e201.y + 0.5f)) >> bitcast<u32>(_e236)) & 1i) != 0i) {
                let _e306 = textureSampleLevel(global_5, global_2, _e297, _e276);
                let _e309 = ((_e306.xyz * 2f) - vec3<f32>(1f, 1f, 1f));
                let _e312 = (_e309.xy * _e204.z);
                let _e317 = vec3<f32>(_e312.x, _e309.y, _e309.z);
                phi_6998_ = vec3<f32>(_e317.x, _e312.y, _e317.z);
            }
            let _e324 = phi_6998_;
            phi_7636_ = (_e230 + _e246);
            phi_7635_ = (_e232 + (_e324 * _e246));
            phi_7633_ = (_e234 + (_e298.xyz * _e246));
            continue;
        } else {
            break;
        }
        continuing {
            let _e329 = phi_7636_;
            let _e331 = phi_7635_;
            let _e333 = phi_7633_;
            phi_7004_ = _e329;
            phi_7001_ = _e331;
            phi_6997_ = _e333;
            phi_6993_ = (_e236 + 1i);
        }
    }
    let _e336 = local_24;
    let _e337 = (_e336 > 0f);
    if _e337 {
        let _e339 = local_25;
        phi_7008_ = (1f / _e339);
    } else {
        phi_7008_ = 0f;
    }
    let _e342 = phi_7008_;
    let _e344 = local_26;
    if _e337 {
        let _e347 = local_27;
        phi_7014_ = (_e347 * _e342);
    } else {
        phi_7014_ = vec3<f32>(0f, 0f, 1f);
    }
    let _e350 = phi_7014_;
    let _e353 = global_22;
    let _e356 = (_e353.xyz * max((_e344 * _e342), vec3<f32>(0f, 0f, 0f)));
    let _e358 = global_22[3u];
    let _e361 = global_23.member[1u];
    if (_e361 > 0.5f) {
        let _e365 = global_23.member[2u];
        if (1f < _e365) {
            discard;
        }
    }
    let _e367 = global_21;
    let _e368 = normalize(_e367);
    let _e369 = global_24;
    let _e370 = _e369.xyz;
    let _e373 = (_e370 - (_e368 * dot(_e368, _e370)));
    let _e375 = (dot(_e373, _e373) > 0.000000000001f);
    phi_2205_ = _e375;
    if _e375 {
        phi_2205_ = (dot(_e350, _e350) > 0.000000000001f);
    }
    let _e379 = phi_2205_;
    phi_7020_ = _e368;
    if _e379 {
        let _e380 = normalize(_e373);
        let _e383 = global_24[3u];
        let _e387 = normalize(_e350);
        phi_7020_ = normalize((((_e380 * _e387.x) + ((cross(_e368, _e380) * select(1f, -1f, (_e383 < 0f))) * _e387.y)) + (_e368 * _e387.z)));
    }
    let _e398 = phi_7020_;
    let _e401 = global_25.member_5[3u];
    let _e402 = (_e401 > 0.5f);
    if _e402 {
        let _e405 = global_25.member_1[2u];
        phi_7017_ = clamp(_e405, 0f, 1f);
    } else {
        phi_7017_ = 0f;
    }
    let _e408 = phi_7017_;
    phi_2262_ = _e402;
    if _e402 {
        let _e409 = global_26;
        phi_2262_ = !(_e409);
    }
    let _e412 = phi_2262_;
    phi_7131_ = _e398;
    if (_e412 && (_e408 <= 0f)) {
        phi_7131_ = -(_e398);
    }
    let _e417 = phi_7131_;
    let _e419 = global_6.member_4;
    let _e421 = normalize(_e419.xyz);
    let _e423 = global_6.member_6;
    let _e424 = _e423.xyz;
    let _e425 = global_13;
    let _e426 = (_e424 - _e425);
    let _e427 = normalize(_e426);
    let _e429 = normalize((_e421 + _e427));
    let _e430 = global_26;
    let _e432 = (_e368 * select(-1f, 1f, _e430));
    let _e434 = global_27[0u];
    let _e435 = (_e434 > 0.5f);
    let _e438 = global_6.member_5[3u];
    phi_7163_ = 1f;
    phi_7128_ = _e356;
    if ((_e438 > 0.5f) && _e435) {
        switch bitcast<i32>(0u) {
            default: {
                let _e444 = global_6.member_21[0u];
                let _e445 = i32(_e444);
                let _e447 = global_6.member_20;
                let _e452 = global_6.member_20[3u];
                let _e453 = (dot(_e447.xyz, _e425) + _e452);
                phi_7021_ = 0i;
                loop {
                    let _e455 = phi_7021_;
                    local_28 = _e455;
                    local_29 = _e455;
                    local_30 = _e455;
                    local_31 = _e455;
                    local_32 = _e455;
                    local_33 = _e455;
                    local_35 = _e455;
                    local_36 = _e455;
                    local_37 = _e455;
                    let _e457 = (_e455 < (_e445 - 1i));
                    phi_3318_ = _e457;
                    if _e457 {
                        let _e460 = global_6.member_16[_e455];
                        phi_3318_ = (_e453 > _e460);
                    }
                    let _e463 = phi_3318_;
                    if _e463 {
                        continue;
                    } else {
                        break;
                    }
                    continuing {
                        phi_7021_ = (_e455 + 1i);
                    }
                }
                let _e467 = local_28;
                let _e469 = global_6.member_16[_e467];
                if (_e453 > _e469) {
                    phi_7077_ = vec3<f32>(1f, 1f, 1f);
                    phi_7076_ = 1f;
                    break;
                }
                let _e473 = local_29;
                let _e475 = global_6.member_18[_e473];
                let _e477 = (_e425 + (_e432 * _e475));
                switch bitcast<i32>(0u) {
                    default: {
                        let _e481 = local_30;
                        let _e483 = global_6.member_14[_e481];
                        let _e488 = (_e483 * vec4<f32>(_e477.x, _e477.y, _e477.z, 1f));
                        let _e490 = (_e488.x < 0f);
                        phi_3431_ = _e490;
                        if !(_e490) {
                            phi_3431_ = (_e488.x > 1f);
                        }
                        let _e494 = phi_3431_;
                        phi_3438_ = _e494;
                        if !(_e494) {
                            phi_3438_ = (_e488.y < 0f);
                        }
                        let _e499 = phi_3438_;
                        phi_3445_ = _e499;
                        if !(_e499) {
                            phi_3445_ = (_e488.y > 1f);
                        }
                        let _e504 = phi_3445_;
                        if _e504 {
                            phi_7034_ = 1f;
                            break;
                        }
                        let _e506 = local_31;
                        let _e510 = local_32;
                        let _e516 = global_6.member_23;
                        let _e517 = _e516.xy;
                        let _e518 = (vec2<f32>(f32((_e506 & 1i)), f32((_e510 >> bitcast<u32>(1i)))) * _e517);
                        let _e523 = local_33;
                        let _e525 = global_6.member_19[_e523];
                        let _e526 = (min(_e488.z, 1f) - _e525);
                        let _e529 = global_6.member_22;
                        let _e530 = _e529.xy;
                        let _e531 = (_e530 * 0.5f);
                        let _e533 = (_e518 + (_e488.xy * _e517));
                        let _e534 = (_e518 + _e531);
                        let _e536 = ((_e518 + _e517) - _e531);
                        let _e541 = vec4<f32>(_e534.x, _e534.y, _e536.x, _e536.y);
                        switch bitcast<i32>(0u) {
                            default: {
                                let _e545 = global_6.member_22[2u];
                                let _e546 = i32(_e545);
                                if (_e546 <= 0i) {
                                    let _e550 = clamp(_e533, _e541.xy, _e541.zw);
                                    let _e555 = textureSampleCompare(global_8, global_7, vec3<f32>(_e550.x, _e550.y, _e526).xy, _e526);
                                    phi_7033_ = _e555;
                                    break;
                                }
                                let _e557 = ((_e533 / _e530) + vec2<f32>(0.5f, 0.5f));
                                let _e558 = floor(_e557);
                                let _e559 = (_e557 - _e558);
                                let _e561 = (_e546 == 1i);
                                if _e561 {
                                    let _e562 = (_e559 * 2f);
                                    local_18[0i] = (vec2<f32>(3f, 3f) - _e562);
                                    local_18[1i] = (vec2<f32>(1f, 1f) + _e562);
                                    let _e568 = local_18[0i];
                                    local_19[0i] = (((vec2<f32>(2f, 2f) - _e559) / _e568) - vec2<f32>(1f, 1f));
                                    let _e572 = local_18[1i];
                                    local_19[1i] = ((_e559 / _e572) + vec2<f32>(1f, 1f));
                                } else {
                                    let _e576 = (_e559 * 3f);
                                    local_18[0i] = (vec2<f32>(4f, 4f) - _e576);
                                    local_18[1i] = vec2<f32>(7f, 7f);
                                    local_18[2i] = (vec2<f32>(1f, 1f) + _e576);
                                    let _e584 = local_18[0i];
                                    local_19[0i] = (((vec2<f32>(3f, 3f) - (_e559 * 2f)) / _e584) - vec2<f32>(2f, 2f));
                                    let _e589 = local_18[1i];
                                    local_19[1i] = ((vec2<f32>(3f, 3f) + _e559) / _e589);
                                    let _e592 = local_18[2i];
                                    local_19[2i] = ((_e559 / _e592) + vec2<f32>(2f, 2f));
                                }
                                let _e597 = select(3i, 2i, _e561);
                                phi_7026_ = 0f;
                                phi_7023_ = 0i;
                                loop {
                                    let _e599 = phi_7026_;
                                    let _e601 = phi_7023_;
                                    local_34 = _e599;
                                    if (_e601 < _e597) {
                                        phi_7032_ = _e599;
                                        phi_7029_ = 0i;
                                        loop {
                                            let _e604 = phi_7032_;
                                            let _e606 = phi_7029_;
                                            local_47 = _e604;
                                            if (_e606 < _e597) {
                                                continue;
                                            } else {
                                                break;
                                            }
                                            continuing {
                                                let _e610 = local_19[_e606][0u];
                                                let _e613 = local_19[_e601][1u];
                                                let _e619 = clamp((_e530 * ((_e558 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e610, _e613))), _e541.xy, _e541.zw);
                                                let _e622 = local_18[_e606][0u];
                                                let _e625 = local_18[_e601][1u];
                                                let _e631 = textureSampleCompare(global_8, global_7, vec3<f32>(_e619.x, _e619.y, _e526).xy, _e526);
                                                phi_7032_ = (_e604 + ((_e622 * _e625) * _e631));
                                                phi_7029_ = (_e606 + 1i);
                                            }
                                        }
                                        continue;
                                    } else {
                                        break;
                                    }
                                    continuing {
                                        let _e2644 = local_47;
                                        phi_7026_ = _e2644;
                                        phi_7023_ = (_e601 + 1i);
                                    }
                                }
                                let _e637 = local_34;
                                phi_7033_ = (_e637 * select(0.0069444445f, 0.0625f, _e561));
                                break;
                            }
                        }
                        let _e640 = phi_7033_;
                        phi_7034_ = _e640;
                        break;
                    }
                }
                let _e642 = phi_7034_;
                local_20 = array<vec3<f32>, 4>(vec3<f32>(1f, 0.45f, 0.45f), vec3<f32>(0.45f, 1f, 0.45f), vec3<f32>(0.5f, 0.6f, 1f), vec3<f32>(1f, 1f, 0.4f));
                let _e644 = local_35;
                let _e646 = local_20[_e644];
                let _e649 = local_36;
                let _e651 = global_6.member_17[_e649];
                phi_7074_ = _e642;
                phi_7071_ = _e646;
                if (_e453 > _e651) {
                    let _e655 = ((_e453 - _e651) / (_e469 - _e651));
                    let _e657 = local_37;
                    let _e658 = (_e657 + 1i);
                    if (_e658 < _e445) {
                        let _e662 = global_6.member_18[_e658];
                        let _e664 = (_e425 + (_e432 * _e662));
                        switch bitcast<i32>(0u) {
                            default: {
                                let _e668 = global_6.member_14[_e658];
                                let _e673 = (_e668 * vec4<f32>(_e664.x, _e664.y, _e664.z, 1f));
                                let _e675 = (_e673.x < 0f);
                                phi_3718_ = _e675;
                                if !(_e675) {
                                    phi_3718_ = (_e673.x > 1f);
                                }
                                let _e679 = phi_3718_;
                                phi_3725_ = _e679;
                                if !(_e679) {
                                    phi_3725_ = (_e673.y < 0f);
                                }
                                let _e684 = phi_3725_;
                                phi_3732_ = _e684;
                                if !(_e684) {
                                    phi_3732_ = (_e673.y > 1f);
                                }
                                let _e689 = phi_3732_;
                                if _e689 {
                                    phi_7054_ = 1f;
                                    break;
                                }
                                let _e697 = global_6.member_23;
                                let _e698 = _e697.xy;
                                let _e699 = (vec2<f32>(f32((_e658 & 1i)), f32((_e658 >> bitcast<u32>(1i)))) * _e698);
                                let _e704 = global_6.member_19[_e658];
                                let _e705 = (min(_e673.z, 1f) - _e704);
                                let _e708 = global_6.member_22;
                                let _e709 = _e708.xy;
                                let _e710 = (_e709 * 0.5f);
                                let _e712 = (_e699 + (_e673.xy * _e698));
                                let _e713 = (_e699 + _e710);
                                let _e715 = ((_e699 + _e698) - _e710);
                                let _e720 = vec4<f32>(_e713.x, _e713.y, _e715.x, _e715.y);
                                switch bitcast<i32>(0u) {
                                    default: {
                                        let _e724 = global_6.member_22[2u];
                                        let _e725 = i32(_e724);
                                        if (_e725 <= 0i) {
                                            let _e729 = clamp(_e712, _e720.xy, _e720.zw);
                                            let _e734 = textureSampleCompare(global_8, global_7, vec3<f32>(_e729.x, _e729.y, _e705).xy, _e705);
                                            phi_7053_ = _e734;
                                            break;
                                        }
                                        let _e736 = ((_e712 / _e709) + vec2<f32>(0.5f, 0.5f));
                                        let _e737 = floor(_e736);
                                        let _e738 = (_e736 - _e737);
                                        let _e740 = (_e725 == 1i);
                                        if _e740 {
                                            let _e741 = (_e738 * 2f);
                                            local_16[0i] = (vec2<f32>(3f, 3f) - _e741);
                                            local_16[1i] = (vec2<f32>(1f, 1f) + _e741);
                                            let _e747 = local_16[0i];
                                            local_17[0i] = (((vec2<f32>(2f, 2f) - _e738) / _e747) - vec2<f32>(1f, 1f));
                                            let _e751 = local_16[1i];
                                            local_17[1i] = ((_e738 / _e751) + vec2<f32>(1f, 1f));
                                        } else {
                                            let _e755 = (_e738 * 3f);
                                            local_16[0i] = (vec2<f32>(4f, 4f) - _e755);
                                            local_16[1i] = vec2<f32>(7f, 7f);
                                            local_16[2i] = (vec2<f32>(1f, 1f) + _e755);
                                            let _e763 = local_16[0i];
                                            local_17[0i] = (((vec2<f32>(3f, 3f) - (_e738 * 2f)) / _e763) - vec2<f32>(2f, 2f));
                                            let _e768 = local_16[1i];
                                            local_17[1i] = ((vec2<f32>(3f, 3f) + _e738) / _e768);
                                            let _e771 = local_16[2i];
                                            local_17[2i] = ((_e738 / _e771) + vec2<f32>(2f, 2f));
                                        }
                                        let _e776 = select(3i, 2i, _e740);
                                        phi_7046_ = 0f;
                                        phi_7043_ = 0i;
                                        loop {
                                            let _e778 = phi_7046_;
                                            let _e780 = phi_7043_;
                                            local_38 = _e778;
                                            if (_e780 < _e776) {
                                                phi_7052_ = _e778;
                                                phi_7049_ = 0i;
                                                loop {
                                                    let _e783 = phi_7052_;
                                                    let _e785 = phi_7049_;
                                                    local_48 = _e783;
                                                    if (_e785 < _e776) {
                                                        continue;
                                                    } else {
                                                        break;
                                                    }
                                                    continuing {
                                                        let _e789 = local_17[_e785][0u];
                                                        let _e792 = local_17[_e780][1u];
                                                        let _e798 = clamp((_e709 * ((_e737 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e789, _e792))), _e720.xy, _e720.zw);
                                                        let _e801 = local_16[_e785][0u];
                                                        let _e804 = local_16[_e780][1u];
                                                        let _e810 = textureSampleCompare(global_8, global_7, vec3<f32>(_e798.x, _e798.y, _e705).xy, _e705);
                                                        phi_7052_ = (_e783 + ((_e801 * _e804) * _e810));
                                                        phi_7049_ = (_e785 + 1i);
                                                    }
                                                }
                                                continue;
                                            } else {
                                                break;
                                            }
                                            continuing {
                                                let _e2659 = local_48;
                                                phi_7046_ = _e2659;
                                                phi_7043_ = (_e780 + 1i);
                                            }
                                        }
                                        let _e816 = local_38;
                                        phi_7053_ = (_e816 * select(0.0069444445f, 0.0625f, _e740));
                                        break;
                                    }
                                }
                                let _e819 = phi_7053_;
                                phi_7054_ = _e819;
                                break;
                            }
                        }
                        let _e821 = phi_7054_;
                        local_21 = array<vec3<f32>, 4>(vec3<f32>(1f, 0.45f, 0.45f), vec3<f32>(0.45f, 1f, 0.45f), vec3<f32>(0.5f, 0.6f, 1f), vec3<f32>(1f, 1f, 0.4f));
                        let _e824 = local_21[_e658];
                        phi_7075_ = mix(_e642, _e821, _e655);
                        phi_7072_ = mix(_e646, _e824, vec3(_e655));
                    } else {
                        phi_7075_ = mix(_e642, 1f, _e655);
                        phi_7072_ = _e646;
                    }
                    let _e829 = phi_7075_;
                    let _e831 = phi_7072_;
                    phi_7074_ = _e829;
                    phi_7071_ = _e831;
                }
                let _e833 = phi_7074_;
                let _e835 = phi_7071_;
                let _e838 = global_6.member_22[3u];
                phi_7077_ = select(vec3<f32>(1f, 1f, 1f), _e835, vec3((_e838 > 0.5f)));
                phi_7076_ = _e833;
                break;
            }
        }
        let _e843 = phi_7077_;
        let _e845 = phi_7076_;
        phi_7163_ = _e845;
        phi_7128_ = (_e356 * _e843);
    }
    let _e848 = phi_7163_;
    let _e850 = phi_7128_;
    let _e852 = global_6.member_5;
    let _e856 = global_6.member_4[3u];
    let _e857 = (_e852.xyz * _e856);
    let _e859 = global_24[3u];
    let _e860 = abs(_e859);
    phi_7239_ = 1f;
    if (_e860 > 0f) {
        phi_7239_ = min(_e860, 1f);
    }
    let _e864 = phi_7239_;
    if !(_e402) {
        let _e866 = dot(_e417, _e421);
        let _e873 = global_25.member_1[3u];
        let _e877 = global_25.member_1[2u];
        let _e884 = global_6.member_29[0u];
        if (_e884 > 0.5f) {
            let _e887 = global_6.member_29;
            let _e894 = ((_e887.z * _e417.x) - (_e887.w * _e417.z));
            let _e898 = ((_e887.w * _e417.x) + (_e887.z * _e417.z));
            let _e902 = (1.092548f * _e894);
            local_15 = array<f32, 9>(0.282095f, (0.488603f * _e417.y), (0.488603f * _e898), (0.488603f * _e894), (_e902 * _e417.y), ((1.092548f * _e417.y) * _e898), (0.315392f * (((3f * _e898) * _e898) - 1f)), (_e902 * _e898), (0.546274f * ((_e894 * _e894) - (_e417.y * _e417.y))));
            phi_7388_ = vec3<f32>(0f, 0f, 0f);
            phi_7387_ = 0i;
            loop {
                let _e917 = phi_7388_;
                let _e919 = phi_7387_;
                local_39 = _e917;
                if (_e919 < 9i) {
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e923 = textureLoad(global_9, (vec2<i32>(496i, 256i) + vec2<i32>(_e919, 0i)), 0i);
                    let _e926 = local_15[_e919];
                    phi_7388_ = (_e917 + (_e923.xyz * _e926));
                    phi_7387_ = (_e919 + 1i);
                }
            }
            let _e931 = local_39;
            let _e935 = global_6.member_29[1u];
            phi_7389_ = (max(_e931, vec3<f32>(0f, 0f, 0f)) * _e935);
        } else {
            let _e938 = global_6.member_9;
            let _e941 = global_6.member_8;
            let _e950 = global_6.member_8[3u];
            phi_7389_ = (mix(_e938.xyz, _e941.xyz, vec3(((_e417.y * 0.5f) + 0.5f))) * _e950);
        }
        let _e953 = phi_7389_;
        let _e959 = ((_e850 * ((_e953 * _e864) + ((_e857 * max(_e866, 0f)) * _e848))) + ((_e857 * ((pow(max(dot(_e417, _e429), 0f), _e873) * _e877) * step(0f, _e866))) * _e848));
        let _e962 = global_6.member_13[3u];
        phi_7398_ = _e959;
        if (_e962 > 0.5f) {
            let _e965 = global_6.member_11;
            let _e970 = global_6.member_11[3u];
            let _e972 = global_16;
            let _e975 = global_6.member_12;
            let _e980 = global_6.member_13;
            let _e983 = clamp(floor((_e972.xy * _e975.xy)), vec2<f32>(0f, 0f), (_e980.xy - vec2<f32>(1f, 1f)));
            let _e988 = global_6.member_12[2u];
            let _e992 = global_6.member_12[3u];
            let _e997 = global_6.member_13[2u];
            let _e1002 = global_6.member_13[1u];
            let _e1008 = global_6.member_13[0u];
            let _e1012 = u32(((((clamp(floor(((log2(max((dot(_e965.xyz, _e425) + _e970), 0.000001f)) * _e988) + _e992)), 0f, (_e997 - 1f)) * _e1002) + _e983.y) * _e1008) + _e983.x));
            let _e1019 = global_17.member[(_e1012 >> bitcast<u32>(2i))][(_e1012 & 3u)];
            let _e1020 = (_e1019 & 65535u);
            phi_7399_ = _e959;
            phi_7396_ = _e1020;
            loop {
                let _e1024 = phi_7399_;
                let _e1026 = phi_7396_;
                local_52 = _e1024;
                if (_e1026 < (_e1020 + (_e1019 >> bitcast<u32>(16i)))) {
                    let _e1029 = (_e1026 / 3u);
                    let _e1036 = global_18.member[(_e1029 >> bitcast<u32>(2i))][(_e1029 & 3u)];
                    let _e1042 = ((_e1036 >> bitcast<u32>(((_e1026 - (_e1029 * 3u)) * 10u))) & 1023u);
                    let _e1045 = global_12.member[_e1042];
                    let _e1047 = (_e1045.xyz - _e425);
                    let _e1048 = dot(_e1047, _e1047);
                    let _e1050 = (_e1048 * _e1045.w);
                    let _e1053 = clamp((1f - (_e1050 * _e1050)), 0f, 1f);
                    let _e1056 = (_e1047 * inverseSqrt(max(_e1048, 0.00000001f)));
                    let _e1059 = global_14.member[_e1042];
                    let _e1062 = global_15.member[_e1042];
                    let _e1070 = clamp(((dot(-(_e1056), _e1062.xyz) * _e1059.w) + _e1062.w), 0f, 1f);
                    let _e1077 = (_e1059.xyz * ((((_e1053 * _e1053) * _e1070) * _e1070) / max(_e1048, 0.0001f)));
                    phi_7598_ = _e1077;
                    if _e435 {
                        switch bitcast<i32>(0u) {
                            default: {
                                let _e1081 = global_6.member_21[2u];
                                let _e1082 = u32(_e1081);
                                if (_e1042 < _e1082) {
                                    let _e1086 = global_6.member_26[_e1042];
                                    let _e1089 = global_6.member_15[_e1042];
                                    let _e1098 = (_e1086.z * max((_e1089 * vec4<f32>(_e425.x, _e425.y, _e425.z, 1f)).w, 0f));
                                    let _e1101 = global_6.member_25[0u];
                                    let _e1107 = global_6.member_25[1u];
                                    let _e1110 = ((_e425 + (_e432 * (_e1098 * _e1101))) + (_e1056 * (_e1098 * _e1107)));
                                    let _e1115 = (_e1089 * vec4<f32>(_e1110.x, _e1110.y, _e1110.z, 1f));
                                    if (_e1115.w <= 0f) {
                                        phi_7544_ = 1f;
                                        break;
                                    }
                                    let _e1120 = (_e1115.xyz / vec3(_e1115.w));
                                    let _e1122 = (_e1120.x < 0f);
                                    phi_4373_ = _e1122;
                                    if !(_e1122) {
                                        phi_4373_ = (_e1120.x > 1f);
                                    }
                                    let _e1126 = phi_4373_;
                                    phi_4380_ = _e1126;
                                    if !(_e1126) {
                                        phi_4380_ = (_e1120.y < 0f);
                                    }
                                    let _e1131 = phi_4380_;
                                    phi_4387_ = _e1131;
                                    if !(_e1131) {
                                        phi_4387_ = (_e1120.y > 1f);
                                    }
                                    let _e1136 = phi_4387_;
                                    phi_4394_ = _e1136;
                                    if !(_e1136) {
                                        phi_4394_ = (_e1120.z > 1f);
                                    }
                                    let _e1141 = phi_4394_;
                                    if _e1141 {
                                        phi_7544_ = 1f;
                                        break;
                                    }
                                    let _e1144 = _e1086.xy;
                                    let _e1146 = global_6.member_23;
                                    let _e1147 = _e1146.zw;
                                    let _e1149 = global_6.member_22;
                                    let _e1150 = _e1149.xy;
                                    let _e1151 = (_e1150 * 0.5f);
                                    let _e1153 = (_e1144 + (_e1120.xy * _e1147));
                                    let _e1154 = (_e1144 + _e1151);
                                    let _e1156 = ((_e1144 + _e1147) - _e1151);
                                    let _e1161 = vec4<f32>(_e1154.x, _e1154.y, _e1156.x, _e1156.y);
                                    switch bitcast<i32>(0u) {
                                        default: {
                                            let _e1165 = global_6.member_22[2u];
                                            let _e1166 = i32(_e1165);
                                            if (_e1166 <= 0i) {
                                                let _e1170 = clamp(_e1153, _e1161.xy, _e1161.zw);
                                                let _e1175 = textureSampleCompare(global_8, global_7, vec3<f32>(_e1170.x, _e1170.y, _e1120.z).xy, _e1120.z);
                                                phi_7543_ = _e1175;
                                                break;
                                            }
                                            let _e1177 = ((_e1153 / _e1150) + vec2<f32>(0.5f, 0.5f));
                                            let _e1178 = floor(_e1177);
                                            let _e1179 = (_e1177 - _e1178);
                                            let _e1181 = (_e1166 == 1i);
                                            if _e1181 {
                                                let _e1182 = (_e1179 * 2f);
                                                local_11[0i] = (vec2<f32>(3f, 3f) - _e1182);
                                                local_11[1i] = (vec2<f32>(1f, 1f) + _e1182);
                                                let _e1188 = local_11[0i];
                                                local_12[0i] = (((vec2<f32>(2f, 2f) - _e1179) / _e1188) - vec2<f32>(1f, 1f));
                                                let _e1192 = local_11[1i];
                                                local_12[1i] = ((_e1179 / _e1192) + vec2<f32>(1f, 1f));
                                            } else {
                                                let _e1196 = (_e1179 * 3f);
                                                local_11[0i] = (vec2<f32>(4f, 4f) - _e1196);
                                                local_11[1i] = vec2<f32>(7f, 7f);
                                                local_11[2i] = (vec2<f32>(1f, 1f) + _e1196);
                                                let _e1204 = local_11[0i];
                                                local_12[0i] = (((vec2<f32>(3f, 3f) - (_e1179 * 2f)) / _e1204) - vec2<f32>(2f, 2f));
                                                let _e1209 = local_11[1i];
                                                local_12[1i] = ((vec2<f32>(3f, 3f) + _e1179) / _e1209);
                                                let _e1212 = local_11[2i];
                                                local_12[2i] = ((_e1179 / _e1212) + vec2<f32>(2f, 2f));
                                            }
                                            let _e1217 = select(3i, 2i, _e1181);
                                            phi_7536_ = 0f;
                                            phi_7533_ = 0i;
                                            loop {
                                                let _e1219 = phi_7536_;
                                                let _e1221 = phi_7533_;
                                                local_40 = _e1219;
                                                if (_e1221 < _e1217) {
                                                    phi_7542_ = _e1219;
                                                    phi_7539_ = 0i;
                                                    loop {
                                                        let _e1224 = phi_7542_;
                                                        let _e1226 = phi_7539_;
                                                        local_50 = _e1224;
                                                        if (_e1226 < _e1217) {
                                                            continue;
                                                        } else {
                                                            break;
                                                        }
                                                        continuing {
                                                            let _e1230 = local_12[_e1226][0u];
                                                            let _e1233 = local_12[_e1221][1u];
                                                            let _e1239 = clamp((_e1150 * ((_e1178 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e1230, _e1233))), _e1161.xy, _e1161.zw);
                                                            let _e1242 = local_11[_e1226][0u];
                                                            let _e1245 = local_11[_e1221][1u];
                                                            let _e1251 = textureSampleCompare(global_8, global_7, vec3<f32>(_e1239.x, _e1239.y, _e1120.z).xy, _e1120.z);
                                                            phi_7542_ = (_e1224 + ((_e1242 * _e1245) * _e1251));
                                                            phi_7539_ = (_e1226 + 1i);
                                                        }
                                                    }
                                                    continue;
                                                } else {
                                                    break;
                                                }
                                                continuing {
                                                    let _e2689 = local_50;
                                                    phi_7536_ = _e2689;
                                                    phi_7533_ = (_e1221 + 1i);
                                                }
                                            }
                                            let _e1257 = local_40;
                                            phi_7543_ = (_e1257 * select(0.0069444445f, 0.0625f, _e1181));
                                            break;
                                        }
                                    }
                                    let _e1260 = phi_7543_;
                                    phi_7544_ = _e1260;
                                    break;
                                }
                                let _e1261 = (_e1042 - _e1082);
                                let _e1264 = global_6.member_21[3u];
                                if (_e1261 >= u32(_e1264)) {
                                    phi_7544_ = 1f;
                                    break;
                                }
                                let _e1269 = global_6.member_27[_e1261];
                                let _e1272 = global_6.member_28[_e1261];
                                let _e1274 = _e1269.xyz;
                                let _e1277 = (_e1269.w * length((_e425 - _e1274)));
                                let _e1280 = global_6.member_25[0u];
                                let _e1286 = global_6.member_25[1u];
                                let _e1290 = (((_e425 + (_e432 * (_e1277 * _e1280))) + (_e1056 * (_e1277 * _e1286))) - _e1274);
                                let _e1291 = abs(_e1290);
                                let _e1294 = (_e1291.x >= _e1291.y);
                                phi_4464_ = _e1294;
                                if _e1294 {
                                    phi_4464_ = (_e1291.x >= _e1291.z);
                                }
                                let _e1298 = phi_4464_;
                                if _e1298 {
                                    phi_7520_ = select(1i, 0i, (_e1290.x > 0f));
                                    phi_7518_ = _e1291.x;
                                } else {
                                    let _e1303 = (_e1291.y >= _e1291.z);
                                    if _e1303 {
                                        phi_7521_ = select(3i, 2i, (_e1290.y > 0f));
                                    } else {
                                        phi_7521_ = select(5i, 4i, (_e1290.z > 0f));
                                    }
                                    let _e1311 = phi_7521_;
                                    phi_7520_ = _e1311;
                                    phi_7518_ = select(_e1291.z, _e1291.y, _e1303);
                                }
                                let _e1314 = phi_7520_;
                                let _e1316 = phi_7518_;
                                if (_e1316 <= 0f) {
                                    phi_7544_ = 1f;
                                    break;
                                }
                                local_13 = array<vec3<f32>, 6>(vec3<f32>(0f, 0f, 1f), vec3<f32>(0f, 0f, -1f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(1f, 0f, 0f));
                                let _e1319 = local_13[_e1314];
                                local_14 = array<vec3<f32>, 6>(vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 0f, -1f), vec3<f32>(0f, 0f, 1f), vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 1f, 0f));
                                let _e1322 = local_14[_e1314];
                                let _e1327 = global_6.member_24[2u];
                                let _e1330 = (vec2<f32>(dot(_e1290, _e1319), dot(_e1290, _e1322)) / vec2((_e1316 * _e1327)));
                                let _e1334 = (_e1272.z + (_e1272.w / _e1316));
                                if (_e1334 > 1f) {
                                    phi_7544_ = 1f;
                                    break;
                                }
                                let _e1349 = global_6.member_24;
                                let _e1350 = _e1349.xy;
                                let _e1352 = (_e1272.xy + (vec2<f32>(f32((_e1314 - (i32(floor((f32(_e1314) / f32(3i)))) * 3i))), f32((_e1314 / 3i))) * _e1350));
                                let _e1361 = global_6.member_22;
                                let _e1362 = _e1361.xy;
                                let _e1363 = (_e1362 * 0.5f);
                                let _e1365 = (_e1352 + (vec2<f32>((0.5f + (0.5f * _e1330.x)), (0.5f - (0.5f * _e1330.y))) * _e1350));
                                let _e1366 = (_e1352 + _e1363);
                                let _e1368 = ((_e1352 + _e1350) - _e1363);
                                let _e1373 = vec4<f32>(_e1366.x, _e1366.y, _e1368.x, _e1368.y);
                                switch bitcast<i32>(0u) {
                                    default: {
                                        let _e1377 = global_6.member_22[2u];
                                        let _e1378 = i32(_e1377);
                                        if (_e1378 <= 0i) {
                                            let _e1382 = clamp(_e1365, _e1373.xy, _e1373.zw);
                                            let _e1387 = textureSampleCompare(global_8, global_7, vec3<f32>(_e1382.x, _e1382.y, _e1334).xy, _e1334);
                                            phi_7532_ = _e1387;
                                            break;
                                        }
                                        let _e1389 = ((_e1365 / _e1362) + vec2<f32>(0.5f, 0.5f));
                                        let _e1390 = floor(_e1389);
                                        let _e1391 = (_e1389 - _e1390);
                                        let _e1393 = (_e1378 == 1i);
                                        if _e1393 {
                                            let _e1394 = (_e1391 * 2f);
                                            local_9[0i] = (vec2<f32>(3f, 3f) - _e1394);
                                            local_9[1i] = (vec2<f32>(1f, 1f) + _e1394);
                                            let _e1400 = local_9[0i];
                                            local_10[0i] = (((vec2<f32>(2f, 2f) - _e1391) / _e1400) - vec2<f32>(1f, 1f));
                                            let _e1404 = local_9[1i];
                                            local_10[1i] = ((_e1391 / _e1404) + vec2<f32>(1f, 1f));
                                        } else {
                                            let _e1408 = (_e1391 * 3f);
                                            local_9[0i] = (vec2<f32>(4f, 4f) - _e1408);
                                            local_9[1i] = vec2<f32>(7f, 7f);
                                            local_9[2i] = (vec2<f32>(1f, 1f) + _e1408);
                                            let _e1416 = local_9[0i];
                                            local_10[0i] = (((vec2<f32>(3f, 3f) - (_e1391 * 2f)) / _e1416) - vec2<f32>(2f, 2f));
                                            let _e1421 = local_9[1i];
                                            local_10[1i] = ((vec2<f32>(3f, 3f) + _e1391) / _e1421);
                                            let _e1424 = local_9[2i];
                                            local_10[2i] = ((_e1391 / _e1424) + vec2<f32>(2f, 2f));
                                        }
                                        let _e1429 = select(3i, 2i, _e1393);
                                        phi_7525_ = 0f;
                                        phi_7522_ = 0i;
                                        loop {
                                            let _e1431 = phi_7525_;
                                            let _e1433 = phi_7522_;
                                            local_41 = _e1431;
                                            if (_e1433 < _e1429) {
                                                phi_7531_ = _e1431;
                                                phi_7528_ = 0i;
                                                loop {
                                                    let _e1436 = phi_7531_;
                                                    let _e1438 = phi_7528_;
                                                    local_51 = _e1436;
                                                    if (_e1438 < _e1429) {
                                                        continue;
                                                    } else {
                                                        break;
                                                    }
                                                    continuing {
                                                        let _e1442 = local_10[_e1438][0u];
                                                        let _e1445 = local_10[_e1433][1u];
                                                        let _e1451 = clamp((_e1362 * ((_e1390 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e1442, _e1445))), _e1373.xy, _e1373.zw);
                                                        let _e1454 = local_9[_e1438][0u];
                                                        let _e1457 = local_9[_e1433][1u];
                                                        let _e1463 = textureSampleCompare(global_8, global_7, vec3<f32>(_e1451.x, _e1451.y, _e1334).xy, _e1334);
                                                        phi_7531_ = (_e1436 + ((_e1454 * _e1457) * _e1463));
                                                        phi_7528_ = (_e1438 + 1i);
                                                    }
                                                }
                                                continue;
                                            } else {
                                                break;
                                            }
                                            continuing {
                                                let _e2701 = local_51;
                                                phi_7525_ = _e2701;
                                                phi_7522_ = (_e1433 + 1i);
                                            }
                                        }
                                        let _e1469 = local_41;
                                        phi_7532_ = (_e1469 * select(0.0069444445f, 0.0625f, _e1393));
                                        break;
                                    }
                                }
                                let _e1472 = phi_7532_;
                                phi_7544_ = _e1472;
                                break;
                            }
                        }
                        let _e1474 = phi_7544_;
                        phi_7598_ = (_e1077 * _e1474);
                    }
                    let _e1477 = phi_7598_;
                    let _e1478 = dot(_e417, _e1056);
                    local_49 = (_e1024 + (((_e850 * max(_e1478, 0f)) * _e1477) + (_e1477 * ((pow(max(dot(_e417, normalize((_e1056 + _e427))), 0f), _e873) * _e877) * step(0f, _e1478)))));
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e2681 = local_49;
                    phi_7399_ = _e2681;
                    phi_7396_ = (_e1026 + bitcast<u32>(1i));
                }
            }
            let _e2711 = local_52;
            phi_7398_ = _e2711;
        }
        let _e1496 = phi_7398_;
        phi_7397_ = _e1496;
    } else {
        let _e1497 = clamp(_e207.x, 0f, 1f);
        let _e1498 = clamp(_e204.w, 0.045f, 1f);
        let _e1499 = (_e1498 * _e1498);
        let _e1501 = (_e850 * (1f - _e1497));
        let _e1503 = mix(vec3<f32>(0.04f, 0.04f, 0.04f), _e850, vec3(_e1497));
        let _e1504 = (_e408 > 0f);
        phi_7154_ = _e417;
        if _e1504 {
            let _e1505 = dpdx(_e425);
            let _e1506 = dpdy(_e425);
            let _e1507 = cross(_e1505, _e1506);
            phi_7155_ = _e417;
            if (dot(_e1507, _e1507) > 0.00000000000000000001f) {
                phi_7155_ = normalize(((normalize(_e1507) * select(1f, -1f, (dot(_e1507, _e427) < 0f))) + (_e417 - _e368)));
            }
            let _e1519 = phi_7155_;
            phi_7154_ = _e1519;
        }
        let _e1521 = phi_7154_;
        let _e1523 = max(dot(_e1521, _e427), 0.0001f);
        let _e1526 = dot(_e1521, _e421);
        let _e1527 = clamp(_e1526, 0f, 1f);
        let _e1529 = clamp(dot(_e1521, _e429), 0f, 1f);
        let _e1531 = clamp(dot(_e427, _e429), 0f, 1f);
        phi_7159_ = _e1523;
        phi_7158_ = _e1531;
        if _e1504 {
            phi_7159_ = max(_e1523, 0.5f);
            phi_7158_ = max(_e1531, 0.5f);
        }
        let _e1535 = phi_7159_;
        let _e1537 = phi_7158_;
        let _e1540 = (vec3<f32>(1f, 1f, 1f) - _e1503);
        let _e1542 = (_e1503 + (_e1540 * pow((1f - _e1537), 5f)));
        let _e1543 = (_e1499 * _e1499);
        let _e1545 = (_e1543 - 1f);
        let _e1547 = (((_e1529 * _e1529) * _e1545) + 1f);
        let _e1552 = (1f - _e1543);
        let _e1555 = sqrt((((_e1535 * _e1535) * _e1552) + _e1543));
        let _e1574 = ((((((vec3<f32>(1f, 1f, 1f) - _e1542) * _e1501) * clamp(dot(_e417, _e421), 0f, 1f)) + (((_e1542 * ((_e1543 / ((3.1415927f * _e1547) * _e1547)) * (0.5f / max(((_e1527 * _e1555) + (_e1535 * sqrt((((_e1527 * _e1527) * _e1552) + _e1543)))), 0.00001f)))) * 3.1415927f) * _e1527)) * _e857) * _e848);
        phi_7253_ = _e1574;
        if _e1504 {
            phi_7253_ = (_e1574 + (((((_e1501 * _e857) * _e848) * _e408) * clamp(-(_e1526), 0f, 1f)) * (0.35f + (0.65f * pow(clamp(dot(-(_e427), _e421), 0f, 1f), 3f)))));
        }
        let _e1590 = phi_7253_;
        let _e1593 = global_6.member_29[0u];
        if (_e1593 > 0.5f) {
            let _e1599 = textureSample(global_10, global_11, (((vec2<f32>(_e1535, _e1498) * 31f) + vec2<f32>(0.5f, 0.5f)) * vec2<f32>(0.03125f, 0.03125f)));
            let _e1602 = global_6.member_29;
            let _e1609 = ((_e1602.z * _e417.x) - (_e1602.w * _e417.z));
            let _e1613 = ((_e1602.w * _e417.x) + (_e1602.z * _e417.z));
            let _e1617 = (1.092548f * _e1609);
            local_8 = array<f32, 9>(0.282095f, (0.488603f * _e417.y), (0.488603f * _e1613), (0.488603f * _e1609), (_e1617 * _e417.y), ((1.092548f * _e417.y) * _e1613), (0.315392f * (((3f * _e1613) * _e1613) - 1f)), (_e1617 * _e1613), (0.546274f * ((_e1609 * _e1609) - (_e417.y * _e417.y))));
            phi_7171_ = vec3<f32>(0f, 0f, 0f);
            phi_7170_ = 0i;
            loop {
                let _e1632 = phi_7171_;
                let _e1634 = phi_7170_;
                local_42 = _e1632;
                if (_e1634 < 9i) {
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e1638 = textureLoad(global_9, (vec2<i32>(496i, 256i) + vec2<i32>(_e1634, 0i)), 0i);
                    let _e1641 = local_8[_e1634];
                    phi_7171_ = (_e1632 + (_e1638.xyz * _e1641));
                    phi_7170_ = (_e1634 + 1i);
                }
            }
            let _e1646 = local_42;
            let _e1650 = global_6.member_29[1u];
            let _e1653 = reflect(-(_e427), _e1521);
            let _e1670 = vec2<f32>(((atan2(((_e1602.z * _e1653.x) - (_e1602.w * _e1653.z)), -(((_e1602.w * _e1653.x) + (_e1602.z * _e1653.z)))) * 0.15915494f) + 0.5f), (acos(clamp(_e1653.y, -1f, 1f)) * 0.31830987f));
            let _e1671 = (_e1498 * 5f);
            let _e1673 = min(i32(_e1671), 4i);
            local_6 = array<vec4<i32>, 6>(vec4<i32>(0i, 0i, 512i, 256i), vec4<i32>(0i, 256i, 256i, 128i), vec4<i32>(256i, 256i, 128i, 64i), vec4<i32>(384i, 256i, 64i, 32i), vec4<i32>(448i, 256i, 32i, 16i), vec4<i32>(480i, 256i, 16i, 8i));
            let _e1675 = local_6[_e1673];
            let _e1679 = ((_e1670 * vec2<f32>(_e1675.zw)) - vec2<f32>(0.5f, 0.5f));
            let _e1680 = floor(_e1679);
            let _e1681 = (_e1679 - _e1680);
            let _e1683 = i32(_e1680.x);
            let _e1685 = i32(_e1680.y);
            phi_7173_ = _e1683;
            if (_e1683 < 0i) {
                phi_7173_ = (_e1683 + _e1675.z);
            }
            let _e1690 = phi_7173_;
            phi_7174_ = _e1690;
            if (_e1690 >= _e1675.z) {
                phi_7174_ = (_e1690 - _e1675.z);
            }
            let _e1695 = phi_7174_;
            let _e1696 = (_e1695 + 1i);
            let _e1698 = select(_e1696, 0i, (_e1696 == _e1675.z));
            let _e1702 = min((_e1685 + 1i), (_e1675.w - 1i));
            let _e1703 = max(_e1685, 0i);
            let _e1704 = _e1675.xy;
            let _e1707 = textureLoad(global_9, (_e1704 + vec2<i32>(_e1695, _e1703)), 0i);
            let _e1711 = textureLoad(global_9, (_e1704 + vec2<i32>(_e1698, _e1703)), 0i);
            let _e1715 = textureLoad(global_9, (_e1704 + vec2<i32>(_e1695, _e1702)), 0i);
            let _e1719 = textureLoad(global_9, (_e1704 + vec2<i32>(_e1698, _e1702)), 0i);
            let _e1722 = vec3(_e1681.x);
            local_7 = array<vec4<i32>, 6>(vec4<i32>(0i, 0i, 512i, 256i), vec4<i32>(0i, 256i, 256i, 128i), vec4<i32>(256i, 256i, 128i, 64i), vec4<i32>(384i, 256i, 64i, 32i), vec4<i32>(448i, 256i, 32i, 16i), vec4<i32>(480i, 256i, 16i, 8i));
            let _e1730 = local_7[(_e1673 + 1i)];
            let _e1734 = ((_e1670 * vec2<f32>(_e1730.zw)) - vec2<f32>(0.5f, 0.5f));
            let _e1735 = floor(_e1734);
            let _e1736 = (_e1734 - _e1735);
            let _e1738 = i32(_e1735.x);
            let _e1740 = i32(_e1735.y);
            phi_7180_ = _e1738;
            if (_e1738 < 0i) {
                phi_7180_ = (_e1738 + _e1730.z);
            }
            let _e1745 = phi_7180_;
            phi_7181_ = _e1745;
            if (_e1745 >= _e1730.z) {
                phi_7181_ = (_e1745 - _e1730.z);
            }
            let _e1750 = phi_7181_;
            let _e1751 = (_e1750 + 1i);
            let _e1753 = select(_e1751, 0i, (_e1751 == _e1730.z));
            let _e1757 = min((_e1740 + 1i), (_e1730.w - 1i));
            let _e1758 = max(_e1740, 0i);
            let _e1759 = _e1730.xy;
            let _e1762 = textureLoad(global_9, (_e1759 + vec2<i32>(_e1750, _e1758)), 0i);
            let _e1766 = textureLoad(global_9, (_e1759 + vec2<i32>(_e1753, _e1758)), 0i);
            let _e1770 = textureLoad(global_9, (_e1759 + vec2<i32>(_e1750, _e1757)), 0i);
            let _e1774 = textureLoad(global_9, (_e1759 + vec2<i32>(_e1753, _e1757)), 0i);
            let _e1777 = vec3(_e1736.x);
            phi_7216_ = (max(_e1646, vec3<f32>(0f, 0f, 0f)) * _e1650);
            phi_7204_ = _e1599.xy;
            phi_7188_ = (mix(mix(mix(_e1707.xyz, _e1711.xyz, _e1722), mix(_e1715.xyz, _e1719.xyz, _e1722), vec3(_e1681.y)), mix(mix(_e1762.xyz, _e1766.xyz, _e1777), mix(_e1770.xyz, _e1774.xyz, _e1777), vec3(_e1736.y)), vec3((_e1671 - f32(_e1673)))) * _e1650);
        } else {
            let _e1789 = ((vec4<f32>(-1f, -0.0275f, -0.572f, 0.022f) * _e1498) + vec4<f32>(1f, 0.0425f, 1.04f, -0.04f));
            let _e1802 = global_6.member_9;
            let _e1803 = _e1802.xyz;
            let _e1805 = global_6.member_8;
            let _e1806 = _e1805.xyz;
            let _e1814 = global_6.member_8[3u];
            let _e1815 = (mix(_e1803, _e1806, vec3(((_e417.y * 0.5f) + 0.5f))) * _e1814);
            phi_7216_ = _e1815;
            phi_7204_ = ((vec2<f32>(-1.04f, 1.04f) * ((min((_e1789.x * _e1789.x), exp2((-9.28f * _e1535))) * _e1789.x) + _e1789.y)) + _e1789.zw);
            phi_7188_ = mix((mix(_e1803, _e1806, vec3(((reflect(-(_e427), _e1521).y * 0.5f) + 0.5f))) * _e1814), _e1815, vec3(_e1498));
        }
        let _e1827 = phi_7216_;
        let _e1829 = phi_7204_;
        let _e1831 = phi_7188_;
        let _e1834 = global_25.member_6[3u];
        let _e1835 = (_e1834 > 0.5f);
        phi_2692_ = _e1835;
        if _e1835 {
            let _e1838 = global_6.member_33[2u];
            phi_2692_ = (_e1838 > 0.5f);
        }
        let _e1841 = phi_2692_;
        phi_7225_ = _e1831;
        if _e1841 {
            switch bitcast<i32>(0u) {
                default: {
                    let _e1844 = global_6.member_31;
                    let _e1845 = _e1844.xyz;
                    let _e1848 = global_6.member_33[0u];
                    let _e1853 = global_6.member_31[3u];
                    let _e1862 = global_6.member_32[1u];
                    let _e1868 = global_6.member_32[0u];
                    let _e1871 = (((_e1868 * (1f - smoothstep((_e1848 * 0.5f), _e1848, abs((dot(_e1845, _e425) - _e1853))))) * smoothstep(0.5f, 0.9f, dot(_e432, _e1845))) * (1f - smoothstep((_e1862 * 0.5f), _e1862, _e1498)));
                    if (_e1871 <= 0f) {
                        phi_7201_ = _e1831;
                        break;
                    }
                    let _e1878 = global_6.member_32[3u];
                    let _e1880 = (_e425 + ((_e417 - (_e1845 * dot(_e417, _e1845))) * _e1878));
                    let _e1882 = global_6.member_30;
                    let _e1887 = (_e1882 * vec4<f32>(_e1880.x, _e1880.y, _e1880.z, 1f));
                    let _e1899 = global_6.member_32[2u];
                    phi_7200_ = 0f;
                    phi_7199_ = vec3<f32>(0f, 0f, 0f);
                    phi_7198_ = 0i;
                    loop {
                        let _e1902 = phi_7200_;
                        let _e1904 = phi_7199_;
                        let _e1906 = phi_7198_;
                        local_43 = _e1904;
                        local_44 = _e1902;
                        if (_e1906 < 12i) {
                            continue;
                        } else {
                            break;
                        }
                        continuing {
                            let _e1908 = f32(_e1906);
                            let _e1913 = (_e1908 * 2.3999631f);
                            let _e1917 = global_6.member_33[1u];
                            let _e1922 = ((((vec2<f32>(_e1887.x, -(_e1887.y)) / vec2(_e1887.w)) * 0.5f) + vec2<f32>(0.5f, 0.5f)) + (vec2<f32>((cos(_e1913) * _e1917), sin(_e1913)) * (sqrt(((_e1908 + 0.5f) * 0.083333336f)) * (_e1899 * _e1498))));
                            let _e1924 = min(_e1922, (vec2<f32>(1f, 1f) - _e1922));
                            let _e1928 = smoothstep(0f, 0.04f, min(_e1924.x, _e1924.y));
                            let _e1930 = textureSampleLevel(global_19, global_2, clamp(_e1922, vec2<f32>(0f, 0f), vec2<f32>(1f, 1f)), 0f);
                            let _e1931 = _e1930.xyz;
                            phi_7200_ = (_e1902 + (_e1930.w * _e1928));
                            phi_7199_ = (_e1904 + ((_e1931 / (vec3<f32>(1f, 1f, 1f) - min(_e1931, vec3<f32>(0.995f, 0.995f, 0.995f)))) * _e1928));
                            phi_7198_ = (_e1906 + 1i);
                        }
                    }
                    let _e1942 = local_43;
                    let _e1945 = local_44;
                    phi_7201_ = mix(_e1831, ((_e1942 * vec3<f32>(0.083333336f, 0.083333336f, 0.083333336f)) + (_e1831 * (1f - (_e1945 * 0.083333336f)))), vec3(_e1871));
                    break;
                }
            }
            let _e1953 = phi_7201_;
            phi_7225_ = _e1953;
        }
        let _e1955 = phi_7225_;
        let _e1960 = ((_e1503 * _e1829.x) + vec3(_e1829.y));
        let _e1967 = (_e1590 + (((((vec3<f32>(1f, 1f, 1f) - _e1960) * _e1501) * _e1827) + (_e1960 * _e1955)) * _e864));
        let _e1970 = global_6.member_13[3u];
        phi_7400_ = _e1967;
        if (_e1970 > 0.5f) {
            let _e1973 = global_6.member_11;
            let _e1978 = global_6.member_11[3u];
            let _e1980 = global_16;
            let _e1983 = global_6.member_12;
            let _e1988 = global_6.member_13;
            let _e1991 = clamp(floor((_e1980.xy * _e1983.xy)), vec2<f32>(0f, 0f), (_e1988.xy - vec2<f32>(1f, 1f)));
            let _e1996 = global_6.member_12[2u];
            let _e2000 = global_6.member_12[3u];
            let _e2005 = global_6.member_13[2u];
            let _e2010 = global_6.member_13[1u];
            let _e2016 = global_6.member_13[0u];
            let _e2020 = u32(((((clamp(floor(((log2(max((dot(_e1973.xyz, _e425) + _e1978), 0.000001f)) * _e1996) + _e2000)), 0f, (_e2005 - 1f)) * _e2010) + _e1991.y) * _e2016) + _e1991.x));
            let _e2027 = global_17.member[(_e2020 >> bitcast<u32>(2i))][(_e2020 & 3u)];
            let _e2028 = (_e2027 & 65535u);
            phi_7353_ = _e1967;
            phi_7256_ = _e2028;
            loop {
                let _e2032 = phi_7353_;
                let _e2034 = phi_7256_;
                local_56 = _e2032;
                if (_e2034 < (_e2028 + (_e2027 >> bitcast<u32>(16i)))) {
                    let _e2037 = (_e2034 / 3u);
                    let _e2044 = global_18.member[(_e2037 >> bitcast<u32>(2i))][(_e2037 & 3u)];
                    let _e2050 = ((_e2044 >> bitcast<u32>(((_e2034 - (_e2037 * 3u)) * 10u))) & 1023u);
                    let _e2053 = global_12.member[_e2050];
                    let _e2055 = (_e2053.xyz - _e425);
                    let _e2056 = dot(_e2055, _e2055);
                    let _e2058 = (_e2056 * _e2053.w);
                    let _e2061 = clamp((1f - (_e2058 * _e2058)), 0f, 1f);
                    let _e2064 = (_e2055 * inverseSqrt(max(_e2056, 0.00000001f)));
                    let _e2067 = global_14.member[_e2050];
                    let _e2070 = global_15.member[_e2050];
                    let _e2078 = clamp(((dot(-(_e2064), _e2070.xyz) * _e2067.w) + _e2070.w), 0f, 1f);
                    let _e2085 = (_e2067.xyz * ((((_e2061 * _e2061) * _e2078) * _e2078) / max(_e2056, 0.0001f)));
                    phi_7351_ = _e2085;
                    if _e435 {
                        switch bitcast<i32>(0u) {
                            default: {
                                let _e2089 = global_6.member_21[2u];
                                let _e2090 = u32(_e2089);
                                if (_e2050 < _e2090) {
                                    let _e2094 = global_6.member_26[_e2050];
                                    let _e2097 = global_6.member_15[_e2050];
                                    let _e2106 = (_e2094.z * max((_e2097 * vec4<f32>(_e425.x, _e425.y, _e425.z, 1f)).w, 0f));
                                    let _e2109 = global_6.member_25[0u];
                                    let _e2115 = global_6.member_25[1u];
                                    let _e2118 = ((_e425 + (_e432 * (_e2106 * _e2109))) + (_e2064 * (_e2106 * _e2115)));
                                    let _e2123 = (_e2097 * vec4<f32>(_e2118.x, _e2118.y, _e2118.z, 1f));
                                    if (_e2123.w <= 0f) {
                                        phi_7283_ = 1f;
                                        break;
                                    }
                                    let _e2128 = (_e2123.xyz / vec3(_e2123.w));
                                    let _e2130 = (_e2128.x < 0f);
                                    phi_6055_ = _e2130;
                                    if !(_e2130) {
                                        phi_6055_ = (_e2128.x > 1f);
                                    }
                                    let _e2134 = phi_6055_;
                                    phi_6062_ = _e2134;
                                    if !(_e2134) {
                                        phi_6062_ = (_e2128.y < 0f);
                                    }
                                    let _e2139 = phi_6062_;
                                    phi_6069_ = _e2139;
                                    if !(_e2139) {
                                        phi_6069_ = (_e2128.y > 1f);
                                    }
                                    let _e2144 = phi_6069_;
                                    phi_6076_ = _e2144;
                                    if !(_e2144) {
                                        phi_6076_ = (_e2128.z > 1f);
                                    }
                                    let _e2149 = phi_6076_;
                                    if _e2149 {
                                        phi_7283_ = 1f;
                                        break;
                                    }
                                    let _e2152 = _e2094.xy;
                                    let _e2154 = global_6.member_23;
                                    let _e2155 = _e2154.zw;
                                    let _e2157 = global_6.member_22;
                                    let _e2158 = _e2157.xy;
                                    let _e2159 = (_e2158 * 0.5f);
                                    let _e2161 = (_e2152 + (_e2128.xy * _e2155));
                                    let _e2162 = (_e2152 + _e2159);
                                    let _e2164 = ((_e2152 + _e2155) - _e2159);
                                    let _e2169 = vec4<f32>(_e2162.x, _e2162.y, _e2164.x, _e2164.y);
                                    switch bitcast<i32>(0u) {
                                        default: {
                                            let _e2173 = global_6.member_22[2u];
                                            let _e2174 = i32(_e2173);
                                            if (_e2174 <= 0i) {
                                                let _e2178 = clamp(_e2161, _e2169.xy, _e2169.zw);
                                                let _e2183 = textureSampleCompare(global_8, global_7, vec3<f32>(_e2178.x, _e2178.y, _e2128.z).xy, _e2128.z);
                                                phi_7282_ = _e2183;
                                                break;
                                            }
                                            let _e2185 = ((_e2161 / _e2158) + vec2<f32>(0.5f, 0.5f));
                                            let _e2186 = floor(_e2185);
                                            let _e2187 = (_e2185 - _e2186);
                                            let _e2189 = (_e2174 == 1i);
                                            if _e2189 {
                                                let _e2190 = (_e2187 * 2f);
                                                local_2[0i] = (vec2<f32>(3f, 3f) - _e2190);
                                                local_2[1i] = (vec2<f32>(1f, 1f) + _e2190);
                                                let _e2196 = local_2[0i];
                                                local_3[0i] = (((vec2<f32>(2f, 2f) - _e2187) / _e2196) - vec2<f32>(1f, 1f));
                                                let _e2200 = local_2[1i];
                                                local_3[1i] = ((_e2187 / _e2200) + vec2<f32>(1f, 1f));
                                            } else {
                                                let _e2204 = (_e2187 * 3f);
                                                local_2[0i] = (vec2<f32>(4f, 4f) - _e2204);
                                                local_2[1i] = vec2<f32>(7f, 7f);
                                                local_2[2i] = (vec2<f32>(1f, 1f) + _e2204);
                                                let _e2212 = local_2[0i];
                                                local_3[0i] = (((vec2<f32>(3f, 3f) - (_e2187 * 2f)) / _e2212) - vec2<f32>(2f, 2f));
                                                let _e2217 = local_2[1i];
                                                local_3[1i] = ((vec2<f32>(3f, 3f) + _e2187) / _e2217);
                                                let _e2220 = local_2[2i];
                                                local_3[2i] = ((_e2187 / _e2220) + vec2<f32>(2f, 2f));
                                            }
                                            let _e2225 = select(3i, 2i, _e2189);
                                            phi_7275_ = 0f;
                                            phi_7272_ = 0i;
                                            loop {
                                                let _e2227 = phi_7275_;
                                                let _e2229 = phi_7272_;
                                                local_45 = _e2227;
                                                if (_e2229 < _e2225) {
                                                    phi_7281_ = _e2227;
                                                    phi_7278_ = 0i;
                                                    loop {
                                                        let _e2232 = phi_7281_;
                                                        let _e2234 = phi_7278_;
                                                        local_54 = _e2232;
                                                        if (_e2234 < _e2225) {
                                                            continue;
                                                        } else {
                                                            break;
                                                        }
                                                        continuing {
                                                            let _e2238 = local_3[_e2234][0u];
                                                            let _e2241 = local_3[_e2229][1u];
                                                            let _e2247 = clamp((_e2158 * ((_e2186 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e2238, _e2241))), _e2169.xy, _e2169.zw);
                                                            let _e2250 = local_2[_e2234][0u];
                                                            let _e2253 = local_2[_e2229][1u];
                                                            let _e2259 = textureSampleCompare(global_8, global_7, vec3<f32>(_e2247.x, _e2247.y, _e2128.z).xy, _e2128.z);
                                                            phi_7281_ = (_e2232 + ((_e2250 * _e2253) * _e2259));
                                                            phi_7278_ = (_e2234 + 1i);
                                                        }
                                                    }
                                                    continue;
                                                } else {
                                                    break;
                                                }
                                                continuing {
                                                    let _e2745 = local_54;
                                                    phi_7275_ = _e2745;
                                                    phi_7272_ = (_e2229 + 1i);
                                                }
                                            }
                                            let _e2265 = local_45;
                                            phi_7282_ = (_e2265 * select(0.0069444445f, 0.0625f, _e2189));
                                            break;
                                        }
                                    }
                                    let _e2268 = phi_7282_;
                                    phi_7283_ = _e2268;
                                    break;
                                }
                                let _e2269 = (_e2050 - _e2090);
                                let _e2272 = global_6.member_21[3u];
                                if (_e2269 >= u32(_e2272)) {
                                    phi_7283_ = 1f;
                                    break;
                                }
                                let _e2277 = global_6.member_27[_e2269];
                                let _e2280 = global_6.member_28[_e2269];
                                let _e2282 = _e2277.xyz;
                                let _e2285 = (_e2277.w * length((_e425 - _e2282)));
                                let _e2288 = global_6.member_25[0u];
                                let _e2294 = global_6.member_25[1u];
                                let _e2298 = (((_e425 + (_e432 * (_e2285 * _e2288))) + (_e2064 * (_e2285 * _e2294))) - _e2282);
                                let _e2299 = abs(_e2298);
                                let _e2302 = (_e2299.x >= _e2299.y);
                                phi_6146_ = _e2302;
                                if _e2302 {
                                    phi_6146_ = (_e2299.x >= _e2299.z);
                                }
                                let _e2306 = phi_6146_;
                                if _e2306 {
                                    phi_7259_ = select(1i, 0i, (_e2298.x > 0f));
                                    phi_7257_ = _e2299.x;
                                } else {
                                    let _e2311 = (_e2299.y >= _e2299.z);
                                    if _e2311 {
                                        phi_7260_ = select(3i, 2i, (_e2298.y > 0f));
                                    } else {
                                        phi_7260_ = select(5i, 4i, (_e2298.z > 0f));
                                    }
                                    let _e2319 = phi_7260_;
                                    phi_7259_ = _e2319;
                                    phi_7257_ = select(_e2299.z, _e2299.y, _e2311);
                                }
                                let _e2322 = phi_7259_;
                                let _e2324 = phi_7257_;
                                if (_e2324 <= 0f) {
                                    phi_7283_ = 1f;
                                    break;
                                }
                                local_4 = array<vec3<f32>, 6>(vec3<f32>(0f, 0f, 1f), vec3<f32>(0f, 0f, -1f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(1f, 0f, 0f));
                                let _e2327 = local_4[_e2322];
                                local_5 = array<vec3<f32>, 6>(vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 0f, -1f), vec3<f32>(0f, 0f, 1f), vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 1f, 0f));
                                let _e2330 = local_5[_e2322];
                                let _e2335 = global_6.member_24[2u];
                                let _e2338 = (vec2<f32>(dot(_e2298, _e2327), dot(_e2298, _e2330)) / vec2((_e2324 * _e2335)));
                                let _e2342 = (_e2280.z + (_e2280.w / _e2324));
                                if (_e2342 > 1f) {
                                    phi_7283_ = 1f;
                                    break;
                                }
                                let _e2357 = global_6.member_24;
                                let _e2358 = _e2357.xy;
                                let _e2360 = (_e2280.xy + (vec2<f32>(f32((_e2322 - (i32(floor((f32(_e2322) / f32(3i)))) * 3i))), f32((_e2322 / 3i))) * _e2358));
                                let _e2369 = global_6.member_22;
                                let _e2370 = _e2369.xy;
                                let _e2371 = (_e2370 * 0.5f);
                                let _e2373 = (_e2360 + (vec2<f32>((0.5f + (0.5f * _e2338.x)), (0.5f - (0.5f * _e2338.y))) * _e2358));
                                let _e2374 = (_e2360 + _e2371);
                                let _e2376 = ((_e2360 + _e2358) - _e2371);
                                let _e2381 = vec4<f32>(_e2374.x, _e2374.y, _e2376.x, _e2376.y);
                                switch bitcast<i32>(0u) {
                                    default: {
                                        let _e2385 = global_6.member_22[2u];
                                        let _e2386 = i32(_e2385);
                                        if (_e2386 <= 0i) {
                                            let _e2390 = clamp(_e2373, _e2381.xy, _e2381.zw);
                                            let _e2395 = textureSampleCompare(global_8, global_7, vec3<f32>(_e2390.x, _e2390.y, _e2342).xy, _e2342);
                                            phi_7271_ = _e2395;
                                            break;
                                        }
                                        let _e2397 = ((_e2373 / _e2370) + vec2<f32>(0.5f, 0.5f));
                                        let _e2398 = floor(_e2397);
                                        let _e2399 = (_e2397 - _e2398);
                                        let _e2401 = (_e2386 == 1i);
                                        if _e2401 {
                                            let _e2402 = (_e2399 * 2f);
                                            local[0i] = (vec2<f32>(3f, 3f) - _e2402);
                                            local[1i] = (vec2<f32>(1f, 1f) + _e2402);
                                            let _e2408 = local[0i];
                                            local_1[0i] = (((vec2<f32>(2f, 2f) - _e2399) / _e2408) - vec2<f32>(1f, 1f));
                                            let _e2412 = local[1i];
                                            local_1[1i] = ((_e2399 / _e2412) + vec2<f32>(1f, 1f));
                                        } else {
                                            let _e2416 = (_e2399 * 3f);
                                            local[0i] = (vec2<f32>(4f, 4f) - _e2416);
                                            local[1i] = vec2<f32>(7f, 7f);
                                            local[2i] = (vec2<f32>(1f, 1f) + _e2416);
                                            let _e2424 = local[0i];
                                            local_1[0i] = (((vec2<f32>(3f, 3f) - (_e2399 * 2f)) / _e2424) - vec2<f32>(2f, 2f));
                                            let _e2429 = local[1i];
                                            local_1[1i] = ((vec2<f32>(3f, 3f) + _e2399) / _e2429);
                                            let _e2432 = local[2i];
                                            local_1[2i] = ((_e2399 / _e2432) + vec2<f32>(2f, 2f));
                                        }
                                        let _e2437 = select(3i, 2i, _e2401);
                                        phi_7264_ = 0f;
                                        phi_7261_ = 0i;
                                        loop {
                                            let _e2439 = phi_7264_;
                                            let _e2441 = phi_7261_;
                                            local_46 = _e2439;
                                            if (_e2441 < _e2437) {
                                                phi_7270_ = _e2439;
                                                phi_7267_ = 0i;
                                                loop {
                                                    let _e2444 = phi_7270_;
                                                    let _e2446 = phi_7267_;
                                                    local_55 = _e2444;
                                                    if (_e2446 < _e2437) {
                                                        continue;
                                                    } else {
                                                        break;
                                                    }
                                                    continuing {
                                                        let _e2450 = local_1[_e2446][0u];
                                                        let _e2453 = local_1[_e2441][1u];
                                                        let _e2459 = clamp((_e2370 * ((_e2398 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e2450, _e2453))), _e2381.xy, _e2381.zw);
                                                        let _e2462 = local[_e2446][0u];
                                                        let _e2465 = local[_e2441][1u];
                                                        let _e2471 = textureSampleCompare(global_8, global_7, vec3<f32>(_e2459.x, _e2459.y, _e2342).xy, _e2342);
                                                        phi_7270_ = (_e2444 + ((_e2462 * _e2465) * _e2471));
                                                        phi_7267_ = (_e2446 + 1i);
                                                    }
                                                }
                                                continue;
                                            } else {
                                                break;
                                            }
                                            continuing {
                                                let _e2757 = local_55;
                                                phi_7264_ = _e2757;
                                                phi_7261_ = (_e2441 + 1i);
                                            }
                                        }
                                        let _e2477 = local_46;
                                        phi_7271_ = (_e2477 * select(0.0069444445f, 0.0625f, _e2401));
                                        break;
                                    }
                                }
                                let _e2480 = phi_7271_;
                                phi_7283_ = _e2480;
                                break;
                            }
                        }
                        let _e2482 = phi_7283_;
                        phi_7351_ = (_e2085 * _e2482);
                    }
                    let _e2485 = phi_7351_;
                    let _e2487 = normalize((_e2064 + _e427));
                    let _e2489 = clamp(dot(_e417, _e2064), 0f, 1f);
                    let _e2491 = clamp(dot(_e417, _e2487), 0f, 1f);
                    let _e2497 = (_e1503 + (_e1540 * pow((1f - clamp(dot(_e427, _e2487), 0f, 1f)), 5f)));
                    let _e2500 = (((_e2491 * _e2491) * _e1545) + 1f);
                    local_53 = (_e2032 + (((((vec3<f32>(1f, 1f, 1f) - _e2497) * _e1501) + ((_e2497 * ((_e1543 / ((3.1415927f * _e2500) * _e2500)) * (0.5f / max(((_e2489 * _e1555) + (_e1535 * sqrt((((_e2489 * _e2489) * _e1552) + _e1543)))), 0.00001f)))) * 3.1415927f)) * _e2489) * _e2485));
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e2737 = local_53;
                    phi_7353_ = _e2737;
                    phi_7256_ = (_e2034 + bitcast<u32>(1i));
                }
            }
            let _e2767 = local_56;
            phi_7400_ = _e2767;
        }
        let _e2525 = phi_7400_;
        phi_7397_ = _e2525;
    }
    let _e2527 = phi_7397_;
    let _e2530 = global_25.member_1[1u];
    let _e2534 = -(length(_e426));
    let _e2537 = global_6.member_7[3u];
    let _e2543 = global_6.member_9[3u];
    phi_7442_ = (1f - exp((_e2534 * _e2537)));
    if (_e2543 != 0f) {
        let _e2547 = (_e2543 * (_e425 - _e424).y);
        if (abs(_e2547) < 0.0001f) {
            phi_7439_ = (1f - (0.5f * _e2547));
        } else {
            phi_7439_ = ((1f - exp(min(-(_e2547), 60f))) / _e2547);
        }
        let _e2558 = phi_7439_;
        let _e2562 = global_6.member_6[1u];
        let _e2565 = global_6.member_6[3u];
        phi_7442_ = (1f - exp(((_e2534 * (_e2537 * exp(min((-(_e2543) * (_e2562 - _e2565)), 30f)))) * _e2558)));
    }
    let _e2576 = phi_7442_;
    let _e2578 = global_6.member_7;
    let _e2581 = mix(mix(_e2527, _e850, vec3(_e2530)), _e2578.xyz, vec3(_e2576));
    let _e2584 = global_6.member_33[3u];
    phi_7443_ = _e2581;
    if (_e2584 > 0.5f) {
        phi_7443_ = (_e2581 / (vec3<f32>(1f, 1f, 1f) + _e2581));
    }
    let _e2589 = phi_7443_;
    global_28 = vec4<f32>(_e2589.x, _e2589.y, _e2589.z, _e358);
    let _e2594 = global_30;
    let _e2595 = global_31;
    switch bitcast<i32>(0u) {
        default: {
            if (_e2595.w <= 0f) {
                phi_7517_ = vec2<f32>(0f, 0f);
                break;
            }
            phi_7517_ = (((_e2595.xy / vec2(_e2595.w)) - (_e2594.xy / vec2(_e2594.w))) * vec2<f32>(0.5f, -0.5f));
            break;
        }
    }
    let _e2609 = phi_7517_;
    global_29 = _e2609;
    return;
}

@fragment 
fn main(@location(0) param: vec3<f32>, @builtin(position) param_1: vec4<f32>, @location(2) param_2: vec2<f32>, @location(1) param_3: vec3<f32>, @location(3) param_4: vec4<f32>, @location(8) param_5: vec4<f32>, @builtin(front_facing) param_6: bool, @location(5) param_7: vec4<f32>, @location(6) param_8: vec4<f32>, @location(7) param_9: vec4<f32>) -> FragmentOutput {
    global_13 = param;
    global_16 = param_1;
    global_20 = param_2;
    global_21 = param_3;
    global_22 = param_4;
    global_24 = param_5;
    global_26 = param_6;
    global_27 = param_7;
    global_30 = param_8;
    global_31 = param_9;
    function_();
    let _e22 = global_28;
    let _e23 = global_29;
    return FragmentOutput(_e22, _e23);
}
