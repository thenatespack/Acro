// Generated from mesh_paint_mask_probes.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: a432f0f1030d456d
// glsl-fnv1a64: 38a3caf15dcac5bd

diagnostic(off, derivative_uniformity);

struct type_24 {
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

struct type_39 {
    member: array<vec4<u32>>,
}

struct type_48 {
    member: vec4<f32>,
    member_1: vec4<f32>,
    member_2: vec4<f32>,
    member_3: vec4<f32>,
    member_4: vec4<f32>,
    member_5: vec4<f32>,
    member_6: vec4<f32>,
}

struct type_53 {
    member: array<vec4<f32>, 1024>,
}

struct type_56 {
    member: array<vec4<u32>, 1024>,
}

struct FragmentOutput {
    @location(0) member: vec4<f32>,
    @location(1) member_1: vec2<f32>,
}

@group(0) @binding(0) 
var<uniform> global: type_24;
@group(1) @binding(1) 
var global_1: sampler_comparison;
@group(1) @binding(0) 
var global_2: texture_depth_2d;
@group(2) @binding(25) 
var<storage> global_3: type_39;
@group(2) @binding(14) 
var global_4: texture_2d<f32>;
@group(2) @binding(17) 
var global_5: sampler;
@group(2) @binding(15) 
var global_6: texture_2d<f32>;
@group(2) @binding(23) 
var global_7: sampler;
@group(2) @binding(2) 
var<uniform> global_8: type_48;
var<private> global_9: vec3<f32>;
var<private> global_10: vec4<f32>;
var<private> global_11: vec3<f32>;
@group(2) @binding(3) 
var<uniform> global_12: type_53;
var<private> global_13: vec3<f32>;
@group(2) @binding(4) 
var<uniform> global_14: type_53;
@group(2) @binding(5) 
var<uniform> global_15: type_53;
var<private> global_16: vec4<f32>;
@group(2) @binding(6) 
var<uniform> global_17: type_56;
@group(2) @binding(7) 
var<uniform> global_18: type_56;
@group(2) @binding(12) 
var global_19: texture_2d<f32>;
var<private> global_20: vec2<f32>;
@group(2) @binding(9) 
var global_21: texture_2d<f32>;
var<private> global_22: vec4<f32>;
var<private> global_23: vec4<f32>;
@group(2) @binding(11) 
var global_24: texture_2d<f32>;
var<private> global_25: bool;
var<private> global_26: vec4<f32>;
@group(2) @binding(10) 
var global_27: texture_2d<f32>;
var<private> global_28: vec4<f32>;
@group(2) @binding(13) 
var global_29: texture_2d<f32>;
var<private> global_30: vec4<f32>;
var<private> global_31: vec2<f32>;
var<private> global_32: vec4<f32>;
var<private> global_33: vec4<f32>;

fn function_() {
    var local: array<f32, 9>;
    var local_1: array<vec2<f32>, 3>;
    var local_2: array<vec2<f32>, 3>;
    var local_3: array<vec2<f32>, 3>;
    var local_4: array<vec2<f32>, 3>;
    var local_5: array<vec3<f32>, 6>;
    var local_6: array<vec3<f32>, 6>;
    var local_7: array<vec3<i32>, 6>;
    var local_8: array<vec3<i32>, 6>;
    var local_9: array<vec4<i32>, 6>;
    var local_10: array<vec4<i32>, 6>;
    var local_11: array<vec4<i32>, 6>;
    var local_12: array<vec4<i32>, 6>;
    var local_13: array<f32, 9>;
    var local_14: array<vec2<f32>, 3>;
    var local_15: array<vec2<f32>, 3>;
    var local_16: array<vec2<f32>, 3>;
    var local_17: array<vec2<f32>, 3>;
    var local_18: array<vec3<f32>, 6>;
    var local_19: array<vec3<f32>, 6>;
    var local_20: array<f32, 9>;
    var local_21: array<f32, 9>;
    var local_22: array<vec2<f32>, 3>;
    var local_23: array<vec2<f32>, 3>;
    var local_24: array<vec2<f32>, 3>;
    var local_25: array<vec2<f32>, 3>;
    var local_26: array<vec3<f32>, 4>;
    var local_27: array<vec3<f32>, 4>;
    var phi_20856_: vec3<f32>;
    var phi_20854_: f32;
    var local_28: vec3<f32>;
    var phi_21017_: vec2<f32>;
    var phi_20984_: f32;
    var phi_20953_: vec3<f32>;
    var phi_20857_: vec2<f32>;
    var phi_20858_: vec3<f32>;
    var phi_20867_: vec3<f32>;
    var phi_20866_: vec3<f32>;
    var phi_20863_: f32;
    var phi_3647_: bool;
    var phi_21053_: vec3<f32>;
    var phi_20868_: i32;
    var phi_5431_: bool;
    var local_29: i32;
    var local_30: i32;
    var local_31: i32;
    var phi_5544_: bool;
    var phi_5551_: bool;
    var phi_5558_: bool;
    var local_32: i32;
    var local_33: i32;
    var local_34: i32;
    var phi_20873_: f32;
    var phi_20870_: i32;
    var phi_20879_: f32;
    var phi_20876_: i32;
    var local_35: f32;
    var phi_20880_: f32;
    var phi_20881_: f32;
    var local_36: i32;
    var local_37: i32;
    var local_38: i32;
    var phi_5831_: bool;
    var phi_5838_: bool;
    var phi_5845_: bool;
    var phi_20893_: f32;
    var phi_20890_: i32;
    var phi_20899_: f32;
    var phi_20896_: i32;
    var local_39: f32;
    var phi_20900_: f32;
    var phi_20901_: f32;
    var phi_20922_: f32;
    var phi_20919_: vec3<f32>;
    var phi_20921_: f32;
    var phi_20918_: vec3<f32>;
    var phi_20924_: vec3<f32>;
    var phi_20923_: f32;
    var phi_21087_: f32;
    var phi_21047_: vec3<f32>;
    var phi_20976_: f32;
    var phi_21177_: f32;
    var phi_21704_: vec3<f32>;
    var phi_21703_: i32;
    var local_40: vec3<f32>;
    var phi_21705_: vec3<f32>;
    var phi_21715_: vec3<f32>;
    var phi_21714_: i32;
    var local_41: vec3<f32>;
    var phi_21716_: vec3<f32>;
    var phi_21722_: vec3<f32>;
    var phi_21721_: i32;
    var phi_22109_: f32;
    var phi_22147_: vec3<f32>;
    var phi_22146_: vec3<f32>;
    var local_42: vec3<f32>;
    var phi_21732_: vec3<f32>;
    var phi_21733_: vec3<f32>;
    var phi_21729_: u32;
    var phi_9396_: bool;
    var phi_9403_: bool;
    var phi_9410_: bool;
    var phi_9417_: bool;
    var phi_22015_: f32;
    var phi_22012_: i32;
    var phi_22021_: f32;
    var phi_22018_: i32;
    var local_43: f32;
    var phi_22022_: f32;
    var phi_9487_: bool;
    var phi_22000_: i32;
    var phi_21999_: i32;
    var phi_21997_: f32;
    var phi_22004_: f32;
    var phi_22001_: i32;
    var phi_22010_: f32;
    var phi_22007_: i32;
    var local_44: f32;
    var phi_22011_: f32;
    var phi_22023_: f32;
    var phi_22074_: vec3<f32>;
    var phi_21731_: vec3<f32>;
    var phi_21048_: f32;
    var phi_21043_: f32;
    var phi_21077_: vec3<f32>;
    var phi_21076_: vec3<f32>;
    var phi_21081_: f32;
    var phi_21080_: f32;
    var phi_21191_: vec3<f32>;
    var phi_21099_: vec3<f32>;
    var phi_21098_: i32;
    var local_45: vec3<f32>;
    var phi_21102_: i32;
    var phi_21103_: i32;
    var phi_21109_: i32;
    var phi_21110_: i32;
    var phi_21153_: vec3<f32>;
    var phi_21141_: vec2<f32>;
    var phi_21117_: vec3<f32>;
    var phi_4165_: bool;
    var phi_21137_: f32;
    var phi_21136_: vec3<f32>;
    var phi_21135_: i32;
    var local_46: vec3<f32>;
    var local_47: f32;
    var phi_21138_: vec3<f32>;
    var phi_21162_: vec3<f32>;
    var phi_21198_: vec3<f32>;
    var phi_21197_: i32;
    var phi_21698_: f32;
    var phi_22117_: vec3<f32>;
    var phi_22116_: vec3<f32>;
    var phi_21199_: vec3<f32>;
    var phi_21222_: i32;
    var phi_21223_: i32;
    var phi_21229_: i32;
    var phi_21230_: i32;
    var phi_21236_: vec3<f32>;
    var phi_21318_: vec3<f32>;
    var phi_21252_: f32;
    var phi_21251_: i32;
    var phi_21253_: f32;
    var phi_21254_: vec3<f32>;
    var phi_21255_: vec3<f32>;
    var phi_21256_: i32;
    var phi_21257_: i32;
    var phi_21263_: vec2<u32>;
    var phi_21265_: vec2<u32>;
    var phi_21268_: vec2<u32>;
    var phi_21269_: vec2<u32>;
    var phi_21270_: i32;
    var phi_21271_: i32;
    var phi_21277_: vec2<u32>;
    var phi_21279_: vec2<u32>;
    var phi_21282_: vec2<u32>;
    var phi_21283_: vec2<u32>;
    var phi_22131_: vec3<f32>;
    var phi_22130_: f32;
    var local_48: f32;
    var local_49: vec3<f32>;
    var phi_4283_: bool;
    var phi_21393_: f32;
    var phi_21392_: vec3<f32>;
    var phi_21391_: i32;
    var local_50: vec3<f32>;
    var local_51: f32;
    var phi_21394_: vec3<f32>;
    var phi_21428_: vec3<f32>;
    var phi_21427_: vec3<f32>;
    var phi_21664_: vec3<f32>;
    var phi_21663_: vec3<f32>;
    var phi_21529_: u32;
    var phi_15373_: bool;
    var phi_15380_: bool;
    var phi_15387_: bool;
    var phi_15394_: bool;
    var phi_21548_: f32;
    var phi_21545_: i32;
    var phi_21554_: f32;
    var phi_21551_: i32;
    var local_52: f32;
    var phi_21555_: f32;
    var phi_15464_: bool;
    var phi_21533_: i32;
    var phi_21532_: i32;
    var phi_21530_: f32;
    var phi_21537_: f32;
    var phi_21534_: i32;
    var phi_21543_: f32;
    var phi_21540_: i32;
    var local_53: f32;
    var phi_21544_: f32;
    var phi_21556_: f32;
    var phi_21661_: vec3<f32>;
    var phi_21734_: vec3<f32>;
    var phi_21730_: vec3<f32>;
    var phi_21813_: f32;
    var phi_21816_: f32;
    var phi_21826_: vec3<f32>;
    var phi_21825_: i32;
    var local_54: vec3<f32>;
    var phi_21827_: vec3<f32>;
    var phi_21831_: vec3<f32>;
    var phi_21830_: i32;
    var phi_21992_: f32;
    var phi_22161_: vec3<f32>;
    var phi_22160_: vec3<f32>;
    var phi_21832_: vec3<f32>;
    var phi_21863_: vec3<f32>;
    var phi_21864_: vec3<f32>;
    var phi_21991_: vec2<f32>;
    var local_55: vec2<f32>;
    var local_56: f32;
    var local_57: f32;
    var local_58: vec3<f32>;
    var local_59: f32;
    var local_60: f32;
    var local_61: vec3<f32>;
    var local_62: vec3<f32>;
    var local_63: vec3<f32>;
    var local_64: f32;
    var local_65: f32;
    var local_66: vec3<f32>;
    var local_67: vec3<f32>;

    let _e267 = global_8.member_2;
    let _e269 = global_20;
    let _e273 = global_8.member_2[2u];
    let _e276 = global_8.member_3;
    let _e281 = global_8.member_3[2u];
    let _e283 = vec2<f32>((dot(_e267.xy, _e269) + _e273), (dot(_e276.xy, _e269) + _e281));
    let _e284 = textureSample(global_21, global_5, _e283);
    let _e285 = global_22;
    let _e286 = _e285.xyz;
    let _e288 = global_8.member;
    let _e291 = _e284.xyz;
    let _e295 = global_8.member[3u];
    let _e300 = global_8.member_6[0u];
    if ((_e295 * _e284.w) < _e300) {
        discard;
    }
    let _e303 = global_22[3u];
    let _e304 = global_23;
    let _e306 = (((_e286 * _e288.xyz) * _e291) * _e304.xyz);
    let _e308 = global_23[3u];
    let _e312 = global_8.member_1[0u];
    phi_20856_ = _e306;
    if (_e312 > 0.5f) {
        let _e314 = global_13;
        let _e317 = floor((_e314.xz * vec2<f32>(0.5f, 0.5f)));
        let _e321 = abs((_e317.x + _e317.y));
        phi_20856_ = (_e306 * select(0.75f, 1f, ((_e321 - (floor((_e321 / 2f)) * 2f)) < 0.5f)));
    }
    let _e330 = phi_20856_;
    let _e333 = global_8.member_3[3u];
    phi_21017_ = vec2<f32>(0f, 0f);
    phi_20984_ = 0f;
    phi_20953_ = _e330;
    if (_e333 > 0.5f) {
        switch bitcast<i32>(0u) {
            default: {
                let _e338 = global_8.member_2[3u];
                let _e340 = vec4<f32>(_e338, _e333, 0f, 0f).xyy;
                let _e342 = floor((_e340 * vec3<f32>(0.000015258789f, 0.000015258789f, 0.000015258789f)));
                let _e344 = (_e340 - (_e342 * 65536f));
                let _e346 = floor((_e344 * vec3<f32>(0.00390625f, 0.00390625f, 0.00390625f)));
                let _e348 = (_e344 - (_e346 * 256f));
                let _e360 = (_e342.y - 128f);
                let _e367 = (floor((_e360 * 0.03125f)) * 0.33333334f);
                let _e371 = global_9;
                let _e372 = normalize(_e371);
                let _e373 = global_10;
                let _e374 = _e373.xyz;
                let _e375 = dot(_e372, _e374);
                let _e381 = ((_e375 / max(length((_e374 - (_e372 * _e375))), 0.000001f)) * 25.5f);
                local_28 = ((vec3<f32>(_e348.x, _e346.x, _e342.x) * vec3<f32>(0.003921569f, 0.003921569f, 0.003921569f)) * 2f);
                local_55 = (vec2<f32>(_e348.y, _e346.y) * vec2<f32>(0.003921569f, 0.003921569f));
                if ((-24f + _e381) < -2f) {
                    phi_20854_ = 0f;
                    break;
                }
                let _e384 = global_11;
                let _e385 = (_e384 * (4f * exp2(((_e360 - (floor((_e360 / 32f)) * 32f)) * 0.33333334f))));
                let _e386 = floor(_e385);
                let _e387 = (_e385 - _e386);
                let _e391 = ((_e387 * _e387) * (vec3<f32>(3f, 3f, 3f) - (_e387 * 2f)));
                let _e393 = bitcast<vec3<u32>>(vec3<i32>(_e386));
                let _e402 = ((((_e393.x * 1597334677u) ^ (_e393.y * 3812015801u)) ^ (_e393.z * 2798796415u)) * 1597334677u);
                let _e411 = bitcast<vec3<u32>>(vec3<i32>((_e386 + vec3<f32>(1f, 0f, 0f))));
                let _e420 = ((((_e411.x * 1597334677u) ^ (_e411.y * 3812015801u)) ^ (_e411.z * 2798796415u)) * 1597334677u);
                let _e431 = bitcast<vec3<u32>>(vec3<i32>((_e386 + vec3<f32>(0f, 1f, 0f))));
                let _e440 = ((((_e431.x * 1597334677u) ^ (_e431.y * 3812015801u)) ^ (_e431.z * 2798796415u)) * 1597334677u);
                let _e449 = bitcast<vec3<u32>>(vec3<i32>((_e386 + vec3<f32>(1f, 1f, 0f))));
                let _e458 = ((((_e449.x * 1597334677u) ^ (_e449.y * 3812015801u)) ^ (_e449.z * 2798796415u)) * 1597334677u);
                let _e470 = bitcast<vec3<u32>>(vec3<i32>((_e386 + vec3<f32>(0f, 0f, 1f))));
                let _e479 = ((((_e470.x * 1597334677u) ^ (_e470.y * 3812015801u)) ^ (_e470.z * 2798796415u)) * 1597334677u);
                let _e488 = bitcast<vec3<u32>>(vec3<i32>((_e386 + vec3<f32>(1f, 0f, 1f))));
                let _e497 = ((((_e488.x * 1597334677u) ^ (_e488.y * 3812015801u)) ^ (_e488.z * 2798796415u)) * 1597334677u);
                let _e507 = bitcast<vec3<u32>>(vec3<i32>((_e386 + vec3<f32>(0f, 1f, 1f))));
                let _e516 = ((((_e507.x * 1597334677u) ^ (_e507.y * 3812015801u)) ^ (_e507.z * 2798796415u)) * 1597334677u);
                let _e525 = bitcast<vec3<u32>>(vec3<i32>((_e386 + vec3<f32>(1f, 1f, 1f))));
                let _e534 = ((((_e525.x * 1597334677u) ^ (_e525.y * 3812015801u)) ^ (_e525.z * 2798796415u)) * 1597334677u);
                let _e547 = ((_e385 * 2.7f) + vec3<f32>(17.3f, 5.1f, 9.7f));
                let _e548 = floor(_e547);
                let _e549 = (_e547 - _e548);
                let _e553 = ((_e549 * _e549) * (vec3<f32>(3f, 3f, 3f) - (_e549 * 2f)));
                let _e555 = bitcast<vec3<u32>>(vec3<i32>(_e548));
                let _e564 = ((((_e555.x * 1597334677u) ^ (_e555.y * 3812015801u)) ^ (_e555.z * 2798796415u)) * 1597334677u);
                let _e573 = bitcast<vec3<u32>>(vec3<i32>((_e548 + vec3<f32>(1f, 0f, 0f))));
                let _e582 = ((((_e573.x * 1597334677u) ^ (_e573.y * 3812015801u)) ^ (_e573.z * 2798796415u)) * 1597334677u);
                let _e593 = bitcast<vec3<u32>>(vec3<i32>((_e548 + vec3<f32>(0f, 1f, 0f))));
                let _e602 = ((((_e593.x * 1597334677u) ^ (_e593.y * 3812015801u)) ^ (_e593.z * 2798796415u)) * 1597334677u);
                let _e611 = bitcast<vec3<u32>>(vec3<i32>((_e548 + vec3<f32>(1f, 1f, 0f))));
                let _e620 = ((((_e611.x * 1597334677u) ^ (_e611.y * 3812015801u)) ^ (_e611.z * 2798796415u)) * 1597334677u);
                let _e632 = bitcast<vec3<u32>>(vec3<i32>((_e548 + vec3<f32>(0f, 0f, 1f))));
                let _e641 = ((((_e632.x * 1597334677u) ^ (_e632.y * 3812015801u)) ^ (_e632.z * 2798796415u)) * 1597334677u);
                let _e650 = bitcast<vec3<u32>>(vec3<i32>((_e548 + vec3<f32>(1f, 0f, 1f))));
                let _e659 = ((((_e650.x * 1597334677u) ^ (_e650.y * 3812015801u)) ^ (_e650.z * 2798796415u)) * 1597334677u);
                let _e669 = bitcast<vec3<u32>>(vec3<i32>((_e548 + vec3<f32>(0f, 1f, 1f))));
                let _e678 = ((((_e669.x * 1597334677u) ^ (_e669.y * 3812015801u)) ^ (_e669.z * 2798796415u)) * 1597334677u);
                let _e687 = bitcast<vec3<u32>>(vec3<i32>((_e548 + vec3<f32>(1f, 1f, 1f))));
                let _e696 = ((((_e687.x * 1597334677u) ^ (_e687.y * 3812015801u)) ^ (_e687.z * 2798796415u)) * 1597334677u);
                let _e709 = mix(0.45f, 0.05f, _e367);
                phi_20854_ = smoothstep(-(_e709), _e709, ((_e381 + -24.45f) + ((((mix(mix(mix((f32(((_e402 ^ (_e402 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e420 ^ (_e420 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e391.x), mix((f32(((_e440 ^ (_e440 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e458 ^ (_e458 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e391.x), _e391.y), mix(mix((f32(((_e479 ^ (_e479 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e497 ^ (_e497 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e391.x), mix((f32(((_e516 ^ (_e516 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e534 ^ (_e534 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e391.x), _e391.y), _e391.z) * 0.65f) + (mix(mix(mix((f32(((_e564 ^ (_e564 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e582 ^ (_e582 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e553.x), mix((f32(((_e602 ^ (_e602 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e620 ^ (_e620 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e553.x), _e553.y), mix(mix((f32(((_e641 ^ (_e641 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e659 ^ (_e659 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e553.x), mix((f32(((_e678 ^ (_e678 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e696 ^ (_e696 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e553.x), _e553.y), _e553.z) * 0.35f)) - 0.5f) * mix(0.8f, 2.2f, _e367))));
                break;
            }
        }
        let _e718 = phi_20854_;
        let _e720 = local_28;
        let _e7762 = local_55;
        phi_21017_ = _e7762;
        phi_20984_ = _e718;
        phi_20953_ = mix(_e330, ((_e286 * _e720) * mix(vec3<f32>(1f, 1f, 1f), (_e291 * 2f), vec3<f32>(0.5f, 0.5f, 0.5f))), vec3(_e718));
    }
    let _e728 = phi_21017_;
    let _e730 = phi_20984_;
    let _e732 = phi_20953_;
    let _e733 = global_9;
    let _e734 = normalize(_e733);
    let _e737 = global_8.member_6[1u];
    phi_20866_ = _e734;
    if (_e737 > 0.5f) {
        let _e739 = global_10;
        let _e740 = _e739.xyz;
        let _e743 = (_e740 - (_e734 * dot(_e734, _e740)));
        phi_20867_ = _e734;
        if (dot(_e743, _e743) > 0.000000000001f) {
            let _e746 = normalize(_e743);
            let _e749 = global_10[3u];
            let _e753 = textureSample(global_24, global_5, _e283);
            let _e756 = global_8.member_6[2u];
            if (_e756 > 0.5f) {
                if (_e756 > 1.5f) {
                    phi_20857_ = _e753.xw;
                } else {
                    phi_20857_ = _e753.xy;
                }
                let _e762 = phi_20857_;
                let _e764 = ((_e762 * 2f) - vec2<f32>(1f, 1f));
                phi_20858_ = vec3<f32>(_e764.x, _e764.y, sqrt(clamp((1f - dot(_e764, _e764)), 0f, 1f)));
            } else {
                phi_20858_ = ((_e753.xyz * 2f) - vec3<f32>(1f, 1f, 1f));
            }
            let _e776 = phi_20858_;
            let _e779 = global_8.member_4[2u];
            let _e781 = (_e776.xy * _e779);
            phi_20867_ = normalize((((_e746 * _e781.x) + ((cross(_e734, _e746) * select(1f, -1f, (_e749 < 0f))) * _e781.y)) + (_e734 * _e776.z)));
        }
        let _e792 = phi_20867_;
        phi_20866_ = _e792;
    }
    let _e794 = phi_20866_;
    let _e797 = global_8.member_5[3u];
    let _e798 = (_e797 > 0.5f);
    if _e798 {
        let _e801 = global_8.member_1[2u];
        phi_20863_ = clamp(_e801, 0f, 1f);
    } else {
        phi_20863_ = 0f;
    }
    let _e804 = phi_20863_;
    phi_3647_ = _e798;
    if _e798 {
        let _e805 = global_25;
        phi_3647_ = !(_e805);
    }
    let _e808 = phi_3647_;
    phi_21053_ = _e794;
    if (_e808 && (_e804 <= 0f)) {
        phi_21053_ = -(_e794);
    }
    let _e813 = phi_21053_;
    let _e815 = global.member_4;
    let _e817 = normalize(_e815.xyz);
    let _e819 = global.member_6;
    let _e820 = _e819.xyz;
    let _e821 = global_13;
    let _e822 = (_e820 - _e821);
    let _e823 = normalize(_e822);
    let _e825 = normalize((_e817 + _e823));
    let _e826 = global_25;
    let _e828 = (_e734 * select(-1f, 1f, _e826));
    let _e830 = global_26[0u];
    let _e831 = (_e830 > 0.5f);
    let _e834 = global.member_5[3u];
    phi_21087_ = 1f;
    phi_21047_ = _e732;
    if ((_e834 > 0.5f) && _e831) {
        switch bitcast<i32>(0u) {
            default: {
                let _e840 = global.member_21[0u];
                let _e841 = i32(_e840);
                let _e843 = global.member_20;
                let _e848 = global.member_20[3u];
                let _e849 = (dot(_e843.xyz, _e821) + _e848);
                phi_20868_ = 0i;
                loop {
                    let _e851 = phi_20868_;
                    local_29 = _e851;
                    local_30 = _e851;
                    local_31 = _e851;
                    local_32 = _e851;
                    local_33 = _e851;
                    local_34 = _e851;
                    local_36 = _e851;
                    local_37 = _e851;
                    local_38 = _e851;
                    let _e853 = (_e851 < (_e841 - 1i));
                    phi_5431_ = _e853;
                    if _e853 {
                        let _e856 = global.member_16[_e851];
                        phi_5431_ = (_e849 > _e856);
                    }
                    let _e859 = phi_5431_;
                    if _e859 {
                        continue;
                    } else {
                        break;
                    }
                    continuing {
                        phi_20868_ = (_e851 + 1i);
                    }
                }
                let _e863 = local_29;
                let _e865 = global.member_16[_e863];
                if (_e849 > _e865) {
                    phi_20924_ = vec3<f32>(1f, 1f, 1f);
                    phi_20923_ = 1f;
                    break;
                }
                let _e869 = local_30;
                let _e871 = global.member_18[_e869];
                let _e873 = (_e821 + (_e828 * _e871));
                switch bitcast<i32>(0u) {
                    default: {
                        let _e877 = local_31;
                        let _e879 = global.member_14[_e877];
                        let _e884 = (_e879 * vec4<f32>(_e873.x, _e873.y, _e873.z, 1f));
                        let _e886 = (_e884.x < 0f);
                        phi_5544_ = _e886;
                        if !(_e886) {
                            phi_5544_ = (_e884.x > 1f);
                        }
                        let _e890 = phi_5544_;
                        phi_5551_ = _e890;
                        if !(_e890) {
                            phi_5551_ = (_e884.y < 0f);
                        }
                        let _e895 = phi_5551_;
                        phi_5558_ = _e895;
                        if !(_e895) {
                            phi_5558_ = (_e884.y > 1f);
                        }
                        let _e900 = phi_5558_;
                        if _e900 {
                            phi_20881_ = 1f;
                            break;
                        }
                        let _e902 = local_32;
                        let _e906 = local_33;
                        let _e912 = global.member_23;
                        let _e913 = _e912.xy;
                        let _e914 = (vec2<f32>(f32((_e902 & 1i)), f32((_e906 >> bitcast<u32>(1i)))) * _e913);
                        let _e919 = local_34;
                        let _e921 = global.member_19[_e919];
                        let _e922 = (min(_e884.z, 1f) - _e921);
                        let _e925 = global.member_22;
                        let _e926 = _e925.xy;
                        let _e927 = (_e926 * 0.5f);
                        let _e929 = (_e914 + (_e884.xy * _e913));
                        let _e930 = (_e914 + _e927);
                        let _e932 = ((_e914 + _e913) - _e927);
                        let _e937 = vec4<f32>(_e930.x, _e930.y, _e932.x, _e932.y);
                        switch bitcast<i32>(0u) {
                            default: {
                                let _e941 = global.member_22[2u];
                                let _e942 = i32(_e941);
                                if (_e942 <= 0i) {
                                    let _e946 = clamp(_e929, _e937.xy, _e937.zw);
                                    let _e951 = textureSampleCompare(global_2, global_1, vec3<f32>(_e946.x, _e946.y, _e922).xy, _e922);
                                    phi_20880_ = _e951;
                                    break;
                                }
                                let _e953 = ((_e929 / _e926) + vec2<f32>(0.5f, 0.5f));
                                let _e954 = floor(_e953);
                                let _e955 = (_e953 - _e954);
                                let _e957 = (_e942 == 1i);
                                if _e957 {
                                    let _e958 = (_e955 * 2f);
                                    local_24[0i] = (vec2<f32>(3f, 3f) - _e958);
                                    local_24[1i] = (vec2<f32>(1f, 1f) + _e958);
                                    let _e964 = local_24[0i];
                                    local_25[0i] = (((vec2<f32>(2f, 2f) - _e955) / _e964) - vec2<f32>(1f, 1f));
                                    let _e968 = local_24[1i];
                                    local_25[1i] = ((_e955 / _e968) + vec2<f32>(1f, 1f));
                                } else {
                                    let _e972 = (_e955 * 3f);
                                    local_24[0i] = (vec2<f32>(4f, 4f) - _e972);
                                    local_24[1i] = vec2<f32>(7f, 7f);
                                    local_24[2i] = (vec2<f32>(1f, 1f) + _e972);
                                    let _e980 = local_24[0i];
                                    local_25[0i] = (((vec2<f32>(3f, 3f) - (_e955 * 2f)) / _e980) - vec2<f32>(2f, 2f));
                                    let _e985 = local_24[1i];
                                    local_25[1i] = ((vec2<f32>(3f, 3f) + _e955) / _e985);
                                    let _e988 = local_24[2i];
                                    local_25[2i] = ((_e955 / _e988) + vec2<f32>(2f, 2f));
                                }
                                let _e993 = select(3i, 2i, _e957);
                                phi_20873_ = 0f;
                                phi_20870_ = 0i;
                                loop {
                                    let _e995 = phi_20873_;
                                    let _e997 = phi_20870_;
                                    local_35 = _e995;
                                    if (_e997 < _e993) {
                                        phi_20879_ = _e995;
                                        phi_20876_ = 0i;
                                        loop {
                                            let _e1000 = phi_20879_;
                                            let _e1002 = phi_20876_;
                                            local_56 = _e1000;
                                            if (_e1002 < _e993) {
                                                continue;
                                            } else {
                                                break;
                                            }
                                            continuing {
                                                let _e1006 = local_25[_e1002][0u];
                                                let _e1009 = local_25[_e997][1u];
                                                let _e1015 = clamp((_e926 * ((_e954 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e1006, _e1009))), _e937.xy, _e937.zw);
                                                let _e1018 = local_24[_e1002][0u];
                                                let _e1021 = local_24[_e997][1u];
                                                let _e1027 = textureSampleCompare(global_2, global_1, vec3<f32>(_e1015.x, _e1015.y, _e922).xy, _e922);
                                                phi_20879_ = (_e1000 + ((_e1018 * _e1021) * _e1027));
                                                phi_20876_ = (_e1002 + 1i);
                                            }
                                        }
                                        continue;
                                    } else {
                                        break;
                                    }
                                    continuing {
                                        let _e7785 = local_56;
                                        phi_20873_ = _e7785;
                                        phi_20870_ = (_e997 + 1i);
                                    }
                                }
                                let _e1033 = local_35;
                                phi_20880_ = (_e1033 * select(0.0069444445f, 0.0625f, _e957));
                                break;
                            }
                        }
                        let _e1036 = phi_20880_;
                        phi_20881_ = _e1036;
                        break;
                    }
                }
                let _e1038 = phi_20881_;
                local_26 = array<vec3<f32>, 4>(vec3<f32>(1f, 0.45f, 0.45f), vec3<f32>(0.45f, 1f, 0.45f), vec3<f32>(0.5f, 0.6f, 1f), vec3<f32>(1f, 1f, 0.4f));
                let _e1040 = local_36;
                let _e1042 = local_26[_e1040];
                let _e1045 = local_37;
                let _e1047 = global.member_17[_e1045];
                phi_20921_ = _e1038;
                phi_20918_ = _e1042;
                if (_e849 > _e1047) {
                    let _e1051 = ((_e849 - _e1047) / (_e865 - _e1047));
                    let _e1053 = local_38;
                    let _e1054 = (_e1053 + 1i);
                    if (_e1054 < _e841) {
                        let _e1058 = global.member_18[_e1054];
                        let _e1060 = (_e821 + (_e828 * _e1058));
                        switch bitcast<i32>(0u) {
                            default: {
                                let _e1064 = global.member_14[_e1054];
                                let _e1069 = (_e1064 * vec4<f32>(_e1060.x, _e1060.y, _e1060.z, 1f));
                                let _e1071 = (_e1069.x < 0f);
                                phi_5831_ = _e1071;
                                if !(_e1071) {
                                    phi_5831_ = (_e1069.x > 1f);
                                }
                                let _e1075 = phi_5831_;
                                phi_5838_ = _e1075;
                                if !(_e1075) {
                                    phi_5838_ = (_e1069.y < 0f);
                                }
                                let _e1080 = phi_5838_;
                                phi_5845_ = _e1080;
                                if !(_e1080) {
                                    phi_5845_ = (_e1069.y > 1f);
                                }
                                let _e1085 = phi_5845_;
                                if _e1085 {
                                    phi_20901_ = 1f;
                                    break;
                                }
                                let _e1093 = global.member_23;
                                let _e1094 = _e1093.xy;
                                let _e1095 = (vec2<f32>(f32((_e1054 & 1i)), f32((_e1054 >> bitcast<u32>(1i)))) * _e1094);
                                let _e1100 = global.member_19[_e1054];
                                let _e1101 = (min(_e1069.z, 1f) - _e1100);
                                let _e1104 = global.member_22;
                                let _e1105 = _e1104.xy;
                                let _e1106 = (_e1105 * 0.5f);
                                let _e1108 = (_e1095 + (_e1069.xy * _e1094));
                                let _e1109 = (_e1095 + _e1106);
                                let _e1111 = ((_e1095 + _e1094) - _e1106);
                                let _e1116 = vec4<f32>(_e1109.x, _e1109.y, _e1111.x, _e1111.y);
                                switch bitcast<i32>(0u) {
                                    default: {
                                        let _e1120 = global.member_22[2u];
                                        let _e1121 = i32(_e1120);
                                        if (_e1121 <= 0i) {
                                            let _e1125 = clamp(_e1108, _e1116.xy, _e1116.zw);
                                            let _e1130 = textureSampleCompare(global_2, global_1, vec3<f32>(_e1125.x, _e1125.y, _e1101).xy, _e1101);
                                            phi_20900_ = _e1130;
                                            break;
                                        }
                                        let _e1132 = ((_e1108 / _e1105) + vec2<f32>(0.5f, 0.5f));
                                        let _e1133 = floor(_e1132);
                                        let _e1134 = (_e1132 - _e1133);
                                        let _e1136 = (_e1121 == 1i);
                                        if _e1136 {
                                            let _e1137 = (_e1134 * 2f);
                                            local_22[0i] = (vec2<f32>(3f, 3f) - _e1137);
                                            local_22[1i] = (vec2<f32>(1f, 1f) + _e1137);
                                            let _e1143 = local_22[0i];
                                            local_23[0i] = (((vec2<f32>(2f, 2f) - _e1134) / _e1143) - vec2<f32>(1f, 1f));
                                            let _e1147 = local_22[1i];
                                            local_23[1i] = ((_e1134 / _e1147) + vec2<f32>(1f, 1f));
                                        } else {
                                            let _e1151 = (_e1134 * 3f);
                                            local_22[0i] = (vec2<f32>(4f, 4f) - _e1151);
                                            local_22[1i] = vec2<f32>(7f, 7f);
                                            local_22[2i] = (vec2<f32>(1f, 1f) + _e1151);
                                            let _e1159 = local_22[0i];
                                            local_23[0i] = (((vec2<f32>(3f, 3f) - (_e1134 * 2f)) / _e1159) - vec2<f32>(2f, 2f));
                                            let _e1164 = local_22[1i];
                                            local_23[1i] = ((vec2<f32>(3f, 3f) + _e1134) / _e1164);
                                            let _e1167 = local_22[2i];
                                            local_23[2i] = ((_e1134 / _e1167) + vec2<f32>(2f, 2f));
                                        }
                                        let _e1172 = select(3i, 2i, _e1136);
                                        phi_20893_ = 0f;
                                        phi_20890_ = 0i;
                                        loop {
                                            let _e1174 = phi_20893_;
                                            let _e1176 = phi_20890_;
                                            local_39 = _e1174;
                                            if (_e1176 < _e1172) {
                                                phi_20899_ = _e1174;
                                                phi_20896_ = 0i;
                                                loop {
                                                    let _e1179 = phi_20899_;
                                                    let _e1181 = phi_20896_;
                                                    local_57 = _e1179;
                                                    if (_e1181 < _e1172) {
                                                        continue;
                                                    } else {
                                                        break;
                                                    }
                                                    continuing {
                                                        let _e1185 = local_23[_e1181][0u];
                                                        let _e1188 = local_23[_e1176][1u];
                                                        let _e1194 = clamp((_e1105 * ((_e1133 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e1185, _e1188))), _e1116.xy, _e1116.zw);
                                                        let _e1197 = local_22[_e1181][0u];
                                                        let _e1200 = local_22[_e1176][1u];
                                                        let _e1206 = textureSampleCompare(global_2, global_1, vec3<f32>(_e1194.x, _e1194.y, _e1101).xy, _e1101);
                                                        phi_20899_ = (_e1179 + ((_e1197 * _e1200) * _e1206));
                                                        phi_20896_ = (_e1181 + 1i);
                                                    }
                                                }
                                                continue;
                                            } else {
                                                break;
                                            }
                                            continuing {
                                                let _e7800 = local_57;
                                                phi_20893_ = _e7800;
                                                phi_20890_ = (_e1176 + 1i);
                                            }
                                        }
                                        let _e1212 = local_39;
                                        phi_20900_ = (_e1212 * select(0.0069444445f, 0.0625f, _e1136));
                                        break;
                                    }
                                }
                                let _e1215 = phi_20900_;
                                phi_20901_ = _e1215;
                                break;
                            }
                        }
                        let _e1217 = phi_20901_;
                        local_27 = array<vec3<f32>, 4>(vec3<f32>(1f, 0.45f, 0.45f), vec3<f32>(0.45f, 1f, 0.45f), vec3<f32>(0.5f, 0.6f, 1f), vec3<f32>(1f, 1f, 0.4f));
                        let _e1220 = local_27[_e1054];
                        phi_20922_ = mix(_e1038, _e1217, _e1051);
                        phi_20919_ = mix(_e1042, _e1220, vec3(_e1051));
                    } else {
                        phi_20922_ = mix(_e1038, 1f, _e1051);
                        phi_20919_ = _e1042;
                    }
                    let _e1225 = phi_20922_;
                    let _e1227 = phi_20919_;
                    phi_20921_ = _e1225;
                    phi_20918_ = _e1227;
                }
                let _e1229 = phi_20921_;
                let _e1231 = phi_20918_;
                let _e1234 = global.member_22[3u];
                phi_20924_ = select(vec3<f32>(1f, 1f, 1f), _e1231, vec3((_e1234 > 0.5f)));
                phi_20923_ = _e1229;
                break;
            }
        }
        let _e1239 = phi_20924_;
        let _e1241 = phi_20923_;
        phi_21087_ = _e1241;
        phi_21047_ = (_e732 * _e1239);
    }
    let _e1244 = phi_21087_;
    let _e1246 = phi_21047_;
    let _e1248 = global.member_5;
    let _e1252 = global.member_4[3u];
    let _e1253 = (_e1248.xyz * _e1252);
    let _e1256 = global_8.member_6[3u];
    let _e1257 = (_e1256 > 0.5f);
    if _e1257 {
        phi_20976_ = 1f;
    } else {
        let _e1260 = global_8.member_4[3u];
        let _e1261 = textureSample(global_19, global_5, _e283);
        phi_20976_ = (1f + (_e1260 * (_e1261.x - 1f)));
    }
    let _e1267 = phi_20976_;
    let _e1269 = global_10[3u];
    let _e1270 = abs(_e1269);
    phi_21177_ = _e1267;
    if (_e1270 > 0f) {
        phi_21177_ = (_e1267 * min(_e1270, 1f));
    }
    let _e1275 = phi_21177_;
    if !(_e798) {
        let _e1277 = dot(_e813, _e817);
        let _e1284 = global_8.member_1[3u];
        let _e1288 = global_8.member_1[2u];
        let _e1295 = global.member_29[0u];
        let _e1296 = (_e1295 > 0.5f);
        if _e1296 {
            let _e1298 = global.member_29;
            let _e1305 = ((_e1298.z * _e813.x) - (_e1298.w * _e813.z));
            let _e1309 = ((_e1298.w * _e813.x) + (_e1298.z * _e813.z));
            let _e1313 = (1.092548f * _e1305);
            local_21 = array<f32, 9>(0.282095f, (0.488603f * _e813.y), (0.488603f * _e1309), (0.488603f * _e1305), (_e1313 * _e813.y), ((1.092548f * _e813.y) * _e1309), (0.315392f * (((3f * _e1309) * _e1309) - 1f)), (_e1313 * _e1309), (0.546274f * ((_e1305 * _e1305) - (_e813.y * _e813.y))));
            phi_21704_ = vec3<f32>(0f, 0f, 0f);
            phi_21703_ = 0i;
            loop {
                let _e1328 = phi_21704_;
                let _e1330 = phi_21703_;
                local_40 = _e1328;
                if (_e1330 < 9i) {
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e1334 = textureLoad(global_4, (vec2<i32>(496i, 256i) + vec2<i32>(_e1330, 0i)), 0i);
                    let _e1337 = local_21[_e1330];
                    phi_21704_ = (_e1328 + (_e1334.xyz * _e1337));
                    phi_21703_ = (_e1330 + 1i);
                }
            }
            let _e1342 = local_40;
            let _e1346 = global.member_29[1u];
            phi_21705_ = (max(_e1342, vec3<f32>(0f, 0f, 0f)) * _e1346);
        } else {
            let _e1349 = global.member_9;
            let _e1352 = global.member_8;
            let _e1361 = global.member_8[3u];
            phi_21705_ = (mix(_e1349.xyz, _e1352.xyz, vec3(((_e813.y * 0.5f) + 0.5f))) * _e1361);
        }
        let _e1364 = phi_21705_;
        let _e1370 = ((_e1246 * ((_e1364 * _e1275) + ((_e1253 * max(_e1277, 0f)) * _e1244))) + ((_e1253 * ((pow(max(dot(_e813, _e825), 0f), _e1284) * _e1288) * step(0f, _e1277))) * _e1244));
        let _e1373 = global.member_34[1u];
        phi_21732_ = _e1370;
        if (_e1373 > 0.5f) {
            if _e1296 {
                let _e1376 = global.member_29;
                let _e1383 = ((_e1376.z * _e813.x) - (_e1376.w * _e813.z));
                let _e1387 = ((_e1376.w * _e813.x) + (_e1376.z * _e813.z));
                let _e1391 = (1.092548f * _e1383);
                local_20 = array<f32, 9>(0.282095f, (0.488603f * _e813.y), (0.488603f * _e1387), (0.488603f * _e1383), (_e1391 * _e813.y), ((1.092548f * _e813.y) * _e1387), (0.315392f * (((3f * _e1387) * _e1387) - 1f)), (_e1391 * _e1387), (0.546274f * ((_e1383 * _e1383) - (_e813.y * _e813.y))));
                phi_21715_ = vec3<f32>(0f, 0f, 0f);
                phi_21714_ = 0i;
                loop {
                    let _e1406 = phi_21715_;
                    let _e1408 = phi_21714_;
                    local_41 = _e1406;
                    if (_e1408 < 9i) {
                        continue;
                    } else {
                        break;
                    }
                    continuing {
                        let _e1412 = textureLoad(global_4, (vec2<i32>(496i, 256i) + vec2<i32>(_e1408, 0i)), 0i);
                        let _e1415 = local_20[_e1408];
                        phi_21715_ = (_e1406 + (_e1412.xyz * _e1415));
                        phi_21714_ = (_e1408 + 1i);
                    }
                }
                let _e1420 = local_41;
                let _e1424 = global.member_29[1u];
                phi_21716_ = (max(_e1420, vec3<f32>(0f, 0f, 0f)) * _e1424);
            } else {
                let _e1427 = global.member_9;
                let _e1430 = global.member_8;
                let _e1439 = global.member_8[3u];
                phi_21716_ = (mix(_e1427.xyz, _e1430.xyz, vec3(((_e813.y * 0.5f) + 0.5f))) * _e1439);
            }
            let _e1442 = phi_21716_;
            let _e1446 = global.member_34[0u];
            phi_21722_ = _e1442;
            phi_21721_ = 0i;
            loop {
                let _e1449 = phi_21722_;
                let _e1451 = phi_21721_;
                local_42 = _e1449;
                if (_e1451 < i32(_e1373)) {
                    let _e1454 = (8i * (i32(_e1446) + _e1451));
                    let _e1458 = global_3.member[(_e1454 + 3i)];
                    let _e1459 = bitcast<vec4<f32>>(_e1458);
                    let _e1462 = global_3.member[_e1454];
                    let _e1463 = bitcast<vec4<f32>>(_e1462);
                    let _e1467 = global_3.member[(_e1454 + 1i)];
                    let _e1468 = bitcast<vec4<f32>>(_e1467);
                    let _e1472 = global_3.member[(_e1454 + 2i)];
                    let _e1473 = bitcast<vec4<f32>>(_e1472);
                    let _e1474 = _e1463.xyz;
                    let _e1478 = _e1468.xyz;
                    let _e1482 = _e1473.xyz;
                    let _e1486 = vec3<f32>((dot(_e1474, _e821) + _e1463.w), (dot(_e1478, _e821) + _e1468.w), (dot(_e1482, _e821) + _e1473.w));
                    let _e1487 = _e1459.xyz;
                    switch bitcast<i32>(0u) {
                        default: {
                            let _e1491 = (_e1487 - abs(_e1486));
                            let _e1496 = min(_e1491.x, min(_e1491.y, _e1491.z));
                            if (_e1496 <= 0f) {
                                phi_22109_ = 0f;
                                break;
                            }
                            if (_e1459.w <= 0f) {
                                phi_22109_ = 1f;
                                break;
                            }
                            let _e1500 = min((_e1496 / _e1459.w), 1f);
                            phi_22109_ = ((_e1500 * _e1500) * (3f - (2f * _e1500)));
                            break;
                        }
                    }
                    let _e1506 = phi_22109_;
                    if (_e1506 <= 0f) {
                        phi_22146_ = _e1449;
                        continue;
                    }
                    let _e1511 = global_3.member[(_e1454 + 4i)];
                    let _e1513 = bitcast<vec4<f32>>(_e1511).xyz;
                    let _e1517 = global_3.member[(_e1454 + 5i)];
                    let _e1518 = bitcast<vec4<f32>>(_e1517);
                    let _e1523 = global_3.member[(_e1454 + 6i)][0u];
                    let _e1524 = bitcast<i32>(_e1523);
                    let _e1525 = dot(_e1474, _e813);
                    let _e1526 = dot(_e1478, _e813);
                    let _e1527 = dot(_e1482, _e813);
                    let _e1528 = vec3<f32>(_e1525, _e1526, _e1527);
                    let _e1534 = ((_e821 + (_e813 * _e1518.x)) + (_e823 * _e1518.y));
                    let _e1549 = clamp(((((vec3<f32>((dot(_e1474, _e1534) + _e1463.w), (dot(_e1478, _e1534) + _e1468.w), (dot(_e1482, _e1534) + _e1473.w)) + _e1487) / max((_e1487 * 2f), vec3<f32>(0.000001f, 0.000001f, 0.000001f))) * _e1513) - vec3<f32>(0.5f, 0.5f, 0.5f)), vec3<f32>(0f, 0f, 0f), (_e1513 - vec3<f32>(1f, 1f, 1f)));
                    let _e1550 = vec3<i32>(_e1513);
                    let _e1554 = min(vec3<i32>(_e1549), max((_e1550 - vec3<i32>(2i, 2i, 2i)), vec3<i32>(0i, 0i, 0i)));
                    let _e1556 = (_e1549 - vec3<f32>(_e1554));
                    let _e1557 = (0.488603f * _e1526);
                    let _e1558 = (0.488603f * _e1527);
                    let _e1559 = (0.488603f * _e1525);
                    let _e1560 = (1.092548f * _e1525);
                    let _e1561 = (_e1560 * _e1526);
                    let _e1563 = ((1.092548f * _e1526) * _e1527);
                    let _e1567 = (0.315392f * (((3f * _e1527) * _e1527) - 1f));
                    let _e1568 = (_e1560 * _e1527);
                    let _e1572 = (0.546274f * ((_e1525 * _e1525) - (_e1526 * _e1526)));
                    let _e1573 = (_e1550 - vec3<i32>(1i, 1i, 1i));
                    let _e1574 = min(_e1554, _e1573);
                    let _e1585 = (_e1524 + ((_e1574.x + (_e1550.x * (_e1574.y + (_e1550.y * _e1574.z)))) * 4i));
                    let _e1586 = (vec3<f32>(1f, 1f, 1f) - _e1556);
                    let _e1593 = ((((((vec3<f32>(_e1574) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e1513) * _e1487) * 2f) - _e1487) - _e1486);
                    let _e1599 = (dot((_e1593 * inverseSqrt(max(dot(_e1593, _e1593), 0.0000000001f))), _e1528) + 1f);
                    let _e1602 = (_e1586.x * _e1586.y);
                    let _e1609 = (_e1585 + 3i);
                    let _e1613 = global_3.member[_e1609][1u];
                    let _e1618 = (((_e1602 * _e1586.z) * ((0.25f * (_e1599 * _e1599)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e1613).y > 0.5f)));
                    let _e1621 = global_3.member[_e1585];
                    let _e1625 = global_3.member[(_e1585 + 1i)];
                    let _e1629 = global_3.member[(_e1585 + 2i)];
                    let _e1632 = global_3.member[_e1609];
                    let _e1634 = unpack2x16float(_e1621.x);
                    let _e1636 = unpack2x16float(_e1621.y);
                    let _e1638 = unpack2x16float(_e1621.z);
                    let _e1640 = unpack2x16float(_e1621.w);
                    let _e1642 = unpack2x16float(_e1625.x);
                    let _e1644 = unpack2x16float(_e1625.y);
                    let _e1646 = unpack2x16float(_e1625.z);
                    let _e1648 = unpack2x16float(_e1625.w);
                    let _e1650 = unpack2x16float(_e1629.x);
                    let _e1652 = unpack2x16float(_e1629.y);
                    let _e1654 = unpack2x16float(_e1629.z);
                    let _e1656 = unpack2x16float(_e1629.w);
                    let _e1658 = unpack2x16float(_e1632.x);
                    let _e1714 = ((((((((((vec3<f32>(_e1634.x, _e1634.y, _e1636.x) * 0.282095f) + (vec3<f32>(_e1636.y, _e1638.x, _e1638.y) * _e1557)) + (vec3<f32>(_e1640.x, _e1640.y, _e1642.x) * _e1558)) + (vec3<f32>(_e1642.y, _e1644.x, _e1644.y) * _e1559)) + (vec3<f32>(_e1646.x, _e1646.y, _e1648.x) * _e1561)) + (vec3<f32>(_e1648.y, _e1650.x, _e1650.y) * _e1563)) + (vec3<f32>(_e1652.x, _e1652.y, _e1654.x) * _e1567)) + (vec3<f32>(_e1654.y, _e1656.x, _e1656.y) * _e1568)) + (vec3<f32>(_e1658.x, _e1658.y, unpack2x16float(_e1632.y).x) * _e1572)) * _e1618);
                    let _e1720 = min((_e1554 + vec3<i32>(1i, 0i, 0i)), _e1573);
                    let _e1729 = (_e1524 + ((_e1720.x + (_e1550.x * (_e1720.y + (_e1550.y * _e1720.z)))) * 4i));
                    let _e1736 = ((((((vec3<f32>(_e1720) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e1513) * _e1487) * 2f) - _e1487) - _e1486);
                    let _e1742 = (dot((_e1736 * inverseSqrt(max(dot(_e1736, _e1736), 0.0000000001f))), _e1528) + 1f);
                    let _e1744 = (_e1556.x * _e1586.y);
                    let _e1750 = (_e1729 + 3i);
                    let _e1754 = global_3.member[_e1750][1u];
                    let _e1759 = (((_e1744 * _e1586.z) * ((0.25f * (_e1742 * _e1742)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e1754).y > 0.5f)));
                    let _e1762 = global_3.member[_e1729];
                    let _e1766 = global_3.member[(_e1729 + 1i)];
                    let _e1770 = global_3.member[(_e1729 + 2i)];
                    let _e1773 = global_3.member[_e1750];
                    let _e1775 = unpack2x16float(_e1762.x);
                    let _e1777 = unpack2x16float(_e1762.y);
                    let _e1779 = unpack2x16float(_e1762.z);
                    let _e1781 = unpack2x16float(_e1762.w);
                    let _e1783 = unpack2x16float(_e1766.x);
                    let _e1785 = unpack2x16float(_e1766.y);
                    let _e1787 = unpack2x16float(_e1766.z);
                    let _e1789 = unpack2x16float(_e1766.w);
                    let _e1791 = unpack2x16float(_e1770.x);
                    let _e1793 = unpack2x16float(_e1770.y);
                    let _e1795 = unpack2x16float(_e1770.z);
                    let _e1797 = unpack2x16float(_e1770.w);
                    let _e1799 = unpack2x16float(_e1773.x);
                    let _e1855 = ((((((((((vec3<f32>(_e1775.x, _e1775.y, _e1777.x) * 0.282095f) + (vec3<f32>(_e1777.y, _e1779.x, _e1779.y) * _e1557)) + (vec3<f32>(_e1781.x, _e1781.y, _e1783.x) * _e1558)) + (vec3<f32>(_e1783.y, _e1785.x, _e1785.y) * _e1559)) + (vec3<f32>(_e1787.x, _e1787.y, _e1789.x) * _e1561)) + (vec3<f32>(_e1789.y, _e1791.x, _e1791.y) * _e1563)) + (vec3<f32>(_e1793.x, _e1793.y, _e1795.x) * _e1567)) + (vec3<f32>(_e1795.y, _e1797.x, _e1797.y) * _e1568)) + (vec3<f32>(_e1799.x, _e1799.y, unpack2x16float(_e1773.y).x) * _e1572)) * _e1759);
                    let _e1862 = min((_e1554 + vec3<i32>(0i, 1i, 0i)), _e1573);
                    let _e1871 = (_e1524 + ((_e1862.x + (_e1550.x * (_e1862.y + (_e1550.y * _e1862.z)))) * 4i));
                    let _e1878 = ((((((vec3<f32>(_e1862) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e1513) * _e1487) * 2f) - _e1487) - _e1486);
                    let _e1884 = (dot((_e1878 * inverseSqrt(max(dot(_e1878, _e1878), 0.0000000001f))), _e1528) + 1f);
                    let _e1886 = (_e1586.x * _e1556.y);
                    let _e1892 = (_e1871 + 3i);
                    let _e1896 = global_3.member[_e1892][1u];
                    let _e1901 = (((_e1886 * _e1586.z) * ((0.25f * (_e1884 * _e1884)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e1896).y > 0.5f)));
                    let _e1904 = global_3.member[_e1871];
                    let _e1908 = global_3.member[(_e1871 + 1i)];
                    let _e1912 = global_3.member[(_e1871 + 2i)];
                    let _e1915 = global_3.member[_e1892];
                    let _e1917 = unpack2x16float(_e1904.x);
                    let _e1919 = unpack2x16float(_e1904.y);
                    let _e1921 = unpack2x16float(_e1904.z);
                    let _e1923 = unpack2x16float(_e1904.w);
                    let _e1925 = unpack2x16float(_e1908.x);
                    let _e1927 = unpack2x16float(_e1908.y);
                    let _e1929 = unpack2x16float(_e1908.z);
                    let _e1931 = unpack2x16float(_e1908.w);
                    let _e1933 = unpack2x16float(_e1912.x);
                    let _e1935 = unpack2x16float(_e1912.y);
                    let _e1937 = unpack2x16float(_e1912.z);
                    let _e1939 = unpack2x16float(_e1912.w);
                    let _e1941 = unpack2x16float(_e1915.x);
                    let _e1997 = ((((((((((vec3<f32>(_e1917.x, _e1917.y, _e1919.x) * 0.282095f) + (vec3<f32>(_e1919.y, _e1921.x, _e1921.y) * _e1557)) + (vec3<f32>(_e1923.x, _e1923.y, _e1925.x) * _e1558)) + (vec3<f32>(_e1925.y, _e1927.x, _e1927.y) * _e1559)) + (vec3<f32>(_e1929.x, _e1929.y, _e1931.x) * _e1561)) + (vec3<f32>(_e1931.y, _e1933.x, _e1933.y) * _e1563)) + (vec3<f32>(_e1935.x, _e1935.y, _e1937.x) * _e1567)) + (vec3<f32>(_e1937.y, _e1939.x, _e1939.y) * _e1568)) + (vec3<f32>(_e1941.x, _e1941.y, unpack2x16float(_e1915.y).x) * _e1572)) * _e1901);
                    let _e2004 = min((_e1554 + vec3<i32>(1i, 1i, 0i)), _e1573);
                    let _e2013 = (_e1524 + ((_e2004.x + (_e1550.x * (_e2004.y + (_e1550.y * _e2004.z)))) * 4i));
                    let _e2020 = ((((((vec3<f32>(_e2004) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e1513) * _e1487) * 2f) - _e1487) - _e1486);
                    let _e2026 = (dot((_e2020 * inverseSqrt(max(dot(_e2020, _e2020), 0.0000000001f))), _e1528) + 1f);
                    let _e2027 = (_e1556.x * _e1556.y);
                    let _e2033 = (_e2013 + 3i);
                    let _e2037 = global_3.member[_e2033][1u];
                    let _e2042 = (((_e2027 * _e1586.z) * ((0.25f * (_e2026 * _e2026)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e2037).y > 0.5f)));
                    let _e2045 = global_3.member[_e2013];
                    let _e2049 = global_3.member[(_e2013 + 1i)];
                    let _e2053 = global_3.member[(_e2013 + 2i)];
                    let _e2056 = global_3.member[_e2033];
                    let _e2058 = unpack2x16float(_e2045.x);
                    let _e2060 = unpack2x16float(_e2045.y);
                    let _e2062 = unpack2x16float(_e2045.z);
                    let _e2064 = unpack2x16float(_e2045.w);
                    let _e2066 = unpack2x16float(_e2049.x);
                    let _e2068 = unpack2x16float(_e2049.y);
                    let _e2070 = unpack2x16float(_e2049.z);
                    let _e2072 = unpack2x16float(_e2049.w);
                    let _e2074 = unpack2x16float(_e2053.x);
                    let _e2076 = unpack2x16float(_e2053.y);
                    let _e2078 = unpack2x16float(_e2053.z);
                    let _e2080 = unpack2x16float(_e2053.w);
                    let _e2082 = unpack2x16float(_e2056.x);
                    let _e2138 = ((((((((((vec3<f32>(_e2058.x, _e2058.y, _e2060.x) * 0.282095f) + (vec3<f32>(_e2060.y, _e2062.x, _e2062.y) * _e1557)) + (vec3<f32>(_e2064.x, _e2064.y, _e2066.x) * _e1558)) + (vec3<f32>(_e2066.y, _e2068.x, _e2068.y) * _e1559)) + (vec3<f32>(_e2070.x, _e2070.y, _e2072.x) * _e1561)) + (vec3<f32>(_e2072.y, _e2074.x, _e2074.y) * _e1563)) + (vec3<f32>(_e2076.x, _e2076.y, _e2078.x) * _e1567)) + (vec3<f32>(_e2078.y, _e2080.x, _e2080.y) * _e1568)) + (vec3<f32>(_e2082.x, _e2082.y, unpack2x16float(_e2056.y).x) * _e1572)) * _e2042);
                    let _e2145 = min((_e1554 + vec3<i32>(0i, 0i, 1i)), _e1573);
                    let _e2154 = (_e1524 + ((_e2145.x + (_e1550.x * (_e2145.y + (_e1550.y * _e2145.z)))) * 4i));
                    let _e2161 = ((((((vec3<f32>(_e2145) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e1513) * _e1487) * 2f) - _e1487) - _e1486);
                    let _e2167 = (dot((_e2161 * inverseSqrt(max(dot(_e2161, _e2161), 0.0000000001f))), _e1528) + 1f);
                    let _e2174 = (_e2154 + 3i);
                    let _e2178 = global_3.member[_e2174][1u];
                    let _e2183 = (((_e1602 * _e1556.z) * ((0.25f * (_e2167 * _e2167)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e2178).y > 0.5f)));
                    let _e2186 = global_3.member[_e2154];
                    let _e2190 = global_3.member[(_e2154 + 1i)];
                    let _e2194 = global_3.member[(_e2154 + 2i)];
                    let _e2197 = global_3.member[_e2174];
                    let _e2199 = unpack2x16float(_e2186.x);
                    let _e2201 = unpack2x16float(_e2186.y);
                    let _e2203 = unpack2x16float(_e2186.z);
                    let _e2205 = unpack2x16float(_e2186.w);
                    let _e2207 = unpack2x16float(_e2190.x);
                    let _e2209 = unpack2x16float(_e2190.y);
                    let _e2211 = unpack2x16float(_e2190.z);
                    let _e2213 = unpack2x16float(_e2190.w);
                    let _e2215 = unpack2x16float(_e2194.x);
                    let _e2217 = unpack2x16float(_e2194.y);
                    let _e2219 = unpack2x16float(_e2194.z);
                    let _e2221 = unpack2x16float(_e2194.w);
                    let _e2223 = unpack2x16float(_e2197.x);
                    let _e2279 = ((((((((((vec3<f32>(_e2199.x, _e2199.y, _e2201.x) * 0.282095f) + (vec3<f32>(_e2201.y, _e2203.x, _e2203.y) * _e1557)) + (vec3<f32>(_e2205.x, _e2205.y, _e2207.x) * _e1558)) + (vec3<f32>(_e2207.y, _e2209.x, _e2209.y) * _e1559)) + (vec3<f32>(_e2211.x, _e2211.y, _e2213.x) * _e1561)) + (vec3<f32>(_e2213.y, _e2215.x, _e2215.y) * _e1563)) + (vec3<f32>(_e2217.x, _e2217.y, _e2219.x) * _e1567)) + (vec3<f32>(_e2219.y, _e2221.x, _e2221.y) * _e1568)) + (vec3<f32>(_e2223.x, _e2223.y, unpack2x16float(_e2197.y).x) * _e1572)) * _e2183);
                    let _e2286 = min((_e1554 + vec3<i32>(1i, 0i, 1i)), _e1573);
                    let _e2295 = (_e1524 + ((_e2286.x + (_e1550.x * (_e2286.y + (_e1550.y * _e2286.z)))) * 4i));
                    let _e2302 = ((((((vec3<f32>(_e2286) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e1513) * _e1487) * 2f) - _e1487) - _e1486);
                    let _e2308 = (dot((_e2302 * inverseSqrt(max(dot(_e2302, _e2302), 0.0000000001f))), _e1528) + 1f);
                    let _e2314 = (_e2295 + 3i);
                    let _e2318 = global_3.member[_e2314][1u];
                    let _e2323 = (((_e1744 * _e1556.z) * ((0.25f * (_e2308 * _e2308)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e2318).y > 0.5f)));
                    let _e2326 = global_3.member[_e2295];
                    let _e2330 = global_3.member[(_e2295 + 1i)];
                    let _e2334 = global_3.member[(_e2295 + 2i)];
                    let _e2337 = global_3.member[_e2314];
                    let _e2339 = unpack2x16float(_e2326.x);
                    let _e2341 = unpack2x16float(_e2326.y);
                    let _e2343 = unpack2x16float(_e2326.z);
                    let _e2345 = unpack2x16float(_e2326.w);
                    let _e2347 = unpack2x16float(_e2330.x);
                    let _e2349 = unpack2x16float(_e2330.y);
                    let _e2351 = unpack2x16float(_e2330.z);
                    let _e2353 = unpack2x16float(_e2330.w);
                    let _e2355 = unpack2x16float(_e2334.x);
                    let _e2357 = unpack2x16float(_e2334.y);
                    let _e2359 = unpack2x16float(_e2334.z);
                    let _e2361 = unpack2x16float(_e2334.w);
                    let _e2363 = unpack2x16float(_e2337.x);
                    let _e2419 = ((((((((((vec3<f32>(_e2339.x, _e2339.y, _e2341.x) * 0.282095f) + (vec3<f32>(_e2341.y, _e2343.x, _e2343.y) * _e1557)) + (vec3<f32>(_e2345.x, _e2345.y, _e2347.x) * _e1558)) + (vec3<f32>(_e2347.y, _e2349.x, _e2349.y) * _e1559)) + (vec3<f32>(_e2351.x, _e2351.y, _e2353.x) * _e1561)) + (vec3<f32>(_e2353.y, _e2355.x, _e2355.y) * _e1563)) + (vec3<f32>(_e2357.x, _e2357.y, _e2359.x) * _e1567)) + (vec3<f32>(_e2359.y, _e2361.x, _e2361.y) * _e1568)) + (vec3<f32>(_e2363.x, _e2363.y, unpack2x16float(_e2337.y).x) * _e1572)) * _e2323);
                    let _e2426 = min((_e1554 + vec3<i32>(0i, 1i, 1i)), _e1573);
                    let _e2435 = (_e1524 + ((_e2426.x + (_e1550.x * (_e2426.y + (_e1550.y * _e2426.z)))) * 4i));
                    let _e2442 = ((((((vec3<f32>(_e2426) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e1513) * _e1487) * 2f) - _e1487) - _e1486);
                    let _e2448 = (dot((_e2442 * inverseSqrt(max(dot(_e2442, _e2442), 0.0000000001f))), _e1528) + 1f);
                    let _e2454 = (_e2435 + 3i);
                    let _e2458 = global_3.member[_e2454][1u];
                    let _e2463 = (((_e1886 * _e1556.z) * ((0.25f * (_e2448 * _e2448)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e2458).y > 0.5f)));
                    let _e2466 = global_3.member[_e2435];
                    let _e2470 = global_3.member[(_e2435 + 1i)];
                    let _e2474 = global_3.member[(_e2435 + 2i)];
                    let _e2477 = global_3.member[_e2454];
                    let _e2479 = unpack2x16float(_e2466.x);
                    let _e2481 = unpack2x16float(_e2466.y);
                    let _e2483 = unpack2x16float(_e2466.z);
                    let _e2485 = unpack2x16float(_e2466.w);
                    let _e2487 = unpack2x16float(_e2470.x);
                    let _e2489 = unpack2x16float(_e2470.y);
                    let _e2491 = unpack2x16float(_e2470.z);
                    let _e2493 = unpack2x16float(_e2470.w);
                    let _e2495 = unpack2x16float(_e2474.x);
                    let _e2497 = unpack2x16float(_e2474.y);
                    let _e2499 = unpack2x16float(_e2474.z);
                    let _e2501 = unpack2x16float(_e2474.w);
                    let _e2503 = unpack2x16float(_e2477.x);
                    let _e2559 = ((((((((((vec3<f32>(_e2479.x, _e2479.y, _e2481.x) * 0.282095f) + (vec3<f32>(_e2481.y, _e2483.x, _e2483.y) * _e1557)) + (vec3<f32>(_e2485.x, _e2485.y, _e2487.x) * _e1558)) + (vec3<f32>(_e2487.y, _e2489.x, _e2489.y) * _e1559)) + (vec3<f32>(_e2491.x, _e2491.y, _e2493.x) * _e1561)) + (vec3<f32>(_e2493.y, _e2495.x, _e2495.y) * _e1563)) + (vec3<f32>(_e2497.x, _e2497.y, _e2499.x) * _e1567)) + (vec3<f32>(_e2499.y, _e2501.x, _e2501.y) * _e1568)) + (vec3<f32>(_e2503.x, _e2503.y, unpack2x16float(_e2477.y).x) * _e1572)) * _e2463);
                    let _e2566 = min((_e1554 + vec3<i32>(1i, 1i, 1i)), _e1573);
                    let _e2575 = (_e1524 + ((_e2566.x + (_e1550.x * (_e2566.y + (_e1550.y * _e2566.z)))) * 4i));
                    let _e2582 = ((((((vec3<f32>(_e2566) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e1513) * _e1487) * 2f) - _e1487) - _e1486);
                    let _e2588 = (dot((_e2582 * inverseSqrt(max(dot(_e2582, _e2582), 0.0000000001f))), _e1528) + 1f);
                    let _e2594 = (_e2575 + 3i);
                    let _e2598 = global_3.member[_e2594][1u];
                    let _e2603 = (((_e2027 * _e1556.z) * ((0.25f * (_e2588 * _e2588)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e2598).y > 0.5f)));
                    let _e2606 = global_3.member[_e2575];
                    let _e2610 = global_3.member[(_e2575 + 1i)];
                    let _e2614 = global_3.member[(_e2575 + 2i)];
                    let _e2617 = global_3.member[_e2594];
                    let _e2619 = unpack2x16float(_e2606.x);
                    let _e2621 = unpack2x16float(_e2606.y);
                    let _e2623 = unpack2x16float(_e2606.z);
                    let _e2625 = unpack2x16float(_e2606.w);
                    let _e2627 = unpack2x16float(_e2610.x);
                    let _e2629 = unpack2x16float(_e2610.y);
                    let _e2631 = unpack2x16float(_e2610.z);
                    let _e2633 = unpack2x16float(_e2610.w);
                    let _e2635 = unpack2x16float(_e2614.x);
                    let _e2637 = unpack2x16float(_e2614.y);
                    let _e2639 = unpack2x16float(_e2614.z);
                    let _e2641 = unpack2x16float(_e2614.w);
                    let _e2643 = unpack2x16float(_e2617.x);
                    let _e2699 = ((((((((((vec3<f32>(_e2619.x, _e2619.y, _e2621.x) * 0.282095f) + (vec3<f32>(_e2621.y, _e2623.x, _e2623.y) * _e1557)) + (vec3<f32>(_e2625.x, _e2625.y, _e2627.x) * _e1558)) + (vec3<f32>(_e2627.y, _e2629.x, _e2629.y) * _e1559)) + (vec3<f32>(_e2631.x, _e2631.y, _e2633.x) * _e1561)) + (vec3<f32>(_e2633.y, _e2635.x, _e2635.y) * _e1563)) + (vec3<f32>(_e2637.x, _e2637.y, _e2639.x) * _e1567)) + (vec3<f32>(_e2639.y, _e2641.x, _e2641.y) * _e1568)) + (vec3<f32>(_e2643.x, _e2643.y, unpack2x16float(_e2617.y).x) * _e1572)) * _e2603);
                    let _e2704 = (((((((vec4<f32>(_e1714.x, _e1714.y, _e1714.z, _e1618) + vec4<f32>(_e1855.x, _e1855.y, _e1855.z, _e1759)) + vec4<f32>(_e1997.x, _e1997.y, _e1997.z, _e1901)) + vec4<f32>(_e2138.x, _e2138.y, _e2138.z, _e2042)) + vec4<f32>(_e2279.x, _e2279.y, _e2279.z, _e2183)) + vec4<f32>(_e2419.x, _e2419.y, _e2419.z, _e2323)) + vec4<f32>(_e2559.x, _e2559.y, _e2559.z, _e2463)) + vec4<f32>(_e2699.x, _e2699.y, _e2699.z, _e2603));
                    phi_22147_ = _e1449;
                    if (_e2704.w > 0.00001f) {
                        phi_22147_ = mix(_e1449, ((max(_e2704.xyz, vec3<f32>(0f, 0f, 0f)) / vec3(_e2704.w)) * _e1518.z), vec3(_e1506));
                    }
                    let _e2716 = phi_22147_;
                    phi_22146_ = _e2716;
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e2718 = phi_22146_;
                    phi_21722_ = _e2718;
                    phi_21721_ = (_e1451 + 1i);
                }
            }
            let _e2721 = local_42;
            phi_21732_ = (_e1370 + ((_e1246 * (_e2721 - _e1442)) * _e1275));
        }
        let _e2727 = phi_21732_;
        let _e2730 = global.member_13[3u];
        phi_21731_ = _e2727;
        if (_e2730 > 0.5f) {
            let _e2733 = global.member_11;
            let _e2738 = global.member_11[3u];
            let _e2740 = global_16;
            let _e2743 = global.member_12;
            let _e2748 = global.member_13;
            let _e2751 = clamp(floor((_e2740.xy * _e2743.xy)), vec2<f32>(0f, 0f), (_e2748.xy - vec2<f32>(1f, 1f)));
            let _e2756 = global.member_12[2u];
            let _e2760 = global.member_12[3u];
            let _e2765 = global.member_13[2u];
            let _e2770 = global.member_13[1u];
            let _e2776 = global.member_13[0u];
            let _e2780 = u32(((((clamp(floor(((log2(max((dot(_e2733.xyz, _e821) + _e2738), 0.000001f)) * _e2756) + _e2760)), 0f, (_e2765 - 1f)) * _e2770) + _e2751.y) * _e2776) + _e2751.x));
            let _e2787 = global_17.member[(_e2780 >> bitcast<u32>(2i))][(_e2780 & 3u)];
            let _e2788 = (_e2787 & 65535u);
            phi_21733_ = _e2727;
            phi_21729_ = _e2788;
            loop {
                let _e2792 = phi_21733_;
                let _e2794 = phi_21729_;
                local_61 = _e2792;
                if (_e2794 < (_e2788 + (_e2787 >> bitcast<u32>(16i)))) {
                    let _e2797 = (_e2794 / 3u);
                    let _e2804 = global_18.member[(_e2797 >> bitcast<u32>(2i))][(_e2797 & 3u)];
                    let _e2810 = ((_e2804 >> bitcast<u32>(((_e2794 - (_e2797 * 3u)) * 10u))) & 1023u);
                    let _e2813 = global_12.member[_e2810];
                    let _e2815 = (_e2813.xyz - _e821);
                    let _e2816 = dot(_e2815, _e2815);
                    let _e2818 = (_e2816 * _e2813.w);
                    let _e2821 = clamp((1f - (_e2818 * _e2818)), 0f, 1f);
                    let _e2824 = (_e2815 * inverseSqrt(max(_e2816, 0.00000001f)));
                    let _e2827 = global_14.member[_e2810];
                    let _e2830 = global_15.member[_e2810];
                    let _e2838 = clamp(((dot(-(_e2824), _e2830.xyz) * _e2827.w) + _e2830.w), 0f, 1f);
                    let _e2845 = (_e2827.xyz * ((((_e2821 * _e2821) * _e2838) * _e2838) / max(_e2816, 0.0001f)));
                    phi_22074_ = _e2845;
                    if _e831 {
                        switch bitcast<i32>(0u) {
                            default: {
                                let _e2849 = global.member_21[2u];
                                let _e2850 = u32(_e2849);
                                if (_e2810 < _e2850) {
                                    let _e2854 = global.member_26[_e2810];
                                    let _e2857 = global.member_15[_e2810];
                                    let _e2866 = (_e2854.z * max((_e2857 * vec4<f32>(_e821.x, _e821.y, _e821.z, 1f)).w, 0f));
                                    let _e2869 = global.member_25[0u];
                                    let _e2875 = global.member_25[1u];
                                    let _e2878 = ((_e821 + (_e828 * (_e2866 * _e2869))) + (_e2824 * (_e2866 * _e2875)));
                                    let _e2883 = (_e2857 * vec4<f32>(_e2878.x, _e2878.y, _e2878.z, 1f));
                                    if (_e2883.w <= 0f) {
                                        phi_22023_ = 1f;
                                        break;
                                    }
                                    let _e2888 = (_e2883.xyz / vec3(_e2883.w));
                                    let _e2890 = (_e2888.x < 0f);
                                    phi_9396_ = _e2890;
                                    if !(_e2890) {
                                        phi_9396_ = (_e2888.x > 1f);
                                    }
                                    let _e2894 = phi_9396_;
                                    phi_9403_ = _e2894;
                                    if !(_e2894) {
                                        phi_9403_ = (_e2888.y < 0f);
                                    }
                                    let _e2899 = phi_9403_;
                                    phi_9410_ = _e2899;
                                    if !(_e2899) {
                                        phi_9410_ = (_e2888.y > 1f);
                                    }
                                    let _e2904 = phi_9410_;
                                    phi_9417_ = _e2904;
                                    if !(_e2904) {
                                        phi_9417_ = (_e2888.z > 1f);
                                    }
                                    let _e2909 = phi_9417_;
                                    if _e2909 {
                                        phi_22023_ = 1f;
                                        break;
                                    }
                                    let _e2912 = _e2854.xy;
                                    let _e2914 = global.member_23;
                                    let _e2915 = _e2914.zw;
                                    let _e2917 = global.member_22;
                                    let _e2918 = _e2917.xy;
                                    let _e2919 = (_e2918 * 0.5f);
                                    let _e2921 = (_e2912 + (_e2888.xy * _e2915));
                                    let _e2922 = (_e2912 + _e2919);
                                    let _e2924 = ((_e2912 + _e2915) - _e2919);
                                    let _e2929 = vec4<f32>(_e2922.x, _e2922.y, _e2924.x, _e2924.y);
                                    switch bitcast<i32>(0u) {
                                        default: {
                                            let _e2933 = global.member_22[2u];
                                            let _e2934 = i32(_e2933);
                                            if (_e2934 <= 0i) {
                                                let _e2938 = clamp(_e2921, _e2929.xy, _e2929.zw);
                                                let _e2943 = textureSampleCompare(global_2, global_1, vec3<f32>(_e2938.x, _e2938.y, _e2888.z).xy, _e2888.z);
                                                phi_22022_ = _e2943;
                                                break;
                                            }
                                            let _e2945 = ((_e2921 / _e2918) + vec2<f32>(0.5f, 0.5f));
                                            let _e2946 = floor(_e2945);
                                            let _e2947 = (_e2945 - _e2946);
                                            let _e2949 = (_e2934 == 1i);
                                            if _e2949 {
                                                let _e2950 = (_e2947 * 2f);
                                                local_16[0i] = (vec2<f32>(3f, 3f) - _e2950);
                                                local_16[1i] = (vec2<f32>(1f, 1f) + _e2950);
                                                let _e2956 = local_16[0i];
                                                local_17[0i] = (((vec2<f32>(2f, 2f) - _e2947) / _e2956) - vec2<f32>(1f, 1f));
                                                let _e2960 = local_16[1i];
                                                local_17[1i] = ((_e2947 / _e2960) + vec2<f32>(1f, 1f));
                                            } else {
                                                let _e2964 = (_e2947 * 3f);
                                                local_16[0i] = (vec2<f32>(4f, 4f) - _e2964);
                                                local_16[1i] = vec2<f32>(7f, 7f);
                                                local_16[2i] = (vec2<f32>(1f, 1f) + _e2964);
                                                let _e2972 = local_16[0i];
                                                local_17[0i] = (((vec2<f32>(3f, 3f) - (_e2947 * 2f)) / _e2972) - vec2<f32>(2f, 2f));
                                                let _e2977 = local_16[1i];
                                                local_17[1i] = ((vec2<f32>(3f, 3f) + _e2947) / _e2977);
                                                let _e2980 = local_16[2i];
                                                local_17[2i] = ((_e2947 / _e2980) + vec2<f32>(2f, 2f));
                                            }
                                            let _e2985 = select(3i, 2i, _e2949);
                                            phi_22015_ = 0f;
                                            phi_22012_ = 0i;
                                            loop {
                                                let _e2987 = phi_22015_;
                                                let _e2989 = phi_22012_;
                                                local_43 = _e2987;
                                                if (_e2989 < _e2985) {
                                                    phi_22021_ = _e2987;
                                                    phi_22018_ = 0i;
                                                    loop {
                                                        let _e2992 = phi_22021_;
                                                        let _e2994 = phi_22018_;
                                                        local_59 = _e2992;
                                                        if (_e2994 < _e2985) {
                                                            continue;
                                                        } else {
                                                            break;
                                                        }
                                                        continuing {
                                                            let _e2998 = local_17[_e2994][0u];
                                                            let _e3001 = local_17[_e2989][1u];
                                                            let _e3007 = clamp((_e2918 * ((_e2946 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e2998, _e3001))), _e2929.xy, _e2929.zw);
                                                            let _e3010 = local_16[_e2994][0u];
                                                            let _e3013 = local_16[_e2989][1u];
                                                            let _e3019 = textureSampleCompare(global_2, global_1, vec3<f32>(_e3007.x, _e3007.y, _e2888.z).xy, _e2888.z);
                                                            phi_22021_ = (_e2992 + ((_e3010 * _e3013) * _e3019));
                                                            phi_22018_ = (_e2994 + 1i);
                                                        }
                                                    }
                                                    continue;
                                                } else {
                                                    break;
                                                }
                                                continuing {
                                                    let _e7842 = local_59;
                                                    phi_22015_ = _e7842;
                                                    phi_22012_ = (_e2989 + 1i);
                                                }
                                            }
                                            let _e3025 = local_43;
                                            phi_22022_ = (_e3025 * select(0.0069444445f, 0.0625f, _e2949));
                                            break;
                                        }
                                    }
                                    let _e3028 = phi_22022_;
                                    phi_22023_ = _e3028;
                                    break;
                                }
                                let _e3029 = (_e2810 - _e2850);
                                let _e3032 = global.member_21[3u];
                                if (_e3029 >= u32(_e3032)) {
                                    phi_22023_ = 1f;
                                    break;
                                }
                                let _e3037 = global.member_27[_e3029];
                                let _e3040 = global.member_28[_e3029];
                                let _e3042 = _e3037.xyz;
                                let _e3045 = (_e3037.w * length((_e821 - _e3042)));
                                let _e3048 = global.member_25[0u];
                                let _e3054 = global.member_25[1u];
                                let _e3058 = (((_e821 + (_e828 * (_e3045 * _e3048))) + (_e2824 * (_e3045 * _e3054))) - _e3042);
                                let _e3059 = abs(_e3058);
                                let _e3062 = (_e3059.x >= _e3059.y);
                                phi_9487_ = _e3062;
                                if _e3062 {
                                    phi_9487_ = (_e3059.x >= _e3059.z);
                                }
                                let _e3066 = phi_9487_;
                                if _e3066 {
                                    phi_21999_ = select(1i, 0i, (_e3058.x > 0f));
                                    phi_21997_ = _e3059.x;
                                } else {
                                    let _e3071 = (_e3059.y >= _e3059.z);
                                    if _e3071 {
                                        phi_22000_ = select(3i, 2i, (_e3058.y > 0f));
                                    } else {
                                        phi_22000_ = select(5i, 4i, (_e3058.z > 0f));
                                    }
                                    let _e3079 = phi_22000_;
                                    phi_21999_ = _e3079;
                                    phi_21997_ = select(_e3059.z, _e3059.y, _e3071);
                                }
                                let _e3082 = phi_21999_;
                                let _e3084 = phi_21997_;
                                if (_e3084 <= 0f) {
                                    phi_22023_ = 1f;
                                    break;
                                }
                                local_18 = array<vec3<f32>, 6>(vec3<f32>(0f, 0f, 1f), vec3<f32>(0f, 0f, -1f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(1f, 0f, 0f));
                                let _e3087 = local_18[_e3082];
                                local_19 = array<vec3<f32>, 6>(vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 0f, -1f), vec3<f32>(0f, 0f, 1f), vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 1f, 0f));
                                let _e3090 = local_19[_e3082];
                                let _e3095 = global.member_24[2u];
                                let _e3098 = (vec2<f32>(dot(_e3058, _e3087), dot(_e3058, _e3090)) / vec2((_e3084 * _e3095)));
                                let _e3102 = (_e3040.z + (_e3040.w / _e3084));
                                if (_e3102 > 1f) {
                                    phi_22023_ = 1f;
                                    break;
                                }
                                let _e3117 = global.member_24;
                                let _e3118 = _e3117.xy;
                                let _e3120 = (_e3040.xy + (vec2<f32>(f32((_e3082 - (i32(floor((f32(_e3082) / f32(3i)))) * 3i))), f32((_e3082 / 3i))) * _e3118));
                                let _e3129 = global.member_22;
                                let _e3130 = _e3129.xy;
                                let _e3131 = (_e3130 * 0.5f);
                                let _e3133 = (_e3120 + (vec2<f32>((0.5f + (0.5f * _e3098.x)), (0.5f - (0.5f * _e3098.y))) * _e3118));
                                let _e3134 = (_e3120 + _e3131);
                                let _e3136 = ((_e3120 + _e3118) - _e3131);
                                let _e3141 = vec4<f32>(_e3134.x, _e3134.y, _e3136.x, _e3136.y);
                                switch bitcast<i32>(0u) {
                                    default: {
                                        let _e3145 = global.member_22[2u];
                                        let _e3146 = i32(_e3145);
                                        if (_e3146 <= 0i) {
                                            let _e3150 = clamp(_e3133, _e3141.xy, _e3141.zw);
                                            let _e3155 = textureSampleCompare(global_2, global_1, vec3<f32>(_e3150.x, _e3150.y, _e3102).xy, _e3102);
                                            phi_22011_ = _e3155;
                                            break;
                                        }
                                        let _e3157 = ((_e3133 / _e3130) + vec2<f32>(0.5f, 0.5f));
                                        let _e3158 = floor(_e3157);
                                        let _e3159 = (_e3157 - _e3158);
                                        let _e3161 = (_e3146 == 1i);
                                        if _e3161 {
                                            let _e3162 = (_e3159 * 2f);
                                            local_14[0i] = (vec2<f32>(3f, 3f) - _e3162);
                                            local_14[1i] = (vec2<f32>(1f, 1f) + _e3162);
                                            let _e3168 = local_14[0i];
                                            local_15[0i] = (((vec2<f32>(2f, 2f) - _e3159) / _e3168) - vec2<f32>(1f, 1f));
                                            let _e3172 = local_14[1i];
                                            local_15[1i] = ((_e3159 / _e3172) + vec2<f32>(1f, 1f));
                                        } else {
                                            let _e3176 = (_e3159 * 3f);
                                            local_14[0i] = (vec2<f32>(4f, 4f) - _e3176);
                                            local_14[1i] = vec2<f32>(7f, 7f);
                                            local_14[2i] = (vec2<f32>(1f, 1f) + _e3176);
                                            let _e3184 = local_14[0i];
                                            local_15[0i] = (((vec2<f32>(3f, 3f) - (_e3159 * 2f)) / _e3184) - vec2<f32>(2f, 2f));
                                            let _e3189 = local_14[1i];
                                            local_15[1i] = ((vec2<f32>(3f, 3f) + _e3159) / _e3189);
                                            let _e3192 = local_14[2i];
                                            local_15[2i] = ((_e3159 / _e3192) + vec2<f32>(2f, 2f));
                                        }
                                        let _e3197 = select(3i, 2i, _e3161);
                                        phi_22004_ = 0f;
                                        phi_22001_ = 0i;
                                        loop {
                                            let _e3199 = phi_22004_;
                                            let _e3201 = phi_22001_;
                                            local_44 = _e3199;
                                            if (_e3201 < _e3197) {
                                                phi_22010_ = _e3199;
                                                phi_22007_ = 0i;
                                                loop {
                                                    let _e3204 = phi_22010_;
                                                    let _e3206 = phi_22007_;
                                                    local_60 = _e3204;
                                                    if (_e3206 < _e3197) {
                                                        continue;
                                                    } else {
                                                        break;
                                                    }
                                                    continuing {
                                                        let _e3210 = local_15[_e3206][0u];
                                                        let _e3213 = local_15[_e3201][1u];
                                                        let _e3219 = clamp((_e3130 * ((_e3158 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e3210, _e3213))), _e3141.xy, _e3141.zw);
                                                        let _e3222 = local_14[_e3206][0u];
                                                        let _e3225 = local_14[_e3201][1u];
                                                        let _e3231 = textureSampleCompare(global_2, global_1, vec3<f32>(_e3219.x, _e3219.y, _e3102).xy, _e3102);
                                                        phi_22010_ = (_e3204 + ((_e3222 * _e3225) * _e3231));
                                                        phi_22007_ = (_e3206 + 1i);
                                                    }
                                                }
                                                continue;
                                            } else {
                                                break;
                                            }
                                            continuing {
                                                let _e7854 = local_60;
                                                phi_22004_ = _e7854;
                                                phi_22001_ = (_e3201 + 1i);
                                            }
                                        }
                                        let _e3237 = local_44;
                                        phi_22011_ = (_e3237 * select(0.0069444445f, 0.0625f, _e3161));
                                        break;
                                    }
                                }
                                let _e3240 = phi_22011_;
                                phi_22023_ = _e3240;
                                break;
                            }
                        }
                        let _e3242 = phi_22023_;
                        phi_22074_ = (_e2845 * _e3242);
                    }
                    let _e3245 = phi_22074_;
                    let _e3246 = dot(_e813, _e2824);
                    local_58 = (_e2792 + (((_e1246 * max(_e3246, 0f)) * _e3245) + (_e3245 * ((pow(max(dot(_e813, normalize((_e2824 + _e823))), 0f), _e1284) * _e1288) * step(0f, _e3246)))));
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e7834 = local_58;
                    phi_21733_ = _e7834;
                    phi_21729_ = (_e2794 + bitcast<u32>(1i));
                }
            }
            let _e7864 = local_61;
            phi_21731_ = _e7864;
        }
        let _e3264 = phi_21731_;
        phi_21730_ = _e3264;
    } else {
        let _e3265 = textureSample(global_27, global_5, _e283);
        let _e3268 = global_8.member_4[0u];
        let _e3272 = global_28[1u];
        let _e3274 = clamp(((_e3268 * _e3265.z) * _e3272), 0f, 1f);
        let _e3277 = global_8.member_4[1u];
        let _e3281 = global_28[0u];
        let _e3283 = clamp(((_e3277 * _e3265.y) * _e3281), 0.045f, 1f);
        phi_21048_ = _e3274;
        phi_21043_ = _e3283;
        if (_e730 > 0f) {
            phi_21048_ = mix(_e3274, _e728.y, _e730);
            phi_21043_ = mix(_e3283, max(_e728.x, 0.045f), _e730);
        }
        let _e3291 = phi_21048_;
        let _e3293 = phi_21043_;
        let _e3294 = (_e3293 * _e3293);
        let _e3296 = (_e1246 * (1f - _e3291));
        let _e3298 = mix(vec3<f32>(0.04f, 0.04f, 0.04f), _e1246, vec3(_e3291));
        let _e3299 = (_e804 > 0f);
        phi_21076_ = _e813;
        if _e3299 {
            let _e3300 = dpdx(_e821);
            let _e3301 = dpdy(_e821);
            let _e3302 = cross(_e3300, _e3301);
            phi_21077_ = _e813;
            if (dot(_e3302, _e3302) > 0.00000000000000000001f) {
                phi_21077_ = normalize(((normalize(_e3302) * select(1f, -1f, (dot(_e3302, _e823) < 0f))) + (_e813 - _e734)));
            }
            let _e3314 = phi_21077_;
            phi_21076_ = _e3314;
        }
        let _e3316 = phi_21076_;
        let _e3318 = max(dot(_e3316, _e823), 0.0001f);
        let _e3321 = dot(_e3316, _e817);
        let _e3322 = clamp(_e3321, 0f, 1f);
        let _e3324 = clamp(dot(_e3316, _e825), 0f, 1f);
        let _e3326 = clamp(dot(_e823, _e825), 0f, 1f);
        phi_21081_ = _e3318;
        phi_21080_ = _e3326;
        if _e3299 {
            phi_21081_ = max(_e3318, 0.5f);
            phi_21080_ = max(_e3326, 0.5f);
        }
        let _e3330 = phi_21081_;
        let _e3332 = phi_21080_;
        let _e3335 = (vec3<f32>(1f, 1f, 1f) - _e3298);
        let _e3337 = (_e3298 + (_e3335 * pow((1f - _e3332), 5f)));
        let _e3338 = (_e3294 * _e3294);
        let _e3340 = (_e3338 - 1f);
        let _e3342 = (((_e3324 * _e3324) * _e3340) + 1f);
        let _e3347 = (1f - _e3338);
        let _e3350 = sqrt((((_e3330 * _e3330) * _e3347) + _e3338));
        let _e3369 = ((((((vec3<f32>(1f, 1f, 1f) - _e3337) * _e3296) * clamp(dot(_e813, _e817), 0f, 1f)) + (((_e3337 * ((_e3338 / ((3.1415927f * _e3342) * _e3342)) * (0.5f / max(((_e3322 * _e3350) + (_e3330 * sqrt((((_e3322 * _e3322) * _e3347) + _e3338)))), 0.00001f)))) * 3.1415927f) * _e3322)) * _e1253) * _e1244);
        phi_21191_ = _e3369;
        if _e3299 {
            phi_21191_ = (_e3369 + (((((_e3296 * _e1253) * _e1244) * _e804) * clamp(-(_e3321), 0f, 1f)) * (0.35f + (0.65f * pow(clamp(dot(-(_e823), _e817), 0f, 1f), 3f)))));
        }
        let _e3385 = phi_21191_;
        let _e3388 = global.member_29[0u];
        let _e3389 = (_e3388 > 0.5f);
        if _e3389 {
            let _e3394 = textureSample(global_6, global_7, (((vec2<f32>(_e3330, _e3293) * 31f) + vec2<f32>(0.5f, 0.5f)) * vec2<f32>(0.03125f, 0.03125f)));
            let _e3397 = global.member_29;
            let _e3404 = ((_e3397.z * _e813.x) - (_e3397.w * _e813.z));
            let _e3408 = ((_e3397.w * _e813.x) + (_e3397.z * _e813.z));
            let _e3412 = (1.092548f * _e3404);
            local_13 = array<f32, 9>(0.282095f, (0.488603f * _e813.y), (0.488603f * _e3408), (0.488603f * _e3404), (_e3412 * _e813.y), ((1.092548f * _e813.y) * _e3408), (0.315392f * (((3f * _e3408) * _e3408) - 1f)), (_e3412 * _e3408), (0.546274f * ((_e3404 * _e3404) - (_e813.y * _e813.y))));
            phi_21099_ = vec3<f32>(0f, 0f, 0f);
            phi_21098_ = 0i;
            loop {
                let _e3427 = phi_21099_;
                let _e3429 = phi_21098_;
                local_45 = _e3427;
                if (_e3429 < 9i) {
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e3433 = textureLoad(global_4, (vec2<i32>(496i, 256i) + vec2<i32>(_e3429, 0i)), 0i);
                    let _e3436 = local_13[_e3429];
                    phi_21099_ = (_e3427 + (_e3433.xyz * _e3436));
                    phi_21098_ = (_e3429 + 1i);
                }
            }
            let _e3441 = local_45;
            let _e3445 = global.member_29[1u];
            let _e3448 = reflect(-(_e823), _e3316);
            let _e3465 = vec2<f32>(((atan2(((_e3397.z * _e3448.x) - (_e3397.w * _e3448.z)), -(((_e3397.w * _e3448.x) + (_e3397.z * _e3448.z)))) * 0.15915494f) + 0.5f), (acos(clamp(_e3448.y, -1f, 1f)) * 0.31830987f));
            let _e3466 = (_e3293 * 5f);
            let _e3468 = min(i32(_e3466), 4i);
            local_11 = array<vec4<i32>, 6>(vec4<i32>(0i, 0i, 512i, 256i), vec4<i32>(0i, 256i, 256i, 128i), vec4<i32>(256i, 256i, 128i, 64i), vec4<i32>(384i, 256i, 64i, 32i), vec4<i32>(448i, 256i, 32i, 16i), vec4<i32>(480i, 256i, 16i, 8i));
            let _e3470 = local_11[_e3468];
            let _e3474 = ((_e3465 * vec2<f32>(_e3470.zw)) - vec2<f32>(0.5f, 0.5f));
            let _e3475 = floor(_e3474);
            let _e3476 = (_e3474 - _e3475);
            let _e3478 = i32(_e3475.x);
            let _e3480 = i32(_e3475.y);
            phi_21102_ = _e3478;
            if (_e3478 < 0i) {
                phi_21102_ = (_e3478 + _e3470.z);
            }
            let _e3485 = phi_21102_;
            phi_21103_ = _e3485;
            if (_e3485 >= _e3470.z) {
                phi_21103_ = (_e3485 - _e3470.z);
            }
            let _e3490 = phi_21103_;
            let _e3491 = (_e3490 + 1i);
            let _e3493 = select(_e3491, 0i, (_e3491 == _e3470.z));
            let _e3497 = min((_e3480 + 1i), (_e3470.w - 1i));
            let _e3498 = max(_e3480, 0i);
            let _e3499 = _e3470.xy;
            let _e3502 = textureLoad(global_4, (_e3499 + vec2<i32>(_e3490, _e3498)), 0i);
            let _e3506 = textureLoad(global_4, (_e3499 + vec2<i32>(_e3493, _e3498)), 0i);
            let _e3510 = textureLoad(global_4, (_e3499 + vec2<i32>(_e3490, _e3497)), 0i);
            let _e3514 = textureLoad(global_4, (_e3499 + vec2<i32>(_e3493, _e3497)), 0i);
            let _e3517 = vec3(_e3476.x);
            local_12 = array<vec4<i32>, 6>(vec4<i32>(0i, 0i, 512i, 256i), vec4<i32>(0i, 256i, 256i, 128i), vec4<i32>(256i, 256i, 128i, 64i), vec4<i32>(384i, 256i, 64i, 32i), vec4<i32>(448i, 256i, 32i, 16i), vec4<i32>(480i, 256i, 16i, 8i));
            let _e3525 = local_12[(_e3468 + 1i)];
            let _e3529 = ((_e3465 * vec2<f32>(_e3525.zw)) - vec2<f32>(0.5f, 0.5f));
            let _e3530 = floor(_e3529);
            let _e3531 = (_e3529 - _e3530);
            let _e3533 = i32(_e3530.x);
            let _e3535 = i32(_e3530.y);
            phi_21109_ = _e3533;
            if (_e3533 < 0i) {
                phi_21109_ = (_e3533 + _e3525.z);
            }
            let _e3540 = phi_21109_;
            phi_21110_ = _e3540;
            if (_e3540 >= _e3525.z) {
                phi_21110_ = (_e3540 - _e3525.z);
            }
            let _e3545 = phi_21110_;
            let _e3546 = (_e3545 + 1i);
            let _e3548 = select(_e3546, 0i, (_e3546 == _e3525.z));
            let _e3552 = min((_e3535 + 1i), (_e3525.w - 1i));
            let _e3553 = max(_e3535, 0i);
            let _e3554 = _e3525.xy;
            let _e3557 = textureLoad(global_4, (_e3554 + vec2<i32>(_e3545, _e3553)), 0i);
            let _e3561 = textureLoad(global_4, (_e3554 + vec2<i32>(_e3548, _e3553)), 0i);
            let _e3565 = textureLoad(global_4, (_e3554 + vec2<i32>(_e3545, _e3552)), 0i);
            let _e3569 = textureLoad(global_4, (_e3554 + vec2<i32>(_e3548, _e3552)), 0i);
            let _e3572 = vec3(_e3531.x);
            phi_21153_ = (max(_e3441, vec3<f32>(0f, 0f, 0f)) * _e3445);
            phi_21141_ = _e3394.xy;
            phi_21117_ = (mix(mix(mix(_e3502.xyz, _e3506.xyz, _e3517), mix(_e3510.xyz, _e3514.xyz, _e3517), vec3(_e3476.y)), mix(mix(_e3557.xyz, _e3561.xyz, _e3572), mix(_e3565.xyz, _e3569.xyz, _e3572), vec3(_e3531.y)), vec3((_e3466 - f32(_e3468)))) * _e3445);
        } else {
            let _e3584 = ((vec4<f32>(-1f, -0.0275f, -0.572f, 0.022f) * _e3293) + vec4<f32>(1f, 0.0425f, 1.04f, -0.04f));
            let _e3597 = global.member_9;
            let _e3598 = _e3597.xyz;
            let _e3600 = global.member_8;
            let _e3601 = _e3600.xyz;
            let _e3609 = global.member_8[3u];
            let _e3610 = (mix(_e3598, _e3601, vec3(((_e813.y * 0.5f) + 0.5f))) * _e3609);
            phi_21153_ = _e3610;
            phi_21141_ = ((vec2<f32>(-1.04f, 1.04f) * ((min((_e3584.x * _e3584.x), exp2((-9.28f * _e3330))) * _e3584.x) + _e3584.y)) + _e3584.zw);
            phi_21117_ = mix((mix(_e3598, _e3601, vec3(((reflect(-(_e823), _e3316).y * 0.5f) + 0.5f))) * _e3609), _e3610, vec3(_e3293));
        }
        let _e3622 = phi_21153_;
        let _e3624 = phi_21141_;
        let _e3626 = phi_21117_;
        phi_4165_ = _e1257;
        if _e1257 {
            let _e3629 = global.member_33[2u];
            phi_4165_ = (_e3629 > 0.5f);
        }
        let _e3632 = phi_4165_;
        phi_21162_ = _e3626;
        if _e3632 {
            switch bitcast<i32>(0u) {
                default: {
                    let _e3635 = global.member_31;
                    let _e3636 = _e3635.xyz;
                    let _e3639 = global.member_33[0u];
                    let _e3644 = global.member_31[3u];
                    let _e3653 = global.member_32[1u];
                    let _e3659 = global.member_32[0u];
                    let _e3662 = (((_e3659 * (1f - smoothstep((_e3639 * 0.5f), _e3639, abs((dot(_e3636, _e821) - _e3644))))) * smoothstep(0.5f, 0.9f, dot(_e828, _e3636))) * (1f - smoothstep((_e3653 * 0.5f), _e3653, _e3293)));
                    if (_e3662 <= 0f) {
                        phi_21138_ = _e3626;
                        break;
                    }
                    let _e3669 = global.member_32[3u];
                    let _e3671 = (_e821 + ((_e813 - (_e3636 * dot(_e813, _e3636))) * _e3669));
                    let _e3673 = global.member_30;
                    let _e3678 = (_e3673 * vec4<f32>(_e3671.x, _e3671.y, _e3671.z, 1f));
                    let _e3690 = global.member_32[2u];
                    phi_21137_ = 0f;
                    phi_21136_ = vec3<f32>(0f, 0f, 0f);
                    phi_21135_ = 0i;
                    loop {
                        let _e3693 = phi_21137_;
                        let _e3695 = phi_21136_;
                        let _e3697 = phi_21135_;
                        local_46 = _e3695;
                        local_47 = _e3693;
                        if (_e3697 < 12i) {
                            continue;
                        } else {
                            break;
                        }
                        continuing {
                            let _e3699 = f32(_e3697);
                            let _e3704 = (_e3699 * 2.3999631f);
                            let _e3708 = global.member_33[1u];
                            let _e3713 = ((((vec2<f32>(_e3678.x, -(_e3678.y)) / vec2(_e3678.w)) * 0.5f) + vec2<f32>(0.5f, 0.5f)) + (vec2<f32>((cos(_e3704) * _e3708), sin(_e3704)) * (sqrt(((_e3699 + 0.5f) * 0.083333336f)) * (_e3690 * _e3293))));
                            let _e3715 = min(_e3713, (vec2<f32>(1f, 1f) - _e3713));
                            let _e3719 = smoothstep(0f, 0.04f, min(_e3715.x, _e3715.y));
                            let _e3721 = textureSampleLevel(global_19, global_5, clamp(_e3713, vec2<f32>(0f, 0f), vec2<f32>(1f, 1f)), 0f);
                            let _e3722 = _e3721.xyz;
                            phi_21137_ = (_e3693 + (_e3721.w * _e3719));
                            phi_21136_ = (_e3695 + ((_e3722 / (vec3<f32>(1f, 1f, 1f) - min(_e3722, vec3<f32>(0.995f, 0.995f, 0.995f)))) * _e3719));
                            phi_21135_ = (_e3697 + 1i);
                        }
                    }
                    let _e3733 = local_46;
                    let _e3736 = local_47;
                    phi_21138_ = mix(_e3626, ((_e3733 * vec3<f32>(0.083333336f, 0.083333336f, 0.083333336f)) + (_e3626 * (1f - (_e3736 * 0.083333336f)))), vec3(_e3662));
                    break;
                }
            }
            let _e3744 = phi_21138_;
            phi_21162_ = _e3744;
        }
        let _e3746 = phi_21162_;
        let _e3751 = ((_e3298 * _e3624.x) + vec3(_e3624.y));
        let _e3753 = ((vec3<f32>(1f, 1f, 1f) - _e3751) * _e3296);
        let _e3758 = (_e3385 + (((_e3753 * _e3622) + (_e3751 * _e3746)) * _e1275));
        let _e3761 = global.member_34[0u];
        let _e3764 = global.member_34[1u];
        phi_21664_ = _e3758;
        if ((_e3761 + _e3764) > 0.5f) {
            if (_e3764 > 0.5f) {
                phi_21198_ = _e3622;
                phi_21197_ = 0i;
                loop {
                    let _e3771 = phi_21198_;
                    let _e3773 = phi_21197_;
                    local_62 = _e3771;
                    if (_e3773 < i32(_e3764)) {
                        let _e3776 = (8i * (i32(_e3761) + _e3773));
                        let _e3780 = global_3.member[(_e3776 + 3i)];
                        let _e3781 = bitcast<vec4<f32>>(_e3780);
                        let _e3784 = global_3.member[_e3776];
                        let _e3785 = bitcast<vec4<f32>>(_e3784);
                        let _e3789 = global_3.member[(_e3776 + 1i)];
                        let _e3790 = bitcast<vec4<f32>>(_e3789);
                        let _e3794 = global_3.member[(_e3776 + 2i)];
                        let _e3795 = bitcast<vec4<f32>>(_e3794);
                        let _e3796 = _e3785.xyz;
                        let _e3800 = _e3790.xyz;
                        let _e3804 = _e3795.xyz;
                        let _e3808 = vec3<f32>((dot(_e3796, _e821) + _e3785.w), (dot(_e3800, _e821) + _e3790.w), (dot(_e3804, _e821) + _e3795.w));
                        let _e3809 = _e3781.xyz;
                        switch bitcast<i32>(0u) {
                            default: {
                                let _e3813 = (_e3809 - abs(_e3808));
                                let _e3818 = min(_e3813.x, min(_e3813.y, _e3813.z));
                                if (_e3818 <= 0f) {
                                    phi_21698_ = 0f;
                                    break;
                                }
                                if (_e3781.w <= 0f) {
                                    phi_21698_ = 1f;
                                    break;
                                }
                                let _e3822 = min((_e3818 / _e3781.w), 1f);
                                phi_21698_ = ((_e3822 * _e3822) * (3f - (2f * _e3822)));
                                break;
                            }
                        }
                        let _e3828 = phi_21698_;
                        if (_e3828 <= 0f) {
                            phi_22116_ = _e3771;
                            continue;
                        }
                        let _e3833 = global_3.member[(_e3776 + 4i)];
                        let _e3835 = bitcast<vec4<f32>>(_e3833).xyz;
                        let _e3839 = global_3.member[(_e3776 + 5i)];
                        let _e3840 = bitcast<vec4<f32>>(_e3839);
                        let _e3845 = global_3.member[(_e3776 + 6i)][0u];
                        let _e3846 = bitcast<i32>(_e3845);
                        let _e3847 = dot(_e3796, _e813);
                        let _e3848 = dot(_e3800, _e813);
                        let _e3849 = dot(_e3804, _e813);
                        let _e3850 = vec3<f32>(_e3847, _e3848, _e3849);
                        let _e3856 = ((_e821 + (_e813 * _e3840.x)) + (_e823 * _e3840.y));
                        let _e3871 = clamp(((((vec3<f32>((dot(_e3796, _e3856) + _e3785.w), (dot(_e3800, _e3856) + _e3790.w), (dot(_e3804, _e3856) + _e3795.w)) + _e3809) / max((_e3809 * 2f), vec3<f32>(0.000001f, 0.000001f, 0.000001f))) * _e3835) - vec3<f32>(0.5f, 0.5f, 0.5f)), vec3<f32>(0f, 0f, 0f), (_e3835 - vec3<f32>(1f, 1f, 1f)));
                        let _e3872 = vec3<i32>(_e3835);
                        let _e3876 = min(vec3<i32>(_e3871), max((_e3872 - vec3<i32>(2i, 2i, 2i)), vec3<i32>(0i, 0i, 0i)));
                        let _e3878 = (_e3871 - vec3<f32>(_e3876));
                        let _e3879 = (0.488603f * _e3848);
                        let _e3880 = (0.488603f * _e3849);
                        let _e3881 = (0.488603f * _e3847);
                        let _e3882 = (1.092548f * _e3847);
                        let _e3883 = (_e3882 * _e3848);
                        let _e3885 = ((1.092548f * _e3848) * _e3849);
                        let _e3889 = (0.315392f * (((3f * _e3849) * _e3849) - 1f));
                        let _e3890 = (_e3882 * _e3849);
                        let _e3894 = (0.546274f * ((_e3847 * _e3847) - (_e3848 * _e3848)));
                        let _e3895 = (_e3872 - vec3<i32>(1i, 1i, 1i));
                        let _e3896 = min(_e3876, _e3895);
                        let _e3907 = (_e3846 + ((_e3896.x + (_e3872.x * (_e3896.y + (_e3872.y * _e3896.z)))) * 4i));
                        let _e3908 = (vec3<f32>(1f, 1f, 1f) - _e3878);
                        let _e3915 = ((((((vec3<f32>(_e3896) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e3835) * _e3809) * 2f) - _e3809) - _e3808);
                        let _e3921 = (dot((_e3915 * inverseSqrt(max(dot(_e3915, _e3915), 0.0000000001f))), _e3850) + 1f);
                        let _e3924 = (_e3908.x * _e3908.y);
                        let _e3931 = (_e3907 + 3i);
                        let _e3935 = global_3.member[_e3931][1u];
                        let _e3940 = (((_e3924 * _e3908.z) * ((0.25f * (_e3921 * _e3921)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e3935).y > 0.5f)));
                        let _e3943 = global_3.member[_e3907];
                        let _e3947 = global_3.member[(_e3907 + 1i)];
                        let _e3951 = global_3.member[(_e3907 + 2i)];
                        let _e3954 = global_3.member[_e3931];
                        let _e3956 = unpack2x16float(_e3943.x);
                        let _e3958 = unpack2x16float(_e3943.y);
                        let _e3960 = unpack2x16float(_e3943.z);
                        let _e3962 = unpack2x16float(_e3943.w);
                        let _e3964 = unpack2x16float(_e3947.x);
                        let _e3966 = unpack2x16float(_e3947.y);
                        let _e3968 = unpack2x16float(_e3947.z);
                        let _e3970 = unpack2x16float(_e3947.w);
                        let _e3972 = unpack2x16float(_e3951.x);
                        let _e3974 = unpack2x16float(_e3951.y);
                        let _e3976 = unpack2x16float(_e3951.z);
                        let _e3978 = unpack2x16float(_e3951.w);
                        let _e3980 = unpack2x16float(_e3954.x);
                        let _e4036 = ((((((((((vec3<f32>(_e3956.x, _e3956.y, _e3958.x) * 0.282095f) + (vec3<f32>(_e3958.y, _e3960.x, _e3960.y) * _e3879)) + (vec3<f32>(_e3962.x, _e3962.y, _e3964.x) * _e3880)) + (vec3<f32>(_e3964.y, _e3966.x, _e3966.y) * _e3881)) + (vec3<f32>(_e3968.x, _e3968.y, _e3970.x) * _e3883)) + (vec3<f32>(_e3970.y, _e3972.x, _e3972.y) * _e3885)) + (vec3<f32>(_e3974.x, _e3974.y, _e3976.x) * _e3889)) + (vec3<f32>(_e3976.y, _e3978.x, _e3978.y) * _e3890)) + (vec3<f32>(_e3980.x, _e3980.y, unpack2x16float(_e3954.y).x) * _e3894)) * _e3940);
                        let _e4042 = min((_e3876 + vec3<i32>(1i, 0i, 0i)), _e3895);
                        let _e4051 = (_e3846 + ((_e4042.x + (_e3872.x * (_e4042.y + (_e3872.y * _e4042.z)))) * 4i));
                        let _e4058 = ((((((vec3<f32>(_e4042) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e3835) * _e3809) * 2f) - _e3809) - _e3808);
                        let _e4064 = (dot((_e4058 * inverseSqrt(max(dot(_e4058, _e4058), 0.0000000001f))), _e3850) + 1f);
                        let _e4066 = (_e3878.x * _e3908.y);
                        let _e4072 = (_e4051 + 3i);
                        let _e4076 = global_3.member[_e4072][1u];
                        let _e4081 = (((_e4066 * _e3908.z) * ((0.25f * (_e4064 * _e4064)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e4076).y > 0.5f)));
                        let _e4084 = global_3.member[_e4051];
                        let _e4088 = global_3.member[(_e4051 + 1i)];
                        let _e4092 = global_3.member[(_e4051 + 2i)];
                        let _e4095 = global_3.member[_e4072];
                        let _e4097 = unpack2x16float(_e4084.x);
                        let _e4099 = unpack2x16float(_e4084.y);
                        let _e4101 = unpack2x16float(_e4084.z);
                        let _e4103 = unpack2x16float(_e4084.w);
                        let _e4105 = unpack2x16float(_e4088.x);
                        let _e4107 = unpack2x16float(_e4088.y);
                        let _e4109 = unpack2x16float(_e4088.z);
                        let _e4111 = unpack2x16float(_e4088.w);
                        let _e4113 = unpack2x16float(_e4092.x);
                        let _e4115 = unpack2x16float(_e4092.y);
                        let _e4117 = unpack2x16float(_e4092.z);
                        let _e4119 = unpack2x16float(_e4092.w);
                        let _e4121 = unpack2x16float(_e4095.x);
                        let _e4177 = ((((((((((vec3<f32>(_e4097.x, _e4097.y, _e4099.x) * 0.282095f) + (vec3<f32>(_e4099.y, _e4101.x, _e4101.y) * _e3879)) + (vec3<f32>(_e4103.x, _e4103.y, _e4105.x) * _e3880)) + (vec3<f32>(_e4105.y, _e4107.x, _e4107.y) * _e3881)) + (vec3<f32>(_e4109.x, _e4109.y, _e4111.x) * _e3883)) + (vec3<f32>(_e4111.y, _e4113.x, _e4113.y) * _e3885)) + (vec3<f32>(_e4115.x, _e4115.y, _e4117.x) * _e3889)) + (vec3<f32>(_e4117.y, _e4119.x, _e4119.y) * _e3890)) + (vec3<f32>(_e4121.x, _e4121.y, unpack2x16float(_e4095.y).x) * _e3894)) * _e4081);
                        let _e4184 = min((_e3876 + vec3<i32>(0i, 1i, 0i)), _e3895);
                        let _e4193 = (_e3846 + ((_e4184.x + (_e3872.x * (_e4184.y + (_e3872.y * _e4184.z)))) * 4i));
                        let _e4200 = ((((((vec3<f32>(_e4184) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e3835) * _e3809) * 2f) - _e3809) - _e3808);
                        let _e4206 = (dot((_e4200 * inverseSqrt(max(dot(_e4200, _e4200), 0.0000000001f))), _e3850) + 1f);
                        let _e4208 = (_e3908.x * _e3878.y);
                        let _e4214 = (_e4193 + 3i);
                        let _e4218 = global_3.member[_e4214][1u];
                        let _e4223 = (((_e4208 * _e3908.z) * ((0.25f * (_e4206 * _e4206)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e4218).y > 0.5f)));
                        let _e4226 = global_3.member[_e4193];
                        let _e4230 = global_3.member[(_e4193 + 1i)];
                        let _e4234 = global_3.member[(_e4193 + 2i)];
                        let _e4237 = global_3.member[_e4214];
                        let _e4239 = unpack2x16float(_e4226.x);
                        let _e4241 = unpack2x16float(_e4226.y);
                        let _e4243 = unpack2x16float(_e4226.z);
                        let _e4245 = unpack2x16float(_e4226.w);
                        let _e4247 = unpack2x16float(_e4230.x);
                        let _e4249 = unpack2x16float(_e4230.y);
                        let _e4251 = unpack2x16float(_e4230.z);
                        let _e4253 = unpack2x16float(_e4230.w);
                        let _e4255 = unpack2x16float(_e4234.x);
                        let _e4257 = unpack2x16float(_e4234.y);
                        let _e4259 = unpack2x16float(_e4234.z);
                        let _e4261 = unpack2x16float(_e4234.w);
                        let _e4263 = unpack2x16float(_e4237.x);
                        let _e4319 = ((((((((((vec3<f32>(_e4239.x, _e4239.y, _e4241.x) * 0.282095f) + (vec3<f32>(_e4241.y, _e4243.x, _e4243.y) * _e3879)) + (vec3<f32>(_e4245.x, _e4245.y, _e4247.x) * _e3880)) + (vec3<f32>(_e4247.y, _e4249.x, _e4249.y) * _e3881)) + (vec3<f32>(_e4251.x, _e4251.y, _e4253.x) * _e3883)) + (vec3<f32>(_e4253.y, _e4255.x, _e4255.y) * _e3885)) + (vec3<f32>(_e4257.x, _e4257.y, _e4259.x) * _e3889)) + (vec3<f32>(_e4259.y, _e4261.x, _e4261.y) * _e3890)) + (vec3<f32>(_e4263.x, _e4263.y, unpack2x16float(_e4237.y).x) * _e3894)) * _e4223);
                        let _e4326 = min((_e3876 + vec3<i32>(1i, 1i, 0i)), _e3895);
                        let _e4335 = (_e3846 + ((_e4326.x + (_e3872.x * (_e4326.y + (_e3872.y * _e4326.z)))) * 4i));
                        let _e4342 = ((((((vec3<f32>(_e4326) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e3835) * _e3809) * 2f) - _e3809) - _e3808);
                        let _e4348 = (dot((_e4342 * inverseSqrt(max(dot(_e4342, _e4342), 0.0000000001f))), _e3850) + 1f);
                        let _e4349 = (_e3878.x * _e3878.y);
                        let _e4355 = (_e4335 + 3i);
                        let _e4359 = global_3.member[_e4355][1u];
                        let _e4364 = (((_e4349 * _e3908.z) * ((0.25f * (_e4348 * _e4348)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e4359).y > 0.5f)));
                        let _e4367 = global_3.member[_e4335];
                        let _e4371 = global_3.member[(_e4335 + 1i)];
                        let _e4375 = global_3.member[(_e4335 + 2i)];
                        let _e4378 = global_3.member[_e4355];
                        let _e4380 = unpack2x16float(_e4367.x);
                        let _e4382 = unpack2x16float(_e4367.y);
                        let _e4384 = unpack2x16float(_e4367.z);
                        let _e4386 = unpack2x16float(_e4367.w);
                        let _e4388 = unpack2x16float(_e4371.x);
                        let _e4390 = unpack2x16float(_e4371.y);
                        let _e4392 = unpack2x16float(_e4371.z);
                        let _e4394 = unpack2x16float(_e4371.w);
                        let _e4396 = unpack2x16float(_e4375.x);
                        let _e4398 = unpack2x16float(_e4375.y);
                        let _e4400 = unpack2x16float(_e4375.z);
                        let _e4402 = unpack2x16float(_e4375.w);
                        let _e4404 = unpack2x16float(_e4378.x);
                        let _e4460 = ((((((((((vec3<f32>(_e4380.x, _e4380.y, _e4382.x) * 0.282095f) + (vec3<f32>(_e4382.y, _e4384.x, _e4384.y) * _e3879)) + (vec3<f32>(_e4386.x, _e4386.y, _e4388.x) * _e3880)) + (vec3<f32>(_e4388.y, _e4390.x, _e4390.y) * _e3881)) + (vec3<f32>(_e4392.x, _e4392.y, _e4394.x) * _e3883)) + (vec3<f32>(_e4394.y, _e4396.x, _e4396.y) * _e3885)) + (vec3<f32>(_e4398.x, _e4398.y, _e4400.x) * _e3889)) + (vec3<f32>(_e4400.y, _e4402.x, _e4402.y) * _e3890)) + (vec3<f32>(_e4404.x, _e4404.y, unpack2x16float(_e4378.y).x) * _e3894)) * _e4364);
                        let _e4467 = min((_e3876 + vec3<i32>(0i, 0i, 1i)), _e3895);
                        let _e4476 = (_e3846 + ((_e4467.x + (_e3872.x * (_e4467.y + (_e3872.y * _e4467.z)))) * 4i));
                        let _e4483 = ((((((vec3<f32>(_e4467) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e3835) * _e3809) * 2f) - _e3809) - _e3808);
                        let _e4489 = (dot((_e4483 * inverseSqrt(max(dot(_e4483, _e4483), 0.0000000001f))), _e3850) + 1f);
                        let _e4496 = (_e4476 + 3i);
                        let _e4500 = global_3.member[_e4496][1u];
                        let _e4505 = (((_e3924 * _e3878.z) * ((0.25f * (_e4489 * _e4489)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e4500).y > 0.5f)));
                        let _e4508 = global_3.member[_e4476];
                        let _e4512 = global_3.member[(_e4476 + 1i)];
                        let _e4516 = global_3.member[(_e4476 + 2i)];
                        let _e4519 = global_3.member[_e4496];
                        let _e4521 = unpack2x16float(_e4508.x);
                        let _e4523 = unpack2x16float(_e4508.y);
                        let _e4525 = unpack2x16float(_e4508.z);
                        let _e4527 = unpack2x16float(_e4508.w);
                        let _e4529 = unpack2x16float(_e4512.x);
                        let _e4531 = unpack2x16float(_e4512.y);
                        let _e4533 = unpack2x16float(_e4512.z);
                        let _e4535 = unpack2x16float(_e4512.w);
                        let _e4537 = unpack2x16float(_e4516.x);
                        let _e4539 = unpack2x16float(_e4516.y);
                        let _e4541 = unpack2x16float(_e4516.z);
                        let _e4543 = unpack2x16float(_e4516.w);
                        let _e4545 = unpack2x16float(_e4519.x);
                        let _e4601 = ((((((((((vec3<f32>(_e4521.x, _e4521.y, _e4523.x) * 0.282095f) + (vec3<f32>(_e4523.y, _e4525.x, _e4525.y) * _e3879)) + (vec3<f32>(_e4527.x, _e4527.y, _e4529.x) * _e3880)) + (vec3<f32>(_e4529.y, _e4531.x, _e4531.y) * _e3881)) + (vec3<f32>(_e4533.x, _e4533.y, _e4535.x) * _e3883)) + (vec3<f32>(_e4535.y, _e4537.x, _e4537.y) * _e3885)) + (vec3<f32>(_e4539.x, _e4539.y, _e4541.x) * _e3889)) + (vec3<f32>(_e4541.y, _e4543.x, _e4543.y) * _e3890)) + (vec3<f32>(_e4545.x, _e4545.y, unpack2x16float(_e4519.y).x) * _e3894)) * _e4505);
                        let _e4608 = min((_e3876 + vec3<i32>(1i, 0i, 1i)), _e3895);
                        let _e4617 = (_e3846 + ((_e4608.x + (_e3872.x * (_e4608.y + (_e3872.y * _e4608.z)))) * 4i));
                        let _e4624 = ((((((vec3<f32>(_e4608) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e3835) * _e3809) * 2f) - _e3809) - _e3808);
                        let _e4630 = (dot((_e4624 * inverseSqrt(max(dot(_e4624, _e4624), 0.0000000001f))), _e3850) + 1f);
                        let _e4636 = (_e4617 + 3i);
                        let _e4640 = global_3.member[_e4636][1u];
                        let _e4645 = (((_e4066 * _e3878.z) * ((0.25f * (_e4630 * _e4630)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e4640).y > 0.5f)));
                        let _e4648 = global_3.member[_e4617];
                        let _e4652 = global_3.member[(_e4617 + 1i)];
                        let _e4656 = global_3.member[(_e4617 + 2i)];
                        let _e4659 = global_3.member[_e4636];
                        let _e4661 = unpack2x16float(_e4648.x);
                        let _e4663 = unpack2x16float(_e4648.y);
                        let _e4665 = unpack2x16float(_e4648.z);
                        let _e4667 = unpack2x16float(_e4648.w);
                        let _e4669 = unpack2x16float(_e4652.x);
                        let _e4671 = unpack2x16float(_e4652.y);
                        let _e4673 = unpack2x16float(_e4652.z);
                        let _e4675 = unpack2x16float(_e4652.w);
                        let _e4677 = unpack2x16float(_e4656.x);
                        let _e4679 = unpack2x16float(_e4656.y);
                        let _e4681 = unpack2x16float(_e4656.z);
                        let _e4683 = unpack2x16float(_e4656.w);
                        let _e4685 = unpack2x16float(_e4659.x);
                        let _e4741 = ((((((((((vec3<f32>(_e4661.x, _e4661.y, _e4663.x) * 0.282095f) + (vec3<f32>(_e4663.y, _e4665.x, _e4665.y) * _e3879)) + (vec3<f32>(_e4667.x, _e4667.y, _e4669.x) * _e3880)) + (vec3<f32>(_e4669.y, _e4671.x, _e4671.y) * _e3881)) + (vec3<f32>(_e4673.x, _e4673.y, _e4675.x) * _e3883)) + (vec3<f32>(_e4675.y, _e4677.x, _e4677.y) * _e3885)) + (vec3<f32>(_e4679.x, _e4679.y, _e4681.x) * _e3889)) + (vec3<f32>(_e4681.y, _e4683.x, _e4683.y) * _e3890)) + (vec3<f32>(_e4685.x, _e4685.y, unpack2x16float(_e4659.y).x) * _e3894)) * _e4645);
                        let _e4748 = min((_e3876 + vec3<i32>(0i, 1i, 1i)), _e3895);
                        let _e4757 = (_e3846 + ((_e4748.x + (_e3872.x * (_e4748.y + (_e3872.y * _e4748.z)))) * 4i));
                        let _e4764 = ((((((vec3<f32>(_e4748) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e3835) * _e3809) * 2f) - _e3809) - _e3808);
                        let _e4770 = (dot((_e4764 * inverseSqrt(max(dot(_e4764, _e4764), 0.0000000001f))), _e3850) + 1f);
                        let _e4776 = (_e4757 + 3i);
                        let _e4780 = global_3.member[_e4776][1u];
                        let _e4785 = (((_e4208 * _e3878.z) * ((0.25f * (_e4770 * _e4770)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e4780).y > 0.5f)));
                        let _e4788 = global_3.member[_e4757];
                        let _e4792 = global_3.member[(_e4757 + 1i)];
                        let _e4796 = global_3.member[(_e4757 + 2i)];
                        let _e4799 = global_3.member[_e4776];
                        let _e4801 = unpack2x16float(_e4788.x);
                        let _e4803 = unpack2x16float(_e4788.y);
                        let _e4805 = unpack2x16float(_e4788.z);
                        let _e4807 = unpack2x16float(_e4788.w);
                        let _e4809 = unpack2x16float(_e4792.x);
                        let _e4811 = unpack2x16float(_e4792.y);
                        let _e4813 = unpack2x16float(_e4792.z);
                        let _e4815 = unpack2x16float(_e4792.w);
                        let _e4817 = unpack2x16float(_e4796.x);
                        let _e4819 = unpack2x16float(_e4796.y);
                        let _e4821 = unpack2x16float(_e4796.z);
                        let _e4823 = unpack2x16float(_e4796.w);
                        let _e4825 = unpack2x16float(_e4799.x);
                        let _e4881 = ((((((((((vec3<f32>(_e4801.x, _e4801.y, _e4803.x) * 0.282095f) + (vec3<f32>(_e4803.y, _e4805.x, _e4805.y) * _e3879)) + (vec3<f32>(_e4807.x, _e4807.y, _e4809.x) * _e3880)) + (vec3<f32>(_e4809.y, _e4811.x, _e4811.y) * _e3881)) + (vec3<f32>(_e4813.x, _e4813.y, _e4815.x) * _e3883)) + (vec3<f32>(_e4815.y, _e4817.x, _e4817.y) * _e3885)) + (vec3<f32>(_e4819.x, _e4819.y, _e4821.x) * _e3889)) + (vec3<f32>(_e4821.y, _e4823.x, _e4823.y) * _e3890)) + (vec3<f32>(_e4825.x, _e4825.y, unpack2x16float(_e4799.y).x) * _e3894)) * _e4785);
                        let _e4888 = min((_e3876 + vec3<i32>(1i, 1i, 1i)), _e3895);
                        let _e4897 = (_e3846 + ((_e4888.x + (_e3872.x * (_e4888.y + (_e3872.y * _e4888.z)))) * 4i));
                        let _e4904 = ((((((vec3<f32>(_e4888) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e3835) * _e3809) * 2f) - _e3809) - _e3808);
                        let _e4910 = (dot((_e4904 * inverseSqrt(max(dot(_e4904, _e4904), 0.0000000001f))), _e3850) + 1f);
                        let _e4916 = (_e4897 + 3i);
                        let _e4920 = global_3.member[_e4916][1u];
                        let _e4925 = (((_e4349 * _e3878.z) * ((0.25f * (_e4910 * _e4910)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e4920).y > 0.5f)));
                        let _e4928 = global_3.member[_e4897];
                        let _e4932 = global_3.member[(_e4897 + 1i)];
                        let _e4936 = global_3.member[(_e4897 + 2i)];
                        let _e4939 = global_3.member[_e4916];
                        let _e4941 = unpack2x16float(_e4928.x);
                        let _e4943 = unpack2x16float(_e4928.y);
                        let _e4945 = unpack2x16float(_e4928.z);
                        let _e4947 = unpack2x16float(_e4928.w);
                        let _e4949 = unpack2x16float(_e4932.x);
                        let _e4951 = unpack2x16float(_e4932.y);
                        let _e4953 = unpack2x16float(_e4932.z);
                        let _e4955 = unpack2x16float(_e4932.w);
                        let _e4957 = unpack2x16float(_e4936.x);
                        let _e4959 = unpack2x16float(_e4936.y);
                        let _e4961 = unpack2x16float(_e4936.z);
                        let _e4963 = unpack2x16float(_e4936.w);
                        let _e4965 = unpack2x16float(_e4939.x);
                        let _e5021 = ((((((((((vec3<f32>(_e4941.x, _e4941.y, _e4943.x) * 0.282095f) + (vec3<f32>(_e4943.y, _e4945.x, _e4945.y) * _e3879)) + (vec3<f32>(_e4947.x, _e4947.y, _e4949.x) * _e3880)) + (vec3<f32>(_e4949.y, _e4951.x, _e4951.y) * _e3881)) + (vec3<f32>(_e4953.x, _e4953.y, _e4955.x) * _e3883)) + (vec3<f32>(_e4955.y, _e4957.x, _e4957.y) * _e3885)) + (vec3<f32>(_e4959.x, _e4959.y, _e4961.x) * _e3889)) + (vec3<f32>(_e4961.y, _e4963.x, _e4963.y) * _e3890)) + (vec3<f32>(_e4965.x, _e4965.y, unpack2x16float(_e4939.y).x) * _e3894)) * _e4925);
                        let _e5026 = (((((((vec4<f32>(_e4036.x, _e4036.y, _e4036.z, _e3940) + vec4<f32>(_e4177.x, _e4177.y, _e4177.z, _e4081)) + vec4<f32>(_e4319.x, _e4319.y, _e4319.z, _e4223)) + vec4<f32>(_e4460.x, _e4460.y, _e4460.z, _e4364)) + vec4<f32>(_e4601.x, _e4601.y, _e4601.z, _e4505)) + vec4<f32>(_e4741.x, _e4741.y, _e4741.z, _e4645)) + vec4<f32>(_e4881.x, _e4881.y, _e4881.z, _e4785)) + vec4<f32>(_e5021.x, _e5021.y, _e5021.z, _e4925));
                        phi_22117_ = _e3771;
                        if (_e5026.w > 0.00001f) {
                            phi_22117_ = mix(_e3771, ((max(_e5026.xyz, vec3<f32>(0f, 0f, 0f)) / vec3(_e5026.w)) * _e3840.z), vec3(_e3828));
                        }
                        let _e5038 = phi_22117_;
                        phi_22116_ = _e5038;
                        continue;
                    } else {
                        break;
                    }
                    continuing {
                        let _e5040 = phi_22116_;
                        phi_21198_ = _e5040;
                        phi_21197_ = (_e3773 + 1i);
                    }
                }
                let _e7897 = local_62;
                phi_21199_ = _e7897;
            } else {
                phi_21199_ = _e3622;
            }
            let _e5043 = phi_21199_;
            phi_21427_ = _e3746;
            if (_e3761 > 0.5f) {
                if _e3389 {
                    let _e5046 = reflect(-(_e823), _e3316);
                    let _e5048 = global.member_29;
                    let _e5067 = vec2<f32>(((atan2(((_e5048.z * _e5046.x) - (_e5048.w * _e5046.z)), -(((_e5048.w * _e5046.x) + (_e5048.z * _e5046.z)))) * 0.15915494f) + 0.5f), (acos(clamp(_e5046.y, -1f, 1f)) * 0.31830987f));
                    let _e5068 = (_e3293 * 5f);
                    let _e5070 = min(i32(_e5068), 4i);
                    local_9 = array<vec4<i32>, 6>(vec4<i32>(0i, 0i, 512i, 256i), vec4<i32>(0i, 256i, 256i, 128i), vec4<i32>(256i, 256i, 128i, 64i), vec4<i32>(384i, 256i, 64i, 32i), vec4<i32>(448i, 256i, 32i, 16i), vec4<i32>(480i, 256i, 16i, 8i));
                    let _e5072 = local_9[_e5070];
                    let _e5076 = ((_e5067 * vec2<f32>(_e5072.zw)) - vec2<f32>(0.5f, 0.5f));
                    let _e5077 = floor(_e5076);
                    let _e5078 = (_e5076 - _e5077);
                    let _e5080 = i32(_e5077.x);
                    let _e5082 = i32(_e5077.y);
                    phi_21222_ = _e5080;
                    if (_e5080 < 0i) {
                        phi_21222_ = (_e5080 + _e5072.z);
                    }
                    let _e5087 = phi_21222_;
                    phi_21223_ = _e5087;
                    if (_e5087 >= _e5072.z) {
                        phi_21223_ = (_e5087 - _e5072.z);
                    }
                    let _e5092 = phi_21223_;
                    let _e5093 = (_e5092 + 1i);
                    let _e5095 = select(_e5093, 0i, (_e5093 == _e5072.z));
                    let _e5099 = min((_e5082 + 1i), (_e5072.w - 1i));
                    let _e5100 = max(_e5082, 0i);
                    let _e5101 = _e5072.xy;
                    let _e5104 = textureLoad(global_4, (_e5101 + vec2<i32>(_e5092, _e5100)), 0i);
                    let _e5108 = textureLoad(global_4, (_e5101 + vec2<i32>(_e5095, _e5100)), 0i);
                    let _e5112 = textureLoad(global_4, (_e5101 + vec2<i32>(_e5092, _e5099)), 0i);
                    let _e5116 = textureLoad(global_4, (_e5101 + vec2<i32>(_e5095, _e5099)), 0i);
                    let _e5119 = vec3(_e5078.x);
                    local_10 = array<vec4<i32>, 6>(vec4<i32>(0i, 0i, 512i, 256i), vec4<i32>(0i, 256i, 256i, 128i), vec4<i32>(256i, 256i, 128i, 64i), vec4<i32>(384i, 256i, 64i, 32i), vec4<i32>(448i, 256i, 32i, 16i), vec4<i32>(480i, 256i, 16i, 8i));
                    let _e5127 = local_10[(_e5070 + 1i)];
                    let _e5131 = ((_e5067 * vec2<f32>(_e5127.zw)) - vec2<f32>(0.5f, 0.5f));
                    let _e5132 = floor(_e5131);
                    let _e5133 = (_e5131 - _e5132);
                    let _e5135 = i32(_e5132.x);
                    let _e5137 = i32(_e5132.y);
                    phi_21229_ = _e5135;
                    if (_e5135 < 0i) {
                        phi_21229_ = (_e5135 + _e5127.z);
                    }
                    let _e5142 = phi_21229_;
                    phi_21230_ = _e5142;
                    if (_e5142 >= _e5127.z) {
                        phi_21230_ = (_e5142 - _e5127.z);
                    }
                    let _e5147 = phi_21230_;
                    let _e5148 = (_e5147 + 1i);
                    let _e5150 = select(_e5148, 0i, (_e5148 == _e5127.z));
                    let _e5154 = min((_e5137 + 1i), (_e5127.w - 1i));
                    let _e5155 = max(_e5137, 0i);
                    let _e5156 = _e5127.xy;
                    let _e5159 = textureLoad(global_4, (_e5156 + vec2<i32>(_e5147, _e5155)), 0i);
                    let _e5163 = textureLoad(global_4, (_e5156 + vec2<i32>(_e5150, _e5155)), 0i);
                    let _e5167 = textureLoad(global_4, (_e5156 + vec2<i32>(_e5147, _e5154)), 0i);
                    let _e5171 = textureLoad(global_4, (_e5156 + vec2<i32>(_e5150, _e5154)), 0i);
                    let _e5174 = vec3(_e5133.x);
                    let _e5186 = global.member_29[1u];
                    phi_21236_ = (mix(mix(mix(_e5104.xyz, _e5108.xyz, _e5119), mix(_e5112.xyz, _e5116.xyz, _e5119), vec3(_e5078.y)), mix(mix(_e5159.xyz, _e5163.xyz, _e5174), mix(_e5167.xyz, _e5171.xyz, _e5174), vec3(_e5133.y)), vec3((_e5068 - f32(_e5070)))) * _e5186);
                } else {
                    let _e5191 = global.member_9;
                    let _e5194 = global.member_8;
                    let _e5203 = global.member_8[3u];
                    phi_21236_ = mix((mix(_e5191.xyz, _e5194.xyz, vec3(((reflect(-(_e823), _e3316).y * 0.5f) + 0.5f))) * _e5203), _e3622, vec3(_e3293));
                }
                let _e5208 = phi_21236_;
                let _e5210 = reflect(-(_e823), _e3316);
                phi_21318_ = vec3<f32>(0f, 0f, 0f);
                phi_21252_ = 0f;
                phi_21251_ = 0i;
                loop {
                    let _e5213 = phi_21318_;
                    let _e5215 = phi_21252_;
                    let _e5217 = phi_21251_;
                    local_48 = _e5215;
                    local_49 = _e5213;
                    if (_e5217 < i32(_e3761)) {
                        if (_e5215 > 0.999f) {
                            break;
                        }
                        let _e5220 = (_e5217 * 8i);
                        let _e5223 = global_3.member[_e5220];
                        let _e5224 = bitcast<vec4<f32>>(_e5223);
                        let _e5228 = global_3.member[(_e5220 + 1i)];
                        let _e5229 = bitcast<vec4<f32>>(_e5228);
                        let _e5233 = global_3.member[(_e5220 + 2i)];
                        let _e5234 = bitcast<vec4<f32>>(_e5233);
                        let _e5235 = _e5224.xyz;
                        let _e5239 = _e5229.xyz;
                        let _e5243 = _e5234.xyz;
                        let _e5247 = vec3<f32>((dot(_e5235, _e821) + _e5224.w), (dot(_e5239, _e821) + _e5229.w), (dot(_e5243, _e821) + _e5234.w));
                        let _e5251 = global_3.member[(_e5220 + 3i)];
                        let _e5252 = bitcast<vec4<f32>>(_e5251);
                        switch bitcast<i32>(0u) {
                            default: {
                                let _e5257 = (_e5252.xyz - abs(_e5247));
                                let _e5262 = min(_e5257.x, min(_e5257.y, _e5257.z));
                                if (_e5262 <= 0f) {
                                    phi_21253_ = 0f;
                                    break;
                                }
                                if (_e5252.w <= 0f) {
                                    phi_21253_ = 1f;
                                    break;
                                }
                                let _e5266 = min((_e5262 / _e5252.w), 1f);
                                phi_21253_ = ((_e5266 * _e5266) * (3f - (2f * _e5266)));
                                break;
                            }
                        }
                        let _e5272 = phi_21253_;
                        if (_e5272 <= 0f) {
                            phi_22131_ = _e5213;
                            phi_22130_ = _e5215;
                            continue;
                        }
                        let _e5277 = global_3.member[(_e5220 + 4i)];
                        let _e5278 = bitcast<vec4<f32>>(_e5277);
                        let _e5282 = global_3.member[(_e5220 + 5i)];
                        let _e5283 = bitcast<vec4<f32>>(_e5282);
                        let _e5287 = vec3<f32>(dot(_e5235, _e5210), dot(_e5239, _e5210), dot(_e5243, _e5210));
                        if (_e5278.w > 0.5f) {
                            let _e5290 = _e5278.xyz;
                            let _e5292 = -(_e5290);
                            let _e5293 = clamp(_e5247, _e5292, _e5290);
                            let _e5297 = step(vec3<f32>(0.000001f, 0.000001f, 0.000001f), abs(_e5287));
                            let _e5301 = mix(vec3<f32>(1000000000000000000000000000000f, 1000000000000000000000000000000f, 1000000000000000000000000000000f), ((mix(_e5292, _e5290, step(vec3<f32>(0f, 0f, 0f), _e5287)) - _e5293) / mix(vec3<f32>(0.000001f, 0.000001f, 0.000001f), _e5287, _e5297)), _e5297);
                            let _e5310 = ((_e5293 + (_e5287 * max(min(_e5301.x, min(_e5301.y, _e5301.z)), 0f))) - _e5283.xyz);
                            if (dot(_e5310, _e5310) > 0.000000000001f) {
                                phi_21254_ = normalize(_e5310);
                            } else {
                                phi_21254_ = _e5287;
                            }
                            let _e5315 = phi_21254_;
                            phi_21255_ = _e5315;
                        } else {
                            phi_21255_ = _e5287;
                        }
                        let _e5317 = phi_21255_;
                        let _e5322 = global_3.member[(_e5220 + 6i)][0u];
                        let _e5323 = bitcast<i32>(_e5322);
                        let _e5334 = vec2<f32>(((atan2(_e5317.x, -(_e5317.z)) * 0.15915494f) + 0.5f), (acos(clamp(_e5317.y, -1f, 1f)) * 0.31830987f));
                        let _e5335 = (_e3293 * 5f);
                        let _e5337 = min(i32(_e5335), 4i);
                        local_8 = array<vec3<i32>, 6>(vec3<i32>(0i, 256i, 128i), vec3<i32>(32768i, 128i, 64i), vec3<i32>(40960i, 64i, 32i), vec3<i32>(43008i, 32i, 16i), vec3<i32>(43520i, 16i, 8i), vec3<i32>(43648i, 8i, 4i));
                        let _e5339 = local_8[_e5337];
                        let _e5341 = (_e5323 + _e5339.x);
                        let _e5345 = ((_e5334 * vec2<f32>(_e5339.yz)) - vec2<f32>(0.5f, 0.5f));
                        let _e5346 = floor(_e5345);
                        let _e5347 = (_e5345 - _e5346);
                        let _e5349 = i32(_e5346.x);
                        let _e5351 = i32(_e5346.y);
                        phi_21256_ = _e5349;
                        if (_e5349 < 0i) {
                            phi_21256_ = (_e5349 + _e5339.y);
                        }
                        let _e5356 = phi_21256_;
                        phi_21257_ = _e5356;
                        if (_e5356 >= _e5339.y) {
                            phi_21257_ = (_e5356 - _e5339.y);
                        }
                        let _e5361 = phi_21257_;
                        let _e5362 = (_e5361 + 1i);
                        let _e5364 = select(_e5362, 0i, (_e5362 == _e5339.y));
                        let _e5371 = (_e5341 + (max(_e5351, 0i) * _e5339.y));
                        let _e5372 = (_e5371 + _e5361);
                        let _e5377 = global_3.member[(_e5372 >> bitcast<u32>(1i))];
                        if ((_e5372 & 1i) == 0i) {
                            phi_21263_ = _e5377.xy;
                        } else {
                            phi_21263_ = _e5377.zw;
                        }
                        let _e5383 = phi_21263_;
                        let _e5385 = unpack2x16float(_e5383.x);
                        let _e5392 = (_e5371 + _e5364);
                        let _e5397 = global_3.member[(_e5392 >> bitcast<u32>(1i))];
                        if ((_e5392 & 1i) == 0i) {
                            phi_21265_ = _e5397.xy;
                        } else {
                            phi_21265_ = _e5397.zw;
                        }
                        let _e5403 = phi_21265_;
                        let _e5405 = unpack2x16float(_e5403.x);
                        let _e5413 = (_e5341 + (min((_e5351 + 1i), (_e5339.z - 1i)) * _e5339.y));
                        let _e5414 = (_e5413 + _e5361);
                        let _e5419 = global_3.member[(_e5414 >> bitcast<u32>(1i))];
                        if ((_e5414 & 1i) == 0i) {
                            phi_21268_ = _e5419.xy;
                        } else {
                            phi_21268_ = _e5419.zw;
                        }
                        let _e5425 = phi_21268_;
                        let _e5427 = unpack2x16float(_e5425.x);
                        let _e5434 = (_e5413 + _e5364);
                        let _e5439 = global_3.member[(_e5434 >> bitcast<u32>(1i))];
                        if ((_e5434 & 1i) == 0i) {
                            phi_21269_ = _e5439.xy;
                        } else {
                            phi_21269_ = _e5439.zw;
                        }
                        let _e5445 = phi_21269_;
                        let _e5447 = unpack2x16float(_e5445.x);
                        let _e5455 = vec3(_e5347.x);
                        local_7 = array<vec3<i32>, 6>(vec3<i32>(0i, 256i, 128i), vec3<i32>(32768i, 128i, 64i), vec3<i32>(40960i, 64i, 32i), vec3<i32>(43008i, 32i, 16i), vec3<i32>(43520i, 16i, 8i), vec3<i32>(43648i, 8i, 4i));
                        let _e5463 = local_7[(_e5337 + 1i)];
                        let _e5465 = (_e5323 + _e5463.x);
                        let _e5469 = ((_e5334 * vec2<f32>(_e5463.yz)) - vec2<f32>(0.5f, 0.5f));
                        let _e5470 = floor(_e5469);
                        let _e5471 = (_e5469 - _e5470);
                        let _e5473 = i32(_e5470.x);
                        let _e5475 = i32(_e5470.y);
                        phi_21270_ = _e5473;
                        if (_e5473 < 0i) {
                            phi_21270_ = (_e5473 + _e5463.y);
                        }
                        let _e5480 = phi_21270_;
                        phi_21271_ = _e5480;
                        if (_e5480 >= _e5463.y) {
                            phi_21271_ = (_e5480 - _e5463.y);
                        }
                        let _e5485 = phi_21271_;
                        let _e5486 = (_e5485 + 1i);
                        let _e5488 = select(_e5486, 0i, (_e5486 == _e5463.y));
                        let _e5495 = (_e5465 + (max(_e5475, 0i) * _e5463.y));
                        let _e5496 = (_e5495 + _e5485);
                        let _e5501 = global_3.member[(_e5496 >> bitcast<u32>(1i))];
                        if ((_e5496 & 1i) == 0i) {
                            phi_21277_ = _e5501.xy;
                        } else {
                            phi_21277_ = _e5501.zw;
                        }
                        let _e5507 = phi_21277_;
                        let _e5509 = unpack2x16float(_e5507.x);
                        let _e5516 = (_e5495 + _e5488);
                        let _e5521 = global_3.member[(_e5516 >> bitcast<u32>(1i))];
                        if ((_e5516 & 1i) == 0i) {
                            phi_21279_ = _e5521.xy;
                        } else {
                            phi_21279_ = _e5521.zw;
                        }
                        let _e5527 = phi_21279_;
                        let _e5529 = unpack2x16float(_e5527.x);
                        let _e5537 = (_e5465 + (min((_e5475 + 1i), (_e5463.z - 1i)) * _e5463.y));
                        let _e5538 = (_e5537 + _e5485);
                        let _e5543 = global_3.member[(_e5538 >> bitcast<u32>(1i))];
                        if ((_e5538 & 1i) == 0i) {
                            phi_21282_ = _e5543.xy;
                        } else {
                            phi_21282_ = _e5543.zw;
                        }
                        let _e5549 = phi_21282_;
                        let _e5551 = unpack2x16float(_e5549.x);
                        let _e5558 = (_e5537 + _e5488);
                        let _e5563 = global_3.member[(_e5558 >> bitcast<u32>(1i))];
                        if ((_e5558 & 1i) == 0i) {
                            phi_21283_ = _e5563.xy;
                        } else {
                            phi_21283_ = _e5563.zw;
                        }
                        let _e5569 = phi_21283_;
                        let _e5571 = unpack2x16float(_e5569.x);
                        let _e5579 = vec3(_e5471.x);
                        let _e5592 = (_e5272 * (1f - _e5215));
                        phi_22131_ = (_e5213 + ((mix(mix(mix(vec3<f32>(_e5385.x, _e5385.y, unpack2x16float(_e5383.y).x), vec3<f32>(_e5405.x, _e5405.y, unpack2x16float(_e5403.y).x), _e5455), mix(vec3<f32>(_e5427.x, _e5427.y, unpack2x16float(_e5425.y).x), vec3<f32>(_e5447.x, _e5447.y, unpack2x16float(_e5445.y).x), _e5455), vec3(_e5347.y)), mix(mix(vec3<f32>(_e5509.x, _e5509.y, unpack2x16float(_e5507.y).x), vec3<f32>(_e5529.x, _e5529.y, unpack2x16float(_e5527.y).x), _e5579), mix(vec3<f32>(_e5551.x, _e5551.y, unpack2x16float(_e5549.y).x), vec3<f32>(_e5571.x, _e5571.y, unpack2x16float(_e5569.y).x), _e5579), vec3(_e5471.y)), vec3((_e5335 - f32(_e5337)))) * _e5283.w) * _e5592));
                        phi_22130_ = (_e5215 + _e5592);
                        continue;
                    } else {
                        break;
                    }
                    continuing {
                        let _e5597 = phi_22131_;
                        let _e5599 = phi_22130_;
                        phi_21318_ = _e5597;
                        phi_21252_ = _e5599;
                        phi_21251_ = (_e5217 + 1i);
                    }
                }
                let _e5602 = local_48;
                let _e5606 = local_49;
                let _e5607 = (_e5606 + (_e5208 * (1f - _e5602)));
                phi_4283_ = _e1257;
                if _e1257 {
                    let _e5610 = global.member_33[2u];
                    phi_4283_ = (_e5610 > 0.5f);
                }
                let _e5613 = phi_4283_;
                phi_21428_ = _e5607;
                if _e5613 {
                    switch bitcast<i32>(0u) {
                        default: {
                            let _e5616 = global.member_31;
                            let _e5617 = _e5616.xyz;
                            let _e5620 = global.member_33[0u];
                            let _e5625 = global.member_31[3u];
                            let _e5634 = global.member_32[1u];
                            let _e5640 = global.member_32[0u];
                            let _e5643 = (((_e5640 * (1f - smoothstep((_e5620 * 0.5f), _e5620, abs((dot(_e5617, _e821) - _e5625))))) * smoothstep(0.5f, 0.9f, dot(_e828, _e5617))) * (1f - smoothstep((_e5634 * 0.5f), _e5634, _e3293)));
                            if (_e5643 <= 0f) {
                                phi_21394_ = _e5607;
                                break;
                            }
                            let _e5650 = global.member_32[3u];
                            let _e5652 = (_e821 + ((_e813 - (_e5617 * dot(_e813, _e5617))) * _e5650));
                            let _e5654 = global.member_30;
                            let _e5659 = (_e5654 * vec4<f32>(_e5652.x, _e5652.y, _e5652.z, 1f));
                            let _e5671 = global.member_32[2u];
                            phi_21393_ = 0f;
                            phi_21392_ = vec3<f32>(0f, 0f, 0f);
                            phi_21391_ = 0i;
                            loop {
                                let _e5674 = phi_21393_;
                                let _e5676 = phi_21392_;
                                let _e5678 = phi_21391_;
                                local_50 = _e5676;
                                local_51 = _e5674;
                                if (_e5678 < 12i) {
                                    continue;
                                } else {
                                    break;
                                }
                                continuing {
                                    let _e5680 = f32(_e5678);
                                    let _e5685 = (_e5680 * 2.3999631f);
                                    let _e5689 = global.member_33[1u];
                                    let _e5694 = ((((vec2<f32>(_e5659.x, -(_e5659.y)) / vec2(_e5659.w)) * 0.5f) + vec2<f32>(0.5f, 0.5f)) + (vec2<f32>((cos(_e5685) * _e5689), sin(_e5685)) * (sqrt(((_e5680 + 0.5f) * 0.083333336f)) * (_e5671 * _e3293))));
                                    let _e5696 = min(_e5694, (vec2<f32>(1f, 1f) - _e5694));
                                    let _e5700 = smoothstep(0f, 0.04f, min(_e5696.x, _e5696.y));
                                    let _e5702 = textureSampleLevel(global_19, global_5, clamp(_e5694, vec2<f32>(0f, 0f), vec2<f32>(1f, 1f)), 0f);
                                    let _e5703 = _e5702.xyz;
                                    phi_21393_ = (_e5674 + (_e5702.w * _e5700));
                                    phi_21392_ = (_e5676 + ((_e5703 / (vec3<f32>(1f, 1f, 1f) - min(_e5703, vec3<f32>(0.995f, 0.995f, 0.995f)))) * _e5700));
                                    phi_21391_ = (_e5678 + 1i);
                                }
                            }
                            let _e5714 = local_50;
                            let _e5717 = local_51;
                            phi_21394_ = mix(_e5607, ((_e5714 * vec3<f32>(0.083333336f, 0.083333336f, 0.083333336f)) + (_e5607 * (1f - (_e5717 * 0.083333336f)))), vec3(_e5643));
                            break;
                        }
                    }
                    let _e5725 = phi_21394_;
                    phi_21428_ = _e5725;
                }
                let _e5727 = phi_21428_;
                phi_21427_ = _e5727;
            }
            let _e5729 = phi_21427_;
            phi_21664_ = (_e3758 + (((_e3753 * (_e5043 - _e3622)) + (_e3751 * (_e5729 - _e3746))) * _e1275));
        }
        let _e5738 = phi_21664_;
        let _e5741 = global.member_13[3u];
        phi_21734_ = _e5738;
        if (_e5741 > 0.5f) {
            let _e5744 = global.member_11;
            let _e5749 = global.member_11[3u];
            let _e5751 = global_16;
            let _e5754 = global.member_12;
            let _e5759 = global.member_13;
            let _e5762 = clamp(floor((_e5751.xy * _e5754.xy)), vec2<f32>(0f, 0f), (_e5759.xy - vec2<f32>(1f, 1f)));
            let _e5767 = global.member_12[2u];
            let _e5771 = global.member_12[3u];
            let _e5776 = global.member_13[2u];
            let _e5781 = global.member_13[1u];
            let _e5787 = global.member_13[0u];
            let _e5791 = u32(((((clamp(floor(((log2(max((dot(_e5744.xyz, _e821) + _e5749), 0.000001f)) * _e5767) + _e5771)), 0f, (_e5776 - 1f)) * _e5781) + _e5762.y) * _e5787) + _e5762.x));
            let _e5798 = global_17.member[(_e5791 >> bitcast<u32>(2i))][(_e5791 & 3u)];
            let _e5799 = (_e5798 & 65535u);
            phi_21663_ = _e5738;
            phi_21529_ = _e5799;
            loop {
                let _e5803 = phi_21663_;
                let _e5805 = phi_21529_;
                local_66 = _e5803;
                if (_e5805 < (_e5799 + (_e5798 >> bitcast<u32>(16i)))) {
                    let _e5808 = (_e5805 / 3u);
                    let _e5815 = global_18.member[(_e5808 >> bitcast<u32>(2i))][(_e5808 & 3u)];
                    let _e5821 = ((_e5815 >> bitcast<u32>(((_e5805 - (_e5808 * 3u)) * 10u))) & 1023u);
                    let _e5824 = global_12.member[_e5821];
                    let _e5826 = (_e5824.xyz - _e821);
                    let _e5827 = dot(_e5826, _e5826);
                    let _e5829 = (_e5827 * _e5824.w);
                    let _e5832 = clamp((1f - (_e5829 * _e5829)), 0f, 1f);
                    let _e5835 = (_e5826 * inverseSqrt(max(_e5827, 0.00000001f)));
                    let _e5838 = global_14.member[_e5821];
                    let _e5841 = global_15.member[_e5821];
                    let _e5849 = clamp(((dot(-(_e5835), _e5841.xyz) * _e5838.w) + _e5841.w), 0f, 1f);
                    let _e5856 = (_e5838.xyz * ((((_e5832 * _e5832) * _e5849) * _e5849) / max(_e5827, 0.0001f)));
                    phi_21661_ = _e5856;
                    if _e831 {
                        switch bitcast<i32>(0u) {
                            default: {
                                let _e5860 = global.member_21[2u];
                                let _e5861 = u32(_e5860);
                                if (_e5821 < _e5861) {
                                    let _e5865 = global.member_26[_e5821];
                                    let _e5868 = global.member_15[_e5821];
                                    let _e5877 = (_e5865.z * max((_e5868 * vec4<f32>(_e821.x, _e821.y, _e821.z, 1f)).w, 0f));
                                    let _e5880 = global.member_25[0u];
                                    let _e5886 = global.member_25[1u];
                                    let _e5889 = ((_e821 + (_e828 * (_e5877 * _e5880))) + (_e5835 * (_e5877 * _e5886)));
                                    let _e5894 = (_e5868 * vec4<f32>(_e5889.x, _e5889.y, _e5889.z, 1f));
                                    if (_e5894.w <= 0f) {
                                        phi_21556_ = 1f;
                                        break;
                                    }
                                    let _e5899 = (_e5894.xyz / vec3(_e5894.w));
                                    let _e5901 = (_e5899.x < 0f);
                                    phi_15373_ = _e5901;
                                    if !(_e5901) {
                                        phi_15373_ = (_e5899.x > 1f);
                                    }
                                    let _e5905 = phi_15373_;
                                    phi_15380_ = _e5905;
                                    if !(_e5905) {
                                        phi_15380_ = (_e5899.y < 0f);
                                    }
                                    let _e5910 = phi_15380_;
                                    phi_15387_ = _e5910;
                                    if !(_e5910) {
                                        phi_15387_ = (_e5899.y > 1f);
                                    }
                                    let _e5915 = phi_15387_;
                                    phi_15394_ = _e5915;
                                    if !(_e5915) {
                                        phi_15394_ = (_e5899.z > 1f);
                                    }
                                    let _e5920 = phi_15394_;
                                    if _e5920 {
                                        phi_21556_ = 1f;
                                        break;
                                    }
                                    let _e5923 = _e5865.xy;
                                    let _e5925 = global.member_23;
                                    let _e5926 = _e5925.zw;
                                    let _e5928 = global.member_22;
                                    let _e5929 = _e5928.xy;
                                    let _e5930 = (_e5929 * 0.5f);
                                    let _e5932 = (_e5923 + (_e5899.xy * _e5926));
                                    let _e5933 = (_e5923 + _e5930);
                                    let _e5935 = ((_e5923 + _e5926) - _e5930);
                                    let _e5940 = vec4<f32>(_e5933.x, _e5933.y, _e5935.x, _e5935.y);
                                    switch bitcast<i32>(0u) {
                                        default: {
                                            let _e5944 = global.member_22[2u];
                                            let _e5945 = i32(_e5944);
                                            if (_e5945 <= 0i) {
                                                let _e5949 = clamp(_e5932, _e5940.xy, _e5940.zw);
                                                let _e5954 = textureSampleCompare(global_2, global_1, vec3<f32>(_e5949.x, _e5949.y, _e5899.z).xy, _e5899.z);
                                                phi_21555_ = _e5954;
                                                break;
                                            }
                                            let _e5956 = ((_e5932 / _e5929) + vec2<f32>(0.5f, 0.5f));
                                            let _e5957 = floor(_e5956);
                                            let _e5958 = (_e5956 - _e5957);
                                            let _e5960 = (_e5945 == 1i);
                                            if _e5960 {
                                                let _e5961 = (_e5958 * 2f);
                                                local_3[0i] = (vec2<f32>(3f, 3f) - _e5961);
                                                local_3[1i] = (vec2<f32>(1f, 1f) + _e5961);
                                                let _e5967 = local_3[0i];
                                                local_4[0i] = (((vec2<f32>(2f, 2f) - _e5958) / _e5967) - vec2<f32>(1f, 1f));
                                                let _e5971 = local_3[1i];
                                                local_4[1i] = ((_e5958 / _e5971) + vec2<f32>(1f, 1f));
                                            } else {
                                                let _e5975 = (_e5958 * 3f);
                                                local_3[0i] = (vec2<f32>(4f, 4f) - _e5975);
                                                local_3[1i] = vec2<f32>(7f, 7f);
                                                local_3[2i] = (vec2<f32>(1f, 1f) + _e5975);
                                                let _e5983 = local_3[0i];
                                                local_4[0i] = (((vec2<f32>(3f, 3f) - (_e5958 * 2f)) / _e5983) - vec2<f32>(2f, 2f));
                                                let _e5988 = local_3[1i];
                                                local_4[1i] = ((vec2<f32>(3f, 3f) + _e5958) / _e5988);
                                                let _e5991 = local_3[2i];
                                                local_4[2i] = ((_e5958 / _e5991) + vec2<f32>(2f, 2f));
                                            }
                                            let _e5996 = select(3i, 2i, _e5960);
                                            phi_21548_ = 0f;
                                            phi_21545_ = 0i;
                                            loop {
                                                let _e5998 = phi_21548_;
                                                let _e6000 = phi_21545_;
                                                local_52 = _e5998;
                                                if (_e6000 < _e5996) {
                                                    phi_21554_ = _e5998;
                                                    phi_21551_ = 0i;
                                                    loop {
                                                        let _e6003 = phi_21554_;
                                                        let _e6005 = phi_21551_;
                                                        local_64 = _e6003;
                                                        if (_e6005 < _e5996) {
                                                            continue;
                                                        } else {
                                                            break;
                                                        }
                                                        continuing {
                                                            let _e6009 = local_4[_e6005][0u];
                                                            let _e6012 = local_4[_e6000][1u];
                                                            let _e6018 = clamp((_e5929 * ((_e5957 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e6009, _e6012))), _e5940.xy, _e5940.zw);
                                                            let _e6021 = local_3[_e6005][0u];
                                                            let _e6024 = local_3[_e6000][1u];
                                                            let _e6030 = textureSampleCompare(global_2, global_1, vec3<f32>(_e6018.x, _e6018.y, _e5899.z).xy, _e5899.z);
                                                            phi_21554_ = (_e6003 + ((_e6021 * _e6024) * _e6030));
                                                            phi_21551_ = (_e6005 + 1i);
                                                        }
                                                    }
                                                    continue;
                                                } else {
                                                    break;
                                                }
                                                continuing {
                                                    let _e7945 = local_64;
                                                    phi_21548_ = _e7945;
                                                    phi_21545_ = (_e6000 + 1i);
                                                }
                                            }
                                            let _e6036 = local_52;
                                            phi_21555_ = (_e6036 * select(0.0069444445f, 0.0625f, _e5960));
                                            break;
                                        }
                                    }
                                    let _e6039 = phi_21555_;
                                    phi_21556_ = _e6039;
                                    break;
                                }
                                let _e6040 = (_e5821 - _e5861);
                                let _e6043 = global.member_21[3u];
                                if (_e6040 >= u32(_e6043)) {
                                    phi_21556_ = 1f;
                                    break;
                                }
                                let _e6048 = global.member_27[_e6040];
                                let _e6051 = global.member_28[_e6040];
                                let _e6053 = _e6048.xyz;
                                let _e6056 = (_e6048.w * length((_e821 - _e6053)));
                                let _e6059 = global.member_25[0u];
                                let _e6065 = global.member_25[1u];
                                let _e6069 = (((_e821 + (_e828 * (_e6056 * _e6059))) + (_e5835 * (_e6056 * _e6065))) - _e6053);
                                let _e6070 = abs(_e6069);
                                let _e6073 = (_e6070.x >= _e6070.y);
                                phi_15464_ = _e6073;
                                if _e6073 {
                                    phi_15464_ = (_e6070.x >= _e6070.z);
                                }
                                let _e6077 = phi_15464_;
                                if _e6077 {
                                    phi_21532_ = select(1i, 0i, (_e6069.x > 0f));
                                    phi_21530_ = _e6070.x;
                                } else {
                                    let _e6082 = (_e6070.y >= _e6070.z);
                                    if _e6082 {
                                        phi_21533_ = select(3i, 2i, (_e6069.y > 0f));
                                    } else {
                                        phi_21533_ = select(5i, 4i, (_e6069.z > 0f));
                                    }
                                    let _e6090 = phi_21533_;
                                    phi_21532_ = _e6090;
                                    phi_21530_ = select(_e6070.z, _e6070.y, _e6082);
                                }
                                let _e6093 = phi_21532_;
                                let _e6095 = phi_21530_;
                                if (_e6095 <= 0f) {
                                    phi_21556_ = 1f;
                                    break;
                                }
                                local_5 = array<vec3<f32>, 6>(vec3<f32>(0f, 0f, 1f), vec3<f32>(0f, 0f, -1f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(1f, 0f, 0f));
                                let _e6098 = local_5[_e6093];
                                local_6 = array<vec3<f32>, 6>(vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 0f, -1f), vec3<f32>(0f, 0f, 1f), vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 1f, 0f));
                                let _e6101 = local_6[_e6093];
                                let _e6106 = global.member_24[2u];
                                let _e6109 = (vec2<f32>(dot(_e6069, _e6098), dot(_e6069, _e6101)) / vec2((_e6095 * _e6106)));
                                let _e6113 = (_e6051.z + (_e6051.w / _e6095));
                                if (_e6113 > 1f) {
                                    phi_21556_ = 1f;
                                    break;
                                }
                                let _e6128 = global.member_24;
                                let _e6129 = _e6128.xy;
                                let _e6131 = (_e6051.xy + (vec2<f32>(f32((_e6093 - (i32(floor((f32(_e6093) / f32(3i)))) * 3i))), f32((_e6093 / 3i))) * _e6129));
                                let _e6140 = global.member_22;
                                let _e6141 = _e6140.xy;
                                let _e6142 = (_e6141 * 0.5f);
                                let _e6144 = (_e6131 + (vec2<f32>((0.5f + (0.5f * _e6109.x)), (0.5f - (0.5f * _e6109.y))) * _e6129));
                                let _e6145 = (_e6131 + _e6142);
                                let _e6147 = ((_e6131 + _e6129) - _e6142);
                                let _e6152 = vec4<f32>(_e6145.x, _e6145.y, _e6147.x, _e6147.y);
                                switch bitcast<i32>(0u) {
                                    default: {
                                        let _e6156 = global.member_22[2u];
                                        let _e6157 = i32(_e6156);
                                        if (_e6157 <= 0i) {
                                            let _e6161 = clamp(_e6144, _e6152.xy, _e6152.zw);
                                            let _e6166 = textureSampleCompare(global_2, global_1, vec3<f32>(_e6161.x, _e6161.y, _e6113).xy, _e6113);
                                            phi_21544_ = _e6166;
                                            break;
                                        }
                                        let _e6168 = ((_e6144 / _e6141) + vec2<f32>(0.5f, 0.5f));
                                        let _e6169 = floor(_e6168);
                                        let _e6170 = (_e6168 - _e6169);
                                        let _e6172 = (_e6157 == 1i);
                                        if _e6172 {
                                            let _e6173 = (_e6170 * 2f);
                                            local_1[0i] = (vec2<f32>(3f, 3f) - _e6173);
                                            local_1[1i] = (vec2<f32>(1f, 1f) + _e6173);
                                            let _e6179 = local_1[0i];
                                            local_2[0i] = (((vec2<f32>(2f, 2f) - _e6170) / _e6179) - vec2<f32>(1f, 1f));
                                            let _e6183 = local_1[1i];
                                            local_2[1i] = ((_e6170 / _e6183) + vec2<f32>(1f, 1f));
                                        } else {
                                            let _e6187 = (_e6170 * 3f);
                                            local_1[0i] = (vec2<f32>(4f, 4f) - _e6187);
                                            local_1[1i] = vec2<f32>(7f, 7f);
                                            local_1[2i] = (vec2<f32>(1f, 1f) + _e6187);
                                            let _e6195 = local_1[0i];
                                            local_2[0i] = (((vec2<f32>(3f, 3f) - (_e6170 * 2f)) / _e6195) - vec2<f32>(2f, 2f));
                                            let _e6200 = local_1[1i];
                                            local_2[1i] = ((vec2<f32>(3f, 3f) + _e6170) / _e6200);
                                            let _e6203 = local_1[2i];
                                            local_2[2i] = ((_e6170 / _e6203) + vec2<f32>(2f, 2f));
                                        }
                                        let _e6208 = select(3i, 2i, _e6172);
                                        phi_21537_ = 0f;
                                        phi_21534_ = 0i;
                                        loop {
                                            let _e6210 = phi_21537_;
                                            let _e6212 = phi_21534_;
                                            local_53 = _e6210;
                                            if (_e6212 < _e6208) {
                                                phi_21543_ = _e6210;
                                                phi_21540_ = 0i;
                                                loop {
                                                    let _e6215 = phi_21543_;
                                                    let _e6217 = phi_21540_;
                                                    local_65 = _e6215;
                                                    if (_e6217 < _e6208) {
                                                        continue;
                                                    } else {
                                                        break;
                                                    }
                                                    continuing {
                                                        let _e6221 = local_2[_e6217][0u];
                                                        let _e6224 = local_2[_e6212][1u];
                                                        let _e6230 = clamp((_e6141 * ((_e6169 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e6221, _e6224))), _e6152.xy, _e6152.zw);
                                                        let _e6233 = local_1[_e6217][0u];
                                                        let _e6236 = local_1[_e6212][1u];
                                                        let _e6242 = textureSampleCompare(global_2, global_1, vec3<f32>(_e6230.x, _e6230.y, _e6113).xy, _e6113);
                                                        phi_21543_ = (_e6215 + ((_e6233 * _e6236) * _e6242));
                                                        phi_21540_ = (_e6217 + 1i);
                                                    }
                                                }
                                                continue;
                                            } else {
                                                break;
                                            }
                                            continuing {
                                                let _e7957 = local_65;
                                                phi_21537_ = _e7957;
                                                phi_21534_ = (_e6212 + 1i);
                                            }
                                        }
                                        let _e6248 = local_53;
                                        phi_21544_ = (_e6248 * select(0.0069444445f, 0.0625f, _e6172));
                                        break;
                                    }
                                }
                                let _e6251 = phi_21544_;
                                phi_21556_ = _e6251;
                                break;
                            }
                        }
                        let _e6253 = phi_21556_;
                        phi_21661_ = (_e5856 * _e6253);
                    }
                    let _e6256 = phi_21661_;
                    let _e6258 = normalize((_e5835 + _e823));
                    let _e6260 = clamp(dot(_e813, _e5835), 0f, 1f);
                    let _e6262 = clamp(dot(_e813, _e6258), 0f, 1f);
                    let _e6268 = (_e3298 + (_e3335 * pow((1f - clamp(dot(_e823, _e6258), 0f, 1f)), 5f)));
                    let _e6271 = (((_e6262 * _e6262) * _e3340) + 1f);
                    local_63 = (_e5803 + (((((vec3<f32>(1f, 1f, 1f) - _e6268) * _e3296) + ((_e6268 * ((_e3338 / ((3.1415927f * _e6271) * _e6271)) * (0.5f / max(((_e6260 * _e3350) + (_e3330 * sqrt((((_e6260 * _e6260) * _e3347) + _e3338)))), 0.00001f)))) * 3.1415927f)) * _e6260) * _e6256));
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e7937 = local_63;
                    phi_21663_ = _e7937;
                    phi_21529_ = (_e5805 + bitcast<u32>(1i));
                }
            }
            let _e7967 = local_66;
            phi_21734_ = _e7967;
        }
        let _e6296 = phi_21734_;
        phi_21730_ = _e6296;
    }
    let _e6298 = phi_21730_;
    let _e6301 = global_8.member_1[1u];
    let _e6305 = global_8.member_5;
    let _e6307 = textureSample(global_29, global_5, _e283);
    let _e6310 = global_26;
    let _e6315 = global_28[2u];
    let _e6319 = -(length(_e822));
    let _e6322 = global.member_7[3u];
    let _e6328 = global.member_9[3u];
    phi_21816_ = (1f - exp((_e6319 * _e6322)));
    if (_e6328 != 0f) {
        let _e6332 = (_e6328 * (_e821 - _e820).y);
        if (abs(_e6332) < 0.0001f) {
            phi_21813_ = (1f - (0.5f * _e6332));
        } else {
            phi_21813_ = ((1f - exp(min(-(_e6332), 60f))) / _e6332);
        }
        let _e6343 = phi_21813_;
        let _e6347 = global.member_6[1u];
        let _e6350 = global.member_6[3u];
        phi_21816_ = (1f - exp(((_e6319 * (_e6322 * exp(min((-(_e6328) * (_e6347 - _e6350)), 30f)))) * _e6343)));
    }
    let _e6361 = phi_21816_;
    let _e6363 = global.member_7;
    let _e6369 = global.member_34[2u];
    phi_21863_ = mix((mix(_e6298, _e1246, vec3(_e6301)) + (((_e6305.xyz * _e6307.xyz) * (vec3<f32>(1f, 1f, 1f) + _e6310.yzw)) * _e6315)), _e6363.xyz, vec3(_e6361));
    if (_e6369 > 0.5f) {
        let _e6373 = global.member_29[0u];
        if (_e6373 > 0.5f) {
            let _e6376 = global.member_29;
            let _e6383 = ((_e6376.z * _e813.x) - (_e6376.w * _e813.z));
            let _e6387 = ((_e6376.w * _e813.x) + (_e6376.z * _e813.z));
            let _e6391 = (1.092548f * _e6383);
            local = array<f32, 9>(0.282095f, (0.488603f * _e813.y), (0.488603f * _e6387), (0.488603f * _e6383), (_e6391 * _e813.y), ((1.092548f * _e813.y) * _e6387), (0.315392f * (((3f * _e6387) * _e6387) - 1f)), (_e6391 * _e6387), (0.546274f * ((_e6383 * _e6383) - (_e813.y * _e813.y))));
            phi_21826_ = vec3<f32>(0f, 0f, 0f);
            phi_21825_ = 0i;
            loop {
                let _e6406 = phi_21826_;
                let _e6408 = phi_21825_;
                local_54 = _e6406;
                if (_e6408 < 9i) {
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e6412 = textureLoad(global_4, (vec2<i32>(496i, 256i) + vec2<i32>(_e6408, 0i)), 0i);
                    let _e6415 = local[_e6408];
                    phi_21826_ = (_e6406 + (_e6412.xyz * _e6415));
                    phi_21825_ = (_e6408 + 1i);
                }
            }
            let _e6420 = local_54;
            let _e6424 = global.member_29[1u];
            phi_21827_ = (max(_e6420, vec3<f32>(0f, 0f, 0f)) * _e6424);
        } else {
            let _e6427 = global.member_9;
            let _e6430 = global.member_8;
            let _e6439 = global.member_8[3u];
            phi_21827_ = (mix(_e6427.xyz, _e6430.xyz, vec3(((_e813.y * 0.5f) + 0.5f))) * _e6439);
        }
        let _e6442 = phi_21827_;
        let _e6445 = global.member_34[1u];
        phi_21832_ = _e6442;
        if (_e6445 > 0.5f) {
            let _e6450 = global.member_34[0u];
            phi_21831_ = _e6442;
            phi_21830_ = 0i;
            loop {
                let _e6453 = phi_21831_;
                let _e6455 = phi_21830_;
                local_67 = _e6453;
                if (_e6455 < i32(_e6445)) {
                    let _e6458 = (8i * (i32(_e6450) + _e6455));
                    let _e6462 = global_3.member[(_e6458 + 3i)];
                    let _e6463 = bitcast<vec4<f32>>(_e6462);
                    let _e6466 = global_3.member[_e6458];
                    let _e6467 = bitcast<vec4<f32>>(_e6466);
                    let _e6471 = global_3.member[(_e6458 + 1i)];
                    let _e6472 = bitcast<vec4<f32>>(_e6471);
                    let _e6476 = global_3.member[(_e6458 + 2i)];
                    let _e6477 = bitcast<vec4<f32>>(_e6476);
                    let _e6478 = _e6467.xyz;
                    let _e6482 = _e6472.xyz;
                    let _e6486 = _e6477.xyz;
                    let _e6490 = vec3<f32>((dot(_e6478, _e821) + _e6467.w), (dot(_e6482, _e821) + _e6472.w), (dot(_e6486, _e821) + _e6477.w));
                    let _e6491 = _e6463.xyz;
                    switch bitcast<i32>(0u) {
                        default: {
                            let _e6495 = (_e6491 - abs(_e6490));
                            let _e6500 = min(_e6495.x, min(_e6495.y, _e6495.z));
                            if (_e6500 <= 0f) {
                                phi_21992_ = 0f;
                                break;
                            }
                            if (_e6463.w <= 0f) {
                                phi_21992_ = 1f;
                                break;
                            }
                            let _e6504 = min((_e6500 / _e6463.w), 1f);
                            phi_21992_ = ((_e6504 * _e6504) * (3f - (2f * _e6504)));
                            break;
                        }
                    }
                    let _e6510 = phi_21992_;
                    if (_e6510 <= 0f) {
                        phi_22160_ = _e6453;
                        continue;
                    }
                    let _e6515 = global_3.member[(_e6458 + 4i)];
                    let _e6517 = bitcast<vec4<f32>>(_e6515).xyz;
                    let _e6521 = global_3.member[(_e6458 + 5i)];
                    let _e6522 = bitcast<vec4<f32>>(_e6521);
                    let _e6527 = global_3.member[(_e6458 + 6i)][0u];
                    let _e6528 = bitcast<i32>(_e6527);
                    let _e6529 = dot(_e6478, _e813);
                    let _e6530 = dot(_e6482, _e813);
                    let _e6531 = dot(_e6486, _e813);
                    let _e6532 = vec3<f32>(_e6529, _e6530, _e6531);
                    let _e6538 = ((_e821 + (_e813 * _e6522.x)) + (_e823 * _e6522.y));
                    let _e6553 = clamp(((((vec3<f32>((dot(_e6478, _e6538) + _e6467.w), (dot(_e6482, _e6538) + _e6472.w), (dot(_e6486, _e6538) + _e6477.w)) + _e6491) / max((_e6491 * 2f), vec3<f32>(0.000001f, 0.000001f, 0.000001f))) * _e6517) - vec3<f32>(0.5f, 0.5f, 0.5f)), vec3<f32>(0f, 0f, 0f), (_e6517 - vec3<f32>(1f, 1f, 1f)));
                    let _e6554 = vec3<i32>(_e6517);
                    let _e6558 = min(vec3<i32>(_e6553), max((_e6554 - vec3<i32>(2i, 2i, 2i)), vec3<i32>(0i, 0i, 0i)));
                    let _e6560 = (_e6553 - vec3<f32>(_e6558));
                    let _e6561 = (0.488603f * _e6530);
                    let _e6562 = (0.488603f * _e6531);
                    let _e6563 = (0.488603f * _e6529);
                    let _e6564 = (1.092548f * _e6529);
                    let _e6565 = (_e6564 * _e6530);
                    let _e6567 = ((1.092548f * _e6530) * _e6531);
                    let _e6571 = (0.315392f * (((3f * _e6531) * _e6531) - 1f));
                    let _e6572 = (_e6564 * _e6531);
                    let _e6576 = (0.546274f * ((_e6529 * _e6529) - (_e6530 * _e6530)));
                    let _e6577 = (_e6554 - vec3<i32>(1i, 1i, 1i));
                    let _e6578 = min(_e6558, _e6577);
                    let _e6589 = (_e6528 + ((_e6578.x + (_e6554.x * (_e6578.y + (_e6554.y * _e6578.z)))) * 4i));
                    let _e6590 = (vec3<f32>(1f, 1f, 1f) - _e6560);
                    let _e6597 = ((((((vec3<f32>(_e6578) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e6517) * _e6491) * 2f) - _e6491) - _e6490);
                    let _e6603 = (dot((_e6597 * inverseSqrt(max(dot(_e6597, _e6597), 0.0000000001f))), _e6532) + 1f);
                    let _e6606 = (_e6590.x * _e6590.y);
                    let _e6613 = (_e6589 + 3i);
                    let _e6617 = global_3.member[_e6613][1u];
                    let _e6622 = (((_e6606 * _e6590.z) * ((0.25f * (_e6603 * _e6603)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e6617).y > 0.5f)));
                    let _e6625 = global_3.member[_e6589];
                    let _e6629 = global_3.member[(_e6589 + 1i)];
                    let _e6633 = global_3.member[(_e6589 + 2i)];
                    let _e6636 = global_3.member[_e6613];
                    let _e6638 = unpack2x16float(_e6625.x);
                    let _e6640 = unpack2x16float(_e6625.y);
                    let _e6642 = unpack2x16float(_e6625.z);
                    let _e6644 = unpack2x16float(_e6625.w);
                    let _e6646 = unpack2x16float(_e6629.x);
                    let _e6648 = unpack2x16float(_e6629.y);
                    let _e6650 = unpack2x16float(_e6629.z);
                    let _e6652 = unpack2x16float(_e6629.w);
                    let _e6654 = unpack2x16float(_e6633.x);
                    let _e6656 = unpack2x16float(_e6633.y);
                    let _e6658 = unpack2x16float(_e6633.z);
                    let _e6660 = unpack2x16float(_e6633.w);
                    let _e6662 = unpack2x16float(_e6636.x);
                    let _e6718 = ((((((((((vec3<f32>(_e6638.x, _e6638.y, _e6640.x) * 0.282095f) + (vec3<f32>(_e6640.y, _e6642.x, _e6642.y) * _e6561)) + (vec3<f32>(_e6644.x, _e6644.y, _e6646.x) * _e6562)) + (vec3<f32>(_e6646.y, _e6648.x, _e6648.y) * _e6563)) + (vec3<f32>(_e6650.x, _e6650.y, _e6652.x) * _e6565)) + (vec3<f32>(_e6652.y, _e6654.x, _e6654.y) * _e6567)) + (vec3<f32>(_e6656.x, _e6656.y, _e6658.x) * _e6571)) + (vec3<f32>(_e6658.y, _e6660.x, _e6660.y) * _e6572)) + (vec3<f32>(_e6662.x, _e6662.y, unpack2x16float(_e6636.y).x) * _e6576)) * _e6622);
                    let _e6724 = min((_e6558 + vec3<i32>(1i, 0i, 0i)), _e6577);
                    let _e6733 = (_e6528 + ((_e6724.x + (_e6554.x * (_e6724.y + (_e6554.y * _e6724.z)))) * 4i));
                    let _e6740 = ((((((vec3<f32>(_e6724) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e6517) * _e6491) * 2f) - _e6491) - _e6490);
                    let _e6746 = (dot((_e6740 * inverseSqrt(max(dot(_e6740, _e6740), 0.0000000001f))), _e6532) + 1f);
                    let _e6748 = (_e6560.x * _e6590.y);
                    let _e6754 = (_e6733 + 3i);
                    let _e6758 = global_3.member[_e6754][1u];
                    let _e6763 = (((_e6748 * _e6590.z) * ((0.25f * (_e6746 * _e6746)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e6758).y > 0.5f)));
                    let _e6766 = global_3.member[_e6733];
                    let _e6770 = global_3.member[(_e6733 + 1i)];
                    let _e6774 = global_3.member[(_e6733 + 2i)];
                    let _e6777 = global_3.member[_e6754];
                    let _e6779 = unpack2x16float(_e6766.x);
                    let _e6781 = unpack2x16float(_e6766.y);
                    let _e6783 = unpack2x16float(_e6766.z);
                    let _e6785 = unpack2x16float(_e6766.w);
                    let _e6787 = unpack2x16float(_e6770.x);
                    let _e6789 = unpack2x16float(_e6770.y);
                    let _e6791 = unpack2x16float(_e6770.z);
                    let _e6793 = unpack2x16float(_e6770.w);
                    let _e6795 = unpack2x16float(_e6774.x);
                    let _e6797 = unpack2x16float(_e6774.y);
                    let _e6799 = unpack2x16float(_e6774.z);
                    let _e6801 = unpack2x16float(_e6774.w);
                    let _e6803 = unpack2x16float(_e6777.x);
                    let _e6859 = ((((((((((vec3<f32>(_e6779.x, _e6779.y, _e6781.x) * 0.282095f) + (vec3<f32>(_e6781.y, _e6783.x, _e6783.y) * _e6561)) + (vec3<f32>(_e6785.x, _e6785.y, _e6787.x) * _e6562)) + (vec3<f32>(_e6787.y, _e6789.x, _e6789.y) * _e6563)) + (vec3<f32>(_e6791.x, _e6791.y, _e6793.x) * _e6565)) + (vec3<f32>(_e6793.y, _e6795.x, _e6795.y) * _e6567)) + (vec3<f32>(_e6797.x, _e6797.y, _e6799.x) * _e6571)) + (vec3<f32>(_e6799.y, _e6801.x, _e6801.y) * _e6572)) + (vec3<f32>(_e6803.x, _e6803.y, unpack2x16float(_e6777.y).x) * _e6576)) * _e6763);
                    let _e6866 = min((_e6558 + vec3<i32>(0i, 1i, 0i)), _e6577);
                    let _e6875 = (_e6528 + ((_e6866.x + (_e6554.x * (_e6866.y + (_e6554.y * _e6866.z)))) * 4i));
                    let _e6882 = ((((((vec3<f32>(_e6866) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e6517) * _e6491) * 2f) - _e6491) - _e6490);
                    let _e6888 = (dot((_e6882 * inverseSqrt(max(dot(_e6882, _e6882), 0.0000000001f))), _e6532) + 1f);
                    let _e6890 = (_e6590.x * _e6560.y);
                    let _e6896 = (_e6875 + 3i);
                    let _e6900 = global_3.member[_e6896][1u];
                    let _e6905 = (((_e6890 * _e6590.z) * ((0.25f * (_e6888 * _e6888)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e6900).y > 0.5f)));
                    let _e6908 = global_3.member[_e6875];
                    let _e6912 = global_3.member[(_e6875 + 1i)];
                    let _e6916 = global_3.member[(_e6875 + 2i)];
                    let _e6919 = global_3.member[_e6896];
                    let _e6921 = unpack2x16float(_e6908.x);
                    let _e6923 = unpack2x16float(_e6908.y);
                    let _e6925 = unpack2x16float(_e6908.z);
                    let _e6927 = unpack2x16float(_e6908.w);
                    let _e6929 = unpack2x16float(_e6912.x);
                    let _e6931 = unpack2x16float(_e6912.y);
                    let _e6933 = unpack2x16float(_e6912.z);
                    let _e6935 = unpack2x16float(_e6912.w);
                    let _e6937 = unpack2x16float(_e6916.x);
                    let _e6939 = unpack2x16float(_e6916.y);
                    let _e6941 = unpack2x16float(_e6916.z);
                    let _e6943 = unpack2x16float(_e6916.w);
                    let _e6945 = unpack2x16float(_e6919.x);
                    let _e7001 = ((((((((((vec3<f32>(_e6921.x, _e6921.y, _e6923.x) * 0.282095f) + (vec3<f32>(_e6923.y, _e6925.x, _e6925.y) * _e6561)) + (vec3<f32>(_e6927.x, _e6927.y, _e6929.x) * _e6562)) + (vec3<f32>(_e6929.y, _e6931.x, _e6931.y) * _e6563)) + (vec3<f32>(_e6933.x, _e6933.y, _e6935.x) * _e6565)) + (vec3<f32>(_e6935.y, _e6937.x, _e6937.y) * _e6567)) + (vec3<f32>(_e6939.x, _e6939.y, _e6941.x) * _e6571)) + (vec3<f32>(_e6941.y, _e6943.x, _e6943.y) * _e6572)) + (vec3<f32>(_e6945.x, _e6945.y, unpack2x16float(_e6919.y).x) * _e6576)) * _e6905);
                    let _e7008 = min((_e6558 + vec3<i32>(1i, 1i, 0i)), _e6577);
                    let _e7017 = (_e6528 + ((_e7008.x + (_e6554.x * (_e7008.y + (_e6554.y * _e7008.z)))) * 4i));
                    let _e7024 = ((((((vec3<f32>(_e7008) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e6517) * _e6491) * 2f) - _e6491) - _e6490);
                    let _e7030 = (dot((_e7024 * inverseSqrt(max(dot(_e7024, _e7024), 0.0000000001f))), _e6532) + 1f);
                    let _e7031 = (_e6560.x * _e6560.y);
                    let _e7037 = (_e7017 + 3i);
                    let _e7041 = global_3.member[_e7037][1u];
                    let _e7046 = (((_e7031 * _e6590.z) * ((0.25f * (_e7030 * _e7030)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e7041).y > 0.5f)));
                    let _e7049 = global_3.member[_e7017];
                    let _e7053 = global_3.member[(_e7017 + 1i)];
                    let _e7057 = global_3.member[(_e7017 + 2i)];
                    let _e7060 = global_3.member[_e7037];
                    let _e7062 = unpack2x16float(_e7049.x);
                    let _e7064 = unpack2x16float(_e7049.y);
                    let _e7066 = unpack2x16float(_e7049.z);
                    let _e7068 = unpack2x16float(_e7049.w);
                    let _e7070 = unpack2x16float(_e7053.x);
                    let _e7072 = unpack2x16float(_e7053.y);
                    let _e7074 = unpack2x16float(_e7053.z);
                    let _e7076 = unpack2x16float(_e7053.w);
                    let _e7078 = unpack2x16float(_e7057.x);
                    let _e7080 = unpack2x16float(_e7057.y);
                    let _e7082 = unpack2x16float(_e7057.z);
                    let _e7084 = unpack2x16float(_e7057.w);
                    let _e7086 = unpack2x16float(_e7060.x);
                    let _e7142 = ((((((((((vec3<f32>(_e7062.x, _e7062.y, _e7064.x) * 0.282095f) + (vec3<f32>(_e7064.y, _e7066.x, _e7066.y) * _e6561)) + (vec3<f32>(_e7068.x, _e7068.y, _e7070.x) * _e6562)) + (vec3<f32>(_e7070.y, _e7072.x, _e7072.y) * _e6563)) + (vec3<f32>(_e7074.x, _e7074.y, _e7076.x) * _e6565)) + (vec3<f32>(_e7076.y, _e7078.x, _e7078.y) * _e6567)) + (vec3<f32>(_e7080.x, _e7080.y, _e7082.x) * _e6571)) + (vec3<f32>(_e7082.y, _e7084.x, _e7084.y) * _e6572)) + (vec3<f32>(_e7086.x, _e7086.y, unpack2x16float(_e7060.y).x) * _e6576)) * _e7046);
                    let _e7149 = min((_e6558 + vec3<i32>(0i, 0i, 1i)), _e6577);
                    let _e7158 = (_e6528 + ((_e7149.x + (_e6554.x * (_e7149.y + (_e6554.y * _e7149.z)))) * 4i));
                    let _e7165 = ((((((vec3<f32>(_e7149) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e6517) * _e6491) * 2f) - _e6491) - _e6490);
                    let _e7171 = (dot((_e7165 * inverseSqrt(max(dot(_e7165, _e7165), 0.0000000001f))), _e6532) + 1f);
                    let _e7178 = (_e7158 + 3i);
                    let _e7182 = global_3.member[_e7178][1u];
                    let _e7187 = (((_e6606 * _e6560.z) * ((0.25f * (_e7171 * _e7171)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e7182).y > 0.5f)));
                    let _e7190 = global_3.member[_e7158];
                    let _e7194 = global_3.member[(_e7158 + 1i)];
                    let _e7198 = global_3.member[(_e7158 + 2i)];
                    let _e7201 = global_3.member[_e7178];
                    let _e7203 = unpack2x16float(_e7190.x);
                    let _e7205 = unpack2x16float(_e7190.y);
                    let _e7207 = unpack2x16float(_e7190.z);
                    let _e7209 = unpack2x16float(_e7190.w);
                    let _e7211 = unpack2x16float(_e7194.x);
                    let _e7213 = unpack2x16float(_e7194.y);
                    let _e7215 = unpack2x16float(_e7194.z);
                    let _e7217 = unpack2x16float(_e7194.w);
                    let _e7219 = unpack2x16float(_e7198.x);
                    let _e7221 = unpack2x16float(_e7198.y);
                    let _e7223 = unpack2x16float(_e7198.z);
                    let _e7225 = unpack2x16float(_e7198.w);
                    let _e7227 = unpack2x16float(_e7201.x);
                    let _e7283 = ((((((((((vec3<f32>(_e7203.x, _e7203.y, _e7205.x) * 0.282095f) + (vec3<f32>(_e7205.y, _e7207.x, _e7207.y) * _e6561)) + (vec3<f32>(_e7209.x, _e7209.y, _e7211.x) * _e6562)) + (vec3<f32>(_e7211.y, _e7213.x, _e7213.y) * _e6563)) + (vec3<f32>(_e7215.x, _e7215.y, _e7217.x) * _e6565)) + (vec3<f32>(_e7217.y, _e7219.x, _e7219.y) * _e6567)) + (vec3<f32>(_e7221.x, _e7221.y, _e7223.x) * _e6571)) + (vec3<f32>(_e7223.y, _e7225.x, _e7225.y) * _e6572)) + (vec3<f32>(_e7227.x, _e7227.y, unpack2x16float(_e7201.y).x) * _e6576)) * _e7187);
                    let _e7290 = min((_e6558 + vec3<i32>(1i, 0i, 1i)), _e6577);
                    let _e7299 = (_e6528 + ((_e7290.x + (_e6554.x * (_e7290.y + (_e6554.y * _e7290.z)))) * 4i));
                    let _e7306 = ((((((vec3<f32>(_e7290) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e6517) * _e6491) * 2f) - _e6491) - _e6490);
                    let _e7312 = (dot((_e7306 * inverseSqrt(max(dot(_e7306, _e7306), 0.0000000001f))), _e6532) + 1f);
                    let _e7318 = (_e7299 + 3i);
                    let _e7322 = global_3.member[_e7318][1u];
                    let _e7327 = (((_e6748 * _e6560.z) * ((0.25f * (_e7312 * _e7312)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e7322).y > 0.5f)));
                    let _e7330 = global_3.member[_e7299];
                    let _e7334 = global_3.member[(_e7299 + 1i)];
                    let _e7338 = global_3.member[(_e7299 + 2i)];
                    let _e7341 = global_3.member[_e7318];
                    let _e7343 = unpack2x16float(_e7330.x);
                    let _e7345 = unpack2x16float(_e7330.y);
                    let _e7347 = unpack2x16float(_e7330.z);
                    let _e7349 = unpack2x16float(_e7330.w);
                    let _e7351 = unpack2x16float(_e7334.x);
                    let _e7353 = unpack2x16float(_e7334.y);
                    let _e7355 = unpack2x16float(_e7334.z);
                    let _e7357 = unpack2x16float(_e7334.w);
                    let _e7359 = unpack2x16float(_e7338.x);
                    let _e7361 = unpack2x16float(_e7338.y);
                    let _e7363 = unpack2x16float(_e7338.z);
                    let _e7365 = unpack2x16float(_e7338.w);
                    let _e7367 = unpack2x16float(_e7341.x);
                    let _e7423 = ((((((((((vec3<f32>(_e7343.x, _e7343.y, _e7345.x) * 0.282095f) + (vec3<f32>(_e7345.y, _e7347.x, _e7347.y) * _e6561)) + (vec3<f32>(_e7349.x, _e7349.y, _e7351.x) * _e6562)) + (vec3<f32>(_e7351.y, _e7353.x, _e7353.y) * _e6563)) + (vec3<f32>(_e7355.x, _e7355.y, _e7357.x) * _e6565)) + (vec3<f32>(_e7357.y, _e7359.x, _e7359.y) * _e6567)) + (vec3<f32>(_e7361.x, _e7361.y, _e7363.x) * _e6571)) + (vec3<f32>(_e7363.y, _e7365.x, _e7365.y) * _e6572)) + (vec3<f32>(_e7367.x, _e7367.y, unpack2x16float(_e7341.y).x) * _e6576)) * _e7327);
                    let _e7430 = min((_e6558 + vec3<i32>(0i, 1i, 1i)), _e6577);
                    let _e7439 = (_e6528 + ((_e7430.x + (_e6554.x * (_e7430.y + (_e6554.y * _e7430.z)))) * 4i));
                    let _e7446 = ((((((vec3<f32>(_e7430) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e6517) * _e6491) * 2f) - _e6491) - _e6490);
                    let _e7452 = (dot((_e7446 * inverseSqrt(max(dot(_e7446, _e7446), 0.0000000001f))), _e6532) + 1f);
                    let _e7458 = (_e7439 + 3i);
                    let _e7462 = global_3.member[_e7458][1u];
                    let _e7467 = (((_e6890 * _e6560.z) * ((0.25f * (_e7452 * _e7452)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e7462).y > 0.5f)));
                    let _e7470 = global_3.member[_e7439];
                    let _e7474 = global_3.member[(_e7439 + 1i)];
                    let _e7478 = global_3.member[(_e7439 + 2i)];
                    let _e7481 = global_3.member[_e7458];
                    let _e7483 = unpack2x16float(_e7470.x);
                    let _e7485 = unpack2x16float(_e7470.y);
                    let _e7487 = unpack2x16float(_e7470.z);
                    let _e7489 = unpack2x16float(_e7470.w);
                    let _e7491 = unpack2x16float(_e7474.x);
                    let _e7493 = unpack2x16float(_e7474.y);
                    let _e7495 = unpack2x16float(_e7474.z);
                    let _e7497 = unpack2x16float(_e7474.w);
                    let _e7499 = unpack2x16float(_e7478.x);
                    let _e7501 = unpack2x16float(_e7478.y);
                    let _e7503 = unpack2x16float(_e7478.z);
                    let _e7505 = unpack2x16float(_e7478.w);
                    let _e7507 = unpack2x16float(_e7481.x);
                    let _e7563 = ((((((((((vec3<f32>(_e7483.x, _e7483.y, _e7485.x) * 0.282095f) + (vec3<f32>(_e7485.y, _e7487.x, _e7487.y) * _e6561)) + (vec3<f32>(_e7489.x, _e7489.y, _e7491.x) * _e6562)) + (vec3<f32>(_e7491.y, _e7493.x, _e7493.y) * _e6563)) + (vec3<f32>(_e7495.x, _e7495.y, _e7497.x) * _e6565)) + (vec3<f32>(_e7497.y, _e7499.x, _e7499.y) * _e6567)) + (vec3<f32>(_e7501.x, _e7501.y, _e7503.x) * _e6571)) + (vec3<f32>(_e7503.y, _e7505.x, _e7505.y) * _e6572)) + (vec3<f32>(_e7507.x, _e7507.y, unpack2x16float(_e7481.y).x) * _e6576)) * _e7467);
                    let _e7570 = min((_e6558 + vec3<i32>(1i, 1i, 1i)), _e6577);
                    let _e7579 = (_e6528 + ((_e7570.x + (_e6554.x * (_e7570.y + (_e6554.y * _e7570.z)))) * 4i));
                    let _e7586 = ((((((vec3<f32>(_e7570) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e6517) * _e6491) * 2f) - _e6491) - _e6490);
                    let _e7592 = (dot((_e7586 * inverseSqrt(max(dot(_e7586, _e7586), 0.0000000001f))), _e6532) + 1f);
                    let _e7598 = (_e7579 + 3i);
                    let _e7602 = global_3.member[_e7598][1u];
                    let _e7607 = (((_e7031 * _e6560.z) * ((0.25f * (_e7592 * _e7592)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e7602).y > 0.5f)));
                    let _e7610 = global_3.member[_e7579];
                    let _e7614 = global_3.member[(_e7579 + 1i)];
                    let _e7618 = global_3.member[(_e7579 + 2i)];
                    let _e7621 = global_3.member[_e7598];
                    let _e7623 = unpack2x16float(_e7610.x);
                    let _e7625 = unpack2x16float(_e7610.y);
                    let _e7627 = unpack2x16float(_e7610.z);
                    let _e7629 = unpack2x16float(_e7610.w);
                    let _e7631 = unpack2x16float(_e7614.x);
                    let _e7633 = unpack2x16float(_e7614.y);
                    let _e7635 = unpack2x16float(_e7614.z);
                    let _e7637 = unpack2x16float(_e7614.w);
                    let _e7639 = unpack2x16float(_e7618.x);
                    let _e7641 = unpack2x16float(_e7618.y);
                    let _e7643 = unpack2x16float(_e7618.z);
                    let _e7645 = unpack2x16float(_e7618.w);
                    let _e7647 = unpack2x16float(_e7621.x);
                    let _e7703 = ((((((((((vec3<f32>(_e7623.x, _e7623.y, _e7625.x) * 0.282095f) + (vec3<f32>(_e7625.y, _e7627.x, _e7627.y) * _e6561)) + (vec3<f32>(_e7629.x, _e7629.y, _e7631.x) * _e6562)) + (vec3<f32>(_e7631.y, _e7633.x, _e7633.y) * _e6563)) + (vec3<f32>(_e7635.x, _e7635.y, _e7637.x) * _e6565)) + (vec3<f32>(_e7637.y, _e7639.x, _e7639.y) * _e6567)) + (vec3<f32>(_e7641.x, _e7641.y, _e7643.x) * _e6571)) + (vec3<f32>(_e7643.y, _e7645.x, _e7645.y) * _e6572)) + (vec3<f32>(_e7647.x, _e7647.y, unpack2x16float(_e7621.y).x) * _e6576)) * _e7607);
                    let _e7708 = (((((((vec4<f32>(_e6718.x, _e6718.y, _e6718.z, _e6622) + vec4<f32>(_e6859.x, _e6859.y, _e6859.z, _e6763)) + vec4<f32>(_e7001.x, _e7001.y, _e7001.z, _e6905)) + vec4<f32>(_e7142.x, _e7142.y, _e7142.z, _e7046)) + vec4<f32>(_e7283.x, _e7283.y, _e7283.z, _e7187)) + vec4<f32>(_e7423.x, _e7423.y, _e7423.z, _e7327)) + vec4<f32>(_e7563.x, _e7563.y, _e7563.z, _e7467)) + vec4<f32>(_e7703.x, _e7703.y, _e7703.z, _e7607));
                    phi_22161_ = _e6453;
                    if (_e7708.w > 0.00001f) {
                        phi_22161_ = mix(_e6453, ((max(_e7708.xyz, vec3<f32>(0f, 0f, 0f)) / vec3(_e7708.w)) * _e6522.z), vec3(_e6510));
                    }
                    let _e7720 = phi_22161_;
                    phi_22160_ = _e7720;
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e7722 = phi_22160_;
                    phi_21831_ = _e7722;
                    phi_21830_ = (_e6455 + 1i);
                }
            }
            let _e7982 = local_67;
            phi_21832_ = _e7982;
        }
        let _e7725 = phi_21832_;
        phi_21863_ = (_e7725 * _e1275);
    }
    let _e7728 = phi_21863_;
    let _e7731 = global.member_33[3u];
    phi_21864_ = _e7728;
    if (_e7731 > 0.5f) {
        phi_21864_ = (_e7728 / (vec3<f32>(1f, 1f, 1f) + _e7728));
    }
    let _e7736 = phi_21864_;
    global_30 = vec4<f32>(_e7736.x, _e7736.y, _e7736.z, (_e303 * _e308));
    let _e7741 = global_32;
    let _e7742 = global_33;
    switch bitcast<i32>(0u) {
        default: {
            if (_e7742.w <= 0f) {
                phi_21991_ = vec2<f32>(0f, 0f);
                break;
            }
            phi_21991_ = (((_e7742.xy / vec2(_e7742.w)) - (_e7741.xy / vec2(_e7741.w))) * vec2<f32>(0.5f, -0.5f));
            break;
        }
    }
    let _e7756 = phi_21991_;
    global_31 = _e7756;
    return;
}

@fragment 
fn main(@location(1) param: vec3<f32>, @location(8) param_1: vec4<f32>, @location(4) param_2: vec3<f32>, @location(0) param_3: vec3<f32>, @builtin(position) param_4: vec4<f32>, @location(2) param_5: vec2<f32>, @location(3) param_6: vec4<f32>, @location(9) param_7: vec4<f32>, @builtin(front_facing) param_8: bool, @location(5) param_9: vec4<f32>, @location(10) param_10: vec4<f32>, @location(6) param_11: vec4<f32>, @location(7) param_12: vec4<f32>) -> FragmentOutput {
    global_9 = param;
    global_10 = param_1;
    global_11 = param_2;
    global_13 = param_3;
    global_16 = param_4;
    global_20 = param_5;
    global_22 = param_6;
    global_23 = param_7;
    global_25 = param_8;
    global_26 = param_9;
    global_28 = param_10;
    global_32 = param_11;
    global_33 = param_12;
    function_();
    let _e28 = global_30;
    let _e29 = global_31;
    return FragmentOutput(_e28, _e29);
}
