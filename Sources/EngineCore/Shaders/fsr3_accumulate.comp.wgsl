// Generated from fsr3_accumulate.comp by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: d92921cec87a51c5
// glsl-fnv1a64: 87df2372a59d4de8

diagnostic(off, derivative_uniformity);

struct type_11 {
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

@group(3) @binding(0) 
var<uniform> global: type_11;
@group(2) @binding(14) 
var global_1: texture_2d<f32>;
@group(2) @binding(11) 
var global_2: texture_2d<f32>;
@group(2) @binding(32) 
var global_3: texture_storage_2d<rgba16float,write>;
@group(2) @binding(12) 
var global_4: texture_2d<f32>;
@group(2) @binding(17) 
var global_5: sampler;
@group(2) @binding(13) 
var global_6: texture_2d<f32>;
@group(2) @binding(33) 
var global_7: texture_storage_2d<r8unorm,read_write>;
@group(2) @binding(10) 
var global_8: texture_2d<f32>;
@group(2) @binding(9) 
var global_9: texture_2d<f32>;
var<private> global_10: vec3<u32>;

fn function_() {
    var local: array<vec3<f32>, 9>;
    var local_1: array<vec4<f32>, 4>;
    var phi_7467_: vec4<f32>;
    var phi_2596_: bool;
    var phi_2606_: bool;
    var phi_2608_: bool;
    var phi_2445_: bool;
    var phi_2311_: bool;
    var phi_7502_: vec4<f32>;
    var phi_7503_: vec4<f32>;
    var phi_7504_: vec4<f32>;
    var phi_7505_: vec4<f32>;
    var phi_7506_: vec4<f32>;
    var phi_7507_: vec4<f32>;
    var phi_7508_: vec4<f32>;
    var phi_7509_: vec4<f32>;
    var phi_7510_: vec4<f32>;
    var phi_7511_: vec4<f32>;
    var phi_7512_: vec4<f32>;
    var phi_7513_: vec4<f32>;
    var phi_7514_: vec4<f32>;
    var phi_7515_: vec4<f32>;
    var phi_7516_: vec4<f32>;
    var phi_7517_: vec4<f32>;
    var phi_7518_: f32;
    var phi_7519_: f32;
    var phi_7520_: f32;
    var phi_7521_: f32;
    var phi_7522_: f32;
    var phi_7523_: f32;
    var phi_7524_: f32;
    var phi_7525_: f32;
    var phi_7526_: f32;
    var phi_7527_: f32;
    var phi_7528_: f32;
    var phi_7529_: f32;
    var phi_7530_: f32;
    var phi_7531_: f32;
    var phi_7532_: f32;
    var phi_7533_: f32;
    var phi_7534_: f32;
    var phi_7535_: f32;
    var phi_7536_: f32;
    var phi_7537_: f32;
    var phi_7541_: vec4<f32>;
    var phi_7540_: vec4<f32>;
    var phi_7538_: i32;
    var local_2: vec4<f32>;
    var local_3: vec4<f32>;
    var phi_7545_: vec3<f32>;
    var phi_7543_: f32;
    var phi_7553_: f32;
    var phi_5512_: bool;
    var phi_5522_: bool;
    var phi_5524_: bool;
    var phi_7606_: i32;
    var phi_7703_: i32;
    var phi_7702_: i32;
    var phi_7695_: i32;
    var phi_7697_: i32;
    var phi_7699_: i32;
    var phi_7704_: vec4<f32>;
    var phi_7626_: vec3<f32>;
    var phi_7623_: f32;
    var phi_7617_: vec3<f32>;
    var phi_7615_: vec3<f32>;
    var phi_7613_: vec3<f32>;
    var phi_7611_: vec3<f32>;
    var phi_7609_: f32;
    var phi_7608_: i32;
    var phi_7655_: i32;
    var phi_7687_: vec3<f32>;
    var phi_7683_: vec3<f32>;
    var phi_7679_: vec3<f32>;
    var phi_7675_: vec3<f32>;
    var phi_7671_: f32;
    var phi_7661_: f32;
    var phi_7658_: vec3<f32>;
    var phi_7654_: i32;
    var phi_7647_: i32;
    var phi_7649_: i32;
    var phi_7651_: i32;
    var phi_7750_: f32;
    var phi_7748_: vec3<f32>;
    var phi_7692_: vec3<f32>;
    var phi_7691_: vec3<f32>;
    var phi_7690_: vec3<f32>;
    var phi_7689_: vec3<f32>;
    var phi_7688_: f32;
    var local_4: f32;
    var local_5: f32;
    var local_6: vec3<f32>;
    var local_7: vec3<f32>;
    var local_8: f32;
    var local_9: f32;
    var local_10: vec3<f32>;
    var local_11: vec3<f32>;
    var local_12: vec3<f32>;
    var phi_7636_: vec3<f32>;
    var phi_7634_: f32;
    var phi_7646_: vec3<f32>;
    var local_13: i32;
    var local_14: i32;
    var local_15: vec3<f32>;
    var local_16: f32;
    var local_17: vec3<f32>;
    var local_18: vec3<f32>;
    var local_19: vec3<f32>;
    var local_20: vec3<f32>;
    var local_21: f32;
    var local_22: i32;
    var local_23: vec3<f32>;
    var local_24: vec3<f32>;
    var local_25: vec3<f32>;
    var local_26: vec3<f32>;
    var local_27: f32;
    var local_28: f32;
    var local_29: vec3<f32>;
    var local_30: i32;
    var local_31: vec3<f32>;

    let _e86 = global_10;
    let _e87 = _e86.xy;
    let _e88 = bitcast<vec2<i32>>(_e87);
    let _e90 = (vec2<f32>(_e88) + vec2<f32>(0.5f, 0.5f));
    let _e92 = global.member_2;
    let _e94 = (_e90 / vec2<f32>(_e92));
    let _e96 = global.member_5;
    let _e98 = global.member;
    let _e99 = vec2<f32>(_e98);
    let _e101 = (_e94 + (_e96 / _e99));
    let _e103 = (_e99 - vec2<f32>(0.5f, 0.5f));
    let _e107 = (_e94 * _e99);
    let _e108 = vec2<i32>(_e107);
    let _e110 = textureDimensions(global_8, 0i);
    if all((bitcast<vec2<u32>>(_e108) < bitcast<vec2<u32>>(vec2<i32>(_e110)))) {
        let _e115 = textureLoad(global_8, _e108, 0i);
        phi_7467_ = _e115;
    } else {
        phi_7467_ = vec4<f32>(0f, 0f, 0f, 0f);
    }
    let _e117 = phi_7467_;
    let _e118 = _e117.xy;
    let _e120 = length((_e118 * vec2<f32>(3840f, 2160f)));
    let _e121 = (_e94 + _e118);
    let _e123 = (_e121.x >= 0f);
    phi_2596_ = _e123;
    if _e123 {
        phi_2596_ = (_e121.x <= 1f);
    }
    let _e126 = phi_2596_;
    phi_2608_ = _e126;
    if _e126 {
        let _e128 = (_e121.y >= 0f);
        phi_2606_ = _e128;
        if _e128 {
            phi_2606_ = (_e121.y <= 1f);
        }
        let _e131 = phi_2606_;
        phi_2608_ = _e131;
    }
    let _e133 = phi_2608_;
    let _e137 = textureSampleLevel(global_6, global_5, (max(vec2<f32>(0.5f, 0.5f), min(_e107, _e103)) / _e99), 0f);
    let _e140 = textureDimensions(global_4, 0i);
    let _e142 = vec2<f32>((_e98 / vec2<i32>(2i, 2i)));
    let _e149 = textureSampleLevel(global_4, global_5, (max(vec2<f32>(0.5f, 0.5f), min((_e101 * _e142), (_e142 - vec2<f32>(0.5f, 0.5f)))) / vec2<f32>(vec2<i32>(_e140))), 0f);
    phi_2445_ = !(_e133);
    if _e133 {
        let _e153 = global.member_12;
        phi_2445_ = (0f == _e153);
    }
    let _e156 = phi_2445_;
    let _e157 = textureSampleLevel(global_9, global_5, (max(vec2<f32>(0.5f, 0.5f), min((_e101 * _e99), _e103)) / _e99), 0f);
    let _e159 = clamp(_e157.x, 0f, 1f);
    let _e161 = clamp(_e157.y, 0f, 1f);
    let _e163 = clamp(_e157.z, 0f, 1f);
    let _e165 = clamp(_e157.w, 0f, 1f);
    let _e170 = (_e165 * select(0f, 1f, (round((_e165 * 100f)) > 1f)));
    phi_2311_ = _e133;
    if _e133 {
        phi_2311_ = !(_e156);
    }
    let _e173 = phi_2311_;
    phi_7545_ = vec3<f32>(0f, 0f, 0f);
    phi_7543_ = 0f;
    if _e173 {
        let _e175 = global.member_3;
        let _e178 = ((_e121 * vec2<f32>(_e175)) - vec2<f32>(0.5f, 0.5f));
        let _e179 = fract(_e178);
        let _e194 = vec2<i32>(floor(vec2<f32>(max(0f, min(f32((_e175.x - 1i)), _e178.x)), max(0f, min(f32((_e175.y - 1i)), _e178.y)))));
        let _e195 = (_e194 + vec2<i32>(-1i, -1i));
        let _e196 = (_e175.x - 2i);
        let _e200 = (_e175.y - 2i);
        let _e204 = vec2<i32>(max(1i, min(_e195.x, _e196)), max(1i, min(_e195.y, _e200)));
        let _e206 = textureDimensions(global_2, 0i);
        if all((bitcast<vec2<u32>>(_e204) < bitcast<vec2<u32>>(vec2<i32>(_e206)))) {
            let _e211 = textureLoad(global_2, _e204, 0i);
            phi_7502_ = _e211;
        } else {
            phi_7502_ = vec4<f32>(0f, 0f, 0f, 0f);
        }
        let _e213 = phi_7502_;
        let _e214 = (_e194 + vec2<i32>(0i, -1i));
        let _e221 = vec2<i32>(max(1i, min(_e214.x, _e196)), max(1i, min(_e214.y, _e200)));
        let _e223 = textureDimensions(global_2, 0i);
        if all((bitcast<vec2<u32>>(_e221) < bitcast<vec2<u32>>(vec2<i32>(_e223)))) {
            let _e228 = textureLoad(global_2, _e221, 0i);
            phi_7503_ = _e228;
        } else {
            phi_7503_ = vec4<f32>(0f, 0f, 0f, 0f);
        }
        let _e230 = phi_7503_;
        let _e231 = (_e194 + vec2<i32>(1i, -1i));
        let _e238 = vec2<i32>(max(1i, min(_e231.x, _e196)), max(1i, min(_e231.y, _e200)));
        let _e240 = textureDimensions(global_2, 0i);
        if all((bitcast<vec2<u32>>(_e238) < bitcast<vec2<u32>>(vec2<i32>(_e240)))) {
            let _e245 = textureLoad(global_2, _e238, 0i);
            phi_7504_ = _e245;
        } else {
            phi_7504_ = vec4<f32>(0f, 0f, 0f, 0f);
        }
        let _e247 = phi_7504_;
        let _e248 = (_e194 + vec2<i32>(2i, -1i));
        let _e255 = vec2<i32>(max(1i, min(_e248.x, _e196)), max(1i, min(_e248.y, _e200)));
        let _e257 = textureDimensions(global_2, 0i);
        if all((bitcast<vec2<u32>>(_e255) < bitcast<vec2<u32>>(vec2<i32>(_e257)))) {
            let _e262 = textureLoad(global_2, _e255, 0i);
            phi_7505_ = _e262;
        } else {
            phi_7505_ = vec4<f32>(0f, 0f, 0f, 0f);
        }
        let _e264 = phi_7505_;
        let _e265 = (_e194 + vec2<i32>(-1i, 0i));
        let _e272 = vec2<i32>(max(1i, min(_e265.x, _e196)), max(1i, min(_e265.y, _e200)));
        let _e274 = textureDimensions(global_2, 0i);
        if all((bitcast<vec2<u32>>(_e272) < bitcast<vec2<u32>>(vec2<i32>(_e274)))) {
            let _e279 = textureLoad(global_2, _e272, 0i);
            phi_7506_ = _e279;
        } else {
            phi_7506_ = vec4<f32>(0f, 0f, 0f, 0f);
        }
        let _e281 = phi_7506_;
        let _e288 = vec2<i32>(max(1i, min(_e194.x, _e196)), max(1i, min(_e194.y, _e200)));
        let _e290 = textureDimensions(global_2, 0i);
        if all((bitcast<vec2<u32>>(_e288) < bitcast<vec2<u32>>(vec2<i32>(_e290)))) {
            let _e295 = textureLoad(global_2, _e288, 0i);
            phi_7507_ = _e295;
        } else {
            phi_7507_ = vec4<f32>(0f, 0f, 0f, 0f);
        }
        let _e297 = phi_7507_;
        let _e298 = (_e194 + vec2<i32>(1i, 0i));
        let _e305 = vec2<i32>(max(1i, min(_e298.x, _e196)), max(1i, min(_e298.y, _e200)));
        let _e307 = textureDimensions(global_2, 0i);
        if all((bitcast<vec2<u32>>(_e305) < bitcast<vec2<u32>>(vec2<i32>(_e307)))) {
            let _e312 = textureLoad(global_2, _e305, 0i);
            phi_7508_ = _e312;
        } else {
            phi_7508_ = vec4<f32>(0f, 0f, 0f, 0f);
        }
        let _e314 = phi_7508_;
        let _e315 = (_e194 + vec2<i32>(2i, 0i));
        let _e322 = vec2<i32>(max(1i, min(_e315.x, _e196)), max(1i, min(_e315.y, _e200)));
        let _e324 = textureDimensions(global_2, 0i);
        if all((bitcast<vec2<u32>>(_e322) < bitcast<vec2<u32>>(vec2<i32>(_e324)))) {
            let _e329 = textureLoad(global_2, _e322, 0i);
            phi_7509_ = _e329;
        } else {
            phi_7509_ = vec4<f32>(0f, 0f, 0f, 0f);
        }
        let _e331 = phi_7509_;
        let _e332 = (_e194 + vec2<i32>(-1i, 1i));
        let _e339 = vec2<i32>(max(1i, min(_e332.x, _e196)), max(1i, min(_e332.y, _e200)));
        let _e341 = textureDimensions(global_2, 0i);
        if all((bitcast<vec2<u32>>(_e339) < bitcast<vec2<u32>>(vec2<i32>(_e341)))) {
            let _e346 = textureLoad(global_2, _e339, 0i);
            phi_7510_ = _e346;
        } else {
            phi_7510_ = vec4<f32>(0f, 0f, 0f, 0f);
        }
        let _e348 = phi_7510_;
        let _e349 = (_e194 + vec2<i32>(0i, 1i));
        let _e356 = vec2<i32>(max(1i, min(_e349.x, _e196)), max(1i, min(_e349.y, _e200)));
        let _e358 = textureDimensions(global_2, 0i);
        if all((bitcast<vec2<u32>>(_e356) < bitcast<vec2<u32>>(vec2<i32>(_e358)))) {
            let _e363 = textureLoad(global_2, _e356, 0i);
            phi_7511_ = _e363;
        } else {
            phi_7511_ = vec4<f32>(0f, 0f, 0f, 0f);
        }
        let _e365 = phi_7511_;
        let _e366 = (_e194 + vec2<i32>(1i, 1i));
        let _e373 = vec2<i32>(max(1i, min(_e366.x, _e196)), max(1i, min(_e366.y, _e200)));
        let _e375 = textureDimensions(global_2, 0i);
        if all((bitcast<vec2<u32>>(_e373) < bitcast<vec2<u32>>(vec2<i32>(_e375)))) {
            let _e380 = textureLoad(global_2, _e373, 0i);
            phi_7512_ = _e380;
        } else {
            phi_7512_ = vec4<f32>(0f, 0f, 0f, 0f);
        }
        let _e382 = phi_7512_;
        let _e383 = (_e194 + vec2<i32>(2i, 1i));
        let _e390 = vec2<i32>(max(1i, min(_e383.x, _e196)), max(1i, min(_e383.y, _e200)));
        let _e392 = textureDimensions(global_2, 0i);
        if all((bitcast<vec2<u32>>(_e390) < bitcast<vec2<u32>>(vec2<i32>(_e392)))) {
            let _e397 = textureLoad(global_2, _e390, 0i);
            phi_7513_ = _e397;
        } else {
            phi_7513_ = vec4<f32>(0f, 0f, 0f, 0f);
        }
        let _e399 = phi_7513_;
        let _e400 = (_e194 + vec2<i32>(-1i, 2i));
        let _e407 = vec2<i32>(max(1i, min(_e400.x, _e196)), max(1i, min(_e400.y, _e200)));
        let _e409 = textureDimensions(global_2, 0i);
        if all((bitcast<vec2<u32>>(_e407) < bitcast<vec2<u32>>(vec2<i32>(_e409)))) {
            let _e414 = textureLoad(global_2, _e407, 0i);
            phi_7514_ = _e414;
        } else {
            phi_7514_ = vec4<f32>(0f, 0f, 0f, 0f);
        }
        let _e416 = phi_7514_;
        let _e417 = (_e194 + vec2<i32>(0i, 2i));
        let _e424 = vec2<i32>(max(1i, min(_e417.x, _e196)), max(1i, min(_e417.y, _e200)));
        let _e426 = textureDimensions(global_2, 0i);
        if all((bitcast<vec2<u32>>(_e424) < bitcast<vec2<u32>>(vec2<i32>(_e426)))) {
            let _e431 = textureLoad(global_2, _e424, 0i);
            phi_7515_ = _e431;
        } else {
            phi_7515_ = vec4<f32>(0f, 0f, 0f, 0f);
        }
        let _e433 = phi_7515_;
        let _e434 = (_e194 + vec2<i32>(1i, 2i));
        let _e441 = vec2<i32>(max(1i, min(_e434.x, _e196)), max(1i, min(_e434.y, _e200)));
        let _e443 = textureDimensions(global_2, 0i);
        if all((bitcast<vec2<u32>>(_e441) < bitcast<vec2<u32>>(vec2<i32>(_e443)))) {
            let _e448 = textureLoad(global_2, _e441, 0i);
            phi_7516_ = _e448;
        } else {
            phi_7516_ = vec4<f32>(0f, 0f, 0f, 0f);
        }
        let _e450 = phi_7516_;
        let _e451 = (_e194 + vec2<i32>(2i, 2i));
        let _e458 = vec2<i32>(max(1i, min(_e451.x, _e196)), max(1i, min(_e451.y, _e200)));
        let _e460 = textureDimensions(global_2, 0i);
        if all((bitcast<vec2<u32>>(_e458) < bitcast<vec2<u32>>(vec2<i32>(_e460)))) {
            let _e465 = textureLoad(global_2, _e458, 0i);
            phi_7517_ = _e465;
        } else {
            phi_7517_ = vec4<f32>(0f, 0f, 0f, 0f);
        }
        let _e467 = phi_7517_;
        let _e471 = min(abs((-1f - _e179.x)), 2f);
        let _e473 = (abs(_e471) < 0.000061f);
        if _e473 {
            phi_7518_ = 1f;
        } else {
            let _e474 = (3.1415927f * _e471);
            let _e477 = (1.5707964f * _e471);
            phi_7518_ = ((sin(_e474) / _e474) * (sin(_e477) / _e477));
        }
        let _e482 = phi_7518_;
        let _e485 = min(abs(-(_e179.x)), 2f);
        let _e487 = (abs(_e485) < 0.000061f);
        if _e487 {
            phi_7519_ = 1f;
        } else {
            let _e488 = (3.1415927f * _e485);
            let _e491 = (1.5707964f * _e485);
            phi_7519_ = ((sin(_e488) / _e488) * (sin(_e491) / _e491));
        }
        let _e496 = phi_7519_;
        let _e499 = min(abs((1f - _e179.x)), 2f);
        let _e501 = (abs(_e499) < 0.000061f);
        if _e501 {
            phi_7520_ = 1f;
        } else {
            let _e502 = (3.1415927f * _e499);
            let _e505 = (1.5707964f * _e499);
            phi_7520_ = ((sin(_e502) / _e502) * (sin(_e505) / _e505));
        }
        let _e510 = phi_7520_;
        let _e513 = min(abs((2f - _e179.x)), 2f);
        let _e515 = (abs(_e513) < 0.000061f);
        if _e515 {
            phi_7521_ = 1f;
        } else {
            let _e516 = (3.1415927f * _e513);
            let _e519 = (1.5707964f * _e513);
            phi_7521_ = ((sin(_e516) / _e516) * (sin(_e519) / _e519));
        }
        let _e524 = phi_7521_;
        if _e473 {
            phi_7522_ = 1f;
        } else {
            let _e537 = (3.1415927f * _e471);
            let _e540 = (1.5707964f * _e471);
            phi_7522_ = ((sin(_e537) / _e537) * (sin(_e540) / _e540));
        }
        let _e545 = phi_7522_;
        if _e487 {
            phi_7523_ = 1f;
        } else {
            let _e546 = (3.1415927f * _e485);
            let _e549 = (1.5707964f * _e485);
            phi_7523_ = ((sin(_e546) / _e546) * (sin(_e549) / _e549));
        }
        let _e554 = phi_7523_;
        if _e501 {
            phi_7524_ = 1f;
        } else {
            let _e555 = (3.1415927f * _e499);
            let _e558 = (1.5707964f * _e499);
            phi_7524_ = ((sin(_e555) / _e555) * (sin(_e558) / _e558));
        }
        let _e563 = phi_7524_;
        if _e515 {
            phi_7525_ = 1f;
        } else {
            let _e564 = (3.1415927f * _e513);
            let _e567 = (1.5707964f * _e513);
            phi_7525_ = ((sin(_e564) / _e564) * (sin(_e567) / _e567));
        }
        let _e572 = phi_7525_;
        if _e473 {
            phi_7526_ = 1f;
        } else {
            let _e585 = (3.1415927f * _e471);
            let _e588 = (1.5707964f * _e471);
            phi_7526_ = ((sin(_e585) / _e585) * (sin(_e588) / _e588));
        }
        let _e593 = phi_7526_;
        if _e487 {
            phi_7527_ = 1f;
        } else {
            let _e594 = (3.1415927f * _e485);
            let _e597 = (1.5707964f * _e485);
            phi_7527_ = ((sin(_e594) / _e594) * (sin(_e597) / _e597));
        }
        let _e602 = phi_7527_;
        if _e501 {
            phi_7528_ = 1f;
        } else {
            let _e603 = (3.1415927f * _e499);
            let _e606 = (1.5707964f * _e499);
            phi_7528_ = ((sin(_e603) / _e603) * (sin(_e606) / _e606));
        }
        let _e611 = phi_7528_;
        if _e515 {
            phi_7529_ = 1f;
        } else {
            let _e612 = (3.1415927f * _e513);
            let _e615 = (1.5707964f * _e513);
            phi_7529_ = ((sin(_e612) / _e612) * (sin(_e615) / _e615));
        }
        let _e620 = phi_7529_;
        if _e473 {
            phi_7530_ = 1f;
        } else {
            let _e633 = (3.1415927f * _e471);
            let _e636 = (1.5707964f * _e471);
            phi_7530_ = ((sin(_e633) / _e633) * (sin(_e636) / _e636));
        }
        let _e641 = phi_7530_;
        if _e487 {
            phi_7531_ = 1f;
        } else {
            let _e642 = (3.1415927f * _e485);
            let _e645 = (1.5707964f * _e485);
            phi_7531_ = ((sin(_e642) / _e642) * (sin(_e645) / _e645));
        }
        let _e650 = phi_7531_;
        if _e501 {
            phi_7532_ = 1f;
        } else {
            let _e651 = (3.1415927f * _e499);
            let _e654 = (1.5707964f * _e499);
            phi_7532_ = ((sin(_e651) / _e651) * (sin(_e654) / _e654));
        }
        let _e659 = phi_7532_;
        if _e515 {
            phi_7533_ = 1f;
        } else {
            let _e660 = (3.1415927f * _e513);
            let _e663 = (1.5707964f * _e513);
            phi_7533_ = ((sin(_e660) / _e660) * (sin(_e663) / _e663));
        }
        let _e668 = phi_7533_;
        let _e684 = min(abs((-1f - _e179.y)), 2f);
        if (abs(_e684) < 0.000061f) {
            phi_7534_ = 1f;
        } else {
            let _e687 = (3.1415927f * _e684);
            let _e690 = (1.5707964f * _e684);
            phi_7534_ = ((sin(_e687) / _e687) * (sin(_e690) / _e690));
        }
        let _e695 = phi_7534_;
        let _e698 = min(abs(-(_e179.y)), 2f);
        if (abs(_e698) < 0.000061f) {
            phi_7535_ = 1f;
        } else {
            let _e701 = (3.1415927f * _e698);
            let _e704 = (1.5707964f * _e698);
            phi_7535_ = ((sin(_e701) / _e701) * (sin(_e704) / _e704));
        }
        let _e709 = phi_7535_;
        let _e712 = min(abs((1f - _e179.y)), 2f);
        if (abs(_e712) < 0.000061f) {
            phi_7536_ = 1f;
        } else {
            let _e715 = (3.1415927f * _e712);
            let _e718 = (1.5707964f * _e712);
            phi_7536_ = ((sin(_e715) / _e715) * (sin(_e718) / _e718));
        }
        let _e723 = phi_7536_;
        let _e726 = min(abs((2f - _e179.y)), 2f);
        if (abs(_e726) < 0.000061f) {
            phi_7537_ = 1f;
        } else {
            let _e729 = (3.1415927f * _e726);
            let _e732 = (1.5707964f * _e726);
            phi_7537_ = ((sin(_e729) / _e729) * (sin(_e732) / _e732));
        }
        let _e737 = phi_7537_;
        local_1 = array<vec4<f32>, 4>(_e297, _e314, _e365, _e382);
        let _e752 = local_1[0i];
        let _e753 = local_1[0i];
        phi_7541_ = _e753;
        phi_7540_ = _e752;
        phi_7538_ = 1i;
        loop {
            let _e755 = phi_7541_;
            let _e757 = phi_7540_;
            let _e759 = phi_7538_;
            local_2 = _e757;
            local_3 = _e755;
            if (_e759 < 4i) {
                continue;
            } else {
                break;
            }
            continuing {
                let _e762 = local_1[_e759];
                let _e764 = local_1[_e759];
                phi_7541_ = max(_e755, _e764);
                phi_7540_ = min(_e757, _e762);
                phi_7538_ = (_e759 + 1i);
            }
        }
        let _e768 = local_2;
        let _e770 = local_3;
        let _e771 = clamp(((((((((((_e213 * _e482) + (_e230 * _e496)) + (_e247 * _e510)) + (_e264 * _e524)) / vec4((((_e482 + _e496) + _e510) + _e524))) * _e695) + ((((((_e281 * _e545) + (_e297 * _e554)) + (_e314 * _e563)) + (_e331 * _e572)) / vec4((((_e545 + _e554) + _e563) + _e572))) * _e709)) + ((((((_e348 * _e593) + (_e365 * _e602)) + (_e382 * _e611)) + (_e399 * _e620)) / vec4((((_e593 + _e602) + _e611) + _e620))) * _e723)) + ((((((_e416 * _e641) + (_e433 * _e650)) + (_e450 * _e659)) + (_e467 * _e668)) / vec4((((_e641 + _e650) + _e659) + _e668))) * _e737)) / vec4((((_e695 + _e709) + _e723) + _e737))), _e768, _e770);
        let _e774 = global.member_10;
        let _e777 = global.member_18;
        let _e780 = ((_e771.xyz * _e774) * select(_e777, 1f, (_e777 == 0f)));
        let _e784 = (0.5f * _e780.y);
        let _e787 = (0.25f * _e780.z);
        phi_7545_ = vec3<f32>((((0.25f * _e780.x) + _e784) + _e787), (0.5f * (_e780.x - _e780.z)), (((-0.25f * _e780.x) + _e784) - _e787));
        phi_7543_ = _e771.w;
    }
    let _e797 = phi_7545_;
    let _e799 = phi_7543_;
    let _e805 = max(clamp(_e163, 0f, 1f), max(_e159, _e161));
    let _e808 = max(0f, ((_e799 * select(0f, 1f, !(_e156))) - (_e805 * 2f)));
    let _e812 = textureDimensions(global_7);
    if all((_e87 < bitcast<vec2<u32>>(vec2<i32>(_e812)))) {
        let _e817 = textureLoad(global_7, _e88);
        phi_7553_ = _e817.x;
    } else {
        phi_7553_ = 0f;
    }
    let _e820 = phi_7553_;
    let _e828 = global.member_9;
    let _e834 = (_e94 - _e118);
    let _e836 = (_e834.x >= 0f);
    phi_5512_ = _e836;
    if _e836 {
        phi_5512_ = (_e834.x <= 1f);
    }
    let _e839 = phi_5512_;
    phi_5524_ = _e839;
    if _e839 {
        let _e841 = (_e834.y >= 0f);
        phi_5522_ = _e841;
        if _e841 {
            phi_5522_ = (_e834.y <= 1f);
        }
        let _e844 = phi_5522_;
        phi_5524_ = _e844;
    }
    let _e846 = phi_5524_;
    let _e850 = global.member_13;
    let _e856 = min(_e170, mix(_e170, 0.15f, clamp(max(0f, ((_e120 * _e850) * 2f)), 0f, 1f)));
    let _e858 = global.member_7;
    let _e859 = (_e90 * _e858);
    let _e861 = vec2<i32>(floor(_e859));
    let _e864 = ((vec2<f32>(_e861) + vec2<f32>(0.5f, 0.5f)) - _e96);
    let _e868 = (_e864.x > _e859.x);
    let _e872 = (_e864.y > _e859.y);
    let _e874 = vec2<i32>(select(-1i, -2i, _e868), select(-1i, -2i, _e872));
    let _e876 = (_e170 == 0f);
    phi_7606_ = 0i;
    phi_7703_ = 0i;
    loop {
        let _e878 = phi_7606_;
        let _e880 = phi_7703_;
        if (_e878 < 3i) {
            phi_7702_ = _e880;
            phi_7695_ = 0i;
            loop {
                let _e883 = phi_7702_;
                let _e885 = phi_7695_;
                local_13 = _e883;
                if (_e885 < 3i) {
                    if _e868 {
                        phi_7697_ = (3i - _e885);
                    } else {
                        phi_7697_ = _e885;
                    }
                    let _e889 = phi_7697_;
                    if _e872 {
                        phi_7699_ = (3i - _e878);
                    } else {
                        phi_7699_ = _e878;
                    }
                    let _e892 = phi_7699_;
                    let _e895 = ((_e861 + _e874) + vec2<i32>(_e889, _e892));
                    let _e906 = vec2<i32>(max(0i, min(_e895.x, (_e98.x - 1i))), max(0i, min(_e895.y, (_e98.y - 1i))));
                    let _e908 = textureDimensions(global_1, 0i);
                    if all((bitcast<vec2<u32>>(_e906) < bitcast<vec2<u32>>(vec2<i32>(_e908)))) {
                        let _e913 = textureLoad(global_1, _e906, 0i);
                        phi_7704_ = _e913;
                    } else {
                        phi_7704_ = vec4<f32>(0f, 0f, 0f, 0f);
                    }
                    let _e915 = phi_7704_;
                    let _e919 = global.member_18;
                    let _e922 = (max(vec3<f32>(0f, 0f, 0f), _e915.xyz) * select(_e919, 1f, (_e919 == 0f)));
                    let _e926 = (0.5f * _e922.y);
                    let _e929 = (0.25f * _e922.z);
                    local[_e883] = vec3<f32>((((0.25f * _e922.x) + _e926) + _e929), (0.5f * (_e922.x - _e922.z)), (((-0.25f * _e922.x) + _e926) - _e929));
                    local_14 = (_e883 + 1i);
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e1240 = local_14;
                    phi_7702_ = _e1240;
                    phi_7695_ = (_e885 + 1i);
                }
            }
            continue;
        } else {
            break;
        }
        continuing {
            phi_7606_ = (_e878 + 1i);
            let _e1237 = local_13;
            phi_7703_ = _e1237;
        }
    }
    let _e945 = min(1.99f, (1f + ((vec2<f32>(1f, 1f) / _e858) - vec2<f32>(1f, 1f)).x));
    phi_7626_ = vec3<f32>(0f, 0f, 0f);
    phi_7623_ = 0f;
    phi_7617_ = vec3<f32>();
    phi_7615_ = vec3<f32>();
    phi_7613_ = vec3<f32>();
    phi_7611_ = vec3<f32>();
    phi_7609_ = f32();
    phi_7608_ = 0i;
    phi_7655_ = 0i;
    loop {
        let _e958 = phi_7626_;
        let _e960 = phi_7623_;
        let _e962 = phi_7617_;
        let _e964 = phi_7615_;
        let _e966 = phi_7613_;
        let _e968 = phi_7611_;
        let _e970 = phi_7609_;
        let _e972 = phi_7608_;
        let _e974 = phi_7655_;
        local_4 = _e970;
        local_5 = _e970;
        local_6 = _e962;
        local_7 = _e964;
        local_8 = _e960;
        local_9 = _e960;
        local_10 = _e958;
        local_11 = _e966;
        local_12 = _e968;
        local_31 = _e958;
        if (_e972 < 3i) {
            phi_7687_ = _e962;
            phi_7683_ = _e964;
            phi_7679_ = _e966;
            phi_7675_ = _e968;
            phi_7671_ = _e970;
            phi_7661_ = _e960;
            phi_7658_ = _e958;
            phi_7654_ = _e974;
            phi_7647_ = 0i;
            loop {
                let _e977 = phi_7687_;
                let _e979 = phi_7683_;
                let _e981 = phi_7679_;
                let _e983 = phi_7675_;
                let _e985 = phi_7671_;
                let _e987 = phi_7661_;
                let _e989 = phi_7658_;
                let _e991 = phi_7654_;
                let _e993 = phi_7647_;
                local_15 = _e989;
                local_16 = _e987;
                local_17 = _e977;
                local_18 = _e979;
                local_19 = _e981;
                local_20 = _e983;
                local_21 = _e985;
                local_22 = _e991;
                if (_e993 < 3i) {
                    if _e868 {
                        phi_7649_ = (3i - _e993);
                    } else {
                        phi_7649_ = _e993;
                    }
                    let _e997 = phi_7649_;
                    if _e872 {
                        phi_7651_ = (3i - _e972);
                    } else {
                        phi_7651_ = _e972;
                    }
                    let _e1000 = phi_7651_;
                    let _e1001 = vec2<i32>(_e997, _e1000);
                    let _e1004 = ((_e864 - _e859) + (vec2<f32>(_e874) + vec2<f32>(_e1001)));
                    let _e1011 = select(0f, 1f, all((bitcast<vec2<u32>>(((_e861 + _e874) + _e1001)) < bitcast<vec2<u32>>(_e98))));
                    phi_7750_ = _e987;
                    phi_7748_ = _e989;
                    if !(_e876) {
                        let _e1014 = (_e1004 * vec2(mix(max(1f, ((1f + _e945) * 0.3f)), _e945, min((1f - (_e161 * 0.5f)), min((1f - _e163), clamp((_e856 * 5f), 0f, 1f))))));
                        let _e1016 = min(dot(_e1014, _e1014), 4f);
                        let _e1018 = ((0.4f * _e1016) - 1f);
                        let _e1020 = ((0.25f * _e1016) - 1f);
                        let _e1026 = (_e1011 * ((((1.5625f * _e1018) * _e1018) - 0.5625f) * (_e1020 * _e1020)));
                        let _e1028 = local[_e991];
                        phi_7750_ = (_e987 + _e1026);
                        phi_7748_ = (_e989 + (_e1028 * _e1026));
                    }
                    let _e1033 = phi_7750_;
                    let _e1035 = phi_7748_;
                    let _e1039 = (exp((-2.3f * dot(_e1004, _e1004))) * _e1011);
                    let _e1044 = local[_e991];
                    local_28 = _e1033;
                    local_29 = _e1035;
                    if ((_e972 == 0i) && (_e993 == 0i)) {
                        let _e1045 = (_e1044 * _e1039);
                        phi_7692_ = _e1045;
                        phi_7691_ = (_e1044 * _e1045);
                        phi_7690_ = _e1044;
                        phi_7689_ = _e1044;
                        phi_7688_ = _e1039;
                    } else {
                        let _e1049 = (_e1044 * _e1039);
                        phi_7692_ = (_e977 + _e1049);
                        phi_7691_ = (_e979 + (_e1044 * _e1049));
                        phi_7690_ = min(_e981, _e1044);
                        phi_7689_ = max(_e983, _e1044);
                        phi_7688_ = (_e985 + _e1039);
                    }
                    let _e1055 = phi_7692_;
                    let _e1057 = phi_7691_;
                    let _e1059 = phi_7690_;
                    let _e1061 = phi_7689_;
                    let _e1063 = phi_7688_;
                    local_23 = _e1055;
                    local_24 = _e1057;
                    local_25 = _e1059;
                    local_26 = _e1061;
                    local_27 = _e1063;
                    local_30 = (_e991 + 1i);
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e1272 = local_23;
                    phi_7687_ = _e1272;
                    let _e1275 = local_24;
                    phi_7683_ = _e1275;
                    let _e1278 = local_25;
                    phi_7679_ = _e1278;
                    let _e1281 = local_26;
                    phi_7675_ = _e1281;
                    let _e1284 = local_27;
                    phi_7671_ = _e1284;
                    let _e1287 = local_28;
                    phi_7661_ = _e1287;
                    let _e1290 = local_29;
                    phi_7658_ = _e1290;
                    let _e1293 = local_30;
                    phi_7654_ = _e1293;
                    phi_7647_ = (_e993 + 1i);
                }
            }
            continue;
        } else {
            break;
        }
        continuing {
            let _e1247 = local_15;
            phi_7626_ = _e1247;
            let _e1250 = local_16;
            phi_7623_ = _e1250;
            let _e1253 = local_17;
            phi_7617_ = _e1253;
            let _e1256 = local_18;
            phi_7615_ = _e1256;
            let _e1259 = local_19;
            phi_7613_ = _e1259;
            let _e1262 = local_20;
            phi_7611_ = _e1262;
            let _e1265 = local_21;
            phi_7609_ = _e1265;
            phi_7608_ = (_e972 + 1i);
            let _e1269 = local_22;
            phi_7655_ = _e1269;
        }
    }
    let _e1068 = local_4;
    let _e1072 = local_5;
    let _e1074 = vec3(select(1f, _e1072, (abs(_e1068) > 0.000000000000000000000000000000000000011754944f)));
    let _e1076 = local_6;
    let _e1077 = (_e1076 / _e1074);
    let _e1079 = local_7;
    let _e1086 = local_8;
    let _e1090 = local_9;
    let _e1091 = (_e1090 * select(0f, 1f, (_e1086 > 0.000061f)));
    let _e1315 = local_31;
    phi_7636_ = _e1315;
    phi_7634_ = _e1091;
    if (_e1091 > 0.000061f) {
        let _e1095 = local_10;
        let _e1099 = local_11;
        let _e1101 = local_12;
        phi_7636_ = clamp((_e1095 / vec3(_e1091)), _e1099, _e1101);
        phi_7634_ = (_e1091 * 0.04625f);
    }
    let _e1104 = phi_7636_;
    let _e1106 = phi_7634_;
    let _e1109 = select(_e1106, 1f, _e876);
    let _e1110 = select(_e856, 0f, _e876);
    let _e1124 = ((sqrt(abs(((_e1079 / _e1074) - (_e1077 * _e1077)))) * vec3<f32>(1.7f, 1f, 1f)) * mix(3f, 1f, max(clamp((_e120 * 0.05f), 0f, 1f), max(clamp((0.75f - (_e149.x * 0.05f)), 0f, 1f), max((1f - _e170), max(pow(_e159, 0.5f), _e163))))));
    let _e1127 = ((_e797 - _e1077) / max(_e1124, vec3<f32>(0.0000001193f, 0.0000001193f, 0.0000001193f)));
    phi_7646_ = _e797;
    if (length(_e1127) > 1f) {
        phi_7646_ = mix(((normalize(_e1127) * _e1124) + _e1077), _e797, vec3(clamp(((max(_e137.x, clamp(clamp((_e808 - 1f), 0f, 1f), 0f, 1f)) * _e170) * (1f - _e161)), 0f, 1f)));
    }
    let _e1141 = phi_7646_;
    let _e1150 = mix(_e1141, select(_e1104, _e1077, vec3(_e876)), vec3(clamp((_e1109 / max(0.000061f, ((_e1110 * select(0f, 1f, (_e1110 > 0.000061f))) + _e1109))), 0f, 1f)));
    let _e1161 = global.member_18;
    let _e1166 = max((vec3<f32>(((_e1150.x + _e1150.y) - _e1150.z), (_e1150.x + _e1150.z), ((_e1150.x - _e1150.y) - _e1150.z)) / vec3(select(_e1161, 1f, (_e1161 == 0f)))), vec3<f32>(0f, 0f, 0f));
    let _e1171 = textureDimensions(global_3);
    if all((_e87 < bitcast<vec2<u32>>(vec2<i32>(_e1171)))) {
        textureStore(global_3, _e88, vec4<f32>(_e1166.x, _e1166.y, _e1166.z, (max(0f, (max(0f, min((_e808 + (_e820 * (1f - max(0f, _e159)))), 2f)) - ((0.1f / _e828) * (1f - _e805)))) * select(0f, 1f, _e846))));
    }
    let _e1176 = textureDimensions(global_7);
    if all((_e87 < bitcast<vec2<u32>>(vec2<i32>(_e1176)))) {
        textureStore(global_7, _e88, vec4<f32>(0f, 0f, 0f, 0f));
    }
    return;
}

@compute @workgroup_size(8, 8, 1) 
fn main(@builtin(global_invocation_id) param: vec3<u32>) {
    global_10 = param;
    function_();
}
