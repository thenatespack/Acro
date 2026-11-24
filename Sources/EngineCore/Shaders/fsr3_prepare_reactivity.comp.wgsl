// Generated from fsr3_prepare_reactivity.comp by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: ce06e82bb01a330f
// glsl-fnv1a64: 39e6ca7415491ad3

diagnostic(off, derivative_uniformity);

struct type_12 {
    member: vec2<i32>,
    member_1: vec2<i32>,
    member_2: vec2<i32>,
    member_3: vec2<i32>,
    member_4: vec4<f32>,
    member_5: vec2<f32>,
    member_6: vec2<f32>,
    member_7: vec2<f32>,
    member_8: f32,
    member_9: f32,
    member_10: f32,
    member_11: f32,
    member_12: f32,
    member_13: f32,
    member_14: f32,
    member_15: f32,
    member_16: f32,
    member_17: f32,
    member_18: f32,
    member_19: vec2<u32>,
}

struct type_24 {
    member: array<u32>,
}

@group(3) @binding(0) 
var<uniform> global: type_12;
@group(2) @binding(11) 
var global_1: texture_2d<f32>;
@group(2) @binding(12) 
var global_2: texture_2d<f32>;
@group(2) @binding(17) 
var global_3: sampler;
@group(2) @binding(34) 
var global_4: texture_storage_2d<r8unorm,write>;
@group(2) @binding(13) 
var global_5: texture_2d<f32>;
@group(2) @binding(14) 
var global_6: texture_2d<f32>;
@group(2) @binding(33) 
var global_7: texture_storage_2d<r8unorm,write>;
@group(2) @binding(24) 
var<storage, read_write> global_8: type_24;
@group(2) @binding(9) 
var global_9: texture_2d<f32>;
@group(2) @binding(10) 
var global_10: texture_2d<f32>;
@group(2) @binding(32) 
var global_11: texture_storage_2d<rgba8unorm,write>;
var<private> global_12: vec3<u32>;

fn function_() {
    var local: array<f32, 4>;
    var local_1: array<vec2<i32>, 4>;
    var local_2: array<vec2<i32>, 9>;
    var local_3: array<f32, 9>;
    var local_4: array<u32, 4>;
    var local_5: array<u32, 4>;
    var phi_3073_: vec4<f32>;
    var phi_3074_: vec4<f32>;
    var phi_3078_: f32;
    var phi_3077_: f32;
    var phi_3076_: bool;
    var phi_3075_: i32;
    var phi_3161_: f32;
    var phi_3177_: f32;
    var phi_3174_: f32;
    var phi_3176_: f32;
    var phi_3173_: f32;
    var phi_3170_: bool;
    var phi_3175_: f32;
    var phi_3172_: f32;
    var phi_3169_: bool;
    var local_6: f32;
    var local_7: bool;
    var local_8: f32;
    var local_9: f32;
    var phi_3079_: f32;
    var phi_3081_: f32;
    var phi_3080_: i32;
    var phi_3159_: f32;
    var phi_3155_: i32;
    var phi_3157_: vec4<f32>;
    var local_10: f32;
    var phi_3082_: vec4<f32>;
    var phi_3083_: vec4<f32>;
    var phi_3084_: f32;
    var phi_2549_: bool;
    var phi_2559_: bool;
    var phi_2561_: bool;
    var phi_3085_: f32;
    var phi_3126_: f32;
    var phi_3121_: f32;
    var phi_3104_: i32;
    var phi_3151_: vec4<f32>;
    var phi_3148_: i32;
    var phi_3111_: u32;
    var phi_3107_: f32;
    var phi_3106_: f32;
    var phi_3105_: i32;
    var local_11: f32;
    var local_12: f32;
    var phi_3186_: u32;
    var phi_3185_: f32;
    var phi_3184_: f32;
    var local_13: f32;
    var local_14: f32;
    var phi_2788_: bool;
    var phi_3108_: i32;
    var local_15: u32;
    var phi_3128_: f32;
    var phi_3112_: bool;
    var local_16: f32;
    var local_17: f32;
    var phi_3127_: f32;
    var local_18: f32;
    var local_19: f32;
    var local_20: bool;
    var local_21: f32;
    var local_22: f32;
    var local_23: f32;
    var local_24: f32;
    var local_25: u32;
    var local_26: f32;
    var local_27: f32;

    let _e76 = global_12;
    let _e77 = _e76.xy;
    let _e78 = bitcast<vec2<i32>>(_e77);
    let _e80 = (vec2<f32>(_e78) + vec2<f32>(0.5f, 0.5f));
    let _e82 = global.member;
    let _e83 = vec2<f32>(_e82);
    let _e84 = (_e80 / _e83);
    let _e85 = textureDimensions(global_9, 0i);
    if all((_e77 < bitcast<vec2<u32>>(vec2<i32>(_e85)))) {
        let _e90 = textureLoad(global_9, _e78, 0i);
        phi_3073_ = _e90;
    } else {
        phi_3073_ = vec4<f32>(0f, 0f, 0f, 0f);
    }
    let _e92 = phi_3073_;
    let _e93 = _e92.xy;
    let _e94 = textureDimensions(global_10, 0i);
    if all((_e77 < bitcast<vec2<u32>>(vec2<i32>(_e94)))) {
        let _e99 = textureLoad(global_10, _e78, 0i);
        phi_3074_ = _e99;
    } else {
        phi_3074_ = vec4<f32>(0f, 0f, 0f, 0f);
    }
    let _e101 = phi_3074_;
    let _e104 = global.member_4;
    let _e108 = (_e104.y / (_e101.x - _e104.x));
    let _e110 = global.member_11;
    let _e111 = (_e108 * _e110);
    let _e117 = length((_e93 * vec2<f32>(3840f, 2160f)));
    let _e123 = (((_e84 + (_e93 * select(0f, 1f, (_e117 > mix(0.25f, 0.75f, clamp((min(_e111, 65504f) * 0.01f), 0f, 1f)))))) * _e83) - vec2<f32>(0.5f, 0.5f));
    let _e126 = fract(_e123);
    let _e128 = (1f - _e126.x);
    let _e130 = (1f - _e126.y);
    local_1 = array<vec2<i32>, 4>(vec2<i32>(0i, 0i), vec2<i32>(1i, 0i), vec2<i32>(0i, 1i), vec2<i32>(1i, 1i));
    local = array<f32, 4>((_e128 * _e130), (_e126.x * _e130), (_e128 * _e126.y), (_e126.x * _e126.y));
    phi_3078_ = 0f;
    phi_3077_ = 0f;
    phi_3076_ = true;
    phi_3075_ = 0i;
    loop {
        let _e137 = phi_3078_;
        let _e139 = phi_3077_;
        let _e141 = phi_3076_;
        let _e143 = phi_3075_;
        local_6 = _e139;
        local_7 = _e141;
        local_8 = _e137;
        local_9 = _e139;
        if ((_e143 < 4i) && _e141) {
            let _e147 = local_1[_e143];
            let _e148 = (vec2<i32>(floor(_e123)) + _e147);
            let _e153 = max(0i, min(_e148.x, (_e82.x - 1i)));
            let _e158 = max(0i, min(_e148.y, (_e82.y - 1i)));
            let _e163 = all((bitcast<vec2<u32>>(vec2<i32>(_e153, _e158)) < bitcast<vec2<u32>>(_e82)));
            phi_3175_ = _e137;
            phi_3172_ = _e139;
            phi_3169_ = _e141;
            if _e163 {
                let _e165 = local[_e143];
                phi_3176_ = _e137;
                phi_3173_ = _e139;
                phi_3170_ = _e141;
                if (_e165 > 0.00061f) {
                    if _e163 {
                        let _e172 = global_8.member[bitcast<u32>(((_e158 * _e82.x) + _e153))];
                        phi_3161_ = bitcast<f32>(_e172);
                    } else {
                        phi_3161_ = 0f;
                    }
                    let _e175 = phi_3161_;
                    let _e177 = (_e104.y / (_e175 - _e104.x));
                    let _e178 = (_e108 - _e177);
                    let _e180 = (_e141 && (_e178 > 0.000000000000000000000000000000000000011754944f));
                    phi_3177_ = _e137;
                    phi_3174_ = _e139;
                    if _e180 {
                        phi_3177_ = (_e137 + (clamp((((0.0000137f * length((_e83 * 0.5f))) * max(_e108, _e177)) / _e178), 0f, 1f) * _e165));
                        phi_3174_ = (_e139 + _e165);
                    }
                    let _e192 = phi_3177_;
                    let _e194 = phi_3174_;
                    phi_3176_ = _e192;
                    phi_3173_ = _e194;
                    phi_3170_ = _e180;
                }
                let _e196 = phi_3176_;
                let _e198 = phi_3173_;
                let _e200 = phi_3170_;
                phi_3175_ = _e196;
                phi_3172_ = _e198;
                phi_3169_ = _e200;
            }
            let _e202 = phi_3175_;
            let _e204 = phi_3172_;
            let _e206 = phi_3169_;
            local_18 = _e202;
            local_19 = _e204;
            local_20 = _e206;
            continue;
        } else {
            break;
        }
        continuing {
            let _e515 = local_18;
            phi_3078_ = _e515;
            let _e518 = local_19;
            phi_3077_ = _e518;
            let _e521 = local_20;
            phi_3076_ = _e521;
            phi_3075_ = (_e143 + 1i);
        }
    }
    let _e209 = local_6;
    let _e212 = local_7;
    if (_e212 && (_e209 > 0f)) {
        let _e215 = local_8;
        let _e217 = local_9;
        phi_3079_ = clamp((1f - (_e215 / _e217)), 0f, 1f);
    } else {
        phi_3079_ = 0f;
    }
    let _e222 = phi_3079_;
    phi_3081_ = 0f;
    phi_3080_ = -1i;
    loop {
        let _e224 = phi_3081_;
        let _e226 = phi_3080_;
        local_10 = _e224;
        if (_e226 <= 1i) {
            phi_3159_ = _e224;
            phi_3155_ = -1i;
            loop {
                let _e229 = phi_3159_;
                let _e231 = phi_3155_;
                local_21 = _e229;
                if (_e231 <= 1i) {
                    let _e234 = (_e78 + vec2<i32>(_e231, _e226));
                    let _e245 = vec2<i32>(max(0i, min(_e234.x, (_e82.x - 1i))), max(0i, min(_e234.y, (_e82.y - 1i))));
                    let _e247 = textureDimensions(global_1, 0i);
                    if all((bitcast<vec2<u32>>(_e245) < bitcast<vec2<u32>>(vec2<i32>(_e247)))) {
                        let _e252 = textureLoad(global_1, _e245, 0i);
                        phi_3157_ = _e252;
                    } else {
                        phi_3157_ = vec4<f32>(0f, 0f, 0f, 0f);
                    }
                    let _e254 = phi_3157_;
                    let _e257 = global.member_14;
                    local_22 = max(_e229, (_e254.x * _e257));
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e543 = local_22;
                    phi_3159_ = _e543;
                    phi_3155_ = (_e231 + 1i);
                }
            }
            continue;
        } else {
            break;
        }
        continuing {
            let _e539 = local_21;
            phi_3081_ = _e539;
            phi_3080_ = (_e226 + 1i);
        }
    }
    let _e263 = global.member_5;
    let _e268 = vec2<f32>(vec2<i32>((_e83 * 0.5f)));
    let _e274 = textureSampleLevel(global_5, global_3, (max(vec2<f32>(0.5f, 0.5f), min(((_e84 - (_e263 / _e83)) * _e268), (_e268 - vec2<f32>(0.5f, 0.5f)))) / _e268), 0f);
    let _e277 = global.member_15;
    let _e281 = local_10;
    let _e282 = max(_e281, clamp((_e274.x * _e277), 0f, 1f));
    let _e283 = (_e84 + _e93);
    let _e285 = vec2<i32>((_e283 * _e83));
    let _e286 = bitcast<vec2<u32>>(_e285);
    let _e287 = textureDimensions(global_10, 0i);
    if all((_e286 < bitcast<vec2<u32>>(vec2<i32>(_e287)))) {
        let _e292 = textureLoad(global_10, _e285, 0i);
        phi_3082_ = _e292;
    } else {
        phi_3082_ = vec4<f32>(0f, 0f, 0f, 0f);
    }
    let _e294 = phi_3082_;
    let _e296 = textureDimensions(global_9, 0i);
    if all((_e286 < bitcast<vec2<u32>>(vec2<i32>(_e296)))) {
        let _e301 = textureLoad(global_9, _e285, 0i);
        phi_3083_ = _e301;
    } else {
        phi_3083_ = vec4<f32>(0f, 0f, 0f, 0f);
    }
    let _e303 = phi_3083_;
    let _e309 = ((_e104.y / (_e294.x - _e104.x)) * _e110);
    let _e310 = max(_e309, _e111);
    if (_e310 != 0f) {
        phi_3084_ = (min(_e309, _e111) / _e310);
    } else {
        phi_3084_ = 0f;
    }
    let _e315 = phi_3084_;
    let _e325 = (_e283.x >= 0f);
    phi_2549_ = _e325;
    if _e325 {
        phi_2549_ = (_e283.x <= 1f);
    }
    let _e328 = phi_2549_;
    phi_2561_ = _e328;
    if _e328 {
        let _e330 = (_e283.y >= 0f);
        phi_2559_ = _e330;
        if _e330 {
            phi_2559_ = (_e283.y <= 1f);
        }
        let _e333 = phi_2559_;
        phi_2561_ = _e333;
    }
    let _e335 = phi_2561_;
    phi_3085_ = 0f;
    if _e335 {
        let _e337 = global.member_1;
        let _e338 = vec2<f32>(_e337);
        let _e344 = textureSampleLevel(global_2, global_3, (max(vec2<f32>(0.5f, 0.5f), min((_e283 * _e338), (_e338 - vec2<f32>(0.5f, 0.5f)))) / _e83), 0f);
        phi_3085_ = clamp(_e344.x, 0f, 1f);
    }
    let _e348 = phi_3085_;
    let _e350 = global.member_16;
    let _e351 = mix(_e348, 0f, _e282);
    let _e353 = global.member_17;
    let _e355 = mix(_e351, min(_e353, _e351), _e222);
    let _e360 = (_e355 * select(0f, 1f, (round((_e355 * 100f)) > 1f)));
    let _e363 = textureDimensions(global_4);
    if all((_e77 < bitcast<vec2<u32>>(vec2<i32>(_e363)))) {
        textureStore(global_4, _e78, vec4<f32>(clamp((_e360 + _e350), 0f, 1f), 0f, 0f, 0f));
    }
    let _e370 = textureDimensions(global_11);
    if all((_e77 < bitcast<vec2<u32>>(vec2<i32>(_e370)))) {
        textureStore(global_11, _e78, vec4<f32>(max((((1f - clamp((length((_e303.xy * vec2<f32>(3840f, 2160f))) / _e117), 0f, 1f)) * _e315) * clamp((_e117 * 0.1f), 0f, 1f)), 0f), _e222, _e282, _e360));
    }
    switch bitcast<i32>(0u) {
        default: {
            phi_3126_ = 0.000000000000000000000000000000000000011754944f;
            phi_3121_ = 0x1.fffffep+127f;
            phi_3104_ = 0i;
            loop {
                let _e377 = phi_3126_;
                let _e379 = phi_3121_;
                let _e381 = phi_3104_;
                local_11 = _e377;
                local_12 = _e379;
                local_16 = _e379;
                local_17 = _e377;
                if (_e381 < 9i) {
                    local_2 = array<vec2<i32>, 9>(vec2<i32>(0i, 0i), vec2<i32>(-1i, -1i), vec2<i32>(0i, -1i), vec2<i32>(1i, -1i), vec2<i32>(-1i, 0i), vec2<i32>(1i, 0i), vec2<i32>(-1i, 1i), vec2<i32>(0i, 1i), vec2<i32>(1i, 1i));
                    let _e384 = local_2[_e381];
                    let _e385 = (_e78 + _e384);
                    let _e396 = vec2<i32>(max(0i, min(_e385.x, (_e82.x - 1i))), max(0i, min(_e385.y, (_e82.y - 1i))));
                    let _e398 = textureDimensions(global_6, 0i);
                    if all((bitcast<vec2<u32>>(_e396) < bitcast<vec2<u32>>(vec2<i32>(_e398)))) {
                        let _e403 = textureLoad(global_6, _e396, 0i);
                        phi_3151_ = _e403;
                    } else {
                        phi_3151_ = vec4<f32>(0f, 0f, 0f, 0f);
                    }
                    let _e405 = phi_3151_;
                    let _e408 = global.member_18;
                    local_3[_e381] = (_e405.x * select(_e408, 1f, (_e408 == 0f)));
                    let _e413 = local_3[_e381];
                    let _e415 = local_3[_e381];
                    local_23 = max(_e377, _e415);
                    local_24 = min(_e379, _e413);
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e556 = local_23;
                    phi_3126_ = _e556;
                    let _e559 = local_24;
                    phi_3121_ = _e559;
                    phi_3104_ = (_e381 + 1i);
                }
            }
            phi_3148_ = 1i;
            phi_3111_ = 1u;
            phi_3107_ = 0x1.fffffep+127f;
            phi_3106_ = 0f;
            phi_3105_ = 1i;
            loop {
                let _e419 = phi_3148_;
                let _e421 = phi_3111_;
                let _e423 = phi_3107_;
                let _e425 = phi_3106_;
                let _e427 = phi_3105_;
                local_13 = _e425;
                local_14 = _e423;
                local_15 = _e421;
                if (_e427 < 9i) {
                    let _e430 = local_3[_e427];
                    let _e432 = local_3[0i];
                    let _e436 = local_11;
                    let _e438 = local_12;
                    if ((abs((_e430 - _e432)) / (_e436 - _e438)) < 0.9f) {
                        phi_3186_ = (_e421 | (1u << bitcast<u32>(_e419)));
                        phi_3185_ = _e423;
                        phi_3184_ = _e425;
                    } else {
                        let _e445 = local_3[_e427];
                        let _e447 = local_3[_e427];
                        phi_3186_ = _e421;
                        phi_3185_ = min(_e423, _e445);
                        phi_3184_ = max(_e425, _e447);
                    }
                    let _e450 = phi_3186_;
                    let _e452 = phi_3185_;
                    let _e454 = phi_3184_;
                    local_25 = _e450;
                    local_26 = _e452;
                    local_27 = _e454;
                    continue;
                } else {
                    break;
                }
                continuing {
                    phi_3148_ = (_e419 + 1i);
                    let _e565 = local_25;
                    phi_3111_ = _e565;
                    let _e568 = local_26;
                    phi_3107_ = _e568;
                    let _e571 = local_27;
                    phi_3106_ = _e571;
                    phi_3105_ = (_e427 + 1i);
                }
            }
            let _e458 = local_3[0i];
            let _e460 = local_13;
            let _e461 = (_e458 > _e460);
            phi_2788_ = _e461;
            if !(_e461) {
                let _e463 = local_3[0i];
                let _e465 = local_14;
                phi_2788_ = (_e463 < _e465);
            }
            let _e468 = phi_2788_;
            if !(_e468) {
                phi_3127_ = 0f;
                break;
            }
            phi_3108_ = 0i;
            loop {
                let _e471 = phi_3108_;
                phi_3128_ = f32();
                phi_3112_ = false;
                if (bitcast<u32>(_e471) < 4u) {
                    local_4 = array<u32, 4>(23u, 45u, 209u, 417u);
                    let _e475 = local_4[_e471];
                    let _e477 = local_15;
                    local_5 = array<u32, 4>(23u, 45u, 209u, 417u);
                    let _e480 = local_5[_e471];
                    if ((_e477 & _e475) == _e480) {
                        phi_3128_ = 0f;
                        phi_3112_ = true;
                        break;
                    }
                    continue;
                } else {
                    break;
                }
                continuing {
                    phi_3108_ = (_e471 + 1i);
                }
            }
            let _e484 = phi_3128_;
            let _e486 = phi_3112_;
            phi_3127_ = _e484;
            if _e486 {
                break;
            }
            let _e488 = local_16;
            let _e490 = local_17;
            phi_3127_ = (1f - (_e488 / _e490));
            break;
        }
    }
    let _e494 = phi_3127_;
    if (_e494 > 0.01f) {
        let _e499 = global.member_2;
        let _e503 = vec2<i32>(floor((((_e80 - _e263) / _e83) * vec2<f32>(_e499))));
        let _e505 = textureDimensions(global_7);
        if all((bitcast<vec2<u32>>(_e503) < bitcast<vec2<u32>>(vec2<i32>(_e505)))) {
            textureStore(global_7, _e503, vec4<f32>(_e494, 0f, 0f, 0f));
        }
    }
    return;
}

@compute @workgroup_size(8, 8, 1) 
fn main(@builtin(global_invocation_id) param: vec3<u32>) {
    global_12 = param;
    function_();
}
