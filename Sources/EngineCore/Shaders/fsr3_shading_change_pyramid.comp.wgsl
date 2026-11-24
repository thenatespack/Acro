// Generated from fsr3_shading_change_pyramid.comp by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: 28841895df1f75d4
// glsl-fnv1a64: 13f1c8af5b6ad0df

diagnostic(off, derivative_uniformity);

struct type_13 {
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
var<uniform> global: type_13;
@group(2) @binding(9) 
var global_1: texture_2d<f32>;
@group(2) @binding(10) 
var global_2: texture_2d<f32>;
@group(2) @binding(11) 
var global_3: texture_2d<f32>;
@group(2) @binding(32) 
var global_4: texture_storage_2d<rg16float,write>;
@group(2) @binding(33) 
var global_5: texture_storage_2d<rg16float,write>;
@group(2) @binding(34) 
var global_6: texture_storage_2d<rg16float,write>;
var<workgroup> global_7: u32;
var<workgroup> global_8: array<array<f32, 16>, 16>;
var<workgroup> global_9: array<array<f32, 16>, 16>;
var<workgroup> global_10: array<array<f32, 16>, 16>;
var<workgroup> global_11: array<array<f32, 16>, 16>;
var<private> global_12: vec3<u32>;
var<private> global_13: u32;

fn function_() {
    var local: array<f32, 5>;
    var local_1: array<f32, 5>;
    var local_2: array<f32, 5>;
    var local_3: array<f32, 5>;
    var local_4: array<f32, 5>;
    var local_5: array<f32, 5>;
    var local_6: array<f32, 5>;
    var local_7: array<f32, 5>;
    var local_8: array<f32, 5>;
    var local_9: array<f32, 5>;
    var local_10: array<f32, 5>;
    var local_11: array<f32, 5>;
    var local_12: array<f32, 5>;
    var local_13: array<f32, 5>;
    var local_14: array<f32, 5>;
    var local_15: array<f32, 5>;
    var local_16: array<f32, 5>;
    var local_17: array<f32, 5>;
    var local_18: array<f32, 5>;
    var local_19: array<f32, 5>;
    var local_20: array<f32, 5>;
    var local_21: array<f32, 5>;
    var local_22: array<f32, 5>;
    var local_23: array<f32, 5>;
    var local_24: array<f32, 5>;
    var local_25: array<f32, 5>;
    var local_26: array<f32, 5>;
    var local_27: array<f32, 5>;
    var local_28: array<f32, 5>;
    var local_29: array<f32, 5>;
    var local_30: array<f32, 5>;
    var local_31: array<f32, 5>;
    var local_32: array<f32, 5>;
    var local_33: array<f32, 5>;
    var local_34: array<f32, 5>;
    var local_35: array<f32, 5>;
    var local_36: array<f32, 5>;
    var local_37: array<f32, 5>;
    var local_38: array<f32, 5>;
    var local_39: array<f32, 5>;
    var local_40: array<f32, 5>;
    var local_41: array<f32, 5>;
    var local_42: array<f32, 5>;
    var local_43: array<f32, 5>;
    var local_44: array<f32, 5>;
    var local_45: array<f32, 5>;
    var local_46: array<f32, 5>;
    var local_47: array<f32, 5>;
    var local_48: array<f32, 5>;
    var local_49: array<f32, 5>;
    var local_50: array<f32, 5>;
    var local_51: array<f32, 5>;
    var local_52: array<f32, 5>;
    var local_53: array<f32, 5>;
    var local_54: array<f32, 5>;
    var local_55: array<f32, 5>;
    var local_56: array<f32, 5>;
    var local_57: array<f32, 5>;
    var local_58: array<f32, 5>;
    var local_59: array<f32, 5>;
    var local_60: array<f32, 5>;
    var local_61: array<f32, 5>;
    var local_62: array<f32, 5>;
    var local_63: array<f32, 5>;
    var local_64: array<vec2<i32>, 5>;
    var local_65: array<vec2<i32>, 5>;
    var local_66: array<vec2<i32>, 5>;
    var local_67: array<vec2<i32>, 5>;
    var local_68: array<vec2<i32>, 5>;
    var local_69: array<vec2<i32>, 5>;
    var local_70: array<vec2<i32>, 5>;
    var local_71: array<vec2<i32>, 5>;
    var local_72: array<vec2<i32>, 5>;
    var local_73: array<vec2<i32>, 5>;
    var local_74: array<vec2<i32>, 5>;
    var local_75: array<vec2<i32>, 5>;
    var local_76: array<vec2<i32>, 5>;
    var local_77: array<vec2<i32>, 5>;
    var local_78: array<vec2<i32>, 5>;
    var local_79: array<vec2<i32>, 5>;
    var local_80: array<vec2<i32>, 5>;
    var local_81: array<vec2<i32>, 5>;
    var local_82: array<vec2<i32>, 5>;
    var local_83: array<vec2<i32>, 5>;
    var local_84: array<vec2<i32>, 5>;
    var local_85: array<vec2<i32>, 5>;
    var local_86: array<vec2<i32>, 5>;
    var local_87: array<vec2<i32>, 5>;
    var local_88: array<vec2<i32>, 5>;
    var local_89: array<vec2<i32>, 5>;
    var local_90: array<vec2<i32>, 5>;
    var local_91: array<vec2<i32>, 5>;
    var local_92: array<vec2<i32>, 5>;
    var local_93: array<vec2<i32>, 5>;
    var local_94: array<vec2<i32>, 5>;
    var local_95: array<vec2<i32>, 5>;
    var local_96: array<vec4<f32>, 4>;
    var phi_29743_: vec4<f32>;
    var phi_29744_: i32;
    var phi_30358_: vec4<f32>;
    var phi_3343_: bool;
    var phi_3353_: bool;
    var phi_3355_: bool;
    var phi_29745_: i32;
    var phi_30356_: vec4<f32>;
    var phi_30349_: i32;
    var phi_30348_: i32;
    var phi_29747_: f32;
    var phi_29746_: i32;
    var phi_30350_: f32;
    var phi_30503_: i32;
    var phi_30502_: i32;
    var phi_30360_: f32;
    var phi_29748_: f32;
    var phi_29749_: f32;
    var phi_29756_: f32;
    var phi_29758_: vec4<f32>;
    var phi_29759_: i32;
    var phi_30346_: vec4<f32>;
    var phi_4499_: bool;
    var phi_4509_: bool;
    var phi_4511_: bool;
    var phi_29760_: i32;
    var phi_30344_: vec4<f32>;
    var phi_30337_: i32;
    var phi_30336_: i32;
    var phi_29762_: f32;
    var phi_29761_: i32;
    var phi_30338_: f32;
    var phi_30501_: i32;
    var phi_30500_: i32;
    var phi_30363_: f32;
    var phi_29763_: f32;
    var phi_29764_: f32;
    var phi_29771_: f32;
    var phi_29773_: vec4<f32>;
    var phi_29774_: i32;
    var phi_30334_: vec4<f32>;
    var phi_5655_: bool;
    var phi_5665_: bool;
    var phi_5667_: bool;
    var phi_29775_: i32;
    var phi_30332_: vec4<f32>;
    var phi_30325_: i32;
    var phi_30324_: i32;
    var phi_29777_: f32;
    var phi_29776_: i32;
    var phi_30326_: f32;
    var phi_30499_: i32;
    var phi_30498_: i32;
    var phi_30366_: f32;
    var phi_29778_: f32;
    var phi_29779_: f32;
    var phi_29786_: f32;
    var phi_29788_: vec4<f32>;
    var phi_29789_: i32;
    var phi_30322_: vec4<f32>;
    var phi_6811_: bool;
    var phi_6821_: bool;
    var phi_6823_: bool;
    var phi_29790_: i32;
    var phi_30320_: vec4<f32>;
    var phi_30313_: i32;
    var phi_30312_: i32;
    var phi_29792_: f32;
    var phi_29791_: i32;
    var phi_30314_: f32;
    var phi_30497_: i32;
    var phi_30496_: i32;
    var phi_30369_: f32;
    var phi_29793_: f32;
    var phi_29794_: f32;
    var phi_29801_: f32;
    var phi_29847_: vec4<f32>;
    var phi_29848_: i32;
    var phi_30310_: vec4<f32>;
    var phi_8108_: bool;
    var phi_8118_: bool;
    var phi_8120_: bool;
    var phi_29849_: i32;
    var phi_30308_: vec4<f32>;
    var phi_30301_: i32;
    var phi_30300_: i32;
    var phi_29851_: f32;
    var phi_29850_: i32;
    var phi_30302_: f32;
    var phi_30495_: i32;
    var phi_30494_: i32;
    var phi_30388_: f32;
    var phi_29852_: f32;
    var phi_29853_: f32;
    var phi_29860_: f32;
    var phi_29862_: vec4<f32>;
    var phi_29863_: i32;
    var phi_30298_: vec4<f32>;
    var phi_9264_: bool;
    var phi_9274_: bool;
    var phi_9276_: bool;
    var phi_29864_: i32;
    var phi_30296_: vec4<f32>;
    var phi_30289_: i32;
    var phi_30288_: i32;
    var phi_29866_: f32;
    var phi_29865_: i32;
    var phi_30290_: f32;
    var phi_30493_: i32;
    var phi_30492_: i32;
    var phi_30391_: f32;
    var phi_29867_: f32;
    var phi_29868_: f32;
    var phi_29875_: f32;
    var phi_29877_: vec4<f32>;
    var phi_29878_: i32;
    var phi_30286_: vec4<f32>;
    var phi_10420_: bool;
    var phi_10430_: bool;
    var phi_10432_: bool;
    var phi_29879_: i32;
    var phi_30284_: vec4<f32>;
    var phi_30277_: i32;
    var phi_30276_: i32;
    var phi_29881_: f32;
    var phi_29880_: i32;
    var phi_30278_: f32;
    var phi_30491_: i32;
    var phi_30490_: i32;
    var phi_30394_: f32;
    var phi_29882_: f32;
    var phi_29883_: f32;
    var phi_29890_: f32;
    var phi_29892_: vec4<f32>;
    var phi_29893_: i32;
    var phi_30274_: vec4<f32>;
    var phi_11576_: bool;
    var phi_11586_: bool;
    var phi_11588_: bool;
    var phi_29894_: i32;
    var phi_30272_: vec4<f32>;
    var phi_30265_: i32;
    var phi_30264_: i32;
    var phi_29896_: f32;
    var phi_29895_: i32;
    var phi_30266_: f32;
    var phi_30489_: i32;
    var phi_30488_: i32;
    var phi_30397_: f32;
    var phi_29897_: f32;
    var phi_29898_: f32;
    var phi_29905_: f32;
    var phi_29951_: vec4<f32>;
    var phi_29952_: i32;
    var phi_30262_: vec4<f32>;
    var phi_12873_: bool;
    var phi_12883_: bool;
    var phi_12885_: bool;
    var phi_29953_: i32;
    var phi_30260_: vec4<f32>;
    var phi_30253_: i32;
    var phi_30252_: i32;
    var phi_29955_: f32;
    var phi_29954_: i32;
    var phi_30254_: f32;
    var phi_30487_: i32;
    var phi_30486_: i32;
    var phi_30416_: f32;
    var phi_29956_: f32;
    var phi_29957_: f32;
    var phi_29964_: f32;
    var phi_29966_: vec4<f32>;
    var phi_29967_: i32;
    var phi_30250_: vec4<f32>;
    var phi_14029_: bool;
    var phi_14039_: bool;
    var phi_14041_: bool;
    var phi_29968_: i32;
    var phi_30248_: vec4<f32>;
    var phi_30241_: i32;
    var phi_30240_: i32;
    var phi_29970_: f32;
    var phi_29969_: i32;
    var phi_30242_: f32;
    var phi_30485_: i32;
    var phi_30484_: i32;
    var phi_30419_: f32;
    var phi_29971_: f32;
    var phi_29972_: f32;
    var phi_29979_: f32;
    var phi_29981_: vec4<f32>;
    var phi_29982_: i32;
    var phi_30238_: vec4<f32>;
    var phi_15185_: bool;
    var phi_15195_: bool;
    var phi_15197_: bool;
    var phi_29983_: i32;
    var phi_30236_: vec4<f32>;
    var phi_30229_: i32;
    var phi_30228_: i32;
    var phi_29985_: f32;
    var phi_29984_: i32;
    var phi_30230_: f32;
    var phi_30483_: i32;
    var phi_30482_: i32;
    var phi_30422_: f32;
    var phi_29986_: f32;
    var phi_29987_: f32;
    var phi_29994_: f32;
    var phi_29996_: vec4<f32>;
    var phi_29997_: i32;
    var phi_30226_: vec4<f32>;
    var phi_16341_: bool;
    var phi_16351_: bool;
    var phi_16353_: bool;
    var phi_29998_: i32;
    var phi_30224_: vec4<f32>;
    var phi_30217_: i32;
    var phi_30216_: i32;
    var phi_30000_: f32;
    var phi_29999_: i32;
    var phi_30218_: f32;
    var phi_30481_: i32;
    var phi_30480_: i32;
    var phi_30425_: f32;
    var phi_30001_: f32;
    var phi_30002_: f32;
    var phi_30009_: f32;
    var phi_30055_: vec4<f32>;
    var phi_30056_: i32;
    var phi_30214_: vec4<f32>;
    var phi_17638_: bool;
    var phi_17648_: bool;
    var phi_17650_: bool;
    var phi_30057_: i32;
    var phi_30212_: vec4<f32>;
    var phi_30205_: i32;
    var phi_30204_: i32;
    var phi_30059_: f32;
    var phi_30058_: i32;
    var phi_30206_: f32;
    var phi_30479_: i32;
    var phi_30478_: i32;
    var phi_30444_: f32;
    var phi_30060_: f32;
    var phi_30061_: f32;
    var phi_30068_: f32;
    var phi_30070_: vec4<f32>;
    var phi_30071_: i32;
    var phi_30202_: vec4<f32>;
    var phi_18794_: bool;
    var phi_18804_: bool;
    var phi_18806_: bool;
    var phi_30072_: i32;
    var phi_30200_: vec4<f32>;
    var phi_30193_: i32;
    var phi_30192_: i32;
    var phi_30074_: f32;
    var phi_30073_: i32;
    var phi_30194_: f32;
    var phi_30477_: i32;
    var phi_30476_: i32;
    var phi_30447_: f32;
    var phi_30075_: f32;
    var phi_30076_: f32;
    var phi_30083_: f32;
    var phi_30085_: vec4<f32>;
    var phi_30086_: i32;
    var phi_30190_: vec4<f32>;
    var phi_19950_: bool;
    var phi_19960_: bool;
    var phi_19962_: bool;
    var phi_30087_: i32;
    var phi_30188_: vec4<f32>;
    var phi_30181_: i32;
    var phi_30180_: i32;
    var phi_30089_: f32;
    var phi_30088_: i32;
    var phi_30182_: f32;
    var phi_30475_: i32;
    var phi_30474_: i32;
    var phi_30450_: f32;
    var phi_30090_: f32;
    var phi_30091_: f32;
    var phi_30098_: f32;
    var phi_30100_: vec4<f32>;
    var phi_30101_: i32;
    var phi_30178_: vec4<f32>;
    var phi_21106_: bool;
    var phi_21116_: bool;
    var phi_21118_: bool;
    var phi_30102_: i32;
    var phi_30176_: vec4<f32>;
    var phi_30169_: i32;
    var phi_30168_: i32;
    var phi_30104_: f32;
    var phi_30103_: i32;
    var phi_30170_: f32;
    var phi_30473_: i32;
    var phi_30472_: i32;
    var phi_30453_: f32;
    var phi_30105_: f32;
    var phi_30106_: f32;
    var phi_30113_: f32;
    var phi_30159_: u32;
    var local_97: u32;
    var local_98: u32;
    var local_99: u32;
    var local_100: u32;
    var local_101: u32;
    var local_102: u32;
    var local_103: u32;
    var local_104: u32;
    var local_105: u32;
    var local_106: u32;
    var local_107: u32;
    var local_108: u32;
    var local_109: u32;
    var local_110: u32;
    var local_111: u32;
    var local_112: u32;
    var local_113: u32;
    var local_114: u32;
    var local_115: vec2<i32>;
    var local_116: u32;
    var local_117: u32;
    var local_118: u32;
    var local_119: u32;
    var local_120: u32;
    var local_121: u32;
    var local_122: u32;
    var local_123: u32;
    var local_124: u32;
    var local_125: u32;
    var local_126: u32;
    var local_127: u32;
    var local_128: u32;
    var local_129: u32;
    var local_130: u32;
    var local_131: u32;
    var local_132: u32;
    var local_133: u32;
    var local_134: u32;
    var local_135: u32;
    var local_136: u32;
    var local_137: u32;
    var local_138: u32;
    var local_139: u32;
    var local_140: u32;
    var local_141: u32;
    var local_142: u32;
    var local_143: u32;
    var local_144: u32;
    var local_145: u32;
    var local_146: u32;
    var local_147: u32;
    var local_148: u32;
    var local_149: u32;
    var local_150: u32;
    var local_151: u32;
    var local_152: u32;
    var local_153: u32;
    var local_154: u32;
    var local_155: u32;
    var local_156: u32;
    var local_157: u32;
    var local_158: u32;
    var local_159: u32;
    var local_160: u32;
    var local_161: u32;
    var local_162: u32;
    var local_163: u32;
    var local_164: u32;
    var local_165: u32;
    var local_166: u32;
    var local_167: u32;
    var local_168: u32;
    var local_169: u32;
    var local_170: i32;
    var local_171: i32;
    var local_172: f32;
    var local_173: f32;
    var local_174: i32;
    var local_175: i32;
    var local_176: f32;
    var local_177: f32;
    var local_178: i32;
    var local_179: i32;
    var local_180: f32;
    var local_181: f32;
    var local_182: i32;
    var local_183: i32;
    var local_184: f32;
    var local_185: f32;
    var local_186: i32;
    var local_187: i32;
    var local_188: f32;
    var local_189: f32;
    var local_190: i32;
    var local_191: i32;
    var local_192: f32;
    var local_193: f32;
    var local_194: i32;
    var local_195: i32;
    var local_196: f32;
    var local_197: f32;
    var local_198: i32;
    var local_199: i32;
    var local_200: f32;
    var local_201: f32;
    var local_202: i32;
    var local_203: i32;
    var local_204: f32;
    var local_205: f32;
    var local_206: i32;
    var local_207: i32;
    var local_208: f32;
    var local_209: f32;
    var local_210: i32;
    var local_211: i32;
    var local_212: f32;
    var local_213: f32;
    var local_214: i32;
    var local_215: i32;
    var local_216: f32;
    var local_217: f32;
    var local_218: i32;
    var local_219: i32;
    var local_220: f32;
    var local_221: f32;
    var local_222: i32;
    var local_223: i32;
    var local_224: f32;
    var local_225: f32;
    var local_226: i32;
    var local_227: i32;
    var local_228: f32;
    var local_229: f32;
    var local_230: i32;
    var local_231: i32;
    var local_232: f32;
    var local_233: f32;

    let _e165 = global_12;
    let _e166 = global_13;
    let _e167 = _e165.xy;
    let _e170 = global.member_19[0u];
    let _e173 = global.member_19[1u];
    switch bitcast<i32>(0u) {
        default: {
            let _e175 = (_e166 % 64u);
            let _e195 = (insertBits(extractBits(_e175, bitcast<u32>(2i), bitcast<u32>(3i)), _e175, bitcast<u32>(0i), bitcast<u32>(1i)) + (8u * ((_e166 >> bitcast<u32>(6i)) % 2u)));
            let _e199 = (insertBits(extractBits(_e175, bitcast<u32>(3i), bitcast<u32>(3i)), extractBits(_e175, bitcast<u32>(1i), bitcast<u32>(2i)), bitcast<u32>(0i), bitcast<u32>(2i)) + (8u * (_e166 >> bitcast<u32>(7i))));
            switch bitcast<i32>(0u) {
                default: {
                    let _e202 = bitcast<vec2<i32>>((_e167 * vec2<u32>(64u, 64u)));
                    let _e203 = (_e195 * 2u);
                    let _e204 = bitcast<i32>(_e203);
                    let _e205 = (_e199 * 2u);
                    let _e206 = bitcast<i32>(_e205);
                    let _e208 = (_e202 + vec2<i32>(_e204, _e206));
                    let _e210 = bitcast<vec2<i32>>((_e167 * vec2<u32>(32u, 32u)));
                    let _e211 = bitcast<i32>(_e195);
                    let _e212 = bitcast<i32>(_e199);
                    let _e213 = vec2<i32>(_e211, _e212);
                    let _e214 = (_e210 + _e213);
                    let _e215 = bitcast<vec2<u32>>(_e208);
                    let _e220 = vec2<i32>(vec2<f32>(_e208));
                    let _e222 = global.member;
                    let _e224 = (_e222.x - 1i);
                    let _e229 = (_e222.y - 1i);
                    let _e233 = vec2<i32>(max(0i, min(_e220.x, _e224)), max(0i, min(_e220.y, _e229)));
                    let _e235 = textureDimensions(global_3, 0i);
                    local_97 = _e203;
                    local_98 = _e205;
                    local_99 = _e203;
                    local_100 = _e205;
                    local_101 = _e203;
                    local_102 = _e205;
                    local_103 = _e203;
                    local_104 = _e205;
                    local_105 = _e203;
                    local_106 = _e205;
                    local_107 = _e205;
                    local_108 = _e205;
                    local_109 = _e205;
                    local_110 = _e205;
                    local_111 = _e203;
                    local_112 = _e203;
                    local_113 = _e203;
                    local_114 = _e203;
                    local_115 = _e213;
                    local_116 = _e203;
                    local_117 = _e205;
                    local_118 = _e205;
                    local_119 = _e205;
                    local_120 = _e205;
                    local_121 = _e205;
                    local_122 = _e205;
                    local_123 = _e205;
                    local_124 = _e205;
                    local_125 = _e205;
                    local_126 = _e203;
                    local_127 = _e205;
                    local_128 = _e203;
                    local_129 = _e205;
                    local_130 = _e203;
                    local_131 = _e205;
                    local_132 = _e203;
                    local_133 = _e205;
                    local_134 = _e203;
                    local_135 = _e205;
                    local_137 = _e205;
                    local_139 = _e205;
                    local_141 = _e205;
                    local_143 = _e205;
                    local_144 = _e203;
                    local_146 = _e203;
                    local_148 = _e203;
                    local_150 = _e203;
                    local_160 = _e203;
                    local_161 = _e205;
                    local_162 = _e205;
                    local_163 = _e205;
                    local_164 = _e205;
                    local_165 = _e205;
                    local_166 = _e205;
                    local_167 = _e205;
                    local_168 = _e205;
                    local_169 = _e205;
                    if all((bitcast<vec2<u32>>(_e233) < bitcast<vec2<u32>>(vec2<i32>(_e235)))) {
                        let _e240 = textureLoad(global_3, _e233, 0i);
                        phi_29743_ = _e240;
                    } else {
                        phi_29743_ = vec4<f32>(0f, 0f, 0f, 0f);
                    }
                    let _e242 = phi_29743_;
                    let _e246 = vec2<f32>(_e222);
                    let _e247 = ((vec2<f32>(_e233) + vec2<f32>(0.5f, 0.5f)) / _e246);
                    let _e249 = global.member_5;
                    let _e250 = (_e249 / _e246);
                    phi_29744_ = 0i;
                    loop {
                        let _e256 = phi_29744_;
                        if (_e256 < 5i) {
                            local_95 = array<vec2<i32>, 5>(vec2<i32>(0i, 0i), vec2<i32>(-1i, 0i), vec2<i32>(1i, 0i), vec2<i32>(0i, -1i), vec2<i32>(0i, 1i));
                            let _e259 = local_95[_e256];
                            let _e260 = (vec2<i32>(floor(((_e247 + _e250) * _e246))) + _e259);
                            let _e267 = vec2<i32>(max(0i, min(_e260.x, _e224)), max(0i, min(_e260.y, _e229)));
                            let _e269 = textureDimensions(global_1, 0i);
                            if all((bitcast<vec2<u32>>(_e267) < bitcast<vec2<u32>>(vec2<i32>(_e269)))) {
                                let _e274 = textureLoad(global_1, _e267, 0i);
                                phi_30358_ = _e274;
                            } else {
                                phi_30358_ = vec4<f32>(0f, 0f, 0f, 0f);
                            }
                            let _e276 = phi_30358_;
                            let _e279 = global.member_18;
                            local_18[_e256] = (_e276.x * select(_e279, 1f, (_e279 == 0f)));
                            let _e284 = local_18[_e256];
                            local_18[_e256] = pow(_e284, 1f);
                            let _e286 = local_18[_e256];
                            local_18[_e256] = max(_e286, 0.000061f);
                            continue;
                        } else {
                            break;
                        }
                        continuing {
                            phi_29744_ = (_e256 + 1i);
                        }
                    }
                    let _e289 = local_18;
                    let _e291 = global.member_6;
                    let _e293 = global.member_1;
                    let _e294 = vec2<f32>(_e293);
                    let _e295 = (_e291 / _e294);
                    let _e297 = ((_e247 + _e295) + _e242.xy);
                    let _e299 = (_e297.x >= 0f);
                    phi_3343_ = _e299;
                    if _e299 {
                        phi_3343_ = (_e297.x <= 1f);
                    }
                    let _e302 = phi_3343_;
                    phi_3355_ = _e302;
                    if _e302 {
                        let _e304 = (_e297.y >= 0f);
                        phi_3353_ = _e304;
                        if _e304 {
                            phi_3353_ = (_e297.y <= 1f);
                        }
                        let _e307 = phi_3353_;
                        phi_3355_ = _e307;
                    }
                    let _e309 = phi_3355_;
                    if _e309 {
                        phi_29745_ = 0i;
                        loop {
                            let _e314 = phi_29745_;
                            if (_e314 < 5i) {
                                local_94 = array<vec2<i32>, 5>(vec2<i32>(0i, 0i), vec2<i32>(-1i, 0i), vec2<i32>(1i, 0i), vec2<i32>(0i, -1i), vec2<i32>(0i, 1i));
                                let _e317 = local_94[_e314];
                                let _e318 = (vec2<i32>(floor((_e297 * _e294))) + _e317);
                                let _e329 = vec2<i32>(max(0i, min(_e318.x, (_e293.x - 1i))), max(0i, min(_e318.y, (_e293.y - 1i))));
                                let _e331 = textureDimensions(global_2, 0i);
                                if all((bitcast<vec2<u32>>(_e329) < bitcast<vec2<u32>>(vec2<i32>(_e331)))) {
                                    let _e336 = textureLoad(global_2, _e329, 0i);
                                    phi_30356_ = _e336;
                                } else {
                                    phi_30356_ = vec4<f32>(0f, 0f, 0f, 0f);
                                }
                                let _e338 = phi_30356_;
                                let _e341 = global.member_10;
                                let _e344 = global.member_18;
                                local[_e314] = ((_e338.x * _e341) * select(_e344, 1f, (_e344 == 0f)));
                                let _e349 = local[_e314];
                                local[_e314] = pow(_e349, 1f);
                                let _e351 = local[_e314];
                                local[_e314] = max(_e351, 0.000061f);
                                continue;
                            } else {
                                break;
                            }
                            continuing {
                                phi_29745_ = (_e314 + 1i);
                            }
                        }
                    }
                    let _e354 = local;
                    phi_29749_ = 0f;
                    if _e309 {
                        let _e360 = min(_e289[0], _e289[3]);
                        let _e361 = max(_e289[0], _e289[3]);
                        let _e362 = min(_e289[1], _e289[4]);
                        let _e363 = max(_e289[1], _e289[4]);
                        let _e364 = min(_e360, _e289[2]);
                        let _e365 = max(_e360, _e289[2]);
                        let _e366 = min(_e362, _e361);
                        let _e367 = max(_e362, _e361);
                        let _e369 = max(_e364, _e366);
                        let _e370 = min(_e365, _e363);
                        let _e371 = max(_e365, _e363);
                        let _e373 = max(_e369, _e370);
                        let _e374 = min(_e367, _e371);
                        local_17 = array<f32, 5>(min(_e364, _e366), min(_e369, _e370), min(_e373, _e374), max(_e373, _e374), max(_e367, _e371));
                        let _e384 = min(_e354[0], _e354[3]);
                        let _e385 = max(_e354[0], _e354[3]);
                        let _e386 = min(_e354[1], _e354[4]);
                        let _e387 = max(_e354[1], _e354[4]);
                        let _e388 = min(_e384, _e354[2]);
                        let _e389 = max(_e384, _e354[2]);
                        let _e390 = min(_e386, _e385);
                        let _e391 = max(_e386, _e385);
                        let _e393 = max(_e388, _e390);
                        let _e394 = min(_e389, _e387);
                        let _e395 = max(_e389, _e387);
                        let _e397 = max(_e393, _e394);
                        let _e398 = min(_e391, _e395);
                        local_16 = array<f32, 5>(min(_e388, _e390), min(_e393, _e394), min(_e397, _e398), max(_e397, _e398), max(_e391, _e395));
                        let _e404 = local_17[4i];
                        let _e406 = local_16[4i];
                        phi_29748_ = 65503f;
                        if (min(_e404, _e406) > 0.000000000000000000000000000000000000011754944f) {
                            phi_30349_ = 0i;
                            phi_30348_ = 0i;
                            phi_29747_ = 65503f;
                            phi_29746_ = 0i;
                            loop {
                                let _e410 = phi_30349_;
                                let _e412 = phi_30348_;
                                let _e414 = phi_29747_;
                                let _e416 = phi_29746_;
                                local_173 = _e414;
                                if ((_e416 < 5i) && (_e414 < 65504f)) {
                                    let _e421 = local_17[_e412];
                                    let _e423 = local_16[_e410];
                                    let _e424 = (_e421 - _e423);
                                    if (abs(_e424) > 0.000061f) {
                                        let _e428 = local_17[_e412];
                                        let _e429 = local_16[_e410];
                                        let _e430 = max(_e428, _e429);
                                        if (_e430 != 0f) {
                                            phi_30350_ = (min(_e428, _e429) / _e430);
                                        } else {
                                            phi_30350_ = 0f;
                                        }
                                        let _e435 = phi_30350_;
                                        let _e437 = (sign(_e424) * (1f - _e435));
                                        let _e442 = local_17[_e412];
                                        let _e443 = local_16[_e410];
                                        let _e446 = (_e412 + select(0i, 1i, (_e442 < _e443)));
                                        let _e448 = local_17[_e446];
                                        let _e449 = local_16[_e410];
                                        phi_30503_ = (_e410 + select(0i, 1i, (_e448 >= _e449)));
                                        phi_30502_ = _e446;
                                        phi_30360_ = select(_e414, _e437, (abs(_e437) < abs(_e414)));
                                    } else {
                                        phi_30503_ = _e410;
                                        phi_30502_ = _e412;
                                        phi_30360_ = 65504f;
                                    }
                                    let _e454 = phi_30503_;
                                    let _e456 = phi_30502_;
                                    let _e458 = phi_30360_;
                                    local_170 = _e454;
                                    local_171 = _e456;
                                    local_172 = _e458;
                                    continue;
                                } else {
                                    break;
                                }
                                continuing {
                                    let _e5162 = local_170;
                                    phi_30349_ = _e5162;
                                    let _e5165 = local_171;
                                    phi_30348_ = _e5165;
                                    let _e5168 = local_172;
                                    phi_29747_ = _e5168;
                                    phi_29746_ = (_e416 + 1i);
                                }
                            }
                            let _e5176 = local_173;
                            phi_29748_ = _e5176;
                        }
                        let _e461 = phi_29748_;
                        phi_29749_ = (_e461 * select(0f, 1f, (_e461 < 65503f)));
                    }
                    let _e466 = phi_29749_;
                    let _e471 = vec4<f32>(_e466, vec4<f32>(0f, 0f, 0f, 0f).y, vec4<f32>(0f, 0f, 0f, 0f).z, vec4<f32>(0f, 0f, 0f, 0f).w);
                    if (_e466 != 0f) {
                        phi_29756_ = sign(_e466);
                    } else {
                        phi_29756_ = 0f;
                    }
                    let _e475 = phi_29756_;
                    let _e480 = vec4<f32>(_e471.x, _e475, _e471.z, _e471.w);
                    let _e488 = vec2<i32>(vec2<f32>(bitcast<vec2<i32>>((_e215 + vec2<u32>(0u, 1u)))));
                    let _e495 = vec2<i32>(max(0i, min(_e488.x, _e224)), max(0i, min(_e488.y, _e229)));
                    let _e497 = textureDimensions(global_3, 0i);
                    if all((bitcast<vec2<u32>>(_e495) < bitcast<vec2<u32>>(vec2<i32>(_e497)))) {
                        let _e502 = textureLoad(global_3, _e495, 0i);
                        phi_29758_ = _e502;
                    } else {
                        phi_29758_ = vec4<f32>(0f, 0f, 0f, 0f);
                    }
                    let _e504 = phi_29758_;
                    let _e508 = ((vec2<f32>(_e495) + vec2<f32>(0.5f, 0.5f)) / _e246);
                    phi_29759_ = 0i;
                    loop {
                        let _e514 = phi_29759_;
                        if (_e514 < 5i) {
                            local_93 = array<vec2<i32>, 5>(vec2<i32>(0i, 0i), vec2<i32>(-1i, 0i), vec2<i32>(1i, 0i), vec2<i32>(0i, -1i), vec2<i32>(0i, 1i));
                            let _e517 = local_93[_e514];
                            let _e518 = (vec2<i32>(floor(((_e508 + _e250) * _e246))) + _e517);
                            let _e525 = vec2<i32>(max(0i, min(_e518.x, _e224)), max(0i, min(_e518.y, _e229)));
                            let _e527 = textureDimensions(global_1, 0i);
                            if all((bitcast<vec2<u32>>(_e525) < bitcast<vec2<u32>>(vec2<i32>(_e527)))) {
                                let _e532 = textureLoad(global_1, _e525, 0i);
                                phi_30346_ = _e532;
                            } else {
                                phi_30346_ = vec4<f32>(0f, 0f, 0f, 0f);
                            }
                            let _e534 = phi_30346_;
                            let _e537 = global.member_18;
                            local_21[_e514] = (_e534.x * select(_e537, 1f, (_e537 == 0f)));
                            let _e542 = local_21[_e514];
                            local_21[_e514] = pow(_e542, 1f);
                            let _e544 = local_21[_e514];
                            local_21[_e514] = max(_e544, 0.000061f);
                            continue;
                        } else {
                            break;
                        }
                        continuing {
                            phi_29759_ = (_e514 + 1i);
                        }
                    }
                    let _e547 = local_21;
                    let _e549 = ((_e508 + _e295) + _e504.xy);
                    let _e551 = (_e549.x >= 0f);
                    phi_4499_ = _e551;
                    if _e551 {
                        phi_4499_ = (_e549.x <= 1f);
                    }
                    let _e554 = phi_4499_;
                    phi_4511_ = _e554;
                    if _e554 {
                        let _e556 = (_e549.y >= 0f);
                        phi_4509_ = _e556;
                        if _e556 {
                            phi_4509_ = (_e549.y <= 1f);
                        }
                        let _e559 = phi_4509_;
                        phi_4511_ = _e559;
                    }
                    let _e561 = phi_4511_;
                    if _e561 {
                        phi_29760_ = 0i;
                        loop {
                            let _e566 = phi_29760_;
                            if (_e566 < 5i) {
                                local_92 = array<vec2<i32>, 5>(vec2<i32>(0i, 0i), vec2<i32>(-1i, 0i), vec2<i32>(1i, 0i), vec2<i32>(0i, -1i), vec2<i32>(0i, 1i));
                                let _e569 = local_92[_e566];
                                let _e570 = (vec2<i32>(floor((_e549 * _e294))) + _e569);
                                let _e581 = vec2<i32>(max(0i, min(_e570.x, (_e293.x - 1i))), max(0i, min(_e570.y, (_e293.y - 1i))));
                                let _e583 = textureDimensions(global_2, 0i);
                                if all((bitcast<vec2<u32>>(_e581) < bitcast<vec2<u32>>(vec2<i32>(_e583)))) {
                                    let _e588 = textureLoad(global_2, _e581, 0i);
                                    phi_30344_ = _e588;
                                } else {
                                    phi_30344_ = vec4<f32>(0f, 0f, 0f, 0f);
                                }
                                let _e590 = phi_30344_;
                                let _e593 = global.member_10;
                                let _e596 = global.member_18;
                                local_1[_e566] = ((_e590.x * _e593) * select(_e596, 1f, (_e596 == 0f)));
                                let _e601 = local_1[_e566];
                                local_1[_e566] = pow(_e601, 1f);
                                let _e603 = local_1[_e566];
                                local_1[_e566] = max(_e603, 0.000061f);
                                continue;
                            } else {
                                break;
                            }
                            continuing {
                                phi_29760_ = (_e566 + 1i);
                            }
                        }
                    }
                    let _e606 = local_1;
                    phi_29764_ = 0f;
                    if _e561 {
                        let _e612 = min(_e547[0], _e547[3]);
                        let _e613 = max(_e547[0], _e547[3]);
                        let _e614 = min(_e547[1], _e547[4]);
                        let _e615 = max(_e547[1], _e547[4]);
                        let _e616 = min(_e612, _e547[2]);
                        let _e617 = max(_e612, _e547[2]);
                        let _e618 = min(_e614, _e613);
                        let _e619 = max(_e614, _e613);
                        let _e621 = max(_e616, _e618);
                        let _e622 = min(_e617, _e615);
                        let _e623 = max(_e617, _e615);
                        let _e625 = max(_e621, _e622);
                        let _e626 = min(_e619, _e623);
                        local_20 = array<f32, 5>(min(_e616, _e618), min(_e621, _e622), min(_e625, _e626), max(_e625, _e626), max(_e619, _e623));
                        let _e636 = min(_e606[0], _e606[3]);
                        let _e637 = max(_e606[0], _e606[3]);
                        let _e638 = min(_e606[1], _e606[4]);
                        let _e639 = max(_e606[1], _e606[4]);
                        let _e640 = min(_e636, _e606[2]);
                        let _e641 = max(_e636, _e606[2]);
                        let _e642 = min(_e638, _e637);
                        let _e643 = max(_e638, _e637);
                        let _e645 = max(_e640, _e642);
                        let _e646 = min(_e641, _e639);
                        let _e647 = max(_e641, _e639);
                        let _e649 = max(_e645, _e646);
                        let _e650 = min(_e643, _e647);
                        local_19 = array<f32, 5>(min(_e640, _e642), min(_e645, _e646), min(_e649, _e650), max(_e649, _e650), max(_e643, _e647));
                        let _e656 = local_20[4i];
                        let _e658 = local_19[4i];
                        phi_29763_ = 65503f;
                        if (min(_e656, _e658) > 0.000000000000000000000000000000000000011754944f) {
                            phi_30337_ = 0i;
                            phi_30336_ = 0i;
                            phi_29762_ = 65503f;
                            phi_29761_ = 0i;
                            loop {
                                let _e662 = phi_30337_;
                                let _e664 = phi_30336_;
                                let _e666 = phi_29762_;
                                let _e668 = phi_29761_;
                                local_177 = _e666;
                                if ((_e668 < 5i) && (_e666 < 65504f)) {
                                    let _e673 = local_20[_e664];
                                    let _e675 = local_19[_e662];
                                    let _e676 = (_e673 - _e675);
                                    if (abs(_e676) > 0.000061f) {
                                        let _e680 = local_20[_e664];
                                        let _e681 = local_19[_e662];
                                        let _e682 = max(_e680, _e681);
                                        if (_e682 != 0f) {
                                            phi_30338_ = (min(_e680, _e681) / _e682);
                                        } else {
                                            phi_30338_ = 0f;
                                        }
                                        let _e687 = phi_30338_;
                                        let _e689 = (sign(_e676) * (1f - _e687));
                                        let _e694 = local_20[_e664];
                                        let _e695 = local_19[_e662];
                                        let _e698 = (_e664 + select(0i, 1i, (_e694 < _e695)));
                                        let _e700 = local_20[_e698];
                                        let _e701 = local_19[_e662];
                                        phi_30501_ = (_e662 + select(0i, 1i, (_e700 >= _e701)));
                                        phi_30500_ = _e698;
                                        phi_30363_ = select(_e666, _e689, (abs(_e689) < abs(_e666)));
                                    } else {
                                        phi_30501_ = _e662;
                                        phi_30500_ = _e664;
                                        phi_30363_ = 65504f;
                                    }
                                    let _e706 = phi_30501_;
                                    let _e708 = phi_30500_;
                                    let _e710 = phi_30363_;
                                    local_174 = _e706;
                                    local_175 = _e708;
                                    local_176 = _e710;
                                    continue;
                                } else {
                                    break;
                                }
                                continuing {
                                    let _e5189 = local_174;
                                    phi_30337_ = _e5189;
                                    let _e5192 = local_175;
                                    phi_30336_ = _e5192;
                                    let _e5195 = local_176;
                                    phi_29762_ = _e5195;
                                    phi_29761_ = (_e668 + 1i);
                                }
                            }
                            let _e5203 = local_177;
                            phi_29763_ = _e5203;
                        }
                        let _e713 = phi_29763_;
                        phi_29764_ = (_e713 * select(0f, 1f, (_e713 < 65503f)));
                    }
                    let _e718 = phi_29764_;
                    let _e723 = vec4<f32>(_e718, vec4<f32>(0f, 0f, 0f, 0f).y, vec4<f32>(0f, 0f, 0f, 0f).z, vec4<f32>(0f, 0f, 0f, 0f).w);
                    if (_e718 != 0f) {
                        phi_29771_ = sign(_e718);
                    } else {
                        phi_29771_ = 0f;
                    }
                    let _e727 = phi_29771_;
                    let _e732 = vec4<f32>(_e723.x, _e727, _e723.z, _e723.w);
                    let _e740 = vec2<i32>(vec2<f32>(bitcast<vec2<i32>>((_e215 + vec2<u32>(1u, 0u)))));
                    let _e747 = vec2<i32>(max(0i, min(_e740.x, _e224)), max(0i, min(_e740.y, _e229)));
                    let _e749 = textureDimensions(global_3, 0i);
                    if all((bitcast<vec2<u32>>(_e747) < bitcast<vec2<u32>>(vec2<i32>(_e749)))) {
                        let _e754 = textureLoad(global_3, _e747, 0i);
                        phi_29773_ = _e754;
                    } else {
                        phi_29773_ = vec4<f32>(0f, 0f, 0f, 0f);
                    }
                    let _e756 = phi_29773_;
                    let _e760 = ((vec2<f32>(_e747) + vec2<f32>(0.5f, 0.5f)) / _e246);
                    phi_29774_ = 0i;
                    loop {
                        let _e766 = phi_29774_;
                        if (_e766 < 5i) {
                            local_91 = array<vec2<i32>, 5>(vec2<i32>(0i, 0i), vec2<i32>(-1i, 0i), vec2<i32>(1i, 0i), vec2<i32>(0i, -1i), vec2<i32>(0i, 1i));
                            let _e769 = local_91[_e766];
                            let _e770 = (vec2<i32>(floor(((_e760 + _e250) * _e246))) + _e769);
                            let _e777 = vec2<i32>(max(0i, min(_e770.x, _e224)), max(0i, min(_e770.y, _e229)));
                            let _e779 = textureDimensions(global_1, 0i);
                            if all((bitcast<vec2<u32>>(_e777) < bitcast<vec2<u32>>(vec2<i32>(_e779)))) {
                                let _e784 = textureLoad(global_1, _e777, 0i);
                                phi_30334_ = _e784;
                            } else {
                                phi_30334_ = vec4<f32>(0f, 0f, 0f, 0f);
                            }
                            let _e786 = phi_30334_;
                            let _e789 = global.member_18;
                            local_24[_e766] = (_e786.x * select(_e789, 1f, (_e789 == 0f)));
                            let _e794 = local_24[_e766];
                            local_24[_e766] = pow(_e794, 1f);
                            let _e796 = local_24[_e766];
                            local_24[_e766] = max(_e796, 0.000061f);
                            continue;
                        } else {
                            break;
                        }
                        continuing {
                            phi_29774_ = (_e766 + 1i);
                        }
                    }
                    let _e799 = local_24;
                    let _e801 = ((_e760 + _e295) + _e756.xy);
                    let _e803 = (_e801.x >= 0f);
                    phi_5655_ = _e803;
                    if _e803 {
                        phi_5655_ = (_e801.x <= 1f);
                    }
                    let _e806 = phi_5655_;
                    phi_5667_ = _e806;
                    if _e806 {
                        let _e808 = (_e801.y >= 0f);
                        phi_5665_ = _e808;
                        if _e808 {
                            phi_5665_ = (_e801.y <= 1f);
                        }
                        let _e811 = phi_5665_;
                        phi_5667_ = _e811;
                    }
                    let _e813 = phi_5667_;
                    if _e813 {
                        phi_29775_ = 0i;
                        loop {
                            let _e818 = phi_29775_;
                            if (_e818 < 5i) {
                                local_90 = array<vec2<i32>, 5>(vec2<i32>(0i, 0i), vec2<i32>(-1i, 0i), vec2<i32>(1i, 0i), vec2<i32>(0i, -1i), vec2<i32>(0i, 1i));
                                let _e821 = local_90[_e818];
                                let _e822 = (vec2<i32>(floor((_e801 * _e294))) + _e821);
                                let _e833 = vec2<i32>(max(0i, min(_e822.x, (_e293.x - 1i))), max(0i, min(_e822.y, (_e293.y - 1i))));
                                let _e835 = textureDimensions(global_2, 0i);
                                if all((bitcast<vec2<u32>>(_e833) < bitcast<vec2<u32>>(vec2<i32>(_e835)))) {
                                    let _e840 = textureLoad(global_2, _e833, 0i);
                                    phi_30332_ = _e840;
                                } else {
                                    phi_30332_ = vec4<f32>(0f, 0f, 0f, 0f);
                                }
                                let _e842 = phi_30332_;
                                let _e845 = global.member_10;
                                let _e848 = global.member_18;
                                local_2[_e818] = ((_e842.x * _e845) * select(_e848, 1f, (_e848 == 0f)));
                                let _e853 = local_2[_e818];
                                local_2[_e818] = pow(_e853, 1f);
                                let _e855 = local_2[_e818];
                                local_2[_e818] = max(_e855, 0.000061f);
                                continue;
                            } else {
                                break;
                            }
                            continuing {
                                phi_29775_ = (_e818 + 1i);
                            }
                        }
                    }
                    let _e858 = local_2;
                    phi_29779_ = 0f;
                    if _e813 {
                        let _e864 = min(_e799[0], _e799[3]);
                        let _e865 = max(_e799[0], _e799[3]);
                        let _e866 = min(_e799[1], _e799[4]);
                        let _e867 = max(_e799[1], _e799[4]);
                        let _e868 = min(_e864, _e799[2]);
                        let _e869 = max(_e864, _e799[2]);
                        let _e870 = min(_e866, _e865);
                        let _e871 = max(_e866, _e865);
                        let _e873 = max(_e868, _e870);
                        let _e874 = min(_e869, _e867);
                        let _e875 = max(_e869, _e867);
                        let _e877 = max(_e873, _e874);
                        let _e878 = min(_e871, _e875);
                        local_23 = array<f32, 5>(min(_e868, _e870), min(_e873, _e874), min(_e877, _e878), max(_e877, _e878), max(_e871, _e875));
                        let _e888 = min(_e858[0], _e858[3]);
                        let _e889 = max(_e858[0], _e858[3]);
                        let _e890 = min(_e858[1], _e858[4]);
                        let _e891 = max(_e858[1], _e858[4]);
                        let _e892 = min(_e888, _e858[2]);
                        let _e893 = max(_e888, _e858[2]);
                        let _e894 = min(_e890, _e889);
                        let _e895 = max(_e890, _e889);
                        let _e897 = max(_e892, _e894);
                        let _e898 = min(_e893, _e891);
                        let _e899 = max(_e893, _e891);
                        let _e901 = max(_e897, _e898);
                        let _e902 = min(_e895, _e899);
                        local_22 = array<f32, 5>(min(_e892, _e894), min(_e897, _e898), min(_e901, _e902), max(_e901, _e902), max(_e895, _e899));
                        let _e908 = local_23[4i];
                        let _e910 = local_22[4i];
                        phi_29778_ = 65503f;
                        if (min(_e908, _e910) > 0.000000000000000000000000000000000000011754944f) {
                            phi_30325_ = 0i;
                            phi_30324_ = 0i;
                            phi_29777_ = 65503f;
                            phi_29776_ = 0i;
                            loop {
                                let _e914 = phi_30325_;
                                let _e916 = phi_30324_;
                                let _e918 = phi_29777_;
                                let _e920 = phi_29776_;
                                local_181 = _e918;
                                if ((_e920 < 5i) && (_e918 < 65504f)) {
                                    let _e925 = local_23[_e916];
                                    let _e927 = local_22[_e914];
                                    let _e928 = (_e925 - _e927);
                                    if (abs(_e928) > 0.000061f) {
                                        let _e932 = local_23[_e916];
                                        let _e933 = local_22[_e914];
                                        let _e934 = max(_e932, _e933);
                                        if (_e934 != 0f) {
                                            phi_30326_ = (min(_e932, _e933) / _e934);
                                        } else {
                                            phi_30326_ = 0f;
                                        }
                                        let _e939 = phi_30326_;
                                        let _e941 = (sign(_e928) * (1f - _e939));
                                        let _e946 = local_23[_e916];
                                        let _e947 = local_22[_e914];
                                        let _e950 = (_e916 + select(0i, 1i, (_e946 < _e947)));
                                        let _e952 = local_23[_e950];
                                        let _e953 = local_22[_e914];
                                        phi_30499_ = (_e914 + select(0i, 1i, (_e952 >= _e953)));
                                        phi_30498_ = _e950;
                                        phi_30366_ = select(_e918, _e941, (abs(_e941) < abs(_e918)));
                                    } else {
                                        phi_30499_ = _e914;
                                        phi_30498_ = _e916;
                                        phi_30366_ = 65504f;
                                    }
                                    let _e958 = phi_30499_;
                                    let _e960 = phi_30498_;
                                    let _e962 = phi_30366_;
                                    local_178 = _e958;
                                    local_179 = _e960;
                                    local_180 = _e962;
                                    continue;
                                } else {
                                    break;
                                }
                                continuing {
                                    let _e5216 = local_178;
                                    phi_30325_ = _e5216;
                                    let _e5219 = local_179;
                                    phi_30324_ = _e5219;
                                    let _e5222 = local_180;
                                    phi_29777_ = _e5222;
                                    phi_29776_ = (_e920 + 1i);
                                }
                            }
                            let _e5230 = local_181;
                            phi_29778_ = _e5230;
                        }
                        let _e965 = phi_29778_;
                        phi_29779_ = (_e965 * select(0f, 1f, (_e965 < 65503f)));
                    }
                    let _e970 = phi_29779_;
                    let _e975 = vec4<f32>(_e970, vec4<f32>(0f, 0f, 0f, 0f).y, vec4<f32>(0f, 0f, 0f, 0f).z, vec4<f32>(0f, 0f, 0f, 0f).w);
                    if (_e970 != 0f) {
                        phi_29786_ = sign(_e970);
                    } else {
                        phi_29786_ = 0f;
                    }
                    let _e979 = phi_29786_;
                    let _e984 = vec4<f32>(_e975.x, _e979, _e975.z, _e975.w);
                    let _e992 = vec2<i32>(vec2<f32>(bitcast<vec2<i32>>((_e215 + vec2<u32>(1u, 1u)))));
                    let _e999 = vec2<i32>(max(0i, min(_e992.x, _e224)), max(0i, min(_e992.y, _e229)));
                    let _e1001 = textureDimensions(global_3, 0i);
                    if all((bitcast<vec2<u32>>(_e999) < bitcast<vec2<u32>>(vec2<i32>(_e1001)))) {
                        let _e1006 = textureLoad(global_3, _e999, 0i);
                        phi_29788_ = _e1006;
                    } else {
                        phi_29788_ = vec4<f32>(0f, 0f, 0f, 0f);
                    }
                    let _e1008 = phi_29788_;
                    let _e1012 = ((vec2<f32>(_e999) + vec2<f32>(0.5f, 0.5f)) / _e246);
                    phi_29789_ = 0i;
                    loop {
                        let _e1018 = phi_29789_;
                        if (_e1018 < 5i) {
                            local_89 = array<vec2<i32>, 5>(vec2<i32>(0i, 0i), vec2<i32>(-1i, 0i), vec2<i32>(1i, 0i), vec2<i32>(0i, -1i), vec2<i32>(0i, 1i));
                            let _e1021 = local_89[_e1018];
                            let _e1022 = (vec2<i32>(floor(((_e1012 + _e250) * _e246))) + _e1021);
                            let _e1029 = vec2<i32>(max(0i, min(_e1022.x, _e224)), max(0i, min(_e1022.y, _e229)));
                            let _e1031 = textureDimensions(global_1, 0i);
                            if all((bitcast<vec2<u32>>(_e1029) < bitcast<vec2<u32>>(vec2<i32>(_e1031)))) {
                                let _e1036 = textureLoad(global_1, _e1029, 0i);
                                phi_30322_ = _e1036;
                            } else {
                                phi_30322_ = vec4<f32>(0f, 0f, 0f, 0f);
                            }
                            let _e1038 = phi_30322_;
                            let _e1041 = global.member_18;
                            local_27[_e1018] = (_e1038.x * select(_e1041, 1f, (_e1041 == 0f)));
                            let _e1046 = local_27[_e1018];
                            local_27[_e1018] = pow(_e1046, 1f);
                            let _e1048 = local_27[_e1018];
                            local_27[_e1018] = max(_e1048, 0.000061f);
                            continue;
                        } else {
                            break;
                        }
                        continuing {
                            phi_29789_ = (_e1018 + 1i);
                        }
                    }
                    let _e1051 = local_27;
                    let _e1053 = ((_e1012 + _e295) + _e1008.xy);
                    let _e1055 = (_e1053.x >= 0f);
                    phi_6811_ = _e1055;
                    if _e1055 {
                        phi_6811_ = (_e1053.x <= 1f);
                    }
                    let _e1058 = phi_6811_;
                    phi_6823_ = _e1058;
                    if _e1058 {
                        let _e1060 = (_e1053.y >= 0f);
                        phi_6821_ = _e1060;
                        if _e1060 {
                            phi_6821_ = (_e1053.y <= 1f);
                        }
                        let _e1063 = phi_6821_;
                        phi_6823_ = _e1063;
                    }
                    let _e1065 = phi_6823_;
                    if _e1065 {
                        phi_29790_ = 0i;
                        loop {
                            let _e1070 = phi_29790_;
                            if (_e1070 < 5i) {
                                local_88 = array<vec2<i32>, 5>(vec2<i32>(0i, 0i), vec2<i32>(-1i, 0i), vec2<i32>(1i, 0i), vec2<i32>(0i, -1i), vec2<i32>(0i, 1i));
                                let _e1073 = local_88[_e1070];
                                let _e1074 = (vec2<i32>(floor((_e1053 * _e294))) + _e1073);
                                let _e1085 = vec2<i32>(max(0i, min(_e1074.x, (_e293.x - 1i))), max(0i, min(_e1074.y, (_e293.y - 1i))));
                                let _e1087 = textureDimensions(global_2, 0i);
                                if all((bitcast<vec2<u32>>(_e1085) < bitcast<vec2<u32>>(vec2<i32>(_e1087)))) {
                                    let _e1092 = textureLoad(global_2, _e1085, 0i);
                                    phi_30320_ = _e1092;
                                } else {
                                    phi_30320_ = vec4<f32>(0f, 0f, 0f, 0f);
                                }
                                let _e1094 = phi_30320_;
                                let _e1097 = global.member_10;
                                let _e1100 = global.member_18;
                                local_3[_e1070] = ((_e1094.x * _e1097) * select(_e1100, 1f, (_e1100 == 0f)));
                                let _e1105 = local_3[_e1070];
                                local_3[_e1070] = pow(_e1105, 1f);
                                let _e1107 = local_3[_e1070];
                                local_3[_e1070] = max(_e1107, 0.000061f);
                                continue;
                            } else {
                                break;
                            }
                            continuing {
                                phi_29790_ = (_e1070 + 1i);
                            }
                        }
                    }
                    let _e1110 = local_3;
                    phi_29794_ = 0f;
                    if _e1065 {
                        let _e1116 = min(_e1051[0], _e1051[3]);
                        let _e1117 = max(_e1051[0], _e1051[3]);
                        let _e1118 = min(_e1051[1], _e1051[4]);
                        let _e1119 = max(_e1051[1], _e1051[4]);
                        let _e1120 = min(_e1116, _e1051[2]);
                        let _e1121 = max(_e1116, _e1051[2]);
                        let _e1122 = min(_e1118, _e1117);
                        let _e1123 = max(_e1118, _e1117);
                        let _e1125 = max(_e1120, _e1122);
                        let _e1126 = min(_e1121, _e1119);
                        let _e1127 = max(_e1121, _e1119);
                        let _e1129 = max(_e1125, _e1126);
                        let _e1130 = min(_e1123, _e1127);
                        local_26 = array<f32, 5>(min(_e1120, _e1122), min(_e1125, _e1126), min(_e1129, _e1130), max(_e1129, _e1130), max(_e1123, _e1127));
                        let _e1140 = min(_e1110[0], _e1110[3]);
                        let _e1141 = max(_e1110[0], _e1110[3]);
                        let _e1142 = min(_e1110[1], _e1110[4]);
                        let _e1143 = max(_e1110[1], _e1110[4]);
                        let _e1144 = min(_e1140, _e1110[2]);
                        let _e1145 = max(_e1140, _e1110[2]);
                        let _e1146 = min(_e1142, _e1141);
                        let _e1147 = max(_e1142, _e1141);
                        let _e1149 = max(_e1144, _e1146);
                        let _e1150 = min(_e1145, _e1143);
                        let _e1151 = max(_e1145, _e1143);
                        let _e1153 = max(_e1149, _e1150);
                        let _e1154 = min(_e1147, _e1151);
                        local_25 = array<f32, 5>(min(_e1144, _e1146), min(_e1149, _e1150), min(_e1153, _e1154), max(_e1153, _e1154), max(_e1147, _e1151));
                        let _e1160 = local_26[4i];
                        let _e1162 = local_25[4i];
                        phi_29793_ = 65503f;
                        if (min(_e1160, _e1162) > 0.000000000000000000000000000000000000011754944f) {
                            phi_30313_ = 0i;
                            phi_30312_ = 0i;
                            phi_29792_ = 65503f;
                            phi_29791_ = 0i;
                            loop {
                                let _e1166 = phi_30313_;
                                let _e1168 = phi_30312_;
                                let _e1170 = phi_29792_;
                                let _e1172 = phi_29791_;
                                local_185 = _e1170;
                                if ((_e1172 < 5i) && (_e1170 < 65504f)) {
                                    let _e1177 = local_26[_e1168];
                                    let _e1179 = local_25[_e1166];
                                    let _e1180 = (_e1177 - _e1179);
                                    if (abs(_e1180) > 0.000061f) {
                                        let _e1184 = local_26[_e1168];
                                        let _e1185 = local_25[_e1166];
                                        let _e1186 = max(_e1184, _e1185);
                                        if (_e1186 != 0f) {
                                            phi_30314_ = (min(_e1184, _e1185) / _e1186);
                                        } else {
                                            phi_30314_ = 0f;
                                        }
                                        let _e1191 = phi_30314_;
                                        let _e1193 = (sign(_e1180) * (1f - _e1191));
                                        let _e1198 = local_26[_e1168];
                                        let _e1199 = local_25[_e1166];
                                        let _e1202 = (_e1168 + select(0i, 1i, (_e1198 < _e1199)));
                                        let _e1204 = local_26[_e1202];
                                        let _e1205 = local_25[_e1166];
                                        phi_30497_ = (_e1166 + select(0i, 1i, (_e1204 >= _e1205)));
                                        phi_30496_ = _e1202;
                                        phi_30369_ = select(_e1170, _e1193, (abs(_e1193) < abs(_e1170)));
                                    } else {
                                        phi_30497_ = _e1166;
                                        phi_30496_ = _e1168;
                                        phi_30369_ = 65504f;
                                    }
                                    let _e1210 = phi_30497_;
                                    let _e1212 = phi_30496_;
                                    let _e1214 = phi_30369_;
                                    local_182 = _e1210;
                                    local_183 = _e1212;
                                    local_184 = _e1214;
                                    continue;
                                } else {
                                    break;
                                }
                                continuing {
                                    let _e5243 = local_182;
                                    phi_30313_ = _e5243;
                                    let _e5246 = local_183;
                                    phi_30312_ = _e5246;
                                    let _e5249 = local_184;
                                    phi_29792_ = _e5249;
                                    phi_29791_ = (_e1172 + 1i);
                                }
                            }
                            let _e5257 = local_185;
                            phi_29793_ = _e5257;
                        }
                        let _e1217 = phi_29793_;
                        phi_29794_ = (_e1217 * select(0f, 1f, (_e1217 < 65503f)));
                    }
                    let _e1222 = phi_29794_;
                    let _e1227 = vec4<f32>(_e1222, vec4<f32>(0f, 0f, 0f, 0f).y, vec4<f32>(0f, 0f, 0f, 0f).z, vec4<f32>(0f, 0f, 0f, 0f).w);
                    if (_e1222 != 0f) {
                        phi_29801_ = sign(_e1222);
                    } else {
                        phi_29801_ = 0f;
                    }
                    let _e1231 = phi_29801_;
                    let _e1236 = vec4<f32>(_e1227.x, _e1231, _e1227.z, _e1227.w);
                    local_96[0i] = ((((vec4<f32>(_e480.x, _e480.y, 1f, _e480.w) + vec4<f32>(_e732.x, _e732.y, 1f, _e732.w)) + vec4<f32>(_e984.x, _e984.y, 1f, _e984.w)) + vec4<f32>(_e1236.x, _e1236.y, 1f, _e1236.w)) * 0.25f);
                    let _e1247 = local_96[0i];
                    let _e1249 = textureDimensions(global_4);
                    if all((bitcast<vec2<u32>>(_e214) < bitcast<vec2<u32>>(vec2<i32>(_e1249)))) {
                        textureStore(global_4, _e214, vec4<f32>(_e1247.x, _e1247.y, 0f, 0f));
                    }
                    let _e1258 = bitcast<i32>((_e203 + 32u));
                    let _e1260 = (_e202 + vec2<i32>(_e1258, _e206));
                    let _e1262 = bitcast<i32>((_e195 + 16u));
                    let _e1264 = (_e210 + vec2<i32>(_e1262, _e212));
                    let _e1265 = bitcast<vec2<u32>>(_e1260);
                    let _e1270 = vec2<i32>(vec2<f32>(_e1260));
                    let _e1277 = vec2<i32>(max(0i, min(_e1270.x, _e224)), max(0i, min(_e1270.y, _e229)));
                    let _e1279 = textureDimensions(global_3, 0i);
                    if all((bitcast<vec2<u32>>(_e1277) < bitcast<vec2<u32>>(vec2<i32>(_e1279)))) {
                        let _e1284 = textureLoad(global_3, _e1277, 0i);
                        phi_29847_ = _e1284;
                    } else {
                        phi_29847_ = vec4<f32>(0f, 0f, 0f, 0f);
                    }
                    let _e1286 = phi_29847_;
                    let _e1290 = ((vec2<f32>(_e1277) + vec2<f32>(0.5f, 0.5f)) / _e246);
                    phi_29848_ = 0i;
                    loop {
                        let _e1296 = phi_29848_;
                        if (_e1296 < 5i) {
                            local_87 = array<vec2<i32>, 5>(vec2<i32>(0i, 0i), vec2<i32>(-1i, 0i), vec2<i32>(1i, 0i), vec2<i32>(0i, -1i), vec2<i32>(0i, 1i));
                            let _e1299 = local_87[_e1296];
                            let _e1300 = (vec2<i32>(floor(((_e1290 + _e250) * _e246))) + _e1299);
                            let _e1307 = vec2<i32>(max(0i, min(_e1300.x, _e224)), max(0i, min(_e1300.y, _e229)));
                            let _e1309 = textureDimensions(global_1, 0i);
                            if all((bitcast<vec2<u32>>(_e1307) < bitcast<vec2<u32>>(vec2<i32>(_e1309)))) {
                                let _e1314 = textureLoad(global_1, _e1307, 0i);
                                phi_30310_ = _e1314;
                            } else {
                                phi_30310_ = vec4<f32>(0f, 0f, 0f, 0f);
                            }
                            let _e1316 = phi_30310_;
                            let _e1319 = global.member_18;
                            local_30[_e1296] = (_e1316.x * select(_e1319, 1f, (_e1319 == 0f)));
                            let _e1324 = local_30[_e1296];
                            local_30[_e1296] = pow(_e1324, 1f);
                            let _e1326 = local_30[_e1296];
                            local_30[_e1296] = max(_e1326, 0.000061f);
                            continue;
                        } else {
                            break;
                        }
                        continuing {
                            phi_29848_ = (_e1296 + 1i);
                        }
                    }
                    let _e1329 = local_30;
                    let _e1331 = ((_e1290 + _e295) + _e1286.xy);
                    let _e1333 = (_e1331.x >= 0f);
                    phi_8108_ = _e1333;
                    if _e1333 {
                        phi_8108_ = (_e1331.x <= 1f);
                    }
                    let _e1336 = phi_8108_;
                    phi_8120_ = _e1336;
                    if _e1336 {
                        let _e1338 = (_e1331.y >= 0f);
                        phi_8118_ = _e1338;
                        if _e1338 {
                            phi_8118_ = (_e1331.y <= 1f);
                        }
                        let _e1341 = phi_8118_;
                        phi_8120_ = _e1341;
                    }
                    let _e1343 = phi_8120_;
                    if _e1343 {
                        phi_29849_ = 0i;
                        loop {
                            let _e1348 = phi_29849_;
                            if (_e1348 < 5i) {
                                local_86 = array<vec2<i32>, 5>(vec2<i32>(0i, 0i), vec2<i32>(-1i, 0i), vec2<i32>(1i, 0i), vec2<i32>(0i, -1i), vec2<i32>(0i, 1i));
                                let _e1351 = local_86[_e1348];
                                let _e1352 = (vec2<i32>(floor((_e1331 * _e294))) + _e1351);
                                let _e1363 = vec2<i32>(max(0i, min(_e1352.x, (_e293.x - 1i))), max(0i, min(_e1352.y, (_e293.y - 1i))));
                                let _e1365 = textureDimensions(global_2, 0i);
                                if all((bitcast<vec2<u32>>(_e1363) < bitcast<vec2<u32>>(vec2<i32>(_e1365)))) {
                                    let _e1370 = textureLoad(global_2, _e1363, 0i);
                                    phi_30308_ = _e1370;
                                } else {
                                    phi_30308_ = vec4<f32>(0f, 0f, 0f, 0f);
                                }
                                let _e1372 = phi_30308_;
                                let _e1375 = global.member_10;
                                let _e1378 = global.member_18;
                                local_4[_e1348] = ((_e1372.x * _e1375) * select(_e1378, 1f, (_e1378 == 0f)));
                                let _e1383 = local_4[_e1348];
                                local_4[_e1348] = pow(_e1383, 1f);
                                let _e1385 = local_4[_e1348];
                                local_4[_e1348] = max(_e1385, 0.000061f);
                                continue;
                            } else {
                                break;
                            }
                            continuing {
                                phi_29849_ = (_e1348 + 1i);
                            }
                        }
                    }
                    let _e1388 = local_4;
                    phi_29853_ = 0f;
                    if _e1343 {
                        let _e1394 = min(_e1329[0], _e1329[3]);
                        let _e1395 = max(_e1329[0], _e1329[3]);
                        let _e1396 = min(_e1329[1], _e1329[4]);
                        let _e1397 = max(_e1329[1], _e1329[4]);
                        let _e1398 = min(_e1394, _e1329[2]);
                        let _e1399 = max(_e1394, _e1329[2]);
                        let _e1400 = min(_e1396, _e1395);
                        let _e1401 = max(_e1396, _e1395);
                        let _e1403 = max(_e1398, _e1400);
                        let _e1404 = min(_e1399, _e1397);
                        let _e1405 = max(_e1399, _e1397);
                        let _e1407 = max(_e1403, _e1404);
                        let _e1408 = min(_e1401, _e1405);
                        local_29 = array<f32, 5>(min(_e1398, _e1400), min(_e1403, _e1404), min(_e1407, _e1408), max(_e1407, _e1408), max(_e1401, _e1405));
                        let _e1418 = min(_e1388[0], _e1388[3]);
                        let _e1419 = max(_e1388[0], _e1388[3]);
                        let _e1420 = min(_e1388[1], _e1388[4]);
                        let _e1421 = max(_e1388[1], _e1388[4]);
                        let _e1422 = min(_e1418, _e1388[2]);
                        let _e1423 = max(_e1418, _e1388[2]);
                        let _e1424 = min(_e1420, _e1419);
                        let _e1425 = max(_e1420, _e1419);
                        let _e1427 = max(_e1422, _e1424);
                        let _e1428 = min(_e1423, _e1421);
                        let _e1429 = max(_e1423, _e1421);
                        let _e1431 = max(_e1427, _e1428);
                        let _e1432 = min(_e1425, _e1429);
                        local_28 = array<f32, 5>(min(_e1422, _e1424), min(_e1427, _e1428), min(_e1431, _e1432), max(_e1431, _e1432), max(_e1425, _e1429));
                        let _e1438 = local_29[4i];
                        let _e1440 = local_28[4i];
                        phi_29852_ = 65503f;
                        if (min(_e1438, _e1440) > 0.000000000000000000000000000000000000011754944f) {
                            phi_30301_ = 0i;
                            phi_30300_ = 0i;
                            phi_29851_ = 65503f;
                            phi_29850_ = 0i;
                            loop {
                                let _e1444 = phi_30301_;
                                let _e1446 = phi_30300_;
                                let _e1448 = phi_29851_;
                                let _e1450 = phi_29850_;
                                local_189 = _e1448;
                                if ((_e1450 < 5i) && (_e1448 < 65504f)) {
                                    let _e1455 = local_29[_e1446];
                                    let _e1457 = local_28[_e1444];
                                    let _e1458 = (_e1455 - _e1457);
                                    if (abs(_e1458) > 0.000061f) {
                                        let _e1462 = local_29[_e1446];
                                        let _e1463 = local_28[_e1444];
                                        let _e1464 = max(_e1462, _e1463);
                                        if (_e1464 != 0f) {
                                            phi_30302_ = (min(_e1462, _e1463) / _e1464);
                                        } else {
                                            phi_30302_ = 0f;
                                        }
                                        let _e1469 = phi_30302_;
                                        let _e1471 = (sign(_e1458) * (1f - _e1469));
                                        let _e1476 = local_29[_e1446];
                                        let _e1477 = local_28[_e1444];
                                        let _e1480 = (_e1446 + select(0i, 1i, (_e1476 < _e1477)));
                                        let _e1482 = local_29[_e1480];
                                        let _e1483 = local_28[_e1444];
                                        phi_30495_ = (_e1444 + select(0i, 1i, (_e1482 >= _e1483)));
                                        phi_30494_ = _e1480;
                                        phi_30388_ = select(_e1448, _e1471, (abs(_e1471) < abs(_e1448)));
                                    } else {
                                        phi_30495_ = _e1444;
                                        phi_30494_ = _e1446;
                                        phi_30388_ = 65504f;
                                    }
                                    let _e1488 = phi_30495_;
                                    let _e1490 = phi_30494_;
                                    let _e1492 = phi_30388_;
                                    local_186 = _e1488;
                                    local_187 = _e1490;
                                    local_188 = _e1492;
                                    continue;
                                } else {
                                    break;
                                }
                                continuing {
                                    let _e5270 = local_186;
                                    phi_30301_ = _e5270;
                                    let _e5273 = local_187;
                                    phi_30300_ = _e5273;
                                    let _e5276 = local_188;
                                    phi_29851_ = _e5276;
                                    phi_29850_ = (_e1450 + 1i);
                                }
                            }
                            let _e5284 = local_189;
                            phi_29852_ = _e5284;
                        }
                        let _e1495 = phi_29852_;
                        phi_29853_ = (_e1495 * select(0f, 1f, (_e1495 < 65503f)));
                    }
                    let _e1500 = phi_29853_;
                    let _e1505 = vec4<f32>(_e1500, vec4<f32>(0f, 0f, 0f, 0f).y, vec4<f32>(0f, 0f, 0f, 0f).z, vec4<f32>(0f, 0f, 0f, 0f).w);
                    if (_e1500 != 0f) {
                        phi_29860_ = sign(_e1500);
                    } else {
                        phi_29860_ = 0f;
                    }
                    let _e1509 = phi_29860_;
                    let _e1514 = vec4<f32>(_e1505.x, _e1509, _e1505.z, _e1505.w);
                    let _e1522 = vec2<i32>(vec2<f32>(bitcast<vec2<i32>>((_e1265 + vec2<u32>(0u, 1u)))));
                    let _e1529 = vec2<i32>(max(0i, min(_e1522.x, _e224)), max(0i, min(_e1522.y, _e229)));
                    let _e1531 = textureDimensions(global_3, 0i);
                    if all((bitcast<vec2<u32>>(_e1529) < bitcast<vec2<u32>>(vec2<i32>(_e1531)))) {
                        let _e1536 = textureLoad(global_3, _e1529, 0i);
                        phi_29862_ = _e1536;
                    } else {
                        phi_29862_ = vec4<f32>(0f, 0f, 0f, 0f);
                    }
                    let _e1538 = phi_29862_;
                    let _e1542 = ((vec2<f32>(_e1529) + vec2<f32>(0.5f, 0.5f)) / _e246);
                    phi_29863_ = 0i;
                    loop {
                        let _e1548 = phi_29863_;
                        if (_e1548 < 5i) {
                            local_85 = array<vec2<i32>, 5>(vec2<i32>(0i, 0i), vec2<i32>(-1i, 0i), vec2<i32>(1i, 0i), vec2<i32>(0i, -1i), vec2<i32>(0i, 1i));
                            let _e1551 = local_85[_e1548];
                            let _e1552 = (vec2<i32>(floor(((_e1542 + _e250) * _e246))) + _e1551);
                            let _e1559 = vec2<i32>(max(0i, min(_e1552.x, _e224)), max(0i, min(_e1552.y, _e229)));
                            let _e1561 = textureDimensions(global_1, 0i);
                            if all((bitcast<vec2<u32>>(_e1559) < bitcast<vec2<u32>>(vec2<i32>(_e1561)))) {
                                let _e1566 = textureLoad(global_1, _e1559, 0i);
                                phi_30298_ = _e1566;
                            } else {
                                phi_30298_ = vec4<f32>(0f, 0f, 0f, 0f);
                            }
                            let _e1568 = phi_30298_;
                            let _e1571 = global.member_18;
                            local_33[_e1548] = (_e1568.x * select(_e1571, 1f, (_e1571 == 0f)));
                            let _e1576 = local_33[_e1548];
                            local_33[_e1548] = pow(_e1576, 1f);
                            let _e1578 = local_33[_e1548];
                            local_33[_e1548] = max(_e1578, 0.000061f);
                            continue;
                        } else {
                            break;
                        }
                        continuing {
                            phi_29863_ = (_e1548 + 1i);
                        }
                    }
                    let _e1581 = local_33;
                    let _e1583 = ((_e1542 + _e295) + _e1538.xy);
                    let _e1585 = (_e1583.x >= 0f);
                    phi_9264_ = _e1585;
                    if _e1585 {
                        phi_9264_ = (_e1583.x <= 1f);
                    }
                    let _e1588 = phi_9264_;
                    phi_9276_ = _e1588;
                    if _e1588 {
                        let _e1590 = (_e1583.y >= 0f);
                        phi_9274_ = _e1590;
                        if _e1590 {
                            phi_9274_ = (_e1583.y <= 1f);
                        }
                        let _e1593 = phi_9274_;
                        phi_9276_ = _e1593;
                    }
                    let _e1595 = phi_9276_;
                    if _e1595 {
                        phi_29864_ = 0i;
                        loop {
                            let _e1600 = phi_29864_;
                            if (_e1600 < 5i) {
                                local_84 = array<vec2<i32>, 5>(vec2<i32>(0i, 0i), vec2<i32>(-1i, 0i), vec2<i32>(1i, 0i), vec2<i32>(0i, -1i), vec2<i32>(0i, 1i));
                                let _e1603 = local_84[_e1600];
                                let _e1604 = (vec2<i32>(floor((_e1583 * _e294))) + _e1603);
                                let _e1615 = vec2<i32>(max(0i, min(_e1604.x, (_e293.x - 1i))), max(0i, min(_e1604.y, (_e293.y - 1i))));
                                let _e1617 = textureDimensions(global_2, 0i);
                                if all((bitcast<vec2<u32>>(_e1615) < bitcast<vec2<u32>>(vec2<i32>(_e1617)))) {
                                    let _e1622 = textureLoad(global_2, _e1615, 0i);
                                    phi_30296_ = _e1622;
                                } else {
                                    phi_30296_ = vec4<f32>(0f, 0f, 0f, 0f);
                                }
                                let _e1624 = phi_30296_;
                                let _e1627 = global.member_10;
                                let _e1630 = global.member_18;
                                local_5[_e1600] = ((_e1624.x * _e1627) * select(_e1630, 1f, (_e1630 == 0f)));
                                let _e1635 = local_5[_e1600];
                                local_5[_e1600] = pow(_e1635, 1f);
                                let _e1637 = local_5[_e1600];
                                local_5[_e1600] = max(_e1637, 0.000061f);
                                continue;
                            } else {
                                break;
                            }
                            continuing {
                                phi_29864_ = (_e1600 + 1i);
                            }
                        }
                    }
                    let _e1640 = local_5;
                    phi_29868_ = 0f;
                    if _e1595 {
                        let _e1646 = min(_e1581[0], _e1581[3]);
                        let _e1647 = max(_e1581[0], _e1581[3]);
                        let _e1648 = min(_e1581[1], _e1581[4]);
                        let _e1649 = max(_e1581[1], _e1581[4]);
                        let _e1650 = min(_e1646, _e1581[2]);
                        let _e1651 = max(_e1646, _e1581[2]);
                        let _e1652 = min(_e1648, _e1647);
                        let _e1653 = max(_e1648, _e1647);
                        let _e1655 = max(_e1650, _e1652);
                        let _e1656 = min(_e1651, _e1649);
                        let _e1657 = max(_e1651, _e1649);
                        let _e1659 = max(_e1655, _e1656);
                        let _e1660 = min(_e1653, _e1657);
                        local_32 = array<f32, 5>(min(_e1650, _e1652), min(_e1655, _e1656), min(_e1659, _e1660), max(_e1659, _e1660), max(_e1653, _e1657));
                        let _e1670 = min(_e1640[0], _e1640[3]);
                        let _e1671 = max(_e1640[0], _e1640[3]);
                        let _e1672 = min(_e1640[1], _e1640[4]);
                        let _e1673 = max(_e1640[1], _e1640[4]);
                        let _e1674 = min(_e1670, _e1640[2]);
                        let _e1675 = max(_e1670, _e1640[2]);
                        let _e1676 = min(_e1672, _e1671);
                        let _e1677 = max(_e1672, _e1671);
                        let _e1679 = max(_e1674, _e1676);
                        let _e1680 = min(_e1675, _e1673);
                        let _e1681 = max(_e1675, _e1673);
                        let _e1683 = max(_e1679, _e1680);
                        let _e1684 = min(_e1677, _e1681);
                        local_31 = array<f32, 5>(min(_e1674, _e1676), min(_e1679, _e1680), min(_e1683, _e1684), max(_e1683, _e1684), max(_e1677, _e1681));
                        let _e1690 = local_32[4i];
                        let _e1692 = local_31[4i];
                        phi_29867_ = 65503f;
                        if (min(_e1690, _e1692) > 0.000000000000000000000000000000000000011754944f) {
                            phi_30289_ = 0i;
                            phi_30288_ = 0i;
                            phi_29866_ = 65503f;
                            phi_29865_ = 0i;
                            loop {
                                let _e1696 = phi_30289_;
                                let _e1698 = phi_30288_;
                                let _e1700 = phi_29866_;
                                let _e1702 = phi_29865_;
                                local_193 = _e1700;
                                if ((_e1702 < 5i) && (_e1700 < 65504f)) {
                                    let _e1707 = local_32[_e1698];
                                    let _e1709 = local_31[_e1696];
                                    let _e1710 = (_e1707 - _e1709);
                                    if (abs(_e1710) > 0.000061f) {
                                        let _e1714 = local_32[_e1698];
                                        let _e1715 = local_31[_e1696];
                                        let _e1716 = max(_e1714, _e1715);
                                        if (_e1716 != 0f) {
                                            phi_30290_ = (min(_e1714, _e1715) / _e1716);
                                        } else {
                                            phi_30290_ = 0f;
                                        }
                                        let _e1721 = phi_30290_;
                                        let _e1723 = (sign(_e1710) * (1f - _e1721));
                                        let _e1728 = local_32[_e1698];
                                        let _e1729 = local_31[_e1696];
                                        let _e1732 = (_e1698 + select(0i, 1i, (_e1728 < _e1729)));
                                        let _e1734 = local_32[_e1732];
                                        let _e1735 = local_31[_e1696];
                                        phi_30493_ = (_e1696 + select(0i, 1i, (_e1734 >= _e1735)));
                                        phi_30492_ = _e1732;
                                        phi_30391_ = select(_e1700, _e1723, (abs(_e1723) < abs(_e1700)));
                                    } else {
                                        phi_30493_ = _e1696;
                                        phi_30492_ = _e1698;
                                        phi_30391_ = 65504f;
                                    }
                                    let _e1740 = phi_30493_;
                                    let _e1742 = phi_30492_;
                                    let _e1744 = phi_30391_;
                                    local_190 = _e1740;
                                    local_191 = _e1742;
                                    local_192 = _e1744;
                                    continue;
                                } else {
                                    break;
                                }
                                continuing {
                                    let _e5297 = local_190;
                                    phi_30289_ = _e5297;
                                    let _e5300 = local_191;
                                    phi_30288_ = _e5300;
                                    let _e5303 = local_192;
                                    phi_29866_ = _e5303;
                                    phi_29865_ = (_e1702 + 1i);
                                }
                            }
                            let _e5311 = local_193;
                            phi_29867_ = _e5311;
                        }
                        let _e1747 = phi_29867_;
                        phi_29868_ = (_e1747 * select(0f, 1f, (_e1747 < 65503f)));
                    }
                    let _e1752 = phi_29868_;
                    let _e1757 = vec4<f32>(_e1752, vec4<f32>(0f, 0f, 0f, 0f).y, vec4<f32>(0f, 0f, 0f, 0f).z, vec4<f32>(0f, 0f, 0f, 0f).w);
                    if (_e1752 != 0f) {
                        phi_29875_ = sign(_e1752);
                    } else {
                        phi_29875_ = 0f;
                    }
                    let _e1761 = phi_29875_;
                    let _e1766 = vec4<f32>(_e1757.x, _e1761, _e1757.z, _e1757.w);
                    let _e1774 = vec2<i32>(vec2<f32>(bitcast<vec2<i32>>((_e1265 + vec2<u32>(1u, 0u)))));
                    let _e1781 = vec2<i32>(max(0i, min(_e1774.x, _e224)), max(0i, min(_e1774.y, _e229)));
                    let _e1783 = textureDimensions(global_3, 0i);
                    if all((bitcast<vec2<u32>>(_e1781) < bitcast<vec2<u32>>(vec2<i32>(_e1783)))) {
                        let _e1788 = textureLoad(global_3, _e1781, 0i);
                        phi_29877_ = _e1788;
                    } else {
                        phi_29877_ = vec4<f32>(0f, 0f, 0f, 0f);
                    }
                    let _e1790 = phi_29877_;
                    let _e1794 = ((vec2<f32>(_e1781) + vec2<f32>(0.5f, 0.5f)) / _e246);
                    phi_29878_ = 0i;
                    loop {
                        let _e1800 = phi_29878_;
                        if (_e1800 < 5i) {
                            local_83 = array<vec2<i32>, 5>(vec2<i32>(0i, 0i), vec2<i32>(-1i, 0i), vec2<i32>(1i, 0i), vec2<i32>(0i, -1i), vec2<i32>(0i, 1i));
                            let _e1803 = local_83[_e1800];
                            let _e1804 = (vec2<i32>(floor(((_e1794 + _e250) * _e246))) + _e1803);
                            let _e1811 = vec2<i32>(max(0i, min(_e1804.x, _e224)), max(0i, min(_e1804.y, _e229)));
                            let _e1813 = textureDimensions(global_1, 0i);
                            if all((bitcast<vec2<u32>>(_e1811) < bitcast<vec2<u32>>(vec2<i32>(_e1813)))) {
                                let _e1818 = textureLoad(global_1, _e1811, 0i);
                                phi_30286_ = _e1818;
                            } else {
                                phi_30286_ = vec4<f32>(0f, 0f, 0f, 0f);
                            }
                            let _e1820 = phi_30286_;
                            let _e1823 = global.member_18;
                            local_36[_e1800] = (_e1820.x * select(_e1823, 1f, (_e1823 == 0f)));
                            let _e1828 = local_36[_e1800];
                            local_36[_e1800] = pow(_e1828, 1f);
                            let _e1830 = local_36[_e1800];
                            local_36[_e1800] = max(_e1830, 0.000061f);
                            continue;
                        } else {
                            break;
                        }
                        continuing {
                            phi_29878_ = (_e1800 + 1i);
                        }
                    }
                    let _e1833 = local_36;
                    let _e1835 = ((_e1794 + _e295) + _e1790.xy);
                    let _e1837 = (_e1835.x >= 0f);
                    phi_10420_ = _e1837;
                    if _e1837 {
                        phi_10420_ = (_e1835.x <= 1f);
                    }
                    let _e1840 = phi_10420_;
                    phi_10432_ = _e1840;
                    if _e1840 {
                        let _e1842 = (_e1835.y >= 0f);
                        phi_10430_ = _e1842;
                        if _e1842 {
                            phi_10430_ = (_e1835.y <= 1f);
                        }
                        let _e1845 = phi_10430_;
                        phi_10432_ = _e1845;
                    }
                    let _e1847 = phi_10432_;
                    if _e1847 {
                        phi_29879_ = 0i;
                        loop {
                            let _e1852 = phi_29879_;
                            if (_e1852 < 5i) {
                                local_82 = array<vec2<i32>, 5>(vec2<i32>(0i, 0i), vec2<i32>(-1i, 0i), vec2<i32>(1i, 0i), vec2<i32>(0i, -1i), vec2<i32>(0i, 1i));
                                let _e1855 = local_82[_e1852];
                                let _e1856 = (vec2<i32>(floor((_e1835 * _e294))) + _e1855);
                                let _e1867 = vec2<i32>(max(0i, min(_e1856.x, (_e293.x - 1i))), max(0i, min(_e1856.y, (_e293.y - 1i))));
                                let _e1869 = textureDimensions(global_2, 0i);
                                if all((bitcast<vec2<u32>>(_e1867) < bitcast<vec2<u32>>(vec2<i32>(_e1869)))) {
                                    let _e1874 = textureLoad(global_2, _e1867, 0i);
                                    phi_30284_ = _e1874;
                                } else {
                                    phi_30284_ = vec4<f32>(0f, 0f, 0f, 0f);
                                }
                                let _e1876 = phi_30284_;
                                let _e1879 = global.member_10;
                                let _e1882 = global.member_18;
                                local_6[_e1852] = ((_e1876.x * _e1879) * select(_e1882, 1f, (_e1882 == 0f)));
                                let _e1887 = local_6[_e1852];
                                local_6[_e1852] = pow(_e1887, 1f);
                                let _e1889 = local_6[_e1852];
                                local_6[_e1852] = max(_e1889, 0.000061f);
                                continue;
                            } else {
                                break;
                            }
                            continuing {
                                phi_29879_ = (_e1852 + 1i);
                            }
                        }
                    }
                    let _e1892 = local_6;
                    phi_29883_ = 0f;
                    if _e1847 {
                        let _e1898 = min(_e1833[0], _e1833[3]);
                        let _e1899 = max(_e1833[0], _e1833[3]);
                        let _e1900 = min(_e1833[1], _e1833[4]);
                        let _e1901 = max(_e1833[1], _e1833[4]);
                        let _e1902 = min(_e1898, _e1833[2]);
                        let _e1903 = max(_e1898, _e1833[2]);
                        let _e1904 = min(_e1900, _e1899);
                        let _e1905 = max(_e1900, _e1899);
                        let _e1907 = max(_e1902, _e1904);
                        let _e1908 = min(_e1903, _e1901);
                        let _e1909 = max(_e1903, _e1901);
                        let _e1911 = max(_e1907, _e1908);
                        let _e1912 = min(_e1905, _e1909);
                        local_35 = array<f32, 5>(min(_e1902, _e1904), min(_e1907, _e1908), min(_e1911, _e1912), max(_e1911, _e1912), max(_e1905, _e1909));
                        let _e1922 = min(_e1892[0], _e1892[3]);
                        let _e1923 = max(_e1892[0], _e1892[3]);
                        let _e1924 = min(_e1892[1], _e1892[4]);
                        let _e1925 = max(_e1892[1], _e1892[4]);
                        let _e1926 = min(_e1922, _e1892[2]);
                        let _e1927 = max(_e1922, _e1892[2]);
                        let _e1928 = min(_e1924, _e1923);
                        let _e1929 = max(_e1924, _e1923);
                        let _e1931 = max(_e1926, _e1928);
                        let _e1932 = min(_e1927, _e1925);
                        let _e1933 = max(_e1927, _e1925);
                        let _e1935 = max(_e1931, _e1932);
                        let _e1936 = min(_e1929, _e1933);
                        local_34 = array<f32, 5>(min(_e1926, _e1928), min(_e1931, _e1932), min(_e1935, _e1936), max(_e1935, _e1936), max(_e1929, _e1933));
                        let _e1942 = local_35[4i];
                        let _e1944 = local_34[4i];
                        phi_29882_ = 65503f;
                        if (min(_e1942, _e1944) > 0.000000000000000000000000000000000000011754944f) {
                            phi_30277_ = 0i;
                            phi_30276_ = 0i;
                            phi_29881_ = 65503f;
                            phi_29880_ = 0i;
                            loop {
                                let _e1948 = phi_30277_;
                                let _e1950 = phi_30276_;
                                let _e1952 = phi_29881_;
                                let _e1954 = phi_29880_;
                                local_197 = _e1952;
                                if ((_e1954 < 5i) && (_e1952 < 65504f)) {
                                    let _e1959 = local_35[_e1950];
                                    let _e1961 = local_34[_e1948];
                                    let _e1962 = (_e1959 - _e1961);
                                    if (abs(_e1962) > 0.000061f) {
                                        let _e1966 = local_35[_e1950];
                                        let _e1967 = local_34[_e1948];
                                        let _e1968 = max(_e1966, _e1967);
                                        if (_e1968 != 0f) {
                                            phi_30278_ = (min(_e1966, _e1967) / _e1968);
                                        } else {
                                            phi_30278_ = 0f;
                                        }
                                        let _e1973 = phi_30278_;
                                        let _e1975 = (sign(_e1962) * (1f - _e1973));
                                        let _e1980 = local_35[_e1950];
                                        let _e1981 = local_34[_e1948];
                                        let _e1984 = (_e1950 + select(0i, 1i, (_e1980 < _e1981)));
                                        let _e1986 = local_35[_e1984];
                                        let _e1987 = local_34[_e1948];
                                        phi_30491_ = (_e1948 + select(0i, 1i, (_e1986 >= _e1987)));
                                        phi_30490_ = _e1984;
                                        phi_30394_ = select(_e1952, _e1975, (abs(_e1975) < abs(_e1952)));
                                    } else {
                                        phi_30491_ = _e1948;
                                        phi_30490_ = _e1950;
                                        phi_30394_ = 65504f;
                                    }
                                    let _e1992 = phi_30491_;
                                    let _e1994 = phi_30490_;
                                    let _e1996 = phi_30394_;
                                    local_194 = _e1992;
                                    local_195 = _e1994;
                                    local_196 = _e1996;
                                    continue;
                                } else {
                                    break;
                                }
                                continuing {
                                    let _e5324 = local_194;
                                    phi_30277_ = _e5324;
                                    let _e5327 = local_195;
                                    phi_30276_ = _e5327;
                                    let _e5330 = local_196;
                                    phi_29881_ = _e5330;
                                    phi_29880_ = (_e1954 + 1i);
                                }
                            }
                            let _e5338 = local_197;
                            phi_29882_ = _e5338;
                        }
                        let _e1999 = phi_29882_;
                        phi_29883_ = (_e1999 * select(0f, 1f, (_e1999 < 65503f)));
                    }
                    let _e2004 = phi_29883_;
                    let _e2009 = vec4<f32>(_e2004, vec4<f32>(0f, 0f, 0f, 0f).y, vec4<f32>(0f, 0f, 0f, 0f).z, vec4<f32>(0f, 0f, 0f, 0f).w);
                    if (_e2004 != 0f) {
                        phi_29890_ = sign(_e2004);
                    } else {
                        phi_29890_ = 0f;
                    }
                    let _e2013 = phi_29890_;
                    let _e2018 = vec4<f32>(_e2009.x, _e2013, _e2009.z, _e2009.w);
                    let _e2026 = vec2<i32>(vec2<f32>(bitcast<vec2<i32>>((_e1265 + vec2<u32>(1u, 1u)))));
                    let _e2033 = vec2<i32>(max(0i, min(_e2026.x, _e224)), max(0i, min(_e2026.y, _e229)));
                    let _e2035 = textureDimensions(global_3, 0i);
                    if all((bitcast<vec2<u32>>(_e2033) < bitcast<vec2<u32>>(vec2<i32>(_e2035)))) {
                        let _e2040 = textureLoad(global_3, _e2033, 0i);
                        phi_29892_ = _e2040;
                    } else {
                        phi_29892_ = vec4<f32>(0f, 0f, 0f, 0f);
                    }
                    let _e2042 = phi_29892_;
                    let _e2046 = ((vec2<f32>(_e2033) + vec2<f32>(0.5f, 0.5f)) / _e246);
                    phi_29893_ = 0i;
                    loop {
                        let _e2052 = phi_29893_;
                        if (_e2052 < 5i) {
                            local_81 = array<vec2<i32>, 5>(vec2<i32>(0i, 0i), vec2<i32>(-1i, 0i), vec2<i32>(1i, 0i), vec2<i32>(0i, -1i), vec2<i32>(0i, 1i));
                            let _e2055 = local_81[_e2052];
                            let _e2056 = (vec2<i32>(floor(((_e2046 + _e250) * _e246))) + _e2055);
                            let _e2063 = vec2<i32>(max(0i, min(_e2056.x, _e224)), max(0i, min(_e2056.y, _e229)));
                            let _e2065 = textureDimensions(global_1, 0i);
                            if all((bitcast<vec2<u32>>(_e2063) < bitcast<vec2<u32>>(vec2<i32>(_e2065)))) {
                                let _e2070 = textureLoad(global_1, _e2063, 0i);
                                phi_30274_ = _e2070;
                            } else {
                                phi_30274_ = vec4<f32>(0f, 0f, 0f, 0f);
                            }
                            let _e2072 = phi_30274_;
                            let _e2075 = global.member_18;
                            local_39[_e2052] = (_e2072.x * select(_e2075, 1f, (_e2075 == 0f)));
                            let _e2080 = local_39[_e2052];
                            local_39[_e2052] = pow(_e2080, 1f);
                            let _e2082 = local_39[_e2052];
                            local_39[_e2052] = max(_e2082, 0.000061f);
                            continue;
                        } else {
                            break;
                        }
                        continuing {
                            phi_29893_ = (_e2052 + 1i);
                        }
                    }
                    let _e2085 = local_39;
                    let _e2087 = ((_e2046 + _e295) + _e2042.xy);
                    let _e2089 = (_e2087.x >= 0f);
                    phi_11576_ = _e2089;
                    if _e2089 {
                        phi_11576_ = (_e2087.x <= 1f);
                    }
                    let _e2092 = phi_11576_;
                    phi_11588_ = _e2092;
                    if _e2092 {
                        let _e2094 = (_e2087.y >= 0f);
                        phi_11586_ = _e2094;
                        if _e2094 {
                            phi_11586_ = (_e2087.y <= 1f);
                        }
                        let _e2097 = phi_11586_;
                        phi_11588_ = _e2097;
                    }
                    let _e2099 = phi_11588_;
                    if _e2099 {
                        phi_29894_ = 0i;
                        loop {
                            let _e2104 = phi_29894_;
                            if (_e2104 < 5i) {
                                local_80 = array<vec2<i32>, 5>(vec2<i32>(0i, 0i), vec2<i32>(-1i, 0i), vec2<i32>(1i, 0i), vec2<i32>(0i, -1i), vec2<i32>(0i, 1i));
                                let _e2107 = local_80[_e2104];
                                let _e2108 = (vec2<i32>(floor((_e2087 * _e294))) + _e2107);
                                let _e2119 = vec2<i32>(max(0i, min(_e2108.x, (_e293.x - 1i))), max(0i, min(_e2108.y, (_e293.y - 1i))));
                                let _e2121 = textureDimensions(global_2, 0i);
                                if all((bitcast<vec2<u32>>(_e2119) < bitcast<vec2<u32>>(vec2<i32>(_e2121)))) {
                                    let _e2126 = textureLoad(global_2, _e2119, 0i);
                                    phi_30272_ = _e2126;
                                } else {
                                    phi_30272_ = vec4<f32>(0f, 0f, 0f, 0f);
                                }
                                let _e2128 = phi_30272_;
                                let _e2131 = global.member_10;
                                let _e2134 = global.member_18;
                                local_7[_e2104] = ((_e2128.x * _e2131) * select(_e2134, 1f, (_e2134 == 0f)));
                                let _e2139 = local_7[_e2104];
                                local_7[_e2104] = pow(_e2139, 1f);
                                let _e2141 = local_7[_e2104];
                                local_7[_e2104] = max(_e2141, 0.000061f);
                                continue;
                            } else {
                                break;
                            }
                            continuing {
                                phi_29894_ = (_e2104 + 1i);
                            }
                        }
                    }
                    let _e2144 = local_7;
                    phi_29898_ = 0f;
                    if _e2099 {
                        let _e2150 = min(_e2085[0], _e2085[3]);
                        let _e2151 = max(_e2085[0], _e2085[3]);
                        let _e2152 = min(_e2085[1], _e2085[4]);
                        let _e2153 = max(_e2085[1], _e2085[4]);
                        let _e2154 = min(_e2150, _e2085[2]);
                        let _e2155 = max(_e2150, _e2085[2]);
                        let _e2156 = min(_e2152, _e2151);
                        let _e2157 = max(_e2152, _e2151);
                        let _e2159 = max(_e2154, _e2156);
                        let _e2160 = min(_e2155, _e2153);
                        let _e2161 = max(_e2155, _e2153);
                        let _e2163 = max(_e2159, _e2160);
                        let _e2164 = min(_e2157, _e2161);
                        local_38 = array<f32, 5>(min(_e2154, _e2156), min(_e2159, _e2160), min(_e2163, _e2164), max(_e2163, _e2164), max(_e2157, _e2161));
                        let _e2174 = min(_e2144[0], _e2144[3]);
                        let _e2175 = max(_e2144[0], _e2144[3]);
                        let _e2176 = min(_e2144[1], _e2144[4]);
                        let _e2177 = max(_e2144[1], _e2144[4]);
                        let _e2178 = min(_e2174, _e2144[2]);
                        let _e2179 = max(_e2174, _e2144[2]);
                        let _e2180 = min(_e2176, _e2175);
                        let _e2181 = max(_e2176, _e2175);
                        let _e2183 = max(_e2178, _e2180);
                        let _e2184 = min(_e2179, _e2177);
                        let _e2185 = max(_e2179, _e2177);
                        let _e2187 = max(_e2183, _e2184);
                        let _e2188 = min(_e2181, _e2185);
                        local_37 = array<f32, 5>(min(_e2178, _e2180), min(_e2183, _e2184), min(_e2187, _e2188), max(_e2187, _e2188), max(_e2181, _e2185));
                        let _e2194 = local_38[4i];
                        let _e2196 = local_37[4i];
                        phi_29897_ = 65503f;
                        if (min(_e2194, _e2196) > 0.000000000000000000000000000000000000011754944f) {
                            phi_30265_ = 0i;
                            phi_30264_ = 0i;
                            phi_29896_ = 65503f;
                            phi_29895_ = 0i;
                            loop {
                                let _e2200 = phi_30265_;
                                let _e2202 = phi_30264_;
                                let _e2204 = phi_29896_;
                                let _e2206 = phi_29895_;
                                local_201 = _e2204;
                                if ((_e2206 < 5i) && (_e2204 < 65504f)) {
                                    let _e2211 = local_38[_e2202];
                                    let _e2213 = local_37[_e2200];
                                    let _e2214 = (_e2211 - _e2213);
                                    if (abs(_e2214) > 0.000061f) {
                                        let _e2218 = local_38[_e2202];
                                        let _e2219 = local_37[_e2200];
                                        let _e2220 = max(_e2218, _e2219);
                                        if (_e2220 != 0f) {
                                            phi_30266_ = (min(_e2218, _e2219) / _e2220);
                                        } else {
                                            phi_30266_ = 0f;
                                        }
                                        let _e2225 = phi_30266_;
                                        let _e2227 = (sign(_e2214) * (1f - _e2225));
                                        let _e2232 = local_38[_e2202];
                                        let _e2233 = local_37[_e2200];
                                        let _e2236 = (_e2202 + select(0i, 1i, (_e2232 < _e2233)));
                                        let _e2238 = local_38[_e2236];
                                        let _e2239 = local_37[_e2200];
                                        phi_30489_ = (_e2200 + select(0i, 1i, (_e2238 >= _e2239)));
                                        phi_30488_ = _e2236;
                                        phi_30397_ = select(_e2204, _e2227, (abs(_e2227) < abs(_e2204)));
                                    } else {
                                        phi_30489_ = _e2200;
                                        phi_30488_ = _e2202;
                                        phi_30397_ = 65504f;
                                    }
                                    let _e2244 = phi_30489_;
                                    let _e2246 = phi_30488_;
                                    let _e2248 = phi_30397_;
                                    local_198 = _e2244;
                                    local_199 = _e2246;
                                    local_200 = _e2248;
                                    continue;
                                } else {
                                    break;
                                }
                                continuing {
                                    let _e5351 = local_198;
                                    phi_30265_ = _e5351;
                                    let _e5354 = local_199;
                                    phi_30264_ = _e5354;
                                    let _e5357 = local_200;
                                    phi_29896_ = _e5357;
                                    phi_29895_ = (_e2206 + 1i);
                                }
                            }
                            let _e5365 = local_201;
                            phi_29897_ = _e5365;
                        }
                        let _e2251 = phi_29897_;
                        phi_29898_ = (_e2251 * select(0f, 1f, (_e2251 < 65503f)));
                    }
                    let _e2256 = phi_29898_;
                    let _e2261 = vec4<f32>(_e2256, vec4<f32>(0f, 0f, 0f, 0f).y, vec4<f32>(0f, 0f, 0f, 0f).z, vec4<f32>(0f, 0f, 0f, 0f).w);
                    if (_e2256 != 0f) {
                        phi_29905_ = sign(_e2256);
                    } else {
                        phi_29905_ = 0f;
                    }
                    let _e2265 = phi_29905_;
                    let _e2270 = vec4<f32>(_e2261.x, _e2265, _e2261.z, _e2261.w);
                    local_96[1i] = ((((vec4<f32>(_e1514.x, _e1514.y, 1f, _e1514.w) + vec4<f32>(_e1766.x, _e1766.y, 1f, _e1766.w)) + vec4<f32>(_e2018.x, _e2018.y, 1f, _e2018.w)) + vec4<f32>(_e2270.x, _e2270.y, 1f, _e2270.w)) * 0.25f);
                    let _e2281 = local_96[1i];
                    let _e2283 = textureDimensions(global_4);
                    if all((bitcast<vec2<u32>>(_e1264) < bitcast<vec2<u32>>(vec2<i32>(_e2283)))) {
                        textureStore(global_4, _e1264, vec4<f32>(_e2281.x, _e2281.y, 0f, 0f));
                    }
                    let _e2292 = bitcast<i32>((_e205 + 32u));
                    let _e2294 = (_e202 + vec2<i32>(_e204, _e2292));
                    let _e2296 = bitcast<i32>((_e199 + 16u));
                    let _e2298 = (_e210 + vec2<i32>(_e211, _e2296));
                    let _e2299 = bitcast<vec2<u32>>(_e2294);
                    let _e2304 = vec2<i32>(vec2<f32>(_e2294));
                    let _e2311 = vec2<i32>(max(0i, min(_e2304.x, _e224)), max(0i, min(_e2304.y, _e229)));
                    let _e2313 = textureDimensions(global_3, 0i);
                    if all((bitcast<vec2<u32>>(_e2311) < bitcast<vec2<u32>>(vec2<i32>(_e2313)))) {
                        let _e2318 = textureLoad(global_3, _e2311, 0i);
                        phi_29951_ = _e2318;
                    } else {
                        phi_29951_ = vec4<f32>(0f, 0f, 0f, 0f);
                    }
                    let _e2320 = phi_29951_;
                    let _e2324 = ((vec2<f32>(_e2311) + vec2<f32>(0.5f, 0.5f)) / _e246);
                    phi_29952_ = 0i;
                    loop {
                        let _e2330 = phi_29952_;
                        if (_e2330 < 5i) {
                            local_79 = array<vec2<i32>, 5>(vec2<i32>(0i, 0i), vec2<i32>(-1i, 0i), vec2<i32>(1i, 0i), vec2<i32>(0i, -1i), vec2<i32>(0i, 1i));
                            let _e2333 = local_79[_e2330];
                            let _e2334 = (vec2<i32>(floor(((_e2324 + _e250) * _e246))) + _e2333);
                            let _e2341 = vec2<i32>(max(0i, min(_e2334.x, _e224)), max(0i, min(_e2334.y, _e229)));
                            let _e2343 = textureDimensions(global_1, 0i);
                            if all((bitcast<vec2<u32>>(_e2341) < bitcast<vec2<u32>>(vec2<i32>(_e2343)))) {
                                let _e2348 = textureLoad(global_1, _e2341, 0i);
                                phi_30262_ = _e2348;
                            } else {
                                phi_30262_ = vec4<f32>(0f, 0f, 0f, 0f);
                            }
                            let _e2350 = phi_30262_;
                            let _e2353 = global.member_18;
                            local_42[_e2330] = (_e2350.x * select(_e2353, 1f, (_e2353 == 0f)));
                            let _e2358 = local_42[_e2330];
                            local_42[_e2330] = pow(_e2358, 1f);
                            let _e2360 = local_42[_e2330];
                            local_42[_e2330] = max(_e2360, 0.000061f);
                            continue;
                        } else {
                            break;
                        }
                        continuing {
                            phi_29952_ = (_e2330 + 1i);
                        }
                    }
                    let _e2363 = local_42;
                    let _e2365 = ((_e2324 + _e295) + _e2320.xy);
                    let _e2367 = (_e2365.x >= 0f);
                    phi_12873_ = _e2367;
                    if _e2367 {
                        phi_12873_ = (_e2365.x <= 1f);
                    }
                    let _e2370 = phi_12873_;
                    phi_12885_ = _e2370;
                    if _e2370 {
                        let _e2372 = (_e2365.y >= 0f);
                        phi_12883_ = _e2372;
                        if _e2372 {
                            phi_12883_ = (_e2365.y <= 1f);
                        }
                        let _e2375 = phi_12883_;
                        phi_12885_ = _e2375;
                    }
                    let _e2377 = phi_12885_;
                    if _e2377 {
                        phi_29953_ = 0i;
                        loop {
                            let _e2382 = phi_29953_;
                            if (_e2382 < 5i) {
                                local_78 = array<vec2<i32>, 5>(vec2<i32>(0i, 0i), vec2<i32>(-1i, 0i), vec2<i32>(1i, 0i), vec2<i32>(0i, -1i), vec2<i32>(0i, 1i));
                                let _e2385 = local_78[_e2382];
                                let _e2386 = (vec2<i32>(floor((_e2365 * _e294))) + _e2385);
                                let _e2397 = vec2<i32>(max(0i, min(_e2386.x, (_e293.x - 1i))), max(0i, min(_e2386.y, (_e293.y - 1i))));
                                let _e2399 = textureDimensions(global_2, 0i);
                                if all((bitcast<vec2<u32>>(_e2397) < bitcast<vec2<u32>>(vec2<i32>(_e2399)))) {
                                    let _e2404 = textureLoad(global_2, _e2397, 0i);
                                    phi_30260_ = _e2404;
                                } else {
                                    phi_30260_ = vec4<f32>(0f, 0f, 0f, 0f);
                                }
                                let _e2406 = phi_30260_;
                                let _e2409 = global.member_10;
                                let _e2412 = global.member_18;
                                local_8[_e2382] = ((_e2406.x * _e2409) * select(_e2412, 1f, (_e2412 == 0f)));
                                let _e2417 = local_8[_e2382];
                                local_8[_e2382] = pow(_e2417, 1f);
                                let _e2419 = local_8[_e2382];
                                local_8[_e2382] = max(_e2419, 0.000061f);
                                continue;
                            } else {
                                break;
                            }
                            continuing {
                                phi_29953_ = (_e2382 + 1i);
                            }
                        }
                    }
                    let _e2422 = local_8;
                    phi_29957_ = 0f;
                    if _e2377 {
                        let _e2428 = min(_e2363[0], _e2363[3]);
                        let _e2429 = max(_e2363[0], _e2363[3]);
                        let _e2430 = min(_e2363[1], _e2363[4]);
                        let _e2431 = max(_e2363[1], _e2363[4]);
                        let _e2432 = min(_e2428, _e2363[2]);
                        let _e2433 = max(_e2428, _e2363[2]);
                        let _e2434 = min(_e2430, _e2429);
                        let _e2435 = max(_e2430, _e2429);
                        let _e2437 = max(_e2432, _e2434);
                        let _e2438 = min(_e2433, _e2431);
                        let _e2439 = max(_e2433, _e2431);
                        let _e2441 = max(_e2437, _e2438);
                        let _e2442 = min(_e2435, _e2439);
                        local_41 = array<f32, 5>(min(_e2432, _e2434), min(_e2437, _e2438), min(_e2441, _e2442), max(_e2441, _e2442), max(_e2435, _e2439));
                        let _e2452 = min(_e2422[0], _e2422[3]);
                        let _e2453 = max(_e2422[0], _e2422[3]);
                        let _e2454 = min(_e2422[1], _e2422[4]);
                        let _e2455 = max(_e2422[1], _e2422[4]);
                        let _e2456 = min(_e2452, _e2422[2]);
                        let _e2457 = max(_e2452, _e2422[2]);
                        let _e2458 = min(_e2454, _e2453);
                        let _e2459 = max(_e2454, _e2453);
                        let _e2461 = max(_e2456, _e2458);
                        let _e2462 = min(_e2457, _e2455);
                        let _e2463 = max(_e2457, _e2455);
                        let _e2465 = max(_e2461, _e2462);
                        let _e2466 = min(_e2459, _e2463);
                        local_40 = array<f32, 5>(min(_e2456, _e2458), min(_e2461, _e2462), min(_e2465, _e2466), max(_e2465, _e2466), max(_e2459, _e2463));
                        let _e2472 = local_41[4i];
                        let _e2474 = local_40[4i];
                        phi_29956_ = 65503f;
                        if (min(_e2472, _e2474) > 0.000000000000000000000000000000000000011754944f) {
                            phi_30253_ = 0i;
                            phi_30252_ = 0i;
                            phi_29955_ = 65503f;
                            phi_29954_ = 0i;
                            loop {
                                let _e2478 = phi_30253_;
                                let _e2480 = phi_30252_;
                                let _e2482 = phi_29955_;
                                let _e2484 = phi_29954_;
                                local_205 = _e2482;
                                if ((_e2484 < 5i) && (_e2482 < 65504f)) {
                                    let _e2489 = local_41[_e2480];
                                    let _e2491 = local_40[_e2478];
                                    let _e2492 = (_e2489 - _e2491);
                                    if (abs(_e2492) > 0.000061f) {
                                        let _e2496 = local_41[_e2480];
                                        let _e2497 = local_40[_e2478];
                                        let _e2498 = max(_e2496, _e2497);
                                        if (_e2498 != 0f) {
                                            phi_30254_ = (min(_e2496, _e2497) / _e2498);
                                        } else {
                                            phi_30254_ = 0f;
                                        }
                                        let _e2503 = phi_30254_;
                                        let _e2505 = (sign(_e2492) * (1f - _e2503));
                                        let _e2510 = local_41[_e2480];
                                        let _e2511 = local_40[_e2478];
                                        let _e2514 = (_e2480 + select(0i, 1i, (_e2510 < _e2511)));
                                        let _e2516 = local_41[_e2514];
                                        let _e2517 = local_40[_e2478];
                                        phi_30487_ = (_e2478 + select(0i, 1i, (_e2516 >= _e2517)));
                                        phi_30486_ = _e2514;
                                        phi_30416_ = select(_e2482, _e2505, (abs(_e2505) < abs(_e2482)));
                                    } else {
                                        phi_30487_ = _e2478;
                                        phi_30486_ = _e2480;
                                        phi_30416_ = 65504f;
                                    }
                                    let _e2522 = phi_30487_;
                                    let _e2524 = phi_30486_;
                                    let _e2526 = phi_30416_;
                                    local_202 = _e2522;
                                    local_203 = _e2524;
                                    local_204 = _e2526;
                                    continue;
                                } else {
                                    break;
                                }
                                continuing {
                                    let _e5378 = local_202;
                                    phi_30253_ = _e5378;
                                    let _e5381 = local_203;
                                    phi_30252_ = _e5381;
                                    let _e5384 = local_204;
                                    phi_29955_ = _e5384;
                                    phi_29954_ = (_e2484 + 1i);
                                }
                            }
                            let _e5392 = local_205;
                            phi_29956_ = _e5392;
                        }
                        let _e2529 = phi_29956_;
                        phi_29957_ = (_e2529 * select(0f, 1f, (_e2529 < 65503f)));
                    }
                    let _e2534 = phi_29957_;
                    let _e2539 = vec4<f32>(_e2534, vec4<f32>(0f, 0f, 0f, 0f).y, vec4<f32>(0f, 0f, 0f, 0f).z, vec4<f32>(0f, 0f, 0f, 0f).w);
                    if (_e2534 != 0f) {
                        phi_29964_ = sign(_e2534);
                    } else {
                        phi_29964_ = 0f;
                    }
                    let _e2543 = phi_29964_;
                    let _e2548 = vec4<f32>(_e2539.x, _e2543, _e2539.z, _e2539.w);
                    let _e2556 = vec2<i32>(vec2<f32>(bitcast<vec2<i32>>((_e2299 + vec2<u32>(0u, 1u)))));
                    let _e2563 = vec2<i32>(max(0i, min(_e2556.x, _e224)), max(0i, min(_e2556.y, _e229)));
                    let _e2565 = textureDimensions(global_3, 0i);
                    if all((bitcast<vec2<u32>>(_e2563) < bitcast<vec2<u32>>(vec2<i32>(_e2565)))) {
                        let _e2570 = textureLoad(global_3, _e2563, 0i);
                        phi_29966_ = _e2570;
                    } else {
                        phi_29966_ = vec4<f32>(0f, 0f, 0f, 0f);
                    }
                    let _e2572 = phi_29966_;
                    let _e2576 = ((vec2<f32>(_e2563) + vec2<f32>(0.5f, 0.5f)) / _e246);
                    phi_29967_ = 0i;
                    loop {
                        let _e2582 = phi_29967_;
                        if (_e2582 < 5i) {
                            local_77 = array<vec2<i32>, 5>(vec2<i32>(0i, 0i), vec2<i32>(-1i, 0i), vec2<i32>(1i, 0i), vec2<i32>(0i, -1i), vec2<i32>(0i, 1i));
                            let _e2585 = local_77[_e2582];
                            let _e2586 = (vec2<i32>(floor(((_e2576 + _e250) * _e246))) + _e2585);
                            let _e2593 = vec2<i32>(max(0i, min(_e2586.x, _e224)), max(0i, min(_e2586.y, _e229)));
                            let _e2595 = textureDimensions(global_1, 0i);
                            if all((bitcast<vec2<u32>>(_e2593) < bitcast<vec2<u32>>(vec2<i32>(_e2595)))) {
                                let _e2600 = textureLoad(global_1, _e2593, 0i);
                                phi_30250_ = _e2600;
                            } else {
                                phi_30250_ = vec4<f32>(0f, 0f, 0f, 0f);
                            }
                            let _e2602 = phi_30250_;
                            let _e2605 = global.member_18;
                            local_45[_e2582] = (_e2602.x * select(_e2605, 1f, (_e2605 == 0f)));
                            let _e2610 = local_45[_e2582];
                            local_45[_e2582] = pow(_e2610, 1f);
                            let _e2612 = local_45[_e2582];
                            local_45[_e2582] = max(_e2612, 0.000061f);
                            continue;
                        } else {
                            break;
                        }
                        continuing {
                            phi_29967_ = (_e2582 + 1i);
                        }
                    }
                    let _e2615 = local_45;
                    let _e2617 = ((_e2576 + _e295) + _e2572.xy);
                    let _e2619 = (_e2617.x >= 0f);
                    phi_14029_ = _e2619;
                    if _e2619 {
                        phi_14029_ = (_e2617.x <= 1f);
                    }
                    let _e2622 = phi_14029_;
                    phi_14041_ = _e2622;
                    if _e2622 {
                        let _e2624 = (_e2617.y >= 0f);
                        phi_14039_ = _e2624;
                        if _e2624 {
                            phi_14039_ = (_e2617.y <= 1f);
                        }
                        let _e2627 = phi_14039_;
                        phi_14041_ = _e2627;
                    }
                    let _e2629 = phi_14041_;
                    if _e2629 {
                        phi_29968_ = 0i;
                        loop {
                            let _e2634 = phi_29968_;
                            if (_e2634 < 5i) {
                                local_76 = array<vec2<i32>, 5>(vec2<i32>(0i, 0i), vec2<i32>(-1i, 0i), vec2<i32>(1i, 0i), vec2<i32>(0i, -1i), vec2<i32>(0i, 1i));
                                let _e2637 = local_76[_e2634];
                                let _e2638 = (vec2<i32>(floor((_e2617 * _e294))) + _e2637);
                                let _e2649 = vec2<i32>(max(0i, min(_e2638.x, (_e293.x - 1i))), max(0i, min(_e2638.y, (_e293.y - 1i))));
                                let _e2651 = textureDimensions(global_2, 0i);
                                if all((bitcast<vec2<u32>>(_e2649) < bitcast<vec2<u32>>(vec2<i32>(_e2651)))) {
                                    let _e2656 = textureLoad(global_2, _e2649, 0i);
                                    phi_30248_ = _e2656;
                                } else {
                                    phi_30248_ = vec4<f32>(0f, 0f, 0f, 0f);
                                }
                                let _e2658 = phi_30248_;
                                let _e2661 = global.member_10;
                                let _e2664 = global.member_18;
                                local_9[_e2634] = ((_e2658.x * _e2661) * select(_e2664, 1f, (_e2664 == 0f)));
                                let _e2669 = local_9[_e2634];
                                local_9[_e2634] = pow(_e2669, 1f);
                                let _e2671 = local_9[_e2634];
                                local_9[_e2634] = max(_e2671, 0.000061f);
                                continue;
                            } else {
                                break;
                            }
                            continuing {
                                phi_29968_ = (_e2634 + 1i);
                            }
                        }
                    }
                    let _e2674 = local_9;
                    phi_29972_ = 0f;
                    if _e2629 {
                        let _e2680 = min(_e2615[0], _e2615[3]);
                        let _e2681 = max(_e2615[0], _e2615[3]);
                        let _e2682 = min(_e2615[1], _e2615[4]);
                        let _e2683 = max(_e2615[1], _e2615[4]);
                        let _e2684 = min(_e2680, _e2615[2]);
                        let _e2685 = max(_e2680, _e2615[2]);
                        let _e2686 = min(_e2682, _e2681);
                        let _e2687 = max(_e2682, _e2681);
                        let _e2689 = max(_e2684, _e2686);
                        let _e2690 = min(_e2685, _e2683);
                        let _e2691 = max(_e2685, _e2683);
                        let _e2693 = max(_e2689, _e2690);
                        let _e2694 = min(_e2687, _e2691);
                        local_44 = array<f32, 5>(min(_e2684, _e2686), min(_e2689, _e2690), min(_e2693, _e2694), max(_e2693, _e2694), max(_e2687, _e2691));
                        let _e2704 = min(_e2674[0], _e2674[3]);
                        let _e2705 = max(_e2674[0], _e2674[3]);
                        let _e2706 = min(_e2674[1], _e2674[4]);
                        let _e2707 = max(_e2674[1], _e2674[4]);
                        let _e2708 = min(_e2704, _e2674[2]);
                        let _e2709 = max(_e2704, _e2674[2]);
                        let _e2710 = min(_e2706, _e2705);
                        let _e2711 = max(_e2706, _e2705);
                        let _e2713 = max(_e2708, _e2710);
                        let _e2714 = min(_e2709, _e2707);
                        let _e2715 = max(_e2709, _e2707);
                        let _e2717 = max(_e2713, _e2714);
                        let _e2718 = min(_e2711, _e2715);
                        local_43 = array<f32, 5>(min(_e2708, _e2710), min(_e2713, _e2714), min(_e2717, _e2718), max(_e2717, _e2718), max(_e2711, _e2715));
                        let _e2724 = local_44[4i];
                        let _e2726 = local_43[4i];
                        phi_29971_ = 65503f;
                        if (min(_e2724, _e2726) > 0.000000000000000000000000000000000000011754944f) {
                            phi_30241_ = 0i;
                            phi_30240_ = 0i;
                            phi_29970_ = 65503f;
                            phi_29969_ = 0i;
                            loop {
                                let _e2730 = phi_30241_;
                                let _e2732 = phi_30240_;
                                let _e2734 = phi_29970_;
                                let _e2736 = phi_29969_;
                                local_209 = _e2734;
                                if ((_e2736 < 5i) && (_e2734 < 65504f)) {
                                    let _e2741 = local_44[_e2732];
                                    let _e2743 = local_43[_e2730];
                                    let _e2744 = (_e2741 - _e2743);
                                    if (abs(_e2744) > 0.000061f) {
                                        let _e2748 = local_44[_e2732];
                                        let _e2749 = local_43[_e2730];
                                        let _e2750 = max(_e2748, _e2749);
                                        if (_e2750 != 0f) {
                                            phi_30242_ = (min(_e2748, _e2749) / _e2750);
                                        } else {
                                            phi_30242_ = 0f;
                                        }
                                        let _e2755 = phi_30242_;
                                        let _e2757 = (sign(_e2744) * (1f - _e2755));
                                        let _e2762 = local_44[_e2732];
                                        let _e2763 = local_43[_e2730];
                                        let _e2766 = (_e2732 + select(0i, 1i, (_e2762 < _e2763)));
                                        let _e2768 = local_44[_e2766];
                                        let _e2769 = local_43[_e2730];
                                        phi_30485_ = (_e2730 + select(0i, 1i, (_e2768 >= _e2769)));
                                        phi_30484_ = _e2766;
                                        phi_30419_ = select(_e2734, _e2757, (abs(_e2757) < abs(_e2734)));
                                    } else {
                                        phi_30485_ = _e2730;
                                        phi_30484_ = _e2732;
                                        phi_30419_ = 65504f;
                                    }
                                    let _e2774 = phi_30485_;
                                    let _e2776 = phi_30484_;
                                    let _e2778 = phi_30419_;
                                    local_206 = _e2774;
                                    local_207 = _e2776;
                                    local_208 = _e2778;
                                    continue;
                                } else {
                                    break;
                                }
                                continuing {
                                    let _e5405 = local_206;
                                    phi_30241_ = _e5405;
                                    let _e5408 = local_207;
                                    phi_30240_ = _e5408;
                                    let _e5411 = local_208;
                                    phi_29970_ = _e5411;
                                    phi_29969_ = (_e2736 + 1i);
                                }
                            }
                            let _e5419 = local_209;
                            phi_29971_ = _e5419;
                        }
                        let _e2781 = phi_29971_;
                        phi_29972_ = (_e2781 * select(0f, 1f, (_e2781 < 65503f)));
                    }
                    let _e2786 = phi_29972_;
                    let _e2791 = vec4<f32>(_e2786, vec4<f32>(0f, 0f, 0f, 0f).y, vec4<f32>(0f, 0f, 0f, 0f).z, vec4<f32>(0f, 0f, 0f, 0f).w);
                    if (_e2786 != 0f) {
                        phi_29979_ = sign(_e2786);
                    } else {
                        phi_29979_ = 0f;
                    }
                    let _e2795 = phi_29979_;
                    let _e2800 = vec4<f32>(_e2791.x, _e2795, _e2791.z, _e2791.w);
                    let _e2808 = vec2<i32>(vec2<f32>(bitcast<vec2<i32>>((_e2299 + vec2<u32>(1u, 0u)))));
                    let _e2815 = vec2<i32>(max(0i, min(_e2808.x, _e224)), max(0i, min(_e2808.y, _e229)));
                    let _e2817 = textureDimensions(global_3, 0i);
                    if all((bitcast<vec2<u32>>(_e2815) < bitcast<vec2<u32>>(vec2<i32>(_e2817)))) {
                        let _e2822 = textureLoad(global_3, _e2815, 0i);
                        phi_29981_ = _e2822;
                    } else {
                        phi_29981_ = vec4<f32>(0f, 0f, 0f, 0f);
                    }
                    let _e2824 = phi_29981_;
                    let _e2828 = ((vec2<f32>(_e2815) + vec2<f32>(0.5f, 0.5f)) / _e246);
                    phi_29982_ = 0i;
                    loop {
                        let _e2834 = phi_29982_;
                        if (_e2834 < 5i) {
                            local_75 = array<vec2<i32>, 5>(vec2<i32>(0i, 0i), vec2<i32>(-1i, 0i), vec2<i32>(1i, 0i), vec2<i32>(0i, -1i), vec2<i32>(0i, 1i));
                            let _e2837 = local_75[_e2834];
                            let _e2838 = (vec2<i32>(floor(((_e2828 + _e250) * _e246))) + _e2837);
                            let _e2845 = vec2<i32>(max(0i, min(_e2838.x, _e224)), max(0i, min(_e2838.y, _e229)));
                            let _e2847 = textureDimensions(global_1, 0i);
                            if all((bitcast<vec2<u32>>(_e2845) < bitcast<vec2<u32>>(vec2<i32>(_e2847)))) {
                                let _e2852 = textureLoad(global_1, _e2845, 0i);
                                phi_30238_ = _e2852;
                            } else {
                                phi_30238_ = vec4<f32>(0f, 0f, 0f, 0f);
                            }
                            let _e2854 = phi_30238_;
                            let _e2857 = global.member_18;
                            local_48[_e2834] = (_e2854.x * select(_e2857, 1f, (_e2857 == 0f)));
                            let _e2862 = local_48[_e2834];
                            local_48[_e2834] = pow(_e2862, 1f);
                            let _e2864 = local_48[_e2834];
                            local_48[_e2834] = max(_e2864, 0.000061f);
                            continue;
                        } else {
                            break;
                        }
                        continuing {
                            phi_29982_ = (_e2834 + 1i);
                        }
                    }
                    let _e2867 = local_48;
                    let _e2869 = ((_e2828 + _e295) + _e2824.xy);
                    let _e2871 = (_e2869.x >= 0f);
                    phi_15185_ = _e2871;
                    if _e2871 {
                        phi_15185_ = (_e2869.x <= 1f);
                    }
                    let _e2874 = phi_15185_;
                    phi_15197_ = _e2874;
                    if _e2874 {
                        let _e2876 = (_e2869.y >= 0f);
                        phi_15195_ = _e2876;
                        if _e2876 {
                            phi_15195_ = (_e2869.y <= 1f);
                        }
                        let _e2879 = phi_15195_;
                        phi_15197_ = _e2879;
                    }
                    let _e2881 = phi_15197_;
                    if _e2881 {
                        phi_29983_ = 0i;
                        loop {
                            let _e2886 = phi_29983_;
                            if (_e2886 < 5i) {
                                local_74 = array<vec2<i32>, 5>(vec2<i32>(0i, 0i), vec2<i32>(-1i, 0i), vec2<i32>(1i, 0i), vec2<i32>(0i, -1i), vec2<i32>(0i, 1i));
                                let _e2889 = local_74[_e2886];
                                let _e2890 = (vec2<i32>(floor((_e2869 * _e294))) + _e2889);
                                let _e2901 = vec2<i32>(max(0i, min(_e2890.x, (_e293.x - 1i))), max(0i, min(_e2890.y, (_e293.y - 1i))));
                                let _e2903 = textureDimensions(global_2, 0i);
                                if all((bitcast<vec2<u32>>(_e2901) < bitcast<vec2<u32>>(vec2<i32>(_e2903)))) {
                                    let _e2908 = textureLoad(global_2, _e2901, 0i);
                                    phi_30236_ = _e2908;
                                } else {
                                    phi_30236_ = vec4<f32>(0f, 0f, 0f, 0f);
                                }
                                let _e2910 = phi_30236_;
                                let _e2913 = global.member_10;
                                let _e2916 = global.member_18;
                                local_10[_e2886] = ((_e2910.x * _e2913) * select(_e2916, 1f, (_e2916 == 0f)));
                                let _e2921 = local_10[_e2886];
                                local_10[_e2886] = pow(_e2921, 1f);
                                let _e2923 = local_10[_e2886];
                                local_10[_e2886] = max(_e2923, 0.000061f);
                                continue;
                            } else {
                                break;
                            }
                            continuing {
                                phi_29983_ = (_e2886 + 1i);
                            }
                        }
                    }
                    let _e2926 = local_10;
                    phi_29987_ = 0f;
                    if _e2881 {
                        let _e2932 = min(_e2867[0], _e2867[3]);
                        let _e2933 = max(_e2867[0], _e2867[3]);
                        let _e2934 = min(_e2867[1], _e2867[4]);
                        let _e2935 = max(_e2867[1], _e2867[4]);
                        let _e2936 = min(_e2932, _e2867[2]);
                        let _e2937 = max(_e2932, _e2867[2]);
                        let _e2938 = min(_e2934, _e2933);
                        let _e2939 = max(_e2934, _e2933);
                        let _e2941 = max(_e2936, _e2938);
                        let _e2942 = min(_e2937, _e2935);
                        let _e2943 = max(_e2937, _e2935);
                        let _e2945 = max(_e2941, _e2942);
                        let _e2946 = min(_e2939, _e2943);
                        local_47 = array<f32, 5>(min(_e2936, _e2938), min(_e2941, _e2942), min(_e2945, _e2946), max(_e2945, _e2946), max(_e2939, _e2943));
                        let _e2956 = min(_e2926[0], _e2926[3]);
                        let _e2957 = max(_e2926[0], _e2926[3]);
                        let _e2958 = min(_e2926[1], _e2926[4]);
                        let _e2959 = max(_e2926[1], _e2926[4]);
                        let _e2960 = min(_e2956, _e2926[2]);
                        let _e2961 = max(_e2956, _e2926[2]);
                        let _e2962 = min(_e2958, _e2957);
                        let _e2963 = max(_e2958, _e2957);
                        let _e2965 = max(_e2960, _e2962);
                        let _e2966 = min(_e2961, _e2959);
                        let _e2967 = max(_e2961, _e2959);
                        let _e2969 = max(_e2965, _e2966);
                        let _e2970 = min(_e2963, _e2967);
                        local_46 = array<f32, 5>(min(_e2960, _e2962), min(_e2965, _e2966), min(_e2969, _e2970), max(_e2969, _e2970), max(_e2963, _e2967));
                        let _e2976 = local_47[4i];
                        let _e2978 = local_46[4i];
                        phi_29986_ = 65503f;
                        if (min(_e2976, _e2978) > 0.000000000000000000000000000000000000011754944f) {
                            phi_30229_ = 0i;
                            phi_30228_ = 0i;
                            phi_29985_ = 65503f;
                            phi_29984_ = 0i;
                            loop {
                                let _e2982 = phi_30229_;
                                let _e2984 = phi_30228_;
                                let _e2986 = phi_29985_;
                                let _e2988 = phi_29984_;
                                local_213 = _e2986;
                                if ((_e2988 < 5i) && (_e2986 < 65504f)) {
                                    let _e2993 = local_47[_e2984];
                                    let _e2995 = local_46[_e2982];
                                    let _e2996 = (_e2993 - _e2995);
                                    if (abs(_e2996) > 0.000061f) {
                                        let _e3000 = local_47[_e2984];
                                        let _e3001 = local_46[_e2982];
                                        let _e3002 = max(_e3000, _e3001);
                                        if (_e3002 != 0f) {
                                            phi_30230_ = (min(_e3000, _e3001) / _e3002);
                                        } else {
                                            phi_30230_ = 0f;
                                        }
                                        let _e3007 = phi_30230_;
                                        let _e3009 = (sign(_e2996) * (1f - _e3007));
                                        let _e3014 = local_47[_e2984];
                                        let _e3015 = local_46[_e2982];
                                        let _e3018 = (_e2984 + select(0i, 1i, (_e3014 < _e3015)));
                                        let _e3020 = local_47[_e3018];
                                        let _e3021 = local_46[_e2982];
                                        phi_30483_ = (_e2982 + select(0i, 1i, (_e3020 >= _e3021)));
                                        phi_30482_ = _e3018;
                                        phi_30422_ = select(_e2986, _e3009, (abs(_e3009) < abs(_e2986)));
                                    } else {
                                        phi_30483_ = _e2982;
                                        phi_30482_ = _e2984;
                                        phi_30422_ = 65504f;
                                    }
                                    let _e3026 = phi_30483_;
                                    let _e3028 = phi_30482_;
                                    let _e3030 = phi_30422_;
                                    local_210 = _e3026;
                                    local_211 = _e3028;
                                    local_212 = _e3030;
                                    continue;
                                } else {
                                    break;
                                }
                                continuing {
                                    let _e5432 = local_210;
                                    phi_30229_ = _e5432;
                                    let _e5435 = local_211;
                                    phi_30228_ = _e5435;
                                    let _e5438 = local_212;
                                    phi_29985_ = _e5438;
                                    phi_29984_ = (_e2988 + 1i);
                                }
                            }
                            let _e5446 = local_213;
                            phi_29986_ = _e5446;
                        }
                        let _e3033 = phi_29986_;
                        phi_29987_ = (_e3033 * select(0f, 1f, (_e3033 < 65503f)));
                    }
                    let _e3038 = phi_29987_;
                    let _e3043 = vec4<f32>(_e3038, vec4<f32>(0f, 0f, 0f, 0f).y, vec4<f32>(0f, 0f, 0f, 0f).z, vec4<f32>(0f, 0f, 0f, 0f).w);
                    if (_e3038 != 0f) {
                        phi_29994_ = sign(_e3038);
                    } else {
                        phi_29994_ = 0f;
                    }
                    let _e3047 = phi_29994_;
                    let _e3052 = vec4<f32>(_e3043.x, _e3047, _e3043.z, _e3043.w);
                    let _e3060 = vec2<i32>(vec2<f32>(bitcast<vec2<i32>>((_e2299 + vec2<u32>(1u, 1u)))));
                    let _e3067 = vec2<i32>(max(0i, min(_e3060.x, _e224)), max(0i, min(_e3060.y, _e229)));
                    let _e3069 = textureDimensions(global_3, 0i);
                    if all((bitcast<vec2<u32>>(_e3067) < bitcast<vec2<u32>>(vec2<i32>(_e3069)))) {
                        let _e3074 = textureLoad(global_3, _e3067, 0i);
                        phi_29996_ = _e3074;
                    } else {
                        phi_29996_ = vec4<f32>(0f, 0f, 0f, 0f);
                    }
                    let _e3076 = phi_29996_;
                    let _e3080 = ((vec2<f32>(_e3067) + vec2<f32>(0.5f, 0.5f)) / _e246);
                    phi_29997_ = 0i;
                    loop {
                        let _e3086 = phi_29997_;
                        if (_e3086 < 5i) {
                            local_73 = array<vec2<i32>, 5>(vec2<i32>(0i, 0i), vec2<i32>(-1i, 0i), vec2<i32>(1i, 0i), vec2<i32>(0i, -1i), vec2<i32>(0i, 1i));
                            let _e3089 = local_73[_e3086];
                            let _e3090 = (vec2<i32>(floor(((_e3080 + _e250) * _e246))) + _e3089);
                            let _e3097 = vec2<i32>(max(0i, min(_e3090.x, _e224)), max(0i, min(_e3090.y, _e229)));
                            let _e3099 = textureDimensions(global_1, 0i);
                            if all((bitcast<vec2<u32>>(_e3097) < bitcast<vec2<u32>>(vec2<i32>(_e3099)))) {
                                let _e3104 = textureLoad(global_1, _e3097, 0i);
                                phi_30226_ = _e3104;
                            } else {
                                phi_30226_ = vec4<f32>(0f, 0f, 0f, 0f);
                            }
                            let _e3106 = phi_30226_;
                            let _e3109 = global.member_18;
                            local_51[_e3086] = (_e3106.x * select(_e3109, 1f, (_e3109 == 0f)));
                            let _e3114 = local_51[_e3086];
                            local_51[_e3086] = pow(_e3114, 1f);
                            let _e3116 = local_51[_e3086];
                            local_51[_e3086] = max(_e3116, 0.000061f);
                            continue;
                        } else {
                            break;
                        }
                        continuing {
                            phi_29997_ = (_e3086 + 1i);
                        }
                    }
                    let _e3119 = local_51;
                    let _e3121 = ((_e3080 + _e295) + _e3076.xy);
                    let _e3123 = (_e3121.x >= 0f);
                    phi_16341_ = _e3123;
                    if _e3123 {
                        phi_16341_ = (_e3121.x <= 1f);
                    }
                    let _e3126 = phi_16341_;
                    phi_16353_ = _e3126;
                    if _e3126 {
                        let _e3128 = (_e3121.y >= 0f);
                        phi_16351_ = _e3128;
                        if _e3128 {
                            phi_16351_ = (_e3121.y <= 1f);
                        }
                        let _e3131 = phi_16351_;
                        phi_16353_ = _e3131;
                    }
                    let _e3133 = phi_16353_;
                    if _e3133 {
                        phi_29998_ = 0i;
                        loop {
                            let _e3138 = phi_29998_;
                            if (_e3138 < 5i) {
                                local_72 = array<vec2<i32>, 5>(vec2<i32>(0i, 0i), vec2<i32>(-1i, 0i), vec2<i32>(1i, 0i), vec2<i32>(0i, -1i), vec2<i32>(0i, 1i));
                                let _e3141 = local_72[_e3138];
                                let _e3142 = (vec2<i32>(floor((_e3121 * _e294))) + _e3141);
                                let _e3153 = vec2<i32>(max(0i, min(_e3142.x, (_e293.x - 1i))), max(0i, min(_e3142.y, (_e293.y - 1i))));
                                let _e3155 = textureDimensions(global_2, 0i);
                                if all((bitcast<vec2<u32>>(_e3153) < bitcast<vec2<u32>>(vec2<i32>(_e3155)))) {
                                    let _e3160 = textureLoad(global_2, _e3153, 0i);
                                    phi_30224_ = _e3160;
                                } else {
                                    phi_30224_ = vec4<f32>(0f, 0f, 0f, 0f);
                                }
                                let _e3162 = phi_30224_;
                                let _e3165 = global.member_10;
                                let _e3168 = global.member_18;
                                local_11[_e3138] = ((_e3162.x * _e3165) * select(_e3168, 1f, (_e3168 == 0f)));
                                let _e3173 = local_11[_e3138];
                                local_11[_e3138] = pow(_e3173, 1f);
                                let _e3175 = local_11[_e3138];
                                local_11[_e3138] = max(_e3175, 0.000061f);
                                continue;
                            } else {
                                break;
                            }
                            continuing {
                                phi_29998_ = (_e3138 + 1i);
                            }
                        }
                    }
                    let _e3178 = local_11;
                    phi_30002_ = 0f;
                    if _e3133 {
                        let _e3184 = min(_e3119[0], _e3119[3]);
                        let _e3185 = max(_e3119[0], _e3119[3]);
                        let _e3186 = min(_e3119[1], _e3119[4]);
                        let _e3187 = max(_e3119[1], _e3119[4]);
                        let _e3188 = min(_e3184, _e3119[2]);
                        let _e3189 = max(_e3184, _e3119[2]);
                        let _e3190 = min(_e3186, _e3185);
                        let _e3191 = max(_e3186, _e3185);
                        let _e3193 = max(_e3188, _e3190);
                        let _e3194 = min(_e3189, _e3187);
                        let _e3195 = max(_e3189, _e3187);
                        let _e3197 = max(_e3193, _e3194);
                        let _e3198 = min(_e3191, _e3195);
                        local_50 = array<f32, 5>(min(_e3188, _e3190), min(_e3193, _e3194), min(_e3197, _e3198), max(_e3197, _e3198), max(_e3191, _e3195));
                        let _e3208 = min(_e3178[0], _e3178[3]);
                        let _e3209 = max(_e3178[0], _e3178[3]);
                        let _e3210 = min(_e3178[1], _e3178[4]);
                        let _e3211 = max(_e3178[1], _e3178[4]);
                        let _e3212 = min(_e3208, _e3178[2]);
                        let _e3213 = max(_e3208, _e3178[2]);
                        let _e3214 = min(_e3210, _e3209);
                        let _e3215 = max(_e3210, _e3209);
                        let _e3217 = max(_e3212, _e3214);
                        let _e3218 = min(_e3213, _e3211);
                        let _e3219 = max(_e3213, _e3211);
                        let _e3221 = max(_e3217, _e3218);
                        let _e3222 = min(_e3215, _e3219);
                        local_49 = array<f32, 5>(min(_e3212, _e3214), min(_e3217, _e3218), min(_e3221, _e3222), max(_e3221, _e3222), max(_e3215, _e3219));
                        let _e3228 = local_50[4i];
                        let _e3230 = local_49[4i];
                        phi_30001_ = 65503f;
                        if (min(_e3228, _e3230) > 0.000000000000000000000000000000000000011754944f) {
                            phi_30217_ = 0i;
                            phi_30216_ = 0i;
                            phi_30000_ = 65503f;
                            phi_29999_ = 0i;
                            loop {
                                let _e3234 = phi_30217_;
                                let _e3236 = phi_30216_;
                                let _e3238 = phi_30000_;
                                let _e3240 = phi_29999_;
                                local_217 = _e3238;
                                if ((_e3240 < 5i) && (_e3238 < 65504f)) {
                                    let _e3245 = local_50[_e3236];
                                    let _e3247 = local_49[_e3234];
                                    let _e3248 = (_e3245 - _e3247);
                                    if (abs(_e3248) > 0.000061f) {
                                        let _e3252 = local_50[_e3236];
                                        let _e3253 = local_49[_e3234];
                                        let _e3254 = max(_e3252, _e3253);
                                        if (_e3254 != 0f) {
                                            phi_30218_ = (min(_e3252, _e3253) / _e3254);
                                        } else {
                                            phi_30218_ = 0f;
                                        }
                                        let _e3259 = phi_30218_;
                                        let _e3261 = (sign(_e3248) * (1f - _e3259));
                                        let _e3266 = local_50[_e3236];
                                        let _e3267 = local_49[_e3234];
                                        let _e3270 = (_e3236 + select(0i, 1i, (_e3266 < _e3267)));
                                        let _e3272 = local_50[_e3270];
                                        let _e3273 = local_49[_e3234];
                                        phi_30481_ = (_e3234 + select(0i, 1i, (_e3272 >= _e3273)));
                                        phi_30480_ = _e3270;
                                        phi_30425_ = select(_e3238, _e3261, (abs(_e3261) < abs(_e3238)));
                                    } else {
                                        phi_30481_ = _e3234;
                                        phi_30480_ = _e3236;
                                        phi_30425_ = 65504f;
                                    }
                                    let _e3278 = phi_30481_;
                                    let _e3280 = phi_30480_;
                                    let _e3282 = phi_30425_;
                                    local_214 = _e3278;
                                    local_215 = _e3280;
                                    local_216 = _e3282;
                                    continue;
                                } else {
                                    break;
                                }
                                continuing {
                                    let _e5459 = local_214;
                                    phi_30217_ = _e5459;
                                    let _e5462 = local_215;
                                    phi_30216_ = _e5462;
                                    let _e5465 = local_216;
                                    phi_30000_ = _e5465;
                                    phi_29999_ = (_e3240 + 1i);
                                }
                            }
                            let _e5473 = local_217;
                            phi_30001_ = _e5473;
                        }
                        let _e3285 = phi_30001_;
                        phi_30002_ = (_e3285 * select(0f, 1f, (_e3285 < 65503f)));
                    }
                    let _e3290 = phi_30002_;
                    let _e3295 = vec4<f32>(_e3290, vec4<f32>(0f, 0f, 0f, 0f).y, vec4<f32>(0f, 0f, 0f, 0f).z, vec4<f32>(0f, 0f, 0f, 0f).w);
                    if (_e3290 != 0f) {
                        phi_30009_ = sign(_e3290);
                    } else {
                        phi_30009_ = 0f;
                    }
                    let _e3299 = phi_30009_;
                    let _e3304 = vec4<f32>(_e3295.x, _e3299, _e3295.z, _e3295.w);
                    local_96[2i] = ((((vec4<f32>(_e2548.x, _e2548.y, 1f, _e2548.w) + vec4<f32>(_e2800.x, _e2800.y, 1f, _e2800.w)) + vec4<f32>(_e3052.x, _e3052.y, 1f, _e3052.w)) + vec4<f32>(_e3304.x, _e3304.y, 1f, _e3304.w)) * 0.25f);
                    let _e3315 = local_96[2i];
                    let _e3317 = textureDimensions(global_4);
                    if all((bitcast<vec2<u32>>(_e2298) < bitcast<vec2<u32>>(vec2<i32>(_e3317)))) {
                        textureStore(global_4, _e2298, vec4<f32>(_e3315.x, _e3315.y, 0f, 0f));
                    }
                    let _e3326 = (_e202 + vec2<i32>(_e1258, _e2292));
                    let _e3328 = (_e210 + vec2<i32>(_e1262, _e2296));
                    let _e3329 = bitcast<vec2<u32>>(_e3326);
                    let _e3334 = vec2<i32>(vec2<f32>(_e3326));
                    let _e3341 = vec2<i32>(max(0i, min(_e3334.x, _e224)), max(0i, min(_e3334.y, _e229)));
                    let _e3343 = textureDimensions(global_3, 0i);
                    if all((bitcast<vec2<u32>>(_e3341) < bitcast<vec2<u32>>(vec2<i32>(_e3343)))) {
                        let _e3348 = textureLoad(global_3, _e3341, 0i);
                        phi_30055_ = _e3348;
                    } else {
                        phi_30055_ = vec4<f32>(0f, 0f, 0f, 0f);
                    }
                    let _e3350 = phi_30055_;
                    let _e3354 = ((vec2<f32>(_e3341) + vec2<f32>(0.5f, 0.5f)) / _e246);
                    phi_30056_ = 0i;
                    loop {
                        let _e3360 = phi_30056_;
                        if (_e3360 < 5i) {
                            local_71 = array<vec2<i32>, 5>(vec2<i32>(0i, 0i), vec2<i32>(-1i, 0i), vec2<i32>(1i, 0i), vec2<i32>(0i, -1i), vec2<i32>(0i, 1i));
                            let _e3363 = local_71[_e3360];
                            let _e3364 = (vec2<i32>(floor(((_e3354 + _e250) * _e246))) + _e3363);
                            let _e3371 = vec2<i32>(max(0i, min(_e3364.x, _e224)), max(0i, min(_e3364.y, _e229)));
                            let _e3373 = textureDimensions(global_1, 0i);
                            if all((bitcast<vec2<u32>>(_e3371) < bitcast<vec2<u32>>(vec2<i32>(_e3373)))) {
                                let _e3378 = textureLoad(global_1, _e3371, 0i);
                                phi_30214_ = _e3378;
                            } else {
                                phi_30214_ = vec4<f32>(0f, 0f, 0f, 0f);
                            }
                            let _e3380 = phi_30214_;
                            let _e3383 = global.member_18;
                            local_54[_e3360] = (_e3380.x * select(_e3383, 1f, (_e3383 == 0f)));
                            let _e3388 = local_54[_e3360];
                            local_54[_e3360] = pow(_e3388, 1f);
                            let _e3390 = local_54[_e3360];
                            local_54[_e3360] = max(_e3390, 0.000061f);
                            continue;
                        } else {
                            break;
                        }
                        continuing {
                            phi_30056_ = (_e3360 + 1i);
                        }
                    }
                    let _e3393 = local_54;
                    let _e3395 = ((_e3354 + _e295) + _e3350.xy);
                    let _e3397 = (_e3395.x >= 0f);
                    phi_17638_ = _e3397;
                    if _e3397 {
                        phi_17638_ = (_e3395.x <= 1f);
                    }
                    let _e3400 = phi_17638_;
                    phi_17650_ = _e3400;
                    if _e3400 {
                        let _e3402 = (_e3395.y >= 0f);
                        phi_17648_ = _e3402;
                        if _e3402 {
                            phi_17648_ = (_e3395.y <= 1f);
                        }
                        let _e3405 = phi_17648_;
                        phi_17650_ = _e3405;
                    }
                    let _e3407 = phi_17650_;
                    if _e3407 {
                        phi_30057_ = 0i;
                        loop {
                            let _e3412 = phi_30057_;
                            if (_e3412 < 5i) {
                                local_70 = array<vec2<i32>, 5>(vec2<i32>(0i, 0i), vec2<i32>(-1i, 0i), vec2<i32>(1i, 0i), vec2<i32>(0i, -1i), vec2<i32>(0i, 1i));
                                let _e3415 = local_70[_e3412];
                                let _e3416 = (vec2<i32>(floor((_e3395 * _e294))) + _e3415);
                                let _e3427 = vec2<i32>(max(0i, min(_e3416.x, (_e293.x - 1i))), max(0i, min(_e3416.y, (_e293.y - 1i))));
                                let _e3429 = textureDimensions(global_2, 0i);
                                if all((bitcast<vec2<u32>>(_e3427) < bitcast<vec2<u32>>(vec2<i32>(_e3429)))) {
                                    let _e3434 = textureLoad(global_2, _e3427, 0i);
                                    phi_30212_ = _e3434;
                                } else {
                                    phi_30212_ = vec4<f32>(0f, 0f, 0f, 0f);
                                }
                                let _e3436 = phi_30212_;
                                let _e3439 = global.member_10;
                                let _e3442 = global.member_18;
                                local_12[_e3412] = ((_e3436.x * _e3439) * select(_e3442, 1f, (_e3442 == 0f)));
                                let _e3447 = local_12[_e3412];
                                local_12[_e3412] = pow(_e3447, 1f);
                                let _e3449 = local_12[_e3412];
                                local_12[_e3412] = max(_e3449, 0.000061f);
                                continue;
                            } else {
                                break;
                            }
                            continuing {
                                phi_30057_ = (_e3412 + 1i);
                            }
                        }
                    }
                    let _e3452 = local_12;
                    phi_30061_ = 0f;
                    if _e3407 {
                        let _e3458 = min(_e3393[0], _e3393[3]);
                        let _e3459 = max(_e3393[0], _e3393[3]);
                        let _e3460 = min(_e3393[1], _e3393[4]);
                        let _e3461 = max(_e3393[1], _e3393[4]);
                        let _e3462 = min(_e3458, _e3393[2]);
                        let _e3463 = max(_e3458, _e3393[2]);
                        let _e3464 = min(_e3460, _e3459);
                        let _e3465 = max(_e3460, _e3459);
                        let _e3467 = max(_e3462, _e3464);
                        let _e3468 = min(_e3463, _e3461);
                        let _e3469 = max(_e3463, _e3461);
                        let _e3471 = max(_e3467, _e3468);
                        let _e3472 = min(_e3465, _e3469);
                        local_53 = array<f32, 5>(min(_e3462, _e3464), min(_e3467, _e3468), min(_e3471, _e3472), max(_e3471, _e3472), max(_e3465, _e3469));
                        let _e3482 = min(_e3452[0], _e3452[3]);
                        let _e3483 = max(_e3452[0], _e3452[3]);
                        let _e3484 = min(_e3452[1], _e3452[4]);
                        let _e3485 = max(_e3452[1], _e3452[4]);
                        let _e3486 = min(_e3482, _e3452[2]);
                        let _e3487 = max(_e3482, _e3452[2]);
                        let _e3488 = min(_e3484, _e3483);
                        let _e3489 = max(_e3484, _e3483);
                        let _e3491 = max(_e3486, _e3488);
                        let _e3492 = min(_e3487, _e3485);
                        let _e3493 = max(_e3487, _e3485);
                        let _e3495 = max(_e3491, _e3492);
                        let _e3496 = min(_e3489, _e3493);
                        local_52 = array<f32, 5>(min(_e3486, _e3488), min(_e3491, _e3492), min(_e3495, _e3496), max(_e3495, _e3496), max(_e3489, _e3493));
                        let _e3502 = local_53[4i];
                        let _e3504 = local_52[4i];
                        phi_30060_ = 65503f;
                        if (min(_e3502, _e3504) > 0.000000000000000000000000000000000000011754944f) {
                            phi_30205_ = 0i;
                            phi_30204_ = 0i;
                            phi_30059_ = 65503f;
                            phi_30058_ = 0i;
                            loop {
                                let _e3508 = phi_30205_;
                                let _e3510 = phi_30204_;
                                let _e3512 = phi_30059_;
                                let _e3514 = phi_30058_;
                                local_221 = _e3512;
                                if ((_e3514 < 5i) && (_e3512 < 65504f)) {
                                    let _e3519 = local_53[_e3510];
                                    let _e3521 = local_52[_e3508];
                                    let _e3522 = (_e3519 - _e3521);
                                    if (abs(_e3522) > 0.000061f) {
                                        let _e3526 = local_53[_e3510];
                                        let _e3527 = local_52[_e3508];
                                        let _e3528 = max(_e3526, _e3527);
                                        if (_e3528 != 0f) {
                                            phi_30206_ = (min(_e3526, _e3527) / _e3528);
                                        } else {
                                            phi_30206_ = 0f;
                                        }
                                        let _e3533 = phi_30206_;
                                        let _e3535 = (sign(_e3522) * (1f - _e3533));
                                        let _e3540 = local_53[_e3510];
                                        let _e3541 = local_52[_e3508];
                                        let _e3544 = (_e3510 + select(0i, 1i, (_e3540 < _e3541)));
                                        let _e3546 = local_53[_e3544];
                                        let _e3547 = local_52[_e3508];
                                        phi_30479_ = (_e3508 + select(0i, 1i, (_e3546 >= _e3547)));
                                        phi_30478_ = _e3544;
                                        phi_30444_ = select(_e3512, _e3535, (abs(_e3535) < abs(_e3512)));
                                    } else {
                                        phi_30479_ = _e3508;
                                        phi_30478_ = _e3510;
                                        phi_30444_ = 65504f;
                                    }
                                    let _e3552 = phi_30479_;
                                    let _e3554 = phi_30478_;
                                    let _e3556 = phi_30444_;
                                    local_218 = _e3552;
                                    local_219 = _e3554;
                                    local_220 = _e3556;
                                    continue;
                                } else {
                                    break;
                                }
                                continuing {
                                    let _e5486 = local_218;
                                    phi_30205_ = _e5486;
                                    let _e5489 = local_219;
                                    phi_30204_ = _e5489;
                                    let _e5492 = local_220;
                                    phi_30059_ = _e5492;
                                    phi_30058_ = (_e3514 + 1i);
                                }
                            }
                            let _e5500 = local_221;
                            phi_30060_ = _e5500;
                        }
                        let _e3559 = phi_30060_;
                        phi_30061_ = (_e3559 * select(0f, 1f, (_e3559 < 65503f)));
                    }
                    let _e3564 = phi_30061_;
                    let _e3569 = vec4<f32>(_e3564, vec4<f32>(0f, 0f, 0f, 0f).y, vec4<f32>(0f, 0f, 0f, 0f).z, vec4<f32>(0f, 0f, 0f, 0f).w);
                    if (_e3564 != 0f) {
                        phi_30068_ = sign(_e3564);
                    } else {
                        phi_30068_ = 0f;
                    }
                    let _e3573 = phi_30068_;
                    let _e3578 = vec4<f32>(_e3569.x, _e3573, _e3569.z, _e3569.w);
                    let _e3586 = vec2<i32>(vec2<f32>(bitcast<vec2<i32>>((_e3329 + vec2<u32>(0u, 1u)))));
                    let _e3593 = vec2<i32>(max(0i, min(_e3586.x, _e224)), max(0i, min(_e3586.y, _e229)));
                    let _e3595 = textureDimensions(global_3, 0i);
                    if all((bitcast<vec2<u32>>(_e3593) < bitcast<vec2<u32>>(vec2<i32>(_e3595)))) {
                        let _e3600 = textureLoad(global_3, _e3593, 0i);
                        phi_30070_ = _e3600;
                    } else {
                        phi_30070_ = vec4<f32>(0f, 0f, 0f, 0f);
                    }
                    let _e3602 = phi_30070_;
                    let _e3606 = ((vec2<f32>(_e3593) + vec2<f32>(0.5f, 0.5f)) / _e246);
                    phi_30071_ = 0i;
                    loop {
                        let _e3612 = phi_30071_;
                        if (_e3612 < 5i) {
                            local_69 = array<vec2<i32>, 5>(vec2<i32>(0i, 0i), vec2<i32>(-1i, 0i), vec2<i32>(1i, 0i), vec2<i32>(0i, -1i), vec2<i32>(0i, 1i));
                            let _e3615 = local_69[_e3612];
                            let _e3616 = (vec2<i32>(floor(((_e3606 + _e250) * _e246))) + _e3615);
                            let _e3623 = vec2<i32>(max(0i, min(_e3616.x, _e224)), max(0i, min(_e3616.y, _e229)));
                            let _e3625 = textureDimensions(global_1, 0i);
                            if all((bitcast<vec2<u32>>(_e3623) < bitcast<vec2<u32>>(vec2<i32>(_e3625)))) {
                                let _e3630 = textureLoad(global_1, _e3623, 0i);
                                phi_30202_ = _e3630;
                            } else {
                                phi_30202_ = vec4<f32>(0f, 0f, 0f, 0f);
                            }
                            let _e3632 = phi_30202_;
                            let _e3635 = global.member_18;
                            local_57[_e3612] = (_e3632.x * select(_e3635, 1f, (_e3635 == 0f)));
                            let _e3640 = local_57[_e3612];
                            local_57[_e3612] = pow(_e3640, 1f);
                            let _e3642 = local_57[_e3612];
                            local_57[_e3612] = max(_e3642, 0.000061f);
                            continue;
                        } else {
                            break;
                        }
                        continuing {
                            phi_30071_ = (_e3612 + 1i);
                        }
                    }
                    let _e3645 = local_57;
                    let _e3647 = ((_e3606 + _e295) + _e3602.xy);
                    let _e3649 = (_e3647.x >= 0f);
                    phi_18794_ = _e3649;
                    if _e3649 {
                        phi_18794_ = (_e3647.x <= 1f);
                    }
                    let _e3652 = phi_18794_;
                    phi_18806_ = _e3652;
                    if _e3652 {
                        let _e3654 = (_e3647.y >= 0f);
                        phi_18804_ = _e3654;
                        if _e3654 {
                            phi_18804_ = (_e3647.y <= 1f);
                        }
                        let _e3657 = phi_18804_;
                        phi_18806_ = _e3657;
                    }
                    let _e3659 = phi_18806_;
                    if _e3659 {
                        phi_30072_ = 0i;
                        loop {
                            let _e3664 = phi_30072_;
                            if (_e3664 < 5i) {
                                local_68 = array<vec2<i32>, 5>(vec2<i32>(0i, 0i), vec2<i32>(-1i, 0i), vec2<i32>(1i, 0i), vec2<i32>(0i, -1i), vec2<i32>(0i, 1i));
                                let _e3667 = local_68[_e3664];
                                let _e3668 = (vec2<i32>(floor((_e3647 * _e294))) + _e3667);
                                let _e3679 = vec2<i32>(max(0i, min(_e3668.x, (_e293.x - 1i))), max(0i, min(_e3668.y, (_e293.y - 1i))));
                                let _e3681 = textureDimensions(global_2, 0i);
                                if all((bitcast<vec2<u32>>(_e3679) < bitcast<vec2<u32>>(vec2<i32>(_e3681)))) {
                                    let _e3686 = textureLoad(global_2, _e3679, 0i);
                                    phi_30200_ = _e3686;
                                } else {
                                    phi_30200_ = vec4<f32>(0f, 0f, 0f, 0f);
                                }
                                let _e3688 = phi_30200_;
                                let _e3691 = global.member_10;
                                let _e3694 = global.member_18;
                                local_13[_e3664] = ((_e3688.x * _e3691) * select(_e3694, 1f, (_e3694 == 0f)));
                                let _e3699 = local_13[_e3664];
                                local_13[_e3664] = pow(_e3699, 1f);
                                let _e3701 = local_13[_e3664];
                                local_13[_e3664] = max(_e3701, 0.000061f);
                                continue;
                            } else {
                                break;
                            }
                            continuing {
                                phi_30072_ = (_e3664 + 1i);
                            }
                        }
                    }
                    let _e3704 = local_13;
                    phi_30076_ = 0f;
                    if _e3659 {
                        let _e3710 = min(_e3645[0], _e3645[3]);
                        let _e3711 = max(_e3645[0], _e3645[3]);
                        let _e3712 = min(_e3645[1], _e3645[4]);
                        let _e3713 = max(_e3645[1], _e3645[4]);
                        let _e3714 = min(_e3710, _e3645[2]);
                        let _e3715 = max(_e3710, _e3645[2]);
                        let _e3716 = min(_e3712, _e3711);
                        let _e3717 = max(_e3712, _e3711);
                        let _e3719 = max(_e3714, _e3716);
                        let _e3720 = min(_e3715, _e3713);
                        let _e3721 = max(_e3715, _e3713);
                        let _e3723 = max(_e3719, _e3720);
                        let _e3724 = min(_e3717, _e3721);
                        local_56 = array<f32, 5>(min(_e3714, _e3716), min(_e3719, _e3720), min(_e3723, _e3724), max(_e3723, _e3724), max(_e3717, _e3721));
                        let _e3734 = min(_e3704[0], _e3704[3]);
                        let _e3735 = max(_e3704[0], _e3704[3]);
                        let _e3736 = min(_e3704[1], _e3704[4]);
                        let _e3737 = max(_e3704[1], _e3704[4]);
                        let _e3738 = min(_e3734, _e3704[2]);
                        let _e3739 = max(_e3734, _e3704[2]);
                        let _e3740 = min(_e3736, _e3735);
                        let _e3741 = max(_e3736, _e3735);
                        let _e3743 = max(_e3738, _e3740);
                        let _e3744 = min(_e3739, _e3737);
                        let _e3745 = max(_e3739, _e3737);
                        let _e3747 = max(_e3743, _e3744);
                        let _e3748 = min(_e3741, _e3745);
                        local_55 = array<f32, 5>(min(_e3738, _e3740), min(_e3743, _e3744), min(_e3747, _e3748), max(_e3747, _e3748), max(_e3741, _e3745));
                        let _e3754 = local_56[4i];
                        let _e3756 = local_55[4i];
                        phi_30075_ = 65503f;
                        if (min(_e3754, _e3756) > 0.000000000000000000000000000000000000011754944f) {
                            phi_30193_ = 0i;
                            phi_30192_ = 0i;
                            phi_30074_ = 65503f;
                            phi_30073_ = 0i;
                            loop {
                                let _e3760 = phi_30193_;
                                let _e3762 = phi_30192_;
                                let _e3764 = phi_30074_;
                                let _e3766 = phi_30073_;
                                local_225 = _e3764;
                                if ((_e3766 < 5i) && (_e3764 < 65504f)) {
                                    let _e3771 = local_56[_e3762];
                                    let _e3773 = local_55[_e3760];
                                    let _e3774 = (_e3771 - _e3773);
                                    if (abs(_e3774) > 0.000061f) {
                                        let _e3778 = local_56[_e3762];
                                        let _e3779 = local_55[_e3760];
                                        let _e3780 = max(_e3778, _e3779);
                                        if (_e3780 != 0f) {
                                            phi_30194_ = (min(_e3778, _e3779) / _e3780);
                                        } else {
                                            phi_30194_ = 0f;
                                        }
                                        let _e3785 = phi_30194_;
                                        let _e3787 = (sign(_e3774) * (1f - _e3785));
                                        let _e3792 = local_56[_e3762];
                                        let _e3793 = local_55[_e3760];
                                        let _e3796 = (_e3762 + select(0i, 1i, (_e3792 < _e3793)));
                                        let _e3798 = local_56[_e3796];
                                        let _e3799 = local_55[_e3760];
                                        phi_30477_ = (_e3760 + select(0i, 1i, (_e3798 >= _e3799)));
                                        phi_30476_ = _e3796;
                                        phi_30447_ = select(_e3764, _e3787, (abs(_e3787) < abs(_e3764)));
                                    } else {
                                        phi_30477_ = _e3760;
                                        phi_30476_ = _e3762;
                                        phi_30447_ = 65504f;
                                    }
                                    let _e3804 = phi_30477_;
                                    let _e3806 = phi_30476_;
                                    let _e3808 = phi_30447_;
                                    local_222 = _e3804;
                                    local_223 = _e3806;
                                    local_224 = _e3808;
                                    continue;
                                } else {
                                    break;
                                }
                                continuing {
                                    let _e5513 = local_222;
                                    phi_30193_ = _e5513;
                                    let _e5516 = local_223;
                                    phi_30192_ = _e5516;
                                    let _e5519 = local_224;
                                    phi_30074_ = _e5519;
                                    phi_30073_ = (_e3766 + 1i);
                                }
                            }
                            let _e5527 = local_225;
                            phi_30075_ = _e5527;
                        }
                        let _e3811 = phi_30075_;
                        phi_30076_ = (_e3811 * select(0f, 1f, (_e3811 < 65503f)));
                    }
                    let _e3816 = phi_30076_;
                    let _e3821 = vec4<f32>(_e3816, vec4<f32>(0f, 0f, 0f, 0f).y, vec4<f32>(0f, 0f, 0f, 0f).z, vec4<f32>(0f, 0f, 0f, 0f).w);
                    if (_e3816 != 0f) {
                        phi_30083_ = sign(_e3816);
                    } else {
                        phi_30083_ = 0f;
                    }
                    let _e3825 = phi_30083_;
                    let _e3830 = vec4<f32>(_e3821.x, _e3825, _e3821.z, _e3821.w);
                    let _e3838 = vec2<i32>(vec2<f32>(bitcast<vec2<i32>>((_e3329 + vec2<u32>(1u, 0u)))));
                    let _e3845 = vec2<i32>(max(0i, min(_e3838.x, _e224)), max(0i, min(_e3838.y, _e229)));
                    let _e3847 = textureDimensions(global_3, 0i);
                    if all((bitcast<vec2<u32>>(_e3845) < bitcast<vec2<u32>>(vec2<i32>(_e3847)))) {
                        let _e3852 = textureLoad(global_3, _e3845, 0i);
                        phi_30085_ = _e3852;
                    } else {
                        phi_30085_ = vec4<f32>(0f, 0f, 0f, 0f);
                    }
                    let _e3854 = phi_30085_;
                    let _e3858 = ((vec2<f32>(_e3845) + vec2<f32>(0.5f, 0.5f)) / _e246);
                    phi_30086_ = 0i;
                    loop {
                        let _e3864 = phi_30086_;
                        if (_e3864 < 5i) {
                            local_67 = array<vec2<i32>, 5>(vec2<i32>(0i, 0i), vec2<i32>(-1i, 0i), vec2<i32>(1i, 0i), vec2<i32>(0i, -1i), vec2<i32>(0i, 1i));
                            let _e3867 = local_67[_e3864];
                            let _e3868 = (vec2<i32>(floor(((_e3858 + _e250) * _e246))) + _e3867);
                            let _e3875 = vec2<i32>(max(0i, min(_e3868.x, _e224)), max(0i, min(_e3868.y, _e229)));
                            let _e3877 = textureDimensions(global_1, 0i);
                            if all((bitcast<vec2<u32>>(_e3875) < bitcast<vec2<u32>>(vec2<i32>(_e3877)))) {
                                let _e3882 = textureLoad(global_1, _e3875, 0i);
                                phi_30190_ = _e3882;
                            } else {
                                phi_30190_ = vec4<f32>(0f, 0f, 0f, 0f);
                            }
                            let _e3884 = phi_30190_;
                            let _e3887 = global.member_18;
                            local_60[_e3864] = (_e3884.x * select(_e3887, 1f, (_e3887 == 0f)));
                            let _e3892 = local_60[_e3864];
                            local_60[_e3864] = pow(_e3892, 1f);
                            let _e3894 = local_60[_e3864];
                            local_60[_e3864] = max(_e3894, 0.000061f);
                            continue;
                        } else {
                            break;
                        }
                        continuing {
                            phi_30086_ = (_e3864 + 1i);
                        }
                    }
                    let _e3897 = local_60;
                    let _e3899 = ((_e3858 + _e295) + _e3854.xy);
                    let _e3901 = (_e3899.x >= 0f);
                    phi_19950_ = _e3901;
                    if _e3901 {
                        phi_19950_ = (_e3899.x <= 1f);
                    }
                    let _e3904 = phi_19950_;
                    phi_19962_ = _e3904;
                    if _e3904 {
                        let _e3906 = (_e3899.y >= 0f);
                        phi_19960_ = _e3906;
                        if _e3906 {
                            phi_19960_ = (_e3899.y <= 1f);
                        }
                        let _e3909 = phi_19960_;
                        phi_19962_ = _e3909;
                    }
                    let _e3911 = phi_19962_;
                    if _e3911 {
                        phi_30087_ = 0i;
                        loop {
                            let _e3916 = phi_30087_;
                            if (_e3916 < 5i) {
                                local_66 = array<vec2<i32>, 5>(vec2<i32>(0i, 0i), vec2<i32>(-1i, 0i), vec2<i32>(1i, 0i), vec2<i32>(0i, -1i), vec2<i32>(0i, 1i));
                                let _e3919 = local_66[_e3916];
                                let _e3920 = (vec2<i32>(floor((_e3899 * _e294))) + _e3919);
                                let _e3931 = vec2<i32>(max(0i, min(_e3920.x, (_e293.x - 1i))), max(0i, min(_e3920.y, (_e293.y - 1i))));
                                let _e3933 = textureDimensions(global_2, 0i);
                                if all((bitcast<vec2<u32>>(_e3931) < bitcast<vec2<u32>>(vec2<i32>(_e3933)))) {
                                    let _e3938 = textureLoad(global_2, _e3931, 0i);
                                    phi_30188_ = _e3938;
                                } else {
                                    phi_30188_ = vec4<f32>(0f, 0f, 0f, 0f);
                                }
                                let _e3940 = phi_30188_;
                                let _e3943 = global.member_10;
                                let _e3946 = global.member_18;
                                local_14[_e3916] = ((_e3940.x * _e3943) * select(_e3946, 1f, (_e3946 == 0f)));
                                let _e3951 = local_14[_e3916];
                                local_14[_e3916] = pow(_e3951, 1f);
                                let _e3953 = local_14[_e3916];
                                local_14[_e3916] = max(_e3953, 0.000061f);
                                continue;
                            } else {
                                break;
                            }
                            continuing {
                                phi_30087_ = (_e3916 + 1i);
                            }
                        }
                    }
                    let _e3956 = local_14;
                    phi_30091_ = 0f;
                    if _e3911 {
                        let _e3962 = min(_e3897[0], _e3897[3]);
                        let _e3963 = max(_e3897[0], _e3897[3]);
                        let _e3964 = min(_e3897[1], _e3897[4]);
                        let _e3965 = max(_e3897[1], _e3897[4]);
                        let _e3966 = min(_e3962, _e3897[2]);
                        let _e3967 = max(_e3962, _e3897[2]);
                        let _e3968 = min(_e3964, _e3963);
                        let _e3969 = max(_e3964, _e3963);
                        let _e3971 = max(_e3966, _e3968);
                        let _e3972 = min(_e3967, _e3965);
                        let _e3973 = max(_e3967, _e3965);
                        let _e3975 = max(_e3971, _e3972);
                        let _e3976 = min(_e3969, _e3973);
                        local_59 = array<f32, 5>(min(_e3966, _e3968), min(_e3971, _e3972), min(_e3975, _e3976), max(_e3975, _e3976), max(_e3969, _e3973));
                        let _e3986 = min(_e3956[0], _e3956[3]);
                        let _e3987 = max(_e3956[0], _e3956[3]);
                        let _e3988 = min(_e3956[1], _e3956[4]);
                        let _e3989 = max(_e3956[1], _e3956[4]);
                        let _e3990 = min(_e3986, _e3956[2]);
                        let _e3991 = max(_e3986, _e3956[2]);
                        let _e3992 = min(_e3988, _e3987);
                        let _e3993 = max(_e3988, _e3987);
                        let _e3995 = max(_e3990, _e3992);
                        let _e3996 = min(_e3991, _e3989);
                        let _e3997 = max(_e3991, _e3989);
                        let _e3999 = max(_e3995, _e3996);
                        let _e4000 = min(_e3993, _e3997);
                        local_58 = array<f32, 5>(min(_e3990, _e3992), min(_e3995, _e3996), min(_e3999, _e4000), max(_e3999, _e4000), max(_e3993, _e3997));
                        let _e4006 = local_59[4i];
                        let _e4008 = local_58[4i];
                        phi_30090_ = 65503f;
                        if (min(_e4006, _e4008) > 0.000000000000000000000000000000000000011754944f) {
                            phi_30181_ = 0i;
                            phi_30180_ = 0i;
                            phi_30089_ = 65503f;
                            phi_30088_ = 0i;
                            loop {
                                let _e4012 = phi_30181_;
                                let _e4014 = phi_30180_;
                                let _e4016 = phi_30089_;
                                let _e4018 = phi_30088_;
                                local_229 = _e4016;
                                if ((_e4018 < 5i) && (_e4016 < 65504f)) {
                                    let _e4023 = local_59[_e4014];
                                    let _e4025 = local_58[_e4012];
                                    let _e4026 = (_e4023 - _e4025);
                                    if (abs(_e4026) > 0.000061f) {
                                        let _e4030 = local_59[_e4014];
                                        let _e4031 = local_58[_e4012];
                                        let _e4032 = max(_e4030, _e4031);
                                        if (_e4032 != 0f) {
                                            phi_30182_ = (min(_e4030, _e4031) / _e4032);
                                        } else {
                                            phi_30182_ = 0f;
                                        }
                                        let _e4037 = phi_30182_;
                                        let _e4039 = (sign(_e4026) * (1f - _e4037));
                                        let _e4044 = local_59[_e4014];
                                        let _e4045 = local_58[_e4012];
                                        let _e4048 = (_e4014 + select(0i, 1i, (_e4044 < _e4045)));
                                        let _e4050 = local_59[_e4048];
                                        let _e4051 = local_58[_e4012];
                                        phi_30475_ = (_e4012 + select(0i, 1i, (_e4050 >= _e4051)));
                                        phi_30474_ = _e4048;
                                        phi_30450_ = select(_e4016, _e4039, (abs(_e4039) < abs(_e4016)));
                                    } else {
                                        phi_30475_ = _e4012;
                                        phi_30474_ = _e4014;
                                        phi_30450_ = 65504f;
                                    }
                                    let _e4056 = phi_30475_;
                                    let _e4058 = phi_30474_;
                                    let _e4060 = phi_30450_;
                                    local_226 = _e4056;
                                    local_227 = _e4058;
                                    local_228 = _e4060;
                                    continue;
                                } else {
                                    break;
                                }
                                continuing {
                                    let _e5540 = local_226;
                                    phi_30181_ = _e5540;
                                    let _e5543 = local_227;
                                    phi_30180_ = _e5543;
                                    let _e5546 = local_228;
                                    phi_30089_ = _e5546;
                                    phi_30088_ = (_e4018 + 1i);
                                }
                            }
                            let _e5554 = local_229;
                            phi_30090_ = _e5554;
                        }
                        let _e4063 = phi_30090_;
                        phi_30091_ = (_e4063 * select(0f, 1f, (_e4063 < 65503f)));
                    }
                    let _e4068 = phi_30091_;
                    let _e4073 = vec4<f32>(_e4068, vec4<f32>(0f, 0f, 0f, 0f).y, vec4<f32>(0f, 0f, 0f, 0f).z, vec4<f32>(0f, 0f, 0f, 0f).w);
                    if (_e4068 != 0f) {
                        phi_30098_ = sign(_e4068);
                    } else {
                        phi_30098_ = 0f;
                    }
                    let _e4077 = phi_30098_;
                    let _e4082 = vec4<f32>(_e4073.x, _e4077, _e4073.z, _e4073.w);
                    let _e4090 = vec2<i32>(vec2<f32>(bitcast<vec2<i32>>((_e3329 + vec2<u32>(1u, 1u)))));
                    let _e4097 = vec2<i32>(max(0i, min(_e4090.x, _e224)), max(0i, min(_e4090.y, _e229)));
                    let _e4099 = textureDimensions(global_3, 0i);
                    if all((bitcast<vec2<u32>>(_e4097) < bitcast<vec2<u32>>(vec2<i32>(_e4099)))) {
                        let _e4104 = textureLoad(global_3, _e4097, 0i);
                        phi_30100_ = _e4104;
                    } else {
                        phi_30100_ = vec4<f32>(0f, 0f, 0f, 0f);
                    }
                    let _e4106 = phi_30100_;
                    let _e4110 = ((vec2<f32>(_e4097) + vec2<f32>(0.5f, 0.5f)) / _e246);
                    phi_30101_ = 0i;
                    loop {
                        let _e4116 = phi_30101_;
                        if (_e4116 < 5i) {
                            local_65 = array<vec2<i32>, 5>(vec2<i32>(0i, 0i), vec2<i32>(-1i, 0i), vec2<i32>(1i, 0i), vec2<i32>(0i, -1i), vec2<i32>(0i, 1i));
                            let _e4119 = local_65[_e4116];
                            let _e4120 = (vec2<i32>(floor(((_e4110 + _e250) * _e246))) + _e4119);
                            let _e4127 = vec2<i32>(max(0i, min(_e4120.x, _e224)), max(0i, min(_e4120.y, _e229)));
                            let _e4129 = textureDimensions(global_1, 0i);
                            if all((bitcast<vec2<u32>>(_e4127) < bitcast<vec2<u32>>(vec2<i32>(_e4129)))) {
                                let _e4134 = textureLoad(global_1, _e4127, 0i);
                                phi_30178_ = _e4134;
                            } else {
                                phi_30178_ = vec4<f32>(0f, 0f, 0f, 0f);
                            }
                            let _e4136 = phi_30178_;
                            let _e4139 = global.member_18;
                            local_63[_e4116] = (_e4136.x * select(_e4139, 1f, (_e4139 == 0f)));
                            let _e4144 = local_63[_e4116];
                            local_63[_e4116] = pow(_e4144, 1f);
                            let _e4146 = local_63[_e4116];
                            local_63[_e4116] = max(_e4146, 0.000061f);
                            continue;
                        } else {
                            break;
                        }
                        continuing {
                            phi_30101_ = (_e4116 + 1i);
                        }
                    }
                    let _e4149 = local_63;
                    let _e4151 = ((_e4110 + _e295) + _e4106.xy);
                    let _e4153 = (_e4151.x >= 0f);
                    phi_21106_ = _e4153;
                    if _e4153 {
                        phi_21106_ = (_e4151.x <= 1f);
                    }
                    let _e4156 = phi_21106_;
                    phi_21118_ = _e4156;
                    if _e4156 {
                        let _e4158 = (_e4151.y >= 0f);
                        phi_21116_ = _e4158;
                        if _e4158 {
                            phi_21116_ = (_e4151.y <= 1f);
                        }
                        let _e4161 = phi_21116_;
                        phi_21118_ = _e4161;
                    }
                    let _e4163 = phi_21118_;
                    if _e4163 {
                        phi_30102_ = 0i;
                        loop {
                            let _e4168 = phi_30102_;
                            if (_e4168 < 5i) {
                                local_64 = array<vec2<i32>, 5>(vec2<i32>(0i, 0i), vec2<i32>(-1i, 0i), vec2<i32>(1i, 0i), vec2<i32>(0i, -1i), vec2<i32>(0i, 1i));
                                let _e4171 = local_64[_e4168];
                                let _e4172 = (vec2<i32>(floor((_e4151 * _e294))) + _e4171);
                                let _e4183 = vec2<i32>(max(0i, min(_e4172.x, (_e293.x - 1i))), max(0i, min(_e4172.y, (_e293.y - 1i))));
                                let _e4185 = textureDimensions(global_2, 0i);
                                if all((bitcast<vec2<u32>>(_e4183) < bitcast<vec2<u32>>(vec2<i32>(_e4185)))) {
                                    let _e4190 = textureLoad(global_2, _e4183, 0i);
                                    phi_30176_ = _e4190;
                                } else {
                                    phi_30176_ = vec4<f32>(0f, 0f, 0f, 0f);
                                }
                                let _e4192 = phi_30176_;
                                let _e4195 = global.member_10;
                                let _e4198 = global.member_18;
                                local_15[_e4168] = ((_e4192.x * _e4195) * select(_e4198, 1f, (_e4198 == 0f)));
                                let _e4203 = local_15[_e4168];
                                local_15[_e4168] = pow(_e4203, 1f);
                                let _e4205 = local_15[_e4168];
                                local_15[_e4168] = max(_e4205, 0.000061f);
                                continue;
                            } else {
                                break;
                            }
                            continuing {
                                phi_30102_ = (_e4168 + 1i);
                            }
                        }
                    }
                    let _e4208 = local_15;
                    phi_30106_ = 0f;
                    if _e4163 {
                        let _e4214 = min(_e4149[0], _e4149[3]);
                        let _e4215 = max(_e4149[0], _e4149[3]);
                        let _e4216 = min(_e4149[1], _e4149[4]);
                        let _e4217 = max(_e4149[1], _e4149[4]);
                        let _e4218 = min(_e4214, _e4149[2]);
                        let _e4219 = max(_e4214, _e4149[2]);
                        let _e4220 = min(_e4216, _e4215);
                        let _e4221 = max(_e4216, _e4215);
                        let _e4223 = max(_e4218, _e4220);
                        let _e4224 = min(_e4219, _e4217);
                        let _e4225 = max(_e4219, _e4217);
                        let _e4227 = max(_e4223, _e4224);
                        let _e4228 = min(_e4221, _e4225);
                        local_62 = array<f32, 5>(min(_e4218, _e4220), min(_e4223, _e4224), min(_e4227, _e4228), max(_e4227, _e4228), max(_e4221, _e4225));
                        let _e4238 = min(_e4208[0], _e4208[3]);
                        let _e4239 = max(_e4208[0], _e4208[3]);
                        let _e4240 = min(_e4208[1], _e4208[4]);
                        let _e4241 = max(_e4208[1], _e4208[4]);
                        let _e4242 = min(_e4238, _e4208[2]);
                        let _e4243 = max(_e4238, _e4208[2]);
                        let _e4244 = min(_e4240, _e4239);
                        let _e4245 = max(_e4240, _e4239);
                        let _e4247 = max(_e4242, _e4244);
                        let _e4248 = min(_e4243, _e4241);
                        let _e4249 = max(_e4243, _e4241);
                        let _e4251 = max(_e4247, _e4248);
                        let _e4252 = min(_e4245, _e4249);
                        local_61 = array<f32, 5>(min(_e4242, _e4244), min(_e4247, _e4248), min(_e4251, _e4252), max(_e4251, _e4252), max(_e4245, _e4249));
                        let _e4258 = local_62[4i];
                        let _e4260 = local_61[4i];
                        phi_30105_ = 65503f;
                        if (min(_e4258, _e4260) > 0.000000000000000000000000000000000000011754944f) {
                            phi_30169_ = 0i;
                            phi_30168_ = 0i;
                            phi_30104_ = 65503f;
                            phi_30103_ = 0i;
                            loop {
                                let _e4264 = phi_30169_;
                                let _e4266 = phi_30168_;
                                let _e4268 = phi_30104_;
                                let _e4270 = phi_30103_;
                                local_233 = _e4268;
                                if ((_e4270 < 5i) && (_e4268 < 65504f)) {
                                    let _e4275 = local_62[_e4266];
                                    let _e4277 = local_61[_e4264];
                                    let _e4278 = (_e4275 - _e4277);
                                    if (abs(_e4278) > 0.000061f) {
                                        let _e4282 = local_62[_e4266];
                                        let _e4283 = local_61[_e4264];
                                        let _e4284 = max(_e4282, _e4283);
                                        if (_e4284 != 0f) {
                                            phi_30170_ = (min(_e4282, _e4283) / _e4284);
                                        } else {
                                            phi_30170_ = 0f;
                                        }
                                        let _e4289 = phi_30170_;
                                        let _e4291 = (sign(_e4278) * (1f - _e4289));
                                        let _e4296 = local_62[_e4266];
                                        let _e4297 = local_61[_e4264];
                                        let _e4300 = (_e4266 + select(0i, 1i, (_e4296 < _e4297)));
                                        let _e4302 = local_62[_e4300];
                                        let _e4303 = local_61[_e4264];
                                        phi_30473_ = (_e4264 + select(0i, 1i, (_e4302 >= _e4303)));
                                        phi_30472_ = _e4300;
                                        phi_30453_ = select(_e4268, _e4291, (abs(_e4291) < abs(_e4268)));
                                    } else {
                                        phi_30473_ = _e4264;
                                        phi_30472_ = _e4266;
                                        phi_30453_ = 65504f;
                                    }
                                    let _e4308 = phi_30473_;
                                    let _e4310 = phi_30472_;
                                    let _e4312 = phi_30453_;
                                    local_230 = _e4308;
                                    local_231 = _e4310;
                                    local_232 = _e4312;
                                    continue;
                                } else {
                                    break;
                                }
                                continuing {
                                    let _e5567 = local_230;
                                    phi_30169_ = _e5567;
                                    let _e5570 = local_231;
                                    phi_30168_ = _e5570;
                                    let _e5573 = local_232;
                                    phi_30104_ = _e5573;
                                    phi_30103_ = (_e4270 + 1i);
                                }
                            }
                            let _e5581 = local_233;
                            phi_30105_ = _e5581;
                        }
                        let _e4315 = phi_30105_;
                        phi_30106_ = (_e4315 * select(0f, 1f, (_e4315 < 65503f)));
                    }
                    let _e4320 = phi_30106_;
                    let _e4325 = vec4<f32>(_e4320, vec4<f32>(0f, 0f, 0f, 0f).y, vec4<f32>(0f, 0f, 0f, 0f).z, vec4<f32>(0f, 0f, 0f, 0f).w);
                    if (_e4320 != 0f) {
                        phi_30113_ = sign(_e4320);
                    } else {
                        phi_30113_ = 0f;
                    }
                    let _e4329 = phi_30113_;
                    let _e4334 = vec4<f32>(_e4325.x, _e4329, _e4325.z, _e4325.w);
                    local_96[3i] = ((((vec4<f32>(_e3578.x, _e3578.y, 1f, _e3578.w) + vec4<f32>(_e3830.x, _e3830.y, 1f, _e3830.w)) + vec4<f32>(_e4082.x, _e4082.y, 1f, _e4082.w)) + vec4<f32>(_e4334.x, _e4334.y, 1f, _e4334.w)) * 0.25f);
                    let _e4345 = local_96[3i];
                    let _e4347 = textureDimensions(global_4);
                    if all((bitcast<vec2<u32>>(_e3328) < bitcast<vec2<u32>>(vec2<i32>(_e4347)))) {
                        textureStore(global_4, _e3328, vec4<f32>(_e4345.x, _e4345.y, 0f, 0f));
                    }
                    if (_e170 <= 1u) {
                        break;
                    }
                    phi_30159_ = 0u;
                    loop {
                        let _e4357 = phi_30159_;
                        if (_e4357 < 4u) {
                            let _e4360 = local_96[_e4357];
                            global_8[_e195][_e199] = _e4360.x;
                            global_9[_e195][_e199] = _e4360.y;
                            global_10[_e195][_e199] = _e4360.z;
                            global_11[_e195][_e199] = _e4360.w;
                            storageBarrier();
                            workgroupBarrier();
                            textureBarrier();
                            workgroupBarrier();
                            if (_e166 < 64u) {
                                let _e4374 = (_e203 + 1u);
                                let _e4375 = (_e205 + 1u);
                                let _e4378 = global_8[_e203][_e205];
                                let _e4381 = global_9[_e203][_e205];
                                let _e4384 = global_10[_e203][_e205];
                                let _e4387 = global_11[_e203][_e205];
                                let _e4391 = global_8[_e4374][_e205];
                                let _e4394 = global_9[_e4374][_e205];
                                let _e4397 = global_10[_e4374][_e205];
                                let _e4400 = global_11[_e4374][_e205];
                                let _e4404 = global_8[_e203][_e4375];
                                let _e4407 = global_9[_e203][_e4375];
                                let _e4410 = global_10[_e203][_e4375];
                                let _e4413 = global_11[_e203][_e4375];
                                let _e4417 = global_8[_e4374][_e4375];
                                let _e4420 = global_9[_e4374][_e4375];
                                let _e4423 = global_10[_e4374][_e4375];
                                let _e4426 = global_11[_e4374][_e4375];
                                local_96[_e4357] = ((((vec4<f32>(_e4378, _e4381, _e4384, _e4387) + vec4<f32>(_e4391, _e4394, _e4397, _e4400)) + vec4<f32>(_e4404, _e4407, _e4410, _e4413)) + vec4<f32>(_e4417, _e4420, _e4423, _e4426)) * 0.25f);
                                let _e4443 = (bitcast<vec2<i32>>((_e167 * vec2<u32>(16u, 16u))) + vec2<i32>(bitcast<i32>((_e195 + ((_e4357 % 2u) * 8u))), bitcast<i32>((_e199 + ((_e4357 / 2u) * 8u)))));
                                let _e4444 = local_96[_e4357];
                                let _e4446 = textureDimensions(global_5);
                                if all((bitcast<vec2<u32>>(_e4443) < bitcast<vec2<u32>>(vec2<i32>(_e4446)))) {
                                    textureStore(global_5, _e4443, vec4<f32>(_e4444.x, _e4444.y, 0f, 0f));
                                }
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
                            phi_30159_ = (_e4357 + bitcast<u32>(1i));
                        }
                    }
                    if (_e166 < 64u) {
                        let _e4457 = local_96[0i];
                        global_8[_e195][_e199] = _e4457.x;
                        global_9[_e195][_e199] = _e4457.y;
                        global_10[_e195][_e199] = _e4457.z;
                        global_11[_e195][_e199] = _e4457.w;
                        let _e4470 = (_e195 + 8u);
                        let _e4471 = local_96[1i];
                        global_8[_e4470][_e199] = _e4471.x;
                        global_9[_e4470][_e199] = _e4471.y;
                        global_10[_e4470][_e199] = _e4471.z;
                        global_11[_e4470][_e199] = _e4471.w;
                        let _e4484 = (_e199 + 8u);
                        let _e4485 = local_96[2i];
                        global_8[_e195][_e4484] = _e4485.x;
                        global_9[_e195][_e4484] = _e4485.y;
                        global_10[_e195][_e4484] = _e4485.z;
                        global_11[_e195][_e4484] = _e4485.w;
                        let _e4498 = local_96[3i];
                        global_8[_e4470][_e4484] = _e4498.x;
                        global_9[_e4470][_e4484] = _e4498.y;
                        global_10[_e4470][_e4484] = _e4498.z;
                        global_11[_e4470][_e4484] = _e4498.w;
                    }
                    break;
                }
            }
            switch bitcast<i32>(0u) {
                default: {
                    if (_e170 <= 2u) {
                        break;
                    }
                    storageBarrier();
                    workgroupBarrier();
                    textureBarrier();
                    workgroupBarrier();
                    if (_e166 < 64u) {
                        let _e4515 = local_97;
                        let _e4516 = (_e4515 + 1u);
                        let _e4518 = local_98;
                        let _e4519 = (_e4518 + 1u);
                        let _e4521 = local_99;
                        let _e4524 = local_100;
                        let _e4526 = global_8[_e4521][_e4524];
                        let _e4528 = local_101;
                        let _e4531 = local_102;
                        let _e4533 = global_9[_e4528][_e4531];
                        let _e4535 = local_103;
                        let _e4538 = local_104;
                        let _e4540 = global_10[_e4535][_e4538];
                        let _e4542 = local_105;
                        let _e4545 = local_106;
                        let _e4547 = global_11[_e4542][_e4545];
                        let _e4551 = local_107;
                        let _e4553 = global_8[_e4516][_e4551];
                        let _e4556 = local_108;
                        let _e4558 = global_9[_e4516][_e4556];
                        let _e4561 = local_109;
                        let _e4563 = global_10[_e4516][_e4561];
                        let _e4566 = local_110;
                        let _e4568 = global_11[_e4516][_e4566];
                        let _e4571 = local_111;
                        let _e4574 = global_8[_e4571][_e4519];
                        let _e4576 = local_112;
                        let _e4579 = global_9[_e4576][_e4519];
                        let _e4581 = local_113;
                        let _e4584 = global_10[_e4581][_e4519];
                        let _e4586 = local_114;
                        let _e4589 = global_11[_e4586][_e4519];
                        let _e4593 = global_8[_e4516][_e4519];
                        let _e4596 = global_9[_e4516][_e4519];
                        let _e4599 = global_10[_e4516][_e4519];
                        let _e4602 = global_11[_e4516][_e4519];
                        let _e4607 = ((((vec4<f32>(_e4526, _e4533, _e4540, _e4547) + vec4<f32>(_e4553, _e4558, _e4563, _e4568)) + vec4<f32>(_e4574, _e4579, _e4584, _e4589)) + vec4<f32>(_e4593, _e4596, _e4599, _e4602)) * 0.25f);
                        let _e4611 = local_115;
                        let _e4612 = (bitcast<vec2<i32>>((_e167 * vec2<u32>(8u, 8u))) + _e4611);
                        let _e4614 = textureDimensions(global_6);
                        if all((bitcast<vec2<u32>>(_e4612) < bitcast<vec2<u32>>(vec2<i32>(_e4614)))) {
                            textureStore(global_6, _e4612, vec4<f32>(_e4607.x, _e4607.y, 0f, 0f));
                        }
                        let _e4624 = local_116;
                        let _e4625 = (_e4624 + (_e199 % 2u));
                        let _e4629 = local_117;
                        global_8[_e4625][_e4629] = _e4607.x;
                        let _e4634 = local_118;
                        global_9[_e4625][_e4634] = _e4607.y;
                        let _e4639 = local_119;
                        global_10[_e4625][_e4639] = _e4607.z;
                        let _e4644 = local_120;
                        global_11[_e4625][_e4644] = _e4607.w;
                    }
                    if (_e170 <= 3u) {
                        break;
                    }
                    storageBarrier();
                    workgroupBarrier();
                    textureBarrier();
                    workgroupBarrier();
                    if (_e166 < 16u) {
                        let _e4648 = (_e195 * 4u);
                        let _e4649 = (_e199 * 4u);
                        let _e4650 = (_e4648 + 2u);
                        let _e4651 = (_e4648 + 1u);
                        let _e4652 = (_e4649 + 2u);
                        let _e4653 = (_e4648 + 3u);
                        let _e4656 = global_8[_e4648][_e4649];
                        let _e4659 = global_9[_e4648][_e4649];
                        let _e4662 = global_10[_e4648][_e4649];
                        let _e4665 = global_11[_e4648][_e4649];
                        let _e4669 = global_8[_e4650][_e4649];
                        let _e4672 = global_9[_e4650][_e4649];
                        let _e4675 = global_10[_e4650][_e4649];
                        let _e4678 = global_11[_e4650][_e4649];
                        let _e4682 = global_8[_e4651][_e4652];
                        let _e4685 = global_9[_e4651][_e4652];
                        let _e4688 = global_10[_e4651][_e4652];
                        let _e4691 = global_11[_e4651][_e4652];
                        let _e4695 = global_8[_e4653][_e4652];
                        let _e4698 = global_9[_e4653][_e4652];
                        let _e4701 = global_10[_e4653][_e4652];
                        let _e4704 = global_11[_e4653][_e4652];
                        let _e4709 = ((((vec4<f32>(_e4656, _e4659, _e4662, _e4665) + vec4<f32>(_e4669, _e4672, _e4675, _e4678)) + vec4<f32>(_e4682, _e4685, _e4688, _e4691)) + vec4<f32>(_e4695, _e4698, _e4701, _e4704)) * 0.25f);
                        let _e4710 = (_e4648 + _e199);
                        global_8[_e4710][_e4649] = _e4709.x;
                        global_9[_e4710][_e4649] = _e4709.y;
                        global_10[_e4710][_e4649] = _e4709.z;
                        global_11[_e4710][_e4649] = _e4709.w;
                    }
                    if (_e170 <= 4u) {
                        break;
                    }
                    storageBarrier();
                    workgroupBarrier();
                    textureBarrier();
                    workgroupBarrier();
                    if (_e166 < 4u) {
                        let _e4725 = (_e195 * 8u);
                        let _e4727 = local_121;
                        let _e4728 = (_e4725 + _e4727);
                        let _e4729 = (_e199 * 8u);
                        let _e4732 = local_122;
                        let _e4733 = ((_e4725 + 4u) + _e4732);
                        let _e4736 = local_123;
                        let _e4737 = ((_e4725 + 1u) + _e4736);
                        let _e4738 = (_e4729 + 4u);
                        let _e4741 = local_124;
                        let _e4742 = ((_e4725 + 5u) + _e4741);
                        let _e4745 = global_8[_e4728][_e4729];
                        let _e4748 = global_9[_e4728][_e4729];
                        let _e4751 = global_10[_e4728][_e4729];
                        let _e4754 = global_11[_e4728][_e4729];
                        let _e4758 = global_8[_e4733][_e4729];
                        let _e4761 = global_9[_e4733][_e4729];
                        let _e4764 = global_10[_e4733][_e4729];
                        let _e4767 = global_11[_e4733][_e4729];
                        let _e4771 = global_8[_e4737][_e4738];
                        let _e4774 = global_9[_e4737][_e4738];
                        let _e4777 = global_10[_e4737][_e4738];
                        let _e4780 = global_11[_e4737][_e4738];
                        let _e4784 = global_8[_e4742][_e4738];
                        let _e4787 = global_9[_e4742][_e4738];
                        let _e4790 = global_10[_e4742][_e4738];
                        let _e4793 = global_11[_e4742][_e4738];
                        let _e4798 = ((((vec4<f32>(_e4745, _e4748, _e4751, _e4754) + vec4<f32>(_e4758, _e4761, _e4764, _e4767)) + vec4<f32>(_e4771, _e4774, _e4777, _e4780)) + vec4<f32>(_e4784, _e4787, _e4790, _e4793)) * 0.25f);
                        let _e4800 = local_125;
                        let _e4801 = (_e195 + _e4800);
                        global_8[_e4801][0u] = _e4798.x;
                        global_9[_e4801][0u] = _e4798.y;
                        global_10[_e4801][0u] = _e4798.z;
                        global_11[_e4801][0u] = _e4798.w;
                    }
                    if (_e170 <= 5u) {
                        break;
                    }
                    storageBarrier();
                    workgroupBarrier();
                    textureBarrier();
                    workgroupBarrier();
                    break;
                }
            }
            if (_e170 <= 6u) {
                break;
            }
            if (_e166 == 0u) {
                global_7 = 0u;
            }
            storageBarrier();
            workgroupBarrier();
            textureBarrier();
            workgroupBarrier();
            let _e4817 = global_7;
            if (_e4817 != (_e173 - 1u)) {
                break;
            }
            switch bitcast<i32>(0u) {
                default: {
                    let _e4822 = local_126;
                    let _e4823 = (_e4822 + 1u);
                    let _e4825 = local_127;
                    let _e4826 = (_e4825 + 1u);
                    local_136 = _e4823;
                    local_138 = _e4823;
                    local_140 = _e4823;
                    local_142 = _e4823;
                    local_145 = _e4826;
                    local_147 = _e4826;
                    local_149 = _e4826;
                    local_151 = _e4826;
                    local_152 = _e4823;
                    local_153 = _e4826;
                    local_154 = _e4823;
                    local_155 = _e4826;
                    local_156 = _e4823;
                    local_157 = _e4826;
                    local_158 = _e4823;
                    local_159 = _e4826;
                    if (_e170 <= 7u) {
                        break;
                    }
                    global_8[_e195][_e199] = 0f;
                    global_9[_e195][_e199] = 0f;
                    global_10[_e195][_e199] = 0f;
                    global_11[_e195][_e199] = 0f;
                    break;
                }
            }
            switch bitcast<i32>(0u) {
                default: {
                    if (_e170 <= 8u) {
                        break;
                    }
                    storageBarrier();
                    workgroupBarrier();
                    textureBarrier();
                    workgroupBarrier();
                    if (_e166 < 64u) {
                        let _e4840 = local_128;
                        let _e4843 = local_129;
                        let _e4845 = global_8[_e4840][_e4843];
                        let _e4847 = local_130;
                        let _e4850 = local_131;
                        let _e4852 = global_9[_e4847][_e4850];
                        let _e4854 = local_132;
                        let _e4857 = local_133;
                        let _e4859 = global_10[_e4854][_e4857];
                        let _e4861 = local_134;
                        let _e4864 = local_135;
                        let _e4866 = global_11[_e4861][_e4864];
                        let _e4869 = local_136;
                        let _e4872 = local_137;
                        let _e4874 = global_8[_e4869][_e4872];
                        let _e4876 = local_138;
                        let _e4879 = local_139;
                        let _e4881 = global_9[_e4876][_e4879];
                        let _e4883 = local_140;
                        let _e4886 = local_141;
                        let _e4888 = global_10[_e4883][_e4886];
                        let _e4890 = local_142;
                        let _e4893 = local_143;
                        let _e4895 = global_11[_e4890][_e4893];
                        let _e4898 = local_144;
                        let _e4901 = local_145;
                        let _e4903 = global_8[_e4898][_e4901];
                        let _e4905 = local_146;
                        let _e4908 = local_147;
                        let _e4910 = global_9[_e4905][_e4908];
                        let _e4912 = local_148;
                        let _e4915 = local_149;
                        let _e4917 = global_10[_e4912][_e4915];
                        let _e4919 = local_150;
                        let _e4922 = local_151;
                        let _e4924 = global_11[_e4919][_e4922];
                        let _e4927 = local_152;
                        let _e4930 = local_153;
                        let _e4932 = global_8[_e4927][_e4930];
                        let _e4934 = local_154;
                        let _e4937 = local_155;
                        let _e4939 = global_9[_e4934][_e4937];
                        let _e4941 = local_156;
                        let _e4944 = local_157;
                        let _e4946 = global_10[_e4941][_e4944];
                        let _e4948 = local_158;
                        let _e4951 = local_159;
                        let _e4953 = global_11[_e4948][_e4951];
                        let _e4958 = ((((vec4<f32>(_e4845, _e4852, _e4859, _e4866) + vec4<f32>(_e4874, _e4881, _e4888, _e4895)) + vec4<f32>(_e4903, _e4910, _e4917, _e4924)) + vec4<f32>(_e4932, _e4939, _e4946, _e4953)) * 0.25f);
                        let _e4961 = local_160;
                        let _e4962 = (_e4961 + (_e199 % 2u));
                        let _e4966 = local_161;
                        global_8[_e4962][_e4966] = _e4958.x;
                        let _e4971 = local_162;
                        global_9[_e4962][_e4971] = _e4958.y;
                        let _e4976 = local_163;
                        global_10[_e4962][_e4976] = _e4958.z;
                        let _e4981 = local_164;
                        global_11[_e4962][_e4981] = _e4958.w;
                    }
                    if (_e170 <= 9u) {
                        break;
                    }
                    storageBarrier();
                    workgroupBarrier();
                    textureBarrier();
                    workgroupBarrier();
                    if (_e166 < 16u) {
                        let _e4985 = (_e195 * 4u);
                        let _e4986 = (_e199 * 4u);
                        let _e4987 = (_e4985 + 2u);
                        let _e4988 = (_e4985 + 1u);
                        let _e4989 = (_e4986 + 2u);
                        let _e4990 = (_e4985 + 3u);
                        let _e4993 = global_8[_e4985][_e4986];
                        let _e4996 = global_9[_e4985][_e4986];
                        let _e4999 = global_10[_e4985][_e4986];
                        let _e5002 = global_11[_e4985][_e4986];
                        let _e5006 = global_8[_e4987][_e4986];
                        let _e5009 = global_9[_e4987][_e4986];
                        let _e5012 = global_10[_e4987][_e4986];
                        let _e5015 = global_11[_e4987][_e4986];
                        let _e5019 = global_8[_e4988][_e4989];
                        let _e5022 = global_9[_e4988][_e4989];
                        let _e5025 = global_10[_e4988][_e4989];
                        let _e5028 = global_11[_e4988][_e4989];
                        let _e5032 = global_8[_e4990][_e4989];
                        let _e5035 = global_9[_e4990][_e4989];
                        let _e5038 = global_10[_e4990][_e4989];
                        let _e5041 = global_11[_e4990][_e4989];
                        let _e5046 = ((((vec4<f32>(_e4993, _e4996, _e4999, _e5002) + vec4<f32>(_e5006, _e5009, _e5012, _e5015)) + vec4<f32>(_e5019, _e5022, _e5025, _e5028)) + vec4<f32>(_e5032, _e5035, _e5038, _e5041)) * 0.25f);
                        let _e5047 = (_e4985 + _e199);
                        global_8[_e5047][_e4986] = _e5046.x;
                        global_9[_e5047][_e4986] = _e5046.y;
                        global_10[_e5047][_e4986] = _e5046.z;
                        global_11[_e5047][_e4986] = _e5046.w;
                    }
                    if (_e170 <= 10u) {
                        break;
                    }
                    storageBarrier();
                    workgroupBarrier();
                    textureBarrier();
                    workgroupBarrier();
                    if (_e166 < 4u) {
                        let _e5062 = (_e195 * 8u);
                        let _e5064 = local_165;
                        let _e5065 = (_e5062 + _e5064);
                        let _e5066 = (_e199 * 8u);
                        let _e5069 = local_166;
                        let _e5070 = ((_e5062 + 4u) + _e5069);
                        let _e5073 = local_167;
                        let _e5074 = ((_e5062 + 1u) + _e5073);
                        let _e5075 = (_e5066 + 4u);
                        let _e5078 = local_168;
                        let _e5079 = ((_e5062 + 5u) + _e5078);
                        let _e5082 = global_8[_e5065][_e5066];
                        let _e5085 = global_9[_e5065][_e5066];
                        let _e5088 = global_10[_e5065][_e5066];
                        let _e5091 = global_11[_e5065][_e5066];
                        let _e5095 = global_8[_e5070][_e5066];
                        let _e5098 = global_9[_e5070][_e5066];
                        let _e5101 = global_10[_e5070][_e5066];
                        let _e5104 = global_11[_e5070][_e5066];
                        let _e5108 = global_8[_e5074][_e5075];
                        let _e5111 = global_9[_e5074][_e5075];
                        let _e5114 = global_10[_e5074][_e5075];
                        let _e5117 = global_11[_e5074][_e5075];
                        let _e5121 = global_8[_e5079][_e5075];
                        let _e5124 = global_9[_e5079][_e5075];
                        let _e5127 = global_10[_e5079][_e5075];
                        let _e5130 = global_11[_e5079][_e5075];
                        let _e5135 = ((((vec4<f32>(_e5082, _e5085, _e5088, _e5091) + vec4<f32>(_e5095, _e5098, _e5101, _e5104)) + vec4<f32>(_e5108, _e5111, _e5114, _e5117)) + vec4<f32>(_e5121, _e5124, _e5127, _e5130)) * 0.25f);
                        let _e5137 = local_169;
                        let _e5138 = (_e195 + _e5137);
                        global_8[_e5138][0u] = _e5135.x;
                        global_9[_e5138][0u] = _e5135.y;
                        global_10[_e5138][0u] = _e5135.z;
                        global_11[_e5138][0u] = _e5135.w;
                    }
                    if (_e170 <= 11u) {
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
    global_12 = param;
    global_13 = param_1;
    function_();
}
