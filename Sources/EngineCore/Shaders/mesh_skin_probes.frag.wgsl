// Generated from mesh_skin_probes.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: 39bea39e25b463fa
// glsl-fnv1a64: 2de752fba45c2c26

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
@group(3) @binding(0) 
var<uniform> global_19: type_48;
var<private> global_20: bool;
var<private> global_21: vec2<f32>;
@group(2) @binding(9) 
var global_22: texture_2d<f32>;
var<private> global_23: vec4<f32>;
@group(2) @binding(11) 
var global_24: texture_2d<f32>;
var<private> global_25: vec4<f32>;
@group(2) @binding(12) 
var global_26: texture_2d<f32>;
@group(2) @binding(10) 
var global_27: texture_2d<f32>;
@group(2) @binding(13) 
var global_28: texture_2d<f32>;
var<private> global_29: vec4<f32>;
var<private> global_30: vec2<f32>;
var<private> global_31: vec4<f32>;
var<private> global_32: vec4<f32>;

fn function_() {
    var local: array<vec3<f32>, 2>;
    var local_1: array<vec3<f32>, 2>;
    var local_2: array<vec3<f32>, 2>;
    var local_3: array<vec3<f32>, 2>;
    var local_4: array<f32, 9>;
    var local_5: array<vec3<i32>, 6>;
    var local_6: array<vec3<i32>, 6>;
    var local_7: array<vec4<i32>, 6>;
    var local_8: array<vec4<i32>, 6>;
    var local_9: array<f32, 9>;
    var local_10: array<vec2<f32>, 3>;
    var local_11: array<vec2<f32>, 3>;
    var local_12: array<vec2<f32>, 3>;
    var local_13: array<vec2<f32>, 3>;
    var local_14: array<vec3<f32>, 6>;
    var local_15: array<vec3<f32>, 6>;
    var local_16: array<vec2<f32>, 3>;
    var local_17: array<vec2<f32>, 3>;
    var local_18: array<vec2<f32>, 3>;
    var local_19: array<vec2<f32>, 3>;
    var local_20: array<vec3<f32>, 6>;
    var local_21: array<vec3<f32>, 6>;
    var local_22: array<f32, 4>;
    var local_23: array<f32, 4>;
    var local_24: array<vec2<f32>, 3>;
    var local_25: array<vec2<f32>, 3>;
    var local_26: array<vec2<f32>, 3>;
    var local_27: array<vec2<f32>, 3>;
    var local_28: array<vec3<f32>, 6>;
    var local_29: array<vec3<f32>, 6>;
    var local_30: array<vec2<f32>, 3>;
    var local_31: array<vec2<f32>, 3>;
    var local_32: array<vec2<f32>, 3>;
    var local_33: array<vec2<f32>, 3>;
    var local_34: array<f32, 4>;
    var local_35: array<f32, 4>;
    var local_36: array<f32, 9>;
    var local_37: array<vec2<f32>, 3>;
    var local_38: array<vec2<f32>, 3>;
    var local_39: array<vec2<f32>, 3>;
    var local_40: array<vec2<f32>, 3>;
    var local_41: array<vec3<f32>, 6>;
    var local_42: array<vec3<f32>, 6>;
    var local_43: array<f32, 9>;
    var local_44: array<f32, 9>;
    var local_45: array<vec2<f32>, 3>;
    var local_46: array<vec2<f32>, 3>;
    var local_47: array<vec2<f32>, 3>;
    var local_48: array<vec2<f32>, 3>;
    var local_49: array<vec3<f32>, 4>;
    var local_50: array<vec3<f32>, 4>;
    var phi_35353_: vec3<f32>;
    var phi_35351_: f32;
    var local_51: vec3<f32>;
    var phi_35514_: vec2<f32>;
    var phi_35481_: f32;
    var phi_35450_: vec3<f32>;
    var phi_35354_: vec2<f32>;
    var phi_35355_: vec3<f32>;
    var phi_35364_: vec3<f32>;
    var phi_35363_: vec3<f32>;
    var phi_35360_: f32;
    var phi_5879_: bool;
    var phi_35548_: vec3<f32>;
    var phi_35365_: i32;
    var phi_7292_: bool;
    var local_52: i32;
    var local_53: i32;
    var local_54: i32;
    var phi_7405_: bool;
    var phi_7412_: bool;
    var phi_7419_: bool;
    var local_55: i32;
    var local_56: i32;
    var local_57: i32;
    var phi_35370_: f32;
    var phi_35367_: i32;
    var phi_35376_: f32;
    var phi_35373_: i32;
    var local_58: f32;
    var phi_35377_: f32;
    var phi_35378_: f32;
    var local_59: i32;
    var local_60: i32;
    var local_61: i32;
    var phi_7692_: bool;
    var phi_7699_: bool;
    var phi_7706_: bool;
    var phi_35390_: f32;
    var phi_35387_: i32;
    var phi_35396_: f32;
    var phi_35393_: i32;
    var local_62: f32;
    var phi_35397_: f32;
    var phi_35398_: f32;
    var phi_35419_: f32;
    var phi_35416_: vec3<f32>;
    var phi_35418_: f32;
    var phi_35415_: vec3<f32>;
    var phi_35421_: vec3<f32>;
    var phi_35420_: f32;
    var phi_35574_: f32;
    var phi_35543_: vec3<f32>;
    var phi_35473_: f32;
    var phi_35576_: f32;
    var phi_36568_: vec3<f32>;
    var phi_36567_: i32;
    var local_63: vec3<f32>;
    var phi_36569_: vec3<f32>;
    var phi_36579_: vec3<f32>;
    var phi_36578_: i32;
    var local_64: vec3<f32>;
    var phi_36580_: vec3<f32>;
    var phi_36586_: vec3<f32>;
    var phi_36585_: i32;
    var phi_37548_: f32;
    var phi_37684_: vec3<f32>;
    var phi_37683_: vec3<f32>;
    var local_65: vec3<f32>;
    var phi_36596_: vec3<f32>;
    var phi_36597_: vec3<f32>;
    var phi_36593_: u32;
    var phi_11257_: bool;
    var phi_11264_: bool;
    var phi_11271_: bool;
    var phi_11278_: bool;
    var phi_37454_: f32;
    var phi_37451_: i32;
    var phi_37460_: f32;
    var phi_37457_: i32;
    var local_66: f32;
    var phi_37461_: f32;
    var phi_11348_: bool;
    var phi_37439_: i32;
    var phi_37438_: i32;
    var phi_37436_: f32;
    var phi_37443_: f32;
    var phi_37440_: i32;
    var phi_37449_: f32;
    var phi_37446_: i32;
    var local_67: f32;
    var phi_37450_: f32;
    var phi_37462_: f32;
    var phi_37513_: vec3<f32>;
    var phi_36595_: vec3<f32>;
    var phi_35578_: f32;
    var phi_35577_: f32;
    var phi_36234_: vec2<f32>;
    var phi_36235_: vec3<f32>;
    var phi_36236_: vec3<f32>;
    var phi_36237_: vec3<f32>;
    var phi_36241_: vec3<f32>;
    var phi_36240_: vec3<f32>;
    var phi_36239_: vec3<f32>;
    var local_68: vec3<f32>;
    var phi_12097_: bool;
    var local_69: vec3<f32>;
    var local_70: vec3<f32>;
    var local_71: vec3<f32>;
    var phi_36245_: vec2<f32>;
    var phi_36252_: f32;
    var phi_36250_: f32;
    var phi_36246_: vec3<f32>;
    var phi_36255_: vec3<f32>;
    var phi_36254_: i32;
    var local_72: vec3<f32>;
    var phi_36256_: i32;
    var phi_36257_: i32;
    var phi_36263_: i32;
    var phi_36264_: i32;
    var phi_36280_: vec3<f32>;
    var phi_36270_: vec3<f32>;
    var phi_36278_: vec3<f32>;
    var phi_36277_: i32;
    var phi_36562_: f32;
    var phi_37662_: vec3<f32>;
    var phi_37661_: vec3<f32>;
    var phi_36371_: vec3<f32>;
    var phi_36349_: vec3<f32>;
    var phi_36283_: f32;
    var phi_36282_: i32;
    var phi_36284_: f32;
    var phi_36285_: vec3<f32>;
    var phi_36286_: vec3<f32>;
    var phi_36287_: i32;
    var phi_36288_: i32;
    var phi_36294_: vec2<u32>;
    var phi_36296_: vec2<u32>;
    var phi_36299_: vec2<u32>;
    var phi_36300_: vec2<u32>;
    var phi_36301_: i32;
    var phi_36302_: i32;
    var phi_36308_: vec2<u32>;
    var phi_36310_: vec2<u32>;
    var phi_36313_: vec2<u32>;
    var phi_36314_: vec2<u32>;
    var phi_37667_: vec3<f32>;
    var phi_37666_: f32;
    var local_73: f32;
    var local_74: vec3<f32>;
    var phi_36392_: vec3<f32>;
    var phi_36465_: vec3<f32>;
    var phi_36428_: vec3<f32>;
    var phi_36424_: u32;
    var phi_36464_: vec3<f32>;
    var phi_36427_: vec3<f32>;
    var phi_36425_: vec2<f32>;
    var phi_35579_: vec3<f32>;
    var phi_19742_: bool;
    var phi_35580_: f32;
    var phi_35581_: f32;
    var phi_35582_: i32;
    var phi_35588_: vec3<f32>;
    var phi_35590_: vec3<f32>;
    var phi_35592_: vec3<f32>;
    var phi_35594_: vec3<f32>;
    var phi_35593_: i32;
    var local_75: vec3<f32>;
    var phi_35595_: vec3<f32>;
    var phi_35601_: f32;
    var phi_35602_: vec3<f32>;
    var phi_19871_: bool;
    var phi_19877_: bool;
    var phi_35607_: i32;
    var phi_21564_: bool;
    var local_76: i32;
    var local_77: i32;
    var local_78: i32;
    var phi_21751_: bool;
    var phi_21758_: bool;
    var phi_21765_: bool;
    var local_79: i32;
    var local_80: i32;
    var local_81: i32;
    var phi_35612_: f32;
    var phi_35609_: i32;
    var phi_35618_: f32;
    var phi_35615_: i32;
    var local_82: f32;
    var phi_35619_: f32;
    var phi_35620_: f32;
    var phi_35623_: vec3<f32>;
    var phi_35622_: vec3<f32>;
    var phi_35621_: i32;
    var local_83: mat4x4<f32>;
    var phi_22083_: bool;
    var phi_22090_: bool;
    var phi_22097_: bool;
    var local_84: i32;
    var local_85: i32;
    var local_86: i32;
    var phi_35636_: f32;
    var phi_35633_: i32;
    var phi_35642_: f32;
    var phi_35639_: i32;
    var local_87: f32;
    var phi_35643_: f32;
    var phi_35644_: f32;
    var phi_35661_: vec3<f32>;
    var phi_35662_: vec3<f32>;
    var phi_35869_: vec3<f32>;
    var phi_35928_: vec3<f32>;
    var phi_35870_: vec3<f32>;
    var phi_35688_: u32;
    var phi_22637_: bool;
    var phi_22644_: bool;
    var phi_22651_: bool;
    var phi_22658_: bool;
    var phi_35973_: f32;
    var phi_35970_: i32;
    var phi_35979_: f32;
    var phi_35976_: i32;
    var local_88: f32;
    var phi_35980_: f32;
    var phi_22728_: bool;
    var phi_35958_: i32;
    var phi_35957_: i32;
    var phi_35955_: f32;
    var phi_35962_: f32;
    var phi_35959_: i32;
    var phi_35968_: f32;
    var phi_35965_: i32;
    var local_89: f32;
    var phi_35969_: f32;
    var phi_35981_: f32;
    var phi_35982_: f32;
    var phi_35984_: vec3<f32>;
    var phi_35983_: i32;
    var local_90: vec3<f32>;
    var phi_35985_: vec3<f32>;
    var phi_36024_: f32;
    var phi_36025_: vec3<f32>;
    var phi_19990_: bool;
    var phi_23798_: bool;
    var phi_23805_: bool;
    var phi_23812_: bool;
    var phi_23819_: bool;
    var phi_36065_: f32;
    var phi_36062_: i32;
    var phi_36071_: f32;
    var phi_36068_: i32;
    var local_91: f32;
    var phi_36072_: f32;
    var phi_23889_: bool;
    var phi_36050_: i32;
    var phi_36049_: i32;
    var phi_36047_: f32;
    var phi_36054_: f32;
    var phi_36051_: i32;
    var phi_36060_: f32;
    var phi_36057_: i32;
    var local_92: f32;
    var phi_36061_: f32;
    var phi_36073_: f32;
    var phi_36076_: vec3<f32>;
    var phi_36075_: vec3<f32>;
    var phi_36074_: i32;
    var local_93: bool;
    var phi_24555_: bool;
    var phi_24562_: bool;
    var phi_24569_: bool;
    var phi_24576_: bool;
    var phi_36095_: f32;
    var phi_36092_: i32;
    var phi_36101_: f32;
    var phi_36098_: i32;
    var local_94: f32;
    var phi_36102_: f32;
    var local_95: u32;
    var phi_24646_: bool;
    var phi_36080_: i32;
    var phi_36079_: i32;
    var phi_36077_: f32;
    var phi_36084_: f32;
    var phi_36081_: i32;
    var phi_36090_: f32;
    var phi_36087_: i32;
    var local_96: f32;
    var phi_36091_: f32;
    var phi_36103_: f32;
    var phi_36136_: vec3<f32>;
    var phi_36137_: vec3<f32>;
    var phi_37611_: vec3<f32>;
    var phi_35903_: vec3<f32>;
    var phi_35868_: vec3<f32>;
    var phi_35718_: vec3<f32>;
    var phi_35717_: i32;
    var local_97: vec3<f32>;
    var phi_35719_: i32;
    var phi_35720_: i32;
    var phi_35726_: i32;
    var phi_35727_: i32;
    var phi_35743_: vec3<f32>;
    var phi_35733_: vec3<f32>;
    var phi_35741_: vec3<f32>;
    var phi_35740_: i32;
    var phi_35950_: f32;
    var phi_37605_: vec3<f32>;
    var phi_37604_: vec3<f32>;
    var phi_35834_: vec3<f32>;
    var phi_35812_: vec3<f32>;
    var phi_35746_: f32;
    var phi_35745_: i32;
    var phi_35747_: f32;
    var phi_35748_: vec3<f32>;
    var phi_35749_: vec3<f32>;
    var phi_35750_: i32;
    var phi_35751_: i32;
    var phi_35757_: vec2<u32>;
    var phi_35759_: vec2<u32>;
    var phi_35762_: vec2<u32>;
    var phi_35763_: vec2<u32>;
    var phi_35764_: i32;
    var phi_35765_: i32;
    var phi_35771_: vec2<u32>;
    var phi_35773_: vec2<u32>;
    var phi_35776_: vec2<u32>;
    var phi_35777_: vec2<u32>;
    var phi_37610_: vec3<f32>;
    var phi_37609_: f32;
    var local_98: f32;
    var local_99: vec3<f32>;
    var phi_35855_: vec3<f32>;
    var phi_35856_: vec2<f32>;
    var phi_37181_: vec3<f32>;
    var phi_36598_: vec3<f32>;
    var phi_37172_: vec3<f32>;
    var phi_36594_: vec3<f32>;
    var phi_36782_: f32;
    var phi_36785_: f32;
    var phi_36972_: vec3<f32>;
    var phi_36971_: i32;
    var local_100: vec3<f32>;
    var phi_36973_: vec3<f32>;
    var phi_36977_: vec3<f32>;
    var phi_36976_: i32;
    var phi_37431_: f32;
    var phi_37698_: vec3<f32>;
    var phi_37697_: vec3<f32>;
    var phi_36978_: vec3<f32>;
    var phi_37167_: vec3<f32>;
    var phi_37196_: vec3<f32>;
    var phi_6398_: bool;
    var phi_37197_: f32;
    var phi_37430_: vec2<f32>;
    var local_101: vec2<f32>;
    var local_102: f32;
    var local_103: f32;
    var local_104: vec3<f32>;
    var local_105: f32;
    var local_106: f32;
    var local_107: vec3<f32>;
    var local_108: vec3<f32>;
    var local_109: vec3<f32>;
    var local_110: vec3<f32>;
    var local_111: f32;
    var local_112: vec3<f32>;
    var local_113: vec3<f32>;
    var local_114: f32;
    var local_115: vec3<f32>;
    var local_116: vec3<f32>;
    var local_117: vec3<f32>;
    var local_118: f32;
    var local_119: f32;
    var local_120: f32;
    var local_121: f32;
    var local_122: vec3<f32>;
    var local_123: vec3<f32>;
    var local_124: f32;
    var local_125: f32;
    var local_126: vec3<f32>;
    var local_127: vec3<f32>;
    var local_128: vec3<f32>;
    var local_129: vec3<f32>;
    var local_130: vec3<f32>;

    let _e411 = global_8.member_2;
    let _e413 = global_21;
    let _e417 = global_8.member_2[2u];
    let _e420 = global_8.member_3;
    let _e425 = global_8.member_3[2u];
    let _e427 = vec2<f32>((dot(_e411.xy, _e413) + _e417), (dot(_e420.xy, _e413) + _e425));
    let _e428 = textureSample(global_22, global_5, _e427);
    let _e429 = global_23;
    let _e430 = _e429.xyz;
    let _e432 = global_8.member;
    let _e435 = _e428.xyz;
    let _e436 = ((_e430 * _e432.xyz) * _e435);
    let _e438 = global_23[3u];
    let _e441 = global_8.member[3u];
    let _e447 = global_8.member_1[0u];
    phi_35353_ = _e436;
    if (_e447 > 0.5f) {
        let _e449 = global_13;
        let _e452 = floor((_e449.xz * vec2<f32>(0.5f, 0.5f)));
        let _e456 = abs((_e452.x + _e452.y));
        phi_35353_ = (_e436 * select(0.75f, 1f, ((_e456 - (floor((_e456 / 2f)) * 2f)) < 0.5f)));
    }
    let _e465 = phi_35353_;
    let _e468 = global_8.member_3[3u];
    phi_35514_ = vec2<f32>(0f, 0f);
    phi_35481_ = 0f;
    phi_35450_ = _e465;
    if (_e468 > 0.5f) {
        switch bitcast<i32>(0u) {
            default: {
                let _e473 = global_8.member_2[3u];
                let _e475 = vec4<f32>(_e473, _e468, 0f, 0f).xyy;
                let _e477 = floor((_e475 * vec3<f32>(0.000015258789f, 0.000015258789f, 0.000015258789f)));
                let _e479 = (_e475 - (_e477 * 65536f));
                let _e481 = floor((_e479 * vec3<f32>(0.00390625f, 0.00390625f, 0.00390625f)));
                let _e483 = (_e479 - (_e481 * 256f));
                let _e495 = (_e477.y - 128f);
                let _e502 = (floor((_e495 * 0.03125f)) * 0.33333334f);
                let _e506 = global_9;
                let _e507 = normalize(_e506);
                let _e508 = global_10;
                let _e509 = _e508.xyz;
                let _e510 = dot(_e507, _e509);
                let _e516 = ((_e510 / max(length((_e509 - (_e507 * _e510))), 0.000001f)) * 25.5f);
                local_51 = ((vec3<f32>(_e483.x, _e481.x, _e477.x) * vec3<f32>(0.003921569f, 0.003921569f, 0.003921569f)) * 2f);
                local_101 = (vec2<f32>(_e483.y, _e481.y) * vec2<f32>(0.003921569f, 0.003921569f));
                if ((-24f + _e516) < -2f) {
                    phi_35351_ = 0f;
                    break;
                }
                let _e519 = global_11;
                let _e520 = (_e519 * (4f * exp2(((_e495 - (floor((_e495 / 32f)) * 32f)) * 0.33333334f))));
                let _e521 = floor(_e520);
                let _e522 = (_e520 - _e521);
                let _e526 = ((_e522 * _e522) * (vec3<f32>(3f, 3f, 3f) - (_e522 * 2f)));
                let _e528 = bitcast<vec3<u32>>(vec3<i32>(_e521));
                let _e537 = ((((_e528.x * 1597334677u) ^ (_e528.y * 3812015801u)) ^ (_e528.z * 2798796415u)) * 1597334677u);
                let _e546 = bitcast<vec3<u32>>(vec3<i32>((_e521 + vec3<f32>(1f, 0f, 0f))));
                let _e555 = ((((_e546.x * 1597334677u) ^ (_e546.y * 3812015801u)) ^ (_e546.z * 2798796415u)) * 1597334677u);
                let _e566 = bitcast<vec3<u32>>(vec3<i32>((_e521 + vec3<f32>(0f, 1f, 0f))));
                let _e575 = ((((_e566.x * 1597334677u) ^ (_e566.y * 3812015801u)) ^ (_e566.z * 2798796415u)) * 1597334677u);
                let _e584 = bitcast<vec3<u32>>(vec3<i32>((_e521 + vec3<f32>(1f, 1f, 0f))));
                let _e593 = ((((_e584.x * 1597334677u) ^ (_e584.y * 3812015801u)) ^ (_e584.z * 2798796415u)) * 1597334677u);
                let _e605 = bitcast<vec3<u32>>(vec3<i32>((_e521 + vec3<f32>(0f, 0f, 1f))));
                let _e614 = ((((_e605.x * 1597334677u) ^ (_e605.y * 3812015801u)) ^ (_e605.z * 2798796415u)) * 1597334677u);
                let _e623 = bitcast<vec3<u32>>(vec3<i32>((_e521 + vec3<f32>(1f, 0f, 1f))));
                let _e632 = ((((_e623.x * 1597334677u) ^ (_e623.y * 3812015801u)) ^ (_e623.z * 2798796415u)) * 1597334677u);
                let _e642 = bitcast<vec3<u32>>(vec3<i32>((_e521 + vec3<f32>(0f, 1f, 1f))));
                let _e651 = ((((_e642.x * 1597334677u) ^ (_e642.y * 3812015801u)) ^ (_e642.z * 2798796415u)) * 1597334677u);
                let _e660 = bitcast<vec3<u32>>(vec3<i32>((_e521 + vec3<f32>(1f, 1f, 1f))));
                let _e669 = ((((_e660.x * 1597334677u) ^ (_e660.y * 3812015801u)) ^ (_e660.z * 2798796415u)) * 1597334677u);
                let _e682 = ((_e520 * 2.7f) + vec3<f32>(17.3f, 5.1f, 9.7f));
                let _e683 = floor(_e682);
                let _e684 = (_e682 - _e683);
                let _e688 = ((_e684 * _e684) * (vec3<f32>(3f, 3f, 3f) - (_e684 * 2f)));
                let _e690 = bitcast<vec3<u32>>(vec3<i32>(_e683));
                let _e699 = ((((_e690.x * 1597334677u) ^ (_e690.y * 3812015801u)) ^ (_e690.z * 2798796415u)) * 1597334677u);
                let _e708 = bitcast<vec3<u32>>(vec3<i32>((_e683 + vec3<f32>(1f, 0f, 0f))));
                let _e717 = ((((_e708.x * 1597334677u) ^ (_e708.y * 3812015801u)) ^ (_e708.z * 2798796415u)) * 1597334677u);
                let _e728 = bitcast<vec3<u32>>(vec3<i32>((_e683 + vec3<f32>(0f, 1f, 0f))));
                let _e737 = ((((_e728.x * 1597334677u) ^ (_e728.y * 3812015801u)) ^ (_e728.z * 2798796415u)) * 1597334677u);
                let _e746 = bitcast<vec3<u32>>(vec3<i32>((_e683 + vec3<f32>(1f, 1f, 0f))));
                let _e755 = ((((_e746.x * 1597334677u) ^ (_e746.y * 3812015801u)) ^ (_e746.z * 2798796415u)) * 1597334677u);
                let _e767 = bitcast<vec3<u32>>(vec3<i32>((_e683 + vec3<f32>(0f, 0f, 1f))));
                let _e776 = ((((_e767.x * 1597334677u) ^ (_e767.y * 3812015801u)) ^ (_e767.z * 2798796415u)) * 1597334677u);
                let _e785 = bitcast<vec3<u32>>(vec3<i32>((_e683 + vec3<f32>(1f, 0f, 1f))));
                let _e794 = ((((_e785.x * 1597334677u) ^ (_e785.y * 3812015801u)) ^ (_e785.z * 2798796415u)) * 1597334677u);
                let _e804 = bitcast<vec3<u32>>(vec3<i32>((_e683 + vec3<f32>(0f, 1f, 1f))));
                let _e813 = ((((_e804.x * 1597334677u) ^ (_e804.y * 3812015801u)) ^ (_e804.z * 2798796415u)) * 1597334677u);
                let _e822 = bitcast<vec3<u32>>(vec3<i32>((_e683 + vec3<f32>(1f, 1f, 1f))));
                let _e831 = ((((_e822.x * 1597334677u) ^ (_e822.y * 3812015801u)) ^ (_e822.z * 2798796415u)) * 1597334677u);
                let _e844 = mix(0.45f, 0.05f, _e502);
                phi_35351_ = smoothstep(-(_e844), _e844, ((_e516 + -24.45f) + ((((mix(mix(mix((f32(((_e537 ^ (_e537 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e555 ^ (_e555 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e526.x), mix((f32(((_e575 ^ (_e575 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e593 ^ (_e593 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e526.x), _e526.y), mix(mix((f32(((_e614 ^ (_e614 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e632 ^ (_e632 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e526.x), mix((f32(((_e651 ^ (_e651 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e669 ^ (_e669 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e526.x), _e526.y), _e526.z) * 0.65f) + (mix(mix(mix((f32(((_e699 ^ (_e699 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e717 ^ (_e717 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e688.x), mix((f32(((_e737 ^ (_e737 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e755 ^ (_e755 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e688.x), _e688.y), mix(mix((f32(((_e776 ^ (_e776 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e794 ^ (_e794 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e688.x), mix((f32(((_e813 ^ (_e813 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e831 ^ (_e831 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e688.x), _e688.y), _e688.z) * 0.35f)) - 0.5f) * mix(0.8f, 2.2f, _e502))));
                break;
            }
        }
        let _e853 = phi_35351_;
        let _e855 = local_51;
        let _e13270 = local_101;
        phi_35514_ = _e13270;
        phi_35481_ = _e853;
        phi_35450_ = mix(_e465, ((_e430 * _e855) * mix(vec3<f32>(1f, 1f, 1f), (_e435 * 2f), vec3<f32>(0.5f, 0.5f, 0.5f))), vec3(_e853));
    }
    let _e863 = phi_35514_;
    let _e865 = phi_35481_;
    let _e867 = phi_35450_;
    let _e868 = global_9;
    let _e869 = normalize(_e868);
    let _e872 = global_8.member_6[1u];
    phi_35363_ = _e869;
    if (_e872 > 0.5f) {
        let _e874 = global_10;
        let _e875 = _e874.xyz;
        let _e878 = (_e875 - (_e869 * dot(_e869, _e875)));
        phi_35364_ = _e869;
        if (dot(_e878, _e878) > 0.000000000001f) {
            let _e881 = normalize(_e878);
            let _e884 = global_10[3u];
            let _e888 = textureSample(global_24, global_5, _e427);
            let _e891 = global_8.member_6[2u];
            if (_e891 > 0.5f) {
                if (_e891 > 1.5f) {
                    phi_35354_ = _e888.xw;
                } else {
                    phi_35354_ = _e888.xy;
                }
                let _e897 = phi_35354_;
                let _e899 = ((_e897 * 2f) - vec2<f32>(1f, 1f));
                phi_35355_ = vec3<f32>(_e899.x, _e899.y, sqrt(clamp((1f - dot(_e899, _e899)), 0f, 1f)));
            } else {
                phi_35355_ = ((_e888.xyz * 2f) - vec3<f32>(1f, 1f, 1f));
            }
            let _e911 = phi_35355_;
            let _e914 = global_8.member_4[2u];
            let _e916 = (_e911.xy * _e914);
            phi_35364_ = normalize((((_e881 * _e916.x) + ((cross(_e869, _e881) * select(1f, -1f, (_e884 < 0f))) * _e916.y)) + (_e869 * _e911.z)));
        }
        let _e927 = phi_35364_;
        phi_35363_ = _e927;
    }
    let _e929 = phi_35363_;
    let _e932 = global_8.member_5[3u];
    let _e933 = (_e932 > 0.5f);
    if _e933 {
        let _e936 = global_8.member_1[2u];
        phi_35360_ = clamp(_e936, 0f, 1f);
    } else {
        phi_35360_ = 0f;
    }
    let _e939 = phi_35360_;
    phi_5879_ = _e933;
    if _e933 {
        let _e940 = global_20;
        phi_5879_ = !(_e940);
    }
    let _e943 = phi_5879_;
    phi_35548_ = _e929;
    if (_e943 && (_e939 <= 0f)) {
        phi_35548_ = -(_e929);
    }
    let _e948 = phi_35548_;
    let _e950 = global.member_4;
    let _e952 = normalize(_e950.xyz);
    let _e954 = global.member_6;
    let _e955 = _e954.xyz;
    let _e956 = global_13;
    let _e957 = (_e955 - _e956);
    let _e958 = normalize(_e957);
    let _e960 = normalize((_e952 + _e958));
    let _e961 = global_20;
    let _e963 = (_e869 * select(-1f, 1f, _e961));
    let _e965 = global_25[0u];
    let _e966 = (_e965 > 0.5f);
    let _e969 = global.member_5[3u];
    phi_35574_ = 1f;
    phi_35543_ = _e867;
    if ((_e969 > 0.5f) && _e966) {
        switch bitcast<i32>(0u) {
            default: {
                let _e975 = global.member_21[0u];
                let _e976 = i32(_e975);
                let _e978 = global.member_20;
                let _e983 = global.member_20[3u];
                let _e984 = (dot(_e978.xyz, _e956) + _e983);
                phi_35365_ = 0i;
                loop {
                    let _e986 = phi_35365_;
                    local_52 = _e986;
                    local_53 = _e986;
                    local_54 = _e986;
                    local_55 = _e986;
                    local_56 = _e986;
                    local_57 = _e986;
                    local_59 = _e986;
                    local_60 = _e986;
                    local_61 = _e986;
                    let _e988 = (_e986 < (_e976 - 1i));
                    phi_7292_ = _e988;
                    if _e988 {
                        let _e991 = global.member_16[_e986];
                        phi_7292_ = (_e984 > _e991);
                    }
                    let _e994 = phi_7292_;
                    if _e994 {
                        continue;
                    } else {
                        break;
                    }
                    continuing {
                        phi_35365_ = (_e986 + 1i);
                    }
                }
                let _e998 = local_52;
                let _e1000 = global.member_16[_e998];
                if (_e984 > _e1000) {
                    phi_35421_ = vec3<f32>(1f, 1f, 1f);
                    phi_35420_ = 1f;
                    break;
                }
                let _e1004 = local_53;
                let _e1006 = global.member_18[_e1004];
                let _e1008 = (_e956 + (_e963 * _e1006));
                switch bitcast<i32>(0u) {
                    default: {
                        let _e1012 = local_54;
                        let _e1014 = global.member_14[_e1012];
                        let _e1019 = (_e1014 * vec4<f32>(_e1008.x, _e1008.y, _e1008.z, 1f));
                        let _e1021 = (_e1019.x < 0f);
                        phi_7405_ = _e1021;
                        if !(_e1021) {
                            phi_7405_ = (_e1019.x > 1f);
                        }
                        let _e1025 = phi_7405_;
                        phi_7412_ = _e1025;
                        if !(_e1025) {
                            phi_7412_ = (_e1019.y < 0f);
                        }
                        let _e1030 = phi_7412_;
                        phi_7419_ = _e1030;
                        if !(_e1030) {
                            phi_7419_ = (_e1019.y > 1f);
                        }
                        let _e1035 = phi_7419_;
                        if _e1035 {
                            phi_35378_ = 1f;
                            break;
                        }
                        let _e1037 = local_55;
                        let _e1041 = local_56;
                        let _e1047 = global.member_23;
                        let _e1048 = _e1047.xy;
                        let _e1049 = (vec2<f32>(f32((_e1037 & 1i)), f32((_e1041 >> bitcast<u32>(1i)))) * _e1048);
                        let _e1054 = local_57;
                        let _e1056 = global.member_19[_e1054];
                        let _e1057 = (min(_e1019.z, 1f) - _e1056);
                        let _e1060 = global.member_22;
                        let _e1061 = _e1060.xy;
                        let _e1062 = (_e1061 * 0.5f);
                        let _e1064 = (_e1049 + (_e1019.xy * _e1048));
                        let _e1065 = (_e1049 + _e1062);
                        let _e1067 = ((_e1049 + _e1048) - _e1062);
                        let _e1072 = vec4<f32>(_e1065.x, _e1065.y, _e1067.x, _e1067.y);
                        switch bitcast<i32>(0u) {
                            default: {
                                let _e1076 = global.member_22[2u];
                                let _e1077 = i32(_e1076);
                                if (_e1077 <= 0i) {
                                    let _e1081 = clamp(_e1064, _e1072.xy, _e1072.zw);
                                    let _e1086 = textureSampleCompare(global_2, global_1, vec3<f32>(_e1081.x, _e1081.y, _e1057).xy, _e1057);
                                    phi_35377_ = _e1086;
                                    break;
                                }
                                let _e1088 = ((_e1064 / _e1061) + vec2<f32>(0.5f, 0.5f));
                                let _e1089 = floor(_e1088);
                                let _e1090 = (_e1088 - _e1089);
                                let _e1092 = (_e1077 == 1i);
                                if _e1092 {
                                    let _e1093 = (_e1090 * 2f);
                                    local_47[0i] = (vec2<f32>(3f, 3f) - _e1093);
                                    local_47[1i] = (vec2<f32>(1f, 1f) + _e1093);
                                    let _e1099 = local_47[0i];
                                    local_48[0i] = (((vec2<f32>(2f, 2f) - _e1090) / _e1099) - vec2<f32>(1f, 1f));
                                    let _e1103 = local_47[1i];
                                    local_48[1i] = ((_e1090 / _e1103) + vec2<f32>(1f, 1f));
                                } else {
                                    let _e1107 = (_e1090 * 3f);
                                    local_47[0i] = (vec2<f32>(4f, 4f) - _e1107);
                                    local_47[1i] = vec2<f32>(7f, 7f);
                                    local_47[2i] = (vec2<f32>(1f, 1f) + _e1107);
                                    let _e1115 = local_47[0i];
                                    local_48[0i] = (((vec2<f32>(3f, 3f) - (_e1090 * 2f)) / _e1115) - vec2<f32>(2f, 2f));
                                    let _e1120 = local_47[1i];
                                    local_48[1i] = ((vec2<f32>(3f, 3f) + _e1090) / _e1120);
                                    let _e1123 = local_47[2i];
                                    local_48[2i] = ((_e1090 / _e1123) + vec2<f32>(2f, 2f));
                                }
                                let _e1128 = select(3i, 2i, _e1092);
                                phi_35370_ = 0f;
                                phi_35367_ = 0i;
                                loop {
                                    let _e1130 = phi_35370_;
                                    let _e1132 = phi_35367_;
                                    local_58 = _e1130;
                                    if (_e1132 < _e1128) {
                                        phi_35376_ = _e1130;
                                        phi_35373_ = 0i;
                                        loop {
                                            let _e1135 = phi_35376_;
                                            let _e1137 = phi_35373_;
                                            local_102 = _e1135;
                                            if (_e1137 < _e1128) {
                                                continue;
                                            } else {
                                                break;
                                            }
                                            continuing {
                                                let _e1141 = local_48[_e1137][0u];
                                                let _e1144 = local_48[_e1132][1u];
                                                let _e1150 = clamp((_e1061 * ((_e1089 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e1141, _e1144))), _e1072.xy, _e1072.zw);
                                                let _e1153 = local_47[_e1137][0u];
                                                let _e1156 = local_47[_e1132][1u];
                                                let _e1162 = textureSampleCompare(global_2, global_1, vec3<f32>(_e1150.x, _e1150.y, _e1057).xy, _e1057);
                                                phi_35376_ = (_e1135 + ((_e1153 * _e1156) * _e1162));
                                                phi_35373_ = (_e1137 + 1i);
                                            }
                                        }
                                        continue;
                                    } else {
                                        break;
                                    }
                                    continuing {
                                        let _e13293 = local_102;
                                        phi_35370_ = _e13293;
                                        phi_35367_ = (_e1132 + 1i);
                                    }
                                }
                                let _e1168 = local_58;
                                phi_35377_ = (_e1168 * select(0.0069444445f, 0.0625f, _e1092));
                                break;
                            }
                        }
                        let _e1171 = phi_35377_;
                        phi_35378_ = _e1171;
                        break;
                    }
                }
                let _e1173 = phi_35378_;
                local_49 = array<vec3<f32>, 4>(vec3<f32>(1f, 0.45f, 0.45f), vec3<f32>(0.45f, 1f, 0.45f), vec3<f32>(0.5f, 0.6f, 1f), vec3<f32>(1f, 1f, 0.4f));
                let _e1175 = local_59;
                let _e1177 = local_49[_e1175];
                let _e1180 = local_60;
                let _e1182 = global.member_17[_e1180];
                phi_35418_ = _e1173;
                phi_35415_ = _e1177;
                if (_e984 > _e1182) {
                    let _e1186 = ((_e984 - _e1182) / (_e1000 - _e1182));
                    let _e1188 = local_61;
                    let _e1189 = (_e1188 + 1i);
                    if (_e1189 < _e976) {
                        let _e1193 = global.member_18[_e1189];
                        let _e1195 = (_e956 + (_e963 * _e1193));
                        switch bitcast<i32>(0u) {
                            default: {
                                let _e1199 = global.member_14[_e1189];
                                let _e1204 = (_e1199 * vec4<f32>(_e1195.x, _e1195.y, _e1195.z, 1f));
                                let _e1206 = (_e1204.x < 0f);
                                phi_7692_ = _e1206;
                                if !(_e1206) {
                                    phi_7692_ = (_e1204.x > 1f);
                                }
                                let _e1210 = phi_7692_;
                                phi_7699_ = _e1210;
                                if !(_e1210) {
                                    phi_7699_ = (_e1204.y < 0f);
                                }
                                let _e1215 = phi_7699_;
                                phi_7706_ = _e1215;
                                if !(_e1215) {
                                    phi_7706_ = (_e1204.y > 1f);
                                }
                                let _e1220 = phi_7706_;
                                if _e1220 {
                                    phi_35398_ = 1f;
                                    break;
                                }
                                let _e1228 = global.member_23;
                                let _e1229 = _e1228.xy;
                                let _e1230 = (vec2<f32>(f32((_e1189 & 1i)), f32((_e1189 >> bitcast<u32>(1i)))) * _e1229);
                                let _e1235 = global.member_19[_e1189];
                                let _e1236 = (min(_e1204.z, 1f) - _e1235);
                                let _e1239 = global.member_22;
                                let _e1240 = _e1239.xy;
                                let _e1241 = (_e1240 * 0.5f);
                                let _e1243 = (_e1230 + (_e1204.xy * _e1229));
                                let _e1244 = (_e1230 + _e1241);
                                let _e1246 = ((_e1230 + _e1229) - _e1241);
                                let _e1251 = vec4<f32>(_e1244.x, _e1244.y, _e1246.x, _e1246.y);
                                switch bitcast<i32>(0u) {
                                    default: {
                                        let _e1255 = global.member_22[2u];
                                        let _e1256 = i32(_e1255);
                                        if (_e1256 <= 0i) {
                                            let _e1260 = clamp(_e1243, _e1251.xy, _e1251.zw);
                                            let _e1265 = textureSampleCompare(global_2, global_1, vec3<f32>(_e1260.x, _e1260.y, _e1236).xy, _e1236);
                                            phi_35397_ = _e1265;
                                            break;
                                        }
                                        let _e1267 = ((_e1243 / _e1240) + vec2<f32>(0.5f, 0.5f));
                                        let _e1268 = floor(_e1267);
                                        let _e1269 = (_e1267 - _e1268);
                                        let _e1271 = (_e1256 == 1i);
                                        if _e1271 {
                                            let _e1272 = (_e1269 * 2f);
                                            local_45[0i] = (vec2<f32>(3f, 3f) - _e1272);
                                            local_45[1i] = (vec2<f32>(1f, 1f) + _e1272);
                                            let _e1278 = local_45[0i];
                                            local_46[0i] = (((vec2<f32>(2f, 2f) - _e1269) / _e1278) - vec2<f32>(1f, 1f));
                                            let _e1282 = local_45[1i];
                                            local_46[1i] = ((_e1269 / _e1282) + vec2<f32>(1f, 1f));
                                        } else {
                                            let _e1286 = (_e1269 * 3f);
                                            local_45[0i] = (vec2<f32>(4f, 4f) - _e1286);
                                            local_45[1i] = vec2<f32>(7f, 7f);
                                            local_45[2i] = (vec2<f32>(1f, 1f) + _e1286);
                                            let _e1294 = local_45[0i];
                                            local_46[0i] = (((vec2<f32>(3f, 3f) - (_e1269 * 2f)) / _e1294) - vec2<f32>(2f, 2f));
                                            let _e1299 = local_45[1i];
                                            local_46[1i] = ((vec2<f32>(3f, 3f) + _e1269) / _e1299);
                                            let _e1302 = local_45[2i];
                                            local_46[2i] = ((_e1269 / _e1302) + vec2<f32>(2f, 2f));
                                        }
                                        let _e1307 = select(3i, 2i, _e1271);
                                        phi_35390_ = 0f;
                                        phi_35387_ = 0i;
                                        loop {
                                            let _e1309 = phi_35390_;
                                            let _e1311 = phi_35387_;
                                            local_62 = _e1309;
                                            if (_e1311 < _e1307) {
                                                phi_35396_ = _e1309;
                                                phi_35393_ = 0i;
                                                loop {
                                                    let _e1314 = phi_35396_;
                                                    let _e1316 = phi_35393_;
                                                    local_103 = _e1314;
                                                    if (_e1316 < _e1307) {
                                                        continue;
                                                    } else {
                                                        break;
                                                    }
                                                    continuing {
                                                        let _e1320 = local_46[_e1316][0u];
                                                        let _e1323 = local_46[_e1311][1u];
                                                        let _e1329 = clamp((_e1240 * ((_e1268 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e1320, _e1323))), _e1251.xy, _e1251.zw);
                                                        let _e1332 = local_45[_e1316][0u];
                                                        let _e1335 = local_45[_e1311][1u];
                                                        let _e1341 = textureSampleCompare(global_2, global_1, vec3<f32>(_e1329.x, _e1329.y, _e1236).xy, _e1236);
                                                        phi_35396_ = (_e1314 + ((_e1332 * _e1335) * _e1341));
                                                        phi_35393_ = (_e1316 + 1i);
                                                    }
                                                }
                                                continue;
                                            } else {
                                                break;
                                            }
                                            continuing {
                                                let _e13308 = local_103;
                                                phi_35390_ = _e13308;
                                                phi_35387_ = (_e1311 + 1i);
                                            }
                                        }
                                        let _e1347 = local_62;
                                        phi_35397_ = (_e1347 * select(0.0069444445f, 0.0625f, _e1271));
                                        break;
                                    }
                                }
                                let _e1350 = phi_35397_;
                                phi_35398_ = _e1350;
                                break;
                            }
                        }
                        let _e1352 = phi_35398_;
                        local_50 = array<vec3<f32>, 4>(vec3<f32>(1f, 0.45f, 0.45f), vec3<f32>(0.45f, 1f, 0.45f), vec3<f32>(0.5f, 0.6f, 1f), vec3<f32>(1f, 1f, 0.4f));
                        let _e1355 = local_50[_e1189];
                        phi_35419_ = mix(_e1173, _e1352, _e1186);
                        phi_35416_ = mix(_e1177, _e1355, vec3(_e1186));
                    } else {
                        phi_35419_ = mix(_e1173, 1f, _e1186);
                        phi_35416_ = _e1177;
                    }
                    let _e1360 = phi_35419_;
                    let _e1362 = phi_35416_;
                    phi_35418_ = _e1360;
                    phi_35415_ = _e1362;
                }
                let _e1364 = phi_35418_;
                let _e1366 = phi_35415_;
                let _e1369 = global.member_22[3u];
                phi_35421_ = select(vec3<f32>(1f, 1f, 1f), _e1366, vec3((_e1369 > 0.5f)));
                phi_35420_ = _e1364;
                break;
            }
        }
        let _e1374 = phi_35421_;
        let _e1376 = phi_35420_;
        phi_35574_ = _e1376;
        phi_35543_ = (_e867 * _e1374);
    }
    let _e1379 = phi_35574_;
    let _e1381 = phi_35543_;
    let _e1383 = global.member_5;
    let _e1387 = global.member_4[3u];
    let _e1388 = (_e1383.xyz * _e1387);
    let _e1391 = global_8.member_6[3u];
    if (_e1391 > 0.5f) {
        phi_35473_ = 1f;
    } else {
        let _e1395 = global_8.member_4[3u];
        let _e1396 = textureSample(global_26, global_5, _e427);
        phi_35473_ = (1f + (_e1395 * (_e1396.x - 1f)));
    }
    let _e1402 = phi_35473_;
    let _e1404 = global_10[3u];
    let _e1405 = abs(_e1404);
    phi_35576_ = _e1402;
    if (_e1405 > 0f) {
        phi_35576_ = (_e1402 * min(_e1405, 1f));
    }
    let _e1410 = phi_35576_;
    if !(_e933) {
        let _e1412 = dot(_e948, _e952);
        let _e1419 = global_8.member_1[3u];
        let _e1423 = global_8.member_1[2u];
        let _e1430 = global.member_29[0u];
        let _e1431 = (_e1430 > 0.5f);
        if _e1431 {
            let _e1433 = global.member_29;
            let _e1440 = ((_e1433.z * _e948.x) - (_e1433.w * _e948.z));
            let _e1444 = ((_e1433.w * _e948.x) + (_e1433.z * _e948.z));
            let _e1448 = (1.092548f * _e1440);
            local_44 = array<f32, 9>(0.282095f, (0.488603f * _e948.y), (0.488603f * _e1444), (0.488603f * _e1440), (_e1448 * _e948.y), ((1.092548f * _e948.y) * _e1444), (0.315392f * (((3f * _e1444) * _e1444) - 1f)), (_e1448 * _e1444), (0.546274f * ((_e1440 * _e1440) - (_e948.y * _e948.y))));
            phi_36568_ = vec3<f32>(0f, 0f, 0f);
            phi_36567_ = 0i;
            loop {
                let _e1463 = phi_36568_;
                let _e1465 = phi_36567_;
                local_63 = _e1463;
                if (_e1465 < 9i) {
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e1469 = textureLoad(global_4, (vec2<i32>(496i, 256i) + vec2<i32>(_e1465, 0i)), 0i);
                    let _e1472 = local_44[_e1465];
                    phi_36568_ = (_e1463 + (_e1469.xyz * _e1472));
                    phi_36567_ = (_e1465 + 1i);
                }
            }
            let _e1477 = local_63;
            let _e1481 = global.member_29[1u];
            phi_36569_ = (max(_e1477, vec3<f32>(0f, 0f, 0f)) * _e1481);
        } else {
            let _e1484 = global.member_9;
            let _e1487 = global.member_8;
            let _e1496 = global.member_8[3u];
            phi_36569_ = (mix(_e1484.xyz, _e1487.xyz, vec3(((_e948.y * 0.5f) + 0.5f))) * _e1496);
        }
        let _e1499 = phi_36569_;
        let _e1505 = ((_e1381 * ((_e1499 * _e1410) + ((_e1388 * max(_e1412, 0f)) * _e1379))) + ((_e1388 * ((pow(max(dot(_e948, _e960), 0f), _e1419) * _e1423) * step(0f, _e1412))) * _e1379));
        let _e1508 = global.member_34[1u];
        phi_36596_ = _e1505;
        if (_e1508 > 0.5f) {
            if _e1431 {
                let _e1511 = global.member_29;
                let _e1518 = ((_e1511.z * _e948.x) - (_e1511.w * _e948.z));
                let _e1522 = ((_e1511.w * _e948.x) + (_e1511.z * _e948.z));
                let _e1526 = (1.092548f * _e1518);
                local_43 = array<f32, 9>(0.282095f, (0.488603f * _e948.y), (0.488603f * _e1522), (0.488603f * _e1518), (_e1526 * _e948.y), ((1.092548f * _e948.y) * _e1522), (0.315392f * (((3f * _e1522) * _e1522) - 1f)), (_e1526 * _e1522), (0.546274f * ((_e1518 * _e1518) - (_e948.y * _e948.y))));
                phi_36579_ = vec3<f32>(0f, 0f, 0f);
                phi_36578_ = 0i;
                loop {
                    let _e1541 = phi_36579_;
                    let _e1543 = phi_36578_;
                    local_64 = _e1541;
                    if (_e1543 < 9i) {
                        continue;
                    } else {
                        break;
                    }
                    continuing {
                        let _e1547 = textureLoad(global_4, (vec2<i32>(496i, 256i) + vec2<i32>(_e1543, 0i)), 0i);
                        let _e1550 = local_43[_e1543];
                        phi_36579_ = (_e1541 + (_e1547.xyz * _e1550));
                        phi_36578_ = (_e1543 + 1i);
                    }
                }
                let _e1555 = local_64;
                let _e1559 = global.member_29[1u];
                phi_36580_ = (max(_e1555, vec3<f32>(0f, 0f, 0f)) * _e1559);
            } else {
                let _e1562 = global.member_9;
                let _e1565 = global.member_8;
                let _e1574 = global.member_8[3u];
                phi_36580_ = (mix(_e1562.xyz, _e1565.xyz, vec3(((_e948.y * 0.5f) + 0.5f))) * _e1574);
            }
            let _e1577 = phi_36580_;
            let _e1581 = global.member_34[0u];
            phi_36586_ = _e1577;
            phi_36585_ = 0i;
            loop {
                let _e1584 = phi_36586_;
                let _e1586 = phi_36585_;
                local_65 = _e1584;
                if (_e1586 < i32(_e1508)) {
                    let _e1589 = (8i * (i32(_e1581) + _e1586));
                    let _e1593 = global_3.member[(_e1589 + 3i)];
                    let _e1594 = bitcast<vec4<f32>>(_e1593);
                    let _e1597 = global_3.member[_e1589];
                    let _e1598 = bitcast<vec4<f32>>(_e1597);
                    let _e1602 = global_3.member[(_e1589 + 1i)];
                    let _e1603 = bitcast<vec4<f32>>(_e1602);
                    let _e1607 = global_3.member[(_e1589 + 2i)];
                    let _e1608 = bitcast<vec4<f32>>(_e1607);
                    let _e1609 = _e1598.xyz;
                    let _e1613 = _e1603.xyz;
                    let _e1617 = _e1608.xyz;
                    let _e1621 = vec3<f32>((dot(_e1609, _e956) + _e1598.w), (dot(_e1613, _e956) + _e1603.w), (dot(_e1617, _e956) + _e1608.w));
                    let _e1622 = _e1594.xyz;
                    switch bitcast<i32>(0u) {
                        default: {
                            let _e1626 = (_e1622 - abs(_e1621));
                            let _e1631 = min(_e1626.x, min(_e1626.y, _e1626.z));
                            if (_e1631 <= 0f) {
                                phi_37548_ = 0f;
                                break;
                            }
                            if (_e1594.w <= 0f) {
                                phi_37548_ = 1f;
                                break;
                            }
                            let _e1635 = min((_e1631 / _e1594.w), 1f);
                            phi_37548_ = ((_e1635 * _e1635) * (3f - (2f * _e1635)));
                            break;
                        }
                    }
                    let _e1641 = phi_37548_;
                    if (_e1641 <= 0f) {
                        phi_37683_ = _e1584;
                        continue;
                    }
                    let _e1646 = global_3.member[(_e1589 + 4i)];
                    let _e1648 = bitcast<vec4<f32>>(_e1646).xyz;
                    let _e1652 = global_3.member[(_e1589 + 5i)];
                    let _e1653 = bitcast<vec4<f32>>(_e1652);
                    let _e1658 = global_3.member[(_e1589 + 6i)][0u];
                    let _e1659 = bitcast<i32>(_e1658);
                    let _e1660 = dot(_e1609, _e948);
                    let _e1661 = dot(_e1613, _e948);
                    let _e1662 = dot(_e1617, _e948);
                    let _e1663 = vec3<f32>(_e1660, _e1661, _e1662);
                    let _e1669 = ((_e956 + (_e948 * _e1653.x)) + (_e958 * _e1653.y));
                    let _e1684 = clamp(((((vec3<f32>((dot(_e1609, _e1669) + _e1598.w), (dot(_e1613, _e1669) + _e1603.w), (dot(_e1617, _e1669) + _e1608.w)) + _e1622) / max((_e1622 * 2f), vec3<f32>(0.000001f, 0.000001f, 0.000001f))) * _e1648) - vec3<f32>(0.5f, 0.5f, 0.5f)), vec3<f32>(0f, 0f, 0f), (_e1648 - vec3<f32>(1f, 1f, 1f)));
                    let _e1685 = vec3<i32>(_e1648);
                    let _e1689 = min(vec3<i32>(_e1684), max((_e1685 - vec3<i32>(2i, 2i, 2i)), vec3<i32>(0i, 0i, 0i)));
                    let _e1691 = (_e1684 - vec3<f32>(_e1689));
                    let _e1692 = (0.488603f * _e1661);
                    let _e1693 = (0.488603f * _e1662);
                    let _e1694 = (0.488603f * _e1660);
                    let _e1695 = (1.092548f * _e1660);
                    let _e1696 = (_e1695 * _e1661);
                    let _e1698 = ((1.092548f * _e1661) * _e1662);
                    let _e1702 = (0.315392f * (((3f * _e1662) * _e1662) - 1f));
                    let _e1703 = (_e1695 * _e1662);
                    let _e1707 = (0.546274f * ((_e1660 * _e1660) - (_e1661 * _e1661)));
                    let _e1708 = (_e1685 - vec3<i32>(1i, 1i, 1i));
                    let _e1709 = min(_e1689, _e1708);
                    let _e1720 = (_e1659 + ((_e1709.x + (_e1685.x * (_e1709.y + (_e1685.y * _e1709.z)))) * 4i));
                    let _e1721 = (vec3<f32>(1f, 1f, 1f) - _e1691);
                    let _e1728 = ((((((vec3<f32>(_e1709) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e1648) * _e1622) * 2f) - _e1622) - _e1621);
                    let _e1734 = (dot((_e1728 * inverseSqrt(max(dot(_e1728, _e1728), 0.0000000001f))), _e1663) + 1f);
                    let _e1737 = (_e1721.x * _e1721.y);
                    let _e1744 = (_e1720 + 3i);
                    let _e1748 = global_3.member[_e1744][1u];
                    let _e1753 = (((_e1737 * _e1721.z) * ((0.25f * (_e1734 * _e1734)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e1748).y > 0.5f)));
                    let _e1756 = global_3.member[_e1720];
                    let _e1760 = global_3.member[(_e1720 + 1i)];
                    let _e1764 = global_3.member[(_e1720 + 2i)];
                    let _e1767 = global_3.member[_e1744];
                    let _e1769 = unpack2x16float(_e1756.x);
                    let _e1771 = unpack2x16float(_e1756.y);
                    let _e1773 = unpack2x16float(_e1756.z);
                    let _e1775 = unpack2x16float(_e1756.w);
                    let _e1777 = unpack2x16float(_e1760.x);
                    let _e1779 = unpack2x16float(_e1760.y);
                    let _e1781 = unpack2x16float(_e1760.z);
                    let _e1783 = unpack2x16float(_e1760.w);
                    let _e1785 = unpack2x16float(_e1764.x);
                    let _e1787 = unpack2x16float(_e1764.y);
                    let _e1789 = unpack2x16float(_e1764.z);
                    let _e1791 = unpack2x16float(_e1764.w);
                    let _e1793 = unpack2x16float(_e1767.x);
                    let _e1849 = ((((((((((vec3<f32>(_e1769.x, _e1769.y, _e1771.x) * 0.282095f) + (vec3<f32>(_e1771.y, _e1773.x, _e1773.y) * _e1692)) + (vec3<f32>(_e1775.x, _e1775.y, _e1777.x) * _e1693)) + (vec3<f32>(_e1777.y, _e1779.x, _e1779.y) * _e1694)) + (vec3<f32>(_e1781.x, _e1781.y, _e1783.x) * _e1696)) + (vec3<f32>(_e1783.y, _e1785.x, _e1785.y) * _e1698)) + (vec3<f32>(_e1787.x, _e1787.y, _e1789.x) * _e1702)) + (vec3<f32>(_e1789.y, _e1791.x, _e1791.y) * _e1703)) + (vec3<f32>(_e1793.x, _e1793.y, unpack2x16float(_e1767.y).x) * _e1707)) * _e1753);
                    let _e1855 = min((_e1689 + vec3<i32>(1i, 0i, 0i)), _e1708);
                    let _e1864 = (_e1659 + ((_e1855.x + (_e1685.x * (_e1855.y + (_e1685.y * _e1855.z)))) * 4i));
                    let _e1871 = ((((((vec3<f32>(_e1855) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e1648) * _e1622) * 2f) - _e1622) - _e1621);
                    let _e1877 = (dot((_e1871 * inverseSqrt(max(dot(_e1871, _e1871), 0.0000000001f))), _e1663) + 1f);
                    let _e1879 = (_e1691.x * _e1721.y);
                    let _e1885 = (_e1864 + 3i);
                    let _e1889 = global_3.member[_e1885][1u];
                    let _e1894 = (((_e1879 * _e1721.z) * ((0.25f * (_e1877 * _e1877)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e1889).y > 0.5f)));
                    let _e1897 = global_3.member[_e1864];
                    let _e1901 = global_3.member[(_e1864 + 1i)];
                    let _e1905 = global_3.member[(_e1864 + 2i)];
                    let _e1908 = global_3.member[_e1885];
                    let _e1910 = unpack2x16float(_e1897.x);
                    let _e1912 = unpack2x16float(_e1897.y);
                    let _e1914 = unpack2x16float(_e1897.z);
                    let _e1916 = unpack2x16float(_e1897.w);
                    let _e1918 = unpack2x16float(_e1901.x);
                    let _e1920 = unpack2x16float(_e1901.y);
                    let _e1922 = unpack2x16float(_e1901.z);
                    let _e1924 = unpack2x16float(_e1901.w);
                    let _e1926 = unpack2x16float(_e1905.x);
                    let _e1928 = unpack2x16float(_e1905.y);
                    let _e1930 = unpack2x16float(_e1905.z);
                    let _e1932 = unpack2x16float(_e1905.w);
                    let _e1934 = unpack2x16float(_e1908.x);
                    let _e1990 = ((((((((((vec3<f32>(_e1910.x, _e1910.y, _e1912.x) * 0.282095f) + (vec3<f32>(_e1912.y, _e1914.x, _e1914.y) * _e1692)) + (vec3<f32>(_e1916.x, _e1916.y, _e1918.x) * _e1693)) + (vec3<f32>(_e1918.y, _e1920.x, _e1920.y) * _e1694)) + (vec3<f32>(_e1922.x, _e1922.y, _e1924.x) * _e1696)) + (vec3<f32>(_e1924.y, _e1926.x, _e1926.y) * _e1698)) + (vec3<f32>(_e1928.x, _e1928.y, _e1930.x) * _e1702)) + (vec3<f32>(_e1930.y, _e1932.x, _e1932.y) * _e1703)) + (vec3<f32>(_e1934.x, _e1934.y, unpack2x16float(_e1908.y).x) * _e1707)) * _e1894);
                    let _e1997 = min((_e1689 + vec3<i32>(0i, 1i, 0i)), _e1708);
                    let _e2006 = (_e1659 + ((_e1997.x + (_e1685.x * (_e1997.y + (_e1685.y * _e1997.z)))) * 4i));
                    let _e2013 = ((((((vec3<f32>(_e1997) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e1648) * _e1622) * 2f) - _e1622) - _e1621);
                    let _e2019 = (dot((_e2013 * inverseSqrt(max(dot(_e2013, _e2013), 0.0000000001f))), _e1663) + 1f);
                    let _e2021 = (_e1721.x * _e1691.y);
                    let _e2027 = (_e2006 + 3i);
                    let _e2031 = global_3.member[_e2027][1u];
                    let _e2036 = (((_e2021 * _e1721.z) * ((0.25f * (_e2019 * _e2019)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e2031).y > 0.5f)));
                    let _e2039 = global_3.member[_e2006];
                    let _e2043 = global_3.member[(_e2006 + 1i)];
                    let _e2047 = global_3.member[(_e2006 + 2i)];
                    let _e2050 = global_3.member[_e2027];
                    let _e2052 = unpack2x16float(_e2039.x);
                    let _e2054 = unpack2x16float(_e2039.y);
                    let _e2056 = unpack2x16float(_e2039.z);
                    let _e2058 = unpack2x16float(_e2039.w);
                    let _e2060 = unpack2x16float(_e2043.x);
                    let _e2062 = unpack2x16float(_e2043.y);
                    let _e2064 = unpack2x16float(_e2043.z);
                    let _e2066 = unpack2x16float(_e2043.w);
                    let _e2068 = unpack2x16float(_e2047.x);
                    let _e2070 = unpack2x16float(_e2047.y);
                    let _e2072 = unpack2x16float(_e2047.z);
                    let _e2074 = unpack2x16float(_e2047.w);
                    let _e2076 = unpack2x16float(_e2050.x);
                    let _e2132 = ((((((((((vec3<f32>(_e2052.x, _e2052.y, _e2054.x) * 0.282095f) + (vec3<f32>(_e2054.y, _e2056.x, _e2056.y) * _e1692)) + (vec3<f32>(_e2058.x, _e2058.y, _e2060.x) * _e1693)) + (vec3<f32>(_e2060.y, _e2062.x, _e2062.y) * _e1694)) + (vec3<f32>(_e2064.x, _e2064.y, _e2066.x) * _e1696)) + (vec3<f32>(_e2066.y, _e2068.x, _e2068.y) * _e1698)) + (vec3<f32>(_e2070.x, _e2070.y, _e2072.x) * _e1702)) + (vec3<f32>(_e2072.y, _e2074.x, _e2074.y) * _e1703)) + (vec3<f32>(_e2076.x, _e2076.y, unpack2x16float(_e2050.y).x) * _e1707)) * _e2036);
                    let _e2139 = min((_e1689 + vec3<i32>(1i, 1i, 0i)), _e1708);
                    let _e2148 = (_e1659 + ((_e2139.x + (_e1685.x * (_e2139.y + (_e1685.y * _e2139.z)))) * 4i));
                    let _e2155 = ((((((vec3<f32>(_e2139) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e1648) * _e1622) * 2f) - _e1622) - _e1621);
                    let _e2161 = (dot((_e2155 * inverseSqrt(max(dot(_e2155, _e2155), 0.0000000001f))), _e1663) + 1f);
                    let _e2162 = (_e1691.x * _e1691.y);
                    let _e2168 = (_e2148 + 3i);
                    let _e2172 = global_3.member[_e2168][1u];
                    let _e2177 = (((_e2162 * _e1721.z) * ((0.25f * (_e2161 * _e2161)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e2172).y > 0.5f)));
                    let _e2180 = global_3.member[_e2148];
                    let _e2184 = global_3.member[(_e2148 + 1i)];
                    let _e2188 = global_3.member[(_e2148 + 2i)];
                    let _e2191 = global_3.member[_e2168];
                    let _e2193 = unpack2x16float(_e2180.x);
                    let _e2195 = unpack2x16float(_e2180.y);
                    let _e2197 = unpack2x16float(_e2180.z);
                    let _e2199 = unpack2x16float(_e2180.w);
                    let _e2201 = unpack2x16float(_e2184.x);
                    let _e2203 = unpack2x16float(_e2184.y);
                    let _e2205 = unpack2x16float(_e2184.z);
                    let _e2207 = unpack2x16float(_e2184.w);
                    let _e2209 = unpack2x16float(_e2188.x);
                    let _e2211 = unpack2x16float(_e2188.y);
                    let _e2213 = unpack2x16float(_e2188.z);
                    let _e2215 = unpack2x16float(_e2188.w);
                    let _e2217 = unpack2x16float(_e2191.x);
                    let _e2273 = ((((((((((vec3<f32>(_e2193.x, _e2193.y, _e2195.x) * 0.282095f) + (vec3<f32>(_e2195.y, _e2197.x, _e2197.y) * _e1692)) + (vec3<f32>(_e2199.x, _e2199.y, _e2201.x) * _e1693)) + (vec3<f32>(_e2201.y, _e2203.x, _e2203.y) * _e1694)) + (vec3<f32>(_e2205.x, _e2205.y, _e2207.x) * _e1696)) + (vec3<f32>(_e2207.y, _e2209.x, _e2209.y) * _e1698)) + (vec3<f32>(_e2211.x, _e2211.y, _e2213.x) * _e1702)) + (vec3<f32>(_e2213.y, _e2215.x, _e2215.y) * _e1703)) + (vec3<f32>(_e2217.x, _e2217.y, unpack2x16float(_e2191.y).x) * _e1707)) * _e2177);
                    let _e2280 = min((_e1689 + vec3<i32>(0i, 0i, 1i)), _e1708);
                    let _e2289 = (_e1659 + ((_e2280.x + (_e1685.x * (_e2280.y + (_e1685.y * _e2280.z)))) * 4i));
                    let _e2296 = ((((((vec3<f32>(_e2280) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e1648) * _e1622) * 2f) - _e1622) - _e1621);
                    let _e2302 = (dot((_e2296 * inverseSqrt(max(dot(_e2296, _e2296), 0.0000000001f))), _e1663) + 1f);
                    let _e2309 = (_e2289 + 3i);
                    let _e2313 = global_3.member[_e2309][1u];
                    let _e2318 = (((_e1737 * _e1691.z) * ((0.25f * (_e2302 * _e2302)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e2313).y > 0.5f)));
                    let _e2321 = global_3.member[_e2289];
                    let _e2325 = global_3.member[(_e2289 + 1i)];
                    let _e2329 = global_3.member[(_e2289 + 2i)];
                    let _e2332 = global_3.member[_e2309];
                    let _e2334 = unpack2x16float(_e2321.x);
                    let _e2336 = unpack2x16float(_e2321.y);
                    let _e2338 = unpack2x16float(_e2321.z);
                    let _e2340 = unpack2x16float(_e2321.w);
                    let _e2342 = unpack2x16float(_e2325.x);
                    let _e2344 = unpack2x16float(_e2325.y);
                    let _e2346 = unpack2x16float(_e2325.z);
                    let _e2348 = unpack2x16float(_e2325.w);
                    let _e2350 = unpack2x16float(_e2329.x);
                    let _e2352 = unpack2x16float(_e2329.y);
                    let _e2354 = unpack2x16float(_e2329.z);
                    let _e2356 = unpack2x16float(_e2329.w);
                    let _e2358 = unpack2x16float(_e2332.x);
                    let _e2414 = ((((((((((vec3<f32>(_e2334.x, _e2334.y, _e2336.x) * 0.282095f) + (vec3<f32>(_e2336.y, _e2338.x, _e2338.y) * _e1692)) + (vec3<f32>(_e2340.x, _e2340.y, _e2342.x) * _e1693)) + (vec3<f32>(_e2342.y, _e2344.x, _e2344.y) * _e1694)) + (vec3<f32>(_e2346.x, _e2346.y, _e2348.x) * _e1696)) + (vec3<f32>(_e2348.y, _e2350.x, _e2350.y) * _e1698)) + (vec3<f32>(_e2352.x, _e2352.y, _e2354.x) * _e1702)) + (vec3<f32>(_e2354.y, _e2356.x, _e2356.y) * _e1703)) + (vec3<f32>(_e2358.x, _e2358.y, unpack2x16float(_e2332.y).x) * _e1707)) * _e2318);
                    let _e2421 = min((_e1689 + vec3<i32>(1i, 0i, 1i)), _e1708);
                    let _e2430 = (_e1659 + ((_e2421.x + (_e1685.x * (_e2421.y + (_e1685.y * _e2421.z)))) * 4i));
                    let _e2437 = ((((((vec3<f32>(_e2421) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e1648) * _e1622) * 2f) - _e1622) - _e1621);
                    let _e2443 = (dot((_e2437 * inverseSqrt(max(dot(_e2437, _e2437), 0.0000000001f))), _e1663) + 1f);
                    let _e2449 = (_e2430 + 3i);
                    let _e2453 = global_3.member[_e2449][1u];
                    let _e2458 = (((_e1879 * _e1691.z) * ((0.25f * (_e2443 * _e2443)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e2453).y > 0.5f)));
                    let _e2461 = global_3.member[_e2430];
                    let _e2465 = global_3.member[(_e2430 + 1i)];
                    let _e2469 = global_3.member[(_e2430 + 2i)];
                    let _e2472 = global_3.member[_e2449];
                    let _e2474 = unpack2x16float(_e2461.x);
                    let _e2476 = unpack2x16float(_e2461.y);
                    let _e2478 = unpack2x16float(_e2461.z);
                    let _e2480 = unpack2x16float(_e2461.w);
                    let _e2482 = unpack2x16float(_e2465.x);
                    let _e2484 = unpack2x16float(_e2465.y);
                    let _e2486 = unpack2x16float(_e2465.z);
                    let _e2488 = unpack2x16float(_e2465.w);
                    let _e2490 = unpack2x16float(_e2469.x);
                    let _e2492 = unpack2x16float(_e2469.y);
                    let _e2494 = unpack2x16float(_e2469.z);
                    let _e2496 = unpack2x16float(_e2469.w);
                    let _e2498 = unpack2x16float(_e2472.x);
                    let _e2554 = ((((((((((vec3<f32>(_e2474.x, _e2474.y, _e2476.x) * 0.282095f) + (vec3<f32>(_e2476.y, _e2478.x, _e2478.y) * _e1692)) + (vec3<f32>(_e2480.x, _e2480.y, _e2482.x) * _e1693)) + (vec3<f32>(_e2482.y, _e2484.x, _e2484.y) * _e1694)) + (vec3<f32>(_e2486.x, _e2486.y, _e2488.x) * _e1696)) + (vec3<f32>(_e2488.y, _e2490.x, _e2490.y) * _e1698)) + (vec3<f32>(_e2492.x, _e2492.y, _e2494.x) * _e1702)) + (vec3<f32>(_e2494.y, _e2496.x, _e2496.y) * _e1703)) + (vec3<f32>(_e2498.x, _e2498.y, unpack2x16float(_e2472.y).x) * _e1707)) * _e2458);
                    let _e2561 = min((_e1689 + vec3<i32>(0i, 1i, 1i)), _e1708);
                    let _e2570 = (_e1659 + ((_e2561.x + (_e1685.x * (_e2561.y + (_e1685.y * _e2561.z)))) * 4i));
                    let _e2577 = ((((((vec3<f32>(_e2561) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e1648) * _e1622) * 2f) - _e1622) - _e1621);
                    let _e2583 = (dot((_e2577 * inverseSqrt(max(dot(_e2577, _e2577), 0.0000000001f))), _e1663) + 1f);
                    let _e2589 = (_e2570 + 3i);
                    let _e2593 = global_3.member[_e2589][1u];
                    let _e2598 = (((_e2021 * _e1691.z) * ((0.25f * (_e2583 * _e2583)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e2593).y > 0.5f)));
                    let _e2601 = global_3.member[_e2570];
                    let _e2605 = global_3.member[(_e2570 + 1i)];
                    let _e2609 = global_3.member[(_e2570 + 2i)];
                    let _e2612 = global_3.member[_e2589];
                    let _e2614 = unpack2x16float(_e2601.x);
                    let _e2616 = unpack2x16float(_e2601.y);
                    let _e2618 = unpack2x16float(_e2601.z);
                    let _e2620 = unpack2x16float(_e2601.w);
                    let _e2622 = unpack2x16float(_e2605.x);
                    let _e2624 = unpack2x16float(_e2605.y);
                    let _e2626 = unpack2x16float(_e2605.z);
                    let _e2628 = unpack2x16float(_e2605.w);
                    let _e2630 = unpack2x16float(_e2609.x);
                    let _e2632 = unpack2x16float(_e2609.y);
                    let _e2634 = unpack2x16float(_e2609.z);
                    let _e2636 = unpack2x16float(_e2609.w);
                    let _e2638 = unpack2x16float(_e2612.x);
                    let _e2694 = ((((((((((vec3<f32>(_e2614.x, _e2614.y, _e2616.x) * 0.282095f) + (vec3<f32>(_e2616.y, _e2618.x, _e2618.y) * _e1692)) + (vec3<f32>(_e2620.x, _e2620.y, _e2622.x) * _e1693)) + (vec3<f32>(_e2622.y, _e2624.x, _e2624.y) * _e1694)) + (vec3<f32>(_e2626.x, _e2626.y, _e2628.x) * _e1696)) + (vec3<f32>(_e2628.y, _e2630.x, _e2630.y) * _e1698)) + (vec3<f32>(_e2632.x, _e2632.y, _e2634.x) * _e1702)) + (vec3<f32>(_e2634.y, _e2636.x, _e2636.y) * _e1703)) + (vec3<f32>(_e2638.x, _e2638.y, unpack2x16float(_e2612.y).x) * _e1707)) * _e2598);
                    let _e2701 = min((_e1689 + vec3<i32>(1i, 1i, 1i)), _e1708);
                    let _e2710 = (_e1659 + ((_e2701.x + (_e1685.x * (_e2701.y + (_e1685.y * _e2701.z)))) * 4i));
                    let _e2717 = ((((((vec3<f32>(_e2701) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e1648) * _e1622) * 2f) - _e1622) - _e1621);
                    let _e2723 = (dot((_e2717 * inverseSqrt(max(dot(_e2717, _e2717), 0.0000000001f))), _e1663) + 1f);
                    let _e2729 = (_e2710 + 3i);
                    let _e2733 = global_3.member[_e2729][1u];
                    let _e2738 = (((_e2162 * _e1691.z) * ((0.25f * (_e2723 * _e2723)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e2733).y > 0.5f)));
                    let _e2741 = global_3.member[_e2710];
                    let _e2745 = global_3.member[(_e2710 + 1i)];
                    let _e2749 = global_3.member[(_e2710 + 2i)];
                    let _e2752 = global_3.member[_e2729];
                    let _e2754 = unpack2x16float(_e2741.x);
                    let _e2756 = unpack2x16float(_e2741.y);
                    let _e2758 = unpack2x16float(_e2741.z);
                    let _e2760 = unpack2x16float(_e2741.w);
                    let _e2762 = unpack2x16float(_e2745.x);
                    let _e2764 = unpack2x16float(_e2745.y);
                    let _e2766 = unpack2x16float(_e2745.z);
                    let _e2768 = unpack2x16float(_e2745.w);
                    let _e2770 = unpack2x16float(_e2749.x);
                    let _e2772 = unpack2x16float(_e2749.y);
                    let _e2774 = unpack2x16float(_e2749.z);
                    let _e2776 = unpack2x16float(_e2749.w);
                    let _e2778 = unpack2x16float(_e2752.x);
                    let _e2834 = ((((((((((vec3<f32>(_e2754.x, _e2754.y, _e2756.x) * 0.282095f) + (vec3<f32>(_e2756.y, _e2758.x, _e2758.y) * _e1692)) + (vec3<f32>(_e2760.x, _e2760.y, _e2762.x) * _e1693)) + (vec3<f32>(_e2762.y, _e2764.x, _e2764.y) * _e1694)) + (vec3<f32>(_e2766.x, _e2766.y, _e2768.x) * _e1696)) + (vec3<f32>(_e2768.y, _e2770.x, _e2770.y) * _e1698)) + (vec3<f32>(_e2772.x, _e2772.y, _e2774.x) * _e1702)) + (vec3<f32>(_e2774.y, _e2776.x, _e2776.y) * _e1703)) + (vec3<f32>(_e2778.x, _e2778.y, unpack2x16float(_e2752.y).x) * _e1707)) * _e2738);
                    let _e2839 = (((((((vec4<f32>(_e1849.x, _e1849.y, _e1849.z, _e1753) + vec4<f32>(_e1990.x, _e1990.y, _e1990.z, _e1894)) + vec4<f32>(_e2132.x, _e2132.y, _e2132.z, _e2036)) + vec4<f32>(_e2273.x, _e2273.y, _e2273.z, _e2177)) + vec4<f32>(_e2414.x, _e2414.y, _e2414.z, _e2318)) + vec4<f32>(_e2554.x, _e2554.y, _e2554.z, _e2458)) + vec4<f32>(_e2694.x, _e2694.y, _e2694.z, _e2598)) + vec4<f32>(_e2834.x, _e2834.y, _e2834.z, _e2738));
                    phi_37684_ = _e1584;
                    if (_e2839.w > 0.00001f) {
                        phi_37684_ = mix(_e1584, ((max(_e2839.xyz, vec3<f32>(0f, 0f, 0f)) / vec3(_e2839.w)) * _e1653.z), vec3(_e1641));
                    }
                    let _e2851 = phi_37684_;
                    phi_37683_ = _e2851;
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e2853 = phi_37683_;
                    phi_36586_ = _e2853;
                    phi_36585_ = (_e1586 + 1i);
                }
            }
            let _e2856 = local_65;
            phi_36596_ = (_e1505 + ((_e1381 * (_e2856 - _e1577)) * _e1410));
        }
        let _e2862 = phi_36596_;
        let _e2865 = global.member_13[3u];
        phi_36595_ = _e2862;
        if (_e2865 > 0.5f) {
            let _e2868 = global.member_11;
            let _e2873 = global.member_11[3u];
            let _e2875 = global_16;
            let _e2878 = global.member_12;
            let _e2883 = global.member_13;
            let _e2886 = clamp(floor((_e2875.xy * _e2878.xy)), vec2<f32>(0f, 0f), (_e2883.xy - vec2<f32>(1f, 1f)));
            let _e2891 = global.member_12[2u];
            let _e2895 = global.member_12[3u];
            let _e2900 = global.member_13[2u];
            let _e2905 = global.member_13[1u];
            let _e2911 = global.member_13[0u];
            let _e2915 = u32(((((clamp(floor(((log2(max((dot(_e2868.xyz, _e956) + _e2873), 0.000001f)) * _e2891) + _e2895)), 0f, (_e2900 - 1f)) * _e2905) + _e2886.y) * _e2911) + _e2886.x));
            let _e2922 = global_17.member[(_e2915 >> bitcast<u32>(2i))][(_e2915 & 3u)];
            let _e2923 = (_e2922 & 65535u);
            phi_36597_ = _e2862;
            phi_36593_ = _e2923;
            loop {
                let _e2927 = phi_36597_;
                let _e2929 = phi_36593_;
                local_107 = _e2927;
                if (_e2929 < (_e2923 + (_e2922 >> bitcast<u32>(16i)))) {
                    let _e2932 = (_e2929 / 3u);
                    let _e2939 = global_18.member[(_e2932 >> bitcast<u32>(2i))][(_e2932 & 3u)];
                    let _e2945 = ((_e2939 >> bitcast<u32>(((_e2929 - (_e2932 * 3u)) * 10u))) & 1023u);
                    let _e2948 = global_12.member[_e2945];
                    let _e2950 = (_e2948.xyz - _e956);
                    let _e2951 = dot(_e2950, _e2950);
                    let _e2953 = (_e2951 * _e2948.w);
                    let _e2956 = clamp((1f - (_e2953 * _e2953)), 0f, 1f);
                    let _e2959 = (_e2950 * inverseSqrt(max(_e2951, 0.00000001f)));
                    let _e2962 = global_14.member[_e2945];
                    let _e2965 = global_15.member[_e2945];
                    let _e2973 = clamp(((dot(-(_e2959), _e2965.xyz) * _e2962.w) + _e2965.w), 0f, 1f);
                    let _e2980 = (_e2962.xyz * ((((_e2956 * _e2956) * _e2973) * _e2973) / max(_e2951, 0.0001f)));
                    phi_37513_ = _e2980;
                    if _e966 {
                        switch bitcast<i32>(0u) {
                            default: {
                                let _e2984 = global.member_21[2u];
                                let _e2985 = u32(_e2984);
                                if (_e2945 < _e2985) {
                                    let _e2989 = global.member_26[_e2945];
                                    let _e2992 = global.member_15[_e2945];
                                    let _e3001 = (_e2989.z * max((_e2992 * vec4<f32>(_e956.x, _e956.y, _e956.z, 1f)).w, 0f));
                                    let _e3004 = global.member_25[0u];
                                    let _e3010 = global.member_25[1u];
                                    let _e3013 = ((_e956 + (_e963 * (_e3001 * _e3004))) + (_e2959 * (_e3001 * _e3010)));
                                    let _e3018 = (_e2992 * vec4<f32>(_e3013.x, _e3013.y, _e3013.z, 1f));
                                    if (_e3018.w <= 0f) {
                                        phi_37462_ = 1f;
                                        break;
                                    }
                                    let _e3023 = (_e3018.xyz / vec3(_e3018.w));
                                    let _e3025 = (_e3023.x < 0f);
                                    phi_11257_ = _e3025;
                                    if !(_e3025) {
                                        phi_11257_ = (_e3023.x > 1f);
                                    }
                                    let _e3029 = phi_11257_;
                                    phi_11264_ = _e3029;
                                    if !(_e3029) {
                                        phi_11264_ = (_e3023.y < 0f);
                                    }
                                    let _e3034 = phi_11264_;
                                    phi_11271_ = _e3034;
                                    if !(_e3034) {
                                        phi_11271_ = (_e3023.y > 1f);
                                    }
                                    let _e3039 = phi_11271_;
                                    phi_11278_ = _e3039;
                                    if !(_e3039) {
                                        phi_11278_ = (_e3023.z > 1f);
                                    }
                                    let _e3044 = phi_11278_;
                                    if _e3044 {
                                        phi_37462_ = 1f;
                                        break;
                                    }
                                    let _e3047 = _e2989.xy;
                                    let _e3049 = global.member_23;
                                    let _e3050 = _e3049.zw;
                                    let _e3052 = global.member_22;
                                    let _e3053 = _e3052.xy;
                                    let _e3054 = (_e3053 * 0.5f);
                                    let _e3056 = (_e3047 + (_e3023.xy * _e3050));
                                    let _e3057 = (_e3047 + _e3054);
                                    let _e3059 = ((_e3047 + _e3050) - _e3054);
                                    let _e3064 = vec4<f32>(_e3057.x, _e3057.y, _e3059.x, _e3059.y);
                                    switch bitcast<i32>(0u) {
                                        default: {
                                            let _e3068 = global.member_22[2u];
                                            let _e3069 = i32(_e3068);
                                            if (_e3069 <= 0i) {
                                                let _e3073 = clamp(_e3056, _e3064.xy, _e3064.zw);
                                                let _e3078 = textureSampleCompare(global_2, global_1, vec3<f32>(_e3073.x, _e3073.y, _e3023.z).xy, _e3023.z);
                                                phi_37461_ = _e3078;
                                                break;
                                            }
                                            let _e3080 = ((_e3056 / _e3053) + vec2<f32>(0.5f, 0.5f));
                                            let _e3081 = floor(_e3080);
                                            let _e3082 = (_e3080 - _e3081);
                                            let _e3084 = (_e3069 == 1i);
                                            if _e3084 {
                                                let _e3085 = (_e3082 * 2f);
                                                local_39[0i] = (vec2<f32>(3f, 3f) - _e3085);
                                                local_39[1i] = (vec2<f32>(1f, 1f) + _e3085);
                                                let _e3091 = local_39[0i];
                                                local_40[0i] = (((vec2<f32>(2f, 2f) - _e3082) / _e3091) - vec2<f32>(1f, 1f));
                                                let _e3095 = local_39[1i];
                                                local_40[1i] = ((_e3082 / _e3095) + vec2<f32>(1f, 1f));
                                            } else {
                                                let _e3099 = (_e3082 * 3f);
                                                local_39[0i] = (vec2<f32>(4f, 4f) - _e3099);
                                                local_39[1i] = vec2<f32>(7f, 7f);
                                                local_39[2i] = (vec2<f32>(1f, 1f) + _e3099);
                                                let _e3107 = local_39[0i];
                                                local_40[0i] = (((vec2<f32>(3f, 3f) - (_e3082 * 2f)) / _e3107) - vec2<f32>(2f, 2f));
                                                let _e3112 = local_39[1i];
                                                local_40[1i] = ((vec2<f32>(3f, 3f) + _e3082) / _e3112);
                                                let _e3115 = local_39[2i];
                                                local_40[2i] = ((_e3082 / _e3115) + vec2<f32>(2f, 2f));
                                            }
                                            let _e3120 = select(3i, 2i, _e3084);
                                            phi_37454_ = 0f;
                                            phi_37451_ = 0i;
                                            loop {
                                                let _e3122 = phi_37454_;
                                                let _e3124 = phi_37451_;
                                                local_66 = _e3122;
                                                if (_e3124 < _e3120) {
                                                    phi_37460_ = _e3122;
                                                    phi_37457_ = 0i;
                                                    loop {
                                                        let _e3127 = phi_37460_;
                                                        let _e3129 = phi_37457_;
                                                        local_105 = _e3127;
                                                        if (_e3129 < _e3120) {
                                                            continue;
                                                        } else {
                                                            break;
                                                        }
                                                        continuing {
                                                            let _e3133 = local_40[_e3129][0u];
                                                            let _e3136 = local_40[_e3124][1u];
                                                            let _e3142 = clamp((_e3053 * ((_e3081 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e3133, _e3136))), _e3064.xy, _e3064.zw);
                                                            let _e3145 = local_39[_e3129][0u];
                                                            let _e3148 = local_39[_e3124][1u];
                                                            let _e3154 = textureSampleCompare(global_2, global_1, vec3<f32>(_e3142.x, _e3142.y, _e3023.z).xy, _e3023.z);
                                                            phi_37460_ = (_e3127 + ((_e3145 * _e3148) * _e3154));
                                                            phi_37457_ = (_e3129 + 1i);
                                                        }
                                                    }
                                                    continue;
                                                } else {
                                                    break;
                                                }
                                                continuing {
                                                    let _e13350 = local_105;
                                                    phi_37454_ = _e13350;
                                                    phi_37451_ = (_e3124 + 1i);
                                                }
                                            }
                                            let _e3160 = local_66;
                                            phi_37461_ = (_e3160 * select(0.0069444445f, 0.0625f, _e3084));
                                            break;
                                        }
                                    }
                                    let _e3163 = phi_37461_;
                                    phi_37462_ = _e3163;
                                    break;
                                }
                                let _e3164 = (_e2945 - _e2985);
                                let _e3167 = global.member_21[3u];
                                if (_e3164 >= u32(_e3167)) {
                                    phi_37462_ = 1f;
                                    break;
                                }
                                let _e3172 = global.member_27[_e3164];
                                let _e3175 = global.member_28[_e3164];
                                let _e3177 = _e3172.xyz;
                                let _e3180 = (_e3172.w * length((_e956 - _e3177)));
                                let _e3183 = global.member_25[0u];
                                let _e3189 = global.member_25[1u];
                                let _e3193 = (((_e956 + (_e963 * (_e3180 * _e3183))) + (_e2959 * (_e3180 * _e3189))) - _e3177);
                                let _e3194 = abs(_e3193);
                                let _e3197 = (_e3194.x >= _e3194.y);
                                phi_11348_ = _e3197;
                                if _e3197 {
                                    phi_11348_ = (_e3194.x >= _e3194.z);
                                }
                                let _e3201 = phi_11348_;
                                if _e3201 {
                                    phi_37438_ = select(1i, 0i, (_e3193.x > 0f));
                                    phi_37436_ = _e3194.x;
                                } else {
                                    let _e3206 = (_e3194.y >= _e3194.z);
                                    if _e3206 {
                                        phi_37439_ = select(3i, 2i, (_e3193.y > 0f));
                                    } else {
                                        phi_37439_ = select(5i, 4i, (_e3193.z > 0f));
                                    }
                                    let _e3214 = phi_37439_;
                                    phi_37438_ = _e3214;
                                    phi_37436_ = select(_e3194.z, _e3194.y, _e3206);
                                }
                                let _e3217 = phi_37438_;
                                let _e3219 = phi_37436_;
                                if (_e3219 <= 0f) {
                                    phi_37462_ = 1f;
                                    break;
                                }
                                local_41 = array<vec3<f32>, 6>(vec3<f32>(0f, 0f, 1f), vec3<f32>(0f, 0f, -1f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(1f, 0f, 0f));
                                let _e3222 = local_41[_e3217];
                                local_42 = array<vec3<f32>, 6>(vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 0f, -1f), vec3<f32>(0f, 0f, 1f), vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 1f, 0f));
                                let _e3225 = local_42[_e3217];
                                let _e3230 = global.member_24[2u];
                                let _e3233 = (vec2<f32>(dot(_e3193, _e3222), dot(_e3193, _e3225)) / vec2((_e3219 * _e3230)));
                                let _e3237 = (_e3175.z + (_e3175.w / _e3219));
                                if (_e3237 > 1f) {
                                    phi_37462_ = 1f;
                                    break;
                                }
                                let _e3252 = global.member_24;
                                let _e3253 = _e3252.xy;
                                let _e3255 = (_e3175.xy + (vec2<f32>(f32((_e3217 - (i32(floor((f32(_e3217) / f32(3i)))) * 3i))), f32((_e3217 / 3i))) * _e3253));
                                let _e3264 = global.member_22;
                                let _e3265 = _e3264.xy;
                                let _e3266 = (_e3265 * 0.5f);
                                let _e3268 = (_e3255 + (vec2<f32>((0.5f + (0.5f * _e3233.x)), (0.5f - (0.5f * _e3233.y))) * _e3253));
                                let _e3269 = (_e3255 + _e3266);
                                let _e3271 = ((_e3255 + _e3253) - _e3266);
                                let _e3276 = vec4<f32>(_e3269.x, _e3269.y, _e3271.x, _e3271.y);
                                switch bitcast<i32>(0u) {
                                    default: {
                                        let _e3280 = global.member_22[2u];
                                        let _e3281 = i32(_e3280);
                                        if (_e3281 <= 0i) {
                                            let _e3285 = clamp(_e3268, _e3276.xy, _e3276.zw);
                                            let _e3290 = textureSampleCompare(global_2, global_1, vec3<f32>(_e3285.x, _e3285.y, _e3237).xy, _e3237);
                                            phi_37450_ = _e3290;
                                            break;
                                        }
                                        let _e3292 = ((_e3268 / _e3265) + vec2<f32>(0.5f, 0.5f));
                                        let _e3293 = floor(_e3292);
                                        let _e3294 = (_e3292 - _e3293);
                                        let _e3296 = (_e3281 == 1i);
                                        if _e3296 {
                                            let _e3297 = (_e3294 * 2f);
                                            local_37[0i] = (vec2<f32>(3f, 3f) - _e3297);
                                            local_37[1i] = (vec2<f32>(1f, 1f) + _e3297);
                                            let _e3303 = local_37[0i];
                                            local_38[0i] = (((vec2<f32>(2f, 2f) - _e3294) / _e3303) - vec2<f32>(1f, 1f));
                                            let _e3307 = local_37[1i];
                                            local_38[1i] = ((_e3294 / _e3307) + vec2<f32>(1f, 1f));
                                        } else {
                                            let _e3311 = (_e3294 * 3f);
                                            local_37[0i] = (vec2<f32>(4f, 4f) - _e3311);
                                            local_37[1i] = vec2<f32>(7f, 7f);
                                            local_37[2i] = (vec2<f32>(1f, 1f) + _e3311);
                                            let _e3319 = local_37[0i];
                                            local_38[0i] = (((vec2<f32>(3f, 3f) - (_e3294 * 2f)) / _e3319) - vec2<f32>(2f, 2f));
                                            let _e3324 = local_37[1i];
                                            local_38[1i] = ((vec2<f32>(3f, 3f) + _e3294) / _e3324);
                                            let _e3327 = local_37[2i];
                                            local_38[2i] = ((_e3294 / _e3327) + vec2<f32>(2f, 2f));
                                        }
                                        let _e3332 = select(3i, 2i, _e3296);
                                        phi_37443_ = 0f;
                                        phi_37440_ = 0i;
                                        loop {
                                            let _e3334 = phi_37443_;
                                            let _e3336 = phi_37440_;
                                            local_67 = _e3334;
                                            if (_e3336 < _e3332) {
                                                phi_37449_ = _e3334;
                                                phi_37446_ = 0i;
                                                loop {
                                                    let _e3339 = phi_37449_;
                                                    let _e3341 = phi_37446_;
                                                    local_106 = _e3339;
                                                    if (_e3341 < _e3332) {
                                                        continue;
                                                    } else {
                                                        break;
                                                    }
                                                    continuing {
                                                        let _e3345 = local_38[_e3341][0u];
                                                        let _e3348 = local_38[_e3336][1u];
                                                        let _e3354 = clamp((_e3265 * ((_e3293 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e3345, _e3348))), _e3276.xy, _e3276.zw);
                                                        let _e3357 = local_37[_e3341][0u];
                                                        let _e3360 = local_37[_e3336][1u];
                                                        let _e3366 = textureSampleCompare(global_2, global_1, vec3<f32>(_e3354.x, _e3354.y, _e3237).xy, _e3237);
                                                        phi_37449_ = (_e3339 + ((_e3357 * _e3360) * _e3366));
                                                        phi_37446_ = (_e3341 + 1i);
                                                    }
                                                }
                                                continue;
                                            } else {
                                                break;
                                            }
                                            continuing {
                                                let _e13362 = local_106;
                                                phi_37443_ = _e13362;
                                                phi_37440_ = (_e3336 + 1i);
                                            }
                                        }
                                        let _e3372 = local_67;
                                        phi_37450_ = (_e3372 * select(0.0069444445f, 0.0625f, _e3296));
                                        break;
                                    }
                                }
                                let _e3375 = phi_37450_;
                                phi_37462_ = _e3375;
                                break;
                            }
                        }
                        let _e3377 = phi_37462_;
                        phi_37513_ = (_e2980 * _e3377);
                    }
                    let _e3380 = phi_37513_;
                    let _e3381 = dot(_e948, _e2959);
                    local_104 = (_e2927 + (((_e1381 * max(_e3381, 0f)) * _e3380) + (_e3380 * ((pow(max(dot(_e948, normalize((_e2959 + _e958))), 0f), _e1419) * _e1423) * step(0f, _e3381)))));
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e13342 = local_104;
                    phi_36597_ = _e13342;
                    phi_36593_ = (_e2929 + bitcast<u32>(1i));
                }
            }
            let _e13372 = local_107;
            phi_36595_ = _e13372;
        }
        let _e3399 = phi_36595_;
        phi_37172_ = vec3<f32>(0f, 0f, 0f);
        phi_36594_ = _e3399;
    } else {
        let _e3400 = textureSample(global_27, global_5, _e427);
        let _e3403 = global_8.member_4[0u];
        let _e3406 = clamp((_e3403 * _e3400.z), 0f, 1f);
        let _e3409 = global_8.member_4[1u];
        let _e3412 = clamp((_e3409 * _e3400.y), 0.045f, 1f);
        phi_35578_ = _e3406;
        phi_35577_ = _e3412;
        if (_e865 > 0f) {
            phi_35578_ = mix(_e3406, _e863.y, _e865);
            phi_35577_ = mix(_e3412, max(_e863.x, 0.045f), _e865);
        }
        let _e3420 = phi_35578_;
        let _e3422 = phi_35577_;
        let _e3425 = global_19.member_1[2u];
        if (_e3425 > 0.5f) {
            let _e3428 = ((_e413 - vec2<f32>(0.5f, 0.5f)) * 2f);
            let _e3429 = length(_e3428);
            let _e3432 = global_19.member_4[3u];
            let _e3435 = global_19.member_5[3u];
            let _e3436 = (_e3429 > 1f);
            if _e3436 {
                phi_36234_ = (_e3428 / vec2(_e3429));
            } else {
                phi_36234_ = _e3428;
            }
            let _e3440 = phi_36234_;
            switch bitcast<i32>(0u) {
                default: {
                    let _e3444 = asin(min(length(_e3440), 1f));
                    let _e3446 = asin(clamp(_e3432, 0.05f, 0.95f));
                    let _e3448 = min((_e3444 / _e3446), 1f);
                    let _e3450 = (1f - (_e3448 * _e3448));
                    let _e3456 = atan2(_e3440.y, (_e3440.x + 0.000000001f));
                    let _e3457 = sin(_e3444);
                    let _e3458 = cos(_e3456);
                    let _e3460 = sin(_e3456);
                    let _e3462 = cos(_e3444);
                    let _e3463 = vec3<f32>((_e3457 * _e3458), (_e3457 * _e3460), _e3462);
                    let _e3464 = (1f + ((0.08f * _e3450) * _e3450));
                    let _e3465 = (_e3463 * _e3464);
                    local_68 = _e3465;
                    local_69 = _e3465;
                    local_70 = _e3465;
                    local_71 = _e3465;
                    if (_e3444 >= _e3446) {
                        phi_36235_ = _e3463;
                        break;
                    }
                    phi_36235_ = normalize((_e3463 + ((vec3<f32>((_e3462 * _e3458), (_e3462 * _e3460), -(_e3457)) * (((0.32f * _e3448) * _e3450) / _e3446)) / vec3(_e3464))));
                    break;
                }
            }
            let _e3480 = phi_36235_;
            phi_36236_ = _e3480;
            if _e3436 {
                phi_36236_ = vec3<f32>(_e3480.x, _e3480.y, -(_e3480.z));
            }
            let _e3487 = phi_36236_;
            let _e3488 = global_10;
            let _e3489 = _e3488.xyz;
            if (dot(_e3489, _e3489) < 0.000000000001f) {
                let _e3494 = normalize((cross(_e963, vec3<f32>(1f, 0f, 0f)) + vec3<f32>(0f, 0.0001f, 0f)));
                phi_36241_ = _e963;
                phi_36240_ = _e3494;
                phi_36239_ = cross(_e3494, _e963);
            } else {
                let _e3496 = normalize(_e3489);
                let _e3499 = (_e963 - (_e3496 * _e3487.x));
                let _e3500 = length(_e3499);
                let _e3501 = _e3487.yz;
                let _e3505 = (_e3501 / vec2(max(length(_e3501), 0.000001f)));
                if (_e3500 > 0.000001f) {
                    phi_36237_ = (_e3499 / vec3(_e3500));
                } else {
                    phi_36237_ = _e963;
                }
                let _e3510 = phi_36237_;
                let _e3511 = cross(_e3496, _e3510);
                phi_36241_ = ((_e3510 * _e3505.y) + (_e3511 * _e3505.x));
                phi_36240_ = ((_e3510 * _e3505.x) - (_e3511 * _e3505.y));
                phi_36239_ = _e3496;
            }
            let _e3521 = phi_36241_;
            let _e3523 = phi_36240_;
            let _e3525 = phi_36239_;
            let _e3532 = global_19.member_6[2u];
            let _e3533 = (1.08f - _e3532);
            let _e3534 = (_e3429 < 1f);
            phi_12097_ = _e3534;
            if _e3534 {
                let _e3536 = local_68;
                phi_12097_ = (_e3536.z > _e3533);
            }
            let _e3540 = phi_12097_;
            if _e3540 {
                let _e3542 = refract(-(vec3<f32>(dot(_e958, _e3525), dot(_e958, _e3523), dot(_e958, _e3521))), _e3487, 0.74850297f);
                phi_36245_ = _e3428;
                if (_e3542.z < -0.001f) {
                    let _e3546 = local_69;
                    let _e3552 = local_71;
                    phi_36245_ = (_e3546.xy + (_e3542.xy * ((_e3533 - _e3552.z) / _e3542.z)));
                }
                let _e3559 = phi_36245_;
                let _e3562 = length(_e3559);
                let _e3563 = smoothstep((_e3432 - 0.035f), (_e3432 + 0.015f), _e3562);
                let _e3565 = global_19.member_4;
                let _e3566 = _e3565.xyz;
                let _e3567 = (_e3562 / _e3432);
                let _e3571 = atan2(_e3559.y, (_e3559.x + 0.000000001f));
                let _e3574 = vec2<f32>(cos(_e3571), sin(_e3571));
                let _e3575 = (_e3574 * 26f);
                let _e3579 = vec3<f32>(_e3575.x, _e3575.y, (_e3567 * 2.2f));
                let _e3580 = floor(_e3579);
                let _e3581 = (_e3579 - _e3580);
                let _e3585 = ((_e3581 * _e3581) * (vec3<f32>(3f, 3f, 3f) - (_e3581 * 2f)));
                let _e3587 = bitcast<vec3<u32>>(vec3<i32>(_e3580));
                let _e3596 = ((((_e3587.x * 1597334677u) ^ (_e3587.y * 3812015801u)) ^ (_e3587.z * 2798796415u)) * 1597334677u);
                let _e3605 = bitcast<vec3<u32>>(vec3<i32>((_e3580 + vec3<f32>(1f, 0f, 0f))));
                let _e3614 = ((((_e3605.x * 1597334677u) ^ (_e3605.y * 3812015801u)) ^ (_e3605.z * 2798796415u)) * 1597334677u);
                let _e3625 = bitcast<vec3<u32>>(vec3<i32>((_e3580 + vec3<f32>(0f, 1f, 0f))));
                let _e3634 = ((((_e3625.x * 1597334677u) ^ (_e3625.y * 3812015801u)) ^ (_e3625.z * 2798796415u)) * 1597334677u);
                let _e3643 = bitcast<vec3<u32>>(vec3<i32>((_e3580 + vec3<f32>(1f, 1f, 0f))));
                let _e3652 = ((((_e3643.x * 1597334677u) ^ (_e3643.y * 3812015801u)) ^ (_e3643.z * 2798796415u)) * 1597334677u);
                let _e3664 = bitcast<vec3<u32>>(vec3<i32>((_e3580 + vec3<f32>(0f, 0f, 1f))));
                let _e3673 = ((((_e3664.x * 1597334677u) ^ (_e3664.y * 3812015801u)) ^ (_e3664.z * 2798796415u)) * 1597334677u);
                let _e3682 = bitcast<vec3<u32>>(vec3<i32>((_e3580 + vec3<f32>(1f, 0f, 1f))));
                let _e3691 = ((((_e3682.x * 1597334677u) ^ (_e3682.y * 3812015801u)) ^ (_e3682.z * 2798796415u)) * 1597334677u);
                let _e3701 = bitcast<vec3<u32>>(vec3<i32>((_e3580 + vec3<f32>(0f, 1f, 1f))));
                let _e3710 = ((((_e3701.x * 1597334677u) ^ (_e3701.y * 3812015801u)) ^ (_e3701.z * 2798796415u)) * 1597334677u);
                let _e3719 = bitcast<vec3<u32>>(vec3<i32>((_e3580 + vec3<f32>(1f, 1f, 1f))));
                let _e3728 = ((((_e3719.x * 1597334677u) ^ (_e3719.y * 3812015801u)) ^ (_e3719.z * 2798796415u)) * 1597334677u);
                let _e3740 = (_e3574 * 61f);
                let _e3745 = vec3<f32>(_e3740.x, _e3740.y, ((_e3567 * 4f) + 7f));
                let _e3746 = floor(_e3745);
                let _e3747 = (_e3745 - _e3746);
                let _e3751 = ((_e3747 * _e3747) * (vec3<f32>(3f, 3f, 3f) - (_e3747 * 2f)));
                let _e3753 = bitcast<vec3<u32>>(vec3<i32>(_e3746));
                let _e3762 = ((((_e3753.x * 1597334677u) ^ (_e3753.y * 3812015801u)) ^ (_e3753.z * 2798796415u)) * 1597334677u);
                let _e3771 = bitcast<vec3<u32>>(vec3<i32>((_e3746 + vec3<f32>(1f, 0f, 0f))));
                let _e3780 = ((((_e3771.x * 1597334677u) ^ (_e3771.y * 3812015801u)) ^ (_e3771.z * 2798796415u)) * 1597334677u);
                let _e3791 = bitcast<vec3<u32>>(vec3<i32>((_e3746 + vec3<f32>(0f, 1f, 0f))));
                let _e3800 = ((((_e3791.x * 1597334677u) ^ (_e3791.y * 3812015801u)) ^ (_e3791.z * 2798796415u)) * 1597334677u);
                let _e3809 = bitcast<vec3<u32>>(vec3<i32>((_e3746 + vec3<f32>(1f, 1f, 0f))));
                let _e3818 = ((((_e3809.x * 1597334677u) ^ (_e3809.y * 3812015801u)) ^ (_e3809.z * 2798796415u)) * 1597334677u);
                let _e3830 = bitcast<vec3<u32>>(vec3<i32>((_e3746 + vec3<f32>(0f, 0f, 1f))));
                let _e3839 = ((((_e3830.x * 1597334677u) ^ (_e3830.y * 3812015801u)) ^ (_e3830.z * 2798796415u)) * 1597334677u);
                let _e3848 = bitcast<vec3<u32>>(vec3<i32>((_e3746 + vec3<f32>(1f, 0f, 1f))));
                let _e3857 = ((((_e3848.x * 1597334677u) ^ (_e3848.y * 3812015801u)) ^ (_e3848.z * 2798796415u)) * 1597334677u);
                let _e3867 = bitcast<vec3<u32>>(vec3<i32>((_e3746 + vec3<f32>(0f, 1f, 1f))));
                let _e3876 = ((((_e3867.x * 1597334677u) ^ (_e3867.y * 3812015801u)) ^ (_e3867.z * 2798796415u)) * 1597334677u);
                let _e3885 = bitcast<vec3<u32>>(vec3<i32>((_e3746 + vec3<f32>(1f, 1f, 1f))));
                let _e3894 = ((((_e3885.x * 1597334677u) ^ (_e3885.y * 3812015801u)) ^ (_e3885.z * 2798796415u)) * 1597334677u);
                let _e3907 = (_e3574 * 9f);
                let _e3912 = vec3<f32>(_e3907.x, _e3907.y, ((_e3567 * 7f) + 3f));
                let _e3913 = floor(_e3912);
                let _e3914 = (_e3912 - _e3913);
                let _e3918 = ((_e3914 * _e3914) * (vec3<f32>(3f, 3f, 3f) - (_e3914 * 2f)));
                let _e3920 = bitcast<vec3<u32>>(vec3<i32>(_e3913));
                let _e3929 = ((((_e3920.x * 1597334677u) ^ (_e3920.y * 3812015801u)) ^ (_e3920.z * 2798796415u)) * 1597334677u);
                let _e3938 = bitcast<vec3<u32>>(vec3<i32>((_e3913 + vec3<f32>(1f, 0f, 0f))));
                let _e3947 = ((((_e3938.x * 1597334677u) ^ (_e3938.y * 3812015801u)) ^ (_e3938.z * 2798796415u)) * 1597334677u);
                let _e3958 = bitcast<vec3<u32>>(vec3<i32>((_e3913 + vec3<f32>(0f, 1f, 0f))));
                let _e3967 = ((((_e3958.x * 1597334677u) ^ (_e3958.y * 3812015801u)) ^ (_e3958.z * 2798796415u)) * 1597334677u);
                let _e3976 = bitcast<vec3<u32>>(vec3<i32>((_e3913 + vec3<f32>(1f, 1f, 0f))));
                let _e3985 = ((((_e3976.x * 1597334677u) ^ (_e3976.y * 3812015801u)) ^ (_e3976.z * 2798796415u)) * 1597334677u);
                let _e3997 = bitcast<vec3<u32>>(vec3<i32>((_e3913 + vec3<f32>(0f, 0f, 1f))));
                let _e4006 = ((((_e3997.x * 1597334677u) ^ (_e3997.y * 3812015801u)) ^ (_e3997.z * 2798796415u)) * 1597334677u);
                let _e4015 = bitcast<vec3<u32>>(vec3<i32>((_e3913 + vec3<f32>(1f, 0f, 1f))));
                let _e4024 = ((((_e4015.x * 1597334677u) ^ (_e4015.y * 3812015801u)) ^ (_e4015.z * 2798796415u)) * 1597334677u);
                let _e4034 = bitcast<vec3<u32>>(vec3<i32>((_e3913 + vec3<f32>(0f, 1f, 1f))));
                let _e4043 = ((((_e4034.x * 1597334677u) ^ (_e4034.y * 3812015801u)) ^ (_e4034.z * 2798796415u)) * 1597334677u);
                let _e4052 = bitcast<vec3<u32>>(vec3<i32>((_e3913 + vec3<f32>(1f, 1f, 1f))));
                let _e4061 = ((((_e4052.x * 1597334677u) ^ (_e4052.y * 3812015801u)) ^ (_e4052.z * 2798796415u)) * 1597334677u);
                let _e4091 = global_19.member_6[0u];
                let _e4103 = global_19.member_5;
                let _e4111 = (_e3428 / vec2(max(_e3429, 0.0001f)));
                let _e4112 = (_e4111 * 6f);
                let _e4117 = vec3<f32>(_e4112.x, _e4112.y, ((_e3429 * 2.2f) + 1.7f));
                let _e4118 = floor(_e4117);
                let _e4119 = (_e4117 - _e4118);
                let _e4123 = ((_e4119 * _e4119) * (vec3<f32>(3f, 3f, 3f) - (_e4119 * 2f)));
                let _e4125 = bitcast<vec3<u32>>(vec3<i32>(_e4118));
                let _e4134 = ((((_e4125.x * 1597334677u) ^ (_e4125.y * 3812015801u)) ^ (_e4125.z * 2798796415u)) * 1597334677u);
                let _e4143 = bitcast<vec3<u32>>(vec3<i32>((_e4118 + vec3<f32>(1f, 0f, 0f))));
                let _e4152 = ((((_e4143.x * 1597334677u) ^ (_e4143.y * 3812015801u)) ^ (_e4143.z * 2798796415u)) * 1597334677u);
                let _e4163 = bitcast<vec3<u32>>(vec3<i32>((_e4118 + vec3<f32>(0f, 1f, 0f))));
                let _e4172 = ((((_e4163.x * 1597334677u) ^ (_e4163.y * 3812015801u)) ^ (_e4163.z * 2798796415u)) * 1597334677u);
                let _e4181 = bitcast<vec3<u32>>(vec3<i32>((_e4118 + vec3<f32>(1f, 1f, 0f))));
                let _e4190 = ((((_e4181.x * 1597334677u) ^ (_e4181.y * 3812015801u)) ^ (_e4181.z * 2798796415u)) * 1597334677u);
                let _e4202 = bitcast<vec3<u32>>(vec3<i32>((_e4118 + vec3<f32>(0f, 0f, 1f))));
                let _e4211 = ((((_e4202.x * 1597334677u) ^ (_e4202.y * 3812015801u)) ^ (_e4202.z * 2798796415u)) * 1597334677u);
                let _e4220 = bitcast<vec3<u32>>(vec3<i32>((_e4118 + vec3<f32>(1f, 0f, 1f))));
                let _e4229 = ((((_e4220.x * 1597334677u) ^ (_e4220.y * 3812015801u)) ^ (_e4220.z * 2798796415u)) * 1597334677u);
                let _e4239 = bitcast<vec3<u32>>(vec3<i32>((_e4118 + vec3<f32>(0f, 1f, 1f))));
                let _e4248 = ((((_e4239.x * 1597334677u) ^ (_e4239.y * 3812015801u)) ^ (_e4239.z * 2798796415u)) * 1597334677u);
                let _e4257 = bitcast<vec3<u32>>(vec3<i32>((_e4118 + vec3<f32>(1f, 1f, 1f))));
                let _e4266 = ((((_e4257.x * 1597334677u) ^ (_e4257.y * 3812015801u)) ^ (_e4257.z * 2798796415u)) * 1597334677u);
                let _e4277 = (_e4111 * 15f);
                let _e4282 = vec3<f32>(_e4277.x, _e4277.y, ((_e3429 * 5f) + 9.3f));
                let _e4283 = floor(_e4282);
                let _e4284 = (_e4282 - _e4283);
                let _e4288 = ((_e4284 * _e4284) * (vec3<f32>(3f, 3f, 3f) - (_e4284 * 2f)));
                let _e4290 = bitcast<vec3<u32>>(vec3<i32>(_e4283));
                let _e4299 = ((((_e4290.x * 1597334677u) ^ (_e4290.y * 3812015801u)) ^ (_e4290.z * 2798796415u)) * 1597334677u);
                let _e4308 = bitcast<vec3<u32>>(vec3<i32>((_e4283 + vec3<f32>(1f, 0f, 0f))));
                let _e4317 = ((((_e4308.x * 1597334677u) ^ (_e4308.y * 3812015801u)) ^ (_e4308.z * 2798796415u)) * 1597334677u);
                let _e4328 = bitcast<vec3<u32>>(vec3<i32>((_e4283 + vec3<f32>(0f, 1f, 0f))));
                let _e4337 = ((((_e4328.x * 1597334677u) ^ (_e4328.y * 3812015801u)) ^ (_e4328.z * 2798796415u)) * 1597334677u);
                let _e4346 = bitcast<vec3<u32>>(vec3<i32>((_e4283 + vec3<f32>(1f, 1f, 0f))));
                let _e4355 = ((((_e4346.x * 1597334677u) ^ (_e4346.y * 3812015801u)) ^ (_e4346.z * 2798796415u)) * 1597334677u);
                let _e4367 = bitcast<vec3<u32>>(vec3<i32>((_e4283 + vec3<f32>(0f, 0f, 1f))));
                let _e4376 = ((((_e4367.x * 1597334677u) ^ (_e4367.y * 3812015801u)) ^ (_e4367.z * 2798796415u)) * 1597334677u);
                let _e4385 = bitcast<vec3<u32>>(vec3<i32>((_e4283 + vec3<f32>(1f, 0f, 1f))));
                let _e4394 = ((((_e4385.x * 1597334677u) ^ (_e4385.y * 3812015801u)) ^ (_e4385.z * 2798796415u)) * 1597334677u);
                let _e4404 = bitcast<vec3<u32>>(vec3<i32>((_e4283 + vec3<f32>(0f, 1f, 1f))));
                let _e4413 = ((((_e4404.x * 1597334677u) ^ (_e4404.y * 3812015801u)) ^ (_e4404.z * 2798796415u)) * 1597334677u);
                let _e4422 = bitcast<vec3<u32>>(vec3<i32>((_e4283 + vec3<f32>(1f, 1f, 1f))));
                let _e4431 = ((((_e4422.x * 1597334677u) ^ (_e4422.y * 3812015801u)) ^ (_e4422.z * 2798796415u)) * 1597334677u);
                let _e4461 = global_19.member_6[1u];
                phi_36252_ = _e3563;
                phi_36250_ = (1f - _e3563);
                phi_36246_ = mix(mix(vec3<f32>(0.004f, 0.004f, 0.004f), (mix(((_e3566 * (0.45f + (1.1f * ((mix(mix(mix((f32(((_e3596 ^ (_e3596 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e3614 ^ (_e3614 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e3585.x), mix((f32(((_e3634 ^ (_e3634 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e3652 ^ (_e3652 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e3585.x), _e3585.y), mix(mix((f32(((_e3673 ^ (_e3673 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e3691 ^ (_e3691 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e3585.x), mix((f32(((_e3710 ^ (_e3710 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e3728 ^ (_e3728 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e3585.x), _e3585.y), _e3585.z) * 0.65f) + (mix(mix(mix((f32(((_e3762 ^ (_e3762 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e3780 ^ (_e3780 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e3751.x), mix((f32(((_e3800 ^ (_e3800 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e3818 ^ (_e3818 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e3751.x), _e3751.y), mix(mix((f32(((_e3839 ^ (_e3839 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e3857 ^ (_e3857 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e3751.x), mix((f32(((_e3876 ^ (_e3876 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e3894 ^ (_e3894 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e3751.x), _e3751.y), _e3751.z) * 0.35f))))) * mix(0.55f, 1f, smoothstep(0.25f, 0.55f, mix(mix(mix((f32(((_e3929 ^ (_e3929 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e3947 ^ (_e3947 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e3918.x), mix((f32(((_e3967 ^ (_e3967 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e3985 ^ (_e3985 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e3918.x), _e3918.y), mix(mix((f32(((_e4006 ^ (_e4006 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e4024 ^ (_e4024 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e3918.x), mix((f32(((_e4043 ^ (_e4043 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e4061 ^ (_e4061 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e3918.x), _e3918.y), _e3918.z)))), ((_e3566 * 1.7f) + vec3<f32>(0.05f, 0.035f, 0f)), vec3((exp(-(pow(((_e3567 - (_e3435 + 0.17f)) * 11.111111f), 2f))) * 0.55f))) * (1f - ((_e4091 * 0.85f) * smoothstep(0.72f, 1f, _e3567)))), vec3(smoothstep((_e3435 - 0.025f), (_e3435 + 0.025f), _e3567))), (mix((_e4103.xyz * mix(vec3<f32>(1f, 1f, 1f), vec3<f32>(1.02f, 0.86f, 0.82f), vec3(smoothstep(0.45f, 1f, _e3429)))), vec3<f32>(0.5f, 0.07f, 0.06f), vec3(clamp(((((pow((1f - abs(((2f * mix(mix(mix((f32(((_e4134 ^ (_e4134 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e4152 ^ (_e4152 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e4123.x), mix((f32(((_e4172 ^ (_e4172 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e4190 ^ (_e4190 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e4123.x), _e4123.y), mix(mix((f32(((_e4211 ^ (_e4211 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e4229 ^ (_e4229 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e4123.x), mix((f32(((_e4248 ^ (_e4248 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e4266 ^ (_e4266 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e4123.x), _e4123.y), _e4123.z)) - 1f))), 24f) + ((0.5f * pow((1f - abs(((2f * mix(mix(mix((f32(((_e4299 ^ (_e4299 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e4317 ^ (_e4317 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e4288.x), mix((f32(((_e4337 ^ (_e4337 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e4355 ^ (_e4355 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e4288.x), _e4288.y), mix(mix((f32(((_e4376 ^ (_e4376 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e4394 ^ (_e4394 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e4288.x), mix((f32(((_e4413 ^ (_e4413 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e4431 ^ (_e4431 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e4288.x), _e4288.y), _e4288.z)) - 1f))), 30f)) * smoothstep(0.6f, 0.9f, _e3429))) * smoothstep((_e3432 + 0.08f), 0.95f, _e3429)) * _e4461) * 1.4f), 0f, 0.8f))) * (1f - (0.6f * _e4091))), vec3(_e3563));
            } else {
                let _e4474 = global_19.member_5;
                let _e4482 = (_e3428 / vec2(max(_e3429, 0.0001f)));
                let _e4483 = (_e4482 * 6f);
                let _e4488 = vec3<f32>(_e4483.x, _e4483.y, ((_e3429 * 2.2f) + 1.7f));
                let _e4489 = floor(_e4488);
                let _e4490 = (_e4488 - _e4489);
                let _e4494 = ((_e4490 * _e4490) * (vec3<f32>(3f, 3f, 3f) - (_e4490 * 2f)));
                let _e4496 = bitcast<vec3<u32>>(vec3<i32>(_e4489));
                let _e4505 = ((((_e4496.x * 1597334677u) ^ (_e4496.y * 3812015801u)) ^ (_e4496.z * 2798796415u)) * 1597334677u);
                let _e4514 = bitcast<vec3<u32>>(vec3<i32>((_e4489 + vec3<f32>(1f, 0f, 0f))));
                let _e4523 = ((((_e4514.x * 1597334677u) ^ (_e4514.y * 3812015801u)) ^ (_e4514.z * 2798796415u)) * 1597334677u);
                let _e4534 = bitcast<vec3<u32>>(vec3<i32>((_e4489 + vec3<f32>(0f, 1f, 0f))));
                let _e4543 = ((((_e4534.x * 1597334677u) ^ (_e4534.y * 3812015801u)) ^ (_e4534.z * 2798796415u)) * 1597334677u);
                let _e4552 = bitcast<vec3<u32>>(vec3<i32>((_e4489 + vec3<f32>(1f, 1f, 0f))));
                let _e4561 = ((((_e4552.x * 1597334677u) ^ (_e4552.y * 3812015801u)) ^ (_e4552.z * 2798796415u)) * 1597334677u);
                let _e4573 = bitcast<vec3<u32>>(vec3<i32>((_e4489 + vec3<f32>(0f, 0f, 1f))));
                let _e4582 = ((((_e4573.x * 1597334677u) ^ (_e4573.y * 3812015801u)) ^ (_e4573.z * 2798796415u)) * 1597334677u);
                let _e4591 = bitcast<vec3<u32>>(vec3<i32>((_e4489 + vec3<f32>(1f, 0f, 1f))));
                let _e4600 = ((((_e4591.x * 1597334677u) ^ (_e4591.y * 3812015801u)) ^ (_e4591.z * 2798796415u)) * 1597334677u);
                let _e4610 = bitcast<vec3<u32>>(vec3<i32>((_e4489 + vec3<f32>(0f, 1f, 1f))));
                let _e4619 = ((((_e4610.x * 1597334677u) ^ (_e4610.y * 3812015801u)) ^ (_e4610.z * 2798796415u)) * 1597334677u);
                let _e4628 = bitcast<vec3<u32>>(vec3<i32>((_e4489 + vec3<f32>(1f, 1f, 1f))));
                let _e4637 = ((((_e4628.x * 1597334677u) ^ (_e4628.y * 3812015801u)) ^ (_e4628.z * 2798796415u)) * 1597334677u);
                let _e4648 = (_e4482 * 15f);
                let _e4653 = vec3<f32>(_e4648.x, _e4648.y, ((_e3429 * 5f) + 9.3f));
                let _e4654 = floor(_e4653);
                let _e4655 = (_e4653 - _e4654);
                let _e4659 = ((_e4655 * _e4655) * (vec3<f32>(3f, 3f, 3f) - (_e4655 * 2f)));
                let _e4661 = bitcast<vec3<u32>>(vec3<i32>(_e4654));
                let _e4670 = ((((_e4661.x * 1597334677u) ^ (_e4661.y * 3812015801u)) ^ (_e4661.z * 2798796415u)) * 1597334677u);
                let _e4679 = bitcast<vec3<u32>>(vec3<i32>((_e4654 + vec3<f32>(1f, 0f, 0f))));
                let _e4688 = ((((_e4679.x * 1597334677u) ^ (_e4679.y * 3812015801u)) ^ (_e4679.z * 2798796415u)) * 1597334677u);
                let _e4699 = bitcast<vec3<u32>>(vec3<i32>((_e4654 + vec3<f32>(0f, 1f, 0f))));
                let _e4708 = ((((_e4699.x * 1597334677u) ^ (_e4699.y * 3812015801u)) ^ (_e4699.z * 2798796415u)) * 1597334677u);
                let _e4717 = bitcast<vec3<u32>>(vec3<i32>((_e4654 + vec3<f32>(1f, 1f, 0f))));
                let _e4726 = ((((_e4717.x * 1597334677u) ^ (_e4717.y * 3812015801u)) ^ (_e4717.z * 2798796415u)) * 1597334677u);
                let _e4738 = bitcast<vec3<u32>>(vec3<i32>((_e4654 + vec3<f32>(0f, 0f, 1f))));
                let _e4747 = ((((_e4738.x * 1597334677u) ^ (_e4738.y * 3812015801u)) ^ (_e4738.z * 2798796415u)) * 1597334677u);
                let _e4756 = bitcast<vec3<u32>>(vec3<i32>((_e4654 + vec3<f32>(1f, 0f, 1f))));
                let _e4765 = ((((_e4756.x * 1597334677u) ^ (_e4756.y * 3812015801u)) ^ (_e4756.z * 2798796415u)) * 1597334677u);
                let _e4775 = bitcast<vec3<u32>>(vec3<i32>((_e4654 + vec3<f32>(0f, 1f, 1f))));
                let _e4784 = ((((_e4775.x * 1597334677u) ^ (_e4775.y * 3812015801u)) ^ (_e4775.z * 2798796415u)) * 1597334677u);
                let _e4793 = bitcast<vec3<u32>>(vec3<i32>((_e4654 + vec3<f32>(1f, 1f, 1f))));
                let _e4802 = ((((_e4793.x * 1597334677u) ^ (_e4793.y * 3812015801u)) ^ (_e4793.z * 2798796415u)) * 1597334677u);
                let _e4832 = global_19.member_6[1u];
                let _e4840 = global_19.member_6[0u];
                phi_36252_ = 1f;
                phi_36250_ = 0f;
                phi_36246_ = (mix((_e4474.xyz * mix(vec3<f32>(1f, 1f, 1f), vec3<f32>(1.02f, 0.86f, 0.82f), vec3(smoothstep(0.45f, 1f, _e3429)))), vec3<f32>(0.5f, 0.07f, 0.06f), vec3(clamp(((((pow((1f - abs(((2f * mix(mix(mix((f32(((_e4505 ^ (_e4505 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e4523 ^ (_e4523 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e4494.x), mix((f32(((_e4543 ^ (_e4543 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e4561 ^ (_e4561 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e4494.x), _e4494.y), mix(mix((f32(((_e4582 ^ (_e4582 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e4600 ^ (_e4600 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e4494.x), mix((f32(((_e4619 ^ (_e4619 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e4637 ^ (_e4637 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e4494.x), _e4494.y), _e4494.z)) - 1f))), 24f) + ((0.5f * pow((1f - abs(((2f * mix(mix(mix((f32(((_e4670 ^ (_e4670 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e4688 ^ (_e4688 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e4659.x), mix((f32(((_e4708 ^ (_e4708 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e4726 ^ (_e4726 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e4659.x), _e4659.y), mix(mix((f32(((_e4747 ^ (_e4747 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e4765 ^ (_e4765 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e4659.x), mix((f32(((_e4784 ^ (_e4784 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e4802 ^ (_e4802 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e4659.x), _e4659.y), _e4659.z)) - 1f))), 30f)) * smoothstep(0.6f, 0.9f, _e3429))) * smoothstep((_e3432 + 0.08f), 0.95f, _e3429)) * _e4832) * 1.4f), 0f, 0.8f))) * (1f - ((_e4840 * 0.35f) * (1f - smoothstep(_e3432, (_e3432 + 0.07f), _e3429)))));
            }
            let _e4849 = phi_36252_;
            let _e4851 = phi_36250_;
            let _e4853 = phi_36246_;
            let _e4870 = select((((1f - (0.65f * smoothstep(0.45f, 0.95f, abs(_e3428.x)))) * (1f - (0.45f * smoothstep(0.15f, 0.6f, _e3428.y)))) * (1f - (0.3f * smoothstep(0.25f, 0.7f, -(_e3428.y))))), 0.2f, _e3436);
            let _e4871 = mix(1f, _e4870, 0.6f);
            let _e4872 = dot(_e963, _e952);
            let _e4889 = mix(_e963, _e3521, vec3(_e4851));
            let _e4891 = reflect(-(_e958), _e963);
            let _e4894 = global.member_29[0u];
            let _e4895 = (_e4894 > 0.5f);
            if _e4895 {
                let _e4897 = global.member_29;
                let _e4904 = ((_e4897.z * _e4889.x) - (_e4897.w * _e4889.z));
                let _e4908 = ((_e4897.w * _e4889.x) + (_e4897.z * _e4889.z));
                let _e4912 = (1.092548f * _e4904);
                local_36 = array<f32, 9>(0.282095f, (0.488603f * _e4889.y), (0.488603f * _e4908), (0.488603f * _e4904), (_e4912 * _e4889.y), ((1.092548f * _e4889.y) * _e4908), (0.315392f * (((3f * _e4908) * _e4908) - 1f)), (_e4912 * _e4908), (0.546274f * ((_e4904 * _e4904) - (_e4889.y * _e4889.y))));
                phi_36255_ = vec3<f32>(0f, 0f, 0f);
                phi_36254_ = 0i;
                loop {
                    let _e4927 = phi_36255_;
                    let _e4929 = phi_36254_;
                    local_72 = _e4927;
                    if (_e4929 < 9i) {
                        continue;
                    } else {
                        break;
                    }
                    continuing {
                        let _e4933 = textureLoad(global_4, (vec2<i32>(496i, 256i) + vec2<i32>(_e4929, 0i)), 0i);
                        let _e4936 = local_36[_e4929];
                        phi_36255_ = (_e4927 + (_e4933.xyz * _e4936));
                        phi_36254_ = (_e4929 + 1i);
                    }
                }
                let _e4941 = local_72;
                let _e4945 = global.member_29[1u];
                let _e4963 = vec2<f32>(((atan2(((_e4897.z * _e4891.x) - (_e4897.w * _e4891.z)), -(((_e4897.w * _e4891.x) + (_e4897.z * _e4891.z)))) * 0.15915494f) + 0.5f), (acos(clamp(_e4891.y, -1f, 1f)) * 0.31830987f));
                let _e4965 = ((_e4963 * vec2<f32>(512f, 256f)) - vec2<f32>(0.5f, 0.5f));
                let _e4966 = floor(_e4965);
                let _e4967 = (_e4965 - _e4966);
                let _e4969 = i32(_e4966.x);
                let _e4971 = i32(_e4966.y);
                phi_36256_ = _e4969;
                if (_e4969 < 0i) {
                    phi_36256_ = (_e4969 + 512i);
                }
                let _e4975 = phi_36256_;
                phi_36257_ = _e4975;
                if (_e4975 >= 512i) {
                    phi_36257_ = (_e4975 - 512i);
                }
                let _e4979 = phi_36257_;
                let _e4980 = (_e4979 + 1i);
                let _e4982 = select(_e4980, 0i, (_e4980 == 512i));
                let _e4984 = min((_e4971 + 1i), 255i);
                let _e4985 = max(_e4971, 0i);
                let _e4987 = textureLoad(global_4, vec2<i32>(_e4979, _e4985), 0i);
                let _e4990 = textureLoad(global_4, vec2<i32>(_e4982, _e4985), 0i);
                let _e4993 = textureLoad(global_4, vec2<i32>(_e4979, _e4984), 0i);
                let _e4996 = textureLoad(global_4, vec2<i32>(_e4982, _e4984), 0i);
                let _e4999 = vec3(_e4967.x);
                let _e5006 = ((_e4963 * vec2<f32>(256f, 128f)) - vec2<f32>(0.5f, 0.5f));
                let _e5007 = floor(_e5006);
                let _e5008 = (_e5006 - _e5007);
                let _e5010 = i32(_e5007.x);
                let _e5012 = i32(_e5007.y);
                phi_36263_ = _e5010;
                if (_e5010 < 0i) {
                    phi_36263_ = (_e5010 + 256i);
                }
                let _e5016 = phi_36263_;
                phi_36264_ = _e5016;
                if (_e5016 >= 256i) {
                    phi_36264_ = (_e5016 - 256i);
                }
                let _e5020 = phi_36264_;
                let _e5021 = (_e5020 + 1i);
                let _e5023 = select(_e5021, 0i, (_e5021 == 256i));
                let _e5025 = min((_e5012 + 1i), 127i);
                let _e5026 = max(_e5012, 0i);
                let _e5029 = textureLoad(global_4, (vec2<i32>(0i, 256i) + vec2<i32>(_e5020, _e5026)), 0i);
                let _e5033 = textureLoad(global_4, (vec2<i32>(0i, 256i) + vec2<i32>(_e5023, _e5026)), 0i);
                let _e5037 = textureLoad(global_4, (vec2<i32>(0i, 256i) + vec2<i32>(_e5020, _e5025)), 0i);
                let _e5041 = textureLoad(global_4, (vec2<i32>(0i, 256i) + vec2<i32>(_e5023, _e5025)), 0i);
                let _e5044 = vec3(_e5008.x);
                phi_36280_ = (mix(mix(mix(_e4987.xyz, _e4990.xyz, _e4999), mix(_e4993.xyz, _e4996.xyz, _e4999), vec3(_e4967.y)), mix(mix(_e5029.xyz, _e5033.xyz, _e5044), mix(_e5037.xyz, _e5041.xyz, _e5044), vec3(_e5008.y)), vec3<f32>(0.35f, 0.35f, 0.35f)) * _e4945);
                phi_36270_ = (max(_e4941, vec3<f32>(0f, 0f, 0f)) * _e4945);
            } else {
                let _e5053 = global.member_9;
                let _e5054 = _e5053.xyz;
                let _e5056 = global.member_8;
                let _e5057 = _e5056.xyz;
                let _e5065 = global.member_8[3u];
                let _e5066 = (mix(_e5054, _e5057, vec3(((_e4889.y * 0.5f) + 0.5f))) * _e5065);
                phi_36280_ = mix((mix(_e5054, _e5057, vec3(((_e4891.y * 0.5f) + 0.5f))) * _e5065), _e5066, vec3<f32>(0.07f, 0.07f, 0.07f));
                phi_36270_ = _e5066;
            }
            let _e5075 = phi_36280_;
            let _e5077 = phi_36270_;
            let _e5080 = global.member_34[1u];
            phi_36371_ = _e5077;
            if (_e5080 > 0.5f) {
                let _e5085 = global.member_34[0u];
                phi_36278_ = _e5077;
                phi_36277_ = 0i;
                loop {
                    let _e5088 = phi_36278_;
                    let _e5090 = phi_36277_;
                    local_108 = _e5088;
                    if (_e5090 < i32(_e5080)) {
                        let _e5093 = (8i * (i32(_e5085) + _e5090));
                        let _e5097 = global_3.member[(_e5093 + 3i)];
                        let _e5098 = bitcast<vec4<f32>>(_e5097);
                        let _e5101 = global_3.member[_e5093];
                        let _e5102 = bitcast<vec4<f32>>(_e5101);
                        let _e5106 = global_3.member[(_e5093 + 1i)];
                        let _e5107 = bitcast<vec4<f32>>(_e5106);
                        let _e5111 = global_3.member[(_e5093 + 2i)];
                        let _e5112 = bitcast<vec4<f32>>(_e5111);
                        let _e5113 = _e5102.xyz;
                        let _e5117 = _e5107.xyz;
                        let _e5121 = _e5112.xyz;
                        let _e5125 = vec3<f32>((dot(_e5113, _e956) + _e5102.w), (dot(_e5117, _e956) + _e5107.w), (dot(_e5121, _e956) + _e5112.w));
                        let _e5126 = _e5098.xyz;
                        switch bitcast<i32>(0u) {
                            default: {
                                let _e5130 = (_e5126 - abs(_e5125));
                                let _e5135 = min(_e5130.x, min(_e5130.y, _e5130.z));
                                if (_e5135 <= 0f) {
                                    phi_36562_ = 0f;
                                    break;
                                }
                                if (_e5098.w <= 0f) {
                                    phi_36562_ = 1f;
                                    break;
                                }
                                let _e5139 = min((_e5135 / _e5098.w), 1f);
                                phi_36562_ = ((_e5139 * _e5139) * (3f - (2f * _e5139)));
                                break;
                            }
                        }
                        let _e5145 = phi_36562_;
                        if (_e5145 <= 0f) {
                            phi_37661_ = _e5088;
                            continue;
                        }
                        let _e5150 = global_3.member[(_e5093 + 4i)];
                        let _e5152 = bitcast<vec4<f32>>(_e5150).xyz;
                        let _e5156 = global_3.member[(_e5093 + 5i)];
                        let _e5157 = bitcast<vec4<f32>>(_e5156);
                        let _e5162 = global_3.member[(_e5093 + 6i)][0u];
                        let _e5163 = bitcast<i32>(_e5162);
                        let _e5164 = dot(_e5113, _e4889);
                        let _e5165 = dot(_e5117, _e4889);
                        let _e5166 = dot(_e5121, _e4889);
                        let _e5167 = vec3<f32>(_e5164, _e5165, _e5166);
                        let _e5173 = ((_e956 + (_e4889 * _e5157.x)) + (_e958 * _e5157.y));
                        let _e5188 = clamp(((((vec3<f32>((dot(_e5113, _e5173) + _e5102.w), (dot(_e5117, _e5173) + _e5107.w), (dot(_e5121, _e5173) + _e5112.w)) + _e5126) / max((_e5126 * 2f), vec3<f32>(0.000001f, 0.000001f, 0.000001f))) * _e5152) - vec3<f32>(0.5f, 0.5f, 0.5f)), vec3<f32>(0f, 0f, 0f), (_e5152 - vec3<f32>(1f, 1f, 1f)));
                        let _e5189 = vec3<i32>(_e5152);
                        let _e5193 = min(vec3<i32>(_e5188), max((_e5189 - vec3<i32>(2i, 2i, 2i)), vec3<i32>(0i, 0i, 0i)));
                        let _e5195 = (_e5188 - vec3<f32>(_e5193));
                        let _e5196 = (0.488603f * _e5165);
                        let _e5197 = (0.488603f * _e5166);
                        let _e5198 = (0.488603f * _e5164);
                        let _e5199 = (1.092548f * _e5164);
                        let _e5200 = (_e5199 * _e5165);
                        let _e5202 = ((1.092548f * _e5165) * _e5166);
                        let _e5206 = (0.315392f * (((3f * _e5166) * _e5166) - 1f));
                        let _e5207 = (_e5199 * _e5166);
                        let _e5211 = (0.546274f * ((_e5164 * _e5164) - (_e5165 * _e5165)));
                        let _e5212 = (_e5189 - vec3<i32>(1i, 1i, 1i));
                        let _e5213 = min(_e5193, _e5212);
                        let _e5224 = (_e5163 + ((_e5213.x + (_e5189.x * (_e5213.y + (_e5189.y * _e5213.z)))) * 4i));
                        let _e5225 = (vec3<f32>(1f, 1f, 1f) - _e5195);
                        let _e5232 = ((((((vec3<f32>(_e5213) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e5152) * _e5126) * 2f) - _e5126) - _e5125);
                        let _e5238 = (dot((_e5232 * inverseSqrt(max(dot(_e5232, _e5232), 0.0000000001f))), _e5167) + 1f);
                        let _e5241 = (_e5225.x * _e5225.y);
                        let _e5248 = (_e5224 + 3i);
                        let _e5252 = global_3.member[_e5248][1u];
                        let _e5257 = (((_e5241 * _e5225.z) * ((0.25f * (_e5238 * _e5238)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e5252).y > 0.5f)));
                        let _e5260 = global_3.member[_e5224];
                        let _e5264 = global_3.member[(_e5224 + 1i)];
                        let _e5268 = global_3.member[(_e5224 + 2i)];
                        let _e5271 = global_3.member[_e5248];
                        let _e5273 = unpack2x16float(_e5260.x);
                        let _e5275 = unpack2x16float(_e5260.y);
                        let _e5277 = unpack2x16float(_e5260.z);
                        let _e5279 = unpack2x16float(_e5260.w);
                        let _e5281 = unpack2x16float(_e5264.x);
                        let _e5283 = unpack2x16float(_e5264.y);
                        let _e5285 = unpack2x16float(_e5264.z);
                        let _e5287 = unpack2x16float(_e5264.w);
                        let _e5289 = unpack2x16float(_e5268.x);
                        let _e5291 = unpack2x16float(_e5268.y);
                        let _e5293 = unpack2x16float(_e5268.z);
                        let _e5295 = unpack2x16float(_e5268.w);
                        let _e5297 = unpack2x16float(_e5271.x);
                        let _e5353 = ((((((((((vec3<f32>(_e5273.x, _e5273.y, _e5275.x) * 0.282095f) + (vec3<f32>(_e5275.y, _e5277.x, _e5277.y) * _e5196)) + (vec3<f32>(_e5279.x, _e5279.y, _e5281.x) * _e5197)) + (vec3<f32>(_e5281.y, _e5283.x, _e5283.y) * _e5198)) + (vec3<f32>(_e5285.x, _e5285.y, _e5287.x) * _e5200)) + (vec3<f32>(_e5287.y, _e5289.x, _e5289.y) * _e5202)) + (vec3<f32>(_e5291.x, _e5291.y, _e5293.x) * _e5206)) + (vec3<f32>(_e5293.y, _e5295.x, _e5295.y) * _e5207)) + (vec3<f32>(_e5297.x, _e5297.y, unpack2x16float(_e5271.y).x) * _e5211)) * _e5257);
                        let _e5359 = min((_e5193 + vec3<i32>(1i, 0i, 0i)), _e5212);
                        let _e5368 = (_e5163 + ((_e5359.x + (_e5189.x * (_e5359.y + (_e5189.y * _e5359.z)))) * 4i));
                        let _e5375 = ((((((vec3<f32>(_e5359) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e5152) * _e5126) * 2f) - _e5126) - _e5125);
                        let _e5381 = (dot((_e5375 * inverseSqrt(max(dot(_e5375, _e5375), 0.0000000001f))), _e5167) + 1f);
                        let _e5383 = (_e5195.x * _e5225.y);
                        let _e5389 = (_e5368 + 3i);
                        let _e5393 = global_3.member[_e5389][1u];
                        let _e5398 = (((_e5383 * _e5225.z) * ((0.25f * (_e5381 * _e5381)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e5393).y > 0.5f)));
                        let _e5401 = global_3.member[_e5368];
                        let _e5405 = global_3.member[(_e5368 + 1i)];
                        let _e5409 = global_3.member[(_e5368 + 2i)];
                        let _e5412 = global_3.member[_e5389];
                        let _e5414 = unpack2x16float(_e5401.x);
                        let _e5416 = unpack2x16float(_e5401.y);
                        let _e5418 = unpack2x16float(_e5401.z);
                        let _e5420 = unpack2x16float(_e5401.w);
                        let _e5422 = unpack2x16float(_e5405.x);
                        let _e5424 = unpack2x16float(_e5405.y);
                        let _e5426 = unpack2x16float(_e5405.z);
                        let _e5428 = unpack2x16float(_e5405.w);
                        let _e5430 = unpack2x16float(_e5409.x);
                        let _e5432 = unpack2x16float(_e5409.y);
                        let _e5434 = unpack2x16float(_e5409.z);
                        let _e5436 = unpack2x16float(_e5409.w);
                        let _e5438 = unpack2x16float(_e5412.x);
                        let _e5494 = ((((((((((vec3<f32>(_e5414.x, _e5414.y, _e5416.x) * 0.282095f) + (vec3<f32>(_e5416.y, _e5418.x, _e5418.y) * _e5196)) + (vec3<f32>(_e5420.x, _e5420.y, _e5422.x) * _e5197)) + (vec3<f32>(_e5422.y, _e5424.x, _e5424.y) * _e5198)) + (vec3<f32>(_e5426.x, _e5426.y, _e5428.x) * _e5200)) + (vec3<f32>(_e5428.y, _e5430.x, _e5430.y) * _e5202)) + (vec3<f32>(_e5432.x, _e5432.y, _e5434.x) * _e5206)) + (vec3<f32>(_e5434.y, _e5436.x, _e5436.y) * _e5207)) + (vec3<f32>(_e5438.x, _e5438.y, unpack2x16float(_e5412.y).x) * _e5211)) * _e5398);
                        let _e5501 = min((_e5193 + vec3<i32>(0i, 1i, 0i)), _e5212);
                        let _e5510 = (_e5163 + ((_e5501.x + (_e5189.x * (_e5501.y + (_e5189.y * _e5501.z)))) * 4i));
                        let _e5517 = ((((((vec3<f32>(_e5501) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e5152) * _e5126) * 2f) - _e5126) - _e5125);
                        let _e5523 = (dot((_e5517 * inverseSqrt(max(dot(_e5517, _e5517), 0.0000000001f))), _e5167) + 1f);
                        let _e5525 = (_e5225.x * _e5195.y);
                        let _e5531 = (_e5510 + 3i);
                        let _e5535 = global_3.member[_e5531][1u];
                        let _e5540 = (((_e5525 * _e5225.z) * ((0.25f * (_e5523 * _e5523)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e5535).y > 0.5f)));
                        let _e5543 = global_3.member[_e5510];
                        let _e5547 = global_3.member[(_e5510 + 1i)];
                        let _e5551 = global_3.member[(_e5510 + 2i)];
                        let _e5554 = global_3.member[_e5531];
                        let _e5556 = unpack2x16float(_e5543.x);
                        let _e5558 = unpack2x16float(_e5543.y);
                        let _e5560 = unpack2x16float(_e5543.z);
                        let _e5562 = unpack2x16float(_e5543.w);
                        let _e5564 = unpack2x16float(_e5547.x);
                        let _e5566 = unpack2x16float(_e5547.y);
                        let _e5568 = unpack2x16float(_e5547.z);
                        let _e5570 = unpack2x16float(_e5547.w);
                        let _e5572 = unpack2x16float(_e5551.x);
                        let _e5574 = unpack2x16float(_e5551.y);
                        let _e5576 = unpack2x16float(_e5551.z);
                        let _e5578 = unpack2x16float(_e5551.w);
                        let _e5580 = unpack2x16float(_e5554.x);
                        let _e5636 = ((((((((((vec3<f32>(_e5556.x, _e5556.y, _e5558.x) * 0.282095f) + (vec3<f32>(_e5558.y, _e5560.x, _e5560.y) * _e5196)) + (vec3<f32>(_e5562.x, _e5562.y, _e5564.x) * _e5197)) + (vec3<f32>(_e5564.y, _e5566.x, _e5566.y) * _e5198)) + (vec3<f32>(_e5568.x, _e5568.y, _e5570.x) * _e5200)) + (vec3<f32>(_e5570.y, _e5572.x, _e5572.y) * _e5202)) + (vec3<f32>(_e5574.x, _e5574.y, _e5576.x) * _e5206)) + (vec3<f32>(_e5576.y, _e5578.x, _e5578.y) * _e5207)) + (vec3<f32>(_e5580.x, _e5580.y, unpack2x16float(_e5554.y).x) * _e5211)) * _e5540);
                        let _e5643 = min((_e5193 + vec3<i32>(1i, 1i, 0i)), _e5212);
                        let _e5652 = (_e5163 + ((_e5643.x + (_e5189.x * (_e5643.y + (_e5189.y * _e5643.z)))) * 4i));
                        let _e5659 = ((((((vec3<f32>(_e5643) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e5152) * _e5126) * 2f) - _e5126) - _e5125);
                        let _e5665 = (dot((_e5659 * inverseSqrt(max(dot(_e5659, _e5659), 0.0000000001f))), _e5167) + 1f);
                        let _e5666 = (_e5195.x * _e5195.y);
                        let _e5672 = (_e5652 + 3i);
                        let _e5676 = global_3.member[_e5672][1u];
                        let _e5681 = (((_e5666 * _e5225.z) * ((0.25f * (_e5665 * _e5665)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e5676).y > 0.5f)));
                        let _e5684 = global_3.member[_e5652];
                        let _e5688 = global_3.member[(_e5652 + 1i)];
                        let _e5692 = global_3.member[(_e5652 + 2i)];
                        let _e5695 = global_3.member[_e5672];
                        let _e5697 = unpack2x16float(_e5684.x);
                        let _e5699 = unpack2x16float(_e5684.y);
                        let _e5701 = unpack2x16float(_e5684.z);
                        let _e5703 = unpack2x16float(_e5684.w);
                        let _e5705 = unpack2x16float(_e5688.x);
                        let _e5707 = unpack2x16float(_e5688.y);
                        let _e5709 = unpack2x16float(_e5688.z);
                        let _e5711 = unpack2x16float(_e5688.w);
                        let _e5713 = unpack2x16float(_e5692.x);
                        let _e5715 = unpack2x16float(_e5692.y);
                        let _e5717 = unpack2x16float(_e5692.z);
                        let _e5719 = unpack2x16float(_e5692.w);
                        let _e5721 = unpack2x16float(_e5695.x);
                        let _e5777 = ((((((((((vec3<f32>(_e5697.x, _e5697.y, _e5699.x) * 0.282095f) + (vec3<f32>(_e5699.y, _e5701.x, _e5701.y) * _e5196)) + (vec3<f32>(_e5703.x, _e5703.y, _e5705.x) * _e5197)) + (vec3<f32>(_e5705.y, _e5707.x, _e5707.y) * _e5198)) + (vec3<f32>(_e5709.x, _e5709.y, _e5711.x) * _e5200)) + (vec3<f32>(_e5711.y, _e5713.x, _e5713.y) * _e5202)) + (vec3<f32>(_e5715.x, _e5715.y, _e5717.x) * _e5206)) + (vec3<f32>(_e5717.y, _e5719.x, _e5719.y) * _e5207)) + (vec3<f32>(_e5721.x, _e5721.y, unpack2x16float(_e5695.y).x) * _e5211)) * _e5681);
                        let _e5784 = min((_e5193 + vec3<i32>(0i, 0i, 1i)), _e5212);
                        let _e5793 = (_e5163 + ((_e5784.x + (_e5189.x * (_e5784.y + (_e5189.y * _e5784.z)))) * 4i));
                        let _e5800 = ((((((vec3<f32>(_e5784) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e5152) * _e5126) * 2f) - _e5126) - _e5125);
                        let _e5806 = (dot((_e5800 * inverseSqrt(max(dot(_e5800, _e5800), 0.0000000001f))), _e5167) + 1f);
                        let _e5813 = (_e5793 + 3i);
                        let _e5817 = global_3.member[_e5813][1u];
                        let _e5822 = (((_e5241 * _e5195.z) * ((0.25f * (_e5806 * _e5806)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e5817).y > 0.5f)));
                        let _e5825 = global_3.member[_e5793];
                        let _e5829 = global_3.member[(_e5793 + 1i)];
                        let _e5833 = global_3.member[(_e5793 + 2i)];
                        let _e5836 = global_3.member[_e5813];
                        let _e5838 = unpack2x16float(_e5825.x);
                        let _e5840 = unpack2x16float(_e5825.y);
                        let _e5842 = unpack2x16float(_e5825.z);
                        let _e5844 = unpack2x16float(_e5825.w);
                        let _e5846 = unpack2x16float(_e5829.x);
                        let _e5848 = unpack2x16float(_e5829.y);
                        let _e5850 = unpack2x16float(_e5829.z);
                        let _e5852 = unpack2x16float(_e5829.w);
                        let _e5854 = unpack2x16float(_e5833.x);
                        let _e5856 = unpack2x16float(_e5833.y);
                        let _e5858 = unpack2x16float(_e5833.z);
                        let _e5860 = unpack2x16float(_e5833.w);
                        let _e5862 = unpack2x16float(_e5836.x);
                        let _e5918 = ((((((((((vec3<f32>(_e5838.x, _e5838.y, _e5840.x) * 0.282095f) + (vec3<f32>(_e5840.y, _e5842.x, _e5842.y) * _e5196)) + (vec3<f32>(_e5844.x, _e5844.y, _e5846.x) * _e5197)) + (vec3<f32>(_e5846.y, _e5848.x, _e5848.y) * _e5198)) + (vec3<f32>(_e5850.x, _e5850.y, _e5852.x) * _e5200)) + (vec3<f32>(_e5852.y, _e5854.x, _e5854.y) * _e5202)) + (vec3<f32>(_e5856.x, _e5856.y, _e5858.x) * _e5206)) + (vec3<f32>(_e5858.y, _e5860.x, _e5860.y) * _e5207)) + (vec3<f32>(_e5862.x, _e5862.y, unpack2x16float(_e5836.y).x) * _e5211)) * _e5822);
                        let _e5925 = min((_e5193 + vec3<i32>(1i, 0i, 1i)), _e5212);
                        let _e5934 = (_e5163 + ((_e5925.x + (_e5189.x * (_e5925.y + (_e5189.y * _e5925.z)))) * 4i));
                        let _e5941 = ((((((vec3<f32>(_e5925) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e5152) * _e5126) * 2f) - _e5126) - _e5125);
                        let _e5947 = (dot((_e5941 * inverseSqrt(max(dot(_e5941, _e5941), 0.0000000001f))), _e5167) + 1f);
                        let _e5953 = (_e5934 + 3i);
                        let _e5957 = global_3.member[_e5953][1u];
                        let _e5962 = (((_e5383 * _e5195.z) * ((0.25f * (_e5947 * _e5947)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e5957).y > 0.5f)));
                        let _e5965 = global_3.member[_e5934];
                        let _e5969 = global_3.member[(_e5934 + 1i)];
                        let _e5973 = global_3.member[(_e5934 + 2i)];
                        let _e5976 = global_3.member[_e5953];
                        let _e5978 = unpack2x16float(_e5965.x);
                        let _e5980 = unpack2x16float(_e5965.y);
                        let _e5982 = unpack2x16float(_e5965.z);
                        let _e5984 = unpack2x16float(_e5965.w);
                        let _e5986 = unpack2x16float(_e5969.x);
                        let _e5988 = unpack2x16float(_e5969.y);
                        let _e5990 = unpack2x16float(_e5969.z);
                        let _e5992 = unpack2x16float(_e5969.w);
                        let _e5994 = unpack2x16float(_e5973.x);
                        let _e5996 = unpack2x16float(_e5973.y);
                        let _e5998 = unpack2x16float(_e5973.z);
                        let _e6000 = unpack2x16float(_e5973.w);
                        let _e6002 = unpack2x16float(_e5976.x);
                        let _e6058 = ((((((((((vec3<f32>(_e5978.x, _e5978.y, _e5980.x) * 0.282095f) + (vec3<f32>(_e5980.y, _e5982.x, _e5982.y) * _e5196)) + (vec3<f32>(_e5984.x, _e5984.y, _e5986.x) * _e5197)) + (vec3<f32>(_e5986.y, _e5988.x, _e5988.y) * _e5198)) + (vec3<f32>(_e5990.x, _e5990.y, _e5992.x) * _e5200)) + (vec3<f32>(_e5992.y, _e5994.x, _e5994.y) * _e5202)) + (vec3<f32>(_e5996.x, _e5996.y, _e5998.x) * _e5206)) + (vec3<f32>(_e5998.y, _e6000.x, _e6000.y) * _e5207)) + (vec3<f32>(_e6002.x, _e6002.y, unpack2x16float(_e5976.y).x) * _e5211)) * _e5962);
                        let _e6065 = min((_e5193 + vec3<i32>(0i, 1i, 1i)), _e5212);
                        let _e6074 = (_e5163 + ((_e6065.x + (_e5189.x * (_e6065.y + (_e5189.y * _e6065.z)))) * 4i));
                        let _e6081 = ((((((vec3<f32>(_e6065) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e5152) * _e5126) * 2f) - _e5126) - _e5125);
                        let _e6087 = (dot((_e6081 * inverseSqrt(max(dot(_e6081, _e6081), 0.0000000001f))), _e5167) + 1f);
                        let _e6093 = (_e6074 + 3i);
                        let _e6097 = global_3.member[_e6093][1u];
                        let _e6102 = (((_e5525 * _e5195.z) * ((0.25f * (_e6087 * _e6087)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e6097).y > 0.5f)));
                        let _e6105 = global_3.member[_e6074];
                        let _e6109 = global_3.member[(_e6074 + 1i)];
                        let _e6113 = global_3.member[(_e6074 + 2i)];
                        let _e6116 = global_3.member[_e6093];
                        let _e6118 = unpack2x16float(_e6105.x);
                        let _e6120 = unpack2x16float(_e6105.y);
                        let _e6122 = unpack2x16float(_e6105.z);
                        let _e6124 = unpack2x16float(_e6105.w);
                        let _e6126 = unpack2x16float(_e6109.x);
                        let _e6128 = unpack2x16float(_e6109.y);
                        let _e6130 = unpack2x16float(_e6109.z);
                        let _e6132 = unpack2x16float(_e6109.w);
                        let _e6134 = unpack2x16float(_e6113.x);
                        let _e6136 = unpack2x16float(_e6113.y);
                        let _e6138 = unpack2x16float(_e6113.z);
                        let _e6140 = unpack2x16float(_e6113.w);
                        let _e6142 = unpack2x16float(_e6116.x);
                        let _e6198 = ((((((((((vec3<f32>(_e6118.x, _e6118.y, _e6120.x) * 0.282095f) + (vec3<f32>(_e6120.y, _e6122.x, _e6122.y) * _e5196)) + (vec3<f32>(_e6124.x, _e6124.y, _e6126.x) * _e5197)) + (vec3<f32>(_e6126.y, _e6128.x, _e6128.y) * _e5198)) + (vec3<f32>(_e6130.x, _e6130.y, _e6132.x) * _e5200)) + (vec3<f32>(_e6132.y, _e6134.x, _e6134.y) * _e5202)) + (vec3<f32>(_e6136.x, _e6136.y, _e6138.x) * _e5206)) + (vec3<f32>(_e6138.y, _e6140.x, _e6140.y) * _e5207)) + (vec3<f32>(_e6142.x, _e6142.y, unpack2x16float(_e6116.y).x) * _e5211)) * _e6102);
                        let _e6205 = min((_e5193 + vec3<i32>(1i, 1i, 1i)), _e5212);
                        let _e6214 = (_e5163 + ((_e6205.x + (_e5189.x * (_e6205.y + (_e5189.y * _e6205.z)))) * 4i));
                        let _e6221 = ((((((vec3<f32>(_e6205) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e5152) * _e5126) * 2f) - _e5126) - _e5125);
                        let _e6227 = (dot((_e6221 * inverseSqrt(max(dot(_e6221, _e6221), 0.0000000001f))), _e5167) + 1f);
                        let _e6233 = (_e6214 + 3i);
                        let _e6237 = global_3.member[_e6233][1u];
                        let _e6242 = (((_e5666 * _e5195.z) * ((0.25f * (_e6227 * _e6227)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e6237).y > 0.5f)));
                        let _e6245 = global_3.member[_e6214];
                        let _e6249 = global_3.member[(_e6214 + 1i)];
                        let _e6253 = global_3.member[(_e6214 + 2i)];
                        let _e6256 = global_3.member[_e6233];
                        let _e6258 = unpack2x16float(_e6245.x);
                        let _e6260 = unpack2x16float(_e6245.y);
                        let _e6262 = unpack2x16float(_e6245.z);
                        let _e6264 = unpack2x16float(_e6245.w);
                        let _e6266 = unpack2x16float(_e6249.x);
                        let _e6268 = unpack2x16float(_e6249.y);
                        let _e6270 = unpack2x16float(_e6249.z);
                        let _e6272 = unpack2x16float(_e6249.w);
                        let _e6274 = unpack2x16float(_e6253.x);
                        let _e6276 = unpack2x16float(_e6253.y);
                        let _e6278 = unpack2x16float(_e6253.z);
                        let _e6280 = unpack2x16float(_e6253.w);
                        let _e6282 = unpack2x16float(_e6256.x);
                        let _e6338 = ((((((((((vec3<f32>(_e6258.x, _e6258.y, _e6260.x) * 0.282095f) + (vec3<f32>(_e6260.y, _e6262.x, _e6262.y) * _e5196)) + (vec3<f32>(_e6264.x, _e6264.y, _e6266.x) * _e5197)) + (vec3<f32>(_e6266.y, _e6268.x, _e6268.y) * _e5198)) + (vec3<f32>(_e6270.x, _e6270.y, _e6272.x) * _e5200)) + (vec3<f32>(_e6272.y, _e6274.x, _e6274.y) * _e5202)) + (vec3<f32>(_e6276.x, _e6276.y, _e6278.x) * _e5206)) + (vec3<f32>(_e6278.y, _e6280.x, _e6280.y) * _e5207)) + (vec3<f32>(_e6282.x, _e6282.y, unpack2x16float(_e6256.y).x) * _e5211)) * _e6242);
                        let _e6343 = (((((((vec4<f32>(_e5353.x, _e5353.y, _e5353.z, _e5257) + vec4<f32>(_e5494.x, _e5494.y, _e5494.z, _e5398)) + vec4<f32>(_e5636.x, _e5636.y, _e5636.z, _e5540)) + vec4<f32>(_e5777.x, _e5777.y, _e5777.z, _e5681)) + vec4<f32>(_e5918.x, _e5918.y, _e5918.z, _e5822)) + vec4<f32>(_e6058.x, _e6058.y, _e6058.z, _e5962)) + vec4<f32>(_e6198.x, _e6198.y, _e6198.z, _e6102)) + vec4<f32>(_e6338.x, _e6338.y, _e6338.z, _e6242));
                        phi_37662_ = _e5088;
                        if (_e6343.w > 0.00001f) {
                            phi_37662_ = mix(_e5088, ((max(_e6343.xyz, vec3<f32>(0f, 0f, 0f)) / vec3(_e6343.w)) * _e5157.z), vec3(_e5145));
                        }
                        let _e6355 = phi_37662_;
                        phi_37661_ = _e6355;
                        continue;
                    } else {
                        break;
                    }
                    continuing {
                        let _e6357 = phi_37661_;
                        phi_36278_ = _e6357;
                        phi_36277_ = (_e5090 + 1i);
                    }
                }
                let _e13407 = local_108;
                phi_36371_ = _e13407;
            }
            let _e6360 = phi_36371_;
            let _e6363 = global.member_34[0u];
            phi_36392_ = _e5075;
            if (_e6363 > 0.5f) {
                phi_36349_ = vec3<f32>(0f, 0f, 0f);
                phi_36283_ = 0f;
                phi_36282_ = 0i;
                loop {
                    let _e6367 = phi_36349_;
                    let _e6369 = phi_36283_;
                    let _e6371 = phi_36282_;
                    local_73 = _e6369;
                    local_74 = _e6367;
                    if (_e6371 < i32(_e6363)) {
                        if (_e6369 > 0.999f) {
                            break;
                        }
                        let _e6374 = (_e6371 * 8i);
                        let _e6377 = global_3.member[_e6374];
                        let _e6378 = bitcast<vec4<f32>>(_e6377);
                        let _e6382 = global_3.member[(_e6374 + 1i)];
                        let _e6383 = bitcast<vec4<f32>>(_e6382);
                        let _e6387 = global_3.member[(_e6374 + 2i)];
                        let _e6388 = bitcast<vec4<f32>>(_e6387);
                        let _e6389 = _e6378.xyz;
                        let _e6393 = _e6383.xyz;
                        let _e6397 = _e6388.xyz;
                        let _e6401 = vec3<f32>((dot(_e6389, _e956) + _e6378.w), (dot(_e6393, _e956) + _e6383.w), (dot(_e6397, _e956) + _e6388.w));
                        let _e6405 = global_3.member[(_e6374 + 3i)];
                        let _e6406 = bitcast<vec4<f32>>(_e6405);
                        switch bitcast<i32>(0u) {
                            default: {
                                let _e6411 = (_e6406.xyz - abs(_e6401));
                                let _e6416 = min(_e6411.x, min(_e6411.y, _e6411.z));
                                if (_e6416 <= 0f) {
                                    phi_36284_ = 0f;
                                    break;
                                }
                                if (_e6406.w <= 0f) {
                                    phi_36284_ = 1f;
                                    break;
                                }
                                let _e6420 = min((_e6416 / _e6406.w), 1f);
                                phi_36284_ = ((_e6420 * _e6420) * (3f - (2f * _e6420)));
                                break;
                            }
                        }
                        let _e6426 = phi_36284_;
                        if (_e6426 <= 0f) {
                            phi_37667_ = _e6367;
                            phi_37666_ = _e6369;
                            continue;
                        }
                        let _e6431 = global_3.member[(_e6374 + 4i)];
                        let _e6432 = bitcast<vec4<f32>>(_e6431);
                        let _e6436 = global_3.member[(_e6374 + 5i)];
                        let _e6437 = bitcast<vec4<f32>>(_e6436);
                        let _e6441 = vec3<f32>(dot(_e6389, _e4891), dot(_e6393, _e4891), dot(_e6397, _e4891));
                        if (_e6432.w > 0.5f) {
                            let _e6444 = _e6432.xyz;
                            let _e6446 = -(_e6444);
                            let _e6447 = clamp(_e6401, _e6446, _e6444);
                            let _e6451 = step(vec3<f32>(0.000001f, 0.000001f, 0.000001f), abs(_e6441));
                            let _e6455 = mix(vec3<f32>(1000000000000000000000000000000f, 1000000000000000000000000000000f, 1000000000000000000000000000000f), ((mix(_e6446, _e6444, step(vec3<f32>(0f, 0f, 0f), _e6441)) - _e6447) / mix(vec3<f32>(0.000001f, 0.000001f, 0.000001f), _e6441, _e6451)), _e6451);
                            let _e6464 = ((_e6447 + (_e6441 * max(min(_e6455.x, min(_e6455.y, _e6455.z)), 0f))) - _e6437.xyz);
                            if (dot(_e6464, _e6464) > 0.000000000001f) {
                                phi_36285_ = normalize(_e6464);
                            } else {
                                phi_36285_ = _e6441;
                            }
                            let _e6469 = phi_36285_;
                            phi_36286_ = _e6469;
                        } else {
                            phi_36286_ = _e6441;
                        }
                        let _e6471 = phi_36286_;
                        let _e6476 = global_3.member[(_e6374 + 6i)][0u];
                        let _e6477 = bitcast<i32>(_e6476);
                        let _e6488 = vec2<f32>(((atan2(_e6471.x, -(_e6471.z)) * 0.15915494f) + 0.5f), (acos(clamp(_e6471.y, -1f, 1f)) * 0.31830987f));
                        let _e6490 = ((_e6488 * vec2<f32>(256f, 128f)) - vec2<f32>(0.5f, 0.5f));
                        let _e6491 = floor(_e6490);
                        let _e6492 = (_e6490 - _e6491);
                        let _e6494 = i32(_e6491.x);
                        let _e6496 = i32(_e6491.y);
                        phi_36287_ = _e6494;
                        if (_e6494 < 0i) {
                            phi_36287_ = (_e6494 + 256i);
                        }
                        let _e6500 = phi_36287_;
                        phi_36288_ = _e6500;
                        if (_e6500 >= 256i) {
                            phi_36288_ = (_e6500 - 256i);
                        }
                        let _e6504 = phi_36288_;
                        let _e6505 = (_e6504 + 1i);
                        let _e6507 = select(_e6505, 0i, (_e6505 == 256i));
                        let _e6512 = (_e6477 + (max(_e6496, 0i) * 256i));
                        let _e6513 = (_e6512 + _e6504);
                        let _e6518 = global_3.member[(_e6513 >> bitcast<u32>(1i))];
                        if ((_e6513 & 1i) == 0i) {
                            phi_36294_ = _e6518.xy;
                        } else {
                            phi_36294_ = _e6518.zw;
                        }
                        let _e6524 = phi_36294_;
                        let _e6526 = unpack2x16float(_e6524.x);
                        let _e6533 = (_e6512 + _e6507);
                        let _e6538 = global_3.member[(_e6533 >> bitcast<u32>(1i))];
                        if ((_e6533 & 1i) == 0i) {
                            phi_36296_ = _e6538.xy;
                        } else {
                            phi_36296_ = _e6538.zw;
                        }
                        let _e6544 = phi_36296_;
                        let _e6546 = unpack2x16float(_e6544.x);
                        let _e6554 = (_e6477 + (min((_e6496 + 1i), 127i) * 256i));
                        let _e6555 = (_e6554 + _e6504);
                        let _e6560 = global_3.member[(_e6555 >> bitcast<u32>(1i))];
                        if ((_e6555 & 1i) == 0i) {
                            phi_36299_ = _e6560.xy;
                        } else {
                            phi_36299_ = _e6560.zw;
                        }
                        let _e6566 = phi_36299_;
                        let _e6568 = unpack2x16float(_e6566.x);
                        let _e6575 = (_e6554 + _e6507);
                        let _e6580 = global_3.member[(_e6575 >> bitcast<u32>(1i))];
                        if ((_e6575 & 1i) == 0i) {
                            phi_36300_ = _e6580.xy;
                        } else {
                            phi_36300_ = _e6580.zw;
                        }
                        let _e6586 = phi_36300_;
                        let _e6588 = unpack2x16float(_e6586.x);
                        let _e6596 = vec3(_e6492.x);
                        let _e6602 = (_e6477 + 32768i);
                        let _e6604 = ((_e6488 * vec2<f32>(128f, 64f)) - vec2<f32>(0.5f, 0.5f));
                        let _e6605 = floor(_e6604);
                        let _e6606 = (_e6604 - _e6605);
                        let _e6608 = i32(_e6605.x);
                        let _e6610 = i32(_e6605.y);
                        phi_36301_ = _e6608;
                        if (_e6608 < 0i) {
                            phi_36301_ = (_e6608 + 128i);
                        }
                        let _e6614 = phi_36301_;
                        phi_36302_ = _e6614;
                        if (_e6614 >= 128i) {
                            phi_36302_ = (_e6614 - 128i);
                        }
                        let _e6618 = phi_36302_;
                        let _e6619 = (_e6618 + 1i);
                        let _e6621 = select(_e6619, 0i, (_e6619 == 128i));
                        let _e6626 = (_e6602 + (max(_e6610, 0i) * 128i));
                        let _e6627 = (_e6626 + _e6618);
                        let _e6632 = global_3.member[(_e6627 >> bitcast<u32>(1i))];
                        if ((_e6627 & 1i) == 0i) {
                            phi_36308_ = _e6632.xy;
                        } else {
                            phi_36308_ = _e6632.zw;
                        }
                        let _e6638 = phi_36308_;
                        let _e6640 = unpack2x16float(_e6638.x);
                        let _e6647 = (_e6626 + _e6621);
                        let _e6652 = global_3.member[(_e6647 >> bitcast<u32>(1i))];
                        if ((_e6647 & 1i) == 0i) {
                            phi_36310_ = _e6652.xy;
                        } else {
                            phi_36310_ = _e6652.zw;
                        }
                        let _e6658 = phi_36310_;
                        let _e6660 = unpack2x16float(_e6658.x);
                        let _e6668 = (_e6602 + (min((_e6610 + 1i), 63i) * 128i));
                        let _e6669 = (_e6668 + _e6618);
                        let _e6674 = global_3.member[(_e6669 >> bitcast<u32>(1i))];
                        if ((_e6669 & 1i) == 0i) {
                            phi_36313_ = _e6674.xy;
                        } else {
                            phi_36313_ = _e6674.zw;
                        }
                        let _e6680 = phi_36313_;
                        let _e6682 = unpack2x16float(_e6680.x);
                        let _e6689 = (_e6668 + _e6621);
                        let _e6694 = global_3.member[(_e6689 >> bitcast<u32>(1i))];
                        if ((_e6689 & 1i) == 0i) {
                            phi_36314_ = _e6694.xy;
                        } else {
                            phi_36314_ = _e6694.zw;
                        }
                        let _e6700 = phi_36314_;
                        let _e6702 = unpack2x16float(_e6700.x);
                        let _e6710 = vec3(_e6606.x);
                        let _e6720 = (_e6426 * (1f - _e6369));
                        phi_37667_ = (_e6367 + ((mix(mix(mix(vec3<f32>(_e6526.x, _e6526.y, unpack2x16float(_e6524.y).x), vec3<f32>(_e6546.x, _e6546.y, unpack2x16float(_e6544.y).x), _e6596), mix(vec3<f32>(_e6568.x, _e6568.y, unpack2x16float(_e6566.y).x), vec3<f32>(_e6588.x, _e6588.y, unpack2x16float(_e6586.y).x), _e6596), vec3(_e6492.y)), mix(mix(vec3<f32>(_e6640.x, _e6640.y, unpack2x16float(_e6638.y).x), vec3<f32>(_e6660.x, _e6660.y, unpack2x16float(_e6658.y).x), _e6710), mix(vec3<f32>(_e6682.x, _e6682.y, unpack2x16float(_e6680.y).x), vec3<f32>(_e6702.x, _e6702.y, unpack2x16float(_e6700.y).x), _e6710), vec3(_e6606.y)), vec3<f32>(0.35f, 0.35f, 0.35f)) * _e6437.w) * _e6720));
                        phi_37666_ = (_e6369 + _e6720);
                        continue;
                    } else {
                        break;
                    }
                    continuing {
                        let _e6725 = phi_37667_;
                        let _e6727 = phi_37666_;
                        phi_36349_ = _e6725;
                        phi_36283_ = _e6727;
                        phi_36282_ = (_e6371 + 1i);
                    }
                }
                let _e6730 = local_73;
                let _e6734 = local_74;
                phi_36392_ = (_e6734 + (_e5075 * (1f - _e6730)));
            }
            let _e6737 = phi_36392_;
            let _e6740 = ((((vec3(((max(((dot(_e3521, _e952) * 0.65f) + (_e4872 * 0.35f)), 0f) * _e4851) + (max(((_e4872 + 0.3f) * 0.7692308f), 0f) * _e4849))) * _e1388) * _e1379) * _e4871) + ((_e6360 * _e1410) * _e4870));
            let _e6742 = max(dot(_e963, _e958), 0.0001f);
            let _e6743 = clamp(_e4872, 0f, 1f);
            let _e6751 = clamp(dot(_e963, _e960), 0f, 1f);
            let _e6754 = (((_e6751 * _e6751) * -0.999976f) + 1f);
            let _e6760 = sqrt((((_e6742 * _e6742) * 0.999976f) + 0.00002401f));
            let _e6776 = (((((((vec3<f32>(0.025f, 0.025f, 0.025f) + (vec3<f32>(0.975f, 0.975f, 0.975f) * pow((1f - clamp(dot(_e958, _e960), 0f, 1f)), 5f))) * (0.000012005f / (((3.1415927f * _e6754) * _e6754) * max(((_e6743 * _e6760) + (_e6742 * sqrt((((_e6743 * _e6743) * 0.999976f) + 0.00002401f)))), 0.00001f)))) * 3.1415927f) * _e6743) * _e1388) * _e1379) * _e4871);
            let _e6779 = global.member_13[3u];
            phi_36464_ = _e6740;
            phi_36427_ = _e6776;
            if (_e6779 > 0.5f) {
                let _e6782 = global.member_11;
                let _e6787 = global.member_11[3u];
                let _e6789 = global_16;
                let _e6792 = global.member_12;
                let _e6797 = global.member_13;
                let _e6800 = clamp(floor((_e6789.xy * _e6792.xy)), vec2<f32>(0f, 0f), (_e6797.xy - vec2<f32>(1f, 1f)));
                let _e6805 = global.member_12[2u];
                let _e6809 = global.member_12[3u];
                let _e6814 = global.member_13[2u];
                let _e6819 = global.member_13[1u];
                let _e6825 = global.member_13[0u];
                let _e6829 = u32(((((clamp(floor(((log2(max((dot(_e6782.xyz, _e956) + _e6787), 0.000001f)) * _e6805) + _e6809)), 0f, (_e6814 - 1f)) * _e6819) + _e6800.y) * _e6825) + _e6800.x));
                let _e6836 = global_17.member[(_e6829 >> bitcast<u32>(2i))][(_e6829 & 3u)];
                let _e6837 = (_e6836 & 65535u);
                phi_36465_ = _e6740;
                phi_36428_ = _e6776;
                phi_36424_ = _e6837;
                loop {
                    let _e6841 = phi_36465_;
                    let _e6843 = phi_36428_;
                    let _e6845 = phi_36424_;
                    local_109 = _e6841;
                    local_110 = _e6843;
                    if (_e6845 < (_e6837 + (_e6836 >> bitcast<u32>(16i)))) {
                        continue;
                    } else {
                        break;
                    }
                    continuing {
                        let _e6848 = (_e6845 / 3u);
                        let _e6855 = global_18.member[(_e6848 >> bitcast<u32>(2i))][(_e6848 & 3u)];
                        let _e6861 = ((_e6855 >> bitcast<u32>(((_e6845 - (_e6848 * 3u)) * 10u))) & 1023u);
                        let _e6864 = global_12.member[_e6861];
                        let _e6866 = (_e6864.xyz - _e956);
                        let _e6867 = dot(_e6866, _e6866);
                        let _e6869 = (_e6867 * _e6864.w);
                        let _e6872 = clamp((1f - (_e6869 * _e6869)), 0f, 1f);
                        let _e6875 = (_e6866 * inverseSqrt(max(_e6867, 0.00000001f)));
                        let _e6878 = global_14.member[_e6861];
                        let _e6881 = global_15.member[_e6861];
                        let _e6889 = clamp(((dot(-(_e6875), _e6881.xyz) * _e6878.w) + _e6881.w), 0f, 1f);
                        let _e6897 = ((_e6878.xyz * ((((_e6872 * _e6872) * _e6889) * _e6889) / max(_e6867, 0.0001f))) * _e4871);
                        let _e6898 = dot(_e963, _e6875);
                        let _e6914 = normalize((_e6875 + _e958));
                        let _e6915 = clamp(_e6898, 0f, 1f);
                        let _e6923 = clamp(dot(_e963, _e6914), 0f, 1f);
                        let _e6926 = (((_e6923 * _e6923) * -0.999976f) + 1f);
                        phi_36465_ = (_e6841 + (vec3(((max(((dot(_e3521, _e6875) * 0.65f) + (_e6898 * 0.35f)), 0f) * _e4851) + (max(((_e6898 + 0.3f) * 0.7692308f), 0f) * _e4849))) * _e6897));
                        phi_36428_ = (_e6843 + (((((vec3<f32>(0.025f, 0.025f, 0.025f) + (vec3<f32>(0.975f, 0.975f, 0.975f) * pow((1f - clamp(dot(_e958, _e6914), 0f, 1f)), 5f))) * (0.000012005f / (((3.1415927f * _e6926) * _e6926) * max(((_e6915 * _e6760) + (_e6742 * sqrt((((_e6915 * _e6915) * 0.999976f) + 0.00002401f)))), 0.00001f)))) * 3.1415927f) * _e6915) * _e6897));
                        phi_36424_ = (_e6845 + bitcast<u32>(1i));
                    }
                }
                let _e13436 = local_109;
                phi_36464_ = _e13436;
                let _e13439 = local_110;
                phi_36427_ = _e13439;
            }
            let _e6947 = phi_36464_;
            let _e6949 = phi_36427_;
            if _e4895 {
                let _e6954 = textureSample(global_6, global_7, (((vec2<f32>(_e6742, 0.07f) * 31f) + vec2<f32>(0.5f, 0.5f)) * vec2<f32>(0.03125f, 0.03125f)));
                phi_36425_ = _e6954.xy;
            } else {
                phi_36425_ = ((vec2<f32>(-1.04f, 1.04f) * ((min(0.8649f, exp2((-9.28f * _e6742))) * 0.93f) + 0.040575f)) + vec2<f32>(0.99995995f, -0.038459998f));
            }
            let _e6964 = phi_36425_;
            let _e6969 = ((vec3<f32>(0.025f, 0.025f, 0.025f) * _e6964.x) + vec3(_e6964.y));
            let _e6973 = (_e6949 + ((_e6969 * _e6737) * mix(1f, _e4870, 0.7f)));
            phi_37181_ = _e6973;
            phi_36598_ = ((((_e4853 * _e1381) * _e6947) * (vec3<f32>(1f, 1f, 1f) - _e6969)) + _e6973);
        } else {
            switch bitcast<i32>(0u) {
                default: {
                    let _e6981 = global_19.member_3[1u];
                    let _e6984 = global_19.member_3[0u];
                    if ((_e6984 <= 0f) || (_e6981 <= 0f)) {
                        phi_35579_ = _e948;
                        break;
                    }
                    let _e6988 = global_11;
                    let _e6989 = dpdx(_e6988);
                    let _e6990 = dpdy(_e6988);
                    let _e6994 = (max(length(_e6989), length(_e6990)) * _e6981);
                    let _e6996 = (1f - smoothstep(0.25f, 0.7f, _e6994));
                    if (_e6996 <= 0f) {
                        phi_35579_ = _e948;
                        break;
                    }
                    let _e6998 = (_e6988 * _e6981);
                    let _e6999 = floor(_e6998);
                    let _e7000 = (_e6998 - _e6999);
                    let _e7004 = ((_e7000 * _e7000) * (vec3<f32>(3f, 3f, 3f) - (_e7000 * 2f)));
                    let _e7009 = bitcast<vec3<u32>>(vec3<i32>(_e6999));
                    let _e7018 = ((((_e7009.x * 1597334677u) ^ (_e7009.y * 3812015801u)) ^ (_e7009.z * 2798796415u)) * 1597334677u);
                    let _e7023 = f32(((_e7018 ^ (_e7018 >> bitcast<u32>(16i))) & 65535u));
                    let _e7024 = (_e7023 * 0.000015259022f);
                    let _e7027 = bitcast<vec3<u32>>(vec3<i32>((_e6999 + vec3<f32>(1f, 0f, 0f))));
                    let _e7036 = ((((_e7027.x * 1597334677u) ^ (_e7027.y * 3812015801u)) ^ (_e7027.z * 2798796415u)) * 1597334677u);
                    let _e7042 = (f32(((_e7036 ^ (_e7036 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f);
                    let _e7045 = bitcast<vec3<u32>>(vec3<i32>((_e6999 + vec3<f32>(0f, 1f, 0f))));
                    let _e7054 = ((((_e7045.x * 1597334677u) ^ (_e7045.y * 3812015801u)) ^ (_e7045.z * 2798796415u)) * 1597334677u);
                    let _e7060 = (f32(((_e7054 ^ (_e7054 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f);
                    let _e7063 = bitcast<vec3<u32>>(vec3<i32>((_e6999 + vec3<f32>(1f, 1f, 0f))));
                    let _e7072 = ((((_e7063.x * 1597334677u) ^ (_e7063.y * 3812015801u)) ^ (_e7063.z * 2798796415u)) * 1597334677u);
                    let _e7078 = (f32(((_e7072 ^ (_e7072 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f);
                    let _e7081 = bitcast<vec3<u32>>(vec3<i32>((_e6999 + vec3<f32>(0f, 0f, 1f))));
                    let _e7090 = ((((_e7081.x * 1597334677u) ^ (_e7081.y * 3812015801u)) ^ (_e7081.z * 2798796415u)) * 1597334677u);
                    let _e7096 = (f32(((_e7090 ^ (_e7090 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f);
                    let _e7099 = bitcast<vec3<u32>>(vec3<i32>((_e6999 + vec3<f32>(1f, 0f, 1f))));
                    let _e7108 = ((((_e7099.x * 1597334677u) ^ (_e7099.y * 3812015801u)) ^ (_e7099.z * 2798796415u)) * 1597334677u);
                    let _e7114 = (f32(((_e7108 ^ (_e7108 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f);
                    let _e7117 = bitcast<vec3<u32>>(vec3<i32>((_e6999 + vec3<f32>(0f, 1f, 1f))));
                    let _e7126 = ((((_e7117.x * 1597334677u) ^ (_e7117.y * 3812015801u)) ^ (_e7117.z * 2798796415u)) * 1597334677u);
                    let _e7132 = (f32(((_e7126 ^ (_e7126 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f);
                    let _e7135 = bitcast<vec3<u32>>(vec3<i32>((_e6999 + vec3<f32>(1f, 1f, 1f))));
                    let _e7144 = ((((_e7135.x * 1597334677u) ^ (_e7135.y * 3812015801u)) ^ (_e7135.z * 2798796415u)) * 1597334677u);
                    let _e7151 = (_e7042 - _e7024);
                    let _e7152 = (_e7060 - _e7024);
                    let _e7153 = (_e7096 - _e7024);
                    let _e7154 = (_e7024 - _e7042);
                    let _e7156 = ((_e7154 - _e7060) + _e7078);
                    let _e7159 = (((_e7024 - _e7060) - _e7096) + _e7132);
                    let _e7161 = ((_e7154 - _e7096) + _e7114);
                    let _e7169 = ((((((((_e7023 * -0.000015259022f) + _e7042) + _e7060) - _e7078) + _e7096) - _e7114) - _e7132) + (f32(((_e7144 ^ (_e7144 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f));
                    let _e7179 = (_e7156 * _e7004.x);
                    let _e7182 = (_e7159 * _e7004.y);
                    let _e7185 = (_e7161 * _e7004.z);
                    let _e7189 = ((_e7169 * _e7004.x) * _e7004.y);
                    let _e7191 = (((((((_e7024 + (_e7151 * _e7004.x)) + (_e7152 * _e7004.y)) + (_e7153 * _e7004.z)) + (_e7179 * _e7004.y)) + (_e7182 * _e7004.z)) + (_e7185 * _e7004.x)) + (_e7189 * _e7004.z));
                    let _e7209 = (((_e7000 * 6f) * (vec3<f32>(1f, 1f, 1f) - _e7000)) * vec3<f32>((((_e7151 + (_e7156 * _e7004.y)) + _e7185) + ((_e7169 * _e7004.y) * _e7004.z)), (((_e7152 + (_e7159 * _e7004.z)) + _e7179) + ((_e7169 * _e7004.z) * _e7004.x)), (((_e7153 + (_e7161 * _e7004.x)) + _e7182) + _e7189)));
                    let _e7214 = (1f - _e7191);
                    let _e7221 = ((_e6998 * vec3<f32>(2.9f, 2.3f, 2.6f)) + vec3<f32>(13.1f, 7.7f, 3.3f));
                    let _e7222 = floor(_e7221);
                    let _e7223 = (_e7221 - _e7222);
                    let _e7227 = ((_e7223 * _e7223) * (vec3<f32>(3f, 3f, 3f) - (_e7223 * 2f)));
                    let _e7232 = bitcast<vec3<u32>>(vec3<i32>(_e7222));
                    let _e7241 = ((((_e7232.x * 1597334677u) ^ (_e7232.y * 3812015801u)) ^ (_e7232.z * 2798796415u)) * 1597334677u);
                    let _e7246 = f32(((_e7241 ^ (_e7241 >> bitcast<u32>(16i))) & 65535u));
                    let _e7247 = (_e7246 * 0.000015259022f);
                    let _e7250 = bitcast<vec3<u32>>(vec3<i32>((_e7222 + vec3<f32>(1f, 0f, 0f))));
                    let _e7259 = ((((_e7250.x * 1597334677u) ^ (_e7250.y * 3812015801u)) ^ (_e7250.z * 2798796415u)) * 1597334677u);
                    let _e7265 = (f32(((_e7259 ^ (_e7259 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f);
                    let _e7268 = bitcast<vec3<u32>>(vec3<i32>((_e7222 + vec3<f32>(0f, 1f, 0f))));
                    let _e7277 = ((((_e7268.x * 1597334677u) ^ (_e7268.y * 3812015801u)) ^ (_e7268.z * 2798796415u)) * 1597334677u);
                    let _e7283 = (f32(((_e7277 ^ (_e7277 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f);
                    let _e7286 = bitcast<vec3<u32>>(vec3<i32>((_e7222 + vec3<f32>(1f, 1f, 0f))));
                    let _e7295 = ((((_e7286.x * 1597334677u) ^ (_e7286.y * 3812015801u)) ^ (_e7286.z * 2798796415u)) * 1597334677u);
                    let _e7301 = (f32(((_e7295 ^ (_e7295 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f);
                    let _e7304 = bitcast<vec3<u32>>(vec3<i32>((_e7222 + vec3<f32>(0f, 0f, 1f))));
                    let _e7313 = ((((_e7304.x * 1597334677u) ^ (_e7304.y * 3812015801u)) ^ (_e7304.z * 2798796415u)) * 1597334677u);
                    let _e7319 = (f32(((_e7313 ^ (_e7313 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f);
                    let _e7322 = bitcast<vec3<u32>>(vec3<i32>((_e7222 + vec3<f32>(1f, 0f, 1f))));
                    let _e7331 = ((((_e7322.x * 1597334677u) ^ (_e7322.y * 3812015801u)) ^ (_e7322.z * 2798796415u)) * 1597334677u);
                    let _e7337 = (f32(((_e7331 ^ (_e7331 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f);
                    let _e7340 = bitcast<vec3<u32>>(vec3<i32>((_e7222 + vec3<f32>(0f, 1f, 1f))));
                    let _e7349 = ((((_e7340.x * 1597334677u) ^ (_e7340.y * 3812015801u)) ^ (_e7340.z * 2798796415u)) * 1597334677u);
                    let _e7355 = (f32(((_e7349 ^ (_e7349 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f);
                    let _e7358 = bitcast<vec3<u32>>(vec3<i32>((_e7222 + vec3<f32>(1f, 1f, 1f))));
                    let _e7367 = ((((_e7358.x * 1597334677u) ^ (_e7358.y * 3812015801u)) ^ (_e7358.z * 2798796415u)) * 1597334677u);
                    let _e7377 = (_e7247 - _e7265);
                    let _e7379 = ((_e7377 - _e7283) + _e7301);
                    let _e7382 = (((_e7247 - _e7283) - _e7319) + _e7355);
                    let _e7384 = ((_e7377 - _e7319) + _e7337);
                    let _e7392 = ((((((((_e7246 * -0.000015259022f) + _e7265) + _e7283) - _e7301) + _e7319) - _e7337) - _e7355) + (f32(((_e7367 ^ (_e7367 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f));
                    let _e7418 = (((_e7223 * 6f) * (vec3<f32>(1f, 1f, 1f) - _e7223)) * vec3<f32>(((((_e7265 - _e7247) + (_e7379 * _e7227.y)) + (_e7384 * _e7227.z)) + ((_e7392 * _e7227.y) * _e7227.z)), ((((_e7283 - _e7247) + (_e7382 * _e7227.z)) + (_e7379 * _e7227.x)) + ((_e7392 * _e7227.z) * _e7227.x)), ((((_e7319 - _e7247) + (_e7384 * _e7227.x)) + (_e7382 * _e7227.y)) + ((_e7392 * _e7227.x) * _e7227.y))));
                    let _e7432 = (((vec4<f32>(_e7191, _e7209.x, _e7209.y, _e7209.z).yzw * (((4f * _e7214) * _e7214) * _e7214)) + ((vec3<f32>(1.015f, 0.805f, 0.91f) * vec4<f32>(f32(), _e7418.x, _e7418.y, _e7418.z).yzw) * (1f - smoothstep(0.2f, 0.5f, (_e6994 * 2.9f))))) * ((0.25f * _e6984) * _e6996));
                    let _e7435 = dpdx(_e956);
                    let _e7436 = dpdy(_e956);
                    let _e7437 = cross(_e7436, _e948);
                    let _e7439 = dot(_e7435, _e7437);
                    let _e7440 = abs(_e7439);
                    if (_e7440 < 0.00000000000000000001f) {
                        phi_35579_ = _e948;
                        break;
                    }
                    phi_35579_ = normalize(((_e948 * _e7440) - (((_e7437 * dot(_e7432, _e6989)) + (cross(_e948, _e7435) * dot(_e7432, _e6990))) * sign(_e7439))));
                    break;
                }
            }
            let _e7451 = phi_35579_;
            let _e7453 = max(dot(_e7451, _e958), 0.0001f);
            let _e7457 = mix(vec3<f32>(0.028f, 0.028f, 0.028f), _e1381, vec3(_e3420));
            let _e7460 = global_19.member[3u];
            let _e7462 = clamp((vec3<f32>(0.48f, 0.41f, 0.28f) * _e7460), vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e7463 = (_e7460 > 0f);
            phi_19742_ = _e7463;
            if _e7463 {
                let _e7466 = global_19.member_1[0u];
                phi_19742_ = (_e7466 > 0f);
            }
            let _e7469 = phi_19742_;
            let _e7472 = global_19.member_1[3u];
            let _e7474 = (_e7469 && (_e7472 <= 0.5f));
            if _e7469 {
                let _e7477 = global_19.member_1[1u];
                phi_35580_ = _e7477;
            } else {
                phi_35580_ = 0f;
            }
            let _e7479 = phi_35580_;
            let _e7480 = (_e7479 > 0f);
            phi_35581_ = 0f;
            if (_e7474 || _e7480) {
                let _e7482 = fwidth(_e963);
                let _e7484 = fwidth(_e956);
                phi_35581_ = clamp((length(_e7482) / max(length(_e7484), 0.0000001f)), 0f, 400f);
            }
            let _e7490 = phi_35581_;
            let _e7491 = max(_e7490, 2f);
            if _e7474 {
                let _e7493 = global_19.member;
                let _e7497 = global_19.member_1[0u];
                phi_35582_ = 0i;
                loop {
                    let _e7502 = phi_35582_;
                    if (_e7502 < 2i) {
                        continue;
                    } else {
                        break;
                    }
                    continuing {
                        let _e7506 = (((_e7493.xyz * (_e7497 * 0.5f)) * _e7490) * select(1.72f, 0.52f, (_e7502 == 0i)));
                        let _e7507 = (_e7506 * 1.3556262f);
                        local_3[_e7502] = cos(_e7507);
                        local_2[_e7502] = sin(_e7507);
                        let _e7512 = (_e7506 * 2.85697f);
                        local_1[_e7502] = cos(_e7512);
                        local[_e7502] = sin(_e7512);
                        phi_35582_ = (_e7502 + 1i);
                    }
                }
            }
            if _e7474 {
                phi_35588_ = normalize(mix(_e7451, _e963, vec3(_e7462.x)));
            } else {
                phi_35588_ = _e7451;
            }
            let _e7523 = phi_35588_;
            if _e7474 {
                phi_35590_ = normalize(mix(_e7451, _e963, vec3((_e7462.y * 0.6f))));
            } else {
                phi_35590_ = _e7451;
            }
            let _e7530 = phi_35590_;
            if _e7474 {
                phi_35592_ = normalize(mix(_e7451, _e963, vec3((_e7462.z * 0.4f))));
            } else {
                phi_35592_ = _e7451;
            }
            let _e7537 = phi_35592_;
            let _e7539 = dot(_e7530, _e952);
            let _e7541 = vec3<f32>(dot(_e7523, _e952), _e7539, dot(_e7537, _e952));
            if _e7474 {
                let _e7542 = clamp(_e7541, vec3<f32>(-1f, -1f, -1f), vec3<f32>(1f, 1f, 1f));
                let _e7546 = sqrt(max((vec3<f32>(1f, 1f, 1f) - (_e7542 * _e7542)), vec3<f32>(0f, 0f, 0f)));
                phi_35594_ = vec3<f32>(0f, 0f, 0f);
                phi_35593_ = 0i;
                loop {
                    let _e7548 = phi_35594_;
                    let _e7550 = phi_35593_;
                    local_75 = _e7548;
                    if (_e7550 < 2i) {
                        continue;
                    } else {
                        break;
                    }
                    continuing {
                        let _e7555 = local_3[_e7550];
                        let _e7558 = local_2[_e7550];
                        let _e7562 = local_3[_e7550];
                        let _e7564 = local_2[_e7550];
                        let _e7572 = local_1[_e7550];
                        let _e7575 = local[_e7550];
                        let _e7579 = local_1[_e7550];
                        let _e7581 = local[_e7550];
                        phi_35594_ = (_e7548 + ((((max(_e7542, vec3<f32>(0f, 0f, 0f)) * 0.5333333f) + ((max(((_e7542 * _e7555) - (_e7546 * _e7558)), vec3<f32>(0f, 0f, 0f)) + max(((_e7542 * _e7562) + (_e7546 * _e7564)), vec3<f32>(0f, 0f, 0f))) * 0.2220759f)) + ((max(((_e7542 * _e7572) - (_e7546 * _e7575)), vec3<f32>(0f, 0f, 0f)) + max(((_e7542 * _e7579) + (_e7546 * _e7581)), vec3<f32>(0f, 0f, 0f))) * 0.0112574f)) * select(0.57f, 0.43f, (_e7550 == 0i))));
                        phi_35593_ = (_e7550 + 1i);
                    }
                }
                let _e7595 = local_75;
                phi_35595_ = mix(max(_e7541, vec3<f32>(0f, 0f, 0f)), _e7595, _e7462);
            } else {
                phi_35595_ = vec3(max(_e7539, 0f));
            }
            let _e7600 = phi_35595_;
            let _e7602 = ((_e7600 * _e1388) * _e1379);
            switch bitcast<i32>(0u) {
                default: {
                    let _e7605 = clamp(dot(_e7451, _e952), 0f, 1f);
                    if (_e7605 <= 0f) {
                        phi_35602_ = vec3<f32>(0f, 0f, 0f);
                        break;
                    }
                    let _e7608 = clamp(dot(_e7451, _e960), 0f, 1f);
                    let _e7618 = global_19.member_2[0u];
                    let _e7620 = clamp((_e3422 * _e7618), 0.045f, 1f);
                    let _e7621 = (_e7620 * _e7620);
                    let _e7622 = (_e7621 * _e7621);
                    let _e7623 = (_e7608 * _e7608);
                    let _e7626 = ((_e7623 * (_e7622 - 1f)) + 1f);
                    let _e7630 = (_e7453 * _e7453);
                    let _e7631 = (1f - _e7622);
                    let _e7636 = (_e7605 * _e7605);
                    let _e7644 = ((_e7622 / ((3.1415927f * _e7626) * _e7626)) * (0.5f / max(((_e7605 * sqrt(((_e7630 * _e7631) + _e7622))) + (_e7453 * sqrt(((_e7636 * _e7631) + _e7622)))), 0.00001f)));
                    let _e7647 = global_19.member_2[3u];
                    phi_35601_ = _e7644;
                    if (_e7647 > 0.5f) {
                        let _e7651 = global_19.member_2[1u];
                        let _e7653 = clamp((_e3422 * _e7651), 0.045f, 1f);
                        let _e7654 = (_e7653 * _e7653);
                        let _e7655 = (_e7654 * _e7654);
                        let _e7658 = ((_e7623 * (_e7655 - 1f)) + 1f);
                        let _e7662 = (1f - _e7655);
                        let _e7677 = global_19.member_2[2u];
                        phi_35601_ = mix(_e7644, ((_e7655 / ((3.1415927f * _e7658) * _e7658)) * (0.5f / max(((_e7605 * sqrt(((_e7630 * _e7662) + _e7655))) + (_e7453 * sqrt(((_e7636 * _e7662) + _e7655)))), 0.00001f))), _e7677);
                    }
                    let _e7680 = phi_35601_;
                    phi_35602_ = ((_e7457 + ((vec3<f32>(1f, 1f, 1f) - _e7457) * pow((1f - clamp(dot(_e958, _e960), 0f, 1f)), 5f))) * ((_e7680 * 3.1415927f) * _e7605));
                    break;
                }
            }
            let _e7685 = phi_35602_;
            let _e7687 = ((_e7685 * _e1388) * _e1379);
            phi_19871_ = _e7480;
            if _e7480 {
                phi_19871_ = (dot(_e963, _e952) < 0.35f);
            }
            let _e7691 = phi_19871_;
            phi_19877_ = _e7691;
            if _e7691 {
                phi_19877_ = (_e1387 > 0f);
            }
            let _e7694 = phi_19877_;
            phi_35869_ = _e7602;
            if _e7694 {
                if _e966 {
                    switch bitcast<i32>(0u) {
                        default: {
                            let _e7698 = global.member_21[0u];
                            let _e7699 = i32(_e7698);
                            if ((_e969 < 0.5f) || (_e7699 == 0i)) {
                                let _e7706 = global_19.member_1[1u];
                                let _e7709 = ((1200f / _e7491) / (0.6f + (6f * _e7706)));
                                let _e7711 = (-(_e7709) * _e7709);
                                phi_35661_ = ((((((vec3<f32>(0.233f, 0.455f, 0.649f) * exp((_e7711 * 156.25f))) + (vec3<f32>(0.1f, 0.336f, 0.344f) * exp((_e7711 * 20.661158f)))) + (vec3<f32>(0.118f, 0.198f, 0f) * exp((_e7711 * 5.3475933f)))) + (vec3<f32>(0.113f, 0.007f, 0.007f) * exp((_e7711 * 1.7636685f)))) + (vec3<f32>(0.358f, 0.004f, 0f) * exp((_e7711 * 0.5025126f)))) + (vec3<f32>(0.078f, 0f, 0f) * exp((_e7711 * 0.13495277f))));
                                break;
                            }
                            let _e7736 = global.member_20;
                            let _e7741 = global.member_20[3u];
                            let _e7742 = (dot(_e7736.xyz, _e956) + _e7741);
                            phi_35607_ = 0i;
                            loop {
                                let _e7744 = phi_35607_;
                                local_76 = _e7744;
                                local_77 = _e7744;
                                local_78 = _e7744;
                                local_79 = _e7744;
                                local_80 = _e7744;
                                local_81 = _e7744;
                                local_84 = _e7744;
                                local_85 = _e7744;
                                local_86 = _e7744;
                                let _e7746 = (_e7744 < (_e7699 - 1i));
                                phi_21564_ = _e7746;
                                if _e7746 {
                                    let _e7749 = global.member_16[_e7744];
                                    phi_21564_ = (_e7742 > _e7749);
                                }
                                let _e7752 = phi_21564_;
                                if _e7752 {
                                    continue;
                                } else {
                                    break;
                                }
                                continuing {
                                    phi_35607_ = (_e7744 + 1i);
                                }
                            }
                            let _e7756 = local_76;
                            let _e7758 = global.member_16[_e7756];
                            if (_e7742 > _e7758) {
                                let _e7763 = global_19.member_1[1u];
                                let _e7766 = ((1200f / _e7491) / (0.6f + (6f * _e7763)));
                                let _e7768 = (-(_e7766) * _e7766);
                                phi_35661_ = ((((((vec3<f32>(0.233f, 0.455f, 0.649f) * exp((_e7768 * 156.25f))) + (vec3<f32>(0.1f, 0.336f, 0.344f) * exp((_e7768 * 20.661158f)))) + (vec3<f32>(0.118f, 0.198f, 0f) * exp((_e7768 * 5.3475933f)))) + (vec3<f32>(0.113f, 0.007f, 0.007f) * exp((_e7768 * 1.7636685f)))) + (vec3<f32>(0.358f, 0.004f, 0f) * exp((_e7768 * 0.5025126f)))) + (vec3<f32>(0.078f, 0f, 0f) * exp((_e7768 * 0.13495277f))));
                                break;
                            }
                            let _e7794 = local_77;
                            let _e7796 = global.member_18[_e7794];
                            let _e7800 = (_e956 - (_e963 * max((_e7796 * 2f), 0.004f)));
                            let _e7802 = (_e7800 + (_e952 * 0.02f));
                            switch bitcast<i32>(0u) {
                                default: {
                                    let _e7806 = local_78;
                                    let _e7808 = global.member_14[_e7806];
                                    let _e7813 = (_e7808 * vec4<f32>(_e7802.x, _e7802.y, _e7802.z, 1f));
                                    let _e7815 = (_e7813.x < 0f);
                                    phi_21751_ = _e7815;
                                    local_83 = _e7808;
                                    if !(_e7815) {
                                        phi_21751_ = (_e7813.x > 1f);
                                    }
                                    let _e7819 = phi_21751_;
                                    phi_21758_ = _e7819;
                                    if !(_e7819) {
                                        phi_21758_ = (_e7813.y < 0f);
                                    }
                                    let _e7824 = phi_21758_;
                                    phi_21765_ = _e7824;
                                    if !(_e7824) {
                                        phi_21765_ = (_e7813.y > 1f);
                                    }
                                    let _e7829 = phi_21765_;
                                    if _e7829 {
                                        phi_35620_ = 1f;
                                        break;
                                    }
                                    let _e7831 = local_79;
                                    let _e7835 = local_80;
                                    let _e7841 = global.member_23;
                                    let _e7842 = _e7841.xy;
                                    let _e7843 = (vec2<f32>(f32((_e7831 & 1i)), f32((_e7835 >> bitcast<u32>(1i)))) * _e7842);
                                    let _e7848 = local_81;
                                    let _e7850 = global.member_19[_e7848];
                                    let _e7851 = (min(_e7813.z, 1f) - _e7850);
                                    let _e7854 = global.member_22;
                                    let _e7855 = _e7854.xy;
                                    let _e7856 = (_e7855 * 0.5f);
                                    let _e7858 = (_e7843 + (_e7813.xy * _e7842));
                                    let _e7859 = (_e7843 + _e7856);
                                    let _e7861 = ((_e7843 + _e7842) - _e7856);
                                    let _e7866 = vec4<f32>(_e7859.x, _e7859.y, _e7861.x, _e7861.y);
                                    switch bitcast<i32>(0u) {
                                        default: {
                                            let _e7870 = global.member_22[2u];
                                            let _e7871 = i32(_e7870);
                                            if (_e7871 <= 0i) {
                                                let _e7875 = clamp(_e7858, _e7866.xy, _e7866.zw);
                                                let _e7880 = textureSampleCompare(global_2, global_1, vec3<f32>(_e7875.x, _e7875.y, _e7851).xy, _e7851);
                                                phi_35619_ = _e7880;
                                                break;
                                            }
                                            let _e7882 = ((_e7858 / _e7855) + vec2<f32>(0.5f, 0.5f));
                                            let _e7883 = floor(_e7882);
                                            let _e7884 = (_e7882 - _e7883);
                                            let _e7886 = (_e7871 == 1i);
                                            if _e7886 {
                                                let _e7887 = (_e7884 * 2f);
                                                local_32[0i] = (vec2<f32>(3f, 3f) - _e7887);
                                                local_32[1i] = (vec2<f32>(1f, 1f) + _e7887);
                                                let _e7893 = local_32[0i];
                                                local_33[0i] = (((vec2<f32>(2f, 2f) - _e7884) / _e7893) - vec2<f32>(1f, 1f));
                                                let _e7897 = local_32[1i];
                                                local_33[1i] = ((_e7884 / _e7897) + vec2<f32>(1f, 1f));
                                            } else {
                                                let _e7901 = (_e7884 * 3f);
                                                local_32[0i] = (vec2<f32>(4f, 4f) - _e7901);
                                                local_32[1i] = vec2<f32>(7f, 7f);
                                                local_32[2i] = (vec2<f32>(1f, 1f) + _e7901);
                                                let _e7909 = local_32[0i];
                                                local_33[0i] = (((vec2<f32>(3f, 3f) - (_e7884 * 2f)) / _e7909) - vec2<f32>(2f, 2f));
                                                let _e7914 = local_32[1i];
                                                local_33[1i] = ((vec2<f32>(3f, 3f) + _e7884) / _e7914);
                                                let _e7917 = local_32[2i];
                                                local_33[2i] = ((_e7884 / _e7917) + vec2<f32>(2f, 2f));
                                            }
                                            let _e7922 = select(3i, 2i, _e7886);
                                            phi_35612_ = 0f;
                                            phi_35609_ = 0i;
                                            loop {
                                                let _e7924 = phi_35612_;
                                                let _e7926 = phi_35609_;
                                                local_82 = _e7924;
                                                if (_e7926 < _e7922) {
                                                    phi_35618_ = _e7924;
                                                    phi_35615_ = 0i;
                                                    loop {
                                                        let _e7929 = phi_35618_;
                                                        let _e7931 = phi_35615_;
                                                        local_111 = _e7929;
                                                        if (_e7931 < _e7922) {
                                                            continue;
                                                        } else {
                                                            break;
                                                        }
                                                        continuing {
                                                            let _e7935 = local_33[_e7931][0u];
                                                            let _e7938 = local_33[_e7926][1u];
                                                            let _e7944 = clamp((_e7855 * ((_e7883 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e7935, _e7938))), _e7866.xy, _e7866.zw);
                                                            let _e7947 = local_32[_e7931][0u];
                                                            let _e7950 = local_32[_e7926][1u];
                                                            let _e7956 = textureSampleCompare(global_2, global_1, vec3<f32>(_e7944.x, _e7944.y, _e7851).xy, _e7851);
                                                            phi_35618_ = (_e7929 + ((_e7947 * _e7950) * _e7956));
                                                            phi_35615_ = (_e7931 + 1i);
                                                        }
                                                    }
                                                    continue;
                                                } else {
                                                    break;
                                                }
                                                continuing {
                                                    let _e13470 = local_111;
                                                    phi_35612_ = _e13470;
                                                    phi_35609_ = (_e7926 + 1i);
                                                }
                                            }
                                            let _e7962 = local_82;
                                            phi_35619_ = (_e7962 * select(0.0069444445f, 0.0625f, _e7886));
                                            break;
                                        }
                                    }
                                    let _e7965 = phi_35619_;
                                    phi_35620_ = _e7965;
                                    break;
                                }
                            }
                            let _e7967 = phi_35620_;
                            if (_e7967 <= 0f) {
                                phi_35661_ = vec3<f32>(0f, 0f, 0f);
                                break;
                            }
                            phi_35623_ = vec3<f32>(1f, 1f, 1f);
                            phi_35622_ = vec3<f32>(0f, 0f, 0f);
                            phi_35621_ = 0i;
                            loop {
                                let _e7970 = phi_35623_;
                                let _e7972 = phi_35622_;
                                let _e7974 = phi_35621_;
                                local_115 = _e7972;
                                if (_e7974 < 4i) {
                                    local_34 = array<f32, 4>(0.002f, 0.005f, 0.01f, 0.02f);
                                    let _e7977 = local_34[_e7974];
                                    let _e7981 = global_19.member_1[1u];
                                    let _e7984 = ((_e7977 * 1000f) / (0.6f + (6f * _e7981)));
                                    let _e7986 = (-(_e7984) * _e7984);
                                    let _e8009 = ((((((vec3<f32>(0.233f, 0.455f, 0.649f) * exp((_e7986 * 156.25f))) + (vec3<f32>(0.1f, 0.336f, 0.344f) * exp((_e7986 * 20.661158f)))) + (vec3<f32>(0.118f, 0.198f, 0f) * exp((_e7986 * 5.3475933f)))) + (vec3<f32>(0.113f, 0.007f, 0.007f) * exp((_e7986 * 1.7636685f)))) + (vec3<f32>(0.358f, 0.004f, 0f) * exp((_e7986 * 0.5025126f)))) + (vec3<f32>(0.078f, 0f, 0f) * exp((_e7986 * 0.13495277f))));
                                    local_35 = array<f32, 4>(0.002f, 0.005f, 0.01f, 0.02f);
                                    let _e8012 = local_35[_e7974];
                                    let _e8014 = (_e7800 + (_e952 * _e8012));
                                    local_112 = _e8009;
                                    switch bitcast<i32>(0u) {
                                        default: {
                                            let _e8021 = local_83;
                                            let _e8022 = (_e8021 * vec4<f32>(_e8014.x, _e8014.y, _e8014.z, 1f));
                                            let _e8024 = (_e8022.x < 0f);
                                            phi_22083_ = _e8024;
                                            if !(_e8024) {
                                                phi_22083_ = (_e8022.x > 1f);
                                            }
                                            let _e8028 = phi_22083_;
                                            phi_22090_ = _e8028;
                                            if !(_e8028) {
                                                phi_22090_ = (_e8022.y < 0f);
                                            }
                                            let _e8033 = phi_22090_;
                                            phi_22097_ = _e8033;
                                            if !(_e8033) {
                                                phi_22097_ = (_e8022.y > 1f);
                                            }
                                            let _e8038 = phi_22097_;
                                            if _e8038 {
                                                phi_35644_ = 1f;
                                                break;
                                            }
                                            let _e8040 = local_84;
                                            let _e8044 = local_85;
                                            let _e8050 = global.member_23;
                                            let _e8051 = _e8050.xy;
                                            let _e8052 = (vec2<f32>(f32((_e8040 & 1i)), f32((_e8044 >> bitcast<u32>(1i)))) * _e8051);
                                            let _e8057 = local_86;
                                            let _e8059 = global.member_19[_e8057];
                                            let _e8060 = (min(_e8022.z, 1f) - _e8059);
                                            let _e8063 = global.member_22;
                                            let _e8064 = _e8063.xy;
                                            let _e8065 = (_e8064 * 0.5f);
                                            let _e8067 = (_e8052 + (_e8022.xy * _e8051));
                                            let _e8068 = (_e8052 + _e8065);
                                            let _e8070 = ((_e8052 + _e8051) - _e8065);
                                            let _e8075 = vec4<f32>(_e8068.x, _e8068.y, _e8070.x, _e8070.y);
                                            switch bitcast<i32>(0u) {
                                                default: {
                                                    let _e8079 = global.member_22[2u];
                                                    let _e8080 = i32(_e8079);
                                                    if (_e8080 <= 0i) {
                                                        let _e8084 = clamp(_e8067, _e8075.xy, _e8075.zw);
                                                        let _e8089 = textureSampleCompare(global_2, global_1, vec3<f32>(_e8084.x, _e8084.y, _e8060).xy, _e8060);
                                                        phi_35643_ = _e8089;
                                                        break;
                                                    }
                                                    let _e8091 = ((_e8067 / _e8064) + vec2<f32>(0.5f, 0.5f));
                                                    let _e8092 = floor(_e8091);
                                                    let _e8093 = (_e8091 - _e8092);
                                                    let _e8095 = (_e8080 == 1i);
                                                    if _e8095 {
                                                        let _e8096 = (_e8093 * 2f);
                                                        local_30[0i] = (vec2<f32>(3f, 3f) - _e8096);
                                                        local_30[1i] = (vec2<f32>(1f, 1f) + _e8096);
                                                        let _e8102 = local_30[0i];
                                                        local_31[0i] = (((vec2<f32>(2f, 2f) - _e8093) / _e8102) - vec2<f32>(1f, 1f));
                                                        let _e8106 = local_30[1i];
                                                        local_31[1i] = ((_e8093 / _e8106) + vec2<f32>(1f, 1f));
                                                    } else {
                                                        let _e8110 = (_e8093 * 3f);
                                                        local_30[0i] = (vec2<f32>(4f, 4f) - _e8110);
                                                        local_30[1i] = vec2<f32>(7f, 7f);
                                                        local_30[2i] = (vec2<f32>(1f, 1f) + _e8110);
                                                        let _e8118 = local_30[0i];
                                                        local_31[0i] = (((vec2<f32>(3f, 3f) - (_e8093 * 2f)) / _e8118) - vec2<f32>(2f, 2f));
                                                        let _e8123 = local_30[1i];
                                                        local_31[1i] = ((vec2<f32>(3f, 3f) + _e8093) / _e8123);
                                                        let _e8126 = local_30[2i];
                                                        local_31[2i] = ((_e8093 / _e8126) + vec2<f32>(2f, 2f));
                                                    }
                                                    let _e8131 = select(3i, 2i, _e8095);
                                                    phi_35636_ = 0f;
                                                    phi_35633_ = 0i;
                                                    loop {
                                                        let _e8133 = phi_35636_;
                                                        let _e8135 = phi_35633_;
                                                        local_87 = _e8133;
                                                        if (_e8135 < _e8131) {
                                                            phi_35642_ = _e8133;
                                                            phi_35639_ = 0i;
                                                            loop {
                                                                let _e8138 = phi_35642_;
                                                                let _e8140 = phi_35639_;
                                                                local_114 = _e8138;
                                                                if (_e8140 < _e8131) {
                                                                    continue;
                                                                } else {
                                                                    break;
                                                                }
                                                                continuing {
                                                                    let _e8144 = local_31[_e8140][0u];
                                                                    let _e8147 = local_31[_e8135][1u];
                                                                    let _e8153 = clamp((_e8064 * ((_e8092 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e8144, _e8147))), _e8075.xy, _e8075.zw);
                                                                    let _e8156 = local_30[_e8140][0u];
                                                                    let _e8159 = local_30[_e8135][1u];
                                                                    let _e8165 = textureSampleCompare(global_2, global_1, vec3<f32>(_e8153.x, _e8153.y, _e8060).xy, _e8060);
                                                                    phi_35642_ = (_e8138 + ((_e8156 * _e8159) * _e8165));
                                                                    phi_35639_ = (_e8140 + 1i);
                                                                }
                                                            }
                                                            continue;
                                                        } else {
                                                            break;
                                                        }
                                                        continuing {
                                                            let _e13493 = local_114;
                                                            phi_35636_ = _e13493;
                                                            phi_35633_ = (_e8135 + 1i);
                                                        }
                                                    }
                                                    let _e8171 = local_87;
                                                    phi_35643_ = (_e8171 * select(0.0069444445f, 0.0625f, _e8095));
                                                    break;
                                                }
                                            }
                                            let _e8174 = phi_35643_;
                                            phi_35644_ = _e8174;
                                            break;
                                        }
                                    }
                                    let _e8176 = phi_35644_;
                                    local_113 = (_e7972 + ((_e7970 - _e8009) * _e8176));
                                    continue;
                                } else {
                                    break;
                                }
                                continuing {
                                    let _e13479 = local_112;
                                    phi_35623_ = _e13479;
                                    let _e13482 = local_113;
                                    phi_35622_ = _e13482;
                                    phi_35621_ = (_e7974 + 1i);
                                }
                            }
                            let _e13502 = local_115;
                            phi_35661_ = _e13502;
                            break;
                        }
                    }
                    let _e8181 = phi_35661_;
                    phi_35662_ = _e8181;
                } else {
                    let _e8185 = global_19.member_1[1u];
                    let _e8188 = ((1200f / _e7491) / (0.6f + (6f * _e8185)));
                    let _e8190 = (-(_e8188) * _e8188);
                    phi_35662_ = ((((((vec3<f32>(0.233f, 0.455f, 0.649f) * exp((_e8190 * 156.25f))) + (vec3<f32>(0.1f, 0.336f, 0.344f) * exp((_e8190 * 20.661158f)))) + (vec3<f32>(0.118f, 0.198f, 0f) * exp((_e8190 * 5.3475933f)))) + (vec3<f32>(0.113f, 0.007f, 0.007f) * exp((_e8190 * 1.7636685f)))) + (vec3<f32>(0.358f, 0.004f, 0f) * exp((_e8190 * 0.5025126f)))) + (vec3<f32>(0.078f, 0f, 0f) * exp((_e8190 * 0.13495277f))));
                }
                let _e8215 = phi_35662_;
                phi_35869_ = (_e7602 + ((_e8215 * _e1388) * ((clamp((0.3f - dot(_e963, _e952)), 0f, 1f) * _e7479) * 2f)));
            }
            let _e8225 = phi_35869_;
            let _e8228 = global.member_13[3u];
            phi_35903_ = _e7687;
            phi_35868_ = _e8225;
            if (_e8228 > 0.5f) {
                let _e8231 = global.member_11;
                let _e8236 = global.member_11[3u];
                let _e8238 = global_16;
                let _e8241 = global.member_12;
                let _e8246 = global.member_13;
                let _e8249 = clamp(floor((_e8238.xy * _e8241.xy)), vec2<f32>(0f, 0f), (_e8246.xy - vec2<f32>(1f, 1f)));
                let _e8254 = global.member_12[2u];
                let _e8258 = global.member_12[3u];
                let _e8263 = global.member_13[2u];
                let _e8268 = global.member_13[1u];
                let _e8274 = global.member_13[0u];
                let _e8278 = u32(((((clamp(floor(((log2(max((dot(_e8231.xyz, _e956) + _e8236), 0.000001f)) * _e8254) + _e8258)), 0f, (_e8263 - 1f)) * _e8268) + _e8249.y) * _e8274) + _e8249.x));
                let _e8285 = global_17.member[(_e8278 >> bitcast<u32>(2i))][(_e8278 & 3u)];
                let _e8286 = (_e8285 & 65535u);
                phi_35928_ = _e7687;
                phi_35870_ = _e8225;
                phi_35688_ = _e8286;
                loop {
                    let _e8290 = phi_35928_;
                    let _e8292 = phi_35870_;
                    let _e8294 = phi_35688_;
                    local_127 = _e8290;
                    local_128 = _e8292;
                    if (_e8294 < (_e8286 + (_e8285 >> bitcast<u32>(16i)))) {
                        let _e8297 = (_e8294 / 3u);
                        let _e8304 = global_18.member[(_e8297 >> bitcast<u32>(2i))][(_e8297 & 3u)];
                        let _e8310 = ((_e8304 >> bitcast<u32>(((_e8294 - (_e8297 * 3u)) * 10u))) & 1023u);
                        let _e8313 = global_12.member[_e8310];
                        let _e8315 = (_e8313.xyz - _e956);
                        let _e8316 = dot(_e8315, _e8315);
                        let _e8318 = (_e8316 * _e8313.w);
                        let _e8321 = clamp((1f - (_e8318 * _e8318)), 0f, 1f);
                        let _e8324 = (_e8315 * inverseSqrt(max(_e8316, 0.00000001f)));
                        let _e8327 = global_14.member[_e8310];
                        let _e8330 = global_15.member[_e8310];
                        let _e8338 = clamp(((dot(-(_e8324), _e8330.xyz) * _e8327.w) + _e8330.w), 0f, 1f);
                        let _e8345 = (_e8327.xyz * ((((_e8321 * _e8321) * _e8338) * _e8338) / max(_e8316, 0.0001f)));
                        if _e966 {
                            switch bitcast<i32>(0u) {
                                default: {
                                    let _e8349 = global.member_21[2u];
                                    let _e8350 = u32(_e8349);
                                    if (_e8310 < _e8350) {
                                        let _e8354 = global.member_26[_e8310];
                                        let _e8357 = global.member_15[_e8310];
                                        let _e8366 = (_e8354.z * max((_e8357 * vec4<f32>(_e956.x, _e956.y, _e956.z, 1f)).w, 0f));
                                        let _e8369 = global.member_25[0u];
                                        let _e8375 = global.member_25[1u];
                                        let _e8378 = ((_e956 + (_e963 * (_e8366 * _e8369))) + (_e8324 * (_e8366 * _e8375)));
                                        let _e8383 = (_e8357 * vec4<f32>(_e8378.x, _e8378.y, _e8378.z, 1f));
                                        if (_e8383.w <= 0f) {
                                            phi_35981_ = 1f;
                                            break;
                                        }
                                        let _e8388 = (_e8383.xyz / vec3(_e8383.w));
                                        let _e8390 = (_e8388.x < 0f);
                                        phi_22637_ = _e8390;
                                        if !(_e8390) {
                                            phi_22637_ = (_e8388.x > 1f);
                                        }
                                        let _e8394 = phi_22637_;
                                        phi_22644_ = _e8394;
                                        if !(_e8394) {
                                            phi_22644_ = (_e8388.y < 0f);
                                        }
                                        let _e8399 = phi_22644_;
                                        phi_22651_ = _e8399;
                                        if !(_e8399) {
                                            phi_22651_ = (_e8388.y > 1f);
                                        }
                                        let _e8404 = phi_22651_;
                                        phi_22658_ = _e8404;
                                        if !(_e8404) {
                                            phi_22658_ = (_e8388.z > 1f);
                                        }
                                        let _e8409 = phi_22658_;
                                        if _e8409 {
                                            phi_35981_ = 1f;
                                            break;
                                        }
                                        let _e8412 = _e8354.xy;
                                        let _e8414 = global.member_23;
                                        let _e8415 = _e8414.zw;
                                        let _e8417 = global.member_22;
                                        let _e8418 = _e8417.xy;
                                        let _e8419 = (_e8418 * 0.5f);
                                        let _e8421 = (_e8412 + (_e8388.xy * _e8415));
                                        let _e8422 = (_e8412 + _e8419);
                                        let _e8424 = ((_e8412 + _e8415) - _e8419);
                                        let _e8429 = vec4<f32>(_e8422.x, _e8422.y, _e8424.x, _e8424.y);
                                        switch bitcast<i32>(0u) {
                                            default: {
                                                let _e8433 = global.member_22[2u];
                                                let _e8434 = i32(_e8433);
                                                if (_e8434 <= 0i) {
                                                    let _e8438 = clamp(_e8421, _e8429.xy, _e8429.zw);
                                                    let _e8443 = textureSampleCompare(global_2, global_1, vec3<f32>(_e8438.x, _e8438.y, _e8388.z).xy, _e8388.z);
                                                    phi_35980_ = _e8443;
                                                    break;
                                                }
                                                let _e8445 = ((_e8421 / _e8418) + vec2<f32>(0.5f, 0.5f));
                                                let _e8446 = floor(_e8445);
                                                let _e8447 = (_e8445 - _e8446);
                                                let _e8449 = (_e8434 == 1i);
                                                if _e8449 {
                                                    let _e8450 = (_e8447 * 2f);
                                                    local_26[0i] = (vec2<f32>(3f, 3f) - _e8450);
                                                    local_26[1i] = (vec2<f32>(1f, 1f) + _e8450);
                                                    let _e8456 = local_26[0i];
                                                    local_27[0i] = (((vec2<f32>(2f, 2f) - _e8447) / _e8456) - vec2<f32>(1f, 1f));
                                                    let _e8460 = local_26[1i];
                                                    local_27[1i] = ((_e8447 / _e8460) + vec2<f32>(1f, 1f));
                                                } else {
                                                    let _e8464 = (_e8447 * 3f);
                                                    local_26[0i] = (vec2<f32>(4f, 4f) - _e8464);
                                                    local_26[1i] = vec2<f32>(7f, 7f);
                                                    local_26[2i] = (vec2<f32>(1f, 1f) + _e8464);
                                                    let _e8472 = local_26[0i];
                                                    local_27[0i] = (((vec2<f32>(3f, 3f) - (_e8447 * 2f)) / _e8472) - vec2<f32>(2f, 2f));
                                                    let _e8477 = local_26[1i];
                                                    local_27[1i] = ((vec2<f32>(3f, 3f) + _e8447) / _e8477);
                                                    let _e8480 = local_26[2i];
                                                    local_27[2i] = ((_e8447 / _e8480) + vec2<f32>(2f, 2f));
                                                }
                                                let _e8485 = select(3i, 2i, _e8449);
                                                phi_35973_ = 0f;
                                                phi_35970_ = 0i;
                                                loop {
                                                    let _e8487 = phi_35973_;
                                                    let _e8489 = phi_35970_;
                                                    local_88 = _e8487;
                                                    if (_e8489 < _e8485) {
                                                        phi_35979_ = _e8487;
                                                        phi_35976_ = 0i;
                                                        loop {
                                                            let _e8492 = phi_35979_;
                                                            let _e8494 = phi_35976_;
                                                            local_118 = _e8492;
                                                            if (_e8494 < _e8485) {
                                                                continue;
                                                            } else {
                                                                break;
                                                            }
                                                            continuing {
                                                                let _e8498 = local_27[_e8494][0u];
                                                                let _e8501 = local_27[_e8489][1u];
                                                                let _e8507 = clamp((_e8418 * ((_e8446 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e8498, _e8501))), _e8429.xy, _e8429.zw);
                                                                let _e8510 = local_26[_e8494][0u];
                                                                let _e8513 = local_26[_e8489][1u];
                                                                let _e8519 = textureSampleCompare(global_2, global_1, vec3<f32>(_e8507.x, _e8507.y, _e8388.z).xy, _e8388.z);
                                                                phi_35979_ = (_e8492 + ((_e8510 * _e8513) * _e8519));
                                                                phi_35976_ = (_e8494 + 1i);
                                                            }
                                                        }
                                                        continue;
                                                    } else {
                                                        break;
                                                    }
                                                    continuing {
                                                        let _e13518 = local_118;
                                                        phi_35973_ = _e13518;
                                                        phi_35970_ = (_e8489 + 1i);
                                                    }
                                                }
                                                let _e8525 = local_88;
                                                phi_35980_ = (_e8525 * select(0.0069444445f, 0.0625f, _e8449));
                                                break;
                                            }
                                        }
                                        let _e8528 = phi_35980_;
                                        phi_35981_ = _e8528;
                                        break;
                                    }
                                    let _e8529 = (_e8310 - _e8350);
                                    let _e8532 = global.member_21[3u];
                                    if (_e8529 >= u32(_e8532)) {
                                        phi_35981_ = 1f;
                                        break;
                                    }
                                    let _e8537 = global.member_27[_e8529];
                                    let _e8540 = global.member_28[_e8529];
                                    let _e8542 = _e8537.xyz;
                                    let _e8545 = (_e8537.w * length((_e956 - _e8542)));
                                    let _e8548 = global.member_25[0u];
                                    let _e8554 = global.member_25[1u];
                                    let _e8558 = (((_e956 + (_e963 * (_e8545 * _e8548))) + (_e8324 * (_e8545 * _e8554))) - _e8542);
                                    let _e8559 = abs(_e8558);
                                    let _e8562 = (_e8559.x >= _e8559.y);
                                    phi_22728_ = _e8562;
                                    if _e8562 {
                                        phi_22728_ = (_e8559.x >= _e8559.z);
                                    }
                                    let _e8566 = phi_22728_;
                                    if _e8566 {
                                        phi_35957_ = select(1i, 0i, (_e8558.x > 0f));
                                        phi_35955_ = _e8559.x;
                                    } else {
                                        let _e8571 = (_e8559.y >= _e8559.z);
                                        if _e8571 {
                                            phi_35958_ = select(3i, 2i, (_e8558.y > 0f));
                                        } else {
                                            phi_35958_ = select(5i, 4i, (_e8558.z > 0f));
                                        }
                                        let _e8579 = phi_35958_;
                                        phi_35957_ = _e8579;
                                        phi_35955_ = select(_e8559.z, _e8559.y, _e8571);
                                    }
                                    let _e8582 = phi_35957_;
                                    let _e8584 = phi_35955_;
                                    if (_e8584 <= 0f) {
                                        phi_35981_ = 1f;
                                        break;
                                    }
                                    local_28 = array<vec3<f32>, 6>(vec3<f32>(0f, 0f, 1f), vec3<f32>(0f, 0f, -1f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(1f, 0f, 0f));
                                    let _e8587 = local_28[_e8582];
                                    local_29 = array<vec3<f32>, 6>(vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 0f, -1f), vec3<f32>(0f, 0f, 1f), vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 1f, 0f));
                                    let _e8590 = local_29[_e8582];
                                    let _e8595 = global.member_24[2u];
                                    let _e8598 = (vec2<f32>(dot(_e8558, _e8587), dot(_e8558, _e8590)) / vec2((_e8584 * _e8595)));
                                    let _e8602 = (_e8540.z + (_e8540.w / _e8584));
                                    if (_e8602 > 1f) {
                                        phi_35981_ = 1f;
                                        break;
                                    }
                                    let _e8617 = global.member_24;
                                    let _e8618 = _e8617.xy;
                                    let _e8620 = (_e8540.xy + (vec2<f32>(f32((_e8582 - (i32(floor((f32(_e8582) / f32(3i)))) * 3i))), f32((_e8582 / 3i))) * _e8618));
                                    let _e8629 = global.member_22;
                                    let _e8630 = _e8629.xy;
                                    let _e8631 = (_e8630 * 0.5f);
                                    let _e8633 = (_e8620 + (vec2<f32>((0.5f + (0.5f * _e8598.x)), (0.5f - (0.5f * _e8598.y))) * _e8618));
                                    let _e8634 = (_e8620 + _e8631);
                                    let _e8636 = ((_e8620 + _e8618) - _e8631);
                                    let _e8641 = vec4<f32>(_e8634.x, _e8634.y, _e8636.x, _e8636.y);
                                    switch bitcast<i32>(0u) {
                                        default: {
                                            let _e8645 = global.member_22[2u];
                                            let _e8646 = i32(_e8645);
                                            if (_e8646 <= 0i) {
                                                let _e8650 = clamp(_e8633, _e8641.xy, _e8641.zw);
                                                let _e8655 = textureSampleCompare(global_2, global_1, vec3<f32>(_e8650.x, _e8650.y, _e8602).xy, _e8602);
                                                phi_35969_ = _e8655;
                                                break;
                                            }
                                            let _e8657 = ((_e8633 / _e8630) + vec2<f32>(0.5f, 0.5f));
                                            let _e8658 = floor(_e8657);
                                            let _e8659 = (_e8657 - _e8658);
                                            let _e8661 = (_e8646 == 1i);
                                            if _e8661 {
                                                let _e8662 = (_e8659 * 2f);
                                                local_24[0i] = (vec2<f32>(3f, 3f) - _e8662);
                                                local_24[1i] = (vec2<f32>(1f, 1f) + _e8662);
                                                let _e8668 = local_24[0i];
                                                local_25[0i] = (((vec2<f32>(2f, 2f) - _e8659) / _e8668) - vec2<f32>(1f, 1f));
                                                let _e8672 = local_24[1i];
                                                local_25[1i] = ((_e8659 / _e8672) + vec2<f32>(1f, 1f));
                                            } else {
                                                let _e8676 = (_e8659 * 3f);
                                                local_24[0i] = (vec2<f32>(4f, 4f) - _e8676);
                                                local_24[1i] = vec2<f32>(7f, 7f);
                                                local_24[2i] = (vec2<f32>(1f, 1f) + _e8676);
                                                let _e8684 = local_24[0i];
                                                local_25[0i] = (((vec2<f32>(3f, 3f) - (_e8659 * 2f)) / _e8684) - vec2<f32>(2f, 2f));
                                                let _e8689 = local_24[1i];
                                                local_25[1i] = ((vec2<f32>(3f, 3f) + _e8659) / _e8689);
                                                let _e8692 = local_24[2i];
                                                local_25[2i] = ((_e8659 / _e8692) + vec2<f32>(2f, 2f));
                                            }
                                            let _e8697 = select(3i, 2i, _e8661);
                                            phi_35962_ = 0f;
                                            phi_35959_ = 0i;
                                            loop {
                                                let _e8699 = phi_35962_;
                                                let _e8701 = phi_35959_;
                                                local_89 = _e8699;
                                                if (_e8701 < _e8697) {
                                                    phi_35968_ = _e8699;
                                                    phi_35965_ = 0i;
                                                    loop {
                                                        let _e8704 = phi_35968_;
                                                        let _e8706 = phi_35965_;
                                                        local_119 = _e8704;
                                                        if (_e8706 < _e8697) {
                                                            continue;
                                                        } else {
                                                            break;
                                                        }
                                                        continuing {
                                                            let _e8710 = local_25[_e8706][0u];
                                                            let _e8713 = local_25[_e8701][1u];
                                                            let _e8719 = clamp((_e8630 * ((_e8658 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e8710, _e8713))), _e8641.xy, _e8641.zw);
                                                            let _e8722 = local_24[_e8706][0u];
                                                            let _e8725 = local_24[_e8701][1u];
                                                            let _e8731 = textureSampleCompare(global_2, global_1, vec3<f32>(_e8719.x, _e8719.y, _e8602).xy, _e8602);
                                                            phi_35968_ = (_e8704 + ((_e8722 * _e8725) * _e8731));
                                                            phi_35965_ = (_e8706 + 1i);
                                                        }
                                                    }
                                                    continue;
                                                } else {
                                                    break;
                                                }
                                                continuing {
                                                    let _e13530 = local_119;
                                                    phi_35962_ = _e13530;
                                                    phi_35959_ = (_e8701 + 1i);
                                                }
                                            }
                                            let _e8737 = local_89;
                                            phi_35969_ = (_e8737 * select(0.0069444445f, 0.0625f, _e8661));
                                            break;
                                        }
                                    }
                                    let _e8740 = phi_35969_;
                                    phi_35981_ = _e8740;
                                    break;
                                }
                            }
                            let _e8742 = phi_35981_;
                            phi_35982_ = _e8742;
                        } else {
                            phi_35982_ = 1f;
                        }
                        let _e8744 = phi_35982_;
                        let _e8746 = dot(_e7530, _e8324);
                        let _e8748 = vec3<f32>(dot(_e7523, _e8324), _e8746, dot(_e7537, _e8324));
                        if _e7474 {
                            let _e8749 = clamp(_e8748, vec3<f32>(-1f, -1f, -1f), vec3<f32>(1f, 1f, 1f));
                            let _e8753 = sqrt(max((vec3<f32>(1f, 1f, 1f) - (_e8749 * _e8749)), vec3<f32>(0f, 0f, 0f)));
                            phi_35984_ = vec3<f32>(0f, 0f, 0f);
                            phi_35983_ = 0i;
                            loop {
                                let _e8755 = phi_35984_;
                                let _e8757 = phi_35983_;
                                local_90 = _e8755;
                                if (_e8757 < 2i) {
                                    continue;
                                } else {
                                    break;
                                }
                                continuing {
                                    let _e8762 = local_3[_e8757];
                                    let _e8765 = local_2[_e8757];
                                    let _e8769 = local_3[_e8757];
                                    let _e8771 = local_2[_e8757];
                                    let _e8779 = local_1[_e8757];
                                    let _e8782 = local[_e8757];
                                    let _e8786 = local_1[_e8757];
                                    let _e8788 = local[_e8757];
                                    phi_35984_ = (_e8755 + ((((max(_e8749, vec3<f32>(0f, 0f, 0f)) * 0.5333333f) + ((max(((_e8749 * _e8762) - (_e8753 * _e8765)), vec3<f32>(0f, 0f, 0f)) + max(((_e8749 * _e8769) + (_e8753 * _e8771)), vec3<f32>(0f, 0f, 0f))) * 0.2220759f)) + ((max(((_e8749 * _e8779) - (_e8753 * _e8782)), vec3<f32>(0f, 0f, 0f)) + max(((_e8749 * _e8786) + (_e8753 * _e8788)), vec3<f32>(0f, 0f, 0f))) * 0.0112574f)) * select(0.57f, 0.43f, (_e8757 == 0i))));
                                    phi_35983_ = (_e8757 + 1i);
                                }
                            }
                            let _e8802 = local_90;
                            phi_35985_ = mix(max(_e8748, vec3<f32>(0f, 0f, 0f)), _e8802, _e7462);
                        } else {
                            phi_35985_ = vec3(max(_e8746, 0f));
                        }
                        let _e8807 = phi_35985_;
                        let _e8810 = (_e8292 + ((_e8807 * _e8345) * _e8744));
                        switch bitcast<i32>(0u) {
                            default: {
                                let _e8813 = normalize((_e8324 + _e958));
                                let _e8815 = clamp(dot(_e7451, _e8324), 0f, 1f);
                                if (_e8815 <= 0f) {
                                    phi_36025_ = vec3<f32>(0f, 0f, 0f);
                                    break;
                                }
                                let _e8818 = clamp(dot(_e7451, _e8813), 0f, 1f);
                                let _e8828 = global_19.member_2[0u];
                                let _e8830 = clamp((_e3422 * _e8828), 0.045f, 1f);
                                let _e8831 = (_e8830 * _e8830);
                                let _e8832 = (_e8831 * _e8831);
                                let _e8833 = (_e8818 * _e8818);
                                let _e8836 = ((_e8833 * (_e8832 - 1f)) + 1f);
                                let _e8840 = (_e7453 * _e7453);
                                let _e8841 = (1f - _e8832);
                                let _e8846 = (_e8815 * _e8815);
                                let _e8854 = ((_e8832 / ((3.1415927f * _e8836) * _e8836)) * (0.5f / max(((_e8815 * sqrt(((_e8840 * _e8841) + _e8832))) + (_e7453 * sqrt(((_e8846 * _e8841) + _e8832)))), 0.00001f)));
                                let _e8857 = global_19.member_2[3u];
                                phi_36024_ = _e8854;
                                if (_e8857 > 0.5f) {
                                    let _e8861 = global_19.member_2[1u];
                                    let _e8863 = clamp((_e3422 * _e8861), 0.045f, 1f);
                                    let _e8864 = (_e8863 * _e8863);
                                    let _e8865 = (_e8864 * _e8864);
                                    let _e8868 = ((_e8833 * (_e8865 - 1f)) + 1f);
                                    let _e8872 = (1f - _e8865);
                                    let _e8887 = global_19.member_2[2u];
                                    phi_36024_ = mix(_e8854, ((_e8865 / ((3.1415927f * _e8868) * _e8868)) * (0.5f / max(((_e8815 * sqrt(((_e8840 * _e8872) + _e8865))) + (_e7453 * sqrt(((_e8846 * _e8872) + _e8865)))), 0.00001f))), _e8887);
                                }
                                let _e8890 = phi_36024_;
                                phi_36025_ = ((_e7457 + ((vec3<f32>(1f, 1f, 1f) - _e7457) * pow((1f - clamp(dot(_e958, _e8813), 0f, 1f)), 5f))) * ((_e8890 * 3.1415927f) * _e8815));
                                break;
                            }
                        }
                        let _e8895 = phi_36025_;
                        local_116 = (_e8290 + ((_e8895 * _e8345) * _e8744));
                        phi_19990_ = _e7480;
                        if _e7480 {
                            phi_19990_ = (dot(_e963, _e8324) < 0.35f);
                        }
                        let _e8902 = phi_19990_;
                        phi_37611_ = _e8810;
                        if _e8902 {
                            if _e966 {
                                switch bitcast<i32>(0u) {
                                    default: {
                                        let _e8906 = global.member_21[2u];
                                        let _e8909 = global.member_21[3u];
                                        if (_e8310 >= u32((_e8906 + _e8909))) {
                                            let _e8916 = global_19.member_1[1u];
                                            let _e8919 = ((1200f / _e7491) / (0.6f + (6f * _e8916)));
                                            let _e8921 = (-(_e8919) * _e8919);
                                            phi_36136_ = ((((((vec3<f32>(0.233f, 0.455f, 0.649f) * exp((_e8921 * 156.25f))) + (vec3<f32>(0.1f, 0.336f, 0.344f) * exp((_e8921 * 20.661158f)))) + (vec3<f32>(0.118f, 0.198f, 0f) * exp((_e8921 * 5.3475933f)))) + (vec3<f32>(0.113f, 0.007f, 0.007f) * exp((_e8921 * 1.7636685f)))) + (vec3<f32>(0.358f, 0.004f, 0f) * exp((_e8921 * 0.5025126f)))) + (vec3<f32>(0.078f, 0f, 0f) * exp((_e8921 * 0.13495277f))));
                                            break;
                                        }
                                        let _e8946 = (_e956 - (_e963 * 0.004f));
                                        let _e8948 = (_e8946 + (_e8324 * 0.02f));
                                        switch bitcast<i32>(0u) {
                                            default: {
                                                let _e8950 = u32(_e8906);
                                                let _e8951 = (_e8310 < _e8950);
                                                local_93 = _e8951;
                                                local_95 = _e8950;
                                                if _e8951 {
                                                    let _e8954 = global.member_26[_e8310];
                                                    let _e8957 = global.member_15[_e8310];
                                                    let _e8966 = (_e8954.z * max((_e8957 * vec4<f32>(_e8948.x, _e8948.y, _e8948.z, 1f)).w, 0f));
                                                    let _e8969 = global.member_25[0u];
                                                    let _e8975 = global.member_25[1u];
                                                    let _e8978 = ((_e8948 + (_e963 * (_e8966 * _e8969))) + (_e8324 * (_e8966 * _e8975)));
                                                    let _e8983 = (_e8957 * vec4<f32>(_e8978.x, _e8978.y, _e8978.z, 1f));
                                                    if (_e8983.w <= 0f) {
                                                        phi_36073_ = 1f;
                                                        break;
                                                    }
                                                    let _e8988 = (_e8983.xyz / vec3(_e8983.w));
                                                    let _e8990 = (_e8988.x < 0f);
                                                    phi_23798_ = _e8990;
                                                    if !(_e8990) {
                                                        phi_23798_ = (_e8988.x > 1f);
                                                    }
                                                    let _e8994 = phi_23798_;
                                                    phi_23805_ = _e8994;
                                                    if !(_e8994) {
                                                        phi_23805_ = (_e8988.y < 0f);
                                                    }
                                                    let _e8999 = phi_23805_;
                                                    phi_23812_ = _e8999;
                                                    if !(_e8999) {
                                                        phi_23812_ = (_e8988.y > 1f);
                                                    }
                                                    let _e9004 = phi_23812_;
                                                    phi_23819_ = _e9004;
                                                    if !(_e9004) {
                                                        phi_23819_ = (_e8988.z > 1f);
                                                    }
                                                    let _e9009 = phi_23819_;
                                                    if _e9009 {
                                                        phi_36073_ = 1f;
                                                        break;
                                                    }
                                                    let _e9012 = _e8954.xy;
                                                    let _e9014 = global.member_23;
                                                    let _e9015 = _e9014.zw;
                                                    let _e9017 = global.member_22;
                                                    let _e9018 = _e9017.xy;
                                                    let _e9019 = (_e9018 * 0.5f);
                                                    let _e9021 = (_e9012 + (_e8988.xy * _e9015));
                                                    let _e9022 = (_e9012 + _e9019);
                                                    let _e9024 = ((_e9012 + _e9015) - _e9019);
                                                    let _e9029 = vec4<f32>(_e9022.x, _e9022.y, _e9024.x, _e9024.y);
                                                    switch bitcast<i32>(0u) {
                                                        default: {
                                                            let _e9033 = global.member_22[2u];
                                                            let _e9034 = i32(_e9033);
                                                            if (_e9034 <= 0i) {
                                                                let _e9038 = clamp(_e9021, _e9029.xy, _e9029.zw);
                                                                let _e9043 = textureSampleCompare(global_2, global_1, vec3<f32>(_e9038.x, _e9038.y, _e8988.z).xy, _e8988.z);
                                                                phi_36072_ = _e9043;
                                                                break;
                                                            }
                                                            let _e9045 = ((_e9021 / _e9018) + vec2<f32>(0.5f, 0.5f));
                                                            let _e9046 = floor(_e9045);
                                                            let _e9047 = (_e9045 - _e9046);
                                                            let _e9049 = (_e9034 == 1i);
                                                            if _e9049 {
                                                                let _e9050 = (_e9047 * 2f);
                                                                local_18[0i] = (vec2<f32>(3f, 3f) - _e9050);
                                                                local_18[1i] = (vec2<f32>(1f, 1f) + _e9050);
                                                                let _e9056 = local_18[0i];
                                                                local_19[0i] = (((vec2<f32>(2f, 2f) - _e9047) / _e9056) - vec2<f32>(1f, 1f));
                                                                let _e9060 = local_18[1i];
                                                                local_19[1i] = ((_e9047 / _e9060) + vec2<f32>(1f, 1f));
                                                            } else {
                                                                let _e9064 = (_e9047 * 3f);
                                                                local_18[0i] = (vec2<f32>(4f, 4f) - _e9064);
                                                                local_18[1i] = vec2<f32>(7f, 7f);
                                                                local_18[2i] = (vec2<f32>(1f, 1f) + _e9064);
                                                                let _e9072 = local_18[0i];
                                                                local_19[0i] = (((vec2<f32>(3f, 3f) - (_e9047 * 2f)) / _e9072) - vec2<f32>(2f, 2f));
                                                                let _e9077 = local_18[1i];
                                                                local_19[1i] = ((vec2<f32>(3f, 3f) + _e9047) / _e9077);
                                                                let _e9080 = local_18[2i];
                                                                local_19[2i] = ((_e9047 / _e9080) + vec2<f32>(2f, 2f));
                                                            }
                                                            let _e9085 = select(3i, 2i, _e9049);
                                                            phi_36065_ = 0f;
                                                            phi_36062_ = 0i;
                                                            loop {
                                                                let _e9087 = phi_36065_;
                                                                let _e9089 = phi_36062_;
                                                                local_91 = _e9087;
                                                                if (_e9089 < _e9085) {
                                                                    phi_36071_ = _e9087;
                                                                    phi_36068_ = 0i;
                                                                    loop {
                                                                        let _e9092 = phi_36071_;
                                                                        let _e9094 = phi_36068_;
                                                                        local_120 = _e9092;
                                                                        if (_e9094 < _e9085) {
                                                                            continue;
                                                                        } else {
                                                                            break;
                                                                        }
                                                                        continuing {
                                                                            let _e9098 = local_19[_e9094][0u];
                                                                            let _e9101 = local_19[_e9089][1u];
                                                                            let _e9107 = clamp((_e9018 * ((_e9046 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e9098, _e9101))), _e9029.xy, _e9029.zw);
                                                                            let _e9110 = local_18[_e9094][0u];
                                                                            let _e9113 = local_18[_e9089][1u];
                                                                            let _e9119 = textureSampleCompare(global_2, global_1, vec3<f32>(_e9107.x, _e9107.y, _e8988.z).xy, _e8988.z);
                                                                            phi_36071_ = (_e9092 + ((_e9110 * _e9113) * _e9119));
                                                                            phi_36068_ = (_e9094 + 1i);
                                                                        }
                                                                    }
                                                                    continue;
                                                                } else {
                                                                    break;
                                                                }
                                                                continuing {
                                                                    let _e13551 = local_120;
                                                                    phi_36065_ = _e13551;
                                                                    phi_36062_ = (_e9089 + 1i);
                                                                }
                                                            }
                                                            let _e9125 = local_91;
                                                            phi_36072_ = (_e9125 * select(0.0069444445f, 0.0625f, _e9049));
                                                            break;
                                                        }
                                                    }
                                                    let _e9128 = phi_36072_;
                                                    phi_36073_ = _e9128;
                                                    break;
                                                }
                                                let _e9129 = (_e8310 - _e8950);
                                                if (_e9129 >= u32(_e8909)) {
                                                    phi_36073_ = 1f;
                                                    break;
                                                }
                                                let _e9134 = global.member_27[_e9129];
                                                let _e9137 = global.member_28[_e9129];
                                                let _e9139 = _e9134.xyz;
                                                let _e9142 = (_e9134.w * length((_e8948 - _e9139)));
                                                let _e9145 = global.member_25[0u];
                                                let _e9151 = global.member_25[1u];
                                                let _e9155 = (((_e8948 + (_e963 * (_e9142 * _e9145))) + (_e8324 * (_e9142 * _e9151))) - _e9139);
                                                let _e9156 = abs(_e9155);
                                                let _e9159 = (_e9156.x >= _e9156.y);
                                                phi_23889_ = _e9159;
                                                if _e9159 {
                                                    phi_23889_ = (_e9156.x >= _e9156.z);
                                                }
                                                let _e9163 = phi_23889_;
                                                if _e9163 {
                                                    phi_36049_ = select(1i, 0i, (_e9155.x > 0f));
                                                    phi_36047_ = _e9156.x;
                                                } else {
                                                    let _e9168 = (_e9156.y >= _e9156.z);
                                                    if _e9168 {
                                                        phi_36050_ = select(3i, 2i, (_e9155.y > 0f));
                                                    } else {
                                                        phi_36050_ = select(5i, 4i, (_e9155.z > 0f));
                                                    }
                                                    let _e9176 = phi_36050_;
                                                    phi_36049_ = _e9176;
                                                    phi_36047_ = select(_e9156.z, _e9156.y, _e9168);
                                                }
                                                let _e9179 = phi_36049_;
                                                let _e9181 = phi_36047_;
                                                if (_e9181 <= 0f) {
                                                    phi_36073_ = 1f;
                                                    break;
                                                }
                                                local_20 = array<vec3<f32>, 6>(vec3<f32>(0f, 0f, 1f), vec3<f32>(0f, 0f, -1f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(1f, 0f, 0f));
                                                let _e9184 = local_20[_e9179];
                                                local_21 = array<vec3<f32>, 6>(vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 0f, -1f), vec3<f32>(0f, 0f, 1f), vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 1f, 0f));
                                                let _e9187 = local_21[_e9179];
                                                let _e9192 = global.member_24[2u];
                                                let _e9195 = (vec2<f32>(dot(_e9155, _e9184), dot(_e9155, _e9187)) / vec2((_e9181 * _e9192)));
                                                let _e9199 = (_e9137.z + (_e9137.w / _e9181));
                                                if (_e9199 > 1f) {
                                                    phi_36073_ = 1f;
                                                    break;
                                                }
                                                let _e9214 = global.member_24;
                                                let _e9215 = _e9214.xy;
                                                let _e9217 = (_e9137.xy + (vec2<f32>(f32((_e9179 - (i32(floor((f32(_e9179) / f32(3i)))) * 3i))), f32((_e9179 / 3i))) * _e9215));
                                                let _e9226 = global.member_22;
                                                let _e9227 = _e9226.xy;
                                                let _e9228 = (_e9227 * 0.5f);
                                                let _e9230 = (_e9217 + (vec2<f32>((0.5f + (0.5f * _e9195.x)), (0.5f - (0.5f * _e9195.y))) * _e9215));
                                                let _e9231 = (_e9217 + _e9228);
                                                let _e9233 = ((_e9217 + _e9215) - _e9228);
                                                let _e9238 = vec4<f32>(_e9231.x, _e9231.y, _e9233.x, _e9233.y);
                                                switch bitcast<i32>(0u) {
                                                    default: {
                                                        let _e9242 = global.member_22[2u];
                                                        let _e9243 = i32(_e9242);
                                                        if (_e9243 <= 0i) {
                                                            let _e9247 = clamp(_e9230, _e9238.xy, _e9238.zw);
                                                            let _e9252 = textureSampleCompare(global_2, global_1, vec3<f32>(_e9247.x, _e9247.y, _e9199).xy, _e9199);
                                                            phi_36061_ = _e9252;
                                                            break;
                                                        }
                                                        let _e9254 = ((_e9230 / _e9227) + vec2<f32>(0.5f, 0.5f));
                                                        let _e9255 = floor(_e9254);
                                                        let _e9256 = (_e9254 - _e9255);
                                                        let _e9258 = (_e9243 == 1i);
                                                        if _e9258 {
                                                            let _e9259 = (_e9256 * 2f);
                                                            local_16[0i] = (vec2<f32>(3f, 3f) - _e9259);
                                                            local_16[1i] = (vec2<f32>(1f, 1f) + _e9259);
                                                            let _e9265 = local_16[0i];
                                                            local_17[0i] = (((vec2<f32>(2f, 2f) - _e9256) / _e9265) - vec2<f32>(1f, 1f));
                                                            let _e9269 = local_16[1i];
                                                            local_17[1i] = ((_e9256 / _e9269) + vec2<f32>(1f, 1f));
                                                        } else {
                                                            let _e9273 = (_e9256 * 3f);
                                                            local_16[0i] = (vec2<f32>(4f, 4f) - _e9273);
                                                            local_16[1i] = vec2<f32>(7f, 7f);
                                                            local_16[2i] = (vec2<f32>(1f, 1f) + _e9273);
                                                            let _e9281 = local_16[0i];
                                                            local_17[0i] = (((vec2<f32>(3f, 3f) - (_e9256 * 2f)) / _e9281) - vec2<f32>(2f, 2f));
                                                            let _e9286 = local_16[1i];
                                                            local_17[1i] = ((vec2<f32>(3f, 3f) + _e9256) / _e9286);
                                                            let _e9289 = local_16[2i];
                                                            local_17[2i] = ((_e9256 / _e9289) + vec2<f32>(2f, 2f));
                                                        }
                                                        let _e9294 = select(3i, 2i, _e9258);
                                                        phi_36054_ = 0f;
                                                        phi_36051_ = 0i;
                                                        loop {
                                                            let _e9296 = phi_36054_;
                                                            let _e9298 = phi_36051_;
                                                            local_92 = _e9296;
                                                            if (_e9298 < _e9294) {
                                                                phi_36060_ = _e9296;
                                                                phi_36057_ = 0i;
                                                                loop {
                                                                    let _e9301 = phi_36060_;
                                                                    let _e9303 = phi_36057_;
                                                                    local_121 = _e9301;
                                                                    if (_e9303 < _e9294) {
                                                                        continue;
                                                                    } else {
                                                                        break;
                                                                    }
                                                                    continuing {
                                                                        let _e9307 = local_17[_e9303][0u];
                                                                        let _e9310 = local_17[_e9298][1u];
                                                                        let _e9316 = clamp((_e9227 * ((_e9255 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e9307, _e9310))), _e9238.xy, _e9238.zw);
                                                                        let _e9319 = local_16[_e9303][0u];
                                                                        let _e9322 = local_16[_e9298][1u];
                                                                        let _e9328 = textureSampleCompare(global_2, global_1, vec3<f32>(_e9316.x, _e9316.y, _e9199).xy, _e9199);
                                                                        phi_36060_ = (_e9301 + ((_e9319 * _e9322) * _e9328));
                                                                        phi_36057_ = (_e9303 + 1i);
                                                                    }
                                                                }
                                                                continue;
                                                            } else {
                                                                break;
                                                            }
                                                            continuing {
                                                                let _e13563 = local_121;
                                                                phi_36054_ = _e13563;
                                                                phi_36051_ = (_e9298 + 1i);
                                                            }
                                                        }
                                                        let _e9334 = local_92;
                                                        phi_36061_ = (_e9334 * select(0.0069444445f, 0.0625f, _e9258));
                                                        break;
                                                    }
                                                }
                                                let _e9337 = phi_36061_;
                                                phi_36073_ = _e9337;
                                                break;
                                            }
                                        }
                                        let _e9339 = phi_36073_;
                                        if (_e9339 <= 0f) {
                                            phi_36136_ = vec3<f32>(0f, 0f, 0f);
                                            break;
                                        }
                                        phi_36076_ = vec3<f32>(1f, 1f, 1f);
                                        phi_36075_ = vec3<f32>(0f, 0f, 0f);
                                        phi_36074_ = 0i;
                                        loop {
                                            let _e9342 = phi_36076_;
                                            let _e9344 = phi_36075_;
                                            let _e9346 = phi_36074_;
                                            local_126 = _e9344;
                                            if (_e9346 < 4i) {
                                                local_22 = array<f32, 4>(0.002f, 0.005f, 0.01f, 0.02f);
                                                let _e9349 = local_22[_e9346];
                                                let _e9353 = global_19.member_1[1u];
                                                let _e9356 = ((_e9349 * 1000f) / (0.6f + (6f * _e9353)));
                                                let _e9358 = (-(_e9356) * _e9356);
                                                let _e9381 = ((((((vec3<f32>(0.233f, 0.455f, 0.649f) * exp((_e9358 * 156.25f))) + (vec3<f32>(0.1f, 0.336f, 0.344f) * exp((_e9358 * 20.661158f)))) + (vec3<f32>(0.118f, 0.198f, 0f) * exp((_e9358 * 5.3475933f)))) + (vec3<f32>(0.113f, 0.007f, 0.007f) * exp((_e9358 * 1.7636685f)))) + (vec3<f32>(0.358f, 0.004f, 0f) * exp((_e9358 * 0.5025126f)))) + (vec3<f32>(0.078f, 0f, 0f) * exp((_e9358 * 0.13495277f))));
                                                local_23 = array<f32, 4>(0.002f, 0.005f, 0.01f, 0.02f);
                                                let _e9384 = local_23[_e9346];
                                                let _e9386 = (_e8946 + (_e8324 * _e9384));
                                                local_122 = _e9381;
                                                switch bitcast<i32>(0u) {
                                                    default: {
                                                        let _e9389 = local_93;
                                                        if _e9389 {
                                                            let _e9392 = global.member_26[_e8310];
                                                            let _e9395 = global.member_15[_e8310];
                                                            let _e9404 = (_e9392.z * max((_e9395 * vec4<f32>(_e9386.x, _e9386.y, _e9386.z, 1f)).w, 0f));
                                                            let _e9407 = global.member_25[0u];
                                                            let _e9413 = global.member_25[1u];
                                                            let _e9416 = ((_e9386 + (_e963 * (_e9404 * _e9407))) + (_e8324 * (_e9404 * _e9413)));
                                                            let _e9421 = (_e9395 * vec4<f32>(_e9416.x, _e9416.y, _e9416.z, 1f));
                                                            if (_e9421.w <= 0f) {
                                                                phi_36103_ = 1f;
                                                                break;
                                                            }
                                                            let _e9426 = (_e9421.xyz / vec3(_e9421.w));
                                                            let _e9428 = (_e9426.x < 0f);
                                                            phi_24555_ = _e9428;
                                                            if !(_e9428) {
                                                                phi_24555_ = (_e9426.x > 1f);
                                                            }
                                                            let _e9432 = phi_24555_;
                                                            phi_24562_ = _e9432;
                                                            if !(_e9432) {
                                                                phi_24562_ = (_e9426.y < 0f);
                                                            }
                                                            let _e9437 = phi_24562_;
                                                            phi_24569_ = _e9437;
                                                            if !(_e9437) {
                                                                phi_24569_ = (_e9426.y > 1f);
                                                            }
                                                            let _e9442 = phi_24569_;
                                                            phi_24576_ = _e9442;
                                                            if !(_e9442) {
                                                                phi_24576_ = (_e9426.z > 1f);
                                                            }
                                                            let _e9447 = phi_24576_;
                                                            if _e9447 {
                                                                phi_36103_ = 1f;
                                                                break;
                                                            }
                                                            let _e9450 = _e9392.xy;
                                                            let _e9452 = global.member_23;
                                                            let _e9453 = _e9452.zw;
                                                            let _e9455 = global.member_22;
                                                            let _e9456 = _e9455.xy;
                                                            let _e9457 = (_e9456 * 0.5f);
                                                            let _e9459 = (_e9450 + (_e9426.xy * _e9453));
                                                            let _e9460 = (_e9450 + _e9457);
                                                            let _e9462 = ((_e9450 + _e9453) - _e9457);
                                                            let _e9467 = vec4<f32>(_e9460.x, _e9460.y, _e9462.x, _e9462.y);
                                                            switch bitcast<i32>(0u) {
                                                                default: {
                                                                    let _e9471 = global.member_22[2u];
                                                                    let _e9472 = i32(_e9471);
                                                                    if (_e9472 <= 0i) {
                                                                        let _e9476 = clamp(_e9459, _e9467.xy, _e9467.zw);
                                                                        let _e9481 = textureSampleCompare(global_2, global_1, vec3<f32>(_e9476.x, _e9476.y, _e9426.z).xy, _e9426.z);
                                                                        phi_36102_ = _e9481;
                                                                        break;
                                                                    }
                                                                    let _e9483 = ((_e9459 / _e9456) + vec2<f32>(0.5f, 0.5f));
                                                                    let _e9484 = floor(_e9483);
                                                                    let _e9485 = (_e9483 - _e9484);
                                                                    let _e9487 = (_e9472 == 1i);
                                                                    if _e9487 {
                                                                        let _e9488 = (_e9485 * 2f);
                                                                        local_12[0i] = (vec2<f32>(3f, 3f) - _e9488);
                                                                        local_12[1i] = (vec2<f32>(1f, 1f) + _e9488);
                                                                        let _e9494 = local_12[0i];
                                                                        local_13[0i] = (((vec2<f32>(2f, 2f) - _e9485) / _e9494) - vec2<f32>(1f, 1f));
                                                                        let _e9498 = local_12[1i];
                                                                        local_13[1i] = ((_e9485 / _e9498) + vec2<f32>(1f, 1f));
                                                                    } else {
                                                                        let _e9502 = (_e9485 * 3f);
                                                                        local_12[0i] = (vec2<f32>(4f, 4f) - _e9502);
                                                                        local_12[1i] = vec2<f32>(7f, 7f);
                                                                        local_12[2i] = (vec2<f32>(1f, 1f) + _e9502);
                                                                        let _e9510 = local_12[0i];
                                                                        local_13[0i] = (((vec2<f32>(3f, 3f) - (_e9485 * 2f)) / _e9510) - vec2<f32>(2f, 2f));
                                                                        let _e9515 = local_12[1i];
                                                                        local_13[1i] = ((vec2<f32>(3f, 3f) + _e9485) / _e9515);
                                                                        let _e9518 = local_12[2i];
                                                                        local_13[2i] = ((_e9485 / _e9518) + vec2<f32>(2f, 2f));
                                                                    }
                                                                    let _e9523 = select(3i, 2i, _e9487);
                                                                    phi_36095_ = 0f;
                                                                    phi_36092_ = 0i;
                                                                    loop {
                                                                        let _e9525 = phi_36095_;
                                                                        let _e9527 = phi_36092_;
                                                                        local_94 = _e9525;
                                                                        if (_e9527 < _e9523) {
                                                                            phi_36101_ = _e9525;
                                                                            phi_36098_ = 0i;
                                                                            loop {
                                                                                let _e9530 = phi_36101_;
                                                                                let _e9532 = phi_36098_;
                                                                                local_124 = _e9530;
                                                                                if (_e9532 < _e9523) {
                                                                                    continue;
                                                                                } else {
                                                                                    break;
                                                                                }
                                                                                continuing {
                                                                                    let _e9536 = local_13[_e9532][0u];
                                                                                    let _e9539 = local_13[_e9527][1u];
                                                                                    let _e9545 = clamp((_e9456 * ((_e9484 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e9536, _e9539))), _e9467.xy, _e9467.zw);
                                                                                    let _e9548 = local_12[_e9532][0u];
                                                                                    let _e9551 = local_12[_e9527][1u];
                                                                                    let _e9557 = textureSampleCompare(global_2, global_1, vec3<f32>(_e9545.x, _e9545.y, _e9426.z).xy, _e9426.z);
                                                                                    phi_36101_ = (_e9530 + ((_e9548 * _e9551) * _e9557));
                                                                                    phi_36098_ = (_e9532 + 1i);
                                                                                }
                                                                            }
                                                                            continue;
                                                                        } else {
                                                                            break;
                                                                        }
                                                                        continuing {
                                                                            let _e13584 = local_124;
                                                                            phi_36095_ = _e13584;
                                                                            phi_36092_ = (_e9527 + 1i);
                                                                        }
                                                                    }
                                                                    let _e9563 = local_94;
                                                                    phi_36102_ = (_e9563 * select(0.0069444445f, 0.0625f, _e9487));
                                                                    break;
                                                                }
                                                            }
                                                            let _e9566 = phi_36102_;
                                                            phi_36103_ = _e9566;
                                                            break;
                                                        }
                                                        let _e9568 = local_95;
                                                        let _e9569 = (_e8310 - _e9568);
                                                        if (_e9569 >= u32(_e8909)) {
                                                            phi_36103_ = 1f;
                                                            break;
                                                        }
                                                        let _e9574 = global.member_27[_e9569];
                                                        let _e9577 = global.member_28[_e9569];
                                                        let _e9579 = _e9574.xyz;
                                                        let _e9582 = (_e9574.w * length((_e9386 - _e9579)));
                                                        let _e9585 = global.member_25[0u];
                                                        let _e9591 = global.member_25[1u];
                                                        let _e9595 = (((_e9386 + (_e963 * (_e9582 * _e9585))) + (_e8324 * (_e9582 * _e9591))) - _e9579);
                                                        let _e9596 = abs(_e9595);
                                                        let _e9599 = (_e9596.x >= _e9596.y);
                                                        phi_24646_ = _e9599;
                                                        if _e9599 {
                                                            phi_24646_ = (_e9596.x >= _e9596.z);
                                                        }
                                                        let _e9603 = phi_24646_;
                                                        if _e9603 {
                                                            phi_36079_ = select(1i, 0i, (_e9595.x > 0f));
                                                            phi_36077_ = _e9596.x;
                                                        } else {
                                                            let _e9608 = (_e9596.y >= _e9596.z);
                                                            if _e9608 {
                                                                phi_36080_ = select(3i, 2i, (_e9595.y > 0f));
                                                            } else {
                                                                phi_36080_ = select(5i, 4i, (_e9595.z > 0f));
                                                            }
                                                            let _e9616 = phi_36080_;
                                                            phi_36079_ = _e9616;
                                                            phi_36077_ = select(_e9596.z, _e9596.y, _e9608);
                                                        }
                                                        let _e9619 = phi_36079_;
                                                        let _e9621 = phi_36077_;
                                                        if (_e9621 <= 0f) {
                                                            phi_36103_ = 1f;
                                                            break;
                                                        }
                                                        local_14 = array<vec3<f32>, 6>(vec3<f32>(0f, 0f, 1f), vec3<f32>(0f, 0f, -1f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(1f, 0f, 0f));
                                                        let _e9624 = local_14[_e9619];
                                                        local_15 = array<vec3<f32>, 6>(vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 0f, -1f), vec3<f32>(0f, 0f, 1f), vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 1f, 0f));
                                                        let _e9627 = local_15[_e9619];
                                                        let _e9632 = global.member_24[2u];
                                                        let _e9635 = (vec2<f32>(dot(_e9595, _e9624), dot(_e9595, _e9627)) / vec2((_e9621 * _e9632)));
                                                        let _e9639 = (_e9577.z + (_e9577.w / _e9621));
                                                        if (_e9639 > 1f) {
                                                            phi_36103_ = 1f;
                                                            break;
                                                        }
                                                        let _e9654 = global.member_24;
                                                        let _e9655 = _e9654.xy;
                                                        let _e9657 = (_e9577.xy + (vec2<f32>(f32((_e9619 - (i32(floor((f32(_e9619) / f32(3i)))) * 3i))), f32((_e9619 / 3i))) * _e9655));
                                                        let _e9666 = global.member_22;
                                                        let _e9667 = _e9666.xy;
                                                        let _e9668 = (_e9667 * 0.5f);
                                                        let _e9670 = (_e9657 + (vec2<f32>((0.5f + (0.5f * _e9635.x)), (0.5f - (0.5f * _e9635.y))) * _e9655));
                                                        let _e9671 = (_e9657 + _e9668);
                                                        let _e9673 = ((_e9657 + _e9655) - _e9668);
                                                        let _e9678 = vec4<f32>(_e9671.x, _e9671.y, _e9673.x, _e9673.y);
                                                        switch bitcast<i32>(0u) {
                                                            default: {
                                                                let _e9682 = global.member_22[2u];
                                                                let _e9683 = i32(_e9682);
                                                                if (_e9683 <= 0i) {
                                                                    let _e9687 = clamp(_e9670, _e9678.xy, _e9678.zw);
                                                                    let _e9692 = textureSampleCompare(global_2, global_1, vec3<f32>(_e9687.x, _e9687.y, _e9639).xy, _e9639);
                                                                    phi_36091_ = _e9692;
                                                                    break;
                                                                }
                                                                let _e9694 = ((_e9670 / _e9667) + vec2<f32>(0.5f, 0.5f));
                                                                let _e9695 = floor(_e9694);
                                                                let _e9696 = (_e9694 - _e9695);
                                                                let _e9698 = (_e9683 == 1i);
                                                                if _e9698 {
                                                                    let _e9699 = (_e9696 * 2f);
                                                                    local_10[0i] = (vec2<f32>(3f, 3f) - _e9699);
                                                                    local_10[1i] = (vec2<f32>(1f, 1f) + _e9699);
                                                                    let _e9705 = local_10[0i];
                                                                    local_11[0i] = (((vec2<f32>(2f, 2f) - _e9696) / _e9705) - vec2<f32>(1f, 1f));
                                                                    let _e9709 = local_10[1i];
                                                                    local_11[1i] = ((_e9696 / _e9709) + vec2<f32>(1f, 1f));
                                                                } else {
                                                                    let _e9713 = (_e9696 * 3f);
                                                                    local_10[0i] = (vec2<f32>(4f, 4f) - _e9713);
                                                                    local_10[1i] = vec2<f32>(7f, 7f);
                                                                    local_10[2i] = (vec2<f32>(1f, 1f) + _e9713);
                                                                    let _e9721 = local_10[0i];
                                                                    local_11[0i] = (((vec2<f32>(3f, 3f) - (_e9696 * 2f)) / _e9721) - vec2<f32>(2f, 2f));
                                                                    let _e9726 = local_10[1i];
                                                                    local_11[1i] = ((vec2<f32>(3f, 3f) + _e9696) / _e9726);
                                                                    let _e9729 = local_10[2i];
                                                                    local_11[2i] = ((_e9696 / _e9729) + vec2<f32>(2f, 2f));
                                                                }
                                                                let _e9734 = select(3i, 2i, _e9698);
                                                                phi_36084_ = 0f;
                                                                phi_36081_ = 0i;
                                                                loop {
                                                                    let _e9736 = phi_36084_;
                                                                    let _e9738 = phi_36081_;
                                                                    local_96 = _e9736;
                                                                    if (_e9738 < _e9734) {
                                                                        phi_36090_ = _e9736;
                                                                        phi_36087_ = 0i;
                                                                        loop {
                                                                            let _e9741 = phi_36090_;
                                                                            let _e9743 = phi_36087_;
                                                                            local_125 = _e9741;
                                                                            if (_e9743 < _e9734) {
                                                                                continue;
                                                                            } else {
                                                                                break;
                                                                            }
                                                                            continuing {
                                                                                let _e9747 = local_11[_e9743][0u];
                                                                                let _e9750 = local_11[_e9738][1u];
                                                                                let _e9756 = clamp((_e9667 * ((_e9695 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e9747, _e9750))), _e9678.xy, _e9678.zw);
                                                                                let _e9759 = local_10[_e9743][0u];
                                                                                let _e9762 = local_10[_e9738][1u];
                                                                                let _e9768 = textureSampleCompare(global_2, global_1, vec3<f32>(_e9756.x, _e9756.y, _e9639).xy, _e9639);
                                                                                phi_36090_ = (_e9741 + ((_e9759 * _e9762) * _e9768));
                                                                                phi_36087_ = (_e9743 + 1i);
                                                                            }
                                                                        }
                                                                        continue;
                                                                    } else {
                                                                        break;
                                                                    }
                                                                    continuing {
                                                                        let _e13597 = local_125;
                                                                        phi_36084_ = _e13597;
                                                                        phi_36081_ = (_e9738 + 1i);
                                                                    }
                                                                }
                                                                let _e9774 = local_96;
                                                                phi_36091_ = (_e9774 * select(0.0069444445f, 0.0625f, _e9698));
                                                                break;
                                                            }
                                                        }
                                                        let _e9777 = phi_36091_;
                                                        phi_36103_ = _e9777;
                                                        break;
                                                    }
                                                }
                                                let _e9779 = phi_36103_;
                                                local_123 = (_e9344 + ((_e9342 - _e9381) * _e9779));
                                                continue;
                                            } else {
                                                break;
                                            }
                                            continuing {
                                                let _e13572 = local_122;
                                                phi_36076_ = _e13572;
                                                let _e13575 = local_123;
                                                phi_36075_ = _e13575;
                                                phi_36074_ = (_e9346 + 1i);
                                            }
                                        }
                                        let _e13606 = local_126;
                                        phi_36136_ = _e13606;
                                        break;
                                    }
                                }
                                let _e9784 = phi_36136_;
                                phi_36137_ = _e9784;
                            } else {
                                let _e9788 = global_19.member_1[1u];
                                let _e9791 = ((1200f / _e7491) / (0.6f + (6f * _e9788)));
                                let _e9793 = (-(_e9791) * _e9791);
                                phi_36137_ = ((((((vec3<f32>(0.233f, 0.455f, 0.649f) * exp((_e9793 * 156.25f))) + (vec3<f32>(0.1f, 0.336f, 0.344f) * exp((_e9793 * 20.661158f)))) + (vec3<f32>(0.118f, 0.198f, 0f) * exp((_e9793 * 5.3475933f)))) + (vec3<f32>(0.113f, 0.007f, 0.007f) * exp((_e9793 * 1.7636685f)))) + (vec3<f32>(0.358f, 0.004f, 0f) * exp((_e9793 * 0.5025126f)))) + (vec3<f32>(0.078f, 0f, 0f) * exp((_e9793 * 0.13495277f))));
                            }
                            let _e9818 = phi_36137_;
                            phi_37611_ = (_e8810 + ((_e9818 * _e8345) * ((clamp((0.3f - dot(_e963, _e8324)), 0f, 1f) * _e7479) * 2f)));
                        }
                        let _e9828 = phi_37611_;
                        local_117 = _e9828;
                        continue;
                    } else {
                        break;
                    }
                    continuing {
                        let _e13507 = local_116;
                        phi_35928_ = _e13507;
                        let _e13510 = local_117;
                        phi_35870_ = _e13510;
                        phi_35688_ = (_e8294 + bitcast<u32>(1i));
                    }
                }
                let _e13611 = local_127;
                phi_35903_ = _e13611;
                let _e13614 = local_128;
                phi_35868_ = _e13614;
            }
            let _e9832 = phi_35903_;
            let _e9834 = phi_35868_;
            let _e9837 = global_19.member_2[0u];
            let _e9840 = global_19.member_2[1u];
            let _e9843 = global_19.member_2[2u];
            let _e9846 = clamp((_e3422 * mix(_e9837, _e9840, _e9843)), 0.045f, 1f);
            let _e9848 = reflect(-(_e958), _e7451);
            let _e9851 = global.member_29[0u];
            let _e9852 = (_e9851 > 0.5f);
            if _e9852 {
                let _e9854 = global.member_29;
                let _e9861 = ((_e9854.z * _e7451.x) - (_e9854.w * _e7451.z));
                let _e9865 = ((_e9854.w * _e7451.x) + (_e9854.z * _e7451.z));
                let _e9869 = (1.092548f * _e9861);
                local_9 = array<f32, 9>(0.282095f, (0.488603f * _e7451.y), (0.488603f * _e9865), (0.488603f * _e9861), (_e9869 * _e7451.y), ((1.092548f * _e7451.y) * _e9865), (0.315392f * (((3f * _e9865) * _e9865) - 1f)), (_e9869 * _e9865), (0.546274f * ((_e9861 * _e9861) - (_e7451.y * _e7451.y))));
                phi_35718_ = vec3<f32>(0f, 0f, 0f);
                phi_35717_ = 0i;
                loop {
                    let _e9884 = phi_35718_;
                    let _e9886 = phi_35717_;
                    local_97 = _e9884;
                    if (_e9886 < 9i) {
                        continue;
                    } else {
                        break;
                    }
                    continuing {
                        let _e9890 = textureLoad(global_4, (vec2<i32>(496i, 256i) + vec2<i32>(_e9886, 0i)), 0i);
                        let _e9893 = local_9[_e9886];
                        phi_35718_ = (_e9884 + (_e9890.xyz * _e9893));
                        phi_35717_ = (_e9886 + 1i);
                    }
                }
                let _e9898 = local_97;
                let _e9902 = global.member_29[1u];
                let _e9920 = vec2<f32>(((atan2(((_e9854.z * _e9848.x) - (_e9854.w * _e9848.z)), -(((_e9854.w * _e9848.x) + (_e9854.z * _e9848.z)))) * 0.15915494f) + 0.5f), (acos(clamp(_e9848.y, -1f, 1f)) * 0.31830987f));
                let _e9921 = (_e9846 * 5f);
                let _e9923 = min(i32(_e9921), 4i);
                local_7 = array<vec4<i32>, 6>(vec4<i32>(0i, 0i, 512i, 256i), vec4<i32>(0i, 256i, 256i, 128i), vec4<i32>(256i, 256i, 128i, 64i), vec4<i32>(384i, 256i, 64i, 32i), vec4<i32>(448i, 256i, 32i, 16i), vec4<i32>(480i, 256i, 16i, 8i));
                let _e9925 = local_7[_e9923];
                let _e9929 = ((_e9920 * vec2<f32>(_e9925.zw)) - vec2<f32>(0.5f, 0.5f));
                let _e9930 = floor(_e9929);
                let _e9931 = (_e9929 - _e9930);
                let _e9933 = i32(_e9930.x);
                let _e9935 = i32(_e9930.y);
                phi_35719_ = _e9933;
                if (_e9933 < 0i) {
                    phi_35719_ = (_e9933 + _e9925.z);
                }
                let _e9940 = phi_35719_;
                phi_35720_ = _e9940;
                if (_e9940 >= _e9925.z) {
                    phi_35720_ = (_e9940 - _e9925.z);
                }
                let _e9945 = phi_35720_;
                let _e9946 = (_e9945 + 1i);
                let _e9948 = select(_e9946, 0i, (_e9946 == _e9925.z));
                let _e9952 = min((_e9935 + 1i), (_e9925.w - 1i));
                let _e9953 = max(_e9935, 0i);
                let _e9954 = _e9925.xy;
                let _e9957 = textureLoad(global_4, (_e9954 + vec2<i32>(_e9945, _e9953)), 0i);
                let _e9961 = textureLoad(global_4, (_e9954 + vec2<i32>(_e9948, _e9953)), 0i);
                let _e9965 = textureLoad(global_4, (_e9954 + vec2<i32>(_e9945, _e9952)), 0i);
                let _e9969 = textureLoad(global_4, (_e9954 + vec2<i32>(_e9948, _e9952)), 0i);
                let _e9972 = vec3(_e9931.x);
                local_8 = array<vec4<i32>, 6>(vec4<i32>(0i, 0i, 512i, 256i), vec4<i32>(0i, 256i, 256i, 128i), vec4<i32>(256i, 256i, 128i, 64i), vec4<i32>(384i, 256i, 64i, 32i), vec4<i32>(448i, 256i, 32i, 16i), vec4<i32>(480i, 256i, 16i, 8i));
                let _e9980 = local_8[(_e9923 + 1i)];
                let _e9984 = ((_e9920 * vec2<f32>(_e9980.zw)) - vec2<f32>(0.5f, 0.5f));
                let _e9985 = floor(_e9984);
                let _e9986 = (_e9984 - _e9985);
                let _e9988 = i32(_e9985.x);
                let _e9990 = i32(_e9985.y);
                phi_35726_ = _e9988;
                if (_e9988 < 0i) {
                    phi_35726_ = (_e9988 + _e9980.z);
                }
                let _e9995 = phi_35726_;
                phi_35727_ = _e9995;
                if (_e9995 >= _e9980.z) {
                    phi_35727_ = (_e9995 - _e9980.z);
                }
                let _e10000 = phi_35727_;
                let _e10001 = (_e10000 + 1i);
                let _e10003 = select(_e10001, 0i, (_e10001 == _e9980.z));
                let _e10007 = min((_e9990 + 1i), (_e9980.w - 1i));
                let _e10008 = max(_e9990, 0i);
                let _e10009 = _e9980.xy;
                let _e10012 = textureLoad(global_4, (_e10009 + vec2<i32>(_e10000, _e10008)), 0i);
                let _e10016 = textureLoad(global_4, (_e10009 + vec2<i32>(_e10003, _e10008)), 0i);
                let _e10020 = textureLoad(global_4, (_e10009 + vec2<i32>(_e10000, _e10007)), 0i);
                let _e10024 = textureLoad(global_4, (_e10009 + vec2<i32>(_e10003, _e10007)), 0i);
                let _e10027 = vec3(_e9986.x);
                phi_35743_ = (mix(mix(mix(_e9957.xyz, _e9961.xyz, _e9972), mix(_e9965.xyz, _e9969.xyz, _e9972), vec3(_e9931.y)), mix(mix(_e10012.xyz, _e10016.xyz, _e10027), mix(_e10020.xyz, _e10024.xyz, _e10027), vec3(_e9986.y)), vec3((_e9921 - f32(_e9923)))) * _e9902);
                phi_35733_ = (max(_e9898, vec3<f32>(0f, 0f, 0f)) * _e9902);
            } else {
                let _e10039 = global.member_9;
                let _e10040 = _e10039.xyz;
                let _e10042 = global.member_8;
                let _e10043 = _e10042.xyz;
                let _e10051 = global.member_8[3u];
                let _e10052 = (mix(_e10040, _e10043, vec3(((_e7451.y * 0.5f) + 0.5f))) * _e10051);
                phi_35743_ = mix((mix(_e10040, _e10043, vec3(((_e9848.y * 0.5f) + 0.5f))) * _e10051), _e10052, vec3(_e9846));
                phi_35733_ = _e10052;
            }
            let _e10062 = phi_35743_;
            let _e10064 = phi_35733_;
            let _e10067 = global.member_34[1u];
            phi_35834_ = _e10064;
            if (_e10067 > 0.5f) {
                let _e10072 = global.member_34[0u];
                phi_35741_ = _e10064;
                phi_35740_ = 0i;
                loop {
                    let _e10075 = phi_35741_;
                    let _e10077 = phi_35740_;
                    local_129 = _e10075;
                    if (_e10077 < i32(_e10067)) {
                        let _e10080 = (8i * (i32(_e10072) + _e10077));
                        let _e10084 = global_3.member[(_e10080 + 3i)];
                        let _e10085 = bitcast<vec4<f32>>(_e10084);
                        let _e10088 = global_3.member[_e10080];
                        let _e10089 = bitcast<vec4<f32>>(_e10088);
                        let _e10093 = global_3.member[(_e10080 + 1i)];
                        let _e10094 = bitcast<vec4<f32>>(_e10093);
                        let _e10098 = global_3.member[(_e10080 + 2i)];
                        let _e10099 = bitcast<vec4<f32>>(_e10098);
                        let _e10100 = _e10089.xyz;
                        let _e10104 = _e10094.xyz;
                        let _e10108 = _e10099.xyz;
                        let _e10112 = vec3<f32>((dot(_e10100, _e956) + _e10089.w), (dot(_e10104, _e956) + _e10094.w), (dot(_e10108, _e956) + _e10099.w));
                        let _e10113 = _e10085.xyz;
                        switch bitcast<i32>(0u) {
                            default: {
                                let _e10117 = (_e10113 - abs(_e10112));
                                let _e10122 = min(_e10117.x, min(_e10117.y, _e10117.z));
                                if (_e10122 <= 0f) {
                                    phi_35950_ = 0f;
                                    break;
                                }
                                if (_e10085.w <= 0f) {
                                    phi_35950_ = 1f;
                                    break;
                                }
                                let _e10126 = min((_e10122 / _e10085.w), 1f);
                                phi_35950_ = ((_e10126 * _e10126) * (3f - (2f * _e10126)));
                                break;
                            }
                        }
                        let _e10132 = phi_35950_;
                        if (_e10132 <= 0f) {
                            phi_37604_ = _e10075;
                            continue;
                        }
                        let _e10137 = global_3.member[(_e10080 + 4i)];
                        let _e10139 = bitcast<vec4<f32>>(_e10137).xyz;
                        let _e10143 = global_3.member[(_e10080 + 5i)];
                        let _e10144 = bitcast<vec4<f32>>(_e10143);
                        let _e10149 = global_3.member[(_e10080 + 6i)][0u];
                        let _e10150 = bitcast<i32>(_e10149);
                        let _e10151 = dot(_e10100, _e7451);
                        let _e10152 = dot(_e10104, _e7451);
                        let _e10153 = dot(_e10108, _e7451);
                        let _e10154 = vec3<f32>(_e10151, _e10152, _e10153);
                        let _e10160 = ((_e956 + (_e7451 * _e10144.x)) + (_e958 * _e10144.y));
                        let _e10175 = clamp(((((vec3<f32>((dot(_e10100, _e10160) + _e10089.w), (dot(_e10104, _e10160) + _e10094.w), (dot(_e10108, _e10160) + _e10099.w)) + _e10113) / max((_e10113 * 2f), vec3<f32>(0.000001f, 0.000001f, 0.000001f))) * _e10139) - vec3<f32>(0.5f, 0.5f, 0.5f)), vec3<f32>(0f, 0f, 0f), (_e10139 - vec3<f32>(1f, 1f, 1f)));
                        let _e10176 = vec3<i32>(_e10139);
                        let _e10180 = min(vec3<i32>(_e10175), max((_e10176 - vec3<i32>(2i, 2i, 2i)), vec3<i32>(0i, 0i, 0i)));
                        let _e10182 = (_e10175 - vec3<f32>(_e10180));
                        let _e10183 = (0.488603f * _e10152);
                        let _e10184 = (0.488603f * _e10153);
                        let _e10185 = (0.488603f * _e10151);
                        let _e10186 = (1.092548f * _e10151);
                        let _e10187 = (_e10186 * _e10152);
                        let _e10189 = ((1.092548f * _e10152) * _e10153);
                        let _e10193 = (0.315392f * (((3f * _e10153) * _e10153) - 1f));
                        let _e10194 = (_e10186 * _e10153);
                        let _e10198 = (0.546274f * ((_e10151 * _e10151) - (_e10152 * _e10152)));
                        let _e10199 = (_e10176 - vec3<i32>(1i, 1i, 1i));
                        let _e10200 = min(_e10180, _e10199);
                        let _e10211 = (_e10150 + ((_e10200.x + (_e10176.x * (_e10200.y + (_e10176.y * _e10200.z)))) * 4i));
                        let _e10212 = (vec3<f32>(1f, 1f, 1f) - _e10182);
                        let _e10219 = ((((((vec3<f32>(_e10200) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e10139) * _e10113) * 2f) - _e10113) - _e10112);
                        let _e10225 = (dot((_e10219 * inverseSqrt(max(dot(_e10219, _e10219), 0.0000000001f))), _e10154) + 1f);
                        let _e10228 = (_e10212.x * _e10212.y);
                        let _e10235 = (_e10211 + 3i);
                        let _e10239 = global_3.member[_e10235][1u];
                        let _e10244 = (((_e10228 * _e10212.z) * ((0.25f * (_e10225 * _e10225)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e10239).y > 0.5f)));
                        let _e10247 = global_3.member[_e10211];
                        let _e10251 = global_3.member[(_e10211 + 1i)];
                        let _e10255 = global_3.member[(_e10211 + 2i)];
                        let _e10258 = global_3.member[_e10235];
                        let _e10260 = unpack2x16float(_e10247.x);
                        let _e10262 = unpack2x16float(_e10247.y);
                        let _e10264 = unpack2x16float(_e10247.z);
                        let _e10266 = unpack2x16float(_e10247.w);
                        let _e10268 = unpack2x16float(_e10251.x);
                        let _e10270 = unpack2x16float(_e10251.y);
                        let _e10272 = unpack2x16float(_e10251.z);
                        let _e10274 = unpack2x16float(_e10251.w);
                        let _e10276 = unpack2x16float(_e10255.x);
                        let _e10278 = unpack2x16float(_e10255.y);
                        let _e10280 = unpack2x16float(_e10255.z);
                        let _e10282 = unpack2x16float(_e10255.w);
                        let _e10284 = unpack2x16float(_e10258.x);
                        let _e10340 = ((((((((((vec3<f32>(_e10260.x, _e10260.y, _e10262.x) * 0.282095f) + (vec3<f32>(_e10262.y, _e10264.x, _e10264.y) * _e10183)) + (vec3<f32>(_e10266.x, _e10266.y, _e10268.x) * _e10184)) + (vec3<f32>(_e10268.y, _e10270.x, _e10270.y) * _e10185)) + (vec3<f32>(_e10272.x, _e10272.y, _e10274.x) * _e10187)) + (vec3<f32>(_e10274.y, _e10276.x, _e10276.y) * _e10189)) + (vec3<f32>(_e10278.x, _e10278.y, _e10280.x) * _e10193)) + (vec3<f32>(_e10280.y, _e10282.x, _e10282.y) * _e10194)) + (vec3<f32>(_e10284.x, _e10284.y, unpack2x16float(_e10258.y).x) * _e10198)) * _e10244);
                        let _e10346 = min((_e10180 + vec3<i32>(1i, 0i, 0i)), _e10199);
                        let _e10355 = (_e10150 + ((_e10346.x + (_e10176.x * (_e10346.y + (_e10176.y * _e10346.z)))) * 4i));
                        let _e10362 = ((((((vec3<f32>(_e10346) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e10139) * _e10113) * 2f) - _e10113) - _e10112);
                        let _e10368 = (dot((_e10362 * inverseSqrt(max(dot(_e10362, _e10362), 0.0000000001f))), _e10154) + 1f);
                        let _e10370 = (_e10182.x * _e10212.y);
                        let _e10376 = (_e10355 + 3i);
                        let _e10380 = global_3.member[_e10376][1u];
                        let _e10385 = (((_e10370 * _e10212.z) * ((0.25f * (_e10368 * _e10368)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e10380).y > 0.5f)));
                        let _e10388 = global_3.member[_e10355];
                        let _e10392 = global_3.member[(_e10355 + 1i)];
                        let _e10396 = global_3.member[(_e10355 + 2i)];
                        let _e10399 = global_3.member[_e10376];
                        let _e10401 = unpack2x16float(_e10388.x);
                        let _e10403 = unpack2x16float(_e10388.y);
                        let _e10405 = unpack2x16float(_e10388.z);
                        let _e10407 = unpack2x16float(_e10388.w);
                        let _e10409 = unpack2x16float(_e10392.x);
                        let _e10411 = unpack2x16float(_e10392.y);
                        let _e10413 = unpack2x16float(_e10392.z);
                        let _e10415 = unpack2x16float(_e10392.w);
                        let _e10417 = unpack2x16float(_e10396.x);
                        let _e10419 = unpack2x16float(_e10396.y);
                        let _e10421 = unpack2x16float(_e10396.z);
                        let _e10423 = unpack2x16float(_e10396.w);
                        let _e10425 = unpack2x16float(_e10399.x);
                        let _e10481 = ((((((((((vec3<f32>(_e10401.x, _e10401.y, _e10403.x) * 0.282095f) + (vec3<f32>(_e10403.y, _e10405.x, _e10405.y) * _e10183)) + (vec3<f32>(_e10407.x, _e10407.y, _e10409.x) * _e10184)) + (vec3<f32>(_e10409.y, _e10411.x, _e10411.y) * _e10185)) + (vec3<f32>(_e10413.x, _e10413.y, _e10415.x) * _e10187)) + (vec3<f32>(_e10415.y, _e10417.x, _e10417.y) * _e10189)) + (vec3<f32>(_e10419.x, _e10419.y, _e10421.x) * _e10193)) + (vec3<f32>(_e10421.y, _e10423.x, _e10423.y) * _e10194)) + (vec3<f32>(_e10425.x, _e10425.y, unpack2x16float(_e10399.y).x) * _e10198)) * _e10385);
                        let _e10488 = min((_e10180 + vec3<i32>(0i, 1i, 0i)), _e10199);
                        let _e10497 = (_e10150 + ((_e10488.x + (_e10176.x * (_e10488.y + (_e10176.y * _e10488.z)))) * 4i));
                        let _e10504 = ((((((vec3<f32>(_e10488) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e10139) * _e10113) * 2f) - _e10113) - _e10112);
                        let _e10510 = (dot((_e10504 * inverseSqrt(max(dot(_e10504, _e10504), 0.0000000001f))), _e10154) + 1f);
                        let _e10512 = (_e10212.x * _e10182.y);
                        let _e10518 = (_e10497 + 3i);
                        let _e10522 = global_3.member[_e10518][1u];
                        let _e10527 = (((_e10512 * _e10212.z) * ((0.25f * (_e10510 * _e10510)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e10522).y > 0.5f)));
                        let _e10530 = global_3.member[_e10497];
                        let _e10534 = global_3.member[(_e10497 + 1i)];
                        let _e10538 = global_3.member[(_e10497 + 2i)];
                        let _e10541 = global_3.member[_e10518];
                        let _e10543 = unpack2x16float(_e10530.x);
                        let _e10545 = unpack2x16float(_e10530.y);
                        let _e10547 = unpack2x16float(_e10530.z);
                        let _e10549 = unpack2x16float(_e10530.w);
                        let _e10551 = unpack2x16float(_e10534.x);
                        let _e10553 = unpack2x16float(_e10534.y);
                        let _e10555 = unpack2x16float(_e10534.z);
                        let _e10557 = unpack2x16float(_e10534.w);
                        let _e10559 = unpack2x16float(_e10538.x);
                        let _e10561 = unpack2x16float(_e10538.y);
                        let _e10563 = unpack2x16float(_e10538.z);
                        let _e10565 = unpack2x16float(_e10538.w);
                        let _e10567 = unpack2x16float(_e10541.x);
                        let _e10623 = ((((((((((vec3<f32>(_e10543.x, _e10543.y, _e10545.x) * 0.282095f) + (vec3<f32>(_e10545.y, _e10547.x, _e10547.y) * _e10183)) + (vec3<f32>(_e10549.x, _e10549.y, _e10551.x) * _e10184)) + (vec3<f32>(_e10551.y, _e10553.x, _e10553.y) * _e10185)) + (vec3<f32>(_e10555.x, _e10555.y, _e10557.x) * _e10187)) + (vec3<f32>(_e10557.y, _e10559.x, _e10559.y) * _e10189)) + (vec3<f32>(_e10561.x, _e10561.y, _e10563.x) * _e10193)) + (vec3<f32>(_e10563.y, _e10565.x, _e10565.y) * _e10194)) + (vec3<f32>(_e10567.x, _e10567.y, unpack2x16float(_e10541.y).x) * _e10198)) * _e10527);
                        let _e10630 = min((_e10180 + vec3<i32>(1i, 1i, 0i)), _e10199);
                        let _e10639 = (_e10150 + ((_e10630.x + (_e10176.x * (_e10630.y + (_e10176.y * _e10630.z)))) * 4i));
                        let _e10646 = ((((((vec3<f32>(_e10630) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e10139) * _e10113) * 2f) - _e10113) - _e10112);
                        let _e10652 = (dot((_e10646 * inverseSqrt(max(dot(_e10646, _e10646), 0.0000000001f))), _e10154) + 1f);
                        let _e10653 = (_e10182.x * _e10182.y);
                        let _e10659 = (_e10639 + 3i);
                        let _e10663 = global_3.member[_e10659][1u];
                        let _e10668 = (((_e10653 * _e10212.z) * ((0.25f * (_e10652 * _e10652)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e10663).y > 0.5f)));
                        let _e10671 = global_3.member[_e10639];
                        let _e10675 = global_3.member[(_e10639 + 1i)];
                        let _e10679 = global_3.member[(_e10639 + 2i)];
                        let _e10682 = global_3.member[_e10659];
                        let _e10684 = unpack2x16float(_e10671.x);
                        let _e10686 = unpack2x16float(_e10671.y);
                        let _e10688 = unpack2x16float(_e10671.z);
                        let _e10690 = unpack2x16float(_e10671.w);
                        let _e10692 = unpack2x16float(_e10675.x);
                        let _e10694 = unpack2x16float(_e10675.y);
                        let _e10696 = unpack2x16float(_e10675.z);
                        let _e10698 = unpack2x16float(_e10675.w);
                        let _e10700 = unpack2x16float(_e10679.x);
                        let _e10702 = unpack2x16float(_e10679.y);
                        let _e10704 = unpack2x16float(_e10679.z);
                        let _e10706 = unpack2x16float(_e10679.w);
                        let _e10708 = unpack2x16float(_e10682.x);
                        let _e10764 = ((((((((((vec3<f32>(_e10684.x, _e10684.y, _e10686.x) * 0.282095f) + (vec3<f32>(_e10686.y, _e10688.x, _e10688.y) * _e10183)) + (vec3<f32>(_e10690.x, _e10690.y, _e10692.x) * _e10184)) + (vec3<f32>(_e10692.y, _e10694.x, _e10694.y) * _e10185)) + (vec3<f32>(_e10696.x, _e10696.y, _e10698.x) * _e10187)) + (vec3<f32>(_e10698.y, _e10700.x, _e10700.y) * _e10189)) + (vec3<f32>(_e10702.x, _e10702.y, _e10704.x) * _e10193)) + (vec3<f32>(_e10704.y, _e10706.x, _e10706.y) * _e10194)) + (vec3<f32>(_e10708.x, _e10708.y, unpack2x16float(_e10682.y).x) * _e10198)) * _e10668);
                        let _e10771 = min((_e10180 + vec3<i32>(0i, 0i, 1i)), _e10199);
                        let _e10780 = (_e10150 + ((_e10771.x + (_e10176.x * (_e10771.y + (_e10176.y * _e10771.z)))) * 4i));
                        let _e10787 = ((((((vec3<f32>(_e10771) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e10139) * _e10113) * 2f) - _e10113) - _e10112);
                        let _e10793 = (dot((_e10787 * inverseSqrt(max(dot(_e10787, _e10787), 0.0000000001f))), _e10154) + 1f);
                        let _e10800 = (_e10780 + 3i);
                        let _e10804 = global_3.member[_e10800][1u];
                        let _e10809 = (((_e10228 * _e10182.z) * ((0.25f * (_e10793 * _e10793)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e10804).y > 0.5f)));
                        let _e10812 = global_3.member[_e10780];
                        let _e10816 = global_3.member[(_e10780 + 1i)];
                        let _e10820 = global_3.member[(_e10780 + 2i)];
                        let _e10823 = global_3.member[_e10800];
                        let _e10825 = unpack2x16float(_e10812.x);
                        let _e10827 = unpack2x16float(_e10812.y);
                        let _e10829 = unpack2x16float(_e10812.z);
                        let _e10831 = unpack2x16float(_e10812.w);
                        let _e10833 = unpack2x16float(_e10816.x);
                        let _e10835 = unpack2x16float(_e10816.y);
                        let _e10837 = unpack2x16float(_e10816.z);
                        let _e10839 = unpack2x16float(_e10816.w);
                        let _e10841 = unpack2x16float(_e10820.x);
                        let _e10843 = unpack2x16float(_e10820.y);
                        let _e10845 = unpack2x16float(_e10820.z);
                        let _e10847 = unpack2x16float(_e10820.w);
                        let _e10849 = unpack2x16float(_e10823.x);
                        let _e10905 = ((((((((((vec3<f32>(_e10825.x, _e10825.y, _e10827.x) * 0.282095f) + (vec3<f32>(_e10827.y, _e10829.x, _e10829.y) * _e10183)) + (vec3<f32>(_e10831.x, _e10831.y, _e10833.x) * _e10184)) + (vec3<f32>(_e10833.y, _e10835.x, _e10835.y) * _e10185)) + (vec3<f32>(_e10837.x, _e10837.y, _e10839.x) * _e10187)) + (vec3<f32>(_e10839.y, _e10841.x, _e10841.y) * _e10189)) + (vec3<f32>(_e10843.x, _e10843.y, _e10845.x) * _e10193)) + (vec3<f32>(_e10845.y, _e10847.x, _e10847.y) * _e10194)) + (vec3<f32>(_e10849.x, _e10849.y, unpack2x16float(_e10823.y).x) * _e10198)) * _e10809);
                        let _e10912 = min((_e10180 + vec3<i32>(1i, 0i, 1i)), _e10199);
                        let _e10921 = (_e10150 + ((_e10912.x + (_e10176.x * (_e10912.y + (_e10176.y * _e10912.z)))) * 4i));
                        let _e10928 = ((((((vec3<f32>(_e10912) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e10139) * _e10113) * 2f) - _e10113) - _e10112);
                        let _e10934 = (dot((_e10928 * inverseSqrt(max(dot(_e10928, _e10928), 0.0000000001f))), _e10154) + 1f);
                        let _e10940 = (_e10921 + 3i);
                        let _e10944 = global_3.member[_e10940][1u];
                        let _e10949 = (((_e10370 * _e10182.z) * ((0.25f * (_e10934 * _e10934)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e10944).y > 0.5f)));
                        let _e10952 = global_3.member[_e10921];
                        let _e10956 = global_3.member[(_e10921 + 1i)];
                        let _e10960 = global_3.member[(_e10921 + 2i)];
                        let _e10963 = global_3.member[_e10940];
                        let _e10965 = unpack2x16float(_e10952.x);
                        let _e10967 = unpack2x16float(_e10952.y);
                        let _e10969 = unpack2x16float(_e10952.z);
                        let _e10971 = unpack2x16float(_e10952.w);
                        let _e10973 = unpack2x16float(_e10956.x);
                        let _e10975 = unpack2x16float(_e10956.y);
                        let _e10977 = unpack2x16float(_e10956.z);
                        let _e10979 = unpack2x16float(_e10956.w);
                        let _e10981 = unpack2x16float(_e10960.x);
                        let _e10983 = unpack2x16float(_e10960.y);
                        let _e10985 = unpack2x16float(_e10960.z);
                        let _e10987 = unpack2x16float(_e10960.w);
                        let _e10989 = unpack2x16float(_e10963.x);
                        let _e11045 = ((((((((((vec3<f32>(_e10965.x, _e10965.y, _e10967.x) * 0.282095f) + (vec3<f32>(_e10967.y, _e10969.x, _e10969.y) * _e10183)) + (vec3<f32>(_e10971.x, _e10971.y, _e10973.x) * _e10184)) + (vec3<f32>(_e10973.y, _e10975.x, _e10975.y) * _e10185)) + (vec3<f32>(_e10977.x, _e10977.y, _e10979.x) * _e10187)) + (vec3<f32>(_e10979.y, _e10981.x, _e10981.y) * _e10189)) + (vec3<f32>(_e10983.x, _e10983.y, _e10985.x) * _e10193)) + (vec3<f32>(_e10985.y, _e10987.x, _e10987.y) * _e10194)) + (vec3<f32>(_e10989.x, _e10989.y, unpack2x16float(_e10963.y).x) * _e10198)) * _e10949);
                        let _e11052 = min((_e10180 + vec3<i32>(0i, 1i, 1i)), _e10199);
                        let _e11061 = (_e10150 + ((_e11052.x + (_e10176.x * (_e11052.y + (_e10176.y * _e11052.z)))) * 4i));
                        let _e11068 = ((((((vec3<f32>(_e11052) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e10139) * _e10113) * 2f) - _e10113) - _e10112);
                        let _e11074 = (dot((_e11068 * inverseSqrt(max(dot(_e11068, _e11068), 0.0000000001f))), _e10154) + 1f);
                        let _e11080 = (_e11061 + 3i);
                        let _e11084 = global_3.member[_e11080][1u];
                        let _e11089 = (((_e10512 * _e10182.z) * ((0.25f * (_e11074 * _e11074)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e11084).y > 0.5f)));
                        let _e11092 = global_3.member[_e11061];
                        let _e11096 = global_3.member[(_e11061 + 1i)];
                        let _e11100 = global_3.member[(_e11061 + 2i)];
                        let _e11103 = global_3.member[_e11080];
                        let _e11105 = unpack2x16float(_e11092.x);
                        let _e11107 = unpack2x16float(_e11092.y);
                        let _e11109 = unpack2x16float(_e11092.z);
                        let _e11111 = unpack2x16float(_e11092.w);
                        let _e11113 = unpack2x16float(_e11096.x);
                        let _e11115 = unpack2x16float(_e11096.y);
                        let _e11117 = unpack2x16float(_e11096.z);
                        let _e11119 = unpack2x16float(_e11096.w);
                        let _e11121 = unpack2x16float(_e11100.x);
                        let _e11123 = unpack2x16float(_e11100.y);
                        let _e11125 = unpack2x16float(_e11100.z);
                        let _e11127 = unpack2x16float(_e11100.w);
                        let _e11129 = unpack2x16float(_e11103.x);
                        let _e11185 = ((((((((((vec3<f32>(_e11105.x, _e11105.y, _e11107.x) * 0.282095f) + (vec3<f32>(_e11107.y, _e11109.x, _e11109.y) * _e10183)) + (vec3<f32>(_e11111.x, _e11111.y, _e11113.x) * _e10184)) + (vec3<f32>(_e11113.y, _e11115.x, _e11115.y) * _e10185)) + (vec3<f32>(_e11117.x, _e11117.y, _e11119.x) * _e10187)) + (vec3<f32>(_e11119.y, _e11121.x, _e11121.y) * _e10189)) + (vec3<f32>(_e11123.x, _e11123.y, _e11125.x) * _e10193)) + (vec3<f32>(_e11125.y, _e11127.x, _e11127.y) * _e10194)) + (vec3<f32>(_e11129.x, _e11129.y, unpack2x16float(_e11103.y).x) * _e10198)) * _e11089);
                        let _e11192 = min((_e10180 + vec3<i32>(1i, 1i, 1i)), _e10199);
                        let _e11201 = (_e10150 + ((_e11192.x + (_e10176.x * (_e11192.y + (_e10176.y * _e11192.z)))) * 4i));
                        let _e11208 = ((((((vec3<f32>(_e11192) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e10139) * _e10113) * 2f) - _e10113) - _e10112);
                        let _e11214 = (dot((_e11208 * inverseSqrt(max(dot(_e11208, _e11208), 0.0000000001f))), _e10154) + 1f);
                        let _e11220 = (_e11201 + 3i);
                        let _e11224 = global_3.member[_e11220][1u];
                        let _e11229 = (((_e10653 * _e10182.z) * ((0.25f * (_e11214 * _e11214)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e11224).y > 0.5f)));
                        let _e11232 = global_3.member[_e11201];
                        let _e11236 = global_3.member[(_e11201 + 1i)];
                        let _e11240 = global_3.member[(_e11201 + 2i)];
                        let _e11243 = global_3.member[_e11220];
                        let _e11245 = unpack2x16float(_e11232.x);
                        let _e11247 = unpack2x16float(_e11232.y);
                        let _e11249 = unpack2x16float(_e11232.z);
                        let _e11251 = unpack2x16float(_e11232.w);
                        let _e11253 = unpack2x16float(_e11236.x);
                        let _e11255 = unpack2x16float(_e11236.y);
                        let _e11257 = unpack2x16float(_e11236.z);
                        let _e11259 = unpack2x16float(_e11236.w);
                        let _e11261 = unpack2x16float(_e11240.x);
                        let _e11263 = unpack2x16float(_e11240.y);
                        let _e11265 = unpack2x16float(_e11240.z);
                        let _e11267 = unpack2x16float(_e11240.w);
                        let _e11269 = unpack2x16float(_e11243.x);
                        let _e11325 = ((((((((((vec3<f32>(_e11245.x, _e11245.y, _e11247.x) * 0.282095f) + (vec3<f32>(_e11247.y, _e11249.x, _e11249.y) * _e10183)) + (vec3<f32>(_e11251.x, _e11251.y, _e11253.x) * _e10184)) + (vec3<f32>(_e11253.y, _e11255.x, _e11255.y) * _e10185)) + (vec3<f32>(_e11257.x, _e11257.y, _e11259.x) * _e10187)) + (vec3<f32>(_e11259.y, _e11261.x, _e11261.y) * _e10189)) + (vec3<f32>(_e11263.x, _e11263.y, _e11265.x) * _e10193)) + (vec3<f32>(_e11265.y, _e11267.x, _e11267.y) * _e10194)) + (vec3<f32>(_e11269.x, _e11269.y, unpack2x16float(_e11243.y).x) * _e10198)) * _e11229);
                        let _e11330 = (((((((vec4<f32>(_e10340.x, _e10340.y, _e10340.z, _e10244) + vec4<f32>(_e10481.x, _e10481.y, _e10481.z, _e10385)) + vec4<f32>(_e10623.x, _e10623.y, _e10623.z, _e10527)) + vec4<f32>(_e10764.x, _e10764.y, _e10764.z, _e10668)) + vec4<f32>(_e10905.x, _e10905.y, _e10905.z, _e10809)) + vec4<f32>(_e11045.x, _e11045.y, _e11045.z, _e10949)) + vec4<f32>(_e11185.x, _e11185.y, _e11185.z, _e11089)) + vec4<f32>(_e11325.x, _e11325.y, _e11325.z, _e11229));
                        phi_37605_ = _e10075;
                        if (_e11330.w > 0.00001f) {
                            phi_37605_ = mix(_e10075, ((max(_e11330.xyz, vec3<f32>(0f, 0f, 0f)) / vec3(_e11330.w)) * _e10144.z), vec3(_e10132));
                        }
                        let _e11342 = phi_37605_;
                        phi_37604_ = _e11342;
                        continue;
                    } else {
                        break;
                    }
                    continuing {
                        let _e11344 = phi_37604_;
                        phi_35741_ = _e11344;
                        phi_35740_ = (_e10077 + 1i);
                    }
                }
                let _e13631 = local_129;
                phi_35834_ = _e13631;
            }
            let _e11347 = phi_35834_;
            let _e11350 = global.member_34[0u];
            phi_35855_ = _e10062;
            if (_e11350 > 0.5f) {
                phi_35812_ = vec3<f32>(0f, 0f, 0f);
                phi_35746_ = 0f;
                phi_35745_ = 0i;
                loop {
                    let _e11354 = phi_35812_;
                    let _e11356 = phi_35746_;
                    let _e11358 = phi_35745_;
                    local_98 = _e11356;
                    local_99 = _e11354;
                    if (_e11358 < i32(_e11350)) {
                        if (_e11356 > 0.999f) {
                            break;
                        }
                        let _e11361 = (_e11358 * 8i);
                        let _e11364 = global_3.member[_e11361];
                        let _e11365 = bitcast<vec4<f32>>(_e11364);
                        let _e11369 = global_3.member[(_e11361 + 1i)];
                        let _e11370 = bitcast<vec4<f32>>(_e11369);
                        let _e11374 = global_3.member[(_e11361 + 2i)];
                        let _e11375 = bitcast<vec4<f32>>(_e11374);
                        let _e11376 = _e11365.xyz;
                        let _e11380 = _e11370.xyz;
                        let _e11384 = _e11375.xyz;
                        let _e11388 = vec3<f32>((dot(_e11376, _e956) + _e11365.w), (dot(_e11380, _e956) + _e11370.w), (dot(_e11384, _e956) + _e11375.w));
                        let _e11392 = global_3.member[(_e11361 + 3i)];
                        let _e11393 = bitcast<vec4<f32>>(_e11392);
                        switch bitcast<i32>(0u) {
                            default: {
                                let _e11398 = (_e11393.xyz - abs(_e11388));
                                let _e11403 = min(_e11398.x, min(_e11398.y, _e11398.z));
                                if (_e11403 <= 0f) {
                                    phi_35747_ = 0f;
                                    break;
                                }
                                if (_e11393.w <= 0f) {
                                    phi_35747_ = 1f;
                                    break;
                                }
                                let _e11407 = min((_e11403 / _e11393.w), 1f);
                                phi_35747_ = ((_e11407 * _e11407) * (3f - (2f * _e11407)));
                                break;
                            }
                        }
                        let _e11413 = phi_35747_;
                        if (_e11413 <= 0f) {
                            phi_37610_ = _e11354;
                            phi_37609_ = _e11356;
                            continue;
                        }
                        let _e11418 = global_3.member[(_e11361 + 4i)];
                        let _e11419 = bitcast<vec4<f32>>(_e11418);
                        let _e11423 = global_3.member[(_e11361 + 5i)];
                        let _e11424 = bitcast<vec4<f32>>(_e11423);
                        let _e11428 = vec3<f32>(dot(_e11376, _e9848), dot(_e11380, _e9848), dot(_e11384, _e9848));
                        if (_e11419.w > 0.5f) {
                            let _e11431 = _e11419.xyz;
                            let _e11433 = -(_e11431);
                            let _e11434 = clamp(_e11388, _e11433, _e11431);
                            let _e11438 = step(vec3<f32>(0.000001f, 0.000001f, 0.000001f), abs(_e11428));
                            let _e11442 = mix(vec3<f32>(1000000000000000000000000000000f, 1000000000000000000000000000000f, 1000000000000000000000000000000f), ((mix(_e11433, _e11431, step(vec3<f32>(0f, 0f, 0f), _e11428)) - _e11434) / mix(vec3<f32>(0.000001f, 0.000001f, 0.000001f), _e11428, _e11438)), _e11438);
                            let _e11451 = ((_e11434 + (_e11428 * max(min(_e11442.x, min(_e11442.y, _e11442.z)), 0f))) - _e11424.xyz);
                            if (dot(_e11451, _e11451) > 0.000000000001f) {
                                phi_35748_ = normalize(_e11451);
                            } else {
                                phi_35748_ = _e11428;
                            }
                            let _e11456 = phi_35748_;
                            phi_35749_ = _e11456;
                        } else {
                            phi_35749_ = _e11428;
                        }
                        let _e11458 = phi_35749_;
                        let _e11463 = global_3.member[(_e11361 + 6i)][0u];
                        let _e11464 = bitcast<i32>(_e11463);
                        let _e11475 = vec2<f32>(((atan2(_e11458.x, -(_e11458.z)) * 0.15915494f) + 0.5f), (acos(clamp(_e11458.y, -1f, 1f)) * 0.31830987f));
                        let _e11476 = (_e9846 * 5f);
                        let _e11478 = min(i32(_e11476), 4i);
                        local_6 = array<vec3<i32>, 6>(vec3<i32>(0i, 256i, 128i), vec3<i32>(32768i, 128i, 64i), vec3<i32>(40960i, 64i, 32i), vec3<i32>(43008i, 32i, 16i), vec3<i32>(43520i, 16i, 8i), vec3<i32>(43648i, 8i, 4i));
                        let _e11480 = local_6[_e11478];
                        let _e11482 = (_e11464 + _e11480.x);
                        let _e11486 = ((_e11475 * vec2<f32>(_e11480.yz)) - vec2<f32>(0.5f, 0.5f));
                        let _e11487 = floor(_e11486);
                        let _e11488 = (_e11486 - _e11487);
                        let _e11490 = i32(_e11487.x);
                        let _e11492 = i32(_e11487.y);
                        phi_35750_ = _e11490;
                        if (_e11490 < 0i) {
                            phi_35750_ = (_e11490 + _e11480.y);
                        }
                        let _e11497 = phi_35750_;
                        phi_35751_ = _e11497;
                        if (_e11497 >= _e11480.y) {
                            phi_35751_ = (_e11497 - _e11480.y);
                        }
                        let _e11502 = phi_35751_;
                        let _e11503 = (_e11502 + 1i);
                        let _e11505 = select(_e11503, 0i, (_e11503 == _e11480.y));
                        let _e11512 = (_e11482 + (max(_e11492, 0i) * _e11480.y));
                        let _e11513 = (_e11512 + _e11502);
                        let _e11518 = global_3.member[(_e11513 >> bitcast<u32>(1i))];
                        if ((_e11513 & 1i) == 0i) {
                            phi_35757_ = _e11518.xy;
                        } else {
                            phi_35757_ = _e11518.zw;
                        }
                        let _e11524 = phi_35757_;
                        let _e11526 = unpack2x16float(_e11524.x);
                        let _e11533 = (_e11512 + _e11505);
                        let _e11538 = global_3.member[(_e11533 >> bitcast<u32>(1i))];
                        if ((_e11533 & 1i) == 0i) {
                            phi_35759_ = _e11538.xy;
                        } else {
                            phi_35759_ = _e11538.zw;
                        }
                        let _e11544 = phi_35759_;
                        let _e11546 = unpack2x16float(_e11544.x);
                        let _e11554 = (_e11482 + (min((_e11492 + 1i), (_e11480.z - 1i)) * _e11480.y));
                        let _e11555 = (_e11554 + _e11502);
                        let _e11560 = global_3.member[(_e11555 >> bitcast<u32>(1i))];
                        if ((_e11555 & 1i) == 0i) {
                            phi_35762_ = _e11560.xy;
                        } else {
                            phi_35762_ = _e11560.zw;
                        }
                        let _e11566 = phi_35762_;
                        let _e11568 = unpack2x16float(_e11566.x);
                        let _e11575 = (_e11554 + _e11505);
                        let _e11580 = global_3.member[(_e11575 >> bitcast<u32>(1i))];
                        if ((_e11575 & 1i) == 0i) {
                            phi_35763_ = _e11580.xy;
                        } else {
                            phi_35763_ = _e11580.zw;
                        }
                        let _e11586 = phi_35763_;
                        let _e11588 = unpack2x16float(_e11586.x);
                        let _e11596 = vec3(_e11488.x);
                        local_5 = array<vec3<i32>, 6>(vec3<i32>(0i, 256i, 128i), vec3<i32>(32768i, 128i, 64i), vec3<i32>(40960i, 64i, 32i), vec3<i32>(43008i, 32i, 16i), vec3<i32>(43520i, 16i, 8i), vec3<i32>(43648i, 8i, 4i));
                        let _e11604 = local_5[(_e11478 + 1i)];
                        let _e11606 = (_e11464 + _e11604.x);
                        let _e11610 = ((_e11475 * vec2<f32>(_e11604.yz)) - vec2<f32>(0.5f, 0.5f));
                        let _e11611 = floor(_e11610);
                        let _e11612 = (_e11610 - _e11611);
                        let _e11614 = i32(_e11611.x);
                        let _e11616 = i32(_e11611.y);
                        phi_35764_ = _e11614;
                        if (_e11614 < 0i) {
                            phi_35764_ = (_e11614 + _e11604.y);
                        }
                        let _e11621 = phi_35764_;
                        phi_35765_ = _e11621;
                        if (_e11621 >= _e11604.y) {
                            phi_35765_ = (_e11621 - _e11604.y);
                        }
                        let _e11626 = phi_35765_;
                        let _e11627 = (_e11626 + 1i);
                        let _e11629 = select(_e11627, 0i, (_e11627 == _e11604.y));
                        let _e11636 = (_e11606 + (max(_e11616, 0i) * _e11604.y));
                        let _e11637 = (_e11636 + _e11626);
                        let _e11642 = global_3.member[(_e11637 >> bitcast<u32>(1i))];
                        if ((_e11637 & 1i) == 0i) {
                            phi_35771_ = _e11642.xy;
                        } else {
                            phi_35771_ = _e11642.zw;
                        }
                        let _e11648 = phi_35771_;
                        let _e11650 = unpack2x16float(_e11648.x);
                        let _e11657 = (_e11636 + _e11629);
                        let _e11662 = global_3.member[(_e11657 >> bitcast<u32>(1i))];
                        if ((_e11657 & 1i) == 0i) {
                            phi_35773_ = _e11662.xy;
                        } else {
                            phi_35773_ = _e11662.zw;
                        }
                        let _e11668 = phi_35773_;
                        let _e11670 = unpack2x16float(_e11668.x);
                        let _e11678 = (_e11606 + (min((_e11616 + 1i), (_e11604.z - 1i)) * _e11604.y));
                        let _e11679 = (_e11678 + _e11626);
                        let _e11684 = global_3.member[(_e11679 >> bitcast<u32>(1i))];
                        if ((_e11679 & 1i) == 0i) {
                            phi_35776_ = _e11684.xy;
                        } else {
                            phi_35776_ = _e11684.zw;
                        }
                        let _e11690 = phi_35776_;
                        let _e11692 = unpack2x16float(_e11690.x);
                        let _e11699 = (_e11678 + _e11629);
                        let _e11704 = global_3.member[(_e11699 >> bitcast<u32>(1i))];
                        if ((_e11699 & 1i) == 0i) {
                            phi_35777_ = _e11704.xy;
                        } else {
                            phi_35777_ = _e11704.zw;
                        }
                        let _e11710 = phi_35777_;
                        let _e11712 = unpack2x16float(_e11710.x);
                        let _e11720 = vec3(_e11612.x);
                        let _e11733 = (_e11413 * (1f - _e11356));
                        phi_37610_ = (_e11354 + ((mix(mix(mix(vec3<f32>(_e11526.x, _e11526.y, unpack2x16float(_e11524.y).x), vec3<f32>(_e11546.x, _e11546.y, unpack2x16float(_e11544.y).x), _e11596), mix(vec3<f32>(_e11568.x, _e11568.y, unpack2x16float(_e11566.y).x), vec3<f32>(_e11588.x, _e11588.y, unpack2x16float(_e11586.y).x), _e11596), vec3(_e11488.y)), mix(mix(vec3<f32>(_e11650.x, _e11650.y, unpack2x16float(_e11648.y).x), vec3<f32>(_e11670.x, _e11670.y, unpack2x16float(_e11668.y).x), _e11720), mix(vec3<f32>(_e11692.x, _e11692.y, unpack2x16float(_e11690.y).x), vec3<f32>(_e11712.x, _e11712.y, unpack2x16float(_e11710.y).x), _e11720), vec3(_e11612.y)), vec3((_e11476 - f32(_e11478)))) * _e11424.w) * _e11733));
                        phi_37609_ = (_e11356 + _e11733);
                        continue;
                    } else {
                        break;
                    }
                    continuing {
                        let _e11738 = phi_37610_;
                        let _e11740 = phi_37609_;
                        phi_35812_ = _e11738;
                        phi_35746_ = _e11740;
                        phi_35745_ = (_e11358 + 1i);
                    }
                }
                let _e11743 = local_98;
                let _e11747 = local_99;
                phi_35855_ = (_e11747 + (_e10062 * (1f - _e11743)));
            }
            let _e11750 = phi_35855_;
            if _e9852 {
                let _e11755 = textureSample(global_6, global_7, (((vec2<f32>(_e7453, _e9846) * 31f) + vec2<f32>(0.5f, 0.5f)) * vec2<f32>(0.03125f, 0.03125f)));
                phi_35856_ = _e11755.xy;
            } else {
                let _e11758 = ((vec4<f32>(-1f, -0.0275f, -0.572f, 0.022f) * _e9846) + vec4<f32>(1f, 0.0425f, 1.04f, -0.04f));
                phi_35856_ = ((vec2<f32>(-1.04f, 1.04f) * ((min((_e11758.x * _e11758.x), exp2((-9.28f * _e7453))) * _e11758.x) + _e11758.y)) + _e11758.zw);
            }
            let _e11771 = phi_35856_;
            let _e11776 = ((_e7457 * _e11771.x) + vec3(_e11771.y));
            let _e11785 = (_e9832 + ((_e11776 * _e11750) * _e1410));
            phi_37181_ = _e11785;
            phi_36598_ = (((_e1381 * (1f - _e3420)) * ((_e9834 * (vec3<f32>(1f, 1f, 1f) - _e7457)) + (((vec3<f32>(1f, 1f, 1f) - _e11776) * _e11347) * _e1410))) + _e11785);
        }
        let _e11789 = phi_37181_;
        let _e11791 = phi_36598_;
        phi_37172_ = _e11789;
        phi_36594_ = _e11791;
    }
    let _e11793 = phi_37172_;
    let _e11795 = phi_36594_;
    let _e11798 = global_8.member_1[1u];
    let _e11802 = global_8.member_5;
    let _e11804 = textureSample(global_28, global_5, _e427);
    let _e11807 = global_25;
    let _e11813 = -(length(_e957));
    let _e11816 = global.member_7[3u];
    let _e11822 = global.member_9[3u];
    phi_36785_ = (1f - exp((_e11813 * _e11816)));
    if (_e11822 != 0f) {
        let _e11826 = (_e11822 * (_e956 - _e955).y);
        if (abs(_e11826) < 0.0001f) {
            phi_36782_ = (1f - (0.5f * _e11826));
        } else {
            phi_36782_ = ((1f - exp(min(-(_e11826), 60f))) / _e11826);
        }
        let _e11837 = phi_36782_;
        let _e11841 = global.member_6[1u];
        let _e11844 = global.member_6[3u];
        phi_36785_ = (1f - exp(((_e11813 * (_e11816 * exp(min((-(_e11822) * (_e11841 - _e11844)), 30f)))) * _e11837)));
    }
    let _e11855 = phi_36785_;
    let _e11857 = global.member_7;
    let _e11863 = global.member_34[2u];
    phi_37167_ = mix((mix(_e11795, _e1381, vec3(_e11798)) + ((_e11802.xyz * _e11804.xyz) * (vec3<f32>(1f, 1f, 1f) + _e11807.yzw))), _e11857.xyz, vec3(_e11855));
    if (_e11863 > 0.5f) {
        let _e11867 = global.member_29[0u];
        if (_e11867 > 0.5f) {
            let _e11870 = global.member_29;
            let _e11877 = ((_e11870.z * _e948.x) - (_e11870.w * _e948.z));
            let _e11881 = ((_e11870.w * _e948.x) + (_e11870.z * _e948.z));
            let _e11885 = (1.092548f * _e11877);
            local_4 = array<f32, 9>(0.282095f, (0.488603f * _e948.y), (0.488603f * _e11881), (0.488603f * _e11877), (_e11885 * _e948.y), ((1.092548f * _e948.y) * _e11881), (0.315392f * (((3f * _e11881) * _e11881) - 1f)), (_e11885 * _e11881), (0.546274f * ((_e11877 * _e11877) - (_e948.y * _e948.y))));
            phi_36972_ = vec3<f32>(0f, 0f, 0f);
            phi_36971_ = 0i;
            loop {
                let _e11900 = phi_36972_;
                let _e11902 = phi_36971_;
                local_100 = _e11900;
                if (_e11902 < 9i) {
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e11906 = textureLoad(global_4, (vec2<i32>(496i, 256i) + vec2<i32>(_e11902, 0i)), 0i);
                    let _e11909 = local_4[_e11902];
                    phi_36972_ = (_e11900 + (_e11906.xyz * _e11909));
                    phi_36971_ = (_e11902 + 1i);
                }
            }
            let _e11914 = local_100;
            let _e11918 = global.member_29[1u];
            phi_36973_ = (max(_e11914, vec3<f32>(0f, 0f, 0f)) * _e11918);
        } else {
            let _e11921 = global.member_9;
            let _e11924 = global.member_8;
            let _e11933 = global.member_8[3u];
            phi_36973_ = (mix(_e11921.xyz, _e11924.xyz, vec3(((_e948.y * 0.5f) + 0.5f))) * _e11933);
        }
        let _e11936 = phi_36973_;
        let _e11939 = global.member_34[1u];
        phi_36978_ = _e11936;
        if (_e11939 > 0.5f) {
            let _e11944 = global.member_34[0u];
            phi_36977_ = _e11936;
            phi_36976_ = 0i;
            loop {
                let _e11947 = phi_36977_;
                let _e11949 = phi_36976_;
                local_130 = _e11947;
                if (_e11949 < i32(_e11939)) {
                    let _e11952 = (8i * (i32(_e11944) + _e11949));
                    let _e11956 = global_3.member[(_e11952 + 3i)];
                    let _e11957 = bitcast<vec4<f32>>(_e11956);
                    let _e11960 = global_3.member[_e11952];
                    let _e11961 = bitcast<vec4<f32>>(_e11960);
                    let _e11965 = global_3.member[(_e11952 + 1i)];
                    let _e11966 = bitcast<vec4<f32>>(_e11965);
                    let _e11970 = global_3.member[(_e11952 + 2i)];
                    let _e11971 = bitcast<vec4<f32>>(_e11970);
                    let _e11972 = _e11961.xyz;
                    let _e11976 = _e11966.xyz;
                    let _e11980 = _e11971.xyz;
                    let _e11984 = vec3<f32>((dot(_e11972, _e956) + _e11961.w), (dot(_e11976, _e956) + _e11966.w), (dot(_e11980, _e956) + _e11971.w));
                    let _e11985 = _e11957.xyz;
                    switch bitcast<i32>(0u) {
                        default: {
                            let _e11989 = (_e11985 - abs(_e11984));
                            let _e11994 = min(_e11989.x, min(_e11989.y, _e11989.z));
                            if (_e11994 <= 0f) {
                                phi_37431_ = 0f;
                                break;
                            }
                            if (_e11957.w <= 0f) {
                                phi_37431_ = 1f;
                                break;
                            }
                            let _e11998 = min((_e11994 / _e11957.w), 1f);
                            phi_37431_ = ((_e11998 * _e11998) * (3f - (2f * _e11998)));
                            break;
                        }
                    }
                    let _e12004 = phi_37431_;
                    if (_e12004 <= 0f) {
                        phi_37697_ = _e11947;
                        continue;
                    }
                    let _e12009 = global_3.member[(_e11952 + 4i)];
                    let _e12011 = bitcast<vec4<f32>>(_e12009).xyz;
                    let _e12015 = global_3.member[(_e11952 + 5i)];
                    let _e12016 = bitcast<vec4<f32>>(_e12015);
                    let _e12021 = global_3.member[(_e11952 + 6i)][0u];
                    let _e12022 = bitcast<i32>(_e12021);
                    let _e12023 = dot(_e11972, _e948);
                    let _e12024 = dot(_e11976, _e948);
                    let _e12025 = dot(_e11980, _e948);
                    let _e12026 = vec3<f32>(_e12023, _e12024, _e12025);
                    let _e12032 = ((_e956 + (_e948 * _e12016.x)) + (_e958 * _e12016.y));
                    let _e12047 = clamp(((((vec3<f32>((dot(_e11972, _e12032) + _e11961.w), (dot(_e11976, _e12032) + _e11966.w), (dot(_e11980, _e12032) + _e11971.w)) + _e11985) / max((_e11985 * 2f), vec3<f32>(0.000001f, 0.000001f, 0.000001f))) * _e12011) - vec3<f32>(0.5f, 0.5f, 0.5f)), vec3<f32>(0f, 0f, 0f), (_e12011 - vec3<f32>(1f, 1f, 1f)));
                    let _e12048 = vec3<i32>(_e12011);
                    let _e12052 = min(vec3<i32>(_e12047), max((_e12048 - vec3<i32>(2i, 2i, 2i)), vec3<i32>(0i, 0i, 0i)));
                    let _e12054 = (_e12047 - vec3<f32>(_e12052));
                    let _e12055 = (0.488603f * _e12024);
                    let _e12056 = (0.488603f * _e12025);
                    let _e12057 = (0.488603f * _e12023);
                    let _e12058 = (1.092548f * _e12023);
                    let _e12059 = (_e12058 * _e12024);
                    let _e12061 = ((1.092548f * _e12024) * _e12025);
                    let _e12065 = (0.315392f * (((3f * _e12025) * _e12025) - 1f));
                    let _e12066 = (_e12058 * _e12025);
                    let _e12070 = (0.546274f * ((_e12023 * _e12023) - (_e12024 * _e12024)));
                    let _e12071 = (_e12048 - vec3<i32>(1i, 1i, 1i));
                    let _e12072 = min(_e12052, _e12071);
                    let _e12083 = (_e12022 + ((_e12072.x + (_e12048.x * (_e12072.y + (_e12048.y * _e12072.z)))) * 4i));
                    let _e12084 = (vec3<f32>(1f, 1f, 1f) - _e12054);
                    let _e12091 = ((((((vec3<f32>(_e12072) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e12011) * _e11985) * 2f) - _e11985) - _e11984);
                    let _e12097 = (dot((_e12091 * inverseSqrt(max(dot(_e12091, _e12091), 0.0000000001f))), _e12026) + 1f);
                    let _e12100 = (_e12084.x * _e12084.y);
                    let _e12107 = (_e12083 + 3i);
                    let _e12111 = global_3.member[_e12107][1u];
                    let _e12116 = (((_e12100 * _e12084.z) * ((0.25f * (_e12097 * _e12097)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e12111).y > 0.5f)));
                    let _e12119 = global_3.member[_e12083];
                    let _e12123 = global_3.member[(_e12083 + 1i)];
                    let _e12127 = global_3.member[(_e12083 + 2i)];
                    let _e12130 = global_3.member[_e12107];
                    let _e12132 = unpack2x16float(_e12119.x);
                    let _e12134 = unpack2x16float(_e12119.y);
                    let _e12136 = unpack2x16float(_e12119.z);
                    let _e12138 = unpack2x16float(_e12119.w);
                    let _e12140 = unpack2x16float(_e12123.x);
                    let _e12142 = unpack2x16float(_e12123.y);
                    let _e12144 = unpack2x16float(_e12123.z);
                    let _e12146 = unpack2x16float(_e12123.w);
                    let _e12148 = unpack2x16float(_e12127.x);
                    let _e12150 = unpack2x16float(_e12127.y);
                    let _e12152 = unpack2x16float(_e12127.z);
                    let _e12154 = unpack2x16float(_e12127.w);
                    let _e12156 = unpack2x16float(_e12130.x);
                    let _e12212 = ((((((((((vec3<f32>(_e12132.x, _e12132.y, _e12134.x) * 0.282095f) + (vec3<f32>(_e12134.y, _e12136.x, _e12136.y) * _e12055)) + (vec3<f32>(_e12138.x, _e12138.y, _e12140.x) * _e12056)) + (vec3<f32>(_e12140.y, _e12142.x, _e12142.y) * _e12057)) + (vec3<f32>(_e12144.x, _e12144.y, _e12146.x) * _e12059)) + (vec3<f32>(_e12146.y, _e12148.x, _e12148.y) * _e12061)) + (vec3<f32>(_e12150.x, _e12150.y, _e12152.x) * _e12065)) + (vec3<f32>(_e12152.y, _e12154.x, _e12154.y) * _e12066)) + (vec3<f32>(_e12156.x, _e12156.y, unpack2x16float(_e12130.y).x) * _e12070)) * _e12116);
                    let _e12218 = min((_e12052 + vec3<i32>(1i, 0i, 0i)), _e12071);
                    let _e12227 = (_e12022 + ((_e12218.x + (_e12048.x * (_e12218.y + (_e12048.y * _e12218.z)))) * 4i));
                    let _e12234 = ((((((vec3<f32>(_e12218) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e12011) * _e11985) * 2f) - _e11985) - _e11984);
                    let _e12240 = (dot((_e12234 * inverseSqrt(max(dot(_e12234, _e12234), 0.0000000001f))), _e12026) + 1f);
                    let _e12242 = (_e12054.x * _e12084.y);
                    let _e12248 = (_e12227 + 3i);
                    let _e12252 = global_3.member[_e12248][1u];
                    let _e12257 = (((_e12242 * _e12084.z) * ((0.25f * (_e12240 * _e12240)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e12252).y > 0.5f)));
                    let _e12260 = global_3.member[_e12227];
                    let _e12264 = global_3.member[(_e12227 + 1i)];
                    let _e12268 = global_3.member[(_e12227 + 2i)];
                    let _e12271 = global_3.member[_e12248];
                    let _e12273 = unpack2x16float(_e12260.x);
                    let _e12275 = unpack2x16float(_e12260.y);
                    let _e12277 = unpack2x16float(_e12260.z);
                    let _e12279 = unpack2x16float(_e12260.w);
                    let _e12281 = unpack2x16float(_e12264.x);
                    let _e12283 = unpack2x16float(_e12264.y);
                    let _e12285 = unpack2x16float(_e12264.z);
                    let _e12287 = unpack2x16float(_e12264.w);
                    let _e12289 = unpack2x16float(_e12268.x);
                    let _e12291 = unpack2x16float(_e12268.y);
                    let _e12293 = unpack2x16float(_e12268.z);
                    let _e12295 = unpack2x16float(_e12268.w);
                    let _e12297 = unpack2x16float(_e12271.x);
                    let _e12353 = ((((((((((vec3<f32>(_e12273.x, _e12273.y, _e12275.x) * 0.282095f) + (vec3<f32>(_e12275.y, _e12277.x, _e12277.y) * _e12055)) + (vec3<f32>(_e12279.x, _e12279.y, _e12281.x) * _e12056)) + (vec3<f32>(_e12281.y, _e12283.x, _e12283.y) * _e12057)) + (vec3<f32>(_e12285.x, _e12285.y, _e12287.x) * _e12059)) + (vec3<f32>(_e12287.y, _e12289.x, _e12289.y) * _e12061)) + (vec3<f32>(_e12291.x, _e12291.y, _e12293.x) * _e12065)) + (vec3<f32>(_e12293.y, _e12295.x, _e12295.y) * _e12066)) + (vec3<f32>(_e12297.x, _e12297.y, unpack2x16float(_e12271.y).x) * _e12070)) * _e12257);
                    let _e12360 = min((_e12052 + vec3<i32>(0i, 1i, 0i)), _e12071);
                    let _e12369 = (_e12022 + ((_e12360.x + (_e12048.x * (_e12360.y + (_e12048.y * _e12360.z)))) * 4i));
                    let _e12376 = ((((((vec3<f32>(_e12360) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e12011) * _e11985) * 2f) - _e11985) - _e11984);
                    let _e12382 = (dot((_e12376 * inverseSqrt(max(dot(_e12376, _e12376), 0.0000000001f))), _e12026) + 1f);
                    let _e12384 = (_e12084.x * _e12054.y);
                    let _e12390 = (_e12369 + 3i);
                    let _e12394 = global_3.member[_e12390][1u];
                    let _e12399 = (((_e12384 * _e12084.z) * ((0.25f * (_e12382 * _e12382)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e12394).y > 0.5f)));
                    let _e12402 = global_3.member[_e12369];
                    let _e12406 = global_3.member[(_e12369 + 1i)];
                    let _e12410 = global_3.member[(_e12369 + 2i)];
                    let _e12413 = global_3.member[_e12390];
                    let _e12415 = unpack2x16float(_e12402.x);
                    let _e12417 = unpack2x16float(_e12402.y);
                    let _e12419 = unpack2x16float(_e12402.z);
                    let _e12421 = unpack2x16float(_e12402.w);
                    let _e12423 = unpack2x16float(_e12406.x);
                    let _e12425 = unpack2x16float(_e12406.y);
                    let _e12427 = unpack2x16float(_e12406.z);
                    let _e12429 = unpack2x16float(_e12406.w);
                    let _e12431 = unpack2x16float(_e12410.x);
                    let _e12433 = unpack2x16float(_e12410.y);
                    let _e12435 = unpack2x16float(_e12410.z);
                    let _e12437 = unpack2x16float(_e12410.w);
                    let _e12439 = unpack2x16float(_e12413.x);
                    let _e12495 = ((((((((((vec3<f32>(_e12415.x, _e12415.y, _e12417.x) * 0.282095f) + (vec3<f32>(_e12417.y, _e12419.x, _e12419.y) * _e12055)) + (vec3<f32>(_e12421.x, _e12421.y, _e12423.x) * _e12056)) + (vec3<f32>(_e12423.y, _e12425.x, _e12425.y) * _e12057)) + (vec3<f32>(_e12427.x, _e12427.y, _e12429.x) * _e12059)) + (vec3<f32>(_e12429.y, _e12431.x, _e12431.y) * _e12061)) + (vec3<f32>(_e12433.x, _e12433.y, _e12435.x) * _e12065)) + (vec3<f32>(_e12435.y, _e12437.x, _e12437.y) * _e12066)) + (vec3<f32>(_e12439.x, _e12439.y, unpack2x16float(_e12413.y).x) * _e12070)) * _e12399);
                    let _e12502 = min((_e12052 + vec3<i32>(1i, 1i, 0i)), _e12071);
                    let _e12511 = (_e12022 + ((_e12502.x + (_e12048.x * (_e12502.y + (_e12048.y * _e12502.z)))) * 4i));
                    let _e12518 = ((((((vec3<f32>(_e12502) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e12011) * _e11985) * 2f) - _e11985) - _e11984);
                    let _e12524 = (dot((_e12518 * inverseSqrt(max(dot(_e12518, _e12518), 0.0000000001f))), _e12026) + 1f);
                    let _e12525 = (_e12054.x * _e12054.y);
                    let _e12531 = (_e12511 + 3i);
                    let _e12535 = global_3.member[_e12531][1u];
                    let _e12540 = (((_e12525 * _e12084.z) * ((0.25f * (_e12524 * _e12524)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e12535).y > 0.5f)));
                    let _e12543 = global_3.member[_e12511];
                    let _e12547 = global_3.member[(_e12511 + 1i)];
                    let _e12551 = global_3.member[(_e12511 + 2i)];
                    let _e12554 = global_3.member[_e12531];
                    let _e12556 = unpack2x16float(_e12543.x);
                    let _e12558 = unpack2x16float(_e12543.y);
                    let _e12560 = unpack2x16float(_e12543.z);
                    let _e12562 = unpack2x16float(_e12543.w);
                    let _e12564 = unpack2x16float(_e12547.x);
                    let _e12566 = unpack2x16float(_e12547.y);
                    let _e12568 = unpack2x16float(_e12547.z);
                    let _e12570 = unpack2x16float(_e12547.w);
                    let _e12572 = unpack2x16float(_e12551.x);
                    let _e12574 = unpack2x16float(_e12551.y);
                    let _e12576 = unpack2x16float(_e12551.z);
                    let _e12578 = unpack2x16float(_e12551.w);
                    let _e12580 = unpack2x16float(_e12554.x);
                    let _e12636 = ((((((((((vec3<f32>(_e12556.x, _e12556.y, _e12558.x) * 0.282095f) + (vec3<f32>(_e12558.y, _e12560.x, _e12560.y) * _e12055)) + (vec3<f32>(_e12562.x, _e12562.y, _e12564.x) * _e12056)) + (vec3<f32>(_e12564.y, _e12566.x, _e12566.y) * _e12057)) + (vec3<f32>(_e12568.x, _e12568.y, _e12570.x) * _e12059)) + (vec3<f32>(_e12570.y, _e12572.x, _e12572.y) * _e12061)) + (vec3<f32>(_e12574.x, _e12574.y, _e12576.x) * _e12065)) + (vec3<f32>(_e12576.y, _e12578.x, _e12578.y) * _e12066)) + (vec3<f32>(_e12580.x, _e12580.y, unpack2x16float(_e12554.y).x) * _e12070)) * _e12540);
                    let _e12643 = min((_e12052 + vec3<i32>(0i, 0i, 1i)), _e12071);
                    let _e12652 = (_e12022 + ((_e12643.x + (_e12048.x * (_e12643.y + (_e12048.y * _e12643.z)))) * 4i));
                    let _e12659 = ((((((vec3<f32>(_e12643) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e12011) * _e11985) * 2f) - _e11985) - _e11984);
                    let _e12665 = (dot((_e12659 * inverseSqrt(max(dot(_e12659, _e12659), 0.0000000001f))), _e12026) + 1f);
                    let _e12672 = (_e12652 + 3i);
                    let _e12676 = global_3.member[_e12672][1u];
                    let _e12681 = (((_e12100 * _e12054.z) * ((0.25f * (_e12665 * _e12665)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e12676).y > 0.5f)));
                    let _e12684 = global_3.member[_e12652];
                    let _e12688 = global_3.member[(_e12652 + 1i)];
                    let _e12692 = global_3.member[(_e12652 + 2i)];
                    let _e12695 = global_3.member[_e12672];
                    let _e12697 = unpack2x16float(_e12684.x);
                    let _e12699 = unpack2x16float(_e12684.y);
                    let _e12701 = unpack2x16float(_e12684.z);
                    let _e12703 = unpack2x16float(_e12684.w);
                    let _e12705 = unpack2x16float(_e12688.x);
                    let _e12707 = unpack2x16float(_e12688.y);
                    let _e12709 = unpack2x16float(_e12688.z);
                    let _e12711 = unpack2x16float(_e12688.w);
                    let _e12713 = unpack2x16float(_e12692.x);
                    let _e12715 = unpack2x16float(_e12692.y);
                    let _e12717 = unpack2x16float(_e12692.z);
                    let _e12719 = unpack2x16float(_e12692.w);
                    let _e12721 = unpack2x16float(_e12695.x);
                    let _e12777 = ((((((((((vec3<f32>(_e12697.x, _e12697.y, _e12699.x) * 0.282095f) + (vec3<f32>(_e12699.y, _e12701.x, _e12701.y) * _e12055)) + (vec3<f32>(_e12703.x, _e12703.y, _e12705.x) * _e12056)) + (vec3<f32>(_e12705.y, _e12707.x, _e12707.y) * _e12057)) + (vec3<f32>(_e12709.x, _e12709.y, _e12711.x) * _e12059)) + (vec3<f32>(_e12711.y, _e12713.x, _e12713.y) * _e12061)) + (vec3<f32>(_e12715.x, _e12715.y, _e12717.x) * _e12065)) + (vec3<f32>(_e12717.y, _e12719.x, _e12719.y) * _e12066)) + (vec3<f32>(_e12721.x, _e12721.y, unpack2x16float(_e12695.y).x) * _e12070)) * _e12681);
                    let _e12784 = min((_e12052 + vec3<i32>(1i, 0i, 1i)), _e12071);
                    let _e12793 = (_e12022 + ((_e12784.x + (_e12048.x * (_e12784.y + (_e12048.y * _e12784.z)))) * 4i));
                    let _e12800 = ((((((vec3<f32>(_e12784) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e12011) * _e11985) * 2f) - _e11985) - _e11984);
                    let _e12806 = (dot((_e12800 * inverseSqrt(max(dot(_e12800, _e12800), 0.0000000001f))), _e12026) + 1f);
                    let _e12812 = (_e12793 + 3i);
                    let _e12816 = global_3.member[_e12812][1u];
                    let _e12821 = (((_e12242 * _e12054.z) * ((0.25f * (_e12806 * _e12806)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e12816).y > 0.5f)));
                    let _e12824 = global_3.member[_e12793];
                    let _e12828 = global_3.member[(_e12793 + 1i)];
                    let _e12832 = global_3.member[(_e12793 + 2i)];
                    let _e12835 = global_3.member[_e12812];
                    let _e12837 = unpack2x16float(_e12824.x);
                    let _e12839 = unpack2x16float(_e12824.y);
                    let _e12841 = unpack2x16float(_e12824.z);
                    let _e12843 = unpack2x16float(_e12824.w);
                    let _e12845 = unpack2x16float(_e12828.x);
                    let _e12847 = unpack2x16float(_e12828.y);
                    let _e12849 = unpack2x16float(_e12828.z);
                    let _e12851 = unpack2x16float(_e12828.w);
                    let _e12853 = unpack2x16float(_e12832.x);
                    let _e12855 = unpack2x16float(_e12832.y);
                    let _e12857 = unpack2x16float(_e12832.z);
                    let _e12859 = unpack2x16float(_e12832.w);
                    let _e12861 = unpack2x16float(_e12835.x);
                    let _e12917 = ((((((((((vec3<f32>(_e12837.x, _e12837.y, _e12839.x) * 0.282095f) + (vec3<f32>(_e12839.y, _e12841.x, _e12841.y) * _e12055)) + (vec3<f32>(_e12843.x, _e12843.y, _e12845.x) * _e12056)) + (vec3<f32>(_e12845.y, _e12847.x, _e12847.y) * _e12057)) + (vec3<f32>(_e12849.x, _e12849.y, _e12851.x) * _e12059)) + (vec3<f32>(_e12851.y, _e12853.x, _e12853.y) * _e12061)) + (vec3<f32>(_e12855.x, _e12855.y, _e12857.x) * _e12065)) + (vec3<f32>(_e12857.y, _e12859.x, _e12859.y) * _e12066)) + (vec3<f32>(_e12861.x, _e12861.y, unpack2x16float(_e12835.y).x) * _e12070)) * _e12821);
                    let _e12924 = min((_e12052 + vec3<i32>(0i, 1i, 1i)), _e12071);
                    let _e12933 = (_e12022 + ((_e12924.x + (_e12048.x * (_e12924.y + (_e12048.y * _e12924.z)))) * 4i));
                    let _e12940 = ((((((vec3<f32>(_e12924) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e12011) * _e11985) * 2f) - _e11985) - _e11984);
                    let _e12946 = (dot((_e12940 * inverseSqrt(max(dot(_e12940, _e12940), 0.0000000001f))), _e12026) + 1f);
                    let _e12952 = (_e12933 + 3i);
                    let _e12956 = global_3.member[_e12952][1u];
                    let _e12961 = (((_e12384 * _e12054.z) * ((0.25f * (_e12946 * _e12946)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e12956).y > 0.5f)));
                    let _e12964 = global_3.member[_e12933];
                    let _e12968 = global_3.member[(_e12933 + 1i)];
                    let _e12972 = global_3.member[(_e12933 + 2i)];
                    let _e12975 = global_3.member[_e12952];
                    let _e12977 = unpack2x16float(_e12964.x);
                    let _e12979 = unpack2x16float(_e12964.y);
                    let _e12981 = unpack2x16float(_e12964.z);
                    let _e12983 = unpack2x16float(_e12964.w);
                    let _e12985 = unpack2x16float(_e12968.x);
                    let _e12987 = unpack2x16float(_e12968.y);
                    let _e12989 = unpack2x16float(_e12968.z);
                    let _e12991 = unpack2x16float(_e12968.w);
                    let _e12993 = unpack2x16float(_e12972.x);
                    let _e12995 = unpack2x16float(_e12972.y);
                    let _e12997 = unpack2x16float(_e12972.z);
                    let _e12999 = unpack2x16float(_e12972.w);
                    let _e13001 = unpack2x16float(_e12975.x);
                    let _e13057 = ((((((((((vec3<f32>(_e12977.x, _e12977.y, _e12979.x) * 0.282095f) + (vec3<f32>(_e12979.y, _e12981.x, _e12981.y) * _e12055)) + (vec3<f32>(_e12983.x, _e12983.y, _e12985.x) * _e12056)) + (vec3<f32>(_e12985.y, _e12987.x, _e12987.y) * _e12057)) + (vec3<f32>(_e12989.x, _e12989.y, _e12991.x) * _e12059)) + (vec3<f32>(_e12991.y, _e12993.x, _e12993.y) * _e12061)) + (vec3<f32>(_e12995.x, _e12995.y, _e12997.x) * _e12065)) + (vec3<f32>(_e12997.y, _e12999.x, _e12999.y) * _e12066)) + (vec3<f32>(_e13001.x, _e13001.y, unpack2x16float(_e12975.y).x) * _e12070)) * _e12961);
                    let _e13064 = min((_e12052 + vec3<i32>(1i, 1i, 1i)), _e12071);
                    let _e13073 = (_e12022 + ((_e13064.x + (_e12048.x * (_e13064.y + (_e12048.y * _e13064.z)))) * 4i));
                    let _e13080 = ((((((vec3<f32>(_e13064) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e12011) * _e11985) * 2f) - _e11985) - _e11984);
                    let _e13086 = (dot((_e13080 * inverseSqrt(max(dot(_e13080, _e13080), 0.0000000001f))), _e12026) + 1f);
                    let _e13092 = (_e13073 + 3i);
                    let _e13096 = global_3.member[_e13092][1u];
                    let _e13101 = (((_e12525 * _e12054.z) * ((0.25f * (_e13086 * _e13086)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e13096).y > 0.5f)));
                    let _e13104 = global_3.member[_e13073];
                    let _e13108 = global_3.member[(_e13073 + 1i)];
                    let _e13112 = global_3.member[(_e13073 + 2i)];
                    let _e13115 = global_3.member[_e13092];
                    let _e13117 = unpack2x16float(_e13104.x);
                    let _e13119 = unpack2x16float(_e13104.y);
                    let _e13121 = unpack2x16float(_e13104.z);
                    let _e13123 = unpack2x16float(_e13104.w);
                    let _e13125 = unpack2x16float(_e13108.x);
                    let _e13127 = unpack2x16float(_e13108.y);
                    let _e13129 = unpack2x16float(_e13108.z);
                    let _e13131 = unpack2x16float(_e13108.w);
                    let _e13133 = unpack2x16float(_e13112.x);
                    let _e13135 = unpack2x16float(_e13112.y);
                    let _e13137 = unpack2x16float(_e13112.z);
                    let _e13139 = unpack2x16float(_e13112.w);
                    let _e13141 = unpack2x16float(_e13115.x);
                    let _e13197 = ((((((((((vec3<f32>(_e13117.x, _e13117.y, _e13119.x) * 0.282095f) + (vec3<f32>(_e13119.y, _e13121.x, _e13121.y) * _e12055)) + (vec3<f32>(_e13123.x, _e13123.y, _e13125.x) * _e12056)) + (vec3<f32>(_e13125.y, _e13127.x, _e13127.y) * _e12057)) + (vec3<f32>(_e13129.x, _e13129.y, _e13131.x) * _e12059)) + (vec3<f32>(_e13131.y, _e13133.x, _e13133.y) * _e12061)) + (vec3<f32>(_e13135.x, _e13135.y, _e13137.x) * _e12065)) + (vec3<f32>(_e13137.y, _e13139.x, _e13139.y) * _e12066)) + (vec3<f32>(_e13141.x, _e13141.y, unpack2x16float(_e13115.y).x) * _e12070)) * _e13101);
                    let _e13202 = (((((((vec4<f32>(_e12212.x, _e12212.y, _e12212.z, _e12116) + vec4<f32>(_e12353.x, _e12353.y, _e12353.z, _e12257)) + vec4<f32>(_e12495.x, _e12495.y, _e12495.z, _e12399)) + vec4<f32>(_e12636.x, _e12636.y, _e12636.z, _e12540)) + vec4<f32>(_e12777.x, _e12777.y, _e12777.z, _e12681)) + vec4<f32>(_e12917.x, _e12917.y, _e12917.z, _e12821)) + vec4<f32>(_e13057.x, _e13057.y, _e13057.z, _e12961)) + vec4<f32>(_e13197.x, _e13197.y, _e13197.z, _e13101));
                    phi_37698_ = _e11947;
                    if (_e13202.w > 0.00001f) {
                        phi_37698_ = mix(_e11947, ((max(_e13202.xyz, vec3<f32>(0f, 0f, 0f)) / vec3(_e13202.w)) * _e12016.z), vec3(_e12004));
                    }
                    let _e13214 = phi_37698_;
                    phi_37697_ = _e13214;
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e13216 = phi_37697_;
                    phi_36977_ = _e13216;
                    phi_36976_ = (_e11949 + 1i);
                }
            }
            let _e13673 = local_130;
            phi_36978_ = _e13673;
        }
        let _e13219 = phi_36978_;
        phi_37167_ = (_e13219 * _e1410);
    }
    let _e13222 = phi_37167_;
    let _e13225 = global.member_33[3u];
    phi_37196_ = _e13222;
    if (_e13225 > 0.5f) {
        phi_37196_ = (_e13222 / (vec3<f32>(1f, 1f, 1f) + _e13222));
    }
    let _e13230 = phi_37196_;
    let _e13233 = global_19.member_1[3u];
    let _e13234 = (_e13233 > 0.5f);
    phi_6398_ = _e13234;
    if _e13234 {
        phi_6398_ = (_e13225 < 0.5f);
    }
    let _e13237 = phi_6398_;
    phi_37197_ = ((_e438 * _e441) * _e428.w);
    if _e13237 {
        phi_37197_ = (-1f - max(dot((_e11793 * (1f - _e11855)), vec3<f32>(0.2126f, 0.7152f, 0.0722f)), 0f));
    }
    let _e13244 = phi_37197_;
    global_29 = vec4<f32>(_e13230.x, _e13230.y, _e13230.z, _e13244);
    let _e13249 = global_31;
    let _e13250 = global_32;
    switch bitcast<i32>(0u) {
        default: {
            if (_e13250.w <= 0f) {
                phi_37430_ = vec2<f32>(0f, 0f);
                break;
            }
            phi_37430_ = (((_e13250.xy / vec2(_e13250.w)) - (_e13249.xy / vec2(_e13249.w))) * vec2<f32>(0.5f, -0.5f));
            break;
        }
    }
    let _e13264 = phi_37430_;
    global_30 = _e13264;
    return;
}

@fragment 
fn main(@location(1) param: vec3<f32>, @location(8) param_1: vec4<f32>, @location(4) param_2: vec3<f32>, @location(0) param_3: vec3<f32>, @builtin(position) param_4: vec4<f32>, @builtin(front_facing) param_5: bool, @location(2) param_6: vec2<f32>, @location(3) param_7: vec4<f32>, @location(5) param_8: vec4<f32>, @location(6) param_9: vec4<f32>, @location(7) param_10: vec4<f32>) -> FragmentOutput {
    global_9 = param;
    global_10 = param_1;
    global_11 = param_2;
    global_13 = param_3;
    global_16 = param_4;
    global_20 = param_5;
    global_21 = param_6;
    global_23 = param_7;
    global_25 = param_8;
    global_31 = param_9;
    global_32 = param_10;
    function_();
    let _e24 = global_29;
    let _e25 = global_30;
    return FragmentOutput(_e24, _e25);
}
