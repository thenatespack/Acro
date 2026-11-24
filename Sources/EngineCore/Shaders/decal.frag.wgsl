// Generated from decal.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: 29b58d0b22e29645
// glsl-fnv1a64: 0c25c26eb52d7739

diagnostic(off, derivative_uniformity);

struct type_21 {
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
}

struct type_34 {
    member: mat4x4<f32>,
    member_1: mat4x4<f32>,
    member_2: mat4x4<f32>,
    member_3: vec4<f32>,
    member_4: vec4<f32>,
    member_5: vec4<f32>,
}

struct type_40 {
    member: array<vec4<u32>, 1024>,
}

struct type_44 {
    member: array<vec4<f32>, 1024>,
}

@group(0) @binding(0) 
var<uniform> global: type_21;
@group(1) @binding(1) 
var global_1: sampler_comparison;
@group(1) @binding(0) 
var global_2: texture_depth_2d;
@group(2) @binding(14) 
var global_3: texture_2d<f32>;
@group(2) @binding(17) 
var global_4: sampler;
@group(2) @binding(15) 
var global_5: texture_2d<f32>;
@group(2) @binding(23) 
var global_6: sampler;
@group(2) @binding(10) 
var global_7: texture_2d<f32>;
@group(2) @binding(2) 
var<uniform> global_8: type_34;
var<private> global_9: vec4<f32>;
@group(2) @binding(9) 
var global_10: texture_2d<f32>;
@group(2) @binding(6) 
var<uniform> global_11: type_40;
@group(2) @binding(7) 
var<uniform> global_12: type_40;
@group(2) @binding(3) 
var<uniform> global_13: type_44;
@group(2) @binding(4) 
var<uniform> global_14: type_44;
@group(2) @binding(5) 
var<uniform> global_15: type_44;
var<private> global_16: vec4<f32>;

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
    var phi_4723_: vec3<f32>;
    var phi_4728_: vec3<f32>;
    var phi_4726_: vec4<f32>;
    var phi_4729_: f32;
    var phi_4733_: i32;
    var phi_2502_: bool;
    var local_13: i32;
    var local_14: i32;
    var local_15: i32;
    var phi_2615_: bool;
    var phi_2622_: bool;
    var phi_2629_: bool;
    var local_16: i32;
    var local_17: i32;
    var local_18: i32;
    var phi_4738_: f32;
    var phi_4735_: i32;
    var phi_4744_: f32;
    var phi_4741_: i32;
    var local_19: f32;
    var phi_4745_: f32;
    var phi_4746_: f32;
    var local_20: i32;
    var local_21: i32;
    var phi_2902_: bool;
    var phi_2909_: bool;
    var phi_2916_: bool;
    var phi_4758_: f32;
    var phi_4755_: i32;
    var phi_4764_: f32;
    var phi_4761_: i32;
    var local_22: f32;
    var phi_4765_: f32;
    var phi_4766_: f32;
    var phi_4768_: f32;
    var phi_4767_: f32;
    var phi_4769_: f32;
    var phi_4814_: f32;
    var phi_4816_: vec3<f32>;
    var phi_4815_: i32;
    var local_23: vec3<f32>;
    var phi_4819_: i32;
    var phi_4820_: i32;
    var phi_4826_: i32;
    var phi_4827_: i32;
    var phi_4848_: vec3<f32>;
    var phi_4841_: vec3<f32>;
    var phi_4833_: vec2<f32>;
    var phi_4859_: vec3<f32>;
    var phi_4857_: u32;
    var phi_3893_: bool;
    var phi_3900_: bool;
    var phi_3907_: bool;
    var phi_3914_: bool;
    var phi_4918_: f32;
    var phi_4915_: i32;
    var phi_4924_: f32;
    var phi_4921_: i32;
    var local_24: f32;
    var phi_4925_: f32;
    var phi_3984_: bool;
    var phi_4903_: i32;
    var phi_4902_: i32;
    var phi_4900_: f32;
    var phi_4907_: f32;
    var phi_4904_: i32;
    var phi_4913_: f32;
    var phi_4910_: i32;
    var local_25: f32;
    var phi_4914_: f32;
    var phi_4926_: f32;
    var phi_4858_: vec3<f32>;
    var local_26: f32;
    var local_27: f32;
    var local_28: vec3<f32>;
    var local_29: f32;
    var local_30: f32;
    var local_31: vec3<f32>;

    let _e154 = textureDimensions(global_7, 0i);
    let _e155 = vec2<i32>(_e154);
    let _e156 = global_9;
    let _e157 = _e156.xy;
    let _e158 = vec2<i32>(_e157);
    let _e159 = (_e155 - vec2<i32>(1i, 1i));
    let _e160 = clamp(_e158, vec2<i32>(0i, 0i), _e159);
    let _e161 = textureLoad(global_7, _e160, 0i);
    let _e167 = f32(_e155.x);
    let _e175 = f32(_e155.y);
    let _e180 = global_8.member_2;
    let _e182 = (_e180 * vec4<f32>(((((f32(_e160.x) + 0.5f) / _e167) * 2f) - 1f), (1f - (((f32(_e160.y) + 0.5f) / _e175) * 2f)), _e161.x, 1f));
    let _e186 = (_e182.xyz / vec3(_e182.w));
    let _e188 = global_8.member_1;
    let _e192 = vec4<f32>(_e186.x, _e186.y, _e186.z, 1f);
    let _e193 = (_e188 * _e192);
    if any((abs(_e193.xyz) > vec3<f32>(0.5f, 0.5f, 0.5f))) {
        discard;
    }
    let _e199 = clamp((_e158 + vec2<i32>(1i, 0i)), vec2<i32>(0i, 0i), _e159);
    let _e200 = textureLoad(global_7, _e199, 0i);
    let _e215 = (_e180 * vec4<f32>(((((f32(_e199.x) + 0.5f) / _e167) * 2f) - 1f), (1f - (((f32(_e199.y) + 0.5f) / _e175) * 2f)), _e200.x, 1f));
    let _e221 = clamp((_e158 - vec2<i32>(1i, 0i)), vec2<i32>(0i, 0i), _e159);
    let _e222 = textureLoad(global_7, _e221, 0i);
    let _e237 = (_e180 * vec4<f32>(((((f32(_e221.x) + 0.5f) / _e167) * 2f) - 1f), (1f - (((f32(_e221.y) + 0.5f) / _e175) * 2f)), _e222.x, 1f));
    let _e243 = clamp((_e158 + vec2<i32>(0i, 1i)), vec2<i32>(0i, 0i), _e159);
    let _e244 = textureLoad(global_7, _e243, 0i);
    let _e259 = (_e180 * vec4<f32>(((((f32(_e243.x) + 0.5f) / _e167) * 2f) - 1f), (1f - (((f32(_e243.y) + 0.5f) / _e175) * 2f)), _e244.x, 1f));
    let _e265 = clamp((_e158 - vec2<i32>(0i, 1i)), vec2<i32>(0i, 0i), _e159);
    let _e266 = textureLoad(global_7, _e265, 0i);
    let _e281 = (_e180 * vec4<f32>(((((f32(_e265.x) + 0.5f) / _e167) * 2f) - 1f), (1f - (((f32(_e265.y) + 0.5f) / _e175) * 2f)), _e266.x, 1f));
    let _e286 = ((_e215.xyz / vec3(_e215.w)) - _e186);
    let _e287 = (_e186 - (_e237.xyz / vec3(_e237.w)));
    let _e288 = ((_e259.xyz / vec3(_e259.w)) - _e186);
    let _e289 = (_e186 - (_e281.xyz / vec3(_e281.w)));
    let _e294 = select(_e287, _e286, vec3((dot(_e286, _e286) < dot(_e287, _e287))));
    let _e299 = select(_e289, _e288, vec3((dot(_e288, _e288) < dot(_e289, _e289))));
    let _e301 = global.member_6;
    let _e303 = (_e301.xyz - _e186);
    let _e304 = cross(_e294, _e299);
    if (dot(_e304, _e304) > 0.00000000000000000001f) {
        phi_4723_ = normalize(_e304);
    } else {
        phi_4723_ = normalize(_e303);
    }
    let _e310 = phi_4723_;
    phi_4728_ = _e310;
    if (dot(_e310, _e303) < 0f) {
        phi_4728_ = -(_e310);
    }
    let _e315 = phi_4728_;
    let _e316 = normalize(_e303);
    let _e322 = (_e186 + _e294);
    let _e329 = _e193.xy;
    let _e332 = (_e186 + _e299);
    let _e343 = global_8.member_4[3u];
    if (_e343 > 0.5f) {
        let _e345 = textureSampleGrad(global_10, global_4, vec2<f32>((_e193.x + 0.5f), (0.5f - _e193.y)), (((_e188 * vec4<f32>(_e322.x, _e322.y, _e322.z, 1f)).xy - _e329) * vec2<f32>(1f, -1f)), (((_e188 * vec4<f32>(_e332.x, _e332.y, _e332.z, 1f)).xy - _e329) * vec2<f32>(1f, -1f)));
        phi_4726_ = _e345;
    } else {
        phi_4726_ = vec4<f32>(1f, 1f, 1f, 1f);
    }
    let _e347 = phi_4726_;
    let _e349 = global_8.member_3;
    let _e352 = (_e349.xyz * _e347.xyz);
    let _e355 = global_8.member_3[3u];
    let _e357 = (_e355 * _e347.w);
    let _e360 = global_8.member_4[2u];
    phi_4729_ = _e357;
    if (_e360 > 0f) {
        let _e363 = global_8.member_5;
        phi_4729_ = (_e357 * clamp((dot(_e315, -(_e363.xyz)) / _e360), 0f, 1f));
    }
    let _e371 = phi_4729_;
    if (_e371 <= 0f) {
        discard;
    }
    let _e375 = global_8.member_4[1u];
    let _e376 = (_e375 * _e375);
    let _e378 = global.member_4;
    let _e380 = normalize(_e378.xyz);
    let _e382 = normalize((_e380 + _e316));
    let _e385 = global.member_5[3u];
    phi_4814_ = 1f;
    if (_e385 > 0.5f) {
        switch bitcast<i32>(0u) {
            default: {
                let _e390 = global.member_21[0u];
                let _e391 = i32(_e390);
                let _e393 = global.member_20;
                let _e398 = global.member_20[3u];
                let _e399 = (dot(_e393.xyz, _e186) + _e398);
                phi_4733_ = 0i;
                loop {
                    let _e401 = phi_4733_;
                    local_13 = _e401;
                    local_14 = _e401;
                    local_15 = _e401;
                    local_16 = _e401;
                    local_17 = _e401;
                    local_18 = _e401;
                    local_20 = _e401;
                    local_21 = _e401;
                    let _e403 = (_e401 < (_e391 - 1i));
                    phi_2502_ = _e403;
                    if _e403 {
                        let _e406 = global.member_16[_e401];
                        phi_2502_ = (_e399 > _e406);
                    }
                    let _e409 = phi_2502_;
                    if _e409 {
                        continue;
                    } else {
                        break;
                    }
                    continuing {
                        phi_4733_ = (_e401 + 1i);
                    }
                }
                let _e413 = local_13;
                let _e415 = global.member_16[_e413];
                if (_e399 > _e415) {
                    phi_4769_ = 1f;
                    break;
                }
                let _e419 = local_14;
                let _e421 = global.member_18[_e419];
                let _e423 = (_e186 + (_e315 * _e421));
                switch bitcast<i32>(0u) {
                    default: {
                        let _e427 = local_15;
                        let _e429 = global.member_14[_e427];
                        let _e434 = (_e429 * vec4<f32>(_e423.x, _e423.y, _e423.z, 1f));
                        let _e436 = (_e434.x < 0f);
                        phi_2615_ = _e436;
                        if !(_e436) {
                            phi_2615_ = (_e434.x > 1f);
                        }
                        let _e440 = phi_2615_;
                        phi_2622_ = _e440;
                        if !(_e440) {
                            phi_2622_ = (_e434.y < 0f);
                        }
                        let _e445 = phi_2622_;
                        phi_2629_ = _e445;
                        if !(_e445) {
                            phi_2629_ = (_e434.y > 1f);
                        }
                        let _e450 = phi_2629_;
                        if _e450 {
                            phi_4746_ = 1f;
                            break;
                        }
                        let _e452 = local_16;
                        let _e456 = local_17;
                        let _e462 = global.member_23;
                        let _e463 = _e462.xy;
                        let _e464 = (vec2<f32>(f32((_e452 & 1i)), f32((_e456 >> bitcast<u32>(1i)))) * _e463);
                        let _e469 = local_18;
                        let _e471 = global.member_19[_e469];
                        let _e472 = (min(_e434.z, 1f) - _e471);
                        let _e475 = global.member_22;
                        let _e476 = _e475.xy;
                        let _e477 = (_e476 * 0.5f);
                        let _e479 = (_e464 + (_e434.xy * _e463));
                        let _e480 = (_e464 + _e477);
                        let _e482 = ((_e464 + _e463) - _e477);
                        let _e487 = vec4<f32>(_e480.x, _e480.y, _e482.x, _e482.y);
                        switch bitcast<i32>(0u) {
                            default: {
                                let _e491 = global.member_22[2u];
                                let _e492 = i32(_e491);
                                if (_e492 <= 0i) {
                                    let _e496 = clamp(_e479, _e487.xy, _e487.zw);
                                    let _e501 = textureSampleCompare(global_2, global_1, vec3<f32>(_e496.x, _e496.y, _e472).xy, _e472);
                                    phi_4745_ = _e501;
                                    break;
                                }
                                let _e503 = ((_e479 / _e476) + vec2<f32>(0.5f, 0.5f));
                                let _e504 = floor(_e503);
                                let _e505 = (_e503 - _e504);
                                let _e507 = (_e492 == 1i);
                                if _e507 {
                                    let _e508 = (_e505 * 2f);
                                    local_11[0i] = (vec2<f32>(3f, 3f) - _e508);
                                    local_11[1i] = (vec2<f32>(1f, 1f) + _e508);
                                    let _e514 = local_11[0i];
                                    local_12[0i] = (((vec2<f32>(2f, 2f) - _e505) / _e514) - vec2<f32>(1f, 1f));
                                    let _e518 = local_11[1i];
                                    local_12[1i] = ((_e505 / _e518) + vec2<f32>(1f, 1f));
                                } else {
                                    let _e522 = (_e505 * 3f);
                                    local_11[0i] = (vec2<f32>(4f, 4f) - _e522);
                                    local_11[1i] = vec2<f32>(7f, 7f);
                                    local_11[2i] = (vec2<f32>(1f, 1f) + _e522);
                                    let _e530 = local_11[0i];
                                    local_12[0i] = (((vec2<f32>(3f, 3f) - (_e505 * 2f)) / _e530) - vec2<f32>(2f, 2f));
                                    let _e535 = local_11[1i];
                                    local_12[1i] = ((vec2<f32>(3f, 3f) + _e505) / _e535);
                                    let _e538 = local_11[2i];
                                    local_12[2i] = ((_e505 / _e538) + vec2<f32>(2f, 2f));
                                }
                                let _e543 = select(3i, 2i, _e507);
                                phi_4738_ = 0f;
                                phi_4735_ = 0i;
                                loop {
                                    let _e545 = phi_4738_;
                                    let _e547 = phi_4735_;
                                    local_19 = _e545;
                                    if (_e547 < _e543) {
                                        phi_4744_ = _e545;
                                        phi_4741_ = 0i;
                                        loop {
                                            let _e550 = phi_4744_;
                                            let _e552 = phi_4741_;
                                            local_26 = _e550;
                                            if (_e552 < _e543) {
                                                continue;
                                            } else {
                                                break;
                                            }
                                            continuing {
                                                let _e556 = local_12[_e552][0u];
                                                let _e559 = local_12[_e547][1u];
                                                let _e565 = clamp((_e476 * ((_e504 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e556, _e559))), _e487.xy, _e487.zw);
                                                let _e568 = local_11[_e552][0u];
                                                let _e571 = local_11[_e547][1u];
                                                let _e577 = textureSampleCompare(global_2, global_1, vec3<f32>(_e565.x, _e565.y, _e472).xy, _e472);
                                                phi_4744_ = (_e550 + ((_e568 * _e571) * _e577));
                                                phi_4741_ = (_e552 + 1i);
                                            }
                                        }
                                        continue;
                                    } else {
                                        break;
                                    }
                                    continuing {
                                        let _e1665 = local_26;
                                        phi_4738_ = _e1665;
                                        phi_4735_ = (_e547 + 1i);
                                    }
                                }
                                let _e583 = local_19;
                                phi_4745_ = (_e583 * select(0.0069444445f, 0.0625f, _e507));
                                break;
                            }
                        }
                        let _e586 = phi_4745_;
                        phi_4746_ = _e586;
                        break;
                    }
                }
                let _e588 = phi_4746_;
                let _e591 = local_20;
                let _e593 = global.member_17[_e591];
                phi_4767_ = _e588;
                if (_e399 > _e593) {
                    let _e597 = ((_e399 - _e593) / (_e415 - _e593));
                    let _e599 = local_21;
                    let _e600 = (_e599 + 1i);
                    if (_e600 < _e391) {
                        let _e604 = global.member_18[_e600];
                        let _e606 = (_e186 + (_e315 * _e604));
                        switch bitcast<i32>(0u) {
                            default: {
                                let _e610 = global.member_14[_e600];
                                let _e615 = (_e610 * vec4<f32>(_e606.x, _e606.y, _e606.z, 1f));
                                let _e617 = (_e615.x < 0f);
                                phi_2902_ = _e617;
                                if !(_e617) {
                                    phi_2902_ = (_e615.x > 1f);
                                }
                                let _e621 = phi_2902_;
                                phi_2909_ = _e621;
                                if !(_e621) {
                                    phi_2909_ = (_e615.y < 0f);
                                }
                                let _e626 = phi_2909_;
                                phi_2916_ = _e626;
                                if !(_e626) {
                                    phi_2916_ = (_e615.y > 1f);
                                }
                                let _e631 = phi_2916_;
                                if _e631 {
                                    phi_4766_ = 1f;
                                    break;
                                }
                                let _e639 = global.member_23;
                                let _e640 = _e639.xy;
                                let _e641 = (vec2<f32>(f32((_e600 & 1i)), f32((_e600 >> bitcast<u32>(1i)))) * _e640);
                                let _e646 = global.member_19[_e600];
                                let _e647 = (min(_e615.z, 1f) - _e646);
                                let _e650 = global.member_22;
                                let _e651 = _e650.xy;
                                let _e652 = (_e651 * 0.5f);
                                let _e654 = (_e641 + (_e615.xy * _e640));
                                let _e655 = (_e641 + _e652);
                                let _e657 = ((_e641 + _e640) - _e652);
                                let _e662 = vec4<f32>(_e655.x, _e655.y, _e657.x, _e657.y);
                                switch bitcast<i32>(0u) {
                                    default: {
                                        let _e666 = global.member_22[2u];
                                        let _e667 = i32(_e666);
                                        if (_e667 <= 0i) {
                                            let _e671 = clamp(_e654, _e662.xy, _e662.zw);
                                            let _e676 = textureSampleCompare(global_2, global_1, vec3<f32>(_e671.x, _e671.y, _e647).xy, _e647);
                                            phi_4765_ = _e676;
                                            break;
                                        }
                                        let _e678 = ((_e654 / _e651) + vec2<f32>(0.5f, 0.5f));
                                        let _e679 = floor(_e678);
                                        let _e680 = (_e678 - _e679);
                                        let _e682 = (_e667 == 1i);
                                        if _e682 {
                                            let _e683 = (_e680 * 2f);
                                            local_9[0i] = (vec2<f32>(3f, 3f) - _e683);
                                            local_9[1i] = (vec2<f32>(1f, 1f) + _e683);
                                            let _e689 = local_9[0i];
                                            local_10[0i] = (((vec2<f32>(2f, 2f) - _e680) / _e689) - vec2<f32>(1f, 1f));
                                            let _e693 = local_9[1i];
                                            local_10[1i] = ((_e680 / _e693) + vec2<f32>(1f, 1f));
                                        } else {
                                            let _e697 = (_e680 * 3f);
                                            local_9[0i] = (vec2<f32>(4f, 4f) - _e697);
                                            local_9[1i] = vec2<f32>(7f, 7f);
                                            local_9[2i] = (vec2<f32>(1f, 1f) + _e697);
                                            let _e705 = local_9[0i];
                                            local_10[0i] = (((vec2<f32>(3f, 3f) - (_e680 * 2f)) / _e705) - vec2<f32>(2f, 2f));
                                            let _e710 = local_9[1i];
                                            local_10[1i] = ((vec2<f32>(3f, 3f) + _e680) / _e710);
                                            let _e713 = local_9[2i];
                                            local_10[2i] = ((_e680 / _e713) + vec2<f32>(2f, 2f));
                                        }
                                        let _e718 = select(3i, 2i, _e682);
                                        phi_4758_ = 0f;
                                        phi_4755_ = 0i;
                                        loop {
                                            let _e720 = phi_4758_;
                                            let _e722 = phi_4755_;
                                            local_22 = _e720;
                                            if (_e722 < _e718) {
                                                phi_4764_ = _e720;
                                                phi_4761_ = 0i;
                                                loop {
                                                    let _e725 = phi_4764_;
                                                    let _e727 = phi_4761_;
                                                    local_27 = _e725;
                                                    if (_e727 < _e718) {
                                                        continue;
                                                    } else {
                                                        break;
                                                    }
                                                    continuing {
                                                        let _e731 = local_10[_e727][0u];
                                                        let _e734 = local_10[_e722][1u];
                                                        let _e740 = clamp((_e651 * ((_e679 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e731, _e734))), _e662.xy, _e662.zw);
                                                        let _e743 = local_9[_e727][0u];
                                                        let _e746 = local_9[_e722][1u];
                                                        let _e752 = textureSampleCompare(global_2, global_1, vec3<f32>(_e740.x, _e740.y, _e647).xy, _e647);
                                                        phi_4764_ = (_e725 + ((_e743 * _e746) * _e752));
                                                        phi_4761_ = (_e727 + 1i);
                                                    }
                                                }
                                                continue;
                                            } else {
                                                break;
                                            }
                                            continuing {
                                                let _e1679 = local_27;
                                                phi_4758_ = _e1679;
                                                phi_4755_ = (_e722 + 1i);
                                            }
                                        }
                                        let _e758 = local_22;
                                        phi_4765_ = (_e758 * select(0.0069444445f, 0.0625f, _e682));
                                        break;
                                    }
                                }
                                let _e761 = phi_4765_;
                                phi_4766_ = _e761;
                                break;
                            }
                        }
                        let _e763 = phi_4766_;
                        phi_4768_ = mix(_e588, _e763, _e597);
                    } else {
                        phi_4768_ = mix(_e588, 1f, _e597);
                    }
                    let _e767 = phi_4768_;
                    phi_4767_ = _e767;
                }
                let _e769 = phi_4767_;
                phi_4769_ = _e769;
                break;
            }
        }
        let _e771 = phi_4769_;
        phi_4814_ = _e771;
    }
    let _e773 = phi_4814_;
    let _e775 = global.member_5;
    let _e779 = global.member_4[3u];
    let _e782 = max(dot(_e315, _e316), 0.0001f);
    let _e784 = clamp(dot(_e315, _e380), 0f, 1f);
    let _e786 = clamp(dot(_e315, _e382), 0f, 1f);
    let _e791 = (vec3<f32>(0.96f, 0.96f, 0.96f) * pow((1f - clamp(dot(_e316, _e382), 0f, 1f)), 5f));
    let _e793 = (_e376 * _e376);
    let _e795 = (_e793 - 1f);
    let _e797 = (((_e786 * _e786) * _e795) + 1f);
    let _e802 = (1f - _e793);
    let _e805 = sqrt((((_e782 * _e782) * _e802) + _e793));
    let _e826 = global.member_29[0u];
    if (_e826 > 0.5f) {
        let _e832 = textureSample(global_5, global_6, (((vec2<f32>(_e782, _e375) * 31f) + vec2<f32>(0.5f, 0.5f)) * vec2<f32>(0.03125f, 0.03125f)));
        let _e835 = global.member_29;
        let _e842 = ((_e835.z * _e315.x) - (_e835.w * _e315.z));
        let _e846 = ((_e835.w * _e315.x) + (_e835.z * _e315.z));
        let _e850 = (1.092548f * _e842);
        local_8 = array<f32, 9>(0.282095f, (0.488603f * _e315.y), (0.488603f * _e846), (0.488603f * _e842), (_e850 * _e315.y), ((1.092548f * _e315.y) * _e846), (0.315392f * (((3f * _e846) * _e846) - 1f)), (_e850 * _e846), (0.546274f * ((_e842 * _e842) - (_e315.y * _e315.y))));
        phi_4816_ = vec3<f32>(0f, 0f, 0f);
        phi_4815_ = 0i;
        loop {
            let _e865 = phi_4816_;
            let _e867 = phi_4815_;
            local_23 = _e865;
            if (_e867 < 9i) {
                continue;
            } else {
                break;
            }
            continuing {
                let _e871 = textureLoad(global_3, (vec2<i32>(496i, 256i) + vec2<i32>(_e867, 0i)), 0i);
                let _e874 = local_8[_e867];
                phi_4816_ = (_e865 + (_e871.xyz * _e874));
                phi_4815_ = (_e867 + 1i);
            }
        }
        let _e879 = local_23;
        let _e883 = global.member_29[1u];
        let _e886 = reflect(-(_e316), _e315);
        let _e903 = vec2<f32>(((atan2(((_e835.z * _e886.x) - (_e835.w * _e886.z)), -(((_e835.w * _e886.x) + (_e835.z * _e886.z)))) * 0.15915494f) + 0.5f), (acos(clamp(_e886.y, -1f, 1f)) * 0.31830987f));
        let _e904 = (_e375 * 5f);
        let _e906 = min(i32(_e904), 4i);
        local_6 = array<vec4<i32>, 6>(vec4<i32>(0i, 0i, 512i, 256i), vec4<i32>(0i, 256i, 256i, 128i), vec4<i32>(256i, 256i, 128i, 64i), vec4<i32>(384i, 256i, 64i, 32i), vec4<i32>(448i, 256i, 32i, 16i), vec4<i32>(480i, 256i, 16i, 8i));
        let _e908 = local_6[_e906];
        let _e912 = ((_e903 * vec2<f32>(_e908.zw)) - vec2<f32>(0.5f, 0.5f));
        let _e913 = floor(_e912);
        let _e914 = (_e912 - _e913);
        let _e916 = i32(_e913.x);
        let _e918 = i32(_e913.y);
        phi_4819_ = _e916;
        if (_e916 < 0i) {
            phi_4819_ = (_e916 + _e908.z);
        }
        let _e923 = phi_4819_;
        phi_4820_ = _e923;
        if (_e923 >= _e908.z) {
            phi_4820_ = (_e923 - _e908.z);
        }
        let _e928 = phi_4820_;
        let _e929 = (_e928 + 1i);
        let _e931 = select(_e929, 0i, (_e929 == _e908.z));
        let _e935 = min((_e918 + 1i), (_e908.w - 1i));
        let _e936 = max(_e918, 0i);
        let _e937 = _e908.xy;
        let _e940 = textureLoad(global_3, (_e937 + vec2<i32>(_e928, _e936)), 0i);
        let _e944 = textureLoad(global_3, (_e937 + vec2<i32>(_e931, _e936)), 0i);
        let _e948 = textureLoad(global_3, (_e937 + vec2<i32>(_e928, _e935)), 0i);
        let _e952 = textureLoad(global_3, (_e937 + vec2<i32>(_e931, _e935)), 0i);
        let _e955 = vec3(_e914.x);
        local_7 = array<vec4<i32>, 6>(vec4<i32>(0i, 0i, 512i, 256i), vec4<i32>(0i, 256i, 256i, 128i), vec4<i32>(256i, 256i, 128i, 64i), vec4<i32>(384i, 256i, 64i, 32i), vec4<i32>(448i, 256i, 32i, 16i), vec4<i32>(480i, 256i, 16i, 8i));
        let _e963 = local_7[(_e906 + 1i)];
        let _e967 = ((_e903 * vec2<f32>(_e963.zw)) - vec2<f32>(0.5f, 0.5f));
        let _e968 = floor(_e967);
        let _e969 = (_e967 - _e968);
        let _e971 = i32(_e968.x);
        let _e973 = i32(_e968.y);
        phi_4826_ = _e971;
        if (_e971 < 0i) {
            phi_4826_ = (_e971 + _e963.z);
        }
        let _e978 = phi_4826_;
        phi_4827_ = _e978;
        if (_e978 >= _e963.z) {
            phi_4827_ = (_e978 - _e963.z);
        }
        let _e983 = phi_4827_;
        let _e984 = (_e983 + 1i);
        let _e986 = select(_e984, 0i, (_e984 == _e963.z));
        let _e990 = min((_e973 + 1i), (_e963.w - 1i));
        let _e991 = max(_e973, 0i);
        let _e992 = _e963.xy;
        let _e995 = textureLoad(global_3, (_e992 + vec2<i32>(_e983, _e991)), 0i);
        let _e999 = textureLoad(global_3, (_e992 + vec2<i32>(_e986, _e991)), 0i);
        let _e1003 = textureLoad(global_3, (_e992 + vec2<i32>(_e983, _e990)), 0i);
        let _e1007 = textureLoad(global_3, (_e992 + vec2<i32>(_e986, _e990)), 0i);
        let _e1010 = vec3(_e969.x);
        phi_4848_ = (mix(mix(mix(_e940.xyz, _e944.xyz, _e955), mix(_e948.xyz, _e952.xyz, _e955), vec3(_e914.y)), mix(mix(_e995.xyz, _e999.xyz, _e1010), mix(_e1003.xyz, _e1007.xyz, _e1010), vec3(_e969.y)), vec3((_e904 - f32(_e906)))) * _e883);
        phi_4841_ = (max(_e879, vec3<f32>(0f, 0f, 0f)) * _e883);
        phi_4833_ = _e832.xy;
    } else {
        let _e1022 = ((vec4<f32>(-1f, -0.0275f, -0.572f, 0.022f) * _e375) + vec4<f32>(1f, 0.0425f, 1.04f, -0.04f));
        let _e1035 = global.member_9;
        let _e1036 = _e1035.xyz;
        let _e1038 = global.member_8;
        let _e1039 = _e1038.xyz;
        let _e1047 = global.member_8[3u];
        let _e1048 = (mix(_e1036, _e1039, vec3(((_e315.y * 0.5f) + 0.5f))) * _e1047);
        phi_4848_ = mix((mix(_e1036, _e1039, vec3(((reflect(-(_e316), _e315).y * 0.5f) + 0.5f))) * _e1047), _e1048, vec3(_e375));
        phi_4841_ = _e1048;
        phi_4833_ = ((vec2<f32>(-1.04f, 1.04f) * ((min((_e1022.x * _e1022.x), exp2((-9.28f * _e782))) * _e1022.x) + _e1022.y)) + _e1022.zw);
    }
    let _e1060 = phi_4848_;
    let _e1062 = phi_4841_;
    let _e1064 = phi_4833_;
    let _e1069 = ((vec3<f32>(0.04f, 0.04f, 0.04f) * _e1064.x) + vec3(_e1064.y));
    let _e1075 = (((((((vec3<f32>(0.96f, 0.96f, 0.96f) - _e791) * _e352) + (((vec3<f32>(0.04f, 0.04f, 0.04f) + _e791) * ((_e793 / ((3.1415927f * _e797) * _e797)) * (0.5f / max(((_e784 * _e805) + (_e782 * sqrt((((_e784 * _e784) * _e802) + _e793)))), 0.00001f)))) * 3.1415927f)) * _e784) * (_e775.xyz * _e779)) * _e773) + ((((vec3<f32>(1f, 1f, 1f) - _e1069) * _e352) * _e1062) + (_e1069 * _e1060)));
    let _e1078 = global.member_13[3u];
    phi_4858_ = _e1075;
    if (_e1078 > 0.5f) {
        let _e1081 = global.member_11;
        let _e1086 = global.member_11[3u];
        let _e1089 = global.member_12;
        let _e1094 = global.member_13;
        let _e1097 = clamp(floor((_e157 * _e1089.xy)), vec2<f32>(0f, 0f), (_e1094.xy - vec2<f32>(1f, 1f)));
        let _e1102 = global.member_12[2u];
        let _e1106 = global.member_12[3u];
        let _e1111 = global.member_13[2u];
        let _e1116 = global.member_13[1u];
        let _e1122 = global.member_13[0u];
        let _e1126 = u32(((((clamp(floor(((log2(max((dot(_e1081.xyz, _e186) + _e1086), 0.000001f)) * _e1102) + _e1106)), 0f, (_e1111 - 1f)) * _e1116) + _e1097.y) * _e1122) + _e1097.x));
        let _e1133 = global_11.member[(_e1126 >> bitcast<u32>(2i))][(_e1126 & 3u)];
        let _e1134 = (_e1133 & 65535u);
        phi_4859_ = _e1075;
        phi_4857_ = _e1134;
        loop {
            let _e1138 = phi_4859_;
            let _e1140 = phi_4857_;
            local_31 = _e1138;
            if (_e1140 < (_e1134 + (_e1133 >> bitcast<u32>(16i)))) {
                let _e1143 = (_e1140 / 3u);
                let _e1150 = global_12.member[(_e1143 >> bitcast<u32>(2i))][(_e1143 & 3u)];
                let _e1156 = ((_e1150 >> bitcast<u32>(((_e1140 - (_e1143 * 3u)) * 10u))) & 1023u);
                let _e1159 = global_13.member[_e1156];
                let _e1161 = (_e1159.xyz - _e186);
                let _e1162 = dot(_e1161, _e1161);
                let _e1164 = (_e1162 * _e1159.w);
                let _e1167 = clamp((1f - (_e1164 * _e1164)), 0f, 1f);
                let _e1170 = (_e1161 * inverseSqrt(max(_e1162, 0.00000001f)));
                let _e1173 = global_14.member[_e1156];
                let _e1176 = global_15.member[_e1156];
                let _e1184 = clamp(((dot(-(_e1170), _e1176.xyz) * _e1173.w) + _e1176.w), 0f, 1f);
                switch bitcast<i32>(0u) {
                    default: {
                        let _e1195 = global.member_21[2u];
                        let _e1196 = u32(_e1195);
                        if (_e1156 < _e1196) {
                            let _e1200 = global.member_26[_e1156];
                            let _e1203 = global.member_15[_e1156];
                            let _e1208 = (_e1200.z * max((_e1203 * _e192).w, 0f));
                            let _e1211 = global.member_25[0u];
                            let _e1217 = global.member_25[1u];
                            let _e1220 = ((_e186 + (_e315 * (_e1208 * _e1211))) + (_e1170 * (_e1208 * _e1217)));
                            let _e1225 = (_e1203 * vec4<f32>(_e1220.x, _e1220.y, _e1220.z, 1f));
                            if (_e1225.w <= 0f) {
                                phi_4926_ = 1f;
                                break;
                            }
                            let _e1230 = (_e1225.xyz / vec3(_e1225.w));
                            let _e1232 = (_e1230.x < 0f);
                            phi_3893_ = _e1232;
                            if !(_e1232) {
                                phi_3893_ = (_e1230.x > 1f);
                            }
                            let _e1236 = phi_3893_;
                            phi_3900_ = _e1236;
                            if !(_e1236) {
                                phi_3900_ = (_e1230.y < 0f);
                            }
                            let _e1241 = phi_3900_;
                            phi_3907_ = _e1241;
                            if !(_e1241) {
                                phi_3907_ = (_e1230.y > 1f);
                            }
                            let _e1246 = phi_3907_;
                            phi_3914_ = _e1246;
                            if !(_e1246) {
                                phi_3914_ = (_e1230.z > 1f);
                            }
                            let _e1251 = phi_3914_;
                            if _e1251 {
                                phi_4926_ = 1f;
                                break;
                            }
                            let _e1254 = _e1200.xy;
                            let _e1256 = global.member_23;
                            let _e1257 = _e1256.zw;
                            let _e1259 = global.member_22;
                            let _e1260 = _e1259.xy;
                            let _e1261 = (_e1260 * 0.5f);
                            let _e1263 = (_e1254 + (_e1230.xy * _e1257));
                            let _e1264 = (_e1254 + _e1261);
                            let _e1266 = ((_e1254 + _e1257) - _e1261);
                            let _e1271 = vec4<f32>(_e1264.x, _e1264.y, _e1266.x, _e1266.y);
                            switch bitcast<i32>(0u) {
                                default: {
                                    let _e1275 = global.member_22[2u];
                                    let _e1276 = i32(_e1275);
                                    if (_e1276 <= 0i) {
                                        let _e1280 = clamp(_e1263, _e1271.xy, _e1271.zw);
                                        let _e1285 = textureSampleCompare(global_2, global_1, vec3<f32>(_e1280.x, _e1280.y, _e1230.z).xy, _e1230.z);
                                        phi_4925_ = _e1285;
                                        break;
                                    }
                                    let _e1287 = ((_e1263 / _e1260) + vec2<f32>(0.5f, 0.5f));
                                    let _e1288 = floor(_e1287);
                                    let _e1289 = (_e1287 - _e1288);
                                    let _e1291 = (_e1276 == 1i);
                                    if _e1291 {
                                        let _e1292 = (_e1289 * 2f);
                                        local_2[0i] = (vec2<f32>(3f, 3f) - _e1292);
                                        local_2[1i] = (vec2<f32>(1f, 1f) + _e1292);
                                        let _e1298 = local_2[0i];
                                        local_3[0i] = (((vec2<f32>(2f, 2f) - _e1289) / _e1298) - vec2<f32>(1f, 1f));
                                        let _e1302 = local_2[1i];
                                        local_3[1i] = ((_e1289 / _e1302) + vec2<f32>(1f, 1f));
                                    } else {
                                        let _e1306 = (_e1289 * 3f);
                                        local_2[0i] = (vec2<f32>(4f, 4f) - _e1306);
                                        local_2[1i] = vec2<f32>(7f, 7f);
                                        local_2[2i] = (vec2<f32>(1f, 1f) + _e1306);
                                        let _e1314 = local_2[0i];
                                        local_3[0i] = (((vec2<f32>(3f, 3f) - (_e1289 * 2f)) / _e1314) - vec2<f32>(2f, 2f));
                                        let _e1319 = local_2[1i];
                                        local_3[1i] = ((vec2<f32>(3f, 3f) + _e1289) / _e1319);
                                        let _e1322 = local_2[2i];
                                        local_3[2i] = ((_e1289 / _e1322) + vec2<f32>(2f, 2f));
                                    }
                                    let _e1327 = select(3i, 2i, _e1291);
                                    phi_4918_ = 0f;
                                    phi_4915_ = 0i;
                                    loop {
                                        let _e1329 = phi_4918_;
                                        let _e1331 = phi_4915_;
                                        local_24 = _e1329;
                                        if (_e1331 < _e1327) {
                                            phi_4924_ = _e1329;
                                            phi_4921_ = 0i;
                                            loop {
                                                let _e1334 = phi_4924_;
                                                let _e1336 = phi_4921_;
                                                local_29 = _e1334;
                                                if (_e1336 < _e1327) {
                                                    continue;
                                                } else {
                                                    break;
                                                }
                                                continuing {
                                                    let _e1340 = local_3[_e1336][0u];
                                                    let _e1343 = local_3[_e1331][1u];
                                                    let _e1349 = clamp((_e1260 * ((_e1288 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e1340, _e1343))), _e1271.xy, _e1271.zw);
                                                    let _e1352 = local_2[_e1336][0u];
                                                    let _e1355 = local_2[_e1331][1u];
                                                    let _e1361 = textureSampleCompare(global_2, global_1, vec3<f32>(_e1349.x, _e1349.y, _e1230.z).xy, _e1230.z);
                                                    phi_4924_ = (_e1334 + ((_e1352 * _e1355) * _e1361));
                                                    phi_4921_ = (_e1336 + 1i);
                                                }
                                            }
                                            continue;
                                        } else {
                                            break;
                                        }
                                        continuing {
                                            let _e1710 = local_29;
                                            phi_4918_ = _e1710;
                                            phi_4915_ = (_e1331 + 1i);
                                        }
                                    }
                                    let _e1367 = local_24;
                                    phi_4925_ = (_e1367 * select(0.0069444445f, 0.0625f, _e1291));
                                    break;
                                }
                            }
                            let _e1370 = phi_4925_;
                            phi_4926_ = _e1370;
                            break;
                        }
                        let _e1371 = (_e1156 - _e1196);
                        let _e1374 = global.member_21[3u];
                        if (_e1371 >= u32(_e1374)) {
                            phi_4926_ = 1f;
                            break;
                        }
                        let _e1379 = global.member_27[_e1371];
                        let _e1382 = global.member_28[_e1371];
                        let _e1384 = _e1379.xyz;
                        let _e1387 = (_e1379.w * length((_e186 - _e1384)));
                        let _e1390 = global.member_25[0u];
                        let _e1396 = global.member_25[1u];
                        let _e1400 = (((_e186 + (_e315 * (_e1387 * _e1390))) + (_e1170 * (_e1387 * _e1396))) - _e1384);
                        let _e1401 = abs(_e1400);
                        let _e1404 = (_e1401.x >= _e1401.y);
                        phi_3984_ = _e1404;
                        if _e1404 {
                            phi_3984_ = (_e1401.x >= _e1401.z);
                        }
                        let _e1408 = phi_3984_;
                        if _e1408 {
                            phi_4902_ = select(1i, 0i, (_e1400.x > 0f));
                            phi_4900_ = _e1401.x;
                        } else {
                            let _e1413 = (_e1401.y >= _e1401.z);
                            if _e1413 {
                                phi_4903_ = select(3i, 2i, (_e1400.y > 0f));
                            } else {
                                phi_4903_ = select(5i, 4i, (_e1400.z > 0f));
                            }
                            let _e1421 = phi_4903_;
                            phi_4902_ = _e1421;
                            phi_4900_ = select(_e1401.z, _e1401.y, _e1413);
                        }
                        let _e1424 = phi_4902_;
                        let _e1426 = phi_4900_;
                        if (_e1426 <= 0f) {
                            phi_4926_ = 1f;
                            break;
                        }
                        local_4 = array<vec3<f32>, 6>(vec3<f32>(0f, 0f, 1f), vec3<f32>(0f, 0f, -1f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(1f, 0f, 0f));
                        let _e1429 = local_4[_e1424];
                        local_5 = array<vec3<f32>, 6>(vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 0f, -1f), vec3<f32>(0f, 0f, 1f), vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 1f, 0f));
                        let _e1432 = local_5[_e1424];
                        let _e1437 = global.member_24[2u];
                        let _e1440 = (vec2<f32>(dot(_e1400, _e1429), dot(_e1400, _e1432)) / vec2((_e1426 * _e1437)));
                        let _e1444 = (_e1382.z + (_e1382.w / _e1426));
                        if (_e1444 > 1f) {
                            phi_4926_ = 1f;
                            break;
                        }
                        let _e1459 = global.member_24;
                        let _e1460 = _e1459.xy;
                        let _e1462 = (_e1382.xy + (vec2<f32>(f32((_e1424 - (i32(floor((f32(_e1424) / f32(3i)))) * 3i))), f32((_e1424 / 3i))) * _e1460));
                        let _e1471 = global.member_22;
                        let _e1472 = _e1471.xy;
                        let _e1473 = (_e1472 * 0.5f);
                        let _e1475 = (_e1462 + (vec2<f32>((0.5f + (0.5f * _e1440.x)), (0.5f - (0.5f * _e1440.y))) * _e1460));
                        let _e1476 = (_e1462 + _e1473);
                        let _e1478 = ((_e1462 + _e1460) - _e1473);
                        let _e1483 = vec4<f32>(_e1476.x, _e1476.y, _e1478.x, _e1478.y);
                        switch bitcast<i32>(0u) {
                            default: {
                                let _e1487 = global.member_22[2u];
                                let _e1488 = i32(_e1487);
                                if (_e1488 <= 0i) {
                                    let _e1492 = clamp(_e1475, _e1483.xy, _e1483.zw);
                                    let _e1497 = textureSampleCompare(global_2, global_1, vec3<f32>(_e1492.x, _e1492.y, _e1444).xy, _e1444);
                                    phi_4914_ = _e1497;
                                    break;
                                }
                                let _e1499 = ((_e1475 / _e1472) + vec2<f32>(0.5f, 0.5f));
                                let _e1500 = floor(_e1499);
                                let _e1501 = (_e1499 - _e1500);
                                let _e1503 = (_e1488 == 1i);
                                if _e1503 {
                                    let _e1504 = (_e1501 * 2f);
                                    local[0i] = (vec2<f32>(3f, 3f) - _e1504);
                                    local[1i] = (vec2<f32>(1f, 1f) + _e1504);
                                    let _e1510 = local[0i];
                                    local_1[0i] = (((vec2<f32>(2f, 2f) - _e1501) / _e1510) - vec2<f32>(1f, 1f));
                                    let _e1514 = local[1i];
                                    local_1[1i] = ((_e1501 / _e1514) + vec2<f32>(1f, 1f));
                                } else {
                                    let _e1518 = (_e1501 * 3f);
                                    local[0i] = (vec2<f32>(4f, 4f) - _e1518);
                                    local[1i] = vec2<f32>(7f, 7f);
                                    local[2i] = (vec2<f32>(1f, 1f) + _e1518);
                                    let _e1526 = local[0i];
                                    local_1[0i] = (((vec2<f32>(3f, 3f) - (_e1501 * 2f)) / _e1526) - vec2<f32>(2f, 2f));
                                    let _e1531 = local[1i];
                                    local_1[1i] = ((vec2<f32>(3f, 3f) + _e1501) / _e1531);
                                    let _e1534 = local[2i];
                                    local_1[2i] = ((_e1501 / _e1534) + vec2<f32>(2f, 2f));
                                }
                                let _e1539 = select(3i, 2i, _e1503);
                                phi_4907_ = 0f;
                                phi_4904_ = 0i;
                                loop {
                                    let _e1541 = phi_4907_;
                                    let _e1543 = phi_4904_;
                                    local_25 = _e1541;
                                    if (_e1543 < _e1539) {
                                        phi_4913_ = _e1541;
                                        phi_4910_ = 0i;
                                        loop {
                                            let _e1546 = phi_4913_;
                                            let _e1548 = phi_4910_;
                                            local_30 = _e1546;
                                            if (_e1548 < _e1539) {
                                                continue;
                                            } else {
                                                break;
                                            }
                                            continuing {
                                                let _e1552 = local_1[_e1548][0u];
                                                let _e1555 = local_1[_e1543][1u];
                                                let _e1561 = clamp((_e1472 * ((_e1500 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e1552, _e1555))), _e1483.xy, _e1483.zw);
                                                let _e1564 = local[_e1548][0u];
                                                let _e1567 = local[_e1543][1u];
                                                let _e1573 = textureSampleCompare(global_2, global_1, vec3<f32>(_e1561.x, _e1561.y, _e1444).xy, _e1444);
                                                phi_4913_ = (_e1546 + ((_e1564 * _e1567) * _e1573));
                                                phi_4910_ = (_e1548 + 1i);
                                            }
                                        }
                                        continue;
                                    } else {
                                        break;
                                    }
                                    continuing {
                                        let _e1722 = local_30;
                                        phi_4907_ = _e1722;
                                        phi_4904_ = (_e1543 + 1i);
                                    }
                                }
                                let _e1579 = local_25;
                                phi_4914_ = (_e1579 * select(0.0069444445f, 0.0625f, _e1503));
                                break;
                            }
                        }
                        let _e1582 = phi_4914_;
                        phi_4926_ = _e1582;
                        break;
                    }
                }
                let _e1584 = phi_4926_;
                let _e1587 = normalize((_e1170 + _e316));
                let _e1589 = clamp(dot(_e315, _e1170), 0f, 1f);
                let _e1591 = clamp(dot(_e315, _e1587), 0f, 1f);
                let _e1596 = (vec3<f32>(0.96f, 0.96f, 0.96f) * pow((1f - clamp(dot(_e316, _e1587), 0f, 1f)), 5f));
                let _e1600 = (((_e1591 * _e1591) * _e795) + 1f);
                local_28 = (_e1138 + (((((vec3<f32>(0.96f, 0.96f, 0.96f) - _e1596) * _e352) + (((vec3<f32>(0.04f, 0.04f, 0.04f) + _e1596) * ((_e793 / ((3.1415927f * _e1600) * _e1600)) * (0.5f / max(((_e1589 * _e805) + (_e782 * sqrt((((_e1589 * _e1589) * _e802) + _e793)))), 0.00001f)))) * 3.1415927f)) * _e1589) * ((_e1173.xyz * ((((_e1167 * _e1167) * _e1184) * _e1184) / max(_e1162, 0.0001f))) * _e1584)));
                continue;
            } else {
                break;
            }
            continuing {
                let _e1702 = local_28;
                phi_4859_ = _e1702;
                phi_4857_ = (_e1140 + bitcast<u32>(1i));
            }
        }
        let _e1731 = local_31;
        phi_4858_ = _e1731;
    }
    let _e1625 = phi_4858_;
    let _e1628 = global_8.member_4[0u];
    let _e1635 = global.member_7[3u];
    let _e1640 = global.member_7;
    let _e1643 = mix((_e1625 + (_e352 * _e1628)), _e1640.xyz, vec3((1f - exp((-(length(_e303)) * _e1635)))));
    global_16 = vec4<f32>(_e1643.x, _e1643.y, _e1643.z, _e371);
    return;
}

@fragment 
fn main(@builtin(position) param: vec4<f32>) -> @location(0) vec4<f32> {
    global_9 = param;
    function_();
    let _e3 = global_16;
    return _e3;
}
