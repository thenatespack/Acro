// Generated from mesh_paint_probes.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: c087786f762a3e54
// glsl-fnv1a64: 811456345029bd61

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
    var phi_20842_: vec3<f32>;
    var phi_20840_: f32;
    var local_28: vec3<f32>;
    var phi_21003_: vec2<f32>;
    var phi_20970_: f32;
    var phi_20939_: vec3<f32>;
    var phi_20843_: vec2<f32>;
    var phi_20844_: vec3<f32>;
    var phi_20853_: vec3<f32>;
    var phi_20852_: vec3<f32>;
    var phi_20849_: f32;
    var phi_3634_: bool;
    var phi_21039_: vec3<f32>;
    var phi_20854_: i32;
    var phi_5418_: bool;
    var local_29: i32;
    var local_30: i32;
    var local_31: i32;
    var phi_5531_: bool;
    var phi_5538_: bool;
    var phi_5545_: bool;
    var local_32: i32;
    var local_33: i32;
    var local_34: i32;
    var phi_20859_: f32;
    var phi_20856_: i32;
    var phi_20865_: f32;
    var phi_20862_: i32;
    var local_35: f32;
    var phi_20866_: f32;
    var phi_20867_: f32;
    var local_36: i32;
    var local_37: i32;
    var local_38: i32;
    var phi_5818_: bool;
    var phi_5825_: bool;
    var phi_5832_: bool;
    var phi_20879_: f32;
    var phi_20876_: i32;
    var phi_20885_: f32;
    var phi_20882_: i32;
    var local_39: f32;
    var phi_20886_: f32;
    var phi_20887_: f32;
    var phi_20908_: f32;
    var phi_20905_: vec3<f32>;
    var phi_20907_: f32;
    var phi_20904_: vec3<f32>;
    var phi_20910_: vec3<f32>;
    var phi_20909_: f32;
    var phi_21073_: f32;
    var phi_21033_: vec3<f32>;
    var phi_20962_: f32;
    var phi_21163_: f32;
    var phi_21690_: vec3<f32>;
    var phi_21689_: i32;
    var local_40: vec3<f32>;
    var phi_21691_: vec3<f32>;
    var phi_21701_: vec3<f32>;
    var phi_21700_: i32;
    var local_41: vec3<f32>;
    var phi_21702_: vec3<f32>;
    var phi_21708_: vec3<f32>;
    var phi_21707_: i32;
    var phi_21969_: f32;
    var phi_22007_: vec3<f32>;
    var phi_22006_: vec3<f32>;
    var local_42: vec3<f32>;
    var phi_21718_: vec3<f32>;
    var phi_21719_: vec3<f32>;
    var phi_21715_: u32;
    var phi_9383_: bool;
    var phi_9390_: bool;
    var phi_9397_: bool;
    var phi_9404_: bool;
    var phi_21875_: f32;
    var phi_21872_: i32;
    var phi_21881_: f32;
    var phi_21878_: i32;
    var local_43: f32;
    var phi_21882_: f32;
    var phi_9474_: bool;
    var phi_21860_: i32;
    var phi_21859_: i32;
    var phi_21857_: f32;
    var phi_21864_: f32;
    var phi_21861_: i32;
    var phi_21870_: f32;
    var phi_21867_: i32;
    var local_44: f32;
    var phi_21871_: f32;
    var phi_21883_: f32;
    var phi_21934_: vec3<f32>;
    var phi_21717_: vec3<f32>;
    var phi_21034_: f32;
    var phi_21029_: f32;
    var phi_21063_: vec3<f32>;
    var phi_21062_: vec3<f32>;
    var phi_21067_: f32;
    var phi_21066_: f32;
    var phi_21177_: vec3<f32>;
    var phi_21085_: vec3<f32>;
    var phi_21084_: i32;
    var local_45: vec3<f32>;
    var phi_21088_: i32;
    var phi_21089_: i32;
    var phi_21095_: i32;
    var phi_21096_: i32;
    var phi_21139_: vec3<f32>;
    var phi_21127_: vec2<f32>;
    var phi_21103_: vec3<f32>;
    var phi_4152_: bool;
    var phi_21123_: f32;
    var phi_21122_: vec3<f32>;
    var phi_21121_: i32;
    var local_46: vec3<f32>;
    var local_47: f32;
    var phi_21124_: vec3<f32>;
    var phi_21148_: vec3<f32>;
    var phi_21184_: vec3<f32>;
    var phi_21183_: i32;
    var phi_21684_: f32;
    var phi_21977_: vec3<f32>;
    var phi_21976_: vec3<f32>;
    var phi_21185_: vec3<f32>;
    var phi_21208_: i32;
    var phi_21209_: i32;
    var phi_21215_: i32;
    var phi_21216_: i32;
    var phi_21222_: vec3<f32>;
    var phi_21304_: vec3<f32>;
    var phi_21238_: f32;
    var phi_21237_: i32;
    var phi_21239_: f32;
    var phi_21240_: vec3<f32>;
    var phi_21241_: vec3<f32>;
    var phi_21242_: i32;
    var phi_21243_: i32;
    var phi_21249_: vec2<u32>;
    var phi_21251_: vec2<u32>;
    var phi_21254_: vec2<u32>;
    var phi_21255_: vec2<u32>;
    var phi_21256_: i32;
    var phi_21257_: i32;
    var phi_21263_: vec2<u32>;
    var phi_21265_: vec2<u32>;
    var phi_21268_: vec2<u32>;
    var phi_21269_: vec2<u32>;
    var phi_21991_: vec3<f32>;
    var phi_21990_: f32;
    var local_48: f32;
    var local_49: vec3<f32>;
    var phi_4270_: bool;
    var phi_21379_: f32;
    var phi_21378_: vec3<f32>;
    var phi_21377_: i32;
    var local_50: vec3<f32>;
    var local_51: f32;
    var phi_21380_: vec3<f32>;
    var phi_21414_: vec3<f32>;
    var phi_21413_: vec3<f32>;
    var phi_21650_: vec3<f32>;
    var phi_21649_: vec3<f32>;
    var phi_21515_: u32;
    var phi_15360_: bool;
    var phi_15367_: bool;
    var phi_15374_: bool;
    var phi_15381_: bool;
    var phi_21534_: f32;
    var phi_21531_: i32;
    var phi_21540_: f32;
    var phi_21537_: i32;
    var local_52: f32;
    var phi_21541_: f32;
    var phi_15451_: bool;
    var phi_21519_: i32;
    var phi_21518_: i32;
    var phi_21516_: f32;
    var phi_21523_: f32;
    var phi_21520_: i32;
    var phi_21529_: f32;
    var phi_21526_: i32;
    var local_53: f32;
    var phi_21530_: f32;
    var phi_21542_: f32;
    var phi_21647_: vec3<f32>;
    var phi_21720_: vec3<f32>;
    var phi_21716_: vec3<f32>;
    var phi_21799_: f32;
    var phi_21802_: f32;
    var phi_21812_: vec3<f32>;
    var phi_21811_: i32;
    var local_54: vec3<f32>;
    var phi_21813_: vec3<f32>;
    var phi_21817_: vec3<f32>;
    var phi_21816_: i32;
    var phi_21852_: f32;
    var phi_22021_: vec3<f32>;
    var phi_22020_: vec3<f32>;
    var phi_21818_: vec3<f32>;
    var phi_21849_: vec3<f32>;
    var phi_21850_: vec3<f32>;
    var phi_21851_: vec2<f32>;
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
    let _e294 = global_22[3u];
    let _e297 = global_8.member[3u];
    let _e301 = global_23;
    let _e303 = (((_e286 * _e288.xyz) * _e291) * _e301.xyz);
    let _e305 = global_23[3u];
    let _e309 = global_8.member_1[0u];
    phi_20842_ = _e303;
    if (_e309 > 0.5f) {
        let _e311 = global_13;
        let _e314 = floor((_e311.xz * vec2<f32>(0.5f, 0.5f)));
        let _e318 = abs((_e314.x + _e314.y));
        phi_20842_ = (_e303 * select(0.75f, 1f, ((_e318 - (floor((_e318 / 2f)) * 2f)) < 0.5f)));
    }
    let _e327 = phi_20842_;
    let _e330 = global_8.member_3[3u];
    phi_21003_ = vec2<f32>(0f, 0f);
    phi_20970_ = 0f;
    phi_20939_ = _e327;
    if (_e330 > 0.5f) {
        switch bitcast<i32>(0u) {
            default: {
                let _e335 = global_8.member_2[3u];
                let _e337 = vec4<f32>(_e335, _e330, 0f, 0f).xyy;
                let _e339 = floor((_e337 * vec3<f32>(0.000015258789f, 0.000015258789f, 0.000015258789f)));
                let _e341 = (_e337 - (_e339 * 65536f));
                let _e343 = floor((_e341 * vec3<f32>(0.00390625f, 0.00390625f, 0.00390625f)));
                let _e345 = (_e341 - (_e343 * 256f));
                let _e357 = (_e339.y - 128f);
                let _e364 = (floor((_e357 * 0.03125f)) * 0.33333334f);
                let _e368 = global_9;
                let _e369 = normalize(_e368);
                let _e370 = global_10;
                let _e371 = _e370.xyz;
                let _e372 = dot(_e369, _e371);
                let _e378 = ((_e372 / max(length((_e371 - (_e369 * _e372))), 0.000001f)) * 25.5f);
                local_28 = ((vec3<f32>(_e345.x, _e343.x, _e339.x) * vec3<f32>(0.003921569f, 0.003921569f, 0.003921569f)) * 2f);
                local_55 = (vec2<f32>(_e345.y, _e343.y) * vec2<f32>(0.003921569f, 0.003921569f));
                if ((-24f + _e378) < -2f) {
                    phi_20840_ = 0f;
                    break;
                }
                let _e381 = global_11;
                let _e382 = (_e381 * (4f * exp2(((_e357 - (floor((_e357 / 32f)) * 32f)) * 0.33333334f))));
                let _e383 = floor(_e382);
                let _e384 = (_e382 - _e383);
                let _e388 = ((_e384 * _e384) * (vec3<f32>(3f, 3f, 3f) - (_e384 * 2f)));
                let _e390 = bitcast<vec3<u32>>(vec3<i32>(_e383));
                let _e399 = ((((_e390.x * 1597334677u) ^ (_e390.y * 3812015801u)) ^ (_e390.z * 2798796415u)) * 1597334677u);
                let _e408 = bitcast<vec3<u32>>(vec3<i32>((_e383 + vec3<f32>(1f, 0f, 0f))));
                let _e417 = ((((_e408.x * 1597334677u) ^ (_e408.y * 3812015801u)) ^ (_e408.z * 2798796415u)) * 1597334677u);
                let _e428 = bitcast<vec3<u32>>(vec3<i32>((_e383 + vec3<f32>(0f, 1f, 0f))));
                let _e437 = ((((_e428.x * 1597334677u) ^ (_e428.y * 3812015801u)) ^ (_e428.z * 2798796415u)) * 1597334677u);
                let _e446 = bitcast<vec3<u32>>(vec3<i32>((_e383 + vec3<f32>(1f, 1f, 0f))));
                let _e455 = ((((_e446.x * 1597334677u) ^ (_e446.y * 3812015801u)) ^ (_e446.z * 2798796415u)) * 1597334677u);
                let _e467 = bitcast<vec3<u32>>(vec3<i32>((_e383 + vec3<f32>(0f, 0f, 1f))));
                let _e476 = ((((_e467.x * 1597334677u) ^ (_e467.y * 3812015801u)) ^ (_e467.z * 2798796415u)) * 1597334677u);
                let _e485 = bitcast<vec3<u32>>(vec3<i32>((_e383 + vec3<f32>(1f, 0f, 1f))));
                let _e494 = ((((_e485.x * 1597334677u) ^ (_e485.y * 3812015801u)) ^ (_e485.z * 2798796415u)) * 1597334677u);
                let _e504 = bitcast<vec3<u32>>(vec3<i32>((_e383 + vec3<f32>(0f, 1f, 1f))));
                let _e513 = ((((_e504.x * 1597334677u) ^ (_e504.y * 3812015801u)) ^ (_e504.z * 2798796415u)) * 1597334677u);
                let _e522 = bitcast<vec3<u32>>(vec3<i32>((_e383 + vec3<f32>(1f, 1f, 1f))));
                let _e531 = ((((_e522.x * 1597334677u) ^ (_e522.y * 3812015801u)) ^ (_e522.z * 2798796415u)) * 1597334677u);
                let _e544 = ((_e382 * 2.7f) + vec3<f32>(17.3f, 5.1f, 9.7f));
                let _e545 = floor(_e544);
                let _e546 = (_e544 - _e545);
                let _e550 = ((_e546 * _e546) * (vec3<f32>(3f, 3f, 3f) - (_e546 * 2f)));
                let _e552 = bitcast<vec3<u32>>(vec3<i32>(_e545));
                let _e561 = ((((_e552.x * 1597334677u) ^ (_e552.y * 3812015801u)) ^ (_e552.z * 2798796415u)) * 1597334677u);
                let _e570 = bitcast<vec3<u32>>(vec3<i32>((_e545 + vec3<f32>(1f, 0f, 0f))));
                let _e579 = ((((_e570.x * 1597334677u) ^ (_e570.y * 3812015801u)) ^ (_e570.z * 2798796415u)) * 1597334677u);
                let _e590 = bitcast<vec3<u32>>(vec3<i32>((_e545 + vec3<f32>(0f, 1f, 0f))));
                let _e599 = ((((_e590.x * 1597334677u) ^ (_e590.y * 3812015801u)) ^ (_e590.z * 2798796415u)) * 1597334677u);
                let _e608 = bitcast<vec3<u32>>(vec3<i32>((_e545 + vec3<f32>(1f, 1f, 0f))));
                let _e617 = ((((_e608.x * 1597334677u) ^ (_e608.y * 3812015801u)) ^ (_e608.z * 2798796415u)) * 1597334677u);
                let _e629 = bitcast<vec3<u32>>(vec3<i32>((_e545 + vec3<f32>(0f, 0f, 1f))));
                let _e638 = ((((_e629.x * 1597334677u) ^ (_e629.y * 3812015801u)) ^ (_e629.z * 2798796415u)) * 1597334677u);
                let _e647 = bitcast<vec3<u32>>(vec3<i32>((_e545 + vec3<f32>(1f, 0f, 1f))));
                let _e656 = ((((_e647.x * 1597334677u) ^ (_e647.y * 3812015801u)) ^ (_e647.z * 2798796415u)) * 1597334677u);
                let _e666 = bitcast<vec3<u32>>(vec3<i32>((_e545 + vec3<f32>(0f, 1f, 1f))));
                let _e675 = ((((_e666.x * 1597334677u) ^ (_e666.y * 3812015801u)) ^ (_e666.z * 2798796415u)) * 1597334677u);
                let _e684 = bitcast<vec3<u32>>(vec3<i32>((_e545 + vec3<f32>(1f, 1f, 1f))));
                let _e693 = ((((_e684.x * 1597334677u) ^ (_e684.y * 3812015801u)) ^ (_e684.z * 2798796415u)) * 1597334677u);
                let _e706 = mix(0.45f, 0.05f, _e364);
                phi_20840_ = smoothstep(-(_e706), _e706, ((_e378 + -24.45f) + ((((mix(mix(mix((f32(((_e399 ^ (_e399 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e417 ^ (_e417 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e388.x), mix((f32(((_e437 ^ (_e437 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e455 ^ (_e455 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e388.x), _e388.y), mix(mix((f32(((_e476 ^ (_e476 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e494 ^ (_e494 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e388.x), mix((f32(((_e513 ^ (_e513 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e531 ^ (_e531 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e388.x), _e388.y), _e388.z) * 0.65f) + (mix(mix(mix((f32(((_e561 ^ (_e561 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e579 ^ (_e579 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e550.x), mix((f32(((_e599 ^ (_e599 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e617 ^ (_e617 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e550.x), _e550.y), mix(mix((f32(((_e638 ^ (_e638 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e656 ^ (_e656 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e550.x), mix((f32(((_e675 ^ (_e675 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e693 ^ (_e693 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e550.x), _e550.y), _e550.z) * 0.35f)) - 0.5f) * mix(0.8f, 2.2f, _e364))));
                break;
            }
        }
        let _e715 = phi_20840_;
        let _e717 = local_28;
        let _e7759 = local_55;
        phi_21003_ = _e7759;
        phi_20970_ = _e715;
        phi_20939_ = mix(_e327, ((_e286 * _e717) * mix(vec3<f32>(1f, 1f, 1f), (_e291 * 2f), vec3<f32>(0.5f, 0.5f, 0.5f))), vec3(_e715));
    }
    let _e725 = phi_21003_;
    let _e727 = phi_20970_;
    let _e729 = phi_20939_;
    let _e730 = global_9;
    let _e731 = normalize(_e730);
    let _e734 = global_8.member_6[1u];
    phi_20852_ = _e731;
    if (_e734 > 0.5f) {
        let _e736 = global_10;
        let _e737 = _e736.xyz;
        let _e740 = (_e737 - (_e731 * dot(_e731, _e737)));
        phi_20853_ = _e731;
        if (dot(_e740, _e740) > 0.000000000001f) {
            let _e743 = normalize(_e740);
            let _e746 = global_10[3u];
            let _e750 = textureSample(global_24, global_5, _e283);
            let _e753 = global_8.member_6[2u];
            if (_e753 > 0.5f) {
                if (_e753 > 1.5f) {
                    phi_20843_ = _e750.xw;
                } else {
                    phi_20843_ = _e750.xy;
                }
                let _e759 = phi_20843_;
                let _e761 = ((_e759 * 2f) - vec2<f32>(1f, 1f));
                phi_20844_ = vec3<f32>(_e761.x, _e761.y, sqrt(clamp((1f - dot(_e761, _e761)), 0f, 1f)));
            } else {
                phi_20844_ = ((_e750.xyz * 2f) - vec3<f32>(1f, 1f, 1f));
            }
            let _e773 = phi_20844_;
            let _e776 = global_8.member_4[2u];
            let _e778 = (_e773.xy * _e776);
            phi_20853_ = normalize((((_e743 * _e778.x) + ((cross(_e731, _e743) * select(1f, -1f, (_e746 < 0f))) * _e778.y)) + (_e731 * _e773.z)));
        }
        let _e789 = phi_20853_;
        phi_20852_ = _e789;
    }
    let _e791 = phi_20852_;
    let _e794 = global_8.member_5[3u];
    let _e795 = (_e794 > 0.5f);
    if _e795 {
        let _e798 = global_8.member_1[2u];
        phi_20849_ = clamp(_e798, 0f, 1f);
    } else {
        phi_20849_ = 0f;
    }
    let _e801 = phi_20849_;
    phi_3634_ = _e795;
    if _e795 {
        let _e802 = global_25;
        phi_3634_ = !(_e802);
    }
    let _e805 = phi_3634_;
    phi_21039_ = _e791;
    if (_e805 && (_e801 <= 0f)) {
        phi_21039_ = -(_e791);
    }
    let _e810 = phi_21039_;
    let _e812 = global.member_4;
    let _e814 = normalize(_e812.xyz);
    let _e816 = global.member_6;
    let _e817 = _e816.xyz;
    let _e818 = global_13;
    let _e819 = (_e817 - _e818);
    let _e820 = normalize(_e819);
    let _e822 = normalize((_e814 + _e820));
    let _e823 = global_25;
    let _e825 = (_e731 * select(-1f, 1f, _e823));
    let _e827 = global_26[0u];
    let _e828 = (_e827 > 0.5f);
    let _e831 = global.member_5[3u];
    phi_21073_ = 1f;
    phi_21033_ = _e729;
    if ((_e831 > 0.5f) && _e828) {
        switch bitcast<i32>(0u) {
            default: {
                let _e837 = global.member_21[0u];
                let _e838 = i32(_e837);
                let _e840 = global.member_20;
                let _e845 = global.member_20[3u];
                let _e846 = (dot(_e840.xyz, _e818) + _e845);
                phi_20854_ = 0i;
                loop {
                    let _e848 = phi_20854_;
                    local_29 = _e848;
                    local_30 = _e848;
                    local_31 = _e848;
                    local_32 = _e848;
                    local_33 = _e848;
                    local_34 = _e848;
                    local_36 = _e848;
                    local_37 = _e848;
                    local_38 = _e848;
                    let _e850 = (_e848 < (_e838 - 1i));
                    phi_5418_ = _e850;
                    if _e850 {
                        let _e853 = global.member_16[_e848];
                        phi_5418_ = (_e846 > _e853);
                    }
                    let _e856 = phi_5418_;
                    if _e856 {
                        continue;
                    } else {
                        break;
                    }
                    continuing {
                        phi_20854_ = (_e848 + 1i);
                    }
                }
                let _e860 = local_29;
                let _e862 = global.member_16[_e860];
                if (_e846 > _e862) {
                    phi_20910_ = vec3<f32>(1f, 1f, 1f);
                    phi_20909_ = 1f;
                    break;
                }
                let _e866 = local_30;
                let _e868 = global.member_18[_e866];
                let _e870 = (_e818 + (_e825 * _e868));
                switch bitcast<i32>(0u) {
                    default: {
                        let _e874 = local_31;
                        let _e876 = global.member_14[_e874];
                        let _e881 = (_e876 * vec4<f32>(_e870.x, _e870.y, _e870.z, 1f));
                        let _e883 = (_e881.x < 0f);
                        phi_5531_ = _e883;
                        if !(_e883) {
                            phi_5531_ = (_e881.x > 1f);
                        }
                        let _e887 = phi_5531_;
                        phi_5538_ = _e887;
                        if !(_e887) {
                            phi_5538_ = (_e881.y < 0f);
                        }
                        let _e892 = phi_5538_;
                        phi_5545_ = _e892;
                        if !(_e892) {
                            phi_5545_ = (_e881.y > 1f);
                        }
                        let _e897 = phi_5545_;
                        if _e897 {
                            phi_20867_ = 1f;
                            break;
                        }
                        let _e899 = local_32;
                        let _e903 = local_33;
                        let _e909 = global.member_23;
                        let _e910 = _e909.xy;
                        let _e911 = (vec2<f32>(f32((_e899 & 1i)), f32((_e903 >> bitcast<u32>(1i)))) * _e910);
                        let _e916 = local_34;
                        let _e918 = global.member_19[_e916];
                        let _e919 = (min(_e881.z, 1f) - _e918);
                        let _e922 = global.member_22;
                        let _e923 = _e922.xy;
                        let _e924 = (_e923 * 0.5f);
                        let _e926 = (_e911 + (_e881.xy * _e910));
                        let _e927 = (_e911 + _e924);
                        let _e929 = ((_e911 + _e910) - _e924);
                        let _e934 = vec4<f32>(_e927.x, _e927.y, _e929.x, _e929.y);
                        switch bitcast<i32>(0u) {
                            default: {
                                let _e938 = global.member_22[2u];
                                let _e939 = i32(_e938);
                                if (_e939 <= 0i) {
                                    let _e943 = clamp(_e926, _e934.xy, _e934.zw);
                                    let _e948 = textureSampleCompare(global_2, global_1, vec3<f32>(_e943.x, _e943.y, _e919).xy, _e919);
                                    phi_20866_ = _e948;
                                    break;
                                }
                                let _e950 = ((_e926 / _e923) + vec2<f32>(0.5f, 0.5f));
                                let _e951 = floor(_e950);
                                let _e952 = (_e950 - _e951);
                                let _e954 = (_e939 == 1i);
                                if _e954 {
                                    let _e955 = (_e952 * 2f);
                                    local_24[0i] = (vec2<f32>(3f, 3f) - _e955);
                                    local_24[1i] = (vec2<f32>(1f, 1f) + _e955);
                                    let _e961 = local_24[0i];
                                    local_25[0i] = (((vec2<f32>(2f, 2f) - _e952) / _e961) - vec2<f32>(1f, 1f));
                                    let _e965 = local_24[1i];
                                    local_25[1i] = ((_e952 / _e965) + vec2<f32>(1f, 1f));
                                } else {
                                    let _e969 = (_e952 * 3f);
                                    local_24[0i] = (vec2<f32>(4f, 4f) - _e969);
                                    local_24[1i] = vec2<f32>(7f, 7f);
                                    local_24[2i] = (vec2<f32>(1f, 1f) + _e969);
                                    let _e977 = local_24[0i];
                                    local_25[0i] = (((vec2<f32>(3f, 3f) - (_e952 * 2f)) / _e977) - vec2<f32>(2f, 2f));
                                    let _e982 = local_24[1i];
                                    local_25[1i] = ((vec2<f32>(3f, 3f) + _e952) / _e982);
                                    let _e985 = local_24[2i];
                                    local_25[2i] = ((_e952 / _e985) + vec2<f32>(2f, 2f));
                                }
                                let _e990 = select(3i, 2i, _e954);
                                phi_20859_ = 0f;
                                phi_20856_ = 0i;
                                loop {
                                    let _e992 = phi_20859_;
                                    let _e994 = phi_20856_;
                                    local_35 = _e992;
                                    if (_e994 < _e990) {
                                        phi_20865_ = _e992;
                                        phi_20862_ = 0i;
                                        loop {
                                            let _e997 = phi_20865_;
                                            let _e999 = phi_20862_;
                                            local_56 = _e997;
                                            if (_e999 < _e990) {
                                                continue;
                                            } else {
                                                break;
                                            }
                                            continuing {
                                                let _e1003 = local_25[_e999][0u];
                                                let _e1006 = local_25[_e994][1u];
                                                let _e1012 = clamp((_e923 * ((_e951 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e1003, _e1006))), _e934.xy, _e934.zw);
                                                let _e1015 = local_24[_e999][0u];
                                                let _e1018 = local_24[_e994][1u];
                                                let _e1024 = textureSampleCompare(global_2, global_1, vec3<f32>(_e1012.x, _e1012.y, _e919).xy, _e919);
                                                phi_20865_ = (_e997 + ((_e1015 * _e1018) * _e1024));
                                                phi_20862_ = (_e999 + 1i);
                                            }
                                        }
                                        continue;
                                    } else {
                                        break;
                                    }
                                    continuing {
                                        let _e7782 = local_56;
                                        phi_20859_ = _e7782;
                                        phi_20856_ = (_e994 + 1i);
                                    }
                                }
                                let _e1030 = local_35;
                                phi_20866_ = (_e1030 * select(0.0069444445f, 0.0625f, _e954));
                                break;
                            }
                        }
                        let _e1033 = phi_20866_;
                        phi_20867_ = _e1033;
                        break;
                    }
                }
                let _e1035 = phi_20867_;
                local_26 = array<vec3<f32>, 4>(vec3<f32>(1f, 0.45f, 0.45f), vec3<f32>(0.45f, 1f, 0.45f), vec3<f32>(0.5f, 0.6f, 1f), vec3<f32>(1f, 1f, 0.4f));
                let _e1037 = local_36;
                let _e1039 = local_26[_e1037];
                let _e1042 = local_37;
                let _e1044 = global.member_17[_e1042];
                phi_20907_ = _e1035;
                phi_20904_ = _e1039;
                if (_e846 > _e1044) {
                    let _e1048 = ((_e846 - _e1044) / (_e862 - _e1044));
                    let _e1050 = local_38;
                    let _e1051 = (_e1050 + 1i);
                    if (_e1051 < _e838) {
                        let _e1055 = global.member_18[_e1051];
                        let _e1057 = (_e818 + (_e825 * _e1055));
                        switch bitcast<i32>(0u) {
                            default: {
                                let _e1061 = global.member_14[_e1051];
                                let _e1066 = (_e1061 * vec4<f32>(_e1057.x, _e1057.y, _e1057.z, 1f));
                                let _e1068 = (_e1066.x < 0f);
                                phi_5818_ = _e1068;
                                if !(_e1068) {
                                    phi_5818_ = (_e1066.x > 1f);
                                }
                                let _e1072 = phi_5818_;
                                phi_5825_ = _e1072;
                                if !(_e1072) {
                                    phi_5825_ = (_e1066.y < 0f);
                                }
                                let _e1077 = phi_5825_;
                                phi_5832_ = _e1077;
                                if !(_e1077) {
                                    phi_5832_ = (_e1066.y > 1f);
                                }
                                let _e1082 = phi_5832_;
                                if _e1082 {
                                    phi_20887_ = 1f;
                                    break;
                                }
                                let _e1090 = global.member_23;
                                let _e1091 = _e1090.xy;
                                let _e1092 = (vec2<f32>(f32((_e1051 & 1i)), f32((_e1051 >> bitcast<u32>(1i)))) * _e1091);
                                let _e1097 = global.member_19[_e1051];
                                let _e1098 = (min(_e1066.z, 1f) - _e1097);
                                let _e1101 = global.member_22;
                                let _e1102 = _e1101.xy;
                                let _e1103 = (_e1102 * 0.5f);
                                let _e1105 = (_e1092 + (_e1066.xy * _e1091));
                                let _e1106 = (_e1092 + _e1103);
                                let _e1108 = ((_e1092 + _e1091) - _e1103);
                                let _e1113 = vec4<f32>(_e1106.x, _e1106.y, _e1108.x, _e1108.y);
                                switch bitcast<i32>(0u) {
                                    default: {
                                        let _e1117 = global.member_22[2u];
                                        let _e1118 = i32(_e1117);
                                        if (_e1118 <= 0i) {
                                            let _e1122 = clamp(_e1105, _e1113.xy, _e1113.zw);
                                            let _e1127 = textureSampleCompare(global_2, global_1, vec3<f32>(_e1122.x, _e1122.y, _e1098).xy, _e1098);
                                            phi_20886_ = _e1127;
                                            break;
                                        }
                                        let _e1129 = ((_e1105 / _e1102) + vec2<f32>(0.5f, 0.5f));
                                        let _e1130 = floor(_e1129);
                                        let _e1131 = (_e1129 - _e1130);
                                        let _e1133 = (_e1118 == 1i);
                                        if _e1133 {
                                            let _e1134 = (_e1131 * 2f);
                                            local_22[0i] = (vec2<f32>(3f, 3f) - _e1134);
                                            local_22[1i] = (vec2<f32>(1f, 1f) + _e1134);
                                            let _e1140 = local_22[0i];
                                            local_23[0i] = (((vec2<f32>(2f, 2f) - _e1131) / _e1140) - vec2<f32>(1f, 1f));
                                            let _e1144 = local_22[1i];
                                            local_23[1i] = ((_e1131 / _e1144) + vec2<f32>(1f, 1f));
                                        } else {
                                            let _e1148 = (_e1131 * 3f);
                                            local_22[0i] = (vec2<f32>(4f, 4f) - _e1148);
                                            local_22[1i] = vec2<f32>(7f, 7f);
                                            local_22[2i] = (vec2<f32>(1f, 1f) + _e1148);
                                            let _e1156 = local_22[0i];
                                            local_23[0i] = (((vec2<f32>(3f, 3f) - (_e1131 * 2f)) / _e1156) - vec2<f32>(2f, 2f));
                                            let _e1161 = local_22[1i];
                                            local_23[1i] = ((vec2<f32>(3f, 3f) + _e1131) / _e1161);
                                            let _e1164 = local_22[2i];
                                            local_23[2i] = ((_e1131 / _e1164) + vec2<f32>(2f, 2f));
                                        }
                                        let _e1169 = select(3i, 2i, _e1133);
                                        phi_20879_ = 0f;
                                        phi_20876_ = 0i;
                                        loop {
                                            let _e1171 = phi_20879_;
                                            let _e1173 = phi_20876_;
                                            local_39 = _e1171;
                                            if (_e1173 < _e1169) {
                                                phi_20885_ = _e1171;
                                                phi_20882_ = 0i;
                                                loop {
                                                    let _e1176 = phi_20885_;
                                                    let _e1178 = phi_20882_;
                                                    local_57 = _e1176;
                                                    if (_e1178 < _e1169) {
                                                        continue;
                                                    } else {
                                                        break;
                                                    }
                                                    continuing {
                                                        let _e1182 = local_23[_e1178][0u];
                                                        let _e1185 = local_23[_e1173][1u];
                                                        let _e1191 = clamp((_e1102 * ((_e1130 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e1182, _e1185))), _e1113.xy, _e1113.zw);
                                                        let _e1194 = local_22[_e1178][0u];
                                                        let _e1197 = local_22[_e1173][1u];
                                                        let _e1203 = textureSampleCompare(global_2, global_1, vec3<f32>(_e1191.x, _e1191.y, _e1098).xy, _e1098);
                                                        phi_20885_ = (_e1176 + ((_e1194 * _e1197) * _e1203));
                                                        phi_20882_ = (_e1178 + 1i);
                                                    }
                                                }
                                                continue;
                                            } else {
                                                break;
                                            }
                                            continuing {
                                                let _e7797 = local_57;
                                                phi_20879_ = _e7797;
                                                phi_20876_ = (_e1173 + 1i);
                                            }
                                        }
                                        let _e1209 = local_39;
                                        phi_20886_ = (_e1209 * select(0.0069444445f, 0.0625f, _e1133));
                                        break;
                                    }
                                }
                                let _e1212 = phi_20886_;
                                phi_20887_ = _e1212;
                                break;
                            }
                        }
                        let _e1214 = phi_20887_;
                        local_27 = array<vec3<f32>, 4>(vec3<f32>(1f, 0.45f, 0.45f), vec3<f32>(0.45f, 1f, 0.45f), vec3<f32>(0.5f, 0.6f, 1f), vec3<f32>(1f, 1f, 0.4f));
                        let _e1217 = local_27[_e1051];
                        phi_20908_ = mix(_e1035, _e1214, _e1048);
                        phi_20905_ = mix(_e1039, _e1217, vec3(_e1048));
                    } else {
                        phi_20908_ = mix(_e1035, 1f, _e1048);
                        phi_20905_ = _e1039;
                    }
                    let _e1222 = phi_20908_;
                    let _e1224 = phi_20905_;
                    phi_20907_ = _e1222;
                    phi_20904_ = _e1224;
                }
                let _e1226 = phi_20907_;
                let _e1228 = phi_20904_;
                let _e1231 = global.member_22[3u];
                phi_20910_ = select(vec3<f32>(1f, 1f, 1f), _e1228, vec3((_e1231 > 0.5f)));
                phi_20909_ = _e1226;
                break;
            }
        }
        let _e1236 = phi_20910_;
        let _e1238 = phi_20909_;
        phi_21073_ = _e1238;
        phi_21033_ = (_e729 * _e1236);
    }
    let _e1241 = phi_21073_;
    let _e1243 = phi_21033_;
    let _e1245 = global.member_5;
    let _e1249 = global.member_4[3u];
    let _e1250 = (_e1245.xyz * _e1249);
    let _e1253 = global_8.member_6[3u];
    let _e1254 = (_e1253 > 0.5f);
    if _e1254 {
        phi_20962_ = 1f;
    } else {
        let _e1257 = global_8.member_4[3u];
        let _e1258 = textureSample(global_19, global_5, _e283);
        phi_20962_ = (1f + (_e1257 * (_e1258.x - 1f)));
    }
    let _e1264 = phi_20962_;
    let _e1266 = global_10[3u];
    let _e1267 = abs(_e1266);
    phi_21163_ = _e1264;
    if (_e1267 > 0f) {
        phi_21163_ = (_e1264 * min(_e1267, 1f));
    }
    let _e1272 = phi_21163_;
    if !(_e795) {
        let _e1274 = dot(_e810, _e814);
        let _e1281 = global_8.member_1[3u];
        let _e1285 = global_8.member_1[2u];
        let _e1292 = global.member_29[0u];
        let _e1293 = (_e1292 > 0.5f);
        if _e1293 {
            let _e1295 = global.member_29;
            let _e1302 = ((_e1295.z * _e810.x) - (_e1295.w * _e810.z));
            let _e1306 = ((_e1295.w * _e810.x) + (_e1295.z * _e810.z));
            let _e1310 = (1.092548f * _e1302);
            local_21 = array<f32, 9>(0.282095f, (0.488603f * _e810.y), (0.488603f * _e1306), (0.488603f * _e1302), (_e1310 * _e810.y), ((1.092548f * _e810.y) * _e1306), (0.315392f * (((3f * _e1306) * _e1306) - 1f)), (_e1310 * _e1306), (0.546274f * ((_e1302 * _e1302) - (_e810.y * _e810.y))));
            phi_21690_ = vec3<f32>(0f, 0f, 0f);
            phi_21689_ = 0i;
            loop {
                let _e1325 = phi_21690_;
                let _e1327 = phi_21689_;
                local_40 = _e1325;
                if (_e1327 < 9i) {
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e1331 = textureLoad(global_4, (vec2<i32>(496i, 256i) + vec2<i32>(_e1327, 0i)), 0i);
                    let _e1334 = local_21[_e1327];
                    phi_21690_ = (_e1325 + (_e1331.xyz * _e1334));
                    phi_21689_ = (_e1327 + 1i);
                }
            }
            let _e1339 = local_40;
            let _e1343 = global.member_29[1u];
            phi_21691_ = (max(_e1339, vec3<f32>(0f, 0f, 0f)) * _e1343);
        } else {
            let _e1346 = global.member_9;
            let _e1349 = global.member_8;
            let _e1358 = global.member_8[3u];
            phi_21691_ = (mix(_e1346.xyz, _e1349.xyz, vec3(((_e810.y * 0.5f) + 0.5f))) * _e1358);
        }
        let _e1361 = phi_21691_;
        let _e1367 = ((_e1243 * ((_e1361 * _e1272) + ((_e1250 * max(_e1274, 0f)) * _e1241))) + ((_e1250 * ((pow(max(dot(_e810, _e822), 0f), _e1281) * _e1285) * step(0f, _e1274))) * _e1241));
        let _e1370 = global.member_34[1u];
        phi_21718_ = _e1367;
        if (_e1370 > 0.5f) {
            if _e1293 {
                let _e1373 = global.member_29;
                let _e1380 = ((_e1373.z * _e810.x) - (_e1373.w * _e810.z));
                let _e1384 = ((_e1373.w * _e810.x) + (_e1373.z * _e810.z));
                let _e1388 = (1.092548f * _e1380);
                local_20 = array<f32, 9>(0.282095f, (0.488603f * _e810.y), (0.488603f * _e1384), (0.488603f * _e1380), (_e1388 * _e810.y), ((1.092548f * _e810.y) * _e1384), (0.315392f * (((3f * _e1384) * _e1384) - 1f)), (_e1388 * _e1384), (0.546274f * ((_e1380 * _e1380) - (_e810.y * _e810.y))));
                phi_21701_ = vec3<f32>(0f, 0f, 0f);
                phi_21700_ = 0i;
                loop {
                    let _e1403 = phi_21701_;
                    let _e1405 = phi_21700_;
                    local_41 = _e1403;
                    if (_e1405 < 9i) {
                        continue;
                    } else {
                        break;
                    }
                    continuing {
                        let _e1409 = textureLoad(global_4, (vec2<i32>(496i, 256i) + vec2<i32>(_e1405, 0i)), 0i);
                        let _e1412 = local_20[_e1405];
                        phi_21701_ = (_e1403 + (_e1409.xyz * _e1412));
                        phi_21700_ = (_e1405 + 1i);
                    }
                }
                let _e1417 = local_41;
                let _e1421 = global.member_29[1u];
                phi_21702_ = (max(_e1417, vec3<f32>(0f, 0f, 0f)) * _e1421);
            } else {
                let _e1424 = global.member_9;
                let _e1427 = global.member_8;
                let _e1436 = global.member_8[3u];
                phi_21702_ = (mix(_e1424.xyz, _e1427.xyz, vec3(((_e810.y * 0.5f) + 0.5f))) * _e1436);
            }
            let _e1439 = phi_21702_;
            let _e1443 = global.member_34[0u];
            phi_21708_ = _e1439;
            phi_21707_ = 0i;
            loop {
                let _e1446 = phi_21708_;
                let _e1448 = phi_21707_;
                local_42 = _e1446;
                if (_e1448 < i32(_e1370)) {
                    let _e1451 = (8i * (i32(_e1443) + _e1448));
                    let _e1455 = global_3.member[(_e1451 + 3i)];
                    let _e1456 = bitcast<vec4<f32>>(_e1455);
                    let _e1459 = global_3.member[_e1451];
                    let _e1460 = bitcast<vec4<f32>>(_e1459);
                    let _e1464 = global_3.member[(_e1451 + 1i)];
                    let _e1465 = bitcast<vec4<f32>>(_e1464);
                    let _e1469 = global_3.member[(_e1451 + 2i)];
                    let _e1470 = bitcast<vec4<f32>>(_e1469);
                    let _e1471 = _e1460.xyz;
                    let _e1475 = _e1465.xyz;
                    let _e1479 = _e1470.xyz;
                    let _e1483 = vec3<f32>((dot(_e1471, _e818) + _e1460.w), (dot(_e1475, _e818) + _e1465.w), (dot(_e1479, _e818) + _e1470.w));
                    let _e1484 = _e1456.xyz;
                    switch bitcast<i32>(0u) {
                        default: {
                            let _e1488 = (_e1484 - abs(_e1483));
                            let _e1493 = min(_e1488.x, min(_e1488.y, _e1488.z));
                            if (_e1493 <= 0f) {
                                phi_21969_ = 0f;
                                break;
                            }
                            if (_e1456.w <= 0f) {
                                phi_21969_ = 1f;
                                break;
                            }
                            let _e1497 = min((_e1493 / _e1456.w), 1f);
                            phi_21969_ = ((_e1497 * _e1497) * (3f - (2f * _e1497)));
                            break;
                        }
                    }
                    let _e1503 = phi_21969_;
                    if (_e1503 <= 0f) {
                        phi_22006_ = _e1446;
                        continue;
                    }
                    let _e1508 = global_3.member[(_e1451 + 4i)];
                    let _e1510 = bitcast<vec4<f32>>(_e1508).xyz;
                    let _e1514 = global_3.member[(_e1451 + 5i)];
                    let _e1515 = bitcast<vec4<f32>>(_e1514);
                    let _e1520 = global_3.member[(_e1451 + 6i)][0u];
                    let _e1521 = bitcast<i32>(_e1520);
                    let _e1522 = dot(_e1471, _e810);
                    let _e1523 = dot(_e1475, _e810);
                    let _e1524 = dot(_e1479, _e810);
                    let _e1525 = vec3<f32>(_e1522, _e1523, _e1524);
                    let _e1531 = ((_e818 + (_e810 * _e1515.x)) + (_e820 * _e1515.y));
                    let _e1546 = clamp(((((vec3<f32>((dot(_e1471, _e1531) + _e1460.w), (dot(_e1475, _e1531) + _e1465.w), (dot(_e1479, _e1531) + _e1470.w)) + _e1484) / max((_e1484 * 2f), vec3<f32>(0.000001f, 0.000001f, 0.000001f))) * _e1510) - vec3<f32>(0.5f, 0.5f, 0.5f)), vec3<f32>(0f, 0f, 0f), (_e1510 - vec3<f32>(1f, 1f, 1f)));
                    let _e1547 = vec3<i32>(_e1510);
                    let _e1551 = min(vec3<i32>(_e1546), max((_e1547 - vec3<i32>(2i, 2i, 2i)), vec3<i32>(0i, 0i, 0i)));
                    let _e1553 = (_e1546 - vec3<f32>(_e1551));
                    let _e1554 = (0.488603f * _e1523);
                    let _e1555 = (0.488603f * _e1524);
                    let _e1556 = (0.488603f * _e1522);
                    let _e1557 = (1.092548f * _e1522);
                    let _e1558 = (_e1557 * _e1523);
                    let _e1560 = ((1.092548f * _e1523) * _e1524);
                    let _e1564 = (0.315392f * (((3f * _e1524) * _e1524) - 1f));
                    let _e1565 = (_e1557 * _e1524);
                    let _e1569 = (0.546274f * ((_e1522 * _e1522) - (_e1523 * _e1523)));
                    let _e1570 = (_e1547 - vec3<i32>(1i, 1i, 1i));
                    let _e1571 = min(_e1551, _e1570);
                    let _e1582 = (_e1521 + ((_e1571.x + (_e1547.x * (_e1571.y + (_e1547.y * _e1571.z)))) * 4i));
                    let _e1583 = (vec3<f32>(1f, 1f, 1f) - _e1553);
                    let _e1590 = ((((((vec3<f32>(_e1571) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e1510) * _e1484) * 2f) - _e1484) - _e1483);
                    let _e1596 = (dot((_e1590 * inverseSqrt(max(dot(_e1590, _e1590), 0.0000000001f))), _e1525) + 1f);
                    let _e1599 = (_e1583.x * _e1583.y);
                    let _e1606 = (_e1582 + 3i);
                    let _e1610 = global_3.member[_e1606][1u];
                    let _e1615 = (((_e1599 * _e1583.z) * ((0.25f * (_e1596 * _e1596)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e1610).y > 0.5f)));
                    let _e1618 = global_3.member[_e1582];
                    let _e1622 = global_3.member[(_e1582 + 1i)];
                    let _e1626 = global_3.member[(_e1582 + 2i)];
                    let _e1629 = global_3.member[_e1606];
                    let _e1631 = unpack2x16float(_e1618.x);
                    let _e1633 = unpack2x16float(_e1618.y);
                    let _e1635 = unpack2x16float(_e1618.z);
                    let _e1637 = unpack2x16float(_e1618.w);
                    let _e1639 = unpack2x16float(_e1622.x);
                    let _e1641 = unpack2x16float(_e1622.y);
                    let _e1643 = unpack2x16float(_e1622.z);
                    let _e1645 = unpack2x16float(_e1622.w);
                    let _e1647 = unpack2x16float(_e1626.x);
                    let _e1649 = unpack2x16float(_e1626.y);
                    let _e1651 = unpack2x16float(_e1626.z);
                    let _e1653 = unpack2x16float(_e1626.w);
                    let _e1655 = unpack2x16float(_e1629.x);
                    let _e1711 = ((((((((((vec3<f32>(_e1631.x, _e1631.y, _e1633.x) * 0.282095f) + (vec3<f32>(_e1633.y, _e1635.x, _e1635.y) * _e1554)) + (vec3<f32>(_e1637.x, _e1637.y, _e1639.x) * _e1555)) + (vec3<f32>(_e1639.y, _e1641.x, _e1641.y) * _e1556)) + (vec3<f32>(_e1643.x, _e1643.y, _e1645.x) * _e1558)) + (vec3<f32>(_e1645.y, _e1647.x, _e1647.y) * _e1560)) + (vec3<f32>(_e1649.x, _e1649.y, _e1651.x) * _e1564)) + (vec3<f32>(_e1651.y, _e1653.x, _e1653.y) * _e1565)) + (vec3<f32>(_e1655.x, _e1655.y, unpack2x16float(_e1629.y).x) * _e1569)) * _e1615);
                    let _e1717 = min((_e1551 + vec3<i32>(1i, 0i, 0i)), _e1570);
                    let _e1726 = (_e1521 + ((_e1717.x + (_e1547.x * (_e1717.y + (_e1547.y * _e1717.z)))) * 4i));
                    let _e1733 = ((((((vec3<f32>(_e1717) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e1510) * _e1484) * 2f) - _e1484) - _e1483);
                    let _e1739 = (dot((_e1733 * inverseSqrt(max(dot(_e1733, _e1733), 0.0000000001f))), _e1525) + 1f);
                    let _e1741 = (_e1553.x * _e1583.y);
                    let _e1747 = (_e1726 + 3i);
                    let _e1751 = global_3.member[_e1747][1u];
                    let _e1756 = (((_e1741 * _e1583.z) * ((0.25f * (_e1739 * _e1739)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e1751).y > 0.5f)));
                    let _e1759 = global_3.member[_e1726];
                    let _e1763 = global_3.member[(_e1726 + 1i)];
                    let _e1767 = global_3.member[(_e1726 + 2i)];
                    let _e1770 = global_3.member[_e1747];
                    let _e1772 = unpack2x16float(_e1759.x);
                    let _e1774 = unpack2x16float(_e1759.y);
                    let _e1776 = unpack2x16float(_e1759.z);
                    let _e1778 = unpack2x16float(_e1759.w);
                    let _e1780 = unpack2x16float(_e1763.x);
                    let _e1782 = unpack2x16float(_e1763.y);
                    let _e1784 = unpack2x16float(_e1763.z);
                    let _e1786 = unpack2x16float(_e1763.w);
                    let _e1788 = unpack2x16float(_e1767.x);
                    let _e1790 = unpack2x16float(_e1767.y);
                    let _e1792 = unpack2x16float(_e1767.z);
                    let _e1794 = unpack2x16float(_e1767.w);
                    let _e1796 = unpack2x16float(_e1770.x);
                    let _e1852 = ((((((((((vec3<f32>(_e1772.x, _e1772.y, _e1774.x) * 0.282095f) + (vec3<f32>(_e1774.y, _e1776.x, _e1776.y) * _e1554)) + (vec3<f32>(_e1778.x, _e1778.y, _e1780.x) * _e1555)) + (vec3<f32>(_e1780.y, _e1782.x, _e1782.y) * _e1556)) + (vec3<f32>(_e1784.x, _e1784.y, _e1786.x) * _e1558)) + (vec3<f32>(_e1786.y, _e1788.x, _e1788.y) * _e1560)) + (vec3<f32>(_e1790.x, _e1790.y, _e1792.x) * _e1564)) + (vec3<f32>(_e1792.y, _e1794.x, _e1794.y) * _e1565)) + (vec3<f32>(_e1796.x, _e1796.y, unpack2x16float(_e1770.y).x) * _e1569)) * _e1756);
                    let _e1859 = min((_e1551 + vec3<i32>(0i, 1i, 0i)), _e1570);
                    let _e1868 = (_e1521 + ((_e1859.x + (_e1547.x * (_e1859.y + (_e1547.y * _e1859.z)))) * 4i));
                    let _e1875 = ((((((vec3<f32>(_e1859) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e1510) * _e1484) * 2f) - _e1484) - _e1483);
                    let _e1881 = (dot((_e1875 * inverseSqrt(max(dot(_e1875, _e1875), 0.0000000001f))), _e1525) + 1f);
                    let _e1883 = (_e1583.x * _e1553.y);
                    let _e1889 = (_e1868 + 3i);
                    let _e1893 = global_3.member[_e1889][1u];
                    let _e1898 = (((_e1883 * _e1583.z) * ((0.25f * (_e1881 * _e1881)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e1893).y > 0.5f)));
                    let _e1901 = global_3.member[_e1868];
                    let _e1905 = global_3.member[(_e1868 + 1i)];
                    let _e1909 = global_3.member[(_e1868 + 2i)];
                    let _e1912 = global_3.member[_e1889];
                    let _e1914 = unpack2x16float(_e1901.x);
                    let _e1916 = unpack2x16float(_e1901.y);
                    let _e1918 = unpack2x16float(_e1901.z);
                    let _e1920 = unpack2x16float(_e1901.w);
                    let _e1922 = unpack2x16float(_e1905.x);
                    let _e1924 = unpack2x16float(_e1905.y);
                    let _e1926 = unpack2x16float(_e1905.z);
                    let _e1928 = unpack2x16float(_e1905.w);
                    let _e1930 = unpack2x16float(_e1909.x);
                    let _e1932 = unpack2x16float(_e1909.y);
                    let _e1934 = unpack2x16float(_e1909.z);
                    let _e1936 = unpack2x16float(_e1909.w);
                    let _e1938 = unpack2x16float(_e1912.x);
                    let _e1994 = ((((((((((vec3<f32>(_e1914.x, _e1914.y, _e1916.x) * 0.282095f) + (vec3<f32>(_e1916.y, _e1918.x, _e1918.y) * _e1554)) + (vec3<f32>(_e1920.x, _e1920.y, _e1922.x) * _e1555)) + (vec3<f32>(_e1922.y, _e1924.x, _e1924.y) * _e1556)) + (vec3<f32>(_e1926.x, _e1926.y, _e1928.x) * _e1558)) + (vec3<f32>(_e1928.y, _e1930.x, _e1930.y) * _e1560)) + (vec3<f32>(_e1932.x, _e1932.y, _e1934.x) * _e1564)) + (vec3<f32>(_e1934.y, _e1936.x, _e1936.y) * _e1565)) + (vec3<f32>(_e1938.x, _e1938.y, unpack2x16float(_e1912.y).x) * _e1569)) * _e1898);
                    let _e2001 = min((_e1551 + vec3<i32>(1i, 1i, 0i)), _e1570);
                    let _e2010 = (_e1521 + ((_e2001.x + (_e1547.x * (_e2001.y + (_e1547.y * _e2001.z)))) * 4i));
                    let _e2017 = ((((((vec3<f32>(_e2001) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e1510) * _e1484) * 2f) - _e1484) - _e1483);
                    let _e2023 = (dot((_e2017 * inverseSqrt(max(dot(_e2017, _e2017), 0.0000000001f))), _e1525) + 1f);
                    let _e2024 = (_e1553.x * _e1553.y);
                    let _e2030 = (_e2010 + 3i);
                    let _e2034 = global_3.member[_e2030][1u];
                    let _e2039 = (((_e2024 * _e1583.z) * ((0.25f * (_e2023 * _e2023)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e2034).y > 0.5f)));
                    let _e2042 = global_3.member[_e2010];
                    let _e2046 = global_3.member[(_e2010 + 1i)];
                    let _e2050 = global_3.member[(_e2010 + 2i)];
                    let _e2053 = global_3.member[_e2030];
                    let _e2055 = unpack2x16float(_e2042.x);
                    let _e2057 = unpack2x16float(_e2042.y);
                    let _e2059 = unpack2x16float(_e2042.z);
                    let _e2061 = unpack2x16float(_e2042.w);
                    let _e2063 = unpack2x16float(_e2046.x);
                    let _e2065 = unpack2x16float(_e2046.y);
                    let _e2067 = unpack2x16float(_e2046.z);
                    let _e2069 = unpack2x16float(_e2046.w);
                    let _e2071 = unpack2x16float(_e2050.x);
                    let _e2073 = unpack2x16float(_e2050.y);
                    let _e2075 = unpack2x16float(_e2050.z);
                    let _e2077 = unpack2x16float(_e2050.w);
                    let _e2079 = unpack2x16float(_e2053.x);
                    let _e2135 = ((((((((((vec3<f32>(_e2055.x, _e2055.y, _e2057.x) * 0.282095f) + (vec3<f32>(_e2057.y, _e2059.x, _e2059.y) * _e1554)) + (vec3<f32>(_e2061.x, _e2061.y, _e2063.x) * _e1555)) + (vec3<f32>(_e2063.y, _e2065.x, _e2065.y) * _e1556)) + (vec3<f32>(_e2067.x, _e2067.y, _e2069.x) * _e1558)) + (vec3<f32>(_e2069.y, _e2071.x, _e2071.y) * _e1560)) + (vec3<f32>(_e2073.x, _e2073.y, _e2075.x) * _e1564)) + (vec3<f32>(_e2075.y, _e2077.x, _e2077.y) * _e1565)) + (vec3<f32>(_e2079.x, _e2079.y, unpack2x16float(_e2053.y).x) * _e1569)) * _e2039);
                    let _e2142 = min((_e1551 + vec3<i32>(0i, 0i, 1i)), _e1570);
                    let _e2151 = (_e1521 + ((_e2142.x + (_e1547.x * (_e2142.y + (_e1547.y * _e2142.z)))) * 4i));
                    let _e2158 = ((((((vec3<f32>(_e2142) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e1510) * _e1484) * 2f) - _e1484) - _e1483);
                    let _e2164 = (dot((_e2158 * inverseSqrt(max(dot(_e2158, _e2158), 0.0000000001f))), _e1525) + 1f);
                    let _e2171 = (_e2151 + 3i);
                    let _e2175 = global_3.member[_e2171][1u];
                    let _e2180 = (((_e1599 * _e1553.z) * ((0.25f * (_e2164 * _e2164)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e2175).y > 0.5f)));
                    let _e2183 = global_3.member[_e2151];
                    let _e2187 = global_3.member[(_e2151 + 1i)];
                    let _e2191 = global_3.member[(_e2151 + 2i)];
                    let _e2194 = global_3.member[_e2171];
                    let _e2196 = unpack2x16float(_e2183.x);
                    let _e2198 = unpack2x16float(_e2183.y);
                    let _e2200 = unpack2x16float(_e2183.z);
                    let _e2202 = unpack2x16float(_e2183.w);
                    let _e2204 = unpack2x16float(_e2187.x);
                    let _e2206 = unpack2x16float(_e2187.y);
                    let _e2208 = unpack2x16float(_e2187.z);
                    let _e2210 = unpack2x16float(_e2187.w);
                    let _e2212 = unpack2x16float(_e2191.x);
                    let _e2214 = unpack2x16float(_e2191.y);
                    let _e2216 = unpack2x16float(_e2191.z);
                    let _e2218 = unpack2x16float(_e2191.w);
                    let _e2220 = unpack2x16float(_e2194.x);
                    let _e2276 = ((((((((((vec3<f32>(_e2196.x, _e2196.y, _e2198.x) * 0.282095f) + (vec3<f32>(_e2198.y, _e2200.x, _e2200.y) * _e1554)) + (vec3<f32>(_e2202.x, _e2202.y, _e2204.x) * _e1555)) + (vec3<f32>(_e2204.y, _e2206.x, _e2206.y) * _e1556)) + (vec3<f32>(_e2208.x, _e2208.y, _e2210.x) * _e1558)) + (vec3<f32>(_e2210.y, _e2212.x, _e2212.y) * _e1560)) + (vec3<f32>(_e2214.x, _e2214.y, _e2216.x) * _e1564)) + (vec3<f32>(_e2216.y, _e2218.x, _e2218.y) * _e1565)) + (vec3<f32>(_e2220.x, _e2220.y, unpack2x16float(_e2194.y).x) * _e1569)) * _e2180);
                    let _e2283 = min((_e1551 + vec3<i32>(1i, 0i, 1i)), _e1570);
                    let _e2292 = (_e1521 + ((_e2283.x + (_e1547.x * (_e2283.y + (_e1547.y * _e2283.z)))) * 4i));
                    let _e2299 = ((((((vec3<f32>(_e2283) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e1510) * _e1484) * 2f) - _e1484) - _e1483);
                    let _e2305 = (dot((_e2299 * inverseSqrt(max(dot(_e2299, _e2299), 0.0000000001f))), _e1525) + 1f);
                    let _e2311 = (_e2292 + 3i);
                    let _e2315 = global_3.member[_e2311][1u];
                    let _e2320 = (((_e1741 * _e1553.z) * ((0.25f * (_e2305 * _e2305)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e2315).y > 0.5f)));
                    let _e2323 = global_3.member[_e2292];
                    let _e2327 = global_3.member[(_e2292 + 1i)];
                    let _e2331 = global_3.member[(_e2292 + 2i)];
                    let _e2334 = global_3.member[_e2311];
                    let _e2336 = unpack2x16float(_e2323.x);
                    let _e2338 = unpack2x16float(_e2323.y);
                    let _e2340 = unpack2x16float(_e2323.z);
                    let _e2342 = unpack2x16float(_e2323.w);
                    let _e2344 = unpack2x16float(_e2327.x);
                    let _e2346 = unpack2x16float(_e2327.y);
                    let _e2348 = unpack2x16float(_e2327.z);
                    let _e2350 = unpack2x16float(_e2327.w);
                    let _e2352 = unpack2x16float(_e2331.x);
                    let _e2354 = unpack2x16float(_e2331.y);
                    let _e2356 = unpack2x16float(_e2331.z);
                    let _e2358 = unpack2x16float(_e2331.w);
                    let _e2360 = unpack2x16float(_e2334.x);
                    let _e2416 = ((((((((((vec3<f32>(_e2336.x, _e2336.y, _e2338.x) * 0.282095f) + (vec3<f32>(_e2338.y, _e2340.x, _e2340.y) * _e1554)) + (vec3<f32>(_e2342.x, _e2342.y, _e2344.x) * _e1555)) + (vec3<f32>(_e2344.y, _e2346.x, _e2346.y) * _e1556)) + (vec3<f32>(_e2348.x, _e2348.y, _e2350.x) * _e1558)) + (vec3<f32>(_e2350.y, _e2352.x, _e2352.y) * _e1560)) + (vec3<f32>(_e2354.x, _e2354.y, _e2356.x) * _e1564)) + (vec3<f32>(_e2356.y, _e2358.x, _e2358.y) * _e1565)) + (vec3<f32>(_e2360.x, _e2360.y, unpack2x16float(_e2334.y).x) * _e1569)) * _e2320);
                    let _e2423 = min((_e1551 + vec3<i32>(0i, 1i, 1i)), _e1570);
                    let _e2432 = (_e1521 + ((_e2423.x + (_e1547.x * (_e2423.y + (_e1547.y * _e2423.z)))) * 4i));
                    let _e2439 = ((((((vec3<f32>(_e2423) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e1510) * _e1484) * 2f) - _e1484) - _e1483);
                    let _e2445 = (dot((_e2439 * inverseSqrt(max(dot(_e2439, _e2439), 0.0000000001f))), _e1525) + 1f);
                    let _e2451 = (_e2432 + 3i);
                    let _e2455 = global_3.member[_e2451][1u];
                    let _e2460 = (((_e1883 * _e1553.z) * ((0.25f * (_e2445 * _e2445)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e2455).y > 0.5f)));
                    let _e2463 = global_3.member[_e2432];
                    let _e2467 = global_3.member[(_e2432 + 1i)];
                    let _e2471 = global_3.member[(_e2432 + 2i)];
                    let _e2474 = global_3.member[_e2451];
                    let _e2476 = unpack2x16float(_e2463.x);
                    let _e2478 = unpack2x16float(_e2463.y);
                    let _e2480 = unpack2x16float(_e2463.z);
                    let _e2482 = unpack2x16float(_e2463.w);
                    let _e2484 = unpack2x16float(_e2467.x);
                    let _e2486 = unpack2x16float(_e2467.y);
                    let _e2488 = unpack2x16float(_e2467.z);
                    let _e2490 = unpack2x16float(_e2467.w);
                    let _e2492 = unpack2x16float(_e2471.x);
                    let _e2494 = unpack2x16float(_e2471.y);
                    let _e2496 = unpack2x16float(_e2471.z);
                    let _e2498 = unpack2x16float(_e2471.w);
                    let _e2500 = unpack2x16float(_e2474.x);
                    let _e2556 = ((((((((((vec3<f32>(_e2476.x, _e2476.y, _e2478.x) * 0.282095f) + (vec3<f32>(_e2478.y, _e2480.x, _e2480.y) * _e1554)) + (vec3<f32>(_e2482.x, _e2482.y, _e2484.x) * _e1555)) + (vec3<f32>(_e2484.y, _e2486.x, _e2486.y) * _e1556)) + (vec3<f32>(_e2488.x, _e2488.y, _e2490.x) * _e1558)) + (vec3<f32>(_e2490.y, _e2492.x, _e2492.y) * _e1560)) + (vec3<f32>(_e2494.x, _e2494.y, _e2496.x) * _e1564)) + (vec3<f32>(_e2496.y, _e2498.x, _e2498.y) * _e1565)) + (vec3<f32>(_e2500.x, _e2500.y, unpack2x16float(_e2474.y).x) * _e1569)) * _e2460);
                    let _e2563 = min((_e1551 + vec3<i32>(1i, 1i, 1i)), _e1570);
                    let _e2572 = (_e1521 + ((_e2563.x + (_e1547.x * (_e2563.y + (_e1547.y * _e2563.z)))) * 4i));
                    let _e2579 = ((((((vec3<f32>(_e2563) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e1510) * _e1484) * 2f) - _e1484) - _e1483);
                    let _e2585 = (dot((_e2579 * inverseSqrt(max(dot(_e2579, _e2579), 0.0000000001f))), _e1525) + 1f);
                    let _e2591 = (_e2572 + 3i);
                    let _e2595 = global_3.member[_e2591][1u];
                    let _e2600 = (((_e2024 * _e1553.z) * ((0.25f * (_e2585 * _e2585)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e2595).y > 0.5f)));
                    let _e2603 = global_3.member[_e2572];
                    let _e2607 = global_3.member[(_e2572 + 1i)];
                    let _e2611 = global_3.member[(_e2572 + 2i)];
                    let _e2614 = global_3.member[_e2591];
                    let _e2616 = unpack2x16float(_e2603.x);
                    let _e2618 = unpack2x16float(_e2603.y);
                    let _e2620 = unpack2x16float(_e2603.z);
                    let _e2622 = unpack2x16float(_e2603.w);
                    let _e2624 = unpack2x16float(_e2607.x);
                    let _e2626 = unpack2x16float(_e2607.y);
                    let _e2628 = unpack2x16float(_e2607.z);
                    let _e2630 = unpack2x16float(_e2607.w);
                    let _e2632 = unpack2x16float(_e2611.x);
                    let _e2634 = unpack2x16float(_e2611.y);
                    let _e2636 = unpack2x16float(_e2611.z);
                    let _e2638 = unpack2x16float(_e2611.w);
                    let _e2640 = unpack2x16float(_e2614.x);
                    let _e2696 = ((((((((((vec3<f32>(_e2616.x, _e2616.y, _e2618.x) * 0.282095f) + (vec3<f32>(_e2618.y, _e2620.x, _e2620.y) * _e1554)) + (vec3<f32>(_e2622.x, _e2622.y, _e2624.x) * _e1555)) + (vec3<f32>(_e2624.y, _e2626.x, _e2626.y) * _e1556)) + (vec3<f32>(_e2628.x, _e2628.y, _e2630.x) * _e1558)) + (vec3<f32>(_e2630.y, _e2632.x, _e2632.y) * _e1560)) + (vec3<f32>(_e2634.x, _e2634.y, _e2636.x) * _e1564)) + (vec3<f32>(_e2636.y, _e2638.x, _e2638.y) * _e1565)) + (vec3<f32>(_e2640.x, _e2640.y, unpack2x16float(_e2614.y).x) * _e1569)) * _e2600);
                    let _e2701 = (((((((vec4<f32>(_e1711.x, _e1711.y, _e1711.z, _e1615) + vec4<f32>(_e1852.x, _e1852.y, _e1852.z, _e1756)) + vec4<f32>(_e1994.x, _e1994.y, _e1994.z, _e1898)) + vec4<f32>(_e2135.x, _e2135.y, _e2135.z, _e2039)) + vec4<f32>(_e2276.x, _e2276.y, _e2276.z, _e2180)) + vec4<f32>(_e2416.x, _e2416.y, _e2416.z, _e2320)) + vec4<f32>(_e2556.x, _e2556.y, _e2556.z, _e2460)) + vec4<f32>(_e2696.x, _e2696.y, _e2696.z, _e2600));
                    phi_22007_ = _e1446;
                    if (_e2701.w > 0.00001f) {
                        phi_22007_ = mix(_e1446, ((max(_e2701.xyz, vec3<f32>(0f, 0f, 0f)) / vec3(_e2701.w)) * _e1515.z), vec3(_e1503));
                    }
                    let _e2713 = phi_22007_;
                    phi_22006_ = _e2713;
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e2715 = phi_22006_;
                    phi_21708_ = _e2715;
                    phi_21707_ = (_e1448 + 1i);
                }
            }
            let _e2718 = local_42;
            phi_21718_ = (_e1367 + ((_e1243 * (_e2718 - _e1439)) * _e1272));
        }
        let _e2724 = phi_21718_;
        let _e2727 = global.member_13[3u];
        phi_21717_ = _e2724;
        if (_e2727 > 0.5f) {
            let _e2730 = global.member_11;
            let _e2735 = global.member_11[3u];
            let _e2737 = global_16;
            let _e2740 = global.member_12;
            let _e2745 = global.member_13;
            let _e2748 = clamp(floor((_e2737.xy * _e2740.xy)), vec2<f32>(0f, 0f), (_e2745.xy - vec2<f32>(1f, 1f)));
            let _e2753 = global.member_12[2u];
            let _e2757 = global.member_12[3u];
            let _e2762 = global.member_13[2u];
            let _e2767 = global.member_13[1u];
            let _e2773 = global.member_13[0u];
            let _e2777 = u32(((((clamp(floor(((log2(max((dot(_e2730.xyz, _e818) + _e2735), 0.000001f)) * _e2753) + _e2757)), 0f, (_e2762 - 1f)) * _e2767) + _e2748.y) * _e2773) + _e2748.x));
            let _e2784 = global_17.member[(_e2777 >> bitcast<u32>(2i))][(_e2777 & 3u)];
            let _e2785 = (_e2784 & 65535u);
            phi_21719_ = _e2724;
            phi_21715_ = _e2785;
            loop {
                let _e2789 = phi_21719_;
                let _e2791 = phi_21715_;
                local_61 = _e2789;
                if (_e2791 < (_e2785 + (_e2784 >> bitcast<u32>(16i)))) {
                    let _e2794 = (_e2791 / 3u);
                    let _e2801 = global_18.member[(_e2794 >> bitcast<u32>(2i))][(_e2794 & 3u)];
                    let _e2807 = ((_e2801 >> bitcast<u32>(((_e2791 - (_e2794 * 3u)) * 10u))) & 1023u);
                    let _e2810 = global_12.member[_e2807];
                    let _e2812 = (_e2810.xyz - _e818);
                    let _e2813 = dot(_e2812, _e2812);
                    let _e2815 = (_e2813 * _e2810.w);
                    let _e2818 = clamp((1f - (_e2815 * _e2815)), 0f, 1f);
                    let _e2821 = (_e2812 * inverseSqrt(max(_e2813, 0.00000001f)));
                    let _e2824 = global_14.member[_e2807];
                    let _e2827 = global_15.member[_e2807];
                    let _e2835 = clamp(((dot(-(_e2821), _e2827.xyz) * _e2824.w) + _e2827.w), 0f, 1f);
                    let _e2842 = (_e2824.xyz * ((((_e2818 * _e2818) * _e2835) * _e2835) / max(_e2813, 0.0001f)));
                    phi_21934_ = _e2842;
                    if _e828 {
                        switch bitcast<i32>(0u) {
                            default: {
                                let _e2846 = global.member_21[2u];
                                let _e2847 = u32(_e2846);
                                if (_e2807 < _e2847) {
                                    let _e2851 = global.member_26[_e2807];
                                    let _e2854 = global.member_15[_e2807];
                                    let _e2863 = (_e2851.z * max((_e2854 * vec4<f32>(_e818.x, _e818.y, _e818.z, 1f)).w, 0f));
                                    let _e2866 = global.member_25[0u];
                                    let _e2872 = global.member_25[1u];
                                    let _e2875 = ((_e818 + (_e825 * (_e2863 * _e2866))) + (_e2821 * (_e2863 * _e2872)));
                                    let _e2880 = (_e2854 * vec4<f32>(_e2875.x, _e2875.y, _e2875.z, 1f));
                                    if (_e2880.w <= 0f) {
                                        phi_21883_ = 1f;
                                        break;
                                    }
                                    let _e2885 = (_e2880.xyz / vec3(_e2880.w));
                                    let _e2887 = (_e2885.x < 0f);
                                    phi_9383_ = _e2887;
                                    if !(_e2887) {
                                        phi_9383_ = (_e2885.x > 1f);
                                    }
                                    let _e2891 = phi_9383_;
                                    phi_9390_ = _e2891;
                                    if !(_e2891) {
                                        phi_9390_ = (_e2885.y < 0f);
                                    }
                                    let _e2896 = phi_9390_;
                                    phi_9397_ = _e2896;
                                    if !(_e2896) {
                                        phi_9397_ = (_e2885.y > 1f);
                                    }
                                    let _e2901 = phi_9397_;
                                    phi_9404_ = _e2901;
                                    if !(_e2901) {
                                        phi_9404_ = (_e2885.z > 1f);
                                    }
                                    let _e2906 = phi_9404_;
                                    if _e2906 {
                                        phi_21883_ = 1f;
                                        break;
                                    }
                                    let _e2909 = _e2851.xy;
                                    let _e2911 = global.member_23;
                                    let _e2912 = _e2911.zw;
                                    let _e2914 = global.member_22;
                                    let _e2915 = _e2914.xy;
                                    let _e2916 = (_e2915 * 0.5f);
                                    let _e2918 = (_e2909 + (_e2885.xy * _e2912));
                                    let _e2919 = (_e2909 + _e2916);
                                    let _e2921 = ((_e2909 + _e2912) - _e2916);
                                    let _e2926 = vec4<f32>(_e2919.x, _e2919.y, _e2921.x, _e2921.y);
                                    switch bitcast<i32>(0u) {
                                        default: {
                                            let _e2930 = global.member_22[2u];
                                            let _e2931 = i32(_e2930);
                                            if (_e2931 <= 0i) {
                                                let _e2935 = clamp(_e2918, _e2926.xy, _e2926.zw);
                                                let _e2940 = textureSampleCompare(global_2, global_1, vec3<f32>(_e2935.x, _e2935.y, _e2885.z).xy, _e2885.z);
                                                phi_21882_ = _e2940;
                                                break;
                                            }
                                            let _e2942 = ((_e2918 / _e2915) + vec2<f32>(0.5f, 0.5f));
                                            let _e2943 = floor(_e2942);
                                            let _e2944 = (_e2942 - _e2943);
                                            let _e2946 = (_e2931 == 1i);
                                            if _e2946 {
                                                let _e2947 = (_e2944 * 2f);
                                                local_16[0i] = (vec2<f32>(3f, 3f) - _e2947);
                                                local_16[1i] = (vec2<f32>(1f, 1f) + _e2947);
                                                let _e2953 = local_16[0i];
                                                local_17[0i] = (((vec2<f32>(2f, 2f) - _e2944) / _e2953) - vec2<f32>(1f, 1f));
                                                let _e2957 = local_16[1i];
                                                local_17[1i] = ((_e2944 / _e2957) + vec2<f32>(1f, 1f));
                                            } else {
                                                let _e2961 = (_e2944 * 3f);
                                                local_16[0i] = (vec2<f32>(4f, 4f) - _e2961);
                                                local_16[1i] = vec2<f32>(7f, 7f);
                                                local_16[2i] = (vec2<f32>(1f, 1f) + _e2961);
                                                let _e2969 = local_16[0i];
                                                local_17[0i] = (((vec2<f32>(3f, 3f) - (_e2944 * 2f)) / _e2969) - vec2<f32>(2f, 2f));
                                                let _e2974 = local_16[1i];
                                                local_17[1i] = ((vec2<f32>(3f, 3f) + _e2944) / _e2974);
                                                let _e2977 = local_16[2i];
                                                local_17[2i] = ((_e2944 / _e2977) + vec2<f32>(2f, 2f));
                                            }
                                            let _e2982 = select(3i, 2i, _e2946);
                                            phi_21875_ = 0f;
                                            phi_21872_ = 0i;
                                            loop {
                                                let _e2984 = phi_21875_;
                                                let _e2986 = phi_21872_;
                                                local_43 = _e2984;
                                                if (_e2986 < _e2982) {
                                                    phi_21881_ = _e2984;
                                                    phi_21878_ = 0i;
                                                    loop {
                                                        let _e2989 = phi_21881_;
                                                        let _e2991 = phi_21878_;
                                                        local_59 = _e2989;
                                                        if (_e2991 < _e2982) {
                                                            continue;
                                                        } else {
                                                            break;
                                                        }
                                                        continuing {
                                                            let _e2995 = local_17[_e2991][0u];
                                                            let _e2998 = local_17[_e2986][1u];
                                                            let _e3004 = clamp((_e2915 * ((_e2943 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e2995, _e2998))), _e2926.xy, _e2926.zw);
                                                            let _e3007 = local_16[_e2991][0u];
                                                            let _e3010 = local_16[_e2986][1u];
                                                            let _e3016 = textureSampleCompare(global_2, global_1, vec3<f32>(_e3004.x, _e3004.y, _e2885.z).xy, _e2885.z);
                                                            phi_21881_ = (_e2989 + ((_e3007 * _e3010) * _e3016));
                                                            phi_21878_ = (_e2991 + 1i);
                                                        }
                                                    }
                                                    continue;
                                                } else {
                                                    break;
                                                }
                                                continuing {
                                                    let _e7839 = local_59;
                                                    phi_21875_ = _e7839;
                                                    phi_21872_ = (_e2986 + 1i);
                                                }
                                            }
                                            let _e3022 = local_43;
                                            phi_21882_ = (_e3022 * select(0.0069444445f, 0.0625f, _e2946));
                                            break;
                                        }
                                    }
                                    let _e3025 = phi_21882_;
                                    phi_21883_ = _e3025;
                                    break;
                                }
                                let _e3026 = (_e2807 - _e2847);
                                let _e3029 = global.member_21[3u];
                                if (_e3026 >= u32(_e3029)) {
                                    phi_21883_ = 1f;
                                    break;
                                }
                                let _e3034 = global.member_27[_e3026];
                                let _e3037 = global.member_28[_e3026];
                                let _e3039 = _e3034.xyz;
                                let _e3042 = (_e3034.w * length((_e818 - _e3039)));
                                let _e3045 = global.member_25[0u];
                                let _e3051 = global.member_25[1u];
                                let _e3055 = (((_e818 + (_e825 * (_e3042 * _e3045))) + (_e2821 * (_e3042 * _e3051))) - _e3039);
                                let _e3056 = abs(_e3055);
                                let _e3059 = (_e3056.x >= _e3056.y);
                                phi_9474_ = _e3059;
                                if _e3059 {
                                    phi_9474_ = (_e3056.x >= _e3056.z);
                                }
                                let _e3063 = phi_9474_;
                                if _e3063 {
                                    phi_21859_ = select(1i, 0i, (_e3055.x > 0f));
                                    phi_21857_ = _e3056.x;
                                } else {
                                    let _e3068 = (_e3056.y >= _e3056.z);
                                    if _e3068 {
                                        phi_21860_ = select(3i, 2i, (_e3055.y > 0f));
                                    } else {
                                        phi_21860_ = select(5i, 4i, (_e3055.z > 0f));
                                    }
                                    let _e3076 = phi_21860_;
                                    phi_21859_ = _e3076;
                                    phi_21857_ = select(_e3056.z, _e3056.y, _e3068);
                                }
                                let _e3079 = phi_21859_;
                                let _e3081 = phi_21857_;
                                if (_e3081 <= 0f) {
                                    phi_21883_ = 1f;
                                    break;
                                }
                                local_18 = array<vec3<f32>, 6>(vec3<f32>(0f, 0f, 1f), vec3<f32>(0f, 0f, -1f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(1f, 0f, 0f));
                                let _e3084 = local_18[_e3079];
                                local_19 = array<vec3<f32>, 6>(vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 0f, -1f), vec3<f32>(0f, 0f, 1f), vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 1f, 0f));
                                let _e3087 = local_19[_e3079];
                                let _e3092 = global.member_24[2u];
                                let _e3095 = (vec2<f32>(dot(_e3055, _e3084), dot(_e3055, _e3087)) / vec2((_e3081 * _e3092)));
                                let _e3099 = (_e3037.z + (_e3037.w / _e3081));
                                if (_e3099 > 1f) {
                                    phi_21883_ = 1f;
                                    break;
                                }
                                let _e3114 = global.member_24;
                                let _e3115 = _e3114.xy;
                                let _e3117 = (_e3037.xy + (vec2<f32>(f32((_e3079 - (i32(floor((f32(_e3079) / f32(3i)))) * 3i))), f32((_e3079 / 3i))) * _e3115));
                                let _e3126 = global.member_22;
                                let _e3127 = _e3126.xy;
                                let _e3128 = (_e3127 * 0.5f);
                                let _e3130 = (_e3117 + (vec2<f32>((0.5f + (0.5f * _e3095.x)), (0.5f - (0.5f * _e3095.y))) * _e3115));
                                let _e3131 = (_e3117 + _e3128);
                                let _e3133 = ((_e3117 + _e3115) - _e3128);
                                let _e3138 = vec4<f32>(_e3131.x, _e3131.y, _e3133.x, _e3133.y);
                                switch bitcast<i32>(0u) {
                                    default: {
                                        let _e3142 = global.member_22[2u];
                                        let _e3143 = i32(_e3142);
                                        if (_e3143 <= 0i) {
                                            let _e3147 = clamp(_e3130, _e3138.xy, _e3138.zw);
                                            let _e3152 = textureSampleCompare(global_2, global_1, vec3<f32>(_e3147.x, _e3147.y, _e3099).xy, _e3099);
                                            phi_21871_ = _e3152;
                                            break;
                                        }
                                        let _e3154 = ((_e3130 / _e3127) + vec2<f32>(0.5f, 0.5f));
                                        let _e3155 = floor(_e3154);
                                        let _e3156 = (_e3154 - _e3155);
                                        let _e3158 = (_e3143 == 1i);
                                        if _e3158 {
                                            let _e3159 = (_e3156 * 2f);
                                            local_14[0i] = (vec2<f32>(3f, 3f) - _e3159);
                                            local_14[1i] = (vec2<f32>(1f, 1f) + _e3159);
                                            let _e3165 = local_14[0i];
                                            local_15[0i] = (((vec2<f32>(2f, 2f) - _e3156) / _e3165) - vec2<f32>(1f, 1f));
                                            let _e3169 = local_14[1i];
                                            local_15[1i] = ((_e3156 / _e3169) + vec2<f32>(1f, 1f));
                                        } else {
                                            let _e3173 = (_e3156 * 3f);
                                            local_14[0i] = (vec2<f32>(4f, 4f) - _e3173);
                                            local_14[1i] = vec2<f32>(7f, 7f);
                                            local_14[2i] = (vec2<f32>(1f, 1f) + _e3173);
                                            let _e3181 = local_14[0i];
                                            local_15[0i] = (((vec2<f32>(3f, 3f) - (_e3156 * 2f)) / _e3181) - vec2<f32>(2f, 2f));
                                            let _e3186 = local_14[1i];
                                            local_15[1i] = ((vec2<f32>(3f, 3f) + _e3156) / _e3186);
                                            let _e3189 = local_14[2i];
                                            local_15[2i] = ((_e3156 / _e3189) + vec2<f32>(2f, 2f));
                                        }
                                        let _e3194 = select(3i, 2i, _e3158);
                                        phi_21864_ = 0f;
                                        phi_21861_ = 0i;
                                        loop {
                                            let _e3196 = phi_21864_;
                                            let _e3198 = phi_21861_;
                                            local_44 = _e3196;
                                            if (_e3198 < _e3194) {
                                                phi_21870_ = _e3196;
                                                phi_21867_ = 0i;
                                                loop {
                                                    let _e3201 = phi_21870_;
                                                    let _e3203 = phi_21867_;
                                                    local_60 = _e3201;
                                                    if (_e3203 < _e3194) {
                                                        continue;
                                                    } else {
                                                        break;
                                                    }
                                                    continuing {
                                                        let _e3207 = local_15[_e3203][0u];
                                                        let _e3210 = local_15[_e3198][1u];
                                                        let _e3216 = clamp((_e3127 * ((_e3155 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e3207, _e3210))), _e3138.xy, _e3138.zw);
                                                        let _e3219 = local_14[_e3203][0u];
                                                        let _e3222 = local_14[_e3198][1u];
                                                        let _e3228 = textureSampleCompare(global_2, global_1, vec3<f32>(_e3216.x, _e3216.y, _e3099).xy, _e3099);
                                                        phi_21870_ = (_e3201 + ((_e3219 * _e3222) * _e3228));
                                                        phi_21867_ = (_e3203 + 1i);
                                                    }
                                                }
                                                continue;
                                            } else {
                                                break;
                                            }
                                            continuing {
                                                let _e7851 = local_60;
                                                phi_21864_ = _e7851;
                                                phi_21861_ = (_e3198 + 1i);
                                            }
                                        }
                                        let _e3234 = local_44;
                                        phi_21871_ = (_e3234 * select(0.0069444445f, 0.0625f, _e3158));
                                        break;
                                    }
                                }
                                let _e3237 = phi_21871_;
                                phi_21883_ = _e3237;
                                break;
                            }
                        }
                        let _e3239 = phi_21883_;
                        phi_21934_ = (_e2842 * _e3239);
                    }
                    let _e3242 = phi_21934_;
                    let _e3243 = dot(_e810, _e2821);
                    local_58 = (_e2789 + (((_e1243 * max(_e3243, 0f)) * _e3242) + (_e3242 * ((pow(max(dot(_e810, normalize((_e2821 + _e820))), 0f), _e1281) * _e1285) * step(0f, _e3243)))));
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e7831 = local_58;
                    phi_21719_ = _e7831;
                    phi_21715_ = (_e2791 + bitcast<u32>(1i));
                }
            }
            let _e7861 = local_61;
            phi_21717_ = _e7861;
        }
        let _e3261 = phi_21717_;
        phi_21716_ = _e3261;
    } else {
        let _e3262 = textureSample(global_27, global_5, _e283);
        let _e3265 = global_8.member_4[0u];
        let _e3269 = global_28[1u];
        let _e3271 = clamp(((_e3265 * _e3262.z) * _e3269), 0f, 1f);
        let _e3274 = global_8.member_4[1u];
        let _e3278 = global_28[0u];
        let _e3280 = clamp(((_e3274 * _e3262.y) * _e3278), 0.045f, 1f);
        phi_21034_ = _e3271;
        phi_21029_ = _e3280;
        if (_e727 > 0f) {
            phi_21034_ = mix(_e3271, _e725.y, _e727);
            phi_21029_ = mix(_e3280, max(_e725.x, 0.045f), _e727);
        }
        let _e3288 = phi_21034_;
        let _e3290 = phi_21029_;
        let _e3291 = (_e3290 * _e3290);
        let _e3293 = (_e1243 * (1f - _e3288));
        let _e3295 = mix(vec3<f32>(0.04f, 0.04f, 0.04f), _e1243, vec3(_e3288));
        let _e3296 = (_e801 > 0f);
        phi_21062_ = _e810;
        if _e3296 {
            let _e3297 = dpdx(_e818);
            let _e3298 = dpdy(_e818);
            let _e3299 = cross(_e3297, _e3298);
            phi_21063_ = _e810;
            if (dot(_e3299, _e3299) > 0.00000000000000000001f) {
                phi_21063_ = normalize(((normalize(_e3299) * select(1f, -1f, (dot(_e3299, _e820) < 0f))) + (_e810 - _e731)));
            }
            let _e3311 = phi_21063_;
            phi_21062_ = _e3311;
        }
        let _e3313 = phi_21062_;
        let _e3315 = max(dot(_e3313, _e820), 0.0001f);
        let _e3318 = dot(_e3313, _e814);
        let _e3319 = clamp(_e3318, 0f, 1f);
        let _e3321 = clamp(dot(_e3313, _e822), 0f, 1f);
        let _e3323 = clamp(dot(_e820, _e822), 0f, 1f);
        phi_21067_ = _e3315;
        phi_21066_ = _e3323;
        if _e3296 {
            phi_21067_ = max(_e3315, 0.5f);
            phi_21066_ = max(_e3323, 0.5f);
        }
        let _e3327 = phi_21067_;
        let _e3329 = phi_21066_;
        let _e3332 = (vec3<f32>(1f, 1f, 1f) - _e3295);
        let _e3334 = (_e3295 + (_e3332 * pow((1f - _e3329), 5f)));
        let _e3335 = (_e3291 * _e3291);
        let _e3337 = (_e3335 - 1f);
        let _e3339 = (((_e3321 * _e3321) * _e3337) + 1f);
        let _e3344 = (1f - _e3335);
        let _e3347 = sqrt((((_e3327 * _e3327) * _e3344) + _e3335));
        let _e3366 = ((((((vec3<f32>(1f, 1f, 1f) - _e3334) * _e3293) * clamp(dot(_e810, _e814), 0f, 1f)) + (((_e3334 * ((_e3335 / ((3.1415927f * _e3339) * _e3339)) * (0.5f / max(((_e3319 * _e3347) + (_e3327 * sqrt((((_e3319 * _e3319) * _e3344) + _e3335)))), 0.00001f)))) * 3.1415927f) * _e3319)) * _e1250) * _e1241);
        phi_21177_ = _e3366;
        if _e3296 {
            phi_21177_ = (_e3366 + (((((_e3293 * _e1250) * _e1241) * _e801) * clamp(-(_e3318), 0f, 1f)) * (0.35f + (0.65f * pow(clamp(dot(-(_e820), _e814), 0f, 1f), 3f)))));
        }
        let _e3382 = phi_21177_;
        let _e3385 = global.member_29[0u];
        let _e3386 = (_e3385 > 0.5f);
        if _e3386 {
            let _e3391 = textureSample(global_6, global_7, (((vec2<f32>(_e3327, _e3290) * 31f) + vec2<f32>(0.5f, 0.5f)) * vec2<f32>(0.03125f, 0.03125f)));
            let _e3394 = global.member_29;
            let _e3401 = ((_e3394.z * _e810.x) - (_e3394.w * _e810.z));
            let _e3405 = ((_e3394.w * _e810.x) + (_e3394.z * _e810.z));
            let _e3409 = (1.092548f * _e3401);
            local_13 = array<f32, 9>(0.282095f, (0.488603f * _e810.y), (0.488603f * _e3405), (0.488603f * _e3401), (_e3409 * _e810.y), ((1.092548f * _e810.y) * _e3405), (0.315392f * (((3f * _e3405) * _e3405) - 1f)), (_e3409 * _e3405), (0.546274f * ((_e3401 * _e3401) - (_e810.y * _e810.y))));
            phi_21085_ = vec3<f32>(0f, 0f, 0f);
            phi_21084_ = 0i;
            loop {
                let _e3424 = phi_21085_;
                let _e3426 = phi_21084_;
                local_45 = _e3424;
                if (_e3426 < 9i) {
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e3430 = textureLoad(global_4, (vec2<i32>(496i, 256i) + vec2<i32>(_e3426, 0i)), 0i);
                    let _e3433 = local_13[_e3426];
                    phi_21085_ = (_e3424 + (_e3430.xyz * _e3433));
                    phi_21084_ = (_e3426 + 1i);
                }
            }
            let _e3438 = local_45;
            let _e3442 = global.member_29[1u];
            let _e3445 = reflect(-(_e820), _e3313);
            let _e3462 = vec2<f32>(((atan2(((_e3394.z * _e3445.x) - (_e3394.w * _e3445.z)), -(((_e3394.w * _e3445.x) + (_e3394.z * _e3445.z)))) * 0.15915494f) + 0.5f), (acos(clamp(_e3445.y, -1f, 1f)) * 0.31830987f));
            let _e3463 = (_e3290 * 5f);
            let _e3465 = min(i32(_e3463), 4i);
            local_11 = array<vec4<i32>, 6>(vec4<i32>(0i, 0i, 512i, 256i), vec4<i32>(0i, 256i, 256i, 128i), vec4<i32>(256i, 256i, 128i, 64i), vec4<i32>(384i, 256i, 64i, 32i), vec4<i32>(448i, 256i, 32i, 16i), vec4<i32>(480i, 256i, 16i, 8i));
            let _e3467 = local_11[_e3465];
            let _e3471 = ((_e3462 * vec2<f32>(_e3467.zw)) - vec2<f32>(0.5f, 0.5f));
            let _e3472 = floor(_e3471);
            let _e3473 = (_e3471 - _e3472);
            let _e3475 = i32(_e3472.x);
            let _e3477 = i32(_e3472.y);
            phi_21088_ = _e3475;
            if (_e3475 < 0i) {
                phi_21088_ = (_e3475 + _e3467.z);
            }
            let _e3482 = phi_21088_;
            phi_21089_ = _e3482;
            if (_e3482 >= _e3467.z) {
                phi_21089_ = (_e3482 - _e3467.z);
            }
            let _e3487 = phi_21089_;
            let _e3488 = (_e3487 + 1i);
            let _e3490 = select(_e3488, 0i, (_e3488 == _e3467.z));
            let _e3494 = min((_e3477 + 1i), (_e3467.w - 1i));
            let _e3495 = max(_e3477, 0i);
            let _e3496 = _e3467.xy;
            let _e3499 = textureLoad(global_4, (_e3496 + vec2<i32>(_e3487, _e3495)), 0i);
            let _e3503 = textureLoad(global_4, (_e3496 + vec2<i32>(_e3490, _e3495)), 0i);
            let _e3507 = textureLoad(global_4, (_e3496 + vec2<i32>(_e3487, _e3494)), 0i);
            let _e3511 = textureLoad(global_4, (_e3496 + vec2<i32>(_e3490, _e3494)), 0i);
            let _e3514 = vec3(_e3473.x);
            local_12 = array<vec4<i32>, 6>(vec4<i32>(0i, 0i, 512i, 256i), vec4<i32>(0i, 256i, 256i, 128i), vec4<i32>(256i, 256i, 128i, 64i), vec4<i32>(384i, 256i, 64i, 32i), vec4<i32>(448i, 256i, 32i, 16i), vec4<i32>(480i, 256i, 16i, 8i));
            let _e3522 = local_12[(_e3465 + 1i)];
            let _e3526 = ((_e3462 * vec2<f32>(_e3522.zw)) - vec2<f32>(0.5f, 0.5f));
            let _e3527 = floor(_e3526);
            let _e3528 = (_e3526 - _e3527);
            let _e3530 = i32(_e3527.x);
            let _e3532 = i32(_e3527.y);
            phi_21095_ = _e3530;
            if (_e3530 < 0i) {
                phi_21095_ = (_e3530 + _e3522.z);
            }
            let _e3537 = phi_21095_;
            phi_21096_ = _e3537;
            if (_e3537 >= _e3522.z) {
                phi_21096_ = (_e3537 - _e3522.z);
            }
            let _e3542 = phi_21096_;
            let _e3543 = (_e3542 + 1i);
            let _e3545 = select(_e3543, 0i, (_e3543 == _e3522.z));
            let _e3549 = min((_e3532 + 1i), (_e3522.w - 1i));
            let _e3550 = max(_e3532, 0i);
            let _e3551 = _e3522.xy;
            let _e3554 = textureLoad(global_4, (_e3551 + vec2<i32>(_e3542, _e3550)), 0i);
            let _e3558 = textureLoad(global_4, (_e3551 + vec2<i32>(_e3545, _e3550)), 0i);
            let _e3562 = textureLoad(global_4, (_e3551 + vec2<i32>(_e3542, _e3549)), 0i);
            let _e3566 = textureLoad(global_4, (_e3551 + vec2<i32>(_e3545, _e3549)), 0i);
            let _e3569 = vec3(_e3528.x);
            phi_21139_ = (max(_e3438, vec3<f32>(0f, 0f, 0f)) * _e3442);
            phi_21127_ = _e3391.xy;
            phi_21103_ = (mix(mix(mix(_e3499.xyz, _e3503.xyz, _e3514), mix(_e3507.xyz, _e3511.xyz, _e3514), vec3(_e3473.y)), mix(mix(_e3554.xyz, _e3558.xyz, _e3569), mix(_e3562.xyz, _e3566.xyz, _e3569), vec3(_e3528.y)), vec3((_e3463 - f32(_e3465)))) * _e3442);
        } else {
            let _e3581 = ((vec4<f32>(-1f, -0.0275f, -0.572f, 0.022f) * _e3290) + vec4<f32>(1f, 0.0425f, 1.04f, -0.04f));
            let _e3594 = global.member_9;
            let _e3595 = _e3594.xyz;
            let _e3597 = global.member_8;
            let _e3598 = _e3597.xyz;
            let _e3606 = global.member_8[3u];
            let _e3607 = (mix(_e3595, _e3598, vec3(((_e810.y * 0.5f) + 0.5f))) * _e3606);
            phi_21139_ = _e3607;
            phi_21127_ = ((vec2<f32>(-1.04f, 1.04f) * ((min((_e3581.x * _e3581.x), exp2((-9.28f * _e3327))) * _e3581.x) + _e3581.y)) + _e3581.zw);
            phi_21103_ = mix((mix(_e3595, _e3598, vec3(((reflect(-(_e820), _e3313).y * 0.5f) + 0.5f))) * _e3606), _e3607, vec3(_e3290));
        }
        let _e3619 = phi_21139_;
        let _e3621 = phi_21127_;
        let _e3623 = phi_21103_;
        phi_4152_ = _e1254;
        if _e1254 {
            let _e3626 = global.member_33[2u];
            phi_4152_ = (_e3626 > 0.5f);
        }
        let _e3629 = phi_4152_;
        phi_21148_ = _e3623;
        if _e3629 {
            switch bitcast<i32>(0u) {
                default: {
                    let _e3632 = global.member_31;
                    let _e3633 = _e3632.xyz;
                    let _e3636 = global.member_33[0u];
                    let _e3641 = global.member_31[3u];
                    let _e3650 = global.member_32[1u];
                    let _e3656 = global.member_32[0u];
                    let _e3659 = (((_e3656 * (1f - smoothstep((_e3636 * 0.5f), _e3636, abs((dot(_e3633, _e818) - _e3641))))) * smoothstep(0.5f, 0.9f, dot(_e825, _e3633))) * (1f - smoothstep((_e3650 * 0.5f), _e3650, _e3290)));
                    if (_e3659 <= 0f) {
                        phi_21124_ = _e3623;
                        break;
                    }
                    let _e3666 = global.member_32[3u];
                    let _e3668 = (_e818 + ((_e810 - (_e3633 * dot(_e810, _e3633))) * _e3666));
                    let _e3670 = global.member_30;
                    let _e3675 = (_e3670 * vec4<f32>(_e3668.x, _e3668.y, _e3668.z, 1f));
                    let _e3687 = global.member_32[2u];
                    phi_21123_ = 0f;
                    phi_21122_ = vec3<f32>(0f, 0f, 0f);
                    phi_21121_ = 0i;
                    loop {
                        let _e3690 = phi_21123_;
                        let _e3692 = phi_21122_;
                        let _e3694 = phi_21121_;
                        local_46 = _e3692;
                        local_47 = _e3690;
                        if (_e3694 < 12i) {
                            continue;
                        } else {
                            break;
                        }
                        continuing {
                            let _e3696 = f32(_e3694);
                            let _e3701 = (_e3696 * 2.3999631f);
                            let _e3705 = global.member_33[1u];
                            let _e3710 = ((((vec2<f32>(_e3675.x, -(_e3675.y)) / vec2(_e3675.w)) * 0.5f) + vec2<f32>(0.5f, 0.5f)) + (vec2<f32>((cos(_e3701) * _e3705), sin(_e3701)) * (sqrt(((_e3696 + 0.5f) * 0.083333336f)) * (_e3687 * _e3290))));
                            let _e3712 = min(_e3710, (vec2<f32>(1f, 1f) - _e3710));
                            let _e3716 = smoothstep(0f, 0.04f, min(_e3712.x, _e3712.y));
                            let _e3718 = textureSampleLevel(global_19, global_5, clamp(_e3710, vec2<f32>(0f, 0f), vec2<f32>(1f, 1f)), 0f);
                            let _e3719 = _e3718.xyz;
                            phi_21123_ = (_e3690 + (_e3718.w * _e3716));
                            phi_21122_ = (_e3692 + ((_e3719 / (vec3<f32>(1f, 1f, 1f) - min(_e3719, vec3<f32>(0.995f, 0.995f, 0.995f)))) * _e3716));
                            phi_21121_ = (_e3694 + 1i);
                        }
                    }
                    let _e3730 = local_46;
                    let _e3733 = local_47;
                    phi_21124_ = mix(_e3623, ((_e3730 * vec3<f32>(0.083333336f, 0.083333336f, 0.083333336f)) + (_e3623 * (1f - (_e3733 * 0.083333336f)))), vec3(_e3659));
                    break;
                }
            }
            let _e3741 = phi_21124_;
            phi_21148_ = _e3741;
        }
        let _e3743 = phi_21148_;
        let _e3748 = ((_e3295 * _e3621.x) + vec3(_e3621.y));
        let _e3750 = ((vec3<f32>(1f, 1f, 1f) - _e3748) * _e3293);
        let _e3755 = (_e3382 + (((_e3750 * _e3619) + (_e3748 * _e3743)) * _e1272));
        let _e3758 = global.member_34[0u];
        let _e3761 = global.member_34[1u];
        phi_21650_ = _e3755;
        if ((_e3758 + _e3761) > 0.5f) {
            if (_e3761 > 0.5f) {
                phi_21184_ = _e3619;
                phi_21183_ = 0i;
                loop {
                    let _e3768 = phi_21184_;
                    let _e3770 = phi_21183_;
                    local_62 = _e3768;
                    if (_e3770 < i32(_e3761)) {
                        let _e3773 = (8i * (i32(_e3758) + _e3770));
                        let _e3777 = global_3.member[(_e3773 + 3i)];
                        let _e3778 = bitcast<vec4<f32>>(_e3777);
                        let _e3781 = global_3.member[_e3773];
                        let _e3782 = bitcast<vec4<f32>>(_e3781);
                        let _e3786 = global_3.member[(_e3773 + 1i)];
                        let _e3787 = bitcast<vec4<f32>>(_e3786);
                        let _e3791 = global_3.member[(_e3773 + 2i)];
                        let _e3792 = bitcast<vec4<f32>>(_e3791);
                        let _e3793 = _e3782.xyz;
                        let _e3797 = _e3787.xyz;
                        let _e3801 = _e3792.xyz;
                        let _e3805 = vec3<f32>((dot(_e3793, _e818) + _e3782.w), (dot(_e3797, _e818) + _e3787.w), (dot(_e3801, _e818) + _e3792.w));
                        let _e3806 = _e3778.xyz;
                        switch bitcast<i32>(0u) {
                            default: {
                                let _e3810 = (_e3806 - abs(_e3805));
                                let _e3815 = min(_e3810.x, min(_e3810.y, _e3810.z));
                                if (_e3815 <= 0f) {
                                    phi_21684_ = 0f;
                                    break;
                                }
                                if (_e3778.w <= 0f) {
                                    phi_21684_ = 1f;
                                    break;
                                }
                                let _e3819 = min((_e3815 / _e3778.w), 1f);
                                phi_21684_ = ((_e3819 * _e3819) * (3f - (2f * _e3819)));
                                break;
                            }
                        }
                        let _e3825 = phi_21684_;
                        if (_e3825 <= 0f) {
                            phi_21976_ = _e3768;
                            continue;
                        }
                        let _e3830 = global_3.member[(_e3773 + 4i)];
                        let _e3832 = bitcast<vec4<f32>>(_e3830).xyz;
                        let _e3836 = global_3.member[(_e3773 + 5i)];
                        let _e3837 = bitcast<vec4<f32>>(_e3836);
                        let _e3842 = global_3.member[(_e3773 + 6i)][0u];
                        let _e3843 = bitcast<i32>(_e3842);
                        let _e3844 = dot(_e3793, _e810);
                        let _e3845 = dot(_e3797, _e810);
                        let _e3846 = dot(_e3801, _e810);
                        let _e3847 = vec3<f32>(_e3844, _e3845, _e3846);
                        let _e3853 = ((_e818 + (_e810 * _e3837.x)) + (_e820 * _e3837.y));
                        let _e3868 = clamp(((((vec3<f32>((dot(_e3793, _e3853) + _e3782.w), (dot(_e3797, _e3853) + _e3787.w), (dot(_e3801, _e3853) + _e3792.w)) + _e3806) / max((_e3806 * 2f), vec3<f32>(0.000001f, 0.000001f, 0.000001f))) * _e3832) - vec3<f32>(0.5f, 0.5f, 0.5f)), vec3<f32>(0f, 0f, 0f), (_e3832 - vec3<f32>(1f, 1f, 1f)));
                        let _e3869 = vec3<i32>(_e3832);
                        let _e3873 = min(vec3<i32>(_e3868), max((_e3869 - vec3<i32>(2i, 2i, 2i)), vec3<i32>(0i, 0i, 0i)));
                        let _e3875 = (_e3868 - vec3<f32>(_e3873));
                        let _e3876 = (0.488603f * _e3845);
                        let _e3877 = (0.488603f * _e3846);
                        let _e3878 = (0.488603f * _e3844);
                        let _e3879 = (1.092548f * _e3844);
                        let _e3880 = (_e3879 * _e3845);
                        let _e3882 = ((1.092548f * _e3845) * _e3846);
                        let _e3886 = (0.315392f * (((3f * _e3846) * _e3846) - 1f));
                        let _e3887 = (_e3879 * _e3846);
                        let _e3891 = (0.546274f * ((_e3844 * _e3844) - (_e3845 * _e3845)));
                        let _e3892 = (_e3869 - vec3<i32>(1i, 1i, 1i));
                        let _e3893 = min(_e3873, _e3892);
                        let _e3904 = (_e3843 + ((_e3893.x + (_e3869.x * (_e3893.y + (_e3869.y * _e3893.z)))) * 4i));
                        let _e3905 = (vec3<f32>(1f, 1f, 1f) - _e3875);
                        let _e3912 = ((((((vec3<f32>(_e3893) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e3832) * _e3806) * 2f) - _e3806) - _e3805);
                        let _e3918 = (dot((_e3912 * inverseSqrt(max(dot(_e3912, _e3912), 0.0000000001f))), _e3847) + 1f);
                        let _e3921 = (_e3905.x * _e3905.y);
                        let _e3928 = (_e3904 + 3i);
                        let _e3932 = global_3.member[_e3928][1u];
                        let _e3937 = (((_e3921 * _e3905.z) * ((0.25f * (_e3918 * _e3918)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e3932).y > 0.5f)));
                        let _e3940 = global_3.member[_e3904];
                        let _e3944 = global_3.member[(_e3904 + 1i)];
                        let _e3948 = global_3.member[(_e3904 + 2i)];
                        let _e3951 = global_3.member[_e3928];
                        let _e3953 = unpack2x16float(_e3940.x);
                        let _e3955 = unpack2x16float(_e3940.y);
                        let _e3957 = unpack2x16float(_e3940.z);
                        let _e3959 = unpack2x16float(_e3940.w);
                        let _e3961 = unpack2x16float(_e3944.x);
                        let _e3963 = unpack2x16float(_e3944.y);
                        let _e3965 = unpack2x16float(_e3944.z);
                        let _e3967 = unpack2x16float(_e3944.w);
                        let _e3969 = unpack2x16float(_e3948.x);
                        let _e3971 = unpack2x16float(_e3948.y);
                        let _e3973 = unpack2x16float(_e3948.z);
                        let _e3975 = unpack2x16float(_e3948.w);
                        let _e3977 = unpack2x16float(_e3951.x);
                        let _e4033 = ((((((((((vec3<f32>(_e3953.x, _e3953.y, _e3955.x) * 0.282095f) + (vec3<f32>(_e3955.y, _e3957.x, _e3957.y) * _e3876)) + (vec3<f32>(_e3959.x, _e3959.y, _e3961.x) * _e3877)) + (vec3<f32>(_e3961.y, _e3963.x, _e3963.y) * _e3878)) + (vec3<f32>(_e3965.x, _e3965.y, _e3967.x) * _e3880)) + (vec3<f32>(_e3967.y, _e3969.x, _e3969.y) * _e3882)) + (vec3<f32>(_e3971.x, _e3971.y, _e3973.x) * _e3886)) + (vec3<f32>(_e3973.y, _e3975.x, _e3975.y) * _e3887)) + (vec3<f32>(_e3977.x, _e3977.y, unpack2x16float(_e3951.y).x) * _e3891)) * _e3937);
                        let _e4039 = min((_e3873 + vec3<i32>(1i, 0i, 0i)), _e3892);
                        let _e4048 = (_e3843 + ((_e4039.x + (_e3869.x * (_e4039.y + (_e3869.y * _e4039.z)))) * 4i));
                        let _e4055 = ((((((vec3<f32>(_e4039) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e3832) * _e3806) * 2f) - _e3806) - _e3805);
                        let _e4061 = (dot((_e4055 * inverseSqrt(max(dot(_e4055, _e4055), 0.0000000001f))), _e3847) + 1f);
                        let _e4063 = (_e3875.x * _e3905.y);
                        let _e4069 = (_e4048 + 3i);
                        let _e4073 = global_3.member[_e4069][1u];
                        let _e4078 = (((_e4063 * _e3905.z) * ((0.25f * (_e4061 * _e4061)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e4073).y > 0.5f)));
                        let _e4081 = global_3.member[_e4048];
                        let _e4085 = global_3.member[(_e4048 + 1i)];
                        let _e4089 = global_3.member[(_e4048 + 2i)];
                        let _e4092 = global_3.member[_e4069];
                        let _e4094 = unpack2x16float(_e4081.x);
                        let _e4096 = unpack2x16float(_e4081.y);
                        let _e4098 = unpack2x16float(_e4081.z);
                        let _e4100 = unpack2x16float(_e4081.w);
                        let _e4102 = unpack2x16float(_e4085.x);
                        let _e4104 = unpack2x16float(_e4085.y);
                        let _e4106 = unpack2x16float(_e4085.z);
                        let _e4108 = unpack2x16float(_e4085.w);
                        let _e4110 = unpack2x16float(_e4089.x);
                        let _e4112 = unpack2x16float(_e4089.y);
                        let _e4114 = unpack2x16float(_e4089.z);
                        let _e4116 = unpack2x16float(_e4089.w);
                        let _e4118 = unpack2x16float(_e4092.x);
                        let _e4174 = ((((((((((vec3<f32>(_e4094.x, _e4094.y, _e4096.x) * 0.282095f) + (vec3<f32>(_e4096.y, _e4098.x, _e4098.y) * _e3876)) + (vec3<f32>(_e4100.x, _e4100.y, _e4102.x) * _e3877)) + (vec3<f32>(_e4102.y, _e4104.x, _e4104.y) * _e3878)) + (vec3<f32>(_e4106.x, _e4106.y, _e4108.x) * _e3880)) + (vec3<f32>(_e4108.y, _e4110.x, _e4110.y) * _e3882)) + (vec3<f32>(_e4112.x, _e4112.y, _e4114.x) * _e3886)) + (vec3<f32>(_e4114.y, _e4116.x, _e4116.y) * _e3887)) + (vec3<f32>(_e4118.x, _e4118.y, unpack2x16float(_e4092.y).x) * _e3891)) * _e4078);
                        let _e4181 = min((_e3873 + vec3<i32>(0i, 1i, 0i)), _e3892);
                        let _e4190 = (_e3843 + ((_e4181.x + (_e3869.x * (_e4181.y + (_e3869.y * _e4181.z)))) * 4i));
                        let _e4197 = ((((((vec3<f32>(_e4181) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e3832) * _e3806) * 2f) - _e3806) - _e3805);
                        let _e4203 = (dot((_e4197 * inverseSqrt(max(dot(_e4197, _e4197), 0.0000000001f))), _e3847) + 1f);
                        let _e4205 = (_e3905.x * _e3875.y);
                        let _e4211 = (_e4190 + 3i);
                        let _e4215 = global_3.member[_e4211][1u];
                        let _e4220 = (((_e4205 * _e3905.z) * ((0.25f * (_e4203 * _e4203)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e4215).y > 0.5f)));
                        let _e4223 = global_3.member[_e4190];
                        let _e4227 = global_3.member[(_e4190 + 1i)];
                        let _e4231 = global_3.member[(_e4190 + 2i)];
                        let _e4234 = global_3.member[_e4211];
                        let _e4236 = unpack2x16float(_e4223.x);
                        let _e4238 = unpack2x16float(_e4223.y);
                        let _e4240 = unpack2x16float(_e4223.z);
                        let _e4242 = unpack2x16float(_e4223.w);
                        let _e4244 = unpack2x16float(_e4227.x);
                        let _e4246 = unpack2x16float(_e4227.y);
                        let _e4248 = unpack2x16float(_e4227.z);
                        let _e4250 = unpack2x16float(_e4227.w);
                        let _e4252 = unpack2x16float(_e4231.x);
                        let _e4254 = unpack2x16float(_e4231.y);
                        let _e4256 = unpack2x16float(_e4231.z);
                        let _e4258 = unpack2x16float(_e4231.w);
                        let _e4260 = unpack2x16float(_e4234.x);
                        let _e4316 = ((((((((((vec3<f32>(_e4236.x, _e4236.y, _e4238.x) * 0.282095f) + (vec3<f32>(_e4238.y, _e4240.x, _e4240.y) * _e3876)) + (vec3<f32>(_e4242.x, _e4242.y, _e4244.x) * _e3877)) + (vec3<f32>(_e4244.y, _e4246.x, _e4246.y) * _e3878)) + (vec3<f32>(_e4248.x, _e4248.y, _e4250.x) * _e3880)) + (vec3<f32>(_e4250.y, _e4252.x, _e4252.y) * _e3882)) + (vec3<f32>(_e4254.x, _e4254.y, _e4256.x) * _e3886)) + (vec3<f32>(_e4256.y, _e4258.x, _e4258.y) * _e3887)) + (vec3<f32>(_e4260.x, _e4260.y, unpack2x16float(_e4234.y).x) * _e3891)) * _e4220);
                        let _e4323 = min((_e3873 + vec3<i32>(1i, 1i, 0i)), _e3892);
                        let _e4332 = (_e3843 + ((_e4323.x + (_e3869.x * (_e4323.y + (_e3869.y * _e4323.z)))) * 4i));
                        let _e4339 = ((((((vec3<f32>(_e4323) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e3832) * _e3806) * 2f) - _e3806) - _e3805);
                        let _e4345 = (dot((_e4339 * inverseSqrt(max(dot(_e4339, _e4339), 0.0000000001f))), _e3847) + 1f);
                        let _e4346 = (_e3875.x * _e3875.y);
                        let _e4352 = (_e4332 + 3i);
                        let _e4356 = global_3.member[_e4352][1u];
                        let _e4361 = (((_e4346 * _e3905.z) * ((0.25f * (_e4345 * _e4345)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e4356).y > 0.5f)));
                        let _e4364 = global_3.member[_e4332];
                        let _e4368 = global_3.member[(_e4332 + 1i)];
                        let _e4372 = global_3.member[(_e4332 + 2i)];
                        let _e4375 = global_3.member[_e4352];
                        let _e4377 = unpack2x16float(_e4364.x);
                        let _e4379 = unpack2x16float(_e4364.y);
                        let _e4381 = unpack2x16float(_e4364.z);
                        let _e4383 = unpack2x16float(_e4364.w);
                        let _e4385 = unpack2x16float(_e4368.x);
                        let _e4387 = unpack2x16float(_e4368.y);
                        let _e4389 = unpack2x16float(_e4368.z);
                        let _e4391 = unpack2x16float(_e4368.w);
                        let _e4393 = unpack2x16float(_e4372.x);
                        let _e4395 = unpack2x16float(_e4372.y);
                        let _e4397 = unpack2x16float(_e4372.z);
                        let _e4399 = unpack2x16float(_e4372.w);
                        let _e4401 = unpack2x16float(_e4375.x);
                        let _e4457 = ((((((((((vec3<f32>(_e4377.x, _e4377.y, _e4379.x) * 0.282095f) + (vec3<f32>(_e4379.y, _e4381.x, _e4381.y) * _e3876)) + (vec3<f32>(_e4383.x, _e4383.y, _e4385.x) * _e3877)) + (vec3<f32>(_e4385.y, _e4387.x, _e4387.y) * _e3878)) + (vec3<f32>(_e4389.x, _e4389.y, _e4391.x) * _e3880)) + (vec3<f32>(_e4391.y, _e4393.x, _e4393.y) * _e3882)) + (vec3<f32>(_e4395.x, _e4395.y, _e4397.x) * _e3886)) + (vec3<f32>(_e4397.y, _e4399.x, _e4399.y) * _e3887)) + (vec3<f32>(_e4401.x, _e4401.y, unpack2x16float(_e4375.y).x) * _e3891)) * _e4361);
                        let _e4464 = min((_e3873 + vec3<i32>(0i, 0i, 1i)), _e3892);
                        let _e4473 = (_e3843 + ((_e4464.x + (_e3869.x * (_e4464.y + (_e3869.y * _e4464.z)))) * 4i));
                        let _e4480 = ((((((vec3<f32>(_e4464) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e3832) * _e3806) * 2f) - _e3806) - _e3805);
                        let _e4486 = (dot((_e4480 * inverseSqrt(max(dot(_e4480, _e4480), 0.0000000001f))), _e3847) + 1f);
                        let _e4493 = (_e4473 + 3i);
                        let _e4497 = global_3.member[_e4493][1u];
                        let _e4502 = (((_e3921 * _e3875.z) * ((0.25f * (_e4486 * _e4486)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e4497).y > 0.5f)));
                        let _e4505 = global_3.member[_e4473];
                        let _e4509 = global_3.member[(_e4473 + 1i)];
                        let _e4513 = global_3.member[(_e4473 + 2i)];
                        let _e4516 = global_3.member[_e4493];
                        let _e4518 = unpack2x16float(_e4505.x);
                        let _e4520 = unpack2x16float(_e4505.y);
                        let _e4522 = unpack2x16float(_e4505.z);
                        let _e4524 = unpack2x16float(_e4505.w);
                        let _e4526 = unpack2x16float(_e4509.x);
                        let _e4528 = unpack2x16float(_e4509.y);
                        let _e4530 = unpack2x16float(_e4509.z);
                        let _e4532 = unpack2x16float(_e4509.w);
                        let _e4534 = unpack2x16float(_e4513.x);
                        let _e4536 = unpack2x16float(_e4513.y);
                        let _e4538 = unpack2x16float(_e4513.z);
                        let _e4540 = unpack2x16float(_e4513.w);
                        let _e4542 = unpack2x16float(_e4516.x);
                        let _e4598 = ((((((((((vec3<f32>(_e4518.x, _e4518.y, _e4520.x) * 0.282095f) + (vec3<f32>(_e4520.y, _e4522.x, _e4522.y) * _e3876)) + (vec3<f32>(_e4524.x, _e4524.y, _e4526.x) * _e3877)) + (vec3<f32>(_e4526.y, _e4528.x, _e4528.y) * _e3878)) + (vec3<f32>(_e4530.x, _e4530.y, _e4532.x) * _e3880)) + (vec3<f32>(_e4532.y, _e4534.x, _e4534.y) * _e3882)) + (vec3<f32>(_e4536.x, _e4536.y, _e4538.x) * _e3886)) + (vec3<f32>(_e4538.y, _e4540.x, _e4540.y) * _e3887)) + (vec3<f32>(_e4542.x, _e4542.y, unpack2x16float(_e4516.y).x) * _e3891)) * _e4502);
                        let _e4605 = min((_e3873 + vec3<i32>(1i, 0i, 1i)), _e3892);
                        let _e4614 = (_e3843 + ((_e4605.x + (_e3869.x * (_e4605.y + (_e3869.y * _e4605.z)))) * 4i));
                        let _e4621 = ((((((vec3<f32>(_e4605) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e3832) * _e3806) * 2f) - _e3806) - _e3805);
                        let _e4627 = (dot((_e4621 * inverseSqrt(max(dot(_e4621, _e4621), 0.0000000001f))), _e3847) + 1f);
                        let _e4633 = (_e4614 + 3i);
                        let _e4637 = global_3.member[_e4633][1u];
                        let _e4642 = (((_e4063 * _e3875.z) * ((0.25f * (_e4627 * _e4627)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e4637).y > 0.5f)));
                        let _e4645 = global_3.member[_e4614];
                        let _e4649 = global_3.member[(_e4614 + 1i)];
                        let _e4653 = global_3.member[(_e4614 + 2i)];
                        let _e4656 = global_3.member[_e4633];
                        let _e4658 = unpack2x16float(_e4645.x);
                        let _e4660 = unpack2x16float(_e4645.y);
                        let _e4662 = unpack2x16float(_e4645.z);
                        let _e4664 = unpack2x16float(_e4645.w);
                        let _e4666 = unpack2x16float(_e4649.x);
                        let _e4668 = unpack2x16float(_e4649.y);
                        let _e4670 = unpack2x16float(_e4649.z);
                        let _e4672 = unpack2x16float(_e4649.w);
                        let _e4674 = unpack2x16float(_e4653.x);
                        let _e4676 = unpack2x16float(_e4653.y);
                        let _e4678 = unpack2x16float(_e4653.z);
                        let _e4680 = unpack2x16float(_e4653.w);
                        let _e4682 = unpack2x16float(_e4656.x);
                        let _e4738 = ((((((((((vec3<f32>(_e4658.x, _e4658.y, _e4660.x) * 0.282095f) + (vec3<f32>(_e4660.y, _e4662.x, _e4662.y) * _e3876)) + (vec3<f32>(_e4664.x, _e4664.y, _e4666.x) * _e3877)) + (vec3<f32>(_e4666.y, _e4668.x, _e4668.y) * _e3878)) + (vec3<f32>(_e4670.x, _e4670.y, _e4672.x) * _e3880)) + (vec3<f32>(_e4672.y, _e4674.x, _e4674.y) * _e3882)) + (vec3<f32>(_e4676.x, _e4676.y, _e4678.x) * _e3886)) + (vec3<f32>(_e4678.y, _e4680.x, _e4680.y) * _e3887)) + (vec3<f32>(_e4682.x, _e4682.y, unpack2x16float(_e4656.y).x) * _e3891)) * _e4642);
                        let _e4745 = min((_e3873 + vec3<i32>(0i, 1i, 1i)), _e3892);
                        let _e4754 = (_e3843 + ((_e4745.x + (_e3869.x * (_e4745.y + (_e3869.y * _e4745.z)))) * 4i));
                        let _e4761 = ((((((vec3<f32>(_e4745) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e3832) * _e3806) * 2f) - _e3806) - _e3805);
                        let _e4767 = (dot((_e4761 * inverseSqrt(max(dot(_e4761, _e4761), 0.0000000001f))), _e3847) + 1f);
                        let _e4773 = (_e4754 + 3i);
                        let _e4777 = global_3.member[_e4773][1u];
                        let _e4782 = (((_e4205 * _e3875.z) * ((0.25f * (_e4767 * _e4767)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e4777).y > 0.5f)));
                        let _e4785 = global_3.member[_e4754];
                        let _e4789 = global_3.member[(_e4754 + 1i)];
                        let _e4793 = global_3.member[(_e4754 + 2i)];
                        let _e4796 = global_3.member[_e4773];
                        let _e4798 = unpack2x16float(_e4785.x);
                        let _e4800 = unpack2x16float(_e4785.y);
                        let _e4802 = unpack2x16float(_e4785.z);
                        let _e4804 = unpack2x16float(_e4785.w);
                        let _e4806 = unpack2x16float(_e4789.x);
                        let _e4808 = unpack2x16float(_e4789.y);
                        let _e4810 = unpack2x16float(_e4789.z);
                        let _e4812 = unpack2x16float(_e4789.w);
                        let _e4814 = unpack2x16float(_e4793.x);
                        let _e4816 = unpack2x16float(_e4793.y);
                        let _e4818 = unpack2x16float(_e4793.z);
                        let _e4820 = unpack2x16float(_e4793.w);
                        let _e4822 = unpack2x16float(_e4796.x);
                        let _e4878 = ((((((((((vec3<f32>(_e4798.x, _e4798.y, _e4800.x) * 0.282095f) + (vec3<f32>(_e4800.y, _e4802.x, _e4802.y) * _e3876)) + (vec3<f32>(_e4804.x, _e4804.y, _e4806.x) * _e3877)) + (vec3<f32>(_e4806.y, _e4808.x, _e4808.y) * _e3878)) + (vec3<f32>(_e4810.x, _e4810.y, _e4812.x) * _e3880)) + (vec3<f32>(_e4812.y, _e4814.x, _e4814.y) * _e3882)) + (vec3<f32>(_e4816.x, _e4816.y, _e4818.x) * _e3886)) + (vec3<f32>(_e4818.y, _e4820.x, _e4820.y) * _e3887)) + (vec3<f32>(_e4822.x, _e4822.y, unpack2x16float(_e4796.y).x) * _e3891)) * _e4782);
                        let _e4885 = min((_e3873 + vec3<i32>(1i, 1i, 1i)), _e3892);
                        let _e4894 = (_e3843 + ((_e4885.x + (_e3869.x * (_e4885.y + (_e3869.y * _e4885.z)))) * 4i));
                        let _e4901 = ((((((vec3<f32>(_e4885) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e3832) * _e3806) * 2f) - _e3806) - _e3805);
                        let _e4907 = (dot((_e4901 * inverseSqrt(max(dot(_e4901, _e4901), 0.0000000001f))), _e3847) + 1f);
                        let _e4913 = (_e4894 + 3i);
                        let _e4917 = global_3.member[_e4913][1u];
                        let _e4922 = (((_e4346 * _e3875.z) * ((0.25f * (_e4907 * _e4907)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e4917).y > 0.5f)));
                        let _e4925 = global_3.member[_e4894];
                        let _e4929 = global_3.member[(_e4894 + 1i)];
                        let _e4933 = global_3.member[(_e4894 + 2i)];
                        let _e4936 = global_3.member[_e4913];
                        let _e4938 = unpack2x16float(_e4925.x);
                        let _e4940 = unpack2x16float(_e4925.y);
                        let _e4942 = unpack2x16float(_e4925.z);
                        let _e4944 = unpack2x16float(_e4925.w);
                        let _e4946 = unpack2x16float(_e4929.x);
                        let _e4948 = unpack2x16float(_e4929.y);
                        let _e4950 = unpack2x16float(_e4929.z);
                        let _e4952 = unpack2x16float(_e4929.w);
                        let _e4954 = unpack2x16float(_e4933.x);
                        let _e4956 = unpack2x16float(_e4933.y);
                        let _e4958 = unpack2x16float(_e4933.z);
                        let _e4960 = unpack2x16float(_e4933.w);
                        let _e4962 = unpack2x16float(_e4936.x);
                        let _e5018 = ((((((((((vec3<f32>(_e4938.x, _e4938.y, _e4940.x) * 0.282095f) + (vec3<f32>(_e4940.y, _e4942.x, _e4942.y) * _e3876)) + (vec3<f32>(_e4944.x, _e4944.y, _e4946.x) * _e3877)) + (vec3<f32>(_e4946.y, _e4948.x, _e4948.y) * _e3878)) + (vec3<f32>(_e4950.x, _e4950.y, _e4952.x) * _e3880)) + (vec3<f32>(_e4952.y, _e4954.x, _e4954.y) * _e3882)) + (vec3<f32>(_e4956.x, _e4956.y, _e4958.x) * _e3886)) + (vec3<f32>(_e4958.y, _e4960.x, _e4960.y) * _e3887)) + (vec3<f32>(_e4962.x, _e4962.y, unpack2x16float(_e4936.y).x) * _e3891)) * _e4922);
                        let _e5023 = (((((((vec4<f32>(_e4033.x, _e4033.y, _e4033.z, _e3937) + vec4<f32>(_e4174.x, _e4174.y, _e4174.z, _e4078)) + vec4<f32>(_e4316.x, _e4316.y, _e4316.z, _e4220)) + vec4<f32>(_e4457.x, _e4457.y, _e4457.z, _e4361)) + vec4<f32>(_e4598.x, _e4598.y, _e4598.z, _e4502)) + vec4<f32>(_e4738.x, _e4738.y, _e4738.z, _e4642)) + vec4<f32>(_e4878.x, _e4878.y, _e4878.z, _e4782)) + vec4<f32>(_e5018.x, _e5018.y, _e5018.z, _e4922));
                        phi_21977_ = _e3768;
                        if (_e5023.w > 0.00001f) {
                            phi_21977_ = mix(_e3768, ((max(_e5023.xyz, vec3<f32>(0f, 0f, 0f)) / vec3(_e5023.w)) * _e3837.z), vec3(_e3825));
                        }
                        let _e5035 = phi_21977_;
                        phi_21976_ = _e5035;
                        continue;
                    } else {
                        break;
                    }
                    continuing {
                        let _e5037 = phi_21976_;
                        phi_21184_ = _e5037;
                        phi_21183_ = (_e3770 + 1i);
                    }
                }
                let _e7894 = local_62;
                phi_21185_ = _e7894;
            } else {
                phi_21185_ = _e3619;
            }
            let _e5040 = phi_21185_;
            phi_21413_ = _e3743;
            if (_e3758 > 0.5f) {
                if _e3386 {
                    let _e5043 = reflect(-(_e820), _e3313);
                    let _e5045 = global.member_29;
                    let _e5064 = vec2<f32>(((atan2(((_e5045.z * _e5043.x) - (_e5045.w * _e5043.z)), -(((_e5045.w * _e5043.x) + (_e5045.z * _e5043.z)))) * 0.15915494f) + 0.5f), (acos(clamp(_e5043.y, -1f, 1f)) * 0.31830987f));
                    let _e5065 = (_e3290 * 5f);
                    let _e5067 = min(i32(_e5065), 4i);
                    local_9 = array<vec4<i32>, 6>(vec4<i32>(0i, 0i, 512i, 256i), vec4<i32>(0i, 256i, 256i, 128i), vec4<i32>(256i, 256i, 128i, 64i), vec4<i32>(384i, 256i, 64i, 32i), vec4<i32>(448i, 256i, 32i, 16i), vec4<i32>(480i, 256i, 16i, 8i));
                    let _e5069 = local_9[_e5067];
                    let _e5073 = ((_e5064 * vec2<f32>(_e5069.zw)) - vec2<f32>(0.5f, 0.5f));
                    let _e5074 = floor(_e5073);
                    let _e5075 = (_e5073 - _e5074);
                    let _e5077 = i32(_e5074.x);
                    let _e5079 = i32(_e5074.y);
                    phi_21208_ = _e5077;
                    if (_e5077 < 0i) {
                        phi_21208_ = (_e5077 + _e5069.z);
                    }
                    let _e5084 = phi_21208_;
                    phi_21209_ = _e5084;
                    if (_e5084 >= _e5069.z) {
                        phi_21209_ = (_e5084 - _e5069.z);
                    }
                    let _e5089 = phi_21209_;
                    let _e5090 = (_e5089 + 1i);
                    let _e5092 = select(_e5090, 0i, (_e5090 == _e5069.z));
                    let _e5096 = min((_e5079 + 1i), (_e5069.w - 1i));
                    let _e5097 = max(_e5079, 0i);
                    let _e5098 = _e5069.xy;
                    let _e5101 = textureLoad(global_4, (_e5098 + vec2<i32>(_e5089, _e5097)), 0i);
                    let _e5105 = textureLoad(global_4, (_e5098 + vec2<i32>(_e5092, _e5097)), 0i);
                    let _e5109 = textureLoad(global_4, (_e5098 + vec2<i32>(_e5089, _e5096)), 0i);
                    let _e5113 = textureLoad(global_4, (_e5098 + vec2<i32>(_e5092, _e5096)), 0i);
                    let _e5116 = vec3(_e5075.x);
                    local_10 = array<vec4<i32>, 6>(vec4<i32>(0i, 0i, 512i, 256i), vec4<i32>(0i, 256i, 256i, 128i), vec4<i32>(256i, 256i, 128i, 64i), vec4<i32>(384i, 256i, 64i, 32i), vec4<i32>(448i, 256i, 32i, 16i), vec4<i32>(480i, 256i, 16i, 8i));
                    let _e5124 = local_10[(_e5067 + 1i)];
                    let _e5128 = ((_e5064 * vec2<f32>(_e5124.zw)) - vec2<f32>(0.5f, 0.5f));
                    let _e5129 = floor(_e5128);
                    let _e5130 = (_e5128 - _e5129);
                    let _e5132 = i32(_e5129.x);
                    let _e5134 = i32(_e5129.y);
                    phi_21215_ = _e5132;
                    if (_e5132 < 0i) {
                        phi_21215_ = (_e5132 + _e5124.z);
                    }
                    let _e5139 = phi_21215_;
                    phi_21216_ = _e5139;
                    if (_e5139 >= _e5124.z) {
                        phi_21216_ = (_e5139 - _e5124.z);
                    }
                    let _e5144 = phi_21216_;
                    let _e5145 = (_e5144 + 1i);
                    let _e5147 = select(_e5145, 0i, (_e5145 == _e5124.z));
                    let _e5151 = min((_e5134 + 1i), (_e5124.w - 1i));
                    let _e5152 = max(_e5134, 0i);
                    let _e5153 = _e5124.xy;
                    let _e5156 = textureLoad(global_4, (_e5153 + vec2<i32>(_e5144, _e5152)), 0i);
                    let _e5160 = textureLoad(global_4, (_e5153 + vec2<i32>(_e5147, _e5152)), 0i);
                    let _e5164 = textureLoad(global_4, (_e5153 + vec2<i32>(_e5144, _e5151)), 0i);
                    let _e5168 = textureLoad(global_4, (_e5153 + vec2<i32>(_e5147, _e5151)), 0i);
                    let _e5171 = vec3(_e5130.x);
                    let _e5183 = global.member_29[1u];
                    phi_21222_ = (mix(mix(mix(_e5101.xyz, _e5105.xyz, _e5116), mix(_e5109.xyz, _e5113.xyz, _e5116), vec3(_e5075.y)), mix(mix(_e5156.xyz, _e5160.xyz, _e5171), mix(_e5164.xyz, _e5168.xyz, _e5171), vec3(_e5130.y)), vec3((_e5065 - f32(_e5067)))) * _e5183);
                } else {
                    let _e5188 = global.member_9;
                    let _e5191 = global.member_8;
                    let _e5200 = global.member_8[3u];
                    phi_21222_ = mix((mix(_e5188.xyz, _e5191.xyz, vec3(((reflect(-(_e820), _e3313).y * 0.5f) + 0.5f))) * _e5200), _e3619, vec3(_e3290));
                }
                let _e5205 = phi_21222_;
                let _e5207 = reflect(-(_e820), _e3313);
                phi_21304_ = vec3<f32>(0f, 0f, 0f);
                phi_21238_ = 0f;
                phi_21237_ = 0i;
                loop {
                    let _e5210 = phi_21304_;
                    let _e5212 = phi_21238_;
                    let _e5214 = phi_21237_;
                    local_48 = _e5212;
                    local_49 = _e5210;
                    if (_e5214 < i32(_e3758)) {
                        if (_e5212 > 0.999f) {
                            break;
                        }
                        let _e5217 = (_e5214 * 8i);
                        let _e5220 = global_3.member[_e5217];
                        let _e5221 = bitcast<vec4<f32>>(_e5220);
                        let _e5225 = global_3.member[(_e5217 + 1i)];
                        let _e5226 = bitcast<vec4<f32>>(_e5225);
                        let _e5230 = global_3.member[(_e5217 + 2i)];
                        let _e5231 = bitcast<vec4<f32>>(_e5230);
                        let _e5232 = _e5221.xyz;
                        let _e5236 = _e5226.xyz;
                        let _e5240 = _e5231.xyz;
                        let _e5244 = vec3<f32>((dot(_e5232, _e818) + _e5221.w), (dot(_e5236, _e818) + _e5226.w), (dot(_e5240, _e818) + _e5231.w));
                        let _e5248 = global_3.member[(_e5217 + 3i)];
                        let _e5249 = bitcast<vec4<f32>>(_e5248);
                        switch bitcast<i32>(0u) {
                            default: {
                                let _e5254 = (_e5249.xyz - abs(_e5244));
                                let _e5259 = min(_e5254.x, min(_e5254.y, _e5254.z));
                                if (_e5259 <= 0f) {
                                    phi_21239_ = 0f;
                                    break;
                                }
                                if (_e5249.w <= 0f) {
                                    phi_21239_ = 1f;
                                    break;
                                }
                                let _e5263 = min((_e5259 / _e5249.w), 1f);
                                phi_21239_ = ((_e5263 * _e5263) * (3f - (2f * _e5263)));
                                break;
                            }
                        }
                        let _e5269 = phi_21239_;
                        if (_e5269 <= 0f) {
                            phi_21991_ = _e5210;
                            phi_21990_ = _e5212;
                            continue;
                        }
                        let _e5274 = global_3.member[(_e5217 + 4i)];
                        let _e5275 = bitcast<vec4<f32>>(_e5274);
                        let _e5279 = global_3.member[(_e5217 + 5i)];
                        let _e5280 = bitcast<vec4<f32>>(_e5279);
                        let _e5284 = vec3<f32>(dot(_e5232, _e5207), dot(_e5236, _e5207), dot(_e5240, _e5207));
                        if (_e5275.w > 0.5f) {
                            let _e5287 = _e5275.xyz;
                            let _e5289 = -(_e5287);
                            let _e5290 = clamp(_e5244, _e5289, _e5287);
                            let _e5294 = step(vec3<f32>(0.000001f, 0.000001f, 0.000001f), abs(_e5284));
                            let _e5298 = mix(vec3<f32>(1000000000000000000000000000000f, 1000000000000000000000000000000f, 1000000000000000000000000000000f), ((mix(_e5289, _e5287, step(vec3<f32>(0f, 0f, 0f), _e5284)) - _e5290) / mix(vec3<f32>(0.000001f, 0.000001f, 0.000001f), _e5284, _e5294)), _e5294);
                            let _e5307 = ((_e5290 + (_e5284 * max(min(_e5298.x, min(_e5298.y, _e5298.z)), 0f))) - _e5280.xyz);
                            if (dot(_e5307, _e5307) > 0.000000000001f) {
                                phi_21240_ = normalize(_e5307);
                            } else {
                                phi_21240_ = _e5284;
                            }
                            let _e5312 = phi_21240_;
                            phi_21241_ = _e5312;
                        } else {
                            phi_21241_ = _e5284;
                        }
                        let _e5314 = phi_21241_;
                        let _e5319 = global_3.member[(_e5217 + 6i)][0u];
                        let _e5320 = bitcast<i32>(_e5319);
                        let _e5331 = vec2<f32>(((atan2(_e5314.x, -(_e5314.z)) * 0.15915494f) + 0.5f), (acos(clamp(_e5314.y, -1f, 1f)) * 0.31830987f));
                        let _e5332 = (_e3290 * 5f);
                        let _e5334 = min(i32(_e5332), 4i);
                        local_8 = array<vec3<i32>, 6>(vec3<i32>(0i, 256i, 128i), vec3<i32>(32768i, 128i, 64i), vec3<i32>(40960i, 64i, 32i), vec3<i32>(43008i, 32i, 16i), vec3<i32>(43520i, 16i, 8i), vec3<i32>(43648i, 8i, 4i));
                        let _e5336 = local_8[_e5334];
                        let _e5338 = (_e5320 + _e5336.x);
                        let _e5342 = ((_e5331 * vec2<f32>(_e5336.yz)) - vec2<f32>(0.5f, 0.5f));
                        let _e5343 = floor(_e5342);
                        let _e5344 = (_e5342 - _e5343);
                        let _e5346 = i32(_e5343.x);
                        let _e5348 = i32(_e5343.y);
                        phi_21242_ = _e5346;
                        if (_e5346 < 0i) {
                            phi_21242_ = (_e5346 + _e5336.y);
                        }
                        let _e5353 = phi_21242_;
                        phi_21243_ = _e5353;
                        if (_e5353 >= _e5336.y) {
                            phi_21243_ = (_e5353 - _e5336.y);
                        }
                        let _e5358 = phi_21243_;
                        let _e5359 = (_e5358 + 1i);
                        let _e5361 = select(_e5359, 0i, (_e5359 == _e5336.y));
                        let _e5368 = (_e5338 + (max(_e5348, 0i) * _e5336.y));
                        let _e5369 = (_e5368 + _e5358);
                        let _e5374 = global_3.member[(_e5369 >> bitcast<u32>(1i))];
                        if ((_e5369 & 1i) == 0i) {
                            phi_21249_ = _e5374.xy;
                        } else {
                            phi_21249_ = _e5374.zw;
                        }
                        let _e5380 = phi_21249_;
                        let _e5382 = unpack2x16float(_e5380.x);
                        let _e5389 = (_e5368 + _e5361);
                        let _e5394 = global_3.member[(_e5389 >> bitcast<u32>(1i))];
                        if ((_e5389 & 1i) == 0i) {
                            phi_21251_ = _e5394.xy;
                        } else {
                            phi_21251_ = _e5394.zw;
                        }
                        let _e5400 = phi_21251_;
                        let _e5402 = unpack2x16float(_e5400.x);
                        let _e5410 = (_e5338 + (min((_e5348 + 1i), (_e5336.z - 1i)) * _e5336.y));
                        let _e5411 = (_e5410 + _e5358);
                        let _e5416 = global_3.member[(_e5411 >> bitcast<u32>(1i))];
                        if ((_e5411 & 1i) == 0i) {
                            phi_21254_ = _e5416.xy;
                        } else {
                            phi_21254_ = _e5416.zw;
                        }
                        let _e5422 = phi_21254_;
                        let _e5424 = unpack2x16float(_e5422.x);
                        let _e5431 = (_e5410 + _e5361);
                        let _e5436 = global_3.member[(_e5431 >> bitcast<u32>(1i))];
                        if ((_e5431 & 1i) == 0i) {
                            phi_21255_ = _e5436.xy;
                        } else {
                            phi_21255_ = _e5436.zw;
                        }
                        let _e5442 = phi_21255_;
                        let _e5444 = unpack2x16float(_e5442.x);
                        let _e5452 = vec3(_e5344.x);
                        local_7 = array<vec3<i32>, 6>(vec3<i32>(0i, 256i, 128i), vec3<i32>(32768i, 128i, 64i), vec3<i32>(40960i, 64i, 32i), vec3<i32>(43008i, 32i, 16i), vec3<i32>(43520i, 16i, 8i), vec3<i32>(43648i, 8i, 4i));
                        let _e5460 = local_7[(_e5334 + 1i)];
                        let _e5462 = (_e5320 + _e5460.x);
                        let _e5466 = ((_e5331 * vec2<f32>(_e5460.yz)) - vec2<f32>(0.5f, 0.5f));
                        let _e5467 = floor(_e5466);
                        let _e5468 = (_e5466 - _e5467);
                        let _e5470 = i32(_e5467.x);
                        let _e5472 = i32(_e5467.y);
                        phi_21256_ = _e5470;
                        if (_e5470 < 0i) {
                            phi_21256_ = (_e5470 + _e5460.y);
                        }
                        let _e5477 = phi_21256_;
                        phi_21257_ = _e5477;
                        if (_e5477 >= _e5460.y) {
                            phi_21257_ = (_e5477 - _e5460.y);
                        }
                        let _e5482 = phi_21257_;
                        let _e5483 = (_e5482 + 1i);
                        let _e5485 = select(_e5483, 0i, (_e5483 == _e5460.y));
                        let _e5492 = (_e5462 + (max(_e5472, 0i) * _e5460.y));
                        let _e5493 = (_e5492 + _e5482);
                        let _e5498 = global_3.member[(_e5493 >> bitcast<u32>(1i))];
                        if ((_e5493 & 1i) == 0i) {
                            phi_21263_ = _e5498.xy;
                        } else {
                            phi_21263_ = _e5498.zw;
                        }
                        let _e5504 = phi_21263_;
                        let _e5506 = unpack2x16float(_e5504.x);
                        let _e5513 = (_e5492 + _e5485);
                        let _e5518 = global_3.member[(_e5513 >> bitcast<u32>(1i))];
                        if ((_e5513 & 1i) == 0i) {
                            phi_21265_ = _e5518.xy;
                        } else {
                            phi_21265_ = _e5518.zw;
                        }
                        let _e5524 = phi_21265_;
                        let _e5526 = unpack2x16float(_e5524.x);
                        let _e5534 = (_e5462 + (min((_e5472 + 1i), (_e5460.z - 1i)) * _e5460.y));
                        let _e5535 = (_e5534 + _e5482);
                        let _e5540 = global_3.member[(_e5535 >> bitcast<u32>(1i))];
                        if ((_e5535 & 1i) == 0i) {
                            phi_21268_ = _e5540.xy;
                        } else {
                            phi_21268_ = _e5540.zw;
                        }
                        let _e5546 = phi_21268_;
                        let _e5548 = unpack2x16float(_e5546.x);
                        let _e5555 = (_e5534 + _e5485);
                        let _e5560 = global_3.member[(_e5555 >> bitcast<u32>(1i))];
                        if ((_e5555 & 1i) == 0i) {
                            phi_21269_ = _e5560.xy;
                        } else {
                            phi_21269_ = _e5560.zw;
                        }
                        let _e5566 = phi_21269_;
                        let _e5568 = unpack2x16float(_e5566.x);
                        let _e5576 = vec3(_e5468.x);
                        let _e5589 = (_e5269 * (1f - _e5212));
                        phi_21991_ = (_e5210 + ((mix(mix(mix(vec3<f32>(_e5382.x, _e5382.y, unpack2x16float(_e5380.y).x), vec3<f32>(_e5402.x, _e5402.y, unpack2x16float(_e5400.y).x), _e5452), mix(vec3<f32>(_e5424.x, _e5424.y, unpack2x16float(_e5422.y).x), vec3<f32>(_e5444.x, _e5444.y, unpack2x16float(_e5442.y).x), _e5452), vec3(_e5344.y)), mix(mix(vec3<f32>(_e5506.x, _e5506.y, unpack2x16float(_e5504.y).x), vec3<f32>(_e5526.x, _e5526.y, unpack2x16float(_e5524.y).x), _e5576), mix(vec3<f32>(_e5548.x, _e5548.y, unpack2x16float(_e5546.y).x), vec3<f32>(_e5568.x, _e5568.y, unpack2x16float(_e5566.y).x), _e5576), vec3(_e5468.y)), vec3((_e5332 - f32(_e5334)))) * _e5280.w) * _e5589));
                        phi_21990_ = (_e5212 + _e5589);
                        continue;
                    } else {
                        break;
                    }
                    continuing {
                        let _e5594 = phi_21991_;
                        let _e5596 = phi_21990_;
                        phi_21304_ = _e5594;
                        phi_21238_ = _e5596;
                        phi_21237_ = (_e5214 + 1i);
                    }
                }
                let _e5599 = local_48;
                let _e5603 = local_49;
                let _e5604 = (_e5603 + (_e5205 * (1f - _e5599)));
                phi_4270_ = _e1254;
                if _e1254 {
                    let _e5607 = global.member_33[2u];
                    phi_4270_ = (_e5607 > 0.5f);
                }
                let _e5610 = phi_4270_;
                phi_21414_ = _e5604;
                if _e5610 {
                    switch bitcast<i32>(0u) {
                        default: {
                            let _e5613 = global.member_31;
                            let _e5614 = _e5613.xyz;
                            let _e5617 = global.member_33[0u];
                            let _e5622 = global.member_31[3u];
                            let _e5631 = global.member_32[1u];
                            let _e5637 = global.member_32[0u];
                            let _e5640 = (((_e5637 * (1f - smoothstep((_e5617 * 0.5f), _e5617, abs((dot(_e5614, _e818) - _e5622))))) * smoothstep(0.5f, 0.9f, dot(_e825, _e5614))) * (1f - smoothstep((_e5631 * 0.5f), _e5631, _e3290)));
                            if (_e5640 <= 0f) {
                                phi_21380_ = _e5604;
                                break;
                            }
                            let _e5647 = global.member_32[3u];
                            let _e5649 = (_e818 + ((_e810 - (_e5614 * dot(_e810, _e5614))) * _e5647));
                            let _e5651 = global.member_30;
                            let _e5656 = (_e5651 * vec4<f32>(_e5649.x, _e5649.y, _e5649.z, 1f));
                            let _e5668 = global.member_32[2u];
                            phi_21379_ = 0f;
                            phi_21378_ = vec3<f32>(0f, 0f, 0f);
                            phi_21377_ = 0i;
                            loop {
                                let _e5671 = phi_21379_;
                                let _e5673 = phi_21378_;
                                let _e5675 = phi_21377_;
                                local_50 = _e5673;
                                local_51 = _e5671;
                                if (_e5675 < 12i) {
                                    continue;
                                } else {
                                    break;
                                }
                                continuing {
                                    let _e5677 = f32(_e5675);
                                    let _e5682 = (_e5677 * 2.3999631f);
                                    let _e5686 = global.member_33[1u];
                                    let _e5691 = ((((vec2<f32>(_e5656.x, -(_e5656.y)) / vec2(_e5656.w)) * 0.5f) + vec2<f32>(0.5f, 0.5f)) + (vec2<f32>((cos(_e5682) * _e5686), sin(_e5682)) * (sqrt(((_e5677 + 0.5f) * 0.083333336f)) * (_e5668 * _e3290))));
                                    let _e5693 = min(_e5691, (vec2<f32>(1f, 1f) - _e5691));
                                    let _e5697 = smoothstep(0f, 0.04f, min(_e5693.x, _e5693.y));
                                    let _e5699 = textureSampleLevel(global_19, global_5, clamp(_e5691, vec2<f32>(0f, 0f), vec2<f32>(1f, 1f)), 0f);
                                    let _e5700 = _e5699.xyz;
                                    phi_21379_ = (_e5671 + (_e5699.w * _e5697));
                                    phi_21378_ = (_e5673 + ((_e5700 / (vec3<f32>(1f, 1f, 1f) - min(_e5700, vec3<f32>(0.995f, 0.995f, 0.995f)))) * _e5697));
                                    phi_21377_ = (_e5675 + 1i);
                                }
                            }
                            let _e5711 = local_50;
                            let _e5714 = local_51;
                            phi_21380_ = mix(_e5604, ((_e5711 * vec3<f32>(0.083333336f, 0.083333336f, 0.083333336f)) + (_e5604 * (1f - (_e5714 * 0.083333336f)))), vec3(_e5640));
                            break;
                        }
                    }
                    let _e5722 = phi_21380_;
                    phi_21414_ = _e5722;
                }
                let _e5724 = phi_21414_;
                phi_21413_ = _e5724;
            }
            let _e5726 = phi_21413_;
            phi_21650_ = (_e3755 + (((_e3750 * (_e5040 - _e3619)) + (_e3748 * (_e5726 - _e3743))) * _e1272));
        }
        let _e5735 = phi_21650_;
        let _e5738 = global.member_13[3u];
        phi_21720_ = _e5735;
        if (_e5738 > 0.5f) {
            let _e5741 = global.member_11;
            let _e5746 = global.member_11[3u];
            let _e5748 = global_16;
            let _e5751 = global.member_12;
            let _e5756 = global.member_13;
            let _e5759 = clamp(floor((_e5748.xy * _e5751.xy)), vec2<f32>(0f, 0f), (_e5756.xy - vec2<f32>(1f, 1f)));
            let _e5764 = global.member_12[2u];
            let _e5768 = global.member_12[3u];
            let _e5773 = global.member_13[2u];
            let _e5778 = global.member_13[1u];
            let _e5784 = global.member_13[0u];
            let _e5788 = u32(((((clamp(floor(((log2(max((dot(_e5741.xyz, _e818) + _e5746), 0.000001f)) * _e5764) + _e5768)), 0f, (_e5773 - 1f)) * _e5778) + _e5759.y) * _e5784) + _e5759.x));
            let _e5795 = global_17.member[(_e5788 >> bitcast<u32>(2i))][(_e5788 & 3u)];
            let _e5796 = (_e5795 & 65535u);
            phi_21649_ = _e5735;
            phi_21515_ = _e5796;
            loop {
                let _e5800 = phi_21649_;
                let _e5802 = phi_21515_;
                local_66 = _e5800;
                if (_e5802 < (_e5796 + (_e5795 >> bitcast<u32>(16i)))) {
                    let _e5805 = (_e5802 / 3u);
                    let _e5812 = global_18.member[(_e5805 >> bitcast<u32>(2i))][(_e5805 & 3u)];
                    let _e5818 = ((_e5812 >> bitcast<u32>(((_e5802 - (_e5805 * 3u)) * 10u))) & 1023u);
                    let _e5821 = global_12.member[_e5818];
                    let _e5823 = (_e5821.xyz - _e818);
                    let _e5824 = dot(_e5823, _e5823);
                    let _e5826 = (_e5824 * _e5821.w);
                    let _e5829 = clamp((1f - (_e5826 * _e5826)), 0f, 1f);
                    let _e5832 = (_e5823 * inverseSqrt(max(_e5824, 0.00000001f)));
                    let _e5835 = global_14.member[_e5818];
                    let _e5838 = global_15.member[_e5818];
                    let _e5846 = clamp(((dot(-(_e5832), _e5838.xyz) * _e5835.w) + _e5838.w), 0f, 1f);
                    let _e5853 = (_e5835.xyz * ((((_e5829 * _e5829) * _e5846) * _e5846) / max(_e5824, 0.0001f)));
                    phi_21647_ = _e5853;
                    if _e828 {
                        switch bitcast<i32>(0u) {
                            default: {
                                let _e5857 = global.member_21[2u];
                                let _e5858 = u32(_e5857);
                                if (_e5818 < _e5858) {
                                    let _e5862 = global.member_26[_e5818];
                                    let _e5865 = global.member_15[_e5818];
                                    let _e5874 = (_e5862.z * max((_e5865 * vec4<f32>(_e818.x, _e818.y, _e818.z, 1f)).w, 0f));
                                    let _e5877 = global.member_25[0u];
                                    let _e5883 = global.member_25[1u];
                                    let _e5886 = ((_e818 + (_e825 * (_e5874 * _e5877))) + (_e5832 * (_e5874 * _e5883)));
                                    let _e5891 = (_e5865 * vec4<f32>(_e5886.x, _e5886.y, _e5886.z, 1f));
                                    if (_e5891.w <= 0f) {
                                        phi_21542_ = 1f;
                                        break;
                                    }
                                    let _e5896 = (_e5891.xyz / vec3(_e5891.w));
                                    let _e5898 = (_e5896.x < 0f);
                                    phi_15360_ = _e5898;
                                    if !(_e5898) {
                                        phi_15360_ = (_e5896.x > 1f);
                                    }
                                    let _e5902 = phi_15360_;
                                    phi_15367_ = _e5902;
                                    if !(_e5902) {
                                        phi_15367_ = (_e5896.y < 0f);
                                    }
                                    let _e5907 = phi_15367_;
                                    phi_15374_ = _e5907;
                                    if !(_e5907) {
                                        phi_15374_ = (_e5896.y > 1f);
                                    }
                                    let _e5912 = phi_15374_;
                                    phi_15381_ = _e5912;
                                    if !(_e5912) {
                                        phi_15381_ = (_e5896.z > 1f);
                                    }
                                    let _e5917 = phi_15381_;
                                    if _e5917 {
                                        phi_21542_ = 1f;
                                        break;
                                    }
                                    let _e5920 = _e5862.xy;
                                    let _e5922 = global.member_23;
                                    let _e5923 = _e5922.zw;
                                    let _e5925 = global.member_22;
                                    let _e5926 = _e5925.xy;
                                    let _e5927 = (_e5926 * 0.5f);
                                    let _e5929 = (_e5920 + (_e5896.xy * _e5923));
                                    let _e5930 = (_e5920 + _e5927);
                                    let _e5932 = ((_e5920 + _e5923) - _e5927);
                                    let _e5937 = vec4<f32>(_e5930.x, _e5930.y, _e5932.x, _e5932.y);
                                    switch bitcast<i32>(0u) {
                                        default: {
                                            let _e5941 = global.member_22[2u];
                                            let _e5942 = i32(_e5941);
                                            if (_e5942 <= 0i) {
                                                let _e5946 = clamp(_e5929, _e5937.xy, _e5937.zw);
                                                let _e5951 = textureSampleCompare(global_2, global_1, vec3<f32>(_e5946.x, _e5946.y, _e5896.z).xy, _e5896.z);
                                                phi_21541_ = _e5951;
                                                break;
                                            }
                                            let _e5953 = ((_e5929 / _e5926) + vec2<f32>(0.5f, 0.5f));
                                            let _e5954 = floor(_e5953);
                                            let _e5955 = (_e5953 - _e5954);
                                            let _e5957 = (_e5942 == 1i);
                                            if _e5957 {
                                                let _e5958 = (_e5955 * 2f);
                                                local_3[0i] = (vec2<f32>(3f, 3f) - _e5958);
                                                local_3[1i] = (vec2<f32>(1f, 1f) + _e5958);
                                                let _e5964 = local_3[0i];
                                                local_4[0i] = (((vec2<f32>(2f, 2f) - _e5955) / _e5964) - vec2<f32>(1f, 1f));
                                                let _e5968 = local_3[1i];
                                                local_4[1i] = ((_e5955 / _e5968) + vec2<f32>(1f, 1f));
                                            } else {
                                                let _e5972 = (_e5955 * 3f);
                                                local_3[0i] = (vec2<f32>(4f, 4f) - _e5972);
                                                local_3[1i] = vec2<f32>(7f, 7f);
                                                local_3[2i] = (vec2<f32>(1f, 1f) + _e5972);
                                                let _e5980 = local_3[0i];
                                                local_4[0i] = (((vec2<f32>(3f, 3f) - (_e5955 * 2f)) / _e5980) - vec2<f32>(2f, 2f));
                                                let _e5985 = local_3[1i];
                                                local_4[1i] = ((vec2<f32>(3f, 3f) + _e5955) / _e5985);
                                                let _e5988 = local_3[2i];
                                                local_4[2i] = ((_e5955 / _e5988) + vec2<f32>(2f, 2f));
                                            }
                                            let _e5993 = select(3i, 2i, _e5957);
                                            phi_21534_ = 0f;
                                            phi_21531_ = 0i;
                                            loop {
                                                let _e5995 = phi_21534_;
                                                let _e5997 = phi_21531_;
                                                local_52 = _e5995;
                                                if (_e5997 < _e5993) {
                                                    phi_21540_ = _e5995;
                                                    phi_21537_ = 0i;
                                                    loop {
                                                        let _e6000 = phi_21540_;
                                                        let _e6002 = phi_21537_;
                                                        local_64 = _e6000;
                                                        if (_e6002 < _e5993) {
                                                            continue;
                                                        } else {
                                                            break;
                                                        }
                                                        continuing {
                                                            let _e6006 = local_4[_e6002][0u];
                                                            let _e6009 = local_4[_e5997][1u];
                                                            let _e6015 = clamp((_e5926 * ((_e5954 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e6006, _e6009))), _e5937.xy, _e5937.zw);
                                                            let _e6018 = local_3[_e6002][0u];
                                                            let _e6021 = local_3[_e5997][1u];
                                                            let _e6027 = textureSampleCompare(global_2, global_1, vec3<f32>(_e6015.x, _e6015.y, _e5896.z).xy, _e5896.z);
                                                            phi_21540_ = (_e6000 + ((_e6018 * _e6021) * _e6027));
                                                            phi_21537_ = (_e6002 + 1i);
                                                        }
                                                    }
                                                    continue;
                                                } else {
                                                    break;
                                                }
                                                continuing {
                                                    let _e7942 = local_64;
                                                    phi_21534_ = _e7942;
                                                    phi_21531_ = (_e5997 + 1i);
                                                }
                                            }
                                            let _e6033 = local_52;
                                            phi_21541_ = (_e6033 * select(0.0069444445f, 0.0625f, _e5957));
                                            break;
                                        }
                                    }
                                    let _e6036 = phi_21541_;
                                    phi_21542_ = _e6036;
                                    break;
                                }
                                let _e6037 = (_e5818 - _e5858);
                                let _e6040 = global.member_21[3u];
                                if (_e6037 >= u32(_e6040)) {
                                    phi_21542_ = 1f;
                                    break;
                                }
                                let _e6045 = global.member_27[_e6037];
                                let _e6048 = global.member_28[_e6037];
                                let _e6050 = _e6045.xyz;
                                let _e6053 = (_e6045.w * length((_e818 - _e6050)));
                                let _e6056 = global.member_25[0u];
                                let _e6062 = global.member_25[1u];
                                let _e6066 = (((_e818 + (_e825 * (_e6053 * _e6056))) + (_e5832 * (_e6053 * _e6062))) - _e6050);
                                let _e6067 = abs(_e6066);
                                let _e6070 = (_e6067.x >= _e6067.y);
                                phi_15451_ = _e6070;
                                if _e6070 {
                                    phi_15451_ = (_e6067.x >= _e6067.z);
                                }
                                let _e6074 = phi_15451_;
                                if _e6074 {
                                    phi_21518_ = select(1i, 0i, (_e6066.x > 0f));
                                    phi_21516_ = _e6067.x;
                                } else {
                                    let _e6079 = (_e6067.y >= _e6067.z);
                                    if _e6079 {
                                        phi_21519_ = select(3i, 2i, (_e6066.y > 0f));
                                    } else {
                                        phi_21519_ = select(5i, 4i, (_e6066.z > 0f));
                                    }
                                    let _e6087 = phi_21519_;
                                    phi_21518_ = _e6087;
                                    phi_21516_ = select(_e6067.z, _e6067.y, _e6079);
                                }
                                let _e6090 = phi_21518_;
                                let _e6092 = phi_21516_;
                                if (_e6092 <= 0f) {
                                    phi_21542_ = 1f;
                                    break;
                                }
                                local_5 = array<vec3<f32>, 6>(vec3<f32>(0f, 0f, 1f), vec3<f32>(0f, 0f, -1f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(1f, 0f, 0f));
                                let _e6095 = local_5[_e6090];
                                local_6 = array<vec3<f32>, 6>(vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 0f, -1f), vec3<f32>(0f, 0f, 1f), vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 1f, 0f));
                                let _e6098 = local_6[_e6090];
                                let _e6103 = global.member_24[2u];
                                let _e6106 = (vec2<f32>(dot(_e6066, _e6095), dot(_e6066, _e6098)) / vec2((_e6092 * _e6103)));
                                let _e6110 = (_e6048.z + (_e6048.w / _e6092));
                                if (_e6110 > 1f) {
                                    phi_21542_ = 1f;
                                    break;
                                }
                                let _e6125 = global.member_24;
                                let _e6126 = _e6125.xy;
                                let _e6128 = (_e6048.xy + (vec2<f32>(f32((_e6090 - (i32(floor((f32(_e6090) / f32(3i)))) * 3i))), f32((_e6090 / 3i))) * _e6126));
                                let _e6137 = global.member_22;
                                let _e6138 = _e6137.xy;
                                let _e6139 = (_e6138 * 0.5f);
                                let _e6141 = (_e6128 + (vec2<f32>((0.5f + (0.5f * _e6106.x)), (0.5f - (0.5f * _e6106.y))) * _e6126));
                                let _e6142 = (_e6128 + _e6139);
                                let _e6144 = ((_e6128 + _e6126) - _e6139);
                                let _e6149 = vec4<f32>(_e6142.x, _e6142.y, _e6144.x, _e6144.y);
                                switch bitcast<i32>(0u) {
                                    default: {
                                        let _e6153 = global.member_22[2u];
                                        let _e6154 = i32(_e6153);
                                        if (_e6154 <= 0i) {
                                            let _e6158 = clamp(_e6141, _e6149.xy, _e6149.zw);
                                            let _e6163 = textureSampleCompare(global_2, global_1, vec3<f32>(_e6158.x, _e6158.y, _e6110).xy, _e6110);
                                            phi_21530_ = _e6163;
                                            break;
                                        }
                                        let _e6165 = ((_e6141 / _e6138) + vec2<f32>(0.5f, 0.5f));
                                        let _e6166 = floor(_e6165);
                                        let _e6167 = (_e6165 - _e6166);
                                        let _e6169 = (_e6154 == 1i);
                                        if _e6169 {
                                            let _e6170 = (_e6167 * 2f);
                                            local_1[0i] = (vec2<f32>(3f, 3f) - _e6170);
                                            local_1[1i] = (vec2<f32>(1f, 1f) + _e6170);
                                            let _e6176 = local_1[0i];
                                            local_2[0i] = (((vec2<f32>(2f, 2f) - _e6167) / _e6176) - vec2<f32>(1f, 1f));
                                            let _e6180 = local_1[1i];
                                            local_2[1i] = ((_e6167 / _e6180) + vec2<f32>(1f, 1f));
                                        } else {
                                            let _e6184 = (_e6167 * 3f);
                                            local_1[0i] = (vec2<f32>(4f, 4f) - _e6184);
                                            local_1[1i] = vec2<f32>(7f, 7f);
                                            local_1[2i] = (vec2<f32>(1f, 1f) + _e6184);
                                            let _e6192 = local_1[0i];
                                            local_2[0i] = (((vec2<f32>(3f, 3f) - (_e6167 * 2f)) / _e6192) - vec2<f32>(2f, 2f));
                                            let _e6197 = local_1[1i];
                                            local_2[1i] = ((vec2<f32>(3f, 3f) + _e6167) / _e6197);
                                            let _e6200 = local_1[2i];
                                            local_2[2i] = ((_e6167 / _e6200) + vec2<f32>(2f, 2f));
                                        }
                                        let _e6205 = select(3i, 2i, _e6169);
                                        phi_21523_ = 0f;
                                        phi_21520_ = 0i;
                                        loop {
                                            let _e6207 = phi_21523_;
                                            let _e6209 = phi_21520_;
                                            local_53 = _e6207;
                                            if (_e6209 < _e6205) {
                                                phi_21529_ = _e6207;
                                                phi_21526_ = 0i;
                                                loop {
                                                    let _e6212 = phi_21529_;
                                                    let _e6214 = phi_21526_;
                                                    local_65 = _e6212;
                                                    if (_e6214 < _e6205) {
                                                        continue;
                                                    } else {
                                                        break;
                                                    }
                                                    continuing {
                                                        let _e6218 = local_2[_e6214][0u];
                                                        let _e6221 = local_2[_e6209][1u];
                                                        let _e6227 = clamp((_e6138 * ((_e6166 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e6218, _e6221))), _e6149.xy, _e6149.zw);
                                                        let _e6230 = local_1[_e6214][0u];
                                                        let _e6233 = local_1[_e6209][1u];
                                                        let _e6239 = textureSampleCompare(global_2, global_1, vec3<f32>(_e6227.x, _e6227.y, _e6110).xy, _e6110);
                                                        phi_21529_ = (_e6212 + ((_e6230 * _e6233) * _e6239));
                                                        phi_21526_ = (_e6214 + 1i);
                                                    }
                                                }
                                                continue;
                                            } else {
                                                break;
                                            }
                                            continuing {
                                                let _e7954 = local_65;
                                                phi_21523_ = _e7954;
                                                phi_21520_ = (_e6209 + 1i);
                                            }
                                        }
                                        let _e6245 = local_53;
                                        phi_21530_ = (_e6245 * select(0.0069444445f, 0.0625f, _e6169));
                                        break;
                                    }
                                }
                                let _e6248 = phi_21530_;
                                phi_21542_ = _e6248;
                                break;
                            }
                        }
                        let _e6250 = phi_21542_;
                        phi_21647_ = (_e5853 * _e6250);
                    }
                    let _e6253 = phi_21647_;
                    let _e6255 = normalize((_e5832 + _e820));
                    let _e6257 = clamp(dot(_e810, _e5832), 0f, 1f);
                    let _e6259 = clamp(dot(_e810, _e6255), 0f, 1f);
                    let _e6265 = (_e3295 + (_e3332 * pow((1f - clamp(dot(_e820, _e6255), 0f, 1f)), 5f)));
                    let _e6268 = (((_e6259 * _e6259) * _e3337) + 1f);
                    local_63 = (_e5800 + (((((vec3<f32>(1f, 1f, 1f) - _e6265) * _e3293) + ((_e6265 * ((_e3335 / ((3.1415927f * _e6268) * _e6268)) * (0.5f / max(((_e6257 * _e3347) + (_e3327 * sqrt((((_e6257 * _e6257) * _e3344) + _e3335)))), 0.00001f)))) * 3.1415927f)) * _e6257) * _e6253));
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e7934 = local_63;
                    phi_21649_ = _e7934;
                    phi_21515_ = (_e5802 + bitcast<u32>(1i));
                }
            }
            let _e7964 = local_66;
            phi_21720_ = _e7964;
        }
        let _e6293 = phi_21720_;
        phi_21716_ = _e6293;
    }
    let _e6295 = phi_21716_;
    let _e6298 = global_8.member_1[1u];
    let _e6302 = global_8.member_5;
    let _e6304 = textureSample(global_29, global_5, _e283);
    let _e6307 = global_26;
    let _e6312 = global_28[2u];
    let _e6316 = -(length(_e819));
    let _e6319 = global.member_7[3u];
    let _e6325 = global.member_9[3u];
    phi_21802_ = (1f - exp((_e6316 * _e6319)));
    if (_e6325 != 0f) {
        let _e6329 = (_e6325 * (_e818 - _e817).y);
        if (abs(_e6329) < 0.0001f) {
            phi_21799_ = (1f - (0.5f * _e6329));
        } else {
            phi_21799_ = ((1f - exp(min(-(_e6329), 60f))) / _e6329);
        }
        let _e6340 = phi_21799_;
        let _e6344 = global.member_6[1u];
        let _e6347 = global.member_6[3u];
        phi_21802_ = (1f - exp(((_e6316 * (_e6319 * exp(min((-(_e6325) * (_e6344 - _e6347)), 30f)))) * _e6340)));
    }
    let _e6358 = phi_21802_;
    let _e6360 = global.member_7;
    let _e6366 = global.member_34[2u];
    phi_21849_ = mix((mix(_e6295, _e1243, vec3(_e6298)) + (((_e6302.xyz * _e6304.xyz) * (vec3<f32>(1f, 1f, 1f) + _e6307.yzw)) * _e6312)), _e6360.xyz, vec3(_e6358));
    if (_e6366 > 0.5f) {
        let _e6370 = global.member_29[0u];
        if (_e6370 > 0.5f) {
            let _e6373 = global.member_29;
            let _e6380 = ((_e6373.z * _e810.x) - (_e6373.w * _e810.z));
            let _e6384 = ((_e6373.w * _e810.x) + (_e6373.z * _e810.z));
            let _e6388 = (1.092548f * _e6380);
            local = array<f32, 9>(0.282095f, (0.488603f * _e810.y), (0.488603f * _e6384), (0.488603f * _e6380), (_e6388 * _e810.y), ((1.092548f * _e810.y) * _e6384), (0.315392f * (((3f * _e6384) * _e6384) - 1f)), (_e6388 * _e6384), (0.546274f * ((_e6380 * _e6380) - (_e810.y * _e810.y))));
            phi_21812_ = vec3<f32>(0f, 0f, 0f);
            phi_21811_ = 0i;
            loop {
                let _e6403 = phi_21812_;
                let _e6405 = phi_21811_;
                local_54 = _e6403;
                if (_e6405 < 9i) {
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e6409 = textureLoad(global_4, (vec2<i32>(496i, 256i) + vec2<i32>(_e6405, 0i)), 0i);
                    let _e6412 = local[_e6405];
                    phi_21812_ = (_e6403 + (_e6409.xyz * _e6412));
                    phi_21811_ = (_e6405 + 1i);
                }
            }
            let _e6417 = local_54;
            let _e6421 = global.member_29[1u];
            phi_21813_ = (max(_e6417, vec3<f32>(0f, 0f, 0f)) * _e6421);
        } else {
            let _e6424 = global.member_9;
            let _e6427 = global.member_8;
            let _e6436 = global.member_8[3u];
            phi_21813_ = (mix(_e6424.xyz, _e6427.xyz, vec3(((_e810.y * 0.5f) + 0.5f))) * _e6436);
        }
        let _e6439 = phi_21813_;
        let _e6442 = global.member_34[1u];
        phi_21818_ = _e6439;
        if (_e6442 > 0.5f) {
            let _e6447 = global.member_34[0u];
            phi_21817_ = _e6439;
            phi_21816_ = 0i;
            loop {
                let _e6450 = phi_21817_;
                let _e6452 = phi_21816_;
                local_67 = _e6450;
                if (_e6452 < i32(_e6442)) {
                    let _e6455 = (8i * (i32(_e6447) + _e6452));
                    let _e6459 = global_3.member[(_e6455 + 3i)];
                    let _e6460 = bitcast<vec4<f32>>(_e6459);
                    let _e6463 = global_3.member[_e6455];
                    let _e6464 = bitcast<vec4<f32>>(_e6463);
                    let _e6468 = global_3.member[(_e6455 + 1i)];
                    let _e6469 = bitcast<vec4<f32>>(_e6468);
                    let _e6473 = global_3.member[(_e6455 + 2i)];
                    let _e6474 = bitcast<vec4<f32>>(_e6473);
                    let _e6475 = _e6464.xyz;
                    let _e6479 = _e6469.xyz;
                    let _e6483 = _e6474.xyz;
                    let _e6487 = vec3<f32>((dot(_e6475, _e818) + _e6464.w), (dot(_e6479, _e818) + _e6469.w), (dot(_e6483, _e818) + _e6474.w));
                    let _e6488 = _e6460.xyz;
                    switch bitcast<i32>(0u) {
                        default: {
                            let _e6492 = (_e6488 - abs(_e6487));
                            let _e6497 = min(_e6492.x, min(_e6492.y, _e6492.z));
                            if (_e6497 <= 0f) {
                                phi_21852_ = 0f;
                                break;
                            }
                            if (_e6460.w <= 0f) {
                                phi_21852_ = 1f;
                                break;
                            }
                            let _e6501 = min((_e6497 / _e6460.w), 1f);
                            phi_21852_ = ((_e6501 * _e6501) * (3f - (2f * _e6501)));
                            break;
                        }
                    }
                    let _e6507 = phi_21852_;
                    if (_e6507 <= 0f) {
                        phi_22020_ = _e6450;
                        continue;
                    }
                    let _e6512 = global_3.member[(_e6455 + 4i)];
                    let _e6514 = bitcast<vec4<f32>>(_e6512).xyz;
                    let _e6518 = global_3.member[(_e6455 + 5i)];
                    let _e6519 = bitcast<vec4<f32>>(_e6518);
                    let _e6524 = global_3.member[(_e6455 + 6i)][0u];
                    let _e6525 = bitcast<i32>(_e6524);
                    let _e6526 = dot(_e6475, _e810);
                    let _e6527 = dot(_e6479, _e810);
                    let _e6528 = dot(_e6483, _e810);
                    let _e6529 = vec3<f32>(_e6526, _e6527, _e6528);
                    let _e6535 = ((_e818 + (_e810 * _e6519.x)) + (_e820 * _e6519.y));
                    let _e6550 = clamp(((((vec3<f32>((dot(_e6475, _e6535) + _e6464.w), (dot(_e6479, _e6535) + _e6469.w), (dot(_e6483, _e6535) + _e6474.w)) + _e6488) / max((_e6488 * 2f), vec3<f32>(0.000001f, 0.000001f, 0.000001f))) * _e6514) - vec3<f32>(0.5f, 0.5f, 0.5f)), vec3<f32>(0f, 0f, 0f), (_e6514 - vec3<f32>(1f, 1f, 1f)));
                    let _e6551 = vec3<i32>(_e6514);
                    let _e6555 = min(vec3<i32>(_e6550), max((_e6551 - vec3<i32>(2i, 2i, 2i)), vec3<i32>(0i, 0i, 0i)));
                    let _e6557 = (_e6550 - vec3<f32>(_e6555));
                    let _e6558 = (0.488603f * _e6527);
                    let _e6559 = (0.488603f * _e6528);
                    let _e6560 = (0.488603f * _e6526);
                    let _e6561 = (1.092548f * _e6526);
                    let _e6562 = (_e6561 * _e6527);
                    let _e6564 = ((1.092548f * _e6527) * _e6528);
                    let _e6568 = (0.315392f * (((3f * _e6528) * _e6528) - 1f));
                    let _e6569 = (_e6561 * _e6528);
                    let _e6573 = (0.546274f * ((_e6526 * _e6526) - (_e6527 * _e6527)));
                    let _e6574 = (_e6551 - vec3<i32>(1i, 1i, 1i));
                    let _e6575 = min(_e6555, _e6574);
                    let _e6586 = (_e6525 + ((_e6575.x + (_e6551.x * (_e6575.y + (_e6551.y * _e6575.z)))) * 4i));
                    let _e6587 = (vec3<f32>(1f, 1f, 1f) - _e6557);
                    let _e6594 = ((((((vec3<f32>(_e6575) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e6514) * _e6488) * 2f) - _e6488) - _e6487);
                    let _e6600 = (dot((_e6594 * inverseSqrt(max(dot(_e6594, _e6594), 0.0000000001f))), _e6529) + 1f);
                    let _e6603 = (_e6587.x * _e6587.y);
                    let _e6610 = (_e6586 + 3i);
                    let _e6614 = global_3.member[_e6610][1u];
                    let _e6619 = (((_e6603 * _e6587.z) * ((0.25f * (_e6600 * _e6600)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e6614).y > 0.5f)));
                    let _e6622 = global_3.member[_e6586];
                    let _e6626 = global_3.member[(_e6586 + 1i)];
                    let _e6630 = global_3.member[(_e6586 + 2i)];
                    let _e6633 = global_3.member[_e6610];
                    let _e6635 = unpack2x16float(_e6622.x);
                    let _e6637 = unpack2x16float(_e6622.y);
                    let _e6639 = unpack2x16float(_e6622.z);
                    let _e6641 = unpack2x16float(_e6622.w);
                    let _e6643 = unpack2x16float(_e6626.x);
                    let _e6645 = unpack2x16float(_e6626.y);
                    let _e6647 = unpack2x16float(_e6626.z);
                    let _e6649 = unpack2x16float(_e6626.w);
                    let _e6651 = unpack2x16float(_e6630.x);
                    let _e6653 = unpack2x16float(_e6630.y);
                    let _e6655 = unpack2x16float(_e6630.z);
                    let _e6657 = unpack2x16float(_e6630.w);
                    let _e6659 = unpack2x16float(_e6633.x);
                    let _e6715 = ((((((((((vec3<f32>(_e6635.x, _e6635.y, _e6637.x) * 0.282095f) + (vec3<f32>(_e6637.y, _e6639.x, _e6639.y) * _e6558)) + (vec3<f32>(_e6641.x, _e6641.y, _e6643.x) * _e6559)) + (vec3<f32>(_e6643.y, _e6645.x, _e6645.y) * _e6560)) + (vec3<f32>(_e6647.x, _e6647.y, _e6649.x) * _e6562)) + (vec3<f32>(_e6649.y, _e6651.x, _e6651.y) * _e6564)) + (vec3<f32>(_e6653.x, _e6653.y, _e6655.x) * _e6568)) + (vec3<f32>(_e6655.y, _e6657.x, _e6657.y) * _e6569)) + (vec3<f32>(_e6659.x, _e6659.y, unpack2x16float(_e6633.y).x) * _e6573)) * _e6619);
                    let _e6721 = min((_e6555 + vec3<i32>(1i, 0i, 0i)), _e6574);
                    let _e6730 = (_e6525 + ((_e6721.x + (_e6551.x * (_e6721.y + (_e6551.y * _e6721.z)))) * 4i));
                    let _e6737 = ((((((vec3<f32>(_e6721) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e6514) * _e6488) * 2f) - _e6488) - _e6487);
                    let _e6743 = (dot((_e6737 * inverseSqrt(max(dot(_e6737, _e6737), 0.0000000001f))), _e6529) + 1f);
                    let _e6745 = (_e6557.x * _e6587.y);
                    let _e6751 = (_e6730 + 3i);
                    let _e6755 = global_3.member[_e6751][1u];
                    let _e6760 = (((_e6745 * _e6587.z) * ((0.25f * (_e6743 * _e6743)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e6755).y > 0.5f)));
                    let _e6763 = global_3.member[_e6730];
                    let _e6767 = global_3.member[(_e6730 + 1i)];
                    let _e6771 = global_3.member[(_e6730 + 2i)];
                    let _e6774 = global_3.member[_e6751];
                    let _e6776 = unpack2x16float(_e6763.x);
                    let _e6778 = unpack2x16float(_e6763.y);
                    let _e6780 = unpack2x16float(_e6763.z);
                    let _e6782 = unpack2x16float(_e6763.w);
                    let _e6784 = unpack2x16float(_e6767.x);
                    let _e6786 = unpack2x16float(_e6767.y);
                    let _e6788 = unpack2x16float(_e6767.z);
                    let _e6790 = unpack2x16float(_e6767.w);
                    let _e6792 = unpack2x16float(_e6771.x);
                    let _e6794 = unpack2x16float(_e6771.y);
                    let _e6796 = unpack2x16float(_e6771.z);
                    let _e6798 = unpack2x16float(_e6771.w);
                    let _e6800 = unpack2x16float(_e6774.x);
                    let _e6856 = ((((((((((vec3<f32>(_e6776.x, _e6776.y, _e6778.x) * 0.282095f) + (vec3<f32>(_e6778.y, _e6780.x, _e6780.y) * _e6558)) + (vec3<f32>(_e6782.x, _e6782.y, _e6784.x) * _e6559)) + (vec3<f32>(_e6784.y, _e6786.x, _e6786.y) * _e6560)) + (vec3<f32>(_e6788.x, _e6788.y, _e6790.x) * _e6562)) + (vec3<f32>(_e6790.y, _e6792.x, _e6792.y) * _e6564)) + (vec3<f32>(_e6794.x, _e6794.y, _e6796.x) * _e6568)) + (vec3<f32>(_e6796.y, _e6798.x, _e6798.y) * _e6569)) + (vec3<f32>(_e6800.x, _e6800.y, unpack2x16float(_e6774.y).x) * _e6573)) * _e6760);
                    let _e6863 = min((_e6555 + vec3<i32>(0i, 1i, 0i)), _e6574);
                    let _e6872 = (_e6525 + ((_e6863.x + (_e6551.x * (_e6863.y + (_e6551.y * _e6863.z)))) * 4i));
                    let _e6879 = ((((((vec3<f32>(_e6863) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e6514) * _e6488) * 2f) - _e6488) - _e6487);
                    let _e6885 = (dot((_e6879 * inverseSqrt(max(dot(_e6879, _e6879), 0.0000000001f))), _e6529) + 1f);
                    let _e6887 = (_e6587.x * _e6557.y);
                    let _e6893 = (_e6872 + 3i);
                    let _e6897 = global_3.member[_e6893][1u];
                    let _e6902 = (((_e6887 * _e6587.z) * ((0.25f * (_e6885 * _e6885)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e6897).y > 0.5f)));
                    let _e6905 = global_3.member[_e6872];
                    let _e6909 = global_3.member[(_e6872 + 1i)];
                    let _e6913 = global_3.member[(_e6872 + 2i)];
                    let _e6916 = global_3.member[_e6893];
                    let _e6918 = unpack2x16float(_e6905.x);
                    let _e6920 = unpack2x16float(_e6905.y);
                    let _e6922 = unpack2x16float(_e6905.z);
                    let _e6924 = unpack2x16float(_e6905.w);
                    let _e6926 = unpack2x16float(_e6909.x);
                    let _e6928 = unpack2x16float(_e6909.y);
                    let _e6930 = unpack2x16float(_e6909.z);
                    let _e6932 = unpack2x16float(_e6909.w);
                    let _e6934 = unpack2x16float(_e6913.x);
                    let _e6936 = unpack2x16float(_e6913.y);
                    let _e6938 = unpack2x16float(_e6913.z);
                    let _e6940 = unpack2x16float(_e6913.w);
                    let _e6942 = unpack2x16float(_e6916.x);
                    let _e6998 = ((((((((((vec3<f32>(_e6918.x, _e6918.y, _e6920.x) * 0.282095f) + (vec3<f32>(_e6920.y, _e6922.x, _e6922.y) * _e6558)) + (vec3<f32>(_e6924.x, _e6924.y, _e6926.x) * _e6559)) + (vec3<f32>(_e6926.y, _e6928.x, _e6928.y) * _e6560)) + (vec3<f32>(_e6930.x, _e6930.y, _e6932.x) * _e6562)) + (vec3<f32>(_e6932.y, _e6934.x, _e6934.y) * _e6564)) + (vec3<f32>(_e6936.x, _e6936.y, _e6938.x) * _e6568)) + (vec3<f32>(_e6938.y, _e6940.x, _e6940.y) * _e6569)) + (vec3<f32>(_e6942.x, _e6942.y, unpack2x16float(_e6916.y).x) * _e6573)) * _e6902);
                    let _e7005 = min((_e6555 + vec3<i32>(1i, 1i, 0i)), _e6574);
                    let _e7014 = (_e6525 + ((_e7005.x + (_e6551.x * (_e7005.y + (_e6551.y * _e7005.z)))) * 4i));
                    let _e7021 = ((((((vec3<f32>(_e7005) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e6514) * _e6488) * 2f) - _e6488) - _e6487);
                    let _e7027 = (dot((_e7021 * inverseSqrt(max(dot(_e7021, _e7021), 0.0000000001f))), _e6529) + 1f);
                    let _e7028 = (_e6557.x * _e6557.y);
                    let _e7034 = (_e7014 + 3i);
                    let _e7038 = global_3.member[_e7034][1u];
                    let _e7043 = (((_e7028 * _e6587.z) * ((0.25f * (_e7027 * _e7027)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e7038).y > 0.5f)));
                    let _e7046 = global_3.member[_e7014];
                    let _e7050 = global_3.member[(_e7014 + 1i)];
                    let _e7054 = global_3.member[(_e7014 + 2i)];
                    let _e7057 = global_3.member[_e7034];
                    let _e7059 = unpack2x16float(_e7046.x);
                    let _e7061 = unpack2x16float(_e7046.y);
                    let _e7063 = unpack2x16float(_e7046.z);
                    let _e7065 = unpack2x16float(_e7046.w);
                    let _e7067 = unpack2x16float(_e7050.x);
                    let _e7069 = unpack2x16float(_e7050.y);
                    let _e7071 = unpack2x16float(_e7050.z);
                    let _e7073 = unpack2x16float(_e7050.w);
                    let _e7075 = unpack2x16float(_e7054.x);
                    let _e7077 = unpack2x16float(_e7054.y);
                    let _e7079 = unpack2x16float(_e7054.z);
                    let _e7081 = unpack2x16float(_e7054.w);
                    let _e7083 = unpack2x16float(_e7057.x);
                    let _e7139 = ((((((((((vec3<f32>(_e7059.x, _e7059.y, _e7061.x) * 0.282095f) + (vec3<f32>(_e7061.y, _e7063.x, _e7063.y) * _e6558)) + (vec3<f32>(_e7065.x, _e7065.y, _e7067.x) * _e6559)) + (vec3<f32>(_e7067.y, _e7069.x, _e7069.y) * _e6560)) + (vec3<f32>(_e7071.x, _e7071.y, _e7073.x) * _e6562)) + (vec3<f32>(_e7073.y, _e7075.x, _e7075.y) * _e6564)) + (vec3<f32>(_e7077.x, _e7077.y, _e7079.x) * _e6568)) + (vec3<f32>(_e7079.y, _e7081.x, _e7081.y) * _e6569)) + (vec3<f32>(_e7083.x, _e7083.y, unpack2x16float(_e7057.y).x) * _e6573)) * _e7043);
                    let _e7146 = min((_e6555 + vec3<i32>(0i, 0i, 1i)), _e6574);
                    let _e7155 = (_e6525 + ((_e7146.x + (_e6551.x * (_e7146.y + (_e6551.y * _e7146.z)))) * 4i));
                    let _e7162 = ((((((vec3<f32>(_e7146) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e6514) * _e6488) * 2f) - _e6488) - _e6487);
                    let _e7168 = (dot((_e7162 * inverseSqrt(max(dot(_e7162, _e7162), 0.0000000001f))), _e6529) + 1f);
                    let _e7175 = (_e7155 + 3i);
                    let _e7179 = global_3.member[_e7175][1u];
                    let _e7184 = (((_e6603 * _e6557.z) * ((0.25f * (_e7168 * _e7168)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e7179).y > 0.5f)));
                    let _e7187 = global_3.member[_e7155];
                    let _e7191 = global_3.member[(_e7155 + 1i)];
                    let _e7195 = global_3.member[(_e7155 + 2i)];
                    let _e7198 = global_3.member[_e7175];
                    let _e7200 = unpack2x16float(_e7187.x);
                    let _e7202 = unpack2x16float(_e7187.y);
                    let _e7204 = unpack2x16float(_e7187.z);
                    let _e7206 = unpack2x16float(_e7187.w);
                    let _e7208 = unpack2x16float(_e7191.x);
                    let _e7210 = unpack2x16float(_e7191.y);
                    let _e7212 = unpack2x16float(_e7191.z);
                    let _e7214 = unpack2x16float(_e7191.w);
                    let _e7216 = unpack2x16float(_e7195.x);
                    let _e7218 = unpack2x16float(_e7195.y);
                    let _e7220 = unpack2x16float(_e7195.z);
                    let _e7222 = unpack2x16float(_e7195.w);
                    let _e7224 = unpack2x16float(_e7198.x);
                    let _e7280 = ((((((((((vec3<f32>(_e7200.x, _e7200.y, _e7202.x) * 0.282095f) + (vec3<f32>(_e7202.y, _e7204.x, _e7204.y) * _e6558)) + (vec3<f32>(_e7206.x, _e7206.y, _e7208.x) * _e6559)) + (vec3<f32>(_e7208.y, _e7210.x, _e7210.y) * _e6560)) + (vec3<f32>(_e7212.x, _e7212.y, _e7214.x) * _e6562)) + (vec3<f32>(_e7214.y, _e7216.x, _e7216.y) * _e6564)) + (vec3<f32>(_e7218.x, _e7218.y, _e7220.x) * _e6568)) + (vec3<f32>(_e7220.y, _e7222.x, _e7222.y) * _e6569)) + (vec3<f32>(_e7224.x, _e7224.y, unpack2x16float(_e7198.y).x) * _e6573)) * _e7184);
                    let _e7287 = min((_e6555 + vec3<i32>(1i, 0i, 1i)), _e6574);
                    let _e7296 = (_e6525 + ((_e7287.x + (_e6551.x * (_e7287.y + (_e6551.y * _e7287.z)))) * 4i));
                    let _e7303 = ((((((vec3<f32>(_e7287) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e6514) * _e6488) * 2f) - _e6488) - _e6487);
                    let _e7309 = (dot((_e7303 * inverseSqrt(max(dot(_e7303, _e7303), 0.0000000001f))), _e6529) + 1f);
                    let _e7315 = (_e7296 + 3i);
                    let _e7319 = global_3.member[_e7315][1u];
                    let _e7324 = (((_e6745 * _e6557.z) * ((0.25f * (_e7309 * _e7309)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e7319).y > 0.5f)));
                    let _e7327 = global_3.member[_e7296];
                    let _e7331 = global_3.member[(_e7296 + 1i)];
                    let _e7335 = global_3.member[(_e7296 + 2i)];
                    let _e7338 = global_3.member[_e7315];
                    let _e7340 = unpack2x16float(_e7327.x);
                    let _e7342 = unpack2x16float(_e7327.y);
                    let _e7344 = unpack2x16float(_e7327.z);
                    let _e7346 = unpack2x16float(_e7327.w);
                    let _e7348 = unpack2x16float(_e7331.x);
                    let _e7350 = unpack2x16float(_e7331.y);
                    let _e7352 = unpack2x16float(_e7331.z);
                    let _e7354 = unpack2x16float(_e7331.w);
                    let _e7356 = unpack2x16float(_e7335.x);
                    let _e7358 = unpack2x16float(_e7335.y);
                    let _e7360 = unpack2x16float(_e7335.z);
                    let _e7362 = unpack2x16float(_e7335.w);
                    let _e7364 = unpack2x16float(_e7338.x);
                    let _e7420 = ((((((((((vec3<f32>(_e7340.x, _e7340.y, _e7342.x) * 0.282095f) + (vec3<f32>(_e7342.y, _e7344.x, _e7344.y) * _e6558)) + (vec3<f32>(_e7346.x, _e7346.y, _e7348.x) * _e6559)) + (vec3<f32>(_e7348.y, _e7350.x, _e7350.y) * _e6560)) + (vec3<f32>(_e7352.x, _e7352.y, _e7354.x) * _e6562)) + (vec3<f32>(_e7354.y, _e7356.x, _e7356.y) * _e6564)) + (vec3<f32>(_e7358.x, _e7358.y, _e7360.x) * _e6568)) + (vec3<f32>(_e7360.y, _e7362.x, _e7362.y) * _e6569)) + (vec3<f32>(_e7364.x, _e7364.y, unpack2x16float(_e7338.y).x) * _e6573)) * _e7324);
                    let _e7427 = min((_e6555 + vec3<i32>(0i, 1i, 1i)), _e6574);
                    let _e7436 = (_e6525 + ((_e7427.x + (_e6551.x * (_e7427.y + (_e6551.y * _e7427.z)))) * 4i));
                    let _e7443 = ((((((vec3<f32>(_e7427) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e6514) * _e6488) * 2f) - _e6488) - _e6487);
                    let _e7449 = (dot((_e7443 * inverseSqrt(max(dot(_e7443, _e7443), 0.0000000001f))), _e6529) + 1f);
                    let _e7455 = (_e7436 + 3i);
                    let _e7459 = global_3.member[_e7455][1u];
                    let _e7464 = (((_e6887 * _e6557.z) * ((0.25f * (_e7449 * _e7449)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e7459).y > 0.5f)));
                    let _e7467 = global_3.member[_e7436];
                    let _e7471 = global_3.member[(_e7436 + 1i)];
                    let _e7475 = global_3.member[(_e7436 + 2i)];
                    let _e7478 = global_3.member[_e7455];
                    let _e7480 = unpack2x16float(_e7467.x);
                    let _e7482 = unpack2x16float(_e7467.y);
                    let _e7484 = unpack2x16float(_e7467.z);
                    let _e7486 = unpack2x16float(_e7467.w);
                    let _e7488 = unpack2x16float(_e7471.x);
                    let _e7490 = unpack2x16float(_e7471.y);
                    let _e7492 = unpack2x16float(_e7471.z);
                    let _e7494 = unpack2x16float(_e7471.w);
                    let _e7496 = unpack2x16float(_e7475.x);
                    let _e7498 = unpack2x16float(_e7475.y);
                    let _e7500 = unpack2x16float(_e7475.z);
                    let _e7502 = unpack2x16float(_e7475.w);
                    let _e7504 = unpack2x16float(_e7478.x);
                    let _e7560 = ((((((((((vec3<f32>(_e7480.x, _e7480.y, _e7482.x) * 0.282095f) + (vec3<f32>(_e7482.y, _e7484.x, _e7484.y) * _e6558)) + (vec3<f32>(_e7486.x, _e7486.y, _e7488.x) * _e6559)) + (vec3<f32>(_e7488.y, _e7490.x, _e7490.y) * _e6560)) + (vec3<f32>(_e7492.x, _e7492.y, _e7494.x) * _e6562)) + (vec3<f32>(_e7494.y, _e7496.x, _e7496.y) * _e6564)) + (vec3<f32>(_e7498.x, _e7498.y, _e7500.x) * _e6568)) + (vec3<f32>(_e7500.y, _e7502.x, _e7502.y) * _e6569)) + (vec3<f32>(_e7504.x, _e7504.y, unpack2x16float(_e7478.y).x) * _e6573)) * _e7464);
                    let _e7567 = min((_e6555 + vec3<i32>(1i, 1i, 1i)), _e6574);
                    let _e7576 = (_e6525 + ((_e7567.x + (_e6551.x * (_e7567.y + (_e6551.y * _e7567.z)))) * 4i));
                    let _e7583 = ((((((vec3<f32>(_e7567) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e6514) * _e6488) * 2f) - _e6488) - _e6487);
                    let _e7589 = (dot((_e7583 * inverseSqrt(max(dot(_e7583, _e7583), 0.0000000001f))), _e6529) + 1f);
                    let _e7595 = (_e7576 + 3i);
                    let _e7599 = global_3.member[_e7595][1u];
                    let _e7604 = (((_e7028 * _e6557.z) * ((0.25f * (_e7589 * _e7589)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e7599).y > 0.5f)));
                    let _e7607 = global_3.member[_e7576];
                    let _e7611 = global_3.member[(_e7576 + 1i)];
                    let _e7615 = global_3.member[(_e7576 + 2i)];
                    let _e7618 = global_3.member[_e7595];
                    let _e7620 = unpack2x16float(_e7607.x);
                    let _e7622 = unpack2x16float(_e7607.y);
                    let _e7624 = unpack2x16float(_e7607.z);
                    let _e7626 = unpack2x16float(_e7607.w);
                    let _e7628 = unpack2x16float(_e7611.x);
                    let _e7630 = unpack2x16float(_e7611.y);
                    let _e7632 = unpack2x16float(_e7611.z);
                    let _e7634 = unpack2x16float(_e7611.w);
                    let _e7636 = unpack2x16float(_e7615.x);
                    let _e7638 = unpack2x16float(_e7615.y);
                    let _e7640 = unpack2x16float(_e7615.z);
                    let _e7642 = unpack2x16float(_e7615.w);
                    let _e7644 = unpack2x16float(_e7618.x);
                    let _e7700 = ((((((((((vec3<f32>(_e7620.x, _e7620.y, _e7622.x) * 0.282095f) + (vec3<f32>(_e7622.y, _e7624.x, _e7624.y) * _e6558)) + (vec3<f32>(_e7626.x, _e7626.y, _e7628.x) * _e6559)) + (vec3<f32>(_e7628.y, _e7630.x, _e7630.y) * _e6560)) + (vec3<f32>(_e7632.x, _e7632.y, _e7634.x) * _e6562)) + (vec3<f32>(_e7634.y, _e7636.x, _e7636.y) * _e6564)) + (vec3<f32>(_e7638.x, _e7638.y, _e7640.x) * _e6568)) + (vec3<f32>(_e7640.y, _e7642.x, _e7642.y) * _e6569)) + (vec3<f32>(_e7644.x, _e7644.y, unpack2x16float(_e7618.y).x) * _e6573)) * _e7604);
                    let _e7705 = (((((((vec4<f32>(_e6715.x, _e6715.y, _e6715.z, _e6619) + vec4<f32>(_e6856.x, _e6856.y, _e6856.z, _e6760)) + vec4<f32>(_e6998.x, _e6998.y, _e6998.z, _e6902)) + vec4<f32>(_e7139.x, _e7139.y, _e7139.z, _e7043)) + vec4<f32>(_e7280.x, _e7280.y, _e7280.z, _e7184)) + vec4<f32>(_e7420.x, _e7420.y, _e7420.z, _e7324)) + vec4<f32>(_e7560.x, _e7560.y, _e7560.z, _e7464)) + vec4<f32>(_e7700.x, _e7700.y, _e7700.z, _e7604));
                    phi_22021_ = _e6450;
                    if (_e7705.w > 0.00001f) {
                        phi_22021_ = mix(_e6450, ((max(_e7705.xyz, vec3<f32>(0f, 0f, 0f)) / vec3(_e7705.w)) * _e6519.z), vec3(_e6507));
                    }
                    let _e7717 = phi_22021_;
                    phi_22020_ = _e7717;
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e7719 = phi_22020_;
                    phi_21817_ = _e7719;
                    phi_21816_ = (_e6452 + 1i);
                }
            }
            let _e7979 = local_67;
            phi_21818_ = _e7979;
        }
        let _e7722 = phi_21818_;
        phi_21849_ = (_e7722 * _e1272);
    }
    let _e7725 = phi_21849_;
    let _e7728 = global.member_33[3u];
    phi_21850_ = _e7725;
    if (_e7728 > 0.5f) {
        phi_21850_ = (_e7725 / (vec3<f32>(1f, 1f, 1f) + _e7725));
    }
    let _e7733 = phi_21850_;
    global_30 = vec4<f32>(_e7733.x, _e7733.y, _e7733.z, (((_e294 * _e297) * _e284.w) * _e305));
    let _e7738 = global_32;
    let _e7739 = global_33;
    switch bitcast<i32>(0u) {
        default: {
            if (_e7739.w <= 0f) {
                phi_21851_ = vec2<f32>(0f, 0f);
                break;
            }
            phi_21851_ = (((_e7739.xy / vec2(_e7739.w)) - (_e7738.xy / vec2(_e7738.w))) * vec2<f32>(0.5f, -0.5f));
            break;
        }
    }
    let _e7753 = phi_21851_;
    global_31 = _e7753;
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
