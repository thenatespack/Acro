// Generated from fsr3_luma_pyramid.comp by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: 5580087f5b2989dc
// glsl-fnv1a64: ec70f5918fe39a9f

diagnostic(off, derivative_uniformity);

struct type_10 {
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
var<uniform> global: type_10;
@group(2) @binding(10) 
var global_1: texture_2d<f32>;
@group(2) @binding(32) 
var global_2: texture_storage_2d<r16float,write>;
@group(2) @binding(9) 
var global_3: texture_2d<f32>;
var<workgroup> global_4: u32;
var<workgroup> global_5: array<array<f32, 16>, 16>;
var<workgroup> global_6: array<array<f32, 16>, 16>;
var<workgroup> global_7: array<array<f32, 16>, 16>;
var<workgroup> global_8: array<array<f32, 16>, 16>;
var<private> global_9: vec3<u32>;
var<private> global_10: u32;

fn function_() {
    var local: array<vec4<f32>, 4>;
    var phi_10049_: vec4<f32>;
    var phi_10050_: vec4<f32>;
    var phi_10051_: vec4<f32>;
    var phi_10052_: vec4<f32>;
    var phi_10053_: vec4<f32>;
    var phi_10054_: vec4<f32>;
    var phi_10055_: vec4<f32>;
    var phi_10056_: vec4<f32>;
    var phi_10065_: vec4<f32>;
    var phi_10066_: vec4<f32>;
    var phi_10067_: vec4<f32>;
    var phi_10068_: vec4<f32>;
    var phi_10069_: vec4<f32>;
    var phi_10070_: vec4<f32>;
    var phi_10071_: vec4<f32>;
    var phi_10072_: vec4<f32>;
    var phi_10081_: vec4<f32>;
    var phi_10082_: vec4<f32>;
    var phi_10083_: vec4<f32>;
    var phi_10084_: vec4<f32>;
    var phi_10085_: vec4<f32>;
    var phi_10086_: vec4<f32>;
    var phi_10087_: vec4<f32>;
    var phi_10088_: vec4<f32>;
    var phi_10097_: vec4<f32>;
    var phi_10098_: vec4<f32>;
    var phi_10099_: vec4<f32>;
    var phi_10100_: vec4<f32>;
    var phi_10101_: vec4<f32>;
    var phi_10102_: vec4<f32>;
    var phi_10103_: vec4<f32>;
    var phi_10104_: vec4<f32>;
    var phi_10113_: u32;
    var local_1: u32;
    var local_2: u32;
    var local_3: u32;
    var local_4: u32;
    var local_5: u32;
    var local_6: u32;
    var local_7: u32;
    var local_8: u32;
    var local_9: u32;
    var local_10: u32;
    var local_11: u32;
    var local_12: u32;
    var local_13: u32;
    var local_14: u32;
    var local_15: u32;
    var local_16: u32;
    var local_17: u32;
    var local_18: u32;
    var local_19: u32;
    var local_20: u32;
    var local_21: u32;
    var local_22: u32;
    var local_23: u32;
    var local_24: u32;
    var local_25: u32;
    var local_26: u32;
    var local_27: u32;
    var local_28: u32;
    var local_29: u32;
    var local_30: u32;
    var local_31: u32;
    var local_32: u32;
    var local_33: u32;
    var local_34: u32;
    var local_35: u32;
    var local_36: u32;
    var local_37: u32;
    var local_38: u32;
    var local_39: u32;
    var local_40: u32;
    var local_41: u32;
    var local_42: u32;
    var local_43: u32;
    var local_44: u32;
    var local_45: u32;
    var local_46: u32;
    var local_47: u32;
    var local_48: u32;
    var local_49: u32;
    var local_50: u32;
    var local_51: u32;
    var local_52: u32;
    var local_53: u32;
    var local_54: u32;
    var local_55: u32;
    var local_56: u32;
    var local_57: u32;
    var local_58: u32;
    var local_59: u32;
    var local_60: u32;
    var local_61: u32;
    var local_62: u32;
    var local_63: u32;
    var local_64: u32;
    var local_65: u32;
    var local_66: u32;
    var local_67: u32;
    var local_68: u32;
    var local_69: u32;
    var local_70: u32;
    var local_71: u32;
    var local_72: u32;

    let _e47 = global_9;
    let _e48 = global_10;
    let _e49 = _e47.xy;
    let _e52 = global.member_19[0u];
    let _e55 = global.member_19[1u];
    switch bitcast<i32>(0u) {
        default: {
            let _e57 = (_e48 % 64u);
            let _e77 = (insertBits(extractBits(_e57, bitcast<u32>(2i), bitcast<u32>(3i)), _e57, bitcast<u32>(0i), bitcast<u32>(1i)) + (8u * ((_e48 >> bitcast<u32>(6i)) % 2u)));
            let _e81 = (insertBits(extractBits(_e57, bitcast<u32>(3i), bitcast<u32>(3i)), extractBits(_e57, bitcast<u32>(1i), bitcast<u32>(2i)), bitcast<u32>(0i), bitcast<u32>(2i)) + (8u * (_e48 >> bitcast<u32>(7i))));
            switch bitcast<i32>(0u) {
                default: {
                    let _e84 = bitcast<vec2<i32>>((_e49 * vec2<u32>(64u, 64u)));
                    let _e85 = (_e77 * 2u);
                    let _e86 = bitcast<i32>(_e85);
                    let _e87 = (_e81 * 2u);
                    let _e88 = bitcast<i32>(_e87);
                    let _e90 = (_e84 + vec2<i32>(_e86, _e88));
                    let _e92 = bitcast<vec2<i32>>((_e49 * vec2<u32>(32u, 32u)));
                    let _e93 = bitcast<i32>(_e77);
                    let _e94 = bitcast<i32>(_e81);
                    let _e96 = (_e92 + vec2<i32>(_e93, _e94));
                    let _e97 = bitcast<vec2<u32>>(_e90);
                    let _e102 = vec2<i32>(vec2<f32>(_e90));
                    let _e104 = global.member;
                    let _e106 = (_e104.x - 1i);
                    let _e111 = (_e104.y - 1i);
                    let _e115 = vec2<i32>(max(0i, min(_e102.x, _e106)), max(0i, min(_e102.y, _e111)));
                    let _e116 = bitcast<vec2<u32>>(_e115);
                    let _e117 = textureDimensions(global_3, 0i);
                    local_1 = _e85;
                    local_2 = _e87;
                    local_3 = _e85;
                    local_4 = _e87;
                    local_5 = _e85;
                    local_6 = _e87;
                    local_7 = _e85;
                    local_8 = _e87;
                    local_9 = _e85;
                    local_10 = _e87;
                    local_11 = _e87;
                    local_12 = _e87;
                    local_13 = _e87;
                    local_14 = _e87;
                    local_15 = _e85;
                    local_16 = _e85;
                    local_17 = _e85;
                    local_18 = _e85;
                    local_19 = _e85;
                    local_20 = _e87;
                    local_21 = _e87;
                    local_22 = _e87;
                    local_23 = _e87;
                    local_24 = _e87;
                    local_25 = _e87;
                    local_26 = _e87;
                    local_27 = _e87;
                    local_28 = _e87;
                    local_29 = _e85;
                    local_30 = _e87;
                    local_31 = _e85;
                    local_32 = _e87;
                    local_33 = _e85;
                    local_34 = _e87;
                    local_35 = _e85;
                    local_36 = _e87;
                    local_37 = _e85;
                    local_38 = _e87;
                    local_40 = _e87;
                    local_42 = _e87;
                    local_44 = _e87;
                    local_46 = _e87;
                    local_47 = _e85;
                    local_49 = _e85;
                    local_51 = _e85;
                    local_53 = _e85;
                    local_63 = _e85;
                    local_64 = _e87;
                    local_65 = _e87;
                    local_66 = _e87;
                    local_67 = _e87;
                    local_68 = _e87;
                    local_69 = _e87;
                    local_70 = _e87;
                    local_71 = _e87;
                    local_72 = _e87;
                    if all((_e116 < bitcast<vec2<u32>>(vec2<i32>(_e117)))) {
                        let _e122 = textureLoad(global_3, _e115, 0i);
                        phi_10049_ = _e122;
                    } else {
                        phi_10049_ = vec4<f32>(0f, 0f, 0f, 0f);
                    }
                    let _e124 = phi_10049_;
                    let _e128 = textureDimensions(global_1, 0i);
                    if all((_e116 < bitcast<vec2<u32>>(vec2<i32>(_e128)))) {
                        let _e133 = textureLoad(global_1, _e115, 0i);
                        phi_10050_ = _e133;
                    } else {
                        phi_10050_ = vec4<f32>(0f, 0f, 0f, 0f);
                    }
                    let _e135 = phi_10050_;
                    let _e141 = vec4<f32>(max(0.000061f, log(_e124.x)), vec4<f32>(0f, 0f, 0f, 0f).y, vec4<f32>(0f, 0f, 0f, 0f).z, vec4<f32>(0f, 0f, 0f, 0f).w);
                    let _e146 = vec4<f32>(_e141.x, _e124.x, _e141.z, _e141.w);
                    let _e154 = vec2<i32>(vec2<f32>(bitcast<vec2<i32>>((_e97 + vec2<u32>(0u, 1u)))));
                    let _e161 = vec2<i32>(max(0i, min(_e154.x, _e106)), max(0i, min(_e154.y, _e111)));
                    let _e162 = bitcast<vec2<u32>>(_e161);
                    let _e163 = textureDimensions(global_3, 0i);
                    if all((_e162 < bitcast<vec2<u32>>(vec2<i32>(_e163)))) {
                        let _e168 = textureLoad(global_3, _e161, 0i);
                        phi_10051_ = _e168;
                    } else {
                        phi_10051_ = vec4<f32>(0f, 0f, 0f, 0f);
                    }
                    let _e170 = phi_10051_;
                    let _e174 = textureDimensions(global_1, 0i);
                    if all((_e162 < bitcast<vec2<u32>>(vec2<i32>(_e174)))) {
                        let _e179 = textureLoad(global_1, _e161, 0i);
                        phi_10052_ = _e179;
                    } else {
                        phi_10052_ = vec4<f32>(0f, 0f, 0f, 0f);
                    }
                    let _e181 = phi_10052_;
                    let _e187 = vec4<f32>(max(0.000061f, log(_e170.x)), vec4<f32>(0f, 0f, 0f, 0f).y, vec4<f32>(0f, 0f, 0f, 0f).z, vec4<f32>(0f, 0f, 0f, 0f).w);
                    let _e192 = vec4<f32>(_e187.x, _e170.x, _e187.z, _e187.w);
                    let _e200 = vec2<i32>(vec2<f32>(bitcast<vec2<i32>>((_e97 + vec2<u32>(1u, 0u)))));
                    let _e207 = vec2<i32>(max(0i, min(_e200.x, _e106)), max(0i, min(_e200.y, _e111)));
                    let _e208 = bitcast<vec2<u32>>(_e207);
                    let _e209 = textureDimensions(global_3, 0i);
                    if all((_e208 < bitcast<vec2<u32>>(vec2<i32>(_e209)))) {
                        let _e214 = textureLoad(global_3, _e207, 0i);
                        phi_10053_ = _e214;
                    } else {
                        phi_10053_ = vec4<f32>(0f, 0f, 0f, 0f);
                    }
                    let _e216 = phi_10053_;
                    let _e220 = textureDimensions(global_1, 0i);
                    if all((_e208 < bitcast<vec2<u32>>(vec2<i32>(_e220)))) {
                        let _e225 = textureLoad(global_1, _e207, 0i);
                        phi_10054_ = _e225;
                    } else {
                        phi_10054_ = vec4<f32>(0f, 0f, 0f, 0f);
                    }
                    let _e227 = phi_10054_;
                    let _e233 = vec4<f32>(max(0.000061f, log(_e216.x)), vec4<f32>(0f, 0f, 0f, 0f).y, vec4<f32>(0f, 0f, 0f, 0f).z, vec4<f32>(0f, 0f, 0f, 0f).w);
                    let _e238 = vec4<f32>(_e233.x, _e216.x, _e233.z, _e233.w);
                    let _e246 = vec2<i32>(vec2<f32>(bitcast<vec2<i32>>((_e97 + vec2<u32>(1u, 1u)))));
                    let _e253 = vec2<i32>(max(0i, min(_e246.x, _e106)), max(0i, min(_e246.y, _e111)));
                    let _e254 = bitcast<vec2<u32>>(_e253);
                    let _e255 = textureDimensions(global_3, 0i);
                    if all((_e254 < bitcast<vec2<u32>>(vec2<i32>(_e255)))) {
                        let _e260 = textureLoad(global_3, _e253, 0i);
                        phi_10055_ = _e260;
                    } else {
                        phi_10055_ = vec4<f32>(0f, 0f, 0f, 0f);
                    }
                    let _e262 = phi_10055_;
                    let _e266 = textureDimensions(global_1, 0i);
                    if all((_e254 < bitcast<vec2<u32>>(vec2<i32>(_e266)))) {
                        let _e271 = textureLoad(global_1, _e253, 0i);
                        phi_10056_ = _e271;
                    } else {
                        phi_10056_ = vec4<f32>(0f, 0f, 0f, 0f);
                    }
                    let _e273 = phi_10056_;
                    let _e279 = vec4<f32>(max(0.000061f, log(_e262.x)), vec4<f32>(0f, 0f, 0f, 0f).y, vec4<f32>(0f, 0f, 0f, 0f).z, vec4<f32>(0f, 0f, 0f, 0f).w);
                    let _e284 = vec4<f32>(_e279.x, _e262.x, _e279.z, _e279.w);
                    local[0i] = ((((vec4<f32>(_e146.x, _e146.y, _e135.x, _e146.w) + vec4<f32>(_e192.x, _e192.y, _e181.x, _e192.w)) + vec4<f32>(_e238.x, _e238.y, _e227.x, _e238.w)) + vec4<f32>(_e284.x, _e284.y, _e273.x, _e284.w)) * 0.25f);
                    let _e295 = local[0i];
                    let _e298 = textureDimensions(global_2);
                    if all((bitcast<vec2<u32>>(_e96) < bitcast<vec2<u32>>(vec2<i32>(_e298)))) {
                        textureStore(global_2, _e96, vec4<f32>(_e295.z, 0f, 0f, 0f));
                    }
                    let _e305 = bitcast<i32>((_e85 + 32u));
                    let _e307 = (_e84 + vec2<i32>(_e305, _e88));
                    let _e309 = bitcast<i32>((_e77 + 16u));
                    let _e311 = (_e92 + vec2<i32>(_e309, _e94));
                    let _e312 = bitcast<vec2<u32>>(_e307);
                    let _e317 = vec2<i32>(vec2<f32>(_e307));
                    let _e324 = vec2<i32>(max(0i, min(_e317.x, _e106)), max(0i, min(_e317.y, _e111)));
                    let _e325 = bitcast<vec2<u32>>(_e324);
                    let _e326 = textureDimensions(global_3, 0i);
                    if all((_e325 < bitcast<vec2<u32>>(vec2<i32>(_e326)))) {
                        let _e331 = textureLoad(global_3, _e324, 0i);
                        phi_10065_ = _e331;
                    } else {
                        phi_10065_ = vec4<f32>(0f, 0f, 0f, 0f);
                    }
                    let _e333 = phi_10065_;
                    let _e337 = textureDimensions(global_1, 0i);
                    if all((_e325 < bitcast<vec2<u32>>(vec2<i32>(_e337)))) {
                        let _e342 = textureLoad(global_1, _e324, 0i);
                        phi_10066_ = _e342;
                    } else {
                        phi_10066_ = vec4<f32>(0f, 0f, 0f, 0f);
                    }
                    let _e344 = phi_10066_;
                    let _e350 = vec4<f32>(max(0.000061f, log(_e333.x)), vec4<f32>(0f, 0f, 0f, 0f).y, vec4<f32>(0f, 0f, 0f, 0f).z, vec4<f32>(0f, 0f, 0f, 0f).w);
                    let _e355 = vec4<f32>(_e350.x, _e333.x, _e350.z, _e350.w);
                    let _e363 = vec2<i32>(vec2<f32>(bitcast<vec2<i32>>((_e312 + vec2<u32>(0u, 1u)))));
                    let _e370 = vec2<i32>(max(0i, min(_e363.x, _e106)), max(0i, min(_e363.y, _e111)));
                    let _e371 = bitcast<vec2<u32>>(_e370);
                    let _e372 = textureDimensions(global_3, 0i);
                    if all((_e371 < bitcast<vec2<u32>>(vec2<i32>(_e372)))) {
                        let _e377 = textureLoad(global_3, _e370, 0i);
                        phi_10067_ = _e377;
                    } else {
                        phi_10067_ = vec4<f32>(0f, 0f, 0f, 0f);
                    }
                    let _e379 = phi_10067_;
                    let _e383 = textureDimensions(global_1, 0i);
                    if all((_e371 < bitcast<vec2<u32>>(vec2<i32>(_e383)))) {
                        let _e388 = textureLoad(global_1, _e370, 0i);
                        phi_10068_ = _e388;
                    } else {
                        phi_10068_ = vec4<f32>(0f, 0f, 0f, 0f);
                    }
                    let _e390 = phi_10068_;
                    let _e396 = vec4<f32>(max(0.000061f, log(_e379.x)), vec4<f32>(0f, 0f, 0f, 0f).y, vec4<f32>(0f, 0f, 0f, 0f).z, vec4<f32>(0f, 0f, 0f, 0f).w);
                    let _e401 = vec4<f32>(_e396.x, _e379.x, _e396.z, _e396.w);
                    let _e409 = vec2<i32>(vec2<f32>(bitcast<vec2<i32>>((_e312 + vec2<u32>(1u, 0u)))));
                    let _e416 = vec2<i32>(max(0i, min(_e409.x, _e106)), max(0i, min(_e409.y, _e111)));
                    let _e417 = bitcast<vec2<u32>>(_e416);
                    let _e418 = textureDimensions(global_3, 0i);
                    if all((_e417 < bitcast<vec2<u32>>(vec2<i32>(_e418)))) {
                        let _e423 = textureLoad(global_3, _e416, 0i);
                        phi_10069_ = _e423;
                    } else {
                        phi_10069_ = vec4<f32>(0f, 0f, 0f, 0f);
                    }
                    let _e425 = phi_10069_;
                    let _e429 = textureDimensions(global_1, 0i);
                    if all((_e417 < bitcast<vec2<u32>>(vec2<i32>(_e429)))) {
                        let _e434 = textureLoad(global_1, _e416, 0i);
                        phi_10070_ = _e434;
                    } else {
                        phi_10070_ = vec4<f32>(0f, 0f, 0f, 0f);
                    }
                    let _e436 = phi_10070_;
                    let _e442 = vec4<f32>(max(0.000061f, log(_e425.x)), vec4<f32>(0f, 0f, 0f, 0f).y, vec4<f32>(0f, 0f, 0f, 0f).z, vec4<f32>(0f, 0f, 0f, 0f).w);
                    let _e447 = vec4<f32>(_e442.x, _e425.x, _e442.z, _e442.w);
                    let _e455 = vec2<i32>(vec2<f32>(bitcast<vec2<i32>>((_e312 + vec2<u32>(1u, 1u)))));
                    let _e462 = vec2<i32>(max(0i, min(_e455.x, _e106)), max(0i, min(_e455.y, _e111)));
                    let _e463 = bitcast<vec2<u32>>(_e462);
                    let _e464 = textureDimensions(global_3, 0i);
                    if all((_e463 < bitcast<vec2<u32>>(vec2<i32>(_e464)))) {
                        let _e469 = textureLoad(global_3, _e462, 0i);
                        phi_10071_ = _e469;
                    } else {
                        phi_10071_ = vec4<f32>(0f, 0f, 0f, 0f);
                    }
                    let _e471 = phi_10071_;
                    let _e475 = textureDimensions(global_1, 0i);
                    if all((_e463 < bitcast<vec2<u32>>(vec2<i32>(_e475)))) {
                        let _e480 = textureLoad(global_1, _e462, 0i);
                        phi_10072_ = _e480;
                    } else {
                        phi_10072_ = vec4<f32>(0f, 0f, 0f, 0f);
                    }
                    let _e482 = phi_10072_;
                    let _e488 = vec4<f32>(max(0.000061f, log(_e471.x)), vec4<f32>(0f, 0f, 0f, 0f).y, vec4<f32>(0f, 0f, 0f, 0f).z, vec4<f32>(0f, 0f, 0f, 0f).w);
                    let _e493 = vec4<f32>(_e488.x, _e471.x, _e488.z, _e488.w);
                    local[1i] = ((((vec4<f32>(_e355.x, _e355.y, _e344.x, _e355.w) + vec4<f32>(_e401.x, _e401.y, _e390.x, _e401.w)) + vec4<f32>(_e447.x, _e447.y, _e436.x, _e447.w)) + vec4<f32>(_e493.x, _e493.y, _e482.x, _e493.w)) * 0.25f);
                    let _e504 = local[1i];
                    let _e507 = textureDimensions(global_2);
                    if all((bitcast<vec2<u32>>(_e311) < bitcast<vec2<u32>>(vec2<i32>(_e507)))) {
                        textureStore(global_2, _e311, vec4<f32>(_e504.z, 0f, 0f, 0f));
                    }
                    let _e514 = bitcast<i32>((_e87 + 32u));
                    let _e516 = (_e84 + vec2<i32>(_e86, _e514));
                    let _e518 = bitcast<i32>((_e81 + 16u));
                    let _e520 = (_e92 + vec2<i32>(_e93, _e518));
                    let _e521 = bitcast<vec2<u32>>(_e516);
                    let _e526 = vec2<i32>(vec2<f32>(_e516));
                    let _e533 = vec2<i32>(max(0i, min(_e526.x, _e106)), max(0i, min(_e526.y, _e111)));
                    let _e534 = bitcast<vec2<u32>>(_e533);
                    let _e535 = textureDimensions(global_3, 0i);
                    if all((_e534 < bitcast<vec2<u32>>(vec2<i32>(_e535)))) {
                        let _e540 = textureLoad(global_3, _e533, 0i);
                        phi_10081_ = _e540;
                    } else {
                        phi_10081_ = vec4<f32>(0f, 0f, 0f, 0f);
                    }
                    let _e542 = phi_10081_;
                    let _e546 = textureDimensions(global_1, 0i);
                    if all((_e534 < bitcast<vec2<u32>>(vec2<i32>(_e546)))) {
                        let _e551 = textureLoad(global_1, _e533, 0i);
                        phi_10082_ = _e551;
                    } else {
                        phi_10082_ = vec4<f32>(0f, 0f, 0f, 0f);
                    }
                    let _e553 = phi_10082_;
                    let _e559 = vec4<f32>(max(0.000061f, log(_e542.x)), vec4<f32>(0f, 0f, 0f, 0f).y, vec4<f32>(0f, 0f, 0f, 0f).z, vec4<f32>(0f, 0f, 0f, 0f).w);
                    let _e564 = vec4<f32>(_e559.x, _e542.x, _e559.z, _e559.w);
                    let _e572 = vec2<i32>(vec2<f32>(bitcast<vec2<i32>>((_e521 + vec2<u32>(0u, 1u)))));
                    let _e579 = vec2<i32>(max(0i, min(_e572.x, _e106)), max(0i, min(_e572.y, _e111)));
                    let _e580 = bitcast<vec2<u32>>(_e579);
                    let _e581 = textureDimensions(global_3, 0i);
                    if all((_e580 < bitcast<vec2<u32>>(vec2<i32>(_e581)))) {
                        let _e586 = textureLoad(global_3, _e579, 0i);
                        phi_10083_ = _e586;
                    } else {
                        phi_10083_ = vec4<f32>(0f, 0f, 0f, 0f);
                    }
                    let _e588 = phi_10083_;
                    let _e592 = textureDimensions(global_1, 0i);
                    if all((_e580 < bitcast<vec2<u32>>(vec2<i32>(_e592)))) {
                        let _e597 = textureLoad(global_1, _e579, 0i);
                        phi_10084_ = _e597;
                    } else {
                        phi_10084_ = vec4<f32>(0f, 0f, 0f, 0f);
                    }
                    let _e599 = phi_10084_;
                    let _e605 = vec4<f32>(max(0.000061f, log(_e588.x)), vec4<f32>(0f, 0f, 0f, 0f).y, vec4<f32>(0f, 0f, 0f, 0f).z, vec4<f32>(0f, 0f, 0f, 0f).w);
                    let _e610 = vec4<f32>(_e605.x, _e588.x, _e605.z, _e605.w);
                    let _e618 = vec2<i32>(vec2<f32>(bitcast<vec2<i32>>((_e521 + vec2<u32>(1u, 0u)))));
                    let _e625 = vec2<i32>(max(0i, min(_e618.x, _e106)), max(0i, min(_e618.y, _e111)));
                    let _e626 = bitcast<vec2<u32>>(_e625);
                    let _e627 = textureDimensions(global_3, 0i);
                    if all((_e626 < bitcast<vec2<u32>>(vec2<i32>(_e627)))) {
                        let _e632 = textureLoad(global_3, _e625, 0i);
                        phi_10085_ = _e632;
                    } else {
                        phi_10085_ = vec4<f32>(0f, 0f, 0f, 0f);
                    }
                    let _e634 = phi_10085_;
                    let _e638 = textureDimensions(global_1, 0i);
                    if all((_e626 < bitcast<vec2<u32>>(vec2<i32>(_e638)))) {
                        let _e643 = textureLoad(global_1, _e625, 0i);
                        phi_10086_ = _e643;
                    } else {
                        phi_10086_ = vec4<f32>(0f, 0f, 0f, 0f);
                    }
                    let _e645 = phi_10086_;
                    let _e651 = vec4<f32>(max(0.000061f, log(_e634.x)), vec4<f32>(0f, 0f, 0f, 0f).y, vec4<f32>(0f, 0f, 0f, 0f).z, vec4<f32>(0f, 0f, 0f, 0f).w);
                    let _e656 = vec4<f32>(_e651.x, _e634.x, _e651.z, _e651.w);
                    let _e664 = vec2<i32>(vec2<f32>(bitcast<vec2<i32>>((_e521 + vec2<u32>(1u, 1u)))));
                    let _e671 = vec2<i32>(max(0i, min(_e664.x, _e106)), max(0i, min(_e664.y, _e111)));
                    let _e672 = bitcast<vec2<u32>>(_e671);
                    let _e673 = textureDimensions(global_3, 0i);
                    if all((_e672 < bitcast<vec2<u32>>(vec2<i32>(_e673)))) {
                        let _e678 = textureLoad(global_3, _e671, 0i);
                        phi_10087_ = _e678;
                    } else {
                        phi_10087_ = vec4<f32>(0f, 0f, 0f, 0f);
                    }
                    let _e680 = phi_10087_;
                    let _e684 = textureDimensions(global_1, 0i);
                    if all((_e672 < bitcast<vec2<u32>>(vec2<i32>(_e684)))) {
                        let _e689 = textureLoad(global_1, _e671, 0i);
                        phi_10088_ = _e689;
                    } else {
                        phi_10088_ = vec4<f32>(0f, 0f, 0f, 0f);
                    }
                    let _e691 = phi_10088_;
                    let _e697 = vec4<f32>(max(0.000061f, log(_e680.x)), vec4<f32>(0f, 0f, 0f, 0f).y, vec4<f32>(0f, 0f, 0f, 0f).z, vec4<f32>(0f, 0f, 0f, 0f).w);
                    let _e702 = vec4<f32>(_e697.x, _e680.x, _e697.z, _e697.w);
                    local[2i] = ((((vec4<f32>(_e564.x, _e564.y, _e553.x, _e564.w) + vec4<f32>(_e610.x, _e610.y, _e599.x, _e610.w)) + vec4<f32>(_e656.x, _e656.y, _e645.x, _e656.w)) + vec4<f32>(_e702.x, _e702.y, _e691.x, _e702.w)) * 0.25f);
                    let _e713 = local[2i];
                    let _e716 = textureDimensions(global_2);
                    if all((bitcast<vec2<u32>>(_e520) < bitcast<vec2<u32>>(vec2<i32>(_e716)))) {
                        textureStore(global_2, _e520, vec4<f32>(_e713.z, 0f, 0f, 0f));
                    }
                    let _e723 = (_e84 + vec2<i32>(_e305, _e514));
                    let _e725 = (_e92 + vec2<i32>(_e309, _e518));
                    let _e726 = bitcast<vec2<u32>>(_e723);
                    let _e731 = vec2<i32>(vec2<f32>(_e723));
                    let _e738 = vec2<i32>(max(0i, min(_e731.x, _e106)), max(0i, min(_e731.y, _e111)));
                    let _e739 = bitcast<vec2<u32>>(_e738);
                    let _e740 = textureDimensions(global_3, 0i);
                    if all((_e739 < bitcast<vec2<u32>>(vec2<i32>(_e740)))) {
                        let _e745 = textureLoad(global_3, _e738, 0i);
                        phi_10097_ = _e745;
                    } else {
                        phi_10097_ = vec4<f32>(0f, 0f, 0f, 0f);
                    }
                    let _e747 = phi_10097_;
                    let _e751 = textureDimensions(global_1, 0i);
                    if all((_e739 < bitcast<vec2<u32>>(vec2<i32>(_e751)))) {
                        let _e756 = textureLoad(global_1, _e738, 0i);
                        phi_10098_ = _e756;
                    } else {
                        phi_10098_ = vec4<f32>(0f, 0f, 0f, 0f);
                    }
                    let _e758 = phi_10098_;
                    let _e764 = vec4<f32>(max(0.000061f, log(_e747.x)), vec4<f32>(0f, 0f, 0f, 0f).y, vec4<f32>(0f, 0f, 0f, 0f).z, vec4<f32>(0f, 0f, 0f, 0f).w);
                    let _e769 = vec4<f32>(_e764.x, _e747.x, _e764.z, _e764.w);
                    let _e777 = vec2<i32>(vec2<f32>(bitcast<vec2<i32>>((_e726 + vec2<u32>(0u, 1u)))));
                    let _e784 = vec2<i32>(max(0i, min(_e777.x, _e106)), max(0i, min(_e777.y, _e111)));
                    let _e785 = bitcast<vec2<u32>>(_e784);
                    let _e786 = textureDimensions(global_3, 0i);
                    if all((_e785 < bitcast<vec2<u32>>(vec2<i32>(_e786)))) {
                        let _e791 = textureLoad(global_3, _e784, 0i);
                        phi_10099_ = _e791;
                    } else {
                        phi_10099_ = vec4<f32>(0f, 0f, 0f, 0f);
                    }
                    let _e793 = phi_10099_;
                    let _e797 = textureDimensions(global_1, 0i);
                    if all((_e785 < bitcast<vec2<u32>>(vec2<i32>(_e797)))) {
                        let _e802 = textureLoad(global_1, _e784, 0i);
                        phi_10100_ = _e802;
                    } else {
                        phi_10100_ = vec4<f32>(0f, 0f, 0f, 0f);
                    }
                    let _e804 = phi_10100_;
                    let _e810 = vec4<f32>(max(0.000061f, log(_e793.x)), vec4<f32>(0f, 0f, 0f, 0f).y, vec4<f32>(0f, 0f, 0f, 0f).z, vec4<f32>(0f, 0f, 0f, 0f).w);
                    let _e815 = vec4<f32>(_e810.x, _e793.x, _e810.z, _e810.w);
                    let _e823 = vec2<i32>(vec2<f32>(bitcast<vec2<i32>>((_e726 + vec2<u32>(1u, 0u)))));
                    let _e830 = vec2<i32>(max(0i, min(_e823.x, _e106)), max(0i, min(_e823.y, _e111)));
                    let _e831 = bitcast<vec2<u32>>(_e830);
                    let _e832 = textureDimensions(global_3, 0i);
                    if all((_e831 < bitcast<vec2<u32>>(vec2<i32>(_e832)))) {
                        let _e837 = textureLoad(global_3, _e830, 0i);
                        phi_10101_ = _e837;
                    } else {
                        phi_10101_ = vec4<f32>(0f, 0f, 0f, 0f);
                    }
                    let _e839 = phi_10101_;
                    let _e843 = textureDimensions(global_1, 0i);
                    if all((_e831 < bitcast<vec2<u32>>(vec2<i32>(_e843)))) {
                        let _e848 = textureLoad(global_1, _e830, 0i);
                        phi_10102_ = _e848;
                    } else {
                        phi_10102_ = vec4<f32>(0f, 0f, 0f, 0f);
                    }
                    let _e850 = phi_10102_;
                    let _e856 = vec4<f32>(max(0.000061f, log(_e839.x)), vec4<f32>(0f, 0f, 0f, 0f).y, vec4<f32>(0f, 0f, 0f, 0f).z, vec4<f32>(0f, 0f, 0f, 0f).w);
                    let _e861 = vec4<f32>(_e856.x, _e839.x, _e856.z, _e856.w);
                    let _e869 = vec2<i32>(vec2<f32>(bitcast<vec2<i32>>((_e726 + vec2<u32>(1u, 1u)))));
                    let _e876 = vec2<i32>(max(0i, min(_e869.x, _e106)), max(0i, min(_e869.y, _e111)));
                    let _e877 = bitcast<vec2<u32>>(_e876);
                    let _e878 = textureDimensions(global_3, 0i);
                    if all((_e877 < bitcast<vec2<u32>>(vec2<i32>(_e878)))) {
                        let _e883 = textureLoad(global_3, _e876, 0i);
                        phi_10103_ = _e883;
                    } else {
                        phi_10103_ = vec4<f32>(0f, 0f, 0f, 0f);
                    }
                    let _e885 = phi_10103_;
                    let _e889 = textureDimensions(global_1, 0i);
                    if all((_e877 < bitcast<vec2<u32>>(vec2<i32>(_e889)))) {
                        let _e894 = textureLoad(global_1, _e876, 0i);
                        phi_10104_ = _e894;
                    } else {
                        phi_10104_ = vec4<f32>(0f, 0f, 0f, 0f);
                    }
                    let _e896 = phi_10104_;
                    let _e902 = vec4<f32>(max(0.000061f, log(_e885.x)), vec4<f32>(0f, 0f, 0f, 0f).y, vec4<f32>(0f, 0f, 0f, 0f).z, vec4<f32>(0f, 0f, 0f, 0f).w);
                    let _e907 = vec4<f32>(_e902.x, _e885.x, _e902.z, _e902.w);
                    local[3i] = ((((vec4<f32>(_e769.x, _e769.y, _e758.x, _e769.w) + vec4<f32>(_e815.x, _e815.y, _e804.x, _e815.w)) + vec4<f32>(_e861.x, _e861.y, _e850.x, _e861.w)) + vec4<f32>(_e907.x, _e907.y, _e896.x, _e907.w)) * 0.25f);
                    let _e918 = local[3i];
                    let _e921 = textureDimensions(global_2);
                    if all((bitcast<vec2<u32>>(_e725) < bitcast<vec2<u32>>(vec2<i32>(_e921)))) {
                        textureStore(global_2, _e725, vec4<f32>(_e918.z, 0f, 0f, 0f));
                    }
                    if (_e52 <= 1u) {
                        break;
                    }
                    phi_10113_ = 0u;
                    loop {
                        let _e929 = phi_10113_;
                        if (_e929 < 4u) {
                            let _e932 = local[_e929];
                            global_5[_e77][_e81] = _e932.x;
                            global_6[_e77][_e81] = _e932.y;
                            global_7[_e77][_e81] = _e932.z;
                            global_8[_e77][_e81] = _e932.w;
                            storageBarrier();
                            workgroupBarrier();
                            textureBarrier();
                            workgroupBarrier();
                            if (_e48 < 64u) {
                                let _e946 = (_e85 + 1u);
                                let _e947 = (_e87 + 1u);
                                let _e950 = global_5[_e85][_e87];
                                let _e953 = global_6[_e85][_e87];
                                let _e956 = global_7[_e85][_e87];
                                let _e959 = global_8[_e85][_e87];
                                let _e963 = global_5[_e946][_e87];
                                let _e966 = global_6[_e946][_e87];
                                let _e969 = global_7[_e946][_e87];
                                let _e972 = global_8[_e946][_e87];
                                let _e976 = global_5[_e85][_e947];
                                let _e979 = global_6[_e85][_e947];
                                let _e982 = global_7[_e85][_e947];
                                let _e985 = global_8[_e85][_e947];
                                let _e989 = global_5[_e946][_e947];
                                let _e992 = global_6[_e946][_e947];
                                let _e995 = global_7[_e946][_e947];
                                let _e998 = global_8[_e946][_e947];
                                local[_e929] = ((((vec4<f32>(_e950, _e953, _e956, _e959) + vec4<f32>(_e963, _e966, _e969, _e972)) + vec4<f32>(_e976, _e979, _e982, _e985)) + vec4<f32>(_e989, _e992, _e995, _e998)) * 0.25f);
                            }
                            storageBarrier();
                            workgroupBarrier();
                            textureBarrier();
                            workgroupBarrier();
                            continue;
                        } else {
                            break;
                        }
                        continuing {
                            phi_10113_ = (_e929 + bitcast<u32>(1i));
                        }
                    }
                    if (_e48 < 64u) {
                        let _e1007 = local[0i];
                        global_5[_e77][_e81] = _e1007.x;
                        global_6[_e77][_e81] = _e1007.y;
                        global_7[_e77][_e81] = _e1007.z;
                        global_8[_e77][_e81] = _e1007.w;
                        let _e1020 = (_e77 + 8u);
                        let _e1021 = local[1i];
                        global_5[_e1020][_e81] = _e1021.x;
                        global_6[_e1020][_e81] = _e1021.y;
                        global_7[_e1020][_e81] = _e1021.z;
                        global_8[_e1020][_e81] = _e1021.w;
                        let _e1034 = (_e81 + 8u);
                        let _e1035 = local[2i];
                        global_5[_e77][_e1034] = _e1035.x;
                        global_6[_e77][_e1034] = _e1035.y;
                        global_7[_e77][_e1034] = _e1035.z;
                        global_8[_e77][_e1034] = _e1035.w;
                        let _e1048 = local[3i];
                        global_5[_e1020][_e1034] = _e1048.x;
                        global_6[_e1020][_e1034] = _e1048.y;
                        global_7[_e1020][_e1034] = _e1048.z;
                        global_8[_e1020][_e1034] = _e1048.w;
                    }
                    break;
                }
            }
            switch bitcast<i32>(0u) {
                default: {
                    if (_e52 <= 2u) {
                        break;
                    }
                    storageBarrier();
                    workgroupBarrier();
                    textureBarrier();
                    workgroupBarrier();
                    if (_e48 < 64u) {
                        let _e1065 = local_1;
                        let _e1066 = (_e1065 + 1u);
                        let _e1068 = local_2;
                        let _e1069 = (_e1068 + 1u);
                        let _e1071 = local_3;
                        let _e1074 = local_4;
                        let _e1076 = global_5[_e1071][_e1074];
                        let _e1078 = local_5;
                        let _e1081 = local_6;
                        let _e1083 = global_6[_e1078][_e1081];
                        let _e1085 = local_7;
                        let _e1088 = local_8;
                        let _e1090 = global_7[_e1085][_e1088];
                        let _e1092 = local_9;
                        let _e1095 = local_10;
                        let _e1097 = global_8[_e1092][_e1095];
                        let _e1101 = local_11;
                        let _e1103 = global_5[_e1066][_e1101];
                        let _e1106 = local_12;
                        let _e1108 = global_6[_e1066][_e1106];
                        let _e1111 = local_13;
                        let _e1113 = global_7[_e1066][_e1111];
                        let _e1116 = local_14;
                        let _e1118 = global_8[_e1066][_e1116];
                        let _e1121 = local_15;
                        let _e1124 = global_5[_e1121][_e1069];
                        let _e1126 = local_16;
                        let _e1129 = global_6[_e1126][_e1069];
                        let _e1131 = local_17;
                        let _e1134 = global_7[_e1131][_e1069];
                        let _e1136 = local_18;
                        let _e1139 = global_8[_e1136][_e1069];
                        let _e1143 = global_5[_e1066][_e1069];
                        let _e1146 = global_6[_e1066][_e1069];
                        let _e1149 = global_7[_e1066][_e1069];
                        let _e1152 = global_8[_e1066][_e1069];
                        let _e1157 = ((((vec4<f32>(_e1076, _e1083, _e1090, _e1097) + vec4<f32>(_e1103, _e1108, _e1113, _e1118)) + vec4<f32>(_e1124, _e1129, _e1134, _e1139)) + vec4<f32>(_e1143, _e1146, _e1149, _e1152)) * 0.25f);
                        let _e1160 = local_19;
                        let _e1161 = (_e1160 + (_e81 % 2u));
                        let _e1165 = local_20;
                        global_5[_e1161][_e1165] = _e1157.x;
                        let _e1170 = local_21;
                        global_6[_e1161][_e1170] = _e1157.y;
                        let _e1175 = local_22;
                        global_7[_e1161][_e1175] = _e1157.z;
                        let _e1180 = local_23;
                        global_8[_e1161][_e1180] = _e1157.w;
                    }
                    if (_e52 <= 3u) {
                        break;
                    }
                    storageBarrier();
                    workgroupBarrier();
                    textureBarrier();
                    workgroupBarrier();
                    if (_e48 < 16u) {
                        let _e1184 = (_e77 * 4u);
                        let _e1185 = (_e81 * 4u);
                        let _e1186 = (_e1184 + 2u);
                        let _e1187 = (_e1184 + 1u);
                        let _e1188 = (_e1185 + 2u);
                        let _e1189 = (_e1184 + 3u);
                        let _e1192 = global_5[_e1184][_e1185];
                        let _e1195 = global_6[_e1184][_e1185];
                        let _e1198 = global_7[_e1184][_e1185];
                        let _e1201 = global_8[_e1184][_e1185];
                        let _e1205 = global_5[_e1186][_e1185];
                        let _e1208 = global_6[_e1186][_e1185];
                        let _e1211 = global_7[_e1186][_e1185];
                        let _e1214 = global_8[_e1186][_e1185];
                        let _e1218 = global_5[_e1187][_e1188];
                        let _e1221 = global_6[_e1187][_e1188];
                        let _e1224 = global_7[_e1187][_e1188];
                        let _e1227 = global_8[_e1187][_e1188];
                        let _e1231 = global_5[_e1189][_e1188];
                        let _e1234 = global_6[_e1189][_e1188];
                        let _e1237 = global_7[_e1189][_e1188];
                        let _e1240 = global_8[_e1189][_e1188];
                        let _e1245 = ((((vec4<f32>(_e1192, _e1195, _e1198, _e1201) + vec4<f32>(_e1205, _e1208, _e1211, _e1214)) + vec4<f32>(_e1218, _e1221, _e1224, _e1227)) + vec4<f32>(_e1231, _e1234, _e1237, _e1240)) * 0.25f);
                        let _e1246 = (_e1184 + _e81);
                        global_5[_e1246][_e1185] = _e1245.x;
                        global_6[_e1246][_e1185] = _e1245.y;
                        global_7[_e1246][_e1185] = _e1245.z;
                        global_8[_e1246][_e1185] = _e1245.w;
                    }
                    if (_e52 <= 4u) {
                        break;
                    }
                    storageBarrier();
                    workgroupBarrier();
                    textureBarrier();
                    workgroupBarrier();
                    if (_e48 < 4u) {
                        let _e1261 = (_e77 * 8u);
                        let _e1263 = local_24;
                        let _e1264 = (_e1261 + _e1263);
                        let _e1265 = (_e81 * 8u);
                        let _e1268 = local_25;
                        let _e1269 = ((_e1261 + 4u) + _e1268);
                        let _e1272 = local_26;
                        let _e1273 = ((_e1261 + 1u) + _e1272);
                        let _e1274 = (_e1265 + 4u);
                        let _e1277 = local_27;
                        let _e1278 = ((_e1261 + 5u) + _e1277);
                        let _e1281 = global_5[_e1264][_e1265];
                        let _e1284 = global_6[_e1264][_e1265];
                        let _e1287 = global_7[_e1264][_e1265];
                        let _e1290 = global_8[_e1264][_e1265];
                        let _e1294 = global_5[_e1269][_e1265];
                        let _e1297 = global_6[_e1269][_e1265];
                        let _e1300 = global_7[_e1269][_e1265];
                        let _e1303 = global_8[_e1269][_e1265];
                        let _e1307 = global_5[_e1273][_e1274];
                        let _e1310 = global_6[_e1273][_e1274];
                        let _e1313 = global_7[_e1273][_e1274];
                        let _e1316 = global_8[_e1273][_e1274];
                        let _e1320 = global_5[_e1278][_e1274];
                        let _e1323 = global_6[_e1278][_e1274];
                        let _e1326 = global_7[_e1278][_e1274];
                        let _e1329 = global_8[_e1278][_e1274];
                        let _e1334 = ((((vec4<f32>(_e1281, _e1284, _e1287, _e1290) + vec4<f32>(_e1294, _e1297, _e1300, _e1303)) + vec4<f32>(_e1307, _e1310, _e1313, _e1316)) + vec4<f32>(_e1320, _e1323, _e1326, _e1329)) * 0.25f);
                        let _e1336 = local_28;
                        let _e1337 = (_e77 + _e1336);
                        global_5[_e1337][0u] = _e1334.x;
                        global_6[_e1337][0u] = _e1334.y;
                        global_7[_e1337][0u] = _e1334.z;
                        global_8[_e1337][0u] = _e1334.w;
                    }
                    if (_e52 <= 5u) {
                        break;
                    }
                    storageBarrier();
                    workgroupBarrier();
                    textureBarrier();
                    workgroupBarrier();
                    break;
                }
            }
            if (_e52 <= 6u) {
                break;
            }
            if (_e48 == 0u) {
                global_4 = 0u;
            }
            storageBarrier();
            workgroupBarrier();
            textureBarrier();
            workgroupBarrier();
            let _e1353 = global_4;
            if (_e1353 != (_e55 - 1u)) {
                break;
            }
            switch bitcast<i32>(0u) {
                default: {
                    let _e1358 = local_29;
                    let _e1359 = (_e1358 + 1u);
                    let _e1361 = local_30;
                    let _e1362 = (_e1361 + 1u);
                    local_39 = _e1359;
                    local_41 = _e1359;
                    local_43 = _e1359;
                    local_45 = _e1359;
                    local_48 = _e1362;
                    local_50 = _e1362;
                    local_52 = _e1362;
                    local_54 = _e1362;
                    local_55 = _e1359;
                    local_56 = _e1362;
                    local_57 = _e1359;
                    local_58 = _e1362;
                    local_59 = _e1359;
                    local_60 = _e1362;
                    local_61 = _e1359;
                    local_62 = _e1362;
                    if (_e52 <= 7u) {
                        break;
                    }
                    global_5[_e77][_e81] = 0f;
                    global_6[_e77][_e81] = 0f;
                    global_7[_e77][_e81] = 0f;
                    global_8[_e77][_e81] = 0f;
                    break;
                }
            }
            switch bitcast<i32>(0u) {
                default: {
                    if (_e52 <= 8u) {
                        break;
                    }
                    storageBarrier();
                    workgroupBarrier();
                    textureBarrier();
                    workgroupBarrier();
                    if (_e48 < 64u) {
                        let _e1376 = local_31;
                        let _e1379 = local_32;
                        let _e1381 = global_5[_e1376][_e1379];
                        let _e1383 = local_33;
                        let _e1386 = local_34;
                        let _e1388 = global_6[_e1383][_e1386];
                        let _e1390 = local_35;
                        let _e1393 = local_36;
                        let _e1395 = global_7[_e1390][_e1393];
                        let _e1397 = local_37;
                        let _e1400 = local_38;
                        let _e1402 = global_8[_e1397][_e1400];
                        let _e1405 = local_39;
                        let _e1408 = local_40;
                        let _e1410 = global_5[_e1405][_e1408];
                        let _e1412 = local_41;
                        let _e1415 = local_42;
                        let _e1417 = global_6[_e1412][_e1415];
                        let _e1419 = local_43;
                        let _e1422 = local_44;
                        let _e1424 = global_7[_e1419][_e1422];
                        let _e1426 = local_45;
                        let _e1429 = local_46;
                        let _e1431 = global_8[_e1426][_e1429];
                        let _e1434 = local_47;
                        let _e1437 = local_48;
                        let _e1439 = global_5[_e1434][_e1437];
                        let _e1441 = local_49;
                        let _e1444 = local_50;
                        let _e1446 = global_6[_e1441][_e1444];
                        let _e1448 = local_51;
                        let _e1451 = local_52;
                        let _e1453 = global_7[_e1448][_e1451];
                        let _e1455 = local_53;
                        let _e1458 = local_54;
                        let _e1460 = global_8[_e1455][_e1458];
                        let _e1463 = local_55;
                        let _e1466 = local_56;
                        let _e1468 = global_5[_e1463][_e1466];
                        let _e1470 = local_57;
                        let _e1473 = local_58;
                        let _e1475 = global_6[_e1470][_e1473];
                        let _e1477 = local_59;
                        let _e1480 = local_60;
                        let _e1482 = global_7[_e1477][_e1480];
                        let _e1484 = local_61;
                        let _e1487 = local_62;
                        let _e1489 = global_8[_e1484][_e1487];
                        let _e1494 = ((((vec4<f32>(_e1381, _e1388, _e1395, _e1402) + vec4<f32>(_e1410, _e1417, _e1424, _e1431)) + vec4<f32>(_e1439, _e1446, _e1453, _e1460)) + vec4<f32>(_e1468, _e1475, _e1482, _e1489)) * 0.25f);
                        let _e1497 = local_63;
                        let _e1498 = (_e1497 + (_e81 % 2u));
                        let _e1502 = local_64;
                        global_5[_e1498][_e1502] = _e1494.x;
                        let _e1507 = local_65;
                        global_6[_e1498][_e1507] = _e1494.y;
                        let _e1512 = local_66;
                        global_7[_e1498][_e1512] = _e1494.z;
                        let _e1517 = local_67;
                        global_8[_e1498][_e1517] = _e1494.w;
                    }
                    if (_e52 <= 9u) {
                        break;
                    }
                    storageBarrier();
                    workgroupBarrier();
                    textureBarrier();
                    workgroupBarrier();
                    if (_e48 < 16u) {
                        let _e1521 = (_e77 * 4u);
                        let _e1522 = (_e81 * 4u);
                        let _e1523 = (_e1521 + 2u);
                        let _e1524 = (_e1521 + 1u);
                        let _e1525 = (_e1522 + 2u);
                        let _e1526 = (_e1521 + 3u);
                        let _e1529 = global_5[_e1521][_e1522];
                        let _e1532 = global_6[_e1521][_e1522];
                        let _e1535 = global_7[_e1521][_e1522];
                        let _e1538 = global_8[_e1521][_e1522];
                        let _e1542 = global_5[_e1523][_e1522];
                        let _e1545 = global_6[_e1523][_e1522];
                        let _e1548 = global_7[_e1523][_e1522];
                        let _e1551 = global_8[_e1523][_e1522];
                        let _e1555 = global_5[_e1524][_e1525];
                        let _e1558 = global_6[_e1524][_e1525];
                        let _e1561 = global_7[_e1524][_e1525];
                        let _e1564 = global_8[_e1524][_e1525];
                        let _e1568 = global_5[_e1526][_e1525];
                        let _e1571 = global_6[_e1526][_e1525];
                        let _e1574 = global_7[_e1526][_e1525];
                        let _e1577 = global_8[_e1526][_e1525];
                        let _e1582 = ((((vec4<f32>(_e1529, _e1532, _e1535, _e1538) + vec4<f32>(_e1542, _e1545, _e1548, _e1551)) + vec4<f32>(_e1555, _e1558, _e1561, _e1564)) + vec4<f32>(_e1568, _e1571, _e1574, _e1577)) * 0.25f);
                        let _e1583 = (_e1521 + _e81);
                        global_5[_e1583][_e1522] = _e1582.x;
                        global_6[_e1583][_e1522] = _e1582.y;
                        global_7[_e1583][_e1522] = _e1582.z;
                        global_8[_e1583][_e1522] = _e1582.w;
                    }
                    if (_e52 <= 10u) {
                        break;
                    }
                    storageBarrier();
                    workgroupBarrier();
                    textureBarrier();
                    workgroupBarrier();
                    if (_e48 < 4u) {
                        let _e1598 = (_e77 * 8u);
                        let _e1600 = local_68;
                        let _e1601 = (_e1598 + _e1600);
                        let _e1602 = (_e81 * 8u);
                        let _e1605 = local_69;
                        let _e1606 = ((_e1598 + 4u) + _e1605);
                        let _e1609 = local_70;
                        let _e1610 = ((_e1598 + 1u) + _e1609);
                        let _e1611 = (_e1602 + 4u);
                        let _e1614 = local_71;
                        let _e1615 = ((_e1598 + 5u) + _e1614);
                        let _e1618 = global_5[_e1601][_e1602];
                        let _e1621 = global_6[_e1601][_e1602];
                        let _e1624 = global_7[_e1601][_e1602];
                        let _e1627 = global_8[_e1601][_e1602];
                        let _e1631 = global_5[_e1606][_e1602];
                        let _e1634 = global_6[_e1606][_e1602];
                        let _e1637 = global_7[_e1606][_e1602];
                        let _e1640 = global_8[_e1606][_e1602];
                        let _e1644 = global_5[_e1610][_e1611];
                        let _e1647 = global_6[_e1610][_e1611];
                        let _e1650 = global_7[_e1610][_e1611];
                        let _e1653 = global_8[_e1610][_e1611];
                        let _e1657 = global_5[_e1615][_e1611];
                        let _e1660 = global_6[_e1615][_e1611];
                        let _e1663 = global_7[_e1615][_e1611];
                        let _e1666 = global_8[_e1615][_e1611];
                        let _e1671 = ((((vec4<f32>(_e1618, _e1621, _e1624, _e1627) + vec4<f32>(_e1631, _e1634, _e1637, _e1640)) + vec4<f32>(_e1644, _e1647, _e1650, _e1653)) + vec4<f32>(_e1657, _e1660, _e1663, _e1666)) * 0.25f);
                        let _e1673 = local_72;
                        let _e1674 = (_e77 + _e1673);
                        global_5[_e1674][0u] = _e1671.x;
                        global_6[_e1674][0u] = _e1671.y;
                        global_7[_e1674][0u] = _e1671.z;
                        global_8[_e1674][0u] = _e1671.w;
                    }
                    if (_e52 <= 11u) {
                        break;
                    }
                    storageBarrier();
                    workgroupBarrier();
                    textureBarrier();
                    workgroupBarrier();
                    break;
                }
            }
            break;
        }
    }
    return;
}

@compute @workgroup_size(256, 1, 1) 
fn main(@builtin(workgroup_id) param: vec3<u32>, @builtin(local_invocation_index) param_1: u32) {
    global_9 = param;
    global_10 = param_1;
    function_();
}
