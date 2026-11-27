// Generated from mesh_skin.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: d433a392a9e432dd
// glsl-fnv1a64: 5f2e617ff78cfba5

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
    member_30: mat4x4<f32>,
    member_31: vec4<f32>,
    member_32: vec4<f32>,
    member_33: vec4<f32>,
    member_34: vec4<f32>,
}

struct type_38 {
    member: vec4<f32>,
    member_1: vec4<f32>,
    member_2: vec4<f32>,
    member_3: vec4<f32>,
    member_4: vec4<f32>,
    member_5: vec4<f32>,
    member_6: vec4<f32>,
}

struct type_43 {
    member: array<vec4<f32>, 1024>,
}

struct type_47 {
    member: array<vec4<u32>, 1024>,
}

struct FragmentOutput {
    @location(0) member: vec4<f32>,
    @location(1) member_1: vec2<f32>,
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
@group(2) @binding(2) 
var<uniform> global_7: type_38;
var<private> global_8: vec3<f32>;
var<private> global_9: vec4<f32>;
var<private> global_10: vec3<f32>;
@group(2) @binding(3) 
var<uniform> global_11: type_43;
var<private> global_12: vec3<f32>;
@group(2) @binding(4) 
var<uniform> global_13: type_43;
@group(2) @binding(5) 
var<uniform> global_14: type_43;
var<private> global_15: vec4<f32>;
@group(2) @binding(6) 
var<uniform> global_16: type_47;
@group(2) @binding(7) 
var<uniform> global_17: type_47;
@group(3) @binding(0) 
var<uniform> global_18: type_38;
var<private> global_19: bool;
var<private> global_20: vec2<f32>;
@group(2) @binding(9) 
var global_21: texture_2d<f32>;
var<private> global_22: vec4<f32>;
@group(2) @binding(11) 
var global_23: texture_2d<f32>;
var<private> global_24: vec4<f32>;
@group(2) @binding(12) 
var global_25: texture_2d<f32>;
@group(2) @binding(10) 
var global_26: texture_2d<f32>;
@group(2) @binding(13) 
var global_27: texture_2d<f32>;
var<private> global_28: vec4<f32>;
var<private> global_29: vec2<f32>;
var<private> global_30: vec4<f32>;
var<private> global_31: vec4<f32>;

fn function_() {
    var local: array<vec3<f32>, 2>;
    var local_1: array<vec3<f32>, 2>;
    var local_2: array<vec3<f32>, 2>;
    var local_3: array<vec3<f32>, 2>;
    var local_4: array<vec4<i32>, 6>;
    var local_5: array<vec4<i32>, 6>;
    var local_6: array<f32, 9>;
    var local_7: array<vec2<f32>, 3>;
    var local_8: array<vec2<f32>, 3>;
    var local_9: array<vec2<f32>, 3>;
    var local_10: array<vec2<f32>, 3>;
    var local_11: array<vec3<f32>, 6>;
    var local_12: array<vec3<f32>, 6>;
    var local_13: array<vec2<f32>, 3>;
    var local_14: array<vec2<f32>, 3>;
    var local_15: array<vec2<f32>, 3>;
    var local_16: array<vec2<f32>, 3>;
    var local_17: array<vec3<f32>, 6>;
    var local_18: array<vec3<f32>, 6>;
    var local_19: array<f32, 4>;
    var local_20: array<f32, 4>;
    var local_21: array<vec2<f32>, 3>;
    var local_22: array<vec2<f32>, 3>;
    var local_23: array<vec2<f32>, 3>;
    var local_24: array<vec2<f32>, 3>;
    var local_25: array<vec3<f32>, 6>;
    var local_26: array<vec3<f32>, 6>;
    var local_27: array<vec2<f32>, 3>;
    var local_28: array<vec2<f32>, 3>;
    var local_29: array<vec2<f32>, 3>;
    var local_30: array<vec2<f32>, 3>;
    var local_31: array<f32, 4>;
    var local_32: array<f32, 4>;
    var local_33: array<f32, 9>;
    var local_34: array<vec2<f32>, 3>;
    var local_35: array<vec2<f32>, 3>;
    var local_36: array<vec2<f32>, 3>;
    var local_37: array<vec2<f32>, 3>;
    var local_38: array<vec3<f32>, 6>;
    var local_39: array<vec3<f32>, 6>;
    var local_40: array<f32, 9>;
    var local_41: array<vec2<f32>, 3>;
    var local_42: array<vec2<f32>, 3>;
    var local_43: array<vec2<f32>, 3>;
    var local_44: array<vec2<f32>, 3>;
    var local_45: array<vec3<f32>, 4>;
    var local_46: array<vec3<f32>, 4>;
    var phi_18581_: vec3<f32>;
    var phi_18579_: f32;
    var local_47: vec3<f32>;
    var phi_18742_: vec2<f32>;
    var phi_18709_: f32;
    var phi_18678_: vec3<f32>;
    var phi_18582_: vec2<f32>;
    var phi_18583_: vec3<f32>;
    var phi_18592_: vec3<f32>;
    var phi_18591_: vec3<f32>;
    var phi_18588_: f32;
    var phi_4559_: bool;
    var phi_18776_: vec3<f32>;
    var phi_18593_: i32;
    var phi_5910_: bool;
    var local_48: i32;
    var local_49: i32;
    var local_50: i32;
    var phi_6023_: bool;
    var phi_6030_: bool;
    var phi_6037_: bool;
    var local_51: i32;
    var local_52: i32;
    var local_53: i32;
    var phi_18598_: f32;
    var phi_18595_: i32;
    var phi_18604_: f32;
    var phi_18601_: i32;
    var local_54: f32;
    var phi_18605_: f32;
    var phi_18606_: f32;
    var local_55: i32;
    var local_56: i32;
    var local_57: i32;
    var phi_6310_: bool;
    var phi_6317_: bool;
    var phi_6324_: bool;
    var phi_18618_: f32;
    var phi_18615_: i32;
    var phi_18624_: f32;
    var phi_18621_: i32;
    var local_58: f32;
    var phi_18625_: f32;
    var phi_18626_: f32;
    var phi_18647_: f32;
    var phi_18644_: vec3<f32>;
    var phi_18646_: f32;
    var phi_18643_: vec3<f32>;
    var phi_18649_: vec3<f32>;
    var phi_18648_: f32;
    var phi_18802_: f32;
    var phi_18771_: vec3<f32>;
    var phi_18701_: f32;
    var phi_18804_: f32;
    var phi_19395_: vec3<f32>;
    var phi_19394_: i32;
    var local_59: vec3<f32>;
    var phi_19396_: vec3<f32>;
    var phi_19406_: vec3<f32>;
    var phi_19403_: u32;
    var phi_6965_: bool;
    var phi_6972_: bool;
    var phi_6979_: bool;
    var phi_6986_: bool;
    var phi_19747_: f32;
    var phi_19744_: i32;
    var phi_19753_: f32;
    var phi_19750_: i32;
    var local_60: f32;
    var phi_19754_: f32;
    var phi_7056_: bool;
    var phi_19732_: i32;
    var phi_19731_: i32;
    var phi_19729_: f32;
    var phi_19736_: f32;
    var phi_19733_: i32;
    var phi_19742_: f32;
    var phi_19739_: i32;
    var local_61: f32;
    var phi_19743_: f32;
    var phi_19755_: f32;
    var phi_19809_: vec3<f32>;
    var phi_19405_: vec3<f32>;
    var phi_18806_: f32;
    var phi_18805_: f32;
    var phi_19296_: vec2<f32>;
    var phi_19297_: vec3<f32>;
    var phi_19298_: vec3<f32>;
    var phi_19299_: vec3<f32>;
    var phi_19303_: vec3<f32>;
    var phi_19302_: vec3<f32>;
    var phi_19301_: vec3<f32>;
    var local_62: vec3<f32>;
    var phi_7805_: bool;
    var local_63: vec3<f32>;
    var local_64: vec3<f32>;
    var local_65: vec3<f32>;
    var phi_19307_: vec2<f32>;
    var phi_19314_: f32;
    var phi_19312_: f32;
    var phi_19308_: vec3<f32>;
    var phi_19317_: vec3<f32>;
    var phi_19316_: i32;
    var local_66: vec3<f32>;
    var phi_19318_: i32;
    var phi_19319_: i32;
    var phi_19325_: i32;
    var phi_19326_: i32;
    var phi_19339_: vec3<f32>;
    var phi_19332_: vec3<f32>;
    var phi_19366_: vec3<f32>;
    var phi_19352_: vec3<f32>;
    var phi_19348_: u32;
    var phi_19365_: vec3<f32>;
    var phi_19351_: vec3<f32>;
    var phi_19349_: vec2<f32>;
    var phi_18807_: vec3<f32>;
    var phi_11690_: bool;
    var phi_18808_: f32;
    var phi_18809_: f32;
    var phi_18810_: i32;
    var phi_18816_: vec3<f32>;
    var phi_18818_: vec3<f32>;
    var phi_18820_: vec3<f32>;
    var phi_18822_: vec3<f32>;
    var phi_18821_: i32;
    var local_67: vec3<f32>;
    var phi_18823_: vec3<f32>;
    var phi_18829_: f32;
    var phi_18830_: vec3<f32>;
    var phi_11819_: bool;
    var phi_11825_: bool;
    var phi_18835_: i32;
    var phi_13512_: bool;
    var local_68: i32;
    var local_69: i32;
    var local_70: i32;
    var phi_13699_: bool;
    var phi_13706_: bool;
    var phi_13713_: bool;
    var local_71: i32;
    var local_72: i32;
    var local_73: i32;
    var phi_18840_: f32;
    var phi_18837_: i32;
    var phi_18846_: f32;
    var phi_18843_: i32;
    var local_74: f32;
    var phi_18847_: f32;
    var phi_18848_: f32;
    var phi_18851_: vec3<f32>;
    var phi_18850_: vec3<f32>;
    var phi_18849_: i32;
    var local_75: mat4x4<f32>;
    var phi_14031_: bool;
    var phi_14038_: bool;
    var phi_14045_: bool;
    var local_76: i32;
    var local_77: i32;
    var local_78: i32;
    var phi_18864_: f32;
    var phi_18861_: i32;
    var phi_18870_: f32;
    var phi_18867_: i32;
    var local_79: f32;
    var phi_18871_: f32;
    var phi_18872_: f32;
    var phi_18889_: vec3<f32>;
    var phi_18890_: vec3<f32>;
    var phi_18980_: vec3<f32>;
    var phi_19016_: vec3<f32>;
    var phi_18981_: vec3<f32>;
    var phi_18916_: u32;
    var phi_14585_: bool;
    var phi_14592_: bool;
    var phi_14599_: bool;
    var phi_14606_: bool;
    var phi_19035_: f32;
    var phi_19032_: i32;
    var phi_19041_: f32;
    var phi_19038_: i32;
    var local_80: f32;
    var phi_19042_: f32;
    var phi_14676_: bool;
    var phi_19020_: i32;
    var phi_19019_: i32;
    var phi_19017_: f32;
    var phi_19024_: f32;
    var phi_19021_: i32;
    var phi_19030_: f32;
    var phi_19027_: i32;
    var local_81: f32;
    var phi_19031_: f32;
    var phi_19043_: f32;
    var phi_19044_: f32;
    var phi_19046_: vec3<f32>;
    var phi_19045_: i32;
    var local_82: vec3<f32>;
    var phi_19047_: vec3<f32>;
    var phi_19086_: f32;
    var phi_19087_: vec3<f32>;
    var phi_11938_: bool;
    var phi_15746_: bool;
    var phi_15753_: bool;
    var phi_15760_: bool;
    var phi_15767_: bool;
    var phi_19127_: f32;
    var phi_19124_: i32;
    var phi_19133_: f32;
    var phi_19130_: i32;
    var local_83: f32;
    var phi_19134_: f32;
    var phi_15837_: bool;
    var phi_19112_: i32;
    var phi_19111_: i32;
    var phi_19109_: f32;
    var phi_19116_: f32;
    var phi_19113_: i32;
    var phi_19122_: f32;
    var phi_19119_: i32;
    var local_84: f32;
    var phi_19123_: f32;
    var phi_19135_: f32;
    var phi_19138_: vec3<f32>;
    var phi_19137_: vec3<f32>;
    var phi_19136_: i32;
    var local_85: bool;
    var phi_16503_: bool;
    var phi_16510_: bool;
    var phi_16517_: bool;
    var phi_16524_: bool;
    var phi_19157_: f32;
    var phi_19154_: i32;
    var phi_19163_: f32;
    var phi_19160_: i32;
    var local_86: f32;
    var phi_19164_: f32;
    var local_87: u32;
    var phi_16594_: bool;
    var phi_19142_: i32;
    var phi_19141_: i32;
    var phi_19139_: f32;
    var phi_19146_: f32;
    var phi_19143_: i32;
    var phi_19152_: f32;
    var phi_19149_: i32;
    var local_88: f32;
    var phi_19153_: f32;
    var phi_19165_: f32;
    var phi_19198_: vec3<f32>;
    var phi_19199_: vec3<f32>;
    var phi_19895_: vec3<f32>;
    var phi_18991_: vec3<f32>;
    var phi_18979_: vec3<f32>;
    var phi_18946_: vec3<f32>;
    var phi_18945_: i32;
    var local_89: vec3<f32>;
    var phi_18947_: i32;
    var phi_18948_: i32;
    var phi_18954_: i32;
    var phi_18955_: i32;
    var phi_18968_: vec3<f32>;
    var phi_18961_: vec3<f32>;
    var phi_18969_: vec2<f32>;
    var phi_19549_: vec3<f32>;
    var phi_19407_: vec3<f32>;
    var phi_19544_: vec3<f32>;
    var phi_19404_: vec3<f32>;
    var phi_19537_: f32;
    var phi_19540_: f32;
    var phi_19555_: vec3<f32>;
    var phi_5004_: bool;
    var phi_19556_: f32;
    var phi_19728_: vec2<f32>;
    var local_90: vec2<f32>;
    var local_91: f32;
    var local_92: f32;
    var local_93: vec3<f32>;
    var local_94: f32;
    var local_95: f32;
    var local_96: vec3<f32>;
    var local_97: vec3<f32>;
    var local_98: vec3<f32>;
    var local_99: f32;
    var local_100: vec3<f32>;
    var local_101: vec3<f32>;
    var local_102: f32;
    var local_103: vec3<f32>;
    var local_104: vec3<f32>;
    var local_105: vec3<f32>;
    var local_106: f32;
    var local_107: f32;
    var local_108: f32;
    var local_109: f32;
    var local_110: vec3<f32>;
    var local_111: vec3<f32>;
    var local_112: f32;
    var local_113: f32;
    var local_114: vec3<f32>;
    var local_115: vec3<f32>;
    var local_116: vec3<f32>;

    let _e376 = global_7.member_2;
    let _e378 = global_20;
    let _e382 = global_7.member_2[2u];
    let _e385 = global_7.member_3;
    let _e390 = global_7.member_3[2u];
    let _e392 = vec2<f32>((dot(_e376.xy, _e378) + _e382), (dot(_e385.xy, _e378) + _e390));
    let _e393 = textureSample(global_21, global_4, _e392);
    let _e394 = global_22;
    let _e395 = _e394.xyz;
    let _e397 = global_7.member;
    let _e400 = _e393.xyz;
    let _e401 = ((_e395 * _e397.xyz) * _e400);
    let _e403 = global_22[3u];
    let _e406 = global_7.member[3u];
    let _e412 = global_7.member_1[0u];
    phi_18581_ = _e401;
    if (_e412 > 0.5f) {
        let _e414 = global_12;
        let _e417 = floor((_e414.xz * vec2<f32>(0.5f, 0.5f)));
        let _e421 = abs((_e417.x + _e417.y));
        phi_18581_ = (_e401 * select(0.75f, 1f, ((_e421 - (floor((_e421 / 2f)) * 2f)) < 0.5f)));
    }
    let _e430 = phi_18581_;
    let _e433 = global_7.member_3[3u];
    phi_18742_ = vec2<f32>(0f, 0f);
    phi_18709_ = 0f;
    phi_18678_ = _e430;
    if (_e433 > 0.5f) {
        switch bitcast<i32>(0u) {
            default: {
                let _e438 = global_7.member_2[3u];
                let _e440 = vec4<f32>(_e438, _e433, 0f, 0f).xyy;
                let _e442 = floor((_e440 * vec3<f32>(0.000015258789f, 0.000015258789f, 0.000015258789f)));
                let _e444 = (_e440 - (_e442 * 65536f));
                let _e446 = floor((_e444 * vec3<f32>(0.00390625f, 0.00390625f, 0.00390625f)));
                let _e448 = (_e444 - (_e446 * 256f));
                let _e460 = (_e442.y - 128f);
                let _e467 = (floor((_e460 * 0.03125f)) * 0.33333334f);
                let _e471 = global_8;
                let _e472 = normalize(_e471);
                let _e473 = global_9;
                let _e474 = _e473.xyz;
                let _e475 = dot(_e472, _e474);
                let _e481 = ((_e475 / max(length((_e474 - (_e472 * _e475))), 0.000001f)) * 25.5f);
                local_47 = ((vec3<f32>(_e448.x, _e446.x, _e442.x) * vec3<f32>(0.003921569f, 0.003921569f, 0.003921569f)) * 2f);
                local_90 = (vec2<f32>(_e448.y, _e446.y) * vec2<f32>(0.003921569f, 0.003921569f));
                if ((-24f + _e481) < -2f) {
                    phi_18579_ = 0f;
                    break;
                }
                let _e484 = global_10;
                let _e485 = (_e484 * (4f * exp2(((_e460 - (floor((_e460 / 32f)) * 32f)) * 0.33333334f))));
                let _e486 = floor(_e485);
                let _e487 = (_e485 - _e486);
                let _e491 = ((_e487 * _e487) * (vec3<f32>(3f, 3f, 3f) - (_e487 * 2f)));
                let _e493 = bitcast<vec3<u32>>(vec3<i32>(_e486));
                let _e502 = ((((_e493.x * 1597334677u) ^ (_e493.y * 3812015801u)) ^ (_e493.z * 2798796415u)) * 1597334677u);
                let _e511 = bitcast<vec3<u32>>(vec3<i32>((_e486 + vec3<f32>(1f, 0f, 0f))));
                let _e520 = ((((_e511.x * 1597334677u) ^ (_e511.y * 3812015801u)) ^ (_e511.z * 2798796415u)) * 1597334677u);
                let _e531 = bitcast<vec3<u32>>(vec3<i32>((_e486 + vec3<f32>(0f, 1f, 0f))));
                let _e540 = ((((_e531.x * 1597334677u) ^ (_e531.y * 3812015801u)) ^ (_e531.z * 2798796415u)) * 1597334677u);
                let _e549 = bitcast<vec3<u32>>(vec3<i32>((_e486 + vec3<f32>(1f, 1f, 0f))));
                let _e558 = ((((_e549.x * 1597334677u) ^ (_e549.y * 3812015801u)) ^ (_e549.z * 2798796415u)) * 1597334677u);
                let _e570 = bitcast<vec3<u32>>(vec3<i32>((_e486 + vec3<f32>(0f, 0f, 1f))));
                let _e579 = ((((_e570.x * 1597334677u) ^ (_e570.y * 3812015801u)) ^ (_e570.z * 2798796415u)) * 1597334677u);
                let _e588 = bitcast<vec3<u32>>(vec3<i32>((_e486 + vec3<f32>(1f, 0f, 1f))));
                let _e597 = ((((_e588.x * 1597334677u) ^ (_e588.y * 3812015801u)) ^ (_e588.z * 2798796415u)) * 1597334677u);
                let _e607 = bitcast<vec3<u32>>(vec3<i32>((_e486 + vec3<f32>(0f, 1f, 1f))));
                let _e616 = ((((_e607.x * 1597334677u) ^ (_e607.y * 3812015801u)) ^ (_e607.z * 2798796415u)) * 1597334677u);
                let _e625 = bitcast<vec3<u32>>(vec3<i32>((_e486 + vec3<f32>(1f, 1f, 1f))));
                let _e634 = ((((_e625.x * 1597334677u) ^ (_e625.y * 3812015801u)) ^ (_e625.z * 2798796415u)) * 1597334677u);
                let _e647 = ((_e485 * 2.7f) + vec3<f32>(17.3f, 5.1f, 9.7f));
                let _e648 = floor(_e647);
                let _e649 = (_e647 - _e648);
                let _e653 = ((_e649 * _e649) * (vec3<f32>(3f, 3f, 3f) - (_e649 * 2f)));
                let _e655 = bitcast<vec3<u32>>(vec3<i32>(_e648));
                let _e664 = ((((_e655.x * 1597334677u) ^ (_e655.y * 3812015801u)) ^ (_e655.z * 2798796415u)) * 1597334677u);
                let _e673 = bitcast<vec3<u32>>(vec3<i32>((_e648 + vec3<f32>(1f, 0f, 0f))));
                let _e682 = ((((_e673.x * 1597334677u) ^ (_e673.y * 3812015801u)) ^ (_e673.z * 2798796415u)) * 1597334677u);
                let _e693 = bitcast<vec3<u32>>(vec3<i32>((_e648 + vec3<f32>(0f, 1f, 0f))));
                let _e702 = ((((_e693.x * 1597334677u) ^ (_e693.y * 3812015801u)) ^ (_e693.z * 2798796415u)) * 1597334677u);
                let _e711 = bitcast<vec3<u32>>(vec3<i32>((_e648 + vec3<f32>(1f, 1f, 0f))));
                let _e720 = ((((_e711.x * 1597334677u) ^ (_e711.y * 3812015801u)) ^ (_e711.z * 2798796415u)) * 1597334677u);
                let _e732 = bitcast<vec3<u32>>(vec3<i32>((_e648 + vec3<f32>(0f, 0f, 1f))));
                let _e741 = ((((_e732.x * 1597334677u) ^ (_e732.y * 3812015801u)) ^ (_e732.z * 2798796415u)) * 1597334677u);
                let _e750 = bitcast<vec3<u32>>(vec3<i32>((_e648 + vec3<f32>(1f, 0f, 1f))));
                let _e759 = ((((_e750.x * 1597334677u) ^ (_e750.y * 3812015801u)) ^ (_e750.z * 2798796415u)) * 1597334677u);
                let _e769 = bitcast<vec3<u32>>(vec3<i32>((_e648 + vec3<f32>(0f, 1f, 1f))));
                let _e778 = ((((_e769.x * 1597334677u) ^ (_e769.y * 3812015801u)) ^ (_e769.z * 2798796415u)) * 1597334677u);
                let _e787 = bitcast<vec3<u32>>(vec3<i32>((_e648 + vec3<f32>(1f, 1f, 1f))));
                let _e796 = ((((_e787.x * 1597334677u) ^ (_e787.y * 3812015801u)) ^ (_e787.z * 2798796415u)) * 1597334677u);
                let _e809 = mix(0.45f, 0.05f, _e467);
                phi_18579_ = smoothstep(-(_e809), _e809, ((_e481 + -24.45f) + ((((mix(mix(mix((f32(((_e502 ^ (_e502 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e520 ^ (_e520 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e491.x), mix((f32(((_e540 ^ (_e540 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e558 ^ (_e558 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e491.x), _e491.y), mix(mix((f32(((_e579 ^ (_e579 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e597 ^ (_e597 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e491.x), mix((f32(((_e616 ^ (_e616 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e634 ^ (_e634 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e491.x), _e491.y), _e491.z) * 0.65f) + (mix(mix(mix((f32(((_e664 ^ (_e664 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e682 ^ (_e682 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e653.x), mix((f32(((_e702 ^ (_e702 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e720 ^ (_e720 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e653.x), _e653.y), mix(mix((f32(((_e741 ^ (_e741 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e759 ^ (_e759 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e653.x), mix((f32(((_e778 ^ (_e778 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e796 ^ (_e796 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e653.x), _e653.y), _e653.z) * 0.35f)) - 0.5f) * mix(0.8f, 2.2f, _e467))));
                break;
            }
        }
        let _e818 = phi_18579_;
        let _e820 = local_47;
        let _e7170 = local_90;
        phi_18742_ = _e7170;
        phi_18709_ = _e818;
        phi_18678_ = mix(_e430, ((_e395 * _e820) * mix(vec3<f32>(1f, 1f, 1f), (_e400 * 2f), vec3<f32>(0.5f, 0.5f, 0.5f))), vec3(_e818));
    }
    let _e828 = phi_18742_;
    let _e830 = phi_18709_;
    let _e832 = phi_18678_;
    let _e833 = global_8;
    let _e834 = normalize(_e833);
    let _e837 = global_7.member_6[1u];
    phi_18591_ = _e834;
    if (_e837 > 0.5f) {
        let _e839 = global_9;
        let _e840 = _e839.xyz;
        let _e843 = (_e840 - (_e834 * dot(_e834, _e840)));
        phi_18592_ = _e834;
        if (dot(_e843, _e843) > 0.000000000001f) {
            let _e846 = normalize(_e843);
            let _e849 = global_9[3u];
            let _e853 = textureSample(global_23, global_4, _e392);
            let _e856 = global_7.member_6[2u];
            if (_e856 > 0.5f) {
                if (_e856 > 1.5f) {
                    phi_18582_ = _e853.xw;
                } else {
                    phi_18582_ = _e853.xy;
                }
                let _e862 = phi_18582_;
                let _e864 = ((_e862 * 2f) - vec2<f32>(1f, 1f));
                phi_18583_ = vec3<f32>(_e864.x, _e864.y, sqrt(clamp((1f - dot(_e864, _e864)), 0f, 1f)));
            } else {
                phi_18583_ = ((_e853.xyz * 2f) - vec3<f32>(1f, 1f, 1f));
            }
            let _e876 = phi_18583_;
            let _e879 = global_7.member_4[2u];
            let _e881 = (_e876.xy * _e879);
            phi_18592_ = normalize((((_e846 * _e881.x) + ((cross(_e834, _e846) * select(1f, -1f, (_e849 < 0f))) * _e881.y)) + (_e834 * _e876.z)));
        }
        let _e892 = phi_18592_;
        phi_18591_ = _e892;
    }
    let _e894 = phi_18591_;
    let _e897 = global_7.member_5[3u];
    let _e898 = (_e897 > 0.5f);
    if _e898 {
        let _e901 = global_7.member_1[2u];
        phi_18588_ = clamp(_e901, 0f, 1f);
    } else {
        phi_18588_ = 0f;
    }
    let _e904 = phi_18588_;
    phi_4559_ = _e898;
    if _e898 {
        let _e905 = global_19;
        phi_4559_ = !(_e905);
    }
    let _e908 = phi_4559_;
    phi_18776_ = _e894;
    if (_e908 && (_e904 <= 0f)) {
        phi_18776_ = -(_e894);
    }
    let _e913 = phi_18776_;
    let _e915 = global.member_4;
    let _e917 = normalize(_e915.xyz);
    let _e919 = global.member_6;
    let _e920 = _e919.xyz;
    let _e921 = global_12;
    let _e922 = (_e920 - _e921);
    let _e923 = normalize(_e922);
    let _e925 = normalize((_e917 + _e923));
    let _e926 = global_19;
    let _e928 = (_e834 * select(-1f, 1f, _e926));
    let _e930 = global_24[0u];
    let _e931 = (_e930 > 0.5f);
    let _e934 = global.member_5[3u];
    phi_18802_ = 1f;
    phi_18771_ = _e832;
    if ((_e934 > 0.5f) && _e931) {
        switch bitcast<i32>(0u) {
            default: {
                let _e940 = global.member_21[0u];
                let _e941 = i32(_e940);
                let _e943 = global.member_20;
                let _e948 = global.member_20[3u];
                let _e949 = (dot(_e943.xyz, _e921) + _e948);
                phi_18593_ = 0i;
                loop {
                    let _e951 = phi_18593_;
                    local_48 = _e951;
                    local_49 = _e951;
                    local_50 = _e951;
                    local_51 = _e951;
                    local_52 = _e951;
                    local_53 = _e951;
                    local_55 = _e951;
                    local_56 = _e951;
                    local_57 = _e951;
                    let _e953 = (_e951 < (_e941 - 1i));
                    phi_5910_ = _e953;
                    if _e953 {
                        let _e956 = global.member_16[_e951];
                        phi_5910_ = (_e949 > _e956);
                    }
                    let _e959 = phi_5910_;
                    if _e959 {
                        continue;
                    } else {
                        break;
                    }
                    continuing {
                        phi_18593_ = (_e951 + 1i);
                    }
                }
                let _e963 = local_48;
                let _e965 = global.member_16[_e963];
                if (_e949 > _e965) {
                    phi_18649_ = vec3<f32>(1f, 1f, 1f);
                    phi_18648_ = 1f;
                    break;
                }
                let _e969 = local_49;
                let _e971 = global.member_18[_e969];
                let _e973 = (_e921 + (_e928 * _e971));
                switch bitcast<i32>(0u) {
                    default: {
                        let _e977 = local_50;
                        let _e979 = global.member_14[_e977];
                        let _e984 = (_e979 * vec4<f32>(_e973.x, _e973.y, _e973.z, 1f));
                        let _e986 = (_e984.x < 0f);
                        phi_6023_ = _e986;
                        if !(_e986) {
                            phi_6023_ = (_e984.x > 1f);
                        }
                        let _e990 = phi_6023_;
                        phi_6030_ = _e990;
                        if !(_e990) {
                            phi_6030_ = (_e984.y < 0f);
                        }
                        let _e995 = phi_6030_;
                        phi_6037_ = _e995;
                        if !(_e995) {
                            phi_6037_ = (_e984.y > 1f);
                        }
                        let _e1000 = phi_6037_;
                        if _e1000 {
                            phi_18606_ = 1f;
                            break;
                        }
                        let _e1002 = local_51;
                        let _e1006 = local_52;
                        let _e1012 = global.member_23;
                        let _e1013 = _e1012.xy;
                        let _e1014 = (vec2<f32>(f32((_e1002 & 1i)), f32((_e1006 >> bitcast<u32>(1i)))) * _e1013);
                        let _e1019 = local_53;
                        let _e1021 = global.member_19[_e1019];
                        let _e1022 = (min(_e984.z, 1f) - _e1021);
                        let _e1025 = global.member_22;
                        let _e1026 = _e1025.xy;
                        let _e1027 = (_e1026 * 0.5f);
                        let _e1029 = (_e1014 + (_e984.xy * _e1013));
                        let _e1030 = (_e1014 + _e1027);
                        let _e1032 = ((_e1014 + _e1013) - _e1027);
                        let _e1037 = vec4<f32>(_e1030.x, _e1030.y, _e1032.x, _e1032.y);
                        switch bitcast<i32>(0u) {
                            default: {
                                let _e1041 = global.member_22[2u];
                                let _e1042 = i32(_e1041);
                                if (_e1042 <= 0i) {
                                    let _e1046 = clamp(_e1029, _e1037.xy, _e1037.zw);
                                    let _e1051 = textureSampleCompare(global_2, global_1, vec3<f32>(_e1046.x, _e1046.y, _e1022).xy, _e1022);
                                    phi_18605_ = _e1051;
                                    break;
                                }
                                let _e1053 = ((_e1029 / _e1026) + vec2<f32>(0.5f, 0.5f));
                                let _e1054 = floor(_e1053);
                                let _e1055 = (_e1053 - _e1054);
                                let _e1057 = (_e1042 == 1i);
                                if _e1057 {
                                    let _e1058 = (_e1055 * 2f);
                                    local_43[0i] = (vec2<f32>(3f, 3f) - _e1058);
                                    local_43[1i] = (vec2<f32>(1f, 1f) + _e1058);
                                    let _e1064 = local_43[0i];
                                    local_44[0i] = (((vec2<f32>(2f, 2f) - _e1055) / _e1064) - vec2<f32>(1f, 1f));
                                    let _e1068 = local_43[1i];
                                    local_44[1i] = ((_e1055 / _e1068) + vec2<f32>(1f, 1f));
                                } else {
                                    let _e1072 = (_e1055 * 3f);
                                    local_43[0i] = (vec2<f32>(4f, 4f) - _e1072);
                                    local_43[1i] = vec2<f32>(7f, 7f);
                                    local_43[2i] = (vec2<f32>(1f, 1f) + _e1072);
                                    let _e1080 = local_43[0i];
                                    local_44[0i] = (((vec2<f32>(3f, 3f) - (_e1055 * 2f)) / _e1080) - vec2<f32>(2f, 2f));
                                    let _e1085 = local_43[1i];
                                    local_44[1i] = ((vec2<f32>(3f, 3f) + _e1055) / _e1085);
                                    let _e1088 = local_43[2i];
                                    local_44[2i] = ((_e1055 / _e1088) + vec2<f32>(2f, 2f));
                                }
                                let _e1093 = select(3i, 2i, _e1057);
                                phi_18598_ = 0f;
                                phi_18595_ = 0i;
                                loop {
                                    let _e1095 = phi_18598_;
                                    let _e1097 = phi_18595_;
                                    local_54 = _e1095;
                                    if (_e1097 < _e1093) {
                                        phi_18604_ = _e1095;
                                        phi_18601_ = 0i;
                                        loop {
                                            let _e1100 = phi_18604_;
                                            let _e1102 = phi_18601_;
                                            local_91 = _e1100;
                                            if (_e1102 < _e1093) {
                                                continue;
                                            } else {
                                                break;
                                            }
                                            continuing {
                                                let _e1106 = local_44[_e1102][0u];
                                                let _e1109 = local_44[_e1097][1u];
                                                let _e1115 = clamp((_e1026 * ((_e1054 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e1106, _e1109))), _e1037.xy, _e1037.zw);
                                                let _e1118 = local_43[_e1102][0u];
                                                let _e1121 = local_43[_e1097][1u];
                                                let _e1127 = textureSampleCompare(global_2, global_1, vec3<f32>(_e1115.x, _e1115.y, _e1022).xy, _e1022);
                                                phi_18604_ = (_e1100 + ((_e1118 * _e1121) * _e1127));
                                                phi_18601_ = (_e1102 + 1i);
                                            }
                                        }
                                        continue;
                                    } else {
                                        break;
                                    }
                                    continuing {
                                        let _e7193 = local_91;
                                        phi_18598_ = _e7193;
                                        phi_18595_ = (_e1097 + 1i);
                                    }
                                }
                                let _e1133 = local_54;
                                phi_18605_ = (_e1133 * select(0.0069444445f, 0.0625f, _e1057));
                                break;
                            }
                        }
                        let _e1136 = phi_18605_;
                        phi_18606_ = _e1136;
                        break;
                    }
                }
                let _e1138 = phi_18606_;
                local_45 = array<vec3<f32>, 4>(vec3<f32>(1f, 0.45f, 0.45f), vec3<f32>(0.45f, 1f, 0.45f), vec3<f32>(0.5f, 0.6f, 1f), vec3<f32>(1f, 1f, 0.4f));
                let _e1140 = local_55;
                let _e1142 = local_45[_e1140];
                let _e1145 = local_56;
                let _e1147 = global.member_17[_e1145];
                phi_18646_ = _e1138;
                phi_18643_ = _e1142;
                if (_e949 > _e1147) {
                    let _e1151 = ((_e949 - _e1147) / (_e965 - _e1147));
                    let _e1153 = local_57;
                    let _e1154 = (_e1153 + 1i);
                    if (_e1154 < _e941) {
                        let _e1158 = global.member_18[_e1154];
                        let _e1160 = (_e921 + (_e928 * _e1158));
                        switch bitcast<i32>(0u) {
                            default: {
                                let _e1164 = global.member_14[_e1154];
                                let _e1169 = (_e1164 * vec4<f32>(_e1160.x, _e1160.y, _e1160.z, 1f));
                                let _e1171 = (_e1169.x < 0f);
                                phi_6310_ = _e1171;
                                if !(_e1171) {
                                    phi_6310_ = (_e1169.x > 1f);
                                }
                                let _e1175 = phi_6310_;
                                phi_6317_ = _e1175;
                                if !(_e1175) {
                                    phi_6317_ = (_e1169.y < 0f);
                                }
                                let _e1180 = phi_6317_;
                                phi_6324_ = _e1180;
                                if !(_e1180) {
                                    phi_6324_ = (_e1169.y > 1f);
                                }
                                let _e1185 = phi_6324_;
                                if _e1185 {
                                    phi_18626_ = 1f;
                                    break;
                                }
                                let _e1193 = global.member_23;
                                let _e1194 = _e1193.xy;
                                let _e1195 = (vec2<f32>(f32((_e1154 & 1i)), f32((_e1154 >> bitcast<u32>(1i)))) * _e1194);
                                let _e1200 = global.member_19[_e1154];
                                let _e1201 = (min(_e1169.z, 1f) - _e1200);
                                let _e1204 = global.member_22;
                                let _e1205 = _e1204.xy;
                                let _e1206 = (_e1205 * 0.5f);
                                let _e1208 = (_e1195 + (_e1169.xy * _e1194));
                                let _e1209 = (_e1195 + _e1206);
                                let _e1211 = ((_e1195 + _e1194) - _e1206);
                                let _e1216 = vec4<f32>(_e1209.x, _e1209.y, _e1211.x, _e1211.y);
                                switch bitcast<i32>(0u) {
                                    default: {
                                        let _e1220 = global.member_22[2u];
                                        let _e1221 = i32(_e1220);
                                        if (_e1221 <= 0i) {
                                            let _e1225 = clamp(_e1208, _e1216.xy, _e1216.zw);
                                            let _e1230 = textureSampleCompare(global_2, global_1, vec3<f32>(_e1225.x, _e1225.y, _e1201).xy, _e1201);
                                            phi_18625_ = _e1230;
                                            break;
                                        }
                                        let _e1232 = ((_e1208 / _e1205) + vec2<f32>(0.5f, 0.5f));
                                        let _e1233 = floor(_e1232);
                                        let _e1234 = (_e1232 - _e1233);
                                        let _e1236 = (_e1221 == 1i);
                                        if _e1236 {
                                            let _e1237 = (_e1234 * 2f);
                                            local_41[0i] = (vec2<f32>(3f, 3f) - _e1237);
                                            local_41[1i] = (vec2<f32>(1f, 1f) + _e1237);
                                            let _e1243 = local_41[0i];
                                            local_42[0i] = (((vec2<f32>(2f, 2f) - _e1234) / _e1243) - vec2<f32>(1f, 1f));
                                            let _e1247 = local_41[1i];
                                            local_42[1i] = ((_e1234 / _e1247) + vec2<f32>(1f, 1f));
                                        } else {
                                            let _e1251 = (_e1234 * 3f);
                                            local_41[0i] = (vec2<f32>(4f, 4f) - _e1251);
                                            local_41[1i] = vec2<f32>(7f, 7f);
                                            local_41[2i] = (vec2<f32>(1f, 1f) + _e1251);
                                            let _e1259 = local_41[0i];
                                            local_42[0i] = (((vec2<f32>(3f, 3f) - (_e1234 * 2f)) / _e1259) - vec2<f32>(2f, 2f));
                                            let _e1264 = local_41[1i];
                                            local_42[1i] = ((vec2<f32>(3f, 3f) + _e1234) / _e1264);
                                            let _e1267 = local_41[2i];
                                            local_42[2i] = ((_e1234 / _e1267) + vec2<f32>(2f, 2f));
                                        }
                                        let _e1272 = select(3i, 2i, _e1236);
                                        phi_18618_ = 0f;
                                        phi_18615_ = 0i;
                                        loop {
                                            let _e1274 = phi_18618_;
                                            let _e1276 = phi_18615_;
                                            local_58 = _e1274;
                                            if (_e1276 < _e1272) {
                                                phi_18624_ = _e1274;
                                                phi_18621_ = 0i;
                                                loop {
                                                    let _e1279 = phi_18624_;
                                                    let _e1281 = phi_18621_;
                                                    local_92 = _e1279;
                                                    if (_e1281 < _e1272) {
                                                        continue;
                                                    } else {
                                                        break;
                                                    }
                                                    continuing {
                                                        let _e1285 = local_42[_e1281][0u];
                                                        let _e1288 = local_42[_e1276][1u];
                                                        let _e1294 = clamp((_e1205 * ((_e1233 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e1285, _e1288))), _e1216.xy, _e1216.zw);
                                                        let _e1297 = local_41[_e1281][0u];
                                                        let _e1300 = local_41[_e1276][1u];
                                                        let _e1306 = textureSampleCompare(global_2, global_1, vec3<f32>(_e1294.x, _e1294.y, _e1201).xy, _e1201);
                                                        phi_18624_ = (_e1279 + ((_e1297 * _e1300) * _e1306));
                                                        phi_18621_ = (_e1281 + 1i);
                                                    }
                                                }
                                                continue;
                                            } else {
                                                break;
                                            }
                                            continuing {
                                                let _e7208 = local_92;
                                                phi_18618_ = _e7208;
                                                phi_18615_ = (_e1276 + 1i);
                                            }
                                        }
                                        let _e1312 = local_58;
                                        phi_18625_ = (_e1312 * select(0.0069444445f, 0.0625f, _e1236));
                                        break;
                                    }
                                }
                                let _e1315 = phi_18625_;
                                phi_18626_ = _e1315;
                                break;
                            }
                        }
                        let _e1317 = phi_18626_;
                        local_46 = array<vec3<f32>, 4>(vec3<f32>(1f, 0.45f, 0.45f), vec3<f32>(0.45f, 1f, 0.45f), vec3<f32>(0.5f, 0.6f, 1f), vec3<f32>(1f, 1f, 0.4f));
                        let _e1320 = local_46[_e1154];
                        phi_18647_ = mix(_e1138, _e1317, _e1151);
                        phi_18644_ = mix(_e1142, _e1320, vec3(_e1151));
                    } else {
                        phi_18647_ = mix(_e1138, 1f, _e1151);
                        phi_18644_ = _e1142;
                    }
                    let _e1325 = phi_18647_;
                    let _e1327 = phi_18644_;
                    phi_18646_ = _e1325;
                    phi_18643_ = _e1327;
                }
                let _e1329 = phi_18646_;
                let _e1331 = phi_18643_;
                let _e1334 = global.member_22[3u];
                phi_18649_ = select(vec3<f32>(1f, 1f, 1f), _e1331, vec3((_e1334 > 0.5f)));
                phi_18648_ = _e1329;
                break;
            }
        }
        let _e1339 = phi_18649_;
        let _e1341 = phi_18648_;
        phi_18802_ = _e1341;
        phi_18771_ = (_e832 * _e1339);
    }
    let _e1344 = phi_18802_;
    let _e1346 = phi_18771_;
    let _e1348 = global.member_5;
    let _e1352 = global.member_4[3u];
    let _e1353 = (_e1348.xyz * _e1352);
    let _e1356 = global_7.member_6[3u];
    if (_e1356 > 0.5f) {
        phi_18701_ = 1f;
    } else {
        let _e1360 = global_7.member_4[3u];
        let _e1361 = textureSample(global_25, global_4, _e392);
        phi_18701_ = (1f + (_e1360 * (_e1361.x - 1f)));
    }
    let _e1367 = phi_18701_;
    let _e1369 = global_9[3u];
    let _e1370 = abs(_e1369);
    phi_18804_ = _e1367;
    if (_e1370 > 0f) {
        phi_18804_ = (_e1367 * min(_e1370, 1f));
    }
    let _e1375 = phi_18804_;
    if !(_e898) {
        let _e1377 = dot(_e913, _e917);
        let _e1384 = global_7.member_1[3u];
        let _e1388 = global_7.member_1[2u];
        let _e1395 = global.member_29[0u];
        if (_e1395 > 0.5f) {
            let _e1398 = global.member_29;
            let _e1405 = ((_e1398.z * _e913.x) - (_e1398.w * _e913.z));
            let _e1409 = ((_e1398.w * _e913.x) + (_e1398.z * _e913.z));
            let _e1413 = (1.092548f * _e1405);
            local_40 = array<f32, 9>(0.282095f, (0.488603f * _e913.y), (0.488603f * _e1409), (0.488603f * _e1405), (_e1413 * _e913.y), ((1.092548f * _e913.y) * _e1409), (0.315392f * (((3f * _e1409) * _e1409) - 1f)), (_e1413 * _e1409), (0.546274f * ((_e1405 * _e1405) - (_e913.y * _e913.y))));
            phi_19395_ = vec3<f32>(0f, 0f, 0f);
            phi_19394_ = 0i;
            loop {
                let _e1428 = phi_19395_;
                let _e1430 = phi_19394_;
                local_59 = _e1428;
                if (_e1430 < 9i) {
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e1434 = textureLoad(global_3, (vec2<i32>(496i, 256i) + vec2<i32>(_e1430, 0i)), 0i);
                    let _e1437 = local_40[_e1430];
                    phi_19395_ = (_e1428 + (_e1434.xyz * _e1437));
                    phi_19394_ = (_e1430 + 1i);
                }
            }
            let _e1442 = local_59;
            let _e1446 = global.member_29[1u];
            phi_19396_ = (max(_e1442, vec3<f32>(0f, 0f, 0f)) * _e1446);
        } else {
            let _e1449 = global.member_9;
            let _e1452 = global.member_8;
            let _e1461 = global.member_8[3u];
            phi_19396_ = (mix(_e1449.xyz, _e1452.xyz, vec3(((_e913.y * 0.5f) + 0.5f))) * _e1461);
        }
        let _e1464 = phi_19396_;
        let _e1470 = ((_e1346 * ((_e1464 * _e1375) + ((_e1353 * max(_e1377, 0f)) * _e1344))) + ((_e1353 * ((pow(max(dot(_e913, _e925), 0f), _e1384) * _e1388) * step(0f, _e1377))) * _e1344));
        let _e1473 = global.member_13[3u];
        phi_19405_ = _e1470;
        if (_e1473 > 0.5f) {
            let _e1476 = global.member_11;
            let _e1481 = global.member_11[3u];
            let _e1483 = global_15;
            let _e1486 = global.member_12;
            let _e1491 = global.member_13;
            let _e1494 = clamp(floor((_e1483.xy * _e1486.xy)), vec2<f32>(0f, 0f), (_e1491.xy - vec2<f32>(1f, 1f)));
            let _e1499 = global.member_12[2u];
            let _e1503 = global.member_12[3u];
            let _e1508 = global.member_13[2u];
            let _e1513 = global.member_13[1u];
            let _e1519 = global.member_13[0u];
            let _e1523 = u32(((((clamp(floor(((log2(max((dot(_e1476.xyz, _e921) + _e1481), 0.000001f)) * _e1499) + _e1503)), 0f, (_e1508 - 1f)) * _e1513) + _e1494.y) * _e1519) + _e1494.x));
            let _e1530 = global_16.member[(_e1523 >> bitcast<u32>(2i))][(_e1523 & 3u)];
            let _e1531 = (_e1530 & 65535u);
            phi_19406_ = _e1470;
            phi_19403_ = _e1531;
            loop {
                let _e1535 = phi_19406_;
                let _e1537 = phi_19403_;
                local_96 = _e1535;
                if (_e1537 < (_e1531 + (_e1530 >> bitcast<u32>(16i)))) {
                    let _e1540 = (_e1537 / 3u);
                    let _e1547 = global_17.member[(_e1540 >> bitcast<u32>(2i))][(_e1540 & 3u)];
                    let _e1553 = ((_e1547 >> bitcast<u32>(((_e1537 - (_e1540 * 3u)) * 10u))) & 1023u);
                    let _e1556 = global_11.member[_e1553];
                    let _e1558 = (_e1556.xyz - _e921);
                    let _e1559 = dot(_e1558, _e1558);
                    let _e1561 = (_e1559 * _e1556.w);
                    let _e1564 = clamp((1f - (_e1561 * _e1561)), 0f, 1f);
                    let _e1567 = (_e1558 * inverseSqrt(max(_e1559, 0.00000001f)));
                    let _e1570 = global_13.member[_e1553];
                    let _e1573 = global_14.member[_e1553];
                    let _e1581 = clamp(((dot(-(_e1567), _e1573.xyz) * _e1570.w) + _e1573.w), 0f, 1f);
                    let _e1588 = (_e1570.xyz * ((((_e1564 * _e1564) * _e1581) * _e1581) / max(_e1559, 0.0001f)));
                    phi_19809_ = _e1588;
                    if _e931 {
                        switch bitcast<i32>(0u) {
                            default: {
                                let _e1592 = global.member_21[2u];
                                let _e1593 = u32(_e1592);
                                if (_e1553 < _e1593) {
                                    let _e1597 = global.member_26[_e1553];
                                    let _e1600 = global.member_15[_e1553];
                                    let _e1609 = (_e1597.z * max((_e1600 * vec4<f32>(_e921.x, _e921.y, _e921.z, 1f)).w, 0f));
                                    let _e1612 = global.member_25[0u];
                                    let _e1618 = global.member_25[1u];
                                    let _e1621 = ((_e921 + (_e928 * (_e1609 * _e1612))) + (_e1567 * (_e1609 * _e1618)));
                                    let _e1626 = (_e1600 * vec4<f32>(_e1621.x, _e1621.y, _e1621.z, 1f));
                                    if (_e1626.w <= 0f) {
                                        phi_19755_ = 1f;
                                        break;
                                    }
                                    let _e1631 = (_e1626.xyz / vec3(_e1626.w));
                                    let _e1633 = (_e1631.x < 0f);
                                    phi_6965_ = _e1633;
                                    if !(_e1633) {
                                        phi_6965_ = (_e1631.x > 1f);
                                    }
                                    let _e1637 = phi_6965_;
                                    phi_6972_ = _e1637;
                                    if !(_e1637) {
                                        phi_6972_ = (_e1631.y < 0f);
                                    }
                                    let _e1642 = phi_6972_;
                                    phi_6979_ = _e1642;
                                    if !(_e1642) {
                                        phi_6979_ = (_e1631.y > 1f);
                                    }
                                    let _e1647 = phi_6979_;
                                    phi_6986_ = _e1647;
                                    if !(_e1647) {
                                        phi_6986_ = (_e1631.z > 1f);
                                    }
                                    let _e1652 = phi_6986_;
                                    if _e1652 {
                                        phi_19755_ = 1f;
                                        break;
                                    }
                                    let _e1655 = _e1597.xy;
                                    let _e1657 = global.member_23;
                                    let _e1658 = _e1657.zw;
                                    let _e1660 = global.member_22;
                                    let _e1661 = _e1660.xy;
                                    let _e1662 = (_e1661 * 0.5f);
                                    let _e1664 = (_e1655 + (_e1631.xy * _e1658));
                                    let _e1665 = (_e1655 + _e1662);
                                    let _e1667 = ((_e1655 + _e1658) - _e1662);
                                    let _e1672 = vec4<f32>(_e1665.x, _e1665.y, _e1667.x, _e1667.y);
                                    switch bitcast<i32>(0u) {
                                        default: {
                                            let _e1676 = global.member_22[2u];
                                            let _e1677 = i32(_e1676);
                                            if (_e1677 <= 0i) {
                                                let _e1681 = clamp(_e1664, _e1672.xy, _e1672.zw);
                                                let _e1686 = textureSampleCompare(global_2, global_1, vec3<f32>(_e1681.x, _e1681.y, _e1631.z).xy, _e1631.z);
                                                phi_19754_ = _e1686;
                                                break;
                                            }
                                            let _e1688 = ((_e1664 / _e1661) + vec2<f32>(0.5f, 0.5f));
                                            let _e1689 = floor(_e1688);
                                            let _e1690 = (_e1688 - _e1689);
                                            let _e1692 = (_e1677 == 1i);
                                            if _e1692 {
                                                let _e1693 = (_e1690 * 2f);
                                                local_36[0i] = (vec2<f32>(3f, 3f) - _e1693);
                                                local_36[1i] = (vec2<f32>(1f, 1f) + _e1693);
                                                let _e1699 = local_36[0i];
                                                local_37[0i] = (((vec2<f32>(2f, 2f) - _e1690) / _e1699) - vec2<f32>(1f, 1f));
                                                let _e1703 = local_36[1i];
                                                local_37[1i] = ((_e1690 / _e1703) + vec2<f32>(1f, 1f));
                                            } else {
                                                let _e1707 = (_e1690 * 3f);
                                                local_36[0i] = (vec2<f32>(4f, 4f) - _e1707);
                                                local_36[1i] = vec2<f32>(7f, 7f);
                                                local_36[2i] = (vec2<f32>(1f, 1f) + _e1707);
                                                let _e1715 = local_36[0i];
                                                local_37[0i] = (((vec2<f32>(3f, 3f) - (_e1690 * 2f)) / _e1715) - vec2<f32>(2f, 2f));
                                                let _e1720 = local_36[1i];
                                                local_37[1i] = ((vec2<f32>(3f, 3f) + _e1690) / _e1720);
                                                let _e1723 = local_36[2i];
                                                local_37[2i] = ((_e1690 / _e1723) + vec2<f32>(2f, 2f));
                                            }
                                            let _e1728 = select(3i, 2i, _e1692);
                                            phi_19747_ = 0f;
                                            phi_19744_ = 0i;
                                            loop {
                                                let _e1730 = phi_19747_;
                                                let _e1732 = phi_19744_;
                                                local_60 = _e1730;
                                                if (_e1732 < _e1728) {
                                                    phi_19753_ = _e1730;
                                                    phi_19750_ = 0i;
                                                    loop {
                                                        let _e1735 = phi_19753_;
                                                        let _e1737 = phi_19750_;
                                                        local_94 = _e1735;
                                                        if (_e1737 < _e1728) {
                                                            continue;
                                                        } else {
                                                            break;
                                                        }
                                                        continuing {
                                                            let _e1741 = local_37[_e1737][0u];
                                                            let _e1744 = local_37[_e1732][1u];
                                                            let _e1750 = clamp((_e1661 * ((_e1689 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e1741, _e1744))), _e1672.xy, _e1672.zw);
                                                            let _e1753 = local_36[_e1737][0u];
                                                            let _e1756 = local_36[_e1732][1u];
                                                            let _e1762 = textureSampleCompare(global_2, global_1, vec3<f32>(_e1750.x, _e1750.y, _e1631.z).xy, _e1631.z);
                                                            phi_19753_ = (_e1735 + ((_e1753 * _e1756) * _e1762));
                                                            phi_19750_ = (_e1737 + 1i);
                                                        }
                                                    }
                                                    continue;
                                                } else {
                                                    break;
                                                }
                                                continuing {
                                                    let _e7239 = local_94;
                                                    phi_19747_ = _e7239;
                                                    phi_19744_ = (_e1732 + 1i);
                                                }
                                            }
                                            let _e1768 = local_60;
                                            phi_19754_ = (_e1768 * select(0.0069444445f, 0.0625f, _e1692));
                                            break;
                                        }
                                    }
                                    let _e1771 = phi_19754_;
                                    phi_19755_ = _e1771;
                                    break;
                                }
                                let _e1772 = (_e1553 - _e1593);
                                let _e1775 = global.member_21[3u];
                                if (_e1772 >= u32(_e1775)) {
                                    phi_19755_ = 1f;
                                    break;
                                }
                                let _e1780 = global.member_27[_e1772];
                                let _e1783 = global.member_28[_e1772];
                                let _e1785 = _e1780.xyz;
                                let _e1788 = (_e1780.w * length((_e921 - _e1785)));
                                let _e1791 = global.member_25[0u];
                                let _e1797 = global.member_25[1u];
                                let _e1801 = (((_e921 + (_e928 * (_e1788 * _e1791))) + (_e1567 * (_e1788 * _e1797))) - _e1785);
                                let _e1802 = abs(_e1801);
                                let _e1805 = (_e1802.x >= _e1802.y);
                                phi_7056_ = _e1805;
                                if _e1805 {
                                    phi_7056_ = (_e1802.x >= _e1802.z);
                                }
                                let _e1809 = phi_7056_;
                                if _e1809 {
                                    phi_19731_ = select(1i, 0i, (_e1801.x > 0f));
                                    phi_19729_ = _e1802.x;
                                } else {
                                    let _e1814 = (_e1802.y >= _e1802.z);
                                    if _e1814 {
                                        phi_19732_ = select(3i, 2i, (_e1801.y > 0f));
                                    } else {
                                        phi_19732_ = select(5i, 4i, (_e1801.z > 0f));
                                    }
                                    let _e1822 = phi_19732_;
                                    phi_19731_ = _e1822;
                                    phi_19729_ = select(_e1802.z, _e1802.y, _e1814);
                                }
                                let _e1825 = phi_19731_;
                                let _e1827 = phi_19729_;
                                if (_e1827 <= 0f) {
                                    phi_19755_ = 1f;
                                    break;
                                }
                                local_38 = array<vec3<f32>, 6>(vec3<f32>(0f, 0f, 1f), vec3<f32>(0f, 0f, -1f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(1f, 0f, 0f));
                                let _e1830 = local_38[_e1825];
                                local_39 = array<vec3<f32>, 6>(vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 0f, -1f), vec3<f32>(0f, 0f, 1f), vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 1f, 0f));
                                let _e1833 = local_39[_e1825];
                                let _e1838 = global.member_24[2u];
                                let _e1841 = (vec2<f32>(dot(_e1801, _e1830), dot(_e1801, _e1833)) / vec2((_e1827 * _e1838)));
                                let _e1845 = (_e1783.z + (_e1783.w / _e1827));
                                if (_e1845 > 1f) {
                                    phi_19755_ = 1f;
                                    break;
                                }
                                let _e1860 = global.member_24;
                                let _e1861 = _e1860.xy;
                                let _e1863 = (_e1783.xy + (vec2<f32>(f32((_e1825 - (i32(floor((f32(_e1825) / f32(3i)))) * 3i))), f32((_e1825 / 3i))) * _e1861));
                                let _e1872 = global.member_22;
                                let _e1873 = _e1872.xy;
                                let _e1874 = (_e1873 * 0.5f);
                                let _e1876 = (_e1863 + (vec2<f32>((0.5f + (0.5f * _e1841.x)), (0.5f - (0.5f * _e1841.y))) * _e1861));
                                let _e1877 = (_e1863 + _e1874);
                                let _e1879 = ((_e1863 + _e1861) - _e1874);
                                let _e1884 = vec4<f32>(_e1877.x, _e1877.y, _e1879.x, _e1879.y);
                                switch bitcast<i32>(0u) {
                                    default: {
                                        let _e1888 = global.member_22[2u];
                                        let _e1889 = i32(_e1888);
                                        if (_e1889 <= 0i) {
                                            let _e1893 = clamp(_e1876, _e1884.xy, _e1884.zw);
                                            let _e1898 = textureSampleCompare(global_2, global_1, vec3<f32>(_e1893.x, _e1893.y, _e1845).xy, _e1845);
                                            phi_19743_ = _e1898;
                                            break;
                                        }
                                        let _e1900 = ((_e1876 / _e1873) + vec2<f32>(0.5f, 0.5f));
                                        let _e1901 = floor(_e1900);
                                        let _e1902 = (_e1900 - _e1901);
                                        let _e1904 = (_e1889 == 1i);
                                        if _e1904 {
                                            let _e1905 = (_e1902 * 2f);
                                            local_34[0i] = (vec2<f32>(3f, 3f) - _e1905);
                                            local_34[1i] = (vec2<f32>(1f, 1f) + _e1905);
                                            let _e1911 = local_34[0i];
                                            local_35[0i] = (((vec2<f32>(2f, 2f) - _e1902) / _e1911) - vec2<f32>(1f, 1f));
                                            let _e1915 = local_34[1i];
                                            local_35[1i] = ((_e1902 / _e1915) + vec2<f32>(1f, 1f));
                                        } else {
                                            let _e1919 = (_e1902 * 3f);
                                            local_34[0i] = (vec2<f32>(4f, 4f) - _e1919);
                                            local_34[1i] = vec2<f32>(7f, 7f);
                                            local_34[2i] = (vec2<f32>(1f, 1f) + _e1919);
                                            let _e1927 = local_34[0i];
                                            local_35[0i] = (((vec2<f32>(3f, 3f) - (_e1902 * 2f)) / _e1927) - vec2<f32>(2f, 2f));
                                            let _e1932 = local_34[1i];
                                            local_35[1i] = ((vec2<f32>(3f, 3f) + _e1902) / _e1932);
                                            let _e1935 = local_34[2i];
                                            local_35[2i] = ((_e1902 / _e1935) + vec2<f32>(2f, 2f));
                                        }
                                        let _e1940 = select(3i, 2i, _e1904);
                                        phi_19736_ = 0f;
                                        phi_19733_ = 0i;
                                        loop {
                                            let _e1942 = phi_19736_;
                                            let _e1944 = phi_19733_;
                                            local_61 = _e1942;
                                            if (_e1944 < _e1940) {
                                                phi_19742_ = _e1942;
                                                phi_19739_ = 0i;
                                                loop {
                                                    let _e1947 = phi_19742_;
                                                    let _e1949 = phi_19739_;
                                                    local_95 = _e1947;
                                                    if (_e1949 < _e1940) {
                                                        continue;
                                                    } else {
                                                        break;
                                                    }
                                                    continuing {
                                                        let _e1953 = local_35[_e1949][0u];
                                                        let _e1956 = local_35[_e1944][1u];
                                                        let _e1962 = clamp((_e1873 * ((_e1901 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e1953, _e1956))), _e1884.xy, _e1884.zw);
                                                        let _e1965 = local_34[_e1949][0u];
                                                        let _e1968 = local_34[_e1944][1u];
                                                        let _e1974 = textureSampleCompare(global_2, global_1, vec3<f32>(_e1962.x, _e1962.y, _e1845).xy, _e1845);
                                                        phi_19742_ = (_e1947 + ((_e1965 * _e1968) * _e1974));
                                                        phi_19739_ = (_e1949 + 1i);
                                                    }
                                                }
                                                continue;
                                            } else {
                                                break;
                                            }
                                            continuing {
                                                let _e7251 = local_95;
                                                phi_19736_ = _e7251;
                                                phi_19733_ = (_e1944 + 1i);
                                            }
                                        }
                                        let _e1980 = local_61;
                                        phi_19743_ = (_e1980 * select(0.0069444445f, 0.0625f, _e1904));
                                        break;
                                    }
                                }
                                let _e1983 = phi_19743_;
                                phi_19755_ = _e1983;
                                break;
                            }
                        }
                        let _e1985 = phi_19755_;
                        phi_19809_ = (_e1588 * _e1985);
                    }
                    let _e1988 = phi_19809_;
                    let _e1989 = dot(_e913, _e1567);
                    local_93 = (_e1535 + (((_e1346 * max(_e1989, 0f)) * _e1988) + (_e1988 * ((pow(max(dot(_e913, normalize((_e1567 + _e923))), 0f), _e1384) * _e1388) * step(0f, _e1989)))));
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e7231 = local_93;
                    phi_19406_ = _e7231;
                    phi_19403_ = (_e1537 + bitcast<u32>(1i));
                }
            }
            let _e7261 = local_96;
            phi_19405_ = _e7261;
        }
        let _e2007 = phi_19405_;
        phi_19544_ = vec3<f32>(0f, 0f, 0f);
        phi_19404_ = _e2007;
    } else {
        let _e2008 = textureSample(global_26, global_4, _e392);
        let _e2011 = global_7.member_4[0u];
        let _e2014 = clamp((_e2011 * _e2008.z), 0f, 1f);
        let _e2017 = global_7.member_4[1u];
        let _e2020 = clamp((_e2017 * _e2008.y), 0.045f, 1f);
        phi_18806_ = _e2014;
        phi_18805_ = _e2020;
        if (_e830 > 0f) {
            phi_18806_ = mix(_e2014, _e828.y, _e830);
            phi_18805_ = mix(_e2020, max(_e828.x, 0.045f), _e830);
        }
        let _e2028 = phi_18806_;
        let _e2030 = phi_18805_;
        let _e2033 = global_18.member_1[2u];
        if (_e2033 > 0.5f) {
            let _e2036 = ((_e378 - vec2<f32>(0.5f, 0.5f)) * 2f);
            let _e2037 = length(_e2036);
            let _e2040 = global_18.member_4[3u];
            let _e2043 = global_18.member_5[3u];
            let _e2044 = (_e2037 > 1f);
            if _e2044 {
                phi_19296_ = (_e2036 / vec2(_e2037));
            } else {
                phi_19296_ = _e2036;
            }
            let _e2048 = phi_19296_;
            switch bitcast<i32>(0u) {
                default: {
                    let _e2052 = asin(min(length(_e2048), 1f));
                    let _e2054 = asin(clamp(_e2040, 0.05f, 0.95f));
                    let _e2056 = min((_e2052 / _e2054), 1f);
                    let _e2058 = (1f - (_e2056 * _e2056));
                    let _e2064 = atan2(_e2048.y, (_e2048.x + 0.000000001f));
                    let _e2065 = sin(_e2052);
                    let _e2066 = cos(_e2064);
                    let _e2068 = sin(_e2064);
                    let _e2070 = cos(_e2052);
                    let _e2071 = vec3<f32>((_e2065 * _e2066), (_e2065 * _e2068), _e2070);
                    let _e2072 = (1f + ((0.08f * _e2058) * _e2058));
                    let _e2073 = (_e2071 * _e2072);
                    local_62 = _e2073;
                    local_63 = _e2073;
                    local_64 = _e2073;
                    local_65 = _e2073;
                    if (_e2052 >= _e2054) {
                        phi_19297_ = _e2071;
                        break;
                    }
                    phi_19297_ = normalize((_e2071 + ((vec3<f32>((_e2070 * _e2066), (_e2070 * _e2068), -(_e2065)) * (((0.32f * _e2056) * _e2058) / _e2054)) / vec3(_e2072))));
                    break;
                }
            }
            let _e2088 = phi_19297_;
            phi_19298_ = _e2088;
            if _e2044 {
                phi_19298_ = vec3<f32>(_e2088.x, _e2088.y, -(_e2088.z));
            }
            let _e2095 = phi_19298_;
            let _e2096 = global_9;
            let _e2097 = _e2096.xyz;
            if (dot(_e2097, _e2097) < 0.000000000001f) {
                let _e2102 = normalize((cross(_e928, vec3<f32>(1f, 0f, 0f)) + vec3<f32>(0f, 0.0001f, 0f)));
                phi_19303_ = _e928;
                phi_19302_ = _e2102;
                phi_19301_ = cross(_e2102, _e928);
            } else {
                let _e2104 = normalize(_e2097);
                let _e2107 = (_e928 - (_e2104 * _e2095.x));
                let _e2108 = length(_e2107);
                let _e2109 = _e2095.yz;
                let _e2113 = (_e2109 / vec2(max(length(_e2109), 0.000001f)));
                if (_e2108 > 0.000001f) {
                    phi_19299_ = (_e2107 / vec3(_e2108));
                } else {
                    phi_19299_ = _e928;
                }
                let _e2118 = phi_19299_;
                let _e2119 = cross(_e2104, _e2118);
                phi_19303_ = ((_e2118 * _e2113.y) + (_e2119 * _e2113.x));
                phi_19302_ = ((_e2118 * _e2113.x) - (_e2119 * _e2113.y));
                phi_19301_ = _e2104;
            }
            let _e2129 = phi_19303_;
            let _e2131 = phi_19302_;
            let _e2133 = phi_19301_;
            let _e2140 = global_18.member_6[2u];
            let _e2141 = (1.08f - _e2140);
            let _e2142 = (_e2037 < 1f);
            phi_7805_ = _e2142;
            if _e2142 {
                let _e2144 = local_62;
                phi_7805_ = (_e2144.z > _e2141);
            }
            let _e2148 = phi_7805_;
            if _e2148 {
                let _e2150 = refract(-(vec3<f32>(dot(_e923, _e2133), dot(_e923, _e2131), dot(_e923, _e2129))), _e2095, 0.74850297f);
                phi_19307_ = _e2036;
                if (_e2150.z < -0.001f) {
                    let _e2154 = local_63;
                    let _e2160 = local_65;
                    phi_19307_ = (_e2154.xy + (_e2150.xy * ((_e2141 - _e2160.z) / _e2150.z)));
                }
                let _e2167 = phi_19307_;
                let _e2170 = length(_e2167);
                let _e2171 = smoothstep((_e2040 - 0.035f), (_e2040 + 0.015f), _e2170);
                let _e2173 = global_18.member_4;
                let _e2174 = _e2173.xyz;
                let _e2175 = (_e2170 / _e2040);
                let _e2179 = atan2(_e2167.y, (_e2167.x + 0.000000001f));
                let _e2182 = vec2<f32>(cos(_e2179), sin(_e2179));
                let _e2183 = (_e2182 * 26f);
                let _e2187 = vec3<f32>(_e2183.x, _e2183.y, (_e2175 * 2.2f));
                let _e2188 = floor(_e2187);
                let _e2189 = (_e2187 - _e2188);
                let _e2193 = ((_e2189 * _e2189) * (vec3<f32>(3f, 3f, 3f) - (_e2189 * 2f)));
                let _e2195 = bitcast<vec3<u32>>(vec3<i32>(_e2188));
                let _e2204 = ((((_e2195.x * 1597334677u) ^ (_e2195.y * 3812015801u)) ^ (_e2195.z * 2798796415u)) * 1597334677u);
                let _e2213 = bitcast<vec3<u32>>(vec3<i32>((_e2188 + vec3<f32>(1f, 0f, 0f))));
                let _e2222 = ((((_e2213.x * 1597334677u) ^ (_e2213.y * 3812015801u)) ^ (_e2213.z * 2798796415u)) * 1597334677u);
                let _e2233 = bitcast<vec3<u32>>(vec3<i32>((_e2188 + vec3<f32>(0f, 1f, 0f))));
                let _e2242 = ((((_e2233.x * 1597334677u) ^ (_e2233.y * 3812015801u)) ^ (_e2233.z * 2798796415u)) * 1597334677u);
                let _e2251 = bitcast<vec3<u32>>(vec3<i32>((_e2188 + vec3<f32>(1f, 1f, 0f))));
                let _e2260 = ((((_e2251.x * 1597334677u) ^ (_e2251.y * 3812015801u)) ^ (_e2251.z * 2798796415u)) * 1597334677u);
                let _e2272 = bitcast<vec3<u32>>(vec3<i32>((_e2188 + vec3<f32>(0f, 0f, 1f))));
                let _e2281 = ((((_e2272.x * 1597334677u) ^ (_e2272.y * 3812015801u)) ^ (_e2272.z * 2798796415u)) * 1597334677u);
                let _e2290 = bitcast<vec3<u32>>(vec3<i32>((_e2188 + vec3<f32>(1f, 0f, 1f))));
                let _e2299 = ((((_e2290.x * 1597334677u) ^ (_e2290.y * 3812015801u)) ^ (_e2290.z * 2798796415u)) * 1597334677u);
                let _e2309 = bitcast<vec3<u32>>(vec3<i32>((_e2188 + vec3<f32>(0f, 1f, 1f))));
                let _e2318 = ((((_e2309.x * 1597334677u) ^ (_e2309.y * 3812015801u)) ^ (_e2309.z * 2798796415u)) * 1597334677u);
                let _e2327 = bitcast<vec3<u32>>(vec3<i32>((_e2188 + vec3<f32>(1f, 1f, 1f))));
                let _e2336 = ((((_e2327.x * 1597334677u) ^ (_e2327.y * 3812015801u)) ^ (_e2327.z * 2798796415u)) * 1597334677u);
                let _e2348 = (_e2182 * 61f);
                let _e2353 = vec3<f32>(_e2348.x, _e2348.y, ((_e2175 * 4f) + 7f));
                let _e2354 = floor(_e2353);
                let _e2355 = (_e2353 - _e2354);
                let _e2359 = ((_e2355 * _e2355) * (vec3<f32>(3f, 3f, 3f) - (_e2355 * 2f)));
                let _e2361 = bitcast<vec3<u32>>(vec3<i32>(_e2354));
                let _e2370 = ((((_e2361.x * 1597334677u) ^ (_e2361.y * 3812015801u)) ^ (_e2361.z * 2798796415u)) * 1597334677u);
                let _e2379 = bitcast<vec3<u32>>(vec3<i32>((_e2354 + vec3<f32>(1f, 0f, 0f))));
                let _e2388 = ((((_e2379.x * 1597334677u) ^ (_e2379.y * 3812015801u)) ^ (_e2379.z * 2798796415u)) * 1597334677u);
                let _e2399 = bitcast<vec3<u32>>(vec3<i32>((_e2354 + vec3<f32>(0f, 1f, 0f))));
                let _e2408 = ((((_e2399.x * 1597334677u) ^ (_e2399.y * 3812015801u)) ^ (_e2399.z * 2798796415u)) * 1597334677u);
                let _e2417 = bitcast<vec3<u32>>(vec3<i32>((_e2354 + vec3<f32>(1f, 1f, 0f))));
                let _e2426 = ((((_e2417.x * 1597334677u) ^ (_e2417.y * 3812015801u)) ^ (_e2417.z * 2798796415u)) * 1597334677u);
                let _e2438 = bitcast<vec3<u32>>(vec3<i32>((_e2354 + vec3<f32>(0f, 0f, 1f))));
                let _e2447 = ((((_e2438.x * 1597334677u) ^ (_e2438.y * 3812015801u)) ^ (_e2438.z * 2798796415u)) * 1597334677u);
                let _e2456 = bitcast<vec3<u32>>(vec3<i32>((_e2354 + vec3<f32>(1f, 0f, 1f))));
                let _e2465 = ((((_e2456.x * 1597334677u) ^ (_e2456.y * 3812015801u)) ^ (_e2456.z * 2798796415u)) * 1597334677u);
                let _e2475 = bitcast<vec3<u32>>(vec3<i32>((_e2354 + vec3<f32>(0f, 1f, 1f))));
                let _e2484 = ((((_e2475.x * 1597334677u) ^ (_e2475.y * 3812015801u)) ^ (_e2475.z * 2798796415u)) * 1597334677u);
                let _e2493 = bitcast<vec3<u32>>(vec3<i32>((_e2354 + vec3<f32>(1f, 1f, 1f))));
                let _e2502 = ((((_e2493.x * 1597334677u) ^ (_e2493.y * 3812015801u)) ^ (_e2493.z * 2798796415u)) * 1597334677u);
                let _e2515 = (_e2182 * 9f);
                let _e2520 = vec3<f32>(_e2515.x, _e2515.y, ((_e2175 * 7f) + 3f));
                let _e2521 = floor(_e2520);
                let _e2522 = (_e2520 - _e2521);
                let _e2526 = ((_e2522 * _e2522) * (vec3<f32>(3f, 3f, 3f) - (_e2522 * 2f)));
                let _e2528 = bitcast<vec3<u32>>(vec3<i32>(_e2521));
                let _e2537 = ((((_e2528.x * 1597334677u) ^ (_e2528.y * 3812015801u)) ^ (_e2528.z * 2798796415u)) * 1597334677u);
                let _e2546 = bitcast<vec3<u32>>(vec3<i32>((_e2521 + vec3<f32>(1f, 0f, 0f))));
                let _e2555 = ((((_e2546.x * 1597334677u) ^ (_e2546.y * 3812015801u)) ^ (_e2546.z * 2798796415u)) * 1597334677u);
                let _e2566 = bitcast<vec3<u32>>(vec3<i32>((_e2521 + vec3<f32>(0f, 1f, 0f))));
                let _e2575 = ((((_e2566.x * 1597334677u) ^ (_e2566.y * 3812015801u)) ^ (_e2566.z * 2798796415u)) * 1597334677u);
                let _e2584 = bitcast<vec3<u32>>(vec3<i32>((_e2521 + vec3<f32>(1f, 1f, 0f))));
                let _e2593 = ((((_e2584.x * 1597334677u) ^ (_e2584.y * 3812015801u)) ^ (_e2584.z * 2798796415u)) * 1597334677u);
                let _e2605 = bitcast<vec3<u32>>(vec3<i32>((_e2521 + vec3<f32>(0f, 0f, 1f))));
                let _e2614 = ((((_e2605.x * 1597334677u) ^ (_e2605.y * 3812015801u)) ^ (_e2605.z * 2798796415u)) * 1597334677u);
                let _e2623 = bitcast<vec3<u32>>(vec3<i32>((_e2521 + vec3<f32>(1f, 0f, 1f))));
                let _e2632 = ((((_e2623.x * 1597334677u) ^ (_e2623.y * 3812015801u)) ^ (_e2623.z * 2798796415u)) * 1597334677u);
                let _e2642 = bitcast<vec3<u32>>(vec3<i32>((_e2521 + vec3<f32>(0f, 1f, 1f))));
                let _e2651 = ((((_e2642.x * 1597334677u) ^ (_e2642.y * 3812015801u)) ^ (_e2642.z * 2798796415u)) * 1597334677u);
                let _e2660 = bitcast<vec3<u32>>(vec3<i32>((_e2521 + vec3<f32>(1f, 1f, 1f))));
                let _e2669 = ((((_e2660.x * 1597334677u) ^ (_e2660.y * 3812015801u)) ^ (_e2660.z * 2798796415u)) * 1597334677u);
                let _e2699 = global_18.member_6[0u];
                let _e2711 = global_18.member_5;
                let _e2719 = (_e2036 / vec2(max(_e2037, 0.0001f)));
                let _e2720 = (_e2719 * 6f);
                let _e2725 = vec3<f32>(_e2720.x, _e2720.y, ((_e2037 * 2.2f) + 1.7f));
                let _e2726 = floor(_e2725);
                let _e2727 = (_e2725 - _e2726);
                let _e2731 = ((_e2727 * _e2727) * (vec3<f32>(3f, 3f, 3f) - (_e2727 * 2f)));
                let _e2733 = bitcast<vec3<u32>>(vec3<i32>(_e2726));
                let _e2742 = ((((_e2733.x * 1597334677u) ^ (_e2733.y * 3812015801u)) ^ (_e2733.z * 2798796415u)) * 1597334677u);
                let _e2751 = bitcast<vec3<u32>>(vec3<i32>((_e2726 + vec3<f32>(1f, 0f, 0f))));
                let _e2760 = ((((_e2751.x * 1597334677u) ^ (_e2751.y * 3812015801u)) ^ (_e2751.z * 2798796415u)) * 1597334677u);
                let _e2771 = bitcast<vec3<u32>>(vec3<i32>((_e2726 + vec3<f32>(0f, 1f, 0f))));
                let _e2780 = ((((_e2771.x * 1597334677u) ^ (_e2771.y * 3812015801u)) ^ (_e2771.z * 2798796415u)) * 1597334677u);
                let _e2789 = bitcast<vec3<u32>>(vec3<i32>((_e2726 + vec3<f32>(1f, 1f, 0f))));
                let _e2798 = ((((_e2789.x * 1597334677u) ^ (_e2789.y * 3812015801u)) ^ (_e2789.z * 2798796415u)) * 1597334677u);
                let _e2810 = bitcast<vec3<u32>>(vec3<i32>((_e2726 + vec3<f32>(0f, 0f, 1f))));
                let _e2819 = ((((_e2810.x * 1597334677u) ^ (_e2810.y * 3812015801u)) ^ (_e2810.z * 2798796415u)) * 1597334677u);
                let _e2828 = bitcast<vec3<u32>>(vec3<i32>((_e2726 + vec3<f32>(1f, 0f, 1f))));
                let _e2837 = ((((_e2828.x * 1597334677u) ^ (_e2828.y * 3812015801u)) ^ (_e2828.z * 2798796415u)) * 1597334677u);
                let _e2847 = bitcast<vec3<u32>>(vec3<i32>((_e2726 + vec3<f32>(0f, 1f, 1f))));
                let _e2856 = ((((_e2847.x * 1597334677u) ^ (_e2847.y * 3812015801u)) ^ (_e2847.z * 2798796415u)) * 1597334677u);
                let _e2865 = bitcast<vec3<u32>>(vec3<i32>((_e2726 + vec3<f32>(1f, 1f, 1f))));
                let _e2874 = ((((_e2865.x * 1597334677u) ^ (_e2865.y * 3812015801u)) ^ (_e2865.z * 2798796415u)) * 1597334677u);
                let _e2885 = (_e2719 * 15f);
                let _e2890 = vec3<f32>(_e2885.x, _e2885.y, ((_e2037 * 5f) + 9.3f));
                let _e2891 = floor(_e2890);
                let _e2892 = (_e2890 - _e2891);
                let _e2896 = ((_e2892 * _e2892) * (vec3<f32>(3f, 3f, 3f) - (_e2892 * 2f)));
                let _e2898 = bitcast<vec3<u32>>(vec3<i32>(_e2891));
                let _e2907 = ((((_e2898.x * 1597334677u) ^ (_e2898.y * 3812015801u)) ^ (_e2898.z * 2798796415u)) * 1597334677u);
                let _e2916 = bitcast<vec3<u32>>(vec3<i32>((_e2891 + vec3<f32>(1f, 0f, 0f))));
                let _e2925 = ((((_e2916.x * 1597334677u) ^ (_e2916.y * 3812015801u)) ^ (_e2916.z * 2798796415u)) * 1597334677u);
                let _e2936 = bitcast<vec3<u32>>(vec3<i32>((_e2891 + vec3<f32>(0f, 1f, 0f))));
                let _e2945 = ((((_e2936.x * 1597334677u) ^ (_e2936.y * 3812015801u)) ^ (_e2936.z * 2798796415u)) * 1597334677u);
                let _e2954 = bitcast<vec3<u32>>(vec3<i32>((_e2891 + vec3<f32>(1f, 1f, 0f))));
                let _e2963 = ((((_e2954.x * 1597334677u) ^ (_e2954.y * 3812015801u)) ^ (_e2954.z * 2798796415u)) * 1597334677u);
                let _e2975 = bitcast<vec3<u32>>(vec3<i32>((_e2891 + vec3<f32>(0f, 0f, 1f))));
                let _e2984 = ((((_e2975.x * 1597334677u) ^ (_e2975.y * 3812015801u)) ^ (_e2975.z * 2798796415u)) * 1597334677u);
                let _e2993 = bitcast<vec3<u32>>(vec3<i32>((_e2891 + vec3<f32>(1f, 0f, 1f))));
                let _e3002 = ((((_e2993.x * 1597334677u) ^ (_e2993.y * 3812015801u)) ^ (_e2993.z * 2798796415u)) * 1597334677u);
                let _e3012 = bitcast<vec3<u32>>(vec3<i32>((_e2891 + vec3<f32>(0f, 1f, 1f))));
                let _e3021 = ((((_e3012.x * 1597334677u) ^ (_e3012.y * 3812015801u)) ^ (_e3012.z * 2798796415u)) * 1597334677u);
                let _e3030 = bitcast<vec3<u32>>(vec3<i32>((_e2891 + vec3<f32>(1f, 1f, 1f))));
                let _e3039 = ((((_e3030.x * 1597334677u) ^ (_e3030.y * 3812015801u)) ^ (_e3030.z * 2798796415u)) * 1597334677u);
                let _e3069 = global_18.member_6[1u];
                phi_19314_ = _e2171;
                phi_19312_ = (1f - _e2171);
                phi_19308_ = mix(mix(vec3<f32>(0.004f, 0.004f, 0.004f), (mix(((_e2174 * (0.45f + (1.1f * ((mix(mix(mix((f32(((_e2204 ^ (_e2204 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e2222 ^ (_e2222 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e2193.x), mix((f32(((_e2242 ^ (_e2242 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e2260 ^ (_e2260 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e2193.x), _e2193.y), mix(mix((f32(((_e2281 ^ (_e2281 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e2299 ^ (_e2299 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e2193.x), mix((f32(((_e2318 ^ (_e2318 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e2336 ^ (_e2336 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e2193.x), _e2193.y), _e2193.z) * 0.65f) + (mix(mix(mix((f32(((_e2370 ^ (_e2370 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e2388 ^ (_e2388 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e2359.x), mix((f32(((_e2408 ^ (_e2408 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e2426 ^ (_e2426 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e2359.x), _e2359.y), mix(mix((f32(((_e2447 ^ (_e2447 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e2465 ^ (_e2465 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e2359.x), mix((f32(((_e2484 ^ (_e2484 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e2502 ^ (_e2502 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e2359.x), _e2359.y), _e2359.z) * 0.35f))))) * mix(0.55f, 1f, smoothstep(0.25f, 0.55f, mix(mix(mix((f32(((_e2537 ^ (_e2537 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e2555 ^ (_e2555 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e2526.x), mix((f32(((_e2575 ^ (_e2575 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e2593 ^ (_e2593 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e2526.x), _e2526.y), mix(mix((f32(((_e2614 ^ (_e2614 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e2632 ^ (_e2632 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e2526.x), mix((f32(((_e2651 ^ (_e2651 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e2669 ^ (_e2669 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e2526.x), _e2526.y), _e2526.z)))), ((_e2174 * 1.7f) + vec3<f32>(0.05f, 0.035f, 0f)), vec3((exp(-(pow(((_e2175 - (_e2043 + 0.17f)) * 11.111111f), 2f))) * 0.55f))) * (1f - ((_e2699 * 0.85f) * smoothstep(0.72f, 1f, _e2175)))), vec3(smoothstep((_e2043 - 0.025f), (_e2043 + 0.025f), _e2175))), (mix((_e2711.xyz * mix(vec3<f32>(1f, 1f, 1f), vec3<f32>(1.02f, 0.86f, 0.82f), vec3(smoothstep(0.45f, 1f, _e2037)))), vec3<f32>(0.5f, 0.07f, 0.06f), vec3(clamp(((((pow((1f - abs(((2f * mix(mix(mix((f32(((_e2742 ^ (_e2742 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e2760 ^ (_e2760 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e2731.x), mix((f32(((_e2780 ^ (_e2780 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e2798 ^ (_e2798 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e2731.x), _e2731.y), mix(mix((f32(((_e2819 ^ (_e2819 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e2837 ^ (_e2837 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e2731.x), mix((f32(((_e2856 ^ (_e2856 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e2874 ^ (_e2874 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e2731.x), _e2731.y), _e2731.z)) - 1f))), 24f) + ((0.5f * pow((1f - abs(((2f * mix(mix(mix((f32(((_e2907 ^ (_e2907 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e2925 ^ (_e2925 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e2896.x), mix((f32(((_e2945 ^ (_e2945 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e2963 ^ (_e2963 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e2896.x), _e2896.y), mix(mix((f32(((_e2984 ^ (_e2984 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e3002 ^ (_e3002 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e2896.x), mix((f32(((_e3021 ^ (_e3021 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e3039 ^ (_e3039 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e2896.x), _e2896.y), _e2896.z)) - 1f))), 30f)) * smoothstep(0.6f, 0.9f, _e2037))) * smoothstep((_e2040 + 0.08f), 0.95f, _e2037)) * _e3069) * 1.4f), 0f, 0.8f))) * (1f - (0.6f * _e2699))), vec3(_e2171));
            } else {
                let _e3082 = global_18.member_5;
                let _e3090 = (_e2036 / vec2(max(_e2037, 0.0001f)));
                let _e3091 = (_e3090 * 6f);
                let _e3096 = vec3<f32>(_e3091.x, _e3091.y, ((_e2037 * 2.2f) + 1.7f));
                let _e3097 = floor(_e3096);
                let _e3098 = (_e3096 - _e3097);
                let _e3102 = ((_e3098 * _e3098) * (vec3<f32>(3f, 3f, 3f) - (_e3098 * 2f)));
                let _e3104 = bitcast<vec3<u32>>(vec3<i32>(_e3097));
                let _e3113 = ((((_e3104.x * 1597334677u) ^ (_e3104.y * 3812015801u)) ^ (_e3104.z * 2798796415u)) * 1597334677u);
                let _e3122 = bitcast<vec3<u32>>(vec3<i32>((_e3097 + vec3<f32>(1f, 0f, 0f))));
                let _e3131 = ((((_e3122.x * 1597334677u) ^ (_e3122.y * 3812015801u)) ^ (_e3122.z * 2798796415u)) * 1597334677u);
                let _e3142 = bitcast<vec3<u32>>(vec3<i32>((_e3097 + vec3<f32>(0f, 1f, 0f))));
                let _e3151 = ((((_e3142.x * 1597334677u) ^ (_e3142.y * 3812015801u)) ^ (_e3142.z * 2798796415u)) * 1597334677u);
                let _e3160 = bitcast<vec3<u32>>(vec3<i32>((_e3097 + vec3<f32>(1f, 1f, 0f))));
                let _e3169 = ((((_e3160.x * 1597334677u) ^ (_e3160.y * 3812015801u)) ^ (_e3160.z * 2798796415u)) * 1597334677u);
                let _e3181 = bitcast<vec3<u32>>(vec3<i32>((_e3097 + vec3<f32>(0f, 0f, 1f))));
                let _e3190 = ((((_e3181.x * 1597334677u) ^ (_e3181.y * 3812015801u)) ^ (_e3181.z * 2798796415u)) * 1597334677u);
                let _e3199 = bitcast<vec3<u32>>(vec3<i32>((_e3097 + vec3<f32>(1f, 0f, 1f))));
                let _e3208 = ((((_e3199.x * 1597334677u) ^ (_e3199.y * 3812015801u)) ^ (_e3199.z * 2798796415u)) * 1597334677u);
                let _e3218 = bitcast<vec3<u32>>(vec3<i32>((_e3097 + vec3<f32>(0f, 1f, 1f))));
                let _e3227 = ((((_e3218.x * 1597334677u) ^ (_e3218.y * 3812015801u)) ^ (_e3218.z * 2798796415u)) * 1597334677u);
                let _e3236 = bitcast<vec3<u32>>(vec3<i32>((_e3097 + vec3<f32>(1f, 1f, 1f))));
                let _e3245 = ((((_e3236.x * 1597334677u) ^ (_e3236.y * 3812015801u)) ^ (_e3236.z * 2798796415u)) * 1597334677u);
                let _e3256 = (_e3090 * 15f);
                let _e3261 = vec3<f32>(_e3256.x, _e3256.y, ((_e2037 * 5f) + 9.3f));
                let _e3262 = floor(_e3261);
                let _e3263 = (_e3261 - _e3262);
                let _e3267 = ((_e3263 * _e3263) * (vec3<f32>(3f, 3f, 3f) - (_e3263 * 2f)));
                let _e3269 = bitcast<vec3<u32>>(vec3<i32>(_e3262));
                let _e3278 = ((((_e3269.x * 1597334677u) ^ (_e3269.y * 3812015801u)) ^ (_e3269.z * 2798796415u)) * 1597334677u);
                let _e3287 = bitcast<vec3<u32>>(vec3<i32>((_e3262 + vec3<f32>(1f, 0f, 0f))));
                let _e3296 = ((((_e3287.x * 1597334677u) ^ (_e3287.y * 3812015801u)) ^ (_e3287.z * 2798796415u)) * 1597334677u);
                let _e3307 = bitcast<vec3<u32>>(vec3<i32>((_e3262 + vec3<f32>(0f, 1f, 0f))));
                let _e3316 = ((((_e3307.x * 1597334677u) ^ (_e3307.y * 3812015801u)) ^ (_e3307.z * 2798796415u)) * 1597334677u);
                let _e3325 = bitcast<vec3<u32>>(vec3<i32>((_e3262 + vec3<f32>(1f, 1f, 0f))));
                let _e3334 = ((((_e3325.x * 1597334677u) ^ (_e3325.y * 3812015801u)) ^ (_e3325.z * 2798796415u)) * 1597334677u);
                let _e3346 = bitcast<vec3<u32>>(vec3<i32>((_e3262 + vec3<f32>(0f, 0f, 1f))));
                let _e3355 = ((((_e3346.x * 1597334677u) ^ (_e3346.y * 3812015801u)) ^ (_e3346.z * 2798796415u)) * 1597334677u);
                let _e3364 = bitcast<vec3<u32>>(vec3<i32>((_e3262 + vec3<f32>(1f, 0f, 1f))));
                let _e3373 = ((((_e3364.x * 1597334677u) ^ (_e3364.y * 3812015801u)) ^ (_e3364.z * 2798796415u)) * 1597334677u);
                let _e3383 = bitcast<vec3<u32>>(vec3<i32>((_e3262 + vec3<f32>(0f, 1f, 1f))));
                let _e3392 = ((((_e3383.x * 1597334677u) ^ (_e3383.y * 3812015801u)) ^ (_e3383.z * 2798796415u)) * 1597334677u);
                let _e3401 = bitcast<vec3<u32>>(vec3<i32>((_e3262 + vec3<f32>(1f, 1f, 1f))));
                let _e3410 = ((((_e3401.x * 1597334677u) ^ (_e3401.y * 3812015801u)) ^ (_e3401.z * 2798796415u)) * 1597334677u);
                let _e3440 = global_18.member_6[1u];
                let _e3448 = global_18.member_6[0u];
                phi_19314_ = 1f;
                phi_19312_ = 0f;
                phi_19308_ = (mix((_e3082.xyz * mix(vec3<f32>(1f, 1f, 1f), vec3<f32>(1.02f, 0.86f, 0.82f), vec3(smoothstep(0.45f, 1f, _e2037)))), vec3<f32>(0.5f, 0.07f, 0.06f), vec3(clamp(((((pow((1f - abs(((2f * mix(mix(mix((f32(((_e3113 ^ (_e3113 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e3131 ^ (_e3131 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e3102.x), mix((f32(((_e3151 ^ (_e3151 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e3169 ^ (_e3169 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e3102.x), _e3102.y), mix(mix((f32(((_e3190 ^ (_e3190 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e3208 ^ (_e3208 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e3102.x), mix((f32(((_e3227 ^ (_e3227 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e3245 ^ (_e3245 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e3102.x), _e3102.y), _e3102.z)) - 1f))), 24f) + ((0.5f * pow((1f - abs(((2f * mix(mix(mix((f32(((_e3278 ^ (_e3278 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e3296 ^ (_e3296 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e3267.x), mix((f32(((_e3316 ^ (_e3316 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e3334 ^ (_e3334 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e3267.x), _e3267.y), mix(mix((f32(((_e3355 ^ (_e3355 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e3373 ^ (_e3373 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e3267.x), mix((f32(((_e3392 ^ (_e3392 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e3410 ^ (_e3410 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e3267.x), _e3267.y), _e3267.z)) - 1f))), 30f)) * smoothstep(0.6f, 0.9f, _e2037))) * smoothstep((_e2040 + 0.08f), 0.95f, _e2037)) * _e3440) * 1.4f), 0f, 0.8f))) * (1f - ((_e3448 * 0.35f) * (1f - smoothstep(_e2040, (_e2040 + 0.07f), _e2037)))));
            }
            let _e3457 = phi_19314_;
            let _e3459 = phi_19312_;
            let _e3461 = phi_19308_;
            let _e3478 = select((((1f - (0.65f * smoothstep(0.45f, 0.95f, abs(_e2036.x)))) * (1f - (0.45f * smoothstep(0.15f, 0.6f, _e2036.y)))) * (1f - (0.3f * smoothstep(0.25f, 0.7f, -(_e2036.y))))), 0.2f, _e2044);
            let _e3479 = mix(1f, _e3478, 0.6f);
            let _e3480 = dot(_e928, _e917);
            let _e3497 = mix(_e928, _e2129, vec3(_e3459));
            let _e3499 = reflect(-(_e923), _e928);
            let _e3502 = global.member_29[0u];
            let _e3503 = (_e3502 > 0.5f);
            if _e3503 {
                let _e3505 = global.member_29;
                let _e3512 = ((_e3505.z * _e3497.x) - (_e3505.w * _e3497.z));
                let _e3516 = ((_e3505.w * _e3497.x) + (_e3505.z * _e3497.z));
                let _e3520 = (1.092548f * _e3512);
                local_33 = array<f32, 9>(0.282095f, (0.488603f * _e3497.y), (0.488603f * _e3516), (0.488603f * _e3512), (_e3520 * _e3497.y), ((1.092548f * _e3497.y) * _e3516), (0.315392f * (((3f * _e3516) * _e3516) - 1f)), (_e3520 * _e3516), (0.546274f * ((_e3512 * _e3512) - (_e3497.y * _e3497.y))));
                phi_19317_ = vec3<f32>(0f, 0f, 0f);
                phi_19316_ = 0i;
                loop {
                    let _e3535 = phi_19317_;
                    let _e3537 = phi_19316_;
                    local_66 = _e3535;
                    if (_e3537 < 9i) {
                        continue;
                    } else {
                        break;
                    }
                    continuing {
                        let _e3541 = textureLoad(global_3, (vec2<i32>(496i, 256i) + vec2<i32>(_e3537, 0i)), 0i);
                        let _e3544 = local_33[_e3537];
                        phi_19317_ = (_e3535 + (_e3541.xyz * _e3544));
                        phi_19316_ = (_e3537 + 1i);
                    }
                }
                let _e3549 = local_66;
                let _e3553 = global.member_29[1u];
                let _e3571 = vec2<f32>(((atan2(((_e3505.z * _e3499.x) - (_e3505.w * _e3499.z)), -(((_e3505.w * _e3499.x) + (_e3505.z * _e3499.z)))) * 0.15915494f) + 0.5f), (acos(clamp(_e3499.y, -1f, 1f)) * 0.31830987f));
                let _e3573 = ((_e3571 * vec2<f32>(512f, 256f)) - vec2<f32>(0.5f, 0.5f));
                let _e3574 = floor(_e3573);
                let _e3575 = (_e3573 - _e3574);
                let _e3577 = i32(_e3574.x);
                let _e3579 = i32(_e3574.y);
                phi_19318_ = _e3577;
                if (_e3577 < 0i) {
                    phi_19318_ = (_e3577 + 512i);
                }
                let _e3583 = phi_19318_;
                phi_19319_ = _e3583;
                if (_e3583 >= 512i) {
                    phi_19319_ = (_e3583 - 512i);
                }
                let _e3587 = phi_19319_;
                let _e3588 = (_e3587 + 1i);
                let _e3590 = select(_e3588, 0i, (_e3588 == 512i));
                let _e3592 = min((_e3579 + 1i), 255i);
                let _e3593 = max(_e3579, 0i);
                let _e3595 = textureLoad(global_3, vec2<i32>(_e3587, _e3593), 0i);
                let _e3598 = textureLoad(global_3, vec2<i32>(_e3590, _e3593), 0i);
                let _e3601 = textureLoad(global_3, vec2<i32>(_e3587, _e3592), 0i);
                let _e3604 = textureLoad(global_3, vec2<i32>(_e3590, _e3592), 0i);
                let _e3607 = vec3(_e3575.x);
                let _e3614 = ((_e3571 * vec2<f32>(256f, 128f)) - vec2<f32>(0.5f, 0.5f));
                let _e3615 = floor(_e3614);
                let _e3616 = (_e3614 - _e3615);
                let _e3618 = i32(_e3615.x);
                let _e3620 = i32(_e3615.y);
                phi_19325_ = _e3618;
                if (_e3618 < 0i) {
                    phi_19325_ = (_e3618 + 256i);
                }
                let _e3624 = phi_19325_;
                phi_19326_ = _e3624;
                if (_e3624 >= 256i) {
                    phi_19326_ = (_e3624 - 256i);
                }
                let _e3628 = phi_19326_;
                let _e3629 = (_e3628 + 1i);
                let _e3631 = select(_e3629, 0i, (_e3629 == 256i));
                let _e3633 = min((_e3620 + 1i), 127i);
                let _e3634 = max(_e3620, 0i);
                let _e3637 = textureLoad(global_3, (vec2<i32>(0i, 256i) + vec2<i32>(_e3628, _e3634)), 0i);
                let _e3641 = textureLoad(global_3, (vec2<i32>(0i, 256i) + vec2<i32>(_e3631, _e3634)), 0i);
                let _e3645 = textureLoad(global_3, (vec2<i32>(0i, 256i) + vec2<i32>(_e3628, _e3633)), 0i);
                let _e3649 = textureLoad(global_3, (vec2<i32>(0i, 256i) + vec2<i32>(_e3631, _e3633)), 0i);
                let _e3652 = vec3(_e3616.x);
                phi_19339_ = (mix(mix(mix(_e3595.xyz, _e3598.xyz, _e3607), mix(_e3601.xyz, _e3604.xyz, _e3607), vec3(_e3575.y)), mix(mix(_e3637.xyz, _e3641.xyz, _e3652), mix(_e3645.xyz, _e3649.xyz, _e3652), vec3(_e3616.y)), vec3<f32>(0.35f, 0.35f, 0.35f)) * _e3553);
                phi_19332_ = (max(_e3549, vec3<f32>(0f, 0f, 0f)) * _e3553);
            } else {
                let _e3661 = global.member_9;
                let _e3662 = _e3661.xyz;
                let _e3664 = global.member_8;
                let _e3665 = _e3664.xyz;
                let _e3673 = global.member_8[3u];
                let _e3674 = (mix(_e3662, _e3665, vec3(((_e3497.y * 0.5f) + 0.5f))) * _e3673);
                phi_19339_ = mix((mix(_e3662, _e3665, vec3(((_e3499.y * 0.5f) + 0.5f))) * _e3673), _e3674, vec3<f32>(0.07f, 0.07f, 0.07f));
                phi_19332_ = _e3674;
            }
            let _e3683 = phi_19339_;
            let _e3685 = phi_19332_;
            let _e3688 = ((((vec3(((max(((dot(_e2129, _e917) * 0.65f) + (_e3480 * 0.35f)), 0f) * _e3459) + (max(((_e3480 + 0.3f) * 0.7692308f), 0f) * _e3457))) * _e1353) * _e1344) * _e3479) + ((_e3685 * _e1375) * _e3478));
            let _e3690 = max(dot(_e928, _e923), 0.0001f);
            let _e3691 = clamp(_e3480, 0f, 1f);
            let _e3699 = clamp(dot(_e928, _e925), 0f, 1f);
            let _e3702 = (((_e3699 * _e3699) * -0.999976f) + 1f);
            let _e3708 = sqrt((((_e3690 * _e3690) * 0.999976f) + 0.00002401f));
            let _e3724 = (((((((vec3<f32>(0.025f, 0.025f, 0.025f) + (vec3<f32>(0.975f, 0.975f, 0.975f) * pow((1f - clamp(dot(_e923, _e925), 0f, 1f)), 5f))) * (0.000012005f / (((3.1415927f * _e3702) * _e3702) * max(((_e3691 * _e3708) + (_e3690 * sqrt((((_e3691 * _e3691) * 0.999976f) + 0.00002401f)))), 0.00001f)))) * 3.1415927f) * _e3691) * _e1353) * _e1344) * _e3479);
            let _e3727 = global.member_13[3u];
            phi_19365_ = _e3688;
            phi_19351_ = _e3724;
            if (_e3727 > 0.5f) {
                let _e3730 = global.member_11;
                let _e3735 = global.member_11[3u];
                let _e3737 = global_15;
                let _e3740 = global.member_12;
                let _e3745 = global.member_13;
                let _e3748 = clamp(floor((_e3737.xy * _e3740.xy)), vec2<f32>(0f, 0f), (_e3745.xy - vec2<f32>(1f, 1f)));
                let _e3753 = global.member_12[2u];
                let _e3757 = global.member_12[3u];
                let _e3762 = global.member_13[2u];
                let _e3767 = global.member_13[1u];
                let _e3773 = global.member_13[0u];
                let _e3777 = u32(((((clamp(floor(((log2(max((dot(_e3730.xyz, _e921) + _e3735), 0.000001f)) * _e3753) + _e3757)), 0f, (_e3762 - 1f)) * _e3767) + _e3748.y) * _e3773) + _e3748.x));
                let _e3784 = global_16.member[(_e3777 >> bitcast<u32>(2i))][(_e3777 & 3u)];
                let _e3785 = (_e3784 & 65535u);
                phi_19366_ = _e3688;
                phi_19352_ = _e3724;
                phi_19348_ = _e3785;
                loop {
                    let _e3789 = phi_19366_;
                    let _e3791 = phi_19352_;
                    let _e3793 = phi_19348_;
                    local_97 = _e3789;
                    local_98 = _e3791;
                    if (_e3793 < (_e3785 + (_e3784 >> bitcast<u32>(16i)))) {
                        continue;
                    } else {
                        break;
                    }
                    continuing {
                        let _e3796 = (_e3793 / 3u);
                        let _e3803 = global_17.member[(_e3796 >> bitcast<u32>(2i))][(_e3796 & 3u)];
                        let _e3809 = ((_e3803 >> bitcast<u32>(((_e3793 - (_e3796 * 3u)) * 10u))) & 1023u);
                        let _e3812 = global_11.member[_e3809];
                        let _e3814 = (_e3812.xyz - _e921);
                        let _e3815 = dot(_e3814, _e3814);
                        let _e3817 = (_e3815 * _e3812.w);
                        let _e3820 = clamp((1f - (_e3817 * _e3817)), 0f, 1f);
                        let _e3823 = (_e3814 * inverseSqrt(max(_e3815, 0.00000001f)));
                        let _e3826 = global_13.member[_e3809];
                        let _e3829 = global_14.member[_e3809];
                        let _e3837 = clamp(((dot(-(_e3823), _e3829.xyz) * _e3826.w) + _e3829.w), 0f, 1f);
                        let _e3845 = ((_e3826.xyz * ((((_e3820 * _e3820) * _e3837) * _e3837) / max(_e3815, 0.0001f))) * _e3479);
                        let _e3846 = dot(_e928, _e3823);
                        let _e3862 = normalize((_e3823 + _e923));
                        let _e3863 = clamp(_e3846, 0f, 1f);
                        let _e3871 = clamp(dot(_e928, _e3862), 0f, 1f);
                        let _e3874 = (((_e3871 * _e3871) * -0.999976f) + 1f);
                        phi_19366_ = (_e3789 + (vec3(((max(((dot(_e2129, _e3823) * 0.65f) + (_e3846 * 0.35f)), 0f) * _e3459) + (max(((_e3846 + 0.3f) * 0.7692308f), 0f) * _e3457))) * _e3845));
                        phi_19352_ = (_e3791 + (((((vec3<f32>(0.025f, 0.025f, 0.025f) + (vec3<f32>(0.975f, 0.975f, 0.975f) * pow((1f - clamp(dot(_e923, _e3862), 0f, 1f)), 5f))) * (0.000012005f / (((3.1415927f * _e3874) * _e3874) * max(((_e3863 * _e3708) + (_e3690 * sqrt((((_e3863 * _e3863) * 0.999976f) + 0.00002401f)))), 0.00001f)))) * 3.1415927f) * _e3863) * _e3845));
                        phi_19348_ = (_e3793 + bitcast<u32>(1i));
                    }
                }
                let _e7294 = local_97;
                phi_19365_ = _e7294;
                let _e7297 = local_98;
                phi_19351_ = _e7297;
            }
            let _e3895 = phi_19365_;
            let _e3897 = phi_19351_;
            if _e3503 {
                let _e3902 = textureSample(global_5, global_6, (((vec2<f32>(_e3690, 0.07f) * 31f) + vec2<f32>(0.5f, 0.5f)) * vec2<f32>(0.03125f, 0.03125f)));
                phi_19349_ = _e3902.xy;
            } else {
                phi_19349_ = ((vec2<f32>(-1.04f, 1.04f) * ((min(0.8649f, exp2((-9.28f * _e3690))) * 0.93f) + 0.040575f)) + vec2<f32>(0.99995995f, -0.038459998f));
            }
            let _e3912 = phi_19349_;
            let _e3917 = ((vec3<f32>(0.025f, 0.025f, 0.025f) * _e3912.x) + vec3(_e3912.y));
            let _e3921 = (_e3897 + ((_e3917 * _e3683) * mix(1f, _e3478, 0.7f)));
            phi_19549_ = _e3921;
            phi_19407_ = ((((_e3461 * _e1346) * _e3895) * (vec3<f32>(1f, 1f, 1f) - _e3917)) + _e3921);
        } else {
            switch bitcast<i32>(0u) {
                default: {
                    let _e3929 = global_18.member_3[1u];
                    let _e3932 = global_18.member_3[0u];
                    if ((_e3932 <= 0f) || (_e3929 <= 0f)) {
                        phi_18807_ = _e913;
                        break;
                    }
                    let _e3936 = global_10;
                    let _e3937 = dpdx(_e3936);
                    let _e3938 = dpdy(_e3936);
                    let _e3942 = (max(length(_e3937), length(_e3938)) * _e3929);
                    let _e3944 = (1f - smoothstep(0.25f, 0.7f, _e3942));
                    if (_e3944 <= 0f) {
                        phi_18807_ = _e913;
                        break;
                    }
                    let _e3946 = (_e3936 * _e3929);
                    let _e3947 = floor(_e3946);
                    let _e3948 = (_e3946 - _e3947);
                    let _e3952 = ((_e3948 * _e3948) * (vec3<f32>(3f, 3f, 3f) - (_e3948 * 2f)));
                    let _e3957 = bitcast<vec3<u32>>(vec3<i32>(_e3947));
                    let _e3966 = ((((_e3957.x * 1597334677u) ^ (_e3957.y * 3812015801u)) ^ (_e3957.z * 2798796415u)) * 1597334677u);
                    let _e3971 = f32(((_e3966 ^ (_e3966 >> bitcast<u32>(16i))) & 65535u));
                    let _e3972 = (_e3971 * 0.000015259022f);
                    let _e3975 = bitcast<vec3<u32>>(vec3<i32>((_e3947 + vec3<f32>(1f, 0f, 0f))));
                    let _e3984 = ((((_e3975.x * 1597334677u) ^ (_e3975.y * 3812015801u)) ^ (_e3975.z * 2798796415u)) * 1597334677u);
                    let _e3990 = (f32(((_e3984 ^ (_e3984 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f);
                    let _e3993 = bitcast<vec3<u32>>(vec3<i32>((_e3947 + vec3<f32>(0f, 1f, 0f))));
                    let _e4002 = ((((_e3993.x * 1597334677u) ^ (_e3993.y * 3812015801u)) ^ (_e3993.z * 2798796415u)) * 1597334677u);
                    let _e4008 = (f32(((_e4002 ^ (_e4002 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f);
                    let _e4011 = bitcast<vec3<u32>>(vec3<i32>((_e3947 + vec3<f32>(1f, 1f, 0f))));
                    let _e4020 = ((((_e4011.x * 1597334677u) ^ (_e4011.y * 3812015801u)) ^ (_e4011.z * 2798796415u)) * 1597334677u);
                    let _e4026 = (f32(((_e4020 ^ (_e4020 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f);
                    let _e4029 = bitcast<vec3<u32>>(vec3<i32>((_e3947 + vec3<f32>(0f, 0f, 1f))));
                    let _e4038 = ((((_e4029.x * 1597334677u) ^ (_e4029.y * 3812015801u)) ^ (_e4029.z * 2798796415u)) * 1597334677u);
                    let _e4044 = (f32(((_e4038 ^ (_e4038 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f);
                    let _e4047 = bitcast<vec3<u32>>(vec3<i32>((_e3947 + vec3<f32>(1f, 0f, 1f))));
                    let _e4056 = ((((_e4047.x * 1597334677u) ^ (_e4047.y * 3812015801u)) ^ (_e4047.z * 2798796415u)) * 1597334677u);
                    let _e4062 = (f32(((_e4056 ^ (_e4056 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f);
                    let _e4065 = bitcast<vec3<u32>>(vec3<i32>((_e3947 + vec3<f32>(0f, 1f, 1f))));
                    let _e4074 = ((((_e4065.x * 1597334677u) ^ (_e4065.y * 3812015801u)) ^ (_e4065.z * 2798796415u)) * 1597334677u);
                    let _e4080 = (f32(((_e4074 ^ (_e4074 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f);
                    let _e4083 = bitcast<vec3<u32>>(vec3<i32>((_e3947 + vec3<f32>(1f, 1f, 1f))));
                    let _e4092 = ((((_e4083.x * 1597334677u) ^ (_e4083.y * 3812015801u)) ^ (_e4083.z * 2798796415u)) * 1597334677u);
                    let _e4099 = (_e3990 - _e3972);
                    let _e4100 = (_e4008 - _e3972);
                    let _e4101 = (_e4044 - _e3972);
                    let _e4102 = (_e3972 - _e3990);
                    let _e4104 = ((_e4102 - _e4008) + _e4026);
                    let _e4107 = (((_e3972 - _e4008) - _e4044) + _e4080);
                    let _e4109 = ((_e4102 - _e4044) + _e4062);
                    let _e4117 = ((((((((_e3971 * -0.000015259022f) + _e3990) + _e4008) - _e4026) + _e4044) - _e4062) - _e4080) + (f32(((_e4092 ^ (_e4092 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f));
                    let _e4127 = (_e4104 * _e3952.x);
                    let _e4130 = (_e4107 * _e3952.y);
                    let _e4133 = (_e4109 * _e3952.z);
                    let _e4137 = ((_e4117 * _e3952.x) * _e3952.y);
                    let _e4139 = (((((((_e3972 + (_e4099 * _e3952.x)) + (_e4100 * _e3952.y)) + (_e4101 * _e3952.z)) + (_e4127 * _e3952.y)) + (_e4130 * _e3952.z)) + (_e4133 * _e3952.x)) + (_e4137 * _e3952.z));
                    let _e4157 = (((_e3948 * 6f) * (vec3<f32>(1f, 1f, 1f) - _e3948)) * vec3<f32>((((_e4099 + (_e4104 * _e3952.y)) + _e4133) + ((_e4117 * _e3952.y) * _e3952.z)), (((_e4100 + (_e4107 * _e3952.z)) + _e4127) + ((_e4117 * _e3952.z) * _e3952.x)), (((_e4101 + (_e4109 * _e3952.x)) + _e4130) + _e4137)));
                    let _e4162 = (1f - _e4139);
                    let _e4169 = ((_e3946 * vec3<f32>(2.9f, 2.3f, 2.6f)) + vec3<f32>(13.1f, 7.7f, 3.3f));
                    let _e4170 = floor(_e4169);
                    let _e4171 = (_e4169 - _e4170);
                    let _e4175 = ((_e4171 * _e4171) * (vec3<f32>(3f, 3f, 3f) - (_e4171 * 2f)));
                    let _e4180 = bitcast<vec3<u32>>(vec3<i32>(_e4170));
                    let _e4189 = ((((_e4180.x * 1597334677u) ^ (_e4180.y * 3812015801u)) ^ (_e4180.z * 2798796415u)) * 1597334677u);
                    let _e4194 = f32(((_e4189 ^ (_e4189 >> bitcast<u32>(16i))) & 65535u));
                    let _e4195 = (_e4194 * 0.000015259022f);
                    let _e4198 = bitcast<vec3<u32>>(vec3<i32>((_e4170 + vec3<f32>(1f, 0f, 0f))));
                    let _e4207 = ((((_e4198.x * 1597334677u) ^ (_e4198.y * 3812015801u)) ^ (_e4198.z * 2798796415u)) * 1597334677u);
                    let _e4213 = (f32(((_e4207 ^ (_e4207 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f);
                    let _e4216 = bitcast<vec3<u32>>(vec3<i32>((_e4170 + vec3<f32>(0f, 1f, 0f))));
                    let _e4225 = ((((_e4216.x * 1597334677u) ^ (_e4216.y * 3812015801u)) ^ (_e4216.z * 2798796415u)) * 1597334677u);
                    let _e4231 = (f32(((_e4225 ^ (_e4225 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f);
                    let _e4234 = bitcast<vec3<u32>>(vec3<i32>((_e4170 + vec3<f32>(1f, 1f, 0f))));
                    let _e4243 = ((((_e4234.x * 1597334677u) ^ (_e4234.y * 3812015801u)) ^ (_e4234.z * 2798796415u)) * 1597334677u);
                    let _e4249 = (f32(((_e4243 ^ (_e4243 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f);
                    let _e4252 = bitcast<vec3<u32>>(vec3<i32>((_e4170 + vec3<f32>(0f, 0f, 1f))));
                    let _e4261 = ((((_e4252.x * 1597334677u) ^ (_e4252.y * 3812015801u)) ^ (_e4252.z * 2798796415u)) * 1597334677u);
                    let _e4267 = (f32(((_e4261 ^ (_e4261 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f);
                    let _e4270 = bitcast<vec3<u32>>(vec3<i32>((_e4170 + vec3<f32>(1f, 0f, 1f))));
                    let _e4279 = ((((_e4270.x * 1597334677u) ^ (_e4270.y * 3812015801u)) ^ (_e4270.z * 2798796415u)) * 1597334677u);
                    let _e4285 = (f32(((_e4279 ^ (_e4279 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f);
                    let _e4288 = bitcast<vec3<u32>>(vec3<i32>((_e4170 + vec3<f32>(0f, 1f, 1f))));
                    let _e4297 = ((((_e4288.x * 1597334677u) ^ (_e4288.y * 3812015801u)) ^ (_e4288.z * 2798796415u)) * 1597334677u);
                    let _e4303 = (f32(((_e4297 ^ (_e4297 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f);
                    let _e4306 = bitcast<vec3<u32>>(vec3<i32>((_e4170 + vec3<f32>(1f, 1f, 1f))));
                    let _e4315 = ((((_e4306.x * 1597334677u) ^ (_e4306.y * 3812015801u)) ^ (_e4306.z * 2798796415u)) * 1597334677u);
                    let _e4325 = (_e4195 - _e4213);
                    let _e4327 = ((_e4325 - _e4231) + _e4249);
                    let _e4330 = (((_e4195 - _e4231) - _e4267) + _e4303);
                    let _e4332 = ((_e4325 - _e4267) + _e4285);
                    let _e4340 = ((((((((_e4194 * -0.000015259022f) + _e4213) + _e4231) - _e4249) + _e4267) - _e4285) - _e4303) + (f32(((_e4315 ^ (_e4315 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f));
                    let _e4366 = (((_e4171 * 6f) * (vec3<f32>(1f, 1f, 1f) - _e4171)) * vec3<f32>(((((_e4213 - _e4195) + (_e4327 * _e4175.y)) + (_e4332 * _e4175.z)) + ((_e4340 * _e4175.y) * _e4175.z)), ((((_e4231 - _e4195) + (_e4330 * _e4175.z)) + (_e4327 * _e4175.x)) + ((_e4340 * _e4175.z) * _e4175.x)), ((((_e4267 - _e4195) + (_e4332 * _e4175.x)) + (_e4330 * _e4175.y)) + ((_e4340 * _e4175.x) * _e4175.y))));
                    let _e4380 = (((vec4<f32>(_e4139, _e4157.x, _e4157.y, _e4157.z).yzw * (((4f * _e4162) * _e4162) * _e4162)) + ((vec3<f32>(1.015f, 0.805f, 0.91f) * vec4<f32>(f32(), _e4366.x, _e4366.y, _e4366.z).yzw) * (1f - smoothstep(0.2f, 0.5f, (_e3942 * 2.9f))))) * ((0.25f * _e3932) * _e3944));
                    let _e4383 = dpdx(_e921);
                    let _e4384 = dpdy(_e921);
                    let _e4385 = cross(_e4384, _e913);
                    let _e4387 = dot(_e4383, _e4385);
                    let _e4388 = abs(_e4387);
                    if (_e4388 < 0.00000000000000000001f) {
                        phi_18807_ = _e913;
                        break;
                    }
                    phi_18807_ = normalize(((_e913 * _e4388) - (((_e4385 * dot(_e4380, _e3937)) + (cross(_e913, _e4383) * dot(_e4380, _e3938))) * sign(_e4387))));
                    break;
                }
            }
            let _e4399 = phi_18807_;
            let _e4401 = max(dot(_e4399, _e923), 0.0001f);
            let _e4405 = mix(vec3<f32>(0.028f, 0.028f, 0.028f), _e1346, vec3(_e2028));
            let _e4408 = global_18.member[3u];
            let _e4410 = clamp((vec3<f32>(0.48f, 0.41f, 0.28f) * _e4408), vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e4411 = (_e4408 > 0f);
            phi_11690_ = _e4411;
            if _e4411 {
                let _e4414 = global_18.member_1[0u];
                phi_11690_ = (_e4414 > 0f);
            }
            let _e4417 = phi_11690_;
            let _e4420 = global_18.member_1[3u];
            let _e4422 = (_e4417 && (_e4420 <= 0.5f));
            if _e4417 {
                let _e4425 = global_18.member_1[1u];
                phi_18808_ = _e4425;
            } else {
                phi_18808_ = 0f;
            }
            let _e4427 = phi_18808_;
            let _e4428 = (_e4427 > 0f);
            phi_18809_ = 0f;
            if (_e4422 || _e4428) {
                let _e4430 = fwidth(_e928);
                let _e4432 = fwidth(_e921);
                phi_18809_ = clamp((length(_e4430) / max(length(_e4432), 0.0000001f)), 0f, 400f);
            }
            let _e4438 = phi_18809_;
            let _e4439 = max(_e4438, 2f);
            if _e4422 {
                let _e4441 = global_18.member;
                let _e4445 = global_18.member_1[0u];
                phi_18810_ = 0i;
                loop {
                    let _e4450 = phi_18810_;
                    if (_e4450 < 2i) {
                        continue;
                    } else {
                        break;
                    }
                    continuing {
                        let _e4454 = (((_e4441.xyz * (_e4445 * 0.5f)) * _e4438) * select(1.72f, 0.52f, (_e4450 == 0i)));
                        let _e4455 = (_e4454 * 1.3556262f);
                        local_3[_e4450] = cos(_e4455);
                        local_2[_e4450] = sin(_e4455);
                        let _e4460 = (_e4454 * 2.85697f);
                        local_1[_e4450] = cos(_e4460);
                        local[_e4450] = sin(_e4460);
                        phi_18810_ = (_e4450 + 1i);
                    }
                }
            }
            if _e4422 {
                phi_18816_ = normalize(mix(_e4399, _e928, vec3(_e4410.x)));
            } else {
                phi_18816_ = _e4399;
            }
            let _e4471 = phi_18816_;
            if _e4422 {
                phi_18818_ = normalize(mix(_e4399, _e928, vec3((_e4410.y * 0.6f))));
            } else {
                phi_18818_ = _e4399;
            }
            let _e4478 = phi_18818_;
            if _e4422 {
                phi_18820_ = normalize(mix(_e4399, _e928, vec3((_e4410.z * 0.4f))));
            } else {
                phi_18820_ = _e4399;
            }
            let _e4485 = phi_18820_;
            let _e4487 = dot(_e4478, _e917);
            let _e4489 = vec3<f32>(dot(_e4471, _e917), _e4487, dot(_e4485, _e917));
            if _e4422 {
                let _e4490 = clamp(_e4489, vec3<f32>(-1f, -1f, -1f), vec3<f32>(1f, 1f, 1f));
                let _e4494 = sqrt(max((vec3<f32>(1f, 1f, 1f) - (_e4490 * _e4490)), vec3<f32>(0f, 0f, 0f)));
                phi_18822_ = vec3<f32>(0f, 0f, 0f);
                phi_18821_ = 0i;
                loop {
                    let _e4496 = phi_18822_;
                    let _e4498 = phi_18821_;
                    local_67 = _e4496;
                    if (_e4498 < 2i) {
                        continue;
                    } else {
                        break;
                    }
                    continuing {
                        let _e4503 = local_3[_e4498];
                        let _e4506 = local_2[_e4498];
                        let _e4510 = local_3[_e4498];
                        let _e4512 = local_2[_e4498];
                        let _e4520 = local_1[_e4498];
                        let _e4523 = local[_e4498];
                        let _e4527 = local_1[_e4498];
                        let _e4529 = local[_e4498];
                        phi_18822_ = (_e4496 + ((((max(_e4490, vec3<f32>(0f, 0f, 0f)) * 0.5333333f) + ((max(((_e4490 * _e4503) - (_e4494 * _e4506)), vec3<f32>(0f, 0f, 0f)) + max(((_e4490 * _e4510) + (_e4494 * _e4512)), vec3<f32>(0f, 0f, 0f))) * 0.2220759f)) + ((max(((_e4490 * _e4520) - (_e4494 * _e4523)), vec3<f32>(0f, 0f, 0f)) + max(((_e4490 * _e4527) + (_e4494 * _e4529)), vec3<f32>(0f, 0f, 0f))) * 0.0112574f)) * select(0.57f, 0.43f, (_e4498 == 0i))));
                        phi_18821_ = (_e4498 + 1i);
                    }
                }
                let _e4543 = local_67;
                phi_18823_ = mix(max(_e4489, vec3<f32>(0f, 0f, 0f)), _e4543, _e4410);
            } else {
                phi_18823_ = vec3(max(_e4487, 0f));
            }
            let _e4548 = phi_18823_;
            let _e4550 = ((_e4548 * _e1353) * _e1344);
            switch bitcast<i32>(0u) {
                default: {
                    let _e4553 = clamp(dot(_e4399, _e917), 0f, 1f);
                    if (_e4553 <= 0f) {
                        phi_18830_ = vec3<f32>(0f, 0f, 0f);
                        break;
                    }
                    let _e4556 = clamp(dot(_e4399, _e925), 0f, 1f);
                    let _e4566 = global_18.member_2[0u];
                    let _e4568 = clamp((_e2030 * _e4566), 0.045f, 1f);
                    let _e4569 = (_e4568 * _e4568);
                    let _e4570 = (_e4569 * _e4569);
                    let _e4571 = (_e4556 * _e4556);
                    let _e4574 = ((_e4571 * (_e4570 - 1f)) + 1f);
                    let _e4578 = (_e4401 * _e4401);
                    let _e4579 = (1f - _e4570);
                    let _e4584 = (_e4553 * _e4553);
                    let _e4592 = ((_e4570 / ((3.1415927f * _e4574) * _e4574)) * (0.5f / max(((_e4553 * sqrt(((_e4578 * _e4579) + _e4570))) + (_e4401 * sqrt(((_e4584 * _e4579) + _e4570)))), 0.00001f)));
                    let _e4595 = global_18.member_2[3u];
                    phi_18829_ = _e4592;
                    if (_e4595 > 0.5f) {
                        let _e4599 = global_18.member_2[1u];
                        let _e4601 = clamp((_e2030 * _e4599), 0.045f, 1f);
                        let _e4602 = (_e4601 * _e4601);
                        let _e4603 = (_e4602 * _e4602);
                        let _e4606 = ((_e4571 * (_e4603 - 1f)) + 1f);
                        let _e4610 = (1f - _e4603);
                        let _e4625 = global_18.member_2[2u];
                        phi_18829_ = mix(_e4592, ((_e4603 / ((3.1415927f * _e4606) * _e4606)) * (0.5f / max(((_e4553 * sqrt(((_e4578 * _e4610) + _e4603))) + (_e4401 * sqrt(((_e4584 * _e4610) + _e4603)))), 0.00001f))), _e4625);
                    }
                    let _e4628 = phi_18829_;
                    phi_18830_ = ((_e4405 + ((vec3<f32>(1f, 1f, 1f) - _e4405) * pow((1f - clamp(dot(_e923, _e925), 0f, 1f)), 5f))) * ((_e4628 * 3.1415927f) * _e4553));
                    break;
                }
            }
            let _e4633 = phi_18830_;
            let _e4635 = ((_e4633 * _e1353) * _e1344);
            phi_11819_ = _e4428;
            if _e4428 {
                phi_11819_ = (dot(_e928, _e917) < 0.35f);
            }
            let _e4639 = phi_11819_;
            phi_11825_ = _e4639;
            if _e4639 {
                phi_11825_ = (_e1352 > 0f);
            }
            let _e4642 = phi_11825_;
            phi_18980_ = _e4550;
            if _e4642 {
                if _e931 {
                    switch bitcast<i32>(0u) {
                        default: {
                            let _e4646 = global.member_21[0u];
                            let _e4647 = i32(_e4646);
                            if ((_e934 < 0.5f) || (_e4647 == 0i)) {
                                let _e4654 = global_18.member_1[1u];
                                let _e4657 = ((1200f / _e4439) / (0.6f + (6f * _e4654)));
                                let _e4659 = (-(_e4657) * _e4657);
                                phi_18889_ = ((((((vec3<f32>(0.233f, 0.455f, 0.649f) * exp((_e4659 * 156.25f))) + (vec3<f32>(0.1f, 0.336f, 0.344f) * exp((_e4659 * 20.661158f)))) + (vec3<f32>(0.118f, 0.198f, 0f) * exp((_e4659 * 5.3475933f)))) + (vec3<f32>(0.113f, 0.007f, 0.007f) * exp((_e4659 * 1.7636685f)))) + (vec3<f32>(0.358f, 0.004f, 0f) * exp((_e4659 * 0.5025126f)))) + (vec3<f32>(0.078f, 0f, 0f) * exp((_e4659 * 0.13495277f))));
                                break;
                            }
                            let _e4684 = global.member_20;
                            let _e4689 = global.member_20[3u];
                            let _e4690 = (dot(_e4684.xyz, _e921) + _e4689);
                            phi_18835_ = 0i;
                            loop {
                                let _e4692 = phi_18835_;
                                local_68 = _e4692;
                                local_69 = _e4692;
                                local_70 = _e4692;
                                local_71 = _e4692;
                                local_72 = _e4692;
                                local_73 = _e4692;
                                local_76 = _e4692;
                                local_77 = _e4692;
                                local_78 = _e4692;
                                let _e4694 = (_e4692 < (_e4647 - 1i));
                                phi_13512_ = _e4694;
                                if _e4694 {
                                    let _e4697 = global.member_16[_e4692];
                                    phi_13512_ = (_e4690 > _e4697);
                                }
                                let _e4700 = phi_13512_;
                                if _e4700 {
                                    continue;
                                } else {
                                    break;
                                }
                                continuing {
                                    phi_18835_ = (_e4692 + 1i);
                                }
                            }
                            let _e4704 = local_68;
                            let _e4706 = global.member_16[_e4704];
                            if (_e4690 > _e4706) {
                                let _e4711 = global_18.member_1[1u];
                                let _e4714 = ((1200f / _e4439) / (0.6f + (6f * _e4711)));
                                let _e4716 = (-(_e4714) * _e4714);
                                phi_18889_ = ((((((vec3<f32>(0.233f, 0.455f, 0.649f) * exp((_e4716 * 156.25f))) + (vec3<f32>(0.1f, 0.336f, 0.344f) * exp((_e4716 * 20.661158f)))) + (vec3<f32>(0.118f, 0.198f, 0f) * exp((_e4716 * 5.3475933f)))) + (vec3<f32>(0.113f, 0.007f, 0.007f) * exp((_e4716 * 1.7636685f)))) + (vec3<f32>(0.358f, 0.004f, 0f) * exp((_e4716 * 0.5025126f)))) + (vec3<f32>(0.078f, 0f, 0f) * exp((_e4716 * 0.13495277f))));
                                break;
                            }
                            let _e4742 = local_69;
                            let _e4744 = global.member_18[_e4742];
                            let _e4748 = (_e921 - (_e928 * max((_e4744 * 2f), 0.004f)));
                            let _e4750 = (_e4748 + (_e917 * 0.02f));
                            switch bitcast<i32>(0u) {
                                default: {
                                    let _e4754 = local_70;
                                    let _e4756 = global.member_14[_e4754];
                                    let _e4761 = (_e4756 * vec4<f32>(_e4750.x, _e4750.y, _e4750.z, 1f));
                                    let _e4763 = (_e4761.x < 0f);
                                    phi_13699_ = _e4763;
                                    local_75 = _e4756;
                                    if !(_e4763) {
                                        phi_13699_ = (_e4761.x > 1f);
                                    }
                                    let _e4767 = phi_13699_;
                                    phi_13706_ = _e4767;
                                    if !(_e4767) {
                                        phi_13706_ = (_e4761.y < 0f);
                                    }
                                    let _e4772 = phi_13706_;
                                    phi_13713_ = _e4772;
                                    if !(_e4772) {
                                        phi_13713_ = (_e4761.y > 1f);
                                    }
                                    let _e4777 = phi_13713_;
                                    if _e4777 {
                                        phi_18848_ = 1f;
                                        break;
                                    }
                                    let _e4779 = local_71;
                                    let _e4783 = local_72;
                                    let _e4789 = global.member_23;
                                    let _e4790 = _e4789.xy;
                                    let _e4791 = (vec2<f32>(f32((_e4779 & 1i)), f32((_e4783 >> bitcast<u32>(1i)))) * _e4790);
                                    let _e4796 = local_73;
                                    let _e4798 = global.member_19[_e4796];
                                    let _e4799 = (min(_e4761.z, 1f) - _e4798);
                                    let _e4802 = global.member_22;
                                    let _e4803 = _e4802.xy;
                                    let _e4804 = (_e4803 * 0.5f);
                                    let _e4806 = (_e4791 + (_e4761.xy * _e4790));
                                    let _e4807 = (_e4791 + _e4804);
                                    let _e4809 = ((_e4791 + _e4790) - _e4804);
                                    let _e4814 = vec4<f32>(_e4807.x, _e4807.y, _e4809.x, _e4809.y);
                                    switch bitcast<i32>(0u) {
                                        default: {
                                            let _e4818 = global.member_22[2u];
                                            let _e4819 = i32(_e4818);
                                            if (_e4819 <= 0i) {
                                                let _e4823 = clamp(_e4806, _e4814.xy, _e4814.zw);
                                                let _e4828 = textureSampleCompare(global_2, global_1, vec3<f32>(_e4823.x, _e4823.y, _e4799).xy, _e4799);
                                                phi_18847_ = _e4828;
                                                break;
                                            }
                                            let _e4830 = ((_e4806 / _e4803) + vec2<f32>(0.5f, 0.5f));
                                            let _e4831 = floor(_e4830);
                                            let _e4832 = (_e4830 - _e4831);
                                            let _e4834 = (_e4819 == 1i);
                                            if _e4834 {
                                                let _e4835 = (_e4832 * 2f);
                                                local_29[0i] = (vec2<f32>(3f, 3f) - _e4835);
                                                local_29[1i] = (vec2<f32>(1f, 1f) + _e4835);
                                                let _e4841 = local_29[0i];
                                                local_30[0i] = (((vec2<f32>(2f, 2f) - _e4832) / _e4841) - vec2<f32>(1f, 1f));
                                                let _e4845 = local_29[1i];
                                                local_30[1i] = ((_e4832 / _e4845) + vec2<f32>(1f, 1f));
                                            } else {
                                                let _e4849 = (_e4832 * 3f);
                                                local_29[0i] = (vec2<f32>(4f, 4f) - _e4849);
                                                local_29[1i] = vec2<f32>(7f, 7f);
                                                local_29[2i] = (vec2<f32>(1f, 1f) + _e4849);
                                                let _e4857 = local_29[0i];
                                                local_30[0i] = (((vec2<f32>(3f, 3f) - (_e4832 * 2f)) / _e4857) - vec2<f32>(2f, 2f));
                                                let _e4862 = local_29[1i];
                                                local_30[1i] = ((vec2<f32>(3f, 3f) + _e4832) / _e4862);
                                                let _e4865 = local_29[2i];
                                                local_30[2i] = ((_e4832 / _e4865) + vec2<f32>(2f, 2f));
                                            }
                                            let _e4870 = select(3i, 2i, _e4834);
                                            phi_18840_ = 0f;
                                            phi_18837_ = 0i;
                                            loop {
                                                let _e4872 = phi_18840_;
                                                let _e4874 = phi_18837_;
                                                local_74 = _e4872;
                                                if (_e4874 < _e4870) {
                                                    phi_18846_ = _e4872;
                                                    phi_18843_ = 0i;
                                                    loop {
                                                        let _e4877 = phi_18846_;
                                                        let _e4879 = phi_18843_;
                                                        local_99 = _e4877;
                                                        if (_e4879 < _e4870) {
                                                            continue;
                                                        } else {
                                                            break;
                                                        }
                                                        continuing {
                                                            let _e4883 = local_30[_e4879][0u];
                                                            let _e4886 = local_30[_e4874][1u];
                                                            let _e4892 = clamp((_e4803 * ((_e4831 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e4883, _e4886))), _e4814.xy, _e4814.zw);
                                                            let _e4895 = local_29[_e4879][0u];
                                                            let _e4898 = local_29[_e4874][1u];
                                                            let _e4904 = textureSampleCompare(global_2, global_1, vec3<f32>(_e4892.x, _e4892.y, _e4799).xy, _e4799);
                                                            phi_18846_ = (_e4877 + ((_e4895 * _e4898) * _e4904));
                                                            phi_18843_ = (_e4879 + 1i);
                                                        }
                                                    }
                                                    continue;
                                                } else {
                                                    break;
                                                }
                                                continuing {
                                                    let _e7328 = local_99;
                                                    phi_18840_ = _e7328;
                                                    phi_18837_ = (_e4874 + 1i);
                                                }
                                            }
                                            let _e4910 = local_74;
                                            phi_18847_ = (_e4910 * select(0.0069444445f, 0.0625f, _e4834));
                                            break;
                                        }
                                    }
                                    let _e4913 = phi_18847_;
                                    phi_18848_ = _e4913;
                                    break;
                                }
                            }
                            let _e4915 = phi_18848_;
                            if (_e4915 <= 0f) {
                                phi_18889_ = vec3<f32>(0f, 0f, 0f);
                                break;
                            }
                            phi_18851_ = vec3<f32>(1f, 1f, 1f);
                            phi_18850_ = vec3<f32>(0f, 0f, 0f);
                            phi_18849_ = 0i;
                            loop {
                                let _e4918 = phi_18851_;
                                let _e4920 = phi_18850_;
                                let _e4922 = phi_18849_;
                                local_103 = _e4920;
                                if (_e4922 < 4i) {
                                    local_31 = array<f32, 4>(0.002f, 0.005f, 0.01f, 0.02f);
                                    let _e4925 = local_31[_e4922];
                                    let _e4929 = global_18.member_1[1u];
                                    let _e4932 = ((_e4925 * 1000f) / (0.6f + (6f * _e4929)));
                                    let _e4934 = (-(_e4932) * _e4932);
                                    let _e4957 = ((((((vec3<f32>(0.233f, 0.455f, 0.649f) * exp((_e4934 * 156.25f))) + (vec3<f32>(0.1f, 0.336f, 0.344f) * exp((_e4934 * 20.661158f)))) + (vec3<f32>(0.118f, 0.198f, 0f) * exp((_e4934 * 5.3475933f)))) + (vec3<f32>(0.113f, 0.007f, 0.007f) * exp((_e4934 * 1.7636685f)))) + (vec3<f32>(0.358f, 0.004f, 0f) * exp((_e4934 * 0.5025126f)))) + (vec3<f32>(0.078f, 0f, 0f) * exp((_e4934 * 0.13495277f))));
                                    local_32 = array<f32, 4>(0.002f, 0.005f, 0.01f, 0.02f);
                                    let _e4960 = local_32[_e4922];
                                    let _e4962 = (_e4748 + (_e917 * _e4960));
                                    local_100 = _e4957;
                                    switch bitcast<i32>(0u) {
                                        default: {
                                            let _e4969 = local_75;
                                            let _e4970 = (_e4969 * vec4<f32>(_e4962.x, _e4962.y, _e4962.z, 1f));
                                            let _e4972 = (_e4970.x < 0f);
                                            phi_14031_ = _e4972;
                                            if !(_e4972) {
                                                phi_14031_ = (_e4970.x > 1f);
                                            }
                                            let _e4976 = phi_14031_;
                                            phi_14038_ = _e4976;
                                            if !(_e4976) {
                                                phi_14038_ = (_e4970.y < 0f);
                                            }
                                            let _e4981 = phi_14038_;
                                            phi_14045_ = _e4981;
                                            if !(_e4981) {
                                                phi_14045_ = (_e4970.y > 1f);
                                            }
                                            let _e4986 = phi_14045_;
                                            if _e4986 {
                                                phi_18872_ = 1f;
                                                break;
                                            }
                                            let _e4988 = local_76;
                                            let _e4992 = local_77;
                                            let _e4998 = global.member_23;
                                            let _e4999 = _e4998.xy;
                                            let _e5000 = (vec2<f32>(f32((_e4988 & 1i)), f32((_e4992 >> bitcast<u32>(1i)))) * _e4999);
                                            let _e5005 = local_78;
                                            let _e5007 = global.member_19[_e5005];
                                            let _e5008 = (min(_e4970.z, 1f) - _e5007);
                                            let _e5011 = global.member_22;
                                            let _e5012 = _e5011.xy;
                                            let _e5013 = (_e5012 * 0.5f);
                                            let _e5015 = (_e5000 + (_e4970.xy * _e4999));
                                            let _e5016 = (_e5000 + _e5013);
                                            let _e5018 = ((_e5000 + _e4999) - _e5013);
                                            let _e5023 = vec4<f32>(_e5016.x, _e5016.y, _e5018.x, _e5018.y);
                                            switch bitcast<i32>(0u) {
                                                default: {
                                                    let _e5027 = global.member_22[2u];
                                                    let _e5028 = i32(_e5027);
                                                    if (_e5028 <= 0i) {
                                                        let _e5032 = clamp(_e5015, _e5023.xy, _e5023.zw);
                                                        let _e5037 = textureSampleCompare(global_2, global_1, vec3<f32>(_e5032.x, _e5032.y, _e5008).xy, _e5008);
                                                        phi_18871_ = _e5037;
                                                        break;
                                                    }
                                                    let _e5039 = ((_e5015 / _e5012) + vec2<f32>(0.5f, 0.5f));
                                                    let _e5040 = floor(_e5039);
                                                    let _e5041 = (_e5039 - _e5040);
                                                    let _e5043 = (_e5028 == 1i);
                                                    if _e5043 {
                                                        let _e5044 = (_e5041 * 2f);
                                                        local_27[0i] = (vec2<f32>(3f, 3f) - _e5044);
                                                        local_27[1i] = (vec2<f32>(1f, 1f) + _e5044);
                                                        let _e5050 = local_27[0i];
                                                        local_28[0i] = (((vec2<f32>(2f, 2f) - _e5041) / _e5050) - vec2<f32>(1f, 1f));
                                                        let _e5054 = local_27[1i];
                                                        local_28[1i] = ((_e5041 / _e5054) + vec2<f32>(1f, 1f));
                                                    } else {
                                                        let _e5058 = (_e5041 * 3f);
                                                        local_27[0i] = (vec2<f32>(4f, 4f) - _e5058);
                                                        local_27[1i] = vec2<f32>(7f, 7f);
                                                        local_27[2i] = (vec2<f32>(1f, 1f) + _e5058);
                                                        let _e5066 = local_27[0i];
                                                        local_28[0i] = (((vec2<f32>(3f, 3f) - (_e5041 * 2f)) / _e5066) - vec2<f32>(2f, 2f));
                                                        let _e5071 = local_27[1i];
                                                        local_28[1i] = ((vec2<f32>(3f, 3f) + _e5041) / _e5071);
                                                        let _e5074 = local_27[2i];
                                                        local_28[2i] = ((_e5041 / _e5074) + vec2<f32>(2f, 2f));
                                                    }
                                                    let _e5079 = select(3i, 2i, _e5043);
                                                    phi_18864_ = 0f;
                                                    phi_18861_ = 0i;
                                                    loop {
                                                        let _e5081 = phi_18864_;
                                                        let _e5083 = phi_18861_;
                                                        local_79 = _e5081;
                                                        if (_e5083 < _e5079) {
                                                            phi_18870_ = _e5081;
                                                            phi_18867_ = 0i;
                                                            loop {
                                                                let _e5086 = phi_18870_;
                                                                let _e5088 = phi_18867_;
                                                                local_102 = _e5086;
                                                                if (_e5088 < _e5079) {
                                                                    continue;
                                                                } else {
                                                                    break;
                                                                }
                                                                continuing {
                                                                    let _e5092 = local_28[_e5088][0u];
                                                                    let _e5095 = local_28[_e5083][1u];
                                                                    let _e5101 = clamp((_e5012 * ((_e5040 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e5092, _e5095))), _e5023.xy, _e5023.zw);
                                                                    let _e5104 = local_27[_e5088][0u];
                                                                    let _e5107 = local_27[_e5083][1u];
                                                                    let _e5113 = textureSampleCompare(global_2, global_1, vec3<f32>(_e5101.x, _e5101.y, _e5008).xy, _e5008);
                                                                    phi_18870_ = (_e5086 + ((_e5104 * _e5107) * _e5113));
                                                                    phi_18867_ = (_e5088 + 1i);
                                                                }
                                                            }
                                                            continue;
                                                        } else {
                                                            break;
                                                        }
                                                        continuing {
                                                            let _e7351 = local_102;
                                                            phi_18864_ = _e7351;
                                                            phi_18861_ = (_e5083 + 1i);
                                                        }
                                                    }
                                                    let _e5119 = local_79;
                                                    phi_18871_ = (_e5119 * select(0.0069444445f, 0.0625f, _e5043));
                                                    break;
                                                }
                                            }
                                            let _e5122 = phi_18871_;
                                            phi_18872_ = _e5122;
                                            break;
                                        }
                                    }
                                    let _e5124 = phi_18872_;
                                    local_101 = (_e4920 + ((_e4918 - _e4957) * _e5124));
                                    continue;
                                } else {
                                    break;
                                }
                                continuing {
                                    let _e7337 = local_100;
                                    phi_18851_ = _e7337;
                                    let _e7340 = local_101;
                                    phi_18850_ = _e7340;
                                    phi_18849_ = (_e4922 + 1i);
                                }
                            }
                            let _e7360 = local_103;
                            phi_18889_ = _e7360;
                            break;
                        }
                    }
                    let _e5129 = phi_18889_;
                    phi_18890_ = _e5129;
                } else {
                    let _e5133 = global_18.member_1[1u];
                    let _e5136 = ((1200f / _e4439) / (0.6f + (6f * _e5133)));
                    let _e5138 = (-(_e5136) * _e5136);
                    phi_18890_ = ((((((vec3<f32>(0.233f, 0.455f, 0.649f) * exp((_e5138 * 156.25f))) + (vec3<f32>(0.1f, 0.336f, 0.344f) * exp((_e5138 * 20.661158f)))) + (vec3<f32>(0.118f, 0.198f, 0f) * exp((_e5138 * 5.3475933f)))) + (vec3<f32>(0.113f, 0.007f, 0.007f) * exp((_e5138 * 1.7636685f)))) + (vec3<f32>(0.358f, 0.004f, 0f) * exp((_e5138 * 0.5025126f)))) + (vec3<f32>(0.078f, 0f, 0f) * exp((_e5138 * 0.13495277f))));
                }
                let _e5163 = phi_18890_;
                phi_18980_ = (_e4550 + ((_e5163 * _e1353) * ((clamp((0.3f - dot(_e928, _e917)), 0f, 1f) * _e4427) * 2f)));
            }
            let _e5173 = phi_18980_;
            let _e5176 = global.member_13[3u];
            phi_18991_ = _e4635;
            phi_18979_ = _e5173;
            if (_e5176 > 0.5f) {
                let _e5179 = global.member_11;
                let _e5184 = global.member_11[3u];
                let _e5186 = global_15;
                let _e5189 = global.member_12;
                let _e5194 = global.member_13;
                let _e5197 = clamp(floor((_e5186.xy * _e5189.xy)), vec2<f32>(0f, 0f), (_e5194.xy - vec2<f32>(1f, 1f)));
                let _e5202 = global.member_12[2u];
                let _e5206 = global.member_12[3u];
                let _e5211 = global.member_13[2u];
                let _e5216 = global.member_13[1u];
                let _e5222 = global.member_13[0u];
                let _e5226 = u32(((((clamp(floor(((log2(max((dot(_e5179.xyz, _e921) + _e5184), 0.000001f)) * _e5202) + _e5206)), 0f, (_e5211 - 1f)) * _e5216) + _e5197.y) * _e5222) + _e5197.x));
                let _e5233 = global_16.member[(_e5226 >> bitcast<u32>(2i))][(_e5226 & 3u)];
                let _e5234 = (_e5233 & 65535u);
                phi_19016_ = _e4635;
                phi_18981_ = _e5173;
                phi_18916_ = _e5234;
                loop {
                    let _e5238 = phi_19016_;
                    let _e5240 = phi_18981_;
                    let _e5242 = phi_18916_;
                    local_115 = _e5238;
                    local_116 = _e5240;
                    if (_e5242 < (_e5234 + (_e5233 >> bitcast<u32>(16i)))) {
                        let _e5245 = (_e5242 / 3u);
                        let _e5252 = global_17.member[(_e5245 >> bitcast<u32>(2i))][(_e5245 & 3u)];
                        let _e5258 = ((_e5252 >> bitcast<u32>(((_e5242 - (_e5245 * 3u)) * 10u))) & 1023u);
                        let _e5261 = global_11.member[_e5258];
                        let _e5263 = (_e5261.xyz - _e921);
                        let _e5264 = dot(_e5263, _e5263);
                        let _e5266 = (_e5264 * _e5261.w);
                        let _e5269 = clamp((1f - (_e5266 * _e5266)), 0f, 1f);
                        let _e5272 = (_e5263 * inverseSqrt(max(_e5264, 0.00000001f)));
                        let _e5275 = global_13.member[_e5258];
                        let _e5278 = global_14.member[_e5258];
                        let _e5286 = clamp(((dot(-(_e5272), _e5278.xyz) * _e5275.w) + _e5278.w), 0f, 1f);
                        let _e5293 = (_e5275.xyz * ((((_e5269 * _e5269) * _e5286) * _e5286) / max(_e5264, 0.0001f)));
                        if _e931 {
                            switch bitcast<i32>(0u) {
                                default: {
                                    let _e5297 = global.member_21[2u];
                                    let _e5298 = u32(_e5297);
                                    if (_e5258 < _e5298) {
                                        let _e5302 = global.member_26[_e5258];
                                        let _e5305 = global.member_15[_e5258];
                                        let _e5314 = (_e5302.z * max((_e5305 * vec4<f32>(_e921.x, _e921.y, _e921.z, 1f)).w, 0f));
                                        let _e5317 = global.member_25[0u];
                                        let _e5323 = global.member_25[1u];
                                        let _e5326 = ((_e921 + (_e928 * (_e5314 * _e5317))) + (_e5272 * (_e5314 * _e5323)));
                                        let _e5331 = (_e5305 * vec4<f32>(_e5326.x, _e5326.y, _e5326.z, 1f));
                                        if (_e5331.w <= 0f) {
                                            phi_19043_ = 1f;
                                            break;
                                        }
                                        let _e5336 = (_e5331.xyz / vec3(_e5331.w));
                                        let _e5338 = (_e5336.x < 0f);
                                        phi_14585_ = _e5338;
                                        if !(_e5338) {
                                            phi_14585_ = (_e5336.x > 1f);
                                        }
                                        let _e5342 = phi_14585_;
                                        phi_14592_ = _e5342;
                                        if !(_e5342) {
                                            phi_14592_ = (_e5336.y < 0f);
                                        }
                                        let _e5347 = phi_14592_;
                                        phi_14599_ = _e5347;
                                        if !(_e5347) {
                                            phi_14599_ = (_e5336.y > 1f);
                                        }
                                        let _e5352 = phi_14599_;
                                        phi_14606_ = _e5352;
                                        if !(_e5352) {
                                            phi_14606_ = (_e5336.z > 1f);
                                        }
                                        let _e5357 = phi_14606_;
                                        if _e5357 {
                                            phi_19043_ = 1f;
                                            break;
                                        }
                                        let _e5360 = _e5302.xy;
                                        let _e5362 = global.member_23;
                                        let _e5363 = _e5362.zw;
                                        let _e5365 = global.member_22;
                                        let _e5366 = _e5365.xy;
                                        let _e5367 = (_e5366 * 0.5f);
                                        let _e5369 = (_e5360 + (_e5336.xy * _e5363));
                                        let _e5370 = (_e5360 + _e5367);
                                        let _e5372 = ((_e5360 + _e5363) - _e5367);
                                        let _e5377 = vec4<f32>(_e5370.x, _e5370.y, _e5372.x, _e5372.y);
                                        switch bitcast<i32>(0u) {
                                            default: {
                                                let _e5381 = global.member_22[2u];
                                                let _e5382 = i32(_e5381);
                                                if (_e5382 <= 0i) {
                                                    let _e5386 = clamp(_e5369, _e5377.xy, _e5377.zw);
                                                    let _e5391 = textureSampleCompare(global_2, global_1, vec3<f32>(_e5386.x, _e5386.y, _e5336.z).xy, _e5336.z);
                                                    phi_19042_ = _e5391;
                                                    break;
                                                }
                                                let _e5393 = ((_e5369 / _e5366) + vec2<f32>(0.5f, 0.5f));
                                                let _e5394 = floor(_e5393);
                                                let _e5395 = (_e5393 - _e5394);
                                                let _e5397 = (_e5382 == 1i);
                                                if _e5397 {
                                                    let _e5398 = (_e5395 * 2f);
                                                    local_23[0i] = (vec2<f32>(3f, 3f) - _e5398);
                                                    local_23[1i] = (vec2<f32>(1f, 1f) + _e5398);
                                                    let _e5404 = local_23[0i];
                                                    local_24[0i] = (((vec2<f32>(2f, 2f) - _e5395) / _e5404) - vec2<f32>(1f, 1f));
                                                    let _e5408 = local_23[1i];
                                                    local_24[1i] = ((_e5395 / _e5408) + vec2<f32>(1f, 1f));
                                                } else {
                                                    let _e5412 = (_e5395 * 3f);
                                                    local_23[0i] = (vec2<f32>(4f, 4f) - _e5412);
                                                    local_23[1i] = vec2<f32>(7f, 7f);
                                                    local_23[2i] = (vec2<f32>(1f, 1f) + _e5412);
                                                    let _e5420 = local_23[0i];
                                                    local_24[0i] = (((vec2<f32>(3f, 3f) - (_e5395 * 2f)) / _e5420) - vec2<f32>(2f, 2f));
                                                    let _e5425 = local_23[1i];
                                                    local_24[1i] = ((vec2<f32>(3f, 3f) + _e5395) / _e5425);
                                                    let _e5428 = local_23[2i];
                                                    local_24[2i] = ((_e5395 / _e5428) + vec2<f32>(2f, 2f));
                                                }
                                                let _e5433 = select(3i, 2i, _e5397);
                                                phi_19035_ = 0f;
                                                phi_19032_ = 0i;
                                                loop {
                                                    let _e5435 = phi_19035_;
                                                    let _e5437 = phi_19032_;
                                                    local_80 = _e5435;
                                                    if (_e5437 < _e5433) {
                                                        phi_19041_ = _e5435;
                                                        phi_19038_ = 0i;
                                                        loop {
                                                            let _e5440 = phi_19041_;
                                                            let _e5442 = phi_19038_;
                                                            local_106 = _e5440;
                                                            if (_e5442 < _e5433) {
                                                                continue;
                                                            } else {
                                                                break;
                                                            }
                                                            continuing {
                                                                let _e5446 = local_24[_e5442][0u];
                                                                let _e5449 = local_24[_e5437][1u];
                                                                let _e5455 = clamp((_e5366 * ((_e5394 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e5446, _e5449))), _e5377.xy, _e5377.zw);
                                                                let _e5458 = local_23[_e5442][0u];
                                                                let _e5461 = local_23[_e5437][1u];
                                                                let _e5467 = textureSampleCompare(global_2, global_1, vec3<f32>(_e5455.x, _e5455.y, _e5336.z).xy, _e5336.z);
                                                                phi_19041_ = (_e5440 + ((_e5458 * _e5461) * _e5467));
                                                                phi_19038_ = (_e5442 + 1i);
                                                            }
                                                        }
                                                        continue;
                                                    } else {
                                                        break;
                                                    }
                                                    continuing {
                                                        let _e7376 = local_106;
                                                        phi_19035_ = _e7376;
                                                        phi_19032_ = (_e5437 + 1i);
                                                    }
                                                }
                                                let _e5473 = local_80;
                                                phi_19042_ = (_e5473 * select(0.0069444445f, 0.0625f, _e5397));
                                                break;
                                            }
                                        }
                                        let _e5476 = phi_19042_;
                                        phi_19043_ = _e5476;
                                        break;
                                    }
                                    let _e5477 = (_e5258 - _e5298);
                                    let _e5480 = global.member_21[3u];
                                    if (_e5477 >= u32(_e5480)) {
                                        phi_19043_ = 1f;
                                        break;
                                    }
                                    let _e5485 = global.member_27[_e5477];
                                    let _e5488 = global.member_28[_e5477];
                                    let _e5490 = _e5485.xyz;
                                    let _e5493 = (_e5485.w * length((_e921 - _e5490)));
                                    let _e5496 = global.member_25[0u];
                                    let _e5502 = global.member_25[1u];
                                    let _e5506 = (((_e921 + (_e928 * (_e5493 * _e5496))) + (_e5272 * (_e5493 * _e5502))) - _e5490);
                                    let _e5507 = abs(_e5506);
                                    let _e5510 = (_e5507.x >= _e5507.y);
                                    phi_14676_ = _e5510;
                                    if _e5510 {
                                        phi_14676_ = (_e5507.x >= _e5507.z);
                                    }
                                    let _e5514 = phi_14676_;
                                    if _e5514 {
                                        phi_19019_ = select(1i, 0i, (_e5506.x > 0f));
                                        phi_19017_ = _e5507.x;
                                    } else {
                                        let _e5519 = (_e5507.y >= _e5507.z);
                                        if _e5519 {
                                            phi_19020_ = select(3i, 2i, (_e5506.y > 0f));
                                        } else {
                                            phi_19020_ = select(5i, 4i, (_e5506.z > 0f));
                                        }
                                        let _e5527 = phi_19020_;
                                        phi_19019_ = _e5527;
                                        phi_19017_ = select(_e5507.z, _e5507.y, _e5519);
                                    }
                                    let _e5530 = phi_19019_;
                                    let _e5532 = phi_19017_;
                                    if (_e5532 <= 0f) {
                                        phi_19043_ = 1f;
                                        break;
                                    }
                                    local_25 = array<vec3<f32>, 6>(vec3<f32>(0f, 0f, 1f), vec3<f32>(0f, 0f, -1f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(1f, 0f, 0f));
                                    let _e5535 = local_25[_e5530];
                                    local_26 = array<vec3<f32>, 6>(vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 0f, -1f), vec3<f32>(0f, 0f, 1f), vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 1f, 0f));
                                    let _e5538 = local_26[_e5530];
                                    let _e5543 = global.member_24[2u];
                                    let _e5546 = (vec2<f32>(dot(_e5506, _e5535), dot(_e5506, _e5538)) / vec2((_e5532 * _e5543)));
                                    let _e5550 = (_e5488.z + (_e5488.w / _e5532));
                                    if (_e5550 > 1f) {
                                        phi_19043_ = 1f;
                                        break;
                                    }
                                    let _e5565 = global.member_24;
                                    let _e5566 = _e5565.xy;
                                    let _e5568 = (_e5488.xy + (vec2<f32>(f32((_e5530 - (i32(floor((f32(_e5530) / f32(3i)))) * 3i))), f32((_e5530 / 3i))) * _e5566));
                                    let _e5577 = global.member_22;
                                    let _e5578 = _e5577.xy;
                                    let _e5579 = (_e5578 * 0.5f);
                                    let _e5581 = (_e5568 + (vec2<f32>((0.5f + (0.5f * _e5546.x)), (0.5f - (0.5f * _e5546.y))) * _e5566));
                                    let _e5582 = (_e5568 + _e5579);
                                    let _e5584 = ((_e5568 + _e5566) - _e5579);
                                    let _e5589 = vec4<f32>(_e5582.x, _e5582.y, _e5584.x, _e5584.y);
                                    switch bitcast<i32>(0u) {
                                        default: {
                                            let _e5593 = global.member_22[2u];
                                            let _e5594 = i32(_e5593);
                                            if (_e5594 <= 0i) {
                                                let _e5598 = clamp(_e5581, _e5589.xy, _e5589.zw);
                                                let _e5603 = textureSampleCompare(global_2, global_1, vec3<f32>(_e5598.x, _e5598.y, _e5550).xy, _e5550);
                                                phi_19031_ = _e5603;
                                                break;
                                            }
                                            let _e5605 = ((_e5581 / _e5578) + vec2<f32>(0.5f, 0.5f));
                                            let _e5606 = floor(_e5605);
                                            let _e5607 = (_e5605 - _e5606);
                                            let _e5609 = (_e5594 == 1i);
                                            if _e5609 {
                                                let _e5610 = (_e5607 * 2f);
                                                local_21[0i] = (vec2<f32>(3f, 3f) - _e5610);
                                                local_21[1i] = (vec2<f32>(1f, 1f) + _e5610);
                                                let _e5616 = local_21[0i];
                                                local_22[0i] = (((vec2<f32>(2f, 2f) - _e5607) / _e5616) - vec2<f32>(1f, 1f));
                                                let _e5620 = local_21[1i];
                                                local_22[1i] = ((_e5607 / _e5620) + vec2<f32>(1f, 1f));
                                            } else {
                                                let _e5624 = (_e5607 * 3f);
                                                local_21[0i] = (vec2<f32>(4f, 4f) - _e5624);
                                                local_21[1i] = vec2<f32>(7f, 7f);
                                                local_21[2i] = (vec2<f32>(1f, 1f) + _e5624);
                                                let _e5632 = local_21[0i];
                                                local_22[0i] = (((vec2<f32>(3f, 3f) - (_e5607 * 2f)) / _e5632) - vec2<f32>(2f, 2f));
                                                let _e5637 = local_21[1i];
                                                local_22[1i] = ((vec2<f32>(3f, 3f) + _e5607) / _e5637);
                                                let _e5640 = local_21[2i];
                                                local_22[2i] = ((_e5607 / _e5640) + vec2<f32>(2f, 2f));
                                            }
                                            let _e5645 = select(3i, 2i, _e5609);
                                            phi_19024_ = 0f;
                                            phi_19021_ = 0i;
                                            loop {
                                                let _e5647 = phi_19024_;
                                                let _e5649 = phi_19021_;
                                                local_81 = _e5647;
                                                if (_e5649 < _e5645) {
                                                    phi_19030_ = _e5647;
                                                    phi_19027_ = 0i;
                                                    loop {
                                                        let _e5652 = phi_19030_;
                                                        let _e5654 = phi_19027_;
                                                        local_107 = _e5652;
                                                        if (_e5654 < _e5645) {
                                                            continue;
                                                        } else {
                                                            break;
                                                        }
                                                        continuing {
                                                            let _e5658 = local_22[_e5654][0u];
                                                            let _e5661 = local_22[_e5649][1u];
                                                            let _e5667 = clamp((_e5578 * ((_e5606 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e5658, _e5661))), _e5589.xy, _e5589.zw);
                                                            let _e5670 = local_21[_e5654][0u];
                                                            let _e5673 = local_21[_e5649][1u];
                                                            let _e5679 = textureSampleCompare(global_2, global_1, vec3<f32>(_e5667.x, _e5667.y, _e5550).xy, _e5550);
                                                            phi_19030_ = (_e5652 + ((_e5670 * _e5673) * _e5679));
                                                            phi_19027_ = (_e5654 + 1i);
                                                        }
                                                    }
                                                    continue;
                                                } else {
                                                    break;
                                                }
                                                continuing {
                                                    let _e7388 = local_107;
                                                    phi_19024_ = _e7388;
                                                    phi_19021_ = (_e5649 + 1i);
                                                }
                                            }
                                            let _e5685 = local_81;
                                            phi_19031_ = (_e5685 * select(0.0069444445f, 0.0625f, _e5609));
                                            break;
                                        }
                                    }
                                    let _e5688 = phi_19031_;
                                    phi_19043_ = _e5688;
                                    break;
                                }
                            }
                            let _e5690 = phi_19043_;
                            phi_19044_ = _e5690;
                        } else {
                            phi_19044_ = 1f;
                        }
                        let _e5692 = phi_19044_;
                        let _e5694 = dot(_e4478, _e5272);
                        let _e5696 = vec3<f32>(dot(_e4471, _e5272), _e5694, dot(_e4485, _e5272));
                        if _e4422 {
                            let _e5697 = clamp(_e5696, vec3<f32>(-1f, -1f, -1f), vec3<f32>(1f, 1f, 1f));
                            let _e5701 = sqrt(max((vec3<f32>(1f, 1f, 1f) - (_e5697 * _e5697)), vec3<f32>(0f, 0f, 0f)));
                            phi_19046_ = vec3<f32>(0f, 0f, 0f);
                            phi_19045_ = 0i;
                            loop {
                                let _e5703 = phi_19046_;
                                let _e5705 = phi_19045_;
                                local_82 = _e5703;
                                if (_e5705 < 2i) {
                                    continue;
                                } else {
                                    break;
                                }
                                continuing {
                                    let _e5710 = local_3[_e5705];
                                    let _e5713 = local_2[_e5705];
                                    let _e5717 = local_3[_e5705];
                                    let _e5719 = local_2[_e5705];
                                    let _e5727 = local_1[_e5705];
                                    let _e5730 = local[_e5705];
                                    let _e5734 = local_1[_e5705];
                                    let _e5736 = local[_e5705];
                                    phi_19046_ = (_e5703 + ((((max(_e5697, vec3<f32>(0f, 0f, 0f)) * 0.5333333f) + ((max(((_e5697 * _e5710) - (_e5701 * _e5713)), vec3<f32>(0f, 0f, 0f)) + max(((_e5697 * _e5717) + (_e5701 * _e5719)), vec3<f32>(0f, 0f, 0f))) * 0.2220759f)) + ((max(((_e5697 * _e5727) - (_e5701 * _e5730)), vec3<f32>(0f, 0f, 0f)) + max(((_e5697 * _e5734) + (_e5701 * _e5736)), vec3<f32>(0f, 0f, 0f))) * 0.0112574f)) * select(0.57f, 0.43f, (_e5705 == 0i))));
                                    phi_19045_ = (_e5705 + 1i);
                                }
                            }
                            let _e5750 = local_82;
                            phi_19047_ = mix(max(_e5696, vec3<f32>(0f, 0f, 0f)), _e5750, _e4410);
                        } else {
                            phi_19047_ = vec3(max(_e5694, 0f));
                        }
                        let _e5755 = phi_19047_;
                        let _e5758 = (_e5240 + ((_e5755 * _e5293) * _e5692));
                        switch bitcast<i32>(0u) {
                            default: {
                                let _e5761 = normalize((_e5272 + _e923));
                                let _e5763 = clamp(dot(_e4399, _e5272), 0f, 1f);
                                if (_e5763 <= 0f) {
                                    phi_19087_ = vec3<f32>(0f, 0f, 0f);
                                    break;
                                }
                                let _e5766 = clamp(dot(_e4399, _e5761), 0f, 1f);
                                let _e5776 = global_18.member_2[0u];
                                let _e5778 = clamp((_e2030 * _e5776), 0.045f, 1f);
                                let _e5779 = (_e5778 * _e5778);
                                let _e5780 = (_e5779 * _e5779);
                                let _e5781 = (_e5766 * _e5766);
                                let _e5784 = ((_e5781 * (_e5780 - 1f)) + 1f);
                                let _e5788 = (_e4401 * _e4401);
                                let _e5789 = (1f - _e5780);
                                let _e5794 = (_e5763 * _e5763);
                                let _e5802 = ((_e5780 / ((3.1415927f * _e5784) * _e5784)) * (0.5f / max(((_e5763 * sqrt(((_e5788 * _e5789) + _e5780))) + (_e4401 * sqrt(((_e5794 * _e5789) + _e5780)))), 0.00001f)));
                                let _e5805 = global_18.member_2[3u];
                                phi_19086_ = _e5802;
                                if (_e5805 > 0.5f) {
                                    let _e5809 = global_18.member_2[1u];
                                    let _e5811 = clamp((_e2030 * _e5809), 0.045f, 1f);
                                    let _e5812 = (_e5811 * _e5811);
                                    let _e5813 = (_e5812 * _e5812);
                                    let _e5816 = ((_e5781 * (_e5813 - 1f)) + 1f);
                                    let _e5820 = (1f - _e5813);
                                    let _e5835 = global_18.member_2[2u];
                                    phi_19086_ = mix(_e5802, ((_e5813 / ((3.1415927f * _e5816) * _e5816)) * (0.5f / max(((_e5763 * sqrt(((_e5788 * _e5820) + _e5813))) + (_e4401 * sqrt(((_e5794 * _e5820) + _e5813)))), 0.00001f))), _e5835);
                                }
                                let _e5838 = phi_19086_;
                                phi_19087_ = ((_e4405 + ((vec3<f32>(1f, 1f, 1f) - _e4405) * pow((1f - clamp(dot(_e923, _e5761), 0f, 1f)), 5f))) * ((_e5838 * 3.1415927f) * _e5763));
                                break;
                            }
                        }
                        let _e5843 = phi_19087_;
                        local_104 = (_e5238 + ((_e5843 * _e5293) * _e5692));
                        phi_11938_ = _e4428;
                        if _e4428 {
                            phi_11938_ = (dot(_e928, _e5272) < 0.35f);
                        }
                        let _e5850 = phi_11938_;
                        phi_19895_ = _e5758;
                        if _e5850 {
                            if _e931 {
                                switch bitcast<i32>(0u) {
                                    default: {
                                        let _e5854 = global.member_21[2u];
                                        let _e5857 = global.member_21[3u];
                                        if (_e5258 >= u32((_e5854 + _e5857))) {
                                            let _e5864 = global_18.member_1[1u];
                                            let _e5867 = ((1200f / _e4439) / (0.6f + (6f * _e5864)));
                                            let _e5869 = (-(_e5867) * _e5867);
                                            phi_19198_ = ((((((vec3<f32>(0.233f, 0.455f, 0.649f) * exp((_e5869 * 156.25f))) + (vec3<f32>(0.1f, 0.336f, 0.344f) * exp((_e5869 * 20.661158f)))) + (vec3<f32>(0.118f, 0.198f, 0f) * exp((_e5869 * 5.3475933f)))) + (vec3<f32>(0.113f, 0.007f, 0.007f) * exp((_e5869 * 1.7636685f)))) + (vec3<f32>(0.358f, 0.004f, 0f) * exp((_e5869 * 0.5025126f)))) + (vec3<f32>(0.078f, 0f, 0f) * exp((_e5869 * 0.13495277f))));
                                            break;
                                        }
                                        let _e5894 = (_e921 - (_e928 * 0.004f));
                                        let _e5896 = (_e5894 + (_e5272 * 0.02f));
                                        switch bitcast<i32>(0u) {
                                            default: {
                                                let _e5898 = u32(_e5854);
                                                let _e5899 = (_e5258 < _e5898);
                                                local_85 = _e5899;
                                                local_87 = _e5898;
                                                if _e5899 {
                                                    let _e5902 = global.member_26[_e5258];
                                                    let _e5905 = global.member_15[_e5258];
                                                    let _e5914 = (_e5902.z * max((_e5905 * vec4<f32>(_e5896.x, _e5896.y, _e5896.z, 1f)).w, 0f));
                                                    let _e5917 = global.member_25[0u];
                                                    let _e5923 = global.member_25[1u];
                                                    let _e5926 = ((_e5896 + (_e928 * (_e5914 * _e5917))) + (_e5272 * (_e5914 * _e5923)));
                                                    let _e5931 = (_e5905 * vec4<f32>(_e5926.x, _e5926.y, _e5926.z, 1f));
                                                    if (_e5931.w <= 0f) {
                                                        phi_19135_ = 1f;
                                                        break;
                                                    }
                                                    let _e5936 = (_e5931.xyz / vec3(_e5931.w));
                                                    let _e5938 = (_e5936.x < 0f);
                                                    phi_15746_ = _e5938;
                                                    if !(_e5938) {
                                                        phi_15746_ = (_e5936.x > 1f);
                                                    }
                                                    let _e5942 = phi_15746_;
                                                    phi_15753_ = _e5942;
                                                    if !(_e5942) {
                                                        phi_15753_ = (_e5936.y < 0f);
                                                    }
                                                    let _e5947 = phi_15753_;
                                                    phi_15760_ = _e5947;
                                                    if !(_e5947) {
                                                        phi_15760_ = (_e5936.y > 1f);
                                                    }
                                                    let _e5952 = phi_15760_;
                                                    phi_15767_ = _e5952;
                                                    if !(_e5952) {
                                                        phi_15767_ = (_e5936.z > 1f);
                                                    }
                                                    let _e5957 = phi_15767_;
                                                    if _e5957 {
                                                        phi_19135_ = 1f;
                                                        break;
                                                    }
                                                    let _e5960 = _e5902.xy;
                                                    let _e5962 = global.member_23;
                                                    let _e5963 = _e5962.zw;
                                                    let _e5965 = global.member_22;
                                                    let _e5966 = _e5965.xy;
                                                    let _e5967 = (_e5966 * 0.5f);
                                                    let _e5969 = (_e5960 + (_e5936.xy * _e5963));
                                                    let _e5970 = (_e5960 + _e5967);
                                                    let _e5972 = ((_e5960 + _e5963) - _e5967);
                                                    let _e5977 = vec4<f32>(_e5970.x, _e5970.y, _e5972.x, _e5972.y);
                                                    switch bitcast<i32>(0u) {
                                                        default: {
                                                            let _e5981 = global.member_22[2u];
                                                            let _e5982 = i32(_e5981);
                                                            if (_e5982 <= 0i) {
                                                                let _e5986 = clamp(_e5969, _e5977.xy, _e5977.zw);
                                                                let _e5991 = textureSampleCompare(global_2, global_1, vec3<f32>(_e5986.x, _e5986.y, _e5936.z).xy, _e5936.z);
                                                                phi_19134_ = _e5991;
                                                                break;
                                                            }
                                                            let _e5993 = ((_e5969 / _e5966) + vec2<f32>(0.5f, 0.5f));
                                                            let _e5994 = floor(_e5993);
                                                            let _e5995 = (_e5993 - _e5994);
                                                            let _e5997 = (_e5982 == 1i);
                                                            if _e5997 {
                                                                let _e5998 = (_e5995 * 2f);
                                                                local_15[0i] = (vec2<f32>(3f, 3f) - _e5998);
                                                                local_15[1i] = (vec2<f32>(1f, 1f) + _e5998);
                                                                let _e6004 = local_15[0i];
                                                                local_16[0i] = (((vec2<f32>(2f, 2f) - _e5995) / _e6004) - vec2<f32>(1f, 1f));
                                                                let _e6008 = local_15[1i];
                                                                local_16[1i] = ((_e5995 / _e6008) + vec2<f32>(1f, 1f));
                                                            } else {
                                                                let _e6012 = (_e5995 * 3f);
                                                                local_15[0i] = (vec2<f32>(4f, 4f) - _e6012);
                                                                local_15[1i] = vec2<f32>(7f, 7f);
                                                                local_15[2i] = (vec2<f32>(1f, 1f) + _e6012);
                                                                let _e6020 = local_15[0i];
                                                                local_16[0i] = (((vec2<f32>(3f, 3f) - (_e5995 * 2f)) / _e6020) - vec2<f32>(2f, 2f));
                                                                let _e6025 = local_15[1i];
                                                                local_16[1i] = ((vec2<f32>(3f, 3f) + _e5995) / _e6025);
                                                                let _e6028 = local_15[2i];
                                                                local_16[2i] = ((_e5995 / _e6028) + vec2<f32>(2f, 2f));
                                                            }
                                                            let _e6033 = select(3i, 2i, _e5997);
                                                            phi_19127_ = 0f;
                                                            phi_19124_ = 0i;
                                                            loop {
                                                                let _e6035 = phi_19127_;
                                                                let _e6037 = phi_19124_;
                                                                local_83 = _e6035;
                                                                if (_e6037 < _e6033) {
                                                                    phi_19133_ = _e6035;
                                                                    phi_19130_ = 0i;
                                                                    loop {
                                                                        let _e6040 = phi_19133_;
                                                                        let _e6042 = phi_19130_;
                                                                        local_108 = _e6040;
                                                                        if (_e6042 < _e6033) {
                                                                            continue;
                                                                        } else {
                                                                            break;
                                                                        }
                                                                        continuing {
                                                                            let _e6046 = local_16[_e6042][0u];
                                                                            let _e6049 = local_16[_e6037][1u];
                                                                            let _e6055 = clamp((_e5966 * ((_e5994 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e6046, _e6049))), _e5977.xy, _e5977.zw);
                                                                            let _e6058 = local_15[_e6042][0u];
                                                                            let _e6061 = local_15[_e6037][1u];
                                                                            let _e6067 = textureSampleCompare(global_2, global_1, vec3<f32>(_e6055.x, _e6055.y, _e5936.z).xy, _e5936.z);
                                                                            phi_19133_ = (_e6040 + ((_e6058 * _e6061) * _e6067));
                                                                            phi_19130_ = (_e6042 + 1i);
                                                                        }
                                                                    }
                                                                    continue;
                                                                } else {
                                                                    break;
                                                                }
                                                                continuing {
                                                                    let _e7409 = local_108;
                                                                    phi_19127_ = _e7409;
                                                                    phi_19124_ = (_e6037 + 1i);
                                                                }
                                                            }
                                                            let _e6073 = local_83;
                                                            phi_19134_ = (_e6073 * select(0.0069444445f, 0.0625f, _e5997));
                                                            break;
                                                        }
                                                    }
                                                    let _e6076 = phi_19134_;
                                                    phi_19135_ = _e6076;
                                                    break;
                                                }
                                                let _e6077 = (_e5258 - _e5898);
                                                if (_e6077 >= u32(_e5857)) {
                                                    phi_19135_ = 1f;
                                                    break;
                                                }
                                                let _e6082 = global.member_27[_e6077];
                                                let _e6085 = global.member_28[_e6077];
                                                let _e6087 = _e6082.xyz;
                                                let _e6090 = (_e6082.w * length((_e5896 - _e6087)));
                                                let _e6093 = global.member_25[0u];
                                                let _e6099 = global.member_25[1u];
                                                let _e6103 = (((_e5896 + (_e928 * (_e6090 * _e6093))) + (_e5272 * (_e6090 * _e6099))) - _e6087);
                                                let _e6104 = abs(_e6103);
                                                let _e6107 = (_e6104.x >= _e6104.y);
                                                phi_15837_ = _e6107;
                                                if _e6107 {
                                                    phi_15837_ = (_e6104.x >= _e6104.z);
                                                }
                                                let _e6111 = phi_15837_;
                                                if _e6111 {
                                                    phi_19111_ = select(1i, 0i, (_e6103.x > 0f));
                                                    phi_19109_ = _e6104.x;
                                                } else {
                                                    let _e6116 = (_e6104.y >= _e6104.z);
                                                    if _e6116 {
                                                        phi_19112_ = select(3i, 2i, (_e6103.y > 0f));
                                                    } else {
                                                        phi_19112_ = select(5i, 4i, (_e6103.z > 0f));
                                                    }
                                                    let _e6124 = phi_19112_;
                                                    phi_19111_ = _e6124;
                                                    phi_19109_ = select(_e6104.z, _e6104.y, _e6116);
                                                }
                                                let _e6127 = phi_19111_;
                                                let _e6129 = phi_19109_;
                                                if (_e6129 <= 0f) {
                                                    phi_19135_ = 1f;
                                                    break;
                                                }
                                                local_17 = array<vec3<f32>, 6>(vec3<f32>(0f, 0f, 1f), vec3<f32>(0f, 0f, -1f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(1f, 0f, 0f));
                                                let _e6132 = local_17[_e6127];
                                                local_18 = array<vec3<f32>, 6>(vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 0f, -1f), vec3<f32>(0f, 0f, 1f), vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 1f, 0f));
                                                let _e6135 = local_18[_e6127];
                                                let _e6140 = global.member_24[2u];
                                                let _e6143 = (vec2<f32>(dot(_e6103, _e6132), dot(_e6103, _e6135)) / vec2((_e6129 * _e6140)));
                                                let _e6147 = (_e6085.z + (_e6085.w / _e6129));
                                                if (_e6147 > 1f) {
                                                    phi_19135_ = 1f;
                                                    break;
                                                }
                                                let _e6162 = global.member_24;
                                                let _e6163 = _e6162.xy;
                                                let _e6165 = (_e6085.xy + (vec2<f32>(f32((_e6127 - (i32(floor((f32(_e6127) / f32(3i)))) * 3i))), f32((_e6127 / 3i))) * _e6163));
                                                let _e6174 = global.member_22;
                                                let _e6175 = _e6174.xy;
                                                let _e6176 = (_e6175 * 0.5f);
                                                let _e6178 = (_e6165 + (vec2<f32>((0.5f + (0.5f * _e6143.x)), (0.5f - (0.5f * _e6143.y))) * _e6163));
                                                let _e6179 = (_e6165 + _e6176);
                                                let _e6181 = ((_e6165 + _e6163) - _e6176);
                                                let _e6186 = vec4<f32>(_e6179.x, _e6179.y, _e6181.x, _e6181.y);
                                                switch bitcast<i32>(0u) {
                                                    default: {
                                                        let _e6190 = global.member_22[2u];
                                                        let _e6191 = i32(_e6190);
                                                        if (_e6191 <= 0i) {
                                                            let _e6195 = clamp(_e6178, _e6186.xy, _e6186.zw);
                                                            let _e6200 = textureSampleCompare(global_2, global_1, vec3<f32>(_e6195.x, _e6195.y, _e6147).xy, _e6147);
                                                            phi_19123_ = _e6200;
                                                            break;
                                                        }
                                                        let _e6202 = ((_e6178 / _e6175) + vec2<f32>(0.5f, 0.5f));
                                                        let _e6203 = floor(_e6202);
                                                        let _e6204 = (_e6202 - _e6203);
                                                        let _e6206 = (_e6191 == 1i);
                                                        if _e6206 {
                                                            let _e6207 = (_e6204 * 2f);
                                                            local_13[0i] = (vec2<f32>(3f, 3f) - _e6207);
                                                            local_13[1i] = (vec2<f32>(1f, 1f) + _e6207);
                                                            let _e6213 = local_13[0i];
                                                            local_14[0i] = (((vec2<f32>(2f, 2f) - _e6204) / _e6213) - vec2<f32>(1f, 1f));
                                                            let _e6217 = local_13[1i];
                                                            local_14[1i] = ((_e6204 / _e6217) + vec2<f32>(1f, 1f));
                                                        } else {
                                                            let _e6221 = (_e6204 * 3f);
                                                            local_13[0i] = (vec2<f32>(4f, 4f) - _e6221);
                                                            local_13[1i] = vec2<f32>(7f, 7f);
                                                            local_13[2i] = (vec2<f32>(1f, 1f) + _e6221);
                                                            let _e6229 = local_13[0i];
                                                            local_14[0i] = (((vec2<f32>(3f, 3f) - (_e6204 * 2f)) / _e6229) - vec2<f32>(2f, 2f));
                                                            let _e6234 = local_13[1i];
                                                            local_14[1i] = ((vec2<f32>(3f, 3f) + _e6204) / _e6234);
                                                            let _e6237 = local_13[2i];
                                                            local_14[2i] = ((_e6204 / _e6237) + vec2<f32>(2f, 2f));
                                                        }
                                                        let _e6242 = select(3i, 2i, _e6206);
                                                        phi_19116_ = 0f;
                                                        phi_19113_ = 0i;
                                                        loop {
                                                            let _e6244 = phi_19116_;
                                                            let _e6246 = phi_19113_;
                                                            local_84 = _e6244;
                                                            if (_e6246 < _e6242) {
                                                                phi_19122_ = _e6244;
                                                                phi_19119_ = 0i;
                                                                loop {
                                                                    let _e6249 = phi_19122_;
                                                                    let _e6251 = phi_19119_;
                                                                    local_109 = _e6249;
                                                                    if (_e6251 < _e6242) {
                                                                        continue;
                                                                    } else {
                                                                        break;
                                                                    }
                                                                    continuing {
                                                                        let _e6255 = local_14[_e6251][0u];
                                                                        let _e6258 = local_14[_e6246][1u];
                                                                        let _e6264 = clamp((_e6175 * ((_e6203 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e6255, _e6258))), _e6186.xy, _e6186.zw);
                                                                        let _e6267 = local_13[_e6251][0u];
                                                                        let _e6270 = local_13[_e6246][1u];
                                                                        let _e6276 = textureSampleCompare(global_2, global_1, vec3<f32>(_e6264.x, _e6264.y, _e6147).xy, _e6147);
                                                                        phi_19122_ = (_e6249 + ((_e6267 * _e6270) * _e6276));
                                                                        phi_19119_ = (_e6251 + 1i);
                                                                    }
                                                                }
                                                                continue;
                                                            } else {
                                                                break;
                                                            }
                                                            continuing {
                                                                let _e7421 = local_109;
                                                                phi_19116_ = _e7421;
                                                                phi_19113_ = (_e6246 + 1i);
                                                            }
                                                        }
                                                        let _e6282 = local_84;
                                                        phi_19123_ = (_e6282 * select(0.0069444445f, 0.0625f, _e6206));
                                                        break;
                                                    }
                                                }
                                                let _e6285 = phi_19123_;
                                                phi_19135_ = _e6285;
                                                break;
                                            }
                                        }
                                        let _e6287 = phi_19135_;
                                        if (_e6287 <= 0f) {
                                            phi_19198_ = vec3<f32>(0f, 0f, 0f);
                                            break;
                                        }
                                        phi_19138_ = vec3<f32>(1f, 1f, 1f);
                                        phi_19137_ = vec3<f32>(0f, 0f, 0f);
                                        phi_19136_ = 0i;
                                        loop {
                                            let _e6290 = phi_19138_;
                                            let _e6292 = phi_19137_;
                                            let _e6294 = phi_19136_;
                                            local_114 = _e6292;
                                            if (_e6294 < 4i) {
                                                local_19 = array<f32, 4>(0.002f, 0.005f, 0.01f, 0.02f);
                                                let _e6297 = local_19[_e6294];
                                                let _e6301 = global_18.member_1[1u];
                                                let _e6304 = ((_e6297 * 1000f) / (0.6f + (6f * _e6301)));
                                                let _e6306 = (-(_e6304) * _e6304);
                                                let _e6329 = ((((((vec3<f32>(0.233f, 0.455f, 0.649f) * exp((_e6306 * 156.25f))) + (vec3<f32>(0.1f, 0.336f, 0.344f) * exp((_e6306 * 20.661158f)))) + (vec3<f32>(0.118f, 0.198f, 0f) * exp((_e6306 * 5.3475933f)))) + (vec3<f32>(0.113f, 0.007f, 0.007f) * exp((_e6306 * 1.7636685f)))) + (vec3<f32>(0.358f, 0.004f, 0f) * exp((_e6306 * 0.5025126f)))) + (vec3<f32>(0.078f, 0f, 0f) * exp((_e6306 * 0.13495277f))));
                                                local_20 = array<f32, 4>(0.002f, 0.005f, 0.01f, 0.02f);
                                                let _e6332 = local_20[_e6294];
                                                let _e6334 = (_e5894 + (_e5272 * _e6332));
                                                local_110 = _e6329;
                                                switch bitcast<i32>(0u) {
                                                    default: {
                                                        let _e6337 = local_85;
                                                        if _e6337 {
                                                            let _e6340 = global.member_26[_e5258];
                                                            let _e6343 = global.member_15[_e5258];
                                                            let _e6352 = (_e6340.z * max((_e6343 * vec4<f32>(_e6334.x, _e6334.y, _e6334.z, 1f)).w, 0f));
                                                            let _e6355 = global.member_25[0u];
                                                            let _e6361 = global.member_25[1u];
                                                            let _e6364 = ((_e6334 + (_e928 * (_e6352 * _e6355))) + (_e5272 * (_e6352 * _e6361)));
                                                            let _e6369 = (_e6343 * vec4<f32>(_e6364.x, _e6364.y, _e6364.z, 1f));
                                                            if (_e6369.w <= 0f) {
                                                                phi_19165_ = 1f;
                                                                break;
                                                            }
                                                            let _e6374 = (_e6369.xyz / vec3(_e6369.w));
                                                            let _e6376 = (_e6374.x < 0f);
                                                            phi_16503_ = _e6376;
                                                            if !(_e6376) {
                                                                phi_16503_ = (_e6374.x > 1f);
                                                            }
                                                            let _e6380 = phi_16503_;
                                                            phi_16510_ = _e6380;
                                                            if !(_e6380) {
                                                                phi_16510_ = (_e6374.y < 0f);
                                                            }
                                                            let _e6385 = phi_16510_;
                                                            phi_16517_ = _e6385;
                                                            if !(_e6385) {
                                                                phi_16517_ = (_e6374.y > 1f);
                                                            }
                                                            let _e6390 = phi_16517_;
                                                            phi_16524_ = _e6390;
                                                            if !(_e6390) {
                                                                phi_16524_ = (_e6374.z > 1f);
                                                            }
                                                            let _e6395 = phi_16524_;
                                                            if _e6395 {
                                                                phi_19165_ = 1f;
                                                                break;
                                                            }
                                                            let _e6398 = _e6340.xy;
                                                            let _e6400 = global.member_23;
                                                            let _e6401 = _e6400.zw;
                                                            let _e6403 = global.member_22;
                                                            let _e6404 = _e6403.xy;
                                                            let _e6405 = (_e6404 * 0.5f);
                                                            let _e6407 = (_e6398 + (_e6374.xy * _e6401));
                                                            let _e6408 = (_e6398 + _e6405);
                                                            let _e6410 = ((_e6398 + _e6401) - _e6405);
                                                            let _e6415 = vec4<f32>(_e6408.x, _e6408.y, _e6410.x, _e6410.y);
                                                            switch bitcast<i32>(0u) {
                                                                default: {
                                                                    let _e6419 = global.member_22[2u];
                                                                    let _e6420 = i32(_e6419);
                                                                    if (_e6420 <= 0i) {
                                                                        let _e6424 = clamp(_e6407, _e6415.xy, _e6415.zw);
                                                                        let _e6429 = textureSampleCompare(global_2, global_1, vec3<f32>(_e6424.x, _e6424.y, _e6374.z).xy, _e6374.z);
                                                                        phi_19164_ = _e6429;
                                                                        break;
                                                                    }
                                                                    let _e6431 = ((_e6407 / _e6404) + vec2<f32>(0.5f, 0.5f));
                                                                    let _e6432 = floor(_e6431);
                                                                    let _e6433 = (_e6431 - _e6432);
                                                                    let _e6435 = (_e6420 == 1i);
                                                                    if _e6435 {
                                                                        let _e6436 = (_e6433 * 2f);
                                                                        local_9[0i] = (vec2<f32>(3f, 3f) - _e6436);
                                                                        local_9[1i] = (vec2<f32>(1f, 1f) + _e6436);
                                                                        let _e6442 = local_9[0i];
                                                                        local_10[0i] = (((vec2<f32>(2f, 2f) - _e6433) / _e6442) - vec2<f32>(1f, 1f));
                                                                        let _e6446 = local_9[1i];
                                                                        local_10[1i] = ((_e6433 / _e6446) + vec2<f32>(1f, 1f));
                                                                    } else {
                                                                        let _e6450 = (_e6433 * 3f);
                                                                        local_9[0i] = (vec2<f32>(4f, 4f) - _e6450);
                                                                        local_9[1i] = vec2<f32>(7f, 7f);
                                                                        local_9[2i] = (vec2<f32>(1f, 1f) + _e6450);
                                                                        let _e6458 = local_9[0i];
                                                                        local_10[0i] = (((vec2<f32>(3f, 3f) - (_e6433 * 2f)) / _e6458) - vec2<f32>(2f, 2f));
                                                                        let _e6463 = local_9[1i];
                                                                        local_10[1i] = ((vec2<f32>(3f, 3f) + _e6433) / _e6463);
                                                                        let _e6466 = local_9[2i];
                                                                        local_10[2i] = ((_e6433 / _e6466) + vec2<f32>(2f, 2f));
                                                                    }
                                                                    let _e6471 = select(3i, 2i, _e6435);
                                                                    phi_19157_ = 0f;
                                                                    phi_19154_ = 0i;
                                                                    loop {
                                                                        let _e6473 = phi_19157_;
                                                                        let _e6475 = phi_19154_;
                                                                        local_86 = _e6473;
                                                                        if (_e6475 < _e6471) {
                                                                            phi_19163_ = _e6473;
                                                                            phi_19160_ = 0i;
                                                                            loop {
                                                                                let _e6478 = phi_19163_;
                                                                                let _e6480 = phi_19160_;
                                                                                local_112 = _e6478;
                                                                                if (_e6480 < _e6471) {
                                                                                    continue;
                                                                                } else {
                                                                                    break;
                                                                                }
                                                                                continuing {
                                                                                    let _e6484 = local_10[_e6480][0u];
                                                                                    let _e6487 = local_10[_e6475][1u];
                                                                                    let _e6493 = clamp((_e6404 * ((_e6432 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e6484, _e6487))), _e6415.xy, _e6415.zw);
                                                                                    let _e6496 = local_9[_e6480][0u];
                                                                                    let _e6499 = local_9[_e6475][1u];
                                                                                    let _e6505 = textureSampleCompare(global_2, global_1, vec3<f32>(_e6493.x, _e6493.y, _e6374.z).xy, _e6374.z);
                                                                                    phi_19163_ = (_e6478 + ((_e6496 * _e6499) * _e6505));
                                                                                    phi_19160_ = (_e6480 + 1i);
                                                                                }
                                                                            }
                                                                            continue;
                                                                        } else {
                                                                            break;
                                                                        }
                                                                        continuing {
                                                                            let _e7442 = local_112;
                                                                            phi_19157_ = _e7442;
                                                                            phi_19154_ = (_e6475 + 1i);
                                                                        }
                                                                    }
                                                                    let _e6511 = local_86;
                                                                    phi_19164_ = (_e6511 * select(0.0069444445f, 0.0625f, _e6435));
                                                                    break;
                                                                }
                                                            }
                                                            let _e6514 = phi_19164_;
                                                            phi_19165_ = _e6514;
                                                            break;
                                                        }
                                                        let _e6516 = local_87;
                                                        let _e6517 = (_e5258 - _e6516);
                                                        if (_e6517 >= u32(_e5857)) {
                                                            phi_19165_ = 1f;
                                                            break;
                                                        }
                                                        let _e6522 = global.member_27[_e6517];
                                                        let _e6525 = global.member_28[_e6517];
                                                        let _e6527 = _e6522.xyz;
                                                        let _e6530 = (_e6522.w * length((_e6334 - _e6527)));
                                                        let _e6533 = global.member_25[0u];
                                                        let _e6539 = global.member_25[1u];
                                                        let _e6543 = (((_e6334 + (_e928 * (_e6530 * _e6533))) + (_e5272 * (_e6530 * _e6539))) - _e6527);
                                                        let _e6544 = abs(_e6543);
                                                        let _e6547 = (_e6544.x >= _e6544.y);
                                                        phi_16594_ = _e6547;
                                                        if _e6547 {
                                                            phi_16594_ = (_e6544.x >= _e6544.z);
                                                        }
                                                        let _e6551 = phi_16594_;
                                                        if _e6551 {
                                                            phi_19141_ = select(1i, 0i, (_e6543.x > 0f));
                                                            phi_19139_ = _e6544.x;
                                                        } else {
                                                            let _e6556 = (_e6544.y >= _e6544.z);
                                                            if _e6556 {
                                                                phi_19142_ = select(3i, 2i, (_e6543.y > 0f));
                                                            } else {
                                                                phi_19142_ = select(5i, 4i, (_e6543.z > 0f));
                                                            }
                                                            let _e6564 = phi_19142_;
                                                            phi_19141_ = _e6564;
                                                            phi_19139_ = select(_e6544.z, _e6544.y, _e6556);
                                                        }
                                                        let _e6567 = phi_19141_;
                                                        let _e6569 = phi_19139_;
                                                        if (_e6569 <= 0f) {
                                                            phi_19165_ = 1f;
                                                            break;
                                                        }
                                                        local_11 = array<vec3<f32>, 6>(vec3<f32>(0f, 0f, 1f), vec3<f32>(0f, 0f, -1f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(1f, 0f, 0f));
                                                        let _e6572 = local_11[_e6567];
                                                        local_12 = array<vec3<f32>, 6>(vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 0f, -1f), vec3<f32>(0f, 0f, 1f), vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 1f, 0f));
                                                        let _e6575 = local_12[_e6567];
                                                        let _e6580 = global.member_24[2u];
                                                        let _e6583 = (vec2<f32>(dot(_e6543, _e6572), dot(_e6543, _e6575)) / vec2((_e6569 * _e6580)));
                                                        let _e6587 = (_e6525.z + (_e6525.w / _e6569));
                                                        if (_e6587 > 1f) {
                                                            phi_19165_ = 1f;
                                                            break;
                                                        }
                                                        let _e6602 = global.member_24;
                                                        let _e6603 = _e6602.xy;
                                                        let _e6605 = (_e6525.xy + (vec2<f32>(f32((_e6567 - (i32(floor((f32(_e6567) / f32(3i)))) * 3i))), f32((_e6567 / 3i))) * _e6603));
                                                        let _e6614 = global.member_22;
                                                        let _e6615 = _e6614.xy;
                                                        let _e6616 = (_e6615 * 0.5f);
                                                        let _e6618 = (_e6605 + (vec2<f32>((0.5f + (0.5f * _e6583.x)), (0.5f - (0.5f * _e6583.y))) * _e6603));
                                                        let _e6619 = (_e6605 + _e6616);
                                                        let _e6621 = ((_e6605 + _e6603) - _e6616);
                                                        let _e6626 = vec4<f32>(_e6619.x, _e6619.y, _e6621.x, _e6621.y);
                                                        switch bitcast<i32>(0u) {
                                                            default: {
                                                                let _e6630 = global.member_22[2u];
                                                                let _e6631 = i32(_e6630);
                                                                if (_e6631 <= 0i) {
                                                                    let _e6635 = clamp(_e6618, _e6626.xy, _e6626.zw);
                                                                    let _e6640 = textureSampleCompare(global_2, global_1, vec3<f32>(_e6635.x, _e6635.y, _e6587).xy, _e6587);
                                                                    phi_19153_ = _e6640;
                                                                    break;
                                                                }
                                                                let _e6642 = ((_e6618 / _e6615) + vec2<f32>(0.5f, 0.5f));
                                                                let _e6643 = floor(_e6642);
                                                                let _e6644 = (_e6642 - _e6643);
                                                                let _e6646 = (_e6631 == 1i);
                                                                if _e6646 {
                                                                    let _e6647 = (_e6644 * 2f);
                                                                    local_7[0i] = (vec2<f32>(3f, 3f) - _e6647);
                                                                    local_7[1i] = (vec2<f32>(1f, 1f) + _e6647);
                                                                    let _e6653 = local_7[0i];
                                                                    local_8[0i] = (((vec2<f32>(2f, 2f) - _e6644) / _e6653) - vec2<f32>(1f, 1f));
                                                                    let _e6657 = local_7[1i];
                                                                    local_8[1i] = ((_e6644 / _e6657) + vec2<f32>(1f, 1f));
                                                                } else {
                                                                    let _e6661 = (_e6644 * 3f);
                                                                    local_7[0i] = (vec2<f32>(4f, 4f) - _e6661);
                                                                    local_7[1i] = vec2<f32>(7f, 7f);
                                                                    local_7[2i] = (vec2<f32>(1f, 1f) + _e6661);
                                                                    let _e6669 = local_7[0i];
                                                                    local_8[0i] = (((vec2<f32>(3f, 3f) - (_e6644 * 2f)) / _e6669) - vec2<f32>(2f, 2f));
                                                                    let _e6674 = local_7[1i];
                                                                    local_8[1i] = ((vec2<f32>(3f, 3f) + _e6644) / _e6674);
                                                                    let _e6677 = local_7[2i];
                                                                    local_8[2i] = ((_e6644 / _e6677) + vec2<f32>(2f, 2f));
                                                                }
                                                                let _e6682 = select(3i, 2i, _e6646);
                                                                phi_19146_ = 0f;
                                                                phi_19143_ = 0i;
                                                                loop {
                                                                    let _e6684 = phi_19146_;
                                                                    let _e6686 = phi_19143_;
                                                                    local_88 = _e6684;
                                                                    if (_e6686 < _e6682) {
                                                                        phi_19152_ = _e6684;
                                                                        phi_19149_ = 0i;
                                                                        loop {
                                                                            let _e6689 = phi_19152_;
                                                                            let _e6691 = phi_19149_;
                                                                            local_113 = _e6689;
                                                                            if (_e6691 < _e6682) {
                                                                                continue;
                                                                            } else {
                                                                                break;
                                                                            }
                                                                            continuing {
                                                                                let _e6695 = local_8[_e6691][0u];
                                                                                let _e6698 = local_8[_e6686][1u];
                                                                                let _e6704 = clamp((_e6615 * ((_e6643 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e6695, _e6698))), _e6626.xy, _e6626.zw);
                                                                                let _e6707 = local_7[_e6691][0u];
                                                                                let _e6710 = local_7[_e6686][1u];
                                                                                let _e6716 = textureSampleCompare(global_2, global_1, vec3<f32>(_e6704.x, _e6704.y, _e6587).xy, _e6587);
                                                                                phi_19152_ = (_e6689 + ((_e6707 * _e6710) * _e6716));
                                                                                phi_19149_ = (_e6691 + 1i);
                                                                            }
                                                                        }
                                                                        continue;
                                                                    } else {
                                                                        break;
                                                                    }
                                                                    continuing {
                                                                        let _e7455 = local_113;
                                                                        phi_19146_ = _e7455;
                                                                        phi_19143_ = (_e6686 + 1i);
                                                                    }
                                                                }
                                                                let _e6722 = local_88;
                                                                phi_19153_ = (_e6722 * select(0.0069444445f, 0.0625f, _e6646));
                                                                break;
                                                            }
                                                        }
                                                        let _e6725 = phi_19153_;
                                                        phi_19165_ = _e6725;
                                                        break;
                                                    }
                                                }
                                                let _e6727 = phi_19165_;
                                                local_111 = (_e6292 + ((_e6290 - _e6329) * _e6727));
                                                continue;
                                            } else {
                                                break;
                                            }
                                            continuing {
                                                let _e7430 = local_110;
                                                phi_19138_ = _e7430;
                                                let _e7433 = local_111;
                                                phi_19137_ = _e7433;
                                                phi_19136_ = (_e6294 + 1i);
                                            }
                                        }
                                        let _e7464 = local_114;
                                        phi_19198_ = _e7464;
                                        break;
                                    }
                                }
                                let _e6732 = phi_19198_;
                                phi_19199_ = _e6732;
                            } else {
                                let _e6736 = global_18.member_1[1u];
                                let _e6739 = ((1200f / _e4439) / (0.6f + (6f * _e6736)));
                                let _e6741 = (-(_e6739) * _e6739);
                                phi_19199_ = ((((((vec3<f32>(0.233f, 0.455f, 0.649f) * exp((_e6741 * 156.25f))) + (vec3<f32>(0.1f, 0.336f, 0.344f) * exp((_e6741 * 20.661158f)))) + (vec3<f32>(0.118f, 0.198f, 0f) * exp((_e6741 * 5.3475933f)))) + (vec3<f32>(0.113f, 0.007f, 0.007f) * exp((_e6741 * 1.7636685f)))) + (vec3<f32>(0.358f, 0.004f, 0f) * exp((_e6741 * 0.5025126f)))) + (vec3<f32>(0.078f, 0f, 0f) * exp((_e6741 * 0.13495277f))));
                            }
                            let _e6766 = phi_19199_;
                            phi_19895_ = (_e5758 + ((_e6766 * _e5293) * ((clamp((0.3f - dot(_e928, _e5272)), 0f, 1f) * _e4427) * 2f)));
                        }
                        let _e6776 = phi_19895_;
                        local_105 = _e6776;
                        continue;
                    } else {
                        break;
                    }
                    continuing {
                        let _e7365 = local_104;
                        phi_19016_ = _e7365;
                        let _e7368 = local_105;
                        phi_18981_ = _e7368;
                        phi_18916_ = (_e5242 + bitcast<u32>(1i));
                    }
                }
                let _e7469 = local_115;
                phi_18991_ = _e7469;
                let _e7472 = local_116;
                phi_18979_ = _e7472;
            }
            let _e6780 = phi_18991_;
            let _e6782 = phi_18979_;
            let _e6785 = global_18.member_2[0u];
            let _e6788 = global_18.member_2[1u];
            let _e6791 = global_18.member_2[2u];
            let _e6794 = clamp((_e2030 * mix(_e6785, _e6788, _e6791)), 0.045f, 1f);
            let _e6796 = reflect(-(_e923), _e4399);
            let _e6799 = global.member_29[0u];
            let _e6800 = (_e6799 > 0.5f);
            if _e6800 {
                let _e6802 = global.member_29;
                let _e6809 = ((_e6802.z * _e4399.x) - (_e6802.w * _e4399.z));
                let _e6813 = ((_e6802.w * _e4399.x) + (_e6802.z * _e4399.z));
                let _e6817 = (1.092548f * _e6809);
                local_6 = array<f32, 9>(0.282095f, (0.488603f * _e4399.y), (0.488603f * _e6813), (0.488603f * _e6809), (_e6817 * _e4399.y), ((1.092548f * _e4399.y) * _e6813), (0.315392f * (((3f * _e6813) * _e6813) - 1f)), (_e6817 * _e6813), (0.546274f * ((_e6809 * _e6809) - (_e4399.y * _e4399.y))));
                phi_18946_ = vec3<f32>(0f, 0f, 0f);
                phi_18945_ = 0i;
                loop {
                    let _e6832 = phi_18946_;
                    let _e6834 = phi_18945_;
                    local_89 = _e6832;
                    if (_e6834 < 9i) {
                        continue;
                    } else {
                        break;
                    }
                    continuing {
                        let _e6838 = textureLoad(global_3, (vec2<i32>(496i, 256i) + vec2<i32>(_e6834, 0i)), 0i);
                        let _e6841 = local_6[_e6834];
                        phi_18946_ = (_e6832 + (_e6838.xyz * _e6841));
                        phi_18945_ = (_e6834 + 1i);
                    }
                }
                let _e6846 = local_89;
                let _e6850 = global.member_29[1u];
                let _e6868 = vec2<f32>(((atan2(((_e6802.z * _e6796.x) - (_e6802.w * _e6796.z)), -(((_e6802.w * _e6796.x) + (_e6802.z * _e6796.z)))) * 0.15915494f) + 0.5f), (acos(clamp(_e6796.y, -1f, 1f)) * 0.31830987f));
                let _e6869 = (_e6794 * 5f);
                let _e6871 = min(i32(_e6869), 4i);
                local_4 = array<vec4<i32>, 6>(vec4<i32>(0i, 0i, 512i, 256i), vec4<i32>(0i, 256i, 256i, 128i), vec4<i32>(256i, 256i, 128i, 64i), vec4<i32>(384i, 256i, 64i, 32i), vec4<i32>(448i, 256i, 32i, 16i), vec4<i32>(480i, 256i, 16i, 8i));
                let _e6873 = local_4[_e6871];
                let _e6877 = ((_e6868 * vec2<f32>(_e6873.zw)) - vec2<f32>(0.5f, 0.5f));
                let _e6878 = floor(_e6877);
                let _e6879 = (_e6877 - _e6878);
                let _e6881 = i32(_e6878.x);
                let _e6883 = i32(_e6878.y);
                phi_18947_ = _e6881;
                if (_e6881 < 0i) {
                    phi_18947_ = (_e6881 + _e6873.z);
                }
                let _e6888 = phi_18947_;
                phi_18948_ = _e6888;
                if (_e6888 >= _e6873.z) {
                    phi_18948_ = (_e6888 - _e6873.z);
                }
                let _e6893 = phi_18948_;
                let _e6894 = (_e6893 + 1i);
                let _e6896 = select(_e6894, 0i, (_e6894 == _e6873.z));
                let _e6900 = min((_e6883 + 1i), (_e6873.w - 1i));
                let _e6901 = max(_e6883, 0i);
                let _e6902 = _e6873.xy;
                let _e6905 = textureLoad(global_3, (_e6902 + vec2<i32>(_e6893, _e6901)), 0i);
                let _e6909 = textureLoad(global_3, (_e6902 + vec2<i32>(_e6896, _e6901)), 0i);
                let _e6913 = textureLoad(global_3, (_e6902 + vec2<i32>(_e6893, _e6900)), 0i);
                let _e6917 = textureLoad(global_3, (_e6902 + vec2<i32>(_e6896, _e6900)), 0i);
                let _e6920 = vec3(_e6879.x);
                local_5 = array<vec4<i32>, 6>(vec4<i32>(0i, 0i, 512i, 256i), vec4<i32>(0i, 256i, 256i, 128i), vec4<i32>(256i, 256i, 128i, 64i), vec4<i32>(384i, 256i, 64i, 32i), vec4<i32>(448i, 256i, 32i, 16i), vec4<i32>(480i, 256i, 16i, 8i));
                let _e6928 = local_5[(_e6871 + 1i)];
                let _e6932 = ((_e6868 * vec2<f32>(_e6928.zw)) - vec2<f32>(0.5f, 0.5f));
                let _e6933 = floor(_e6932);
                let _e6934 = (_e6932 - _e6933);
                let _e6936 = i32(_e6933.x);
                let _e6938 = i32(_e6933.y);
                phi_18954_ = _e6936;
                if (_e6936 < 0i) {
                    phi_18954_ = (_e6936 + _e6928.z);
                }
                let _e6943 = phi_18954_;
                phi_18955_ = _e6943;
                if (_e6943 >= _e6928.z) {
                    phi_18955_ = (_e6943 - _e6928.z);
                }
                let _e6948 = phi_18955_;
                let _e6949 = (_e6948 + 1i);
                let _e6951 = select(_e6949, 0i, (_e6949 == _e6928.z));
                let _e6955 = min((_e6938 + 1i), (_e6928.w - 1i));
                let _e6956 = max(_e6938, 0i);
                let _e6957 = _e6928.xy;
                let _e6960 = textureLoad(global_3, (_e6957 + vec2<i32>(_e6948, _e6956)), 0i);
                let _e6964 = textureLoad(global_3, (_e6957 + vec2<i32>(_e6951, _e6956)), 0i);
                let _e6968 = textureLoad(global_3, (_e6957 + vec2<i32>(_e6948, _e6955)), 0i);
                let _e6972 = textureLoad(global_3, (_e6957 + vec2<i32>(_e6951, _e6955)), 0i);
                let _e6975 = vec3(_e6934.x);
                phi_18968_ = (mix(mix(mix(_e6905.xyz, _e6909.xyz, _e6920), mix(_e6913.xyz, _e6917.xyz, _e6920), vec3(_e6879.y)), mix(mix(_e6960.xyz, _e6964.xyz, _e6975), mix(_e6968.xyz, _e6972.xyz, _e6975), vec3(_e6934.y)), vec3((_e6869 - f32(_e6871)))) * _e6850);
                phi_18961_ = (max(_e6846, vec3<f32>(0f, 0f, 0f)) * _e6850);
            } else {
                let _e6987 = global.member_9;
                let _e6988 = _e6987.xyz;
                let _e6990 = global.member_8;
                let _e6991 = _e6990.xyz;
                let _e6999 = global.member_8[3u];
                let _e7000 = (mix(_e6988, _e6991, vec3(((_e4399.y * 0.5f) + 0.5f))) * _e6999);
                phi_18968_ = mix((mix(_e6988, _e6991, vec3(((_e6796.y * 0.5f) + 0.5f))) * _e6999), _e7000, vec3(_e6794));
                phi_18961_ = _e7000;
            }
            let _e7010 = phi_18968_;
            let _e7012 = phi_18961_;
            if _e6800 {
                let _e7017 = textureSample(global_5, global_6, (((vec2<f32>(_e4401, _e6794) * 31f) + vec2<f32>(0.5f, 0.5f)) * vec2<f32>(0.03125f, 0.03125f)));
                phi_18969_ = _e7017.xy;
            } else {
                let _e7020 = ((vec4<f32>(-1f, -0.0275f, -0.572f, 0.022f) * _e6794) + vec4<f32>(1f, 0.0425f, 1.04f, -0.04f));
                phi_18969_ = ((vec2<f32>(-1.04f, 1.04f) * ((min((_e7020.x * _e7020.x), exp2((-9.28f * _e4401))) * _e7020.x) + _e7020.y)) + _e7020.zw);
            }
            let _e7033 = phi_18969_;
            let _e7038 = ((_e4405 * _e7033.x) + vec3(_e7033.y));
            let _e7047 = (_e6780 + ((_e7038 * _e7010) * _e1375));
            phi_19549_ = _e7047;
            phi_19407_ = (((_e1346 * (1f - _e2028)) * ((_e6782 * (vec3<f32>(1f, 1f, 1f) - _e4405)) + (((vec3<f32>(1f, 1f, 1f) - _e7038) * _e7012) * _e1375))) + _e7047);
        }
        let _e7051 = phi_19549_;
        let _e7053 = phi_19407_;
        phi_19544_ = _e7051;
        phi_19404_ = _e7053;
    }
    let _e7055 = phi_19544_;
    let _e7057 = phi_19404_;
    let _e7060 = global_7.member_1[1u];
    let _e7064 = global_7.member_5;
    let _e7066 = textureSample(global_27, global_4, _e392);
    let _e7069 = global_24;
    let _e7075 = -(length(_e922));
    let _e7078 = global.member_7[3u];
    let _e7084 = global.member_9[3u];
    phi_19540_ = (1f - exp((_e7075 * _e7078)));
    if (_e7084 != 0f) {
        let _e7088 = (_e7084 * (_e921 - _e920).y);
        if (abs(_e7088) < 0.0001f) {
            phi_19537_ = (1f - (0.5f * _e7088));
        } else {
            phi_19537_ = ((1f - exp(min(-(_e7088), 60f))) / _e7088);
        }
        let _e7099 = phi_19537_;
        let _e7103 = global.member_6[1u];
        let _e7106 = global.member_6[3u];
        phi_19540_ = (1f - exp(((_e7075 * (_e7078 * exp(min((-(_e7084) * (_e7103 - _e7106)), 30f)))) * _e7099)));
    }
    let _e7117 = phi_19540_;
    let _e7119 = global.member_7;
    let _e7122 = mix((mix(_e7057, _e1346, vec3(_e7060)) + ((_e7064.xyz * _e7066.xyz) * (vec3<f32>(1f, 1f, 1f) + _e7069.yzw))), _e7119.xyz, vec3(_e7117));
    let _e7125 = global.member_33[3u];
    phi_19555_ = _e7122;
    if (_e7125 > 0.5f) {
        phi_19555_ = (_e7122 / (vec3<f32>(1f, 1f, 1f) + _e7122));
    }
    let _e7130 = phi_19555_;
    let _e7133 = global_18.member_1[3u];
    let _e7134 = (_e7133 > 0.5f);
    phi_5004_ = _e7134;
    if _e7134 {
        phi_5004_ = (_e7125 < 0.5f);
    }
    let _e7137 = phi_5004_;
    phi_19556_ = ((_e403 * _e406) * _e393.w);
    if _e7137 {
        phi_19556_ = (-1f - max(dot((_e7055 * (1f - _e7117)), vec3<f32>(0.2126f, 0.7152f, 0.0722f)), 0f));
    }
    let _e7144 = phi_19556_;
    global_28 = vec4<f32>(_e7130.x, _e7130.y, _e7130.z, _e7144);
    let _e7149 = global_30;
    let _e7150 = global_31;
    switch bitcast<i32>(0u) {
        default: {
            if (_e7150.w <= 0f) {
                phi_19728_ = vec2<f32>(0f, 0f);
                break;
            }
            phi_19728_ = (((_e7150.xy / vec2(_e7150.w)) - (_e7149.xy / vec2(_e7149.w))) * vec2<f32>(0.5f, -0.5f));
            break;
        }
    }
    let _e7164 = phi_19728_;
    global_29 = _e7164;
    return;
}

@fragment 
fn main(@location(1) param: vec3<f32>, @location(8) param_1: vec4<f32>, @location(4) param_2: vec3<f32>, @location(0) param_3: vec3<f32>, @builtin(position) param_4: vec4<f32>, @builtin(front_facing) param_5: bool, @location(2) param_6: vec2<f32>, @location(3) param_7: vec4<f32>, @location(5) param_8: vec4<f32>, @location(6) param_9: vec4<f32>, @location(7) param_10: vec4<f32>) -> FragmentOutput {
    global_8 = param;
    global_9 = param_1;
    global_10 = param_2;
    global_12 = param_3;
    global_15 = param_4;
    global_19 = param_5;
    global_20 = param_6;
    global_22 = param_7;
    global_24 = param_8;
    global_30 = param_9;
    global_31 = param_10;
    function_();
    let _e24 = global_28;
    let _e25 = global_29;
    return FragmentOutput(_e24, _e25);
}
