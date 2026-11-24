// Generated from mesh_mask_probes.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: 01c6799f8aa23ee3
// glsl-fnv1a64: d9703b0b70dba6d1

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
    var phi_20837_: vec3<f32>;
    var phi_20835_: f32;
    var local_28: vec3<f32>;
    var phi_20998_: vec2<f32>;
    var phi_20965_: f32;
    var phi_20934_: vec3<f32>;
    var phi_20838_: vec2<f32>;
    var phi_20839_: vec3<f32>;
    var phi_20848_: vec3<f32>;
    var phi_20847_: vec3<f32>;
    var phi_20844_: f32;
    var phi_3638_: bool;
    var phi_21034_: vec3<f32>;
    var phi_20849_: i32;
    var phi_5412_: bool;
    var local_29: i32;
    var local_30: i32;
    var local_31: i32;
    var phi_5525_: bool;
    var phi_5532_: bool;
    var phi_5539_: bool;
    var local_32: i32;
    var local_33: i32;
    var local_34: i32;
    var phi_20854_: f32;
    var phi_20851_: i32;
    var phi_20860_: f32;
    var phi_20857_: i32;
    var local_35: f32;
    var phi_20861_: f32;
    var phi_20862_: f32;
    var local_36: i32;
    var local_37: i32;
    var local_38: i32;
    var phi_5812_: bool;
    var phi_5819_: bool;
    var phi_5826_: bool;
    var phi_20874_: f32;
    var phi_20871_: i32;
    var phi_20880_: f32;
    var phi_20877_: i32;
    var local_39: f32;
    var phi_20881_: f32;
    var phi_20882_: f32;
    var phi_20903_: f32;
    var phi_20900_: vec3<f32>;
    var phi_20902_: f32;
    var phi_20899_: vec3<f32>;
    var phi_20905_: vec3<f32>;
    var phi_20904_: f32;
    var phi_21068_: f32;
    var phi_21028_: vec3<f32>;
    var phi_20957_: f32;
    var phi_21158_: f32;
    var phi_21685_: vec3<f32>;
    var phi_21684_: i32;
    var local_40: vec3<f32>;
    var phi_21686_: vec3<f32>;
    var phi_21696_: vec3<f32>;
    var phi_21695_: i32;
    var local_41: vec3<f32>;
    var phi_21697_: vec3<f32>;
    var phi_21703_: vec3<f32>;
    var phi_21702_: i32;
    var phi_22090_: f32;
    var phi_22128_: vec3<f32>;
    var phi_22127_: vec3<f32>;
    var local_42: vec3<f32>;
    var phi_21713_: vec3<f32>;
    var phi_21714_: vec3<f32>;
    var phi_21710_: u32;
    var phi_9377_: bool;
    var phi_9384_: bool;
    var phi_9391_: bool;
    var phi_9398_: bool;
    var phi_21996_: f32;
    var phi_21993_: i32;
    var phi_22002_: f32;
    var phi_21999_: i32;
    var local_43: f32;
    var phi_22003_: f32;
    var phi_9468_: bool;
    var phi_21981_: i32;
    var phi_21980_: i32;
    var phi_21978_: f32;
    var phi_21985_: f32;
    var phi_21982_: i32;
    var phi_21991_: f32;
    var phi_21988_: i32;
    var local_44: f32;
    var phi_21992_: f32;
    var phi_22004_: f32;
    var phi_22055_: vec3<f32>;
    var phi_21712_: vec3<f32>;
    var phi_21029_: f32;
    var phi_21024_: f32;
    var phi_21058_: vec3<f32>;
    var phi_21057_: vec3<f32>;
    var phi_21062_: f32;
    var phi_21061_: f32;
    var phi_21172_: vec3<f32>;
    var phi_21080_: vec3<f32>;
    var phi_21079_: i32;
    var local_45: vec3<f32>;
    var phi_21083_: i32;
    var phi_21084_: i32;
    var phi_21090_: i32;
    var phi_21091_: i32;
    var phi_21134_: vec3<f32>;
    var phi_21122_: vec2<f32>;
    var phi_21098_: vec3<f32>;
    var phi_4149_: bool;
    var phi_21118_: f32;
    var phi_21117_: vec3<f32>;
    var phi_21116_: i32;
    var local_46: vec3<f32>;
    var local_47: f32;
    var phi_21119_: vec3<f32>;
    var phi_21143_: vec3<f32>;
    var phi_21179_: vec3<f32>;
    var phi_21178_: i32;
    var phi_21679_: f32;
    var phi_22098_: vec3<f32>;
    var phi_22097_: vec3<f32>;
    var phi_21180_: vec3<f32>;
    var phi_21203_: i32;
    var phi_21204_: i32;
    var phi_21210_: i32;
    var phi_21211_: i32;
    var phi_21217_: vec3<f32>;
    var phi_21299_: vec3<f32>;
    var phi_21233_: f32;
    var phi_21232_: i32;
    var phi_21234_: f32;
    var phi_21235_: vec3<f32>;
    var phi_21236_: vec3<f32>;
    var phi_21237_: i32;
    var phi_21238_: i32;
    var phi_21244_: vec2<u32>;
    var phi_21246_: vec2<u32>;
    var phi_21249_: vec2<u32>;
    var phi_21250_: vec2<u32>;
    var phi_21251_: i32;
    var phi_21252_: i32;
    var phi_21258_: vec2<u32>;
    var phi_21260_: vec2<u32>;
    var phi_21263_: vec2<u32>;
    var phi_21264_: vec2<u32>;
    var phi_22112_: vec3<f32>;
    var phi_22111_: f32;
    var local_48: f32;
    var local_49: vec3<f32>;
    var phi_4267_: bool;
    var phi_21374_: f32;
    var phi_21373_: vec3<f32>;
    var phi_21372_: i32;
    var local_50: vec3<f32>;
    var local_51: f32;
    var phi_21375_: vec3<f32>;
    var phi_21409_: vec3<f32>;
    var phi_21408_: vec3<f32>;
    var phi_21645_: vec3<f32>;
    var phi_21644_: vec3<f32>;
    var phi_21510_: u32;
    var phi_15354_: bool;
    var phi_15361_: bool;
    var phi_15368_: bool;
    var phi_15375_: bool;
    var phi_21529_: f32;
    var phi_21526_: i32;
    var phi_21535_: f32;
    var phi_21532_: i32;
    var local_52: f32;
    var phi_21536_: f32;
    var phi_15445_: bool;
    var phi_21514_: i32;
    var phi_21513_: i32;
    var phi_21511_: f32;
    var phi_21518_: f32;
    var phi_21515_: i32;
    var phi_21524_: f32;
    var phi_21521_: i32;
    var local_53: f32;
    var phi_21525_: f32;
    var phi_21537_: f32;
    var phi_21642_: vec3<f32>;
    var phi_21715_: vec3<f32>;
    var phi_21711_: vec3<f32>;
    var phi_21794_: f32;
    var phi_21797_: f32;
    var phi_21807_: vec3<f32>;
    var phi_21806_: i32;
    var local_54: vec3<f32>;
    var phi_21808_: vec3<f32>;
    var phi_21812_: vec3<f32>;
    var phi_21811_: i32;
    var phi_21973_: f32;
    var phi_22142_: vec3<f32>;
    var phi_22141_: vec3<f32>;
    var phi_21813_: vec3<f32>;
    var phi_21844_: vec3<f32>;
    var phi_21845_: vec3<f32>;
    var phi_21972_: vec2<f32>;
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
    let _e293 = global_8.member[3u];
    let _e298 = global_8.member_6[0u];
    if ((_e293 * _e282.w) < _e298) {
        discard;
    }
    let _e301 = global_22[3u];
    let _e304 = global_8.member_1[0u];
    phi_20837_ = _e290;
    if (_e304 > 0.5f) {
        let _e306 = global_13;
        let _e309 = floor((_e306.xz * vec2<f32>(0.5f, 0.5f)));
        let _e313 = abs((_e309.x + _e309.y));
        phi_20837_ = (_e290 * select(0.75f, 1f, ((_e313 - (floor((_e313 / 2f)) * 2f)) < 0.5f)));
    }
    let _e322 = phi_20837_;
    let _e325 = global_8.member_3[3u];
    phi_20998_ = vec2<f32>(0f, 0f);
    phi_20965_ = 0f;
    phi_20934_ = _e322;
    if (_e325 > 0.5f) {
        switch bitcast<i32>(0u) {
            default: {
                let _e330 = global_8.member_2[3u];
                let _e332 = vec4<f32>(_e330, _e325, 0f, 0f).xyy;
                let _e334 = floor((_e332 * vec3<f32>(0.000015258789f, 0.000015258789f, 0.000015258789f)));
                let _e336 = (_e332 - (_e334 * 65536f));
                let _e338 = floor((_e336 * vec3<f32>(0.00390625f, 0.00390625f, 0.00390625f)));
                let _e340 = (_e336 - (_e338 * 256f));
                let _e352 = (_e334.y - 128f);
                let _e359 = (floor((_e352 * 0.03125f)) * 0.33333334f);
                let _e363 = global_9;
                let _e364 = normalize(_e363);
                let _e365 = global_10;
                let _e366 = _e365.xyz;
                let _e367 = dot(_e364, _e366);
                let _e373 = ((_e367 / max(length((_e366 - (_e364 * _e367))), 0.000001f)) * 25.5f);
                local_28 = ((vec3<f32>(_e340.x, _e338.x, _e334.x) * vec3<f32>(0.003921569f, 0.003921569f, 0.003921569f)) * 2f);
                local_55 = (vec2<f32>(_e340.y, _e338.y) * vec2<f32>(0.003921569f, 0.003921569f));
                if ((-24f + _e373) < -2f) {
                    phi_20835_ = 0f;
                    break;
                }
                let _e376 = global_11;
                let _e377 = (_e376 * (4f * exp2(((_e352 - (floor((_e352 / 32f)) * 32f)) * 0.33333334f))));
                let _e378 = floor(_e377);
                let _e379 = (_e377 - _e378);
                let _e383 = ((_e379 * _e379) * (vec3<f32>(3f, 3f, 3f) - (_e379 * 2f)));
                let _e385 = bitcast<vec3<u32>>(vec3<i32>(_e378));
                let _e394 = ((((_e385.x * 1597334677u) ^ (_e385.y * 3812015801u)) ^ (_e385.z * 2798796415u)) * 1597334677u);
                let _e403 = bitcast<vec3<u32>>(vec3<i32>((_e378 + vec3<f32>(1f, 0f, 0f))));
                let _e412 = ((((_e403.x * 1597334677u) ^ (_e403.y * 3812015801u)) ^ (_e403.z * 2798796415u)) * 1597334677u);
                let _e423 = bitcast<vec3<u32>>(vec3<i32>((_e378 + vec3<f32>(0f, 1f, 0f))));
                let _e432 = ((((_e423.x * 1597334677u) ^ (_e423.y * 3812015801u)) ^ (_e423.z * 2798796415u)) * 1597334677u);
                let _e441 = bitcast<vec3<u32>>(vec3<i32>((_e378 + vec3<f32>(1f, 1f, 0f))));
                let _e450 = ((((_e441.x * 1597334677u) ^ (_e441.y * 3812015801u)) ^ (_e441.z * 2798796415u)) * 1597334677u);
                let _e462 = bitcast<vec3<u32>>(vec3<i32>((_e378 + vec3<f32>(0f, 0f, 1f))));
                let _e471 = ((((_e462.x * 1597334677u) ^ (_e462.y * 3812015801u)) ^ (_e462.z * 2798796415u)) * 1597334677u);
                let _e480 = bitcast<vec3<u32>>(vec3<i32>((_e378 + vec3<f32>(1f, 0f, 1f))));
                let _e489 = ((((_e480.x * 1597334677u) ^ (_e480.y * 3812015801u)) ^ (_e480.z * 2798796415u)) * 1597334677u);
                let _e499 = bitcast<vec3<u32>>(vec3<i32>((_e378 + vec3<f32>(0f, 1f, 1f))));
                let _e508 = ((((_e499.x * 1597334677u) ^ (_e499.y * 3812015801u)) ^ (_e499.z * 2798796415u)) * 1597334677u);
                let _e517 = bitcast<vec3<u32>>(vec3<i32>((_e378 + vec3<f32>(1f, 1f, 1f))));
                let _e526 = ((((_e517.x * 1597334677u) ^ (_e517.y * 3812015801u)) ^ (_e517.z * 2798796415u)) * 1597334677u);
                let _e539 = ((_e377 * 2.7f) + vec3<f32>(17.3f, 5.1f, 9.7f));
                let _e540 = floor(_e539);
                let _e541 = (_e539 - _e540);
                let _e545 = ((_e541 * _e541) * (vec3<f32>(3f, 3f, 3f) - (_e541 * 2f)));
                let _e547 = bitcast<vec3<u32>>(vec3<i32>(_e540));
                let _e556 = ((((_e547.x * 1597334677u) ^ (_e547.y * 3812015801u)) ^ (_e547.z * 2798796415u)) * 1597334677u);
                let _e565 = bitcast<vec3<u32>>(vec3<i32>((_e540 + vec3<f32>(1f, 0f, 0f))));
                let _e574 = ((((_e565.x * 1597334677u) ^ (_e565.y * 3812015801u)) ^ (_e565.z * 2798796415u)) * 1597334677u);
                let _e585 = bitcast<vec3<u32>>(vec3<i32>((_e540 + vec3<f32>(0f, 1f, 0f))));
                let _e594 = ((((_e585.x * 1597334677u) ^ (_e585.y * 3812015801u)) ^ (_e585.z * 2798796415u)) * 1597334677u);
                let _e603 = bitcast<vec3<u32>>(vec3<i32>((_e540 + vec3<f32>(1f, 1f, 0f))));
                let _e612 = ((((_e603.x * 1597334677u) ^ (_e603.y * 3812015801u)) ^ (_e603.z * 2798796415u)) * 1597334677u);
                let _e624 = bitcast<vec3<u32>>(vec3<i32>((_e540 + vec3<f32>(0f, 0f, 1f))));
                let _e633 = ((((_e624.x * 1597334677u) ^ (_e624.y * 3812015801u)) ^ (_e624.z * 2798796415u)) * 1597334677u);
                let _e642 = bitcast<vec3<u32>>(vec3<i32>((_e540 + vec3<f32>(1f, 0f, 1f))));
                let _e651 = ((((_e642.x * 1597334677u) ^ (_e642.y * 3812015801u)) ^ (_e642.z * 2798796415u)) * 1597334677u);
                let _e661 = bitcast<vec3<u32>>(vec3<i32>((_e540 + vec3<f32>(0f, 1f, 1f))));
                let _e670 = ((((_e661.x * 1597334677u) ^ (_e661.y * 3812015801u)) ^ (_e661.z * 2798796415u)) * 1597334677u);
                let _e679 = bitcast<vec3<u32>>(vec3<i32>((_e540 + vec3<f32>(1f, 1f, 1f))));
                let _e688 = ((((_e679.x * 1597334677u) ^ (_e679.y * 3812015801u)) ^ (_e679.z * 2798796415u)) * 1597334677u);
                let _e701 = mix(0.45f, 0.05f, _e359);
                phi_20835_ = smoothstep(-(_e701), _e701, ((_e373 + -24.45f) + ((((mix(mix(mix((f32(((_e394 ^ (_e394 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e412 ^ (_e412 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e383.x), mix((f32(((_e432 ^ (_e432 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e450 ^ (_e450 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e383.x), _e383.y), mix(mix((f32(((_e471 ^ (_e471 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e489 ^ (_e489 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e383.x), mix((f32(((_e508 ^ (_e508 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e526 ^ (_e526 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e383.x), _e383.y), _e383.z) * 0.65f) + (mix(mix(mix((f32(((_e556 ^ (_e556 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e574 ^ (_e574 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e545.x), mix((f32(((_e594 ^ (_e594 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e612 ^ (_e612 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e545.x), _e545.y), mix(mix((f32(((_e633 ^ (_e633 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e651 ^ (_e651 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e545.x), mix((f32(((_e670 ^ (_e670 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e688 ^ (_e688 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e545.x), _e545.y), _e545.z) * 0.35f)) - 0.5f) * mix(0.8f, 2.2f, _e359))));
                break;
            }
        }
        let _e710 = phi_20835_;
        let _e712 = local_28;
        let _e7745 = local_55;
        phi_20998_ = _e7745;
        phi_20965_ = _e710;
        phi_20934_ = mix(_e322, ((_e284 * _e712) * mix(vec3<f32>(1f, 1f, 1f), (_e289 * 2f), vec3<f32>(0.5f, 0.5f, 0.5f))), vec3(_e710));
    }
    let _e720 = phi_20998_;
    let _e722 = phi_20965_;
    let _e724 = phi_20934_;
    let _e725 = global_9;
    let _e726 = normalize(_e725);
    let _e729 = global_8.member_6[1u];
    phi_20847_ = _e726;
    if (_e729 > 0.5f) {
        let _e731 = global_10;
        let _e732 = _e731.xyz;
        let _e735 = (_e732 - (_e726 * dot(_e726, _e732)));
        phi_20848_ = _e726;
        if (dot(_e735, _e735) > 0.000000000001f) {
            let _e738 = normalize(_e735);
            let _e741 = global_10[3u];
            let _e745 = textureSample(global_23, global_5, _e281);
            let _e748 = global_8.member_6[2u];
            if (_e748 > 0.5f) {
                if (_e748 > 1.5f) {
                    phi_20838_ = _e745.xw;
                } else {
                    phi_20838_ = _e745.xy;
                }
                let _e754 = phi_20838_;
                let _e756 = ((_e754 * 2f) - vec2<f32>(1f, 1f));
                phi_20839_ = vec3<f32>(_e756.x, _e756.y, sqrt(clamp((1f - dot(_e756, _e756)), 0f, 1f)));
            } else {
                phi_20839_ = ((_e745.xyz * 2f) - vec3<f32>(1f, 1f, 1f));
            }
            let _e768 = phi_20839_;
            let _e771 = global_8.member_4[2u];
            let _e773 = (_e768.xy * _e771);
            phi_20848_ = normalize((((_e738 * _e773.x) + ((cross(_e726, _e738) * select(1f, -1f, (_e741 < 0f))) * _e773.y)) + (_e726 * _e768.z)));
        }
        let _e784 = phi_20848_;
        phi_20847_ = _e784;
    }
    let _e786 = phi_20847_;
    let _e789 = global_8.member_5[3u];
    let _e790 = (_e789 > 0.5f);
    if _e790 {
        let _e793 = global_8.member_1[2u];
        phi_20844_ = clamp(_e793, 0f, 1f);
    } else {
        phi_20844_ = 0f;
    }
    let _e796 = phi_20844_;
    phi_3638_ = _e790;
    if _e790 {
        let _e797 = global_24;
        phi_3638_ = !(_e797);
    }
    let _e800 = phi_3638_;
    phi_21034_ = _e786;
    if (_e800 && (_e796 <= 0f)) {
        phi_21034_ = -(_e786);
    }
    let _e805 = phi_21034_;
    let _e807 = global.member_4;
    let _e809 = normalize(_e807.xyz);
    let _e811 = global.member_6;
    let _e812 = _e811.xyz;
    let _e813 = global_13;
    let _e814 = (_e812 - _e813);
    let _e815 = normalize(_e814);
    let _e817 = normalize((_e809 + _e815));
    let _e818 = global_24;
    let _e820 = (_e726 * select(-1f, 1f, _e818));
    let _e822 = global_25[0u];
    let _e823 = (_e822 > 0.5f);
    let _e826 = global.member_5[3u];
    phi_21068_ = 1f;
    phi_21028_ = _e724;
    if ((_e826 > 0.5f) && _e823) {
        switch bitcast<i32>(0u) {
            default: {
                let _e832 = global.member_21[0u];
                let _e833 = i32(_e832);
                let _e835 = global.member_20;
                let _e840 = global.member_20[3u];
                let _e841 = (dot(_e835.xyz, _e813) + _e840);
                phi_20849_ = 0i;
                loop {
                    let _e843 = phi_20849_;
                    local_29 = _e843;
                    local_30 = _e843;
                    local_31 = _e843;
                    local_32 = _e843;
                    local_33 = _e843;
                    local_34 = _e843;
                    local_36 = _e843;
                    local_37 = _e843;
                    local_38 = _e843;
                    let _e845 = (_e843 < (_e833 - 1i));
                    phi_5412_ = _e845;
                    if _e845 {
                        let _e848 = global.member_16[_e843];
                        phi_5412_ = (_e841 > _e848);
                    }
                    let _e851 = phi_5412_;
                    if _e851 {
                        continue;
                    } else {
                        break;
                    }
                    continuing {
                        phi_20849_ = (_e843 + 1i);
                    }
                }
                let _e855 = local_29;
                let _e857 = global.member_16[_e855];
                if (_e841 > _e857) {
                    phi_20905_ = vec3<f32>(1f, 1f, 1f);
                    phi_20904_ = 1f;
                    break;
                }
                let _e861 = local_30;
                let _e863 = global.member_18[_e861];
                let _e865 = (_e813 + (_e820 * _e863));
                switch bitcast<i32>(0u) {
                    default: {
                        let _e869 = local_31;
                        let _e871 = global.member_14[_e869];
                        let _e876 = (_e871 * vec4<f32>(_e865.x, _e865.y, _e865.z, 1f));
                        let _e878 = (_e876.x < 0f);
                        phi_5525_ = _e878;
                        if !(_e878) {
                            phi_5525_ = (_e876.x > 1f);
                        }
                        let _e882 = phi_5525_;
                        phi_5532_ = _e882;
                        if !(_e882) {
                            phi_5532_ = (_e876.y < 0f);
                        }
                        let _e887 = phi_5532_;
                        phi_5539_ = _e887;
                        if !(_e887) {
                            phi_5539_ = (_e876.y > 1f);
                        }
                        let _e892 = phi_5539_;
                        if _e892 {
                            phi_20862_ = 1f;
                            break;
                        }
                        let _e894 = local_32;
                        let _e898 = local_33;
                        let _e904 = global.member_23;
                        let _e905 = _e904.xy;
                        let _e906 = (vec2<f32>(f32((_e894 & 1i)), f32((_e898 >> bitcast<u32>(1i)))) * _e905);
                        let _e911 = local_34;
                        let _e913 = global.member_19[_e911];
                        let _e914 = (min(_e876.z, 1f) - _e913);
                        let _e917 = global.member_22;
                        let _e918 = _e917.xy;
                        let _e919 = (_e918 * 0.5f);
                        let _e921 = (_e906 + (_e876.xy * _e905));
                        let _e922 = (_e906 + _e919);
                        let _e924 = ((_e906 + _e905) - _e919);
                        let _e929 = vec4<f32>(_e922.x, _e922.y, _e924.x, _e924.y);
                        switch bitcast<i32>(0u) {
                            default: {
                                let _e933 = global.member_22[2u];
                                let _e934 = i32(_e933);
                                if (_e934 <= 0i) {
                                    let _e938 = clamp(_e921, _e929.xy, _e929.zw);
                                    let _e943 = textureSampleCompare(global_2, global_1, vec3<f32>(_e938.x, _e938.y, _e914).xy, _e914);
                                    phi_20861_ = _e943;
                                    break;
                                }
                                let _e945 = ((_e921 / _e918) + vec2<f32>(0.5f, 0.5f));
                                let _e946 = floor(_e945);
                                let _e947 = (_e945 - _e946);
                                let _e949 = (_e934 == 1i);
                                if _e949 {
                                    let _e950 = (_e947 * 2f);
                                    local_24[0i] = (vec2<f32>(3f, 3f) - _e950);
                                    local_24[1i] = (vec2<f32>(1f, 1f) + _e950);
                                    let _e956 = local_24[0i];
                                    local_25[0i] = (((vec2<f32>(2f, 2f) - _e947) / _e956) - vec2<f32>(1f, 1f));
                                    let _e960 = local_24[1i];
                                    local_25[1i] = ((_e947 / _e960) + vec2<f32>(1f, 1f));
                                } else {
                                    let _e964 = (_e947 * 3f);
                                    local_24[0i] = (vec2<f32>(4f, 4f) - _e964);
                                    local_24[1i] = vec2<f32>(7f, 7f);
                                    local_24[2i] = (vec2<f32>(1f, 1f) + _e964);
                                    let _e972 = local_24[0i];
                                    local_25[0i] = (((vec2<f32>(3f, 3f) - (_e947 * 2f)) / _e972) - vec2<f32>(2f, 2f));
                                    let _e977 = local_24[1i];
                                    local_25[1i] = ((vec2<f32>(3f, 3f) + _e947) / _e977);
                                    let _e980 = local_24[2i];
                                    local_25[2i] = ((_e947 / _e980) + vec2<f32>(2f, 2f));
                                }
                                let _e985 = select(3i, 2i, _e949);
                                phi_20854_ = 0f;
                                phi_20851_ = 0i;
                                loop {
                                    let _e987 = phi_20854_;
                                    let _e989 = phi_20851_;
                                    local_35 = _e987;
                                    if (_e989 < _e985) {
                                        phi_20860_ = _e987;
                                        phi_20857_ = 0i;
                                        loop {
                                            let _e992 = phi_20860_;
                                            let _e994 = phi_20857_;
                                            local_56 = _e992;
                                            if (_e994 < _e985) {
                                                continue;
                                            } else {
                                                break;
                                            }
                                            continuing {
                                                let _e998 = local_25[_e994][0u];
                                                let _e1001 = local_25[_e989][1u];
                                                let _e1007 = clamp((_e918 * ((_e946 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e998, _e1001))), _e929.xy, _e929.zw);
                                                let _e1010 = local_24[_e994][0u];
                                                let _e1013 = local_24[_e989][1u];
                                                let _e1019 = textureSampleCompare(global_2, global_1, vec3<f32>(_e1007.x, _e1007.y, _e914).xy, _e914);
                                                phi_20860_ = (_e992 + ((_e1010 * _e1013) * _e1019));
                                                phi_20857_ = (_e994 + 1i);
                                            }
                                        }
                                        continue;
                                    } else {
                                        break;
                                    }
                                    continuing {
                                        let _e7768 = local_56;
                                        phi_20854_ = _e7768;
                                        phi_20851_ = (_e989 + 1i);
                                    }
                                }
                                let _e1025 = local_35;
                                phi_20861_ = (_e1025 * select(0.0069444445f, 0.0625f, _e949));
                                break;
                            }
                        }
                        let _e1028 = phi_20861_;
                        phi_20862_ = _e1028;
                        break;
                    }
                }
                let _e1030 = phi_20862_;
                local_26 = array<vec3<f32>, 4>(vec3<f32>(1f, 0.45f, 0.45f), vec3<f32>(0.45f, 1f, 0.45f), vec3<f32>(0.5f, 0.6f, 1f), vec3<f32>(1f, 1f, 0.4f));
                let _e1032 = local_36;
                let _e1034 = local_26[_e1032];
                let _e1037 = local_37;
                let _e1039 = global.member_17[_e1037];
                phi_20902_ = _e1030;
                phi_20899_ = _e1034;
                if (_e841 > _e1039) {
                    let _e1043 = ((_e841 - _e1039) / (_e857 - _e1039));
                    let _e1045 = local_38;
                    let _e1046 = (_e1045 + 1i);
                    if (_e1046 < _e833) {
                        let _e1050 = global.member_18[_e1046];
                        let _e1052 = (_e813 + (_e820 * _e1050));
                        switch bitcast<i32>(0u) {
                            default: {
                                let _e1056 = global.member_14[_e1046];
                                let _e1061 = (_e1056 * vec4<f32>(_e1052.x, _e1052.y, _e1052.z, 1f));
                                let _e1063 = (_e1061.x < 0f);
                                phi_5812_ = _e1063;
                                if !(_e1063) {
                                    phi_5812_ = (_e1061.x > 1f);
                                }
                                let _e1067 = phi_5812_;
                                phi_5819_ = _e1067;
                                if !(_e1067) {
                                    phi_5819_ = (_e1061.y < 0f);
                                }
                                let _e1072 = phi_5819_;
                                phi_5826_ = _e1072;
                                if !(_e1072) {
                                    phi_5826_ = (_e1061.y > 1f);
                                }
                                let _e1077 = phi_5826_;
                                if _e1077 {
                                    phi_20882_ = 1f;
                                    break;
                                }
                                let _e1085 = global.member_23;
                                let _e1086 = _e1085.xy;
                                let _e1087 = (vec2<f32>(f32((_e1046 & 1i)), f32((_e1046 >> bitcast<u32>(1i)))) * _e1086);
                                let _e1092 = global.member_19[_e1046];
                                let _e1093 = (min(_e1061.z, 1f) - _e1092);
                                let _e1096 = global.member_22;
                                let _e1097 = _e1096.xy;
                                let _e1098 = (_e1097 * 0.5f);
                                let _e1100 = (_e1087 + (_e1061.xy * _e1086));
                                let _e1101 = (_e1087 + _e1098);
                                let _e1103 = ((_e1087 + _e1086) - _e1098);
                                let _e1108 = vec4<f32>(_e1101.x, _e1101.y, _e1103.x, _e1103.y);
                                switch bitcast<i32>(0u) {
                                    default: {
                                        let _e1112 = global.member_22[2u];
                                        let _e1113 = i32(_e1112);
                                        if (_e1113 <= 0i) {
                                            let _e1117 = clamp(_e1100, _e1108.xy, _e1108.zw);
                                            let _e1122 = textureSampleCompare(global_2, global_1, vec3<f32>(_e1117.x, _e1117.y, _e1093).xy, _e1093);
                                            phi_20881_ = _e1122;
                                            break;
                                        }
                                        let _e1124 = ((_e1100 / _e1097) + vec2<f32>(0.5f, 0.5f));
                                        let _e1125 = floor(_e1124);
                                        let _e1126 = (_e1124 - _e1125);
                                        let _e1128 = (_e1113 == 1i);
                                        if _e1128 {
                                            let _e1129 = (_e1126 * 2f);
                                            local_22[0i] = (vec2<f32>(3f, 3f) - _e1129);
                                            local_22[1i] = (vec2<f32>(1f, 1f) + _e1129);
                                            let _e1135 = local_22[0i];
                                            local_23[0i] = (((vec2<f32>(2f, 2f) - _e1126) / _e1135) - vec2<f32>(1f, 1f));
                                            let _e1139 = local_22[1i];
                                            local_23[1i] = ((_e1126 / _e1139) + vec2<f32>(1f, 1f));
                                        } else {
                                            let _e1143 = (_e1126 * 3f);
                                            local_22[0i] = (vec2<f32>(4f, 4f) - _e1143);
                                            local_22[1i] = vec2<f32>(7f, 7f);
                                            local_22[2i] = (vec2<f32>(1f, 1f) + _e1143);
                                            let _e1151 = local_22[0i];
                                            local_23[0i] = (((vec2<f32>(3f, 3f) - (_e1126 * 2f)) / _e1151) - vec2<f32>(2f, 2f));
                                            let _e1156 = local_22[1i];
                                            local_23[1i] = ((vec2<f32>(3f, 3f) + _e1126) / _e1156);
                                            let _e1159 = local_22[2i];
                                            local_23[2i] = ((_e1126 / _e1159) + vec2<f32>(2f, 2f));
                                        }
                                        let _e1164 = select(3i, 2i, _e1128);
                                        phi_20874_ = 0f;
                                        phi_20871_ = 0i;
                                        loop {
                                            let _e1166 = phi_20874_;
                                            let _e1168 = phi_20871_;
                                            local_39 = _e1166;
                                            if (_e1168 < _e1164) {
                                                phi_20880_ = _e1166;
                                                phi_20877_ = 0i;
                                                loop {
                                                    let _e1171 = phi_20880_;
                                                    let _e1173 = phi_20877_;
                                                    local_57 = _e1171;
                                                    if (_e1173 < _e1164) {
                                                        continue;
                                                    } else {
                                                        break;
                                                    }
                                                    continuing {
                                                        let _e1177 = local_23[_e1173][0u];
                                                        let _e1180 = local_23[_e1168][1u];
                                                        let _e1186 = clamp((_e1097 * ((_e1125 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e1177, _e1180))), _e1108.xy, _e1108.zw);
                                                        let _e1189 = local_22[_e1173][0u];
                                                        let _e1192 = local_22[_e1168][1u];
                                                        let _e1198 = textureSampleCompare(global_2, global_1, vec3<f32>(_e1186.x, _e1186.y, _e1093).xy, _e1093);
                                                        phi_20880_ = (_e1171 + ((_e1189 * _e1192) * _e1198));
                                                        phi_20877_ = (_e1173 + 1i);
                                                    }
                                                }
                                                continue;
                                            } else {
                                                break;
                                            }
                                            continuing {
                                                let _e7783 = local_57;
                                                phi_20874_ = _e7783;
                                                phi_20871_ = (_e1168 + 1i);
                                            }
                                        }
                                        let _e1204 = local_39;
                                        phi_20881_ = (_e1204 * select(0.0069444445f, 0.0625f, _e1128));
                                        break;
                                    }
                                }
                                let _e1207 = phi_20881_;
                                phi_20882_ = _e1207;
                                break;
                            }
                        }
                        let _e1209 = phi_20882_;
                        local_27 = array<vec3<f32>, 4>(vec3<f32>(1f, 0.45f, 0.45f), vec3<f32>(0.45f, 1f, 0.45f), vec3<f32>(0.5f, 0.6f, 1f), vec3<f32>(1f, 1f, 0.4f));
                        let _e1212 = local_27[_e1046];
                        phi_20903_ = mix(_e1030, _e1209, _e1043);
                        phi_20900_ = mix(_e1034, _e1212, vec3(_e1043));
                    } else {
                        phi_20903_ = mix(_e1030, 1f, _e1043);
                        phi_20900_ = _e1034;
                    }
                    let _e1217 = phi_20903_;
                    let _e1219 = phi_20900_;
                    phi_20902_ = _e1217;
                    phi_20899_ = _e1219;
                }
                let _e1221 = phi_20902_;
                let _e1223 = phi_20899_;
                let _e1226 = global.member_22[3u];
                phi_20905_ = select(vec3<f32>(1f, 1f, 1f), _e1223, vec3((_e1226 > 0.5f)));
                phi_20904_ = _e1221;
                break;
            }
        }
        let _e1231 = phi_20905_;
        let _e1233 = phi_20904_;
        phi_21068_ = _e1233;
        phi_21028_ = (_e724 * _e1231);
    }
    let _e1236 = phi_21068_;
    let _e1238 = phi_21028_;
    let _e1240 = global.member_5;
    let _e1244 = global.member_4[3u];
    let _e1245 = (_e1240.xyz * _e1244);
    let _e1248 = global_8.member_6[3u];
    let _e1249 = (_e1248 > 0.5f);
    if _e1249 {
        phi_20957_ = 1f;
    } else {
        let _e1252 = global_8.member_4[3u];
        let _e1253 = textureSample(global_19, global_5, _e281);
        phi_20957_ = (1f + (_e1252 * (_e1253.x - 1f)));
    }
    let _e1259 = phi_20957_;
    let _e1261 = global_10[3u];
    let _e1262 = abs(_e1261);
    phi_21158_ = _e1259;
    if (_e1262 > 0f) {
        phi_21158_ = (_e1259 * min(_e1262, 1f));
    }
    let _e1267 = phi_21158_;
    if !(_e790) {
        let _e1269 = dot(_e805, _e809);
        let _e1276 = global_8.member_1[3u];
        let _e1280 = global_8.member_1[2u];
        let _e1287 = global.member_29[0u];
        let _e1288 = (_e1287 > 0.5f);
        if _e1288 {
            let _e1290 = global.member_29;
            let _e1297 = ((_e1290.z * _e805.x) - (_e1290.w * _e805.z));
            let _e1301 = ((_e1290.w * _e805.x) + (_e1290.z * _e805.z));
            let _e1305 = (1.092548f * _e1297);
            local_21 = array<f32, 9>(0.282095f, (0.488603f * _e805.y), (0.488603f * _e1301), (0.488603f * _e1297), (_e1305 * _e805.y), ((1.092548f * _e805.y) * _e1301), (0.315392f * (((3f * _e1301) * _e1301) - 1f)), (_e1305 * _e1301), (0.546274f * ((_e1297 * _e1297) - (_e805.y * _e805.y))));
            phi_21685_ = vec3<f32>(0f, 0f, 0f);
            phi_21684_ = 0i;
            loop {
                let _e1320 = phi_21685_;
                let _e1322 = phi_21684_;
                local_40 = _e1320;
                if (_e1322 < 9i) {
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e1326 = textureLoad(global_4, (vec2<i32>(496i, 256i) + vec2<i32>(_e1322, 0i)), 0i);
                    let _e1329 = local_21[_e1322];
                    phi_21685_ = (_e1320 + (_e1326.xyz * _e1329));
                    phi_21684_ = (_e1322 + 1i);
                }
            }
            let _e1334 = local_40;
            let _e1338 = global.member_29[1u];
            phi_21686_ = (max(_e1334, vec3<f32>(0f, 0f, 0f)) * _e1338);
        } else {
            let _e1341 = global.member_9;
            let _e1344 = global.member_8;
            let _e1353 = global.member_8[3u];
            phi_21686_ = (mix(_e1341.xyz, _e1344.xyz, vec3(((_e805.y * 0.5f) + 0.5f))) * _e1353);
        }
        let _e1356 = phi_21686_;
        let _e1362 = ((_e1238 * ((_e1356 * _e1267) + ((_e1245 * max(_e1269, 0f)) * _e1236))) + ((_e1245 * ((pow(max(dot(_e805, _e817), 0f), _e1276) * _e1280) * step(0f, _e1269))) * _e1236));
        let _e1365 = global.member_34[1u];
        phi_21713_ = _e1362;
        if (_e1365 > 0.5f) {
            if _e1288 {
                let _e1368 = global.member_29;
                let _e1375 = ((_e1368.z * _e805.x) - (_e1368.w * _e805.z));
                let _e1379 = ((_e1368.w * _e805.x) + (_e1368.z * _e805.z));
                let _e1383 = (1.092548f * _e1375);
                local_20 = array<f32, 9>(0.282095f, (0.488603f * _e805.y), (0.488603f * _e1379), (0.488603f * _e1375), (_e1383 * _e805.y), ((1.092548f * _e805.y) * _e1379), (0.315392f * (((3f * _e1379) * _e1379) - 1f)), (_e1383 * _e1379), (0.546274f * ((_e1375 * _e1375) - (_e805.y * _e805.y))));
                phi_21696_ = vec3<f32>(0f, 0f, 0f);
                phi_21695_ = 0i;
                loop {
                    let _e1398 = phi_21696_;
                    let _e1400 = phi_21695_;
                    local_41 = _e1398;
                    if (_e1400 < 9i) {
                        continue;
                    } else {
                        break;
                    }
                    continuing {
                        let _e1404 = textureLoad(global_4, (vec2<i32>(496i, 256i) + vec2<i32>(_e1400, 0i)), 0i);
                        let _e1407 = local_20[_e1400];
                        phi_21696_ = (_e1398 + (_e1404.xyz * _e1407));
                        phi_21695_ = (_e1400 + 1i);
                    }
                }
                let _e1412 = local_41;
                let _e1416 = global.member_29[1u];
                phi_21697_ = (max(_e1412, vec3<f32>(0f, 0f, 0f)) * _e1416);
            } else {
                let _e1419 = global.member_9;
                let _e1422 = global.member_8;
                let _e1431 = global.member_8[3u];
                phi_21697_ = (mix(_e1419.xyz, _e1422.xyz, vec3(((_e805.y * 0.5f) + 0.5f))) * _e1431);
            }
            let _e1434 = phi_21697_;
            let _e1438 = global.member_34[0u];
            phi_21703_ = _e1434;
            phi_21702_ = 0i;
            loop {
                let _e1441 = phi_21703_;
                let _e1443 = phi_21702_;
                local_42 = _e1441;
                if (_e1443 < i32(_e1365)) {
                    let _e1446 = (8i * (i32(_e1438) + _e1443));
                    let _e1450 = global_3.member[(_e1446 + 3i)];
                    let _e1451 = bitcast<vec4<f32>>(_e1450);
                    let _e1454 = global_3.member[_e1446];
                    let _e1455 = bitcast<vec4<f32>>(_e1454);
                    let _e1459 = global_3.member[(_e1446 + 1i)];
                    let _e1460 = bitcast<vec4<f32>>(_e1459);
                    let _e1464 = global_3.member[(_e1446 + 2i)];
                    let _e1465 = bitcast<vec4<f32>>(_e1464);
                    let _e1466 = _e1455.xyz;
                    let _e1470 = _e1460.xyz;
                    let _e1474 = _e1465.xyz;
                    let _e1478 = vec3<f32>((dot(_e1466, _e813) + _e1455.w), (dot(_e1470, _e813) + _e1460.w), (dot(_e1474, _e813) + _e1465.w));
                    let _e1479 = _e1451.xyz;
                    switch bitcast<i32>(0u) {
                        default: {
                            let _e1483 = (_e1479 - abs(_e1478));
                            let _e1488 = min(_e1483.x, min(_e1483.y, _e1483.z));
                            if (_e1488 <= 0f) {
                                phi_22090_ = 0f;
                                break;
                            }
                            if (_e1451.w <= 0f) {
                                phi_22090_ = 1f;
                                break;
                            }
                            let _e1492 = min((_e1488 / _e1451.w), 1f);
                            phi_22090_ = ((_e1492 * _e1492) * (3f - (2f * _e1492)));
                            break;
                        }
                    }
                    let _e1498 = phi_22090_;
                    if (_e1498 <= 0f) {
                        phi_22127_ = _e1441;
                        continue;
                    }
                    let _e1503 = global_3.member[(_e1446 + 4i)];
                    let _e1505 = bitcast<vec4<f32>>(_e1503).xyz;
                    let _e1509 = global_3.member[(_e1446 + 5i)];
                    let _e1510 = bitcast<vec4<f32>>(_e1509);
                    let _e1515 = global_3.member[(_e1446 + 6i)][0u];
                    let _e1516 = bitcast<i32>(_e1515);
                    let _e1517 = dot(_e1466, _e805);
                    let _e1518 = dot(_e1470, _e805);
                    let _e1519 = dot(_e1474, _e805);
                    let _e1520 = vec3<f32>(_e1517, _e1518, _e1519);
                    let _e1526 = ((_e813 + (_e805 * _e1510.x)) + (_e815 * _e1510.y));
                    let _e1541 = clamp(((((vec3<f32>((dot(_e1466, _e1526) + _e1455.w), (dot(_e1470, _e1526) + _e1460.w), (dot(_e1474, _e1526) + _e1465.w)) + _e1479) / max((_e1479 * 2f), vec3<f32>(0.000001f, 0.000001f, 0.000001f))) * _e1505) - vec3<f32>(0.5f, 0.5f, 0.5f)), vec3<f32>(0f, 0f, 0f), (_e1505 - vec3<f32>(1f, 1f, 1f)));
                    let _e1542 = vec3<i32>(_e1505);
                    let _e1546 = min(vec3<i32>(_e1541), max((_e1542 - vec3<i32>(2i, 2i, 2i)), vec3<i32>(0i, 0i, 0i)));
                    let _e1548 = (_e1541 - vec3<f32>(_e1546));
                    let _e1549 = (0.488603f * _e1518);
                    let _e1550 = (0.488603f * _e1519);
                    let _e1551 = (0.488603f * _e1517);
                    let _e1552 = (1.092548f * _e1517);
                    let _e1553 = (_e1552 * _e1518);
                    let _e1555 = ((1.092548f * _e1518) * _e1519);
                    let _e1559 = (0.315392f * (((3f * _e1519) * _e1519) - 1f));
                    let _e1560 = (_e1552 * _e1519);
                    let _e1564 = (0.546274f * ((_e1517 * _e1517) - (_e1518 * _e1518)));
                    let _e1565 = (_e1542 - vec3<i32>(1i, 1i, 1i));
                    let _e1566 = min(_e1546, _e1565);
                    let _e1577 = (_e1516 + ((_e1566.x + (_e1542.x * (_e1566.y + (_e1542.y * _e1566.z)))) * 4i));
                    let _e1578 = (vec3<f32>(1f, 1f, 1f) - _e1548);
                    let _e1585 = ((((((vec3<f32>(_e1566) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e1505) * _e1479) * 2f) - _e1479) - _e1478);
                    let _e1591 = (dot((_e1585 * inverseSqrt(max(dot(_e1585, _e1585), 0.0000000001f))), _e1520) + 1f);
                    let _e1594 = (_e1578.x * _e1578.y);
                    let _e1601 = (_e1577 + 3i);
                    let _e1605 = global_3.member[_e1601][1u];
                    let _e1610 = (((_e1594 * _e1578.z) * ((0.25f * (_e1591 * _e1591)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e1605).y > 0.5f)));
                    let _e1613 = global_3.member[_e1577];
                    let _e1617 = global_3.member[(_e1577 + 1i)];
                    let _e1621 = global_3.member[(_e1577 + 2i)];
                    let _e1624 = global_3.member[_e1601];
                    let _e1626 = unpack2x16float(_e1613.x);
                    let _e1628 = unpack2x16float(_e1613.y);
                    let _e1630 = unpack2x16float(_e1613.z);
                    let _e1632 = unpack2x16float(_e1613.w);
                    let _e1634 = unpack2x16float(_e1617.x);
                    let _e1636 = unpack2x16float(_e1617.y);
                    let _e1638 = unpack2x16float(_e1617.z);
                    let _e1640 = unpack2x16float(_e1617.w);
                    let _e1642 = unpack2x16float(_e1621.x);
                    let _e1644 = unpack2x16float(_e1621.y);
                    let _e1646 = unpack2x16float(_e1621.z);
                    let _e1648 = unpack2x16float(_e1621.w);
                    let _e1650 = unpack2x16float(_e1624.x);
                    let _e1706 = ((((((((((vec3<f32>(_e1626.x, _e1626.y, _e1628.x) * 0.282095f) + (vec3<f32>(_e1628.y, _e1630.x, _e1630.y) * _e1549)) + (vec3<f32>(_e1632.x, _e1632.y, _e1634.x) * _e1550)) + (vec3<f32>(_e1634.y, _e1636.x, _e1636.y) * _e1551)) + (vec3<f32>(_e1638.x, _e1638.y, _e1640.x) * _e1553)) + (vec3<f32>(_e1640.y, _e1642.x, _e1642.y) * _e1555)) + (vec3<f32>(_e1644.x, _e1644.y, _e1646.x) * _e1559)) + (vec3<f32>(_e1646.y, _e1648.x, _e1648.y) * _e1560)) + (vec3<f32>(_e1650.x, _e1650.y, unpack2x16float(_e1624.y).x) * _e1564)) * _e1610);
                    let _e1712 = min((_e1546 + vec3<i32>(1i, 0i, 0i)), _e1565);
                    let _e1721 = (_e1516 + ((_e1712.x + (_e1542.x * (_e1712.y + (_e1542.y * _e1712.z)))) * 4i));
                    let _e1728 = ((((((vec3<f32>(_e1712) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e1505) * _e1479) * 2f) - _e1479) - _e1478);
                    let _e1734 = (dot((_e1728 * inverseSqrt(max(dot(_e1728, _e1728), 0.0000000001f))), _e1520) + 1f);
                    let _e1736 = (_e1548.x * _e1578.y);
                    let _e1742 = (_e1721 + 3i);
                    let _e1746 = global_3.member[_e1742][1u];
                    let _e1751 = (((_e1736 * _e1578.z) * ((0.25f * (_e1734 * _e1734)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e1746).y > 0.5f)));
                    let _e1754 = global_3.member[_e1721];
                    let _e1758 = global_3.member[(_e1721 + 1i)];
                    let _e1762 = global_3.member[(_e1721 + 2i)];
                    let _e1765 = global_3.member[_e1742];
                    let _e1767 = unpack2x16float(_e1754.x);
                    let _e1769 = unpack2x16float(_e1754.y);
                    let _e1771 = unpack2x16float(_e1754.z);
                    let _e1773 = unpack2x16float(_e1754.w);
                    let _e1775 = unpack2x16float(_e1758.x);
                    let _e1777 = unpack2x16float(_e1758.y);
                    let _e1779 = unpack2x16float(_e1758.z);
                    let _e1781 = unpack2x16float(_e1758.w);
                    let _e1783 = unpack2x16float(_e1762.x);
                    let _e1785 = unpack2x16float(_e1762.y);
                    let _e1787 = unpack2x16float(_e1762.z);
                    let _e1789 = unpack2x16float(_e1762.w);
                    let _e1791 = unpack2x16float(_e1765.x);
                    let _e1847 = ((((((((((vec3<f32>(_e1767.x, _e1767.y, _e1769.x) * 0.282095f) + (vec3<f32>(_e1769.y, _e1771.x, _e1771.y) * _e1549)) + (vec3<f32>(_e1773.x, _e1773.y, _e1775.x) * _e1550)) + (vec3<f32>(_e1775.y, _e1777.x, _e1777.y) * _e1551)) + (vec3<f32>(_e1779.x, _e1779.y, _e1781.x) * _e1553)) + (vec3<f32>(_e1781.y, _e1783.x, _e1783.y) * _e1555)) + (vec3<f32>(_e1785.x, _e1785.y, _e1787.x) * _e1559)) + (vec3<f32>(_e1787.y, _e1789.x, _e1789.y) * _e1560)) + (vec3<f32>(_e1791.x, _e1791.y, unpack2x16float(_e1765.y).x) * _e1564)) * _e1751);
                    let _e1854 = min((_e1546 + vec3<i32>(0i, 1i, 0i)), _e1565);
                    let _e1863 = (_e1516 + ((_e1854.x + (_e1542.x * (_e1854.y + (_e1542.y * _e1854.z)))) * 4i));
                    let _e1870 = ((((((vec3<f32>(_e1854) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e1505) * _e1479) * 2f) - _e1479) - _e1478);
                    let _e1876 = (dot((_e1870 * inverseSqrt(max(dot(_e1870, _e1870), 0.0000000001f))), _e1520) + 1f);
                    let _e1878 = (_e1578.x * _e1548.y);
                    let _e1884 = (_e1863 + 3i);
                    let _e1888 = global_3.member[_e1884][1u];
                    let _e1893 = (((_e1878 * _e1578.z) * ((0.25f * (_e1876 * _e1876)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e1888).y > 0.5f)));
                    let _e1896 = global_3.member[_e1863];
                    let _e1900 = global_3.member[(_e1863 + 1i)];
                    let _e1904 = global_3.member[(_e1863 + 2i)];
                    let _e1907 = global_3.member[_e1884];
                    let _e1909 = unpack2x16float(_e1896.x);
                    let _e1911 = unpack2x16float(_e1896.y);
                    let _e1913 = unpack2x16float(_e1896.z);
                    let _e1915 = unpack2x16float(_e1896.w);
                    let _e1917 = unpack2x16float(_e1900.x);
                    let _e1919 = unpack2x16float(_e1900.y);
                    let _e1921 = unpack2x16float(_e1900.z);
                    let _e1923 = unpack2x16float(_e1900.w);
                    let _e1925 = unpack2x16float(_e1904.x);
                    let _e1927 = unpack2x16float(_e1904.y);
                    let _e1929 = unpack2x16float(_e1904.z);
                    let _e1931 = unpack2x16float(_e1904.w);
                    let _e1933 = unpack2x16float(_e1907.x);
                    let _e1989 = ((((((((((vec3<f32>(_e1909.x, _e1909.y, _e1911.x) * 0.282095f) + (vec3<f32>(_e1911.y, _e1913.x, _e1913.y) * _e1549)) + (vec3<f32>(_e1915.x, _e1915.y, _e1917.x) * _e1550)) + (vec3<f32>(_e1917.y, _e1919.x, _e1919.y) * _e1551)) + (vec3<f32>(_e1921.x, _e1921.y, _e1923.x) * _e1553)) + (vec3<f32>(_e1923.y, _e1925.x, _e1925.y) * _e1555)) + (vec3<f32>(_e1927.x, _e1927.y, _e1929.x) * _e1559)) + (vec3<f32>(_e1929.y, _e1931.x, _e1931.y) * _e1560)) + (vec3<f32>(_e1933.x, _e1933.y, unpack2x16float(_e1907.y).x) * _e1564)) * _e1893);
                    let _e1996 = min((_e1546 + vec3<i32>(1i, 1i, 0i)), _e1565);
                    let _e2005 = (_e1516 + ((_e1996.x + (_e1542.x * (_e1996.y + (_e1542.y * _e1996.z)))) * 4i));
                    let _e2012 = ((((((vec3<f32>(_e1996) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e1505) * _e1479) * 2f) - _e1479) - _e1478);
                    let _e2018 = (dot((_e2012 * inverseSqrt(max(dot(_e2012, _e2012), 0.0000000001f))), _e1520) + 1f);
                    let _e2019 = (_e1548.x * _e1548.y);
                    let _e2025 = (_e2005 + 3i);
                    let _e2029 = global_3.member[_e2025][1u];
                    let _e2034 = (((_e2019 * _e1578.z) * ((0.25f * (_e2018 * _e2018)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e2029).y > 0.5f)));
                    let _e2037 = global_3.member[_e2005];
                    let _e2041 = global_3.member[(_e2005 + 1i)];
                    let _e2045 = global_3.member[(_e2005 + 2i)];
                    let _e2048 = global_3.member[_e2025];
                    let _e2050 = unpack2x16float(_e2037.x);
                    let _e2052 = unpack2x16float(_e2037.y);
                    let _e2054 = unpack2x16float(_e2037.z);
                    let _e2056 = unpack2x16float(_e2037.w);
                    let _e2058 = unpack2x16float(_e2041.x);
                    let _e2060 = unpack2x16float(_e2041.y);
                    let _e2062 = unpack2x16float(_e2041.z);
                    let _e2064 = unpack2x16float(_e2041.w);
                    let _e2066 = unpack2x16float(_e2045.x);
                    let _e2068 = unpack2x16float(_e2045.y);
                    let _e2070 = unpack2x16float(_e2045.z);
                    let _e2072 = unpack2x16float(_e2045.w);
                    let _e2074 = unpack2x16float(_e2048.x);
                    let _e2130 = ((((((((((vec3<f32>(_e2050.x, _e2050.y, _e2052.x) * 0.282095f) + (vec3<f32>(_e2052.y, _e2054.x, _e2054.y) * _e1549)) + (vec3<f32>(_e2056.x, _e2056.y, _e2058.x) * _e1550)) + (vec3<f32>(_e2058.y, _e2060.x, _e2060.y) * _e1551)) + (vec3<f32>(_e2062.x, _e2062.y, _e2064.x) * _e1553)) + (vec3<f32>(_e2064.y, _e2066.x, _e2066.y) * _e1555)) + (vec3<f32>(_e2068.x, _e2068.y, _e2070.x) * _e1559)) + (vec3<f32>(_e2070.y, _e2072.x, _e2072.y) * _e1560)) + (vec3<f32>(_e2074.x, _e2074.y, unpack2x16float(_e2048.y).x) * _e1564)) * _e2034);
                    let _e2137 = min((_e1546 + vec3<i32>(0i, 0i, 1i)), _e1565);
                    let _e2146 = (_e1516 + ((_e2137.x + (_e1542.x * (_e2137.y + (_e1542.y * _e2137.z)))) * 4i));
                    let _e2153 = ((((((vec3<f32>(_e2137) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e1505) * _e1479) * 2f) - _e1479) - _e1478);
                    let _e2159 = (dot((_e2153 * inverseSqrt(max(dot(_e2153, _e2153), 0.0000000001f))), _e1520) + 1f);
                    let _e2166 = (_e2146 + 3i);
                    let _e2170 = global_3.member[_e2166][1u];
                    let _e2175 = (((_e1594 * _e1548.z) * ((0.25f * (_e2159 * _e2159)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e2170).y > 0.5f)));
                    let _e2178 = global_3.member[_e2146];
                    let _e2182 = global_3.member[(_e2146 + 1i)];
                    let _e2186 = global_3.member[(_e2146 + 2i)];
                    let _e2189 = global_3.member[_e2166];
                    let _e2191 = unpack2x16float(_e2178.x);
                    let _e2193 = unpack2x16float(_e2178.y);
                    let _e2195 = unpack2x16float(_e2178.z);
                    let _e2197 = unpack2x16float(_e2178.w);
                    let _e2199 = unpack2x16float(_e2182.x);
                    let _e2201 = unpack2x16float(_e2182.y);
                    let _e2203 = unpack2x16float(_e2182.z);
                    let _e2205 = unpack2x16float(_e2182.w);
                    let _e2207 = unpack2x16float(_e2186.x);
                    let _e2209 = unpack2x16float(_e2186.y);
                    let _e2211 = unpack2x16float(_e2186.z);
                    let _e2213 = unpack2x16float(_e2186.w);
                    let _e2215 = unpack2x16float(_e2189.x);
                    let _e2271 = ((((((((((vec3<f32>(_e2191.x, _e2191.y, _e2193.x) * 0.282095f) + (vec3<f32>(_e2193.y, _e2195.x, _e2195.y) * _e1549)) + (vec3<f32>(_e2197.x, _e2197.y, _e2199.x) * _e1550)) + (vec3<f32>(_e2199.y, _e2201.x, _e2201.y) * _e1551)) + (vec3<f32>(_e2203.x, _e2203.y, _e2205.x) * _e1553)) + (vec3<f32>(_e2205.y, _e2207.x, _e2207.y) * _e1555)) + (vec3<f32>(_e2209.x, _e2209.y, _e2211.x) * _e1559)) + (vec3<f32>(_e2211.y, _e2213.x, _e2213.y) * _e1560)) + (vec3<f32>(_e2215.x, _e2215.y, unpack2x16float(_e2189.y).x) * _e1564)) * _e2175);
                    let _e2278 = min((_e1546 + vec3<i32>(1i, 0i, 1i)), _e1565);
                    let _e2287 = (_e1516 + ((_e2278.x + (_e1542.x * (_e2278.y + (_e1542.y * _e2278.z)))) * 4i));
                    let _e2294 = ((((((vec3<f32>(_e2278) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e1505) * _e1479) * 2f) - _e1479) - _e1478);
                    let _e2300 = (dot((_e2294 * inverseSqrt(max(dot(_e2294, _e2294), 0.0000000001f))), _e1520) + 1f);
                    let _e2306 = (_e2287 + 3i);
                    let _e2310 = global_3.member[_e2306][1u];
                    let _e2315 = (((_e1736 * _e1548.z) * ((0.25f * (_e2300 * _e2300)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e2310).y > 0.5f)));
                    let _e2318 = global_3.member[_e2287];
                    let _e2322 = global_3.member[(_e2287 + 1i)];
                    let _e2326 = global_3.member[(_e2287 + 2i)];
                    let _e2329 = global_3.member[_e2306];
                    let _e2331 = unpack2x16float(_e2318.x);
                    let _e2333 = unpack2x16float(_e2318.y);
                    let _e2335 = unpack2x16float(_e2318.z);
                    let _e2337 = unpack2x16float(_e2318.w);
                    let _e2339 = unpack2x16float(_e2322.x);
                    let _e2341 = unpack2x16float(_e2322.y);
                    let _e2343 = unpack2x16float(_e2322.z);
                    let _e2345 = unpack2x16float(_e2322.w);
                    let _e2347 = unpack2x16float(_e2326.x);
                    let _e2349 = unpack2x16float(_e2326.y);
                    let _e2351 = unpack2x16float(_e2326.z);
                    let _e2353 = unpack2x16float(_e2326.w);
                    let _e2355 = unpack2x16float(_e2329.x);
                    let _e2411 = ((((((((((vec3<f32>(_e2331.x, _e2331.y, _e2333.x) * 0.282095f) + (vec3<f32>(_e2333.y, _e2335.x, _e2335.y) * _e1549)) + (vec3<f32>(_e2337.x, _e2337.y, _e2339.x) * _e1550)) + (vec3<f32>(_e2339.y, _e2341.x, _e2341.y) * _e1551)) + (vec3<f32>(_e2343.x, _e2343.y, _e2345.x) * _e1553)) + (vec3<f32>(_e2345.y, _e2347.x, _e2347.y) * _e1555)) + (vec3<f32>(_e2349.x, _e2349.y, _e2351.x) * _e1559)) + (vec3<f32>(_e2351.y, _e2353.x, _e2353.y) * _e1560)) + (vec3<f32>(_e2355.x, _e2355.y, unpack2x16float(_e2329.y).x) * _e1564)) * _e2315);
                    let _e2418 = min((_e1546 + vec3<i32>(0i, 1i, 1i)), _e1565);
                    let _e2427 = (_e1516 + ((_e2418.x + (_e1542.x * (_e2418.y + (_e1542.y * _e2418.z)))) * 4i));
                    let _e2434 = ((((((vec3<f32>(_e2418) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e1505) * _e1479) * 2f) - _e1479) - _e1478);
                    let _e2440 = (dot((_e2434 * inverseSqrt(max(dot(_e2434, _e2434), 0.0000000001f))), _e1520) + 1f);
                    let _e2446 = (_e2427 + 3i);
                    let _e2450 = global_3.member[_e2446][1u];
                    let _e2455 = (((_e1878 * _e1548.z) * ((0.25f * (_e2440 * _e2440)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e2450).y > 0.5f)));
                    let _e2458 = global_3.member[_e2427];
                    let _e2462 = global_3.member[(_e2427 + 1i)];
                    let _e2466 = global_3.member[(_e2427 + 2i)];
                    let _e2469 = global_3.member[_e2446];
                    let _e2471 = unpack2x16float(_e2458.x);
                    let _e2473 = unpack2x16float(_e2458.y);
                    let _e2475 = unpack2x16float(_e2458.z);
                    let _e2477 = unpack2x16float(_e2458.w);
                    let _e2479 = unpack2x16float(_e2462.x);
                    let _e2481 = unpack2x16float(_e2462.y);
                    let _e2483 = unpack2x16float(_e2462.z);
                    let _e2485 = unpack2x16float(_e2462.w);
                    let _e2487 = unpack2x16float(_e2466.x);
                    let _e2489 = unpack2x16float(_e2466.y);
                    let _e2491 = unpack2x16float(_e2466.z);
                    let _e2493 = unpack2x16float(_e2466.w);
                    let _e2495 = unpack2x16float(_e2469.x);
                    let _e2551 = ((((((((((vec3<f32>(_e2471.x, _e2471.y, _e2473.x) * 0.282095f) + (vec3<f32>(_e2473.y, _e2475.x, _e2475.y) * _e1549)) + (vec3<f32>(_e2477.x, _e2477.y, _e2479.x) * _e1550)) + (vec3<f32>(_e2479.y, _e2481.x, _e2481.y) * _e1551)) + (vec3<f32>(_e2483.x, _e2483.y, _e2485.x) * _e1553)) + (vec3<f32>(_e2485.y, _e2487.x, _e2487.y) * _e1555)) + (vec3<f32>(_e2489.x, _e2489.y, _e2491.x) * _e1559)) + (vec3<f32>(_e2491.y, _e2493.x, _e2493.y) * _e1560)) + (vec3<f32>(_e2495.x, _e2495.y, unpack2x16float(_e2469.y).x) * _e1564)) * _e2455);
                    let _e2558 = min((_e1546 + vec3<i32>(1i, 1i, 1i)), _e1565);
                    let _e2567 = (_e1516 + ((_e2558.x + (_e1542.x * (_e2558.y + (_e1542.y * _e2558.z)))) * 4i));
                    let _e2574 = ((((((vec3<f32>(_e2558) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e1505) * _e1479) * 2f) - _e1479) - _e1478);
                    let _e2580 = (dot((_e2574 * inverseSqrt(max(dot(_e2574, _e2574), 0.0000000001f))), _e1520) + 1f);
                    let _e2586 = (_e2567 + 3i);
                    let _e2590 = global_3.member[_e2586][1u];
                    let _e2595 = (((_e2019 * _e1548.z) * ((0.25f * (_e2580 * _e2580)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e2590).y > 0.5f)));
                    let _e2598 = global_3.member[_e2567];
                    let _e2602 = global_3.member[(_e2567 + 1i)];
                    let _e2606 = global_3.member[(_e2567 + 2i)];
                    let _e2609 = global_3.member[_e2586];
                    let _e2611 = unpack2x16float(_e2598.x);
                    let _e2613 = unpack2x16float(_e2598.y);
                    let _e2615 = unpack2x16float(_e2598.z);
                    let _e2617 = unpack2x16float(_e2598.w);
                    let _e2619 = unpack2x16float(_e2602.x);
                    let _e2621 = unpack2x16float(_e2602.y);
                    let _e2623 = unpack2x16float(_e2602.z);
                    let _e2625 = unpack2x16float(_e2602.w);
                    let _e2627 = unpack2x16float(_e2606.x);
                    let _e2629 = unpack2x16float(_e2606.y);
                    let _e2631 = unpack2x16float(_e2606.z);
                    let _e2633 = unpack2x16float(_e2606.w);
                    let _e2635 = unpack2x16float(_e2609.x);
                    let _e2691 = ((((((((((vec3<f32>(_e2611.x, _e2611.y, _e2613.x) * 0.282095f) + (vec3<f32>(_e2613.y, _e2615.x, _e2615.y) * _e1549)) + (vec3<f32>(_e2617.x, _e2617.y, _e2619.x) * _e1550)) + (vec3<f32>(_e2619.y, _e2621.x, _e2621.y) * _e1551)) + (vec3<f32>(_e2623.x, _e2623.y, _e2625.x) * _e1553)) + (vec3<f32>(_e2625.y, _e2627.x, _e2627.y) * _e1555)) + (vec3<f32>(_e2629.x, _e2629.y, _e2631.x) * _e1559)) + (vec3<f32>(_e2631.y, _e2633.x, _e2633.y) * _e1560)) + (vec3<f32>(_e2635.x, _e2635.y, unpack2x16float(_e2609.y).x) * _e1564)) * _e2595);
                    let _e2696 = (((((((vec4<f32>(_e1706.x, _e1706.y, _e1706.z, _e1610) + vec4<f32>(_e1847.x, _e1847.y, _e1847.z, _e1751)) + vec4<f32>(_e1989.x, _e1989.y, _e1989.z, _e1893)) + vec4<f32>(_e2130.x, _e2130.y, _e2130.z, _e2034)) + vec4<f32>(_e2271.x, _e2271.y, _e2271.z, _e2175)) + vec4<f32>(_e2411.x, _e2411.y, _e2411.z, _e2315)) + vec4<f32>(_e2551.x, _e2551.y, _e2551.z, _e2455)) + vec4<f32>(_e2691.x, _e2691.y, _e2691.z, _e2595));
                    phi_22128_ = _e1441;
                    if (_e2696.w > 0.00001f) {
                        phi_22128_ = mix(_e1441, ((max(_e2696.xyz, vec3<f32>(0f, 0f, 0f)) / vec3(_e2696.w)) * _e1510.z), vec3(_e1498));
                    }
                    let _e2708 = phi_22128_;
                    phi_22127_ = _e2708;
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e2710 = phi_22127_;
                    phi_21703_ = _e2710;
                    phi_21702_ = (_e1443 + 1i);
                }
            }
            let _e2713 = local_42;
            phi_21713_ = (_e1362 + ((_e1238 * (_e2713 - _e1434)) * _e1267));
        }
        let _e2719 = phi_21713_;
        let _e2722 = global.member_13[3u];
        phi_21712_ = _e2719;
        if (_e2722 > 0.5f) {
            let _e2725 = global.member_11;
            let _e2730 = global.member_11[3u];
            let _e2732 = global_16;
            let _e2735 = global.member_12;
            let _e2740 = global.member_13;
            let _e2743 = clamp(floor((_e2732.xy * _e2735.xy)), vec2<f32>(0f, 0f), (_e2740.xy - vec2<f32>(1f, 1f)));
            let _e2748 = global.member_12[2u];
            let _e2752 = global.member_12[3u];
            let _e2757 = global.member_13[2u];
            let _e2762 = global.member_13[1u];
            let _e2768 = global.member_13[0u];
            let _e2772 = u32(((((clamp(floor(((log2(max((dot(_e2725.xyz, _e813) + _e2730), 0.000001f)) * _e2748) + _e2752)), 0f, (_e2757 - 1f)) * _e2762) + _e2743.y) * _e2768) + _e2743.x));
            let _e2779 = global_17.member[(_e2772 >> bitcast<u32>(2i))][(_e2772 & 3u)];
            let _e2780 = (_e2779 & 65535u);
            phi_21714_ = _e2719;
            phi_21710_ = _e2780;
            loop {
                let _e2784 = phi_21714_;
                let _e2786 = phi_21710_;
                local_61 = _e2784;
                if (_e2786 < (_e2780 + (_e2779 >> bitcast<u32>(16i)))) {
                    let _e2789 = (_e2786 / 3u);
                    let _e2796 = global_18.member[(_e2789 >> bitcast<u32>(2i))][(_e2789 & 3u)];
                    let _e2802 = ((_e2796 >> bitcast<u32>(((_e2786 - (_e2789 * 3u)) * 10u))) & 1023u);
                    let _e2805 = global_12.member[_e2802];
                    let _e2807 = (_e2805.xyz - _e813);
                    let _e2808 = dot(_e2807, _e2807);
                    let _e2810 = (_e2808 * _e2805.w);
                    let _e2813 = clamp((1f - (_e2810 * _e2810)), 0f, 1f);
                    let _e2816 = (_e2807 * inverseSqrt(max(_e2808, 0.00000001f)));
                    let _e2819 = global_14.member[_e2802];
                    let _e2822 = global_15.member[_e2802];
                    let _e2830 = clamp(((dot(-(_e2816), _e2822.xyz) * _e2819.w) + _e2822.w), 0f, 1f);
                    let _e2837 = (_e2819.xyz * ((((_e2813 * _e2813) * _e2830) * _e2830) / max(_e2808, 0.0001f)));
                    phi_22055_ = _e2837;
                    if _e823 {
                        switch bitcast<i32>(0u) {
                            default: {
                                let _e2841 = global.member_21[2u];
                                let _e2842 = u32(_e2841);
                                if (_e2802 < _e2842) {
                                    let _e2846 = global.member_26[_e2802];
                                    let _e2849 = global.member_15[_e2802];
                                    let _e2858 = (_e2846.z * max((_e2849 * vec4<f32>(_e813.x, _e813.y, _e813.z, 1f)).w, 0f));
                                    let _e2861 = global.member_25[0u];
                                    let _e2867 = global.member_25[1u];
                                    let _e2870 = ((_e813 + (_e820 * (_e2858 * _e2861))) + (_e2816 * (_e2858 * _e2867)));
                                    let _e2875 = (_e2849 * vec4<f32>(_e2870.x, _e2870.y, _e2870.z, 1f));
                                    if (_e2875.w <= 0f) {
                                        phi_22004_ = 1f;
                                        break;
                                    }
                                    let _e2880 = (_e2875.xyz / vec3(_e2875.w));
                                    let _e2882 = (_e2880.x < 0f);
                                    phi_9377_ = _e2882;
                                    if !(_e2882) {
                                        phi_9377_ = (_e2880.x > 1f);
                                    }
                                    let _e2886 = phi_9377_;
                                    phi_9384_ = _e2886;
                                    if !(_e2886) {
                                        phi_9384_ = (_e2880.y < 0f);
                                    }
                                    let _e2891 = phi_9384_;
                                    phi_9391_ = _e2891;
                                    if !(_e2891) {
                                        phi_9391_ = (_e2880.y > 1f);
                                    }
                                    let _e2896 = phi_9391_;
                                    phi_9398_ = _e2896;
                                    if !(_e2896) {
                                        phi_9398_ = (_e2880.z > 1f);
                                    }
                                    let _e2901 = phi_9398_;
                                    if _e2901 {
                                        phi_22004_ = 1f;
                                        break;
                                    }
                                    let _e2904 = _e2846.xy;
                                    let _e2906 = global.member_23;
                                    let _e2907 = _e2906.zw;
                                    let _e2909 = global.member_22;
                                    let _e2910 = _e2909.xy;
                                    let _e2911 = (_e2910 * 0.5f);
                                    let _e2913 = (_e2904 + (_e2880.xy * _e2907));
                                    let _e2914 = (_e2904 + _e2911);
                                    let _e2916 = ((_e2904 + _e2907) - _e2911);
                                    let _e2921 = vec4<f32>(_e2914.x, _e2914.y, _e2916.x, _e2916.y);
                                    switch bitcast<i32>(0u) {
                                        default: {
                                            let _e2925 = global.member_22[2u];
                                            let _e2926 = i32(_e2925);
                                            if (_e2926 <= 0i) {
                                                let _e2930 = clamp(_e2913, _e2921.xy, _e2921.zw);
                                                let _e2935 = textureSampleCompare(global_2, global_1, vec3<f32>(_e2930.x, _e2930.y, _e2880.z).xy, _e2880.z);
                                                phi_22003_ = _e2935;
                                                break;
                                            }
                                            let _e2937 = ((_e2913 / _e2910) + vec2<f32>(0.5f, 0.5f));
                                            let _e2938 = floor(_e2937);
                                            let _e2939 = (_e2937 - _e2938);
                                            let _e2941 = (_e2926 == 1i);
                                            if _e2941 {
                                                let _e2942 = (_e2939 * 2f);
                                                local_16[0i] = (vec2<f32>(3f, 3f) - _e2942);
                                                local_16[1i] = (vec2<f32>(1f, 1f) + _e2942);
                                                let _e2948 = local_16[0i];
                                                local_17[0i] = (((vec2<f32>(2f, 2f) - _e2939) / _e2948) - vec2<f32>(1f, 1f));
                                                let _e2952 = local_16[1i];
                                                local_17[1i] = ((_e2939 / _e2952) + vec2<f32>(1f, 1f));
                                            } else {
                                                let _e2956 = (_e2939 * 3f);
                                                local_16[0i] = (vec2<f32>(4f, 4f) - _e2956);
                                                local_16[1i] = vec2<f32>(7f, 7f);
                                                local_16[2i] = (vec2<f32>(1f, 1f) + _e2956);
                                                let _e2964 = local_16[0i];
                                                local_17[0i] = (((vec2<f32>(3f, 3f) - (_e2939 * 2f)) / _e2964) - vec2<f32>(2f, 2f));
                                                let _e2969 = local_16[1i];
                                                local_17[1i] = ((vec2<f32>(3f, 3f) + _e2939) / _e2969);
                                                let _e2972 = local_16[2i];
                                                local_17[2i] = ((_e2939 / _e2972) + vec2<f32>(2f, 2f));
                                            }
                                            let _e2977 = select(3i, 2i, _e2941);
                                            phi_21996_ = 0f;
                                            phi_21993_ = 0i;
                                            loop {
                                                let _e2979 = phi_21996_;
                                                let _e2981 = phi_21993_;
                                                local_43 = _e2979;
                                                if (_e2981 < _e2977) {
                                                    phi_22002_ = _e2979;
                                                    phi_21999_ = 0i;
                                                    loop {
                                                        let _e2984 = phi_22002_;
                                                        let _e2986 = phi_21999_;
                                                        local_59 = _e2984;
                                                        if (_e2986 < _e2977) {
                                                            continue;
                                                        } else {
                                                            break;
                                                        }
                                                        continuing {
                                                            let _e2990 = local_17[_e2986][0u];
                                                            let _e2993 = local_17[_e2981][1u];
                                                            let _e2999 = clamp((_e2910 * ((_e2938 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e2990, _e2993))), _e2921.xy, _e2921.zw);
                                                            let _e3002 = local_16[_e2986][0u];
                                                            let _e3005 = local_16[_e2981][1u];
                                                            let _e3011 = textureSampleCompare(global_2, global_1, vec3<f32>(_e2999.x, _e2999.y, _e2880.z).xy, _e2880.z);
                                                            phi_22002_ = (_e2984 + ((_e3002 * _e3005) * _e3011));
                                                            phi_21999_ = (_e2986 + 1i);
                                                        }
                                                    }
                                                    continue;
                                                } else {
                                                    break;
                                                }
                                                continuing {
                                                    let _e7825 = local_59;
                                                    phi_21996_ = _e7825;
                                                    phi_21993_ = (_e2981 + 1i);
                                                }
                                            }
                                            let _e3017 = local_43;
                                            phi_22003_ = (_e3017 * select(0.0069444445f, 0.0625f, _e2941));
                                            break;
                                        }
                                    }
                                    let _e3020 = phi_22003_;
                                    phi_22004_ = _e3020;
                                    break;
                                }
                                let _e3021 = (_e2802 - _e2842);
                                let _e3024 = global.member_21[3u];
                                if (_e3021 >= u32(_e3024)) {
                                    phi_22004_ = 1f;
                                    break;
                                }
                                let _e3029 = global.member_27[_e3021];
                                let _e3032 = global.member_28[_e3021];
                                let _e3034 = _e3029.xyz;
                                let _e3037 = (_e3029.w * length((_e813 - _e3034)));
                                let _e3040 = global.member_25[0u];
                                let _e3046 = global.member_25[1u];
                                let _e3050 = (((_e813 + (_e820 * (_e3037 * _e3040))) + (_e2816 * (_e3037 * _e3046))) - _e3034);
                                let _e3051 = abs(_e3050);
                                let _e3054 = (_e3051.x >= _e3051.y);
                                phi_9468_ = _e3054;
                                if _e3054 {
                                    phi_9468_ = (_e3051.x >= _e3051.z);
                                }
                                let _e3058 = phi_9468_;
                                if _e3058 {
                                    phi_21980_ = select(1i, 0i, (_e3050.x > 0f));
                                    phi_21978_ = _e3051.x;
                                } else {
                                    let _e3063 = (_e3051.y >= _e3051.z);
                                    if _e3063 {
                                        phi_21981_ = select(3i, 2i, (_e3050.y > 0f));
                                    } else {
                                        phi_21981_ = select(5i, 4i, (_e3050.z > 0f));
                                    }
                                    let _e3071 = phi_21981_;
                                    phi_21980_ = _e3071;
                                    phi_21978_ = select(_e3051.z, _e3051.y, _e3063);
                                }
                                let _e3074 = phi_21980_;
                                let _e3076 = phi_21978_;
                                if (_e3076 <= 0f) {
                                    phi_22004_ = 1f;
                                    break;
                                }
                                local_18 = array<vec3<f32>, 6>(vec3<f32>(0f, 0f, 1f), vec3<f32>(0f, 0f, -1f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(1f, 0f, 0f));
                                let _e3079 = local_18[_e3074];
                                local_19 = array<vec3<f32>, 6>(vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 0f, -1f), vec3<f32>(0f, 0f, 1f), vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 1f, 0f));
                                let _e3082 = local_19[_e3074];
                                let _e3087 = global.member_24[2u];
                                let _e3090 = (vec2<f32>(dot(_e3050, _e3079), dot(_e3050, _e3082)) / vec2((_e3076 * _e3087)));
                                let _e3094 = (_e3032.z + (_e3032.w / _e3076));
                                if (_e3094 > 1f) {
                                    phi_22004_ = 1f;
                                    break;
                                }
                                let _e3109 = global.member_24;
                                let _e3110 = _e3109.xy;
                                let _e3112 = (_e3032.xy + (vec2<f32>(f32((_e3074 - (i32(floor((f32(_e3074) / f32(3i)))) * 3i))), f32((_e3074 / 3i))) * _e3110));
                                let _e3121 = global.member_22;
                                let _e3122 = _e3121.xy;
                                let _e3123 = (_e3122 * 0.5f);
                                let _e3125 = (_e3112 + (vec2<f32>((0.5f + (0.5f * _e3090.x)), (0.5f - (0.5f * _e3090.y))) * _e3110));
                                let _e3126 = (_e3112 + _e3123);
                                let _e3128 = ((_e3112 + _e3110) - _e3123);
                                let _e3133 = vec4<f32>(_e3126.x, _e3126.y, _e3128.x, _e3128.y);
                                switch bitcast<i32>(0u) {
                                    default: {
                                        let _e3137 = global.member_22[2u];
                                        let _e3138 = i32(_e3137);
                                        if (_e3138 <= 0i) {
                                            let _e3142 = clamp(_e3125, _e3133.xy, _e3133.zw);
                                            let _e3147 = textureSampleCompare(global_2, global_1, vec3<f32>(_e3142.x, _e3142.y, _e3094).xy, _e3094);
                                            phi_21992_ = _e3147;
                                            break;
                                        }
                                        let _e3149 = ((_e3125 / _e3122) + vec2<f32>(0.5f, 0.5f));
                                        let _e3150 = floor(_e3149);
                                        let _e3151 = (_e3149 - _e3150);
                                        let _e3153 = (_e3138 == 1i);
                                        if _e3153 {
                                            let _e3154 = (_e3151 * 2f);
                                            local_14[0i] = (vec2<f32>(3f, 3f) - _e3154);
                                            local_14[1i] = (vec2<f32>(1f, 1f) + _e3154);
                                            let _e3160 = local_14[0i];
                                            local_15[0i] = (((vec2<f32>(2f, 2f) - _e3151) / _e3160) - vec2<f32>(1f, 1f));
                                            let _e3164 = local_14[1i];
                                            local_15[1i] = ((_e3151 / _e3164) + vec2<f32>(1f, 1f));
                                        } else {
                                            let _e3168 = (_e3151 * 3f);
                                            local_14[0i] = (vec2<f32>(4f, 4f) - _e3168);
                                            local_14[1i] = vec2<f32>(7f, 7f);
                                            local_14[2i] = (vec2<f32>(1f, 1f) + _e3168);
                                            let _e3176 = local_14[0i];
                                            local_15[0i] = (((vec2<f32>(3f, 3f) - (_e3151 * 2f)) / _e3176) - vec2<f32>(2f, 2f));
                                            let _e3181 = local_14[1i];
                                            local_15[1i] = ((vec2<f32>(3f, 3f) + _e3151) / _e3181);
                                            let _e3184 = local_14[2i];
                                            local_15[2i] = ((_e3151 / _e3184) + vec2<f32>(2f, 2f));
                                        }
                                        let _e3189 = select(3i, 2i, _e3153);
                                        phi_21985_ = 0f;
                                        phi_21982_ = 0i;
                                        loop {
                                            let _e3191 = phi_21985_;
                                            let _e3193 = phi_21982_;
                                            local_44 = _e3191;
                                            if (_e3193 < _e3189) {
                                                phi_21991_ = _e3191;
                                                phi_21988_ = 0i;
                                                loop {
                                                    let _e3196 = phi_21991_;
                                                    let _e3198 = phi_21988_;
                                                    local_60 = _e3196;
                                                    if (_e3198 < _e3189) {
                                                        continue;
                                                    } else {
                                                        break;
                                                    }
                                                    continuing {
                                                        let _e3202 = local_15[_e3198][0u];
                                                        let _e3205 = local_15[_e3193][1u];
                                                        let _e3211 = clamp((_e3122 * ((_e3150 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e3202, _e3205))), _e3133.xy, _e3133.zw);
                                                        let _e3214 = local_14[_e3198][0u];
                                                        let _e3217 = local_14[_e3193][1u];
                                                        let _e3223 = textureSampleCompare(global_2, global_1, vec3<f32>(_e3211.x, _e3211.y, _e3094).xy, _e3094);
                                                        phi_21991_ = (_e3196 + ((_e3214 * _e3217) * _e3223));
                                                        phi_21988_ = (_e3198 + 1i);
                                                    }
                                                }
                                                continue;
                                            } else {
                                                break;
                                            }
                                            continuing {
                                                let _e7837 = local_60;
                                                phi_21985_ = _e7837;
                                                phi_21982_ = (_e3193 + 1i);
                                            }
                                        }
                                        let _e3229 = local_44;
                                        phi_21992_ = (_e3229 * select(0.0069444445f, 0.0625f, _e3153));
                                        break;
                                    }
                                }
                                let _e3232 = phi_21992_;
                                phi_22004_ = _e3232;
                                break;
                            }
                        }
                        let _e3234 = phi_22004_;
                        phi_22055_ = (_e2837 * _e3234);
                    }
                    let _e3237 = phi_22055_;
                    let _e3238 = dot(_e805, _e2816);
                    local_58 = (_e2784 + (((_e1238 * max(_e3238, 0f)) * _e3237) + (_e3237 * ((pow(max(dot(_e805, normalize((_e2816 + _e815))), 0f), _e1276) * _e1280) * step(0f, _e3238)))));
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e7817 = local_58;
                    phi_21714_ = _e7817;
                    phi_21710_ = (_e2786 + bitcast<u32>(1i));
                }
            }
            let _e7847 = local_61;
            phi_21712_ = _e7847;
        }
        let _e3256 = phi_21712_;
        phi_21711_ = _e3256;
    } else {
        let _e3257 = textureSample(global_26, global_5, _e281);
        let _e3260 = global_8.member_4[0u];
        let _e3263 = clamp((_e3260 * _e3257.z), 0f, 1f);
        let _e3266 = global_8.member_4[1u];
        let _e3269 = clamp((_e3266 * _e3257.y), 0.045f, 1f);
        phi_21029_ = _e3263;
        phi_21024_ = _e3269;
        if (_e722 > 0f) {
            phi_21029_ = mix(_e3263, _e720.y, _e722);
            phi_21024_ = mix(_e3269, max(_e720.x, 0.045f), _e722);
        }
        let _e3277 = phi_21029_;
        let _e3279 = phi_21024_;
        let _e3280 = (_e3279 * _e3279);
        let _e3282 = (_e1238 * (1f - _e3277));
        let _e3284 = mix(vec3<f32>(0.04f, 0.04f, 0.04f), _e1238, vec3(_e3277));
        let _e3285 = (_e796 > 0f);
        phi_21057_ = _e805;
        if _e3285 {
            let _e3286 = dpdx(_e813);
            let _e3287 = dpdy(_e813);
            let _e3288 = cross(_e3286, _e3287);
            phi_21058_ = _e805;
            if (dot(_e3288, _e3288) > 0.00000000000000000001f) {
                phi_21058_ = normalize(((normalize(_e3288) * select(1f, -1f, (dot(_e3288, _e815) < 0f))) + (_e805 - _e726)));
            }
            let _e3300 = phi_21058_;
            phi_21057_ = _e3300;
        }
        let _e3302 = phi_21057_;
        let _e3304 = max(dot(_e3302, _e815), 0.0001f);
        let _e3307 = dot(_e3302, _e809);
        let _e3308 = clamp(_e3307, 0f, 1f);
        let _e3310 = clamp(dot(_e3302, _e817), 0f, 1f);
        let _e3312 = clamp(dot(_e815, _e817), 0f, 1f);
        phi_21062_ = _e3304;
        phi_21061_ = _e3312;
        if _e3285 {
            phi_21062_ = max(_e3304, 0.5f);
            phi_21061_ = max(_e3312, 0.5f);
        }
        let _e3316 = phi_21062_;
        let _e3318 = phi_21061_;
        let _e3321 = (vec3<f32>(1f, 1f, 1f) - _e3284);
        let _e3323 = (_e3284 + (_e3321 * pow((1f - _e3318), 5f)));
        let _e3324 = (_e3280 * _e3280);
        let _e3326 = (_e3324 - 1f);
        let _e3328 = (((_e3310 * _e3310) * _e3326) + 1f);
        let _e3333 = (1f - _e3324);
        let _e3336 = sqrt((((_e3316 * _e3316) * _e3333) + _e3324));
        let _e3355 = ((((((vec3<f32>(1f, 1f, 1f) - _e3323) * _e3282) * clamp(dot(_e805, _e809), 0f, 1f)) + (((_e3323 * ((_e3324 / ((3.1415927f * _e3328) * _e3328)) * (0.5f / max(((_e3308 * _e3336) + (_e3316 * sqrt((((_e3308 * _e3308) * _e3333) + _e3324)))), 0.00001f)))) * 3.1415927f) * _e3308)) * _e1245) * _e1236);
        phi_21172_ = _e3355;
        if _e3285 {
            phi_21172_ = (_e3355 + (((((_e3282 * _e1245) * _e1236) * _e796) * clamp(-(_e3307), 0f, 1f)) * (0.35f + (0.65f * pow(clamp(dot(-(_e815), _e809), 0f, 1f), 3f)))));
        }
        let _e3371 = phi_21172_;
        let _e3374 = global.member_29[0u];
        let _e3375 = (_e3374 > 0.5f);
        if _e3375 {
            let _e3380 = textureSample(global_6, global_7, (((vec2<f32>(_e3316, _e3279) * 31f) + vec2<f32>(0.5f, 0.5f)) * vec2<f32>(0.03125f, 0.03125f)));
            let _e3383 = global.member_29;
            let _e3390 = ((_e3383.z * _e805.x) - (_e3383.w * _e805.z));
            let _e3394 = ((_e3383.w * _e805.x) + (_e3383.z * _e805.z));
            let _e3398 = (1.092548f * _e3390);
            local_13 = array<f32, 9>(0.282095f, (0.488603f * _e805.y), (0.488603f * _e3394), (0.488603f * _e3390), (_e3398 * _e805.y), ((1.092548f * _e805.y) * _e3394), (0.315392f * (((3f * _e3394) * _e3394) - 1f)), (_e3398 * _e3394), (0.546274f * ((_e3390 * _e3390) - (_e805.y * _e805.y))));
            phi_21080_ = vec3<f32>(0f, 0f, 0f);
            phi_21079_ = 0i;
            loop {
                let _e3413 = phi_21080_;
                let _e3415 = phi_21079_;
                local_45 = _e3413;
                if (_e3415 < 9i) {
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e3419 = textureLoad(global_4, (vec2<i32>(496i, 256i) + vec2<i32>(_e3415, 0i)), 0i);
                    let _e3422 = local_13[_e3415];
                    phi_21080_ = (_e3413 + (_e3419.xyz * _e3422));
                    phi_21079_ = (_e3415 + 1i);
                }
            }
            let _e3427 = local_45;
            let _e3431 = global.member_29[1u];
            let _e3434 = reflect(-(_e815), _e3302);
            let _e3451 = vec2<f32>(((atan2(((_e3383.z * _e3434.x) - (_e3383.w * _e3434.z)), -(((_e3383.w * _e3434.x) + (_e3383.z * _e3434.z)))) * 0.15915494f) + 0.5f), (acos(clamp(_e3434.y, -1f, 1f)) * 0.31830987f));
            let _e3452 = (_e3279 * 5f);
            let _e3454 = min(i32(_e3452), 4i);
            local_11 = array<vec4<i32>, 6>(vec4<i32>(0i, 0i, 512i, 256i), vec4<i32>(0i, 256i, 256i, 128i), vec4<i32>(256i, 256i, 128i, 64i), vec4<i32>(384i, 256i, 64i, 32i), vec4<i32>(448i, 256i, 32i, 16i), vec4<i32>(480i, 256i, 16i, 8i));
            let _e3456 = local_11[_e3454];
            let _e3460 = ((_e3451 * vec2<f32>(_e3456.zw)) - vec2<f32>(0.5f, 0.5f));
            let _e3461 = floor(_e3460);
            let _e3462 = (_e3460 - _e3461);
            let _e3464 = i32(_e3461.x);
            let _e3466 = i32(_e3461.y);
            phi_21083_ = _e3464;
            if (_e3464 < 0i) {
                phi_21083_ = (_e3464 + _e3456.z);
            }
            let _e3471 = phi_21083_;
            phi_21084_ = _e3471;
            if (_e3471 >= _e3456.z) {
                phi_21084_ = (_e3471 - _e3456.z);
            }
            let _e3476 = phi_21084_;
            let _e3477 = (_e3476 + 1i);
            let _e3479 = select(_e3477, 0i, (_e3477 == _e3456.z));
            let _e3483 = min((_e3466 + 1i), (_e3456.w - 1i));
            let _e3484 = max(_e3466, 0i);
            let _e3485 = _e3456.xy;
            let _e3488 = textureLoad(global_4, (_e3485 + vec2<i32>(_e3476, _e3484)), 0i);
            let _e3492 = textureLoad(global_4, (_e3485 + vec2<i32>(_e3479, _e3484)), 0i);
            let _e3496 = textureLoad(global_4, (_e3485 + vec2<i32>(_e3476, _e3483)), 0i);
            let _e3500 = textureLoad(global_4, (_e3485 + vec2<i32>(_e3479, _e3483)), 0i);
            let _e3503 = vec3(_e3462.x);
            local_12 = array<vec4<i32>, 6>(vec4<i32>(0i, 0i, 512i, 256i), vec4<i32>(0i, 256i, 256i, 128i), vec4<i32>(256i, 256i, 128i, 64i), vec4<i32>(384i, 256i, 64i, 32i), vec4<i32>(448i, 256i, 32i, 16i), vec4<i32>(480i, 256i, 16i, 8i));
            let _e3511 = local_12[(_e3454 + 1i)];
            let _e3515 = ((_e3451 * vec2<f32>(_e3511.zw)) - vec2<f32>(0.5f, 0.5f));
            let _e3516 = floor(_e3515);
            let _e3517 = (_e3515 - _e3516);
            let _e3519 = i32(_e3516.x);
            let _e3521 = i32(_e3516.y);
            phi_21090_ = _e3519;
            if (_e3519 < 0i) {
                phi_21090_ = (_e3519 + _e3511.z);
            }
            let _e3526 = phi_21090_;
            phi_21091_ = _e3526;
            if (_e3526 >= _e3511.z) {
                phi_21091_ = (_e3526 - _e3511.z);
            }
            let _e3531 = phi_21091_;
            let _e3532 = (_e3531 + 1i);
            let _e3534 = select(_e3532, 0i, (_e3532 == _e3511.z));
            let _e3538 = min((_e3521 + 1i), (_e3511.w - 1i));
            let _e3539 = max(_e3521, 0i);
            let _e3540 = _e3511.xy;
            let _e3543 = textureLoad(global_4, (_e3540 + vec2<i32>(_e3531, _e3539)), 0i);
            let _e3547 = textureLoad(global_4, (_e3540 + vec2<i32>(_e3534, _e3539)), 0i);
            let _e3551 = textureLoad(global_4, (_e3540 + vec2<i32>(_e3531, _e3538)), 0i);
            let _e3555 = textureLoad(global_4, (_e3540 + vec2<i32>(_e3534, _e3538)), 0i);
            let _e3558 = vec3(_e3517.x);
            phi_21134_ = (max(_e3427, vec3<f32>(0f, 0f, 0f)) * _e3431);
            phi_21122_ = _e3380.xy;
            phi_21098_ = (mix(mix(mix(_e3488.xyz, _e3492.xyz, _e3503), mix(_e3496.xyz, _e3500.xyz, _e3503), vec3(_e3462.y)), mix(mix(_e3543.xyz, _e3547.xyz, _e3558), mix(_e3551.xyz, _e3555.xyz, _e3558), vec3(_e3517.y)), vec3((_e3452 - f32(_e3454)))) * _e3431);
        } else {
            let _e3570 = ((vec4<f32>(-1f, -0.0275f, -0.572f, 0.022f) * _e3279) + vec4<f32>(1f, 0.0425f, 1.04f, -0.04f));
            let _e3583 = global.member_9;
            let _e3584 = _e3583.xyz;
            let _e3586 = global.member_8;
            let _e3587 = _e3586.xyz;
            let _e3595 = global.member_8[3u];
            let _e3596 = (mix(_e3584, _e3587, vec3(((_e805.y * 0.5f) + 0.5f))) * _e3595);
            phi_21134_ = _e3596;
            phi_21122_ = ((vec2<f32>(-1.04f, 1.04f) * ((min((_e3570.x * _e3570.x), exp2((-9.28f * _e3316))) * _e3570.x) + _e3570.y)) + _e3570.zw);
            phi_21098_ = mix((mix(_e3584, _e3587, vec3(((reflect(-(_e815), _e3302).y * 0.5f) + 0.5f))) * _e3595), _e3596, vec3(_e3279));
        }
        let _e3608 = phi_21134_;
        let _e3610 = phi_21122_;
        let _e3612 = phi_21098_;
        phi_4149_ = _e1249;
        if _e1249 {
            let _e3615 = global.member_33[2u];
            phi_4149_ = (_e3615 > 0.5f);
        }
        let _e3618 = phi_4149_;
        phi_21143_ = _e3612;
        if _e3618 {
            switch bitcast<i32>(0u) {
                default: {
                    let _e3621 = global.member_31;
                    let _e3622 = _e3621.xyz;
                    let _e3625 = global.member_33[0u];
                    let _e3630 = global.member_31[3u];
                    let _e3639 = global.member_32[1u];
                    let _e3645 = global.member_32[0u];
                    let _e3648 = (((_e3645 * (1f - smoothstep((_e3625 * 0.5f), _e3625, abs((dot(_e3622, _e813) - _e3630))))) * smoothstep(0.5f, 0.9f, dot(_e820, _e3622))) * (1f - smoothstep((_e3639 * 0.5f), _e3639, _e3279)));
                    if (_e3648 <= 0f) {
                        phi_21119_ = _e3612;
                        break;
                    }
                    let _e3655 = global.member_32[3u];
                    let _e3657 = (_e813 + ((_e805 - (_e3622 * dot(_e805, _e3622))) * _e3655));
                    let _e3659 = global.member_30;
                    let _e3664 = (_e3659 * vec4<f32>(_e3657.x, _e3657.y, _e3657.z, 1f));
                    let _e3676 = global.member_32[2u];
                    phi_21118_ = 0f;
                    phi_21117_ = vec3<f32>(0f, 0f, 0f);
                    phi_21116_ = 0i;
                    loop {
                        let _e3679 = phi_21118_;
                        let _e3681 = phi_21117_;
                        let _e3683 = phi_21116_;
                        local_46 = _e3681;
                        local_47 = _e3679;
                        if (_e3683 < 12i) {
                            continue;
                        } else {
                            break;
                        }
                        continuing {
                            let _e3685 = f32(_e3683);
                            let _e3690 = (_e3685 * 2.3999631f);
                            let _e3694 = global.member_33[1u];
                            let _e3699 = ((((vec2<f32>(_e3664.x, -(_e3664.y)) / vec2(_e3664.w)) * 0.5f) + vec2<f32>(0.5f, 0.5f)) + (vec2<f32>((cos(_e3690) * _e3694), sin(_e3690)) * (sqrt(((_e3685 + 0.5f) * 0.083333336f)) * (_e3676 * _e3279))));
                            let _e3701 = min(_e3699, (vec2<f32>(1f, 1f) - _e3699));
                            let _e3705 = smoothstep(0f, 0.04f, min(_e3701.x, _e3701.y));
                            let _e3707 = textureSampleLevel(global_19, global_5, clamp(_e3699, vec2<f32>(0f, 0f), vec2<f32>(1f, 1f)), 0f);
                            let _e3708 = _e3707.xyz;
                            phi_21118_ = (_e3679 + (_e3707.w * _e3705));
                            phi_21117_ = (_e3681 + ((_e3708 / (vec3<f32>(1f, 1f, 1f) - min(_e3708, vec3<f32>(0.995f, 0.995f, 0.995f)))) * _e3705));
                            phi_21116_ = (_e3683 + 1i);
                        }
                    }
                    let _e3719 = local_46;
                    let _e3722 = local_47;
                    phi_21119_ = mix(_e3612, ((_e3719 * vec3<f32>(0.083333336f, 0.083333336f, 0.083333336f)) + (_e3612 * (1f - (_e3722 * 0.083333336f)))), vec3(_e3648));
                    break;
                }
            }
            let _e3730 = phi_21119_;
            phi_21143_ = _e3730;
        }
        let _e3732 = phi_21143_;
        let _e3737 = ((_e3284 * _e3610.x) + vec3(_e3610.y));
        let _e3739 = ((vec3<f32>(1f, 1f, 1f) - _e3737) * _e3282);
        let _e3744 = (_e3371 + (((_e3739 * _e3608) + (_e3737 * _e3732)) * _e1267));
        let _e3747 = global.member_34[0u];
        let _e3750 = global.member_34[1u];
        phi_21645_ = _e3744;
        if ((_e3747 + _e3750) > 0.5f) {
            if (_e3750 > 0.5f) {
                phi_21179_ = _e3608;
                phi_21178_ = 0i;
                loop {
                    let _e3757 = phi_21179_;
                    let _e3759 = phi_21178_;
                    local_62 = _e3757;
                    if (_e3759 < i32(_e3750)) {
                        let _e3762 = (8i * (i32(_e3747) + _e3759));
                        let _e3766 = global_3.member[(_e3762 + 3i)];
                        let _e3767 = bitcast<vec4<f32>>(_e3766);
                        let _e3770 = global_3.member[_e3762];
                        let _e3771 = bitcast<vec4<f32>>(_e3770);
                        let _e3775 = global_3.member[(_e3762 + 1i)];
                        let _e3776 = bitcast<vec4<f32>>(_e3775);
                        let _e3780 = global_3.member[(_e3762 + 2i)];
                        let _e3781 = bitcast<vec4<f32>>(_e3780);
                        let _e3782 = _e3771.xyz;
                        let _e3786 = _e3776.xyz;
                        let _e3790 = _e3781.xyz;
                        let _e3794 = vec3<f32>((dot(_e3782, _e813) + _e3771.w), (dot(_e3786, _e813) + _e3776.w), (dot(_e3790, _e813) + _e3781.w));
                        let _e3795 = _e3767.xyz;
                        switch bitcast<i32>(0u) {
                            default: {
                                let _e3799 = (_e3795 - abs(_e3794));
                                let _e3804 = min(_e3799.x, min(_e3799.y, _e3799.z));
                                if (_e3804 <= 0f) {
                                    phi_21679_ = 0f;
                                    break;
                                }
                                if (_e3767.w <= 0f) {
                                    phi_21679_ = 1f;
                                    break;
                                }
                                let _e3808 = min((_e3804 / _e3767.w), 1f);
                                phi_21679_ = ((_e3808 * _e3808) * (3f - (2f * _e3808)));
                                break;
                            }
                        }
                        let _e3814 = phi_21679_;
                        if (_e3814 <= 0f) {
                            phi_22097_ = _e3757;
                            continue;
                        }
                        let _e3819 = global_3.member[(_e3762 + 4i)];
                        let _e3821 = bitcast<vec4<f32>>(_e3819).xyz;
                        let _e3825 = global_3.member[(_e3762 + 5i)];
                        let _e3826 = bitcast<vec4<f32>>(_e3825);
                        let _e3831 = global_3.member[(_e3762 + 6i)][0u];
                        let _e3832 = bitcast<i32>(_e3831);
                        let _e3833 = dot(_e3782, _e805);
                        let _e3834 = dot(_e3786, _e805);
                        let _e3835 = dot(_e3790, _e805);
                        let _e3836 = vec3<f32>(_e3833, _e3834, _e3835);
                        let _e3842 = ((_e813 + (_e805 * _e3826.x)) + (_e815 * _e3826.y));
                        let _e3857 = clamp(((((vec3<f32>((dot(_e3782, _e3842) + _e3771.w), (dot(_e3786, _e3842) + _e3776.w), (dot(_e3790, _e3842) + _e3781.w)) + _e3795) / max((_e3795 * 2f), vec3<f32>(0.000001f, 0.000001f, 0.000001f))) * _e3821) - vec3<f32>(0.5f, 0.5f, 0.5f)), vec3<f32>(0f, 0f, 0f), (_e3821 - vec3<f32>(1f, 1f, 1f)));
                        let _e3858 = vec3<i32>(_e3821);
                        let _e3862 = min(vec3<i32>(_e3857), max((_e3858 - vec3<i32>(2i, 2i, 2i)), vec3<i32>(0i, 0i, 0i)));
                        let _e3864 = (_e3857 - vec3<f32>(_e3862));
                        let _e3865 = (0.488603f * _e3834);
                        let _e3866 = (0.488603f * _e3835);
                        let _e3867 = (0.488603f * _e3833);
                        let _e3868 = (1.092548f * _e3833);
                        let _e3869 = (_e3868 * _e3834);
                        let _e3871 = ((1.092548f * _e3834) * _e3835);
                        let _e3875 = (0.315392f * (((3f * _e3835) * _e3835) - 1f));
                        let _e3876 = (_e3868 * _e3835);
                        let _e3880 = (0.546274f * ((_e3833 * _e3833) - (_e3834 * _e3834)));
                        let _e3881 = (_e3858 - vec3<i32>(1i, 1i, 1i));
                        let _e3882 = min(_e3862, _e3881);
                        let _e3893 = (_e3832 + ((_e3882.x + (_e3858.x * (_e3882.y + (_e3858.y * _e3882.z)))) * 4i));
                        let _e3894 = (vec3<f32>(1f, 1f, 1f) - _e3864);
                        let _e3901 = ((((((vec3<f32>(_e3882) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e3821) * _e3795) * 2f) - _e3795) - _e3794);
                        let _e3907 = (dot((_e3901 * inverseSqrt(max(dot(_e3901, _e3901), 0.0000000001f))), _e3836) + 1f);
                        let _e3910 = (_e3894.x * _e3894.y);
                        let _e3917 = (_e3893 + 3i);
                        let _e3921 = global_3.member[_e3917][1u];
                        let _e3926 = (((_e3910 * _e3894.z) * ((0.25f * (_e3907 * _e3907)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e3921).y > 0.5f)));
                        let _e3929 = global_3.member[_e3893];
                        let _e3933 = global_3.member[(_e3893 + 1i)];
                        let _e3937 = global_3.member[(_e3893 + 2i)];
                        let _e3940 = global_3.member[_e3917];
                        let _e3942 = unpack2x16float(_e3929.x);
                        let _e3944 = unpack2x16float(_e3929.y);
                        let _e3946 = unpack2x16float(_e3929.z);
                        let _e3948 = unpack2x16float(_e3929.w);
                        let _e3950 = unpack2x16float(_e3933.x);
                        let _e3952 = unpack2x16float(_e3933.y);
                        let _e3954 = unpack2x16float(_e3933.z);
                        let _e3956 = unpack2x16float(_e3933.w);
                        let _e3958 = unpack2x16float(_e3937.x);
                        let _e3960 = unpack2x16float(_e3937.y);
                        let _e3962 = unpack2x16float(_e3937.z);
                        let _e3964 = unpack2x16float(_e3937.w);
                        let _e3966 = unpack2x16float(_e3940.x);
                        let _e4022 = ((((((((((vec3<f32>(_e3942.x, _e3942.y, _e3944.x) * 0.282095f) + (vec3<f32>(_e3944.y, _e3946.x, _e3946.y) * _e3865)) + (vec3<f32>(_e3948.x, _e3948.y, _e3950.x) * _e3866)) + (vec3<f32>(_e3950.y, _e3952.x, _e3952.y) * _e3867)) + (vec3<f32>(_e3954.x, _e3954.y, _e3956.x) * _e3869)) + (vec3<f32>(_e3956.y, _e3958.x, _e3958.y) * _e3871)) + (vec3<f32>(_e3960.x, _e3960.y, _e3962.x) * _e3875)) + (vec3<f32>(_e3962.y, _e3964.x, _e3964.y) * _e3876)) + (vec3<f32>(_e3966.x, _e3966.y, unpack2x16float(_e3940.y).x) * _e3880)) * _e3926);
                        let _e4028 = min((_e3862 + vec3<i32>(1i, 0i, 0i)), _e3881);
                        let _e4037 = (_e3832 + ((_e4028.x + (_e3858.x * (_e4028.y + (_e3858.y * _e4028.z)))) * 4i));
                        let _e4044 = ((((((vec3<f32>(_e4028) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e3821) * _e3795) * 2f) - _e3795) - _e3794);
                        let _e4050 = (dot((_e4044 * inverseSqrt(max(dot(_e4044, _e4044), 0.0000000001f))), _e3836) + 1f);
                        let _e4052 = (_e3864.x * _e3894.y);
                        let _e4058 = (_e4037 + 3i);
                        let _e4062 = global_3.member[_e4058][1u];
                        let _e4067 = (((_e4052 * _e3894.z) * ((0.25f * (_e4050 * _e4050)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e4062).y > 0.5f)));
                        let _e4070 = global_3.member[_e4037];
                        let _e4074 = global_3.member[(_e4037 + 1i)];
                        let _e4078 = global_3.member[(_e4037 + 2i)];
                        let _e4081 = global_3.member[_e4058];
                        let _e4083 = unpack2x16float(_e4070.x);
                        let _e4085 = unpack2x16float(_e4070.y);
                        let _e4087 = unpack2x16float(_e4070.z);
                        let _e4089 = unpack2x16float(_e4070.w);
                        let _e4091 = unpack2x16float(_e4074.x);
                        let _e4093 = unpack2x16float(_e4074.y);
                        let _e4095 = unpack2x16float(_e4074.z);
                        let _e4097 = unpack2x16float(_e4074.w);
                        let _e4099 = unpack2x16float(_e4078.x);
                        let _e4101 = unpack2x16float(_e4078.y);
                        let _e4103 = unpack2x16float(_e4078.z);
                        let _e4105 = unpack2x16float(_e4078.w);
                        let _e4107 = unpack2x16float(_e4081.x);
                        let _e4163 = ((((((((((vec3<f32>(_e4083.x, _e4083.y, _e4085.x) * 0.282095f) + (vec3<f32>(_e4085.y, _e4087.x, _e4087.y) * _e3865)) + (vec3<f32>(_e4089.x, _e4089.y, _e4091.x) * _e3866)) + (vec3<f32>(_e4091.y, _e4093.x, _e4093.y) * _e3867)) + (vec3<f32>(_e4095.x, _e4095.y, _e4097.x) * _e3869)) + (vec3<f32>(_e4097.y, _e4099.x, _e4099.y) * _e3871)) + (vec3<f32>(_e4101.x, _e4101.y, _e4103.x) * _e3875)) + (vec3<f32>(_e4103.y, _e4105.x, _e4105.y) * _e3876)) + (vec3<f32>(_e4107.x, _e4107.y, unpack2x16float(_e4081.y).x) * _e3880)) * _e4067);
                        let _e4170 = min((_e3862 + vec3<i32>(0i, 1i, 0i)), _e3881);
                        let _e4179 = (_e3832 + ((_e4170.x + (_e3858.x * (_e4170.y + (_e3858.y * _e4170.z)))) * 4i));
                        let _e4186 = ((((((vec3<f32>(_e4170) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e3821) * _e3795) * 2f) - _e3795) - _e3794);
                        let _e4192 = (dot((_e4186 * inverseSqrt(max(dot(_e4186, _e4186), 0.0000000001f))), _e3836) + 1f);
                        let _e4194 = (_e3894.x * _e3864.y);
                        let _e4200 = (_e4179 + 3i);
                        let _e4204 = global_3.member[_e4200][1u];
                        let _e4209 = (((_e4194 * _e3894.z) * ((0.25f * (_e4192 * _e4192)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e4204).y > 0.5f)));
                        let _e4212 = global_3.member[_e4179];
                        let _e4216 = global_3.member[(_e4179 + 1i)];
                        let _e4220 = global_3.member[(_e4179 + 2i)];
                        let _e4223 = global_3.member[_e4200];
                        let _e4225 = unpack2x16float(_e4212.x);
                        let _e4227 = unpack2x16float(_e4212.y);
                        let _e4229 = unpack2x16float(_e4212.z);
                        let _e4231 = unpack2x16float(_e4212.w);
                        let _e4233 = unpack2x16float(_e4216.x);
                        let _e4235 = unpack2x16float(_e4216.y);
                        let _e4237 = unpack2x16float(_e4216.z);
                        let _e4239 = unpack2x16float(_e4216.w);
                        let _e4241 = unpack2x16float(_e4220.x);
                        let _e4243 = unpack2x16float(_e4220.y);
                        let _e4245 = unpack2x16float(_e4220.z);
                        let _e4247 = unpack2x16float(_e4220.w);
                        let _e4249 = unpack2x16float(_e4223.x);
                        let _e4305 = ((((((((((vec3<f32>(_e4225.x, _e4225.y, _e4227.x) * 0.282095f) + (vec3<f32>(_e4227.y, _e4229.x, _e4229.y) * _e3865)) + (vec3<f32>(_e4231.x, _e4231.y, _e4233.x) * _e3866)) + (vec3<f32>(_e4233.y, _e4235.x, _e4235.y) * _e3867)) + (vec3<f32>(_e4237.x, _e4237.y, _e4239.x) * _e3869)) + (vec3<f32>(_e4239.y, _e4241.x, _e4241.y) * _e3871)) + (vec3<f32>(_e4243.x, _e4243.y, _e4245.x) * _e3875)) + (vec3<f32>(_e4245.y, _e4247.x, _e4247.y) * _e3876)) + (vec3<f32>(_e4249.x, _e4249.y, unpack2x16float(_e4223.y).x) * _e3880)) * _e4209);
                        let _e4312 = min((_e3862 + vec3<i32>(1i, 1i, 0i)), _e3881);
                        let _e4321 = (_e3832 + ((_e4312.x + (_e3858.x * (_e4312.y + (_e3858.y * _e4312.z)))) * 4i));
                        let _e4328 = ((((((vec3<f32>(_e4312) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e3821) * _e3795) * 2f) - _e3795) - _e3794);
                        let _e4334 = (dot((_e4328 * inverseSqrt(max(dot(_e4328, _e4328), 0.0000000001f))), _e3836) + 1f);
                        let _e4335 = (_e3864.x * _e3864.y);
                        let _e4341 = (_e4321 + 3i);
                        let _e4345 = global_3.member[_e4341][1u];
                        let _e4350 = (((_e4335 * _e3894.z) * ((0.25f * (_e4334 * _e4334)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e4345).y > 0.5f)));
                        let _e4353 = global_3.member[_e4321];
                        let _e4357 = global_3.member[(_e4321 + 1i)];
                        let _e4361 = global_3.member[(_e4321 + 2i)];
                        let _e4364 = global_3.member[_e4341];
                        let _e4366 = unpack2x16float(_e4353.x);
                        let _e4368 = unpack2x16float(_e4353.y);
                        let _e4370 = unpack2x16float(_e4353.z);
                        let _e4372 = unpack2x16float(_e4353.w);
                        let _e4374 = unpack2x16float(_e4357.x);
                        let _e4376 = unpack2x16float(_e4357.y);
                        let _e4378 = unpack2x16float(_e4357.z);
                        let _e4380 = unpack2x16float(_e4357.w);
                        let _e4382 = unpack2x16float(_e4361.x);
                        let _e4384 = unpack2x16float(_e4361.y);
                        let _e4386 = unpack2x16float(_e4361.z);
                        let _e4388 = unpack2x16float(_e4361.w);
                        let _e4390 = unpack2x16float(_e4364.x);
                        let _e4446 = ((((((((((vec3<f32>(_e4366.x, _e4366.y, _e4368.x) * 0.282095f) + (vec3<f32>(_e4368.y, _e4370.x, _e4370.y) * _e3865)) + (vec3<f32>(_e4372.x, _e4372.y, _e4374.x) * _e3866)) + (vec3<f32>(_e4374.y, _e4376.x, _e4376.y) * _e3867)) + (vec3<f32>(_e4378.x, _e4378.y, _e4380.x) * _e3869)) + (vec3<f32>(_e4380.y, _e4382.x, _e4382.y) * _e3871)) + (vec3<f32>(_e4384.x, _e4384.y, _e4386.x) * _e3875)) + (vec3<f32>(_e4386.y, _e4388.x, _e4388.y) * _e3876)) + (vec3<f32>(_e4390.x, _e4390.y, unpack2x16float(_e4364.y).x) * _e3880)) * _e4350);
                        let _e4453 = min((_e3862 + vec3<i32>(0i, 0i, 1i)), _e3881);
                        let _e4462 = (_e3832 + ((_e4453.x + (_e3858.x * (_e4453.y + (_e3858.y * _e4453.z)))) * 4i));
                        let _e4469 = ((((((vec3<f32>(_e4453) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e3821) * _e3795) * 2f) - _e3795) - _e3794);
                        let _e4475 = (dot((_e4469 * inverseSqrt(max(dot(_e4469, _e4469), 0.0000000001f))), _e3836) + 1f);
                        let _e4482 = (_e4462 + 3i);
                        let _e4486 = global_3.member[_e4482][1u];
                        let _e4491 = (((_e3910 * _e3864.z) * ((0.25f * (_e4475 * _e4475)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e4486).y > 0.5f)));
                        let _e4494 = global_3.member[_e4462];
                        let _e4498 = global_3.member[(_e4462 + 1i)];
                        let _e4502 = global_3.member[(_e4462 + 2i)];
                        let _e4505 = global_3.member[_e4482];
                        let _e4507 = unpack2x16float(_e4494.x);
                        let _e4509 = unpack2x16float(_e4494.y);
                        let _e4511 = unpack2x16float(_e4494.z);
                        let _e4513 = unpack2x16float(_e4494.w);
                        let _e4515 = unpack2x16float(_e4498.x);
                        let _e4517 = unpack2x16float(_e4498.y);
                        let _e4519 = unpack2x16float(_e4498.z);
                        let _e4521 = unpack2x16float(_e4498.w);
                        let _e4523 = unpack2x16float(_e4502.x);
                        let _e4525 = unpack2x16float(_e4502.y);
                        let _e4527 = unpack2x16float(_e4502.z);
                        let _e4529 = unpack2x16float(_e4502.w);
                        let _e4531 = unpack2x16float(_e4505.x);
                        let _e4587 = ((((((((((vec3<f32>(_e4507.x, _e4507.y, _e4509.x) * 0.282095f) + (vec3<f32>(_e4509.y, _e4511.x, _e4511.y) * _e3865)) + (vec3<f32>(_e4513.x, _e4513.y, _e4515.x) * _e3866)) + (vec3<f32>(_e4515.y, _e4517.x, _e4517.y) * _e3867)) + (vec3<f32>(_e4519.x, _e4519.y, _e4521.x) * _e3869)) + (vec3<f32>(_e4521.y, _e4523.x, _e4523.y) * _e3871)) + (vec3<f32>(_e4525.x, _e4525.y, _e4527.x) * _e3875)) + (vec3<f32>(_e4527.y, _e4529.x, _e4529.y) * _e3876)) + (vec3<f32>(_e4531.x, _e4531.y, unpack2x16float(_e4505.y).x) * _e3880)) * _e4491);
                        let _e4594 = min((_e3862 + vec3<i32>(1i, 0i, 1i)), _e3881);
                        let _e4603 = (_e3832 + ((_e4594.x + (_e3858.x * (_e4594.y + (_e3858.y * _e4594.z)))) * 4i));
                        let _e4610 = ((((((vec3<f32>(_e4594) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e3821) * _e3795) * 2f) - _e3795) - _e3794);
                        let _e4616 = (dot((_e4610 * inverseSqrt(max(dot(_e4610, _e4610), 0.0000000001f))), _e3836) + 1f);
                        let _e4622 = (_e4603 + 3i);
                        let _e4626 = global_3.member[_e4622][1u];
                        let _e4631 = (((_e4052 * _e3864.z) * ((0.25f * (_e4616 * _e4616)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e4626).y > 0.5f)));
                        let _e4634 = global_3.member[_e4603];
                        let _e4638 = global_3.member[(_e4603 + 1i)];
                        let _e4642 = global_3.member[(_e4603 + 2i)];
                        let _e4645 = global_3.member[_e4622];
                        let _e4647 = unpack2x16float(_e4634.x);
                        let _e4649 = unpack2x16float(_e4634.y);
                        let _e4651 = unpack2x16float(_e4634.z);
                        let _e4653 = unpack2x16float(_e4634.w);
                        let _e4655 = unpack2x16float(_e4638.x);
                        let _e4657 = unpack2x16float(_e4638.y);
                        let _e4659 = unpack2x16float(_e4638.z);
                        let _e4661 = unpack2x16float(_e4638.w);
                        let _e4663 = unpack2x16float(_e4642.x);
                        let _e4665 = unpack2x16float(_e4642.y);
                        let _e4667 = unpack2x16float(_e4642.z);
                        let _e4669 = unpack2x16float(_e4642.w);
                        let _e4671 = unpack2x16float(_e4645.x);
                        let _e4727 = ((((((((((vec3<f32>(_e4647.x, _e4647.y, _e4649.x) * 0.282095f) + (vec3<f32>(_e4649.y, _e4651.x, _e4651.y) * _e3865)) + (vec3<f32>(_e4653.x, _e4653.y, _e4655.x) * _e3866)) + (vec3<f32>(_e4655.y, _e4657.x, _e4657.y) * _e3867)) + (vec3<f32>(_e4659.x, _e4659.y, _e4661.x) * _e3869)) + (vec3<f32>(_e4661.y, _e4663.x, _e4663.y) * _e3871)) + (vec3<f32>(_e4665.x, _e4665.y, _e4667.x) * _e3875)) + (vec3<f32>(_e4667.y, _e4669.x, _e4669.y) * _e3876)) + (vec3<f32>(_e4671.x, _e4671.y, unpack2x16float(_e4645.y).x) * _e3880)) * _e4631);
                        let _e4734 = min((_e3862 + vec3<i32>(0i, 1i, 1i)), _e3881);
                        let _e4743 = (_e3832 + ((_e4734.x + (_e3858.x * (_e4734.y + (_e3858.y * _e4734.z)))) * 4i));
                        let _e4750 = ((((((vec3<f32>(_e4734) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e3821) * _e3795) * 2f) - _e3795) - _e3794);
                        let _e4756 = (dot((_e4750 * inverseSqrt(max(dot(_e4750, _e4750), 0.0000000001f))), _e3836) + 1f);
                        let _e4762 = (_e4743 + 3i);
                        let _e4766 = global_3.member[_e4762][1u];
                        let _e4771 = (((_e4194 * _e3864.z) * ((0.25f * (_e4756 * _e4756)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e4766).y > 0.5f)));
                        let _e4774 = global_3.member[_e4743];
                        let _e4778 = global_3.member[(_e4743 + 1i)];
                        let _e4782 = global_3.member[(_e4743 + 2i)];
                        let _e4785 = global_3.member[_e4762];
                        let _e4787 = unpack2x16float(_e4774.x);
                        let _e4789 = unpack2x16float(_e4774.y);
                        let _e4791 = unpack2x16float(_e4774.z);
                        let _e4793 = unpack2x16float(_e4774.w);
                        let _e4795 = unpack2x16float(_e4778.x);
                        let _e4797 = unpack2x16float(_e4778.y);
                        let _e4799 = unpack2x16float(_e4778.z);
                        let _e4801 = unpack2x16float(_e4778.w);
                        let _e4803 = unpack2x16float(_e4782.x);
                        let _e4805 = unpack2x16float(_e4782.y);
                        let _e4807 = unpack2x16float(_e4782.z);
                        let _e4809 = unpack2x16float(_e4782.w);
                        let _e4811 = unpack2x16float(_e4785.x);
                        let _e4867 = ((((((((((vec3<f32>(_e4787.x, _e4787.y, _e4789.x) * 0.282095f) + (vec3<f32>(_e4789.y, _e4791.x, _e4791.y) * _e3865)) + (vec3<f32>(_e4793.x, _e4793.y, _e4795.x) * _e3866)) + (vec3<f32>(_e4795.y, _e4797.x, _e4797.y) * _e3867)) + (vec3<f32>(_e4799.x, _e4799.y, _e4801.x) * _e3869)) + (vec3<f32>(_e4801.y, _e4803.x, _e4803.y) * _e3871)) + (vec3<f32>(_e4805.x, _e4805.y, _e4807.x) * _e3875)) + (vec3<f32>(_e4807.y, _e4809.x, _e4809.y) * _e3876)) + (vec3<f32>(_e4811.x, _e4811.y, unpack2x16float(_e4785.y).x) * _e3880)) * _e4771);
                        let _e4874 = min((_e3862 + vec3<i32>(1i, 1i, 1i)), _e3881);
                        let _e4883 = (_e3832 + ((_e4874.x + (_e3858.x * (_e4874.y + (_e3858.y * _e4874.z)))) * 4i));
                        let _e4890 = ((((((vec3<f32>(_e4874) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e3821) * _e3795) * 2f) - _e3795) - _e3794);
                        let _e4896 = (dot((_e4890 * inverseSqrt(max(dot(_e4890, _e4890), 0.0000000001f))), _e3836) + 1f);
                        let _e4902 = (_e4883 + 3i);
                        let _e4906 = global_3.member[_e4902][1u];
                        let _e4911 = (((_e4335 * _e3864.z) * ((0.25f * (_e4896 * _e4896)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e4906).y > 0.5f)));
                        let _e4914 = global_3.member[_e4883];
                        let _e4918 = global_3.member[(_e4883 + 1i)];
                        let _e4922 = global_3.member[(_e4883 + 2i)];
                        let _e4925 = global_3.member[_e4902];
                        let _e4927 = unpack2x16float(_e4914.x);
                        let _e4929 = unpack2x16float(_e4914.y);
                        let _e4931 = unpack2x16float(_e4914.z);
                        let _e4933 = unpack2x16float(_e4914.w);
                        let _e4935 = unpack2x16float(_e4918.x);
                        let _e4937 = unpack2x16float(_e4918.y);
                        let _e4939 = unpack2x16float(_e4918.z);
                        let _e4941 = unpack2x16float(_e4918.w);
                        let _e4943 = unpack2x16float(_e4922.x);
                        let _e4945 = unpack2x16float(_e4922.y);
                        let _e4947 = unpack2x16float(_e4922.z);
                        let _e4949 = unpack2x16float(_e4922.w);
                        let _e4951 = unpack2x16float(_e4925.x);
                        let _e5007 = ((((((((((vec3<f32>(_e4927.x, _e4927.y, _e4929.x) * 0.282095f) + (vec3<f32>(_e4929.y, _e4931.x, _e4931.y) * _e3865)) + (vec3<f32>(_e4933.x, _e4933.y, _e4935.x) * _e3866)) + (vec3<f32>(_e4935.y, _e4937.x, _e4937.y) * _e3867)) + (vec3<f32>(_e4939.x, _e4939.y, _e4941.x) * _e3869)) + (vec3<f32>(_e4941.y, _e4943.x, _e4943.y) * _e3871)) + (vec3<f32>(_e4945.x, _e4945.y, _e4947.x) * _e3875)) + (vec3<f32>(_e4947.y, _e4949.x, _e4949.y) * _e3876)) + (vec3<f32>(_e4951.x, _e4951.y, unpack2x16float(_e4925.y).x) * _e3880)) * _e4911);
                        let _e5012 = (((((((vec4<f32>(_e4022.x, _e4022.y, _e4022.z, _e3926) + vec4<f32>(_e4163.x, _e4163.y, _e4163.z, _e4067)) + vec4<f32>(_e4305.x, _e4305.y, _e4305.z, _e4209)) + vec4<f32>(_e4446.x, _e4446.y, _e4446.z, _e4350)) + vec4<f32>(_e4587.x, _e4587.y, _e4587.z, _e4491)) + vec4<f32>(_e4727.x, _e4727.y, _e4727.z, _e4631)) + vec4<f32>(_e4867.x, _e4867.y, _e4867.z, _e4771)) + vec4<f32>(_e5007.x, _e5007.y, _e5007.z, _e4911));
                        phi_22098_ = _e3757;
                        if (_e5012.w > 0.00001f) {
                            phi_22098_ = mix(_e3757, ((max(_e5012.xyz, vec3<f32>(0f, 0f, 0f)) / vec3(_e5012.w)) * _e3826.z), vec3(_e3814));
                        }
                        let _e5024 = phi_22098_;
                        phi_22097_ = _e5024;
                        continue;
                    } else {
                        break;
                    }
                    continuing {
                        let _e5026 = phi_22097_;
                        phi_21179_ = _e5026;
                        phi_21178_ = (_e3759 + 1i);
                    }
                }
                let _e7880 = local_62;
                phi_21180_ = _e7880;
            } else {
                phi_21180_ = _e3608;
            }
            let _e5029 = phi_21180_;
            phi_21408_ = _e3732;
            if (_e3747 > 0.5f) {
                if _e3375 {
                    let _e5032 = reflect(-(_e815), _e3302);
                    let _e5034 = global.member_29;
                    let _e5053 = vec2<f32>(((atan2(((_e5034.z * _e5032.x) - (_e5034.w * _e5032.z)), -(((_e5034.w * _e5032.x) + (_e5034.z * _e5032.z)))) * 0.15915494f) + 0.5f), (acos(clamp(_e5032.y, -1f, 1f)) * 0.31830987f));
                    let _e5054 = (_e3279 * 5f);
                    let _e5056 = min(i32(_e5054), 4i);
                    local_9 = array<vec4<i32>, 6>(vec4<i32>(0i, 0i, 512i, 256i), vec4<i32>(0i, 256i, 256i, 128i), vec4<i32>(256i, 256i, 128i, 64i), vec4<i32>(384i, 256i, 64i, 32i), vec4<i32>(448i, 256i, 32i, 16i), vec4<i32>(480i, 256i, 16i, 8i));
                    let _e5058 = local_9[_e5056];
                    let _e5062 = ((_e5053 * vec2<f32>(_e5058.zw)) - vec2<f32>(0.5f, 0.5f));
                    let _e5063 = floor(_e5062);
                    let _e5064 = (_e5062 - _e5063);
                    let _e5066 = i32(_e5063.x);
                    let _e5068 = i32(_e5063.y);
                    phi_21203_ = _e5066;
                    if (_e5066 < 0i) {
                        phi_21203_ = (_e5066 + _e5058.z);
                    }
                    let _e5073 = phi_21203_;
                    phi_21204_ = _e5073;
                    if (_e5073 >= _e5058.z) {
                        phi_21204_ = (_e5073 - _e5058.z);
                    }
                    let _e5078 = phi_21204_;
                    let _e5079 = (_e5078 + 1i);
                    let _e5081 = select(_e5079, 0i, (_e5079 == _e5058.z));
                    let _e5085 = min((_e5068 + 1i), (_e5058.w - 1i));
                    let _e5086 = max(_e5068, 0i);
                    let _e5087 = _e5058.xy;
                    let _e5090 = textureLoad(global_4, (_e5087 + vec2<i32>(_e5078, _e5086)), 0i);
                    let _e5094 = textureLoad(global_4, (_e5087 + vec2<i32>(_e5081, _e5086)), 0i);
                    let _e5098 = textureLoad(global_4, (_e5087 + vec2<i32>(_e5078, _e5085)), 0i);
                    let _e5102 = textureLoad(global_4, (_e5087 + vec2<i32>(_e5081, _e5085)), 0i);
                    let _e5105 = vec3(_e5064.x);
                    local_10 = array<vec4<i32>, 6>(vec4<i32>(0i, 0i, 512i, 256i), vec4<i32>(0i, 256i, 256i, 128i), vec4<i32>(256i, 256i, 128i, 64i), vec4<i32>(384i, 256i, 64i, 32i), vec4<i32>(448i, 256i, 32i, 16i), vec4<i32>(480i, 256i, 16i, 8i));
                    let _e5113 = local_10[(_e5056 + 1i)];
                    let _e5117 = ((_e5053 * vec2<f32>(_e5113.zw)) - vec2<f32>(0.5f, 0.5f));
                    let _e5118 = floor(_e5117);
                    let _e5119 = (_e5117 - _e5118);
                    let _e5121 = i32(_e5118.x);
                    let _e5123 = i32(_e5118.y);
                    phi_21210_ = _e5121;
                    if (_e5121 < 0i) {
                        phi_21210_ = (_e5121 + _e5113.z);
                    }
                    let _e5128 = phi_21210_;
                    phi_21211_ = _e5128;
                    if (_e5128 >= _e5113.z) {
                        phi_21211_ = (_e5128 - _e5113.z);
                    }
                    let _e5133 = phi_21211_;
                    let _e5134 = (_e5133 + 1i);
                    let _e5136 = select(_e5134, 0i, (_e5134 == _e5113.z));
                    let _e5140 = min((_e5123 + 1i), (_e5113.w - 1i));
                    let _e5141 = max(_e5123, 0i);
                    let _e5142 = _e5113.xy;
                    let _e5145 = textureLoad(global_4, (_e5142 + vec2<i32>(_e5133, _e5141)), 0i);
                    let _e5149 = textureLoad(global_4, (_e5142 + vec2<i32>(_e5136, _e5141)), 0i);
                    let _e5153 = textureLoad(global_4, (_e5142 + vec2<i32>(_e5133, _e5140)), 0i);
                    let _e5157 = textureLoad(global_4, (_e5142 + vec2<i32>(_e5136, _e5140)), 0i);
                    let _e5160 = vec3(_e5119.x);
                    let _e5172 = global.member_29[1u];
                    phi_21217_ = (mix(mix(mix(_e5090.xyz, _e5094.xyz, _e5105), mix(_e5098.xyz, _e5102.xyz, _e5105), vec3(_e5064.y)), mix(mix(_e5145.xyz, _e5149.xyz, _e5160), mix(_e5153.xyz, _e5157.xyz, _e5160), vec3(_e5119.y)), vec3((_e5054 - f32(_e5056)))) * _e5172);
                } else {
                    let _e5177 = global.member_9;
                    let _e5180 = global.member_8;
                    let _e5189 = global.member_8[3u];
                    phi_21217_ = mix((mix(_e5177.xyz, _e5180.xyz, vec3(((reflect(-(_e815), _e3302).y * 0.5f) + 0.5f))) * _e5189), _e3608, vec3(_e3279));
                }
                let _e5194 = phi_21217_;
                let _e5196 = reflect(-(_e815), _e3302);
                phi_21299_ = vec3<f32>(0f, 0f, 0f);
                phi_21233_ = 0f;
                phi_21232_ = 0i;
                loop {
                    let _e5199 = phi_21299_;
                    let _e5201 = phi_21233_;
                    let _e5203 = phi_21232_;
                    local_48 = _e5201;
                    local_49 = _e5199;
                    if (_e5203 < i32(_e3747)) {
                        if (_e5201 > 0.999f) {
                            break;
                        }
                        let _e5206 = (_e5203 * 8i);
                        let _e5209 = global_3.member[_e5206];
                        let _e5210 = bitcast<vec4<f32>>(_e5209);
                        let _e5214 = global_3.member[(_e5206 + 1i)];
                        let _e5215 = bitcast<vec4<f32>>(_e5214);
                        let _e5219 = global_3.member[(_e5206 + 2i)];
                        let _e5220 = bitcast<vec4<f32>>(_e5219);
                        let _e5221 = _e5210.xyz;
                        let _e5225 = _e5215.xyz;
                        let _e5229 = _e5220.xyz;
                        let _e5233 = vec3<f32>((dot(_e5221, _e813) + _e5210.w), (dot(_e5225, _e813) + _e5215.w), (dot(_e5229, _e813) + _e5220.w));
                        let _e5237 = global_3.member[(_e5206 + 3i)];
                        let _e5238 = bitcast<vec4<f32>>(_e5237);
                        switch bitcast<i32>(0u) {
                            default: {
                                let _e5243 = (_e5238.xyz - abs(_e5233));
                                let _e5248 = min(_e5243.x, min(_e5243.y, _e5243.z));
                                if (_e5248 <= 0f) {
                                    phi_21234_ = 0f;
                                    break;
                                }
                                if (_e5238.w <= 0f) {
                                    phi_21234_ = 1f;
                                    break;
                                }
                                let _e5252 = min((_e5248 / _e5238.w), 1f);
                                phi_21234_ = ((_e5252 * _e5252) * (3f - (2f * _e5252)));
                                break;
                            }
                        }
                        let _e5258 = phi_21234_;
                        if (_e5258 <= 0f) {
                            phi_22112_ = _e5199;
                            phi_22111_ = _e5201;
                            continue;
                        }
                        let _e5263 = global_3.member[(_e5206 + 4i)];
                        let _e5264 = bitcast<vec4<f32>>(_e5263);
                        let _e5268 = global_3.member[(_e5206 + 5i)];
                        let _e5269 = bitcast<vec4<f32>>(_e5268);
                        let _e5273 = vec3<f32>(dot(_e5221, _e5196), dot(_e5225, _e5196), dot(_e5229, _e5196));
                        if (_e5264.w > 0.5f) {
                            let _e5276 = _e5264.xyz;
                            let _e5278 = -(_e5276);
                            let _e5279 = clamp(_e5233, _e5278, _e5276);
                            let _e5283 = step(vec3<f32>(0.000001f, 0.000001f, 0.000001f), abs(_e5273));
                            let _e5287 = mix(vec3<f32>(1000000000000000000000000000000f, 1000000000000000000000000000000f, 1000000000000000000000000000000f), ((mix(_e5278, _e5276, step(vec3<f32>(0f, 0f, 0f), _e5273)) - _e5279) / mix(vec3<f32>(0.000001f, 0.000001f, 0.000001f), _e5273, _e5283)), _e5283);
                            let _e5296 = ((_e5279 + (_e5273 * max(min(_e5287.x, min(_e5287.y, _e5287.z)), 0f))) - _e5269.xyz);
                            if (dot(_e5296, _e5296) > 0.000000000001f) {
                                phi_21235_ = normalize(_e5296);
                            } else {
                                phi_21235_ = _e5273;
                            }
                            let _e5301 = phi_21235_;
                            phi_21236_ = _e5301;
                        } else {
                            phi_21236_ = _e5273;
                        }
                        let _e5303 = phi_21236_;
                        let _e5308 = global_3.member[(_e5206 + 6i)][0u];
                        let _e5309 = bitcast<i32>(_e5308);
                        let _e5320 = vec2<f32>(((atan2(_e5303.x, -(_e5303.z)) * 0.15915494f) + 0.5f), (acos(clamp(_e5303.y, -1f, 1f)) * 0.31830987f));
                        let _e5321 = (_e3279 * 5f);
                        let _e5323 = min(i32(_e5321), 4i);
                        local_8 = array<vec3<i32>, 6>(vec3<i32>(0i, 256i, 128i), vec3<i32>(32768i, 128i, 64i), vec3<i32>(40960i, 64i, 32i), vec3<i32>(43008i, 32i, 16i), vec3<i32>(43520i, 16i, 8i), vec3<i32>(43648i, 8i, 4i));
                        let _e5325 = local_8[_e5323];
                        let _e5327 = (_e5309 + _e5325.x);
                        let _e5331 = ((_e5320 * vec2<f32>(_e5325.yz)) - vec2<f32>(0.5f, 0.5f));
                        let _e5332 = floor(_e5331);
                        let _e5333 = (_e5331 - _e5332);
                        let _e5335 = i32(_e5332.x);
                        let _e5337 = i32(_e5332.y);
                        phi_21237_ = _e5335;
                        if (_e5335 < 0i) {
                            phi_21237_ = (_e5335 + _e5325.y);
                        }
                        let _e5342 = phi_21237_;
                        phi_21238_ = _e5342;
                        if (_e5342 >= _e5325.y) {
                            phi_21238_ = (_e5342 - _e5325.y);
                        }
                        let _e5347 = phi_21238_;
                        let _e5348 = (_e5347 + 1i);
                        let _e5350 = select(_e5348, 0i, (_e5348 == _e5325.y));
                        let _e5357 = (_e5327 + (max(_e5337, 0i) * _e5325.y));
                        let _e5358 = (_e5357 + _e5347);
                        let _e5363 = global_3.member[(_e5358 >> bitcast<u32>(1i))];
                        if ((_e5358 & 1i) == 0i) {
                            phi_21244_ = _e5363.xy;
                        } else {
                            phi_21244_ = _e5363.zw;
                        }
                        let _e5369 = phi_21244_;
                        let _e5371 = unpack2x16float(_e5369.x);
                        let _e5378 = (_e5357 + _e5350);
                        let _e5383 = global_3.member[(_e5378 >> bitcast<u32>(1i))];
                        if ((_e5378 & 1i) == 0i) {
                            phi_21246_ = _e5383.xy;
                        } else {
                            phi_21246_ = _e5383.zw;
                        }
                        let _e5389 = phi_21246_;
                        let _e5391 = unpack2x16float(_e5389.x);
                        let _e5399 = (_e5327 + (min((_e5337 + 1i), (_e5325.z - 1i)) * _e5325.y));
                        let _e5400 = (_e5399 + _e5347);
                        let _e5405 = global_3.member[(_e5400 >> bitcast<u32>(1i))];
                        if ((_e5400 & 1i) == 0i) {
                            phi_21249_ = _e5405.xy;
                        } else {
                            phi_21249_ = _e5405.zw;
                        }
                        let _e5411 = phi_21249_;
                        let _e5413 = unpack2x16float(_e5411.x);
                        let _e5420 = (_e5399 + _e5350);
                        let _e5425 = global_3.member[(_e5420 >> bitcast<u32>(1i))];
                        if ((_e5420 & 1i) == 0i) {
                            phi_21250_ = _e5425.xy;
                        } else {
                            phi_21250_ = _e5425.zw;
                        }
                        let _e5431 = phi_21250_;
                        let _e5433 = unpack2x16float(_e5431.x);
                        let _e5441 = vec3(_e5333.x);
                        local_7 = array<vec3<i32>, 6>(vec3<i32>(0i, 256i, 128i), vec3<i32>(32768i, 128i, 64i), vec3<i32>(40960i, 64i, 32i), vec3<i32>(43008i, 32i, 16i), vec3<i32>(43520i, 16i, 8i), vec3<i32>(43648i, 8i, 4i));
                        let _e5449 = local_7[(_e5323 + 1i)];
                        let _e5451 = (_e5309 + _e5449.x);
                        let _e5455 = ((_e5320 * vec2<f32>(_e5449.yz)) - vec2<f32>(0.5f, 0.5f));
                        let _e5456 = floor(_e5455);
                        let _e5457 = (_e5455 - _e5456);
                        let _e5459 = i32(_e5456.x);
                        let _e5461 = i32(_e5456.y);
                        phi_21251_ = _e5459;
                        if (_e5459 < 0i) {
                            phi_21251_ = (_e5459 + _e5449.y);
                        }
                        let _e5466 = phi_21251_;
                        phi_21252_ = _e5466;
                        if (_e5466 >= _e5449.y) {
                            phi_21252_ = (_e5466 - _e5449.y);
                        }
                        let _e5471 = phi_21252_;
                        let _e5472 = (_e5471 + 1i);
                        let _e5474 = select(_e5472, 0i, (_e5472 == _e5449.y));
                        let _e5481 = (_e5451 + (max(_e5461, 0i) * _e5449.y));
                        let _e5482 = (_e5481 + _e5471);
                        let _e5487 = global_3.member[(_e5482 >> bitcast<u32>(1i))];
                        if ((_e5482 & 1i) == 0i) {
                            phi_21258_ = _e5487.xy;
                        } else {
                            phi_21258_ = _e5487.zw;
                        }
                        let _e5493 = phi_21258_;
                        let _e5495 = unpack2x16float(_e5493.x);
                        let _e5502 = (_e5481 + _e5474);
                        let _e5507 = global_3.member[(_e5502 >> bitcast<u32>(1i))];
                        if ((_e5502 & 1i) == 0i) {
                            phi_21260_ = _e5507.xy;
                        } else {
                            phi_21260_ = _e5507.zw;
                        }
                        let _e5513 = phi_21260_;
                        let _e5515 = unpack2x16float(_e5513.x);
                        let _e5523 = (_e5451 + (min((_e5461 + 1i), (_e5449.z - 1i)) * _e5449.y));
                        let _e5524 = (_e5523 + _e5471);
                        let _e5529 = global_3.member[(_e5524 >> bitcast<u32>(1i))];
                        if ((_e5524 & 1i) == 0i) {
                            phi_21263_ = _e5529.xy;
                        } else {
                            phi_21263_ = _e5529.zw;
                        }
                        let _e5535 = phi_21263_;
                        let _e5537 = unpack2x16float(_e5535.x);
                        let _e5544 = (_e5523 + _e5474);
                        let _e5549 = global_3.member[(_e5544 >> bitcast<u32>(1i))];
                        if ((_e5544 & 1i) == 0i) {
                            phi_21264_ = _e5549.xy;
                        } else {
                            phi_21264_ = _e5549.zw;
                        }
                        let _e5555 = phi_21264_;
                        let _e5557 = unpack2x16float(_e5555.x);
                        let _e5565 = vec3(_e5457.x);
                        let _e5578 = (_e5258 * (1f - _e5201));
                        phi_22112_ = (_e5199 + ((mix(mix(mix(vec3<f32>(_e5371.x, _e5371.y, unpack2x16float(_e5369.y).x), vec3<f32>(_e5391.x, _e5391.y, unpack2x16float(_e5389.y).x), _e5441), mix(vec3<f32>(_e5413.x, _e5413.y, unpack2x16float(_e5411.y).x), vec3<f32>(_e5433.x, _e5433.y, unpack2x16float(_e5431.y).x), _e5441), vec3(_e5333.y)), mix(mix(vec3<f32>(_e5495.x, _e5495.y, unpack2x16float(_e5493.y).x), vec3<f32>(_e5515.x, _e5515.y, unpack2x16float(_e5513.y).x), _e5565), mix(vec3<f32>(_e5537.x, _e5537.y, unpack2x16float(_e5535.y).x), vec3<f32>(_e5557.x, _e5557.y, unpack2x16float(_e5555.y).x), _e5565), vec3(_e5457.y)), vec3((_e5321 - f32(_e5323)))) * _e5269.w) * _e5578));
                        phi_22111_ = (_e5201 + _e5578);
                        continue;
                    } else {
                        break;
                    }
                    continuing {
                        let _e5583 = phi_22112_;
                        let _e5585 = phi_22111_;
                        phi_21299_ = _e5583;
                        phi_21233_ = _e5585;
                        phi_21232_ = (_e5203 + 1i);
                    }
                }
                let _e5588 = local_48;
                let _e5592 = local_49;
                let _e5593 = (_e5592 + (_e5194 * (1f - _e5588)));
                phi_4267_ = _e1249;
                if _e1249 {
                    let _e5596 = global.member_33[2u];
                    phi_4267_ = (_e5596 > 0.5f);
                }
                let _e5599 = phi_4267_;
                phi_21409_ = _e5593;
                if _e5599 {
                    switch bitcast<i32>(0u) {
                        default: {
                            let _e5602 = global.member_31;
                            let _e5603 = _e5602.xyz;
                            let _e5606 = global.member_33[0u];
                            let _e5611 = global.member_31[3u];
                            let _e5620 = global.member_32[1u];
                            let _e5626 = global.member_32[0u];
                            let _e5629 = (((_e5626 * (1f - smoothstep((_e5606 * 0.5f), _e5606, abs((dot(_e5603, _e813) - _e5611))))) * smoothstep(0.5f, 0.9f, dot(_e820, _e5603))) * (1f - smoothstep((_e5620 * 0.5f), _e5620, _e3279)));
                            if (_e5629 <= 0f) {
                                phi_21375_ = _e5593;
                                break;
                            }
                            let _e5636 = global.member_32[3u];
                            let _e5638 = (_e813 + ((_e805 - (_e5603 * dot(_e805, _e5603))) * _e5636));
                            let _e5640 = global.member_30;
                            let _e5645 = (_e5640 * vec4<f32>(_e5638.x, _e5638.y, _e5638.z, 1f));
                            let _e5657 = global.member_32[2u];
                            phi_21374_ = 0f;
                            phi_21373_ = vec3<f32>(0f, 0f, 0f);
                            phi_21372_ = 0i;
                            loop {
                                let _e5660 = phi_21374_;
                                let _e5662 = phi_21373_;
                                let _e5664 = phi_21372_;
                                local_50 = _e5662;
                                local_51 = _e5660;
                                if (_e5664 < 12i) {
                                    continue;
                                } else {
                                    break;
                                }
                                continuing {
                                    let _e5666 = f32(_e5664);
                                    let _e5671 = (_e5666 * 2.3999631f);
                                    let _e5675 = global.member_33[1u];
                                    let _e5680 = ((((vec2<f32>(_e5645.x, -(_e5645.y)) / vec2(_e5645.w)) * 0.5f) + vec2<f32>(0.5f, 0.5f)) + (vec2<f32>((cos(_e5671) * _e5675), sin(_e5671)) * (sqrt(((_e5666 + 0.5f) * 0.083333336f)) * (_e5657 * _e3279))));
                                    let _e5682 = min(_e5680, (vec2<f32>(1f, 1f) - _e5680));
                                    let _e5686 = smoothstep(0f, 0.04f, min(_e5682.x, _e5682.y));
                                    let _e5688 = textureSampleLevel(global_19, global_5, clamp(_e5680, vec2<f32>(0f, 0f), vec2<f32>(1f, 1f)), 0f);
                                    let _e5689 = _e5688.xyz;
                                    phi_21374_ = (_e5660 + (_e5688.w * _e5686));
                                    phi_21373_ = (_e5662 + ((_e5689 / (vec3<f32>(1f, 1f, 1f) - min(_e5689, vec3<f32>(0.995f, 0.995f, 0.995f)))) * _e5686));
                                    phi_21372_ = (_e5664 + 1i);
                                }
                            }
                            let _e5700 = local_50;
                            let _e5703 = local_51;
                            phi_21375_ = mix(_e5593, ((_e5700 * vec3<f32>(0.083333336f, 0.083333336f, 0.083333336f)) + (_e5593 * (1f - (_e5703 * 0.083333336f)))), vec3(_e5629));
                            break;
                        }
                    }
                    let _e5711 = phi_21375_;
                    phi_21409_ = _e5711;
                }
                let _e5713 = phi_21409_;
                phi_21408_ = _e5713;
            }
            let _e5715 = phi_21408_;
            phi_21645_ = (_e3744 + (((_e3739 * (_e5029 - _e3608)) + (_e3737 * (_e5715 - _e3732))) * _e1267));
        }
        let _e5724 = phi_21645_;
        let _e5727 = global.member_13[3u];
        phi_21715_ = _e5724;
        if (_e5727 > 0.5f) {
            let _e5730 = global.member_11;
            let _e5735 = global.member_11[3u];
            let _e5737 = global_16;
            let _e5740 = global.member_12;
            let _e5745 = global.member_13;
            let _e5748 = clamp(floor((_e5737.xy * _e5740.xy)), vec2<f32>(0f, 0f), (_e5745.xy - vec2<f32>(1f, 1f)));
            let _e5753 = global.member_12[2u];
            let _e5757 = global.member_12[3u];
            let _e5762 = global.member_13[2u];
            let _e5767 = global.member_13[1u];
            let _e5773 = global.member_13[0u];
            let _e5777 = u32(((((clamp(floor(((log2(max((dot(_e5730.xyz, _e813) + _e5735), 0.000001f)) * _e5753) + _e5757)), 0f, (_e5762 - 1f)) * _e5767) + _e5748.y) * _e5773) + _e5748.x));
            let _e5784 = global_17.member[(_e5777 >> bitcast<u32>(2i))][(_e5777 & 3u)];
            let _e5785 = (_e5784 & 65535u);
            phi_21644_ = _e5724;
            phi_21510_ = _e5785;
            loop {
                let _e5789 = phi_21644_;
                let _e5791 = phi_21510_;
                local_66 = _e5789;
                if (_e5791 < (_e5785 + (_e5784 >> bitcast<u32>(16i)))) {
                    let _e5794 = (_e5791 / 3u);
                    let _e5801 = global_18.member[(_e5794 >> bitcast<u32>(2i))][(_e5794 & 3u)];
                    let _e5807 = ((_e5801 >> bitcast<u32>(((_e5791 - (_e5794 * 3u)) * 10u))) & 1023u);
                    let _e5810 = global_12.member[_e5807];
                    let _e5812 = (_e5810.xyz - _e813);
                    let _e5813 = dot(_e5812, _e5812);
                    let _e5815 = (_e5813 * _e5810.w);
                    let _e5818 = clamp((1f - (_e5815 * _e5815)), 0f, 1f);
                    let _e5821 = (_e5812 * inverseSqrt(max(_e5813, 0.00000001f)));
                    let _e5824 = global_14.member[_e5807];
                    let _e5827 = global_15.member[_e5807];
                    let _e5835 = clamp(((dot(-(_e5821), _e5827.xyz) * _e5824.w) + _e5827.w), 0f, 1f);
                    let _e5842 = (_e5824.xyz * ((((_e5818 * _e5818) * _e5835) * _e5835) / max(_e5813, 0.0001f)));
                    phi_21642_ = _e5842;
                    if _e823 {
                        switch bitcast<i32>(0u) {
                            default: {
                                let _e5846 = global.member_21[2u];
                                let _e5847 = u32(_e5846);
                                if (_e5807 < _e5847) {
                                    let _e5851 = global.member_26[_e5807];
                                    let _e5854 = global.member_15[_e5807];
                                    let _e5863 = (_e5851.z * max((_e5854 * vec4<f32>(_e813.x, _e813.y, _e813.z, 1f)).w, 0f));
                                    let _e5866 = global.member_25[0u];
                                    let _e5872 = global.member_25[1u];
                                    let _e5875 = ((_e813 + (_e820 * (_e5863 * _e5866))) + (_e5821 * (_e5863 * _e5872)));
                                    let _e5880 = (_e5854 * vec4<f32>(_e5875.x, _e5875.y, _e5875.z, 1f));
                                    if (_e5880.w <= 0f) {
                                        phi_21537_ = 1f;
                                        break;
                                    }
                                    let _e5885 = (_e5880.xyz / vec3(_e5880.w));
                                    let _e5887 = (_e5885.x < 0f);
                                    phi_15354_ = _e5887;
                                    if !(_e5887) {
                                        phi_15354_ = (_e5885.x > 1f);
                                    }
                                    let _e5891 = phi_15354_;
                                    phi_15361_ = _e5891;
                                    if !(_e5891) {
                                        phi_15361_ = (_e5885.y < 0f);
                                    }
                                    let _e5896 = phi_15361_;
                                    phi_15368_ = _e5896;
                                    if !(_e5896) {
                                        phi_15368_ = (_e5885.y > 1f);
                                    }
                                    let _e5901 = phi_15368_;
                                    phi_15375_ = _e5901;
                                    if !(_e5901) {
                                        phi_15375_ = (_e5885.z > 1f);
                                    }
                                    let _e5906 = phi_15375_;
                                    if _e5906 {
                                        phi_21537_ = 1f;
                                        break;
                                    }
                                    let _e5909 = _e5851.xy;
                                    let _e5911 = global.member_23;
                                    let _e5912 = _e5911.zw;
                                    let _e5914 = global.member_22;
                                    let _e5915 = _e5914.xy;
                                    let _e5916 = (_e5915 * 0.5f);
                                    let _e5918 = (_e5909 + (_e5885.xy * _e5912));
                                    let _e5919 = (_e5909 + _e5916);
                                    let _e5921 = ((_e5909 + _e5912) - _e5916);
                                    let _e5926 = vec4<f32>(_e5919.x, _e5919.y, _e5921.x, _e5921.y);
                                    switch bitcast<i32>(0u) {
                                        default: {
                                            let _e5930 = global.member_22[2u];
                                            let _e5931 = i32(_e5930);
                                            if (_e5931 <= 0i) {
                                                let _e5935 = clamp(_e5918, _e5926.xy, _e5926.zw);
                                                let _e5940 = textureSampleCompare(global_2, global_1, vec3<f32>(_e5935.x, _e5935.y, _e5885.z).xy, _e5885.z);
                                                phi_21536_ = _e5940;
                                                break;
                                            }
                                            let _e5942 = ((_e5918 / _e5915) + vec2<f32>(0.5f, 0.5f));
                                            let _e5943 = floor(_e5942);
                                            let _e5944 = (_e5942 - _e5943);
                                            let _e5946 = (_e5931 == 1i);
                                            if _e5946 {
                                                let _e5947 = (_e5944 * 2f);
                                                local_3[0i] = (vec2<f32>(3f, 3f) - _e5947);
                                                local_3[1i] = (vec2<f32>(1f, 1f) + _e5947);
                                                let _e5953 = local_3[0i];
                                                local_4[0i] = (((vec2<f32>(2f, 2f) - _e5944) / _e5953) - vec2<f32>(1f, 1f));
                                                let _e5957 = local_3[1i];
                                                local_4[1i] = ((_e5944 / _e5957) + vec2<f32>(1f, 1f));
                                            } else {
                                                let _e5961 = (_e5944 * 3f);
                                                local_3[0i] = (vec2<f32>(4f, 4f) - _e5961);
                                                local_3[1i] = vec2<f32>(7f, 7f);
                                                local_3[2i] = (vec2<f32>(1f, 1f) + _e5961);
                                                let _e5969 = local_3[0i];
                                                local_4[0i] = (((vec2<f32>(3f, 3f) - (_e5944 * 2f)) / _e5969) - vec2<f32>(2f, 2f));
                                                let _e5974 = local_3[1i];
                                                local_4[1i] = ((vec2<f32>(3f, 3f) + _e5944) / _e5974);
                                                let _e5977 = local_3[2i];
                                                local_4[2i] = ((_e5944 / _e5977) + vec2<f32>(2f, 2f));
                                            }
                                            let _e5982 = select(3i, 2i, _e5946);
                                            phi_21529_ = 0f;
                                            phi_21526_ = 0i;
                                            loop {
                                                let _e5984 = phi_21529_;
                                                let _e5986 = phi_21526_;
                                                local_52 = _e5984;
                                                if (_e5986 < _e5982) {
                                                    phi_21535_ = _e5984;
                                                    phi_21532_ = 0i;
                                                    loop {
                                                        let _e5989 = phi_21535_;
                                                        let _e5991 = phi_21532_;
                                                        local_64 = _e5989;
                                                        if (_e5991 < _e5982) {
                                                            continue;
                                                        } else {
                                                            break;
                                                        }
                                                        continuing {
                                                            let _e5995 = local_4[_e5991][0u];
                                                            let _e5998 = local_4[_e5986][1u];
                                                            let _e6004 = clamp((_e5915 * ((_e5943 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e5995, _e5998))), _e5926.xy, _e5926.zw);
                                                            let _e6007 = local_3[_e5991][0u];
                                                            let _e6010 = local_3[_e5986][1u];
                                                            let _e6016 = textureSampleCompare(global_2, global_1, vec3<f32>(_e6004.x, _e6004.y, _e5885.z).xy, _e5885.z);
                                                            phi_21535_ = (_e5989 + ((_e6007 * _e6010) * _e6016));
                                                            phi_21532_ = (_e5991 + 1i);
                                                        }
                                                    }
                                                    continue;
                                                } else {
                                                    break;
                                                }
                                                continuing {
                                                    let _e7928 = local_64;
                                                    phi_21529_ = _e7928;
                                                    phi_21526_ = (_e5986 + 1i);
                                                }
                                            }
                                            let _e6022 = local_52;
                                            phi_21536_ = (_e6022 * select(0.0069444445f, 0.0625f, _e5946));
                                            break;
                                        }
                                    }
                                    let _e6025 = phi_21536_;
                                    phi_21537_ = _e6025;
                                    break;
                                }
                                let _e6026 = (_e5807 - _e5847);
                                let _e6029 = global.member_21[3u];
                                if (_e6026 >= u32(_e6029)) {
                                    phi_21537_ = 1f;
                                    break;
                                }
                                let _e6034 = global.member_27[_e6026];
                                let _e6037 = global.member_28[_e6026];
                                let _e6039 = _e6034.xyz;
                                let _e6042 = (_e6034.w * length((_e813 - _e6039)));
                                let _e6045 = global.member_25[0u];
                                let _e6051 = global.member_25[1u];
                                let _e6055 = (((_e813 + (_e820 * (_e6042 * _e6045))) + (_e5821 * (_e6042 * _e6051))) - _e6039);
                                let _e6056 = abs(_e6055);
                                let _e6059 = (_e6056.x >= _e6056.y);
                                phi_15445_ = _e6059;
                                if _e6059 {
                                    phi_15445_ = (_e6056.x >= _e6056.z);
                                }
                                let _e6063 = phi_15445_;
                                if _e6063 {
                                    phi_21513_ = select(1i, 0i, (_e6055.x > 0f));
                                    phi_21511_ = _e6056.x;
                                } else {
                                    let _e6068 = (_e6056.y >= _e6056.z);
                                    if _e6068 {
                                        phi_21514_ = select(3i, 2i, (_e6055.y > 0f));
                                    } else {
                                        phi_21514_ = select(5i, 4i, (_e6055.z > 0f));
                                    }
                                    let _e6076 = phi_21514_;
                                    phi_21513_ = _e6076;
                                    phi_21511_ = select(_e6056.z, _e6056.y, _e6068);
                                }
                                let _e6079 = phi_21513_;
                                let _e6081 = phi_21511_;
                                if (_e6081 <= 0f) {
                                    phi_21537_ = 1f;
                                    break;
                                }
                                local_5 = array<vec3<f32>, 6>(vec3<f32>(0f, 0f, 1f), vec3<f32>(0f, 0f, -1f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(1f, 0f, 0f));
                                let _e6084 = local_5[_e6079];
                                local_6 = array<vec3<f32>, 6>(vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 0f, -1f), vec3<f32>(0f, 0f, 1f), vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 1f, 0f));
                                let _e6087 = local_6[_e6079];
                                let _e6092 = global.member_24[2u];
                                let _e6095 = (vec2<f32>(dot(_e6055, _e6084), dot(_e6055, _e6087)) / vec2((_e6081 * _e6092)));
                                let _e6099 = (_e6037.z + (_e6037.w / _e6081));
                                if (_e6099 > 1f) {
                                    phi_21537_ = 1f;
                                    break;
                                }
                                let _e6114 = global.member_24;
                                let _e6115 = _e6114.xy;
                                let _e6117 = (_e6037.xy + (vec2<f32>(f32((_e6079 - (i32(floor((f32(_e6079) / f32(3i)))) * 3i))), f32((_e6079 / 3i))) * _e6115));
                                let _e6126 = global.member_22;
                                let _e6127 = _e6126.xy;
                                let _e6128 = (_e6127 * 0.5f);
                                let _e6130 = (_e6117 + (vec2<f32>((0.5f + (0.5f * _e6095.x)), (0.5f - (0.5f * _e6095.y))) * _e6115));
                                let _e6131 = (_e6117 + _e6128);
                                let _e6133 = ((_e6117 + _e6115) - _e6128);
                                let _e6138 = vec4<f32>(_e6131.x, _e6131.y, _e6133.x, _e6133.y);
                                switch bitcast<i32>(0u) {
                                    default: {
                                        let _e6142 = global.member_22[2u];
                                        let _e6143 = i32(_e6142);
                                        if (_e6143 <= 0i) {
                                            let _e6147 = clamp(_e6130, _e6138.xy, _e6138.zw);
                                            let _e6152 = textureSampleCompare(global_2, global_1, vec3<f32>(_e6147.x, _e6147.y, _e6099).xy, _e6099);
                                            phi_21525_ = _e6152;
                                            break;
                                        }
                                        let _e6154 = ((_e6130 / _e6127) + vec2<f32>(0.5f, 0.5f));
                                        let _e6155 = floor(_e6154);
                                        let _e6156 = (_e6154 - _e6155);
                                        let _e6158 = (_e6143 == 1i);
                                        if _e6158 {
                                            let _e6159 = (_e6156 * 2f);
                                            local_1[0i] = (vec2<f32>(3f, 3f) - _e6159);
                                            local_1[1i] = (vec2<f32>(1f, 1f) + _e6159);
                                            let _e6165 = local_1[0i];
                                            local_2[0i] = (((vec2<f32>(2f, 2f) - _e6156) / _e6165) - vec2<f32>(1f, 1f));
                                            let _e6169 = local_1[1i];
                                            local_2[1i] = ((_e6156 / _e6169) + vec2<f32>(1f, 1f));
                                        } else {
                                            let _e6173 = (_e6156 * 3f);
                                            local_1[0i] = (vec2<f32>(4f, 4f) - _e6173);
                                            local_1[1i] = vec2<f32>(7f, 7f);
                                            local_1[2i] = (vec2<f32>(1f, 1f) + _e6173);
                                            let _e6181 = local_1[0i];
                                            local_2[0i] = (((vec2<f32>(3f, 3f) - (_e6156 * 2f)) / _e6181) - vec2<f32>(2f, 2f));
                                            let _e6186 = local_1[1i];
                                            local_2[1i] = ((vec2<f32>(3f, 3f) + _e6156) / _e6186);
                                            let _e6189 = local_1[2i];
                                            local_2[2i] = ((_e6156 / _e6189) + vec2<f32>(2f, 2f));
                                        }
                                        let _e6194 = select(3i, 2i, _e6158);
                                        phi_21518_ = 0f;
                                        phi_21515_ = 0i;
                                        loop {
                                            let _e6196 = phi_21518_;
                                            let _e6198 = phi_21515_;
                                            local_53 = _e6196;
                                            if (_e6198 < _e6194) {
                                                phi_21524_ = _e6196;
                                                phi_21521_ = 0i;
                                                loop {
                                                    let _e6201 = phi_21524_;
                                                    let _e6203 = phi_21521_;
                                                    local_65 = _e6201;
                                                    if (_e6203 < _e6194) {
                                                        continue;
                                                    } else {
                                                        break;
                                                    }
                                                    continuing {
                                                        let _e6207 = local_2[_e6203][0u];
                                                        let _e6210 = local_2[_e6198][1u];
                                                        let _e6216 = clamp((_e6127 * ((_e6155 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e6207, _e6210))), _e6138.xy, _e6138.zw);
                                                        let _e6219 = local_1[_e6203][0u];
                                                        let _e6222 = local_1[_e6198][1u];
                                                        let _e6228 = textureSampleCompare(global_2, global_1, vec3<f32>(_e6216.x, _e6216.y, _e6099).xy, _e6099);
                                                        phi_21524_ = (_e6201 + ((_e6219 * _e6222) * _e6228));
                                                        phi_21521_ = (_e6203 + 1i);
                                                    }
                                                }
                                                continue;
                                            } else {
                                                break;
                                            }
                                            continuing {
                                                let _e7940 = local_65;
                                                phi_21518_ = _e7940;
                                                phi_21515_ = (_e6198 + 1i);
                                            }
                                        }
                                        let _e6234 = local_53;
                                        phi_21525_ = (_e6234 * select(0.0069444445f, 0.0625f, _e6158));
                                        break;
                                    }
                                }
                                let _e6237 = phi_21525_;
                                phi_21537_ = _e6237;
                                break;
                            }
                        }
                        let _e6239 = phi_21537_;
                        phi_21642_ = (_e5842 * _e6239);
                    }
                    let _e6242 = phi_21642_;
                    let _e6244 = normalize((_e5821 + _e815));
                    let _e6246 = clamp(dot(_e805, _e5821), 0f, 1f);
                    let _e6248 = clamp(dot(_e805, _e6244), 0f, 1f);
                    let _e6254 = (_e3284 + (_e3321 * pow((1f - clamp(dot(_e815, _e6244), 0f, 1f)), 5f)));
                    let _e6257 = (((_e6248 * _e6248) * _e3326) + 1f);
                    local_63 = (_e5789 + (((((vec3<f32>(1f, 1f, 1f) - _e6254) * _e3282) + ((_e6254 * ((_e3324 / ((3.1415927f * _e6257) * _e6257)) * (0.5f / max(((_e6246 * _e3336) + (_e3316 * sqrt((((_e6246 * _e6246) * _e3333) + _e3324)))), 0.00001f)))) * 3.1415927f)) * _e6246) * _e6242));
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e7920 = local_63;
                    phi_21644_ = _e7920;
                    phi_21510_ = (_e5791 + bitcast<u32>(1i));
                }
            }
            let _e7950 = local_66;
            phi_21715_ = _e7950;
        }
        let _e6282 = phi_21715_;
        phi_21711_ = _e6282;
    }
    let _e6284 = phi_21711_;
    let _e6287 = global_8.member_1[1u];
    let _e6291 = global_8.member_5;
    let _e6293 = textureSample(global_27, global_5, _e281);
    let _e6296 = global_25;
    let _e6302 = -(length(_e814));
    let _e6305 = global.member_7[3u];
    let _e6311 = global.member_9[3u];
    phi_21797_ = (1f - exp((_e6302 * _e6305)));
    if (_e6311 != 0f) {
        let _e6315 = (_e6311 * (_e813 - _e812).y);
        if (abs(_e6315) < 0.0001f) {
            phi_21794_ = (1f - (0.5f * _e6315));
        } else {
            phi_21794_ = ((1f - exp(min(-(_e6315), 60f))) / _e6315);
        }
        let _e6326 = phi_21794_;
        let _e6330 = global.member_6[1u];
        let _e6333 = global.member_6[3u];
        phi_21797_ = (1f - exp(((_e6302 * (_e6305 * exp(min((-(_e6311) * (_e6330 - _e6333)), 30f)))) * _e6326)));
    }
    let _e6344 = phi_21797_;
    let _e6346 = global.member_7;
    let _e6352 = global.member_34[2u];
    phi_21844_ = mix((mix(_e6284, _e1238, vec3(_e6287)) + ((_e6291.xyz * _e6293.xyz) * (vec3<f32>(1f, 1f, 1f) + _e6296.yzw))), _e6346.xyz, vec3(_e6344));
    if (_e6352 > 0.5f) {
        let _e6356 = global.member_29[0u];
        if (_e6356 > 0.5f) {
            let _e6359 = global.member_29;
            let _e6366 = ((_e6359.z * _e805.x) - (_e6359.w * _e805.z));
            let _e6370 = ((_e6359.w * _e805.x) + (_e6359.z * _e805.z));
            let _e6374 = (1.092548f * _e6366);
            local = array<f32, 9>(0.282095f, (0.488603f * _e805.y), (0.488603f * _e6370), (0.488603f * _e6366), (_e6374 * _e805.y), ((1.092548f * _e805.y) * _e6370), (0.315392f * (((3f * _e6370) * _e6370) - 1f)), (_e6374 * _e6370), (0.546274f * ((_e6366 * _e6366) - (_e805.y * _e805.y))));
            phi_21807_ = vec3<f32>(0f, 0f, 0f);
            phi_21806_ = 0i;
            loop {
                let _e6389 = phi_21807_;
                let _e6391 = phi_21806_;
                local_54 = _e6389;
                if (_e6391 < 9i) {
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e6395 = textureLoad(global_4, (vec2<i32>(496i, 256i) + vec2<i32>(_e6391, 0i)), 0i);
                    let _e6398 = local[_e6391];
                    phi_21807_ = (_e6389 + (_e6395.xyz * _e6398));
                    phi_21806_ = (_e6391 + 1i);
                }
            }
            let _e6403 = local_54;
            let _e6407 = global.member_29[1u];
            phi_21808_ = (max(_e6403, vec3<f32>(0f, 0f, 0f)) * _e6407);
        } else {
            let _e6410 = global.member_9;
            let _e6413 = global.member_8;
            let _e6422 = global.member_8[3u];
            phi_21808_ = (mix(_e6410.xyz, _e6413.xyz, vec3(((_e805.y * 0.5f) + 0.5f))) * _e6422);
        }
        let _e6425 = phi_21808_;
        let _e6428 = global.member_34[1u];
        phi_21813_ = _e6425;
        if (_e6428 > 0.5f) {
            let _e6433 = global.member_34[0u];
            phi_21812_ = _e6425;
            phi_21811_ = 0i;
            loop {
                let _e6436 = phi_21812_;
                let _e6438 = phi_21811_;
                local_67 = _e6436;
                if (_e6438 < i32(_e6428)) {
                    let _e6441 = (8i * (i32(_e6433) + _e6438));
                    let _e6445 = global_3.member[(_e6441 + 3i)];
                    let _e6446 = bitcast<vec4<f32>>(_e6445);
                    let _e6449 = global_3.member[_e6441];
                    let _e6450 = bitcast<vec4<f32>>(_e6449);
                    let _e6454 = global_3.member[(_e6441 + 1i)];
                    let _e6455 = bitcast<vec4<f32>>(_e6454);
                    let _e6459 = global_3.member[(_e6441 + 2i)];
                    let _e6460 = bitcast<vec4<f32>>(_e6459);
                    let _e6461 = _e6450.xyz;
                    let _e6465 = _e6455.xyz;
                    let _e6469 = _e6460.xyz;
                    let _e6473 = vec3<f32>((dot(_e6461, _e813) + _e6450.w), (dot(_e6465, _e813) + _e6455.w), (dot(_e6469, _e813) + _e6460.w));
                    let _e6474 = _e6446.xyz;
                    switch bitcast<i32>(0u) {
                        default: {
                            let _e6478 = (_e6474 - abs(_e6473));
                            let _e6483 = min(_e6478.x, min(_e6478.y, _e6478.z));
                            if (_e6483 <= 0f) {
                                phi_21973_ = 0f;
                                break;
                            }
                            if (_e6446.w <= 0f) {
                                phi_21973_ = 1f;
                                break;
                            }
                            let _e6487 = min((_e6483 / _e6446.w), 1f);
                            phi_21973_ = ((_e6487 * _e6487) * (3f - (2f * _e6487)));
                            break;
                        }
                    }
                    let _e6493 = phi_21973_;
                    if (_e6493 <= 0f) {
                        phi_22141_ = _e6436;
                        continue;
                    }
                    let _e6498 = global_3.member[(_e6441 + 4i)];
                    let _e6500 = bitcast<vec4<f32>>(_e6498).xyz;
                    let _e6504 = global_3.member[(_e6441 + 5i)];
                    let _e6505 = bitcast<vec4<f32>>(_e6504);
                    let _e6510 = global_3.member[(_e6441 + 6i)][0u];
                    let _e6511 = bitcast<i32>(_e6510);
                    let _e6512 = dot(_e6461, _e805);
                    let _e6513 = dot(_e6465, _e805);
                    let _e6514 = dot(_e6469, _e805);
                    let _e6515 = vec3<f32>(_e6512, _e6513, _e6514);
                    let _e6521 = ((_e813 + (_e805 * _e6505.x)) + (_e815 * _e6505.y));
                    let _e6536 = clamp(((((vec3<f32>((dot(_e6461, _e6521) + _e6450.w), (dot(_e6465, _e6521) + _e6455.w), (dot(_e6469, _e6521) + _e6460.w)) + _e6474) / max((_e6474 * 2f), vec3<f32>(0.000001f, 0.000001f, 0.000001f))) * _e6500) - vec3<f32>(0.5f, 0.5f, 0.5f)), vec3<f32>(0f, 0f, 0f), (_e6500 - vec3<f32>(1f, 1f, 1f)));
                    let _e6537 = vec3<i32>(_e6500);
                    let _e6541 = min(vec3<i32>(_e6536), max((_e6537 - vec3<i32>(2i, 2i, 2i)), vec3<i32>(0i, 0i, 0i)));
                    let _e6543 = (_e6536 - vec3<f32>(_e6541));
                    let _e6544 = (0.488603f * _e6513);
                    let _e6545 = (0.488603f * _e6514);
                    let _e6546 = (0.488603f * _e6512);
                    let _e6547 = (1.092548f * _e6512);
                    let _e6548 = (_e6547 * _e6513);
                    let _e6550 = ((1.092548f * _e6513) * _e6514);
                    let _e6554 = (0.315392f * (((3f * _e6514) * _e6514) - 1f));
                    let _e6555 = (_e6547 * _e6514);
                    let _e6559 = (0.546274f * ((_e6512 * _e6512) - (_e6513 * _e6513)));
                    let _e6560 = (_e6537 - vec3<i32>(1i, 1i, 1i));
                    let _e6561 = min(_e6541, _e6560);
                    let _e6572 = (_e6511 + ((_e6561.x + (_e6537.x * (_e6561.y + (_e6537.y * _e6561.z)))) * 4i));
                    let _e6573 = (vec3<f32>(1f, 1f, 1f) - _e6543);
                    let _e6580 = ((((((vec3<f32>(_e6561) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e6500) * _e6474) * 2f) - _e6474) - _e6473);
                    let _e6586 = (dot((_e6580 * inverseSqrt(max(dot(_e6580, _e6580), 0.0000000001f))), _e6515) + 1f);
                    let _e6589 = (_e6573.x * _e6573.y);
                    let _e6596 = (_e6572 + 3i);
                    let _e6600 = global_3.member[_e6596][1u];
                    let _e6605 = (((_e6589 * _e6573.z) * ((0.25f * (_e6586 * _e6586)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e6600).y > 0.5f)));
                    let _e6608 = global_3.member[_e6572];
                    let _e6612 = global_3.member[(_e6572 + 1i)];
                    let _e6616 = global_3.member[(_e6572 + 2i)];
                    let _e6619 = global_3.member[_e6596];
                    let _e6621 = unpack2x16float(_e6608.x);
                    let _e6623 = unpack2x16float(_e6608.y);
                    let _e6625 = unpack2x16float(_e6608.z);
                    let _e6627 = unpack2x16float(_e6608.w);
                    let _e6629 = unpack2x16float(_e6612.x);
                    let _e6631 = unpack2x16float(_e6612.y);
                    let _e6633 = unpack2x16float(_e6612.z);
                    let _e6635 = unpack2x16float(_e6612.w);
                    let _e6637 = unpack2x16float(_e6616.x);
                    let _e6639 = unpack2x16float(_e6616.y);
                    let _e6641 = unpack2x16float(_e6616.z);
                    let _e6643 = unpack2x16float(_e6616.w);
                    let _e6645 = unpack2x16float(_e6619.x);
                    let _e6701 = ((((((((((vec3<f32>(_e6621.x, _e6621.y, _e6623.x) * 0.282095f) + (vec3<f32>(_e6623.y, _e6625.x, _e6625.y) * _e6544)) + (vec3<f32>(_e6627.x, _e6627.y, _e6629.x) * _e6545)) + (vec3<f32>(_e6629.y, _e6631.x, _e6631.y) * _e6546)) + (vec3<f32>(_e6633.x, _e6633.y, _e6635.x) * _e6548)) + (vec3<f32>(_e6635.y, _e6637.x, _e6637.y) * _e6550)) + (vec3<f32>(_e6639.x, _e6639.y, _e6641.x) * _e6554)) + (vec3<f32>(_e6641.y, _e6643.x, _e6643.y) * _e6555)) + (vec3<f32>(_e6645.x, _e6645.y, unpack2x16float(_e6619.y).x) * _e6559)) * _e6605);
                    let _e6707 = min((_e6541 + vec3<i32>(1i, 0i, 0i)), _e6560);
                    let _e6716 = (_e6511 + ((_e6707.x + (_e6537.x * (_e6707.y + (_e6537.y * _e6707.z)))) * 4i));
                    let _e6723 = ((((((vec3<f32>(_e6707) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e6500) * _e6474) * 2f) - _e6474) - _e6473);
                    let _e6729 = (dot((_e6723 * inverseSqrt(max(dot(_e6723, _e6723), 0.0000000001f))), _e6515) + 1f);
                    let _e6731 = (_e6543.x * _e6573.y);
                    let _e6737 = (_e6716 + 3i);
                    let _e6741 = global_3.member[_e6737][1u];
                    let _e6746 = (((_e6731 * _e6573.z) * ((0.25f * (_e6729 * _e6729)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e6741).y > 0.5f)));
                    let _e6749 = global_3.member[_e6716];
                    let _e6753 = global_3.member[(_e6716 + 1i)];
                    let _e6757 = global_3.member[(_e6716 + 2i)];
                    let _e6760 = global_3.member[_e6737];
                    let _e6762 = unpack2x16float(_e6749.x);
                    let _e6764 = unpack2x16float(_e6749.y);
                    let _e6766 = unpack2x16float(_e6749.z);
                    let _e6768 = unpack2x16float(_e6749.w);
                    let _e6770 = unpack2x16float(_e6753.x);
                    let _e6772 = unpack2x16float(_e6753.y);
                    let _e6774 = unpack2x16float(_e6753.z);
                    let _e6776 = unpack2x16float(_e6753.w);
                    let _e6778 = unpack2x16float(_e6757.x);
                    let _e6780 = unpack2x16float(_e6757.y);
                    let _e6782 = unpack2x16float(_e6757.z);
                    let _e6784 = unpack2x16float(_e6757.w);
                    let _e6786 = unpack2x16float(_e6760.x);
                    let _e6842 = ((((((((((vec3<f32>(_e6762.x, _e6762.y, _e6764.x) * 0.282095f) + (vec3<f32>(_e6764.y, _e6766.x, _e6766.y) * _e6544)) + (vec3<f32>(_e6768.x, _e6768.y, _e6770.x) * _e6545)) + (vec3<f32>(_e6770.y, _e6772.x, _e6772.y) * _e6546)) + (vec3<f32>(_e6774.x, _e6774.y, _e6776.x) * _e6548)) + (vec3<f32>(_e6776.y, _e6778.x, _e6778.y) * _e6550)) + (vec3<f32>(_e6780.x, _e6780.y, _e6782.x) * _e6554)) + (vec3<f32>(_e6782.y, _e6784.x, _e6784.y) * _e6555)) + (vec3<f32>(_e6786.x, _e6786.y, unpack2x16float(_e6760.y).x) * _e6559)) * _e6746);
                    let _e6849 = min((_e6541 + vec3<i32>(0i, 1i, 0i)), _e6560);
                    let _e6858 = (_e6511 + ((_e6849.x + (_e6537.x * (_e6849.y + (_e6537.y * _e6849.z)))) * 4i));
                    let _e6865 = ((((((vec3<f32>(_e6849) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e6500) * _e6474) * 2f) - _e6474) - _e6473);
                    let _e6871 = (dot((_e6865 * inverseSqrt(max(dot(_e6865, _e6865), 0.0000000001f))), _e6515) + 1f);
                    let _e6873 = (_e6573.x * _e6543.y);
                    let _e6879 = (_e6858 + 3i);
                    let _e6883 = global_3.member[_e6879][1u];
                    let _e6888 = (((_e6873 * _e6573.z) * ((0.25f * (_e6871 * _e6871)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e6883).y > 0.5f)));
                    let _e6891 = global_3.member[_e6858];
                    let _e6895 = global_3.member[(_e6858 + 1i)];
                    let _e6899 = global_3.member[(_e6858 + 2i)];
                    let _e6902 = global_3.member[_e6879];
                    let _e6904 = unpack2x16float(_e6891.x);
                    let _e6906 = unpack2x16float(_e6891.y);
                    let _e6908 = unpack2x16float(_e6891.z);
                    let _e6910 = unpack2x16float(_e6891.w);
                    let _e6912 = unpack2x16float(_e6895.x);
                    let _e6914 = unpack2x16float(_e6895.y);
                    let _e6916 = unpack2x16float(_e6895.z);
                    let _e6918 = unpack2x16float(_e6895.w);
                    let _e6920 = unpack2x16float(_e6899.x);
                    let _e6922 = unpack2x16float(_e6899.y);
                    let _e6924 = unpack2x16float(_e6899.z);
                    let _e6926 = unpack2x16float(_e6899.w);
                    let _e6928 = unpack2x16float(_e6902.x);
                    let _e6984 = ((((((((((vec3<f32>(_e6904.x, _e6904.y, _e6906.x) * 0.282095f) + (vec3<f32>(_e6906.y, _e6908.x, _e6908.y) * _e6544)) + (vec3<f32>(_e6910.x, _e6910.y, _e6912.x) * _e6545)) + (vec3<f32>(_e6912.y, _e6914.x, _e6914.y) * _e6546)) + (vec3<f32>(_e6916.x, _e6916.y, _e6918.x) * _e6548)) + (vec3<f32>(_e6918.y, _e6920.x, _e6920.y) * _e6550)) + (vec3<f32>(_e6922.x, _e6922.y, _e6924.x) * _e6554)) + (vec3<f32>(_e6924.y, _e6926.x, _e6926.y) * _e6555)) + (vec3<f32>(_e6928.x, _e6928.y, unpack2x16float(_e6902.y).x) * _e6559)) * _e6888);
                    let _e6991 = min((_e6541 + vec3<i32>(1i, 1i, 0i)), _e6560);
                    let _e7000 = (_e6511 + ((_e6991.x + (_e6537.x * (_e6991.y + (_e6537.y * _e6991.z)))) * 4i));
                    let _e7007 = ((((((vec3<f32>(_e6991) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e6500) * _e6474) * 2f) - _e6474) - _e6473);
                    let _e7013 = (dot((_e7007 * inverseSqrt(max(dot(_e7007, _e7007), 0.0000000001f))), _e6515) + 1f);
                    let _e7014 = (_e6543.x * _e6543.y);
                    let _e7020 = (_e7000 + 3i);
                    let _e7024 = global_3.member[_e7020][1u];
                    let _e7029 = (((_e7014 * _e6573.z) * ((0.25f * (_e7013 * _e7013)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e7024).y > 0.5f)));
                    let _e7032 = global_3.member[_e7000];
                    let _e7036 = global_3.member[(_e7000 + 1i)];
                    let _e7040 = global_3.member[(_e7000 + 2i)];
                    let _e7043 = global_3.member[_e7020];
                    let _e7045 = unpack2x16float(_e7032.x);
                    let _e7047 = unpack2x16float(_e7032.y);
                    let _e7049 = unpack2x16float(_e7032.z);
                    let _e7051 = unpack2x16float(_e7032.w);
                    let _e7053 = unpack2x16float(_e7036.x);
                    let _e7055 = unpack2x16float(_e7036.y);
                    let _e7057 = unpack2x16float(_e7036.z);
                    let _e7059 = unpack2x16float(_e7036.w);
                    let _e7061 = unpack2x16float(_e7040.x);
                    let _e7063 = unpack2x16float(_e7040.y);
                    let _e7065 = unpack2x16float(_e7040.z);
                    let _e7067 = unpack2x16float(_e7040.w);
                    let _e7069 = unpack2x16float(_e7043.x);
                    let _e7125 = ((((((((((vec3<f32>(_e7045.x, _e7045.y, _e7047.x) * 0.282095f) + (vec3<f32>(_e7047.y, _e7049.x, _e7049.y) * _e6544)) + (vec3<f32>(_e7051.x, _e7051.y, _e7053.x) * _e6545)) + (vec3<f32>(_e7053.y, _e7055.x, _e7055.y) * _e6546)) + (vec3<f32>(_e7057.x, _e7057.y, _e7059.x) * _e6548)) + (vec3<f32>(_e7059.y, _e7061.x, _e7061.y) * _e6550)) + (vec3<f32>(_e7063.x, _e7063.y, _e7065.x) * _e6554)) + (vec3<f32>(_e7065.y, _e7067.x, _e7067.y) * _e6555)) + (vec3<f32>(_e7069.x, _e7069.y, unpack2x16float(_e7043.y).x) * _e6559)) * _e7029);
                    let _e7132 = min((_e6541 + vec3<i32>(0i, 0i, 1i)), _e6560);
                    let _e7141 = (_e6511 + ((_e7132.x + (_e6537.x * (_e7132.y + (_e6537.y * _e7132.z)))) * 4i));
                    let _e7148 = ((((((vec3<f32>(_e7132) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e6500) * _e6474) * 2f) - _e6474) - _e6473);
                    let _e7154 = (dot((_e7148 * inverseSqrt(max(dot(_e7148, _e7148), 0.0000000001f))), _e6515) + 1f);
                    let _e7161 = (_e7141 + 3i);
                    let _e7165 = global_3.member[_e7161][1u];
                    let _e7170 = (((_e6589 * _e6543.z) * ((0.25f * (_e7154 * _e7154)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e7165).y > 0.5f)));
                    let _e7173 = global_3.member[_e7141];
                    let _e7177 = global_3.member[(_e7141 + 1i)];
                    let _e7181 = global_3.member[(_e7141 + 2i)];
                    let _e7184 = global_3.member[_e7161];
                    let _e7186 = unpack2x16float(_e7173.x);
                    let _e7188 = unpack2x16float(_e7173.y);
                    let _e7190 = unpack2x16float(_e7173.z);
                    let _e7192 = unpack2x16float(_e7173.w);
                    let _e7194 = unpack2x16float(_e7177.x);
                    let _e7196 = unpack2x16float(_e7177.y);
                    let _e7198 = unpack2x16float(_e7177.z);
                    let _e7200 = unpack2x16float(_e7177.w);
                    let _e7202 = unpack2x16float(_e7181.x);
                    let _e7204 = unpack2x16float(_e7181.y);
                    let _e7206 = unpack2x16float(_e7181.z);
                    let _e7208 = unpack2x16float(_e7181.w);
                    let _e7210 = unpack2x16float(_e7184.x);
                    let _e7266 = ((((((((((vec3<f32>(_e7186.x, _e7186.y, _e7188.x) * 0.282095f) + (vec3<f32>(_e7188.y, _e7190.x, _e7190.y) * _e6544)) + (vec3<f32>(_e7192.x, _e7192.y, _e7194.x) * _e6545)) + (vec3<f32>(_e7194.y, _e7196.x, _e7196.y) * _e6546)) + (vec3<f32>(_e7198.x, _e7198.y, _e7200.x) * _e6548)) + (vec3<f32>(_e7200.y, _e7202.x, _e7202.y) * _e6550)) + (vec3<f32>(_e7204.x, _e7204.y, _e7206.x) * _e6554)) + (vec3<f32>(_e7206.y, _e7208.x, _e7208.y) * _e6555)) + (vec3<f32>(_e7210.x, _e7210.y, unpack2x16float(_e7184.y).x) * _e6559)) * _e7170);
                    let _e7273 = min((_e6541 + vec3<i32>(1i, 0i, 1i)), _e6560);
                    let _e7282 = (_e6511 + ((_e7273.x + (_e6537.x * (_e7273.y + (_e6537.y * _e7273.z)))) * 4i));
                    let _e7289 = ((((((vec3<f32>(_e7273) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e6500) * _e6474) * 2f) - _e6474) - _e6473);
                    let _e7295 = (dot((_e7289 * inverseSqrt(max(dot(_e7289, _e7289), 0.0000000001f))), _e6515) + 1f);
                    let _e7301 = (_e7282 + 3i);
                    let _e7305 = global_3.member[_e7301][1u];
                    let _e7310 = (((_e6731 * _e6543.z) * ((0.25f * (_e7295 * _e7295)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e7305).y > 0.5f)));
                    let _e7313 = global_3.member[_e7282];
                    let _e7317 = global_3.member[(_e7282 + 1i)];
                    let _e7321 = global_3.member[(_e7282 + 2i)];
                    let _e7324 = global_3.member[_e7301];
                    let _e7326 = unpack2x16float(_e7313.x);
                    let _e7328 = unpack2x16float(_e7313.y);
                    let _e7330 = unpack2x16float(_e7313.z);
                    let _e7332 = unpack2x16float(_e7313.w);
                    let _e7334 = unpack2x16float(_e7317.x);
                    let _e7336 = unpack2x16float(_e7317.y);
                    let _e7338 = unpack2x16float(_e7317.z);
                    let _e7340 = unpack2x16float(_e7317.w);
                    let _e7342 = unpack2x16float(_e7321.x);
                    let _e7344 = unpack2x16float(_e7321.y);
                    let _e7346 = unpack2x16float(_e7321.z);
                    let _e7348 = unpack2x16float(_e7321.w);
                    let _e7350 = unpack2x16float(_e7324.x);
                    let _e7406 = ((((((((((vec3<f32>(_e7326.x, _e7326.y, _e7328.x) * 0.282095f) + (vec3<f32>(_e7328.y, _e7330.x, _e7330.y) * _e6544)) + (vec3<f32>(_e7332.x, _e7332.y, _e7334.x) * _e6545)) + (vec3<f32>(_e7334.y, _e7336.x, _e7336.y) * _e6546)) + (vec3<f32>(_e7338.x, _e7338.y, _e7340.x) * _e6548)) + (vec3<f32>(_e7340.y, _e7342.x, _e7342.y) * _e6550)) + (vec3<f32>(_e7344.x, _e7344.y, _e7346.x) * _e6554)) + (vec3<f32>(_e7346.y, _e7348.x, _e7348.y) * _e6555)) + (vec3<f32>(_e7350.x, _e7350.y, unpack2x16float(_e7324.y).x) * _e6559)) * _e7310);
                    let _e7413 = min((_e6541 + vec3<i32>(0i, 1i, 1i)), _e6560);
                    let _e7422 = (_e6511 + ((_e7413.x + (_e6537.x * (_e7413.y + (_e6537.y * _e7413.z)))) * 4i));
                    let _e7429 = ((((((vec3<f32>(_e7413) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e6500) * _e6474) * 2f) - _e6474) - _e6473);
                    let _e7435 = (dot((_e7429 * inverseSqrt(max(dot(_e7429, _e7429), 0.0000000001f))), _e6515) + 1f);
                    let _e7441 = (_e7422 + 3i);
                    let _e7445 = global_3.member[_e7441][1u];
                    let _e7450 = (((_e6873 * _e6543.z) * ((0.25f * (_e7435 * _e7435)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e7445).y > 0.5f)));
                    let _e7453 = global_3.member[_e7422];
                    let _e7457 = global_3.member[(_e7422 + 1i)];
                    let _e7461 = global_3.member[(_e7422 + 2i)];
                    let _e7464 = global_3.member[_e7441];
                    let _e7466 = unpack2x16float(_e7453.x);
                    let _e7468 = unpack2x16float(_e7453.y);
                    let _e7470 = unpack2x16float(_e7453.z);
                    let _e7472 = unpack2x16float(_e7453.w);
                    let _e7474 = unpack2x16float(_e7457.x);
                    let _e7476 = unpack2x16float(_e7457.y);
                    let _e7478 = unpack2x16float(_e7457.z);
                    let _e7480 = unpack2x16float(_e7457.w);
                    let _e7482 = unpack2x16float(_e7461.x);
                    let _e7484 = unpack2x16float(_e7461.y);
                    let _e7486 = unpack2x16float(_e7461.z);
                    let _e7488 = unpack2x16float(_e7461.w);
                    let _e7490 = unpack2x16float(_e7464.x);
                    let _e7546 = ((((((((((vec3<f32>(_e7466.x, _e7466.y, _e7468.x) * 0.282095f) + (vec3<f32>(_e7468.y, _e7470.x, _e7470.y) * _e6544)) + (vec3<f32>(_e7472.x, _e7472.y, _e7474.x) * _e6545)) + (vec3<f32>(_e7474.y, _e7476.x, _e7476.y) * _e6546)) + (vec3<f32>(_e7478.x, _e7478.y, _e7480.x) * _e6548)) + (vec3<f32>(_e7480.y, _e7482.x, _e7482.y) * _e6550)) + (vec3<f32>(_e7484.x, _e7484.y, _e7486.x) * _e6554)) + (vec3<f32>(_e7486.y, _e7488.x, _e7488.y) * _e6555)) + (vec3<f32>(_e7490.x, _e7490.y, unpack2x16float(_e7464.y).x) * _e6559)) * _e7450);
                    let _e7553 = min((_e6541 + vec3<i32>(1i, 1i, 1i)), _e6560);
                    let _e7562 = (_e6511 + ((_e7553.x + (_e6537.x * (_e7553.y + (_e6537.y * _e7553.z)))) * 4i));
                    let _e7569 = ((((((vec3<f32>(_e7553) + vec3<f32>(0.5f, 0.5f, 0.5f)) / _e6500) * _e6474) * 2f) - _e6474) - _e6473);
                    let _e7575 = (dot((_e7569 * inverseSqrt(max(dot(_e7569, _e7569), 0.0000000001f))), _e6515) + 1f);
                    let _e7581 = (_e7562 + 3i);
                    let _e7585 = global_3.member[_e7581][1u];
                    let _e7590 = (((_e7014 * _e6543.z) * ((0.25f * (_e7575 * _e7575)) + 0.2f)) * select(0f, 1f, (unpack2x16float(_e7585).y > 0.5f)));
                    let _e7593 = global_3.member[_e7562];
                    let _e7597 = global_3.member[(_e7562 + 1i)];
                    let _e7601 = global_3.member[(_e7562 + 2i)];
                    let _e7604 = global_3.member[_e7581];
                    let _e7606 = unpack2x16float(_e7593.x);
                    let _e7608 = unpack2x16float(_e7593.y);
                    let _e7610 = unpack2x16float(_e7593.z);
                    let _e7612 = unpack2x16float(_e7593.w);
                    let _e7614 = unpack2x16float(_e7597.x);
                    let _e7616 = unpack2x16float(_e7597.y);
                    let _e7618 = unpack2x16float(_e7597.z);
                    let _e7620 = unpack2x16float(_e7597.w);
                    let _e7622 = unpack2x16float(_e7601.x);
                    let _e7624 = unpack2x16float(_e7601.y);
                    let _e7626 = unpack2x16float(_e7601.z);
                    let _e7628 = unpack2x16float(_e7601.w);
                    let _e7630 = unpack2x16float(_e7604.x);
                    let _e7686 = ((((((((((vec3<f32>(_e7606.x, _e7606.y, _e7608.x) * 0.282095f) + (vec3<f32>(_e7608.y, _e7610.x, _e7610.y) * _e6544)) + (vec3<f32>(_e7612.x, _e7612.y, _e7614.x) * _e6545)) + (vec3<f32>(_e7614.y, _e7616.x, _e7616.y) * _e6546)) + (vec3<f32>(_e7618.x, _e7618.y, _e7620.x) * _e6548)) + (vec3<f32>(_e7620.y, _e7622.x, _e7622.y) * _e6550)) + (vec3<f32>(_e7624.x, _e7624.y, _e7626.x) * _e6554)) + (vec3<f32>(_e7626.y, _e7628.x, _e7628.y) * _e6555)) + (vec3<f32>(_e7630.x, _e7630.y, unpack2x16float(_e7604.y).x) * _e6559)) * _e7590);
                    let _e7691 = (((((((vec4<f32>(_e6701.x, _e6701.y, _e6701.z, _e6605) + vec4<f32>(_e6842.x, _e6842.y, _e6842.z, _e6746)) + vec4<f32>(_e6984.x, _e6984.y, _e6984.z, _e6888)) + vec4<f32>(_e7125.x, _e7125.y, _e7125.z, _e7029)) + vec4<f32>(_e7266.x, _e7266.y, _e7266.z, _e7170)) + vec4<f32>(_e7406.x, _e7406.y, _e7406.z, _e7310)) + vec4<f32>(_e7546.x, _e7546.y, _e7546.z, _e7450)) + vec4<f32>(_e7686.x, _e7686.y, _e7686.z, _e7590));
                    phi_22142_ = _e6436;
                    if (_e7691.w > 0.00001f) {
                        phi_22142_ = mix(_e6436, ((max(_e7691.xyz, vec3<f32>(0f, 0f, 0f)) / vec3(_e7691.w)) * _e6505.z), vec3(_e6493));
                    }
                    let _e7703 = phi_22142_;
                    phi_22141_ = _e7703;
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e7705 = phi_22141_;
                    phi_21812_ = _e7705;
                    phi_21811_ = (_e6438 + 1i);
                }
            }
            let _e7965 = local_67;
            phi_21813_ = _e7965;
        }
        let _e7708 = phi_21813_;
        phi_21844_ = (_e7708 * _e1267);
    }
    let _e7711 = phi_21844_;
    let _e7714 = global.member_33[3u];
    phi_21845_ = _e7711;
    if (_e7714 > 0.5f) {
        phi_21845_ = (_e7711 / (vec3<f32>(1f, 1f, 1f) + _e7711));
    }
    let _e7719 = phi_21845_;
    global_28 = vec4<f32>(_e7719.x, _e7719.y, _e7719.z, _e301);
    let _e7724 = global_30;
    let _e7725 = global_31;
    switch bitcast<i32>(0u) {
        default: {
            if (_e7725.w <= 0f) {
                phi_21972_ = vec2<f32>(0f, 0f);
                break;
            }
            phi_21972_ = (((_e7725.xy / vec2(_e7725.w)) - (_e7724.xy / vec2(_e7724.w))) * vec2<f32>(0.5f, -0.5f));
            break;
        }
    }
    let _e7739 = phi_21972_;
    global_29 = _e7739;
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
