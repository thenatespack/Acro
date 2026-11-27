// Generated from mesh_probes.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: 1e6ed52dc75687a3
// glsl-fnv1a64: dc6b24bfa5314702

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
@group(2) @binding(11) 
var global_23: texture_2d<f32>;
var<private> global_24: bool;
var<private> global_25: vec4<f32>;
@group(2) @binding(10) 
var global_26: texture_2d<f32>;
@group(2) @binding(13) 
var global_27: texture_2d<f32>;
var<private> global_28: vec4<f32>;
var<private> global_29: vec2<f32>;
var<private> global_30: vec4<f32>;
var<private> global_31: vec4<f32>;

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
    var phi_20823_: vec3<f32>;
    var phi_20821_: f32;
    var local_28: vec3<f32>;
    var phi_20984_: vec2<f32>;
    var phi_20951_: f32;
    var phi_20920_: vec3<f32>;
    var phi_20824_: vec2<f32>;
    var phi_20825_: vec3<f32>;
    var phi_20834_: vec3<f32>;
    var phi_20833_: vec3<f32>;
    var phi_20830_: f32;
    var phi_3625_: bool;
    var phi_21020_: vec3<f32>;
    var phi_20835_: i32;
    var phi_5399_: bool;
    var local_29: i32;
    var local_30: i32;
    var local_31: i32;
    var phi_5512_: bool;
    var phi_5519_: bool;
    var phi_5526_: bool;
    var local_32: i32;
    var local_33: i32;
    var local_34: i32;
    var phi_20840_: f32;
    var phi_20837_: i32;
    var phi_20846_: f32;
    var phi_20843_: i32;
    var local_35: f32;
    var phi_20847_: f32;
    var phi_20848_: f32;
    var local_36: i32;
    var local_37: i32;
    var local_38: i32;
    var phi_5799_: bool;
    var phi_5806_: bool;
    var phi_5813_: bool;
    var phi_20860_: f32;
    var phi_20857_: i32;
    var phi_20866_: f32;
    var phi_20863_: i32;
    var local_39: f32;
    var phi_20867_: f32;
    var phi_20868_: f32;
    var phi_20889_: f32;
    var phi_20886_: vec3<f32>;
    var phi_20888_: f32;
    var phi_20885_: vec3<f32>;
    var phi_20891_: vec3<f32>;
    var phi_20890_: f32;
    var phi_21054_: f32;
    var phi_21014_: vec3<f32>;
    var phi_20943_: f32;
    var phi_21144_: f32;
    var phi_21671_: vec3<f32>;
    var phi_21670_: i32;
    var local_40: vec3<f32>;
    var phi_21672_: vec3<f32>;
    var phi_21682_: vec3<f32>;
    var phi_21681_: i32;
    var local_41: vec3<f32>;
    var phi_21683_: vec3<f32>;
    var phi_21689_: vec3<f32>;
    var phi_21688_: i32;
    var phi_21950_: f32;
    var phi_21988_: vec3<f32>;
    var phi_21987_: vec3<f32>;
    var local_42: vec3<f32>;
    var phi_21699_: vec3<f32>;
    var phi_21700_: vec3<f32>;
    var phi_21696_: u32;
    var phi_9364_: bool;
    var phi_9371_: bool;
    var phi_9378_: bool;
    var phi_9385_: bool;
    var phi_21856_: f32;
    var phi_21853_: i32;
    var phi_21862_: f32;
    var phi_21859_: i32;
    var local_43: f32;
    var phi_21863_: f32;
    var phi_9455_: bool;
    var phi_21841_: i32;
    var phi_21840_: i32;
    var phi_21838_: f32;
    var phi_21845_: f32;
    var phi_21842_: i32;
    var phi_21851_: f32;
    var phi_21848_: i32;
    var local_44: f32;
    var phi_21852_: f32;
    var phi_21864_: f32;
    var phi_21915_: vec3<f32>;
    var phi_21698_: vec3<f32>;
    var phi_21015_: f32;
    var phi_21010_: f32;
    var phi_21044_: vec3<f32>;
    var phi_21043_: vec3<f32>;
    var phi_21048_: f32;
    var phi_21047_: f32;
    var phi_21158_: vec3<f32>;
    var phi_21066_: vec3<f32>;
    var phi_21065_: i32;
    var local_45: vec3<f32>;
    var phi_21069_: i32;
    var phi_21070_: i32;
    var phi_21076_: i32;
    var phi_21077_: i32;
    var phi_21120_: vec3<f32>;
    var phi_21108_: vec2<f32>;
    var phi_21084_: vec3<f32>;
    var phi_4136_: bool;
    var phi_21104_: f32;
    var phi_21103_: vec3<f32>;
    var phi_21102_: i32;
    var local_46: vec3<f32>;
    var local_47: f32;
    var phi_21105_: vec3<f32>;
    var phi_21129_: vec3<f32>;
    var phi_21165_: vec3<f32>;
    var phi_21164_: i32;
    var phi_21665_: f32;
    var phi_21958_: vec3<f32>;
    var phi_21957_: vec3<f32>;
    var phi_21166_: vec3<f32>;
    var phi_21189_: i32;
    var phi_21190_: i32;
    var phi_21196_: i32;
    var phi_21197_: i32;
    var phi_21203_: vec3<f32>;
    var phi_21285_: vec3<f32>;
    var phi_21219_: f32;
    var phi_21218_: i32;
    var phi_21220_: f32;
    var phi_21221_: vec3<f32>;
    var phi_21222_: vec3<f32>;
    var phi_21223_: i32;
    var phi_21224_: i32;
    var phi_21230_: vec2<u32>;
    var phi_21232_: vec2<u32>;
    var phi_21235_: vec2<u32>;
    var phi_21236_: vec2<u32>;
    var phi_21237_: i32;
    var phi_21238_: i32;
    var phi_21244_: vec2<u32>;
    var phi_21246_: vec2<u32>;
    var phi_21249_: vec2<u32>;
    var phi_21250_: vec2<u32>;
    var phi_21972_: vec3<f32>;
    var phi_21971_: f32;
    var local_48: f32;
    var local_49: vec3<f32>;
    var phi_4254_: bool;
    var phi_21360_: f32;
    var phi_21359_: vec3<f32>;
    var phi_21358_: i32;
    var local_50: vec3<f32>;
    var local_51: f32;
    var phi_21361_: vec3<f32>;
    var phi_21395_: vec3<f32>;
    var phi_21394_: vec3<f32>;
    var phi_21631_: vec3<f32>;
    var phi_21630_: vec3<f32>;
    var phi_21496_: u32;
    var phi_15341_: bool;
    var phi_15348_: bool;
    var phi_15355_: bool;
    var phi_15362_: bool;
    var phi_21515_: f32;
    var phi_21512_: i32;
    var phi_21521_: f32;
    var phi_21518_: i32;
    var local_52: f32;
    var phi_21522_: f32;
    var phi_15432_: bool;
    var phi_21500_: i32;
    var phi_21499_: i32;
    var phi_21497_: f32;
    var phi_21504_: f32;
    var phi_21501_: i32;
    var phi_21510_: f32;
    var phi_21507_: i32;
    var local_53: f32;
    var phi_21511_: f32;
    var phi_21523_: f32;
    var phi_21628_: vec3<f32>;
    var phi_21701_: vec3<f32>;
    var phi_21697_: vec3<f32>;
    var phi_21780_: f32;
    var phi_21783_: f32;
    var phi_21793_: vec3<f32>;
    var phi_21792_: i32;
    var local_54: vec3<f32>;
    var phi_21794_: vec3<f32>;
    var phi_21798_: vec3<f32>;
    var phi_21797_: i32;
    var phi_21833_: f32;
    var phi_22002_: vec3<f32>;
    var phi_22001_: vec3<f32>;
    var phi_21799_: vec3<f32>;
    var phi_21830_: vec3<f32>;
    var phi_21831_: vec3<f32>;
    var phi_21832_: vec2<f32>;
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

    let _e265 = global_8.member_2;
    let _e267 = global_20;
    let _e271 = global_8.member_2[2u];
    let _e274 = global_8.member_3;
    let _e279 = global_8.member_3[2u];
    let _e281 = vec2<f32>((dot(_e265.xy, _e267) + _e271), (dot(_e274.xy, _e267) + _e279));
    let _e282 = textureSample(global_21, global_5, _e281);
    let _e283 = global_22;
    let _e284 = _e283.xyz;
    let _e286 = global_8.member;
    let _e289 = _e282.xyz;
    let _e290 = ((_e284 * _e286.xyz) * _e289);
    let _e292 = global_22[3u];
    let _e295 = global_8.member[3u];
    let _e301 = global_8.member_1[0u];
    phi_20823_ = _e290;
    if (_e301 > 0.5f) {
        let _e303 = global_13;
        let _e306 = floor((_e303.xz * vec2<f32>(0.5f, 0.5f)));
        let _e310 = abs((_e306.x + _e306.y));
        phi_20823_ = (_e290 * select(0.75f, 1f, ((_e310 - (floor((_e310 / 2f)) * 2f)) < 0.5f)));
    }
    let _e319 = phi_20823_;
    let _e322 = global_8.member_3[3u];
    phi_20984_ = vec2<f32>(0f, 0f);
    phi_20951_ = 0f;
    phi_20920_ = _e319;
    if (_e322 > 0.5f) {
        switch bitcast<i32>(0u) {
            default: {
                let _e327 = global_8.member_2[3u];
                let _e329 = vec4<f32>(_e327, _e322, 0f, 0f).xyy;
                let _e331 = floor((_e329 * vec3<f32>(0.000015258789f, 0.000015258789f, 0.000015258789f)));
                let _e333 = (_e329 - (_e331 * 65536f));
                let _e335 = floor((_e333 * vec3<f32>(0.00390625f, 0.00390625f, 0.00390625f)));
                let _e337 = (_e333 - (_e335 * 256f));
                let _e349 = (_e331.y - 128f);
                let _e356 = (floor((_e349 * 0.03125f)) * 0.33333334f);
                let _e360 = global_9;
                let _e361 = normalize(_e360);
                let _e362 = global_10;
                let _e363 = _e362.xyz;
                let _e364 = dot(_e361, _e363);
                let _e370 = ((_e364 / max(length((_e363 - (_e361 * _e364))), 0.000001f)) * 25.5f);
                local_28 = ((vec3<f32>(_e337.x, _e335.x, _e331.x) * vec3<f32>(0.003921569f, 0.003921569f, 0.003921569f)) * 2f);
                local_55 = (vec2<f32>(_e337.y, _e335.y) * vec2<f32>(0.003921569f, 0.003921569f));
                if ((-24f + _e370) < -2f) {
                    phi_20821_ = 0f;
                    break;
                }
                let _e373 = global_11;
                let _e374 = (_e373 * (4f * exp2(((_e349 - (floor((_e349 / 32f)) * 32f)) * 0.33333334f))));
                let _e375 = floor(_e374);
                let _e376 = (_e374 - _e375);
                let _e380 = ((_e376 * _e376) * (vec3<f32>(3f, 3f, 3f) - (_e376 * 2f)));
                let _e382 = bitcast<vec3<u32>>(vec3<i32>(_e375));
                let _e391 = ((((_e382.x * 1597334677u) ^ (_e382.y * 3812015801u)) ^ (_e382.z * 2798796415u)) * 1597334677u);
                let _e400 = bitcast<vec3<u32>>(vec3<i32>((_e375 + vec3<f32>(1f, 0f, 0f))));
                let _e409 = ((((_e400.x * 1597334677u) ^ (_e400.y * 3812015801u)) ^ (_e400.z * 2798796415u)) * 1597334677u);
                let _e420 = bitcast<vec3<u32>>(vec3<i32>((_e375 + vec3<f32>(0f, 1f, 0f))));
                let _e429 = ((((_e420.x * 1597334677u) ^ (_e420.y * 3812015801u)) ^ (_e420.z * 2798796415u)) * 1597334677u);
                let _e438 = bitcast<vec3<u32>>(vec3<i32>((_e375 + vec3<f32>(1f, 1f, 0f))));
                let _e447 = ((((_e438.x * 1597334677u) ^ (_e438.y * 3812015801u)) ^ (_e438.z * 2798796415u)) * 1597334677u);
                let _e459 = bitcast<vec3<u32>>(vec3<i32>((_e375 + vec3<f32>(0f, 0f, 1f))));
                let _e468 = ((((_e459.x * 1597334677u) ^ (_e459.y * 3812015801u)) ^ (_e459.z * 2798796415u)) * 1597334677u);
                let _e477 = bitcast<vec3<u32>>(vec3<i32>((_e375 + vec3<f32>(1f, 0f, 1f))));
                let _e486 = ((((_e477.x * 1597334677u) ^ (_e477.y * 3812015801u)) ^ (_e477.z * 2798796415u)) * 1597334677u);
                let _e496 = bitcast<vec3<u32>>(vec3<i32>((_e375 + vec3<f32>(0f, 1f, 1f))));
                let _e505 = ((((_e496.x * 1597334677u) ^ (_e496.y * 3812015801u)) ^ (_e496.z * 2798796415u)) * 1597334677u);
                let _e514 = bitcast<vec3<u32>>(vec3<i32>((_e375 + vec3<f32>(1f, 1f, 1f))));
                let _e523 = ((((_e514.x * 1597334677u) ^ (_e514.y * 3812015801u)) ^ (_e514.z * 2798796415u)) * 1597334677u);
                let _e536 = ((_e374 * 2.7f) + vec3<f32>(17.3f, 5.1f, 9.7f));
                let _e537 = floor(_e536);
                let _e538 = (_e536 - _e537);
                let _e542 = ((_e538 * _e538) * (vec3<f32>(3f, 3f, 3f) - (_e538 * 2f)));
                let _e544 = bitcast<vec3<u32>>(vec3<i32>(_e537));
                let _e553 = ((((_e544.x * 1597334677u) ^ (_e544.y * 3812015801u)) ^ (_e544.z * 2798796415u)) * 1597334677u);
                let _e562 = bitcast<vec3<u32>>(vec3<i32>((_e537 + vec3<f32>(1f, 0f, 0f))));
                let _e571 = ((((_e562.x * 1597334677u) ^ (_e562.y * 3812015801u)) ^ (_e562.z * 2798796415u)) * 1597334677u);
                let _e582 = bitcast<vec3<u32>>(vec3<i32>((_e537 + vec3<f32>(0f, 1f, 0f))));
                let _e591 = ((((_e582.x * 1597334677u) ^ (_e582.y * 3812015801u)) ^ (_e582.z * 2798796415u)) * 1597334677u);
                let _e600 = bitcast<vec3<u32>>(vec3<i32>((_e537 + vec3<f32>(1f, 1f, 0f))));
                let _e609 = ((((_e600.x * 1597334677u) ^ (_e600.y * 3812015801u)) ^ (_e600.z * 2798796415u)) * 1597334677u);
                let _e621 = bitcast<vec3<u32>>(vec3<i32>((_e537 + vec3<f32>(0f, 0f, 1f))));
                let _e630 = ((((_e621.x * 1597334677u) ^ (_e621.y * 3812015801u)) ^ (_e621.z * 2798796415u)) * 1597334677u);
                let _e639 = bitcast<vec3<u32>>(vec3<i32>((_e537 + vec3<f32>(1f, 0f, 1f))));
                let _e648 = ((((_e639.x * 1597334677u) ^ (_e639.y * 3812015801u)) ^ (_e639.z * 2798796415u)) * 1597334677u);
                let _e658 = bitcast<vec3<u32>>(vec3<i32>((_e537 + vec3<f32>(0f, 1f, 1f))));
                let _e667 = ((((_e658.x * 1597334677u) ^ (_e658.y * 3812015801u)) ^ (_e658.z * 2798796415u)) * 1597334677u);
                let _e676 = bitcast<vec3<u32>>(vec3<i32>((_e537 + vec3<f32>(1f, 1f, 1f))));
                let _e685 = ((((_e676.x * 1597334677u) ^ (_e676.y * 3812015801u)) ^ (_e676.z * 2798796415u)) * 1597334677u);
                let _e698 = mix(0.45f, 0.05f, _e356);
                phi_20821_ = smoothstep(-(_e698), _e698, ((_e370 + -24.45f) + ((((mix(mix(mix((f32(((_e391 ^ (_e391 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e409 ^ (_e409 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e380.x), mix((f32(((_e429 ^ (_e429 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e447 ^ (_e447 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e380.x), _e380.y), mix(mix((f32(((_e468 ^ (_e468 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e486 ^ (_e486 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e380.x), mix((f32(((_e505 ^ (_e505 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e523 ^ (_e523 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e380.x), _e380.y), _e380.z) * 0.65f) + (mix(mix(mix((f32(((_e553 ^ (_e553 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e571 ^ (_e571 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e542.x), mix((f32(((_e591 ^ (_e591 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e609 ^ (_e609 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e542.x), _e542.y), mix(mix((f32(((_e630 ^ (_e630 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e648 ^ (_e648 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e542.x), mix((f32(((_e667 ^ (_e667 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e685 ^ (_e685 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e542.x), _e542.y), _e542.z) * 0.35f)) - 0.5f) * mix(0.8f, 2.2f, _e356))));
                break;
            }
        }
        let _e707 = phi_20821_;
        let _e709 = local_28;
        let _e7742 = local_55;
        phi_20984_ = _e7742;
        phi_20951_ = _e707;
        phi_20920_ = mix(_e319, ((_e284 * _e709) * mix(vec3<f32>(1f, 1f, 1f), (_e289 * 2f), vec3<f32>(0.5f, 0.5f, 0.5f))), vec3(_e707));
    }
    let _e717 = phi_20984_;
    let _e719 = phi_20951_;
    let _e721 = phi_20920_;
    let _e722 = global_9;
    let _e723 = normalize(_e722);
    let _e726 = global_8.member_6[1u];
    phi_20833_ = _e723;
    if (_e726 > 0.5f) {
        let _e728 = global_10;
        let _e729 = _e728.xyz;
        let _e732 = (_e729 - (_e723 * dot(_e723, _e729)));
        phi_20834_ = _e723;
        if (dot(_e732, _e732) > 0.000000000001f) {
            let _e735 = normalize(_e732);
            let _e738 = global_10[3u];
            let _e742 = textureSample(global_23, global_5, _e281);
            let _e745 = global_8.member_6[2u];
            if (_e745 > 0.5f) {
                if (_e745 > 1.5f) {
                    phi_20824_ = _e742.xw;
                } else {
                    phi_20824_ = _e742.xy;
                }
                let _e751 = phi_20824_;
                let _e753 = ((_e751 * 2f) - vec2<f32>(1f, 1f));
                phi_20825_ = vec3<f32>(_e753.x, _e753.y, sqrt(clamp((1f - dot(_e753, _e753)), 0f, 1f)));
            } else {
                phi_20825_ = ((_e742.xyz * 2f) - vec3<f32>(1f, 1f, 1f));
            }
            let _e765 = phi_20825_;
            let _e768 = global_8.member_4[2u];
            let _e770 = (_e765.xy * _e768);
            phi_20834_ = normalize((((_e735 * _e770.x) + ((cross(_e723, _e735) * select(1f, -1f, (_e738 < 0f))) * _e770.y)) + (_e723 * _e765.z)));
        }
        let _e781 = phi_20834_;
        phi_20833_ = _e781;
    }
    let _e783 = phi_20833_;
    let _e786 = global_8.member_5[3u];
    let _e787 = (_e786 > 0.5f);
    if _e787 {
        let _e790 = global_8.member_1[2u];
        phi_20830_ = clamp(_e790, 0f, 1f);
    } else {
        phi_20830_ = 0f;
    }
    let _e793 = phi_20830_;
    phi_3625_ = _e787;
    if _e787 {
        let _e794 = global_24;
        phi_3625_ = !(_e794);
    }
    let _e797 = phi_3625_;
    phi_21020_ = _e783;
    if (_e797 && (_e793 <= 0f)) {
        phi_21020_ = -(_e783);
    }
    let _e802 = phi_21020_;
    let _e804 = global.member_4;
    let _e806 = normalize(_e804.xyz);
    let _e808 = global.member_6;
    let _e809 = _e808.xyz;
    let _e810 = global_13;
    let _e811 = (_e809 - _e810);
    let _e812 = normalize(_e811);
    let _e814 = normalize((_e806 + _e812));
    let _e815 = global_24;
    let _e817 = (_e723 * select(-1f, 1f, _e815));
    let _e819 = global_25[0u];
    let _e820 = (_e819 > 0.5f);
    let _e823 = global.member_5[3u];
    phi_21054_ = 1f;
    phi_21014_ = _e721;
    if ((_e823 > 0.5f) && _e820) {
        switch bitcast<i32>(0u) {
            default: {
                let _e829 = global.member_21[0u];
                let _e830 = i32(_e829);
                let _e832 = global.member_20;
                let _e837 = global.member_20[3u];
                let _e838 = (dot(_e832.xyz, _e810) + _e837);
                phi_20835_ = 0i;
                loop {
                    let _e840 = phi_20835_;
                    local_29 = _e840;
                    local_30 = _e840;
                    local_31 = _e840;
                    local_32 = _e840;
                    local_33 = _e840;
                    local_34 = _e840;
                    local_36 = _e840;
                    local_37 = _e840;
                    local_38 = _e840;
                    let _e842 = (_e840 < (_e830 - 1i));
                    phi_5399_ = _e842;
                    if _e842 {
                        let _e845 = global.member_16[_e840];
                        phi_5399_ = (_e838 > _e845);
                    }
                    let _e848 = phi_5399_;
                    if _e848 {
                        continue;
                    } else {
                        break;
                    }
                    continuing {
                        phi_20835_ = (_e840 + 1i);
                    }
                }
                let _e852 = local_29;
                let _e854 = global.member_16[_e852];
                if (_e838 > _e854) {
                    phi_20891_ = vec3<f32>(1f, 1f, 1f);
                    phi_20890_ = 1f;
                    break;
                }
                let _e858 = local_30;
                let _e860 = global.member_18[_e858];
                let _e862 = (_e810 + (_e817 * _e860));
                switch bitcast<i32>(0u) {
                    default: {
                        let _e866 = local_31;
                        let _e868 = global.member_14[_e866];
                        let _e873 = (_e868 * vec4<f32>(_e862.x, _e862.y, _e862.z, 1f));
                        let _e875 = (_e873.x < 0f);
                        phi_5512_ = _e875;
                        if !(_e875) {
                            phi_5512_ = (_e873.x > 1f);
                        }
                        let _e879 = phi_5512_;
                        phi_5519_ = _e879;
                        if !(_e879) {
                            phi_5519_ = (_e873.y < 0f);
                        }
                        let _e884 = phi_5519_;
                        phi_5526_ = _e884;
                        if !(_e884) {
                            phi_5526_ = (_e873.y > 1f);
                        }
                        let _e889 = phi_5526_;
                        if _e889 {
                            phi_20848_ = 1f;
                            break;
                        }
                        let _e891 = local_32;
                        let _e895 = local_33;
                        let _e901 = global.member_23;
                        let _e902 = _e901.xy;
                        let _e903 = (vec2<f32>(f32((_e891 & 1i)), f32((_e895 >> bitcast<u32>(1i)))) * _e902);
                        let _e908 = local_34;
                        let _e910 = global.member_19[_e908];
                        let _e911 = (min(_e873.z, 1f) - _e910);
                        let _e914 = global.member_22;
                        let _e915 = _e914.xy;
                        let _e916 = (_e915 * 0.5f);
                        let _e918 = (_e903 + (_e873.xy * _e902));
                        let _e919 = (_e903 + _e916);
                        let _e921 = ((_e903 + _e902) - _e916);
                        let _e926 = vec4<f32>(_e919.x, _e919.y, _e921.x, _e921.y);
                        switch bitcast<i32>(0u) {
                            default: {
                                let _e930 = global.member_22[2u];
                                let _e931 = i32(_e930);
                                if (_e931 <= 0i) {
                                    let _e935 = clamp(_e918, _e926.xy, _e926.zw);
                                    let _e940 = textureSampleCompare(global_2, global_1, vec3<f32>(_e935.x, _e935.y, _e911).xy, _e911);
                                    phi_20847_ = _e940;
                                    break;
                                }
                                let _e942 = ((_e918 / _e915) + vec2<f32>(0.5f, 0.5f));
                                let _e943 = floor(_e942);
                                let _e944 = (_e942 - _e943);
                                let _e946 = (_e931 == 1i);
                                if _e946 {
                                    let _e947 = (_e944 * 2f);
                                    local_24[0i] = (vec2<f32>(3f, 3f) - _e947);
                                    local_24[1i] = (vec2<f32>(1f, 1f) + _e947);
                                    let _e953 = local_24[0i];
                                    local_25[0i] = (((vec2<f32>(2f, 2f) - _e944) / _e953) - vec2<f32>(1f, 1f));
                                    let _e957 = local_24[1i];
                                    local_25[1i] = ((_e944 / _e957) + vec2<f32>(1f, 1f));
                                } else {
                                    let _e961 = (_e944 * 3f);
                                    local_24[0i] = (vec2<f32>(4f, 4f) - _e961);
                                    local_24[1i] = vec2<f32>(7f, 7f);
                                    local_24[2i] = (vec2<f32>(1f, 1f) + _e961);
                                    let _e969 = local_24[0i];
                                    local_25[0i] = (((vec2<f32>(3f, 3f) - (_e944 * 2f)) / _e969) - vec2<f32>(2f, 2f));
                                    let _e974 = local_24[1i];
                                    local_25[1i] = ((vec2<f32>(3f, 3f) + _e944) / _e974);
                                    let _e977 = local_24[2i];
                                    local_25[2i] = ((_e944 / _e977) + vec2<f32>(2f, 2f));
                                }
                                let _e982 = select(3i, 2i, _e946);
                                phi_20840_ = 0f;
                                phi_20837_ = 0i;
                                loop {
                                    let _e984 = phi_20840_;
                                    let _e986 = phi_20837_;
                                    local_35 = _e984;
                                    if (_e986 < _e982) {
                                        phi_20846_ = _e984;
                                        phi_20843_ = 0i;
                                        loop {
                                            let _e989 = phi_20846_;
                                            let _e991 = phi_20843_;
                                            local_56 = _e989;
                                            if (_e991 < _e982) {
                                                continue;
                                            } else {
                                                break;
                                            }
                                            continuing {
                                                let _e995 = local_25[_e991][0u];
                                                let _e998 = local_25[_e986][1u];
                                                let _e1004 = clamp((_e915 * ((_e943 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e995, _e998))), _e926.xy, _e926.zw);
                                                let _e1007 = local_24[_e991][0u];
                                                let _e1010 = local_24[_e986][1u];
                                                let _e1016 = textureSampleCompare(global_2, global_1, vec3<f32>(_e1004.x, _e1004.y, _e911).xy, _e911);
                                                phi_20846_ = (_e989 + ((_e1007 * _e1010) * _e1016));
                                                phi_20843_ = (_e991 + 1i);
                                            }
                                        }
                                        continue;
                                    } else {
                                        break;
                                    }
                                    continuing {
                                        let _e7765 = local_56;
                                        phi_20840_ = _e7765;
                                        phi_20837_ = (_e986 + 1i);
                                    }
                                }
                                let _e1022 = local_35;
                                phi_20847_ = (_e1022 * select(0.0069444445f, 0.0625f, _e946));
                                break;
                            }
                        }
                        let _e1025 = phi_20847_;
                        phi_20848_ = _e1025;
                        break;
                    }
                }
                let _e1027 = phi_20848_;
                local_26 = array<vec3<f32>, 4>(vec3<f32>(1f, 0.45f, 0.45f), vec3<f32>(0.45f, 1f, 0.45f), vec3<f32>(0.5f, 0.6f, 1f), vec3<f32>(1f, 1f, 0.4f));
                let _e1029 = local_36;
                let _e1031 = local_26[_e1029];
                let _e1034 = local_37;
                let _e1036 = global.member_17[_e1034];
                phi_20888_ = _e1027;
                phi_20885_ = _e1031;
                if (_e838 > _e1036) {
                    let _e1040 = ((_e838 - _e1036) / (_e854 - _e1036));
                    let _e1042 = local_38;
                    let _e1043 = (_e1042 + 1i);
                    if (_e1043 < _e830) {
                        let _e1047 = global.member_18[_e1043];
                        let _e1049 = (_e810 + (_e817 * _e1047));
                        switch bitcast<i32>(0u) {
                            default: {
                                let _e1053 = global.member_14[_e1043];
                                let _e1058 = (_e1053 * vec4<f32>(_e1049.x, _e1049.y, _e1049.z, 1f));
                                let _e1060 = (_e1058.x < 0f);
                                phi_5799_ = _e1060;
                                if !(_e1060) {
                                    phi_5799_ = (_e1058.x > 1f);
                                }
                                let _e1064 = phi_5799_;
                                phi_5806_ = _e1064;
                                if !(_e1064) {
                                    phi_5806_ = (_e1058.y < 0f);
                                }
                                let _e1069 = phi_5806_;
                                phi_5813_ = _e1069;
                                if !(_e1069) {
                                    phi_5813_ = (_e1058.y > 1f);
                                }
                                let _e1074 = phi_5813_;
                                if _e1074 {
                                    phi_20868_ = 1f;
                                    break;
                                }
                                let _e1082 = global.member_23;
                                let _e1083 = _e1082.xy;
                                let _e1084 = (vec2<f32>(f32((_e1043 & 1i)), f32((_e1043 >> bitcast<u32>(1i)))) * _e1083);
                                let _e1089 = global.member_19[_e1043];
                                let _e1090 = (min(_e1058.z, 1f) - _e1089);
                                let _e1093 = global.member_22;
                                let _e1094 = _e1093.xy;
                                let _e1095 = (_e1094 * 0.5f);
                                let _e1097 = (_e1084 + (_e1058.xy * _e1083));
                                let _e1098 = (_e1084 + _e1095);
                                let _e1100 = ((_e1084 + _e1083) - _e1095);
                                let _e1105 = vec4<f32>(_e1098.x, _e1098.y, _e1100.x, _e1100.y);
                                switch bitcast<i32>(0u) {
                                    default: {
                                        let _e1109 = global.member_22[2u];
                                        let _e1110 = i32(_e1109);
                                        if (_e1110 <= 0i) {
                                            let _e1114 = clamp(_e1097, _e1105.xy, _e1105.zw);
                                            let _e1119 = textureSampleCompare(global_2, global_1, vec3<f32>(_e1114.x, _e1114.y, _e1090).xy, _e1090);
                                            phi_20867_ = _e1119;
                                            break;
                                        }
                                        let _e1121 = ((_e1097 / _e1094) + vec2<f32>(0.5f, 0.5f));
                                        let _e1122 = floor(_e1121);
                                        let _e1123 = (_e1121 - _e1122);
                                        let _e1125 = (_e1110 == 1i);
                                        if _e1125 {
                                            let _e1126 = (_e1123 * 2f);
                                            local_22[0i] = (vec2<f32>(3f, 3f) - _e1126);
                                            local_22[1i] = (vec2<f32>(1f, 1f) + _e1126);
                                            let _e1132 = local_22[0i];
                                            local_23[0i] = (((vec2<f32>(2f, 2f) - _e1123) / _e1132) - vec2<f32>(1f, 1f));
                                            let _e1136 = local_22[1i];
                                            local_23[1i] = ((_e1123 / _e1136) + vec2<f32>(1f, 1f));
                                        } else {
                                            let _e1140 = (_e1123 * 3f);
                                            local_22[0i] = (vec2<f32>(4f, 4f) - _e1140);
                                            local_22[1i] = vec2<f32>(7f, 7f);
                                            local_22[2i] = (vec2<f32>(1f, 1f) + _e1140);
                                            let _e1148 = local_22[0i];
                                            local_23[0i] = (((vec2<f32>(3f, 3f) - (_e1123 * 2f)) / _e1148) - vec2<f32>(2f, 2f));
                                            let _e1153 = local_22[1i];
                                            local_23[1i] = ((vec2<f32>(3f, 3f) + _e1123) / _e1153);
                                            let _e1156 = local_22[2i];
                                            local_23[2i] = ((_e1123 / _e1156) + vec2<f32>(2f, 2f));
                                        }
                                        let _e1161 = select(3i, 2i, _e1125);
                                        phi_20860_ = 0f;
                                        phi_20857_ = 0i;
                                        loop {
                                            let _e1163 = phi_20860_;
                                            let _e1165 = phi_20857_;
                                            local_39 = _e1163;
                                            if (_e1165 < _e1161) {
                                                phi_20866_ = _e1163;
                                                phi_20863_ = 0i;
                                                loop {
                                                    let _e1168 = phi_20866_;
                                                    let _e1170 = phi_20863_;
                                                    local_57 = _e1168;
                                                    if (_e1170 < _e1161) {
                                                        continue;
                                                    } else {
                                                        break;
                                                    }
                                                    continuing {
                                                        let _e1174 = local_23[_e1170][0u];
                                                        let _e1177 = local_23[_e1165][1u];
                                                        let _e1183 = clamp((_e1094 * ((_e1122 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e1174, _e1177))), _e1105.xy, _e1105.zw);
                                                        let _e1186 = local_22[_e1170][0u];
                                                        let _e1189 = local_22[_e1165][1u];
                                                        let _e1195 = textureSampleCompare(global_2, global_1, vec3<f32>(_e1183.x, _e1183.y, _e1090).xy, _e1090);
                                                        phi_20866_ = (_e1168 + ((_e1186 * _e1189) * _e1195));
                                                        phi_20863_ = (_e1170 + 1i);
                                                    }
                                                }
                                                continue;
                                            } else {
                                                break;
                                            }
                                            continuing {
                                                let _e7780 = local_57;
                                                phi_20860_ = _e7780;
                                                phi_20857_ = (_e1165 + 1i);
                                            }
                                        }
                                        let _e1201 = local_39;
                                        phi_20867_ = (_e1201 * select(0.0069444445f, 0.0625f, _e1125));
                                        break;
                                    }
                                }
                                let _e1204 = phi_20867_;
                                phi_20868_ = _e1204;
                                break;
                            }
                        }
                        let _e1206 = phi_20868_;
                        local_27 = array<vec3<f32>, 4>(vec3<f32>(1f, 0.45f, 0.45f), vec3<f32>(0.45f, 1f, 0.45f), vec3<f32>(0.5f, 0.6f, 1f), vec3<f32>(1f, 1f, 0.4f));
                        let _e1209 = local_27[_e1043];
                        phi_20889_ = mix(_e1027, _e1206, _e1040);
                        phi_20886_ = mix(_e1031, _e1209, vec3(_e1040));
                    } else {
                        phi_20889_ = mix(_e1027, 1f, _e1040);
                        phi_20886_ = _e1031;
                    }
                    let _e1214 = phi_20889_;
                    let _e1216 = phi_20886_;
                    phi_20888_ = _e1214;
                    phi_20885_ = _e1216;
                }
                let _e1218 = phi_20888_;
                let _e1220 = phi_20885_;
                let _e1223 = global.member_22[3u];
                phi_20891_ = select(vec3<f32>(1f, 1f, 1f), _e1220, vec3((_e1223 > 0.5f)));
                phi_20890_ = _e1218;
                break;
            }
        }
        let _e1228 = phi_20891_;
        let _e1230 = phi_20890_;
        phi_21054_ = _e1230;
        phi_21014_ = (_e721 * _e1228);
    }
    let _e1233 = phi_21054_;
    let _e1235 = phi_21014_;
    let _e1237 = global.member_5;
    let _e1241 = global.member_4[3u];
    let _e1242 = (_e1237.xyz * _e1241);
    let _e1245 = global_8.member_6[3u];
    let _e1246 = (_e1245 > 0.5f);
    if _e1246 {
        phi_20943_ = 1f;
    } else {
        let _e1249 = global_8.member_4[3u];
        let _e1250 = textureSample(global_19, global_5, _e281);
        phi_20943_ = (1f + (_e1249 * (_e1250.x - 1f)));
    }
    let _e1256 = phi_20943_;
    let _e1258 = global_10[3u];
    let _e1259 = abs(_e1258);
    phi_21144_ = _e1256;
    if (_e1259 > 0f) {
        phi_21144_ = (_e1256 * min(_e1259, 1f));
    }
    let _e1264 = phi_21144_;
    if !(_e787) {
        let _e1266 = dot(_e802, _e806);
        let _e1273 = global_8.member_1[3u];
        let _e1277 = global_8.member_1[2u];
        let _e1284 = global.member_29[0u];
        let _e1285 = (_e1284 > 0.5f);
        if _e1285 {
            let _e1287 = global.member_29;
            let _e1294 = ((_e1287.z * _e802.x) - (_e1287.w * _e802.z));
            let _e1298 = ((_e1287.w * _e802.x) + (_e1287.z * _e802.z));
            let _e1302 = (1.092548f * _e1294);
            local_21 = array<f32, 9>(0.282095f, (0.488603f * _e802.y), (0.488603f * _e1298), (0.488603f * _e1294), (_e1302 * _e802.y), ((1.092548f * _e802.y) * _e1298), (0.315392f * (((3f * _e1298) * _e1298) - 1f)), (_e1302 * _e1298), (0.546274f * ((_e1294 * _e1294) - (_e802.y * _e802.y))));
            phi_21671_ = vec3<f32>(0f, 0f, 0f);
            phi_21670_ = 0i;
            loop {
                let _e1317 = phi_21671_;
                let _e1319 = phi_21670_;
                local_40 = _e1317;
                if (_e1319 < 9i) {
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e1323 = textureLoad(global_4, (vec2<i32>(496i, 256i) + vec2<i32>(_e1319, 0i)), 0i);
                    let _e1326 = local_21[_e1319];
                    phi_21671_ = (_e1317 + (_e1323.xyz * _e1326));
                    phi_21670_ = (_e1319 + 1i);
                }
            }
            let _e1331 = local_40;
            let _e1335 = global.member_29[1u];
            phi_21672_ = (max(_e1331, vec3<f32>(0f, 0f, 0f)) * _e1335);
        } else {
            let _e1338 = global.member_9;
            let _e1341 = global.member_8;
            let _e1350 = global.member_8[3u];
            phi_21672_ = (mix(_e1338.xyz, _e1341.xyz, vec3(((_e802.y * 0.5f) + 0.5f))) * _e1350);
        }
        let _e1353 = phi_21672_;
        let _e1359 = ((_e1235 * ((_e1353 * _e1264) + ((_e1242 * max(_e1266, 0f)) * _e1233))) + ((_e1242 * ((pow(max(dot(_e802, _e814), 0f), _e1273) * _e1277) * step(0f, _e1266))) * _e1233));
        let _e1362 = global.member_34[1u];
        phi_21699_ = _e1359;
        if (_e1362 > 0.5f) {
            if _e1285 {
                let _e1365 = global.member_29;
                let _e1372 = ((_e1365.z * _e802.x) - (_e1365.w * _e802.z));
                let _e1376 = ((_e1365.w * _e802.x) + (_e1365.z * _e802.z));
                let _e1380 = (1.092548f * _e1372);
                local_20 = array<f32, 9>(0.282095f, (0.488603f * _e802.y), (0.488603f * _e1376), (0.488603f * _e1372), (_e1380 * _e802.y), ((1.092548f * _e802.y) * _e1376), (0.315392f * (((3f * _e1376) * _e1376) - 1f)), (_e1380 * _e1376), (0.546274f * ((_e1372 * _e1372) - (_e802.y * _e802.y))));
                phi_21682_ = vec3<f32>(0f, 0f, 0f);
                phi_21681_ = 0i;
                loop {
                    let _e1395 = phi_21682_;
                    let _e1397 = phi_21681_;
                    local_41 = _e1395;
                    if (_e1397 < 9i) {
                        continue;
                    } else {
                        break;
                    }
                    continuing {
                        let _e1401 = textureLoad(global_4, (vec2<i32>(496i, 256i) + vec2<i32>(_e1397, 0i)), 0i);
                        let _e1404 = local_20[_e1397];
                        phi_21682_ = (_e1395 + (_e1401.xyz * _e1404));
                        phi_21681_ = (_e1397 + 1i);
                    }
                }
                let _e1409 = local_41;
                let _e1413 = global.member_29[1u];
                phi_21683_ = (max(_e1409, vec3<f32>(0f, 0f, 0f)) * _e1413);
            } else {
                let _e1416 = global.member_9;
                let _e1419 = global.member_8;
                let _e1428 = global.member_8[3u];
                phi_21683_ = (mix(_e1416.xyz, _e1419.xyz, vec3(((_e802.y * 0.5f) + 0.5f))) * _e1428);
            }
            let _e1431 = phi_21683_;
            let _e1435 = global.member_34[0u];
            phi_21689_ = _e1431;
            phi_21688_ = 0i;
            loop {
                let _e1438 = phi_21689_;
                let _e1440 = phi_21688_;
                local_42 = _e1438;
                if (_e1440 < i32(_e1362)) {
                    let _e1443 = (8i * (i32(_e1435) + _e1440));
                    let _e1447 = global_3.member[(_e1443 + 3i)];
                    let _e1448 = bitcast<vec4<f32>>(_e1447);
                    let _e1451 = global_3.member[_e1443];
                    let _e1452 = bitcast<vec4<f32>>(_e1451);
                    let _e1456 = global_3.member[(_e1443 + 1i)];
                    let _e1457 = bitcast<vec4<f32>>(_e1456);
                    let _e1461 = global_3.member[(_e1443 + 2i)];
                    let _e1462 = bitcast<vec4<f32>>(_e1461);
                    let _e1463 = _e1452.xyz;
                    let _e1467 = _e1457.xyz;
                    let _e1471 = _e1462.xyz;
                    let _e1475 = vec3<f32>((dot(_e1463, _e810) + _e1452.w), (dot(_e1467, _e810) + _e1457.w), (dot(_e1471, _e810) + _e1462.w));
                    let _e1476 = _e1448.xyz;
                    switch bitcast<i32>(0u) {
                        default: {
                            let _e1480 = (_e1476 - abs(_e1475));
                            let _e1485 = min(_e1480.x, min(_e1480.y, _e1480.z));
                            if (_e1485 <= 0f) {
                                phi_21950_ = 0f;
                                break;
                            }
                            if (_e1448.w <= 0f) {
                                phi_21950_ = 1f;
                                break;
                            }
                            let _e1489 = min((_e1485 / _e1448.w), 1f);
                            phi_21950_ = ((_e1489 * _e1489) * (3f - (2f * _e1489)));
                            break;
                        }
                    }
                    let _e1495 = phi_21950_;
                    if (_e1495 <= 0f) {
                        phi_21987_ = _e1438;
                        continue;
                    }
                    let _e1500 = global_3.member[(_e1443 + 4i)];
                    let _e1502 = bitcast<vec4<f32>>(_e1500).xyz;
                    let _e1506 = global_3.member[(_e1443 + 5i)];
                    let _e1507 = bitcast<vec4<f32>>(_e1506);
                    let _e1512 = global_3.member[(_e1443 + 6i)][0u];
                    let _e1513 = bitcast<i32>(_e1512);
                    let _e1514 = dot(_e1463, _e802);
                    let _e1515 = dot(_e1467, _e802);
                    let _e1516 = dot(_e1471, _e802);
                    let _e1517 = vec3<f32>(_e1514, _e1515, _e1516);
                    let _e1523 = ((_e810 + (_e802 * _e1507.x)) + (_e812 * _e1507.y));
                    let _e1538 = clamp(((((vec3<f32>((dot(_e1463, _e1523) + _e1452.w), (dot(_e1467, _e1523) + _e1457.w), (dot(_e1471, _e1523) + _e1462.w)) + _e1476) / max((_e1476 * 2f), vec3<f32>(0.000001f, 0.000001f, 0.000001f))) * _e1502) - vec3<f32>(0.5f, 0.5f, 0.5f)), vec3<f32>(0f, 0f, 0f), (_e1502 - vec3<f32>(1f, 1f, 1f)));
                    let _e1539 = vec3<i32>(_e1502);
                    let _e1543 = min(vec3<i32>(_e1538), max((_e1539 - vec3<i32>(2i, 2i, 2i)), vec3<i32>(0i, 0i, 0i)));
                    let _e1545 = (_e1538 - vec3<f32>(_e1543));
                    let _e1546 = (0.488603f * _e1515);
                    let _e1547 = (0.488603f * _e1516);
                    let _e1548 = (0.488603f * _e1514);
                    let _e1549 = (1.092548f * _e1514);
                    let _e1550 = (_e1549 * _e1515);
                    let _e1552 = ((1.092548f * _e1515) * _e1516);
                    let _e1556 = (0.315392f * (((3f * _e1516) * _e1516) - 1f));
                    let _e1557 = (_e1549 * _e1516);
                    let _e1561 = (0.546274f * ((_e1514 * _e1514) - (_e1515 * _e1515)));
                    let _e1562 = (_e1539 - vec3<i32>(1i, 1i, 1i));
                    let _e1563 = min(_e1543, _e1562);
                    let _e1574 = (_e1513 + ((_e1563.x + (_e1539.x * (_e1563.y + (_e1539.y * _e1563.z)))) * 4i));
                    let _e1575 = (vec3<f32>(1f, 1f, 1f) - _e1545);
                    let _e1582 = ((((((vec3<f32>(_e1563) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e1502) * _e1476) * 2f) - _e1476) - _e1475);
                    let _e1588 = (dot((_e1582 * inverseSqrt(max(dot(_e1582, _e1582), 0.0000000001f))), _e1517) + 1f);
                    let _e1591 = (_e1575.x * _e1575.y);
                    let _e1598 = (_e1574 + 3i);
                    let _e1602 = global_3.member[_e1598][1u];
                    let _e1607 = (((_e1591 * _e1575.z) * ((0.25f * (_e1588 * _e1588)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e1602).y > 0.5f)));
                    let _e1610 = global_3.member[_e1574];
                    let _e1614 = global_3.member[(_e1574 + 1i)];
                    let _e1618 = global_3.member[(_e1574 + 2i)];
                    let _e1621 = global_3.member[_e1598];
                    let _e1623 = unpack2x16float(_e1610.x);
                    let _e1625 = unpack2x16float(_e1610.y);
                    let _e1627 = unpack2x16float(_e1610.z);
                    let _e1629 = unpack2x16float(_e1610.w);
                    let _e1631 = unpack2x16float(_e1614.x);
                    let _e1633 = unpack2x16float(_e1614.y);
                    let _e1635 = unpack2x16float(_e1614.z);
                    let _e1637 = unpack2x16float(_e1614.w);
                    let _e1639 = unpack2x16float(_e1618.x);
                    let _e1641 = unpack2x16float(_e1618.y);
                    let _e1643 = unpack2x16float(_e1618.z);
                    let _e1645 = unpack2x16float(_e1618.w);
                    let _e1647 = unpack2x16float(_e1621.x);
                    let _e1703 = ((((((((((vec3<f32>(_e1623.x, _e1623.y, _e1625.x) * 0.282095f) + (vec3<f32>(_e1625.y, _e1627.x, _e1627.y) * _e1546)) + (vec3<f32>(_e1629.x, _e1629.y, _e1631.x) * _e1547)) + (vec3<f32>(_e1631.y, _e1633.x, _e1633.y) * _e1548)) + (vec3<f32>(_e1635.x, _e1635.y, _e1637.x) * _e1550)) + (vec3<f32>(_e1637.y, _e1639.x, _e1639.y) * _e1552)) + (vec3<f32>(_e1641.x, _e1641.y, _e1643.x) * _e1556)) + (vec3<f32>(_e1643.y, _e1645.x, _e1645.y) * _e1557)) + (vec3<f32>(_e1647.x, _e1647.y, unpack2x16float(_e1621.y).x) * _e1561)) * _e1607);
                    let _e1709 = min((_e1543 + vec3<i32>(1i, 0i, 0i)), _e1562);
                    let _e1718 = (_e1513 + ((_e1709.x + (_e1539.x * (_e1709.y + (_e1539.y * _e1709.z)))) * 4i));
                    let _e1725 = ((((((vec3<f32>(_e1709) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e1502) * _e1476) * 2f) - _e1476) - _e1475);
                    let _e1731 = (dot((_e1725 * inverseSqrt(max(dot(_e1725, _e1725), 0.0000000001f))), _e1517) + 1f);
                    let _e1733 = (_e1545.x * _e1575.y);
                    let _e1739 = (_e1718 + 3i);
                    let _e1743 = global_3.member[_e1739][1u];
                    let _e1748 = (((_e1733 * _e1575.z) * ((0.25f * (_e1731 * _e1731)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e1743).y > 0.5f)));
                    let _e1751 = global_3.member[_e1718];
                    let _e1755 = global_3.member[(_e1718 + 1i)];
                    let _e1759 = global_3.member[(_e1718 + 2i)];
                    let _e1762 = global_3.member[_e1739];
                    let _e1764 = unpack2x16float(_e1751.x);
                    let _e1766 = unpack2x16float(_e1751.y);
                    let _e1768 = unpack2x16float(_e1751.z);
                    let _e1770 = unpack2x16float(_e1751.w);
                    let _e1772 = unpack2x16float(_e1755.x);
                    let _e1774 = unpack2x16float(_e1755.y);
                    let _e1776 = unpack2x16float(_e1755.z);
                    let _e1778 = unpack2x16float(_e1755.w);
                    let _e1780 = unpack2x16float(_e1759.x);
                    let _e1782 = unpack2x16float(_e1759.y);
                    let _e1784 = unpack2x16float(_e1759.z);
                    let _e1786 = unpack2x16float(_e1759.w);
                    let _e1788 = unpack2x16float(_e1762.x);
                    let _e1844 = ((((((((((vec3<f32>(_e1764.x, _e1764.y, _e1766.x) * 0.282095f) + (vec3<f32>(_e1766.y, _e1768.x, _e1768.y) * _e1546)) + (vec3<f32>(_e1770.x, _e1770.y, _e1772.x) * _e1547)) + (vec3<f32>(_e1772.y, _e1774.x, _e1774.y) * _e1548)) + (vec3<f32>(_e1776.x, _e1776.y, _e1778.x) * _e1550)) + (vec3<f32>(_e1778.y, _e1780.x, _e1780.y) * _e1552)) + (vec3<f32>(_e1782.x, _e1782.y, _e1784.x) * _e1556)) + (vec3<f32>(_e1784.y, _e1786.x, _e1786.y) * _e1557)) + (vec3<f32>(_e1788.x, _e1788.y, unpack2x16float(_e1762.y).x) * _e1561)) * _e1748);
                    let _e1851 = min((_e1543 + vec3<i32>(0i, 1i, 0i)), _e1562);
                    let _e1860 = (_e1513 + ((_e1851.x + (_e1539.x * (_e1851.y + (_e1539.y * _e1851.z)))) * 4i));
                    let _e1867 = ((((((vec3<f32>(_e1851) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e1502) * _e1476) * 2f) - _e1476) - _e1475);
                    let _e1873 = (dot((_e1867 * inverseSqrt(max(dot(_e1867, _e1867), 0.0000000001f))), _e1517) + 1f);
                    let _e1875 = (_e1575.x * _e1545.y);
                    let _e1881 = (_e1860 + 3i);
                    let _e1885 = global_3.member[_e1881][1u];
                    let _e1890 = (((_e1875 * _e1575.z) * ((0.25f * (_e1873 * _e1873)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e1885).y > 0.5f)));
                    let _e1893 = global_3.member[_e1860];
                    let _e1897 = global_3.member[(_e1860 + 1i)];
                    let _e1901 = global_3.member[(_e1860 + 2i)];
                    let _e1904 = global_3.member[_e1881];
                    let _e1906 = unpack2x16float(_e1893.x);
                    let _e1908 = unpack2x16float(_e1893.y);
                    let _e1910 = unpack2x16float(_e1893.z);
                    let _e1912 = unpack2x16float(_e1893.w);
                    let _e1914 = unpack2x16float(_e1897.x);
                    let _e1916 = unpack2x16float(_e1897.y);
                    let _e1918 = unpack2x16float(_e1897.z);
                    let _e1920 = unpack2x16float(_e1897.w);
                    let _e1922 = unpack2x16float(_e1901.x);
                    let _e1924 = unpack2x16float(_e1901.y);
                    let _e1926 = unpack2x16float(_e1901.z);
                    let _e1928 = unpack2x16float(_e1901.w);
                    let _e1930 = unpack2x16float(_e1904.x);
                    let _e1986 = ((((((((((vec3<f32>(_e1906.x, _e1906.y, _e1908.x) * 0.282095f) + (vec3<f32>(_e1908.y, _e1910.x, _e1910.y) * _e1546)) + (vec3<f32>(_e1912.x, _e1912.y, _e1914.x) * _e1547)) + (vec3<f32>(_e1914.y, _e1916.x, _e1916.y) * _e1548)) + (vec3<f32>(_e1918.x, _e1918.y, _e1920.x) * _e1550)) + (vec3<f32>(_e1920.y, _e1922.x, _e1922.y) * _e1552)) + (vec3<f32>(_e1924.x, _e1924.y, _e1926.x) * _e1556)) + (vec3<f32>(_e1926.y, _e1928.x, _e1928.y) * _e1557)) + (vec3<f32>(_e1930.x, _e1930.y, unpack2x16float(_e1904.y).x) * _e1561)) * _e1890);
                    let _e1993 = min((_e1543 + vec3<i32>(1i, 1i, 0i)), _e1562);
                    let _e2002 = (_e1513 + ((_e1993.x + (_e1539.x * (_e1993.y + (_e1539.y * _e1993.z)))) * 4i));
                    let _e2009 = ((((((vec3<f32>(_e1993) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e1502) * _e1476) * 2f) - _e1476) - _e1475);
                    let _e2015 = (dot((_e2009 * inverseSqrt(max(dot(_e2009, _e2009), 0.0000000001f))), _e1517) + 1f);
                    let _e2016 = (_e1545.x * _e1545.y);
                    let _e2022 = (_e2002 + 3i);
                    let _e2026 = global_3.member[_e2022][1u];
                    let _e2031 = (((_e2016 * _e1575.z) * ((0.25f * (_e2015 * _e2015)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e2026).y > 0.5f)));
                    let _e2034 = global_3.member[_e2002];
                    let _e2038 = global_3.member[(_e2002 + 1i)];
                    let _e2042 = global_3.member[(_e2002 + 2i)];
                    let _e2045 = global_3.member[_e2022];
                    let _e2047 = unpack2x16float(_e2034.x);
                    let _e2049 = unpack2x16float(_e2034.y);
                    let _e2051 = unpack2x16float(_e2034.z);
                    let _e2053 = unpack2x16float(_e2034.w);
                    let _e2055 = unpack2x16float(_e2038.x);
                    let _e2057 = unpack2x16float(_e2038.y);
                    let _e2059 = unpack2x16float(_e2038.z);
                    let _e2061 = unpack2x16float(_e2038.w);
                    let _e2063 = unpack2x16float(_e2042.x);
                    let _e2065 = unpack2x16float(_e2042.y);
                    let _e2067 = unpack2x16float(_e2042.z);
                    let _e2069 = unpack2x16float(_e2042.w);
                    let _e2071 = unpack2x16float(_e2045.x);
                    let _e2127 = ((((((((((vec3<f32>(_e2047.x, _e2047.y, _e2049.x) * 0.282095f) + (vec3<f32>(_e2049.y, _e2051.x, _e2051.y) * _e1546)) + (vec3<f32>(_e2053.x, _e2053.y, _e2055.x) * _e1547)) + (vec3<f32>(_e2055.y, _e2057.x, _e2057.y) * _e1548)) + (vec3<f32>(_e2059.x, _e2059.y, _e2061.x) * _e1550)) + (vec3<f32>(_e2061.y, _e2063.x, _e2063.y) * _e1552)) + (vec3<f32>(_e2065.x, _e2065.y, _e2067.x) * _e1556)) + (vec3<f32>(_e2067.y, _e2069.x, _e2069.y) * _e1557)) + (vec3<f32>(_e2071.x, _e2071.y, unpack2x16float(_e2045.y).x) * _e1561)) * _e2031);
                    let _e2134 = min((_e1543 + vec3<i32>(0i, 0i, 1i)), _e1562);
                    let _e2143 = (_e1513 + ((_e2134.x + (_e1539.x * (_e2134.y + (_e1539.y * _e2134.z)))) * 4i));
                    let _e2150 = ((((((vec3<f32>(_e2134) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e1502) * _e1476) * 2f) - _e1476) - _e1475);
                    let _e2156 = (dot((_e2150 * inverseSqrt(max(dot(_e2150, _e2150), 0.0000000001f))), _e1517) + 1f);
                    let _e2163 = (_e2143 + 3i);
                    let _e2167 = global_3.member[_e2163][1u];
                    let _e2172 = (((_e1591 * _e1545.z) * ((0.25f * (_e2156 * _e2156)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e2167).y > 0.5f)));
                    let _e2175 = global_3.member[_e2143];
                    let _e2179 = global_3.member[(_e2143 + 1i)];
                    let _e2183 = global_3.member[(_e2143 + 2i)];
                    let _e2186 = global_3.member[_e2163];
                    let _e2188 = unpack2x16float(_e2175.x);
                    let _e2190 = unpack2x16float(_e2175.y);
                    let _e2192 = unpack2x16float(_e2175.z);
                    let _e2194 = unpack2x16float(_e2175.w);
                    let _e2196 = unpack2x16float(_e2179.x);
                    let _e2198 = unpack2x16float(_e2179.y);
                    let _e2200 = unpack2x16float(_e2179.z);
                    let _e2202 = unpack2x16float(_e2179.w);
                    let _e2204 = unpack2x16float(_e2183.x);
                    let _e2206 = unpack2x16float(_e2183.y);
                    let _e2208 = unpack2x16float(_e2183.z);
                    let _e2210 = unpack2x16float(_e2183.w);
                    let _e2212 = unpack2x16float(_e2186.x);
                    let _e2268 = ((((((((((vec3<f32>(_e2188.x, _e2188.y, _e2190.x) * 0.282095f) + (vec3<f32>(_e2190.y, _e2192.x, _e2192.y) * _e1546)) + (vec3<f32>(_e2194.x, _e2194.y, _e2196.x) * _e1547)) + (vec3<f32>(_e2196.y, _e2198.x, _e2198.y) * _e1548)) + (vec3<f32>(_e2200.x, _e2200.y, _e2202.x) * _e1550)) + (vec3<f32>(_e2202.y, _e2204.x, _e2204.y) * _e1552)) + (vec3<f32>(_e2206.x, _e2206.y, _e2208.x) * _e1556)) + (vec3<f32>(_e2208.y, _e2210.x, _e2210.y) * _e1557)) + (vec3<f32>(_e2212.x, _e2212.y, unpack2x16float(_e2186.y).x) * _e1561)) * _e2172);
                    let _e2275 = min((_e1543 + vec3<i32>(1i, 0i, 1i)), _e1562);
                    let _e2284 = (_e1513 + ((_e2275.x + (_e1539.x * (_e2275.y + (_e1539.y * _e2275.z)))) * 4i));
                    let _e2291 = ((((((vec3<f32>(_e2275) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e1502) * _e1476) * 2f) - _e1476) - _e1475);
                    let _e2297 = (dot((_e2291 * inverseSqrt(max(dot(_e2291, _e2291), 0.0000000001f))), _e1517) + 1f);
                    let _e2303 = (_e2284 + 3i);
                    let _e2307 = global_3.member[_e2303][1u];
                    let _e2312 = (((_e1733 * _e1545.z) * ((0.25f * (_e2297 * _e2297)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e2307).y > 0.5f)));
                    let _e2315 = global_3.member[_e2284];
                    let _e2319 = global_3.member[(_e2284 + 1i)];
                    let _e2323 = global_3.member[(_e2284 + 2i)];
                    let _e2326 = global_3.member[_e2303];
                    let _e2328 = unpack2x16float(_e2315.x);
                    let _e2330 = unpack2x16float(_e2315.y);
                    let _e2332 = unpack2x16float(_e2315.z);
                    let _e2334 = unpack2x16float(_e2315.w);
                    let _e2336 = unpack2x16float(_e2319.x);
                    let _e2338 = unpack2x16float(_e2319.y);
                    let _e2340 = unpack2x16float(_e2319.z);
                    let _e2342 = unpack2x16float(_e2319.w);
                    let _e2344 = unpack2x16float(_e2323.x);
                    let _e2346 = unpack2x16float(_e2323.y);
                    let _e2348 = unpack2x16float(_e2323.z);
                    let _e2350 = unpack2x16float(_e2323.w);
                    let _e2352 = unpack2x16float(_e2326.x);
                    let _e2408 = ((((((((((vec3<f32>(_e2328.x, _e2328.y, _e2330.x) * 0.282095f) + (vec3<f32>(_e2330.y, _e2332.x, _e2332.y) * _e1546)) + (vec3<f32>(_e2334.x, _e2334.y, _e2336.x) * _e1547)) + (vec3<f32>(_e2336.y, _e2338.x, _e2338.y) * _e1548)) + (vec3<f32>(_e2340.x, _e2340.y, _e2342.x) * _e1550)) + (vec3<f32>(_e2342.y, _e2344.x, _e2344.y) * _e1552)) + (vec3<f32>(_e2346.x, _e2346.y, _e2348.x) * _e1556)) + (vec3<f32>(_e2348.y, _e2350.x, _e2350.y) * _e1557)) + (vec3<f32>(_e2352.x, _e2352.y, unpack2x16float(_e2326.y).x) * _e1561)) * _e2312);
                    let _e2415 = min((_e1543 + vec3<i32>(0i, 1i, 1i)), _e1562);
                    let _e2424 = (_e1513 + ((_e2415.x + (_e1539.x * (_e2415.y + (_e1539.y * _e2415.z)))) * 4i));
                    let _e2431 = ((((((vec3<f32>(_e2415) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e1502) * _e1476) * 2f) - _e1476) - _e1475);
                    let _e2437 = (dot((_e2431 * inverseSqrt(max(dot(_e2431, _e2431), 0.0000000001f))), _e1517) + 1f);
                    let _e2443 = (_e2424 + 3i);
                    let _e2447 = global_3.member[_e2443][1u];
                    let _e2452 = (((_e1875 * _e1545.z) * ((0.25f * (_e2437 * _e2437)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e2447).y > 0.5f)));
                    let _e2455 = global_3.member[_e2424];
                    let _e2459 = global_3.member[(_e2424 + 1i)];
                    let _e2463 = global_3.member[(_e2424 + 2i)];
                    let _e2466 = global_3.member[_e2443];
                    let _e2468 = unpack2x16float(_e2455.x);
                    let _e2470 = unpack2x16float(_e2455.y);
                    let _e2472 = unpack2x16float(_e2455.z);
                    let _e2474 = unpack2x16float(_e2455.w);
                    let _e2476 = unpack2x16float(_e2459.x);
                    let _e2478 = unpack2x16float(_e2459.y);
                    let _e2480 = unpack2x16float(_e2459.z);
                    let _e2482 = unpack2x16float(_e2459.w);
                    let _e2484 = unpack2x16float(_e2463.x);
                    let _e2486 = unpack2x16float(_e2463.y);
                    let _e2488 = unpack2x16float(_e2463.z);
                    let _e2490 = unpack2x16float(_e2463.w);
                    let _e2492 = unpack2x16float(_e2466.x);
                    let _e2548 = ((((((((((vec3<f32>(_e2468.x, _e2468.y, _e2470.x) * 0.282095f) + (vec3<f32>(_e2470.y, _e2472.x, _e2472.y) * _e1546)) + (vec3<f32>(_e2474.x, _e2474.y, _e2476.x) * _e1547)) + (vec3<f32>(_e2476.y, _e2478.x, _e2478.y) * _e1548)) + (vec3<f32>(_e2480.x, _e2480.y, _e2482.x) * _e1550)) + (vec3<f32>(_e2482.y, _e2484.x, _e2484.y) * _e1552)) + (vec3<f32>(_e2486.x, _e2486.y, _e2488.x) * _e1556)) + (vec3<f32>(_e2488.y, _e2490.x, _e2490.y) * _e1557)) + (vec3<f32>(_e2492.x, _e2492.y, unpack2x16float(_e2466.y).x) * _e1561)) * _e2452);
                    let _e2555 = min((_e1543 + vec3<i32>(1i, 1i, 1i)), _e1562);
                    let _e2564 = (_e1513 + ((_e2555.x + (_e1539.x * (_e2555.y + (_e1539.y * _e2555.z)))) * 4i));
                    let _e2571 = ((((((vec3<f32>(_e2555) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e1502) * _e1476) * 2f) - _e1476) - _e1475);
                    let _e2577 = (dot((_e2571 * inverseSqrt(max(dot(_e2571, _e2571), 0.0000000001f))), _e1517) + 1f);
                    let _e2583 = (_e2564 + 3i);
                    let _e2587 = global_3.member[_e2583][1u];
                    let _e2592 = (((_e2016 * _e1545.z) * ((0.25f * (_e2577 * _e2577)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e2587).y > 0.5f)));
                    let _e2595 = global_3.member[_e2564];
                    let _e2599 = global_3.member[(_e2564 + 1i)];
                    let _e2603 = global_3.member[(_e2564 + 2i)];
                    let _e2606 = global_3.member[_e2583];
                    let _e2608 = unpack2x16float(_e2595.x);
                    let _e2610 = unpack2x16float(_e2595.y);
                    let _e2612 = unpack2x16float(_e2595.z);
                    let _e2614 = unpack2x16float(_e2595.w);
                    let _e2616 = unpack2x16float(_e2599.x);
                    let _e2618 = unpack2x16float(_e2599.y);
                    let _e2620 = unpack2x16float(_e2599.z);
                    let _e2622 = unpack2x16float(_e2599.w);
                    let _e2624 = unpack2x16float(_e2603.x);
                    let _e2626 = unpack2x16float(_e2603.y);
                    let _e2628 = unpack2x16float(_e2603.z);
                    let _e2630 = unpack2x16float(_e2603.w);
                    let _e2632 = unpack2x16float(_e2606.x);
                    let _e2688 = ((((((((((vec3<f32>(_e2608.x, _e2608.y, _e2610.x) * 0.282095f) + (vec3<f32>(_e2610.y, _e2612.x, _e2612.y) * _e1546)) + (vec3<f32>(_e2614.x, _e2614.y, _e2616.x) * _e1547)) + (vec3<f32>(_e2616.y, _e2618.x, _e2618.y) * _e1548)) + (vec3<f32>(_e2620.x, _e2620.y, _e2622.x) * _e1550)) + (vec3<f32>(_e2622.y, _e2624.x, _e2624.y) * _e1552)) + (vec3<f32>(_e2626.x, _e2626.y, _e2628.x) * _e1556)) + (vec3<f32>(_e2628.y, _e2630.x, _e2630.y) * _e1557)) + (vec3<f32>(_e2632.x, _e2632.y, unpack2x16float(_e2606.y).x) * _e1561)) * _e2592);
                    let _e2693 = (((((((vec4<f32>(_e1703.x, _e1703.y, _e1703.z, _e1607) + vec4<f32>(_e1844.x, _e1844.y, _e1844.z, _e1748)) + vec4<f32>(_e1986.x, _e1986.y, _e1986.z, _e1890)) + vec4<f32>(_e2127.x, _e2127.y, _e2127.z, _e2031)) + vec4<f32>(_e2268.x, _e2268.y, _e2268.z, _e2172)) + vec4<f32>(_e2408.x, _e2408.y, _e2408.z, _e2312)) + vec4<f32>(_e2548.x, _e2548.y, _e2548.z, _e2452)) + vec4<f32>(_e2688.x, _e2688.y, _e2688.z, _e2592));
                    phi_21988_ = _e1438;
                    if (_e2693.w > 0.00001f) {
                        phi_21988_ = mix(_e1438, ((max(_e2693.xyz, vec3<f32>(0f, 0f, 0f)) / vec3(_e2693.w)) * _e1507.z), vec3(_e1495));
                    }
                    let _e2705 = phi_21988_;
                    phi_21987_ = _e2705;
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e2707 = phi_21987_;
                    phi_21689_ = _e2707;
                    phi_21688_ = (_e1440 + 1i);
                }
            }
            let _e2710 = local_42;
            phi_21699_ = (_e1359 + ((_e1235 * (_e2710 - _e1431)) * _e1264));
        }
        let _e2716 = phi_21699_;
        let _e2719 = global.member_13[3u];
        phi_21698_ = _e2716;
        if (_e2719 > 0.5f) {
            let _e2722 = global.member_11;
            let _e2727 = global.member_11[3u];
            let _e2729 = global_16;
            let _e2732 = global.member_12;
            let _e2737 = global.member_13;
            let _e2740 = clamp(floor((_e2729.xy * _e2732.xy)), vec2<f32>(0f, 0f), (_e2737.xy - vec2<f32>(1f, 1f)));
            let _e2745 = global.member_12[2u];
            let _e2749 = global.member_12[3u];
            let _e2754 = global.member_13[2u];
            let _e2759 = global.member_13[1u];
            let _e2765 = global.member_13[0u];
            let _e2769 = u32(((((clamp(floor(((log2(max((dot(_e2722.xyz, _e810) + _e2727), 0.000001f)) * _e2745) + _e2749)), 0f, (_e2754 - 1f)) * _e2759) + _e2740.y) * _e2765) + _e2740.x));
            let _e2776 = global_17.member[(_e2769 >> bitcast<u32>(2i))][(_e2769 & 3u)];
            let _e2777 = (_e2776 & 65535u);
            phi_21700_ = _e2716;
            phi_21696_ = _e2777;
            loop {
                let _e2781 = phi_21700_;
                let _e2783 = phi_21696_;
                local_61 = _e2781;
                if (_e2783 < (_e2777 + (_e2776 >> bitcast<u32>(16i)))) {
                    let _e2786 = (_e2783 / 3u);
                    let _e2793 = global_18.member[(_e2786 >> bitcast<u32>(2i))][(_e2786 & 3u)];
                    let _e2799 = ((_e2793 >> bitcast<u32>(((_e2783 - (_e2786 * 3u)) * 10u))) & 1023u);
                    let _e2802 = global_12.member[_e2799];
                    let _e2804 = (_e2802.xyz - _e810);
                    let _e2805 = dot(_e2804, _e2804);
                    let _e2807 = (_e2805 * _e2802.w);
                    let _e2810 = clamp((1f - (_e2807 * _e2807)), 0f, 1f);
                    let _e2813 = (_e2804 * inverseSqrt(max(_e2805, 0.00000001f)));
                    let _e2816 = global_14.member[_e2799];
                    let _e2819 = global_15.member[_e2799];
                    let _e2827 = clamp(((dot(-(_e2813), _e2819.xyz) * _e2816.w) + _e2819.w), 0f, 1f);
                    let _e2834 = (_e2816.xyz * ((((_e2810 * _e2810) * _e2827) * _e2827) / max(_e2805, 0.0001f)));
                    phi_21915_ = _e2834;
                    if _e820 {
                        switch bitcast<i32>(0u) {
                            default: {
                                let _e2838 = global.member_21[2u];
                                let _e2839 = u32(_e2838);
                                if (_e2799 < _e2839) {
                                    let _e2843 = global.member_26[_e2799];
                                    let _e2846 = global.member_15[_e2799];
                                    let _e2855 = (_e2843.z * max((_e2846 * vec4<f32>(_e810.x, _e810.y, _e810.z, 1f)).w, 0f));
                                    let _e2858 = global.member_25[0u];
                                    let _e2864 = global.member_25[1u];
                                    let _e2867 = ((_e810 + (_e817 * (_e2855 * _e2858))) + (_e2813 * (_e2855 * _e2864)));
                                    let _e2872 = (_e2846 * vec4<f32>(_e2867.x, _e2867.y, _e2867.z, 1f));
                                    if (_e2872.w <= 0f) {
                                        phi_21864_ = 1f;
                                        break;
                                    }
                                    let _e2877 = (_e2872.xyz / vec3(_e2872.w));
                                    let _e2879 = (_e2877.x < 0f);
                                    phi_9364_ = _e2879;
                                    if !(_e2879) {
                                        phi_9364_ = (_e2877.x > 1f);
                                    }
                                    let _e2883 = phi_9364_;
                                    phi_9371_ = _e2883;
                                    if !(_e2883) {
                                        phi_9371_ = (_e2877.y < 0f);
                                    }
                                    let _e2888 = phi_9371_;
                                    phi_9378_ = _e2888;
                                    if !(_e2888) {
                                        phi_9378_ = (_e2877.y > 1f);
                                    }
                                    let _e2893 = phi_9378_;
                                    phi_9385_ = _e2893;
                                    if !(_e2893) {
                                        phi_9385_ = (_e2877.z > 1f);
                                    }
                                    let _e2898 = phi_9385_;
                                    if _e2898 {
                                        phi_21864_ = 1f;
                                        break;
                                    }
                                    let _e2901 = _e2843.xy;
                                    let _e2903 = global.member_23;
                                    let _e2904 = _e2903.zw;
                                    let _e2906 = global.member_22;
                                    let _e2907 = _e2906.xy;
                                    let _e2908 = (_e2907 * 0.5f);
                                    let _e2910 = (_e2901 + (_e2877.xy * _e2904));
                                    let _e2911 = (_e2901 + _e2908);
                                    let _e2913 = ((_e2901 + _e2904) - _e2908);
                                    let _e2918 = vec4<f32>(_e2911.x, _e2911.y, _e2913.x, _e2913.y);
                                    switch bitcast<i32>(0u) {
                                        default: {
                                            let _e2922 = global.member_22[2u];
                                            let _e2923 = i32(_e2922);
                                            if (_e2923 <= 0i) {
                                                let _e2927 = clamp(_e2910, _e2918.xy, _e2918.zw);
                                                let _e2932 = textureSampleCompare(global_2, global_1, vec3<f32>(_e2927.x, _e2927.y, _e2877.z).xy, _e2877.z);
                                                phi_21863_ = _e2932;
                                                break;
                                            }
                                            let _e2934 = ((_e2910 / _e2907) + vec2<f32>(0.5f, 0.5f));
                                            let _e2935 = floor(_e2934);
                                            let _e2936 = (_e2934 - _e2935);
                                            let _e2938 = (_e2923 == 1i);
                                            if _e2938 {
                                                let _e2939 = (_e2936 * 2f);
                                                local_16[0i] = (vec2<f32>(3f, 3f) - _e2939);
                                                local_16[1i] = (vec2<f32>(1f, 1f) + _e2939);
                                                let _e2945 = local_16[0i];
                                                local_17[0i] = (((vec2<f32>(2f, 2f) - _e2936) / _e2945) - vec2<f32>(1f, 1f));
                                                let _e2949 = local_16[1i];
                                                local_17[1i] = ((_e2936 / _e2949) + vec2<f32>(1f, 1f));
                                            } else {
                                                let _e2953 = (_e2936 * 3f);
                                                local_16[0i] = (vec2<f32>(4f, 4f) - _e2953);
                                                local_16[1i] = vec2<f32>(7f, 7f);
                                                local_16[2i] = (vec2<f32>(1f, 1f) + _e2953);
                                                let _e2961 = local_16[0i];
                                                local_17[0i] = (((vec2<f32>(3f, 3f) - (_e2936 * 2f)) / _e2961) - vec2<f32>(2f, 2f));
                                                let _e2966 = local_16[1i];
                                                local_17[1i] = ((vec2<f32>(3f, 3f) + _e2936) / _e2966);
                                                let _e2969 = local_16[2i];
                                                local_17[2i] = ((_e2936 / _e2969) + vec2<f32>(2f, 2f));
                                            }
                                            let _e2974 = select(3i, 2i, _e2938);
                                            phi_21856_ = 0f;
                                            phi_21853_ = 0i;
                                            loop {
                                                let _e2976 = phi_21856_;
                                                let _e2978 = phi_21853_;
                                                local_43 = _e2976;
                                                if (_e2978 < _e2974) {
                                                    phi_21862_ = _e2976;
                                                    phi_21859_ = 0i;
                                                    loop {
                                                        let _e2981 = phi_21862_;
                                                        let _e2983 = phi_21859_;
                                                        local_59 = _e2981;
                                                        if (_e2983 < _e2974) {
                                                            continue;
                                                        } else {
                                                            break;
                                                        }
                                                        continuing {
                                                            let _e2987 = local_17[_e2983][0u];
                                                            let _e2990 = local_17[_e2978][1u];
                                                            let _e2996 = clamp((_e2907 * ((_e2935 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e2987, _e2990))), _e2918.xy, _e2918.zw);
                                                            let _e2999 = local_16[_e2983][0u];
                                                            let _e3002 = local_16[_e2978][1u];
                                                            let _e3008 = textureSampleCompare(global_2, global_1, vec3<f32>(_e2996.x, _e2996.y, _e2877.z).xy, _e2877.z);
                                                            phi_21862_ = (_e2981 + ((_e2999 * _e3002) * _e3008));
                                                            phi_21859_ = (_e2983 + 1i);
                                                        }
                                                    }
                                                    continue;
                                                } else {
                                                    break;
                                                }
                                                continuing {
                                                    let _e7822 = local_59;
                                                    phi_21856_ = _e7822;
                                                    phi_21853_ = (_e2978 + 1i);
                                                }
                                            }
                                            let _e3014 = local_43;
                                            phi_21863_ = (_e3014 * select(0.0069444445f, 0.0625f, _e2938));
                                            break;
                                        }
                                    }
                                    let _e3017 = phi_21863_;
                                    phi_21864_ = _e3017;
                                    break;
                                }
                                let _e3018 = (_e2799 - _e2839);
                                let _e3021 = global.member_21[3u];
                                if (_e3018 >= u32(_e3021)) {
                                    phi_21864_ = 1f;
                                    break;
                                }
                                let _e3026 = global.member_27[_e3018];
                                let _e3029 = global.member_28[_e3018];
                                let _e3031 = _e3026.xyz;
                                let _e3034 = (_e3026.w * length((_e810 - _e3031)));
                                let _e3037 = global.member_25[0u];
                                let _e3043 = global.member_25[1u];
                                let _e3047 = (((_e810 + (_e817 * (_e3034 * _e3037))) + (_e2813 * (_e3034 * _e3043))) - _e3031);
                                let _e3048 = abs(_e3047);
                                let _e3051 = (_e3048.x >= _e3048.y);
                                phi_9455_ = _e3051;
                                if _e3051 {
                                    phi_9455_ = (_e3048.x >= _e3048.z);
                                }
                                let _e3055 = phi_9455_;
                                if _e3055 {
                                    phi_21840_ = select(1i, 0i, (_e3047.x > 0f));
                                    phi_21838_ = _e3048.x;
                                } else {
                                    let _e3060 = (_e3048.y >= _e3048.z);
                                    if _e3060 {
                                        phi_21841_ = select(3i, 2i, (_e3047.y > 0f));
                                    } else {
                                        phi_21841_ = select(5i, 4i, (_e3047.z > 0f));
                                    }
                                    let _e3068 = phi_21841_;
                                    phi_21840_ = _e3068;
                                    phi_21838_ = select(_e3048.z, _e3048.y, _e3060);
                                }
                                let _e3071 = phi_21840_;
                                let _e3073 = phi_21838_;
                                if (_e3073 <= 0f) {
                                    phi_21864_ = 1f;
                                    break;
                                }
                                local_18 = array<vec3<f32>, 6>(vec3<f32>(0f, 0f, 1f), vec3<f32>(0f, 0f, -1f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(1f, 0f, 0f));
                                let _e3076 = local_18[_e3071];
                                local_19 = array<vec3<f32>, 6>(vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 0f, -1f), vec3<f32>(0f, 0f, 1f), vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 1f, 0f));
                                let _e3079 = local_19[_e3071];
                                let _e3084 = global.member_24[2u];
                                let _e3087 = (vec2<f32>(dot(_e3047, _e3076), dot(_e3047, _e3079)) / vec2((_e3073 * _e3084)));
                                let _e3091 = (_e3029.z + (_e3029.w / _e3073));
                                if (_e3091 > 1f) {
                                    phi_21864_ = 1f;
                                    break;
                                }
                                let _e3106 = global.member_24;
                                let _e3107 = _e3106.xy;
                                let _e3109 = (_e3029.xy + (vec2<f32>(f32((_e3071 - (i32(floor((f32(_e3071) / f32(3i)))) * 3i))), f32((_e3071 / 3i))) * _e3107));
                                let _e3118 = global.member_22;
                                let _e3119 = _e3118.xy;
                                let _e3120 = (_e3119 * 0.5f);
                                let _e3122 = (_e3109 + (vec2<f32>((0.5f + (0.5f * _e3087.x)), (0.5f - (0.5f * _e3087.y))) * _e3107));
                                let _e3123 = (_e3109 + _e3120);
                                let _e3125 = ((_e3109 + _e3107) - _e3120);
                                let _e3130 = vec4<f32>(_e3123.x, _e3123.y, _e3125.x, _e3125.y);
                                switch bitcast<i32>(0u) {
                                    default: {
                                        let _e3134 = global.member_22[2u];
                                        let _e3135 = i32(_e3134);
                                        if (_e3135 <= 0i) {
                                            let _e3139 = clamp(_e3122, _e3130.xy, _e3130.zw);
                                            let _e3144 = textureSampleCompare(global_2, global_1, vec3<f32>(_e3139.x, _e3139.y, _e3091).xy, _e3091);
                                            phi_21852_ = _e3144;
                                            break;
                                        }
                                        let _e3146 = ((_e3122 / _e3119) + vec2<f32>(0.5f, 0.5f));
                                        let _e3147 = floor(_e3146);
                                        let _e3148 = (_e3146 - _e3147);
                                        let _e3150 = (_e3135 == 1i);
                                        if _e3150 {
                                            let _e3151 = (_e3148 * 2f);
                                            local_14[0i] = (vec2<f32>(3f, 3f) - _e3151);
                                            local_14[1i] = (vec2<f32>(1f, 1f) + _e3151);
                                            let _e3157 = local_14[0i];
                                            local_15[0i] = (((vec2<f32>(2f, 2f) - _e3148) / _e3157) - vec2<f32>(1f, 1f));
                                            let _e3161 = local_14[1i];
                                            local_15[1i] = ((_e3148 / _e3161) + vec2<f32>(1f, 1f));
                                        } else {
                                            let _e3165 = (_e3148 * 3f);
                                            local_14[0i] = (vec2<f32>(4f, 4f) - _e3165);
                                            local_14[1i] = vec2<f32>(7f, 7f);
                                            local_14[2i] = (vec2<f32>(1f, 1f) + _e3165);
                                            let _e3173 = local_14[0i];
                                            local_15[0i] = (((vec2<f32>(3f, 3f) - (_e3148 * 2f)) / _e3173) - vec2<f32>(2f, 2f));
                                            let _e3178 = local_14[1i];
                                            local_15[1i] = ((vec2<f32>(3f, 3f) + _e3148) / _e3178);
                                            let _e3181 = local_14[2i];
                                            local_15[2i] = ((_e3148 / _e3181) + vec2<f32>(2f, 2f));
                                        }
                                        let _e3186 = select(3i, 2i, _e3150);
                                        phi_21845_ = 0f;
                                        phi_21842_ = 0i;
                                        loop {
                                            let _e3188 = phi_21845_;
                                            let _e3190 = phi_21842_;
                                            local_44 = _e3188;
                                            if (_e3190 < _e3186) {
                                                phi_21851_ = _e3188;
                                                phi_21848_ = 0i;
                                                loop {
                                                    let _e3193 = phi_21851_;
                                                    let _e3195 = phi_21848_;
                                                    local_60 = _e3193;
                                                    if (_e3195 < _e3186) {
                                                        continue;
                                                    } else {
                                                        break;
                                                    }
                                                    continuing {
                                                        let _e3199 = local_15[_e3195][0u];
                                                        let _e3202 = local_15[_e3190][1u];
                                                        let _e3208 = clamp((_e3119 * ((_e3147 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e3199, _e3202))), _e3130.xy, _e3130.zw);
                                                        let _e3211 = local_14[_e3195][0u];
                                                        let _e3214 = local_14[_e3190][1u];
                                                        let _e3220 = textureSampleCompare(global_2, global_1, vec3<f32>(_e3208.x, _e3208.y, _e3091).xy, _e3091);
                                                        phi_21851_ = (_e3193 + ((_e3211 * _e3214) * _e3220));
                                                        phi_21848_ = (_e3195 + 1i);
                                                    }
                                                }
                                                continue;
                                            } else {
                                                break;
                                            }
                                            continuing {
                                                let _e7834 = local_60;
                                                phi_21845_ = _e7834;
                                                phi_21842_ = (_e3190 + 1i);
                                            }
                                        }
                                        let _e3226 = local_44;
                                        phi_21852_ = (_e3226 * select(0.0069444445f, 0.0625f, _e3150));
                                        break;
                                    }
                                }
                                let _e3229 = phi_21852_;
                                phi_21864_ = _e3229;
                                break;
                            }
                        }
                        let _e3231 = phi_21864_;
                        phi_21915_ = (_e2834 * _e3231);
                    }
                    let _e3234 = phi_21915_;
                    let _e3235 = dot(_e802, _e2813);
                    local_58 = (_e2781 + (((_e1235 * max(_e3235, 0f)) * _e3234) + (_e3234 * ((pow(max(dot(_e802, normalize((_e2813 + _e812))), 0f), _e1273) * _e1277) * step(0f, _e3235)))));
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e7814 = local_58;
                    phi_21700_ = _e7814;
                    phi_21696_ = (_e2783 + bitcast<u32>(1i));
                }
            }
            let _e7844 = local_61;
            phi_21698_ = _e7844;
        }
        let _e3253 = phi_21698_;
        phi_21697_ = _e3253;
    } else {
        let _e3254 = textureSample(global_26, global_5, _e281);
        let _e3257 = global_8.member_4[0u];
        let _e3260 = clamp((_e3257 * _e3254.z), 0f, 1f);
        let _e3263 = global_8.member_4[1u];
        let _e3266 = clamp((_e3263 * _e3254.y), 0.045f, 1f);
        phi_21015_ = _e3260;
        phi_21010_ = _e3266;
        if (_e719 > 0f) {
            phi_21015_ = mix(_e3260, _e717.y, _e719);
            phi_21010_ = mix(_e3266, max(_e717.x, 0.045f), _e719);
        }
        let _e3274 = phi_21015_;
        let _e3276 = phi_21010_;
        let _e3277 = (_e3276 * _e3276);
        let _e3279 = (_e1235 * (1f - _e3274));
        let _e3281 = mix(vec3<f32>(0.04f, 0.04f, 0.04f), _e1235, vec3(_e3274));
        let _e3282 = (_e793 > 0f);
        phi_21043_ = _e802;
        if _e3282 {
            let _e3283 = dpdx(_e810);
            let _e3284 = dpdy(_e810);
            let _e3285 = cross(_e3283, _e3284);
            phi_21044_ = _e802;
            if (dot(_e3285, _e3285) > 0.00000000000000000001f) {
                phi_21044_ = normalize(((normalize(_e3285) * select(1f, -1f, (dot(_e3285, _e812) < 0f))) + (_e802 - _e723)));
            }
            let _e3297 = phi_21044_;
            phi_21043_ = _e3297;
        }
        let _e3299 = phi_21043_;
        let _e3301 = max(dot(_e3299, _e812), 0.0001f);
        let _e3304 = dot(_e3299, _e806);
        let _e3305 = clamp(_e3304, 0f, 1f);
        let _e3307 = clamp(dot(_e3299, _e814), 0f, 1f);
        let _e3309 = clamp(dot(_e812, _e814), 0f, 1f);
        phi_21048_ = _e3301;
        phi_21047_ = _e3309;
        if _e3282 {
            phi_21048_ = max(_e3301, 0.5f);
            phi_21047_ = max(_e3309, 0.5f);
        }
        let _e3313 = phi_21048_;
        let _e3315 = phi_21047_;
        let _e3318 = (vec3<f32>(1f, 1f, 1f) - _e3281);
        let _e3320 = (_e3281 + (_e3318 * pow((1f - _e3315), 5f)));
        let _e3321 = (_e3277 * _e3277);
        let _e3323 = (_e3321 - 1f);
        let _e3325 = (((_e3307 * _e3307) * _e3323) + 1f);
        let _e3330 = (1f - _e3321);
        let _e3333 = sqrt((((_e3313 * _e3313) * _e3330) + _e3321));
        let _e3352 = ((((((vec3<f32>(1f, 1f, 1f) - _e3320) * _e3279) * clamp(dot(_e802, _e806), 0f, 1f)) + (((_e3320 * ((_e3321 / ((3.1415927f * _e3325) * _e3325)) * (0.5f / max(((_e3305 * _e3333) + (_e3313 * sqrt((((_e3305 * _e3305) * _e3330) + _e3321)))), 0.00001f)))) * 3.1415927f) * _e3305)) * _e1242) * _e1233);
        phi_21158_ = _e3352;
        if _e3282 {
            phi_21158_ = (_e3352 + (((((_e3279 * _e1242) * _e1233) * _e793) * clamp(-(_e3304), 0f, 1f)) * (0.35f + (0.65f * pow(clamp(dot(-(_e812), _e806), 0f, 1f), 3f)))));
        }
        let _e3368 = phi_21158_;
        let _e3371 = global.member_29[0u];
        let _e3372 = (_e3371 > 0.5f);
        if _e3372 {
            let _e3377 = textureSample(global_6, global_7, (((vec2<f32>(_e3313, _e3276) * 31f) + vec2<f32>(0.5f, 0.5f)) * vec2<f32>(0.03125f, 0.03125f)));
            let _e3380 = global.member_29;
            let _e3387 = ((_e3380.z * _e802.x) - (_e3380.w * _e802.z));
            let _e3391 = ((_e3380.w * _e802.x) + (_e3380.z * _e802.z));
            let _e3395 = (1.092548f * _e3387);
            local_13 = array<f32, 9>(0.282095f, (0.488603f * _e802.y), (0.488603f * _e3391), (0.488603f * _e3387), (_e3395 * _e802.y), ((1.092548f * _e802.y) * _e3391), (0.315392f * (((3f * _e3391) * _e3391) - 1f)), (_e3395 * _e3391), (0.546274f * ((_e3387 * _e3387) - (_e802.y * _e802.y))));
            phi_21066_ = vec3<f32>(0f, 0f, 0f);
            phi_21065_ = 0i;
            loop {
                let _e3410 = phi_21066_;
                let _e3412 = phi_21065_;
                local_45 = _e3410;
                if (_e3412 < 9i) {
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e3416 = textureLoad(global_4, (vec2<i32>(496i, 256i) + vec2<i32>(_e3412, 0i)), 0i);
                    let _e3419 = local_13[_e3412];
                    phi_21066_ = (_e3410 + (_e3416.xyz * _e3419));
                    phi_21065_ = (_e3412 + 1i);
                }
            }
            let _e3424 = local_45;
            let _e3428 = global.member_29[1u];
            let _e3431 = reflect(-(_e812), _e3299);
            let _e3448 = vec2<f32>(((atan2(((_e3380.z * _e3431.x) - (_e3380.w * _e3431.z)), -(((_e3380.w * _e3431.x) + (_e3380.z * _e3431.z)))) * 0.15915494f) + 0.5f), (acos(clamp(_e3431.y, -1f, 1f)) * 0.31830987f));
            let _e3449 = (_e3276 * 5f);
            let _e3451 = min(i32(_e3449), 4i);
            local_11 = array<vec4<i32>, 6>(vec4<i32>(0i, 0i, 512i, 256i), vec4<i32>(0i, 256i, 256i, 128i), vec4<i32>(256i, 256i, 128i, 64i), vec4<i32>(384i, 256i, 64i, 32i), vec4<i32>(448i, 256i, 32i, 16i), vec4<i32>(480i, 256i, 16i, 8i));
            let _e3453 = local_11[_e3451];
            let _e3457 = ((_e3448 * vec2<f32>(_e3453.zw)) - vec2<f32>(0.5f, 0.5f));
            let _e3458 = floor(_e3457);
            let _e3459 = (_e3457 - _e3458);
            let _e3461 = i32(_e3458.x);
            let _e3463 = i32(_e3458.y);
            phi_21069_ = _e3461;
            if (_e3461 < 0i) {
                phi_21069_ = (_e3461 + _e3453.z);
            }
            let _e3468 = phi_21069_;
            phi_21070_ = _e3468;
            if (_e3468 >= _e3453.z) {
                phi_21070_ = (_e3468 - _e3453.z);
            }
            let _e3473 = phi_21070_;
            let _e3474 = (_e3473 + 1i);
            let _e3476 = select(_e3474, 0i, (_e3474 == _e3453.z));
            let _e3480 = min((_e3463 + 1i), (_e3453.w - 1i));
            let _e3481 = max(_e3463, 0i);
            let _e3482 = _e3453.xy;
            let _e3485 = textureLoad(global_4, (_e3482 + vec2<i32>(_e3473, _e3481)), 0i);
            let _e3489 = textureLoad(global_4, (_e3482 + vec2<i32>(_e3476, _e3481)), 0i);
            let _e3493 = textureLoad(global_4, (_e3482 + vec2<i32>(_e3473, _e3480)), 0i);
            let _e3497 = textureLoad(global_4, (_e3482 + vec2<i32>(_e3476, _e3480)), 0i);
            let _e3500 = vec3(_e3459.x);
            local_12 = array<vec4<i32>, 6>(vec4<i32>(0i, 0i, 512i, 256i), vec4<i32>(0i, 256i, 256i, 128i), vec4<i32>(256i, 256i, 128i, 64i), vec4<i32>(384i, 256i, 64i, 32i), vec4<i32>(448i, 256i, 32i, 16i), vec4<i32>(480i, 256i, 16i, 8i));
            let _e3508 = local_12[(_e3451 + 1i)];
            let _e3512 = ((_e3448 * vec2<f32>(_e3508.zw)) - vec2<f32>(0.5f, 0.5f));
            let _e3513 = floor(_e3512);
            let _e3514 = (_e3512 - _e3513);
            let _e3516 = i32(_e3513.x);
            let _e3518 = i32(_e3513.y);
            phi_21076_ = _e3516;
            if (_e3516 < 0i) {
                phi_21076_ = (_e3516 + _e3508.z);
            }
            let _e3523 = phi_21076_;
            phi_21077_ = _e3523;
            if (_e3523 >= _e3508.z) {
                phi_21077_ = (_e3523 - _e3508.z);
            }
            let _e3528 = phi_21077_;
            let _e3529 = (_e3528 + 1i);
            let _e3531 = select(_e3529, 0i, (_e3529 == _e3508.z));
            let _e3535 = min((_e3518 + 1i), (_e3508.w - 1i));
            let _e3536 = max(_e3518, 0i);
            let _e3537 = _e3508.xy;
            let _e3540 = textureLoad(global_4, (_e3537 + vec2<i32>(_e3528, _e3536)), 0i);
            let _e3544 = textureLoad(global_4, (_e3537 + vec2<i32>(_e3531, _e3536)), 0i);
            let _e3548 = textureLoad(global_4, (_e3537 + vec2<i32>(_e3528, _e3535)), 0i);
            let _e3552 = textureLoad(global_4, (_e3537 + vec2<i32>(_e3531, _e3535)), 0i);
            let _e3555 = vec3(_e3514.x);
            phi_21120_ = (max(_e3424, vec3<f32>(0f, 0f, 0f)) * _e3428);
            phi_21108_ = _e3377.xy;
            phi_21084_ = (mix(mix(mix(_e3485.xyz, _e3489.xyz, _e3500), mix(_e3493.xyz, _e3497.xyz, _e3500), vec3(_e3459.y)), mix(mix(_e3540.xyz, _e3544.xyz, _e3555), mix(_e3548.xyz, _e3552.xyz, _e3555), vec3(_e3514.y)), vec3((_e3449 - f32(_e3451)))) * _e3428);
        } else {
            let _e3567 = ((vec4<f32>(-1f, -0.0275f, -0.572f, 0.022f) * _e3276) + vec4<f32>(1f, 0.0425f, 1.04f, -0.04f));
            let _e3580 = global.member_9;
            let _e3581 = _e3580.xyz;
            let _e3583 = global.member_8;
            let _e3584 = _e3583.xyz;
            let _e3592 = global.member_8[3u];
            let _e3593 = (mix(_e3581, _e3584, vec3(((_e802.y * 0.5f) + 0.5f))) * _e3592);
            phi_21120_ = _e3593;
            phi_21108_ = ((vec2<f32>(-1.04f, 1.04f) * ((min((_e3567.x * _e3567.x), exp2((-9.28f * _e3313))) * _e3567.x) + _e3567.y)) + _e3567.zw);
            phi_21084_ = mix((mix(_e3581, _e3584, vec3(((reflect(-(_e812), _e3299).y * 0.5f) + 0.5f))) * _e3592), _e3593, vec3(_e3276));
        }
        let _e3605 = phi_21120_;
        let _e3607 = phi_21108_;
        let _e3609 = phi_21084_;
        phi_4136_ = _e1246;
        if _e1246 {
            let _e3612 = global.member_33[2u];
            phi_4136_ = (_e3612 > 0.5f);
        }
        let _e3615 = phi_4136_;
        phi_21129_ = _e3609;
        if _e3615 {
            switch bitcast<i32>(0u) {
                default: {
                    let _e3618 = global.member_31;
                    let _e3619 = _e3618.xyz;
                    let _e3622 = global.member_33[0u];
                    let _e3627 = global.member_31[3u];
                    let _e3636 = global.member_32[1u];
                    let _e3642 = global.member_32[0u];
                    let _e3645 = (((_e3642 * (1f - smoothstep((_e3622 * 0.5f), _e3622, abs((dot(_e3619, _e810) - _e3627))))) * smoothstep(0.5f, 0.9f, dot(_e817, _e3619))) * (1f - smoothstep((_e3636 * 0.5f), _e3636, _e3276)));
                    if (_e3645 <= 0f) {
                        phi_21105_ = _e3609;
                        break;
                    }
                    let _e3652 = global.member_32[3u];
                    let _e3654 = (_e810 + ((_e802 - (_e3619 * dot(_e802, _e3619))) * _e3652));
                    let _e3656 = global.member_30;
                    let _e3661 = (_e3656 * vec4<f32>(_e3654.x, _e3654.y, _e3654.z, 1f));
                    let _e3673 = global.member_32[2u];
                    phi_21104_ = 0f;
                    phi_21103_ = vec3<f32>(0f, 0f, 0f);
                    phi_21102_ = 0i;
                    loop {
                        let _e3676 = phi_21104_;
                        let _e3678 = phi_21103_;
                        let _e3680 = phi_21102_;
                        local_46 = _e3678;
                        local_47 = _e3676;
                        if (_e3680 < 12i) {
                            continue;
                        } else {
                            break;
                        }
                        continuing {
                            let _e3682 = f32(_e3680);
                            let _e3687 = (_e3682 * 2.3999631f);
                            let _e3691 = global.member_33[1u];
                            let _e3696 = ((((vec2<f32>(_e3661.x, -(_e3661.y)) / vec2(_e3661.w)) * 0.5f) + vec2<f32>(0.5f, 0.5f)) + (vec2<f32>((cos(_e3687) * _e3691), sin(_e3687)) * (sqrt(((_e3682 + 0.5f) * 0.083333336f)) * (_e3673 * _e3276))));
                            let _e3698 = min(_e3696, (vec2<f32>(1f, 1f) - _e3696));
                            let _e3702 = smoothstep(0f, 0.04f, min(_e3698.x, _e3698.y));
                            let _e3704 = textureSampleLevel(global_19, global_5, clamp(_e3696, vec2<f32>(0f, 0f), vec2<f32>(1f, 1f)), 0f);
                            let _e3705 = _e3704.xyz;
                            phi_21104_ = (_e3676 + (_e3704.w * _e3702));
                            phi_21103_ = (_e3678 + ((_e3705 / (vec3<f32>(1f, 1f, 1f) - min(_e3705, vec3<f32>(0.995f, 0.995f, 0.995f)))) * _e3702));
                            phi_21102_ = (_e3680 + 1i);
                        }
                    }
                    let _e3716 = local_46;
                    let _e3719 = local_47;
                    phi_21105_ = mix(_e3609, ((_e3716 * vec3<f32>(0.083333336f, 0.083333336f, 0.083333336f)) + (_e3609 * (1f - (_e3719 * 0.083333336f)))), vec3(_e3645));
                    break;
                }
            }
            let _e3727 = phi_21105_;
            phi_21129_ = _e3727;
        }
        let _e3729 = phi_21129_;
        let _e3734 = ((_e3281 * _e3607.x) + vec3(_e3607.y));
        let _e3736 = ((vec3<f32>(1f, 1f, 1f) - _e3734) * _e3279);
        let _e3741 = (_e3368 + (((_e3736 * _e3605) + (_e3734 * _e3729)) * _e1264));
        let _e3744 = global.member_34[0u];
        let _e3747 = global.member_34[1u];
        phi_21631_ = _e3741;
        if ((_e3744 + _e3747) > 0.5f) {
            if (_e3747 > 0.5f) {
                phi_21165_ = _e3605;
                phi_21164_ = 0i;
                loop {
                    let _e3754 = phi_21165_;
                    let _e3756 = phi_21164_;
                    local_62 = _e3754;
                    if (_e3756 < i32(_e3747)) {
                        let _e3759 = (8i * (i32(_e3744) + _e3756));
                        let _e3763 = global_3.member[(_e3759 + 3i)];
                        let _e3764 = bitcast<vec4<f32>>(_e3763);
                        let _e3767 = global_3.member[_e3759];
                        let _e3768 = bitcast<vec4<f32>>(_e3767);
                        let _e3772 = global_3.member[(_e3759 + 1i)];
                        let _e3773 = bitcast<vec4<f32>>(_e3772);
                        let _e3777 = global_3.member[(_e3759 + 2i)];
                        let _e3778 = bitcast<vec4<f32>>(_e3777);
                        let _e3779 = _e3768.xyz;
                        let _e3783 = _e3773.xyz;
                        let _e3787 = _e3778.xyz;
                        let _e3791 = vec3<f32>((dot(_e3779, _e810) + _e3768.w), (dot(_e3783, _e810) + _e3773.w), (dot(_e3787, _e810) + _e3778.w));
                        let _e3792 = _e3764.xyz;
                        switch bitcast<i32>(0u) {
                            default: {
                                let _e3796 = (_e3792 - abs(_e3791));
                                let _e3801 = min(_e3796.x, min(_e3796.y, _e3796.z));
                                if (_e3801 <= 0f) {
                                    phi_21665_ = 0f;
                                    break;
                                }
                                if (_e3764.w <= 0f) {
                                    phi_21665_ = 1f;
                                    break;
                                }
                                let _e3805 = min((_e3801 / _e3764.w), 1f);
                                phi_21665_ = ((_e3805 * _e3805) * (3f - (2f * _e3805)));
                                break;
                            }
                        }
                        let _e3811 = phi_21665_;
                        if (_e3811 <= 0f) {
                            phi_21957_ = _e3754;
                            continue;
                        }
                        let _e3816 = global_3.member[(_e3759 + 4i)];
                        let _e3818 = bitcast<vec4<f32>>(_e3816).xyz;
                        let _e3822 = global_3.member[(_e3759 + 5i)];
                        let _e3823 = bitcast<vec4<f32>>(_e3822);
                        let _e3828 = global_3.member[(_e3759 + 6i)][0u];
                        let _e3829 = bitcast<i32>(_e3828);
                        let _e3830 = dot(_e3779, _e802);
                        let _e3831 = dot(_e3783, _e802);
                        let _e3832 = dot(_e3787, _e802);
                        let _e3833 = vec3<f32>(_e3830, _e3831, _e3832);
                        let _e3839 = ((_e810 + (_e802 * _e3823.x)) + (_e812 * _e3823.y));
                        let _e3854 = clamp(((((vec3<f32>((dot(_e3779, _e3839) + _e3768.w), (dot(_e3783, _e3839) + _e3773.w), (dot(_e3787, _e3839) + _e3778.w)) + _e3792) / max((_e3792 * 2f), vec3<f32>(0.000001f, 0.000001f, 0.000001f))) * _e3818) - vec3<f32>(0.5f, 0.5f, 0.5f)), vec3<f32>(0f, 0f, 0f), (_e3818 - vec3<f32>(1f, 1f, 1f)));
                        let _e3855 = vec3<i32>(_e3818);
                        let _e3859 = min(vec3<i32>(_e3854), max((_e3855 - vec3<i32>(2i, 2i, 2i)), vec3<i32>(0i, 0i, 0i)));
                        let _e3861 = (_e3854 - vec3<f32>(_e3859));
                        let _e3862 = (0.488603f * _e3831);
                        let _e3863 = (0.488603f * _e3832);
                        let _e3864 = (0.488603f * _e3830);
                        let _e3865 = (1.092548f * _e3830);
                        let _e3866 = (_e3865 * _e3831);
                        let _e3868 = ((1.092548f * _e3831) * _e3832);
                        let _e3872 = (0.315392f * (((3f * _e3832) * _e3832) - 1f));
                        let _e3873 = (_e3865 * _e3832);
                        let _e3877 = (0.546274f * ((_e3830 * _e3830) - (_e3831 * _e3831)));
                        let _e3878 = (_e3855 - vec3<i32>(1i, 1i, 1i));
                        let _e3879 = min(_e3859, _e3878);
                        let _e3890 = (_e3829 + ((_e3879.x + (_e3855.x * (_e3879.y + (_e3855.y * _e3879.z)))) * 4i));
                        let _e3891 = (vec3<f32>(1f, 1f, 1f) - _e3861);
                        let _e3898 = ((((((vec3<f32>(_e3879) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e3818) * _e3792) * 2f) - _e3792) - _e3791);
                        let _e3904 = (dot((_e3898 * inverseSqrt(max(dot(_e3898, _e3898), 0.0000000001f))), _e3833) + 1f);
                        let _e3907 = (_e3891.x * _e3891.y);
                        let _e3914 = (_e3890 + 3i);
                        let _e3918 = global_3.member[_e3914][1u];
                        let _e3923 = (((_e3907 * _e3891.z) * ((0.25f * (_e3904 * _e3904)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e3918).y > 0.5f)));
                        let _e3926 = global_3.member[_e3890];
                        let _e3930 = global_3.member[(_e3890 + 1i)];
                        let _e3934 = global_3.member[(_e3890 + 2i)];
                        let _e3937 = global_3.member[_e3914];
                        let _e3939 = unpack2x16float(_e3926.x);
                        let _e3941 = unpack2x16float(_e3926.y);
                        let _e3943 = unpack2x16float(_e3926.z);
                        let _e3945 = unpack2x16float(_e3926.w);
                        let _e3947 = unpack2x16float(_e3930.x);
                        let _e3949 = unpack2x16float(_e3930.y);
                        let _e3951 = unpack2x16float(_e3930.z);
                        let _e3953 = unpack2x16float(_e3930.w);
                        let _e3955 = unpack2x16float(_e3934.x);
                        let _e3957 = unpack2x16float(_e3934.y);
                        let _e3959 = unpack2x16float(_e3934.z);
                        let _e3961 = unpack2x16float(_e3934.w);
                        let _e3963 = unpack2x16float(_e3937.x);
                        let _e4019 = ((((((((((vec3<f32>(_e3939.x, _e3939.y, _e3941.x) * 0.282095f) + (vec3<f32>(_e3941.y, _e3943.x, _e3943.y) * _e3862)) + (vec3<f32>(_e3945.x, _e3945.y, _e3947.x) * _e3863)) + (vec3<f32>(_e3947.y, _e3949.x, _e3949.y) * _e3864)) + (vec3<f32>(_e3951.x, _e3951.y, _e3953.x) * _e3866)) + (vec3<f32>(_e3953.y, _e3955.x, _e3955.y) * _e3868)) + (vec3<f32>(_e3957.x, _e3957.y, _e3959.x) * _e3872)) + (vec3<f32>(_e3959.y, _e3961.x, _e3961.y) * _e3873)) + (vec3<f32>(_e3963.x, _e3963.y, unpack2x16float(_e3937.y).x) * _e3877)) * _e3923);
                        let _e4025 = min((_e3859 + vec3<i32>(1i, 0i, 0i)), _e3878);
                        let _e4034 = (_e3829 + ((_e4025.x + (_e3855.x * (_e4025.y + (_e3855.y * _e4025.z)))) * 4i));
                        let _e4041 = ((((((vec3<f32>(_e4025) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e3818) * _e3792) * 2f) - _e3792) - _e3791);
                        let _e4047 = (dot((_e4041 * inverseSqrt(max(dot(_e4041, _e4041), 0.0000000001f))), _e3833) + 1f);
                        let _e4049 = (_e3861.x * _e3891.y);
                        let _e4055 = (_e4034 + 3i);
                        let _e4059 = global_3.member[_e4055][1u];
                        let _e4064 = (((_e4049 * _e3891.z) * ((0.25f * (_e4047 * _e4047)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e4059).y > 0.5f)));
                        let _e4067 = global_3.member[_e4034];
                        let _e4071 = global_3.member[(_e4034 + 1i)];
                        let _e4075 = global_3.member[(_e4034 + 2i)];
                        let _e4078 = global_3.member[_e4055];
                        let _e4080 = unpack2x16float(_e4067.x);
                        let _e4082 = unpack2x16float(_e4067.y);
                        let _e4084 = unpack2x16float(_e4067.z);
                        let _e4086 = unpack2x16float(_e4067.w);
                        let _e4088 = unpack2x16float(_e4071.x);
                        let _e4090 = unpack2x16float(_e4071.y);
                        let _e4092 = unpack2x16float(_e4071.z);
                        let _e4094 = unpack2x16float(_e4071.w);
                        let _e4096 = unpack2x16float(_e4075.x);
                        let _e4098 = unpack2x16float(_e4075.y);
                        let _e4100 = unpack2x16float(_e4075.z);
                        let _e4102 = unpack2x16float(_e4075.w);
                        let _e4104 = unpack2x16float(_e4078.x);
                        let _e4160 = ((((((((((vec3<f32>(_e4080.x, _e4080.y, _e4082.x) * 0.282095f) + (vec3<f32>(_e4082.y, _e4084.x, _e4084.y) * _e3862)) + (vec3<f32>(_e4086.x, _e4086.y, _e4088.x) * _e3863)) + (vec3<f32>(_e4088.y, _e4090.x, _e4090.y) * _e3864)) + (vec3<f32>(_e4092.x, _e4092.y, _e4094.x) * _e3866)) + (vec3<f32>(_e4094.y, _e4096.x, _e4096.y) * _e3868)) + (vec3<f32>(_e4098.x, _e4098.y, _e4100.x) * _e3872)) + (vec3<f32>(_e4100.y, _e4102.x, _e4102.y) * _e3873)) + (vec3<f32>(_e4104.x, _e4104.y, unpack2x16float(_e4078.y).x) * _e3877)) * _e4064);
                        let _e4167 = min((_e3859 + vec3<i32>(0i, 1i, 0i)), _e3878);
                        let _e4176 = (_e3829 + ((_e4167.x + (_e3855.x * (_e4167.y + (_e3855.y * _e4167.z)))) * 4i));
                        let _e4183 = ((((((vec3<f32>(_e4167) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e3818) * _e3792) * 2f) - _e3792) - _e3791);
                        let _e4189 = (dot((_e4183 * inverseSqrt(max(dot(_e4183, _e4183), 0.0000000001f))), _e3833) + 1f);
                        let _e4191 = (_e3891.x * _e3861.y);
                        let _e4197 = (_e4176 + 3i);
                        let _e4201 = global_3.member[_e4197][1u];
                        let _e4206 = (((_e4191 * _e3891.z) * ((0.25f * (_e4189 * _e4189)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e4201).y > 0.5f)));
                        let _e4209 = global_3.member[_e4176];
                        let _e4213 = global_3.member[(_e4176 + 1i)];
                        let _e4217 = global_3.member[(_e4176 + 2i)];
                        let _e4220 = global_3.member[_e4197];
                        let _e4222 = unpack2x16float(_e4209.x);
                        let _e4224 = unpack2x16float(_e4209.y);
                        let _e4226 = unpack2x16float(_e4209.z);
                        let _e4228 = unpack2x16float(_e4209.w);
                        let _e4230 = unpack2x16float(_e4213.x);
                        let _e4232 = unpack2x16float(_e4213.y);
                        let _e4234 = unpack2x16float(_e4213.z);
                        let _e4236 = unpack2x16float(_e4213.w);
                        let _e4238 = unpack2x16float(_e4217.x);
                        let _e4240 = unpack2x16float(_e4217.y);
                        let _e4242 = unpack2x16float(_e4217.z);
                        let _e4244 = unpack2x16float(_e4217.w);
                        let _e4246 = unpack2x16float(_e4220.x);
                        let _e4302 = ((((((((((vec3<f32>(_e4222.x, _e4222.y, _e4224.x) * 0.282095f) + (vec3<f32>(_e4224.y, _e4226.x, _e4226.y) * _e3862)) + (vec3<f32>(_e4228.x, _e4228.y, _e4230.x) * _e3863)) + (vec3<f32>(_e4230.y, _e4232.x, _e4232.y) * _e3864)) + (vec3<f32>(_e4234.x, _e4234.y, _e4236.x) * _e3866)) + (vec3<f32>(_e4236.y, _e4238.x, _e4238.y) * _e3868)) + (vec3<f32>(_e4240.x, _e4240.y, _e4242.x) * _e3872)) + (vec3<f32>(_e4242.y, _e4244.x, _e4244.y) * _e3873)) + (vec3<f32>(_e4246.x, _e4246.y, unpack2x16float(_e4220.y).x) * _e3877)) * _e4206);
                        let _e4309 = min((_e3859 + vec3<i32>(1i, 1i, 0i)), _e3878);
                        let _e4318 = (_e3829 + ((_e4309.x + (_e3855.x * (_e4309.y + (_e3855.y * _e4309.z)))) * 4i));
                        let _e4325 = ((((((vec3<f32>(_e4309) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e3818) * _e3792) * 2f) - _e3792) - _e3791);
                        let _e4331 = (dot((_e4325 * inverseSqrt(max(dot(_e4325, _e4325), 0.0000000001f))), _e3833) + 1f);
                        let _e4332 = (_e3861.x * _e3861.y);
                        let _e4338 = (_e4318 + 3i);
                        let _e4342 = global_3.member[_e4338][1u];
                        let _e4347 = (((_e4332 * _e3891.z) * ((0.25f * (_e4331 * _e4331)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e4342).y > 0.5f)));
                        let _e4350 = global_3.member[_e4318];
                        let _e4354 = global_3.member[(_e4318 + 1i)];
                        let _e4358 = global_3.member[(_e4318 + 2i)];
                        let _e4361 = global_3.member[_e4338];
                        let _e4363 = unpack2x16float(_e4350.x);
                        let _e4365 = unpack2x16float(_e4350.y);
                        let _e4367 = unpack2x16float(_e4350.z);
                        let _e4369 = unpack2x16float(_e4350.w);
                        let _e4371 = unpack2x16float(_e4354.x);
                        let _e4373 = unpack2x16float(_e4354.y);
                        let _e4375 = unpack2x16float(_e4354.z);
                        let _e4377 = unpack2x16float(_e4354.w);
                        let _e4379 = unpack2x16float(_e4358.x);
                        let _e4381 = unpack2x16float(_e4358.y);
                        let _e4383 = unpack2x16float(_e4358.z);
                        let _e4385 = unpack2x16float(_e4358.w);
                        let _e4387 = unpack2x16float(_e4361.x);
                        let _e4443 = ((((((((((vec3<f32>(_e4363.x, _e4363.y, _e4365.x) * 0.282095f) + (vec3<f32>(_e4365.y, _e4367.x, _e4367.y) * _e3862)) + (vec3<f32>(_e4369.x, _e4369.y, _e4371.x) * _e3863)) + (vec3<f32>(_e4371.y, _e4373.x, _e4373.y) * _e3864)) + (vec3<f32>(_e4375.x, _e4375.y, _e4377.x) * _e3866)) + (vec3<f32>(_e4377.y, _e4379.x, _e4379.y) * _e3868)) + (vec3<f32>(_e4381.x, _e4381.y, _e4383.x) * _e3872)) + (vec3<f32>(_e4383.y, _e4385.x, _e4385.y) * _e3873)) + (vec3<f32>(_e4387.x, _e4387.y, unpack2x16float(_e4361.y).x) * _e3877)) * _e4347);
                        let _e4450 = min((_e3859 + vec3<i32>(0i, 0i, 1i)), _e3878);
                        let _e4459 = (_e3829 + ((_e4450.x + (_e3855.x * (_e4450.y + (_e3855.y * _e4450.z)))) * 4i));
                        let _e4466 = ((((((vec3<f32>(_e4450) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e3818) * _e3792) * 2f) - _e3792) - _e3791);
                        let _e4472 = (dot((_e4466 * inverseSqrt(max(dot(_e4466, _e4466), 0.0000000001f))), _e3833) + 1f);
                        let _e4479 = (_e4459 + 3i);
                        let _e4483 = global_3.member[_e4479][1u];
                        let _e4488 = (((_e3907 * _e3861.z) * ((0.25f * (_e4472 * _e4472)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e4483).y > 0.5f)));
                        let _e4491 = global_3.member[_e4459];
                        let _e4495 = global_3.member[(_e4459 + 1i)];
                        let _e4499 = global_3.member[(_e4459 + 2i)];
                        let _e4502 = global_3.member[_e4479];
                        let _e4504 = unpack2x16float(_e4491.x);
                        let _e4506 = unpack2x16float(_e4491.y);
                        let _e4508 = unpack2x16float(_e4491.z);
                        let _e4510 = unpack2x16float(_e4491.w);
                        let _e4512 = unpack2x16float(_e4495.x);
                        let _e4514 = unpack2x16float(_e4495.y);
                        let _e4516 = unpack2x16float(_e4495.z);
                        let _e4518 = unpack2x16float(_e4495.w);
                        let _e4520 = unpack2x16float(_e4499.x);
                        let _e4522 = unpack2x16float(_e4499.y);
                        let _e4524 = unpack2x16float(_e4499.z);
                        let _e4526 = unpack2x16float(_e4499.w);
                        let _e4528 = unpack2x16float(_e4502.x);
                        let _e4584 = ((((((((((vec3<f32>(_e4504.x, _e4504.y, _e4506.x) * 0.282095f) + (vec3<f32>(_e4506.y, _e4508.x, _e4508.y) * _e3862)) + (vec3<f32>(_e4510.x, _e4510.y, _e4512.x) * _e3863)) + (vec3<f32>(_e4512.y, _e4514.x, _e4514.y) * _e3864)) + (vec3<f32>(_e4516.x, _e4516.y, _e4518.x) * _e3866)) + (vec3<f32>(_e4518.y, _e4520.x, _e4520.y) * _e3868)) + (vec3<f32>(_e4522.x, _e4522.y, _e4524.x) * _e3872)) + (vec3<f32>(_e4524.y, _e4526.x, _e4526.y) * _e3873)) + (vec3<f32>(_e4528.x, _e4528.y, unpack2x16float(_e4502.y).x) * _e3877)) * _e4488);
                        let _e4591 = min((_e3859 + vec3<i32>(1i, 0i, 1i)), _e3878);
                        let _e4600 = (_e3829 + ((_e4591.x + (_e3855.x * (_e4591.y + (_e3855.y * _e4591.z)))) * 4i));
                        let _e4607 = ((((((vec3<f32>(_e4591) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e3818) * _e3792) * 2f) - _e3792) - _e3791);
                        let _e4613 = (dot((_e4607 * inverseSqrt(max(dot(_e4607, _e4607), 0.0000000001f))), _e3833) + 1f);
                        let _e4619 = (_e4600 + 3i);
                        let _e4623 = global_3.member[_e4619][1u];
                        let _e4628 = (((_e4049 * _e3861.z) * ((0.25f * (_e4613 * _e4613)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e4623).y > 0.5f)));
                        let _e4631 = global_3.member[_e4600];
                        let _e4635 = global_3.member[(_e4600 + 1i)];
                        let _e4639 = global_3.member[(_e4600 + 2i)];
                        let _e4642 = global_3.member[_e4619];
                        let _e4644 = unpack2x16float(_e4631.x);
                        let _e4646 = unpack2x16float(_e4631.y);
                        let _e4648 = unpack2x16float(_e4631.z);
                        let _e4650 = unpack2x16float(_e4631.w);
                        let _e4652 = unpack2x16float(_e4635.x);
                        let _e4654 = unpack2x16float(_e4635.y);
                        let _e4656 = unpack2x16float(_e4635.z);
                        let _e4658 = unpack2x16float(_e4635.w);
                        let _e4660 = unpack2x16float(_e4639.x);
                        let _e4662 = unpack2x16float(_e4639.y);
                        let _e4664 = unpack2x16float(_e4639.z);
                        let _e4666 = unpack2x16float(_e4639.w);
                        let _e4668 = unpack2x16float(_e4642.x);
                        let _e4724 = ((((((((((vec3<f32>(_e4644.x, _e4644.y, _e4646.x) * 0.282095f) + (vec3<f32>(_e4646.y, _e4648.x, _e4648.y) * _e3862)) + (vec3<f32>(_e4650.x, _e4650.y, _e4652.x) * _e3863)) + (vec3<f32>(_e4652.y, _e4654.x, _e4654.y) * _e3864)) + (vec3<f32>(_e4656.x, _e4656.y, _e4658.x) * _e3866)) + (vec3<f32>(_e4658.y, _e4660.x, _e4660.y) * _e3868)) + (vec3<f32>(_e4662.x, _e4662.y, _e4664.x) * _e3872)) + (vec3<f32>(_e4664.y, _e4666.x, _e4666.y) * _e3873)) + (vec3<f32>(_e4668.x, _e4668.y, unpack2x16float(_e4642.y).x) * _e3877)) * _e4628);
                        let _e4731 = min((_e3859 + vec3<i32>(0i, 1i, 1i)), _e3878);
                        let _e4740 = (_e3829 + ((_e4731.x + (_e3855.x * (_e4731.y + (_e3855.y * _e4731.z)))) * 4i));
                        let _e4747 = ((((((vec3<f32>(_e4731) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e3818) * _e3792) * 2f) - _e3792) - _e3791);
                        let _e4753 = (dot((_e4747 * inverseSqrt(max(dot(_e4747, _e4747), 0.0000000001f))), _e3833) + 1f);
                        let _e4759 = (_e4740 + 3i);
                        let _e4763 = global_3.member[_e4759][1u];
                        let _e4768 = (((_e4191 * _e3861.z) * ((0.25f * (_e4753 * _e4753)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e4763).y > 0.5f)));
                        let _e4771 = global_3.member[_e4740];
                        let _e4775 = global_3.member[(_e4740 + 1i)];
                        let _e4779 = global_3.member[(_e4740 + 2i)];
                        let _e4782 = global_3.member[_e4759];
                        let _e4784 = unpack2x16float(_e4771.x);
                        let _e4786 = unpack2x16float(_e4771.y);
                        let _e4788 = unpack2x16float(_e4771.z);
                        let _e4790 = unpack2x16float(_e4771.w);
                        let _e4792 = unpack2x16float(_e4775.x);
                        let _e4794 = unpack2x16float(_e4775.y);
                        let _e4796 = unpack2x16float(_e4775.z);
                        let _e4798 = unpack2x16float(_e4775.w);
                        let _e4800 = unpack2x16float(_e4779.x);
                        let _e4802 = unpack2x16float(_e4779.y);
                        let _e4804 = unpack2x16float(_e4779.z);
                        let _e4806 = unpack2x16float(_e4779.w);
                        let _e4808 = unpack2x16float(_e4782.x);
                        let _e4864 = ((((((((((vec3<f32>(_e4784.x, _e4784.y, _e4786.x) * 0.282095f) + (vec3<f32>(_e4786.y, _e4788.x, _e4788.y) * _e3862)) + (vec3<f32>(_e4790.x, _e4790.y, _e4792.x) * _e3863)) + (vec3<f32>(_e4792.y, _e4794.x, _e4794.y) * _e3864)) + (vec3<f32>(_e4796.x, _e4796.y, _e4798.x) * _e3866)) + (vec3<f32>(_e4798.y, _e4800.x, _e4800.y) * _e3868)) + (vec3<f32>(_e4802.x, _e4802.y, _e4804.x) * _e3872)) + (vec3<f32>(_e4804.y, _e4806.x, _e4806.y) * _e3873)) + (vec3<f32>(_e4808.x, _e4808.y, unpack2x16float(_e4782.y).x) * _e3877)) * _e4768);
                        let _e4871 = min((_e3859 + vec3<i32>(1i, 1i, 1i)), _e3878);
                        let _e4880 = (_e3829 + ((_e4871.x + (_e3855.x * (_e4871.y + (_e3855.y * _e4871.z)))) * 4i));
                        let _e4887 = ((((((vec3<f32>(_e4871) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e3818) * _e3792) * 2f) - _e3792) - _e3791);
                        let _e4893 = (dot((_e4887 * inverseSqrt(max(dot(_e4887, _e4887), 0.0000000001f))), _e3833) + 1f);
                        let _e4899 = (_e4880 + 3i);
                        let _e4903 = global_3.member[_e4899][1u];
                        let _e4908 = (((_e4332 * _e3861.z) * ((0.25f * (_e4893 * _e4893)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e4903).y > 0.5f)));
                        let _e4911 = global_3.member[_e4880];
                        let _e4915 = global_3.member[(_e4880 + 1i)];
                        let _e4919 = global_3.member[(_e4880 + 2i)];
                        let _e4922 = global_3.member[_e4899];
                        let _e4924 = unpack2x16float(_e4911.x);
                        let _e4926 = unpack2x16float(_e4911.y);
                        let _e4928 = unpack2x16float(_e4911.z);
                        let _e4930 = unpack2x16float(_e4911.w);
                        let _e4932 = unpack2x16float(_e4915.x);
                        let _e4934 = unpack2x16float(_e4915.y);
                        let _e4936 = unpack2x16float(_e4915.z);
                        let _e4938 = unpack2x16float(_e4915.w);
                        let _e4940 = unpack2x16float(_e4919.x);
                        let _e4942 = unpack2x16float(_e4919.y);
                        let _e4944 = unpack2x16float(_e4919.z);
                        let _e4946 = unpack2x16float(_e4919.w);
                        let _e4948 = unpack2x16float(_e4922.x);
                        let _e5004 = ((((((((((vec3<f32>(_e4924.x, _e4924.y, _e4926.x) * 0.282095f) + (vec3<f32>(_e4926.y, _e4928.x, _e4928.y) * _e3862)) + (vec3<f32>(_e4930.x, _e4930.y, _e4932.x) * _e3863)) + (vec3<f32>(_e4932.y, _e4934.x, _e4934.y) * _e3864)) + (vec3<f32>(_e4936.x, _e4936.y, _e4938.x) * _e3866)) + (vec3<f32>(_e4938.y, _e4940.x, _e4940.y) * _e3868)) + (vec3<f32>(_e4942.x, _e4942.y, _e4944.x) * _e3872)) + (vec3<f32>(_e4944.y, _e4946.x, _e4946.y) * _e3873)) + (vec3<f32>(_e4948.x, _e4948.y, unpack2x16float(_e4922.y).x) * _e3877)) * _e4908);
                        let _e5009 = (((((((vec4<f32>(_e4019.x, _e4019.y, _e4019.z, _e3923) + vec4<f32>(_e4160.x, _e4160.y, _e4160.z, _e4064)) + vec4<f32>(_e4302.x, _e4302.y, _e4302.z, _e4206)) + vec4<f32>(_e4443.x, _e4443.y, _e4443.z, _e4347)) + vec4<f32>(_e4584.x, _e4584.y, _e4584.z, _e4488)) + vec4<f32>(_e4724.x, _e4724.y, _e4724.z, _e4628)) + vec4<f32>(_e4864.x, _e4864.y, _e4864.z, _e4768)) + vec4<f32>(_e5004.x, _e5004.y, _e5004.z, _e4908));
                        phi_21958_ = _e3754;
                        if (_e5009.w > 0.00001f) {
                            phi_21958_ = mix(_e3754, ((max(_e5009.xyz, vec3<f32>(0f, 0f, 0f)) / vec3(_e5009.w)) * _e3823.z), vec3(_e3811));
                        }
                        let _e5021 = phi_21958_;
                        phi_21957_ = _e5021;
                        continue;
                    } else {
                        break;
                    }
                    continuing {
                        let _e5023 = phi_21957_;
                        phi_21165_ = _e5023;
                        phi_21164_ = (_e3756 + 1i);
                    }
                }
                let _e7877 = local_62;
                phi_21166_ = _e7877;
            } else {
                phi_21166_ = _e3605;
            }
            let _e5026 = phi_21166_;
            phi_21394_ = _e3729;
            if (_e3744 > 0.5f) {
                if _e3372 {
                    let _e5029 = reflect(-(_e812), _e3299);
                    let _e5031 = global.member_29;
                    let _e5050 = vec2<f32>(((atan2(((_e5031.z * _e5029.x) - (_e5031.w * _e5029.z)), -(((_e5031.w * _e5029.x) + (_e5031.z * _e5029.z)))) * 0.15915494f) + 0.5f), (acos(clamp(_e5029.y, -1f, 1f)) * 0.31830987f));
                    let _e5051 = (_e3276 * 5f);
                    let _e5053 = min(i32(_e5051), 4i);
                    local_9 = array<vec4<i32>, 6>(vec4<i32>(0i, 0i, 512i, 256i), vec4<i32>(0i, 256i, 256i, 128i), vec4<i32>(256i, 256i, 128i, 64i), vec4<i32>(384i, 256i, 64i, 32i), vec4<i32>(448i, 256i, 32i, 16i), vec4<i32>(480i, 256i, 16i, 8i));
                    let _e5055 = local_9[_e5053];
                    let _e5059 = ((_e5050 * vec2<f32>(_e5055.zw)) - vec2<f32>(0.5f, 0.5f));
                    let _e5060 = floor(_e5059);
                    let _e5061 = (_e5059 - _e5060);
                    let _e5063 = i32(_e5060.x);
                    let _e5065 = i32(_e5060.y);
                    phi_21189_ = _e5063;
                    if (_e5063 < 0i) {
                        phi_21189_ = (_e5063 + _e5055.z);
                    }
                    let _e5070 = phi_21189_;
                    phi_21190_ = _e5070;
                    if (_e5070 >= _e5055.z) {
                        phi_21190_ = (_e5070 - _e5055.z);
                    }
                    let _e5075 = phi_21190_;
                    let _e5076 = (_e5075 + 1i);
                    let _e5078 = select(_e5076, 0i, (_e5076 == _e5055.z));
                    let _e5082 = min((_e5065 + 1i), (_e5055.w - 1i));
                    let _e5083 = max(_e5065, 0i);
                    let _e5084 = _e5055.xy;
                    let _e5087 = textureLoad(global_4, (_e5084 + vec2<i32>(_e5075, _e5083)), 0i);
                    let _e5091 = textureLoad(global_4, (_e5084 + vec2<i32>(_e5078, _e5083)), 0i);
                    let _e5095 = textureLoad(global_4, (_e5084 + vec2<i32>(_e5075, _e5082)), 0i);
                    let _e5099 = textureLoad(global_4, (_e5084 + vec2<i32>(_e5078, _e5082)), 0i);
                    let _e5102 = vec3(_e5061.x);
                    local_10 = array<vec4<i32>, 6>(vec4<i32>(0i, 0i, 512i, 256i), vec4<i32>(0i, 256i, 256i, 128i), vec4<i32>(256i, 256i, 128i, 64i), vec4<i32>(384i, 256i, 64i, 32i), vec4<i32>(448i, 256i, 32i, 16i), vec4<i32>(480i, 256i, 16i, 8i));
                    let _e5110 = local_10[(_e5053 + 1i)];
                    let _e5114 = ((_e5050 * vec2<f32>(_e5110.zw)) - vec2<f32>(0.5f, 0.5f));
                    let _e5115 = floor(_e5114);
                    let _e5116 = (_e5114 - _e5115);
                    let _e5118 = i32(_e5115.x);
                    let _e5120 = i32(_e5115.y);
                    phi_21196_ = _e5118;
                    if (_e5118 < 0i) {
                        phi_21196_ = (_e5118 + _e5110.z);
                    }
                    let _e5125 = phi_21196_;
                    phi_21197_ = _e5125;
                    if (_e5125 >= _e5110.z) {
                        phi_21197_ = (_e5125 - _e5110.z);
                    }
                    let _e5130 = phi_21197_;
                    let _e5131 = (_e5130 + 1i);
                    let _e5133 = select(_e5131, 0i, (_e5131 == _e5110.z));
                    let _e5137 = min((_e5120 + 1i), (_e5110.w - 1i));
                    let _e5138 = max(_e5120, 0i);
                    let _e5139 = _e5110.xy;
                    let _e5142 = textureLoad(global_4, (_e5139 + vec2<i32>(_e5130, _e5138)), 0i);
                    let _e5146 = textureLoad(global_4, (_e5139 + vec2<i32>(_e5133, _e5138)), 0i);
                    let _e5150 = textureLoad(global_4, (_e5139 + vec2<i32>(_e5130, _e5137)), 0i);
                    let _e5154 = textureLoad(global_4, (_e5139 + vec2<i32>(_e5133, _e5137)), 0i);
                    let _e5157 = vec3(_e5116.x);
                    let _e5169 = global.member_29[1u];
                    phi_21203_ = (mix(mix(mix(_e5087.xyz, _e5091.xyz, _e5102), mix(_e5095.xyz, _e5099.xyz, _e5102), vec3(_e5061.y)), mix(mix(_e5142.xyz, _e5146.xyz, _e5157), mix(_e5150.xyz, _e5154.xyz, _e5157), vec3(_e5116.y)), vec3((_e5051 - f32(_e5053)))) * _e5169);
                } else {
                    let _e5174 = global.member_9;
                    let _e5177 = global.member_8;
                    let _e5186 = global.member_8[3u];
                    phi_21203_ = mix((mix(_e5174.xyz, _e5177.xyz, vec3(((reflect(-(_e812), _e3299).y * 0.5f) + 0.5f))) * _e5186), _e3605, vec3(_e3276));
                }
                let _e5191 = phi_21203_;
                let _e5193 = reflect(-(_e812), _e3299);
                phi_21285_ = vec3<f32>(0f, 0f, 0f);
                phi_21219_ = 0f;
                phi_21218_ = 0i;
                loop {
                    let _e5196 = phi_21285_;
                    let _e5198 = phi_21219_;
                    let _e5200 = phi_21218_;
                    local_48 = _e5198;
                    local_49 = _e5196;
                    if (_e5200 < i32(_e3744)) {
                        if (_e5198 > 0.999f) {
                            break;
                        }
                        let _e5203 = (_e5200 * 8i);
                        let _e5206 = global_3.member[_e5203];
                        let _e5207 = bitcast<vec4<f32>>(_e5206);
                        let _e5211 = global_3.member[(_e5203 + 1i)];
                        let _e5212 = bitcast<vec4<f32>>(_e5211);
                        let _e5216 = global_3.member[(_e5203 + 2i)];
                        let _e5217 = bitcast<vec4<f32>>(_e5216);
                        let _e5218 = _e5207.xyz;
                        let _e5222 = _e5212.xyz;
                        let _e5226 = _e5217.xyz;
                        let _e5230 = vec3<f32>((dot(_e5218, _e810) + _e5207.w), (dot(_e5222, _e810) + _e5212.w), (dot(_e5226, _e810) + _e5217.w));
                        let _e5234 = global_3.member[(_e5203 + 3i)];
                        let _e5235 = bitcast<vec4<f32>>(_e5234);
                        switch bitcast<i32>(0u) {
                            default: {
                                let _e5240 = (_e5235.xyz - abs(_e5230));
                                let _e5245 = min(_e5240.x, min(_e5240.y, _e5240.z));
                                if (_e5245 <= 0f) {
                                    phi_21220_ = 0f;
                                    break;
                                }
                                if (_e5235.w <= 0f) {
                                    phi_21220_ = 1f;
                                    break;
                                }
                                let _e5249 = min((_e5245 / _e5235.w), 1f);
                                phi_21220_ = ((_e5249 * _e5249) * (3f - (2f * _e5249)));
                                break;
                            }
                        }
                        let _e5255 = phi_21220_;
                        if (_e5255 <= 0f) {
                            phi_21972_ = _e5196;
                            phi_21971_ = _e5198;
                            continue;
                        }
                        let _e5260 = global_3.member[(_e5203 + 4i)];
                        let _e5261 = bitcast<vec4<f32>>(_e5260);
                        let _e5265 = global_3.member[(_e5203 + 5i)];
                        let _e5266 = bitcast<vec4<f32>>(_e5265);
                        let _e5270 = vec3<f32>(dot(_e5218, _e5193), dot(_e5222, _e5193), dot(_e5226, _e5193));
                        if (_e5261.w > 0.5f) {
                            let _e5273 = _e5261.xyz;
                            let _e5275 = -(_e5273);
                            let _e5276 = clamp(_e5230, _e5275, _e5273);
                            let _e5280 = step(vec3<f32>(0.000001f, 0.000001f, 0.000001f), abs(_e5270));
                            let _e5284 = mix(vec3<f32>(1000000000000000000000000000000f, 1000000000000000000000000000000f, 1000000000000000000000000000000f), ((mix(_e5275, _e5273, step(vec3<f32>(0f, 0f, 0f), _e5270)) - _e5276) / mix(vec3<f32>(0.000001f, 0.000001f, 0.000001f), _e5270, _e5280)), _e5280);
                            let _e5293 = ((_e5276 + (_e5270 * max(min(_e5284.x, min(_e5284.y, _e5284.z)), 0f))) - _e5266.xyz);
                            if (dot(_e5293, _e5293) > 0.000000000001f) {
                                phi_21221_ = normalize(_e5293);
                            } else {
                                phi_21221_ = _e5270;
                            }
                            let _e5298 = phi_21221_;
                            phi_21222_ = _e5298;
                        } else {
                            phi_21222_ = _e5270;
                        }
                        let _e5300 = phi_21222_;
                        let _e5305 = global_3.member[(_e5203 + 6i)][0u];
                        let _e5306 = bitcast<i32>(_e5305);
                        let _e5317 = vec2<f32>(((atan2(_e5300.x, -(_e5300.z)) * 0.15915494f) + 0.5f), (acos(clamp(_e5300.y, -1f, 1f)) * 0.31830987f));
                        let _e5318 = (_e3276 * 5f);
                        let _e5320 = min(i32(_e5318), 4i);
                        local_8 = array<vec3<i32>, 6>(vec3<i32>(0i, 256i, 128i), vec3<i32>(32768i, 128i, 64i), vec3<i32>(40960i, 64i, 32i), vec3<i32>(43008i, 32i, 16i), vec3<i32>(43520i, 16i, 8i), vec3<i32>(43648i, 8i, 4i));
                        let _e5322 = local_8[_e5320];
                        let _e5324 = (_e5306 + _e5322.x);
                        let _e5328 = ((_e5317 * vec2<f32>(_e5322.yz)) - vec2<f32>(0.5f, 0.5f));
                        let _e5329 = floor(_e5328);
                        let _e5330 = (_e5328 - _e5329);
                        let _e5332 = i32(_e5329.x);
                        let _e5334 = i32(_e5329.y);
                        phi_21223_ = _e5332;
                        if (_e5332 < 0i) {
                            phi_21223_ = (_e5332 + _e5322.y);
                        }
                        let _e5339 = phi_21223_;
                        phi_21224_ = _e5339;
                        if (_e5339 >= _e5322.y) {
                            phi_21224_ = (_e5339 - _e5322.y);
                        }
                        let _e5344 = phi_21224_;
                        let _e5345 = (_e5344 + 1i);
                        let _e5347 = select(_e5345, 0i, (_e5345 == _e5322.y));
                        let _e5354 = (_e5324 + (max(_e5334, 0i) * _e5322.y));
                        let _e5355 = (_e5354 + _e5344);
                        let _e5360 = global_3.member[(_e5355 >> bitcast<u32>(1i))];
                        if ((_e5355 & 1i) == 0i) {
                            phi_21230_ = _e5360.xy;
                        } else {
                            phi_21230_ = _e5360.zw;
                        }
                        let _e5366 = phi_21230_;
                        let _e5368 = unpack2x16float(_e5366.x);
                        let _e5375 = (_e5354 + _e5347);
                        let _e5380 = global_3.member[(_e5375 >> bitcast<u32>(1i))];
                        if ((_e5375 & 1i) == 0i) {
                            phi_21232_ = _e5380.xy;
                        } else {
                            phi_21232_ = _e5380.zw;
                        }
                        let _e5386 = phi_21232_;
                        let _e5388 = unpack2x16float(_e5386.x);
                        let _e5396 = (_e5324 + (min((_e5334 + 1i), (_e5322.z - 1i)) * _e5322.y));
                        let _e5397 = (_e5396 + _e5344);
                        let _e5402 = global_3.member[(_e5397 >> bitcast<u32>(1i))];
                        if ((_e5397 & 1i) == 0i) {
                            phi_21235_ = _e5402.xy;
                        } else {
                            phi_21235_ = _e5402.zw;
                        }
                        let _e5408 = phi_21235_;
                        let _e5410 = unpack2x16float(_e5408.x);
                        let _e5417 = (_e5396 + _e5347);
                        let _e5422 = global_3.member[(_e5417 >> bitcast<u32>(1i))];
                        if ((_e5417 & 1i) == 0i) {
                            phi_21236_ = _e5422.xy;
                        } else {
                            phi_21236_ = _e5422.zw;
                        }
                        let _e5428 = phi_21236_;
                        let _e5430 = unpack2x16float(_e5428.x);
                        let _e5438 = vec3(_e5330.x);
                        local_7 = array<vec3<i32>, 6>(vec3<i32>(0i, 256i, 128i), vec3<i32>(32768i, 128i, 64i), vec3<i32>(40960i, 64i, 32i), vec3<i32>(43008i, 32i, 16i), vec3<i32>(43520i, 16i, 8i), vec3<i32>(43648i, 8i, 4i));
                        let _e5446 = local_7[(_e5320 + 1i)];
                        let _e5448 = (_e5306 + _e5446.x);
                        let _e5452 = ((_e5317 * vec2<f32>(_e5446.yz)) - vec2<f32>(0.5f, 0.5f));
                        let _e5453 = floor(_e5452);
                        let _e5454 = (_e5452 - _e5453);
                        let _e5456 = i32(_e5453.x);
                        let _e5458 = i32(_e5453.y);
                        phi_21237_ = _e5456;
                        if (_e5456 < 0i) {
                            phi_21237_ = (_e5456 + _e5446.y);
                        }
                        let _e5463 = phi_21237_;
                        phi_21238_ = _e5463;
                        if (_e5463 >= _e5446.y) {
                            phi_21238_ = (_e5463 - _e5446.y);
                        }
                        let _e5468 = phi_21238_;
                        let _e5469 = (_e5468 + 1i);
                        let _e5471 = select(_e5469, 0i, (_e5469 == _e5446.y));
                        let _e5478 = (_e5448 + (max(_e5458, 0i) * _e5446.y));
                        let _e5479 = (_e5478 + _e5468);
                        let _e5484 = global_3.member[(_e5479 >> bitcast<u32>(1i))];
                        if ((_e5479 & 1i) == 0i) {
                            phi_21244_ = _e5484.xy;
                        } else {
                            phi_21244_ = _e5484.zw;
                        }
                        let _e5490 = phi_21244_;
                        let _e5492 = unpack2x16float(_e5490.x);
                        let _e5499 = (_e5478 + _e5471);
                        let _e5504 = global_3.member[(_e5499 >> bitcast<u32>(1i))];
                        if ((_e5499 & 1i) == 0i) {
                            phi_21246_ = _e5504.xy;
                        } else {
                            phi_21246_ = _e5504.zw;
                        }
                        let _e5510 = phi_21246_;
                        let _e5512 = unpack2x16float(_e5510.x);
                        let _e5520 = (_e5448 + (min((_e5458 + 1i), (_e5446.z - 1i)) * _e5446.y));
                        let _e5521 = (_e5520 + _e5468);
                        let _e5526 = global_3.member[(_e5521 >> bitcast<u32>(1i))];
                        if ((_e5521 & 1i) == 0i) {
                            phi_21249_ = _e5526.xy;
                        } else {
                            phi_21249_ = _e5526.zw;
                        }
                        let _e5532 = phi_21249_;
                        let _e5534 = unpack2x16float(_e5532.x);
                        let _e5541 = (_e5520 + _e5471);
                        let _e5546 = global_3.member[(_e5541 >> bitcast<u32>(1i))];
                        if ((_e5541 & 1i) == 0i) {
                            phi_21250_ = _e5546.xy;
                        } else {
                            phi_21250_ = _e5546.zw;
                        }
                        let _e5552 = phi_21250_;
                        let _e5554 = unpack2x16float(_e5552.x);
                        let _e5562 = vec3(_e5454.x);
                        let _e5575 = (_e5255 * (1f - _e5198));
                        phi_21972_ = (_e5196 + ((mix(mix(mix(vec3<f32>(_e5368.x, _e5368.y, unpack2x16float(_e5366.y).x), vec3<f32>(_e5388.x, _e5388.y, unpack2x16float(_e5386.y).x), _e5438), mix(vec3<f32>(_e5410.x, _e5410.y, unpack2x16float(_e5408.y).x), vec3<f32>(_e5430.x, _e5430.y, unpack2x16float(_e5428.y).x), _e5438), vec3(_e5330.y)), mix(mix(vec3<f32>(_e5492.x, _e5492.y, unpack2x16float(_e5490.y).x), vec3<f32>(_e5512.x, _e5512.y, unpack2x16float(_e5510.y).x), _e5562), mix(vec3<f32>(_e5534.x, _e5534.y, unpack2x16float(_e5532.y).x), vec3<f32>(_e5554.x, _e5554.y, unpack2x16float(_e5552.y).x), _e5562), vec3(_e5454.y)), vec3((_e5318 - f32(_e5320)))) * _e5266.w) * _e5575));
                        phi_21971_ = (_e5198 + _e5575);
                        continue;
                    } else {
                        break;
                    }
                    continuing {
                        let _e5580 = phi_21972_;
                        let _e5582 = phi_21971_;
                        phi_21285_ = _e5580;
                        phi_21219_ = _e5582;
                        phi_21218_ = (_e5200 + 1i);
                    }
                }
                let _e5585 = local_48;
                let _e5589 = local_49;
                let _e5590 = (_e5589 + (_e5191 * (1f - _e5585)));
                phi_4254_ = _e1246;
                if _e1246 {
                    let _e5593 = global.member_33[2u];
                    phi_4254_ = (_e5593 > 0.5f);
                }
                let _e5596 = phi_4254_;
                phi_21395_ = _e5590;
                if _e5596 {
                    switch bitcast<i32>(0u) {
                        default: {
                            let _e5599 = global.member_31;
                            let _e5600 = _e5599.xyz;
                            let _e5603 = global.member_33[0u];
                            let _e5608 = global.member_31[3u];
                            let _e5617 = global.member_32[1u];
                            let _e5623 = global.member_32[0u];
                            let _e5626 = (((_e5623 * (1f - smoothstep((_e5603 * 0.5f), _e5603, abs((dot(_e5600, _e810) - _e5608))))) * smoothstep(0.5f, 0.9f, dot(_e817, _e5600))) * (1f - smoothstep((_e5617 * 0.5f), _e5617, _e3276)));
                            if (_e5626 <= 0f) {
                                phi_21361_ = _e5590;
                                break;
                            }
                            let _e5633 = global.member_32[3u];
                            let _e5635 = (_e810 + ((_e802 - (_e5600 * dot(_e802, _e5600))) * _e5633));
                            let _e5637 = global.member_30;
                            let _e5642 = (_e5637 * vec4<f32>(_e5635.x, _e5635.y, _e5635.z, 1f));
                            let _e5654 = global.member_32[2u];
                            phi_21360_ = 0f;
                            phi_21359_ = vec3<f32>(0f, 0f, 0f);
                            phi_21358_ = 0i;
                            loop {
                                let _e5657 = phi_21360_;
                                let _e5659 = phi_21359_;
                                let _e5661 = phi_21358_;
                                local_50 = _e5659;
                                local_51 = _e5657;
                                if (_e5661 < 12i) {
                                    continue;
                                } else {
                                    break;
                                }
                                continuing {
                                    let _e5663 = f32(_e5661);
                                    let _e5668 = (_e5663 * 2.3999631f);
                                    let _e5672 = global.member_33[1u];
                                    let _e5677 = ((((vec2<f32>(_e5642.x, -(_e5642.y)) / vec2(_e5642.w)) * 0.5f) + vec2<f32>(0.5f, 0.5f)) + (vec2<f32>((cos(_e5668) * _e5672), sin(_e5668)) * (sqrt(((_e5663 + 0.5f) * 0.083333336f)) * (_e5654 * _e3276))));
                                    let _e5679 = min(_e5677, (vec2<f32>(1f, 1f) - _e5677));
                                    let _e5683 = smoothstep(0f, 0.04f, min(_e5679.x, _e5679.y));
                                    let _e5685 = textureSampleLevel(global_19, global_5, clamp(_e5677, vec2<f32>(0f, 0f), vec2<f32>(1f, 1f)), 0f);
                                    let _e5686 = _e5685.xyz;
                                    phi_21360_ = (_e5657 + (_e5685.w * _e5683));
                                    phi_21359_ = (_e5659 + ((_e5686 / (vec3<f32>(1f, 1f, 1f) - min(_e5686, vec3<f32>(0.995f, 0.995f, 0.995f)))) * _e5683));
                                    phi_21358_ = (_e5661 + 1i);
                                }
                            }
                            let _e5697 = local_50;
                            let _e5700 = local_51;
                            phi_21361_ = mix(_e5590, ((_e5697 * vec3<f32>(0.083333336f, 0.083333336f, 0.083333336f)) + (_e5590 * (1f - (_e5700 * 0.083333336f)))), vec3(_e5626));
                            break;
                        }
                    }
                    let _e5708 = phi_21361_;
                    phi_21395_ = _e5708;
                }
                let _e5710 = phi_21395_;
                phi_21394_ = _e5710;
            }
            let _e5712 = phi_21394_;
            phi_21631_ = (_e3741 + (((_e3736 * (_e5026 - _e3605)) + (_e3734 * (_e5712 - _e3729))) * _e1264));
        }
        let _e5721 = phi_21631_;
        let _e5724 = global.member_13[3u];
        phi_21701_ = _e5721;
        if (_e5724 > 0.5f) {
            let _e5727 = global.member_11;
            let _e5732 = global.member_11[3u];
            let _e5734 = global_16;
            let _e5737 = global.member_12;
            let _e5742 = global.member_13;
            let _e5745 = clamp(floor((_e5734.xy * _e5737.xy)), vec2<f32>(0f, 0f), (_e5742.xy - vec2<f32>(1f, 1f)));
            let _e5750 = global.member_12[2u];
            let _e5754 = global.member_12[3u];
            let _e5759 = global.member_13[2u];
            let _e5764 = global.member_13[1u];
            let _e5770 = global.member_13[0u];
            let _e5774 = u32(((((clamp(floor(((log2(max((dot(_e5727.xyz, _e810) + _e5732), 0.000001f)) * _e5750) + _e5754)), 0f, (_e5759 - 1f)) * _e5764) + _e5745.y) * _e5770) + _e5745.x));
            let _e5781 = global_17.member[(_e5774 >> bitcast<u32>(2i))][(_e5774 & 3u)];
            let _e5782 = (_e5781 & 65535u);
            phi_21630_ = _e5721;
            phi_21496_ = _e5782;
            loop {
                let _e5786 = phi_21630_;
                let _e5788 = phi_21496_;
                local_66 = _e5786;
                if (_e5788 < (_e5782 + (_e5781 >> bitcast<u32>(16i)))) {
                    let _e5791 = (_e5788 / 3u);
                    let _e5798 = global_18.member[(_e5791 >> bitcast<u32>(2i))][(_e5791 & 3u)];
                    let _e5804 = ((_e5798 >> bitcast<u32>(((_e5788 - (_e5791 * 3u)) * 10u))) & 1023u);
                    let _e5807 = global_12.member[_e5804];
                    let _e5809 = (_e5807.xyz - _e810);
                    let _e5810 = dot(_e5809, _e5809);
                    let _e5812 = (_e5810 * _e5807.w);
                    let _e5815 = clamp((1f - (_e5812 * _e5812)), 0f, 1f);
                    let _e5818 = (_e5809 * inverseSqrt(max(_e5810, 0.00000001f)));
                    let _e5821 = global_14.member[_e5804];
                    let _e5824 = global_15.member[_e5804];
                    let _e5832 = clamp(((dot(-(_e5818), _e5824.xyz) * _e5821.w) + _e5824.w), 0f, 1f);
                    let _e5839 = (_e5821.xyz * ((((_e5815 * _e5815) * _e5832) * _e5832) / max(_e5810, 0.0001f)));
                    phi_21628_ = _e5839;
                    if _e820 {
                        switch bitcast<i32>(0u) {
                            default: {
                                let _e5843 = global.member_21[2u];
                                let _e5844 = u32(_e5843);
                                if (_e5804 < _e5844) {
                                    let _e5848 = global.member_26[_e5804];
                                    let _e5851 = global.member_15[_e5804];
                                    let _e5860 = (_e5848.z * max((_e5851 * vec4<f32>(_e810.x, _e810.y, _e810.z, 1f)).w, 0f));
                                    let _e5863 = global.member_25[0u];
                                    let _e5869 = global.member_25[1u];
                                    let _e5872 = ((_e810 + (_e817 * (_e5860 * _e5863))) + (_e5818 * (_e5860 * _e5869)));
                                    let _e5877 = (_e5851 * vec4<f32>(_e5872.x, _e5872.y, _e5872.z, 1f));
                                    if (_e5877.w <= 0f) {
                                        phi_21523_ = 1f;
                                        break;
                                    }
                                    let _e5882 = (_e5877.xyz / vec3(_e5877.w));
                                    let _e5884 = (_e5882.x < 0f);
                                    phi_15341_ = _e5884;
                                    if !(_e5884) {
                                        phi_15341_ = (_e5882.x > 1f);
                                    }
                                    let _e5888 = phi_15341_;
                                    phi_15348_ = _e5888;
                                    if !(_e5888) {
                                        phi_15348_ = (_e5882.y < 0f);
                                    }
                                    let _e5893 = phi_15348_;
                                    phi_15355_ = _e5893;
                                    if !(_e5893) {
                                        phi_15355_ = (_e5882.y > 1f);
                                    }
                                    let _e5898 = phi_15355_;
                                    phi_15362_ = _e5898;
                                    if !(_e5898) {
                                        phi_15362_ = (_e5882.z > 1f);
                                    }
                                    let _e5903 = phi_15362_;
                                    if _e5903 {
                                        phi_21523_ = 1f;
                                        break;
                                    }
                                    let _e5906 = _e5848.xy;
                                    let _e5908 = global.member_23;
                                    let _e5909 = _e5908.zw;
                                    let _e5911 = global.member_22;
                                    let _e5912 = _e5911.xy;
                                    let _e5913 = (_e5912 * 0.5f);
                                    let _e5915 = (_e5906 + (_e5882.xy * _e5909));
                                    let _e5916 = (_e5906 + _e5913);
                                    let _e5918 = ((_e5906 + _e5909) - _e5913);
                                    let _e5923 = vec4<f32>(_e5916.x, _e5916.y, _e5918.x, _e5918.y);
                                    switch bitcast<i32>(0u) {
                                        default: {
                                            let _e5927 = global.member_22[2u];
                                            let _e5928 = i32(_e5927);
                                            if (_e5928 <= 0i) {
                                                let _e5932 = clamp(_e5915, _e5923.xy, _e5923.zw);
                                                let _e5937 = textureSampleCompare(global_2, global_1, vec3<f32>(_e5932.x, _e5932.y, _e5882.z).xy, _e5882.z);
                                                phi_21522_ = _e5937;
                                                break;
                                            }
                                            let _e5939 = ((_e5915 / _e5912) + vec2<f32>(0.5f, 0.5f));
                                            let _e5940 = floor(_e5939);
                                            let _e5941 = (_e5939 - _e5940);
                                            let _e5943 = (_e5928 == 1i);
                                            if _e5943 {
                                                let _e5944 = (_e5941 * 2f);
                                                local_3[0i] = (vec2<f32>(3f, 3f) - _e5944);
                                                local_3[1i] = (vec2<f32>(1f, 1f) + _e5944);
                                                let _e5950 = local_3[0i];
                                                local_4[0i] = (((vec2<f32>(2f, 2f) - _e5941) / _e5950) - vec2<f32>(1f, 1f));
                                                let _e5954 = local_3[1i];
                                                local_4[1i] = ((_e5941 / _e5954) + vec2<f32>(1f, 1f));
                                            } else {
                                                let _e5958 = (_e5941 * 3f);
                                                local_3[0i] = (vec2<f32>(4f, 4f) - _e5958);
                                                local_3[1i] = vec2<f32>(7f, 7f);
                                                local_3[2i] = (vec2<f32>(1f, 1f) + _e5958);
                                                let _e5966 = local_3[0i];
                                                local_4[0i] = (((vec2<f32>(3f, 3f) - (_e5941 * 2f)) / _e5966) - vec2<f32>(2f, 2f));
                                                let _e5971 = local_3[1i];
                                                local_4[1i] = ((vec2<f32>(3f, 3f) + _e5941) / _e5971);
                                                let _e5974 = local_3[2i];
                                                local_4[2i] = ((_e5941 / _e5974) + vec2<f32>(2f, 2f));
                                            }
                                            let _e5979 = select(3i, 2i, _e5943);
                                            phi_21515_ = 0f;
                                            phi_21512_ = 0i;
                                            loop {
                                                let _e5981 = phi_21515_;
                                                let _e5983 = phi_21512_;
                                                local_52 = _e5981;
                                                if (_e5983 < _e5979) {
                                                    phi_21521_ = _e5981;
                                                    phi_21518_ = 0i;
                                                    loop {
                                                        let _e5986 = phi_21521_;
                                                        let _e5988 = phi_21518_;
                                                        local_64 = _e5986;
                                                        if (_e5988 < _e5979) {
                                                            continue;
                                                        } else {
                                                            break;
                                                        }
                                                        continuing {
                                                            let _e5992 = local_4[_e5988][0u];
                                                            let _e5995 = local_4[_e5983][1u];
                                                            let _e6001 = clamp((_e5912 * ((_e5940 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e5992, _e5995))), _e5923.xy, _e5923.zw);
                                                            let _e6004 = local_3[_e5988][0u];
                                                            let _e6007 = local_3[_e5983][1u];
                                                            let _e6013 = textureSampleCompare(global_2, global_1, vec3<f32>(_e6001.x, _e6001.y, _e5882.z).xy, _e5882.z);
                                                            phi_21521_ = (_e5986 + ((_e6004 * _e6007) * _e6013));
                                                            phi_21518_ = (_e5988 + 1i);
                                                        }
                                                    }
                                                    continue;
                                                } else {
                                                    break;
                                                }
                                                continuing {
                                                    let _e7925 = local_64;
                                                    phi_21515_ = _e7925;
                                                    phi_21512_ = (_e5983 + 1i);
                                                }
                                            }
                                            let _e6019 = local_52;
                                            phi_21522_ = (_e6019 * select(0.0069444445f, 0.0625f, _e5943));
                                            break;
                                        }
                                    }
                                    let _e6022 = phi_21522_;
                                    phi_21523_ = _e6022;
                                    break;
                                }
                                let _e6023 = (_e5804 - _e5844);
                                let _e6026 = global.member_21[3u];
                                if (_e6023 >= u32(_e6026)) {
                                    phi_21523_ = 1f;
                                    break;
                                }
                                let _e6031 = global.member_27[_e6023];
                                let _e6034 = global.member_28[_e6023];
                                let _e6036 = _e6031.xyz;
                                let _e6039 = (_e6031.w * length((_e810 - _e6036)));
                                let _e6042 = global.member_25[0u];
                                let _e6048 = global.member_25[1u];
                                let _e6052 = (((_e810 + (_e817 * (_e6039 * _e6042))) + (_e5818 * (_e6039 * _e6048))) - _e6036);
                                let _e6053 = abs(_e6052);
                                let _e6056 = (_e6053.x >= _e6053.y);
                                phi_15432_ = _e6056;
                                if _e6056 {
                                    phi_15432_ = (_e6053.x >= _e6053.z);
                                }
                                let _e6060 = phi_15432_;
                                if _e6060 {
                                    phi_21499_ = select(1i, 0i, (_e6052.x > 0f));
                                    phi_21497_ = _e6053.x;
                                } else {
                                    let _e6065 = (_e6053.y >= _e6053.z);
                                    if _e6065 {
                                        phi_21500_ = select(3i, 2i, (_e6052.y > 0f));
                                    } else {
                                        phi_21500_ = select(5i, 4i, (_e6052.z > 0f));
                                    }
                                    let _e6073 = phi_21500_;
                                    phi_21499_ = _e6073;
                                    phi_21497_ = select(_e6053.z, _e6053.y, _e6065);
                                }
                                let _e6076 = phi_21499_;
                                let _e6078 = phi_21497_;
                                if (_e6078 <= 0f) {
                                    phi_21523_ = 1f;
                                    break;
                                }
                                local_5 = array<vec3<f32>, 6>(vec3<f32>(0f, 0f, 1f), vec3<f32>(0f, 0f, -1f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(1f, 0f, 0f));
                                let _e6081 = local_5[_e6076];
                                local_6 = array<vec3<f32>, 6>(vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 0f, -1f), vec3<f32>(0f, 0f, 1f), vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 1f, 0f));
                                let _e6084 = local_6[_e6076];
                                let _e6089 = global.member_24[2u];
                                let _e6092 = (vec2<f32>(dot(_e6052, _e6081), dot(_e6052, _e6084)) / vec2((_e6078 * _e6089)));
                                let _e6096 = (_e6034.z + (_e6034.w / _e6078));
                                if (_e6096 > 1f) {
                                    phi_21523_ = 1f;
                                    break;
                                }
                                let _e6111 = global.member_24;
                                let _e6112 = _e6111.xy;
                                let _e6114 = (_e6034.xy + (vec2<f32>(f32((_e6076 - (i32(floor((f32(_e6076) / f32(3i)))) * 3i))), f32((_e6076 / 3i))) * _e6112));
                                let _e6123 = global.member_22;
                                let _e6124 = _e6123.xy;
                                let _e6125 = (_e6124 * 0.5f);
                                let _e6127 = (_e6114 + (vec2<f32>((0.5f + (0.5f * _e6092.x)), (0.5f - (0.5f * _e6092.y))) * _e6112));
                                let _e6128 = (_e6114 + _e6125);
                                let _e6130 = ((_e6114 + _e6112) - _e6125);
                                let _e6135 = vec4<f32>(_e6128.x, _e6128.y, _e6130.x, _e6130.y);
                                switch bitcast<i32>(0u) {
                                    default: {
                                        let _e6139 = global.member_22[2u];
                                        let _e6140 = i32(_e6139);
                                        if (_e6140 <= 0i) {
                                            let _e6144 = clamp(_e6127, _e6135.xy, _e6135.zw);
                                            let _e6149 = textureSampleCompare(global_2, global_1, vec3<f32>(_e6144.x, _e6144.y, _e6096).xy, _e6096);
                                            phi_21511_ = _e6149;
                                            break;
                                        }
                                        let _e6151 = ((_e6127 / _e6124) + vec2<f32>(0.5f, 0.5f));
                                        let _e6152 = floor(_e6151);
                                        let _e6153 = (_e6151 - _e6152);
                                        let _e6155 = (_e6140 == 1i);
                                        if _e6155 {
                                            let _e6156 = (_e6153 * 2f);
                                            local_1[0i] = (vec2<f32>(3f, 3f) - _e6156);
                                            local_1[1i] = (vec2<f32>(1f, 1f) + _e6156);
                                            let _e6162 = local_1[0i];
                                            local_2[0i] = (((vec2<f32>(2f, 2f) - _e6153) / _e6162) - vec2<f32>(1f, 1f));
                                            let _e6166 = local_1[1i];
                                            local_2[1i] = ((_e6153 / _e6166) + vec2<f32>(1f, 1f));
                                        } else {
                                            let _e6170 = (_e6153 * 3f);
                                            local_1[0i] = (vec2<f32>(4f, 4f) - _e6170);
                                            local_1[1i] = vec2<f32>(7f, 7f);
                                            local_1[2i] = (vec2<f32>(1f, 1f) + _e6170);
                                            let _e6178 = local_1[0i];
                                            local_2[0i] = (((vec2<f32>(3f, 3f) - (_e6153 * 2f)) / _e6178) - vec2<f32>(2f, 2f));
                                            let _e6183 = local_1[1i];
                                            local_2[1i] = ((vec2<f32>(3f, 3f) + _e6153) / _e6183);
                                            let _e6186 = local_1[2i];
                                            local_2[2i] = ((_e6153 / _e6186) + vec2<f32>(2f, 2f));
                                        }
                                        let _e6191 = select(3i, 2i, _e6155);
                                        phi_21504_ = 0f;
                                        phi_21501_ = 0i;
                                        loop {
                                            let _e6193 = phi_21504_;
                                            let _e6195 = phi_21501_;
                                            local_53 = _e6193;
                                            if (_e6195 < _e6191) {
                                                phi_21510_ = _e6193;
                                                phi_21507_ = 0i;
                                                loop {
                                                    let _e6198 = phi_21510_;
                                                    let _e6200 = phi_21507_;
                                                    local_65 = _e6198;
                                                    if (_e6200 < _e6191) {
                                                        continue;
                                                    } else {
                                                        break;
                                                    }
                                                    continuing {
                                                        let _e6204 = local_2[_e6200][0u];
                                                        let _e6207 = local_2[_e6195][1u];
                                                        let _e6213 = clamp((_e6124 * ((_e6152 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e6204, _e6207))), _e6135.xy, _e6135.zw);
                                                        let _e6216 = local_1[_e6200][0u];
                                                        let _e6219 = local_1[_e6195][1u];
                                                        let _e6225 = textureSampleCompare(global_2, global_1, vec3<f32>(_e6213.x, _e6213.y, _e6096).xy, _e6096);
                                                        phi_21510_ = (_e6198 + ((_e6216 * _e6219) * _e6225));
                                                        phi_21507_ = (_e6200 + 1i);
                                                    }
                                                }
                                                continue;
                                            } else {
                                                break;
                                            }
                                            continuing {
                                                let _e7937 = local_65;
                                                phi_21504_ = _e7937;
                                                phi_21501_ = (_e6195 + 1i);
                                            }
                                        }
                                        let _e6231 = local_53;
                                        phi_21511_ = (_e6231 * select(0.0069444445f, 0.0625f, _e6155));
                                        break;
                                    }
                                }
                                let _e6234 = phi_21511_;
                                phi_21523_ = _e6234;
                                break;
                            }
                        }
                        let _e6236 = phi_21523_;
                        phi_21628_ = (_e5839 * _e6236);
                    }
                    let _e6239 = phi_21628_;
                    let _e6241 = normalize((_e5818 + _e812));
                    let _e6243 = clamp(dot(_e802, _e5818), 0f, 1f);
                    let _e6245 = clamp(dot(_e802, _e6241), 0f, 1f);
                    let _e6251 = (_e3281 + (_e3318 * pow((1f - clamp(dot(_e812, _e6241), 0f, 1f)), 5f)));
                    let _e6254 = (((_e6245 * _e6245) * _e3323) + 1f);
                    local_63 = (_e5786 + (((((vec3<f32>(1f, 1f, 1f) - _e6251) * _e3279) + ((_e6251 * ((_e3321 / ((3.1415927f * _e6254) * _e6254)) * (0.5f / max(((_e6243 * _e3333) + (_e3313 * sqrt((((_e6243 * _e6243) * _e3330) + _e3321)))), 0.00001f)))) * 3.1415927f)) * _e6243) * _e6239));
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e7917 = local_63;
                    phi_21630_ = _e7917;
                    phi_21496_ = (_e5788 + bitcast<u32>(1i));
                }
            }
            let _e7947 = local_66;
            phi_21701_ = _e7947;
        }
        let _e6279 = phi_21701_;
        phi_21697_ = _e6279;
    }
    let _e6281 = phi_21697_;
    let _e6284 = global_8.member_1[1u];
    let _e6288 = global_8.member_5;
    let _e6290 = textureSample(global_27, global_5, _e281);
    let _e6293 = global_25;
    let _e6299 = -(length(_e811));
    let _e6302 = global.member_7[3u];
    let _e6308 = global.member_9[3u];
    phi_21783_ = (1f - exp((_e6299 * _e6302)));
    if (_e6308 != 0f) {
        let _e6312 = (_e6308 * (_e810 - _e809).y);
        if (abs(_e6312) < 0.0001f) {
            phi_21780_ = (1f - (0.5f * _e6312));
        } else {
            phi_21780_ = ((1f - exp(min(-(_e6312), 60f))) / _e6312);
        }
        let _e6323 = phi_21780_;
        let _e6327 = global.member_6[1u];
        let _e6330 = global.member_6[3u];
        phi_21783_ = (1f - exp(((_e6299 * (_e6302 * exp(min((-(_e6308) * (_e6327 - _e6330)), 30f)))) * _e6323)));
    }
    let _e6341 = phi_21783_;
    let _e6343 = global.member_7;
    let _e6349 = global.member_34[2u];
    phi_21830_ = mix((mix(_e6281, _e1235, vec3(_e6284)) + ((_e6288.xyz * _e6290.xyz) * (vec3<f32>(1f, 1f, 1f) + _e6293.yzw))), _e6343.xyz, vec3(_e6341));
    if (_e6349 > 0.5f) {
        let _e6353 = global.member_29[0u];
        if (_e6353 > 0.5f) {
            let _e6356 = global.member_29;
            let _e6363 = ((_e6356.z * _e802.x) - (_e6356.w * _e802.z));
            let _e6367 = ((_e6356.w * _e802.x) + (_e6356.z * _e802.z));
            let _e6371 = (1.092548f * _e6363);
            local = array<f32, 9>(0.282095f, (0.488603f * _e802.y), (0.488603f * _e6367), (0.488603f * _e6363), (_e6371 * _e802.y), ((1.092548f * _e802.y) * _e6367), (0.315392f * (((3f * _e6367) * _e6367) - 1f)), (_e6371 * _e6367), (0.546274f * ((_e6363 * _e6363) - (_e802.y * _e802.y))));
            phi_21793_ = vec3<f32>(0f, 0f, 0f);
            phi_21792_ = 0i;
            loop {
                let _e6386 = phi_21793_;
                let _e6388 = phi_21792_;
                local_54 = _e6386;
                if (_e6388 < 9i) {
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e6392 = textureLoad(global_4, (vec2<i32>(496i, 256i) + vec2<i32>(_e6388, 0i)), 0i);
                    let _e6395 = local[_e6388];
                    phi_21793_ = (_e6386 + (_e6392.xyz * _e6395));
                    phi_21792_ = (_e6388 + 1i);
                }
            }
            let _e6400 = local_54;
            let _e6404 = global.member_29[1u];
            phi_21794_ = (max(_e6400, vec3<f32>(0f, 0f, 0f)) * _e6404);
        } else {
            let _e6407 = global.member_9;
            let _e6410 = global.member_8;
            let _e6419 = global.member_8[3u];
            phi_21794_ = (mix(_e6407.xyz, _e6410.xyz, vec3(((_e802.y * 0.5f) + 0.5f))) * _e6419);
        }
        let _e6422 = phi_21794_;
        let _e6425 = global.member_34[1u];
        phi_21799_ = _e6422;
        if (_e6425 > 0.5f) {
            let _e6430 = global.member_34[0u];
            phi_21798_ = _e6422;
            phi_21797_ = 0i;
            loop {
                let _e6433 = phi_21798_;
                let _e6435 = phi_21797_;
                local_67 = _e6433;
                if (_e6435 < i32(_e6425)) {
                    let _e6438 = (8i * (i32(_e6430) + _e6435));
                    let _e6442 = global_3.member[(_e6438 + 3i)];
                    let _e6443 = bitcast<vec4<f32>>(_e6442);
                    let _e6446 = global_3.member[_e6438];
                    let _e6447 = bitcast<vec4<f32>>(_e6446);
                    let _e6451 = global_3.member[(_e6438 + 1i)];
                    let _e6452 = bitcast<vec4<f32>>(_e6451);
                    let _e6456 = global_3.member[(_e6438 + 2i)];
                    let _e6457 = bitcast<vec4<f32>>(_e6456);
                    let _e6458 = _e6447.xyz;
                    let _e6462 = _e6452.xyz;
                    let _e6466 = _e6457.xyz;
                    let _e6470 = vec3<f32>((dot(_e6458, _e810) + _e6447.w), (dot(_e6462, _e810) + _e6452.w), (dot(_e6466, _e810) + _e6457.w));
                    let _e6471 = _e6443.xyz;
                    switch bitcast<i32>(0u) {
                        default: {
                            let _e6475 = (_e6471 - abs(_e6470));
                            let _e6480 = min(_e6475.x, min(_e6475.y, _e6475.z));
                            if (_e6480 <= 0f) {
                                phi_21833_ = 0f;
                                break;
                            }
                            if (_e6443.w <= 0f) {
                                phi_21833_ = 1f;
                                break;
                            }
                            let _e6484 = min((_e6480 / _e6443.w), 1f);
                            phi_21833_ = ((_e6484 * _e6484) * (3f - (2f * _e6484)));
                            break;
                        }
                    }
                    let _e6490 = phi_21833_;
                    if (_e6490 <= 0f) {
                        phi_22001_ = _e6433;
                        continue;
                    }
                    let _e6495 = global_3.member[(_e6438 + 4i)];
                    let _e6497 = bitcast<vec4<f32>>(_e6495).xyz;
                    let _e6501 = global_3.member[(_e6438 + 5i)];
                    let _e6502 = bitcast<vec4<f32>>(_e6501);
                    let _e6507 = global_3.member[(_e6438 + 6i)][0u];
                    let _e6508 = bitcast<i32>(_e6507);
                    let _e6509 = dot(_e6458, _e802);
                    let _e6510 = dot(_e6462, _e802);
                    let _e6511 = dot(_e6466, _e802);
                    let _e6512 = vec3<f32>(_e6509, _e6510, _e6511);
                    let _e6518 = ((_e810 + (_e802 * _e6502.x)) + (_e812 * _e6502.y));
                    let _e6533 = clamp(((((vec3<f32>((dot(_e6458, _e6518) + _e6447.w), (dot(_e6462, _e6518) + _e6452.w), (dot(_e6466, _e6518) + _e6457.w)) + _e6471) / max((_e6471 * 2f), vec3<f32>(0.000001f, 0.000001f, 0.000001f))) * _e6497) - vec3<f32>(0.5f, 0.5f, 0.5f)), vec3<f32>(0f, 0f, 0f), (_e6497 - vec3<f32>(1f, 1f, 1f)));
                    let _e6534 = vec3<i32>(_e6497);
                    let _e6538 = min(vec3<i32>(_e6533), max((_e6534 - vec3<i32>(2i, 2i, 2i)), vec3<i32>(0i, 0i, 0i)));
                    let _e6540 = (_e6533 - vec3<f32>(_e6538));
                    let _e6541 = (0.488603f * _e6510);
                    let _e6542 = (0.488603f * _e6511);
                    let _e6543 = (0.488603f * _e6509);
                    let _e6544 = (1.092548f * _e6509);
                    let _e6545 = (_e6544 * _e6510);
                    let _e6547 = ((1.092548f * _e6510) * _e6511);
                    let _e6551 = (0.315392f * (((3f * _e6511) * _e6511) - 1f));
                    let _e6552 = (_e6544 * _e6511);
                    let _e6556 = (0.546274f * ((_e6509 * _e6509) - (_e6510 * _e6510)));
                    let _e6557 = (_e6534 - vec3<i32>(1i, 1i, 1i));
                    let _e6558 = min(_e6538, _e6557);
                    let _e6569 = (_e6508 + ((_e6558.x + (_e6534.x * (_e6558.y + (_e6534.y * _e6558.z)))) * 4i));
                    let _e6570 = (vec3<f32>(1f, 1f, 1f) - _e6540);
                    let _e6577 = ((((((vec3<f32>(_e6558) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e6497) * _e6471) * 2f) - _e6471) - _e6470);
                    let _e6583 = (dot((_e6577 * inverseSqrt(max(dot(_e6577, _e6577), 0.0000000001f))), _e6512) + 1f);
                    let _e6586 = (_e6570.x * _e6570.y);
                    let _e6593 = (_e6569 + 3i);
                    let _e6597 = global_3.member[_e6593][1u];
                    let _e6602 = (((_e6586 * _e6570.z) * ((0.25f * (_e6583 * _e6583)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e6597).y > 0.5f)));
                    let _e6605 = global_3.member[_e6569];
                    let _e6609 = global_3.member[(_e6569 + 1i)];
                    let _e6613 = global_3.member[(_e6569 + 2i)];
                    let _e6616 = global_3.member[_e6593];
                    let _e6618 = unpack2x16float(_e6605.x);
                    let _e6620 = unpack2x16float(_e6605.y);
                    let _e6622 = unpack2x16float(_e6605.z);
                    let _e6624 = unpack2x16float(_e6605.w);
                    let _e6626 = unpack2x16float(_e6609.x);
                    let _e6628 = unpack2x16float(_e6609.y);
                    let _e6630 = unpack2x16float(_e6609.z);
                    let _e6632 = unpack2x16float(_e6609.w);
                    let _e6634 = unpack2x16float(_e6613.x);
                    let _e6636 = unpack2x16float(_e6613.y);
                    let _e6638 = unpack2x16float(_e6613.z);
                    let _e6640 = unpack2x16float(_e6613.w);
                    let _e6642 = unpack2x16float(_e6616.x);
                    let _e6698 = ((((((((((vec3<f32>(_e6618.x, _e6618.y, _e6620.x) * 0.282095f) + (vec3<f32>(_e6620.y, _e6622.x, _e6622.y) * _e6541)) + (vec3<f32>(_e6624.x, _e6624.y, _e6626.x) * _e6542)) + (vec3<f32>(_e6626.y, _e6628.x, _e6628.y) * _e6543)) + (vec3<f32>(_e6630.x, _e6630.y, _e6632.x) * _e6545)) + (vec3<f32>(_e6632.y, _e6634.x, _e6634.y) * _e6547)) + (vec3<f32>(_e6636.x, _e6636.y, _e6638.x) * _e6551)) + (vec3<f32>(_e6638.y, _e6640.x, _e6640.y) * _e6552)) + (vec3<f32>(_e6642.x, _e6642.y, unpack2x16float(_e6616.y).x) * _e6556)) * _e6602);
                    let _e6704 = min((_e6538 + vec3<i32>(1i, 0i, 0i)), _e6557);
                    let _e6713 = (_e6508 + ((_e6704.x + (_e6534.x * (_e6704.y + (_e6534.y * _e6704.z)))) * 4i));
                    let _e6720 = ((((((vec3<f32>(_e6704) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e6497) * _e6471) * 2f) - _e6471) - _e6470);
                    let _e6726 = (dot((_e6720 * inverseSqrt(max(dot(_e6720, _e6720), 0.0000000001f))), _e6512) + 1f);
                    let _e6728 = (_e6540.x * _e6570.y);
                    let _e6734 = (_e6713 + 3i);
                    let _e6738 = global_3.member[_e6734][1u];
                    let _e6743 = (((_e6728 * _e6570.z) * ((0.25f * (_e6726 * _e6726)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e6738).y > 0.5f)));
                    let _e6746 = global_3.member[_e6713];
                    let _e6750 = global_3.member[(_e6713 + 1i)];
                    let _e6754 = global_3.member[(_e6713 + 2i)];
                    let _e6757 = global_3.member[_e6734];
                    let _e6759 = unpack2x16float(_e6746.x);
                    let _e6761 = unpack2x16float(_e6746.y);
                    let _e6763 = unpack2x16float(_e6746.z);
                    let _e6765 = unpack2x16float(_e6746.w);
                    let _e6767 = unpack2x16float(_e6750.x);
                    let _e6769 = unpack2x16float(_e6750.y);
                    let _e6771 = unpack2x16float(_e6750.z);
                    let _e6773 = unpack2x16float(_e6750.w);
                    let _e6775 = unpack2x16float(_e6754.x);
                    let _e6777 = unpack2x16float(_e6754.y);
                    let _e6779 = unpack2x16float(_e6754.z);
                    let _e6781 = unpack2x16float(_e6754.w);
                    let _e6783 = unpack2x16float(_e6757.x);
                    let _e6839 = ((((((((((vec3<f32>(_e6759.x, _e6759.y, _e6761.x) * 0.282095f) + (vec3<f32>(_e6761.y, _e6763.x, _e6763.y) * _e6541)) + (vec3<f32>(_e6765.x, _e6765.y, _e6767.x) * _e6542)) + (vec3<f32>(_e6767.y, _e6769.x, _e6769.y) * _e6543)) + (vec3<f32>(_e6771.x, _e6771.y, _e6773.x) * _e6545)) + (vec3<f32>(_e6773.y, _e6775.x, _e6775.y) * _e6547)) + (vec3<f32>(_e6777.x, _e6777.y, _e6779.x) * _e6551)) + (vec3<f32>(_e6779.y, _e6781.x, _e6781.y) * _e6552)) + (vec3<f32>(_e6783.x, _e6783.y, unpack2x16float(_e6757.y).x) * _e6556)) * _e6743);
                    let _e6846 = min((_e6538 + vec3<i32>(0i, 1i, 0i)), _e6557);
                    let _e6855 = (_e6508 + ((_e6846.x + (_e6534.x * (_e6846.y + (_e6534.y * _e6846.z)))) * 4i));
                    let _e6862 = ((((((vec3<f32>(_e6846) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e6497) * _e6471) * 2f) - _e6471) - _e6470);
                    let _e6868 = (dot((_e6862 * inverseSqrt(max(dot(_e6862, _e6862), 0.0000000001f))), _e6512) + 1f);
                    let _e6870 = (_e6570.x * _e6540.y);
                    let _e6876 = (_e6855 + 3i);
                    let _e6880 = global_3.member[_e6876][1u];
                    let _e6885 = (((_e6870 * _e6570.z) * ((0.25f * (_e6868 * _e6868)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e6880).y > 0.5f)));
                    let _e6888 = global_3.member[_e6855];
                    let _e6892 = global_3.member[(_e6855 + 1i)];
                    let _e6896 = global_3.member[(_e6855 + 2i)];
                    let _e6899 = global_3.member[_e6876];
                    let _e6901 = unpack2x16float(_e6888.x);
                    let _e6903 = unpack2x16float(_e6888.y);
                    let _e6905 = unpack2x16float(_e6888.z);
                    let _e6907 = unpack2x16float(_e6888.w);
                    let _e6909 = unpack2x16float(_e6892.x);
                    let _e6911 = unpack2x16float(_e6892.y);
                    let _e6913 = unpack2x16float(_e6892.z);
                    let _e6915 = unpack2x16float(_e6892.w);
                    let _e6917 = unpack2x16float(_e6896.x);
                    let _e6919 = unpack2x16float(_e6896.y);
                    let _e6921 = unpack2x16float(_e6896.z);
                    let _e6923 = unpack2x16float(_e6896.w);
                    let _e6925 = unpack2x16float(_e6899.x);
                    let _e6981 = ((((((((((vec3<f32>(_e6901.x, _e6901.y, _e6903.x) * 0.282095f) + (vec3<f32>(_e6903.y, _e6905.x, _e6905.y) * _e6541)) + (vec3<f32>(_e6907.x, _e6907.y, _e6909.x) * _e6542)) + (vec3<f32>(_e6909.y, _e6911.x, _e6911.y) * _e6543)) + (vec3<f32>(_e6913.x, _e6913.y, _e6915.x) * _e6545)) + (vec3<f32>(_e6915.y, _e6917.x, _e6917.y) * _e6547)) + (vec3<f32>(_e6919.x, _e6919.y, _e6921.x) * _e6551)) + (vec3<f32>(_e6921.y, _e6923.x, _e6923.y) * _e6552)) + (vec3<f32>(_e6925.x, _e6925.y, unpack2x16float(_e6899.y).x) * _e6556)) * _e6885);
                    let _e6988 = min((_e6538 + vec3<i32>(1i, 1i, 0i)), _e6557);
                    let _e6997 = (_e6508 + ((_e6988.x + (_e6534.x * (_e6988.y + (_e6534.y * _e6988.z)))) * 4i));
                    let _e7004 = ((((((vec3<f32>(_e6988) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e6497) * _e6471) * 2f) - _e6471) - _e6470);
                    let _e7010 = (dot((_e7004 * inverseSqrt(max(dot(_e7004, _e7004), 0.0000000001f))), _e6512) + 1f);
                    let _e7011 = (_e6540.x * _e6540.y);
                    let _e7017 = (_e6997 + 3i);
                    let _e7021 = global_3.member[_e7017][1u];
                    let _e7026 = (((_e7011 * _e6570.z) * ((0.25f * (_e7010 * _e7010)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e7021).y > 0.5f)));
                    let _e7029 = global_3.member[_e6997];
                    let _e7033 = global_3.member[(_e6997 + 1i)];
                    let _e7037 = global_3.member[(_e6997 + 2i)];
                    let _e7040 = global_3.member[_e7017];
                    let _e7042 = unpack2x16float(_e7029.x);
                    let _e7044 = unpack2x16float(_e7029.y);
                    let _e7046 = unpack2x16float(_e7029.z);
                    let _e7048 = unpack2x16float(_e7029.w);
                    let _e7050 = unpack2x16float(_e7033.x);
                    let _e7052 = unpack2x16float(_e7033.y);
                    let _e7054 = unpack2x16float(_e7033.z);
                    let _e7056 = unpack2x16float(_e7033.w);
                    let _e7058 = unpack2x16float(_e7037.x);
                    let _e7060 = unpack2x16float(_e7037.y);
                    let _e7062 = unpack2x16float(_e7037.z);
                    let _e7064 = unpack2x16float(_e7037.w);
                    let _e7066 = unpack2x16float(_e7040.x);
                    let _e7122 = ((((((((((vec3<f32>(_e7042.x, _e7042.y, _e7044.x) * 0.282095f) + (vec3<f32>(_e7044.y, _e7046.x, _e7046.y) * _e6541)) + (vec3<f32>(_e7048.x, _e7048.y, _e7050.x) * _e6542)) + (vec3<f32>(_e7050.y, _e7052.x, _e7052.y) * _e6543)) + (vec3<f32>(_e7054.x, _e7054.y, _e7056.x) * _e6545)) + (vec3<f32>(_e7056.y, _e7058.x, _e7058.y) * _e6547)) + (vec3<f32>(_e7060.x, _e7060.y, _e7062.x) * _e6551)) + (vec3<f32>(_e7062.y, _e7064.x, _e7064.y) * _e6552)) + (vec3<f32>(_e7066.x, _e7066.y, unpack2x16float(_e7040.y).x) * _e6556)) * _e7026);
                    let _e7129 = min((_e6538 + vec3<i32>(0i, 0i, 1i)), _e6557);
                    let _e7138 = (_e6508 + ((_e7129.x + (_e6534.x * (_e7129.y + (_e6534.y * _e7129.z)))) * 4i));
                    let _e7145 = ((((((vec3<f32>(_e7129) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e6497) * _e6471) * 2f) - _e6471) - _e6470);
                    let _e7151 = (dot((_e7145 * inverseSqrt(max(dot(_e7145, _e7145), 0.0000000001f))), _e6512) + 1f);
                    let _e7158 = (_e7138 + 3i);
                    let _e7162 = global_3.member[_e7158][1u];
                    let _e7167 = (((_e6586 * _e6540.z) * ((0.25f * (_e7151 * _e7151)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e7162).y > 0.5f)));
                    let _e7170 = global_3.member[_e7138];
                    let _e7174 = global_3.member[(_e7138 + 1i)];
                    let _e7178 = global_3.member[(_e7138 + 2i)];
                    let _e7181 = global_3.member[_e7158];
                    let _e7183 = unpack2x16float(_e7170.x);
                    let _e7185 = unpack2x16float(_e7170.y);
                    let _e7187 = unpack2x16float(_e7170.z);
                    let _e7189 = unpack2x16float(_e7170.w);
                    let _e7191 = unpack2x16float(_e7174.x);
                    let _e7193 = unpack2x16float(_e7174.y);
                    let _e7195 = unpack2x16float(_e7174.z);
                    let _e7197 = unpack2x16float(_e7174.w);
                    let _e7199 = unpack2x16float(_e7178.x);
                    let _e7201 = unpack2x16float(_e7178.y);
                    let _e7203 = unpack2x16float(_e7178.z);
                    let _e7205 = unpack2x16float(_e7178.w);
                    let _e7207 = unpack2x16float(_e7181.x);
                    let _e7263 = ((((((((((vec3<f32>(_e7183.x, _e7183.y, _e7185.x) * 0.282095f) + (vec3<f32>(_e7185.y, _e7187.x, _e7187.y) * _e6541)) + (vec3<f32>(_e7189.x, _e7189.y, _e7191.x) * _e6542)) + (vec3<f32>(_e7191.y, _e7193.x, _e7193.y) * _e6543)) + (vec3<f32>(_e7195.x, _e7195.y, _e7197.x) * _e6545)) + (vec3<f32>(_e7197.y, _e7199.x, _e7199.y) * _e6547)) + (vec3<f32>(_e7201.x, _e7201.y, _e7203.x) * _e6551)) + (vec3<f32>(_e7203.y, _e7205.x, _e7205.y) * _e6552)) + (vec3<f32>(_e7207.x, _e7207.y, unpack2x16float(_e7181.y).x) * _e6556)) * _e7167);
                    let _e7270 = min((_e6538 + vec3<i32>(1i, 0i, 1i)), _e6557);
                    let _e7279 = (_e6508 + ((_e7270.x + (_e6534.x * (_e7270.y + (_e6534.y * _e7270.z)))) * 4i));
                    let _e7286 = ((((((vec3<f32>(_e7270) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e6497) * _e6471) * 2f) - _e6471) - _e6470);
                    let _e7292 = (dot((_e7286 * inverseSqrt(max(dot(_e7286, _e7286), 0.0000000001f))), _e6512) + 1f);
                    let _e7298 = (_e7279 + 3i);
                    let _e7302 = global_3.member[_e7298][1u];
                    let _e7307 = (((_e6728 * _e6540.z) * ((0.25f * (_e7292 * _e7292)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e7302).y > 0.5f)));
                    let _e7310 = global_3.member[_e7279];
                    let _e7314 = global_3.member[(_e7279 + 1i)];
                    let _e7318 = global_3.member[(_e7279 + 2i)];
                    let _e7321 = global_3.member[_e7298];
                    let _e7323 = unpack2x16float(_e7310.x);
                    let _e7325 = unpack2x16float(_e7310.y);
                    let _e7327 = unpack2x16float(_e7310.z);
                    let _e7329 = unpack2x16float(_e7310.w);
                    let _e7331 = unpack2x16float(_e7314.x);
                    let _e7333 = unpack2x16float(_e7314.y);
                    let _e7335 = unpack2x16float(_e7314.z);
                    let _e7337 = unpack2x16float(_e7314.w);
                    let _e7339 = unpack2x16float(_e7318.x);
                    let _e7341 = unpack2x16float(_e7318.y);
                    let _e7343 = unpack2x16float(_e7318.z);
                    let _e7345 = unpack2x16float(_e7318.w);
                    let _e7347 = unpack2x16float(_e7321.x);
                    let _e7403 = ((((((((((vec3<f32>(_e7323.x, _e7323.y, _e7325.x) * 0.282095f) + (vec3<f32>(_e7325.y, _e7327.x, _e7327.y) * _e6541)) + (vec3<f32>(_e7329.x, _e7329.y, _e7331.x) * _e6542)) + (vec3<f32>(_e7331.y, _e7333.x, _e7333.y) * _e6543)) + (vec3<f32>(_e7335.x, _e7335.y, _e7337.x) * _e6545)) + (vec3<f32>(_e7337.y, _e7339.x, _e7339.y) * _e6547)) + (vec3<f32>(_e7341.x, _e7341.y, _e7343.x) * _e6551)) + (vec3<f32>(_e7343.y, _e7345.x, _e7345.y) * _e6552)) + (vec3<f32>(_e7347.x, _e7347.y, unpack2x16float(_e7321.y).x) * _e6556)) * _e7307);
                    let _e7410 = min((_e6538 + vec3<i32>(0i, 1i, 1i)), _e6557);
                    let _e7419 = (_e6508 + ((_e7410.x + (_e6534.x * (_e7410.y + (_e6534.y * _e7410.z)))) * 4i));
                    let _e7426 = ((((((vec3<f32>(_e7410) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e6497) * _e6471) * 2f) - _e6471) - _e6470);
                    let _e7432 = (dot((_e7426 * inverseSqrt(max(dot(_e7426, _e7426), 0.0000000001f))), _e6512) + 1f);
                    let _e7438 = (_e7419 + 3i);
                    let _e7442 = global_3.member[_e7438][1u];
                    let _e7447 = (((_e6870 * _e6540.z) * ((0.25f * (_e7432 * _e7432)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e7442).y > 0.5f)));
                    let _e7450 = global_3.member[_e7419];
                    let _e7454 = global_3.member[(_e7419 + 1i)];
                    let _e7458 = global_3.member[(_e7419 + 2i)];
                    let _e7461 = global_3.member[_e7438];
                    let _e7463 = unpack2x16float(_e7450.x);
                    let _e7465 = unpack2x16float(_e7450.y);
                    let _e7467 = unpack2x16float(_e7450.z);
                    let _e7469 = unpack2x16float(_e7450.w);
                    let _e7471 = unpack2x16float(_e7454.x);
                    let _e7473 = unpack2x16float(_e7454.y);
                    let _e7475 = unpack2x16float(_e7454.z);
                    let _e7477 = unpack2x16float(_e7454.w);
                    let _e7479 = unpack2x16float(_e7458.x);
                    let _e7481 = unpack2x16float(_e7458.y);
                    let _e7483 = unpack2x16float(_e7458.z);
                    let _e7485 = unpack2x16float(_e7458.w);
                    let _e7487 = unpack2x16float(_e7461.x);
                    let _e7543 = ((((((((((vec3<f32>(_e7463.x, _e7463.y, _e7465.x) * 0.282095f) + (vec3<f32>(_e7465.y, _e7467.x, _e7467.y) * _e6541)) + (vec3<f32>(_e7469.x, _e7469.y, _e7471.x) * _e6542)) + (vec3<f32>(_e7471.y, _e7473.x, _e7473.y) * _e6543)) + (vec3<f32>(_e7475.x, _e7475.y, _e7477.x) * _e6545)) + (vec3<f32>(_e7477.y, _e7479.x, _e7479.y) * _e6547)) + (vec3<f32>(_e7481.x, _e7481.y, _e7483.x) * _e6551)) + (vec3<f32>(_e7483.y, _e7485.x, _e7485.y) * _e6552)) + (vec3<f32>(_e7487.x, _e7487.y, unpack2x16float(_e7461.y).x) * _e6556)) * _e7447);
                    let _e7550 = min((_e6538 + vec3<i32>(1i, 1i, 1i)), _e6557);
                    let _e7559 = (_e6508 + ((_e7550.x + (_e6534.x * (_e7550.y + (_e6534.y * _e7550.z)))) * 4i));
                    let _e7566 = ((((((vec3<f32>(_e7550) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e6497) * _e6471) * 2f) - _e6471) - _e6470);
                    let _e7572 = (dot((_e7566 * inverseSqrt(max(dot(_e7566, _e7566), 0.0000000001f))), _e6512) + 1f);
                    let _e7578 = (_e7559 + 3i);
                    let _e7582 = global_3.member[_e7578][1u];
                    let _e7587 = (((_e7011 * _e6540.z) * ((0.25f * (_e7572 * _e7572)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e7582).y > 0.5f)));
                    let _e7590 = global_3.member[_e7559];
                    let _e7594 = global_3.member[(_e7559 + 1i)];
                    let _e7598 = global_3.member[(_e7559 + 2i)];
                    let _e7601 = global_3.member[_e7578];
                    let _e7603 = unpack2x16float(_e7590.x);
                    let _e7605 = unpack2x16float(_e7590.y);
                    let _e7607 = unpack2x16float(_e7590.z);
                    let _e7609 = unpack2x16float(_e7590.w);
                    let _e7611 = unpack2x16float(_e7594.x);
                    let _e7613 = unpack2x16float(_e7594.y);
                    let _e7615 = unpack2x16float(_e7594.z);
                    let _e7617 = unpack2x16float(_e7594.w);
                    let _e7619 = unpack2x16float(_e7598.x);
                    let _e7621 = unpack2x16float(_e7598.y);
                    let _e7623 = unpack2x16float(_e7598.z);
                    let _e7625 = unpack2x16float(_e7598.w);
                    let _e7627 = unpack2x16float(_e7601.x);
                    let _e7683 = ((((((((((vec3<f32>(_e7603.x, _e7603.y, _e7605.x) * 0.282095f) + (vec3<f32>(_e7605.y, _e7607.x, _e7607.y) * _e6541)) + (vec3<f32>(_e7609.x, _e7609.y, _e7611.x) * _e6542)) + (vec3<f32>(_e7611.y, _e7613.x, _e7613.y) * _e6543)) + (vec3<f32>(_e7615.x, _e7615.y, _e7617.x) * _e6545)) + (vec3<f32>(_e7617.y, _e7619.x, _e7619.y) * _e6547)) + (vec3<f32>(_e7621.x, _e7621.y, _e7623.x) * _e6551)) + (vec3<f32>(_e7623.y, _e7625.x, _e7625.y) * _e6552)) + (vec3<f32>(_e7627.x, _e7627.y, unpack2x16float(_e7601.y).x) * _e6556)) * _e7587);
                    let _e7688 = (((((((vec4<f32>(_e6698.x, _e6698.y, _e6698.z, _e6602) + vec4<f32>(_e6839.x, _e6839.y, _e6839.z, _e6743)) + vec4<f32>(_e6981.x, _e6981.y, _e6981.z, _e6885)) + vec4<f32>(_e7122.x, _e7122.y, _e7122.z, _e7026)) + vec4<f32>(_e7263.x, _e7263.y, _e7263.z, _e7167)) + vec4<f32>(_e7403.x, _e7403.y, _e7403.z, _e7307)) + vec4<f32>(_e7543.x, _e7543.y, _e7543.z, _e7447)) + vec4<f32>(_e7683.x, _e7683.y, _e7683.z, _e7587));
                    phi_22002_ = _e6433;
                    if (_e7688.w > 0.00001f) {
                        phi_22002_ = mix(_e6433, ((max(_e7688.xyz, vec3<f32>(0f, 0f, 0f)) / vec3(_e7688.w)) * _e6502.z), vec3(_e6490));
                    }
                    let _e7700 = phi_22002_;
                    phi_22001_ = _e7700;
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e7702 = phi_22001_;
                    phi_21798_ = _e7702;
                    phi_21797_ = (_e6435 + 1i);
                }
            }
            let _e7962 = local_67;
            phi_21799_ = _e7962;
        }
        let _e7705 = phi_21799_;
        phi_21830_ = (_e7705 * _e1264);
    }
    let _e7708 = phi_21830_;
    let _e7711 = global.member_33[3u];
    phi_21831_ = _e7708;
    if (_e7711 > 0.5f) {
        phi_21831_ = (_e7708 / (vec3<f32>(1f, 1f, 1f) + _e7708));
    }
    let _e7716 = phi_21831_;
    global_28 = vec4<f32>(_e7716.x, _e7716.y, _e7716.z, ((_e292 * _e295) * _e282.w));
    let _e7721 = global_30;
    let _e7722 = global_31;
    switch bitcast<i32>(0u) {
        default: {
            if (_e7722.w <= 0f) {
                phi_21832_ = vec2<f32>(0f, 0f);
                break;
            }
            phi_21832_ = (((_e7722.xy / vec2(_e7722.w)) - (_e7721.xy / vec2(_e7721.w))) * vec2<f32>(0.5f, -0.5f));
            break;
        }
    }
    let _e7736 = phi_21832_;
    global_29 = _e7736;
    return;
}

@fragment 
fn main(@location(1) param: vec3<f32>, @location(8) param_1: vec4<f32>, @location(4) param_2: vec3<f32>, @location(0) param_3: vec3<f32>, @builtin(position) param_4: vec4<f32>, @location(2) param_5: vec2<f32>, @location(3) param_6: vec4<f32>, @builtin(front_facing) param_7: bool, @location(5) param_8: vec4<f32>, @location(6) param_9: vec4<f32>, @location(7) param_10: vec4<f32>) -> FragmentOutput {
    global_9 = param;
    global_10 = param_1;
    global_11 = param_2;
    global_13 = param_3;
    global_16 = param_4;
    global_20 = param_5;
    global_22 = param_6;
    global_24 = param_7;
    global_25 = param_8;
    global_30 = param_9;
    global_31 = param_10;
    function_();
    let _e24 = global_28;
    let _e25 = global_29;
    return FragmentOutput(_e24, _e25);
}
